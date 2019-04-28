
#import "Audio.h"
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark - global c-style things

/**
 *  User-specified c-style callback that we'll send samples through.
 */
static AudioCallback theAudioCallback;
static void* theAudioCallbackUserData;

/**
 *  Sample conversion stuff
 */
static Float32 convertFromFloatCoefficient = (Float32)(1 << 24); // scale audio from -1.0 to 1.0
static Float32 convertToFloatCoefficient = 1.0 / (Float32)(1 << 24);
void convertAUToFloat(AudioBufferList* input, Float32* buffer, UInt32 numFrames, UInt32* actualFrames);
void convertAUFromFloat(AudioBufferList* input, Float32* buffer, UInt32 numFrames);

// use this buffer for floating point conversion
static Float32 theFloatBuffer[AUDIO_MAX_BUFFER_SIZE * AUDIO_NUM_CHANNELS];


/**
 *  Main core audio input callback
 */
OSStatus coreAudioCallback(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);


#pragma mark - Audio

@interface Audio () <AVAudioSessionDelegate>
{
  BOOL isSessionActive;
}

- (BOOL) configureAudio;
- (BOOL) configureAudioDataFormat;
- (BOOL) disposeAudio;

// listeners for audio state changes
- (void) handleAudioRouteChange: (NSNotification*)notification;
- (void) handleAudioInterruption: (NSNotification*)notification;

- (void) AudioLog: (NSString*)str, ...;

@end


@implementation Audio

- (id)initWithSampleRate: (double)sampleRate bufferSize: (unsigned short)bufferSize callback: (AudioCallback)callback userData:(void*)data
{
  if (self = [super init]) {
    _isMicrophoneEnabled = NO;
    _overrideToSpeaker = NO;
    isSessionActive = NO;
    
    _sampleRate = sampleRate;
    _bufferSize = MIN(bufferSize, AUDIO_MAX_BUFFER_SIZE);
    theAudioCallback = callback;
    theAudioCallbackUserData = data;
  }
  return self;
}

- (void)dealloc
{
  [self disposeAudio];
}

#pragma mark - audio session lifecycle

- (BOOL)startSession
{
  if (isSessionActive)
    return NO;
  
  [self AudioLog:@"starting session"];
  
  NSError* err = nil;
  
  // push our parameters into the AVAudioSession
  [[AVAudioSession sharedInstance] setPreferredSampleRate:_sampleRate error:&err];
  if (err)
    [self AudioLog:@"failed to set sample rate to %lf: %@", _sampleRate, err.description];
  
  NSTimeInterval bufferDuration = _bufferSize / _sampleRate;
  [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:bufferDuration error:&err];
  if (err)
    [self AudioLog:@"failed to set buffer size to %lf: %@", bufferDuration, err.description];
  
  // enable the session
  [[AVAudioSession sharedInstance] setActive:YES error:&err];
  if (err)  {
    [self AudioLog:@"failed to start session: %@", err.description];
    return NO;
  }
  
  // listen for audio notifications
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleAudioRouteChange:)
                                               name:AVAudioSessionRouteChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleAudioInterruption:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
  
  // microphone?
  _isMicrophoneAvailable = [AVAudioSession sharedInstance].inputAvailable;
  
  // configure and start audio unit
  if ([self configureAudio]) {
    OSStatus err = AudioOutputUnitStart(_audioUnit);
    if (err != kAudioSessionNoError) {
      [self AudioLog:@"failed to start audio unit"];
      return NO;
    }
  } else
    return NO;
  
  isSessionActive = YES;
  return YES;
}

- (BOOL)configureAudio
{
  OSStatus err;
  
  // describe an audio component that we want
  AudioComponentDescription desc;
  desc.componentType = kAudioUnitType_Output;
  desc.componentSubType = kAudioUnitSubType_RemoteIO;
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  
  // open remote I/O unit with a component matching our description
  err = AudioComponentInstanceNew(AudioComponentFindNext(NULL, &desc), &_audioUnit);
  if (err) {
    [self AudioLog:@"failed to open the remote I/O unit"];
    return NO;
  }
  
  // if there's a mic, enable it
  err = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &_isMicrophoneAvailable, sizeof(_isMicrophoneAvailable));
  if (err) {
    [self AudioLog:@"failed to enable mic on the remote I/O unit"];
    return NO;
  }
  
  // wire up our render callback
  AURenderCallbackStruct renderProc;
  renderProc.inputProc = coreAudioCallback;
  renderProc.inputProcRefCon = (__bridge void*)self;
  err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderProc, sizeof(renderProc));
  if (err) {
    [self AudioLog:@"failed to set callback"];
    return NO;
  }
  
  // configure the data format
  if (![self configureAudioDataFormat]) {
    [self AudioLog:@"failed to configure I/O unit's data format"];
    return NO;
  }
  
  // ok, ready to initialize
  err = AudioUnitInitialize(_audioUnit);
  if (err) {
    [self AudioLog:@"failed to initialize the remote I/O unit"];
    return NO;
  }
  
  return YES;
}

- (BOOL)configureAudioDataFormat
{
  OSStatus err = kAudioSessionNoError;
  
  // desired data format
  AudioStreamBasicDescription desiredFormat;
  
  desiredFormat.mFormatID = kAudioFormatLinearPCM;
  desiredFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
  desiredFormat.mReserved = 0;
  
  desiredFormat.mSampleRate = _sampleRate;
  desiredFormat.mChannelsPerFrame = AUDIO_NUM_CHANNELS;
  desiredFormat.mBitsPerChannel = 8 * sizeof(SInt32);
  desiredFormat.mBytesPerFrame  = desiredFormat.mChannelsPerFrame * sizeof(SInt32);
  desiredFormat.mFramesPerPacket = 1;
  desiredFormat.mBytesPerPacket = desiredFormat.mBytesPerFrame * desiredFormat.mFramesPerPacket;
  
  // local data format
  AudioStreamBasicDescription localFormat;
  
  UInt32 size = sizeof(localFormat);
  err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &localFormat, &size);
  if (err) {
    [self AudioLog:@"couldn't get the remote I/O unit's output client format"];
    return NO;
  }
  
  localFormat.mSampleRate = desiredFormat.mSampleRate;
  localFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger |
  kAudioFormatFlagIsPacked |
  kAudioFormatFlagIsNonInterleaved |
  (24 << kLinearPCMFormatFlagsSampleFractionShift);
  localFormat.mChannelsPerFrame = desiredFormat.mChannelsPerFrame;
  localFormat.mBytesPerFrame = 4;
  localFormat.mBytesPerPacket = 4;
  localFormat.mBitsPerChannel = 32;
  
  // configure input stream format
  err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &localFormat, sizeof(localFormat));
  if (err) {
    [self AudioLog:@"couldn't set the remote I/O unit's input client format"];
    return NO;
  }
  
  // write actual input stream format to desired format
  size = sizeof(desiredFormat);
  err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &desiredFormat, &size);
  if (err) {
    [self AudioLog:@"couldn't get the remote I/O unit's output client format"];
    return NO;
  }
  
  // configure output stream format
  err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desiredFormat, sizeof(desiredFormat));
  if (err) {
    [self AudioLog:@"couldn't set the remote I/O unit's output client format"];
    return NO;
  }
  
  return YES;
}

- (BOOL)disposeAudio
{
  if (!isSessionActive)
    return NO;
  
  OSStatus err = kAudioSessionNoError;
  
  // tear down the audio unit
  err = AudioOutputUnitStop(_audioUnit);
  if (err) {
    [self AudioLog:@"failed to stop the audio unit"];
    return NO;
  }
  err = AudioComponentInstanceDispose(_audioUnit);
  if (err) {
    [self AudioLog:@"failed to dispose of the audio unit"];
    return NO;
  }
  
  // stop listening for route changes
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
  
  isSessionActive = NO;
  return YES;
}

- (BOOL)suspendSession
{
  [self disposeAudio];
  return YES;
}



#pragma mark - external properties

// if we are outputting and reading audio at the same time, iOS will route to headphones.
// set this to true to override that behavior.

- (void)setOverrideToSpeaker: (BOOL)overrideToSpeaker
{
#if TARGET_IPHONE_SIMULATOR
    return;
#else
  NSError *err;
  AVAudioSessionPortOverride overrideType = AVAudioSessionPortOverrideNone;
  
  if (!overrideToSpeaker) {
    _overrideToSpeaker = NO;
  } else {
    _overrideToSpeaker = YES;
    overrideType = AVAudioSessionPortOverrideSpeaker;
  }
  
  [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];
  
  if (err)
    [self AudioLog:@"failed to set override to speaker to %d", overrideToSpeaker];
#endif
}

- (void)setEnableMic:(BOOL)enableMic
{
  NSError* err = nil;
  _isMicrophoneEnabled = enableMic;
  
  // is there a mic to use?
  _isMicrophoneAvailable = [AVAudioSession sharedInstance].inputAvailable;
  
  if (_isMicrophoneAvailable && _isMicrophoneEnabled)
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:&err];
  else
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&err];
  
  if (err) {
    [self AudioLog:@"failed to %@ mic input: %@", (enableMic ? @"enable" : @"disable"), err.description];
  }
}

- (void)setMicrophoneGain:(float)microphoneGain
{
  if (_microphoneGain != microphoneGain) {
    _microphoneGain = microphoneGain;
    if (_isMicrophoneEnabled && _isMicrophoneAvailable) {
      NSError* error;
      if ([AVAudioSession sharedInstance].isInputGainSettable) {
        [[AVAudioSession sharedInstance] setInputGain:microphoneGain error:&error];
      }
    }
  }
}



#pragma mark - audio notif listeners

- (void)handleAudioRouteChange:(NSNotification *)notification
{
  if (AUDIO_VERBOSE)
    [self AudioLog:@"New route: %@", notification.userInfo];
  
  // reestablish speaker override if necessary
  if (_overrideToSpeaker)
    [self setOverrideToSpeaker:YES];
  
  // reestablish mic input if necessary
  [self setIsMicrophoneEnabled:_isMicrophoneEnabled];
}

- (void) handleAudioInterruption:(NSNotification *)notification
{
  NSDictionary *info = notification.userInfo;
  if (info && [info objectForKey:AVAudioSessionInterruptionTypeKey]) {
    NSUInteger type = [[info objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (type) {
      case AVAudioSessionInterruptionTypeBegan: {
        [self AudioLog:@"session interrupted"];
        [self disposeAudio];
        break;
      }
      case AVAudioSessionInterruptionTypeEnded: {
        [self AudioLog:@"session interruption ended"];
        [self startSession];
        break;
      }
    }
  }
}


#pragma mark misc log method

- (void)AudioLog: (NSString*)str, ...
{
  if (AUDIO_VERBOSE) {
    va_list argList;
    va_start(argList, str);
    NSString* formatted = [[NSString alloc] initWithFormat:str arguments:argList];
    va_end(argList);
    
    NSString* toLog = [NSString stringWithFormat:@"Audio: %@", formatted];
    NSLog(@"%@", toLog);
  }
}

@end

#pragma mark - c-style callbacks

void convertAUToFloat(AudioBufferList* input, Float32* buffer, UInt32 numFrames, UInt32* actualFrames) {
  assert(input->mNumberBuffers == AUDIO_NUM_CHANNELS);
  UInt32 inFrames = input->mBuffers[0].mDataByteSize / 4; // sizeof(SInt32) == 4
  assert(inFrames <= numFrames);
  
  // interleave
  for (UInt32 frameIndex = 0; frameIndex < inFrames; frameIndex++)
    // convert (AU is by default 8.24 fixed)
    for(UInt32 channel = 0; channel < AUDIO_NUM_CHANNELS; channel++)
      buffer[AUDIO_NUM_CHANNELS * frameIndex + channel] = ((Float32)(((SInt32 *)input->mBuffers[channel].mData)[frameIndex])) * convertToFloatCoefficient;
  
  // return
  *actualFrames = inFrames;
}


void convertAUFromFloat(AudioBufferList* input, Float32* buffer, UInt32 numFrames) {
  assert(input->mNumberBuffers == AUDIO_NUM_CHANNELS);
  UInt32 inFrames = input->mBuffers[0].mDataByteSize / 4; // sizeof(SInt32) == 4
  assert(inFrames <= numFrames);
  
  // interleave
  for (UInt32 frameIndex = 0; frameIndex < inFrames; frameIndex++)
    // convert (AU is by default 8.24 fixed)
    for (UInt32 channel = 0; channel < AUDIO_NUM_CHANNELS; channel++)
      ((SInt32*)input->mBuffers[channel].mData)[frameIndex] = (SInt32)(buffer[AUDIO_NUM_CHANNELS * frameIndex + channel] * convertFromFloatCoefficient);
}

OSStatus coreAudioCallback(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData) {
  OSStatus err = kAudioSessionNoError;
  Audio* theAudio = (__bridge Audio*)inRefCon;
  
  // render mic input.
  // convert mic input to float, or just write zeroes if there's no mic
  UInt32 numFramesRendered = 0;
  if (theAudio.isMicrophoneAvailable && theAudio.isMicrophoneEnabled) {
    err = AudioUnitRender(theAudio.audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    if (err) {
      if (AUDIO_VERBOSE)
        fprintf(stdout, "Audio: input render procedure encountered error %d\n", (int)err);
      return err;
    }
    convertAUToFloat(ioData, theFloatBuffer, AUDIO_MAX_BUFFER_SIZE, &numFramesRendered);
  } else {
    memset(theFloatBuffer, 0, inNumberFrames * AUDIO_NUM_CHANNELS * sizeof(Sample));
    numFramesRendered = inNumberFrames;
  }
  
  // total num frames sent to the audio callback to be processed
  UInt32 numFramesSent = 0;
  
  while (numFramesSent < numFramesRendered) {
    // send this many frames: MIN(the audio object's actual buffer size, number of frames remaining to send)
    UInt32 framesChunkSize = MIN(theAudio.bufferSize, numFramesRendered - numFramesSent);
    
    theAudioCallback(theFloatBuffer + (numFramesSent * AUDIO_NUM_CHANNELS), framesChunkSize, theAudioCallbackUserData);
    numFramesSent += framesChunkSize;
  }
  
  // convert back to fixed point if we are using the mic
  convertAUFromFloat(ioData, theFloatBuffer, AUDIO_MAX_BUFFER_SIZE);
  
  return err;
}

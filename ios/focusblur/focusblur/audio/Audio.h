
#import <AudioUnit/AudioUnit.h>
#include "AudioConstants.h"

#define AUDIO_VERBOSE 1

@interface Audio : NSObject

- (id) initWithSampleRate:(double)sampleRate
               bufferSize:(UInt16)bufferSize
                 callback:(AudioCallback)callback
                 userData:(void*)data;

- (BOOL)startSession;
- (BOOL)suspendSession;

@property (nonatomic, assign) BOOL overrideToSpeaker;
@property (nonatomic, assign) BOOL isMicrophoneEnabled;

@property (nonatomic, readonly) double sampleRate;
@property (nonatomic, readonly) UInt16 bufferSize;
@property (nonatomic, readonly) BOOL isMicrophoneAvailable;

@property (nonatomic, readwrite) AudioUnit audioUnit;

@property (nonatomic, assign) float microphoneGain;

@end


#import "ViewController.h"
#import "Audio.h"
#import "Analyzer.h"
#import "GLView.h"
#import "ManicTextModel.h"
#import "ManicTextView.h"
#import "Renderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

void audioCallback(Sample* buffer, unsigned int numFrames, void* userData);

@interface ViewController ()

- (void) startAnimation;
- (void) stopAnimation;

@property (nonatomic, readonly) BOOL isAnimating;

@property (nonatomic, strong) EAGLContext* context;
@property (nonatomic, strong) CADisplayLink* displayLink;
@property (nonatomic, assign) CFTimeInterval displayLinkLastTimestamp;
@property (nonatomic, strong) Audio *audio;
@property (nonatomic, assign) Renderer *renderer;
@property (nonatomic, assign) Analyzer *analyzer;

@property (nonatomic, strong) ManicTextView *vText;
@property (nonatomic, strong) ManicTextModel *textModel;

// gesture controls
@property (nonatomic, assign) float initialMicrophoneGain;
@property (nonatomic, assign) CGPoint initialTouchLocation;

@end

@implementation ViewController

- (void)loadView
{
  self.view = [[GLView alloc] init];
  self.view.frame = [[UIScreen mainScreen] bounds];
  [self.view setMultipleTouchEnabled:YES];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self _initializeOpenGL];
  [self _initializeAudio];
  
  _textModel = [[ManicTextModel alloc] init];
  _vText = [[ManicTextView alloc] initWithFrame:self.view.bounds];
  _vText.model = _textModel;
  [self.view addSubview:_vText];
  
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self startAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self stopAnimation];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  _vText.frame = self.view.bounds;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void) dealloc
{
  if (_context) {
    if ([EAGLContext currentContext] == _context)
      [EAGLContext setCurrentContext:nil];
    _context = nil;
  }
  if (_renderer) {
    delete _renderer;
    _renderer = nil;
  }
  if (_analyzer) {
    delete _analyzer;
    _analyzer = nil;
  }
}

#pragma mark - public

- (void)startAnimation
{
  if (_audio) {
    if (![_audio startSession]) {
      NSLog(@"Failed to start audio session");
    }
  }
  if (!_isAnimating) {
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_draw:)];
    if ([_displayLink respondsToSelector:@selector(setPreferredFramesPerSecond:)]) {
      [_displayLink setPreferredFramesPerSecond:60];
    } else {
      [_displayLink setFrameInterval:1.0];
    }
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    _isAnimating = YES;
  }
}

- (void)stopAnimation
{
  if (_audio) {
    [_audio suspendSession];
  }
  if (_isAnimating) {
    [self.displayLink invalidate];
    self.displayLink = nil;
    _isAnimating = NO;
  }
}

#pragma mark - touches

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
  CGSize screenSize = self.view.bounds.size;
  
  for (UITouch *touch in touches) {
    CGPoint location = [touch locationInView:self.view];
    location.y = (screenSize.height / [UIScreen mainScreen].scale) - location.y; // cocoa uses inverted y axis
    _initialTouchLocation = location;
    _initialMicrophoneGain = (_audio) ? _audio.microphoneGain : 1.0;
    _renderer->setEnableTouchFeedback(true);
    
    if (location.x < 64 && location.y < 64) {
      // corner: kill switch
      _analyzer->reset();
    }
  }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
  CGSize screenSize = self.view.bounds.size;
  
  for (UITouch *touch in touches) {
    CGPoint location = [touch locationInView:self.view];
    location.y = (screenSize.height / [UIScreen mainScreen].scale) - location.y; // cocoa uses inverted y axis
    [self _adjustMicrophoneGainFromTouchScalar:[self _absolutePointToViewportScalar:location].y];
    _renderer->touchMoved(location.y - _initialTouchLocation.y);
  }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
  CGSize screenSize = self.view.bounds.size;
  
  for (UITouch *touch in touches) {
    CGPoint location = [touch locationInView:self.view];
    location.y = (screenSize.height / [UIScreen mainScreen].scale) - location.y; // cocoa uses inverted y axis
    _renderer->setEnableTouchFeedback(false);
  }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self touchesEnded:touches withEvent:event];
}

#pragma mark - internal

- (void)_draw:(CADisplayLink *)sender
{
  CFTimeInterval dt = (_displayLinkLastTimestamp > 0) ? sender.timestamp - _displayLinkLastTimestamp : 0;
  
  [_textModel tick:dt withAnalyzer:_analyzer];
  [_vText recomputeText];
  
  _displayLinkLastTimestamp = sender.timestamp;
  [(GLView*)self.view setFramebuffer];
  
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  _renderer->render(dt, _analyzer);
  
  [(GLView*)self.view presentFramebuffer];
}

- (void)_initializeAudio
{
  _analyzer = new Analyzer();
  _audio = [[Audio alloc] initWithSampleRate:AUDIO_SAMPLE_RATE
                                  bufferSize:AUDIO_BUFFER_SIZE
                                    callback:audioCallback
                                    userData:(void *)_analyzer];
  [_audio setIsMicrophoneEnabled:YES];
}

- (void)_initializeOpenGL
{
  // set up GL context
  _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
  _renderer = new Renderer();
  _renderer->setViewport(self.view.bounds.size.width, self.view.bounds.size.height);
  
  if (!_context) {
    NSLog(@"Failed to create ES context");
  } else if (![EAGLContext setCurrentContext:_context]) {
    NSLog(@"Failed to set ES context current");
  }
  
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnableClientState(GL_VERTEX_ARRAY);
  
  // retina display?
  // scale should be 2.0 for retina displays.
  if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
    [(GLView*)self.view setScaleFactor:[UIScreen mainScreen].scale];
    _renderer->setScreenScale([UIScreen mainScreen].scale);
  }
  
  [(GLView*)self.view setContext:_context];
  [(GLView*)self.view setFramebuffer];
  
  _isAnimating = NO;
  self.displayLink = nil;
}

- (void)_adjustMicrophoneGainFromTouchScalar:(float)touchScalarY
{
  float deltaYScalar = touchScalarY - [self _absolutePointToViewportScalar:_initialTouchLocation].y;
  float finalGain = _initialMicrophoneGain + deltaYScalar;
  if (finalGain < 0.05) {
    finalGain = 0.05;
  }
  [_audio setMicrophoneGain:finalGain];
  [_textModel addInfoLineWithText:[NSString stringWithFormat:@"%.2f", finalGain]];
}

- (CGPoint)_absolutePointToViewportScalar:(CGPoint)location
{
  CGSize screenSize = self.view.bounds.size;
  return CGPointMake(
    (location.x / (screenSize.width / [UIScreen mainScreen].scale)),
    (location.y / (screenSize.height / [UIScreen mainScreen].scale))
  );
}

@end

void audioCallback(Sample* buffer, unsigned int nFrames, void* userData) {
  AudioSharedBuffer sharedBuffer;
  sharedBuffer.length = AUDIO_NUM_CHANNELS * nFrames;
  sharedBuffer.buffer = buffer;
  ((Analyzer *)userData)->copyAudioInputBuffer(&sharedBuffer);
  
  memset(buffer, 0, AUDIO_NUM_CHANNELS * nFrames * sizeof(Sample));
  return;
}

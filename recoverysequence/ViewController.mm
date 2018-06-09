
#import "ViewController.h"
#import "OGLWrapperView.h"
#import "RSChuckRunner.h"
#import "RSOSCListener.h"
#import "RSTextContainer.h"

#import "Renderer.h"
#import "AkaiMPD218Model.h"

#include <OpenGL/gl.h>

// this stub is needed to silence the system sound when keys are pressed.
@interface SilentView : NSView

@end

@implementation SilentView

- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {}

@end

@interface ViewController () <RSOSCListenerDelegate, RSChuckRunnerDelegate>

@property (nonatomic, strong) RSOSCListener *oscListener;
@property (nonatomic, assign) Renderer *renderer;
@property (nonatomic, assign) AkaiMPD218Model *model;
@property (nonatomic, strong) RSTextContainer *vTextContainer;
@property (nonatomic, strong) RSChuckRunner *chuckRunner;

@end

@implementation ViewController

- (void)loadView
{
  SilentView *view = [[SilentView alloc] initWithFrame:[[NSScreen mainScreen] frame]];
  view.wantsLayer = YES;
  self.view = view;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  OGLWrapperView *oglView = [[OGLWrapperView alloc] initWithFrame:self.view.bounds];
  [oglView setRenderCallback:&oglRenderCallback userInfo:(__bridge void *)self];
  [self.view addSubview:oglView];
  
  RSTextContainer *vTextContainer = [[RSTextContainer alloc] initWithFrame:self.view.bounds];
  _vTextContainer = vTextContainer;
  [self.view addSubview:vTextContainer];
  
  _renderer = new Renderer();
  _renderer->setViewport(self.view.bounds.size.width, self.view.bounds.size.height);
  _model = new AkaiMPD218Model();
  
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent * _Nullable(NSEvent * _Nonnull e) {
    [self flagsChanged:e];
    return e;
  }];
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull e) {
    [self keyDown:e];
    return e;
  }];
  
  _chuckRunner = [[RSChuckRunner alloc] init];
  _chuckRunner.delegate = self;
  
  _oscListener = [[RSOSCListener alloc] initWithPort:4242];
  _oscListener.delegate = self;
  [_oscListener start];
}

- (void)dealloc
{
  if (_renderer) {
    delete _renderer;
    _renderer = nil;
  }
  if (_model) {
    delete _model;
    _model = nil;
  }
}

#pragma mark - input listeners

- (void)keyDown:(NSEvent *)event
{
  NSLog(@"key pressed: '%@'", event.characters);

  // TODO: put this test code somewhere nice
  /* if ([event.characters isEqualToString:@"1"]) {
    _model->isPadActive[0] = !_model->isPadActive[0];
  } */
  
  NSInteger n = [event.characters integerValue];
  if (n > 0) {
    [_chuckRunner runPatchAtIndex:n - 1];
  } else if ([event.characters isEqualToString:@" "]) {
    [_chuckRunner killAllChuck];
  }
}

- (void)oscListener:(RSOSCListener *)listener didReceiveMessageWithAddress:(NSArray *)addressComponents arguments:(NSArray *)arguments
{
  BOOL isValid = NO;
  if (addressComponents.count) {
    if ([addressComponents.firstObject isEqualToString:@"param"]) {
      // direct param from controller
      // expect /param i i i s
      if (arguments.count == 4) {
        AkaiMPD218ParamType type = (AkaiMPD218ParamType)[arguments[0] intValue];
        int param = [arguments[1] intValue];
        int value = [arguments[2] intValue];
        NSString *desc = arguments[3];
        _model->ingestOscMessage(type, param, value);
        [_vTextContainer addTextLine:[NSString stringWithFormat:@"%d %d %@", param, value, desc]];
        isValid = YES;
      }
    } else if ([addressComponents.firstObject isEqualToString:@"mouse"]) {
      // allow debug mouse control
      // expect /mouse i i
      if (arguments.count == 2) {
        int dx = [arguments[0] intValue];
        int dy = [arguments[1] intValue];
        _model->ingestDebugMouseMessage(dx, dy);
        [_vTextContainer addTextLine:[NSString stringWithFormat:@"%d %d", dx, dy]];
        isValid = YES;
      }
    }
  }
  if (!isValid) {
    NSLog(@"Unrecognized osc message: /%@ %@", [addressComponents componentsJoinedByString:@"/"], [arguments componentsJoinedByString:@" "]);
  }
}

- (void)chuckRunnerDidUpdateStatus:(RSChuckRunner *)runner
{
  if (_chuckRunner.status) {
    [_vTextContainer addTextLine:_chuckRunner.status];
  }
}

#pragma mark - ogl callback

static void oglRenderCallback(double dt, void *userInfo) {
  ViewController *vc = (__bridge ViewController *)userInfo;
  vc.renderer->render(dt, vc.model);
}

@end

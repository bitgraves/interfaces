
#import "ViewController.h"
#import "OGLWrapperView.h"
#import "RSOSCListener.h"

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

@interface ViewController ()

@property (nonatomic, strong) RSOSCListener *oscListener;
@property (nonatomic, assign) Renderer *renderer;
@property (nonatomic, assign) AkaiMPD218Model *model;

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
  
  _renderer = new Renderer();
  _model = new AkaiMPD218Model();
  
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent * _Nullable(NSEvent * _Nonnull e) {
    [self flagsChanged:e];
    return e;
  }];
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull e) {
    [self keyDown:e];
    return e;
  }];
  
  _oscListener = [[RSOSCListener alloc] initWithPort:4242];
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

- (void)keyDown:(NSEvent *)event
{
  NSLog(@"key pressed: %@", event.characters);
}

static void oglRenderCallback(double dt, void *userInfo) {
  ViewController *vc = (__bridge ViewController *)userInfo;
  vc.renderer->render(vc.model);
}

@end

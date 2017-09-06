
#import "ViewController.h"
#import "OGLWrapperView.h"
#import "RSOSCListener.h"

// this stub is needed to silence the system sound when keys are pressed.
@interface SilentView : NSView

@end

@implementation SilentView

- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {}

@end

@interface ViewController ()

@property (nonatomic, strong) RSOSCListener *oscListener;

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
  [self.view addSubview:oglView];
  
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

- (void)keyDown:(NSEvent *)event
{
  NSLog(@"key pressed: %@", event.characters);
}

@end

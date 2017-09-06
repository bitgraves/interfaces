
#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) NSWindow *window;

@end

// this stub is needed to prevent a stupid system sound when keys are pressed
@interface SilentWindow : NSWindow

@end

@implementation SilentWindow

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  NSRect mainDisplayRect = [[NSScreen mainScreen] frame];
  self.window = [[SilentWindow alloc] initWithContentRect:mainDisplayRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
  [_window setLevel:NSMainMenuWindowLevel+1];
  [_window setOpaque:YES];
  [_window setHidesOnDeactivate:YES];
  
  ViewController *vc = [[ViewController alloc] init];
  NSRect viewRect = NSMakeRect(0.0, 0.0, mainDisplayRect.size.width, mainDisplayRect.size.height);
  [vc.view setFrame:viewRect];
  [_window setContentView:vc.view];
  _window.initialFirstResponder = vc.view;
  [_window makeKeyAndOrderFront:self];
  
  [self _enableFullScreen:YES];
}

- (void)_enableFullScreen:(BOOL)enable
{
  // TODO: most of this method
  if (enable) {
    [NSCursor hide];
  } else {
    [NSCursor unhide];
  }
}

+ (NSMenu *)makeMainMenu
{
  NSMenu *mainMenu = [[NSMenu alloc] init];
  NSMenuItem *mainMenuItem = [[NSMenuItem alloc] initWithTitle:@"Application" action:nil keyEquivalent:@""];
  [mainMenu addItem:mainMenuItem];
  
  NSMenu *appMenu = [[NSMenu alloc] init];
  mainMenuItem.submenu = appMenu;
  
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
  quitItem.target = [NSApplication sharedApplication];
  [appMenu addItem:quitItem];
  return mainMenu;
}


@end

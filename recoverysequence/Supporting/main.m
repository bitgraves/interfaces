
#import <Cocoa/Cocoa.h>

#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
  // return NSApplicationMain(argc, argv);
  @autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    application.mainMenu = [AppDelegate makeMainMenu];
    [application setDelegate:appDelegate];
    [application run];
  }
  
  return EXIT_SUCCESS;
}

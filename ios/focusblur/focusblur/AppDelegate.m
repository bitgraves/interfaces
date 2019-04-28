
#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) ViewController *viewController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.viewController = [[ViewController alloc] init];
  self.window.rootViewController = self.viewController;
  [self.window addSubview:self.viewController.view];
  [self.window makeKeyAndVisible];
  return YES;
}

@end

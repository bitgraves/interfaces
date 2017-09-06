
#import <Foundation/Foundation.h>

@interface RSOSCListener : NSObject

- (instancetype)initWithPort:(UInt16)port NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)start;
- (void)stop;

@end

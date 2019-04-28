
#import <Foundation/Foundation.h>

@class RSOSCListener;

@protocol RSOSCListenerDelegate <NSObject>

- (void)oscListener:(RSOSCListener *)listener didReceiveMessageWithAddress:(NSArray *)addressComponents arguments:(NSArray *)arguments;

@end

@interface RSOSCListener : NSObject

- (instancetype)initWithPort:(UInt16)port NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)start;
- (void)stop;

@property (nonatomic, assign) id<RSOSCListenerDelegate> delegate;

@end

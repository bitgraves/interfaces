
#import <Foundation/Foundation.h>

@interface ManicTextLine : NSObject

+ (instancetype)lineWithText:(NSString *)text initialPower:(float)power;
- (void)tick:(CFTimeInterval)dt;

@property (nonatomic, readonly) NSString *text;

@end

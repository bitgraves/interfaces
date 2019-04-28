
#import <Foundation/Foundation.h>

@interface ManicTextModel : NSObject

- (void)tick:(CFTimeInterval)dt withAnalyzer:(void *)analyzer;
- (NSString *)text;
- (void)addInfoLineWithText:(NSString *)text;

@end

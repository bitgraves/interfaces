
#import <Foundation/Foundation.h>

@interface RSChuckRunner : NSObject

@property (nonatomic, readonly) NSString *status;

- (void)runPatchAtIndex:(NSUInteger)index;
- (void)runTestPatch;
- (void)killAllChuck;

@end

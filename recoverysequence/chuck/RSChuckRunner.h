
#import <Foundation/Foundation.h>

@class RSChuckRunner;

@protocol RSChuckRunnerDelegate <NSObject>

- (void)chuckRunnerDidUpdateStatus:(RSChuckRunner *)runner;

@end

@interface RSChuckRunner : NSObject

@property (nonatomic, assign) id<RSChuckRunnerDelegate> delegate;
@property (nonatomic, readonly) NSString *status;

- (void)runPatchAtIndex:(NSUInteger)index;
- (void)runTestPatch;
- (void)killAllChuck;

@end

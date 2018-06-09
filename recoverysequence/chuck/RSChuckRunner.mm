
#import "RSChuckRunner.h"
#import "Task.h"

// TODO: move to plist
NSString * const kTestPatchDir = @"/Users/ben/Documents/code/bitgraves/recoverysequence/recoverysequence/chuck";
NSString * const kShowPatchDir = @"/Users/ben/Documents/audio/chuck/bitgraves/show/june2018";
NSString * const kCmdChuckPath = @"/usr/local/bin/chuck";
NSString * const kCmdKillallPath = @"/usr/bin/killall";

@interface RSChuckRunner ()

@property (nonatomic, strong) NSArray<NSString *> *patches;
@property (nonatomic, strong) NSString *status;

@end

@implementation RSChuckRunner

- (instancetype)init
{
  if (self = [super init]) {
    _patches = @[@"itself", @"dawn0", @"crystal", @"processing", @"tremor", @"retina"];
  }
  return self;
}

- (void)killAllChuck
{
  [self _runCommand:kCmdKillallPath withArg:@"chuck"];
}

- (void)runTestPatch
{
  NSString *patchPath = [NSString stringWithFormat:@"%@/%@", kTestPatchDir, @"test.ck"];
  [self _runCommand:kCmdChuckPath withArg:patchPath];
}

- (void)runPatchAtIndex:(NSUInteger)index
{
  if (index < _patches.count) {
    NSString *patchPath = [NSString stringWithFormat:@"%@/%@.ck", kShowPatchDir, _patches[index]];
    [self _runCommand:kCmdChuckPath withArg:patchPath];
  }
}

#pragma mark - internal

- (void)_runCommand:(NSString *)command withArg:(NSString *)arg
{
  Task t([command UTF8String], [arg UTF8String]);
  t.run();
  
  NSString *formattedArg = ([arg rangeOfString:@"/"].location == NSNotFound) ? arg : [arg lastPathComponent];
  self.status = [NSString stringWithFormat:@"%@ %@", [command lastPathComponent], formattedArg];
}

- (void)setStatus:(NSString *)status
{
  _status = status;
  if (_delegate) {
    [_delegate chuckRunnerDidUpdateStatus:self];
  }
}

@end

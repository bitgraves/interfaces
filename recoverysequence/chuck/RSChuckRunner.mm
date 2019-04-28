
#import "RSChuckRunner.h"
#import "Task.h"

// TODO: move to plist
NSString * const kTestPatchDir = @"/Users/ben/Documents/code/bitgraves/recoverysequence/recoverysequence/chuck";
NSString * const kShowPatchDir = @"/Users/ben/Documents/audio/chuck/bitgraves/show/apr2019";
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
    _patches = @[@"flash", @"echo", @"interlude", @"linda"];
  }
  return self;
}

- (void)killAllChuck
{
  [self _runCommand:[NSString stringWithFormat:@"%@ chuck", kCmdKillallPath]];
  self.status = @"killall chuck";
}

- (void)runTestPatch
{
  NSString *patchPath = [NSString stringWithFormat:@"%@/%@", kTestPatchDir, @"test.ck"];
  [self _runChuckWithPatch:patchPath fromDirectory:kTestPatchDir];
}

- (void)runPatchAtIndex:(NSUInteger)index
{
  if (index < _patches.count) {
    NSString *patchPath = [NSString stringWithFormat:@"%@/%@.ck", kShowPatchDir, _patches[index]];
    [self _runChuckWithPatch:patchPath fromDirectory:kShowPatchDir];
  }
}

#pragma mark - internal

- (void)_runChuckWithPatch:(NSString *)patchPath fromDirectory:(NSString *)workingDirectory
{
  // chuck working dir matters for loading resources with relative paths from inside the chuck patch.
  [self _runCommand:[NSString stringWithFormat:@"cd %@ && %@ --adc:3 --bufsize:1024 %@", workingDirectory, kCmdChuckPath, patchPath]];
  self.status = [NSString stringWithFormat:@"chuck %@", [patchPath lastPathComponent]];
}

- (void)_runCommand:(NSString *)command
{
  Task t([command UTF8String]);
  t.run();
}

- (void)setStatus:(NSString *)status
{
  _status = status;
  if (_delegate) {
    [_delegate chuckRunnerDidUpdateStatus:self];
  }
}

@end

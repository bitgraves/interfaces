
#import "RSChuckRunner.h"
#import "Task.h"

// TODO: move to plist
NSString * const kTestPatchDir = @"/Users/ben/Documents/code/bitgraves/recoverysequence/recoverysequence/chuck";
NSString * const kShowPatchDir = @"/Users/ben/Documents/audio/chuck/bitgraves/show/june2018";
NSString * const kCmdChuckPath = @"/usr/local/bin/chuck";
NSString * const kCmdKillallPath = @"/usr/bin/killall";

@interface RSChuckRunner ()

@property (nonatomic, strong) NSString *status;

@end

@implementation RSChuckRunner

- (void)killAllChuck
{
  Task t([kCmdKillallPath UTF8String], "chuck");
  t.run();
  _status = @"killall chuck";
}

- (void)runTestPatch
{
  NSString *patchPath = [NSString stringWithFormat:@"%@/%@", kTestPatchDir, @"test.ck"];
  Task t([kCmdChuckPath UTF8String], [patchPath UTF8String]);
  t.run();
  _status = [NSString stringWithFormat:@"chuck %@", patchPath];
}

- (void)runPatchAtIndex:(NSUInteger)index
{
  // TODO
}

@end

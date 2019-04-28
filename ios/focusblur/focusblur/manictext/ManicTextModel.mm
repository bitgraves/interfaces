
#import "ManicTextModel.h"
#import "ManicTextLine.h"
#include "Analyzer.h"

#import <UIKit/UIDevice.h>

@interface ManicTextModel ()

@property (nonatomic, strong) NSArray<NSString *> *availableLines;
@property (nonatomic, strong) NSMutableArray<ManicTextLine *> *lines;
@property (nonatomic, strong) NSDate *dtmLastAddedLine;

@end

@implementation ManicTextModel

- (instancetype)init
{
  if (self = [super init]) {
    _lines = [NSMutableArray arrayWithCapacity:[self _maxNumLines]];
    [self _loadAllLines];
    for (NSInteger ii = 0, nn = [self _maxNumLines]; ii < nn; ii++) {
      [self _addLineWithPower:0.2f];
    }
  }
  return self;
}

- (NSString *)text
{
  NSArray *linesText = [_lines valueForKey:@"text"];
  return [linesText componentsJoinedByString:@"\n"];
}

- (void)tick:(CFTimeInterval)dt withAnalyzer:(void *)analyzer
{
  Analyzer *ana = (Analyzer *)analyzer;
  float power = ana->getPower();
  float threshold = fmax(0.1f, 0.3f - (ana->getSlowRollingPower() * 0.2f));
  if (power > threshold) {
    // if it's been over a half second, guarantee add a line; otherwise, sooner is less probability.
    NSTimeInterval sinceLastLine = (_dtmLastAddedLine) ? [[NSDate date] timeIntervalSinceDate:_dtmLastAddedLine] : 1000;
    BOOL addLine = NO;
    if (sinceLastLine > 0.5) {
      addLine = YES;
    } else {
      // lower -> lower prob.
      float randf = (float)rand() / (float)RAND_MAX;
      if (randf < (sinceLastLine / 0.5)) {
        addLine = YES;
      }
    }
    if (addLine) {
      [self _addLineWithPower:power];
    }
  }
  @synchronized (_lines) {
    [_lines enumerateObjectsUsingBlock:^(ManicTextLine * _Nonnull line, NSUInteger idx, BOOL * _Nonnull stop) {
      [line tick:dt];
    }];
  }
}

- (void)addInfoLineWithText:(NSString *)text
{
  ManicTextLine *line = [ManicTextLine lineWithText:text initialPower:0.5f];
  [self _addLine:line];
}

#pragma mark - internal

- (NSUInteger)_maxNumLines
{
  UIUserInterfaceIdiom idiom = UI_USER_INTERFACE_IDIOM();
  switch (idiom) {
    case UIUserInterfaceIdiomPhone: default:
      return 16;
    case UIUserInterfaceIdiomPad:
      return 48;
  }
}

- (void)_addLineWithPower:(float)power
{
  ManicTextLine *line = [ManicTextLine lineWithText:[self _randomLine] initialPower:power];
  [self _addLine:line];
}

- (void)_addLine:(ManicTextLine *)line
{
  @synchronized (_lines) {
    [_lines addObject:line];
    if (_lines.count > [self _maxNumLines]) {
      [_lines removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _lines.count - [self _maxNumLines])]];
    }
    _dtmLastAddedLine = [NSDate date];
  }
}

- (NSString *)_randomLine
{
  NSUInteger idx = rand() % _availableLines.count;
  return _availableLines[idx];
}

- (void)_loadAllLines
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"corpus" ofType:@"txt"];
  NSError *err;
  NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
  NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@"\n.?!"];
  NSArray<NSString *> *rawLines = [contents componentsSeparatedByCharactersInSet:separators];
  NSMutableArray<NSString *> *cleanLines = [NSMutableArray arrayWithCapacity:rawLines.count];
  [rawLines enumerateObjectsUsingBlock:^(NSString * _Nonnull rawLine, NSUInteger idx, BOOL * _Nonnull stop) {
    if (rawLine.length > 1 && rawLine.length < 180) {
      [cleanLines addObject:rawLine];
    }
  }];
  _availableLines = cleanLines;
}

@end


#import "ManicTextLine.h"

@interface ManicTextLine ()

@property (nonatomic, strong) NSString *initialText;
@property (nonatomic, strong) NSMutableString *mutableText;
@property (nonatomic, assign) CFTimeInterval ttl;
@property (nonatomic, assign) float initialPower;

@end

@implementation ManicTextLine

+ (instancetype)lineWithText:(NSString *)text initialPower:(float)power
{
  ManicTextLine *line = [[ManicTextLine alloc] init];
  line.text = text;
  line.initialPower = power;
  [line _garbleText];
  line.ttl = 1.0f + ((float)rand() / (float)RAND_MAX) * power * 10.0;
  if (((float)rand() / (float)RAND_MAX) < 0.1) {
    line.ttl += 5.0f;
  }
  return line;
}

- (instancetype)init
{
  if (self = [super init]) {
    _ttl = 0;
  }
  return self;
}

- (void)tick:(CFTimeInterval)dt
{
  _ttl -= dt;
  // if energy is low, occasionally switch text
  // if it's high, switch text frequently
  float randf = (float)rand() / (float)RAND_MAX;
  float threshold = MIN(0.95f, _initialPower * 2.0f * dt);
  if (randf < threshold) {
    [self _garbleText];
  }
  if (_ttl <= 0) {
    [self setText:@""];
  }
}

- (NSString *)text
{
  return _mutableText;
}

#pragma mark - internal

- (void)setText:(NSString *)text
{
  _initialText = text;
  _mutableText = [NSMutableString stringWithString:text];
}

- (void)_garbleText
{
  // if energy is high, keep clarity (dont replace - low threshold)
  // if energy is low, be more obscure (replace - high threshold)
  float threshold = (float)MIN(1, 1.0f - _initialPower) * 0.15;
  for (NSUInteger ii = 0, nn = _mutableText.length; ii < nn; ii++) {
    NSRange replaceChar = NSMakeRange(ii, 1);
    float randf = (float)rand() / (float)RAND_MAX;
    if (randf < threshold) {
      [_mutableText replaceCharactersInRange:replaceChar withString:[self _randomCharacter]];
    } else {
      [_mutableText replaceCharactersInRange:replaceChar
                                  withString:[_initialText substringWithRange:replaceChar]];
    }
  }
}

- (NSString *)_randomCharacter
{
  int randomUnicodeDigit = 21 + (arc4random() % 90);
  unichar val = randomUnicodeDigit % (0xffffu + 1);
  return [NSString stringWithFormat:@"%C", val];
}

@end

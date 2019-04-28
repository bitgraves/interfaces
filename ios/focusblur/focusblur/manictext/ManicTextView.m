
#import "ManicTextView.h"

@interface ManicTextView ()

@property (nonatomic, strong) UILabel *lblText;

@end

@implementation ManicTextView

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    _lblText = [[UILabel alloc] initWithFrame:self.bounds];
    _lblText.textColor = [UIColor whiteColor];
    _lblText.font = [UIFont fontWithName:@"Courier-Bold" size:16.0f];
    _lblText.numberOfLines = 0;
    [self addSubview:_lblText];
    
    // TODO
    _lblText.text = @"Wake up neo";
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _lblText.frame = self.bounds;
  [_lblText sizeToFit];
}

- (void)recomputeText
{
  dispatch_async(dispatch_get_main_queue(), ^{
    _lblText.frame = self.bounds;
    _lblText.text = [_model text];
    [_lblText sizeToFit];
  });
}

@end

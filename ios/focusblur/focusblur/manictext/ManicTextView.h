
#import <UIKit/UIKit.h>
#import "ManicTextModel.h"

@interface ManicTextView : UIView

@property (nonatomic, strong) ManicTextModel *model;

- (void)recomputeText;

@end

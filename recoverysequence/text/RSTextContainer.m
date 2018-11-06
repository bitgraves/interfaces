#import "RSTextContainer.h"

@interface RSTextContainer ()

@property (nonatomic, strong) NSMutableArray<NSString *> *lines;
@property (nonatomic, strong) NSTextView *vText;

@end

#define MAX_NUM_LINES 30

@implementation RSTextContainer

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect]) {
    _lines = [NSMutableArray array];
    [self _configureViews];
  }
  return self;
}

- (void)addTextLine:(NSString *)text
{
  [_lines addObject:text];
  if (_lines.count > MAX_NUM_LINES) {
    [_lines removeObjectAtIndex:0];
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_vText.string = [self->_lines componentsJoinedByString:@"\n"];
  });
}

#pragma mark - internal

- (void)_configureViews
{
  self.wantsLayer = YES;
  self.layer.backgroundColor = [NSColor clearColor].CGColor;
  
  self.vText = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 512, self.frame.size.height)];
  [_vText setEditable:NO];
  _vText.backgroundColor = [NSColor clearColor];
  [_vText setSelectable:NO];
  [_vText setTextColor:[NSColor redColor]];
  // CourierNewPS-BoldMT, Menlo-Bold, Menlo-Regular
  //     NSLog(@"%@", [[NSFontManager sharedFontManager] availableFonts]);
  [_vText setFont:[NSFont fontWithName:@"Menlo" size:24.0]];
  [self addSubview:_vText];
  
  // add some empty lines
  for (NSUInteger ii = 0; ii < MAX_NUM_LINES; ii++) {
    [_lines addObject:@""];
  }
}

@end

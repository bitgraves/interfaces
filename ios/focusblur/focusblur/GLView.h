
#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLView : UIView

@property (nonatomic, strong) EAGLContext* context;
@property (nonatomic, readonly) CGSize frameBufferSize;

- (void)setScaleFactor: (CGFloat)scale;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end

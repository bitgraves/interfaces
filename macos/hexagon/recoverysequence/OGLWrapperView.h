/**
 *  A NSView with a c-style OpenGL render callback which is attached to a CVDisplayLink.
 */
#import <Cocoa/Cocoa.h>

typedef void (* OGLRenderCallback)(double dt, void* userInfo);

@interface OGLWrapperView : NSOpenGLView

- (void)setRenderCallback:(OGLRenderCallback)callback userInfo:(void *)userInfo;

@end

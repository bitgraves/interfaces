
#import "OGLWrapperView.h"

#include <OpenGL/gl.h>
#include <CoreVideo/CVDisplayLink.h>

@interface OGLWrapperView ()
{
  CVDisplayLinkRef _displayLink;
}

@property (nonatomic, assign) CFTimeInterval dt;

@end

@implementation OGLWrapperView

- (instancetype)initWithFrame:(NSRect)frameRect
{
  NSOpenGLPixelFormatAttribute attributes[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFAColorSize, 24,
    NSOpenGLPFAAlphaSize, 8,
    NSOpenGLPFADepthSize, 8,
    NSOpenGLPFAAccelerated,
    0
  };
  NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  if (self = [super initWithFrame:frameRect pixelFormat:format]) {
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    CVDisplayLinkSetOutputCallback(_displayLink, &DisplayLinkCallback, (__bridge void *)self);
    
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);
  }
  return self;
}

- (void)prepareOpenGL
{
  if ([self lockFocusIfCanDraw]) {
    [[self openGLContext] makeCurrentContext];
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [[self openGLContext] update];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    [self unlockFocus];
  }
  // Activate the display link
  CVDisplayLinkStart(_displayLink);
}

- (void)dealloc
{
  CVDisplayLinkStop(_displayLink);
  CVDisplayLinkRelease(_displayLink);
}

- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
  if ([self lockFocusIfCanDraw]) {
    [[self openGLContext] makeCurrentContext];
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // BEN
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glColor3f(1.0f, 0.85f, 0.35f);
    glBegin(GL_TRIANGLES);
    {
      glVertex3f(0.0, 0.6, 0.0);
      glVertex3f(-0.2, -0.3, 0.0);
      glVertex3f(0.2, -0.3 ,0.0);
    }
    glEnd();
    glFlush();
    
    [[self openGLContext] flushBuffer];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    [self unlockFocus];
  }
}

#pragma mark - CV callback

- (CVReturn)_getFrameForTime:(const CVTimeStamp*)outputTime
{
  _dt = 1.0 / (outputTime->rateScalar * (double)outputTime->videoTimeScale / (double)outputTime->videoRefreshPeriod);
  [self drawRect:[self bounds]];
  
  return kCVReturnSuccess;
}

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
  @autoreleasepool {
    CVReturn result = [(__bridge OGLWrapperView *)displayLinkContext _getFrameForTime:outputTime];
    return result;
  }
}

@end

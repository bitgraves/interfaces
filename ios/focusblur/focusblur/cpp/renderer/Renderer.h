
#ifndef __RENDERER_H__
#define __RENDERER_H__

#include "Analyzer.h"

#include <list>

class LineParticle;
class ScrollingBlockGroup;
using std::list;

class Renderer {
public:
  Renderer();
  ~Renderer();

  void render(double dt, Analyzer *ana);
  void setViewport(float width, float height);
  void setScreenScale(float scale);
  
  // TODO: some kind of env class in cpp-land
  float _viewportWidth, _viewportHeight;
  
  void setEnableTouchFeedback(bool enable);
  void touchMoved(float deltaY);
  
protected:
  void _setOrthoProjection();
  
private:
  double _time;
  float _screenScale;
  list<LineParticle *> _particles;
  
  void _renderSimpleFFTGraph(Analyzer *ana, bool normalize);
  void _renderSimplePower(Analyzer *ana);
  void _render(double dt, Analyzer *ana);
  void _maybeRenderTouchFeedback();
  void _maybeChangeNumBlocks(Analyzer *ana);
  
  ScrollingBlockGroup *_scrollingBlocks;
  bool _enableTouchFeedback;
  float _touchDy;
};

#endif

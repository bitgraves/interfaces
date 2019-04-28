
#ifndef __SCROLLING_BLOCK_H__
#define __SCROLLING_BLOCK_H__

#import "Analyzer.h"

class Renderer;

class ScrollingBlock {
public:
  ScrollingBlock(Renderer *renderer);
  void setBounds(float xPercent, float widthPercent);
  void render(Analyzer *ana);
private:
  Renderer *_renderer;
  bool _willChangeVelocity;
  float _y, _vy;
  float _brightness;
  
  // x and width in proportion to viewport
  float _xPercent, _widthPercent;
};

#endif

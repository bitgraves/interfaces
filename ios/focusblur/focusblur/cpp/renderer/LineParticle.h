
#ifndef __LINEPARTICLE_H__
#define __LINEPARTICLE_H__

#include "Renderer.h"

class LineParticle {
public:
  LineParticle(Renderer *renderer);
  bool isAlive();
  void render(double dt);
  
private:
  Renderer *_renderer;
  float _ttl;
  float _y, _vy, _ay;
};

#endif

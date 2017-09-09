
#ifndef renderer_h
#define renderer_h

#include <stdio.h>
#include "AkaiMPD218Model.h"

class Renderer {
public:
  Renderer();
  void render(double dt, AkaiMPD218Model* model);
  void setViewport(float width, float height);
  
private:
  float _viewportWidth, _viewportHeight;
  double _time;
  float _scale;
  void _renderFancyHexagon(AkaiMPD218Model *model);
  void _renderHexagon(AkaiMPD218Model *model);
  void _renderDebug(AkaiMPD218Model* model);
};

#endif /* renderer_h */

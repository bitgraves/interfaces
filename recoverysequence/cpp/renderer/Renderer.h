
#ifndef renderer_h
#define renderer_h

#include <stdio.h>
#include "AkaiMPD218Model.h"

class Renderer {
public:
  Renderer();
  void render(AkaiMPD218Model* model);
  void setViewport(float width, float height);
  
private:
  float _viewportWidth, _viewportHeight;
  void _renderHexagon(AkaiMPD218Model *model);
  void _renderDebug(AkaiMPD218Model* model);
};

#endif /* renderer_h */

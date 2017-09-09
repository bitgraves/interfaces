
#include "Renderer.h"

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

void Renderer::render(AkaiMPD218Model *model) {
  float sqSide = 0.2;
  float totalWidth = sqSide * AkaiMPD218Model::NUM_KNOBS;
  for (unsigned int ii = 0; ii < AkaiMPD218Model::NUM_KNOBS; ii++) {
    float alpha = (float)(model->knobValues[ii]) / 128.0;
    float xi = (totalWidth * -0.5) + (ii * sqSide);
    float s = (sqSide * 0.97);
    float partialS = 1 * alpha;
    glColor4f(1, 1, 1, 0.1);
    glRectf(xi, -0.5, xi + s, 0.5);
    if (ii == model->knobIndexLastUpdated) {
      glColor4f(1, 0, 0, alpha);
    } else {
      glColor4f(1, 1, 1, alpha);
    }
    glRectf(xi, -0.5, xi + s, -0.5 + partialS);
  }
}

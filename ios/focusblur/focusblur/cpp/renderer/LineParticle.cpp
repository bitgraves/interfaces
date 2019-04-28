
#include "LineParticle.h"

#include <cstdlib>
#include <OpenGLES/ES1/gl.h>

LineParticle::LineParticle(Renderer *renderer) : _renderer(renderer) {
  _ttl = 1.5f;
  _y = ((float)rand() / (float)RAND_MAX) * renderer->_viewportHeight;
  _vy = -3.0 + (((float)rand() / (float)RAND_MAX) * 6.0);
  _ay = -0.4 + (((float)rand() / (float)RAND_MAX) * 0.8);
}

bool LineParticle::isAlive() {
  return (_ttl > 0);
}

void LineParticle::render(double dt) {
  glColor4f(1, 1, 1, 1);
  GLfloat vertices[2 * 2];
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  vertices[0] = 0; vertices[1] = _y;
  vertices[2] = _renderer->_viewportWidth; vertices[3] = _y;
  glDrawArrays(GL_LINE_LOOP, 0, 2);
  
  _ttl -= dt;
  _vy += _ay;
  _y += _vy;
}

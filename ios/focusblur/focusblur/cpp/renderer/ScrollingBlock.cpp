
#include "Renderer.h"
#include "ScrollingBlock.h"

#include <OpenGLES/ES1/gl.h>

ScrollingBlock::ScrollingBlock(Renderer *renderer) {
  _renderer = renderer;
  _y = 0;
  _vy = 20;
  _brightness = 0;
  _willChangeVelocity = true;
  this->setBounds(0, 1);
}

void ScrollingBlock::setBounds(float xPercent, float widthPercent) {
  _xPercent = xPercent;
  _widthPercent = widthPercent;
}

void ScrollingBlock::render(Analyzer *ana) {
  float power = ana->getPower();
  if (power >= 0.3f) {
    float randf = (float)rand() / (float)RAND_MAX;
    if (randf < 0.02) {
      _willChangeVelocity = true;
    }
  }
  float red = (power >= 0.8f) ? 1.0 : power / 0.8f;
  if (red > _brightness) {
    _brightness = red;
  } else {
    _brightness *= 0.9f;
  }
  float x = _xPercent * _renderer->_viewportWidth, width = _widthPercent * _renderer->_viewportWidth;
  
  GLfloat vertices[4 * 2];
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  {
    glColor4f(1, 0, 0, 0.2 + (_brightness * 0.3));
    vertices[0] = x; vertices[1] = _y;
    vertices[2] = width; vertices[3] = _y;
    vertices[4] = x; vertices[5] = _y + _renderer->_viewportHeight; // bottom left
    vertices[6] = width; vertices[7] = _y + _renderer->_viewportHeight; // bottom right
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  }
  if (ana->getSlowRollingPower() > 0.6
      && ana->getHiPower() > 0.1
      && ana->getHiPower() > ana->getLowPower() * 0.6) {
    float randf = (float)rand() / (float)RAND_MAX;
    float xOffset = -40.0f + randf * 80.0f;
    glBlendFunc(GL_ONE, GL_ONE);
    {
      glColor4f(0, 0, 0.2 + (_brightness * 0.3), 0.2 + (_brightness * 0.3));
      vertices[0] = x + xOffset;
      vertices[2] = width + xOffset;
      vertices[4] = x + xOffset;
      vertices[6] = width + xOffset;
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
  }

  _y += _vy;
  bool mightChangeVelocity = false;
  if (_y > _renderer->_viewportHeight && _vy > 0) {
    _y = -_renderer->_viewportHeight;
    mightChangeVelocity = true;
  } else if (_y < -_renderer->_viewportHeight && _vy <= 0) {
    _y = _renderer->_viewportHeight;
    mightChangeVelocity = true;
  }
  if (mightChangeVelocity && _willChangeVelocity) {
    _willChangeVelocity = false;
    float randf = (float)rand() / (float)RAND_MAX;
    _vy = 20.0 + randf * 20.0;
    randf = (float)rand() / (float)RAND_MAX;
    if (randf < 0.5) {
      _vy *= -1;
    }
    if (randf < 0.08 && ana->getSlowRollingPower() > 0.7) {
      // sometimes go way faster
      _vy *= 5;
    }
  }
}

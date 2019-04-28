
#include "chuck_fft.h"
#include "Renderer.h"
#include "LineParticle.h"
#import "ScrollingBlockGroup.h"

#include <math.h>
#include <OpenGLES/ES1/gl.h>

Renderer::Renderer() {
  _time = 0;
  _screenScale = 1;

  this->setViewport(0, 0);
  _scrollingBlocks = new ScrollingBlockGroup(this);
  _scrollingBlocks->setNumBlocks(1);
  
  // touch feedbcak
  _enableTouchFeedback = false;
  _touchDy = 0;
}

Renderer::~Renderer() {
  for (list<LineParticle *>::iterator it = _particles.begin(); it != _particles.end(); ++it) {
    LineParticle *particle = *it;
    delete particle;
  }
  _particles.clear();
  delete _scrollingBlocks;
}

void Renderer::setScreenScale(float scale) {
  _screenScale = scale;
}

void Renderer::setViewport(float width, float height) {
  _viewportWidth = width;
  _viewportHeight = height;
}

void Renderer::render(double dt, Analyzer *ana) {
  ana->prepareToRender();
  this->_setOrthoProjection();
  this->_render(dt, ana);
  if (this->_enableTouchFeedback) {
    this->_renderSimplePower(ana);
  }
}

void Renderer::setEnableTouchFeedback(bool enable) {
  _enableTouchFeedback = enable;
}

void Renderer::touchMoved(float deltaY) {
  _touchDy = deltaY;
}

#pragma mark - internal

void Renderer::_render(double dt, Analyzer *ana) {
  if (ana->getSlowRollingPower() > 0.35) {
    _scrollingBlocks->render(ana);
    this->_maybeChangeNumBlocks(ana);
  }
  float randf = (float)rand() / (float)RAND_MAX;
  float threshold = 0.2f;
  if (ana->getHiPower() > ana->getLowPower()) {
    // produce more lines if spectrum has high bias
    threshold = 0.3f;
  }
  if (randf < ana->getPower() * threshold) {
    _particles.push_back(new LineParticle(this));
  }
  list<LineParticle *>::iterator it = _particles.begin();
  while (it != _particles.end()) {
    LineParticle* p = *it;
    p->render(dt);
    
    if (!p->isAlive()) {
      delete *it;
      _particles.erase(it++);
    } else {
      it++;
    }
  }
  
  this->_maybeRenderTouchFeedback();
}

void Renderer::_maybeChangeNumBlocks(Analyzer *ana) {
  if (ana->getPower() > 0.6f) {
    float randf = (float)rand() / (float)RAND_MAX;
    if (randf < 0.05) {
      int newNumBlocks = 1;
      if (randf < 0.04) {
        randf = (float)rand() / (float)RAND_MAX;
        float maxNumBlocks = fmin(fmax(1, ana->getSlowRollingPower() * 7.0), 4);
        newNumBlocks = ceilf(randf * maxNumBlocks);
      }
      _scrollingBlocks->setNumBlocks(newNumBlocks);
    }
  }
}

void Renderer::_renderSimpleFFTGraph(Analyzer *ana, bool normalize) {
  glColor4f(1, 0, 0, 1);
  
  GLfloat vertices[4 * 2];
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  float normalizer = 0.5f;
  for (int xx = 0, ii = 0; xx < _viewportWidth && ii < Analyzer::kFFTSize / 2; xx += 8, ii++) {
    float mag = (_viewportHeight - 32) * sqrt(25 * cmp_abs(*(ana->getFFTValue(ii))));
    if (normalize) {
      mag *= normalizer;
      normalizer += (1.0f - normalizer) * 0.3f;
    }
    vertices[0] = xx; vertices[1] = 0; // top left
    vertices[2] = xx + 6; vertices[3] = 0; // top right
    vertices[4] = xx + 6; vertices[5] = 32 + mag; // bottom right
    vertices[6] = xx; vertices[7] = 32 + mag; // bottom left
    
    glDrawArrays(GL_LINE_LOOP, 0, 4);
  }
}

void Renderer::_renderSimplePower(Analyzer *ana) {
  glColor4f(0, 0, 1, 1);
  GLfloat vertices[4 * 2];
  glVertexPointer(2, GL_FLOAT, 0, vertices);

  for (unsigned int ii = 0; ii < 4; ii++) {
    float mag = 0;
    switch (ii) {
      case 0: {
        mag = (ana->getPower());
        break;
      }
      case 1: {
        mag = (ana->getLowPower());
        break;
      }
      case 2: {
        mag = (ana->getHiPower());
        break;
      }
      case 3: {
        mag = (ana->getSlowRollingPower());
        break;
      }
    }
    mag *= _viewportHeight;
    float x = _viewportWidth - (float)ii * 100.0f;
    vertices[0] = x; vertices[1] = 0; // top left
    vertices[2] = x - 100; vertices[3] = 0; // top right
    vertices[4] = x - 100; vertices[5] = mag; // bottom right
    vertices[6] = x; vertices[7] = mag; // bottom left
    
    glDrawArrays(GL_LINE_LOOP, 0, 4);
  }
}

void Renderer::_setOrthoProjection() {
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrthof(0, _viewportWidth / _screenScale, 0, _viewportHeight / _screenScale, -1, 1);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
}

void Renderer::_maybeRenderTouchFeedback() {
  if (_enableTouchFeedback) {
    float lineSep = 32;
    float _initialLineY = (int)_touchDy % (int)lineSep;
    
    glColor4f(1, 1, 1, 1);
    GLfloat vertices[2 * 2];
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    for (float yy = _initialLineY; yy < _viewportHeight; yy += lineSep) {
      vertices[0] = _viewportWidth - 40; vertices[1] = yy;
      vertices[2] = _viewportWidth - 8; vertices[3] = yy;
      glDrawArrays(GL_LINE_LOOP, 0, 2);
    }
  }
}

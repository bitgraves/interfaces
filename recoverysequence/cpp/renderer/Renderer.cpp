
#include "Renderer.h"

#include <math.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

Renderer::Renderer() {
  _time = 0;
  _scale = 1;
  this->setViewport(0, 0);
}

void Renderer::render(double dt, AkaiMPD218Model *model) {
  _time += dt;
  _scale = 1.0 + (0.05 * sin(_time * 0.4));
  this->_renderFancyHexagon(model);
}

void Renderer::setViewport(float width, float height) {
  _viewportWidth = width;
  _viewportHeight = height;
}

#pragma mark - internal

static float hexIdxToKnobIdx[] = { 3, 1, 0, 2, 4, 5 };

void Renderer::_renderHexagon(AkaiMPD218Model *model) {
  float incAngle = 360.0 / (float)AkaiMPD218Model::NUM_KNOBS;
  float radius = 250;
  float halfwidth = 60;
  
  glPushMatrix();
  glTranslatef(_viewportWidth * 0.5, _viewportHeight * 0.5, 0);
  for (int hexIdx = 0; hexIdx < AkaiMPD218Model::NUM_KNOBS; hexIdx++) {
    int knobIdx = hexIdxToKnobIdx[hexIdx];
    float knobValue = (float)(model->knobValues[knobIdx]) / 128.0;
    
    glColor4f(1, 1, 1, 0.1);
    glRectf(radius + -halfwidth, -halfwidth, radius + halfwidth, halfwidth);
    
    if (knobIdx == model->knobIndexLastUpdated) {
      glColor4f(1, 0, 0, knobValue);
    } else {
      glColor4f(1, 1, 1, knobValue);
    }
    glRectf(radius + -halfwidth, -halfwidth, radius + -halfwidth + (knobValue * halfwidth * 2.0), halfwidth);
    glRotatef(incAngle, 0, 0, 1);
  }
  glPopMatrix();
}

void Renderer::_renderFancyHexagon(AkaiMPD218Model *model) {
  float incAngle = 360.0 / (float)AkaiMPD218Model::NUM_KNOBS;
  float innerRadius = 158;
  
  glPushMatrix();
  glTranslatef(_viewportWidth * 0.5, _viewportHeight * 0.5, 0);
  glScalef(_scale, _scale, 1);
  for (int hexIdx = 0; hexIdx < AkaiMPD218Model::NUM_KNOBS; hexIdx++) {
    int knobIdx = hexIdxToKnobIdx[hexIdx];
    float knobValue = (float)(model->knobValues[knobIdx]) / 128.0;
    
    if (knobIdx == model->knobIndexLastUpdated) {
      glColor4f(1, 0, 0, knobValue);
    } else {
      glColor4f(1, 1, 1, knobValue);
    }
    float lineAngle = ((M_PI * 2.0) / (float)AkaiMPD218Model::NUM_KNOBS) * 0.5;
    float hexSideLen = 92;
    float quadRadius = innerRadius + 800 * knobValue;
    glBegin(GL_QUADS);
    {
      glVertex2f(innerRadius, -hexSideLen);
      glVertex2f(innerRadius, hexSideLen);
      glVertex2f(quadRadius * cosf(lineAngle), quadRadius * sinf(lineAngle));
      glVertex2f(quadRadius * cosf(-lineAngle), quadRadius * sinf(-lineAngle));
    }
    glEnd();
    
    glRotatef(incAngle, 0, 0, 1);
  }
  glPopMatrix();
}

// renders easily readable version of the model
// (six large vertical bars)
void Renderer::_renderDebug(AkaiMPD218Model *model) {
  float sqSide = 0.3;
  float totalWidth = sqSide * AkaiMPD218Model::NUM_KNOBS;
  for (unsigned int ii = 0; ii < AkaiMPD218Model::NUM_KNOBS; ii++) {
    float alpha = (float)(model->knobValues[ii]) / 128.0;
    float xi = (totalWidth * -0.5) + (ii * sqSide);
    float s = (sqSide * 0.97);
    float partialS = 1.5 * alpha;
    glColor4f(1, 1, 1, 0.1);
    glRectf(xi, -0.75, xi + s, 0.75);
    if (ii == model->knobIndexLastUpdated) {
      glColor4f(1, 0, 0, alpha);
    } else {
      glColor4f(1, 1, 1, alpha);
    }
    glRectf(xi, -0.75, xi + s, -0.75 + partialS);
  }
}

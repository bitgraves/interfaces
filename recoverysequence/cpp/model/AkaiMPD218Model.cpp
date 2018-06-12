
#include "AkaiMPD218Model.h"

#include <math.h>
#include <stdio.h>

const int paramKnobMapping[] = { 3, 9, 12, 13, 14, 15 };

AkaiMPD218Model::AkaiMPD218Model() {
  reset();
}

void AkaiMPD218Model::reset() {
  for (unsigned int ii = 0; ii < NUM_KNOBS; ii++) {
    knobValues[ii] = 0;
  }
  for (unsigned int ii = 0; ii < NUM_PADS; ii++) {
    isPadActive[ii] = false;
  }
  _debugMouseX = 0;
  _debugMouseY = 0;
}

void AkaiMPD218Model::ingestOscMessage(AkaiMPD218ParamType type, int param, int value) {
  switch (type) {
    case kAkaiMPD218ParamTypeKnob: {
      int knobIndex = 0;
      for (unsigned int ii = 0; ii < NUM_KNOBS; ii++) {
        if (param == paramKnobMapping[ii]) {
          knobIndex = ii;
          break;
        }
      }
      knobValues[knobIndex] = value;
      knobIndexLastUpdated = knobIndex;
      break;
    }
    case kAkaiMPD218ParamTypePad:
      isPadActive[param] = (bool)value;
      break;
    default:
      break;
  }
}

void AkaiMPD218Model::ingestDebugMouseMessage(int dx, int dy) {
  _debugMouseX += dx;
  _debugMouseY += dy;
  
  _debugMouseX = fmax(0, fmin(500, _debugMouseX));
  _debugMouseY = fmax(0, fmin(128, _debugMouseY));
  
  int knobIndex = _debugMouseX / 100;
  knobValues[knobIndex] = _debugMouseY;
  knobIndexLastUpdated = knobIndex;
}


#include "AkaiMPD218Model.h"

#include <math.h>
#include <stdio.h>

const int paramKnobMapping[] = { 3, 9, 12, 13, 14, 15 };

AkaiMPD218Model::AkaiMPD218Model() {
  for (unsigned int ii = 0; ii < NUM_KNOBS; ii++) {
    knobValues[ii] = 0;
  }
  _debugMouseX = 0;
  _debugMouseY = 0;
}

void AkaiMPD218Model::ingestOscMessage(int param, int value) {
  int knobIndex = 0;
  for (unsigned int ii = 0; ii < NUM_KNOBS; ii++) {
    if (param == paramKnobMapping[ii]) {
      knobIndex = ii;
      break;
    }
  }
  knobValues[knobIndex] = value;
  knobIndexLastUpdated = knobIndex;
}

void AkaiMPD218Model::ingestDebugMouseMessage(int dx, int dy) {
  _debugMouseX += dx;
  _debugMouseY += dy;
  
  _debugMouseX = fmax(0, fmin(500, _debugMouseX));
  _debugMouseY = fmax(0, fmin(128, _debugMouseY));
  
  int knobIndex = _debugMouseX / 100;
  fprintf(stdout, "set %d to %d\n", knobIndex, _debugMouseY);
  knobValues[knobIndex] = _debugMouseY;
  knobIndexLastUpdated = knobIndex;
}

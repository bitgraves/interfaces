
#include "AkaiMPD218Model.h"

const int paramKnobMapping[] = { 3, 9, 12, 13, 14, 15 };

AkaiMPD218Model::AkaiMPD218Model() {
  for (unsigned int ii = 0; ii < NUM_KNOBS; ii++) {
    knobValues[ii] = 0;
  }
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

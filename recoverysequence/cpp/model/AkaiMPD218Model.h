
#ifndef __akai_mpd218_model_h__
#define __akai_mpd218_model_h__

class AkaiMPD218Model {
public:
  AkaiMPD218Model();
  
  static const int NUM_KNOBS = 6;
  int knobValues[NUM_KNOBS];
  int knobIndexLastUpdated;
  
  void ingestOscMessage(int param, int value);
};

#endif


#ifndef __akai_mpd218_model_h__
#define __akai_mpd218_model_h__

typedef enum AkaiMPD218ParamType {
  kAkaiMPD218ParamTypeKnob,
  kAkaiMPD218ParamTypePad,
} AkaiMPD218ParamType;

class AkaiMPD218Model {
public:
  AkaiMPD218Model();
  
  static const int NUM_KNOBS = 6;
  static const int NUM_PADS = 16;
  int knobValues[NUM_KNOBS];
  int knobIndexLastUpdated;
  bool isPadActive[NUM_PADS];
  
  void ingestOscMessage(AkaiMPD218ParamType type, int param, int value);
  void ingestDebugMouseMessage(int dx, int dy);
  
private:
  int _debugMouseX, _debugMouseY;
};

#endif

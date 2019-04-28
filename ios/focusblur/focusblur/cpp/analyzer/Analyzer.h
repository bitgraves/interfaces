
#ifndef __ANALYZER_H__
#define __ANALYZER_H__

#include "AudioConstants.h"
#include "chuck_fft.h"

class Analyzer {
public:
  static const unsigned int kFFTWindowSize = AUDIO_BUFFER_SIZE;
  static const unsigned int kFFTSize = kFFTWindowSize * 2;
  
  Analyzer();
  ~Analyzer();
  void copyAudioInputBuffer(AudioSharedBuffer *buffer);
  void prepareToRender();
  
  complex *getFFTValue(int index);
  float getPower(); // 0-1
  float getLowPower();
  float getHiPower();
  float getSlowRollingPower(); // 0-1, builds slowly when stuff is happening, diminishes when nothing is happening.
  
  void reset();
  
private:
  void _performFFT();
  float _computePower(AudioSharedBuffer *buffer);
  void _analyzeFFT();

  AudioSharedBuffer *_inputBuffer;
  float *_fftData;
  float *_fftWindow;
  float _power;
  float _lowPower;
  float _hiPower;
  float _slowRollingPower;
};

#endif

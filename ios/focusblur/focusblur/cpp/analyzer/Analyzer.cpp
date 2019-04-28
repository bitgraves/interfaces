
#include "Analyzer.h"

#include <assert.h>

Analyzer::Analyzer() : _power(0), _lowPower(0), _hiPower(0), _slowRollingPower(0) {
  // init empty input buffer
  _inputBuffer = (AudioSharedBuffer *) malloc(sizeof(AudioSharedBuffer*));
  _inputBuffer->length = AUDIO_MAX_BUFFER_SIZE * AUDIO_NUM_CHANNELS;
  _inputBuffer->buffer = (Sample *)malloc(_inputBuffer->length * sizeof(Sample));
  
  // init fft window and data
  _fftWindow = (float *)malloc(kFFTWindowSize * sizeof(float));
  hamming(_fftWindow, kFFTWindowSize);
  _fftData = (float *)malloc(kFFTSize * sizeof(float));
  memset(_fftData, 0, sizeof(float) * kFFTSize);
}

Analyzer::~Analyzer() {
  if (_inputBuffer) {
    free(_inputBuffer->buffer);
    free(_inputBuffer);
    _inputBuffer = NULL;
  }
  if (_fftWindow) {
    free(_fftWindow);
    _fftWindow = NULL;
  }
  if (_fftData) {
    free(_fftData);
    _fftData = NULL;
  }
}

void Analyzer::copyAudioInputBuffer(AudioSharedBuffer *otherBuffer) {
  assert(otherBuffer->length <= AUDIO_MAX_BUFFER_SIZE * AUDIO_NUM_CHANNELS);
  _inputBuffer->length = otherBuffer->length;
  memcpy(_inputBuffer->buffer, otherBuffer->buffer, otherBuffer->length * sizeof(Sample));
  
  _power = this->_computePower(_inputBuffer);
  // TODO: might wanna use _buffer->length here instead of fftWindowSize
  apply_window(_inputBuffer->buffer, _fftWindow, kFFTWindowSize);
}

void Analyzer::prepareToRender() {
  this->_performFFT();
  this->_analyzeFFT();
  _slowRollingPower += _power * 0.002;
  _slowRollingPower -= 0.0003;
  if (_slowRollingPower > 1.0f) {
    _slowRollingPower = 1.0f;
  }
  if (_slowRollingPower < 0) {
    _slowRollingPower = 0;
  }
}

complex *Analyzer::getFFTValue(int index) {
  complex *fftDataCmp = (complex *)_fftData;
  return fftDataCmp + index;
}

float Analyzer::getPower() {
  return _power;
}

float Analyzer::getLowPower() {
  return _lowPower;
}

float Analyzer::getHiPower() {
  return _hiPower;
}

float Analyzer::getSlowRollingPower() {
  return _slowRollingPower;
}

void Analyzer::reset() {
  _slowRollingPower = 0;
}

#pragma mark - internal

void Analyzer::_performFFT() {
  memcpy(_fftData, _inputBuffer->buffer, sizeof(float) * kFFTWindowSize);
  rfft(_fftData, kFFTSize / 2, FFT_FORWARD);
}

float Analyzer::_computePower(AudioSharedBuffer *buffer) {
  float sqrSum = 0;
  for (unsigned long ii = 0, nn = buffer->length; ii < nn; ii += AUDIO_NUM_CHANNELS) {
    Sample val = 0;
    for (unsigned long cc = 0; cc < AUDIO_NUM_CHANNELS; cc++) {
      val += buffer->buffer[ii + cc];
    }
    sqrSum += val * val;
  }
  float power = sqrSum / (float)(buffer->length / AUDIO_NUM_CHANNELS);
  return fminf(1.0f, power);
}

void Analyzer::_analyzeFFT() {
  complex *fftDataCmp = (complex *)_fftData;
  float lowPower = 0, hiPower = 0;

  int division = 24;
  int sizeToAnalyze = fmin(96, Analyzer::kFFTSize / 2);
  for (int ii = 0; ii < sizeToAnalyze; ii++) {
    float val = cmp_abs(fftDataCmp[ii]);

    if (ii < division) {
      lowPower += val;
    } else {
      hiPower += val;// = fmax(hiPower, val);
    }
  }
  
  _lowPower = lowPower;
  _hiPower = hiPower;
}

/* void Analyzer::_computeEnergy() {
  int energy = 0;
  float threshold = 0.7;
  complex *fftDataCmp = (complex *)_fftData;
  for (int ii = 0; ii < Analyzer::kFFTSize / 2; ii++) {
    float val = sqrt(cmp_abs(fftDataCmp[ii]));
    if (val > threshold) {
      energy++;
      threshold *= 1.2;
    } else {
      threshold *= 0.993;
    }
    // if ((ii < 15 && val > 0.25) || (ii >= 15 && val > 0.07)) {
    //   energy++;
    // }
  }
  _energy = energy;
} */

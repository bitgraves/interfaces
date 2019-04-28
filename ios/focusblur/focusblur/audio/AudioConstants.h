
#ifndef __AUDIO_DEF_H__
#define __AUDIO_DEF_H__

#include <cstdlib>
#include <complex>

typedef float Sample; // 32 bit

typedef void (*AudioCallback)(Sample* buffer, unsigned int numFrames, void* userData);

#define AUDIO_SAMPLE_RATE 44100.0
#define AUDIO_BUFFER_SIZE 512 // frames
#define AUDIO_MAX_BUFFER_SIZE 1024 // frames
#define AUDIO_NUM_CHANNELS 2

#define INPUT_BUFFER_MICROPHONE 1

typedef struct AudioSharedBuffer {
  Sample* buffer;
  size_t length;
} AudioSharedBuffer;

typedef std::complex<Sample> AudioComplex;

#endif

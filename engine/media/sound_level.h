#ifndef MOTOLII_MEDIA_SOUND_LEVEL_H_
#define MOTOLII_MEDIA_SOUND_LEVEL_H_

// Measures the sound of an audio or video file.
//
// Provides the loudness over the length of the file, measured with GStreamer's level element.
// The file is decoded as fast as possible, not played. Also provides the strikes, the times
// where the sound gets suddenly louder, such as a drum or a clap. After Effects' Convert Audio
// to Keyframes reads the same loudness, and the strikes are where its curve jumps. Finally
// provides the sound as ISF audio inputs take it.

#include <string>
#include <vector>

// Returns the loudness of the loudest channel of `file` in dB, where 0 is full scale, sampled
// every 1/rate seconds of the file's own time. Returns an empty list if no sound could be read.
std::vector<float> sound_loudness(const char* file, double rate);

// Returns the strike times, in seconds of the file, found in the loudness list `db` that was
// sampled at `rate` per second. A strike is a point where the loudness grows by at least `rise`
// dB within 30 ms and is above -40 dB, so that it can be heard. After a strike, no other strike
// is reported for 120 ms.
std::vector<double> sound_strikes(const std::vector<float>& db, double rate, double rise);

// The sound of a file as ISF audio inputs take it, one channel for the whole length of the file.
// In the ISF specification an audio input is an image with one row per channel. In an "audio"
// input each column is one sample of the wave, centered on 0.5. In an "audioFFT" input each
// column is one value of the FFT. At each time the amount of data matches what VIDVOX's own ISF
// Editor gives an ISF (VVISF-GL, AudioController: fftQuality 512, and the wave is twice that).
struct SoundRead {
    // Samples of the wave, sound_rate per second, from -1 to 1.
    std::vector<float> wave;
    // Spectrum rows of sound_bands values, sound_rows rows per second. Values go from 0 at
    // minDecibels to 1 at maxDecibels.
    std::vector<float> fft;
};
inline constexpr int sound_rate = 24000, sound_bands = 512, sound_rows = 60;

// Returns the sound of `file`, read once in the background because reading takes as long as
// decoding the file. Returns null until the read has finished; the caller should treat that as
// silence. Each read runs under std::async and its future is kept. When the futures are
// destroyed at exit, each destructor waits for its read to finish ([futures.async]).
const SoundRead* sound_of(const std::string& file);

// Returns what an ISF audio input reads at time `at`, in seconds of the file. `r` may be null.
// `fft` selects the spectrum; otherwise the wave is returned. `wide` is the number of values
// wanted, which is the MAX of the input; 0 means all of them. Follows VVISF-GL's
// AudioController. Each value is the mean of the neighboring values it covers (valsPerAvg),
// with the last group kept inside the range. The wave is the 1024 samples up to `at`, and each
// sample is mapped by (sample * 4 + 4) / 8. Returns silence when there is no data.
std::vector<float> sound_at(const SoundRead* r, bool fft, int wide, double at);

#endif  // MOTOLII_MEDIA_SOUND_LEVEL_H_

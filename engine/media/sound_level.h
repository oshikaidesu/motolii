#ifndef MOTOLII_MEDIA_SOUND_LEVEL_H_
#define MOTOLII_MEDIA_SOUND_LEVEL_H_

// Measures the sound of an audio or video file.
//
// Provides the loudness over the length of the file, measured with GStreamer's
// level element. The file is decoded as fast as possible, not played. Also
// provides the strikes, the times where the sound gets suddenly louder, such as
// a drum or a clap. After Effects' Convert Audio to Keyframes reads the same
// loudness, and the strikes are where its curve jumps. Finally provides the
// sound as ISF audio inputs take it.

#include <string>
#include <vector>

namespace motolii {

// Returns the loudness of the loudest channel of `file` in dB, where 0 is full
// scale, sampled every 1/rate seconds of the file's own time. Returns an empty
// list if no sound could be read.
std::vector<float> sound_loudness(const char* file, double rate);

// Returns the strike times, in seconds of the file, found in the loudness list
// `db` that was sampled at `rate` per second. A strike is a point where the
// loudness grows by at least `rise` dB within 30 ms and is above -40 dB, so
// that it can be heard. After a strike, no other strike is reported for 120 ms.
std::vector<double> sound_strikes(const std::vector<float>& db, double rate,
                                  double rise);

// The sound of a file, one channel for the whole length of the file, read at
// sound_rate, the rate a Web page's AudioContext runs at on most machines.
struct SoundRead {
  // Samples of the wave, sound_rate per second, from -1 to 1.
  std::vector<float> wave;
};
// sound_size is the fftSize an AnalyserNode starts with, sound_rows how often
// a page that draws every frame asks one, and sound_history how many askings
// back a row of the spectrum is worked out from. sound_bands is what an ISF
// audio input is given: VIDVOX's own ISF Editor gives an ISF that many values
// of the spectrum and twice as many samples of the wave (VVISF-GL,
// AudioController: fftQuality 512).
inline constexpr int sound_rate = 48000, sound_size = 2048, sound_rows = 60,
                     sound_history = 64, sound_bands = 512;

// Returns the sound of `file`, read once in the background because reading
// takes as long as decoding the file. Returns null until the read has finished;
// the caller should treat that as silence. Each read runs under std::async and
// its future is kept. When the futures are destroyed at exit, each destructor
// waits for its read to finish ([futures.async]). With `wait`, does not return
// before the read has finished, so that the same time always gives the same
// sound.
const SoundRead* sound_of(const std::string& file, bool wait = false);

// One asking of the Web's AnalyserNode (W3C Web Audio API, section 1.8.6, "FFT
// windowing and smoothing over time"): `latest` holds the `size` samples heard last, the
// oldest first, `size` a power of two. They are put under a Blackman window
// and transformed (the transform is GStreamer's gst_fft_f32), each pitch's
// size divided by `size` and smoothed with what the asking before left in
// `smooth` (size / 2 values, zeros before the first asking) by `tau`, the
// smoothingTimeConstant. `smooth` is left holding the result; 20 x log10 of a
// value is its decibels.
void analyser_asked(const float* latest, int size, double tau, double* smooth);

// Fills `to` with the `n` samples of the wave before time `at`, in seconds of
// the file, the oldest first: the last is sample `at` x sound_rate - 1, as a
// page that has run for that long has been given them. Zeros where the file
// has none, and for a null `r`.
void sound_wave(const SoundRead* r, double at, float* to, int n);

// Returns the sound at time `at`, in seconds of the file, as an AnalyserNode
// that is as it comes (an fftSize of sound_size, a smoothingTimeConstant of
// 0.8) gives it to a page that has asked sound_rows times a second: with
// `fft`, the decibels of its sound_size / 2 pitches, pitch i at
// i x sound_rate / sound_size Hz (minus infinity for a pitch with no sound);
// without, the sound_size samples of the wave up to `at`, each -1 to 1.
// Returns an empty list when `r` is null, `at` is negative, or, with `fft`,
// `at` is past the end of the sound.
std::vector<float> sound_raw(const SoundRead* r, bool fft, double at);

// Returns what an ISF audio input reads at time `at`, in seconds of the file.
// In the ISF specification an audio input is an image with one row per
// channel: in an "audio" input each column is one sample of the wave, centered
// on 0.5, and in an "audioFFT" input each column is one value of the FFT. `r`
// may be null. `fft` selects the spectrum: the lowest sound_bands pitches of
// sound_raw, from 0 at -100 dB to 1 at -30 dB (an AnalyserNode's minDecibels
// and maxDecibels as they come). Otherwise the wave: the 2 x sound_bands
// samples up to `at`, each mapped by (sample * 4 + 4) / 8. `wide` is the
// number of values wanted, which is the MAX of the input; 0 means all of
// them. Follows VVISF-GL's AudioController: each value is the mean of the
// neighboring values it covers (valsPerAvg), with the last group kept inside
// the range. Returns silence when there is no data.
std::vector<float> sound_at(const SoundRead* r, bool fft, int wide, double at);

}  // namespace motolii

#endif  // MOTOLII_MEDIA_SOUND_LEVEL_H_

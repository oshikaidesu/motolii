#include "media/sound_level.h"

#include <gst/app/gstappsink.h>
#include <gst/fft/gstfftf32.h>
#include <gst/gst.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <future>
#include <map>
#include <mutex>
#include <string>
#include <vector>

#include "media/gstreamer_file_source.h"

namespace motolii {

namespace {

// Reads the sound of `file` once, decoding it at full speed.
//
// The wave is taken from appsink, whose gst_app_sink_pull_sample returns NULL
// at the end of the stream. The spectrum is then worked out from the wave as
// the Web's AnalyserNode works it out (W3C Web Audio API 1.8.6, "FFT windowing
// and smoothing over time", which Shadertoy's sound also uses) for a page that
// asks sound_rows times a second from the start of the sound: the latest
// 2 x sound_bands samples under a Blackman window, their Fourier transform
// divided by its length (the transform itself is GStreamer's gst_fft_f32),
// each pitch smoothed over the askings with smoothingTimeConstant, then in
// decibels, scaled from minDecibels to maxDecibels as 0 to 1.
SoundRead sound_read(const std::string& file) {
  static const bool started = (gst_init(nullptr, nullptr), true);
  (void)started;
  SoundRead r;
  const std::string from =
      std::string(
          "filesrc name=in ! decodebin ! audioconvert ! audioresample ! "
          "audio/x-raw,format=F32LE,channels=1,rate=") +
      std::to_string(sound_rate);
  GstElement* reads = gst_parse_launch(
      (from + " ! appsink name=out sync=false").c_str(), nullptr);
  if (!reads) return r;
  gst_read_from(reads, file.c_str());
  GstElement* out = gst_bin_get_by_name(GST_BIN(reads), "out");
  // If the pipeline cannot start, for example because the file does not exist,
  // no end of stream would ever arrive, so do not pull.
  const bool pulling = gst_element_set_state(reads, GST_STATE_PLAYING) !=
                       GST_STATE_CHANGE_FAILURE;
  while (GstSample* got =
             pulling ? gst_app_sink_pull_sample(GST_APP_SINK(out)) : nullptr) {
    GstMapInfo map;
    if (GstBuffer* b = gst_sample_get_buffer(got);
        b && gst_buffer_map(b, &map, GST_MAP_READ)) {
      const float* f = (const float*)map.data;
      r.wave.insert(r.wave.end(), f, f + map.size / sizeof(float));
      gst_buffer_unmap(b, &map);
    }
    gst_sample_unref(got);
  }
  gst_element_set_state(reads, GST_STATE_NULL);
  gst_object_unref(out), gst_object_unref(reads);
  // The defaults of AnalyserOptions: minDecibels, maxDecibels and
  // smoothingTimeConstant. The window is the specification's, alpha 0.16.
  const double low = -100.0, high = -30.0, tau = 0.8;
  const int size = 2 * sound_bands;
  std::vector<float> window((size_t)size), in((size_t)size);
  for (int n = 0; n < size; ++n)
    window[(size_t)n] = (float)(0.42 - 0.5 * std::cos(2.0 * M_PI * n / size) +
                                0.08 * std::cos(4.0 * M_PI * n / size));
  std::vector<GstFFTF32Complex> out_of((size_t)sound_bands + 1);
  GstFFTF32* transform = gst_fft_f32_new(size, FALSE);
  // The smoothed values of the asking before, zero at first.
  std::vector<double> smooth((size_t)sound_bands, 0.0);
  for (long end = 0; end <= (long)r.wave.size();
       end += sound_rate / sound_rows) {
    for (int n = 0; n < size; ++n) {
      const long k = end - size + n;
      in[(size_t)n] = k >= 0 ? r.wave[(size_t)k] * window[(size_t)n] : 0.f;
    }
    gst_fft_f32_fft(transform, in.data(), out_of.data());
    for (int i = 0; i < sound_bands; ++i) {
      double& x = smooth[(size_t)i];
      x = tau * x + (1.0 - tau) *
                        std::hypot((double)out_of[(size_t)i].r,
                                   (double)out_of[(size_t)i].i) /
                        size;
      r.fft.push_back((float)std::clamp(
          (20.0 * std::log10(std::max(x, 1e-12)) - low) / (high - low), 0.0,
          1.0));
    }
  }
  gst_fft_f32_free(transform);
  return r;
}

}  // namespace

std::vector<float> sound_loudness(const char* file, double rate) {
  static const bool started = (gst_init(nullptr, nullptr), true);
  (void)started;
  std::vector<float> db;
  const std::string said =
      std::string(
          "filesrc name=in ! decodebin ! audioconvert ! audio/x-raw ! level "
          "name=level post-messages=true interval=") +
      std::to_string((guint64)(1e9 / rate)) + " ! fakesink sync=false";
  GError* wrong = nullptr;
  GstElement* reads = gst_parse_launch(said.c_str(), &wrong);
  if (wrong) g_error_free(wrong);
  if (!reads) return db;
  gst_read_from(reads, file);
  GstBus* bus = gst_element_get_bus(reads);
  gst_element_set_state(reads, GST_STATE_PLAYING);
  for (bool going = true; going;) {
    GstMessage* heard = gst_bus_timed_pop_filtered(
        bus, 10 * GST_SECOND,
        (GstMessageType)(GST_MESSAGE_ELEMENT | GST_MESSAGE_EOS |
                         GST_MESSAGE_ERROR));
    if (!heard) break;
    if (GST_MESSAGE_TYPE(heard) != GST_MESSAGE_ELEMENT)
      going = false;
    else if (const GstStructure* s = gst_message_get_structure(heard);
             s && gst_structure_has_name(s, "level")) {
      const GValue* rms = gst_structure_get_value(s, "rms");
      float loudest = -100.f;
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      if (rms && G_VALUE_HOLDS(rms, G_TYPE_VALUE_ARRAY)) {
        const GValueArray* each = (const GValueArray*)g_value_get_boxed(rms);
        for (guint c = 0; c < each->n_values; ++c)
          loudest =
              std::max(loudest, (float)g_value_get_double(g_value_array_get_nth(
                                    (GValueArray*)each, c)));
      }
      G_GNUC_END_IGNORE_DEPRECATIONS
      db.push_back(std::max(loudest, -100.f));
    }
    gst_message_unref(heard);
  }
  gst_element_set_state(reads, GST_STATE_NULL);
  gst_object_unref(bus);
  gst_object_unref(reads);
  return db;
}

std::vector<double> sound_strikes(const std::vector<float>& db, double rate,
                                  double rise) {
  std::vector<double> at;
  const int near = std::max(1, (int)std::lround(0.03 * rate)),
            apart = std::max(1, (int)std::lround(0.12 * rate));
  int last = -apart;
  for (int i = 0; i < (int)db.size(); ++i) {
    if (i - last < apart || db[(size_t)i] < -40.f) continue;
    // Before the file begins there is silence.
    float low = i < near ? -100.f : db[(size_t)i];
    for (int j = std::max(0, i - near); j < i; ++j)
      low = std::min(low, db[(size_t)j]);
    if (db[(size_t)i] - low >= rise) at.push_back(i / rate), last = i;
  }
  return at;
}

const SoundRead* sound_of(const std::string& file, bool wait) {
  static std::map<std::string, std::shared_future<SoundRead>> read;
  static std::mutex one;
  std::shared_future<SoundRead> it;
  {
    std::lock_guard<std::mutex> hold(one);
    auto found = read.find(file);
    if (found == read.end())
      found =
          read.emplace(file,
                       std::async(std::launch::async, sound_read, file).share())
              .first;
    it = found->second;
  }
  // The map keeps the future, so what it holds outlives this call.
  return wait || it.wait_for(std::chrono::seconds(0)) ==
                     std::future_status::ready
             ? &it.get()
             : nullptr;
}

std::vector<float> sound_raw(const SoundRead* r, bool fft, double at) {
  const int raw = fft ? sound_bands : 2 * sound_bands;
  if (!r || at < 0) return {};
  std::vector<float> all((size_t)raw, 0.f);
  if (fft) {
    const long row = std::lround(at * sound_rows);
    if ((row + 1) * sound_bands > (long)r->fft.size()) return {};
    std::copy_n(r->fft.begin() + row * sound_bands, sound_bands, all.begin());
  } else {
    const long last = std::lround(at * sound_rate);
    for (int i = 0; i < raw; ++i)
      if (const long k = last - raw + 1 + i; k >= 0 && k < (long)r->wave.size())
        all[(size_t)i] = r->wave[(size_t)k];
  }
  return all;
}

std::vector<float> sound_at(const SoundRead* r, bool fft, int wide, double at) {
  const int raw = fft ? sound_bands : 2 * sound_bands;
  std::vector<float> v((size_t)std::clamp(wide > 0 ? wide : raw, 1, raw),
                       fft ? 0.f : 0.5f);
  std::vector<float> all = sound_raw(r, fft, at);
  if (all.empty()) return v;
  if (!fft)
    for (float& sample : all) sample = (sample * 4.f + 4.f) / 8.f;
  const int per = std::max(1, (int)std::lround((float)raw / (float)v.size()));
  for (int c = 0; c < (int)v.size(); ++c) {
    const int first = (c + 1) * per >= raw ? raw - per : c * per;
    double sum = 0;
    for (int i = 0; i < per; ++i) sum += all[(size_t)(first + i)];
    v[(size_t)c] = (float)(sum / per);
  }
  return v;
}

}  // namespace motolii

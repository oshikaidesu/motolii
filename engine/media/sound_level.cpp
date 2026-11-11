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

// Reads the sound of `file` once, decoding it at full speed: its wave, taken
// from appsink, whose gst_app_sink_pull_sample returns NULL at the end of the
// stream.
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

void analyser_asked(const float* latest, int size, double tau,
                    double* smooth) {
  // One transform a size, kept: making one works out its table of sines.
  struct Made {
    GstFFTF32* transform;
    std::vector<float> window, in;
    std::vector<GstFFTF32Complex> out;
  };
  static auto& made = *new std::map<int, Made>;
  static std::mutex one;
  std::lock_guard<std::mutex> hold(one);
  Made& m = made[size];
  if (!m.transform) {
    m.transform = gst_fft_f32_new(size, FALSE);
    m.window.resize((size_t)size), m.in.resize((size_t)size);
    m.out.resize((size_t)size / 2 + 1);
    // The specification's Blackman window, alpha 0.16.
    for (int n = 0; n < size; ++n)
      m.window[(size_t)n] =
          (float)(0.42 - 0.5 * std::cos(2.0 * M_PI * n / size) +
                  0.08 * std::cos(4.0 * M_PI * n / size));
  }
  for (int n = 0; n < size; ++n)
    m.in[(size_t)n] = latest[n] * m.window[(size_t)n];
  gst_fft_f32_fft(m.transform, m.in.data(), m.out.data());
  for (int i = 0; i < size / 2; ++i) {
    const double x = tau * smooth[i] +
                     (1.0 - tau) *
                         std::hypot((double)m.out[(size_t)i].r,
                                    (double)m.out[(size_t)i].i) /
                         size;
    smooth[i] = std::isfinite(x) ? x : 0.0;
  }
}

void sound_wave(const SoundRead* r, double at, float* to, int n) {
  const long last = r ? std::lround(at * sound_rate) : 0;
  for (int i = 0; i < n; ++i) {
    const long k = last - n + 1 + i;
    to[i] = r && k >= 0 && k < (long)r->wave.size() ? r->wave[(size_t)k] : 0.f;
  }
}

std::vector<float> sound_raw(const SoundRead* r, bool fft, double at) {
  if (!r || at < 0) return {};
  if (!fft) {
    std::vector<float> wave((size_t)sound_size);
    sound_wave(r, at, wave.data(), sound_size);
    return wave;
  }
  const long step = sound_rate / sound_rows, row = std::lround(at * sound_rows);
  if (row * step > (long)r->wave.size()) return {};
  // The row last worked out for each sound: one frame's letters all ask for
  // the same one.
  static auto& kept = *new std::map<const SoundRead*,
                                    std::pair<long, std::vector<float>>>;
  static std::mutex one;
  std::lock_guard<std::mutex> hold(one);
  auto& [held, decibels] = kept[r];
  if (decibels.empty() || held != row) {
    // What the askings before left has faded to under a millionth after
    // sound_history of them (0.8 to that power), so the row is worked out from
    // that many back, whichever second was asked before: the same second gives
    // the same numbers.
    std::vector<double> smooth((size_t)sound_size / 2, 0.0);
    std::vector<float> latest((size_t)sound_size);
    for (long k = std::max(0L, row - sound_history); k <= row; ++k) {
      const long end = k * step;
      for (int n = 0; n < sound_size; ++n) {
        const long i = end - sound_size + n;
        latest[(size_t)n] =
            i >= 0 && i < (long)r->wave.size() ? r->wave[(size_t)i] : 0.f;
      }
      analyser_asked(latest.data(), sound_size, 0.8, smooth.data());
    }
    decibels.resize(smooth.size());
    for (size_t i = 0; i < smooth.size(); ++i)
      decibels[i] = (float)(20.0 * std::log10(smooth[i]));
    held = row;
  }
  return decibels;
}

std::vector<float> sound_at(const SoundRead* r, bool fft, int wide, double at) {
  const int raw = fft ? sound_bands : 2 * sound_bands;
  std::vector<float> v((size_t)std::clamp(wide > 0 ? wide : raw, 1, raw),
                       fft ? 0.f : 0.5f);
  if (!r || at < 0) return v;
  std::vector<float> all((size_t)raw);
  if (fft) {
    // The lowest sound_bands pitches, from minDecibels to maxDecibels as 0 to
    // 1 (AnalyserOptions' defaults).
    const std::vector<float> decibels = sound_raw(r, true, at);
    if (decibels.empty()) return v;
    for (int i = 0; i < raw; ++i)
      all[(size_t)i] = std::clamp(
          ((float)decibels[(size_t)i] + 100.f) / 70.f, 0.f, 1.f);
  } else {
    sound_wave(r, at, all.data(), raw);
    for (float& sample : all) sample = (sample * 4.f + 4.f) / 8.f;
  }
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

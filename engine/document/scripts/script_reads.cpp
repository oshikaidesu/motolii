#include "document/scripts/script_reads.h"

#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec4.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "document/document.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/sound_level.h"
#include "media/video_frames_for_scripts.h"
#include "media/video_layer.h"
#include "stage/canvas/image_pixels.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace math = filament::math;
using filament::math::float2;

namespace {

constexpr double kRadToDeg = 180.0 / 3.14159265358979323846;

// A video file read on the CPU for scripts, and the frame of it last asked for.
struct Film {
  bool tried = false, open = false;
  FilmRead read;
  ImagePixels now;
  long held = -2;  // which frame of `read` is in `now`
};

// Normalizes effect / parameter labels for case- and punctuation-insensitive
// lookup (matches script_parameters.cpp's snake_name).
std::string norm_key(const std::string& s) {
  std::string out;
  out.reserve(s.size());
  for (unsigned char c : s) {
    if (std::isalnum(c))
      out.push_back((char)std::tolower(c));
    else if (out.empty() || out.back() != '_')
      out.push_back('_');
  }
  while (!out.empty() && out.back() == '_') out.pop_back();
  return out;
}

// Gives the second of its file that a video or sound layer plays at `t`.
bool audio_second(Doc& d, int layer, double t, double* second) {
  const std::string kind = doc_word(d, layer, "kind");
  if (kind != "video" && kind != "sound") return false;
  const double start = doc_number(d, layer, "start", 0, 0),
               lasts = doc_number(d, layer, "duration", 0, -1);
  if (t < start || (lasts >= 0 && t >= start + lasts)) return false;
  if (kind == "video") {
    const auto shown = d.on_stage.shown.find(layer);
    const Video* v =
        shown == d.on_stage.shown.end() ? nullptr : shown->second.video;
    if (v && v->seconds > 0.f) {
      const double since = doc_element_now(d, layer, t) - start,
                   in = std::fmod(std::max(0.0, since), (double)v->seconds) *
                        std::fabs((double)v->speed);
      *second = v->speed > 0.f ? (double)v->from + in : (double)v->to - in;
      return true;
    }
  }
  const double begin = doc_number(d, layer, "begin", 0, 0),
               speed = doc_number(d, layer, "speed", 0, 1);
  *second = begin + (doc_element_now(d, layer, t) - start) * speed;
  return *second >= 0.0;
}

// Returns the video file second when the video is live on stage (for frames).
bool file_second(Doc& d, int layer, double t, double* second) {
  if (doc_word(d, layer, "kind") != "video") return false;
  const auto shown = d.on_stage.shown.find(layer);
  const Video* v =
      shown == d.on_stage.shown.end() ? nullptr : shown->second.video;
  if (!v || v->seconds <= 0.f) return false;
  const double since = doc_element_now(d, layer, t) -
                       doc_number(d, layer, "start", 0, 0),
               in = std::fmod(std::max(0.0, since), (double)v->seconds) *
                    std::fabs((double)v->speed);
  *second = v->speed > 0.f ? (double)v->from + in : (double)v->to - in;
  return true;
}

// Returns the picture layer `layer` shows at second `t` as pixels, or null when
// it has none to read (script_reads.h says which layers do).
const ImagePixels* layer_pixels(Doc& d, int layer, double t,
                                std::shared_ptr<const ImagePixels>& keeps) {
  const std::string file = doc_word(d, layer, "file");
  if (doc_word(d, layer, "kind") == "image")
    return (keeps = image_pixels(file)).get();
  double second = 0;
  if (!file_second(d, layer, t, &second)) return nullptr;
  static auto& films = *new std::map<std::string, Film>;
  Film& f = films[file];
  if (!f.tried) f.tried = true, f.open = f.read.open(file, 0);
  if (!f.open || !f.read.at(second)) return nullptr;
  if (f.held != f.read.frame)
    f.now.w = f.read.w, f.now.h = f.read.h, f.now.rgba = f.read.last,
    f.held = f.read.frame;
  return &f.now;
}

// Pixel dimensions of `layer` for fromWorld/toWorld: image/video dimensions
// when available, else composition-pixel dimensions from doc_half.
bool layer_pixel_size(Doc& d, int layer, double t, float2* half, double* w,
                      double* h) {
  if (!doc_half(d, layer, half) || half->x <= 0.f || half->y <= 0.f)
    return false;
  std::shared_ptr<const ImagePixels> keeps;
  if (const ImagePixels* picture = layer_pixels(d, layer, t, keeps)) {
    *w = picture->w, *h = picture->h;
    return *w > 0 && *h > 0;
  }
  const double px = doc_stage_pixel(d, layer, t);
  if (px <= 1e-9) return false;
  *w = 2.0 * (double)half->x / px;
  *h = 2.0 * (double)half->y / px;
  return *w > 0 && *h > 0;
}

std::vector<int> ordered_layers(Doc& d) {
  std::vector<int> list = doc_laid(d);
  return list.empty() ? doc_layers(d) : list;
}

// Reads raw spectrum (dB) or waveform (-1..1) from one layer, or mixes all
// active audible video/sound layers when `layer <= 0`.
std::vector<float> read_sound_raw(Doc& d, int layer, bool spectrum, double t) {
  const auto one_layer = [&](int id) -> std::vector<float> {
    double second = 0;
    if (!audio_second(d, id, t, &second)) return {};
    const std::string file = doc_word(d, id, "file");
    if (file.empty()) return {};
    return sound_raw(sound_of(file, true), spectrum, second);
  };
  if (layer > 0) return one_layer(layer);
  std::vector<float> mix;
  for (const int id : ordered_layers(d)) {
    if (doc_number(d, id, "volume", t, 1) <= 0.0) continue;
    const std::vector<float> cur = one_layer(id);
    if (cur.empty()) continue;
    if (mix.empty()) {
      mix = cur;
    } else {
      for (size_t i = 0; i < mix.size() && i < cur.size(); ++i)
        mix[i] = spectrum ? std::max(mix[i], cur[i])
                          : std::clamp(mix[i] + cur[i], -1.f, 1.f);
    }
  }
  return mix;
}

// Cached MIDI events per file for channel-filtered reads.
const std::vector<MidiEvent>& cached_midi_events(const std::string& file) {
  static std::mutex mu;
  static auto& cache = *new std::map<std::string, std::vector<MidiEvent>>;
  std::lock_guard<std::mutex> lock(mu);
  auto it = cache.find(file);
  if (it == cache.end())
    it = cache.emplace(file, midi_events(file.c_str())).first;
  return it->second;
}

double cached_midi_bpm(const std::string& file) {
  static std::mutex mu;
  static auto& cache = *new std::map<std::string, double>;
  std::lock_guard<std::mutex> lock(mu);
  auto it = cache.find(file);
  if (it == cache.end()) it = cache.emplace(file, midi_bpm(file.c_str())).first;
  return it->second;
}

bool is_digits(const std::string& s) {
  return !s.empty() && std::all_of(s.begin(), s.end(), [](unsigned char c) {
    return std::isdigit(c) != 0;
  });
}

}  // namespace

void doc_script_reads(Doc& d, Script& run) {
  // The script runs on this thread inside the call that holds the project, so
  // reading is safe; the lock is taken as well, as the render callback does.
  // Limits how deeply layers read each other, so that a cycle terminates.
  run.reads([&d](int layer, const std::string& name, double at,
                 double otherwise, int copy) {
    static thread_local int depth = 0;
    if (depth >= 4 || layer < 0 || name.empty()) return std::nan("");
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    struct Guard {
      int& n;
      explicit Guard(int& v) : n(v) { ++n; }
      ~Guard() { --n; }
    } guard(depth);
    for (const char* known : doc_relate_names) {
      if (name != known) continue;
      if (copy >= 0 && name.size() == 1 && name[0] >= 'x')
        return (doc_place(d, layer, at, 1, copy, true) *
                math::double4{doc_letter_middle(d, layer, copy),
                              doc_line_middle(d, layer, copy), 0,
                              1})[name[0] - 'x'];
      return doc_literal(d, layer, known, at, otherwise);
    }
    return doc_number(d, layer, name.c_str(), at, otherwise);
  });
  run.reads_keys(
      [&d](int layer, const std::string& name) -> std::vector<double> {
        if (layer < 0 || name.empty()) return {};
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        return doc_keys_of(d, layer, name.c_str()).at;
      },
      [&d](const std::string& name) {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        for (const int layer : doc_layers(d))
          if (doc_word(d, layer, "name") == name) return layer;
        return 0;
      });
  run.reads_pictures(
      [&d](int layer, double x, double y, double rx, double ry, bool,
           double t) -> std::array<double, 4> {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        std::shared_ptr<const ImagePixels> keeps;
        const ImagePixels* picture = layer_pixels(d, layer, t, keeps);
        if (!picture) return {0, 0, 0, 0};
        return image_sample(*picture, x, y, rx, ry);
      },
      [&d](int layer, double x, double y, double z,
           double t) -> std::array<double, 2> {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        float2 half{0.f};
        double w = 0, h = 0;
        if (!layer_pixel_size(d, layer, t, &half, &w, &h))
          return {std::nan(""), std::nan("")};
        // The layer's own box runs from -half to +half, y up. Its pixels run
        // from the upper left, [0, 0] the centre of the first.
        const math::double4 in =
            inverse(doc_place(d, layer, t, 1)) * math::double4{x, y, z, 1};
        return {(in.x / (double)half.x + 1.0) * 0.5 * w - 0.5,
                (1.0 - in.y / (double)half.y) * 0.5 * h - 0.5};
      });
  // Sound of a single video/sound layer (`layer > 0`) or the mixed stage audio
  // (`layer <= 0`).
  run.reads_sound([&d](int layer, bool spectrum, double t) {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    return read_sound_raw(d, layer, spectrum, t);
  });

  Script::HostReads host;
  host.word = [&d](int layer, const std::string& name) -> std::string {
    if (layer < 0 || name.empty()) return "";
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    return doc_word(d, layer, name.c_str());
  };
  host.bounds = [&d](int layer, double t) -> std::array<double, 8> {
    constexpr double kNaN = std::numeric_limits<double>::quiet_NaN();
    if (layer <= 0) return {kNaN, kNaN, kNaN, kNaN, kNaN, kNaN, kNaN, kNaN};
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    float2 half{0.f};
    const bool has_half = doc_half(d, layer, &half);
    const double px = doc_stage_pixel(d, layer, t);
    double frame[8] = {};
    if (d.stage && d.stage->camera && doc_frame(d, layer, t, frame)) {
      return {frame[0], frame[1], frame[2], frame[3],
              frame[4], half.x,   half.y,   px};
    }
    if (!has_half || px <= 1e-9)
      return {kNaN, kNaN, kNaN, kNaN, kNaN, kNaN, kNaN, kNaN};
    const double size = doc_number(d, layer, "size", t, 1),
                 sx = std::fabs(doc_number(d, layer, "scale_x", t, 1)),
                 sy = std::fabs(doc_number(d, layer, "scale_y", t, 1)),
                 W = doc_comp_wide(d), H = doc_comp_high(d);
    const double cx = W * 0.5 + doc_number(d, layer, "x", t, 0) / px,
                 cy = H * 0.5 - doc_number(d, layer, "y", t, 0) / px,
                 w = 2.0 * (double)half.x * size * sx / px,
                 h = 2.0 * (double)half.y * size * sy / px,
                 rot = -doc_number(d, layer, "rotate", t, 0);
    return {cx, cy, w, h, rot, half.x, half.y, px};
  };
  host.to_world = [&d](int layer, double x, double y, double z,
                       double t) -> std::array<double, 3> {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    float2 half{0.f};
    double w = 0, h = 0;
    if (!layer_pixel_size(d, layer, t, &half, &w, &h))
      return {std::nan(""), std::nan(""), std::nan("")};
    const double px = doc_stage_pixel(d, layer, t);
    const math::double4 local{((x + 0.5) / w * 2.0 - 1.0) * (double)half.x,
                              (1.0 - (y + 0.5) / h * 2.0) * (double)half.y,
                              z * px, 1.0};
    const math::double4 world = doc_place(d, layer, t, 1) * local;
    return {world.x, world.y, world.z};
  };
  host.to_screen = [&d](double x, double y, double z,
                        double) -> std::array<double, 2> {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    if (!d.stage || !d.stage->camera) return {std::nan(""), std::nan("")};
    const math::double2 p = doc_seen(d, math::double3{x, y, z});
    return {p.x, p.y};
  };
  host.layers = [&d]() {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    return ordered_layers(d);
  };
  host.children = [&d](int parent) {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    std::vector<int> out;
    for (const int id : ordered_layers(d))
      if ((int)doc_number(d, id, "parent", 0, 0) == parent) out.push_back(id);
    return out;
  };
  host.camera = [&d](double t) -> std::array<double, 12> {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    int cam = 0;
    for (const int id : ordered_layers(d)) {
      if (doc_word(d, id, "kind") != "camera") continue;
      const double start = doc_number(d, id, "start", 0, 0),
                   lasts = doc_number(d, id, "duration", 0, -1);
      if (t >= start && (lasts < 0.0 || t < start + lasts) &&
          doc_visible(d, id))
        cam = id;
    }
    const DocViewCamera v = doc_view_camera_of(d, cam, t);
    return {v.eye.x,  v.eye.y,           v.eye.z, v.look.x,
            v.look.y, v.look.z,          v.up.x,  v.up.y,
            v.up.z,   v.fov * kRadToDeg, v.far,   (double)cam};
  };
  // AudioLink-compatible 4-band split (Bass, Low-Mid, High-Mid, Treble) + RMS.
  host.audio_bands = [&d](int layer, double t) -> std::array<double, 5> {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    const std::vector<float> db = read_sound_raw(d, layer, true, t);
    if (db.empty()) return {0, 0, 0, 0, 0};
    constexpr size_t kBins = 128;
    const size_t src_bins = std::min<size_t>(db.size(), (size_t)sound_bands);
    std::array<double, kBins> norm{};
    const size_t per = std::max<size_t>(1, src_bins / kBins);
    for (size_t i = 0; i < kBins; ++i) {
      double acc = 0.0;
      size_t cnt = 0;
      for (size_t j = 0; j < per && i * per + j < src_bins; ++j) {
        const double v =
            std::clamp(((double)db[i * per + j] + 100.0) / 70.0, 0.0, 1.0);
        acc += v, ++cnt;
      }
      norm[i] = cnt ? acc / (double)cnt : 0.0;
    }
    const auto band = [&](size_t a, size_t b) {
      double sum = 0.0, peak = 0.0;
      for (size_t i = a; i < b && i < kBins; ++i)
        sum += norm[i], peak = std::max(peak, norm[i]);
      const double avg = b > a ? sum / (double)(b - a) : 0.0;
      return std::clamp(0.6 * avg + 0.4 * peak, 0.0, 1.0);
    };
    const double b0 = band(0, 8), b1 = band(8, 24), b2 = band(24, 64),
                 b3 = band(64, 128);
    const double rms =
        std::clamp(0.4 * b0 + 0.2 * b1 + 0.2 * b2 + 0.2 * b3, 0.0, 1.0);
    return {b0, b1, b2, b3, rms};
  };
  host.midi = [&d](int current_layer, const std::string& source, int channel,
                   double t) -> std::array<double, 4> {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    std::string file;
    if (source.empty()) {
      if (current_layer > 0) file = doc_word(d, current_layer, "script");
    } else if (is_digits(source)) {
      const int id = std::atoi(source.c_str());
      if (id > 0) file = doc_word(d, id, "script");
    } else {
      for (const int id : doc_layers(d)) {
        if (doc_word(d, id, "name") == source) {
          file = doc_word(d, id, "script");
          break;
        }
      }
      if (file.empty()) file = source;
    }
    if (file.empty() || std::filesystem::path(file).extension() != ".mid")
      return {0, 0, 0, 120};
    const double bpm = cached_midi_bpm(file);
    if (channel < 0) {
      const auto& notes = midi_of(file);
      const MidiNote* active = nullptr;
      for (const auto& note : notes) {
        if (note.on > t) break;
        if (t < note.off) active = &note;
      }
      if (!active) return {0, 0, 0, bpm};
      return {std::clamp((double)active->velocity / 127.0, 0.0, 1.0),
              (double)active->pitch, 1.0, bpm};
    }
    // Channel-filtered lookup using cached events.
    const auto& evs = cached_midi_events(file);
    int active_pitch = -1, active_vel = 0;
    for (const auto& ev : evs) {
      if (ev.at > t) break;
      if (ev.channel != channel) continue;
      if (ev.on) {
        active_pitch = ev.pitch, active_vel = ev.velocity;
      } else if (ev.pitch == active_pitch) {
        active_pitch = -1, active_vel = 0;
      }
    }
    if (active_pitch < 0) return {0, 0, 0, bpm};
    return {std::clamp((double)active_vel / 127.0, 0.0, 1.0),
            (double)active_pitch, 1.0, bpm};
  };
  host.effect_param = [&d](int layer, const std::string& effect,
                           const std::string& param, double t) -> double {
    if (layer < 0 || effect.empty() || param.empty()) return std::nan("");
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    const std::string want_fx = norm_key(effect), want_p = norm_key(param);
    const auto match_script = [&](const std::string& entry, bool is_fx,
                                  double* out) -> bool {
      const std::string file = fx_entry_path(entry);
      if (file.empty()) return false;
      const std::string stem =
          norm_key(std::filesystem::path(file).stem().generic_string());
      const bool fx_exact = stem == want_fx;
      const bool fx_partial =
          !fx_exact && (stem.find(want_fx) != std::string::npos ||
                        want_fx.find(stem) != std::string::npos);
      if (!fx_exact && !fx_partial) return false;
      DocScript* sc = doc_script_of(d, file, false);
      if (!sc) return false;
      const std::string inst = is_fx ? doc_fx_values_id(d, entry) : "";
      for (size_t i = 0; i < sc->parameters.size(); ++i) {
        const ScriptParameter& p = sc->parameters[i];
        if (p.name == param || p.label == param || norm_key(p.name) == want_p ||
            norm_key(p.label) == want_p) {
          const std::string prop =
              inst.empty() ? sc->names[i]
                           : doc_screen_parameter(file, p.name, inst);
          *out = doc_number(d, layer, prop.c_str(), t, p.usual);
          return true;
        }
      }
      return false;
    };
    double found = std::nan("");
    for (const std::string& entry : doc_fx_entries(d, layer, false))
      if (match_script(entry, true, &found)) return found;
    if (const std::string sc = doc_word(d, layer, "script"); !sc.empty())
      if (match_script(sc, false, &found)) return found;
    // Direct fallback to js_<effect>_<param> or js_<param> if keyed manually.
    for (const std::string& candidate :
         {"js_" + want_fx + "_" + want_p, "js_" + want_fx, "js_" + want_p}) {
      if (!doc_keys_of(d, layer, candidate.c_str()).at.empty())
        return doc_number(d, layer, candidate.c_str(), t, std::nan(""));
    }
    return std::nan("");
  };
  run.reads_host(std::move(host));
}

}  // namespace motolii

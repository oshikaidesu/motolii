#include "entry/calls_sound.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "document/document.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/undo.h"
#include "entry/motolii.h"
#include "entry/motolii_handle.h"
#include "entry/on_render_thread.h"
#include "entry/window.h"
#include "media/sound_level.h"

using namespace motolii;

namespace motolii {

namespace {

// Returns the loudness in dB of a file's sound, sampled 100 times per second of
// the file's own time. The file is decoded once, as fast as it decodes, and the
// result is cached for the life of the process. If read_it is false and the
// file has not been read yet, returns nullptr instead of reading it. Safe to
// call from any thread.
const std::vector<float>* loudness_of(const std::string& file,
                                      bool read_it = true) {
  static std::map<std::string, std::vector<float>> read;
  static std::mutex one;
  std::lock_guard<std::mutex> hold(one);
  auto found = read.find(file);
  if (found == read.end()) {
    if (!read_it) return nullptr;
    found = read.emplace(file, sound_loudness(file.c_str(), 100.0)).first;
  }
  return &found->second;
}

}  // namespace

}  // namespace motolii

// Copies the loudness of a video layer's sound, in dB, to db: 100 samples per
// second of the video's own time, at most room of them. Returns how many
// samples the sound has, which can exceed room, or 0 if the layer is not a
// video or has no sound. Reads the file on first use.
int motolii_loudness(Motolii* m, int layer, float* db, int room) {
  const std::string file = by_look(m, [=] {
    return doc_knows(doc(m), layer) && doc_word(*m->d, layer, "kind") == "video"
               ? doc_word(*m->d, layer, "file")
               : std::string();
  });
  if (file.empty()) return 0;
  const std::vector<float>& all = *loudness_of(file);
  for (int i = 0; i < room && i < (int)all.size(); ++i) db[i] = all[(size_t)i];
  return (int)all.size();
}
// Fills db with the loudness in dB of a video layer's sound at n evenly spaced
// project times from `from` up to but not including `to`. A sample is -100
// where the layer is silent or not shown. Returns n, -1 if the sound has not
// been read yet (motolii_loudness reads it), or 0 if the layer has no sound.
int motolii_loudness_over(Motolii* m, int layer, double from, double to, int n,
                          float* db) {
  const std::string file = by_look(m, [=] {
    return doc_knows(doc(m), layer) && doc_word(*m->d, layer, "kind") == "video"
               ? doc_word(*m->d, layer, "file")
               : std::string();
  });
  if (file.empty()) return 0;
  const std::vector<float>* all = loudness_of(file, false);
  if (!all) return -1;
  if (all->empty()) return 0;
  // Project time s maps to the video's own time as begin + (s - start) * speed,
  // where start is when the layer comes on and begin is where in the video it
  // starts playing.
  return by_look(m, [&] {
    Doc& d = *m->d;
    const double start = doc_number(d, layer, "start", 0, 0),
                 begin = doc_number(d, layer, "begin", 0, 0),
                 speed = doc_number(d, layer, "speed", 0, 1),
                 lasts = doc_number(d, layer, "duration", 0, -1);
    for (int i = 0; i < n; ++i) {
      const double s = from + (to - from) * i / n,
                   own = begin + (s - start) * speed;
      const long k = std::lround(own * 100.0);
      db[i] = s < start || (lasts > 0.0 && s >= start + lasts) || k < 0 ||
                      k >= (long)all->size()
                  ? -100.f
                  : (*all)[(size_t)k];
    }
    return n;
  });
}

namespace motolii {

bool duck(Motolii* m, int layer) {
  Doc& d = *m->d;
  if (!doc_knows(d, layer) || doc_word(d, layer, "kind") != "video")
    return d.error = "a film or a sound is ducked", false;
  if (doc_keys(d, layer, "volume"))
    return d.error = "its volume has keys already", false;
  const double rate = 100.0, from = doc_number(d, layer, "start", 0, 0),
               lasts = doc_number(d, layer, "duration", 0, -1),
               to = lasts > 0.0 ? from + lasts : doc_seconds(d);
  std::vector<char> loud((size_t)std::max(0.0, std::ceil((to - from) * rate)),
                         0);
  bool any = false;
  for (const int t : doc_layers(d)) {
    if (t == layer || doc_word(d, t, "kind") != "video") continue;
    const std::vector<float>* all = loudness_of(doc_word(d, t, "file"), false);
    if (!all) return d.error = "the other sounds are not read yet", false;
    const double start = doc_number(d, t, "start", 0, 0),
                 begin = doc_number(d, t, "begin", 0, 0),
                 speed = doc_number(d, t, "speed", 0, 1),
                 its = doc_number(d, t, "duration", 0, -1);
    // Map project time to the video's own time as in motolii_loudness_over.
    for (size_t i = 0; i < loud.size(); ++i) {
      const double s = from + (double)i / rate;
      const long k = std::lround((begin + (s - start) * speed) * 100.0);
      if (s >= start && (its <= 0.0 || s < start + its) && k >= 0 &&
          k < (long)all->size() && (*all)[(size_t)k] > -30.f)
        loud[i] = any = true;
    }
  }
  if (!any)
    return d.error = "no other sound is louder than -30 dB while it plays",
           false;
  std::vector<std::pair<double, double>> runs;
  for (size_t i = 0; i < loud.size();) {
    if (!loud[i]) {
      ++i;
      continue;
    }
    size_t j = i;
    while (j < loud.size() && loud[j]) ++j;
    const double a = from + (double)i / rate, b = from + (double)j / rate;
    // Merge with the previous loud stretch when the gap is under one second,
    // which is Audacity's Maximum Pause setting.
    if (!runs.empty() && a - runs.back().second < 1.0)
      runs.back().second = b;
    else
      runs.push_back({a, b});
    i = j;
  }
  const double was = doc_number(d, layer, "volume", 0, 1),
               low = was * std::pow(10.0, -12.0 / 20.0);
  doc_act(d);
  for (const auto& [a, b] : runs)
    if (!(doc_key(d, layer, "volume", std::max(from, a - 0.5), was) &&
          doc_key(d, layer, "volume", a, low) &&
          doc_key(d, layer, "volume", b, low) &&
          doc_key(d, layer, "volume", std::min(to, b + 0.5), was)))
      d.act.ok = false;
  return doc_acted(d);
}

}  // namespace motolii

// Finds the times where a video's sound grows louder by at least `rise` dB
// within 30 ms. If own is nonzero the times are in the video's own seconds.
// Otherwise they are mapped to project time, and times outside the part of the
// video that the layer shows are dropped. Writes at most room times to at and
// returns how many there are, which can exceed room, or 0 if the layer is not a
// video.
int motolii_strikes(Motolii* m, int layer, double rise, int own, double* at,
                    int room) {
  const std::string file = by_look(m, [=] {
    return doc_knows(doc(m), layer) && doc_word(*m->d, layer, "kind") == "video"
               ? doc_word(*m->d, layer, "file")
               : std::string();
  });
  if (file.empty()) return 0;
  const std::vector<double> struck =
      sound_strikes(*loudness_of(file), 100.0, rise);
  // The video's own seconds, as its loudness is counted.
  if (own) {
    for (int i = 0; i < room && i < (int)struck.size(); ++i)
      at[i] = struck[(size_t)i];
    return (int)struck.size();
  }
  // Map the video's own seconds to project time: the layer's start, plus the
  // time since the video's begin offset divided by the speed, while the layer
  // lasts.
  return by_look(m, [&] {
    Doc& d = *m->d;
    const double start = doc_number(d, layer, "start", 0, 0),
                 begin = doc_number(d, layer, "begin", 0, 0),
                 speed = doc_number(d, layer, "speed", 0, 1),
                 lasts = doc_number(d, layer, "duration", 0, -1);
    int n = 0;
    for (const double t : struck) {
      const double when = speed == 0.0 ? -1.0 : start + (t - begin) / speed;
      if (when < start || (lasts > 0.0 && when >= start + lasts)) continue;
      if (n < room) at[n] = when;
      ++n;
    }
    return n;
  });
}

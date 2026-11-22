#include "document/evaluate/value_at.h"

#include <sqlite3.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <functional>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "document/document.h"
#include "media/midi_notes.h"
#include "media/sound_level.h"
#include "motion/easing_curves.h"
#include "motion/easing_names.h"
#include "stage/effects/screen_fx.h"

namespace motolii {

bool doc_rows(Doc& d, char* ask,
              const std::function<void(sqlite3_stmt*)>& each) {
  sqlite3_stmt* rows = nullptr;
  bool ok = sqlite3_prepare_v2(d.file, ask, -1, &rows, nullptr) == SQLITE_OK;
  while (ok && sqlite3_step(rows) == SQLITE_ROW)
    if (each) each(rows);
  sqlite3_finalize(rows);
  sqlite3_free(ask);
  return ok;
}

void doc_forget(Doc& d) {
  d.place_cache.scripted.clear();
  d.value_cache.moving.clear(), d.value_cache.literals.clear(),
      d.value_cache.words.clear(), d.value_cache.keyed.clear(),
      d.place_cache.halves.clear(), d.value_cache.heardWords.clear(),
      d.place_cache.talls.clear(), d.place_cache.placing.clear();
  d.value_cache.named.clear(), d.place_cache.tracks.clear(),
      d.relations.drivers.clear(), d.relations.connects.clear(),
      d.relations.relationsOf.clear();
  d.value_cache.laid.clear();
  d.value_cache.macro_maps.clear();
  d.value_cache.macro_sources.clear();
}

void doc_forget_keys(Doc& d, int layer) {
  d.value_cache.moving.erase(layer);
  d.value_cache.macro_maps.erase(layer);
  d.value_cache.macro_sources.erase(layer);
  // literals stores pointers into moving; erase them too or they dangle.
  for (auto it = d.value_cache.literals.begin();
       it != d.value_cache.literals.end();) {
    if (it->first.first == layer)
      it = d.value_cache.literals.erase(it);
    else
      ++it;
  }
  for (auto it = d.value_cache.heardWords.begin();
       it != d.value_cache.heardWords.end();) {
    if (it->first.first == layer)
      it = d.value_cache.heardWords.erase(it);
    else
      ++it;
  }
  for (auto it = d.value_cache.keyed.begin();
       it != d.value_cache.keyed.end();) {
    if (it->first.first == layer)
      it = d.value_cache.keyed.erase(it);
    else
      ++it;
  }
}

const std::vector<int>& doc_laid(Doc& d) {
  if (d.value_cache.laid.empty())
    doc_rows(
        d,
        sqlite3_mprintf(
            "select f.layer from keyframe f where f.name = 'kind' order by "
            "coalesce((select o.value from keyframe o where o.layer = f.layer "
            "and o.name = 'order' and o.at = 0), f.layer), f.layer"),
        [&](sqlite3_stmt* row) {
          d.value_cache.laid.push_back(sqlite3_column_int(row, 0));
        });
  return d.value_cache.laid;
}

sqlite3_stmt* doc_expression_statement(Doc& d, const std::string& expression) {
  auto ready = d.value_cache.expression_statements.find(expression);
  if (ready != d.value_cache.expression_statements.end()) return ready->second;
  sqlite3_stmt* made = nullptr;
  char* asked = sqlite3_mprintf(
      "with v(u, t, d, a, b, p1, p2, p3, p4) as (select ?, ?, ?, ?, ?, ?, ?, "
      "?, ?) select (%s) from v",
      expression.c_str());
  if (sqlite3_prepare_v2(d.file, asked, -1, &made, nullptr) != SQLITE_OK)
    d.error = sqlite3_errmsg(d.file), made = nullptr;
  sqlite3_free(asked);
  return made ? d.value_cache.expression_statements[expression] = made
              : nullptr;
}

double doc_went(sqlite3_stmt* statement, double u, double t, double length,
                double a, double b, const double* p) {
  const double told[] = {u, t, length, a, b, p[0], p[1], p[2], p[3]};
  for (int i = 0; i < 9; ++i) sqlite3_bind_double(statement, i + 1, told[i]);
  const double is = sqlite3_step(statement) == SQLITE_ROW
                        ? sqlite3_column_double(statement, 0)
                        : a;
  sqlite3_reset(statement);
  return is;
}

sqlite3_stmt* doc_easing_named(Doc& d, const std::string& name) {
  auto known = d.value_cache.named.find(name);
  if (known != d.value_cache.named.end()) return known->second;
  sqlite3_stmt* statement = nullptr;
  doc_rows(d,
           sqlite3_mprintf("select expression from easing where name = %Q",
                           name.c_str()),
           [&](sqlite3_stmt* row) {
             statement = doc_expression_statement(
                 d, (const char*)sqlite3_column_text(row, 0));
           });
  // Not defined in the project, so try the built-in easings.
  if (!statement)
    for (const auto& one : named_ways)
      if (name == one.name)
        statement = doc_expression_statement(
            d, std::string("a + (b - a) * (") + one.goes + ")");
  return d.value_cache.named[name] = statement;
}

double doc_went_by(Doc& d, const std::string& own, double u, double t,
                   double length, double a, double b) {
  std::istringstream said(own);
  std::string easing;
  double p[4] = {0, 0, 0, 0};
  said >> easing;
  for (double& one : p) said >> one;
  sqlite3_stmt* statement = doc_easing_named(d, easing);
  return statement ? doc_went(statement, u, t, length, a, b, p) : a;
}

namespace {
// Returns the nearest ancestor of `layer` that is a nested element (see
// doc_element_add), or 0 if there is none.
int doc_element_above(Doc& d, int layer) {
  for (int p = layer, n = 0; p && n < 64; ++n) {
    const DocKeys& up = doc_keys_of(d, p, "parent");
    p = up.value.empty() ? 0 : (int)up.value.front();
    if (const DocKeys& was = doc_keys_of(d, p, "element_length");
        p && !was.value.empty() && was.value.front() > 0.0)
      return p;
  }
  return 0;
}
// Maps stage time `at` to the time inside nested element `el`, which may be
// shorter or longer than the element's original length. The intro and outro
// keep their original timing. The middle is held, stretched, looped, or looped
// and stretched, according to the `retime` property. After the end the clock is
// blank. Follows Alight Motion's Re-timing and the at() function of NestedClock
// in AbsentMotion's NestedScenes.kt (Apache-2.0, Copyright 2026 The
// AbsentMotion authors). Times are in seconds and are not rounded to frame
// centers. Freeze holds the center of the last frame
// middle() does, rather than the time just after the scene end. Returns -1e9
// when the element is not visible at `at` (the Blank method).
double doc_element_clock(Doc& d, int el, double at) {
  const double origin = doc_keys_at(d, doc_keys_of(d, el, "start"), 0, 0),
               scene_end =
                   doc_keys_at(d, doc_keys_of(d, el, "element_length"), 0, 0);
  const double lasts = doc_keys_at(d, doc_keys_of(d, el, "duration"), 0, -1),
               layer_end = lasts >= 0.0 ? lasts : scene_end;
  const std::string method = doc_word(d, el, "retime");
  const double local = at - origin;
  if (method == "blank") return local < scene_end ? at : -1e9;
  const double intro = std::clamp(
                   doc_keys_at(d, doc_keys_of(d, el, "retime_in"), 0, 0), 0.0,
                   scene_end),
               out = doc_keys_at(d, doc_keys_of(d, el, "retime_out"), 0, 0);
  const double outro =
                   out > 0.0 ? std::clamp(out, intro, scene_end) : scene_end,
               outro_start = layer_end - (scene_end - outro),
               room = outro_start - intro, span = outro - intro;
  double mapped = local;
  if (local >= outro_start)
    mapped = outro + local - outro_start;
  else if (local >= intro) {
    const double into = local - intro;
    if (method == "stretch" && room > 0.0)
      mapped = intro + into * span / room;
    else if (method == "loop")
      mapped = intro + (span > 0.0 ? std::fmod(into, span) : 0.0);
    else if (method == "loop_stretch" && span > 0.0 && room > 0.0) {
      const double each = room / std::max(1.0, std::round(room / span));
      mapped = intro + std::fmod(into, each) * span / each;
    } else {
      // Freeze, the default method for a new element.
      const double fps = d.stage ? screen_rate(*d.stage) : 60.0,
                   held = (std::ceil(outro * fps - 1e-9) - 0.5) / fps;
      mapped = into < span ? intro + into : std::max(intro, held);
    }
  }
  return origin + mapped;
}
}  // namespace

double doc_element_now(Doc& d, int layer, double at) {
  const int el = layer ? doc_element_above(d, layer) : 0;
  return el ? doc_element_clock(d, el, at) : at;
}

double doc_stepped(Doc& d, int layer, const DocKeys& k, double at) {
  if (k.at.size() < 2 || !layer) return at;
  at = doc_element_now(d, layer, at);
  const DocKeys& rate = doc_keys_of(d, layer, "frame_rate");
  if (rate.value.empty() || !(rate.value.front() > 0.0)) return at;
  const DocKeys& from = doc_keys_of(d, layer, "start");
  const double start = from.value.empty() ? 0.0 : from.value.front(),
               r = rate.value.front();
  return at <= start ? at : start + std::floor((at - start) * r + 1e-9) / r;
}

namespace {
// Returns the macro target driving `name` on `layer` from its `macro_map` word
// ("<slot> <prop> <lo> <hi>" per line), or nullptr when unmapped.
const DocValueCache::MacroTarget* doc_macro_target(Doc& d, int layer,
                                                   const char* name) {
  if (layer <= 0 || !name || std::strncmp(name, "macro_", 6) == 0)
    return nullptr;
  auto it = d.value_cache.macro_maps.find(layer);
  if (it == d.value_cache.macro_maps.end()) {
    std::unordered_map<std::string, DocValueCache::MacroTarget,
                       DocValueCache::NameHash, std::equal_to<>>
        parsed;
    const std::string raw = doc_word(d, layer, "macro_map");
    if (!raw.empty()) {
      std::istringstream lines(raw);
      for (std::string line; std::getline(lines, line);) {
        std::istringstream in(line);
        int slot = 0;
        std::string prop;
        double lo = 0.0, hi = 1.0;
        if ((in >> slot >> prop >> lo >> hi) && slot >= 1 && slot <= 8 &&
            !prop.empty() && prop.rfind("macro_", 0) != 0) {
          parsed[std::move(prop)] = {slot, lo, hi};
        }
      }
    }
    it = d.value_cache.macro_maps.emplace(layer, std::move(parsed)).first;
  }
  const auto found = it->second.find(std::string_view(name));
  return found == it->second.end() ? nullptr : &found->second;
}

// Parses `macro_sources` word property once per layer into 8 slot descriptors.
const DocValueCache::MacroSource& doc_macro_source(Doc& d, int layer,
                                                   int slot) {
  static const DocValueCache::MacroSource kDefault{};
  if (layer <= 0 || slot < 1 || slot > 8) return kDefault;
  auto it = d.value_cache.macro_sources.find(layer);
  if (it == d.value_cache.macro_sources.end()) {
    std::array<DocValueCache::MacroSource, 8> parsed{};
    const std::string raw = doc_word(d, layer, "macro_sources");
    if (!raw.empty()) {
      std::istringstream lines(raw);
      for (std::string line; std::getline(lines, line);) {
        std::istringstream in(line);
        int s = 0;
        std::string kind;
        if (!(in >> s >> kind) || s < 1 || s > 8) continue;
        DocValueCache::MacroSource src;
        if (kind == "wave") {
          src.kind = DocValueCache::MacroSource::kWave;
          src.sub = "sine";
          src.a = 1.0;
          src.b = 0.0;
          in >> src.sub >> src.a >> src.b;
        } else if (kind == "audio") {
          src.kind = DocValueCache::MacroSource::kAudio;
          src.ref = 0;
          src.a = 1.5;
          src.b = 0.05;
          in >> src.ref >> src.a >> src.b;
        } else if (kind == "midi") {
          src.kind = DocValueCache::MacroSource::kMidi;
          src.sub = "vel";
          src.ref = -1;
          in >> src.sub >> src.ref;
          std::string rest;
          std::getline(in, rest);
          const size_t first = rest.find_first_not_of(" \t\r");
          if (first != std::string::npos) src.path = rest.substr(first);
        } else if (kind == "layer") {
          src.kind = DocValueCache::MacroSource::kLayer;
          src.ref = 0;
          src.sub = "rotate";
          src.a = 0.0;
          src.b = 1.0;
          in >> src.ref >> src.sub >> src.a >> src.b;
        } else {
          src.kind = DocValueCache::MacroSource::kKnob;
        }
        parsed[(size_t)(s - 1)] = std::move(src);
      }
    }
    it = d.value_cache.macro_sources.emplace(layer, std::move(parsed)).first;
  }
  return it->second[(size_t)(slot - 1)];
}

double macro_hash01(int64_t n) {
  uint64_t x = (uint64_t)n * 0x9e3779b97f4a7c15ULL;
  x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
  x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
  x = x ^ (x >> 31);
  return (double)(x >> 11) * (1.0 / (double)(1ULL << 53));
}

double eval_wave_signal(const std::string& shape, double hz, double phase,
                        double at) {
  const double t = at * hz + phase;
  const double f = t - std::floor(t);
  if (shape == "tri") return 1.0 - std::fabs(2.0 * f - 1.0);
  if (shape == "saw") return f;
  if (shape == "square") return f < 0.5 ? 1.0 : 0.0;
  if (shape == "noise") {
    const int64_t i = (int64_t)std::floor(t);
    const double u = f * f * (3.0 - 2.0 * f);
    return macro_hash01(i) * (1.0 - u) + macro_hash01(i + 1) * u;
  }
  constexpr double kTwoPi = 6.28318530717958647692;
  return 0.5 + 0.5 * std::sin(kTwoPi * t);
}

double eval_audio_layer_rms(Doc& d, int src_layer, double at, double smooth) {
  const std::string file = doc_word(d, src_layer, "file");
  if (file.empty()) return 0.0;
  const SoundRead* read = sound_of(file);
  if (!read) return 0.0;
  const double start = doc_number(d, src_layer, "start", 0, 0),
               lasts = doc_number(d, src_layer, "duration", 0, -1);
  if (at < start || (lasts >= 0 && at >= start + lasts)) return 0.0;
  const double begin = doc_number(d, src_layer, "begin", 0, 0),
               speed = doc_number(d, src_layer, "speed", 0, 1),
               vol = std::max(0.0, doc_number(d, src_layer, "volume", at, 1));
  if (vol <= 0.0) return 0.0;
  const int n =
      std::clamp((int)std::lround(std::max(0.02, smooth) * sound_rate), 512,
                 16384);
  std::vector<float> wave((size_t)n, 0.f);
  sound_wave(read, begin + (at - start) * speed, wave.data(), n);
  double sq = 0.0;
  for (float s : wave) sq += (double)s * (double)s;
  return std::sqrt(sq / (double)n) * 2.5 * vol;
}

double eval_audio_signal(Doc& d, int ref_layer, double gain, double smooth,
                         double at) {
  double level = 0.0;
  if (ref_layer > 0) {
    level = eval_audio_layer_rms(d, ref_layer, at, smooth);
  } else {
    for (const int t : doc_laid(d)) {
      if (doc_word(d, t, "kind") != "video") continue;
      level = std::max(level, eval_audio_layer_rms(d, t, at, smooth));
    }
  }
  return std::clamp(level * std::max(0.0, gain), 0.0, 1.0);
}

double eval_midi_signal(Doc& d, int layer, const std::string& mode,
                        const std::string& path, double at) {
  std::string file = path;
  if (file.empty()) {
    file = doc_word(d, layer, "script");
  } else if (file.rfind("layer:", 0) == 0) {
    const int src = std::atoi(file.c_str() + 6);
    file = src > 0 ? doc_word(d, src, "script") : "";
  }
  if (file.empty()) return 0.0;
  const auto& notes = midi_of(file);
  const MidiNote* active = nullptr;
  for (const auto& note : notes) {
    if (note.on > at) break;
    if (at < note.off) active = &note;
  }
  if (!active) return 0.0;
  if (mode == "gate") return 1.0;
  if (mode == "pitch")
    return std::clamp(((double)active->pitch - 24.0) / 84.0, 0.0, 1.0);
  return std::clamp((double)active->velocity / 127.0, 0.0, 1.0);
}

int macro_slot_of(const char* name) {
  if (!name || std::strncmp(name, "macro_", 6) != 0) return 0;
  if (name[6] >= '1' && name[6] <= '8' && name[7] == '\0')
    return name[6] - '0';
  return 0;
}

// Evaluates a macro slot's normalized 0..1 signal at time `at`.
// Cycle-guarded so cross-layer bindings cannot recurse infinitely.
double doc_macro_signal(Doc& d, int layer, int slot, double at) {
  thread_local int macro_depth = 0;
  if (macro_depth >= 8 || slot < 1 || slot > 8) return 0.0;
  struct Guard {
    int& depth;
    Guard(int& v) : depth(v) { ++depth; }
    ~Guard() { --depth; }
  } guard(macro_depth);

  const auto& src = doc_macro_source(d, layer, slot);
  switch (src.kind) {
    case DocValueCache::MacroSource::kWave:
      return std::clamp(eval_wave_signal(src.sub, src.a, src.b, at), 0.0, 1.0);
    case DocValueCache::MacroSource::kAudio:
      return eval_audio_signal(d, src.ref, src.a, src.b, at);
    case DocValueCache::MacroSource::kMidi:
      return eval_midi_signal(d, layer, src.sub, src.path, at);
    case DocValueCache::MacroSource::kLayer: {
      if (src.ref <= 0 || src.sub.empty()) return 0.0;
      const double span = src.b - src.a;
      if (std::fabs(span) < 1e-12) return 0.0;
      const double v = doc_number(d, src.ref, src.sub.c_str(), at, src.a);
      return std::clamp((v - src.a) / span, 0.0, 1.0);
    }
    case DocValueCache::MacroSource::kKnob:
    default: {
      static constexpr const char* kMacros[8] = {"macro_1", "macro_2",
                                                 "macro_3", "macro_4",
                                                 "macro_5", "macro_6",
                                                 "macro_7", "macro_8"};
      const char* name = kMacros[slot - 1];
      if (d.held.layer == layer)
        if (const auto tried = d.held.tried.find(name);
            tried != d.held.tried.end())
          return std::clamp(tried->second, 0.0, 1.0);
      const DocKeys& k = doc_keys_of(d, layer, name);
      return std::clamp(doc_keys_at(d, k, doc_stepped(d, layer, k, at), 0.0),
                        0.0, 1.0);
    }
  }
}
}  // namespace

double doc_number(Doc& d, int layer, const char* name, double at,
                  double otherwise) {
  if (d.held.layer == layer)
    if (const auto tried = d.held.tried.find(name); tried != d.held.tried.end())
      return tried->second;
  if (const int slot = macro_slot_of(name); slot > 0) {
    if (doc_macro_source(d, layer, slot).kind !=
        DocValueCache::MacroSource::kKnob)
      return doc_macro_signal(d, layer, slot, at);
  }
  if (const auto* target = doc_macro_target(d, layer, name)) {
    const double m = doc_macro_signal(d, layer, target->slot, at);
    return target->lo + (target->hi - target->lo) * m;
  }
  const DocKeys& k = doc_keys_of(d, layer, name);
  return doc_keys_at(d, k, doc_stepped(d, layer, k, at), otherwise);
}

double doc_cel(Doc& d, int layer, double at) {
  const DocKeys& k = doc_keys_of(d, layer, "cel");
  double held = k.value.empty() ? 1.0 : k.value.front();
  for (size_t i = 0; i < k.at.size() && k.at[i] <= at + 1e-9; ++i)
    held = k.value[i];
  return (double)std::llround(held);
}

const DocKeys& doc_keys_of(Doc& d, int layer, const char* name) {
  if (d.solver.reading) d.solver.reading->insert(layer);
  auto& of = d.value_cache.moving[layer];
  auto found = of.find(std::string_view(name));
  if (found == of.end()) {
    DocKeys keys;
    doc_rows(
        d,
        sqlite3_mprintf("select at, value, coalesce(easing, '') from keyframe "
                        "where layer = %d and name = %Q order by at",
                        layer, name),
        [&](sqlite3_stmt* row) {
          keys.at.push_back(sqlite3_column_double(row, 0));
          keys.value.push_back(sqlite3_column_double(row, 1));
          const std::string easing = (const char*)sqlite3_column_text(row, 2);
          Interp kind;
          // An empty easing means Linear. A name that is not one of the nine
          // built-in kinds is a project-defined easing, kept in keys.own.
          const bool of_the_nine =
              interp_said(easing.empty() ? "Linear" : easing, &kind) == 0;
          keys.interp.push_back(kind);
          keys.own.push_back(of_the_nine ? "" : easing);
        });
    // The `<name>_loop` property says how the keys repeat after the last one;
    // see doc_keys_at.
    if (keys.at.size() > 1)
      keys.loop = doc_word(d, layer, (std::string(name) + "_loop").c_str());
    found = d.value_cache.moving[layer]
                .emplace(std::string(name), std::move(keys))
                .first;
  }
  return found->second;
}

double doc_keys_at(Doc& d, const DocKeys& k, double at, double otherwise) {
  if (k.at.empty()) return otherwise;
  if (k.at.size() == 1 || at <= k.at.front()) return k.value.front();
  // Past the last keyframe the keys can repeat
  // "cycle", "pingpong" or "offset", applied to all keys. With "offset" each
  // repeat starts where the previous one ended.
  double on = 0.0;
  if (at > k.at.back() &&
      (k.loop == "cycle" || k.loop == "pingpong" || k.loop == "offset")) {
    const double span = k.at.back() - k.at.front(),
                 rounds = std::floor((at - k.at.front()) / span),
                 left = at - k.at.front() - rounds * span;
    at = k.loop == "pingpong" && std::fmod(rounds, 2.0) != 0.0
             ? k.at.back() - left
             : k.at.front() + left;
    if (k.loop == "offset") on = rounds * (k.value.back() - k.value.front());
  }
  if (at <= k.at.front()) return k.value.front() + on;
  if (at >= k.at.back()) return k.value.back() + on;
  // The segment containing `at` begins at keyframe i.
  const size_t i =
      (size_t)(std::upper_bound(k.at.begin(), k.at.end(), at) - k.at.begin()) -
      1;
  const double u = (at - k.at[i]) / (k.at[i + 1] - k.at[i]);
  if (k.own[i].empty())
    return k.value[i] +
           (k.value[i + 1] - k.value[i]) * interp_ease(k.interp[i], u) + on;
  return doc_went_by(d, k.own[i], u, at - k.at[i], k.at[i + 1] - k.at[i],
                     k.value[i], k.value[i + 1]) +
         on;
}

std::string doc_word(Doc& d, int layer, const char* name) {
  // Layer 0 is the stage; its properties apply to the whole image.
  if (layer == 0 && !strcmp(name, "kind")) return "stage";
  if (d.held.layer == layer)
    if (const auto said = d.held.said.find(name); said != d.held.said.end())
      return said->second;
  // The same property is read many times between changes, so the database is
  // queried once.
  const auto known = d.value_cache.words.find({layer, name});
  if (known != d.value_cache.words.end()) return known->second;
  std::string is;
  doc_rows(d,
           sqlite3_mprintf(
               "select value from keyframe where layer = %d and name = %Q",
               layer, name),
           [&](sqlite3_stmt* row) {
             is = (const char*)sqlite3_column_text(row, 0);
           });
  d.value_cache.words.emplace(std::make_pair(layer, std::string(name)), is);
  return is;
}

}  // namespace motolii

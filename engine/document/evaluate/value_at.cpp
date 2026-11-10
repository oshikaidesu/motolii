#include "document/evaluate/value_at.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <functional>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "document/kinds.h"
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
  // The physics world is rebuilt only if its inputs changed; see doc_physics.
  d.phys_stale = true, d.scripted.clear();
  d.moving.clear(), d.literals.clear(), d.words.clear(), d.keyed.clear(),
      d.halves.clear(), d.heardWords.clear(), d.talls.clear(),
      d.placing.clear();
  d.named.clear(), d.tracks.clear(), d.drivers.clear(), d.connects.clear(),
      d.relationsOf.clear();
  d.laid.clear();
}

const std::vector<int>& doc_laid(Doc& d) {
  if (d.laid.empty())
    doc_rows(
        d,
        sqlite3_mprintf(
            "select f.layer from keyframe f where f.name = 'kind' order by "
            "coalesce((select o.value from keyframe o where o.layer = f.layer "
            "and o.name = 'order' and o.at = 0), f.layer), f.layer"),
        [&](sqlite3_stmt* row) {
          d.laid.push_back(sqlite3_column_int(row, 0));
        });
  return d.laid;
}

sqlite3_stmt* doc_expression_statement(Doc& d, const std::string& expression) {
  auto ready = d.expression_statements.find(expression);
  if (ready != d.expression_statements.end()) return ready->second;
  sqlite3_stmt* made = nullptr;
  char* asked = sqlite3_mprintf(
      "with v(u, t, d, a, b, p1, p2, p3, p4) as (select ?, ?, ?, ?, ?, ?, ?, "
      "?, ?) select (%s) from v",
      expression.c_str());
  if (sqlite3_prepare_v2(d.file, asked, -1, &made, nullptr) != SQLITE_OK)
    d.error = sqlite3_errmsg(d.file), made = nullptr;
  sqlite3_free(asked);
  return made ? d.expression_statements[expression] = made : nullptr;
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
  auto known = d.named.find(name);
  if (known != d.named.end()) return known->second;
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
  return d.named[name] = statement;
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
    const Doc::Keys& up = doc_keys_of(d, p, "parent");
    p = up.value.empty() ? 0 : (int)up.value.front();
    if (const Doc::Keys& was = doc_keys_of(d, p, "element_length");
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
// centers. Freeze holds the center of the last frame, as AbsentMotion's
// middle() does, rather than the time just after the scene end. Returns -1e9
// when the element is not visible at `at` (the Blank method).
double doc_element_clock(Doc& d, int el, double at) {
  const double origin = doc_keys_at(d, doc_keys_of(d, el, "start"), 0, 0),
               scene_end =
                   doc_keys_at(d, doc_keys_of(d, el, "element_length"), 0, 0);
  const double lasts = doc_keys_at(d, doc_keys_of(d, el, "duration"), 0, -1),
               layer_end = lasts > 0.0 ? lasts : scene_end;
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

double doc_stepped(Doc& d, int layer, const Doc::Keys& k, double at) {
  if (k.at.size() < 2 || !layer) return at;
  at = doc_element_now(d, layer, at);
  const Doc::Keys& rate = doc_keys_of(d, layer, "frame_rate");
  if (rate.value.empty() || !(rate.value.front() > 0.0)) return at;
  const Doc::Keys& from = doc_keys_of(d, layer, "start");
  const double start = from.value.empty() ? 0.0 : from.value.front(),
               r = rate.value.front();
  return at <= start ? at : start + std::floor((at - start) * r + 1e-9) / r;
}

double doc_number(Doc& d, int layer, const char* name, double at,
                  double otherwise) {
  if (d.held.layer == layer)
    if (const auto tried = d.held.tried.find(name); tried != d.held.tried.end())
      return tried->second;
  const Doc::Keys& k = doc_keys_of(d, layer, name);
  return doc_keys_at(d, k, doc_stepped(d, layer, k, at), otherwise);
}

double doc_cel(Doc& d, int layer, double at) {
  const Doc::Keys& k = doc_keys_of(d, layer, "cel");
  double held = k.value.empty() ? 1.0 : k.value.front();
  for (size_t i = 0; i < k.at.size() && k.at[i] <= at + 1e-9; ++i)
    held = k.value[i];
  return (double)std::llround(held);
}

const Doc::Keys& doc_keys_of(Doc& d, int layer, const char* name) {
  if (d.reading) d.reading->insert(layer);
  auto& of = d.moving[layer];
  auto found = of.find(std::string_view(name));
  if (found == of.end()) {
    Doc::Keys keys;
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
    found = d.moving[layer].emplace(std::string(name), std::move(keys)).first;
  }
  return found->second;
}

double doc_keys_at(Doc& d, const Doc::Keys& k, double at, double otherwise) {
  if (k.at.empty()) return otherwise;
  if (k.at.size() == 1 || at <= k.at.front()) return k.value.front();
  // Past the last keyframe the keys can repeat, as in After Effects' loopOut:
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
  const auto known = d.words.find({layer, name});
  if (known != d.words.end()) return known->second;
  std::string is;
  doc_rows(d,
           sqlite3_mprintf(
               "select value from keyframe where layer = %d and name = %Q",
               layer, name),
           [&](sqlite3_stmt* row) {
             is = (const char*)sqlite3_column_text(row, 0);
           });
  d.words.emplace(std::make_pair(layer, std::string(name)), is);
  return is;
}

}  // namespace motolii

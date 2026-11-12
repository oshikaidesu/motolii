#include "document/evaluate/world.h"

#include <math/vec2.h>
#include <math/vec3.h>
#include <sqlite3.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstring>
#include <functional>
#include <iterator>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "community/script_runner/script_runner.h"
#include "document/document.h"
#include "document/evaluate/kept_frames.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/script_reads.h"
#include "document/scripts/scripts.h"

namespace motolii {

namespace math = filament::math;
using filament::math::float2;

namespace {
// Returns the script parameters of relation `by` at time `at` as the text of a
// JavaScript object literal. Choice parameters send the selected word, or the
// first choice when none is selected.
std::string doc_relate_parameters(Doc& d, int by, const DocScript& sc,
                                  double at) {
  std::ostringstream js;
  js.precision(12);
  js << '{';
  for (size_t i = 0; i < sc.parameters.size(); ++i) {
    js << sc.parameters[i].name << ':';
    if (sc.parameters[i].kind != "select") {
      js << doc_number(d, by, sc.names[i].c_str(), at, sc.parameters[i].usual)
         << ',';
      continue;
    }
    const std::string w = doc_word(d, by, sc.names[i].c_str());
    js << '"'
       << (w.empty() ? sc.parameters[i].words.substr(
                           0, sc.parameters[i].words.find(' '))
                     : w)
       << "\",";
  }
  js << '}';
  return js.str();
}
}  // namespace

const std::vector<double>& doc_related_all(Doc& d, int by, double t) {
  DocSolver::RelatedKept& k = d.solver.relatedKept[by];
  // A relation asked for while it is being worked out, because its script read
  // a layer that one of its own layers leads to, gives nothing: those layers
  // show what is under it.
  static std::set<int> working;
  if (working.count(by)) return k.values;
  struct Working {
    int by;
    explicit Working(int by) : by(by) { working.insert(by); }
    ~Working() { working.erase(by); }
  } work(by);
  DocKeptTells tells{d, k};
  if (doc_kept_stands(d, k, t)) return k.values;
  k.values.clear();
  DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
  if (!sc || !sc->run || !sc->run->ok()) return k.values;
  if (k.solves < 0) {
    const std::vector<double> takes =
        sc->run->numbers("Float64Array.of(__relate().length)");
    k.solves = !takes.empty() && takes[0] > 3;
  }
  const DocRelation& rel = doc_relation_of(d, by);
  constexpr size_t many = std::size(doc_relate_names);
  // What the script reads of other layers: layerValue() and the rest.
  doc_script_reads(d, *sc->run);
  const auto tell = [&](double at, size_t frame) {
    std::ostringstream js;
    js.precision(12);
    js << "__relates([";
    for (size_t i = 0; i < rel.members.size(); ++i) {
      const int layer = rel.members[i];
      if (!layer) continue;
      const int was = rel.under.empty() ? 0 : rel.under[i];
      js << '[';
      double size = 1;
      math::double3 place{0.0};
      for (const char* name : doc_relate_names) {
        const double own = doc_number(
                         d, layer, name, at,
                         !strcmp(name, "size") || !strcmp(name, "opacity") ? 1
                                                                           : 0),
                     is = was ? doc_related(d, was, layer, name, at, own) : own;
        if (!strcmp(name, "size")) size = is;
        if (name[0] >= 'x' && !name[1]) place[name[0] - 'x'] = is;
        js << is << ',';
      }
      float2 half{0.f};
      doc_half(d, layer, &half);
      js << 2.0 * half.x * size << ',' << 2.0 * half.y * size << ',' << layer
         << ',' << doc_falloff_at(d, by, place, at) << ',';
      // Where it showed when it joined, x and y, or NaN where that is not
      // known.
      for (size_t axis = 0; axis < 2; ++axis) {
        const double came =
            rel.from.empty() ? std::nan("") : rel.from[2 * i + axis];
        if (std::isnan(came))
          js << "NaN,";
        else
          js << came << ',';
      }
      js << "],";
    }
    js << "]," << at << ',' << doc_relate_parameters(d, by, *sc, at) << ','
       << by << ',' << frame << ','
       << (!k.solves || doc_number(d, by, "strength", at, 1) > 0 ? "true"
                                                                 : "false")
       << ')';
    return js.str();
  };
  // Builds the input as `tell` does. On the first frame it also records which
  // layers are read.
  const auto told = [&](double at, size_t frame) {
    std::set<int>* const outer = d.solver.reading;
    if (!frame) k.reads.clear(), d.solver.reading = &k.reads;
    const std::string js = tell(at, frame);
    d.solver.reading = outer;
    return js;
  };
  if (k.solves &&
      !doc_kept_walk(
          d, k, t, [&](size_t f) { return told((double)f / 60.0, f); },
          [&](const std::string& js, size_t) { return sc->run->numbers(js); }))
    return k.values;
  const std::vector<double> said =
      k.solves ? k.frames[std::min((size_t)std::max(0.0, std::round(t * 60.0)),
                                   k.frames.size() - 1)]
               : sc->run->numbers(told(t, 0));
  if (said.size() !=
      many * (rel.members.size() -
              (size_t)std::count(rel.members.begin(), rel.members.end(), 0)))
    return k.values;
  k.values.assign(many * rel.members.size(), 0.0);
  for (size_t i = 0, in = 0; i < rel.members.size(); ++i)
    if (rel.members[i]) {
      if (many * (in + 1) <= said.size())
        std::copy_n(said.begin() + (long)(many * in), many,
                    k.values.begin() + (long)(many * i));
      ++in;
    }
  return k.values;
}

bool doc_pushes(Doc& d, int by) {
  DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
  if (!sc || !sc->run || !sc->run->ok()) return false;
  if (sc->pushes < 0) {
    const std::vector<double> has =
        sc->run->numbers("Float64Array.of(typeof force == 'function' ? 1 : 0)");
    sc->pushes = !has.empty() && has[0] > 0;
  }
  return sc->pushes > 0;
}

namespace {
// All relations that push share one world, as Houdini's POP microsolvers share
// one stream of particles. Each layer is one particle with a position and a
// speed, whichever relations act on it. Every relation receives the frame as it
// stands and adds to the speed. This is the contract of d3-force: "read the
// node's current position and then add to the node's velocity", so d3's own
// forces run unchanged. What each relation adds is weighted by its Strength and
// Falloff (Cavalry's Falloff is a multiplier on Strength). The weighted
// additions are summed, as the POP Solver's microsolvers "accumulate forces",
// and the world then moves each layer by its speed once, as d3-force's tick
// does. A rule can therefore change without a jerk, because the speed carries
// on whichever relation provides it. A layer that nothing pushes shows what is
// under all the relations, and continues from there with the speed it has, as a
// Houdini Bullet object follows its animation until it is made active. While
// some relations push it, it blends by the total weight, as Strength always
// weights. A layer fading out of its only force goes home. The only source for
// that is this file's own earlier behavior; Houdini's would coast. A plain
// relation between two layers that push is passed over, and the world stands on
// what is under the lowest one.
//
// Layout of the values for each layer. "Told" is the input sent to the scripts:
// the values in doc_relate_names, then the speed. "Kept" is what is cached per
// frame: the 8 values the layer shows, its position, its speed, and the
// position where it would be left alone.
constexpr size_t doc_world_told = 11, doc_world_at = 8, doc_world_speed = 11,
                 doc_world_home = 14, doc_world_kept = 17;
// Rebuilds d.solver.world: the layers that pushing relations act on and the
// relations themselves.
void doc_world_made(Doc& d) {
  DocSolver::World w;
  std::vector<int> files;
  doc_rows(d,
           sqlite3_mprintf("select layer from keyframe where name = 'file' and "
                           "value = 'relate' order by layer"),
           [&](sqlite3_stmt* q) { files.push_back(sqlite3_column_int(q, 0)); });
  for (const int by : files) {
    if (!doc_pushes(d, by)) continue;
    w.forces.push_back(by);
    const DocRelation& rel = doc_relation_of(d, by);
    for (size_t i = 0; i < rel.members.size(); ++i)
      if (const int t = rel.members[i];
          t && w.slot.emplace(t, w.layers.size()).second)
        w.layers.push_back(t),
            w.below.push_back(rel.under.empty() ? 0 : rel.under[i]);
  }
  d.solver.world = std::move(w);
}
// Returns the cached values of the shared world at time `t`, doc_world_kept
// doubles per layer, solving any frames not yet cached. Returns nullptr if
// nothing can be shown yet.
const std::vector<double>* doc_world(Doc& d, double t) {
  DocSolver::RelatedKept& k = d.solver.relatedKept[0];
  DocKeptTells tells{d, k};
  const auto known = [&]() -> const std::vector<double>* {
    return k.frames.empty()
               ? nullptr
               : &k.frames[std::min((size_t)std::max(0.0, std::round(t * 60.0)),
                                    k.frames.size() - 1)];
  };
  if (d.solver.walking || doc_kept_stands(d, k, t)) return known();
  if (k.solves < 0) {
    const std::vector<int> was = d.solver.world.layers;
    doc_world_made(d), k.solves = 1;
    // Cached frames were laid out for different layers, so they are no longer
    // valid.
    if (d.solver.world.layers != was)
      k.frames.clear(), k.told.clear(), k.sure = k.fresh = 0;
  }
  struct Walking {
    Doc& d;
    explicit Walking(Doc& d) : d(d) { d.solver.walking = true; }
    ~Walking() { d.solver.walking = false; }
  } walking(d);
  const DocSolver::World& w = d.solver.world;
  const size_t many = std::size(doc_relate_names), n = w.layers.size();
  // One script call. `on` lists, for each layer the call covers, its slot in
  // the world and the weight of the call for it.
  struct Call {
    DocScript* sc;
    std::string js;
    std::vector<std::pair<size_t, double>> on;
  };
  std::vector<Call> calls;
  std::vector<double> now, home;
  const auto tell = [&](size_t f) {
    const double at = (double)f / 60.0;
    std::set<int>* const outer = d.solver.reading;
    if (!f) k.reads.clear(), d.solver.reading = &k.reads;
    const double* const was = f ? k.frames[f - 1].data() : nullptr;
    now.assign(n * doc_world_told, 0.0), home.assign(n * (many + 2), 0.0);
    for (size_t s = 0; s < n; ++s) {
      double size = 1;
      for (size_t j = 0; j < many; ++j) {
        const char* name = doc_relate_names[j];
        const double own = doc_number(
            d, w.layers[s], name, at,
            !strcmp(name, "size") || !strcmp(name, "opacity") ? 1 : 0);
        const double is = home[s * (many + 2) + j] =
            w.below[s] ? doc_related(d, w.below[s], w.layers[s], name, at, own)
                       : own;
        now[s * doc_world_told + j] = is;
        if (!strcmp(name, "size")) size = is;
      }
      float2 half{0.f};
      doc_half(d, w.layers[s], &half);
      home[s * (many + 2) + many] = 2.0 * half.x * size,
                            home[s * (many + 2) + many + 1] =
                                2.0 * half.y * size;
      if (was)
        for (size_t j = 0; j < 3; ++j)
          now[s * doc_world_told +
              j] = was[s * doc_world_kept + doc_world_at + j],
              now[s * doc_world_told + many + j] =
                  was[s * doc_world_kept + doc_world_speed + j];
    }
    calls.clear();
    std::string all;
    for (const int by : w.forces) {
      DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
      if (!sc || !sc->run) continue;
      const DocRelation& rel = doc_relation_of(d, by);
      // The weight is 0 at the first frame, where every layer starts at its
      // home position.
      const double strength = doc_number(d, by, "strength", at, 1),
                   weight = f && doc_number(d, by, "visible", 0, 1) > 0.5
                                ? std::clamp(strength, 0.0, 2.0)
                                : 0.0;
      std::ostringstream js;
      js.precision(12);
      // An asleep relation forgets the state it wrote, so it starts anew when
      // it wakes. At the first frame it is still called, to find out which
      // layers it reads.
      if (f && weight <= 0.0) {
        js << "__asleep(" << by << ',' << f << ')';
        all += js.str(), calls.push_back(Call{sc, js.str(), {}});
        continue;
      }
      js << "__forces([";
      Call call{sc, "", {}};
      for (const int layer : rel.members) {
        if (!layer) continue;
        const size_t s = w.slot.at(layer);
        const double *const is = &now[s * doc_world_told],
                            *const stands = &home[s * (many + 2)];
        const double near = doc_falloff_at(d, by, {is[0], is[1], is[2]}, at);
        js << '[';
        for (size_t j = 0; j < doc_world_told; ++j) js << is[j] << ',';
        js << stands[many] << ',' << stands[many + 1] << ',' << layer << ','
           << near << ',' << stands[0] << ',' << stands[1] << ',' << stands[2]
           << "],";
        call.on.emplace_back(s, weight * near);
      }
      js << "]," << at << ',' << doc_relate_parameters(d, by, *sc, at) << ','
         << by << ',' << f << ',' << (weight > 0.0 ? "true" : "false") << ')';
      call.js = js.str();
      all += call.js;
      calls.push_back(std::move(call));
    }
    d.solver.reading = outer;
    return all;
  };
  const auto make = [&](const std::string&, size_t f) {
    std::vector<double> sum = now, pushed(n, 0.0), next(n * doc_world_kept);
    for (const Call& call : calls) {
      const std::vector<double> said = call.sc->run->numbers(call.js);
      // The call failed and its error is reported; the results of the other
      // calls stand.
      if (said.size() != call.on.size() * doc_world_told) continue;
      for (size_t in = 0; in < call.on.size(); ++in) {
        const auto [s, weight] = call.on[in];
        pushed[s] += weight;
        for (size_t j = 0; j < doc_world_told; ++j)
          sum[s * doc_world_told + j] +=
              weight *
              (said[in * doc_world_told + j] - now[s * doc_world_told + j]);
      }
    }
    for (size_t s = 0; s < n; ++s) {
      const double share = std::min(1.0, pushed[s]),
                   *const stands = &home[s * (many + 2)],
                   *const sums = &sum[s * doc_world_told];
      double* const out = &next[s * doc_world_kept];
      std::copy_n(sums + 3, many - 3, out + 3);
      for (size_t j = 0; j < 3; ++j) {
        const double speed =
            share > 0.0 ? sums[many + j]
            : f ? stands[j] -
                      k.frames[f - 1][s * doc_world_kept + doc_world_home + j]
                : 0.0;
        out[doc_world_at + j] = share > 0.0 ? sums[j] + speed : stands[j],
                           out[doc_world_speed + j] = speed,
                           out[doc_world_home + j] = stands[j];
        out[j] = stands[j] + (out[doc_world_at + j] - stands[j]) * share;
      }
    }
    return next;
  };
  doc_kept_walk(d, k, t, tell, make);
  return known();
}
}  // namespace

double doc_world_value(Doc& d, int layer, size_t name, double t,
                       double otherwise) {
  const std::vector<double>* const all = doc_world(d, t);
  const auto at = d.solver.world.slot.find(layer);
  return !all || at == d.solver.world.slot.end() ||
                 (at->second + 1) * doc_world_kept > all->size()
             ? otherwise
             : (*all)[at->second * doc_world_kept + name];
}

}  // namespace motolii

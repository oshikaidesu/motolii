#include "document/evaluate/relations.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <math/mat4.h>
#include <math/quat.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <initializer_list>
#include <iterator>
#include <memory>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/script_runner/script_runner.h"
#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/place.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/evaluate/world.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace math = filament::math;
using filament::MaterialInstance;
using filament::math::float2;

double doc_behaviour_at(Doc& d, int by, int copy, int n, double t) {
  // Limits how deeply behaviours can drive each other, so that a cycle of them
  // terminates.
  static int depth = 0;
  struct Deeper {
    Deeper() { ++depth; }
    ~Deeper() { --depth; }
  } deeper;
  // Returns the parameter `name` of this behaviour for this copy. When another
  // behaviour drives the parameter, that behaviour's value for this copy is
  // used. Otherwise it is the stored number, or `otherwise` when there is none.
  const auto parameter = [&](const char* name, double otherwise) {
    if (depth < 4)
      if (const int other = doc_driven_by(d, by, name); other && other != by)
        return doc_behaviour_at(d, other, copy, n, t);
    return doc_number(d, by, name, t, otherwise);
  };
  const std::string type = doc_word(d, by, "file");
  const double lo = parameter("minimum", 0), hi = parameter("maximum", 1),
               offset = parameter("offset", 0);
  const double frequency = parameter("frequency", 1),
               apart = parameter("stagger", 0) / 360.0;
  const uint32_t seed = (uint32_t)doc_number(d, by, "seed", 0, 0);
  // Returns a deterministic number from 0 to 1 for the seed and the integer
  // `k`.
  const auto hash = [&](int64_t k) {
    uint32_t h = seed * 0x9E3779B9u ^ (uint32_t)k * 0x85EBCA6Bu ^ 0xC2B2AE35u;
    h ^= h >> 16, h *= 0x7FEB352Du, h ^= h >> 15, h *= 0x846CA68Bu,
        h ^= h >> 16;
    return (double)h / 4294967295.0;
  };
  double u = 0.0;
  // Stagger: the copy's position in the order, from 0 for the first copy to 1
  // for the last, shifted by the offset.
  if (type == "stagger")
    u = std::clamp((n > 1 ? (double)copy / (n - 1) : 0.0) + offset, 0.0, 1.0);
  // Oscillator: a sine wave over time, mapped to the range 0 to 1. `apart` is
  // the phase shift per copy in turns.
  else if (type == "oscillator")
    u = 0.5 +
        0.5 * std::sin((double)TAU * (frequency * t + offset + apart * copy));
  // Noise: smooth interpolation between hashed values at whole positions along
  // time. Each copy starts further along.
  else if (type == "noise") {
    const double x = frequency * t + offset + apart * copy * 4.0,
                 f = std::floor(x),
                 e = (x - f) * (x - f) * (3.0 - 2.0 * (x - f));
    u = hash((int64_t)f) * (1.0 - e) + hash((int64_t)f + 1) * e;
  }
  // Random: a fixed value for each copy, determined by the seed.
  else if (type == "random")
    u = hash(copy + 1);
  // Round to a multiple of `step` when it is positive.
  const double step = parameter("step", 0), v = lo + (hi - lo) * u;
  return step > 0.0 ? std::round(v / step) * step : v;
}

bool doc_connects(Doc& d, int layer) {
  if (const auto known = d.relations.connects.find(layer);
      known != d.relations.connects.end())
    return known->second;
  bool any = false;
  doc_rows(d,
           sqlite3_mprintf("select 1 from keyframe where layer = %d and name "
                           "glob '*_by' and value <> 0 limit 1",
                           layer),
           [&](sqlite3_stmt*) { any = true; });
  return d.relations.connects.emplace(layer, any).first->second;
}

int doc_driven_by(Doc& d, int layer, const char* name) {
  if (!doc_connects(d, layer)) return 0;
  const auto key = std::make_pair(layer, std::string(name));
  if (const auto known = d.relations.drivers.find(key);
      known != d.relations.drivers.end())
    return known->second;
  int by = (int)doc_number(d, layer, (std::string(name) + "_by").c_str(), 0, 0);
  if (by && doc_word(d, by, "kind") != "behaviour") by = 0;
  return d.relations.drivers.emplace(key, by).first->second;
}

double doc_falloff_at(Doc& d, int by, math::double3 at, double t) {
  const int f = (int)doc_number(d, by, "region", 0, 0);
  if (!f) return 1.0;
  const auto found = d.on_stage.shown.find(f);
  const Canvas2D* b =
      found == d.on_stage.shown.end() ? nullptr : found->second.drawn;
  if (!b || !b->cut || !b->outline) return 1.0;
  const math::mat4 place = doc_place(d, f, t, 0, 0, false);
  // The point in the falloff layer's own space.
  const math::double4 on = inverse(place) * math::double4{at, 1.0};
  const tvg::PathCommand* cmds;
  const tvg::Point* pts;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
  b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
  float far = 0.f;
  // Convert to the units of the outline, which is plainHigh high with its
  // origin at the top left.
  const bool inside = sk_inside(
      cmds, cmdsCnt, pts,
      (float)(on.x / b->sheetHigh * b->plainHigh + 0.5 * b->cutW),
      (float)(0.5 * b->plainHigh - on.y / b->sheetHigh * b->plainHigh), &far);
  // The softness is measured on the stage, so it does not grow with the shape.
  // `away` is the distance to the outline in stage units.
  const double soft = doc_number(d, by, "falloff_soft", t, 0),
               away = far / b->plainHigh * b->sheetHigh *
                      std::sqrt(length(place[0].xyz) * length(place[1].xyz));
  const double w = inside       ? 1.0
                   : soft > 0.0 ? std::max(0.0, 1.0 - away / soft)
                                : 0.0;
  return doc_number(d, by, "falloff_invert", 0, 0) > 0.5 ? 1.0 - w : w;
}

double doc_given(Doc& d, int by, int copy, int n, double t, double own,
                 const math::double3* at) {
  const double v = doc_behaviour_at(d, by, copy, n, t);
  if (!at) return v;
  const double w = doc_falloff_at(d, by, *at, t);
  return own + (v - own) * w;
}

void doc_copy_looks_off(Doc& d, const Mesh* m, MaterialInstance* main) {
  Stage& s = *d.stage;
  auto& faces = s.engine->getRenderableManager();
  for (const Stage::Renderable& made : s.renderables) {
    if (made.of != m) continue;
    const auto found = d.copy_materials.looks.find(made.thing.getId());
    if (found == d.copy_materials.looks.end()) continue;
    if (main)
      faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, main);
    s.engine->destroy(found->second);
    d.copy_materials.looks.erase(found);
    // The copy's own edge material goes back to the layer's edge material in
    // the same way.
    if (const auto edge = d.copy_materials.edges.find(made.thing.getId());
        edge != d.copy_materials.edges.end()) {
      const DocShownLayer* t = nullptr;
      for (const auto& [id, one] : d.on_stage.shown)
        if (one.drawn && one.drawn->sheet == m) t = &one;
      if (t && t->drawn->edgeLook)
        faces.setMaterialInstanceAt(faces.getInstance(made.thing), 1,
                                    t->drawn->edgeLook);
      s.engine->destroy(edge->second);
      d.copy_materials.edges.erase(edge);
    }
  }
}

const DocRelation& doc_relation_of(Doc& d, int by) {
  if (const auto known = d.relations.relationsOf.find(by);
      known != d.relations.relationsOf.end())
    return known->second;
  // Limits how deeply relations can build on relations, so that a cycle of them
  // terminates.
  static int depth = 0;
  struct Deeper {
    Deeper() { ++depth; }
    ~Deeper() { --depth; }
  } deeper;
  DocRelation r;
  std::vector<int> connected;
  doc_rows(
      d,
      sqlite3_mprintf("select distinct layer from keyframe where name glob "
                      "'*_by' and value = %d order by layer",
                      by),
      [&](sqlite3_stmt* q) { connected.push_back(sqlite3_column_int(q, 0)); });
  // Splits the text value `name` of the relation into words.
  const auto words = [&](const char* name) {
    std::vector<std::string> all;
    std::istringstream said(doc_word(d, by, name));
    for (std::string one; said >> one;) all.push_back(one);
    return all;
  };
  const std::vector<std::string> members = words("members"),
                                 under = words("under"), from = words("from");
  // Returns whether layer `t` is a member of this relation indirectly. Walks
  // back through the relations that the layer was in before, at most 8 steps,
  // looking for this one.
  const auto reaches = [&](int t) {
    for (int cur = doc_driven_by(d, t, "x") ? doc_driven_by(d, t, "x")
                                            : doc_driven_by(d, t, "y"),
             n = 0;
         cur && n < 8 && depth < 6; ++n) {
      if (cur == by) return true;
      const DocRelation& above = doc_relation_of(d, cur);
      const auto at = std::find(above.members.begin(), above.members.end(), t);
      cur = at == above.members.end() || above.under.empty()
                ? 0
                : above.under[(size_t)(at - above.members.begin())];
    }
    return false;
  };
  // Keep a listed member only when it is still connected or reachable.
  // Otherwise leave a 0 slot.
  for (size_t k = 0; k < members.size(); ++k) {
    const int t = std::atoi(members[k].c_str());
    const bool in =
        t &&
        std::find(r.members.begin(), r.members.end(), t) == r.members.end() &&
        (std::find(connected.begin(), connected.end(), t) != connected.end() ||
         reaches(t));
    r.members.push_back(in ? t : 0);
  }
  // Append the connected layers that are not listed.
  for (const int t : connected)
    if (std::find(r.members.begin(), r.members.end(), t) == r.members.end())
      r.members.push_back(t);
  if (under.size() == members.size())
    for (const std::string& u : under) r.under.push_back(std::atoi(u.c_str()));
  if (from.size() == 2 * members.size())
    for (const std::string& f : from) r.from.push_back(std::atof(f.c_str()));
  // Keep `under` and `from` either empty or one entry per member, padding with
  // 0 and NaN.
  r.under.resize(r.under.empty() ? 0 : r.members.size(), 0);
  r.from.resize(r.from.empty() ? 0 : 2 * r.members.size(), std::nan(""));
  return d.relations.relationsOf.emplace(by, std::move(r)).first->second;
}

double doc_related(Doc& d, int by, int layer, const char* name, double t,
                   double own) {
  // Limits recursion when a leader is itself in a relation that leads back to
  // this one.
  static int depth = 0;
  struct Deeper {
    Deeper() { ++depth; }
    ~Deeper() { --depth; }
  } deeper;
  if (depth > 6) return own;
  const DocRelation& rel = doc_relation_of(d, by);
  const auto found = std::find(rel.members.begin(), rel.members.end(), layer);
  if (found == rel.members.end()) return own;
  const size_t i = (size_t)(found - rel.members.begin());
  const int was = rel.under.empty() ? 0 : rel.under[i];
  // The value before this relation: what the previous relation gives, or `own`.
  const double base = was ? doc_related(d, was, layer, name, t, own) : own;
  // Each member's strength is read later than the one before by the script's
  // `lag` seconds, as in Cavalry's stagger, so that a strength that rises over
  // time reaches the members one after another. A script without a `lag`
  // parameter has no delay.
  double lag = 0;
  if (const DocScript* sc = doc_script_of(d, doc_word(d, by, "script")))
    for (size_t j = 0; j < sc->parameters.size(); ++j)
      if (sc->parameters[j].kind == "track" && sc->parameters[j].name == "lag")
        lag =
            doc_number(d, by, sc->names[j].c_str(), t, sc->parameters[j].usual);
  // The strength may go below 0 and above 1 so that an easing that overshoots,
  // such as Back or Elastic, shows between two keyframes. It is held within -1
  // and 2.
  const double strength = std::clamp(
      doc_number(d, by, "strength", t - lag * (double)i, 1), -1.0, 2.0);
  // A relation that is switched off leaves the value as it was. Its strength is
  // kept.
  if (doc_number(d, by, "visible", 0, 1) <= 0.5) return base;
  // The relation is a script file. When the file defines force(), the value
  // comes from the simulated world. Otherwise it comes from the file's relate()
  // results, one number per member and per name in doc_relate_names, blended by
  // the strength. Its falloff is applied inside the file, see __relates in
  // engine/community/p5/p5_stand.h. While layers settle (d.relations.settled)
  // it gives nothing, because what it gives may change with time.
  if (d.relations.settled) return base;
  const bool pushes = doc_pushes(d, by);
  const std::vector<double> none,
      &all = pushes ? none : doc_related_all(d, by, t);
  constexpr size_t many = std::size(doc_relate_names);
  for (size_t j = 0; j < many; ++j)
    if (!strcmp(name, doc_relate_names[j]))
      return pushes ? doc_world_value(d, layer, j, t, base)
             : many * i + j < all.size()
                 ? base + (all[many * i + j] - base) * strength
                 : base;
  return base;
}

double doc_literal(Doc& d, int layer, const char* literal, double at,
                   double otherwise) {
  // The layer is being dragged. Use its own value. If it is in a relation, the
  // relation still applies, because the drag moves the layer's own value.
  if (d.held.layer == layer) {
    const double own = doc_number(d, layer, literal, at, otherwise);
    const int by = doc_driven_by(d, layer, literal);
    return by && doc_among(doc_relations, doc_word(d, by, "file"))
               ? doc_related(d, by, layer, literal, at, own)
               : own;
  }
  // Driven by a behaviour or relation. For a behaviour, use the value for the
  // copy being placed, weighed by its falloff where the copy lies.
  if (const int by = doc_driven_by(d, layer, literal)) {
    const DocKeys& k = doc_keys_of(d, layer, literal);
    const double own =
        doc_keys_at(d, k, doc_stepped(d, layer, k, at), otherwise);
    // A relation applies by the layer's place among its layers, not by a copy's
    // place.
    if (doc_among(doc_relations, doc_word(d, by, "file")))
      return doc_related(d, by, layer, literal, at, own);
    return doc_given(d, by, d.copy_context.copy, d.copy_context.n, at, own,
                     d.copy_context.has_at ? &d.copy_context.at : nullptr);
  }
  const auto key = std::make_pair(layer, literal);
  auto kept = d.value_cache.literals.find(key);
  if (kept == d.value_cache.literals.end())
    kept = d.value_cache.literals.emplace(key, &doc_keys_of(d, layer, literal))
               .first;
  return doc_keys_at(d, *kept->second, doc_stepped(d, layer, *kept->second, at),
                     otherwise);
}

const std::string& doc_literal_word(Doc& d, int layer, const char* literal) {
  const auto key = std::make_pair(layer, literal);
  if (const auto kept = d.value_cache.heardWords.find(key);
      kept != d.value_cache.heardWords.end())
    return kept->second;
  return d.value_cache.heardWords.emplace(key, doc_word(d, layer, literal))
      .first->second;
}

const std::vector<AbsentCopy>& doc_absent_copies(Doc& d, int layer,
                                                 double now) {
  DocRelations::AbsentKept& k = d.relations.absentKept[layer];
  const long changes = d.file ? (long)sqlite3_total_changes(d.file) : 0;
  if (k.at == now && k.changes == changes && k.seen == files_changed())
    return k.copies;
  k.at = now, k.changes = changes, k.seen = files_changed();
  k.copies.clear();
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos)
    return k.copies;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  // `k2` converts points of the preview to pixels of the document.
  const double high = doc_number(d, 0, "high", 0, 1080),
               k2 = high / std::max(1, d.stage->h);
  const math::double2 at =
      doc_seen(d, (doc_above(d, layer, now, 0) *
                   math::double4{doc_literal(d, layer, "x", now, 0),
                                 doc_literal(d, layer, "y", now, 0),
                                 doc_literal(d, layer, "z", now, 0), 1.0})
                      .xyz) *
      k2;
  float2 half{0.5f};
  doc_half(d, layer, &half);
  // Distance from the layer's position to the farthest point of its box,
  // computed as in CopiesOf: half of the longer side times 1.415, about the
  // square root of 2.
  const double reach = std::max(half.x, half.y) *
                       doc_literal(d, layer, "size", now, 1) *
                       doc_point(d, layer, now) * k2 * 1.415;
  // AbsentMotion measures time in milliseconds.
  k.copies =
      absent_copies(doc_absent_on(d, layer, now), layer, 1000.0 * begins,
                    1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))),
                    1000.0 * now, (float)(d.stage->w * k2), (float)high,
                    (float)at.x, (float)at.y, (float)reach);
  return k.copies;
}

std::string doc_text_shown(Doc& d, int layer, double now, bool* moves) {
  const std::string typed = doc_word(d, layer, "text");
  if (moves) *moves = false;
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return typed;
  const std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
  if (!absent_text_on(on)) return typed;
  if (moves) *moves = true;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_text(on, layer, 1000.0 * begins,
                     1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))),
                     1000.0 * now, 60, typed);
}

bool doc_shutter(Doc& d, int layer, double now, double* open, bool* moves) {
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return false;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_shutter(
      doc_absent_on(d, layer, now), layer, 1000.0 * begins,
      1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now,
      60, open, moves);
}

double doc_group_opacity(Doc& d, int layer, double now) {
  double k = 1.0;
  // Stop after 64 levels so that a cycle of parents terminates.
  for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0;
       up && n < 64 && k > 0.0;
       up = (int)doc_number(d, up, "parent", 0, 0), ++n)
    if (doc_word(d, up, "shape") == "null")
      k *= doc_number(d, up, "visible", 0, 1) > 0.5
               ? std::clamp(doc_number(d, up, "opacity", now, 1), 0.0, 1.0)
               : 0.0;
  return k;
}

double doc_absent_opacity(Doc& d, int layer, double now) {
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return 1.0;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_opacity(
      doc_absent_on(d, layer, now), layer, 1000.0 * begins,
      1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now);
}

int doc_members(Doc& d, int layer) {
  const auto t = d.on_stage.shown.find(layer);
  if (t != d.on_stage.shown.end() && t->second.drawn &&
      !t->second.drawn->letters.empty())
    return (int)t->second.drawn->letters.size();
  if (const std::vector<AbsentCopy>& copies =
          doc_absent_copies(d, layer, d.stage->now);
      !copies.empty())
    return (int)copies.size();
  return std::max(1, (int)doc_literal(d, layer, "copies", 0, 1));
}

double doc_delay(Doc& d, int layer, int nth) {
  const double stagger = doc_literal(d, layer, "stagger", 0, 0);
  const int n = doc_members(d, layer);
  if (stagger <= 0.0 || n < 2) return 0.0;
  const double along = (double)nth / (double)(n - 1),
               centre = std::fabs(along - 0.5) * 2.0;
  const std::string& from = doc_literal_word(d, layer, "stagger_from");
  return stagger * (from == "centre"  ? centre
                    : from == "end"   ? 1.0 - along
                    : from == "edges" ? 1.0 - centre
                                      : along);
}

math::mat4 doc_above(Doc& d, int layer, double now, int deeper) {
  const int parent = (int)doc_literal(d, layer, "parent", 0, 0);
  const auto up = d.on_stage.shown.find(parent),
             self = d.on_stage.shown.find(layer);
  if (up != d.on_stage.shown.end() && up->second.camera &&
      self != d.on_stage.shown.end() && self->second.space == 2)
    return math::mat4{};
  // Stop after 64 levels so that a document with a cycle of parents terminates.
  return parent && up != d.on_stage.shown.end() && deeper < 64
             ? doc_place(d, parent, now, deeper + 1)
             : math::mat4{};
}

double doc_letter_middle(Doc& d, int layer, int copy) {
  const auto sh = d.on_stage.shown.find(layer);
  if (copy < 0 || sh == d.on_stage.shown.end() || !sh->second.drawn ||
      copy >= (int)sh->second.drawn->letters.size())
    return 0.0;
  float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  const float2 l = sh->second.drawn->letters[(size_t)copy];
  return ((double)(l.x + l.y) * 0.5 - 0.5) * 2.0 * half.x;
}

bool doc_staggered(Doc& d, int layer, double now) {
  // One box in a sketch is placed by the sketch in the same way.
  if (const DocScript* sc =
          doc_script_of(d, doc_literal_word(d, layer, "script"));
      sc && sc->run && sc->run->sketch())
    return true;
  // A layer with no copies but with expressions is its own single copy, index 0
  // of 1.
  if (!doc_expressions_fx(d, layer).empty()) return true;
  return doc_members(d, layer) > 1 ||
         doc_number(d, layer, "stagger", 0, 0) > 0.0;
}

}  // namespace motolii

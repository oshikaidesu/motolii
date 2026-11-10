#include "document/evaluate/relations.h"

#include <filament/RenderableManager.h>

#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "stage/canvas/path_operations.h"

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

}  // namespace motolii

#include "document/evaluate/relations.h"

#include <filament/RenderableManager.h>
#include <quickjs.h>

#include <filesystem>
#include <map>
#include <mutex>
#include <string>
#include <tuple>
#include <vector>

#include "base/file_read.h"
#include "document/card_table.h"
#include "document/evaluate/shown.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

namespace math = filament::math;
using filament::MaterialInstance;
using filament::math::float2;

namespace {

// The 4 built-in behaviours (stagger / oscillator / noise / random) are
// shelves/behaviours/*.js. Each exports `all(n, t, k)` and returns a
// Float64Array of n values (one per copy) in [0, 1]. The engine calls that
// function once per behaviour layer per frame; `doc_behaviour_at(copy, ...)`
// reads out[copy] from the cached array. This stays one QuickJS call per
// frame no matter how many copies the layer has, so the per-copy work is
// plain C++. A TSL compute node will replace the JS call itself later.
// The JS runtime loads on first use and stays while the engine runs. All
// calls take a mutex because QuickJS is not thread-safe: every path that
// reaches a behaviour value (evaluate layer, sketch, scripts...) can touch
// it. seed is passed as a signed int32 whose bit pattern matches the engine's
// uint32 seed so Math.imul in the JS hashes the same 32 bits.
struct BehaviourRun {
  JSRuntime* rt = nullptr;
  JSContext* cx = nullptr;
  std::map<std::string, JSValue> fns;  // type name -> `all` function
  // Cached array per (behaviour layer, t, n, offset, frequency, apart, seed).
  // The tuple catches every parameter the JS sees, so a changed parameter
  // (e.g. the user dragged the frequency slider) misses and recomputes.
  using Key = std::tuple<int, double, int, double, double, double, uint32_t>;
  std::map<Key, std::vector<double>> cache;
  std::mutex lock;

  // Returns the `all` function for `type`, loading its JS file on first use.
  // JS_UNDEFINED when the file is not there or does not compile.
  JSValue fn_of(const std::string& type) {
    if (!rt) rt = JS_NewRuntime(), cx = JS_NewContext(rt);
    auto it = fns.find(type);
    if (it != fns.end()) return it->second;
    const std::filesystem::path p = std::filesystem::absolute(
        doc_engine("..") / "shelves" / "behaviours" / (type + ".js"));
    const std::string key = "__all_" + type;
    const std::string wrap = "import { all } from '" + p.generic_string() +
                             "';\nglobalThis['" + key + "'] = all;\n";
    JSValue ran = JS_Eval(cx, wrap.c_str(), wrap.size(),
                          (type + ".behaviour").c_str(), JS_EVAL_TYPE_MODULE);
    JSValue fn = JS_UNDEFINED;
    if (!JS_IsException(ran)) {
      for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
      }
      JSValue g = JS_GetGlobalObject(cx);
      fn = JS_GetPropertyStr(cx, g, key.c_str());
      JS_FreeValue(cx, g);
      if (!JS_IsFunction(cx, fn)) JS_FreeValue(cx, fn), fn = JS_UNDEFINED;
    } else {
      JSValue e = JS_GetException(cx);
      JS_FreeValue(cx, e);
    }
    JS_FreeValue(cx, ran);
    return fns[type] = fn;
  }

  // Returns the Float64Array for `type` at these parameters: the cached entry,
  // or a fresh one computed by a single JS_Call. The cache holds at most a few
  // entries per behaviour layer (current frame plus any older ones) and is
  // kept small by dropping anything with a different t when a new t arrives.
  const std::vector<double>& all_of(const std::string& type, int by, int n,
                                    double t, double offset, double frequency,
                                    double apart, uint32_t seed) {
    const Key k{by, t, n, offset, frequency, apart, seed};
    if (const auto it = cache.find(k); it != cache.end()) return it->second;
    // Drop older entries for this layer so the map does not grow across frames.
    std::erase_if(cache,
                  [by](const auto& kv) { return std::get<0>(kv.first) == by; });
    std::vector<double>& out = cache[k];
    const JSValue fn = fn_of(type);
    if (!JS_IsFunction(cx, fn) || n <= 0) return out;
    JSValue kObj = JS_NewObject(cx);
    JS_SetPropertyStr(cx, kObj, "offset", JS_NewFloat64(cx, offset));
    JS_SetPropertyStr(cx, kObj, "frequency", JS_NewFloat64(cx, frequency));
    JS_SetPropertyStr(cx, kObj, "apart", JS_NewFloat64(cx, apart));
    JS_SetPropertyStr(cx, kObj, "seed", JS_NewInt32(cx, (int32_t)seed));
    JSValue args[3] = {JS_NewInt32(cx, n), JS_NewFloat64(cx, t), kObj};
    JSValue result = JS_Call(cx, fn, JS_UNDEFINED, 3, args);
    for (int i = 0; i < 3; ++i) JS_FreeValue(cx, args[i]);
    // The JS returns a Float64Array. Pull the bytes out in one copy.
    if (!JS_IsException(result)) {
      size_t from = 0, bytes = 0, each = 0, size = 0;
      JSValue buffer = JS_GetTypedArrayBuffer(cx, result, &from, &bytes, &each);
      if (const uint8_t* p = JS_IsException(buffer)
                                 ? nullptr
                                 : JS_GetArrayBuffer(cx, &size, buffer)) {
        const double* ds = (const double*)(p + from);
        out.assign(ds, ds + bytes / sizeof(double));
      }
      JS_FreeValue(cx, buffer);
    }
    JS_FreeValue(cx, result);
    return out;
  }
};
BehaviourRun& behaviour_run() {
  static BehaviourRun r;
  return r;
}

}  // namespace

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
  // One JS call per behaviour layer per frame: the array for every copy is
  // computed in that call and cached. Out-of-range copy indices read 0.
  BehaviourRun& run = behaviour_run();
  std::lock_guard<std::mutex> hold(run.lock);
  const std::vector<double>& all =
      run.all_of(type, by, n, t, offset, frequency, apart, seed);
  const double u =
      copy >= 0 && copy < (int)all.size() ? all[(size_t)copy] : 0.0;
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
  // `lag` seconds stagger, so that a strength that rises over
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
  // engine/community/p5js/p5_stand.h. While layers settle (d.relations.settled)
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

// -- layer_reads: what a layer reads of itself and its group. --

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
  const double begins = doc_literal(d, layer, "start", 0, 0);
  // `k2` converts points of the preview to pixels of the document.
  const double high = doc_comp_high(d), k2 = high / std::max(1, d.stage->h);
  const math::double3 pos = doc_position(d, layer, now);
  const math::double2 at = doc_seen(d, (doc_above(d, layer, now, 0) *
                                        math::double4{pos.x, pos.y, pos.z, 1.0})
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
  k.copies = absent_copies(doc_absent_on(d, layer, now), layer, 1000.0 * begins,
                           1000.0 * doc_layer_ends(d, layer), 1000.0 * now,
                           (float)(d.stage->w * k2), (float)high, (float)at.x,
                           (float)at.y, (float)reach);
  return k.copies;
}

std::string doc_text_shown(Doc& d, int layer, double now, bool* moves) {
  const std::string typed = doc_word(d, layer, "text");
  if (moves) *moves = false;
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return typed;
  const std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
  if (!absent_text_on(on)) return typed;
  if (moves) *moves = true;
  const double begins = doc_literal(d, layer, "start", 0, 0);
  return absent_text(on, layer, 1000.0 * begins,
                     1000.0 * doc_layer_ends(d, layer), 1000.0 * now, 60,
                     typed);
}

bool doc_shutter(Doc& d, int layer, double now, double* open, bool* moves) {
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return false;
  const double begins = doc_literal(d, layer, "start", 0, 0);
  return absent_shutter(doc_absent_on(d, layer, now), layer, 1000.0 * begins,
                        1000.0 * doc_layer_ends(d, layer), 1000.0 * now, 60,
                        open, moves);
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
  const double begins = doc_literal(d, layer, "start", 0, 0);
  return absent_opacity(doc_absent_on(d, layer, now), layer, 1000.0 * begins,
                        1000.0 * doc_layer_ends(d, layer), 1000.0 * now);
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
  // A line's middle across is the middle of its own box.
  if (sh->second.drawn->lettersDown) {
    if ((size_t)copy >= sh->second.drawn->boxes.size()) return 0.0;
    const float2 b = sh->second.drawn->boxes[(size_t)copy];
    return ((double)b.x + (double)b.y * 0.5 - 0.5) * 2.0 * half.x;
  }
  const float2 l = sh->second.drawn->letters[(size_t)copy];
  return ((double)(l.x + l.y) * 0.5 - 0.5) * 2.0 * half.x;
}

double doc_line_middle(Doc& d, int layer, int copy) {
  const auto sh = d.on_stage.shown.find(layer);
  if (copy < 0 || sh == d.on_stage.shown.end() || !sh->second.drawn ||
      !sh->second.drawn->lettersDown ||
      copy >= (int)sh->second.drawn->letters.size())
    return 0.0;
  float2 half{0.5f};
  doc_half(d, layer, &half);
  // A cut lies halfway between two lines, so a line's own middle is half a
  // line's pitch from the cut above it (below it, for the first line, whose
  // part of the image begins at the image's top). The cuts run down the image
  // from its top; the stage's y runs up.
  const Canvas2D& drawn = *sh->second.drawn;
  const double pitch = drawn.linePitch,
               down = drawn.letters.size() < 2 ? 0.5
                      : copy == 0
                          ? (double)drawn.letters[0].y - 0.5 * pitch
                          : (double)drawn.letters[(size_t)copy].x + 0.5 * pitch;
  return (0.5 - down) * 2.0 * half.y;
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

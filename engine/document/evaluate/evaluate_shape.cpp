#include "document/evaluate/evaluate_shape.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/scripts.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

namespace {

// The bends of one layer's shape while they are worked out: the layer, and what
// working out the bends of the layer and of its copies has found so far.
struct Bending {
  Doc& d;
  const int layer;
  // The layer as it is on the stage.
  DocShownLayer& t;
  const double now;
  // The time in seconds since the layer started.
  const double since;
  // True when a behaviour gives each copy its own bend, so each copy needs
  // its own material.
  bool driven = false;
  // Falloff region of a behaviour that drives a bend, weighed point by
  // point in the material: a circle where the region's shape lies, as large
  // as the shape. Its fourth component is the softness, negative when
  // inverted.
  float4 region{0.f};
};

// Fills `bends`, eight float4 values, for one copy. Slots 0 to 3 hold
// warp, bend and twist, skew and squash, and wiggle. Slot 4 holds
// stretch, slots 5 and 6 the corner pins, and slot 7 the falloff region.
// A property driven by a behaviour takes that behaviour's value for this
// copy.
void bends_of(Bending& bending, int copy, int n, float4* bends,
              const math::double3* where = nullptr) {
  Doc& d = bending.d;
  const int layer = bending.layer;
  DocShownLayer& t = bending.t;
  const double now = bending.now;
  bool& driven = bending.driven;
  float4& region = bending.region;
  const auto num = [&](const char* name, double otherwise) {
    return (float)doc_number(d, layer, name, now, otherwise);
  };
  const float deg = (float)(TAU / 360.0), since = (float)bending.since;
  const auto at = [&](const char* name, double otherwise) {
    if (const int by = doc_driven_by(d, layer, name)) {
      driven = true;
      // A behaviour with a region weighs points of the shape, not whole
      // copies.
      if (const int f = (int)doc_number(d, by, "region", 0, 0);
          f && d.on_stage.shown.count(f) && d.on_stage.shown[f].drawn) {
        const math::mat4 there = doc_place(d, f, now, 0, 0, false);
        const math::double4 middle = there * math::double4{0, 0, 0, 1};
        const double r = length((there *
                                 math::double4{
                                     0.5 * d.on_stage.shown[f].drawn->sheetHigh,
                                     0, 0, 0})
                                    .xyz),
                     soft = doc_number(d, by, "falloff_soft", now, 0);
        region = float4{(float)middle.x, (float)middle.y, (float)r,
                        (float)(doc_number(d, by, "falloff_invert", 0, 0) > 0.5
                                    ? -std::max(soft, 1e-4)
                                    : soft)};
        return (float)doc_behaviour_at(d, by, copy, n, now);
      }
      return (float)doc_given(d, by, copy, n, now, num(name, otherwise), where);
    }
    return num(name, otherwise);
  };
  const float4 all[7] = {
      {at("warp", 0), at("warp_width", 0.5), at("warp_speed", 1) * since,
       at("warp_angle", 0) * deg},
      {at("bend", 0) * deg,
       doc_word(d, layer, "bend_direction") == "vertical" ? 1.f : 0.f,
       at("twist", 0) * deg, at("pinch", 0)},
      {at("skew", 0) * deg, at("skew_axis", 0) * deg, at("squash", 0),
       0.5f * t.drawn->wideBy},
      {at("wiggle", 0), at("wiggle_detail", 3), at("wiggle_speed", 1) * since,
       num("seed", 0) * 7.31f},
      {0.f, 0.f, num("stretch", 0), 0.f},
      {at("pin_tl_x", 0), at("pin_tl_y", 0), at("pin_tr_x", 0),
       at("pin_tr_y", 0)},
      {at("pin_bl_x", 0), at("pin_bl_y", 0), at("pin_br_x", 0),
       at("pin_br_y", 0)}};
  std::copy(all, all + 7, bends);
  bends[7] = region;
}

// Returns another shape's path at this time, placed in this layer's units
// as shape_cut lays it out. With `all` true the path of every copy of the
// other layer is included.
Canvas2D::Other other_path(Doc& d, int layer, DocShownLayer& t, double now,
                           int with, bool all) {
  Canvas2D::Other o;
  const auto found = d.on_stage.shown.find(with);
  if (with == layer || found == d.on_stage.shown.end() ||
      !found->second.drawn || !found->second.drawn->cut)
    return o;
  const Canvas2D* a = t.drawn;
  const Canvas2D* b = found->second.drawn;
  const math::mat4 back = inverse(doc_place(d, layer, now));
  const tvg::PathCommand* cmds;
  const tvg::Point* pts;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
  b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
  const int many = all ? doc_members(d, with) : 1;
  // A plate can be cut by a whole grid of copies.
  for (int copy = 0; copy < many; ++copy) {
    const math::mat4 to =
        back * (many > 1 ? doc_place(d, with, now, 0, copy, true)
                         : doc_place(d, with, now));
    o.by.insert(o.by.end(), cmds, cmds + cmdsCnt);
    for (uint32_t k = 0; k < ptsCnt; ++k) {
      const math::double4 on =
          to *
          math::double4{
              (pts[k].x - 0.5 * b->cutW) / b->plainHigh * b->sheetHigh,
              (0.5 * b->plainHigh - pts[k].y) / b->plainHigh * b->sheetHigh,
              0.0, 1.0};
      o.at.push_back(
          {(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW),
           (float)(0.5 * a->plainHigh - on.y / a->sheetHigh * a->plainHigh)});
    }
  }
  return o;
}

// Returns the track of another layer over the last trail_length seconds, as in
// Cavalry's Trails, or an empty path when the layer trails none. It follows
// the middle of that layer and is expressed in this layer's path units.
Canvas2D::Other trail_of(Doc& d, int layer, DocShownLayer& t, double now) {
  Canvas2D::Other trace;
  if (const int with = (int)doc_number(d, layer, "trail", 0, 0);
      with && with != layer && d.on_stage.shown.count(with)) {
    const math::mat4 back = inverse(doc_place(d, layer, now));
    const double length =
        std::max(1e-3, doc_number(d, layer, "trail_length", now, 1));
    const Canvas2D* a = t.drawn;
    // The track is sampled on a grid of 64 ticks over its length, fixed in
    // time. A tick is computed once and cached in d.place_cache.tracks, so
    // each evaluation computes only the ticks that are new. The two ends
    // are where the other layer was at the start of the window and where it
    // is now.
    const double step = length / 64.0, last = std::floor(now / step);
    if (d.place_cache.tracks.size() > 200000) d.place_cache.tracks.clear();
    const auto was = [&](double t, long long tick) {
      if (tick < 0)
        return (doc_shown_at(d, with, t) * math::double4{0, 0, 0, 1}).xyz;
      auto found = d.place_cache.tracks.find({with, step, tick});
      if (found == d.place_cache.tracks.end())
        found =
            d.place_cache.tracks
                .emplace(
                    std::make_tuple(with, step, tick),
                    (doc_shown_at(d, with, t) * math::double4{0, 0, 0, 1}).xyz)
                .first;
      return found->second;
    };
    const auto put = [&](math::double3 world) {
      const math::double4 on = back * math::double4{world, 1.0};
      trace.by.push_back(trace.by.empty() ? tvg::PathCommand::MoveTo
                                          : tvg::PathCommand::LineTo);
      trace.at.push_back(
          {(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW),
           (float)(0.5 * a->plainHigh - on.y / a->sheetHigh * a->plainHigh)});
    };
    put(was(now - length, -1));
    for (long long k = (long long)last - 63; k <= (long long)last; ++k)
      if ((double)k * step > now - length) put(was((double)k * step, k));
    put(was(now, -1));
  }
  return trace;
}

// A freehand stroke with AbsentMotion drawing effects such as Stroke
// Taper and Drawing Progress. Its outline is regenerated as those effects
// make it now with absent_drawing and converted to the path's own units.
// It is regenerated only when the effect parameters change.
void drawing_traced(Doc& d, int layer, DocShownLayer& t, double now,
                    Canvas2D::Other& trace) {
  if (const std::string drawn =
          trace.by.empty() ? doc_word(d, layer, "drawing") : std::string();
      !drawn.empty() &&
      doc_word(d, layer, "fx").find(".am") != std::string::npos) {
    std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
    std::erase_if(on, [](const AbsentEffect& e) {
      return e.id != "stroketaper" && e.id != "drawingprogress";
    });
    std::string key = std::to_string(std::hash<std::string>{}(drawn));
    for (const AbsentEffect& e : on)
      for (const auto& [name, v] : e.params)
        for (const float one : v) key += " " + std::to_string(one);
    auto& kept = d.on_stage.drawingKept[layer];
    if (!on.empty() && kept.first != key) {
      kept = {key, absent_drawing(drawn, on, layer, 0.0, 1000.0, 0.0, false)};
    }
    std::vector<tvg::PathCommand> c;
    std::vector<tvg::Point> p;
    if (!on.empty() && sk_svg(kept.second.c_str(), c, p)) {
      const Canvas2D* a = t.drawn;
      for (tvg::Point& at : p)
        at = {0.5f * a->cutW + at.x * a->plainHigh,
              0.5f * a->plainHigh + at.y * a->plainHigh};
      trace.by = std::move(c), trace.at = std::move(p);
    }
  }
}

// Gives each copy of the layer its bends. `bends` are the bends of the layer
// itself.
void copies_bent(Bending& bending, const float4* bends) {
  Doc& d = bending.d;
  Stage& s = *d.stage;
  const int layer = bending.layer;
  DocShownLayer& t = bending.t;
  const bool& driven = bending.driven;
  t.drivenLooks = driven;
  const int members = driven ? doc_members(d, layer) : 1;
  auto& faces = s.engine->getRenderableManager();
  for (const Stage::Renderable& made : s.renderables) {
    if (made.of != t.drawn->sheet || made.matte) continue;
    // When a behaviour drives a bend, each copy gets its own bends in its
    // own material and its edge's material.
    if (driven && !made.many) {
      float4 own[8];
      // Where this copy lies, which a falloff weighs.
      const math::double3 where{made.place[3].x, made.place[3].y,
                                made.place[3].z};
      bends_of(bending, std::max(0, made.nth), members, own, &where);
      if (own[4].z == 0.f) own[4] = bends[4];
      const auto one = faces.getInstance(made.thing);
      MaterialInstance*& look = d.copy_materials.looks[made.thing.getId()];
      if (!look)
        look = MaterialInstance::duplicate(t.drawn->look),
        faces.setMaterialInstanceAt(one, 0, look);
      look->setParameter("bends", own, 8);
      if (t.drawn->edgeLook && faces.getPrimitiveCount(one) > 1) {
        MaterialInstance*& edge = d.copy_materials.edges[made.thing.getId()];
        if (!edge)
          edge = MaterialInstance::duplicate(t.drawn->edgeLook),
          faces.setMaterialInstanceAt(one, 1, edge);
        edge->setParameter("bends", own, 8);
      }
    } else if (const auto own = d.copy_materials.looks.find(made.thing.getId());
               own != d.copy_materials.looks.end())
      own->second->setParameter("bends", bends, 8);
  }
}

}  // namespace

// A shape cut into triangles is bent in its material and its copies'
// materials, and nothing is drawn again.
void evaluate_cut_shape(Doc& d, int layer, DocShownLayer& t, double now,
                        double since) {
  if (!(t.drawn && t.drawn->cut)) return;
  Stage& s = *d.stage;
  const auto num = [&](const char* name, double otherwise) {
    return (float)doc_number(d, layer, name, now, otherwise);
  };
  Bending bending{d, layer, t, now, since};
  float4 bends[8];
  bends_of(bending, 0, 1, bends);
  // Stretch follows motion. Slot 4 holds where the layer's middle was 1/60
  // s ago, seen from the layer's current rotation and size and scaled to
  // units per second.
  if (bends[4].z != 0.f) {
    const math::mat4 was = doc_place(d, layer, now - 1.0 / 60.0),
                     is = doc_place(d, layer, now);
    const math::float4 back = inverse(is) * was * math::float4{0, 0, 0, 1};
    bends[4].x = (float)(-60.0 * back.x), bends[4].y = (float)(-60.0 * back.y);
  }
  t.drawn->look->setParameter("bends", bends, 8);
  if (t.drawn->edgeLook) t.drawn->edgeLook->setParameter("bends", bends, 8);
  // `join` combines this shape with another using the path operations of
  // Skia, in the order subtract, intersect, union, exclude; see
  // engine/stage/canvas/skia_path_operations.cpp. `morph` turns this shape
  // toward another by `much`.
  Canvas2D::Other join, morph;
  const std::string how = doc_word(d, layer, "boolean");
  for (int k = 0; k < 4; ++k)
    if (how == std::array<const char*, 4>{"subtract", "intersect", "union",
                                          "exclude"}[(size_t)k])
      join = other_path(d, layer, t, now,
                        (int)doc_number(d, layer, "boolean_with", 0, 0), true),
      join.how = k;
  if (const float much = num("morph", 0); much > 0.f)
    morph = other_path(d, layer, t, now,
                       (int)doc_number(d, layer, "morph_to", 0, 0), false),
    morph.much = much;
  // Morph steps blend every step at once.
  if (const int steps = (int)doc_number(d, layer, "morph_steps", 0, 0);
      steps > 1)
    morph = other_path(d, layer, t, now,
                       (int)doc_number(d, layer, "morph_to", 0, 0), false),
    morph.much = 1.f, morph.how = std::min(steps, 64);
  Canvas2D::Other trace = trail_of(d, layer, t, now);
  drawing_traced(d, layer, t, now, trace);
  // Cut the path again if anything about it changed.
  cut_at(s, t.drawn,
         float3{num("trim", 0), num("trim_begin", 0), num("trim_offset", 0)},
         {num("round", 0), num("bloat", 0), num("zigzag", 0),
          num("zigzag_ridges", 5), num("zigzag_smooth", 0), num("offset", 0),
          num("rough", 0), num("rough_detail", 0.03),
          std::round(num("resample", 0)), num("voxel", 0)},
         join, morph, trace);
  copies_bent(bending, bends);
}

}  // namespace motolii

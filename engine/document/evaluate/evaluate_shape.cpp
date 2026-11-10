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

namespace motolii {

namespace math = filament::math;
using filament::MaterialInstance;
using filament::math::float3;
using filament::math::float4;

namespace {

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

}  // namespace

// A shape cut into triangles is cut again when its path changed.
void evaluate_cut_shape(Doc& d, int layer, DocShownLayer& t, double now) {
  if (!(t.drawn && t.drawn->cut)) return;
  Stage& s = *d.stage;
  const auto num = [&](const char* name, double otherwise) {
    return (float)doc_number(d, layer, name, now, otherwise);
  };
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
}

}  // namespace motolii

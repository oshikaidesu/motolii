#include "document/evaluate/bodies.h"

#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "community/jolt/rigid_bodies.h"
#include "document/document.h"
#include "document/evaluate/kept_frames.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/expressions.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace math = filament::math;

namespace {
constexpr double kTau = 6.283185307179586;
// How many pixels of the project a metre is (bodies.h).
constexpr double kPixelsAMetre = 100.0;
// What a frame keeps of each body: where its own point is and how far it is
// turned, in metres and radians.
constexpr size_t kKept = 3;

// The plane a layer's copies are laid in: where a copy's offset (ScriptCopy's
// x and y) counts from, before the layer's own size. doc_place puts a copy at
//   above * position * rotation * offset * size * (about the copy's middle).
struct BodyPlane {
  math::mat4 to_world, to_plane;
  // The layer's size across and up, and the world's length of one unit of
  // the plane each way.
  double size_x = 1, size_y = 1, tall = 1, wide = 1, high = 1, turn = 0;
};
BodyPlane doc_body_plane(Doc& d, int layer, double at) {
  math::float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  const math::double3 anchor{doc_literal(d, layer, "anchor_x", at, 0) * half.x,
                             doc_literal(d, layer, "anchor_y", at, 0) * half.y,
                             doc_literal(d, layer, "anchor_z", at, 0) * deep};
  const auto never_zero = [](double v) {
    return std::fabs(v) < 1e-9 ? 1e-9 : v;
  };
  BodyPlane p;
  const double size = doc_literal(d, layer, "size", at, 1);
  p.size_x = never_zero(size * doc_literal(d, layer, "scale_x", at, 1));
  p.size_y = never_zero(size * doc_literal(d, layer, "scale_y", at, 1));
  p.tall = never_zero(doc_literal(d, layer, "tall", at, 1));
  // The layer's own place, before the camera, with its size and anchor taken
  // off again.
  p.to_world =
      doc_place(d, layer, at, 1) * math::mat4::translation(anchor) *
      math::mat4::scaling(math::double3{1.0 / p.size_x,
                                        1.0 / (p.size_y * p.tall), 1.0});
  p.to_plane = inverse(p.to_world);
  p.wide = never_zero(length(p.to_world[0].xyz));
  p.high = never_zero(length(p.to_world[1].xyz));
  p.turn = std::atan2(p.to_world[0].y, p.to_world[0].x);
  return p;
}

// One copy's box in its layer's own units, at size 1: the point it turns
// about (doc_place), half its size, and how far its middle lies above that
// point. A letter is as wide as the letter and as tall as the text's ink; a
// line as wide and tall as the line; anything else is the whole layer.
struct BodyBox {
  double about_x = 0, about_y = 0, half_wide = 0, half_high = 0, above = 0;
};
BodyBox doc_body_box(Doc& d, int layer, int copy) {
  math::float2 half{0.5f};
  doc_half(d, layer, &half);
  BodyBox b;
  b.half_wide = half.x, b.half_high = half.y;
  const auto shown = d.on_stage.shown.find(layer);
  if (shown == d.on_stage.shown.end() || !shown->second.drawn) return b;
  const auto& drawn = *shown->second.drawn;
  if (copy < 0 || (size_t)copy >= drawn.letters.size()) return b;
  const math::float2 cut = drawn.letters[(size_t)copy];
  b.about_x = doc_letter_middle(d, layer, copy);
  b.about_y = doc_line_middle(d, layer, copy);
  if (!drawn.lettersDown) {
    b.half_wide = (double)(cut.y - cut.x) * half.x;
    return b;
  }
  if ((size_t)copy < drawn.boxes.size())
    b.half_wide = (double)drawn.boxes[(size_t)copy].y * half.x;
  b.half_high = (double)(cut.y - cut.x) * half.y;
  b.above = (1.0 - (double)cut.x - (double)cut.y) * half.y - b.about_y;
  return b;
}

// Whether the layer is on at `at`: between its start and its end, and shown.
bool doc_body_layer_on(Doc& d, int layer, double at) {
  const double start = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return at >= start && (lasts <= 0.0 || at < start + lasts) &&
         doc_number(d, layer, "visible", 0, 1) > 0.5;
}

// Finds the layers that have bodies: those whose expressions say a mass for
// any copy where the layer starts. Returns false when they are the same
// layers and counts as before.
bool doc_bodies_found(Doc& d) {
  DocSolver::Bodies& b = d.solver.bodies;
  std::vector<std::pair<int, int>> layers;
  for (const auto& [layer, shown] : d.on_stage.shown) {
    if (layer <= 0) continue;
    const int n = doc_members(d, layer);
    const std::vector<ScriptCopy> laid = doc_copies_laid(
        d, layer, n, std::max(0.0, doc_literal(d, layer, "start", 0, 0)));
    if (std::any_of(laid.begin(), laid.end(),
                    [](const ScriptCopy& c) { return c.mass >= 0; }))
      layers.emplace_back(layer, n);
  }
  std::sort(layers.begin(), layers.end());
  if (layers == b.layers) return false;
  b.layers = std::move(layers), b.first.clear();
  size_t at = 0;
  for (const auto& [layer, n] : b.layers) b.first[layer] = at, at += (size_t)n;
  return true;
}

// Returns the frame of the bodies at time `t`, kKept numbers a body, making
// the frames not yet kept. Returns nullptr when there is none to show.
const std::vector<double>* doc_bodies(Doc& d, double t) {
  DocSolver::Bodies& b = d.solver.bodies;
  DocSolver::RelatedKept& k = b.kept;
  DocKeptTells tells{d, k};
  const auto known = [&]() -> const std::vector<double>* {
    return k.frames.empty()
               ? nullptr
               : &k.frames[std::min((size_t)std::max(0.0, std::round(t * 60.0)),
                                    k.frames.size() - 1)];
  };
  if (b.walking || doc_kept_stands(d, k, t)) return known();
  struct Walking {
    bool& on;
    explicit Walking(bool& on) : on(on) { on = true; }
    ~Walking() { on = false; }
  } walking(b.walking);
  if (k.solves < 0) {
    k.solves = 1;
    // Frames kept for other bodies are of no use.
    if (doc_bodies_found(d) || !b.jolt)
      k.frames.clear(), k.told.clear(), k.sure = k.fresh = 0;
  }
  if (b.layers.empty()) return nullptr;
  if (!b.jolt) b.jolt = std::make_shared<RigidBodies>(), b.at = -1;
  // A metre in stage units, where the first layer with bodies stands.
  b.metre = kPixelsAMetre * (double)d.stage->h /
            std::max(1.0, doc_number(d, 0, "high", 0, 1080) *
                              doc_point(d, b.layers.front().first, 0));
  std::vector<RigidBodyTold> told;
  const auto tell = [&](size_t f) {
    const double at = (double)f / 60.0;
    std::set<int>* const outer = d.solver.reading;
    if (!f) k.reads.clear(), d.solver.reading = &k.reads;
    told.clear();
    std::ostringstream all;
    all.precision(9);
    for (const auto& [layer, n] : b.layers) {
      const BodyPlane plane = doc_body_plane(d, layer, at);
      const std::vector<ScriptCopy> laid = doc_copies_laid(d, layer, n, at);
      const bool on = doc_body_layer_on(d, layer, at);
      for (int i = 0; i < n; ++i) {
        const ScriptCopy c = (size_t)i < laid.size() ? laid[(size_t)i]
                                                     : ScriptCopy{};
        const BodyBox box = doc_body_box(d, layer, i);
        const math::double4 point =
            plane.to_world * math::double4{c.x + plane.size_x * box.about_x,
                                           c.y + plane.size_y * box.about_y,
                                           0.0, 1.0};
        RigidBodyTold body;
        body.present = on && c.mass >= 0 && box.half_wide > 0 &&
                       box.half_high > 0;
        body.half_wide =
            box.half_wide * std::fabs(plane.size_x) * plane.wide / b.metre;
        body.half_high = box.half_high *
                         std::fabs(plane.size_y * plane.tall) * plane.high /
                         b.metre;
        body.middle_y =
            box.above * plane.size_y * plane.tall * plane.high / b.metre;
        body.x = point.x / b.metre, body.y = point.y / b.metre;
        body.turn = plane.turn + c.rotate * kTau / 360.0;
        body.mass = std::max(0.0, c.mass);
        body.gravity_factor = c.gravity_factor;
        body.restitution = c.restitution, body.friction = c.friction;
        body.force_x = c.force_x, body.force_y = c.force_y;
        told.push_back(body);
        all << body.present << ' ' << body.half_wide << ' ' << body.half_high
            << ' ' << body.middle_y << ' ' << body.x << ' ' << body.y << ' '
            << body.turn << ' ' << body.mass << ' ' << body.gravity_factor
            << ' ' << body.restitution << ' ' << body.friction << ' '
            << body.force_x << ' ' << body.force_y << '\n';
      }
    }
    d.solver.reading = outer;
    return all.str();
  };
  const auto make = [&](const std::string&, size_t f) {
    // The first frame is every body where its layer puts it. Any other is one
    // step on from the frame before, from Jolt's state as it was kept then.
    if (!f)
      b.jolt->begin(told);
    else {
      if (b.at != (long)f - 1) b.jolt->restore(b.states[f - 1]);
      b.jolt->step(told);
    }
    b.at = (long)f;
    b.states.resize(std::max(b.states.size(), f + 1));
    b.states[f] = b.jolt->state();
    std::vector<double> next;
    for (const RigidBodyPlace& p : b.jolt->places())
      next.insert(next.end(), {p.x, p.y, p.turn});
    return next;
  };
  doc_kept_walk(d, k, t, tell, make);
  return known();
}
}  // namespace

void doc_body_over(Doc& d, int layer, int copy, double said, ScriptCopy& c) {
  const std::vector<double>* const frame = doc_bodies(d, said);
  const DocSolver::Bodies& b = d.solver.bodies;
  const auto first = b.first.find(layer);
  if (!frame || first == b.first.end() ||
      (first->second + (size_t)copy + 1) * kKept > frame->size() ||
      !doc_body_layer_on(d, layer, said))
    return;
  const double* const is = &(*frame)[(first->second + (size_t)copy) * kKept];
  const BodyPlane plane = doc_body_plane(d, layer, said);
  const BodyBox box = doc_body_box(d, layer, copy);
  const math::double4 point =
      plane.to_plane *
      math::double4{is[0] * b.metre, is[1] * b.metre, 0.0, 1.0};
  c.x = point.x - plane.size_x * box.about_x;
  c.y = point.y - plane.size_y * box.about_y;
  c.rotate = (is[2] - plane.turn) * 360.0 / kTau;
}

}  // namespace motolii

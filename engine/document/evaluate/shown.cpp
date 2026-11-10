#include "document/evaluate/shown.h"

#include <filament/Box.h>
#include <filament/Camera.h>
#include <gltfio/FilamentAsset.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include <algorithm>
#include <cmath>

#include "document/edit/arrange.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace {

// Computes what doc_half caches.
bool doc_half_now(Doc& d, int layer, float2* half, float* deep) {
  const auto shown = d.shown.find(layer);
  if (shown == d.shown.end()) return false;
  const Doc::Shown& t = shown->second;
  if (t.solid) {
    const Aabb box = t.solid->asset->getBoundingBox();
    const float tall = std::max(box.max.y - box.min.y, 1e-6f);
    if (deep) *deep = 0.5f * (box.max.z - box.min.z) / tall;
    return *half = float2{0.5f * (box.max.x - box.min.x) / tall, 0.5f}, true;
  }
  const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
  if (!m || m->pos.empty()) return false;
  float3 most{0.f};
  for (const float3& p : m->pos) most = max(most, abs(p));
  if (deep) *deep = most.z;
  return *half = most.xy, true;
}

}  // namespace

std::vector<int> doc_layers(Doc& d) { return doc_laid(d); }

double doc_lasts(Doc& d, int layer) {
  const double lasts = doc_number(d, layer, "duration", 0, -1);
  return lasts > 0.0 ? lasts : -1.0;
}

std::vector<double> doc_key_times(Doc& d, int layer, const char* name) {
  // This is asked for again and again between changes, so the document is asked
  // only once.
  const auto known = d.keyed.find({layer, name});
  if (known != d.keyed.end()) return known->second;
  std::vector<double>& at = d.keyed[{layer, name}];
  doc_rows(
      d,
      sqlite3_mprintf("select at from keyframe where layer = %d and name = %Q "
                      "and " DOC_KEYED " order by at",
                      layer, name, layer, name),
      [&](sqlite3_stmt* row) { at.push_back(sqlite3_column_double(row, 0)); });
  return at;
}

bool doc_half(Doc& d, int layer, float2* half, float* deep) {
  if (const auto kept = d.halves.find(layer); kept != d.halves.end())
    return *half = kept->second.first, deep ? *deep = kept->second.second : 0.f,
           true;
  float far = 0.f;
  if (!doc_half_now(d, layer, half, &far)) return false;
  d.halves[layer] = {*half, far};
  if (deep) *deep = far;
  return true;
}

math::double2 doc_seen(Doc& d, math::double3 p) {
  Stage& s = *d.stage;
  const math::double4 c = s.camera->getProjectionMatrix() *
                          s.camera->getViewMatrix() * math::double4{p, 1.0};
  // A point at or behind the camera, such as the far corners of a floor, lands
  // far away on that side and not at an undefined number.
  const double w = std::max(c.w, 1e-6);
  return math::double2{(0.5 + 0.5 * c.x / w) * s.w,
                       (0.5 - 0.5 * c.y / w) * s.h};
}

std::string doc_gizmo(Doc& d, int layer, double now) {
  if (!d.working || doc_word(d, layer, "kind") != "camera") return "";
  Stage& s = *d.stage;
  const DocViewCamera e = doc_view_camera_of(d, layer, now);
  const double high = 6.0 * e.far * std::tan(0.5 * e.fov),
               wide = high * double(s.w) / double(s.h);
  const math::double3 x = (e.round * math::double4{wide, 0, 0, 0}).xyz,
                      y = (e.round * math::double4{0, high, 0, 0}).xyz;
  std::string said;
  for (const math::double3 p : {e.look - x + y, e.look + x + y, e.look + x - y,
                                e.look - x - y, e.look, e.eye}) {
    const math::double4 c = s.camera->getProjectionMatrix() *
                            s.camera->getViewMatrix() * math::double4{p, 1.0};
    const math::double2 at = doc_seen(d, p);
    said += c.w <= 0.0
                ? "x x "
                : std::to_string(at.x) + " " + std::to_string(at.y) + " ";
  }
  return said;
}

double doc_point(Doc& d, int layer, double now) {
  const math::double3 at =
      (doc_above(d, layer, now) *
       math::double4{doc_number(d, layer, "x", now, 0),
                     doc_number(d, layer, "y", now, 0),
                     doc_number(d, layer, "z", now, 0), 1.0})
          .xyz;
  return doc_seen(d, at + math::double3{1, 0, 0}).x - doc_seen(d, at).x;
}

math::mat4 doc_shown_at(Doc& d, int layer, double now) {
  return doc_place(d, layer, now, 0, 0,
                   doc_members(d, layer) == 1 && doc_staggered(d, layer, now));
}

bool doc_frame(Doc& d, int layer, double now, double* frame) {
  float2 half{0.f};
  float deep = 0.f;
  // A layer that is not on, or is set aside, has no bounds, because the user
  // cannot grab what is not seen.
  if (!doc_half(d, layer, &half, &deep) || !d.shown[layer].in) return false;
  const double size = doc_number(d, layer, "size", now, 1),
               point = doc_point(d, layer, now);
  // The layer's own middle, wherever its anchor is.
  const math::double2 middle = doc_seen(
      d, (doc_shown_at(d, layer, now) * math::double4{0, 0, 0, 1}).xyz);
  const double sx = doc_number(d, layer, "scale_x", now, 1),
               sy = doc_number(d, layer, "scale_y", now, 1),
               sz = doc_number(d, layer, "scale_z", now, 1);
  frame[0] = middle.x, frame[1] = middle.y,
  frame[2] = 2.0 * half.x * size * std::fabs(sx) * point,
  frame[3] = 2.0 * half.y * size * std::fabs(sy) * point;
  frame[4] = -doc_number(d, layer, "rotate", now, 0) -
             doc_heading(d, layer, now) * 360.0 / (double)TAU;
  const math::double3 anchor{doc_number(d, layer, "anchor_x", now, 0) * half.x,
                             doc_number(d, layer, "anchor_y", now, 0) * half.y,
                             0.0};
  // The point it rotates about.
  const math::double2 pivot = doc_seen(
      d, (doc_shown_at(d, layer, now) * math::double4{anchor, 1.0}).xyz);
  // The last number is the depth of the layer in points, 0 for a flat layer.
  frame[5] = pivot.x, frame[6] = pivot.y,
  frame[7] = 2.0 * deep * size * std::fabs(sz) * point;
  // A layer that is rotated about an axis other than the camera's, or that has
  // a parent, gets the upright box of what it covers as its bounds.
  double box[4];
  if (doc_number(d, layer, "rotate_x", now, 0) != 0.0 ||
      doc_number(d, layer, "rotate_y", now, 0) != 0.0 ||
      doc_number(d, layer, "parent", 0, 0) != 0.0) {
    // Pairs of x and y that outline what the layer covers, taken from its own
    // points where they are at hand, see doc_outline.
    double around[128];
    const int n = doc_outline(d, layer, now, around);
    if (n > 2) {
      double x0 = around[0], x1 = x0, y0 = around[1], y1 = y0;
      for (int i = 1; i < n; ++i)
        x0 = std::min(x0, around[2 * i]), x1 = std::max(x1, around[2 * i]),
        y0 = std::min(y0, around[2 * i + 1]),
        y1 = std::max(y1, around[2 * i + 1]);
      // The middle stays the layer's own. The bounds reach as far each way as
      // the outline goes on its farther side.
      frame[2] = 2.0 * std::max(frame[0] - x0, x1 - frame[0]),
      frame[3] = 2.0 * std::max(frame[1] - y0, y1 - frame[1]), frame[4] = 0.0;
    } else if (doc_covers(d, layer, now, box))
      frame[2] = box[2], frame[3] = box[3], frame[4] = 0.0;
  }
  return true;
}

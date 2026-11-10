#include "document/edit/arrange.h"

#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <utility>

#include "document/card_table.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

namespace {

// Moves a layer by (dx, dy) canvas points by changing its x and y in the plane
// it lies in. Returns false and sets d.error if the layer is seen edge on.
bool doc_move_seen(Doc& d, int layer, double dx, double dy, double now) {
  const math::mat4 above = doc_above(d, layer, now);
  // `o` is the layer's origin on the canvas and `ex` and `ey` are the canvas
  // vectors of its unit x and y. Solving the two by two system gives the change
  // of x and y that moves the layer by (dx, dy).
  const math::double2 o = doc_seen(d, (above * math::double4{0, 0, 0, 1}).xyz),
                      ex =
                          doc_seen(d, (above * math::double4{1, 0, 0, 1}).xyz) -
                          o,
                      ey =
                          doc_seen(d, (above * math::double4{0, 1, 0, 1}).xyz) -
                          o;
  const double det = ex.x * ey.y - ex.y * ey.x;
  if (std::fabs(det) < 1e-12) return d.error = "it is seen edge on", false;
  return doc_value_by(d, layer, "x", (dx * ey.y - dy * ey.x) / det, 1) &&
         doc_value_by(d, layer, "y", (ex.x * dy - ex.y * dx) / det, 1);
}

}  // namespace

bool doc_seen_box(Doc& d, int layer, double now, double* box) {
  double around[128], cover[4];
  if (!d.shown[layer].in) return false;
  const int n = doc_outline(d, layer, now, around);
  if (n > 2) {
    box[0] = box[2] = around[0], box[1] = box[3] = around[1];
    for (int i = 1; i < n; ++i)
      box[0] = std::min(box[0], around[2 * i]),
      box[2] = std::max(box[2], around[2 * i]),
      box[1] = std::min(box[1], around[2 * i + 1]),
      box[3] = std::max(box[3], around[2 * i + 1]);
    return true;
  }
  if (!doc_covers(d, layer, now, cover)) return false;
  box[0] = cover[0], box[1] = cover[1], box[2] = cover[0] + cover[2],
  box[3] = cover[1] + cover[3];
  return true;
}

bool doc_value_by(Doc& d, int layer, const char* name, double add,
                  double times) {
  int rows = 0;
  doc_rows(d,
           sqlite3_mprintf(
               "select count(*) from keyframe where layer = %d and name = %Q",
               layer, name),
           [&](sqlite3_stmt* q) { rows = sqlite3_column_int(q, 0); });
  if (!rows) return doc_set(d, layer, name, doc_usual(d, name) * times + add);
  return doc_change(
      d, sqlite3_mprintf("update keyframe set value = value * %!.17g + %!.17g "
                         "where layer = %d and name = %Q",
                         times, add, layer, name));
}

bool doc_align(Doc& d, const std::vector<int>& layers, const std::string& how) {
  const double now = d.stage->now;
  std::vector<std::array<double, 4>> boxes;
  for (const int t : layers) {
    std::array<double, 4> b{};
    if (!doc_seen_box(d, t, now, b.data()))
      return d.error = "a layer not seen now", false;
    boxes.push_back(b);
  }
  if (boxes.empty()) return d.error = "nothing to line up", false;
  // The box that layers are aligned to: the canvas for a single layer,
  // otherwise the box around all layers.
  std::array<double, 4> all =
      layers.size() == 1
          ? std::array<double, 4>{0, 0, (double)d.stage->w, (double)d.stage->h}
          : boxes[0];
  for (const auto& b : boxes)
    if (layers.size() > 1)
      all = {std::min(all[0], b[0]), std::min(all[1], b[1]),
             std::max(all[2], b[2]), std::max(all[3], b[3])};
  // `by` is the movement in x and y that each layer needs.
  std::vector<std::pair<double, double>> by(layers.size(), {0.0, 0.0});
  // Spread: layers are ordered by their centre along the axis. The first and
  // the last stay where they are and the gaps between the others are made
  // equal. `a` is the axis, 0 for x and 1 for y.
  if (how == "across" || how == "down") {
    const int a = how == "across" ? 0 : 1;
    if (layers.size() < 3) return d.error = "three or more are spread", false;
    std::vector<size_t> order(layers.size());
    for (size_t i = 0; i < order.size(); ++i) order[i] = i;
    std::sort(order.begin(), order.end(), [&](size_t p, size_t q) {
      return boxes[p][a] + boxes[p][a + 2] < boxes[q][a] + boxes[q][a + 2];
    });
    double sizes = 0;
    for (const auto& b : boxes) sizes += b[a + 2] - b[a];
    const double gap =
        (boxes[order.back()][a + 2] - boxes[order.front()][a] - sizes) /
        (double)(layers.size() - 1);
    double at = boxes[order.front()][a];
    for (const size_t i : order) {
      (a ? by[i].second : by[i].first) = at - boxes[i][a];
      at += boxes[i][a + 2] - boxes[i][a] + gap;
    }
  } else
    for (size_t i = 0; i < layers.size(); ++i) {
      const auto& b = boxes[i];
      if (how == "left")
        by[i].first = all[0] - b[0];
      else if (how == "centre")
        by[i].first = (all[0] + all[2] - b[0] - b[2]) / 2;
      else if (how == "right")
        by[i].first = all[2] - b[2];
      else if (how == "top")
        by[i].second = all[1] - b[1];
      else if (how == "middle")
        by[i].second = (all[1] + all[3] - b[1] - b[3]) / 2;
      else if (how == "bottom")
        by[i].second = all[3] - b[3];
      else
        return d.error =
                   "lined up left, centre, right, top, middle, bottom, across "
                   "or down",
               false;
    }
  doc_act(d);
  bool ok = true;
  for (size_t i = 0; i < layers.size() && ok; ++i)
    ok = doc_move_seen(d, layers[i], by[i].first, by[i].second, now);
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

bool doc_fit(Doc& d, int layer, const std::string& how) {
  const double now = d.stage->now;
  double b[4];
  // Inside a larger undo step, first show what has been made so far, as the end
  // of a step does (doc_acted). This lets an image that is placed and fitted in
  // one step be measured correctly.
  if (d.act && d.act_unmatched) {
    d.act_unmatched = false;
    doc_forget(d);
    if (d.act_ok && !doc_match(d)) d.act_ok = false;
  }
  // While measuring, the layer is fitted to the canvas whichever camera the
  // window looks through, as After Effects' Fit to Comp does. The camera is
  // switched off here and restored by `back`.
  const bool viewCamera = d.viewCameraAsked;
  if (viewCamera) d.viewCameraAsked = false, doc_evaluate(d, now);
  const auto back = [&](bool ok) {
    if (viewCamera) d.viewCameraAsked = true, doc_evaluate(d, now);
    return ok;
  };
  if (!doc_seen_box(d, layer, now, b) || b[2] - b[0] < 1e-6 ||
      b[3] - b[1] < 1e-6)
    return d.error = "it is not seen now", back(false);
  const double wx = (double)d.stage->w / (b[2] - b[0]),
               wy = (double)d.stage->h / (b[3] - b[1]);
  if (how != "fit" && how != "fill" && how != "stretch")
    return d.error = "made to fit, fill or stretch", back(false);
  doc_act(d);
  bool ok = how == "stretch" ? doc_value_by(d, layer, "scale_x", 0, wx) &&
                                   doc_value_by(d, layer, "scale_y", 0, wy)
                             : doc_value_by(d, layer, "size", 0,
                                            how == "fit" ? std::min(wx, wy)
                                                         : std::max(wx, wy));
  if (ok) {
    // Evaluate again so that the box matches the new size before the layer is
    // centred.
    doc_evaluate(d, now);
    ok = doc_seen_box(d, layer, now, b) &&
         doc_move_seen(d, layer, d.stage->w / 2.0 - (b[0] + b[2]) / 2,
                       d.stage->h / 2.0 - (b[1] + b[3]) / 2, now);
  }
  if (!ok) d.act_ok = false;
  return back(doc_acted(d) && ok);
}

bool doc_covers(Doc& d, int layer, double now, double* box) {
  float2 half{0.f};
  float deep = 0.f;
  if (!doc_half(d, layer, &half, &deep)) return false;
  const math::mat4 place = doc_shown_at(d, layer, now);
  math::double2 low{1e12}, high{-1e12};
  for (int corner = 0; corner < 8; ++corner) {
    const math::double2 at =
        doc_seen(d, (place * math::double4{corner & 1 ? half.x : -half.x,
                                           corner & 2 ? half.y : -half.y,
                                           corner & 4 ? deep : -deep, 1.0})
                        .xyz);
    low = min(low, at), high = max(high, at);
  }
  box[0] = low.x, box[1] = low.y, box[2] = high.x - low.x,
  box[3] = high.y - low.y;
  return true;
}

int doc_outline(Doc& d, int layer, double now, double* xy) {
  float2 half{0.f};
  float deep = 0.f;
  if (!doc_half(d, layer, &half, &deep) || !d.shown[layer].in) return 0;
  const math::mat4 place = doc_shown_at(d, layer, now);
  std::vector<math::double2> p;
  // Use the mesh vertices when they are available, taking about 600 of them at
  // most.
  if (const Mesh* shape = d.shown[layer].shape; shape && !shape->pos.empty()) {
    const size_t step = std::max<size_t>(1, shape->pos.size() / 600);
    for (size_t i = 0; i < shape->pos.size(); i += step)
      p.push_back(doc_seen(
          d, (place * math::double4{math::double3(shape->pos[i]), 1.0}).xyz));
  } else
    for (int corner = 0; corner < (deep > 0.f ? 8 : 4); ++corner)
      p.push_back(
          doc_seen(d, (place * math::double4{corner & 1 ? half.x : -half.x,
                                             corner & 2 ? half.y : -half.y,
                                             corner & 4 ? deep : -deep, 1.0})
                          .xyz));
  std::sort(p.begin(), p.end(),
            [](const math::double2& a, const math::double2& b) {
              return a.x < b.x || (a.x == b.x && a.y < b.y);
            });
  const auto turn = [](const math::double2& o, const math::double2& a,
                       const math::double2& b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  };
  std::vector<math::double2> hull(2 * p.size());
  size_t k = 0;
  for (size_t i = 0; i < p.size(); ++i) {
    while (k >= 2 && turn(hull[k - 2], hull[k - 1], p[i]) <= 0) --k;
    hull[k++] = p[i];
  }
  for (size_t i = p.size() - 1, t = k + 1; i > 0; --i) {
    while (k >= t && turn(hull[k - 2], hull[k - 1], p[i - 1]) <= 0) --k;
    hull[k++] = p[i - 1];
  }
  const size_t all = k > 0 ? k - 1 : 0;
  // At most 64 points, chosen evenly, which is round enough.
  const int n = (int)std::min<size_t>(all, 64);
  for (int i = 0; i < n; ++i) {
    const size_t j = (size_t)i * all / (size_t)n;
    xy[2 * i] = hull[j].x, xy[2 * i + 1] = hull[j].y;
  }
  return n;
}

double doc_usual(Doc& d, const char* name) {
  // A script parameter: its default is declared in the head of the script.
  if (!strncmp(name, "js_", 3))
    for (const auto& [file, sc] : doc_scripts(d))
      for (size_t i = 0; i < sc.names.size(); ++i)
        if (sc.names[i] == name) return sc.parameters[i].usual;
  // Properties that default to 1 are listed here. duration defaults to -1 and
  // any property not named below defaults to 0.
  return doc_among(
             "parent_rotate parent_size scale_x scale_y scale_z size speed "
             "volume opacity wide tall visible distance zoom copies "
             "blur_levelletter_spacing line_spacing contrast saturation "
             "vibrance environment gradient_scale slope power strength spread",
             name)
             ? 1.0
         : !strcmp(name, "duration") ? -1.0
         // Defaults of the group behaviours.
         : !strcmp(name, "radius") ? 0.5
         : !strcmp(name, "gap")    ? 0.2
         // Defaults of a solid's material and of the sun.
         : !strcmp(name, "metallic") ||
                 doc_among("bevel_metallic side_metallic back_metallic", name)
             ? 0.08
         : !strcmp(name, "roughness") ||
                 doc_among("bevel_roughness side_roughness back_roughness",
                           name)
             ? 0.6
         : !strcmp(name, "reflectance") ? 0.5
         : !strcmp(name, "thickness")   ? 0.5
         : !strcmp(name, "sun_size")    ? 1.09
         : !strcmp(name, "sun_halo")    ? 10.0
         // Defaults of a light.
         : !strcmp(name, "intensity") ? 1.0
         : !strcmp(name, "falloff")   ? 10.0
         : !strcmp(name, "cone")      ? 30.0
         // Where the fog begins, as it was before this could be set.
         : !strcmp(name, "fog_near") ? 2.0
         // Defaults of physics: what falls and strikes.
         : !strcmp(name, "bounce")   ? 0.3
         : !strcmp(name, "friction") ? 0.5
         : !strcmp(name, "gravity")  ? 9.81
         // Defaults of the glass material.
         : !strcmp(name, "ior")        ? 1.5
         : !strcmp(name, "dispersion") ? 0.1
         : !strcmp(name, "swim")       ? 0.5
         : !strcmp(name, "dark")       ? 4.0
         : !strcmp(name, "vivid")      ? 1.3
                                       : 0.0;
}

double doc_usual_on(Doc& d, int layer, const char* name) {
  return !strcmp(name, "scale_z") && doc_word(d, layer, "kind") != "solid" ? 0.0
         : !strcmp(name, "points")
             ? (doc_word(d, layer, "shape") == "star" ? 5.0 : 6.0)
         : !strcmp(name, "inner") ? 0.5
                                  : doc_usual(d, name);
}

bool doc_value(Doc& d, int layer, const char* name, double at, double* is) {
  return doc_knows(d, layer, name) &&
         (*is = doc_number(d, layer, name, at, doc_usual_on(d, layer, name)),
          true);
}

}  // namespace motolii

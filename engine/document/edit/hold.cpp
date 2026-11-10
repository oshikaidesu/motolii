#include "document/edit/hold.h"

#include <math/mat3.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <string>
#include <vector>

#include "document/edit/arrange.h"
#include "document/edit/layer_edit.h"
#include "document/edit/paths.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/expressions.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

bool doc_hold(Doc& d, int layer) {
  if (!doc_knows(d, layer)) return false;
  if (d.writing)
    return d.error =
               "the document is being written as a film: nothing is held until "
               "that is done",
           false;
  if (d.held.layer != layer) d.held = Doc::Held{}, d.held.layer = layer;
  return true;
}

double doc_own_clock(Doc& d, int t, double by) {
  if (doc_word(d, t, "kind") == "video")
    return by * std::fabs(doc_number(d, t, "speed", 0, 1));
  return doc_word(d, t, "script").empty() ? 0.0 : by;
}

bool doc_carry(Doc& d, const char* by, double a, double b) {
  Doc::Held& h = d.held;
  // The "even_" modes keep the ratio of width to height, or turn in steps of 15
  // degrees, as Shift does in Figma: it "temporarily locks" the aspect ratio
  // and will "snap rotation values to increments of 15". A corner follows the
  // pointer's travel along the diagonal, so pulling a corner through the
  // opposite one flips the layer.
  const bool even = !strncmp(by, "even_", 5);
  if (even) by += 5;
  // Makes the two scale factors equal. With both axes active, the shared factor
  // is the projection of the new position n on the grip position g. With one
  // axis active, which is the middle of a side, the other axis gets the same
  // factor.
  const auto alike = [](double& k0, double& k1, bool& on0, bool& on1, double g0,
                        double g1, double n0, double n1) {
    if (on0 && on1)
      k0 = k1 = (n0 * g0 + n1 * g1) / (g0 * g0 + g1 * g1);
    else if (on0)
      k1 = k0;
    else if (on1)
      k0 = k1;
    on0 = on1 = on0 || on1;
  };
  if (h.layer < 0) return d.error = "nothing is held", false;
  const double now = d.stage->now;
  // Returns the value a property had when the drag first read it. The first
  // read is saved in h.from.
  const auto was = [&](const char* name) {
    auto found = h.from.find(name);
    if (found == h.from.end())
      found = h.from
                  .emplace(name, doc_number(d, h.layer, name, now,
                                            doc_usual(d, name)))
                  .first;
    return found->second;
  };
  // Sets the dragged value of a property, `is`. Returns false if the property
  // is unknown or rejects the value.
  const auto tries = [&](const char* name, double is) {
    return doc_knows(d, h.layer, name, &is) && (h.tried[name] = is, true);
  };
  bool ok = true;
  if (!strcmp(by, "place")) {
    // When the user works through a view camera, the pointer's travel is along
    // that camera's axes, as the working views of After Effects move a 3D
    // layer.
    const math::mat3 ways = d.working
                                ? d.stage->camera->getModelMatrix().upperLeft()
                                : math::mat3{};
    // Saved with the drag: how many canvas points one stage unit is where the
    // layer stood.
    if (!h.from.count(" point")) {
      const math::double3 at =
          (doc_above(d, h.layer, now) *
           math::double4{doc_number(d, h.layer, "x", now, 0),
                         doc_number(d, h.layer, "y", now, 0),
                         doc_number(d, h.layer, "z", now, 0), 1.0})
              .xyz;
      h.from[" point"] = d.working
                             ? doc_seen(d, at + ways[0]).x - doc_seen(d, at).x
                             : doc_point(d, h.layer, now);
    }
    const double x = was("x"), y = was("y"), z = d.working ? was("z") : 0.0,
                 point = h.from[" point"];
    // The pointer's travel is in stage space. A layer that moves with another
    // layer, its parent, is moved in the parent's rotated and scaled space.
    const math::double3 by = inverse(doc_above(d, h.layer, now).upperLeft()) *
                             (ways * math::double3{a / point, -b / point, 0.0});
    ok = tries("x", x + by.x) && tries("y", y + by.y) &&
         (!d.working || tries("z", z + by.z));
  } else if (!strcmp(by, "grip")) {
    // Records where on the canvas the pointer took hold, in points from the top
    // left. Scale, turn and pivot measure from it. frame[] is the layer's box
    // on the canvas: the middle x and y, the width, the height, the rotation,
    // and the pivot x and y.
    double frame[8];
    if (!doc_frame(d, h.layer, now, frame))
      return d.error = "it has no frame on the picture", false;
    h.from[" grip x"] = a, h.from[" grip y"] = b, h.from[" pivot x"] = frame[5],
    h.from[" pivot y"] = frame[6], h.from[" turned"] = frame[4];
    h.from[" middle x"] = frame[0], h.from[" middle y"] = frame[1],
    h.from[" wide"] = frame[2], h.from[" high"] = frame[3];
    h.from[" point"] = doc_point(d, h.layer, now);
    was("scale_x"), was("scale_y"), was("rotate"), was("anchor_x"),
        was("anchor_y"), was("x"), was("y");
  } else if (!strcmp(by, "scale") || !strcmp(by, "turn") ||
             !strcmp(by, "pivot")) {
    // Here a, b are how far the pointer has moved since it took hold.
    if (!h.from.count(" grip x"))
      return d.error = "the hand has not said where it took hold (grip)", false;
    const double px = h.from[" pivot x"], py = h.from[" pivot y"],
                 gx = h.from[" grip x"] - px, gy = h.from[" grip y"] - py,
                 hx = gx + a, hy = gy + b;
    // c and s rotate canvas vectors into the layer's own upright axes. The
    // canvas counts angles clockwise.
    const double turned = h.from[" turned"] * (double)TAU / 360.0,
                 c = std::cos(-turned), s = std::sin(-turned);
    if (!strcmp(by, "scale")) {
      // Each axis is scaled by the ratio of the pointer's distance from the
      // pivot now to its distance when it took hold. An axis where the grip
      // lies within 2 points of the pivot is not scaled.
      const double g0 = c * gx - s * gy, g1 = s * gx + c * gy,
                   n0 = c * hx - s * hy, n1 = s * hx + c * hy;
      bool on0 = std::fabs(g0) >= 2.0, on1 = std::fabs(g1) >= 2.0;
      double k0 = on0 ? n0 / g0 : 1.0, k1 = on1 ? n1 / g1 : 1.0;
      if (even) alike(k0, k1, on0, on1, g0, g1, n0, n1);
      ok = (!on0 || tries("scale_x", was("scale_x") * k0)) &&
           (!on1 || tries("scale_y", was("scale_y") * k1));
    } else if (!strcmp(by, "turn")) {
      // Rotates by the angle the pointer has swept round the pivot. The canvas
      // counts angles clockwise and the stage counts them the other way, hence
      // the minus sign.
      const double by = std::atan2(hy, hx) - std::atan2(gy, gx),
                   to = was("rotate") - by * 360.0 / (double)TAU;
      ok = tries("rotate", even ? std::round(to / 15.0) * 15.0 : to);
    } else {
      // Moves the pivot under the pointer while the layer stays where it
      // appears, like the Pan Behind tool of After Effects. l0 and l1 are the
      // pointer's travel in the layer's own units, with y up.
      float2 half{0.5f};
      doc_half(d, h.layer, &half);
      const double point = h.from[" point"],
                   size = was("size") == 0.0
                              ? 1.0
                              : doc_number(d, h.layer, "size", now, 1);
      const double l0 = (c * a - s * b) / point, l1 = -(s * a + c * b) / point;
      const double sx = was("scale_x"), sy = was("scale_y");
      ok = tries("anchor_x",
                 was("anchor_x") + l0 / (size * (sx == 0.0 ? 1.0 : sx) *
                                         std::max(half.x, 1e-6f))) &&
           tries("anchor_y",
                 was("anchor_y") + l1 / (size * (sy == 0.0 ? 1.0 : sy) *
                                         std::max(half.y, 1e-6f)));
      const math::double3 move =
          inverse(doc_above(d, h.layer, now).upperLeft()) *
          math::double3{a / point, -b / point, 0.0};
      ok = ok && tries("x", was("x") + move.x) && tries("y", was("y") + move.y);
    }
  } else if (!strcmp(by, "side")) {
    // Resizes the layer while the side or corner opposite the grip stays where
    // it is, like the handles of Figma and Keynote. "scale" resizes about the
    // pivot instead, as with Alt.
    if (!h.from.count(" grip x"))
      return d.error = "the hand has not said where it took hold (grip)", false;
    const double turned = h.from[" turned"] * (double)TAU / 360.0,
                 c = std::cos(-turned), s = std::sin(-turned);
    // Converts a canvas vector, taken from the layer's middle, into the layer's
    // own upright axes.
    const auto own = [&](double x, double y) {
      return math::double2{c * x - s * y, s * x + c * y};
    };
    const double mx = h.from[" middle x"], my = h.from[" middle y"],
                 w = h.from[" wide"], hi = h.from[" high"];
    const math::double2 grip =
        own(h.from[" grip x"] - mx, h.from[" grip y"] - my);
    // o is the opposite side or corner, relative to the middle. When the grip
    // is in the middle of an edge, o is 0 along that axis, so that axis is not
    // resized.
    const math::double2 o{
        std::fabs(grip.x) > w / 4.0 ? -std::copysign(w / 2.0, grip.x) : 0.0,
        std::fabs(grip.y) > hi / 4.0 ? -std::copysign(hi / 2.0, grip.y) : 0.0};
    const math::double2 pivot = own(h.from[" pivot x"] - mx,
                                    h.from[" pivot y"] - my),
                        g = grip - o,
                        n = own(h.from[" grip x"] + a - mx,
                                h.from[" grip y"] + b - my) -
                            o;
    bool on0 = o.x != 0.0 && std::fabs(g.x) >= 2.0,
         on1 = o.y != 0.0 && std::fabs(g.y) >= 2.0;
    double k0 = on0 ? n.x / g.x : 1.0, k1 = on1 ? n.y / g.y : 1.0;
    // Held by the middle of a side, the other axis is scaled as much, about the
    // middle.
    if (even) alike(k0, k1, on0, on1, g.x, g.y, n.x, n.y);
    ok = (!on0 || tries("scale_x", was("scale_x") * k0)) &&
         (!on1 || tries("scale_y", was("scale_y") * k1));
    // Scaling about the pivot moves the opposite side. `back` is how far to
    // move the layer to put that side back, in the layer's upright axes.
    const math::double2 back{(1.0 - k0) * (o.x - pivot.x),
                             (1.0 - k1) * (o.y - pivot.y)};
    const double dx = c * back.x + s * back.y, dy = -s * back.x + c * back.y,
                 point = h.from[" point"];
    const math::double3 move = inverse(doc_above(d, h.layer, now).upperLeft()) *
                               math::double3{dx / point, -dy / point, 0.0};
    ok = ok && tries("x", was("x") + move.x) && tries("y", was("y") + move.y);
  } else if (!strcmp(by, "point")) {
    // Moves the point of a path shape that is nearest the grip, as far as the
    // pointer has moved. a, b are the pointer's travel.
    if (!h.from.count(" grip x"))
      return d.error = "the hand has not said where it took hold (grip)", false;
    // On the first call, choose the point and save the path as it was. Both are
    // kept with the drag.
    if (!h.said.count(" path")) {
      int nearest = -1;
      double near = 12.0;
      // Points are searched first, then handles. A handle that lies on its
      // point counts as the point.
      for (const bool handles : {false, true}) {
        std::vector<double> xy(2048);
        const int n = std::min(
            1024, doc_points(d, h.layer, now, xy.data(), 1024, handles));
        for (int i = 0; i < n; ++i)
          if (const double far = std::hypot(xy[2 * i] - h.from[" grip x"],
                                            xy[2 * i + 1] - h.from[" grip y"]);
              far < near - 0.5)
            near = far, nearest = i, h.from[" handle"] = handles;
      }
      if (nearest < 0)
        return d.error = "no point of its path where the hand took hold", false;
      h.from[" point"] = nearest,
      h.said[" path"] = doc_word(d, h.layer, "path");
    }
    const DocPlane plane(d, h.layer, now);
    const math::double2 from = plane.own(h.from[" grip x"], h.from[" grip y"]),
                        to = plane.own(h.from[" grip x"] + a,
                                       h.from[" grip y"] + b);
    std::string moved;
    if (!plane.seen ||
        !(h.from[" handle"] != 0.0 ? sk_svg_move_handle : sk_svg_move)(
            h.said[" path"].c_str(), (int)h.from[" point"],
            (float)(to.x - from.x), (float)(to.y - from.y), moved))
      return d.error = "its point could not be moved", false;
    h.said["path"] = moved;
    // Rebuild the canvas with the new path.
    ok = doc_match(d);
  } else if (!strcmp(by, "bar")) {
    // The whole layer moves in time. Its keyframes go with it when the drag
    // ends.
    h.from[" bar"] = 1.0;
    ok = tries("start", std::max(0.0, was("start") + a));
  } else if (!strcmp(by, "head")) {
    const double start = was("start"), lasts = was("duration"),
                 to = std::clamp(start + a, 0.0,
                                 lasts > 0.0 ? start + lasts - 1e-3 : 1e6);
    ok = tries("start", to) &&
         (lasts <= 0.0 || tries("duration", start + lasts - to));
    if (const double on = doc_own_clock(d, h.layer, to - start);
        ok && on != 0.0)
      ok = tries("begin", std::max(0.0, was("begin") + on));
  } else if (!strcmp(by, "tail")) {
    const double start = was("start"), lasts = was("duration");
    ok = tries(
        "duration",
        std::max(1e-3, (lasts > 0.0 ? lasts : doc_seconds(d) - start) + a));
  } else {
    // `by` is the name of a property. Save its original value first, so that it
    // can be restored when the drag is discarded.
    was(by);
    // `a` is the value the user sees. A value turned by a macro includes the
    // macro's contribution, so subtract it; see expressions.h.
    ok = tries(by, doc_macro_own(d, h.layer, by, now, a));
    // A property that the layer is built from is rebuilt at once, not when the
    // drag ends.
    if (ok && strstr(doc_making, ("'" + std::string(by) + "'").c_str()))
      ok = doc_match(d);
    // A property of an effect is rebuilt only if the effect now reaches past
    // its room.
    else if (ok && strstr(doc_fxing, ("'" + std::string(by) + "'").c_str()))
      ok = doc_match(d);
  }
  doc_evaluate(d, now);
  return ok;
}

bool doc_carry_effect(Doc& d, const char* file) {
  Doc::Held& h = d.held;
  if (h.layer < 0) return d.error = "nothing is held", false;
  // Same rule as doc_fx_say.
  if (doc_word(d, h.layer, "kind") == "camera" &&
      std::filesystem::path(file).extension() != ".am")
    return d.error =
               "a camera takes motions only (it has no picture of its own)",
           false;
  // The leading space marks a key that belongs to the drag itself. Such keys
  // are never written to the document when the drag ends.
  h.said[" effect"] = file;
  return doc_match(d), doc_evaluate(d, d.stage->now), true;
}

}  // namespace motolii

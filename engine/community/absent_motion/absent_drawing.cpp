// Freehand strokes from AbsentMotion: builds the outline of a drawing layer's
// strokes with AbsentMotion's drawing.cpp (BuildGeometry makes a brush from a
// band of round pieces, each as wide as its pressure says; EachPiece applies
// Stroke Taper and Drawing Progress). AbsentMotion is Apache-2.0, Copyright
// 2026 The AbsentMotion authors.
//
// drawing.cpp is included whole and unchanged so that its stroke building,
// which is private to that file, can be called from here. The pieces are either
// merged into one outline with Skia's union (SkPathOps), or put side by side to
// be filled as one (libtess2 nonzero, canvas_flat.h).
#include <algorithm>
#include <cstdint>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_layer.h"
#include "community/absent_motion/absent_motion.h"
#include "drawing.cpp"
#include "include/pathops/SkPathOps.h"
#include "include/utils/SkParsePath.h"

// See absent_motion.h.
std::string absent_drawing(const std::string& strokes,
                           const std::vector<AbsentEffect>& effects,
                           int64_t thing, double startMs, double endMs,
                           double nowMs, bool together) {
  // Coordinates are scaled by 1000 on the way in and back on the way out.
  // Skia's curve and stroke code works to about one unit, so this keeps it as
  // fine as a thousandth of a pixel.
  constexpr float k = 1000.f;
  am::Layer l = absent_layer(effects, thing, startMs, endMs);
  std::istringstream all_said(strokes);
  // Each stroke is parsed the way AbsentMotion's ParseStrokes parses a layer's
  // strokes.
  for (std::string said; std::getline(all_said, said, ';');) {
    std::istringstream in(said);
    int tool = 1;
    float width = 0.f;
    if (!(in >> tool >> width)) continue;
    std::vector<SkPoint> pts;
    std::vector<float> pressure;
    for (float x, y, p; in >> x >> y >> p;)
      pts.push_back({k * x, k * y}), pressure.push_back(std::max(0.0f, p));
    if (pts.empty()) continue;
    am::FreehandStroke s;
    s.tool = tool == 0   ? am::kPen
             : tool == 2 ? am::kFill
             : tool == 3 ? am::kEraser
                         : am::kBrush,
    s.width = k * width;
    together |= s.tool == am::kEraser;
    am::BuildGeometry(&s, pts, pressure);
    l.strokes.push_back(std::move(s));
  }
  SkPath all;
  am::EachPiece(
      l, l.localTime(nowMs),
      [&](const am::FreehandStroke& one, const SkPath& geometry, bool filled) {
        // A pen's line keeps its width, with round ends and corners
        // (AbsentMotion's StrokedOutline).
        am::FreehandStroke piece = one;
        piece.geometry = geometry;
        const SkPath shape = filled ? geometry : am::StrokedOutline(piece);
        // AbsentMotion's DrawDrawing clears with kClear; here the eraser is
        // subtracted from the outline.
        if (one.tool == am::kEraser) Op(all, shape, kDifference_SkPathOp, &all);
        // When the pieces are not merged, or the union fails, they are put side
        // by side and filled as one.
        else if (!together || !Op(all, shape, kUnion_SkPathOp, &all))
          all = SkPathBuilder(all).addPath(shape).detach();
      });
  return SkParsePath::ToSVGString(
             all.makeTransform(SkMatrix::Scale(1.f / k, 1.f / k)))
      .c_str();
}

// skia_path_operations.cpp: Path operations on 2D shapes, implemented with
// Skia.
//
// Cavalry draws its shape paths with the same Skia code. The functions here
// provide:
//   - Boolean operations on two paths: union, difference, intersection and
//   exclusion
//     (SkPathOps).
//   - Reading SVG path data (SkParsePath) and editing it like a pen tool:
//   moving points and
//     handles, adding and removing points.
//   - Roughening a path (SkDiscretePathEffect), morphing between two paths,
//   resampling,
//     trimming, placing points along a path, and voxelizing.
//   - Hit testing against a path.
//
// Editing SVG path data like a pen tool (anchors, handles, adding and removing
// points) is in skia_svg_edit.cpp.
//
// This file is separate from the rest of the canvas code because Skia's headers
// declare many names that would clash with ours. Only the functions declared in
// path_operations.h are visible to the rest of the engine. Built by skia.sh.
#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "include/core/SkContourMeasure.h"
#include "include/core/SkMatrix.h"
#include "include/core/SkPath.h"
#include "include/core/SkPathBuilder.h"
#include "include/core/SkRegion.h"
#include "include/core/SkString.h"
#include "include/core/SkStrokeRec.h"
#include "include/effects/SkDiscretePathEffect.h"
#include "include/pathops/SkPathOps.h"
#include "include/utils/SkParsePath.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

static SkPath sk_of(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
                    const tvg::Point* pts) {
  SkPathBuilder b;
  for (uint32_t c = 0, p = 0; c < cmdsCnt; ++c) switch (cmds[c]) {
      case tvg::PathCommand::MoveTo:
        b.moveTo(pts[p].x, pts[p].y), ++p;
        break;
      case tvg::PathCommand::LineTo:
        b.lineTo(pts[p].x, pts[p].y), ++p;
        break;
      case tvg::PathCommand::CubicTo:
        b.cubicTo(pts[p].x, pts[p].y, pts[p + 1].x, pts[p + 1].y, pts[p + 2].x,
                  pts[p + 2].y),
            p += 3;
        break;
      case tvg::PathCommand::Close:
        b.close();
        break;
    }
  return b.detach();
}

// Appends the Skia path to `cmds` and `pts` as ThorVG commands. ThorVG has only
// cubic curves, so quads and conics are converted to cubics. Returns false if
// nothing was appended.
static bool tvg_of(const SkPath& built, std::vector<tvg::PathCommand>& cmds,
                   std::vector<tvg::Point>& pts) {
  // Appends the quad a, q, e as the cubic with the same shape.
  const auto cubic = [&](SkPoint a, SkPoint q, SkPoint e) {
    cmds.push_back(tvg::PathCommand::CubicTo);
    pts.push_back(
        {a.fX + 2.f / 3.f * (q.fX - a.fX), a.fY + 2.f / 3.f * (q.fY - a.fY)});
    pts.push_back(
        {e.fX + 2.f / 3.f * (q.fX - e.fX), e.fY + 2.f / 3.f * (q.fY - e.fY)});
    pts.push_back({e.fX, e.fY});
  };
  SkPathIter it = built.iter();
  while (const std::optional<SkPathIter::Rec> r = it.next()) {
    const SkSpan<const SkPoint> p = r->fPoints;
    switch (r->fVerb) {
      case SkPathVerb::kMove:
        cmds.push_back(tvg::PathCommand::MoveTo),
            pts.push_back({p[0].fX, p[0].fY});
        break;
      case SkPathVerb::kLine:
        cmds.push_back(tvg::PathCommand::LineTo),
            pts.push_back({p[1].fX, p[1].fY});
        break;
      case SkPathVerb::kQuad:
        cubic(p[0], p[1], p[2]);
        break;
      case SkPathVerb::kConic: {
        SkPoint q[1 + 2 * 8];
        const int n = SkPath::ConvertConicToQuads(p[0], p[1], p[2],
                                                  r->conicWeight(), q, 3);
        for (int i = 0; i < n; ++i) cubic(q[2 * i], q[2 * i + 1], q[2 * i + 2]);
        break;
      }
      case SkPathVerb::kCubic:
        cmds.push_back(tvg::PathCommand::CubicTo);
        for (int i = 1; i < 4; ++i) pts.push_back({p[i].fX, p[i].fY});
        break;
      case SkPathVerb::kClose:
        cmds.push_back(tvg::PathCommand::Close);
        break;
    }
  }
  return !cmds.empty();
}

// Combines path A (ac, ap) with path B (bc, bp) and writes the result to `cmds`
// and `pts`. `op` is an SkPathOp value: 0 is A minus B, 1 is the intersection,
// 2 is the union and 3 is the exclusion (either path but not both). Returns
// false if the result is empty.
bool sk_op(int op, const tvg::PathCommand* ac, uint32_t acn,
           const tvg::Point* ap, const tvg::PathCommand* bc, uint32_t bcn,
           const tvg::Point* bp, std::vector<tvg::PathCommand>& cmds,
           std::vector<tvg::Point>& pts) {
  cmds.clear(), pts.clear();
  const SkPath b = sk_of(bc, bcn, bp);
  // Simplify B first so that overlapping pieces of B become one shape.
  const std::optional<SkPath> one = Simplify(b);
  std::optional<SkPath> built =
      Op(sk_of(ac, acn, ap), one ? *one : b, (SkPathOp)op);
  // Shapes are filled by winding rule, so convert a result that uses another
  // fill type.
  if (built && built->getFillType() != SkPathFillType::kWinding)
    built = AsWinding(*built);
  return built && !built->isEmpty() && tvg_of(*built, cmds, pts);
}

// Parses SVG path data such as "M0 0 L1 1 C... Z" into `cmds` and `pts`.
// Returns false if the data cannot be parsed or is empty.
bool sk_svg(const char* data, std::vector<tvg::PathCommand>& cmds,
            std::vector<tvg::Point>& pts) {
  cmds.clear(), pts.clear();
  const std::optional<SkPath> built = SkParsePath::FromSVGString(data);
  return built && !built->isEmpty() && tvg_of(*built, cmds, pts);
}

// Roughens a path with Skia's discrete path effect. The path is cut into pieces
// about `apart` long, and each end is moved by a random offset of up to `far`.
// `seed` makes the result repeatable. Returns false if the effect fails or the
// result is empty.
bool sk_rough(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
              const tvg::Point* pts, float apart, float far, uint32_t seed,
              std::vector<tvg::PathCommand>& outCmds,
              std::vector<tvg::Point>& outPts) {
  outCmds.clear(), outPts.clear();
  SkPathBuilder built;
  SkStrokeRec fill(SkStrokeRec::kFill_InitStyle);
  return SkDiscretePathEffect::Make(apart, far, seed)
             ->filterPath(&built, sk_of(cmds, cmdsCnt, pts), &fill) &&
         tvg_of(built.detach(), outCmds, outPts);
}

// Morphs path A (ac, ap) into path B (bc, bp), as Cavalry's Morph does. `t` is
// the progress from 0 for A to 1 for B. Each outline is sampled at 256 evenly
// spaced points with Skia's contour measure. Two closed outlines are made to
// run in the same direction, and B starts at the point nearest to the start of
// A. The points are then interpolated pairwise. An outline that exists in only
// one path is shown until t reaches 0.5. Returns false if the result is empty.
bool sk_morph(const tvg::PathCommand* ac, uint32_t acn, const tvg::Point* ap,
              const tvg::PathCommand* bc, uint32_t bcn, const tvg::Point* bp,
              float t, std::vector<tvg::PathCommand>& cmds,
              std::vector<tvg::Point>& pts) {
  constexpr int N = 256;
  cmds.clear(), pts.clear();
  const auto walk = [](const SkPath& path) {
    std::vector<std::pair<std::vector<SkPoint>, bool>> all;
    SkContourMeasureIter it(path, false);
    while (const sk_sp<SkContourMeasure> c = it.next()) {
      std::vector<SkPoint> p(N);
      for (int i = 0; i < N; ++i)
        (void)c->getPosTan(
            c->length() * (float)i / (float)(c->isClosed() ? N : N - 1), &p[i],
            nullptr);
      all.push_back({p, c->isClosed()});
    }
    return all;
  };
  const auto a = walk(sk_of(ac, acn, ap)), b = walk(sk_of(bc, bcn, bp));
  const auto put = [&](const std::vector<SkPoint>& p, bool closed) {
    for (int i = 0; i < N; ++i)
      cmds.push_back(i ? tvg::PathCommand::LineTo : tvg::PathCommand::MoveTo),
          pts.push_back({p[i].fX, p[i].fY});
    if (closed) cmds.push_back(tvg::PathCommand::Close);
  };
  const auto area = [](const std::vector<SkPoint>& p) {
    double s = 0;
    for (int i = 0; i < N; ++i)
      s += (double)p[i].fX * p[(i + 1) % N].fY -
           (double)p[(i + 1) % N].fX * p[i].fY;
    return s;
  };
  for (size_t k = 0; k < std::max(a.size(), b.size()); ++k) {
    if (k >= b.size()) {
      if (t < 0.5f) put(a[k].first, a[k].second);
      continue;
    }
    if (k >= a.size()) {
      if (t >= 0.5f) put(b[k].first, b[k].second);
      continue;
    }
    const std::vector<SkPoint>& p = a[k].first;
    std::vector<SkPoint> q = b[k].first;
    int shift = 0;
    // Two closed outlines: match the direction and the start point.
    if (a[k].second && b[k].second) {
      if ((area(p) < 0) != (area(q) < 0)) std::reverse(q.begin(), q.end());
      double best = 1e300;
      for (int s = 0; s < N; ++s) {
        double sum = 0;
        for (int i = 0; i < N && sum < best; i += 4) {
          const SkPoint e = p[i] - q[(i + s) % N];
          sum += (double)e.fX * e.fX + (double)e.fY * e.fY;
        }
        if (sum < best) best = sum, shift = s;
      }
    }
    std::vector<SkPoint> m(N);
    for (int i = 0; i < N; ++i) m[i] = p[i] + (q[(i + shift) % N] - p[i]) * t;
    put(m, a[k].second || b[k].second);
  }
  return !cmds.empty();
}

// Finds the two ends of each open outline after trimming. `from` and `to` are
// fractions of each outline's own length, as ThorVG trims each outline. Writes
// 8 numbers per outline to `out`: the position and direction of its end as x,
// y, dx, dy, followed by the position and direction of its start as x, y, dx,
// dy. The start direction points away from the outline. Closed outlines and
// outlines trimmed to nothing are skipped. Returns the number of outlines
// written.
int sk_ends(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
            const tvg::Point* pts, float from, float to,
            std::vector<float>& out) {
  out.clear();
  if (to < from) std::swap(from, to);
  from = std::clamp(from, 0.f, 1.f), to = std::clamp(to, 0.f, 1.f);
  SkContourMeasureIter it(sk_of(cmds, cmdsCnt, pts), false);
  while (const sk_sp<SkContourMeasure> c = it.next()) {
    if (c->isClosed() || to - from < 1e-4f) continue;
    SkPoint e, s;
    SkVector et, st;
    if (!c->getPosTan(c->length() * to, &e, &et) ||
        !c->getPosTan(c->length() * from, &s, &st))
      continue;
    out.insert(out.end(),
               {e.fX, e.fY, et.fX, et.fY, s.fX, s.fY, -st.fX, -st.fY});
  }
  return (int)out.size() / 8;
}

// Resamples a path into straight lines, as Cavalry's Resample Path does. Each
// outline is walked at `n` evenly spaced points with Skia's contour measure, so
// curves become polygons and every outline has the same number of points.
// Returns false if the result is empty.
bool sk_resample(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
                 const tvg::Point* pts, int n,
                 std::vector<tvg::PathCommand>& outCmds,
                 std::vector<tvg::Point>& outPts) {
  outCmds.clear(), outPts.clear();
  SkContourMeasureIter it(sk_of(cmds, cmdsCnt, pts), false);
  while (const sk_sp<SkContourMeasure> c = it.next()) {
    const int steps = c->isClosed() ? n : n - 1;
    for (int i = 0; i <= steps; ++i) {
      if (c->isClosed() && i == steps) break;
      SkPoint p;
      if (!c->getPosTan(c->length() * (float)i / (float)std::max(1, steps), &p,
                        nullptr))
        continue;
      outCmds.push_back(i ? tvg::PathCommand::LineTo
                          : tvg::PathCommand::MoveTo),
          outPts.push_back({p.fX, p.fY});
    }
    if (c->isClosed()) outCmds.push_back(tvg::PathCommand::Close);
  }
  return !outCmds.empty();
}

// Converts the part of each outline between `from` and `to` into short straight
// pieces and closes it with a straight line across. `from` and `to` are
// fractions of the outline length. On a closed outline, values outside 0 to 1
// wrap around. This is the filled area of a trimmed shape, which is how After
// Effects' Trim Paths and Skottie trim a fill. Returns false if the result is
// empty.
bool sk_trim(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
             const tvg::Point* pts, float from, float to,
             std::vector<tvg::PathCommand>& outCmds,
             std::vector<tvg::Point>& outPts) {
  outCmds.clear(), outPts.clear();
  SkContourMeasureIter it(sk_of(cmds, cmdsCnt, pts), false);
  while (const sk_sp<SkContourMeasure> c = it.next()) {
    if (to <= from) break;
    const int steps =
        std::clamp((int)(c->length() * (to - from) / 2.f), 8, 512);
    for (int i = 0; i <= steps; ++i) {
      const float at = from + (to - from) * (float)i / (float)steps;
      SkPoint p;
      if (!c->getPosTan(
              c->length() * (c->isClosed() ? at - std::floor(at)
                                           : std::clamp(at, 0.f, 1.f)),
              &p, nullptr))
        continue;
      outCmds.push_back(i ? tvg::PathCommand::LineTo
                          : tvg::PathCommand::MoveTo),
          outPts.push_back({p.fX, p.fY});
    }
    outCmds.push_back(tvg::PathCommand::Close);
  }
  return !outCmds.empty();
}

// Finds `n` places along a path, evenly spaced by length, as Cavalry's
// Duplicator does on a shape's outline. All outlines are treated as one path,
// one after another. On a closed path the last place does not coincide with the
// first. The places are shifted along the path by `from`, a fraction of the
// total length that wraps around on a closed path. Writes three numbers per
// place to `out`: x, y and the direction of the path there in radians. Returns
// the number of places.
int sk_along(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
             const tvg::Point* pts, int n, float from,
             std::vector<float>& out) {
  out.clear();
  std::vector<sk_sp<SkContourMeasure>> all;
  float total = 0.f;
  bool closed = true;
  SkContourMeasureIter it(sk_of(cmds, cmdsCnt, pts), false);
  while (sk_sp<SkContourMeasure> c = it.next())
    total += c->length(), closed = closed && c->isClosed(),
                          all.push_back(std::move(c));
  if (all.empty() || total <= 0.f || n < 1) return 0;
  for (int i = 0; i < n; ++i) {
    float at = (float)i / (float)(closed || n < 2 ? n : n - 1) + from;
    at = closed ? at - std::floor(at) : std::clamp(at, 0.f, 1.f);
    float d = at * total;
    for (const sk_sp<SkContourMeasure>& c : all) {
      if (d > c->length() && &c != &all.back()) {
        d -= c->length();
        continue;
      }
      SkPoint p;
      SkVector t;
      if (c->getPosTan(std::min(d, c->length()), &p, &t))
        out.insert(out.end(), {p.fX, p.fY, std::atan2(t.fY, t.fX)});
      break;
    }
  }
  return (int)out.size() / 3;
}

// Replaces a path with squares of side `cell`, as Cavalry's Voxelize does. A
// square is included when the middle of its grid cell lies inside the path. The
// path is scan-converted onto the grid with SkRegion, where a pixel is inside
// if its center is. The grid has at most 256 cells on a side, so `cell` is
// raised if needed. Returns false if the path or `cell` is empty.
bool sk_voxel(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
              const tvg::Point* pts, float cell,
              std::vector<tvg::PathCommand>& outCmds,
              std::vector<tvg::Point>& outPts) {
  outCmds.clear(), outPts.clear();
  const SkPath path = sk_of(cmds, cmdsCnt, pts);
  const SkRect box = path.getBounds();
  if (box.isEmpty() || cell <= 0.f) return false;
  cell = std::max(cell, std::max(box.width(), box.height()) / 256.f);
  const float x0 = std::floor(box.fLeft / cell) * cell,
              y0 = std::floor(box.fTop / cell) * cell;
  // Scale the path so that one grid cell is one pixel.
  const SkPath grid = path.makeTransform(
      SkMatrix::Translate(-x0, -y0).postScale(1.f / cell, 1.f / cell));
  SkRegion in;
  in.setPath(grid, SkRegion(SkIRect::MakeWH(
                       (int)std::ceil((box.fRight - x0) / cell) + 1,
                       (int)std::ceil((box.fBottom - y0) / cell) + 1)));
  for (SkRegion::Iterator it(in); !it.done(); it.next())
    for (int y = it.rect().fTop; y < it.rect().fBottom; ++y)
      for (int x = it.rect().fLeft; x < it.rect().fRight; ++x) {
        const float px = x0 + (float)x * cell, py = y0 + (float)y * cell;
        outCmds.insert(outCmds.end(),
                       {tvg::PathCommand::MoveTo, tvg::PathCommand::LineTo,
                        tvg::PathCommand::LineTo, tvg::PathCommand::LineTo,
                        tvg::PathCommand::Close});
        outPts.insert(outPts.end(), {{px, py},
                                     {px + cell, py},
                                     {px + cell, py + cell},
                                     {px, py + cell}});
      }
  return !outCmds.empty();
}

// Returns whether the point x, y lies inside the path, using Skia's contains
// with the winding rule. If `far` is not null, it receives the distance from
// the point to the outline in the path's own units. Curves are approximated by
// 16 straight pieces for this distance.
bool sk_inside(const tvg::PathCommand* cmds, uint32_t cmdsCnt,
               const tvg::Point* pts, float x, float y, float* far) {
  const SkPath path = sk_of(cmds, cmdsCnt, pts);
  const SkPoint at{x, y};
  float best = 1e30f;
  const auto seg = [&](SkPoint a, SkPoint b) {
    const SkVector ab = b - a, ap = at - a;
    const float l2 = ab.fX * ab.fX + ab.fY * ab.fY,
                u = l2 > 0.f ? std::clamp((ap.fX * ab.fX + ap.fY * ab.fY) / l2,
                                          0.f, 1.f)
                             : 0.f;
    best = std::min(best, SkPoint::Distance(at, a + ab * u));
  };
  SkPathIter it = path.iter();
  while (const std::optional<SkPathIter::Rec> r = it.next()) {
    const SkSpan<const SkPoint> p = r->fPoints;
    switch (r->fVerb) {
      case SkPathVerb::kLine:
      case SkPathVerb::kClose:
        seg(p[0], p[1]);
        break;
      case SkPathVerb::kQuad:
      case SkPathVerb::kConic:
      case SkPathVerb::kCubic: {
        const auto on = [&](float t) {
          const float u = 1.f - t;
          if (p.size() == 4)
            return p[0] * (u * u * u) + p[1] * (3.f * u * u * t) +
                   p[2] * (3.f * u * t * t) + p[3] * (t * t * t);
          return p[0] * (u * u) + p[1] * (2.f * u * t) + p[2] * (t * t);
        };
        for (int i = 0; i < 16; ++i)
          seg(on((float)i / 16.f), on((float)(i + 1) / 16.f));
        break;
      }
      default:
        break;
    }
  }
  if (far) *far = best;
  return path.contains(x, y);
}

}  // namespace motolii

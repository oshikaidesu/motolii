// skia_svg_edit.cpp: Reading and editing SVG path data like a pen tool, with
// Skia: the anchors and handles of a path, moving them, adding and removing
// points. Separate from skia_path_operations.cpp only to keep each file to one
// job; the same rules apply (Skia's headers stay in files like this one, and
// path_operations.h is all the rest of the engine sees). Built by skia.sh.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "include/core/SkPath.h"
#include "include/core/SkPathBuilder.h"
#include "include/core/SkString.h"
#include "include/utils/SkParsePath.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

// Writes the anchor points of the SVG path data to `xy` as x, y pairs. An
// anchor is the end point of each segment; handles are not included. Returns
// the number of anchors.
int sk_svg_anchors(const char* data, std::vector<float>& xy) {
  xy.clear();
  const std::optional<SkPath> built = SkParsePath::FromSVGString(data);
  if (!built) return 0;
  SkPathIter it = built->iter();
  while (const std::optional<SkPathIter::Rec> r = it.next())
    if (r->fVerb != SkPathVerb::kClose)
      xy.push_back(r->fPoints.back().fX), xy.push_back(r->fPoints.back().fY);
  return (int)xy.size() / 2;
}

// Describes the SVG path data for a pen tool that is about to add a point.
// Writes the first point to `fx`, `fy` and the number of segments, not counting
// moves and closes, to `stretches`. Returns how the path ends: 0 if it cannot
// be parsed or is empty, 1 for a move alone, 2 for a line, 3 for a curve and 4
// if it is closed.
int sk_svg_ends(const char* data, float& fx, float& fy, int& stretches) {
  fx = fy = 0.f, stretches = 0;
  const std::optional<SkPath> built = SkParsePath::FromSVGString(data);
  if (!built || built->isEmpty()) return 0;
  const SkPoint first = built->getPoint(0);
  fx = first.fX, fy = first.fY;
  int last = 1;
  SkPathIter it = built->iter();
  while (const std::optional<SkPathIter::Rec> r = it.next()) {
    if (r->fVerb == SkPathVerb::kMove) continue;
    if (r->fVerb != SkPathVerb::kClose) ++stretches;
    last = r->fVerb == SkPathVerb::kClose  ? 4
           : r->fVerb == SkPathVerb::kLine ? 2
                                           : 3;
  }
  return last;
}

// Moves the nth anchor of the SVG path data by dx, dy and writes the new path
// data to `out`. Any other anchor at the same place, such as the first and last
// points of a closed path, moves with it. The handles on both sides of a moved
// anchor move too, as in a pen tool. Returns false if `nth` is out of range.
bool sk_svg_move(const char* data, int nth, float dx, float dy,
                 std::string& out) {
  std::vector<float> xy;
  if (nth < 0 || nth >= sk_svg_anchors(data, xy)) return false;
  const SkPoint was{xy[2 * nth], xy[2 * nth + 1]}, by{dx, dy};
  const auto here = [&](SkPoint p) {
    return SkPoint::Distance(p, was) < 1e-4f;
  };
  SkPathBuilder b;
  // True on the segment after a moved anchor, whose first handle moves too.
  bool after = false;
  // The iterator reads from this path, so it must stay alive while iterating.
  const SkPath path = *SkParsePath::FromSVGString(data);
  SkPathIter it = path.iter();
  while (const std::optional<SkPathIter::Rec> r = it.next()) {
    std::vector<SkPoint> p(r->fPoints.begin(), r->fPoints.end());
    const bool moved = r->fVerb != SkPathVerb::kClose && here(p.back());
    if (after && p.size() > 2) p[1] += by;
    if (moved) {
      p.back() += by;
      if (r->fVerb == SkPathVerb::kCubic) p[2] += by;
    }
    after = moved;
    switch (r->fVerb) {
      case SkPathVerb::kMove:
        b.moveTo(p[0]);
        break;
      case SkPathVerb::kLine:
        b.lineTo(p[1]);
        break;
      case SkPathVerb::kQuad:
        b.quadTo(p[1], p[2]);
        break;
      case SkPathVerb::kConic:
        b.conicTo(p[1], p[2], r->conicWeight());
        break;
      case SkPathVerb::kCubic:
        b.cubicTo(p[1], p[2], p[3]);
        break;
      case SkPathVerb::kClose:
        b.close();
        break;
    }
  }
  out = SkParsePath::ToSVGString(b.detach()).c_str();
  return true;
}

// Writes the handles of the SVG path data to `xy` as x, y pairs. A handle is a
// control point of a curve, in path order. If `of` is not null, it receives for
// each handle the anchor that the handle belongs to, as x, y pairs. The first
// handle of a cubic belongs to the anchor the curve leaves, and the last one
// belongs to the anchor the curve arrives at. Returns the number of handles.
int sk_svg_handles(const char* data, std::vector<float>& xy,
                   std::vector<float>* of) {
  xy.clear();
  if (of) of->clear();
  const std::optional<SkPath> built = SkParsePath::FromSVGString(data);
  if (!built) return 0;
  SkPathIter it = built->iter();
  while (const std::optional<SkPathIter::Rec> r = it.next())
    if (r->fVerb == SkPathVerb::kCubic || r->fVerb == SkPathVerb::kQuad ||
        r->fVerb == SkPathVerb::kConic)
      for (size_t i = 1; i + 1 < r->fPoints.size(); ++i) {
        xy.push_back(r->fPoints[i].fX), xy.push_back(r->fPoints[i].fY);
        const SkPoint owner = i == 1 && r->fPoints.size() == 4
                                  ? r->fPoints.front()
                                  : r->fPoints.back();
        if (of) of->push_back(owner.fX), of->push_back(owner.fY);
      }
  return (int)xy.size() / 2;
}

// Moves the nth handle of the SVG path data by dx, dy and writes the new path
// data to `out`. If the handle and the handle on the other side of the same
// anchor lay on one straight line through it, within about ten degrees, the
// other handle is turned to stay opposite and keeps its length. This keeps a
// smooth point smooth, as a pen tool does. Returns false if `nth` is out of
// range.
bool sk_svg_move_handle(const char* data, int nth, float dx, float dy,
                        std::string& out) {
  std::vector<float> xy;
  if (nth < 0 || nth >= sk_svg_handles(data, xy)) return false;
  // The iterator reads from this path, so it must stay alive while iterating.
  const SkPath path = *SkParsePath::FromSVGString(data);
  struct Rec {
    SkPathVerb verb;
    std::vector<SkPoint> p;
    float w;
  };
  std::vector<Rec> all;
  SkPathIter it = path.iter();
  while (const std::optional<SkPathIter::Rec> r = it.next())
    all.push_back({r->fVerb,
                   std::vector<SkPoint>(r->fPoints.begin(), r->fPoints.end()),
                   r->fVerb == SkPathVerb::kConic ? r->conicWeight() : 1.f});
  const auto curved = [&](size_t v) {
    return all[v].verb == SkPathVerb::kCubic;
  };
  // The moved handle: hv is its segment and hp is the index of its point in
  // that segment.
  size_t hv = 0, hp = 0;
  for (size_t v = 0, k = 0; v < all.size(); ++v)
    if (all[v].verb == SkPathVerb::kCubic || all[v].verb == SkPathVerb::kQuad ||
        all[v].verb == SkPathVerb::kConic)
      for (size_t i = 1; i + 1 < all[v].p.size(); ++i, ++k)
        if ((int)k == nth) hv = v, hp = i;
  const SkPoint was = all[hv].p[hp];
  all[hv].p[hp] += SkPoint{dx, dy};
  // Find the handle on the other side of the anchor. It is the last handle of
  // the previous segment or the first handle of the next one, wrapping around
  // on a closed outline.
  if (curved(hv)) {
    size_t first = hv, last = hv;
    while (first > 0 && all[first].verb != SkPathVerb::kMove) --first;
    while (last + 1 < all.size() && all[last + 1].verb != SkPathVerb::kMove)
      ++last;
    while (last > first && all[last].verb == SkPathVerb::kClose) --last;
    const bool closed =
        last + 1 < all.size() && all[last + 1].verb == SkPathVerb::kClose;
    size_t ov = SIZE_MAX, op = 0;
    SkPoint at{};
    // The moved handle is the last of its curve: the anchor is where the curve
    // arrives, and the other handle is the first one of the next curve.
    if (hp == 2) {
      at = all[hv].p[3];
      size_t next =
          hv + 1 <= last
              ? hv + 1
              : (closed && SkPoint::Distance(at, all[first].p[0]) < 1e-4f
                     ? first + 1
                     : SIZE_MAX);
      if (next != SIZE_MAX && next <= last && curved(next)) ov = next, op = 1;
    } else {
      // The moved handle is the first of its curve: the anchor is where the
      // curve leaves, and the other handle is the last one of the previous
      // curve.
      at = all[hv].p[0];
      size_t before =
          hv - 1 > first
              ? hv - 1
              : (closed && SkPoint::Distance(all[last].p.back(), at) < 1e-4f
                     ? last
                     : SIZE_MAX);
      if (before != SIZE_MAX && before > first && curved(before))
        ov = before, op = 2;
    }
    if (ov != SIZE_MAX) {
      SkVector a = was - at, b = all[ov].p[op] - at;
      const float la = a.length(), lb = b.length();
      if (la > 1e-6f && lb > 1e-6f &&
          (a.fX * b.fX + a.fY * b.fY) / (la * lb) < -0.985f) {
        SkVector now = all[hv].p[hp] - at;
        if (now.length() > 1e-6f)
          all[ov].p[op] = at - now * (lb / now.length());
      }
    }
  }
  SkPathBuilder b;
  for (const Rec& r : all) switch (r.verb) {
      case SkPathVerb::kMove:
        b.moveTo(r.p[0]);
        break;
      case SkPathVerb::kLine:
        b.lineTo(r.p[1]);
        break;
      case SkPathVerb::kQuad:
        b.quadTo(r.p[1], r.p[2]);
        break;
      case SkPathVerb::kConic:
        b.conicTo(r.p[1], r.p[2], r.w);
        break;
      case SkPathVerb::kCubic:
        b.cubicTo(r.p[1], r.p[2], r.p[3]);
        break;
      case SkPathVerb::kClose:
        b.close();
        break;
    }
  out = SkParsePath::ToSVGString(b.detach()).c_str();
  return true;
}

// A path as editable nodes, for adding and removing points. Each node has an
// incoming handle, an anchor and an outgoing handle. For a line, both handles
// lie on the anchor. SkNodes holds one list of nodes per contour, with a flag
// that is true when the contour is closed. sk_nodes converts a Skia path to
// nodes and sk_path converts nodes back.
struct SkNode {
  SkPoint in, at, out;
};
using SkNodes = std::vector<std::pair<std::vector<SkNode>, bool>>;
static SkNodes sk_nodes(const SkPath& path) {
  SkNodes all;
  SkPathIter it = path.iter();
  while (const std::optional<SkPathIter::Rec> r = it.next()) {
    const SkSpan<const SkPoint> p = r->fPoints;
    if (r->fVerb == SkPathVerb::kMove) {
      all.push_back({{{p[0], p[0], p[0]}}, false});
      continue;
    }
    if (all.empty()) continue;
    std::vector<SkNode>& n = all.back().first;
    switch (r->fVerb) {
      case SkPathVerb::kLine:
        n.push_back({p[1], p[1], p[1]});
        break;
      // A quad or conic is converted to the cubic with the same shape.
      case SkPathVerb::kQuad:
      case SkPathVerb::kConic:
        n.back().out = p[0] + (p[1] - p[0]) * (2.f / 3.f),
        n.push_back({p[2] + (p[1] - p[2]) * (2.f / 3.f), p[2], p[2]});
        break;
      case SkPathVerb::kCubic:
        n.back().out = p[1], n.push_back({p[2], p[3], p[3]});
        break;
      case SkPathVerb::kClose:
        // When the last point equals the first, merge them into one node.
        if (n.size() > 1 &&
            SkPoint::Distance(n.back().at, n.front().at) < 1e-4f)
          n.front().in = n.back().in, n.pop_back();
        all.back().second = true;
        break;
      default:
        break;
    }
  }
  return all;
}
static SkPath sk_path(const SkNodes& all) {
  SkPathBuilder b;
  for (const auto& [n, closed] : all) {
    if (n.empty()) continue;
    b.moveTo(n[0].at);
    for (size_t i = 1; i < n.size(); ++i)
      b.cubicTo(n[i - 1].out, n[i].in, n[i].at);
    if (closed) b.cubicTo(n.back().out, n[0].in, n[0].at), b.close();
  }
  return b.detach();
}

// Applies a pen tool click at x, y to the SVG path data and writes the new data
// to `out`. If the click is within `reach` of an anchor, that anchor is
// removed. If it is within `reach` of the outline, a new anchor is added there
// and the curve is split at that place with de Casteljau's algorithm, which
// keeps the shape unchanged. Returns 1 if a point was removed, 2 if one was
// added and 0 if nothing changed.
int sk_svg_edit(const char* data, float x, float y, float reach,
                std::string& out) {
  const std::optional<SkPath> built = SkParsePath::FromSVGString(data);
  if (!built) return 0;
  SkNodes all = sk_nodes(*built);
  const SkPoint hand{x, y};
  for (auto& [n, closed] : all)
    for (size_t i = 0; i < n.size(); ++i)
      if (SkPoint::Distance(n[i].at, hand) < reach) {
        n.erase(n.begin() + (long)i);
        if (n.size() < 2) n.clear();
        out = SkParsePath::ToSVGString(sk_path(all)).c_str();
        return 1;
      }
  float best = reach, at = 0.f;
  int contour = -1;
  size_t seg = 0;
  // Returns the point at t on the cubic a, b, c, d.
  const auto on = [](SkPoint a, SkPoint b, SkPoint c, SkPoint d, float t) {
    const float u = 1.f - t;
    return a * (u * u * u) + b * (3.f * u * u * t) + c * (3.f * u * t * t) +
           d * (t * t * t);
  };
  for (size_t k = 0; k < all.size(); ++k) {
    const auto& [n, closed] = all[k];
    for (size_t i = 0; i + (closed ? 0 : 1) < n.size(); ++i) {
      const SkNode &a = n[i], &b = n[(i + 1) % n.size()];
      for (int s = 1; s < 128; ++s)
        if (const float t = (float)s / 128.f,
            far = SkPoint::Distance(on(a.at, a.out, b.in, b.at, t), hand);
            far < best)
          best = far, at = t, contour = (int)k, seg = i;
    }
  }
  if (contour < 0) return 0;
  std::vector<SkNode>& n = all[(size_t)contour].first;
  SkNode &a = n[seg], &b = n[(seg + 1) % n.size()];
  const auto mix = [&](SkPoint p, SkPoint q) { return p + (q - p) * at; };
  const SkPoint ab = mix(a.at, a.out), bc = mix(a.out, b.in),
                cd = mix(b.in, b.at), abc = mix(ab, bc), bcd = mix(bc, cd),
                mid = mix(abc, bcd);
  a.out = ab, b.in = cd;
  n.insert(n.begin() + (long)seg + 1, SkNode{abc, mid, bcd});
  out = SkParsePath::ToSVGString(sk_path(all)).c_str();
  return 2;
}

}  // namespace motolii

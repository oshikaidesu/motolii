// thorvg_path_operators.cpp: Path operators and stroke tessellation for 2D shapes.
//
// tvg_bend applies the After Effects path operators (round corners, pucker & bloat, zig zag,
// offset paths) using the modifiers of ThorVG's Lottie reader. They run in that order, with the
// offset last, which is how ThorVG chains them.
//
// tvg_edge turns the outline of a shape into triangles the way ThorVG's WebGPU engine strokes it.
//
// This file is separate from the rest of the canvas code because ThorVG's internal headers
// declare many names that would clash with ours. Only the two functions declared in
// path_operations.h are visible to the rest of the engine.
#include "stage/canvas/path_operations.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <utility>
#include <vector>

#include "tvgLottieModifier.h"
#include "tvgGpuCommon.h"
#include "tvgWgTessellator.h"

// Appends the path to `into` using cubic curves only, as an After Effects path does. A line
// becomes a straight cubic and a closed path ends back at its start. These are the only forms
// the operators understand.
//
// `sharp` places the handles of a line on its end points, as After Effects writes them. Round
// corners look for that, and pucker & bloat bend from it. When false, the handles are spaced
// evenly along the line, which a zig zag needs for its ridges.
//
// `fine` is the longest piece allowed. Each line and curve is cut into pieces no longer than
// `fine`, so that an operator that bends the path later has points along its whole length. A
// `fine` of 0 leaves everything whole. A negative `fine` cuts only the curves and keeps straight
// lines whole, because nothing bends them and a curve only needs to look round.
static void curves(RenderPath& into, const PathCommand* cmds, uint32_t cmdsCnt, const Point* pts, bool sharp, float fine) {
    Point start{}, at{};
    const bool linesWhole = fine < 0.f;
    fine = std::fabs(fine);
    // Number of pieces a stretch of length `along` is cut into. The count is limited to 1024 and
    // is 1 when the length is not finite. Without these limits, a shape moved very far away or a
    // `fine` near zero once asked for more pieces than memory could hold.
    const auto cut = [&](float along) { return fine > 0.f && std::isfinite(along) ? (int)std::min(1024.f, std::max(1.f, std::ceil(along / fine))) : 1; };
    const auto line = [&](const Point& to) {
        const Point from = at;
        const int pieces = linesWhole ? 1 : cut(length(to - from));
        for (int k = 1; k <= pieces; ++k) {
            const Point a = from + (to - from) * ((float)(k - 1) / (float)pieces), b = from + (to - from) * ((float)k / (float)pieces);
            if (sharp) into.cubicTo(a, b, b);
            else into.cubicTo(a + (b - a) * (1.f / 3.f), a + (b - a) * (2.f / 3.f), b);
        }
    };
    const auto curve = [&](const Point& c1, const Point& c2, const Point& to) {
        const Point c0 = at;
        // When nothing bends the curve later, the piece count follows Wang's formula for the
        // flatness of a cubic, with a tolerance of 1/32 of `fine`. A nearly straight curve stays
        // whole and a round one is cut enough to look round. When something bends the curve
        // later, the count follows its length so that the bending operator has points along it.
        const Point dd1 = c0 - c1 * 2.f + c2, dd2 = c1 - c2 * 2.f + to;
        const float bendsBy = std::max(length(dd1), length(dd2));
        const int pieces = linesWhole ? (int)std::clamp(std::ceil(std::sqrt(0.75f * bendsBy / (fine / 32.f))), 1.f, 1024.f) : cut(length(c1 - c0) + length(c2 - c1) + length(to - c2));
        if (pieces == 1) return into.cubicTo(c1, c2, to);
        const auto on = [&](float t) {   // Returns the point at t and the tangent there.
            const float u = 1.f - t;
            return std::pair<Point, Point>{c0 * (u * u * u) + c1 * (3.f * u * u * t) + c2 * (3.f * u * t * t) + to * (t * t * t),
                                           (c1 - c0) * (3.f * u * u) + (c2 - c1) * (6.f * u * t) + (to - c2) * (3.f * t * t)};
        };
        for (int k = 1; k <= pieces; ++k) {
            const float t0 = (float)(k - 1) / (float)pieces, t1 = (float)k / (float)pieces, d = (t1 - t0) / 3.f;
            const auto [a, da] = on(t0);
            const auto [b, db] = on(t1);
            into.cubicTo(a + da * d, b - db * d, b);
        }
    };
    for (uint32_t c = 0, p = 0; c < cmdsCnt; ++c) switch (cmds[c]) {
        case PathCommand::MoveTo: into.moveTo(start = at = pts[p++]); break;
        case PathCommand::LineTo: line(pts[p]), at = pts[p++]; break;
        case PathCommand::CubicTo: curve(pts[p], pts[p + 1], pts[p + 2]), at = pts[p + 2], p += 3; break;
        case PathCommand::Close: if (!tvg::zero(at - start)) line(start); into.close(), at = start; break;
    }
}

// Returns whether every point is a finite number. A point that is not finite, which can happen
// when a shape is pushed far past its parameters, makes ThorVG's own measuring loop forever, so
// such a shape is not drawn.
static bool numbers(const Point* p, uint32_t n) {
    for (uint32_t i = 0; i < n; ++i) if (!std::isfinite(p[i].x) || !std::isfinite(p[i].y)) return false;
    return true;
}

// Replaces the contents of `shape` with the given path after applying the operators.
//
// `round` is the corner radius, `bloat` the pucker & bloat amount, `zigzag` the zig zag size
// with `ridges` ridges per segment (`smooth` selects smooth rather than corner points), and
// `offset` the offset distance. An operator whose amount is 0 is skipped. A negative `fine` cuts
// only curves and keeps lines whole; see curves(). If any input is not finite, the shape is left
// empty.
void tvg_bend(tvg::Shape* shape, const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, uint32_t ptsCnt,
              float round, float bloat, float zigzag, int ridges, bool smooth, float offset, float fine) {
    shape->reset();
    if (!numbers(pts, ptsCnt) || !std::isfinite(round + bloat + zigzag + offset + fine)) return;
    LottieModifier* chain = nullptr;
    // Chains modifiers the way ThorVG's builder does. The modifier added last runs first, so the
    // offset, which is added first, runs last.
    const auto on = [&](LottieModifier* m) { m->next = chain, chain = m; };
    if (offset != 0.f) on(new LottieOffsetModifier(offset));
    if (zigzag != 0.f) on(new LottieZigZagModifier(zigzag, ridges, smooth ? LottieZigZagModifier::Smooth : LottieZigZagModifier::Corner));
    if (bloat != 0.f) on(new LottiePuckerBloatModifier(bloat));
    if (round > 0.f) on(new LottieRoundnessModifier(round));
    RenderPath in, out, cut;
    curves(in, cmds, cmdsCnt, pts, round > 0.f || bloat != 0.f, 0.f);
    const bool any = chain;
    if (chain) chain->path(in, out, nullptr);
    delete chain;
    const RenderPath& bent = any ? out : in;
    if (!numbers(bent.pts.data, bent.pts.count)) return;
    // Cut after bending, so the operators see whole lines. The path is cut into at most 20000
    // pieces. A long zig zag cut finely once produced more triangles than the GPU staging buffer
    // could hold.
    float along = 0.f;
    for (uint32_t i = 1; i < bent.pts.count; ++i) along += length(bent.pts[i] - bent.pts[i - 1]);
    if (fine != 0.f) curves(cut, bent.cmds.data, bent.cmds.count, bent.pts.data, false, std::copysign(std::max(std::fabs(fine), along / 20000.f), fine));
    const RenderPath& to = fine != 0.f ? cut : bent;
    shape->appendPath(to.cmds.data, to.cmds.count, to.pts.data, to.pts.count);
}

// Converts the outline of a path into triangles, using the trim, dash and stroker code of
// ThorVG's WebGPU engine. No tessellator cuts the result.
//
// `width` is the stroke width in points. `cap` and `join` are ThorVG's StrokeCap and
// StrokeJoin values. `dash` is the length of each dash and of each gap; 0 means no dashing, and
// `dashFrom` is where the pattern starts. `from` and `to` select the part of the path's length
// to stroke, as After Effects trim paths does; as in ThorVG's trim, values past 1 wrap around.
//
// Writes vertex positions to `xy` as x, y pairs and triangle indices to `idx`. Both are empty
// if an input is not finite or the trim leaves nothing.
void tvg_edge(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, uint32_t ptsCnt, float width, int cap, int join, float dash, float dashFrom,
              float from, float to, std::vector<float>& xy, std::vector<uint32_t>& idx) {
    xy.clear(), idx.clear();
    if (!numbers(pts, ptsCnt) || !std::isfinite(width + dash + dashFrom + from + to)) return;
    RenderShape rs;
    for (uint32_t i = 0; i < cmdsCnt; ++i) rs.path.cmds.push(cmds[i]);
    for (uint32_t i = 0; i < ptsCnt; ++i) rs.path.pts.push(pts[i]);
    rs.stroke = new RenderStroke;
    rs.stroke->width = width, rs.stroke->cap = (StrokeCap)cap, rs.stroke->join = (StrokeJoin)join;
    rs.stroke->trim.begin = from, rs.stroke->trim.end = to;
    if (dash > 0.f) {
        rs.stroke->dash.pattern = tvg::malloc<float>(2 * sizeof(float));
        rs.stroke->dash.pattern[0] = rs.stroke->dash.pattern[1] = dash;
        rs.stroke->dash.count = 2, rs.stroke->dash.offset = dashFrom, rs.stroke->dash.length = 2.f * dash;
    }
    RenderPath stroked;
    const RenderPath* along = &rs.path;
    if (gpuStrokeDash(rs, stroked, nullptr)) along = &stroked;
    else if (rs.trimpath()) {
        if (!rs.stroke->trim.trim(rs.path, stroked)) return;
        along = &stroked;
    }
    WgMesh mesh;
    WgStroker stroker(&mesh, width, (StrokeCap)cap, (StrokeJoin)join);
    stroker.run(*along);
    for (uint32_t i = 0; i < mesh.vbuffer.count; ++i) xy.push_back(mesh.vbuffer[i].x), xy.push_back(mesh.vbuffer[i].y);
    for (uint32_t i = 0; i < mesh.ibuffer.count; ++i) idx.push_back(mesh.ibuffer[i]);
}

// Flat shapes: the path of each named form (rect, star, wave, SVG path data...)
// and the canvas that fills and strokes it with ThorVG.

#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

void flat_path(Canvas2D* d, tvg::Shape* shape, const char* form, int w, int h,
               float in, int points, float inner, float round, float fine) {
  const float cx = 0.5f * (float)w, cy = 0.5f * (float)h, rx = cx - in,
              ry = cy - in;
  // Line width of a wave or spiral: the stroke width, or a fraction of the
  // height.
  const float thick = in > 0.f ? 2.f * in : 0.08f * (float)h;
  // SVG path data given by the user. The coordinates are in units of the height
  // from the center, y pointing down as in SVG. The path is parsed by Skia.
  if (form[0] == 'M' || form[0] == 'm') {
    std::vector<tvg::PathCommand> c;
    std::vector<tvg::Point> p;
    if (sk_svg(form, c, p)) {
      for (tvg::Point& at : p)
        at = {cx + at.x * (float)h, cy + at.y * (float)h};
      shape->appendPath(c.data(), (uint32_t)c.size(), p.data(),
                        (uint32_t)p.size());
    }
  } else if (!strcmp(form, "circle"))
    shape->appendCircle(cx, cy, rx, ry);
  // A line waving across the shape: `points` cycles along its width, with an
  // amplitude of `inner` as a fraction of the half height.
  else if (!strcmp(form, "wave")) {
    const int cycles = std::clamp(points, 1, 100), n = 48 * cycles;
    const float amp = (cy - thick) * std::clamp(inner, 0.f, 1.f);
    for (int k = 0; k <= n; ++k) {
      const float x = thick + ((float)w - 2.f * thick) * (float)k / (float)n,
                  y = cy +
                      amp * std::sin(TAU * (float)cycles * (float)k / (float)n);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
  }
  // A line winding out from the center as in Cavalry's spiral: `points` turns,
  // starting at `inner` of the way out.
  else if (!strcmp(form, "spiral")) {
    const float turns = (float)std::clamp(points, 1, 50),
                from = std::clamp(inner, 0.f, 0.95f);
    const int n = (int)(96.f * turns);
    for (int k = 0; k <= n; ++k) {
      const float u = (float)k / (float)n, a = -0.25f * TAU + TAU * turns * u,
                  r = from + (1.f - from) * u;
      const float x = cx + (rx - thick) * r * std::cos(a),
                  y = cy + (ry - thick) * r * std::sin(a);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
  }
  // Ring: the hole is `inner` of the way out. Arc: `points` degrees of it,
  // `inner` thick, clockwise from straight up.
  else if (!strcmp(form, "ring") || !strcmp(form, "arc")) {
    const bool arc = !strcmp(form, "arc");
    const float hole = arc ? 1.f - std::clamp(inner, 0.02f, 1.f)
                           : std::clamp(inner, 0.f, 0.98f),
                sweep =
                    arc ? TAU * std::clamp((float)points, 1.f, 360.f) / 360.f
                        : TAU;
    const int n = std::max(8, (int)(96.f * sweep / TAU));
    // Go around the outside, then back around the inside. The hole is a
    // separate contour in the opposite direction.
    for (int k = 0; k <= n; ++k) {
      const float a = -0.25f * TAU + sweep * (float)k / (float)n;
      k ? shape->lineTo(cx + rx * std::cos(a), cy + ry * std::sin(a))
        : shape->moveTo(cx + rx * std::cos(a), cy + ry * std::sin(a));
    }
    if (!arc) shape->close();
    if (hole > 0.f) {
      for (int k = n; k >= 0; --k) {
        const float a = -0.25f * TAU + sweep * (float)k / (float)n;
        (k == n && !arc) ? shape->moveTo(cx + rx * hole * std::cos(a),
                                         cy + ry * hole * std::sin(a))
                         : shape->lineTo(cx + rx * hole * std::cos(a),
                                         cy + ry * hole * std::sin(a));
      }
    }
    shape->close();
  }
  // Arrow pointing right: the shaft is `inner` of the height thick and the head
  // is a third of the length.
  else if (!strcmp(form, "arrow")) {
    const float shaft = 0.5f * ry * std::clamp(inner, 0.05f, 1.f),
                head = (float)w - in - std::min(2.f * rx / 3.f, 1.2f * ry);
    const float pts[][2] = {
        {in, cy - shaft},    {head, cy - shaft},    {head, in},
        {(float)w - in, cy}, {head, (float)h - in}, {head, cy + shaft},
        {in, cy + shaft}};
    for (int k = 0; k < 7; ++k)
      k ? shape->lineTo(pts[k][0], pts[k][1])
        : shape->moveTo(pts[k][0], pts[k][1]);
    shape->close();
  }
  // A rect with its corners cut straight, as Cavalry's rectangle with chamfer.
  // Each corner loses `inner` of the shorter half side.
  else if (!strcmp(form, "chamfer")) {
    const float c = std::clamp(inner, 0.f, 1.f) * std::min(rx, ry), x0 = in,
                y0 = in, x1 = (float)w - in, y1 = (float)h - in;
    const float pts[][2] = {{x0 + c, y0}, {x1 - c, y0}, {x1, y0 + c},
                            {x1, y1 - c}, {x1 - c, y1}, {x0 + c, y1},
                            {x0, y1 - c}, {x0, y0 + c}};
    for (int k = 0; k < 8; ++k)
      k ? shape->lineTo(pts[k][0], pts[k][1])
        : shape->moveTo(pts[k][0], pts[k][1]);
    shape->close();
  }
  // A superellipse |x|^p + |y|^p = 1, where p is `points`. 2 is an ellipse and
  // a higher p is squarer.
  else if (!strcmp(form, "squircle")) {
    const float p = std::clamp((float)points, 2.f, 40.f);
    for (int k = 0; k < 128; ++k) {
      const float a = TAU * (float)k / 128.f, c = std::cos(a), sn = std::sin(a);
      const float x = cx +
                      rx * std::copysign(std::pow(std::fabs(c), 2.f / p), c),
                  y = cy +
                      ry * std::copysign(std::pow(std::fabs(sn), 2.f / p), sn);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
    shape->close();
  }
  // A cogwheel with `points` teeth, each `inner` of the radius deep and flat on
  // top.
  else if (!strcmp(form, "cog")) {
    const int teeth = std::clamp(points, 3, 100), n = 4 * teeth;
    const float deep = 1.f - std::clamp(inner, 0.02f, 0.9f);
    // Each tooth has four corners: rising, top, falling, bottom.
    for (int k = 0; k < n; ++k) {
      const float a0 = -0.25f * TAU + TAU * (float)k / (float)n,
                  r = (k % 4 == 1 || k % 4 == 2) ? 1.f : deep;
      k ? shape->lineTo(cx + rx * r * std::cos(a0), cy + ry * r * std::sin(a0))
        : shape->moveTo(cx + rx * r * std::cos(a0), cy + ry * r * std::sin(a0));
    }
    shape->close();
  } else if (!strcmp(form, "polygon") || !strcmp(form, "star")) {
    const bool star = !strcmp(form, "star");
    const int n = std::clamp(points, 3, 100) * (star ? 2 : 1);
    for (int k = 0; k < n; ++k) {
      // The first point is straight up.
      const float a = -0.5f * TAU / 2.f + TAU * (float)k / (float)n,
                  r = star && (k & 1) ? std::clamp(inner, 0.01f, 1.f) : 1.f;
      k ? shape->lineTo(cx + rx * r * std::cos(a), cy + ry * r * std::sin(a))
        : shape->moveTo(cx + rx * r * std::cos(a), cy + ry * r * std::sin(a));
    }
    shape->close();
  } else {
    // Anything else is a rectangle. The line form rounds its ends completely.
    const float side = std::min((float)w, (float)h) - 2.f * in,
                corner = !strcmp(form, "line") ? 0.5f * side : 0.f;
    shape->appendRect(in, in, (float)w - 2.f * in, (float)h - 2.f * in, corner,
                      corner);
  }
  const tvg::PathCommand* cmds;
  const tvg::Point* pts;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
  shape->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
  d->plain.assign(cmds, cmds + cmdsCnt), d->plainAt.assign(pts, pts + ptsCnt);
  d->plainHigh = (float)h,
  d->plainSide = std::min((float)w, (float)h) - 2.f * in;
  d->fine = fine;
  // Round the corners and cut the path into pieces. Remember the rounding that
  // was used.
  if ((round > 0.f && strcmp(form, "line")) || d->fine != 0.f)
    tvg_bend(shape, d->plain.data(), cmdsCnt, d->plainAt.data(), ptsCnt,
             strcmp(form, "line") ? std::clamp(round, 0.f, 0.5f) * d->plainSide
                                  : 0.f,
             0.f, 0.f, 0, false, 0.f, d->fine),
        d->bent[0] = round;
}

Canvas2D* flat(Stage& s, const char* form, float wide, const mat4f& place,
               float high, float3 colour, const char* lay, float4 edge,
               const Canvas2DFx& fx, int points, float inner, float round) {
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        // Resolution: half the stage's longer side. A long thin bar gets less
        // height so that its length stays within 4096 points.
        const float tall = std::min(0.5f * (float)std::max(s.w, s.h),
                                    4096.f / std::max(wide, 1e-3f));
        *h = std::max(2, 2 * (int)std::ceil(0.5f * tall));
        *w = std::max(2, 2 * (int)std::ceil(0.5f * tall * wide));
        // Half the stroke width. The path is inset by it so that all of the
        // stroke is visible. It is a whole number of points so that corners
        // land on whole points, because ThorVG's rounded corners treat a side
        // as straight only when it is exactly so (tvgLottieModifier.cpp,
        // _colinear).
        const float in =
            std::round(0.5f * std::min(edge.w * (float)*h,
                                       0.5f * (float)std::min(*w, *h)));
        // Line width of a wave or spiral: the stroke width, or a fraction of
        // the height.
        const float thick = in > 0.f ? 2.f * in : 0.08f * (float)*h;
        tvg::Shape* shape = d->shape = tvg::Shape::gen();
        flat_path(d, shape, form, *w, *h, in, points, inner, round, 0.f);
        shape->fill(byte_of(colour.x), byte_of(colour.y), byte_of(colour.z),
                    strcmp(form, "null") && !fx.hollow ? 255 : 0);
        if (fx.ramp.size() > 1 && strcmp(form, "null"))
          shape->fill(ramp_of(fx.ramp, (float)*w, (float)*h, fx.radial,
                              fx.rampAngle, fx.rampScale, fx.spread, fx.rampAt,
                              fx.rampBlend));
        if (in > 0.f)
          shape->strokeWidth(2.f * in),
              shape->strokeFill(byte_of(edge.x), byte_of(edge.y),
                                byte_of(edge.z));
        // Wave and spiral show only their line, in the edge color or else the
        // fill color, with round ends.
        if (!strcmp(form, "wave") || !strcmp(form, "spiral")) {
          const float3 ink = in > 0.f ? float3{edge.x, edge.y, edge.z} : colour;
          shape->fill(0, 0, 0, 0);
          shape->strokeWidth(thick),
              shape->strokeFill(byte_of(ink.x), byte_of(ink.y), byte_of(ink.z));
          shape->strokeCap(tvg::StrokeCap::Round);
        }
        if (fx.cap >= 0) shape->strokeCap((tvg::StrokeCap)fx.cap);
        if (fx.join >= 0) shape->strokeJoin((tvg::StrokeJoin)fx.join);
        // Dashes and gaps are equally long, as fractions of the height.
        if (fx.dash > 0.f) {
          const float gap[2] = {fx.dash * (float)*h, fx.dash * (float)*h};
          shape->strokeDash(gap, 2, fx.dashFrom * (float)*h);
        }
        // Fill with an image. It covers the shape and is visible only where the
        // shape is filled, using ThorVG's alpha mask, as a ramp does on letters
        // in type. The edge is drawn over it.
        if (!fx.media.empty() && strcmp(form, "null") && !fx.hollow) {
          tvg::Picture* pic = tvg::Picture::gen();
          float pw = 0.f, ph = 0.f;
          if (pic->load(fx.media.c_str()) == tvg::Result::Success &&
              pic->size(&pw, &ph) == tvg::Result::Success && pw > 0.f &&
              ph > 0.f) {
            // Cover the shape and keep the middle: crop instead of stretching.
            const float k = std::max((float)*w / pw, (float)*h / ph);
            pic->size(pw * k, ph * k);
            pic->translate(0.5f * ((float)*w - pw * k),
                           0.5f * ((float)*h - ph * k));
            tvg::Shape* cut = static_cast<tvg::Shape*>(shape->duplicate());
            cut->strokeWidth(0.f), cut->fill(255, 255, 255, 255);
            pic->mask(cut, tvg::MaskMethod::Alpha);
            // The shape's own fill is cleared because the image is its fill.
            // The edge stays over it.
            shape->fill(0, 0, 0, 0);
            tvg::Scene* both = tvg::Scene::gen();
            both->add(pic), both->add(shape);
            return both;
          }
          tvg::Paint::rel(pic);
        }
        return shape;
      },
      place, high, float3{-1.f}, true, lay, fx);
}

}  // namespace motolii

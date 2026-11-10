// Color ramps for ThorVG gradients: the blend modes between two stops (OKLab,
// HSV, constant) and the gradient that carries the stops.

#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <vector>

#include "stage/canvas/canvas_renderables.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;

namespace {

// Converts an sRGB component to linear light.
float ramp_lin(float c) {
  return c <= 0.04045f ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f);
}

// Converts a linear-light component to sRGB.
float ramp_gam(float c) {
  return c <= 0.0031308f ? 12.92f * c
                         : 1.055f * std::pow(c, 1.f / 2.4f) - 0.055f;
}

// Converts an sRGB color to OKLab.
float3 ramp_oklab(float3 c) {
  const float r = ramp_lin(c.x), g = ramp_lin(c.y), b = ramp_lin(c.z);
  const float l = std::cbrt(0.4122214708f * r + 0.5363325363f * g +
                            0.0514459929f * b),
              m = std::cbrt(0.2119034982f * r + 0.6806995451f * g +
                            0.1073969566f * b),
              s = std::cbrt(0.0883024619f * r + 0.2817188376f * g +
                            0.6299787005f * b);
  return {0.2104542553f * l + 0.7936177850f * m - 0.0040720468f * s,
          1.9779984951f * l - 2.4285922050f * m + 0.4505937099f * s,
          0.0259040371f * l + 0.7827717662f * m - 0.8086757660f * s};
}

// Converts an OKLab color to sRGB, clamped to [0, 1].
float3 ramp_srgb(float3 o) {
  const float l = o.x + 0.3963377774f * o.y + 0.2158037573f * o.z,
              m = o.x - 0.1055613458f * o.y - 0.0638541728f * o.z,
              s = o.x - 0.0894841775f * o.y - 1.2914855480f * o.z;
  const float L = l * l * l, M = m * m * m, S = s * s * s;
  return {
      std::clamp(
          ramp_gam(4.0767416621f * L - 3.3077115913f * M + 0.2309699292f * S),
          0.f, 1.f),
      std::clamp(
          ramp_gam(-1.2684380046f * L + 2.6097574011f * M - 0.3413193965f * S),
          0.f, 1.f),
      std::clamp(
          ramp_gam(-0.0041960863f * L - 0.7034186147f * M + 1.7076147010f * S),
          0.f, 1.f)};
}

// Converts an RGB color to HSV: hue in degrees, saturation and value in [0, 1].
float3 ramp_hsv(float3 c) {
  const float mx = std::max({c.x, c.y, c.z}), mn = std::min({c.x, c.y, c.z}),
              d = mx - mn;
  float h = 0.f;
  if (d > 0.f)
    h = mx == c.x   ? std::fmod((c.y - c.z) / d, 6.f)
        : mx == c.y ? (c.z - c.x) / d + 2.f
                    : (c.x - c.y) / d + 4.f;
  return {std::fmod(h * 60.f + 360.f, 360.f), mx > 0.f ? d / mx : 0.f, mx};
}

// Converts an HSV color, with hue in degrees, to RGB.
float3 ramp_rgb(float3 h) {
  const float c = h.z * h.y,
              x = c * (1.f - std::fabs(std::fmod(h.x / 60.f, 2.f) - 1.f)),
              m = h.z - c;
  const int k = (int)(h.x / 60.f) % 6;
  const float3 p = k == 0   ? float3{c, x, 0}
                   : k == 1 ? float3{x, c, 0}
                   : k == 2 ? float3{0, c, x}
                   : k == 3 ? float3{0, x, c}
                   : k == 4 ? float3{x, 0, c}
                            : float3{c, 0, x};
  return p + m;
}

// Expands `ramp` (colors) and `at` (stop positions) in place for blend modes 1
// to 3. If `at` does not match `ramp`, stops are spaced evenly. Does nothing
// for mode 0 or fewer than two stops.
void ramp_blend(std::vector<float4>& ramp, std::vector<float>& at, int blend) {
  if (blend <= 0 || ramp.size() < 2) return;
  std::vector<float> pos = at.size() == ramp.size() ? at : std::vector<float>();
  if (pos.empty())
    for (size_t i = 0; i < ramp.size(); ++i)
      pos.push_back((float)i / (float)(ramp.size() - 1));
  std::vector<float4> out;
  std::vector<float> outAt;
  // Number of steps each pair of stops is split into.
  constexpr int between = 8;
  for (size_t i = 0; i + 1 < ramp.size(); ++i) {
    const float4 a = ramp[i], b = ramp[i + 1];
    // Hold the color until the next stop, which begins a hair later, because
    // ThorVG keeps only one of two stops at the same position.
    if (blend == 3) {
      out.push_back(a), outAt.push_back(pos[i]), out.push_back(a),
          outAt.push_back(std::max(pos[i], pos[i + 1] - 1e-4f));
      continue;
    }
    for (int k = 0; k < between; ++k) {
      const float t = (float)k / between;
      float3 c;
      if (blend == 1) {
        c = ramp_srgb(ramp_oklab(a.xyz) * (1.f - t) + ramp_oklab(b.xyz) * t);
      } else {
        float3 p = ramp_hsv(a.xyz), q = ramp_hsv(b.xyz);
        float dh = q.x - p.x;
        // Take the shorter way around the hue circle.
        if (dh > 180.f)
          dh -= 360.f;
        else if (dh < -180.f)
          dh += 360.f;
        c = ramp_rgb({std::fmod(p.x + dh * t + 360.f, 360.f),
                      p.y + (q.y - p.y) * t, p.z + (q.z - p.z) * t});
      }
      out.push_back({c, a.w + (b.w - a.w) * t}),
          outAt.push_back(pos[i] + (pos[i + 1] - pos[i]) * t);
    }
  }
  out.push_back(ramp.back()), outAt.push_back(pos.back());
  ramp = out, at = outAt;
}

}  // namespace

tvg::Fill* ramp_of(const std::vector<float4>& given, float w, float h,
                   bool radial, float angle, float scale, int spread,
                   const std::vector<float>& givenAt, int blend) {
  std::vector<float4> ramp = given;
  std::vector<float> at = givenAt;
  ramp_blend(ramp, at, blend);
  tvg::Fill* g = nullptr;
  const float cx = 0.5f * w, cy = 0.5f * h, k = std::max(scale, 0.01f);
  // From the center out to the corners.
  if (radial) {
    tvg::RadialGradient* r = tvg::RadialGradient::gen();
    const float reach = 0.5f * std::hypot(w, h) * k;
    r->radial(cx, cy, reach, cx, cy, 0.f);
    g = r;
    // Across the area in the direction of `angle`, as far as the box reaches
    // that way.
  } else {
    tvg::LinearGradient* l = tvg::LinearGradient::gen();
    const float a = angle * (float)TAU / 360.f, dx = std::sin(a),
                dy = std::cos(a),
                reach =
                    (0.5f * std::fabs(w * dx) + 0.5f * std::fabs(h * dy)) * k;
    l->linear(cx - dx * reach, cy - dy * reach, cx + dx * reach,
              cy + dy * reach);
    g = l;
  }
  g->spread((tvg::FillSpread)std::clamp(spread, 0, 2));
  std::vector<tvg::Fill::ColorStop> stops;
  for (size_t i = 0; i < ramp.size(); ++i)
    // The w component of a color is its alpha, written as eight bits.
    stops.push_back(
        {at.size() == ramp.size() ? at[i] : (float)i / (float)(ramp.size() - 1),
         byte_of(ramp[i].x), byte_of(ramp[i].y), byte_of(ramp[i].z),
         byte_of(ramp[i].w)});
  g->colorStops(stops.data(), (uint32_t)stops.size());
  return g;
}

}  // namespace motolii

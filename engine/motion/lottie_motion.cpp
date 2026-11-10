#include "motion/lottie_motion.h"

#include <cmath>

namespace motolii {

namespace {

// Converts a flat 2D matrix to a 4x4 matrix in the shared 3D world. The z scale
// is the geometric mean of the x and y scales, so a cube stays a cube.
filament::math::mat4f motion_deep(const tvg::Matrix& f) {
  using namespace filament::math;
  return mat4f(float4{f.e11, f.e21, 0.f, 0.f}, float4{f.e12, f.e22, 0.f, 0.f},
               float4{0.f, 0.f,
                      std::sqrt(std::fabs(f.e11 * f.e22 - f.e12 * f.e21)), 0.f},
               float4{f.e13, f.e23, 0.f, 1.f});
}

}  // namespace

bool motion_open(Motion& m, const char* lottie) {
  // Zero threads: each time is computed on request, on the calling thread.
  static const bool started = tvg::Initializer::init(0) == tvg::Result::Success;
  if (!started) return false;
  m.film = tvg::LottieAnimation::gen();
  m.image = m.film->picture();
  if (m.image->load(lottie) != tvg::Result::Success) return false;
  m.image->size(&m.w, &m.h);
  m.frames = m.film->totalFrame();
  m.seconds = m.film->duration();
  return m.frames > 0.f;
}

bool motion_flat(Motion& m, uint32_t id, tvg::Matrix* place, float* opacity) {
  // Found by walking the layers. Picture::accessible, ThorVG's lookup by name,
  // finds nothing in a Lottie file in ThorVG 1.1.2.
  const tvg::Paint* p = m.image->paint(id);
  if (!p) return false;
  tvg::Matrix all = const_cast<tvg::Paint*>(p)->transform();
  float seen = (float)p->opacity() / 255.f;
  for (const tvg::Paint* up = p->parent();
       up && up->type() != tvg::Type::Picture; up = up->parent()) {
    const tvg::Matrix o = const_cast<tvg::Paint*>(up)->transform();
    all = {o.e11 * all.e11 + o.e12 * all.e21,
           o.e11 * all.e12 + o.e12 * all.e22,
           o.e11 * all.e13 + o.e12 * all.e23 + o.e13,
           o.e21 * all.e11 + o.e22 * all.e21,
           o.e21 * all.e12 + o.e22 * all.e22,
           o.e21 * all.e13 + o.e22 * all.e23 + o.e23,
           0.f,
           0.f,
           1.f};
    seen *= (float)up->opacity() / 255.f;
  }
  *place = all;
  if (opacity) *opacity = seen;
  return true;
}

filament::math::mat4f motion_built(Motion& m, uint32_t id, float* zoom) {
  using namespace filament::math;
  float n[19] = {};
  uint32_t above = 0;
  int kind = 0;
  if (m.film->pose(id, n, &above, &kind) != tvg::Result::Success || kind == 0) {
    tvg::Matrix f{1, 0, 0, 0, 1, 0, 0, 0, 1};
    motion_flat(m, id, &f);
    return motion_deep(f);
  }
  const float deg = 3.14159265f / 180.f;
  const float3 p{n[0], n[1], n[2]}, a{n[3], n[4], n[5]}, s{n[6], n[7], n[8]},
      o{n[9], n[10], n[11]}, r{n[12], n[13], n[14]};
  const float skew = n[15], axis = n[16];
  if (zoom) *zoom = n[18];
  // Auto-orient along the path: a rotation about z.
  const mat4f facing = mat4f::rotation(n[17] * deg, float3{0, 0, 1});
  const auto turns = [&](float3 by) {
    return mat4f::rotation(by.x * deg, float3{1, 0, 0}) *
           mat4f::rotation(by.y * deg, float3{0, 1, 0}) *
           mat4f::rotation(by.z * deg, float3{0, 0, 1});
  };
  // The skew: a shear along x, applied about the skew axis.
  mat4f lean;
  lean[1][0] = std::tan(-skew * deg);
  lean = mat4f::rotation(-axis * deg, float3{0, 0, 1}) * lean *
         mat4f::rotation(axis * deg, float3{0, 0, 1});
  mat4f own;
  if (kind == 1)
    own = mat4f::translation(p) * facing * turns(o) * turns(r) * lean *
          mat4f::scaling(s * 0.01f) * mat4f::translation(-a);
  else {
    // A camera has no scale and no anchor. A camera that looks at a point
    // is first turned to face it, with no roll.
    mat4f towards;
    if (kind == 2 && length(a - p) > 1e-4f) {
      const float3 z = normalize(a - p),
                   x = normalize(cross(float3{0, 1, 0}, z)), y = cross(z, x);
      towards = mat4f(float4{x, 0.f}, float4{y, 0.f}, float4{z, 0.f},
                      float4{0.f, 0.f, 0.f, 1.f});
    }
    own = mat4f::translation(p) * towards * turns(o) * turns(r);
  }
  return above ? motion_built(m, above) * own : own;
}

filament::math::mat4f motion_in_scene(const filament::math::mat4f& place,
                                      filament::math::float3 corner,
                                      filament::math::float3 right,
                                      filament::math::float3 down) {
  using namespace filament::math;
  const float pixel = length(right);
  const float3 x = right / pixel, y = normalize(down), z = cross(x, y);
  return mat4f(float4{x * pixel, 0.f}, float4{y * pixel, 0.f},
               float4{z * pixel, 0.f}, float4{corner, 1.f}) *
         place * mat4f::scaling(1.f / pixel);
}

}  // namespace motolii

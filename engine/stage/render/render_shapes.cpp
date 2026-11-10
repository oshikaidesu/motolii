// The meshes that need no GPU: the sheet given depth, and the cube, torus,
// sphere and gem, as points, normals, uvs and indices in a Mesh.
#include <filament/RenderableManager.h>
#include <geometry/SurfaceOrientation.h>

#include "stage/render/render_stage.h"

namespace motolii {

using filament::Box;
using filament::Engine;
using filament::IndexBuffer;
using filament::IndirectLight;
using filament::InstanceBuffer;
using filament::Material;
using filament::MaterialInstance;
using filament::RenderableManager;
using filament::Renderer;
using filament::RenderTarget;
using filament::Texture;
using filament::TextureSampler;
using filament::VertexAttribute;
using filament::VertexBuffer;
using filament::View;
using filament::Viewport;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
using filament::math::quatf;
namespace backend = filament::backend;
namespace geometry = filament::geometry;
namespace math = filament::math;

void sheet_deep(Mesh* m, float deep) {
  for (size_t i = 0; i < 4; ++i)
    m->pos.push_back(m->pos[i]), m->nrm.push_back(m->nrm[i]),
        m->uv.push_back(m->uv[i]);
  for (size_t i = 0; i < 4; ++i) m->pos[i].z = deep, m->pos[i + 4].z = -deep;
  m->idx = {0, 1, 2, 0, 2, 3, 5, 4, 7, 5, 7, 6, 4, 5, 1, 4, 1, 0,
            5, 6, 2, 5, 2, 1, 6, 7, 3, 6, 3, 2, 7, 4, 0, 7, 0, 3};
}

Mesh* cube(float ROUND, int flat) {
  Mesh* m = new Mesh;
  // Where a face is cut: finely across the rounding, and `flat` times across
  // the flat part.
  std::vector<float> line;
  for (int k = 0; k <= 4; ++k) line.push_back(-1.f + ROUND * (float)k / 4.f);
  for (int k = 1; k < flat; ++k)
    line.push_back(-(1.f - ROUND) +
                   2.f * (1.f - ROUND) * (float)k / (float)flat);
  for (int k = 4; k >= 0; --k) line.push_back(1.f - ROUND * (float)k / 4.f);
  const int n = (int)line.size();
  const float3 ax[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
  for (int f = 0; f < 6; ++f) {
    const float sgn = f < 3 ? 1.f : -1.f;
    const float3 nf = ax[f % 3] * sgn, a = ax[(f + 1) % 3],
                 b = ax[(f + 2) % 3] * sgn;
    const uint32_t base = (uint32_t)m->pos.size();
    for (int j = 0; j < n; ++j)
      for (int i = 0; i < n; ++i) {
        const float3 q = nf + a * line[i] + b * line[j];
        const float3 core =
                         clamp(q, float3{-(1.f - ROUND)}, float3{1.f - ROUND}),
                     out = normalize(q - core);
        m->pos.push_back((core + out * ROUND) * 0.5f);
        m->nrm.push_back(out);
        m->uv.push_back({0, 0});
      }
    for (int j = 0; j + 1 < n; ++j)
      for (int i = 0; i + 1 < n; ++i) {
        const uint32_t p0 = base + (uint32_t)(j * n + i), p1 = p0 + 1,
                       p2 = p0 + (uint32_t)n + 1, p3 = p0 + (uint32_t)n;
        m->idx.insert(m->idx.end(), {p0, p1, p2, p0, p2, p3});
      }
  }
  return m;
}

Mesh* torus(float R, float r, int around, int about) {
  Mesh* m = new Mesh;
  for (int i = 0; i < around; ++i)
    for (int k = 0; k < about; ++k) {
      const float a = TAU * (float)i / around, b = TAU * (float)k / about;
      const float3 out{std::cos(a) * std::cos(b), std::sin(a) * std::cos(b),
                       std::sin(b)};
      m->pos.push_back(float3{std::cos(a), std::sin(a), 0.f} * R + out * r);
      m->nrm.push_back(out);
      m->uv.push_back({(float)i / around, (float)k / about});
      const uint32_t i1 = (uint32_t)((i + 1) % around),
                     k1 = (uint32_t)((k + 1) % about);
      const uint32_t p = (uint32_t)(i * about + k),
                     q = (uint32_t)(i * about) + k1,
                     s = i1 * about + (uint32_t)k, t = i1 * about + k1;
      m->idx.insert(m->idx.end(), {p, s, q, q, s, t});
    }
  return m;
}

Mesh* sphere(float r, int around, int about) {
  Mesh* m = new Mesh;
  for (int i = 0; i <= around; ++i)
    for (int k = 0; k <= about; ++k) {
      const float a = TAU * (float)i / around,
                  b = 0.5f * TAU * (float)k / about - 0.25f * TAU;
      const float3 out{std::cos(a) * std::cos(b), std::sin(b),
                       std::sin(a) * std::cos(b)};
      m->pos.push_back(out * r);
      m->nrm.push_back(out);
      m->uv.push_back({(float)i / around, (float)k / about});
      if (i < around && k < about) {
        const uint32_t p = (uint32_t)(i * (about + 1) + k), q = p + 1,
                       s = p + (uint32_t)(about + 1), t = s + 1;
        m->idx.insert(m->idx.end(), {p, q, s, s, q, t});
      }
    }
  return m;
}

Mesh* gem(float size) {
  const float f = (1.f + std::sqrt(5.f)) * 0.5f;
  const float3 v[12] = {{-1, f, 0}, {1, f, 0}, {-1, -f, 0}, {1, -f, 0},
                        {0, -1, f}, {0, 1, f}, {0, -1, -f}, {0, 1, -f},
                        {f, 0, -1}, {f, 0, 1}, {-f, 0, -1}, {-f, 0, 1}};
  const int faces[20][3] = {{0, 11, 5},  {0, 5, 1},  {0, 1, 7},  {0, 7, 10},
                            {0, 10, 11}, {1, 5, 9},  {5, 11, 4}, {11, 10, 2},
                            {10, 7, 6},  {7, 1, 8},  {3, 9, 4},  {3, 4, 2},
                            {3, 2, 6},   {3, 6, 8},  {3, 8, 9},  {4, 9, 5},
                            {2, 4, 11},  {6, 2, 10}, {8, 6, 7},  {9, 8, 1}};
  Mesh* m = new Mesh;
  for (const auto& t : faces) {
    const float3 n = normalize(cross(v[t[1]] - v[t[0]], v[t[2]] - v[t[0]]));
    for (int k = 0; k < 3; ++k) {
      m->idx.push_back((uint32_t)m->pos.size());
      m->pos.push_back(normalize(v[t[k]]) * size);
      m->nrm.push_back(n);
      m->uv.push_back({0, 0});
    }
  }
  return m;
}

}  // namespace motolii

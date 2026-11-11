// Where the effect image of a layer or a solid is laid: the plane it is drawn
// on, its face and its stand in the scene, and the cover that keeps what is
// behind it.
#include <filament/TextureSampler.h>
#include <filament/Viewport.h>

#include "community/three/solid_three.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
namespace motolii {

using filament::Camera;
using filament::Renderer;
using filament::RenderTarget;
using filament::Scene;
using filament::Texture;
using filament::TextureSampler;
using filament::View;
using filament::Viewport;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
namespace backend = filament::backend;
namespace math = filament::math;

void thing_fx_aim(Stage& s, ThingFx& e, const double* said) {
  const double ppp = (double)s.view->getViewport().width / std::max(1, s.w);
  double box[4] = {said[0], said[1], said[2], said[3]};
  // A solid reads its image point for point, so snap the box to the stage's
  // pixels.
  if (e.shell)
    box[0] = std::floor(box[0] * ppp) / ppp,
    box[1] = std::floor(box[1] * ppp) / ppp,
    box[2] = std::ceil(box[2] * ppp) / ppp,
    box[3] = std::ceil(box[3] * ppp) / ppp;
  std::copy(box, box + 4, e.box), std::copy(box, box + 4, e.st.box);
  // The box in the stage's clip space, y up.
  const double x0 = 2 * box[0] / s.w - 1, x1 = 2 * box[2] / s.w - 1,
               y0 = 1 - 2 * box[3] / s.h, y1 = 1 - 2 * box[1] / s.h;
  math::mat4 crop;
  crop[0][0] = 2 / (x1 - x0), crop[1][1] = 2 / (y1 - y0),
  crop[3][0] = -(x0 + x1) / (x1 - x0), crop[3][1] = -(y0 + y1) / (y1 - y0);
  const Camera& c = *s.camera;
  e.camera->setCustomProjection(crop * c.getProjectionMatrix(),
                                crop * c.getCullingProjectionMatrix(),
                                c.getNear(), c.getCullingFar());
  e.camera->setModelMatrix(c.getModelMatrix());
  e.camera->setExposure(c.getAperture(), c.getShutterSpeed(),
                        c.getSensitivity());
  e.view->setViewport(
      {0, 0, (uint32_t)std::max(1L, std::lround((box[2] - box[0]) * ppp)),
       (uint32_t)std::max(1L, std::lround((box[3] - box[1]) * ppp))});
  math::mat4f place;
  place[0][0] = (float)((x1 - x0) / 2), place[1][1] = (float)((y1 - y0) / 2),
  place[3][0] = (float)((x0 + x1) / 2), place[3][1] = (float)((y0 + y1) / 2);
  if (e.shell)
    e.look->setParameter("box",
                         float4{(float)(box[0] / s.w), (float)(box[1] / s.h),
                                (float)((box[2] - box[0]) / s.w),
                                (float)((box[3] - box[1]) / s.h)});
  else
    e.look->setParameter("place", place);
}

void thing_fx_face(Stage& s, ThingFx& e, const math::mat4& place, float2 half,
                   double room, double dense, const double* sides) {
  math::double3 x = place[0].xyz, y = place[1].xyz;
  const double sx = length(x), sy = length(y), wide = half.x * sx + room,
               high = half.y * sy + room;
  const double l = sides ? sides[0] : wide, r = sides ? sides[1] : wide,
               b = sides ? sides[2] : high, t = sides ? sides[3] : high,
               far = 4.0 * std::max({l, r, b, t}) + 1.0;
  if (wide < 1e-9 || high < 1e-9) return;
  x /= sx, y = normalize(y - dot(y, x) * x);
  const math::double3 z = cross(x, y);
  e.square = math::mat4(math::double4{x, 0}, math::double4{y, 0},
                        math::double4{z, 0}, place[3]);
  e.camera->setModelMatrix(
      e.square * math::mat4::translation(math::double3{0, 0, 0.5 * far}));
  e.camera->setProjection(Camera::Projection::ORTHO, -l, r, -b, t, 0.0, far);
  const Camera& c = *s.camera;
  e.camera->setExposure(c.getAperture(), c.getShutterSpeed(),
                        c.getSensitivity());
  const double k = dense > 0.0 ? dense : 2048.0 / std::max(l + r, b + t);
  e.view->setViewport({0, 0, (uint32_t)std::max(1L, std::lround(k * (l + r))),
                       (uint32_t)std::max(1L, std::lround(k * (b + t)))});
}

void thing_fx_stand(Stage& s, ThingFx& e, const math::mat4& place, float2 half,
                    double seen) {
  // `usual` is the number of stage points per world unit at the stage's own
  // camera distance; see document/evaluate/evaluate.h.
  const double ppp = (double)s.view->getViewport().width / std::max(1, s.w),
               usual = s.h / (12.0 * std::tan(15.0 * M_PI / 180.0));
  const double room = 128.0 / usual, sx = length(place[0].xyz),
               sy = length(place[1].xyz), wide = half.x * sx + room,
               high = half.y * sy + room;
  const double c[4] = {std::max(wide, e.sides[0]), std::max(wide, e.sides[1]),
                       std::max(high, e.sides[2]), std::max(high, e.sides[3])},
               across = c[0] + c[1], tall = c[2] + c[3];
  // At most 4096 pixels.
  const double point =
      std::min(std::max(usual, seen), 4096.0 / (ppp * std::max(across, tall)));
  thing_fx_face(s, e, place, half, room, point * ppp, c);
  e.box[0] = e.box[1] = 0, e.box[2] = across * point, e.box[3] = tall * point;
  std::copy(e.box, e.box + 4, e.st.box);
  e.st.frame[0] = (c[0] - wide) / across, e.st.frame[1] = (c[3] - high) / tall,
  e.st.frame[2] = 2 * wide / across, e.st.frame[3] = 2 * high / tall;
  e.st.own[0] = (c[0] - wide + room) / across,
  e.st.own[1] = (c[3] - high + room) / tall,
  e.st.own[2] = 2 * (wide - room) / across,
  e.st.own[3] = 2 * (high - room) / tall;
  e.own[0] = c[0] * point, e.own[1] = c[3] * point,
  e.own[2] = 2 * half.x * sx * point, e.own[3] = 2 * half.y * sy * point,
  e.own[4] = point;
  const mat4f sheet =
      mat4f(e.square *
            math::mat4::translation(
                math::double3{(c[1] - c[0]) / 2, (c[3] - c[2]) / 2, 0.0}) *
            math::mat4::scaling(math::double3{across / 2, tall / 2, 1.0}));
  move(s, e.sheet, [&](int, const mat4f&) { return sheet; });
}

void thing_fx_solid(Stage& s, ThingFx& e, bool inFrame) {
  std::string said = e.solidFile + " " + std::to_string(e.size.x) + " " +
                     std::to_string(e.size.y) + " " +
                     std::to_string(e.cover->times);
  for (const auto& [n, v] : e.parameters)
    said += " " + n + "=" + std::to_string(v);
  for (const auto& [n, w] : e.words) said += " " + n + ":" + w;
  const auto lit = e.parameters.find("lit");
  const bool flat = lit != e.parameters.end() && lit->second == 0;
  const char* const look =
      flat ? "solid_image_flat.filamat" : "solid_image.filamat";
  const bool anew = !e.solid || e.solidAs != look;
  if (said == e.solidSaid || (anew && inFrame)) return;
  SolidMesh built;
  std::string why;
  if (!solid_three(e.solidFile, e.parameters, e.words, e.size.x, e.size.y,
                   e.cover->a, e.cover->w, e.cover->h, built, why))
    std::fprintf(stderr, "the solid %s is not built: %s\n", e.solidFile.c_str(),
                 why.substr(0, 600).c_str());
  // Nothing is built yet, for example Raster Extrude before its image is read.
  // Use a single point so that the material is ready.
  if (built.idx.empty() || built.pos.size() != built.nrm.size() ||
      built.uv.size() * 3 != built.pos.size() * 2)
    built = SolidMesh{{0, 0, 0, 0, 0, 0, 0, 0, 0},
                      {0, 0, 1, 0, 0, 1, 0, 0, 1},
                      {0, 0, 0, 0, 0, 0},
                      {0, 1, 2}};
  e.solidSaid = said;
  if (anew && e.solid) take_off(s, e.solid), delete e.solid, e.solid = nullptr;
  Mesh* m = e.solid ? e.solid : new Mesh;
  // A buffer object for each attribute, so that a points file can move it.
  m->objects = true;
  m->pos.resize(built.pos.size() / 3), m->nrm.resize(built.pos.size() / 3),
      m->uv.resize(built.uv.size() / 2);
  std::memcpy(m->pos.data(), built.pos.data(),
              built.pos.size() * sizeof(float)),
      std::memcpy(m->nrm.data(), built.nrm.data(),
                  built.nrm.size() * sizeof(float));
  std::memcpy(m->uv.data(), built.uv.data(), built.uv.size() * sizeof(float));
  m->idx = std::move(built.idx);
  e.solidRepeat = built.repeat;
  if (!anew) return reshape(s, m, {(uint32_t)m->idx.size()});
  e.solid = m, e.solidAs = look;
  e.solidLook = add(s, m, look, {mat4f{}}, 1, true);
  if (!e.solidLook) return;
  // Give it an image from the start, as the sheet does.
  e.solidLook->setParameter("image", white_point(s), TextureSampler());
  if (!flat)
    e.solidLook->setParameter("roughness", 0.5f),
        e.solidLook->setParameter("metallic", 0.f);
}

void thing_fx_cover(Stage& s, ThingFx& e, int cells) {
  RenderTarget* const from =
      e.st.steps.empty() ? e.st.target
                         : e.st.betweenTarget[(e.st.steps.size() - 1) % 2];
  const Viewport vp = e.view->getViewport();
  if (!from || !vp.width || !vp.height) return;
  auto* pixels = new std::vector<uint8_t>((size_t)vp.width * vp.height * 4);
  s.renderer->readPixels(
      from, 0, 0, vp.width, vp.height,
      backend::PixelBufferDescriptor::make(
          pixels->data(), pixels->size(), backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE,
          [pixels, cover = e.cover, w = (int)vp.width, h = (int)vp.height,
           cells](void const*, size_t) {
            const double every = (double)std::max(w, h) / std::max(2, cells);
            const int cw = std::max(2, (int)(w / every)),
                      ch = std::max(2, (int)(h / every));
            std::vector<uint8_t> a((size_t)cw * ch);
            for (int y = 0; y < ch; ++y)
              for (int x = 0; x < cw; ++x)
                a[(size_t)(y * cw + x)] =
                    (*pixels)[4 * ((size_t)std::min(h - 1, (int)(y * every)) *
                                       w +
                                   std::min(w - 1, (int)(x * every))) +
                              3];
            if (a != cover->a || cw != cover->w)
              cover->a = std::move(a), cover->w = cw, cover->h = ch,
              cover->times++;
            delete pixels;
          }));
}

}  // namespace motolii

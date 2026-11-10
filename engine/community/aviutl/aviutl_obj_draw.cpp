#include "community/aviutl/aviutl_obj_draw.h"

#include <filament/Texture.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <lua.hpp>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "community/aviutl/aviutl_fx.h"
#include "gpu/screen_interop.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Texture;

namespace {

// One corner of a face. (x, y, z) is the position in pixels relative to the
// centre of the target, with y pointing down. (u, v) is the position in pixels
// in the source image. colour is premultiplied, with each channel from 0 to 1.
struct AviutlCorner {
  double x, y, z, u, v;
  float colour[4] = {1, 1, 1, 1};
};
// Draws faces from the image `from` into `to` on the interop's mesh. The centre
// of `to` is the origin and y points down. A face has three or four corners. A
// four-corner face is drawn as two triangles, 0-1-2 and 0-2-3 (sashimono-edit's
// _fill_quad, MIT). The image is mapped onto the faces at the corners' u, v in
// pixels, or the corners' colours are used (premultiplied, 0 to 1, as lua.txt
// and sashimono-edit's raster.draw_triangle take them). All faces of one call
// are drawn at once, as Filament draws its own triangles.
//
// The faces are seen through AviUtl's camera, as in sashimono-edit's
// engine/gpu/projection.py. The canvas is 1024 pixels in front of the camera,
// and a point z further away appears 1024 / (1024 + z) as large. A face with a
// corner at or behind the camera is not drawn. The GPU's own divide by w
// interpolates the image in perspective between the corners.
//
// This also draws into the temporary buffer. sashimono-edit leaves z out there,
// but the script GrungeConverter.anm2 draws with z in that buffer and
// thresholds the result after blurring the edges, so AviUtl2 itself must apply
// z there.
//
// ox, oy and oz move the whole group. fade multiplies the alpha. way is the
// blend number from aviutl_way, and sampler is the number from aviutl_sampling.
void aviutl_mesh(AviutlRun& r, const AviutlBuf& from, const AviutlBuf& to,
                 const std::vector<std::vector<AviutlCorner>>& faces, double ox,
                 double oy, double oz, double fade, int way, int sampler) {
  std::vector<float> corners;
  const auto corner = [&](const AviutlCorner& p) {
    const float w = (float)((1024.0 + oz + p.z) / 1024.0);
    corners.insert(
        corners.end(),
        {(float)((ox + p.x) / (to.w / 2.0)),
         (float)(-(oy + p.y) / (to.h / 2.0)), 0.f, w, p.colour[0], p.colour[1],
         p.colour[2], p.colour[3], (float)(p.u / std::max(1u, from.w)),
         (float)(p.v / std::max(1u, from.h))});
  };
  for (const auto& c : faces) {
    if (std::any_of(c.begin(), c.end(), [&](const AviutlCorner& p) {
          return 1024.0 + oz + p.z < 1.0;
        }))
      continue;
    corner(c[0]), corner(c[1]), corner(c[2]);
    if (c.size() == 4) corner(c[0]), corner(c[2]), corner(c[3]);
  }
  if (corners.empty()) return;
  const float k[4] = {(float)fade, 0, 0, 0};
  const int pass = r.draws[r.poly]++;
  interop::parameters(r.s->engine, r.poly, k, sizeof k, pass);
  Texture* texture = from.t ? from.t : r.none;
  interop::draw(r.s->engine, r.poly, &texture, to.rt, to.w, to.h, pass, nullptr,
                true, way, sampler, corners.data(),
                (uint32_t)(corners.size() / interop::MESH_CORNER));
}
// Maps the value of obj.setoption "blend" to the interop's blend number.
// Returns -1 for a value that is not supported. The names follow lua.txt, as
// read by sashimono-edit (MIT, compat/aviutl/raster.py _over).
//
// The buffers are premultiplied, so "alpha_add" (colours weighted by their
// alphas, alphas added) is the destination plus the source. "alpha_sub"
// (colours kept, the source alpha subtracted) is Porter-Duff "out". The two
// agree wherever either side is opaque, because sashimono-edit's a_b - a_t is
// a_b (1 - a_t) there. "alpha_add2" lays the colours over each other and adds
// the alphas. "screen" (AviUtl's 4) is Filament's own screen blend. AviUtl's 3
// (multiply) is done as Motolii's own sheets multiply (flat.mat), treating what
// is underneath as opaque.
int aviutl_way(const std::string& b) {
  if (b.empty() || b == "none" || b == "0") return 0;
  if (b == "add" || b == "1" || b == "rgba_add" || b == "alpha_add") return 1;
  if (b == "alpha_sub") return 3;
  if (b == "alpha_add2") return 4;
  if (b == "screen" || b == "4") return 5;
  if (b == "3") return 6;
  return -1;
}
// Maps the current sampler name to the interop's sampler number.
int aviutl_sampling(const AviutlRun& r) {
  return r.sampler == "dot"      ? 1
         : r.sampler == "loop"   ? 2
         : r.sampler == "mirror" ? 3
                                 : 0;
}

}  // namespace

void aviutl_placed(AviutlRun& r, const AviutlBuf& from, const AviutlBuf& to,
                   double x, double y, double z, double sx, double sy,
                   double rx, double ry, double rz, double cx, double cy,
                   double fade, int way, int sampler) {
  std::vector<AviutlCorner> c;
  const double hw = from.w * sx / 2, hh = from.h * sy / 2;
  static const int signs[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
  for (const auto& [kx, ky] : signs) {
    double px = kx * hw - cx, py = ky * hh - cy, pz = 0, cs, sn;
    if (rx)
      cs = std::cos(rx * M_PI / 180), sn = std::sin(rx * M_PI / 180),
      std::tie(py, pz) = std::pair{py * cs + pz * sn, -py * sn + pz * cs};
    if (ry)
      cs = std::cos(ry * M_PI / 180), sn = std::sin(ry * M_PI / 180),
      std::tie(px, pz) = std::pair{px * cs - pz * sn, px * sn + pz * cs};
    if (rz)
      cs = std::cos(rz * M_PI / 180), sn = std::sin(rz * M_PI / 180),
      std::tie(px, py) = std::pair{px * cs - py * sn, px * sn + py * cs};
    c.push_back({px + cx, py + cy, pz, kx > 0 ? (double)from.w : 0.0,
                 ky > 0 ? (double)from.h : 0.0});
  }
  aviutl_mesh(r, from, to, {c}, x, y, z, fade, way, sampler);
}

int aviutl_draw(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const int way = aviutl_way(r.blend);
  if (way < 0) return aviutl_no(L, "obj.draw blend " + r.blend);
  lua_getglobal(L, "obj");
  const auto f = [&](const char* k, double otherwise) {
    lua_getfield(L, -1, k);
    const double v = aviutl_num(L, -1, otherwise);
    lua_pop(L, 1);
    return v;
  };
  // When drawing into the frame, the layer's own x and y are added. When
  // drawing into the temporary buffer, the layer's placement is not applied
  // (lua.txt says the object's own coordinates and settings are not reflected
  // there). What the script has changed since it started is applied: obj.ox,
  // rz, zoom and alpha, which start at 0 or 1 here, with the layer's own
  // placement applied outside them. Mathy_Su moves obj.ox, obj.rz and obj.alpha
  // before each obj.draw() into that buffer, which its README describes as
  // moving along a path by placement position and as the source image's
  // transparency. The script that places an object at four corners does the
  // same with its four.
  const bool own = r.target == "framebuffer";
  const double zoom = aviutl_num(L, 4, 1) * f("zoom", 1),
               aspect = f("aspect", 0);
  const AviutlBuf& to = r.bufs[r.target];
  if (!to.t)
    return aviutl_no(L, "obj.draw into a temporary buffer never created");
  const double z = aviutl_num(L, 3) + f("oz", 0),
               rx = aviutl_num(L, 6) + f("rx", 0),
               ry = aviutl_num(L, 7) + f("ry", 0);
  if (z != 0 || rx != 0 || ry != 0) {
    if (!r.poly) return aviutl_no(L, "obj.draw in depth: " + r.trouble);
    aviutl_placed(r, r.bufs["object"], to,
                  aviutl_num(L, 1) + (own ? f("x", 0) : 0) + f("ox", 0),
                  aviutl_num(L, 2) + (own ? f("y", 0) : 0) + f("oy", 0), z,
                  zoom * (aspect > 0 ? 1 - aspect : 1),
                  zoom * (aspect < 0 ? 1 + aspect : 1), rx, ry,
                  aviutl_num(L, 8) + f("rz", 0), f("cx", 0), f("cy", 0),
                  aviutl_num(L, 5, 1) * f("alpha", 1), way, aviutl_sampling(r));
  } else
    aviutl_lay(
        r, r.bufs["object"], to.rt, to.w, to.h,
        aviutl_num(L, 1) + (own ? f("x", 0) : 0) + f("ox", 0),
        aviutl_num(L, 2) + (own ? f("y", 0) : 0) + f("oy", 0),
        zoom * (aspect > 0 ? 1 - aspect : 1),
        zoom * (aspect < 0 ? 1 + aspect : 1), aviutl_num(L, 8) + f("rz", 0),
        aviutl_num(L, 5, 1) * f("alpha", 1), f("cx", 0), f("cy", 0), way,
        aviutl_sampling(r),
        r.sampler == "clamp" || r.sampler == "loop" || r.sampler == "mirror"
            ? 2.f
            : 0.f);
  lua_pop(L, 1);
  if (own) r.drew = true;
  return 0;
}
int aviutl_drawpoly(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const AviutlBuf& from = r.bufs["object"];
  std::vector<std::vector<AviutlCorner>> faces;
  double alpha = 1;
  const auto item = [&]() {
    std::vector<double> v;
    for (int j = 1; j <= (int)lua_objlen(L, -1); ++j)
      lua_rawgeti(L, -1, j), v.push_back(aviutl_num(L, -1)), lua_pop(L, 1);
    return v;
  };
  const auto face = [&](const double* p) {
    std::vector<AviutlCorner> c(4);
    for (int i = 0; i < 4; ++i)
      c[i] = {p[i * 3], p[i * 3 + 1], p[i * 3 + 2], p[12 + i * 2],
              p[13 + i * 2]};
    return c;
  };
  if (lua_istable(L, 1)) {
    std::vector<std::vector<double>> items;
    for (int i = 1; i <= (int)lua_objlen(L, 1); ++i) {
      lua_rawgeti(L, 1, i);
      if (!lua_istable(L, -1))
        return aviutl_no(L, "obj.drawpoly of a table of numbers");
      items.push_back(item()), lua_pop(L, 1);
    }
    if (items.empty()) return 0;
    const size_t width = items[0].size();
    for (const auto& v : items)
      if (v.size() != width) return aviutl_no(L, "obj.drawpoly of mixed faces");
    if (width == 20) {
      // Faces: 12 position numbers, then 8 numbers of u, v.
      alpha = aviutl_num(L, 2, 1);
      for (const auto& v : items) faces.push_back(face(v.data()));
    } else if (width == 28) {
      // Coloured faces: the positions of four corners, then their colours
      // (premultiplied, 0 to 1). This is laid out like the 20-number face,
      // which has positions and then u, v.
      alpha = aviutl_num(L, 2, 1);
      for (const auto& v : items) {
        std::vector<AviutlCorner> c(4);
        for (int i = 0; i < 4; ++i) {
          // There is no image, so u, v are placed well outside it.
          c[i] = {v[i * 3], v[i * 3 + 1], v[i * 3 + 2], -2.0 * from.w,
                  -2.0 * from.h};
          for (int k = 0; k < 4; ++k)
            c[i].colour[k] = (float)std::clamp(v[12 + i * 4 + k], 0.0, 1.0);
        }
        faces.push_back(c);
      }
    } else if (width == 5 || width == 7) {
      // Corners: 5 numbers have a position and an image position (u, v). 7
      // numbers have a position and a colour.
      const int count = lua_isnumber(L, 2) ? (int)lua_tonumber(L, 2) : 4;
      alpha = aviutl_num(L, 3, 1);
      if ((count != 3 && count != 4) || items.size() % count)
        return aviutl_no(
            L, "obj.drawpoly of " + std::to_string(count) + "-cornered faces");
      for (size_t f = 0; f < items.size(); f += count) {
        std::vector<AviutlCorner> c;
        for (int i = 0; i < count; ++i) {
          const auto& v = items[f + i];
          // A coloured corner (7 numbers) uses no image, so u, v are placed
          // well outside it.
          AviutlCorner one{v[0], v[1], v[2],
                           width == 5 ? v[3] * from.w : -2.0 * from.w,
                           width == 5 ? v[4] * from.h : -2.0 * from.h};
          if (width == 7)
            for (int k = 0; k < 4; ++k)
              one.colour[k] = (float)std::clamp(v[3 + k], 0.0, 1.0);
          c.push_back(one);
        }
        faces.push_back(c);
      }
    } else
      return aviutl_no(
          L, "obj.drawpoly of " + std::to_string(width) + " numbers a face");
  } else {
    const int n = lua_gettop(L);
    if (n < 12)
      return aviutl_no(L, "obj.drawpoly with fewer than four corners");
    double p[20] = {};
    for (int i = 0; i < 12; ++i) p[i] = aviutl_num(L, i + 1);
    if (n >= 20)
      for (int i = 0; i < 8; ++i) p[12 + i] = aviutl_num(L, 13 + i);
    else
      p[14] = from.w, p[16] = from.w, p[17] = from.h, p[19] = from.h;
    alpha = n == 13 ? aviutl_num(L, 13, 1) : n >= 21 ? aviutl_num(L, 21, 1) : 1;
    faces.push_back(face(p));
  }
  const int way = aviutl_way(r.blend);
  if (way < 0) return aviutl_no(L, "obj.drawpoly blend " + r.blend);
  const AviutlBuf& to = r.bufs[r.target];
  if (!to.t)
    return aviutl_no(L, "obj.drawpoly into a temporary buffer never created");
  if (!r.poly) return aviutl_no(L, "obj.drawpoly: " + r.trouble);
  const bool own = r.target == "framebuffer";
  lua_getglobal(L, "obj");
  const auto f = [&](const char* k, double otherwise) {
    lua_getfield(L, -1, k);
    const double v = aviutl_num(L, -1, otherwise);
    lua_pop(L, 1);
    return v;
  };
  const double ox = own ? f("x", 0) + f("ox", 0) : 0,
               oy = own ? f("y", 0) + f("oy", 0) : 0, oz = own ? f("oz", 0) : 0,
               fade = alpha * (own ? f("alpha", 1) : 1);
  lua_pop(L, 1);
  aviutl_mesh(r, from, to, faces, ox, oy, oz, fade, way, aviutl_sampling(r));
  if (own) r.drew = true;
  return 0;
}

}  // namespace motolii

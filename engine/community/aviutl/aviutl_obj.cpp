#include "community/aviutl/aviutl_obj.h"

#include <filament/Texture.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <lua.hpp>
#include <ratio>
#include <string>
#include <utility>
#include <vector>

#include "community/aviutl/aviutl.h"
#include "community/aviutl/aviutl_fx.h"
#include "community/aviutl/aviutl_load.h"
#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Texture;

int aviutl_module(lua_State* L) {
  return luaL_error(L,
                    "needs %s.mod2, an AviUtl2 script module (a Windows DLL)",
                    luaL_checkstring(L, 1));
}
int aviutl_ticks(lua_State* L) {
  return lua_pushnumber(
             L, (double)std::chrono::duration_cast<
                    std::chrono::duration<long long, std::ratio<1, 10000000>>>(
                    std::chrono::steady_clock::now().time_since_epoch())
                    .count()),
         1;
}
int aviutl_pixelshader(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string name = luaL_checkstring(L, 1),
                    target = aviutl_name(luaL_checkstring(L, 2)),
                    blend = lua_isstring(L, 5) ? lua_tostring(L, 5) : "copy",
                    sampler = aviutl_str(L, 6);
  const AviutlShader* sh = nullptr;
  std::string why;
  interop::Screen* d =
      aviutl_interop(r, name, sampler == "clip" || sampler == "dot", why, &sh);
  if (!d)
    return aviutl_no(L, "obj.pixelshader " + name + ": " + why.substr(0, 300));
  if (target.rfind("image:", 0) == 0 || !r.bufs.count(target))
    return aviutl_no(L, "obj.pixelshader into " + target);
  std::vector<std::string> res;
  if (lua_istable(L, 3))
    for (int i = 1; i <= (int)lua_objlen(L, 3); ++i)
      lua_rawgeti(L, 3, i), res.push_back(aviutl_name(aviutl_str(L, -1))),
          lua_pop(L, 1);
  else if (lua_isstring(L, 3))
    res.push_back(aviutl_name(lua_tostring(L, 3)));
  std::vector<Texture*> read((size_t)sh->textureCount, r.none);
  for (size_t i = 0; i < res.size() && i < read.size(); ++i) {
    if (res[i] == "random") {
      read[i] = r.random;
      continue;
    }
    if ((res[i] == "framebuffer" && !r.behind) || !r.bufs.count(res[i]))
      return aviutl_no(L, "obj.pixelshader reading " + res[i]);
    // When the target is also a resource, it is read from a copy, as the spec
    // requires.
    if (res[i] == target)
      aviutl_copy(r, "~" + std::to_string(i), target),
          read[i] = r.bufs["~" + std::to_string(i)].t;
    else
      read[i] = r.bufs[res[i]].t;
  }
  // lua holds the constants as the script gave them. k holds them at the
  // offsets where the WGSL layout expects them (see aviutl.cpp).
  std::vector<float> lua, k(sh->bytes / 4, 0.f);
  if (lua_istable(L, 4))
    for (int i = 1; i <= (int)lua_objlen(L, 4); ++i)
      lua_rawgeti(L, 4, i), lua.push_back((float)aviutl_num(L, -1)),
          lua_pop(L, 1);
  for (size_t s = 0; s < sh->from.size(); ++s)
    for (uint32_t c = 0; c < sh->count[s]; ++c)
      if (sh->from[s] / 4 + c < lua.size() && sh->to[s] / 4 + c < k.size())
        k[sh->to[s] / 4 + c] = lua[sh->from[s] / 4 + c];
  const int way = blend == "copy"   ? -1
                  : blend == "draw" ? 0
                  : blend == "add"  ? 1
                  : blend == "mask" ? 2
                                    : -2;
  if (way == -2) return aviutl_no(L, "obj.pixelshader blend " + blend);
  const AviutlBuf& t = r.bufs[target];
  const int pass = r.draws[d]++;
  if (!k.empty())
    interop::parameters(r.s->engine, d, k.data(), (uint32_t)k.size() * 4, pass);
  interop::draw(r.s->engine, d, read.data(), t.rt, t.w, t.h, pass, nullptr,
                way >= 0, std::max(way, 0),
                sampler == "dot"      ? 1
                : sampler == "loop"   ? 2
                : sampler == "mirror" ? 3
                                      : 0);
  return 0;
}
int aviutl_clearbuffer(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string target = aviutl_name(luaL_checkstring(L, 1));
  const bool sized = lua_isnumber(L, 3);
  if (target.rfind("cache:", 0) != 0 && target != "object" &&
      target != "tempbuffer" && !(target == "framebuffer" && !sized))
    return aviutl_no(L, "obj.clearbuffer " + target);
  const AviutlBuf& b =
      aviutl_buf(r, target, sized ? (uint32_t)aviutl_num(L, 2) : 0,
                 sized ? (uint32_t)aviutl_num(L, 3) : 0);
  aviutl_clear(r, b, aviutl_num(L, sized ? 4 : 2),
               lua_isnumber(L, sized ? 4 : 2));
  return 0;
}
int aviutl_copybuffer(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string to = aviutl_name(luaL_checkstring(L, 1)),
                    from = aviutl_name(luaL_checkstring(L, 2));
  if (from.rfind("image:", 0) == 0 && to != "framebuffer") {
    const AviutlBuf* const img = aviutl_image(r, from.substr(6));
    if (!img) return lua_pushboolean(L, 0), 1;
    const AviutlBuf& t = aviutl_buf(r, to, img->w, img->h);
    aviutl_lay(r, *img, t.rt, t.w, t.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
    return lua_pushboolean(L, 1), 1;
  }
  if ((from == "framebuffer" || to == "framebuffer") && !r.behind)
    return aviutl_no(L, "obj.copybuffer " + to + " from " + from);
  if (!r.bufs.count(from)) return lua_pushboolean(L, 0), 1;
  aviutl_copy(r, to, from);
  return lua_pushboolean(L, 1), 1;
}
int aviutl_setoption(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string n = luaL_checkstring(L, 1);
  if (n == "drawtarget" || n == "dst") {
    const std::string t = aviutl_name(aviutl_str(L, 2));
    if (t != "tempbuffer" && t != "framebuffer")
      return aviutl_no(L, "obj.setoption drawtarget " + t);
    r.target = t;
    if (t == "tempbuffer" && lua_isnumber(L, 3))
      aviutl_clear(r,
                   aviutl_buf(r, t, (uint32_t)aviutl_num(L, 3),
                              (uint32_t)aviutl_num(L, 4)),
                   0, false);
  } else if (n == "blend")
    r.blend = lua_isnumber(L, 2) ? std::to_string((int)lua_tonumber(L, 2))
                                 : aviutl_str(L, 2);
  else if (n == "draw_state")
    r.drew = lua_toboolean(L, 2);
  else if (n == "sampler")
    r.sampler = aviutl_str(L, 2);
  // culling, billboard and focus_mode change nothing when drawing flat, so they
  // are accepted and ignored.
  else if (n != "culling" && n != "billboard" && n != "focus_mode")
    return aviutl_no(L, "obj.setoption " + n);
  return 0;
}
int aviutl_getoption(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string n = luaL_checkstring(L, 1);
  // No track moves by itself here, and there is no camera or rotation, so these
  // are always 0.
  if (n == "track_mode" || n == "camera_mode" || n == "culling" ||
      n == "billboard")
    lua_pushinteger(L, 0);
  else if (n == "section_num")
    lua_pushinteger(L, 1);
  else if (n == "gui" || n == "multi_object")
    lua_pushboolean(L, 0);
  else if (n == "draw_state")
    lua_pushboolean(L, r.drew);
  else if (n == "drawtarget")
    lua_pushstring(L, r.target.c_str());
  else if (n == "blend")
    lua_pushstring(L, r.blend.c_str());
  else if (n == "script_name") {
    // The name of the effect that many steps along the effect chain from this
    // one on the layer (lua.txt), or nil past either end.
    const long i =
        r.at + (lua_isnumber(L, 2) ? std::lround(lua_tonumber(L, 2)) : 0);
    if (i >= 0 && i < (long)r.chain.size())
      lua_pushstring(L, r.chain[(size_t)i].c_str());
    else
      lua_pushnil(L);
  } else if (n == "group_info") {
    // The layer of the enclosing group, where index 0 is the nearest group. 0
    // means there is none, which PixelSnap_S tests as `group_layer > 0`. The
    // value comes from the numbers callback (doc_aviutl_asked).
    const double v =
        r.numbers
            ? (*r.numbers)(
                  r.file,
                  "aviutl.group" + std::to_string(lua_isnumber(L, 2)
                                                      ? (int)lua_tonumber(L, 2)
                                                      : 0),
                  NAN)
            : NAN;
    lua_pushinteger(L, std::isnan(v) ? 0 : (lua_Integer)v);
  } else if (n == "camera_param") {
    // AviUtl's camera. There is no camera here, so report a default one 1024 in
    // front of the canvas, looking at its centre. sashimono-edit's
    // CAMERA_DISTANCE uses the same 1024.
    lua_newtable(L);
    static const std::pair<const char*, double> camera[] = {
        {"x", 0},  {"y", 0},  {"z", -1024}, {"tx", 0},
        {"ty", 0}, {"tz", 0}, {"rz", 0},    {"d", 1024}};
    for (const auto& [k, v] : camera)
      lua_pushnumber(L, v), lua_setfield(L, -2, k);
  } else
    return aviutl_no(L, "obj.getoption " + n);
  return 1;
}
int aviutl_getinfo(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string n = luaL_checkstring(L, 1);
  // The version of the spec that was read: v2.1.15.
  if (n == "version")
    lua_pushinteger(L, 2011500);
  else if (n == "filter" || n == "saving" || n == "reference_frame")
    lua_pushboolean(L, 0);
  // A layer's image does not grow larger than its box.
  else if (n == "image_max")
    return lua_pushinteger(L, r.bufs["framebuffer"].w),
           lua_pushinteger(L, r.bufs["framebuffer"].h), 2;
  else if (n == "script_path")
    lua_pushstring(
        L,
        (std::filesystem::path(r.file).parent_path().string() + "/").c_str());
  // As many layers as the document has layers (doc_aviutl_asked).
  else if (n == "layer_max")
    lua_pushinteger(
        L, r.numbers ? (lua_Integer)(*r.numbers)(r.file, "aviutl.layer_max", 1)
                     : 1);
  else if (n == "clock")
    lua_pushnumber(L, std::chrono::duration<double>(
                          std::chrono::steady_clock::now().time_since_epoch())
                          .count());
  else
    return aviutl_no(L, "obj.getinfo " + n);
  return 1;
}
int aviutl_getvalue(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  std::string n = lua_isnumber(L, 1) ? std::to_string((int)lua_tonumber(L, 1))
                                     : aviutl_str(L, 1);
  int tracks = 0;
  for (const AviutlVar& v : r.vars)
    if (v.kind == "track" &&
        (n == std::to_string(tracks++) || n == "track." + v.var))
      return aviutl_old(v)
                 ? (lua_getglobal(L, "obj"), lua_getfield(L, -1, v.var.c_str()))
                 : lua_getglobal(L, v.var.c_str()),
             1;
  if (n == "time") return lua_pushnumber(L, r.s->now), 1;
  if (n.rfind("layer", 0) == 0 && r.numbers) {
    // Another layer's value, at a time counted from that layer's start, or nil
    // if there is no such layer. The numbers callback supplies the document's
    // layers (doc_aviutl_asked).
    const double v = (*r.numbers)(
        r.file,
        "aviutl." + n +
            (lua_isnumber(L, 2) ? "@" + std::to_string(lua_tonumber(L, 2))
                                : std::string()),
        NAN);
    return std::isnan(v) ? lua_pushnil(L) : lua_pushnumber(L, v), 1;
  }
  if (n == "x" || n == "y" || n == "z" || n == "rx" || n == "ry" || n == "rz" ||
      n == "cx" || n == "cy" || n == "cz" || n == "aspect")
    return lua_pushnumber(L, 0), 1;
  if (n == "sx" || n == "sy" || n == "sz" || n == "alpha")
    return lua_pushnumber(L, 1), 1;
  if (n == "zoom") return lua_pushnumber(L, 100), 1;
  if (n == "pos" || n == "angle" || n == "center")
    return lua_pushnumber(L, 0), lua_pushnumber(L, 0), lua_pushnumber(L, 0), 3;
  if (n == "scale")
    return lua_pushnumber(L, 1), lua_pushnumber(L, 1), lua_pushnumber(L, 1), 3;
  return aviutl_no(L, "obj.getvalue " + n);
}
int aviutl_getaudio(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  std::string kind = lua_isstring(L, 3) ? lua_tostring(L, 3) : "pcm";
  if (kind.size() > 2 && (kind.ends_with(".l") || kind.ends_with(".r")))
    kind.resize(kind.size() - 2);
  const bool fft = kind != "pcm";
  const int most = kind == "spectrum" ? 512 : 1024,
            count = std::clamp(lua_isnumber(L, 4)   ? (int)lua_tonumber(L, 4)
                               : kind == "spectrum" ? 32
                                                    : 1024,
                               1, most);
  std::vector<float> v =
      aviutl_str(L, 2) == "audiobuffer" && r.sounds && *r.sounds
          ? (*r.sounds)(r.file, "aviutl.audiobuffer", fft,
                        std::min(count, fft ? 512 : 1024))
          : std::vector<float>();
  const bool own = !lua_istable(L, 1);
  if (own) lua_newtable(L);
  const int into = own ? lua_gettop(L) : 1;
  for (size_t i = 0; i < v.size(); ++i)
    lua_pushnumber(L, kind == "pcm"        ? (v[i] - 0.5) * 2 * 32767
                      : kind == "spectrum" ? v[i] * 32768.0
                                           : v[i]),
        lua_rawseti(L, into, (int)i + 1);
  lua_pushinteger(L, (lua_Integer)v.size()), lua_pushinteger(L, 24000);
  if (own) lua_pushvalue(L, into);
  return own ? 3 : 2;
}
int aviutl_data(lua_State* L) { return lua_pushnil(L), 1; }
int aviutl_setanchor(lua_State* L) {
  const int num = std::max(1, (int)aviutl_num(L, 2));
  // A table was passed instead of a name. Leave it as it is.
  if (!lua_isstring(L, 1) || lua_isnumber(L, 1))
    return lua_pushinteger(L, num), 1;
  const std::string name = lua_tostring(L, 1);
  if (name == "track" || name.find(',') != std::string::npos)
    return lua_pushinteger(L, num), 1;
  int dims = 2, mesh = 0, given = 0;
  // True when the points are laid along a line. Otherwise they are laid around
  // the centre.
  bool along = false;
  for (int i = 3; i <= lua_gettop(L); ++i) {
    if (lua_istable(L, i)) given = i;
    if (lua_type(L, i) != LUA_TSTRING) continue;
    const std::string o = lua_tostring(L, i);
    if (o == "xyz")
      dims = 3;
    else if (o == "line")
      along = true;
    else if (o == "mesh" && lua_isnumber(L, i + 1))
      mesh = std::max(1, (int)lua_tonumber(L, i + 1));
  }
  lua_getglobal(L, name.c_str());
  if (!lua_istable(L, -1))
    lua_pop(L, 1), lua_newtable(L), lua_pushvalue(L, -1),
        lua_setglobal(L, name.c_str());
  const int t = lua_gettop(L), want = num * dims, had = (int)lua_objlen(L, t);
  // True when all the points sit on one spot.
  bool one = had == want && num > 1;
  for (int i = 1 + dims; one && i <= want; ++i) {
    lua_rawgeti(L, t, i), lua_rawgeti(L, t, 1 + (i - 1) % dims);
    one = lua_tonumber(L, -1) == lua_tonumber(L, -2);
    lua_pop(L, 2);
  }
  if (had != want && given) {
    for (int i = 1; i <= want; ++i)
      lua_rawgeti(L, given, i), lua_rawseti(L, t, i);
  } else if (had != want || one) {
    lua_getglobal(L, "obj");
    double w = 0, h = 0;
    if (lua_istable(L, -1))
      lua_getfield(L, -1, "screen_w"), lua_getfield(L, -2, "screen_h"),
          w = lua_tonumber(L, -2), h = lua_tonumber(L, -1), lua_pop(L, 2);
    lua_pop(L, 1);
    // Scale by the canvas size, because a layer travels along a path across the
    // canvas. A small layer's own size would make the path a speck.
    const double r = w > 0 && h > 0 ? 0.3 * std::min(w, h) : 100;
    for (int i = 0; i < num; ++i) {
      const double f = num > 1 ? (double)i / (num - 1) : 0.5;
      double x, y;
      if (mesh) {
        const int across = std::min(mesh, num),
                  rows = std::max(1, (num + across - 1) / across);
        x = across > 1 ? -r + 2 * r * (i % across) / (across - 1) : 0,
        y = rows > 1 ? -r + 2 * r * (i / across) / (rows - 1) : 0;
      } else if (along)
        x = -r + 2 * r * f, y = num > 2 ? -0.5 * r * std::sin(2 * M_PI * f) : 0;
      else
        x = r * std::cos(-M_PI / 2 + 2 * M_PI * i / num),
        y = r * std::sin(-M_PI / 2 + 2 * M_PI * i / num);
      const double p[3] = {x, y, 0};
      for (int d = 0; d < dims; ++d)
        lua_pushnumber(L, p[d]), lua_rawseti(L, t, i * dims + d + 1);
    }
  }
  lua_pop(L, 1);
  return lua_pushinteger(L, num), 1;
}
int aviutl_setfont(lua_State* L) {
  auto& f = aviutl_of(L).font;
  f.name = lua_isstring(L, 1) ? lua_tostring(L, 1) : "";
  f.size = aviutl_num(L, 2, 48), f.deco = aviutl_num(L, 3, 0),
  f.colour = aviutl_num(L, 4, 0xffffff), f.edge = aviutl_num(L, 5, 0);
  f.bold = aviutl_num(L, 6) != 0, f.italic = aviutl_num(L, 7) != 0;
  return 0;
}

}  // namespace motolii

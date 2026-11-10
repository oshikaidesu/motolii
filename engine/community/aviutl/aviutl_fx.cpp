#include "community/aviutl/aviutl_fx.h"

#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <lua.hpp>
#include <map>
#include <mutex>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "community/aviutl/aviutl.h"
#include "gpu/screen_interop.h"
#include "stage/render/render_stage.h"

using namespace filament;

const char* const aviutl_placing = R"(
struct K { m: vec4f, at: vec2f, src: vec2f, size: vec2f, alpha: f32, way: f32, colour: vec4f }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  if (k.way == 1.0) { return k.colour; }
  let d = frag.xy - k.at;
  let c = (vec2f(dot(k.m.xy, d), dot(k.m.zw, d)) + k.src) / k.size;
  let w = clamp(c * k.size + 0.5, vec2f(0.0), vec2f(1.0)) * clamp((1.0 - c) * k.size + 0.5, vec2f(0.0), vec2f(1.0));
  var s = textureSampleLevel(sourceTexture, near, c, 0.0);
  if (k.colour.x == 1.0) { s = vec4f(s.rgb * s.a, s.a); }
  s = s * (k.alpha * select(w.x * w.y, 1.0, k.way == 2.0));
  if (k.colour.x == 2.0 && s.a > 0.0) { s = vec4f(s.rgb / s.a, s.a); }
  return s;
}
)";
const char* const aviutl_poly = R"(
struct K { alpha: f32 }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@location(0) uv: vec2f, @location(1) colour: vec4f) -> @location(0) vec4f {
  let seen = textureSampleLevel(sourceTexture, near, uv, 0.0);
  return select(seen, vec4f(1.0), uv.x < -1.0) * colour * k.alpha;   // (a coloured face: its uv off the sourceTexture, its colour alone)
}
)";
const char* const aviutl_blur = R"(
struct K { step: vec2f, radius: f32, unused: f32 }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let at = frag.xy / vec2f(textureDimensions(sourceTexture));
  let sigma = max(k.radius * 0.5, 0.5);
  var sum = textureSampleLevel(sourceTexture, near, at, 0.0);
  var total = 1.0;
  let taps = i32(min(k.radius, 96.0));
  for (var i = 1; i <= taps; i++) {
    let o = f32(i);
    let w = exp(-0.5 * o * o / (sigma * sigma));
    sum += (textureSampleLevel(sourceTexture, near, at + k.step * o, 0.0) + textureSampleLevel(sourceTexture, near, at - k.step * o, 0.0)) * w;
    total += 2.0 * w;
  }
  return sum / total;
}
)";

const char* const aviutl_too_long = "takes longer than 5 s a frame";

namespace {

// Draws `from` onto `to` (w x h pixels) with the placing shader. `k` holds the
// 16 floats of the shader's constants (struct K above). `blend` is -1 to
// replace the target, 0 to draw over it, 1 to add and 2 to mask. `sampler` is
// the interop's sampler mode.
void aviutl_put(AviutlRun& r, Texture* from, RenderTarget* to, uint32_t w,
                uint32_t h, const float* k, int blend = -1, int sampler = 0) {
  const int pass = r.draws[r.place]++;
  interop::parameters(r.s->engine, r.place, k, 64, pass);
  interop::draw(r.s->engine, r.place, &from, to, w, h, pass, nullptr,
                blend >= 0, std::max(blend, 0), sampler);
}
// Returns the HLSL text of the shader registered as `name`, or an empty string
// if there is none. The shader is looked up in this script's text, then in the
// whole file's text. A name of the form "name@script" refers to another script
// in the Script folder, and "name@part@file" to a part of an "@" file. Results
// are cached.
std::string aviutl_hlsl(AviutlRun& r, const std::string& name) {
  if (auto cached = r.hlsls.find(name); cached != r.hlsls.end())
    return cached->second;
  const size_t at = name.find('@');
  const std::string entry = name.substr(0, at),
                    head = "--[[pixelshader@" + entry + ":";
  std::vector<std::string> texts = {r.own, r.all};
  if (at != std::string::npos) {
    const std::string other = name.substr(at + 1),
                      part =
                          other.substr(0, other.rfind('@') == std::string::npos
                                              ? 0
                                              : other.rfind('@')),
                      stem = other.substr(other.rfind('@') + 1);
    std::error_code wrong;
    bool found = false;
    for (const std::filesystem::path& dir : aviutl_shared(
             std::filesystem::path(aviutl_path(r.file)).parent_path())) {
      for (const std::string f : {stem + ".anm2", "@" + stem + ".anm2",
                                  stem + ".obj2", "@" + stem + ".obj2"}) {
        std::string own, all, why;
        if (std::filesystem::exists(dir / f, wrong) &&
            aviutl_text((dir / f).string() + (part.empty() ? "" : "#" + part),
                        own, all, why))
          texts.insert(texts.begin(), own), found = true;
      }
      if (found) break;
    }
  }
  for (const std::string& t : texts)
    if (const size_t p = t.find(head); p != std::string::npos)
      return r.hlsls[name] =
                 t.substr(p + head.size(), t.find("]]", p) - p - head.size());
  return r.hlsls[name] = "";
}

}  // namespace

void aviutl_late(lua_State* L, lua_Debug*) {
  lua_getfield(L, LUA_REGISTRYINDEX, "motolii.run");
  const AviutlRun* r = (const AviutlRun*)lua_touserdata(L, -1);
  lua_pop(L, 1);
  if (r && std::chrono::steady_clock::now() > r->until)
    lua_sethook(L, aviutl_late, LUA_MASKLINE, 0),
        luaL_error(L, "%s", aviutl_too_long);
}
AviutlRun& aviutl_of(lua_State* L) {
  AviutlRun& r = *(AviutlRun*)lua_touserdata(L, lua_upvalueindex(1));
  if (std::chrono::steady_clock::now() > r.until)
    luaL_error(L, "%s", aviutl_too_long);
  return r;
}
std::string aviutl_name(std::string n) {
  return n == "obj"   ? "object"
         : n == "tmp" ? "tempbuffer"
         : n == "frm" ? "framebuffer"
                      : n;
}
AviutlBuf& aviutl_buf(AviutlRun& r, const std::string& name, uint32_t w,
                      uint32_t h) {
  AviutlBuf& b = r.bufs[aviutl_name(name)];
  w = std::clamp<uint32_t>(w ? w : b.w, 1, 8192),
  h = std::clamp<uint32_t>(h ? h : b.h, 1, 8192);
  if (b.t && b.w == w && b.h == h) return b;
  if (b.t) r.spare.insert({{b.w, b.h}, b});
  if (const auto cached = r.spare.find({w, h}); cached != r.spare.end())
    return b = cached->second, r.spare.erase(cached), b;
  b.w = w, b.h = h;
  b.t =
      Texture::Builder()
          .width(w)
          .height(h)
          .levels(1)
          .format(Texture::InternalFormat::RGBA16F)
          .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
          .build(*r.s->engine);
  b.rt = RenderTarget::Builder()
             .texture(RenderTarget::AttachmentPoint::COLOR, b.t)
             .build(*r.s->engine);
  return b;
}
void aviutl_lay(AviutlRun& r, const AviutlBuf& from, RenderTarget* to,
                uint32_t w, uint32_t h, double ox, double oy, double sx,
                double sy, double rz, double alpha, double cx, double cy,
                int blend, int sampler, float way, float as) {
  const double a = rz * M_PI / 180, co = std::cos(a), si = std::sin(a);
  const float k[16] = {(float)(co / sx),
                       (float)(si / sx),
                       (float)(-si / sy),
                       (float)(co / sy),
                       (float)(w / 2.0 + ox),
                       (float)(h / 2.0 + oy),
                       (float)(from.w / 2.0 + cx),
                       (float)(from.h / 2.0 + cy),
                       (float)from.w,
                       (float)from.h,
                       (float)alpha,
                       way,
                       as,
                       0,
                       0,
                       0};
  aviutl_put(r, from.t, to, w, h, k, blend, sampler);
}
void aviutl_copy(AviutlRun& r, const std::string& to, const std::string& from) {
  const AviutlBuf f = aviutl_buf(r, from);
  const AviutlBuf& t = aviutl_buf(r, to, f.w, f.h);
  aviutl_lay(r, f, t.rt, t.w, t.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
}
void aviutl_clear(AviutlRun& r, const AviutlBuf& b, double colour,
                  bool opaque) {
  const int c = (int)colour;
  const float k[16] = {1,
                       0,
                       0,
                       1,
                       0,
                       0,
                       0,
                       0,
                       1,
                       1,
                       0,
                       1,
                       opaque ? ((c >> 16) & 255) / 255.f : 0,
                       opaque ? ((c >> 8) & 255) / 255.f : 0,
                       opaque ? (c & 255) / 255.f : 0,
                       opaque ? 1.f : 0};
  aviutl_put(r, r.none, b.rt, b.w, b.h, k);
}
bool aviutl_old(const AviutlVar& v) {
  return !v.named && v.var.size() == 6 &&
         (v.var.rfind("track", 0) == 0 || v.var.rfind("check", 0) == 0) &&
         std::isdigit((unsigned char)v.var[5]);
}
int aviutl_no(lua_State* L, const std::string& what) {
  return luaL_error(L, "not yet: %s", what.c_str());
}
std::string aviutl_str(lua_State* L, int i) {
  return lua_type(L, i) == LUA_TSTRING ? lua_tostring(L, i) : "";
}
double aviutl_num(lua_State* L, int i, double otherwise) {
  return lua_isnumber(L, i)    ? lua_tonumber(L, i)
         : lua_isboolean(L, i) ? lua_toboolean(L, i)
                               : otherwise;
}
std::vector<std::filesystem::path> aviutl_shared(
    const std::filesystem::path& dir) {
  static std::mutex hold;
  static std::map<std::filesystem::path,
                  std::pair<std::filesystem::file_time_type,
                            std::vector<std::filesystem::path>>>
      cached;
  std::vector<std::filesystem::path> dirs = {dir};
  for (std::filesystem::path p = dir;
       p.has_relative_path() && p != p.parent_path(); p = p.parent_path()) {
    if (p.parent_path().filename() != "aviutl_scripts") continue;
    std::error_code wrong;
    const std::filesystem::path root = p.parent_path();
    const auto when = std::filesystem::last_write_time(root, wrong);
    std::lock_guard<std::mutex> one(hold);
    auto& [built, all] = cached[root];
    if (all.empty() || built != when) {
      all.clear(), built = when;
      for (const auto& e : std::filesystem::directory_iterator(root, wrong))
        if (std::filesystem::is_directory(e.path() / "Script", wrong))
          all.push_back(e.path() / "Script");
      std::sort(all.begin(), all.end());
    }
    for (const auto& d : all)
      if (d != dir) dirs.push_back(d);
    break;
  }
  return dirs;
}
interop::Screen* aviutl_interop(AviutlRun& r, const std::string& name,
                                bool clip, std::string& why,
                                const AviutlShader** built) {
  const std::string hlsl = aviutl_hlsl(r, name),
                    entry = name.substr(0, name.find('@'));
  if (hlsl.empty()) return why = "no pixelshader@" + name, nullptr;
  const AviutlShader& sh = aviutl_shader(hlsl, entry, clip);
  if (built) *built = &sh;
  interop::Screen*& d = r.interops[name + (clip ? "|clip" : "")];
  if (!d && sh.wgsl.empty()) return why = sh.why, nullptr;
  if (!d)
    d = interop::screen(r.s->engine, entry.c_str(), sh.wgsl.c_str(), sh.bytes,
                        &why, sh.textureCount);
  return d;
}

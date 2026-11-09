// aviutl_fx.h: an AviUtl2 script (aviutl.h) as one of a thing's effects, run as it is on the thing's picture each frame:
// LuaJIT 2.1 (MIT, AviUtl2's own default Lua) with os, io, debug, ffi.C and ffi.load taken out as lua.txt says, and an
// `obj` of its spec's names, each done by what Motolii already has: its buffers ("object", "tempbuffer", "cache:...",
// "framebuffer": the thing's own picture as it leaves) RGBA16F pictures premultiplied as AviUtl2's, its shaders drawn
// by the interop (screen_interop.h), obj.draw by one placing shader. What it asks for that is not here stops it with
// "not yet: obj.X" (said once, its picture left as it came): never a picture silently other than the script's.
#pragma once
#include "community/aviutl/aviutl.h"
#include <lua.hpp>
#include <array>
#include <mutex>
#include <optional>
#include <random>
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"

struct AviutlBuf { Texture* t = nullptr; RenderTarget* rt = nullptr; uint32_t w = 0, h = 0; };
struct AviutlCalled { int chunk = LUA_NOREF; std::vector<AviutlVar> vars; std::map<std::string, double> usual; };   // (a script of its file it runs by name: aviutl_called)
struct AviutlRun {
    std::string file, own, all, trouble;
    std::vector<AviutlVar> vars;
    std::map<std::string, double> usual;            // (each parameter's value as it comes)
    lua_State* L = nullptr;                         // (the one of the thing's scripts: aviutl_made)
    int chunk = LUA_NOREF, obj = LUA_NOREF;         // (its text made a function, and its obj, in L)
    std::string path;                               // (where its require looks: package.path while it runs)
    std::map<std::string, AviutlBuf> bufs;
    std::map<std::string, AviutlBuf> loaded;        // (figures and picture files obj.load drew, by what was asked: aviutl_load.h)
    std::multimap<std::pair<uint32_t, uint32_t>, AviutlBuf> spare;   // (pictures let go, kept by size for the next asked: a buffer made and let go each frame takes the same ones)
    std::map<std::string, interop::Screen*> interops;     // (each shader made, by its name and way of sampling)
    std::map<std::string, std::string> hlsls;       // (each shader's text by its registered name, found once: aviutl_hlsl, asked each frame)
    std::map<interop::Screen*, int> draws;             // (draws of each this frame: each its own constants, the interop's pass)
    interop::Screen *place = nullptr, *poly = nullptr, *blur = nullptr;
    Texture *none = nullptr, *random = nullptr;
    std::set<std::string> said;
    std::chrono::steady_clock::time_point until = std::chrono::steady_clock::time_point::max();   // (this frame's run stopped past it: aviutl_late)
    std::optional<std::string> late;                // (the parameters' values it ran past that with: not run again with them; none yet, so one of no parameters runs)
    Stage* s = nullptr;                             // (this frame's)
    std::string target, blend, sampler;
    bool drew = false;
    bool behind = false;                            // (it reads the frame: the stage behind the thing, as AviUtl2's framebuffer holds what is drawn before it)
    double box[4] = {0, 0, 0, 0};                   // (where the thing is seen, points of the stage: its frame is that of the stage's)
    int ground = -1;                                // (the stage's colour behind everything, 0xRRGGBB; -1 none)
    bool wide = false;                              // (it draws the object (obj.draw, drawpoly): its frame the stage's, the object the thing's own picture where it is seen)
    const ScreenNumbers* numbers = nullptr;         // (this frame's: what it asks of the other things, the document's answers (document/moment_fx.h doc_aviutl_asked))
    const std::function<std::vector<float>(const std::string&, const std::string&, bool, int)>* sounds = nullptr;   // (the thing's: the sound heard now, ScreenStack's sounds)
    std::vector<std::string> chain;                 // (the effects on the thing in their order, by name, and which is this one: obj.getoption "script_name")
    std::string pixelFrom = "object", pixelType = "col";   // (what obj.getpixel reads, and how it tells a pixel: obj.pixeloption)
    std::vector<uint8_t> pixelSeen;                 // (that buffer read back, once, till pixeloption "get" again: aviutl_pixels.h)
    uint32_t pixelW = 0, pixelH = 0;
    bool pixelRead = false;
    int at = 0;
    double seen[4] = {0, 0, 0, 0};                  // (then where the thing is seen, points of the stage)
    std::map<std::string, ScreenFx*> isf;           // (Sashimono's remakes of AviUtl's built-in effects it ran, by their files: aviutl_sashimono)
    ScreenStack isfStack;
    struct { std::string name; double size = 48, deco = 0, colour = 0xffffff, edge = 0; bool bold = false, italic = false; } font;   // (obj.setfont's, for obj.load "text": aviutl_load.h)
    std::set<std::string> worded;                   // (the words drawn this frame: those not drawn again let go the next, a clock's every second its own)
    std::map<std::string, AviutlCalled> called;     // (the scripts of its file it ran by name (obj.effect), by their names)
};

// The placing shader: a picture (`size` pixels) put with its pixel `from` at `at` of the target, turned and sized by
// `m` (the target's step back to the picture's), faded by alpha; past its edge clear (AviUtl2's sampler "clip", as
// aviutl.cpp's), or not (way 2); way 1: the colour alone (a buffer cleared to it); otherwise colour.x 1: read straight
// and made premultiplied (a thing's picture, straight as Motolii's effects keep it: effected.mat), 2: made straight again.
static const char* const aviutl_placing = R"(
struct K { m: vec4f, at: vec2f, src: vec2f, size: vec2f, alpha: f32, way: f32, colour: vec4f }
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  if (k.way == 1.0) { return k.colour; }
  let d = frag.xy - k.at;
  let c = (vec2f(dot(k.m.xy, d), dot(k.m.zw, d)) + k.src) / k.size;
  let w = clamp(c * k.size + 0.5, vec2f(0.0), vec2f(1.0)) * clamp((1.0 - c) * k.size + 0.5, vec2f(0.0), vec2f(1.0));
  var s = textureSampleLevel(picture, near, c, 0.0);
  if (k.colour.x == 1.0) { s = vec4f(s.rgb * s.a, s.a); }
  s = s * (k.alpha * select(w.x * w.y, 1.0, k.way == 2.0));
  if (k.colour.x == 2.0 && s.a > 0.0) { s = vec4f(s.rgb / s.a, s.a); }
  return s;
}
)";
// obj.drawpoly's: the picture on triangles (the interop's mesh), at each corner's uv, or each corner's colour, faded by alpha.
static const char* const aviutl_poly = R"(
struct K { alpha: f32 }
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@location(0) uv: vec2f, @location(1) colour: vec4f) -> @location(0) vec4f {
  let seen = textureSampleLevel(picture, near, uv, 0.0);
  return select(seen, vec4f(1.0), uv.x < -1.0) * colour * k.alpha;   // (a coloured face: its uv off the picture, its colour alone)
}
)";
// obj.effect ぼかし's: sashimono-edit's blur1d (MIT, effects/builtin.py), one way a pass: the pixel and `radius` either
// side (96 at most) weighed by a Gaussian of half the radius; the buffer premultiplied already, as its premul makes it.
static const char* const aviutl_blur = R"(
struct K { step: vec2f, radius: f32, unused: f32 }
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let at = frag.xy / vec2f(textureDimensions(picture));
  let sigma = max(k.radius * 0.5, 0.5);
  var sum = textureSampleLevel(picture, near, at, 0.0);
  var total = 1.0;
  let taps = i32(min(k.radius, 96.0));
  for (var i = 1; i <= taps; i++) {
    let o = f32(i);
    let w = exp(-0.5 * o * o / (sigma * sigma));
    sum += (textureSampleLevel(picture, near, at + k.step * o, 0.0) + textureSampleLevel(picture, near, at - k.step * o, 0.0)) * w;
    total += 2.0 * w;
  }
  return sum / total;
}
)";

// A frame's run stopped once it takes longer than Redis's own limit for a script (lua-time-limit, 5000 ms), as Redis
// stops one (script_lua.c luaMaskCountHook: a count hook every 100000 instructions, then every line so a pcall cannot
// keep it going). LuaJIT calls no hook inside a loop it has compiled (measured, 11/4: `while true do cf() end` never
// stopped), so each obj call looks too: a script stuck asking obj (as one in obj.getvalue held the tiles) stops there.
static const char* const aviutl_too_long = "takes longer than 5 s a frame";
static void aviutl_late(lua_State* L, lua_Debug*) {
    lua_getfield(L, LUA_REGISTRYINDEX, "motolii.run");
    const AviutlRun* r = (const AviutlRun*)lua_touserdata(L, -1);
    lua_pop(L, 1);
    if (r && std::chrono::steady_clock::now() > r->until) lua_sethook(L, aviutl_late, LUA_MASKLINE, 0), luaL_error(L, "%s", aviutl_too_long);
}
static AviutlRun& aviutl_of(lua_State* L) {
    AviutlRun& r = *(AviutlRun*)lua_touserdata(L, lua_upvalueindex(1));
    if (std::chrono::steady_clock::now() > r.until) luaL_error(L, "%s", aviutl_too_long);
    return r;
}
static std::string aviutl_name(std::string n) { return n == "obj" ? "object" : n == "tmp" ? "tempbuffer" : n == "frm" ? "framebuffer" : n; }
static AviutlBuf& aviutl_buf(AviutlRun& r, const std::string& name, uint32_t w = 0, uint32_t h = 0) {   // (w, h: made that size)
    AviutlBuf& b = r.bufs[aviutl_name(name)];
    w = std::clamp<uint32_t>(w ? w : b.w, 1, 8192), h = std::clamp<uint32_t>(h ? h : b.h, 1, 8192);
    if (b.t && b.w == w && b.h == h) return b;
    if (b.t) r.spare.insert({{b.w, b.h}, b});
    if (const auto kept = r.spare.find({w, h}); kept != r.spare.end()) return b = kept->second, r.spare.erase(kept), b;
    b.w = w, b.h = h;
    b.t = Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA16F).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*r.s->engine);
    b.rt = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, b.t).build(*r.s->engine);
    return b;
}
// One placing (blend: -1 in its place, 0 over, 1 added, 2 masked; sampler as the interop's), parameters as the struct above.
static void aviutl_put(AviutlRun& r, Texture* from, RenderTarget* to, uint32_t w, uint32_t h, const float* k, int blend = -1, int sampler = 0) {
    const int pass = r.draws[r.place]++;
    interop::parameters(r.s->engine, r.place, k, 64, pass);
    interop::draw(r.s->engine, r.place, &from, to, w, h, pass, nullptr, blend >= 0, std::max(blend, 0), sampler);
}
// A picture laid on another: its middle (+ c, its own centre) at the target's middle + o, zoomed (sx, sy) and turned rz degrees.
static void aviutl_lay(AviutlRun& r, const AviutlBuf& from, RenderTarget* to, uint32_t w, uint32_t h, double ox, double oy, double sx, double sy, double rz, double alpha, double cx, double cy, int blend, int sampler, float way = 0, float as = 0) {
    const double a = rz * M_PI / 180, co = std::cos(a), si = std::sin(a);
    const float k[16] = {(float)(co / sx), (float)(si / sx), (float)(-si / sy), (float)(co / sy), (float)(w / 2.0 + ox), (float)(h / 2.0 + oy), (float)(from.w / 2.0 + cx), (float)(from.h / 2.0 + cy), (float)from.w, (float)from.h, (float)alpha, way, as, 0, 0, 0};
    aviutl_put(r, from.t, to, w, h, k, blend, sampler);
}
static void aviutl_copy(AviutlRun& r, const std::string& to, const std::string& from) {
    const AviutlBuf f = aviutl_buf(r, from);
    const AviutlBuf& t = aviutl_buf(r, to, f.w, f.h);
    aviutl_lay(r, f, t.rt, t.w, t.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
}
static void aviutl_clear(AviutlRun& r, const AviutlBuf& b, double colour, bool opaque) {
    const int c = (int)colour;
    const float k[16] = {1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, opaque ? ((c >> 16) & 255) / 255.f : 0, opaque ? ((c >> 8) & 255) / 255.f : 0, opaque ? (c & 255) / 255.f : 0, opaque ? 1.f : 0};
    aviutl_put(r, r.none, b.rt, b.w, b.h, k);
}
static bool aviutl_old(const AviutlVar& v) { return !v.named && v.var.size() == 6 && (v.var.rfind("track", 0) == 0 || v.var.rfind("check", 0) == 0) && std::isdigit((unsigned char)v.var[5]); }   // (--track0: is obj.track0)
static int aviutl_no(lua_State* L, const std::string& what) { return luaL_error(L, "not yet: %s", what.c_str()); }
static std::string aviutl_str(lua_State* L, int i) { return lua_type(L, i) == LUA_TSTRING ? lua_tostring(L, i) : ""; }
static double aviutl_num(lua_State* L, int i, double otherwise = 0) { return lua_isnumber(L, i) ? lua_tonumber(L, i) : lua_isboolean(L, i) ? lua_toboolean(L, i) : otherwise; }
// AviUtl2's one Script folder: an .au2pkg's Script/ goes into it beside every other package's (its package.ini), so a
// script finds another package's module (require) and shaders ("name@part@file") there, as HexScript's
// 色差領域塗りつぶし requires σ軸's Region_S.lua and calls @Region_S.anm2's shaders. Here each package keeps its own
// folder (aviutl_scripts/<package>/Script): these are those folders, the script's own first (read again when a
// package is put in: the folder's time).
static std::vector<std::filesystem::path> aviutl_shared(const std::filesystem::path& dir) {
    static std::mutex hold;
    static std::map<std::filesystem::path, std::pair<std::filesystem::file_time_type, std::vector<std::filesystem::path>>> kept;
    std::vector<std::filesystem::path> dirs = {dir};
    for (std::filesystem::path p = dir; p.has_relative_path() && p != p.parent_path(); p = p.parent_path()) {
        if (p.parent_path().filename() != "aviutl_scripts") continue;
        std::error_code wrong;
        const std::filesystem::path root = p.parent_path();
        const auto when = std::filesystem::last_write_time(root, wrong);
        std::lock_guard<std::mutex> one(hold);
        auto& [made, all] = kept[root];
        if (all.empty() || made != when) {
            all.clear(), made = when;
            for (const auto& e : std::filesystem::directory_iterator(root, wrong))
                if (std::filesystem::is_directory(e.path() / "Script", wrong)) all.push_back(e.path() / "Script");
            std::sort(all.begin(), all.end());
        }
        for (const auto& d : all) if (d != dir) dirs.push_back(d);
        break;
    }
    return dirs;
}
static std::string aviutl_hlsl(AviutlRun& r, const std::string& name) {   // (a shader by its registered name: this script's, this file's, or "name@script" another's in the Script folder ("name@part@file": a part of an @ file))
    if (auto kept = r.hlsls.find(name); kept != r.hlsls.end()) return kept->second;
    const size_t at = name.find('@');
    const std::string entry = name.substr(0, at), head = "--[[pixelshader@" + entry + ":";
    std::vector<std::string> texts = {r.own, r.all};
    if (at != std::string::npos) {
        const std::string other = name.substr(at + 1), part = other.substr(0, other.rfind('@') == std::string::npos ? 0 : other.rfind('@')), stem = other.substr(other.rfind('@') + 1);
        std::error_code wrong;
        bool found = false;
        for (const std::filesystem::path& dir : aviutl_shared(std::filesystem::path(aviutl_path(r.file)).parent_path())) {
            for (const std::string f : {stem + ".anm2", "@" + stem + ".anm2", stem + ".obj2", "@" + stem + ".obj2"}) {
                std::string own, all, why;
                if (std::filesystem::exists(dir / f, wrong) && aviutl_text((dir / f).string() + (part.empty() ? "" : "#" + part), own, all, why)) texts.insert(texts.begin(), own), found = true;
            }
            if (found) break;
        }
    }
    for (const std::string& t : texts)
        if (const size_t p = t.find(head); p != std::string::npos) return r.hlsls[name] = t.substr(p + head.size(), t.find("]]", p) - p - head.size());
    return r.hlsls[name] = "";
}
static interop::Screen* aviutl_interop(AviutlRun& r, const std::string& name, bool clip, std::string& why, const AviutlShader** made = nullptr) {
    const std::string hlsl = aviutl_hlsl(r, name), entry = name.substr(0, name.find('@'));
    if (hlsl.empty()) return why = "no pixelshader@" + name, nullptr;
    const AviutlShader& sh = aviutl_shader(hlsl, entry, clip);
    if (made) *made = &sh;
    interop::Screen*& d = r.interops[name + (clip ? "|clip" : "")];
    if (!d && sh.wgsl.empty()) return why = sh.why, nullptr;
    if (!d) d = interop::screen(r.s->engine, entry.c_str(), sh.wgsl.c_str(), sh.bytes, &why, sh.pictures);
    return d;
}

// (the rest, each a part read only through here, in this order)
#include "community/aviutl/aviutl_obj.h"
#include "community/aviutl/aviutl_obj_draw.h"
#include "community/aviutl/aviutl_obj_effect.h"
#include "community/aviutl/aviutl_run.h"

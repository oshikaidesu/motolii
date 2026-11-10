// Runs an AviUtl2 script (see aviutl.h) as one of a layer's effects. Included by
// stage/effects/layer_fx.h; not self-contained.
//
// The script runs as written on the layer's image every frame, in LuaJIT 2.1 (MIT, the Lua that
// AviUtl2 uses by default) with os, io, debug, ffi.C and ffi.load removed, as lua.txt specifies.
// The `obj` table has the names of the AviUtl2 specification, each implemented with what Motolii
// already has:
//   - The buffers ("object", "tempbuffer", "cache:..." and "framebuffer", which holds the layer's
//     own image as it leaves the effect) are premultiplied RGBA16F images, as in AviUtl2.
//   - Shaders are drawn by the interop (screen_interop.h).
//   - obj.draw uses one placing shader.
// A call the script makes that is not implemented stops the script with "not yet: obj.X", reported
// once, and leaves the image as it came in. The result is never an image that silently differs
// from what the script would produce.
#pragma once
#include "community/aviutl/aviutl.h"
#include <lua.hpp>
#include <array>
#include <mutex>
#include <optional>
#include <random>
#include "base/json.h"

// An image buffer: its texture `t`, the render target `rt` for drawing into it, and its size in
// pixels.
struct AviutlBuf { Texture* t = nullptr; RenderTarget* rt = nullptr; uint32_t w = 0, h = 0; };
// A script of the same file that the running script invoked by name (obj.effect); see
// aviutl_called. Holds its compiled chunk, its variables and their current values.
struct AviutlCalled { int chunk = LUA_NOREF; std::vector<AviutlVar> vars; std::map<std::string, double> usual; };
// The state of one script attached to one layer: its text and parameters, its Lua state, its
// buffers and shaders, and the state of the frame being drawn.
struct AviutlRun {
    // The script's name (see aviutl.h), the text of the script itself, the text of the whole file,
    // and the last error message.
    std::string file, own, all, trouble;
    std::vector<AviutlVar> vars;
    // The current value of each parameter, by variable name.
    std::map<std::string, double> usual;
    // The Lua state shared by the layer's scripts. Created by aviutl_open.
    lua_State* L = nullptr;
    // Registry references in L to the script's compiled function and to its obj table.
    int chunk = LUA_NOREF, obj = LUA_NOREF;
    // Where require looks for modules; set as package.path while the script runs.
    std::string path;
    std::map<std::string, AviutlBuf> bufs;
    // Figures and image files drawn by obj.load, by request (aviutl_load.h).
    std::map<std::string, AviutlBuf> loaded;
    // Released buffers kept by size for reuse. A script that creates and releases a buffer every
    // frame gets the same buffers back.
    std::multimap<std::pair<uint32_t, uint32_t>, AviutlBuf> spare;
    // The shaders already built, by name and sampling mode.
    std::map<std::string, interop::Screen*> interops;
    // The HLSL text of each shader by its registered name. It is looked up once (aviutl_hlsl) and
    // needed every frame.
    std::map<std::string, std::string> hlsls;
    // Number of draws made with each shader this frame. Each draw has its own constants, selected
    // by the interop's pass index.
    std::map<interop::Screen*, int> draws;
    // The shaders for placing images (aviutl_placing), for drawing polygons (aviutl_poly) and for
    // blurring (aviutl_blur).
    interop::Screen *place = nullptr, *poly = nullptr, *blur = nullptr;
    // An empty texture for draws that read no image, and the noise texture that obj.pixelshader
    // supplies for a resource named "random".
    Texture *none = nullptr, *random = nullptr;
    // Error messages already reported on stderr, so each is reported once.
    std::set<std::string> said;
    // The deadline for this frame's run; the script is stopped after it (aviutl_late).
    std::chrono::steady_clock::time_point until = std::chrono::steady_clock::time_point::max();
    // The parameter values with which the script exceeded the time limit; it is not run again with
    // the same values. Empty until such a run happens. It is an optional so that a script without
    // parameters, whose value string is empty, can be told apart from "none yet".
    std::optional<std::string> late;
    // The stage being drawn this frame.
    Stage* s = nullptr;
    std::string target, blend, sampler;
    bool drew = false;
    // True if the script reads the frame: the stage behind the layer, as AviUtl2's framebuffer
    // holds what was drawn before the layer.
    bool behind = false;
    // The region of the stage covered by the layer's effect image, as {x0, y0, x1, y1} in stage
    // points.
    double box[4] = {0, 0, 0, 0};
    // The stage's background color behind everything as 0xRRGGBB, or -1 if there is none.
    int ground = -1;
    // True if the script draws the object (obj.draw, drawpoly). Its coordinate frame is then the
    // stage's, and the object is the layer's own image placed where the layer is seen.
    bool wide = false;
    // This frame's answers to what the script asks about other layers, supplied by the
    // document through doc_aviutl_asked in document/moment_fx.h.
    const ScreenNumbers* numbers = nullptr;
    // Callback that supplies the sound heard now for the layer (ScreenStack's sounds).
    const std::function<std::vector<float>(const std::string&, const std::string&, bool, int)>* sounds = nullptr;
    // The names of the effects on the layer in order, and the position of this script in them, for
    // obj.getoption "script_name".
    std::vector<std::string> chain;
    // The buffer that obj.getpixel reads and the format in which it returns a pixel; both are set
    // by obj.pixeloption.
    std::string pixelFrom = "object", pixelType = "col";
    // That buffer read back once and kept until obj.pixeloption "get" is called again;
    // see aviutl_pixels.h.
    std::vector<uint8_t> pixelSeen;
    uint32_t pixelW = 0, pixelH = 0;
    bool pixelRead = false;
    int at = 0;
    // The part of `box` where the layer itself is visible, in stage points.
    double seen[4] = {0, 0, 0, 0};
    // sashimono-edit's remakes of AviUtl's built-in effects that this script has run, by file;
    // see aviutl_sashimono.
    std::map<std::string, ScreenFx*> isf;
    ScreenStack isfStack;
    // The font set by obj.setfont, used by obj.load "text" (aviutl_load.h).
    struct { std::string name; double size = 48, deco = 0, colour = 0xffffff, edge = 0; bool bold = false, italic = false; } font;
    // The keys of the text images drawn this frame. Text images not drawn again are released the
    // next frame; a clock that changes every second makes a new image each second.
    std::set<std::string> worded;
    // The other scripts of the same file that this script has run by name (obj.effect).
    std::map<std::string, AviutlCalled> called;
};

// The placing shader. It draws an image onto the target so that the image's pixel `src` lands at
// `at` of the target, rotated and scaled by `m` (the matrix that takes target pixels back to image
// pixels), and faded by `alpha`. Outside the image's edge the result is transparent (AviUtl2's
// "clip" sampler, as in aviutl.cpp), except in way 2, where the edge is not clipped. Way 1 outputs
// the plain color, which is how a buffer is cleared. Otherwise colour.x selects a conversion: 1
// reads straight alpha and makes it premultiplied (a layer's image is straight, as Motolii's
// effects keep it), and 2 makes it straight again.
static const char* const aviutl_placing = R"(
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
// The shader for obj.drawpoly: draws the image on triangles (the interop's mesh), sampled at each
// corner's uv, or in each corner's color for a face with no image (uv.x below -1), faded by alpha.
static const char* const aviutl_poly = R"(
struct K { alpha: f32 }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@location(0) uv: vec2f, @location(1) colour: vec4f) -> @location(0) vec4f {
  let seen = textureSampleLevel(sourceTexture, near, uv, 0.0);
  return select(seen, vec4f(1.0), uv.x < -1.0) * colour * k.alpha;   // (a coloured face: its uv off the sourceTexture, its colour alone)
}
)";
// The shader for the blur effect of obj.effect: a copy of sashimono-edit's blur1d (MIT,
// effects/builtin.py). Each pass blurs along one axis: it sums the pixel and up to `radius`
// pixels (at most 96) on each side, weighted by a Gaussian whose sigma is half the radius. The
// buffer is already premultiplied, as its premul step makes it.
static const char* const aviutl_blur = R"(
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

// A frame's run is stopped once it takes longer than Redis allows a script (lua-time-limit,
// 5000 ms). Redis does this with a count hook every 100000 instructions, then a line hook so
// that a pcall cannot keep the script going (script_lua.c, luaMaskCountHook). LuaJIT calls no
// hook inside a loop it has compiled (`while true do cf() end` never stopped when measured), so
// every obj call also checks the deadline. That stops a script stuck inside an obj call such as
// obj.getvalue.
static const char* const aviutl_too_long = "takes longer than 5 s a frame";
// Debug hook that raises a Lua error once this frame's deadline (r->until) has passed. It then
// switches to a line hook, so that a pcall cannot swallow the error and keep the script running.
static void aviutl_late(lua_State* L, lua_Debug*) {
    lua_getfield(L, LUA_REGISTRYINDEX, "motolii.run");
    const AviutlRun* r = (const AviutlRun*)lua_touserdata(L, -1);
    lua_pop(L, 1);
    if (r && std::chrono::steady_clock::now() > r->until) lua_sethook(L, aviutl_late, LUA_MASKLINE, 0), luaL_error(L, "%s", aviutl_too_long);
}
// Returns the AviutlRun bound to the running obj function as its first upvalue. Raises a Lua
// error if the deadline has passed.
static AviutlRun& aviutl_of(lua_State* L) {
    AviutlRun& r = *(AviutlRun*)lua_touserdata(L, lua_upvalueindex(1));
    if (std::chrono::steady_clock::now() > r.until) luaL_error(L, "%s", aviutl_too_long);
    return r;
}
// Maps the short buffer names obj, tmp and frm to "object", "tempbuffer" and "framebuffer". Any
// other name is returned unchanged.
static std::string aviutl_name(std::string n) { return n == "obj" ? "object" : n == "tmp" ? "tempbuffer" : n == "frm" ? "framebuffer" : n; }
// Returns the buffer called `name`, creating it or resizing it to w x h. A size of 0 keeps the
// current size, and sizes are clamped to 1..8192. A buffer replaced by one of another size goes
// to r.spare for reuse.
static AviutlBuf& aviutl_buf(AviutlRun& r, const std::string& name, uint32_t w = 0, uint32_t h = 0) {
    AviutlBuf& b = r.bufs[aviutl_name(name)];
    w = std::clamp<uint32_t>(w ? w : b.w, 1, 8192), h = std::clamp<uint32_t>(h ? h : b.h, 1, 8192);
    if (b.t && b.w == w && b.h == h) return b;
    if (b.t) r.spare.insert({{b.w, b.h}, b});
    if (const auto cached = r.spare.find({w, h}); cached != r.spare.end()) return b = cached->second, r.spare.erase(cached), b;
    b.w = w, b.h = h;
    b.t = Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA16F).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*r.s->engine);
    b.rt = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, b.t).build(*r.s->engine);
    return b;
}
// Draws `from` onto `to` (w x h pixels) with the placing shader. `k` holds the 16 floats of the
// shader's constants (struct K above). `blend` is -1 to replace the target, 0 to draw over it, 1 to
// add and 2 to mask. `sampler` is the interop's sampler mode.
static void aviutl_put(AviutlRun& r, Texture* from, RenderTarget* to, uint32_t w, uint32_t h, const float* k, int blend = -1, int sampler = 0) {
    const int pass = r.draws[r.place]++;
    interop::parameters(r.s->engine, r.place, k, 64, pass);
    interop::draw(r.s->engine, r.place, &from, to, w, h, pass, nullptr, blend >= 0, std::max(blend, 0), sampler);
}
// Lays `from` onto a target of w x h pixels. The image's center, moved by (cx, cy), goes to the
// target's center moved by (ox, oy). The image is scaled by (sx, sy), rotated by rz degrees and
// faded by alpha. `way` and `as` are the shader's way and colour.x. See aviutl_put for `blend`
// and `sampler`.
static void aviutl_lay(AviutlRun& r, const AviutlBuf& from, RenderTarget* to, uint32_t w, uint32_t h, double ox, double oy, double sx, double sy, double rz, double alpha, double cx, double cy, int blend, int sampler, float way = 0, float as = 0) {
    const double a = rz * M_PI / 180, co = std::cos(a), si = std::sin(a);
    const float k[16] = {(float)(co / sx), (float)(si / sx), (float)(-si / sy), (float)(co / sy), (float)(w / 2.0 + ox), (float)(h / 2.0 + oy), (float)(from.w / 2.0 + cx), (float)(from.h / 2.0 + cy), (float)from.w, (float)from.h, (float)alpha, way, as, 0, 0, 0};
    aviutl_put(r, from.t, to, w, h, k, blend, sampler);
}
// Copies buffer `from` into buffer `to`, resizing `to` to match.
static void aviutl_copy(AviutlRun& r, const std::string& to, const std::string& from) {
    const AviutlBuf f = aviutl_buf(r, from);
    const AviutlBuf& t = aviutl_buf(r, to, f.w, f.h);
    aviutl_lay(r, f, t.rt, t.w, t.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
}
// Fills buffer `b` with the color `colour` (0xRRGGBB) if `opaque`, otherwise with transparent
// pixels.
static void aviutl_clear(AviutlRun& r, const AviutlBuf& b, double colour, bool opaque) {
    const int c = (int)colour;
    const float k[16] = {1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, opaque ? ((c >> 16) & 255) / 255.f : 0, opaque ? ((c >> 8) & 255) / 255.f : 0, opaque ? (c & 255) / 255.f : 0, opaque ? 1.f : 0};
    aviutl_put(r, r.none, b.rt, b.w, b.h, k);
}
// Returns true for a variable declared in the old numbered form (--track0:, --check0:), which the
// script reads as obj.track0 rather than as a named variable.
static bool aviutl_old(const AviutlVar& v) { return !v.named && v.var.size() == 6 && (v.var.rfind("track", 0) == 0 || v.var.rfind("check", 0) == 0) && std::isdigit((unsigned char)v.var[5]); }
// Raises the Lua error "not yet: <what>" for something the script asks for that is not
// implemented.
static int aviutl_no(lua_State* L, const std::string& what) { return luaL_error(L, "not yet: %s", what.c_str()); }
// Returns the string at stack index `i`, or an empty string if it is not a string.
static std::string aviutl_str(lua_State* L, int i) { return lua_type(L, i) == LUA_TSTRING ? lua_tostring(L, i) : ""; }
// Returns the number at stack index `i`, counting a boolean as 0 or 1, or `otherwise` if the value
// is neither.
static double aviutl_num(lua_State* L, int i, double otherwise = 0) { return lua_isnumber(L, i) ? lua_tonumber(L, i) : lua_isboolean(L, i) ? lua_toboolean(L, i) : otherwise; }
// Returns the folders searched for a script's modules and shaders, starting with the script's own
// folder `dir`.
//
// AviUtl2 has one Script folder: the Script/ of each .au2pkg is put into it beside those of every
// other package (package.ini). A script can therefore require another package's module and use
// its shaders ("name@part@file"). For example, HexScript's chromatic-aberration region fill
// requires the sigma-axis package's Region_S.lua and calls the shaders of @Region_S.anm2. Motolii
// keeps each package in its own folder (aviutl_scripts/<package>/Script), so this returns all of
// those folders. The list is cached and rebuilt when the modification time of aviutl_scripts
// changes, which happens when a package is added.
static std::vector<std::filesystem::path> aviutl_shared(const std::filesystem::path& dir) {
    static std::mutex hold;
    static std::map<std::filesystem::path, std::pair<std::filesystem::file_time_type, std::vector<std::filesystem::path>>> cached;
    std::vector<std::filesystem::path> dirs = {dir};
    for (std::filesystem::path p = dir; p.has_relative_path() && p != p.parent_path(); p = p.parent_path()) {
        if (p.parent_path().filename() != "aviutl_scripts") continue;
        std::error_code wrong;
        const std::filesystem::path root = p.parent_path();
        const auto when = std::filesystem::last_write_time(root, wrong);
        std::lock_guard<std::mutex> one(hold);
        auto& [built, all] = cached[root];
        if (all.empty() || built != when) {
            all.clear(), built = when;
            for (const auto& e : std::filesystem::directory_iterator(root, wrong))
                if (std::filesystem::is_directory(e.path() / "Script", wrong)) all.push_back(e.path() / "Script");
            std::sort(all.begin(), all.end());
        }
        for (const auto& d : all) if (d != dir) dirs.push_back(d);
        break;
    }
    return dirs;
}
// Returns the HLSL text of the shader registered as `name`, or an empty string if there is none.
// The shader is looked up in this script's text, then in the whole file's text. A name of the form
// "name@script" refers to another script in the Script folder, and "name@part@file" to a part of
// an "@" file. Results are cached.
static std::string aviutl_hlsl(AviutlRun& r, const std::string& name) {
    if (auto cached = r.hlsls.find(name); cached != r.hlsls.end()) return cached->second;
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
// Returns the interop shader for the registered shader `name`, building it on first use. With
// `clip`, samples outside the image are transparent. Returns nullptr and sets `why` on failure. If
// `built` is not null it receives the converted shader.
static interop::Screen* aviutl_interop(AviutlRun& r, const std::string& name, bool clip, std::string& why, const AviutlShader** built = nullptr) {
    const std::string hlsl = aviutl_hlsl(r, name), entry = name.substr(0, name.find('@'));
    if (hlsl.empty()) return why = "no pixelshader@" + name, nullptr;
    const AviutlShader& sh = aviutl_shader(hlsl, entry, clip);
    if (built) *built = &sh;
    interop::Screen*& d = r.interops[name + (clip ? "|clip" : "")];
    if (!d && sh.wgsl.empty()) return why = sh.why, nullptr;
    if (!d) d = interop::screen(r.s->engine, entry.c_str(), sh.wgsl.c_str(), sh.bytes, &why, sh.textureCount);
    return d;
}

// The remaining parts of the implementation. They are included here, in this order, and are not
// meant to be included anywhere else.
#include "community/aviutl/aviutl_obj.h"
#include "community/aviutl/aviutl_obj_draw.h"
#include "community/aviutl/aviutl_obj_effect.h"
#include "community/aviutl/aviutl_run.h"

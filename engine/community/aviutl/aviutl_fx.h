#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_FX_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_FX_H_
// Runs an AviUtl2 script (see aviutl.h) as one of a layer's effects.
//
// The script runs as written on the layer's image every frame, in LuaJIT 2.1
// (MIT, the Lua that AviUtl2 uses by default) with os, io, debug, ffi.C and
// ffi.load removed, as lua.txt specifies. The `obj` table has the names of the
// AviUtl2 specification, each implemented with what Motolii already has:
//   - The buffers ("object", "tempbuffer", "cache:..." and "framebuffer", which
//   holds the layer's
//     own image as it leaves the effect) are premultiplied RGBA16F images, as
//     in AviUtl2.
//   - Shaders are drawn by the interop (screen_interop.h).
//   - obj.draw uses one placing shader.
// A call the script makes that is not implemented stops the script with "not
// yet: obj.X", reported once, and leaves the image as it came in. The result is
// never an image that silently differs from what the script would produce.
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <chrono>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <lua.hpp>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "community/aviutl/aviutl.h"
#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

// An image buffer: its texture `t`, the render target `rt` for drawing into it,
// and its size in pixels.
struct AviutlBuf {
  filament::Texture* t = nullptr;
  filament::RenderTarget* rt = nullptr;
  uint32_t w = 0, h = 0;
};
// A script of the same file that the running script invoked by name
// (obj.effect); see aviutl_called. Holds its compiled chunk, its variables and
// their current values.
struct AviutlCalled {
  int chunk = LUA_NOREF;
  std::vector<AviutlVar> vars;
  std::map<std::string, double> usual;
};
// The state of one script attached to one layer: its text and parameters, its
// Lua state, its buffers and shaders, and the state of the frame being drawn.
struct AviutlRun {
  // The script's name (see aviutl.h), the text of the script itself, the text
  // of the whole file, and the last error message.
  std::string file, own, all, trouble;
  std::vector<AviutlVar> vars;
  // The current value of each parameter, by variable name.
  std::map<std::string, double> usual;
  // The Lua state shared by the layer's scripts. Created by aviutl_open.
  lua_State* L = nullptr;
  // Registry references in L to the script's compiled function and to its obj
  // table.
  int chunk = LUA_NOREF, obj = LUA_NOREF;
  // Where require looks for modules; set as package.path while the script runs.
  std::string path;
  std::map<std::string, AviutlBuf> bufs;
  // Figures and image files drawn by obj.load, by request (aviutl_load.h).
  std::map<std::string, AviutlBuf> loaded;
  // Released buffers kept by size for reuse. A script that creates and releases
  // a buffer every frame gets the same buffers back.
  std::multimap<std::pair<uint32_t, uint32_t>, AviutlBuf> spare;
  // The shaders already built, by name and sampling mode.
  std::map<std::string, interop::Screen*> interops;
  // The HLSL text of each shader by its registered name. It is looked up once
  // (aviutl_hlsl) and needed every frame.
  std::map<std::string, std::string> hlsls;
  // Number of draws made with each shader this frame. Each draw has its own
  // constants, selected by the interop's pass index.
  std::map<interop::Screen*, int> draws;
  // The shaders for placing images (aviutl_placing), for drawing polygons
  // (aviutl_poly) and for blurring (aviutl_blur).
  interop::Screen *place = nullptr, *poly = nullptr, *blur = nullptr;
  // An empty texture for draws that read no image, and the noise texture that
  // obj.pixelshader supplies for a resource named "random".
  filament::Texture *none = nullptr, *random = nullptr;
  // Error messages already reported on stderr, so each is reported once.
  std::set<std::string> said;
  // The deadline for this frame's run; the script is stopped after it
  // (aviutl_late).
  std::chrono::steady_clock::time_point until =
      std::chrono::steady_clock::time_point::max();
  // The parameter values with which the script exceeded the time limit; it is
  // not run again with the same values. Empty until such a run happens. It is
  // an optional so that a script without parameters, whose value string is
  // empty, can be told apart from "none yet".
  std::optional<std::string> late;
  // The stage being drawn this frame.
  Stage* s = nullptr;
  std::string target, blend, sampler;
  bool drew = false;
  // True if the script reads the frame: the stage behind the layer, as
  // AviUtl2's framebuffer holds what was drawn before the layer.
  bool behind = false;
  // The region of the stage covered by the layer's effect image, as {x0, y0,
  // x1, y1} in stage points.
  double box[4] = {0, 0, 0, 0};
  // The stage's background color behind everything as 0xRRGGBB, or -1 if there
  // is none.
  int ground = -1;
  // True if the script draws the object (obj.draw, drawpoly). Its coordinate
  // frame is then the stage's, and the object is the layer's own image placed
  // where the layer is seen.
  bool wide = false;
  // This frame's answers to what the script asks about other layers, supplied
  // by the document through doc_aviutl_asked in document/evaluate/moment_fx.h.
  const ScreenNumbers* numbers = nullptr;
  // Callback that supplies the sound heard now for the layer (ScreenStack's
  // sounds).
  const std::function<std::vector<float>(const std::string&, const std::string&,
                                         bool, int)>* sounds = nullptr;
  // The names of the effects on the layer in order, and the position of this
  // script in them, for obj.getoption "script_name".
  std::vector<std::string> chain;
  // The buffer that obj.getpixel reads and the format in which it returns a
  // pixel; both are set by obj.pixeloption.
  std::string pixelFrom = "object", pixelType = "col";
  // That buffer read back once and kept until obj.pixeloption "get" is called
  // again; see aviutl_pixels.h.
  std::vector<uint8_t> pixelSeen;
  uint32_t pixelW = 0, pixelH = 0;
  bool pixelRead = false;
  int at = 0;
  // The part of `box` where the layer itself is visible, in stage points.
  double seen[4] = {0, 0, 0, 0};
  // sashimono-edit's remakes of AviUtl's built-in effects that this script has
  // run, by file; see aviutl_sashimono.
  std::map<std::string, ScreenFx*> isf;
  ScreenStack isfStack;
  // The font set by obj.setfont, used by obj.load "text" (aviutl_load.h).
  struct {
    std::string name;
    double size = 48, deco = 0, colour = 0xffffff, edge = 0;
    bool bold = false, italic = false;
  } font;
  // The keys of the text images drawn this frame. Text images not drawn again
  // are released the next frame; a clock that changes every second makes a new
  // image each second.
  std::set<std::string> worded;
  // The other scripts of the same file that this script has run by name
  // (obj.effect).
  std::map<std::string, AviutlCalled> called;
};

// The placing shader. It draws an image onto the target so that the image's
// pixel `src` lands at `at` of the target, rotated and scaled by `m` (the
// matrix that takes target pixels back to image pixels), and faded by `alpha`.
// Outside the image's edge the result is transparent (AviUtl2's "clip" sampler,
// as in aviutl.cpp), except in way 2, where the edge is not clipped. Way 1
// outputs the plain color, which is how a buffer is cleared. Otherwise colour.x
// selects a conversion: 1 reads straight alpha and makes it premultiplied (a
// layer's image is straight, as Motolii's effects keep it), and 2 makes it
// straight again.
extern const char* const aviutl_placing;
// The shader for obj.drawpoly: draws the image on triangles (the interop's
// mesh), sampled at each corner's uv, or in each corner's color for a face with
// no image (uv.x below -1), faded by alpha.
extern const char* const aviutl_poly;
// The shader for the blur effect of obj.effect: a copy of sashimono-edit's
// blur1d (MIT, effects/builtin.py). Each pass blurs along one axis: it sums the
// pixel and up to `radius` pixels (at most 96) on each side, weighted by a
// Gaussian whose sigma is half the radius. The buffer is already premultiplied,
// as its premul step makes it.
extern const char* const aviutl_blur;

// A frame's run is stopped once it takes longer than Redis allows a script
// (lua-time-limit, 5000 ms). Redis does this with a count hook every 100000
// instructions, then a line hook so that a pcall cannot keep the script going
// (script_lua.c, luaMaskCountHook). LuaJIT calls no hook inside a loop it has
// compiled (`while true do cf() end` never stopped when measured), so every obj
// call also checks the deadline. That stops a script stuck inside an obj call
// such as obj.getvalue.
extern const char* const aviutl_too_long;
// Debug hook that raises a Lua error once this frame's deadline (r->until) has
// passed. It then switches to a line hook, so that a pcall cannot swallow the
// error and keep the script running.
void aviutl_late(lua_State* L, lua_Debug*);
// Returns the AviutlRun bound to the running obj function as its first upvalue.
// Raises a Lua error if the deadline has passed.
AviutlRun& aviutl_of(lua_State* L);
// Maps the short buffer names obj, tmp and frm to "object", "tempbuffer" and
// "framebuffer". Any other name is returned unchanged.
std::string aviutl_name(std::string n);
// Returns the buffer called `name`, creating it or resizing it to w x h. A size
// of 0 keeps the current size, and sizes are clamped to 1..8192. A buffer
// replaced by one of another size goes to r.spare for reuse.
AviutlBuf& aviutl_buf(AviutlRun& r, const std::string& name, uint32_t w = 0,
                      uint32_t h = 0);
// Lays `from` onto a target of w x h pixels. The image's center, moved by (cx,
// cy), goes to the target's center moved by (ox, oy). The image is scaled by
// (sx, sy), rotated by rz degrees and faded by alpha. `way` and `as` are the
// shader's way and colour.x. See aviutl_put for `blend` and `sampler`.
void aviutl_lay(AviutlRun& r, const AviutlBuf& from, filament::RenderTarget* to,
                uint32_t w, uint32_t h, double ox, double oy, double sx,
                double sy, double rz, double alpha, double cx, double cy,
                int blend, int sampler, float way = 0, float as = 0);
// Copies buffer `from` into buffer `to`, resizing `to` to match.
void aviutl_copy(AviutlRun& r, const std::string& to, const std::string& from);
// Fills buffer `b` with the color `colour` (0xRRGGBB) if `opaque`, otherwise
// with transparent pixels.
void aviutl_clear(AviutlRun& r, const AviutlBuf& b, double colour, bool opaque);
// Returns true for a variable declared in the old numbered form (--track0:,
// --check0:), which the script reads as obj.track0 rather than as a named
// variable.
bool aviutl_old(const AviutlVar& v);
// Raises the Lua error "not yet: <what>" for something the script asks for that
// is not implemented.
int aviutl_no(lua_State* L, const std::string& what);
// Returns the string at stack index `i`, or an empty string if it is not a
// string.
std::string aviutl_str(lua_State* L, int i);
// Returns the number at stack index `i`, counting a boolean as 0 or 1, or
// `otherwise` if the value is neither.
double aviutl_num(lua_State* L, int i, double otherwise = 0);
// Returns the folders searched for a script's modules and shaders, starting
// with the script's own folder `dir`.
//
// AviUtl2 has one Script folder: the Script/ of each .au2pkg is put into it
// beside those of every other package (package.ini). A script can therefore
// require another package's module and use its shaders ("name@part@file"). For
// example, HexScript's chromatic-aberration region fill requires the sigma-axis
// package's Region_S.lua and calls the shaders of @Region_S.anm2. Motolii keeps
// each package in its own folder (aviutl_scripts/<package>/Script), so this
// returns all of those folders. The list is cached and rebuilt when the
// modification time of aviutl_scripts changes, which happens when a package is
// added.
std::vector<std::filesystem::path> aviutl_shared(
    const std::filesystem::path& dir);
// Returns the interop shader for the registered shader `name`, building it on
// first use. With `clip`, samples outside the image are transparent. Returns
// nullptr and sets `why` on failure. If `built` is not null it receives the
// converted shader.
interop::Screen* aviutl_interop(AviutlRun& r, const std::string& name,
                                bool clip, std::string& why,
                                const AviutlShader** built = nullptr);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_FX_H_

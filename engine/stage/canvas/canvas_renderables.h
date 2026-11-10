#ifndef MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_

// Draws ThorVG content (images, animations, text and flat shapes) into textures
// and places each one in the stage as a flat sheet.

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>

#include <functional>
#include <string>
#include <vector>

#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

// Builds a Canvas2D from a ThorVG paint. The paint is drawn into a texture on
// Filament's device, and a flat sheet shows that texture. Shared by
// image_canvas(), type() and flat(). Returns nullptr on failure, or when the
// engine does not use the WebGPU backend. paints: Called on the engine's driver
// thread. Fills in the paint's width and height in points and returns the
// paint, or nullptr on failure. place: Transform of the sheet's center. high:
// Height of the sheet in world units. ground: Background color. If ground.x is
// below 0, the background is transparent. shown: If false, the canvas is built
// but not added to the scene. Used for mattes. lay: Name of the layout for the
// sheet's material. fx: Options applied on top. The effects below are ThorVG
// scene effects. Their sizes are fractions of the content height, and 0 means
// none.
//   blur: blur radius.
//   shadow: shadow color in xyz and its opacity in w.
//   fall: distance the shadow falls.
//   soft: shadow softness.
//   copies: number of instances placed. The document gives each its own
//   transform.
Canvas2D* place_canvas(
    Stage& s, const std::function<tvg::Paint*(Canvas2D*, int*, int*)>& paints,
    const filament::math::mat4f& place, float high,
    filament::math::float3 ground, bool shown, const char* lay,
    const Canvas2DFx& fx = {});

// Adds the image or animation in `file` to the scene. It can be a Lottie
// animation exported from After Effects, an SVG or a photo. The sheet is `high`
// tall, as wide as the content's aspect ratio requires, centered at `place` and
// facing along the z axis of `place`. It is drawn at the stage's resolution.
// ground, shown, lay, fx: As for place_canvas().
// marker: Name of a Lottie marker whose range is played in a loop. An empty
// name plays the whole animation (ThorVG's Lottie markers). Returns nullptr on
// failure.
Canvas2D* image_canvas(
    Stage& s, const char* file, const filament::math::mat4f& place, float high,
    filament::math::float3 ground = filament::math::float3{-1.f},
    bool shown = true, const char* lay = nullptr, const Canvas2DFx& fx = {},
    const char* marker = "");

// Color-ramp blend modes. `blend` selects how colors between two stops are
// mixed:
//   0: sRGB, as ThorVG mixes them.
//   1: OKLab, which is closer to how the eye mixes colors. The conversions
//   follow the sample code
//     in CSS Color 4 and Bjorn Ottosson's OKLab.
//   2: HSV, going the shorter way around the hue and interpolating saturation
//   and value linearly
//     (CSS Color 4, hue interpolation, shorter).
//   3: Constant. Each color is held until the next stop (Blender's ColorRamp,
//   Constant).
// Modes 1 to 3 insert extra stops between each pair of stops, which ThorVG then
// mixes linearly.

// Returns a ThorVG gradient over an area `w` by `h` points. The caller passes
// it to a ThorVG paint, which takes ownership. A linear gradient runs from the
// first color to the last, evenly spaced or at the positions in `givenAt`. A
// radial gradient runs from the center out to the corners. angle: Direction of
// the linear gradient in degrees. 0 runs from top to bottom. scale: How far the
// gradient reaches, as a multiple of the area's extent in that direction.
// spread: ThorVG's FillSpread, clamped to 0..2.
// blend: Color-mixing mode. See the blend modes above.
tvg::Fill* ramp_of(const std::vector<filament::math::float4>& given, float w,
                   float h, bool radial = false, float angle = 0.f,
                   float scale = 1.f, int spread = 0,
                   const std::vector<float>& givenAt = {}, int blend = 0);

// Returns the characters of `words` that the font file has no glyph for, each
// listed once in the order first seen. Returns "" if the file cannot be read.
// It reads the font's cmap with stb_truetype (Sean Barrett, public domain, as
// Filament bundles it). Glyph 0 is .notdef, the box ("tofu") that ThorVG draws
// for a missing character. Spaces, control characters and joiners need no glyph
// and are ignored. For a .ttc file only the first face is read, as ThorVG does
// (engine/deps/patches/thorvg/thorvg_ttc.patch).
// The last few files read are cached, because the fallback lookup asks again
// and again.
std::string type_lacks(const std::string& fontFile, const std::string& words);
// Returns a font to use instead of `fontFile` when it lacks some characters of
// `words`, so that no missing-glyph boxes appear. Returns "" if the font has
// every character or if no font has them all. The search goes through the fonts
// folders listed by doc_folders: first the bundled fonts
// (third_party/noto_sans_jp, Noto Sans JP from notofonts/noto-cjk, OFL), then
// the user's own fonts/ folder. It takes the first font that has every
// character, like a browser going down a CSS font-family list (CSS Fonts 4,
// font fallback). The whole text uses one font, because ThorVG sets a text in
// one font.
std::string type_fallback(const std::string& fontFile,
                          const std::string& words);

// Returns whether ThorVG can set `words` in the font file. The file must load,
// the text must come out with a nonzero size, and the font must have every
// character. ThorVG also measures the box it draws for a missing character, so
// type_lacks() is checked first. Any thread may call this once ThorVG is
// initialized, because ThorVG's font loader holds a lock.
bool type_sets(const char* fontFile, const char* words);
// Adds `words` to the scene, set by ThorVG in the font of `fontFile` (a .ttf).
// Each line is a sheet `high` tall and as wide as its words, centered at
// `place`. If the font lacks some characters, the whole text is set in a
// fallback font instead, chosen by type_fallback. colour: Fill color. edge:
// ThorVG outline around the letters. xyz is its color and w its width as a
// fraction of the text height. 0 means none. align: How lines align under one
// another, as ThorVG does: 0 left, 1 right. fx.rims: Further outlines, each
// outside the last. The letters are drawn again beneath, each with a wider
// outline. The words may contain \n to break lines.
Canvas2D* type(Stage& s, const char* words, const char* fontFile,
               const filament::math::mat4f& place, float high,
               filament::math::float3 colour = filament::math::float3{0.f},
               const char* lay = nullptr,
               filament::math::float4 edge = filament::math::float4{0.f},
               float align = 0.f, const Canvas2DFx& fx = {});

// Appends to `shape` the path of the flat shape `form`, for a picture `w` by
// `h` points, inset by `in` (half the stroke width). form: rect, circle,
// polygon, star, line, wave, spiral, ring, arc, arrow, chamfer, squircle or
// cog, or SVG path data starting with 'M'.
// points: Meaning depends on the form, for example the number of corners or
// teeth. inner: Meaning depends on the form, for example the star's inner
// radius as a fraction of the outer one. round: Corner rounding as a fraction
// of the shorter side. fine: Lines and curves are cut into pieces no longer
// than this many points. 0 leaves them as they are. This lets deformations bend
// them. The unbent path is kept in `d`.
void flat_path(Canvas2D* d, tvg::Shape* shape, const char* form, int w, int h,
               float in, int points, float inner, float round, float fine);

// Returns the width-to-height ratio of the image in `file` as ThorVG reads it,
// or 0 if it cannot be read. Runs on the driver thread, like place_canvas().
float canvas_aspect(Stage& s, const char* file);
Canvas2D* flat(Stage& s, const char* form, float wide,
               const filament::math::mat4f& place, float high,
               filament::math::float3 colour, const char* lay = nullptr,
               filament::math::float4 edge = filament::math::float4{0.f},
               const Canvas2DFx& fx = {}, int points = 6, float inner = 0.5f,
               float round = 0.f);

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_

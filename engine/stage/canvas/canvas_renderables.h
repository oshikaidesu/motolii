#ifndef MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_

// Draws ThorVG content (images, animations, text and flat shapes) into textures
// and places each one in the stage as a flat sheet.

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>

#include <cmath>
#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

// A colour component in 0..1 as the byte ThorVG takes.
inline uint8_t byte_of(float c) { return (uint8_t)std::lround(255.f * c); }

// Pushes the ThorVG canvas' change to its target texture right now (driver
// thread). After this the next `s.renderer->render(s.view)` shows the result.
inline void canvas_redraw_now(Canvas2D* d) {
  d->canvas->update();
  d->canvas->draw(true), d->stale = true;
  d->canvas->sync();
}

// Measures the bent outline of `d->shape` and stores it, normalised to the
// sheet's texture, in d->bentBox (see Canvas2D). Does nothing without a shape
// or a texture size. Bumps s.bentChanges when the box moved, so the window's
// box is snapshotted again, and sets s.bentOverflow when the bend reaches past
// the texture, so the sheet is grown once. Driver thread only, because it reads
// a ThorVG shape. Called by place_canvas after a build and by bend_at after a
// bend, so the grabbed box follows a path operator live without a full rebuild.
void canvas_measure_bent(Stage& s, Canvas2D* d);

// Builds a Canvas2D from a ThorVG paint → Filament texture → flat sheet.
// Returns nullptr on failure or non-WebGPU backend.
// ground.x < 0 = transparent. shown = false builds without adding to scene.
Canvas2D* place_canvas(
    Stage& s, const std::function<tvg::Paint*(Canvas2D*, int*, int*)>& paints,
    const filament::math::mat4f& place, float high,
    filament::math::float3 ground, bool shown, const char* lay,
    const Canvas2DFx& fx = {});

// Adds an image, SVG, Lottie animation or photo to the scene.
// marker: Lottie marker range to loop ("" = whole animation).
Canvas2D* image_canvas(
    Stage& s, const char* file, const filament::math::mat4f& place, float high,
    filament::math::float3 ground = filament::math::float3{-1.f},
    bool shown = true, const char* lay = nullptr, const Canvas2DFx& fx = {},
    const char* marker = "");

// Color-ramp blend modes: 0 sRGB, 1 OKLab (CSS Color 4), 2 HSV shorter hue
// (CSS Color 4), 3 constant (held until next stop). Modes 1–3 insert extra
// stops that ThorVG mixes linearly.

// Returns a ThorVG gradient (caller passes to a paint, which takes ownership).
// angle: degrees, 0 = top-to-bottom. scale: multiple of extent. blend: see
// above.
tvg::Fill* ramp_of(const std::vector<filament::math::float4>& given, float w,
                   float h, bool radial = false, float angle = 0.f,
                   float scale = 1.f, int spread = 0,
                   const std::vector<float>& givenAt = {}, int blend = 0);

// Applies a solid or gradient stroke paint onto `shape`.
void stroke_paint(tvg::Shape* shape, filament::math::float3 rgb,
                  const std::vector<filament::math::float4>& ramp,
                  const std::vector<float>& rampAt, float w, float h,
                  const Canvas2DFx& fx);

// Duplicates `base` as a stroke-only shape aligned inside (-1), center (0) or
// outside (1) using ThorVG alpha / inverse-alpha masking.
tvg::Shape* stroke_layer(tvg::Shape* base, float strokeW, int align,
                         filament::math::float3 rgb,
                         const std::vector<filament::math::float4>& ramp,
                         const std::vector<float>& rampAt, int cap, int join,
                         float dash, float gap, float dashFrom, float w,
                         float h, const Canvas2DFx& fx);

// Wraps `top` with `fx.rims` (outside rims behind, center/inside rims in
// front).
tvg::Paint* stroke_with_rims(tvg::Paint* top, tvg::Shape* base, float baseOut,
                             float baseIn, float rimScale, float w, float h,
                             const Canvas2DFx& fx);

// Characters of `words` missing from the font (cmap via stb_truetype). Cached.
// .ttc: only first face (thorvg_ttc.patch).
std::string type_lacks(const std::string& fontFile, const std::string& words);
// Returns a fallback font that has every character, or "" if none found.
// Searches bundled fonts then user's own fonts/ folder. One font for the whole
// text (ThorVG limitation).
std::string type_fallback(const std::string& fontFile,
                          const std::string& words);

// Whether ThorVG can set `words` in the font file. Thread-safe after ThorVG
// init.
bool type_sets(const char* fontFile, const char* words);
// Adds text to the scene (community/css/text.h). Missing characters use a
// fallback font (type_fallback). edge: xyz color, w width as fraction of
// height.
Canvas2D* type(Stage& s, const char* words, const char* fontFile,
               const char* styles, const filament::math::mat4f& place,
               float high,
               filament::math::float3 colour = filament::math::float3{0.f},
               const char* lay = nullptr,
               filament::math::float4 edge = filament::math::float4{0.f},
               float align = 0.f, const Canvas2DFx& fx = {});

// Appends a flat shape path. form: rect, circle, polygon, star, line, wave,
// spiral, ring, arc, arrow, chamfer, squircle, cog, or SVG 'M...' data.
// fine > 0: subdivide curves for deformation; unbent path kept in `d`.
void flat_path(Canvas2D* d, tvg::Shape* shape, const char* form, int w, int h,
               float in, int points, float inner, float round, float fine);

// Aspect ratio of the image, or 0 on failure. Driver thread.
float canvas_aspect(Stage& s, const char* file);
Canvas2D* flat(Stage& s, const char* form, float wide,
               const filament::math::mat4f& place, float high,
               filament::math::float3 colour, const char* lay = nullptr,
               filament::math::float4 edge = filament::math::float4{0.f},
               const Canvas2DFx& fx = {}, int points = 6, float inner = 0.5f,
               float round = 0.f);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_RENDERABLES_H_

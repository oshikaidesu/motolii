// Full-screen and mesh passes with a user-supplied WGSL fragment shader, drawn
// through Filament's own driver (compute_interop does the same for compute).
//
// Filament 1.77.2 has no public API for running your own shader over an image.
// Its post-processing draws a full-screen triangle with a program, and so does
// this code. The Filament authors say this is "currently not directly possible
// ... via off screen render targets" (google/filament discussion #7676). The
// calls used here are the same as in
// third_party/filament_src/filament/src/PostProcessManager.cpp:
// beginRenderPass, then draw(pipeline, getFullScreenRenderPrimitive(), 0, 3,
// 1). Filament is built from the source in third_party, so the internals this
// relies on stay as written until that source is changed on purpose.
//
// The shader is a fragment shader with this entry point:
//   fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) ->
//   @location(0) vec4f
// where uv (0,0) is the top left. Image k is bound as
//   @group(0) @binding(2k) var <name>: texture_2d<f32>
// with its sampler at binding 2k+1. If the shader has parameters they are bound
// as
//   @binding(2 * images) var<uniform> <name>: <struct>
//
// Calls are queued like any other Filament call. A `draw` issued between the
// render of the image it reads and the render of whatever shows its result is
// ordered with them on the GPU.
#pragma once
#include <cstdint>
#include <string>

namespace filament {
class Engine;
class Texture;
class RenderTarget;
}  // namespace filament

namespace interop {

// Floats per mesh corner: x, y, z, w, r, g, b, a, u, v.
constexpr uint32_t MESH_CORNER = 10;
// A compiled shader pass with its parameter buffer and, for mesh passes, its
// corner buffer.
struct Screen;
// Creates a Screen from a WGSL fragment shader, or returns nullptr if Dawn
// rejects the shader. In that case `why` receives Dawn's message. The shader is
// first tried on Filament's own device inside an error scope, so a bad shader
// cannot disturb anything else.
//
// `parameterBytes` is the size of the shader's uniform struct, or 0 for none.
// `textureCount` is the number of images the shader reads. Image i is at
// `@binding(2i)`, its sampler at `2i+1`, and the parameters at `2 *
// textureCount`. A Screen can be drawn several times per frame as separate
// passes, each with its own parameters; see `pass` in `parameters` and `draw`.
// `layered` is a bit mask: bit k set means image k is a
// `texture_2d_array<f32>`, such as the past frames of a stage. `mesh` makes
// `draw` render triangles given by `corners` instead of the whole target. Each
// corner has a position (x, y, z, w; the GPU divides by w, so the image between
// corners is laid in perspective, with -1 to 1 up after the divide), a colour
// passed to the shader at @location(1), and a uv. Filament's own full-screen
// triangle is given the same way: a vertex buffer and an index buffer made into
// a render primitive; see details/Engine.cpp.
Screen* screen(filament::Engine*, const char* name, const char* fragment,
               uint32_t parameterBytes, std::string* why = nullptr,
               int textureCount = 1, unsigned layered = 0, bool mesh = false);
// Stores the parameters used by `pass` of the next draws. At most
// `parameterBytes` are used.
void parameters(filament::Engine*, Screen*, const void* data, uint32_t bytes,
                int pass = 0);
// Draws one pass reading the images `from` and writing to `to`.
//
// `to`: the render target, or null for the screen.
// `w`, `h`: size of the target in pixels.
// `pass`: which pass's parameters to use. Pass 0 also starts a new frame of
// mesh corners. `at`: if not null, draws only in this rectangle (left, bottom,
// width, height) and clears
//   the rest of the target.
// `over`: lays the result over what `to` already holds, with alpha
// premultiplied as in
//   Filament's own images, instead of replacing it.
// `blend`: used only with `over`.
//   0: normal alpha-over.
//   1: added to what is there.
//   2: what is there multiplied by the alpha drawn (AviUtl2's "add" and
//   "mask"). 3: what is there kept outside what is drawn. 4: laid over with the
//   alphas added. 5: screen. 6: multiply.
// `sampler`: 0 linear and clamped, 1 nearest, 2 repeated, 3 mirrored. These are
// the wrap
//   modes of Filament's SamplerParams.
// `corners`, `count`: for a mesh Screen, `count` corners of MESH_CORNER floats
// each
//   (x, y, z, w, r, g, b, a, u, v). Fewer than 3 corners draws nothing.
void draw(filament::Engine*, Screen*, filament::Texture* const* from,
          filament::RenderTarget* to, uint32_t w, uint32_t h, int pass = 0,
          const int* at = nullptr, bool over = false, int blend = 0,
          int sampler = 0, const float* corners = nullptr, uint32_t count = 0);
// Convenience form for a Screen that reads one image with default settings.
inline void draw(filament::Engine* e, Screen* s, filament::Texture* from,
                 filament::RenderTarget* to, uint32_t w, uint32_t h,
                 const int* at = nullptr) {
  draw(e, s, &from, to, w, h, 0, at);
}
// Releases the Screen and its GPU objects.
void drop(filament::Engine*, Screen*);
}  // namespace interop

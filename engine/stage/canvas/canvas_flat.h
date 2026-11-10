#ifndef MOTOLII_STAGE_CANVAS_CANVAS_FLAT_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_FLAT_H_

// Meshes for flat shapes: the fill and edge triangles of a shape, the cache of
// meshes for trimmed and bent variants of its path, and single layers of an
// After Effects file drawn on their own.

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <array>
#include <cstdint>
#include <vector>

#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Creates a flat shape that Filament draws itself, like the scene's other
// renderables. The path is built the way `flat` builds it, with ThorVG. It is
// tessellated by libtess2, as Unity's vector shapes are, and tessellated again
// only when the path changes (see cut_at). It is drawn with flat.mat, tinted
// with `colour` on a white point. The edge is a second part in the edge color,
// from ThorVG's own stroker. Antialiasing comes from the view's MSAA, and the
// vertex stage of the material moves the points (bends). Nothing is rasterized
// into a texture for it: forty animated shapes cost a quarter of the time of
// the same shapes drawn as ThorVG pictures. There is no gradient ramp and there
// are no effects; those belong to `flat`. `wide` is the width as a multiple of
// the height, `high` the height in stage units. `edge`: xyz is the edge color
// and w its width as a share of the height, inside the frame as for `flat`.
// Returns nullptr if the parts could not be added.
Canvas2D* flat_mesh(Stage& s, const char* form, float wide,
                    const filament::math::mat4f& place, float high,
                    filament::math::float3 colour, const char* lay = nullptr,
                    filament::math::float4 edge = filament::math::float4{0.f},
                    const Canvas2DFx& fx = {}, int points = 6,
                    float inner = 0.5f, float round = 0.f, bool bends = true);

// Rebuilds the triangles of a flat shape for the next frame when its path
// inputs changed. `trim` is After Effects' trim paths on the edge: x is the
// amount cut off the end, y the amount cut off the start and z the offset slid
// along the path. `bend` holds the path operators (round, bloat, zig zag,
// offset; see thorvg_path_operators.cpp), then roughen indices 6 and 7,
// resample at 8 and voxelize at 9. `join` combines the path with another
// shape's path by a Skia path operation (see skia_path_operations.cpp), as
// Cavalry's Boolean: join.how is the operation, -1 for none, and join.by and
// join.at are the other path in this shape's points. `morph` and `trace` use
// the same struct. Finished cuts are cached by their inputs, within a limit
// shared by all shapes.
void cut_at(Stage& s, Canvas2D* d, filament::math::float3 trim,
            const std::array<float, 10>& bend, Canvas2D::Other join = {},
            Canvas2D::Other morph = {}, Canvas2D::Other trace = {});

// Draws one layer of an After Effects file on its own sheet, in the layer's own
// space. Its position and rotation are left out, because they belong to the
// sheet and are applied in the scene through the layer's pose (see
// lottie_motion.h). One composition point is `pixel` stage units on the sheet.
// `box` receives where the sheet lies in the layer's own space (x, y, width,
// height, in points of the composition). Returns nullptr if the layer cannot be
// loaded or has no size.
Canvas2D* layer_canvas(Stage& s, const char* file, uint32_t id, float pixel,
                       filament::math::float4* box);

// Finds the 3D layers of an After Effects file, stores their ids in d->deep and
// returns them. ThorVG reports each layer's pose and whether it is 3D. The ids
// let the caller draw each of these layers as a sheet of its own (see
// layer_canvas) instead of in the file's own canvas.
std::vector<uint32_t> canvas_deep(Stage& s, Canvas2D* d);

// Redraws the layer of `d` at `frame` of its file, for the next rendered frame.
void layer_at(Stage& s, Canvas2D* d, float frame);

// Removes a canvas from the stage for good. Nothing waits for it, as with
// Filament's destroy. What ThorVG holds, and the canvas itself, are released on
// the driver thread after every frame already sent that may still draw it,
// since that thread runs its work in order.
void canvas_off(Stage& s, Canvas2D* d);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_FLAT_H_

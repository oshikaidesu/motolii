#ifndef MOTOLII_STAGE_CANVAS_CANVAS_EDGE_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_EDGE_H_

// canvas_edge.h: how far each point of a picture is from its edge, in points, for its bevel (deep.glsl): the pictures of
// bevy_mod_outline's flood (src/flood/sobel_init.wgsl, jump_flood.wgsl; MIT OR Apache-2.0), its seeds and steps as they
// are, the interop's way of saying them: seeds from what is not the picture, so it floods inward, and the same flood outward
// from what is (its other two numbers), and a last pass that keeps the length, in less than 0 outside, smoothed, which
// reads smoothly between points where the way to the edge turns round, and at the edge itself comes down to 0 as it was
// (a round bevel stands straight up there: an unsmoothed length's least step shows as a saw).

#include <cstdint>

#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

// Its pictures, as large as it is: two the flood goes between, one the look reads.
void edge_make(Stage& s, Canvas2D* d, uint32_t w, uint32_t h);
void edge_off(Stage& s, Canvas2D* d);
// Flooded as far as `reach` points, the steps halving from the power of two at or past it, once in the next frame.
void edge_ask(Stage& s, Canvas2D* d, int reach);

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_EDGE_H_

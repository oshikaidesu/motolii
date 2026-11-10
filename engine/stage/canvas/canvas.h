#ifndef MOTOLII_STAGE_CANVAS_CANVAS_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_H_

// Draws an image with ThorVG as a flat layer in the Filament scene. The scene
// and its layers belong to Filament, where a layer is an entity with a
// transform and a material. This file only makes a layer whose material shows
// the ThorVG image, on a flat sheet.
//
// The image comes from a file: an After Effects animation (Lottie) with
// everything in it, or an SVG. ThorVG draws it with WebGPU on Filament's own
// device, straight into a texture that Filament samples. Nothing goes through
// the CPU and nothing is copied.
//
// This works only on the WebGPU backend (BACKEND=webgpu,
// gpu/filament_webgpu.sh), with ThorVG compiled against Dawn (deps/thorvg.sh)
// and Filament patched to lend its device and take a texture (gpu_interop.h).
// All of ThorVG's work is queued like Filament's own calls and runs on
// Filament's driver thread.

#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
#include "stage/canvas/path_operations.h"

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_H_

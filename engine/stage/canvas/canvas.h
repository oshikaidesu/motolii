// Draws an image with ThorVG as a flat layer in the Filament scene. The scene and its layers belong
// to Filament, where a layer is an entity with a transform and a material. This file only makes a
// layer whose material shows the ThorVG image, on a flat sheet.
//
// The image comes from a file: an After Effects animation (Lottie) with everything in it, or an
// SVG. ThorVG draws it with WebGPU on Filament's own device, straight into a texture that Filament
// samples. Nothing goes through the CPU and nothing is copied.
//
// This works only on the WebGPU backend (BACKEND=webgpu, gpu/filament_webgpu.sh), with ThorVG
// compiled against Dawn (deps/thorvg.sh) and Filament patched to lend its device and take a texture
// (gpu_interop.h). All of ThorVG's work is queued like Filament's own calls and runs on Filament's
// driver thread.
//
// The parts below must be included in this order. Each one depends on the one before it, and none
// stands alone.
#include "stage/canvas/path_operations.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
// Used by canvas_flat.h to draw the ends of an open edge as AbsentMotion does.
#include "community/absent_motion/absent_motion.h"
#include "stage/canvas/canvas_flat.h"

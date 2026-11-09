// canvas.h: a picture ThorVG draws, put in the scene as a thing like any other. The scene and its things are
// Filament's (an entity with a place and a look); this only makes one whose look is ThorVG's picture: a flat sheet.
// The picture is a file: an After Effects film (Lottie) with all it holds, or an SVG. ThorVG draws it with WebGPU on
// Filament's own device straight into a texture Filament reads: nothing goes through the CPU, nothing is copied.
// Only on the WebGPU backend (BACKEND=webgpu, gpu/filament_webgpu.sh), with ThorVG built against Dawn
// (deps/thorvg.sh) and Filament patched to lend its device and take a texture (gpu_interop.h).
// All of ThorVG's work is queued like Filament's own calls and runs on Filament's driver thread.
// In parts, read in this order (each a piece of the one before it, none alone):
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
#include "community/absent_motion/absent_motion.h"   // (an open edge's ends as AbsentMotion draws them: canvas_flat.h)
#include "stage/canvas/canvas_flat.h"

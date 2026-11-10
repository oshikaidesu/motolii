#ifndef MOTOLII_STAGE_CANVAS_CANVAS_SKETCH_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_SKETCH_H_

// canvas_sketch.h: Draws a 2D p5.js sketch onto a ThorVG canvas.
//
// The sketch runs without a web page (see p5_stand.h). On each frame its paint
// commands become ThorVG shapes on the layer's canvas. The canvas keeps its
// previous contents, because Canvas::draw(false) makes WgCompositor load what
// is already there. This matches a p5.js canvas: a sketch that never clears the
// canvas accumulates its painting, and a frame costs only what it adds.
//
// The paint commands arrive as a flat array of doubles, which is built by
// p5_stand.h. Each command has a header of 12 numbers followed by `n` path or
// text numbers and `more` gradient numbers. The header is laid out as follows:
//   p[0]: kind, 1 fill, 2 stroke, 3 text, 4 bitmap.
//   p[1..4]: red, green, blue and alpha, each 0 to 255.
//   p[5]: ThorVG blend method, 0 for none.
//   p[6..8]: stroke width, cap and join for strokes. For text, p[6] is the font
//   size, p[7] the
//     textAlign value and p[8] the textBaseline value.
//   p[9]: n, the number of path or text numbers after the header.
//   p[10]: more, the number of gradient numbers after those.
//   p[11]: the source line of the call in the sketch, which is used to look up
//   a fade amount.
// The first number of the whole array is nonzero when the canvas is cleared
// before drawing.

#include <memory>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Draws the commands in `o` onto the canvas of `d`. Nothing is drawn if `o` is
// empty. The canvas is cleared first when o[0] is nonzero.
void sketch_draw(Canvas2D* d, const std::vector<double>& o);
// Creates the canvas for a sketch layer and places it on the stage. `run` is
// the script that runs the sketch, `fontFile` is the font used for text, `high`
// is passed on to place_canvas, `lay` is the layer name and `fx` the canvas
// effects. Returns null if the sketch has no size.
//
// A sketch has no end, so the canvas is given 36000 frames, which is ten
// minutes at the 60 frames a second that the clock in p5_stand.h runs at.
Canvas2D* sketch_canvas(Stage& s, std::shared_ptr<Script> run,
                        const std::string& fontFile, float high,
                        const char* lay, const Canvas2DFx& fx);
// Creates an offscreen canvas that a WEBGL sketch draws with, which in p5.js is
// made by createGraphics. It is the same kind of canvas at its own size `wide`
// by `high`, and `pic` identifies it in the script. It is shown only where
// sketch.mat reads it, see document/evaluate/sketch.h. Returns null if the
// canvas cannot be placed.
Canvas2D* sketch_texture(Stage& s, Script* run, const std::string& fontFile,
                         int pic, int wide, int high);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_SKETCH_H_

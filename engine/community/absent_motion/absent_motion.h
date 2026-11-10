#ifndef MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_MOTION_H_
#define MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_MOTION_H_

// Declarations for the AbsentMotion adapter: motion, repeat, text, line-end, drawing and blur
// effects of a layer, computed by AbsentMotion's own code. The implementation is in
// absent_motion.cpp, absent_ends.cpp and absent_drawing.cpp, which are built apart with
// AbsentMotion's sources and Skia's headers.
//
// Every function takes the effects on one layer. Each effect is an id and its parameters, each
// parameter a name as AbsentMotion reads it and its values in order (a point or a color is a
// list of numbers). The "thing" argument is the layer's number; it seeds the randomness, like
// AbsentMotion's layer id. startMs, endMs and nowMs are the layer's start, its end and the
// current time, in milliseconds. Distances are in pixels, y points down, and angles are in
// degrees clockwise, as in Skia.
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

// One effect on a layer: its id and its parameters.
struct AbsentEffect { std::string id; std::vector<std::pair<std::string, std::vector<float>>> params; };

// The transform that AbsentMotion's ApplyMotion adds to a layer. The defaults mean no movement.
struct AbsentMoved { double x = 0, y = 0, z = 0, rotate = 0, scale_x = 1, scale_y = 1; };

// Returns how far the motion effects move the layer at nowMs, in pixels and degrees.
AbsentMoved absent_motion(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs);

// Returns the share of the layer's opacity that its opacity effects leave (Pulse Opacity, from
// motion.cpp MotionOpacity). Returns 1 when there are none.
float absent_opacity(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs);

// Returns true when the effects include a text effect (Count Up/Down, Timecode, Text Randomizer).
bool absent_text_on(const std::vector<AbsentEffect>& effects);

// Returns the words of a text layer as AbsentMotion's text effects show them at nowMs (text.cpp
// Shown, using textanim.cpp), with the frame rate fps. Returns text unchanged when no text effect
// is on the layer.
std::string absent_text(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, int fps, std::string text);

// Returns the outline of one end of a line, as AbsentMotion draws it (see absent_ends.cpp). The
// outline is SVG path data to be filled, in the same coordinates as the arguments.
//   x, y: where the end is.
//   dx, dy: the direction of the line at that end, as a unit vector.
//   r: the size of the end.
//   width: the width of the line.
//   cap: 0 butt, 1 round, 2 square.
//   join: 0 miter, 1 round, 2 bevel.
//   style: the end style's name.
// Returns an empty string for an unknown style.
std::string absent_line_end(float x, float y, float dx, float dy, float r, float width, int cap, int join, const char* style);

// Returns the outline of the freehand strokes of one drawing layer at nowMs, as SVG path data to
// be filled, in the same units as strokes (see absent_drawing.cpp). The effects that apply are
// Stroke Taper and Drawing Progress.
//
// strokes holds the strokes separated by ';'. Each stroke is its tool (0 pen, 1 brush, 2 fill,
// 3 eraser), its width (a brush's radius is its pressure times half of the width), and then its
// points as x, y and pressure in turn.
//
// When together is true the pieces are merged into one outline with Skia's union, which takes
// about twice as long as the other mode. It is meant for a path that is kept. The merge is
// always done when an eraser is present. When together is false the pieces are put side by side
// to be filled as one.
std::string absent_drawing(const std::string& strokes, const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, bool together);

// Looks for a motion blur or a shutter blur on the layer (motion.cpp ShutterBlurOf). Returns
// false when there is none. Otherwise it returns true and sets:
//   open: how long the shutter is open, in seconds, at fps frames a second.
//   moves: whether the blur smears the movement. AbsentMotion's quick smear uses only the middle
//          of the movement (styles.cpp DrawShuttered).
bool absent_shutter(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, int fps, double* open, bool* moves);

// One copy made by a repeat effect, placed relative to the layer's own position.
struct AbsentCopy { double x = 0, y = 0, rotate = 0, scale = 1, alpha = 1; };

// Returns the copies made by the repeat effects (Repeat, Linear, Grid, Radial, Scatter Field;
// motion.cpp RepeatCopies), each placed relative to the layer's own position. Returns an empty
// list when there is no repeat effect.
//   wide, high: the size of the composition.
//   atX, atY: where the layer stands on the composition, from the top left.
//   reach: how far the layer extends from that point.
// These arguments are the ones AbsentMotion's CopiesOf takes. A scatter field is laid over the
// whole composition, and its copies are as large as reach.
std::vector<AbsentCopy> absent_copies(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, float wide, float high, float atX, float atY, float reach);

// Returns one of AbsentMotion's easings evaluated at u. type is one of bounce, elastic, cyclic,
// random, step and elasticStep; p holds its n numbers as Alight Motion gives them (easing.h).
// At most 8 numbers are used.
double absent_ease(const char* type, const double* p, int n, double u);

#endif  // MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_MOTION_H_

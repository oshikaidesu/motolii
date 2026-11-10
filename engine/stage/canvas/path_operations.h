#ifndef MOTOLII_STAGE_CANVAS_PATH_OPERATIONS_H_
#define MOTOLII_STAGE_CANVAS_PATH_OPERATIONS_H_

// Path operations on 2D shapes, used by the canvas and by the document.
//
// The sk_* functions are defined in skia_path_operations.cpp, with Skia. The tvg_* functions are
// defined in thorvg_path_operators.cpp, with ThorVG's internal code. Each of those files is built
// apart because the headers of Skia and of ThorVG's internals declare names that clash with ours.
//
// A path is passed as the arrays of ThorVG's Shape: `cmds` with `cmdsCnt` commands and `pts`
// (`ptsCnt` points). Paths that come back are written to vectors that the function clears first.

#include <cstdint>
#include <string>
#include <vector>

#include <thorvg.h>

// Parses SVG path data into path commands and points. Returns false if the data cannot be parsed
// or is empty.
bool sk_svg(const char* data, std::vector<tvg::PathCommand>& cmds, std::vector<tvg::Point>& pts);

// Combines path A (ac, ap) with path B (bc, bp) into `cmds` and `pts`. `op` is an SkPathOp value:
// 0 is A minus B, 1 the intersection, 2 the union and 3 the exclusion. Returns false if the
// result is empty.
bool sk_op(int op, const tvg::PathCommand* ac, uint32_t acn, const tvg::Point* ap, const tvg::PathCommand* bc, uint32_t bcn, const tvg::Point* bp,
           std::vector<tvg::PathCommand>& cmds, std::vector<tvg::Point>& pts);

// Morphs path A into path B by `t`, from 0 for A to 1 for B. Returns false if the result is empty.
bool sk_morph(const tvg::PathCommand* ac, uint32_t acn, const tvg::Point* ap, const tvg::PathCommand* bc, uint32_t bcn, const tvg::Point* bp, float t,
              std::vector<tvg::PathCommand>& cmds, std::vector<tvg::Point>& pts);

// Roughens a path: it is cut into pieces about `apart` long and each end is moved by up to `far`.
// `seed` makes the result repeatable. Returns false if the result is empty.
bool sk_rough(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, float apart, float far, uint32_t seed,
              std::vector<tvg::PathCommand>& outCmds, std::vector<tvg::Point>& outPts);

// Replaces a path by `n` straight-line points per outline. Returns false if the result is empty.
bool sk_resample(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, int n, std::vector<tvg::PathCommand>& outCmds,
                 std::vector<tvg::Point>& outPts);

// Keeps the part of a path between the fractions `from` and `to` of its length, as a filled area.
// Returns false if the result is empty.
bool sk_trim(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, float from, float to, std::vector<tvg::PathCommand>& outCmds,
             std::vector<tvg::Point>& outPts);

// Replaces a path by squares of side `cell`. Returns false if the path or `cell` is empty.
bool sk_voxel(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, float cell, std::vector<tvg::PathCommand>& outCmds,
              std::vector<tvg::Point>& outPts);

// Finds the two ends of each open outline after trimming to the fractions `from` and `to`. Writes
// 8 numbers per outline to `out` (end and start, each as x, y, dx, dy) and returns how many
// outlines were written.
int sk_ends(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, float from, float to, std::vector<float>& out);

// Finds `n` places along a path, evenly spaced by length and shifted by the fraction `from`.
// Writes x, y and the direction in radians per place to `out` and returns the number of places.
int sk_along(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, int n, float from, std::vector<float>& out);

// Returns whether the point x, y lies inside the path. If `far` is not null, it receives the
// distance from the point to the outline.
bool sk_inside(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, float x, float y, float* far);

// The sk_svg_* functions read and edit SVG path data like a pen tool.
//
// Writes the path's anchor points to `xy` as x, y pairs and returns how many there are.
int sk_svg_anchors(const char* data, std::vector<float>& xy);

// Returns how the path ends, using Skia's verbs: 0 not read or empty, 1 a move alone, 2 a line, 3
// a curve, 4 closed. Writes the first point to `fx`, `fy` and the number of stretches to
// `stretches`.
int sk_svg_ends(const char* data, float& fx, float& fy, int& stretches);

// Moves the nth anchor by dx, dy, together with its handles, and writes the new path data to
// `out`. Returns false if `nth` is out of range.
bool sk_svg_move(const char* data, int nth, float dx, float dy, std::string& out);

// Writes the curves' handles to `xy` as x, y pairs and returns how many there are. If `of` is
// given, it receives the anchor each handle belongs to.
int sk_svg_handles(const char* data, std::vector<float>& xy, std::vector<float>* of = nullptr);

// Moves the nth handle by dx, dy and writes the new path data to `out`. Returns false if `nth` is
// out of range.
bool sk_svg_move_handle(const char* data, int nth, float dx, float dy, std::string& out);

// Edits the path at x, y. A point within `reach` is removed, and a point on the outline gets a new
// point put there. Writes the new path data to `out`. Returns 1 if a point was removed, 2 if one
// was put and 0 if nothing changed.
int sk_svg_edit(const char* data, float x, float y, float reach, std::string& out);

// Applies After Effects' path operators with ThorVG and replaces the contents of `shape` with the
// result. `round` rounds the corners, as a fraction of the shorter side. `bloat` pinches in or
// bloats out, from -1 to 1. `zigzag` has a height, as a fraction of the layer height, and
// `ridges` per side, smooth or sharp. `offset` moves the outline out or in, as a fraction of the
// height. `fine` is the longest piece allowed; a negative value cuts only curves.
void tvg_bend(tvg::Shape* shape, const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, uint32_t ptsCnt,
              float round, float bloat, float zigzag, int ridges, bool smooth, float offset, float fine);

// Converts the outline of a path into triangles with the stroker of ThorVG's WebGPU engine.
// `width` is the stroke width, `cap` and `join` are ThorVG's StrokeCap and StrokeJoin values,
// `dash` the length of each dash and gap (0 for none) starting at `dashFrom`, and `from` and `to`
// select the part of the length to stroke. Writes vertex positions to `xy` as x, y pairs and
// triangle indices to `idx`.
void tvg_edge(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, uint32_t ptsCnt, float width, int cap, int join, float dash,
              float dashFrom, float from, float to, std::vector<float>& xy, std::vector<uint32_t>& idx);

#endif  // MOTOLII_STAGE_CANVAS_PATH_OPERATIONS_H_

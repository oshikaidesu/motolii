#ifndef MOTOLII_DOCUMENT_EDIT_PATHS_H_
#define MOTOLII_DOCUMENT_EDIT_PATHS_H_

// paths.h: the plane and points of path shapes, and the tools that create or convert them.

#include <math/vec2.h>

#include "document/kinds.h"

// The plane of a path shape as the image shows it: its middle and its two axes. own() converts a
// point of the image to the shape's own coordinates, where the shape is 1 high, measured from its
// middle with y pointing down as in SVG. at() converts a point back.
struct DocPlane {
    // The shape's middle and its x and y axes, in points of the image. The axes are vectors from
    // the middle.
    filament::math::double2 o, ex, ey;
    // Determinant of the two axes. A value near zero means the shape is seen edge on.
    double det;
    // Whether the plane can be inverted, that is, whether the shape is not seen edge on.
    bool seen;
    // Builds the plane of the layer at time `now`.
    DocPlane(Doc& d, int layer, double now);
    // Converts a point of the image to the shape's own coordinates.
    filament::math::double2 own(double px, double py) const { const double u = px - o.x, v = py - o.y; return {(u * ey.y - v * ey.x) / det, -(ex.x * v - ex.y * u) / det}; }
    // Converts a point in the shape's own coordinates to a point of the image.
    filament::math::double2 at(double fx, double fy) const { return o + ex * fx - ey * fy; }
};
// Returns the number of points of a path shape and writes up to `room` of them to xy as x, y pairs,
// in points of the image from its top left. Returns 0 if the layer is not a path shape. If handles
// is true, writes the curves' handles instead of the points, and, if `of` is given, writes the
// point each handle belongs to (of[2i], of[2i+1]).
int doc_points(Doc& d, int layer, double now, double* xy, int room, bool handles = false, double* of = nullptr);
// Adds to the path of a path shape, as a pen tool does. The point goes at x, y in points of the
// image from its top left, and its handle is pulled out by hx, hy in points, where 0, 0 makes a
// corner. The path gets either a line to the point or, as Illustrator's pen makes one, a curve
// through it (SVG's S command: the point before becomes smooth, with its handle turned through).
// Clicking on the first point again closes the path. On a closed path, a click on one of its points
// removes that point, a click on its outline puts a point there, and a click elsewhere begins
// another path, as Illustrator's pen does. With layer 0 a new path shape is begun, with its first
// point, as one undo step. Returns the layer number, or 0 on failure.
int doc_pen(Doc& d, int layer, double x, double y, double hx, double hy);
// Takes a video's sound out to a layer of its own, as Alight Motion's Extract Audio does. The new
// layer is a hidden copy of the video with " (sound)" added to its name. The copy is still heard,
// because the sound of a hidden video plays (see match.h). The video itself is no longer heard,
// since its volume is set to 0. This is one undo step. Returns the new layer, or 0 on failure.
int doc_extract_sound(Doc& d, int layer);
// Creates a path shape from a freehand stroke. `points` is the outline that perfect-freehand makes
// around the user's stroke, as x y pairs in points of the image. perfect-freehand is by Steve Ruiz
// (MIT license), and the app uses its Dart port by Adil Hanney. The outline becomes a closed path,
// with each point joined to the next by a quadratic curve through their midpoint, as perfect-
// freehand's example draws the outline. This is one undo step. Returns the new layer, or 0 on
// failure.
int doc_freehand(Doc& d, const char* points);
// Creates a path shape from a freehand stroke, fitted with cubic Bezier curves. `said` holds the
// error, then x y pairs of the stroke, in points of the image. The stroke is fitted with the fewest
// cubics that stay within `error` points of it. Sharp turns, those past 70 degrees, are kept as
// corners. Blender's Draw Curve tool fits a stroke in the same way (editcurve_paint.cc,
// curve_fit_cubic_to_points_refit). The app uses an error of 8 screen points.
// The fitting library is curve-fit-nd by Campbell Barton (BSD-3-Clause). A stroke that ends where
// it began becomes a closed path. The anchors and handles are those of an ordinary pen path (M and
// C commands) and can be moved like any other. Returns the new layer, or 0 on failure.
int doc_curve(Doc& d, const char* said);
// Creates a path shape from a brush stroke, or adds a stroke to an existing drawing. `said` holds
// the tool, the brush size in points of the image, and then x y pressure for each point. The points
// come from perfect-freehand, each with the pressure its radius comes from.
// The shape keeps the stroke as drawn in its `drawing` property: the tool, the width, and each
// point with its pressure, in the plane's own units. Its outline is generated from that by
// AbsentMotion (absent_drawing, Alight Motion's brush, a band of round pieces). The drawing effects
// apply to it as time goes by (see doc_evaluate).
// The tools are those of AbsentMotion: 0 a pen, as wide all along; 1 a brush, as wide as the
// pressure says; 2 a fill, which fills the area the stroke goes round; 3 an eraser, a stroke added
// to the drawing of layer `into`, which removes what that drawing has drawn, as AbsentMotion's
// eraser clears within its drawing layer. Returns the shape that was made or erased from, or 0 on
// failure.
int doc_brush(Doc& d, const char* said, int into = 0);
// Converts a flat shape into a path shape of the outline it shows, as Alight Motion's Convert to
// Outline does. The form is drawn again as it is drawn on screen: flat_path makes it, and ThorVG's
// own path operators in tvg_bend apply the round corners, bloat, zigzag and offset, as cut_at does.
// The points are then stored in the path's own units, 1 high from the middle, with y down as in
// SVG. Those operators are set to 0 afterwards, because they are now part of the path. The fill,
// the edge and everything else stay as they were. Returns false, with d.error set, if the shape
// cannot be converted.
bool doc_to_path(Doc& d, int layer);

#endif  // MOTOLII_DOCUMENT_EDIT_PATHS_H_

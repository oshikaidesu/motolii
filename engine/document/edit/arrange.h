#ifndef MOTOLII_DOCUMENT_EDIT_ARRANGE_H_
#define MOTOLII_DOCUMENT_EDIT_ARRANGE_H_

// arrange.h: moves, aligns and fits layers on the canvas, and gives the default
// value of a property.

#include <string>
#include <vector>

#include "document/kinds.h"

namespace motolii {

// Returns the upright bounding box of a layer's outline on the canvas at time
// `now`, written to `box` as left, top, right, bottom in canvas points. The
// outline is the layer's own points when they are available, otherwise the
// corners of its bounds. Returns false if the layer is not shown.
bool doc_seen_box(Doc& d, int layer, double now, double* box);
// Changes a property by `value = value * times + add`. Every keyframe of the
// property is changed, so its easing is kept. If the property has no keyframes,
// its default value is changed and stored.
bool doc_value_by(Doc& d, int layer, const char* name, double add,
                  double times);
// Aligns layers on the canvas as Keynote and Figma do (Arrange > Align). One
// layer is aligned to the canvas and several layers to the box around all of
// them. `how` is left, centre, right, top, middle or bottom, or across or down,
// which spread three or more layers so that the gaps between them are equal.
// Returns false and sets d.error on failure. The change is one undo step.
bool doc_align(Doc& d, const std::vector<int>& layers, const std::string& how);
// Scales a layer to the canvas as Alight Motion's Fit, Fill and Stretch do,
// then centres it on the canvas. `how` is `fit`, which makes it as large as
// possible inside the canvas, `fill`, which makes it cover the canvas, or
// `stretch`, which stretches it to the canvas. Returns false and sets d.error
// on failure. The change is one undo step.
bool doc_fit(Doc& d, int layer, const std::string& how);
// Returns the upright bounding box on the canvas of a layer's 3D bounds at time
// `now`, however the layer is turned or tilted, written to `box` as left, top,
// width, height. Returns false if the layer has no bounds.
bool doc_covers(Doc& d, int layer, double now, double* box);
// Returns a layer's outline on the canvas at time `now`: the convex hull, by
// Andrew's monotone chain, of the layer's points seen through the canvas
// camera. The points are the mesh vertices of a layer that has a built-in shape
// such as a ball, a gem or a ring, otherwise the corners of its bounds for a
// file or a flat layer. A ball gets its round edge, a cube its own outline and
// a flat layer its tilted four corners, and nothing of the layer lies outside.
// Writes x and y pairs in canvas points from the top left, in order round the
// hull, to `xy`, at most 64 pairs. Returns the number of points, or 0 if the
// layer is not shown.
int doc_outline(Doc& d, int layer, double now, double* xy);
// Returns the default value of a property, used when no value is stored for it.
double doc_usual(Doc& d, const char* name);
// Returns the default value of a property on a given layer. A flat layer has no
// thickness (see doc_fx_list), a star has 5 points and any other polygon 6, and
// the inner radius is 0.5.
double doc_usual_on(Doc& d, int layer, const char* name);
// Reads a property at time `at` into `is`. Returns false if the layer does not
// have the property.
bool doc_value(Doc& d, int layer, const char* name, double at, double* is);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_ARRANGE_H_

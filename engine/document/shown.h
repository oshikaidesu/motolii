#ifndef MOTOLII_DOCUMENT_SHOWN_H_
#define MOTOLII_DOCUMENT_SHOWN_H_

// Shown state for the app: the layers there are, how long each is on, the times of keyframes, and
// where a layer appears in the preview.

#include <string>
#include <vector>

#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>

#include "document/kinds.h"

// Returns the layers in the order they lie, the one furthest back first.
std::vector<int> doc_layers(Doc& d);
// Returns how long the layer is on, in seconds, or -1 when it never ends.
double doc_lasts(Doc& d, int layer);
// Returns the times of the keyframes of a property. A property with one keyframe has none.
std::vector<double> doc_key_times(Doc& d, int layer, const char* name);
// Returns half of the width and height of a layer at size 1, before it is placed, in `half`. A
// sheet gives the size of the sheet, and a solid the size of its bounding box. The app draws the
// bounds of a layer from this. `deep`, which may be null, receives half of how far the layer
// reaches towards the camera and away, and is 0 for a flat layer. Returns false when the layer is
// not shown. The result is cached.
bool doc_half(Doc& d, int layer, filament::math::float2* half, float* deep = nullptr);
// Returns where point `p` of the stage appears in the preview, as the stage's camera sees it. The
// result is in points from the top left.
filament::math::double2 doc_seen(Doc& d, filament::math::double3 p);
// Returns the points that draw a camera layer as the working camera sees it, as numbers separated
// by spaces. They are x and y in the preview for the four corners of its frame, the point it looks
// at, and where it is. The frame is the rectangle of the preview at the point it looks at, as large
// as the lens takes in there. This follows the CameraFrame of AbsentMotion and the point of
// interest and camera of After Effects. A point behind the working camera is written "x x". Returns
// an empty text when there is no working camera or the layer is not a camera.
std::string doc_gizmo(Doc& d, int layer, double now);
// Returns how many points of the preview one unit of the stage is, at the depth where the layer
// stands.
double doc_point(Doc& d, int layer, double now);
// Returns where a layer is at time `now`, as the stage places it. A layer on its own that an
// expression moves, or that is delayed, is placed as the member of its copies that it is drawn as.
filament::math::mat4 doc_shown_at(Doc& d, int layer, double now);
// Computes the bounds of a layer in the preview at time `now`, as the stage's camera sees it.
// `frame` receives eight numbers, in points from the top left: the middle x and y, the width, the
// height, the rotation in degrees clockwise as seen, the pivot x and y, and the depth. Returns
// false when the layer is not shown.
bool doc_frame(Doc& d, int layer, double now, double* frame);

#endif  // MOTOLII_DOCUMENT_SHOWN_H_

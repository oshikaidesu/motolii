#ifndef MOTOLII_DOCUMENT_EVALUATE_CAMERA_H_
#define MOTOLII_DOCUMENT_EVALUATE_CAMERA_H_
// camera.h: camera viewpoints, and the look of the canvas: color grading, lens
// effects, fog, room lighting and background.

#include <math/mat4.h>
#include <math/vec3.h>

namespace motolii {

struct Doc;

// A viewpoint computed from a camera layer. `round` is the rotation matrix of
// the camera, `look` is the point it looks at, `eye` is the position of the
// viewer, `up` is the up direction, `far` is the distance of the eye as a
// multiple of the canvas's default distance, and `fov` is the vertical field of
// view in radians.
struct DocViewCamera {
  filament::math::mat4 round;
  filament::math::double3 look, eye, up;
  double far, fov;
};
// Returns the viewpoint of camera layer `camera` at time `now`. Camera 0 means
// the canvas's own camera. The viewpoint looks at the layer's position from a
// direction set by its rotate_y (around the vertical axis), rotate_x (up and
// down) and rotate (roll). The eye is `distance` times the default distance of
// 6 units away, and the field of view of 30 degrees narrows with `zoom`.
DocViewCamera doc_view_camera_of(Doc& d, int camera, double now);
// Applies the look of the project to the canvas: color grading, bloom and lens
// flare, anti-aliasing, vignette, fog, ambient occlusion, screen space
// reflections, room lighting and the background. The settings are properties of
// layer 0, which holds the settings of the canvas itself.
void doc_look(Doc& d);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_CAMERA_H_

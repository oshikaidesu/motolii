#ifndef MOTOLII_DOCUMENT_EVALUATE_CAMERA_H_
#define MOTOLII_DOCUMENT_EVALUATE_CAMERA_H_
// camera.h: camera viewpoints, and the look of the canvas: color grading, lens
// effects, fog, room lighting and background.

#include <math/mat4.h>
#include <math/vec3.h>

#include <string>

namespace filament {
class Skybox;
}  // namespace filament

namespace motolii {

struct Canvas2D;
struct Doc;

// The look of the whole stage as doc_look last applied it: its grade, the
// room that lights it and what is behind everything.
struct DocLook {
  // The stage's grade as last applied by doc_look. It is applied again only
  // when the grade changes.
  std::string graded;
  // The room's own light, as it was when the stage was opened.
  float roomLight = 0.f;
  // Which room lights the stage now (see doc_look).
  std::string roomIs;
  // The room behind everything, once one is set.
  filament::Skybox* sky = nullptr;
  // The color behind everything: a flat color as large as the stage, drawn
  // before everything else in the stage's own view.
  Canvas2D* backdrop = nullptr;
  // The color the backdrop was made in.
  std::string backdropIs;
};

// The camera the stage is seen through at the current time, as doc_evaluate
// last worked it out.
struct DocCamera {
  // The camera the stage is seen through now. 0 means the stage's own camera
  // (see doc_evaluate).
  int looking = 0;
  // The camera of the current time, against the stage's own camera, which is 6
  // units in front and 30 degrees high. rig is how the world is moved for the
  // camera, and a 2D layer moves with it. facing is only how the world is
  // turned, and a 2.5D layer keeps its own angle.
  filament::math::mat4 rig, facing;
  // True if the lens blurs what is off its focus. Applies to solid layers and
  // layers in the world only.
  bool blurred = false;
};

// The window's working camera, like After Effects' working 3D views and
// Alight Motion's view without the camera. Never saved in the project.
struct DocWorkingCamera {
  // True when the window was asked to look through its working camera.
  bool asked = false;
  // The working camera's position around the middle of the world, as three
  // numbers: about, over and how far, the last being a camera's distance.
  double position[3] = {0.0, 0.0, 1.0};
  // True when the stage is seen through the working camera at this time: a
  // camera is on and no video is being exported.
  bool on = false;
};

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

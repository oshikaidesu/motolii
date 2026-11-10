#include "document/evaluate/evaluate_camera.h"

#include <filament/Camera.h>
#include <filament/View.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <vector>

#include "document/document.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/value_at.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

namespace {

// Returns the camera layer in use: the last camera layer in stacking order that
// is active now, or 0 when there is none.
int camera_layer_now(Doc& d, const std::vector<int>& lie, double now) {
  int camera = 0;
  for (int layer : lie)
    if (d.on_stage.shown.count(layer) && d.on_stage.shown[layer].camera) {
      const double since = now - doc_number(d, layer, "start", 0, 0),
                   lasts = doc_number(d, layer, "duration", 0, -1);
      if (since >= 0.0 && (lasts < 0.0 || since < lasts) &&
          doc_number(d, layer, "visible", 0, 1) > 0.5)
        camera = layer;
    }
  return camera;
}

// Depth of field uses Filament's own lens model: sharp at the focus
// distance and blurred away from it as the f-number says. The shutter speed
// follows the f-number, so the image keeps the brightness of the stage's
// default of f/16 at 1/125 s.
void lens_at(Doc& d, int camera, double now, math::double3 eye,
             math::double3 look) {
  Stage& s = *d.stage;
  const double said = camera ? doc_number(d, camera, "aperture", now, 0) : 0.0,
               focus = camera ? doc_number(d, camera, "focus", now, 0) : 0.0;
  d.camera.blurred = !d.working_camera.on && said > 0.0;
  // Filament's widest aperture is f/0.5.
  const double stop = std::max(said, 0.5);
  View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();
  // Update the circle of confusion scale only when it changed.
  if (camera &&
      lens.cocScale != (float)doc_number(d, camera, "blur_level", now, 1))
    lens.cocScale = (float)doc_number(d, camera, "blur_level", now, 1),
    s.view->setDepthOfFieldOptions(lens);
  s.film->setExposure(d.camera.blurred ? (float)stop : 16.f,
                      d.camera.blurred
                          ? (float)(stop * stop / (16.0 * 16.0 * 125.0))
                          : 1.f / 125.f,
                      100.f);
  // The focus distance is the focus property, or the distance to the look-at
  // point when it is 0.
  s.film->setFocusDistance((float)(focus > 0.0 ? focus : length(eye - look)));
}

// In the working view the document camera stays where it is and the stage's
// own camera orbits the origin at the angles and distance in
// d.working_camera.position. A 2D layer belongs to the camera's image and
// to no 3D world, as in the working 3D views of Adobe applications, so it
// is hidden.
void working_view_shown(Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  std::vector<EvaluatedLayer>& lies = evaluation.lies;
  if (d.working_camera.on) {
    const math::mat4 about =
        math::mat4::rotation(d.working_camera.position[0] * (double)TAU / 360.0,
                             math::double3{0, 1, 0}) *
        math::mat4::rotation(d.working_camera.position[1] * (double)TAU / 360.0,
                             math::double3{1, 0, 0});
    s.camera->lookAt(
        (about * math::double4{0, 0, 6.0 * d.working_camera.position[2], 0})
            .xyz,
        math::double3{0.0}, (about * math::double4{0, 1, 0, 0}).xyz);
    s.camera->setProjection(30.0, double(s.w) / double(s.h), 0.05,
                            60.0 * std::max(1.0, d.working_camera.position[2]));
    for (EvaluatedLayer& l : lies) l.on = l.on && l.shown->space != 2;
  }
}

}  // namespace

// The camera is the last camera layer in stacking order that is active now.
// With none, the stage's own camera is used.
void evaluate_camera(Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const double now = evaluation.now;
  const int camera = camera_layer_now(d, evaluation.lie, now);
  // The working view shows the user's view camera instead of the document
  // camera. It needs a camera layer in the document and no export in
  // progress.
  d.working_camera.on =
      d.working_camera.asked && camera && !d.video_export.writing;
  god_view(s, d.working_camera.on);
  // The camera layer whose fog settings apply, read by doc_look. 0 in the
  // working view.
  d.camera.looking = d.working_camera.on ? 0 : camera;
  const DocViewCamera seen = doc_view_camera_of(d, camera, now);
  const math::double3 eye = seen.eye, look = seen.look, up = seen.up;
  const double far = seen.far, fov = seen.fov;
  s.film->lookAt(eye, look, up);
  // An orthographic camera is as large at the point it looks at as the
  // perspective camera shows it there.
  if (camera && doc_word(d, camera, "projection") == "orthographic") {
    const double high = 6.0 * far * std::tan(0.5 * fov),
                 wide = high * double(s.w) / double(s.h);
    s.film->setProjection(Camera::Projection::ORTHO, -wide, wide, -high, high,
                          0.05, 60.0 * std::max(1.0, far));
  } else
    s.film->setProjection(fov * 360.0 / (double)TAU, double(s.w) / double(s.h),
                          0.05, 60.0 * std::max(1.0, far));
  s.film->setShift(camera
                       ? math::double2{doc_number(d, camera, "shift_x", now, 0),
                                       doc_number(d, camera, "shift_y", now, 0)}
                       : math::double2{0.0});
  // Transform from the stage's own camera, six units back along z, to this
  // camera.
  d.camera.rig = s.film->getModelMatrix() *
                 math::mat4::translation(math::double3{0, 0, -6});
  lens_at(d, camera, now, eye, look);
  // The rotation part of d.camera.rig.
  d.camera.facing = math::mat4(d.camera.rig.upperLeft());
  working_view_shown(evaluation);
}

// Glow uses the stage's Filament bloom. A glowing layer brighter than 1 is
// picked up through the bloom threshold, as emissive is. The bloom strength
// follows the strongest glow opacity.
void evaluate_bloom(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const double now = evaluation.now;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  float most = 0.f;
  for (size_t i = 0; i < lies.size(); ++i)
    if (runOf[i] >= 0 && !doc_word(d, lies[i].layer, "glow").empty())
      most = std::max(
          most, (float)doc_number(d, lies[i].layer, "glow_opacity", now, 1));
  if (most > 0.f) {
    View::BloomOptions glow = s.view->getBloomOptions();
    glow.enabled = true, glow.threshold = true,
    glow.strength = std::max(glow.strength, std::clamp(0.35f * most, 0.f, 1.f));
    s.view->setBloomOptions(glow);
  }
}

// The camera's lens is enabled on the stage's own view when solid layers are
// in it.
void evaluate_depth_of_field(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const std::vector<int>& sorts = evaluation.sorts;
  const int base = evaluation.base;
  View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();
  if (lens.enabled !=
      (d.camera.blurred && (base == 1 || (!sorts.empty() && sorts[0]))))
    lens.enabled = !lens.enabled, s.view->setDepthOfFieldOptions(lens);
}

}  // namespace motolii

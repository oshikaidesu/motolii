#include "document/evaluate/camera.h"

#include <filament/Camera.h>
#include <filament/ColorGrading.h>
#include <filament/Engine.h>
#include <filament/IndirectLight.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/Skybox.h>
#include <filament/Texture.h>
#include <filament/ToneMapper.h>
#include <filament/View.h>
#include <image/Ktx1Bundle.h>
#include <ktxreader/Ktx1Reader.h>
#include <math/mat3.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <viewer/Settings.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <string>
#include <vector>

#include "base/file_read.h"
#include "community/quickjs/script.h"
#include "document/document.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluate_camera.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/place.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/viewer_settings.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace math = filament::math;
using filament::Camera;
using filament::ColorGrading;
using filament::IndirectLight;
using filament::LinearToneMapper;
using filament::Skybox;
using filament::Texture;
using filament::View;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

DocViewCamera doc_view_camera_of(Doc& d, int camera, double now) {
  // The camera's orientation: rotate_y (pan), rotate_x (tilt), rotate (roll).
  // With no camera layer the stage's own camera looks straight along -Z, so
  // the rotation matrices are all identity.
  const auto turned = [&](const char* name, math::double3 about) {
    return camera ? math::mat4::rotation(doc_number(d, camera, name, now, 0) *
                                             (double)TAU / 360.0,
                                         about)
                  : math::mat4{};
  };
  DocViewCamera e;
  e.round = turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0}) *
            turned("rotate", {0, 0, 1});
  // The camera's position is the layer's own world position. With no camera
  // layer the stage's own camera sits kStageBack units along +Z, looking at
  // the origin.
  e.eye = camera
              ? (doc_place(d, camera, now) * math::double4{0, 0, 0, 1}).xyz
              : math::double3{0.0, 0.0, kStageBack};
  // The camera looks in its local -Z. One unit ahead gives the look-at point.
  e.look = e.eye + (e.round * math::double4{0, 0, -1, 0}).xyz;
  e.up = (e.round * math::double4{0, 1, 0, 0}).xyz;
  // `far` is a scale on the default clip distance. Keep it at 1 when there is
  // no camera layer so the near/far planes stay as they were.
  e.far = 1.0;
  // Vertical field of view from focal length. The stage uses a 24 mm sensor
  // height (half = 12 mm), matching a 35 mm full-frame crop at 2:3 aspect.
  // Default: 45 mm → ~30° vertical FOV, the same as the old default zoom = 1.
  const double focal =
      camera ? doc_number(d, camera, "focal_length", now, 45.0) : 45.0;
  e.fov = 2.0 * std::atan(12.0 / std::max(focal, 1.0));
  return e;
}

void doc_look(Doc& d) {
  Stage& s = *d.stage;
  // Reads a six digit RRGGBB hex property as a color with components from 0
  // to 1. Returns `otherwise` when the property is not six digits.
  const auto hex = [&](const char* name, float3 otherwise) {
    const std::string w = doc_word(d, 0, name);
    return w.size() == 6
               ? float3{(float)((std::strtol(w.c_str(), nullptr, 16) >> 16) &
                                255),
                        (float)((std::strtol(w.c_str(), nullptr, 16) >> 8) &
                                255),
                        (float)(std::strtol(w.c_str(), nullptr, 16) & 255)} /
                     255.f
               : otherwise;
  };
  // Filament viewer settings files (JSON) with the parameter values of their
  // effects filled in, see stage/effects/viewer_settings.h. They can be on the
  // canvas or on the effects of any layer, as the shelf puts them.
  std::vector<std::string> told;
  // The layers that may carry settings files: the canvas, and every layer whose
  // fx names a .json file.
  std::vector<int> holders{0};
  doc_rows(d,
           sqlite3_mprintf("select distinct layer from keyframe where name = "
                           "'fx' and value like '%%.json%%'"),
           [&](sqlite3_stmt* row) {
             holders.push_back(sqlite3_column_int(row, 0));
           });
  for (const int h : holders)
    for (const std::string& file :
         h == 0 ? script_files(doc_word(d, 0, "script"))
                : doc_fx_list(d, h, true))
      if (DocScript* sc = doc_script_of(d, file); sc && sc->viewer)
        told.push_back(viewer_said(file, sc->parameters, [&](size_t k) {
          return doc_number(d, h, sc->names[k].c_str(), s.now,
                            sc->parameters[k].usual);
        }));
  // True when a settings file sets color grading.
  const bool theirs =
      std::any_of(told.begin(), told.end(), [](const std::string& t) {
        return t.find("\"colorGrading\"") != std::string::npos;
      });
  // The key that detects a change, so the color grading is rebuilt only when
  // this differs from the last one. A settings file's grading is the whole
  // grading, so its text is the key; without one the grading never changes.
  std::string key = "plain";
  if (theirs) {
    key.clear();
    for (const std::string& t : told) key += t;
  }
  if (d.look.graded != key) {
    // The previous grading, destroyed once the new one is set.
    ColorGrading* was = const_cast<ColorGrading*>(s.view->getColorGrading());
    ColorGrading* now = nullptr;
    // A settings file's grading is the whole grading, built as Filament's
    // viewer builds it.
    if (theirs) {
      filament::viewer::Settings in;
      filament::viewer::JsonSerializer read;
      for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
      now =
          filament::viewer::createColorGrading(in.view.colorGrading, s.engine);
    } else {
      // Without a file the grade is Filament's own defaults on the linear tone
      // mapper.
      static LinearToneMapper linear;
      now = ColorGrading::Builder()
                .toneMapper(&linear)
                .exposure(0.f)
                .contrast(1.f)
                .saturation(1.f)
                .vibrance(1.f)
                .whiteBalance(0.f, 0.f)
                .slopeOffsetPower(float3{1.f}, float3{0.f}, float3{1.f})
                .shadowsMidtonesHighlights(
                    float4{1.f, 1.f, 1.f, 0.f}, float4{1.f, 1.f, 1.f, 0.f},
                    float4{1.f, 1.f, 1.f, 0.f}, float4{0.f, 0.333f, 0.55f, 1.f})
                .build(*s.engine);
    }
    s.view->setColorGrading(now);
    if (was) s.engine->destroy(was);
    d.look.graded = key;
  }
  // Bloom, lens flare, vignette, fog, ambient occlusion and screen space
  // reflections are Filament's own defaults, which are all off, until a
  // settings file says otherwise. The edges are smoothed by FXAA, with
  // multisampling off.
  s.view->setBloomOptions({}), s.view->setVignetteOptions({}),
      s.view->setFogOptions({}), s.view->setAmbientOcclusionOptions({}),
      s.view->setScreenSpaceReflectionsOptions({});
  s.view->setAntiAliasing(View::AntiAliasing::FXAA);
  View::MultiSampleAntiAliasingOptions many =
      s.view->getMultiSampleAntiAliasingOptions();
  many.enabled = false;
  s.view->setMultiSampleAntiAliasingOptions(many);
  // Filament settings files are applied over the options above. A section that
  // a file does not name stays as it is.
  if (!told.empty()) {
    filament::viewer::Settings in;
    in.view.bloom = s.view->getBloomOptions(),
    in.view.vignette = s.view->getVignetteOptions(),
    in.view.fog = s.view->getFogOptions();
    in.view.ssao = s.view->getAmbientOcclusionOptions(),
    in.view.screenSpaceReflections = s.view->getScreenSpaceReflectionsOptions();
    filament::viewer::JsonSerializer read;
    for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
    s.view->setBloomOptions(in.view.bloom),
        s.view->setVignetteOptions(in.view.vignette),
        s.view->setFogOptions(in.view.fog);
    s.view->setAmbientOcclusionOptions(in.view.ssao),
        s.view->setScreenSpaceReflectionsOptions(
            in.view.screenSpaceReflections);
  }
  // Remember the intensity of the light that the canvas was opened with.
  if (d.look.roomLight <= 0.f && s.scene->getIndirectLight())
    d.look.roomLight = s.scene->getIndirectLight()->getIntensity();
  std::string which = doc_word(d, 0, "room");
  // The room that the canvas was opened with.
  if (which.empty()) which = "small_studio";
  // Another room: its light is made once from its file and then reused. Every
  // image laid over the canvas is lit by it too.
  if (which != d.look.roomIs) {
    auto& made = d.look.rooms;
    // The first time, register the light in use under the current room name, so
    // that the canvas can switch back to it.
    if (!d.look.roomIs.empty() || made.empty())
      made.emplace(d.look.roomIs.empty() ? "small_studio" : d.look.roomIs,
                   s.scene->getIndirectLight());
    const auto found = made.find(which);
    if (found != made.end())
      s.scene->setIndirectLight(found->second);
    else if (room(s, ("out/" + which + "/" + which + "_ibl.ktx").c_str(),
                  d.look.roomLight))
      made[which] = s.scene->getIndirectLight();
    d.look.roomIs = which;
  }
  if (IndirectLight* room = s.scene->getIndirectLight()) {
    room->setIntensity(d.look.roomLight *
                       (float)doc_number(d, 0, "environment", 0, 1));
    room->setRotation(math::mat3f::rotation(
        (float)(doc_number(d, 0, "environment_rotate", 0, 0) * (double)TAU /
                360.0),
        math::float3{0, 1, 0}));
  }
  // Gives the canvas effects access to the analysis of a sound file.
  d.effects.screen.sounds = [&d](const std::string& file,
                                 const std::string& name, bool fft, int wide) {
    return doc_sound_now(d, 0, file, name, fft, wide);
  };
  // Supplies the parameter values of the canvas effects.
  screen_effects(
      s, d.effects.screen, doc_word(d, 0, "script"),
      [&d](const std::string& file, const std::string& name, double usual) {
        // Called while the frame is drawn, when the render thread does not hold
        // the lock.
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        // Parameters of a mouse: when the followed layer is on the canvas, the
        // value is that layer's position. `pointer` is as on the web, from -1
        // to 1 with y up. The others are from 0 to 1 from the top left, as the
        // uv of the effects.
        static const char* const mice[] = {"pointer", "center", "mouse",
                                           "point"};
        if (const int t = (int)doc_number(d, 0, "follow", 0, 0);
            t > 0 && name.size() > 2 && name[name.size() - 2] == '_')
          for (const char* mouse : mice)
            if (name.compare(0, name.size() - 2, mouse) == 0) {
              double frame[8];
              if (!doc_knows(d, t, nullptr, nullptr, nullptr, false) ||
                  !doc_frame(d, t, d.stage->now, frame))
                break;
              const bool across = name.back() == 'x';
              const double at =
                  across ? frame[0] / d.stage->w : frame[1] / d.stage->h;
              return !strcmp(mouse, "pointer")
                         ? (across ? 2.0 * at - 1.0 : 1.0 - 2.0 * at)
                         : at;
            }
        // The canvas's own time and length are the project's.
        if (name == "clip_time") return d.stage->now;
        if (name == "clip_length") return doc_seconds(d);
        return doc_number(d, 0, doc_screen_parameter(file, name).c_str(),
                          d.stage->now, usual);
      });
  // The background color.
  const std::string behind = doc_word(d, 0, "background");
  // The room itself is shown behind everything, as bright as it lights the
  // canvas. Its sky image is made once for each room.
  if (doc_word(d, 0, "behind") == "room") {
    auto& shown = d.look.skies;
    Skybox*& sky = shown[d.look.roomIs];
    if (!sky) {
      // The sky image refers to this memory, so it must stay alive.
      auto& kept = d.look.skyBytes;
      kept.push_back(read_bytes("out/" + d.look.roomIs + "/" + d.look.roomIs +
                                 "_skybox.ktx"));
      if (!kept.back().empty())
        if (Texture* tex = ktxreader::Ktx1Reader::createTexture(
                s.engine,
                new image::Ktx1Bundle(kept.back().data(),
                                      (uint32_t)kept.back().size()),
                false))
          // The sky shows the sun disc, which is one of the lights. Filament
          // takes the brightness of the sky when it is made.
          sky = Skybox::Builder()
                    .environment(tex)
                    .intensity(d.look.roomLight)
                    .showSun(true)
                    .build(*s.engine);
    }
    if (sky) sky->setLayerMask(0xFF, 0x01);
    s.scene->setSkybox(sky);
  } else
    s.scene->setSkybox(nullptr);
  // A background color is a flat rectangle as large as the canvas, attached to
  // the camera, drawn first in the canvas view without writing depth, so every
  // layer is drawn over it. Filament's sky is drawn after the layers it
  // contains and a flat layer writes no depth, so a sky would be painted over
  // them. The rectangle is opaque, because Filament draws blended sheets after
  // all solid layers whatever their priority, so a blended backdrop was painted
  // over the solids. There is no color when the room is the background.
  const std::string colour = doc_word(d, 0, "behind") == "room" ? "" : behind;
  if (colour != d.look.backdropIs) {
    if (d.look.backdrop)
      canvas_off(s, d.look.backdrop), d.look.backdrop = nullptr;
    if (!colour.empty()) {
      const math::double4 up = s.camera->getProjectionMatrix() *
                               s.camera->getViewMatrix() *
                               math::double4{0, 1, 0, 1};
      // Opaque, so that Filament draws it with the solid layers, first by its
      // priority, and not over them with the blended sheets.
      if ((d.look.backdrop = flat(s, "rect", (float)s.w / (float)s.h, mat4f{},
                                  (float)(2.0 * up.w / up.y),
                                  hex("background", float3{0.f}), "opaque"))) {
        auto& faces = s.engine->getRenderableManager();
        for (const Stage::Renderable& made : s.renderables)
          if (made.of == d.look.backdrop->sheet)
            faces.setPriority(faces.getInstance(made.thing), 0),
                faces.setChannel(faces.getInstance(made.thing), 0);
        d.look.backdrop->look->setDepthWrite(false),
            d.look.backdrop->look->setDepthCulling(false);
      }
    }
    d.look.backdropIs = colour;
  }
  if (d.look.backdrop)
    move(s, d.look.backdrop->sheet,
         [&](int, const mat4f&) { return mat4f(d.camera.rig); });
}

// -- evaluate_camera: the camera phases of doc_evaluate. --

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
          doc_visible(d, layer))
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

// In the working view the Stage's orbital camera orbits the world origin while
// the project's own camera (film) keeps its own viewpoint unchanged. The
// Stage view is always through `s.camera`; the Camera View is always through
// `s.film`. Billboards and 2D layers face whichever camera the current view
// uses, so they look correct in both views without any manual override.
void working_view_shown(Evaluation& evaluation, int camera) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const math::mat4 about =
      math::mat4::rotation(d.working_camera.position[0] * (double)TAU / 360.0,
                           math::double3{0, 1, 0}) *
      math::mat4::rotation(d.working_camera.position[1] * (double)TAU / 360.0,
                           math::double3{1, 0, 0});
  s.camera->lookAt(
      (about *
       math::double4{0, 0, kStageBack * d.working_camera.position[2], 0})
          .xyz,
      math::double3{0.0}, (about * math::double4{0, 1, 0, 0}).xyz);
  s.camera->setProjection(30.0, double(s.w) / double(s.h), kStageNear,
                          60.0 * std::max(1.0, d.working_camera.position[2]));
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
  const DocViewCamera seen = doc_view_camera_of(d, camera, now);
  const math::double3 eye = seen.eye, look = seen.look, up = seen.up;
  const double far = seen.far, fov = seen.fov;
  s.film->lookAt(eye, look, up);
  // An orthographic camera is as large at the point it looks at as the
  // perspective camera shows it there.
  if (camera && doc_word(d, camera, "projection") == "orthographic") {
    const double high = kStageBack * far * std::tan(0.5 * fov),
                 wide = high * double(s.w) / double(s.h);
    s.film->setProjection(Camera::Projection::ORTHO, -wide, wide, -high, high,
                          kStageNear, 60.0 * std::max(1.0, far));
  } else
    s.film->setProjection(fov * 360.0 / (double)TAU, double(s.w) / double(s.h),
                          kStageNear, 60.0 * std::max(1.0, far));
  s.film->setShift(camera
                       ? math::double2{doc_number(d, camera, "shift_x", now, 0),
                                       doc_number(d, camera, "shift_y", now, 0)}
                       : math::double2{0.0});
  lens_at(d, camera, now, eye, look);
  // Set up the working camera first so its model matrix is ready.
  working_view_shown(evaluation, camera);
  // The stage view faces s.camera when the working camera is on; the camera
  // view always faces s.film. Billboards and 2D layers use the facing camera
  // so they look correct in whichever view is shown (Blender's behaviour).
  filament::Camera* const facing_cam =
      d.working_camera.on ? s.camera : s.film;
  d.camera.rig = facing_cam->getModelMatrix() *
                 math::mat4::translation(math::double3{0, 0, -kStageBack});
  d.camera.facing = math::mat4(d.camera.rig.upperLeft());
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

#include "document/evaluate/evaluate.h"

#include <filament/Camera.h>
#include <filament/Color.h>
#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/TransformManager.h>
#include <filament/View.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>
#include <utils/Entity.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <functional>
#include <map>
#include <sstream>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/after_effects/lottie_slots.h"
#include "community/quickjs/script.h"
#include "document/card_table.h"
#include "document/edit/arrange.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/sketch.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/midi_roll.h"
#include "media/video_layer.h"
#include "motion/easing_godot.h"
#include "motion/lottie_motion.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/path_operations.h"
#include "stage/effects/layer_fx.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

void doc_evaluate(Doc& d, double now) {
  Stage& s = *d.stage;
  // Cleared and rebuilt on demand. A flat layer's sheet is now as large as its
  // canvas.
  d.halves.clear(), d.talls.clear();
  // Nothing in the document changes during an evaluation, so what each copy of
  // a layer asks for is computed once and cached in d.placing until the
  // evaluation ends.
  d.placing.clear(), d.evaluating = true;
  // Clears the evaluating state on every exit path, including the early returns
  // below.
  struct Told {
    Doc& d;
    ~Told() { d.evaluating = false, d.placing.clear(); }
  } told{d};
  // A text layer whose words change with time, such as the Timecode and Count
  // Up text effects of AbsentMotion, is updated in place with words_at. If the
  // new words no longer fit the canvas, or the update fails, only that layer is
  // rebuilt with doc_match and evaluation stops.
  if (now == s.now)
    for (auto& [layer, t] : d.shown)
      if (t.wordsMove)
        if (const std::string w = doc_text_shown(d, layer, now);
            w != t.words || (t.drawn && t.drawn->outgrown)) {
          if (t.drawn && words_at(s, t.drawn, w))
            t.words = w;
          else
            return (void)doc_match(d);
        }
  // A cel layer whose keyframes now select a different drawing is rebuilt on
  // its own with doc_match.
  if (now == s.now)
    for (auto& [layer, t] : d.shown)
      if (t.celMove && doc_cel(d, layer, now) != t.cel)
        return (void)doc_match(d);
  const std::vector<int> lie = doc_laid(d);
  // The state of each layer at this time, in stacking order. `on` says whether
  // the layer is shown now. `solid` says whether the layer takes part in depth
  // sorting with other solid layers. `since` is the time in seconds since the
  // layer started. `open` says whether its 3D box is open.
  struct Lies {
    int layer;
    Doc::Shown* shown;
    bool on, solid;
    double since;
    bool open;
  };
  std::vector<Lies> lies;
  // While any layer is solo, only solo layers are shown.
  bool solo = false;
  for (int layer : lie) solo = solo || doc_number(d, layer, "solo", 0, 0) > 0.5;
  // Returns true if the layer is solo, or if a Null above it in the parent
  // chain is solo. A Null's solo applies to the layers under it. The walk stops
  // after 64 levels to guard against parent cycles.
  const auto solo_of = [&](int layer) {
    for (int up = layer, n = 0; up > 0 && n < 64;
         up = (int)doc_number(d, up, "parent", 0, 0), ++n)
      if (doc_number(d, up, "solo", 0, 0) > 0.5 &&
          (up == layer || doc_word(d, up, "shape") == "null"))
        return true;
    return false;
  };
  for (int layer : lie) {
    const auto found = d.shown.find(layer);
    if (found == d.shown.end() || found->second.camera) continue;
    // `since` is the time since the layer started, as an element placed inside
    // it sees it. `lasts` is the layer's duration, negative for unlimited.
    const double since = doc_element_now(d, layer, now) -
                         doc_number(d, layer, "start", 0, 0),
                 lasts = doc_number(d, layer, "duration", 0, -1);
    // The box is open when the layer has depth and its Scale Z is not 0. At
    // Scale Z 0 the box is shut and the layer is one flat sheet; see
    // engine/materials/deep.glsl.
    const bool open = found->second.drawn &&
                      found->second.drawn->boxed.z > 0.f &&
                      doc_literal(d, layer, "scale_z", now, 1) != 0.0;
    // A layer is on when it is within its time range, visible, and not excluded
    // by solo. A layer that is not a 2D layer, or whose box is open, takes part
    // in depth sorting with the solid layers.
    Lies one{layer,
             &found->second,
             since >= 0.0 && (lasts < 0.0 || since < lasts) &&
                 doc_number(d, layer, "visible", 0, 1) > 0.5 &&
                 (!solo || solo_of(layer)),
             found->second.space != 2 || open,
             since,
             open};
    lies.push_back(one);
  }
  // The camera is the last camera layer in stacking order that is active now.
  // With none, the stage's own camera is used.
  {
    int camera = 0;
    for (int layer : lie)
      if (d.shown.count(layer) && d.shown[layer].camera) {
        const double since = now - doc_number(d, layer, "start", 0, 0),
                     lasts = doc_number(d, layer, "duration", 0, -1);
        if (since >= 0.0 && (lasts < 0.0 || since < lasts) &&
            doc_number(d, layer, "visible", 0, 1) > 0.5)
          camera = layer;
      }
    // The working view shows the user's view camera instead of the document
    // camera. It needs a camera layer in the document and no export in
    // progress.
    d.working = d.viewCameraAsked && camera && !d.writing;
    god_view(s, d.working);
    // The camera layer whose fog settings apply, read by doc_look. 0 in the
    // working view.
    d.looking = d.working ? 0 : camera;
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
      s.film->setProjection(fov * 360.0 / (double)TAU,
                            double(s.w) / double(s.h), 0.05,
                            60.0 * std::max(1.0, far));
    s.film->setShift(
        camera ? math::double2{doc_number(d, camera, "shift_x", now, 0),
                               doc_number(d, camera, "shift_y", now, 0)}
               : math::double2{0.0});
    // Transform from the stage's own camera, six units back along z, to this
    // camera.
    d.rig = s.film->getModelMatrix() *
            math::mat4::translation(math::double3{0, 0, -6});
    // Depth of field uses Filament's own lens model: sharp at the focus
    // distance and blurred away from it as the f-number says. The shutter speed
    // follows the f-number, so the image keeps the brightness of the stage's
    // default of f/16 at 1/125 s.
    const double said =
                     camera ? doc_number(d, camera, "aperture", now, 0) : 0.0,
                 focus = camera ? doc_number(d, camera, "focus", now, 0) : 0.0;
    d.blurred = !d.working && said > 0.0;
    // Filament's widest aperture is f/0.5.
    const double stop = std::max(said, 0.5);
    View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();
    // Update the circle of confusion scale only when it changed.
    if (camera &&
        lens.cocScale != (float)doc_number(d, camera, "blur_level", now, 1))
      lens.cocScale = (float)doc_number(d, camera, "blur_level", now, 1),
      s.view->setDepthOfFieldOptions(lens);
    s.film->setExposure(
        d.blurred ? (float)stop : 16.f,
        d.blurred ? (float)(stop * stop / (16.0 * 16.0 * 125.0)) : 1.f / 125.f,
        100.f);
    // The focus distance is the focus property, or the distance to the look-at
    // point when it is 0.
    s.film->setFocusDistance((float)(focus > 0.0 ? focus : length(eye - look)));
    // The rotation part of d.rig.
    d.facing = math::mat4(d.rig.upperLeft());
    // In the working view the document camera stays where it is and the stage's
    // own camera orbits the origin at the angles and distance in
    // d.viewCameraIs. A 2D layer belongs to the camera's image and to no 3D
    // world, as in the working 3D views of Adobe applications, so it is hidden.
    if (d.working) {
      const math::mat4 about =
          math::mat4::rotation(d.viewCameraIs[0] * (double)TAU / 360.0,
                               math::double3{0, 1, 0}) *
          math::mat4::rotation(d.viewCameraIs[1] * (double)TAU / 360.0,
                               math::double3{1, 0, 0});
      s.camera->lookAt(
          (about * math::double4{0, 0, 6.0 * d.viewCameraIs[2], 0}).xyz,
          math::double3{0.0}, (about * math::double4{0, 1, 0, 0}).xyz);
      s.camera->setProjection(30.0, double(s.w) / double(s.h), 0.05,
                              60.0 * std::max(1.0, d.viewCameraIs[2]));
      for (Lies& l : lies) l.on = l.on && l.shown->space != 2;
    }
  }
  doc_look(d);
  d.round = doc_seconds(d);
  // Depth ordering. Flat layers take no part in depth and are ordered by
  // stacking order alone. Solid layers that follow one another sort depth among
  // themselves. Each run of one sort lies wholly over the run before it. All
  // runs are in the stage's own view and are kept in order by Filament render
  // channels. Within a run of flat layers the blend order decides. A flat
  // layer's materials neither read nor write depth.
  std::vector<int> runOf(lies.size(), -1), sorts;
  for (size_t i = 0; i < lies.size(); ++i) {
    // A camera, a behaviour or a light belongs to no run because nothing of it
    // is drawn.
    if (!lies[i].on || lies[i].shown->camera || lies[i].shown->behaviour ||
        !lies[i].shown->light.isNull())
      continue;
    const int sort = lies[i].solid ? 1 : 0;
    if (sorts.empty() || sorts.back() != sort) sorts.push_back(sort);
    runOf[i] = (int)sorts.size() - 1;
  }
  // `base` is 1 when flat layers lie under the first solid layers.
  const int base = sorts.size() > 1 && sorts[0] == 0 && sorts[1] == 1 ? 1 : 0;
  // Returns the effects state of a layer drawn on its own, building it if
  // needed. Unless `shows` is true, the layer's sheet is laid over what is
  // behind it with the layer's blend mode when that mode is add, multiply or
  // screen, which Filament blends natively. Other blend modes are treated as
  // normal for now.
  const auto made = [&](int layer, bool shows) -> ThingFx& {
    const std::string laid = doc_word(d, layer, "blend");
    return thing_fx_built(
        s, d.layerFx[layer],
        shows                                                     ? ""
        : laid == "add" || laid == "multiply" || laid == "screen" ? laid
                                                                  : "",
        !shows && doc_layer_stands(d, layer, d.layerFx[layer]), shows);
  };
  // Returns the scene a layer is drawn in. That is the scene of the nearest
  // ancestor group that has effects of its own and is on now, or the stage's
  // scene if there is none. The walk stops after 64 levels.
  const auto holder = [&](int layer) -> Scene* {
    for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0;
         up > 0 && n < 64; up = (int)doc_number(d, up, "parent", 0, 0), ++n) {
      if (!doc_holds_fx(d, up)) continue;
      const auto at =
          std::find_if(lies.begin(), lies.end(),
                       [&](const Lies& l) { return l.layer == up; });
      if (at != lies.end() && runOf[(size_t)(at - lies.begin())] >= 0)
        return made(up, false).view->getScene();
    }
    return s.scene;
  };
  for (size_t i = 0; i < lies.size(); ++i) {
    if (runOf[i] < 0) continue;
    const int run = runOf[i];
    Doc::Shown& t = *lies[i].shown;
    // A layer with effects of its own is drawn alone and its image is laid in
    // the scene above it; see engine/stage/effects/layer_fx.h.
    const bool own = doc_own_fx(d, lies[i].layer);
    // A solid that shows its own image stays in the stage's scene. It is also
    // filmed by its effects view, together with the stage's lights.
    const bool shows =
        own && doc_layer_shows(d, lies[i].layer, d.layerFx[lies[i].layer]);
    Scene* const above = holder(lies[i].layer);
    Scene* into = own ? made(lies[i].layer, shows).view->getScene() : above;
    // Copy the stage's lights and this layer's entities into the effects view,
    // then continue with the enclosing scene.
    if (shows) {
      s.scene->forEach([&, film = into](utils::Entity e) {
        if (s.engine->getLightManager().hasComponent(e)) film->addEntity(e);
      });
      doc_entities(s, t,
                   [film = into](utils::Entity e) { film->addEntity(e); });
      into = above;
    }
    // Every other run lives in the stage's own scene and is kept in order by
    // Filament channels.
    Scene* const was = t.scene ? t.scene : s.scene;
    // Move the layer's entities into the scene of its run. A layer that is not
    // shown yet is added when it becomes shown.
    if (was != into) {
      if (t.in)
        doc_entities(
            s, t, [&](utils::Entity e) { was->remove(e), into->addEntity(e); });
      t.scene = into;
    }
    // The channel is the run index, capped at Filament's highest channel, 7.
    if (const int channel = std::min(run, 7); channel != t.channel) {
      doc_parts(s, t,
                [&](RenderableManager& faces, RenderableManager::Instance one) {
                  faces.setChannel(one, (uint8_t)channel);
                });
      t.channel = channel;
    }
    // The first time a flat layer is placed in a run, switch off its depth test
    // and depth write.
    if (t.run < 0 && !lies[i].solid)
      doc_material_instances(s, t, [](MaterialInstance* look) {
        look->setDepthCulling(false), look->setDepthWrite(false);
      });
    if (t.lies != (int)i && !lies[i].solid)
      doc_parts(
          s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
            // Each flat layer gets 128 blend-order slots. Its copies are
            // ordered among themselves inside those slots by distance.
            for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
              faces.setBlendOrderAt(one, part, (uint16_t)(i * 128)),
                  faces.setGlobalBlendOrderEnabledAt(one, part, true);
          });
    t.run = run, t.lies = (int)i;
    // Lay the effects sheet where the layer lies, with the same channel and
    // blend order, in the scene of the group the layer is in.
    if (own) {
      auto& faces = s.engine->getRenderableManager();
      thing_fx_into(s, d.layerFx[lies[i].layer], above);
      // `stood` means the sheet stands in the 3D world. A solid layer's sheet
      // is then depth sorted by distance like any solid. A 2D layer's sheet is
      // ordered by stacking order.
      const bool stood = d.layerFx[lies[i].layer].world,
                 deep = stood && lies[i].solid;
      if (stood)
        d.layerFx[lies[i].layer].look->setDepthCulling(deep),
            d.layerFx[lies[i].layer].look->setDepthWrite(deep);
      for (const Stage::Renderable& made : s.renderables)
        if (made.of == d.layerFx[lies[i].layer].sheet ||
            (d.layerFx[lies[i].layer].solid &&
             made.of == d.layerFx[lies[i].layer].solid)) {
          const auto one = faces.getInstance(made.thing);
          // The sheet's vertices are the screen corners, so it is never culled.
          faces.setCulling(one, false),
              faces.setChannel(one, (uint8_t)std::min(run, 7)),
              faces.setBlendOrderAt(one, 0, (uint16_t)(i * 128)),
              faces.setGlobalBlendOrderEnabledAt(one, 0, !deep);
        }
    }
  }
  // Release the effects state of layers that no longer have effects of their
  // own or are gone.
  for (auto e = d.layerFx.begin(); e != d.layerFx.end();) {
    const auto at = std::find_if(lies.begin(), lies.end(), [&](const auto& l) {
      return l.layer == e->first;
    });
    if (at == lies.end() || runOf[(size_t)(at - lies.begin())] < 0 ||
        !doc_own_fx(d, e->first)) {
      // A layer past its time range keeps the effects scene it was last in.
      // Take its parts out of that scene and clear its scene pointer before the
      // scene is released. Otherwise the next evaluation would remove them from
      // a scene that Filament has already destroyed, and Filament does not
      // allow a destroyed scene to be touched. A group's effects scene also
      // holds every layer the group contained and every sheet laid in it, so
      // those are detached too.
      Scene* const gone = e->second.view ? e->second.view->getScene() : nullptr;
      for (auto& [layer, t] : d.shown)
        if (gone && t.scene == gone) {
          if (t.in)
            doc_entities(s, t, [&](utils::Entity x) { gone->remove(x); });
          t.scene = nullptr, t.in = false;
        }
      for (auto& [layer, other] : d.layerFx)
        if (gone && other.in == gone) thing_fx_into(s, other, s.scene);
      thing_fx_off(s, e->second), e = d.layerFx.erase(e);
    } else
      ++e;
  }
  // Draw each layer that has effects of its own into its view first; see
  // moment_fx.h.
  doc_layers_fx(d);
  {
    std::vector<std::pair<int, Doc::Shown*>> laid;
    for (size_t i = 0; i < lies.size(); ++i)
      if (runOf[i] >= 0) laid.emplace_back(lies[i].layer, lies[i].shown);
    doc_layers_read(d, laid);
  }
  // Glow uses the stage's Filament bloom. A glowing layer brighter than 1 is
  // picked up through the bloom threshold, as emissive is. The bloom strength
  // follows the strongest glow opacity.
  {
    float most = 0.f;
    for (size_t i = 0; i < lies.size(); ++i)
      if (runOf[i] >= 0 && !doc_word(d, lies[i].layer, "glow").empty())
        most = std::max(
            most, (float)doc_number(d, lies[i].layer, "glow_opacity", now, 1));
    if (most > 0.f) {
      View::BloomOptions glow = s.view->getBloomOptions();
      glow.enabled = true, glow.threshold = true,
      glow.strength =
          std::max(glow.strength, std::clamp(0.35f * most, 0.f, 1.f));
      s.view->setBloomOptions(glow);
    }
  }
  // The camera's lens is enabled on the stage's own view when solid layers are
  // in it.
  View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();
  if (lens.enabled !=
      (d.blurred && (base == 1 || (!sorts.empty() && sorts[0]))))
    lens.enabled = !lens.enabled, s.view->setDepthOfFieldOptions(lens);
  for (size_t i = 0; i < lies.size(); ++i) {
    const int layer = lies[i].layer;
    Doc::Shown& t = *lies[i].shown;
    const bool in = lies[i].on;
    const Mesh* m = t.video   ? t.video->sheet
                    : t.drawn ? t.drawn->sheet
                              : t.shape;
    if (t.sketch && in) doc_sketch_mesh(d, layer, t, now);
    // Add the layer to, or remove it from, the scene of its run.
    if (in != t.in) {
      Scene* sc = t.scene ? t.scene : s.scene;
      doc_entities(s, t, [&](utils::Entity e) {
        in ? sc->addEntity(e) : sc->remove(e);
      });
      t.in = in;
    }
    if (!in) continue;
    // Show the video frame for the layer's own time. If the stage has a
    // deferred-work queue, the call is queued to run later instead of running
    // now.
    if (t.video) {
      if (s.later)
        s.later->push_back([&s, video = t.video, since = (float)lies[i].since] {
          video_at(s, video, since);
        });
      else
        video_at(s, t.video, (float)lies[i].since);
    }
    // A video layer's look is applied in its material, as ThorVG effects do for
    // an image. The look covers blur, tint and tritone. The blur is in video
    // pixels along blur_direction.
    if (t.video && t.video->look) {
      Canvas2DFx fx;
      std::string why;
      doc_fx(d, layer, now, false, 1.0, fx, why);
      const std::string way = doc_word(d, layer, "blur_direction");
      const float blur = (float)doc_number(d, layer, "blur", now, 0);
      const float4 grade[6] = {
          {way == "vertical" ? 0.f : blur / (float)t.video->w,
           way == "horizontal" ? 0.f : blur / (float)t.video->h, fx.tint,
           fx.tritone},
          {fx.tints[0], 0.f},
          {fx.tints[1], 0.f},
          {fx.tones[0], 0.f},
          {fx.tones[1], 0.f},
          {fx.tones[2], 0.f}};
      t.video->look->setParameter("grade", grade, 6);
    }
    // Play the solid's own animation for each copy, from the time the layer
    // comes on, shifted by the copy's delay and scaled by the speed.
    if (t.solid && !t.solid->moves.empty())
      for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth)
        solid_at(t.solid, doc_word(d, layer, "animation"),
                 (lies[i].since - doc_delay(d, layer, (int)nth)) *
                     doc_number(d, layer, "speed", 0, 1),
                 nth);
    // A Lottie layer: pass the current values of the script parameters into the
    // animation's slots.
    if (t.drawn && t.drawn->lottie)
      if (DocScript* sc = doc_script_of(d, doc_word(d, layer, "file"));
          sc && !sc->parameters.empty()) {
        std::vector<double> v;
        for (size_t k = 0; k < sc->parameters.size(); ++k)
          v.push_back(doc_number(d, layer, sc->names[k].c_str(), now,
                                 sc->parameters[k].usual));
        slots_at(s, t.drawn, lottie_slots_json(sc->parameters, v));
      }
    // A MIDI roll: notes are animated as ALMaMPlayer's note.gd does. A note
    // lights up over 0.17 s and stays lit as long as the note lasts, or 0.2 s
    // longer if the note lasts 0.4 s or less. It then fades over 0.27 s. It
    // grows to 1.03 times its size over 0.2 s and stays grown. While lit it
    // dips by 0.25 + velocity * 0.2 * 0.7, reaching it over 0.17 s and
    // returning over 0.27 s. All curves are sine in and out.
    if (t.drawn &&
        std::filesystem::path(doc_word(d, layer, "file")).extension() ==
            ".mid") {
      const std::string file = doc_word(d, layer, "file");
      const double speed = doc_number(d, layer, "speed", 0, 1),
                   now_in = lies[i].since;
      std::string why;
      // Notes read from each roll file are cached across evaluations.
      static std::map<std::string, std::vector<MidiRollNote>> read;
      const std::string roll = midi_roll_file(
          file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why);
      if (!read.count(roll)) read[roll] = midi_roll_notes(roll);
      // Sine ease in and out, the same as Godot's Tween with TRANS_SINE and
      // EASE_IN_OUT. The input is clamped because a tweener stops at its end,
      // as in Godot's tween.cpp.
      const auto ease = [](double x) {
        return godot::Sine::in_out(std::clamp(x, 0.0, 1.0), 0.0, 1.0, 1.0);
      };
      std::vector<float> lit;
      std::vector<tvg::Matrix> moves;
      for (const MidiRollNote& n : read[roll]) {
        const double hold =
            n.off - n.on > 0.4 ? n.off - n.on : n.off - n.on + 0.2;
        const double up = now_in < n.on ? 0.0
                          : now_in < n.on + hold
                              ? ease((now_in - n.on) / 0.17)
                              : 1.0 - ease((now_in - n.on - hold) / 0.27);
        const float grow = (float)(1.0 +
                                   0.03 * (now_in < n.on
                                               ? 0.0
                                               : ease((now_in - n.on) / 0.2))),
                    dip = (float)(up * (0.25 + n.velocity * 0.2 * 0.7));
        // Grow about the middle of the note's left end, which is where
        // ALMaMPlayer grows it.
        const float x0 = (float)n.x, y0 = (float)(n.y + 0.5 * n.high);
        lit.push_back((float)up);
        moves.push_back(tvg::Matrix{grow, 0.f, x0 * (1.f - grow), 0.f, grow,
                                    y0 * (1.f - grow) + dip, 0.f, 0.f, 1.f});
      }
      lit_at(s, t.drawn, lit, moves, float3{0xed, 0x9e, 0x85} / 255.f);
    }
    // When the 3D box opens or shuts, update the deep parameter and the depth
    // settings of the layer's material and of its copies' materials.
    if (t.drawn && t.drawn->boxed.z > 0.f && lies[i].open != t.drawn->open) {
      t.drawn->open = lies[i].open;
      const float4 box{t.drawn->boxed, lies[i].open ? 1.f : 0.f};
      t.drawn->look->setParameter("deep", box),
          t.drawn->look->setDepthCulling(lies[i].solid),
          t.drawn->look->setDepthWrite(lies[i].solid);
      for (const Stage::Renderable& made : s.renderables)
        if (const auto own = d.copyLooks.find(made.thing.getId());
            made.of == t.drawn->sheet && own != d.copyLooks.end())
          own->second->setParameter("deep", box),
              own->second->setDepthCulling(lies[i].solid),
              own->second->setDepthWrite(lies[i].solid);
    }
    // Bevel, in the box's units and as far across the face as it is deep in the
    // world. The default depth of 12 points has no outside source. The After
    // Effects default of 2 is hardly visible on a title.
    if (t.drawn && t.drawn->edge[0]) {
      Canvas2D& drawn = *t.drawn;
      const float told = (float)(doc_number(d, layer, "bevel_depth", now, 12) /
                                 t.units),
                  z = (float)doc_literal(d, layer, "scale_z", now, 1);
      const float wide = (float)doc_literal(d, layer, "scale_x", now, 1),
                  through = z != 0.f ? told * wide / std::fabs(z) : 0.f;
      // The Step bevel on text with strokes has one stair per stroke band, each
      // as wide as the band. Bevel Depth is the height.
      const bool banded = doc_bevel(d, layer) == 5 && drawn.bands.w > 0.f;
      const float most = banded ? drawn.bands[(int)drawn.bands.w - 1] : 1.f;
      const float across =
          banded ? most * 2.f * drawn.boxed.x / (float)drawn.edgeW : told;
      const float4 cut{across, std::min(through, drawn.boxed.z),
                       told > 0.f ? (float)doc_bevel(d, layer) : 0.f,
                       wide != 0.f ? std::fabs(z / wide) : 1.f};
      const float4 stairs =
          banded ? float4{drawn.bands.x / most, drawn.bands.y / most,
                          drawn.bands.z / most, drawn.bands.w}
                 : float4{0.f};
      drawn.look->setParameter("deepBevel", cut),
          drawn.look->setParameter("deepSteps", stairs);
      for (const Stage::Renderable& made : s.renderables)
        if (const auto own = d.copyLooks.find(made.thing.getId());
            made.of == drawn.sheet && own != d.copyLooks.end())
          own->second->setParameter("deepBevel", cut),
              own->second->setParameter("deepSteps", stairs);
      const int reach =
          (int)std::ceil(across * (float)drawn.edgeW / (2.f * drawn.boxed.x));
      if (drawn.stale || reach > drawn.edgeReach)
        drawn.edgeReach = std::max(reach, drawn.edgeReach),
        edge_ask(s, &drawn, drawn.edgeReach);
    }
    // Surface values of a lit solid, with the same defaults as other solids.
    if (t.drawn && t.drawn->inLight) {
      const float3 surface{
          (float)doc_number(d, layer, "metallic", now, 0.08),
          (float)doc_number(d, layer, "roughness", now, 0.6),
          (float)doc_number(d, layer, "reflectance", now, 0.5)};
      t.drawn->look->setParameter("surface", surface);
      for (const Stage::Renderable& made : s.renderables)
        if (const auto own = d.copyLooks.find(made.thing.getId());
            made.of == t.drawn->sheet && own != d.copyLooks.end())
          own->second->setParameter("surface", surface);
    }
    // The material the layer's sheet is given, with its parameters as they are
    // now; see flat.mat and doc_sheet_material.
    if (const std::string material =
            t.drawn || t.video ? doc_sheet_material(d, layer) : "";
        !material.empty()) {
      const auto at = [&](const char* name, double usual) {
        return (float)doc_number(d, layer, name, now, usual);
      };
      const float vivid = at("vivid", 1.3);
      const float4 coat{material == "glass" ? vivid : at("clear_coat", 0),
                        at("clear_coat_roughness", 0), at("sheen", 0),
                        at("anisotropy", 0)};
      const float4 glass{at("ior", 1.5), at("thickness", 0.5),
                         at("dispersion", 0.1), at("swim", 0.5)};
      const float dark = material == "bubble" ? vivid : at("dark", 4);
      const float3 surface{at("metallic", 0.08), at("roughness", 0.6),
                           at("reflectance", 0.5)};
      doc_parts(
          s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
            for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
              if (MaterialInstance* look =
                      faces.getMaterialInstanceAt(one, part);
                  look->getMaterial()->hasParameter("wearGlass")) {
                look->setParameter("wear", coat),
                    look->setParameter("wearGlass", glass),
                    look->setParameter("wearDark", dark);
                // For a video layer the surface values are set here, as for a
                // drawn sheet above.
                if (t.video) look->setParameter("surface", surface);
              }
          });
    }
    // After Effects' Bevel, Side and Back colors and their Metal. A part with
    // no value looks like the front.
    if (t.drawn && t.drawn->boxed.z > 0.f) {
      float4 colour[3], surface[3];
      const float3 front{(float)doc_number(d, layer, "metallic", now, 0.08),
                         (float)doc_number(d, layer, "roughness", now, 0.6),
                         (float)doc_number(d, layer, "reflectance", now, 0.5)};
      for (int p = 0; p < 3; ++p) {
        const std::string part = p == 0   ? "bevel_"
                                 : p == 1 ? "side_"
                                          : "back_",
                          word = doc_word(d, layer, (part + "color").c_str());
        const long hex =
            word.size() == 6 ? std::strtol(word.c_str(), nullptr, 16) : 0;
        colour[p] =
            float4{(float)((hex >> 16) & 255) / 255.f,
                   (float)((hex >> 8) & 255) / 255.f,
                   (float)(hex & 255) / 255.f, word.size() == 6 ? 1.f : 0.f};
        surface[p] =
            float4{(float)doc_number(d, layer, (part + "metallic").c_str(), now,
                                     front.x),
                   (float)doc_number(d, layer, (part + "roughness").c_str(),
                                     now, front.y),
                   front.z, 0.f};
      }
      t.drawn->look->setParameter("partColour", colour, 3),
          t.drawn->look->setParameter("partSurface", surface, 3);
      for (const Stage::Renderable& made : s.renderables)
        if (const auto own = d.copyLooks.find(made.thing.getId());
            made.of == t.drawn->sheet && own != d.copyLooks.end())
          own->second->setParameter("partColour", colour, 3),
              own->second->setParameter("partSurface", surface, 3);
    }
    // Set the strength of each sketch line as it is now. When a strength
    // changed, the cached drawing is dropped so it is drawn again.
    if (t.drawn && t.drawn->sketchLines) {
      bool moved = false;
      for (auto& [line, strong] : *t.drawn->sketchLines) {
        const double is = doc_number(
            d, layer, ("js_line_" + std::to_string(line)).c_str(), now, 1);
        moved = moved || is != strong, strong = is;
      }
      if (moved)
        cache_drop(s, t.drawn), t.drawn->shownAt = t.drawn->sketchAt = -1;
    }
    if (t.drawn && t.drawn->seconds > 0.f)
      canvas_at(s, t.drawn,
                std::fmod((float)doc_own_time(d, layer, now, lies[i].since),
                          t.drawn->seconds));
    // Update the layer's effects. Those that move are drawn again.
    if (t.drawn && !t.drawn->effects.empty()) {
      Canvas2DFx fx;
      std::string why;
      if (doc_fx(d, layer, now, false, t.units, fx, why)) fx_at(s, t.drawn, fx);
    }
    if (t.drawn && t.drawn->shape)
      trim_at(s, t.drawn, (float)doc_number(d, layer, "trim", now, 0),
              (float)doc_number(d, layer, "trim_begin", now, 0),
              (float)doc_number(d, layer, "trim_offset", now, 0));
    // A shape cut into triangles is bent in its material and its copies'
    // materials, and nothing is drawn again.
    if (t.drawn && t.drawn->cut) {
      const auto num = [&](const char* name, double otherwise) {
        return (float)doc_number(d, layer, name, now, otherwise);
      };
      const float deg = (float)(TAU / 360.0), since = (float)lies[i].since;
      // True when a behaviour gives each copy its own bend, so each copy needs
      // its own material.
      bool driven = false;
      // Falloff region of a behaviour that drives a bend, weighed point by
      // point in the material: a circle where the region's shape lies, as large
      // as the shape. Its fourth component is the softness, negative when
      // inverted.
      float4 region{0.f};
      // Fills `bends`, eight float4 values, for one copy. Slots 0 to 3 hold
      // warp, bend and twist, skew and squash, and wiggle. Slot 4 holds
      // stretch, slots 5 and 6 the corner pins, and slot 7 the falloff region.
      // A property driven by a behaviour takes that behaviour's value for this
      // copy.
      const auto bendsOf = [&](int copy, int n, float4* bends,
                               const math::double3* where = nullptr) {
        const auto at = [&](const char* name, double otherwise) {
          if (const int by = doc_driven_by(d, layer, name)) {
            driven = true;
            // A behaviour with a region weighs points of the shape, not whole
            // copies.
            if (const int f = (int)doc_number(d, by, "region", 0, 0);
                f && d.shown.count(f) && d.shown[f].drawn) {
              const math::mat4 there = doc_place(d, f, now, 0, 0, false);
              const math::double4 middle = there * math::double4{0, 0, 0, 1};
              const double r = length(
                               (there *
                                math::double4{0.5 * d.shown[f].drawn->sheetHigh,
                                              0, 0, 0})
                                   .xyz),
                           soft = doc_number(d, by, "falloff_soft", now, 0);
              region =
                  float4{(float)middle.x, (float)middle.y, (float)r,
                         (float)(doc_number(d, by, "falloff_invert", 0, 0) > 0.5
                                     ? -std::max(soft, 1e-4)
                                     : soft)};
              return (float)doc_behaviour_at(d, by, copy, n, now);
            }
            return (float)doc_given(d, by, copy, n, now, num(name, otherwise),
                                    where);
          }
          return num(name, otherwise);
        };
        const float4 all[7] = {
            {at("warp", 0), at("warp_width", 0.5), at("warp_speed", 1) * since,
             at("warp_angle", 0) * deg},
            {at("bend", 0) * deg,
             doc_word(d, layer, "bend_direction") == "vertical" ? 1.f : 0.f,
             at("twist", 0) * deg, at("pinch", 0)},
            {at("skew", 0) * deg, at("skew_axis", 0) * deg, at("squash", 0),
             0.5f * t.drawn->wideBy},
            {at("wiggle", 0), at("wiggle_detail", 3),
             at("wiggle_speed", 1) * since, num("seed", 0) * 7.31f},
            {0.f, 0.f, num("stretch", 0), 0.f},
            {at("pin_tl_x", 0), at("pin_tl_y", 0), at("pin_tr_x", 0),
             at("pin_tr_y", 0)},
            {at("pin_bl_x", 0), at("pin_bl_y", 0), at("pin_br_x", 0),
             at("pin_br_y", 0)}};
        std::copy(all, all + 7, bends);
        bends[7] = region;
      };
      float4 bends[8];
      bendsOf(0, 1, bends);
      // Stretch follows motion. Slot 4 holds where the layer's middle was 1/60
      // s ago, seen from the layer's current rotation and size and scaled to
      // units per second.
      if (bends[4].z != 0.f) {
        const math::mat4 was = doc_place(d, layer, now - 1.0 / 60.0),
                         is = doc_place(d, layer, now);
        const math::float4 back = inverse(is) * was * math::float4{0, 0, 0, 1};
        bends[4].x = (float)(-60.0 * back.x),
        bends[4].y = (float)(-60.0 * back.y);
      }
      t.drawn->look->setParameter("bends", bends, 8);
      if (t.drawn->edgeLook) t.drawn->edgeLook->setParameter("bends", bends, 8);
      // Returns another shape's path at this time, placed in this layer's units
      // as shape_cut lays it out. With `all` true the path of every copy of the
      // other layer is included.
      const auto other = [&](int with, bool all) {
        Canvas2D::Other o;
        const auto found = d.shown.find(with);
        if (with == layer || found == d.shown.end() || !found->second.drawn ||
            !found->second.drawn->cut)
          return o;
        const Canvas2D* a = t.drawn;
        const Canvas2D* b = found->second.drawn;
        const math::mat4 back = inverse(doc_place(d, layer, now));
        const tvg::PathCommand* cmds;
        const tvg::Point* pts;
        uint32_t cmdsCnt = 0, ptsCnt = 0;
        b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
        const int many = all ? doc_members(d, with) : 1;
        // A plate can be cut by a whole grid of copies.
        for (int copy = 0; copy < many; ++copy) {
          const math::mat4 to =
              back * (many > 1 ? doc_place(d, with, now, 0, copy, true)
                               : doc_place(d, with, now));
          o.by.insert(o.by.end(), cmds, cmds + cmdsCnt);
          for (uint32_t k = 0; k < ptsCnt; ++k) {
            const math::double4 on =
                to * math::double4{(pts[k].x - 0.5 * b->cutW) / b->plainHigh *
                                       b->sheetHigh,
                                   (0.5 * b->plainHigh - pts[k].y) /
                                       b->plainHigh * b->sheetHigh,
                                   0.0, 1.0};
            o.at.push_back(
                {(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW),
                 (float)(0.5 * a->plainHigh -
                         on.y / a->sheetHigh * a->plainHigh)});
          }
        }
        return o;
      };
      // `join` combines this shape with another using the path operations of
      // Skia, in the order subtract, intersect, union, exclude; see
      // engine/stage/canvas/skia_path_operations.cpp. `morph` turns this shape
      // toward another by `much`.
      Canvas2D::Other join, morph;
      const std::string how = doc_word(d, layer, "boolean");
      for (int k = 0; k < 4; ++k)
        if (how == std::array<const char*, 4>{"subtract", "intersect", "union",
                                              "exclude"}[(size_t)k])
          join = other((int)doc_number(d, layer, "boolean_with", 0, 0), true),
          join.how = k;
      if (const float much = num("morph", 0); much > 0.f)
        morph = other((int)doc_number(d, layer, "morph_to", 0, 0), false),
        morph.much = much;
      // Morph steps blend every step at once.
      if (const int steps = (int)doc_number(d, layer, "morph_steps", 0, 0);
          steps > 1)
        morph = other((int)doc_number(d, layer, "morph_to", 0, 0), false),
        morph.much = 1.f, morph.how = std::min(steps, 64);
      // `trace` is the track of another layer over the last trail_length
      // seconds, as in Cavalry's Trails. It follows the middle of that layer
      // and is expressed in this layer's path units.
      Canvas2D::Other trace;
      if (const int with = (int)doc_number(d, layer, "trail", 0, 0);
          with && with != layer && d.shown.count(with)) {
        const math::mat4 back = inverse(doc_place(d, layer, now));
        const double length =
            std::max(1e-3, doc_number(d, layer, "trail_length", now, 1));
        const Canvas2D* a = t.drawn;
        // The track is sampled on a grid of 64 ticks over its length, fixed in
        // time. A tick is computed once and cached in d.tracks, so each
        // evaluation computes only the ticks that are new. The two ends are
        // where the other layer was at the start of the window and where it is
        // now.
        const double step = length / 64.0, last = std::floor(now / step);
        if (d.tracks.size() > 200000) d.tracks.clear();
        const auto was = [&](double t, long long tick) {
          if (tick < 0)
            return (doc_shown_at(d, with, t) * math::double4{0, 0, 0, 1}).xyz;
          auto found = d.tracks.find({with, step, tick});
          if (found == d.tracks.end())
            found = d.tracks
                        .emplace(std::make_tuple(with, step, tick),
                                 (doc_shown_at(d, with, t) *
                                  math::double4{0, 0, 0, 1})
                                     .xyz)
                        .first;
          return found->second;
        };
        const auto put = [&](math::double3 world) {
          const math::double4 on = back * math::double4{world, 1.0};
          trace.by.push_back(trace.by.empty() ? tvg::PathCommand::MoveTo
                                              : tvg::PathCommand::LineTo);
          trace.at.push_back(
              {(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW),
               (float)(0.5 * a->plainHigh -
                       on.y / a->sheetHigh * a->plainHigh)});
        };
        put(was(now - length, -1));
        for (long long k = (long long)last - 63; k <= (long long)last; ++k)
          if ((double)k * step > now - length) put(was((double)k * step, k));
        put(was(now, -1));
      }
      // A freehand stroke with AbsentMotion drawing effects such as Stroke
      // Taper and Drawing Progress. Its outline is regenerated as those effects
      // make it now with absent_drawing and converted to the path's own units.
      // It is regenerated only when the effect parameters change.
      if (const std::string drawn =
              trace.by.empty() ? doc_word(d, layer, "drawing") : std::string();
          !drawn.empty() &&
          doc_word(d, layer, "fx").find(".am") != std::string::npos) {
        std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
        std::erase_if(on, [](const AbsentEffect& e) {
          return e.id != "stroketaper" && e.id != "drawingprogress";
        });
        std::string key = std::to_string(std::hash<std::string>{}(drawn));
        for (const AbsentEffect& e : on)
          for (const auto& [name, v] : e.params)
            for (const float one : v) key += " " + std::to_string(one);
        auto& kept = d.drawingKept[layer];
        if (!on.empty() && kept.first != key) {
          kept = {key,
                  absent_drawing(drawn, on, layer, 0.0, 1000.0, 0.0, false)};
        }
        std::vector<tvg::PathCommand> c;
        std::vector<tvg::Point> p;
        if (!on.empty() && sk_svg(kept.second.c_str(), c, p)) {
          const Canvas2D* a = t.drawn;
          for (tvg::Point& at : p)
            at = {0.5f * a->cutW + at.x * a->plainHigh,
                  0.5f * a->plainHigh + at.y * a->plainHigh};
          trace.by = std::move(c), trace.at = std::move(p);
        }
      }
      // Cut the path again if anything about it changed.
      cut_at(
          s, t.drawn,
          float3{num("trim", 0), num("trim_begin", 0), num("trim_offset", 0)},
          {num("round", 0), num("bloat", 0), num("zigzag", 0),
           num("zigzag_ridges", 5), num("zigzag_smooth", 0), num("offset", 0),
           num("rough", 0), num("rough_detail", 0.03),
           std::round(num("resample", 0)), num("voxel", 0)},
          join, morph, trace);
      t.drivenLooks = driven;
      const int members = driven ? doc_members(d, layer) : 1;
      auto& faces = s.engine->getRenderableManager();
      for (const Stage::Renderable& made : s.renderables) {
        if (made.of != t.drawn->sheet || made.matte) continue;
        // When a behaviour drives a bend, each copy gets its own bends in its
        // own material and its edge's material.
        if (driven && !made.many) {
          float4 own[8];
          // Where this copy lies, which a falloff weighs.
          const math::double3 where{made.place[3].x, made.place[3].y,
                                    made.place[3].z};
          bendsOf(std::max(0, made.nth), members, own, &where);
          if (own[4].z == 0.f) own[4] = bends[4];
          const auto one = faces.getInstance(made.thing);
          MaterialInstance*& look = d.copyLooks[made.thing.getId()];
          if (!look)
            look = MaterialInstance::duplicate(t.drawn->look),
            faces.setMaterialInstanceAt(one, 0, look);
          look->setParameter("bends", own, 8);
          if (t.drawn->edgeLook && faces.getPrimitiveCount(one) > 1) {
            MaterialInstance*& edge = d.copyEdges[made.thing.getId()];
            if (!edge)
              edge = MaterialInstance::duplicate(t.drawn->edgeLook),
              faces.setMaterialInstanceAt(one, 1, edge);
            edge->setParameter("bends", own, 8);
          }
        } else if (const auto own = d.copyLooks.find(made.thing.getId());
                   own != d.copyLooks.end())
          own->second->setParameter("bends", bends, 8);
      }
    }
    if (t.drawn && t.drawn->shape)
      bend_at(s, t.drawn, (float)doc_number(d, layer, "round", now, 0),
              (float)doc_number(d, layer, "bloat", now, 0),
              (float)doc_number(d, layer, "zigzag", now, 0),
              (float)doc_number(d, layer, "zigzag_ridges", now, 5),
              (float)doc_number(d, layer, "zigzag_smooth", now, 0),
              (float)doc_number(d, layer, "offset", now, 0));
    const mat4f place = mat4f(doc_place(d, layer, now));
    // Each copy, the first included, is delayed as late as its order says and
    // placed as its expressions say.
    const bool staggered = doc_staggered(d, layer, now);
    // A joining layer's copies lie between another layer's copies.
    const std::vector<math::mat4> joins =
        doc_number(d, layer, "connect", 0, 0) != 0.0
            ? doc_joins(d, layer, now)
            : std::vector<math::mat4>{};
    if (t.grains && t.look)
      t.look->setParameter("dissolve",
                           (float)doc_number(d, layer, "dissolve", now, 0)),
          t.look->setParameter("grain",
                               (float)doc_number(d, layer, "grain", now, 1));
    // The effect of a splat layer: its uniforms are evaluated at the layer's
    // own time. The parameters come from the document, then the effect's own
    // updateEffect runs.
    if (t.grains && t.look && t.splatFx) {
      const auto said = t.splatFx->uniforms(
          std::max(0.0, now - doc_number(d, layer, "start", 0, 0)), 1.0 / 60.0,
          [&](const std::string& parameter, double usual) {
            return doc_number(
                d, layer,
                doc_screen_parameter(t.splatFxFile, parameter).c_str(), now,
                usual);
          });
      for (const auto& [n, f] : said) {
        if (f.size() == 1)
          t.look->setParameter(n.c_str(), f[0]);
        else if (f.size() == 2)
          t.look->setParameter(n.c_str(), float2{f[0], f[1]});
        else if (f.size() == 3)
          t.look->setParameter(n.c_str(), float3{f[0], f[1], f[2]});
        else if (f.size() >= 4)
          t.look->setParameter(n.c_str(), float4{f[0], f[1], f[2], f[3]});
      }
      // When the effect finishes, switch to the plain material, as PlayCanvas
      // takes the shader off. If time goes back before the end, switch back to
      // the effect's material.
      if (t.splatPlain && t.splatFx->finished() != t.splatDone) {
        t.splatDone = t.splatFx->finished();
        doc_parts(
            s, t,
            [&](RenderableManager& faces, RenderableManager::Instance one) {
              faces.setMaterialInstanceAt(one, 0,
                                          t.splatDone ? t.splatPlain : t.look);
            });
      }
    }
    if (t.solid)
      for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth)
        solid_to(s, t.solid,
                 nth || staggered
                     ? mat4f(doc_place(d, layer, now, 0, (int)nth, staggered))
                     : place,
                 nth);
    else if (doc_number(d, layer, "connect", 0, 0) != 0.0)
      move(s, m, [&](int nth, const mat4f&) {
        return (size_t)nth < joins.size() ? mat4f(joins[(size_t)nth])
                                          : mat4f::scaling(float3{0.f});
      });
    else {
      // Distance of each copy from the camera. Copies further away are drawn
      // first, within the layer's own place.
      std::vector<float> far;
      const mat4f eye = mat4f(s.camera->getViewMatrix());
      const std::string fills = doc_word(d, layer, "copy_fill");
      // Copies coloured along their order are drawn in that order and not
      // sorted by distance.
      const bool flatLayer =
          !lies[i].solid && (fills.empty() || fills == "none");
      // Copies drawn in one batch are sorted with the farthest first. Each
      // copy's own order does the same below.
      move(
          s, m,
          [&](int nth, const mat4f&) {
            const mat4f at =
                nth || staggered
                    ? mat4f(doc_place(d, layer, now, 0, nth, staggered))
                    : place;
            if ((size_t)nth >= far.size()) far.resize((size_t)nth + 1, 0.f);
            far[(size_t)nth] = -(eye * at[3]).z;
            return at;
          },
          flatLayer ? &eye : nullptr);
      if (far.size() > 1 && !lies[i].solid && t.lies >= 0) {
        std::vector<size_t> order(far.size());
        for (size_t k = 0; k < order.size(); ++k) order[k] = k;
        std::stable_sort(order.begin(), order.end(),
                         [&](size_t a, size_t b) { return far[a] > far[b]; });
        std::vector<uint16_t> place_of(far.size());
        for (size_t k = 0; k < order.size(); ++k)
          place_of[order[k]] =
              (uint16_t)(k * 127 / std::max<size_t>(1, order.size() - 1));
        auto& faces = s.engine->getRenderableManager();
        for (const Stage::Renderable& made : s.renderables) {
          if (made.of != m || made.nth < 0 ||
              (size_t)made.nth >= place_of.size())
            continue;
          const auto one = faces.getInstance(made.thing);
          for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
            faces.setBlendOrderAt(
                one, part,
                (uint16_t)(t.lies * 128 + place_of[(size_t)made.nth]));
        }
      }
    }
    // A solid whose sketch gives each copy a colour: each such copy gets a
    // material of its own.
    if (const auto told = d.scripted.find(layer);
        told != d.scripted.end() && t.look && !t.drawn && !t.video) {
      auto& faces = s.engine->getRenderableManager();
      for (const Stage::Renderable& made : s.renderables) {
        if (made.of != m || made.matte || made.nth < 0 ||
            (size_t)made.nth >= told->second.copies.size() ||
            told->second.copies[(size_t)made.nth].colour < 0.0)
          continue;
        MaterialInstance*& own = d.copyLooks[made.thing.getId()];
        if (!own)
          own = MaterialInstance::duplicate(t.look),
          faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
        const long hex = (long)told->second.copies[(size_t)made.nth].colour;
        own->setParameter(
            "color",
            float4{Color::toLinear<ACCURATE>(sRGBColor{
                       float3{(float)((hex >> 16) & 255),
                              (float)((hex >> 8) & 255), (float)(hex & 255)} /
                       255.f}),
                   1.f});
      }
    }
    // The opacity includes AbsentMotion's Pulse Opacity and the opacity of the
    // groups the layer is in.
    const double whole = doc_number(d, layer, "opacity", now, 1) *
                         doc_absent_opacity(d, layer, now) *
                         doc_group_opacity(d, layer, now);
    const auto fxOf = d.layerFx.find(layer);
    // With effects of its own, opacity is applied after the effects, on the
    // effects sheet. After Effects renders a layer's masks, effects and then
    // transform in that order.
    const bool sheetClear =
        fxOf != d.layerFx.end() && fxOf->second.look &&
        fxOf->second.look->getMaterial()->hasParameter("opacity");
    if (sheetClear) fxOf->second.look->setParameter("opacity", (float)whole);
    const double ownClear = sheetClear ? 1.0 : whole;
    if (MaterialInstance* look = t.video   ? t.video->look
                                 : t.drawn ? t.drawn->look
                                           : nullptr)
      look->setParameter("opacity", (float)ownClear);
    if (t.drawn && t.drawn->edgeLook)
      t.drawn->edgeLook->setParameter("opacity", (float)ownClear);
    // Copies coloured along a ramp in their order each get a material of their
    // own, initialised from the layer's material.
    if (MaterialInstance* main = t.video   ? t.video->look
                                 : t.drawn ? t.drawn->look
                                           : nullptr) {
      std::vector<float3> ramp;
      std::istringstream said(doc_word(d, layer, "copy_fill"));
      for (std::string one; said >> one;) {
        if (one == "none") break;
        const long rgb = std::strtol(one.c_str(), nullptr, 16);
        ramp.push_back(Color::toLinear<ACCURATE>(
            sRGBColor{float3{(float)((rgb >> 16) & 255),
                             (float)((rgb >> 8) & 255), (float)(rgb & 255)} /
                      255.f}));
      }
      // With one colour, every copy uses it.
      if (ramp.size() == 1) ramp.push_back(ramp[0]);
      const std::vector<float2>& letters =
          t.drawn ? t.drawn->letters : std::vector<float2>{};
      // A script can give each copy its own opacity.
      const auto scripted = d.scripted.find(layer);
      // AbsentMotion's repeat gives each copy its own opacity, for example the
      // far copies of a scatter field.
      const std::vector<AbsentCopy>& absent = doc_absent_copies(d, layer, now);
      const bool clears =
          (scripted != d.scripted.end() &&
           std::any_of(scripted->second.copies.begin(),
                       scripted->second.copies.end(),
                       [](const ScriptCopy& c) { return c.opacity != 1.0; })) ||
          std::any_of(absent.begin(), absent.end(),
                      [](const AbsentCopy& c) { return c.alpha < 0.999; });
      // A behaviour can give each copy its own opacity or its own place on the
      // ramp.
      const bool clearEach = doc_driven_by(d, layer, "opacity") != 0,
                 pickEach = doc_driven_by(d, layer, "copy_fill_at") != 0;
      // The last copy has this opacity and the first has the layer's, as in
      // After Effects' Repeater End Opacity.
      const double fadeTo = std::clamp(
          doc_number(d, layer, "copy_opacity_end", now, 1), 0.0, 1.0);
      // A staggered copy fades as late as it moves. GSAP's stagger applies
      // every value of a tween, and After Effects' range selector applies
      // Opacity together with the rest.
      const bool clearLate = !sheetClear &&
                             doc_number(d, layer, "stagger", 0, 0) > 0.0 &&
                             doc_key_times(d, layer, "opacity").size() > 1;
      if (ramp.size() < 2 && letters.empty() && !clears && !t.drivenLooks &&
          !clearEach && !pickEach && fadeTo == 1 && !clearLate)
        doc_copy_looks_off(d, m, main);
      else {
        auto& faces = s.engine->getRenderableManager();
        const int n = doc_members(d, layer);
        for (const Stage::Renderable& made : s.renderables) {
          if (made.of != m || made.matte) continue;
          MaterialInstance*& own = d.copyLooks[made.thing.getId()];
          if (!own)
            own = MaterialInstance::duplicate(main),
            faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
          // Copies drawn together in one batch: set the ramp and where this
          // batch's first copy lies on it. flat.mat colours each copy.
          if (made.many) {
            float4 colours[8] = {};
            for (size_t k = 0; k < ramp.size() && k < 8; ++k)
              colours[k] = float4{ramp[k], 1.f};
            own->setParameter("ramp", colours, 8);
            own->setParameter(
                "rampOf",
                ramp.size() >= 2
                    ? float4{(float)made.nth, (float)n,
                             (float)std::min<size_t>(ramp.size(), 8),
                             doc_word(d, layer, "copy_fill_way") == "cycle"
                                 ? 1.f
                                 : 0.f}
                    : float4{0.f});
            if (ramp.size() < 2)
              own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});
            own->setParameter("copyFade",
                              float4{(float)fadeTo, (float)n, (float)made.nth,
                                     fadeTo != 1 ? 1.f : 0.f});
          }
          // Copies drawn one by one. With copy_fill_way set to cycle, each copy
          // takes the ramp colours in turn. Otherwise the colour is picked
          // along the ramp in their order, or where the copy_fill_at behaviour
          // says, 0 for the first colour and 1 for the last. With no ramp the
          // layer's own wash is used, which also fills a shape cut into
          // triangles.
          else if (ramp.size() >= 2 &&
                   doc_word(d, layer, "copy_fill_way") == "cycle")
            own->setParameter(
                "wash", float4{ramp[(size_t)made.nth % ramp.size()], 1.f});
          else if (ramp.size() >= 2) {
            const math::double3 where{made.place[3].x, made.place[3].y,
                                      made.place[3].z};
            const double order =
                n > 1 ? (double)made.nth / (double)(n - 1) : 0.0;
            const double pick =
                pickEach
                    ? std::clamp(
                          doc_given(d, doc_driven_by(d, layer, "copy_fill_at"),
                                    made.nth, n, now, order, &where),
                          0.0, 1.0)
                    : order;
            const float along = (float)pick * (float)(ramp.size() - 1);
            const size_t i = std::min((size_t)along, ramp.size() - 2);
            own->setParameter(
                "wash",
                float4{mix(ramp[i], ramp[i + 1], along - (float)i), 1.f});
          } else
            own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});
          // The copy's own letter.
          if ((size_t)made.nth < letters.size())
            own->setParameter("window",
                              float4{letters[(size_t)made.nth].x,
                                     letters[(size_t)made.nth].y, 1.f, 0.f});
          const double clear =
              (scripted != d.scripted.end() &&
                       (size_t)made.nth < scripted->second.copies.size()
                   ? scripted->second.copies[(size_t)made.nth].opacity
                   : 1.0) *
              ((size_t)made.nth < absent.size() ? absent[(size_t)made.nth].alpha
                                                : 1.0);
          const math::double3 here{made.place[3].x, made.place[3].y,
                                   made.place[3].z};
          const int clearBy = doc_driven_by(d, layer, "opacity");
          // A staggered copy's opacity is delayed by its stagger. Otherwise a
          // behaviour that drives opacity decides, and a relation chooses by
          // the layer's place among its layers. With neither, the layer's
          // opacity is used.
          const double opacity =
              clearLate    ? ownClear /
                                 std::max(doc_number(d, layer, "opacity", now, 1),
                                          1e-6) *
                                 doc_number(d, layer, "opacity",
                                            now - doc_delay(d, layer, made.nth), 1)
              : !clearEach ? ownClear
              : doc_among(doc_relations, doc_word(d, clearBy, "file"))
                  ? std::clamp(doc_literal(d, layer, "opacity", now, 1), 0.0,
                               1.0)
                  : std::clamp(
                        doc_given(d, clearBy, made.nth, n, now,
                                  doc_number(d, layer, "opacity", now, 1),
                                  &here),
                        0.0, 1.0);
          const double fade =
              n > 1 ? 1 + (fadeTo - 1) * (double)made.nth / (double)(n - 1)
                    : 1.0;
          own->setParameter(
              "opacity", (float)(opacity * std::clamp(clear, 0.0, 1.0) * fade));
          // The edge's own material: a frame alone, filled with nothing, is
          // coloured per copy as its fill would be, and gets the copy's
          // opacity.
          if (t.drawn && t.drawn->edgeLook && !made.many) {
            const auto one = faces.getInstance(made.thing);
            if (faces.getPrimitiveCount(one) > 1) {
              MaterialInstance*& edge = d.copyEdges[made.thing.getId()];
              if (!edge)
                edge = MaterialInstance::duplicate(t.drawn->edgeLook),
                faces.setMaterialInstanceAt(one, 1, edge);
              if (t.drawn->hollow && ramp.size() >= 2) {
                edge->setParameter("wash", own->getParameter<float4>("wash"));
              }
              edge->setParameter(
                  "opacity", (float)(opacity * std::clamp(clear, 0.0, 1.0)));
            }
          }
          own->setParameter("glowing",
                            (float)doc_number(d, layer, "emissive", now, 0));
        }
      }
    }
    // How much the layer lights itself now: emissive, plus a share of the glow
    // opacity that the bloom picks up when it is past 1. This applies to a flat
    // layer's sheet and a solid's own faces.
    const float shine =
        (float)doc_number(d, layer, "emissive", now, 0) +
        (doc_word(d, layer, "glow").empty()
             ? 0.f
             : 0.35f * (float)doc_number(d, layer, "glow_opacity", now, 1));
    doc_material_instances(s, t, [&](MaterialInstance* look) {
      if (look->getMaterial()->hasParameter("glowing"))
        look->setParameter("glowing", shine);
    });
  }
  // Soft shadows, Filament's PCSS, are used on the stage's own view while any
  // light that is on asks for them. Otherwise crisp shadows are used.
  {
    bool soft = false;
    for (const Lies& one : lies)
      soft = soft || (one.on && !one.shown->light.isNull() &&
                      doc_number(d, one.layer, "shadow_softness", 0, 0) > 0.0);
    s.view->setShadowType(soft ? View::ShadowType::PCSS
                               : View::ShadowType::PCF);
  }
  // The lights. Each is in every scene of the stage while it is on, where it
  // is, shining in the direction it is turned, as strong as it is now. An
  // intensity of 1 is as bright as the stage's own light.
  for (const Lies& one : lies) {
    const utils::Entity e = one.shown->light;
    if (e.isNull()) continue;
    std::vector<Scene*> all{s.scene};
    // Also the effects scenes of groups with effects of their own, so their
    // layers are lit as on the stage.
    for (const auto& [layer, e] : d.layerFx)
      if (e.view && doc_holds_fx(d, layer)) all.push_back(e.view->getScene());
    for (Scene* sc : all)
      one.on ? (sc->hasEntity(e) ? void() : sc->addEntity(e)) : sc->remove(e);
    if (!one.on) continue;
    auto& lights = s.engine->getLightManager();
    const auto it = lights.getInstance(e);
    const math::mat4 place = doc_place(d, one.layer, now);
    lights.setPosition(it,
                       math::float3((place * math::double4{0, 0, 0, 1}).xyz));
    lights.setDirection(
        it, normalize(math::float3((place * math::double4{0, 0, -1, 0}).xyz)));
    const float strong = (float)doc_number(d, one.layer, "intensity", now, 1);
    // A sun light is in lux, like the stage's own light. Other lights are in
    // candela, chosen so that at six units, where the stage's own camera
    // stands, they are as bright as that light.
    if (lights.getType(it) == LightManager::Type::SUN)
      lights.setIntensity(it, 60000.f * strong);
    else
      lights.setIntensityCandela(it, 60000.f * 36.f * strong);
    if (lights.getType(it) == LightManager::Type::SUN)
      lights.setSunAngularRadius(
          it, (float)doc_number(d, one.layer, "sun_size", now, 1.09) / 2.f),
          lights.setSunHaloSize(
              it, (float)doc_number(d, one.layer, "sun_halo", now, 10));
    if (lights.getType(it) == LightManager::Type::FOCUSED_SPOT) {
      const float cone = (float)(doc_number(d, one.layer, "cone", now, 30) *
                                 (double)TAU / 360.0);
      lights.setSpotLightCone(it, 0.8f * cone, cone);
    }
  }
  // A clipped layer is seen only inside the frame of the layer before it. This
  // uses Filament's scissor on the layer's materials, set to the rectangle that
  // the previous layer covers now. When that layer is turned or leaning, the
  // rectangle is the upright box around it.
  //
  // A group made to mask, through its Null's group_mask as in Alight Motion's
  // Group and Mask and Group and Exclude, works the same way. Its top layer is
  // the shape and is not seen itself. The other layers in the group are seen
  // inside it, or outside it to exclude.
  std::map<int, int> tops;
  for (int layer : lie)
    if (const int g = (int)std::lround(doc_number(d, layer, "parent", 0, 0));
        g > 0)
      // The last layer laid in the group is its top.
      if (const std::string& how = doc_word(d, g, "group_mask");
          how == "mask" || how == "exclude")
        tops[g] = layer;
  int before = 0;
  for (int layer : lie) {
    const auto found = d.shown.find(layer);
    if (found == d.shown.end()) continue;
    Doc::Shown& t = found->second;
    double box[4] = {0, 0, 0, 0};
    const int group = (int)std::lround(doc_number(d, layer, "parent", 0, 0));
    const auto top = tops.find(group);
    // True for a layer in a mask group other than its top. The top cuts it.
    const bool grouped = top != tops.end() && top->second != layer;
    // The group's top is only a shape and is not seen, as in Alight Motion.
    if (top != tops.end() && top->second == layer) {
      if (MaterialInstance* look = t.video   ? t.video->look
                                   : t.drawn ? t.drawn->look
                                             : nullptr)
        look->setParameter("opacity", 0.f);
      if (t.drawn && t.drawn->edgeLook)
        t.drawn->edgeLook->setParameter("opacity", 0.f);
    }
    const int by = grouped ? top->second : before;
    const double invert =
        grouped ? (doc_word(d, group, "group_mask") == "exclude" ? 1.0 : 0.0)
                : doc_number(d, layer, "clip_invert", 0, 0);
    const bool clipped =
        t.in && by && (grouped || doc_number(d, layer, "clip", 0, 0) > 0.5) &&
        doc_covers(d, by, now, box);
    // When the clipping layer is a flat layer drawn by ThorVG, the layer is cut
    // by that layer's own image, like an After Effects alpha matte. Otherwise
    // it is cut by the upright box of what the clipping layer covers.
    const Doc::Shown* const a = clipped ? &d.shown[by] : nullptr;
    // A solid can be cut too, through its own material.
    const bool shaped = a && a->drawn && (t.drawn || t.video || t.look);
    Doc::Cut& cut = d.cuts[layer];
    MaterialInstance* const base = t.video   ? t.video->look
                                   : t.drawn ? t.drawn->look
                                             : t.look;
    // With effects of its own, the sheet they made is cut after them, as After
    // Effects cuts a layer by its matte once its effects are applied.
    const auto fx = d.layerFx.find(layer);
    MaterialInstance* const own =
        fx != d.layerFx.end() && fx->second.look && !fx->second.solid
            ? fx->second.look
            : base;
    // Stops a material from being cut. With `there` true the material still
    // exists, so it is also told to stop using its matte. A material that was
    // made again is gone.
    const auto unmatte = [&](MaterialInstance* look, bool there) {
      if (!look) return;
      std::erase_if(s.cuts,
                    [&](const Stage::Cut& c) { return c.look == look; });
      if (there) look->setParameter("matteUse", float4{0.f});
    };
    // A key describing how the layer is cut. It is set only for a layer that is
    // cut.
    const std::string how =
        shaped ? doc_word(d, layer, "clip_matte") + " " +
                     std::to_string(invert) + " " +
                     std::to_string(doc_number(d, layer, "clip_feather", 0, 0))
               : std::string();
    // When the clipping layer or the way of cutting changed, the matte takes
    // the shape of that layer's image, at that layer's place.
    if (shaped && (cut.from != by || cut.by != a->drawn || cut.how != how)) {
      // Release what cut the material before.
      unmatte(cut.look, cut.look == base || cut.look == own);
      if (cut.matte >= 0) {
        Scene* sc = s.mattes[(size_t)cut.matte].scene;
        doc_unshape(s, [sc](const Stage::Renderable& made) {
          return sc->hasEntity(made.thing);
        });
      }
      cut.matte =
          matte(s, a->drawn->sheet, {mat4f(doc_place(d, by, now))},
                a->drawn->texture ? a->drawn->texture : white_point(s),
                doc_word(d, layer, "clip_matte") == "luma", 1.f, cut.matte);
      cut.from = by, cut.by = a->drawn, cut.look = nullptr, cut.how = how;
    }
    if (shaped && cut.look != own && own && cut.matte >= 0) {
      // The material was made again, or its effects came or went. Release what
      // was cut before.
      unmatte(cut.look, false);
      unmatte(base, base && base != own),
          unmatte(t.drawn ? t.drawn->edgeLook : nullptr, own != base);
      matted(s, own, cut.matte, invert < 0.5,
             (float)doc_number(d, layer, "clip_feather", 0, 0)),
          cut.look = own;
      // The edge material is cut too.
      if (own == base && t.drawn && t.drawn->edgeLook)
        matted(s, t.drawn->edgeLook, cut.matte, invert < 0.5,
               (float)doc_number(d, layer, "clip_feather", 0, 0));
    }
    // The layer is no longer cut. Release its matte.
    if (!shaped && cut.look) {
      std::erase_if(s.cuts,
                    [&](const Stage::Cut& c) { return c.look == cut.look; });
      if (cut.look == own) cut.look->setParameter("matteUse", float4{0.f});
      cut.look = nullptr, cut.from = 0, cut.by = nullptr;
      Scene* sc = s.mattes[(size_t)cut.matte].scene;
      doc_unshape(s, [sc](const Stage::Renderable& made) {
        return sc->hasEntity(made.thing);
      });
    }
    if (shaped) {
      if (t.clipped)
        doc_material_instances(
            s, t, [](MaterialInstance* look) { look->unsetScissor(); }),
            t.clipped = false;
    } else if (clipped || t.clipped) {
      const uint32_t left = (uint32_t)std::clamp(box[0], 0.0, (double)s.w),
                     bottom = (uint32_t)std::clamp(
                         (double)s.h - (box[1] + box[3]), 0.0, (double)s.h);
      doc_material_instances(s, t, [&](MaterialInstance* look) {
        if (clipped)
          look->setScissor(left, bottom,
                           (uint32_t)std::lround(std::max(box[2], 0.0)),
                           (uint32_t)std::lround(std::max(box[3], 0.0)));
        else
          look->unsetScissor();
      });
      t.clipped = clipped;
    }
    if (t.in) before = layer;
  }
  // The 3D layers of an After Effects composition shown as a layer. Each is
  // placed at the time the composition is at, where its pose puts it over the
  // composition's sheet as the stage has it now. The composition's corner is at
  // the sheet's top left and one pixel is a share of the sheet's height.
  for (auto& [layer, t] : d.shown) {
    if (t.deep.empty() || !t.drawn || !t.motion) continue;
    const double since = now - doc_number(d, layer, "start", 0, 0);
    const float sec =
        t.drawn->seconds > 0.f
            ? std::fmod((float)std::max(since, 0.0), t.drawn->seconds)
            : 0.f;
    const float frame =
        t.drawn->fromFrame +
        std::min(sec / std::max(t.drawn->seconds, 1e-6f) * t.drawn->frames,
                 std::max(t.drawn->frames - 1.f, 0.f));
    motion_at(*t.motion, frame);
    mat4f sheetAt;
    bool found = false;
    auto& places = s.engine->getTransformManager();
    for (const Stage::Renderable& made : s.renderables)
      if (made.of == t.drawn->sheet && !made.matte && made.nth == 0) {
        sheetAt = places.getWorldTransform(places.getInstance(made.thing));
        found = true;
        break;
      }
    const float px = 1.f / t.motion->h;
    const float3 corner{-0.5f * t.motion->w * px, 0.5f, 0.f},
        right{px, 0.f, 0.f}, down{0.f, -px, 0.f};
    for (const auto& deep : t.deep) {
      layer_at(s, deep.sheet, frame);
      tvg::Matrix flat;
      float seen = 0.f;
      const bool there = t.in && found &&
                         motion_flat(*t.motion, deep.id, &flat, &seen) &&
                         seen > 0.f;
      const mat4f at = motion_built(*t.motion, deep.id);
      move(s, deep.sheet->sheet, [&](int, const mat4f&) {
        return there ? sheetAt * motion_in_scene(at, corner, right, down) *
                           mat4f::translation(float3{
                               (deep.box.x + 0.5f * deep.box.z) * px,
                               (deep.box.y + 0.5f * deep.box.w) * px, 0.f}) *
                           mat4f::scaling(float3{1, -1, 1})
                     : mat4f::scaling(0.f);
      });
    }
  }
}
double doc_fx_room(Doc& d, int layer) {
  const auto most = [&](const char* name, double otherwise) {
    return std::max(doc_most(d, layer, name, otherwise),
                    doc_number(d, layer, name, 0, otherwise));
  };
  double r = 3.0 * most("blur", 0);
  if (!doc_word(d, layer, "shadow").empty())
    r = std::max(r,
                 most("shadow_distance", 10) + 3.0 * most("shadow_blur", 10));
  return r <= 0.0 ? 0.0 : std::exp2(std::ceil(std::log2(std::max(r, 1.0))));
}

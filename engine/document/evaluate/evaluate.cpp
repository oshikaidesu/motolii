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
#include "community/playcanvas/splatfx.h"
#include "community/quickjs/script.h"
#include "document/card_table.h"
#include "document/document.h"
#include "document/edit/arrange.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/evaluate_camera.h"
#include "document/evaluate/evaluate_clipping.h"
#include "document/evaluate/evaluate_copies.h"
#include "document/evaluate/evaluate_lights.h"
#include "document/evaluate/evaluate_materials.h"
#include "document/evaluate/evaluate_scenes.h"
#include "document/evaluate/evaluate_shape.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/sketch.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
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
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

void doc_evaluate(Doc& d, double now) {
  Stage& s = *d.stage;
  // Cleared and rebuilt on demand. A flat layer's sheet is now as large as its
  // canvas.
  d.place_cache.halves.clear(), d.place_cache.talls.clear();
  // Nothing in the document changes during an evaluation, so what each copy of
  // a layer asks for is computed once and cached in d.place_cache.placing until
  // the evaluation ends.
  d.place_cache.placing.clear(), d.place_cache.evaluating = true;
  // Clears the evaluating state on every exit path, including the early returns
  // below.
  struct Told {
    Doc& d;
    ~Told() { d.place_cache.evaluating = false, d.place_cache.placing.clear(); }
  } told{d};
  // A text layer whose words change with time, such as the Timecode and Count
  // Up text effects of AbsentMotion, is updated in place with words_at. If the
  // new words no longer fit the canvas, or the update fails, only that layer is
  // rebuilt with doc_match and evaluation stops.
  if (now == s.now)
    for (auto& [layer, t] : d.on_stage.shown)
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
    for (auto& [layer, t] : d.on_stage.shown)
      if (t.celMove && doc_cel(d, layer, now) != t.cel)
        return (void)doc_match(d);
  Evaluation evaluation{d, s, now};
  evaluation.lie = doc_laid(d);
  const std::vector<int>& lie = evaluation.lie;
  std::vector<EvaluatedLayer>& lies = evaluation.lies;
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
    const auto found = d.on_stage.shown.find(layer);
    if (found == d.on_stage.shown.end() || found->second.camera) continue;
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
    EvaluatedLayer one{layer,
                       &found->second,
                       since >= 0.0 && (lasts < 0.0 || since < lasts) &&
                           doc_number(d, layer, "visible", 0, 1) > 0.5 &&
                           (!solo || solo_of(layer)),
                       found->second.space != 2 || open,
                       since,
                       open};
    lies.push_back(one);
  }
  evaluate_camera(evaluation);
  doc_look(d);
  d.on_stage.round = doc_seconds(d);
  evaluate_runs(evaluation);
  evaluate_scenes(evaluation);
  evaluate_effects_released(evaluation);
  // Draw each layer that has effects of its own into its view first; see
  // moment_fx.h.
  doc_layers_fx(d);
  evaluate_layers_read(evaluation);
  evaluate_bloom(evaluation);
  evaluate_depth_of_field(evaluation);
  for (size_t i = 0; i < lies.size(); ++i) {
    const int layer = lies[i].layer;
    DocShownLayer& t = *lies[i].shown;
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
    evaluate_box(d, t, lies[i].open, lies[i].solid);
    evaluate_bevel(d, layer, t, now);
    evaluate_lit_surface(d, layer, t, now);
    evaluate_sheet_material(d, layer, t, now);
    evaluate_part_colours(d, layer, t, now);
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
    evaluate_cut_shape(d, layer, t, now, lies[i].since);
    if (t.drawn && t.drawn->shape)
      bend_at(s, t.drawn, (float)doc_number(d, layer, "round", now, 0),
              (float)doc_number(d, layer, "bloat", now, 0),
              (float)doc_number(d, layer, "zigzag", now, 0),
              (float)doc_number(d, layer, "zigzag_ridges", now, 5),
              (float)doc_number(d, layer, "zigzag_smooth", now, 0),
              (float)doc_number(d, layer, "offset", now, 0));
    const CopyPlaces places = evaluate_copy_places(d, layer, now);
    evaluate_splat(d, layer, t, now);
    evaluate_copies_placed(d, layer, t, m, now, lies[i].solid, places);
    evaluate_scripted_copy_colours(d, layer, t, m);
    const LayerOpacity layer_opacity = evaluate_opacity(d, layer, t, now);
    evaluate_copy_looks(d, layer, t, m, now, layer_opacity);
    evaluate_glow(d, layer, t, now);
  }
  evaluate_shadow_type(evaluation);
  evaluate_lights(evaluation);
  evaluate_clipping(evaluation);
  // The 3D layers of an After Effects composition shown as a layer. Each is
  // placed at the time the composition is at, where its pose puts it over the
  // composition's sheet as the stage has it now. The composition's corner is at
  // the sheet's top left and one pixel is a share of the sheet's height.
  for (auto& [layer, t] : d.on_stage.shown) {
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

}  // namespace motolii

#include "document/evaluate/evaluate_layers.h"

#include <filament/Engine.h>
#include <filament/Scene.h>
#include <filament/TransformManager.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>
#include <utils/Entity.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#include "community/after_effects/lottie_slots.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluate_copies.h"
#include "document/evaluate/evaluate_materials.h"
#include "document/evaluate/evaluate_shape.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/sketch.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/midi_roll.h"
#include "media/video_layer.h"
#include "motion/easing_godot.h"
#include "motion/lottie_motion.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Scene;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// Shows a video layer's frame and sets its look. `since` is the time in seconds
// since the layer started.
void video_shown(Doc& d, int layer, DocShownLayer& t, double now,
                 double since) {
  Stage& s = *d.stage;
  // Show the video frame for the layer's own time. If the stage has a
  // deferred-work queue, the call is queued to run later instead of running
  // now.
  if (t.video) {
    if (s.later)
      s.later->push_back([&s, video = t.video, since = (float)since] {
        video_at(s, video, since);
      });
    else
      video_at(s, t.video, (float)since);
  }
}

// Play the solid's own animation for each copy, from the time the layer
// comes on, shifted by the copy's delay and scaled by the speed.
void solid_animated(Doc& d, int layer, DocShownLayer& t, double since) {
  if (t.solid && !t.solid->moves.empty())
    for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth)
      solid_at(t.solid, doc_word(d, layer, "animation"),
               (since - doc_delay(d, layer, (int)nth)) *
                   doc_number(d, layer, "speed", 0, 1),
               nth);
}

// A Lottie layer: pass the current values of the script parameters into the
// animation's slots.
void lottie_slots_set(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->lottie)
    if (DocScript* sc = doc_script_of(d, doc_word(d, layer, "file"));
        sc && !sc->parameters.empty()) {
      std::vector<double> v;
      for (size_t k = 0; k < sc->parameters.size(); ++k)
        v.push_back(doc_number(d, layer, sc->names[k].c_str(), now,
                               sc->parameters[k].usual));
      slots_at(s, t.drawn, lottie_slots_json(sc->parameters, v));
    }
}

// A MIDI roll: notes are animated as ALMaMPlayer's note.gd does. A note
// lights up over 0.17 s and stays lit as long as the note lasts, or 0.2 s
// longer if the note lasts 0.4 s or less. It then fades over 0.27 s. It
// grows to 1.03 times its size over 0.2 s and stays grown. While lit it
// dips by 0.25 + velocity * 0.2 * 0.7, reaching it over 0.17 s and
// returning over 0.27 s. All curves are sine in and out.
void midi_roll_lit(Doc& d, int layer, DocShownLayer& t, double since) {
  Stage& s = *d.stage;
  if (t.drawn &&
      std::filesystem::path(doc_word(d, layer, "file")).extension() == ".mid") {
    const std::string file = doc_word(d, layer, "file");
    const double speed = doc_number(d, layer, "speed", 0, 1), now_in = since;
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
      const float grow =
                      (float)(1.0 + 0.03 * (now_in < n.on
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
}

// Set the strength of each sketch line as it is now. When a strength
// changed, the cached drawing is dropped so it is drawn again.
void sketch_lines_set(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
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
}

// Brings a drawn layer's image to the layer's own time: its animation, its
// effects and its trim. `since` is the time in seconds since the layer started.
void drawing_shown(Doc& d, int layer, DocShownLayer& t, double now,
                   double since) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->seconds > 0.f)
    canvas_at(
        s, t.drawn,
        std::fmod((float)doc_own_time(d, layer, now, since), t.drawn->seconds));
  if (t.drawn && t.drawn->shape)
    trim_at(s, t.drawn, (float)doc_number(d, layer, "trim", now, 0),
            (float)doc_number(d, layer, "trim_begin", now, 0),
            (float)doc_number(d, layer, "trim_offset", now, 0));
}

// Brings one layer to the evaluated time. `i` is its index in the evaluation's
// `lies`. A layer that is not on is taken out of its scene and nothing else is
// done for it.
void layer_evaluated(const Evaluation& evaluation, size_t i) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const double now = evaluation.now;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const int layer = lies[i].layer;
  DocShownLayer& t = *lies[i].shown;
  const bool in = lies[i].on;
  const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
  if (t.sketch && in) doc_sketch_mesh(d, layer, t, now);
  // Add the layer to, or remove it from, the scene of its run.
  if (in != t.in) {
    Scene* sc = t.scene ? t.scene : s.scene;
    doc_entities(
        s, t, [&](utils::Entity e) { in ? sc->addEntity(e) : sc->remove(e); });
    t.in = in;
  }
  if (!in) return;
  video_shown(d, layer, t, now, lies[i].since);
  solid_animated(d, layer, t, lies[i].since);
  lottie_slots_set(d, layer, t, now);
  midi_roll_lit(d, layer, t, lies[i].since);
  evaluate_box(d, t, lies[i].open, lies[i].solid);
  evaluate_bevel(d, layer, t, now);
  evaluate_lit_surface(d, layer, t, now);
  evaluate_sheet_material(d, layer, t, now);
  evaluate_part_colours(d, layer, t, now);
  sketch_lines_set(d, layer, t, now);
  drawing_shown(d, layer, t, now, lies[i].since);
  evaluate_cut_shape(d, layer, t, now);
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

}  // namespace

void evaluate_layers(const Evaluation& evaluation) {
  for (size_t i = 0; i < evaluation.lies.size(); ++i)
    layer_evaluated(evaluation, i);
}

// The 3D layers of an After Effects composition shown as a layer. Each is
// placed at the time the composition is at, where its pose puts it over the
// composition's sheet as the stage has it now. The composition's corner is at
// the sheet's top left and one pixel is a share of the sheet's height.
void evaluate_composition_layers(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const double now = evaluation.now;
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

}  // namespace motolii

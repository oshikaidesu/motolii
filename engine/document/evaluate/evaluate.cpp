#include "document/evaluate/evaluate.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "document/document.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/evaluate_camera.h"
#include "document/evaluate/evaluate_clipping.h"
#include "document/evaluate/evaluate_layers.h"
#include "document/evaluate/evaluate_lights.h"
#include "document/evaluate/evaluate_scenes.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace {

// Rebuilds, with doc_match, one layer whose content changed in a way that
// cannot be shown in place. Returns true when it did: the stage is then already
// rebuilt and the evaluation stops.
bool rebuilt_changed_layer(Doc& d, double now) {
  Stage& s = *d.stage;
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
            return (void)doc_match(d), true;
        }
  // A cel layer whose keyframes now select a different drawing is rebuilt on
  // its own with doc_match.
  if (now == s.now)
    for (auto& [layer, t] : d.on_stage.shown)
      if (t.celMove && doc_cel(d, layer, now) != t.cel)
        return (void)doc_match(d), true;
  return false;
}

// Returns true if the layer is solo, or if a Null above it in the parent
// chain is solo. A Null's solo applies to the layers under it. The walk stops
// after 64 levels to guard against parent cycles.
bool solo_of(Doc& d, int layer) {
  for (int up = layer, n = 0; up > 0 && n < 64;
       up = (int)doc_number(d, up, "parent", 0, 0), ++n)
    if (doc_number(d, up, "solo", 0, 0) > 0.5 &&
        (up == layer || doc_word(d, up, "shape") == "null"))
      return true;
  return false;
}

// Fills `lie` and `lies` of the evaluation: the layers in stacking order, and
// the state at this time of each layer that is on the stage and is not a
// camera.
void evaluate_layer_states(Evaluation& evaluation) {
  Doc& d = evaluation.d;
  const double now = evaluation.now;
  evaluation.lie = doc_laid(d);
  const std::vector<int>& lie = evaluation.lie;
  std::vector<EvaluatedLayer>& lies = evaluation.lies;
  // While any layer is solo, only solo layers are shown.
  bool solo = false;
  for (int layer : lie) solo = solo || doc_number(d, layer, "solo", 0, 0) > 0.5;
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
                           (!solo || solo_of(d, layer)),
                       found->second.space != 2 || open,
                       since,
                       open};
    lies.push_back(one);
  }
}

}  // namespace

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
  if (rebuilt_changed_layer(d, now)) return;
  Evaluation evaluation{d, s, now};
  evaluate_layer_states(evaluation);
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
  evaluate_depth_of_field(evaluation);
  evaluate_layers(evaluation);
  evaluate_shadow_type(evaluation);
  evaluate_lights(evaluation);
  evaluate_clipping(evaluation);
  evaluate_composition_layers(evaluation);
}

}  // namespace motolii

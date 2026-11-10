#ifndef MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_
#define MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

// A layer's effect list: the order in which its effects are laid on it and run.

#include <string>
#include <vector>

#include "stage/canvas/canvas_cache.h"

namespace motolii {

struct Doc;

// Returns the layer's effects in the order they are laid, like the effect stack
// of After Effects.
//
// The "fx" property names the effects in order.
//
// With `off` set, effects that are turned off are included, as the effect cards
// list them (fx_off, the eye on an effect in Alight Motion). Otherwise only
// effects that are on are returned.
std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off = false);
// Returns whether any effect in `list` is a file. Then all of them run in
// order in the camera view; see thing_effects_draw in
// engine/stage/layer_effects/layer_fx.h.
bool doc_fx_files(const std::vector<std::string>& list);
// Returns the effects as the stack runs them: the list from doc_fx_list without
// expressions. AbsentMotion's Motion Blur and Shutter Blur are replaced by its
// Directional Blur, which sits beside them on the shelf as
// am_directionalblur.wgsl. It is told how far and in which direction the layer
// moves while its shutter is open. See engine/document/evaluate/moment_fx.h
// and, for the quick smear, SmearFilter in DrawShuttered in
// engine/third_party/AbsentMotion/app/src/main/cpp/styles.cpp.
std::vector<std::string> doc_fx_steps(Doc& d, int layer);
// Returns the effect names joined with single spaces.
std::string doc_fx_join(const std::vector<std::string>& list);
// Returns the largest value a property takes: the maximum over its keyframes,
// or its set value when it has no keyframes. `otherwise` is the default for an
// unset property.
double doc_most(Doc& d, int layer, const char* name, double otherwise);
// Fills `fx` with how far a flat layer's shape reaches beyond its box, either
// at time `at` or, with `most` set, as far as it reaches at its largest. Also
// checks that the layer's effect files exist and can be run.
//
// Returns false when one cannot, and then `why` says which.
bool doc_fx(Doc& d, int layer, double at, bool most, Canvas2DFx& fx,
            std::string& why);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

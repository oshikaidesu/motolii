#ifndef MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_
#define MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

// A layer's effect list: the order in which its effects are laid on it and run.

#include <string>
#include <vector>

#include "document/kinds.h"
#include "stage/canvas/canvas_cache.h"

// Returns the layer's effects in the order they are laid, like the effect stack of After Effects.
//
// The "fx" property names the effects in order. Effect files (.wgsl) and the built-in ThorVG
// effects (doc_thor_names) can be mixed in any order. A ThorVG effect that is on but not named,
// as in a project saved before "fx" existed, comes first, in the old order: colors, shadow, glow,
// blur.
//
// With `off` set, effects that are turned off are included, as the effect cards list them
// (fx_off, the eye on an effect in Alight Motion). Otherwise only effects that are on are
// returned.
std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off = false);
// Returns whether the layer's effects are laid on it as the camera sees it, rather than in its own
// canvas as ThorVG draws it. That is the case when any effect in `list` is a file. Then all of
// them run in order in the camera view; see thing_effects_draw in
// engine/stage/effects/screen_fx.h.
bool doc_fx_files(const std::vector<std::string>& list);
// Returns the effects as the stack runs them: the list from doc_fx_list without expressions.
// AbsentMotion's Motion Blur and Shutter Blur are replaced by its Directional Blur, which sits
// beside them on the shelf as am_directionalblur.wgsl. It is told how far and in which direction
// the layer moves while its shutter is open. See engine/document/evaluate/moment_fx.h and, for the quick
// smear, SmearFilter in DrawShuttered in
// engine/third_party/AbsentMotion/app/src/main/cpp/styles.cpp.
std::vector<std::string> doc_fx_steps(Doc& d, int layer);
// Returns the effect names joined with single spaces.
std::string doc_fx_join(const std::vector<std::string>& list);
// Returns the largest value a property takes: the maximum over its keyframes, or its set value
// when it has no keyframes. `otherwise` is the default for an unset property.
double doc_most(Doc& d, int layer, const char* name, double otherwise);
// Fills `fx` with the built-in ThorVG effects of a flat layer, either at time `at` or, with `most`
// set, as far as each one reaches at its largest. Lengths are stored as fractions of the layer's
// height. `units` is the number of canvas points in one stage unit, used to convert them.
//
// Returns false when a color is not six hex digits, and then `why` says which. Built-in effects
// that are missing from the layer's effect list are switched off, unless `camera` is set. A
// camera lays them as a step of its stack instead; see thing_thor in
// engine/stage/effects/screen_fx.h.
bool doc_fx(Doc& d, int layer, double at, bool most, double units, Canvas2DFx& fx, std::string& why, bool camera = false);

#endif  // MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

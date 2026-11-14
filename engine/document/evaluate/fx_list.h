#ifndef MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_
#define MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

// A layer's effect list: the order in which its effects are laid on it and run.

#include <string>
#include <utility>
#include <vector>

#include "community/quickjs/script.h"
#include "stage/canvas/canvas_cache.h"

namespace motolii {

struct Doc;

// Returns the files of the layer's effects in the order they are laid, like
// the effect stack of After Effects. The "fx" property names them in order;
// each is the file alone, without the ID an entry may carry (fx_entry_id in
// script.h), so the same file put on twice is here twice.
//
// When `off` is true the list includes the effects that are turned off, as
// cards list them (fx_off, the eye on an effect in Alight Motion). Otherwise
// only effects that are on are returned, and after them the effect being tried
// on the layer (doc_carry_effect).
std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off = false);
// The same effects as the "fx" property names them: an entry is the file with
// its ID in front where it has one ("a1b2c3:blur.wgsl"). For what changes the
// list and writes it back (doc_fx_say), and for what reads an effect's own
// values.
std::vector<std::string> doc_fx_entries(Doc& d, int layer, bool off = false);
// Returns the ID an entry's values are kept under, or "" when they are kept
// under the file's own names. A shader (a .wgsl or an ISF file) reads its
// values by its ID (doc_layers_fx), so two of the same file are turned apart.
// What is not drawn as a shader reads the file's names whichever entry names
// it: a motion, an expression, a solid's shape, a splat effect, an AviUtl2
// script, Filament's settings.
std::string doc_fx_values_id(Doc& d, const std::string& entry);
// Returns whether any effect in `list` is a file. Then all of them run in
// order in the camera view; see thing_effects_draw in
// engine/stage/layer_effects/layer_fx.h.
bool doc_fx_files(const std::vector<std::string>& list);
// Returns the effects as the stack runs them: file paths without instance-ID
// prefixes, without expressions. AbsentMotion's Motion Blur and Shutter Blur
// are replaced by its Directional Blur, which sits beside them on the shelf as
// am_directionalblur.wgsl. It is told how far and in which direction the layer
// moves while its shutter is open. See engine/document/evaluate/moment_fx.h
// and, for the quick smear, SmearFilter in DrawShuttered in
// engine/third_party/AbsentMotion/app/src/main/cpp/styles.cpp.
std::vector<std::string> doc_fx_steps(Doc& d, int layer);
// The same steps as their entries, each with its ID in front where it has one,
// so that what draws them reads each one's own values.
std::vector<std::string> doc_fx_steps_with_ids(Doc& d, int layer);
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

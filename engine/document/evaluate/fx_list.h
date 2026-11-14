#ifndef MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_
#define MOTOLII_DOCUMENT_EVALUATE_FX_LIST_H_

// A layer's effect list: the order in which its effects are laid on it and run.

#include <string>
#include <utility>
#include <vector>

#include "stage/canvas/canvas_cache.h"

namespace motolii {

struct Doc;

// Returns the instance ID of an fx entry. An entry may carry a 6-hex-char
// prefix: "a1b2c3:blur.js" → "a1b2c3". An old entry without a prefix returns
// "". Each instance of the same file on a layer gets its own ID so their
// parameters are stored separately.
std::string fx_entry_id(const std::string& entry);
// Returns the file path of an fx entry, stripping the instance-ID prefix.
// "a1b2c3:blur.js" → "blur.js". "blur.js" → "blur.js".
std::string fx_entry_path(const std::string& entry);

// Returns the layer's effects in the order they are laid, like the effect stack
// of After Effects. Each entry may carry an instance-ID prefix
// ("a1b2c3:blur.js"); callers that need the file path use fx_entry_path().
//
// The "fx" property names the effects in order.
//
// With `off` set, effects that are turned off are included, as the effect cards
// list them (fx_off, the eye on an effect in Alight Motion). Otherwise only
// effects that are on are returned.
std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off = false);
// Like doc_fx_list() but returns (instance_id, file_path) pairs. id is ""
// for old entries that have no instance prefix.
std::vector<std::pair<std::string, std::string>> doc_fx_instances(
    Doc& d, int layer, bool off = false);
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
// Like doc_fx_steps() but preserves instance-ID prefixes in each entry so the
// GPU draw path can pass each instance's ID to the numbers callback.
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

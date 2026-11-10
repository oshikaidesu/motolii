#ifndef MOTOLII_STAGE_EFFECTS_VIEWER_SETTINGS_H_
#define MOTOLII_STAGE_EFFECTS_VIEWER_SETTINGS_H_
// Filament's own settings file as a whole-screen effect on the shelf.
//
// The file is the JSON of Filament's libs/viewer, as saved and read by
// gltf_viewer:
// {"view": {"colorGrading": {...}, "bloom": {...}, "fog": {...}, ...}} (see
// viewer/Settings.h). Its numbers and on/off switches become parameters on the
// effect's card, as the slots of an After Effects file do (see
// community/after_effects/lottie_slots.h, whose rule for a range is used when
// none is given). The current values are written back into the file's text,
// read by Filament's JsonSerializer, and laid on the stage's view over the
// values the stage itself sets (see doc_look in document/evaluate/camera.h). A
// part the file does not mention keeps the stage's values. Words such as enum
// names (a tone mapping, a custom LUT) are not parameters; they stay as the
// file says them.
#include <cstddef>
#include <functional>
#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// Returns true if the file is a viewer settings file.
bool viewer_is(const std::string& file);

// Returns the parameters for all the numbers and switches under "view" in the
// file; empty if the file is not a viewer settings file.
std::vector<ScriptParameter> viewer_parameters(const std::string& file);

// Returns the file's text with each parameter's current value written into its
// place, in the form Filament's JsonSerializer reads, or "" if the file cannot
// be read. `now(k)` returns the current value of parameter k.
std::string viewer_said(const std::string& file,
                        const std::vector<ScriptParameter>& parameters,
                        const std::function<double(size_t)>& now);

}  // namespace motolii

#endif  // MOTOLII_STAGE_EFFECTS_VIEWER_SETTINGS_H_

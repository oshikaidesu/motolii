#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_PARAMETERS_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_PARAMETERS_H_

#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// Returns the parameters a file declares, whatever its dialect. They are read
// from its header; for a sketch they are its lines that draw. Returns an empty
// list if there are none or the file cannot be read.
//
// An AviUtl2 script's header is read by its adapter (aviutl_parameters), a
// three.js scene from the net has one parameter (which part of it the layer
// is), and leva's object form is turned into header lines first. Everything
// else is read by script_header_parameters in community/quickjs/script.h.
std::vector<ScriptParameter> script_parameters(const std::string& file);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_PARAMETERS_H_

#ifndef MOTOLII_COMMUNITY_ISF_ISF_TRANSLATE_H_
#define MOTOLII_COMMUNITY_ISF_ISF_TRANSLATE_H_

// The parts of the ISF to WGSL conversion (isf.h has the entry point). They are
// in separate files: reading the JSON head (isf_head.cpp), compiling GLSL to
// WGSL (isf_compile.cpp) and building the GLSL (isf_translate.cpp).
#include <optional>
#include <string>
#include <vector>

#include "base/json.h"

namespace motolii {

// Converts the text of an ISF file into WGSL. `name` is used in the output
// header and `vertex` is the source of an optional custom vertex shader.
// Returns the WGSL, or "" with the reason in `why`.
std::string isf_wgsl(const std::string& text, const std::string& name,
                     std::string& why, std::string vertex = "");

// Reads a string member of an object, or `fallback`.
std::string isf_str(const rapidjson::Value& o, const char* k,
                    std::string fallback = "");
// Reads a number (a bool counts as 0 or 1), or `fallback`.
double isf_num(const rapidjson::Value& v, double fallback);
// Reads one side of a pass size (`k` is WIDTH or HEIGHT; `side` names the frame
// side it may refer to) and stores it in `said`. The result is "s<share>" for a
// share of the frame side or "a<pixels>" for an absolute size. Returns false if
// the size cannot be expressed.
bool isf_pass_size(const rapidjson::Value& p, const char* k, const char* side,
                   std::string& said);
// The shelf an effect goes on, from the ISF categories, or nothing if the head
// has none. `imageNames` and `inputs` tell whether it is a transition.
std::optional<std::string> isf_shelf(const rapidjson::Value& head,
                                     const std::vector<std::string>& imageNames,
                                     const rapidjson::Value& inputs);
// Compiles the GLSL to SPIR-V with glslang and converts it to WGSL with Tint.
// Returns the WGSL, or "" with the reason in `why`.
std::string isf_compile(const std::string& glsl, std::string& why);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_ISF_ISF_TRANSLATE_H_

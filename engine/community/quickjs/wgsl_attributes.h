#ifndef MOTOLII_COMMUNITY_QUICKJS_WGSL_ATTRIBUTES_H_
#define MOTOLII_COMMUNITY_QUICKJS_WGSL_ATTRIBUTES_H_
// Parses and strips WESL-style UI attributes (@range, @toggle, @color, @point,
// @group, @label, @auto) on a WGSL shader's uniform struct.

#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// Reads WESL-style UI attributes declared on the uniform struct of a WGSL
// shader (wgsl-play style).
std::vector<ScriptParameter> wgsl_attribute_parameters(const std::string& code);

// Strips Motolii/WESL UI attributes from WGSL source while preserving line
// numbers and leaving standard WGSL @group(N) bindings untouched.
std::string wgsl_strip_ui_attributes(const std::string& code);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_QUICKJS_WGSL_ATTRIBUTES_H_

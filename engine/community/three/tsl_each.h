#ifndef MOTOLII_COMMUNITY_THREE_TSL_EACH_H_
#define MOTOLII_COMMUNITY_THREE_TSL_EACH_H_

#include <string>

namespace motolii {

// Builds a WGSL vertex shader from an each() expression source file.
// `three` is the path to engine/third_party/js/three/ (the Three.js folder
// with three.webgpu.js). `writers` is
// engine/community/three_shading_language_to_shelf/ (where from_each.js
// lives). `cavalry` and `ease` are the JS texts of the two preludes that
// script_runner.cpp runs before each() — ways_prelude() and cavalry_prelude.js.
// `src` is the source of the each() file. On success (returns true) `wgsl` is
// the WGSL vertex shader; on failure `why` says what went wrong and `wgsl` is
// empty. Falls back to the CPU path when WGSL cannot be built.
bool tsl_each(const std::string& three, const std::string& writers,
              const std::string& cavalry, const std::string& ease,
              const std::string& src, std::string& wgsl, std::string& why);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_THREE_TSL_EACH_H_

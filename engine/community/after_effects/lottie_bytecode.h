#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_BYTECODE_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_BYTECODE_H_

// Pre-compiled QuickJS bytecode for lottie_shim.js and every module it reaches,
// produced at build time by community/after_effects/lottie_precompile.cpp.
// community/script_runner/script_runner.cpp reads this instead of parsing the
// source of 47 lottie files on every Script load.

#include <cstddef>

namespace motolii {

struct LottieBytecodeEntry {
  const char* name;  // canonical module name ("motolii-lottie-shim" or
                     // "motolii-lottie/<relative>")
  const unsigned char* data;
  std::size_t size;
};

extern const LottieBytecodeEntry kLottieBytecode[];
extern const std::size_t kLottieBytecodeCount;

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_BYTECODE_H_

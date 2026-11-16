#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_CANONICAL_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_CANONICAL_H_

// The module-name normalizer shared between the build-time precompile tool
// (community/after_effects/lottie_precompile.cpp) and the runtime loader
// (community/script_runner/script_runner.cpp). Both must produce the same
// canonical names so the bytecode keys match what the runtime asks for.

#include <quickjs.h>

#include <string>
#include <vector>

namespace motolii {

inline constexpr const char* kLottieShimCanonical = "motolii-lottie-shim";
inline constexpr const char* kLottiePrefix = "motolii-lottie/";

// Resolves an import name to a canonical module name:
//   "motolii-lottie-shim"            → stays as-is (the shim).
//   "motolii-lottie/<relative>"      → stays as-is.
//   "./x" or "../x"                  → resolved against the base's parent and
//                                      reduced to "motolii-lottie/<path>". A
//                                      missing .js extension is added.
//   anything else                    → passed through unchanged.
inline char* lottie_canonical(JSContext* cx, const char* base, const char* name,
                              void*) {
  const std::string n = name;
  const std::string b = base ? base : "";
  if (n == kLottieShimCanonical || n.rfind(kLottiePrefix, 0) == 0)
    return js_strdup(cx, n.c_str());
  if (n.empty() || (n[0] != '.' && n[0] != '/'))
    return js_strdup(cx, n.c_str());
  std::string parent = kLottiePrefix;
  if (b.rfind(kLottiePrefix, 0) == 0) {
    const auto slash = b.find_last_of('/');
    if (slash != std::string::npos) parent = b.substr(0, slash + 1);
  }
  std::vector<std::string> parts;
  const auto push_path = [&](const std::string& s) {
    for (size_t i = 0; i < s.size();) {
      size_t j = s.find('/', i);
      if (j == std::string::npos) j = s.size();
      const std::string seg = s.substr(i, j - i);
      if (seg == "..") {
        if (!parts.empty() && parts.back() + "/" != kLottiePrefix)
          parts.pop_back();
      } else if (!seg.empty() && seg != ".") {
        parts.push_back(seg);
      }
      i = j + 1;
    }
  };
  push_path(parent);
  push_path(n);
  std::string joined;
  for (size_t i = 0; i < parts.size(); ++i) {
    if (i) joined += '/';
    joined += parts[i];
  }
  const auto dot = joined.find_last_of('.');
  const auto last_slash = joined.find_last_of('/');
  if (dot == std::string::npos ||
      (last_slash != std::string::npos && dot < last_slash))
    joined += ".js";
  return js_strdup(cx, joined.c_str());
}

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_CANONICAL_H_

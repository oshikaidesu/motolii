#ifndef MOTOLII_BASE_HASH_H_
#define MOTOLII_BASE_HASH_H_

// FNV-1a 64-bit hash of a byte run. The one engine-wide copy of the loop, so
// cache keys and change checks match without each file keeping its own three
// lines of primes.
//
// FNV-1a (Fowler-Noll-Vo, 1991): start with the 64-bit offset basis, and for
// each byte XOR it in, then multiply by the 64-bit prime. Not for security:
// cache keys and change checks only.

#include <cstdint>
#include <string>
#include <string_view>

namespace motolii {

constexpr uint64_t kFnv1aOffset = 1469598103934665603ull;
constexpr uint64_t kFnv1aPrime = 1099511628211ull;

// Hashes [bytes, bytes+size).
inline uint64_t fnv1a64(const void* bytes, size_t size,
                        uint64_t seed = kFnv1aOffset) {
  const unsigned char* p = static_cast<const unsigned char*>(bytes);
  uint64_t h = seed;
  for (size_t i = 0; i < size; ++i) h = (h ^ p[i]) * kFnv1aPrime;
  return h;
}

inline uint64_t fnv1a64(std::string_view s, uint64_t seed = kFnv1aOffset) {
  return fnv1a64(s.data(), s.size(), seed);
}

inline uint64_t fnv1a64(const std::string& s, uint64_t seed = kFnv1aOffset) {
  return fnv1a64(s.data(), s.size(), seed);
}

// Mixes one byte into an existing hash. For callers that interleave small
// separators (like 0xff between path segments in playback_cache).
inline uint64_t fnv1a64_mix(uint64_t h, uint8_t b) {
  return (h ^ b) * kFnv1aPrime;
}

}  // namespace motolii

#endif  // MOTOLII_BASE_HASH_H_

#ifndef MOTOLII_COMMUNITY_HYDRA_HYDRA_ISF_H_
#define MOTOLII_COMMUNITY_HYDRA_HYDRA_ISF_H_

// Declares the conversion of Hydra code into an ISF effect. Implemented in hydra_isf.cpp.
#include <string>
#include <vector>

// A parameter whose value changes over time. `keys` holds its value sampled every HYDRA_STEP
// seconds, starting at time 0.
struct HydraParameter { std::string name; std::vector<double> keys; };
// Sampling interval, in seconds, for time-varying parameters.
inline constexpr double HYDRA_STEP = 0.1;
// Converts Hydra code into an ISF effect.
//
// `folder` is the directory where shelves/extensions/hydra/get.sh installed hydra-synth.
// `code` is the Hydra source text. `seconds` is the length of time over which time-varying values
// are sampled.
//
// On success, returns true, stores the ISF text in `isf`, and appends the time-varying parameters
// to `parameters`. On failure, returns false and stores the reason in `why`.
bool hydra_isf(const std::string& folder, const std::string& code, double seconds, std::string& isf, std::vector<HydraParameter>& parameters, std::string& why);

#endif  // MOTOLII_COMMUNITY_HYDRA_HYDRA_ISF_H_

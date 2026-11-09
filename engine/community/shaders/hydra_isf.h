// Hydra's code as an ISF effect (hydra_isf.cpp).
#pragma once
#include <string>
#include <vector>

struct HydraParameter { std::string name; std::vector<double> keys; };   // (a parameter that moves by itself: its value every HYDRA_STEP seconds)
inline constexpr double HYDRA_STEP = 0.1;
// `folder`: where extensions/hydra/get.sh put hydra-synth. `seconds`: how far its moving values are read. The ISF text and
// the parameters that move, or false and `why`.
bool hydra_isf(const std::string& folder, const std::string& code, double seconds, std::string& isf, std::vector<HydraParameter>& parameters, std::string& why);

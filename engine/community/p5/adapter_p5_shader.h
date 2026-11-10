#ifndef MOTOLII_COMMUNITY_P5_ADAPTER_P5_SHADER_H_
#define MOTOLII_COMMUNITY_P5_ADAPTER_P5_SHADER_H_

// Converts a p5.js sketch that paints the whole canvas with shader() into an
// ISF effect.
//
// The sketch's fragment shader becomes the ISF effect and its vertex shader
// becomes the ISF vertex shader (.vs, see isf.cpp). The uniform values the
// sketch sets each frame (collected by
// __shaded_take in p5_stand.h) become effect parameters, with keyframes where a
// value changes, as in hydra_isf.h. The vertices of the sketch's shape are not
// carried over: the shader is run over a flat rect, plane or quad, so each
// pixel gets the same input as it would in the sketch.

#include <string>
#include <vector>

#include "community/hydra/hydra_isf.h"

namespace motolii {

// Seconds over which a linear value is extended; recorded keys cover only about
// 30 s.
inline constexpr double ADAPTER_LINE_ENDS = 600.0;
// Returns true if there are 3+ keys on a straight line at equal steps.
bool adapter_line(const std::vector<double>& keys);
// Returns the value a linear key series reaches after ADAPTER_LINE_ENDS
// seconds.
inline double adapter_line_end(const std::vector<double>& keys) {
  return keys[0] + (keys.back() - keys[0]) / (double)(keys.size() - 1) *
                       ADAPTER_LINE_ENDS / HYDRA_STEP;
}

// Builds the ISF effect for a sketch. `json` is the output of __shaded_take:
// the sketch's shader sources, the canvas size, and the uniform values set in
// each frame. On success returns true with the ISF fragment shader in `fs`, the
// vertex shader in `vs`, and in `moving` the parameters whose values change
// over time. Otherwise returns false and sets `why` to a message for the user.
bool adapter_p5_shader(const std::string& json, std::string& fs,
                       std::string& vs, std::vector<HydraParameter>& moving,
                       std::string& why);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_P5_ADAPTER_P5_SHADER_H_

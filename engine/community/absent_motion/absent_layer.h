#ifndef MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_LAYER_H_
#define MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_LAYER_H_

// Internal to the AbsentMotion adapter: the AbsentMotion layer that
// absent_motion.cpp and absent_drawing.cpp both build. Defined in
// absent_motion.cpp.
#include <cstdint>
#include <vector>

#include "community/absent_motion/absent_motion.h"

namespace am {
struct Layer;
}

namespace motolii {

// Builds the AbsentMotion layer that the adapter's functions hand to
// AbsentMotion's code. The layer has the given number and time range, and
// carries the effects in order.
am::Layer absent_layer(const std::vector<AbsentEffect>& effects, int64_t thing,
                       double startMs, double endMs);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_ABSENT_MOTION_ABSENT_LAYER_H_

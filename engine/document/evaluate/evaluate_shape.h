#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

// What doc_evaluate does at one time for a shape layer whose path is cut into
// triangles: the path operations with other shapes, its trail and its freehand
// drawing.

#include <math/vec3.h>

#include <vector>

#include "stage/canvas/path_operations.h"

namespace motolii {

struct Doc;
struct DocShownLayer;

// Reads the layer's ordered `path_ops` stack (empty when unset, in which case
// legacy single properties apply) and resolves the active trim range.
std::vector<PathOpStep> doc_path_op_steps(Doc& d, int layer, double now,
                                          filament::math::float3& trimOut);

// Cuts the path of a layer again when the path changed. `t` is the layer as it
// is on the stage. Does nothing for a layer that is not such a shape.
void evaluate_cut_shape(Doc& d, int layer, DocShownLayer& t, double now);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

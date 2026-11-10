#ifndef MOTOLII_DOCUMENT_EVALUATE_WORLD_H_
#define MOTOLII_DOCUMENT_EVALUATE_WORLD_H_
// Evaluates relations that are written as script files, and the shared
// simulated world that the relations which push layers act on.

#include <cstddef>
#include <vector>

#include "document/document.h"

namespace motolii {

// Returns the values that relation `by`, written as a script file, gives all
// its layers at time `t`. For each layer the values are those named in
// doc_relate_names, in order. The script's relate() receives all layers at
// once, as a Python Effector in Cinema 4D's Full Control does, rather than one
// value at a time as the kinds in relations.h do, so each layer's result can
// depend on all the others.
// Returns an empty vector if there is no script or it failed; the layers
// underneath then show unchanged, and the script's error is reported. If
// relate() takes a fourth argument, the script keeps state, as Cavalry's Value
// Solver and Context's saveObject do: it receives its own result from the
// previous frame, and null at the first frame. While Strength is 0 the relation
// sleeps, as Houdini's Activation does, and the layers underneath show; when it
// wakes it continues from where those layers are then. While the user is
// dragging a value it waits.
const std::vector<double>& doc_related_all(Doc& d, int by, double t);
// Returns true if the script of relation `by` defines force(), meaning it
// pushes layers, rather than relate().
bool doc_pushes(Doc& d, int by);
// Returns value number `name` (an offset within the doc_world_kept values) of
// `layer` in the shared world at time `t`, or `otherwise` if the layer is not
// in the world.
double doc_world_value(Doc& d, int layer, size_t name, double t,
                       double otherwise);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_WORLD_H_

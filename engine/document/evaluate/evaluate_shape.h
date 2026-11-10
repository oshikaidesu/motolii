#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

// What doc_evaluate does at one time for a shape layer whose path is cut into
// triangles: its bends, the path operations with other shapes, its trail and
// its freehand drawing.

namespace motolii {

struct Doc;
struct DocShownLayer;

// Bends the shape of a layer in its material and its copies' materials, and
// cuts its path again when the path changed. `t` is the layer as it is on the
// stage and `since` the time in seconds since the layer started. Does nothing
// for a layer that is not such a shape.
void evaluate_cut_shape(Doc& d, int layer, DocShownLayer& t, double now,
                        double since);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

// What doc_evaluate does at one time for a shape layer whose path is cut into
// triangles: the path operations with other shapes, its trail and its freehand
// drawing.

namespace motolii {

struct Doc;
struct DocShownLayer;

// Cuts the path of a layer again when the path changed. `t` is the layer as it
// is on the stage. Does nothing for a layer that is not such a shape.
void evaluate_cut_shape(Doc& d, int layer, DocShownLayer& t, double now);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SHAPE_H_

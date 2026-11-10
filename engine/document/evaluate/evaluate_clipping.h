#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CLIPPING_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CLIPPING_H_

// The clipping phase of doc_evaluate: layers clipped by the layer before them
// and groups made to mask, cut by a matte or by a scissor rectangle.

namespace motolii {

struct Evaluation;

// Cuts every clipped layer, and every layer of a group made to mask, by the
// layer that clips it as that layer is now, and stops cutting the layers that
// are no longer clipped.
void evaluate_clipping(const Evaluation& evaluation);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CLIPPING_H_

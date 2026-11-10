#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LAYERS_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LAYERS_H_

// The phase of doc_evaluate that brings each layer to the evaluated time: it
// puts the layer in its scene or takes it out, and updates what the layer
// shows (its video frame, animation and drawing), its materials, its shape and
// its copies.

namespace motolii {

struct Evaluation;

// Brings every layer of the evaluation to its time, one layer after another in
// stacking order. Everything of one layer is done before the next layer.
void evaluate_layers(const Evaluation& evaluation);

// Places the 3D layers of each After Effects composition that is shown as a
// layer over that layer's sheet.
void evaluate_composition_layers(const Evaluation& evaluation);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LAYERS_H_

#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SCENES_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SCENES_H_

// The phases of doc_evaluate that decide what is drawn over what: the runs of
// flat and solid layers, the scene, channel and blend order of each layer, and
// the sheets that layers with effects of their own are drawn onto.

namespace motolii {

struct Evaluation;

// Sorts the layers that are drawn into runs of flat layers and runs of solid
// layers, in stacking order. Fills `runOf`, `sorts` and `base` of the
// evaluation.
void evaluate_runs(Evaluation& evaluation);

// Puts each layer that is drawn into the scene of its run, with the run's
// channel and the layer's blend order, and lays the effects sheet of a layer
// that has effects of its own where the layer lies.
void evaluate_scenes(const Evaluation& evaluation);

// Releases the effects state of the layers that no longer have effects of their
// own, are not drawn, or are gone.
void evaluate_effects_released(const Evaluation& evaluation);

// Draws, for each layer that reads what is under it, the image of what is under
// it (doc_layers_read).
void evaluate_layers_read(const Evaluation& evaluation);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_SCENES_H_

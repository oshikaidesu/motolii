#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LIGHTS_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LIGHTS_H_

// The lights phase of doc_evaluate: the light layers and the kind of shadows
// they cast, as they are at the evaluated time.

namespace motolii {

struct Evaluation;

// Chooses soft or crisp shadows for the stage's own view, as the lights that
// are on now ask.
void evaluate_shadow_type(const Evaluation& evaluation);

// Puts each light layer into the scenes while it is on and takes it out while
// it is off, and sets where it is, where it shines and how strong it is now.
void evaluate_lights(const Evaluation& evaluation);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_LIGHTS_H_

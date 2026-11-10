#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CAMERA_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CAMERA_H_

// The camera phases of doc_evaluate: the camera the stage is filmed with at the
// evaluated time, and the depth of field of the stage's own view.

namespace motolii {

struct Evaluation;

// Points the stage's camera as the active camera layer says: where it stands,
// its projection, lens and exposure. In the working view the user's view camera
// is used instead and the 2D layers are marked as not on.
void evaluate_camera(Evaluation& evaluation);

// Enables the camera's depth of field on the stage's own view while solid
// layers are in it, and disables it otherwise.
void evaluate_depth_of_field(const Evaluation& evaluation);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_CAMERA_H_

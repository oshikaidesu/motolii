#ifndef MOTOLII_DOCUMENT_EVALUATE_BODIES_H_
#define MOTOLII_DOCUMENT_EVALUATE_BODIES_H_
// The rigid bodies of a project, as Blender's Rigid Body World is one per
// scene: every copy (a layer, or a letter of a split text) whose expressions
// say a mass is a body, and all of them fall, touch and pile up together,
// moved by Jolt Physics (community/jolt/rigid_bodies.h).
//
// Each frame, 60 a second from the start of the project:
//   1. the expressions of every layer with bodies are asked as at any other
//      time, and what they say of each copy is told to Jolt: its mass, the
//      force on it, where its layer puts it;
//   2. Jolt steps once;
//   3. each body's place is kept for that frame (kept_frames.h), so going back
//      in time costs nothing and a change makes only the frames after it again.
// A body with mass 0 follows its layer, keyframes and all, and pushes what it
// meets (Blender's "Animated"); with a mass it is Jolt's from where it is.
//
// One metre is 100 pixels of the project, the default Pixels Per Unit of a
// Unity sprite and the pixels_per_meter of bevy_rapier's 2D examples: Jolt
// counts in metres and is accurate for bodies of 0.1 to 10 m
// (JoltPhysics/Docs/Architecture.md), which a letter then is.

#include "community/quickjs/script.h"

namespace motolii {

struct Doc;

// Puts copy `copy` of `layer` where its body is at time `said`. `c` is the
// copy as its expressions lay it, with a mass; its x, y and rotate are
// replaced. `c` is left alone while no frame can be shown yet.
void doc_body_over(Doc& d, int layer, int copy, double said, ScriptCopy& c);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_BODIES_H_

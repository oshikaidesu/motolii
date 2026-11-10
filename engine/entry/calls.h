#ifndef MOTOLII_ENTRY_CALLS_H_
#define MOTOLII_ENTRY_CALLS_H_
// calls.h: the calls of motolii.h that read and change the open project's layers, properties,
// keyframes, easings, marks and shelf lists.
//
// A call that changes the project runs on the render thread through on_render_thread. A call that
// only reads goes through by_look.
#include "entry/motolii.h"

// Puts easing `easing` on the keyframe of property `name` at time `at`. If the project lacks the
// easing but the user has an easing of that name in a file, the easing is also written into the
// project. Must run on the render thread. Returns nonzero on success.
int easing_is(Motolii* m, int layer, const char* name, double at, const char* easing);
// Defines easing `easing` in the project as the SQL expression `expression`. The user's own easings
// that the expression refers to are written into the project too, as easing_is does for an easing
// put on a keyframe. Must run on the render thread. Returns nonzero on success.
int define_is(Motolii* m, const char* easing, const char* expression);

#endif  // MOTOLII_ENTRY_CALLS_H_

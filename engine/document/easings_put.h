#ifndef MOTOLII_DOCUMENT_EASINGS_PUT_H_
#define MOTOLII_DOCUMENT_EASINGS_PUT_H_

// easings_put.h: removing a keyframe and setting the easing from a keyframe to the next.

#include <string>

#include "document/kinds.h"

// Removes the keyframe of a property at time "at". If it was the last keyframe, the property
// keeps the value that keyframe held. Returns false and sets d.error on failure.
bool doc_unkey(Doc& d, int layer, const char* name, double at);
// Returns the text listing every easing the user may name: the nine built-in kinds with the
// names of their numbers, the named easings, and the easings defined in this document.
std::string doc_easings(Doc& d);
// Sets the easing of the segment that starts at the keyframe at time "at". "easing" is one of
// the nine built-in kinds, alone or with all its numbers such as "Random 3 0.25 0.5 0.8 0.5",
// or the name of an easing defined in this document with up to four numbers. Returns false and
// sets d.error if the keyframe does not exist or the easing is not valid.
bool doc_easing(Doc& d, int layer, const char* name, double at, const char* easing);
// Defines or replaces the easing "name" as an SQLite expression. The name must not be one of
// the nine built-in kinds. The expression is tried on two segments and is accepted only if it
// starts at the first keyframe's value and ends at the second's. Returns false and sets
// d.error otherwise.
bool doc_define(Doc& d, const char* name, const char* expression);

#endif  // MOTOLII_DOCUMENT_EASINGS_PUT_H_

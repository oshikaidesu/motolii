#ifndef MOTOLII_DOCUMENT_LAYER_EDIT_H_
#define MOTOLII_DOCUMENT_LAYER_EDIT_H_

// Adds, duplicates and removes layers, and checks and sets the values and words of a layer.

#include "document/kinds.h"

// Checks that a request on a layer is allowed. Returns true if the layer exists and, when name is
// given, the layer's kind has a value of that name that accepts the request: a number, a word, or a
// keyframe when key is true. Otherwise sets d.error to the reason and returns false.
bool doc_knows(Doc& d, int layer, const char* name = nullptr, const double* number = nullptr, const char* word = nullptr, bool key = false);

// Returns the kind of layer that a file makes, by the end of its name, or "" for none. This is the
// one place that decides it. A sound is a video that is heard and not seen, see doc_add.
const char* doc_kind_of(const char* file);
// Adds a layer of the given kind (video, image, text or solid) from a file: for a text its font,
// for a solid a file or ring, gem or cube. If kind is empty, the file decides. Returns the new
// layer's number, or 0 if no layer was made, in which case no number is used up.
int doc_add(Doc& d, const char* kind, const char* file);
// Duplicates a layer as a new layer with every keyframe of it, including its keys and easings,
// lying where the original lies. Like After Effects' Duplicate Layer. The new layer has the newest
// number, as for doc_add. Returns it, or 0 on failure.
int doc_duplicate(Doc& d, int layer);
// Removes a layer. Fails if the layer is locked. Removing a relation frees its layers back to what
// is under it, as deleting a constraint does in Blender. Removing a leader first releases what it
// led. Returns true on success.
bool doc_remove(Doc& d, int layer);
// True while doc_lead itself is writing the leader.
extern bool doc_leading;
// Sets a value of a layer to one number that stays. Any keyframes it had are removed. Returns false
// and sets d.error if the request is refused.
bool doc_set(Doc& d, int layer, const char* name, double is);
// Sets a word of a layer. Returns false and sets d.error if the request is refused.
bool doc_say(Doc& d, int layer, const char* name, const char* word);

#endif  // MOTOLII_DOCUMENT_LAYER_EDIT_H_

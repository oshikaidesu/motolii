#ifndef MOTOLII_DOCUMENT_EDIT_PARENT_H_
#define MOTOLII_DOCUMENT_EDIT_PARENT_H_

// parent.h: parenting and ordering of layers for doc.h. It sets a layer's parent, finds the layers
// a group holds, and moves a layer among the layers.

#include <vector>

#include "document/kinds.h"

// Makes `to` the parent of the layer (0 means no parent) without moving the layer on the stage, as
// After Effects does. The layer's position, its rotation about the camera's line of sight and its
// size are expressed again relative to the new parent. A property with keyframes is moved as a
// whole, by the rule of doc_put. A keyed size is left as it is.
// A parent that leans, rotated about x or y, is not undone in the rotation: only the layer's
// position takes it into account. Returns false, with d.error set, if the change is refused.
bool doc_parent(Doc& d, int layer, double to);
// Makes sure the property has a keyframe at time `at`, keeping its value there. Returns false if
// the layer lacks the property. If time_remap has no keyframes yet, it first gets one at the
// layer's start and one at its end, so that the remap starts as the identity.
bool doc_key_here(Doc& d, int layer, const char* name, double at);
// Returns the layers a group holds, however deep. Only a Null layer holds layers. A layer that is
// the parent of others but is not a Null holds nothing, because After Effects' parenting moves a
// child and does not take it in.
std::vector<int> doc_under(Doc& d, int group);
// Moves the layer `places` places nearer among the layers, or further back if places is below 0.
// The order of every layer is written again as one change. A group moves with the layers it holds,
// as one place. A precomposed layer counts as one layer. Returns false, with d.error set, if the
// layer would not move.
bool doc_raise(Doc& d, int layer, int places);

#endif  // MOTOLII_DOCUMENT_EDIT_PARENT_H_

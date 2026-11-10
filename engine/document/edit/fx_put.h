#ifndef MOTOLII_DOCUMENT_EDIT_FX_PUT_H_
#define MOTOLII_DOCUMENT_EDIT_FX_PUT_H_

// Putting effects on a layer, reordering them in its list and taking them off.

#include <cmath>
#include <string>
#include <vector>

#include "document/kinds.h"

namespace motolii {

// Returns the effects of the shelf, one per line, each line holding these
// fields separated by tabs:
//   name, value, label, picture, two empty fields, about
// `picture` is thing_<value>.png in the library's effects/ folder, or "" when
// there is none. `about` is what the effect does; it is the 7th field of the
// result of motolii_effects.
std::string doc_effect_names();
// Sets the layer's effect list to `list`. An empty list unsets it. Returns
// false and sets d.error when the layer is a camera and `list` holds anything
// other than a .am motion.
bool doc_fx_say(Doc& d, int layer, const std::vector<std::string>& list);
// Puts an effect file at the end of the layer's effect list, or takes it out if
// it is already in the list. This is one undo step.
//
// Taking an effect out also deletes the keyframes and values of its parameters,
// as deleting an effect does in After Effects and Alight Motion, so that
// putting it on again starts fresh. Turning the effect off with its eye,
// fx_off, keeps them, as in Alight Motion.
//
// `now` is the time at which a transition is put on, or NAN when there is none.
// A transition runs from that time: its progress is keyed 0 then and 1 a second
// later, so the layer goes away and what is under it shows. This is how the
// transition effects of After Effects take a layer away, with Transition
// Completion from 0 to 100%, and how its transition presets lay keys from the
// current time. A second is the default length of a transition in editors such
// as Premiere Pro and Final Cut Pro, which uses 30 frames. The user can make it
// longer or shorter by moving the keys.
//
// A transition is an ISF effect, see ISF_Spec. It has a progress input and an
// endImage input for the image it goes to.
bool doc_fx_file(Doc& d, int layer, const char* file, double now = NAN);
// Moves one of the layer's effects by `by` places in its list, like dragging an
// effect up or down the stack in After Effects. The effect is a file, or a
// built-in ThorVG effect named by its property, or either one named by its card
// title. This is one undo step.
bool doc_fx_move(Doc& d, int layer, const char* name, int by);
// Puts the shelf effect `name` on the layer at time `at`, or takes it off if it
// is already on. Taking it off unsets its property and its keyframes. This is
// one undo step.
bool doc_effect(Doc& d, int layer, const char* name, double at);
// Turns one of the layer's effects off, or back on, like the eye on an effect
// in Alight Motion. The effect is named by its card title. Its values are kept.
bool doc_fx_eye(Doc& d, int layer, const char* title);
// Takes one of the layer's effects off, named by its card title or its own
// name. This is what the shelf does when the effect is pressed again, and what
// Delete does on an effect card in Alight Motion. An effect file is removed
// from the list, see doc_fx_file. A built-in ThorVG effect is unset, see
// doc_effect. This is one undo step.
bool doc_fx_out(Doc& d, int layer, const char* name);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_FX_PUT_H_

#ifndef MOTOLII_DOCUMENT_EVALUATE_RELATIONS_H_
#define MOTOLII_DOCUMENT_EVALUATE_RELATIONS_H_
// Behaviours, falloffs, relations and copy placement for layers.

#include <math/mat4.h>
#include <math/vec3.h>

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"

namespace filament {
class MaterialInstance;
}  // namespace filament

namespace motolii {

struct Doc;
struct Mesh;

// One relation's layers. members: the layers in order, with 0 where one was
// removed. under: for each member, the relation it was in before; that
// relation's result is this member's start. from: for each member, where it
// showed when it joined, as x and y.
struct DocRelation {
  std::vector<int> members, under;
  std::vector<double> from;
};

// What is known of the behaviors and relations of the project. Found once and
// cleared at every change, unless said otherwise.
struct DocRelations {
  // Each value's behavior (`<name>_by`), by layer and name. Found once and
  // cleared at every change.
  std::map<std::pair<int, std::string>, int> drivers;
  // Whether a layer has any value connected to a behavior. Computed on first
  // use and cleared at every change.
  std::unordered_map<int, bool> connects;
  // Relation data by layer. Found once and cleared at every change.
  std::unordered_map<int, DocRelation> relationsOf;
  // Set while working out where layers settle. Relations give nothing then,
  // because what a relation written as a file gives may change with time, so a
  // relation made while another is moving its layers does not keep that
  // movement.
  bool settled = false;
  // Copies laid out by AbsentMotion effects.
  struct AbsentKept {
    double at = -1;
    long changes = -1;
    int seen = -1;
    std::vector<AbsentCopy> copies;
  };
  // Each layer's copies as AbsentMotion's repeat effects lay them at the time
  // last asked, see doc_absent_copies.
  std::map<int, AbsentKept> absentKept;
};

// Returns the value that behaviour layer `by` gives to copy number `copy` of
// `n` copies at time `t`. The behaviour type is the layer's "file" value:
// stagger, oscillator, noise or random. A number from 0 to 1 is mapped onto the
// range from "minimum" to "maximum", then rounded to a multiple of "step" when
// step is positive. As in Cavalry, a parameter of a behaviour can itself be
// driven by another behaviour.
double doc_behaviour_at(Doc& d, int by, int copy, int n, double t);
// Returns whether any property of the layer is connected to a behaviour, that
// is, whether it has a nonzero `<name>_by` value. The answer is cached per
// layer.
bool doc_connects(Doc& d, int layer);
// Returns the id of the behaviour that drives property `name` of the layer,
// stored as the property
// `<name>_by`. Returns 0 when there is none, or when the target is not a
// behaviour layer.
int doc_driven_by(Doc& d, int layer, const char* name);
// Returns how strongly behaviour `by` applies at the point `at` of the stage,
// from 0 to 1. The falloff is the outline of the layer named by the behaviour's
// "region" value, placed where it is at time `t`. Inside the outline the result
// is 1. Outside it falls linearly to 0 over the distance "falloff_soft".
// "falloff_invert" swaps inside and outside. The result is 1 when the behaviour
// has no falloff.
double doc_falloff_at(Doc& d, int by, filament::math::double3 at, double t);
// Returns the value that behaviour `by` gives to a copy. When the copy's
// position `at` is known, the result is blended between the property's own
// value `own` and the behaviour's value by the falloff at that position. `at`
// may be null.
double doc_given(Doc& d, int by, int copy, int n, double t, double own,
                 const filament::math::double3* at);
// Gives every renderable of mesh `m` its shared material back and destroys the
// materials made just for single copies. `main` is the shared material; when it
// is null the renderables are left as they are.
void doc_copy_looks_off(Doc& d, const Mesh* m,
                        filament::MaterialInstance* main);
// Returns the layers that belong to relation `by`, and the data kept for each.
// A layer belongs when any of its properties has `<name>_by` equal to `by`, or
// when it is reached through another relation that this one builds on.
// `members` follows the order of the relation's "members" value. A slot is 0
// where a layer was removed, so the other layers keep their places. Layers not
// listed there come after, in ascending layer id. `under` has, for each member,
// the relation it was in before. `from` has two numbers per member, x and y,
// saying where the layer appeared when it joined. Each is empty unless it
// matches the number of members. The result is cached.
const DocRelation& doc_relation_of(Doc& d, int by);
// Returns the member layers of relation `by`, in order.
inline const std::vector<int>& doc_members_of(Doc& d, int by) {
  return doc_relation_of(d, by).members;
}
// The properties that a relation written as a file
// (engine/document/evaluate/world.h) can set on its layers. The file returns
// one number per member for each name, in this order.
inline const char* const doc_relate_names[] = {
    "x", "y", "z", "size", "rotate", "rotate_x", "rotate_y", "opacity"};
// Returns the value that relation `by` gives to property `name` of `layer` at
// time `t`. `own` is the layer's own value, and the result is blended with it
// by the relation's strength. The result starts from the value that the
// relation the layer was in before gives, or from `own` when there is none. The
// script gets where each layer appeared when it joined (`from`), so it can add
// only the step from there to the new place, and a layer that the user drags
// stays where it is dragged. If the script has a track called `lag`, member n's
// strength is read n times that many seconds late.
double doc_related(Doc& d, int by, int layer, const char* name, double t,
                   double own);
// Returns the value of property `literal` of the layer at time `at`, or
// `otherwise` when the property has no keyframes. `literal` must be a string
// literal, because its address identifies the name in the cache. The keyframes
// of a property are found once and kept until the document changes, as Beutl
// and Skottie do for properties, and each call only evaluates them. The cache
// is not used while the user drags the layer. A property driven by a behaviour
// gets the behaviour's value for the copy being placed. One driven by a
// relation gets the relation's value.
double doc_literal(Doc& d, int layer, const char* literal, double at,
                   double otherwise);
// Like doc_literal, but for a text property. The text is cached in the same
// way.
const std::string& doc_literal_word(Doc& d, int layer, const char* literal);
// Returns the copies that AbsentMotion's repeat effects lay out for the layer
// at time `now`, see engine/community/absent_motion/absent_motion.h. The
// effects are the .am files in the layer's fx list. The result is computed
// again only when the time, the document or a file has changed. It is empty
// when no repeat effect is on the layer.
const std::vector<AbsentCopy>& doc_absent_copies(Doc& d, int layer, double now);
// Returns the text of a text layer as it is shown at time `now`. It is the
// typed text, or the text changed by AbsentMotion's text effects on the layer
// such as Count Up, Count Down, Timecode and Text Randomizer, see
// engine/community/absent_motion/absent_motion.h. They run at the stage's 60
// frames a second, the RATE in engine/entry/render_thread.h. `moves`, when
// given, is set to whether an effect changes the text.
std::string doc_text_shown(Doc& d, int layer, double now,
                           bool* moves = nullptr);
// Returns whether AbsentMotion's Motion Blur or Shutter Blur is on the layer.
// If so, `open` receives how long the shutter is open in seconds at the stage's
// 60 frames a second, and `moves` whether the motion path is smeared.
bool doc_shutter(Doc& d, int layer, double now, double* open, bool* moves);
// Returns the opacity that the layer inherits from its groups, following Alight
// Motion, where the opacity and visibility of a group apply to everything in
// it. The groups are the Null layers that the layer is parented to, up to the
// top. A Null draws nothing of its own, so its opacity belongs to its group.
// The opacities are multiplied. The result is 0 when one of the Nulls is
// hidden, and 1 when there are none.
double doc_group_opacity(Doc& d, int layer, double now);
// Returns the opacity share that AbsentMotion's opacity effects leave on the
// layer, 1 when there are none.
double doc_absent_opacity(Doc& d, int layer, double now);
// Returns how many members the layer has in their order. A text split into
// letters has one per letter. Otherwise it is the number of copies that
// AbsentMotion's repeat effect lays, or the "copies" value. The result is at
// least 1.
int doc_members(Doc& d, int layer);
// Returns how much later copy `nth` of the layer moves than the layer itself.
// The "stagger" value is spread over the copies by their order, as in GSAP's
// stagger. "stagger_from" chooses whether the order runs from the start, from
// the centre out, from the end, or from the edges in.
double doc_delay(Doc& d, int layer, int nth);
// Returns the transform of the layer's parent, or the identity when there is no
// parent or it does not exist any more. A 2D layer parented to a camera also
// gets the identity, because it already sticks to the camera in doc_place and
// would take the camera's moves twice.
filament::math::mat4 doc_above(Doc& d, int layer, double now, int deeper = 0);
// Returns where the middle of letter `copy` of a split text layer lies across
// the layer, in the layer's own units. Returns 0 when `copy` is not a letter of
// the layer. For a text split into lines, the middle across of line `copy`
// as it is set, short lines to the side their alignment puts them.
double doc_letter_middle(Doc& d, int layer, int copy);
// Returns where the middle of line `copy` of a text layer split into lines
// lies up the layer, in the layer's own units (up is positive). Returns 0
// when the layer is not split into lines or `copy` is not one of them.
double doc_line_middle(Doc& d, int layer, int copy);
// Returns whether the stage places a layer as a member of its copies, or as
// itself. A member is delayed by its order, the first copy too, and laid out as
// its expressions say. The stage and everyone who asks how the layer moves,
// such as motolii_path, place it in the same way.
bool doc_staggered(Doc& d, int layer, double now);
}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_RELATIONS_H_

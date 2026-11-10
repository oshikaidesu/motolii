#ifndef MOTOLII_DOCUMENT_EDIT_HOLD_H_
#define MOTOLII_DOCUMENT_EDIT_HOLD_H_

// Dragging a layer, or a value of a layer.
//
// A drag has three steps: doc_hold starts it, doc_carry updates it, and the end
// of the drag either keeps or discards it. This is the one form of every
// pointer drag: a layer on the stage, its bar on the timeline, a number. While
// the drag lasts, the dragged state is shown at once but is not part of the
// document. When the drag ends and is kept, it becomes one undo step. When it
// is discarded, nothing happened. All the arithmetic of a drag lives here,
// once. The app reports where the pointer is and never works out what the
// document should hold.
//
// doc_carry takes a mode `by` and two numbers a and b. The modes are:
//   "place"   Move the layer on the stage. a, b are how far the pointer has
//   moved since it took
//             hold, in canvas points (right, down). The layer stays under the
//             pointer at its own depth.
//   "bar"     Slide the layer's bar on the timeline. a is how many seconds
//   later the layer comes
//             on.
//   "head", "tail"
//             Cut the layer's bar at one end. a is how many seconds later that
//             end is. A video cut at its head goes on showing at each time what
//             it showed there.
//   "grip"    Record where on the canvas the pointer took hold, as a, b in
//   points from the top
//             left. It must be called before "scale", "side", "turn", "pivot"
//             and "point".
//   "point"   Move the point of a path shape that is nearest the grip, or its
//   handle. a, b are
//             how far the pointer has moved, in canvas points. The handles of a
//             moved point move with it.
//   "scale"   Resize the layer about its pivot as far as the pointer has moved
//   from the grip. "side"    The same, but the side or corner opposite the grip
//   stays where it is. "even_scale", "even_side"
//             The same, with width and height scaled alike. Held by a corner,
//             the scale follows the pointer's travel along the line from that
//             corner to the opposite corner or the pivot. Held by the middle of
//             a side, the other axis is scaled as much.
//   "turn"    Rotate the layer about its pivot as far as the pointer has moved
//   round it. "even_turn"
//             The same, snapped to the nearest 15 degrees.
//   "pivot"   Move the pivot to follow the pointer while the layer stays where
//   it appears. A property name
//             Drag that number. a is its new value.

namespace motolii {

struct Doc;

// Starts a drag on `layer`. Returns false if the layer does not exist, or if
// the project is being exported, because nothing can be dragged until the
// export is done. If a drag is already on this layer it simply continues.
bool doc_hold(Doc& d, int layer);
// Returns how far the layer's own clock advances when `by` seconds of its
// beginning are cut away. A video's clock runs at its speed. A layer with a
// script runs at the stage's rate. Returns 0 for a layer without a clock of its
// own. After Effects' Split Layer and in-point leave the layer's keyframes
// where they are, so what the layer was doing goes on.
double doc_own_clock(Doc& d, int t, double by);
// Updates the current drag according to mode `by` and the numbers a and b; see
// the table at the top of this file. Returns false and sets d.error when
// nothing is being dragged, when a mode that needs "grip" did not get one, or
// when a property rejects the new value. Evaluates the stage at the end.
bool doc_carry(Doc& d, const char* by, double a, double b);
// Shows an effect file on the dragged layer as a preview. The effect is drawn
// last of the layer's effects, as doc_fx_file would put it at the end. It is
// not part of the document and does not appear on the layer's cards, and it
// disappears when the drag ends. Final Cut Pro's effects browser does the same
// by skimming an effect over the clip selected in the viewer, and DaVinci
// Resolve's Live Preview does it for the clip the pointer is over. To put the
// effect on for good, the app ends the drag first and then puts it on as a
// press does, see doc_fx_file, which also handles the keyframes of a
// transition.
bool doc_carry_effect(Doc& d, const char* file);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_HOLD_H_

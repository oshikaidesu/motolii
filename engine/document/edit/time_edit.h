#ifndef MOTOLII_DOCUMENT_EDIT_TIME_EDIT_H_
#define MOTOLII_DOCUMENT_EDIT_TIME_EDIT_H_

// Edits to a layer's timing: moving keyframes, splitting, extracting the work
// area, sequencing and aligning layers, stretching speed, resetting properties,
// and undo and redo.

#include <string>
#include <vector>

#include "document/document.h"

namespace motolii {

// Duplicates `layer` and places the copy directly above it, as one undo step.
// Returns the copy's number, or 0 on failure.
int doc_copy_above(Doc& d, int layer);
// Cuts a layer in two at time `at`, as Ableton Live's Split (Cmd+E) and
// AbsentMotion's Scene.splitAt do. The original ends at `at`. A copy begins at
// `at`, lies directly above the original, and keeps every keyframe where it is
// on the timeline. A video's copy continues from where the first part stops.
// One undo step. Returns the copy's number, as doc_duplicate does, or 0 with
// d.error set on failure.
int doc_split(Doc& d, int layer, double at);
// Takes the work area out and closes the gap, as After Effects' Edit > Extract
// Work Area, Premiere Pro's Extract and DaVinci Resolve's Ripple Delete do.
// Every layer that crosses an edge of the work area is split there with
// doc_split, so that a video's later part continues further into the video. The
// parts inside the work area are removed. Everything after it moves earlier by
// its length, keyframes included. Markers inside the work area are removed and
// markers after it move earlier too. This is what Premiere Pro does with Ripple
// Sequence Markers on: markers after an edit move with the ripple, and from
// version 25.3 markers in the extracted part are cleared. One undo step. For
// example, taking 5 seconds out of the middle of 20 seconds leaves 15, and the
// markers on hits stay with their hits. Returns false with d.error set if the
// work area covers the whole project.
bool doc_extract(Doc& d);
// Ends a drag. If `keep` is true, the values changed during the drag are
// written to the project as one undo step. If `keep` is false or nothing
// changed, the drag is dropped and the stage is rebuilt from the project.
// Returns false with d.error set if no drag was in progress.
bool doc_let_go(Doc& d, bool keep);
// Lines up layers one after another in time, like After Effects' Sequence
// Layers (Keyframe Assistant). It applies to the layers that have a length and
// stand on their own: visible, unlocked, without a parent, and not a camera or
// a light. They are taken from the front of the stack. Each begins where the
// one before ends less `overlap` seconds, on a frame of `rate` frames per
// second, and never before the one before. The first stays where it is. Each
// layer moves whole, with its keyframes. One undo step. Returns false with
// d.error set if fewer than two layers qualify.
bool doc_sequence(Doc& d, double overlap, double rate);
// Lines up the given layers in time, with the modes of Alight Motion's timing
// menu and Final Cut Pro's Extend Edit. `how` is one of:
// - start: every layer starts at the earliest start.
// - end: every layer ends at the latest end.
// - playhead: every layer starts at `now`.
// - playhead_end: every layer ends at `now`.
// - stagger: the layers follow one another in the order given.
// - extend: the start moves to `now`, earlier or later, and the end stays. A
// video continues from
//   where it would have been at the new start.
// - trim_end: the end moves to `now` if `now` is inside the layer.
// A moved layer takes its keyframes with it, as in doc_sequence. One undo step.
// Returns false with d.error set on failure.
bool doc_time_align(Doc& d, const std::vector<int>& layers,
                    const std::string& how, double now);
// Changes a layer's speed while holding one point fixed. `hold` is "start",
// "now" or "end", which keeps the layer's start, the time `now`, or its end in
// place. This follows After Effects' Time Stretch with Hold in Place set to
// Layer In-point, Current Frame or Layer Out-point, and Pinnacle Studio's speed
// anchor. The layer lasts proportionally longer when it is slower, and its
// keyframes are stretched about the fixed point. A video plays the same stretch
// of itself. One undo step. Returns false with d.error set for a speed near 0
// or an unknown `hold`.
bool doc_time_stretch(Doc& d, int layer, double speed, const std::string& hold,
                      double now);
// Resets the named properties of a layer to their defaults, as After Effects'
// Reset does for a group of properties: their keyframes and set values are
// deleted, and so are those of
// `<name>_loop`. `names` is a space-separated list. One undo step. Returns
// false if a name is not a property of the layer.
bool doc_reset(Doc& d, int layer, const std::string& names);
// Undoes the last undo step. Returns false if there is none.
bool doc_undo(Doc& d);
// Redoes the last undone step. Returns false if there is none.
bool doc_redo(Doc& d);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_TIME_EDIT_H_

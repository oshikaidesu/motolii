#ifndef MOTOLII_DOCUMENT_DOC_H_
#define MOTOLII_DOCUMENT_DOC_H_

// doc.h: the project document and the calls that edit it.
//
// The document is a table of keyframes: the value of a layer's named property at a time, as
// (layer, name, at, value). A property with one keyframe is constant. A property with several
// keyframes moves between them. Each call makes one change, which is one undo step, and the
// canvas shows the change by the time the call returns. A change the canvas cannot show is
// not made.
//
// Easing: a keyframe holds a value, and the easing of the segment from a keyframe to the next
// defines how the value moves between them. The built-in easings are the nine kinds in
// easing_curves.h: Hold, Linear, Bezier, Bounce, Elastic, Cyclic, Random, Steps and
// ElasticSteps, each with its own numbers. A custom easing can be added as an SQLite
// expression stored in the document. Its variables are:
//   u        progress through the segment, from 0 to 1
//   t        seconds since the segment began
//   d        length of the segment in seconds
//   a, b     the values of the two keyframes
//   p1..p4   numbers supplied with the easing
// A custom easing is accepted only if it starts at the first keyframe's value and ends at the
// second's.
//
// Storage and undo come from SQLite: the file format, saving (a change is in the file when its
// call returns), and undo through the session extension. A change is recorded as a changeset,
// and undo applies the changeset inverted. The undo steps are stored in the file too. A
// layer's time uses the names from GES: start and duration.
//
// Property names follow ThorVG where ThorVG has a name for the same thing: translate's x and
// y, rotate, size, blend and its modes, text, fill, and the begin, add and remove of a
// segment. The properties are:
//
//   Numbers
//     x, y, z, rotate, size  Center position, rotation in degrees, and height.
//     rotate_x, rotate_y     Rotation in degrees about the layer's own x and y axes, which
//                            tilts a layer back or turns it sideways.
//     opacity                1 is fully visible and 0 is invisible. Applies to video, image
//                            and text layers.
//     start, duration        When the layer appears and for how long. If not set, the layer
//                            stays for the whole project and loops.
//     begin, speed           Video only: the offset into the source and the playback speed.
//                            A negative speed plays backwards.
//     order                  Stacking order among layers. A greater number is nearer the
//                            viewer. If not set, layers stack in creation order.
//     visible                0 hides the layer without removing it from the document, as in
//                            ThorVG.
//     clip                   1 shows the layer only inside the box of the layer before it,
//                            for example a 3D layer cut by a rectangle.
//     wide                   Shape only: the width as a multiple of the height.
//     keyed                  Video only: 1 removes a solid background, such as a green
//                            screen, whose color is the one shared by the four corners. 0
//                            keeps the background. If not set, the background is removed
//                            when the video has such a color.
//
//   Words
//     blend                  How the layer combines with what is behind it:
//                            normal | add | multiply | screen.
//     file, shape            What the layer is made from. The add call sets them. For a file
//                            layer it is the file, and for a text layer it is the font. For a
//                            solid it is one of the built-in shapes: ring | gem | cube. For a
//                            flat shape drawn by ThorVG it is rect | circle.
//     text                   The text to show, up to the end of the line.
//     fill                   The surface of the layer. For text it is a color as six hex
//                            digits, such as ff3366. For a solid it is a color or the
//                            material glass.
//
// The document is split into the parts below. Read them in this order, because each part
// builds on the ones before it.
// Document kinds and the names of properties.
#include "document/kinds.h"
// The properties a layer may have and how each is displayed.
#include "document/values.h"
// A layer's scripts, whose parameters become properties of the layer.
#include "document/scripts/scripts.h"
// The cards that group a layer's properties.
#include "document/card_table.h"
// Reading a property at a time: its keyframes, easings, and the clock of an element or program.
#include "document/evaluate/value_at.h"
// The material of a layer, and how its looks and drawn parts appear on the canvas.
#include "document/evaluate/material.h"
// Behaviors, falloffs, relations and physics.
#include "document/evaluate/relations.h"
// Relations stored as files, and the world shared by the relations that push.
#include "document/evaluate/world.h"
// A layer's expressions, which lay out its copies as many times as it has effects.
#include "document/scripts/expressions.h"
// Where a layer and its copies are placed, and what connects them.
#include "document/evaluate/place.h"
// Where a camera looks from, plus the canvas camera, light and backdrop the document defines.
#include "document/evaluate/camera.h"
// A layer's effects in the order they are applied, and how the effect stack runs them.
#include "document/evaluate/fx_list.h"
// Evaluating a layer that has effects of its own at a time.
#include "document/evaluate/moment_fx.h"
// Godot Tween easing, used for the notes of a MIDI roll.
#include "motion/easing_godot.h"
// What a p5.js sketch draws in WEBGL: one mesh in the world.
#include "document/evaluate/sketch.h"
// Evaluating the canvas at a time.
#include "document/evaluate/evaluate.h"
// Rebuilding the canvas from the document, and opening, changing and undoing the file.
#include "document/match.h"
// Project length, work area, markers, guides, window settings and canvas size.
#include "document/marks.h"
// Opening the document file, recording each change as one undo step, undo and redo.
#include "document/undo.h"
// Adding, recreating, freeing and removing layers, and setting properties.
#include "document/edit/layer_edit.h"
// Putting a layer in a relation and taking it out, and starting and ending a relation drag.
#include "document/edit/relate.h"
// Putting keyframes on a property, and changing a property the way a drag does.
#include "document/edit/keys_put.h"
// Giving a layer a parent, what a group holds, and raising a layer in the stacking order.
#include "document/edit/parent.h"
// The form of a recipe, and the folders the shelves are read from.
#include "document/scripts/folders.h"
// Recipes.
#include "document/scripts/recipes.h"
// A layer's properties as the app lists them: names, words, ranges and cards.
#include "document/cards.h"
// Putting effects on a layer, moving them in its list, and removing them.
#include "document/edit/fx_put.h"
// Removing a keyframe, and setting the easing from a keyframe to the next.
#include "document/edit/easings_put.h"
// What the app reads to draw its lists, and where a layer appears on the image.
#include "document/evaluate/shown.h"
// Code from the net, run through adapters.
#include "document/scripts/adapter.h"
// Saving a layer's look and applying it to another layer.
#include "document/edit/presets.h"
// The plane and points of a path shape.
#include "document/edit/paths.h"
// Moving, aligning and fitting a layer on the image, and a property value as it arrives.
#include "document/edit/arrange.h"
// Holding a layer with a drag, carrying it, and letting go.
#include "document/edit/hold.h"
// Editing a layer's time: moving, cutting, removing, sequencing and stretching keyframes, plus
// reset and undo.
#include "document/edit/time_edit.h"

#endif  // MOTOLII_DOCUMENT_DOC_H_

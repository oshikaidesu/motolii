// doc.h: a document of the stage, and the editing of it as calls: what a shell on a screen would call, and nothing
// else. The document is a file of facts: a thing's value, by name, at a time (thing, name, at, value). A value with one
// fact stays as it is; with more it moves, and they are its keys. One call = one change = one step of undo (Lumit's
// bridge is so), and the stage shows it as the call returns. A change the stage cannot show is not made.
// Keys, Motolii's own way: a key holds a value, and THE STRETCH FROM A KEY TO THE NEXT IS ITSELF DEFINED: how the value
// goes there. The kinds of stretch are Motolii's own nine, brought from the past repository as they are (easing_curves.h:
// Hold, Linear, Bezier, Bounce, Elastic, Cyclic, Random, Steps, ElasticSteps, each with its numbers). A way of one's
// own can be added by an expression kept in the document (worked out by SQLite's own expressions: u is how far
// through the stretch, 0 to 1; t the seconds into it; d its length; a and b the two keys' values; p1 to p4 numbers
// said with it), taken only if it begins at the one key's value and ends at the other's.
// Borrowed whole: the file, saving (a change is in the file as its call returns) and undo are SQLite's (its session
// extension: what a call changed is kept, and undone by applying it reversed: the steps are in the file too). A
// thing's time is told in GES's words (start, duration).
// The names a thing's facts go by are ThorVG's own, where it has one (translate's x and y, rotate, size, blend and its
// words, text, fill, a segment's begin, add, remove):
//   numbers  x, y, z, rotate, size  where its middle is, turned by how many degrees, how tall
//            rotate_x, rotate_y     turned about its own x and y too (degrees): a thing leaning back, a thing turned to its side
//            opacity                how much of it is there: 1 all, 0 none (a film's, a picture's, a text's)
//            start, duration        when it comes on, and for how long (not said: for good, going round)
//            begin, speed           a film's: from where in itself, how fast (below 0: backwards)
//            order                  where it lies among the things: one with a greater number is nearer (not said: as they were made)
//            visible                0: it is put aside, not seen (ThorVG's word), though it is still in the document
//            clip                   1: it is seen only inside the frame of the thing before it (a 3D thing cut by a rectangle)
//            wide                   a shape's: how many times as wide as it is high
//            keyed                  a film's: 1 if its ground is keyed out (a green screen, of whatever colour: the colour its four corners share), 0 if not; not said: keyed if it has such a ground
//   words    blend                  how it lies on what is behind: normal | add | multiply | screen
//            file, shape            what it was made from (add says them): a file (a text's: its font); or, a solid's, one of the kit's shapes: ring | gem | cube;
//                                   or, a shape's (a flat one, drawn by ThorVG), rect | circle
//            text                   a text's: what it says (to the end of the line)
//            fill                   what its surface is: a text's colour as six digits (ff3366); a solid's: a colour, or the material glass
// In parts, read in this order (each a piece of the one before it, none alone):
#include "document/kinds.h"   // (the document and the names its values go by)
#include "document/values.h"   // (the values a thing may have, and how each is shown)
#include "document/scripts.h"   // (a thing's scripts, their knobs as its values)
#include "document/card_table.h"   // (the cards a thing's values are gathered in)
#include "document/value_at.h"   // (a value read at a moment: its keys and ways, an element's and a program's own clock)
#include "document/material.h"   // (the material a thing wears; its looks and drawn parts on the stage)
#include "document/relations.h"   // (behaviours, falloffs, relations, physics)
#include "document/world.h"   // (relations written as files, and the world those that push share)
#include "document/expressions.h"   // (a thing's expressions: what lays its copies, as many as its effects)
#include "document/place.h"   // (where a thing and its copies lie, and what joins them)
#include "document/camera.h"   // (where a camera looks from; the stage's eye, light and backdrop as the document says)
#include "document/fx_list.h"   // (a thing's effects in the order they are laid, and as its stack runs them)
#include "document/moment_fx.h"   // (a thing with effects of its own, told a moment)
#include "motion/easing_godot.h"   // (Godot's Tween's easing, for a MIDI roll's notes)
#include "document/sketch.h"   // (what a p5.js sketch draws in WEBGL, one mesh in the world)
#include "document/evaluate.h"   // (the stage told a moment)
#include "document/match.h"   // (the stage made again as the document says; its file opened, changed, undone)
#include "document/marks.h"   // (the document's length, work area, marks, guides, window settings and stage size)
#include "document/undo.h"   // (the document's file opened; each change kept as one step, undone and done again)
#include "document/layer_edit.h"   // (things added, made again, freed, removed; values and words said)
#include "document/relate.h"   // (a thing put in a relation and taken out of it; a relation led, let go)
#include "document/keys_put.h"   // (keys put on a value, and a value changed as a hand changes it)
#include "document/parent.h"   // (a thing given a parent; what a group holds; a thing raised among the things)
#include "document/folders.h"   // (a recipe's form, and the folders the shelves are read from)
#include "document/recipes.h"   // (recipes)
#include "document/cards.h"   // (a thing's values as a shell lists them: names, words, ranges, cards)
#include "document/fx_put.h"   // (effects put on a thing, moved in its list, taken off)
#include "document/easings_put.h"   // (a key taken off, and the ways from a key to the next)
#include "document/shown.h"   // (what a shell reads to draw its lists, and where a thing is seen on the picture)
#include "document/adapter.h"   // (code from the net)
#include "document/presets.h"   // (a thing's look kept and given to another)
extern "C" {
#include "curve_fit_nd.h"   // (doc_curve: a hand's way made cubic Béziers; curve_fit_nd.sh)
}
#include "document/paths.h"   // (a path shape's plane and points)
#include "document/arrange.h"   // (a thing moved, lined up and fitted on the picture; a value as it comes)
#include "document/hold.h"   // (a thing held by a hand, carried and let go)
#include "document/time_edit.h"   // (a thing's time edited: keys moved, cut, taken out, laid in turn, stretched; reset, undo)

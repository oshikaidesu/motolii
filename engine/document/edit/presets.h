#ifndef MOTOLII_DOCUMENT_EDIT_PRESETS_H_
#define MOTOLII_DOCUMENT_EDIT_PRESETS_H_

// presets.h: saving, applying and pasting presets, copies and elements of
// layers, and packaging a project with its files.
//
// A preset is a document of its own that holds one layer, numbered 1. It stores
// that layer's keyframes in the same layout as a project (name, at, value,
// easing), together with the easings they use. It leaves out what the layer is
// and holds (kind, file, text, a shape's figure and path), its position (x, y,
// z), its parent, and its size and rotation unless they are animated. A preset
// is saved with SQLite's copy between two database files (ATTACH, then insert
// ... select) and applied the same way inside one undo step, so the changes are
// recorded by SQLite's session extension like any other change. A file that
// lies in the library's folders or in the user's own folders is stored as
// {motolii}/... or {own}/... (see doc_folders), so that a preset made on one
// machine finds its files on another. Only text values are rewritten; a number
// stays a number.
//
// Compare After Effects animation presets (.ffx: effects and their keyframes)
// and Alight Motion's Save as Preset and Paste Style.

#include <string>

#include "document/kinds.h"

namespace motolii {

// Writes the layer's preset to the file `path`, replacing any existing file.
// With `whole`, everything except the parent is kept; this is a copy for Edit >
// Copy, which doc_preset_paste turns back into a layer. `only` is a list of
// property names separated by spaces; only those properties are kept, as for
// the card of one effect. Alight Motion copies a single effect the same way.
// Returns false and sets d.error on failure.
bool doc_preset_save(Doc& d, int layer, const char* path, bool whole = false,
                     const std::string& only = "");
// Applies the preset file at `path` to the layer as one undo step. Each
// property the preset defines replaces the layer's own value of that name, with
// its keyframes and easings; the layer's own values of those names are deleted
// first. The rest of the layer is unchanged. Behaviours the preset carries are
// created anew as layers, and the layer's _by links are pointed at them.
// Returns false and sets d.error on failure.
bool doc_preset_put(Doc& d, int layer, const char* path);
// Turns a copy (from doc_preset_save with `whole`) back into layers, as Edit >
// Paste. Returns the number of the first new layer, or 0 on failure. The pasted
// layer begins at time `now` and its keyframes move with it, as doc_keys_by
// moves the keyframes of a layer, like pasting at the insert marker in Ableton
// Live. The behaviours the copy carried and the layers a group held are created
// anew after it, in their order, moved in time by the same amount, with every
// link among them renumbered. All of this is one undo step.
//
// `also` is extra SQL run in the same step. It can use the table pasted_as,
// which maps each layer number in the copy to its new number. `before` is SQL
// run first. `into` is the number of a layer that is already here: it replaces
// the copy's first layer and is kept as it is, and what the copy holds is
// created anew in it.
int doc_preset_paste(Doc& d, const char* path, double now,
                     const char* also = "", int into = 0,
                     const char* before = "");
// Saves the layer's preset on the shelf under `name`, in the user's own presets
// folder (see doc_folders), replacing a file of that name. Compare Alight
// Motion's Save as Preset and After Effects' Save Animation Preset. `only`
// keeps those properties alone, with their keyframes, as for the card of one
// effect, as Alight Motion's preset of one effect. Returns false and sets
// d.error on failure.
bool doc_preset_keep(Doc& d, int layer, const std::string& name,
                     const std::string& only = "");
// Gathers the project and the files it uses in one folder, so that it can be
// taken to another machine whole. Compare Alight Motion's project package and
// After Effects' Collect Files. The project is copied as SQLite copies a
// database (VACUUM INTO) under `name`. Each file a layer uses (its `file`
// value) is copied beside it, except files in the library's folders or the
// user's own folders, which are found on any machine. In the copy, the file
// values become bare file names, which are read relative to the folder the
// project is opened from. Returns the number of files copied, or -1 on failure.
int doc_pack(Doc& d, const std::string& folder, const std::string& name);
// Returns the presets on the shelf, one per line, as
// "name\tpath\tlabel\tpicture". They are the
// *.motolii files in the presets folders of the library and of the user (see
// doc_folders), listed the same way as the effects, followed by the files in
// the elements folders. The name is the file's name and the picture is the .png
// beside it, or empty. The label is "Look" for a preset and "Element" for an
// element, as in Alight Motion's My Elements (see doc_element_keep).
std::string doc_preset_names();
// Saves the layer, with everything it holds, as an element named `name` in the
// user's elements folder, replacing a file of that name. Compare Alight
// Motion's Save to My Elements and AbsentMotion's saveToMyElements
// (ElementActions.kt). Returns false and sets d.error on failure.
bool doc_element_keep(Doc& d, int layer, const std::string& name);
// Puts the element file at `path` into the project at time `now` as the newest
// layer, at the middle of the stage, linked to its file through the `element`
// value in the form a preset uses for file names. AbsentMotion's addElement
// does the same: an embedScene at the centre of the scene with its link
// (ElementActions.kt). One undo step. Returns the new layer's number, or 0 on
// failure.
int doc_element_add(Doc& d, const char* path, double now);
// Updates every layer put in by an element whose file was written after it was
// put in. AbsentMotion's ProjectStore.kt withLinkedElements does the same by
// replacing a linked embedScene's scene with the element's current one. What
// the element held is created anew from the file. The element layer itself
// keeps its own values, where it lies and when it begins, and each text whose
// words the user changed since is given them again. One undo step for each
// element. Returns the number of elements updated.
int doc_elements_follow(Doc& d);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_PRESETS_H_

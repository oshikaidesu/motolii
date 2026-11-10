#ifndef MOTOLII_DOCUMENT_UNDO_H_
#define MOTOLII_DOCUMENT_UNDO_H_

// Opens a project file, upgrades older files, and records each change to the
// project as one undo step that can be undone and redone.

#include <sqlite3.h>

#include <string>

#include "document/kinds.h"
#include "stage/render/render_stage.h"

// Upgrades the database `schema` of `file` from the old table names to the
// current ones (layer, keyframe, easing, undo_step), as described in section 3
// of docs/design/renamed_words.md. It uses SQLite's ALTER TABLE ... RENAME
// (https://sqlite.org/lang_altertable.html) and records the version in the file
// header with PRAGMA user_version
// (https://sqlite.org/pragma.html#pragma_user_version).
// The undo steps stored in the file are cut off. Their changesets name the old
// tables, and SQLite applies a changeset for a table that no longer exists to
// nothing and still reports success
// (https://sqlite.org/session/sqlite3changeset_apply.html). Only their
// changesets are cleared. Their times are kept for doc_edited. `schema` is
// "main", or "preset" for an attached preset file. A file with user_version 0
// and no `fact` table is new and is only given version 1. A file with a newer
// version is refused. Returns false with the reason in `why` on failure.
bool doc_upgrade(sqlite3* file, const std::string& schema, std::string& why);
// Opens the project file at `path`, creating it if it is not there, upgrades it
// if needed, and attaches it to the stage `s`. Returns nullptr if the file
// cannot be opened or is not a project.
Doc* doc_open(Stage& s, const char* path);

// Begins an undo step. Calls nest. Only the outermost call opens the SQLite
// transaction and starts recording changes to the keyframe and easing tables.
// Every call must be matched by doc_acted. All changes made in between become
// one undo step.
void doc_act(Doc& d);
// Ends an undo step begun by doc_act. When the outermost call ends, the
// recorded changes are stored as one undo step and the transaction is
// committed, or rolled back if any change failed. Returns false if the step was
// rolled back.
bool doc_acted(Doc& d);
// Applies one SQL change `change` to the project. The string was allocated by
// SQLite and is freed here. It is an undo step by itself unless it is made
// within another step. The stage shows the result at once. If the stage cannot
// show it, the change is not made, and neither is any other change of the same
// step. Returns true on success. On failure d.error says why. later: a
// keyframe, whose act need not show it before the act ends.
bool doc_change(Doc& d, char* change, bool later = false);

// Returns how long the project has been worked on, in seconds, like Alight
// Motion's Total Edit Time. It is computed from the times at which the undo
// steps were made. The gap from one step to the next counts if it is under 15
// minutes, and a longer gap is a break. This follows WakaTime's way of counting
// time at work from its heartbeats, whose keystroke timeout is 15 minutes by
// default.
double doc_edited(Doc& d);
// Undoes the last undo step if `back` is true, otherwise redoes the last undone
// step. Returns false with d.error set if there is none or if the step no
// longer fits the project.
bool doc_undo_step(Doc& d, bool back);
// Returns the easing that runs from the keyframe at time `at` to the next
// keyframe, in one form: the name of a built-in kind as the table writes it,
// with all its numbers, however the easing was written. Returns "" if the
// property has no keyframe at that time.
std::string doc_easing_of(Doc& d, int layer, const char* name, double at);

#endif  // MOTOLII_DOCUMENT_UNDO_H_

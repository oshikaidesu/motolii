#ifndef MOTOLII_DOCUMENT_MARKS_H_
#define MOTOLII_DOCUMENT_MARKS_H_

// The project's length, work area, marks, guides, window settings and stage
// size.

#include <sqlite3.h>

#include <string>

#include "document/kinds.h"

// Returns how long the project is, in seconds: to the end of what ends last. A
// layer with no duration plays once through itself. Returns 8 if nothing in the
// project ends.
double doc_seconds(Doc& d);

// The work area is the stretch of the project that is played round and exported
// as a video, as in After Effects. If it is not set, it is all of the project.
// Marks are named times of the project, like After Effects' composition
// markers. Both are keyframes of layer 0, the stage itself, and every change to
// them is an undo step.

// Returns the work area through from and to, in seconds, clamped to the
// project.
void doc_work(Doc& d, double* from, double* to);
// Sets the work area. Fails unless 0 <= from, from < to and to <= 1000000
// seconds.
bool doc_work_is(Doc& d, double from, double to);
// Sets the mark at a time to a name, or removes the mark and its color if word
// is empty. Fails if the time is outside 0 to 1000000 seconds or the name is
// more than one line.
bool doc_mark(Doc& d, double at, const char* word);
// Sets a mark's color to one of the sixteen label colors, 1 to 16, or 0 for
// none, as Premiere Pro's, DaVinci Resolve's and CapCut's markers have one, so
// that a cut and a hit can be told apart. The color is a keyframe beside the
// mark's name at its time. Fails if there is no mark at that time.
bool doc_mark_colour(Doc& d, double at, int colour);
// Adds or removes a guide: a line across the image at a place, in points of it,
// like After Effects' composition guides. Axis x is an upright line that far
// from the left, and axis y is a level line that far from the top. Guides are
// keyframes of the stage, and a change to them is an undo step.
bool doc_guide(Doc& d, const char* axis, double at, bool on);
// Returns the guides, one line each: x or y, a space, and where.
std::string doc_guides(Doc& d);
// Returns the mark colors, one line each in time order: the time, a space, and
// the color.
std::string doc_mark_colours(Doc& d);
// The window's own choices, kept with the project. They are not undo steps,
// because their table is not one that undo records. They hold the colors and
// fonts a new layer comes in, as a PowerPoint file keeps its theme's colors and
// fonts. A word of "" removes a setting. doc_settings returns one line each:
// the name, a space, and the word.
bool doc_setting(Doc& d, const char* name, const char* word);
std::string doc_settings(Doc& d);
// Returns the marks, one line each in time order: the time, a space, and the
// name.
std::string doc_marks(Doc& d);

// A project's own stage size: how many points wide and high it is. These are
// keyframes of layer 0, the stage itself. They are not undo steps: a stage is
// opened at a size, so a new size takes effect when the project is next opened.
// doc_size reads the size before a stage is opened for the project. It returns
// false if the project does not specify, or if the file is not there yet.
bool doc_size(const char* path, int* wide, int* high);
// doc_size_words returns the SQL that sets the size, or nullptr if a stage
// cannot be that size. A size must be even and from 16 to 8192. doc_size_is
// sets the size that a new project was first opened at. It is not an undo step,
// because there is nothing before it.
char* doc_size_words(int wide, int high);
bool doc_size_is(sqlite3* file, int wide, int high);

#endif  // MOTOLII_DOCUMENT_MARKS_H_

#ifndef MOTOLII_ENTRY_WINDOW_H_
#define MOTOLII_ENTRY_WINDOW_H_
// The window's side of the C API: opening and closing a document, the strings
// calls answer with, and the live side of the window, which is the stage's
// frame, the preview, selection, playback and the timing report.
#include <string>

#include "document/kinds.h"
#include "entry/motolii.h"

// A string a call answers with. It is kept until the same thread asks again, so
// each caller has its own: the render thread, the window, and a question on
// another isolate. motolii_cache keeps its runs in the same way. One string
// shared by all was overwritten while another caller still read it.
std::string& said_word();
// Returns 1 if ok. Otherwise sets the error text to otherwise, if given, and
// returns 0.
int checked(Motolii* m, bool ok, const char* otherwise = nullptr);
// Clears the error text and returns the document.
Doc& doc(Motolii* m);
// Returns done, the result of a call that changes the document. If the call was
// refused while an act is open, the act is marked failed so it is not made.
// This holds at every entry point. For example, a number out of its range is
// refused before anything is changed.
int changes(Motolii* m, int done);
// Opens the stage's live output if it is not open yet. Returns 1 if it is open.
int live_is(Motolii* m);
// Sets the selected layer and the layer under the pointer, and asks for a
// redraw. Returns 1.
int pick_is(Motolii* m, int layer, int hover);
// Sets the size of the preview in pixels, its offset x and y, its scale and its
// point value. Makes its output again when the size changes. A side under 16
// pixels or a scale that is not positive turns the preview off. Returns 1 if
// the preview's output exists, otherwise 0.
int desk_is(Motolii* m, int w, int h, double x, double y, double scale,
            double point);
// Sets the camera that the window works through. word holds three numbers. If
// it does not, the document's own camera is used. Returns 1.
int view_camera_is(Motolii* m, const char* word);

#endif  // MOTOLII_ENTRY_WINDOW_H_

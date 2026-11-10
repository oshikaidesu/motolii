#ifndef MOTOLII_DOCUMENT_ADAPTER_H_
#define MOTOLII_DOCUMENT_ADAPTER_H_

// adapter.h: imports code found on the net into the project.
// The code (a shader, a p5.js sketch, a three.js scene, Hydra code, or a file of any of them) is
// read as what it is, stored unchanged in the Program shelf folder so that it also appears on the
// shelf, and placed on the canvas. A shader that reads an image becomes an effect on the selected
// layer. A shader that makes its own pixels becomes a layer that fills the canvas. A p5.js sketch
// becomes an image layer, and a three.js scene becomes solid layers in 3D.

#include <string>

#include "document/kinds.h"

// Imports code from `said`, which is a file path, a link to a supported site, or the code itself,
// and places it on the canvas as described at the top of this file. `picked` is the selected layer,
// or 0 for none. Returns the layer that now shows the code, or 0 with d.error set. The whole import
// is one undo step.
int doc_door(Doc& d, const std::string& said, int picked);
// Called when a program file on the shelf is saved. Updates what was made from the file at once,
// instead of waiting for the operating system's file watcher to notify the app. Returns the reason
// the code cannot run, or an empty string when it runs. The shelf and the watcher both report one
// save, so this may be called twice for it; the work is done once, decided by the file's
// modification time.
std::string doc_code_saved(Doc& d, const std::string& file);

#endif  // MOTOLII_DOCUMENT_ADAPTER_H_

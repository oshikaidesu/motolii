#ifndef MOTOLII_DOCUMENT_SCRIPTS_SCRIPTS_H_
#define MOTOLII_DOCUMENT_SCRIPTS_SCRIPTS_H_
// A layer's scripts and the parameters they declare as properties of the layer.

#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "document/kinds.h"

// A script attached to a layer, see
// engine/community/script_runner/script_runner.h. The
// parameters declared in the head of the file become properties of the layer,
// named js_ followed by the name of the parameter. The code is compiled once
// per file and again when the file changes, so that a script that is written
// and saved shows at once.
struct DocScript {
  // Modification time of the file when it was last loaded. -1 before the first
  // load.
  long long stamp = -1;
  // The value of files_changed() when the file was last checked. The file is
  // checked again only after that value has changed.
  int seen = -1;
  // True for Filament's own settings file. It is read and applied to the view
  // of the stage instead of being drawn, see
  // engine/stage/effects/viewer_settings.h.
  bool viewer = false;
  // The id of the AbsentMotion motion effect, for a layer that AbsentMotion's
  // C++ code moves, see engine/community/absent_motion/absent_motion.h. Empty
  // for other scripts.
  std::string absent;
  // The parameters declared by the file.
  std::vector<ScriptParameter> parameters;
  // The property name of each parameter, in the same order as `parameters`.
  std::vector<std::string> names;
  // The description of each property, in the same order.
  std::vector<DocValue> values;
  // How the app shows each property, in the same order.
  std::vector<DocShown> shown;
  // The compiled script. Null when the file is read but not run.
  std::unique_ptr<Script> run;
  // True when the text of the script mentions "opacity". Its copies may then
  // each have a different opacity, so they are drawn one by one rather than all
  // at once.
  bool clears = false;
  // Whether the script is a relation that defines force() and no relate(), see
  // engine/document/evaluate/world.h. -1 means not asked yet.
  int pushes = -1;
};
// Each document has its own scripts. A script runs in a QuickJS runtime of its
// own, and "inside a given runtime, no multi-threading is supported", QuickJS
// documentation, 3.4.1 Runtime and contexts. Two documents, such as the app's
// and a preview of a shelf recipe, are used by different threads, and each runs
// its own scripts under its document's lock. State of the file of a flat
// sketch: `seen` is when it was last looked at, `whole` when it last ran, and
// `ready` is the result of that run.
struct DocSketch {
  long long seen = 0, whole = 0, saved = 0;
  std::shared_ptr<Script> ready;
};
// All the script state of one document. `all` maps file names to scripts.
// `made` counts how many times a script was loaded again. `why` maps a file to
// the error of its new code when that code does not run and the earlier version
// is kept.
struct DocScripts {
  std::map<std::string, DocScript> all;
  int made = 0, told = 0;
  std::map<std::string, DocSketch> sketches;
  std::map<std::string, std::string> why;
};
// Returns the script state of the document, creating it on first use.
inline DocScripts& doc_scripts_kept(Doc& d) {
  if (!d.scripts) d.scripts = std::make_shared<DocScripts>();
  return *d.scripts;
}
// Returns the scripts of the document by file name.
inline std::map<std::string, DocScript>& doc_scripts(Doc& d) {
  return doc_scripts_kept(d).all;
}
// Returns the counter of script loads. Values derived from scripts are worked
// out again when it changes.
inline int& doc_scripts_made(Doc& d) { return doc_scripts_kept(d).made; }
// Returns how the app shows the property `name`, looking at the built-in
// properties first and then at the parameters declared by scripts. Returns null
// for an unknown name.
const DocShown* doc_shown_of(Doc& d, const char* name);
// Returns the property name for a parameter of a full-screen effect. The name
// of the file comes before the name of the parameter, because several such
// effects can lie on one stage and two can have a parameter of the same name.
// The gamma of Posterize and the gamma of Boxinator are not one value. A
// property name is one word, so an ISF file named "Frosted Glass" gives
// Frosted_Glass.
std::string doc_screen_parameter(const std::string& file,
                                 const std::string& parameter);
// Returns the script loaded from `file`, loading it again when the file has
// changed. Returns null when `file` is empty, "none" or a MIDI file, or when it
// cannot be read. When `runs` is false the code is not compiled. The file is
// checked for changes only once for each value of files_changed().
DocScript* doc_script_of(Doc& d, const std::string& file, bool runs = true);
// Sets d.exact for the lifetime of the object and restores the previous value
// afterwards.
struct DocExact {
  Doc& d;
  bool was;
  explicit DocExact(Doc& d) : d(d), was(std::exchange(d.exact, true)) {}
  ~DocExact() { d.exact = was; }
};
// Returns the scripts on a layer, in order. For a layer these are the file in
// its "script" value, which is one path and may contain spaces, then the files
// in its "fx" list, except ThorVG's own effects. For an image layer they also
// include the slots of an After Effects file, or the lines of a sketch that
// draw. For layer 0, the stage, these are the files in its "script" value, one
// over another.
std::vector<DocScript*> doc_scripts_on(Doc& d, int layer);
// Returns AbsentMotion's own motion effects on a layer, in order. They are the
// .am files in its fx list. Each has the value of its parameters at time `now`,
// under the names AbsentMotion reads them by. A point's x and y, and a colour's
// x to w, are separate properties and are joined into one parameter that holds
// numbers in turn. See shelves/effects/sources/from_absent.py.
std::vector<AbsentEffect> doc_absent_on(Doc& d, int layer, double now);
#endif  // MOTOLII_DOCUMENT_SCRIPTS_SCRIPTS_H_

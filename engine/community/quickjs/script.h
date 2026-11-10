#ifndef MOTOLII_COMMUNITY_QUICKJS_SCRIPT_H_
#define MOTOLII_COMMUNITY_QUICKJS_SCRIPT_H_

// The groundwork the script adapters build on: the types a script's parameters
// and copies are passed in (ScriptParameter, ScriptCopy), and the helpers that
// read a script's header, find shelf files, mark a sketch's drawing lines and
// run anime.js's easings. Nothing here knows a dialect. What opens a script of
// any dialect is above the adapters, in community/script_runner/: Script in
// script_runner.h and script_parameters in script_parameters.h.
//
// A script declares its parameters in a header of // lines, one parameter per
// line, in the manner of AviUtl2:
//   // --track@count:Count,1,5000,800,1      A number:
//   name:label,lowest,highest,default,step.
//   // --check@spin:Spin,1                    On or off, 1 or 0:
//   name:label,default.
//   // --select@way:Way,ring,grid,spiral      One of several words. The first
//   is the default.
//   // --group:Advanced                       Folds the parameters after it
//   under that name, until
//                                             a bare // --group line.
//   // --macro@Spread:Spread,0.5 -> StepX 0 0.6, ScatterX 0 2
// A macro is one parameter from 0 to 1, here with default 0.5. It drives other
// parameters. Each driven parameter equals its min + (max - min) x the macro.
// If min is above max, it runs the other way. This follows the Rack Macro
// Controls of Ableton Live 12, Map Mode, section 25.7.1 of its manual. On the
// layer's card the macro comes first and the parameters it drives are folded
// into Advanced, labeled "← Spread" after their names. The user can still set a
// driven parameter by hand. The macro then adds (max - min) x (macro - default)
// to the parameter's own value, just as an After Effects expression "value +
// ..." keeps the user's value. See doc_macro_adds in
// document/scripts/expressions.h.
//
// Instead of those header lines, the file may start with leva's object form,
// for example
//   const knobs = { distance: 2, Advanced: folder({ ... }) }
// See script_leva.h.

#include <iosfwd>
#include <string>
#include <vector>

// One parameter declared in a script's header.
struct ScriptParameter {
  // kind is one of track, check, select, sound or picture. A picture is an
  // effect's image read from another layer.
  std::string name, label, kind;
  // Range, default and step of a track or check. usual is the default.
  double low = 0, high = 1, usual = 0, step = 0;
  // The words of a select, separated by spaces. A sound has two: fft or wave,
  // then the count.
  std::string words;
  // The group from the header's // --group lines, shown as a fold on the card.
  // Empty if none.
  std::string group;
  // A parameter driven by a macro, with the range the macro sweeps it over.
  struct Turned {
    std::string name;
    double low, high;
  };
  // For a macro, the parameters it drives. A macro is a track from 0 to 1.
  std::vector<Turned> turns;
  // The macro that drives this parameter. Empty if none.
  std::string by;
};
// The placement and look of one copy, as returned by each(). colour is the
// copy's own color; -1 means the copy keeps the color of its solid.
struct ScriptCopy {
  double x = 0, y = 0, z = 0, size = 1, rotate = 0, rotate_x = 0, rotate_y = 0,
         opacity = 1, scale_x = 1, scale_y = 1, scale_z = 1, colour = -1;
};

// Returns the path of a shelf file that a project names where the file no
// longer is. The shelf folders have moved: first engine/effects/, then
// shelves/effects/<source>/. If file contains a
// "/" and does not exist, this looks in the shelf of the same kind for a file
// with the same name. The shelves/ folder is found beside engine/, as
// doc_folders finds it. Otherwise, or if no such file exists, file is returned
// unchanged.
std::string script_shelf_file(const std::string& file);
// Splits a space-separated list of files, such as an effect's list or the
// stage's. A word containing "/" is a path and may itself contain spaces, as in
// "Application Support" or an ISF effect's "Bad TV.fs". The path continues
// until a word ends in .wgsl, .fs, .js, .mjs, .json (Filament's own settings),
// .am (Alight Motion's own motion file), or names an AviUtl2 script
// (.anm2 or .obj2, with "#name" after an @ file's). Any other word stands
// alone. Each file goes through script_shelf_file.
std::vector<std::string> script_files(const std::string& word);

// Returns true if src is a relation that pushes layers: it defines force() and
// has no draw(). See document/evaluate/world.h.
inline bool script_pushes(const std::string& src) {
  return src.find("function force(") != std::string::npos &&
         src.find("function draw") == std::string::npos;
}
// Returns true if src is a p5.js sketch, written with setup() and draw(),
// rather than one of our scripts, whose code is each().
inline bool script_is_sketch(const std::string& src) {
  return src.find("function each") == std::string::npos &&
         (src.find("function draw") != std::string::npos ||
          src.find("function relate") != std::string::npos ||
          script_pushes(src) ||
          src.find("function setup") != std::string::npos ||
          src.find("createCanvas") != std::string::npos);
}
// Marks the calls in a sketch that draw. A for loop can make hundreds of shapes
// from one source line, and a count may grow, but the line stays. Each drawing
// call is wrapped as
// __at(line, name), the way Processing's Tweak Mode rewrites a sketch's source
// to reach its numbers (java/src/processing/mode/java/tweak). Each such line
// becomes a parameter of the layer, named line_ plus its line number, that sets
// how strong that line's shapes are. So a sketch opens into a few rows, however
// many shapes it draws. If lines is not null, it receives the marked lines.
// Returns the rewritten source. A line of a sketch that draws, and the name of
// the drawing call on it.
struct SketchLine {
  int line;
  std::string what;
};
std::string sketch_marked(const std::string& src,
                          std::vector<SketchLine>* lines);
// Returns the parameters declared by the header lines read from `from`, in the
// form described at the top of this file. Reading stops at the first line of
// code. A macro comes first, and each parameter it drives is labeled with it
// and folded into Advanced. A .wgsl effect and our own .js scripts declare
// their parameters this way; script_parameters, in
// community/script_runner/script_parameters.h, reads the other dialects and
// leaves the rest to this.
std::vector<ScriptParameter> script_header_parameters(std::istream& from);
// Sets default values for an effect's parameters where its own defaults show
// nothing on the image. Alight Motion's rule is that an effect is seen as it is
// first put on a layer; see the section on first values in
// docs/design/alight_motion_ui.md. This reads first.tsv beside file, with one
// line per value: file, parameter and value separated by tabs. The table is
// measured by fx_first.sh. Its values replace the parameters' defaults (usual).
// The author's file is not changed.
void script_first(const std::string& file,
                  std::vector<ScriptParameter>& parameters);

// Returns how far an anime.js ease (third_party/anime, MIT license) has
// progressed at u. Both u and the result are from 0 to 1. said is the ease as
// anime.js writes it, for example "outElastic(1, .3)", "spring({ bounce: .5
// })", "linear(0, '0.25 75%', 1)", "steps(4)" or "irregular(10, 1)". bundle is
// the path of the anime.js file. If said is not an ease, or anime.js is not
// found, returns u and sets *trouble to the reason.
double anime_ease(const std::string& bundle, const std::string& said, double u,
                  std::string* trouble);

#endif  // MOTOLII_COMMUNITY_QUICKJS_SCRIPT_H_

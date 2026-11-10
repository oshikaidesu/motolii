// Declares Script, which runs a JavaScript file that places copies of a layer, and the helpers
// that read a script's header and find shelf files.
//
// A script declares its parameters in a header of // lines, one parameter per line, in the
// manner of AviUtl2:
//   // --track@count:Count,1,5000,800,1      A number: name:label,lowest,highest,default,step.
//   // --check@spin:Spin,1                    On or off, 1 or 0: name:label,default.
//   // --select@way:Way,ring,grid,spiral      One of several words. The first is the default.
//   // --group:Advanced                       Folds the parameters after it under that name, until
//                                             a bare // --group line.
//   // --macro@Spread:Spread,0.5 -> StepX 0 0.6, ScatterX 0 2
// A macro is one parameter from 0 to 1, here with default 0.5. It drives other parameters.
// Each driven parameter equals its min + (max - min) x the macro. If min is above max, it runs
// the other way. This follows the Rack Macro Controls of Ableton Live 12, Map Mode, section
// 25.7.1 of its manual. On the layer's card the macro comes first and the parameters it drives
// are folded into Advanced, labeled "← Spread" after their names. The user can still set a
// driven parameter by hand. The macro then adds (max - min) x (macro - default) to the
// parameter's own value, just as an After Effects expression "value + ..." keeps the user's
// value. See doc_macro_adds in document/expressions.h.
//
// Instead of those header lines, the file may start with leva's object form, for example
//   const knobs = { distance: 2, Advanced: folder({ ... }) }
// See script_leva.h.
//
// The body defines where each copy of the layer is and how it looks:
//   function each(i, n, t, k) { return { x, y, z, size, rotate, rotate_x, rotate_y, opacity }; }
// Here i is the index of the copy out of n copies, t is the number of seconds since the layer
// began, and k holds the parameters. k also has duration, how long the layer lasts, and px,
// the size of one project pixel in stage units. This is how Cavalry's JavaScript Utility gives
// a Duplicator its points. QuickJS-ng runs the code.
//
// each() may take a fifth argument: each(i, n, t, k, at). at.x, at.y and at.z are the position
// the layer's script and the expressions before this one gave the copy, or 0 0 0 if there are
// none. After Effects gives an expression the same thing as `value`. What each() returns is
// added on top of that position. See document/expressions.h.
//
// A script may hold an After Effects expression as it was posted: AE.compile(`...`) once, then
// AE.run(f, ...) in each(). The expression is compiled once, not every frame. See ae_expr.h.
#pragma once
#include <atomic>
#include <map>
#include <memory>
#include <cstring>
#include <dlfcn.h>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

#include "shelf/shelf_folders.h"

// One parameter declared in a script's header.
struct ScriptParameter {
    // kind is one of track, check, select, sound or picture. A picture is an effect's image read
    // from another layer.
    std::string name, label, kind;
    // Range, default and step of a track or check. usual is the default.
    double low = 0, high = 1, usual = 0, step = 0;
    // The words of a select, separated by spaces. A sound has two: fft or wave, then the count.
    std::string words;
    // The group from the header's // --group lines, shown as a fold on the card. Empty if none.
    std::string group;
    // A parameter driven by a macro, with the range the macro sweeps it over.
    struct Turned { std::string name; double low, high; };
    // For a macro, the parameters it drives. A macro is a track from 0 to 1.
    std::vector<Turned> turns;
    // The macro that drives this parameter. Empty if none.
    std::string by;
};
// The placement and look of one copy, as returned by each(). colour is the copy's own color;
// -1 means the copy keeps the color of its solid.
struct ScriptCopy { double x = 0, y = 0, z = 0, size = 1, rotate = 0, rotate_x = 0, rotate_y = 0, opacity = 1, scale_x = 1, scale_y = 1, scale_z = 1, colour = -1; };

// Returns the path of a shelf file that a project names where the file no longer is. The shelf
// folders have moved: first engine/effects/, then shelves/effects/<source>/. If file contains a
// "/" and does not exist, this looks in the shelf of the same kind for a file with the same
// name. The shelves/ folder is found beside engine/, as doc_folders finds it. Otherwise, or if
// no such file exists, file is returned unchanged.
inline std::string script_shelf_file(const std::string& file) {
    std::error_code wrong;
    if (file.find('/') == std::string::npos || std::filesystem::exists(file, wrong)) return file;
    // For each shelf kind, a map from file name to full path. Filled on first use.
    static std::map<std::string, std::map<std::string, std::string>> by;
    for (std::filesystem::path p = std::filesystem::path(file).parent_path(); !p.empty() && p != p.parent_path(); p = p.parent_path()) {
        const std::string kind = p.filename().string();
        if (kind != "effects" && kind != "create" && kind != "relations" && kind != "expressions" && kind != "solids" && kind != "looks" && kind != "recipes" && kind != "animators") continue;
        // A project saved before the shelves were renamed names the old folders: recipes is now
        // create and animators is now expressions.
        const std::string now = kind == "recipes" ? "create" : kind == "animators" ? "expressions" : kind;
        if (!by.count(now)) {
            Dl_info lib{};
            dladdr((const void*)&script_shelf_file, &lib);
            const auto shelf = std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".", wrong).parent_path().parent_path().parent_path() / "shelves" / now;
            auto& names = by[now];
            for (const auto& e : std::filesystem::recursive_directory_iterator(shelf, wrong)) names.emplace(e.path().filename().string(), e.path().string());
        }
        const auto at = by[now].find(std::filesystem::path(file).filename().string());
        return at == by[now].end() ? file : at->second;
    }
    return file;
}
// Splits a space-separated list of files, such as an effect's list or the stage's. A word
// containing "/" is a path and may itself contain spaces, as in "Application Support" or an ISF
// effect's "Bad TV.fs". The path continues until a word ends in .wgsl, .fs, .js, .mjs, .json
// (Filament's own settings), .am (Alight Motion's own motion file), or names an AviUtl2 script
// (.anm2 or .obj2, with "#name" after an @ file's). Any other word stands alone. Each file goes
// through script_shelf_file.
inline std::vector<std::string> script_files(const std::string& word) {
    std::vector<std::string> all;
    std::istringstream each(word);
    const auto ends = [](const std::string& w) { if (w.find(".anm2") != std::string::npos || w.find(".obj2") != std::string::npos) return true; for (const char* e : {".wgsl", ".fs", ".js", ".mjs", ".json", ".am"}) if (w.size() >= strlen(e) && w.compare(w.size() - strlen(e), std::string::npos, e) == 0) return true; return false; };
    for (std::string w; each >> w;) {
        if (!all.empty() && all.back().find('/') != std::string::npos && !ends(all.back())) all.back() += " " + w;
        else all.push_back(w);
    }
    for (std::string& f : all) f = script_shelf_file(f);
    return all;
}

// Returns true if src is a relation that pushes layers: it defines force() and has no draw().
// See document/world.h.
inline bool script_pushes(const std::string& src) { return src.find("function force(") != std::string::npos && src.find("function draw") == std::string::npos; }
// Returns true if src is a p5.js sketch, written with setup() and draw(), rather than one of
// our scripts, whose code is each().
inline bool script_is_sketch(const std::string& src) { return src.find("function each") == std::string::npos && (src.find("function draw") != std::string::npos || src.find("function relate") != std::string::npos || script_pushes(src) || src.find("function setup") != std::string::npos || src.find("createCanvas") != std::string::npos); }
// Marks the calls in a sketch that draw. A for loop can make hundreds of shapes from one source
// line, and a count may grow, but the line stays. Each drawing call is wrapped as
// __at(line, name), the way Processing's Tweak Mode rewrites a sketch's source to reach its
// numbers (java/src/processing/mode/java/tweak). Each such line becomes a parameter of the
// layer, named line_ plus its line number, that sets how strong that line's shapes are. So a
// sketch opens into a few rows, however many shapes it draws. If lines is not null, it receives
// the marked lines. Returns the rewritten source.
// A line of a sketch that draws, and the name of the drawing call on it.
struct SketchLine { int line; std::string what; };
std::string sketch_marked(const std::string& src, std::vector<SketchLine>* lines);
// Returns the parameters a file declares. They are read from its header; for a sketch they
// are its lines that draw. Returns an empty list if there are none or the file cannot be read.
std::vector<ScriptParameter> script_parameters(const std::string& file);
// Sets default values for an effect's parameters where its own defaults show nothing on the
// image. Alight Motion's rule is that an effect is seen as it is first put on a layer; see the
// section on first values in docs/internal/reports/alight_motion/alight_ui.md. This reads
// first.tsv beside file, with one line per value: file, parameter and value separated by tabs.
// The table is measured by fx_first.sh. Its values replace the parameters' defaults (usual).
// The author's file is not changed.
void script_first(const std::string& file, std::vector<ScriptParameter>& parameters);

// Returns how far an anime.js ease (third_party/anime, MIT license) has progressed at u. Both u
// and the result are from 0 to 1. said is the ease as anime.js writes it, for example
// "outElastic(1, .3)", "spring({ bounce: .5 })", "linear(0, '0.25 75%', 1)", "steps(4)" or
// "irregular(10, 1)". bundle is the path of the anime.js file. If said is not an ease, or
// anime.js is not found, returns u and sets *trouble to the reason.
double anime_ease(const std::string& bundle, const std::string& said, double u, std::string* trouble);

// Runs one JavaScript file with QuickJS-ng. The file is a script with an each() function, a
// Cavalry distribution that is run whole, or a p5.js sketch. The constructor runs the code once
// and keeps each().
class Script {
public:
    // Runs file. p5 is the path of p5.js, needed for a sketch; see p5_stand.h. film is the video
    // that a sketch's createCapture and createVideo see.
    explicit Script(const std::string& file, const std::string& p5 = "", const std::string& film = "");
    ~Script();
    // Returns true if the file ran without error.
    bool ok() const;
    // Returns the text of the error, or an empty string if there was none.
    const std::string& trouble() const;
    // Returns true for a p5.js sketch, which p5.js itself runs; see p5_stand.h.
    bool sketch() const;
    // Returns true if the script has its own each(), which is asked once per copy. Returns false
    // for a sketch and for a Cavalry distribution that is run whole.
    bool lays() const;
    // Returns how many copies the sketch draws at once.
    int most();
    // Returns the shape of the sketch's copies, as the word a solid uses.
    std::string shape();
    // Returns true if the sketch paints on a 2D canvas.
    bool flat();
    // Returns the width of the sketch's canvas.
    int width();
    // Returns the sketch's pixelDensity(): the number of canvas pixels per unit of width.
    float density();
    // Returns the height of the sketch's canvas.
    int height();
    // Evaluates js in the sketch and returns the result as a string.
    std::string said(const std::string& js);
    // Evaluates js in the sketch and returns the contents of __bytes that it leaves.
    std::vector<uint8_t> bytes(const std::string& js);
    // Evaluates js in the sketch and returns the Float64Array it answers with. Returns an empty
    // vector if the evaluation failed, which is reported once.
    std::vector<double> numbers(const std::string& js);
    // Returns what makes frame `frame` on a canvas holding frame `had`, which is the result of
    // __paints in p5_stand.h.
    std::vector<double> paints(int frame, int had, int pic = -1);
    // Returns the source lines of the sketch that draw, as sketch_marked reports them.
    std::vector<int> lines() const;
    // Returns n copies of the layer at time t, with the parameters as the project has them now.
    // numbers holds the numeric parameters, and words holds each select as the word it is set to.
    // For a script with each(), calls each() once per copy. The fifth argument is the placement
    // the copy has so far, taken from before, or 0 0 0 if before has no entry. For a file with no
    // each(), runs the whole file with its parameters as globals (n0, n1, ...), plus time and
    // frame. That run must give a Cavalry PointCloud whose points are in pixels. unit is the size
    // of one pixel in stage units.
    std::vector<ScriptCopy> copies(int n, double t, const std::map<std::string, double>& numbers, const std::map<std::string, std::string>& words, double unit, const std::vector<ScriptCopy>& before = {});
private:
    // Sets the parameters on the script's parameters object.
    void parameters(const std::map<std::string, double>& numbers, const std::map<std::string, std::string>& words);
    // Calls each() for copy i of n at time t, with the parameters as last set. at is where the
    // copy lies so far, passed as each()'s fifth argument.
    ScriptCopy ask(int i, int n, double t, const ScriptCopy& at);

    // State of the JavaScript runtime. Defined in script.cpp.
    struct Own;
    std::unique_ptr<Own> own;
};

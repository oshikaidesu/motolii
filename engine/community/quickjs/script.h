// A recipe as code: a JavaScript file whose head declares its parameters in AviUtl2's manner, one a line,
//   // --track@count:Count,1,5000,800,1      a number: name:label,lowest,highest,as it comes,step
//   // --check@spin:Spin,1                    on or off (1 or 0)
//   // --select@way:Way,ring,grid,spiral      one of some words, the first as it comes
//   // --group:Advanced                       the parameters after it folded away under that name, until a bare // --group
//   // --macro@Spread:Spread,0.5 -> StepX 0 0.6, ScatterX 0 2
//                                             one parameter, 0 to 1 (as it comes: 0.5), turning others: each is its min + (max - min) x
//                                             the macro, Min above Max the other way (Ableton's Rack Macro Controls, Live 12
//                                             manual 25.7.1 Map Mode). On its card it stands first; what it turns is folded into
//                                             Advanced, "← Spread" after its name, and may still be set by hand: the macro adds
//                                             to its own value what it turns away from where it comes, (max - min) x (macro -
//                                             as it comes), as an After Effects expression "value + ..." keeps the hand's value
//                                             (document/expressions.h doc_macro_adds)
// or, in place of those lines, leva's object form at its top, const knobs = { distance: 2, Advanced: folder({ ... }) } (script_leva.h);
// and whose body says, for each copy of the thing it is given to, where it is and how:
//   function each(i, n, t, k) { return { x, y, z, size, rotate, rotate_x, rotate_y, opacity }; }   // i of n copies, t seconds since the thing began, k the parameters (and k.duration: how long the thing lasts)
// (as Cavalry's JavaScript Utility gives a Duplicator its points). Behind the interop: QuickJS-ng (js_bench chose it).
// each() may take a fifth, each(i, n, t, k, at): at.x, at.y, at.z, where the layer's script and the expressions before this one lay this copy (none before: 0 0 0), as After Effects gives an expression `value`; what it returns is laid on top of that all the same (document/expressions.h).
// k also has duration and px (a pixel of the document, in the stage's units). A recipe may hold an After Effects expression
// as it is posted: AE.compile(`...`) once, AE.run(f, ...) in each() (ae_expr.h; read once, not every frame).
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

// How many times a watched file or folder was said to be written, put in or taken out (motolii_files_changed): the OS's
// own watch runs in the window (dart:io's, on FSEvents), none in here; what is made from files asks its file again only then.
static std::atomic<int>& files_changed() { static std::atomic<int> n{0}; return n; }

struct ScriptParameter {
    std::string name, label, kind;   // kind: track, check, select or picture (an effect's image read from another thing)
    double low = 0, high = 1, usual = 0, step = 0;
    std::string words;               // a select's words, with spaces between
    std::string group;               // the group it lies in, as AviUtl2's head says (// --group:Name … // --group): its card's fold ("" none)
    struct Turned { std::string name; double low, high; };
    std::vector<Turned> turns;       // a macro's (// --macro@): the parameters it turns and over what span; a macro is a track of 0 to 1
    std::string by;                  // the macro that turns this one ("" none)
};
struct ScriptCopy { double x = 0, y = 0, z = 0, size = 1, rotate = 0, rotate_x = 0, rotate_y = 0, opacity = 1, scale_x = 1, scale_y = 1, scale_z = 1, colour = -1; };   // (colour: a solid copy's own, red green blue; -1: as the solid is)

// The files a word names in turn, with spaces between (an effect's list, the stage's): a path (a word with a "/" in it) is one to
// its .wgsl, .fs, .js, .mjs, .json (Filament's own settings), .am (AbsentMotion's own motion) or AviUtl2 script (.anm2, .obj2, "#name" after an @ file's), spaces and all ("Application Support", an ISF effect's "Bad TV.fs"); any other word stands alone.
// A shelf file a document names where it no longer is (the shelves moved: engine/effects/, then shelves/effects/<source>/):
// the one of that name in that kind's shelf now (shelves/ beside engine/, as doc_folders finds it), read through.
inline std::string script_shelf_file(const std::string& file) {
    std::error_code wrong;
    if (file.find('/') == std::string::npos || std::filesystem::exists(file, wrong)) return file;
    static std::map<std::string, std::map<std::string, std::string>> by;   // (a kind's files by their name)
    for (std::filesystem::path p = std::filesystem::path(file).parent_path(); !p.empty() && p != p.parent_path(); p = p.parent_path()) {
        const std::string kind = p.filename().string();
        if (kind != "effects" && kind != "create" && kind != "relations" && kind != "expressions" && kind != "solids" && kind != "looks" && kind != "recipes" && kind != "animators") continue;
        const std::string now = kind == "recipes" ? "create" : kind == "animators" ? "expressions" : kind;   // (a document saved before 2026-11-09 names the shelf's old folder)
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

// A file of p5.js's own two, setup() and draw(), as sketches are written: not a recipe of ours, whose code is each().
inline bool script_pushes(const std::string& src) { return src.find("function force(") != std::string::npos && src.find("function draw") == std::string::npos; }   // (a relation that pushes: document/world.h)
inline bool script_is_sketch(const std::string& src) { return src.find("function each") == std::string::npos && (src.find("function draw") != std::string::npos || src.find("function relate") != std::string::npos || script_pushes(src) || src.find("function setup") != std::string::npos || src.find("createCanvas") != std::string::npos); }
// The lines of a sketch that draw: a for makes hundreds from one line and a count may grow, the line stays. Each is told
// to the run as it comes, __L (as Processing's Tweak Mode rewrites a sketch's source to reach its numbers,
// java/src/processing/mode/java/tweak), and is a parameter of the thing, how strong that line's shapes are, named line_ and its
// number: so a sketch is opened into few rows, however many it draws. Returns the source so told.
struct SketchLine { int line; std::string what; };
std::string sketch_marked(const std::string& src, std::vector<SketchLine>* lines);
// The parameters a file declares (read from its head, a sketch's its lines that draw; empty if it has none or cannot be read).
std::vector<ScriptParameter> script_parameters(const std::string& file);
// The values an effect comes with where its own show nothing on a picture (Alight Motion's rule: an effect is seen as it
// is put on, docs/internal/reports/alight_motion/alight_ui.md "最初の値"): first.tsv beside it, "file<TAB>parameter<TAB>value" a line, measured by
// fx_first.sh, laid over its parameters' usual values. The author's file is left as it is.
void script_first(const std::string& file, std::vector<ScriptParameter>& parameters);

// How far an ease of anime.js (third_party/anime, MIT) has gone at u, 0 to 1: `said` as anime.js says it ("outElastic(1, .3)",
// "spring({ bounce: .5 })", "linear(0, '0.25 75%', 1)", "steps(4)", "irregular(10, 1)"); `bundle` is where its file is.
// Not an ease, or anime.js not there: u, and `trouble` says why.
double anime_ease(const std::string& bundle, const std::string& said, double u, std::string* trouble);

class Script {
public:
    explicit Script(const std::string& file, const std::string& p5 = "", const std::string& film = "");   // (film: what a sketch's createCapture and createVideo see)   // made once a file: its code run, its each() kept (p5: where p5.js is, for a sketch: p5_stand.h)
    ~Script();
    bool ok() const;
    const std::string& trouble() const;
    bool sketch() const;       // a p5.js sketch, run by p5.js itself (p5_stand.h)
    bool lays() const;         // an expression: it has its own each(), each copy asked in turn (not a sketch, not a Canvalry distribution run whole)
    int most();                // how many copies it draws at once
    std::string shape();       // and of what shape, as a solid's word
    bool flat();               // a sketch that paints on a 2D canvas
    int width();               // its canvas
    float density();   // (what pixelDensity() says: its canvas has this many pixels to each of its width)
    int height();
    std::string said(const std::string& js);   // what the sketch says to that, as words
    std::vector<uint8_t> bytes(const std::string& js);   // what it leaves in __bytes on being told that
    std::vector<double> numbers(const std::string& js);   // what it answers to that, a Float64Array (empty: it failed, and says so once)
    std::vector<double> paints(int frame, int had, int pic = -1);
    std::vector<int> lines() const;   // (a sketch's lines that draw, as sketch_marked says)   // what makes that frame on a canvas holding the frame `had` (p5_stand.h's __paints)
    // Every copy at once, the parameters as the document says them now (a select by the word it is): each() for each (its
    // fifth, where the copy lies so far, from `before`: none, 0 0 0), or, for a file with no each(), the whole file run with its parameters as globals
    // (n0, n1...), time and frame, giving a Canvalry PointCloud whose points are in pixels (`unit` stage units a pixel).
    std::vector<ScriptCopy> copies(int n, double t, const std::map<std::string, double>& numbers, const std::map<std::string, std::string>& words, double unit, const std::vector<ScriptCopy>& before = {});
private:
    void parameters(const std::map<std::string, double>& numbers, const std::map<std::string, std::string>& words);   // (told the script's parameters object)
    ScriptCopy ask(int i, int n, double t, const ScriptCopy& at);   // (each() with the parameters as last told)

    struct Own;
    std::unique_ptr<Own> own;
};

// doc_scripts.h: part of doc.h (a thing's scripts, their knobs as its values). Read only through doc.h.
// A thing's script (script.h): the knobs its file's head declares, as values of the thing named js_ and the knob's name,
// and its code, made once a file and again when the file changes (a script written and saved shows at once).
struct DocScript {
    long long stamp = -1;
    int seen = -1;   // (files_changed when the file was last asked whether it changed: asked again only after another)
    bool viewer = false;   // (Filament's own settings file: read and laid on the stage's view, not drawn: viewer_settings.h)
    std::string absent;    // (AbsentMotion's own motion effect, its id: the thing moved by AbsentMotion's C++, absent_motion.h)
    std::vector<ScriptKnob> knobs;
    std::vector<std::string> names;
    std::vector<DocValue> values;
    std::vector<DocShown> shown;
    std::unique_ptr<Script> run;
    bool clears = false;   // (its copies may each be as clear as it says: its text says opacity; drawn each of its own, not in one go)
    int pushes = -1;   // (a relation with force() and no relate(): doc_world.h; -1 not asked yet)
};
// Each document its own: a script runs in a QuickJS runtime of its own, and "inside a given runtime, no
// multi-threading is supported" (QuickJS's documentation, 3.4.1 Runtime and contexts): two documents' hands (the
// window's and the recipes' previews) each run theirs, under their document's lock.
struct DocSketch { long long seen = 0, whole = 0, saved = 0; std::shared_ptr<Script> ready; };   // (a flat sketch's file: when it was last looked at, when it last ran, and that run)
struct DocScripts { std::map<std::string, DocScript> all; int made = 0, told = 0; std::map<std::string, DocSketch> sketches; std::map<std::string, std::string> why; };   // (why: a file's code as it does not run, what it was before left standing)
static DocScripts& doc_scripts_kept(Doc& d) { if (!d.scripts) d.scripts = std::make_shared<DocScripts>(); return *d.scripts; }
static std::map<std::string, DocScript>& doc_scripts(Doc& d) { return doc_scripts_kept(d).all; }
static int& doc_scripts_made(Doc& d) { return doc_scripts_kept(d).made; }
static const DocShown* doc_shown_of(Doc& d, const char* name) {
    for (const DocShown& one : doc_shown) if (!strcmp(one.name, name)) return &one;
    for (const auto& [file, script] : doc_scripts(d))
        for (const DocShown& one : script.shown) if (!strcmp(one.name, name)) return &one;
    return nullptr;
}
// A whole-screen effect's knob in the document: its file's name before the knob's, as several lie on one stage and two
// may each have a knob of one name (Posterize's gamma and Boxinator's are not one value).
static std::string doc_screen_knob(const std::string& file, const std::string& knob) {   // (a value's name is one word: an ISF file's "Frosted Glass" says Frosted_Glass)
    std::string stem = std::filesystem::path(file).stem().string();
    for (char& c : stem) if (!(c >= '0' && c <= '9') && !(c >= 'A' && c <= 'Z') && !(c >= 'a' && c <= 'z') && c != '_') c = '_';   // (byte by byte, ASCII's alone: std::isalnum by the locale took a UTF-8 locale's é for 0xE9, half a letter left in the name (effect_tiles.dart _stem: ライ is ______))
    return "js_" + stem + "_" + knob;
}
// ThorVG's own effects by the value that puts each on, as a thing's list of effects names them, and their letters
// (DrawnFx::order).
static const char* const doc_thor_names[] = {"tint", "tritone", "shadow", "blur"};   // (a glow is not ThorVG's: Filament's bloom on the thing's own picture, doc_moment)
static char doc_thor_letter(const std::string& w) {
    for (int i = 0; i < 4; ++i) if (w == doc_thor_names[i]) return "trsb"[i];
    return 0;
}
static std::vector<std::filesystem::path> doc_folders(const char* folder); static std::filesystem::path doc_engine(const char* part);   // (doc_folders.h)
static DocScript* doc_script_of(Doc& d, const std::string& file, bool runs = true) {
    if (file.empty() || file == "none" || std::filesystem::path(file).extension() == ".mid") return nullptr;   // (a MIDI file's notes are copies, not a script: midi.h)
    DocScript& s = doc_scripts(d)[file];
    if (s.stamp >= 0 && s.seen == files_changed()) return &s;   // (first: what follows opens the file)
    const std::string ext = std::filesystem::path(file).extension().string();
    const bool screen = ext == ".wgsl" || ext == ".fs" || ext == ".mjs" || three_is(file) || solid_is(file) || aviutl_is(file);   // (a three.js effect: as an ISF one, three_isf.cpp; a solid's shape: its knobs named by it too, not run as a script, solid_three.cpp; an AviUtl2 script: run by its own Lua, aviutl_fx.h)
    const bool absent = ext == ".am";   // (AbsentMotion's own motion: its knobs in its head, the thing moved by AbsentMotion's C++: absent_motion.h)
    const bool lottie = ext == ".json" || ext == ".lot";   // (an After Effects file: its slots its knobs, lottie_slots.h)   // (.mjs: a PlayCanvas splat effect, its knobs its attributes: splatfx.h)   // (a whole-screen effect's knobs: named by the effect too)
    s.seen = files_changed();
    std::error_code wrong;
    const long long stamp = (long long)std::filesystem::last_write_time(aviutl_is(file) ? aviutl_path(file) : fx_source(file), wrong).time_since_epoch().count();
    if (wrong) return s.stamp >= 0 ? &s : nullptr;
    if (s.stamp != stamp) {
        DocScript was = std::move(s);
        s = DocScript{};
        s.viewer = lottie && viewer_is(file);
        s.stamp = stamp, s.seen = files_changed(), s.knobs = ext == ".mjs" ? SplatEffect(file).knobs() : s.viewer ? viewer_knobs(file) : lottie ? lottie_knobs(file) : script_knobs(screen ? isf_file(file) : fx_source(file));   // (an expression put on again, "repeater~2.js": its file's: doc_fx_duplicate)
        if (screen) script_first(file, s.knobs);   // (the values it comes with, where its own show nothing: fx_first.sh)
        std::erase_if(s.knobs, [](const ScriptKnob& k) { return k.kind == "picture" && k.name == "backdrop"; });   // (what is behind it is given, not chosen on its card: screen.h)
        doc_scripts_made(d)++;   // (what was worked out from the old one is forgotten)
        for (const ScriptKnob& k : s.knobs) s.names.push_back(screen || lottie || absent || fx_source(file) != file ? doc_screen_knob(file, k.name) : "js_" + k.name);   // (one put on again: its values its own, as an effect's)
        for (size_t i = 0; i < s.knobs.size(); ++i) {   // (the names are all made first: what points into them stays put)
            const ScriptKnob& k = s.knobs[i];
            const bool open = k.kind == "track";   // (an effect's number: its author's range is what is vouched for and what its knob shows, not all it may be, Houdini's range not strict (FloatParmTemplate minIsStrict); a low of 0 or more still a floor: doc_edit.h)
            // (a motion's knobs a camera's too: it takes AbsentMotion's motions, golf ㊴; its strength was refused on it)
            s.values.push_back(DocValue{s.names[i].c_str(), absent ? "film picture text shape solid stage camera" : "film picture text shape solid stage behaviour", k.kind == "select" ? 0.0 : k.low, k.kind == "select" ? 0.0 : k.high, k.kind == "track", k.kind == "select" ? k.words.c_str() : nullptr, open});
            s.shown.push_back(DocShown{s.names[i].c_str(), k.kind == "check" ? "onoff" : k.kind == "picture" || k.kind == "sound" ? "thing" : "", "", k.label.c_str(), k.low, k.high, k.group.empty() ? nullptr : k.group.c_str(), open});   // (its group: the card's fold, script.h)
        }
        if (absent) {   // (read, not run: which of AbsentMotion's its head says)
            std::ifstream in(file);
            for (std::string line; std::getline(in, line);) if (line.rfind("// --absent:", 0) == 0) s.absent = line.substr(12);
            return &s;
        }
        if (lottie) return &s;   // (read, not run)
        if (!screen && runs) s.run = std::make_unique<Script>(fx_source(file), (doc_engine("third_party/js/p5") / "p5.min.js").string());   // (a .wgsl or an ISF .fs is drawn, not run: screen.h)
        if (s.run && !s.run->ok() && was.run && was.run->ok()) {   // (code half typed: what ran stays, and says why)
            doc_scripts_kept(d).why[file] = d.trouble = s.run->trouble();
            s = std::move(was), s.stamp = stamp, s.seen = files_changed();
            return &s;
        }
        doc_scripts_kept(d).why.erase(file);
        { std::ifstream in(screen ? isf_file(file) : fx_source(file)); std::stringstream text; text << in.rdbuf(); s.clears = text.str().find("opacity") != std::string::npos; }
    }
    return &s;
}
// A thing's scripts: its one (a path may have spaces) and its own effects (paths with spaces between), or the stage's
// effects, one over another.
static std::string doc_word(Doc& d, int thing, const char* name);
struct DocExact { Doc& d; bool was; explicit DocExact(Doc& d) : d(d), was(std::exchange(d.exact, true)) {} ~DocExact() { d.exact = was; } };
static double doc_number(Doc& d, int thing, const char* name, double at, double otherwise);
static std::vector<DocScript*> doc_scripts_on(Doc& d, int thing) {
    const std::string said = doc_word(d, thing, "script");
    std::vector<DocScript*> all;
    if (thing != 0) {
        if (DocScript* sc = doc_script_of(d, said)) all.push_back(sc);
        for (const std::string& file : script_files(doc_word(d, thing, "fx"))) if (!doc_thor_letter(file)) if (DocScript* sc = doc_script_of(d, file)) all.push_back(sc);
        if (const std::string file = doc_word(d, thing, "file"); doc_word(d, thing, "kind") == "picture")   // (an After Effects file's slots, a sketch's lines that draw; a sketch is run by its picture, doc_match)
            if (const std::string ext = std::filesystem::path(file).extension().string(); ext == ".json" || ext == ".lot" || ext == ".js")
                if (DocScript* sc = doc_script_of(d, file, ext != ".js"); sc && !sc->knobs.empty()) all.push_back(sc);
        return all;
    }
    for (const std::string& file : script_files(said)) if (DocScript* sc = doc_script_of(d, file)) all.push_back(sc);
    return all;
}
static std::string doc_fx_title(const std::string& name);
static std::vector<std::string> doc_fx_list(Doc& d, int thing, bool off = false);
// AbsentMotion's own motion effects on a thing (.am files in its fx), in order, each its knobs' values now by the names
// AbsentMotion reads them by: a point's x and y and a colour's x to w one param of numbers in turn (effects/sources/from_absent.py).
static std::vector<AbsentEffect> doc_absent_on(Doc& d, int thing, double now) {
    std::vector<AbsentEffect> all;
    for (const std::string& file : doc_fx_list(d, thing))   // (those turned off left out)
        if (std::filesystem::path(file).extension() == ".am")
            if (DocScript* sc = doc_script_of(d, file); sc && !sc->absent.empty()) {
                AbsentEffect e{sc->absent, {}};
                for (size_t i = 0; i < sc->knobs.size(); ++i) {
                    std::string name = sc->knobs[i].name;
                    const size_t cut = name.rfind('_');
                    const bool part = cut != std::string::npos && cut + 2 == name.size() && std::string("xyzw").find(name[cut + 1]) != std::string::npos;
                    if (part) name = name.substr(0, cut);
                    const float v = (float)doc_number(d, thing, sc->names[i].c_str(), now, sc->knobs[i].usual);
                    if (part && !e.params.empty() && e.params.back().first == name) e.params.back().second.push_back(v);
                    else e.params.push_back({name, {v}});
                }
                all.push_back(e);
            }
    return all;
}

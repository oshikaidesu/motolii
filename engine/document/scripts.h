// A layer's scripts and the parameters they declare as properties of the layer. Included by doc.h;
// not self-contained.

// A script attached to a layer, see engine/community/quickjs/script.h. The parameters declared in
// the head of the file become properties of the layer, named js_ followed by the name of the
// parameter. The code is compiled once per file and again when the file changes, so that a script
// that is written and saved shows at once.
struct DocScript {
    // Modification time of the file when it was last loaded. -1 before the first load.
    long long stamp = -1;
    // The value of files_changed() when the file was last checked. The file is checked again only
    // after that value has changed.
    int seen = -1;
    // True for Filament's own settings file. It is read and applied to the view of the stage
    // instead of being drawn, see engine/stage/effects/viewer_settings.h.
    bool viewer = false;
    // The id of the AbsentMotion motion effect, for a layer that AbsentMotion's C++ code moves, see
    // engine/community/absent_motion/absent_motion.h. Empty for other scripts.
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
    // True when the text of the script mentions "opacity". Its copies may then each have a
    // different opacity, so they are drawn one by one rather than all at once.
    bool clears = false;
    // Whether the script is a relation that defines force() and no relate(), see
    // engine/document/world.h. -1 means not asked yet.
    int pushes = -1;
};
// Each document has its own scripts. A script runs in a QuickJS runtime of its own, and "inside a
// given runtime, no multi-threading is supported", QuickJS documentation, 3.4.1 Runtime and
// contexts. Two documents, such as the app's and a preview of a shelf recipe, are used by different
// threads, and each runs its own scripts under its document's lock.
// State of the file of a flat sketch: `seen` is when it was last looked at, `whole` when it last
// ran, and `ready` is the result of that run.
struct DocSketch { long long seen = 0, whole = 0, saved = 0; std::shared_ptr<Script> ready; };
// All the script state of one document. `all` maps file names to scripts. `made` counts how many
// times a script was loaded again. `why` maps a file to the error of its new code when that code
// does not run and the earlier version is kept.
struct DocScripts { std::map<std::string, DocScript> all; int made = 0, told = 0; std::map<std::string, DocSketch> sketches; std::map<std::string, std::string> why; };
// Returns the script state of the document, creating it on first use.
static DocScripts& doc_scripts_kept(Doc& d) { if (!d.scripts) d.scripts = std::make_shared<DocScripts>(); return *d.scripts; }
// Returns the scripts of the document by file name.
static std::map<std::string, DocScript>& doc_scripts(Doc& d) { return doc_scripts_kept(d).all; }
// Returns the counter of script loads. Values derived from scripts are worked out again when it
// changes.
static int& doc_scripts_made(Doc& d) { return doc_scripts_kept(d).made; }
// Returns how the app shows the property `name`, looking at the built-in properties first and then
// at the parameters declared by scripts. Returns null for an unknown name.
static const DocShown* doc_shown_of(Doc& d, const char* name) {
    for (const DocShown& one : doc_shown) if (!strcmp(one.name, name)) return &one;
    for (const auto& [file, script] : doc_scripts(d))
        for (const DocShown& one : script.shown) if (!strcmp(one.name, name)) return &one;
    return nullptr;
}
// Returns the property name for a parameter of a full-screen effect. The name of the file comes
// before the name of the parameter, because several such effects can lie on one stage and two can
// have a parameter of the same name. The gamma of Posterize and the gamma of Boxinator are not one
// value. A property name is one word, so an ISF file named "Frosted Glass" gives Frosted_Glass.
static std::string doc_screen_parameter(const std::string& file, const std::string& parameter) {
    std::string stem = std::filesystem::path(file).stem().string();
    // Replace byte by byte, ASCII letters and digits are kept. std::isalnum depends on the locale
    // and takes the byte of a UTF-8 character for a letter, which leaves half a letter in the name.
    // See _stem in app/lib/workspace/shelf/effect_tiles.dart.
    for (char& c : stem) if (!(c >= '0' && c <= '9') && !(c >= 'A' && c <= 'Z') && !(c >= 'a' && c <= 'z') && c != '_') c = '_';
    return "js_" + stem + "_" + parameter;
}
// Returns the script loaded from `file`, loading it again when the file has changed. Returns null
// when `file` is empty, "none" or a MIDI file, or when it cannot be read. When `runs` is false the
// code is not compiled. The file is checked for changes only once for each value of
// files_changed().
static DocScript* doc_script_of(Doc& d, const std::string& file, bool runs = true) {
    // The notes of a MIDI file are copies, not a script, see engine/media/midi_notes.h.
    if (file.empty() || file == "none" || std::filesystem::path(file).extension() == ".mid") return nullptr;
    DocScript& s = doc_scripts(d)[file];
    // Checked already. This must come first, because the code below opens the file.
    if (s.stamp >= 0 && s.seen == files_changed()) return &s;
    const std::string ext = std::filesystem::path(file).extension().string();
    // Files that are drawn as effects, or only named by their parameters, and not run as scripts.
    // These are WGSL and ISF shaders, three.js effects, see engine/community/three/three_isf.cpp,
    // solid shapes, see engine/community/three/solid_three.cpp, and AviUtl2 scripts, which AviUtl's
    // own Lua runs, see engine/community/aviutl/aviutl_fx.h. A .mjs file is a PlayCanvas splat
    // effect whose parameters are its attributes, see engine/community/playcanvas/splatfx.h.
    const bool screen = ext == ".wgsl" || ext == ".fs" || ext == ".mjs" || three_is(file) || solid_is(file) || aviutl_is(file);
    // AbsentMotion's own motion. Its parameters are in the head of the file, and AbsentMotion's C++
    // code moves the layer, see engine/community/absent_motion/absent_motion.h.
    const bool absent = ext == ".am";
    // An After Effects file. Its slots are its parameters, see
    // engine/community/after_effects/lottie_slots.h.
    const bool lottie = ext == ".json" || ext == ".lot";
    s.seen = files_changed();
    std::error_code wrong;
    const long long stamp = (long long)std::filesystem::last_write_time(aviutl_is(file) ? aviutl_path(file) : fx_source(file), wrong).time_since_epoch().count();
    // Keep the loaded script when the file can no longer be read.
    if (wrong) return s.stamp >= 0 ? &s : nullptr;
    if (s.stamp != stamp) {
        DocScript was = std::move(s);
        s = DocScript{};
        s.viewer = lottie && viewer_is(file);
        // A duplicated expression such as "repeater~2.js" reads its parameters from the original
        // file, see doc_fx_duplicate.
        s.stamp = stamp, s.seen = files_changed(), s.parameters = ext == ".mjs" ? SplatEffect(file).parameters() : s.viewer ? viewer_parameters(file) : lottie ? lottie_parameters(file) : script_parameters(screen ? isf_file(file) : fx_source(file));
        // Apply the values the effect comes with, where its own declarations show none, see
        // shelves/effects/sources/fx_first.sh.
        if (screen) script_first(file, s.parameters);
        // What is behind the effect is given, not chosen on its card, see
        // engine/stage/effects/screen_fx.h.
        std::erase_if(s.parameters, [](const ScriptParameter& k) { return k.kind == "picture" && k.name == "backdrop"; });
        // Everything worked out from the old version is forgotten.
        doc_scripts_made(d)++;
        // An effect, or a duplicate of one, names its properties with the file first, so that they
        // are its own.
        for (const ScriptParameter& k : s.parameters) s.names.push_back(screen || lottie || absent || fx_source(file) != file ? doc_screen_parameter(file, k.name) : "js_" + k.name);
        // All the names are created first, because the values below point into them and they must
        // not move.
        for (size_t i = 0; i < s.parameters.size(); ++i) {
            const ScriptParameter& k = s.parameters[i];
            // The range of a number parameter is its author's. It is what the parameter shows and
            // not a limit on what it may be, as in Houdini, where a range is not strict, see
            // FloatParmTemplate minIsStrict. A low bound of 0 or more is still a floor, see
            // engine/document/layer_edit.h.
            const bool open = k.kind == "track";
            // The last text is the layer kinds that the property applies to. A layer moved by
            // AbsentMotion also allows a camera.
            s.values.push_back(DocValue{s.names[i].c_str(), absent ? "video image text shape solid stage camera" : "video image text shape solid stage behaviour", k.kind == "select" ? 0.0 : k.low, k.kind == "select" ? 0.0 : k.high, k.kind == "track", k.kind == "select" ? k.words.c_str() : nullptr, open});
            // Check boxes show as on and off, and picture and sound parameters are chosen from
            // layers. The group names the fold of the card that holds the parameter, see
            // engine/community/quickjs/script.h.
            s.shown.push_back(DocShown{s.names[i].c_str(), k.kind == "check" ? "onoff" : k.kind == "picture" || k.kind == "sound" ? "thing" : "", "", k.label.c_str(), k.low, k.high, k.group.empty() ? nullptr : k.group.c_str(), open});
        }
        // An AbsentMotion file is read, not run. Its head says which motion it is.
        if (absent) {
            std::ifstream in(file);
            for (std::string line; std::getline(in, line);) if (line.rfind("// --absent:", 0) == 0) s.absent = line.substr(12);
            return &s;
        }
        // A Lottie file is read, not run.
        if (lottie) return &s;
        // A .wgsl or ISF .fs file is drawn, not run, see engine/stage/effects/screen_fx.h.
        if (!screen && runs) s.run = std::make_unique<Script>(fx_source(file), (doc_engine("third_party/js/p5") / "p5.min.js").string());
        // The new code does not compile but the old code ran. Keep the old script and record the
        // error, so that code that is half typed does not break the layer.
        if (s.run && !s.run->ok() && was.run && was.run->ok()) {
            doc_scripts_kept(d).why[file] = d.error = s.run->trouble();
            s = std::move(was), s.stamp = stamp, s.seen = files_changed();
            return &s;
        }
        doc_scripts_kept(d).why.erase(file);
        { std::ifstream in(screen ? isf_file(file) : fx_source(file)); std::stringstream text; text << in.rdbuf(); s.clears = text.str().find("opacity") != std::string::npos; }
    }
    return &s;
}
// Declared here; defined elsewhere in doc.h.
static std::string doc_word(Doc& d, int layer, const char* name);
// Sets d.exact for the lifetime of the object and restores the previous value afterwards.
struct DocExact { Doc& d; bool was; explicit DocExact(Doc& d) : d(d), was(std::exchange(d.exact, true)) {} ~DocExact() { d.exact = was; } };
// Declared here; defined elsewhere in doc.h.
static double doc_number(Doc& d, int layer, const char* name, double at, double otherwise);
// Returns the scripts on a layer, in order. For a layer these are the file in its "script" value,
// which is one path and may contain spaces, then the files in its "fx" list, except ThorVG's own
// effects. For an image layer they also include the slots of an After Effects file, or the lines of
// a sketch that draw. For layer 0, the stage, these are the files in its "script" value, one over
// another.
static std::vector<DocScript*> doc_scripts_on(Doc& d, int layer) {
    const std::string said = doc_word(d, layer, "script");
    std::vector<DocScript*> all;
    if (layer != 0) {
        if (DocScript* sc = doc_script_of(d, said)) all.push_back(sc);
        for (const std::string& file : script_files(doc_word(d, layer, "fx"))) if (!doc_thor_letter(file)) if (DocScript* sc = doc_script_of(d, file)) all.push_back(sc);
        // An image layer can be an After Effects file, which has slots, or a sketch, which has
        // lines that draw. The image layer runs a sketch itself, see doc_match, so a .js file is
        // not run here.
        if (const std::string file = doc_word(d, layer, "file"); doc_word(d, layer, "kind") == "image")
            if (const std::string ext = std::filesystem::path(file).extension().string(); ext == ".json" || ext == ".lot" || ext == ".js")
                if (DocScript* sc = doc_script_of(d, file, ext != ".js"); sc && !sc->parameters.empty()) all.push_back(sc);
        return all;
    }
    for (const std::string& file : script_files(said)) if (DocScript* sc = doc_script_of(d, file)) all.push_back(sc);
    return all;
}
// Declared here; defined elsewhere in doc.h.
static std::string doc_fx_title(const std::string& name);
static std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off = false);
// Returns AbsentMotion's own motion effects on a layer, in order. They are the .am files in its fx
// list. Each has the value of its parameters at time `now`, under the names AbsentMotion reads them
// by. A point's x and y, and a colour's x to w, are separate properties and are joined into one
// parameter that holds numbers in turn. See shelves/effects/sources/from_absent.py.
static std::vector<AbsentEffect> doc_absent_on(Doc& d, int layer, double now) {
    std::vector<AbsentEffect> all;
    // Effects that are switched off are not listed.
    for (const std::string& file : doc_fx_list(d, layer))
        if (std::filesystem::path(file).extension() == ".am")
            if (DocScript* sc = doc_script_of(d, file); sc && !sc->absent.empty()) {
                AbsentEffect e{sc->absent, {}};
                for (size_t i = 0; i < sc->parameters.size(); ++i) {
                    std::string name = sc->parameters[i].name;
                    const size_t cut = name.rfind('_');
                    // A name that ends in _x, _y, _z or _w is one component of a vector parameter.
                    const bool part = cut != std::string::npos && cut + 2 == name.size() && std::string("xyzw").find(name[cut + 1]) != std::string::npos;
                    if (part) name = name.substr(0, cut);
                    const float v = (float)doc_number(d, layer, sc->names[i].c_str(), now, sc->parameters[i].usual);
                    if (part && !e.params.empty() && e.params.back().first == name) e.params.back().second.push_back(v);
                    else e.params.push_back({name, {v}});
                }
                all.push_back(e);
            }
    return all;
}

// recipes.h: part of doc.h (recipes). Read only through doc.h.
static std::vector<DocRecipe> doc_recipes_read() {
    std::vector<DocRecipe> all;
    for (const auto& f : doc_folder_files("create", ".js")) {
        DocRecipe r;
        r.path = f.string();
        std::ifstream in(f);
        std::stringstream text;
        text << in.rdbuf();
        const std::string form = adapter_form(text.str()), told = adapter_js(text.str(), form);   // (a form from the net told as a sketch: adapter.h)
        if (text.str().find("\n// make ") == std::string::npos && script_is_sketch(told)) {   // (a sketch of p5.js as it comes, no head of ours: a solid given it)
            r.name = f.stem().string(), r.what = form.empty() ? "A p5.js sketch" : "A sketch from the net", r.code = told.find("WEBGL") != std::string::npos, r.program = adapter_name(form);   // (its layers and motion all its own: docs/internal/notes/CREATE_PROGRAM.md)
            r.lines = {r.code ? "make solid cube" : "make picture " + r.path};   // (in 3D its solids stand in the world; in 2D what it paints is a picture)
            if (!r.code) r.lines.push_back("fit fit");   // (as large as the picture: doc_fit, After Effects' Fit to Comp)
            all.push_back(r);
            continue;
        }
        in.clear(), in.seekg(0);
        for (std::string line; std::getline(in, line);) {
            if (line.rfind("//", 0) != 0) { if (line.find_first_not_of(" \t\r") != std::string::npos) { r.code = true; break; } continue; }
            line.erase(0, line.find_first_not_of("/ "));
            if (line.rfind("--label:", 0) == 0) { r.program = line.substr(8, line.find_last_not_of(" \r") - 7); continue; }   // (a closed pack, what it was written for: a whole Cavalry script's "// --label:Cavalry")
            if (line.rfind("--", 0) == 0) continue;   // (a knob)
            if (r.name.empty()) { const size_t colon = line.find(':'); r.name = line.substr(0, colon); r.what = colon == std::string::npos ? "" : line.substr(line.find_first_not_of(' ', colon + 1)); }
            else if (!line.empty()) r.lines.push_back(line);
        }
        if (!r.name.empty() && !r.lines.empty() && r.lines[0].rfind("make ", 0) == 0) all.push_back(r);
    }
    return all;
}
static std::string doc_recipe_names() {
    std::string all;
    for (const DocRecipe& r : doc_recipes()) all += (all.empty() ? "" : "\n") + r.name + "\t" + r.what + (r.program.empty() ? "" : "\t" + r.program + "\t" + r.path);   // (a pack: the Program shelf's)
    return all;
}
// Whether a file the document's pictures are made from (the stage's effects, the layers' scripts) has been written
// over since it was read: a stage that is not drawing is woken by it (a file saved shows at once).
static bool doc_files_moved(Doc& d) {
    bool moved = screen_moved(d.screen);
    for (int t : doc_laid(d)) doc_scripts_on(d, t);   // (each looks at its file's time and reads it again if it changed)
    if (DocScripts& kept = doc_scripts_kept(d); kept.made != kept.told) kept.told = kept.made, moved = true, d.scripted.clear();   // (read again here, or by a window asking for its cards first)
    return moved;
}
// The files of a kind in its folders (doc_folders) ("name\tpath\tlabel\tpicture", one to a line): the whole-screen effects (effects/*.wgsl),
// the motions a layer may be given (expressions/*.js); a file's name as its first line says it, before the colon; its label
// (what it is for, the shelf's kind) as a head line "// --label:Distort" says it (AviUtl's --label:, its script's menu); its
// picture for the shelf the .png beside it, if there is one ("" none).
// An effect's tile on the shelf, "\tpicture\thome\tsame": its picture (the one drawn for it in
// ~/Library/Caches/Motolii/tiles, with its moving frames beside it, home_0..7.png, as Alight Motion's tiles move; until
// then a .png beside it, as fx_tiles.sh writes the library's; "" none yet), where one drawn for it goes, named by the
// file and when it and the first.tsv beside it were last written, and how the window draws them, as midi_roll_file names
// its rolls (an @ file's script by "file#name"): any of them changed, it is drawn again; and "same" when none of its frames is seen to differ from the sample (home.same; the window
// draws and measures them: app/lib/workspace/shelf/effect_tiles.dart).
static std::string doc_tile(const std::string& ref, const std::filesystem::path& beside) {
    std::error_code wrong;
    const std::string file = ref.substr(0, ref.find('#'));
    std::string key = ref;
    if (auto at = std::filesystem::last_write_time(file, wrong); !wrong) key += "|" + std::to_string((long long)at.time_since_epoch().count());
    if (auto at = std::filesystem::last_write_time(std::filesystem::path(file).parent_path() / "first.tsv", wrong); !wrong) key += "|first " + std::to_string((long long)at.time_since_epoch().count());   // (the values it comes with: script_first)
    wrong.clear();
    key += "|tiles 3";   // (how the window draws them, effect_tiles.dart: made again when that changes)
    uint64_t hash = 1469598103934665603ull;
    for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
    const char* home = std::getenv("HOME");
    char name[24];
    std::snprintf(name, sizeof name, "%016llx.png", (unsigned long long)hash);
    const std::string drawn = (std::filesystem::path(home ? home : "/tmp") / "Library/Caches/Motolii/tiles" / name).string();
    const std::string picture = std::filesystem::exists(drawn, wrong) ? drawn : !beside.empty() && std::filesystem::exists(beside, wrong) ? beside.string() : "";
    return "\t" + picture + "\t" + drawn + "\t" + (std::filesystem::exists(drawn + ".same", wrong) ? "same" : "");
}
// What a WGSL effect is, read from it as isf_tags reads an ISF file (the user's Mercari: read, not asked; Shadertoy's
// filters, golf (92)): from its head, Motolii's own lines (screen_fx.h): its passes (--pass@; more than one: multipass;
// one kept from frame to frame, its first flag 1, or --history@: feedback), another picture (--picture@: image); from
// its body, the stage's clock read (.time, .frame: time).
static std::string doc_wgsl_tags(const std::filesystem::path& file) {
    std::ifstream in(file);
    int passes = 0;
    bool feedback = false, image = false, clock = false;
    static const std::regex ticks(R"(\.\s*(time|frame)\b)");   // (read, knobs.time: a field declared and not read is not the clock)
    for (std::string line; std::getline(in, line);) {
        if (line.rfind("//", 0) == 0) {
            if (const size_t at = line.find("--pass@"); at != std::string::npos) {
                ++passes;
                if (const size_t colon = line.find(':', at); colon != std::string::npos && line.compare(colon + 1, 1, "1") == 0) feedback = true;
            }
            feedback = feedback || line.find("--history@") != std::string::npos;
            image = image || line.find("--picture@") != std::string::npos;
        } else if (!clock && (line.find("time") != std::string::npos || line.find("frame") != std::string::npos) && std::regex_search(line, ticks)) clock = true;   // (the regex only where its words are, as ripgrep's literals: 1,024 lines of 82,592, and std::regex was most of the shelf's listing)
    }
    std::string tags;
    for (const auto& [on, word] : {std::pair{passes > 1, "multipass"}, {feedback, "feedback"}, {clock, "time"}, {image, "image"}}) if (on) tags += (tags.empty() ? "" : " ") + std::string(word);
    return tags;
}
static std::string doc_folder_names(const char* folder, const char* extension) {
    struct Seen { std::string all; int seen = -1; };
    static std::map<std::string, Seen> seen;
    Seen& one = seen[folder];
    std::string& all = one.all;
    if (!doc_folder_moved(one.seen)) return all;
    all.clear();
    for (const auto& f : doc_folder_files(folder, extension)) {
        if (f.extension() == ".json" && !viewer_is(f.string())) continue;   // (a .json not Filament's own settings is no effect: Sashimono's table obj.effect reads, sashimono_aviutl.json)
        const std::string read = isf_file(f.string());   // (an ISF effect: its head as made WGSL; one that cannot be is not shown)
        if (read.empty()) continue;
        std::ifstream in(read);
        std::string first, name = f.stem().string(), label, about;
        if (std::getline(in, first) && first.rfind("// ", 0) == 0 && first.find(':') != std::string::npos) name = first.substr(3, first.find(':') - 3);
        for (std::string line; std::getline(in, line) && line.rfind("//", 0) == 0;) {
            if (const size_t at = line.find("--label:"); at != std::string::npos && label.empty()) label = line.substr(at + 8);
            if (const size_t at = line.find("--about:"); at != std::string::npos && about.empty()) about = line.substr(at + 8);   // (what it does, in its maker's words)
        }
        if (f.extension() == ".mjs") label = "Points";   // (a PlayCanvas splat effect: for a point cloud)
        std::replace(about.begin(), about.end(), '\t', ' ');
        all += (all.empty() ? "" : "\n") + name + "\t" + f.string() + "\t" + label + doc_tile(f.string(), std::filesystem::path(f).replace_extension(".png")) + "\t" + about + "\t" + (f.extension() == ".fs" ? isf_tags(f.string()) : f.extension() == ".wgsl" ? doc_wgsl_tags(f) : "");   // (and what it is, read from it: isf_tags, doc_wgsl_tags)
    }
    return all;
}
// AviUtl2's scripts as their makers give them, a package a folder (aviutl_scripts/<maker>__<package>/, unchanged: a
// script's require reads beside it), in the library's aviutl_scripts/ and the maker's own (doc_folders), to any depth:
// each .anm2 and .obj2 a line as doc_folder_names's, each script of an @ file ("file#name") its own, its label its
// --label:. A file is read again only when it was written over.
static std::string doc_aviutl_names() {
    static std::string all;
    static int seen = -1;
    static std::map<std::string, std::pair<std::filesystem::file_time_type, std::string>> read;   // (each file's lines as it was)
    if (!doc_folder_moved(seen)) return all;
    all.clear();
    std::error_code wrong;
    for (const auto& dir : doc_folders("aviutl_scripts")) {
        std::vector<std::filesystem::path> files;
        for (auto e = std::filesystem::recursive_directory_iterator(dir, wrong); !wrong && e != std::filesystem::recursive_directory_iterator(); e.increment(wrong))
            if (e->is_regular_file(wrong) && aviutl_is(e->path().string())) files.push_back(e->path());
        wrong.clear();
        std::sort(files.begin(), files.end());
        for (const auto& f : files) {
            const auto stamp = std::filesystem::last_write_time(f, wrong);
            auto& [when, lines] = read[f.string()];
            if (lines.empty() || when != stamp) {
                when = stamp, lines.clear();
                std::ifstream in(f);
                const bool many = f.filename().string()[0] == '@';
                std::string name = many ? "" : f.stem().string(), label;
                // (and what each is, read from it as isf_tags reads an ISF file: AviUtl's own kinds by the extension, a custom
                //  object .obj2 a generator and a scene change .scn2 a transition; obj.getaudio: sound; obj.time, obj.frame: time)
                bool sound = false, clock = false;
                const std::string ext = f.extension().string();
                const auto put = [&] {
                    std::string tags;
                    for (const auto& [on, word] : {std::pair{ext == ".scn2", "transition"}, {ext == ".obj2", "generator"}, {sound, "sound"}, {clock, "time"}}) if (on) tags += (tags.empty() ? "" : " ") + std::string(word);
                    if (!name.empty()) lines += name + "\t" + f.string() + (many ? "#" + aviutl_word(name) : "") + "\t" + label + doc_tile(f.string() + (many ? "#" + aviutl_word(name) : ""), many ? std::filesystem::path() : std::filesystem::path(f).replace_extension(".png")) + "\t\t" + tags + "\n";
                    sound = clock = false;
                };
                for (std::string line; std::getline(in, line);) {
                    if (line.rfind("\xEF\xBB\xBF", 0) == 0) line.erase(0, 3);
                    line.erase(line.find_last_not_of(" \t\r") + 1);
                    if (many && line.rfind("@", 0) == 0) { put(), name = line.substr(1), label.clear(); continue; }
                    if (label.empty() && line.rfind("--label:", 0) == 0) label = line.substr(8);
                    sound = sound || line.find("obj.getaudio") != std::string::npos;
                    clock = clock || line.find("obj.time") != std::string::npos || line.find("obj.frame") != std::string::npos;
                }
                put();
            }
            all += lines;
        }
    }
    if (!all.empty()) all.pop_back();
    return all;
}
// The ways a maker keeps of their own, as a maker's scripts are theirs: a file each in ease/ of their own folder
// (doc_folders), and the few the library comes with (one put in either is a tile of the Ease desk at once). Its first line says its name
// before the colon; the rest is how far it is, as a way defined in a document says it (doc_define: a, b, u, p1..p4,
// bezier(u, x1, y1, x2, y2), way('Cyclic', u)). Put on a key, it is written into the document, so the document goes as it did wherever it
// is opened. The maker's own of a name goes before the library's.
// One for the whole program, read by every document's hand and every window's look: held by a lock, given as a copy.
static std::mutex& doc_own_easings_lock() { static std::mutex one; return one; }
static std::atomic<int>& doc_own_easings_made() { static std::atomic<int> made{0}; return made; }   // (how many times what was read was not what was before: the window's picture made again, entry/render_thread.h)
static std::map<std::string, std::string> doc_own_easings() {
    std::lock_guard<std::mutex> hold(doc_own_easings_lock());
    static std::map<std::string, std::string> kept;
    static int seen = -1;
    if (seen == files_changed()) return kept;   // (looked at again when the window says a file changed: the OS's own watch, GIO's GFileMonitor, tells only while GLib's default main context runs, and none runs here; dart:io's runs in the window)
    seen = files_changed();
    std::map<std::string, std::string> all;
    std::error_code wrong;
    for (const auto& dir : doc_folders("ease"))
        for (const auto& e : std::filesystem::directory_iterator(dir, wrong)) {
            if (e.path().extension() != ".way") continue;
            std::ifstream in(e.path());
            std::string line, name, expression;
            while (std::getline(in, line)) {
                if (line.rfind("//", 0) != 0) { expression += line + " "; continue; }
                if (name.empty() && line.find(':') != std::string::npos) name = line.substr(2, line.find(':') - 2);
            }
            name.erase(0, name.find_first_not_of(' '));
            if (name.empty()) name = e.path().stem().string();
            if (expression.find_first_not_of(' ') != std::string::npos) all[name] = expression;   // (the maker's folder is read last: theirs of a name stands)
        }
    if (all != kept) kept = all, ++doc_own_easings_made();
    return kept;
}
static std::string doc_recipe_code_path(const std::string& name) {
    for (const DocRecipe& one : doc_recipes()) if (one.code && one.name == name) return one.path;
    return "";
}
// The recipe of that name made at the stage's present moment, one step (0: not made, d.error says why).
static bool doc_fit(Doc& d, int layer, const std::string& how);
static int doc_make(Doc& d, const char* name) {
    std::vector<DocRecipe> all = doc_recipes();
    const DocRecipe* r = nullptr;
    for (const DocRecipe& one : all) if (one.name == name) r = &one;
    if (!r) return d.error = std::string("there is no recipe ") + name, 0;
    doc_act(d);
    int now = 0, first = 0, before = 0;   // (the layer the lines tell: "make" the first, "then" another, each named as the recipe)
    double from = 0.0;   // (where its keys count from: "here" says the playhead)
    for (const std::string& line : r->lines) {
        std::istringstream w(line);
        std::string call, value;
        w >> call >> value;
        std::string rest;
        std::getline(w, rest);
        rest.erase(0, rest.find_first_not_of(' '));
        if (call == "make" || call == "then") {
            before = now;
            if (!(now = doc_add(d, value.c_str(), rest.c_str()))) break;
            if (!first) first = now;
            doc_say(d, now, "name", r->name.c_str()), doc_set(d, now, "start", 0);   // (on from the document's beginning, wherever the stage stands: a picture that goes round with it)
            if (now == first && r->code) doc_say(d, now, "script", r->path.c_str());
            continue;
        }
        const int layer = now;
        if (!layer) break;
        if (call == "set") doc_set(d, layer, value.c_str(), rest == "first" ? first : rest == "before" ? before : rest == "behind" ? first - 0.5 : std::atof(rest.c_str()));   // (a layer it goes with: the recipe's first, or the one made before this one; an order just behind the first)
        else if (call == "say") doc_say(d, layer, value.c_str(), value == "script" && rest == "this" ? r->path.c_str() : rest.c_str());   // (another of its layers run by the recipe's own code: "this"; by another recipe's, its name: a preset that lays its copies out says "Repeater", doc_say)
        else if (call == "here") from = d.stage->now, doc_set(d, layer, "start", from);   // (it begins where the playhead is, as a clip is placed: not a picture that goes round)
        else if (call == "fit") doc_fit(d, layer, value);
        else if (call == "key") { std::istringstream k(rest); double at = 0, is = 0; k >> at >> is; doc_key(d, layer, value.c_str(), from + at, is); }   // (at that moment of the document, wherever the stage stands: its film loops as made)
    }
    return doc_acted(d) && now ? first : 0;
}

#include "document/scripts/recipes.h"

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <regex>
#include <sstream>
#include <system_error>
#include <utility>

#include "community/aviutl/aviutl.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "community/sites/adapter.h"
#include "document/edit/arrange.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "document/evaluate/value_at.h"
#include "shelf/shelf_folders.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/viewer_settings.h"

namespace {

// Returns the tile fields for a file, as "\timage\thome\tsame".
// image: the preview image drawn for the file in ~/Library/Caches/Motolii/tiles. Its animation
// frames sit beside it as home_0..7.png, as Alight Motion's tiles animate. Until it exists this is
// the .png beside the file, as fx_tiles.sh writes for the library, or empty if there is none yet.
// home: where the image for the file is written. The name is a hash of the file's path and
// modification time, the modification time of the first.tsv beside it, and the version of the app's
// tile drawing, so a change to any of them draws the tile again. For a script inside an @ file the
// path is "file#name", as midi_roll_file names its rolls.
// same: "same" when none of the frames differs from the sample (home.same). The app draws and
// measures the frames in app/lib/workspace/shelf/effect_tiles.dart.
std::string doc_tile(const std::string& ref, const std::filesystem::path& beside) {
    std::error_code wrong;
    const std::string file = ref.substr(0, ref.find('#'));
    std::string key = ref;
    if (auto at = std::filesystem::last_write_time(file, wrong); !wrong) key += "|" + std::to_string((long long)at.time_since_epoch().count());
    // The values the script starts with are in first.tsv (script_first), so its time is part of the
    // key.
    if (auto at = std::filesystem::last_write_time(std::filesystem::path(file).parent_path() / "first.tsv", wrong); !wrong) key += "|first " + std::to_string((long long)at.time_since_epoch().count());
    wrong.clear();
    // Version of the app's tile drawing in effect_tiles.dart. Changing it draws every tile again.
    key += "|tiles 3";
    // 64-bit FNV-1a hash of the key.
    uint64_t hash = 1469598103934665603ull;
    for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
    const char* home = std::getenv("HOME");
    char name[24];
    std::snprintf(name, sizeof name, "%016llx.png", (unsigned long long)hash);
    const std::string drawn = (std::filesystem::path(home ? home : "/tmp") / "Library/Caches/Motolii/tiles" / name).string();
    const std::string picture = std::filesystem::exists(drawn, wrong) ? drawn : !beside.empty() && std::filesystem::exists(beside, wrong) ? beside.string() : "";
    return "\t" + picture + "\t" + drawn + "\t" + (std::filesystem::exists(drawn + ".same", wrong) ? "same" : "");
}

// Returns space-separated tags describing a WGSL effect, read from the file as isf_tags reads an
// ISF file. From the head comment lines, which are Motolii's own (screen_fx.h): "multipass" for
// more than one pass (--pass@), "feedback" when a pass is kept from frame to frame (its first flag
// is 1, or --history@), and "image" when it takes another image (--picture@). From the body: "time"
// when it reads the stage's clock (.time or .frame).
std::string doc_wgsl_tags(const std::filesystem::path& file) {
    std::ifstream in(file);
    int passes = 0;
    bool feedback = false, image = false, clock = false;
    // Matches a read such as knobs.time. A field that is only declared is not use of the clock.
    static const std::regex ticks(R"(\.\s*(time|frame)\b)");
    for (std::string line; std::getline(in, line);) {
        // On lines that are not comments, run the regex only if they contain the words, like a
        // literal prefilter in ripgrep. That is 1,024 of 82,592 lines, and std::regex was most of
        // the time spent listing the shelf.
        if (line.rfind("//", 0) == 0) {
            if (const size_t at = line.find("--pass@"); at != std::string::npos) {
                ++passes;
                if (const size_t colon = line.find(':', at); colon != std::string::npos && line.compare(colon + 1, 1, "1") == 0) feedback = true;
            }
            feedback = feedback || line.find("--history@") != std::string::npos;
            image = image || line.find("--picture@") != std::string::npos;
        } else if (!clock && (line.find("time") != std::string::npos || line.find("frame") != std::string::npos) && std::regex_search(line, ticks)) clock = true;
    }
    std::string tags;
    for (const auto& [on, word] : {std::pair{passes > 1, "multipass"}, {feedback, "feedback"}, {clock, "time"}, {image, "image"}}) if (on) tags += (tags.empty() ? "" : " ") + std::string(word);
    return tags;
}

std::mutex& doc_own_easings_lock() { static std::mutex one; return one; }

}  // namespace

std::vector<DocRecipe> doc_recipes_read() {
    std::vector<DocRecipe> all;
    for (const auto& f : doc_folder_files("create", ".js")) {
        DocRecipe r;
        r.path = f.string();
        std::ifstream in(f);
        std::stringstream text;
        text << in.rdbuf();
        // Detect which program the pasted sketch comes from and convert it to plain JavaScript
        // (adapter.h).
        const std::string form = adapter_form(text.str()), told = adapter_js(text.str(), form);
        // A p5.js sketch as pasted has no head of ours, so it gets a default recipe that adds one
        // layer.
        if (text.str().find("\n// make ") == std::string::npos && script_is_sketch(told)) {
            // The sketch makes its own layers and motion, see
            // docs/design/create_and_program_shelves.md. The code flag is set for a WEBGL sketch.
            r.name = f.stem().string(), r.what = form.empty() ? "A p5.js sketch" : "A sketch from the net", r.code = told.find("WEBGL") != std::string::npos, r.program = adapter_name(form);
            // In 3D the sketch's solids stand in the world. In 2D what it paints becomes an image
            // layer.
            r.lines = {r.code ? "make solid cube" : "make picture " + r.path};
            // Scale the image layer to fill the frame (doc_fit, like After Effects' Fit to Comp).
            if (!r.code) r.lines.push_back("fit fit");
            all.push_back(r);
            continue;
        }
        in.clear(), in.seekg(0);
        for (std::string line; std::getline(in, line);) {
            if (line.rfind("//", 0) != 0) { if (line.find_first_not_of(" \t\r") != std::string::npos) { r.code = true; break; } continue; }
            line.erase(0, line.find_first_not_of("/ "));
            // A head line "--label:" names the program the recipe was written for, for example
            // "--label:Cavalry" at the top of a whole Cavalry script.
            if (line.rfind("--label:", 0) == 0) { r.program = line.substr(8, line.find_last_not_of(" \r") - 7); continue; }
            // Other "--" lines declare parameters and are read elsewhere.
            if (line.rfind("--", 0) == 0) continue;
            // The first remaining comment line is "name: what it does". Later ones are the recipe's
            // commands.
            if (r.name.empty()) { const size_t colon = line.find(':'); r.name = line.substr(0, colon); r.what = colon == std::string::npos ? "" : line.substr(line.find_first_not_of(' ', colon + 1)); }
            else if (!line.empty()) r.lines.push_back(line);
        }
        // Keep only recipes whose first command is "make".
        if (!r.name.empty() && !r.lines.empty() && r.lines[0].rfind("make ", 0) == 0) all.push_back(r);
    }
    return all;
}

std::string doc_recipe_names() {
    std::string all;
    for (const DocRecipe& r : doc_recipes()) all += (all.empty() ? "" : "\n") + r.name + "\t" + r.what + (r.program.empty() ? "" : "\t" + r.program + "\t" + r.path);
    return all;
}

bool doc_files_moved(Doc& d) {
    bool moved = screen_moved(d.screen);
    // Each layer checks its script file's modification time and rereads the file if it changed.
    for (int t : doc_laid(d)) doc_scripts_on(d, t);
    // Scripts reread since the last check also count as moved. The app may have reread them first,
    // when it asked for the layer cards.
    if (DocScripts& kept = doc_scripts_kept(d); kept.made != kept.told) kept.told = kept.made, moved = true, d.scripted.clear();
    return moved;
}

std::string doc_folder_names(const char* folder, const char* extension) {
    struct Seen { std::string all; int seen = -1; };
    static std::map<std::string, Seen> seen;
    Seen& one = seen[folder];
    std::string& all = one.all;
    if (!doc_folder_moved(one.seen)) return all;
    all.clear();
    for (const auto& f : doc_folder_files(folder, extension)) {
        // A .json file that is not Filament's own settings is not an effect. Sashimono's obj.effect
        // table reads sashimono_aviutl.json.
        if (f.extension() == ".json" && !viewer_is(f.string())) continue;
        // An ISF effect is converted to WGSL by reading its head. A file that cannot be converted
        // is not listed.
        const std::string read = isf_file(f.string());
        if (read.empty()) continue;
        std::ifstream in(read);
        std::string first, name = f.stem().string(), label, about;
        if (std::getline(in, first) && first.rfind("// ", 0) == 0 && first.find(':') != std::string::npos) name = first.substr(3, first.find(':') - 3);
        for (std::string line; std::getline(in, line) && line.rfind("//", 0) == 0;) {
            if (const size_t at = line.find("--label:"); at != std::string::npos && label.empty()) label = line.substr(at + 8);
            // --about: is a one-line description, in the effect author's words.
            if (const size_t at = line.find("--about:"); at != std::string::npos && about.empty()) about = line.substr(at + 8);
        }
        // A PlayCanvas splat effect, for a point cloud.
        if (f.extension() == ".mjs") label = "Points";
        std::replace(about.begin(), about.end(), '\t', ' ');
        // The last two fields are the description and the tags read from the file by isf_tags or
        // doc_wgsl_tags.
        all += (all.empty() ? "" : "\n") + name + "\t" + f.string() + "\t" + label + doc_tile(f.string(), std::filesystem::path(f).replace_extension(".png")) + "\t" + about + "\t" + (f.extension() == ".fs" ? isf_tags(f.string()) : f.extension() == ".wgsl" ? doc_wgsl_tags(f) : "");
    }
    return all;
}

std::string doc_aviutl_names() {
    static std::string all;
    static int seen = -1;
    // Cache of each file's output lines, with the modification time they were read at.
    static std::map<std::string, std::pair<std::filesystem::file_time_type, std::string>> read;
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
                // Also read the tags from the script, as isf_tags does for an ISF file. The
                // extension gives AviUtl's own kinds: a custom object .obj2 is a "generator" and a
                // scene change .scn2 is a "transition". obj.getaudio marks "sound" and obj.time or
                // obj.frame marks "time".
                bool sound = false, clock = false;
                const std::string ext = f.extension().string();
                // Writes the line for the script read so far, then resets the tags.
                const auto put = [&] {
                    std::string tags;
                    for (const auto& [on, word] : {std::pair{ext == ".scn2", "transition"}, {ext == ".obj2", "generator"}, {sound, "sound"}, {clock, "time"}}) if (on) tags += (tags.empty() ? "" : " ") + std::string(word);
                    if (!name.empty()) lines += name + "\t" + f.string() + (many ? "#" + aviutl_word(name) : "") + "\t" + label + doc_tile(f.string() + (many ? "#" + aviutl_word(name) : ""), many ? std::filesystem::path() : std::filesystem::path(f).replace_extension(".png")) + "\t\t" + tags + "\n";
                    sound = clock = false;
                };
                for (std::string line; std::getline(in, line);) {
                    if (line.rfind("\xEF\xBB\xBF", 0) == 0) line.erase(0, 3);
                    line.erase(line.find_last_not_of(" \t\r") + 1);
                    // A line starting with @ begins a new script in an @ file.
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

std::atomic<int>& doc_own_easings_made() { static std::atomic<int> made{0}; return made; }

std::map<std::string, std::string> doc_own_easings() {
    std::lock_guard<std::mutex> hold(doc_own_easings_lock());
    static std::map<std::string, std::string> kept;
    static int seen = -1;
    // Look again only when the app reports a file change. The OS file watch, GIO's GFileMonitor,
    // reports only while GLib's default main context runs, and none runs here. dart:io's watch runs
    // in the app.
    if (seen == files_changed()) return kept;
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
            // The user's folder is read last, so the user's easing of a name replaces the
            // library's.
            if (expression.find_first_not_of(' ') != std::string::npos) all[name] = expression;
        }
    if (all != kept) kept = all, ++doc_own_easings_made();
    return kept;
}

std::string doc_recipe_code_path(const std::string& name) {
    for (const DocRecipe& one : doc_recipes()) if (one.code && one.name == name) return one.path;
    return "";
}

int doc_make(Doc& d, const char* name) {
    std::vector<DocRecipe> all = doc_recipes();
    const DocRecipe* r = nullptr;
    for (const DocRecipe& one : all) if (one.name == name) r = &one;
    if (!r) return d.error = std::string("there is no recipe ") + name, 0;
    doc_act(d);
    // now: the layer the current line applies to. "make" starts the first layer and "then" starts
    // another, each named after the recipe. first: the first layer made. before: the layer made
    // before now.
    int now = 0, first = 0, before = 0;
    // Time that key times count from. "here" sets it to the playhead.
    double from = 0.0;
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
            // Start at the beginning of the project, wherever the stage is now, so the image layer
            // loops with the project.
            doc_say(d, now, "name", r->name.c_str()), doc_set(d, now, "start", 0);
            if (now == first && r->code) doc_say(d, now, "script", r->path.c_str());
            continue;
        }
        const int layer = now;
        if (!layer) break;
        // A set line takes a number, "first" or "before" for the id of the recipe's first layer or
        // of the layer made before this one, or "behind", which is half a step below the first
        // layer's id so it orders just behind it.
        if (call == "set") doc_set(d, layer, value.c_str(), rest == "first" ? first : rest == "before" ? before : rest == "behind" ? first - 0.5 : std::atof(rest.c_str()));
        // A say line sets a text property. For "script", "this" runs the layer with the recipe's
        // own code. Another recipe's name runs that recipe's code, for example a preset that lays
        // copies out says "Repeater" (doc_say). A shelf file is given as shelf and name, such as
        // "expressions/wave.js" (script_shelf_file).
        else if (call == "say") doc_say(d, layer, value.c_str(), value == "script" && rest == "this" ? r->path.c_str() : value == "script" ? script_shelf_file(rest).c_str() : rest.c_str());
        // "here" starts the layer at the playhead, like a placed clip, instead of looping with the
        // project.
        else if (call == "here") from = d.stage->now, doc_set(d, layer, "start", from);
        else if (call == "fit") doc_fit(d, layer, value);
        // Key times are relative to the start set above, wherever the stage is now, so the video
        // loops as made.
        else if (call == "key") { std::istringstream k(rest); double at = 0, is = 0; k >> at >> is; doc_key(d, layer, value.c_str(), from + at, is); }
    }
    return doc_acted(d) && now ? first : 0;
}

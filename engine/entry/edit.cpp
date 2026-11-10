// edit.cpp: a command-line shell for editing a project, one call per line. It uses only
// entry/motolii.h, so one program serves every project and is not compiled again for a scene.
// Usage: ./edit.sh out/first.motolii, then type one call per line. `help` lists the calls.
// A call that fails prints the reason and leaves the project unchanged.
#include "entry/motolii.h"
#include <algorithm>
#include <chrono>
#include <thread>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// The text printed by `help` and after a line that is not a call.
static const char* const calls =
    "  add film <file> | add sound <a .mp3, .wav, .m4a: heard, hidden> | add picture <an After Effects file, a .jpg, a .png> | add text <font.ttf> | add solid <file.glb>|ring|gem|cube   (say N fill glass: it is glass)\n"
    "  drag_start <layer> | drag_update <by> <a> <b> | drag_update effect <file> | drag_end 1|0 | remove <layer> | set <layer> <name> <number> | say <layer> <name> <word> | key <layer> <name> <at> <number>\n"
    "  easing <layer> <name> <at> <an easing, and its numbers> | easings | cards <layer>\n"
    "  create <script> | create_scripts | effect <layer> <name> | effects | shelf | presets | together on|off | undo | redo | list | at <seconds> | still <file.png> | export <file.mp4>\n";

// Opens the project named by the first argument and runs the calls read from standard input.
int main(int argc, char** argv) {
    if (argc < 2) return std::printf("FAIL edit <document>\n"), 1;
    // The size of a new project; set SIZE=1920x1080 for another. A project that stores its own size
    // is opened at that size.
    int wide = 1080, high = 1920;
    if (const char* size = std::getenv("SIZE")) std::sscanf(size, "%dx%d", &wide, &high);
    Motolii* m = motolii_open(argv[1], wide, high);
    if (!m) return std::printf("FAIL the document could not be opened\n"), 1;
    for (std::string line; std::getline(std::cin, line);) try {
        std::istringstream said(line);
        std::vector<std::string> w;
        for (std::string word; said >> word;) w.push_back(word);
        if (w.empty()) continue;
        const std::string& call = w[0];
        // True while every word that was read as a number was one.
        bool numbers = true;
        const auto number = [&](size_t i) { char* end = nullptr; const double is = std::strtod(w[i].c_str(), &end); if (*end || !std::isfinite(is)) numbers = false; return is; };
        const auto layer = [&] { const double n = number(1); return numbers && n == std::floor(n) ? (int)n : (numbers = false, 0); };
        // Returns the line from word i to its end.
        const auto rest = [&](size_t i) { size_t at = 0; for (size_t k = 0; k < i; ++k) at = line.find(w[k], at) + w[k].size(); return line.substr(line.find(w[i], at)); };
        const auto t0 = std::chrono::steady_clock::now();
        int ok = 1;
        bool known = true;
        // The file name may contain spaces, so it is the rest of the line.
        if (call == "add" && w.size() >= 3) { if ((ok = motolii_add(m, w[1].c_str(), rest(2).c_str()))) std::printf("thing %d\n", ok); }
        // A brush stroke as the app sends it: the tool (0 pen, 1 brush, 2 fill), the width, then x,
        // y and pressure for each point, in points of the image.
        else if (call == "brush" && w.size() >= 9) {
            const int ticket = motolii_later(m, "brush", 0, "", rest(1).c_str(), 0);
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
            if (ok) std::printf("thing %d\n", ok);
        }
        // Any change the app asks for later: the call, the layer, then its word, as motolii_later
        // takes them.
        else if (call == "later" && w.size() >= 3) {
            const int n = (int)number(2), ticket = numbers ? motolii_later(m, w[1].c_str(), n, "", w.size() > 3 ? rest(3).c_str() : "", 0) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        // Split at a time, as the app's layer menu asks for it.
        else if (call == "split" && w.size() == 3) {
            const int n = layer();
            const double at = number(2);
            const int ticket = numbers ? motolii_later(m, "split", n, "", "", at) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        // Convert to Outline, as the app's layer menu asks for it.
        else if (call == "outline" && w.size() == 2) {
            const int n = layer(), ticket = numbers ? motolii_later(m, "outline", n, "", "", 0) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "remove" && w.size() == 2) { const int n = layer(); if (numbers) ok = motolii_remove(m, n); }
        else if (call == "set" && w.size() == 4) { const int n = layer(); const double is = number(3); if (numbers) ok = motolii_set(m, n, w[2].c_str(), is); }
        else if (call == "drag_start" && w.size() == 2) { const int n = layer(); if (numbers) ok = motolii_drag_start(m, n); }
        // Shows an effect file on the dragged layer without storing it, as the shelf's tile does
        // under the pointer.
        else if (call == "drag_update" && w.size() >= 3 && w[1] == "effect") {
            const int ticket = motolii_later(m, "drag_update", 0, "effect", rest(2).c_str(), 0);
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "drag_update" && w.size() == 4) { const double a = number(2), b = number(3); if (numbers) ok = motolii_drag_update(m, w[1].c_str(), a, b); }
        // As the app ends a drag: motolii_later with "drag_end".
        else if (call == "drag_end" && w.size() == 2) {
            const int ticket = motolii_later(m, "drag_end", 0, "", "", w[1] != "0");
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        // A text layer's words are the rest of the line. With none the word is empty.
        else if (call == "say" && w.size() >= 3) { const int n = layer(); if (numbers) ok = motolii_say(m, n, w[2].c_str(), w.size() > 3 ? rest(3).c_str() : ""); }
        // midi <layer> <name> <kind> <channel, -1 for any> <bpm, 0 for the file's own> <file.mid>
        else if (call == "midi" && w.size() >= 7) { const int n = layer(); const int ch = (int)number(4); const double bpm = number(5); if (numbers) ok = motolii_midi(m, n, w[2].c_str(), rest(6).c_str(), w[3].c_str(), ch, bpm); }
        else if (call == "key" && w.size() == 5) { const int n = layer(); const double at = number(3), is = number(4); if (numbers) ok = motolii_key(m, n, w[2].c_str(), at, is); }
        // The easing applies from that keyframe to the next.
        else if (call == "easing" && w.size() >= 5) { const int n = layer(); const double at = number(3); if (numbers) ok = motolii_easing(m, n, w[2].c_str(), at, rest(4).c_str()); }
        else if (call == "easings" && w.size() == 1) { std::printf("  %s\n", motolii_easings(m)); continue; }
        // A layer's cards as the inspector lays them out: "title: names; ...".
        else if (call == "cards" && w.size() == 2) { const int n = layer(); if (numbers) std::printf("  %s\n", motolii_cards(m, n)); continue; }
        else if (call == "create" && w.size() >= 2) ok = motolii_create(m, rest(1).c_str()) != 0;
        // An effect's name may contain spaces.
        else if (call == "effect" && w.size() >= 3) { const int n = layer(); if (numbers) ok = motolii_effect(m, n, rest(2).c_str(), motolii_now(m)); }
        else if (call == "effects" && w.size() == 1) { std::printf("%s\n", motolii_effect_names(m)); continue; }
        else if (call == "presets" && w.size() == 1) { std::printf("%s\n", motolii_presets(m)); continue; }
        // The effect files on the shelf, including AviUtl2's scripts.
        else if (call == "shelf" && w.size() == 1) { std::printf("%s\n", motolii_effects(m)); continue; }
        // The shelf's effects nearest the words come first, matched by name, label and description
        // with motolii_find (RapidFuzz).
        else if (call == "find" && w.size() >= 2) {
            std::string items;
            for (const char* lines : {motolii_effects(m), motolii_effect_names(m)}) {
                std::istringstream in(lines);
                for (std::string l; std::getline(in, l);) {
                    std::vector<std::string> f;
                    std::istringstream cut(l);
                    for (std::string one; std::getline(cut, one, '\t');) f.push_back(one);
                    if (!f.empty() && !f[0].empty()) items += f[0] + "\t" + f[0] + " " + (f.size() > 2 ? f[2] : "") + "\t" + (f.size() > 6 ? f[6] : "") + "\n";
                }
            }
            std::printf("%s", motolii_find(m, rest(1).c_str(), items.c_str(), 10));
            // Then search the record of what Motolii already has, in
            // docs/design/golf_noise.md, so that a feature that exists is found
            // before anyone says it is missing. Lines that contain the words as typed come first,
            // as the shelf's plain hits, followed by the nearest matches from motolii_find.
            std::string words = rest(1), lower = words, lines, said;
            std::transform(lower.begin(), lower.end(), lower.begin(), [](unsigned char c) { return (char)std::tolower(c); });
            int plain = 0;
            // The path is relative to out/filament_webgpu, where edit.sh runs this program.
            for (const char* book : {"../../../docs/design/golf_noise.md"}) {
                std::ifstream in(book);
                int n = 0;
                for (std::string l; std::getline(in, l);) {
                    ++n;
                    if (l.rfind("| ", 0) != 0 && l.rfind("- [", 0) != 0) continue;
                    const std::string id = std::string(book).substr(std::string(book).rfind('/') + 1) + ":" + std::to_string(n);
                    std::string low = l;
                    std::transform(low.begin(), low.end(), low.begin(), [](unsigned char c) { return (char)std::tolower(c); });
                    // The head of a line ends at the first full-width colon.
                    const size_t colon = l.find("\xEF\xBC\x9A");
                    if (low.find(lower) != std::string::npos) { if (plain++ < 10) said += id + "\t" + l.substr(0, 160) + "\n"; continue; }
                    lines += id + "\t" + l.substr(0, colon == std::string::npos ? 120 : colon) + "\t" + l + "\n";
                }
            }
            std::printf("-- in the ledger and the golf's record\n%s", said.c_str());
            if (plain < 10) {
                std::istringstream near(motolii_find(m, words.c_str(), lines.c_str(), 10 - plain));
                for (std::string l; std::getline(near, l);) {
                    const std::string id = l.substr(0, l.find('\t'));
                    const size_t at = lines.find(id + "\t");
                    if (at != std::string::npos) std::printf("%s ~\t%s\n", id.c_str(), lines.substr(lines.find('\t', lines.find('\t', at) + 1) + 1, 160).c_str());
                }
            }
            continue;
        }
        // Files were written, added or removed. The shelves read them again at their next use.
        else if (call == "changed" && w.size() == 1) { motolii_files_changed(); continue; }
        else if (call == "create_scripts" && w.size() == 1) { std::printf("  %s\n", motolii_create_scripts(m)); continue; }
        // The calls in between are one undo step, and the preview is matched to the project once at
        // the end.
        else if (call == "together" && w.size() == 2) ok = motolii_together(m, w[1] == "on" ? 1 : 0) || w[1] == "on";
        else if (call == "undo" && w.size() == 1) ok = motolii_undo(m);
        // As the app redoes: motolii_later with "redo".
        else if (call == "redo" && w.size() == 1) {
            const int ticket = motolii_later(m, "redo", 0, "", "", 0);
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "at" && w.size() == 2) { const double at = number(1); if (numbers) ok = motolii_at(m, at); }
        else if (call == "still" && w.size() >= 2) ok = motolii_still(m, rest(1).c_str());
        // Stores the project's poster image in the project: motolii_poster.
        else if (call == "poster" && w.size() >= 2) ok = motolii_poster(m, rest(1).c_str());
        // properties <project> [png]: the paths must not contain spaces.
        else if (call == "properties" && w.size() >= 2) std::printf("%s\n", motolii_doc_properties(w[1].c_str(), w.size() >= 3 ? w[2].c_str() : nullptr));
        else if (call == "export" && w.size() >= 2) ok = motolii_export(m, rest(1).c_str());
        else if (call == "pack" && w.size() >= 3) { const int n = motolii_pack(m, w[1].c_str(), rest(2).c_str()); ok = n >= 0; if (ok) std::printf("  %d files\n", n); }
        else if (call == "help") { std::printf("%s", calls); continue; }
        else if (call == "list" && w.size() == 1) { std::printf("%s  (the document runs %.2f seconds)\n", motolii_list(m), motolii_seconds(m)); continue; }
        else known = false;
        if (!known || !numbers) std::printf("not a call: %s\n%s", line.c_str(), !numbers ? "  (a number was asked for where a word stands)\n" : calls);
        else std::printf("%s: %s, %.1f ms\n", call.c_str(), ok ? "done" : (std::string("NOT done: ") + motolii_error(m)).c_str(), std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
        std::fflush(stdout);
    // The engine failed in a way the loop cannot recover from. Report it and stop.
    } catch (const std::exception& e) {
        std::printf("FAIL %s: %s\n", line.c_str(), e.what());
        return 1;
    }
    motolii_close(m);
    return 0;
}

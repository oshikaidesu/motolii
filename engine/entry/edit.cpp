// edit.cpp: a document edited by calls, a line each: a shell over motolii.h, as a shell on a screen would be. It
// calls motolii.h and nothing else: one program for every document, never built again for a scene.
//   ./edit.sh out/first.motolii       then a call a line (`help` lists them)
// A call that is not done says why, and leaves the document as it was.
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

static const char* const calls =
    "  add film <file> | add sound <a .mp3, .wav, .m4a: heard, hidden> | add picture <an After Effects file, a .jpg, a .png> | add text <font.ttf> | add solid <file.glb>|ring|gem|cube   (say N fill glass: it is glass)\n"
    "  pen <layer, 0: new> <x> <y> [<handle x> <handle y>] (points of the picture) | points <layer> | handles <layer> | drag_start <layer> | drag_update <by> <a> <b> | drag_update effect <file> | drag_end 1|0 | remove <layer> | set <layer> <name> <number> | say <layer> <name> <word> | key <layer> <name> <at> <number> | unkey <layer> <name> <at>\n"
    "  easing <layer> <name> <at> <an easing, and its numbers> | easings | cards <layer> | define <an easing's name> <its expression> | value <layer> <name> <at>\n"
    "  create <script> | create_scripts | effect <layer> <name> | effects | shelf | preset save|apply <layer> <file.motolii> | presets | together on|off | undo | redo | list | at <seconds> | still <file.png> | export <file.mp4> | time [frames]\n";

int main(int argc, char** argv) {
    if (argc < 2) return std::printf("FAIL edit <document>\n"), 1;
    int wide = 1080, high = 1920;   // (a new document's size; SIZE=1920x1080 for another: one that says its own is opened at it)
    if (const char* size = std::getenv("SIZE")) std::sscanf(size, "%dx%d", &wide, &high);
    Motolii* m = motolii_open(argv[1], wide, high);
    if (!m) return std::printf("FAIL the document could not be opened\n"), 1;
    for (std::string line; std::getline(std::cin, line);) try {
        std::istringstream said(line);
        std::vector<std::string> w;
        for (std::string word; said >> word;) w.push_back(word);
        if (w.empty()) continue;
        const std::string& call = w[0];
        bool numbers = true;   // (whether every word asked for as a number was one)
        const auto number = [&](size_t i) { char* end = nullptr; const double is = std::strtod(w[i].c_str(), &end); if (*end || !std::isfinite(is)) numbers = false; return is; };
        const auto layer = [&] { const double n = number(1); return numbers && n == std::floor(n) ? (int)n : (numbers = false, 0); };
        const auto rest = [&](size_t i) { size_t at = 0; for (size_t k = 0; k < i; ++k) at = line.find(w[k], at) + w[k].size(); return line.substr(line.find(w[i], at)); };   // (from that word to the end of the line)
        const auto t0 = std::chrono::steady_clock::now();
        int ok = 1;
        bool known = true;
        if (call == "add" && w.size() >= 3) { if ((ok = motolii_add(m, w[1].c_str(), rest(2).c_str()))) std::printf("thing %d\n", ok); }   // (a file's name may have spaces)
        else if (call == "brush" && w.size() >= 9) {   // (a brush's stroke as the window gives it: its tool (0 pen, 1 brush, 2 fill), how wide, then x y pressure each, points of the picture)
            const int ticket = motolii_later(m, "brush", 0, "", rest(1).c_str(), 0);
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
            if (ok) std::printf("thing %d\n", ok);
        }
        else if (call == "later" && w.size() >= 3) {   // (any change the window asks later: its call, the thing, then its word, as motolii_later takes them)
            const int n = (int)number(2), ticket = numbers ? motolii_later(m, w[1].c_str(), n, "", w.size() > 3 ? rest(3).c_str() : "", 0) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "split" && w.size() == 3) {   // (Split at a moment, as the window's thing menu asks it)
            const int n = layer();
            const double at = number(2);
            const int ticket = numbers ? motolii_later(m, "split", n, "", "", at) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "outline" && w.size() == 2) {   // (Convert to Outline, as the window's thing menu asks it)
            const int n = layer(), ticket = numbers ? motolii_later(m, "outline", n, "", "", 0) : 0;
            while (numbers && (ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "remove" && w.size() == 2) { const int n = layer(); if (numbers) ok = motolii_remove(m, n); }
        else if (call == "set" && w.size() == 4) {
            const int n = layer(), keys = numbers ? motolii_keys(m, n, w[2].c_str()) : 0;
            const double is = number(3);
            if (numbers && (ok = motolii_set(m, n, w[2].c_str(), is)) && keys) std::printf("(its %d keys are gone: it stays at that)\n", keys);
        }
        else if (call == "pen" && (w.size() == 4 || w.size() == 6)) { const int n = layer(); const double x = number(2), y = number(3), hx = w.size() == 6 ? number(4) : 0, hy = w.size() == 6 ? number(5) : 0; if (numbers && (ok = motolii_pen(m, n, x, y, hx, hy))) std::printf("thing %d\n", ok); }
        else if (call == "points" && w.size() == 2) { const int n = layer(); double xy[256]; const int k = numbers ? motolii_points(m, n, xy, 128) : 0; for (int i = 0; i < k && i < 128; ++i) std::printf("  %.1f %.1f\n", xy[2 * i], xy[2 * i + 1]); ok = k > 0; }
        else if (call == "handles" && w.size() == 2) { const int n = layer(); double xy[256]; const int k = numbers ? motolii_handles(m, n, xy, nullptr, 128) : 0; for (int i = 0; i < k && i < 128; ++i) std::printf("  %.1f %.1f\n", xy[2 * i], xy[2 * i + 1]); ok = k > 0; }
        else if (call == "drag_start" && w.size() == 2) { const int n = layer(); if (numbers) ok = motolii_drag_start(m, n); }
        else if (call == "drag_update" && w.size() >= 3 && w[1] == "effect") {   // (an effect file shown on the held thing, not kept: the shelf's tile under the hand)
            const int ticket = motolii_later(m, "drag_update", 0, "effect", rest(2).c_str(), 0);
            while ((ok = motolii_answer(m, ticket)) < 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        else if (call == "drag_update" && w.size() == 4) { const double a = number(2), b = number(3); if (numbers) ok = motolii_drag_update(m, w[1].c_str(), a, b); }
        else if (call == "drag_end" && w.size() == 2) ok = motolii_drag_end(m, w[1] != "0");
        else if (call == "say" && w.size() >= 3) { const int n = layer(); if (numbers) ok = motolii_say(m, n, w[2].c_str(), w.size() > 3 ? rest(3).c_str() : ""); }   // (a text's words are the rest of the line; none: said empty)
        else if (call == "midi" && w.size() >= 7) { const int n = layer(); const int ch = (int)number(4); const double bpm = number(5); if (numbers) ok = motolii_midi(m, n, w[2].c_str(), rest(6).c_str(), w[3].c_str(), ch, bpm); }   // (midi <thing> <name> <kind> <channel, -1: any> <bpm, 0: the file's> <file.mid>)
        else if (call == "key" && w.size() == 5) { const int n = layer(); const double at = number(3), is = number(4); if (numbers) ok = motolii_key(m, n, w[2].c_str(), at, is); }
        else if (call == "keys" && w.size() >= 5 && w.size() % 2 == 1) {   // (keys <thing> <name> <at> <value> <at> <value> ...: motolii_key_many, one statement made ready once)
            const int n = layer();
            std::vector<double> at, is;
            for (size_t i = 3; i + 1 < w.size(); i += 2) at.push_back(number(i)), is.push_back(number(i + 1));
            if (numbers) ok = motolii_key_many(m, n, w[2].c_str(), (int)at.size(), at.data(), is.data());
        }
        else if (call == "unkey" && w.size() == 4) { const int n = layer(); const double at = number(3); if (numbers) ok = motolii_unkey(m, n, w[2].c_str(), at); }
        else if (call == "easing" && w.size() >= 5) { const int n = layer(); const double at = number(3); if (numbers) ok = motolii_easing(m, n, w[2].c_str(), at, rest(4).c_str()); }   // (the stretch from that key on)
        else if (call == "define" && w.size() >= 3) ok = motolii_define(m, w[1].c_str(), rest(2).c_str());
        else if (call == "easings" && w.size() == 1) { std::printf("  %s\n", motolii_easings(m)); continue; }
        else if (call == "cards" && w.size() == 2) { const int n = layer(); if (numbers) std::printf("  %s\n", motolii_cards(m, n)); continue; }   // (a thing's cards as the inspector lays them: "title: names; ...")
        else if (call == "value" && w.size() == 4) { const int n = layer(); const double at = number(3); double is = 0; if (numbers && (ok = motolii_value(m, n, w[2].c_str(), at, &is))) { std::printf("  %.4f\n", is); continue; } }
        else if (call == "create" && w.size() >= 2) ok = motolii_create(m, rest(1).c_str()) != 0;
        else if (call == "effect" && w.size() >= 3) { const int n = layer(); if (numbers) ok = motolii_effect(m, n, rest(2).c_str(), motolii_now(m)); }   // (an effect's name may have spaces)
        else if (call == "effects" && w.size() == 1) { std::printf("%s\n", motolii_effect_names(m)); continue; }
        else if (call == "preset" && w.size() >= 4 && (w[1] == "save" || w[1] == "apply")) { const int n = std::atoi(w[2].c_str()); ok = w[1] == "save" ? motolii_preset_save(m, n, rest(3).c_str()) : motolii_preset_apply(m, n, rest(3).c_str()); }   // (a file's name may have spaces)
        else if (call == "presets" && w.size() == 1) { std::printf("%s\n", motolii_presets(m)); continue; }
        else if (call == "shelf" && w.size() == 1) { std::printf("%s\n", motolii_effects(m)); continue; }   // (the effect files on the shelf, AviUtl2's scripts too)
        else if (call == "find" && w.size() >= 2) {   // (the shelf's effects nearest the words first, by name, label and what each does: motolii_find, RapidFuzz)
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
            // (and what Motolii has, as its ledger and the golf's record say it (ASSETS.md's rows, golf_noise.md's
            //  entries): a feature there and forgotten is found before it is said not to be (the user, 10/30). The
            //  lines with the words as typed first, as the shelves' plain hits; then the nearest by motolii_find)
            std::string words = rest(1), lower = words, lines, said;
            std::transform(lower.begin(), lower.end(), lower.begin(), [](unsigned char c) { return (char)std::tolower(c); });
            int plain = 0;
            for (const char* book : {"../../../docs/internal/reports/effects/golf_noise.md"}) {   // (from out/filament_webgpu, where edit.sh runs this)
                std::ifstream in(book);
                int n = 0;
                for (std::string l; std::getline(in, l);) {
                    ++n;
                    if (l.rfind("| ", 0) != 0 && l.rfind("- [", 0) != 0) continue;
                    const std::string id = std::string(book).substr(std::string(book).rfind('/') + 1) + ":" + std::to_string(n);
                    std::string low = l;
                    std::transform(low.begin(), low.end(), low.begin(), [](unsigned char c) { return (char)std::tolower(c); });
                    const size_t colon = l.find("\xEF\xBC\x9A");   // (its head: up to the first full-width colon)
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
        else if (call == "changed" && w.size() == 1) { motolii_files_changed(); continue; }   // (files written, put in or taken out: read again at their next use)
        else if (call == "create_scripts" && w.size() == 1) { std::printf("  %s\n", motolii_create_scripts(m)); continue; }
        else if (call == "together" && w.size() == 2) ok = motolii_together(m, w[1] == "on" ? 1 : 0) || w[1] == "on";   // (the calls between are one step, the stage matched once at the end)
        else if (call == "undo" && w.size() == 1) ok = motolii_undo(m);
        else if (call == "redo" && w.size() == 1) ok = motolii_redo(m);
        else if (call == "at" && w.size() == 2) { const double at = number(1); if (numbers) ok = motolii_at(m, at); }
        else if (call == "still" && w.size() >= 2) ok = motolii_still(m, rest(1).c_str());
        else if (call == "poster" && w.size() >= 2) ok = motolii_poster(m, rest(1).c_str());   // (the document's own picture, kept in it: motolii_poster)
        else if (call == "properties" && w.size() >= 2) std::printf("%s\n", motolii_doc_properties(w[1].c_str(), w.size() >= 3 ? w[2].c_str() : nullptr));   // (facts doc [png]: paths without spaces)
        else if (call == "export" && w.size() >= 2) ok = motolii_export(m, rest(1).c_str());
        else if (call == "pack" && w.size() >= 3) { const int n = motolii_pack(m, w[1].c_str(), rest(2).c_str()); ok = n >= 0; if (ok) std::printf("  %d files\n", n); }
        else if (call == "time" && w.size() <= 2) { const double n = w.size() == 2 ? number(1) : 120; if (numbers) motolii_timed(m, (int)n); }   // (so many pictures, 1/60 s apart: more for a steadier number)
        else if (call == "help") { std::printf("%s", calls); continue; }
        else if (call == "list" && w.size() == 1) { std::printf("%s  (the document runs %.2f seconds)\n", motolii_list(m), motolii_seconds(m)); continue; }
        else known = false;
        if (!known || !numbers) std::printf("not a call: %s\n%s", line.c_str(), !numbers ? "  (a number was asked for where a word stands)\n" : calls);
        else std::printf("%s: %s, %.1f ms\n", call.c_str(), ok ? "done" : (std::string("NOT done: ") + motolii_error(m)).c_str(), std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
        std::fflush(stdout);
    } catch (const std::exception& e) {   // (what the inside could not get past: said, and the end)
        std::printf("FAIL %s: %s\n", line.c_str(), e.what());
        return 1;
    }
    motolii_close(m);
    return 0;
}

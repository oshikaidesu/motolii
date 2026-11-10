#include "document/edit/layer_edit.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

#include <sqlite3.h>

#include "document/card_table.h"
#include "document/cards.h"
#include "document/scripts/expressions.h"
#include "document/evaluate/fx_list.h"
#include "document/edit/fx_put.h"
#include "document/edit/keys_put.h"
#include "document/edit/parent.h"
#include "document/scripts/recipes.h"
#include "document/edit/relate.h"
#include "document/evaluate/relations.h"
#include "document/scripts/scripts.h"
#include "document/evaluate/shown.h"
#include "document/undo.h"
#include "document/evaluate/value_at.h"

bool doc_knows(Doc& d, int layer, const char* name, const double* number, const char* word, bool key) {
    const std::string kind = doc_word(d, layer, "kind");
    if (kind.empty()) return d.error = "there is no layer " + std::to_string(layer), false;
    if (!name) return true;
    const DocValue* v = nullptr;
    for (const DocValue& one : doc_values)
        if (!strcmp(one.name, name) && doc_among(one.kinds, kind)) { v = &one; break; }
    // A value connected to a behavior: `<name>_by` is that behavior, and 0 means none.
    static const DocValue by{"_by", "video image text solid shape camera light behaviour", 0, 1e9, false, nullptr};
    if (!v && strlen(name) > 3 && !strcmp(name + strlen(name) - 3, "_by")) {
        const std::string base(name, strlen(name) - 3);
        for (const DocValue& one : doc_values)
            if (base == one.name && doc_among(one.kinds, kind) && !one.words) v = &by;
        if (v && number && *number != 0.0 && (*number != std::floor(*number) || doc_word(d, (int)*number, "kind") != "behaviour")) return d.error = std::string(name) + " is a behaviour that is there", false;
    }
    // The keys of a value gone through again past the last one: `<name>_loop` (see doc_keys_at).
    static const DocValue looped{"_loop", "video image text solid shape camera light behaviour stage", 0, 0, false, "none cycle pingpong offset"};
    if (!v && strlen(name) > 5 && !strcmp(name + strlen(name) - 5, "_loop")) {
        const std::string base(name, strlen(name) - 5);
        if (doc_knows(d, layer, base.c_str())) v = &looped;
        d.error.clear();
    }
    // A parameter of the layer's script, or of a camera's motion.
    if (!v && !strncmp(name, "js_", 3) && doc_among("video image text shape solid stage camera behaviour", kind))
        for (const DocScript* sc : doc_scripts_on(d, layer))
            for (const DocValue& one : sc->values)
                if (!strcmp(one.name, name)) v = &one;
    // Returns the names the kind has, or only those that can move. Used only to explain a refused
    // call.
    const auto said = [&](bool moves) {
        std::string all;
        for (const DocValue& one : doc_values)
            if (doc_among(one.kinds, kind) && (!moves || one.moves)) all += std::string(all.empty() ? "" : ", ") + one.name;
        if (doc_among("video image text shape solid stage camera behaviour", kind))
            for (const DocScript* sc : doc_scripts_on(d, layer))
                for (const DocValue& one : sc->values)
                    if (!moves || one.moves) all += std::string(all.empty() ? "" : ", ") + one.name;
        return all;
    };
    char range[120];
    if (!v) return d.error = "a " + kind + " has no " + name + ": it has " + said(false), false;
    if (number && v->words) return d.error = std::string(name) + " is a word, told by say" + (*v->words ? std::string(": ") + v->words : ""), false;
    if (word && !v->words) return d.error = std::string(name) + " is a number, told by set", false;
    if (word && *v->words && !doc_among(v->words, word)) return d.error = std::string(name) + " is one of: " + v->words, false;
    // A name that the layer's file has.
    if (word && *word && (!strcmp(name, "marker") || !strcmp(name, "animation"))) {
        const std::string has = doc_words(d, layer, name);
        if (has.empty()) return d.error = std::string("its file has no ") + (!strcmp(name, "marker") ? "markers" : "movements of its own"), false;
        if (!doc_among(has.c_str(), word)) return d.error = std::string(name) + " is one of: " + has, false;
    }
    // copy_tall is numbers, one for each copy in their order.
    if (word && *word && !strcmp(name, "copy_tall") && strcmp(word, "none")) {
        std::istringstream all(word);
        for (std::string one; all >> one;) { char* end = nullptr; const double is = std::strtod(one.c_str(), &end); if (*end || !std::isfinite(is)) return d.error = "copy_tall is numbers, one for each copy, as 1 2.5 0.8", false; }
    }
    // copy_fill is colors of six hex digits each. none means the copies are not colored
    // individually.
    if (word && *word && !strcmp(name, "copy_fill") && strcmp(word, "none")) {
        std::istringstream all(word);
        int n = 0;
        for (std::string one; all >> one; ++n)
            if (one.size() != 6 || one.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos) return d.error = "copy_fill is colours of six digits, as ff3366 1b2fd8", false;
        if (n < 1) return d.error = "copy_fill is colours of six digits, as ff3366 1b2fd8, or none", false;
    }
    // One color: six hex digits.
    if (word && *word && (doc_among("vignette_color fog_color background bevel_color side_color back_color stroke_2 stroke_3", name) || (!strcmp(name, "fill") && kind == "light")))
        if (strlen(word) != 6 || strspn(word, "0123456789abcdefABCDEF") != 6) return d.error = std::string(name) + " is six digits, as ff3366", false;
    // low and high say how far a control goes, not how far the user may go. A number typed, keyed
    // or set beyond them is accepted, as After Effects' Slider Control accepts values past its
    // Slider Range and Cavalry accepts values past its slider. A value is held to its range only
    // where a named source holds the same value so. A switch is on or off, like After Effects'
    // layer switches Video, Solo and Lock, each a box that is ticked or not. An opacity is from
    // none to whole: After Effects' Opacity is 0 to 100%, and so are the End Opacity of its Drop
    // Shadow and of its Repeater. An alpha is 0 to 1 in Porter and Duff's compositing, 1984.
    const bool flag = doc_among("keyed clip visible solo lock shadows clip_invert", name), held = doc_among("opacity shadow_opacity glow_opacity copy_opacity_end", name);
    if (number && (!std::isfinite(*number) || (flag && *number != 0.0 && *number != 1.0) || (held && (*number < v->low || *number > v->high))))
        return std::snprintf(range, sizeof range, flag ? " is 0 or 1" : !std::isfinite(*number) ? " is a number" : " is from %g to %g", v->low, v->high), d.error = name + std::string(range), false;
    if (key && !v->moves) { const std::string moving = said(true); return d.error = std::string(name) + " does not move: " + (moving.empty() ? std::string("nothing of it does") : "keys go on " + moving), false; }
    if ((number || word || key) && strcmp(name, "lock") && doc_number(d, layer, "lock", 0, 0) > 0.5) return d.error = "it is locked", false;
    if (number && (!strcmp(name, "connect") || !strcmp(name, "connect_to")) && *number != 0.0 && (*number != std::floor(*number) || (int)*number == layer || doc_word(d, (int)*number, "kind").empty()))
        // As for a parent, it must be a layer that exists.
        return d.error = std::string(name) + " is another layer that is there", false;
    // A parent is a layer that exists, and not the layer itself nor one that is parented to it.
    if (number && !strcmp(name, "parent") && *number != 0.0) {
        const int to = (int)*number;
        if (to != *number || doc_word(d, to, "kind").empty()) return d.error = "a parent is a layer that is there", false;
        for (int up = to, n = 0; up && n < 1000; up = (int)doc_number(d, up, "parent", 0, 0), ++n)
            if (up == layer) return d.error = "a layer cannot go with itself, nor with one that goes with it", false;
    }
    return true;
}

const char* doc_kind_of(const char* file) {
    static const struct { const char* kind; const char* ends; } made[] = {
        {"video", "mp4 mov m4v webm mkv"}, {"sound", "mp3 wav m4a aac flac ogg opus"}, {"image", "png jpg jpeg webp svg json lot mid js"}, {"solid", "glb gltf ply"}, {"text", "ttf otf ttc"}};
    std::string end = std::filesystem::path(file).extension().string();
    for (char& c : end) c = (char)std::tolower((unsigned char)c);
    if (doc_among(doc_shapes, file)) return "solid";
    if (doc_among("rect circle polygon star line null ring arc arrow squircle cog path spiral chamfer", file)) return "shape";
    for (const auto& one : made)
        if (end.size() > 1 && doc_among(one.ends, end.substr(1))) return one.kind;
    return "";
}
int doc_add(Doc& d, const char* kind, const char* file) {
    // No kind was given, so the file decides.
    if (!*kind) kind = doc_kind_of(file);
    if (!*kind) return d.error = std::string("no kind of layer is made from ") + file, 0;
    // A sound is added as a hidden video that is heard. Alight Motion's audio layer has no image,
    // only its wave on the timeline (docs/internal/reports/alight_motion/alight_ui.md line 177),
    // and Extract Sound's copy (doc_extract_sound) is likewise a hidden video that is heard. Its
    // visibility switch shows its wave (video_layer.h).
    const bool sound = !strcmp(kind, "sound");
    if (sound) kind = "video";
    // The old kind names film and picture are still accepted.
    else if (!strcmp(kind, "film")) kind = "video";
    else if (!strcmp(kind, "picture")) kind = "image";
    if (!doc_among(doc_kinds, kind) && strcmp(kind, "behaviour")) return d.error = std::string("a layer is one of: ") + doc_kinds + " behaviour", 0;
    if (!strcmp(kind, "behaviour") && !doc_among("stagger oscillator noise random around row follow push group relate", file)) return d.error = "a behaviour is a stagger, an oscillator, a noise, a random, or a relation: around, row, follow, push", 0;
    if (!strcmp(kind, "light") && !doc_among("sun point spot", file)) return d.error = "a light is a sun, a point or a spot", 0;
    // The layer comes on at the stage's present time, the playhead, as in AbsentMotion's addAudio
    // and addText: startTime is frameStart(frame).
    if (!doc_change(d, sqlite3_mprintf("insert into layer default values; insert into keyframe(layer, name, at, value) values(last_insert_rowid(), 'kind', 0.0, %Q); insert into keyframe(layer, name, at, value) values(last_insert_rowid(), %Q, 0.0, %Q); insert into keyframe(layer, name, at, value) select id, 'start', 0.0, %!.17g from layer where %d order by id desc limit 1%s",
                                       kind, (!strcmp(kind, "solid") && doc_among(doc_shapes, file)) || !strcmp(kind, "shape") ? "shape" : "file", file, d.stage->now, d.stage->now > 0.0,
                                       // A new text comes with a word to read, at a size that fits
                                       // a stage, in the gray that AbsentMotion's addText fills one
                                       // with: TextActions.kt withFill 0xFF7F7F7F.
                                       (std::string(strcmp(kind, "text") ? "" : "; insert into keyframe(layer, name, at, value) select id, 'text', 0.0, 'Text' from layer order by id desc limit 1; insert into keyframe(layer, name, at, value) select id, 'size', 0.0, 0.5 from layer order by id desc limit 1; insert into keyframe(layer, name, at, value) select id, 'fill', 0.0, '7f7f7f' from layer order by id desc limit 1") +
                                        // The layer lasts as long as the project's layer_length
                                        // setting says, if it is set: AbsentMotion's New Layer
                                        // Length, see its StructureActions.kt and TextActions.kt
                                        // endTimeFor. A video lasts its own length, and a group's
                                        // Null as long as what it holds.
                                        (doc_among("image text solid shape", kind) && strcmp(file, "null") ? "; insert into keyframe(layer, name, at, value) select (select max(id) from layer), 'duration', 0.0, value from keyframe where layer = 0 and name = 'layer_length' and at = 0 and value > 0" : "") +
                                        (sound ? "; insert into keyframe(layer, name, at, value) select max(id), 'visible', 0.0, 0 from layer" : "")).c_str()))) return 0;
    // The newest number, from SQLite's own count of layers, which a change that was not made does
    // not move.
    int layer = 0;
    doc_rows(d, sqlite3_mprintf("select max(id) from layer"), [&](sqlite3_stmt* row) { layer = sqlite3_column_int(row, 0); });
    return layer;
}
int doc_duplicate(Doc& d, int layer) {
    if (!doc_knows(d, layer)) return d.error = "that is no layer", 0;
    if (!doc_change(d, sqlite3_mprintf("insert into layer default values; insert into keyframe(layer, name, at, value, easing) select last_insert_rowid(), name, at, value, easing from keyframe where layer = %d;", layer))) return 0;
    int made = 0;
    doc_rows(d, sqlite3_mprintf("select max(id) from layer"), [&](sqlite3_stmt* row) { made = sqlite3_column_int(row, 0); });
    return made;
}
bool doc_remove(Doc& d, int layer) {
    if (doc_knows(d, layer) && doc_number(d, layer, "lock", 0, 0) > 0.5) return d.error = "it is locked", false;
    // A leader is being removed: the layers it led stay where they show, as After Effects keeps a
    // child where it is when its parent goes.
    if (doc_knows(d, layer) && doc_word(d, layer, "kind") != "behaviour") {
        std::vector<int> led;
        for (const int r : doc_layers(d))
            if (doc_word(d, r, "kind") == "behaviour" && doc_among(doc_relations, doc_word(d, r, "file")) && ((int)doc_number(d, r, "leader", 0, 0) == layer || (int)doc_number(d, r, "leader_b", 0, 0) == layer)) led.push_back(r);
        if (!led.empty()) {
            doc_act(d);
            bool ok = true;
            for (const int r : led) ok = ok && doc_release(d, r, d.stage ? d.stage->now : 0.0);
            ok = ok && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d", layer));
            return doc_acted(d) && ok;
        }
    }
    // A relation is being removed: its layers go back to what is under them, as when a constraint
    // is deleted in Blender. doc_release would keep them where they show instead.
    if (doc_knows(d, layer) && doc_among(doc_relations, doc_word(d, layer, "file")) && doc_word(d, layer, "kind") == "behaviour") {
        const std::vector<int> all = doc_members_of(d, layer);
        doc_act(d);
        bool ok = true;
        for (const int t : all) if (ok && t) ok = doc_free(d, t, layer, d.stage ? d.stage->now : 0.0, false);
        ok = ok && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d", layer));
        return doc_acted(d) && ok;
    }
    return doc_knows(d, layer) && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d", layer)); }
bool doc_leading = false;
bool doc_set(Doc& d, int layer, const char* name, double is) {
    if (!strcmp(name, "parent")) return doc_parent(d, layer, is);
    // A relation's leader changed by any caller goes through doc_lead, so that nothing jumps.
    if (!strcmp(name, "leader") && !doc_leading && is >= 1 && doc_word(d, layer, "kind") == "behaviour" && doc_among(doc_relations, doc_word(d, layer, "file")) && !doc_word(d, layer, "members").empty())
        return doc_lead(d, layer, (int)is, d.stage ? d.stage->now : 0.0);
    return doc_knows(d, layer, name, &is) && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q and at <> 0; insert into keyframe(layer, name, at, value) values(%d, %Q, 0.0, %!.17g) on conflict do update set value = excluded.value, easing = null", layer, name, layer, name, is));
}
bool doc_say(Doc& d, int layer, const char* name, const char* word) {
    // A script given by the name of a recipe resolves to its file, so a preset or a tile can use
    // "Repeater" with no path.
    if (!strcmp(name, "script") && word && *word && !strchr(word, '/')) {
        if (const std::string file = doc_recipe_code_path(word); !file.empty()) return doc_say(d, layer, name, file.c_str());
    }
    // An expression is put among the layer's effects after those it has, as many as it is given
    // (docs/internal/notes/CREATE_PROGRAM.md). If it is already there, it stays as it is.
    if (!strcmp(name, "script") && word && layer != 0 && doc_among("image text shape solid", doc_word(d, layer, "kind")) && doc_expression(d, word)) {
        std::vector<std::string> list = doc_fx_list(d, layer, true);
        if (std::find(list.begin(), list.end(), word) != list.end()) return true;
        list.push_back(word);
        return doc_fx_say(d, layer, list);
    }
    // Alight Motion's Fill is one of a color, a gradient or media. A color takes the place of the
    // image.
    if (!strcmp(name, "fill") && !doc_word(d, layer, "fill_media").empty()) {
        doc_act(d);
        doc_say(d, layer, "fill_media", ""), doc_say(d, layer, name, word);
        return doc_acted(d);
    }
    if (doc_knows(d, layer, name, nullptr, word)) {
        DocScript* sc = !strcmp(name, "script") && doc_word(d, layer, "kind") == "solid" ? doc_script_of(d, word) : nullptr;
        if (!sc || !sc->run || !sc->run->sketch() || !sc->run->ok()) return doc_change(d, sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(%d, %Q, 0.0, %Q) on conflict do update set value = excluded.value", layer, name, word));
        // A sketch given to a solid: set as many copies as the shape it draws needs.
        doc_act(d);
        doc_change(d, sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(%d, %Q, 0.0, %Q) on conflict do update set value = excluded.value", layer, name, word));
        // A scene's parts have their own shapes (adapter.h). A sketch's one mesh is all it draws
        // (sketch.h).
        if (const std::string shape = sc->run->shape(); !shape.empty()) doc_say(d, layer, "shape", shape.c_str()), doc_set(d, layer, "copies", shape == "sketch" ? 1 : sc->run->most());
        return doc_acted(d);
    }
    // An effect's color is ISF's one input that Motolii holds as three numbers and an alpha
    // (isf.cpp: _x, _y, _z, _w). It is set as one color, as the Colors shelf sets a color to a
    // card's value. Each component is put at the stage's current time by the rule for a changed
    // value, with a keyframe there if the value has keyframes (doc_put). The alpha stays as it was.
    // After Effects' and Alight Motion's effect color is one color.
    const std::string base(name), hex(word), why = d.error;
    if (hex.size() != 6 || hex.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos || !doc_knows(d, layer, (base + "_x").c_str())) return d.error = why, false;
    doc_act(d);
    for (int i = 0; i < 3; ++i) doc_put(d, layer, (base + "_" + "xyz"[i]).c_str(), d.stage ? d.stage->now : 0.0, std::stoi(hex.substr(2 * (size_t)i, 2), nullptr, 16) / 255.0);
    return doc_acted(d);
}

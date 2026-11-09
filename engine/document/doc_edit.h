// doc_edit.h: part of doc.h (things added, made again, freed, removed; values and words said). Read only through doc.h.
static bool doc_knows(Doc& d, int thing, const char* name = nullptr, const double* number = nullptr, const char* word = nullptr, bool key = false) {
    const std::string kind = doc_word(d, thing, "kind");
    if (kind.empty()) return d.trouble = "there is no thing " + std::to_string(thing), false;
    if (!name) return true;
    const DocValue* v = nullptr;
    for (const DocValue& one : doc_values)
        if (!strcmp(one.name, name) && doc_among(one.kinds, kind)) { v = &one; break; }
    static const DocValue by{"_by", "film picture text solid shape camera light behaviour", 0, 1e9, false, nullptr};   // (a value connected to a behaviour: `<name>_by` = that behaviour, 0 none)
    if (!v && strlen(name) > 3 && !strcmp(name + strlen(name) - 3, "_by")) {
        const std::string base(name, strlen(name) - 3);
        for (const DocValue& one : doc_values)
            if (base == one.name && doc_among(one.kinds, kind) && !one.words) v = &by;
        if (v && number && *number != 0.0 && (*number != std::floor(*number) || doc_word(d, (int)*number, "kind") != "behaviour")) return d.trouble = std::string(name) + " is a behaviour that is there", false;
    }
    static const DocValue looped{"_loop", "film picture text solid shape camera light behaviour stage", 0, 0, false, "none cycle pingpong offset"};   // (its keys gone through again past the last: `<name>_loop`, doc_keys_at)
    if (!v && strlen(name) > 5 && !strcmp(name + strlen(name) - 5, "_loop")) {
        const std::string base(name, strlen(name) - 5);
        if (doc_knows(d, thing, base.c_str())) v = &looped;
        d.trouble.clear();
    }
    if (!v && !strncmp(name, "js_", 3) && doc_among("film picture text shape solid stage camera behaviour", kind))   // (a knob of the thing's script; a camera's motion's, golf ㊴)
        for (const DocScript* sc : doc_scripts_on(d, thing))
            for (const DocValue& one : sc->values)
                if (!strcmp(one.name, name)) v = &one;
    const auto said = [&](bool moves) {   // (the names it has, or those that move: said only when a call is refused)
        std::string all;
        for (const DocValue& one : doc_values)
            if (doc_among(one.kinds, kind) && (!moves || one.moves)) all += std::string(all.empty() ? "" : ", ") + one.name;
        if (doc_among("film picture text shape solid stage camera behaviour", kind))
            for (const DocScript* sc : doc_scripts_on(d, thing))
                for (const DocValue& one : sc->values)
                    if (!moves || one.moves) all += std::string(all.empty() ? "" : ", ") + one.name;
        return all;
    };
    char range[120];
    if (!v) return d.trouble = "a " + kind + " has no " + name + ": it has " + said(false), false;
    if (number && v->words) return d.trouble = std::string(name) + " is a word, told by say" + (*v->words ? std::string(": ") + v->words : ""), false;
    if (word && !v->words) return d.trouble = std::string(name) + " is a number, told by set", false;
    if (word && *v->words && !doc_among(v->words, word)) return d.trouble = std::string(name) + " is one of: " + v->words, false;
    if (word && *word && (!strcmp(name, "marker") || !strcmp(name, "animation"))) {   // (a name its file has)
        const std::string has = doc_words(d, thing, name);
        if (has.empty()) return d.trouble = std::string("its file has no ") + (!strcmp(name, "marker") ? "markers" : "movements of its own"), false;
        if (!doc_among(has.c_str(), word)) return d.trouble = std::string(name) + " is one of: " + has, false;
    }
    if (word && *word && !strcmp(name, "copy_tall") && strcmp(word, "none")) {   // (numbers, one for each copy in their order)
        std::istringstream all(word);
        for (std::string one; all >> one;) { char* end = nullptr; const double is = std::strtod(one.c_str(), &end); if (*end || !std::isfinite(is)) return d.trouble = "copy_tall is numbers, one for each copy, as 1 2.5 0.8", false; }
    }
    if (word && *word && !strcmp(name, "copy_fill") && strcmp(word, "none")) {   // (colours, six digits each; none: not coloured each)
        std::istringstream all(word);
        int n = 0;
        for (std::string one; all >> one; ++n)
            if (one.size() != 6 || one.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos) return d.trouble = "copy_fill is colours of six digits, as ff3366 1b2fd8", false;
        if (n < 1) return d.trouble = "copy_fill is colours of six digits, as ff3366 1b2fd8, or none", false;
    }
    if (word && *word && (doc_among("vignette_color fog_color background bevel_color side_color back_color stroke_2 stroke_3", name) || (!strcmp(name, "fill") && kind == "light")))   // (one colour: six digits)
        if (strlen(word) != 6 || strspn(word, "0123456789abcdefABCDEF") != 6) return d.trouble = std::string(name) + " is six digits, as ff3366", false;
    // (low and high are how far its knob goes, not how far a hand may: a number typed, keyed or set past them is taken,
    //  as After Effects' Slider Control takes past its Slider Range and Cavalry past its slider. Held to them only where
    //  a named source holds the same value so: a switch is on or off (After Effects' layer switches: Video, Solo, Lock,
    //  each a box ticked or not); an opacity is from none to whole (After Effects' Opacity, 0 to 100%; its Drop Shadow's
    //  and Repeater's End Opacity alike; an alpha is 0 to 1 in Porter and Duff's compositing, 1984))
    const bool flag = doc_among("keyed clip visible solo lock shadows clip_invert", name), held = doc_among("opacity shadow_opacity glow_opacity copy_opacity_end", name);
    if (number && (!std::isfinite(*number) || (flag && *number != 0.0 && *number != 1.0) || (held && (*number < v->low || *number > v->high))))
        return std::snprintf(range, sizeof range, flag ? " is 0 or 1" : !std::isfinite(*number) ? " is a number" : " is from %g to %g", v->low, v->high), d.trouble = name + std::string(range), false;
    if (key && !v->moves) { const std::string moving = said(true); return d.trouble = std::string(name) + " does not move: " + (moving.empty() ? std::string("nothing of it does") : "keys go on " + moving), false; }
    if ((number || word || key) && strcmp(name, "lock") && doc_number(d, thing, "lock", 0, 0) > 0.5) return d.trouble = "it is locked", false;
    if (number && (!strcmp(name, "connect") || !strcmp(name, "connect_to")) && *number != 0.0 && (*number != std::floor(*number) || (int)*number == thing || doc_word(d, (int)*number, "kind").empty()))
        return d.trouble = std::string(name) + " is another thing that is there", false;   // (as a parent is)
    if (number && !strcmp(name, "parent") && *number != 0.0) {   // (a parent is a thing that is there, and not the thing itself nor one that goes with it: the past repository's rule)
        const int to = (int)*number;
        if (to != *number || doc_word(d, to, "kind").empty()) return d.trouble = "a parent is a thing that is there", false;
        for (int up = to, n = 0; up && n < 1000; up = (int)doc_number(d, up, "parent", 0, 0), ++n)
            if (up == thing) return d.trouble = "a thing cannot go with itself, nor with one that goes with it", false;
    }
    return true;
}

// The calls. A new thing of a kind (film, picture, text, solid) from a file (a text: its font; a solid: a file, or ring, gem or cube): its number (0: not
// made, and no number is used up).
// What kind of thing a file makes, by its name's end ("": none): the one place that says so. A sound is a film heard and
// not seen (doc_add).
static const char* doc_kind_of(const char* file) {
    static const struct { const char* kind; const char* ends; } made[] = {
        {"film", "mp4 mov m4v webm mkv"}, {"sound", "mp3 wav m4a aac flac ogg opus"}, {"picture", "png jpg jpeg webp svg json lot mid js"}, {"solid", "glb gltf ply"}, {"text", "ttf otf ttc"}};
    std::string end = std::filesystem::path(file).extension().string();
    for (char& c : end) c = (char)std::tolower((unsigned char)c);
    if (doc_among(doc_shapes, file)) return "solid";
    if (doc_among("rect circle polygon star line null ring arc arrow squircle cog path spiral chamfer", file)) return "shape";
    for (const auto& one : made)
        if (end.size() > 1 && doc_among(one.ends, end.substr(1))) return one.kind;
    return "";
}
static int doc_add(Doc& d, const char* kind, const char* file) {
    if (!*kind) kind = doc_kind_of(file);   // (not said: what the file makes)
    if (!*kind) return d.trouble = std::string("no kind of thing is made from ") + file, 0;
    // (a sound comes in a film that is heard, hidden: Alight Motion's audio layer has no picture, only its wave on the
    //  timeline (docs/internal/reports/alight_motion/alight_ui.md 177), as Extract Sound's copy (doc_extract_sound) is a hidden film heard; its eye
    //  shows its wave, video.h)
    const bool sound = !strcmp(kind, "sound");
    if (sound) kind = "film";
    if (!doc_among(doc_kinds, kind) && strcmp(kind, "behaviour")) return d.trouble = std::string("a thing is one of: ") + doc_kinds + " behaviour", 0;
    if (!strcmp(kind, "behaviour") && !doc_among("stagger oscillator noise random around row follow push group relate", file)) return d.trouble = "a behaviour is a stagger, an oscillator, a noise, a random, or a relation: around, row, follow, push", 0;
    if (!strcmp(kind, "light") && !doc_among("sun point spot", file)) return d.trouble = "a light is a sun, a point or a spot", 0;
    // (it comes on at the stage's present moment, the playhead: AbsentMotion's addAudio and addText, startTime frameStart(frame))
    if (!doc_change(d, sqlite3_mprintf("insert into thing default values; insert into fact(thing, name, at, value) values(last_insert_rowid(), 'kind', 0.0, %Q); insert into fact(thing, name, at, value) values(last_insert_rowid(), %Q, 0.0, %Q); insert into fact(thing, name, at, value) select id, 'start', 0.0, %!.17g from thing where %d order by id desc limit 1%s",
                                       kind, (!strcmp(kind, "solid") && doc_among(doc_shapes, file)) || !strcmp(kind, "shape") ? "shape" : "file", file, d.stage->now, d.stage->now > 0.0,
                                       // (a new text comes with a word to read, at a size that fits a stage, in the grey
                                       //  AbsentMotion's addText fills one with: TextActions.kt withFill 0xFF7F7F7F)
                                       (std::string(strcmp(kind, "text") ? "" : "; insert into fact(thing, name, at, value) select id, 'text', 0.0, 'Text' from thing order by id desc limit 1; insert into fact(thing, name, at, value) select id, 'size', 0.0, 0.5 from thing order by id desc limit 1; insert into fact(thing, name, at, value) select id, 'fill', 0.0, '7f7f7f' from thing order by id desc limit 1") +
                                        // (and lasts as long as the document says a thing put in lasts, if it says: AbsentMotion's New Layer Length,
                                        //  its StructureActions.kt and TextActions.kt endTimeFor; a film its own length, a group's Null as long as what it holds)
                                        (doc_among("picture text solid shape", kind) && strcmp(file, "null") ? "; insert into fact(thing, name, at, value) select (select max(id) from thing), 'duration', 0.0, value from fact where thing = 0 and name = 'layer_length' and at = 0 and value > 0" : "") +
                                        (sound ? "; insert into fact(thing, name, at, value) select max(id), 'visible', 0.0, 0 from thing" : "")).c_str()))) return 0;
    int thing = 0;   // (the newest number: SQLite's own count of things, which a change not made does not move)
    doc_rows(d, sqlite3_mprintf("select max(id) from thing"), [&](sqlite3_stmt* row) { thing = sqlite3_column_int(row, 0); });
    return thing;
}
// A thing made again: a new number with every fact of it (its keys and ways too), lying where it lies (After Effects'
// Duplicate Layer; the new one is the newest number, as for add).
static int doc_duplicate(Doc& d, int thing) {
    if (!doc_knows(d, thing)) return d.trouble = "that is no thing", 0;
    if (!doc_change(d, sqlite3_mprintf("insert into thing default values; insert into fact(thing, name, at, value, way) select last_insert_rowid(), name, at, value, way from fact where thing = %d;", thing))) return 0;
    int made = 0;
    doc_rows(d, sqlite3_mprintf("select max(id) from thing"), [&](sqlite3_stmt* row) { made = sqlite3_column_int(row, 0); });
    return made;
}
static bool doc_release(Doc& d, int by, double now);
static bool doc_free(Doc& d, int thing, int by, double now, bool stay, const std::vector<std::pair<std::string, double>>* told = nullptr);
static std::vector<int> doc_things(Doc& d);
static bool doc_remove(Doc& d, int thing) {
    if (doc_knows(d, thing) && doc_number(d, thing, "lock", 0, 0) > 0.5) return d.trouble = "it is locked", false;
    if (doc_knows(d, thing) && doc_word(d, thing, "kind") != "behaviour") {   // (a leader taken away: what it led lets its things go where they show, as After Effects keeps a child where it is when its parent goes)
        std::vector<int> led;
        for (const int r : doc_things(d))
            if (doc_word(d, r, "kind") == "behaviour" && doc_among(doc_relations, doc_word(d, r, "file")) && ((int)doc_number(d, r, "leader", 0, 0) == thing || (int)doc_number(d, r, "leader_b", 0, 0) == thing)) led.push_back(r);
        if (!led.empty()) {
            doc_act(d);
            bool ok = true;
            for (const int r : led) ok = ok && doc_release(d, r, d.stage ? d.stage->now : 0.0);
            ok = ok && doc_change(d, sqlite3_mprintf("delete from fact where thing = %d", thing));
            return doc_acted(d) && ok;
        }
    }
    if (doc_knows(d, thing) && doc_among(doc_relations, doc_word(d, thing, "file")) && doc_word(d, thing, "kind") == "behaviour") {   // (a relation taken away: its things back to what is under it, as a constraint deleted in Blender; release keeps them where they show)
        const std::vector<int> all = doc_members_of(d, thing);
        doc_act(d);
        bool ok = true;
        for (const int t : all) if (ok && t) ok = doc_free(d, t, thing, d.stage ? d.stage->now : 0.0, false);
        ok = ok && doc_change(d, sqlite3_mprintf("delete from fact where thing = %d", thing));
        return doc_acted(d) && ok;
    }
    return doc_knows(d, thing) && doc_change(d, sqlite3_mprintf("delete from fact where thing = %d", thing)); }
// A value that stays (its keys, if it had any, are gone); a word; a key at a moment; a key taken away.
static bool doc_parent(Doc& d, int thing, double to);
static bool doc_lead(Doc& d, int by, int leader, double now);
static bool doc_leading = false;   // (doc_lead itself writing the leader)
static bool doc_set(Doc& d, int thing, const char* name, double is) {
    if (!strcmp(name, "parent")) return doc_parent(d, thing, is);
    if (!strcmp(name, "leader") && !doc_leading && is >= 1 && doc_word(d, thing, "kind") == "behaviour" && doc_among(doc_relations, doc_word(d, thing, "file")) && !doc_word(d, thing, "members").empty())   // (a relation's leader changed by any hand: as its crown changes it, nothing jumps)
        return doc_lead(d, thing, (int)is, d.stage ? d.stage->now : 0.0);
    return doc_knows(d, thing, name, &is) && doc_change(d, sqlite3_mprintf("delete from fact where thing = %d and name = %Q and at <> 0; insert into fact(thing, name, at, value) values(%d, %Q, 0.0, %!.17g) on conflict do update set value = excluded.value, way = null", thing, name, thing, name, is));
}
static bool doc_put(Doc& d, int thing, const char* name, double at, double is);
static std::string doc_recipe_code_path(const std::string& name);   // (doc_recipes.h: the file of the recipe with code that is called so; none: "")
static bool doc_fx_say(Doc& d, int thing, const std::vector<std::string>& list);   // (doc_fx_put.h: its effects said in this order)
static bool doc_say(Doc& d, int thing, const char* name, const char* word) {
    if (!strcmp(name, "script") && word && *word && !strchr(word, '/')) {   // (a script said by the name of a recipe: its file, so a preset or a tile says "Repeater" and no path)
        if (const std::string file = doc_recipe_code_path(word); !file.empty()) return doc_say(d, thing, name, file.c_str());
    }
    if (!strcmp(name, "script") && word && thing != 0 && doc_among("picture text shape solid", doc_word(d, thing, "kind")) && doc_expression(d, word)) {   // (an expression: put among its effects after those it has, as many as it is given (docs/internal/notes/CREATE_PROGRAM.md); there already: as it is)
        std::vector<std::string> list = doc_fx_list(d, thing, true);
        if (std::find(list.begin(), list.end(), word) != list.end()) return true;
        list.push_back(word);
        return doc_fx_say(d, thing, list);
    }
    if (!strcmp(name, "fill") && !doc_word(d, thing, "fill_media").empty()) {   // (Alight Motion's Fill is one of a colour, a gradient or media: a colour takes the picture's place)
        doc_act(d);
        doc_say(d, thing, "fill_media", ""), doc_say(d, thing, name, word);
        return doc_acted(d);
    }
    if (doc_knows(d, thing, name, nullptr, word)) {
        DocScript* sc = !strcmp(name, "script") && doc_word(d, thing, "kind") == "solid" ? doc_script_of(d, word) : nullptr;
        if (!sc || !sc->run || !sc->run->sketch() || !sc->run->ok()) return doc_change(d, sqlite3_mprintf("insert into fact(thing, name, at, value) values(%d, %Q, 0.0, %Q) on conflict do update set value = excluded.value", thing, name, word));
        doc_act(d);   // (a sketch given to a solid: as many of the shape it draws as it draws)
        doc_change(d, sqlite3_mprintf("insert into fact(thing, name, at, value) values(%d, %Q, 0.0, %Q) on conflict do update set value = excluded.value", thing, name, word));
        if (const std::string shape = sc->run->shape(); !shape.empty()) doc_say(d, thing, "shape", shape.c_str()), doc_set(d, thing, "copies", shape == "sketch" ? 1 : sc->run->most());   // (a scene's parts have their own shapes: doc_door.h; a sketch's one mesh is all it draws: doc_sketch.h)
        return doc_acted(d);
    }
    // (an effect's colour, ISF's one input that Motolii holds as three numbers and an alpha (isf.cpp: _x, _y, _z, _w),
    //  said as one colour, as the Colors shelf says a colour to a card's value: each put at the stage's moment by the rule
    //  of a value changed, a key there if it has keys (doc_put); the alpha as it was. After Effects' and Alight Motion's
    //  effect colour is one colour; golf (83): white took three number fields)
    const std::string base(name), hex(word), why = d.trouble;
    if (hex.size() != 6 || hex.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos || !doc_knows(d, thing, (base + "_x").c_str())) return d.trouble = why, false;
    doc_act(d);
    for (int i = 0; i < 3; ++i) doc_put(d, thing, (base + "_" + "xyz"[i]).c_str(), d.stage ? d.stage->now : 0.0, std::stoi(hex.substr(2 * (size_t)i, 2), nullptr, 16) / 255.0);
    return doc_acted(d);
}

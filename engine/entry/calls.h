// calls.h: part of motolii.mm. Read only through motolii.mm. The open document's things, values, keys, ways, marks
// and shelves, read and changed at once (by_look, by_hand); the rest of motolii.h's calls in the parts motolii.mm reads after this.
int motolii_add(Motolii* m, const char* kind, const char* file) { return by_hand(m, [=] { return changes(m, (int)(doc_add(doc(m), kind, file))); }); }
int motolii_remove(Motolii* m, int thing) { return by_hand(m, [=] { return changes(m, (int)(doc_remove(doc(m), thing))); }); }
int motolii_set(Motolii* m, int thing, const char* name, double number) { return by_hand(m, [=] { return changes(m, (int)(doc_set(doc(m), thing, name, doc_macro_own(doc(m), thing, name, doc(m).stage ? doc(m).stage->now : 0.0, number)))); }); }   // (the value the hand sees: one a macro turns made its own, document/expressions.h)
int motolii_points(Motolii* m, int thing, double* xy, int room) { return by_look(m, [=] { return doc_points(*m->d, thing, m->d->stage->now, xy, room); }); }
int motolii_handles(Motolii* m, int thing, double* xy, double* of, int room) { return by_look(m, [=] { return doc_points(*m->d, thing, m->d->stage->now, xy, room, true, of); }); }
int motolii_pen(Motolii* m, int thing, double x, double y, double hx, double hy) { return by_hand(m, [=] { return changes(m, doc_pen(doc(m), thing, x, y, hx, hy)); }); }
int motolii_say(Motolii* m, int thing, const char* name, const char* word) { return by_hand(m, [=] { return changes(m, (int)(doc_say(doc(m), thing, name, word))); }); }
int motolii_key(Motolii* m, int thing, const char* name, double at, double number) { return by_hand(m, [=] { return changes(m, (int)(doc_key(doc(m), thing, name, at, doc_macro_own(doc(m), thing, name, at, number)))); }); }
// Many keys of one value in one call and one step (a world's motion baked into keys, a film's beats...): asked of the
// hand once, made one act, the stage made again once at its end.
int motolii_key_many(Motolii* m, int thing, const char* name, int n, const double* at, const double* number) {
    return by_hand(m, [=] {
        return changes(m, (int)doc_key_many(doc(m), thing, name, n, at, number));
    });
}
// A MIDI file's notes made keys of a value, as om_midi makes them in After Effects (midi_notes.h: midi_keys), each held; one step.
int motolii_midi(Motolii* m, int thing, const char* name, const char* file, const char* kind, int channel, double bpm) {
    std::vector<MidiEvent> events = midi_events(file);
    if (bpm > 0) {   // (the file's beats at another tempo, as om_midi's BPM box: a time is its beats times 60 / BPM)
        const double by = midi_bpm(file) / bpm;
        for (MidiEvent& e : events) e.at *= by;
    }
    const std::map<double, double> keys = midi_keys(events, kind, channel);
    std::vector<double> at, is;
    for (const auto& [t, v] : keys) at.push_back(t), is.push_back(v);
    if (at.empty()) return by_hand(m, [=, said = std::string(kind)] { return (doc(m).trouble = "no " + said + " keys of notes in " + file + " (kinds: velocity pitch count on bool)", 0); });
    return by_hand(m, [=] {   // (the keys it had go first: made again from the file, as om_midi makes a new null object each time; together, one step)
        Doc& d = doc(m);
        doc_act(d);
        const bool ok = doc_stay(d, thing, name, 0.0) && doc_key_many(d, thing, name, (int)at.size(), at.data(), is.data(), "Hold");
        return changes(m, (int)(doc_acted(d) && ok));
    });
}
double motolii_midi_bpm(const char* file) { return midi_bpm(file); }
int motolii_unkey(Motolii* m, int thing, const char* name, double at) { return by_hand(m, [=] { return changes(m, (int)(doc_unkey(doc(m), thing, name, at))); }); }
int motolii_keys(Motolii* m, int thing, const char* name) { return by_look(m, [=] { return (int)(doc_keys(doc(m), thing, name)); }); }
static int way_is(Motolii* m, int thing, const char* name, double at, const char* way) {   // (on the hand)
    Doc& d = doc(m);
    bool here = false;
    doc_rows(d, sqlite3_mprintf("select 1 from way where name = %Q", way), [&](sqlite3_stmt*) { here = true; });
    const auto ways = doc_own_ways();
    const auto own = ways.find(way);
    if (here || own == ways.end()) return changes(m, (int)(doc_way(d, thing, name, at, way)));
    doc_act(d);   // (the maker's own way: written into the document and put on the key, one step)
    if (!doc_define(d, way, own->second.c_str()) || !doc_way(d, thing, name, at, way)) d.act_ok = false;
    return changes(m, (int)doc_acted(d));
}
int motolii_way(Motolii* m, int thing, const char* name, double at, const char* way) { return by_hand(m, [=] { return way_is(m, thing, name, at, way); }); }
static int define_is(Motolii* m, const char* way, const char* expression) {   // (on the hand)
    Doc& d = doc(m);
    doc_act(d);
    for (const auto& [name, goes] : doc_own_ways()) {   // (the maker's own among the ways it asks for: written into the document too, as way_is writes one put on a key)
        if (!strstr(expression, ("way('" + name).c_str())) continue;
        bool here = false;
        doc_rows(d, sqlite3_mprintf("select 1 from way where name = %Q", name.c_str()), [&](sqlite3_stmt*) { here = true; });
        if (!here && !doc_define(d, name.c_str(), goes.c_str())) d.act_ok = false;
    }
    if (!doc_define(d, way, expression)) d.act_ok = false;
    // (ways laid or turned that nothing goes by any more, nor any other way asks for: the window makes one at each step of a hand)
    if (d.act_ok && !doc_change(d, sqlite3_mprintf("delete from way where (name glob '*×*' or name glob 'Reverse:*') and name <> %Q and name not in (select way from fact where way is not null) and not exists (select 1 from way o where o.name <> way.name and o.goes like '%%''' || way.name || '%%')", way))) d.act_ok = false;
    return changes(m, (int)doc_acted(d));
}
const char* motolii_effect_names(Motolii* m) { return by_look(m, [m] { return (m->listed = doc_effect_names()).c_str(); }); }
int motolii_effect(Motolii* m, int thing, const char* name, double at) { return by_hand(m, [=] { return changes(m, (int)(doc_effect(doc(m), thing, name, at))); }); }
int motolii_define(Motolii* m, const char* way, const char* expression) { return by_hand(m, [=] { return define_is(m, way, expression); }); }
const char* motolii_ways(Motolii* m) { return by_look(m, [m] { return (m->listed = doc_ways(*m->d)).c_str(); }); }
int motolii_work_out(Motolii* m, const char* sum, double* is) {
    const std::string said(sum);
    if (said.find_first_not_of("0123456789.+-*/()eE ") != std::string::npos) return 0;   // (a sum and nothing else: what is asked of SQLite is only ever that)
    static const std::regex whole("(^|[^0-9.eE])([0-9]+)(?![0-9.eE])");
    const std::string real = std::regex_replace(said, whole, "$1$2.0");   // (SQLite divides whole numbers as whole numbers: 1/3 would be 0)
    return by_look(m, [&] {
        sqlite3_stmt* asked = nullptr;
        char* text = sqlite3_mprintf("select (%s)", real.c_str());
        const bool made = sqlite3_prepare_v2(m->d->file, text, -1, &asked, nullptr) == SQLITE_OK;
        sqlite3_free(text);
        const bool ok = made && sqlite3_step(asked) == SQLITE_ROW && sqlite3_column_type(asked, 0) != SQLITE_NULL;
        if (ok) *is = sqlite3_column_double(asked, 0);
        sqlite3_finalize(asked);
        return (int)ok;
    });
}
int motolii_value(Motolii* m, int thing, const char* name, double at, double* is) {
    return by_look(m, [=] { return (int)(doc_value(doc(m), thing, name, at, is) && (doc_macro_over(doc(m), thing, name, at, is), true)); });   // (a knob a macro turns: as the macro makes it)
}
// A value as the stage shows it: what what drives it (a relation, a behaviour) makes of it, 2; its own, 1; none, 0.
int motolii_shows(Motolii* m, int thing, const char* name, double at, double* is) {
    return by_look(m, [=] {
        if (!doc_value(*m->d, thing, name, at, is)) return 0;
        if (!doc_driven_by(*m->d, thing, name)) return 1;
        *is = doc_literal(*m->d, thing, doc_lasting(name), at, *is);
        return 2;
    });
}
int motolii_things(Motolii* m, int* things, int room) {
    return by_look(m, [=] { const std::vector<int> all = doc_things(*m->d); for (int i = 0; i < room && i < (int)all.size(); ++i) things[i] = all[(size_t)i]; return (int)all.size(); });
}
const char* motolii_word(Motolii* m, int thing, const char* name) { return by_look(m, [=] { return (said_word() = !strcmp(name, "name") ? doc_name(*m->d, thing) : doc_word(*m->d, thing, name)).c_str(); }); }
double motolii_lasts(Motolii* m, int thing) { return by_look(m, [=] { return doc_lasts(*m->d, thing); }); }
int motolii_key_moments(Motolii* m, int thing, const char* name, double* at, int room) {
    return by_look(m, [=] { const std::vector<double> all = doc_key_moments(*m->d, thing, name); for (int i = 0; i < room && i < (int)all.size(); ++i) at[i] = all[(size_t)i]; return (int)all.size(); });
}
// A thing's frame on the picture at the stage's moment, as the stage's own eye sees it: its middle, how wide and how
// high (points of the picture, from the top left), and how far it is turned (degrees, clockwise as seen).
int motolii_frame(Motolii* m, int thing, double* frame) {
    return by_look(m, [=] { return (int)(doc_knows(doc(m), thing) && doc_frame(*m->d, thing, m->now, frame)); });
}
// What of a thing is seen at the stage's moment: the upright box of its outline on the picture (left, top, right, bottom).
int motolii_seen(Motolii* m, int thing, double* box) { return by_look(m, [=] { return (int)(doc_knows(doc(m), thing) && doc_seen_box(*m->d, thing, m->now, box)); }); }
int motolii_path(Motolii* m, int thing, int copy, double from, double to, int n, double* path) {
    return by_look(m, [=] {
        if (!doc_knows(doc(m), thing) || n < 1) return 0;
        for (int i = 0; i < n; ++i) {   // (the stage's own placing, at moments of the preview's own: the stage's moment stays)
            const double at = from + (to - from) * i / n;
            const math::mat4 p = doc_place(*m->d, thing, at, 0, copy, copy > 0 || doc_staggered(*m->d, thing, at));   // (as a copy, or as itself, as the stage places it)
            path[4 * i] = p[3][0], path[4 * i + 1] = p[3][1];
            path[4 * i + 2] = std::atan2(p[0][1], p[0][0]) * 360.0 / (double)TAU, path[4 * i + 3] = length(p[0].xyz);
        }
        return n;
    });
}
// The same, in the round: path[4i..4i+3] = where it is (x, y, z, units of the stage) and how large; for a preview that
// draws it as seen from any side.
int motolii_path3(Motolii* m, int thing, int copy, double from, double to, int n, double* path) {
    return by_look(m, [=] {
        if (!doc_knows(doc(m), thing) || n < 1) return 0;
        for (int i = 0; i < n; ++i) {
            const double at = from + (to - from) * i / n;
            const math::mat4 p = doc_place(*m->d, thing, at, 0, copy, copy > 0 || doc_staggered(*m->d, thing, at));
            path[4 * i] = p[3][0], path[4 * i + 1] = p[3][1], path[4 * i + 2] = p[3][2], path[4 * i + 3] = length(p[0].xyz);
        }
        return n;
    });
}
int motolii_keying(Motolii* m, int on) {   // (on below 0: only says whether every change is keyed: a read, answered at once, not queued behind the hand's picture)
    if (on < 0) return (int)m->keying.load();
    m->keying = on != 0;   // (said at once; the document told in the hand's turn, without waiting)
    return posted(m, "keying", [m, on] { m->d->keying = on != 0, m->d->keying_from = m->now; m->keying = m->d->keying; }), on != 0;
}
int motolii_hold(Motolii* m, int thing) { return by_hand(m, [=] { return (int)doc_hold(doc(m), thing); }); }
int motolii_carry(Motolii* m, const char* by, double a, double b) { return posted(m, std::string("carry ") + by, [m, by = std::string(by), a, b] { doc_carry(doc(m), by.c_str(), a, b); }); }   // (refused: said when it is let go)
int motolii_let_go(Motolii* m, int keep) { return by_hand(m, [=] { return changes(m, (int)doc_let_go(doc(m), keep != 0)); }); }
int motolii_put(Motolii* m, int thing, const char* name, double at, double number) { return by_hand(m, [=] { return changes(m, (int)doc_put(doc(m), thing, name, at, doc_macro_own(doc(m), thing, name, at, number))); }); }   // (as the hand sees it: doc_macro_own)
int motolii_key_here(Motolii* m, int thing, const char* name, double at) { return by_hand(m, [=] { return changes(m, (int)doc_key_here(doc(m), thing, name, at)); }); }
int motolii_size(Motolii* m, int wide, int high) {
    return by_hand(m, [=] {
        char* say = doc_size_words(wide, high);
        return say ? changes(m, (int)doc_change(*m->d, say)) : (m->d->trouble = "a stage is from 16 to 8192 points each way, an even number of them", 0);
    });
}
int motolii_work(Motolii* m, double from, double to) { return by_hand(m, [=] { return changes(m, (int)doc_work_is(doc(m), from, to)); }); }
int motolii_work_of(Motolii* m, double* from, double* to) { return by_look(m, [=] { return doc_work(*m->d, from, to), 1; }); }
int motolii_mark(Motolii* m, double at, const char* word) { return by_hand(m, [=] { return changes(m, (int)doc_mark(doc(m), at, word)); }); }
int motolii_guide(Motolii* m, const char* axis, double at, int on) { return by_hand(m, [=] { return changes(m, (int)doc_guide(doc(m), axis, at, on != 0)); }); }
const char* motolii_guides(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_guides(*m->d)).c_str(); }); }
const char* motolii_marks(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_marks(*m->d)).c_str(); }); }
const char* motolii_mark_colours(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_mark_colours(*m->d)).c_str(); }); }
const char* motolii_settings(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_settings(*m->d)).c_str(); }); }
int motolii_fits(Motolii* m) {
    return by_look(m, [=] {   // (a read: the document's size against the stage's)
        int wide = m->s->w, high = m->s->h;
        doc_rows(*m->d, sqlite3_mprintf("select name, value from fact where thing = 0 and name in ('wide', 'high')"),
                 [&](sqlite3_stmt* row) { (strcmp((const char*)sqlite3_column_text(row, 0), "wide") ? high : wide) = sqlite3_column_int(row, 1); });
        return (int)(wide == m->s->w && high == m->s->h);
    });
}
int motolii_size_of(Motolii* m, int* wide, int* high) { return by_look(m, [=] { return *wide = m->s->w, *high = m->s->h, 1; }); }
int motolii_raise(Motolii* m, int thing, int places) { return by_hand(m, [=] { return changes(m, (int)doc_raise(doc(m), thing, places)); }); }
int motolii_stay(Motolii* m, int thing, const char* name, double at) { return by_hand(m, [=] { return changes(m, (int)doc_stay(doc(m), thing, name, at)); }); }
int motolii_keyed(Motolii* m, int thing, const char* name, double at) {
    return by_look(m, [=] { return doc_keyed(*m->d, thing, name, at); });
}
const char* motolii_words(Motolii* m, int thing, const char* name) { return by_look(m, [=] { return (said_word() = doc_words(*m->d, thing, name)).c_str(); }); }
// Every moment a key of any of a thing's values that take keys stands at, each once and in time: a timeline's bar
// marks in one call (asked a value at a time, a document of fifteen recipes was hundreds of calls each reading).
int motolii_thing_key_moments(Motolii* m, int thing, double* at, int room) {
    return by_look(m, [=] {   // (one question to SQLite: the moments of the values of it that have keys, as DOC_KEYED says one has)
        int i = 0;
        doc_rows(*m->d, sqlite3_mprintf("select distinct at from fact where thing = %d and name in (select name from fact where thing = %d group by name having count(*) > 1 or max(at) <> 0 or max(way) is not null) order by at", thing, thing), [&](sqlite3_stmt* row) {
            if (i < room) at[i] = sqlite3_column_double(row, 0);
            ++i;
        });
        return i;
    });
}
const char* motolii_moving(Motolii* m, int thing) { return by_look(m, [=] { return (said_word() = doc_moving(*m->d, thing)).c_str(); }); }
const char* motolii_values(Motolii* m, int thing) { return by_look(m, [=] { return (said_word() = doc_has(*m->d, thing)).c_str(); }); }
int motolii_range(Motolii* m, int thing, const char* name, double* low, double* high) { return by_look(m, [=] { return (int)doc_range(*m->d, thing, name, low, high); }); }
const char* motolii_recipes(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_recipe_names()).c_str(); }); }
const char* motolii_effects(Motolii* m) {   // (the effects folder's, then AviUtl2's scripts)
    return by_look(m, [=] {
        const std::string files = doc_folder_names("effects", ".wgsl .fs .mjs .js .json .am"), aviutl = doc_aviutl_names();   // (.json: Filament's own settings, viewer_settings.h; .am: AbsentMotion's own motion, absent_motion.h)
        return (said_word() = files + (files.empty() || aviutl.empty() ? "" : "\n") + aviutl).c_str();
    });
}
void motolii_files_changed(void) { ++files_changed(); }
int motolii_look_save(Motolii* m, int thing, const char* path) { return by_look(m, [=] { return (int)doc_look_save(*m->d, thing, path); }); }
int motolii_look_put(Motolii* m, int thing, const char* path) { return by_hand(m, [=] { return changes(m, doc_look_put(doc(m), thing, path)); }); }
const char* motolii_looks(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_look_names()).c_str(); }); }
const char* motolii_animators(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_folder_names("expressions", ".js")).c_str(); }); }
const char* motolii_relations(Motolii* m) { return by_look(m, [=] { return (said_word() = doc_folder_names("relations", ".js")).c_str(); }); }
int motolii_make(Motolii* m, const char* recipe) { return by_hand(m, [=] { return changes(m, doc_make(doc(m), recipe)); }); }
const char* motolii_shown(Motolii* m, const char* name) {
    return by_look(m, [=] {
        const DocShown* s = doc_shown_of(*m->d, name);
        char line[512] = "";
        if (s) std::snprintf(line, sizeof line, "%s\t%s\t%s\t%g\t%g\t%s\t%d", s->look, s->unit, s->label, s->low, s->high, s->fold ? s->fold : "", (int)s->open);
        return (said_word() = line).c_str();
    });
}
const char* motolii_cards(Motolii* m, int thing) { return by_look(m, [=] { return (said_word() = doc_cards_of(*m->d, thing)).c_str(); }); }
const char* motolii_cards_more(Motolii* m, int thing) { return by_look(m, [=] { std::string more; doc_cards_of(*m->d, thing, &more); return (said_word() = more).c_str(); }); }
const char* motolii_fx_titles(Motolii* m, int thing) { return by_look(m, [=] { return (said_word() = doc_fx_titles(*m->d, thing)).c_str(); }); }
const char* motolii_kind_of(const char* file) { return doc_kind_of(file); }
int motolii_sets(const char* font, const char* words) { return type_sets(font, words) ? 1 : 0; }
const char* motolii_font_lacks(const char* font, const char* words) {
    thread_local std::string said;
    if (!font || !words) return "";
    const std::string lacks = type_lacks(font, words);
    said = lacks.empty() ? std::string() : lacks + "\t" + type_fallback(font, words);
    return said.c_str();
}
// The names of the ways a stretch may go (the nine kinds, then the ways defined in this document), with spaces between;
// and how one of the nine goes: how far it is, from 0 at its beginning to 1 at its end, at `u` of the way through.
// A kind's numbers as a hand takes them: each one's name, how low and how high ("seed 1 999 grain 0 0.5 ..."); none: "".
const char* motolii_way_numbers(Motolii*, const char* kind) {   // (the kinds are the maker's, not the document's: nothing waited for)
    static thread_local std::string said;
    said.clear();
    for (const auto& k : interp_kinds) {
        if (strcasecmp(k.name, kind)) continue;
        std::istringstream names(k.names);
        std::string name;
        char one[96];
        for (int j = 0; j < k.numbers && names >> name; ++j) std::snprintf(one, sizeof one, "%s%s %.9g %.9g", said.empty() ? "" : " ", name.c_str(), k.lo[j], k.hi[j]), said += one;
    }
    return said.c_str();
}
const char* motolii_way_names(Motolii* m) {
    return by_look(m, [=] {
        said_word().clear();
        for (const auto& kind : interp_kinds) said_word() += std::string(said_word().empty() ? "" : " ") + kind.name;
        std::set<std::string> here;
        doc_rows(*m->d, sqlite3_mprintf("select name from way order by name"), [&](sqlite3_stmt* row) { here.insert((const char*)sqlite3_column_text(row, 0)); said_word() += std::string(" ") + (const char*)sqlite3_column_text(row, 0); });
        for (const auto& [name, goes] : doc_own_ways()) if (!here.count(name)) said_word() += " " + name;   // (then the maker's own, not yet in this document)
        return said_word().c_str();
    });
}
double motolii_way_at(Motolii* m, const char* way, double u) {
    Interp kind;
    if (interp_said(way, &kind) == 0) return interp_ease(kind, u);
    return by_look(m, [=] {
        bool here = false;
        doc_rows(*m->d, sqlite3_mprintf("select 1 from way where name = %Q", way), [&](sqlite3_stmt*) { here = true; });
        const auto ways = doc_own_ways();
        const auto own = ways.find(way);
        if (!here && own != ways.end()) {   // (the maker's own, not yet in this document: as its file says it)
            const double p[4] = {1, 1, 1, 1};
            sqlite3_stmt* goes = doc_goes(*m->d, own->second);
            return goes ? doc_went(goes, u, u, 1.0, 0.0, 1.0, p) : u;
        }
        return doc_went_by(*m->d, way, u, u, 1.0, 0.0, 1.0);   // (one defined in the document: as between a key of 0 and a key of 1, a second apart)
    });
}
int motolii_together(Motolii* m, int on) {
    return by_hand(m, [=] {
        if (on) return doc_act(*m->d), m->d->act_together = true, 1;
        const int done = m->d->act ? (int)doc_acted(*m->d) : 0;
        if (!m->d->act) m->d->act_together = false;
        picture_update(m), picture_moment(m);   // (the pictures put off while the act was open, made once)
        return done;
    });
}
// Every stretch of a thing's keyed values, a line each: from, to, its way ("from\tto\tway\n"): a timeline draws how each
// goes between its two keys (the stretch is the inside's own: the window only draws what it says).
const char* motolii_thing_stretches(Motolii* m, int thing) {
    return by_look(m, [=] {
        std::string all;
        doc_rows(*m->d, sqlite3_mprintf("select at, next, way from (select at, lead(at) over (partition by name order by at) as next, coalesce(way, 'Linear') as way from fact where thing = %d and name in (select name from fact where thing = %d group by name having count(*) > 1 or max(at) <> 0 or max(way) is not null)) where next is not null order by at", thing, thing), [&](sqlite3_stmt* row) {
            std::string way = (const char*)sqlite3_column_text(row, 2);
            Interp kind;
            if (interp_said(way, &kind) == 0) way = interp_words(kind);
            char line[64];
            std::snprintf(line, sizeof line, "%.17g\t%.17g\t", sqlite3_column_double(row, 0), sqlite3_column_double(row, 1));
            all += line + way + "\n";
        });
        return (said_word() = all).c_str();
    });
}
const char* motolii_way_of(Motolii* m, int thing, const char* name, double at) { return by_look(m, [=] { return (said_word() = doc_way_of(*m->d, thing, name, at)).c_str(); }); }
// How many points of the picture one unit of the stage is, where things stand when their z is 0.
static double point_of(Motolii* m) {   // (points of the picture to one unit of the stage, at its middle, as the stage's own eye sees it:
    // 6 units off with 30 degrees up and down (motolii_open): the document's scale, whatever camera the stage looks through now)
    return m->s->h / (2.0 * 6.0 * std::tan(15.0 * TAU / 360.0));
}
double motolii_point(Motolii* m) { return by_look(m, [=] { return point_of(m); }); }
// How a hand reads a thing's value: as the value times `times`, and `from` more ("times from"). Places are counted in
// points of the picture from its top left, as After Effects counts them; scale and opacity in hundredths; the turn about
// z clockwise (a camera's turns as they are, its pitch looking down); the anchor in hundredths of the box from its top
// left (front -50 to back 50); a camera's distance in points of the picture (the stage's own eye 6 units off); any other
// value by its look (stage: points, down: points down the picture, share: hundredths), else as it is.
const char* motolii_reading(Motolii* m, int thing, const char* name) {
    return by_look(m, [=] {
        const double p = point_of(m), w = m->s->w, h = m->s->h;
        const bool camera = doc_word(*m->d, thing, "kind") == "camera";
        const std::string n = name;
        double times = 1, from = 0;
        if (n == "x") times = p, from = w / 2;
        else if (n == "y") times = -p, from = h / 2;
        else if (n == "z") times = p;
        else if (n == "scale_x" || n == "scale_y" || n == "scale_z" || n == "opacity" || n == "zoom") times = 100;
        else if (n == "rotate") times = camera ? 1 : -1;
        else if (n == "rotate_x") times = camera ? -1 : 1;
        else if (n == "anchor_x") times = 50, from = 50;
        else if (n == "anchor_y") times = -50, from = 50;
        else if (n == "anchor_z") times = -50;
        else if (n == "distance") times = 6 * p;
        else if (n == "size") times = p;
        else if (const DocShown* s = doc_shown_of(*m->d, name)) {
            const std::string look = s->look;
            times = look == "stage" ? p : look == "down" ? -p : look == "share" ? 100 : 1;
        }
        char line[64];
        std::snprintf(line, sizeof line, "%.17g %.17g", times, from);
        return (said_word() = line).c_str();
    });
}
int motolii_sequence(Motolii* m, double overlap) { return by_hand(m, [=] { return changes(m, (int)doc_sequence(doc(m), overlap, RATE)); }); }

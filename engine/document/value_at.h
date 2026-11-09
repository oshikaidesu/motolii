// value_at.h: part of doc.h (a value read at a moment: its keys and ways, an element's and a program's own clock). Read only through doc.h.

// Rows of the document: `each` is told every row of what is asked (in SQLite's own words).
static bool doc_rows(Doc& d, char* ask, const std::function<void(sqlite3_stmt*)>& each = nullptr) {
    sqlite3_stmt* rows = nullptr;
    bool ok = sqlite3_prepare_v2(d.file, ask, -1, &rows, nullptr) == SQLITE_OK;
    while (ok && sqlite3_step(rows) == SQLITE_ROW)
        if (each) each(rows);
    sqlite3_finalize(rows);
    sqlite3_free(ask);
    return ok;
}
static void doc_forget(Doc& d) {
    d.phys_stale = true, d.scripted.clear();   // (the world made again only if what it is made of changed: doc_physics)
    d.moving.clear(), d.literals.clear(), d.words.clear(), d.keyed.clear(), d.halves.clear(), d.heardWords.clear(), d.talls.clear(), d.placing.clear();
    d.named.clear(), d.tracks.clear(), d.drivers.clear(), d.connects.clear(), d.relationsOf.clear();
    d.laid.clear();
}
// The things in the order they lie, the one furthest back first: by `order` where it is said, else as they were made.
static const std::vector<int>& doc_laid(Doc& d) {
    if (d.laid.empty())
        doc_rows(d, sqlite3_mprintf("select f.thing from fact f where f.name = 'kind' order by coalesce((select o.value from fact o where o.thing = f.thing and o.name = 'order' and o.at = 0), f.thing), f.thing"),
                 [&](sqlite3_stmt* row) { d.laid.push_back(sqlite3_column_int(row, 0)); });
    return d.laid;
}

// A way's expression made ready for SQLite to work out (nullptr: SQLite does not take it; d.trouble says why).
static sqlite3_stmt* doc_goes(Doc& d, const std::string& expression) {
    auto ready = d.goes.find(expression);
    if (ready != d.goes.end()) return ready->second;
    sqlite3_stmt* made = nullptr;
    char* asked = sqlite3_mprintf("with v(u, t, d, a, b, p1, p2, p3, p4) as (select ?, ?, ?, ?, ?, ?, ?, ?, ?) select (%s) from v", expression.c_str());
    if (sqlite3_prepare_v2(d.file, asked, -1, &made, nullptr) != SQLITE_OK) d.trouble = sqlite3_errmsg(d.file), made = nullptr;
    sqlite3_free(asked);
    return made ? d.goes[expression] = made : nullptr;
}
static double doc_went(sqlite3_stmt* way, double u, double t, double length, double a, double b, const double* p) {
    const double told[] = {u, t, length, a, b, p[0], p[1], p[2], p[3]};
    for (int i = 0; i < 9; ++i) sqlite3_bind_double(way, i + 1, told[i]);
    const double is = sqlite3_step(way) == SQLITE_ROW ? sqlite3_column_double(way, 0) : a;
    sqlite3_reset(way);
    return is;
}
static sqlite3_stmt* doc_way_named(Doc& d, const std::string& name) {
    auto known = d.named.find(name);
    if (known != d.named.end()) return known->second;
    sqlite3_stmt* way = nullptr;
    doc_rows(d, sqlite3_mprintf("select goes from way where name = %Q", name.c_str()), [&](sqlite3_stmt* row) { way = doc_goes(d, (const char*)sqlite3_column_text(row, 0)); });
    if (!way)   // (not defined here: one of the ways by name, easing_names.h)
        for (const auto& one : named_ways) if (name == one.name) way = doc_goes(d, std::string("a + (b - a) * (") + one.goes + ")");
    return d.named[name] = way;
}
// A stretch that goes a way defined in the document (`own`: its name, then its numbers): the value at `u` of the way
// through, `t` seconds in, between a key of `a` and a key of `b`, `length` seconds apart (no such way: `a`).
static double doc_went_by(Doc& d, const std::string& own, double u, double t, double length, double a, double b) {
    std::istringstream said(own);
    std::string way;
    double p[4] = {0, 0, 0, 0};
    said >> way;
    for (double& one : p) said >> one;
    sqlite3_stmt* goes = doc_way_named(d, way);
    return goes ? doc_went(goes, u, t, length, a, b, p) : a;
}

// A value at a moment: `otherwise` where the document does not say; where it has keys, the value the stretch it is in
// gives (before the first key and after the last: theirs). A stretch goes the way said for it (not said: Linear).
static double doc_keys_at(Doc& d, const Doc::Keys& k, double at, double otherwise);
// Where a value's keys are kept (read from the facts once, as doc_number reads them): kept until the document changes.
static const Doc::Keys& doc_keys_of(Doc& d, int thing, const char* name);
static std::string doc_word(Doc& d, int thing, const char* name);
// The element put in that a thing is held in (a group above it put in from an element, doc_element_add): 0 none.
static int doc_element_above(Doc& d, int thing) {
    for (int p = thing, n = 0; p && n < 64; ++n) {
        const Doc::Keys& up = doc_keys_of(d, p, "parent");
        p = up.value.empty() ? 0 : (int)up.value.front();
        if (const Doc::Keys& was = doc_keys_of(d, p, "element_length"); p && !was.value.empty() && was.value.front() > 0.0) return p;
    }
    return 0;
}
// The moment of itself an element put in shows at `at`, as long as it is now against as long as it was: its intro and
// outro as they were, the middle held, stretched, looped or looped and stretched between, or nothing after its end
// (Alight Motion's Re-timing; AbsentMotion's NestedClock, NestedScenes.kt, its at(): Apache-2.0, Copyright 2026 The
// AbsentMotion authors; in seconds, not rounded to the middles of frames, but what Freeze holds: the middle of the
// last frame, as its middle() puts its scene's end, not the moment after it). -1e9: not seen then (Blank).
static double doc_element_clock(Doc& d, int el, double at) {
    const double origin = doc_keys_at(d, doc_keys_of(d, el, "start"), 0, 0), scene_end = doc_keys_at(d, doc_keys_of(d, el, "element_length"), 0, 0);
    const double lasts = doc_keys_at(d, doc_keys_of(d, el, "duration"), 0, -1), layer_end = lasts > 0.0 ? lasts : scene_end;
    const std::string method = doc_word(d, el, "retime");
    const double local = at - origin;
    if (method == "blank") return local < scene_end ? at : -1e9;
    const double intro = std::clamp(doc_keys_at(d, doc_keys_of(d, el, "retime_in"), 0, 0), 0.0, scene_end), out = doc_keys_at(d, doc_keys_of(d, el, "retime_out"), 0, 0);
    const double outro = out > 0.0 ? std::clamp(out, intro, scene_end) : scene_end, outro_start = layer_end - (scene_end - outro), room = outro_start - intro, span = outro - intro;
    double mapped = local;
    if (local >= outro_start) mapped = outro + local - outro_start;
    else if (local >= intro) {
        const double into = local - intro;
        if (method == "stretch" && room > 0.0) mapped = intro + into * span / room;
        else if (method == "loop") mapped = intro + (span > 0.0 ? std::fmod(into, span) : 0.0);
        else if (method == "loop_stretch" && span > 0.0 && room > 0.0) {
            const double each = room / std::max(1.0, std::round(room / span));
            mapped = intro + std::fmod(into, each) * span / each;
        } else {   // (Freeze, as an element is made)
            const double fps = d.stage ? screen_rate(*d.stage) : 60.0, held = (std::ceil(outro * fps - 1e-9) - 0.5) / fps;
            mapped = into < span ? intro + into : std::max(intro, held);
        }
    }
    return origin + mapped;
}
// The moment a thing is at, as the element put in that holds it shows it (none: the stage's own).
static double doc_element_now(Doc& d, int thing, double at) {
    const int el = thing ? doc_element_above(d, thing) : 0;
    return el ? doc_element_clock(d, el, at) : at;
}
// Time Quantization (Alight Motion's; After Effects' Posterize Time): a thing with a frame_rate is seen only at its own
// frames, counted from its start: a value that moves is read at the frame the moment is in. 0: as smooth as the stage.
// (Held in an element put in, first the moment the element shows: doc_element_now.)
static double doc_stepped(Doc& d, int thing, const Doc::Keys& k, double at) {
    if (k.at.size() < 2 || !thing) return at;
    at = doc_element_now(d, thing, at);
    const Doc::Keys& rate = doc_keys_of(d, thing, "frame_rate");
    if (rate.value.empty() || !(rate.value.front() > 0.0)) return at;
    const Doc::Keys& from = doc_keys_of(d, thing, "start");
    const double start = from.value.empty() ? 0.0 : from.value.front(), r = rate.value.front();
    return at <= start ? at : start + std::floor((at - start) * r + 1e-9) / r;
}
static double doc_number(Doc& d, int thing, const char* name, double at, double otherwise) {
    if (d.held.thing == thing)   // (what a hand is carrying shows in place of the document's own)
        if (const auto tried = d.held.tried.find(name); tried != d.held.tried.end()) return tried->second;
    const Doc::Keys& k = doc_keys_of(d, thing, name);
    return doc_keys_at(d, k, doc_stepped(d, thing, k, at), otherwise);
}
// The seconds of its own a program is at, `by` where it has got to by itself. A program is run once in order and its frames
// are kept, so its time keyed only says which of them is seen: nothing in it is written again or run again, and every way a
// program has of reading time goes with it (After Effects' Time Remap, whose value is the layer's own time, any way between keys).
static double doc_own_time(Doc& d, int thing, double at, double by) { return std::max(0.0, doc_number(d, thing, "time_remap", at, by)); }
// A level's drawing at a moment: its key there or the last before it, held to the next whatever way its keys go (a
// timesheet's cells: a drawing is never between two, OpenToonz's xdtsio.cpp each to the next item); 1 if it has none.
static double doc_cel(Doc& d, int thing, double at) {
    const Doc::Keys& k = doc_keys_of(d, thing, "cel");
    double held = k.value.empty() ? 1.0 : k.value.front();
    for (size_t i = 0; i < k.at.size() && k.at[i] <= at + 1e-9; ++i) held = k.value[i];
    return (double)std::llround(held);
}
static const Doc::Keys& doc_keys_of(Doc& d, int thing, const char* name) {
    if (d.reading) d.reading->insert(thing);
    auto& of = d.moving[thing];
    auto found = of.find(std::string_view(name));
    if (found == of.end()) {
        Doc::Keys keys;
        doc_rows(d, sqlite3_mprintf("select at, value, coalesce(way, '') from fact where thing = %d and name = %Q order by at", thing, name), [&](sqlite3_stmt* row) {
            keys.at.push_back(sqlite3_column_double(row, 0));
            keys.value.push_back(sqlite3_column_double(row, 1));
            const std::string way = (const char*)sqlite3_column_text(row, 2);
            Interp kind;
            const bool of_the_nine = interp_said(way.empty() ? "Linear" : way, &kind) == 0;   // (not said: Linear, as a new key is in the past repository)
            keys.interp.push_back(kind);
            keys.own.push_back(of_the_nine ? "" : way);
        });
        if (keys.at.size() > 1) keys.loop = doc_word(d, thing, (std::string(name) + "_loop").c_str());   // (the keys gone through again past the last: doc_keys_at)
        found = d.moving[thing].emplace(std::string(name), std::move(keys)).first;
    }
    return found->second;
}
// A value from its keys at a moment (doc_number's own reckoning: before the first key and after the last, theirs).
static double doc_keys_at(Doc& d, const Doc::Keys& k, double at, double otherwise) {
    if (k.at.empty()) return otherwise;
    if (k.at.size() == 1 || at <= k.at.front()) return k.value.front();
    // (past the last key, gone through again: After Effects' loopOut, its cycle, pingpong and offset, on all its keys;
    //  whatever the value is, as the way of a stretch is. offset: each time on from where the last ended)
    double on = 0.0;
    if (at > k.at.back() && (k.loop == "cycle" || k.loop == "pingpong" || k.loop == "offset")) {
        const double span = k.at.back() - k.at.front(), rounds = std::floor((at - k.at.front()) / span), left = at - k.at.front() - rounds * span;
        at = k.loop == "pingpong" && std::fmod(rounds, 2.0) != 0.0 ? k.at.back() - left : k.at.front() + left;
        if (k.loop == "offset") on = rounds * (k.value.back() - k.value.front());
    }
    if (at <= k.at.front()) return k.value.front() + on;
    if (at >= k.at.back()) return k.value.back() + on;
    const size_t i = (size_t)(std::upper_bound(k.at.begin(), k.at.end(), at) - k.at.begin()) - 1;   // (the stretch it is in begins at key i)
    const double u = (at - k.at[i]) / (k.at[i + 1] - k.at[i]);
    if (k.own[i].empty()) return k.value[i] + (k.value[i + 1] - k.value[i]) * interp_ease(k.interp[i], u) + on;
    return doc_went_by(d, k.own[i], u, at - k.at[i], k.at[i + 1] - k.at[i], k.value[i], k.value[i + 1]) + on;
}
static std::string doc_word(Doc& d, int thing, const char* name) {
    if (thing == 0 && !strcmp(name, "kind")) return "stage";   // (thing 0 is the stage: its values are the whole picture's)
    if (d.held.thing == thing)   // (what a hand is carrying shows in place of the document's own)
        if (const auto said = d.held.said.find(name); said != d.held.said.end()) return said->second;
    const auto known = d.words.find({thing, name});   // (asked again and again between changes: the document asked once)
    if (known != d.words.end()) return known->second;
    std::string is;
    doc_rows(d, sqlite3_mprintf("select value from fact where thing = %d and name = %Q", thing, name), [&](sqlite3_stmt* row) { is = (const char*)sqlite3_column_text(row, 0); });
    d.words.emplace(std::make_pair(thing, std::string(name)), is);
    return is;
}

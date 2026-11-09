// doc_steps.h: part of doc.h (the document's file opened; each change kept as one step, undone and done again). Read only through doc.h.
static std::vector<std::filesystem::path> doc_folders(const char* folder);   // (doc_folders.h)
// The document in `path` (made if it is not there), on the stage. nullptr: the file is not a document.
static std::string doc_recipe_code_path(const std::string& name);   // (doc_recipes.h: the file of the recipe with code that is called so; none: "")
static Doc* doc_open(Stage& s, const char* path) {
    Doc* d = new Doc;
    if (sqlite3_open(path, &d->file) != SQLITE_OK) return nullptr;
    // (a way defined in the document may ask how far a cubic bezier ease is at u, by its two handles, as the nine kinds'
    //  Bezier goes: bezier(u, x1, y1, x2, y2))
    sqlite3_create_function(d->file, "bezier", 5, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nullptr, [](sqlite3_context* c, int, sqlite3_value** v) {
        sqlite3_result_double(c, interp_bezier(interp_clamp(sqlite3_value_double(v[1]), 0.0, 1.0), sqlite3_value_double(v[2]), interp_clamp(sqlite3_value_double(v[3]), 0.0, 1.0), sqlite3_value_double(v[4]), sqlite3_value_double(v[0])));
    }, nullptr, nullptr);
    // (and how far an ease of anime.js has gone at u, as anime.js says it: anime('outElastic(1, .3)', u), script.h)
    sqlite3_create_function(d->file, "anime", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nullptr, [](sqlite3_context* c, int, sqlite3_value** v) {
        static const std::string bundle = (doc_engine("third_party/anime") / "anime.umd.min.js").string();
        std::string trouble;
        const double went = anime_ease(bundle, (const char*)sqlite3_value_text(v[0]), sqlite3_value_double(v[1]), &trouble);
        if (trouble.empty()) sqlite3_result_double(c, went);
        else sqlite3_result_error(c, trouble.c_str(), -1);
    }, nullptr, nullptr);
    // (and how far another way has gone at u, as it is said: way('Cyclic', u), way('Bezier .2 0 0 1', u). So ways are laid
    //  over one another, one through another, times or plus it: GSAP's CustomWiggle's timingEase and amplitudeEase,
    //  Blender's F-Curve stack and its Noise; each begins at its first key and ends at its next, so what they make does too)
    sqlite3_create_function(d->file, "way", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC, d, [](sqlite3_context* c, int, sqlite3_value** v) {
        const char* text = (const char*)sqlite3_value_text(v[0]);
        const std::string said = text ? text : "";
        const double u = sqlite3_value_double(v[1]);
        Interp kind;
        sqlite3_result_double(c, u <= 0.0 || u >= 1.0 ? u : interp_said(said, &kind) == 0 ? interp_ease(kind, u) : doc_went_by(*(Doc*)sqlite3_user_data(c), said, u, u, 1.0, 0.0, 1.0));   // (past its ends as it was: an overshoot above it stays one)
    }, nullptr, nullptr);
    sqlite3_busy_timeout(d->file, 2000);   // (another program at the same document is waited for)
    // (a key's `way` is how the stretch from it to the next key goes; `way` the table holds the ways defined in this document)
    if (sqlite3_exec(d->file, "create table if not exists fact(thing integer, name text, at numeric, value, way text, primary key(thing, name, at)) without rowid;"
                              "create table if not exists way(name text primary key, goes text) without rowid;"
                              "create table if not exists step(n integer primary key, change blob, undone integer default 0);"
                              "create table if not exists thing(id integer primary key autoincrement);"   // (a thing's number is never given again: SQLite's own)
                              "create table if not exists setting(name text primary key, value text) without rowid;"   // (the window's choices kept with the document, not steps: doc_setting)
                              "insert into thing(id) select max(thing) from fact where (select count(*) from thing) = 0 having max(thing) is not null", nullptr, nullptr, nullptr) != SQLITE_OK) return nullptr;
    if (sqlite3_exec(d->file, "select way from fact limit 0", nullptr, nullptr, nullptr) != SQLITE_OK)   // (a document from before stretches had ways)
        sqlite3_exec(d->file, "alter table fact add column way text", nullptr, nullptr, nullptr);
    if (sqlite3_exec(d->file, "select made from step limit 0", nullptr, nullptr, nullptr) != SQLITE_OK)   // (a document from before its steps kept when they were made)
        sqlite3_exec(d->file, "alter table step add column made real", nullptr, nullptr, nullptr);
    // (a document from before its moments were numeric: SQLite's session keeps a row whose moment is a whole number
    //  made and then changed in one act as two, if the moment is real, and that step cannot be undone. Made again once)
    bool real = false;
    doc_rows(*d, sqlite3_mprintf("select 1 from pragma_table_info('fact') where name = 'at' and type = 'REAL'"), [&](sqlite3_stmt*) { real = true; });
    if (real)
        sqlite3_exec(d->file, "begin; create table fact_numeric(thing integer, name text, at numeric, value, way text, primary key(thing, name, at)) without rowid;"
                              "insert into fact_numeric select thing, name, at, value, way from fact; drop table fact; alter table fact_numeric rename to fact; commit", nullptr, nullptr, nullptr);
    // (a document from before the copy and scatter values were taken out, the Repeater recipe laying them now: a thing that had any of
    //  them and no script of its own is given the Repeater, and its values under their new names, their keys and ways as they were;
    //  what drove them (`<name>_by`) is dropped, nothing drives those names now. A step it started from is nothing (the recipe's own
    //  is .3), and a scatter's seed is the recipe's own too. A thing with another script keeps its old rows, which nothing reads)
    if (const std::string repeater = doc_recipe_code_path("Repeater"); !repeater.empty()) {
        static const char* const moved[][2] = {{"copy_x", "js_StepX"}, {"copy_y", "js_StepY"}, {"copy_z", "js_StepZ"}, {"copy_columns", "js_Columns"}, {"copy_turn", "js_Turn"},
                                               {"copy_rotate", "js_Rotate"}, {"copy_rotate_x", "js_RotateX"}, {"copy_rotate_y", "js_RotateY"}, {"copy_size", "js_Size"}, {"copy_wide", "js_Wide"},
                                               {"scatter_x", "js_ScatterX"}, {"scatter_y", "js_ScatterY"}, {"scatter_z", "js_ScatterZ"}, {"scatter_rotate", "js_ScatterRotate"},
                                               {"scatter_size", "js_ScatterSize"}, {"drift_x", "js_DriftX"}, {"drift_y", "js_DriftY"}};
        std::string names, by, rename;
        for (const auto& m : moved) {
            names += std::string(names.empty() ? "" : ",") + "'" + m[0] + "'", by += std::string(by.empty() ? "" : ",") + "'" + m[0] + "_by'";
            rename += std::string(" when '") + m[0] + "' then '" + m[1] + "'";
        }
        char* sql = sqlite3_mprintf(
            "begin;"
            "create temp table if not exists old_things(thing integer primary key); delete from old_things;"
            "insert into old_things select distinct thing from fact where name in (%s) and thing not in (select thing from fact where name = 'script' and value not in ('', 'none'));"
            "insert or ignore into fact(thing, name, at, value) select f.thing, 'js_Seed', 0.0, s.value from (select distinct thing from fact where name in ('scatter_x', 'scatter_y', 'scatter_z', 'scatter_rotate', 'scatter_size') and thing in (select thing from old_things)) f join fact s on s.thing = f.thing and s.name = 'seed' and s.at = 0;"
            "insert or ignore into fact(thing, name, at, value) select thing, 'js_StepX', 0.0, 0.0 from old_things where thing not in (select thing from fact where name = 'copy_x');"
            "update fact set name = case name%s end where thing in (select thing from old_things) and name in (%s);"
            "delete from fact where name in (%s);"
            "delete from fact where thing in (select thing from old_things) and name = 'script';"
            "insert into fact(thing, name, at, value) select thing, 'script', 0.0, %Q from old_things;"
            "drop table old_things; commit;", names.c_str(), rename.c_str(), names.c_str(), by.c_str(), repeater.c_str());
        if (sqlite3_exec(d->file, sql, nullptr, nullptr, nullptr) != SQLITE_OK) sqlite3_exec(d->file, "rollback", nullptr, nullptr, nullptr);
        sqlite3_free(sql);
    }
    d->stage = &s;
    s.playing[d] = [d](double now) { doc_moment(*d, now); };
    if (!doc_match(*d)) std::printf("%s\n", d->trouble.c_str());
    return d;
}

// One change to the document (in SQLite's own words), kept as one step of undo; the stage shows it at once. If the
// stage cannot show it, it is not made: the document and the stage stay as they were.
static void doc_act(Doc& d) {
    if (d.act++) return;
    sqlite3_exec(d.file, "begin", nullptr, nullptr, nullptr);
    sqlite3session_create(d.file, "main", &d.acting);
    sqlite3session_attach(d.acting, "fact");
    sqlite3session_attach(d.acting, "way");
    d.act_ok = true;
}
static bool doc_match(Doc& d);
static void doc_forget(Doc& d);
// What a step changed, as a shell is told it: each value (thing, name) its changeset touches, and whether a thing came
// or went (its kind written or taken away). The changeset is SQLite's own record of the step: nothing is missed.
static void doc_note(Doc& d, int size, void* changeset) {
    sqlite3_changeset_iter* it = nullptr;
    if (sqlite3changeset_start(&it, size, changeset) != SQLITE_OK) return;
    int last = -1;
    while (sqlite3changeset_next(it) == SQLITE_ROW) {
        const char* table = nullptr;
        int columns = 0, op = 0, indirect = 0;
        sqlite3changeset_op(it, &table, &columns, &op, &indirect);
        if (!table || strcmp(table, "fact")) { d.things_changed = true; if (table && !strcmp(table, "way")) d.touched.push_back(-1); continue; }   // (the ways defined: anything may go another way)
        sqlite3_value *thing = nullptr, *name = nullptr;
        (op == SQLITE_INSERT ? sqlite3changeset_new : sqlite3changeset_old)(it, 0, &thing);
        (op == SQLITE_INSERT ? sqlite3changeset_new : sqlite3changeset_old)(it, 1, &name);
        if (!thing || !name) continue;
        const std::string n = (const char*)sqlite3_value_text(name);
        d.changed.insert({sqlite3_value_int(thing), n});
        if (sqlite3_value_int(thing) != last) d.touched.push_back(last = sqlite3_value_int(thing));
        if (n == "kind" && op != SQLITE_UPDATE) d.things_changed = true;
    }
    sqlite3changeset_finalize(it);
}
static bool doc_acted(Doc& d) {
    if (d.act == 1 && d.act_unmatched) {   // (the act's changes shown once, all of them: if the stage cannot, none of them is made)
        d.act_unmatched = false;
        doc_forget(d);
        if (d.act_ok && !doc_match(d)) d.act_ok = false;
    }
    if (--d.act) return d.act_ok;
    int size = 0;
    void* changed = nullptr;
    sqlite3session_changeset(d.acting, &size, &changed);
    sqlite3session_delete(d.acting);
    d.acting = nullptr;
    if (size) doc_note(d, size, changed);   // (an act given up changed them too, and back: shown as they are again)
    if (d.act_ok && size) {   // (what was undone and not done again is forgotten: a new step follows the last one that stands)
        sqlite3_exec(d.file, "delete from step where undone", nullptr, nullptr, nullptr);
        sqlite3_stmt* keep = nullptr;
        sqlite3_prepare_v2(d.file, "insert into step(change, made) values(?, (julianday('now') - 2440587.5) * 86400.0)", -1, &keep, nullptr);   // (and when, in seconds: doc_edited)
        sqlite3_bind_blob(keep, 1, changed, size, SQLITE_TRANSIENT);
        sqlite3_step(keep);
        sqlite3_finalize(keep);
    }
    sqlite3_free(changed);
    sqlite3_exec(d.file, d.act_ok ? "commit" : "rollback", nullptr, nullptr, nullptr);
    if (!d.act_ok) { doc_forget(d); const std::string why = d.trouble; doc_match(d); d.trouble = why; }   // (the stage as the document was before the act)
    return d.act_ok;
}
// One change to the document (in SQLite's own words), an act by itself unless it is made within one; the stage shows
// it at once. If the stage cannot show it, it is not made, and no other change of its act is.
static bool doc_change(Doc& d, char* change, bool later) {
    doc_act(d);
    bool ok = d.act_ok;   // (a change before it in this act was refused: d.trouble still says why)
    if (ok && d.writing) ok = false, d.trouble = "the document is being written as a film: it is not changed until that is done";
    if (ok && !(ok = sqlite3_exec(d.file, change, nullptr, nullptr, nullptr) == SQLITE_OK)) d.trouble = sqlite3_errmsg(d.file);
    sqlite3_free(change);
    if (ok && (later || d.act_together) && d.act > 1) d.act_unmatched = true;   // (a key within a larger act, one of a thousand, or any change within motolii_together's: matched once when the act ends)
    else if (ok) {
        doc_forget(d);
        ok = doc_match(d);
    }
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}

// The last step undone (back = true), or the last undone step done again. false: there is none.
// How long the document has been worked on (Alight Motion's Total Edit Time), from when its steps were made: the time
// from one to the next counted while it is under a quarter of an hour, a longer one a break (WakaTime's way of
// counting time at work from its heartbeats, its keystroke timeout 15 minutes by default). Seconds.
static double doc_edited(Doc& d) {
    double all = 0.0, was = -1.0;
    doc_rows(d, sqlite3_mprintf("select made from step where made is not null order by n"), [&](sqlite3_stmt* row) {
        const double at = sqlite3_column_double(row, 0);
        if (was >= 0.0 && at > was && at - was < 900.0) all += at - was;
        was = at;
    });
    return all;
}
static bool doc_step(Doc& d, bool back) {
    int n = 0;
    std::vector<uint8_t> change;
    doc_rows(d, sqlite3_mprintf(back ? "select n, change from step where not undone order by n desc limit 1" : "select n, change from step where undone order by n limit 1"), [&](sqlite3_stmt* row) {
        n = sqlite3_column_int(row, 0);
        change.assign((const uint8_t*)sqlite3_column_blob(row, 1), (const uint8_t*)sqlite3_column_blob(row, 1) + sqlite3_column_bytes(row, 1));
    });
    if (!n) return d.trouble = back ? "nothing to undo" : "nothing to do again", false;
    int size = (int)change.size();
    void* apply = change.data();
    if (back) sqlite3changeset_invert((int)change.size(), change.data(), &size, &apply);
    const bool ok = sqlite3changeset_apply(d.file, size, apply, nullptr, [](void*, int, sqlite3_changeset_iter*) { return (int)SQLITE_CHANGESET_ABORT; }, nullptr) == SQLITE_OK;
    if (ok) doc_note(d, size, apply);
    if (back) sqlite3_free(apply);
    if (!ok) return d.trouble = "the step does not fit the document as it is", false;
    doc_rows(d, sqlite3_mprintf("update step set undone = %d where n = %d", back ? 1 : 0, n));
    doc_forget(d);
    return doc_match(d);
}
// The way of the stretch that begins at a key, said back in one form: a kind's name as the table writes it and all
// its numbers, however it was told ("": there is no key of that value at that moment).
static std::string doc_way_of(Doc& d, int thing, const char* name, double at) {
    std::string said;
    doc_rows(d, sqlite3_mprintf("select coalesce(way, 'Linear') from fact where thing = %d and name = %Q and at = %!.17g and " DOC_KEYED, thing, name, at, thing, name),
             [&](sqlite3_stmt* row) { said = (const char*)sqlite3_column_text(row, 0); });
    Interp kind;
    return !said.empty() && interp_said(said, &kind) == 0 ? interp_words(kind) : said;
}

// Whether a call names a thing that is there and tells it something a thing of its kind can be told (if not,
// d.trouble says what it can be told).
static std::string doc_words(Doc& d, int thing, const char* name);

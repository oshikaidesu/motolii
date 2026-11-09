// doc_marks.h: part of doc.h (the document's length, work area, marks, guides, window settings and stage size). Read only through doc.h.
// How long the document is: to the end of what ends last (a thing with no duration: once through itself); 8 seconds if nothing in it ends.
static double doc_seconds(Doc& d) {
    double all = 0.0;
    for (const auto& [thing, t] : d.shown) {
        const double own = t.film ? (double)t.film->seconds : t.drawn ? (t.drawn->sketch ? 0.0 : (double)t.drawn->seconds) : t.solid ? (double)t.solid->seconds : 0.0, lasts = doc_number(d, thing, "duration", 0, own);
        if (lasts > 0.0) all = std::max(all, doc_number(d, thing, "start", 0, 0) + lasts);
    }
    return all > 0.0 ? all : 8.0;
}

// The work area: the stretch of the document that is played round and written as a film (After Effects' own); not
// said, all of it. And the marks: moments of the document with a name (After Effects' composition markers). Both are
// facts of thing 0, the stage itself, and every change of them is a step.
static bool doc_change(Doc& d, char* change, bool later = false);   // (later: a key, whose act need not show it before its end)
static void doc_work(Doc& d, double* from, double* to) {
    const double all = doc_seconds(d);
    double in = 0.0, out = all;
    doc_rows(d, sqlite3_mprintf("select name, value from fact where thing = 0 and name in ('work_in', 'work_out')"),
             [&](sqlite3_stmt* row) { (strcmp((const char*)sqlite3_column_text(row, 0), "work_in") ? out : in) = sqlite3_column_double(row, 1); });
    *from = std::clamp(in, 0.0, std::max(0.0, all - 1e-3));
    *to = std::clamp(out, *from + 1e-3, all);
}
static bool doc_work_is(Doc& d, double from, double to) {
    if (!(from >= 0.0 && to > from + 1e-3 && to <= 1e6)) return d.trouble = "a work area is from one moment to a later one", false;
    return doc_change(d, sqlite3_mprintf("insert into fact(thing, name, at, value) values(0, 'work_in', 0.0, %!.17g), (0, 'work_out', 0.0, %!.17g) on conflict do update set value = excluded.value", from, to));
}
static bool doc_mark(Doc& d, double at, const char* word) {   // ("": the mark there is taken away, its colour with it)
    if (!(at >= 0.0 && at <= 1e6)) return d.trouble = "a mark is at a moment of the stage: from 0 to 1000000 seconds", false;
    if (strchr(word, '\n')) return d.trouble = "a mark's name is one line", false;
    return doc_change(d, *word ? sqlite3_mprintf("insert into fact(thing, name, at, value) values(0, 'mark', %!.17g, %Q) on conflict do update set value = excluded.value", at, word)
                               : sqlite3_mprintf("delete from fact where thing = 0 and name in ('mark', 'mark_colour') and at = %!.17g", at));
}
// A mark's colour, one of the sixteen label colours (1 to 16; 0: none), as Premiere Pro's, DaVinci Resolve's and
// CapCut's markers have one (golf ㉕, P02: a cut and a hit told apart): a fact beside its name at its moment.
static bool doc_mark_colour(Doc& d, double at, int colour) {
    if (colour < 0 || colour > 16) return d.trouble = "a mark's colour is one of 16 (0: none)", false;
    bool there = false;
    doc_rows(d, sqlite3_mprintf("select 1 from fact where thing = 0 and name = 'mark' and at = %!.17g", at), [&](sqlite3_stmt*) { there = true; });
    if (!there) return d.trouble = "there is no mark at that moment", false;
    return doc_change(d, colour ? sqlite3_mprintf("insert into fact(thing, name, at, value) values(0, 'mark_colour', %!.17g, %d) on conflict do update set value = excluded.value", at, colour)
                                : sqlite3_mprintf("delete from fact where thing = 0 and name = 'mark_colour' and at = %!.17g", at));
}
// The guides: lines across the picture at a place, in points of it (After Effects' composition guides): x, an upright
// line that far from the left; y, a level one that far from the top. Facts of the stage, a change of them a step.
static bool doc_guide(Doc& d, const char* axis, double at, bool on) {
    if (strcmp(axis, "x") && strcmp(axis, "y")) return d.trouble = "a guide is x (upright) or y (level)", false;
    if (!(std::fabs(at) <= 1e5)) return d.trouble = "a guide is within the picture's reach", false;
    return doc_change(d, on ? sqlite3_mprintf("insert into fact(thing, name, at, value) values(0, 'guide_%s', %!.17g, 1) on conflict do nothing", axis, at)
                            : sqlite3_mprintf("delete from fact where thing = 0 and name = 'guide_%s' and at = %!.17g", axis, at));
}
static std::string doc_guides(Doc& d) {   // (a line each: x or y, a space, where)
    std::string all;
    doc_rows(d, sqlite3_mprintf("select substr(name, 7), at from fact where thing = 0 and name in ('guide_x', 'guide_y') order by name, at"), [&](sqlite3_stmt* row) {
        char line[60];
        std::snprintf(line, sizeof line, "%s %.17g\n", (const char*)sqlite3_column_text(row, 0), sqlite3_column_double(row, 1));   // (all of it: a guide is found again by where it is)
        all += line;
    });
    return all;
}
static std::string doc_mark_colours(Doc& d) {   // (a line each, in time: the moment, a space, its colour)
    std::string all;
    doc_rows(d, sqlite3_mprintf("select at, value from fact where thing = 0 and name = 'mark_colour' order by at"), [&](sqlite3_stmt* row) {
        char line[60];
        std::snprintf(line, sizeof line, "%.17g %d\n", sqlite3_column_double(row, 0), sqlite3_column_int(row, 1));
        all += line;
    });
    return all;
}
// The window's own choices kept with the document, not steps of it (their table is not one the steps record): the
// inks and the fonts a new thing comes in, as a PowerPoint file keeps its theme's colours and fonts (golf (90),
// engine_needs.md E4). A word "" takes one away; doc_settings: a line each, the name, a space, the word.
static bool doc_setting(Doc& d, const char* name, const char* word) {
    if (!*name || strchr(name, ' ') || strchr(name, '\n') || strchr(word, '\n')) return d.trouble = "a setting is one word named, one line said", false;
    char* say = *word ? sqlite3_mprintf("insert into setting(name, value) values(%Q, %Q) on conflict do update set value = excluded.value", name, word)
                      : sqlite3_mprintf("delete from setting where name = %Q", name);
    const bool ok = sqlite3_exec(d.file, say, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(say);
    return ok || (d.trouble = sqlite3_errmsg(d.file), false);
}
static std::string doc_settings(Doc& d) {
    std::string all;
    doc_rows(d, sqlite3_mprintf("select name, value from setting order by name"), [&](sqlite3_stmt* row) {
        all += std::string((const char*)sqlite3_column_text(row, 0)) + " " + (const char*)sqlite3_column_text(row, 1) + "\n";
    });
    return all;
}
static std::string doc_marks(Doc& d) {   // (a line each, in time: the moment, a space, the name)
    std::string all;
    doc_rows(d, sqlite3_mprintf("select at, value from fact where thing = 0 and name = 'mark' order by at"), [&](sqlite3_stmt* row) {
        char at[40];
        std::snprintf(at, sizeof at, "%.17g ", sqlite3_column_double(row, 0));   // (all of it: a mark is found again by its moment, to the last digit)
        all += at + std::string((const char*)sqlite3_column_text(row, 1)) + "\n";
    });
    return all;
}

// A document's own stage: how many points wide and high it is (facts of thing 0, which is the stage itself; they are
// not steps: a stage is opened at a size, so a new size is the document's when it is next opened).
// doc_size: read before a stage is opened for the document (false: it does not say, or it is not there yet).
static bool doc_size(const char* path, int* wide, int* high) {
    sqlite3* file = nullptr;
    sqlite3_stmt* rows = nullptr;
    int w = 0, h = 0;
    if (sqlite3_open_v2(path, &file, SQLITE_OPEN_READONLY, nullptr) == SQLITE_OK && sqlite3_prepare_v2(file, "select name, value from fact where thing = 0 and name in ('wide', 'high')", -1, &rows, nullptr) == SQLITE_OK)
        while (sqlite3_step(rows) == SQLITE_ROW) (strcmp((const char*)sqlite3_column_text(rows, 0), "wide") ? h : w) = sqlite3_column_int(rows, 1);
    sqlite3_finalize(rows);
    sqlite3_close(file);
    return w > 0 && h > 0 ? (*wide = w, *high = h, true) : false;
}
// doc_size_words: the change that says it (nullptr: a stage cannot be that size). doc_size_is: a new document told
// the size it was first opened at (no step of undo: there is nothing before it).
static char* doc_size_words(int wide, int high) {
    if (wide < 16 || high < 16 || wide > 8192 || high > 8192 || wide % 2 || high % 2) return nullptr;
    return sqlite3_mprintf("insert into fact(thing, name, at, value) values(0, 'wide', 0.0, %d), (0, 'high', 0.0, %d) on conflict do update set value = excluded.value", wide, high);
}
static bool doc_size_is(sqlite3* file, int wide, int high) {
    char* say = doc_size_words(wide, high);
    const bool ok = say && sqlite3_exec(file, say, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(say);
    return ok;
}


// Included by doc.h; not self-contained. The project's length, work area, marks, guides, window
// settings and stage size.
// Returns how long the project is, in seconds: to the end of what ends last. A layer with no
// duration plays once through itself. Returns 8 if nothing in the project ends.
static double doc_seconds(Doc& d) {
    double all = 0.0;
    for (const auto& [layer, t] : d.shown) {
        const double own = t.video ? (double)t.video->seconds : t.drawn ? (t.drawn->sketch ? 0.0 : (double)t.drawn->seconds) : t.solid ? (double)t.solid->seconds : 0.0, lasts = doc_number(d, layer, "duration", 0, own);
        if (lasts > 0.0) all = std::max(all, doc_number(d, layer, "start", 0, 0) + lasts);
    }
    return all > 0.0 ? all : 8.0;
}

// The work area is the stretch of the project that is played round and exported as a video, as in
// After Effects. If it is not set, it is all of the project. Marks are named times of the project,
// like After Effects' composition markers. Both are keyframes of layer 0, the stage itself, and
// every change to them is an undo step.
// later: a keyframe, whose act need not show it before the act ends.
static bool doc_change(Doc& d, char* change, bool later = false);
// Returns the work area through from and to, in seconds, clamped to the project.
static void doc_work(Doc& d, double* from, double* to) {
    const double all = doc_seconds(d);
    double in = 0.0, out = all;
    doc_rows(d, sqlite3_mprintf("select name, value from keyframe where layer = 0 and name in ('work_in', 'work_out')"),
             [&](sqlite3_stmt* row) { (strcmp((const char*)sqlite3_column_text(row, 0), "work_in") ? out : in) = sqlite3_column_double(row, 1); });
    *from = std::clamp(in, 0.0, std::max(0.0, all - 1e-3));
    *to = std::clamp(out, *from + 1e-3, all);
}
// Sets the work area. Fails unless 0 <= from, from < to and to <= 1000000 seconds.
static bool doc_work_is(Doc& d, double from, double to) {
    if (!(from >= 0.0 && to > from + 1e-3 && to <= 1e6)) return d.error = "a work area is from one moment to a later one", false;
    return doc_change(d, sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(0, 'work_in', 0.0, %!.17g), (0, 'work_out', 0.0, %!.17g) on conflict do update set value = excluded.value", from, to));
}
// Sets the mark at a time to a name, or removes the mark and its color if word is empty. Fails if
// the time is outside 0 to 1000000 seconds or the name is more than one line.
static bool doc_mark(Doc& d, double at, const char* word) {
    if (!(at >= 0.0 && at <= 1e6)) return d.error = "a mark is at a moment of the stage: from 0 to 1000000 seconds", false;
    if (strchr(word, '\n')) return d.error = "a mark's name is one line", false;
    return doc_change(d, *word ? sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(0, 'mark', %!.17g, %Q) on conflict do update set value = excluded.value", at, word)
                               : sqlite3_mprintf("delete from keyframe where layer = 0 and name in ('mark', 'mark_colour') and at = %!.17g", at));
}
// Sets a mark's color to one of the sixteen label colors, 1 to 16, or 0 for none, as Premiere
// Pro's, DaVinci Resolve's and CapCut's markers have one, so that a cut and a hit can be told
// apart. The color is a keyframe beside the mark's name at its time. Fails if there is no mark at
// that time.
static bool doc_mark_colour(Doc& d, double at, int colour) {
    if (colour < 0 || colour > 16) return d.error = "a mark's colour is one of 16 (0: none)", false;
    bool there = false;
    doc_rows(d, sqlite3_mprintf("select 1 from keyframe where layer = 0 and name = 'mark' and at = %!.17g", at), [&](sqlite3_stmt*) { there = true; });
    if (!there) return d.error = "there is no mark at that moment", false;
    return doc_change(d, colour ? sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(0, 'mark_colour', %!.17g, %d) on conflict do update set value = excluded.value", at, colour)
                                : sqlite3_mprintf("delete from keyframe where layer = 0 and name = 'mark_colour' and at = %!.17g", at));
}
// Adds or removes a guide: a line across the image at a place, in points of it, like After Effects'
// composition guides. Axis x is an upright line that far from the left, and axis y is a level line
// that far from the top. Guides are keyframes of the stage, and a change to them is an undo step.
static bool doc_guide(Doc& d, const char* axis, double at, bool on) {
    if (strcmp(axis, "x") && strcmp(axis, "y")) return d.error = "a guide is x (upright) or y (level)", false;
    if (!(std::fabs(at) <= 1e5)) return d.error = "a guide is within the picture's reach", false;
    return doc_change(d, on ? sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(0, 'guide_%s', %!.17g, 1) on conflict do nothing", axis, at)
                            : sqlite3_mprintf("delete from keyframe where layer = 0 and name = 'guide_%s' and at = %!.17g", axis, at));
}
// Returns the guides, one line each: x or y, a space, and where.
static std::string doc_guides(Doc& d) {
    std::string all;
    doc_rows(d, sqlite3_mprintf("select substr(name, 7), at from keyframe where layer = 0 and name in ('guide_x', 'guide_y') order by name, at"), [&](sqlite3_stmt* row) {
        char line[60];
        // Printed with all its digits, because a guide is found again by where it is.
        std::snprintf(line, sizeof line, "%s %.17g\n", (const char*)sqlite3_column_text(row, 0), sqlite3_column_double(row, 1));
        all += line;
    });
    return all;
}
// Returns the mark colors, one line each in time order: the time, a space, and the color.
static std::string doc_mark_colours(Doc& d) {
    std::string all;
    doc_rows(d, sqlite3_mprintf("select at, value from keyframe where layer = 0 and name = 'mark_colour' order by at"), [&](sqlite3_stmt* row) {
        char line[60];
        std::snprintf(line, sizeof line, "%.17g %d\n", sqlite3_column_double(row, 0), sqlite3_column_int(row, 1));
        all += line;
    });
    return all;
}
// The window's own choices, kept with the project. They are not undo steps, because their table is
// not one that undo records. They hold the colors and fonts a new layer comes in, as a PowerPoint
// file keeps its theme's colors and fonts. A word of "" removes a setting. doc_settings returns one
// line each: the name, a space, and the word.
static bool doc_setting(Doc& d, const char* name, const char* word) {
    if (!*name || strchr(name, ' ') || strchr(name, '\n') || strchr(word, '\n')) return d.error = "a setting is one word named, one line said", false;
    char* say = *word ? sqlite3_mprintf("insert into setting(name, value) values(%Q, %Q) on conflict do update set value = excluded.value", name, word)
                      : sqlite3_mprintf("delete from setting where name = %Q", name);
    const bool ok = sqlite3_exec(d.file, say, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(say);
    return ok || (d.error = sqlite3_errmsg(d.file), false);
}
static std::string doc_settings(Doc& d) {
    std::string all;
    doc_rows(d, sqlite3_mprintf("select name, value from setting order by name"), [&](sqlite3_stmt* row) {
        all += std::string((const char*)sqlite3_column_text(row, 0)) + " " + (const char*)sqlite3_column_text(row, 1) + "\n";
    });
    return all;
}
// Returns the marks, one line each in time order: the time, a space, and the name.
static std::string doc_marks(Doc& d) {
    std::string all;
    doc_rows(d, sqlite3_mprintf("select at, value from keyframe where layer = 0 and name = 'mark' order by at"), [&](sqlite3_stmt* row) {
        char at[40];
        // Printed with all its digits, because a mark is found again by its time, to the last
        // digit.
        std::snprintf(at, sizeof at, "%.17g ", sqlite3_column_double(row, 0));
        all += at + std::string((const char*)sqlite3_column_text(row, 1)) + "\n";
    });
    return all;
}

// A project's own stage size: how many points wide and high it is. These are keyframes of layer 0,
// the stage itself. They are not undo steps: a stage is opened at a size, so a new size takes
// effect when the project is next opened. doc_size reads the size before a stage is opened for the
// project. It returns false if the project does not specify, or if the file is not there yet.
static bool doc_size(const char* path, int* wide, int* high) {
    sqlite3* file = nullptr;
    sqlite3_stmt* rows = nullptr;
    int w = 0, h = 0;
    // Opened read only, so it is not brought up to date. A project written with the old table and
    // column names is therefore read by those names, see doc_upgrade.
    if (sqlite3_open_v2(path, &file, SQLITE_OPEN_READONLY, nullptr) == SQLITE_OK
        && (sqlite3_prepare_v2(file, "select name, value from keyframe where layer = 0 and name in ('wide', 'high')", -1, &rows, nullptr) == SQLITE_OK
            || sqlite3_prepare_v2(file, "select name, value from fact where thing = 0 and name in ('wide', 'high')", -1, &rows, nullptr) == SQLITE_OK))
        while (sqlite3_step(rows) == SQLITE_ROW) (strcmp((const char*)sqlite3_column_text(rows, 0), "wide") ? h : w) = sqlite3_column_int(rows, 1);
    sqlite3_finalize(rows);
    sqlite3_close(file);
    return w > 0 && h > 0 ? (*wide = w, *high = h, true) : false;
}
// doc_size_words returns the SQL that sets the size, or nullptr if a stage cannot be that size. A
// size must be even and from 16 to 8192. doc_size_is sets the size that a new project was first
// opened at. It is not an undo step, because there is nothing before it.
static char* doc_size_words(int wide, int high) {
    if (wide < 16 || high < 16 || wide > 8192 || high > 8192 || wide % 2 || high % 2) return nullptr;
    return sqlite3_mprintf("insert into keyframe(layer, name, at, value) values(0, 'wide', 0.0, %d), (0, 'high', 0.0, %d) on conflict do update set value = excluded.value", wide, high);
}
static bool doc_size_is(sqlite3* file, int wide, int high) {
    char* say = doc_size_words(wide, high);
    const bool ok = say && sqlite3_exec(file, say, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(say);
    return ok;
}


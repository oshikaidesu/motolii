// calls_time.h: part of motolii.mm. Read only through motolii.mm. The document's moment, its own picture (poster, still) and facts read without opening it, and the window's thread watched.
double motolii_seconds(Motolii* m) { return by_look(m, [m] { return doc_seconds(*m->d); }); }
int motolii_at(Motolii* m, double seconds) {
    // (sent, not waited for: the window reads what was drawn, at the moment it was drawn (the moment's picture, snapshot.h),
    //  so it need not wait for the hand to tell this one; a later one still waiting replaces it. Past the document's
    //  ends it is refused there, and said in the trouble)
    return posted(m, "at", [m, seconds] {
        if (!(seconds >= 0.0 && seconds <= doc_seconds(*m->d))) { char runs[80]; std::snprintf(runs, sizeof runs, "the document runs from 0 to %.2f seconds", doc_seconds(*m->d)); m->d->error = runs; return; }
        m->now = seconds;   // (told to the stage in the hand's round, the films put there after the document is let go: not here, under its lock)
        if (m->d->stage) m->d->stage->now = seconds;   // (what is asked after this is made at this moment: a round busy with a sketch's frames has not come yet)
    });
}
static bool ends(const char* name, const char* with) { return strlen(name) > strlen(with) && !strcmp(name + strlen(name) - strlen(with), with); }
static bool placed(const char* name) { return std::filesystem::is_directory(std::filesystem::absolute(name).parent_path()); }
// The document's own picture, for a list of documents, as AbsentMotion keeps a project's (MainActivity.kt saveThumbnail:
// a still 256 on its longer side, drawn as the editor is closed at where its playhead is): drawn at the stage's
// poster_at if it is said (Alight Motion's Set Project Thumbnail), else now, made small (thumbnail_at, GStreamer's
// own scaling, reading a .png as it reads a film), and kept in the document with its size and length (table poster,
// not one the undo records: the session is on fact and way), for motolii_doc_properties to read without opening it.
int motolii_poster(Motolii* m, const char* png) {
    return on_render_thread(m, [m, png] {
        Doc& d = doc(m);
        if (!checked(m, ends(png, ".png"), "a picture is a .png") || !checked(m, placed(png), "there is no such folder")) return 0;
        const std::string whole = (std::filesystem::temp_directory_path() / ("motolii_poster_whole_" + std::to_string(getpid()) + ".png")).string();
        const double at = doc_number(d, 0, "poster_at", 0, -1);
        time_is(*m->s, at >= 0 ? at : (double)m->now);
        const bool shot = shoot(*m->s, whole.c_str());
        time_is(*m->s, m->now);
        const int wide = std::max(1, 256 * m->s->w / std::max({m->s->w, m->s->h, 1}));
        const bool small = shot && thumbnail_at(whole.c_str(), png, wide, 0.0);
        std::remove(whole.c_str());
        if (!checked(m, small, "the picture could not be drawn")) return 0;
        std::ifstream in(png, std::ios::binary);
        const std::vector<char> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (!checked(m, !bytes.empty(), "the picture could not be read back")) return 0;
        sqlite3_exec(d.file, "create table if not exists poster(id integer primary key check (id = 1), png blob, wide integer, high integer, seconds real, rate real)", nullptr, nullptr, nullptr);
        sqlite3_stmt* keep = nullptr;
        sqlite3_prepare_v2(d.file, "insert or replace into poster(id, png, wide, high, seconds, rate) values(1, ?, ?, ?, ?, ?)", -1, &keep, nullptr);
        sqlite3_bind_blob(keep, 1, bytes.data(), (int)bytes.size(), SQLITE_TRANSIENT);
        sqlite3_bind_int(keep, 2, m->s->w), sqlite3_bind_int(keep, 3, m->s->h), sqlite3_bind_double(keep, 4, doc_seconds(d)), sqlite3_bind_double(keep, 5, doc_number(d, 0, "frame_rate", 0, 60));   // (its frames a second, the size box's frame_rate)
        const bool saved = sqlite3_step(keep) == SQLITE_DONE;
        sqlite3_finalize(keep);
        return checked(m, saved, "the document could not keep it");
    });
}
// What a document is, read without opening it (asks nothing of an open one: any thread): "wide high seconds rate" as it
// was last kept (motolii_poster), its picture written to `png` (null: not); "" when it has kept none or is not one.
const char* motolii_doc_properties(const char* path, const char* png) {
    static thread_local std::string out;
    out.clear();
    sqlite3* file = nullptr;
    if (sqlite3_open_v2(path, &file, SQLITE_OPEN_READONLY, nullptr) == SQLITE_OK) {
        sqlite3_stmt* read = nullptr;
        if (sqlite3_prepare_v2(file, "select png, wide, high, seconds, rate from poster where id = 1", -1, &read, nullptr) == SQLITE_OK && sqlite3_step(read) == SQLITE_ROW) {
            char line[96];
            std::snprintf(line, sizeof line, "%d %d %.3f %g", sqlite3_column_int(read, 1), sqlite3_column_int(read, 2), sqlite3_column_double(read, 3), sqlite3_column_double(read, 4));
            out = line;
            if (png) std::ofstream(png, std::ios::binary).write((const char*)sqlite3_column_blob(read, 0), sqlite3_column_bytes(read, 0));
        }
        sqlite3_finalize(read);
    }
    sqlite3_close(file);
    return out.c_str();
}
int motolii_still(Motolii* m, const char* png) {
    return on_render_thread(m, [m, png] {
        doc(m);
        if (!checked(m, ends(png, ".png"), "a still is a .png") || !checked(m, placed(png), "there is no such folder")) return 0;
        const DocExact exact(doc(m));
        time_is(*m->s, m->now);
        return checked(m, shoot(*m->s, png), "the file could not be written");
    });
}
int motolii_rate(Motolii*) { return RATE; }
// The window's thread watched (Chromium's ThreadRestrictions, in the manner of its DisallowBlocking): while on, any
// change it waits for and any read that waits on the document over 2 ms is kept, named and timed; motolii_broken says
// them all ("" none), one to a line, the last 200. Watched from the opening; turned on again, what was kept is forgotten.
void motolii_watch(Motolii* m, int on) { std::lock_guard<std::mutex> h(m->asked_lock); if (on) m->broke.clear(), m->broken = 0; m->watching = on != 0; }
long motolii_broken_count(Motolii* m) { return m->broken.load(); }   // (no lock: a window may ask it every picture)
const char* motolii_broken(Motolii* m) {
    std::lock_guard<std::mutex> h(m->asked_lock);
    m->listed.clear();
    for (const std::string& one : m->broke) m->listed += (m->listed.empty() ? "" : "\n") + one;
    return m->listed.c_str();
}

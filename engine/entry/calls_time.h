// Included by motolii.mm; not self-contained. Implements the time calls of motolii.h: the
// project's length and current time, its poster image and properties (read without opening it),
// a still image of the preview, and the watch on the app's main thread.

// Returns the length of the project in seconds.
double motolii_seconds(Motolii* m) { return by_look(m, [m] { return doc_seconds(*m->d); }); }
// Sets the preview's time. The change is posted to the render thread and not waited for, and a
// newer one that is still waiting replaces it. The app reads what was drawn and the time it was
// drawn at from the snapshot (entry/snapshot.h), so it need not wait. A time outside the
// project, from 0 to its length, is refused when the render thread handles it, and the reason is
// set as the error.
int motolii_at(Motolii* m, double seconds) {
    return posted(m, "at", [m, seconds] {
        if (!(seconds >= 0.0 && seconds <= doc_seconds(*m->d))) { char runs[80]; std::snprintf(runs, sizeof runs, "the document runs from 0 to %.2f seconds", doc_seconds(*m->d)); m->d->error = runs; return; }
        // The preview's videos are updated in the render thread's loop after the project lock is
        // released, not here under the lock.
        m->now = seconds;
        // Anything asked after this is drawn at this time, even if the render thread is busy
        // drawing other frames and its loop has not run yet.
        if (m->d->stage) m->d->stage->now = seconds;
    });
}
// Returns true if name ends with the suffix and is longer than it.
static bool ends(const char* name, const char* with) { return strlen(name) > strlen(with) && !strcmp(name + strlen(name) - strlen(with), with); }
// Returns true if the folder that would contain the file exists.
static bool placed(const char* name) { return std::filesystem::is_directory(std::filesystem::absolute(name).parent_path()); }
// Writes the project's poster image to png and stores it in the project together with the
// project's size and length, so that motolii_doc_properties can read it without opening the
// project. This follows how AbsentMotion keeps a project thumbnail (MainActivity.kt,
// saveThumbnail: a still 256 pixels on its longer side, drawn at the playhead when the editor
// closes). The poster is drawn at the project's poster_at time if it is set, as in Alight
// Motion's Set Project Thumbnail, otherwise at the current time. It is then scaled down with
// thumbnail_at, which uses GStreamer's own scaling and reads a .png as it reads a video. It is
// stored in the table poster, which is not an undo step because the undo session records only
// the keyframe and easing tables. Returns 1 on success, or 0 on failure with the reason set as
// the error.
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
        // rate is the frames per second, from the project's frame_rate property.
        sqlite3_bind_int(keep, 2, m->s->w), sqlite3_bind_int(keep, 3, m->s->h), sqlite3_bind_double(keep, 4, doc_seconds(d)), sqlite3_bind_double(keep, 5, doc_number(d, 0, "frame_rate", 0, 60));
        const bool saved = sqlite3_step(keep) == SQLITE_DONE;
        sqlite3_finalize(keep);
        return checked(m, saved, "the document could not keep it");
    });
}
// Reads a project's properties without opening it, and without asking anything of an open
// project, so any thread may call it. Returns "width height seconds rate" as last stored by
// motolii_poster, or "" if none were stored or path is not a project. If png is not null the
// poster image is written to it. The result is valid until the next call on this thread.
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
// Writes the preview as it is now to a .png file. Returns 1 on success, or 0 on failure.
int motolii_still(Motolii* m, const char* png) {
    return on_render_thread(m, [m, png] {
        doc(m);
        if (!checked(m, ends(png, ".png"), "a still is a .png") || !checked(m, placed(png), "there is no such folder")) return 0;
        const DocExact exact(doc(m));
        time_is(*m->s, m->now);
        return checked(m, shoot(*m->s, png), "the file could not be written");
    });
}
// Returns the frame rate of the exported video, in frames per second.
int motolii_rate(Motolii*) { return RATE; }
// Watches the app's main thread, in the manner of Chromium's ThreadRestrictions and its
// DisallowBlocking. While on, any change the main thread waits for and any read that waits on the
// project for more than 2 ms is recorded with its name and duration. motolii_broken returns the
// records, the last 200. Watching is on from the time the project is opened, and turning it on
// again clears the records.
void motolii_watch(Motolii* m, int on) { std::lock_guard<std::mutex> h(m->asked_lock); if (on) m->broke.clear(), m->broken = 0; m->watching = on != 0; }
// Takes no lock, because the app may ask for this on every frame.
long motolii_broken_count(Motolii* m) { return m->broken.load(); }
// Returns the records made while watching, one per line, or "" if none. Valid until the next call.
const char* motolii_broken(Motolii* m) {
    std::lock_guard<std::mutex> h(m->asked_lock);
    m->listed.clear();
    for (const std::string& one : m->broke) m->listed += (m->listed.empty() ? "" : "\n") + one;
    return m->listed.c_str();
}

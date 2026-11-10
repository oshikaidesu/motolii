// Included by motolii.mm; not self-contained. Implements export, packing, listing and the
// snapshot calls of motolii.h.

// Writes the work area of the project to a video file: .mp4, .mov (HEVC), .gif, or .png / .jpg
// with one image per frame. Calls from other threads are answered while it runs, but they only
// read the project. Returns 1 on success, or 0 on failure with the reason set as the error.
int motolii_export(Motolii* m, const char* mp4) {
    return on_render_thread(m, [m, mp4] {
        doc(m);
        if (!checked(m, ends(mp4, ".mp4") || ends(mp4, ".mov") || ends(mp4, ".gif") || ends(mp4, ".png") || ends(mp4, ".jpg"), "a film is written as an .mp4, .mov (HEVC), .gif, .png or .jpg (a picture each)") || !checked(m, placed(mp4), "there is no such folder") || !checked(m, !m->d->writing, "it is being written already")) return 0;
        double from = 0.0, to = 0.0;
        // Only the work area is written.
        doc_work(*m->d, &from, &to);
        const int frames = (int)std::lround((to - from) * RATE);
        m->d->writing = true;
        m->d->written_from = from;
        // The render thread that handled this call holds the project lock. Release it while each
        // frame is drawn, as in live playback. Between frames the render thread runs the calls that
        // were asked in the meantime, so an app that asked for the export does not stand still.
        // They read the project but do not change it, and the time of the frame being written is
        // set again afterwards.
        m->d->lock.unlock();
        const int ok = checked(m, film(*m->s, mp4, frames, [m, frames, from](double done) {
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            std::deque<std::function<void()>> todo;
            { std::lock_guard<std::mutex> hold(m->asked_lock); todo.swap(m->asked); }
            for (auto& does : todo) does();
            // The position in frames: a whole number, or a time between frames for motion blur.
            const double at = done * frames;
            // The frame's time, counted from the start of the work area.
            time_is(*m->s, from + (std::fabs(at - std::round(at)) < 1e-6 ? std::round(at) : at) / RATE);
        }, FilmWay{(int)doc_number(*m->d, 0, "render_height", 0, 0), (int)(doc_number(*m->d, 0, "render_rate", 0, 0) > 0 ? doc_number(*m->d, 0, "render_rate", 0, 0) : doc_number(*m->d, 0, "frame_rate", 0, 0)), doc_number(*m->d, 0, "render_mbps", 0, 0), (int)doc_number(*m->d, 0, "render_blur", 0, 0), doc_number(*m->d, 0, "render_alpha", 0, 0) > 0.5}), "the file could not be written");
        m->d->lock.lock();
        m->d->writing = false;
        m->d->written_from = 0.0;
        // Restore the time the preview was at before the export.
        time_is(*m->s, m->now);
        return ok;
    });
}
// Copies the project, as name.motolii, and the files its layers use into a folder, and rewrites
// the file names in the copy to the copied files. Returns how many files were copied, or -1 on
// failure.
int motolii_pack(Motolii* m, const char* folder, const char* name) { return by_look(m, [=] { return doc_pack(*m->d, folder, name); }); }
// Returns every keyframe of the project, one per line, as "layer name at time: value", followed
// by ", then easing" when it has one. Valid until the next call.
const char* motolii_list(Motolii* m) {
    return by_look(m, [m] {
    m->listed.clear();
    doc_rows(*m->d, sqlite3_mprintf("select layer || ' ' || name || ' at ' || cast(at as real) || ': ' || value || coalesce(', then ' || easing, '') from keyframe order by layer, name, at"), [m](sqlite3_stmt* row) { m->listed += std::string("  ") + (const char*)sqlite3_column_text(row, 0) + "\n"; });
    return m->listed.c_str();
    });
}

#include "entry/snapshot.h"
// Returns a snapshot of the project for the app (docs/app/BRIDGE.md), read without the project
// lock. which 1 is the project's snapshot: its own part, and the part of each layer newer than
// `since`. which 2 is the time snapshot. The result is a JSON copy that the caller frees with
// free(). *version is set to the version the snapshot is as of.
char* motolii_snapshot(Motolii* m, int which, long since, long* version) {
    std::lock_guard<std::mutex> hold(m->snapshotLock);
    if (which == 2) return *version = m->timeVersion, strdup(m->timeSnapshot.c_str());
    std::string all = "{\"document\":" + (m->snapshotAll.empty() ? std::string("null") : m->snapshotAll) + ",\"thing\":{";
    bool first = true;
    for (const auto& [layer, part] : m->snapshotLayers)
        if (part.first > since) all += (first ? "\"" : ",\"") + std::to_string(layer) + "\":" + part.second, first = false;
    *version = m->snapshotVersion;
    return strdup((all + "}}").c_str());
}
// Sets the app's one listener, which is called when new snapshots exist.
void motolii_add_listener(Motolii* m, void (*listener)(int which)) { m->listener = listener; }

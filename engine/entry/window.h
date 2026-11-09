// window.h: part of motolii.mm. Read only through motolii.mm. A document opened and closed, what a call answers with
// (said_word, doc, changes), and the window's live side: the stage's picture, the desk, pick, play, what is heard and spent.
void motolii_home(const char* folder) { if (chdir(folder)) std::printf("motolii_home: %s is not a folder\n", folder); }
Motolii* motolii_open(const char* document, int wide, int high) {
    setenv("BACKEND", "webgpu", 0);   // (the inside is on Filament's WebGPU backend, wherever it is opened from)
    ++files_changed();   // (a document opened reads the folders as they are now: BRIDGE.md rule 8, read once as a window opens)
    Motolii* m = new Motolii;
    std::promise<bool> opened;
    auto ok = opened.get_future();
    m->render_thread = std::thread(render_thread_run, m, std::string(document), wide, high, &opened);
    if (ok.get()) return m;
    m->render_thread.join();
    return nullptr;
}
void motolii_close(Motolii* m) {
    if (!m) return;
    { std::lock_guard<std::mutex> hold(m->asked_lock); m->closing = true; }
    m->asked_now.notify_one();
    m->render_thread.join();
    if (m->beat) m->beat->stop();
    if (m->d) sqlite3_close(m->d->file);
}
// A word a call answers with, kept till that same thread asks again: each asker its own (the hand, the window, a question
// on another isolate), as motolii_cache keeps its runs; one kept for all was written over while another still read it.
static std::string& said_word() { static thread_local std::string w; return w; }
static const char* motolii_why(Motolii* m) { return m->error.empty() ? m->d->error.c_str() : m->error.c_str(); }
const char* motolii_error(Motolii* m) { return why_asked.empty() ? motolii_why(m) : why_asked.c_str(); }
static int checked(Motolii* m, bool ok, const char* otherwise = nullptr) { if (!ok && otherwise) m->error = otherwise; return ok ? 1 : 0; }
static Doc& doc(Motolii* m) { m->error.clear(); m->d->error.clear(); return *m->d; }
// What a call that changes the document answers. Refused within an act, at whatever door (a number out of its range
// is refused before anything is changed), the act it is part of is not made.
static int changes(Motolii* m, int done) {
    if (!done && m->d->act) m->d->act_ok = false;
    return done;
}

// The stage's picture, live: started once; then the last finished picture and how many there have been (any thread).
static int live_is(Motolii* m) { return m->live || (m->live = live_open(*m->s)) ? 1 : 0; }
void* motolii_front(Motolii* m) { return m->live ? live_front(m->live) : nullptr; }
unsigned long long motolii_frames(Motolii* m) { return m->live ? m->live->frames.load() : 0; }
void motolii_finished(Motolii* m, void (*listener)(void*), void* with) { m->shown_with = with; m->shown = listener; }
const char* motolii_cache(Motolii* m) {
    static thread_local std::string runs;   // (the asker's own copy: the hand may tell it again meanwhile)
    std::lock_guard<std::mutex> hold(m->cache.runsLock);
    return (runs = m->cache.runs).c_str();
}
static int pick_is(Motolii* m, int layer, int hover) { m->pick = layer, m->hover = hover, m->changed = true; return 1; }
static int desk_is(Motolii* m, int w, int h, double x, double y, double scale, double point) {
    if (!m->live) return 0;
    Stage& s = *m->s;
    if (w < 16 || h < 16 || scale <= 0.0) return s.desk.w = 0, m->changed = true, 0;
    if (!m->live->desk || s.desk.w != (uint32_t)w || s.desk.h != (uint32_t)h) {   // (made again at its new size)
        Live* was = m->live->desk;
        m->live->desk = nullptr;
        live_close(s, was);
        m->live->desk = live_open(s, (uint32_t)w, (uint32_t)h);
    }
    s.desk.w = (uint32_t)w, s.desk.h = (uint32_t)h, s.desk.x = x, s.desk.y = y, s.desk.scale = scale, s.desk.point = point;
    m->changed = true;
    return m->live->desk ? 1 : 0;
}
static int view_camera_is(Motolii* m, const char* word) {   // ("about over far": the window's working eye; nothing said: the camera's)
    Doc& d = doc(m);
    d.viewCameraAsked = std::sscanf(word, "%lf %lf %lf", &d.viewCameraIs[0], &d.viewCameraIs[1], &d.viewCameraIs[2]) == 3;
    time_is(*m->s, m->now);
    snapshot_time(m);
    m->changed = true;
    return 1;
}
void* motolii_desk_front(Motolii* m) { return m->live && m->live->desk ? live_front(m->live->desk) : nullptr; }
unsigned long long motolii_desk_frames(Motolii* m) { return m->live && m->live->desk ? m->live->desk->frames.load() : 0; }
int motolii_loop(Motolii* m, int on) {   // (on below 0: only asks: answered at once, not queued behind the hand's picture)
    if (on < 0) return (int)m->loop.load();
    m->loop = on != 0;   // (said at once: the hand reads it as it goes round)
    return on != 0;
}
const char* motolii_shaping(Motolii*) {   // (the cards are the maker's, not the document's: nothing waited for, as motolii_easing_numbers; the window asked it at the opening and waited 22 ms, golf (87))
    std::string all = "kind script shape file split name";   // (and its name: the inspector says it)
    for (const DocCard& c : doc_cards) if (c.when && !doc_among(all, c.when)) all += std::string(" ") + c.when;
    return (said_word() = all).c_str();
}
const char* motolii_spent(Motolii* m) {
    return by_look(m, [=] {
        char line[400];
        std::snprintf(line, sizeof line, "changes %ld %.0f ms, reads %ld %.0f ms, moments %ld %.0f ms, draws %ld %.0f ms (waiting for the GPU %.0f ms); beats drawn on %ld, the GPU not done at %ld, nothing new at %ld, two changes in one %ld, unseen %ld; films put %.0f ms (most %.1f); films' frames kept %ld, from disk %ld, drawn %ld", m->many[0], 1e3 * m->spent[0], m->many[1], 1e3 * m->spent[1], m->many[2], 1e3 * m->spent[2], m->many[3], 1e3 * m->spent[3], m->live ? 1e3 * m->live->waited : 0.0, m->beats_rendered, m->beats_gpu_busy, m->beats_still, m->beats_two, m->beats_unseen, m->videos_ms, m->videos_most, films_cached.load(), films_disk.load(), films_rendered.load());
        std::vector<std::pair<double, std::string>> calls;
        for (const auto& [name, cost] : m->by_call) {
            char one[160];
            std::snprintf(one, sizeof one, "%s %ld %.0f ms (slowest %.1f)", name.c_str(), cost.first, 1e3 * cost.second, 1e3 * m->worst[name]);
            calls.push_back({cost.second, one});
        }
        std::sort(calls.rbegin(), calls.rend());
        said_word() = line;
        if (m->rounds_threw) said_word() += "; the hand's round threw " + std::to_string(m->rounds_threw) + " times";
        { char parts[300]; std::snprintf(parts, sizeof parts, "; the hand's round: files %.0f ms (most %.1f), changes %.0f (%.1f) of which done %.0f (%.1f), telling %.0f (%.1f), GPU asked %.0f (%.1f), ahead %.0f (%.1f), moment and draw %.0f (%.1f)", m->part_ms[0], m->part_most[0], m->part_ms[1], m->part_most[1], m->part_ms[6], m->part_most[6], m->part_ms[2], m->part_most[2], m->part_ms[3], m->part_most[3], m->part_ms[4], m->part_most[4], m->part_ms[5], m->part_most[5]); said_word() += parts; for (double& x : m->part_most) x = 0; }
        char waits[260];
        std::snprintf(waits, sizeof waits, "; reads waited for the document %.0f ms, the longest %.1f ms, %ld over 2 ms; the GPU took %.1f ms a picture, at most %.1f, of %.0f it may", 1e3 * m->read_waited, 1e3 * m->read_waited_most, m->read_waits, m->gpu_ms, m->gpu_most, m->budget);
        said_word() += waits;
        {   // (what the window's own thread asked, the most waited on first)
            std::lock_guard<std::mutex> hold(m->asked_lock);
            std::vector<std::pair<std::string, std::array<double, 4>>> all(m->window.begin(), m->window.end());
            std::sort(all.begin(), all.end(), [](const auto& a, const auto& b) { return a.second[1] + a.second[3] > b.second[1] + b.second[3]; });
            said_word() += "; FROM THE WINDOW";
            for (const auto& [name, w] : all) { char one[200]; std::snprintf(one, sizeof one, "; %s %.0f calls, waited %.1f ms (most %.2f), took %.1f ms", name.c_str(), w[0], 1e3 * w[1], 1e3 * w[2], 1e3 * w[3]); said_word() += one; }
        }
        { std::lock_guard<std::mutex> hold(m->asked_lock); for (const auto& [name, r] : m->rounds) if (r.second) { char one[160]; std::snprintf(one, sizeof one, "; %s waited for the hand up to %.1f ms, %ld over 4 ms", name.c_str(), 1e3 * r.first, r.second); said_word() += one; } }
        for (size_t i = 0; i < calls.size() && i < 20; ++i) said_word() += "; " + calls[i].second;   // (the dearest calls)
        return said_word().c_str();
    });
}
int motolii_play(Motolii* m, int playing) { return posted(m, "play", [m, playing] { m->playing = playing != 0; }); }
double motolii_now(Motolii* m) { return m->now; }


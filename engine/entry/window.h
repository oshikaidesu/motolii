// The window's side of the C API: opening and closing a document, the strings calls answer with,
// and the live side of the window, which is the stage's frame, the preview, selection, playback and
// the timing report. Included by motolii.mm; not self-contained.
// Changes the working directory to folder.
void motolii_home(const char* folder) { if (chdir(folder)) std::printf("motolii_home: %s is not a folder\n", folder); }
// Opens the document on a new render thread and returns the engine, or nullptr if it could not be
// opened. wide and high are the frame size for a new document. A document that stores its own size
// keeps it.
Motolii* motolii_open(const char* document, int wide, int high) {
    // The engine uses Filament's WebGPU backend, wherever it is opened from.
    setenv("BACKEND", "webgpu", 0);
    // A document being opened reads the folders as they are now. They are read once as a window
    // opens (docs/app/BRIDGE.md, rule 8).
    ++files_changed();
    Motolii* m = new Motolii;
    std::promise<bool> opened;
    auto ok = opened.get_future();
    m->render_thread = std::thread(render_thread_run, m, std::string(document), wide, high, &opened);
    if (ok.get()) return m;
    m->render_thread.join();
    return nullptr;
}
// Stops the render thread and closes the document.
void motolii_close(Motolii* m) {
    if (!m) return;
    { std::lock_guard<std::mutex> hold(m->asked_lock); m->closing = true; }
    m->asked_now.notify_one();
    m->render_thread.join();
    if (m->beat) m->beat->stop();
    if (m->d) sqlite3_close(m->d->file);
}
// A string a call answers with. It is kept until the same thread asks again, so each caller has its
// own: the render thread, the window, and a question on another isolate. motolii_cache keeps its
// runs in the same way. One string shared by all was overwritten while another caller still read
// it.
static std::string& said_word() { static thread_local std::string w; return w; }
// Returns the error text: the engine's if it has one, otherwise the document's.
static const char* motolii_why(Motolii* m) { return m->error.empty() ? m->d->error.c_str() : m->error.c_str(); }
// Returns the error text of the calling thread's last call, or the current error text if that call
// left none.
const char* motolii_error(Motolii* m) { return why_asked.empty() ? motolii_why(m) : why_asked.c_str(); }
// Returns 1 if ok. Otherwise sets the error text to otherwise, if given, and returns 0.
static int checked(Motolii* m, bool ok, const char* otherwise = nullptr) { if (!ok && otherwise) m->error = otherwise; return ok ? 1 : 0; }
// Clears the error text and returns the document.
static Doc& doc(Motolii* m) { m->error.clear(); m->d->error.clear(); return *m->d; }
// Returns done, the result of a call that changes the document. If the call was refused while an
// act is open, the act is marked failed so it is not made. This holds at every entry point. For
// example, a number out of its range is refused before anything is changed.
static int changes(Motolii* m, int done) {
    if (!done && m->d->act) m->d->act_ok = false;
    return done;
}

// Opens the stage's live output if it is not open yet. Returns 1 if it is open.
static int live_is(Motolii* m) { return m->live || (m->live = live_open(*m->s)) ? 1 : 0; }
// Returns the last finished frame of the stage, or nullptr.
void* motolii_front(Motolii* m) { return m->live ? live_front(m->live) : nullptr; }
// Returns how many frames of the stage have been finished. Callable from any thread.
unsigned long long motolii_frames(Motolii* m) { return m->live ? m->live->frames.load() : 0; }
// Sets the listener called, with the argument with, whenever a frame is finished.
void motolii_finished(Motolii* m, void (*listener)(void*), void* with) { m->shown_with = with; m->shown = listener; }
// Returns text describing the runs of frames cached on disk.
const char* motolii_cache(Motolii* m) {
    // Each caller gets its own copy, because the render thread may change the runs meanwhile.
    static thread_local std::string runs;
    std::lock_guard<std::mutex> hold(m->cache.runsLock);
    return (runs = m->cache.runs).c_str();
}
// Sets the selected layer and the layer under the pointer, and asks for a redraw. Returns 1.
static int pick_is(Motolii* m, int layer, int hover) { m->pick = layer, m->hover = hover, m->changed = true; return 1; }
// Sets the size of the preview in pixels, its offset x and y, its scale and its point value. Makes
// its output again when the size changes. A side under 16 pixels or a scale that is not positive
// turns the preview off. Returns 1 if the preview's output exists, otherwise 0.
static int desk_is(Motolii* m, int w, int h, double x, double y, double scale, double point) {
    if (!m->live) return 0;
    Stage& s = *m->s;
    if (w < 16 || h < 16 || scale <= 0.0) return s.desk.w = 0, m->changed = true, 0;
    // Make the output again at its new size.
    if (!m->live->desk || s.desk.w != (uint32_t)w || s.desk.h != (uint32_t)h) {
        Live* was = m->live->desk;
        m->live->desk = nullptr;
        live_close(s, was);
        m->live->desk = live_open(s, (uint32_t)w, (uint32_t)h);
    }
    s.desk.w = (uint32_t)w, s.desk.h = (uint32_t)h, s.desk.x = x, s.desk.y = y, s.desk.scale = scale, s.desk.point = point;
    m->changed = true;
    return m->live->desk ? 1 : 0;
}
// Sets the camera that the window works through. word holds three numbers. If it does not, the
// document's own camera is used. Returns 1.
static int view_camera_is(Motolii* m, const char* word) {
    Doc& d = doc(m);
    d.viewCameraAsked = std::sscanf(word, "%lf %lf %lf", &d.viewCameraIs[0], &d.viewCameraIs[1], &d.viewCameraIs[2]) == 3;
    time_is(*m->s, m->now);
    snapshot_time(m);
    m->changed = true;
    return 1;
}
// Returns the last finished frame of the preview, or nullptr.
void* motolii_desk_front(Motolii* m) { return m->live && m->live->desk ? live_front(m->live->desk) : nullptr; }
// Returns how many frames of the preview have been finished.
unsigned long long motolii_desk_frames(Motolii* m) { return m->live && m->live->desk ? m->live->desk->frames.load() : 0; }
// Sets whether playback loops and returns the new state. A negative on only asks. The answer is
// given at once and not queued behind the render thread's frame.
int motolii_loop(Motolii* m, int on) {
    if (on < 0) return (int)m->loop.load();
    // Takes effect at once. The render thread reads it as it goes round.
    m->loop = on != 0;
    return on != 0;
}
// Returns the names of the layer properties that decide which cards the inspector shows. The cards
// belong to the engine, not the document, so nothing waits on the render thread, as in
// motolii_easing_numbers. The window asks this when it opens, and waiting for the render thread
// once cost 22 ms.
const char* motolii_shaping(Motolii*) {
    // name is included because the inspector shows it.
    std::string all = "kind script shape file split name";
    for (const DocCard& c : doc_cards) if (c.when && !doc_among(all, c.when)) all += std::string(" ") + c.when;
    return (said_word() = all).c_str();
}
// Returns a one-line text report of where the engine spent its time. It covers changes, reads,
// evaluations and draws, beat statistics, the parts of the render thread's loop, waits for the
// document, the calls made from the window's thread, and the 20 most expensive calls. It also
// resets the longest time of each part of the loop.
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
        // What the window's own thread asked, with the most waited on first.
        {
            std::lock_guard<std::mutex> hold(m->asked_lock);
            std::vector<std::pair<std::string, std::array<double, 4>>> all(m->window.begin(), m->window.end());
            std::sort(all.begin(), all.end(), [](const auto& a, const auto& b) { return a.second[1] + a.second[3] > b.second[1] + b.second[3]; });
            said_word() += "; FROM THE WINDOW";
            for (const auto& [name, w] : all) { char one[200]; std::snprintf(one, sizeof one, "; %s %.0f calls, waited %.1f ms (most %.2f), took %.1f ms", name.c_str(), w[0], 1e3 * w[1], 1e3 * w[2], 1e3 * w[3]); said_word() += one; }
        }
        { std::lock_guard<std::mutex> hold(m->asked_lock); for (const auto& [name, r] : m->rounds) if (r.second) { char one[160]; std::snprintf(one, sizeof one, "; %s waited for the hand up to %.1f ms, %ld over 4 ms", name.c_str(), 1e3 * r.first, r.second); said_word() += one; } }
        // The most expensive calls.
        for (size_t i = 0; i < calls.size() && i < 20; ++i) said_word() += "; " + calls[i].second;
        return said_word().c_str();
    });
}
// Starts or stops playback. The call is queued and does not wait.
int motolii_play(Motolii* m, int playing) { return posted(m, "play", [m, playing] { m->playing = playing != 0; }); }
// Returns the current time in seconds.
double motolii_now(Motolii* m) { return m->now; }


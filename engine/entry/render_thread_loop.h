// render_thread_loop.h: part of motolii.mm. Read only through motolii.mm. The hand itself: it opens the stage, runs each call
// as it comes, and draws a picture whenever something has changed or time is going on (render_thread.h asks it).
static void motolii_hand(Motolii* m, std::string document, int wide, int high, std::promise<bool>* opened) {
    pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);   // (the hand makes the pictures a window shows: macOS's own word for that, on its fast cores)
    const bool says = doc_size(document.c_str(), &wide, &high);   // (a document that says its own size is opened at it)
    m->s = new Stage(open_stage(wide, high));
    m->s->camera->lookAt({0.f, 0.f, 6.f}, {0.f, 0.f, 0.f}, {0, 1, 0});
    m->s->camera->setProjection(30.0, double(wide) / double(high), 0.05, 60.0, Camera::Fov::VERTICAL);
    m->s->view->setAmbientOcclusionOptions({.enabled = true});
    // (a 3D file may call its faces light-passing: Filament draws such faces in a turn of their own, after the solid
    //  things and before every sheet, so any sheet, however far behind, was painted over them. With that turn off
    //  they are drawn with the solid things, and depth decides. The kit's own glass does not use that turn.)
    m->s->view->setScreenSpaceRefractionEnabled(false);   // (Filament's own: where faces meet it is darker, so a plain solid reads as a solid)
    static LinearToneMapper as_it_is;   // (a film, a photo, typed words keep the colours they came with)
    m->s->view->setColorGrading(ColorGrading::Builder().toneMapper(&as_it_is).build(*m->s->engine));
    const bool ok = room(*m->s, "out/small_studio/small_studio_ibl.ktx", 60000.f) && (m->d = doc_open(*m->s, document.c_str()));
    if (ok && !says) doc_size_is(m->d->file, wide, high), doc_forget(*m->d);   // (a new one is the size it was first opened at; what was read before is read again)
    if (ok) {   // (the window's first pictures of it)
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        picture_update(m), picture_moment(m);
    }
    opened->set_value(ok);
    if (!ok) return;
    auto last = std::chrono::steady_clock::now();
    const auto opened_at = last;   // (the opening's first pictures, its materials made: not a document moving, not judged)
    const auto moving = [m, opened_at](uint64_t drew_before, uint64_t beat) {   // (while something moves: played, or drawn again within two beats, as a hand dragging or scrubbing sends a change each beat; not the opening's first two seconds)
        return m->watching && std::chrono::steady_clock::now() - opened_at > std::chrono::seconds(2) && (m->playing || (drew_before && beat - drew_before <= 2));
    };
    m->beat.reset(thermion::FrameScheduler::create(RATE));
    m->beat->setTargetFps(RATE);
    m->beat->start([](uint64_t, void* p) {
        auto* m = static_cast<Motolii*>(p);
        { std::lock_guard<std::mutex> hold(m->asked_lock); ++m->beats; }
        m->asked_now.notify_one();
    }, m);
    for (;;) {
    try {   // (a throw in the hand's round, a Filament precondition, say: its words said, the round given up: the hand goes on, as the window's own does)

        std::deque<std::function<void()>> todo;
        uint64_t beat;
        {
            m->step = "waiting for a change or a beat";
            std::unique_lock<std::mutex> hold(m->asked_lock);
            const bool goes = m->live && (m->playing || m->changed), begun = m->live && m->live->pending;   // (begun: a picture the GPU has not finished)
            if (begun) m->asked_now.wait_for(hold, std::chrono::milliseconds(1), [m] { return !m->asked.empty() || m->closing; });   // (looked at again a moment later)
            else if (goes) m->asked_now.wait(hold, [m] { return !m->asked.empty() || m->closing || m->beats != m->drew_at; });
            else m->asked_now.wait_for(hold, std::chrono::milliseconds(m->ahead ? 15 : 500), [m] { return !m->asked.empty() || m->closing || (m->live && (m->playing || m->changed)); });   // (twice a second: a file written over; often, while frames ahead are kept)
            if (m->closing) break;
            todo.swap(m->asked);
            beat = m->beats;
            if (m->seen_beat && beat > m->seen_beat + 1) m->beats_unseen += (long)(beat - m->seen_beat - 1);   // (beats that came while the hand was busy elsewhere)
            m->seen_beat = beat;
        }
        auto lap_at = std::chrono::steady_clock::now();
        const auto round_at = lap_at;   // (the round's start: a picture drawn in it took from here, for the red dot)
        const auto lap = [&](int i) { const auto n = std::chrono::steady_clock::now(); const double ms = 1e3 * std::chrono::duration<double>(n - lap_at).count(); m->part_ms[i] += ms; m->part_most[i] = std::max(m->part_most[i], ms); lap_at = n; };
        if (todo.empty() && m->live && ((!m->playing && !m->changed) || m->files_seen != files_changed())) {   // (playing too, once the window says a file changed)
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            m->files_seen = files_changed();
            if (doc_files_moved(*m->d)) doc_match(*m->d), m->changed = true;
        }   // (a shader or a script saved: drawn again)
        lap(0);
        m->step = "doing the changes asked";
        {
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            const long rows = sqlite3_total_changes(m->d->file);
            const auto held = m->d->held.tried;
            for (auto& does : todo) does();
            if (!todo.empty()) ++m->writes_on_beat;
            lap(6);
            if (doc_own_easings(), doc_own_easings_made() != m->picturedWays) m->picturedWays = doc_own_easings_made(), picture_update(m);   // (a way put in the maker's folder: a tile of the Ease desk at once)
            else if (sqlite3_total_changes(m->d->file) != m->picturedRows) picture_update(m);   // (the window's picture of the document, where it changed since it was last made: a call that made it already is not made again, its list of what changed kept)
            if (sqlite3_total_changes(m->d->file) != rows || m->d->held.tried != held)
                (sqlite3_total_changes(m->d->file) != rows ? m->revision : m->carried).fetch_add(1, std::memory_order_release);   // (the document changed, or only what a hand carries: the kept pictures go by these)
        }
        lap(1);
        if (mosh_done.exchange(false)) {   // (a datamosh made meanwhile: the thing made again with it)
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            doc_match(*m->d);
            m->changed = true;
        }
        m->step = "telling the window";
        picture_tell(m);   // (the document let go: the window told what is new)
        if (!m->playing) for (auto& [who, h] : m->heard) if (h.on) gst_element_set_state(h.bin, GST_STATE_PAUSED), h.on = false;   // (the stage stopped: so does its sound)
        lap(2);
        const auto finished = [m] { return m->live ? m->live->frames.load() + (m->live->desk ? m->live->desk->frames.load() : 0) : 0ull; };
        const auto had = finished();
        const bool ready = !m->live || live_ready(*m->s, m->live);   // (the picture begun before, offered once the GPU has finished it)
        if (finished() != had) if (auto tell = m->shown.load()) tell(m->shown_with.load());   // (and Flutter told: Thermion's markTextureFrameAvailable)
        lap(3);
        m->step = "keeping pictures ahead";
        const auto t = std::chrono::steady_clock::now();
        if (!todo.empty() || m->playing || m->changed) m->stirred = t;
        m->ahead = false;
        if (m->live && ready && todo.empty() && !m->playing && !m->changed && t - m->stirred > std::chrono::milliseconds(300)) {   // (the hand rests: a few of each film's frames ahead kept, as Final Cut Pro renders once the hand stops)
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            int begun = 0;
            for (auto& [thing, shown] : m->d->shown)
                if (shown.drawn) begun += picture_ahead(*m->s, shown.drawn, 2);
            if (begun) m->s->engine->flush();
            m->ahead = begun > 0;
            if (t - m->stirred > std::chrono::seconds(5) && !std::getenv("MOTOLII_KEEP_NONE")) {   // (and, five seconds on as Final Cut Pro's background render, the work area's pictures that would be late, kept on disk)
                stage_kept_fresh(m->kept, *m->d, *m->s, m->revision.load(), RATE);
                m->ahead = stage_kept_one(m->kept, *m->d, *m->s, RATE, m->budget) || m->ahead;
            }
        }
        lap(4);
        if (m->live && !m->playing && m->scale != 1.0 && !std::getenv("MOTOLII_SCALE")) stage_scale(m), m->changed = true;   // (stopped: the last picture drawn again full size, for looking)
        if (m->live && beat != m->drew_at && (m->playing || m->changed) && !ready && beat != m->busy_at) {
            m->busy_at = beat, ++m->beats_gpu_busy;
            if (moving(m->drew_at, beat)) {   // (a beat a picture was wanted on, the GPU not done with the last: a missed 60 fps on the GPU)
                const auto last = m->s->renderer->getFrameInfoHistory(1);   // (Filament's own: its last finished frame, as the judge below reads them)
                const double gpu = !last.empty() && last[0].gpuFrameComplete > 0 ? (double)(last[0].gpuFrameComplete - last[0].backendBeginFrame) / 1e6 : 0.0;
                char why[160];
                std::snprintf(why, sizeof why, "the inside's picture on the GPU: not done at the beat (its last took %.1f ms)", gpu);
                std::lock_guard<std::mutex> hold(m->asked_lock);
                broke_one(m, why);
            }
        }
        if (m->live && beat != m->drew_at && !m->playing && !m->changed && beat != m->still_at) m->still_at = beat, ++m->beats_still;   // (a beat with nothing new to draw)
        if (!m->live || beat == m->drew_at || !(m->playing || m->changed) || !ready) { last = m->playing || !ready ? last : t; continue; }   // (not ready: no other picture is begun till it is)
        if (m->playing) {   // (time goes on by the clock, and round again at the document's end)
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            const double runs = doc_seconds(*m->d), on = m->now + std::chrono::duration<double>(t - last).count();
            double from = 0.0, to = runs;
            doc_work(*m->d, &from, &to);   // (round and round within the work area)
            if (on >= to && !m->loop) m->now = to, m->playing = false;   // (once through: it stops at the work area's end)
            else m->now = on >= to || on < from ? from : on;
        }
        last = t;
        const uint64_t drew_before = m->drew_at;
        { std::lock_guard<std::mutex> hold(m->asked_lock); m->drew_at = beat; }
        ++m->beats_drawn;
        if (m->writes_on_beat > 1) ++m->beats_two;   // (more than one change came for this picture: one of them never seen)
        m->writes_on_beat = 0;
        m->s->by_clock = m->playing;
        std::vector<std::function<void()>> films;   // (what the moment asks of the films: done once the document is let go)
        std::map<const void*, Stage::Sound> sounds;
        bool behind = false;   // (a relation that remembers has not caught up: drawn again next beat, as a film without its picture)
        {
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            m->telling = true;
            m->d->live = true, m->d->slice = std::chrono::steady_clock::now();
            m->s->later = &films;
            time_is(*m->s, m->now);
            m->s->later = nullptr;
            if (m->s->desk.w) {   // (the marks on the desk: where the picked thing and the one under the hand are now, as drawn)
                auto& k = m->s->desk;
                k.picked = m->pick > 0 && doc_frame(*m->d, m->pick, m->now, k.pick);
                k.hovered = m->hover > 0 && m->hover != m->pick && doc_frame(*m->d, m->hover, m->now, k.hover);
                k.knob = doc_word(*m->d, m->pick, "kind") != "camera";
            }
            picture_moment(m);   // (the window's picture of this moment)
            m->telling = false;
            behind = std::exchange(m->d->behind, false);
            sounds = heard_told(*m->s);   // (where each sound is to be: read of the document)
        }
        picture_tell(m);
        const auto films_from = std::chrono::steady_clock::now();
        const long films_late = video_late;
        m->step = "putting the films at the moment";
        for (const auto& now : films) now();
        const bool again = (!m->playing && video_late != films_late) || behind;   // (a film without its picture for now yet, a seek under way: drawn again next beat, as a video sink shows its picture once it comes)

        { const double ms = 1e3 * std::chrono::duration<double>(std::chrono::steady_clock::now() - films_from).count(); m->films_ms += ms; m->films_most = std::max(m->films_most, ms); }   // (films put back or stepped on, while the shell reads the document)
        m->step = "putting the sounds at the moment";
        heard(sounds, m->heard, m->now, m->playing);   // (and their sound sought and played so)
        const auto told = std::chrono::steady_clock::now();
        {
            std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
            stage_kept_fresh(m->kept, *m->d, *m->s, m->revision.load(), RATE);
        }
        m->step = "drawing";
        if (!m->playing || m->d->viewCameraAsked || m->second || !stage_kept_show(m->kept, *m->s, m->live, m->now, RATE)) live_camera(m);   // (played: a picture kept is put on the stage, not drawn; kept pictures are the camera's and the desk's alone)
        const auto drawn = std::chrono::steady_clock::now();
        lap(5);
        if (++m->judged % 30 == 0) {   // (how long the GPU took for its last pictures, against the time each may have)
            std::vector<int64_t> took;
            for (const auto& f : m->s->renderer->getFrameInfoHistory(30))
                if (f.gpuFrameComplete > 0 && f.backendBeginFrame > 0) took.push_back(f.gpuFrameComplete - f.backendBeginFrame);
            if (took.size() > 10) {
                std::nth_element(took.begin(), took.begin() + took.size() / 2, took.end());
                const double ms = (double)took[took.size() / 2] / 1e6;
                m->gpu_ms = ms, m->gpu_most = std::max(m->gpu_most, ms);
            }
            stage_scale(m);
        }
        m->spent[2] += std::chrono::duration<double>(told - t).count(), m->many[2]++;
        m->spent[3] += std::chrono::duration<double>(drawn - told).count(), m->many[3]++;
        const auto ms = [](auto a, auto b) { return 1e3 * std::chrono::duration<double>(b - a).count(); };
        if (ms(round_at, drawn) > BEAT_MS && moving(drew_before, beat)) {   // (a picture the hand took longer than a beat to make: the next beat came while it was busy, a missed 60 fps, named by its part)
            char why[200];
            std::snprintf(why, sizeof why, "the inside's picture %.1f ms (changes %.1f, the moment %.1f, drawing %.1f)", ms(round_at, drawn), ms(round_at, t), ms(t, told), ms(told, drawn));
            std::lock_guard<std::mutex> hold(m->asked_lock);
            broke_one(m, why);
        }
        m->changed = again;
        } catch (const std::exception& e) {
        std::fprintf(stderr, "motolii: the hand's round threw while %s: %s\n", m->step.load(), e.what());
        m->trouble = std::string("the hand's round threw: ") + e.what();
        ++m->rounds_threw;   // (the trouble goes with the next call; this stays, told in motolii_spent)
        m->telling = false;
        m->changed = false;
        m->playing = false;
    }
    }
    for (auto& [who, h] : m->heard) heard_off(h);
}


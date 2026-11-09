// motolii_hand.h: part of motolii.mm. Read only through motolii.mm. The one hand (Motolii) and how it is asked: by_hand,
// by_look, posted; what was late kept for the window. Its loop is motolii_hand_loop.h, the window's calls motolii_window.h.
#include <CoreText/CoreText.h>
#include "stage/kit/kit.h"
#include "document/doc.h"
#include "stage/live.h"
#include "stage/stage_kept.h"
#include "media/sound_playback.h"
#include "media/sound_level.h"
#include "media/midi_notes.h"
#include <CoreText/CoreText.h>
#include "entry/motolii.h"
#include "rendering/FrameScheduler.hpp"   // (third_party/thermion_frame: the screen's own beat)
#include <set>
#include <sstream>
#include <atomic>
#include <condition_variable>
#include <deque>
#include <future>
#include <mutex>
#include <thread>
#include <pthread.h>
#include <sys/qos.h>
#include <unistd.h>

// One hand does everything that touches the engine: it opens the stage, runs each call as it comes (the caller waits
// for it), and, when the stage is live, draws a picture whenever something has changed or time is going on. The clock
// is the inside's own: the shell is told a picture is finished, it never asks for one to be drawn.
static const int RATE = 60;   // (pictures a second of a written film: the kit's `film` writes that many)
struct Motolii {
    Stage* s = nullptr;
    Doc* d = nullptr;
    Live* live = nullptr;
    int pick = 0, hover = 0;   // the thing picked in the window and the one under its hand: marked on the desk (motolii_pick)
    std::set<int> watched;     // the things the window shows the moving values of (later "watch", Anthem's subscription): in the moment's picture
    std::map<const void*, Heard> heard;   // the things' sound heard as the live stage plays (sound_playback.h)
    std::string trouble, listed;
    std::thread hand;
    std::atomic<const char*> step{"opening"};   // (where the hand is in its round: said by motolii_hand_step, so a shell that waits long can tell why)
    std::mutex asked_lock;
    std::condition_variable asked_now;
    std::unique_ptr<thermion::FrameScheduler> beat;   // (the screen's beat, Thermion's: a picture is drawn on each; CVDisplayLink, DXGI on Windows)
    uint64_t beats = 0, drew_at = 0;                  // (beats come, and the one the last picture was drawn on: under asked_lock)
    long rounds_threw = 0, beats_drawn = 0, beats_gpu_busy = 0, beats_still = 0, writes_on_beat = 0, beats_two = 0, beats_unseen = 0; uint64_t busy_at = 0, still_at = 0, seen_beat = 0; int files_seen = -1; double films_ms = 0, films_most = 0, part_ms[7] = {}, part_most[7] = {};   // (the hand's round in parts: files looked at, changes, telling, GPU asked, ahead, the rest)   // (beats a picture was drawn on, and beats the GPU had not finished the last: for the spent line)
    std::atomic<void (*)(void*)> shown{nullptr};      // (motolii_finished: told when a picture is finished, to tell Flutter)
    std::atomic<void*> shown_with{nullptr};
    std::deque<std::function<void()>> asked;
    std::map<std::string, std::shared_ptr<std::function<void()>>> latest;
    std::string lastPosted;                                      // (the kind of the queue's last, if posted: only that one is replaced)
    int tickets = 0;                                             // (motolii_later: the last ticket given)
    std::map<int, std::pair<int, std::string>> answers;          // (and each change's answer once done: done or not, and why not)
    std::string answered_why;                                    // (the last answer's why, told to the shell)   // (posted and not done yet, by what it is: a later one of the same takes its place)
    bool closing = false, changed = true;
    std::atomic<bool> playing{false};
    bool second = false;   // the Camera View tab is open (live_camera)
    std::chrono::steady_clock::time_point stirred{};   // (the hand's last stir: something asked, or playing, or changed)
    bool ahead = false;                                  // (films' frames ahead being kept while the hand rests: picture_ahead)
    std::atomic<bool> loop{true};   // (play goes round the work area; not: it stops at its end. Atomic: asked without the document)
    std::atomic<bool> keying{false};   // (the document's own, mirrored: asked each picture without waiting for the document)
    std::atomic<bool> telling{false};  // (the hand is telling the stage a moment, the document held: a shell reading now would wait)
    std::atomic<double> now{0.0};
    std::map<std::string, std::pair<long, double>> by_door;   // (what each call has cost, by its name: for measuring)
    std::map<std::string, double> worst;                      // (and its slowest once)
    int made = 0;   // (the thing the last add or make asked later made: a later call for thing -1 means it)
    std::atomic<long> revision{0};   // (how many times the document has changed: read by anyone, without the document's lock)
    std::atomic<long> carried{0};
    std::atomic<bool> watching{true};   // (motolii_watch: the window's thread may not wait on the hand; what did is kept in `broke`, the last 200; watched from the start)
    std::deque<std::string> broke;
    std::atomic<long> broken{0};   // (how many times, since watched)    // (and how many times what a hand carries has: values a window shows while a hand is on them)
    std::map<std::string, std::array<double, 4>> window;     // (a call from the window's own thread, by name: how many, waited in all, waited at most, took in all: what the window waits on)
    double read_waited = 0, read_waited_most = 0; long read_waits = 0;
    std::map<std::string, std::pair<double, long>> rounds;   // (a call through the hand: its longest wait for the answer, and how many waited over 4 ms)   // (reads waiting for the document: in all, the longest, how many waited over 2 ms)
    double budget = std::getenv("MOTOLII_BUDGET") ? std::atof(std::getenv("MOTOLII_BUDGET")) : 12.0;   // (the milliseconds the GPU may take for a live picture, of the 16.7 a picture has)
    long judged = 0;
    double gpu_ms = 0.0, gpu_most = 0.0;   // (the GPU's middle time for the last pictures, and the most it was)
    double scale = 1.0;   // (how large the stage's views are drawn now: stage_scale)
    StageKept kept;       // (the stage's pictures kept on disk for playing: stage_kept.h)
    double spent[4] = {0, 0, 0, 0};   // (seconds the hand spent: asked to change, asked to read, telling the moment, drawing)
    long many[4] = {0, 0, 0, 0};
    // The window's pictures of the document (picture.h, docs/app/BRIDGE.md), set down by the hand, read under their own lock.
    std::mutex pictureLock;
    std::map<int, std::pair<long, std::string>> pictured;   // (each thing's part of the document's picture, and the version it was made at)
    int picturedWays = -1;                                       // (the maker's own ways as they were read when it was last made: doc_own_ways_made)
    long picturedRows = -1;                                      // (the document's changes, by SQLite's count, the document's picture was last made after)
    std::string pictureAll, momentPicture;                  // (the document's own part; the moment's picture)
    long pictureVersion = 0, momentVersion = 0;
    int pictureTold = 0;                                     // (which are new since the window was told: 1 the document's, 2 the moment's)
    long keptTold = 0;                                       // (what of the kept pictures the window was last told of)
    void (*told)(int) = nullptr;                             // (the window's one listener)
};
// What was late or waited, kept for the window's red dot (asked_lock held): its clock time first, so the window lays
// the inside's and its own in one order. A picture has 1/60 s (the beat): more is a missed beat.
static constexpr double BEAT_MS = 1000.0 / 60.0;
static void broke_one(Motolii* m, const char* why) {
    const auto now = std::chrono::system_clock::now();
    const std::time_t at = std::chrono::system_clock::to_time_t(now);
    std::tm tm{};
    localtime_r(&at, &tm);
    char line[240];
    std::snprintf(line, sizeof line, "%02d:%02d:%02d.%03d %s", tm.tm_hour, tm.tm_min, tm.tm_sec, (int)(std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count() % 1000), why);
    m->broke.push_back(line);
    if (m->broke.size() > 200) m->broke.pop_front();
    m->broken++;
}
// The stage's pictures of this beat: with the Camera View tab open, the stage's own picture is the camera's, whichever
// eye the desk has (After Effects' 2 Views, one comp seen by two eyes): the world told its moment by that eye, drawn again.
static void live_camera(Motolii* m) {
    Stage& s = *m->s;
    Doc& d = *m->d;
    if (!m->second) return live_draw(s, m->live);
    const bool desk = m->live->desk && s.desk.w, eye = d.working;
    if (desk) {
        live_draw(s, m->live);
        if (!eye && (s.over || !s.before.empty())) return;   // (the stage's own picture is the camera's already)
        s.engine->destroy(m->live->pending), m->live->pending = nullptr;
    }
    std::lock_guard<std::recursive_timed_mutex> holding(d.lock);
    const uint32_t w = s.desk.w;
    if (eye) d.eyeAsked = false, time_is(s, m->now);
    s.desk.w = 0;
    live_draw(s, m->live);
    s.desk.w = w;
    if (eye) d.eyeAsked = true, time_is(s, m->now);
}
static void picture_update(Motolii* m);
static void picture_moment(Motolii* m);
static void picture_tell(Motolii* m);

// While it plays and the GPU takes longer than it may, the stage's views are drawn smaller and made large again (as
// Filament's own dynamic resolution does; its own reckoning needs timer queries Dawn's backend has not, so the scale is
// set here from the pictures' own times); at rest, full size, for looking. MOTOLII_SCALE: a scale kept, to measure.
static void stage_scale(Motolii* m) {
    static const double kept = std::getenv("MOTOLII_SCALE") ? std::atof(std::getenv("MOTOLII_SCALE")) : 0.0;
    double want = 1.0;
    if (kept > 0.0) want = kept;
    else if (m->playing && m->gpu_ms > 0.0) want = std::clamp(m->scale * std::sqrt(m->budget / m->gpu_ms), 0.5, 1.0);   // (the GPU's time goes with the pixels drawn: as many fewer as it is over)
    if (std::fabs(want - m->scale) < 0.05 && !(want == 1.0 && m->scale != 1.0)) return;
    m->scale = want;
    View::DynamicResolutionOptions o;
    o.enabled = want < 1.0, o.minScale = o.maxScale = math::float2{(float)want}, o.quality = QualityLevel::MEDIUM;
    m->s->view->setDynamicResolutionOptions(o);
}
// Why the asker's own last call was not done: its own, as each thread has its own errno (POSIX), so what the hand does
// next for another asker never says over it (golf_noise.md ㉝).
static thread_local std::string why_asked;
static const char* motolii_why(Motolii* m);
template <class Does> static auto asked(Motolii* m, Does does, bool changes, const char* who) -> decltype(does()) {
    std::string why;
    std::packaged_task<decltype(does())()> task([&why, m, does] {   // (said before the answer is ready: from then the asker may be gone and this frame with it, C++ [futures.state])
        auto out = does();
        why = motolii_why(m);
        return out;
    });
    auto done = task.get_future();
    {
        std::lock_guard<std::mutex> hold(m->asked_lock);
        m->lastPosted.clear();
        m->asked.push_back([&task, m, changes, who] {
            const auto t0 = std::chrono::steady_clock::now();
            task();
            if (changes) m->changed = true;
            const double took = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
            m->spent[changes ? 0 : 1] += took, m->many[changes ? 0 : 1]++;
            auto& door = m->by_door[who];
            door.first++, door.second += took, m->worst[who] = std::max(m->worst[who], took);
        });
    }
    m->asked_now.notify_one();
    const auto sent = std::chrono::steady_clock::now();
    auto out = done.get();
    why_asked = why;
    const double round = std::chrono::duration<double>(std::chrono::steady_clock::now() - sent).count();   // (the shell waited this long for the hand: in the queue and at work)
    { std::lock_guard<std::mutex> hold(m->asked_lock); auto& r = m->rounds[who]; r.first = std::max(r.first, round), r.second += round > 0.004;
      if (pthread_main_np() && m->watching) { char why[160]; std::snprintf(why, sizeof why, "%s waited %.1f ms for the hand (a change the window may only send: motolii_later)", who, 1e3 * round); broke_one(m, why); }
      if (pthread_main_np()) { auto& w = m->window[who]; w[0]++, w[1] += round, w[2] = std::max(w[2], round), w[3] += round; } }
    return out;
}
// Asked of the hand: by_hand for what may change what is seen (the stage is drawn again after), by_look for what only
// reads (nothing drawn again: a shell that reads its cards a hundred times a picture never waits on a hundred pictures).
template <class Does> static auto by_hand(Motolii* m, Does does, const char* who = __builtin_FUNCTION()) -> decltype(does()) {
    return asked(m, [m, does] {   // (the document changed: its revision counted before the asker hears the answer, so a copy it keeps is never read stale)
        const auto now = [m] { return m->d ? (long)sqlite3_total_changes(m->d->file) : 0L; };
        const long rows = now();
        auto out = does();
        if (now() != rows) {   // (the pictures new before the asker hears the answer: they leave why it was refused as it was, picture.h)
            m->revision.fetch_add(1, std::memory_order_release);
            if (!m->d->act) picture_update(m), picture_moment(m);   // (within motolii_together's act, made once when it ends, as the stage is)
        }
        return out;
    }, true, who);
}
// A read is not queued behind the hand: it is done at once, on the asker's own thread, while it holds the document
// (the hand holds it only while it changes the document or tells it a moment, never while a picture is drawn), so a
// shell's hundreds of reads a build never wait on a picture. (The Flutter kin read so: research_notes/flutter_native_kin.md)
// A change the shell does not wait for (where a hand is, the moment the playhead is put at, play or stop): put in the
// hand's queue and answered at once; one of the same kind last in the queue is replaced by it, keeping its place, so
// a hand moving faster than the pictures leaves only where it is now. Only the last: one with others asked after it
// stays, so nothing is done out of the order it was asked (Chromium's input queue coalesces with its back alone:
// MainThreadEventQueue). What it says absolutely (where the hand is, not how far it moved), the document's own reckoning.
static int posted(Motolii* m, const std::string& kind, std::function<void()> does) {
    {
        std::lock_guard<std::mutex> hold(m->asked_lock);
        auto& waiting = m->latest[kind];
        if (waiting && m->lastPosted == kind) *waiting = std::move(does);
        else {
            auto mine = std::make_shared<std::function<void()>>(std::move(does));
            waiting = mine;
            m->asked.push_back([m, kind, mine] {
                std::function<void()> now;
                { std::lock_guard<std::mutex> hold(m->asked_lock); now = std::move(*mine); if (m->latest[kind] == mine) m->latest.erase(kind); }
                now();
                m->changed = true;
            });
            m->lastPosted = kind;
        }
    }
    m->asked_now.notify_one();
    return 1;
}
// A read of the document, done on the asker's thread while it holds the document: the hand's own (making the window's
// pictures, picture.h), a question asked on another isolate, a check. The window's thread asks none (docs/app/BRIDGE.md).
template <class Does> static auto by_look(Motolii* m, Does does, const char* who = __builtin_FUNCTION()) -> decltype(does()) {
    const auto asked = std::chrono::steady_clock::now();
    std::unique_lock<std::recursive_timed_mutex> hold(m->d->lock);
    const auto t0 = std::chrono::steady_clock::now();
    const double waited = std::chrono::duration<double>(t0 - asked).count();   // (a read waits while the hand holds the document: telling a moment, making a change)
    m->read_waited += waited, m->read_waited_most = std::max(m->read_waited_most, waited), m->read_waits += waited > 0.002;
    auto out = does();
    why_asked = motolii_why(m);
    const double took = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    m->spent[1] += took, m->many[1]++;
    auto& door = m->by_door[who];
    door.first++, door.second += took, m->worst[who] = std::max(m->worst[who], took);
    if (pthread_main_np()) { auto& w = m->window[who]; w[0]++, w[1] += waited, w[2] = std::max(w[2], waited), w[3] += took; }
    if (pthread_main_np() && m->watching && waited > 0.002) { char why[160]; std::snprintf(why, sizeof why, "%s waited %.1f ms for the document", who, 1e3 * waited); std::lock_guard<std::mutex> h(m->asked_lock); broke_one(m, why); }
    return out;
}


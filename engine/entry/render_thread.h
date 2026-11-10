#ifndef MOTOLII_ENTRY_RENDER_THREAD_H_
#define MOTOLII_ENTRY_RENDER_THREAD_H_
// Defines Motolii, the state of the render thread, and the helpers that run
// work on it: on_render_thread, by_look and posted. The thread's loop is in
// render_thread_loop.h and the window's calls are in window.h.
#include <pthread.h>
#include <sqlite3.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <utility>
// Thermion's frame scheduler, in engine/third_party/thermion_frame. It calls
// back once per display refresh.
#include "document/document.h"
#include "entry/calls_later.h"
#include "entry/calls_time.h"
#include "entry/motolii.h"
#include "entry/playback.h"
#include "entry/render_thread_loop.h"
#include "entry/snapshot.h"
#include "entry/timing.h"
#include "entry/window.h"
#include "rendering/FrameScheduler.hpp"
#include "stage/live.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Frames per second. This is also the frame rate of an exported video.
inline constexpr int RATE = 60;

// The render thread and the calls waiting for it. That thread does everything
// that touches the engine: it opens the stage, runs each queued call as it
// arrives while the caller waits for the result, and, when the stage is live,
// draws a frame whenever something has changed or time is advancing. The clock
// belongs to the engine. The app is notified when a frame is finished and never
// asks for one to be drawn.
struct RenderThread {
  std::thread thread;
  // Where the render thread is in its loop. Printed to stderr if the loop
  // throws.
  std::atomic<const char*> status{"opening"};
  // Guards the queue and wakes the thread when a call or a beat arrives.
  std::mutex asked_lock;
  std::condition_variable asked_now;
  // Calls waiting to run on the render thread.
  std::deque<std::function<void()>> asked;
  // Posted calls that have not run yet, by kind. A newer call of the same kind
  // replaces the body of the waiting one.
  std::map<std::string, std::shared_ptr<std::function<void()>>> latest;
  // The kind of the last entry in the queue, if it was posted. Only that entry
  // may be replaced.
  std::string lastPosted;
  // closing is set by motolii_close and ends the loop. changed is true when
  // something has changed that a frame has not shown yet.
  bool closing = false, changed = true;
  // The last file-change count checked.
  int files_seen = -1;
  // The last time the render thread had work: a call arrived, playback ran, or
  // the document changed.
  std::chrono::steady_clock::time_point stirred{};
  // True while frames of videos are being cached ahead of time while the thread
  // is otherwise idle. See frames_ahead.
  bool ahead = false;
  // True while the render thread evaluates the stage at a time and holds the
  // document. A reader that asked now would have to wait.
  std::atomic<bool> evaluating{false};
};

// The resolution scale of the stage's views and the GPU times it is set from.
// See stage_scale.
struct DynamicResolution {
  // Milliseconds the GPU may take for a live frame, out of the 16.7 that a
  // frame has at 60 fps. MOTOLII_BUDGET overrides the default.
  double budget = std::getenv("MOTOLII_BUDGET")
                      ? std::atof(std::getenv("MOTOLII_BUDGET"))
                      : 12.0;
  // The number of frames drawn. The GPU time is measured every 30.
  long judged = 0;
  // The median GPU time of the last frames and the largest seen.
  double gpu_ms = 0.0, gpu_most = 0.0;
  // The scale at which the stage's views are drawn now.
  double scale = 1.0;
};

}  // namespace motolii

// The handle that the C API names (entry/motolii.h declares it at global
// scope), so it is defined outside namespace motolii.
struct Motolii {
  motolii::Stage* s = nullptr;
  motolii::Doc* d = nullptr;
  motolii::Live* live = nullptr;
  std::string error, listed;
  // The number of times the document has changed. Can be read from any thread
  // without the document lock.
  std::atomic<long> revision{0};
  // The number of times the values held by an ongoing drag have changed.
  std::atomic<long> dragged{0};

  // The render thread and the calls waiting for it (render_thread.h).
  motolii::RenderThread render_thread;
  // The display's beats (render_thread_loop.h).
  motolii::DisplayBeats display;
  // The resolution scale of the stage's views (render_thread.h).
  motolii::DynamicResolution resolution;
  // What the window has selected and opened (window.h).
  motolii::WindowState window;
  // Playing the project in the preview (playback.h).
  motolii::Playback playback;
  // The changes queued by motolii_later and their answers (calls_later.h).
  motolii::LaterCalls later;
  // The watch on the app's main thread (calls_time.h).
  motolii::MainThreadWatch watch;
  // Where the engine spends its time (timing.h).
  motolii::Timing timing;
  // The window's snapshots of the document (snapshot.h).
  motolii::Snapshots snapshots;
};

namespace motolii {

// Length of one beat in milliseconds. A frame that takes longer misses a beat.
inline constexpr double BEAT_MS = 1000.0 / 60.0;
// Draws the stage's frame for this beat. With the Camera View tab open, the
// stage's own frame is the camera's, whichever camera the tool panel is using.
// This is After Effects' Two Views: one composition seen through two cameras.
// The stage is evaluated at the current time through that camera and drawn
// again.
void live_camera(Motolii* m);
// Sets the resolution scale of the stage's views. While playing, if the GPU
// takes longer than the budget, the views are drawn smaller and scaled up
// again, as Filament's dynamic resolution does. Filament's own estimate needs
// timer queries that the Dawn backend lacks, so the scale is computed here from
// the measured frame times. At rest the scale is 1 so the user can look
// closely. MOTOLII_SCALE fixes the scale, for measurement.
void stage_scale(Motolii* m);
// The reason the calling thread's last call was not done. It is thread-local,
// like errno in POSIX, so what the render thread does next for another caller
// never overwrites it.
extern thread_local std::string why_asked;
// Returns the error text: the engine's if it has one, otherwise the document's.
inline const char* motolii_why(Motolii* m) {
  return m->error.empty() ? m->d->error.c_str() : m->error.c_str();
}
// Runs does() on the render thread and returns its result. The calling thread
// waits. changes says whether the call may change what is seen, in which case
// the stage is drawn again afterwards. who names the call in the timing
// statistics.
template <class Does>
auto asked(Motolii* m, Does does, bool changes, const char* who)
    -> decltype(does()) {
  std::string why;
  // Copy the error text before the result becomes ready. After that the caller
  // may continue and this stack frame may be gone. See C++ [futures.state].
  std::packaged_task<decltype(does())()> task([&why, m, does] {
    auto out = does();
    why = motolii_why(m);
    return out;
  });
  auto done = task.get_future();
  {
    std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
    m->render_thread.lastPosted.clear();
    m->render_thread.asked.push_back([&task, m, changes, who] {
      const auto t0 = std::chrono::steady_clock::now();
      task();
      if (changes) m->render_thread.changed = true;
      const double took =
          std::chrono::duration<double>(std::chrono::steady_clock::now() - t0)
              .count();
      m->timing.spent[changes ? 0 : 1] += took,
          m->timing.many[changes ? 0 : 1]++;
      auto& call = m->timing.by_call[who];
      call.first++, call.second += took,
          m->timing.worst[who] = std::max(m->timing.worst[who], took);
    });
  }
  m->render_thread.asked_now.notify_one();
  const auto sent = std::chrono::steady_clock::now();
  auto out = done.get();
  why_asked = why;
  // How long the caller waited for the render thread, in the queue and at work.
  const double round =
      std::chrono::duration<double>(std::chrono::steady_clock::now() - sent)
          .count();
  {
    std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
    auto& r = m->timing.rounds[who];
    r.first = std::max(r.first, round), r.second += round > 0.004;
    if (pthread_main_np() && m->watch.watching) {
      char why[160];
      std::snprintf(why, sizeof why,
                    "%s waited %.1f ms for the hand (a change the window may "
                    "only send: motolii_later)",
                    who, 1e3 * round);
      broke_one(m, why);
    }
    if (pthread_main_np()) {
      auto& w = m->timing.window[who];
      w[0]++, w[1] += round, w[2] = std::max(w[2], round), w[3] += round;
    }
  }
  return out;
}
// Runs does() on the render thread. Use on_render_thread for calls that may
// change what is seen: the stage is drawn again afterwards. Use by_look for
// calls that only read: nothing is drawn again, so an app that reads its cards
// a hundred times per frame never waits on a hundred frames.
template <class Does>
auto on_render_thread(Motolii* m, Does does,
                      const char* who = __builtin_FUNCTION())
    -> decltype(does()) {
  // Count the document revision before the caller gets its answer, so a copy
  // the caller keeps is never read stale.
  return asked(
      m,
      [m, does] {
        const auto now = [m] {
          return m->d ? (long)sqlite3_total_changes(m->d->file) : 0L;
        };
        const long rows = now();
        auto out = does();
        // Update the snapshots before the caller gets its answer. They then
        // leave the reason a call was refused as it was. See snapshot.h.
        if (now() != rows) {
          m->revision.fetch_add(1, std::memory_order_release);
          // Inside a motolii_together act, the snapshots are made once when the
          // act ends, as the stage is.
          if (!m->d->act.depth) snapshot_update(m), snapshot_time(m);
        }
        return out;
      },
      true, who);
}
// Queues does on the render thread without waiting for it and returns 1 at
// once. Used for changes the app need not wait for: where the pointer is, the
// time the playhead is put at, play or stop. If the last entry in the queue is
// of the same kind, does replaces that entry's body and keeps its place, so a
// pointer moving faster than frames are drawn leaves only where it is now. Only
// the last entry is replaced. An entry with others queued after it stays, so
// calls never run out of order. Chromium's input queue coalesces in the same
// way, with its back entry only (MainThreadEventQueue). Posted calls must state
// absolute values, such as where the pointer is, not how far it moved.
int posted(Motolii* m, const std::string& kind, std::function<void()> does);
// Runs does() on the caller's own thread while it holds the document lock,
// instead of queuing it behind the render thread. The render thread holds the
// lock only while it changes the document or evaluates a time, never while a
// frame is drawn, so the hundreds of reads an app makes during a build never
// wait on a frame. Used by the render thread itself to make the window's
// snapshots (snapshot.h), by questions asked on another isolate, and by checks.
// The window's thread asks none. See docs/app/BRIDGE.md.
template <class Does>
auto by_look(Motolii* m, Does does, const char* who = __builtin_FUNCTION())
    -> decltype(does()) {
  const auto asked = std::chrono::steady_clock::now();
  std::unique_lock<std::recursive_timed_mutex> hold(m->d->lock);
  const auto t0 = std::chrono::steady_clock::now();
  // A read waits while the render thread holds the document, evaluating a time
  // or making a change.
  const double waited = std::chrono::duration<double>(t0 - asked).count();
  m->timing.read_waited += waited,
      m->timing.read_waited_most = std::max(m->timing.read_waited_most, waited),
      m->timing.read_waits += waited > 0.002;
  auto out = does();
  why_asked = motolii_why(m);
  const double took =
      std::chrono::duration<double>(std::chrono::steady_clock::now() - t0)
          .count();
  m->timing.spent[1] += took, m->timing.many[1]++;
  auto& call = m->timing.by_call[who];
  call.first++, call.second += took,
      m->timing.worst[who] = std::max(m->timing.worst[who], took);
  if (pthread_main_np()) {
    auto& w = m->timing.window[who];
    w[0]++, w[1] += waited, w[2] = std::max(w[2], waited), w[3] += took;
  }
  if (pthread_main_np() && m->watch.watching && waited > 0.002) {
    char why[160];
    std::snprintf(why, sizeof why, "%s waited %.1f ms for the document", who,
                  1e3 * waited);
    std::lock_guard<std::mutex> h(m->render_thread.asked_lock);
    broke_one(m, why);
  }
  return out;
}

}  // namespace motolii

#endif  // MOTOLII_ENTRY_RENDER_THREAD_H_

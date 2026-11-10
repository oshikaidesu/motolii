#ifndef MOTOLII_ENTRY_ON_RENDER_THREAD_H_
#define MOTOLII_ENTRY_ON_RENDER_THREAD_H_
// The two ways a call of the C API reaches the project and waits for its
// result: on_render_thread runs it on the render thread, and by_look runs it on
// the caller's own thread while it holds the document. Both time the call for
// motolii_spent. posted, in render_thread.h, queues a call without waiting.
#include <pthread.h>
#include <sqlite3.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <future>
#include <mutex>
#include <string>

#include "document/document.h"
#include "entry/calls_time.h"
#include "entry/motolii.h"
#include "entry/motolii_handle.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "entry/window.h"

namespace motolii {

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

#endif  // MOTOLII_ENTRY_ON_RENDER_THREAD_H_

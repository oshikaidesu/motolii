#ifndef MOTOLII_ENTRY_RENDER_THREAD_H_
#define MOTOLII_ENTRY_RENDER_THREAD_H_
// Defines RenderThread, the render thread and the queue of calls waiting for
// it, and DynamicResolution, the scale it draws the stage at. posted queues a
// call without waiting. The calls that wait are in on_render_thread.h, the
// thread's loop is in render_thread_loop.h and the handle that holds all of
// this is in motolii_handle.h.
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

#include "entry/motolii.h"

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

}  // namespace motolii

#endif  // MOTOLII_ENTRY_RENDER_THREAD_H_

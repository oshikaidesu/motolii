#ifndef MOTOLII_ENTRY_MOTOLII_HANDLE_H_
#define MOTOLII_ENTRY_MOTOLII_HANDLE_H_
// Defines Motolii, the handle behind the C API (entry/motolii.h): an open
// project, the stage it is shown on, and the render thread that works on both.
// Each part of its state is a struct of its own, defined in the header of the
// code that owns it.
#include <atomic>
#include <string>

#include "entry/calls_later.h"
#include "entry/calls_time.h"
#include "entry/motolii.h"
#include "entry/playback.h"
#include "entry/render_thread.h"
#include "entry/render_thread_loop.h"
#include "entry/snapshot.h"
#include "entry/timing.h"
#include "entry/window.h"

namespace motolii {

struct Doc;
struct Live;
struct Stage;

}  // namespace motolii

// entry/motolii.h declares this type at global scope, so it is defined outside
// namespace motolii. motolii_open makes one and starts its render thread, which
// opens the stage and the project.
struct Motolii {
  // The stage, the project open on it and the stage's live output, which is
  // null until live_is opens it.
  motolii::Stage* s = nullptr;
  motolii::Doc* d = nullptr;
  motolii::Live* live = nullptr;
  // Why the engine refused the last call, and the text the last listing call
  // answered with.
  std::string error, listed;
  // The number of times the document has changed. Can be read from any thread
  // without the document lock.
  std::atomic<long> revision{0};
  // The number of times the values held by an ongoing drag have changed.
  std::atomic<long> dragged{0};

  // The parts, each defined in the header named beside it.
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

#endif  // MOTOLII_ENTRY_MOTOLII_HANDLE_H_

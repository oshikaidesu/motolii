#ifndef MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_
#define MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_
// The render thread's loop. Opens the stage and the document, runs each queued
// call, and draws a frame whenever something has changed or time is advancing.
// render_thread.h defines how calls are queued.
#include <cstdint>
#include <future>
#include <memory>
#include <string>

#include "entry/motolii.h"
// Thermion's frame scheduler, in engine/third_party/thermion_frame. It calls
// back once per display refresh.
#include "rendering/FrameScheduler.hpp"

namespace motolii {

// The display's beats, one per refresh, as the loop receives and counts them.
struct DisplayBeats {
  // Display-synchronized callback from Thermion: CVDisplayLink on macOS, DXGI
  // on Windows. One frame is drawn per beat.
  std::unique_ptr<thermion::FrameScheduler> beat;
  // The number of beats received so far, and the beat the last frame was drawn
  // on. Both are guarded by the render thread's asked_lock.
  uint64_t beats = 0, drew_at = 0;
  // The number of loop iterations that ran a change since the last frame was
  // drawn.
  long writes_on_beat = 0;
  // The last beat counted as one where the GPU was busy, as one with nothing
  // new to draw, and as seen, so a beat is counted once.
  uint64_t busy_at = 0, still_at = 0, seen_beat = 0;
};

// Body of the render thread. Opens the stage and the document at the given
// size, reports through opened whether that worked, and then loops until
// closing is set.
void render_thread_run(Motolii* m, std::string document, int wide, int high,
                       std::promise<bool>* opened);

}  // namespace motolii

#endif  // MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_

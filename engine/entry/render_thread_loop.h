#ifndef MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_
#define MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_
// The render thread's loop. Opens the stage and the document, runs each queued
// call, and draws a frame whenever something has changed or time is advancing.
// render_thread.h defines how calls are queued.
#include <future>
#include <string>

#include "entry/motolii.h"

// Body of the render thread. Opens the stage and the document at the given
// size, reports through opened whether that worked, and then loops until
// closing is set.
void render_thread_run(Motolii* m, std::string document, int wide, int high,
                       std::promise<bool>* opened);

#endif  // MOTOLII_ENTRY_RENDER_THREAD_LOOP_H_

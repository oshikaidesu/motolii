#ifndef MOTOLII_ENTRY_CALLS_TIME_H_
#define MOTOLII_ENTRY_CALLS_TIME_H_
// Implements the time calls of motolii.h: the project's length and current
// time, its poster image and properties (read without opening it), a still
// image of the preview, and the watch on the app's main thread.
#include <atomic>
#include <deque>
#include <string>

#include "entry/motolii.h"

namespace motolii {

// The watch on the app's main thread (motolii_watch).
struct MainThreadWatch {
  // Set by motolii_watch. The window's thread must not wait on the render
  // thread. Calls that did wait are recorded in broke, which keeps the last
  // 200. Watching is on from the start.
  std::atomic<bool> watching{true};
  std::deque<std::string> broke;
  // The number of entries added to broke since watching began.
  std::atomic<long> broken{0};
};

// Appends a line with the current wall-clock time and why to m->watch.broke,
// which keeps the last 200 lines. The caller must hold the render thread's
// asked_lock. The time comes first so the window can put the engine's events
// and its own in one order. The window shows these as its red dot.
void broke_one(Motolii* m, const char* why);

// Returns true if name ends with the suffix and is longer than it.
bool ends(const char* name, const char* with);
// Returns true if the folder that would contain the file exists.
bool placed(const char* name);

}  // namespace motolii

#endif  // MOTOLII_ENTRY_CALLS_TIME_H_

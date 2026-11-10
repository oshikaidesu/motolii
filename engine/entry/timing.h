#ifndef MOTOLII_ENTRY_TIMING_H_
#define MOTOLII_ENTRY_TIMING_H_
// Defines Timing, the measurements of where the engine spends its time. The
// render thread's loop and the calls add to them and motolii_spent reports
// them.
#include <array>
#include <map>
#include <string>
#include <utility>

namespace motolii {

struct Timing {
  // Seconds spent, and in the next member the number of calls, for: changes,
  // reads, evaluating a time, and drawing.
  double spent[4] = {0, 0, 0, 0};
  long many[4] = {0, 0, 0, 0};
  // Count and total time of each call, by call name.
  std::map<std::string, std::pair<long, double>> by_call;
  // The slowest single time of each call.
  std::map<std::string, double> worst;
  // Counters of the render thread's loop. In order: loop iterations that threw,
  // beats a frame was drawn on, beats where the GPU had not finished the
  // previous frame, beats with nothing new to draw, frames drawn after more
  // than one change, and beats that arrived while the thread was busy.
  long rounds_threw = 0, beats_rendered = 0, beats_gpu_busy = 0,
       beats_still = 0, beats_two = 0, beats_unseen = 0;
  // videos_ms and videos_most are the total and longest time spent putting
  // videos at the current time. part_ms and part_most are the total and longest
  // time of each part of one loop iteration: file checks, changes,
  // notifications, GPU submission, work ahead, drawing, and the changes alone.
  double videos_ms = 0, videos_most = 0, part_ms[7] = {}, part_most[7] = {};
  // Calls made from the window's own thread, by name: the number of calls, the
  // total time waited, the longest wait, and the total time taken. Shows what
  // the window waits on. Guarded by the render thread's asked_lock.
  std::map<std::string, std::array<double, 4>> window;
  // Reads that waited for the document: the total wait, the longest wait, and
  // the number of waits over 2 ms.
  double read_waited = 0, read_waited_most = 0;
  long read_waits = 0;
  // Calls through the render thread, by name: the longest wait for the answer
  // and the number of waits over 4 ms. Guarded by the render thread's
  // asked_lock.
  std::map<std::string, std::pair<double, long>> rounds;
};

}  // namespace motolii

#endif  // MOTOLII_ENTRY_TIMING_H_

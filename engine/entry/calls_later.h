#ifndef MOTOLII_ENTRY_CALLS_LATER_H_
#define MOTOLII_ENTRY_CALLS_LATER_H_
// Defines LaterCalls, the state of the changes that motolii_later queues and
// motolii_answer answers.
#include <map>
#include <string>
#include <utility>

namespace motolii {

struct LaterCalls {
  // The last ticket handed out by motolii_later.
  int tickets = 0;
  // The result of each finished change, by ticket: whether it was done and, if
  // not, why. Guarded by the render thread's asked_lock.
  std::map<int, std::pair<int, std::string>> answers;
  // The reason given with the last answer, reported to the app.
  std::string answered_why;
  // The layer made by the last add or make call. A later call that passes layer
  // -1 means this one.
  int last_added = 0;
};

}  // namespace motolii

#endif  // MOTOLII_ENTRY_CALLS_LATER_H_

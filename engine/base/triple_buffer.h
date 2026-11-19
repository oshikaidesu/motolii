#ifndef MOTOLII_BASE_TRIPLE_BUFFER_H_
#define MOTOLII_BASE_TRIPLE_BUFFER_H_

// The newest value of one writer, handed to one reader without a lock and
// without a copy: three values, of which the writer fills one, the reader
// reads another, and the third waits between them.

#include <atomic>

namespace motolii {

template <class T>
class TripleBuffer {
 public:
  // The value the writer fills. Only the writer's thread touches it.
  T& back() { return slots_[back_]; }
  // Hands what was filled to the reader. back() is then another value, one the
  // reader is not reading.
  void publish() {
    back_ = between_.exchange(back_ | kNew, std::memory_order_acq_rel) & 3;
  }
  // The newest value published. Only the reader's thread calls this; the value
  // stays as it is until the reader calls again.
  T& front() {
    if (between_.load(std::memory_order_acquire) & kNew)
      front_ = between_.exchange(front_, std::memory_order_acq_rel) & 3;
    return slots_[front_];
  }

 private:
  // Set in between_ when the value waiting there is newer than the reader's.
  static constexpr unsigned kNew = 4;
  T slots_[3];
  // Which value waits between the two, and whether it is new.
  std::atomic<unsigned> between_{1};
  unsigned back_ = 0, front_ = 2;
};

}  // namespace motolii

#endif  // MOTOLII_BASE_TRIPLE_BUFFER_H_

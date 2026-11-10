#ifndef MOTOLII_ENTRY_PLAYBACK_H_
#define MOTOLII_ENTRY_PLAYBACK_H_
// Defines Playback, the state of playing the project in the preview: whether it
// plays, the current time, and the sounds and cached frames that go with it.
#include <atomic>
#include <map>

#include "media/sound_playback.h"
#include "preview/playback_cache.h"

namespace motolii {

struct Playback {
  // True while the project plays (motolii_play).
  std::atomic<bool> playing{false};
  // True if playback goes round the work area. False if it stops at the end.
  // Atomic so it can be read without the document lock.
  std::atomic<bool> loop{true};
  // The current time in seconds (motolii_at, motolii_now).
  std::atomic<double> now{0.0};
  // The sound of each layer, keyed by pointer, while the live stage plays. See
  // sound_playback.h.
  std::map<const void*, Heard> heard;
  // Frames of the stage cached on disk for playback. See
  // preview/playback_cache.h.
  StageCache cache;
};

}  // namespace motolii

#endif  // MOTOLII_ENTRY_PLAYBACK_H_

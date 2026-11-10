#ifndef MOTOLII_PREVIEW_PLAYBACK_CACHE_H_
#define MOTOLII_PREVIEW_PLAYBACK_CACHE_H_

// Caches rendered stage frames on disk for playback, like Final Cut Pro's background render or
// After Effects' disk cache.
//
// The work area tells us what will be played. While the render thread is idle, each frame in it
// is drawn once, the way an exported video frame is drawn. A frame that took longer than one
// frame period to draw would be late during playback, so it is compressed with zstd and written
// to disk, as cached frames are in canvas.h. During playback a cached frame is put on the screen
// instead of being drawn. A light document caches nothing.
// The cache is keyed on the document's content: its keyframes, its easings, the files it uses and
// its size. Any change draws everything again.

#include <atomic>
#include <cstdint>
#include <deque>
#include <future>
#include <mutex>
#include <string>
#include <vector>

#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include "document/kinds.h"
#include "stage/live.h"
#include "stage/render/render_stage.h"

// The on-disk frame cache of the stage and the state needed to fill and play it.
struct StageCache {
    // Hash of the document's current content, which names the cache files.
    uint64_t key = 0;
    // The document revision at which key was computed.
    long revision = -1;
    // The value of files_changed() when key was computed. A file written over changes it, which
    // forces the key to be computed again.
    int seen = -1;
    // The state of each frame in the document: 0 not examined, 1 drawn fast enough so not cached,
    // 2 cached on disk.
    std::vector<uint8_t> state;
    // Stage size in pixels at the time key was computed.
    int w = 0, h = 0;
    // Render target that a frame to cache is drawn into. Same size as the stage.
    filament::RenderTarget* target = nullptr;
    // The texture behind target.
    filament::Texture* into = nullptr;
    // Texture holding a cached frame while it is shown during playback.
    filament::Texture* shown = nullptr;
    // Keys of the most recent documents that have cache files. Undoing back to one of them finds
    // its frames still on disk. Older ones are deleted.
    std::deque<uint64_t> keys;
    // Counts changes to the set of cached frames. The app reads it without locking, like the
    // revision.
    std::atomic<long> told{0};
    // Guards runs.
    std::mutex runsLock;
    // The cached frames as ranges, "from to from to", for the app to mark on its timeline, like
    // After Effects' green line.
    std::string runs;
    // Index of the frame being read from disk ahead of time on its own thread, or -1.
    int ahead = -1;
    // The read-ahead result for frame ahead.
    std::future<std::vector<uint8_t>*> next;
};

// Recomputes the key if the document, its files, or the stage size changed, and resets the
// per-frame state. Cache files already on disk for the new key are found and marked as cached.
void stage_cache_fresh(StageCache& k, Doc& d, Stage& s, long revision, int rate);

// Draws one not-yet-examined frame of the work area, the way an exported video frame is drawn, and
// caches it if it took longer than budget_ms. The render thread is idle, so the result is not
// shown. Returns false if there is no frame left to examine.
bool stage_cache_one(StageCache& k, Doc& d, Stage& s, int rate, double budget_ms);

// Puts the cached frame for the given time on the stage instead of drawing it, and starts reading
// the next frame from disk. Returns false if no frame is cached for that time, in which case the
// caller must draw it.
bool stage_cache_show(StageCache& k, Stage& s, Live* l, double now, int rate);

#endif  // MOTOLII_PREVIEW_PLAYBACK_CACHE_H_

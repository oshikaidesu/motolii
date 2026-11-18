// Implements export, packing, listing and the snapshot calls of motolii.h.
#include <sqlite3.h>

#include <cmath>
#include <cstring>
#include <deque>
#include <functional>
#include <mutex>
#include <string>

#include "document/document.h"
#include "document/edit/presets.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "entry/calls_time.h"
#include "entry/motolii.h"
#include "entry/motolii_handle.h"
#include "entry/on_render_thread.h"
#include "entry/render_thread.h"
#include "entry/window.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace motolii;

// Writes the work area of the project to a video file: .mp4, .mov (HEVC), .gif,
// or .png / .jpg with one image per frame. Calls from other threads are
// answered while it runs, but they only read the project. Returns 1 on success,
// or 0 on failure with the reason set as the error.
int motolii_export(Motolii* m, const char* mp4) {
  return on_render_thread(m, [m, mp4] {
    doc(m);
    if (!checked(m,
                 ends(mp4, ".mp4") || ends(mp4, ".mov") || ends(mp4, ".gif") ||
                     ends(mp4, ".png") || ends(mp4, ".jpg"),
                 "a film is written as an .mp4, .mov (HEVC), .gif, .png or "
                 ".jpg (a picture each)") ||
        !checked(m, placed(mp4), "there is no such folder") ||
        !checked(m, !m->d->video_export.writing, "it is being written already"))
      return 0;
    double from = 0.0, to = 0.0;
    // Only the work area is written.
    doc_work(*m->d, &from, &to);
    const int frames = (int)std::lround((to - from) * RATE);
    m->d->video_export.writing = true;
    m->d->video_export.written_from = from;
    m->d->video_export.written_fraction = 0.0;
    m->d->video_export.cancelled = false;
    // The render thread that handled this call holds the project lock. Release
    // it while each frame is drawn, as in live playback. Between frames the
    // render thread runs the calls that were asked in the meantime, so an app
    // that asked for the export does not stand still. They read the project but
    // do not change it, and the time of the frame being written is set again
    // afterwards.
    m->d->lock.unlock();
    const int ok = checked(
        m,
        film(
            *m->s, mp4, frames,
            [m, frames, from](double done) {
              std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
              std::deque<std::function<void()>> todo;
              {
                std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
                todo.swap(m->render_thread.asked);
              }
              for (auto& does : todo) does();
              // The position in frames: a whole number, or a time between
              // frames for motion blur.
              const double at = done * frames;
              // The frame's time, counted from the start of the work area.
              time_is(*m->s, from + (std::fabs(at - std::round(at)) < 1e-6
                                         ? std::round(at)
                                         : at) /
                                        RATE);
              m->d->video_export.written_fraction = done;
              return m->d->video_export.cancelled;
            },
            FilmWay{(int)doc_number(*m->d, 0, "render_height", 0, 0),
                    (int)(doc_number(*m->d, 0, "render_rate", 0, 0) > 0
                              ? doc_number(*m->d, 0, "render_rate", 0, 0)
                              : doc_number(*m->d, 0, "frame_rate", 0, 0)),
                    doc_number(*m->d, 0, "render_mbps", 0, 0),
                    (int)doc_number(*m->d, 0, "render_blur", 0, 0),
                    doc_number(*m->d, 0, "render_alpha", 0, 0) > 0.5}),
        "the file could not be written");
    m->d->lock.lock();
    const bool was_cancelled = m->d->video_export.cancelled;
    m->d->video_export.writing = false;
    m->d->video_export.written_from = 0.0;
    m->d->video_export.written_fraction = 0.0;
    m->d->video_export.cancelled = false;
    // Restore the time the preview was at before the export.
    time_is(*m->s, m->playback.now);
    // Set the message the app reads when the export returns 0, so that it can
    // tell cancellation apart from a real failure.
    if (was_cancelled) m->d->error = "cancelled";
    return ok;
  });
}

// Asks the running export to bail out at the next frame boundary. Safe to call
// from another thread: writes the flag without the lock, which film() reads
// between frames.
void motolii_export_cancel(Motolii* m) {
  if (m && m->d) m->d->video_export.cancelled = true;
}
// Returns how far the export has come, from 0 at the start to 1 at the last
// frame. Reads [DocExport.written_fraction] without the project lock: the
// render thread writes it as each frame is drawn, the app reads it from its UI
// thread to show the progress, and a double read on a modern CPU is atomic
// enough for a single-writer counter — a stale value never undoes real
// progress because it just lags one frame.
double motolii_export_fraction(Motolii* m) {
  return m && m->d ? m->d->video_export.written_fraction : 0.0;
}

// Copies the project, as name.motolii, and the files its layers use into a
// folder, and rewrites the file names in the copy to the copied files. Returns
// how many files were copied, or -1 on failure.
int motolii_pack(Motolii* m, const char* folder, const char* name) {
  return by_look(m, [=] { return doc_pack(*m->d, folder, name); });
}
// Returns every keyframe of the project, one per line, as "layer name at time:
// value", followed by ", then easing" when it has one. Valid until the next
// call.
const char* motolii_list(Motolii* m) {
  return by_look(m, [m] {
    m->listed.clear();
    doc_rows(
        *m->d,
        sqlite3_mprintf("select layer || ' ' || name || ' at ' || cast(at as "
                        "real) || ': ' || value || coalesce(', then ' || "
                        "easing, '') from keyframe order by layer, name, at"),
        [m](sqlite3_stmt* row) {
          m->listed += std::string("  ") +
                       (const char*)sqlite3_column_text(row, 0) + "\n";
        });
    return m->listed.c_str();
  });
}
// Returns a snapshot of the project for the app (docs/app/BRIDGE.md), read
// without the project lock. which 1 is the project's snapshot: its own part,
// its tables if they are newer than `since` (else null), and the part of each
// layer newer than `since`. which 2 is the time snapshot.
// The result is a JSON copy that the caller frees with free(). *version is set
// to the version the snapshot is as of.
char* motolii_snapshot(Motolii* m, int which, long since, long* version) {
  std::lock_guard<std::mutex> hold(m->snapshots.lock);
  if (which == 2)
    return *version = m->snapshots.timeVersion,
           strdup(m->snapshots.time.c_str());
  std::string all =
      "{\"document\":" +
      (m->snapshots.all.empty() ? std::string("null") : m->snapshots.all) +
      ",\"tables\":" +
      (m->snapshots.tablesVersion > since && !m->snapshots.tables.empty()
           ? m->snapshots.tables
           : std::string("null")) +
      ",\"layer\":{";
  bool first = true;
  for (const auto& [layer, part] : m->snapshots.layers)
    if (part.first > since)
      all +=
          (first ? "\"" : ",\"") + std::to_string(layer) + "\":" + part.second,
          first = false;
  *version = m->snapshots.version;
  return strdup((all + "}}").c_str());
}
// The time snapshot's per-layer layout as flat doubles, copied out under lock.
int motolii_time_layout(Motolii* m, double* out, int capacity) {
  std::lock_guard<std::mutex> hold(m->snapshots.lock);
  const int n = (int)m->snapshots.timeLayout.size();
  if (out && capacity >= n)
    std::memcpy(out, m->snapshots.timeLayout.data(), n * sizeof(double));
  return n;
}
// Sets the app's one listener, which is posted to when new snapshots exist.
void motolii_add_listener(Motolii* m, bool (*post)(int64_t port, void* message),
                          int64_t port) {
  m->snapshots.post = post, m->snapshots.port = port;
}

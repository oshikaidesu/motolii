#include "entry/render_thread_loop.h"

#include <filament/Camera.h>
#include <filament/ColorGrading.h>
#include <filament/Engine.h>
#include <filament/Renderer.h>
#include <filament/ToneMapper.h>
#include <filament/View.h>
#include <gst/gst.h>
#include <pthread.h>
#include <sqlite3.h>
#include <sys/qos.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <exception>
#include <functional>
#include <future>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/recipes.h"
#include "document/undo.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "media/sound_playback.h"
#include "media/video_datamosh.h"
#include "media/video_layer.h"
#include "preview/playback_cache.h"
#include "rendering/FrameScheduler.hpp"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/live.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

void render_thread_run(Motolii* m, std::string document, int wide, int high,
                       std::promise<bool>* opened) {
  // Run at user-interactive priority. The thread makes the frames the window
  // shows, and macOS puts such threads on its performance cores.
  pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
  // A document that stores its own size is opened at that size.
  const bool says = doc_size(document.c_str(), &wide, &high);
  m->s = new Stage(open_stage(wide, high));
  m->s->camera->lookAt({0.f, 0.f, 6.f}, {0.f, 0.f, 0.f}, {0, 1, 0});
  m->s->camera->setProjection(30.0, double(wide) / double(high), 0.05, 60.0,
                              Camera::Fov::VERTICAL);
  // Ambient occlusion darkens the places where faces meet, so a plain solid
  // reads as a solid.
  m->s->view->setAmbientOcclusionOptions({.enabled = true});
  // A 3D file may mark its faces as light-passing. Filament draws such faces in
  // a separate pass after the solid layers and before every sheet, so any
  // sheet, however far behind, was painted over them. With that pass off they
  // are drawn with the solid layers and depth decides. The built-in glass does
  // not use that pass.
  m->s->view->setScreenSpaceRefractionEnabled(false);
  // Tone mapping that leaves colors unchanged, so a video, a photo or typed
  // text keeps the colors it came with.
  static LinearToneMapper as_it_is;
  m->s->view->setColorGrading(
      ColorGrading::Builder().toneMapper(&as_it_is).build(*m->s->engine));
  // Load the image-based lighting environment, then open the document.
  const bool ok =
      room(*m->s, "out/small_studio/small_studio_ibl.ktx", 60000.f) &&
      (m->d = doc_open(*m->s, document.c_str()));
  // A new document takes the size it was first opened at, and what was read
  // before is read again.
  if (ok && !says) doc_size_is(m->d->file, wide, high), doc_forget(*m->d);
  // Make the window's first snapshots.
  if (ok) {
    std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
    snapshot_update(m), snapshot_time(m);
  }
  opened->set_value(ok);
  if (!ok) return;
  auto last = std::chrono::steady_clock::now();
  // The first frames after opening, while materials are made, are not a
  // document in motion and are not judged.
  const auto opened_at = last;
  // Returns true while something moves: playback, or a frame drawn within the
  // last two beats, as a pointer drag or a scrub sends a change on each beat.
  // Always false in the first two seconds after opening.
  const auto moving = [m, opened_at](uint64_t drew_before, uint64_t beat) {
    return m->watching &&
           std::chrono::steady_clock::now() - opened_at >
               std::chrono::seconds(2) &&
           (m->playing || (drew_before && beat - drew_before <= 2));
  };
  m->beat.reset(thermion::FrameScheduler::create(RATE));
  m->beat->setTargetFps(RATE);
  m->beat->start(
      [](uint64_t, void* p) {
        auto* m = static_cast<Motolii*>(p);
        {
          std::lock_guard<std::mutex> hold(m->asked_lock);
          ++m->beats;
        }
        m->asked_now.notify_one();
      },
      m);
  for (;;) {
    // An exception in one loop iteration, such as a Filament precondition
    // failure, is reported on stderr and the iteration is abandoned. The loop
    // goes on, as the window's own thread does.
    try {
      std::deque<std::function<void()>> todo;
      uint64_t beat;
      {
        m->status = "waiting for a change or a beat";
        std::unique_lock<std::mutex> hold(m->asked_lock);
        // begun is true while a frame has been begun that the GPU has not
        // finished.
        const bool running = m->live && (m->playing || m->changed),
                   begun = m->live && m->live->pending;
        // If a frame is in flight, look again after 1 ms. If a frame is wanted,
        // sleep until a call or a beat arrives. Otherwise wake twice a second
        // to notice a file written over, or every 15 ms while frames are being
        // cached ahead.
        if (begun)
          m->asked_now.wait_for(hold, std::chrono::milliseconds(1), [m] {
            return !m->asked.empty() || m->closing;
          });
        else if (running)
          m->asked_now.wait(hold, [m] {
            return !m->asked.empty() || m->closing || m->beats != m->drew_at;
          });
        else
          m->asked_now.wait_for(
              hold, std::chrono::milliseconds(m->ahead ? 15 : 500), [m] {
                return !m->asked.empty() || m->closing ||
                       (m->live && (m->playing || m->changed));
              });
        if (m->closing) break;
        todo.swap(m->asked);
        beat = m->beats;
        // Count beats that came while the thread was busy elsewhere.
        if (m->seen_beat && beat > m->seen_beat + 1)
          m->beats_unseen += (long)(beat - m->seen_beat - 1);
        m->seen_beat = beat;
      }
      auto lap_at = std::chrono::steady_clock::now();
      // The start of this iteration. A frame drawn in it is timed from here,
      // for the red dot.
      const auto round_at = lap_at;
      // Adds the time since the last lap to part i of the loop's timing.
      const auto lap = [&](int i) {
        const auto n = std::chrono::steady_clock::now();
        const double ms =
            1e3 * std::chrono::duration<double>(n - lap_at).count();
        m->part_ms[i] += ms;
        m->part_most[i] = std::max(m->part_most[i], ms);
        lap_at = n;
      };
      // When nothing is queued, check whether a shader or script file was saved
      // and, if so, draw again. While playing, this check runs only when the
      // window reports that a file changed.
      if (todo.empty() && m->live &&
          ((!m->playing && !m->changed) || m->files_seen != files_changed())) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        m->files_seen = files_changed();
        if (doc_files_moved(*m->d)) doc_match(*m->d), m->changed = true;
      }
      lap(0);
      m->status = "doing the changes asked";
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        const long rows = sqlite3_total_changes(m->d->file);
        const auto held = m->d->held.tried;
        for (auto& does : todo) does();
        if (!todo.empty()) ++m->writes_on_beat;
        lap(6);
        // An easing put in the user's own easings folder appears at once as a
        // tile in the Ease panel. Otherwise, if the document changed since its
        // snapshot was last made, make the snapshot again. A call that already
        // made it is not repeated, so its list of what changed is kept.
        if (doc_own_easings(), doc_own_easings_made() != m->snapshotEasings)
          m->snapshotEasings = doc_own_easings_made(), snapshot_update(m);
        else if (sqlite3_total_changes(m->d->file) != m->snapshotRows)
          snapshot_update(m);
        // Count a document revision if the document changed, or a drag count if
        // only the values held by a drag changed. Cached frames are invalidated
        // by these counts.
        if (sqlite3_total_changes(m->d->file) != rows ||
            m->d->held.tried != held)
          (sqlite3_total_changes(m->d->file) != rows ? m->revision : m->dragged)
              .fetch_add(1, std::memory_order_release);
      }
      lap(1);
      // A datamosh finished meanwhile: make the layers again with it.
      if (mosh_done.exchange(false)) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        doc_match(*m->d);
        m->changed = true;
      }
      m->status = "telling the window";
      // The document lock is released. Tell the window what is new.
      snapshot_notify(m);
      // The stage stopped, so its sound stops too.
      if (!m->playing)
        for (auto& [who, h] : m->heard)
          if (h.on)
            gst_element_set_state(h.bin, GST_STATE_PAUSED), h.on = false;
      lap(2);
      const auto finished = [m] {
        return m->live ? m->live->frames.load() +
                             (m->live->desk ? m->live->desk->frames.load() : 0)
                       : 0ull;
      };
      const auto had = finished();
      // Offer the frame begun earlier once the GPU has finished it.
      const bool ready = !m->live || live_ready(*m->s, m->live);
      // Tell Flutter that a frame is available, as Thermion does with
      // markTextureFrameAvailable.
      if (finished() != had)
        if (auto listener = m->shown.load()) listener(m->shown_with.load());
      lap(3);
      m->status = "keeping pictures ahead";
      const auto t = std::chrono::steady_clock::now();
      if (!todo.empty() || m->playing || m->changed) m->stirred = t;
      m->ahead = false;
      // When the thread rests, cache a few frames of each video ahead, as Final
      // Cut Pro renders once the pointer stops.
      if (m->live && ready && todo.empty() && !m->playing && !m->changed &&
          t - m->stirred > std::chrono::milliseconds(300)) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        int begun = 0;
        for (auto& [layer, shown] : m->d->shown)
          if (shown.drawn) begun += frames_ahead(*m->s, shown.drawn, 2);
        if (begun) m->s->engine->flush();
        m->ahead = begun > 0;
        // After five more seconds, as Final Cut Pro does with background
        // rendering, write to disk the frames of the work area that would be
        // late.
        if (t - m->stirred > std::chrono::seconds(5) &&
            !std::getenv("MOTOLII_KEEP_NONE")) {
          stage_cache_fresh(m->cache, *m->d, *m->s, m->revision.load(), RATE);
          m->ahead = stage_cache_one(m->cache, *m->d, *m->s, RATE, m->budget) ||
                     m->ahead;
        }
      }
      lap(4);
      // After playback stops, draw the last frame again at full size, for
      // looking closely.
      if (m->live && !m->playing && m->scale != 1.0 &&
          !std::getenv("MOTOLII_SCALE"))
        stage_scale(m), m->changed = true;
      if (m->live && beat != m->drew_at && (m->playing || m->changed) &&
          !ready && beat != m->busy_at) {
        m->busy_at = beat, ++m->beats_gpu_busy;
        // A frame was wanted on this beat but the GPU had not finished the last
        // one. That is a missed 60 fps on the GPU.
        if (moving(m->drew_at, beat)) {
          // Filament's record of its last finished frame, as the 30-frame check
          // below reads it.
          const auto last = m->s->renderer->getFrameInfoHistory(1);
          const double gpu = !last.empty() && last[0].gpuFrameComplete > 0
                                 ? (double)(last[0].gpuFrameComplete -
                                            last[0].backendBeginFrame) /
                                       1e6
                                 : 0.0;
          char why[160];
          std::snprintf(why, sizeof why,
                        "the inside's picture on the GPU: not done at the beat "
                        "(its last took %.1f ms)",
                        gpu);
          std::lock_guard<std::mutex> hold(m->asked_lock);
          broke_one(m, why);
        }
      }
      // A beat with nothing new to draw.
      if (m->live && beat != m->drew_at && !m->playing && !m->changed &&
          beat != m->still_at)
        m->still_at = beat, ++m->beats_still;
      // Not ready: no other frame is begun until the GPU has finished the last
      // one.
      if (!m->live || beat == m->drew_at || !(m->playing || m->changed) ||
          !ready) {
        last = m->playing || !ready ? last : t;
        continue;
      }
      // Time goes on by the clock, and goes round again at the end of the work
      // area.
      if (m->playing) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        const double runs = doc_seconds(*m->d),
                     on = m->now +
                          std::chrono::duration<double>(t - last).count();
        double from = 0.0, to = runs;
        // Wrap within the work area.
        doc_work(*m->d, &from, &to);
        // Played once through: stop at the end of the work area.
        if (on >= to && !m->loop)
          m->now = to, m->playing = false;
        else
          m->now = on >= to || on < from ? from : on;
      }
      last = t;
      const uint64_t drew_before = m->drew_at;
      {
        std::lock_guard<std::mutex> hold(m->asked_lock);
        m->drew_at = beat;
      }
      ++m->beats_rendered;
      // More than one change came for this frame, so one of them was never
      // seen.
      if (m->writes_on_beat > 1) ++m->beats_two;
      m->writes_on_beat = 0;
      m->s->by_clock = m->playing;
      // What the current time asks of the videos. It runs once the document is
      // released.
      std::vector<std::function<void()>> videos;
      std::map<const void*, Stage::Sound> sounds;
      // True if a relation that remembers has not caught up. The frame is drawn
      // again next beat, as for a video without its frame.
      bool behind = false;
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        m->evaluating = true;
        m->d->live = true, m->d->slice = std::chrono::steady_clock::now();
        m->s->later = &videos;
        time_is(*m->s, m->now);
        m->s->later = nullptr;
        // The marks in the preview: where the selected layer and the layer
        // under the pointer are now, as drawn.
        if (m->s->desk.w) {
          auto& k = m->s->desk;
          k.picked = m->pick > 0 && doc_frame(*m->d, m->pick, m->now, k.pick);
          k.hovered = m->hover > 0 && m->hover != m->pick &&
                      doc_frame(*m->d, m->hover, m->now, k.hover);
          k.rotateHandle = doc_word(*m->d, m->pick, "kind") != "camera";
        }
        // The window's snapshot of this time.
        snapshot_time(m);
        m->evaluating = false;
        behind = std::exchange(m->d->behind, false);
        // Where each sound should be, read from the document.
        sounds = heard_told(*m->s);
      }
      snapshot_notify(m);
      const auto videos_from = std::chrono::steady_clock::now();
      const long late_before = video_late;
      m->status = "putting the films at the moment";
      for (const auto& now : videos) now();
      // A video has no frame yet or a seek is under way. Draw again next beat,
      // as a video sink shows its frame once it arrives.
      const bool again = (!m->playing && video_late != late_before) || behind;

      // Time spent putting videos back or stepping them, while the app reads
      // the document.
      {
        const double ms =
            1e3 * std::chrono::duration<double>(
                      std::chrono::steady_clock::now() - videos_from)
                      .count();
        m->videos_ms += ms;
        m->videos_most = std::max(m->videos_most, ms);
      }
      m->status = "putting the sounds at the moment";
      // Seek and play the sounds in the same way.
      heard(sounds, m->heard, m->now, m->playing);
      const auto evaluated = std::chrono::steady_clock::now();
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        stage_cache_fresh(m->cache, *m->d, *m->s, m->revision.load(), RATE);
      }
      m->status = "drawing";
      // While playing, a cached frame is put on the stage instead of being
      // drawn, when one exists. Cached frames cover only the camera's view and
      // the preview's.
      if (!m->playing || m->d->viewCameraAsked || m->second ||
          !stage_cache_show(m->cache, *m->s, m->live, m->now, RATE))
        live_camera(m);
      const auto rendered = std::chrono::steady_clock::now();
      lap(5);
      // Every 30 frames, measure how long the GPU took for its last frames,
      // against the time each may have.
      if (++m->judged % 30 == 0) {
        std::vector<int64_t> took;
        for (const auto& f : m->s->renderer->getFrameInfoHistory(30))
          if (f.gpuFrameComplete > 0 && f.backendBeginFrame > 0)
            took.push_back(f.gpuFrameComplete - f.backendBeginFrame);
        if (took.size() > 10) {
          std::nth_element(took.begin(), took.begin() + took.size() / 2,
                           took.end());
          const double ms = (double)took[took.size() / 2] / 1e6;
          m->gpu_ms = ms, m->gpu_most = std::max(m->gpu_most, ms);
        }
        stage_scale(m);
      }
      m->spent[2] += std::chrono::duration<double>(evaluated - t).count(),
          m->many[2]++;
      m->spent[3] +=
          std::chrono::duration<double>(rendered - evaluated).count(),
          m->many[3]++;
      const auto ms = [](auto a, auto b) {
        return 1e3 * std::chrono::duration<double>(b - a).count();
      };
      // A frame took the render thread longer than a beat to make, so the next
      // beat came while it was busy. That is a missed 60 fps. It is reported
      // with the time of each part.
      if (ms(round_at, rendered) > BEAT_MS && moving(drew_before, beat)) {
        char why[200];
        std::snprintf(why, sizeof why,
                      "the inside's picture %.1f ms (changes %.1f, the moment "
                      "%.1f, drawing %.1f)",
                      ms(round_at, rendered), ms(round_at, t), ms(t, evaluated),
                      ms(evaluated, rendered));
        std::lock_guard<std::mutex> hold(m->asked_lock);
        broke_one(m, why);
      }
      m->changed = again;
    } catch (const std::exception& e) {
      std::fprintf(stderr, "motolii: the hand's round threw while %s: %s\n",
                   m->status.load(), e.what());
      m->error = std::string("the hand's round threw: ") + e.what();
      // The error text goes with the next call. This count stays and is
      // reported by motolii_spent.
      ++m->rounds_threw;
      m->evaluating = false;
      m->changed = false;
      m->playing = false;
    }
  }
  for (auto& [who, h] : m->heard) heard_off(h);
}

}  // namespace motolii

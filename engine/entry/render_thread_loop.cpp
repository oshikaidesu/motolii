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

#include "document/document.h"
#include "entry/crash_report.h"
#include "gpu/screen_interop.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/recipes.h"
#include "document/undo.h"
#include "entry/calls_time.h"
#include "entry/motolii_handle.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "gpu/screen_interop.h"
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

namespace motolii {

using filament::Camera;
using filament::ColorGrading;
using filament::Engine;
using filament::Renderer;
using filament::View;

void render_thread_run(Motolii* m, std::string document, int wide, int high,
                       std::promise<bool>* opened) {
  // User-interactive priority: macOS schedules this on performance cores.
  pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
  // Open at the document's stored size if it has one.
  const bool says = doc_size(document.c_str(), &wide, &high);
  m->s = new Stage(open_stage(wide, high));
  m->s->camera->lookAt({0.f, 0.f, 6.f}, {0.f, 0.f, 0.f}, {0, 1, 0});
  m->s->camera->setProjection(30.0, double(wide) / double(high), 0.05, 60.0,
                              Camera::Fov::VERTICAL);
  // AO: so a plain solid reads as three-dimensional.
  m->s->view->setAmbientOcclusionOptions({.enabled = true});
  // Off: Filament's refraction pass draws sheets over transparent faces
  // regardless of depth. The built-in glass does not use that pass.
  m->s->view->setScreenSpaceRefractionEnabled(false);
  // Linear tone map: video/photo/text keeps its original colors.
  static filament::LinearToneMapper as_it_is;
  m->s->view->setColorGrading(
      ColorGrading::Builder().toneMapper(&as_it_is).build(*m->s->engine));
  // Load IBL, then open the document.
  const bool ok =
      room(*m->s, "out/small_studio/small_studio_ibl.ktx", 60000.f) &&
      (m->d = doc_open(*m->s, document.c_str()));
  // A new document takes the size it was first opened at.
  if (ok && !says) doc_size_is(m->d->file, wide, high), doc_forget(*m->d);
  if (ok) {
    std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
    snapshot_update(m), snapshot_time(m);
  }
  opened->set_value(ok);
  if (!ok) return;
  auto last = std::chrono::steady_clock::now();
  // Draw once more when a bend changes the outline after the snapshot, so the
  // window's box catches up without waiting for the drag to end.
  uint64_t bent_seen = 0;
  // Skip judging the first frames while materials compile.
  const auto opened_at = last;
  // True while something moves. False in the first 2 s (material compile).
  const auto moving = [m, opened_at](uint64_t drew_before, uint64_t beat) {
    return m->watch.watching &&
           std::chrono::steady_clock::now() - opened_at >
               std::chrono::seconds(2) &&
           (m->playback.playing || (drew_before && beat - drew_before <= 2));
  };
  m->display.beat.reset(thermion::FrameScheduler::create(RATE));
  m->display.beat->setTargetFps(RATE);
  m->display.beat->start(
      [](uint64_t, void* p) {
        auto* m = static_cast<Motolii*>(p);
        {
          std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
          ++m->display.beats;
        }
        m->render_thread.asked_now.notify_one();
      },
      m);
  for (;;) {
    // An exception abandons the iteration; the loop continues.
    try {
      std::deque<std::function<void()>> todo;
      uint64_t beat;
      {
        m->render_thread.status = "waiting for a change or a beat";
        breadcrumb("waiting");
        std::unique_lock<std::mutex> hold(m->render_thread.asked_lock);
        const bool running = m->live &&
                             (m->playback.playing || m->render_thread.changed),
                   begun = m->live && m->live->pending;
        // In-flight: 1 ms. Running: wait for call/beat. Idle: 500 ms (or 15 ms
        // while caching ahead).
        if (begun)
          m->render_thread.asked_now.wait_for(
              hold, std::chrono::milliseconds(1), [m] {
                return !m->render_thread.asked.empty() ||
                       m->render_thread.closing;
              });
        else if (running)
          m->render_thread.asked_now.wait(hold, [m] {
            return !m->render_thread.asked.empty() ||
                   m->render_thread.closing ||
                   m->display.beats != m->display.drew_at;
          });
        else
          m->render_thread.asked_now.wait_for(
              hold,
              std::chrono::milliseconds(m->render_thread.ahead ? 15 : 500),
              [m] {
                return !m->render_thread.asked.empty() ||
                       m->render_thread.closing ||
                       (m->live &&
                        (m->playback.playing || m->render_thread.changed));
              });
        if (m->render_thread.closing) break;
        todo.swap(m->render_thread.asked);
        beat = m->display.beats;
          if (m->display.seen_beat && beat > m->display.seen_beat + 1)
          m->timing.beats_unseen += (long)(beat - m->display.seen_beat - 1);
        m->display.seen_beat = beat;
      }
      auto lap_at = std::chrono::steady_clock::now();
      const auto round_at = lap_at;
      const auto lap = [&](int i) {
        const auto n = std::chrono::steady_clock::now();
        const double ms =
            1e3 * std::chrono::duration<double>(n - lap_at).count();
        m->timing.part_ms[i] += ms;
        m->timing.part_most[i] = std::max(m->timing.part_most[i], ms);
        lap_at = n;
      };
      // Check for changed shader/script files. During playback, only when the
      // window reports a file change.
      if (todo.empty() && m->live &&
          ((!m->playback.playing && !m->render_thread.changed) ||
           m->render_thread.files_seen != files_changed())) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        m->render_thread.files_seen = files_changed();
        if (doc_files_moved(*m->d))
          doc_match(*m->d), m->render_thread.changed = true;
      }
      lap(0);
      m->render_thread.status = "doing the changes asked";
      breadcrumb("changes");
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        const long rows = sqlite3_total_changes(m->d->file);
        for (auto& does : todo) does();
        if (!todo.empty()) ++m->display.writes_on_beat;
        lap(6);
        // User's own easings folder → tile appears at once. Otherwise re-snapshot
        // if the document changed.
        if (doc_own_easings(), doc_own_easings_made() != m->snapshots.easings)
          m->snapshots.easings = doc_own_easings_made(), snapshot_update(m);
        else if (sqlite3_total_changes(m->d->file) != m->snapshots.rows)
          snapshot_update(m);
        // Catch-all revision bump for posted() calls that skip on_render_thread.
        // Harmless if already bumped: stage_cache_fresh compares for equality.
        if (sqlite3_total_changes(m->d->file) != rows)
          m->revision.fetch_add(1, std::memory_order_release);
      }
      lap(1);
      if (mosh_done.exchange(false)) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        doc_match(*m->d);
        m->render_thread.changed = true;
      }
      // Path operator dragged past sheet edge. Grow once; place_canvas headroom
      // prevents this from firing every frame.
      if (m->s->bentOverflow) {
        m->s->bentOverflow = false;
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        doc_forget(*m->d), doc_match(*m->d);
        m->render_thread.changed = true;
      }
      m->render_thread.status = "telling the window";
      breadcrumb("notify");
      snapshot_notify(m);
      if (!m->playback.playing)
        for (auto& [who, h] : m->playback.heard)
          if (h.on)
            gst_element_set_state(h.bin, GST_STATE_PAUSED), h.on = false;
      lap(2);
      const auto finished = [m] {
        return m->live ? m->live->frames.load() +
                             (m->live->desk ? m->live->desk->frames.load() : 0)
                       : 0ull;
      };
      const auto had = finished();
      const bool ready = !m->live || live_ready(*m->s, m->live);
      // Tell Flutter that a frame is available.
      if (finished() != had)
        if (auto listener = m->window.shown.load())
          listener(m->window.shown_with.load());
      lap(3);
      m->render_thread.status = "keeping pictures ahead";
      breadcrumb("cache");
      const auto t = std::chrono::steady_clock::now();
      if (!todo.empty() || m->playback.playing || m->render_thread.changed)
        m->render_thread.stirred = t;
      m->render_thread.ahead = false;
      // Cache a few frames of each video ahead while idle.
      if (m->live && ready && todo.empty() && !m->playback.playing &&
          !m->render_thread.changed &&
          t - m->render_thread.stirred > std::chrono::milliseconds(300)) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        doc_settle(*m->d);
        int begun = 0;
        for (auto& [layer, shown] : m->d->on_stage.shown)
          if (shown.drawn) begun += frames_ahead(*m->s, shown.drawn, 2);
        if (begun) m->s->engine->flush();
        m->render_thread.ahead = begun > 0;
        // After 5 s idle, write work-area frames that would be late to disk.
        if (t - m->render_thread.stirred > std::chrono::seconds(5) &&
            !std::getenv("MOTOLII_KEEP_NONE")) {
          stage_cache_fresh(m->playback.cache, *m->d, *m->s, m->revision.load(),
                            RATE);
          m->render_thread.ahead =
              stage_cache_one(m->playback.cache, *m->d, *m->s, RATE,
                              m->resolution.budget) ||
              m->render_thread.ahead;
        }
      }
      lap(4);
      // Redraw at full size after playback stops.
      if (m->live && !m->playback.playing && m->resolution.scale != 1.0 &&
          !std::getenv("MOTOLII_SCALE"))
        stage_scale(m), m->render_thread.changed = true;
      if (m->live && beat != m->display.drew_at &&
          (m->playback.playing || m->render_thread.changed) && !ready &&
          beat != m->display.busy_at) {
        m->display.busy_at = beat, ++m->timing.beats_gpu_busy;
        // GPU missed this beat: still finishing the previous frame.
        if (moving(m->display.drew_at, beat)) {
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
          std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
          broke_one(m, why);
        }
      }
      if (m->live && beat != m->display.drew_at && !m->playback.playing &&
          !m->render_thread.changed && beat != m->display.still_at)
        m->display.still_at = beat, ++m->timing.beats_still;
      if (!m->live || beat == m->display.drew_at ||
          !(m->playback.playing || m->render_thread.changed) || !ready) {
        last = m->playback.playing || !ready ? last : t;
        continue;
      }
      // Advance by wall clock; loop at the end of the work area.
      if (m->playback.playing) {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        const double runs = doc_seconds(*m->d),
                     on = m->playback.now +
                          std::chrono::duration<double>(t - last).count();
        double from = 0.0, to = runs;
        doc_work(*m->d, &from, &to);
        if (on >= to && !m->playback.loop)
          m->playback.now = to, m->playback.playing = false;
        else
          m->playback.now = on >= to || on < from ? from : on;
      }
      last = t;
      const uint64_t drew_before = m->display.drew_at;
      {
        std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
        m->display.drew_at = beat;
      }
      ++m->timing.beats_rendered;
      if (m->display.writes_on_beat > 1) ++m->timing.beats_two;
      m->display.writes_on_beat = 0;
      m->s->by_clock = m->playback.playing;
      // Video/sound work deferred until the document lock is released.
      std::vector<std::function<void()>> videos;
      std::map<const void*, Stage::Sound> sounds;
      // A relation that remembers has not caught up → redraw next beat.
      bool behind = false;
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        m->render_thread.evaluating = true;
        m->d->solver.live = true,
        m->d->solver.slice = std::chrono::steady_clock::now();
        m->s->later = &videos;
        time_is(*m->s, m->playback.now);
        m->s->later = nullptr;
        if (m->s->desk.w) {
          auto& k = m->s->desk;
          k.picked = m->window.pick > 0 &&
                     doc_frame(*m->d, m->window.pick, m->playback.now, k.pick);
          k.hovered =
              m->window.hover > 0 && m->window.hover != m->window.pick &&
              doc_frame(*m->d, m->window.hover, m->playback.now, k.hover);
          k.rotateHandle = doc_word(*m->d, m->window.pick, "kind") != "camera";
        }
        snapshot_time(m);
        bent_seen = m->s->bentChanges;
        m->render_thread.evaluating = false;
        behind = std::exchange(m->d->solver.behind, false);
        sounds = heard_told(*m->s);
      }
      snapshot_notify(m);
      const auto videos_from = std::chrono::steady_clock::now();
      const long late_before = video_late;
      m->render_thread.status = "putting the films at the moment";
      breadcrumb("films");
      for (const auto& now : videos) now();
      // No frame yet or seek in flight → redraw next beat.
      const bool again =
          (!m->playback.playing && video_late != late_before) || behind;

      {
        const double ms =
            1e3 * std::chrono::duration<double>(
                      std::chrono::steady_clock::now() - videos_from)
                      .count();
        m->timing.videos_ms += ms;
        m->timing.videos_most = std::max(m->timing.videos_most, ms);
      }
      m->render_thread.status = "putting the sounds at the moment";
      breadcrumb("sounds");
      heard(sounds, m->playback.heard, m->playback.now, m->playback.playing);
      const auto evaluated = std::chrono::steady_clock::now();
      {
        std::lock_guard<std::recursive_timed_mutex> holding(m->d->lock);
        stage_cache_fresh(m->playback.cache, *m->d, *m->s, m->revision.load(),
                          RATE);
      }
      m->render_thread.status = "drawing";
      breadcrumb("draw");
      // During playback, use a cached frame if one exists.
      if (!m->playback.playing || m->d->working_camera.asked ||
          m->window.second ||
          !stage_cache_show(m->playback.cache, *m->s, m->live, m->playback.now,
                            RATE))
        live_camera(m);
      const auto rendered = std::chrono::steady_clock::now();
      lap(5);
      // Every 30 frames, measure GPU time and adjust resolution if needed.
      if (++m->resolution.judged % 30 == 0) {
        std::vector<int64_t> took;
        for (const auto& f : m->s->renderer->getFrameInfoHistory(30))
          if (f.gpuFrameComplete > 0 && f.backendBeginFrame > 0)
            took.push_back(f.gpuFrameComplete - f.backendBeginFrame);
        if (took.size() > 10) {
          std::nth_element(took.begin(), took.begin() + took.size() / 2,
                           took.end());
          const double ms = (double)took[took.size() / 2] / 1e6;
          m->resolution.gpu_ms = ms,
          m->resolution.gpu_most = std::max(m->resolution.gpu_most, ms);
        }
        stage_scale(m);
      }
      m->timing.spent[2] +=
          std::chrono::duration<double>(evaluated - t).count(),
          m->timing.many[2]++;
      m->timing.spent[3] +=
          std::chrono::duration<double>(rendered - evaluated).count(),
          m->timing.many[3]++;
      const auto ms = [](auto a, auto b) {
        return 1e3 * std::chrono::duration<double>(b - a).count();
      };
      m->resolution.frame_ms = ms(round_at, rendered);
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
        std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
        broke_one(m, why);
      }
      // Redraw if a bend changed the outline after this frame's snapshot.
      m->render_thread.changed = again || m->s->bentChanges != bent_seen;
    } catch (const std::exception& e) {
      std::fprintf(stderr, "motolii: the hand's round threw while %s: %s\n",
                   m->render_thread.status.load(), e.what());
      m->error = std::string("the hand's round threw: ") + e.what();
      ++m->timing.rounds_threw;
      m->render_thread.evaluating = false;
      m->render_thread.changed = false;
      m->playback.playing = false;
    } catch (...) {
      std::fprintf(stderr, "motolii: the hand's round threw (unknown) while %s\n",
                   m->render_thread.status.load());
      m->error = "the hand's round threw (unknown)";
      ++m->timing.rounds_threw;
      m->render_thread.evaluating = false;
      m->render_thread.changed = false;
      m->playback.playing = false;
    }
  }
  for (auto& [who, h] : m->playback.heard) heard_off(h);
  if (m->display.beat) m->display.beat->stop();
  if (m->d) doc_close_file(*m->d);
  // Filament's own teardown, on the thread that built the engine (open_stage):
  // Engine::destroy frees whatever the stage still holds, its job threads and
  // GPU memory. Its shutdown destroys leftover materials before their leftover
  // instances (FEngine::shutdown), which a debug build of Filament would stop
  // at; that check is Filament's feature flag, turned off for the teardown.
  if (m->s && m->s->engine) {
    for (interop::Screen* sc : m->s->edge_screens)
      if (sc) interop::drop(m->s->engine, sc);
    if (m->s->place_copy) interop::drop(m->s->engine, m->s->place_copy);
    for (int k = 0; k < 2; ++k)
      if (m->s->place_tone[k]) interop::drop(m->s->engine, m->s->place_tone[k]);
    m->s->engine->setFeatureFlag(
        "engine.debug.assert_destroy_material_before_material_instance", false);
    close_stage(*m->s);
  }
}

}  // namespace motolii

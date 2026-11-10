#include "preview/playback_cache.h"

#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Renderer.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <sqlite3.h>
#include <sys/stat.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <filesystem>
#include <future>
#include <mutex>
#include <string>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

#include "community/quickjs/script.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/live.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

namespace {

// Rebuilds runs from state and signals that the set of cached frames changed.
// Call it whenever a frame is cached, dropped, or all frames are discarded.
void stage_cache_tell(StageCache& k) {
  std::string runs;
  for (int i = 0; i < (int)k.state.size(); ++i) {
    if (k.state[i] != 2 || (i > 0 && k.state[i - 1] == 2)) continue;
    int j = i;
    while (j + 1 < (int)k.state.size() && k.state[j + 1] == 2) ++j;
    runs += (runs.empty() ? "" : " ") + std::to_string(i) + " " +
            std::to_string(j + 1);
  }
  {
    std::lock_guard<std::mutex> hold(k.runsLock);
    k.runs = std::move(runs);
  }
  k.told.fetch_add(1, std::memory_order_release);
}
// Returns a hash of everything that affects how the stage looks: its size, all
// keyframes, the modification time and size of every file the document uses,
// and every easing expression.
uint64_t stage_cache_key(Doc& d, int w, int h) {
  // FNV-1a, as cached frames are named in canvas.h.
  uint64_t hash = 1469598103934665603ull;
  const auto add = [&](const std::string& s) {
    for (unsigned char c : s) hash = (hash ^ c) * 1099511628211ull;
    hash = (hash ^ 0xff) * 1099511628211ull;
  };
  add(std::to_string(w) + "x" + std::to_string(h));
  doc_rows(
      d,
      sqlite3_mprintf("select layer, name, at, value, coalesce(easing, '') "
                      "from keyframe order by layer, name, at"),
      [&](sqlite3_stmt* row) {
        for (int i = 0; i < 5; ++i)
          add(sqlite3_column_text(row, i)
                  ? (const char*)sqlite3_column_text(row, i)
                  : "");
        const char* name = (const char*)sqlite3_column_text(row, 1);
        // Files the document uses, in their current state: an image's file, and
        // the files of effects and scripts.
        if (sqlite3_column_text(row, 3) &&
            (!strcmp(name, "file") || !strcmp(name, "fx") ||
             !strcmp(name, "script")))
          for (const std::string& one :
               !strcmp(name, "file")
                   ? std::vector<std::string>{(const char*)sqlite3_column_text(
                         row, 3)}
                   : script_files((const char*)sqlite3_column_text(row, 3))) {
            struct stat st{};
            if (stat(one.c_str(), &st) == 0)
              add(std::to_string(st.st_mtimespec.tv_sec) + "." +
                  std::to_string(st.st_mtimespec.tv_nsec) + "." +
                  std::to_string(st.st_size));
          }
      });
  doc_rows(
      d,
      sqlite3_mprintf(
          "select name, coalesce(expression, '') from easing order by name"),
      [&](sqlite3_stmt* row) {
        add((const char*)sqlite3_column_text(row, 0));
        add((const char*)sqlite3_column_text(row, 1));
      });
  return hash;
}

// Returns the path of the cache file for a frame of the current document.
std::filesystem::path stage_cache_file(const StageCache& k, int frameIndex) {
  char name[64];
  std::snprintf(name, sizeof name, "stage_%016llx_%05d.zst",
                (unsigned long long)k.key, frameIndex);
  return cache_dir() / name;
}

}  // namespace

void stage_cache_fresh(StageCache& k, Doc& d, Stage& s, long revision,
                       int rate) {
  if (k.revision == revision && k.seen == files_changed() && k.w == s.w &&
      k.h == s.h)
    return;
  k.revision = revision, k.seen = files_changed(), k.w = s.w, k.h = s.h;
  k.key = stage_cache_key(d, s.w, s.h);
  std::erase(k.keys, k.key);
  k.keys.push_back(k.key);
  // Delete the frames of the document as it was three changes ago, on a
  // separate thread.
  if (k.keys.size() > 3) {
    char gone[32];
    std::snprintf(gone, sizeof gone, "stage_%016llx_",
                  (unsigned long long)k.keys.front());
    k.keys.pop_front();
    std::thread([prefix = std::string(gone)] {
      std::error_code e;
      for (const auto& f : std::filesystem::directory_iterator(cache_dir(), e))
        if (f.path().filename().string().rfind(prefix, 0) == 0)
          std::filesystem::remove(f.path(), e);
    }).detach();
  }
  k.state.assign((size_t)std::max(1.0, std::ceil(doc_seconds(d) * rate)) + 1,
                 0);
  // Reset each pointer as it is destroyed. `shown` is created during playback
  // rather than with the target, so a stale pointer would be destroyed twice,
  // and a stale `target` would be drawn into after it was destroyed.
  if (k.target)
    s.engine->destroy(k.target), k.target = nullptr, s.engine->destroy(k.into),
                                 k.into = nullptr;
  if (k.shown) s.engine->destroy(k.shown), k.shown = nullptr;
  // Frames already on disk for this key, from an earlier session or from before
  // an undo.
  for (int i = 0; i < (int)k.state.size(); ++i) {
    std::error_code e;
    if (std::filesystem::exists(stage_cache_file(k, i), e)) k.state[i] = 2;
  }
  stage_cache_tell(k);
}

bool stage_cache_one(StageCache& k, Doc& d, Stage& s, int rate,
                     double budget_ms) {
  // The frames in view are the camera's, which are not drawn from the editing
  // viewpoint.
  if (d.viewCameraAsked) return false;
  double from = 0.0, to = 0.0;
  doc_work(d, &from, &to);
  int at = -1;
  for (int i = (int)std::floor(from * rate);
       i < (int)std::ceil(to * rate) && i < (int)k.state.size(); ++i) {
    if (k.state[i]) continue;
    at = i;
    break;
  }
  if (at < 0) return false;
  if (!k.target) {
    k.into = Texture::Builder()
                 .width(s.w)
                 .height(s.h)
                 .levels(1)
                 .format(Texture::InternalFormat::RGBA8)
                 .usage(Texture::Usage::COLOR_ATTACHMENT |
                        Texture::Usage::SAMPLEABLE | Texture::Usage::BLIT_SRC)
                 .build(*s.engine);
    k.target = RenderTarget::Builder()
                   .texture(RenderTarget::AttachmentPoint::COLOR, k.into)
                   .build(*s.engine);
  }
  const auto t0 = std::chrono::steady_clock::now();
  // The time the app shows. A new layer starts here, as with AbsentMotion's
  // addAudio and addText, whose startTime is frameStart(frame).
  const double playhead = s.now;
  {
    const DocExact exact(d);
    time_is(s, (double)at / rate);
  }
  // The render thread's share of the time, measured as it is during playback.
  const double moment = std::chrono::duration<double, std::milli>(
                            std::chrono::steady_clock::now() - t0)
                            .count();
  RenderTarget* wasOut = s.out;
  Texture* const wasInto = s.drawTarget;
  s.out = k.target;
  if (!s.over) {
    s.drawTarget = k.into;
    s.view->setRenderTarget(k.target);
  }
  auto* pixels = new std::vector<uint8_t>((size_t)s.w * s.h * 4);
  while (!begins(s)) {
  }
  textures_of(s);
  s.renderer->readPixels(
      k.target, 0, 0, (uint32_t)s.w, (uint32_t)s.h,
      backend::PixelBufferDescriptor(pixels->data(), pixels->size(),
                                     backend::PixelDataFormat::RGBA,
                                     backend::PixelDataType::UBYTE));
  s.renderer->endFrame();
  // The render thread is idle, so it may wait for this one frame.
  s.engine->flushAndWait();
  // The GPU's share of the time, from Filament's frame info for its last
  // frames. During playback the two shares run side by side, so either one can
  // make the frame late.
  double gpu = 0.0;
  for (const auto& f : s.renderer->getFrameInfoHistory(2))
    if (f.gpuFrameComplete > 0 && f.backendBeginFrame > 0)
      gpu = std::max(gpu,
                     (double)(f.gpuFrameComplete - f.backendBeginFrame) / 1e6);
  const double took = std::max(moment, gpu);
  if (std::getenv("MOTOLII_KEEP_LOG"))
    std::fprintf(stderr, "CACHED %d moment %.1f gpu %.1f ms\n", at, moment,
                 gpu);
  if (!s.over) {
    s.view->setRenderTarget(nullptr);
  }
  // The layers stay at the cached frame's time. The next frame shown sets its
  // own time first, so videos step forward instead of seeking back.
  s.out = wasOut, s.drawTarget = wasInto;
  // The stage's time goes back to the playhead. Leaving it at the cached
  // frame's time made a song placed with the playhead at 0 start at 4.6 s.
  s.now = playhead;
  if (took > budget_ms) {
    ++cache_unwritten;
    cache_write(stage_cache_file(k, at), std::move(*pixels));
    k.state[at] = 2;
    stage_cache_tell(k);
  } else
    k.state[at] = 1;
  delete pixels;
  return true;
}

bool stage_cache_show(StageCache& k, Stage& s, Live* l, double now, int rate) {
  const int at = (int)std::lround(now * rate);
  if (at < 0 || at >= (int)k.state.size() || k.state[at] != 2) return false;
  const size_t size = (size_t)s.w * s.h * 4;
  const auto read = [size](std::filesystem::path file) {
    auto* p = new std::vector<uint8_t>();
    if (!cache_read(file, *p, size)) delete p, p = nullptr;
    return p;
  };
  std::vector<uint8_t>* pixels = nullptr;
  if (k.next.valid()) {
    std::vector<uint8_t>* got = k.next.get();
    if (k.ahead == at)
      pixels = got;
    else
      delete got;
  }
  // Not read ahead, because playback began here or skipped to here.
  if (!pixels) pixels = read(stage_cache_file(k, at));
  if (at + 1 < (int)k.state.size() && k.state[at + 1] == 2)
    k.ahead = at + 1,
    k.next = std::async(std::launch::async, read, stage_cache_file(k, at + 1));
  if (!pixels) {
    k.state[at] = 0;
    stage_cache_tell(k);
    return false;
  }
  if (!k.shown)
    k.shown =
        Texture::Builder()
            .width(s.w)
            .height(s.h)
            .levels(1)
            .format(Texture::InternalFormat::RGBA8)
            .usage(Texture::Usage::SAMPLEABLE | Texture::Usage::UPLOADABLE)
            .build(*s.engine);
  k.shown->setImage(
      *s.engine, 0,
      backend::PixelBufferDescriptor(
          pixels->data(), pixels->size(), backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE,
          [](void*, size_t, void* user) { delete (std::vector<uint8_t>*)user; },
          pixels));
  live_show(s, l, k.shown);
  return true;
}

}  // namespace motolii

#include "stage/canvas/canvas_cache.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <thorvg.h>
#include <thorvg_lottie.h>
#include <webgpu/webgpu.h>
#include <zstd.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <filesystem>
#include <memory>
#include <mutex>
#include <string>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

#include "gpu/gpu_interop.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Texture;
using filament::TextureSampler;
using filament::math::float3;

std::atomic<int> cache_unwritten{0};
std::atomic<long> films_cached{0}, films_disk{0}, films_rendered{0};

namespace {

// Returns the disk cache file for frame `at`, or an empty path if the frames of
// `d` are not cached on disk.
std::filesystem::path cache_file(const Canvas2D* d, int at) {
  if (d->keyBase.empty() || !d->target) return {};
  std::string all = d->keyBase;
  const auto add = [&](float v) { all += "|" + std::to_string(v); };
  const Canvas2DFx& f = d->fx;
  add((float)wgpuTextureGetWidth(d->target)),
      add((float)wgpuTextureGetHeight(d->target));
  for (float v : {f.blur, (float)f.blurWay, f.shadow.x, f.shadow.y, f.shadow.z,
                  f.shadow.w, f.fall, f.way, f.soft, f.tint, f.tritone,
                  d->fromFrame, d->toFrame})
    add(v);
  for (const float3& c : f.tints) add(c.x), add(c.y), add(c.z);
  for (const float3& c : f.tones) add(c.x), add(c.y), add(c.z);
  for (uint32_t id : d->deep) add((float)id);
  all += "|" + d->slots;
  // FNV-1a, 64 bit.
  uint64_t hash = 1469598103934665603ull;
  for (unsigned char c : all) hash = (hash ^ c) * 1099511628211ull;
  char name[64];
  std::snprintf(name, sizeof name, "%016llx_%05d.zst", (unsigned long long)hash,
                at);
  return cache_dir() / name;
}

// The queue of frames waiting to be compressed and written, with its lock and
// the condition that wakes the writer thread.
std::mutex cache_writing_lock;
std::condition_variable cache_writing_wake;
std::deque<std::pair<std::filesystem::path, std::vector<uint8_t>>>
    cache_writing;
// A pending readback of a cached frame's texture: the buffer, the size, the row
// length in bytes and the file to write to.
struct CacheReadBack {
  WGPUBuffer buffer;
  uint32_t w, h, row;
  std::filesystem::path file;
};
// Records a copy of `texture` into a CPU-readable buffer on `encoder`, to be
// written to `file`. Call cache_map after the encoder is submitted. Counts the
// frame in cache_unwritten.
CacheReadBack* cache_read_back(WGPUDevice device, WGPUCommandEncoder encoder,
                               WGPUTexture texture,
                               std::filesystem::path file) {
  // WebGPU requires rows of a texture copy to be aligned to 256 bytes.
  const uint32_t w = wgpuTextureGetWidth(texture),
                 h = wgpuTextureGetHeight(texture),
                 row = (4 * w + 255) / 256 * 256;
  WGPUBufferDescriptor like{};
  like.size = (uint64_t)row * h;
  like.usage = WGPUBufferUsage_CopyDst | WGPUBufferUsage_MapRead;
  const WGPUBuffer buffer = wgpuDeviceCreateBuffer(device, &like);
  WGPUTexelCopyTextureInfo from{};
  from.texture = texture;
  WGPUTexelCopyBufferInfo to{};
  to.buffer = buffer;
  to.layout.bytesPerRow = row, to.layout.rowsPerImage = h;
  const WGPUExtent3D size{w, h, 1};
  wgpuCommandEncoderCopyTextureToBuffer(encoder, &from, &to, &size);
  ++cache_unwritten;
  return new CacheReadBack{buffer, w, h, row, std::move(file)};
}

// Maps the buffer once the encoder that fills it has been submitted. When the
// GPU finishes, removes the row padding and queues the pixels to be written.
// Frees `job`.
void cache_map(CacheReadBack* job) {
  WGPUBufferMapCallbackInfo done{};
  done.mode = WGPUCallbackMode_AllowSpontaneous;
  done.callback = [](WGPUMapAsyncStatus status, WGPUStringView, void* one,
                     void*) {
    auto* job = (CacheReadBack*)one;
    if (status == WGPUMapAsyncStatus_Success) {
      const auto* at = (const uint8_t*)wgpuBufferGetConstMappedRange(
          job->buffer, 0, (size_t)job->row * job->h);
      std::vector<uint8_t> pixels((size_t)4 * job->w * job->h);
      if (at)
        for (uint32_t y = 0; y < job->h; ++y)
          std::memcpy(pixels.data() + (size_t)4 * job->w * y,
                      at + (size_t)job->row * y, (size_t)4 * job->w);
      wgpuBufferUnmap(job->buffer);
      if (at)
        cache_write(std::move(job->file), std::move(pixels));
      else
        --cache_unwritten;
    } else {
      --cache_unwritten;
    }
    wgpuBufferRelease(job->buffer);
    delete job;
  };
  done.userdata1 = job;
  wgpuBufferMapAsync(job->buffer, WGPUMapMode_Read, 0,
                     (size_t)job->row * job->h, done);
}

// Total bytes of GPU memory used by the cached frames of all animations.
std::atomic<size_t> cache_bytes{0};
// Upper limit for cache_bytes: 2 GB.
constexpr size_t cache_most = size_t(2) << 30;
// Size in bytes of one cached frame of `d`, four bytes a pixel.
size_t cache_one(const Canvas2D* d) {
  return d->target ? 4 * (size_t)wgpuTextureGetWidth(d->target) *
                         wgpuTextureGetHeight(d->target)
                   : 0;
}

// Takes the cached frames that the driver thread made since the last call and
// makes them Filament textures. Main thread.
void cache_take(Stage& s, Canvas2D* d) {
  std::lock_guard<std::mutex> hold(d->keepingLock);
  for (auto& [frame, built] : d->keeping) {
    d->cached[frame] = Texture::Builder()
                           .width(wgpuTextureGetWidth(built))
                           .height(wgpuTextureGetHeight(built))
                           .levels(1)
                           .sampler(Texture::Sampler::SAMPLER_2D)
                           .format(Texture::InternalFormat::RGBA8)
                           .usage(Texture::Usage::SAMPLEABLE)
                           .import((intptr_t)built)
                           .build(*s.engine);
    d->cachedTextures.push_back(built);
  }
  d->keeping.clear();
}

// Uploads a frame read from disk. Driver thread. The frame goes into the
// texture the canvas draws into if `shown`, meaning it is what is displayed
// now, and into a texture of its own if `keep`, which caches it. `age` is the
// keepAge when the work was requested. If it has changed since, the copy is
// released instead of cached.
void cache_put(Stage& s, Canvas2D* d, int at,
               const std::vector<uint8_t>& pixels, bool shown, bool keep,
               int age) {
  const uint32_t w = wgpuTextureGetWidth(d->target),
                 h = wgpuTextureGetHeight(d->target);
  const WGPUDevice device = (WGPUDevice)interop::device(s.engine);
  WGPUTextureDescriptor like{};
  like.size = {w, h, 1};
  like.format = wgpuTextureGetFormat(d->target);
  like.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst |
               WGPUTextureUsage_CopySrc;
  like.dimension = WGPUTextureDimension_2D;
  like.mipLevelCount = 1;
  like.sampleCount = 1;
  const WGPUTexture copy =
      keep ? wgpuDeviceCreateTexture(device, &like) : nullptr;
  WGPUTexelCopyBufferLayout rows{};
  rows.bytesPerRow = 4 * w, rows.rowsPerImage = h;
  for (WGPUTexture t : {shown ? d->target : nullptr, copy}) {
    if (!t) continue;
    WGPUTexelCopyTextureInfo to{};
    to.texture = t;
    wgpuQueueWriteTexture(wgpuDeviceGetQueue(device), &to, pixels.data(),
                          pixels.size(), &rows, &like.size);
  }
  if (shown) d->targetAt = at;
  if (!copy) return;
  std::lock_guard<std::mutex> hold(d->keepingLock);
  if (age == d->keepAge)
    d->keeping.push_back({at, copy});
  else
    wgpuTextureRelease(copy);
}

// Has ThorVG draw frame `at` into the texture the canvas draws into. Driver
// thread. If `keep`, also copies the frame on the GPU to a texture of its own
// that caches it. If `file` does not exist yet, also writes the frame to disk.
// If `paints` is not null, draws the sketch from them instead of the animation.
// `age` is as in cache_put.
void cache_draw(Stage& s, Canvas2D* d, int at, bool keep,
                const std::filesystem::path& file, int age,
                const std::vector<double>* paints = nullptr) {
  if (paints)
    sketch_draw(d, *paints), d->targetAt = at;
  else if (d->film->frame(d->fromFrame + (float)at) == tvg::Result::Success ||
           d->targetAt != at) {
    // The 3D layers have sheets of their own and are not drawn flat here.
    for (uint32_t id : d->deep)
      if (const tvg::Paint* one = d->film->picture()->paint(id))
        const_cast<tvg::Paint*>(one)->visible(false);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
    d->targetAt = at;
  }
  std::error_code e;
  const bool toDisk =
      d->look && !file.empty() && !std::filesystem::exists(file, e);
  if (!keep && !toDisk) return;
  const WGPUDevice device = (WGPUDevice)interop::device(s.engine);
  WGPUCommandEncoder encoder = wgpuDeviceCreateCommandEncoder(device, nullptr);
  WGPUTexture copy = nullptr;
  if (keep) {
    WGPUTextureDescriptor like{};
    like.size = {wgpuTextureGetWidth(d->target),
                 wgpuTextureGetHeight(d->target), 1};
    like.format = wgpuTextureGetFormat(d->target);
    like.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst |
                 WGPUTextureUsage_CopySrc;
    like.dimension = WGPUTextureDimension_2D;
    like.mipLevelCount = 1;
    like.sampleCount = 1;
    copy = wgpuDeviceCreateTexture(device, &like);
    WGPUTexelCopyTextureInfo from{}, to{};
    from.texture = d->target, to.texture = copy;
    wgpuCommandEncoderCopyTextureToTexture(encoder, &from, &to, &like.size);
  }
  CacheReadBack* back =
      toDisk ? cache_read_back(device, encoder, copy ? copy : d->target, file)
             : nullptr;
  WGPUCommandBuffer commands = wgpuCommandEncoderFinish(encoder, nullptr);
  wgpuQueueSubmit(wgpuDeviceGetQueue(device), 1, &commands);
  wgpuCommandBufferRelease(commands);
  wgpuCommandEncoderRelease(encoder);
  if (back) cache_map(back);
  if (!copy) return;
  std::lock_guard<std::mutex> hold(d->keepingLock);
  if (age == d->keepAge) d->keeping.push_back({at, copy});
  // What the layer draws changed while this frame was drawn.
  else
    wgpuTextureRelease(copy);
}

}  // namespace

void effect_on(tvg::Scene* on, char k, const Canvas2DFx& fx, float tall) {
  const auto c = [](float v) { return (int)std::lround(255.f * v); };
  if (k == 't' && fx.tint > 0.f)
    on->add(tvg::SceneEffect::Tint, c(fx.tints[0].x), c(fx.tints[0].y),
            c(fx.tints[0].z), c(fx.tints[1].x), c(fx.tints[1].y),
            c(fx.tints[1].z), (double)(100.f * fx.tint));
  if (k == 'r' && fx.tritone > 0.f)
    on->add(tvg::SceneEffect::Tritone, c(fx.tones[0].x), c(fx.tones[0].y),
            c(fx.tones[0].z), c(fx.tones[1].x), c(fx.tones[1].y),
            c(fx.tones[1].z), c(fx.tones[2].x), c(fx.tones[2].y),
            c(fx.tones[2].z), c(1.f - fx.tritone));
  if (k == 's' && fx.shadow.w > 0.f)
    on->add(tvg::SceneEffect::DropShadow, c(fx.shadow.x), c(fx.shadow.y),
            c(fx.shadow.z), c(fx.shadow.w), (double)fx.way,
            (double)(fx.fall * tall), (double)std::max(fx.soft * tall, 0.01f),
            75);
  // blurWay is the blur direction: both, across, or up and down.
  if (k == 'b' && fx.blur > 0.f)
    on->add(tvg::SceneEffect::GaussianBlur, (double)(fx.blur * tall),
            fx.blurWay, 0, 75);
}

void effects_on(const std::vector<tvg::Scene*>& chain, const Canvas2DFx& fx,
                float tall) {
  tvg::Scene* on = chain[0];
  on->add(tvg::SceneEffect::Clear);
  for (const char* k = fx.order; *k; ++k) effect_on(on, *k, fx, tall);
}

void trim_at(Stage& s, Canvas2D* d, float cut, float begin, float offset) {
  const float3 is{cut, begin, offset};
  if (!d->shape || (is == d->trimmed)) return;
  d->trimmed = is;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, cut, begin, offset] {
    d->shape->trimpath(std::clamp(begin, 0.f, 1.f) + offset,
                       1.f - std::clamp(cut, 0.f, 1.f) + offset);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

void bend_at(Stage& s, Canvas2D* d, float round, float bloat, float zigzag,
             float ridges, float smooth, float offset) {
  const std::array<float, 10> is{round,  bloat, zigzag, ridges, smooth,
                                 offset, 0.f,   0.f,    0.f,    0.f};
  if (!d->shape || d->plain.empty() || is == d->bent) return;
  d->bent = is;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, is] {
    const float high = d->plainHigh, side = d->plainSide;
    tvg_bend(
        d->shape, d->plain.data(), (uint32_t)d->plain.size(), d->plainAt.data(),
        (uint32_t)d->plainAt.size(), std::clamp(is[0], 0.f, 0.5f) * side,
        100.f * std::clamp(is[1], -1.f, 1.f),
        std::clamp(is[2], -4.f, 4.f) * high, (int)std::clamp(is[3], 0.f, 100.f),
        is[4] > 0.5f, std::clamp(is[5], -4.f, 4.f) * high, d->fine);
    // A shape bent to more than 64 times the size of its image is not drawn.
    // None of it would be visible, and ThorVG can crash while measuring,
    // dashing and staging a path that large.
    float x = 0.f, y = 0.f, w = 0.f, h = 0.f;
    if (d->shape->bounds(&x, &y, &w, &h) == tvg::Result::Success &&
        !(std::max(w, h) < 64.f * std::max(1.f, d->canvasHigh)))
      d->shape->reset();
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

void slots_at(Stage& s, Canvas2D* d, const std::string& slots) {
  if (!d->lottie || slots == d->slots) return;
  d->slots = slots;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, slots] {
    if (d->slotsId) d->lottie->del(d->slotsId), d->slotsId = 0;
    if (!slots.empty() && (d->slotsId = d->lottie->gen(slots.c_str())))
      d->lottie->apply(d->slotsId);
    // Draw the current frame again.
    d->targetAt = -1;
  });
}

void lit_at(Stage& s, Canvas2D* d, const std::vector<float>& lit,
            const std::vector<tvg::Matrix>& moves, float3 colour) {
  if (!d->film || (lit == d->lit && moves.size() == d->moves.size() &&
                   std::equal(moves.begin(), moves.end(), d->moves.begin(),
                              [](const tvg::Matrix& a, const tvg::Matrix& b) {
                                return !std::memcmp(&a, &b, sizeof a);
                              })))
    return;
  d->lit = lit, d->moves = moves;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, lit, moves, colour] {
    for (size_t i = 0; i < lit.size(); ++i)
      if (auto* note = const_cast<tvg::Paint*>(d->film->picture()->paint(
              tvg::Accessor::id(("note" + std::to_string(i)).c_str())));
          note && note->type() == tvg::Type::Shape) {
        const float3 c = min(colour + 0.3f * lit[i], float3{1.f});
        static_cast<tvg::Shape*>(note)->fill((uint8_t)std::lround(c.x * 255.f),
                                             (uint8_t)std::lround(c.y * 255.f),
                                             (uint8_t)std::lround(c.z * 255.f));
        if (i < moves.size()) note->transform(moves[i]);
      }
    // ThorVG redraws a picture only if the picture itself is marked changed,
    // not its parts (see update in tvgPicture.h). Paint::opacity marks it.
    d->film->picture()->opacity(254), d->film->picture()->opacity(255);
    // Draws now even if the picture does not move, as fx_at does.
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

bool words_at(Stage& s, Canvas2D* d, const std::string& words) {
  if (!d->text || d->outgrown) return false;
  if (words == d->words) return true;
  // The font lacks a letter. The text is made again with the fallback font.
  if (!type_lacks(d->textFont, words).empty()) return false;
  d->words = words;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, words] {
    d->text->translate(0.f, 0.f);
    d->text->text(words.c_str());
    float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
    if (d->text->bounds(&x, &y, &wide, &tall) != tvg::Result::Success) return;
    d->outgrown = wide > d->textWide + 0.5f;
    d->text->translate(0.5f * (d->textWide - wide) - x, d->textAt);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
  return true;
}

void fx_at(Stage& s, Canvas2D* d, const Canvas2DFx& told) {
  if (d->effects.empty()) return;
  const Canvas2DFx fx = told.over(d->fx.overHigh);
  const Canvas2DFx& was = d->fx;
  if (fx.blur == was.blur && fx.blurWay == was.blurWay &&
      (fx.shadow == was.shadow) && fx.fall == was.fall && fx.way == was.way &&
      fx.soft == was.soft && fx.tint == was.tint && fx.tritone == was.tritone &&
      !strcmp(fx.order, was.order) && (fx.tints[0] == was.tints[0]) &&
      (fx.tints[1] == was.tints[1]) && (fx.tones[0] == was.tones[0]) &&
      (fx.tones[1] == was.tones[1]) && (fx.tones[2] == was.tones[2]))
    return;
  d->fx = fx;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, fx] {
    effects_on(d->effects, fx, d->tall);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

const std::filesystem::path& cache_dir() {
  static const std::filesystem::path dir = [] {
    const char* home = std::getenv("HOME");
    const std::filesystem::path p =
        std::filesystem::path(home ? home : "/tmp") /
        "Library/Caches/Motolii/frames";
    std::error_code e;
    std::filesystem::create_directories(p, e);
    std::thread([p] {
      std::vector<
          std::pair<std::filesystem::file_time_type, std::filesystem::path>>
          files;
      uintmax_t total = 0;
      std::error_code e;
      for (const auto& f : std::filesystem::directory_iterator(p, e))
        if (f.is_regular_file(e))
          files.push_back({f.last_write_time(e), f.path()}),
              total += f.file_size(e);
      std::sort(files.begin(), files.end());
      for (const auto& [when, f] : files) {
        if (total <= (uintmax_t(20) << 30)) break;
        total -= std::filesystem::file_size(f, e);
        std::filesystem::remove(f, e);
      }
    }).detach();
    return p;
  }();
  return dir;
}

void cache_write(std::filesystem::path file, std::vector<uint8_t> pixels) {
  static std::once_flag started;
  std::call_once(started, [] {
    std::thread([] {
      for (;;) {
        std::unique_lock<std::mutex> hold(cache_writing_lock);
        cache_writing_wake.wait(hold, [] { return !cache_writing.empty(); });
        auto job = std::move(cache_writing.front());
        cache_writing.pop_front();
        hold.unlock();
        std::vector<uint8_t> packed(ZSTD_compressBound(job.second.size()));
        const size_t n = ZSTD_compress(packed.data(), packed.size(),
                                       job.second.data(), job.second.size(), 1);
        if (ZSTD_isError(n)) {
          --cache_unwritten;
          continue;
        }
        std::filesystem::path part = job.first;
        part += ".part";
        if (FILE* f = std::fopen(part.c_str(), "wb")) {
          const bool whole = std::fwrite(packed.data(), 1, n, f) == n;
          std::fclose(f);
          std::error_code e;
          if (whole)
            std::filesystem::rename(part, job.first, e);
          else
            std::filesystem::remove(part, e);
        }
        --cache_unwritten;
      }
    }).detach();
    // At exit, waits for the queued frames to be written, for at most ten
    // seconds.
    std::atexit([] {
      for (int i = 0; i < 1000 && cache_unwritten > 0; ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    });
  });
  {
    std::lock_guard<std::mutex> hold(cache_writing_lock);
    cache_writing.push_back({std::move(file), std::move(pixels)});
  }
  cache_writing_wake.notify_one();
}

bool cache_read(const std::filesystem::path& file, std::vector<uint8_t>& pixels,
                size_t size) {
  FILE* f = file.empty() ? nullptr : std::fopen(file.c_str(), "rb");
  if (!f) return false;
  std::fseek(f, 0, SEEK_END);
  std::vector<uint8_t> packed((size_t)std::max(0L, std::ftell(f)));
  std::fseek(f, 0, SEEK_SET);
  const bool whole =
      std::fread(packed.data(), 1, packed.size(), f) == packed.size();
  std::fclose(f);
  pixels.resize(size);
  const size_t n =
      whole ? ZSTD_decompress(pixels.data(), size, packed.data(), packed.size())
            : 0;
  return whole && !ZSTD_isError(n) && n == size;
}

void cache_drop(Stage& s, Canvas2D* d) {
  {
    std::lock_guard<std::mutex> hold(d->keepingLock);
    for (auto& [at, built] : d->keeping)
      d->cached[at] = nullptr, wgpuTextureRelease(built);
    d->keeping.clear();
  }
  const size_t one = d->target ? 4 * (size_t)wgpuTextureGetWidth(d->target) *
                                     wgpuTextureGetHeight(d->target)
                               : 0;
  for (auto& [at, texture] : d->cached) {
    if (texture) s.engine->destroy(texture);
    cache_bytes -= one;
  }
  d->cached.clear();
  d->ahead.clear();
  // Released on the driver thread, after Filament has taken and released them.
  interop::on_driver(s.engine, [built = std::move(d->cachedTextures)] {
    for (WGPUTexture t : built) wgpuTextureRelease(t);
  });
  d->cachedTextures.clear();
  d->shownAt = -1;
  ++d->keepAge;
  if (d->look)
    d->look->setParameter("picture", d->texture,
                          TextureSampler(TextureSampler::MinFilter::LINEAR,
                                         TextureSampler::MagFilter::LINEAR));
}

void canvas_at(Stage& s, Canvas2D* d, float seconds) {
  const int at = (int)std::floor(
      std::min(seconds / d->seconds * d->frames, d->frames - 1.f) + 1e-3f);
  if (at == d->shownAt) return;
  d->shownAt = at;
  const TextureSampler smooth(TextureSampler::MinFilter::LINEAR,
                              TextureSampler::MagFilter::LINEAR);
  cache_take(s, d);
  // Cached on the GPU: show it.
  if (const auto k = d->cached.find(at); k != d->cached.end() && k->second) {
    if (d->look) d->look->setParameter("picture", k->second, smooth);
    ++films_cached;
    return;
  }
  if (d->look) d->look->setParameter("picture", d->texture, smooth);
  const bool keep = d->look && d->cached.find(at) == d->cached.end() &&
                    cache_bytes < cache_most;
  // Reserves the entry so the frame is cached only once. It is filled when the
  // driver thread is done.
  if (keep) d->cached[at] = nullptr, cache_bytes += cache_one(d);
  const std::filesystem::path file = cache_file(d, at);
  auto pixels = std::make_shared<std::vector<uint8_t>>();
  // Cached on disk: upload it as it is instead of drawing it.
  if (d->look && cache_read(file, *pixels, cache_one(d)))
    ++films_disk, interop::on_driver(s.engine, [&s, d, at, pixels, keep,
                                                age = d->keepAge.load()] {
      cache_put(s, d, at, *pixels, true, keep, age);
    });
  else {
    std::shared_ptr<std::vector<double>> paints;
    if (d->sketch)
      paints =
          std::make_shared<std::vector<double>>(d->sketch(at, d->sketchAt)),
      d->sketchAt = at;
    ++films_rendered,
        interop::on_driver(
            s.engine, [&s, d, at, keep, file, paints, age = d->keepAge.load()] {
              cache_draw(s, d, at, keep, file, age, paints.get());
            });
  }
}

int frames_ahead(Stage& s, Canvas2D* d, int many) {
  if (!d->look || !d->film || d->frames <= 1.f || d->shownAt < 0 || !d->target)
    return 0;
  cache_take(s, d);
  const auto now = d->cached.find(d->shownAt);
  // The frame shown does not yet come from the cache, so the texture the canvas
  // draws into is in use.
  if (now == d->cached.end() || !now->second) return 0;
  d->look->setParameter("picture", now->second,
                        TextureSampler(TextureSampler::MinFilter::LINEAR,
                                       TextureSampler::MagFilter::LINEAR));
  const int frames = (int)d->frames;
  int begun = 0;
  std::error_code e;
  for (int i = 1; i < frames && begun < many; ++i) {
    const int at = (d->shownAt + i) % frames;
    if (d->cached.count(at) || d->ahead.count(at)) continue;
    const std::filesystem::path file = cache_file(d, at);
    const bool keep = cache_bytes + cache_one(d) <= cache_most;
    const bool onDisk = !file.empty() && std::filesystem::exists(file, e);
    // There is no room on the GPU and the frame is on disk already, so there is
    // nothing to do.
    if (!keep && (onDisk || file.empty())) continue;
    if (keep) d->cached[at] = nullptr, cache_bytes += cache_one(d);
    // Only onto disk. Not asked again while it is written.
    else
      d->ahead.insert(at);
    auto pixels = std::make_shared<std::vector<uint8_t>>();
    if (onDisk && cache_read(file, *pixels, cache_one(d)))
      interop::on_driver(s.engine,
                         [&s, d, at, pixels, age = d->keepAge.load()] {
                           cache_put(s, d, at, *pixels, false, true, age);
                         });
    else
      interop::on_driver(s.engine,
                         [&s, d, at, keep, file, age = d->keepAge.load()] {
                           cache_draw(s, d, at, keep, file, age);
                         });
    ++begun;
  }
  return begun;
}

}  // namespace motolii

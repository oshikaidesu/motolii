// Stage-wide shared compiled shaders and transient GPU render-target pool.
#include "stage/effects/screen_pool.h"

#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <webgpu/webgpu.h>

#include <algorithm>
#include <cstdio>

#include "gpu/gpu_interop.h"
#include "gpu/screen_interop.h"
#include "shelf/shelf_folders.h"

namespace motolii {

using filament::RenderTarget;
using filament::Texture;

namespace {

uint64_t size_key(uint32_t w, uint32_t h) {
  return (uint64_t(w) << 32) | uint64_t(h);
}

void destroy_layer_slot(Stage& s, PooledLayerSlot& slot) {
  if (slot.depthTarget) s.engine->destroy(slot.depthTarget);
  if (slot.colorTarget) s.engine->destroy(slot.colorTarget);
  if (slot.tex) s.engine->destroy(slot.tex);
  if (slot.device) {
    void* dev = slot.device;
    interop::on_driver(s.engine,
                       [dev] { wgpuTextureRelease((WGPUTexture)dev); });
  }
  slot = PooledLayerSlot{};
}

void destroy_target(Stage& s, PooledTarget& t) {
  if (t.rt) s.engine->destroy(t.rt);
  if (t.tex) s.engine->destroy(t.tex);
  t = PooledTarget{};
}

void invalidate_fused_for(Stage& s, StageFxCache& cache,
                          const std::string& file) {
  for (auto it = cache.fused.begin(); it != cache.fused.end();) {
    const auto& files = it->second.files;
    if (std::find(files.begin(), files.end(), file) != files.end()) {
      if (it->second.interop) interop::drop(s.engine, it->second.interop);
      it = cache.fused.erase(it);
    } else {
      ++it;
    }
  }
}

void compile_shared(Stage& s, SharedScreen& sh) {
  ScreenFx next;
  next.file = sh.file;
  std::string code;
  if (!screen_read(next, code)) {
    std::fprintf(stderr, "%s\n", next.trouble.c_str());
    sh.proto = std::move(next);
    return;
  }
  interop::Screen* built =
      interop::screen(s.engine, sh.file.c_str(), code.c_str(), next.bytes,
                      &next.trouble, next.textureCount, next.layered);
  if (!built) {
    std::fprintf(stderr, "the effect %s is not taken: %s\n", sh.file.c_str(),
                 next.trouble.c_str());
    if (!sh.interop) sh.proto = std::move(next);
    return;
  }
  if (sh.interop) interop::drop(s.engine, sh.interop);
  sh.interop = built;
  next.wgsl = std::move(code);
  screen_analyze_pointwise(next, next.wgsl);
  sh.proto = std::move(next);
}

}  // namespace

StageFxCache& screen_cache(Stage& s) {
  if (!s.fxCache) {
    s.fxCache = new StageFxCache;
    s.fxCacheDrop = screen_cache_off;
  }
  return *s.fxCache;
}

void screen_cache_off(Stage& s) {
  if (!s.fxCache) return;
  StageFxCache* cache = s.fxCache;
  s.fxCache = nullptr;
  if (s.engine) {
    for (auto& [k, sh] : cache->compiled)
      if (sh.interop) interop::drop(s.engine, sh.interop), sh.interop = nullptr;
    for (auto& [k, f] : cache->fused)
      if (f.interop) interop::drop(s.engine, f.interop), f.interop = nullptr;
    for (PooledLayerSlot& slot : cache->layerSlots) destroy_layer_slot(s, slot);
    for (PooledTarget& t : cache->targets) destroy_target(s, t);
    for (auto& [k, d] : cache->depths)
      if (d) s.engine->destroy(d);
  }
  delete cache;
}

void screen_frame_begin(Stage& s) {
  StageFxCache& cache = screen_cache(s);
  if (cache.lastFrame == s.frameCount && s.frameCount != 0) return;
  cache.lastFrame = s.frameCount;
  // Evict pooled textures that have not been touched for 180 frames (e.g. after
  // resizing the stage panel).
  if (s.frameCount > 180 && (s.frameCount % 60) == 0) {
    const uint64_t cutoff = s.frameCount - 180;
    for (auto it = cache.layerSlots.begin(); it != cache.layerSlots.end();) {
      if (!it->inUse && it->lastUsedFrame < cutoff) {
        destroy_layer_slot(s, *it);
        it = cache.layerSlots.erase(it);
      } else {
        ++it;
      }
    }
    for (auto it = cache.targets.begin(); it != cache.targets.end();) {
      if (!it->inUse && it->lastUsedFrame < cutoff) {
        destroy_target(s, *it);
        it = cache.targets.erase(it);
      } else {
        ++it;
      }
    }
  }
}

SharedScreen& screen_shared(Stage& s, const std::string& file) {
  StageFxCache& cache = screen_cache(s);
  auto it = cache.compiled.find(file);
  if (it == cache.compiled.end()) {
    SharedScreen& sh = cache.compiled[file];
    sh.file = file;
    sh.seen = files_changed();
    sh.stamp = screen_stamp(file);
    compile_shared(s, sh);
    return sh;
  }
  SharedScreen& sh = it->second;
  if (sh.seen != files_changed()) {
    sh.seen = files_changed();
    const auto stamp = screen_stamp(file);
    if (stamp != sh.stamp) {
      sh.stamp = stamp;
      compile_shared(s, sh);
      invalidate_fused_for(s, cache, file);
    }
  }
  return sh;
}

interop::Screen* screen_shared_copy(Stage& s) {
  if (!s.place_copy) {
    static const char* const same =
        "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) "
        "@binding(1) var near: sampler;\n"
        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: "
        "vec2f) -> @location(0) vec4f { return textureSampleLevel(source, "
        "near, uv, 0.0); }\n";
    s.place_copy = interop::screen(s.engine, "place", same, 0);
  }
  return s.place_copy;
}

Texture* screen_pool_depth(Stage& s, uint32_t w, uint32_t h) {
  StageFxCache& cache = screen_cache(s);
  Texture*& depth = cache.depths[size_key(w, h)];
  if (!depth) {
    depth = Texture::Builder()
                .width(w)
                .height(h)
                .levels(1)
                .usage(Texture::Usage::DEPTH_ATTACHMENT)
                .format(Texture::InternalFormat::DEPTH24)
                .build(*s.engine);
  }
  return depth;
}

PooledLayerSlot* screen_pool_acquire_layer(Stage& s, uint32_t w, uint32_t h,
                                           bool withDepth) {
  StageFxCache& cache = screen_cache(s);
  for (PooledLayerSlot& slot : cache.layerSlots) {
    if (!slot.inUse && slot.w == w && slot.h == h) {
      if (withDepth && !slot.depthTarget) {
        slot.depthTarget =
            RenderTarget::Builder()
                .texture(RenderTarget::AttachmentPoint::COLOR, slot.tex)
                .texture(RenderTarget::AttachmentPoint::DEPTH,
                         screen_pool_depth(s, w, h))
                .build(*s.engine);
        slot.withDepth = true;
      }
      slot.inUse = true;
      slot.lastUsedFrame = s.frameCount;
      return &slot;
    }
  }
  WGPUTextureDescriptor like{};
  like.size = {w, h, 1};
  like.format = WGPUTextureFormat_BGRA8Unorm;
  like.usage = WGPUTextureUsage_RenderAttachment |
               WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc |
               WGPUTextureUsage_CopyDst;
  like.dimension = WGPUTextureDimension_2D;
  like.mipLevelCount = 1, like.sampleCount = 1;
  like.label = {"fx pooled layer", WGPU_STRLEN};
  void* dev =
      wgpuDeviceCreateTexture((WGPUDevice)interop::device(s.engine), &like);
  Texture* tex =
      Texture::Builder()
          .width(w)
          .height(h)
          .levels(1)
          .format(Texture::InternalFormat::RGBA8)
          .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE |
                 Texture::Usage::BLIT_SRC)
          .import((intptr_t)dev)
          .build(*s.engine);
  PooledLayerSlot slot;
  slot.w = w, slot.h = h, slot.withDepth = withDepth, slot.inUse = true;
  slot.lastUsedFrame = s.frameCount;
  slot.device = dev;
  slot.tex = tex;
  slot.colorTarget = RenderTarget::Builder()
                         .texture(RenderTarget::AttachmentPoint::COLOR, tex)
                         .build(*s.engine);
  if (withDepth) {
    slot.depthTarget = RenderTarget::Builder()
                           .texture(RenderTarget::AttachmentPoint::COLOR, tex)
                           .texture(RenderTarget::AttachmentPoint::DEPTH,
                                    screen_pool_depth(s, w, h))
                           .build(*s.engine);
  }
  cache.layerSlots.push_back(slot);
  return &cache.layerSlots.back();
}

void screen_pool_release_layer(Stage&, PooledLayerSlot* slot) {
  if (slot) slot->inUse = false;
}

PooledTarget* screen_pool_acquire_target(Stage& s, uint32_t w, uint32_t h,
                                         bool fine) {
  StageFxCache& cache = screen_cache(s);
  for (PooledTarget& t : cache.targets) {
    if (!t.inUse && t.w == w && t.h == h && t.fine == fine) {
      t.inUse = true;
      t.lastUsedFrame = s.frameCount;
      return &t;
    }
  }
  PooledTarget t;
  t.w = w, t.h = h, t.fine = fine, t.inUse = true;
  t.lastUsedFrame = s.frameCount;
  t.tex =
      Texture::Builder()
          .width(w)
          .height(h)
          .levels(1)
          .format(fine ? Texture::InternalFormat::RGBA16F
                       : Texture::InternalFormat::RGBA8)
          .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
          .build(*s.engine);
  t.rt = RenderTarget::Builder()
             .texture(RenderTarget::AttachmentPoint::COLOR, t.tex)
             .build(*s.engine);
  cache.targets.push_back(t);
  return &cache.targets.back();
}

void screen_pool_release_target(Stage&, PooledTarget* t) {
  if (t) t->inUse = false;
}

}  // namespace motolii

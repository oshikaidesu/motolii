#ifndef MOTOLII_STAGE_EFFECTS_SCREEN_POOL_H_
#define MOTOLII_STAGE_EFFECTS_SCREEN_POOL_H_
// Stage-wide shared GPU nodes for effects: compiled WGSL/ISF shader cache,
// automatically fused pointwise shader cache, transient RenderTarget / Texture
// pool, and shared AudioLink bus. 詳細: docs/design/effect_pipeline.md
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <cstdint>
#include <deque>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

// A single compiled shader program shared by all layers and stacked instances
// that reference the same effect file.
struct SharedScreen {
  std::string file;
  std::filesystem::file_time_type stamp{};
  int seen = -1;
  uint64_t slotFrame = 0;
  uint32_t nextSlot = 0;
  interop::Screen* interop = nullptr;
  ScreenFx proto;
};

// A compiled single-pass WGSL shader fusing a contiguous run of pointwise
// effects (and optionally the leading linear->sRGB / trailing sRGB->linear
// conversions).
struct FusedScreen {
  interop::Screen* interop = nullptr;
  bool failed = false;
  uint64_t slotFrame = 0;
  uint32_t nextSlot = 0;
  std::vector<uint32_t> offsets;
  uint32_t totalBytes = 0;
  std::vector<std::string> files;
  std::vector<std::filesystem::file_time_type> stamps;
};

// A transient BGRA8 + WGPUTexture slot for layer shot / ping-pong scratch.
struct PooledLayerSlot {
  uint32_t w = 0, h = 0;
  bool withDepth = false;
  bool inUse = false;
  uint64_t lastUsedFrame = 0;
  void* device = nullptr;
  filament::Texture* tex = nullptr;
  filament::RenderTarget* colorTarget = nullptr;
  filament::RenderTarget* depthTarget = nullptr;
};

// A transient RGBA8 or RGBA16F slot for non-persistent ISF intermediate passes.
struct PooledTarget {
  uint32_t w = 0, h = 0;
  bool fine = false;
  bool inUse = false;
  uint64_t lastUsedFrame = 0;
  filament::Texture* tex = nullptr;
  filament::RenderTarget* rt = nullptr;
};

// Stage-shared 1D sound texture (deduplicates identical FFT/wave uploads per
// frame across all layers reading the same audio source).
struct SharedSoundTex {
  uint64_t frame = 0;
  uint32_t w = 0;
  filament::Texture* tex = nullptr;
};

// VRChat AudioLink-style stage-wide 128x8 R16F audio bus texture shared by all
// audio-reactive shaders (updated at most once per frame):
//   Row 0..3: Bass / Low-Mid / High-Mid / Treble history (col 0 = now, right =
//   past) Row 4:    128-bin live FFT spectrum (0..1) Row 5:    128-sample live
//   waveform (0..1, centered at 0.5) Row 6:    Overall RMS energy history Row
//   7:    Beat / onset pulse history (transient detector)
struct SharedAudioLink {
  static constexpr uint32_t kCols = 128, kRows = 8;
  uint64_t frame = 0;
  double lastNow = -1e9;
  float smooth[4] = {0, 0, 0, 0};
  float prevEnergy = 0.f;
  float grid[kRows * kCols] = {};
  filament::Texture* tex = nullptr;
};

struct StageFxCache {
  uint64_t lastFrame = 0;
  std::map<std::string, SharedScreen> compiled;
  std::map<std::string, FusedScreen> fused;
  // Shared DEPTH24 textures keyed by (w << 32) | h.
  std::map<uint64_t, filament::Texture*> depths;
  // Deques preserve pointer stability across push_back while slots are lent.
  std::deque<PooledLayerSlot> layerSlots;
  std::deque<PooledTarget> targets;
  std::map<std::string, SharedSoundTex> sounds;
  SharedAudioLink audioLink;
  // Stage-shared flat 2D Canvas2D blit shaders ([0] = sRGB out, [1] = linear
  // out) for bypassing Filament's 3D View render on simple flat layers.
  interop::Screen* flatBlit[2] = {nullptr, nullptr};
  uint64_t flatBlitFrame[2] = {0, 0};
  uint32_t flatBlitSlot[2] = {0, 0};
};

// Returns (creating on first use) the Stage's shared GPU effect cache.
StageFxCache& screen_cache(Stage& s);
// Releases every GPU shader, fused program, and pooled texture on `s`.
void screen_cache_off(Stage& s);
// Marks frame start for `interop::new_frame` and trims stale pooled textures.
void screen_frame_begin(Stage& s);

// Returns the Stage-wide compiled shader for `file`, compiling once on first
// use and hot-reloading automatically when the file's mtime changes.
SharedScreen& screen_shared(Stage& s, const std::string& file);
// Returns the Stage-wide copy shader (`s.place_copy`), creating once on first
// use instead of per-layer.
interop::Screen* screen_shared_copy(Stage& s);

// Borrows a shared DEPTH24 texture of size `w` x `h`. Owned by StageFxCache.
filament::Texture* screen_pool_depth(Stage& s, uint32_t w, uint32_t h);
// Borrows a transient BGRA8/WGPUTexture layer slot. Return with
// `screen_pool_release_layer`.
PooledLayerSlot* screen_pool_acquire_layer(Stage& s, uint32_t w, uint32_t h,
                                           bool withDepth);
void screen_pool_release_layer(Stage& s, PooledLayerSlot* slot);

// Borrows a transient ISF pass target (RGBA8 or RGBA16F). Return with
// `screen_pool_release_target`.
PooledTarget* screen_pool_acquire_target(Stage& s, uint32_t w, uint32_t h,
                                         bool fine);
void screen_pool_release_target(Stage& s, PooledTarget* t);

// Returns the Stage-wide 128x8 AudioLink bus texture, updating it at most once
// per frame from `fft` (128 bins) and `wave` (128 samples).
filament::Texture* screen_pool_audiolink(
    Stage& s,
    const std::function<std::vector<float>(bool fft, int wide)>& read);
// Returns a Stage-shared 1D R16F sound texture updated at most once per frame
// for `key`.
filament::Texture* screen_pool_sound(
    Stage& s, const std::string& key, bool fft, int wide,
    const std::function<std::vector<float>()>& read);

// Analyzes normalized WGSL produced by `screen_read` and sets `fx.pointwise`
// and its fusion metadata when the shader strictly samples only its own pixel.
void screen_analyze_pointwise(ScreenFx& fx, const std::string& wgsl);

// Blits a straight-sRGB flat Canvas2D texture directly into `to` at normalized
// rectangle `rect` = {u0, v0, 1/uw, 1/vh} with optional linear `wash`,
// bypassing Filament's 3D Renderer::render(v). Outputs premultiplied sRGB when
// `toLinear` is false, or premultiplied linear when `toLinear` is true.
void screen_blit_flat(Stage& s, filament::Texture* from,
                      filament::RenderTarget* to, uint32_t w, uint32_t h,
                      const float rect[4], const float wash[4], bool toLinear);

// Draws a contiguous run of pointwise effects (optionally folding linear->sRGB
// or a direct flat-2D Canvas2D blit at entry, and sRGB->linear at exit) in a
// single GPU pass. Returns false if the fused shader could not be compiled.
bool screen_draw_fused(Stage& s, ScreenStack& st, ScreenFx* const* nodes,
                       size_t count, bool foldToSrgb, bool foldToLinear,
                       filament::Texture* from, filament::RenderTarget* to,
                       const ScreenNumbers& numbers, uint32_t w, uint32_t h,
                       bool over = false, const float* flatRect = nullptr,
                       const float* flatWash = nullptr);

}  // namespace motolii

#endif  // MOTOLII_STAGE_EFFECTS_SCREEN_POOL_H_

// Drawing an effect: its passes run one over another, the stack of effects of a
// stage or layer, and the rebuild when the effect file is written over.

#include "stage/effects/screen_fx.h"

#include <backend/DriverEnums.h>
#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <math/half.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <functional>
#include <map>
#include <string>
#include <system_error>
#include <vector>

#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "gpu/screen_interop.h"
#include "shelf/shelf_folders.h"
#include "stage/effects/screen_pool.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Engine;
using filament::RenderTarget;
using filament::Texture;
namespace backend = filament::backend;
namespace math = filament::math;

Texture* screen_texture(Stage& s) {
  return Texture::Builder()
      .width((uint32_t)s.w)
      .height((uint32_t)s.h)
      .levels(1)
      .format(Texture::InternalFormat::RGBA8)
      .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
      .build(*s.engine);
}

namespace {
// Reuses the Stage's single copy shader instead of compiling one per layer.
interop::Screen* screen_copy(Stage& s, ScreenStack&) {
  return screen_shared_copy(s);
}
}  // namespace

void screen_place(Stage& s, Texture* from, RenderTarget* to, uint32_t w,
                  uint32_t h, const int* at) {
  interop::Screen* copy = screen_shared_copy(s);
  if (copy) interop::draw(s.engine, copy, from, to, w, h, at);
}

void screen_tone(Stage& s, Texture* from, RenderTarget* to, uint32_t w,
                 uint32_t h, bool toSrgb) {
  interop::Screen*& one = s.place_tone[toSrgb ? 1 : 0];
  if (!one) {
    const std::string code =
        std::string(
            "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) "
            "@binding(1) var near: sampler;\n") +
        (toSrgb
             ? "fn tone(c: vec3f) -> vec3f { return select(1.055 * pow(c, "
               "vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); "
               "}\n"
             : "fn tone(c: vec3f) -> vec3f { return select(pow((c + 0.055) / "
               "1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }\n") +
        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: "
        "vec2f) -> @location(0) vec4f {\n"
        "  let p = textureSampleLevel(source, near, uv, 0.0);\n  if (p.a <= "
        "0.0) { return vec4f(0.0); }\n"
        "  return vec4f(tone(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * "
        "p.a, p.a);\n}\n";
    one = interop::screen(s.engine, toSrgb ? "to sRGB" : "to linear",
                          code.c_str(), 0);
  }
  if (one) interop::draw(s.engine, one, from, to, w, h, nullptr);
}

void screen_draw(Stage& s, ScreenStack& st, ScreenFx& fx, Texture* from,
                 RenderTarget* to, const ScreenNumbers& numbers, uint32_t w,
                 uint32_t h, bool over) {
  screen_frame_begin(s);
  if (!w) w = (uint32_t)s.w, h = (uint32_t)s.h;
  std::copy(fx.source ? st.own : st.frame, (fx.source ? st.own : st.frame) + 4,
            fx.frame);
  const auto passing = [&](int t) {
    for (int i = 0; i < 2; ++i) {
      const bool set = t >= 0 && fx.targets[(size_t)t].points[i];
      fx.pass[i] = set ? 0.0 : fx.frame[i],
      fx.pass[2 + i] = set ? 1.0 : fx.frame[2 + i];
    }
  };
  screen_targets(s, fx, false, w, h);
  // Write this frame into the next layer of the history before it is read.
  if (fx.historyFrames) {
    // The size of the image it keeps.
    const uint32_t hw =
                       (uint32_t)std::max(2L, std::lround(w * fx.historyShare)),
                   hh =
                       (uint32_t)std::max(2L, std::lround(h * fx.historyShare));
    // The image has a new size: the history starts again.
    if (fx.history && (fx.hw != hw || fx.hh != hh)) {
      for (RenderTarget* r : fx.historyInto) s.engine->destroy(r);
      fx.historyInto.clear();
      s.engine->destroy(fx.history), fx.history = nullptr;
    }
    if (!fx.history) {
      fx.hw = hw, fx.hh = hh;
      fx.history = Texture::Builder()
                       .width(fx.hw)
                       .height(fx.hh)
                       .depth((uint32_t)fx.historyFrames)
                       .levels(1)
                       .sampler(Texture::Sampler::SAMPLER_2D_ARRAY)
                       .format(Texture::InternalFormat::RGBA8)
                       .usage(Texture::Usage::COLOR_ATTACHMENT |
                              Texture::Usage::SAMPLEABLE)
                       .build(*s.engine);
      for (int k = 0; k < fx.historyFrames; ++k)
        fx.historyInto.push_back(
            RenderTarget::Builder()
                .texture(RenderTarget::AttachmentPoint::COLOR, fx.history)
                .layer(RenderTarget::AttachmentPoint::COLOR, (uint32_t)k)
                .build(*s.engine));
    }
    fx.head = (fx.head + 1) % fx.historyFrames;
    interop::draw(s.engine, screen_copy(s, st), from,
                  fx.historyInto[(size_t)fx.head], fx.hw, fx.hh);
  }
  screen_sounds(s, st, fx);
  // Transient pooled targets borrowed for non-persistent ISF passes; released
  // immediately when this effect finishes so subsequent effects/layers reuse
  // the same hot GPU memory.
  std::vector<PooledTarget*> pooled(fx.targets.size(), nullptr);
  const auto releaseAll = [&] {
    for (PooledTarget*& pt : pooled) {
      if (pt) screen_pool_release_target(s, pt), pt = nullptr;
    }
  };
  std::vector<Texture*> read((size_t)fx.textureCount, from);
  const auto gather = [&] {
    size_t target = 0;
    const size_t own = read.size() - fx.others.size();
    for (size_t k = 1; k < own; ++k) {
      if ((fx.layered >> k) & 1u) {
        read[k] = fx.history;
      } else if (target < fx.targets.size()) {
        const ScreenFx::Target& tgt = fx.targets[target];
        if (tgt.persistent)
          read[k] = tgt.textures[tgt.front];
        else
          read[k] = pooled[target] ? pooled[target]->tex : from;
        ++target;
      } else {
        read[k] = from;
        ++target;
      }
    }
    // Another layer's image. When none is chosen yet, use the effect's own,
    // except for a transition's end image, which is empty (ISF spec, endImage).
    for (size_t k = own; k < read.size(); ++k) {
      // What is behind the layer: the stage's image without it
      // (render_layers.h).
      if (fx.others[k - own] == "backdrop" && s.behind) {
        read[k] = s.behind;
        continue;
      }
      const bool end = fx.others[k - own] == "endImage";
      if (end && !st.clear) {
        st.clear = Texture::Builder()
                       .width(1)
                       .height(1)
                       .levels(1)
                       .format(Texture::InternalFormat::RGBA8)
                       .build(*s.engine);
        st.clear->setImage(
            *s.engine, 0,
            backend::PixelBufferDescriptor(
                new uint32_t(0), 4, backend::PixelDataFormat::RGBA,
                backend::PixelDataType::UBYTE,
                [](void* p, size_t, void*) { delete (uint32_t*)p; }));
      }
      read[k] = k - own < fx.othersNow.size() && fx.othersNow[k - own]
                    ? fx.othersNow[k - own]
                : end ? st.clear
                      : from;
      fx.othersOwn.resize(fx.others.size()),
          fx.othersOwn[k - own] = read[k] == from;
    }
  };
  if (fx.passes.empty()) {
    gather();
    passing(-1);
    const int slot = screen_parameters(s, fx, numbers, 0, w, h);
    interop::draw(s.engine, fx.interop, read.data(), to, w, h, slot, nullptr,
                  over);
    return;
  }
  // If the final pass targets a non-persistent full-size buffer, render that
  // pass directly into `to` and skip the extra full-screen copy pass.
  const int lastTargetIdx = fx.passes.back();
  const bool directFinal = lastTargetIdx >= 0 &&
                           !fx.targets[(size_t)lastTargetIdx].persistent &&
                           fx.targets[(size_t)lastTargetIdx].w == w &&
                           fx.targets[(size_t)lastTargetIdx].h == h;
  for (size_t p = 0; p < fx.passes.size(); ++p) {
    gather();
    const int t = fx.passes[p];
    const bool isDirectLast = directFinal && p + 1 == fx.passes.size();
    passing(t);
    const int slot = screen_parameters(s, fx, numbers, (int)p,
                                       t < 0 ? w : fx.targets[(size_t)t].w,
                                       t < 0 ? h : fx.targets[(size_t)t].h);
    if (t < 0 || isDirectLast) {
      interop::draw(s.engine, fx.interop, read.data(), to, w, h, slot, nullptr,
                    over);
      continue;
    }
    ScreenFx::Target& into = fx.targets[(size_t)t];
    if (into.persistent) {
      const int back = 1 - into.front;
      interop::draw(s.engine, fx.interop, read.data(), into.into[back], into.w,
                    into.h, slot);
      into.front = back;
    } else {
      PooledTarget* prev = pooled[(size_t)t];
      PooledTarget* next =
          screen_pool_acquire_target(s, into.w, into.h, into.fine);
      interop::draw(s.engine, fx.interop, read.data(), next->rt, into.w, into.h,
                    slot);
      if (prev) screen_pool_release_target(s, prev);
      pooled[(size_t)t] = next;
    }
  }
  // The last pass drew into its own target, so that is what the effect shows.
  if (fx.passes.back() >= 0 && !directFinal) {
    const size_t idx = (size_t)fx.passes.back();
    const ScreenFx::Target& last = fx.targets[idx];
    Texture* src =
        last.persistent ? last.textures[last.front] : pooled[idx]->tex;
    interop::draw(s.engine, screen_copy(s, st), &src, to, w, h, 0, nullptr,
                  over);
  }
  releaseAll();
}

namespace {
void sync_from_shared(Stage& s, ScreenFx& fx, SharedScreen& sh) {
  if (fx.interop && !fx.sharedInterop) interop::drop(s.engine, fx.interop);
  screen_targets(s, fx, true);
  fx.parameters = sh.proto.parameters;
  fx.fields = sh.proto.fields;
  fx.bytes = sh.proto.bytes;
  fx.hasFrameRect = sh.proto.hasFrameRect;
  fx.pointwise = sh.proto.pointwise;
  fx.pointwiseSksl = sh.proto.pointwiseSksl;
  fx.preservesZeroAlpha = sh.proto.preservesZeroAlpha;
  fx.usesTime = sh.proto.usesTime;
  fx.wgsl = sh.proto.wgsl;
  fx.uniformStruct = sh.proto.uniformStruct;
  fx.uniformVar = sh.proto.uniformVar;
  fx.sampleExpr = sh.proto.sampleExpr;
  fx.shared = &sh;
  fx.interop = sh.interop;
  fx.sharedInterop = true;
  fx.trouble = sh.proto.trouble;
  fx.textureCount = sh.proto.textureCount;
  fx.targets = sh.proto.targets;
  fx.passes = sh.proto.passes;
  fx.layered = sh.proto.layered;
  fx.historyFrames = sh.proto.historyFrames;
  fx.historyShare = sh.proto.historyShare;
  fx.others = sh.proto.others;
  fx.images = sh.proto.images;
  fx.sounds = sh.proto.sounds;
  fx.source = sh.proto.source;
  fx.spill = sh.proto.spill;
  fx.alpha = sh.proto.alpha;
  fx.stamp = sh.stamp;
  fx.seen = sh.seen;
}
}  // namespace

void screen_fresh(Stage& s, ScreenFx& fx) {
  if (fx.seen == files_changed()) return;
  SharedScreen& sh = screen_shared(s, fx.file);
  fx.seen = sh.seen;
  if (sh.stamp == fx.stamp && fx.interop == sh.interop) return;
  sync_from_shared(s, fx, sh);
}

bool screen_moved(const ScreenStack& st) {
  for (const ScreenFx* fx : st.fx)
    if (fx->seen != files_changed() && screen_stamp(fx->file) != fx->stamp)
      return true;
  return false;
}

ScreenFx* screen_built(Stage& s, ScreenStack& st, const std::string& entry) {
  // The entry may be "id:file" or just "file". Share the compiled GPU program
  // across all layers and stacked instances via StageFxCache, while keeping
  // per-instance state (persistent targets, history, instance_id) separate.
  const std::string id = fx_entry_id(entry);
  const std::string file = fx_entry_path(entry);
  ScreenFx*& built = st.built[entry];
  if (built) return built;
  built = new ScreenFx;
  built->file = file;
  built->instance_id = id;
  SharedScreen& sh = screen_shared(s, file);
  sync_from_shared(s, *built, sh);
  return built;
}

void screen_effects(Stage& s, ScreenStack& st, const std::string& files,
                    ScreenNumbers numbers) {
  if (st.files == files) return;
  st.files = files;
  // Release what was there: the stage draws to the screen again.
  s.over = nullptr;
  s.drawTarget = nullptr;
  s.view->setRenderTarget(nullptr);
  st.fx.clear();
  for (const std::string& file : script_files(files)) {
    // Filament's own settings files are laid on the view, not drawn; see
    // viewer_settings.h.
    if (file == "none" || std::filesystem::path(file).extension() == ".json")
      continue;
    ScreenFx* built = screen_built(s, st, file);
    if (built->interop) st.fx.push_back(built);
  }
  if (st.fx.empty()) return;
  // The intermediate images are made once and kept while the stage is.
  if (!st.shot) {
    st.shot = screen_texture(s);
    st.depth = Texture::Builder()
                   .width((uint32_t)s.w)
                   .height((uint32_t)s.h)
                   .levels(1)
                   .usage(Texture::Usage::DEPTH_ATTACHMENT)
                   .format(Texture::InternalFormat::DEPTH24)
                   .build(*s.engine);
    st.target = RenderTarget::Builder()
                    .texture(RenderTarget::AttachmentPoint::COLOR, st.shot)
                    .texture(RenderTarget::AttachmentPoint::DEPTH, st.depth)
                    .build(*s.engine);
  }
  for (int k = 0; k < 2 && st.fx.size() > 1; ++k)
    if (!st.between[k])
      st.between[k] = screen_texture(s),
      st.betweenTarget[k] =
          RenderTarget::Builder()
              .texture(RenderTarget::AttachmentPoint::COLOR, st.between[k])
              .build(*s.engine);
  s.view->setRenderTarget(st.target);
  // What lies under an image that reads it is copied from here.
  s.drawTarget = st.shot;
  s.over = [&s, &st, numbers] {
    screen_frame_begin(s);
    for (ScreenFx* fx : st.fx) screen_fresh(s, *fx);
    // Fuse contiguous pointwise effects in the stage post-FX chain into single
    // GPU passes when >= 2 pointwise nodes sit adjacent.
    std::vector<std::pair<size_t, size_t>> runs;
    for (size_t i = 0; i < st.fx.size();) {
      if (st.fx[i]->pointwise) {
        size_t j = i + 1;
        while (j < st.fx.size() && st.fx[j]->pointwise) ++j;
        if (j - i >= 2) {
          runs.emplace_back(i, j);
          i = j;
          continue;
        }
      }
      runs.emplace_back(i, i + 1);
      ++i;
    }
    Texture* cur = st.shot;
    for (size_t r = 0; r < runs.size(); ++r) {
      const auto [fromIdx, toIdx] = runs[r];
      const bool last = r + 1 == runs.size();
      RenderTarget* dest = last ? s.out : st.betweenTarget[r % 2];
      Texture* destTex = last ? nullptr : st.between[r % 2];
      const size_t n = toIdx - fromIdx;
      if (n >= 2 &&
          screen_draw_fused(s, st, st.fx.data() + fromIdx, n, false, false, cur,
                            dest, numbers, (uint32_t)s.w, (uint32_t)s.h)) {
        cur = destTex;
        continue;
      }
      // Single effect (or fallback if fusion declined).
      for (size_t k = fromIdx; k < toIdx; ++k) {
        const bool lastOfAll = last && k + 1 == toIdx;
        RenderTarget* stepTo =
            lastOfAll ? s.out : st.betweenTarget[(r + (k - fromIdx)) % 2];
        Texture* stepTex =
            lastOfAll ? nullptr : st.between[(r + (k - fromIdx)) % 2];
        screen_draw(s, st, *st.fx[k], cur, stepTo, numbers);
        cur = stepTex;
      }
    }
  };
}

void screen_stack_off(Stage& s, ScreenStack& st) {
  if (!s.engine) return;
  for (auto& [key, fx] : st.built) {
    if (!fx) continue;
    if (fx->interop && !fx->sharedInterop) interop::drop(s.engine, fx->interop);
    fx->interop = nullptr;
    screen_targets(s, *fx, true);
    if (fx->history) s.engine->destroy(fx->history), fx->history = nullptr;
    for (RenderTarget* rt : fx->historyInto)
      if (rt) s.engine->destroy(rt);
    fx->historyInto.clear();
    for (Texture* t : fx->imagesBuilt)
      if (t) s.engine->destroy(t);
    fx->imagesBuilt.clear();
    for (ScreenFx::Sound& snd : fx->sounds)
      if (snd.texture) s.engine->destroy(snd.texture), snd.texture = nullptr;
    delete fx;
  }
  st.built.clear();
  st.fx.clear();
  st.steps.clear();
  st.aviutl.clear();
  st.aePlugins.clear();
  if (st.copy) interop::drop(s.engine, st.copy), st.copy = nullptr;
  if (st.target) s.engine->destroy(st.target), st.target = nullptr;
  if (st.shot) s.engine->destroy(st.shot), st.shot = nullptr;
  if (st.depth) s.engine->destroy(st.depth), st.depth = nullptr;
  if (st.clear) s.engine->destroy(st.clear), st.clear = nullptr;
  for (int k = 0; k < 2; ++k) {
    if (st.betweenTarget[k])
      s.engine->destroy(st.betweenTarget[k]), st.betweenTarget[k] = nullptr;
    if (st.between[k])
      s.engine->destroy(st.between[k]), st.between[k] = nullptr;
  }
  st.seen = nullptr;
  st.files.clear();
}

}  // namespace motolii

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
// Returns the effect that copies an image unchanged, creating it on first use.
interop::Screen* screen_copy(Stage& s, ScreenStack& st) {
  if (!st.copy) {
    static const char* const same =
        "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) "
        "@binding(1) var near: sampler;\n"
        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: "
        "vec2f) -> @location(0) vec4f { return textureSampleLevel(source, "
        "near, uv, 0.0); }\n";
    st.copy = interop::screen(s.engine, "copy", same, 0);
  }
  return st.copy;
}
}  // namespace

void screen_place(Stage& s, Texture* from, RenderTarget* to, uint32_t w,
                  uint32_t h, const int* at) {
  static std::map<Engine*, interop::Screen*> copies;
  interop::Screen*& copy = copies[s.engine];
  if (!copy) {
    static const char* const same =
        "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) "
        "@binding(1) var near: sampler;\n"
        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: "
        "vec2f) -> @location(0) vec4f { return textureSampleLevel(source, "
        "near, uv, 0.0); }\n";
    copy = interop::screen(s.engine, "place", same, 0);
  }
  if (copy) interop::draw(s.engine, copy, from, to, w, h, at);
}

void screen_tone(Stage& s, Texture* from, RenderTarget* to, uint32_t w,
                 uint32_t h, bool toSrgb) {
  static std::map<Engine*, interop::Screen*> interops[2];
  interop::Screen*& one = interops[toSrgb ? 1 : 0][s.engine];
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
  std::vector<Texture*> read((size_t)fx.textureCount, from);
  const auto gather = [&] {
    size_t target = 0;
    const size_t own = read.size() - fx.others.size();
    for (size_t k = 1; k < own; ++k)
      read[k] = (fx.layered >> k) & 1u ? fx.history
                : target < fx.targets.size()
                    ? fx.targets[target].textures[fx.targets[target].front]
                    : from,
      target += !((fx.layered >> k) & 1u);
    // Another layer's image. When none is chosen yet, use the effect's own,
    // except for a transition's end image, which is empty (ISF spec, endImage).
    for (size_t k = own; k < read.size(); ++k) {
      // What is behind the layer: the stage's image without it
      // (render_layers.h); AbsentMotion's backdrop.
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
    screen_parameters(s, fx, numbers, 0, w, h);
    interop::draw(s.engine, fx.interop, read.data(), to, w, h, 0, nullptr,
                  over);
    return;
  }
  for (size_t p = 0; p < fx.passes.size(); ++p) {
    gather();
    const int t = fx.passes[p];
    passing(t);
    screen_parameters(s, fx, numbers, (int)p,
                      t < 0 ? w : fx.targets[(size_t)t].w,
                      t < 0 ? h : fx.targets[(size_t)t].h);
    if (t < 0) {
      interop::draw(s.engine, fx.interop, read.data(), to, w, h, (int)p,
                    nullptr, over);
      continue;
    }
    ScreenFx::Target& into = fx.targets[(size_t)t];
    const int back = 1 - into.front;
    interop::draw(s.engine, fx.interop, read.data(), into.into[back], into.w,
                  into.h, (int)p);
    into.front = back;
  }
  // The last pass drew into its own target, so that is what the effect shows.
  if (fx.passes.back() >= 0) {
    const ScreenFx::Target& last = fx.targets[(size_t)fx.passes.back()];
    interop::draw(s.engine, screen_copy(s, st), &last.textures[last.front], to,
                  w, h, 0, nullptr, over);
  }
}

void screen_fresh(Stage& s, ScreenFx& fx) {
  if (fx.seen == files_changed()) return;
  fx.seen = files_changed();
  const auto stamp = screen_stamp(fx.file);
  if (stamp == fx.stamp) return;
  fx.stamp = stamp;
  ScreenFx again;
  again.file = fx.file;
  std::string code;
  if (!screen_read(again, code)) {
    std::fprintf(stderr, "%s\n", again.trouble.c_str());
    return;
  }
  interop::Screen* built =
      interop::screen(s.engine, fx.file.c_str(), code.c_str(), again.bytes,
                      &again.trouble, again.textureCount, again.layered);
  if (!built) {
    std::fprintf(stderr,
                 "the effect %s as written now is not taken (the one before "
                 "stays): %s\n",
                 fx.file.c_str(), again.trouble.c_str());
    return;
  }
  interop::drop(s.engine, fx.interop);
  screen_targets(s, fx, true);
  fx.parameters = again.parameters, fx.fields = again.fields,
  fx.bytes = again.bytes, fx.interop = built;
  // The history frames are kept as they are while their count stays the same.
  fx.textureCount = again.textureCount, fx.targets = again.targets,
  fx.passes = again.passes, fx.layered = again.layered, fx.spill = again.spill,
  fx.alpha = again.alpha;
}

bool screen_moved(const ScreenStack& st) {
  for (const ScreenFx* fx : st.fx)
    if (fx->seen != files_changed() && screen_stamp(fx->file) != fx->stamp)
      return true;
  return false;
}

ScreenFx* screen_built(Stage& s, ScreenStack& st, const std::string& file) {
  ScreenFx*& built = st.built[file];
  if (built) return built;
  built = new ScreenFx;
  built->file = file;
  std::string code;
  // Keep the effect marked as not built (interop null), so that it is not read
  // again each time.
  if (!screen_read(*built, code)) {
    std::fprintf(stderr, "%s\n", built->trouble.c_str());
    return built;
  }
  built->interop =
      interop::screen(s.engine, file.c_str(), code.c_str(), built->bytes,
                      &built->trouble, built->textureCount, built->layered);
  if (!built->interop)
    std::fprintf(stderr, "the effect %s is not taken: %s\n", file.c_str(),
                 built->trouble.c_str());
  built->stamp = screen_stamp(file);
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
    for (size_t i = 0; i < st.fx.size(); ++i) {
      screen_fresh(s, *st.fx[i]);
      Texture* from = i == 0 ? st.shot : st.between[(i - 1) % 2];
      // The last effect draws where the stage's image goes: the screen, or the
      // window's live image.
      RenderTarget* to =
          i + 1 == st.fx.size() ? s.out : st.betweenTarget[i % 2];
      screen_draw(s, st, *st.fx[i], from, to, numbers);
    }
  };
}

}  // namespace motolii

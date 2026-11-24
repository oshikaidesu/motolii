// What an effect's passes read and write: the pictures and sounds it takes as
// inputs, the uniform struct of its parameters, and the textures of its
// targets.

#include <backend/DriverEnums.h>
#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <math/half.h>
#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/screen_pool.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Engine;
using filament::RenderTarget;
using filament::Texture;
namespace backend = filament::backend;
namespace math = filament::math;

namespace {
// Loads a picture file with ThorVG, draws it once at its own size, and returns
// it as a Filament texture. Returns nullptr when the file cannot be read or is
// larger than 4096 in either direction.
Texture* screen_image(Stage& s, const std::string& file) {
  float w = 0, h = 0;
  // Start ThorVG before loading: it skips reading a file when it is not started
  // (see TaskScheduler::request in tvgTaskScheduler.cpp).
  tvg::Initializer::init(0);
  tvg::Picture* p = tvg::Picture::gen();
  if (p->load(file.c_str()) != tvg::Result::Success ||
      p->size(&w, &h) != tvg::Result::Success || w < 1 || h < 1 || w > 4096 ||
      h > 4096)
    return delete p, nullptr;
  auto* pixels = new std::vector<uint32_t>((size_t)w * (size_t)h, 0);
  tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
  const bool drew =
      canvas->target(pixels->data(), (uint32_t)w, (uint32_t)w, (uint32_t)h,
                     tvg::ColorSpace::ABGR8888) == tvg::Result::Success &&
      canvas->add(p) == tvg::Result::Success &&
      canvas->draw(true) == tvg::Result::Success &&
      canvas->sync() == tvg::Result::Success;
  delete canvas;
  if (!drew) return delete pixels, nullptr;
  Texture* t = Texture::Builder()
                   .width((uint32_t)w)
                   .height((uint32_t)h)
                   .levels(1)
                   .format(Texture::InternalFormat::RGBA8)
                   .build(*s.engine);
  t->setImage(
      *s.engine, 0,
      backend::PixelBufferDescriptor(
          pixels->data(), pixels->size() * 4, backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE,
          [](void*, size_t, void* u) { delete (std::vector<uint32_t>*)u; },
          pixels));
  return t;
}  // namespace

}  // namespace

// Builds the input textures of an effect for the current frame. Image files are
// loaded once. Audio inputs are rebuilt each frame from their current values
// and uploaded with Filament's setImage; the value buffer is freed by the
// PixelBufferDescriptor callback once it is sent.
void screen_sounds(Stage& s, ScreenStack& st, ScreenFx& fx) {
  fx.othersNow.resize(fx.others.size(), nullptr);
  fx.imagesBuilt.resize(fx.others.size(), nullptr);
  for (size_t k = 0; k < fx.images.size(); ++k) {
    if (fx.images[k].empty()) continue;
    if (!fx.imagesBuilt[k] &&
        !(fx.imagesBuilt[k] = screen_image(s, fx.images[k]))) {
      fx.trouble = "its image " + fx.images[k] + " is not read",
      fx.images[k].clear();
      continue;
    }
    fx.othersNow[k] = fx.imagesBuilt[k];
  }
  for (size_t k = 0; k < fx.sounds.size(); ++k) {
    ScreenFx::Sound& one = fx.sounds[k];
    if (!one.is) continue;
    if (one.audioLink) {
      fx.othersNow[k] = screen_pool_audiolink(s, [&](bool fft, int wide) {
        return st.sounds ? st.sounds(fx.file, fx.others[k], fft, wide)
                         : std::vector<float>();
      });
      continue;
    }
    const std::string key =
        fx.others[k] + "|" + (one.fft ? "f|" : "w|") + std::to_string(one.wide);
    fx.othersNow[k] = screen_pool_sound(s, key, one.fft, one.wide, [&] {
      return st.sounds ? st.sounds(fx.file, fx.others[k], one.fft, one.wide)
                       : std::vector<float>();
    });
  }
}

void screen_fill_parameters(Stage& s, ScreenFx& fx,
                            const ScreenNumbers& numbers, float* out, int pass,
                            double pw, double ph) {
  if (!fx.bytes || !out) return;
  std::memset(out, 0, fx.bytes);
  const double w = (pw > 0 ? pw : s.w) * (fx.hasFrameRect ? fx.pass[2] : 1.0),
               h = (ph > 0 ? ph : s.h) * (fx.hasFrameRect ? fx.pass[3] : 1.0);
  const std::string key = fx.numbers_key();
  for (const ScreenFx::Field& f : fx.fields) {
    float v[4] = {0, 0, 0, 0};
    using K = ScreenFx::FieldKind;
    switch (f.kind) {
      case K::Time:
        v[0] = (float)s.now;
        break;
      case K::ClipTime:
        v[0] = (float)numbers(key, "clip_time", 0);
        break;
      case K::FrameRect:
        for (int i = 0; i < 4; ++i) v[i] = (float)fx.frame[i];
        break;
      case K::PassRect:
        for (int i = 0; i < 4; ++i) v[i] = (float)fx.pass[i];
        break;
      case K::IsfOther: {
        const bool own = f.otherIdx >= 0 &&
                         (size_t)f.otherIdx < fx.othersOwn.size() &&
                         fx.othersOwn[(size_t)f.otherIdx];
        for (int i = 0; i < 4; ++i)
          v[i] = own ? (float)fx.frame[i] : i < 2 ? 0.f : 1.f;
        break;
      }
      case K::Aspect:
        v[0] = (float)(w / h);
        break;
      case K::Resolution:
        v[0] = (float)w, v[1] = (float)h;
        break;
      case K::Screen:
        v[2] = (float)w, v[3] = (float)h;
        break;
      case K::Duration:
        v[0] = (float)numbers(key, "clip_length", 0);
        break;
      case K::Layer:
        v[0] = (float)std::max(1.0, numbers(key, "layerRect_z", w));
        v[1] = (float)std::max(1.0, numbers(key, "layerRect_w", h));
        break;
      case K::Width:
        v[0] = (float)w;
        break;
      case K::Height:
        v[0] = (float)h;
        break;
      case K::Frame:
        v[0] = (float)std::lround(s.now * screen_rate(s));
        break;
      case K::IsfRate:
        v[0] = (float)screen_rate(s);
        break;
      case K::PassIndex:
        v[0] = (float)pass;
        break;
      case K::HistoryHead:
        v[0] = (float)std::max(0, fx.head);
        break;
      case K::HistoryCount:
        v[0] = (float)fx.historyFrames;
        break;
      case K::Param:
        if (fx.paramValsFrame == s.frameCount && f.useCachedVal) {
          for (uint32_t i = 0; i < f.floats && i < 4; ++i) v[i] = f.paramVal[i];
        } else {
          for (uint32_t i = 0; i < f.floats && i < 4; ++i)
            v[i] = (float)numbers(key, f.paramNames[i], f.usual[i]);
        }
        break;
    }
    for (uint32_t i = 0; i < f.floats; ++i) {
      if (f.whole) {
        const int32_t iv = (int32_t)std::lround(v[i]);
        std::memcpy(&out[f.at / 4 + i], &iv, 4);
      } else {
        out[f.at / 4 + i] = v[i];
      }
    }
  }
}

int screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers,
                      int pass, double pw, double ph) {
  if (!fx.bytes) return 0;
  const uint32_t rw = (uint32_t)(pw > 0 ? pw : s.w),
                 rh = (uint32_t)(ph > 0 ? ph : s.h);
  if (fx.paramBufFrame != s.frameCount || fx.paramBufW != rw ||
      fx.paramBufH != rh || fx.paramBufPass != pass ||
      fx.paramBuf.size() != fx.bytes / 4) {
    fx.paramBuf.resize(fx.bytes / 4);
    screen_fill_parameters(s, fx, numbers, fx.paramBuf.data(), pass, pw, ph);
    fx.paramBufFrame = s.frameCount;
    fx.paramBufW = rw;
    fx.paramBufH = rh;
    fx.paramBufPass = pass;
  }
  int slot = pass;
  if (fx.shared) {
    if (fx.shared->slotFrame != s.frameCount)
      fx.shared->slotFrame = s.frameCount, fx.shared->nextSlot = 0;
    slot = (int)fx.shared->nextSlot++;
  }
  interop::parameters(s.engine, fx.interop, fx.paramBuf.data(),
                      (uint32_t)(fx.paramBuf.size() * 4), slot);
  return slot;
}

// Creates persistent ISF target textures (double-buffered across frames).
// Non-persistent intermediate pass targets are borrowed per-draw from
// StageFxCache's transient pool so layers share hot GPU memory.
void screen_targets(Stage& s, ScreenFx& fx, bool drop, uint32_t pw,
                    uint32_t ph) {
  const double W = pw ? pw : s.w, H = ph ? ph : s.h;
  for (ScreenFx::Target& t : fx.targets) {
    const uint32_t w =
        t.points[0] ? (uint32_t)t.points[0]
                    : (uint32_t)std::max(1L, std::lround(W * t.share[0]));
    const uint32_t h =
        t.points[1] ? (uint32_t)t.points[1]
                    : (uint32_t)std::max(1L, std::lround(H * t.share[1]));
    if (!t.persistent) {
      // Always track current dimensions for pooled target borrowing.
      t.w = w, t.h = h;
      if (drop) {
        for (int k = 0; k < 2; ++k) {
          if (t.into[k]) s.engine->destroy(t.into[k]), t.into[k] = nullptr;
          if (t.textures[k]) {
            interop::invalidate_textures(s.engine);
            s.engine->destroy(t.textures[k]), t.textures[k] = nullptr;
          }
        }
      }
      continue;
    }
    for (int k = 0; k < 2; ++k) {
      if (drop || (t.textures[k] && (t.w != w || t.h != h))) {
        if (t.into[k]) s.engine->destroy(t.into[k]), t.into[k] = nullptr;
        if (t.textures[k]) {
          interop::invalidate_textures(s.engine);
          s.engine->destroy(t.textures[k]), t.textures[k] = nullptr;
        }
        if (drop) continue;
      }
      if (t.textures[k]) continue;
      t.w = w, t.h = h;
      t.textures[k] = Texture::Builder()
                          .width(t.w)
                          .height(t.h)
                          .levels(1)
                          .format(t.fine ? Texture::InternalFormat::RGBA16F
                                         : Texture::InternalFormat::RGBA8)
                          .usage(Texture::Usage::COLOR_ATTACHMENT |
                                 Texture::Usage::SAMPLEABLE)
                          .build(*s.engine);
      t.into[k] =
          RenderTarget::Builder()
              .texture(RenderTarget::AttachmentPoint::COLOR, t.textures[k])
              .build(*s.engine);
    }
  }
}

}  // namespace motolii

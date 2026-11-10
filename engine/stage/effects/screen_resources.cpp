// What an effect's passes read and write: the pictures and sounds it takes as
// inputs, the uniform struct of its parameters, and the textures of its targets.

#include "stage/effects/screen_fx.h"

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

}

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
    std::vector<float> v =
        st.sounds ? st.sounds(fx.file, fx.others[k], one.fft, one.wide)
                  : std::vector<float>();
    if (v.empty())
      v.assign((size_t)std::max(one.wide, 1), one.fft ? 0.f : 0.5f);
    if (one.texture && one.texture->getWidth() != v.size())
      s.engine->destroy(one.texture), one.texture = nullptr;
    if (!one.texture)
      one.texture = Texture::Builder()
                        .width((uint32_t)v.size())
                        .height(1)
                        .levels(1)
                        .format(Texture::InternalFormat::R16F)
                        .build(*s.engine);
    auto* halves = new std::vector<math::half>(v.begin(), v.end());
    one.texture->setImage(
        *s.engine, 0,
        backend::PixelBufferDescriptor(
            halves->data(), halves->size() * sizeof(math::half),
            backend::PixelDataFormat::R, backend::PixelDataType::HALF,
            [](void*, size_t, void* user) {
              delete (std::vector<math::half>*)user;
            },
            halves));
    fx.othersNow[k] = one.texture;
  }
}

// Fills the parameter uniform struct of `fx` for one pass and uploads it.
// Members with special names (time, frameRect, passRect, aspect, resolution and
// so on) are computed by the stage; every other member is read through
// `numbers`, a vector one component at a time as name_x, name_y and so on.
// `pass` is the pass index. pw and ph give the size of the image drawn into in
// pixels, or 0 for the stage size.
void screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers,
                       int pass, double pw, double ph) {
  std::vector<float> at(fx.bytes / 4, 0.f);
  // An ISF effect declares frameRect and is told its frame's size. A WGSL
  // effect reads its layerRect, or the whole image.
  const bool framed = std::any_of(
      fx.fields.begin(), fx.fields.end(),
      [](const ScreenFx::Field& f) { return f.name == "frameRect"; });
  // The size in pixels of the image drawn into: ISF's RENDERSIZE, which each
  // pass has of its own (ISF spec, VVISF). The same rule as vgpu: a shader is
  // told the size of its own target, as gl_FragCoord and @builtin(position)
  // count it.
  const double w = (pw > 0 ? pw : s.w) * (framed ? fx.pass[2] : 1.0),
               h = (ph > 0 ? ph : s.h) * (framed ? fx.pass[3] : 1.0);
  for (const ScreenFx::Field& f : fx.fields) {
    float v[4] = {0, 0, 0, 0};
    if (f.name == "time")
      v[0] = (float)s.now;
    else if (f.name == "frameRect" || f.name == "passRect")
      for (int i = 0; i < 4; ++i)
        v[i] = (float)(f.name == "passRect" ? fx.pass : fx.frame)[i];
    // Where one of the other inputs is read: the effect's own image by the
    // frame, another layer's image whole.
    else if (f.name.rfind("isf_other_", 0) == 0) {
      const size_t k = (size_t)(std::find(fx.others.begin(), fx.others.end(),
                                          f.name.substr(10)) -
                                fx.others.begin());
      const bool own = k < fx.othersOwn.size() && fx.othersOwn[k];
      for (int i = 0; i < 4; ++i)
        v[i] = own ? (float)fx.frame[i] : i < 2 ? 0.f : 1.f;
    } else if (f.name == "aspect")
      v[0] = (float)(w / h);
    else if (f.name == "resolution")
      v[0] = (float)w, v[1] = (float)h;
    // AbsentMotion's effects.cpp defines screen as -area.left, -area.top, the
    // scene's width and height. This image is that scene, so a wave's reach is
    // magnitude * min(screen.z, screen.w) * 0.01.
    else if (f.name == "screen" && f.floats >= 4)
      v[2] = (float)w, v[3] = (float)h;
    else if ((f.name == "layer" && f.floats == 2) ||
                     (f.name == "duration" && f.floats == 1)
                 ? std::none_of(fx.parameters.begin(), fx.parameters.end(),
                                [&](const ScriptParameter& one) {
                                  return one.name.rfind(f.name, 0) == 0;
                                })
                 : false) {
      // These come from AbsentMotion's effects.cpp, each only where the file
      // has no parameter of that name. `layer` is the layer's own width and
      // height, at least 1: on a layer its rectangle on its image (layerRect),
      // on the whole image the image's. `duration` is the layer's length in
      // seconds (clip_length: the layer's, or the document's). Block Noise's
      // blocks are a share of `layer`.
      if (f.name == "duration")
        v[0] = (float)numbers(fx.file, "clip_length", 0);
      else
        v[0] = (float)std::max(1.0, numbers(fx.file, "layerRect_z", w)),
        v[1] = (float)std::max(1.0, numbers(fx.file, "layerRect_w", h));
    } else if ((f.name == "width" || f.name == "height") &&
               std::none_of(fx.fields.begin(), fx.fields.end(),
                            [](const ScreenFx::Field& g) {
                              return g.name == "resolution";
                            }) &&
               !(fx.file.ends_with(".fs") &&
                 std::any_of(fx.parameters.begin(), fx.parameters.end(),
                             [&](const ScriptParameter& one) {
                               return one.name == f.name;
                             })))
      // The image size for three.js shaders: halftone.wgsl divides by width
      // and height. A shader that already has resolution, or an ISF parameter
      // of the same name, keeps the parameter the file declares.
      v[0] = (float)(f.name == "width" ? w : h);
    // ISF's FRAMEINDEX: the frame number (ISF spec).
    else if (f.name == "frame")
      v[0] = (float)std::lround(s.now * screen_rate(s));
    // The frame rate; ISF's TIMEDELTA is its reciprocal, the time since the
    // last frame (ISF spec).
    else if (f.name == "isf_rate")
      v[0] = (float)screen_rate(s);
    // ISF's PASSINDEX. The member is not called `pass` because that is a
    // reserved word in WGSL.
    else if (f.name == "passindex")
      v[0] = (float)pass;
    else if (f.name == "history_head")
      v[0] = (float)std::max(0, fx.head);
    else if (f.name == "history_count")
      v[0] = (float)fx.historyFrames;
    else
      // Each component of a vector is a parameter of its own: name_x, name_y
      // and so on.
      for (uint32_t i = 0; i < f.floats; ++i) {
        const std::string k = f.floats == 1 ? f.name : f.name + "_" + "xyzw"[i];
        double usual = 0;
        for (const ScriptParameter& one : fx.parameters)
          if (one.name == k) usual = one.usual;
        v[i] = (float)numbers(fx.file, k, usual);
      }
    for (uint32_t i = 0; i < f.floats; ++i) {
      if (f.whole) {
        const int32_t w = (int32_t)std::lround(v[i]);
        std::memcpy(&at[f.at / 4 + i], &w, 4);
      } else
        at[f.at / 4 + i] = v[i];
    }
  }
  if (!at.empty())
    interop::parameters(s.engine, fx.interop, at.data(),
                        (uint32_t)(at.size() * 4), pass);
}

// Creates the images an effect's passes draw into, when first drawn, at the
// size the stage gives. Each target has two textures: one is read while the
// other is drawn into, then they swap. A persistent target's read texture is
// the last frame's when read before it is drawn. If `drop` is true the textures
// are destroyed and not recreated. pw and ph give the size of the image drawn
// into, or 0 for the stage size.
void screen_targets(Stage& s, ScreenFx& fx, bool drop, uint32_t pw,
                    uint32_t ph) {
  // Sizes are a share of the image drawn into, as the ISF PASSES say: a layer's
  // box, or the stage.
  const double W = pw ? pw : s.w, H = ph ? ph : s.h;
  for (ScreenFx::Target& t : fx.targets)
    for (int k = 0; k < 2; ++k) {
      const uint32_t w =
          t.points[0] ? (uint32_t)t.points[0]
                      : (uint32_t)std::max(1L, std::lround(W * t.share[0]));
      const uint32_t h =
          t.points[1] ? (uint32_t)t.points[1]
                      : (uint32_t)std::max(1L, std::lround(H * t.share[1]));
      // Destroyed when dropped, or when the image it serves has changed size;
      // it is then made again.
      if (drop || (t.textures[k] && (t.w != w || t.h != h))) {
        if (t.into[k]) s.engine->destroy(t.into[k]), t.into[k] = nullptr;
        if (t.textures[k])
          s.engine->destroy(t.textures[k]), t.textures[k] = nullptr;
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

}  // namespace motolii

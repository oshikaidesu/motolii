#include "stage/live.h"

#include <cmath>
#include <cstdint>
#include <initializer_list>

#include <CoreVideo/CoreVideo.h>
#include <Foundation/Foundation.h>
#include <IOSurface/IOSurface.h>

#include <filament/Engine.h>
#include <filament/Fence.h>
#include <filament/RenderTarget.h>
#include <filament/Renderer.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <math/vec2.h>
#include <thorvg.h>
#include <webgpu/webgpu.h>

#include "gpu/gpu_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Engine;
using filament::Fence;
using filament::RenderTarget;
using filament::Texture;
using filament::math::float2;

namespace {

// Draws the editing overlay on top of the frame in buffer i of the editing window's Live.
//
// ThorVG draws into the same buffer after Filament has finished, without clearing it, on the same
// device and queue (the approach canvas.h uses). The overlay has a half-transparent cover over the
// area outside the stage, then for the selected layer its outline, four corner handles, a rotation
// handle, and the pivot, and a thin outline for the layer under the pointer. It reproduces what
// stage_view.dart used to draw in the app.
void desk_marks(Stage& s, Live* l, int i) {
  const auto k = s.desk;

  void *device = interop::device(s.engine), *instance = interop::instance(s.engine);
  const int s_w = s.w, s_h = s.h;
  interop::on_driver(s.engine, [l, i, k, device, instance, s_w, s_h] {
    auto& canvas = reinterpret_cast<tvg::WgCanvas*&>(l->marks[i]);
    if (!canvas) {
      // Same as canvas.h. Initialization is reference counted, so once is enough.
      tvg::Initializer::init(0);
      canvas = tvg::WgCanvas::gen();
      // The last argument, 2, selects drawing over existing content (thorvg_over.patch).
      if (!canvas || canvas->target(device, instance, l->shared[i], k.w, k.h,
                                    tvg::ColorSpace::ABGR8888S, 2) != tvg::Result::Success)
        return;
    }
    canvas->remove();
    const float pt = (float)k.point;
    const auto at = [&](double x, double y) {
      return float2{(float)(x * k.scale + k.x), (float)(y * k.scale + k.y)};
    };
    struct Frame {
      float2 c[4], top, mid, pivot;
    };
    // Corners of a layer's box on the screen, rotated clockwise about its center. f holds the
    // center x, y, width, height, rotation in degrees, and the pivot x, y.
    const auto frame = [&](const double* f) {
      const double turn = f[4] * 3.14159265358979 / 180.0, cs = std::cos(turn), sn = std::sin(turn);
      const auto local = [&](double u, double v) {
        const double x = u * 0.5 * f[2], y = v * 0.5 * f[3];
        return at(f[0] + x * cs - y * sn, f[1] + x * sn + y * cs);
      };
      return Frame{{local(-1, -1), local(1, -1), local(1, 1), local(-1, 1)},
                   local(0, -1),
                   at(f[0], f[1]),
                   at(f[5], f[6])};
    };
    // The overlay is deliberately quiet: no dark edging, thin lines, small handles, and slight
    // transparency. The accent color matches the app's.
    const auto line = [&](std::initializer_list<float2> pts, bool closed, float width, uint8_t a) {
      tvg::Shape* sh = tvg::Shape::gen();
      bool first = true;
      for (float2 p : pts) {
        if (first)
          sh->moveTo(p.x, p.y);
        else
          sh->lineTo(p.x, p.y);
        first = false;
      }
      if (closed) sh->close();
      sh->strokeWidth(width * pt), sh->strokeFill(0xB3, 0xC6, 0x6B, a),
          sh->strokeCap(tvg::StrokeCap::Round);
      canvas->add(sh);
    };
    const auto square = [&](float2 c, float half) {
      tvg::Shape* sh = tvg::Shape::gen();
      sh->appendRect(c.x - half * pt, c.y - half * pt, 2.f * half * pt, 2.f * half * pt, 0.6f * pt,
                     0.6f * pt);
      sh->fill(0xB3, 0xC6, 0x6B, 230);
      canvas->add(sh);
    };
    const auto dot = [&](float2 c, float r) {
      tvg::Shape* sh = tvg::Shape::gen();
      sh->appendCircle(c.x, c.y, r * pt, r * pt);
      sh->fill(0xB3, 0xC6, 0x6B, 230);
      canvas->add(sh);
    };
    // Half-cover the area outside the stage so the stage reads as the picture.
    tvg::Shape* off = tvg::Shape::gen();
    off->appendRect(0, 0, (float)k.w, (float)k.h);
    off->appendRect((float)k.x, (float)k.y, (float)(s_w * k.scale), (float)(s_h * k.scale), 0, 0,
                    false);
    // The app's surround color, Grey.g10, at about half opacity.
    off->fill(0x19, 0x19, 0x19, 140);
    canvas->add(off);
    // The layer under the pointer gets a thin pale outline.
    if (k.hovered) {
      const Frame f = frame(k.hover);
      tvg::Shape* sh = tvg::Shape::gen();
      sh->moveTo(f.c[0].x, f.c[0].y);
      for (int i = 1; i < 4; ++i) sh->lineTo(f.c[i].x, f.c[i].y);
      sh->close();
      sh->strokeWidth(1.f * pt), sh->strokeFill(0xE6, 0xE6, 0xE6, 150);
      canvas->add(sh);
    }
    if (k.picked) {
      const Frame f = frame(k.pick);
      // Outline of the selected layer: the four corners joined.
      line({f.c[0], f.c[1], f.c[2], f.c[3]}, true, 1.f, 220);
      // The rotation handle sits one stem length out from the middle of the top edge.
      if (k.rotateHandle) {
        float2 n = f.top - f.mid;
        const float len = length(n);
        n = len < 1.f ? float2{0.f, -1.f} : n / len;
        // The stem length matches the one the app hit-tests (stage_view.dart _V.stem).
        const float2 handle = f.top + n * 18.f * pt;
        line({f.top, handle}, false, 0.75f, 140);
        dot(handle, 2.75f);
      }
      // Corner handles, used to resize.
      for (float2 c : f.c) square(c, 2.75f);
      // Side-middle handles, shown only together with the rotation handle (see
      // stage_view.dart _handles).
      if (k.rotateHandle)
        for (int i = 0; i < 4; ++i) square((f.c[i] + f.c[(i + 1) % 4]) * 0.5f, 2.75f);
      // The pivot that rotation turns about: a small ring and four short ticks.
      tvg::Shape* ring = tvg::Shape::gen();
      ring->appendCircle(f.pivot.x, f.pivot.y, 4.f * pt, 4.f * pt);
      ring->strokeWidth(1.f * pt), ring->strokeFill(0xB3, 0xC6, 0x6B, 200);
      canvas->add(ring);
      for (float2 d : {float2{1, 0}, float2{-1, 0}, float2{0, 1}, float2{0, -1}})
        line({f.pivot + d * 2.f * pt, f.pivot + d * 7.f * pt}, false, 1.f, 200);
    }
    canvas->update();
    // Clears the canvas's own content but draws over the buffer instead of replacing it
    // (target type 2, thorvg_over.patch).
    canvas->draw(true);
    canvas->sync();
  });
}

}  // namespace

Live* live_open(Stage& s, uint32_t w, uint32_t h) {
  Live* l = new Live;
  if (!w) w = (uint32_t)s.w, h = (uint32_t)s.h;
  NSDictionary* like = @{
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    (id)kCVPixelBufferMetalCompatibilityKey : @YES
  };
  for (CVPixelBufferRef& b : l->buffer)
    if (CVPixelBufferCreate(kCFAllocatorDefault, (size_t)w, (size_t)h, kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)like, &b) != kCVReturnSuccess)
      return nullptr;
  Engine* engine = s.engine;
  interop::on_driver(engine, [l, engine, w, h] {
    for (int i = 0; i < Live::N; ++i) {
      WGPUSharedTextureMemoryIOSurfaceDescriptor from{};
      from.chain.sType = WGPUSType_SharedTextureMemoryIOSurfaceDescriptor;
      from.ioSurface = CVPixelBufferGetIOSurface(l->buffer[i]);
      WGPUSharedTextureMemoryDescriptor what{};
      what.nextInChain = &from.chain;
      l->lent[i] = wgpuDeviceImportSharedTextureMemory((WGPUDevice)interop::device(engine), &what);
      WGPUTextureDescriptor as{};
      as.size = {w, h, 1};
      as.format = WGPUTextureFormat_BGRA8Unorm;
      as.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
      as.dimension = WGPUTextureDimension_2D;
      as.mipLevelCount = 1;
      as.sampleCount = 1;
      l->shared[i] = wgpuSharedTextureMemoryCreateTexture(l->lent[i], &as);
      // Access stays open while the stage is live. On macOS this locks nothing.
      WGPUSharedTextureMemoryBeginAccessDescriptor lend{};
      lend.initialized = false;
      wgpuSharedTextureMemoryBeginAccess(l->lent[i], l->shared[i], &lend);
    }
  });
  s.engine->flushAndWait();
  for (int i = 0; i < Live::N; ++i) {
    if (!l->shared[i]) return nullptr;
    l->seen[i] = Texture::Builder()
                     .width(w)
                     .height(h)
                     .levels(1)
                     .sampler(Texture::Sampler::SAMPLER_2D)
                     .format(Texture::InternalFormat::RGBA8)
                     .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
                     .import((intptr_t)l->shared[i])
                     .build(*s.engine);
    l->target[i] = RenderTarget::Builder()
                       .texture(RenderTarget::AttachmentPoint::COLOR, l->seen[i])
                       .build(*s.engine);
  }
  return l;
}

void live_close(Stage& s, Live* l) {
  if (!l) return;
  s.engine->flushAndWait();
  interop::on_driver(s.engine, [l] {
    for (void* c : l->marks) delete reinterpret_cast<tvg::WgCanvas*>(c);
  });
  for (int i = 0; i < Live::N; ++i) {
    if (l->target[i]) s.engine->destroy(l->target[i]);
    if (l->seen[i]) s.engine->destroy(l->seen[i]);
  }
  s.engine->flushAndWait();
  interop::on_driver(s.engine, [l] {
    for (int i = 0; i < Live::N; ++i) {
      if (l->shared[i]) wgpuTextureRelease(l->shared[i]);
      if (l->lent[i]) wgpuSharedTextureMemoryRelease(l->lent[i]);
    }
  });
  s.engine->flushAndWait();
  // An app that still holds a buffer keeps it alive until it releases it.
  for (CVPixelBufferRef b : l->buffer)
    if (b) CVPixelBufferRelease(b);
  if (l->pending) s.engine->destroy(l->pending);
  delete l;
}

void live_draw(Stage& s, Live* l) {
  Live* desk = l->desk && s.desk.w ? l->desk : nullptr;
  // With effects, whether full-screen or on a single layer, the stage is drawn the way an
  // exported video frame is drawn and then placed in the editing window where the stage lies.
  // An effect belongs to the frame, so the area outside the stage is not part of it. This is
  // the usual post-processing arrangement: render the scene into an offscreen target, apply
  // the effect to that, then present.
  const bool placed = desk && (s.over || !s.before.empty());
  s.out = desk && !placed ? desk->target[desk->next] : l->target[l->next];
  if (desk && !placed) desk_lay(s, true);
  // The texture the views draw into, for a view that reads what is beneath it (see render.h).
  Texture* const wasInto = s.drawTarget;
  if (!s.over) s.drawTarget = desk && !placed ? desk->seen[desk->next] : l->seen[l->next];
  if (placed) {
    const int i = l->next, j = desk->next;
    const int at[4] = {(int)std::lround(s.desk.x),
                       (int)std::lround((double)s.desk.h - s.desk.y - s.h * s.desk.scale),
                       (int)std::lround(s.w * s.desk.scale), (int)std::lround(s.h * s.desk.scale)};
    s.lastly = [&s, l, desk, i, j, at] {
      screen_place(s, l->seen[i], desk->target[j], s.desk.w, s.desk.h, at);
    };
  }
  // With a full-screen effect the stage draws to its own texture and the effect draws to this
  // one (see screen_fx.h).
  if (!s.over) {
    s.view->setRenderTarget(s.out);
  }
  draw(s, nullptr, false);
  s.lastly = nullptr;
  s.drawTarget = wasInto;
  if (desk) desk_marks(s, desk, desk->next);
  if (desk) {
    if (!placed) desk_lay(s, false);
    desk->pendingIn = desk->next;
    desk->next = (desk->next + 1) % Live::N;
  }
  // The fence is not waited on here so the render thread can return to its other work.
  // live_ready publishes the frame once the GPU is done.
  l->pending = s.engine->createFence();
  s.engine->flush();
  l->pendingIn = l->next;
  if (!s.over) {
    s.view->setRenderTarget(nullptr);
  }
  s.out = nullptr;
  // The stage's own buffer was not drawn, so its last frame stays the front one.
  if (desk && !placed)
    l->pendingIn = -1;
  else
    l->next = (l->next + 1) % Live::N;
}

void live_show(Stage& s, Live* l, Texture* frameTexture) {
  Live* desk = l->desk && s.desk.w ? l->desk : nullptr;
  while (!begins(s)) {
  }
  if (desk) {
    const int at[4] = {(int)std::lround(s.desk.x),
                       (int)std::lround((double)s.desk.h - s.desk.y - s.h * s.desk.scale),
                       (int)std::lround(s.w * s.desk.scale), (int)std::lround(s.h * s.desk.scale)};
    screen_place(s, frameTexture, desk->target[desk->next], s.desk.w, s.desk.h, at);
  } else
    screen_place(s, frameTexture, l->target[l->next], (uint32_t)s.w, (uint32_t)s.h, nullptr);
  s.renderer->endFrame();
  if (desk) {
    desk_marks(s, desk, desk->next);
    desk->pendingIn = desk->next;
    desk->next = (desk->next + 1) % Live::N;
  }
  l->pending = s.engine->createFence();
  s.engine->flush();
  l->pendingIn = desk ? -1 : l->next;
  if (!desk) l->next = (l->next + 1) % Live::N;
}

bool live_ready(Stage& s, Live* l) {
  if (!l->pending) return true;
  if (l->pending->wait(Fence::Mode::DONT_FLUSH, 0) != Fence::FenceStatus::CONDITION_SATISFIED)
    return false;
  s.engine->destroy(l->pending);
  l->pending = nullptr;
  if (l->pendingIn >= 0) l->front = l->pendingIn;
  ++l->frames;
  if (Live* desk = l->desk; desk && desk->pendingIn >= 0)
    desk->front = desk->pendingIn, desk->pendingIn = -1, ++desk->frames;
  return true;
}

void* live_front(Live* l) {
  const int i = l->front;
  return i < 0 ? nullptr : (void*)CVPixelBufferRetain(l->buffer[i]);
}

}  // namespace motolii

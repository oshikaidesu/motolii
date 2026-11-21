#include "community/after_effects_plugin/ae_plugin_fx.h"

#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Renderer.h>
#include <filament/Texture.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sstream>

namespace motolii {

using filament::RenderTarget;
using filament::Texture;
namespace backend = filament::backend;

namespace {

constexpr int kRenderTimeoutMs = 5000;

bool ensure_worker(AePluginRun& r) {
  if (r.proc.alive()) return true;
  if (!r.proc.start(ae_plugin_worker(), "--serve", r.file)) {
    r.trouble = "motolii_ae_worker failed to start";
    return false;
  }
  // Wait for the worker's 4-byte readiness banner ("AEW2").
  uint8_t magic[4] = {};
  if (!r.proc.read_all(magic, 4, kRenderTimeoutMs) ||
      std::memcmp(magic, "AEW2", 4) != 0) {
    r.trouble = "worker failed to load plugin";
    r.proc.stop();
    return false;
  }
  return true;
}

template <typename T>
void push_le(std::vector<uint8_t>& buf, T val) {
  const size_t at = buf.size();
  buf.resize(at + sizeof(T));
  std::memcpy(buf.data() + at, &val, sizeof(T));
}

void unpremultiply_rgba8(std::vector<uint8_t>& p) {
  for (size_t i = 0; i + 3 < p.size(); i += 4) {
    const uint8_t a = p[i + 3];
    if (a == 0) {
      p[i] = p[i + 1] = p[i + 2] = 0;
    } else if (a < 255) {
      p[i] = (uint8_t)std::min(255, ((int)p[i] * 255 + a / 2) / a);
      p[i + 1] = (uint8_t)std::min(255, ((int)p[i + 1] * 255 + a / 2) / a);
      p[i + 2] = (uint8_t)std::min(255, ((int)p[i + 2] * 255 + a / 2) / a);
    }
  }
}

void premultiply_rgba8(std::vector<uint8_t>& p) {
  for (size_t i = 0; i + 3 < p.size(); i += 4) {
    const uint8_t a = p[i + 3];
    if (a == 0) {
      p[i] = p[i + 1] = p[i + 2] = 0;
    } else if (a < 255) {
      p[i] = (uint8_t)(((int)p[i] * a + 127) / 255);
      p[i + 1] = (uint8_t)(((int)p[i + 1] * a + 127) / 255);
      p[i + 2] = (uint8_t)(((int)p[i + 2] * a + 127) / 255);
    }
  }
}

bool read_texture_straight(Stage& s, AePluginRun& r, Texture* src, uint32_t w,
                           uint32_t h, std::vector<uint8_t>& out) {
  if (!src || !w || !h) return false;
  if (!r.read_tex || r.read_w != w || r.read_h != h) {
    if (r.read_rt) s.engine->destroy(r.read_rt), r.read_rt = nullptr;
    if (r.read_tex) s.engine->destroy(r.read_tex), r.read_tex = nullptr;
    r.read_tex =
        Texture::Builder()
            .width(w)
            .height(h)
            .levels(1)
            .format(Texture::InternalFormat::RGBA8)
            .usage(Texture::Usage::COLOR_ATTACHMENT |
                   Texture::Usage::SAMPLEABLE | Texture::Usage::BLIT_SRC)
            .build(*s.engine);
    r.read_rt = RenderTarget::Builder()
                    .texture(RenderTarget::AttachmentPoint::COLOR, r.read_tex)
                    .build(*s.engine);
    r.read_w = w, r.read_h = h;
  }
  screen_place(s, src, r.read_rt, w, h, nullptr);
  out.assign((size_t)w * h * 4, 0);
  s.renderer->readPixels(
      r.read_rt, 0, 0, w, h,
      backend::PixelBufferDescriptor::make(
          out.data(), out.size(), backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE, [](void const*, size_t) {}));
  s.engine->flushAndWait();
  unpremultiply_rgba8(out);
  return true;
}

}  // namespace

AePluginRun::~AePluginRun() {
  proc.stop();
  if (stage && stage->engine) {
    if (read_rt) stage->engine->destroy(read_rt);
    if (read_tex) stage->engine->destroy(read_tex);
    if (out_tex) stage->engine->destroy(out_tex);
  }
}

std::shared_ptr<AePluginRun> ae_plugin_open(Stage& s,
                                            const std::string& entry) {
  auto r = std::make_shared<AePluginRun>();
  r->stage = &s;
  r->instance_id = fx_entry_id(entry);
  r->file = fx_entry_path(entry);
  r->info = ae_plugin_probe(r->file);
  if (!r->info.ok) r->trouble = "plugin probe failed: " + r->file;
  return r;
}

void ae_plugin_draw_step(Stage& s, AePluginRun& r, Texture* from,
                         RenderTarget* to, const ScreenNumbers& numbers,
                         const ScreenTextures& textures, uint32_t w,
                         uint32_t h) {
  if (!w) w = (uint32_t)s.w, h = (uint32_t)s.h;
  if (!r.info.ok || !from || !w || !h)
    return screen_place(s, from, to, w, h, nullptr);

  // During interactive editing (s.desk.w > 0), heavy CPU plugins (>16ms full
  // frame) drop to Half resolution (downsample 1/2) and upscale back with AMD
  // FSR 1.0 on the GPU. Export (s.desk.w == 0) always renders at full res.
  bool half = s.desk.w > 0 && r.use_half_preview && w >= 640 && h >= 360;
  if (const char* env = std::getenv("MOTOLII_AE_HALF")) {
    if (env[0] == '1') half = w >= 640 && h >= 360;
    else if (env[0] == '0') half = false;
  }
  const uint32_t ds_den = half ? 2u : 1u;
  const uint32_t rw = half ? std::max(1u, w / 2) : w;
  const uint32_t rh = half ? std::max(1u, h / 2) : h;

  const std::string key = r.numbers_key();
  std::ostringstream sig;
  sig << rw << "x" << rh << "/" << ds_den;

  // Serialize parameters for the worker protocol.
  std::vector<uint8_t> param_bytes;
  uint32_t sent_params = 0;
  for (const AePluginParam& p : r.info.params) {
    if (p.kind == "float" || p.kind == "fixed" || p.kind == "slider" ||
        p.kind == "angle") {
      const double v = numbers ? numbers(key, p.name, p.usual) : p.usual;
      sig << "|" << p.index << "=" << v;
      push_le<uint32_t>(param_bytes, p.index);
      if (p.kind == "float") {
        push_le<uint8_t>(param_bytes, 0);
        push_le<double>(param_bytes, v);
      } else if (p.kind == "fixed") {
        push_le<uint8_t>(param_bytes, 1);
        push_le<double>(param_bytes, v);
      } else if (p.kind == "slider") {
        push_le<uint8_t>(param_bytes, 2);
        push_le<int32_t>(param_bytes, (int32_t)std::llround(v));
      } else {
        push_le<uint8_t>(param_bytes, 3);
        push_le<double>(param_bytes, v);
      }
      ++sent_params;
    } else if (p.kind == "check") {
      const double v = numbers ? numbers(key, p.name, p.usual) : p.usual;
      const uint8_t b = v != 0.0 ? 1 : 0;
      sig << "|" << p.index << "=" << (int)b;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 4);
      push_le<uint8_t>(param_bytes, b);
      ++sent_params;
    } else if (p.kind == "popup") {
      const double v = numbers ? numbers(key, p.name, p.usual) : p.usual;
      const int32_t iv =
          (int32_t)std::clamp(std::llround(v), (long long)1,
                              (long long)std::max(1.0, p.high));
      sig << "|" << p.index << "=" << iv;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 5);
      push_le<int32_t>(param_bytes, iv);
      ++sent_params;
    } else if (p.kind == "point") {
      const double x = numbers ? numbers(key, p.name + "_x", p.x) : p.x;
      const double y = numbers ? numbers(key, p.name + "_y", p.y) : p.y;
      sig << "|" << p.index << "=" << x << "," << y;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 6);
      push_le<double>(param_bytes, x * rw);
      push_le<double>(param_bytes, y * rh);
      ++sent_params;
    } else if (p.kind == "point3d") {
      const double x = numbers ? numbers(key, p.name + "_x", p.x) : p.x;
      const double y = numbers ? numbers(key, p.name + "_y", p.y) : p.y;
      const double z = numbers ? numbers(key, p.name + "_z", p.z) : p.z;
      sig << "|" << p.index << "=" << x << "," << y << "," << z;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 7);
      push_le<double>(param_bytes, x * rw);
      push_le<double>(param_bytes, y * rh);
      push_le<double>(param_bytes, z);
      ++sent_params;
    } else if (p.kind == "color") {
      uint8_t c[4] = {p.rgba[0], p.rgba[1], p.rgba[2], p.rgba[3]};
      for (int i = 0; i < 3; ++i) {
        const double v = numbers ? numbers(key, p.name + "_" + "rgb"[i], c[i])
                                 : (double)c[i];
        c[i] = (uint8_t)std::clamp((int)std::lround(v), 0, 255);
      }
      sig << "|" << p.index << "=" << (int)c[0] << "," << (int)c[1] << ","
          << (int)c[2];
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 8);
      for (int i = 0; i < 4; ++i) push_le<uint8_t>(param_bytes, c[i]);
      ++sent_params;
    } else if (p.kind == "layer") {
      Texture* other = textures ? textures(r.file, p.name) : nullptr;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 9);
      std::vector<uint8_t> lp;
      if (other && read_texture_straight(s, r, other, rw, rh, lp)) {
        push_le<uint32_t>(param_bytes, rw);
        push_le<uint32_t>(param_bytes, rh);
        param_bytes.insert(param_bytes.end(), lp.begin(), lp.end());
      } else {
        push_le<uint32_t>(param_bytes, 0);
        push_le<uint32_t>(param_bytes, 0);
      }
      ++sent_params;
    }
  }

  const std::string cur_sig = sig.str();
  if (r.stuck && *r.stuck == cur_sig)
    return screen_place(s, from, to, w, h, nullptr);

  const auto t_start = std::chrono::steady_clock::now();
  std::vector<uint8_t> in_pixels;
  if (!read_texture_straight(s, r, from, rw, rh, in_pixels))
    return screen_place(s, from, to, w, h, nullptr);

  if (!ensure_worker(r)) {
    r.stuck = cur_sig;
    if (!r.reported) {
      std::fprintf(stderr, "AE plugin %s: %s\n", r.file.c_str(),
                   r.trouble.c_str());
      r.reported = true;
    }
    return screen_place(s, from, to, w, h, nullptr);
  }

  std::vector<uint8_t> req;
  req.reserve(32 + param_bytes.size() + in_pixels.size());
  push_le<uint32_t>(req, rw);
  push_le<uint32_t>(req, rh);
  push_le<uint32_t>(req, ds_den);
  push_le<double>(req, s.now);
  push_le<double>(req, screen_rate(s));
  push_le<uint32_t>(req, sent_params);
  req.insert(req.end(), param_bytes.begin(), param_bytes.end());
  req.insert(req.end(), in_pixels.begin(), in_pixels.end());

  const auto fail = [&](const std::string& why) {
    r.trouble = why;
    r.stuck = cur_sig;
    r.proc.stop();
    if (!r.reported) {
      std::fprintf(stderr, "AE plugin %s: %s\n", r.file.c_str(), why.c_str());
      r.reported = true;
    }
    screen_place(s, from, to, w, h, nullptr);
  };

  if (!r.proc.write_all(req.data(), req.size(), kRenderTimeoutMs))
    return fail("write to worker timed out");

  uint8_t status_b[4] = {};
  if (!r.proc.read_all(status_b, 4, kRenderTimeoutMs))
    return fail("render timed out or worker crashed");

  uint32_t status = 0;
  std::memcpy(&status, status_b, 4);
  if (status != 0) {
    uint8_t len_b[4] = {};
    uint32_t err_len = 0;
    std::string msg = "render failed";
    if (r.proc.read_all(len_b, 4, 500)) {
      std::memcpy(&err_len, len_b, 4);
      if (err_len > 0 && err_len < 4096) {
        msg.resize(err_len);
        if (!r.proc.read_all((uint8_t*)msg.data(), err_len, 500))
          msg = "render failed";
      }
    }
    return fail(msg);
  }

  uint8_t dim_b[8] = {};
  if (!r.proc.read_all(dim_b, 8, kRenderTimeoutMs))
    return fail("reading output dimensions failed");
  uint32_t ow = 0, oh = 0;
  std::memcpy(&ow, dim_b, 4);
  std::memcpy(&oh, dim_b + 4, 4);
  if (!ow || !oh || ow > 16384 || oh > 16384)
    return fail("invalid output dimensions");

  auto* out_pixels = new std::vector<uint8_t>((size_t)ow * oh * 4, 0);
  if (!r.proc.read_all(out_pixels->data(), out_pixels->size(),
                       kRenderTimeoutMs)) {
    delete out_pixels;
    return fail("reading output pixels failed");
  }
  premultiply_rgba8(*out_pixels);

  if (!r.out_tex || r.out_w != ow || r.out_h != oh) {
    if (r.out_tex) s.engine->destroy(r.out_tex), r.out_tex = nullptr;
    r.out_tex =
        Texture::Builder()
            .width(ow)
            .height(oh)
            .levels(1)
            .format(Texture::InternalFormat::RGBA8)
            .usage(Texture::Usage::SAMPLEABLE | Texture::Usage::UPLOADABLE)
            .build(*s.engine);
    r.out_w = ow, r.out_h = oh;
  }
  r.out_tex->setImage(
      *s.engine, 0,
      backend::PixelBufferDescriptor(
          out_pixels->data(), out_pixels->size(), backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE,
          [](void*, size_t, void* user) {
            delete static_cast<std::vector<uint8_t>*>(user);
          },
          out_pixels));
  if (ow < w || oh < h)
    screen_upscale(s, r.out_tex, to, w, h);
  else
    screen_place(s, r.out_tex, to, w, h, nullptr);
  if (!half && s.desk.w > 0 && !r.use_half_preview) {
    const double elapsed_ms =
        std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - t_start)
            .count();
    if (elapsed_ms > 16.0) r.use_half_preview = true;
  }
  r.stuck.reset();
}

}  // namespace motolii

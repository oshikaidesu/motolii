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
#include <cstring>
#include <filesystem>
#include <sstream>
#include <system_error>

#ifndef _WIN32
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace motolii {

using filament::RenderTarget;
using filament::Texture;
namespace backend = filament::backend;

namespace {

constexpr int kRenderTimeoutMs = 5000;

void stop_worker(AePluginRun& r) {
#ifndef _WIN32
  if (r.to_worker >= 0) close(r.to_worker), r.to_worker = -1;
  if (r.from_worker >= 0) close(r.from_worker), r.from_worker = -1;
  if (r.pid > 0) {
    kill(r.pid, SIGKILL);
    waitpid(r.pid, nullptr, 0);
    r.pid = -1;
  }
#else
  (void)r;
#endif
}

bool write_all_timed(int fd, const uint8_t* data, size_t len, int timeout_ms) {
#ifdef _WIN32
  (void)fd, (void)data, (void)len, (void)timeout_ms;
  return false;
#else
  const auto deadline = std::chrono::steady_clock::now() +
                        std::chrono::milliseconds(timeout_ms);
  size_t off = 0;
  while (off < len) {
    const auto now = std::chrono::steady_clock::now();
    if (now >= deadline) return false;
    const int rem = (int)std::chrono::duration_cast<std::chrono::milliseconds>(
                        deadline - now)
                        .count();
    struct pollfd pfd{fd, POLLOUT, 0};
    const int pr = poll(&pfd, 1, std::max(1, rem));
    if (pr <= 0) return false;
    const ssize_t n = write(fd, data + off, len - off);
    if (n > 0)
      off += (size_t)n;
    else if (n < 0 && (errno == EINTR || errno == EAGAIN))
      continue;
    else
      return false;
  }
  return true;
#endif
}

bool read_all_timed(int fd, uint8_t* data, size_t len, int timeout_ms) {
#ifdef _WIN32
  (void)fd, (void)data, (void)len, (void)timeout_ms;
  return false;
#else
  const auto deadline = std::chrono::steady_clock::now() +
                        std::chrono::milliseconds(timeout_ms);
  size_t off = 0;
  while (off < len) {
    const auto now = std::chrono::steady_clock::now();
    if (now >= deadline) return false;
    const int rem = (int)std::chrono::duration_cast<std::chrono::milliseconds>(
                        deadline - now)
                        .count();
    struct pollfd pfd{fd, POLLIN, 0};
    const int pr = poll(&pfd, 1, std::max(1, rem));
    if (pr <= 0) return false;
    const ssize_t n = read(fd, data + off, len - off);
    if (n > 0)
      off += (size_t)n;
    else if (n < 0 && (errno == EINTR || errno == EAGAIN))
      continue;
    else
      return false;
  }
  return true;
#endif
}

bool ensure_worker(AePluginRun& r) {
#ifdef _WIN32
  (void)r;
  return false;
#else
  if (r.pid > 0 && r.to_worker >= 0 && r.from_worker >= 0) return true;
  stop_worker(r);
  const std::string worker = ae_plugin_worker();
  std::error_code ec;
  if (!std::filesystem::exists(worker, ec)) {
    r.trouble = "motolii_ae_worker not found";
    return false;
  }
  int in_pipe[2], out_pipe[2];
  if (pipe(in_pipe) != 0) return false;
  if (pipe(out_pipe) != 0) {
    close(in_pipe[0]), close(in_pipe[1]);
    return false;
  }
  pid_t pid = fork();
  if (pid < 0) {
    close(in_pipe[0]), close(in_pipe[1]), close(out_pipe[0]),
        close(out_pipe[1]);
    return false;
  }
  if (pid == 0) {
    dup2(in_pipe[0], STDIN_FILENO);
    dup2(out_pipe[1], STDOUT_FILENO);
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull >= 0) {
      dup2(devnull, STDERR_FILENO);
      close(devnull);
    }
    close(in_pipe[0]), close(in_pipe[1]), close(out_pipe[0]),
        close(out_pipe[1]);
    execl(worker.c_str(), worker.c_str(), "--serve", r.file.c_str(),
          (char*)nullptr);
    _exit(127);
  }
  close(in_pipe[0]), close(out_pipe[1]);
  fcntl(in_pipe[1], F_SETFL, O_NONBLOCK);
#ifdef F_SETNOSIGPIPE
  fcntl(in_pipe[1], F_SETNOSIGPIPE, 1);
#endif
  fcntl(out_pipe[0], F_SETFL, O_NONBLOCK);
  r.pid = (int)pid;
  r.to_worker = in_pipe[1];
  r.from_worker = out_pipe[0];

  // Wait for the worker's 4-byte readiness banner ("AEW1").
  uint8_t magic[4] = {};
  if (!read_all_timed(r.from_worker, magic, 4, kRenderTimeoutMs) ||
      std::memcmp(magic, "AEW1", 4) != 0) {
    r.trouble = "worker failed to load plugin";
    stop_worker(r);
    return false;
  }
  return true;
#endif
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
  stop_worker(*this);
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

  const std::string key = r.numbers_key();
  std::ostringstream sig;
  sig << w << "x" << h;

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
      push_le<double>(param_bytes, x * w);
      push_le<double>(param_bytes, y * h);
      ++sent_params;
    } else if (p.kind == "point3d") {
      const double x = numbers ? numbers(key, p.name + "_x", p.x) : p.x;
      const double y = numbers ? numbers(key, p.name + "_y", p.y) : p.y;
      const double z = numbers ? numbers(key, p.name + "_z", p.z) : p.z;
      sig << "|" << p.index << "=" << x << "," << y << "," << z;
      push_le<uint32_t>(param_bytes, p.index);
      push_le<uint8_t>(param_bytes, 7);
      push_le<double>(param_bytes, x * w);
      push_le<double>(param_bytes, y * h);
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
      if (other && read_texture_straight(s, r, other, w, h, lp)) {
        push_le<uint32_t>(param_bytes, w);
        push_le<uint32_t>(param_bytes, h);
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

  std::vector<uint8_t> in_pixels;
  if (!read_texture_straight(s, r, from, w, h, in_pixels))
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
  req.reserve(28 + param_bytes.size() + in_pixels.size());
  push_le<uint32_t>(req, w);
  push_le<uint32_t>(req, h);
  push_le<double>(req, s.now);
  push_le<double>(req, screen_rate(s));
  push_le<uint32_t>(req, sent_params);
  req.insert(req.end(), param_bytes.begin(), param_bytes.end());
  req.insert(req.end(), in_pixels.begin(), in_pixels.end());

  const auto fail = [&](const std::string& why) {
    r.trouble = why;
    r.stuck = cur_sig;
    stop_worker(r);
    if (!r.reported) {
      std::fprintf(stderr, "AE plugin %s: %s\n", r.file.c_str(), why.c_str());
      r.reported = true;
    }
    screen_place(s, from, to, w, h, nullptr);
  };

  if (!write_all_timed(r.to_worker, req.data(), req.size(), kRenderTimeoutMs))
    return fail("write to worker timed out");

  uint8_t status_b[4] = {};
  if (!read_all_timed(r.from_worker, status_b, 4, kRenderTimeoutMs))
    return fail("render timed out or worker crashed");

  uint32_t status = 0;
  std::memcpy(&status, status_b, 4);
  if (status != 0) {
    uint8_t len_b[4] = {};
    uint32_t err_len = 0;
    std::string msg = "render failed";
    if (read_all_timed(r.from_worker, len_b, 4, 500)) {
      std::memcpy(&err_len, len_b, 4);
      if (err_len > 0 && err_len < 4096) {
        msg.resize(err_len);
        if (!read_all_timed(r.from_worker, (uint8_t*)msg.data(), err_len, 500))
          msg = "render failed";
      }
    }
    return fail(msg);
  }

  uint8_t dim_b[8] = {};
  if (!read_all_timed(r.from_worker, dim_b, 8, kRenderTimeoutMs))
    return fail("reading output dimensions failed");
  uint32_t ow = 0, oh = 0;
  std::memcpy(&ow, dim_b, 4);
  std::memcpy(&oh, dim_b + 4, 4);
  if (!ow || !oh || ow > 16384 || oh > 16384)
    return fail("invalid output dimensions");

  auto* out_pixels = new std::vector<uint8_t>((size_t)ow * oh * 4, 0);
  if (!read_all_timed(r.from_worker, out_pixels->data(), out_pixels->size(),
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
  screen_place(s, r.out_tex, to, w, h, nullptr);
  r.stuck.reset();
}

}  // namespace motolii

#include "stage/render/render_draw.h"

#include <filament/Engine.h>
#include <filament/InstanceBuffer.h>
#include <filament/TransformManager.h>
#include <filament/View.h>
#include <math/mat4.h>

#include <algorithm>
#include <cmath>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <functional>
#include <string>
#include <vector>

#include "base/video_encoder.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::View;
using filament::math::mat4f;

void move(Stage& s, const Mesh* m,
          const std::function<mat4f(int, const mat4f&)>& to, const mat4f* eye) {
  auto& tm = s.engine->getTransformManager();
  for (const Stage::Renderable& d : s.renderables) {
    if (d.of != m) continue;
    if (!d.many) {
      tm.setTransform(tm.getInstance(d.thing), to(d.nth, d.place));
      continue;
    }
    // A group drawn in one call: all its transforms are computed and set
    // together.
    std::vector<mat4f> all((size_t)d.count);
    for (int k = 0; k < d.count; ++k) all[(size_t)k] = to(d.nth + k, d.place);
    if (eye)
      std::stable_sort(all.begin(), all.end(),
                       [eye](const mat4f& a, const mat4f& b) {
                         return (*eye * a[3]).z < (*eye * b[3]).z;
                       });
    d.many->setLocalTransforms(all.data(), all.size());
  }
}

bool film(Stage& s, const char* path, int frameCount,
          const std::function<void(double)>& pose, const FilmWay& said) {
  // Quotes a file name for the shell.
  const auto quoted = [](std::string name) {
    for (size_t at = 0; (at = name.find('\'', at)) != std::string::npos;
         at += 4)
      name.replace(at, 1, "'\\''");
    return "'" + name + "'";
  };
  std::string files, each, all;
  int n = 0;
  for (const auto& [who, tells] : s.sounding) {
    const Stage::Sound a = tells();
    const double fast = std::fabs(a.speed);
    // Volume automation as ffmpeg asendcmd commands, one every 1/30 s, counted
    // from when the sound starts.
    std::string loud;
    for (size_t i = 0; i < a.loud.size(); ++i)
      if (i == 0 || a.loud[i] != a.loud[i - 1])
        loud += (loud.empty() ? "" : ";") + std::to_string(i / 30.0) +
                " volume@v" + std::to_string(n + 1) + " volume " +
                std::to_string(a.loud[i]);
    // ffmpeg's atempo cannot go below 0.5 in one step, so chain several.
    std::string halved;
    double left = fast;
    for (; left < 0.5; left /= 0.5) halved += "atempo=0.5,";
    // Room for the volume commands.
    std::vector<char> how(700 + loud.size());
    std::snprintf(
        how.data(), how.size(),
        "[%d:a]aresample=48000,atrim=start=%g:end=%g,asetpts=PTS-STARTPTS,%s%"
        "satempo=%g,aloop=loop=-1:size=%ld,atrim=start=%g%s%s,asetpts=PTS-"
        "STARTPTS,%svolume@v%d=%g,adelay=delays=%ld:all=1[a%d];",
        n + 1, a.from, a.to, a.speed < 0.0 ? "areverse," : "", halved.c_str(),
        left, std::lround((a.to - a.from) / fast * 48000.0), a.into,
        a.lasts < 0.0 ? "" : ":duration=",
        a.lasts < 0.0 ? "" : std::to_string(a.lasts).c_str(),
        loud.empty() ? "" : ("asendcmd=c='" + loud + "',").c_str(), n + 1,
        a.loud.empty() ? a.gain : a.loud[0], std::lround(a.on * 1000.0), n + 1);
    files += " -i " + quoted(a.file);
    each += how.data();
    all += "[a" + std::to_string(++n) + "]";
  }
  const std::string ending = std::filesystem::path(path).extension().string();
  const std::string h264 = ending == ".mp4" ? h264_encoder_here() : "";
  if (ending == ".mp4" && h264.empty()) {
    std::fprintf(stderr, "film: this ffmpeg lists no H.264 encoder\n");
    return false;
  }
  const bool silent = ending == ".gif" || ending == ".png" || ending == ".jpg";
  const std::string sound =
      n && !silent ? files + " -filter_complex \"" + each + all +
                         "amix=inputs=" + std::to_string(n) +
                         ":normalize=0:duration=longest,alimiter[a]\" -map 0:v "
                         "-map '[a]' -c:a aac -b:a 160k -t " +
                         std::to_string(frameCount / 60.0)
                   : "";
  const std::string scale = said.high > 0
                                ? "scale=-2:" + std::to_string(said.high) +
                                      ":flags=lanczos"
                                : "",
                    mbps = std::to_string(said.mbps) + "M";
  const std::string sized = scale.empty() || ending == ".gif" ? ""
                                                              : " -vf " + scale,
                    rate = said.rate > 0 && ending != ".gif"
                               ? " -r " + std::to_string(said.rate)
                               : "";
  // Output arguments for each format. JPEG uses -q:v 2, which is nearly the
  // best quality.
  const std::string way =
      ending == ".gif"
          ? " -an -vf \"fps=15," + (scale.empty() ? "" : scale + ",") +
                "split[a][b];[a]palettegen[p];[b][p]paletteuse\" " +
                quoted(path)
      : ending == ".png"
          ? " -an" + sized + rate + " -c:v png " +
                quoted(
                    std::filesystem::path(path).replace_extension().string() +
                    "_%04d.png")
      : ending == ".jpg"
          ? " -an" + sized + rate + " -c:v mjpeg -q:v 2 -pix_fmt yuvj420p " +
                quoted(
                    std::filesystem::path(path).replace_extension().string() +
                    "_%04d.jpg")
      : ending == ".mov"
          ? sized + rate + " -c:v hevc_videotoolbox " +
                (said.mbps > 0.0 ? "-b:v " + mbps : std::string("-q:v 65")) +
                (said.alpha ? " -alpha_quality 0.75 -pix_fmt bgra"
                            : " -pix_fmt yuv420p") +
                " -tag:v hvc1 -movflags +faststart " + quoted(path)
          // H.264 by whichever encoder the LGPL-only ffmpeg has (base/video_encoder.h). On a Mac that is VideoToolbox,
          // whose -q:v 68 is within 1 VMAF point of libx264 -crf 17 (95.9 against 96.2 on 180 frames of a photo
          // moving, 95.8 against 96.7 on one standing still; 2 points are not told apart, ottverse.com's study of
          // VMAF 95), in a file 0.7 to 2.8 times as large.
          : sized + rate + " -c:v " + h264 + h264_quality(h264, said.mbps) +
                "-g 60 -pix_fmt yuv420p -movflags +faststart " + quoted(path);
  const std::string cmd =
      "ffmpeg -loglevel error -y -f rawvideo -pix_fmt rgba -s " +
      std::to_string(s.w) + "x" + std::to_string(s.h) + " -r 60 -i -" + sound +
      way;
  // If ffmpeg gives up, writing to it fails and is reported by the return value
  // instead of SIGPIPE ending this program.
  std::signal(SIGPIPE, SIG_IGN);
  FILE* to = popen(cmd.c_str(), "w");
  if (!to) return false;
  std::vector<uint8_t> pic((size_t)s.w * s.h * 4);
  s.by_clock = false;
  // Filament keeps the alpha channel through post-processing only in
  // translucent mode (see View.h).
  if (said.alpha) s.view->setBlendMode(View::BlendMode::TRANSLUCENT);
  const int samples = std::max(1, said.blur);
  std::vector<uint32_t> sum(samples > 1 ? pic.size() : 0);
  for (int i = 0; i < frameCount; ++i) {
    if (samples > 1) std::fill(sum.begin(), sum.end(), 0u);
    for (int k = 0; k < samples; ++k) {
      // Time of this sample: the frame itself, or one of several around it for
      // motion blur.
      const double at =
          samples > 1 ? std::max(0.0, i + 0.5 * ((k + 0.5) / samples - 0.5))
                      : (double)i;
      time_is(s, at / 60.0);
      pose(at / frameCount);
      draw(s, &pic);
      if (samples > 1)
        for (size_t j = 0; j < pic.size(); ++j) sum[j] += pic[j];
    }
    if (samples > 1)
      for (size_t j = 0; j < pic.size(); ++j)
        pic[j] = (uint8_t)((sum[j] + samples / 2) / samples);
    // Convert from premultiplied alpha, which Filament produces, to straight
    // alpha, which ffmpeg's rgba format expects.
    if (said.alpha)
      for (size_t j = 0; j < pic.size(); j += 4)
        if (const int a = pic[j + 3]; a > 0 && a < 255)
          for (int c = 0; c < 3; ++c)
            pic[j + c] = (uint8_t)std::min(255, (pic[j + c] * 255 + a / 2) / a);
    if (std::fwrite(pic.data(), 1, pic.size(), to) != pic.size()) break;
  }
  if (said.alpha) s.view->setBlendMode(View::BlendMode::OPAQUE);
  return pclose(to) == 0;
}

}  // namespace motolii

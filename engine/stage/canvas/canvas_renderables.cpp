// Putting a ThorVG drawing on the stage: the texture, the sheet that shows it,
// and the images and animations that are drawn into it.
#include "stage/canvas/canvas_renderables.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <thorvg.h>
#include <thorvg_lottie.h>
#include <webgpu/webgpu.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iterator>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "base/file_read.h"
#include "community/css/svg.h"
#include "gpu/gpu_interop.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Texture;
using filament::TextureSampler;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// Returns the first frame of a Lottie file, which is the "ip" key at the top
// level of the file. ThorVG does not report it.
float lottie_in(const char* file) {
  const std::string all = read_text(file);
  int depth = 0;
  bool quoted = false;
  // Look only at the key at the outermost depth, because each layer has its
  // own.
  for (size_t i = 0; i < all.size(); ++i) {
    const char c = all[i];
    if (quoted) {
      if (c == '\\')
        ++i;
      else if (c == '"')
        quoted = false;
      continue;
    }
    if (c == '"') {
      if (depth == 1 && all.compare(i, 4, "\"ip\"") == 0) {
        const size_t colon = all.find(':', i + 4);
        return colon == std::string::npos
                   ? 0.f
                   : std::strtof(all.c_str() + colon + 1, nullptr);
      }
      quoted = true;
    } else if (c == '{' || c == '[')
      ++depth;
    else if (c == '}' || c == ']')
      --depth;
  }
  return 0.f;
}

}  // namespace

Canvas2D* place_canvas(
    Stage& s, const std::function<tvg::Paint*(Canvas2D*, int*, int*)>& paints,
    const mat4f& place, float high, float3 ground, bool shown, const char* lay,
    const Canvas2DFx& fx) {
  // Return nullptr when the engine runs on another backend.
  if (!interop::device(s.engine)) return nullptr;
  Canvas2D* d = new Canvas2D;
  WGPUTexture built = nullptr;
  tvg::Paint* loose = nullptr;
  bool owned = false;
  int w = 0, h = 0;
  float own = high;
  // Everything that touches ThorVG or the GPU device runs on the driver thread.
  interop::on_driver(s.engine, [&] {
    tvg::Initializer::init(0);
    tvg::Paint* p = paints(d, &w, &h);
    if (!p || w <= 0 || h <= 0) return;
    // Scale the sheet for multi-line text, so that `high` stays the height of
    // one line.
    high *= d->tallBy, own = high;
    // Fit the image around the bent outline. A path operator can push the
    // outline past its plain box -- an offset outward, a bloat on a lopsided
    // letter, a zigzag. Bend a copy of the plain path by the operators at their
    // largest, measure how far it reaches past the plain outline on any side,
    // and grow the image by that much all round so the bend is never cut by the
    // box. The content keeps its size and stays centered, so the layer does not
    // shift. Shapes with no path of their own (images, films) are left as they
    // are.
    if (!d->plain.empty() &&
        (fx.round != 0.f || fx.bloat != 0.f || fx.zigzag != 0.f ||
         fx.offset != 0.f)) {
      const float plainHigh = d->plainHigh, side = d->plainSide;
      tvg::Shape* probe = tvg::Shape::gen();
      float px, py, pw, ph, bx, by, bw, bh;
      // The plain outline, unbent, as the image was sized to hold.
      tvg_bend(probe, d->plain.data(), (uint32_t)d->plain.size(),
               d->plainAt.data(), (uint32_t)d->plainAt.size(), 0.f, 0.f, 0.f, 0,
               false, 0.f, d->fine);
      const bool okP = probe->bounds(&px, &py, &pw, &ph) == tvg::Result::Success;
      // The same outline bent by the operators at their largest, with the clamps
      // bend_at uses, so the margin matches what is actually drawn.
      tvg_bend(probe, d->plain.data(), (uint32_t)d->plain.size(),
               d->plainAt.data(), (uint32_t)d->plainAt.size(),
               std::clamp(fx.round, 0.f, 0.5f) * side,
               100.f * std::clamp(fx.bloat, -1.f, 1.f),
               std::clamp(fx.zigzag, -4.f, 4.f) * plainHigh,
               (int)std::clamp(fx.ridges, 0.f, 100.f), fx.smooth > 0.5f,
               std::clamp(fx.offset, -4.f, 4.f) * plainHigh, d->fine);
      const bool okB = probe->bounds(&bx, &by, &bw, &bh) == tvg::Result::Success;
      if (okP && okB) {
        const float over = std::max({0.f, px - bx, (bx + bw) - (px + pw),
                                     py - by, (by + bh) - (py + ph)});
        // Add headroom so a steady path-operator drag does not clip and rebuild
        // the sheet every frame. The grabbed box stays tight regardless, because
        // it is measured from the outline (canvas_measure_bent), not this sheet.
        if (const float room =
                over > 0.f ? std::ceil(1.25f * over + 0.03f * std::max(pw, ph))
                           : 0.f;
            room > 0.f) {
          p->translate(room, room);
          // Enlarge the sheet by the same ratio as the texture, so the content
          // keeps its size.
          high *= ((float)h + 2.f * room) / (float)h;
          w += 2 * (int)room, h += 2 * (int)room;
        }
      }
      tvg::Paint::rel(probe);
    }
    d->canvasHigh = (float)h, d->canvasWide = (float)w;
    // Limit the texture to 4096 points on its longer side, which leaves room to
    // spare on the device. The drawing is scaled down and the sheet keeps its
    // size.
    if (const float most = (float)std::max(w, h); most > 4096.f) {
      tvg::Scene* smaller = tvg::Scene::gen();
      smaller->add(p);
      smaller->scale(4096.f / most);
      p = smaller;
      w = std::max(2, (int)std::floor((float)w * 4096.f / most)),
      h = std::max(2, (int)std::floor((float)h * 4096.f / most));
    }
    // If no animation owns the paint, release it here in case the canvas never
    // takes it.
    loose = d->film ? nullptr : p;
    WGPUTextureDescriptor like{};
    like.size = {(uint32_t)w, (uint32_t)h, 1};
    // ThorVG's last step writes BGRA.
    like.format = WGPUTextureFormat_BGRA8Unorm;
    // CopyDst: frames cached on disk are uploaded into the texture.
    like.usage = WGPUTextureUsage_RenderAttachment |
                 WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc |
                 WGPUTextureUsage_CopyDst;
    like.dimension = WGPUTextureDimension_2D;
    like.mipLevelCount = 1;
    like.sampleCount = 1;
    built =
        wgpuDeviceCreateTexture((WGPUDevice)interop::device(s.engine), &like);
    d->target = built;
    d->canvas = tvg::WgCanvas::gen();
    if (!d->canvas ||
        d->canvas->target(interop::device(s.engine),
                          interop::instance(s.engine), built, (uint32_t)w,
                          (uint32_t)h, tvg::ColorSpace::ABGR8888S,
                          1) != tvg::Result::Success)
      return;
    if (ground.x >= 0.f) {
      tvg::Shape* under = tvg::Shape::gen();
      under->appendRect(0, 0, (float)w, (float)h);
      under->fill(byte_of(ground.x), byte_of(ground.y), byte_of(ground.z), 255);
      d->canvas->add(under);
    }
    d->canvas->add(p);
    owned = true;
    if (d->film)
      d->frames = d->film->totalFrame(), d->seconds = d->film->duration();
    // If a marker selects a range, play only that range: scale the duration to
    // match.
    if (d->film && d->toFrame > d->fromFrame && d->frames > 0.f)
      d->seconds *= (d->toFrame - d->fromFrame) / d->frames,
          d->frames = d->toFrame - d->fromFrame;
    d->canvas->update();
    d->canvas->draw(true);
    d->canvas->sync();
    // The outline's own bounds, for the grabbed box. The shape is still plain
    // here (round apart); bend_at measures again once a path operator is on.
    canvas_measure_bent(s, d);
  });
  // Wait once at setup, because the code above ran on the driver thread.
  s.engine->flushAndWait();
  // Setup failed: release whatever was created.
  if (!built || !owned) {
    interop::on_driver(s.engine, [&] {
      if (loose) tvg::Paint::rel(loose);
      delete d->canvas;
      delete d->film;
      if (built) wgpuTextureRelease(built);
    });
    s.engine->flushAndWait();
    delete d;
    return nullptr;
  }
  d->texture = Texture::Builder()
                   .width((uint32_t)w)
                   .height((uint32_t)h)
                   .levels(1)
                   .sampler(Texture::Sampler::SAMPLER_2D)
                   .format(Texture::InternalFormat::RGBA8)
                   .usage(Texture::Usage::SAMPLEABLE)
                   .import((intptr_t)built)
                   .build(*s.engine);
  // The sheet is a quad centered on the origin whose width follows the
  // texture's aspect ratio.
  d->sheet = new Mesh;
  for (float2 c :
       {float2{-1, -1}, float2{1, -1}, float2{1, 1}, float2{-1, 1}}) {
    d->sheet->pos.push_back(
        {0.5f * high * (float)w / (float)h * c.x, 0.5f * high * c.y, 0.f});
    d->sheet->nrm.push_back({0, 0, 1});
    d->sheet->uv.push_back(c * 0.5f + 0.5f);
  }
  d->sheet->idx = {0, 1, 2, 0, 2, 3};
  // Give the sheet depth: a fifth of its height in total. This is the depth
  // that shelves/solids/Raster_Extrude.js gives at Scale Z 1.
  if (fx.thick)
    sheet_deep(d->sheet, 0.1f * own),
        d->boxed = float3{d->sheet->pos[1].x, d->sheet->pos[2].y, 0.1f * own};
  // An animation advances by itself with the stage's time and loops.
  if (d->frames > 1.f)
    s.playing[d] = [&s, d](double now) {
      canvas_at(s, d, std::fmod((float)now + d->starts, d->seconds));
    };
  if (!shown) return d;
  d->inLight = fx.lit;
  // When the text is split into letters, there is one copy per letter.
  d->look =
      add(s, d->sheet, flat_laid(lay, fx.lit, fx.wear).c_str(),
          std::vector<mat4f>(
              (size_t)std::max(
                  1, d->letters.empty() ? fx.copies : (int)d->letters.size()),
              place),
          1, fx.lit, 1, 4, fx.together && d->letters.empty());
  if (!d->look) return nullptr;
  d->look->setParameter("picture", d->texture,
                        TextureSampler(TextureSampler::MinFilter::LINEAR,
                                       TextureSampler::MagFilter::LINEAR));
  if (fx.thick)
    d->look->setParameter("deep", float4{d->boxed, 0.f}),
        d->look->setParameter("deepTurn", float4{1.f, 0.f, 0.f, 1.f});
  if (fx.bevel)
    edge_make(s, d, (uint32_t)w, (uint32_t)h),
        d->look->setParameter(
            "edge", d->edge[2],
            TextureSampler(TextureSampler::MinFilter::LINEAR,
                           TextureSampler::MagFilter::LINEAR));
  return d;
}

Canvas2D* image_canvas(Stage& s, const char* file, const mat4f& place,
                       float high, float3 ground, bool shown, const char* lay,
                       const Canvas2DFx& fx, const char* marker) {
  // ThorVG ends the program when given a folder, so accept regular files only.
  if (!std::filesystem::is_regular_file(file)) return nullptr;
  const std::string ext = std::filesystem::path(file).extension().string();
  const bool lottie = ext == ".json" || ext == ".lot";
  std::string text;
  if (ext == ".svg") text = read_text(file);
  Canvas2D* built = place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        // An SVG moved by CSS @keyframes, which ThorVG does not run: Blitz
        // plays its CSS and writes the SVG again for each frame
        // (community/css/svg.h). It lasts ten minutes at 60 frames a second,
        // as a sketch does.
        if (text.find("@keyframes") != std::string::npos) {
          std::shared_ptr<MotoliiSvg> svg(motolii_svg_new(text.c_str()),
                                          motolii_svg_free);
          tvg::Picture* first = tvg::Picture::gen();
          float fw = 0.f, fh = 0.f;
          const bool read = svg && first->load(file) == tvg::Result::Success &&
                            first->size(&fw, &fh) == tvg::Result::Success &&
                            fw > 0.f && fh > 0.f;
          tvg::Paint::rel(first);
          if (read) {
            const float fit = (float)std::max(s.w, s.h) / std::max(fw, fh);
            *w = 2 * (int)std::lround(0.5f * fw * fit);
            *h = 2 * (int)std::lround(0.5f * fh * fit);
            tvg::Scene* scene = tvg::Scene::gen();
            d->redraw = [svg, scene, w = (float)*w, h = (float)*h](int at) {
              scene->remove();
              const char* now = motolii_svg_at(svg.get(), at / 60.0);
              tvg::Picture* one = tvg::Picture::gen();
              if (now && one->load(now, (uint32_t)std::strlen(now), "svg",
                                   nullptr, true) == tvg::Result::Success)
                one->size(w, h), scene->add(one);
              else
                tvg::Paint::rel(one);
            };
            d->redraw(0);
            d->frames = 36000.f, d->seconds = 600.f;
            return scene;
          }
        }
        tvg::LottieAnimation* own =
            lottie ? tvg::LottieAnimation::gen() : nullptr;
        d->film = own ? own : tvg::Animation::gen();
        d->lottie = own;
        tvg::Picture* p = d->film->picture();
        float fw = 0.f, fh = 0.f;
        if (p->load(file) != tvg::Result::Success ||
            p->size(&fw, &fh) != tvg::Result::Success || fw <= 0.f || fh <= 0.f)
          return nullptr;
        const float first = lottie ? lottie_in(file) : 0.f;
        // Where each named range begins. A range of zero length runs to the
        // next start, or to the end.
        std::vector<float> starts;
        for (uint32_t i = 0; own && i < own->markersCnt(); ++i) {
          float from = 0.f, to = 0.f;
          if (own->marker(i, &from, &to)) starts.push_back(from);
        }
        // Read each marker's name and pick the one to play.
        for (uint32_t i = 0; own && i < own->markersCnt(); ++i) {
          float from = 0.f, to = 0.f;
          const char* name = own->marker(i, &from, &to);
          if (!name || !*name) continue;
          std::string word(name);
          // A name is one word: strip whitespace, so "End\r\n" becomes "End".
          word.erase(std::remove_if(
                         word.begin(), word.end(),
                         [](char c) { return std::isspace((unsigned char)c); }),
                     word.end());
          d->markers.push_back(word);
          // A marker with no length runs to the next marker or to the end.
          if (to <= from) {
            to = 1e9f;
            for (float b : starts)
              if (b > from) to = std::min(to, b);
          }
          // A marker counts the file's own frames, which begin at its in point.
          // ThorVG counts from 0.
          if (marker && *marker && word == marker)
            d->fromFrame = from - first,
            d->toFrame = std::min(to - first, d->film->totalFrame());
        }
        const float fit = (float)std::max(s.w, s.h) / std::max(fw, fh);
        *w = 2 * (int)std::lround(0.5f * fw * fit);
        *h = 2 * (int)std::lround(0.5f * fh * fit);
        p->size((float)*w, (float)*h);
        return p;
      },
      place, high, ground, shown, lay, fx);
  // Frames cached on disk are identified by the file's path, size and
  // modification time. See cache_file.
  if (built && built->frames > 1.f) {
    std::error_code e;
    built->keyBase =
        std::filesystem::absolute(file, e).string() + "|" +
        std::to_string(std::filesystem::file_size(file, e)) + "|" +
        std::to_string((long long)std::filesystem::last_write_time(file, e)
                           .time_since_epoch()
                           .count());
  }
  return built;
}

float canvas_aspect(Stage& s, const char* file) {
  float pw = 0.f, ph = 0.f;
  interop::on_driver(s.engine, [&] {
    tvg::Initializer::init(0);
    tvg::Picture* pic = tvg::Picture::gen();
    if (pic->load(file) == tvg::Result::Success) pic->size(&pw, &ph);
    tvg::Paint::rel(pic);
  });
  s.engine->flushAndWait();
  return ph > 0.f ? pw / ph : 0.f;
}

}  // namespace motolii

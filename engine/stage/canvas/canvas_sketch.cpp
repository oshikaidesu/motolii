#include "stage/canvas/canvas_sketch.h"

#include <math/mat4.h>
#include <math/vec3.h>
#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "community/quickjs/script.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/render/render_stage.h"

using namespace filament::math;

namespace {

// Creates a ThorVG gradient from the `many` numbers at `g`, which p5_stand.h
// writes for a canvas gradient. g[0] is 1 for a linear gradient and anything
// else for a radial one. g[1..6] hold the geometry. The color stops follow from
// g[7] on, five numbers per stop: offset, red, green, blue and alpha. The
// caller takes ownership of the result.
tvg::Fill* sketch_ramp(const double* g, size_t many) {
  std::vector<tvg::Fill::ColorStop> stops;
  for (size_t i = 7; i + 5 <= many; i += 5)
    stops.push_back({(float)g[i], (uint8_t)std::lround(g[i + 1]),
                     (uint8_t)std::lround(g[i + 2]),
                     (uint8_t)std::lround(g[i + 3]),
                     (uint8_t)std::lround(g[i + 4])});
  tvg::Fill* out;
  if (g[0] == 1.0) {
    auto* l = tvg::LinearGradient::gen();
    l->linear((float)g[1], (float)g[2], (float)g[4], (float)g[5]);
    out = l;
  } else {
    auto* r = tvg::RadialGradient::gen();
    r->radial((float)g[4], (float)g[5], (float)g[6], (float)g[1], (float)g[2],
              (float)g[3]);
    out = r;
  }
  out->colorStops(stops.data(), (uint32_t)stops.size());
  return out;
}

// Creates a ThorVG text paint for a text command. `p` is the command header and
// `q` the first number after it: the six numbers of the transform matrix, then
// the code points in [q + 6, end). The result is aligned according to the
// textAlign and textBaseline values in the header.
tvg::Paint* sketch_words(Canvas2D* d, const double* p, const double* q,
                         const double* end) {
  // The text encoded as UTF-8.
  std::string words;
  for (const double* c = q + 6; c < end; ++c) {
    const uint32_t u = (uint32_t)*c;
    if (u < 0x80)
      words += (char)u;
    else if (u < 0x800)
      words += (char)(0xC0 | u >> 6), words += (char)(0x80 | (u & 63));
    else if (u < 0x10000)
      words += (char)(0xE0 | u >> 12), words += (char)(0x80 | (u >> 6 & 63)),
          words += (char)(0x80 | (u & 63));
    else
      words += (char)(0xF0 | u >> 18), words += (char)(0x80 | (u >> 12 & 63)),
          words += (char)(0x80 | (u >> 6 & 63)),
          words += (char)(0x80 | (u & 63));
  }
  tvg::Text* t = tvg::Text::gen();
  t->font(d->sketchFont.c_str());
  t->size((float)p[6]);
  t->text(words.c_str());
  t->fill((uint8_t)std::lround(p[1]), (uint8_t)std::lround(p[2]),
          (uint8_t)std::lround(p[3]));
  t->opacity((uint8_t)std::lround(p[4]));
  tvg::TextMetrics m{};
  t->metrics(m);
  float x = 0.f, y = 0.f, w = 0.f, h = 0.f;
  t->bounds(&x, &y, &w, &h);
  const float across = p[7] == 1.0 ? -0.5f * w : p[7] == 2.0 ? -w : 0.f;
  // ThorVG places text with its top at the origin, so the baseline modes shift
  // it by the font metrics.
  const float down = p[8] == 1.0   ? 0.f
                     : p[8] == 2.0 ? -0.5f * (m.ascent - m.descent)
                     : p[8] == 3.0 ? -(m.ascent - m.descent)
                                   : -m.ascent;
  t->transform(tvg::Matrix{
      (float)q[0], (float)q[2], (float)(q[4] + q[0] * across + q[2] * down),
      (float)q[1], (float)q[3], (float)(q[5] + q[1] * across + q[3] * down),
      0.f, 0.f, 1.f});
  return t;
}

// Creates a ThorVG picture for a bitmap command (kind 4 in p5_stand.h). The
// numbers at `q` are the transform matrix in q[0..5], the bitmap id in q[6],
// the bitmap size in q[7..8], the source rectangle x, y, width, height in
// q[9..12], and q[13], which is nonzero to disable smoothing. The pixels are
// shared with Canvas2D::sketchPics, and a reference is added to `held` so that
// they stay alive until ThorVG has drawn. Returns null if the bitmap is unknown
// or has the wrong size.
tvg::Paint* sketch_bitmap(
    Canvas2D* d, const double* p, const double* q,
    std::vector<std::shared_ptr<std::vector<uint8_t>>>& held) {
  std::lock_guard<std::mutex> hold(d->sketchPicsLock);
  const auto pic = d->sketchPics.find((int)q[6]);
  const uint32_t w = (uint32_t)q[7], h = (uint32_t)q[8];
  if (pic == d->sketchPics.end() || pic->second->size() != 4ull * w * h)
    return nullptr;
  held.push_back(pic->second);
  tvg::Picture* one = tvg::Picture::gen();
  if (q[13] != 0.0) one->filter(tvg::FilterMethod::Nearest);
  one->load((const uint32_t*)pic->second->data(), w, h,
            tvg::ColorSpace::ABGR8888S, false);
  const tvg::Matrix at{(float)q[0], (float)q[2], (float)q[4],
                       (float)q[1], (float)q[3], (float)q[5],
                       0.f,         0.f,         1.f};
  one->transform(at), one->opacity((uint8_t)std::lround(p[4]));
  if (q[9] > 0.0 || q[10] > 0.0 || q[11] < q[7] || q[12] < q[8]) {
    tvg::Shape* part = tvg::Shape::gen();
    part->appendRect((float)q[9], (float)q[10], (float)q[11], (float)q[12]),
        part->fill(255, 255, 255), part->transform(at), one->clip(part);
  }
  return one;
}

// Creates a conic gradient, which ThorVG does not support. As the canvas
// specification defines it, each point takes its color from its angle around a
// center, measured from a start ray. The gradient is rendered into a bitmap the
// size of the shape's bounds, at most 1024 by 1024, and the shape clips the
// bitmap. Colors come from a table of 1024 entries computed once from the color
// stops instead of from the stops for each pixel. `g` has the layout described
// at sketch_ramp, with the 2 by 2 matrix in g[1..4] and the center in g[5..6].
// The bitmap is added to `held`. Returns the shape itself if the matrix cannot
// be inverted.
tvg::Paint* sketch_conic(
    tvg::Shape* shape, const double* g, size_t many,
    std::vector<std::shared_ptr<std::vector<uint8_t>>>& held) {
  float bx = 0.f, by = 0.f, bw = 0.f, bh = 0.f;
  shape->bounds(&bx, &by, &bw, &bh);
  const int W = std::clamp((int)std::ceil(bw), 1, 1024),
            H = std::clamp((int)std::ceil(bh), 1, 1024);
  const double det = g[1] * g[4] - g[2] * g[3];
  if (det == 0.0) return shape;
  uint32_t ramp[1024];
  for (int i = 0; i < 1024; ++i) {
    const double t = (i + 0.5) / 1024.0;
    size_t b = 7;
    while (b + 5 < many && g[b + 5] <= t) b += 5;
    const size_t c = b + 5 < many ? b + 5 : b;
    const double f = c == b || t <= g[b] ? 0.0 : (t - g[b]) / (g[c] - g[b]);
    uint32_t out = 0;
    for (int k = 3; k >= 0; --k)
      out = out << 8 | (uint32_t)std::lround(g[b + 1 + k] +
                                             f * (g[c + 1 + k] - g[b + 1 + k]));
    ramp[i] = out;
  }
  auto pic = std::make_shared<std::vector<uint8_t>>(4ull * W * H);
  uint32_t* to = (uint32_t*)pic->data();
  for (int y = 0; y < H; ++y)
    for (int x = 0; x < W; ++x) {
      const double dx = bx + (x + 0.5) * bw / W - g[5],
                   dy = by + (y + 0.5) * bh / H - g[6];
      double t = std::atan2((g[1] * dy - g[2] * dx) / det,
                            (g[4] * dx - g[3] * dy) / det) /
                 (2.0 * M_PI);
      if (t < 0.0) t += 1.0;
      *to++ = ramp[std::min(1023, (int)(t * 1024.0))];
    }
  held.push_back(pic);
  tvg::Picture* out = tvg::Picture::gen();
  out->load((const uint32_t*)pic->data(), W, H, tvg::ColorSpace::ABGR8888S,
            false);
  out->transform(tvg::Matrix{bw / W, 0.f, bx, 0.f, bh / H, by, 0.f, 0.f, 1.f});
  out->clip(shape);
  return out;
}

// Fetches from the script the bitmaps that the commands in `o` draw and that
// are not cached yet. At most 64 bitmaps are cached, and the oldest is dropped
// first. This runs while the script can still be asked for bitmap data.
void sketch_bitmaps(Canvas2D* d, Script* run, const std::vector<double>& o) {
  for (size_t i = 1; i + 12 <= o.size();
       i += 12 + (size_t)o[i + 9] + (size_t)o[i + 10]) {
    if (o[i] != 4.0) continue;
    const int id = (int)o[i + 18];
    std::lock_guard<std::mutex> hold(d->sketchPicsLock);
    if (d->sketchPics.count(id)) continue;
    auto pic = std::make_shared<std::vector<uint8_t>>(
        run->bytes("__bitmap(" + std::to_string(id) + ")"));
    if (d->sketchPics.size() >= 64) d->sketchPics.erase(d->sketchPics.begin());
    d->sketchPics[id] = std::move(pic);
  }
}

}  // namespace

void sketch_draw(Canvas2D* d, const std::vector<double>& o) {
  if (o.empty()) return;
  d->sketchScene->remove();
  bool wipe = o[0] != 0.0;
  // Bitmap pixels that ThorVG reads in place, so they must stay alive until it
  // has drawn.
  std::vector<std::shared_ptr<std::vector<uint8_t>>> pics;
  // Draws what has been collected so far and empties the scene. A sketch can
  // paint very many shapes in one frame, for example when it replays a whole
  // painting from the start. Metal's command buffers hold a limited number of
  // commands and the program stops if that is exceeded, so the work is
  // submitted in batches.
  const auto out_now = [&] {
    d->canvas->update();
    d->canvas->draw(wipe), d->stale = true, wipe = false;
    d->canvas->sync();
    d->sketchScene->remove();
    pics.clear();
  };
  int held = 0;
  for (size_t i = 1; i + 12 <= o.size();) {
    const double* p = &o[i];
    const size_t n = (size_t)p[9], more = (size_t)p[10];
    const double *q = p + 12, *end = q + n;
    tvg::Paint* out;
    if (p[0] == 3.0)
      out = sketch_words(d, p, q, end);
    else if (p[0] == 4.0)
      out = sketch_bitmap(d, p, q, pics);
    else {
      tvg::Shape* one = tvg::Shape::gen();
      while (q < end) switch ((int)*q) {
          case 0:
            one->moveTo((float)q[1], (float)q[2]), q += 3;
            break;
          case 1:
            one->lineTo((float)q[1], (float)q[2]), q += 3;
            break;
          case 2:
            one->cubicTo((float)q[1], (float)q[2], (float)q[3], (float)q[4],
                         (float)q[5], (float)q[6]),
                q += 7;
            break;
          default:
            one->close(), q += 1;
        }
      const uint8_t r = (uint8_t)std::lround(p[1]),
                    g = (uint8_t)std::lround(p[2]),
                    b = (uint8_t)std::lround(p[3]),
                    a = (uint8_t)std::lround(p[4]);
      const bool conic = more && end[0] == 3.0;
      if (p[0] == 1.0) {
        if (more && !conic)
          one->fill(sketch_ramp(end, more));
        else
          one->fill(r, g, b, a);
      } else {
        one->strokeWidth((float)p[6]),
            one->strokeCap((tvg::StrokeCap)(int)p[7]),
            one->strokeJoin((tvg::StrokeJoin)(int)p[8]);
        if (more && !conic)
          one->strokeFill(sketch_ramp(end, more));
        else
          one->strokeFill(r, g, b, a);
      }
      out = conic && p[0] == 1.0 ? sketch_conic(one, end, more, pics) : one;
    }
    if (out && p[5] != 0.0) {
      // WgCompositor::renderImage ignores the blend method of a picture that
      // has a clip, and WgSolidBatch takes none, but both honor the blend
      // method of a scene. So a picture with a blend method is wrapped in a
      // scene.
      if (out->type() == tvg::Type::Picture) {
        tvg::Scene* alone = tvg::Scene::gen();
        alone->add(out), out = alone;
      }
      out->blend((tvg::BlendMethod)(int)p[5]);
    }
    if (out) d->sketchScene->add(out);
    i += 12 + n + more;
    if (++held == 4000 || pics.size() >= 256) out_now(), held = 0;
  }
  out_now();
}

Canvas2D* sketch_canvas(Stage& s, std::shared_ptr<Script> run,
                        const std::string& fontFile, float high,
                        const char* lay, const Canvas2DFx& fx) {
  const int fw = run->width(), fh = run->height();
  if (fw <= 0 || fh <= 0) return nullptr;
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        // Render at the resolution of the stage, as picture() does for an SVG.
        const float fit = (float)std::max(s.w, s.h) / (float)std::max(fw, fh);
        *w = 2 * (int)std::lround(0.5f * (float)fw * fit),
        *h = 2 * (int)std::lround(0.5f * (float)fh * fit);
        // Any font will do for a sketch, so use the one that Filament also
        // loads.
        if (tvg::Text::load(fontFile.c_str()) == tvg::Result::Success)
          d->sketchFont = std::filesystem::path(fontFile).stem().string();
        d->sketchScene = tvg::Scene::gen();
        // Paint coordinates are in the sketch canvas's own pixels, and
        // pixelDensity(2) gives it twice as many pixels as its width says.
        d->sketchScene->scale(fit / run->density());
        d->sketchLines = std::make_shared<std::map<int, double>>();
        for (const int line : run->lines()) (*d->sketchLines)[line] = 1.0;
        // Fetches the paint commands for a frame and scales the alpha of each
        // by the current value of the parameter attached to its source line, as
        // evaluated by doc_evaluate.
        d->sketch = [run, d, lines = d->sketchLines](int at, int had) {
          std::vector<double> o = run->paints(at, had);
          for (size_t i = 1; i + 12 <= o.size();) {
            double* p = &o[i];
            const size_t n = (size_t)p[9], more = (size_t)p[10];
            if (const auto k = lines->find((int)p[11]);
                k != lines->end() && k->second < 1.0) {
              p[4] *= k->second;
              for (size_t stop = 7; stop + 5 <= more; stop += 5)
                p[12 + n + stop + 4] *= k->second;
            }
            i += 12 + n + more;
          }
          sketch_bitmaps(d, run.get(), o);
          return o;
        };
        d->frames = 36000.f, d->seconds = 600.f;
        return d->sketchScene;
      },
      mat4f{}, high, float3{-1.f}, true, lay, fx);
}

Canvas2D* sketch_texture(Stage& s, Script* run, const std::string& fontFile,
                         int pic, int wide, int high) {
  Canvas2D* built = place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        *w = wide, *h = high;
        // Any font will do for a sketch, so use the one that Filament also
        // loads.
        if (tvg::Text::load(fontFile.c_str()) == tvg::Result::Success)
          d->sketchFont = std::filesystem::path(fontFile).stem().string();
        d->sketchScene = tvg::Scene::gen();
        d->sketch = [run, d, pic](int at, int had) {
          std::vector<double> o = run->paints(at, had, pic);
          sketch_bitmaps(d, run, o);
          return o;
        };
        d->frames = 36000.f, d->seconds = 600.f;
        return d->sketchScene;
      },
      mat4f{}, 1.f, float3{-1.f}, false, nullptr);
  if (built) s.playing.erase(built);
  return built;
}

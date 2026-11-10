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
#include <list>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <system_error>
#include <utility>
#include <vector>
// stb_truetype reports a malformed font by throwing instead of aborting the
// program. One example is an OpenType cmap (format 4) whose last segment is not
// 0xFFFF.
#define STBTT_assert(x) \
  ((x) ? (void)0 : throw std::out_of_range("stb_truetype"))
// Keep stb_truetype's symbols private to this translation unit.
#define STBTT_STATIC
#define STB_TRUETYPE_IMPLEMENTATION
// Used by type_lacks() to find which characters a font has.
#include "gpu/gpu_interop.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"
#include "third_party/filament_src/third_party/stb/stb_truetype.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

namespace {

// Returns the first frame of a Lottie file, which is the "ip" key at the top
// level of the file. ThorVG does not report it.
float lottie_in(const char* file) {
  std::ifstream in(file);
  std::string all((std::istreambuf_iterator<char>(in)),
                  std::istreambuf_iterator<char>());
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

// Converts an sRGB component to linear light.
float ramp_lin(float c) {
  return c <= 0.04045f ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f);
}

// Converts a linear-light component to sRGB.
float ramp_gam(float c) {
  return c <= 0.0031308f ? 12.92f * c
                         : 1.055f * std::pow(c, 1.f / 2.4f) - 0.055f;
}

// Converts an sRGB color to OKLab.
float3 ramp_oklab(float3 c) {
  const float r = ramp_lin(c.x), g = ramp_lin(c.y), b = ramp_lin(c.z);
  const float l = std::cbrt(0.4122214708f * r + 0.5363325363f * g +
                            0.0514459929f * b),
              m = std::cbrt(0.2119034982f * r + 0.6806995451f * g +
                            0.1073969566f * b),
              s = std::cbrt(0.0883024619f * r + 0.2817188376f * g +
                            0.6299787005f * b);
  return {0.2104542553f * l + 0.7936177850f * m - 0.0040720468f * s,
          1.9779984951f * l - 2.4285922050f * m + 0.4505937099f * s,
          0.0259040371f * l + 0.7827717662f * m - 0.8086757660f * s};
}

// Converts an OKLab color to sRGB, clamped to [0, 1].
float3 ramp_srgb(float3 o) {
  const float l = o.x + 0.3963377774f * o.y + 0.2158037573f * o.z,
              m = o.x - 0.1055613458f * o.y - 0.0638541728f * o.z,
              s = o.x - 0.0894841775f * o.y - 1.2914855480f * o.z;
  const float L = l * l * l, M = m * m * m, S = s * s * s;
  return {
      std::clamp(
          ramp_gam(4.0767416621f * L - 3.3077115913f * M + 0.2309699292f * S),
          0.f, 1.f),
      std::clamp(
          ramp_gam(-1.2684380046f * L + 2.6097574011f * M - 0.3413193965f * S),
          0.f, 1.f),
      std::clamp(
          ramp_gam(-0.0041960863f * L - 0.7034186147f * M + 1.7076147010f * S),
          0.f, 1.f)};
}

// Converts an RGB color to HSV: hue in degrees, saturation and value in [0, 1].
float3 ramp_hsv(float3 c) {
  const float mx = std::max({c.x, c.y, c.z}), mn = std::min({c.x, c.y, c.z}),
              d = mx - mn;
  float h = 0.f;
  if (d > 0.f)
    h = mx == c.x   ? std::fmod((c.y - c.z) / d, 6.f)
        : mx == c.y ? (c.z - c.x) / d + 2.f
                    : (c.x - c.y) / d + 4.f;
  return {std::fmod(h * 60.f + 360.f, 360.f), mx > 0.f ? d / mx : 0.f, mx};
}

// Converts an HSV color, with hue in degrees, to RGB.
float3 ramp_rgb(float3 h) {
  const float c = h.z * h.y,
              x = c * (1.f - std::fabs(std::fmod(h.x / 60.f, 2.f) - 1.f)),
              m = h.z - c;
  const int k = (int)(h.x / 60.f) % 6;
  const float3 p = k == 0   ? float3{c, x, 0}
                   : k == 1 ? float3{x, c, 0}
                   : k == 2 ? float3{0, c, x}
                   : k == 3 ? float3{0, x, c}
                   : k == 4 ? float3{x, 0, c}
                            : float3{c, 0, x};
  return p + m;
}

// Expands `ramp` (colors) and `at` (stop positions) in place for blend modes 1
// to 3. If `at` does not match `ramp`, stops are spaced evenly. Does nothing
// for mode 0 or fewer than two stops.
void ramp_blend(std::vector<float4>& ramp, std::vector<float>& at, int blend) {
  if (blend <= 0 || ramp.size() < 2) return;
  std::vector<float> pos = at.size() == ramp.size() ? at : std::vector<float>();
  if (pos.empty())
    for (size_t i = 0; i < ramp.size(); ++i)
      pos.push_back((float)i / (float)(ramp.size() - 1));
  std::vector<float4> out;
  std::vector<float> outAt;
  // Number of steps each pair of stops is split into.
  constexpr int between = 8;
  for (size_t i = 0; i + 1 < ramp.size(); ++i) {
    const float4 a = ramp[i], b = ramp[i + 1];
    // Hold the color until the next stop, which begins a hair later, because
    // ThorVG keeps only one of two stops at the same position.
    if (blend == 3) {
      out.push_back(a), outAt.push_back(pos[i]), out.push_back(a),
          outAt.push_back(std::max(pos[i], pos[i + 1] - 1e-4f));
      continue;
    }
    for (int k = 0; k < between; ++k) {
      const float t = (float)k / between;
      float3 c;
      if (blend == 1) {
        c = ramp_srgb(ramp_oklab(a.xyz) * (1.f - t) + ramp_oklab(b.xyz) * t);
      } else {
        float3 p = ramp_hsv(a.xyz), q = ramp_hsv(b.xyz);
        float dh = q.x - p.x;
        // Take the shorter way around the hue circle.
        if (dh > 180.f)
          dh -= 360.f;
        else if (dh < -180.f)
          dh += 360.f;
        c = ramp_rgb({std::fmod(p.x + dh * t + 360.f, 360.f),
                      p.y + (q.y - p.y) * t, p.z + (q.z - p.z) * t});
      }
      out.push_back({c, a.w + (b.w - a.w) * t}),
          outAt.push_back(pos[i] + (pos[i + 1] - pos[i]) * t);
    }
  }
  out.push_back(ramp.back()), outAt.push_back(pos.back());
  ramp = out, at = outAt;
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
    // Effect sizes are fractions of this height: the content as drawn, without
    // the margin.
    const float tall = (float)h;
    if (fx.reach > 0.f) {
      // Add a margin for effects that reach beyond the content. fx.reach is a
      // fraction of its height.
      const float room = std::ceil(fx.reach * (float)h);
      p->translate(room, room);
      // Enlarge the sheet by the same ratio as the texture, so the content
      // keeps its size.
      high *= ((float)h + 2.f * room) / (float)h;
      w += 2 * (int)room, h += 2 * (int)room;
    }
    // Effects need a ThorVG scene. Enlarge the picture on all sides by as far
    // as the effects reach.
    if (fx.blur > 0.f || fx.shadow.w > 0.f || fx.tint > 0.f ||
        fx.tritone > 0.f) {
      const float blur = fx.blur * tall, fall = fx.fall * tall,
                  soft = fx.soft * tall;
      const int room = (int)std::ceil(
          std::max({3.f * blur, fx.shadow.w > 0.f ? fall + 3.f * soft : 0.f,
                    fx.room * tall}));
      // One scene holds all the effects, applied in order.
      tvg::Scene* scene = tvg::Scene::gen();
      scene->add(p);
      d->effects.push_back(scene);
      p = scene;
      p->translate((float)room, (float)room);
      effects_on(d->effects, fx, tall);
      // Remember the effects so those that change over time can be drawn again
      // at each time.
      d->tall = tall, d->fx = fx;
      // Enlarge the sheet by the same ratio as the texture, so the content
      // keeps its size.
      high *= (float)(h + 2 * room) / (float)h;
      w += 2 * room, h += 2 * room;
    }
    d->canvasHigh = (float)h;
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
      under->fill((uint8_t)std::lround(255.f * ground.x),
                  (uint8_t)std::lround(255.f * ground.y),
                  (uint8_t)std::lround(255.f * ground.z), 255);
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
  Canvas2D* built = place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
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

tvg::Fill* ramp_of(const std::vector<float4>& given, float w, float h,
                   bool radial, float angle, float scale, int spread,
                   const std::vector<float>& givenAt, int blend) {
  std::vector<float4> ramp = given;
  std::vector<float> at = givenAt;
  ramp_blend(ramp, at, blend);
  tvg::Fill* g = nullptr;
  const float cx = 0.5f * w, cy = 0.5f * h, k = std::max(scale, 0.01f);
  // From the center out to the corners.
  if (radial) {
    tvg::RadialGradient* r = tvg::RadialGradient::gen();
    const float reach = 0.5f * std::hypot(w, h) * k;
    r->radial(cx, cy, reach, cx, cy, 0.f);
    g = r;
    // Across the area in the direction of `angle`, as far as the box reaches
    // that way.
  } else {
    tvg::LinearGradient* l = tvg::LinearGradient::gen();
    const float a = angle * (float)TAU / 360.f, dx = std::sin(a),
                dy = std::cos(a),
                reach =
                    (0.5f * std::fabs(w * dx) + 0.5f * std::fabs(h * dy)) * k;
    l->linear(cx - dx * reach, cy - dy * reach, cx + dx * reach,
              cy + dy * reach);
    g = l;
  }
  g->spread((tvg::FillSpread)std::clamp(spread, 0, 2));
  std::vector<tvg::Fill::ColorStop> stops;
  for (size_t i = 0; i < ramp.size(); ++i)
    // The w component of a color is its alpha, written as eight bits.
    stops.push_back(
        {at.size() == ramp.size() ? at[i] : (float)i / (float)(ramp.size() - 1),
         (uint8_t)std::lround(255.f * ramp[i].x),
         (uint8_t)std::lround(255.f * ramp[i].y),
         (uint8_t)std::lround(255.f * ramp[i].z),
         (uint8_t)std::lround(255.f * ramp[i].w)});
  g->colorStops(stops.data(), (uint32_t)stops.size());
  return g;
}

std::string type_lacks(const std::string& fontFile, const std::string& words) {
  static std::mutex lock;
  // Most recently used first.
  static std::list<
      std::pair<std::string, std::shared_ptr<const std::vector<unsigned char>>>>
      cached;
  std::shared_ptr<const std::vector<unsigned char>> bytes;
  {
    std::lock_guard<std::mutex> hold(lock);
    for (auto it = cached.begin(); it != cached.end() && !bytes; ++it)
      if (it->first == fontFile)
        bytes = it->second, cached.splice(cached.begin(), cached, it);
    if (!bytes) {
      std::ifstream in(fontFile, std::ios::binary);
      if (!in) return "";
      bytes = std::make_shared<const std::vector<unsigned char>>(
          std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
      cached.emplace_front(fontFile, bytes);
      if (cached.size() > 6) cached.pop_back();
    }
  }
  stbtt_fontinfo info;
  try {
    const int at = stbtt_GetFontOffsetForIndex(bytes->data(), 0);
    if (at < 0 || !stbtt_InitFont(&info, bytes->data(), at)) return "";
  } catch (const std::out_of_range&) {
    return "";
  }
  // A font whose cmap lacks the final 0xFFFF segment makes stb_truetype throw.
  // Treat that as no glyph.
  const auto has = [&](uint32_t u) {
    try {
      return stbtt_FindGlyphIndex(&info, (int)u) != 0;
    } catch (const std::out_of_range&) {
      return false;
    }
  };
  std::string lacks;
  // Walk the UTF-8 string one character at a time.
  for (size_t i = 0; i < words.size();) {
    const unsigned char c = (unsigned char)words[i];
    const int n = c < 0x80         ? 1
                  : (c >> 5) == 6  ? 2
                  : (c >> 4) == 14 ? 3
                  : (c >> 3) == 30 ? 4
                                   : 1;
    uint32_t u = n == 1 ? c : c & (0x7f >> n);
    for (int k = 1; k < n && i + k < words.size(); ++k)
      u = (u << 6) | ((unsigned char)words[i + k] & 0x3f);
    const std::string letter = words.substr(i, n);
    i += n;
    if (u <= 0x20 || (u >= 0x7f && u <= 0xa0) || (u >= 0x200b && u <= 0x200f) ||
        u == 0xfeff || (u >= 0xfe00 && u <= 0xfe0f))
      continue;
    if (!has(u) && lacks.find(letter) == std::string::npos) lacks += letter;
  }
  return lacks;
}

std::string type_fallback(const std::string& fontFile,
                          const std::string& words) {
  if (type_lacks(fontFile, words).empty()) return "";
  for (const std::filesystem::path& dir : doc_folders("fonts")) {
    // Per-folder listing errors are ignored.
    std::error_code wrong;
    std::vector<std::filesystem::path> fonts;
    for (const auto& e : std::filesystem::directory_iterator(dir, wrong))
      if (const std::string x = e.path().extension().string();
          x == ".otf" || x == ".ttf" || x == ".ttc" || x == ".OTF" ||
          x == ".TTF")
        fonts.push_back(e.path());
    std::sort(fonts.begin(), fonts.end());
    for (const auto& f : fonts)
      if (f != std::filesystem::path(fontFile) &&
          type_lacks(f.string(), words).empty())
        return f.string();
  }
  return "";
}

bool type_sets(const char* fontFile, const char* words) {
  if (!std::filesystem::is_regular_file(fontFile) ||
      !type_lacks(fontFile, words).empty() ||
      tvg::Text::load(fontFile) != tvg::Result::Success)
    return false;
  tvg::Text* t = tvg::Text::gen();
  t->font(std::filesystem::path(fontFile).stem().string().c_str());
  t->size(100.f);
  t->text(words);
  float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
  const bool sets = t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success &&
                    wide > 0.f && tall > 0.f;
  tvg::Paint::rel(t);
  // ThorVG counts each load. Unload a font that was only asked about, or memory
  // grows (543 MB over the shelf). A font in use stays loaded.
  tvg::Text::unload(fontFile);
  return sets;
}

Canvas2D* type(Stage& s, const char* words, const char* fontFile,
               const mat4f& place, float high, float3 colour, const char* lay,
               float4 edge, float align, const Canvas2DFx& fx) {
  if (!std::filesystem::is_regular_file(fontFile)) return nullptr;
  // If the font lacks characters, use the fallback for all of them. The
  // inspector reports this (motolii_font_lacks).
  const std::string fell = type_fallback(fontFile, words);
  if (!fell.empty()) fontFile = fell.c_str();
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        if (tvg::Text::load(fontFile) != tvg::Result::Success) return nullptr;
        tvg::Text* t = tvg::Text::gen();
        float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
        // Letter height in points, about an eighth of the stage's longer side.
        const float fine = 0.12f * (float)std::max(s.w, s.h);
        // ThorVG names a font by its file.
        t->font(std::filesystem::path(fontFile).stem().string().c_str());
        // The size as set. ThorVG does not report it back.
        float sized = fine;
        t->size(sized);
        t->text(words);
        t->spacing(fx.letters, fx.lines);
        if (fx.italic > 0.f) t->italic(fx.italic);
        // In a layout box ThorVG breaks the text into lines.
        if (fx.wrapWidth > 0.f)
          t->layout(fx.wrapWidth * fine, 0.f),
              t->wrap((tvg::TextWrap)std::clamp(fx.wrap, 0, 4)),
              t->align(align, 0.f);
        t->fill((uint8_t)std::lround(255.f * colour.x),
                (uint8_t)std::lround(255.f * colour.y),
                (uint8_t)std::lround(255.f * colour.z));
        bool measured =
            t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success &&
            wide > 0.f && tall > 0.f;
        // A line too long for one texture is set smaller.
        if (measured && wide > 4096.f) {
          t->size(sized = fine * 4096.f / wide);
          measured = t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success;
        }
        if (!measured) return tvg::Paint::rel(t), nullptr;
        // Align the lines in a box as wide as the widest line, using ThorVG's
        // layout and align.
        if (align > 0.f && fx.wrapWidth <= 0.f) {
          t->layout(wide, 0.f);
          t->align(align, 0.f);
          measured = t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success;
        }
        // A size means one line's height, as a font size does in After Effects
        // and Alight Motion (Font Size). With more lines the sheet becomes
        // taller, so measure one line to get the ratio.
        if (strchr(words, '\n') || fx.wrapWidth > 0.f) {
          std::string one(words);
          one.erase(std::remove(one.begin(), one.end(), '\n'), one.end());
          tvg::Text* line = tvg::Text::gen();
          line->font(std::filesystem::path(fontFile).stem().string().c_str());
          line->size(sized);
          line->text(one.c_str());
          float lineX, lineY, lineWide, lineTall;
          if (line->bounds(&lineX, &lineY, &lineWide, &lineTall) ==
                  tvg::Result::Success &&
              lineTall > 0.f) {
            tvg::TextMetrics font;
            if (fx.column && t->metrics(font) == tvg::Result::Success &&
                font.advance > 0.f)
              t->spacing(fx.letters, fx.lines * lineTall / font.advance),
                  t->bounds(&x, &y, &wide, &tall);
            d->tallBy = tall / lineTall;
          }
          tvg::Paint::rel(line);
        }
        const float stroke = edge.w * tall;
        if (stroke > 0.f)
          t->outline(stroke, (uint8_t)std::lround(255.f * edge.x),
                     (uint8_t)std::lround(255.f * edge.y),
                     (uint8_t)std::lround(255.f * edge.z));
        // Half of the outline lies outside the letters, so the texture grows by
        // that much on all sides.
        float outline = stroke;
        for (const float4& rim : fx.rims) outline += 2.f * rim.w * tall;
        t->translate(-x + 0.5f * outline, -y + 0.5f * outline);
        *w = 2 * (int)std::ceil(0.5f * (wide + outline));
        *h = 2 * (int)std::ceil(0.5f * (tall + outline));
        // Keep the text object so the words can be changed in place (see
        // words_at). This works only for plain text without splitting,
        // wrapping, alignment or rims.
        if (!fx.split && fx.wrapWidth <= 0.f && align <= 0.f && fx.rims.empty())
          d->text = t, d->words = words, d->textFont = fontFile,
          d->textWide = (float)*w, d->textAt = -y + 0.5f * outline;
        // A trailing newline after the words does not make an empty last line.
        std::string line(words);
        while (!line.empty() && (line.back() == '\n' || line.back() == '\r'))
          line.pop_back();
        // One line split into letters. Work out where each letter ends from the
        // width of the words up to it.
        if (fx.split && line.find('\n') == std::string::npos &&
            fx.wrapWidth <= 0.f) {
          // Measures `some`. Returns in x where its ink ends and in y how wide
          // it is, both as fractions of the texture width.
          const auto across = [&](const std::string& some) {
            tvg::Text* up = tvg::Text::gen();
            up->font(std::filesystem::path(fontFile).stem().string().c_str());
            up->size(sized);
            up->spacing(fx.letters, fx.lines);
            if (fx.italic > 0.f) up->italic(fx.italic);
            up->text(some.c_str());
            float ux = 0.f, uy = 0.f, uw = 0.f, uh = 0.f;
            const bool ok =
                up->bounds(&ux, &uy, &uw, &uh) == tvg::Result::Success;
            tvg::Paint::rel(up);
            return float2{ok ? (ux + uw - x + 0.5f * outline) / (float)*w : 0.f,
                          ok ? (uw + outline) / (float)*w : 0.f};
          };
          // For each letter, x is where the words up to and including it end,
          // and y is its width alone.
          std::vector<float2> inks;
          for (const char* at = line.c_str(); *at;) {
            const char* next = at + 1;
            // Advance over one UTF-8 character, however many bytes it has.
            while (*next && ((unsigned char)*next & 0xC0) == 0x80) ++next;
            if (fx.splitWords)
              while (*next && *next != ' ') ++next;
            inks.push_back(float2{across(std::string(line.c_str(), next)).x,
                                  across(std::string(at, next)).y});
            at = next;
            if (fx.splitWords)
              while (*at == ' ') ++at;
          }
          // Cut halfway across the gap between one letter's ink and the next,
          // so that neither includes an edge of its neighbor.
          float was = 0.f;
          for (size_t i = 0; i < inks.size(); ++i) {
            const float end = std::max(was, inks[i].x);
            const float cut =
                i + 1 < inks.size()
                    ? std::max(end,
                               0.5f * (end + std::max(end, inks[i + 1].x -
                                                               inks[i + 1].y)))
                    : 1.f;
            d->letters.push_back(float2{was, cut});
            was = cut;
          }
        }
        std::vector<float> ends;
        for (auto rim = fx.rims.rbegin(); rim != fx.rims.rend(); ++rim)
          ends.push_back((ends.empty() ? 0.f : ends.back()) + rim->w * tall);
        if (stroke > 0.f)
          ends.push_back((ends.empty() ? 0.f : ends.back()) + stroke);
        for (size_t i = 0; i < ends.size() && i < 3; ++i) d->bands[i] = ends[i];
        d->bands.w = (float)std::min<size_t>(ends.size(), 3);
        std::vector<tvg::Paint*> under;
        float wider = stroke;
        for (const float4& rim : fx.rims) {
          wider += 2.f * rim.w * tall;
          const uint8_t r = (uint8_t)std::lround(255.f * rim.x),
                        g = (uint8_t)std::lround(255.f * rim.y),
                        b = (uint8_t)std::lround(255.f * rim.z);
          tvg::Text* round = (tvg::Text*)t->duplicate();
          round->fill(r, g, b), round->outline(wider, r, g, b);
          under.push_back(round);
        }
        const auto over_rims = [&](tvg::Paint* top) -> tvg::Paint* {
          if (under.empty()) return top;
          tvg::Scene* all = tvg::Scene::gen();
          for (auto it = under.rbegin(); it != under.rend(); ++it)
            all->add(*it);
          all->add(top);
          return all;
        };
        if (fx.ramp.size() < 2) return over_rims(t);
        // With a color ramp, draw a rect as large as the text, filled with the
        // ramp, and show it only where the letters are, using ThorVG's alpha
        // mask. ThorVG counts a text's own gradient in the font's units, which
        // are not available from outside.
        tvg::Shape* ramp = tvg::Shape::gen();
        ramp->appendRect(0.f, 0.f, (float)*w, (float)*h);
        ramp->fill(ramp_of(fx.ramp, (float)*w, (float)*h, fx.radial,
                           fx.rampAngle, fx.rampScale, fx.spread, fx.rampAt,
                           fx.rampBlend));
        ramp->mask(t, tvg::MaskMethod::Alpha);
        return over_rims(ramp);
      },
      place, high, float3{-1.f}, true, lay, fx);
}

void flat_path(Canvas2D* d, tvg::Shape* shape, const char* form, int w, int h,
               float in, int points, float inner, float round, float fine) {
  const float cx = 0.5f * (float)w, cy = 0.5f * (float)h, rx = cx - in,
              ry = cy - in;
  // Line width of a wave or spiral: the stroke width, or a fraction of the
  // height.
  const float thick = in > 0.f ? 2.f * in : 0.08f * (float)h;
  // SVG path data given by the user. The coordinates are in units of the height
  // from the center, y pointing down as in SVG. The path is parsed by Skia.
  if (form[0] == 'M' || form[0] == 'm') {
    std::vector<tvg::PathCommand> c;
    std::vector<tvg::Point> p;
    if (sk_svg(form, c, p)) {
      for (tvg::Point& at : p)
        at = {cx + at.x * (float)h, cy + at.y * (float)h};
      shape->appendPath(c.data(), (uint32_t)c.size(), p.data(),
                        (uint32_t)p.size());
    }
  } else if (!strcmp(form, "circle"))
    shape->appendCircle(cx, cy, rx, ry);
  // A line waving across the shape: `points` cycles along its width, with an
  // amplitude of `inner` as a fraction of the half height.
  else if (!strcmp(form, "wave")) {
    const int cycles = std::clamp(points, 1, 100), n = 48 * cycles;
    const float amp = (cy - thick) * std::clamp(inner, 0.f, 1.f);
    for (int k = 0; k <= n; ++k) {
      const float x = thick + ((float)w - 2.f * thick) * (float)k / (float)n,
                  y = cy +
                      amp * std::sin(TAU * (float)cycles * (float)k / (float)n);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
  }
  // A line winding out from the center as in Cavalry's spiral: `points` turns,
  // starting at `inner` of the way out.
  else if (!strcmp(form, "spiral")) {
    const float turns = (float)std::clamp(points, 1, 50),
                from = std::clamp(inner, 0.f, 0.95f);
    const int n = (int)(96.f * turns);
    for (int k = 0; k <= n; ++k) {
      const float u = (float)k / (float)n, a = -0.25f * TAU + TAU * turns * u,
                  r = from + (1.f - from) * u;
      const float x = cx + (rx - thick) * r * std::cos(a),
                  y = cy + (ry - thick) * r * std::sin(a);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
  }
  // Ring: the hole is `inner` of the way out. Arc: `points` degrees of it,
  // `inner` thick, clockwise from straight up.
  else if (!strcmp(form, "ring") || !strcmp(form, "arc")) {
    const bool arc = !strcmp(form, "arc");
    const float hole = arc ? 1.f - std::clamp(inner, 0.02f, 1.f)
                           : std::clamp(inner, 0.f, 0.98f),
                sweep =
                    arc ? TAU * std::clamp((float)points, 1.f, 360.f) / 360.f
                        : TAU;
    const int n = std::max(8, (int)(96.f * sweep / TAU));
    // Go around the outside, then back around the inside. The hole is a
    // separate contour in the opposite direction.
    for (int k = 0; k <= n; ++k) {
      const float a = -0.25f * TAU + sweep * (float)k / (float)n;
      k ? shape->lineTo(cx + rx * std::cos(a), cy + ry * std::sin(a))
        : shape->moveTo(cx + rx * std::cos(a), cy + ry * std::sin(a));
    }
    if (!arc) shape->close();
    if (hole > 0.f) {
      for (int k = n; k >= 0; --k) {
        const float a = -0.25f * TAU + sweep * (float)k / (float)n;
        (k == n && !arc) ? shape->moveTo(cx + rx * hole * std::cos(a),
                                         cy + ry * hole * std::sin(a))
                         : shape->lineTo(cx + rx * hole * std::cos(a),
                                         cy + ry * hole * std::sin(a));
      }
    }
    shape->close();
  }
  // Arrow pointing right: the shaft is `inner` of the height thick and the head
  // is a third of the length.
  else if (!strcmp(form, "arrow")) {
    const float shaft = 0.5f * ry * std::clamp(inner, 0.05f, 1.f),
                head = (float)w - in - std::min(2.f * rx / 3.f, 1.2f * ry);
    const float pts[][2] = {
        {in, cy - shaft},    {head, cy - shaft},    {head, in},
        {(float)w - in, cy}, {head, (float)h - in}, {head, cy + shaft},
        {in, cy + shaft}};
    for (int k = 0; k < 7; ++k)
      k ? shape->lineTo(pts[k][0], pts[k][1])
        : shape->moveTo(pts[k][0], pts[k][1]);
    shape->close();
  }
  // A rect with its corners cut straight, as Cavalry's rectangle with chamfer.
  // Each corner loses `inner` of the shorter half side.
  else if (!strcmp(form, "chamfer")) {
    const float c = std::clamp(inner, 0.f, 1.f) * std::min(rx, ry), x0 = in,
                y0 = in, x1 = (float)w - in, y1 = (float)h - in;
    const float pts[][2] = {{x0 + c, y0}, {x1 - c, y0}, {x1, y0 + c},
                            {x1, y1 - c}, {x1 - c, y1}, {x0 + c, y1},
                            {x0, y1 - c}, {x0, y0 + c}};
    for (int k = 0; k < 8; ++k)
      k ? shape->lineTo(pts[k][0], pts[k][1])
        : shape->moveTo(pts[k][0], pts[k][1]);
    shape->close();
  }
  // A superellipse |x|^p + |y|^p = 1, where p is `points`. 2 is an ellipse and
  // a higher p is squarer.
  else if (!strcmp(form, "squircle")) {
    const float p = std::clamp((float)points, 2.f, 40.f);
    for (int k = 0; k < 128; ++k) {
      const float a = TAU * (float)k / 128.f, c = std::cos(a), sn = std::sin(a);
      const float x = cx +
                      rx * std::copysign(std::pow(std::fabs(c), 2.f / p), c),
                  y = cy +
                      ry * std::copysign(std::pow(std::fabs(sn), 2.f / p), sn);
      k ? shape->lineTo(x, y) : shape->moveTo(x, y);
    }
    shape->close();
  }
  // A cogwheel with `points` teeth, each `inner` of the radius deep and flat on
  // top.
  else if (!strcmp(form, "cog")) {
    const int teeth = std::clamp(points, 3, 100), n = 4 * teeth;
    const float deep = 1.f - std::clamp(inner, 0.02f, 0.9f);
    // Each tooth has four corners: rising, top, falling, bottom.
    for (int k = 0; k < n; ++k) {
      const float a0 = -0.25f * TAU + TAU * (float)k / (float)n,
                  r = (k % 4 == 1 || k % 4 == 2) ? 1.f : deep;
      k ? shape->lineTo(cx + rx * r * std::cos(a0), cy + ry * r * std::sin(a0))
        : shape->moveTo(cx + rx * r * std::cos(a0), cy + ry * r * std::sin(a0));
    }
    shape->close();
  } else if (!strcmp(form, "polygon") || !strcmp(form, "star")) {
    const bool star = !strcmp(form, "star");
    const int n = std::clamp(points, 3, 100) * (star ? 2 : 1);
    for (int k = 0; k < n; ++k) {
      // The first point is straight up.
      const float a = -0.5f * TAU / 2.f + TAU * (float)k / (float)n,
                  r = star && (k & 1) ? std::clamp(inner, 0.01f, 1.f) : 1.f;
      k ? shape->lineTo(cx + rx * r * std::cos(a), cy + ry * r * std::sin(a))
        : shape->moveTo(cx + rx * r * std::cos(a), cy + ry * r * std::sin(a));
    }
    shape->close();
  } else {
    // Anything else is a rectangle. The line form rounds its ends completely.
    const float side = std::min((float)w, (float)h) - 2.f * in,
                corner = !strcmp(form, "line") ? 0.5f * side : 0.f;
    shape->appendRect(in, in, (float)w - 2.f * in, (float)h - 2.f * in, corner,
                      corner);
  }
  const tvg::PathCommand* cmds;
  const tvg::Point* pts;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
  shape->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
  d->plain.assign(cmds, cmds + cmdsCnt), d->plainAt.assign(pts, pts + ptsCnt);
  d->plainHigh = (float)h,
  d->plainSide = std::min((float)w, (float)h) - 2.f * in;
  d->fine = fine;
  // Round the corners and cut the path into pieces. Remember the rounding that
  // was used.
  if ((round > 0.f && strcmp(form, "line")) || d->fine != 0.f)
    tvg_bend(shape, d->plain.data(), cmdsCnt, d->plainAt.data(), ptsCnt,
             strcmp(form, "line") ? std::clamp(round, 0.f, 0.5f) * d->plainSide
                                  : 0.f,
             0.f, 0.f, 0, false, 0.f, d->fine),
        d->bent[0] = round;
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

Canvas2D* flat(Stage& s, const char* form, float wide, const mat4f& place,
               float high, float3 colour, const char* lay, float4 edge,
               const Canvas2DFx& fx, int points, float inner, float round) {
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        // Resolution: half the stage's longer side. A long thin bar gets less
        // height so that its length stays within 4096 points.
        const float tall = std::min(0.5f * (float)std::max(s.w, s.h),
                                    4096.f / std::max(wide, 1e-3f));
        *h = std::max(2, 2 * (int)std::ceil(0.5f * tall));
        *w = std::max(2, 2 * (int)std::ceil(0.5f * tall * wide));
        // Half the stroke width. The path is inset by it so that all of the
        // stroke is visible. It is a whole number of points so that corners
        // land on whole points, because ThorVG's rounded corners treat a side
        // as straight only when it is exactly so (tvgLottieModifier.cpp,
        // _colinear).
        const float in =
            std::round(0.5f * std::min(edge.w * (float)*h,
                                       0.5f * (float)std::min(*w, *h)));
        // Line width of a wave or spiral: the stroke width, or a fraction of
        // the height.
        const float thick = in > 0.f ? 2.f * in : 0.08f * (float)*h;
        tvg::Shape* shape = d->shape = tvg::Shape::gen();
        flat_path(d, shape, form, *w, *h, in, points, inner, round, 0.f);
        shape->fill((uint8_t)std::lround(255.f * colour.x),
                    (uint8_t)std::lround(255.f * colour.y),
                    (uint8_t)std::lround(255.f * colour.z),
                    strcmp(form, "null") && !fx.hollow ? 255 : 0);
        if (fx.ramp.size() > 1 && strcmp(form, "null"))
          shape->fill(ramp_of(fx.ramp, (float)*w, (float)*h, fx.radial,
                              fx.rampAngle, fx.rampScale, fx.spread, fx.rampAt,
                              fx.rampBlend));
        if (in > 0.f)
          shape->strokeWidth(2.f * in),
              shape->strokeFill((uint8_t)std::lround(255.f * edge.x),
                                (uint8_t)std::lround(255.f * edge.y),
                                (uint8_t)std::lround(255.f * edge.z));
        // Wave and spiral show only their line, in the edge color or else the
        // fill color, with round ends.
        if (!strcmp(form, "wave") || !strcmp(form, "spiral")) {
          const float3 ink = in > 0.f ? float3{edge.x, edge.y, edge.z} : colour;
          shape->fill(0, 0, 0, 0);
          shape->strokeWidth(thick),
              shape->strokeFill((uint8_t)std::lround(255.f * ink.x),
                                (uint8_t)std::lround(255.f * ink.y),
                                (uint8_t)std::lround(255.f * ink.z));
          shape->strokeCap(tvg::StrokeCap::Round);
        }
        if (fx.cap >= 0) shape->strokeCap((tvg::StrokeCap)fx.cap);
        if (fx.join >= 0) shape->strokeJoin((tvg::StrokeJoin)fx.join);
        // Dashes and gaps are equally long, as fractions of the height.
        if (fx.dash > 0.f) {
          const float gap[2] = {fx.dash * (float)*h, fx.dash * (float)*h};
          shape->strokeDash(gap, 2, fx.dashFrom * (float)*h);
        }
        // Fill with an image. It covers the shape and is visible only where the
        // shape is filled, using ThorVG's alpha mask, as a ramp does on letters
        // in type. The edge is drawn over it.
        if (!fx.media.empty() && strcmp(form, "null") && !fx.hollow) {
          tvg::Picture* pic = tvg::Picture::gen();
          float pw = 0.f, ph = 0.f;
          if (pic->load(fx.media.c_str()) == tvg::Result::Success &&
              pic->size(&pw, &ph) == tvg::Result::Success && pw > 0.f &&
              ph > 0.f) {
            // Cover the shape and keep the middle: crop instead of stretching.
            const float k = std::max((float)*w / pw, (float)*h / ph);
            pic->size(pw * k, ph * k);
            pic->translate(0.5f * ((float)*w - pw * k),
                           0.5f * ((float)*h - ph * k));
            tvg::Shape* cut = static_cast<tvg::Shape*>(shape->duplicate());
            cut->strokeWidth(0.f), cut->fill(255, 255, 255, 255);
            pic->mask(cut, tvg::MaskMethod::Alpha);
            // The shape's own fill is cleared because the image is its fill.
            // The edge stays over it.
            shape->fill(0, 0, 0, 0);
            tvg::Scene* both = tvg::Scene::gen();
            both->add(pic), both->add(shape);
            return both;
          }
          tvg::Paint::rel(pic);
        }
        return shape;
      },
      place, high, float3{-1.f}, true, lay, fx);
}

}  // namespace motolii

// Text on the stage: finding which characters a font lacks, choosing a
// fallback font, and setting the words into a canvas: Blitz and Parley lay the
// letters out, with CSS on ranges of them (community/css/text.h), and ThorVG
// draws their outlines.

#include <thorvg.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <list>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <sstream>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "community/css/text.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"
// stb_truetype reports a malformed font by throwing instead of aborting the
// program. One example is an OpenType cmap (format 4) whose last segment is not
// 0xFFFF.
#define STBTT_assert(x) \
  ((x) ? (void)0 : throw std::out_of_range("stb_truetype"))
// Keep stb_truetype's symbols private to this translation unit.
#define STBTT_STATIC
#define STB_TRUETYPE_IMPLEMENTATION
// Used by type_lacks() to find which characters a font has.
#include <stb_truetype.h>

#include "shelf/shelf_folders.h"

namespace motolii {

using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {
// ThorVG's size is in points, drawn at 96 / 72 pixels each
// (src/renderer/tvgLoader.h, FontLoader::DPI); a text's size keeps that sense.
constexpr float kPixelsPerPoint = 96.f / 72.f;

// The letters of a text as text.h sets them, freed when it goes.
struct Set {
  MotoliiText* t = nullptr;
  explicit Set(MotoliiText* t) : t(t) {}
  Set(const Set&) = delete;
  Set& operator=(const Set&) = delete;
  ~Set() {
    if (t) motolii_text_free(t);
  }
  template <int N>
  std::vector<std::array<float, N>> get(int32_t (*of)(const MotoliiText*,
                                                      float*)) const {
    std::vector<std::array<float, N>> all((size_t)of(t, nullptr));
    of(t, all.empty() ? nullptr : all[0].data());
    return all;
  }
};

// Puts the outlines of all the letters of `t` into `shape`.
void draw_letters(const MotoliiText* t, tvg::Shape* shape) {
  const uint8_t* verbs = nullptr;
  const float* points = nullptr;
  int32_t verbCount = 0, pointCount = 0;
  motolii_text_path(t, &verbs, &verbCount, &points, &pointCount);
  static constexpr tvg::PathCommand kinds[] = {
      tvg::PathCommand::MoveTo, tvg::PathCommand::LineTo,
      tvg::PathCommand::CubicTo, tvg::PathCommand::Close};
  std::vector<tvg::PathCommand> cmds;
  for (int32_t i = 0; i < verbCount; ++i) cmds.push_back(kinds[verbs[i] & 3]);
  shape->appendPath(cmds.data(), (uint32_t)cmds.size(),
                    reinterpret_cast<const tvg::Point*>(points),
                    (uint32_t)pointCount);
}
}  // namespace

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
      !type_lacks(fontFile, words).empty())
    return false;
  const Set set(
      motolii_text_new(words, nullptr, fontFile, 100.f, 1.2f, 0.f, 0.f, 0.f, 0,
                       0.f));
  if (!set.t) return false;
  const uint8_t* verbs = nullptr;
  const float* points = nullptr;
  int32_t verbCount = 0, pointCount = 0;
  motolii_text_path(set.t, &verbs, &verbCount, &points, &pointCount);
  return verbCount > 0;
}

Canvas2D* type(Stage& s, const char* words, const char* fontFile,
               const char* styles, const mat4f& place, float high,
               float3 colour, const char* lay, float4 edge, float align,
               const Canvas2DFx& fx) {
  if (!std::filesystem::is_regular_file(fontFile)) return nullptr;
  // Letters the font lacks are set in the fallback font, letter by letter. The
  // inspector reports them (motolii_font_lacks).
  std::string fonts = fontFile;
  if (const std::string fell = type_fallback(fontFile, words); !fell.empty())
    fonts += "\n" + fell;
  // Letter height in points, about an eighth of the stage's longer side.
  const float fine = 0.12f * (float)std::max(s.w, s.h);
  const std::string ranges = styles ? styles : "";
  // ThorVG's wrap modes (tvg::TextWrap): 1 breaks between any two letters.
  const auto set = [fonts, ranges, fine, align, lines = fx.lines,
                    tracking = fx.letters, slant = fx.italic,
                    wrap = fx.wrapWidth,
                    breakAll = fx.wrap == 1](const char* some, float sized) {
    return motolii_text_new(some, ranges.c_str(), fonts.c_str(),
                            sized * kPixelsPerPoint, lines, tracking, slant,
                            wrap > 0.f ? wrap * fine : 0.f, breakAll, align);
  };
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        // The size as set.
        float sized = fine;
        auto t = std::make_unique<Set>(set(words, sized));
        if (!t->t) return nullptr;
        tvg::Shape* shape = tvg::Shape::gen();
        draw_letters(t->t, shape);
        // The text's box: from the first line's top to the last line's bottom
        // and across the widest line, and wherever its ink reaches past them.
        float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
        auto lined = t->get<5>(motolii_text_lines);
        const auto measure = [&] {
          if (lined.empty()) return false;
          float x0 = 0.f, y0 = 0.f, x1 = 0.f, y1 = 0.f, ix = 0.f, iy = 0.f,
                iw = 0.f, ih = 0.f;
          x0 = lined[0][3], x1 = x0, y0 = lined[0][0] - lined[0][1];
          y1 = lined.back()[0] + lined.back()[2];
          for (const auto& l : lined)
            x0 = std::min(x0, l[3]), x1 = std::max(x1, l[3] + l[4]);
          if (shape->bounds(&ix, &iy, &iw, &ih) == tvg::Result::Success &&
              iw > 0.f && ih > 0.f)
            x0 = std::min(x0, ix), y0 = std::min(y0, iy),
            x1 = std::max(x1, ix + iw), y1 = std::max(y1, iy + ih);
          x = x0, y = y0, wide = x1 - x0, tall = y1 - y0;
          return wide > 0.f && tall > 0.f;
        };
        bool measured = measure();
        // A line too long for one texture is set smaller.
        if (measured && wide > 4096.f) {
          t = std::make_unique<Set>(set(words, sized = fine * 4096.f / wide));
          if (!t->t) return tvg::Paint::rel(shape), nullptr;
          shape->reset();
          draw_letters(t->t, shape);
          lined = t->get<5>(motolii_text_lines);
          measured = measure();
        }
        if (!measured) return tvg::Paint::rel(shape), nullptr;
        // A size means one line's height in the layer's font, as a font size
        // does in After Effects and Alight Motion (Font Size), whatever the
        // ranges set: more lines, or larger letters, make the sheet taller.
        float ascent = 0.f, descent = 0.f;
        motolii_text_font(t->t, &ascent, &descent);
        if (ascent + descent > 0.f) d->tallBy = tall / (ascent + descent);
        // The shape the letters are drawn from: trim_at trims it as it trims
        // a shape's, and with no fill only the letters' edge shows.
        d->shape = shape, d->letterEdge = nullptr;
        shape->fill(byte_of(colour.x), byte_of(colour.y), byte_of(colour.z),
                    fx.hollow ? 0 : 255);
        const float stroke = edge.w * tall;
        if (stroke > 0.f)
          shape->strokeWidth(stroke),
              shape->strokeFill(byte_of(edge.x), byte_of(edge.y),
                                byte_of(edge.z));
        // Half of the outline lies outside the letters, so the texture grows by
        // that much on all sides.
        float outline = stroke;
        for (const float4& rim : fx.rims) outline += 2.f * rim.w * tall;
        const float dx = -x + 0.5f * outline, dy = -y + 0.5f * outline;
        shape->translate(dx, dy);
        *w = 2 * (int)std::ceil(0.5f * (wide + outline));
        *h = 2 * (int)std::ceil(0.5f * (tall + outline));
        d->em = sized * kPixelsPerPoint / (float)*h;
        const float base = lined[0][0] + dy;
        d->line = {(base - ascent) / (float)*h, (base + descent) / (float)*h};
        const auto colored = t->get<8>(motolii_text_colors);
        // Keep a way to set other words in place (see words_at). This works
        // only for plain text without splitting, wrapping, alignment, rims or
        // ranges.
        if (!fx.split && fx.wrapWidth <= 0.f && align <= 0.f &&
            fx.rims.empty() && ranges.empty()) {
          d->words = words, d->textFont = fontFile,
          d->textWide = (float)*w, d->textAt = dy;
          d->retype = [d, set, sized](const std::string& now) {
            const Set again(set(now.c_str(), sized));
            if (!again.t) return;
            d->shape->translate(0.f, 0.f);
            d->shape->reset();
            draw_letters(again.t, d->shape);
            float ix = 0.f, iy = 0.f, iw = 0.f, ih = 0.f;
            if (d->shape->bounds(&ix, &iy, &iw, &ih) != tvg::Result::Success)
              return;
            d->outgrown = iw > d->textWide + 0.5f;
            d->shape->translate(0.5f * (d->textWide - iw) - ix, d->textAt);
          };
        }
        // A trailing newline after the words does not make an empty last line.
        std::string line(words);
        while (!line.empty() && (line.back() == '\n' || line.back() == '\r'))
          line.pop_back();
        // Split into lines: each line is cut halfway between where its letters
        // reach down and where the next line's reach up.
        if (fx.split && fx.splitLines && fx.wrapWidth <= 0.f) {
          const size_t many = std::min(
              lined.size(),
              (size_t)(1 + std::count(line.begin(), line.end(), '\n')));
          float was = 0.f;
          for (size_t k = 0; k < many; ++k) {
            const float cut =
                k + 1 < many
                    ? std::clamp((0.5f * (lined[k][0] + lined[k][2] +
                                          lined[k + 1][0] - lined[k + 1][1]) +
                                  dy) /
                                     (float)*h,
                                 was, 1.f)
                    : 1.f;
            d->letters.push_back(float2{was, cut});
            // Its box across: where the line is set and how wide it is.
            d->boxes.push_back(float2{
                std::max(0.f, (lined[k][3] + dx - 0.5f * outline) / (float)*w),
                std::min(1.f, (lined[k][4] + outline) / (float)*w)});
            was = cut;
          }
          d->lettersDown = true,
          d->linePitch = (lined.size() > 1 ? lined[1][0] - lined[0][0]
                                           : sized * kPixelsPerPoint * fx.lines) /
                         (float)*h;
        }
        // One line split into letters, or words: each is cut halfway across
        // the gap between its ink and the next one's, so that neither holds
        // an edge of its neighbor; its box is where it is set and its advance.
        if (fx.split && !fx.splitLines &&
            line.find('\n') == std::string::npos && fx.wrapWidth <= 0.f) {
          const auto each = t->get<5>(motolii_text_letters);
          // For each letter, x is where the ink of the words up to and
          // including it ends, and y how wide its own ink is.
          std::vector<float2> inks;
          float reach = 0.f;
          size_t i = 0;
          for (const char* at = line.c_str(); *at && i < each.size();) {
            const auto one = [&] {
              const char* next = at + 1;
              // Over one UTF-8 character, however many bytes it has.
              while (*next && ((unsigned char)*next & 0xC0) == 0x80) ++next;
              at = next;
              return each[i++];
            };
            const auto first = one();
            auto last = first;
            float from = first[2], to = first[3];
            if (fx.splitWords)
              while (*at && *at != ' ' && i < each.size())
                if (last = one(); last[3] > last[2])
                  from = to > from ? std::min(from, last[2]) : last[2],
                  to = std::max(to, last[3]);
            if (to > from) reach = std::max(reach, to);
            inks.push_back(
                float2{(reach + dx + 0.5f * outline) / (float)*w,
                       to > from ? (to - from + outline) / (float)*w : 0.f});
            d->boxes.push_back(float2{
                (first[0] + dx) / (float)*w,
                (last[0] + last[1] - first[0]) / (float)*w});
            if (fx.splitWords)
              while (*at == ' ') ++at, ++i;
          }
          float was = 0.f;
          for (size_t k = 0; k < inks.size(); ++k) {
            const float end = std::max(was, inks[k].x);
            const float cut =
                k + 1 < inks.size()
                    ? std::max(end,
                               0.5f * (end + std::max(end, inks[k + 1].x -
                                                               inks[k + 1].y)))
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
        for (size_t k = 0; k < ends.size() && k < 3; ++k) d->bands[k] = ends[k];
        d->bands.w = (float)std::min<size_t>(ends.size(), 3);
        std::vector<tvg::Paint*> under;
        float wider = stroke;
        for (const float4& rim : fx.rims) {
          wider += 2.f * rim.w * tall;
          const uint8_t r = byte_of(rim.x), g = byte_of(rim.y),
                        b = byte_of(rim.z);
          tvg::Shape* round = (tvg::Shape*)shape->duplicate();
          round->fill(r, g, b), round->strokeWidth(wider),
              round->strokeFill(r, g, b);
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
        if (fx.ramp.size() < 2 && colored.empty()) return over_rims(shape);
        // With a color ramp, or ranges of their own color, draw a sheet as
        // large as the text in the fill, the ramp and the ranges' colors, and
        // show it only where the letters are, using ThorVG's alpha mask.
        tvg::Scene* sheet = tvg::Scene::gen();
        tvg::Shape* ground = tvg::Shape::gen();
        ground->appendRect(0.f, 0.f, (float)*w, (float)*h);
        if (fx.ramp.size() >= 2)
          ground->fill(ramp_of(fx.ramp, (float)*w, (float)*h, fx.radial,
                               fx.rampAngle, fx.rampScale, fx.spread,
                               fx.rampAt, fx.rampBlend));
        else
          ground->fill(byte_of(colour.x), byte_of(colour.y), byte_of(colour.z));
        sheet->add(ground);
        for (const auto& c : colored) {
          tvg::Shape* piece = tvg::Shape::gen();
          piece->appendRect(c[0] + dx, c[1] + dy, c[2], c[3]);
          piece->fill(byte_of(c[4]), byte_of(c[5]), byte_of(c[6]),
                      byte_of(c[7]));
          sheet->add(piece);
        }
        sheet->mask(shape, tvg::MaskMethod::Alpha);
        if (stroke <= 0.f) return over_rims(sheet);
        // The mask shows the sheet's colours on the outline too, so the
        // outline is drawn again over the sheet, as a fill and stroke show.
        tvg::Shape* edged = (tvg::Shape*)shape->duplicate();
        edged->fill(0, 0, 0, 0);
        d->letterEdge = edged;
        tvg::Scene* top = tvg::Scene::gen();
        top->add(sheet), top->add(edged);
        return over_rims(top);
      },
      place, high, float3{-1.f}, true, lay, fx);
}

}  // namespace motolii

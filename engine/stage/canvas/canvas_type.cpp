// Text on the stage: finding which characters a font lacks, choosing a
// fallback font, and setting the words with ThorVG into a canvas.

#include <thorvg.h>

#include <algorithm>
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
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "stage/canvas/canvas_renderables.h"
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
// A ThorVG text in the font of `fontFile` at `size`. ThorVG names a font by its
// file.
tvg::Text* text_new(const char* fontFile, float size) {
  tvg::Text* t = tvg::Text::gen();
  t->font(std::filesystem::path(fontFile).stem().string().c_str());
  t->size(size);
  return t;
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
      !type_lacks(fontFile, words).empty() ||
      tvg::Text::load(fontFile) != tvg::Result::Success)
    return false;
  tvg::Text* t = text_new(fontFile, 100.f);
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
        float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
        // Letter height in points, about an eighth of the stage's longer side.
        const float fine = 0.12f * (float)std::max(s.w, s.h);
        // The size as set. ThorVG does not report it back.
        float sized = fine;
        tvg::Text* t = text_new(fontFile, sized);
        t->text(words);
        t->spacing(fx.letters, fx.lines);
        if (fx.italic > 0.f) t->italic(fx.italic);
        // In a layout box ThorVG breaks the text into lines.
        if (fx.wrapWidth > 0.f)
          t->layout(fx.wrapWidth * fine, 0.f),
              t->wrap((tvg::TextWrap)std::clamp(fx.wrap, 0, 4)),
              t->align(align, 0.f);
        t->fill(byte_of(colour.x), byte_of(colour.y), byte_of(colour.z));
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
          tvg::Text* line = text_new(fontFile, sized);
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
          t->outline(stroke, byte_of(edge.x), byte_of(edge.y), byte_of(edge.z));
        // Half of the outline lies outside the letters, so the texture grows by
        // that much on all sides.
        float outline = stroke;
        for (const float4& rim : fx.rims) outline += 2.f * rim.w * tall;
        t->translate(-x + 0.5f * outline, -y + 0.5f * outline);
        *w = 2 * (int)std::ceil(0.5f * (wide + outline));
        *h = 2 * (int)std::ceil(0.5f * (tall + outline));
        // ThorVG's size is in points, drawn at 96 / 72 pixels each
        // (src/renderer/tvgLoader.h, FontLoader::DPI; sfnt loader's scale).
        d->em = sized * (96.f / 72.f) / (float)*h;
        // ThorVG sets the baseline the hhea ascent below the text's top
        // (loaders/sfnt/tvgSfntLoader.cpp, SfntLoader::transform), and the text
        // was moved by -y here.
        tvg::TextMetrics font;
        if (t->metrics(font) == tvg::Result::Success) {
          const float base = font.ascent - y + 0.5f * outline;
          d->line = {(base - font.ascent) / (float)*h,
                     (base - font.descent) / (float)*h};
        }
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
            tvg::Text* up = text_new(fontFile, sized);
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
            // Its box: the advances of its characters. The last one is set
            // where its ink ends less how far that ink reaches past where it is
            // set; the others before it.
            tvg::GlyphMetrics g{};
            float advance = 0.f;
            for (const char* c = at; c < next;) {
              const char* after = nullptr;
              if (t->metrics(c, g, &after) != tvg::Result::Success || !after)
                break;
              advance += g.advance * fx.letters, c = after;
            }
            const float last = inks.back().x * (float)*w - g.max.x;
            d->boxes.push_back(
                float2{(last - (advance - g.advance * fx.letters)) / (float)*w,
                       advance / (float)*w});
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
          const uint8_t r = byte_of(rim.x), g = byte_of(rim.y),
                        b = byte_of(rim.z);
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

}  // namespace motolii

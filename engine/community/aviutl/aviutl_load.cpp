#include "community/aviutl/aviutl_load.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <string>
#include <system_error>
#include <vector>

#ifdef __APPLE__
// Used by aviutl_font_file to find a font by name.
#include <CoreText/CoreText.h>
#endif

#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/Texture.h>
#include <thorvg.h>

#include <lua.hpp>

#include "community/aviutl/aviutl_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Texture;
namespace backend = filament::backend;

namespace {

// Corner count of each figure name accepted by obj.load: circle (0), background
// (1, a rectangle the size of the screen), rectangle (4), triangle (3),
// pentagon (5), hexagon (6) and five-point star (-5; a negative count means a
// star with that many points).
const std::map<std::string, int> aviutl_figures = {
    {"円", 0},     {"四角形", 4}, {"三角形", 3}, {"五角形", 5},
    {"六角形", 6}, {"星形", -5},  {"背景", 1}};

// Returns an image of the pixels drawn by `paint` on a ThorVG canvas of w x h
// pixels, cached in r.loaded under `key`. Returns nullptr if the size is zero
// or over 4096, or if drawing fails. The pointer stays valid while r.loaded
// keeps the entry.
const AviutlBuf* aviutl_canvas(
    AviutlRun& r, const std::string& key, uint32_t w, uint32_t h,
    const std::function<bool(tvg::SwCanvas*)>& paint) {
  if (const auto cached = r.loaded.find(key); cached != r.loaded.end())
    return &cached->second;
  if (!w || !h || w > 4096 || h > 4096) return nullptr;
  auto* pixels = new std::vector<uint32_t>((size_t)w * h, 0);
  // ThorVG creates no canvas and reads no file until it has been initialized.
  tvg::Initializer::init(0);
  tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
  const bool drew =
      canvas->target(pixels->data(), w, w, h, tvg::ColorSpace::ABGR8888) ==
          tvg::Result::Success &&
      paint(canvas) && canvas->draw(true) == tvg::Result::Success &&
      canvas->sync() == tvg::Result::Success;
  delete canvas;
  if (!drew) return delete pixels, nullptr;
  AviutlBuf& b = r.loaded[key];
  b.w = w, b.h = h;
  b.t = Texture::Builder()
            .width(w)
            .height(h)
            .levels(1)
            .format(Texture::InternalFormat::RGBA8)
            .build(*r.s->engine);
  b.t->setImage(
      *r.s->engine, 0,
      backend::PixelBufferDescriptor(
          pixels->data(), pixels->size() * 4, backend::PixelDataFormat::RGBA,
          backend::PixelDataType::UBYTE,
          [](void*, size_t, void* u) { delete (std::vector<uint32_t>*)u; },
          pixels));
  return &b;
}

// Returns a ThorVG shape of the figure with `corners` corners (see
// aviutl_figures) that fills a w x h box. A positive count gives a regular
// polygon with one corner up. A negative count gives a star with -corners
// points whose inner vertices lie at 0.382 of the outer radius.
tvg::Shape* aviutl_figure(int corners, float w, float h) {
  tvg::Shape* s = tvg::Shape::gen();
  if (corners == 0) return s->appendCircle(w / 2, h / 2, w / 2, h / 2), s;
  if (corners == 4 || corners == 1) return s->appendRect(0, 0, w, h), s;
  const int n = corners < 0 ? -2 * corners : corners;
  for (int i = 0; i < n; ++i) {
    const double a = (corners < 0 ? M_PI * i / -corners
                                  : 2 * M_PI * i / corners) -
                     M_PI / 2,
                 k = corners < 0 && i % 2 ? 0.382 : 1.0;
    const float x = (float)(w / 2 + std::cos(a) * w / 2 * k),
                y = (float)(h / 2 + std::sin(a) * h / 2 * k);
    i ? s->lineTo(x, y) : s->moveTo(x, y);
  }
  return s->close(), s;
}

// Returns the path of a font file for the font called `name`, found as macOS
// finds it (CoreText): by family name, face name or display name, using the
// bold and italic faces when they exist. If the font is not found, or the file
// is one ThorVG cannot read (such as a .ttc collection), returns the app's
// default text font (wsTextFont in app/lib/workspace/state/window.dart).
// `*slant` is set when italic was requested but the face found is not italic,
// so the caller must slant the text.
std::string aviutl_font_file(const std::string& name, bool bold, bool italic,
                             bool* slant) {
  std::string file;
  bool sloped = false;
#ifdef __APPLE__
  CFStringRef said = name.empty()
                         ? nullptr
                         : CFStringCreateWithCString(nullptr, name.c_str(),
                                                     kCFStringEncodingUTF8);
  for (CFStringRef by : {kCTFontFamilyNameAttribute, kCTFontNameAttribute,
                         kCTFontDisplayNameAttribute}) {
    if (!said || !file.empty()) break;
    const void* keys[] = {by};
    const void* values[] = {said};
    CFDictionaryRef asked = CFDictionaryCreate(
        nullptr, keys, values, 1, &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    CFSetRef must = CFSetCreate(nullptr, keys, 1, &kCFTypeSetCallBacks);
    CTFontDescriptorRef wanted = CTFontDescriptorCreateWithAttributes(asked);
    if (CTFontDescriptorRef found =
            CTFontDescriptorCreateMatchingFontDescriptor(wanted, must)) {
      CTFontRef font = CTFontCreateWithFontDescriptor(found, 12, nullptr);
      const CTFontSymbolicTraits traits =
          (bold ? kCTFontBoldTrait : 0) | (italic ? kCTFontItalicTrait : 0);
      if (CTFontRef faced = traits ? CTFontCreateCopyWithSymbolicTraits(
                                         font, 12, nullptr, traits, traits)
                                   : nullptr)
        CFRelease(font), font = faced;
      sloped = italic && !(CTFontGetSymbolicTraits(font) & kCTFontItalicTrait);
      if (CFURLRef url =
              (CFURLRef)CTFontCopyAttribute(font, kCTFontURLAttribute)) {
        char path[4096];
        if (CFURLGetFileSystemRepresentation(url, true, (UInt8*)path,
                                             sizeof path))
          file = path;
        CFRelease(url);
      }
      CFRelease(font), CFRelease(found);
    }
    CFRelease(wanted), CFRelease(must), CFRelease(asked);
  }
  if (said) CFRelease(said);
#endif
  const std::string ext = std::filesystem::path(file).extension().string();
  if (file.empty() ||
      (ext != ".ttf" && ext != ".otf" && ext != ".TTF" && ext != ".OTF") ||
      tvg::Text::load(file.c_str()) != tvg::Result::Success) {
#ifdef _WIN32
    file = "C:/Windows/Fonts/arial.ttf";
#else
    file = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf";
#endif
    sloped = italic;
  }
  return *slant = sloped, file;
}

// Implements obj.load "text": draws `words` into an image just large enough for
// them, using the font, size, color and decoration set by obj.setfont. Returns
// nullptr if nothing can be drawn. With empty text the caller makes the object
// one clear pixel instead.
//
// If `measured` is not null, nothing is drawn: measured[0] and measured[1]
// receive the width and height the text would take, and the result is nullptr.
//
// The layout follows YMM4-LuaScript (routersys, MIT, TextRenderer.Render, the
// layout's own box). Text is set with ThorVG text as for Motolii's text layers
// (canvas_renderables.h): ThorVG sizes are in points while AviUtl's are in
// pixels, hence the factor 72 / 96.
//
// The decorations follow sashimono-edit's measurements of AviUtl2 v2.1.6a (MIT,
// compat/decoration.py DECORATIONS, indexed by obj.setfont's number in the
// order of mapping.py _DECORATION_BY_INDEX):
//   - 1 and 2 are a shadow offset 5 hundredths of the size right and down. 2 is
//   the lighter
//     shadow, half as strong. The shadow is drawn in the edge color.
//   - 3 to 6 are outlines of 8, 4, 12 and 4 hundredths of the size outside the
//   letters (outline,
//     thin, thick and square-cornered), in the edge color.
const AviutlBuf* aviutl_text(AviutlRun& r, const std::string& words,
                             uint32_t* measured = nullptr) {
  const auto& f = r.font;
  const double size = std::clamp(f.size, 1.0, 4096.0);
  const int deco = (int)f.deco, colour = (int)f.colour, edge = (int)f.edge;
  static const double edges[] = {0, 0, 0, 0.08, 0.04, 0.12, 0.04};
  const float out = (float)(size * (deco >= 0 && deco <= 6 ? edges[deco] : 0)),
              down = deco == 1 || deco == 2 ? (float)(0.05 * size) : 0.f;
  const std::string key = "text|" + f.name + "|" + std::to_string(size) + "|" +
                          std::to_string(deco) + "|" + std::to_string(colour) +
                          "|" + std::to_string(edge) + "|" +
                          std::to_string(f.bold) + std::to_string(f.italic) +
                          "|" + words;
  if (!measured) r.worded.insert(key);
  if (const auto cached = r.loaded.find(key); cached != r.loaded.end())
    return measured &&
               (measured[0] = cached->second.w, measured[1] = cached->second.h),
           &cached->second;
  bool slant = false;
  const std::string file = aviutl_font_file(f.name, f.bold, f.italic, &slant);
  if (tvg::Text::load(file.c_str()) != tvg::Result::Success) return nullptr;
  const auto set = [&](int c, uint8_t a) {
    tvg::Text* t = tvg::Text::gen();
    // ThorVG names a font by its file name without the extension.
    t->font(std::filesystem::path(file).stem().string().c_str());
    t->size((float)(size * 72.0 / 96.0));
    t->text(words.c_str());
    if (slant) t->italic();
    t->fill((c >> 16) & 255, (c >> 8) & 255, c & 255);
    t->opacity(a);
    return t;
  };
  tvg::Scene* all = tvg::Scene::gen();
  if (down > 0.f) {
    tvg::Text* shadow = set(edge, deco == 2 ? 128 : 255);
    shadow->translate(down, down);
    all->add(shadow);
  }
  if (out > 0.f) {
    tvg::Text* rim = set(edge, 255);
    // The stroke is centered on the glyph edge, so draw it twice as wide; the
    // inner half is hidden by the letters drawn on top of it.
    rim->outline(2.f * out, (edge >> 16) & 255, (edge >> 8) & 255, edge & 255);
    all->add(rim);
  }
  all->add(set(colour, 255));
  float x = 0, y = 0, w = 0, h = 0;
  if (all->bounds(&x, &y, &w, &h) != tvg::Result::Success || w <= 0.f ||
      h <= 0.f)
    return tvg::Paint::rel(all), nullptr;
  if (measured)
    return measured[0] = (uint32_t)std::ceil(w),
           measured[1] = (uint32_t)std::ceil(h), tvg::Paint::rel(all), nullptr;
  all->translate(-x, -y);
  bool given = false;
  const AviutlBuf* built =
      aviutl_canvas(r, key, (uint32_t)std::ceil(w), (uint32_t)std::ceil(h),
                    [&](tvg::SwCanvas* c) {
                      return given = true, c->add(all) == tvg::Result::Success;
                    });
  if (!given) tvg::Paint::rel(all);
  return built;
}

}  // namespace

const AviutlBuf* aviutl_image(AviutlRun& r, std::string file) {
  if (!file.empty() && file[0] != '/')
    file = (std::filesystem::path(r.file).parent_path() / file).string();
  std::error_code wrong;
  if (file.empty() || !std::filesystem::is_regular_file(file, wrong))
    return nullptr;
  float w = 0, h = 0;
  tvg::Picture* p = tvg::Picture::gen();
  const bool read = p->load(file.c_str()) == tvg::Result::Success &&
                    p->size(&w, &h) == tvg::Result::Success && w >= 1 && h >= 1;
  delete p;
  if (!read) return nullptr;
  const auto at = std::filesystem::last_write_time(file, wrong);
  return aviutl_canvas(
      r,
      "image|" + file + "|" +
          std::to_string((long long)at.time_since_epoch().count()),
      (uint32_t)std::lround(w), (uint32_t)std::lround(h),
      [&](tvg::SwCanvas* c) {
        tvg::Picture* q = tvg::Picture::gen();
        return q->load(file.c_str()) == tvg::Result::Success &&
               c->add(q) == tvg::Result::Success;
      });
}

int aviutl_load(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string kind = aviutl_str(L, 1);
  if (kind == "tempbuffer" && lua_gettop(L) == 1 && r.bufs.count(kind))
    return aviutl_copy(r, "object", kind), lua_pushboolean(L, 1), 1;
  // Replaces the object with `from`, a new object buffer of the same size.
  // Pushes false if `from` is null.
  const auto lay = [&](const AviutlBuf* from) {
    if (!from) return lua_pushboolean(L, 0), 1;
    const AviutlBuf& to = aviutl_buf(r, "object", from->w, from->h);
    aviutl_lay(r, *from, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
    return lua_pushboolean(L, 1), 1;
  };
  if (kind == "figure") {
    const std::string name = aviutl_str(L, 2);
    const auto f = aviutl_figures.find(name);
    if (f == aviutl_figures.end())
      return aviutl_no(L, "obj.load figure " + name);
    const int colour = (int)aviutl_num(L, 3, 0xffffff),
              size = (int)std::clamp(aviutl_num(L, 4, 100), 1.0, 4096.0);
    const uint32_t w = f->second == 1 ? (uint32_t)r.s->w : (uint32_t)size,
                   h = f->second == 1 ? (uint32_t)r.s->h : (uint32_t)size;
    double line = aviutl_num(L, 5, 0);
    if (line >= std::min(4000.0, (double)std::max(w, h))) line = 0;
    if (lua_gettop(L) >= 6 && aviutl_num(L, 6) != 0)
      return aviutl_no(L, "obj.load figure with round corners");
    // A filled square needs no drawing: clear the buffer to the color.
    if (f->second == 4 && line <= 0) {
      aviutl_clear(r, aviutl_buf(r, "object", w, h), colour, true);
      return lua_pushboolean(L, 1), 1;
    }
    const uint8_t cr = (colour >> 16) & 255, cg = (colour >> 8) & 255,
                  cb = colour & 255;
    return lay(aviutl_canvas(
        r,
        "figure|" + name + "|" + std::to_string(colour) + "|" +
            std::to_string(w) + "x" + std::to_string(h) + "|" +
            std::to_string(line),
        w, h, [&](tvg::SwCanvas* c) {
          tvg::Shape* s = aviutl_figure(f->second, (float)w, (float)h);
          if (line <= 0)
            return s->fill(cr, cg, cb), c->add(s) == tvg::Result::Success;
          // The stroke is centered on the outline, so draw it twice as wide and
          // clip it to the figure. Only the inner half remains.
          s->fill(0, 0, 0, 0), s->strokeWidth((float)(2 * line)),
              s->strokeFill(cr, cg, cb);
          s->clip(aviutl_figure(f->second, (float)w, (float)h));
          return c->add(s) == tvg::Result::Success;
        }));
  }
  if (kind == "image") return lay(aviutl_image(r, aviutl_str(L, 2)));
  // obj.load("framebuffer"[, x, y, w, h, alpha]) loads the w x h part of the
  // frame whose top left corner is at x, y (lua.txt). Unless alpha is
  // requested, the part is laid over black, as it appears on the screen.
  if (kind == "framebuffer") {
    const AviutlBuf fb = r.bufs["framebuffer"];
    if (!fb.t) return lua_pushboolean(L, 0), 1;
    const double x = aviutl_num(L, 2, 0), y = aviutl_num(L, 3, 0);
    const uint32_t w = lua_isnumber(L, 4)
                           ? (uint32_t)std::clamp(
                                 std::lround(lua_tonumber(L, 4)), 1L, 8192L)
                           : fb.w,
                   h = lua_isnumber(L, 5)
                           ? (uint32_t)std::clamp(
                                 std::lround(lua_tonumber(L, 5)), 1L, 8192L)
                           : fb.h;
    const AviutlBuf& to = aviutl_buf(r, "object", w, h);
    aviutl_clear(r, to, 0, !lua_toboolean(L, 6));
    aviutl_lay(r, fb, to.rt, w, h, fb.w / 2.0 - x - w / 2.0,
               fb.h / 2.0 - y - h / 2.0, 1, 1, 0, 1, 0, 0, 0, 1);
    return lua_pushboolean(L, 1), 1;
  }
  // obj.load("text.layout", words) returns the width and height the words would
  // take when set, and leaves the object as it is (lua.txt, text layout).
  if (kind == "text.layout") {
    uint32_t size[2] = {0, 0};
    if (lua_isstring(L, 2) && *lua_tostring(L, 2))
      aviutl_text(r, lua_tostring(L, 2), size);
    return lua_pushinteger(L, size[0]), lua_pushinteger(L, size[1]), 2;
  }
  if (kind == "text") {
    const std::string words = lua_isstring(L, 2) ? lua_tostring(L, 2) : "";
    if (words.empty())
      return aviutl_clear(r, aviutl_buf(r, "object", 1, 1), 0, false),
             lua_pushboolean(L, 1), 1;
    return lay(aviutl_text(r, words));
  }
  return aviutl_no(
      L, "obj.load " + kind + (kind == "figure" ? " " + aviutl_str(L, 2) : ""));
}

}  // namespace motolii

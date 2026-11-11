#include "document/scripts/expressions.h"

#include <algorithm>
#include <cstddef>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#include "community/css/css.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "document/document.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/scripts.h"
#include "stage/render/render_stage.h"

namespace motolii {

bool doc_expression(Doc& d, const std::string& file) {
  const std::filesystem::path ext =
      std::filesystem::path(fx_source(file)).extension();
  // A CSS page moves the letters of a split text (doc_css_lay).
  if (ext == ".css") return true;
  if (ext != ".js") return false;
  const DocScript* sc = doc_script_of(d, file);
  return sc && sc->run && sc->run->lays();
}

std::vector<std::string> doc_fx_drawn(Doc& d, std::vector<std::string> list) {
  std::erase_if(list,
                [&](const std::string& w) { return doc_expression(d, w); });
  return list;
}

std::vector<DocScript*> doc_expressions_fx(Doc& d, int layer) {
  std::vector<DocScript*> all;
  if (layer != 0)
    for (const std::string& file : doc_fx_list(d, layer))
      if (doc_expression(d, file))
        if (DocScript* sc = doc_script_of(d, file);
            sc && (sc->run ? sc->run->ok() : !sc->css.empty()))
          all.push_back(sc);
  return all;
}

std::vector<DocScript*> doc_expressions_on(Doc& d, int layer) {
  std::vector<DocScript*> all;
  if (DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script"));
      sc && sc->run && sc->run->ok())
    all.push_back(sc);
  for (DocScript* sc : doc_expressions_fx(d, layer)) all.push_back(sc);
  return all;
}

std::string doc_macro_adds(Doc& d, int layer, const char* name, double at,
                           double* adds) {
  *adds = 0;
  for (DocScript* sc : doc_expressions_on(d, layer))
    for (size_t i = 0; i < sc->parameters.size(); ++i)
      if (sc->names[i] == name && !sc->parameters[i].by.empty())
        for (size_t j = 0; j < sc->parameters.size(); ++j)
          if (sc->parameters[j].name == sc->parameters[i].by) {
            const ScriptParameter& macro = sc->parameters[j];
            const double v =
                doc_number(d, layer, sc->names[j].c_str(), at, macro.usual);
            for (const ScriptParameter::Turned& t : macro.turns)
              if (t.name == sc->parameters[i].name)
                *adds = (t.high - t.low) * (v - macro.usual);
            return macro.label;
          }
  return "";
}

std::string doc_macro_over(Doc& d, int layer, const char* name, double at,
                           double* is) {
  double adds = 0;
  const std::string by = doc_macro_adds(d, layer, name, at, &adds);
  return *is += adds, by;
}

double doc_macro_own(Doc& d, int layer, const char* name, double at,
                     double is) {
  double adds = 0;
  return doc_macro_adds(d, layer, name, at, &adds), is - adds;
}

namespace {
// Composes copy `o` onto copy `c`. This is how a layer's own placement applies
// to its script's copy (doc_place): positions and rotations add, sizes, scales
// and opacity multiply, and a color set by `o` replaces the color of `c`.
// Matrices multiply, `o`'s applied first.
void doc_expression_over(ScriptCopy& c, const ScriptCopy& o) {
  double m[16] = {};
  for (int col = 0; col < 4; ++col)
    for (int row = 0; row < 4; ++row)
      for (int k = 0; k < 4; ++k)
        m[col * 4 + row] += c.matrix[k * 4 + row] * o.matrix[col * 4 + k];
  std::copy(m, m + 16, c.matrix);
  c.x += o.x, c.y += o.y, c.z += o.z, c.rotate += o.rotate,
      c.rotate_x += o.rotate_x, c.rotate_y += o.rotate_y;
  c.size *= o.size, c.scale_x *= o.scale_x, c.scale_y *= o.scale_y,
      c.scale_z *= o.scale_z, c.opacity *= o.opacity;
  if (o.colour >= 0) c.colour = o.colour;
}

// The copies a .css expression lays: the letters (or words) of a split text,
// moved as the pen's page moves them at `clock` seconds (community/css/css.h).
// Its boxes are where the text lays its letters, in project pixels, one CSS
// pixel each (`px` stage units); its y runs down, the stage's up.
std::vector<ScriptCopy> doc_css_lay(Doc& d, int layer, DocScript& sc, int n,
                                    double clock, double px) {
  std::vector<ScriptCopy> made((size_t)std::max(0, n));
  const auto sh = d.on_stage.shown.find(layer);
  if (sh == d.on_stage.shown.end() || !sh->second.drawn) return made;
  const std::vector<filament::math::float2>& letters =
      sh->second.drawn->letters;
  const std::string words = doc_word(d, layer, "text");
  const bool by_words = doc_word(d, layer, "split") == "words";
  filament::math::float2 half{0.5f};
  doc_half(d, layer, &half);
  // The size the letters are drawn at, in project pixels: the page's em.
  const float font = (float)(sh->second.drawn->em * 2.0 * half.y / px);
  DocScript::Page& p = sc.pages[layer];
  const std::string key = words + (by_words ? "\n1\n" : "\n0\n") +
                          std::to_string(font);
  if (!p.page || p.made_for != key) {
    const double high = doc_number(d, 0, "high", 0, 1080);
    p.made_for = key;
    p.page = std::shared_ptr<MotoliiCss>(
        motolii_css_new(sc.css.c_str(), sc.html.c_str(), words.c_str(), 0,
                        by_words, (uint32_t)(high * d.stage->w / d.stage->h),
                        (uint32_t)high, font),
        motolii_css_free);
  }
  const size_t m = std::min(made.size(), letters.size());
  std::vector<float> boxes;
  // Each letter's box as a pen lays it: across, from where it is set to its
  // advance; up and down, the font's line (the content area, which css.rs
  // sizes to the pen's line-height). Its middle is not the letter's middle.
  const filament::math::float2 line = sh->second.drawn->line;
  const std::vector<filament::math::float2>& across =
      sh->second.drawn->boxes;
  const auto box = [&](size_t i) {
    return i < across.size() ? across[i]
                             : filament::math::float2{
                                   letters[i].x, letters[i].y - letters[i].x};
  };
  for (size_t i = 0; i < m; ++i) {
    const filament::math::float2 b = box(i);
    boxes.insert(boxes.end(),
                 {(float)((b.x * 2.f - 1.f) * half.x / px),
                  (float)((line.x * 2.f - 1.f) * half.y / px),
                  (float)(b.y * 2.f * half.x / px),
                  (float)((line.y - line.x) * 2.f * half.y / px)});
  }
  std::vector<double> out(m * 17);
  if (!p.page || motolii_css_at(p.page.get(), clock, boxes.data(), (int32_t)m,
                                out.data()) != (int32_t)m)
    return made;
  // Each matrix moves the letter about its box's middle. Made about the
  // letter's middle (doc_letter_middle) instead, the box's middle being `o`
  // from it: T(o) M T(-o), which adds o - M o to the translation.
  const double oy = (line.x + line.y - 1.0) * half.y / px;
  for (size_t i = 0; i < m; ++i) {
    const filament::math::float2 b = box(i);
    const double ox =
        (2.0 * b.x + b.y - letters[i].x - letters[i].y) * half.x / px;
    double* a = &out[i * 17 + 1];
    for (int row = 0; row < 3; ++row)
      a[12 + row] += (row == 0 ? ox : row == 1 ? oy : 0.0) -
                     a[row] * ox - a[4 + row] * oy;
  }
  // From CSS pixels, y down, to stage units, y up: each entry (row, column)
  // times s[row] / s[column].
  const double s[4] = {px, -px, px, 1};
  for (size_t i = 0; i < m; ++i) {
    made[i].opacity = out[i * 17];
    for (int col = 0; col < 4; ++col)
      for (int row = 0; row < 4; ++row)
        made[i].matrix[col * 4 + row] =
            out[i * 17 + 1 + col * 4 + row] * s[row] / s[col];
  }
  return made;
}
}  // namespace

std::vector<ScriptCopy> doc_expressions_lay(Doc& d, int layer,
                                            const std::vector<DocScript*>& scs,
                                            int n, double said, double clock,
                                            double gone) {
  std::vector<ScriptCopy> all;
  for (DocScript* sc : scs) {
    std::map<std::string, double> numbers;
    std::map<std::string, std::string> words;
    for (size_t i = 0; i < sc->parameters.size(); ++i) {
      if (sc->parameters[i].kind == "select") {
        const std::string w = doc_word(d, layer, sc->names[i].c_str());
        words[sc->parameters[i].name] =
            w.empty() ? sc->parameters[i].words.substr(
                            0, sc->parameters[i].words.find(' '))
                      : w;
      } else
        numbers[sc->parameters[i].name] = doc_number(
            d, layer, sc->names[i].c_str(), said, sc->parameters[i].usual);
    }
    // A macro adds to the parameters it turns: Min + (Max - Min) * macro, minus
    // the macro's value at its default. See doc_macro_adds.
    for (size_t i = 0; i < sc->parameters.size(); ++i) {
      const double v = doc_number(d, layer, sc->names[i].c_str(), said,
                                  sc->parameters[i].usual);
      for (const ScriptParameter::Turned& t : sc->parameters[i].turns)
        numbers[t.name] += (t.high - t.low) * (v - sc->parameters[i].usual);
    }
    // How long the layer lasts. An Out ends it earlier, hence `gone`.
    numbers["duration"] =
        doc_literal(d, layer, "duration", 0, -1) +
        (doc_literal(d, layer, "duration", 0, -1) > 0.0 ? gone : 0.0);
    // How long the project runs, so that a flow goes round a whole number of
    // times in it.
    numbers["round"] = d.on_stage.round;
    // The fourth argument is the size of one project pixel in stage units at
    // the layer's depth. The last argument is the copies laid by the earlier
    // scripts, the fifth argument of each(); see script_runner.h.
    const double px =
        (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) *
                                               doc_point(d, layer, said));
    // A page's pixel is a project pixel as the letters are seen. The letters
    // are laid at size 1 and the layer's size scales them afterwards, so
    // one such pixel is that many times smaller where they are laid.
    const std::vector<ScriptCopy> made =
        sc->run ? sc->run->copies(n, clock, numbers, words, px, all)
                : doc_css_lay(d, layer, *sc, n, clock,
                              px / std::max(1e-6, doc_number(d, layer, "size",
                                                             said, 1)));
    if (all.empty())
      all = made;
    else
      for (size_t i = 0; i < all.size() && i < made.size(); ++i)
        doc_expression_over(all[i], made[i]);
  }
  return all;
}

std::string doc_expressions_said(Doc& d, int layer) {
  std::string all = doc_literal_word(d, layer, "script");
  for (const std::string& file : doc_fx_list(d, layer)) all += " " + file;
  return all;
}

}  // namespace motolii

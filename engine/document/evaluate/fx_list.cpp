#include "document/evaluate/fx_list.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "community/aviutl/aviutl.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/edit/keys_put.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"

namespace motolii {

std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off) {
  std::vector<std::string> said, all;
  const std::string hidden =
      off ? std::string() : ";" + doc_word(d, layer, "fx_off") + ";";
  const auto seen = [&](const std::string& w) {
    return hidden.size() <= 2 ||
           hidden.find(";" + doc_fx_title(w) + ";") == std::string::npos;
  };
  // Glow is not a step of the stack. It is Filament's bloom; see doc_evaluate.
  for (const std::string& w : script_files(doc_word(d, layer, "fx")))
    if (w != "none" && w != "glow") said.push_back(w);
  for (const std::string& w : said)
    if (seen(w)) all.push_back(w);
  // Add the effect being dragged onto the layer, as it is drawn; see
  // doc_carry_effect.
  if (!off && d.held.layer == layer)
    if (const auto e = d.held.said.find(" effect");
        e != d.held.said.end() &&
        std::find(all.begin(), all.end(), e->second) == all.end())
      all.push_back(e->second);
  return all;
}
bool doc_fx_files(const std::vector<std::string>& list) {
  // These file types are not effect files. A splat effect belongs to the point
  // cloud's own look. The motion of AbsentMotion moves the layer; see
  // engine/community/absent_motion/absent_motion.h.
  // Filament's own settings belong to the stage.
  return std::any_of(list.begin(), list.end(), [](const std::string& w) {
    const std::string ext = std::filesystem::path(w).extension().string();
    return ext != ".mjs" && ext != ".am" && ext != ".json";
  });
}
std::vector<std::string> doc_fx_steps(Doc& d, int layer) {
  // Expressions are not drawn; see expressions.h.
  std::vector<std::string> steps = doc_fx_drawn(d, doc_fx_list(d, layer));
  for (std::string& w : steps)
    if (std::filesystem::path(w).extension() == ".am")
      if (const DocScript* sc = doc_script_of(d, w);
          sc && (sc->absent == "motionblur" || sc->absent == "shutterblur"))
        w = (std::filesystem::path(w).parent_path() / "am_directionalblur.wgsl")
                .string();
  return steps;
}
std::string doc_fx_join(const std::vector<std::string>& list) {
  std::string all;
  for (const std::string& w : list) all += (all.empty() ? "" : " ") + w;
  return all;
}
double doc_most(Doc& d, int layer, const char* name, double otherwise) {
  double most = doc_number(d, layer, name, 0, otherwise);
  if (doc_keys(d, layer, name, -1.0))
    doc_rows(
        d,
        sqlite3_mprintf(
            "select max(value) from keyframe where layer = %d and name = %Q",
            layer, name),
        [&](sqlite3_stmt* row) { most = sqlite3_column_double(row, 0); });
  return most;
}
bool doc_fx(Doc& d, int layer, double at, bool most, Canvas2DFx& fx,
            std::string& why) {
  const auto num = [&](const char* name, double otherwise) {
    return most ? doc_most(d, layer, name, otherwise)
                : doc_number(d, layer, name, at, otherwise);
  };
  bool ok = true;
  // Expressions lay copies and are not drawn.
  for (const std::string& w : doc_fx_drawn(d, doc_fx_list(d, layer))) {
    // The file is resolved as a canvas layer's own file is, see doc_match. An
    // effect put on again uses its own file, see fx_source.
    if (!std::filesystem::is_regular_file(aviutl_is(w) ? aviutl_path(w)
                                                       : fx_source(w)))
      ok = false, why = "there is no such file: " + w;
    // The ISF effect is converted to WGSL once and cached; see isf.cpp.
    else if (isf_file(w).empty())
      ok = false, why = "the ISF effect could not be made WGSL: " + w;
  }
  fx.reach =
      (float)(std::max(0.0, num("offset", 0)) + std::fabs(num("zigzag", 0)) +
              0.5 * std::max(0.0, num("bloat", 0)) + std::fabs(num("warp", 0)));
  return ok;
}

}  // namespace motolii

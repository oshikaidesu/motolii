#include "document/evaluate/fx_list.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "community/aviutl/aviutl.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "community/three/solid_three.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/edit/keys_put.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "stage/layer_effects/layer_fx.h"

namespace motolii {

std::vector<std::string> doc_fx_entries(Doc& d, int layer, bool off) {
  std::vector<std::string> said, all;
  const std::string hidden =
      off ? std::string() : ";" + doc_word(d, layer, "fx_off") + ";";
  const auto seen = [&](const std::string& w) {
    return hidden.size() <= 2 ||
           hidden.find(";" + doc_fx_title(w) + ";") == std::string::npos;
  };
  for (const std::string& w : script_files(doc_word(d, layer, "fx")))
    if (w != "none") said.push_back(w);
  for (const std::string& w : said)
    if (seen(w)) all.push_back(w);
  // Add the effect being dragged onto the layer, as it is drawn; see
  // doc_carry_effect.
  if (!off && d.held.layer == layer)
    if (const auto e = d.held.said.find(" effect");
        e != d.held.said.end() &&
        std::none_of(all.begin(), all.end(), [&](const std::string& w) {
          return fx_entry_path(w) == e->second;
        }))
      all.push_back(e->second);
  return all;
}

std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off) {
  std::vector<std::string> all = doc_fx_entries(d, layer, off);
  for (std::string& w : all) w = fx_entry_path(w);
  return all;
}

std::string doc_fx_values_id(Doc& d, const std::string& entry) {
  const std::string id = fx_entry_id(entry), file = fx_entry_path(entry);
  if (id.empty() || doc_expression(d, file)) return "";
  // As thing_effects (layer_fx.cpp) chooses what it builds as a shader.
  const std::string ext =
      std::filesystem::path(file).extension().generic_string();
  return aviutl_is(file) || ext == ".mjs" || ext == ".am" || ext == ".json" ||
                 solid_is(file) || points_is(file)
             ? ""
             : id;
}

bool doc_fx_files(const std::vector<std::string>& list) {
  // These file types are not effect files. A splat effect belongs to the point
  // cloud's own look. The motion of AbsentMotion moves the layer; see
  // engine/community/absent_motion/absent_motion.h.
  // Filament's own settings belong to the stage.
  return std::any_of(list.begin(), list.end(), [](const std::string& w) {
    const std::string ext =
        std::filesystem::path(w).extension().generic_string();
    return ext != ".mjs" && ext != ".am" && ext != ".json";
  });
}
std::vector<std::string> doc_fx_steps_with_ids(Doc& d, int layer) {
  // An entry keeps its ID only where what draws it reads its values by it.
  std::vector<std::string> result;
  for (const std::string& w : doc_fx_entries(d, layer)) {
    const std::string id = doc_fx_values_id(d, w);
    std::string path = fx_entry_path(w);
    if (doc_expression(d, path)) continue;
    if (std::filesystem::path(path).extension() == ".am")
      if (const DocScript* sc = doc_script_of(d, path);
          sc && (sc->absent == "motionblur" || sc->absent == "shutterblur"))
        path = (std::filesystem::path(path).parent_path() /
                "am_directionalblur.wgsl")
                   .generic_string();
    result.push_back(id.empty() ? path : id + ":" + path);
  }
  return result;
}

std::vector<std::string> doc_fx_steps(Doc& d, int layer) {
  std::vector<std::string> result;
  for (const std::string& w : doc_fx_steps_with_ids(d, layer))
    result.push_back(fx_entry_path(w));
  return result;
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
  // Carry the path operators at their largest. place_canvas bends the real path
  // by these and fits the image to where the bent outline reaches, so the box
  // follows the geometry itself -- every operator, present or future, lopsided
  // or not -- instead of a guess made from the values here.
  fx.round = (float)num("round", 0);
  fx.bloat = (float)num("bloat", 0);
  fx.zigzag = (float)num("zigzag", 0);
  fx.ridges = (float)num("zigzag_ridges", 5);
  fx.smooth = (float)num("zigzag_smooth", 0);
  fx.offset = (float)num("offset", 0);
  return ok;
}

}  // namespace motolii

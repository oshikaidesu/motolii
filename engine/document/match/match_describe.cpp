#include "document/match/match_describe.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstring>
#include <filesystem>
#include <map>
#include <string>
#include <system_error>

#include "document/card_table.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/match.h"
#include "document/match/match_look.h"
#include "document/match/match_shape.h"
#include "document/match/match_video.h"
#include "document/match/rebuild.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace {

// Returns true for metallic, roughness and reflectance on a layer that is not a
// solid. A solid is rebuilt when these change. A flat layer (a sheet) has them
// evaluated at each time (evaluate.h) and its image is left alone.
bool doc_sheet_told(Doc& d, int layer, const std::string& name) {
  return doc_among("metallic roughness reflectance", name.c_str()) &&
         doc_word(d, layer, "kind") != "solid";
}

// Reads from the project, for each layer, the text of every property its
// construction depends on.
void told_properties(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  std::map<int, std::string>& told = rebuild.told;
  doc_rows(
      d,
      sqlite3_mprintf(
          "select layer, group_concat(name || '=' || value, ' ') from (select "
          "* from keyframe where layer > 0 and (name in (%s) or name glob "
          "'*_by') and not (name in ('metallic', 'roughness', 'reflectance') "
          "and layer in (select layer from keyframe where name = 'kind' and "
          "value != 'solid')) order by layer, name) group by layer",
          doc_making),
      [&](sqlite3_stmt* row) {
        told[sqlite3_column_int(row, 0)] =
            (const char*)sqlite3_column_text(row, 1);
      });
}

// Makes the blend modes that are drawn the same way compare equal.
void told_blend_modes_alike(Rebuild& rebuild) {
  std::map<int, std::string>& told = rebuild.told;
  // Every blend mode that reads the pixels underneath is drawn the same way, as
  // normal, and flat.mat mixes it. Switching between them changes only the look
  // and needs no rebuild, so replace the mode with * to make them compare
  // equal.
  for (auto& [layer, of] : told)
    if (const size_t at = of.find("blend="); at != std::string::npos) {
      const size_t end = of.find(' ', at);
      if (doc_blend_way(of.substr(at + 6, end == std::string::npos
                                              ? std::string::npos
                                              : end - at - 6)))
        of.replace(at + 6,
                   (end == std::string::npos ? of.size() : end) - at - 6, "*");
    }
}

// Adds when the file of a p5.js sketch or of a three.js part was last written,
// so the layer is rebuilt when its code changes.
void told_files_written(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  std::map<int, std::string>& told = rebuild.told;
  for (auto& [layer, of] : told) {
    if (of.find("kind=image") != std::string::npos)
      if (const std::string file = doc_word(d, layer, "file");
          std::filesystem::path(file).extension() == ".js")
        of += " written=" + std::to_string(doc_sketch_written(d, file));
    // A three.js part is rebuilt from its code when the file changes; see
    // doc_three_saved.
    if (of.find("kind=solid") != std::string::npos)
      if (const std::string file = doc_word(d, layer, "file");
          std::filesystem::path(file).extension() == ".glb") {
        std::error_code wrong;
        of += " written=" +
              std::to_string(
                  (long long)std::filesystem::last_write_time(file, wrong)
                      .time_since_epoch()
                      .count());
      }
  }
}

// Adds whether the layer bends.
void told_bending(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  std::map<int, std::string>& told = rebuild.told;
  // Whether the layer bends: tessellated finely, or subdivided only around its
  // curves.
  for (auto& [layer, of] : told)
    of += doc_bends(d, layer) ? " bent=1" : " bent=0";
}

// Adds what the layer's effects and its depth, light, words and drawing need
// of its construction.
void told_effects(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  Stage& s = rebuild.s;
  std::map<int, std::string>& told = rebuild.told;
  // Effects: record which are on and how much room they need, but not their
  // parameter values.
  for (auto& [layer, of] : told) {
    const auto on = [&](const char* name) {
      return std::max(doc_most(d, layer, name, 0),
                      doc_number(d, layer, name, 0, 0)) > 0.0;
    };
    // Rebuilt once its datamosh has been rendered.
    if (doc_on(d, layer, "mosh")) of += " moshed=" + doc_mosh(d, layer);
    // Rebuilt when it is given depth, because its sheet then becomes a box.
    if (doc_on(d, layer, "scale_z")) of += " deep";
    if (doc_bevel(d, layer)) of += " bevel";
    // Rebuilt when a light is added or removed.
    if (doc_lit(d, layer)) of += " lit";
    // The text as the text effects show it now. Rebuilt when it changes.
    if (of.find("kind=text") != std::string::npos)
      of += " shown=" + doc_text_shown(d, layer, s.now);
    // The drawing of a level shown now. Rebuilt when its keyframes change it.
    if (of.find("kind=image") != std::string::npos &&
        !doc_keys_of(d, layer, "cel").at.empty())
      of += " cel=" + std::to_string(std::llround(doc_cel(d, layer, s.now)));
    of += " order=" + doc_fx_join(doc_fx_list(d, layer)) +
          " fx=" + std::to_string((int)on("blur")) +
          (doc_word(d, layer, "shadow").empty() ? "0" : "1") +
          (doc_word(d, layer, "glow").empty() ? "0" : "1") +
          std::to_string((int)on("tint")) + std::to_string((int)on("tritone")) +
          " room=" + std::to_string(doc_fx_room(d, layer));
  }
}

// Adds the values held by a drag in progress.
void told_held_values(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  std::map<int, std::string>& told = rebuild.told;
  // Values held by a drag in progress also count, so the layer is rebuilt as it
  // will be after the drag.
  if (const auto held = told.find(d.held.layer); held != told.end())
    for (const auto& [name, is] : d.held.said)
      if (name[0] != ' ') held->second += " " + name + "~" + is;
  if (const auto held = told.find(d.held.layer); held != told.end())
    for (const auto& [name, is] : d.held.tried)
      // A property that moves is redrawn at every time by doc_evaluate anyway.
      // It triggers a rebuild only when it switches on or off.
      if (strstr(doc_making, ("'" + name + "'").c_str()) &&
          !doc_sheet_told(d, d.held.layer, name)) {
        bool moves = false;
        for (const DocValue& one : doc_values)
          moves = moves || (one.moves && name == one.name);
        const auto from = d.held.from.find(name);
        if (!moves)
          held->second += " " + name + "~" + std::to_string(is);
        else if (from != d.held.from.end() &&
                 (from->second != 0.0) != (is != 0.0))
          held->second += " " + name + "~" + (is != 0.0 ? "on" : "off");
      }
}

}  // namespace

void match_describe_layers(Rebuild& rebuild) {
  told_properties(rebuild);
  told_blend_modes_alike(rebuild);
  told_files_written(rebuild);
  told_bending(rebuild);
  told_effects(rebuild);
  told_held_values(rebuild);
}

}  // namespace motolii

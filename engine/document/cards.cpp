#include "document/cards.h"

#include <sqlite3.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <map>
#include <utility>
#include <vector>

#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "document/card_table.h"
#include "document/edit/arrange.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "shelf/shelf_folders.h"
#include "stage/effects/thorvg_effect_names.h"

namespace motolii {

namespace {

// Returns the layer's script parameter called "name", or nullptr. Script
// parameter names start with "js_".
const DocValue* doc_script_value(Doc& d, int layer, const char* name) {
  if (strncmp(name, "js_", 3)) return nullptr;
  for (const DocScript* sc : doc_scripts_on(d, layer))
    for (const DocValue& one : sc->values)
      if (!strcmp(one.name, name)) return &one;
  return nullptr;
}

}  // namespace

bool doc_stay(Doc& d, int layer, const char* name, double at) {
  return doc_knows(d, layer, name) &&
         (!doc_keys(d, layer, name) ||
          doc_set(d, layer, name,
                  doc_number(d, layer, name, at, doc_usual(d, name))));
}

std::string doc_words(Doc& d, int layer, const char* name) {
  if (const DocValue* v = doc_script_value(d, layer, name))
    return v->words ? v->words : "";
  const std::string kind = doc_word(d, layer, "kind");
  if (!strcmp(name, "animation") && kind == "solid") {
    // The animations of the solid's file, as gltfio reads them.
    std::string all;
    if (const auto t = d.shown.find(layer);
        t != d.shown.end() && t->second.solid)
      for (const std::string& m : t->second.solid->moves)
        all += (all.empty() ? "" : " ") + m;
    return all;
  }
  if (!strcmp(name, "marker") && kind == "image") {
    // The named segments of the image's file, as ThorVG reads them. "all" plays
    // the whole file.
    std::string all = "all";
    if (const auto t = d.shown.find(layer);
        t != d.shown.end() && t->second.drawn)
      for (const std::string& m : t->second.drawn->markers) all += " " + m;
    return all;
  }
  for (const DocValue& one : doc_values)
    if (!strcmp(one.name, name) && doc_among(one.kinds, kind))
      return one.words ? one.words : "";
  return "";
}

std::string doc_name(Doc& d, int layer) {
  if (const std::string said = doc_word(d, layer, "name"); !said.empty())
    return said;
  if (doc_word(d, layer, "kind") == "camera") return "Camera";
  std::string is = doc_word(d, layer, "text");
  if (is.empty()) is = doc_word(d, layer, "shape");
  if (is.empty() && doc_word(d, layer, "kind") == "behaviour") {
    // A behavior is named by its file. When several share a file, the second
    // and later get a number, as Blender names duplicates with .001.
    const std::string file = doc_word(d, layer, "file");
    int nth = 0, all = 0;
    for (const int t : doc_layers(d))
      if (doc_word(d, t, "kind") == "behaviour" &&
          doc_word(d, t, "file") == file && doc_word(d, t, "name").empty()) {
        ++all;
        if (t <= layer) ++nth;
      }
    return all > 1 && nth > 1 ? file + " " + std::to_string(nth) : file;
  }
  // A light is named by its file, such as Sun, as the tile in the app shows it.
  if (is.empty() && doc_word(d, layer, "kind") == "light")
    is = doc_word(d, layer, "file");
  if (is.empty())
    return std::filesystem::path(doc_word(d, layer, "file"))
        .filename()
        .string();
  if (doc_word(d, layer, "kind") != "text")
    is[0] = (char)std::toupper((unsigned char)is[0]);
  // A multi-line text is listed on one line.
  std::replace(is.begin(), is.end(), '\n', ' ');
  return is;
}

std::string doc_moving(Doc& d, int layer) {
  const std::string kind = doc_word(d, layer, "kind");
  std::string names;
  for (const DocValue& one : doc_values)
    if (one.moves && doc_among(one.kinds, kind))
      names += std::string(names.empty() ? "" : " ") + one.name;
  if (doc_among("video image text shape solid stage camera behaviour", kind))
    // Also the script parameters that take keyframes, as doc_has lists them.
    for (const DocScript* sc : doc_scripts_on(d, layer))
      for (const DocValue& one : sc->values)
        if (one.moves)
          names += std::string(names.empty() ? "" : " ") + one.name;
  return names;
}

std::string doc_has(Doc& d, int layer) {
  const std::string kind = doc_word(d, layer, "kind");
  std::string names;
  for (const DocValue& one : doc_values)
    if (doc_among(one.kinds, kind))
      names += std::string(names.empty() ? "" : " ") + one.name;
  if (doc_among("video image text shape solid stage camera behaviour", kind))
    for (const DocScript* sc : doc_scripts_on(d, layer))
      for (const DocValue& one : sc->values)
        names += std::string(names.empty() ? "" : " ") + one.name;
  return names;
}

std::string doc_fx_title(const std::string& name) {
  if (const std::string source = fx_source(name); source != name) {
    // An effect duplicated from another: the title of its source plus its
    // number, such as "Glow 2". It has its own card.
    const std::string stem = std::filesystem::path(name).stem().string();
    return doc_fx_title(source) + " " + stem.substr(stem.rfind('~') + 1);
  }
  if (doc_thor_letter(name))
    for (const DocCard& card : doc_cards)
      if (card.when && card.is[0] == '+' && name == card.when)
        return card.title;
  // Title as the shelf names it: the name in the file's first comment line,
  // written by the file's author (see doc_folder_names). Cached per effect and
  // read again when files change.
  static std::map<std::string, std::pair<int, std::string>> named;
  if (auto& one = named[name];
      one.first == files_changed() && !one.second.empty())
    return one.second;
  else if (std::ifstream in(isf_file(name)); in) {
    std::string first;
    if (std::getline(in, first) && first.rfind("// ", 0) == 0 &&
        first.find(':') != std::string::npos)
      return (one = {files_changed(), first.substr(3, first.find(':') - 3)})
          .second;
  }
  std::string t = std::filesystem::path(name).stem().string();
  for (char& c : t)
    if (c == '_') c = ' ';
  if (!t.empty()) t[0] = (char)std::toupper((unsigned char)t[0]);
  return t;
}

std::string doc_fx_duplicate(Doc& d, int layer, const std::string& title) {
  std::vector<std::string> list = script_files(doc_word(d, layer, "fx"));
  const auto at = std::find_if(
      list.begin(), list.end(),
      [&](const std::string& w) { return doc_fx_title(w) == title; });
  if (at == list.end()) return d.error = "no effect of that name is on it", "";
  const std::string word = *at;
  const std::filesystem::path source(fx_source(word));
  if (source.extension() != ".fs" && source.extension() != ".wgsl" &&
      !doc_expression(d, word))
    return d.error =
               "only an ISF or a .wgsl effect or an expression is put on again "
               "so far",
           "";
  std::string made;
  for (int n = 2;
       made.empty() || std::find(list.begin(), list.end(), made) != list.end();
       ++n)
    made = (source.parent_path() /
            (source.stem().string() + "~" + std::to_string(n) +
             source.extension().string()))
               .string();
  list.insert(at + 1, made);
  std::string fx;
  for (const std::string& w : list) fx += (fx.empty() ? "" : " ") + w;
  const DocScript* script = doc_script_of(d, word);
  doc_act(d);
  bool ok = doc_say(d, layer, "fx", fx.c_str());
  if (script)
    for (size_t i = 0; i < script->parameters.size(); ++i)
      // The source parameters are looked up by name: an expression's first,
      // then js_<knob>.
      ok = ok &&
           doc_change(
               d,
               sqlite3_mprintf(
                   "insert or replace into keyframe select layer, %Q, at, "
                   "value, easing from keyframe where layer = %d and name = %Q",
                   doc_screen_parameter(made, script->parameters[i].name)
                       .c_str(),
                   layer, script->names[i].c_str()));
  return doc_acted(d) && ok ? made : "";
}

std::string doc_fx_titles(Doc& d, int layer) {
  std::string all;
  for (const std::string& w : doc_fx_list(d, layer, true))
    all += (all.empty() ? "" : ";") + doc_fx_title(w);
  return all;
}

std::string doc_cards_of(Doc& d, int layer, std::string* more) {
  const std::string has = " " + doc_has(d, layer) + " ";
  // The cards of the layer's effects come after the layer's own cards (Text,
  // Fill, Transform, Blending and so on) and before the cards for optional
  // features such as Copies. This matches Premiere Pro's Effect Controls, which
  // lists applied effects under Motion and Opacity. Otherwise the effect cards
  // sit below ten mostly unused cards.
  std::string all, besides;
  // Cards of ThorVG effects, keyed by the property that turns each effect on.
  // They are laid out later in the order of the effect list.
  std::map<std::string, std::string> effects;
  const bool behaviour = doc_word(d, layer, "kind") == "behaviour";
  bool past = false;
  for (const DocCard& card : doc_cards) {
    past = past || !strcmp(card.title, "Field");
    // A behavior shows only its own card, not the cards of other layer kinds
    // whose properties happen to share a name with its parameters.
    if (behaviour && !(card.when && !strcmp(card.when, "file"))) continue;
    if (card.when && card.is[0] == '+') {
      // An effect's card is shown while the effect is on.
      if (!doc_on(d, layer, card.when)) continue;
    } else if (card.when && card.is[0] == '@') {
      // A material's card is shown while the layer has one of the card's
      // materials. A solid with no material, or a flat layer placed in depth,
      // is lit: it gets Filament's lit surface.
      std::string m = doc_material(d, layer);
      const std::string sp = doc_word(d, layer, "space");
      if (m.empty() && (doc_word(d, layer, "kind") == "solid" || sp == "3d" ||
                        sp == "2.5d" || doc_on(d, layer, "scale_z")))
        m = "lit";
      if (m.empty() || !doc_among(card.is + 1, m)) continue;
    } else if (card.when && card.is[0] == '~') {
      // A gradient's card is shown while the fill has more than one color.
      if (doc_word(d, layer, card.when).find(card.is + 1) == std::string::npos)
        continue;
    } else if (card.when) {
      // A card for one fill value and not another, or while the layer is
      // clipped.
      const std::string w = doc_word(d, layer, card.when),
                        want = card.is[0] == '!' ? card.is + 1 : card.is;
      char* end = nullptr;
      const double n = std::strtod(w.c_str(), &end);
      // An unset number counts as 0, for example a layer with no parent.
      const bool is = w == want || (w.empty() && want == "0") ||
                      (!w.empty() && !*end && n == std::atof(want.c_str()) &&
                       !want.empty() && isdigit((unsigned char)want[0]));
      if (is == (card.is[0] == '!')) continue;
    }
    std::string names;
    // Cards marked "added" are hidden until asked for. By default the user sees
    // Alight Motion's tiles for the layer kind (see LayerTools.kt in
    // AbsentMotion: Color & Fill, Blending, Transform, Edit, Effects, and Speed
    // for a video). The rest are shown by More. The canvas's own cards are
    // shown together by Stage settings.
    const std::string kindNow = doc_word(d, layer, "kind");
    bool said = !card.added || layer == 0 ||
                (!strcmp(card.title, "Play") && kindNow == "video");
    for (const char* at = card.names; *at;) {
      const size_t len = strcspn(at, " ");
      const std::string n(at, len);
      said = said || !doc_word(d, layer, n.c_str()).empty() ||
             doc_keys(d, layer, n.c_str());
      // A solid with no animation of its own has nothing to play.
      const bool still = (n == "animation" || n == "speed") &&
                         doc_word(d, layer, "kind") == "solid" &&
                         doc_words(d, layer, "animation").empty();
      if (has.find(" " + n + " ") != std::string::npos && !still)
        names += (names.empty() ? "" : " ") + n;
      at += len + (at[len] ? 1 : 0);
    }
    if (!names.empty() && !said && more)
      *more +=
          (more->empty() ? "" : "; ") + std::string(card.title) + ": " + names;
    if (names.empty() || !said) continue;
    if (card.when && card.is[0] == '+' && doc_thor_letter(card.when))
      effects[card.when] = std::string(card.title) + ": " + names;
    else
      (past ? besides : all) += ((past ? besides : all).empty() ? "" : "; ") +
                                std::string(card.title) + ": " + names;
  }
  // The number of copies goes on the card of the first expression, as After
  // Effects' Repeater has Copies and Cavalry's Duplicator has Count. It is the
  // n of each(i, n, t, k).
  bool copies = has.find(" copies ") == std::string::npos;
  // The copies' own properties, appended at the end of the card, as doc_shown's
  // "Copies" does.
  std::string copied;
  for (const char* n : {"stagger", "stagger_from", "copy_fill", "copy_fill_way",
                        "copy_opacity_end", "tall", "copy_tall"})
    if (has.find(" " + std::string(n) + " ") != std::string::npos)
      copied += std::string(" ") + n;
  // One card per effect, in effect order, for ThorVG effects and file effects
  // alike. Effects that are turned off are included because their values are
  // kept.
  if (layer != 0)
    for (const std::string& w : doc_fx_list(d, layer, true)) {
      std::string card;
      if (doc_thor_letter(w)) {
        if (const auto at = effects.find(w); at != effects.end())
          card = at->second;
      } else {
        // A file effect, with or without parameters. Its card is where the user
        // reaches its visibility toggle, its bin and its code.
        if (const DocScript* sc = doc_script_of(d, w))
          for (const DocValue& one : sc->values)
            card += (card.empty() ? "" : " ") + std::string(one.name);
        if (!copies && doc_expression(d, w))
          card =
              "copies" + std::string(card.empty() ? "" : " ") + card + copied,
          copies = true;
        card = doc_fx_title(w) + ": " + card;
      }
      if (!card.empty()) all += (all.empty() ? "" : "; ") + card;
    }
  if (!besides.empty()) all += (all.empty() ? "" : "; ") + besides;
  if (doc_among("image text shape solid stage behaviour",
                doc_word(d, layer, "kind")))
    // The script's own card, holding the parameters its header declares.
    if (const std::vector<DocScript*> scs = doc_scripts_on(d, layer);
        !scs.empty()) {
      std::string names = layer == 0 ? "script follow" : "script";
      bool script_copied = false;
      // A script that lays copies, with each() or a Cavalry distribution or a
      // name such as "Repeater", gets the copy count on its card. A sketch only
      // paints and lays none.
      if (const DocScript* own = doc_script_of(d, doc_word(d, layer, "script"));
          !copies && own && own->run && !own->run->sketch())
        names += " copies", copies = true, script_copied = true;
      for (const DocScript* sc : scs)
        // Effect files have cards of their own, above. The lines of a sketch
        // that draw belong to its image.
        if (layer == 0 ||
            sc == doc_script_of(d, doc_word(d, layer, "script")) ||
            (std::filesystem::path(doc_word(d, layer, "file")).extension() ==
                 ".js" &&
             sc == doc_script_of(d, doc_word(d, layer, "file"), false)))
          // A parameter shared by two effects is listed once.
          for (const DocValue& one : sc->values)
            if ((" " + names + " ").find(" " + std::string(one.name) + " ") ==
                std::string::npos)
              names += std::string(" ") + one.name;
      // The copies' properties come last, after the script's own parameters.
      if (script_copied) names += copied;
      // No card if no script has parameters.
      if (names != "script")
        all += (all.empty() ? "" : "; ") + std::string("Script: ") + names;
    }
  return all;
}

bool doc_range(Doc& d, int layer, const char* name, double* low, double* high) {
  const std::string kind = doc_word(d, layer, "kind");
  for (const DocValue& one : doc_values)
    if (!strcmp(one.name, name) && doc_among(one.kinds, kind) && !one.words)
      return *low = one.low, *high = one.high, true;
  if (const DocValue* v = doc_script_value(d, layer, name); v && !v->words)
    return *low = v->low, *high = v->high, true;
  return false;
}

bool doc_on(Doc& d, int layer, const char* name) {
  if (doc_keys(d, layer, name)) return true;
  const std::string w = doc_word(d, layer, name);
  double low = 0, high = 0;
  return !w.empty() &&
         (!doc_range(d, layer, name, &low, &high) || std::atof(w.c_str()) != 0);
}

}  // namespace motolii

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

#include "community/after_effects_plugin/ae_plugin.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "document/card_table.h"
#include "document/document.h"
#include "document/edit/arrange.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/stroke_put.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "shelf/shelf_folders.h"
#include "stage/render/gltf_model.h"

namespace motolii {

namespace {

// Returns the layer's script parameter called "name", or nullptr. Script
// parameter names start with "js_".
const DocValue* doc_script_value(Doc& d, int layer, const char* name) {
  // One use's own value ("a1b2c3:js_blur_size") is what the file declares
  // under the name without the ID.
  if (!fx_entry_id(name).empty()) name += 7;
  if (strncmp(name, "js_", 3) != 0) return nullptr;
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
    if (const auto t = d.on_stage.shown.find(layer);
        t != d.on_stage.shown.end() && t->second.solid)
      for (const std::string& m : t->second.solid->moves)
        all += (all.empty() ? "" : " ") + m;
    return all;
  }
  if (!strcmp(name, "marker") && kind == "image") {
    // The named segments of the image's file, as ThorVG reads them. "all" plays
    // the whole file.
    std::string all = "all";
    if (const auto t = d.on_stage.shown.find(layer);
        t != d.on_stage.shown.end() && t->second.drawn)
      for (const std::string& m : t->second.drawn->markers) all += " " + m;
    return all;
  }
  for (const DocValue& one : doc_values)
    if (!strcmp(one.name, name) && doc_among(one.kinds, kind))
      return one.words ? one.words : "";
  // Per-instance names carry an "id:" prefix; fall back to the base name.
  if (const std::string base = fx_entry_path(name);
      base != name && !base.empty())
    return doc_words(d, layer, base.c_str());
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
    // and later get a number
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
        .generic_string();
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
  // Strip instance-ID prefix before any path operations.
  const std::string path = fx_entry_path(name);
  if (path != name) return doc_fx_title(path);
  if (ae_plugin_is(path)) return ae_plugin_title(path);
  if (const std::string source = fx_source(name); source != name) {
    // An effect duplicated from another: the title of its source plus its
    // number, such as "Glow 2". It has its own card.
    const std::string stem =
        std::filesystem::path(name).stem().generic_string();
    return doc_fx_title(source) + " " + stem.substr(stem.rfind('~') + 1);
  }
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
  std::string t = std::filesystem::path(name).stem().generic_string();
  for (char& c : t)
    if (c == '_') c = ' ';
  if (!t.empty()) t[0] = (char)std::toupper((unsigned char)t[0]);
  return t;
}

std::string doc_fx_duplicate(Doc& d, int layer, const std::string& title) {
  std::vector<std::string> list = doc_fx_entries(d, layer, true);
  const auto at = std::find_if(
      list.begin(), list.end(),
      [&](const std::string& w) { return doc_fx_title(w) == title; });
  if (at == list.end()) return d.error = "no effect of that name is on it", "";
  // The file, and the ID its values are kept under (doc_fx_values_id).
  const std::string word = fx_entry_path(*at), own = doc_fx_values_id(d, *at);
  const std::filesystem::path source(fx_source(word));
  if (source.extension() != ".fs" && source.extension() != ".wgsl" &&
      !doc_expression(d, word))
    return d.error =
               "only an ISF or a .wgsl effect or an expression is put on again "
               "so far",
           "";
  std::string made;
  const auto there = [&] {
    return std::any_of(list.begin(), list.end(), [&](const std::string& w) {
      return fx_entry_path(w) == made;
    });
  };
  for (int n = 2; made.empty() || there(); ++n)
    made = (source.parent_path() /
            (source.stem().generic_string() + "~" + std::to_string(n) +
             source.extension().generic_string()))
               .generic_string();
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
                   layer,
                   (own.empty() ? script->names[i]
                                : own + ":" + script->names[i])
                       .c_str()));
  return doc_acted(d) && ok ? made : "";
}

std::string doc_fx_titles(Doc& d, int layer) {
  std::string all;
  for (const std::string& w : doc_fx_list(d, layer, true))
    all += (all.empty() ? "" : ";") + doc_fx_title(w);
  return all;
}

namespace {

// Returns the property as a card reads it. A layer that is lit with no
// material said (a solid, or a flat layer placed in depth) reads "lit" for
// shading, Filament's lit surface; one that is not lit reads "".
std::string card_word(Doc& d, int layer, const char* name) {
  if (strcmp(name, "shading")) return doc_word(d, layer, name);
  std::string m = doc_material(d, layer);
  const std::string sp = doc_word(d, layer, "space");
  if (m.empty() && (doc_word(d, layer, "kind") == "solid" || sp == "3d" ||
                    sp == "2.5d" || doc_on(d, layer, "scale_z")))
    m = "lit";
  return m;
}

// Returns true if the property a card is shown for reads one of the words of
// `is`, space separated. A leading "!" is not part of the words; the caller
// takes it as "none of them". With no word left, the property must be unset. A
// number reads as the word of its value, and an unset number as 0, for example
// a layer with no parent.
bool card_reads(Doc& d, int layer, const DocCard& card) {
  const std::string w = card_word(d, layer, card.when);
  const char* at = card.is + (card.is[0] == '!');
  if (!*at) return w.empty();
  char* end = nullptr;
  const double n = std::strtod(w.c_str(), &end);
  while (*at) {
    const size_t len = strcspn(at, " ");
    const std::string want(at, len);
    if (w == want || (w.empty() && want == "0") ||
        (!w.empty() && !*end && isdigit((unsigned char)want[0]) &&
         n == std::atof(want.c_str())))
      return true;
    at += len + (at[len] ? 1 : 0);
  }
  return false;
}

}  // namespace

std::string doc_cards_of(Doc& d, int layer, std::string* more) {
  const std::string has = " " + doc_has(d, layer) + " ";
  // The cards of the layer's effects come after the layer's own cards (Text,
  // Fill, Transform, Blending and so on) and before the cards for optional
  // features such as Copies. This matches Premiere Pro's Effect Controls, which
  // lists applied effects under Motion and Opacity. Otherwise the effect cards
  // sit below ten mostly unused cards.
  std::string all, besides;
  const bool behaviour = doc_word(d, layer, "kind") == "behaviour";
  bool past = false;
  for (const DocCard& card : doc_cards) {
    past = past || card.later;
    // A behavior shows only its own card, not the cards of other layer kinds
    // whose properties happen to share a name with its parameters.
    if (behaviour && !(card.when && !strcmp(card.when, "file"))) continue;
    if (card.when && card_reads(d, layer, card) == (card.is[0] == '!'))
      continue;
    std::string names;
    // Cards marked "added" are hidden until asked for. By default the user sees
    // Alight Motion's tiles for the layer kind (see LayerTools.kt in
    // AbsentMotion: Color & Fill, Blending, Transform, Edit, Effects, and Speed
    // for a video). The rest are shown by More. The canvas's own cards are
    // shown together by Stage settings.
    const std::string kindNow = doc_word(d, layer, "kind");
    bool said = !card.added || layer == 0 ||
                (!strcmp(card.title, "Media") && kindNow == "video");
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
    // Expand per-instance path operators listed in `path_ops` ("id:kind") so
    // duplicate operators carry independent parameters and keyframes.
    if (!strcmp(card.title, "Paths") && layer != 0) {
      std::istringstream ops(doc_word(d, layer, "path_ops"));
      for (std::string entry; ops >> entry;) {
        const std::string id = fx_entry_id(entry);
        const std::string op = fx_entry_path(entry);
        if (id.empty() || op.empty()) continue;
        const auto add_prop = [&](const std::string& p) {
          if (has.find(" " + p + " ") != std::string::npos)
            names += (names.empty() ? "" : " ") + id + ":" + p;
        };
        add_prop(op);
        if (op == "zigzag")
          add_prop("zigzag_ridges"), add_prop("zigzag_smooth");
        else if (op == "rough")
          add_prop("rough_detail");
        else if (op == "trim")
          add_prop("trim_begin"), add_prop("trim_offset");
        else if (op == "morph")
          add_prop("morph_to"), add_prop("morph_steps");
        else if (op == "trail")
          add_prop("trail_length");
      }
    }
    if (!names.empty() && !said && more)
      *more +=
          (more->empty() ? "" : "; ") + std::string(card.title) + ": " + names;
    if (names.empty() || !said) continue;
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
  // One card per effect, in effect order. Effects that are turned off are
  // included because their values are kept.
  if (layer != 0)
    for (const std::string& entry : doc_fx_entries(d, layer, true)) {
      // A file effect, with or without parameters. Its card is where the user
      // reaches its visibility toggle, its bin and its code. Its values are
      // named as what draws it reads them (doc_fx_values_id).
      const std::string id = doc_fx_values_id(d, entry);
      const std::string w = fx_entry_path(entry);
      std::string card;
      if (const DocScript* sc = doc_script_of(d, w))
        for (const DocValue& one : sc->values)
          card += (card.empty() ? "" : " ") +
                  (id.empty() ? std::string(one.name) : id + ":" + one.name);
      if (!copies && doc_expression(d, w))
        card = "copies" + std::string(card.empty() ? "" : " ") + card + copied,
        copies = true;
      card = doc_fx_title(w) + ": " + card;
      all += (all.empty() ? "" : "; ") + card;
    }
  // Per-instance Stroke cards: one for each entry in the "strokes" word
  // property. Each card carries the colour and width keyed by the instance id.
  if (layer != 0)
    for (const std::string& entry : doc_stroke_list(d, layer)) {
      const std::string id = fx_entry_id(entry);
      if (id.empty()) continue;
      all += (all.empty() ? "" : "; ") + std::string("Stroke: ") + id +
             ":stroke " + id + ":stroke_width " + id + ":cap " + id + ":join " +
             id + ":dash " + id + ":dash_offset " + id + ":stroke_align";
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
  // Per-instance names carry an "id:" prefix; all instances share the same
  // range. See doc_shown_of for the same fall-through.
  if (const std::string base = fx_entry_path(name);
      base != name && !base.empty())
    return doc_range(d, layer, base.c_str(), low, high);
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

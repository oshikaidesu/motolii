#include "document/edit/fx_put.h"

#include <sqlite3.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <sstream>
#include <system_error>

#include "community/quickjs/script.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "shelf/shelf_folders.h"

namespace motolii {

namespace {

// One entry of the table below. A built-in effect is turned on by setting a
// property.
//   name   the name shown on the Effects shelf
//   value  the property that turns the effect on
//   on     what the property is set to when the effect is put on: a number, a
//   word, or keyframes
//          written "keys t0 v0 t1 v1", which key value v0 at time t0 and v1 at
//          time t1, counted from the time the effect is put on. "keys 0 1 1 0"
//          is 1 now and 0 a second later, which draws Trim Paths on, the way it
//          is mostly used in After Effects.
//   word   whether `on` is a word instead of a number
//   label  what the effect is for, as the --label: line of an effect file says
//   with   other properties set with the effect, written "name=number
//   name:word". They are the
//          values the stage draws when the properties are unset, so the
//          effect's card shows what the stage does.
//   about  what the effect does, in words that the shelf search reads
struct DocEffect {
  const char* name;
  const char* value;
  const char* on;
  bool word;
  const char* label;
  const char* with = "";
  const char* about = "";
};

const DocEffect doc_effects[] = {
    {"Trim Paths", "trim", "keys 0 1 1 0", false, "Path"},
    // Lays one copy of the layer along the outline of the layer under it, as
    // copies 1 with a stagger lay one on an outline; see doc_place.
    {"Move Along Path", "copy_on_offset", "keys 0 0 1 1", false, "Path",
     "stagger=0.01",
     "Goes along the outline of the layer under it, end to end in a second. "
     "Alight Motion's Move Along Path"},
    {"Datamosh", "mosh", "1", false, "Glitch", "mosh_at=1"},
    // The fill of the layer is whatever is behind it, so the effects on the
    // layer work on the background in the layer's shape. The layer still blends
    // with what is under it as its blend mode says. This is the Adjustment
    // Layer of After Effects, as one more effect.
    {"Background Copy", "fill", "behind", true, "Utility", "",
     "Its fill is what is behind it: the effects on it work on the background "
     "in its shape. After Effects' Adjustment Layer"},
};

}  // namespace

std::string doc_effect_names() {
  std::string all;
  std::error_code wrong;
  for (const DocEffect& e : doc_effects) {
    if (!*e.label) continue;
    const std::filesystem::path picture =
        script_shelf_file((doc_folders("effects").front() /
                           ("thing_" + std::string(e.value) + ".png"))
                              .string());
    all += (all.empty() ? "" : "\n") + std::string(e.name) + "\t" + e.value +
           "\t" + e.label + "\t" +
           (std::filesystem::exists(picture, wrong) ? picture.string() : "") +
           "\t\t\t" + e.about;
  }
  return all;
}

bool doc_fx_say(Doc& d, int layer, const std::vector<std::string>& list) {
  // A camera has no canvas to lay an effect on. It takes only the motions of
  // AbsentMotion, which move its place, as the camera of AbsentMotion is placed
  // by its own motions. See LayerView in camera.cpp and OwnAt, ApplyMotion in
  // styles.cpp, both in engine/third_party/AbsentMotion/app/src/main/cpp/.
  if (doc_word(d, layer, "kind") == "camera")
    for (const std::string& w : list)
      if (std::filesystem::path(w).extension() != ".am")
        return d.error =
                   "a camera takes motions only (it has no picture of its "
                   "own): " +
                   doc_fx_title(w) + " is an effect",
               false;
  if (!list.empty()) return doc_say(d, layer, "fx", doc_fx_join(list).c_str());
  return !doc_knows(d, layer, "fx") || doc_word(d, layer, "fx").empty() ||
         doc_change(d,
                    sqlite3_mprintf(
                        "delete from keyframe where layer = %d and name = 'fx'",
                        layer));
}

bool doc_fx_file(Doc& d, int layer, const char* file, double now) {
  std::vector<std::string> list = doc_fx_list(d, layer, true);
  const auto at = std::find(list.begin(), list.end(), file);
  const bool out = at != list.end();
  if (out)
    list.erase(at);
  else
    list.push_back(file);
  doc_act(d);
  if (!doc_fx_say(d, layer, list)) d.act.ok = false;
  if (const DocScript* sc = out ? doc_script_of(d, file) : nullptr)
    for (const std::string& n : sc->names)
      if (!doc_change(d,
                      sqlite3_mprintf(
                          "delete from keyframe where layer = %d and name = %Q",
                          layer, n.c_str())))
        d.act.ok = false;
  // A transition put on at the layer's own start comes in instead of going out:
  // its progress runs from 1 to 0, and what is under the layer gives way to it.
  // Premiere Pro does the same: a transition on the head edge of a clip brings
  // the clip in, and one on its tail edge takes it out. "At the start" means
  // within half a frame at the stage's 60 frames per second; see RATE in
  // entry/render_thread.h.
  const bool in =
      !std::isnan(now) &&
      std::fabs(now - doc_number(d, layer, "start", 0, 0)) < 0.5 / 60.0;
  if (const DocScript* sc =
          !out && !std::isnan(now) ? doc_script_of(d, file) : nullptr)
    if (std::any_of(
            sc->parameters.begin(), sc->parameters.end(),
            [](const ScriptParameter& k) { return k.name == "endImage"; }))
      for (size_t i = 0; i < sc->parameters.size(); ++i)
        if (sc->parameters[i].name == "progress" &&
            !(doc_key(d, layer, sc->names[i].c_str(), now, in ? 1.0 : 0.0) &&
              doc_key(d, layer, sc->names[i].c_str(), now + 1.0,
                      in ? 0.0 : 1.0)))
          d.act.ok = false;
  return doc_acted(d);
}

bool doc_fx_move(Doc& d, int layer, const char* name, int by) {
  std::vector<std::string> list = doc_fx_list(d, layer, true);
  auto at = std::find(list.begin(), list.end(), name);
  if (at == list.end())
    at = std::find_if(list.begin(), list.end(), [&](const std::string& w) {
      return doc_fx_title(w) == name;
    });
  if (at == list.end())
    return d.error = std::string(name) + " is not among its effects", false;
  const int from = (int)(at - list.begin()),
            to = std::clamp(from + by, 0, (int)list.size() - 1);
  if (from == to) return true;
  const std::string one = list[(size_t)from];
  list.erase(list.begin() + from);
  list.insert(list.begin() + to, one);
  doc_act(d);
  if (!doc_fx_say(d, layer, list)) d.act.ok = false;
  return doc_acted(d);
}

bool doc_effect(Doc& d, int layer, const char* name, double at) {
  for (const DocEffect& e : doc_effects) {
    if (strcmp(e.name, name)) continue;
    // For the fill effect, "on" means that the fill is this one.
    const bool on = !strcmp(e.value, "fill")
                        ? doc_word(d, layer, "fill") == e.on
                        : doc_on(d, layer, e.value);
    doc_act(d);
    bool ok;
    // Taking it off unsets the property, which restores the state before it was
    // put on.
    if (on)
      ok = doc_knows(d, layer, e.value) &&
           doc_change(d,
                      sqlite3_mprintf(
                          "delete from keyframe where layer = %d and name = %Q",
                          layer, e.value));
    else if (!strncmp(e.on, "keys ", 5)) {
      double a0 = 0, v0 = 0, a1 = 0, v1 = 0;
      ok = std::sscanf(e.on + 5, "%lf %lf %lf %lf", &a0, &v0, &a1, &v1) == 4 &&
           doc_key(d, layer, e.value, at + a0, v0) &&
           doc_key(d, layer, e.value, at + a1, v1);
    } else
      ok = e.word ? doc_say(d, layer, e.value, e.on)
                  : doc_set(d, layer, e.value, std::atof(e.on));
    std::istringstream with(e.with);
    // Set the other properties of the effect to the values the stage draws when
    // they are unset.
    for (std::string one; !on && ok && with >> one;) {
      const size_t at_ = one.find_first_of("=:");
      if (at_ == std::string::npos) continue;
      const std::string n = one.substr(0, at_), v = one.substr(at_ + 1);
      const bool said =
          one[at_] == '='
              ? !std::isnan(doc_number(d, layer, n.c_str(), at, NAN))
              : !doc_word(d, layer, n.c_str()).empty();
      // A property that is already set, by the user or earlier, is left as it
      // is.
      if (!said)
        ok = one[at_] == '='
                 ? doc_set(d, layer, n.c_str(), std::atof(v.c_str()))
                 : doc_say(d, layer, n.c_str(), v.c_str());
    }
    // Move Along Path copies the layer immediately beneath it, as in Alight
    // Motion. Taking the effect off clears that.
    if (ok && !strcmp(e.value, "copy_on_offset")) {
      const std::vector<int> lie = doc_laid(d);
      const auto at_ = std::find(lie.begin(), lie.end(), layer);
      if (on)
        ok = doc_change(d,
                        sqlite3_mprintf("delete from keyframe where layer = %d "
                                        "and name in ('copy_on', 'stagger')",
                                        layer));
      else if (at_ != lie.begin() && at_ != lie.end())
        ok = doc_set(d, layer, "copy_on", *(at_ - 1));
    }
    if (!ok) d.act.ok = false;
    return doc_acted(d);
  }
  d.error = std::string("no effect is called ") + name;
  return false;
}

bool doc_fx_eye(Doc& d, int layer, const char* title) {
  const std::vector<std::string> list = doc_fx_list(d, layer, true);
  if (std::none_of(list.begin(), list.end(), [&](const std::string& w) {
        return doc_fx_title(w) == title;
      }))
    return d.error = std::string(title) + " is not among its effects", false;
  const bool was =
      (";" + doc_word(d, layer, "fx_off") + ";")
          .find(";" + std::string(title) + ";") != std::string::npos;
  std::vector<std::string> off;
  std::istringstream said(doc_word(d, layer, "fx_off"));
  for (std::string one; std::getline(said, one, ';');)
    if (!one.empty() && one != title) off.push_back(one);
  if (!was) off.push_back(title);
  std::string all;
  for (const std::string& one : off) all += (all.empty() ? "" : ";") + one;
  return doc_say(d, layer, "fx_off", all.c_str());
}

bool doc_fx_out(Doc& d, int layer, const char* name) {
  const std::vector<std::string> list = doc_fx_list(d, layer, true);
  auto at = std::find(list.begin(), list.end(), name);
  if (at == list.end())
    at = std::find_if(list.begin(), list.end(), [&](const std::string& w) {
      return doc_fx_title(w) == name;
    });
  if (at == list.end())
    return d.error = std::string(name) + " is not among its effects", false;
  return doc_fx_file(d, layer, at->c_str());
}

}  // namespace motolii

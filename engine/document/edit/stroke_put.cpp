#include "document/edit/stroke_put.h"

#include <sqlite3.h>

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <random>
#include <sstream>

#include "document/document.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/value_at.h"
#include "document/undo.h"

namespace motolii {

std::vector<std::string> doc_stroke_list(Doc& d, int layer) {
  std::vector<std::string> all;
  std::istringstream said(doc_word(d, layer, "strokes"));
  for (std::string one; said >> one;)
    if (!fx_entry_id(one).empty()) all.push_back(one);
  return all;
}

std::string doc_stroke_join(const std::vector<std::string>& list) {
  std::string all;
  for (const std::string& w : list) all += (all.empty() ? "" : " ") + w;
  return all;
}

namespace {

// Generates a 6-hex-char instance ID that is unique in `list`.
std::string make_stroke_id(const std::vector<std::string>& list) {
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<unsigned> dist(0, 0xFFFFFF);
  char buf[7];
  for (;;) {
    std::snprintf(buf, sizeof(buf), "%06x", dist(rng));
    const std::string id(buf, 6);
    if (std::none_of(list.begin(), list.end(), [&](const std::string& e) {
          return fx_entry_id(e) == id;
        }))
      return id;
  }
}

bool doc_stroke_say(Doc& d, int layer, const std::vector<std::string>& list) {
  if (!list.empty())
    return doc_say(d, layer, "strokes", doc_stroke_join(list).c_str());
  return !doc_knows(d, layer, "strokes") ||
         doc_word(d, layer, "strokes").empty() ||
         doc_change(
             d,
             sqlite3_mprintf(
                 "delete from keyframe where layer = %d and name = 'strokes'",
                 layer));
}

}  // namespace

bool doc_stroke_add(Doc& d, int layer) {
  std::vector<std::string> list = doc_stroke_list(d, layer);
  const std::string id = make_stroke_id(list);
  list.push_back(id + ":");
  doc_act(d);
  if (!doc_stroke_say(d, layer, list)) d.act.ok = false;
  return doc_acted(d);
}

bool doc_stroke_out(Doc& d, int layer, const char* id) {
  std::vector<std::string> list = doc_stroke_list(d, layer);
  const auto at =
      std::find_if(list.begin(), list.end(),
                   [&](const std::string& w) { return fx_entry_id(w) == id; });
  if (at == list.end())
    return d.error = std::string(id) + " is not one of its strokes", false;
  list.erase(at);
  doc_act(d);
  if (!doc_stroke_say(d, layer, list)) d.act.ok = false;
  for (const char* name : {"stroke", "stroke_width"}) {
    const std::string key = std::string(id) + ":" + name;
    if (!doc_change(
            d, sqlite3_mprintf(
                   "delete from keyframe where layer = %d and name = %Q", layer,
                   key.c_str())))
      d.act.ok = false;
  }
  return doc_acted(d);
}

}  // namespace motolii

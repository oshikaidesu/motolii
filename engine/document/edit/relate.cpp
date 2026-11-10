#include "document/edit/relate.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <set>
#include <sstream>

#include "document/card_table.h"
#include "document/document.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"

namespace motolii {

namespace {

// Returns the properties of the layer that are connected to a relation, each as
// its name with the _by suffix and the value it shows at time `now`.
std::vector<std::pair<std::string, double>> doc_shown_now(Doc& d, int layer,
                                                          double now) {
  std::vector<std::pair<std::string, double>> names;
  doc_rows(d,
           sqlite3_mprintf("select name from keyframe where layer = %d and "
                           "name glob '*_by' and value <> 0",
                           layer),
           [&](sqlite3_stmt* q) {
             names.push_back({(const char*)sqlite3_column_text(q, 0), 0.0});
           });
  for (auto& [n, shown] : names)
    shown =
        doc_literal(d, layer, doc_lasting(n.substr(0, n.size() - 3)), now, 0.0);
  return names;
}

}  // namespace

const char* doc_lasting(const std::string& name) {
  static std::set<std::string> kept;
  return kept.insert(name).first->c_str();
}
bool doc_free(Doc& d, int layer, int by, double now, bool stay,
              const std::vector<std::pair<std::string, double>>* told) {
  const DocExact exact(d);
  // A copy, because the calls below discard the original.
  const DocRelation rel = doc_relation_of(d, by);
  const auto at = std::find(rel.members.begin(), rel.members.end(), layer);
  if (at == rel.members.end())
    return d.error = "it is not in that relation", false;
  const size_t i = (size_t)(at - rel.members.begin());
  const int was = rel.under.empty() ? 0 : rel.under[i];
  const std::vector<std::pair<std::string, double>> names =
      told ? *told : doc_shown_now(d, layer, now);
  const auto word =
      [&](const char* name, int r,
          const std::function<std::string(size_t, const std::string&)>& each) {
        std::string all;
        std::istringstream said(doc_word(d, r, name));
        size_t k = 0;
        for (std::string one; said >> one; ++k)
          all += (all.empty() ? "" : " ") + each(k, one);
        return sqlite3_mprintf(
            "update keyframe set value = %Q where layer = %d and name = %Q;",
            all.c_str(), r, name);
      };
  doc_act(d);
  char* change = word("members", by, [&](size_t k, const std::string& one) {
    return k == i ? std::string("_") : one;
  });
  // Values connected to this relation go back to what they were connected to
  // before.
  for (const auto& [n, _] : names)
    if ((int)doc_number(d, layer, n.c_str(), 0, 0) == by)
      change =
          was ? sqlite3_mprintf(
                    "%z update keyframe set value = %d where layer = %d and "
                    "name = %Q;",
                    change, was, layer, n.c_str())
              : sqlite3_mprintf(
                    "%z delete from keyframe where layer = %d and name = %Q;",
                    change, layer, n.c_str());
  // A relation that started from this layer for it now starts from the one
  // before.
  for (const auto& [r, other] : d.relations.relationsOf)
    if (r != by) {
      const auto there =
          std::find(other.members.begin(), other.members.end(), layer);
      if (there != other.members.end() && !other.under.empty() &&
          other.under[(size_t)(there - other.members.begin())] == by)
        change = sqlite3_mprintf(
            "%z %z", change,
            word("under", r, [&](size_t k, const std::string& one) {
              return k == (size_t)(there - other.members.begin())
                         ? std::to_string(was)
                         : one;
            }));
    }
  bool ok = doc_change(d, change);
  doc_forget(d);
  // If `stay` is true, move each value by the amount it would otherwise jump,
  // so the layer stays where it shows. Otherwise the layer ends as if the
  // relation's strength went to 0 for good: back at the relation under it, or
  // at its own value, so a morph by strength and a removal agree.
  for (const auto& [n, shown] : names) {
    if (!ok || !stay) break;
    const std::string base = n.substr(0, n.size() - 3);
    const double off =
        shown - doc_literal(d, layer, doc_lasting(base), now, 0.0);
    if (std::abs(off) < 1e-12) continue;
    // Add the offset to every keyframe of the property, and add a keyframe at
    // time 0 if it had none.
    ok = doc_change(
        d, sqlite3_mprintf(
               "update keyframe set value = value + %!.17g where layer = %d "
               "and name = %Q; insert into keyframe(layer, name, at, value) "
               "select %d, %Q, 0.0, %!.17g where not exists (select 1 from "
               "keyframe where layer = %d and name = %Q);",
               off, layer, base.c_str(), layer, base.c_str(), off, layer,
               base.c_str()));
    doc_forget(d);
  }
  return doc_acted(d) && ok;
}
bool doc_picks(Doc& d, int by, int layer) {
  const DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
  if (sc)
    for (size_t i = 0; i < sc->parameters.size(); ++i)
      if (sc->parameters[i].kind == "picture" &&
          (int)doc_number(d, by, sc->names[i].c_str(), 0, 0) == layer)
        return true;
  return false;
}
bool doc_relate(Doc& d, int by, const char* ids, double now) {
  if (doc_word(d, by, "kind") != "behaviour" ||
      !doc_among(doc_relations, doc_word(d, by, "file")))
    return d.error = "that is no relation", false;
  std::vector<int> layers;
  std::istringstream said(ids);
  for (std::string one; said >> one;)
    if (const int t = std::atoi(one.c_str());
        t && t != by && doc_knows(d, t) &&
        std::find(layers.begin(), layers.end(), t) == layers.end())
      layers.push_back(t);
  if (layers.empty()) return d.error = "no layers to put in it", false;
  // Where each layer settles, with the effect of relations left out
  // (d.relations.settled).
  std::map<int, std::pair<double, double>> at;
  d.relations.settled = true;
  doc_forget(d);
  for (const int t : layers)
    at[t] = {doc_literal(d, t, "x", now, 0.0),
             doc_literal(d, t, "y", now, 0.0)};
  d.relations.settled = false;
  doc_forget(d);
  doc_act(d);
  // The leader the script picks, if it is already set, is not a member.
  const int leader = (int)doc_number(d, by, "js_leader", 0, 0);
  std::vector<int> members;
  for (const int t : layers)
    if (t != leader) members.push_back(t);
  std::string order, under, from;
  for (const int t : members) {
    const int before = doc_driven_by(d, t, "x");
    const bool related =
        before && doc_among(doc_relations, doc_word(d, before, "file"));
    order += (order.empty() ? "" : " ") + std::to_string(t);
    under += (under.empty() ? "" : " ") + std::to_string(related ? before : 0);
    char buf[64];
    std::snprintf(buf, sizeof buf, "%.17g %.17g", at[t].first, at[t].second);
    from += (from.empty() ? "" : " ") + std::string(buf);
  }
  bool ok = doc_say(d, by, "members", order.c_str()) &&
            doc_say(d, by, "under", under.c_str()) &&
            doc_say(d, by, "from", from.c_str());
  for (const int t : members) {
    // Also connect depth if the layer has one, and rotation, size and opacity,
    // which a relation written as a file may set.
    ok = ok && doc_set(d, t, "x_by", by) && doc_set(d, t, "y_by", by) &&
         (!doc_knows(d, t, "z") || doc_set(d, t, "z_by", by));
    for (const char* n : {"rotate", "rotate_x", "rotate_y", "size", "opacity"})
      ok = ok && (!doc_knows(d, t, n) ||
                  doc_set(d, t, (std::string(n) + "_by").c_str(), by));
  }
  return doc_acted(d) && ok;
}
bool doc_lead(Doc& d, int by, int leader, double now) {
  // Sets doc_leading while this function runs.
  struct Leading {
    Leading() { doc_leading = true; }
    ~Leading() { doc_leading = false; }
  } leading;
  if (doc_word(d, by, "kind") != "behaviour" ||
      !doc_among(doc_relations, doc_word(d, by, "file")))
    return d.error = "that is no relation", false;
  if (!doc_knows(d, leader) || leader == by)
    return d.error = "a leader is a layer that is there", false;
  const int was = (int)doc_number(d, by, "js_leader", 0, 0);
  if (was == leader) return true;
  std::vector<int> touched;
  for (const int t : doc_members_of(d, by))
    if (t) touched.push_back(t);
  if (std::find(touched.begin(), touched.end(), leader) == touched.end())
    touched.push_back(leader);
  std::map<int, std::pair<double, double>> shown;
  for (const int t : touched)
    shown[t] = {doc_literal(d, t, "x", now, 0.0),
                doc_literal(d, t, "y", now, 0.0)};
  doc_act(d);
  const std::vector<int>& in = doc_members_of(d, by);
  // The leader is not a member the relation moves.
  bool ok = std::find(in.begin(), in.end(), leader) == in.end() ||
            doc_free(d, leader, by, now, true);
  ok = ok && doc_set(d, by, "js_leader", leader);
  doc_forget(d);
  // Move each layer by the amount it would otherwise jump.
  for (const auto& [t, at] : shown) {
    if (!ok) break;
    const double ox = at.first - doc_literal(d, t, "x", now, 0.0),
                 oy = at.second - doc_literal(d, t, "y", now, 0.0);
    for (const auto& [name, off] :
         {std::make_pair("x", ox), std::make_pair("y", oy)})
      if (std::abs(off) > 1e-12)
        // The same shift as in doc_free.
        ok = ok &&
             doc_change(
                 d,
                 sqlite3_mprintf(
                     "update keyframe set value = value + %!.17g where layer = "
                     "%d and name = %Q; insert into keyframe(layer, name, at, "
                     "value) select %d, %Q, 0.0, %!.17g where not exists "
                     "(select 1 from keyframe where layer = %d and name = %Q);",
                     off, t, name, t, name, off, t, name));
    doc_forget(d);
  }
  return doc_acted(d) && ok;
}
bool doc_release(Doc& d, int by, double now) {
  const DocExact exact(d);
  if (doc_word(d, by, "kind") != "behaviour")
    return d.error = "that is no relation", false;
  // A copy, because freeing one layer changes the member list.
  const std::vector<int> all = doc_members_of(d, by);
  // Read every layer's values before any is freed. A relation written as a file
  // derives each member's place from all the others.
  std::map<int, std::vector<std::pair<std::string, double>>> shown;
  for (const int t : all)
    if (t) shown[t] = doc_shown_now(d, t, now);
  // One undo step: all layers freed and the relation gone, or none of it.
  doc_act(d);
  bool ok = true;
  for (const int t : all)
    if (ok && t) ok = doc_free(d, t, by, now, true, &shown[t]);
  ok = ok && doc_remove(d, by);
  return doc_acted(d) && ok;
}

}  // namespace motolii

#include "document/edit/parent.h"

#include <math/mat4.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <map>

#include "document/document.h"
#include "document/edit/arrange.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/undo.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

bool doc_parent(Doc& d, int layer, double to) {
  if (!doc_knows(d, layer, "parent", &to)) return false;
  // A ring of layers that each have the next as parent would have no end, so
  // refuse a parent that already has this layer above it. The walk stops after
  // 64 levels.
  for (int up = (int)to, n = 0; up && n < 64;
       up = (int)doc_number(d, up, "parent", 0, 0), ++n)
    if (up == layer)
      return d.error =
                 "it would go with itself (that one goes with it already)",
             false;
  const double now = d.stage->now;
  // Sums how far the parents turn the layer and multiplies the sizes they give
  // it, walking up from `up`.
  const auto chain = [&](int up, double* turn, double* size) {
    *turn = 0.0, *size = 1.0;
    for (int n = 0; up && n < 64 && d.on_stage.shown.count(up);
         up = (int)doc_number(d, up, "parent", 0, 0), ++n)
      *turn += doc_number(d, up, "rotate", now, 0),
          *size *= doc_number(d, up, "size", now, 1);
  };
  double turnWas, sizeWas, turnTo, sizeTo;
  chain((int)doc_number(d, layer, "parent", 0, 0), &turnWas, &sizeWas);
  chain((int)to, &turnTo, &sizeTo);
  // Record where the layer stands at each keyframe of its position and at the
  // current time. Every keyframe is carried over to the new parent, as After
  // Effects moves a layer's keyframes whole when it is parented. No keyframe is
  // added.
  const char* const xyz[] = {"x", "y", "z"};
  std::map<double, math::double4> stood;
  stood[now] = {doc_number(d, layer, "x", now, 0),
                doc_number(d, layer, "y", now, 0),
                doc_number(d, layer, "z", now, 0), 1.0};
  for (const char* name : xyz)
    for (const double at : doc_key_times(d, layer, name))
      stood[at] = {doc_number(d, layer, "x", at, 0),
                   doc_number(d, layer, "y", at, 0),
                   doc_number(d, layer, "z", at, 0), 1.0};
  const math::mat4 was = doc_above(d, layer, now);
  const double size = doc_number(d, layer, "size", now, 1);
  doc_act(d);
  bool ok = doc_change(
      d,
      sqlite3_mprintf(
          "insert into keyframe(layer, name, at, value) values(%d, 'parent', "
          "0.0, %!.17g) on conflict do update set value = excluded.value",
          layer, to));
  // Drop cached values, so that the parent is read as just written and not as
  // cached from the last frame, as doc_unrelate does after its change.
  doc_forget(d);
  const math::mat4 into = inverse(doc_above(d, layer, now)) * was;
  for (int k = 0; ok && k < 3; ++k) {
    const std::vector<double> keys = doc_key_times(d, layer, xyz[k]);
    if (keys.empty()) ok = doc_set(d, layer, xyz[k], (into * stood[now])[k]);
    for (const double at : keys)
      ok = ok && doc_change(d, sqlite3_mprintf(
                                   "update keyframe set value = %!.17g where "
                                   "layer = %d and name = %Q and at = %!.17g",
                                   (into * stood[at])[k], layer, xyz[k], at));
  }
  const double turnBy = turnWas - turnTo;
  if (ok && turnBy != 0.0)
    ok = doc_keys(d, layer, "rotate")
             ? doc_change(d, sqlite3_mprintf(
                                 "update keyframe set value = value + %!.17g "
                                 "where layer = %d and name = 'rotate'",
                                 turnBy, layer))
             : doc_set(d, layer, "rotate",
                       doc_number(d, layer, "rotate", now, 0) + turnBy);
  // A layer without a size property, such as a camera, is skipped here. Its
  // parent is the layer chosen as its Target in the inspector, and failing on
  // the missing size would wrongly refuse the change. relations.h skips missing
  // properties in the same way.
  if (ok && doc_knows(d, layer, "size") && !doc_keys(d, layer, "size"))
    ok = doc_set(d, layer, "size",
                 std::clamp(size * sizeWas / sizeTo, 1e-3, 1e4));
  return doc_acted(d) && ok;
}
bool doc_key_here(Doc& d, int layer, const char* name, double at) {
  if (!doc_knows(d, layer, name, nullptr, nullptr, true)) return false;
  // Like After Effects' Enable Time Remapping: add a keyframe at the layer's
  // start and one at its end, each holding the layer's own time there. All of
  // it is one undo step.
  if (!strcmp(name, "time_remap") && !doc_keys(d, layer, name)) {
    const double gone = doc_number(d, layer, "begin", 0, 0),
                 start = doc_number(d, layer, "start", 0, 0),
                 lasts = doc_lasts(d, layer) > 0.0
                             ? doc_lasts(d, layer)
                             : std::max(1e-3, doc_seconds(d) - start);
    doc_act(d);
    const bool ok = doc_key(d, layer, name, start, gone) &&
                    doc_key(d, layer, name, start + lasts, gone + lasts) &&
                    (at <= start || at >= start + lasts ||
                     doc_key(d, layer, name, at, gone + at - start));
    if (!ok) d.act.ok = false;
    return doc_acted(d) && ok;
  }
  return doc_keys(d, layer, name, at) && doc_keys(d, layer, name)
             ? true
             : doc_key(d, layer, name, at,
                       doc_number(d, layer, name, at,
                                  doc_usual_on(d, layer, name)));
}
std::vector<int> doc_under(Doc& d, int group) {
  std::vector<int> all;
  if (doc_word(d, group, "shape") != "null") return all;
  for (const int t : doc_laid(d)) {
    int up = (int)doc_number(d, t, "parent", 0, 0);
    for (int n = 0; up > 0 && up != group && n < 64; ++n)
      up = (int)doc_number(d, up, "parent", 0, 0);
    if (up == group) all.push_back(t);
  }
  return all;
}
bool doc_raise(Doc& d, int layer, int places) {
  if (!doc_knows(d, layer)) return false;
  // Drop cached values, so that the order is read as the document has it now,
  // including a layer added in the same undo step, as doc_relate does before it
  // reads.
  doc_forget(d);
  std::vector<int> lie = doc_laid(d), going = doc_under(d, layer);
  going.push_back(layer);
  const long from =
      std::find(lie.begin(), lie.end(), going.front()) - lie.begin();
  lie.erase(std::remove_if(lie.begin(), lie.end(),
                           [&](int t) {
                             return std::find(going.begin(), going.end(), t) !=
                                    going.end();
                           }),
            lie.end());
  const long to = std::clamp(from + (long)places, 0L, (long)lie.size());
  if (to == from)
    return d.error = places > 0 ? "it is the nearest already"
                                : "it is the furthest back already",
           false;
  lie.insert(lie.begin() + to, going.begin(), going.end());
  char* all = sqlite3_mprintf("");
  for (size_t i = 0; i < lie.size(); ++i)
    all = sqlite3_mprintf(
        "%zinsert into keyframe(layer, name, at, value) values(%d, 'order', "
        "0.0, %d) on conflict do update set value = excluded.value;",
        all, lie[i], (int)i + 1);
  return doc_change(d, all);
}

}  // namespace motolii

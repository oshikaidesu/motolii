#include "document/edit/time_edit.h"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <sstream>

#include "document/document.h"
#include "document/edit/hold.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/parent.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"

namespace motolii {

namespace {

// Moves every animated property of `layer` by `by` seconds, as After Effects
// moves a layer's keyframes. A property counts as animated if it has more than
// one keyframe, a keyframe that is not at time 0, or an easing. A property with
// a single keyframe at time 0 and no easing is a constant and stays. Returns
// false if the change fails.
bool doc_keys_by(Doc& d, int layer, double by) {
  // The first statement moves the keyframes to a far-off range and the second
  // brings them back. Going through the far-off range keeps a moved keyframe
  // from landing on one that has not been moved yet, which would collide on the
  // key (layer, name, at).
  return doc_change(
      d, sqlite3_mprintf(
             "update keyframe set at = at + %!.17g where layer = %d and name "
             "in (select name from keyframe where layer = %d group by name "
             "having count(*) > 1 or max(at) <> 0 or max(easing) is not null);"
             "update keyframe set at = at - 1e7 where layer = %d and at >= 5e6",
             1e7 + by, layer, layer, layer));
}

// Moves layer `made`, a new copy of `layer`, to sit directly above `layer`, as
// After Effects' Duplicate and Split Layer do (AbsentMotion: duplicateSelected,
// addAbove). A copy is otherwise created on top of all layers. Returns false on
// failure.
bool doc_lay_above(Doc& d, int made, int layer) {
  doc_forget(d);
  const std::vector<int> lie = doc_laid(d);
  const long from = std::find(lie.begin(), lie.end(), made) - lie.begin(),
             under = std::find(lie.begin(), lie.end(), layer) - lie.begin();
  return from == under + 1 ||
         doc_raise(d, made, (int)(under + (from > under ? 1 : 0) - from));
}

}  // namespace

int doc_copy_above(Doc& d, int layer) {
  doc_act(d);
  const int made = doc_duplicate(d, layer);
  const bool ok = made && doc_lay_above(d, made, layer);
  return doc_acted(d) && ok ? made : 0;
}

int doc_split(Doc& d, int layer, double at) {
  if (doc_knows(d, layer) && doc_number(d, layer, "lock", 0, 0) > 0.5)
    return d.error = "it is locked", 0;
  const double start = doc_number(d, layer, "start", 0, 0),
               lasts = doc_number(d, layer, "duration", 0, -1),
               end = lasts > 0.0 ? start + lasts : doc_seconds(d);
  if (!(at > start + 1e-3 && at < end - 1e-3))
    return d.error = "the moment is not inside it", 0;
  doc_act(d);
  const int made = doc_duplicate(d, layer);
  bool ok = made && doc_set(d, layer, "duration", at - start) &&
            doc_set(d, made, "start", at) &&
            doc_set(d, made, "duration", end - at);
  // Move the copy's playback offset on by how far the layer's own clock has
  // run.
  if (const double on = doc_own_clock(d, layer, at - start); ok && on != 0.0)
    ok = doc_set(d, made, "begin", doc_number(d, layer, "begin", 0, 0) + on);
  // Place the later part directly above the earlier part, as After Effects'
  // Split Layer places the new layer.
  ok = ok && doc_lay_above(d, made, layer);
  return doc_acted(d) && ok ? made : 0;
}

bool doc_extract(Doc& d) {
  double in = 0.0, out = 0.0;
  doc_work(d, &in, &out);
  const double gap = out - in, all = doc_seconds(d);
  if (!(gap > 1e-3) || (in < 1e-3 && out > all - 1e-3))
    return d.error =
               "the work area is all of it: set it to the part to take out",
           false;
  std::vector<int> layers;
  // Collect every layer that has a time of its own, that is every kind except
  // 'behaviour'.
  doc_rows(
      d,
      sqlite3_mprintf("select layer from keyframe where layer <> 0 and name = "
                      "'kind' and value <> 'behaviour' order by layer"),
      [&](sqlite3_stmt* row) { layers.push_back(sqlite3_column_int(row, 0)); });
  doc_act(d);
  bool ok = true;
  for (const int t : layers) {
    // `e` is the end of the layer. A layer with no duration lasts to the end of
    // the project.
    const double s = doc_number(d, t, "start", 0, 0),
                 lasts = doc_number(d, t, "duration", 0, -1),
                 e = lasts > 0.0 ? s + lasts : all;
    // `after` is the part of the layer that lies after the work area and moves
    // earlier. It is the layer itself if it starts after the work area.
    int after = s >= out - 1e-3 ? t : 0;
    // If the layer crosses the end of the work area, split it there. The later
    // part is `after`.
    if (!after && e > out + 1e-3)
      ok = ok && (after = doc_split(d, t, out)) != 0;
    // A layer crossing the start of the work area is split there and the part
    // inside is removed. A layer that starts inside the work area is removed
    // whole, because any part beyond the end was split off above.
    if (s < in - 1e-3 && e > in + 1e-3) {
      const int within = doc_split(d, t, in);
      ok = ok && within && doc_remove(d, within);
    } else if (s >= in - 1e-3 && s < out - 1e-3)
      ok = ok && doc_remove(d, t);
    // Move the later part earlier by the length of the gap, with its keyframes.
    if (after)
      ok = ok &&
           doc_set(d, after, "start",
                   doc_number(d, after, "start", 0, 0) - gap) &&
           doc_keys_by(d, after, -gap);
    if (!ok) break;
  }
  // Markers are the 'mark' and 'mark_colour' properties of layer 0. Delete
  // those inside the work area and move later ones earlier by the gap. As in
  // doc_keys_by, they go through a far-off range so that a moved marker never
  // lands on one that has not been moved yet.
  ok = ok &&
       doc_change(
           d, sqlite3_mprintf(
                  "delete from keyframe where layer = 0 and name in ('mark', "
                  "'mark_colour') and at >= %!.17g and at < %!.17g;"
                  "update keyframe set at = at + %!.17g where layer = 0 and "
                  "name in ('mark', 'mark_colour') and at >= %!.17g;"
                  "update keyframe set at = at - 1e7 where layer = 0 and name "
                  "in ('mark', 'mark_colour') and at >= 5e6",
                  in - 1e-9, out - 1e-9, 1e7 - gap, out - 1e-9));
  if (!ok) d.act_ok = false;
  return doc_acted(d);
}

bool doc_let_go(Doc& d, bool keep) {
  const Doc::Held h = d.held;
  d.held = Doc::Held{};
  if (h.layer < 0) return d.error = "nothing is held", false;
  // Rebuild the stage from the project so that it shows the unchanged values.
  if (!keep || (h.tried.empty() && h.said.empty()))
    return doc_match(d), doc_evaluate(d, d.stage->now), true;
  // Everything the drag changed becomes one undo step. An animated property
  // gets a keyframe at the current time by the usual rule for a value changed
  // at a time. Any other value is set as it is.
  doc_act(d);
  for (const auto& [name, is] : h.tried) {
    bool moves = false;
    for (const DocValue& one : doc_values)
      moves = moves || (one.moves && name == one.name);
    // Names starting with js_ are parameters of the layer's scripts, which are
    // effects, found as doc_knows finds them. One that the script file declares
    // animatable, a track, takes a keyframe. Any other value is set and loses
    // all its keyframes.
    if (!moves && name.rfind("js_", 0) == 0)
      for (const DocScript* sc : doc_scripts_on(d, h.layer))
        for (const DocValue& one : sc->values)
          moves = moves || (one.moves && name == one.name);
    if (!(moves ? doc_put(d, h.layer, name.c_str(), d.stage->now, is)
                : doc_set(d, h.layer, name.c_str(), is)))
      break;
  }
  // Text values. Names starting with a space are bookkeeping stored with the
  // drag, such as ' path', which holds the earlier value. They are not written.
  for (const auto& [name, is] : h.said)
    if (name[0] != ' ' && !doc_say(d, h.layer, name.c_str(), is.c_str())) break;
  // If a group's bar was dragged and its start changed, move its keyframes by
  // the same amount.
  const auto bar = h.from.find(" bar"), start = h.tried.find("start");
  if (bar != h.from.end() && start != h.tried.end() &&
      start->second != h.from.at("start")) {
    const double by = start->second - h.from.at("start");
    doc_keys_by(d, h.layer, by);
    // What the group holds moves with it, as the contents of a precomposed
    // layer move with its bar.
    for (const int t : doc_under(d, h.layer)) {
      doc_set(d, t, "start",
              std::max(0.0, doc_number(d, t, "start", 0, 0) + by));
      doc_keys_by(d, t, by);
    }
  }
  return doc_acted(d);
}

bool doc_sequence(Doc& d, double overlap, double rate) {
  std::vector<int> order;
  const std::vector<int> laid = doc_laid(d);
  for (auto t = laid.rbegin(); t != laid.rend(); ++t) {
    const std::string kind = doc_word(d, *t, "kind");
    if (kind != "camera" && kind != "light" &&
        doc_number(d, *t, "visible", 0, 1) > 0.5 &&
        doc_number(d, *t, "lock", 0, 0) <= 0.5 &&
        doc_number(d, *t, "parent", 0, 0) == 0.0 && doc_lasts(d, *t) > 0.0)
      order.push_back(*t);
  }
  if (order.size() < 2)
    return d.error =
               "two layers that have a length are needed to follow one another",
           false;
  // Rounds a time to the nearest frame.
  const auto frame = [&](double s) { return std::round(s * rate) / rate; };
  double at = frame(doc_number(d, order[0], "start", 0, 0));
  doc_act(d);
  bool ok = true;
  for (const int t : order) {
    const double was = doc_number(d, t, "start", 0, 0), lasts = doc_lasts(d, t);
    if (std::fabs(at - was) > 1e-9)
      ok = ok && doc_set(d, t, "start", at) && doc_keys_by(d, t, at - was);
    at = std::max(at, frame(at + lasts - overlap));
  }
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

bool doc_time_align(Doc& d, const std::vector<int>& layers,
                    const std::string& how, double now) {
  if (layers.empty()) return d.error = "nothing to line up", false;
  const double whole = doc_seconds(d);
  // A layer without a duration, such as one drawn in the app, lasts to the end
  // of the project. doc_time_stretch reads it the same way.
  const auto lasting = [&](int t) {
    return doc_lasts(d, t) > 0.0
               ? doc_lasts(d, t)
               : std::max(1e-3, whole - doc_number(d, t, "start", 0, 0));
  };
  double first = 1e18, last = -1e18;
  for (const int t : layers)
    first = std::min(first, doc_number(d, t, "start", 0, 0)),
    last = std::max(last, doc_number(d, t, "start", 0, 0) + lasting(t));
  doc_act(d);
  bool ok = true;
  double after = doc_number(d, layers[0], "start", 0, 0);
  for (const int t : layers) {
    if (!ok) break;
    const double was = doc_number(d, t, "start", 0, 0), lasts = lasting(t);
    double to = was;
    if (how == "start")
      to = first;
    else if (how == "end")
      to = last - lasts;
    else if (how == "playhead")
      to = now;
    else if (how == "playhead_end")
      to = now - lasts;
    else if (how == "stagger")
      to = after, after += lasts;
    else if (how == "extend") {
      // If `now` is at or past the end there is nothing to extend.
      if (now >= was + lasts - 1e-3) continue;
      ok = doc_set(d, t, "start", std::max(0.0, now)) &&
           doc_set(d, t, "duration", was + lasts - std::max(0.0, now));
      // Move the playback offset on by how far the layer's own clock has run.
      if (const double on = doc_own_clock(d, t, std::max(0.0, now) - was);
          ok && on != 0.0)
        ok = doc_set(d, t, "begin",
                     std::max(0.0, doc_number(d, t, "begin", 0, 0) + on));
      continue;
    } else if (how == "trim_end") {
      // Final Cut Pro's Trim End: the end moves to `now` if `now` is inside the
      // layer.
      if (now > was + 1e-3 && now < was + lasts - 1e-3)
        ok = doc_set(d, t, "duration", now - was);
      continue;
    } else {
      ok = false, d.error =
                      "lined up by start, end, playhead, playhead_end, "
                      "stagger, extend or trim_end";
      break;
    }
    to = std::max(0.0, to);
    if (std::fabs(to - was) > 1e-9)
      ok = doc_set(d, t, "start", to) && doc_keys_by(d, t, to - was);
  }
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

bool doc_time_stretch(Doc& d, int layer, double speed, const std::string& hold,
                      double now) {
  const double was = std::fabs(doc_number(d, layer, "speed", 0, 1)),
               to = std::fabs(speed);
  if (to < 1e-3) return d.error = "a speed of nothing goes nowhere", false;
  if (hold != "start" && hold != "now" && hold != "end")
    return d.error = "held at start, now or end", false;
  // A layer without a duration lasts to the end of the project, as doc_split
  // counts it. `f` is the old speed divided by the new speed, which scales
  // times about the fixed point.
  const double start = doc_number(d, layer, "start", 0, 0),
               lasts = doc_lasts(d, layer) > 0.0
                           ? doc_lasts(d, layer)
                           : std::max(1e-3, doc_seconds(d) - start),
               f = was / to;
  // `at` is the fixed point of the stretch.
  const double at = hold == "start" ? start
                    : hold == "end" ? start + lasts
                                    : std::clamp(now, start, start + lasts);
  doc_act(d);
  // The SQL moves the keyframes of animated properties through a far-off range,
  // for the same reason as in doc_keys_by.
  bool ok =
      doc_set(d, layer, "speed", speed) &&
      doc_set(d, layer, "start", std::max(0.0, at + (start - at) * f)) &&
      doc_set(d, layer, "duration", lasts * f) &&
      doc_change(d,
                 sqlite3_mprintf(
                     "update keyframe set at = 1e7 + %!.17g + (at - %!.17g) * "
                     "%!.17g where layer = %d and name in (select name from "
                     "keyframe where layer = %d group by name having count(*) "
                     "> 1 or max(at) <> 0 or max(easing) is not null);"
                     "update keyframe set at = at - 1e7 where layer = %d and "
                     "at >= 5e6",
                     at, at, f, layer, layer, layer));
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

bool doc_reset(Doc& d, int layer, const std::string& names) {
  doc_act(d);
  bool ok = true;
  std::istringstream said(names);
  for (std::string n; ok && said >> n;)
    ok =
        doc_knows(d, layer, n.c_str()) &&
        doc_change(
            d, sqlite3_mprintf(
                   "delete from keyframe where layer = %d and name in (%Q, %Q)",
                   layer, n.c_str(), (n + "_loop").c_str()));
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

bool doc_undo(Doc& d) { return doc_undo_step(d, true); }

bool doc_redo(Doc& d) { return doc_undo_step(d, false); }

}  // namespace motolii

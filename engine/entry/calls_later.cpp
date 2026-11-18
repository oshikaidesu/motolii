// Queued changes (motolii_later / motolii_answer) and undo.
#include "entry/calls_later.h"

#include <sqlite3.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "document/cards.h"
#include "document/document.h"
#include "document/edit/arrange.h"
#include "document/edit/easings_put.h"
#include "document/edit/fx_put.h"
#include "document/edit/hold.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/parent.h"
#include "document/edit/paths.h"
#include "document/edit/presets.h"
#include "document/edit/relate.h"
#include "document/edit/stroke_put.h"
#include "document/edit/time_edit.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/import_adapter.h"
#include "document/scripts/expressions.h"
#include "document/scripts/recipes.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "entry/calls.h"
#include "entry/calls_sound.h"
#include "entry/crash_report.h"
#include "entry/motolii.h"
#include "entry/motolii_handle.h"
#include "entry/on_render_thread.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "entry/window.h"

using namespace motolii;

// Queues a change on the render thread and returns a ticket. The UI thread
// never waits. motolii_answer polls the result: -1 pending, 0 refused, >0 done.
// layer -1 = the layer that the last add/create made.
int motolii_later(Motolii* m, const char* call, int layer, const char* name,
                  const char* word, double number) {
  const std::string c = call ? call : "", n = name ? name : "",
                    w = word ? word : "";
  int ticket = 0;
  {
    std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
    ticket = ++m->later.tickets;
    m->render_thread.lastPosted.clear();
    m->render_thread.asked.push_back([m, c, n, w, layer = layer, number,
                                      ticket]() mutable {
      if (layer == -1) layer = m->later.last_added;
      breadcrumb(c.c_str());
      const long rows = sqlite3_total_changes(m->d->file);
      int ok = 0;
      std::string said;
      // A throw is caught so one bad call does not end the render thread.
      try {
        if (c == "say")
          ok = changes(m, (int)doc_say(doc(m), layer, n.c_str(), w.c_str()));
        // word "last_added" resolves to the layer the last add made.
        else if (c == "set")
          ok = changes(
              m, (int)doc_set(
                     doc(m), layer, n.c_str(),
                     w == "last_added"
                         ? m->later.last_added
                         : doc_macro_own(doc(m), layer, n.c_str(),
                                         doc(m).stage ? doc(m).stage->now : 0.0,
                                         number)));
        // number: nonzero keeps the drag as an undo step, 0 reverts.
        else if (c == "drag_end") {
          // A reverted drag changes no row; rebuild previews from current state.
          const int held = doc(m).held.layer;
          ok = changes(m, (int)doc_let_go(doc(m), number != 0.0));
          if (number == 0.0 && held >= 0)
            m->d->changes.changed.insert({held, ""}), snapshot_update(m);
        }
        // Keys the layer's volume down under other sounds.
        else if (c == "duck")
          ok = changes(m, (int)duck(m, layer));
        // name "effect": preview the effect in word without keeping it.
        else if (c == "drag_update")
          ok = (int)(n == "effect" ? doc_carry_effect(doc(m), w.c_str())
                                   : doc_carry(doc(m), n.c_str(), number, 0.0));
        else if (c == "undo")
          ok = (int)doc_undo(doc(m));
        else if (c == "redo")
          ok = (int)doc_redo(doc(m));
        // number: <0 rollback, 1 begin, 0 end.
        else if (c == "together") {
          ok =
              number < 0.0
                  ? (m->d->act.depth
                         ? (m->d->act.ok = false, (void)doc_acted(*m->d),
                            m->revision.fetch_add(1, std::memory_order_release),
                            snapshot_update(m), snapshot_time(m), 1)
                         : 0)
              : number != 0.0 ? (doc_act(*m->d), m->d->act.together = true, 1)
                              : (m->d->act.depth ? (int)doc_acted(*m->d) : 0);
          if (!m->d->act.depth) m->d->act.together = false;
        }
        // Result is the new layer.
        else if (c == "add")
          ok = m->later.last_added =
              changes(m, doc_add(doc(m), n.c_str(), w.c_str()));
        // SVG as editable path shapes, falling back to a picture.
        else if (c == "vector") {
          int on = doc_svg_paths(doc(m), w.c_str());
          if (!on) on = doc_add(doc(m), "", w.c_str());
          ok = m->later.last_added = changes(m, on);
        }
        else if (c == "create")
          ok = m->later.last_added = changes(m, doc_make(doc(m), w.c_str()));
        else if (c == "adapter")
          ok = m->later.last_added = changes(m, doc_door(doc(m), w, layer));
        else if (c == "code") {
          const std::string why = doc_code_saved(doc(m), w);
          ok = why.empty(), m->render_thread.changed = true,
          doc(m).changes.layers_changed = true;
          if (!ok) m->error = why;
          m->revision.fetch_add(1, std::memory_order_release),
              snapshot_update(m), snapshot_time(m);
        }
        // Evaluates JS in a running script. Answer is in motolii_answer_why.
        else if (c == "ask")
          said = doc_script_asked(doc(m), n, w), ok = 1;
        else if (c == "duplicate")
          ok = m->later.last_added = changes(m, doc_copy_above(doc(m), layer));
        else if (c == "split")
          ok = m->later.last_added =
              changes(m, doc_split(doc(m), layer, number));
        else if (c == "extract")
          ok = changes(m, (int)doc_extract(doc(m)));
        else if (c == "align") {
          std::istringstream said(w);
          std::string how;
          said >> how;
          std::vector<int> layers;
          for (int t; said >> t;) layers.push_back(t);
          ok = changes(m, (int)doc_align(doc(m), layers, how));
        }
        // Also flips keyframes.
        else if (c == "flip")
          ok = changes(
              m, (int)doc_value_by(doc(m), layer,
                                   w == "y" ? "scale_y" : "scale_x", 0, -1));
        // word: "hold playheadTime". number: new speed.
        else if (c == "time_stretch") {
          std::istringstream said(w);
          std::string hold;
          double now = 0.0;
          said >> hold >> now;
          ok = changes(m,
                       (int)doc_time_stretch(doc(m), layer, number, hold, now));
        }
        // number: playhead time.
        else if (c == "time_align") {
          std::istringstream said(w);
          std::string how;
          said >> how;
          std::vector<int> layers;
          for (int t; said >> t;) layers.push_back(t);
          ok = changes(m, (int)doc_time_align(doc(m), layers, how, number));
        }
        else if (c == "reset")
          ok = changes(m, (int)doc_reset(doc(m), layer, w));
        else if (c == "fit")
          ok = changes(m, (int)doc_fit(doc(m), layer, w));
        else if (c == "extract_sound")
          ok = m->later.last_added =
              changes(m, doc_extract_sound(doc(m), layer));
        else if (c == "freehand")
          ok = m->later.last_added =
              changes(m, doc_freehand(doc(m), w.c_str()));
        // Converts the shape to a path of its visible outline.
        else if (c == "outline")
          ok = changes(m, (int)doc_to_path(doc(m), layer));
        // word: "tolerance x y x y ..."
        else if (c == "curve")
          ok = m->later.last_added = changes(m, doc_curve(doc(m), w.c_str()));
        // word: "tool width x y pressure ..." (tools: 0 pen, 1 brush, 2 fill,
        // 3 eraser).
        else if (c == "brush")
          ok = m->later.last_added =
              changes(m, doc_brush(doc(m), w.c_str(), layer));
        // word: the file to save the whole layer in.
        else if (c == "copy")
          ok = (int)doc_preset_save(doc(m), layer, w.c_str(), true);
        else if (c == "paste")
          ok = m->later.last_added =
              changes(m, doc_preset_paste(doc(m), w.c_str(), number));
        // name: restrict to these properties (see presets.h).
        else if (c == "copy_style")
          ok = (int)doc_preset_save(doc(m), layer, w.c_str(), false, n);
        // name: restrict to these properties.
        else if (c == "keep_preset")
          ok = (int)doc_preset_keep(doc(m), layer, w, n);
        else if (c == "keep_element")
          ok = (int)doc_element_keep(doc(m), layer, w);
        // Duplicates the named effect card with its values.
        else if (c == "fx_duplicate")
          ok = changes(m, (int)!doc_fx_duplicate(doc(m), layer, w).empty());
        // Result is the new layer.
        else if (c == "element")
          ok = m->later.last_added =
              changes(m, doc_element_add(doc(m), w.c_str(), number));
        // Re-read elements whose files changed on disk.
        else if (c == "follow_elements")
          ok = changes(m, doc_elements_follow(doc(m))) >= 0;
        else if (c == "paste_style")
          ok = changes(m, (int)doc_preset_put(doc(m), layer, w.c_str()));
        else if (c == "remove")
          ok = changes(m, (int)doc_remove(doc(m), layer));
        // word: space-separated layer numbers.
        else if (c == "relate")
          ok = changes(
              m, (int)doc_relate(doc(m), layer, w.c_str(), m->playback.now));
        // Toggles an effect. A transition runs from now.
        else if (c == "fx_file")
          ok = changes(
              m, (int)doc_fx_file(doc(m), layer, w.c_str(), m->playback.now));
        else if (c == "fx_out")
          ok = changes(m, (int)doc_fx_out(doc(m), layer, w.c_str()));
        // Toggles effect visibility.
        else if (c == "fx_visible")
          ok = changes(m, (int)doc_fx_eye(doc(m), layer, w.c_str()));
        // number: places to move (positive = up).
        else if (c == "fx_move")
          ok = changes(m, (int)doc_fx_move(doc(m), layer, w.c_str(),
                                           (int)std::lround(number)));
        // Each slot is keyed by a 6-hex id so a layer can have several strokes.
        else if (c == "stroke_add")
          ok = changes(m, (int)doc_stroke_add(doc(m), layer));
        else if (c == "stroke_out")
          ok = changes(m, (int)doc_stroke_out(doc(m), layer, w.c_str()));
        // Makes `number` the leader without moving anything.
        else if (c == "lead")
          ok = changes(
              m, (int)doc_lead(doc(m), layer, (int)number, m->playback.now));
        // Removes the layer from relation `number`, reverting to what is under.
        else if (c == "free")
          ok = changes(m, (int)doc_free(doc(m), layer, (int)number,
                                        m->playback.now, false));
        // Dissolves the relation, baking each layer's current position.
        else if (c == "release")
          ok = changes(m, (int)doc_release(doc(m), layer, m->playback.now));
        else if (c == "mark")
          ok = changes(m, (int)doc_mark(doc(m), number, w.c_str()));
        // word: color 1-16 or 0 for none.
        else if (c == "mark_colour")
          ok = changes(
              m, (int)doc_mark_colour(doc(m), number, std::atoi(w.c_str())));
        // word "off" removes the guide.
        else if (c == "guide")
          ok =
              changes(m, (int)doc_guide(doc(m), n.c_str(), number, w != "off"));
        // number: start, word: end.
        else if (c == "work")
          ok = changes(m,
                       (int)doc_work_is(doc(m), number, std::atof(w.c_str())));
        // Not an undo step (see doc_setting).
        else if (c == "setting")
          ok = (int)doc_setting(doc(m), n.c_str(), w.c_str());
        else if (c == "size") {
          int wide = 0, high = 0;
          std::sscanf(w.c_str(), "%d %d", &wide, &high);
          char* say = doc_size_words(wide, high);
          // 16–8192 points each way, even (see doc_size_words).
          ok = say ? changes(m, (int)doc_change(*m->d, say))
                   : (m->d->error =
                          "a stage is from 16 to 8192 points each way, an even "
                          "number of them",
                      0);
        } else if (c == "raise")
          ok = changes(m, (int)doc_raise(doc(m), layer, (int)number));
        else if (c == "sequence")
          ok = changes(m, (int)doc_sequence(doc(m), number, RATE));
        else if (c == "key_here")
          ok = changes(m, (int)doc_key_here(doc(m), layer, n.c_str(), number));
        else if (c == "key")
          ok = changes(
              m, (int)doc_key(doc(m), layer, n.c_str(), std::atof(w.c_str()),
                              doc_macro_own(doc(m), layer, n.c_str(),
                                            std::atof(w.c_str()), number)));
        else if (c == "unkey")
          ok = changes(m, (int)doc_unkey(doc(m), layer, n.c_str(), number));
        else if (c == "stay")
          ok = changes(m, (int)doc_stay(doc(m), layer, n.c_str(), number));
        else if (c == "easing")
          ok = easing_is(m, layer, n.c_str(), number, w.c_str());
        // word: "layer\tprop\tfrom\tto\tvalue\teasing\n..." per line.
        // Moves keyframes in one pass: unkey at from, key at to, set easing.
        else if (c == "slide_keys") {
          Doc& d = doc(m);
          ok = 1;
          std::istringstream lines(w);
          std::string line;
          // Two-pass: unkey all first, then re-key, to avoid collisions.
          std::vector<std::tuple<int, std::string, double, double, double,
                                 std::string>>
              entries;
          while (std::getline(lines, line)) {
            if (line.empty()) continue;
            int t = 0;
            char prop[128] = {}, easing[256] = {};
            double from = 0, to = 0, val = 0;
            if (std::sscanf(line.c_str(), "%d\t%127[^\t]\t%lf\t%lf\t%lf\t%255[^\n]",
                            &t, prop, &from, &to, &val, easing) >= 5) {
              entries.emplace_back(t, prop, from, to, val,
                                   easing[0] ? easing : "");
            }
          }
          for (const auto& [t, prop, from, to, val, easing] : entries)
            doc_unkey(d, t, prop.c_str(), from);
          for (const auto& [t, prop, from, to, val, easing] : entries) {
            doc_key(d, t, prop.c_str(), to, val);
            if (!easing.empty()) doc_easing(d, t, prop.c_str(), to, easing.c_str());
          }
        }
        // word: "layer\tprop\tat\n..." per line. Batched unkey.
        else if (c == "unkey_batch") {
          Doc& d = doc(m);
          ok = 1;
          std::istringstream lines(w);
          std::string line;
          while (std::getline(lines, line)) {
            if (line.empty()) continue;
            int t = 0;
            char prop[128] = {};
            double at = 0;
            if (std::sscanf(line.c_str(), "%d\t%127[^\t]\t%lf", &t, prop,
                            &at) >= 3)
              doc_unkey(d, t, prop, at);
          }
        }
        // word: "layer\tprop\tat\tvalue[\teasing]\n...". Batched key+easing.
        else if (c == "paste_keys") {
          Doc& d = doc(m);
          ok = 1;
          std::istringstream lines(w);
          std::string line;
          while (std::getline(lines, line)) {
            if (line.empty()) continue;
            int t = 0;
            char prop[128] = {}, easing[256] = {};
            double at = 0, val = 0;
            if (std::sscanf(line.c_str(), "%d\t%127[^\t]\t%lf\t%lf\t%255[^\n]", &t,
                            prop, &at, &val, easing) >= 4) {
              doc_key(d, t, prop, at, val);
              if (easing[0]) doc_easing(d, t, prop, at, easing);
            }
          }
        }
        // word: "layer\tprop\tat\teasing\n...". Batched easing set.
        else if (c == "set_easings") {
          ok = 1;
          std::istringstream lines(w);
          std::string line;
          while (std::getline(lines, line)) {
            if (line.empty()) continue;
            int t = 0;
            char prop[128] = {}, easing[256] = {};
            double at = 0;
            if (std::sscanf(line.c_str(), "%d\t%127[^\t]\t%lf\t%255[^\n]", &t,
                            prop, &at, easing) >= 4)
              easing_is(m, t, prop, at, easing);
          }
        }
        // Defines a custom easing as an SQL expression.
        else if (c == "define")
          ok = define_is(m, n.c_str(), w.c_str());
        // Mid-drag preview: shows the open undo step without ending it.
        else if (c == "show") {
          Doc& d = doc(m);
          ok = 1;
          if (d.act.depth && d.act.unmatched)
            d.act.unmatched = false, doc_forget(d),
            ok = changes(m, (int)doc_match(d));
          // Also update previews; what changed is known only when the step ends.
          if (d.act.depth)
            d.changes.changed.insert({layer, ""}), snapshot_update(m),
                snapshot_time(m);
        }
        // Like "show" but only keyframe times changed: scoped cache clear.
        else if (c == "show_keys") {
          Doc& d = doc(m);
          ok = 1;
          if (d.act.depth) {
            d.act.unmatched = false;
            doc_forget_keys(d, layer);
            doc_evaluate(d, d.stage->now);
            d.changes.changed.insert({layer, ""}), snapshot_update(m),
                snapshot_time(m);
          }
        }
        // Like "show" but for multiple layers at once.
        else if (c == "show_layers") {
          Doc& d = doc(m);
          ok = 1;
          if (d.act.depth && d.act.unmatched)
            d.act.unmatched = false, doc_forget(d),
                ok = changes(m, (int)doc_match(d));
          if (d.act.depth) {
            std::istringstream in(w);
            int t;
            while (in >> t) d.changes.changed.insert({t, ""});
            snapshot_update(m), snapshot_time(m);
          }
        }
        // Like "show_keys" but for multiple layers at once.
        else if (c == "show_keys_layers") {
          Doc& d = doc(m);
          ok = 1;
          if (d.act.depth) {
            d.act.unmatched = false;
            std::istringstream in(w);
            int t;
            while (in >> t) {
              doc_forget_keys(d, t);
              d.changes.changed.insert({t, ""});
            }
            doc_evaluate(d, d.stage->now);
            snapshot_update(m), snapshot_time(m);
          }
        } else if (c == "effect")
          ok = changes(m, (int)doc_effect(doc(m), layer, n.c_str(), number));
        // word: "x y hx hy" in image points.
        else if (c == "pen") {
          double x = 0.0, y = 0.0, hx = 0.0, hy = 0.0;
          std::sscanf(w.c_str(), "%lf %lf %lf %lf", &x, &y, &hx, &hy);
          ok = m->later.last_added =
              changes(m, doc_pen(doc(m), layer, x, y, hx, hy));
        }
        // Result is 1 once the live image is open.
        else if (c == "live")
          ok = live_is(m);
        // layer: picked, number: under pointer.
        else if (c == "pick")
          ok = pick_is(m, layer, (int)number);
        // word: space-separated layer ids to track in previews.
        else if (c == "watch") {
          m->window.watched.clear();
          std::istringstream in(w);
          for (int t; in >> t;) m->window.watched.insert(t);
          // Snapshot now, don't wait for the next preview cycle.
          snapshot_time(m);
          ok = 1, m->render_thread.changed = true;
        }
        // word: "w h x y scale point". Result 1 when image exists.
        else if (c == "desk") {
          int dw = 0, dh = 0;
          double x = 0.0, y = 0.0, sc = 0.0, pt = 0.0;
          std::sscanf(w.c_str(), "%d %d %lf %lf %lf %lf", &dw, &dh, &x, &y, &sc,
                      &pt);
          ok = desk_is(m, dw, dh, x, y, sc, pt);
        }
        // word: non-empty when Camera View is open.
        else if (c == "camera_view")
          ok = 1, m->window.second = !w.empty(),
          m->render_thread.changed = true;
        // Empty word selects the project's camera.
        else if (c == "view_camera")
          ok = view_camera_is(m, w.c_str());
        // Begins a drag on this layer.
        else if (c == "drag_start")
          ok = (int)doc_hold(doc(m), layer);
        else
          m->error =
              "a change asked later is one of: code, adapter, view_camera, "
              "camera_view, say, set, drag_start, drag_update, duck, drag_end, "
              "undo, redo, together, add, create, pen, element, keep_element, "
              "follow_elements, fx_duplicate, duplicate, split, align, "
              "time_align, reset, fit, flip, extract_sound, freehand, brush, "
              "outline, copy, paste, copy_style, paste_style, keep_preset, "
              "remove, mark, guide, work, raise, sequence, key_here, unkey, "
              "stay, easing, effect, fx_file, fx_visible, fx_move, "
              "stroke_add, stroke_out, size, "
              "watch, pick, desk, live, relate, lead, free, release, setting, "
              "ask";
      } catch (const std::exception& e) {
        ok = 0;
        std::fprintf(stderr, "motolii: %s threw: %s\n", c.c_str(), e.what());
        m->error = std::string(c) + " threw: " + e.what();
      } catch (...) {
        ok = 0;
        std::fprintf(stderr, "motolii: %s threw (unknown)\n", c.c_str());
        m->error = std::string(c) + " threw (unknown)";
      }
      // Rebuild previews before answering so the app sees the new state.
      try {
        if (sqlite3_total_changes(m->d->file) != rows)
          m->revision.fetch_add(1, std::memory_order_release),
              snapshot_update(m), snapshot_time(m);
      } catch (const std::exception& e) {
        std::fprintf(stderr, "motolii: snapshot after %s threw: %s\n",
                     c.c_str(), e.what());
      } catch (...) {
        std::fprintf(stderr, "motolii: snapshot after %s threw (unknown)\n",
                     c.c_str());
      }
      m->render_thread.changed = true;
      {
        std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
        m->later.answers[ticket] = {ok,
                                    ok ? said : std::string(motolii_why(m))};
      }
      // Notify the app that an answer is ready (motolii_add_listener).
      {
        std::lock_guard<std::mutex> hold(m->snapshots.lock);
        m->snapshots.pending |= 8;
      }
    });
  }
  m->render_thread.asked_now.notify_one();
  return ticket;
}
// 1 = done, 0 = refused (call motolii_answer_why), -1 = pending.
int motolii_answer(Motolii* m, int ticket) {
  std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
  const auto found = m->later.answers.find(ticket);
  if (found == m->later.answers.end()) return -1;
  const int ok = found->second.first;
  m->later.answered_why = found->second.second;
  m->later.answers.erase(found);
  return ok;
}
// Reason for the last refusal.
const char* motolii_answer_why(Motolii* m) {
  return m->later.answered_why.c_str();
}
// Returns nonzero on success.
int motolii_undo(Motolii* m) {
  return on_render_thread(m, [=] { return (int)(doc_undo(doc(m))); });
}

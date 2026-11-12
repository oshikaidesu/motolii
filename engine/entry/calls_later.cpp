// calls_later.cpp: the calls of motolii.h for changes that are queued and
// answered later, which are motolii_later and motolii_answer, and for undo.
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
#include "document/edit/time_edit.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match.h"
#include "document/scripts/adapter.h"
#include "document/scripts/expressions.h"
#include "document/scripts/recipes.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "entry/calls.h"
#include "entry/calls_sound.h"
#include "entry/motolii.h"
#include "entry/motolii_handle.h"
#include "entry/on_render_thread.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "entry/window.h"

using namespace motolii;

// Queues a change behind every other change on the render thread and returns a
// ticket at once, so that the app's UI thread never waits for the render
// thread. motolii_answer returns the result for a ticket: -1 if the change is
// not done yet, 0 if it was refused, and 1 if it is done. After a refusal
// motolii_answer_why returns the reason, and after `ask` what the script
// answered. For add and create the result is the new layer.
//
// `call` selects the change and `layer`, `name`, `word` and `number` are its
// arguments. Their meaning depends on the call and is given beside each call
// below. The accepted calls are also listed in the error message at the end of
// the chain. A `layer` of -1 means the layer that the last add or create made.
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
      // The layer that the last queued add or create made.
      if (layer == -1) layer = m->later.last_added;
      const long rows = sqlite3_total_changes(m->d->file);
      int ok = 0;
      // What a call that asks gives back as words (ask).
      std::string said;
      // A call that throws is refused with the text of the exception. That
      // keeps one bad call from ending the render thread; the app waits on its
      // ticket.
      try {
        // word: the new text of property `name`.
        if (c == "say")
          ok = changes(m, (int)doc_say(doc(m), layer, n.c_str(), w.c_str()));
        // name: the property. number: its new value. The word "last_added"
        // makes the value the layer that the last add made, for a property that
        // names a layer, such as a connected behaviour or a leader.
        else if (c == "set")
          ok = changes(
              m, (int)doc_set(
                     doc(m), layer, n.c_str(),
                     w == "last_added"
                         ? m->later.last_added
                         : doc_macro_own(doc(m), layer, n.c_str(),
                                         doc(m).stage ? doc(m).stage->now : 0.0,
                                         number)));
        // number: nonzero keeps what was dragged as one undo step, 0 gives it
        // up.
        else if (c == "drag_end") {
          // A drag given up changes no row, so the previews that followed it
          // are made again as the project is.
          const int held = doc(m).held.layer;
          ok = changes(m, (int)doc_let_go(doc(m), number != 0.0));
          if (number == 0.0 && held >= 0)
            m->d->changes.changed.insert({held, ""}), snapshot_update(m);
        }
        // Audacity's Auto Duck: the layer's volume is keyed down under the
        // other sounds.
        else if (c == "duck")
          ok = changes(m, (int)duck(m, layer));
        // name: what is dragged. The name "effect" shows the effect file in
        // `word` on the held layer without keeping it.
        else if (c == "drag_update")
          ok = (int)(n == "effect" ? doc_carry_effect(doc(m), w.c_str())
                                   : doc_carry(doc(m), n.c_str(), number, 0.0));
        else if (c == "undo")
          ok = (int)doc_undo(doc(m));
        else if (c == "redo")
          ok = (int)doc_redo(doc(m));
        // number: below 0 gives up the open undo step, 1 begins one, and 0 ends
        // it with the step's result.
        else if (c == "together") {
          // Below 0 the open step is given up, as SQLite's rollback does. It
          // was only a try on the preview, so nothing is stored, and the app's
          // previews are made again as they were.
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
        // name: the kind. word: the file. The result is the new layer.
        else if (c == "add")
          ok = m->later.last_added =
              changes(m, doc_add(doc(m), n.c_str(), w.c_str()));
        // word: the create script. The result is the new layer.
        else if (c == "create")
          ok = m->later.last_added = changes(m, doc_make(doc(m), w.c_str()));
        // word: code from the net. layer: the layer picked, or 0. The result is
        // the new layer.
        else if (c == "adapter")
          ok = m->later.last_added = changes(m, doc_door(doc(m), w, layer));
        // word: the file of a program, which was saved.
        else if (c == "code") {
          const std::string why = doc_code_saved(doc(m), w);
          // Its parameters may be others now.
          ok = why.empty(), m->render_thread.changed = true,
          doc(m).changes.layers_changed = true;
          if (!ok) m->error = why;
          m->revision.fetch_add(1, std::memory_order_release),
              snapshot_update(m), snapshot_time(m);
        }
        // name: a code file the project runs. word: JavaScript. The file's
        // running script evaluates it and the result, as text, is the answer's
        // words (motolii_answer_why). Nothing of the project is changed.
        else if (c == "ask")
          said = doc_script_asked(doc(m), n, w), ok = 1;
        // The result is the new layer.
        else if (c == "duplicate")
          ok = m->later.last_added = changes(m, doc_copy_above(doc(m), layer));
        // number: the time to split at. The result is the part after it.
        else if (c == "split")
          ok = m->later.last_added =
              changes(m, doc_split(doc(m), layer, number));
        // Take the work area out and close the gap.
        else if (c == "extract")
          ok = changes(m, (int)doc_extract(doc(m)));
        // word: how to align, then the layer numbers.
        else if (c == "align") {
          std::istringstream said(w);
          std::string how;
          said >> how;
          std::vector<int> layers;
          for (int t; said >> t;) layers.push_back(t);
          ok = changes(m, (int)doc_align(doc(m), layers, how));
        }
        // word: x or y. The layer's keyframes are turned over too.
        else if (c == "flip")
          ok = changes(
              m, (int)doc_value_by(doc(m), layer,
                                   w == "y" ? "scale_y" : "scale_x", 0, -1));
        // word: where the layer is held in place, start, now or end, then the
        // playhead time. number: its new speed.
        else if (c == "time_stretch") {
          std::istringstream said(w);
          std::string hold;
          double now = 0.0;
          said >> hold >> now;
          ok = changes(m,
                       (int)doc_time_stretch(doc(m), layer, number, hold, now));
        }
        // word: how to align, then the layer numbers. number: the playhead
        // time.
        else if (c == "time_align") {
          std::istringstream said(w);
          std::string how;
          said >> how;
          std::vector<int> layers;
          for (int t; said >> t;) layers.push_back(t);
          ok = changes(m, (int)doc_time_align(doc(m), layers, how, number));
        }
        // word: the names of the properties.
        else if (c == "reset")
          ok = changes(m, (int)doc_reset(doc(m), layer, w));
        // word: fit, fill or stretch.
        else if (c == "fit")
          ok = changes(m, (int)doc_fit(doc(m), layer, w));
        // The result is the copy that is heard.
        else if (c == "extract_sound")
          ok = m->later.last_added =
              changes(m, doc_extract_sound(doc(m), layer));
        // word: the outline's points in image points, as x y for each. The
        // result is the new shape.
        else if (c == "freehand")
          ok = m->later.last_added =
              changes(m, doc_freehand(doc(m), w.c_str()));
        // Alight Motion's Convert to Outline: the shape becomes a path of the
        // outline it shows.
        else if (c == "outline")
          ok = changes(m, (int)doc_to_path(doc(m), layer));
        // word: how far the curve may stray, in image points, then the points
        // of the stroke as x y for each. The result is the new path.
        else if (c == "curve")
          ok = m->later.last_added = changes(m, doc_curve(doc(m), w.c_str()));
        // word: the tool, how wide, then each point of the stroke in image
        // points as x y and its pressure. The tools are 0 pen, 1 brush, 2 fill
        // and 3 eraser. The result is the new shape, or the one erased from.
        else if (c == "brush")
          ok = m->later.last_added =
              changes(m, doc_brush(doc(m), w.c_str(), layer));
        // word: the file to save the whole layer in.
        else if (c == "copy")
          ok = (int)doc_preset_save(doc(m), layer, w.c_str(), true);
        // word: that file. number: when it begins. The result is the new layer.
        else if (c == "paste")
          ok = m->later.last_added =
              changes(m, doc_preset_paste(doc(m), w.c_str(), number));
        // word: the file. name: only these properties, such as those of one
        // effect card. See document/edit/presets.h.
        else if (c == "copy_style")
          ok = (int)doc_preset_save(doc(m), layer, w.c_str(), false, n);
        // word: the preset's name on the shelf. name: only these properties,
        // such as those of one effect card.
        else if (c == "keep_preset")
          ok = (int)doc_preset_keep(doc(m), layer, w, n);
        // word: the element's name among the elements.
        else if (c == "keep_element")
          ok = (int)doc_element_keep(doc(m), layer, w);
        // word: the title of the effect's card. The effect is put on again
        // after it, with its values.
        else if (c == "fx_duplicate")
          ok = changes(m, (int)!doc_fx_duplicate(doc(m), layer, w).empty());
        // word: the element's file. number: when it begins. The result is the
        // new layer.
        else if (c == "element")
          ok = m->later.last_added =
              changes(m, doc_element_add(doc(m), w.c_str(), number));
        // Each element put in whose file was written since is made again as the
        // file is now.
        else if (c == "follow_elements")
          ok = changes(m, doc_elements_follow(doc(m))) >= 0;
        else if (c == "paste_style")
          ok = changes(m, (int)doc_preset_put(doc(m), layer, w.c_str()));
        // Removes the layer.
        else if (c == "remove")
          ok = changes(m, (int)doc_remove(doc(m), layer));
        // layer: the relation. word: the layer numbers put in it, as they show
        // now.
        else if (c == "relate")
          ok = changes(
              m, (int)doc_relate(doc(m), layer, w.c_str(), m->playback.now));
        // word: an effect file. It is put at the end of the layer's effects, or
        // taken out. A transition runs from now.
        else if (c == "fx_file")
          ok = changes(
              m, (int)doc_fx_file(doc(m), layer, w.c_str(), m->playback.now));
        // word: the title of an effect's card. The effect is taken off.
        else if (c == "fx_out")
          ok = changes(m, (int)doc_fx_out(doc(m), layer, w.c_str()));
        // word: the title of an effect's card. The effect is turned off, or on
        // again.
        else if (c == "fx_visible")
          ok = changes(m, (int)doc_fx_eye(doc(m), layer, w.c_str()));
        // word: the title of an effect's card. number: how many places to move
        // it up or down the list.
        else if (c == "fx_move")
          ok = changes(m, (int)doc_fx_move(doc(m), layer, w.c_str(),
                                           (int)std::lround(number)));
        // Make `number` the leader of the relation `layer`, with nothing
        // moving.
        else if (c == "lead")
          ok = changes(
              m, (int)doc_lead(doc(m), layer, (int)number, m->playback.now));
        // Take the layer out of the relation `number`. It goes back to what is
        // under it, as when the relation is deleted. Only bake keeps where it
        // shows.
        else if (c == "free")
          ok = changes(m, (int)doc_free(doc(m), layer, (int)number,
                                        m->playback.now, false));
        // Let go of the relation `layer`, each of its layers staying where it
        // shows now.
        else if (c == "release")
          ok = changes(m, (int)doc_release(doc(m), layer, m->playback.now));
        else if (c == "mark")
          ok = changes(m, (int)doc_mark(doc(m), number, w.c_str()));
        // number: the time of the mark. word: its color, 1 to 16, or 0 for
        // none.
        else if (c == "mark_colour")
          ok = changes(
              m, (int)doc_mark_colour(doc(m), number, std::atoi(w.c_str())));
        // name: the axis. number: the position. word: "off" removes the guide.
        else if (c == "guide")
          ok =
              changes(m, (int)doc_guide(doc(m), n.c_str(), number, w != "off"));
        // number: the start of the work area. word: its end.
        else if (c == "work")
          ok = changes(m,
                       (int)doc_work_is(doc(m), number, std::atof(w.c_str())));
        // name: a setting of the app that is stored in the project. word: its
        // value, or "" for none. It is not an undo step, see doc_setting.
        else if (c == "setting")
          ok = (int)doc_setting(doc(m), n.c_str(), w.c_str());
        // word: "wide high", the preview's size that the project asks for. The
        // app opens at it again.
        else if (c == "size") {
          int wide = 0, high = 0;
          std::sscanf(w.c_str(), "%d %d", &wide, &high);
          char* say = doc_size_words(wide, high);
          // A size is from 16 to 8192 points each way and even; see
          // doc_size_words.
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
        // name: the easing. word: its SQL expression.
        else if (c == "define")
          ok = define_is(m, n.c_str(), w.c_str());
        // Shows what the open undo step has made so far on the preview while a
        // drag is still in progress, as document/edit/paths.h does for a shape
        // being placed. The step is not ended.
        else if (c == "show") {
          Doc& d = doc(m);
          ok = 1;
          if (d.act.depth && d.act.unmatched)
            d.act.unmatched = false, doc_forget(d),
            ok = changes(m, (int)doc_match(d));
          // Also update the app's previews of that layer. What changed is known
          // only when the step ends, so the bars and numbers follow the drag as
          // well.
          if (d.act.depth)
            d.changes.changed.insert({layer, ""}), snapshot_update(m),
                snapshot_time(m);
        } else if (c == "effect")
          ok = changes(m, (int)doc_effect(doc(m), layer, n.c_str(), number));
        // word: where the pointer is and its handle as "x y hx hy", in image
        // points. The result is the path shape.
        else if (c == "pen") {
          double x = 0.0, y = 0.0, hx = 0.0, hy = 0.0;
          std::sscanf(w.c_str(), "%lf %lf %lf %lf", &x, &y, &hx, &hy);
          ok = m->later.last_added =
              changes(m, doc_pen(doc(m), layer, x, y, hx, hy));
        }
        // Open the preview's live image. The result is 1 once it is open.
        else if (c == "live")
          ok = live_is(m);
        // layer: the layer picked in the app. number: the layer under the
        // pointer.
        else if (c == "pick")
          ok = pick_is(m, layer, (int)number);
        // word: the layer numbers whose moving values the app shows, separated
        // by spaces. Their values are in the next preview.
        else if (c == "watch") {
          m->window.watched.clear();
          std::istringstream in(w);
          for (int t; in >> t;) m->window.watched.insert(t);
          // Get their values at once, not with the next preview.
          snapshot_time(m);
          ok = 1, m->render_thread.changed = true;
        }
        // word: "w h x y scale point", the tool panel's size, its middle, its
        // scale and the point. The result is 1 once the tool panel's image
        // exists.
        else if (c == "desk") {
          int dw = 0, dh = 0;
          double x = 0.0, y = 0.0, sc = 0.0, pt = 0.0;
          std::sscanf(w.c_str(), "%d %d %lf %lf %lf %lf", &dw, &dh, &x, &y, &sc,
                      &pt);
          ok = desk_is(m, dw, dh, x, y, sc, pt);
        }
        // word: not empty when the Camera View tab is open.
        else if (c == "camera_view")
          ok = 1, m->window.second = !w.empty(),
          m->render_thread.changed = true;
        // word: where the app's working camera stands, as in view_camera_is. An
        // empty word selects the project's camera.
        else if (c == "view_camera")
          ok = view_camera_is(m, w.c_str());
        // The user starts dragging: the next drag update belongs to this layer.
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
              "stay, easing, effect, fx_file, fx_visible, fx_move, size, "
              "watch, pick, desk, live, relate, lead, free, release, setting, "
              "ask";
      } catch (const std::exception& e) {
        ok = 0;
        std::fprintf(stderr, "motolii: %s threw: %s\n", c.c_str(), e.what());
        m->error = std::string(c) + " threw: " + e.what();
      }
      // Make new previews before the answer, so that the app reads what is so
      // now.
      if (sqlite3_total_changes(m->d->file) != rows)
        m->revision.fetch_add(1, std::memory_order_release), snapshot_update(m),
            snapshot_time(m);
      m->render_thread.changed = true;
      {
        std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
        m->later.answers[ticket] = {ok,
                                    ok ? said : std::string(motolii_why(m))};
      }
      // Notify the app that an answer is there, see motolii_add_listener, as
      // Thermion's registry is notified when a request is done.
      {
        std::lock_guard<std::mutex> hold(m->snapshots.lock);
        m->snapshots.pending |= 8;
      }
    });
  }
  m->render_thread.asked_now.notify_one();
  return ticket;
}
// Returns the result of the queued change with `ticket`, and forgets it: 1 if
// done, 0 if refused, or -1 if it is not done yet. Call motolii_answer_why
// after a 0.
int motolii_answer(Motolii* m, int ticket) {
  std::lock_guard<std::mutex> hold(m->render_thread.asked_lock);
  const auto found = m->later.answers.find(ticket);
  if (found == m->later.answers.end()) return -1;
  const int ok = found->second.first;
  m->later.answered_why = found->second.second;
  m->later.answers.erase(found);
  return ok;
}
// Returns the reason the change last answered by motolii_answer was refused.
const char* motolii_answer_why(Motolii* m) {
  return m->later.answered_why.c_str();
}
// Undoes the last undo step. Returns nonzero on success.
int motolii_undo(Motolii* m) {
  return on_render_thread(m, [=] { return (int)(doc_undo(doc(m))); });
}

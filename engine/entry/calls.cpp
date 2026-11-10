#include "entry/calls.h"

#include <math/mat4.h>
#include <sqlite3.h>
#include <strings.h>

#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "document/cards.h"
#include "document/edit/arrange.h"
#include "document/edit/easings_put.h"
#include "document/edit/fx_put.h"
#include "document/edit/hold.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/presets.h"
#include "document/edit/relate.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "document/scripts/recipes.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "entry/motolii.h"
#include "entry/render_thread.h"
#include "entry/snapshot.h"
#include "entry/window.h"
#include "media/midi_notes.h"
#include "motion/easing_curves.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace motolii;

// Adds a layer of kind `kind` made from `file`. Returns nonzero on success.
int motolii_add(Motolii* m, const char* kind, const char* file) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_add(doc(m), kind, file))); });
}
// Removes the layer. Returns nonzero on success.
int motolii_remove(Motolii* m, int layer) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_remove(doc(m), layer))); });
}
// Sets property `name` of the layer to `number`. The number goes through
// doc_macro_own first, which turns it into the property's own value when a
// macro drives the property; see document/scripts/expressions.h. Returns
// nonzero on success.
int motolii_set(Motolii* m, int layer, const char* name, double number) {
  return on_render_thread(m, [=] {
    return changes(
        m, (int)(doc_set(
               doc(m), layer, name,
               doc_macro_own(doc(m), layer, name,
                             doc(m).stage ? doc(m).stage->now : 0.0, number))));
  });
}
// Sets the text property `name` of the layer to `word`. Returns nonzero on
// success.
int motolii_say(Motolii* m, int layer, const char* name, const char* word) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_say(doc(m), layer, name, word))); });
}
// Sets the keyframe of property `name` at time `at` to `number`, converted as
// in motolii_set. Returns nonzero on success.
int motolii_key(Motolii* m, int layer, const char* name, double at,
                double number) {
  return on_render_thread(m, [=] {
    return changes(
        m, (int)(doc_key(doc(m), layer, name, at,
                         doc_macro_own(doc(m), layer, name, at, number))));
  });
}
// Turns the notes of a MIDI file into keyframes of a property, as om_midi does
// in After Effects; see midi_notes.h, midi_keys. `kind` selects what the notes
// produce: velocity, pitch, count, on or bool. `channel` selects the MIDI
// channel. A positive `bpm` replays the file at that tempo. Every keyframe uses
// the Hold easing. Returns nonzero on success.
int motolii_midi(Motolii* m, int layer, const char* name, const char* file,
                 const char* kind, int channel, double bpm) {
  std::vector<MidiEvent> events = midi_events(file);
  // Rescale the times from the file's own tempo to `bpm`, as the BPM box of
  // om_midi does. A time is its beat count times 60 divided by the tempo.
  if (bpm > 0) {
    const double by = midi_bpm(file) / bpm;
    for (MidiEvent& e : events) e.at *= by;
  }
  const std::map<double, double> keys = midi_keys(events, kind, channel);
  std::vector<double> at, is;
  for (const auto& [t, v] : keys) at.push_back(t), is.push_back(v);
  if (at.empty())
    return on_render_thread(m, [=, said = std::string(kind)] {
      return (doc(m).error = "no " + said + " keys of notes in " + file +
                             " (kinds: velocity pitch count on bool)",
              0);
    });
  // Remove the property's existing keyframes first and then make them again
  // from the file, as om_midi makes a new null object each time. Both steps are
  // one undo step.
  return on_render_thread(m, [=] {
    Doc& d = doc(m);
    doc_act(d);
    const bool ok = doc_stay(d, layer, name, 0.0) &&
                    doc_key_many(d, layer, name, (int)at.size(), at.data(),
                                 is.data(), "Hold");
    return changes(m, (int)(doc_acted(d) && ok));
  });
}

namespace motolii {

int easing_is(Motolii* m, int layer, const char* name, double at,
              const char* easing) {
  Doc& d = doc(m);
  bool here = false;
  doc_rows(d, sqlite3_mprintf("select 1 from easing where name = %Q", easing),
           [&](sqlite3_stmt*) { here = true; });
  const auto easings = doc_own_easings();
  const auto own = easings.find(easing);
  if (here || own == easings.end())
    return changes(m, (int)(doc_easing(d, layer, name, at, easing)));
  // The user's own easing: write it into the project and put it on the keyframe
  // in one undo step.
  doc_act(d);
  if (!doc_define(d, easing, own->second.c_str()) ||
      !doc_easing(d, layer, name, at, easing))
    d.act_ok = false;
  return changes(m, (int)doc_acted(d));
}

}  // namespace motolii

// Puts easing `easing` on the keyframe of property `name` at time `at`. Returns
// nonzero on success.
int motolii_easing(Motolii* m, int layer, const char* name, double at,
                   const char* easing) {
  return on_render_thread(
      m, [=] { return easing_is(m, layer, name, at, easing); });
}

namespace motolii {

int define_is(Motolii* m, const char* easing, const char* expression) {
  Doc& d = doc(m);
  doc_act(d);
  // Write the user's own easings that the expression asks for through
  // way('name').
  for (const auto& [name, own] : doc_own_easings()) {
    if (!strstr(expression, ("way('" + name).c_str())) continue;
    bool here = false;
    doc_rows(
        d,
        sqlite3_mprintf("select 1 from easing where name = %Q", name.c_str()),
        [&](sqlite3_stmt*) { here = true; });
    if (!here && !doc_define(d, name.c_str(), own.c_str())) d.act_ok = false;
  }
  if (!doc_define(d, easing, expression)) d.act_ok = false;
  // Delete the easings that were composed or reversed, named with × or starting
  // with Reverse:, and that no keyframe uses and no other easing refers to any
  // more. The app makes one at each step of a drag.
  if (d.act_ok &&
      !doc_change(
          d, sqlite3_mprintf(
                 "delete from easing where (name glob '*×*' or name glob "
                 "'Reverse:*') and name <> %Q and name not in (select easing "
                 "from keyframe where easing is not null) and not exists "
                 "(select 1 from easing o where o.name <> easing.name and "
                 "o.expression like '%%''' || easing.name || '%%')",
                 easing)))
    d.act_ok = false;
  return changes(m, (int)doc_acted(d));
}

}  // namespace motolii

// Returns the names of the effects that can be added, separated by spaces.
const char* motolii_effect_names(Motolii* m) {
  return by_look(m, [m] { return (m->listed = doc_effect_names()).c_str(); });
}
// Adds effect `name` to the layer at time `at`. Returns nonzero on success.
int motolii_effect(Motolii* m, int layer, const char* name, double at) {
  return on_render_thread(m, [=] {
    return changes(m, (int)(doc_effect(doc(m), layer, name, at)));
  });
}
// Returns the names of the easings that the project has, as text.
const char* motolii_easings(Motolii* m) {
  return by_look(m, [m] { return (m->listed = doc_easings(*m->d)).c_str(); });
}
// Evaluates the arithmetic text `sum` with SQLite and stores the result in *is.
// Returns 1 on success, or 0 if the text is not plain arithmetic or SQLite
// gives no number.
int motolii_work_out(Motolii* m, const char* sum, double* is) {
  const std::string said(sum);
  // Accept only arithmetic characters, so that all that is ever sent to SQLite
  // is a sum.
  if (said.find_first_not_of("0123456789.+-*/()eE ") != std::string::npos)
    return 0;
  static const std::regex whole("(^|[^0-9.eE])([0-9]+)(?![0-9.eE])");
  // SQLite divides whole numbers as whole numbers, so 1/3 would be 0. Make
  // every whole number real.
  const std::string real = std::regex_replace(said, whole, "$1$2.0");
  return by_look(m, [&] {
    sqlite3_stmt* asked = nullptr;
    char* text = sqlite3_mprintf("select (%s)", real.c_str());
    const bool prepared =
        sqlite3_prepare_v2(m->d->file, text, -1, &asked, nullptr) == SQLITE_OK;
    sqlite3_free(text);
    const bool ok = prepared && sqlite3_step(asked) == SQLITE_ROW &&
                    sqlite3_column_type(asked, 0) != SQLITE_NULL;
    if (ok) *is = sqlite3_column_double(asked, 0);
    sqlite3_finalize(asked);
    return (int)ok;
  });
}
// Reads the value of property `name` at time `at` into *is as the preview shows
// it. Returns 0 if the layer has no such property, 1 if the value is the
// property's own, and 2 if a relation or a behaviour drives it. In the driven
// case *is is the property's own value, not the driven one.
int motolii_shows(Motolii* m, int layer, const char* name, double at,
                  double* is) {
  return by_look(m, [=] {
    if (!doc_value(*m->d, layer, name, at, is)) return 0;
    if (!doc_driven_by(*m->d, layer, name)) return 1;
    *is = doc_literal(*m->d, layer, doc_lasting(name), at, *is);
    return 2;
  });
}
// Copies up to `room` layer numbers into `layers`, in the order they lie with
// the one furthest back first. Returns the total number of layers, which can
// exceed `room`.
int motolii_layers(Motolii* m, int* layers, int room) {
  return by_look(m, [=] {
    const std::vector<int> all = doc_layers(*m->d);
    for (int i = 0; i < room && i < (int)all.size(); ++i)
      layers[i] = all[(size_t)i];
    return (int)all.size();
  });
}
// Returns the text value of property `name` of the layer, or the layer's name
// when `name` is "name". The string is valid until the same thread calls again.
const char* motolii_word(Motolii* m, int layer, const char* name) {
  return by_look(m, [=] {
    return (said_word() = !strcmp(name, "name") ? doc_name(*m->d, layer)
                                                : doc_word(*m->d, layer, name))
        .c_str();
  });
}
// Returns how long the layer lasts.
double motolii_lasts(Motolii* m, int layer) {
  return by_look(m, [=] { return doc_lasts(*m->d, layer); });
}
// Copies up to `room` keyframe times of property `name` into `at`. Returns the
// total number of keyframes, which can exceed `room`.
int motolii_key_times(Motolii* m, int layer, const char* name, double* at,
                      int room) {
  return by_look(m, [=] {
    const std::vector<double> all = doc_key_times(*m->d, layer, name);
    for (int i = 0; i < room && i < (int)all.size(); ++i)
      at[i] = all[(size_t)i];
    return (int)all.size();
  });
}
// Samples where the layer is and how it is turned over time. Fills `path` with
// `n` entries of four numbers each: x, y, the rotation about z in degrees, and
// the scale. The times run from `from` up to but not including `to`. `copy` is
// the number of the copy to sample, or 0 for the layer itself. Returns `n`, or
// 0 if the layer is unknown.
int motolii_path(Motolii* m, int layer, int copy, double from, double to, int n,
                 double* path) {
  return by_look(m, [=] {
    if (!doc_knows(doc(m), layer) || n < 1) return 0;
    // Use the stage's own placement at times of this call's choosing; the
    // preview's current time is left alone.
    for (int i = 0; i < n; ++i) {
      const double at = from + (to - from) * i / n;
      // Place as a copy, or as the layer itself, the way the stage places it.
      const math::mat4 p =
          doc_place(*m->d, layer, at, 0, copy,
                    copy > 0 || doc_staggered(*m->d, layer, at));
      path[4 * i] = p[3][0], path[4 * i + 1] = p[3][1];
      path[4 * i + 2] = std::atan2(p[0][1], p[0][0]) * 360.0 / (double)TAU,
                   path[4 * i + 3] = length(p[0].xyz);
    }
    return n;
  });
}
// Like motolii_path, but each entry is x, y, z in stage units followed by the
// scale, so that a preview can draw the path seen from any side.
int motolii_path3(Motolii* m, int layer, int copy, double from, double to,
                  int n, double* path) {
  return by_look(m, [=] {
    if (!doc_knows(doc(m), layer) || n < 1) return 0;
    for (int i = 0; i < n; ++i) {
      const double at = from + (to - from) * i / n;
      const math::mat4 p =
          doc_place(*m->d, layer, at, 0, copy,
                    copy > 0 || doc_staggered(*m->d, layer, at));
      path[4 * i] = p[3][0], path[4 * i + 1] = p[3][1],
               path[4 * i + 2] = p[3][2], path[4 * i + 3] = length(p[0].xyz);
    }
    return n;
  });
}
// Turns auto-keying on or off, or reads it. Auto-keying makes every change a
// keyframe. With `on` below 0 the call only returns the current state; it is a
// read answered at once, not queued behind the render thread's frame. Otherwise
// it returns whether auto-keying is now on.
int motolii_keying(Motolii* m, int on) {
  if (on < 0) return (int)m->keying.load();
  // Record the new state at once and let the render thread pick it up on its
  // next turn.
  m->keying = on != 0;
  return posted(m, "keying",
                [m, on] {
                  m->d->keying = on != 0, m->d->keying_from = m->now;
                  m->keying = m->d->keying;
                }),
         on != 0;
}
// Starts a drag on the layer. Returns nonzero on success.
int motolii_drag_start(Motolii* m, int layer) {
  return on_render_thread(m, [=] { return (int)doc_hold(doc(m), layer); });
}
// Queues a drag update. `by` names what is being dragged and `a` and `b` are
// its new values; the meaning depends on `by`, see doc_carry. A refused update
// is reported when the drag ends.
int motolii_drag_update(Motolii* m, const char* by, double a, double b) {
  return posted(m, std::string("carry ") + by, [m, by = std::string(by), a, b] {
    doc_carry(doc(m), by.c_str(), a, b);
  });
}
// Reads the work area into *from and *to. Returns 1.
int motolii_work_of(Motolii* m, double* from, double* to) {
  return by_look(m, [=] { return doc_work(*m->d, from, to), 1; });
}
// Returns the guides, one per line: x or y, a space, and the position.
const char* motolii_guides(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_guides(*m->d)).c_str(); });
}
// Returns the marks, one per line in time order: the time, a space, and the
// name.
const char* motolii_marks(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_marks(*m->d)).c_str(); });
}
// Returns the mark colors as text.
const char* motolii_mark_colours(Motolii* m) {
  return by_look(
      m, [=] { return (said_word() = doc_mark_colours(*m->d)).c_str(); });
}
// Returns the project settings, one per line: the name, a space, and the value.
const char* motolii_settings(Motolii* m) {
  return by_look(m,
                 [=] { return (said_word() = doc_settings(*m->d)).c_str(); });
}
// Returns 1 if the project's size is the preview's size, otherwise 0.
int motolii_fits(Motolii* m) {
  return by_look(m, [=] {
    int wide = m->s->w, high = m->s->h;
    doc_rows(*m->d,
             sqlite3_mprintf("select name, value from keyframe where layer = 0 "
                             "and name in ('wide', 'high')"),
             [&](sqlite3_stmt* row) {
               (strcmp((const char*)sqlite3_column_text(row, 0), "wide")
                    ? high
                    : wide) = sqlite3_column_int(row, 1);
             });
    return (int)(wide == m->s->w && high == m->s->h);
  });
}
// Stores the preview's size in *wide and *high. Returns 1.
int motolii_size_of(Motolii* m, int* wide, int* high) {
  return by_look(m, [=] { return *wide = m->s->w, *high = m->s->h, 1; });
}
// Returns the words that text property `name` of the layer accepts, or "" if
// any text is allowed or the property is not text.
const char* motolii_words(Motolii* m, int layer, const char* name) {
  return by_look(
      m, [=] { return (said_word() = doc_words(*m->d, layer, name)).c_str(); });
}
// Copies into `at`, up to `room` entries, every time at which any keyframed
// property of the layer has a keyframe, each time once and in ascending order.
// Returns the total count. The timeline draws its keyframe marks from this in
// one call instead of asking property by property.
int motolii_layer_key_times(Motolii* m, int layer, double* at, int room) {
  // One SQLite query. A property counts as keyframed by the DOC_KEYED rule: it
  // has more than one keyframe, a keyframe not at time 0, or an easing.
  return by_look(m, [=] {
    int i = 0;
    doc_rows(
        *m->d,
        sqlite3_mprintf("select distinct at from keyframe where layer = %d and "
                        "name in (select name from keyframe where layer = %d "
                        "group by name having count(*) > 1 or max(at) <> 0 or "
                        "max(easing) is not null) order by at",
                        layer, layer),
        [&](sqlite3_stmt* row) {
          if (i < room) at[i] = sqlite3_column_double(row, 0);
          ++i;
        });
    return i;
  });
}
// Returns the names of the layer's properties that can have keyframes,
// separated by spaces.
const char* motolii_moving(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_moving(*m->d, layer)).c_str(); });
}
// Returns the names of all properties of the layer, separated by spaces.
const char* motolii_values(Motolii* m, int layer) {
  return by_look(m,
                 [=] { return (said_word() = doc_has(*m->d, layer)).c_str(); });
}
// Stores the display range of numeric property `name` in *low and *high.
// Returns nonzero on success.
int motolii_range(Motolii* m, int layer, const char* name, double* low,
                  double* high) {
  return by_look(m,
                 [=] { return (int)doc_range(*m->d, layer, name, low, high); });
}
// Returns one line per create script: name, a tab, and its description.
const char* motolii_create_scripts(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_recipe_names()).c_str(); });
}
// Returns the names of the effect files followed by the names of the AviUtl2
// scripts, one per line.
const char* motolii_effects(Motolii* m) {
  return by_look(m, [=] {
    // The file types are .wgsl, .fs, .mjs, .js, .json and .am. A .json file
    // holds Filament's own settings, see viewer_settings.h. A .am file is an
    // AbsentMotion motion, see absent_motion.h.
    const std::string files = doc_folder_names("effects",
                                               ".wgsl .fs .mjs .js .json .am"),
                      aviutl = doc_aviutl_names();
    return (said_word() =
                files + (files.empty() || aviutl.empty() ? "" : "\n") + aviutl)
        .c_str();
  });
}
// Records that files on the shelves changed on disk.
void motolii_files_changed(void) { ++files_changed(); }
// Returns the names of the presets on the shelf.
const char* motolii_presets(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_preset_names()).c_str(); });
}
// Returns the names of the expression files, separated by spaces.
const char* motolii_animators(Motolii* m) {
  return by_look(m, [=] {
    return (said_word() = doc_folder_names("expressions", ".js")).c_str();
  });
}
// Returns the names of the relation files, separated by spaces.
const char* motolii_relations(Motolii* m) {
  return by_look(m, [=] {
    return (said_word() = doc_folder_names("relations", ".js")).c_str();
  });
}
// Runs the create script `script`, which makes layers and values in one go.
// Returns nonzero on success.
int motolii_create(Motolii* m, const char* script) {
  return on_render_thread(m,
                          [=] { return changes(m, doc_make(doc(m), script)); });
}
// Returns the display settings of property `name` as tab-separated fields:
// look, unit, label, low, high, the group it folds into, and 1 if that group
// starts open. The line is empty if the property has none.
const char* motolii_shown(Motolii* m, const char* name) {
  return by_look(m, [=] {
    const DocShown* s = doc_shown_of(*m->d, name);
    char line[512] = "";
    if (s)
      std::snprintf(line, sizeof line, "%s\t%s\t%s\t%g\t%g\t%s\t%d", s->look,
                    s->unit, s->label, s->low, s->high, s->fold ? s->fold : "",
                    (int)s->open);
    return (said_word() = line).c_str();
  });
}
// Returns the effect cards of the layer as text.
const char* motolii_cards(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_cards_of(*m->d, layer)).c_str(); });
}
// Returns the cards that exist but stay hidden until the user asks for them, in
// the same format.
const char* motolii_cards_more(Motolii* m, int layer) {
  return by_look(m, [=] {
    std::string more;
    doc_cards_of(*m->d, layer, &more);
    return (said_word() = more).c_str();
  });
}
// Returns the titles of the layer's effect cards in effect order, separated by
// semicolons.
const char* motolii_fx_titles(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_fx_titles(*m->d, layer)).c_str(); });
}
// Returns the layer kind that a file makes, decided by the end of its name, or
// "" for none.
const char* motolii_kind_of(const char* file) { return doc_kind_of(file); }
// Returns 1 if ThorVG can set `words` in the font file, otherwise 0.
int motolii_sets(const char* font, const char* words) {
  return type_sets(font, words) ? 1 : 0;
}
// Returns "" if the font file has every letter of `words`. Otherwise returns
// the letters it lacks, a tab, and the fallback font that has them all, which
// can be empty.
const char* motolii_font_lacks(const char* font, const char* words) {
  thread_local std::string said;
  if (!font || !words) return "";
  const std::string lacks = type_lacks(font, words);
  said =
      lacks.empty() ? std::string() : lacks + "\t" + type_fallback(font, words);
  return said.c_str();
}
// Returns the numbers that easing kind `kind` takes, as the app presents them:
// for each one its name, its lowest and its highest value, such as "seed 1 999
// grain 0 0.5". Returns "" for a kind with none. The kinds are built into the
// engine, so this does not wait for the render thread.
const char* motolii_easing_numbers(Motolii*, const char* kind) {
  static thread_local std::string said;
  said.clear();
  for (const auto& k : interp_kinds) {
    if (strcasecmp(k.name, kind)) continue;
    std::istringstream names(k.names);
    std::string name;
    char one[96];
    for (int j = 0; j < k.numbers && names >> name; ++j)
      std::snprintf(one, sizeof one, "%s%s %.9g %.9g", said.empty() ? "" : " ",
                    name.c_str(), k.lo[j], k.hi[j]),
          said += one;
  }
  return said.c_str();
}
// Returns the names of the easings that can be put on a keyframe, separated by
// spaces: the nine built-in kinds, then the easings defined in the project,
// then the user's own easings that the project does not have yet.
const char* motolii_easing_names(Motolii* m) {
  return by_look(m, [=] {
    said_word().clear();
    for (const auto& kind : interp_kinds)
      said_word() += std::string(said_word().empty() ? "" : " ") + kind.name;
    std::set<std::string> here;
    doc_rows(*m->d, sqlite3_mprintf("select name from easing order by name"),
             [&](sqlite3_stmt* row) {
               here.insert((const char*)sqlite3_column_text(row, 0));
               said_word() +=
                   std::string(" ") + (const char*)sqlite3_column_text(row, 0);
             });
    // Then the user's own easings that this project does not have yet.
    for (const auto& [name, expression] : doc_own_easings())
      if (!here.count(name)) said_word() += " " + name;
    return said_word().c_str();
  });
}
// Returns how far along easing `easing` is at progress `u`, from 0 at its
// beginning to 1 at its end. `easing` is a built-in kind or an easing defined
// in the project or in a file of the user.
double motolii_easing_at(Motolii* m, const char* easing, double u) {
  Interp kind;
  if (interp_said(easing, &kind) == 0) return interp_ease(kind, u);
  return by_look(m, [=] {
    bool here = false;
    doc_rows(*m->d,
             sqlite3_mprintf("select 1 from easing where name = %Q", easing),
             [&](sqlite3_stmt*) { here = true; });
    const auto easings = doc_own_easings();
    const auto own = easings.find(easing);
    // The user's own easing, not yet in this project: evaluate it as its file
    // says. The parameters are all 1.
    if (!here && own != easings.end()) {
      const double p[4] = {1, 1, 1, 1};
      sqlite3_stmt* expression = doc_expression_statement(*m->d, own->second);
      return expression ? doc_went(expression, u, u, 1.0, 0.0, 1.0, p) : u;
    }
    // An easing defined in the project, evaluated as between a keyframe of 0
    // and a keyframe of 1 that are one second apart.
    return doc_went_by(*m->d, easing, u, u, 1.0, 0.0, 1.0);
  });
}
// Begins or ends a group of changes that form one undo step. A nonzero `on`
// begins it. 0 ends it and returns whether the group succeeded. Previews that
// were held back while the group was open are made once when it ends.
int motolii_together(Motolii* m, int on) {
  return on_render_thread(m, [=] {
    if (on) return doc_act(*m->d), m->d->act_together = true, 1;
    const int done = m->d->act ? (int)doc_acted(*m->d) : 0;
    if (!m->d->act) m->d->act_together = false;
    // Make the previews that were held back while the group was open.
    snapshot_update(m), snapshot_time(m);
    return done;
  });
}
// Returns every segment between two keyframes of the layer's keyframed
// properties, one per line as "from\tto\teasing\n". The timeline draws how the
// value goes between the two keyframes from this. The engine decides what the
// segments are; the app only draws them.
const char* motolii_layer_stretches(Motolii* m, int layer) {
  return by_look(m, [=] {
    std::string all;
    doc_rows(*m->d,
             sqlite3_mprintf(
                 "select at, next, easing from (select at, lead(at) over "
                 "(partition by name order by at) as next, coalesce(easing, "
                 "'Linear') as easing from keyframe where layer = %d and name "
                 "in (select name from keyframe where layer = %d group by name "
                 "having count(*) > 1 or max(at) <> 0 or max(easing) is not "
                 "null)) where next is not null order by at",
                 layer, layer),
             [&](sqlite3_stmt* row) {
               std::string easing = (const char*)sqlite3_column_text(row, 2);
               Interp kind;
               if (interp_said(easing, &kind) == 0) easing = interp_words(kind);
               char line[64];
               std::snprintf(line, sizeof line, "%.17g\t%.17g\t",
                             sqlite3_column_double(row, 0),
                             sqlite3_column_double(row, 1));
               all += line + easing + "\n";
             });
    return (said_word() = all).c_str();
  });
}
// Returns the easing of the keyframe of property `name` at time `at`.
const char* motolii_easing_of(Motolii* m, int layer, const char* name,
                              double at) {
  return by_look(m, [=] {
    return (said_word() = doc_easing_of(*m->d, layer, name, at)).c_str();
  });
}

namespace motolii {

namespace {

// Returns how many points of the image one stage unit is, for layers whose z is
// 0. The camera of the stage looks from 6 units away with a vertical field of
// view of 30 degrees; see motolii_open. That fixes the scale at the middle of
// the preview whatever camera the stage looks through now. The result is the
// image height divided by the visible height.
double point_of(Motolii* m) {
  return m->s->h / (2.0 * 6.0 * std::tan(15.0 * TAU / 360.0));
}

}  // namespace

}  // namespace motolii

// Returns how many points of the image one stage unit is, for layers whose z is
// 0.
double motolii_point(Motolii* m) {
  return by_look(m, [=] { return point_of(m); });
}
// Returns how the app reads a property of the layer, as "times from": the app
// shows the value times `times` plus `from`. Places are counted in points of
// the image from its top left corner, as After Effects counts them. Scale and
// opacity are in hundredths. The turn about z is clockwise; a camera's turns
// are as they are, and its pitch looks down. The anchor is in hundredths of the
// box from its top left, front -50 to back 50. A camera's distance is in points
// of the image, the stage's own camera being 6 units away. Any other property
// follows its look: stage is points, down is points down the image, and share
// is hundredths. Otherwise the value is shown as it is.
const char* motolii_reading(Motolii* m, int layer, const char* name) {
  return by_look(m, [=] {
    const double p = point_of(m), w = m->s->w, h = m->s->h;
    const bool camera = doc_word(*m->d, layer, "kind") == "camera";
    const std::string n = name;
    double times = 1, from = 0;
    if (n == "x")
      times = p, from = w / 2;
    else if (n == "y")
      times = -p, from = h / 2;
    else if (n == "z")
      times = p;
    else if (n == "scale_x" || n == "scale_y" || n == "scale_z" ||
             n == "opacity" || n == "zoom")
      times = 100;
    else if (n == "rotate")
      times = camera ? 1 : -1;
    else if (n == "rotate_x")
      times = camera ? -1 : 1;
    else if (n == "anchor_x")
      times = 50, from = 50;
    else if (n == "anchor_y")
      times = -50, from = 50;
    else if (n == "anchor_z")
      times = -50;
    else if (n == "distance")
      times = 6 * p;
    else if (n == "size")
      times = p;
    else if (const DocShown* s = doc_shown_of(*m->d, name)) {
      const std::string look = s->look;
      times = look == "stage"   ? p
              : look == "down"  ? -p
              : look == "share" ? 100
                                : 1;
    }
    char line[64];
    std::snprintf(line, sizeof line, "%.17g %.17g", times, from);
    return (said_word() = line).c_str();
  });
}

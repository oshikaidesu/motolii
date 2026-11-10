#include "entry/calls.h"


#include <regex>

#include "document/cards.h"
#include "document/edit/arrange.h"
#include "document/edit/fx_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/relate.h"
#include "document/evaluate/shown.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "entry/on_render_thread.h"
#include "media/midi_notes.h"

using filament::math::mat4;
namespace math = filament::math;

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

// Adds effect `name` to the layer at time `at`. Returns nonzero on success.
int motolii_effect(Motolii* m, int layer, const char* name, double at) {
  return on_render_thread(m, [=] {
    return changes(m, (int)(doc_effect(doc(m), layer, name, at)));
  });
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
  if (on < 0) return (int)m->window.keying.load();
  // Record the new state at once and let the render thread pick it up on its
  // next turn.
  m->window.keying = on != 0;
  return posted(m, "keying",
                [m, on] {
                  m->d->keying.on = on != 0,
                  m->d->keying.from = m->playback.now;
                  m->window.keying = m->d->keying.on;
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
// Begins or ends a group of changes that form one undo step. A nonzero `on`
// begins it. 0 ends it and returns whether the group succeeded. Previews that
// were held back while the group was open are made once when it ends.
int motolii_together(Motolii* m, int on) {
  return on_render_thread(m, [=] {
    if (on) return doc_act(*m->d), m->d->act.together = true, 1;
    const int done = m->d->act.depth ? (int)doc_acted(*m->d) : 0;
    if (!m->d->act.depth) m->d->act.together = false;
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

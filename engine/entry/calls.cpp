#include "entry/calls.h"

#include <regex>
#include <thorvg.h>

#include <algorithm>
#include <cstdio>
#include <string>

#include "document/cards.h"
#include "document/edit/arrange.h"
#include "document/edit/fx_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/relate.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "entry/on_render_thread.h"
#include "media/midi_notes.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"

using filament::math::mat4;
namespace math = filament::math;

using namespace motolii;

int motolii_add(Motolii* m, const char* kind, const char* file) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_add(doc(m), kind, file))); });
}
int motolii_remove(Motolii* m, int layer) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_remove(doc(m), layer))); });
}
// The number goes through doc_macro_own to invert any expression driving it.
int motolii_set(Motolii* m, int layer, const char* name, double number) {
  return on_render_thread(m, [=] {
    return changes(
        m, (int)(doc_set(
               doc(m), layer, name,
               doc_macro_own(doc(m), layer, name,
                             doc(m).stage ? doc(m).stage->now : 0.0, number))));
  });
}
int motolii_say(Motolii* m, int layer, const char* name, const char* word) {
  return on_render_thread(
      m, [=] { return changes(m, (int)(doc_say(doc(m), layer, name, word))); });
}
// Sets the keyframe, number converted as in motolii_set.
int motolii_key(Motolii* m, int layer, const char* name, double at,
                double number) {
  return on_render_thread(m, [=] {
    return changes(
        m, (int)(doc_key(doc(m), layer, name, at,
                         doc_macro_own(doc(m), layer, name, at, number))));
  });
}
// Turns the notes of a MIDI file into keyframes (midi_notes.h, midi_keys).
// Every keyframe uses Hold easing.
int motolii_midi(Motolii* m, int layer, const char* name, const char* file,
                 const char* kind, int channel, double bpm) {
  std::vector<MidiEvent> events = midi_events(file);
  // Rescale times from the file's own tempo to `bpm`.
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
  // Replace existing keyframes with the file's notes, as one undo step.
  return on_render_thread(m, [=] {
    Doc& d = doc(m);
    doc_act(d);
    const bool ok = doc_stay(d, layer, name, 0.0) &&
                    doc_key_many(d, layer, name, (int)at.size(), at.data(),
                                 is.data(), "Hold");
    return changes(m, (int)(doc_acted(d) && ok));
  });
}

int motolii_effect(Motolii* m, int layer, const char* name, double at) {
  return on_render_thread(m, [=] {
    return changes(m, (int)(doc_effect(doc(m), layer, name, at)));
  });
}
// Evaluates arithmetic text with SQLite. Only allows [0-9.+-*/()eE ].
int motolii_work_out(Motolii* m, const char* sum, double* is) {
  const std::string said(sum);
  if (said.find_first_not_of("0123456789.+-*/()eE ") != std::string::npos)
    return 0;
  static const std::regex whole("(^|[^0-9.eE])([0-9]+)(?![0-9.eE])");
  // SQLite integer division: 1/3 = 0. Make every literal a real.
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
// Returns 0 (no such property), 1 (own value), or 2 (driven; *is is the own
// value, not the driven one).
int motolii_shows(Motolii* m, int layer, const char* name, double at,
                  double* is) {
  return by_look(m, [=] {
    if (!doc_value(*m->d, layer, name, at, is)) return 0;
    if (!doc_driven_by(*m->d, layer, name)) return 1;
    *is = doc_literal(*m->d, layer, doc_lasting(name), at, *is);
    return 2;
  });
}
// Layers in stacking order (furthest back first). Returns total count.
int motolii_layers(Motolii* m, int* layers, int room) {
  return by_look(m, [=] {
    const std::vector<int> all = doc_layers(*m->d);
    for (int i = 0; i < room && i < (int)all.size(); ++i)
      layers[i] = all[(size_t)i];
    return (int)all.size();
  });
}
// String valid until the same thread calls again.
const char* motolii_word(Motolii* m, int layer, const char* name) {
  return by_look(m, [=] {
    return (said_word() = !strcmp(name, "name") ? doc_name(*m->d, layer)
                                                : doc_word(*m->d, layer, name))
        .c_str();
  });
}
double motolii_lasts(Motolii* m, int layer) {
  return by_look(m, [=] { return doc_lasts(*m->d, layer); });
}
// Returns total keyframe count (may exceed `room`).
int motolii_key_times(Motolii* m, int layer, const char* name, double* at,
                      int room) {
  return by_look(m, [=] {
    const std::vector<double> all = doc_key_times(*m->d, layer, name);
    for (int i = 0; i < room && i < (int)all.size(); ++i)
      at[i] = all[(size_t)i];
    return (int)all.size();
  });
}
// Fills `path` with n×(x, y, rotate_z, scale) samples from `from` to `to`.
int motolii_path(Motolii* m, int layer, int copy, double from, double to, int n,
                 double* path) {
  return by_look(m, [=] {
    if (!doc_knows(doc(m), layer) || n < 1) return 0;
    for (int i = 0; i < n; ++i) {
      const double at = from + (to - from) * i / n;
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
// Like motolii_path but entries are (x, y, z, scale) in stage units.
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
// on < 0: read only (not queued). Otherwise sets and returns the new state.
int motolii_keying(Motolii* m, int on) {
  if (on < 0) return (int)m->window.keying.load();
  m->window.keying = on != 0;
  return posted(m, "keying",
                [m, on] {
                  m->d->keying.on = on != 0,
                  m->d->keying.from = m->playback.now;
                  m->window.keying = m->d->keying.on;
                }),
         on != 0;
}
int motolii_drag_start(Motolii* m, int layer) {
  return on_render_thread(m, [=] { return (int)doc_hold(doc(m), layer); });
}
// Queued; see doc_carry for `by` semantics.
int motolii_drag_update(Motolii* m, const char* by, double a, double b) {
  return posted(m, std::string("carry ") + by, [m, by = std::string(by), a, b] {
    Doc& d = doc(m);
    if (doc_carry(d, by.c_str(), a, b))
      d.changes.changed.insert({d.held.layer, ""}), snapshot_update(m);
  });
}
int motolii_work_of(Motolii* m, double* from, double* to) {
  return by_look(m, [=] { return doc_work(*m->d, from, to), 1; });
}
// Format: "x|y position\n" per line.
const char* motolii_guides(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_guides(*m->d)).c_str(); });
}
// Format: "time name\n" per line in time order.
const char* motolii_marks(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_marks(*m->d)).c_str(); });
}
const char* motolii_mark_colours(Motolii* m) {
  return by_look(
      m, [=] { return (said_word() = doc_mark_colours(*m->d)).c_str(); });
}
// Format: "name value\n" per line.
const char* motolii_settings(Motolii* m) {
  return by_look(m,
                 [=] { return (said_word() = doc_settings(*m->d)).c_str(); });
}
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
int motolii_size_of(Motolii* m, int* wide, int* high) {
  return by_look(m, [=] { return *wide = m->s->w, *high = m->s->h, 1; });
}
const char* motolii_words(Motolii* m, int layer, const char* name) {
  return by_look(
      m, [=] { return (said_word() = doc_words(*m->d, layer, name)).c_str(); });
}
// All distinct keyframe times of the layer's keyframed properties, ascending.
// One query instead of property-by-property.
int motolii_layer_key_times(Motolii* m, int layer, double* at, int room) {
  // DOC_KEYED rule: >1 keyframe, a keyframe not at t=0, or an easing.
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
const char* motolii_moving(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_moving(*m->d, layer)).c_str(); });
}
const char* motolii_values(Motolii* m, int layer) {
  return by_look(m,
                 [=] { return (said_word() = doc_has(*m->d, layer)).c_str(); });
}
int motolii_range(Motolii* m, int layer, const char* name, double* low,
                  double* high) {
  return by_look(m,
                 [=] { return (int)doc_range(*m->d, layer, name, low, high); });
}
// Groups changes into one undo step. Previews held back during the group are
// made once when it ends.
int motolii_together(Motolii* m, int on) {
  return on_render_thread(m, [=] {
    if (on) return doc_act(*m->d), m->d->act.together = true, 1;
    const int done = m->d->act.depth ? (int)doc_acted(*m->d) : 0;
    if (!m->d->act.depth) m->d->act.together = false;
    try {
      snapshot_update(m), snapshot_time(m);
    } catch (...) {}
    return done;
  });
}
// Format: "from\tto\teasing\n" per segment. The app draws; the engine decides.
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

// Points per stage unit at z=0. Fixed by the 6-unit distance and 30° FoV of
// the stage camera (motolii_open), regardless of the document's own camera.
double point_of(Motolii* m) {
  return m->s->h / (2.0 * 6.0 * std::tan(15.0 * TAU / 360.0));
}

}  // namespace

}  // namespace motolii

double motolii_point(Motolii* m) {
  return by_look(m, [=] { return point_of(m); });
}
// Returns "times from" for converting a property's engine value to the display
// value the app shows: display = engine × times + from.
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
             n == "opacity")
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
// SVG path of the shape's outline with all operators applied. Coordinates are
// centred at origin, 1 unit high. "" if not a shape.
const char* motolii_shape_svg(Motolii* m, int layer) {
  return by_look(m, [=] {
    Doc& d = *m->d;
    const std::string kind = doc_word(d, layer, "kind");
    // Text: use a square so path operators are visible (letter outlines are noise).
    const bool text = kind == "text";
    const std::string form = text ? std::string("rect") : doc_word(d, layer, "shape");
    if (!text && (kind != "shape" || form.empty() ||
                  form == "path" || form == "null" || form == "solid"))
      return (said_word() = "").c_str();
    const bool line = form == "line", wave = form == "wave";
    const double high = line ? 0.04 : wave ? 0.3 : 1.0,
                 wide = doc_number(d, layer, "wide", 0,
                                   line ? 25 : wave ? 10 : 1);
    const int h = 1024, w = std::max(2, (int)std::lround(1024.0 * wide));
    Canvas2D made;
    tvg::Shape* shape = tvg::Shape::gen();
    flat_path(&made, shape, form.c_str(), w, h, 0.f,
              (int)doc_number(d, layer, "points", 0,
                              form == "star"       ? 5
                              : form == "rect"     ? 4
                              : form == "arc"      ? 270
                              : form == "squircle" ? 4
                              : form == "cog"      ? 12
                              : form == "spiral"   ? 3
                              : wave               ? 4
                                                   : 6),
              (float)doc_number(d, layer, "inner", 0,
                                form == "cog"       ? 0.2
                                : form == "arc"     ? 0.3
                                : form == "spiral"  ? 0.1
                                : form == "chamfer" ? 0.3
                                : form == "rect"    ? 0.0
                                                    : 0.5),
              0.f, 0.f);
    const double at = d.stage->now;
    const auto num = [&](const char* name, double usual) {
      return (float)doc_number(d, layer, name, at, usual);
    };
    tvg_bend(shape, made.plain.data(), (uint32_t)made.plain.size(),
             made.plainAt.data(), (uint32_t)made.plainAt.size(),
             line ? 0.f : std::clamp(num("round", 0), 0.f, 0.5f) * made.plainSide,
             100.f * std::clamp(num("bloat", 0), -1.f, 1.f),
             num("zigzag", 0) * (float)h,
             (int)std::clamp(num("zigzag_ridges", 5), 0.f, 100.f),
             num("zigzag_smooth", 0) > 0.5f, num("offset", 0) * (float)h, 0.f);
    const tvg::PathCommand* cmds;
    const tvg::Point* pts;
    uint32_t cmdsCnt = 0, ptsCnt = 0;
    shape->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
    std::string path;
    char one[96];
    const auto pos = [&](const tvg::Point& p) {
      std::snprintf(one, sizeof one, "%.5f %.5f", (p.x - 0.5 * w) / h,
                    (p.y - 0.5 * h) / h);
      return std::string(one);
    };
    for (uint32_t c = 0, p = 0; c < cmdsCnt; ++c) switch (cmds[c]) {
        case tvg::PathCommand::MoveTo:
          path += (path.empty() ? "M" : " M") + pos(pts[p++]);
          break;
        case tvg::PathCommand::LineTo:
          path += " L" + pos(pts[p++]);
          break;
        case tvg::PathCommand::CubicTo:
          path += " C" + pos(pts[p]) + " " + pos(pts[p + 1]) + " " +
                  pos(pts[p + 2]);
          p += 3;
          break;
        case tvg::PathCommand::Close:
          path += " Z";
          break;
      }
    tvg::Paint::rel(shape);
    return (said_word() = path).c_str();
  });
}

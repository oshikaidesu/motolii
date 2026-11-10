#include "document/evaluate/place.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <math/mat3.h>
#include <math/mat4.h>
#include <math/quat.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>
#include <utils/Entity.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <functional>
#include <mutex>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/quickjs/script.h"
#include "document/document.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/midi_roll.h"
#include "media/sound_level.h"
#include "physics/physics.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

namespace {
// Returns the depth scale of a layer at time `now`. A scale of exactly 0 would
// make the matrix singular, so a layer that is not a solid gets 1e-3 instead.
double doc_scale_z(Doc& d, int layer, double now) {
  const double z = doc_literal(d, layer, "scale_z", now, 1);
  return z == 0 && doc_word(d, layer, "kind") != "solid" ? 1e-3 : z;
}
// Where a script, or the notes of a MIDI file, put one copy of a layer: its
// position, rotation and size. `by` says what produced it: 0 for neither, 1 for
// a MIDI file's note, 2 for a script's each().
struct DocLaid {
  ScriptCopy c;
  int by = 0;
};
// Returns the expressions that place the copies of `layer`. Returns an empty
// list for a sketch, whose mesh has no copies to place (see sketch.h). The
// result is the same for every copy, so while the document is being evaluated
// at one time (d.place_cache.evaluating, and the document cannot change
// meanwhile) it is computed once per layer and cached in d.place_cache.placing,
// like the copy_tall values.
std::vector<DocScript*> doc_placing_scs(Doc& d, int layer) {
  const auto ask = [&] {
    return doc_literal_word(d, layer, "shape") != "sketch"
               ? doc_expressions_on(d, layer)
               : std::vector<DocScript*>{};
  };
  if (!d.place_cache.evaluating) return ask();
  DocPlaceCache::Placing& kept = d.place_cache.placing[layer];
  if (!kept.laid)
    kept.laid = true, kept.scs = ask(),
    kept.from = kept.scs.empty() ? "" : doc_expressions_said(d, layer);
  return kept.scs;
}
// Returns the AbsentEffect motions on `layer` at time `said`, cached per layer
// while the document is being evaluated, like doc_placing_scs.
std::vector<AbsentEffect> doc_placing_absent(Doc& d, int layer, double said) {
  if (!d.place_cache.evaluating) return doc_absent_on(d, layer, said);
  DocPlaceCache::Placing& kept = d.place_cache.placing[layer];
  if (kept.absentAt != said)
    kept.absentAt = said, kept.absent = doc_absent_on(d, layer, said);
  return kept.absent;
}
// Returns the placement of copy `copy` of the `n` copies of `layer` at time
// `said`, as given by the layer's MIDI file or script. It is asked first, so
// that a falloff weighs each copy by the position where the copy lies.
DocLaid doc_laid(Doc& d, int layer, int copy, int n, double said) {
  DocLaid out;
  // If the layer's script is a MIDI file, each copy is one note of the file;
  // see midi_notes.h. Otherwise the script and the layer's expressions place
  // each copy, on top of what the copy's own values say.
  if (const std::string notes = doc_literal_word(d, layer, "script");
      std::filesystem::path(notes).extension() == ".mid") {
    DocPlaceCache::Scripted& kept = d.place_cache.scripted[layer];
    // Recompute only when the time or the number of copies changed. The speed
    // scales the file's beats like the playback speed of a video.
    if (kept.at != said || (int)kept.copies.size() != n) {
      // midi_roll_box returns the size of the piano roll of the same file at
      // the same speed (midi_roll.cpp). The copies' highest row is placed where
      // the roll has its top row, which is the file's highest note.
      const double speed = doc_literal(d, layer, "speed", 0, 1);
      std::string why;
      double w = 0, h = 0;
      midi_roll_box(
          midi_roll_file(
              notes, speed == 1.0 ? 0.0 : midi_bpm(notes.c_str()) * speed, why),
          w, h);
      kept.at = said,
      kept.copies = midi_copies(
          midi_of(notes), n,
          (said - doc_literal(d, layer, "start", 0, 0)) * speed,
          doc_number(d, 0, "high", 0, 1080) / 1080.0 * (double)d.stage->h /
              std::max(1.0, doc_number(d, 0, "high", 0, 1080) *
                                doc_point(d, layer, said)),
          h);
    }
    const ScriptCopy c = copy < n ? kept.copies[(size_t)copy] : ScriptCopy{};
    out.c = c, out.by = 1;
  } else if (const std::vector<DocScript*> scs = doc_placing_scs(d, layer);
             !scs.empty()) {
    DocPlaceCache::Scripted& kept = d.place_cache.scripted[layer];
    // `clock` is the layer's own time. A part after a cut continues from where
    // it was before the cut; see doc_own_clock.
    const double gone = doc_literal(d, layer, "begin", 0, 0),
                 begins = doc_literal(d, layer, "start", 0, 0) - gone,
                 clock = doc_own_time(d, layer, said, said - begins);
    // Recompute all copies at once, so that the parameters are read once.
    if (const std::string from = d.place_cache.evaluating
                                     ? d.place_cache.placing[layer].from
                                     : doc_expressions_said(d, layer);
        kept.at != said || kept.own != clock ||
        kept.made != doc_scripts_made(d) || (int)kept.copies.size() != n ||
        kept.from != from) {
      kept.at = said, kept.own = clock, kept.made = doc_scripts_made(d),
      kept.from = from;
      kept.copies = doc_expressions_lay(d, layer, scs, n, said, clock, gone);
    }
    const ScriptCopy c = copy < n ? kept.copies[(size_t)copy] : ScriptCopy{};
    out.c = c, out.by = 2;
  }
  return out;
}
}  // namespace

math::mat4 doc_place(Doc& d, int layer, double now, int deeper, int copy,
                     bool member) {
  // The time itself, before the copy's delay is subtracted. What places the
  // copies is evaluated at this time.
  const double said = now;
  // Restores the copy context that was set before this call when the function
  // returns.
  struct Placing {
    Doc& d;
    int copy, n;
    bool hasAt;
    math::double3 at;
    ~Placing() {
      d.copy_context.copy = copy, d.copy_context.n = n,
      d.copy_context.has_at = hasAt, d.copy_context.at = at;
    }
  } was{d, d.copy_context.copy, d.copy_context.n, d.copy_context.has_at,
        d.copy_context.at};
  {
    const int many = member ? doc_members(d, layer) : 1;
    d.copy_context.copy = member ? copy : 0, d.copy_context.n = many,
    d.copy_context.has_at = false;
  }
  // A copy is shown with its delay: the layer as it was that much earlier.
  if (member) now -= doc_delay(d, layer, copy);
  const auto turned = [&](const char* name, math::double3 about) {
    return math::mat4::rotation(
        doc_literal(d, layer, name, now, 0) * (double)TAU / 360.0, about);
  };
  float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  const math::double3 anchor{doc_literal(d, layer, "anchor_x", now, 0) * half.x,
                             doc_literal(d, layer, "anchor_y", now, 0) * half.y,
                             doc_literal(d, layer, "anchor_z", now, 0) * deep};
  // A copy is offset in stage units, so that a larger layer does not get larger
  // gaps. The script or the MIDI file places it (doc_laid) relative to the
  // layer's own position. Then it is rotated and scaled as they say, about its
  // anchor.
  const int n = member ? doc_members(d, layer) : 1;
  const DocLaid laid = member ? doc_laid(d, layer, copy, n, said) : DocLaid{};
  math::double3 shift{0.0};
  math::mat4 own;
  if (member) {
    // Apply the scripted offset first, so that a falloff reads the position
    // where the copy lies.
    shift += math::double3{laid.c.x, laid.c.y, laid.c.z};
    // Record the copy's position on the stage as the script places it. A
    // falloff weighs copies by this position. It is recorded only for a
    // connected layer; otherwise has_at stays false.
    if (doc_connects(d, layer)) {
      d.copy_context.at =
          (doc_above(d, layer, now, deeper) *
           math::double4{doc_number(d, layer, "x", now, 0) + shift.x,
                         doc_number(d, layer, "y", now, 0) + shift.y,
                         doc_number(d, layer, "z", now, 0) + shift.z, 1.0})
              .xyz;
      d.copy_context.has_at = true;
    }
  }
  // A MIDI file shown as a piano roll scrolls past. At the layer's start time
  // its beginning is at the layer, and it moves 300 points per second, as in
  // ALMaMPlayer's track.gd.
  if (const std::string file = doc_literal_word(d, layer, "file");
      std::filesystem::path(file).extension() == ".mid") {
    const double speed = doc_literal(d, layer, "speed", 0, 1),
                 point = doc_point(d, layer, said);
    std::string why;
    double w = 0, h = 0;
    if (point > 0 &&
        midi_roll_box(
            midi_roll_file(
                file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why),
            w, h))
      shift.x +=
          (0.5 * w - 300.0 * (said - doc_literal(d, layer, "start", 0, 0))) /
          point;
  }
  // by == 1: a MIDI note, scaled to the size it was given. by == 2: a script's
  // copy, rotated and scaled as its script and expressions say.
  if (laid.by == 1)
    own = own * math::mat4::scaling(laid.c.size);
  else if (laid.by == 2)
    own = own *
          math::mat4::rotation(laid.c.rotate * (double)TAU / 360.0,
                               math::double3{0, 0, 1}) *
          math::mat4::rotation(laid.c.rotate_y * (double)TAU / 360.0,
                               math::double3{0, 1, 0}) *
          math::mat4::rotation(laid.c.rotate_x * (double)TAU / 360.0,
                               math::double3{1, 0, 0}) *
          math::mat4::scaling(math::double3{laid.c.size * laid.c.scale_x,
                                            laid.c.size * laid.c.scale_y,
                                            laid.c.size * laid.c.scale_z});
  // Apply the motion of the layer's AbsentEffect list, in stack order, as
  // absent_motion.h does for Alight Motion.
  if (const std::vector<AbsentEffect> moving =
          doc_placing_absent(d, layer, said);
      !moving.empty()) {
    const double begins = doc_literal(d, layer, "start", 0, 0),
                 lasts = doc_literal(d, layer, "duration", 0, -1);
    const AbsentMoved m =
        absent_motion(moving, layer, 1000.0 * begins,
                      1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))),
                      1000.0 * said);
    // The size of one document pixel in stage units where the layer stands, as
    // for the copies of a script.
    const double pixel =
        (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) *
                                               doc_point(d, layer, said));
    // Alight Motion's y axis points down; the stage's points up.
    shift += math::double3{m.x * pixel, -m.y * pixel, m.z * pixel};
    // Alight Motion rotates clockwise, so the angle is negated.
    own = own *
          math::mat4::rotation(-m.rotate * (double)TAU / 360.0,
                               math::double3{0, 0, 1}) *
          math::mat4::scaling(math::double3{m.scale_x, m.scale_y, 1.0});
    // Offset each copy as the repeat effect lays it out.
    if (const std::vector<AbsentCopy>& copies =
            doc_absent_copies(d, layer, said);
        member && copy < (int)copies.size()) {
      const AbsentCopy& c = copies[(size_t)copy];
      shift += math::double3{c.x * pixel, -c.y * pixel, 0.0};
      own = own *
            math::mat4::rotation(-c.rotate * (double)TAU / 360.0,
                                 math::double3{0, 0, 1}) *
            math::mat4::scaling(c.scale);
    }
  }
  // Vertical scale, with the anchor staying fixed. A copy is also scaled by its
  // entry in copy_tall.
  double tall = doc_literal(d, layer, "tall", now, 1);
  if (member) {
    auto found = d.place_cache.talls.find(layer);
    // Parse copy_tall once per time step and cache it in d.place_cache.talls.
    if (found == d.place_cache.talls.end()) {
      std::istringstream said(doc_literal_word(d, layer, "copy_tall"));
      std::vector<double> all;
      for (std::string one; said >> one && one != "none";)
        all.push_back(std::atof(one.c_str()));
      found = d.place_cache.talls.emplace(layer, std::move(all)).first;
    }
    const std::vector<double>& each = found->second;
    if (!each.empty()) tall *= each[(size_t)copy % each.size()];
  }
  own = own * math::mat4::scaling(math::double3{1.0, tall, 1.0});
  // The letters of a split text rotate and scale about their own middle, not
  // the middle of the whole line.
  if (member)
    if (const double middle = doc_letter_middle(d, layer, copy); middle != 0.0)
      own = math::mat4::translation(math::double3{middle, 0, 0}) * own *
            math::mat4::translation(math::double3{-middle, 0, 0});
  // A layer under physics simulation, or a letter of one: use the position and
  // rotation that the physics world gives, then return.
  if (!d.physics.keyed && !deeper) {
    PhysPose pose;
    if (doc_physics(d, layer, now, &pose, member ? copy : -1)) {
      const math::quat q{pose.turn[3], pose.turn[0], pose.turn[1],
                         pose.turn[2]};
      return math::mat4::translation(
                 math::double3{pose.at[0], pose.at[1], pose.at[2]}) *
             math::mat4(math::mat3(math::quat(q))) *
             math::mat4::scaling(doc_literal(d, layer, "size", now, 1)) *
             math::mat4::scaling(
                 math::double3{doc_literal(d, layer, "scale_x", now, 1),
                               doc_literal(d, layer, "scale_y", now, 1),
                               doc_scale_z(d, layer, now)}) *
             math::mat4::translation(math::double3{
                 -doc_letter_middle(d, layer, member ? copy : -1), 0, 0});
    }
  }
  const math::mat4 heading =
      math::mat4::rotation(doc_heading(d, layer, now), math::double3{0, 0, 1});
  // Copies placed evenly along another shape's outline, each rotated to follow
  // the direction of the outline there, like Cavalry's Duplicator on a shape.
  if (member)
    if (const int on = (int)doc_literal(d, layer, "copy_on", 0, 0);
        on && on != layer && doc_number(d, on, "copy_on", 0, 0) == 0.0) {
      const auto found = d.on_stage.shown.find(on);
      const Canvas2D* b =
          found == d.on_stage.shown.end() ? nullptr : found->second.drawn;
      if (b && b->cut && b->outline) {
        const tvg::PathCommand* cmds;
        const tvg::Point* pts;
        uint32_t cmdsCnt = 0, ptsCnt = 0;
        b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
        const double from = doc_literal(d, layer, "copy_on_offset", said, 0);
        DocPlaceCache::Along& kept = d.place_cache.along[layer];
        const double key =
            (double)ptsCnt +
            (ptsCnt ? pts[0].x * 1e-3 + pts[ptsCnt - 1].y * 1e-6 : 0.0) +
            n * 1e3 + from;
        if (kept.at != said || kept.key != key || kept.of != b)
          kept.at = said, kept.key = key, kept.of = b,
          sk_along(cmds, cmdsCnt, pts, n, (float)from, kept.each);
        if ((size_t)copy * 3 + 2 < kept.each.size()) {
          const float* e = &kept.each[(size_t)copy * 3];
          // The placement of the outline's layer on the stage, as shape_cut
          // computes it.
          const math::mat4 there = doc_place(d, on, now);
          const math::double4 world =
              there *
              math::double4{
                  (e[0] - 0.5 * b->cutW) / b->plainHigh * b->sheetHigh,
                  (0.5 * b->plainHigh - e[1]) / b->plainHigh * b->sheetHigh,
                  0.0, 1.0};
          const math::double3 way =
              there.upperLeft() *
              math::double3{std::cos(e[2]), -std::sin(e[2]), 0.0};
          const math::mat4 frame = doc_above(d, layer, now, deeper) *
                                   math::mat4::translation(math::double3{
                                       doc_literal(d, layer, "x", now, 0),
                                       doc_literal(d, layer, "y", now, 0),
                                       doc_literal(d, layer, "z", now, 0)}) *
                                   heading * turned("rotate", {0, 0, 1}) *
                                   turned("rotate_y", {0, 1, 0}) *
                                   turned("rotate_x", {1, 0, 0});
          const math::mat4 back = inverse(frame);
          // The copy's position in the layer's own rotated frame, without the
          // offsets of rows and scatter.
          shift = (back * world).xyz;
          const math::double3 w = back.upperLeft() * way;
          own = math::mat4::rotation(std::atan2(w.y, w.x),
                                     math::double3{0, 0, 1}) *
                own;
        }
      }
    }
  const math::mat4 above = doc_above(d, layer, now, deeper),
                   there = above * math::mat4::translation(math::double3{
                                       doc_literal(d, layer, "x", now, 0),
                                       doc_literal(d, layer, "y", now, 0),
                                       doc_literal(d, layer, "z", now, 0)});
  // Alight Motion's Parenting Helper, as bevy_alight_motion implements it
  // (MIT/Apache-2.0, src/animation/parenthelper.rs). The parent's rotation and
  // size are applied scaled by their weights, plus the rolling of a wheel.
  math::mat4 helped;
  if (const double wr = doc_literal(d, layer, "parent_rotate", now, 1),
      ws = doc_literal(d, layer, "parent_size", now, 1);
      doc_literal(d, layer, "parent", 0, 0) != 0.0 &&
      (wr != 1.0 || ws != 1.0)) {
    const math::double3 ax = above[0].xyz;
    const double turn = std::atan2(ax.y, ax.x),
                 size = std::max(1e-9, length(ax));
    helped = math::mat4::rotation(turn * (wr - 1.0), math::double3{0, 0, 1}) *
             math::mat4::scaling((1.0 + (size - 1.0) * ws) / size);
  }
  // Wheel roll: the distance travelled along the roll axis turns the layer by
  // distance divided by radius, in radians. Moving right along x turns it
  // clockwise.
  if (const std::string roll = doc_literal_word(d, layer, "roll");
      roll == "x" || roll == "y") {
    float2 half{0.5f};
    float deep = 0.f;
    doc_half(d, layer, &half, &deep);
    const math::double3 at = (there * math::double4{0, 0, 0, 1}).xyz;
    const double r =
        std::min(half.x, half.y) * doc_literal(d, layer, "size", now, 1) +
        doc_literal(d, layer, "roll_radius", now, 0);
    if (std::fabs(r) > 1e-6)
      helped = helped * math::mat4::rotation(-(roll == "x" ? at.x : -at.y) / r,
                                             math::double3{0, 0, 1});
  }
  math::double2 assisted{doc_literal(d, layer, "scale_x", now, 1),
                         doc_literal(d, layer, "scale_y", now, 1)};
  // Alight Motion's Scale Assist, as bevy_alight_motion implements it
  // (resolve_parenthelper_visual_scale in src/animation/parenthelper.rs). The
  // axis is 1 for y, 2 for x and 3 for both; here it is the word "y", "x" or
  // "both".
  if (const std::string assist = doc_literal_word(d, layer, "scale_assist");
      !assist.empty()) {
    const double k = doc_literal(d, layer, "scale_assist_amount", now, 1),
                 damp = std::max(
                     1.0, doc_literal(d, layer, "scale_assist_damp", now, 1));
    if (assist == "y")
      assisted.y *= k;
    else if (assist == "x")
      assisted.x *= k;
    else if (assist == "both")
      assisted.x *= k,
          assisted.y /=
          std::max(1e-9,
                   std::pow(k, 1.71) *
                       std::pow(damp, 1.0 + 2.75 * std::pow(damp - 1.0, 1.93)));
  }
  math::mat4 place =
      there * helped * heading * turned("rotate", {0, 0, 1}) *
      turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0}) *
      math::mat4::translation(shift) *
      math::mat4::scaling(doc_literal(d, layer, "size", now, 1)) *
      math::mat4::scaling(
          math::double3{assisted.x, assisted.y, doc_scale_z(d, layer, now)}) *
      own * math::mat4::translation(-anchor);
  const double reach =
      member ? doc_literal(d, layer, "field_radius", said, 0) : 0.0;
  // Within the field's radius, the layer is scaled and rotated about the point
  // where it is seen, the middle of its image, in proportion to how close it is
  // to the middle of the field.
  if (reach > 0.0) {
    const math::double3 at = (place * math::double4{0.0, 0.0, 0.0, 1.0}).xyz;
    // The field is a sphere, so distance is measured in z as well.
    const math::double3 middle{doc_literal(d, layer, "field_x", said, 0),
                               doc_literal(d, layer, "field_y", said, 0),
                               doc_literal(d, layer, "field_z", said, 0)};
    const double from = length(at - middle),
                 band = doc_literal(d, layer, "field_band", said, 0);
    const double near = std::clamp(band > 0.0
                                       ? 1.0 - std::fabs(from - reach) / band
                                       : 1.0 - from / reach,
                                   0.0, 1.0),
                 k = near * near * (3.0 - 2.0 * near);
    const math::double3 away = at - middle;
    // Push the layer outward as if from a round hole of radius `by`: the
    // nearest copies all end up about the same distance out, so the hole is
    // round however the copies were laid.
    const double r = length(away),
                 by = doc_literal(d, layer, "field_push", said, 0);
    const math::double3 push =
        r > 1e-9
            ? normalize(away) *
                  (by > 0.0 ? k * (std::sqrt(r * r + by * by) - r) : k * by)
            : math::double3{0.0};
    place = math::mat4::translation(push) * math::mat4::translation(at) *
            math::mat4::rotation(
                k * doc_literal(d, layer, "field_rotate", said, 0) *
                    (double)TAU / 360.0,
                math::double3{0, 0, 1}) *
            math::mat4::scaling(std::max(
                0.0, 1.0 + k * doc_literal(d, layer, "field_size", said, 0))) *
            math::mat4::translation(-at) * place;
  }
  // Space set by the user: 2D sticks to the camera; 2.5D stays in the world and
  // is smaller when far, but keeps the angle it was given on the screen; 3D,
  // and a solid, is filmed as it is.
  const auto shown = d.on_stage.shown.find(layer);
  if (deeper || shown == d.on_stage.shown.end() || shown->second.space == 3)
    return place;
  if (shown->second.space == 2) return d.camera.rig * place;
  const math::double3 at = (place * math::double4{anchor, 1.0}).xyz;
  return math::mat4::translation(at) * d.camera.facing *
         math::mat4::translation(-at) * place;
}

std::vector<math::mat4> doc_joins(Doc& d, int layer, double now) {
  const int one = (int)doc_number(d, layer, "connect", 0, 0),
            two = (int)doc_number(d, layer, "connect_to", 0, 0);
  if (!one || one == layer || !d.on_stage.shown.count(one) ||
      (two && (two == layer || !d.on_stage.shown.count(two))))
    return {};
  // Returns the position of the middle of each copy of `other`, before the
  // space is applied.
  const auto where = [&](int other) {
    std::vector<math::double3> at((size_t)doc_members(d, other));
    for (size_t i = 0; i < at.size(); ++i)
      at[i] = (doc_place(d, other, now, 1, (int)i, true) *
               math::double4{0.0, 0.0, 0.0, 1.0})
                  .xyz;
    return at;
  };
  const std::vector<math::double3> a = where(one), b = two ? where(two) : a;
  const double reach = doc_number(d, layer, "connect_reach", now, 0);
  std::vector<std::pair<size_t, size_t>> pairs;
  const size_t most = (size_t)doc_members(d, layer);
  if (two)
    for (size_t i = 0; i < std::min(a.size(), b.size()); ++i)
      pairs.push_back({i, i});
  else if (reach <= 0.0)
    for (size_t i = 0; i + 1 < a.size(); ++i) pairs.push_back({i, i + 1});
  else
    for (size_t i = 0; i < a.size() && pairs.size() < most; ++i)
      for (size_t j = i + 1; j < a.size() && pairs.size() < most; ++j)
        if (length(a[i] - a[j]) < reach) pairs.push_back({i, j});
  float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  const auto shown = d.on_stage.shown.find(layer);
  const int space = shown == d.on_stage.shown.end() ? 3 : shown->second.space;
  std::vector<math::mat4> lines;
  for (size_t k = 0; k < pairs.size() && k < most; ++k) {
    const math::double3 from = a[pairs[k].first], to = b[pairs[k].second],
                        mid = (from + to) * 0.5, way = to - from;
    // The width factor never drops below about a third, because thinner lines
    // break up on the screen.
    const double far = length(way),
                 fine = reach > 0.0 && !two ? 0.35 + 0.65 * (1.0 - far / reach)
                                            : 1.0;
    // The line's axes: along the direction between the two copies, however deep
    // it goes; across it, as level as possible and facing the viewer.
    const math::double3 along = far > 1e-9 ? way / far : math::double3{1, 0, 0},
                        flat = cross(along, math::double3{0, 0, 1});
    const math::double3 across = length(flat) > 1e-6 ? normalize(flat)
                                                     : math::double3{0, 1, 0},
                        up = cross(along, across);
    const double wide = doc_number(d, layer, "size", now, 1) * fine;
    math::mat4 line;
    line[0] = math::double4{along * (far / std::max(1e-6, 2.0 * half.x)), 0.0};
    line[1] = math::double4{-across * wide, 0.0};
    line[2] = math::double4{up, 0.0};
    line[3] = math::double4{mid, 1.0};
    lines.push_back(space == 2 ? d.camera.rig * line : line);
  }
  return lines;
}

void doc_unshape(Stage& s,
                 const std::function<bool(const Stage::Renderable&)>& which) {
  auto& faces = s.engine->getRenderableManager();
  for (size_t i = s.renderables.size(); i-- > 0;) {
    if (!s.renderables[i].matte || !which(s.renderables[i])) continue;
    const utils::Entity e = s.renderables[i].thing;
    MaterialInstance* look =
        faces.getMaterialInstanceAt(faces.getInstance(e), 0);
    for (Stage::Matte& mt : s.mattes) mt.scene->remove(e);
    s.engine->destroy(e);
    s.engine->destroy(look);
    s.renderables.erase(s.renderables.begin() + (long)i);
  }
}

std::vector<float> doc_sound_now(Doc& d, int layer, const std::string& file,
                                 const std::string& name, bool fft, int wide) {
  // Called while a frame is being drawn.
  std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
  const double now = d.stage->now;
  // The special name "aviutl.audiobuffer" selects the mix of all video layers
  // heard now, like AviUtl2's "audiobuffer", which is the mix of every item.
  // Each layer is read at its own time, as below. Waveforms are added; spectrum
  // bands take the maximum.
  if (name == "aviutl.audiobuffer") {
    std::vector<float> all;
    for (const int t : doc_laid(d)) {
      if (doc_word(d, t, "kind") != "video" ||
          doc_number(d, t, "volume", now, 1) <= 0)
        continue;
      const double start = doc_number(d, t, "start", 0, 0),
                   lasts = doc_number(d, t, "duration", 0, -1);
      if (now < start || (lasts > 0 && now >= start + lasts)) continue;
      const std::string heard = doc_word(d, t, "file");
      const SoundRead* read = heard.empty() ? nullptr : sound_of(heard);
      if (!read) continue;
      const std::vector<float> one =
          sound_at(read, fft, wide,
                   doc_number(d, t, "begin", 0, 0) +
                       (now - start) * doc_number(d, t, "speed", 0, 1));
      if (all.empty())
        all = one;
      else
        for (size_t i = 0; i < all.size() && i < one.size(); ++i)
          all[i] = fft ? std::max(all[i], one[i])
                       : std::clamp(all[i] + one[i] - 0.5f, 0.f, 1.f);
    }
    return all;
  }
  const int t = (int)doc_number(
      d, layer, doc_screen_parameter(file, name).c_str(), now, 0);
  if (t <= 0 || !doc_knows(d, t, nullptr, nullptr, nullptr, false)) return {};
  const std::string heard = doc_word(d, t, "file");
  if (heard.empty()) return {};
  const SoundRead* read = sound_of(heard);
  if (!read) return {};
  const double start = doc_number(d, t, "start", 0, 0),
               begin = doc_number(d, t, "begin", 0, 0),
               speed = doc_number(d, t, "speed", 0, 1);
  return sound_at(read, fft, wide,
                  now < start ? -1.0 : begin + (now - start) * speed);
}

}  // namespace motolii

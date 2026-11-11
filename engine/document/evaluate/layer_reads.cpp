// What a layer reads of itself and its group: literal values and words, the
// text it shows, its shutter, its opacity as a group or an AbsentMotion layer,
// its members, delay and letter middle, and whether its copies are staggered.
#include "document/card_table.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/marks.h"
#include "document/scripts/expressions.h"
#include "shelf/shelf_folders.h"
namespace motolii {

namespace math = filament::math;
using filament::MaterialInstance;
using filament::math::float2;

double doc_literal(Doc& d, int layer, const char* literal, double at,
                   double otherwise) {
  // The layer is being dragged. Use its own value. If it is in a relation, the
  // relation still applies, because the drag moves the layer's own value.
  if (d.held.layer == layer) {
    const double own = doc_number(d, layer, literal, at, otherwise);
    const int by = doc_driven_by(d, layer, literal);
    return by && doc_among(doc_relations, doc_word(d, by, "file"))
               ? doc_related(d, by, layer, literal, at, own)
               : own;
  }
  // Driven by a behaviour or relation. For a behaviour, use the value for the
  // copy being placed, weighed by its falloff where the copy lies.
  if (const int by = doc_driven_by(d, layer, literal)) {
    const DocKeys& k = doc_keys_of(d, layer, literal);
    const double own =
        doc_keys_at(d, k, doc_stepped(d, layer, k, at), otherwise);
    // A relation applies by the layer's place among its layers, not by a copy's
    // place.
    if (doc_among(doc_relations, doc_word(d, by, "file")))
      return doc_related(d, by, layer, literal, at, own);
    return doc_given(d, by, d.copy_context.copy, d.copy_context.n, at, own,
                     d.copy_context.has_at ? &d.copy_context.at : nullptr);
  }
  const auto key = std::make_pair(layer, literal);
  auto kept = d.value_cache.literals.find(key);
  if (kept == d.value_cache.literals.end())
    kept = d.value_cache.literals.emplace(key, &doc_keys_of(d, layer, literal))
               .first;
  return doc_keys_at(d, *kept->second, doc_stepped(d, layer, *kept->second, at),
                     otherwise);
}

const std::string& doc_literal_word(Doc& d, int layer, const char* literal) {
  const auto key = std::make_pair(layer, literal);
  if (const auto kept = d.value_cache.heardWords.find(key);
      kept != d.value_cache.heardWords.end())
    return kept->second;
  return d.value_cache.heardWords.emplace(key, doc_word(d, layer, literal))
      .first->second;
}

const std::vector<AbsentCopy>& doc_absent_copies(Doc& d, int layer,
                                                 double now) {
  DocRelations::AbsentKept& k = d.relations.absentKept[layer];
  const long changes = d.file ? (long)sqlite3_total_changes(d.file) : 0;
  if (k.at == now && k.changes == changes && k.seen == files_changed())
    return k.copies;
  k.at = now, k.changes = changes, k.seen = files_changed();
  k.copies.clear();
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos)
    return k.copies;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  // `k2` converts points of the preview to pixels of the document.
  const double high = doc_number(d, 0, "high", 0, 1080),
               k2 = high / std::max(1, d.stage->h);
  const math::double2 at =
      doc_seen(d, (doc_above(d, layer, now, 0) *
                   math::double4{doc_literal(d, layer, "x", now, 0),
                                 doc_literal(d, layer, "y", now, 0),
                                 doc_literal(d, layer, "z", now, 0), 1.0})
                      .xyz) *
      k2;
  float2 half{0.5f};
  doc_half(d, layer, &half);
  // Distance from the layer's position to the farthest point of its box,
  // computed as in CopiesOf: half of the longer side times 1.415, about the
  // square root of 2.
  const double reach = std::max(half.x, half.y) *
                       doc_literal(d, layer, "size", now, 1) *
                       doc_point(d, layer, now) * k2 * 1.415;
  // AbsentMotion measures time in milliseconds.
  k.copies =
      absent_copies(doc_absent_on(d, layer, now), layer, 1000.0 * begins,
                    1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))),
                    1000.0 * now, (float)(d.stage->w * k2), (float)high,
                    (float)at.x, (float)at.y, (float)reach);
  return k.copies;
}

std::string doc_text_shown(Doc& d, int layer, double now, bool* moves) {
  const std::string typed = doc_word(d, layer, "text");
  if (moves) *moves = false;
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return typed;
  const std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
  if (!absent_text_on(on)) return typed;
  if (moves) *moves = true;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_text(on, layer, 1000.0 * begins,
                     1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))),
                     1000.0 * now, 60, typed);
}

bool doc_shutter(Doc& d, int layer, double now, double* open, bool* moves) {
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return false;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_shutter(
      doc_absent_on(d, layer, now), layer, 1000.0 * begins,
      1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now,
      60, open, moves);
}

double doc_group_opacity(Doc& d, int layer, double now) {
  double k = 1.0;
  // Stop after 64 levels so that a cycle of parents terminates.
  for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0;
       up && n < 64 && k > 0.0;
       up = (int)doc_number(d, up, "parent", 0, 0), ++n)
    if (doc_word(d, up, "shape") == "null")
      k *= doc_number(d, up, "visible", 0, 1) > 0.5
               ? std::clamp(doc_number(d, up, "opacity", now, 1), 0.0, 1.0)
               : 0.0;
  return k;
}

double doc_absent_opacity(Doc& d, int layer, double now) {
  if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return 1.0;
  const double begins = doc_literal(d, layer, "start", 0, 0),
               lasts = doc_literal(d, layer, "duration", 0, -1);
  return absent_opacity(
      doc_absent_on(d, layer, now), layer, 1000.0 * begins,
      1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now);
}

int doc_members(Doc& d, int layer) {
  const auto t = d.on_stage.shown.find(layer);
  if (t != d.on_stage.shown.end() && t->second.drawn &&
      !t->second.drawn->letters.empty())
    return (int)t->second.drawn->letters.size();
  if (const std::vector<AbsentCopy>& copies =
          doc_absent_copies(d, layer, d.stage->now);
      !copies.empty())
    return (int)copies.size();
  return std::max(1, (int)doc_literal(d, layer, "copies", 0, 1));
}

double doc_delay(Doc& d, int layer, int nth) {
  const double stagger = doc_literal(d, layer, "stagger", 0, 0);
  const int n = doc_members(d, layer);
  if (stagger <= 0.0 || n < 2) return 0.0;
  const double along = (double)nth / (double)(n - 1),
               centre = std::fabs(along - 0.5) * 2.0;
  const std::string& from = doc_literal_word(d, layer, "stagger_from");
  return stagger * (from == "centre"  ? centre
                    : from == "end"   ? 1.0 - along
                    : from == "edges" ? 1.0 - centre
                                      : along);
}

math::mat4 doc_above(Doc& d, int layer, double now, int deeper) {
  const int parent = (int)doc_literal(d, layer, "parent", 0, 0);
  const auto up = d.on_stage.shown.find(parent),
             self = d.on_stage.shown.find(layer);
  if (up != d.on_stage.shown.end() && up->second.camera &&
      self != d.on_stage.shown.end() && self->second.space == 2)
    return math::mat4{};
  // Stop after 64 levels so that a document with a cycle of parents terminates.
  return parent && up != d.on_stage.shown.end() && deeper < 64
             ? doc_place(d, parent, now, deeper + 1)
             : math::mat4{};
}

double doc_letter_middle(Doc& d, int layer, int copy) {
  const auto sh = d.on_stage.shown.find(layer);
  if (copy < 0 || sh == d.on_stage.shown.end() || !sh->second.drawn ||
      copy >= (int)sh->second.drawn->letters.size())
    return 0.0;
  float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  // A line's middle across is the middle of its own box.
  if (sh->second.drawn->lettersDown) {
    if ((size_t)copy >= sh->second.drawn->boxes.size()) return 0.0;
    const float2 b = sh->second.drawn->boxes[(size_t)copy];
    return ((double)b.x + (double)b.y * 0.5 - 0.5) * 2.0 * half.x;
  }
  const float2 l = sh->second.drawn->letters[(size_t)copy];
  return ((double)(l.x + l.y) * 0.5 - 0.5) * 2.0 * half.x;
}

double doc_line_middle(Doc& d, int layer, int copy) {
  const auto sh = d.on_stage.shown.find(layer);
  if (copy < 0 || sh == d.on_stage.shown.end() || !sh->second.drawn ||
      !sh->second.drawn->lettersDown ||
      copy >= (int)sh->second.drawn->letters.size())
    return 0.0;
  float2 half{0.5f};
  doc_half(d, layer, &half);
  // A cut lies halfway between two lines, so a line's own middle is half a
  // line's pitch from the cut above it (below it, for the first line, whose
  // part of the image begins at the image's top). The cuts run down the image
  // from its top; the stage's y runs up.
  const Canvas2D& drawn = *sh->second.drawn;
  const double pitch = drawn.linePitch,
               down = drawn.letters.size() < 2 ? 0.5
                      : copy == 0 ? (double)drawn.letters[0].y - 0.5 * pitch
                                  : (double)drawn.letters[(size_t)copy].x +
                                        0.5 * pitch;
  return (0.5 - down) * 2.0 * half.y;
}

bool doc_staggered(Doc& d, int layer, double now) {
  // One box in a sketch is placed by the sketch in the same way.
  if (const DocScript* sc =
          doc_script_of(d, doc_literal_word(d, layer, "script"));
      sc && sc->run && sc->run->sketch())
    return true;
  // A layer with no copies but with expressions is its own single copy, index 0
  // of 1.
  if (!doc_expressions_fx(d, layer).empty()) return true;
  return doc_members(d, layer) > 1 ||
         doc_number(d, layer, "stagger", 0, 0) > 0.0;
}

}  // namespace motolii

#ifndef MOTOLII_DOCUMENT_EDIT_STROKE_PUT_H_
#define MOTOLII_DOCUMENT_EDIT_STROKE_PUT_H_
// stroke_put.h: adds and removes an extra stroke on a layer. Each stroke is
// one entry of the "strokes" property, "<id>:" — a 6-hex-char instance ID
// followed by a colon. Its colour and width are keyed under the names
// "<id>:stroke" and "<id>:stroke_width", so the same layer can carry as many
// strokes as the user wants, each with its own value and its own keyframes,
// like stacking the same effect in After Effects. See
// engine/document/edit/fx_put.cpp for the instance-ID mechanism this follows.

#include <string>
#include <vector>

namespace motolii {

struct Doc;

// Returns the layer's extra strokes in the order they are drawn. Each entry
// is one instance ID followed by a colon, as in the "strokes" property.
std::vector<std::string> doc_stroke_list(Doc& d, int layer);
// Joins the entries with single spaces, the form stored in the "strokes"
// property.
std::string doc_stroke_join(const std::vector<std::string>& list);
// Adds a new extra stroke on the layer with a fresh instance ID. The stroke
// is drawn outside of the preceding ones, like After Effects adding one more
// outline.
bool doc_stroke_add(Doc& d, int layer);
// Takes the extra stroke with instance ID `id` off the layer and deletes its
// per-instance colour and width keyframes.
bool doc_stroke_out(Doc& d, int layer, const char* id);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_STROKE_PUT_H_

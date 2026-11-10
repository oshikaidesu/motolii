#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_

// How doc_match builds a shape layer: a flat shape in one colour or a ramp.

namespace motolii {

struct Doc;

// Returns true if the layer has any bending property set, either in its
// keyframes or in the values held by a drag in progress.
bool doc_bends(Doc& d, int layer);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_

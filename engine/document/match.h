#ifndef MOTOLII_DOCUMENT_MATCH_H_
#define MOTOLII_DOCUMENT_MATCH_H_

// Contains doc_match, which rebuilds the preview stage to match the document,
// and the helpers it uses.

#include <string>

#include "document/kinds.h"

namespace motolii {

// Returns the bevel profile of a layer as its index in {angular, convex,
// concave, ogee, step} plus one, or 0 for none. Only a layer with depth
// (scale_z) can have a bevel.
int doc_bevel(Doc& d, int layer);
// Returns the modification time of a p5.js sketch file at the last time it ran
// as a whole 2D sketch. A layer made from the sketch is rebuilt when this value
// changes. If the code does not run, the layer keeps its last working version
// and d.error gets the reason, as the Shadertoy editor keeps the last image
// that compiled. The sketch that ran is kept ready for the layer to use.
long long doc_sketch_written(Doc& d, const std::string& file);
// Rebuilds the preview stage to match the document. For each layer it builds a
// text describing everything that affects how the layer is built. A layer whose
// text changed, or that is new, is torn down and built again. Values that
// change at every time are applied separately by doc_evaluate. Returns false if
// any layer could not be built; d.error then holds the reason.
bool doc_match(Doc& d);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_H_

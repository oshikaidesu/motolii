#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_

// What doc_match reads of a layer's look before it builds the layer: its fill,
// its edge, and the effects and drawing options of a flat layer.

namespace motolii {

struct Doc;

// Returns true if the layer is lit by the scene's lights. It is lit like an
// After Effects 3D layer once the project has a light layer. With no light it
// is drawn as it is, unless it is metallic: a metal shows what it mirrors, and
// it mirrors the stage's environment, like the reflection map of Element 3D.
bool doc_lit(Doc& d, int layer);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_

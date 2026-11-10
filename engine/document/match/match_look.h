#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_

// What doc_match reads of a layer's look before it builds the layer: its fill,
// its edge, and the effects and drawing options of a flat layer.

namespace motolii {

struct Doc;
struct LayerBuild;

// Returns true if the layer is lit by the scene's lights. It is lit like an
// After Effects 3D layer once the project has a light layer. With no light it
// is drawn as it is, unless it is metallic: a metal shows what it mirrors, and
// it mirrors the stage's environment, like the reflection map of Element 3D.
bool doc_lit(Doc& d, int layer);

// Reads the layer's fill: one colour, or the colours of a ramp with their
// positions.
void match_fill(LayerBuild& build);

// Reads the layer's edge, and how many points of the image make one unit of
// the stage where layers start. `why` of the layer says so when the edge is
// not a colour.
void match_stroke(LayerBuild& build);

// Reads the effects and drawing options of a flat layer into `fx` of the
// layer: its depth and material, its ramp, its copies, how a text is set, the
// ends of its edge, and its built-in effects at the largest size they reach.
// `fxOk` of the layer is false when an effect could not be read; `why` then
// says which.
void match_flat_look(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_LOOK_H_

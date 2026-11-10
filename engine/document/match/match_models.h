#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_MODELS_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_MODELS_H_

// How doc_match builds a solid layer: a 3D model, one of the built-in shapes
// or a file, with the material it wears.

namespace motolii {

struct LayerBuild;

// Builds a solid layer: a built-in shape (a gem, a cube, a ball, a ring or a
// p5.js sketch's mesh), a point cloud, or a model file. Its fill is its
// surface: a colour, or the material glass.
void match_model(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_MODELS_H_

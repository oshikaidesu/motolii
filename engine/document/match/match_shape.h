#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_

// How doc_match builds a shape layer: a flat shape in one colour or a ramp.

namespace motolii {

struct Doc;
struct LayerBuild;

// Builds a shape layer: a flat colour as large as the stage, a built-in shape
// or a path, cut into triangles when it is plain and drawn by ThorVG when it
// is not.
void match_shape(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_SHAPE_H_

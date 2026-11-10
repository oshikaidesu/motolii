#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_MATERIALS_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_MATERIALS_H_

// What doc_evaluate sets in the materials of one layer that is on, as the
// document has it at one time: the 3D box and its bevel, the surface, the
// material the layer wears, the opacity and its emissive. Each function takes the
// layer and `t`, the layer as it is on the stage, and does nothing for a layer
// it does not apply to.

namespace motolii {

struct Doc;
struct DocShownLayer;

// Updates the materials of a layer with depth when its 3D box opens or shuts.
// `open` says whether the box is open now, and `solid` whether the layer takes
// part in depth sorting.
void evaluate_box(Doc& d, DocShownLayer& t, bool open, bool solid);

// Sets the bevel of a layer with depth.
void evaluate_bevel(Doc& d, int layer, DocShownLayer& t, double now);

// Sets the metallic, roughness and reflectance of a flat layer that is lit.
void evaluate_lit_surface(Doc& d, int layer, DocShownLayer& t, double now);

// Sets the parameters of the material a flat layer wears (doc_sheet_material).
void evaluate_sheet_material(Doc& d, int layer, DocShownLayer& t, double now);

// Sets the colors and surfaces of the bevel, the side and the back of a layer
// with depth.
void evaluate_part_colours(Doc& d, int layer, DocShownLayer& t, double now);

// Sets the dissolve and grain of a splat layer and the uniforms of its effect.
void evaluate_splat(Doc& d, int layer, DocShownLayer& t, double now);

// How opaque a layer is and where that is applied.
struct LayerOpacity {
  // True when the opacity is applied on the sheet of the layer's own effects,
  // after them.
  bool sheetClear;
  // The opacity of the layer's own materials: 1 when the effects sheet takes
  // the opacity.
  double ownClear;
};

// Sets the opacity of a layer, on its effects sheet or on its own materials,
// and returns what was set.
LayerOpacity evaluate_opacity(Doc& d, int layer, DocShownLayer& t, double now);

// Sets how much a layer lights itself: its emissive.
void evaluate_glow(Doc& d, int layer, DocShownLayer& t, double now);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_MATERIALS_H_

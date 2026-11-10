#ifndef MOTOLII_DOCUMENT_MOMENT_FX_H_
#define MOTOLII_DOCUMENT_MOMENT_FX_H_

// moment_fx.h: per-layer effects for doc.h.
// A layer with effects of its own is drawn alone into an image of the box where it is seen. Its
// effects run on that image before the stage's own view is rendered.
// A layer whose fx names a solid's shape (solids/*.js, for example Alight Motion's Box or Torus) is
// instead drawn alone, square to its own face. Its effects run on that image, and the result is
// laid on the solid's faces where the solid lies. The layer's own sheet is not shown.
// See engine/stage/effects/layer_fx.h.

#include <utility>
#include <vector>

#include "document/kinds.h"
#include "stage/effects/layer_fx.h"

// Returns whether the layer is a group (a Null layer) with effects of its own, including ThorVG
// effects. The layers in the group are drawn together into one image, the effects run on that
// image, and the image is laid where the group lies.
// This matches Alight Motion, where a group is a scene as wide and high as the stage
// (engine/third_party/AbsentMotion/app/src/main/kotlin/app/absentmotion/editor/StructureActions.kt,
// grouped: embedScene). It also matches After Effects, where effects on a precomposed layer work on
// its layers together.
bool doc_holds_fx(Doc& d, int layer);
// Returns whether the layer has effects of its own, from effect files or because it is a group
// holding effects.
bool doc_own_fx(Doc& d, int layer);
// Returns whether the layer's effect image stands in the world where the layer lies (see
// thing_fx_stand). This holds for a single flat layer whose effects work on its own image.
// It does not hold for a layer that reads what is behind it or draws on the whole stage, because
// the stage is its frame. It does not hold for a solid or a layer with many copies, which have no
// single face. It does not hold for a group, whose layers stay where they are.
bool doc_layer_stands(Doc& d, int layer, ThingFx& e);
// Returns whether a solid stays in the world and shows the effect image itself (see
// engine/materials/effected_solid.mat). This holds when the solid's effects work on its own image,
// as they do for a standing layer.
bool doc_layer_shows(Doc& d, int layer, ThingFx& e);

// Rebuilds the effect passes of all layers that have effects of their own. For each layer it
// registers a callback that runs before the frame, to place the layer and prepare its images, and a
// callback that runs in the frame, to draw the layer alone and run its effects. A layer that puts
// the image on its own faces also gets a callback that runs after the frame. See
// engine/stage/effects/layer_fx.h.
void doc_layers_fx(Doc& d);
// Gives each layer that reads what is under it an image of its backdrop. A layer reads its backdrop
// if it uses a blend mode that the GPU's own blending lacks (the W3C backdrop modes), if it fills
// with what is behind it (After Effects' Adjustment Layer), or if its material is glass.
// For each such layer, the stage without that layer and without all that lies over it is drawn into
// an image of its own before the layer is drawn. The layers are handled in stacking order, so each
// one reads those under it as they are laid. This uses the same view as the glass, and Filament's
// layer masks leave the rest out of that one image.
void doc_layers_read(Doc& d, const std::vector<std::pair<int, Doc::Shown*>>& laid);

#endif  // MOTOLII_DOCUMENT_MOMENT_FX_H_

#ifndef MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_
#define MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_

// moment_fx.h: per-layer effects.
// A layer with effects of its own is drawn alone into an image of the box where
// it is seen. Its effects run on that image before the stage's own view is
// rendered. A layer whose fx names a solid's shape (solids/*.js, for example
// Alight Motion's Box or Torus) is instead drawn alone, square to its own face.
// Its effects run on that image, and the result is laid on the solid's faces
// where the solid lies. The layer's own sheet is not shown. See
// engine/stage/layer_effects/layer_fx.h.

#include <map>
#include <utility>
#include <vector>

#include "stage/effects/screen_fx.h"
#include "stage/layer_effects/layer_fx.h"

namespace filament {
class RenderTarget;
class Texture;
}  // namespace filament

namespace motolii {

struct Doc;
struct DocShownLayer;

// The effects of the project as they are on the stage.
struct DocEffects {
  // The layers that have effects of their own (layer_fx.h). Each is drawn alone
  // with its effects applied and is laid where the layer lies.
  std::map<int, ThingFx> layerFx;
  // A layer that reads what is under it: seen is its image of what is below,
  // into is the target that image is drawn to.
  struct Read {
    filament::Texture* seen = nullptr;
    filament::RenderTarget* into = nullptr;
  };
  // The layers that read what is under them, each with its image of it (see
  // doc_layers_read).
  std::map<int, Read> reads;
  // Which layer each of the stage's `before` entries belongs to.
  std::vector<int> beforeOf;
  // The stage's whole-screen effects: its script .wgsl files, one over another
  // (screen_fx.h).
  ScreenStack screen;
};

// The parts of a layer's effects, defined in moment_fx_parts.cpp.
// Prepares a solid layer before the frame is rendered. Draws the layer square
// to its own face, runs its effects, and lays the result on the solid's faces
// where the solid lies.
void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e);
// While the stage is drawn, puts the layer's effect image on its faces (on is
// true). When on is false, puts back the faces' original materials. Does
// nothing if the layer is not shown or is already in the requested state.
void doc_layer_shell(Doc& d, int layer, ThingFx& e, bool on);
// Computes how far the stage reaches from a standing layer along each side of
// the layer's face, and writes four values to sides: toward -x, +x, -y and +y
// of the layer's own axes, in layer units. The stage's corners are projected
// back onto the layer's plane. seen is the length in stage points of one layer
// unit where the layer lies. Each value is rounded up to a multiple of 256
// stage points, so the layer's image is made again only after the stage has
// moved that far. A face seen edge on reaches no further than three times the
// stage's longer side.
void doc_fx_sides(Doc& d, const filament::math::mat4& place, double seen, double* sides);
// Prepares a standing layer before the frame is rendered. Reads its placement
// and scale under the document lock, then sets up its effect image.
void doc_layer_stand(Doc& d, int layer, ThingFx& e);
// Writes where the layer lies on its effect image to frame, in the form
// doc_frame uses for the stage. A standing layer is in the middle of the image
// and upright. Returns false if the layer has no frame.
bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame);
// Runs while the frame is rendered. Draws the effects of a solid layer. If the
// solid's file reads the image, also updates the solid from it, using the
// precision parameter (default 160).
void doc_layer_solid(Doc& d, int layer, ThingFx& e,
                     const ScreenNumbers& numbers);
// Answers an AviUtl2 script's questions about the other layers (see
// engine/community/aviutl/aviutl_fx.h). The script's layers are the document's
// layers in stacking order, with the furthest back as layer 1. AviUtl2 draws
// layer 1 first and the higher layers over it (see doc_laid). box is the
// layer's box on the stage, and usual is the value to return when the layer has
// no number. The supported names are:
// - aviutl.layer: this layer's own number.
// - aviutl.layer_max: the number of layers.
// - aviutl.layerN[.name][@seconds]: the value of layer N, taken the given
// number of seconds from
//   its start, or now if there is no @seconds. This follows
//   obj.getvalue("layer1.x", time) in AviUtl2's script API. x and y are pixels
//   of the script's frame measured from its middle, as obj.x is. rz is the
//   rotation, alpha is the opacity, and time is the time from the layer's
//   start.
// - aviutl.groupN: the layer of the Nth group this layer is in, where 0 is the
// nearest. This
//   follows obj.getoption("group_info").
// Returns NaN, which the script sees as nil, if the layer does not exist or is
// not shown.
double doc_aviutl_asked(Doc& d, int layer, const double* box,
                        const std::string& name, double usual);
// Sets how a layer reads what is under it: the blend mode way, whether it fills
// with what is behind it (behind), and the image of what lies under it
// (picture). It is set on every material of the layer that has a blendWay
// parameter.
void doc_reading(Stage& s, DocShownLayer& t, float way, float behind,
                 filament::Texture* picture);
// The same as doc_reading for a layer with effects. What such a layer lays on
// the stage is its sheet, so its blend mode is applied after its effects, as in
// After Effects, where a layer's blending mode comes after its effects.
void doc_sheet_reads(Doc& d, int layer, float way, filament::Texture* picture);

// Returns whether the layer is a group (a Null layer) with effects of its own.
// The layers in the group are drawn together into one
// image, the effects run on that image, and the image is laid where the group
// lies. This matches Alight Motion, where a group is a scene as wide and high
// as the stage
// (engine/third_party/AbsentMotion/app/src/main/kotlin/app/absentmotion/editor/StructureActions.kt,
// grouped: embedScene). It also matches After Effects, where effects on a
// precomposed layer work on its layers together.
bool doc_holds_fx(Doc& d, int layer);
// Returns whether the layer has effects of its own, from effect files or
// because it is a group holding effects.
bool doc_own_fx(Doc& d, int layer);
// Returns whether the layer's effect image stands in the world where the layer
// lies (see thing_fx_stand). This holds for a single flat layer whose effects
// work on its own image. It does not hold for a layer that reads what is behind
// it or draws on the whole stage, because the stage is its frame. It does not
// hold for a solid or a layer with many copies, which have no single face. It
// does not hold for a group, whose layers stay where they are.
bool doc_layer_stands(Doc& d, int layer, ThingFx& e);
// Returns whether a solid stays in the world and shows the effect image itself
// (see engine/materials/effected_solid.mat). This holds when the solid's
// effects work on its own image, as they do for a standing layer.
bool doc_layer_shows(Doc& d, int layer, ThingFx& e);

// Rebuilds the effect passes of all layers that have effects of their own. For
// each layer it registers a callback that runs before the frame, to place the
// layer and prepare its images, and a callback that runs in the frame, to draw
// the layer alone and run its effects. A layer that puts the image on its own
// faces also gets a callback that runs after the frame. See
// engine/stage/layer_effects/layer_fx.h.
void doc_layers_fx(Doc& d);
// Gives each layer that reads what is under it an image of its backdrop. A
// layer reads its backdrop if it uses a blend mode that the GPU's own blending
// lacks (the W3C backdrop modes), if it fills with what is behind it (After
// Effects' Adjustment Layer), or if its material is glass. For each such layer,
// the stage without that layer and without all that lies over it is drawn into
// an image of its own before the layer is drawn. The layers are handled in
// stacking order, so each one reads those under it as they are laid. This uses
// the same view as the glass, and Filament's layer masks leave the rest out of
// that one image.
void doc_layers_read(Doc& d,
                     const std::vector<std::pair<int, DocShownLayer*>>& laid);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_

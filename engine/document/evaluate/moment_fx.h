#ifndef MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_
#define MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_

// Per-layer effects. A layer with its own fx is drawn alone and its effects
// run before the stage renders. See layer_fx.h.

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
  // Layers with their own effects (layer_fx.h).
  std::map<int, ThingFx> layerFx;
  // A layer that reads what is under it.
  struct Read {
    filament::Texture* seen = nullptr;
    filament::Texture* deep = nullptr;
    filament::RenderTarget* into = nullptr;
    // Built at desk size while editing, comp size on export (doc_layers_read).
    uint32_t w = 0, h = 0;
  };
  std::map<int, Read> reads;
  std::vector<int> beforeOf;
  ScreenStack screen;
};

// Prepares a solid layer: draws it square to its own face, applies effects,
// lays the result on the solid's faces.
void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e);
// Swaps the layer's faces between its effect image (on) and original materials.
void doc_layer_shell(Doc& d, int layer, ThingFx& e, bool on);
// Writes four values to sides: how far the stage reaches along -x, +x, -y, +y
// of the layer's own axes. Rounded up to 256 px multiples to avoid rebuilding
// every frame.
void doc_fx_sides(Doc& d, const filament::math::mat4& place, double seen, double* sides);
// Prepares a standing layer: reads placement under the doc lock, sets up its
// effect image.
void doc_layer_stand(Doc& d, int layer, ThingFx& e);
// Writes the layer's position on its effect image to frame. Returns false if
// the layer has no frame.
bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame);
// Draws the effects of a solid layer during the frame render.
void doc_layer_solid(Doc& d, int layer, ThingFx& e,
                     const ScreenNumbers& numbers);
// Answers an AviUtl2 script's queries about other layers (aviutl_fx.h).
// Supported: aviutl.layer, aviutl.layer_max, aviutl.layerN[.name][@seconds],
// aviutl.groupN. Returns NaN if the layer does not exist.
double doc_aviutl_asked(Doc& d, int layer, const double* box,
                        const std::string& name, double usual);
// Sets blend mode, behind-fill and backdrop image on every material with a
// blendWay parameter.
void doc_reading(Stage& s, DocShownLayer& t, float way, float behind,
                 filament::Texture* picture);
// doc_reading for a layer with effects: blend mode is applied after effects.
void doc_sheet_reads(Doc& d, int layer, float way, filament::Texture* picture);

// Whether the layer is a group with its own effects. The group's layers are
// drawn together and the effects run on the combined image.
bool doc_holds_fx(Doc& d, int layer);
bool doc_own_fx(Doc& d, int layer);
// Whether the effect image stands in the world (thing_fx_stand). False for
// backdrop-readers, solids, multi-copy layers, and groups.
bool doc_layer_stands(Doc& d, int layer, ThingFx& e);
// Whether a solid shows its own effect image (effected_solid.mat).
bool doc_layer_shows(Doc& d, int layer, ThingFx& e);

// Rebuilds effect passes for all layers with own effects (layer_fx.h).
void doc_layers_fx(Doc& d);
// Gives each backdrop-reading layer its own image of what lies under it.
// Triggers: W3C backdrop blend modes, adjustment layers, or glass material.
// Handled in stacking order; Filament layer masks isolate each backdrop.
void doc_layers_read(Doc& d,
                     const std::vector<std::pair<int, DocShownLayer*>>& laid);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_MOMENT_FX_H_

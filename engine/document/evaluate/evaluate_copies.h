#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_COPIES_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_COPIES_H_

// What doc_evaluate does at one time for the copies of one layer that is on:
// where each copy is placed, and the material, color and opacity each copy is
// given. A layer on its own is one copy.

#include <math/mat4.h>

#include <vector>

namespace motolii {

struct Doc;
struct DocShownLayer;
struct LayerOpacity;
struct Mesh;

// Where the copies of one layer are placed at one time.
struct CopyPlaces {
  // The place of the layer itself.
  filament::math::mat4f place;
  // True when each copy, the first included, is delayed as late as its order
  // says and placed as its expressions say.
  bool staggered = false;
  // For a joining layer, whose copies lie between another layer's copies: the
  // place of each copy. Empty for any other layer.
  std::vector<filament::math::mat4> joins;
};

// Works out where the copies of a layer go.
CopyPlaces evaluate_copy_places(Doc& d, int layer, double now);

// Moves each copy of a layer to its place, and orders the copies of a flat
// layer by their distance from the camera. `t` is the layer as it is on the
// stage, `m` the mesh its copies are drawn with, and `solid` says whether the
// layer takes part in depth sorting.
void evaluate_copies_placed(Doc& d, int layer, DocShownLayer& t, const Mesh* m,
                            double now, bool solid, const CopyPlaces& places);

// Gives each copy of a solid the color its sketch gives it, in a material of
// its own.
void evaluate_scripted_copy_colours(Doc& d, int layer, DocShownLayer& t,
                                    const Mesh* m);

// Gives each copy of a flat layer its own color, letter and opacity in a
// material of its own, or takes those materials away when no copy differs from
// the layer. `layer_opacity` is what evaluate_opacity returned for the layer.
void evaluate_copy_looks(Doc& d, int layer, DocShownLayer& t, const Mesh* m,
                         double now, const LayerOpacity& layer_opacity);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_COPIES_H_

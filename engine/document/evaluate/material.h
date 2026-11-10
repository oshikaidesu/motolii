#ifndef MOTOLII_DOCUMENT_EVALUATE_MATERIAL_H_
#define MOTOLII_DOCUMENT_EVALUATE_MATERIAL_H_
// Contains the material a layer wears and the helpers that reach the materials and renderables
// of a layer on the stage.

#include <functional>
#include <string>

#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <utils/Entity.h>

#include "document/kinds.h"
#include "stage/render/render_stage.h"

// Returns the material a layer wears. In the Material group of the Create tab any layer can wear
// one, one at a time, and the shading property names it. Documents from before that group existed
// filled a solid with glass to get glass, so a solid filled with glass wears glass. Returns "" for
// none: a solid then uses Filament's lit surface, and a flat layer is drawn as it is.
std::string doc_material(Doc& d, int layer);
// Returns the variant of the material for a flat layer (a video, image, text or shape): the variant
// of flat.mat made for it (materials/build.sh), with the image as its colour. Returns "" for none,
// and the layer is then drawn as it is. For glass the stage behind the layer is read
// (doc_layers_read).
std::string doc_sheet_material(Doc& d, int layer);
// Returns the 1-based index in flat.mat's blendWay of a blend mode that reads the pixels
// underneath, as defined by the W3C compositing specification and implemented by After Effects and
// ThorVG. Returns 0 for the modes that the GPU's own blending does: normal, add, multiply and
// screen.
int doc_blend_way(const std::string& word);
// Calls `each` with every material instance of a layer on the stage: the one of a sheet, the ones
// of a built-in shape (as many as it is drawn by), and every face of a 3D file.
void doc_material_instances(Stage& s, const Doc::Shown& t, const std::function<void(filament::MaterialInstance*)>& each);
// Calls `each` with each part of a layer that is drawn, as Filament renderables.
void doc_entities(Stage& s, const Doc::Shown& t, const std::function<void(utils::Entity)>& each);
// Calls `each` with the renderable manager and the instance of each drawn part of a layer.
void doc_parts(Stage& s, const Doc::Shown& t, const std::function<void(filament::RenderableManager&, filament::RenderableManager::Instance)>& each);
#endif  // MOTOLII_DOCUMENT_EVALUATE_MATERIAL_H_

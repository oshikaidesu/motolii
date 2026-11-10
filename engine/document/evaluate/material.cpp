#include "document/evaluate/material.h"

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <utils/Entity.h>

#include <cstddef>
#include <functional>
#include <string>

#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/value_at.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

std::string doc_material(Doc& d, int layer) {
  const std::string said = doc_word(d, layer, "shading");
  if (!said.empty()) return said;
  return doc_word(d, layer, "kind") == "solid" &&
                 doc_word(d, layer, "fill") == "glass"
             ? "glass"
             : "";
}

std::string doc_sheet_material(Doc& d, int layer) {
  if (!doc_among("video image text shape", doc_word(d, layer, "kind")))
    return "";
  const std::string m = doc_material(d, layer);
  return m == "lit"                                        ? "wear"
         : m == "glass" || m == "filament_glass"           ? "glass"
         : doc_among("cloth subsurface lacquer bubble", m) ? m
                                                           : "";
}

int doc_blend_way(const std::string& word) {
  static const char* const ways[] = {
      "darken",     "lighten",      "overlay",       "soft_light",
      "hard_light", "color_dodge",  "color_burn",    "difference",
      "exclusion",  "hue",          "saturation",    "color",
      "luminosity", "linear_burn",  "linear_light",  "vivid_light",
      "pin_light",  "darker_color", "lighter_color", "subtract",
      "divide"};
  for (int i = 0; i < 21; ++i)
    if (word == ways[i]) return i + 1;
  return 0;
}

void doc_material_instances(
    Stage& s, const Doc::Shown& t,
    const std::function<void(MaterialInstance*)>& each) {
  auto& faces = s.engine->getRenderableManager();
  if (t.video) each(t.video->look);
  if (t.drawn) each(t.drawn->look);
  for (const Stage::Renderable& made : s.renderables)
    if (t.shape && made.of == t.shape)
      each(faces.getMaterialInstanceAt(faces.getInstance(made.thing), 0));
  if (t.solid)
    for (const utils::Entity e : t.solid->parts) {
      const auto one = faces.getInstance(e);
      for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
        each(faces.getMaterialInstanceAt(one, part));
    }
}

void doc_entities(Stage& s, const Doc::Shown& t,
                  const std::function<void(utils::Entity)>& each) {
  const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
  for (const Stage::Renderable& made : s.renderables)
    if (m && made.of == m && !made.matte) each(made.thing);
  if (t.solid)
    for (const utils::Entity e : t.solid->parts) each(e);
}

void doc_parts(Stage& s, const Doc::Shown& t,
               const std::function<void(RenderableManager&,
                                        RenderableManager::Instance)>& each) {
  auto& faces = s.engine->getRenderableManager();
  doc_entities(s, t,
               [&](utils::Entity e) { each(faces, faces.getInstance(e)); });
}

}  // namespace motolii

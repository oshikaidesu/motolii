#include "document/match/match_layers.h"

#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <utils/Entity.h>
#include <utils/EntityManager.h>

#include <filesystem>
#include <map>
#include <string>

#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/match/rebuild.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::RenderableManager;

namespace {

// Takes one layer off the stage: out of its scene, with its copies' materials,
// its matte shape, and whatever was made for its kind.
void take_layer_off(Doc& d, Stage& s,
                    std::map<int, DocShownLayer>::iterator it) {
  // Remove it from the scene of its run first, because the removal code below
  // takes layers only out of the stage's own scene.
  if (it->second.scene && it->second.scene != s.scene)
    doc_entities(s, it->second,
                 [&](utils::Entity e) { it->second.scene->remove(e); });
  // Give the copies back their own materials first, while the copies are
  // still known.
  if (const Mesh* m = it->second.video   ? it->second.video->sheet
                      : it->second.drawn ? it->second.drawn->sheet
                                         : it->second.shape)
    doc_copy_looks_off(d, m,
                       it->second.video   ? it->second.video->look
                       : it->second.drawn ? it->second.drawn->look
                                          : it->second.look);
  // Then remove the shape it uses to cut a matte.
  if (const Mesh* m = it->second.video   ? it->second.video->sheet
                      : it->second.drawn ? it->second.drawn->sheet
                                         : it->second.shape)
    doc_unshape(s, [m](const Stage::Renderable& made) { return made.of == m; });
  if (it->second.video) video_off(s, it->second.video);
  if (it->second.drawn) canvas_off(s, it->second.drawn);
  for (const auto& deep : it->second.deep) canvas_off(s, deep.sheet);
  if (it->second.solid) solid_off(s, it->second.solid);
  // Remove the light from every scene and destroy it.
  if (!it->second.light.isNull()) {
    s.scene->remove(it->second.light);
    s.engine->getLightManager().destroy(it->second.light),
        utils::EntityManager::get().destroy(it->second.light);
  }
  // The sorting of a point cloud is dropped with it.
  if (it->second.shape)
    s.playing.erase(it->second.shape), take_off(s, it->second.shape);
}

}  // namespace

void match_tear_down_changed(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  Stage& s = rebuild.s;
  const std::map<int, std::string>& told = rebuild.told;
  for (auto it = d.on_stage.shown.begin(); it != d.on_stage.shown.end();) {
    const auto still = told.find(it->first);
    // A text whose words came out wider than its image is always rebuilt.
    if (still != told.end() && still->second == it->second.of &&
        !(it->second.drawn && it->second.drawn->outgrown)) {
      ++it;
      continue;
    }
    take_layer_off(d, s, it);
    it = d.on_stage.shown.erase(it);
  }
}

}  // namespace motolii

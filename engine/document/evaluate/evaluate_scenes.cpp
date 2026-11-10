#include "document/evaluate/evaluate_scenes.h"

#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/View.h>
#include <utils/Entity.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/material.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/value_at.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

namespace {

// Returns the effects state of a layer drawn on its own, building it if
// needed. Unless `shows` is true, the layer's sheet is laid over what is
// behind it with the layer's blend mode when that mode is add, multiply or
// screen, which Filament blends natively. Other blend modes are treated as
// normal for now.
ThingFx& layer_fx_built(Doc& d, int layer, bool shows) {
  Stage& s = *d.stage;
  const std::string laid = doc_word(d, layer, "blend");
  return thing_fx_built(
      s, d.effects.layerFx[layer],
      shows                                                     ? ""
      : laid == "add" || laid == "multiply" || laid == "screen" ? laid
                                                                : "",
      !shows && doc_layer_stands(d, layer, d.effects.layerFx[layer]), shows);
}

// Returns the scene a layer is drawn in. That is the scene of the nearest
// ancestor group that has effects of its own and is on now, or the stage's
// scene if there is none. The walk stops after 64 levels.
Scene* scene_holding(const Evaluation& evaluation, int layer) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0;
       up > 0 && n < 64; up = (int)doc_number(d, up, "parent", 0, 0), ++n) {
    if (!doc_holds_fx(d, up)) continue;
    const auto at =
        std::find_if(lies.begin(), lies.end(),
                     [&](const EvaluatedLayer& l) { return l.layer == up; });
    if (at != lies.end() && runOf[(size_t)(at - lies.begin())] >= 0)
      return layer_fx_built(d, up, false).view->getScene();
  }
  return s.scene;
}

// Gives a layer the channel of its run and its blend order in it. `i` is the
// layer's index in the evaluation's `lies`, and `solid` whether it takes part
// in depth sorting.
void layer_ordered(Stage& s, DocShownLayer& t, int run, size_t i, bool solid) {
  // The channel is the run index, capped at Filament's highest channel, 7.
  if (const int channel = std::min(run, 7); channel != t.channel) {
    doc_parts(s, t,
              [&](RenderableManager& faces, RenderableManager::Instance one) {
                faces.setChannel(one, (uint8_t)channel);
              });
    t.channel = channel;
  }
  // The first time a flat layer is placed in a run, switch off its depth test
  // and depth write.
  if (t.run < 0 && !solid)
    doc_material_instances(s, t, [](MaterialInstance* look) {
      look->setDepthCulling(false), look->setDepthWrite(false);
    });
  if (t.lies != (int)i && !solid)
    doc_parts(
        s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
          // Each flat layer gets 128 blend-order slots. Its copies are
          // ordered among themselves inside those slots by distance.
          for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
            faces.setBlendOrderAt(one, part, (uint16_t)(i * 128)),
                faces.setGlobalBlendOrderEnabledAt(one, part, true);
        });
  t.run = run, t.lies = (int)i;
}

// Lays the effects sheet where the layer lies, with the same channel and
// blend order, in the scene of the group the layer is in.
void fx_sheet_laid(Doc& d, int layer, Scene* above, int run, size_t i,
                   bool solid) {
  Stage& s = *d.stage;
  auto& faces = s.engine->getRenderableManager();
  thing_fx_into(s, d.effects.layerFx[layer], above);
  // `stood` means the sheet stands in the 3D world. A solid layer's sheet
  // is then depth sorted by distance like any solid. A 2D layer's sheet is
  // ordered by stacking order.
  const bool stood = d.effects.layerFx[layer].world, deep = stood && solid;
  if (stood)
    d.effects.layerFx[layer].look->setDepthCulling(deep),
        d.effects.layerFx[layer].look->setDepthWrite(deep);
  for (const Stage::Renderable& made : s.renderables)
    if (made.of == d.effects.layerFx[layer].sheet ||
        (d.effects.layerFx[layer].solid &&
         made.of == d.effects.layerFx[layer].solid)) {
      const auto one = faces.getInstance(made.thing);
      // The sheet's vertices are the screen corners, so it is never culled.
      faces.setCulling(one, false),
          faces.setChannel(one, (uint8_t)std::min(run, 7)),
          faces.setBlendOrderAt(one, 0, (uint16_t)(i * 128)),
          faces.setGlobalBlendOrderEnabledAt(one, 0, !deep);
    }
}

// Puts one layer that is drawn into the scene of its run. `i` is its index in
// the evaluation's `lies`.
void layer_into_scene(const Evaluation& evaluation, size_t i) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  const int run = runOf[i];
  DocShownLayer& t = *lies[i].shown;
  // A layer with effects of its own is drawn alone and its image is laid in
  // the scene above it; see engine/stage/layer_effects/layer_fx.h.
  const bool own = doc_own_fx(d, lies[i].layer);
  // A solid that shows its own image stays in the stage's scene. It is also
  // filmed by its effects view, together with the stage's lights.
  const bool shows = own && doc_layer_shows(d, lies[i].layer,
                                            d.effects.layerFx[lies[i].layer]);
  Scene* const above = scene_holding(evaluation, lies[i].layer);
  Scene* into =
      own ? layer_fx_built(d, lies[i].layer, shows).view->getScene() : above;
  // Copy the stage's lights and this layer's entities into the effects view,
  // then continue with the enclosing scene.
  if (shows) {
    s.scene->forEach([&, film = into](utils::Entity e) {
      if (s.engine->getLightManager().hasComponent(e)) film->addEntity(e);
    });
    doc_entities(s, t, [film = into](utils::Entity e) { film->addEntity(e); });
    into = above;
  }
  // Every other run lives in the stage's own scene and is kept in order by
  // Filament channels.
  Scene* const was = t.scene ? t.scene : s.scene;
  // Move the layer's entities into the scene of its run. A layer that is not
  // shown yet is added when it becomes shown.
  if (was != into) {
    if (t.in)
      doc_entities(
          s, t, [&](utils::Entity e) { was->remove(e), into->addEntity(e); });
    t.scene = into;
  }
  layer_ordered(s, t, run, i, lies[i].solid);
  if (own) fx_sheet_laid(d, lies[i].layer, above, run, i, lies[i].solid);
}

}  // namespace

// Depth ordering. Flat layers take no part in depth and are ordered by
// stacking order alone. Solid layers that follow one another sort depth among
// themselves. Each run of one sort lies wholly over the run before it. All
// runs are in the stage's own view and are kept in order by Filament render
// channels. Within a run of flat layers the blend order decides. A flat
// layer's materials neither read nor write depth.
void evaluate_runs(Evaluation& evaluation) {
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  std::vector<int>&runOf = evaluation.runOf, &sorts = evaluation.sorts;
  runOf.assign(lies.size(), -1);
  for (size_t i = 0; i < lies.size(); ++i) {
    // A camera, a behaviour or a light belongs to no run because nothing of it
    // is drawn.
    if (!lies[i].on || lies[i].shown->camera || lies[i].shown->behaviour ||
        !lies[i].shown->light.isNull())
      continue;
    const int sort = lies[i].solid ? 1 : 0;
    if (sorts.empty() || sorts.back() != sort) sorts.push_back(sort);
    runOf[i] = (int)sorts.size() - 1;
  }
  // `base` is 1 when flat layers lie under the first solid layers.
  evaluation.base = sorts.size() > 1 && sorts[0] == 0 && sorts[1] == 1 ? 1 : 0;
}

void evaluate_scenes(const Evaluation& evaluation) {
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  for (size_t i = 0; i < lies.size(); ++i) {
    if (runOf[i] < 0) continue;
    layer_into_scene(evaluation, i);
  }
}

// Releases the effects state of layers that no longer have effects of their
// own or are gone.
void evaluate_effects_released(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  for (auto e = d.effects.layerFx.begin(); e != d.effects.layerFx.end();) {
    const auto at = std::find_if(lies.begin(), lies.end(), [&](const auto& l) {
      return l.layer == e->first;
    });
    if (at == lies.end() || runOf[(size_t)(at - lies.begin())] < 0 ||
        !doc_own_fx(d, e->first)) {
      // A layer past its time range keeps the effects scene it was last in.
      // Take its parts out of that scene and clear its scene pointer before the
      // scene is released. Otherwise the next evaluation would remove them from
      // a scene that Filament has already destroyed, and Filament does not
      // allow a destroyed scene to be touched. A group's effects scene also
      // holds every layer the group contained and every sheet laid in it, so
      // those are detached too.
      Scene* const gone = e->second.view ? e->second.view->getScene() : nullptr;
      for (auto& [layer, t] : d.on_stage.shown)
        if (gone && t.scene == gone) {
          if (t.in)
            doc_entities(s, t, [&](utils::Entity x) { gone->remove(x); });
          t.scene = nullptr, t.in = false;
        }
      for (auto& [layer, other] : d.effects.layerFx)
        if (gone && other.in == gone) thing_fx_into(s, other, s.scene);
      thing_fx_off(s, e->second), e = d.effects.layerFx.erase(e);
    } else
      ++e;
  }
}

void evaluate_layers_read(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  const std::vector<int>& runOf = evaluation.runOf;
  std::vector<std::pair<int, DocShownLayer*>> laid;
  for (size_t i = 0; i < lies.size(); ++i)
    if (runOf[i] >= 0) laid.emplace_back(lies[i].layer, lies[i].shown);
  doc_layers_read(d, laid);
}

}  // namespace motolii

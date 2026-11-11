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
#include "document/match/match_image.h"
#include "document/match/match_light.h"
#include "document/match/match_look.h"
#include "document/match/match_models.h"
#include "document/match/match_shape.h"
#include "document/match/match_text.h"
#include "document/match/match_video.h"
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

// Reads what the layer is: its kind, file, blend mode and built-in shape, and
// the blend mode the GPU is given.
void layer_words(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  build.kind = build.word("kind");
  build.file = build.word("file");
  build.laid = build.word("blend");
  build.shape = build.word("shape");
  const std::string& laid = build.laid;
  // A layer with effect files of its own is drawn alone as normal. Its blend
  // mode is applied once the effects are on (screen_fx.h).
  const bool effected = doc_fx_files(doc_fx_steps(d, layer));
  // lay is the blend mode for the GPU, or null when the layer is drawn as
  // normal. That is the case with effects, with no blend mode, or with a mode
  // that reads the pixels underneath, which flat.mat mixes itself.
  build.lay =
      effected || laid.empty() || laid == "normal" || doc_blend_way(laid)
          ? nullptr
          : laid.c_str();
}

// Returns true when the layer has an effect file that cannot be built. Such a
// layer is not made: d.error then holds the reason.
bool effect_file_refuses(Rebuild& rebuild, LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const bool fxOk = build.fxOk;
  const std::string& why = build.why;
  const std::string &kind = build.kind, &file = build.file,
                    &shape = build.shape;
  bool& all = rebuild.all;
  // An effect file that cannot be built refuses the layer of any kind, as an
  // image's own file is refused.
  if (!fxOk && doc_fx_files(doc_fx_steps(d, layer))) {
    d.error = why + ": the " + kind + " " +
              std::filesystem::path(file + shape).filename().string() +
              " could not be made";
    all = false;
    return true;
  }
  return false;
}

// Keeps the units the layer is made in, and for a flat layer how it is placed.
void layer_units_and_space(LayerBuild& build) {
  const std::string& kind = build.kind;
  DocShownLayer& made = build.made;
  const double units = build.units;
  made.units = units;
  if (doc_among("video image text shape", kind))
    made.space = build.word("space") == "2.5d" ? 25
                 : build.word("space") == "3d" ? 3
                                                       : 2;
}

// Builds what the layer is on the stage, as its kind says. When nothing can be
// built, `why` of the layer says why.
void build_by_kind(LayerBuild& build) {
  const std::string &kind = build.kind, &file = build.file,
                    &shape = build.shape;
  DocShownLayer& made = build.made;
  std::string& why = build.why;
  // A behaviour and a camera draw nothing. A behaviour changes how the values
  // of other layers move. A camera is the viewpoint of the rest.
  if (kind == "behaviour")
    made.behaviour = true;
  else if (kind == "camera")
    made.camera = true;
  else if (kind == "light")
    match_light(build);
  else if (shape.empty() && !std::filesystem::is_regular_file(file))
    why = "there is no such file";
  else if (kind == "video")
    match_video(build);
  else if (kind == "image")
    match_image(build);
  else if (kind == "text")
    match_text(build);
  else if (kind == "shape")
    match_shape(build);
  else if (kind == "solid")
    match_model(build);
  else
    why = std::string("its kind is one of: ") + doc_kinds;
}

// Returns false when nothing was made of the layer: d.error then holds the
// reason and the layer is left out.
bool layer_made(Rebuild& rebuild, LayerBuild& build) {
  Doc& d = build.d;
  const DocShownLayer& made = build.made;
  const std::string& why = build.why;
  const std::string &kind = build.kind, &file = build.file,
                    &shape = build.shape;
  bool& all = rebuild.all;
  // A level at a cross, or at a drawing it lacks, shows nothing but is kept
  // so that its next drawing is seen.
  if (made.celMove && !made.drawn) {
    if (made.cel >= 0)
      d.error = why + ": the picture " +
                std::filesystem::path(file).filename().string(),
      all = false;
  } else if (!made.video && !made.drawn && !made.solid && !made.shape &&
             !made.camera && made.light.isNull() && kind != "behaviour") {
    d.error = why + ": the " + kind + " " +
              std::filesystem::path(file + shape).filename().string() +
              " could not be made";
    all = false;
    return false;
  }
  return true;
}

// Makes a layer that is now on the stage cast and receive shadows, if it is a
// solid.
void layer_shadows(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  const DocShownLayer& made = build.made;
  // A solid layer casts shadows from lights that throw them, and receives
  // them. The grains of a point cloud are their own light.
  if ((made.solid || made.shape) && !made.grains) {
    const int group = (int)build.number("light_group", 0);
    doc_parts(
        s, d.on_stage.shown[layer],
        [group](RenderableManager& faces, RenderableManager::Instance one) {
          // Filament draws contact shadows only where the light asks for them
          // as well.
          faces.setCastShadows(one, true), faces.setReceiveShadows(one, true),
              faces.setScreenSpaceContactShadows(one, true);
          if (group > 0) faces.setLightChannel(one, (unsigned)group, true);
        });
  }
}

// Builds one layer and puts it on the stage.
void build_layer(Rebuild& rebuild, int layer, const std::string& of) {
  LayerBuild build{rebuild.d, rebuild.s, layer, DocShownLayer{of}};
  layer_words(build);
  match_fill(build);
  match_stroke(build);
  match_flat_look(build);
  if (effect_file_refuses(rebuild, build)) return;
  layer_units_and_space(build);
  build_by_kind(build);
  if (!layer_made(rebuild, build)) return;
  rebuild.d.on_stage.shown[layer] = build.made;
  layer_shadows(build);
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

void match_build_layers(Rebuild& rebuild) {
  Doc& d = rebuild.d;
  for (const auto& [layer, of] : rebuild.told) {
    if (d.on_stage.shown.count(layer)) continue;
    build_layer(rebuild, layer, of);
  }
}

}  // namespace motolii

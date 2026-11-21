#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_

// evaluate.h: doc_evaluate, which updates the stage to the document's state at
// one time, and the helpers that decide how much room a layer's effects need
// and which properties force a layer to be rebuilt.

#include <math/vec3.h>
#include <math/vec4.h>
#include <utils/Entity.h>

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "stage/render/render_stage.h"

namespace filament {
class MaterialInstance;
class Scene;
}  // namespace filament

namespace motolii {

struct Canvas2D;
struct Doc;
struct Motion;
struct Solid;
class SplatEffect;
struct Video;

// One layer as it is on the stage, and what it was made of.
struct DocShownLayer {
  std::string of;
  Video* video = nullptr;
  Canvas2D* drawn = nullptr;
  Solid* solid = nullptr;
  Mesh* shape = nullptr;
  bool in = true, clipped = false, camera = false, behaviour = false,
       grains = false;
  // A photo bakes its crop into the rectangle its file fills (edged_photo), so
  // evaluate_clipping does not cut it again with a scissor.
  bool cropPath = false;
  std::shared_ptr<SplatEffect> splatFx;
  std::string splatFxFile;
  filament::MaterialInstance* splatPlain = nullptr;
  bool splatDone = false;
  int run = -1, lies = -1;
  // sketch: a p5.js sketch's mesh and what it was last made from (see
  // sketch.h).
  bool sketch = false;
  int sketchFrame = -1;
  int sketchMade = -1;
  filament::math::float3 sketchEye{};
  std::map<int, float> sketchStrong;
  std::vector<SketchShape> sketchShapes;
  std::vector<Canvas2D*> sketchPics;
  std::vector<SketchPaint> sketchPaints;
  size_t sketchParts = 1;
  // The layer's Filament light, if it is a light. It is in every scene of the
  // stage while the light is on.
  utils::Entity light;
  // For a flat layer: points of the image per unit of the stage as it was
  // made. Its effects are counted in this unit.
  double units = 1.0;
  // How the layer is placed: 2 is a flat layer on the camera, 25 is one in
  // the world, 3 is a solid layer or a camera.
  int space = 3;
  // A text's words as made, and whether AbsentMotion's text effects change
  // them as time goes (see doc_text_shown).
  std::string words;
  bool wordsMove = false;
  // A level's drawing as made, and whether its keyframes change it as time
  // goes.
  double cel = -2;
  bool celMove = false;
  // The scene the layer is in and its channel there. If none is set, the
  // stage's own scene, where the layer was made.
  filament::Scene* scene = nullptr;
  int channel = -1;
  // A solid's own material, made by the render code. A matte cuts it.
  filament::MaterialInstance* look = nullptr;
  // A 3D layer of an After Effects image: a sheet of its own, placed where
  // the layer is.
  struct Deep {
    uint32_t id;
    Canvas2D* sheet;
    filament::math::float4 box;
  };
  std::vector<Deep> deep;
  // motion: the same file, read for its poses only. They give the position of
  // each part.
  std::shared_ptr<Motion> motion;
};

// What is on the stage now, as doc_evaluate last left it.
struct DocOnStage {
  // A layer clipped by the flat layer before it. matte: the render code's matte
  // that cuts it, its own. from: the layer whose image cuts it. look: the
  // material of the layer that the matte was told about. how: how it was last
  // cut: by transparency or by brightness, inverted or not, and how soft.
  struct Cut {
    int matte = -1, from = 0;
    const Canvas2D* by = nullptr;
    filament::Texture* tex = nullptr;
    filament::MaterialInstance* look = nullptr;
    std::string how;
  };
  std::map<int, Cut> cuts;
  // The layers as they are on the stage, and what each was made of.
  std::map<int, DocShownLayer> shown;
  // Each freehand stroke's outline drawing effects last made
  // it, together with what it was made from. See doc_evaluate.
  std::map<int, std::pair<std::string, std::string>> drawingKept;
  // The last successfully loaded duration of each video layer, in seconds of
  // display time. Kept across frames so that doc_seconds can use it when a
  // file is missing (deleted or moved after the layer was loaded).
  std::map<int, float> file_seconds;
  // The length of the project as last shown. Waves, noise and drifts go round
  // in it a whole number of times, so that an exported video loops.
  double round = 8.0;
};

// Per-copy materials, keyed by the copy's entity: the layer's material
// duplicated while its copies are colored individually.
struct DocCopyMaterials {
  // looks: of the copy itself. edges: the same for the edge, the second part
  // of a copy.
  std::map<uint32_t, filament::MaterialInstance*> looks, edges;
};

// Brings the stage to the state the document has at time `now`. This covers the
// camera and lens, layer order and depth sorting, scenes, per-layer materials
// and copies, lights, clipping and the 3D layers of imported After Effects
// compositions.
// A text layer whose words no longer fit, or a cel layer whose drawing changed,
// is rebuilt with doc_match and evaluation stops there. Nothing in the document
// is modified.
void doc_evaluate(Doc& d, double now);

// Property names that decide how a layer is built, written as a quoted list for
// use in SQL. When one of them changes, the layer is rebuilt by doc_match.
// doc_carry uses the list too.
inline const char* const doc_making =
    "'kind','file','shape','path','blend','fx','fx_off','keyed','space','begin'"
    ",'duration','speed','text','text_styles','fill','fill_media','fill_rule'"
    ",'wide','points'"
    ",'inner','round','crop_left','crop_top','crop_right','crop_bottom','bloat'"
    ",'zigzag','offset','warp','clip','stroke','stroke_width','stroke_align'"
    ",'strokes','align','copies','letter_"
    "spacing','line_spacing','italic','cap','join','heads','head_size','head_"
    "shape','head_start','dash','dash_gap','dash_offset','metallic','roughness'"
    ",'"
    "reflectance','clear_coat','clear_coat_roughness','falloff','shadows','"
    "shadow_softness','contact_shadows','sheen','anisotropy','shading','"
    "thickness','light_group','script','copy_fill','gradient','gradient_angle',"
    "'gradient_scale','gradient_spread','wrap','wrap_at','split','ior','"
    "dispersion','swim','dark','vivid','marker','mosh','mosh_with','mosh_at'";

// -- evaluation: what one call of doc_evaluate works out early and its later
// phases read. It lives for that call only. --

// The state of one layer at the evaluated time. `on` says whether the layer is
// shown now. `solid` says whether the layer takes part in depth sorting with
// other solid layers. `since` is the time in seconds since the layer started.
// `open` says whether its 3D box is open.
struct EvaluatedLayer {
  int layer;
  DocShownLayer* shown;
  bool on, solid;
  double since;
  bool open;
};

// One evaluation of the document at one time.
struct Evaluation {
  Doc& d;
  // The stage of `d`.
  Stage& s;
  // The time the document is evaluated at, in seconds.
  const double now;
  // Every layer of the document in stacking order, cameras included.
  std::vector<int> lie;
  // The state of each layer that is on the stage and is not a camera, in
  // stacking order.
  std::vector<EvaluatedLayer> lies;
  // Depth ordering. Layers that follow one another and are of one sort, flat or
  // solid, form a run. `runOf` gives for each entry of `lies` the index of its
  // run, or -1 when nothing of the layer is drawn. `sorts` gives for each run 1
  // when its layers are solid and 0 when they are flat.
  std::vector<int> runOf, sorts;
  // 1 when flat layers lie under the first solid layers.
  int base = 0;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_

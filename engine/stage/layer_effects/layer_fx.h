#ifndef MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_
#define MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_
// Per-layer effects. Each layer is drawn alone into an offscreen texture
// (post-processing off), effects chain on it, and the result is mapped onto a
// sheet at the layer's position (effected.mat).
#include <filament/Camera.h>
#include <filament/MaterialInstance.h>
#include <filament/Scene.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <utils/Entity.h>

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "stage/canvas/canvas_cache.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Rebuilds the effect chain from `files`. No-op if unchanged. Fills st.steps
// (0 = GPU effect, 'a' = AviUtl2). Sets st.readsBehind and st.wide.
void thing_effects(Stage& s, ScreenStack& st, const std::string& files);
// Creates offscreen textures sized to the view. Called before the frame.
void thing_fx_textures(Stage& s, ScreenStack& st, filament::View* v);
// The layer's image after effects (or its own image if none).
inline filament::Texture* thing_fx_seen(const ScreenStack& st) {
  return st.steps.empty() ? st.shot : st.between[0];
}
struct ThingFx;
// Draws the layer alone, runs effects through alternating textures.
// sRGB before effects, linear after. When `owner` is supplied and eligible,
// skips re-rendering static unchanged layers whose cached output is still
// valid.
void thing_effects_draw(Stage& s, ScreenStack& st, filament::View* v,
                        const ScreenNumbers& numbers,
                        const ScreenTextures& textures = nullptr,
                        ThingFx* owner = nullptr);

// A layer's effect state: its own view, effect chain, and result sheet.
struct ThingFx {
  ScreenStack st;
  filament::View* view = nullptr;
  Mesh* sheet = nullptr;
  filament::MaterialInstance* look = nullptr;
  // Blending variant of effected.mat. Empty = normal.
  std::string lay;
  // The group's scene, or null for the stage's scene.
  filament::Scene* in = nullptr;
  // Copies the stage camera's projection each frame.
  utils::Entity eye;
  filament::Camera* camera = nullptr;
  double box[4] = {0, 0, 0, 0};
  // Extents left, right, down, up along the layer's face, in world units.
  double sides[4] = {0, 0, 0, 0};
  // True: image filmed square to the layer's face. False: screen-aligned.
  bool world = false;
  // Center, width, height (layer points), points per world unit.
  double own[5] = {0, 0, 0, 0, 0};
  // Per-frame cached values populated in `s.aim` under `d.lock` so `numbers`
  // avoids repeated mutex acquisitions and `doc_fx_frame` recomputations.
  double cachedLayerRect[4] = {0, 0, 0, 0};
  bool hasCachedLayerRect = false;
  double cachedClipTime = 0.0, cachedClipLength = 0.0;
  // Static-layer output cache state (skips re-rendering unchanged layers).
  bool cacheEligible = false;
  bool cacheValid = false;
  uint64_t cacheBaseKey = 0;
  uint64_t cacheLastKey = 0;
  uint32_t cacheW = 0, cacheH = 0;
  // Placement without scale; the camera films from here.
  filament::math::mat4 square;
  // Solid: stays in the world, shows the image on its faces.
  bool shell = false;
  // Original face materials, saved while the effect image is on them.
  std::vector<filament::MaterialInstance*> looks;
  // Solid from solids/*.js. solidSaid = last build input, cover = alpha
  // readback.
  std::string solidFile, solidSaid, solidAs;
  // Current parameter values and the layer's size in its own units.
  std::map<std::string, double> parameters;
  std::map<std::string, std::string> words;
  filament::math::float2 size{1.f};
  Mesh* solid = nullptr;
  filament::MaterialInstance* solidLook = nullptr;
  bool solidRepeat = false;
  // Points file (.wgsl compute shader), its current parameters.
  std::string pointsFile;
  std::vector<float> pointsKnobs;
  struct PointsFx* points = nullptr;
  // Alpha sampled from the layer's image: w×h grid, times = readback count.
  struct Cover {
    std::vector<uint8_t> a;
    int w = 0, h = 0, times = 0;
  };
  std::shared_ptr<Cover> cover = std::make_shared<Cover>();
};

// Moves sheet and solid into `into` (null = stage's scene).
void thing_fx_into(Stage& s, ThingFx& e, filament::Scene* into);
// Creates view, sheet and material if missing or if lay/world/shell changed.
ThingFx& thing_fx_built(Stage& s, ThingFx& e, const std::string& lay = "",
                        bool world = false, bool shell = false);

// Tears down the layer's effect resources.
void thing_fx_off(Stage& s, ThingFx& e);

// Pixels per stage point. Editor: desk.scale. Export: stage view.
double thing_fx_ppp(const Stage& s);

// The stage region the effect image covers (LTRB). Editor: full panel
// (off-stage included). Export: comp only.
void thing_fx_work(const Stage& s, double* work);

// Aims the layer's camera at `said` (LTRB stage points). Narrows projection
// so the box fills the image. Sheet placed via effected.mat's `place` param.
void thing_fx_aim(Stage& s, ThingFx& e, const double* said);

// Orthographic camera on the layer's z axis, so the image is stable under
// rotation. 2048px along the longer side, or `dense` px/unit. `room` adds
// margin; `sides` overrides extents.
void thing_fx_face(Stage& s, ThingFx& e, const filament::math::mat4& place,
                   filament::math::float2 half, double room = 0.0,
                   double dense = 0.0, const double* sides = nullptr);

// Stands a flat layer's image in the world
// with masks, effects and transformations. The image is filmed square to the
// layer's face and covers as much of the stage as e.sides says, plus a margin
// that the effects measure by: 128 stage points, as BAKE_MARGIN in
// sashimono-edit. The margin and extents are the same wherever the camera is,
// so what the effects produce stays attached to the layer. When the layer is
// near the camera, the image has as many pixels as the camera sees of it, so it
// stays sharp. `seen` is the number of stage points per world unit where the
// layer is. The sheet lies where the layer lies.
void thing_fx_stand(Stage& s, ThingFx& e, const filament::math::mat4& place,
                    filament::math::float2 half, double seen);

// Rebuilds the layer's solid when what it is made of has changed: the shape
// file, parameters, size or coverage. The solid goes in the stage's scene,
// casts and receives shadows, and is unlit when its Lit parameter is off. A
// solid that already exists only gets its new vertices through reshape. Within
// a frame, when `inFrame` is set, only that happens: a material created then is
// not ready until the next frame, because Filament prepares every material as a
// frame begins, in FEngine::prepare. So a new solid waits for the next frame.
void thing_fx_solid(Stage& s, ThingFx& e, bool inFrame);

// Returns true if the file moves the points of a solid: a .wgsl file with a
// compute shader (`@compute`).
bool points_is(const std::string& file);
// Runs the layer's points file on its solid: every point of the solid is
// handed to the file's compute shader, and where the shader puts it is where
// the solid is drawn this frame. The solid's normals stay as its shape script
// made them unless the file writes them, as three.js leaves them when a
// material moves points and gives no normals. The file is a whole WGSL compute
// shader with these bindings in group 0 (compute_interop.h: slot i is binding 2
// * i):
//   0  uniform: a struct of f32, `time` first (seconds), then one for each
//      `// --track` or `// --check` line of the file's head, in that order
//   2  storage, array<f32>: the points as the shape made them, x y z each
//   4  storage, array<f32>: the texture coordinates, u v each
//   6  storage, array<f32>: the points to draw, x y z each, which it writes
//   8  storage, array<f32>: the normals as the shape made them, x y z each
//  10  storage, array<f32>: the normals to draw, x y z each, which it may
//      write; a point whose normal it leaves at zero keeps the shape's
//  12  storage, array<f32>: the tangents as the shape made them, x y z w each
// It is run with 64 points to a workgroup, so its entry is
// `@compute @workgroup_size(64)` and point i is global_invocation_id.x. The
// buffers may be longer than the solid has points.
void thing_fx_points(Stage& s, ThingFx& e);

// Reads back the coverage (alpha) of the layer's image, for a shape built from
// its outline. Uses Filament's Renderer::readPixels, whose callback runs on a
// later frame; the shape is built from the result then. Samples every so many
// pixels, at most `cells` along the longer side.
void thing_fx_cover(Stage& s, ThingFx& e, int cells);

}  // namespace motolii

#endif  // MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_

#ifndef MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_
#define MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_
// Per-layer effects for the stage. A layer with effects is drawn alone into an
// offscreen texture, in a view of its own with post-processing off, as in
// Filament's samples/rendertarget.cpp. The effects (.wgsl and ISF files,
// including ThorVG's own) then run on that texture one after another, as in
// After Effects where a layer's image comes first and its effects after. The
// result is laid on a sheet where the layer sits; see effected.mat and
// google/filament issues #1818, #7676 and #3784. These are the functions of the
// earlier screen_fx.h, minus the code that laid the image over the whole
// screen.
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

// Rebuilds the effect chain of a layer from `files`, the effect files in order.
// Does nothing if st.files already equals `files`. Fills st.fx with the GPU
// effects and st.aviutl with the AviUtl2 script runners, reusing a runner
// already open for the same file. st.steps gets one code per step: 'a' for an
// AviUtl2 script, a ThorVG letter, or 0 for the next entry of st.fx. Also sets
// st.readsBehind and st.wide.
void thing_effects(Stage& s, ScreenStack& st, const std::string& files);
// Runs one of ThorVG's own effects as one step of the chain. `k` is the
// effect's letter. The input is the GPU texture `from`, w by h pixels. The
// output goes to the texture with index `into` (0 or 1) of the two alternating
// textures. The input is put in a ThorVG scene, the effect is applied to the
// scene, and the drawing runs on the driver thread in order with Filament's
// drawing. Lengths in `fx` are stage points, `ppp` pixels each.
void thing_thor(Stage& s, ScreenStack& st, char k, void* from, int into,
                uint32_t w, uint32_t h, const Canvas2DFx& fx, float ppp);
// Creates or recreates the offscreen textures and render targets of a layer's
// effects, sized to the view's viewport. Called before the frame, because the
// material that shows a texture is given it later by thing_fx_seen.
void thing_fx_textures(Stage& s, ScreenStack& st, filament::View* v);
// Returns the texture that holds the layer's image after its effects: the last
// one drawn into, or the layer's own image if it has none. The sheet or solid
// shows this texture. The last step converts back to linear light; see
// thing_effects_draw.
inline filament::Texture* thing_fx_seen(const ScreenStack& st) {
  return st.steps.empty() ? st.shot : st.between[st.steps.size() % 2];
}
// Draws the layer alone into st.shot, then runs its effects one after another
// through the two alternating textures st.between. The image is converted to
// sRGB before the effects and back to linear light after. The result is left in
// st.seen. `thorFx` supplies the values of ThorVG effects and is called only
// when the chain has one. `textures` returns the extra textures an effect asks
// for by name.
void thing_effects_draw(Stage& s, ScreenStack& st, filament::View* v,
                        const ScreenNumbers& numbers,
                        const std::function<Canvas2DFx()>& thorFx = nullptr,
                        const ScreenTextures& textures = nullptr);

// State of a layer that has effects of its own: the view it is drawn alone in,
// its effect chain, and the sheet (a quad) that carries the result into the
// stage's view.
struct ThingFx {
  ScreenStack st;
  filament::View* view = nullptr;
  Mesh* sheet = nullptr;
  filament::MaterialInstance* look = nullptr;
  // How the sheet blends with what is behind it: one of Filament's blending
  // variants of effected.mat. Empty means normal, over the background.
  std::string lay;
  // The scene the sheet lies in: the scene of a group that has effects of its
  // own, or null for the stage's scene.
  filament::Scene* in = nullptr;
  // Entity of this layer's own camera. It is given the stage's camera each
  // frame, as the offscreen camera in samples/rendertarget.cpp is.
  utils::Entity eye;
  filament::Camera* camera = nullptr;
  // Where the layer is seen, in stage points: left, top, right, bottom.
  double box[4] = {0, 0, 0, 0};
  // Set by thing_fx_stand. How far the stage extends from the layer along its
  // own face, in the order left, right, down, up, in world units.
  // AbsentMotion's effects are cut by the scene; see EffectRuntime::draw in
  // engine/third_party/AbsentMotion/app/src/main/cpp/effects.cpp.
  double sides[4] = {0, 0, 0, 0};
  // True if the sheet stands where the layer is in the world and the image is
  // filmed square to the layer; see thing_fx_stand. False if the sheet is laid
  // on the screen.
  bool world = false;
  // Set by thing_fx_stand. Where the layer itself lies in its image: its
  // center, then its width and height, all in the layer's points, then the
  // points per world unit.
  double own[5] = {0, 0, 0, 0, 0};
  // Set by thing_fx_stand. The layer's own placement without scale, which is
  // where the image is filmed from.
  filament::math::mat4 square;
  // True for a solid. It stays in the world and shows the image itself, using
  // `look` on its faces while the stage is drawn; see effected_solid.mat.
  bool shell = false;
  // The faces' own materials, kept while this layer's image is on them; see
  // doc_layer_shell.
  std::vector<filament::MaterialInstance*> looks;
  // The image on a solid's faces, used when the layer's effects name a shape
  // file in solids/*.js. solidFile is the shape file, solidSaid is what the
  // solid was last built from, solidAs is the material of solidLook, and solid
  // is the mesh. For a shape built from the layer's outline, `cover` holds the
  // coverage as last read back.
  std::string solidFile, solidSaid, solidAs;
  // The shape's parameters as set now, their text values, and the layer's size
  // in its own units.
  std::map<std::string, double> parameters;
  std::map<std::string, std::string> words;
  filament::math::float2 size{1.f};
  Mesh* solid = nullptr;
  filament::MaterialInstance* solidLook = nullptr;
  bool solidRepeat = false;
  // Coverage (alpha) sampled from the layer's image: a grid of `w` by `h` cells
  // in `a`, and the number of times it has been read back.
  struct Cover {
    std::vector<uint8_t> a;
    int w = 0, h = 0, times = 0;
  };
  std::shared_ptr<Cover> cover = std::make_shared<Cover>();
};

// Moves the layer's sheet and solid into scene `into`, a group's scene or, if
// null, the stage's scene. The renderer adds and removes renderables only in
// the stage's scene.
void thing_fx_into(Stage& s, ThingFx& e, filament::Scene* into);
// Creates the layer's view, sheet and material if they are missing or if `lay`,
// `world` or `shell` changed, and returns `e`. The sheet is a quad that covers
// the whole image, as in samples/materials/image.mat; its corners are the
// screen's corners.
ThingFx& thing_fx_built(Stage& s, ThingFx& e, const std::string& lay = "",
                        bool world = false, bool shell = false);

// Removes everything the layer created in the engine and resets `e`.
void thing_fx_off(Stage& s, ThingFx& e);

// Aims the layer's camera at `said`, the box where the layer is seen: left,
// top, right, bottom in stage points. The camera is given the stage's
// projection and pose each frame, as the offscreen camera in
// samples/rendertarget.cpp is (setCustomProjection, setModelMatrix). The
// projection is narrowed to the box so that the box is the whole image. This
// matches After Effects, where a layer's effects work on the layer's own image,
// and an ISF effect's center is its middle. The image has as many pixels as the
// box covers on the stage's view. The sheet is laid on the box through the
// `place` parameter of effected.mat.
void thing_fx_aim(Stage& s, ThingFx& e, const double* said);

// Aims the layer's camera square at the layer's own face, for a solid's faces,
// so that the image is the same however the solid is turned. The camera is
// orthographic, on the layer's z axis, as wide and high as the layer
// (Filament's Camera::setProjection with ORTHO), and is updated each frame as
// in samples/rendertarget.cpp. The image is 2048 pixels along its longer side,
// or `dense` pixels per world unit if that is given, with `room` added around
// the layer. `sides`, if given, are the extents left, right, down, up instead
// of the layer's size.
void thing_fx_face(Stage& s, ThingFx& e, const filament::math::mat4& place,
                   filament::math::float2 half, double room = 0.0,
                   double dense = 0.0, const double* sides = nullptr);

// Stands a flat layer's image in the world, as After Effects does for a layer
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

// Reads back the coverage (alpha) of the layer's image, for a shape built from
// its outline. Uses Filament's Renderer::readPixels, whose callback runs on a
// later frame; the shape is built from the result then. Samples every so many
// pixels, at most `cells` along the longer side.
void thing_fx_cover(Stage& s, ThingFx& e, int cells);

#endif  // MOTOLII_STAGE_LAYER_EFFECTS_LAYER_FX_H_

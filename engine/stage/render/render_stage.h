#ifndef MOTOLII_STAGE_RENDER_RENDER_STAGE_H_
#define MOTOLII_STAGE_RENDER_RENDER_STAGE_H_
// Mesh and Stage types, Filament engine lifecycle, and mesh management.
#include <backend/BufferDescriptor.h>
#include <filament/BufferObject.h>
#include <filament/Camera.h>
#include <filament/Engine.h>
#include <filament/IndexBuffer.h>
#include <filament/InstanceBuffer.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderTarget.h>
#include <filament/Renderer.h>
#include <filament/Scene.h>
#include <filament/SwapChain.h>
#include <filament/Texture.h>
#include <filament/VertexBuffer.h>
#include <filament/View.h>
#include <math/mat4.h>
#include <math/quat.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <utils/Entity.h>

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace interop {
struct Screen;
}  // namespace interop

namespace motolii {

inline constexpr float TAU = 6.2831853f;

// A shape that a p5.js sketch draws, in the form the sketch has it. See
// document/evaluate/sketch.h.
struct SketchShape {
  std::vector<filament::math::float3> pos, nrm;
  std::vector<filament::math::float2> uv;
  std::vector<uint32_t> idx, edges;
};
// A value that the sketch passes to its shader(), identified by name.
struct SketchTold {
  std::string name, type;
  int count = 1, size = 1;
};
// The material made for a sketch's shader, the values it takes, and its
// material instances.
struct SketchPaint {
  filament::Material* material = nullptr;
  std::vector<SketchTold> told;
  int size = 0;
  std::vector<filament::MaterialInstance*> looks;
};
// The points and triangles of one mesh, and the GPU buffers they were last
// uploaded to.
struct Mesh {
  std::vector<filament::math::float3> pos, nrm;
  std::vector<filament::math::float2> uv;
  std::vector<uint32_t> idx;
  std::vector<filament::math::quatf> quat;
  // Per-point colours for sketch.mat. Most meshes have none.
  std::vector<filament::math::float4> color;
  // A second set of texture coordinates, where each point reads its image.
  std::vector<filament::math::float2> uv1;
  // The buffers as last put in the scene. See add_parts and reshape.
  filament::VertexBuffer* vb = nullptr;
  filament::IndexBuffer* ib = nullptr;
  // How many points and indices the buffers hold. The buffers are written again
  // in place while the mesh fits.
  uint32_t vbRoom = 0, ibRoom = 0;
  // True when the points, tangents and texture coordinates each have a buffer
  // object of their own (`object`), so that a compute shader can write the
  // points on the GPU; see layer_points.cpp. Such a mesh has no colours.
  bool objects = false;
  filament::BufferObject* object[3] = {nullptr, nullptr, nullptr};
};

// Gives a sheet depth: its four corners are duplicated in front of it and
// behind it, forming a box that its image is read through. See deep.glsl.
void sheet_deep(Mesh* m, float deep);

// Returns a descriptor holding a copy of `bytes` bytes from `from`. Filament
// reads the buffer later on its own thread and frees it through the callback,
// so the mesh may be rebuilt meanwhile.
filament::backend::BufferDescriptor copied(const void* from, size_t bytes);

// The state of one Filament engine and the stage it draws: scene, views,
// cameras, helper images, and the entities put on it.
struct Stage {
  int w, h;
  filament::Engine* engine;
  filament::Renderer* renderer;
  filament::Scene* scene;
  filament::View* view;
  filament::SwapChain* swap;
  filament::Camera* camera;
  // The project's camera (Camera View). Separate from `camera` (the working
  // orbital camera). 2D layers follow it; mattes are taken through it.
  filament::Camera* film;
  // Owns `film`; also the parent for 2D layers in the scene graph.
  utils::Entity filmEntity;
  // The free camera, once it has been requested.
  filament::Camera* god = nullptr;
  // Scene without glass (layer 2), drawn into `behind` for glass refraction.
  filament::View* view_behind;
  // Depth of `behind` (see doc_layers_read).
  filament::Texture* behindDepth = nullptr;
  filament::Texture* behind;
  // Whether anything reads `behind`. Until then it is not drawn.
  bool behindRead = false;
  // Run once per frame after drawing (e.g. restore material instances).
  std::vector<std::function<void()>> after;
  // Whether a layer effect reads `behind`. Causes it to be drawn before
  // effects.
  bool backdropRead = false;
  // Glass far faces (layer 8), recording face direction (far_side.mat).
  filament::View* view_through = nullptr;
  filament::Texture* through = nullptr;
  // Far-face depth; thick_glass.mat measures glass thickness with it.
  filament::Texture* through_depth = nullptr;
  // The stage's time in seconds.
  double now = 0.0;
  // Project frame rate. 0 = continuous.
  double frames = 0.0;
  // True: real-time playback. False: frame-accurate stepping.
  bool by_clock = false;
  // Deferred video work, run once the project lock is released (motolii.mm).
  // Null = execute immediately.
  std::vector<std::function<void()>>* later = nullptr;
  // A layer's own sound.
  // file: the audio file.
  // from, to: the part of the file used, in seconds of the file.
  // speed: how fast it plays.
  // into: how far into that part the sound is when it starts.
  // on: the stage time in seconds when it starts.
  // lasts: how long it plays in seconds. A negative value means to the end.
  // gain: volume factor. 1 leaves the volume of the file unchanged.
  // loud: keyframed loudness, one value for each 1/30 s from the start.
  struct Sound {
    std::string file;
    double from, to, speed, into, on, lasts;
    double gain = 1.0;
    std::vector<float> loud = {};
  };
  // Active sounds by layer. Queried during export.
  std::map<const void*, std::function<Sound()>> sounding;
  // Auto-advancing callbacks (videos, images), keyed by layer.
  std::map<const void*, std::function<void(double)>> playing;
  // Callbacks that add their own output after each line of `clock`.
  std::vector<std::function<void()>> said_after;
  // One entity on the stage. matte: lives in its own scene for matte rendering.
  // many: Filament instancing buffer (move updates all at once).
  struct Renderable {
    utils::Entity thing;
    const Mesh* of;
    int nth;
    filament::math::mat4f place;
    bool matte = false;
    filament::InstanceBuffer* many = nullptr;
    int count = 1;
  };
  // A matte with its own scene/view/camera. scene == null means the slot is
  // free (release_matte keeps it so indices stay valid). eyeOwned: null when
  // using the shared camera.
  struct Matte {
    filament::Scene* scene;
    filament::View* view;
    filament::Texture* frameTexture;
    bool soft;
    filament::Camera* eye;
    utils::Entity on;
    filament::math::mat4f onPlace;
    utils::Entity eyeOwned;
  };
  // The mattes, drawn before everything else. Null-scene slots are reusable.
  std::vector<Matte> mattes;
  // Matte→material binding. use: 1 inside, -1 outside. soft: blur level.
  struct Cut {
    filament::MaterialInstance* look;
    int slot, matte;
    float use, soft;
  };
  // All matte bindings. Camera matrices set before each frame.
  std::vector<Cut> cuts;
  // A white point: the matte of a layer that nothing cuts.
  filament::Texture* white = nullptr;
  // Materials made once per stage engine.
  std::map<std::string, filament::Material*> materials;
  // screen_place's copy shader. One per stage; not Filament-owned.
  interop::Screen* place_copy = nullptr;
  // screen_tone's shaders: index 0 = sRGB→linear, 1 = linear→sRGB.
  interop::Screen* place_tone[2] = {nullptr, nullptr};
  // canvas_edge's three processing screens: seeds, flood, length.
  std::array<interop::Screen*, 3> edge_screens = {nullptr, nullptr, nullptr};
  // glTF asset/texture loaders (gltf_model.h).
  void* solids = nullptr;
  void* solidTextures = nullptr;
  // All entities on stage. `move` repositions them.
  std::vector<Renderable> renderables;
  // Preview panel state: viewport (w/h/x/y/scale) and selection/hover marks.
  // point: panel pixels per screen point. 0×0 = no panel.
  struct {
    uint32_t w = 0, h = 0;
    double x = 0, y = 0, scale = 1, point = 2;
    filament::math::mat4 was, wasCulled;
    bool picked = false, hovered = false, rotateHandle = true;
    double pick[8] = {}, hover[8] = {};
  } desk;
  // Post-process pass (screen_fx.h).
  std::function<void()> over;
  // One-shot pre-frame work, keyed by owner (e.g. edge distance,
  // canvas_edge.h).
  std::map<const void*, std::function<void()>> once;
  // Per-layer effect passes (layer_fx.h), drawn before the main view.
  std::vector<std::function<void()>> before;
  // Run before each frame to set effect images and material parameters
  // (must precede FRenderer::beginFrame).
  std::vector<std::function<void()>> aim;
  // Run last in the frame (e.g. blit stage to preview panel, live.h).
  std::function<void()> lastly;
  // Render target texture. Null = screen.
  filament::Texture* drawTarget = nullptr;
  // Final output. Null = screen.
  filament::RenderTarget* out = nullptr;
  // Incremented when a bent outline moves. The render loop re-snapshots on
  // change so the selection box follows path operator drags live.
  // Driver→render thread; a stale read just delays by one frame.
  uint64_t bentChanges = 0;
  // Set when a bend overflows its texture. The render loop rebuilds once to
  // grow the sheet.
  bool bentOverflow = false;
};

// Creates the engine, scene, views and camera of a stage w by h pixels.
Stage open_stage(int w, int h);

// Destroys the per-Stage Filament resources (renderer, scene, views, cameras,
// textures) so the shared engine can outlive the stage.
void close_stage(Stage& s);

// Switches viewports between the preview panel (on=true) and the stage
// (on=false). Matte cameras are left as they are.
void desk_lay(Stage& s, bool on);

// Sets the environment light that the glass mirrors and is lit by: one of the
// studios that come with Filament, converted to a .ktx by cmgen. Returns false
// if the file is missing or has no spherical harmonics.
bool room(Stage& s, const char* ktx, float intensity);

// Returns a 1x1 white image, created on first use.
filament::Texture* white_point(Stage& s);

// Material filename for a blend mode. lay: nullptr=normal, "add"/"multiply"/
// "screen". lit: lit variant. wear: named material with its own blend.
std::string flat_laid(const char* lay, bool lit = false,
                      const std::string& wear = "");

// Returns the cached material for `filamat`, or nullptr if missing.
filament::Material* material(Stage& s, const char* filamat);
// Creates a placeholder mesh of one triangle for a sketch. It has no real shape
// yet, because document/evaluate/sketch.h makes it again each frame.
Mesh* sketch_mesh();
// Adds mesh `m` at each `places` transform, returning per-part material
// instances. layer: Filament mask (2=skip behind, 8=glass far faces only).
// order: lower = drawn first. copies: per-place instance count.
std::vector<filament::MaterialInstance*> add_parts(
    Stage& s, Mesh* m, const char* filamat,
    std::vector<filament::math::mat4f> places, std::vector<uint32_t> ends,
    uint8_t layer = 1, bool shadows = false, int copies = 1, int order = 4,
    bool together = false);
// Like add_parts for a mesh of one part. Returns its material instance, or
// nullptr on failure.
filament::MaterialInstance* add(
    Stage& s, Mesh* m, const char* filamat,
    std::vector<filament::math::mat4f> places = {filament::math::mat4f{}},
    uint8_t layer = 1, bool shadows = false, int copies = 1, int order = 4,
    bool together = false);

// Adds more parts to mesh `m`, all using `look`. The entity keeps its scene
// position (Filament rebuilds the renderable in place).
void more_parts(Stage& s, Mesh* m, size_t parts,
                filament::MaterialInstance* look);
// Replaces mesh `m`'s geometry. Reuses existing buffers when they fit;
// otherwise allocates 25% larger ones. Old buffers are kept until no frame uses
// them.
void reshape(Stage& s, Mesh* m, const std::vector<uint32_t>& ends);

// AABB of `pos`. Empty → {zero, zero} (Filament requires a bounding box).
std::pair<filament::math::float3, filament::math::float3> pos_bounds(
    const std::vector<filament::math::float3>& pos);

}  // namespace motolii

#endif  // MOTOLII_STAGE_RENDER_RENDER_STAGE_H_

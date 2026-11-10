#ifndef MOTOLII_STAGE_RENDER_RENDER_STAGE_H_
#define MOTOLII_STAGE_RENDER_RENDER_STAGE_H_
// The stage: the mesh and Stage types, creating a Filament engine and stage, and adding, reshaping
// and making meshes on it.
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>

#include <backend/BufferDescriptor.h>
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

inline constexpr float TAU = 6.2831853f;

// A shape that a p5.js sketch draws, in the form the sketch has it. See document/evaluate/sketch.h.
struct SketchShape { std::vector<filament::math::float3> pos, nrm; std::vector<filament::math::float2> uv; std::vector<uint32_t> idx, edges; };
// A value that the sketch passes to its shader(), identified by name.
struct SketchTold { std::string name, type; int count = 1, size = 1; };
// The material made for a sketch's shader, the values it takes, and its material instances.
struct SketchPaint { filament::Material* material = nullptr; std::vector<SketchTold> told; int size = 0; std::vector<filament::MaterialInstance*> looks; };
// The points and triangles of one mesh, and the GPU buffers they were last uploaded to.
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
    // How many points and indices the buffers hold. The buffers are written again in place while
    // the mesh fits.
    uint32_t vbRoom = 0, ibRoom = 0;
};

// Gives a sheet depth: its four corners are duplicated in front of it and behind it, forming a box
// that its image is read through. See deep.glsl.
void sheet_deep(Mesh* m, float deep);

// Returns a descriptor holding a copy of `bytes` bytes from `from`. Filament reads the buffer later
// on its own thread and frees it through the callback, so the mesh may be rebuilt meanwhile.
filament::backend::BufferDescriptor copied(const void* from, size_t bytes);

// Reads the whole file at `path`. Returns an empty vector if it cannot be read.
std::vector<uint8_t> load_file(const char* path);

// The state of one Filament engine and the stage it draws: scene, views, cameras, helper images,
// and the entities put on it.
struct Stage {
    int w, h;
    filament::Engine* engine;
    filament::Renderer* renderer;
    filament::Scene* scene;
    filament::View* view;
    filament::SwapChain* swap;
    // The camera that views the stage. Every image of the stage is taken by it.
    filament::Camera* camera;
    // The project's own camera. It is the same as `camera` unless a free camera is in use, see
    // god_view. Mattes in the project camera's image are taken by it.
    filament::Camera* film;
    // The free camera, once it has been requested.
    filament::Camera* god = nullptr;
    // The same scene without the glass (layer 2), drawn first into `behind`. It is what a glass
    // block shows.
    filament::View* view_behind;
    // The depth of `behind`. It is drawn into an image of its own for a layer that reads what is
    // under it, see doc_layers_read.
    filament::Texture* behindDepth = nullptr;
    filament::Texture* behind;
    // Whether anything reads `behind`, such as glass or paper. Until then it is not drawn.
    bool behindRead = false;
    // Run once the image is drawn, for example to put a solid's own material instances back. See
    // doc_layer_shell.
    std::vector<std::function<void()>> after;
    // Whether a layer's effect reads `behind`, as the backdrop of AbsentMotion does. Then it is
    // also drawn before the layers' effects.
    bool backdropRead = false;
    // The glass's far faces alone (layer 8), drawn second into `through`. It records which way they
    // face, see far_side.mat.
    filament::View* view_through = nullptr;
    filament::Texture* through = nullptr;
    // How far away those far faces are. The near faces in thick_glass.mat measure the glass with
    // it.
    filament::Texture* through_depth = nullptr;
    // The stage's time in seconds.
    double now = 0.0;
    // Frames per second at which the stage's time is seen, which is the project's frame rate. 0
    // means as smooth as it is drawn.
    double frames = 0.0;
    // True: played as the clock goes, and nothing is waited for. False: frame by frame, each one
    // exact.
    bool by_clock = false;
    // For a live stage: work that a point in time asks of its videos, kept to run once the project
    // is released, see motolii.mm. This way videos put back to their start do not hold the app's
    // reads of the project. If null, the work is done at once.
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
    struct Sound { std::string file; double from, to, speed, into, on, lasts; double gain = 1.0; std::vector<float> loud = {}; };
    // Sounds that are heard, each under its own layer. Asked when a video is exported.
    std::map<const void*, std::function<Sound()>> sounding;
    // Callbacks that advance by themselves as the stage's time does, such as videos and images,
    // each under its own layer.
    std::map<const void*, std::function<void(double)>> playing;
    // Callbacks that add their own output after each line of `clock`.
    std::vector<std::function<void()>> said_after;
    // One Filament entity put on the stage.
    // thing: the entity. of: the mesh it was made from. nth: the index of the place of that mesh.
    //   place: its transform.
    // matte: true for the shape that a matte is cut by, which lives in that matte's own scene.
    // many: draws all its places in one go with Filament's instancing, each place being an instance
    //   of the one entity. `move` updates them all at once.
    // count: the number of instances.
    struct Renderable { utils::Entity thing; const Mesh* of; int nth; filament::math::mat4f place; bool matte = false;
                  filament::InstanceBuffer* many = nullptr; int count = 1; };
    // A matte: its own scene, view and image, the camera that takes it, and the entity it rides on
    // with that entity's transform. soft: whether some layer reads it blurred.
    struct Matte { filament::Scene* scene; filament::View* view; filament::Texture* frameTexture; bool soft; filament::Camera* eye; utils::Entity on; filament::math::mat4f onPlace; };
    // The mattes. Each is an image taken by its own camera and drawn before everything else, see
    // matte.
    std::vector<Matte> mattes;
    // Records that one material instance reads one matte. slot: which matte slot of the instance.
    // matte: the index into `mattes`. use: 1 for inside, -1 for outside. soft: the blur level.
    struct Cut { filament::MaterialInstance* look; int slot, matte; float use, soft; };
    // Which material instance reads which matte, see matted. The matte's camera matrix is set
    // before every frame.
    std::vector<Cut> cuts;
    // A white point: the matte of a layer that nothing cuts.
    filament::Texture* white = nullptr;
    // Resources made once for this stage's engine and kept. A stage opened after another in the
    // same program has its own.
    // Each material file, read and built once.
    std::map<std::string, filament::Material*> materials;
    // Filament's reader of 3D files and its reader of their images, see gltf_model.h.
    void* solids = nullptr; void* solidTextures = nullptr;
    // Every entity put on the stage: which mesh it was made from and at which of that mesh's
    // places. `move` repositions them.
    std::vector<Renderable> renderables;
    // The app's preview panel.
    // w, h: the size in pixels of the whole stage pane of the editing window. 0 means none.
    // The image there is the same as on the stage but seen further back. x, y: where the stage's
    //   top left lies, and scale: how many panel pixels a point of the stage takes. What lies off
    //   the stage is also seen.
    // Over it are the marks of the picked layer and of the one under the pointer. Each is a frame
    //   given by doc_frame: center, width, height, rotation, and the point it rotates about. pick
    //   and hover hold those values, and picked and hovered say whether they are set.
    // point: panel pixels per point of the screen, in which the marks are sized.
    struct { uint32_t w = 0, h = 0; double x = 0, y = 0, scale = 1, point = 2; filament::math::mat4 was, wasCulled;
             bool picked = false, hovered = false, rotateHandle = true; double pick[8] = {}, hover[8] = {}; } desk;
    // Drawn last, over all of them, for example a whole-screen effect. See screen_fx.h.
    std::function<void()> over;
    // Work to do once before the next frame, keyed by its owner, for example an image's distances
    // from its edge. See canvas_edge.h.
    std::map<const void*, std::function<void()>> once;
    // Drawn before the stage's own view, each into an image of its own, for layers with effects of
    // their own. See layer_fx.h.
    std::vector<std::function<void()>> before;
    // Run before each frame begins to set those images and the material instances that show them.
    // Filament uploads material parameters as a frame begins, see FRenderer::beginFrame and
    // FEngine::prepare.
    std::vector<std::function<void()>> aim;
    // Run after everything else in the same frame. For the preview panel it places the stage's
    // image on it, see live.h.
    std::function<void()> lastly;
    // The image the views draw into, see live.h and screen_fx.h. Null means the screen.
    filament::Texture* drawTarget = nullptr;
    // Where the image finally goes. Null means the screen. For the app's window it is the live
    // image, see live.h.
    filament::RenderTarget* out = nullptr;
};

// Creates the engine, scene, views and camera of a stage w by h pixels.
Stage open_stage(int w, int h);

// Lays the stage's images out on the preview panel when `on` is true, before they are drawn, or on
// the stage again when it is false, after. The views that the stage's camera sees by get the
// panel's viewport, and the camera's projection is moved and scaled so the stage lies where the
// panel says. The floor's and the mattes' own cameras are left as they are.
void desk_lay(Stage& s, bool on);

// Sets the environment light that the glass mirrors and is lit by: one of the studios that come
// with Filament, converted to a .ktx by cmgen. Returns false if the file is missing or has no
// spherical harmonics.
bool room(Stage& s, const char* ktx, float intensity);

// Returns a 1x1 white image, created on first use.
filament::Texture* white_point(Stage& s);

// Returns the file name of the flat sheet's material for a blend mode against what is behind it.
// `lay` is nullptr for normal blending over it, or "add", "multiply" or "screen", using Filament's
// own blending. flat.mat is built once for each. `lit` selects the lit variant. A non-empty `wear`
// names a material with its own blend mode.
std::string flat_laid(const char* lay, bool lit = false, const std::string& wear = "");

// Returns the material made from the file `filamat`, reading and making it only once. Every entity
// made from it has its own material instance. Returns nullptr if there is no such file.
filament::Material* material(Stage& s, const char* filamat);
// Creates a placeholder mesh of one triangle for a sketch. It has no real shape yet, because
// document/evaluate/sketch.h makes it again each frame.
Mesh* sketch_mesh();
// Puts mesh `m` on the stage once at each of `places`, with its triangles in parts, and returns the
// material instance of each part. Returns an empty vector if the material file is missing.
// ends: where each part's indices end. Empty means one part. Each part has its own material
// instance of the same material, as a Filament renderable has several primitives.
// layer: the Filament layer mask value. 2 is left out of the image of what is behind, for all
// glass. 8 is only in the image of the glass's far faces.
// order: among entities of a kind, a lower value is drawn first.
// copies: how many times each place is drawn in one go. A material that asks for its instance index
// tells them apart.
// together: draw the places in groups with Filament's instancing, see below.
std::vector<filament::MaterialInstance*> add_parts(Stage& s, Mesh* m, const char* filamat, std::vector<filament::math::mat4f> places, std::vector<uint32_t> ends,
                                                   uint8_t layer = 1, bool shadows = false, int copies = 1, int order = 4, bool together = false);
// Like add_parts for a mesh of one part. Returns its material instance, or nullptr on failure.
filament::MaterialInstance* add(Stage& s, Mesh* m, const char* filamat, std::vector<filament::math::mat4f> places = {filament::math::mat4f{}}, uint8_t layer = 1,
                                bool shadows = false, int copies = 1, int order = 4, bool together = false);

// Gives mesh `m` more parts on the stage, all using material instance `look` until told otherwise.
// Filament makes an entity's renderable again when it is built on it, see
// RenderableManager::Builder::build, so the entity stays where it is, in the scene, under its
// parent.
void more_parts(Stage& s, Mesh* m, size_t parts, filament::MaterialInstance* look);
// Replaces the points and triangles of mesh `m`, with the same count or another. `ends` gives where
// each part's indices end. The mesh is written into the buffers it has while it fits them, as Rive
// and Live2D write theirs again instead of making new ones. Otherwise new buffers a quarter larger
// than needed are made, as Rive grows its buffers. The old buffers are destroyed, and Filament
// keeps them until no frame uses them.
void reshape(Stage& s, Mesh* m, const std::vector<uint32_t>& ends);

// Makes one glass block of edge 1, as real ones are: the edges a little round, by a tenth of half
// the edge, and the faces flat. `flat` is how many times a flat face is cut across.
Mesh* cube(float ROUND, int flat = 1);

// Makes a ring of round section, lying in the plane of x and y. R is the radius of the ring and r
// the radius of its section.
Mesh* torus(float R, float r, int around = 128, int about = 40);

// Makes a ball of radius r, round from pole to pole.
Mesh* sphere(float r, int around = 48, int about = 24);

// Makes a solid of twenty flat faces, an icosahedron. Each face has its own three corners, so the
// edges are hard.
Mesh* gem(float size);

#endif  // MOTOLII_STAGE_RENDER_RENDER_STAGE_H_

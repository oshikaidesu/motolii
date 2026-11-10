// The stage: the mesh and Stage types, creating a Filament engine and stage, and adding, reshaping
// and making meshes on it. Included by render.h; not self-contained.
#include <filament/Camera.h>
#include <filament/ColorGrading.h>
#include <filament/Engine.h>
#include <filament/IndexBuffer.h>
#include <filament/InstanceBuffer.h>
#include <filament/IndirectLight.h>
#include <filament/LightManager.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Renderer.h>
#include <filament/RenderTarget.h>
#include <filament/Scene.h>
#include <filament/SwapChain.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <filament/ToneMapper.h>
#include <filament/TransformManager.h>
#include <filament/VertexBuffer.h>
#include <filament/View.h>
#include <filament/Box.h>
#include <filament/Viewport.h>

#include <geometry/SurfaceOrientation.h>
#include <image/Ktx1Bundle.h>
#include <ktxreader/Ktx1Reader.h>
#include <math/mat4.h>
#include <utils/EntityManager.h>

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>

#include <mach/mach.h>

#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <csignal>
#include <map>
#include <functional>
#include <string>
#include <thread>
#include <vector>

using namespace filament;
using namespace filament::math;

static const float TAU = 6.2831853f;

// A shape that a p5.js sketch draws, in the form the sketch has it. See document/sketch.h.
struct SketchShape { std::vector<float3> pos, nrm; std::vector<float2> uv; std::vector<uint32_t> idx, edges; };
// A value that the sketch passes to its shader(), identified by name.
struct SketchTold { std::string name, type; int count = 1, size = 1; };
// The material made for a sketch's shader, the values it takes, and its material instances.
struct SketchPaint { Material* material = nullptr; std::vector<SketchTold> told; int size = 0; std::vector<MaterialInstance*> looks; };
// The points and triangles of one mesh, and the GPU buffers they were last uploaded to.
struct Mesh {
    std::vector<float3> pos, nrm;
    std::vector<float2> uv;
    std::vector<uint32_t> idx;
    std::vector<quatf> quat;
    // Per-point colours for sketch.mat. Most meshes have none.
    std::vector<float4> color;
    // A second set of texture coordinates, where each point reads its image.
    std::vector<float2> uv1;
    // The buffers as last put in the scene. See add_parts and reshape.
    VertexBuffer* vb = nullptr;
    IndexBuffer* ib = nullptr;
    // How many points and indices the buffers hold. The buffers are written again in place while
    // the mesh fits.
    uint32_t vbRoom = 0, ibRoom = 0;
};

// Gives a sheet depth: its four corners are duplicated in front of it and behind it, forming a box
// that its image is read through. See deep.glsl.
static void sheet_deep(Mesh* m, float deep) {
    for (size_t i = 0; i < 4; ++i) m->pos.push_back(m->pos[i]), m->nrm.push_back(m->nrm[i]), m->uv.push_back(m->uv[i]);
    for (size_t i = 0; i < 4; ++i) m->pos[i].z = deep, m->pos[i + 4].z = -deep;
    m->idx = {0, 1, 2, 0, 2, 3, 5, 4, 7, 5, 7, 6, 4, 5, 1, 4, 1, 0, 5, 6, 2, 5, 2, 1, 6, 7, 3, 6, 3, 2, 7, 4, 0, 7, 0, 3};
}

// Returns a descriptor holding a copy of `bytes` bytes from `from`. Filament reads the buffer later
// on its own thread and frees it through the callback, so the mesh may be rebuilt meanwhile.
static backend::BufferDescriptor copied(const void* from, size_t bytes) {
    void* copy = malloc(bytes);
    memcpy(copy, from, bytes);
    return backend::BufferDescriptor(copy, bytes, [](void* buffer, size_t, void*) { free(buffer); });
}

// Reads the whole file at `path`. Returns an empty vector if it cannot be read.
static std::vector<uint8_t> load_file(const char* path) {
    std::ifstream in(path, std::ios::binary);
    return std::vector<uint8_t>((std::istreambuf_iterator<char>(in)), {});
}

// The state of one Filament engine and the stage it draws: scene, views, cameras, helper images,
// and the entities put on it.
struct Stage {
    int w, h;
    Engine* engine;
    Renderer* renderer;
    Scene* scene;
    View* view;
    SwapChain* swap;
    // The camera that views the stage. Every image of the stage is taken by it.
    Camera* camera;
    // The project's own camera. It is the same as `camera` unless a free camera is in use, see
    // god_view. Mattes in the project camera's image are taken by it.
    Camera* film;
    // The free camera, once it has been requested.
    Camera* god = nullptr;
    // The same scene without the glass (layer 2), drawn first into `behind`. It is what a glass
    // block shows.
    View* view_behind;
    // The depth of `behind`. It is drawn into an image of its own for a layer that reads what is
    // under it, see doc_layers_read.
    Texture* behindDepth = nullptr;
    Texture* behind;
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
    View* view_through = nullptr;
    Texture* through = nullptr;
    // How far away those far faces are. The near faces in thick_glass.mat measure the glass with
    // it.
    Texture* through_depth = nullptr;
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
    struct Renderable { utils::Entity thing; const Mesh* of; int nth; mat4f place; bool matte = false;
                  InstanceBuffer* many = nullptr; int count = 1; };
    // A matte: its own scene, view and image, the camera that takes it, and the entity it rides on
    // with that entity's transform. soft: whether some layer reads it blurred.
    struct Matte { Scene* scene; View* view; Texture* frameTexture; bool soft; Camera* eye; utils::Entity on; mat4f onPlace; };
    // The mattes. Each is an image taken by its own camera and drawn before everything else, see
    // matte.
    std::vector<Matte> mattes;
    // Records that one material instance reads one matte. slot: which matte slot of the instance.
    // matte: the index into `mattes`. use: 1 for inside, -1 for outside. soft: the blur level.
    struct Cut { MaterialInstance* look; int slot, matte; float use, soft; };
    // Which material instance reads which matte, see matted. The matte's camera matrix is set
    // before every frame.
    std::vector<Cut> cuts;
    // A white point: the matte of a layer that nothing cuts.
    Texture* white = nullptr;
    // Resources made once for this stage's engine and kept. A stage opened after another in the
    // same program has its own.
    // Each material file, read and built once.
    std::map<std::string, Material*> materials;
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
    struct { uint32_t w = 0, h = 0; double x = 0, y = 0, scale = 1, point = 2; math::mat4 was, wasCulled;
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
    Texture* drawTarget = nullptr;
    // Where the image finally goes. Null means the screen. For the app's window it is the live
    // image, see live.h.
    RenderTarget* out = nullptr;
};

// Creates the engine, scene, views and camera of a stage w by h pixels.
static Stage open_stage(int w, int h) {
    Stage s{w, h};
    // BACKEND=webgpu selects Filament's WebGPU backend, Dawn, which is the way to Windows. It needs
    // Filament built from source, see gpu/filament_webgpu.sh.
    const char* backend = getenv("BACKEND");
    s.engine = Engine::Builder().backend(backend && !strcmp(backend, "webgpu") ? Engine::Backend::WEBGPU : Engine::Backend::METAL).build();
    // An image that does nothing to its colours gets them through exactly. Filament may then use
    // its one-dimensional lookup table instead of a coarse block of values. With the block a white
    // of 255 comes out as 249.
    s.engine->setFeatureFlag("engine.color_grading.use_1d_lut", true);
    s.renderer = s.engine->createRenderer();
    s.scene = s.engine->createScene();
    s.view = s.engine->createView();
    s.swap = s.engine->createSwapChain((uint32_t)w, (uint32_t)h, 0);
    s.camera = s.engine->createCamera(utils::EntityManager::get().create());
    s.camera->setExposure(16.0f, 1.0f / 125.0f, 100.0f);
    s.film = s.camera;
    s.view->setScene(s.scene);
    s.view->setCamera(s.camera);
    s.view->setViewport({0, 0, (uint32_t)w, (uint32_t)h});
    s.view->setDithering(View::Dithering::NONE);
    s.view->setAntiAliasing(View::AntiAliasing::FXAA);
    // Anti-aliases the edges of flat shapes drawn as triangles, see flat_mesh in canvas.h, as Unity
    // and three.js do.
    s.view->setMultiSampleAntiAliasingOptions({.enabled = true, .sampleCount = 4});
    s.view->setScreenSpaceRefractionEnabled(true);
    s.view->setVisibleLayers(0x03, 0x03);
    Renderer::ClearOptions clear{};
    // Clear to transparent, not black. The stage's own view covers all of it anyway, and an image
    // of one layer alone shows the card where the layer is not.
    clear.clearColor = {0, 0, 0, 0};
    clear.clear = true;
    s.renderer->setClearOptions(clear);
    s.behind = Texture::Builder().width(w).height(h).levels(1).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
                   .format(Texture::InternalFormat::RGBA16F).build(*s.engine);
    Texture* depth = s.behindDepth = Texture::Builder().width(w).height(h).levels(1).usage(Texture::Usage::DEPTH_ATTACHMENT).format(Texture::InternalFormat::DEPTH24).build(*s.engine);
    s.view_behind = s.engine->createView();
    s.view_behind->setScene(s.scene);
    s.view_behind->setCamera(s.camera);
    s.view_behind->setViewport({0, 0, (uint32_t)w, (uint32_t)h});
    s.view_behind->setRenderTarget(RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, s.behind).texture(RenderTarget::AttachmentPoint::DEPTH, depth).build(*s.engine));
    s.view_behind->setPostProcessingEnabled(false);
    s.view_behind->setScreenSpaceRefractionEnabled(false);
    return s;
}

// Lays the stage's images out on the preview panel when `on` is true, before they are drawn, or on
// the stage again when it is false, after. The views that the stage's camera sees by get the
// panel's viewport, and the camera's projection is moved and scaled so the stage lies where the
// panel says. The floor's and the mattes' own cameras are left as they are.
static void desk_lay(Stage& s, bool on) {
    const Viewport at = on ? Viewport{0, 0, s.desk.w, s.desk.h} : Viewport{0, 0, (uint32_t)s.w, (uint32_t)s.h};
    for (View* v : {s.view, s.view_behind, s.view_through}) if (v) v->setViewport(at);
    const double near = s.camera->getNear(), far = s.camera->getCullingFar();
    if (!on) return s.camera->setCustomProjection(s.desk.was, s.desk.wasCulled, near, far);
    s.desk.was = s.camera->getProjectionMatrix(), s.desk.wasCulled = s.camera->getCullingProjectionMatrix();
    const double wide = s.w * s.desk.scale, high = s.h * s.desk.scale;
    // Maps the stage's -1..1 range to where the stage lies in the panel's.
    math::mat4 further;
    further[0][0] = wide / s.desk.w, further[1][1] = high / s.desk.h;
    further[3][0] = 2.0 * (s.desk.x + 0.5 * wide) / s.desk.w - 1.0, further[3][1] = 1.0 - 2.0 * (s.desk.y + 0.5 * high) / s.desk.h;
    s.camera->setCustomProjection(further * s.desk.was, further * s.desk.wasCulled, near, far);
}

// Sets the environment light that the glass mirrors and is lit by: one of the studios that come
// with Filament, converted to a .ktx by cmgen. Returns false if the file is missing or has no
// spherical harmonics.
static bool room(Stage& s, const char* ktx, float intensity) {
    static std::vector<std::vector<uint8_t>> ktxs;
    ktxs.push_back(load_file(ktx));
    if (ktxs.back().empty()) return false;
    auto* bundle = new image::Ktx1Bundle(ktxs.back().data(), (uint32_t)ktxs.back().size());
    float3 sh[9];
    if (!bundle->getSphericalHarmonics(sh)) return false;
    Texture* tex = ktxreader::Ktx1Reader::createTexture(s.engine, bundle, false);
    s.scene->setIndirectLight(IndirectLight::Builder().reflections(tex).irradiance(3, sh).intensity(intensity).build(*s.engine));
    return true;
}

// Returns a 1x1 white image, created on first use.
static Texture* white_point(Stage& s) {
    static const uint8_t one[4] = {255, 255, 255, 255};
    if (!s.white) {
        s.white = Texture::Builder().width(1).height(1).levels(1).format(Texture::InternalFormat::RGBA8).build(*s.engine);
        s.white->setImage(*s.engine, 0, backend::PixelBufferDescriptor(one, 4, backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE));
    }
    return s.white;
}

// Returns the file name of the flat sheet's material for a blend mode against what is behind it.
// `lay` is nullptr for normal blending over it, or "add", "multiply" or "screen", using Filament's
// own blending. flat.mat is built once for each. `lit` selects the lit variant. A non-empty `wear`
// names a material with its own blend mode.
static std::string flat_laid(const char* lay, bool lit = false, const std::string& wear = "") {
    // A sheet with its own material has its own blend mode, see doc_sheet_material.
    if (!wear.empty()) return "flat_" + wear + ".filamat";
    if (lit) return std::string("flat_lit_") + (lay ? lay : "transparent") + ".filamat";
    return lay ? std::string("flat_") + lay + ".filamat" : "flat.filamat";
}

// Returns the material made from the file `filamat`, reading and making it only once. Every entity
// made from it has its own material instance. Returns nullptr if there is no such file.
static Material* material(Stage& s, const char* filamat) {
    auto& built = s.materials;
    if (!built.count(filamat)) {
        const std::vector<uint8_t> pkg = load_file(filamat);
        built[filamat] = pkg.empty() ? nullptr : Material::Builder().package(pkg.data(), pkg.size()).build(*s.engine);
            // Compile the shader programs now, not at the first frame that needs them. In the
            // crowd's first minute this dropped 1 to 4 frames, against 3 to 16 without.
        if (built[filamat]) built[filamat]->compile(Material::CompilerPriorityQueue::HIGH);
    }
    return built[filamat];
}
// Creates the vertex buffer of mesh `m` with room for `room` points. A mesh with per-point colours
// has two more buffers, for the colours and the second texture coordinates.
static VertexBuffer* mesh_buffers(Stage& s, const Mesh& m, uint32_t room) {
    VertexBuffer::Builder make;
    make.vertexCount(room).bufferCount(m.color.empty() ? 3 : 5)
        .attribute(VertexAttribute::POSITION, 0, VertexBuffer::AttributeType::FLOAT3)
        .attribute(VertexAttribute::TANGENTS, 1, VertexBuffer::AttributeType::FLOAT4)
        .attribute(VertexAttribute::UV0, 2, VertexBuffer::AttributeType::FLOAT2);
    if (!m.color.empty()) make.attribute(VertexAttribute::COLOR, 3, VertexBuffer::AttributeType::FLOAT4).attribute(VertexAttribute::UV1, 4, VertexBuffer::AttributeType::FLOAT2);
    return make.build(*s.engine);
}
// Writes the first n points of `m` into the buffers of `vb`.
static void mesh_points(Stage& s, const Mesh& m, VertexBuffer* vb, size_t n) {
    vb->setBufferAt(*s.engine, 0, copied(m.pos.data(), n * sizeof(float3)));
    vb->setBufferAt(*s.engine, 1, copied(m.quat.data(), n * sizeof(quatf)));
    vb->setBufferAt(*s.engine, 2, copied(m.uv.data(), n * sizeof(float2)));
    if (!m.color.empty()) vb->setBufferAt(*s.engine, 3, copied(m.color.data(), n * sizeof(float4))), vb->setBufferAt(*s.engine, 4, copied(m.uv1.data(), n * sizeof(float2)));
}
// Creates a placeholder mesh of one triangle for a sketch. It has no real shape yet, because
// document/sketch.h makes it again each frame.
static Mesh* sketch_mesh() {
    Mesh* m = new Mesh;
    m->pos.assign(3, float3{0.f}), m->nrm.assign(3, float3{0.f, 0.f, 1.f}), m->uv.assign(3, float2{0.f}), m->color.assign(3, float4{0.f}), m->uv1.assign(3, float2{0.f}), m->idx = {0, 1, 2};
    return m;
}
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
static std::vector<MaterialInstance*> add_parts(Stage& s, Mesh* m, const char* filamat, std::vector<mat4f> places, std::vector<uint32_t> ends,
                                                uint8_t layer = 1, bool shadows = false, int copies = 1, int order = 4, bool together = false) {
    Material* mat = material(s, filamat);
    if (!mat) return {};
    if (ends.empty()) ends = {(uint32_t)m->idx.size()};
    const size_t n = m->pos.size();
    auto* frames = geometry::SurfaceOrientation::Builder().vertexCount(n).normals(m->nrm.data()).build();
    m->quat.resize(n);
    frames->getQuats(m->quat.data(), n);
    delete frames;
    VertexBuffer* vb = mesh_buffers(s, *m, (uint32_t)n);
    mesh_points(s, *m, vb, n);
    IndexBuffer* ib = IndexBuffer::Builder().indexCount((uint32_t)std::max<size_t>(1, m->idx.size())).bufferType(IndexBuffer::IndexType::UINT).build(*s.engine);
    if (!m->idx.empty()) ib->setBuffer(*s.engine, copied(m->idx.data(), m->idx.size() * sizeof(uint32_t)));
    m->vb = vb, m->ib = ib, m->vbRoom = (uint32_t)n, m->ibRoom = (uint32_t)std::max<size_t>(1, m->idx.size());
    std::vector<MaterialInstance*> looks;
    for (size_t k = 0; k < ends.size(); ++k) {
        MaterialInstance* mi = mat->createInstance();
        // Fully opaque until told otherwise.
        if (mat->hasParameter("opacity")) mi->setParameter("opacity", 1.f);
        // A material that can be cut is cut by nothing until `matted` says so.
        if (mat->hasParameter("matteUse")) {
            for (const char* name : {"matte0", "matte1", "matte2", "matte3"}) mi->setParameter(name, white_point(s), TextureSampler());
            for (const char* name : {"matteEye0", "matteEye1", "matteEye2", "matteEye3"}) mi->setParameter(name, mat4f{});
            // A video's second plane, see video_layer.h.
            if (mat->hasParameter("colours")) mi->setParameter("colours", white_point(s), TextureSampler());
            mi->setParameter("matteUse", float4{0.f});
            mi->setParameter("matteSoft", float4{0.f});
        }
        // Nothing is read until doc.h says which, and there is no bevel until canvas_renderables.h
        // makes one. Filament refuses a sampler that is left unset.
        for (const char* name : {"backdrop", "edge"}) if (mat->hasParameter(name)) mi->setParameter(name, white_point(s), TextureSampler());
        looks.push_back(mi);
    }
    // Filament wants a rough bounding box if the entity casts or receives shadows.
    float3 low = n ? m->pos[0] : float3{0.f}, high = low;
    for (const float3& p : m->pos) { low = min(low, p); high = max(high, p); }
    // With `together`, the places are drawn in groups of as many as Filament draws in one go, 64,
    // each place being an instance of one entity. A GPU pays for each draw, not for each triangle,
    // so a thousand copies take sixteen draws instead of a thousand.
    // A mesh of two parts, such as a fill and its edge, is not grouped. Filament draws a part for
    // all its instances before the next part, so every edge would lie over every fill, where one
    // copy's fill hid the edge of the copy under it.
    const size_t group = together && places.size() > 1 && ends.size() == 1 ? std::min<size_t>(places.size(), s.engine->getMaxAutomaticInstances()) : 1;
    for (const mat4f& place : places) {
        const size_t at = (size_t)(&place - places.data());
        if (at % group) continue;
        const size_t count = std::min(group, places.size() - at);
        InstanceBuffer* many = nullptr;
        if (group > 1) {
            many = InstanceBuffer::Builder(count).build(*s.engine);
            many->setLocalTransforms(places.data() + at, count);
        }
        utils::Entity e = utils::EntityManager::get().create();
        s.engine->getTransformManager().create(e, {}, many ? mat4f{} : place);
        RenderableManager::Builder b(ends.size());
        for (size_t k = 0; k < ends.size(); ++k) {
            const uint32_t from = k ? ends[k - 1] : 0;
            b.geometry(k, RenderableManager::PrimitiveType::TRIANGLES, vb, ib, from, ends[k] - from).material(k, looks[k]);
        }
        b.boundingBox({(low + high) * 0.5f, max((high - low) * 0.5f, float3{1e-3f})}).culling(false).castShadows(shadows).receiveShadows(shadows).layerMask(0xFF, layer);
        if (many) b.instances(count, many); else b.instances((size_t)copies);
        b.priority((uint8_t)order).build(*s.engine, e);
        s.scene->addEntity(e);
        s.renderables.push_back({e, m, (int)at, place, false, many, (int)count});
    }
    return looks;
}
// Like add_parts for a mesh of one part. Returns its material instance, or nullptr on failure.
static MaterialInstance* add(Stage& s, Mesh* m, const char* filamat, std::vector<mat4f> places = {mat4f{}}, uint8_t layer = 1,
                             bool shadows = false, int copies = 1, int order = 4, bool together = false) {
    const std::vector<MaterialInstance*> looks = add_parts(s, m, filamat, places, {}, layer, shadows, copies, order, together);
    return looks.empty() ? nullptr : looks[0];
}

// Gives mesh `m` more parts on the stage, all using material instance `look` until told otherwise.
// Filament makes an entity's renderable again when it is built on it, see
// RenderableManager::Builder::build, so the entity stays where it is, in the scene, under its
// parent.
static void more_parts(Stage& s, Mesh* m, size_t parts, MaterialInstance* look) {
    auto& faces = s.engine->getRenderableManager();
    for (const Stage::Renderable& built : s.renderables) {
        if (built.of != m) continue;
        const auto at = faces.getInstance(built.thing);
        const uint8_t mask = faces.getLayerMask(at), order = faces.getPriority(at), channel = faces.getChannel(at);
        const uint16_t blend = faces.getBlendOrderAt(at, 0);
        const bool everywhere = faces.isGlobalBlendOrderEnabledAt(at, 0);
        const Box box = faces.getAxisAlignedBoundingBox(at);
        RenderableManager::Builder b(parts);
        for (size_t k = 0; k < parts; ++k) b.geometry(k, RenderableManager::PrimitiveType::TRIANGLES, m->vb, m->ib, 0, 0).material(k, look).blendOrder(k, blend).globalBlendOrderEnabled(k, everywhere);
        b.boundingBox(box).culling(false).castShadows(false).receiveShadows(false).layerMask(0xFF, mask).priority(order).channel(channel).build(*s.engine, built.thing);
    }
}
// Replaces the points and triangles of mesh `m`, with the same count or another. `ends` gives where
// each part's indices end. The mesh is written into the buffers it has while it fits them, as Rive
// and Live2D write theirs again instead of making new ones. Otherwise new buffers a quarter larger
// than needed are made, as Rive grows its buffers. The old buffers are destroyed, and Filament
// keeps them until no frame uses them.
static void reshape(Stage& s, Mesh* m, const std::vector<uint32_t>& ends) {
    VertexBuffer* oldVb = nullptr;
    IndexBuffer* oldIb = nullptr;
    const size_t n = m->pos.size();
    if (!n || m->idx.empty()) return;
    m->quat.resize(n);
    // All normals face one way, a flat shape, so one tangent frame serves every point.
    if (std::all_of(m->nrm.begin(), m->nrm.end(), [&](const float3& v) { return v == m->nrm[0]; })) {
        auto* frames = geometry::SurfaceOrientation::Builder().vertexCount(1).normals(m->nrm.data()).build();
        frames->getQuats(m->quat.data(), 1);
        delete frames;
        std::fill(m->quat.begin() + 1, m->quat.end(), m->quat[0]);
    } else {
        auto* frames = geometry::SurfaceOrientation::Builder().vertexCount(n).normals(m->nrm.data()).build();
        frames->getQuats(m->quat.data(), n);
        delete frames;
    }
    if (!m->vb || n > m->vbRoom) {
        oldVb = m->vb, m->vbRoom = (uint32_t)(n + n / 4 + 16);
        m->vb = mesh_buffers(s, *m, m->vbRoom);
    }
    if (!m->ib || m->idx.size() > m->ibRoom) {
        oldIb = m->ib, m->ibRoom = (uint32_t)(m->idx.size() + m->idx.size() / 4 + 48);
        m->ib = IndexBuffer::Builder().indexCount(m->ibRoom).bufferType(IndexBuffer::IndexType::UINT).build(*s.engine);
    }
    mesh_points(s, *m, m->vb, n);
    m->ib->setBuffer(*s.engine, copied(m->idx.data(), m->idx.size() * sizeof(uint32_t)));
    auto& faces = s.engine->getRenderableManager();
    for (const Stage::Renderable& built : s.renderables) {
        if (built.of != m) continue;
        const auto at = faces.getInstance(built.thing);
        for (size_t k = 0; k < ends.size() && k < faces.getPrimitiveCount(at); ++k) {
            const uint32_t from = k ? ends[k - 1] : 0;
            faces.setGeometryAt(at, k, RenderableManager::PrimitiveType::TRIANGLES, m->vb, m->ib, from, ends[k] - from);
        }
    }
    if (oldVb) s.engine->destroy(oldVb);
    if (oldIb) s.engine->destroy(oldIb);
}

// Makes one glass block of edge 1, as real ones are: the edges a little round, by a tenth of half
// the edge, and the faces flat. `flat` is how many times a flat face is cut across.
static Mesh* cube(float ROUND, int flat = 1) {
    Mesh* m = new Mesh;
    // Where a face is cut: finely across the rounding, and `flat` times across the flat part.
    std::vector<float> line;
    for (int k = 0; k <= 4; ++k) line.push_back(-1.f + ROUND * (float)k / 4.f);
    for (int k = 1; k < flat; ++k) line.push_back(-(1.f - ROUND) + 2.f * (1.f - ROUND) * (float)k / (float)flat);
    for (int k = 4; k >= 0; --k) line.push_back(1.f - ROUND * (float)k / 4.f);
    const int n = (int)line.size();
    const float3 ax[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
    for (int f = 0; f < 6; ++f) {
        const float sgn = f < 3 ? 1.f : -1.f;
        const float3 nf = ax[f % 3] * sgn, a = ax[(f + 1) % 3], b = ax[(f + 2) % 3] * sgn;
        const uint32_t base = (uint32_t)m->pos.size();
        for (int j = 0; j < n; ++j)
            for (int i = 0; i < n; ++i) {
                const float3 q = nf + a * line[i] + b * line[j];
                const float3 core = clamp(q, float3{-(1.f - ROUND)}, float3{1.f - ROUND}), out = normalize(q - core);
                m->pos.push_back((core + out * ROUND) * 0.5f);
                m->nrm.push_back(out);
                m->uv.push_back({0, 0});
            }
        for (int j = 0; j + 1 < n; ++j)
            for (int i = 0; i + 1 < n; ++i) {
                const uint32_t p0 = base + (uint32_t)(j * n + i), p1 = p0 + 1, p2 = p0 + (uint32_t)n + 1, p3 = p0 + (uint32_t)n;
                m->idx.insert(m->idx.end(), {p0, p1, p2, p0, p2, p3});
            }
    }
    return m;
}

// Makes a ring of round section, lying in the plane of x and y. R is the radius of the ring and r
// the radius of its section.
static Mesh* torus(float R, float r, int around = 128, int about = 40) {
    Mesh* m = new Mesh;
    for (int i = 0; i < around; ++i)
        for (int k = 0; k < about; ++k) {
            const float a = TAU * (float)i / around, b = TAU * (float)k / about;
            const float3 out{std::cos(a) * std::cos(b), std::sin(a) * std::cos(b), std::sin(b)};
            m->pos.push_back(float3{std::cos(a), std::sin(a), 0.f} * R + out * r);
            m->nrm.push_back(out);
            m->uv.push_back({(float)i / around, (float)k / about});
            const uint32_t i1 = (uint32_t)((i + 1) % around), k1 = (uint32_t)((k + 1) % about);
            const uint32_t p = (uint32_t)(i * about + k), q = (uint32_t)(i * about) + k1, s = i1 * about + (uint32_t)k, t = i1 * about + k1;
            m->idx.insert(m->idx.end(), {p, s, q, q, s, t});
        }
    return m;
}

// Makes a ball of radius r, round from pole to pole.
static Mesh* sphere(float r, int around = 48, int about = 24) {
    Mesh* m = new Mesh;
    for (int i = 0; i <= around; ++i)
        for (int k = 0; k <= about; ++k) {
            const float a = TAU * (float)i / around, b = 0.5f * TAU * (float)k / about - 0.25f * TAU;
            const float3 out{std::cos(a) * std::cos(b), std::sin(b), std::sin(a) * std::cos(b)};
            m->pos.push_back(out * r);
            m->nrm.push_back(out);
            m->uv.push_back({(float)i / around, (float)k / about});
            if (i < around && k < about) {
                const uint32_t p = (uint32_t)(i * (about + 1) + k), q = p + 1, s = p + (uint32_t)(about + 1), t = s + 1;
                m->idx.insert(m->idx.end(), {p, q, s, s, q, t});
            }
        }
    return m;
}

// Makes a solid of twenty flat faces, an icosahedron. Each face has its own three corners, so the
// edges are hard.
static Mesh* gem(float size) {
    const float f = (1.f + std::sqrt(5.f)) * 0.5f;
    const float3 v[12] = {{-1, f, 0}, {1, f, 0}, {-1, -f, 0}, {1, -f, 0}, {0, -1, f}, {0, 1, f}, {0, -1, -f}, {0, 1, -f}, {f, 0, -1}, {f, 0, 1}, {-f, 0, -1}, {-f, 0, 1}};
    const int faces[20][3] = {{0, 11, 5}, {0, 5, 1}, {0, 1, 7}, {0, 7, 10}, {0, 10, 11}, {1, 5, 9}, {5, 11, 4}, {11, 10, 2}, {10, 7, 6}, {7, 1, 8},
                              {3, 9, 4}, {3, 4, 2}, {3, 2, 6}, {3, 6, 8}, {3, 8, 9}, {4, 9, 5}, {2, 4, 11}, {6, 2, 10}, {8, 6, 7}, {9, 8, 1}};
    Mesh* m = new Mesh;
    for (const auto& t : faces) {
        const float3 n = normalize(cross(v[t[1]] - v[t[0]], v[t[2]] - v[t[0]]));
        for (int k = 0; k < 3; ++k) {
            m->idx.push_back((uint32_t)m->pos.size());
            m->pos.push_back(normalize(v[t[k]]) * size);
            m->nrm.push_back(n);
            m->uv.push_back({0, 0});
        }
    }
    return m;
}

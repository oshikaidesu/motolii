// Per-layer effects for the stage. A layer with effects is drawn alone into an offscreen
// texture, in a view of its own with post-processing off, as in Filament's
// samples/rendertarget.cpp. The effects (.wgsl and ISF files, including ThorVG's own) then run
// on that texture one after another, as in After Effects where a layer's image comes first and
// its effects after. The result is laid on a sheet where the layer sits; see effected.mat and
// google/filament issues #1818, #7676 and #3784. These are the functions of the earlier
// screen_fx.h, minus the code that laid the image over the whole screen.
#pragma once
#include "community/three/solid_three.h"
#include "community/aviutl/aviutl_fx.h"
// Returns the one-letter code of the ThorVG effect named by `w`, or 0 if `w` is not one.
// Defined elsewhere.
static char doc_thor_letter(const std::string& w);
// Rebuilds the effect chain of a layer from `files`, the effect files in order. Does nothing if
// st.files already equals `files`. Fills st.fx with the GPU effects and st.aviutl with the
// AviUtl2 script runners, reusing a runner already open for the same file. st.steps gets one
// code per step: 'a' for an AviUtl2 script, a ThorVG letter, or 0 for the next entry of st.fx.
// Also sets st.readsBehind and st.wide.
static void thing_effects(Stage& s, ScreenStack& st, const std::string& files) {
    if (st.files == files) return;
    st.files = files;
    st.fx.clear();
    st.steps.clear();
    st.readsBehind = false, st.wide = false;
    std::vector<std::shared_ptr<AviutlRun>> scripts;
    for (const std::string& file : script_files(files)) {
        if (file == "none") continue;
        // An AviUtl2 script. It runs each frame on the layer's image.
        if (aviutl_is(file)) {
            const auto found = std::find_if(st.aviutl.begin(), st.aviutl.end(), [&](const auto& r) { return r->file == file; });
            // All scripts of a layer share one Lua state. AviUtl2 runs an object's effects one
            // after another in one Lua, so a global set by one script is read by the next. For
            // example the CrEasy background blur reads the ox that CrEasy set.
            const auto first = !scripts.empty() ? scripts.front() : !st.aviutl.empty() ? st.aviutl.front() : nullptr;
            scripts.push_back(found != st.aviutl.end() ? *found : aviutl_open(s, file, first ? first->L : nullptr)), st.steps.push_back('a');
            // A script that reads its frame needs what is behind the layer: the stage drawn
            // without this layer's own sheet.
            st.readsBehind |= scripts.back()->behind;
            // A script that draws works on the whole stage, as AviUtl2 draws an object on its
            // screen.
            st.wide |= scripts.back()->wide;
            continue;
        }
        // One of ThorVG's own effects. ThorVG draws it at its place in the chain.
        if (const char k = doc_thor_letter(file)) { st.steps.push_back(k); continue; }
        // A splat effect. The point cloud applies it; see render/point_cloud.h.
        if (std::filesystem::path(file).extension() == ".mjs") continue;
        // .am is AbsentMotion's own motion that moves the layer; see absent_motion.h. .json is
        // Filament's settings for the stage; see viewer_settings.h. Neither is an effect here.
        if (const std::string ext = std::filesystem::path(file).extension().string(); ext == ".am" || ext == ".json") continue;
        // A solid's shape. The layer's image is laid on the solid, not run through an effect;
        // see thing_fx_solid.
        if (solid_is(file)) continue;
        ScreenFx*& built = st.built[file];
        if (!built) {
            built = new ScreenFx;
            built->file = file;
            std::string code;
            if (!screen_read(*built, code)) { std::fprintf(stderr, "%s\n", built->trouble.c_str()); continue; }
            built->interop = interop::screen(s.engine, file.c_str(), code.c_str(), built->bytes, &built->trouble, built->textureCount, built->layered);
            if (!built->interop) std::fprintf(stderr, "the effect %s is not taken: %s\n", file.c_str(), built->trouble.c_str());
            built->stamp = screen_stamp(file);
        }
        if (built->interop) st.fx.push_back(built), st.steps.push_back(0);
        // AbsentMotion's backdrop reads what is behind the layer, the stage drawn without it;
        // see screen_fx.h.
        if (built->interop && std::find(built->others.begin(), built->others.end(), "backdrop") != built->others.end()) st.readsBehind = true;
    }
    // Returns the effect's name: for an @ file the part after '#', otherwise the file stem.
    const auto nameOf = [](const std::string& file) { const size_t hash = file.rfind('#'); return hash != std::string::npos ? aviutl_unword(file.substr(hash + 1)) : std::filesystem::path(file).stem().string(); };
    // The effect names in order. A script can ask for its neighbours with
    // obj.getoption("script_name").
    std::vector<std::string> names;
    for (const std::string& file : script_files(files)) if (file != "none") names.push_back(nameOf(file));
    for (const auto& r : scripts) r->chain = names, r->at = (int)(std::find(names.begin(), names.end(), nameOf(r->file)) - names.begin());
    st.aviutl = scripts;
}
// Runs one of ThorVG's own effects as one step of the chain. `k` is the effect's letter. The
// input is the GPU texture `from`, w by h pixels. The output goes to the texture with index
// `into` (0 or 1) of the two alternating textures. The input is put in a ThorVG scene, the
// effect is applied to the scene, and the drawing runs on the driver thread in order with
// Filament's drawing. Lengths in `fx` are stage points, `ppp` pixels each.
static void thing_thor(Stage& s, ScreenStack& st, char k, void* from, int into, uint32_t w, uint32_t h, const Canvas2DFx& fx, float ppp) {
    // Filament's drawing into `from` must reach the GPU queue first, because ThorVG starts
    // drawing at once.
    interop::submit(s.engine);
    interop::on_driver(s.engine, [&s, &st, k, from, into, w, h, fx, ppp] {
        tvg::WgCanvas*& c = st.thor[into];
        if (!c) {
            tvg::Initializer::init(0);
            c = tvg::WgCanvas::gen();
            if (c->target(interop::device(s.engine), interop::instance(s.engine), st.device[into + 1], w, h, tvg::ColorSpace::ABGR8888S, 1) != tvg::Result::Success) return;
        }
        c->remove();
        tvg::Picture* image = tvg::Picture::gen();
        if (image->load(from, w, h) != tvg::Result::Success) return tvg::Paint::rel(image);
        tvg::Scene* scene = tvg::Scene::gen();
        scene->add(image);
        scene->add(tvg::SceneEffect::Clear);
        effect_on(scene, k, fx, ppp);
        c->add(scene);
        c->update();
        c->draw(true);
        c->sync();
    });
}
// Creates or recreates the offscreen textures and render targets of a layer's effects, sized
// to the view's viewport. Called before the frame, because the material that shows a texture
// is given it later by thing_fx_seen.
static void thing_fx_textures(Stage& s, ScreenStack& st, View* v) {
    const Viewport vp = v->getViewport();
    const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width), h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
    // Recreate everything when the viewport size changes.
    if (!st.shot || st.shot->getWidth() != w || st.shot->getHeight() != h) {
        for (Texture*& t : {std::ref(st.shot), std::ref(st.depth), std::ref(st.between[0]), std::ref(st.between[1])}) if (t) s.engine->destroy(t), t = nullptr;
        for (RenderTarget*& r : {std::ref(st.target), std::ref(st.betweenTarget[0]), std::ref(st.betweenTarget[1])}) if (r) s.engine->destroy(r), r = nullptr;
        // Release the device textures only after the drawing that uses them has finished.
        interop::on_driver(s.engine, [built = std::vector<void*>(st.device, st.device + 3), thor = std::vector<tvg::WgCanvas*>(st.thor, st.thor + 2)] {
            for (tvg::WgCanvas* c : thor) delete c;
            for (void* t : built) if (t) wgpuTextureRelease((WGPUTexture)t);
        });
        st.thor[0] = st.thor[1] = nullptr;
        int n = 0;
        // Creates a texture on the device so that ThorVG can read and draw it, and imports it
        // into Filament.
        const auto newTexture = [&] {
            WGPUTextureDescriptor like{};
            like.size = {w, h, 1};
            // The format ThorVG's last step writes, as for an image of its own; see canvas.h.
            like.format = WGPUTextureFormat_BGRA8Unorm;
            like.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc | WGPUTextureUsage_CopyDst;
            like.dimension = WGPUTextureDimension_2D;
            like.mipLevelCount = 1, like.sampleCount = 1;
            static const char* const names[3] = {"thing shot", "thing between 0", "thing between 1"};
            like.label = {names[n], WGPU_STRLEN};
            void* built = st.device[n++] = wgpuDeviceCreateTexture((WGPUDevice)interop::device(s.engine), &like);
            return Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA8).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE | Texture::Usage::BLIT_SRC).import((intptr_t)built).build(*s.engine);
        };
        st.shot = newTexture();
        st.depth = Texture::Builder().width(w).height(h).levels(1).usage(Texture::Usage::DEPTH_ATTACHMENT).format(Texture::InternalFormat::DEPTH24).build(*s.engine);
        st.target = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, st.shot).texture(RenderTarget::AttachmentPoint::DEPTH, st.depth).build(*s.engine);
        for (int k = 0; k < 2; ++k) st.between[k] = newTexture(), st.betweenTarget[k] = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, st.between[k]).build(*s.engine);
    }
}
// Returns the texture that holds the layer's image after its effects: the last one drawn into,
// or the layer's own image if it has none. The sheet or solid shows this texture. The last
// step converts back to linear light; see thing_effects_draw.
static Texture* thing_fx_seen(const ScreenStack& st) { return st.steps.empty() ? st.shot : st.between[st.steps.size() % 2]; }
// Draws the layer alone into st.shot, then runs its effects one after another through the two
// alternating textures st.between. The image is converted to sRGB before the effects and back
// to linear light after. The result is left in st.seen. `thorFx` supplies the values of
// ThorVG effects and is called only when the chain has one. `textures` returns the extra
// textures an effect asks for by name.
static void thing_effects_draw(Stage& s, ScreenStack& st, View* v, const ScreenNumbers& numbers, const std::function<Canvas2DFx()>& thorFx = nullptr, const ScreenTextures& textures = nullptr) {
    // The textures already exist if the layer was aimed; otherwise they are created here.
    thing_fx_textures(s, st, v);
    const Viewport vp = v->getViewport();
    const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width), h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
    RenderTarget* const was = v->getRenderTarget();
    const Renderer::ClearOptions clearWas = s.renderer->getClearOptions();
    Renderer::ClearOptions clear = clearWas;
    // Draw the layer alone, on a transparent background.
    clear.clearColor = {0, 0, 0, 0}, clear.clear = true, clear.discard = true;
    s.renderer->setClearOptions(clear);
    v->setRenderTarget(st.target);
    s.renderer->render(v);
    v->setRenderTarget(was);
    s.renderer->setClearOptions(clearWas);
    st.seen = st.shot;
    // With no effects only the layer's own image is needed, for other layers to use.
    if (st.steps.empty()) return;
    // Pixels of the layer's texture per stage point, as the stage's view draws. A smaller view,
    // such as the tool panel's, has fewer.
    const float ppp = (float)s.view->getViewport().width / (float)std::max(1, s.w);
    const Canvas2DFx thor = thorFx && std::any_of(st.steps.begin(), st.steps.end(), [](char k) { return k != 0 && k != 'a'; }) ? thorFx() : Canvas2DFx{};
    // Convert the image to sRGB for the effects; see screen_tone in screen_fx.h.
    screen_tone(s, st.shot, st.betweenTarget[1], w, h, true);
    // Each step draws into one of the two alternating textures. The effects take the whole
    // texture as their input and fill what is clear.
    for (size_t i = 0, f = 0, a = 0; i < st.steps.size(); ++i) {
        Texture* from = i == 0 ? st.between[1] : st.between[(i - 1) % 2];
        // An AviUtl2 script, told where the layer is seen.
        if (st.steps[i] == 'a') { std::copy(st.box, st.box + 4, st.aviutl[a]->box), std::copy(st.thingSeen, st.thingSeen + 4, st.aviutl[a]->seen), st.aviutl[a]->ground = st.ground, st.aviutl[a]->sounds = &st.sounds; aviutl_draw_step(s, *st.aviutl[a++], from, st.betweenTarget[i % 2], numbers, w, h); continue; }
        // One of ThorVG's own effects.
        if (st.steps[i]) { thing_thor(s, st, st.steps[i], st.device[i == 0 ? 2 : 1 + (i - 1) % 2], (int)(i % 2), w, h, thor, ppp); continue; }
        screen_fresh(s, *st.fx[f]);
        ScreenFx& one = *st.fx[f++];
        one.othersNow.clear();
        for (const std::string& n : one.others) one.othersNow.push_back(textures ? textures(one.file, n) : nullptr);
        screen_draw(s, st, one, from, st.betweenTarget[i % 2], numbers, w, h);
    }
    // Convert back to linear light, as the stage expects.
    screen_tone(s, st.between[(st.steps.size() - 1) % 2], st.betweenTarget[st.steps.size() % 2], w, h, false);
    st.seen = thing_fx_seen(st);
}

// State of a layer that has effects of its own: the view it is drawn alone in, its effect
// chain, and the sheet (a quad) that carries the result into the stage's view.
struct ThingFx {
    ScreenStack st;
    View* view = nullptr;
    Mesh* sheet = nullptr;
    MaterialInstance* look = nullptr;
    // How the sheet blends with what is behind it: one of Filament's blending variants of
    // effected.mat. Empty means normal, over the background.
    std::string lay;
    // The scene the sheet lies in: the scene of a group that has effects of its own, or null
    // for the stage's scene.
    Scene* in = nullptr;
    // Entity of this layer's own camera. It is given the stage's camera each frame, as the
    // offscreen camera in samples/rendertarget.cpp is.
    utils::Entity eye;
    Camera* camera = nullptr;
    // Where the layer is seen, in stage points: left, top, right, bottom.
    double box[4] = {0, 0, 0, 0};
    // Set by thing_fx_stand. How far the stage extends from the layer along its own face, in
    // the order left, right, down, up, in world units. AbsentMotion's effects are cut by the
    // scene; see EffectRuntime::draw in
    // engine/third_party/AbsentMotion/app/src/main/cpp/effects.cpp.
    double sides[4] = {0, 0, 0, 0};
    // True if the sheet stands where the layer is in the world and the image is filmed square
    // to the layer; see thing_fx_stand. False if the sheet is laid on the screen.
    bool world = false;
    // Set by thing_fx_stand. Where the layer itself lies in its image: its center, then its
    // width and height, all in the layer's points, then the points per world unit.
    double own[5] = {0, 0, 0, 0, 0};
    // Set by thing_fx_stand. The layer's own placement without scale, which is where the
    // image is filmed from.
    math::mat4 square;
    // True for a solid. It stays in the world and shows the image itself, using `look` on its
    // faces while the stage is drawn; see effected_solid.mat.
    bool shell = false;
    // The faces' own materials, kept while this layer's image is on them; see doc_layer_shell.
    std::vector<MaterialInstance*> looks;
    // The image on a solid's faces, used when the layer's effects name a shape file in
    // solids/*.js. solidFile is the shape file, solidSaid is what the solid was last built
    // from, solidAs is the material of solidLook, and solid is the mesh. For a shape built from
    // the layer's outline, `cover` holds the coverage as last read back.
    std::string solidFile, solidSaid, solidAs;
    // The shape's parameters as set now, their text values, and the layer's size in its own
    // units.
    std::map<std::string, double> parameters;
    std::map<std::string, std::string> words;
    float2 size{1.f};
    Mesh* solid = nullptr;
    MaterialInstance* solidLook = nullptr;
    bool solidRepeat = false;
    // Coverage (alpha) sampled from the layer's image: a grid of `w` by `h` cells in `a`, and
    // the number of times it has been read back.
    struct Cover { std::vector<uint8_t> a; int w = 0, h = 0, times = 0; };
    std::shared_ptr<Cover> cover = std::make_shared<Cover>();
};

// Creates the view a layer is drawn alone in. It follows the offscreen view of
// samples/rendertarget.cpp: a scene of its own, a camera that follows the stage's, and
// post-processing off, since the stage's own view applies it once over everything.
static View* thing_fx_view(Stage& s, ThingFx& e) {
    View* v = s.engine->createView();
    v->setScene(s.engine->createScene());
    v->getScene()->setIndirectLight(s.scene->getIndirectLight());
    e.eye = utils::EntityManager::get().create();
    e.camera = s.engine->createCamera(e.eye);
    v->setCamera(e.camera);
    v->setViewport(s.view->getViewport());
    v->setPostProcessingEnabled(false);
    // Both layer groups of the stage are visible, as in the stage's own view.
    v->setVisibleLayers(0x03, 0x03);
    v->setBlendMode(View::BlendMode::TRANSLUCENT);
    return v;
}

// Moves the layer's sheet and solid into scene `into`, a group's scene or, if null, the
// stage's scene. The renderer adds and removes renderables only in the stage's scene.
static void thing_fx_into(Stage& s, ThingFx& e, Scene* into) {
    Scene* const to = into ? into : s.scene;
    // Renderables created since then in the stage's scene are moved too.
    for (const Stage::Renderable& built : s.renderables)
        if ((built.of == e.sheet || (e.solid && built.of == e.solid)) && !to->hasEntity(built.thing)) (e.in ? e.in : s.scene)->remove(built.thing), s.scene->remove(built.thing), to->addEntity(built.thing);
    e.in = to == s.scene ? nullptr : to;
}
// Creates the layer's view, sheet and material if they are missing or if `lay`, `world` or
// `shell` changed, and returns `e`. The sheet is a quad that covers the whole image, as in
// samples/materials/image.mat; its corners are the screen's corners.
static ThingFx& thing_fx_built(Stage& s, ThingFx& e, const std::string& lay = "", bool world = false, bool shell = false) {
    if (e.view && e.lay == lay && e.world == world && e.shell == shell) return e;
    if (!e.view) e.view = thing_fx_view(s, e);
    thing_fx_into(s, e, s.scene);
    // A different way of lying needs the sheet made again.
    if (e.sheet) take_off(s, e.sheet), delete e.sheet;
    e.lay = lay, e.world = world, e.shell = shell;
    e.sheet = new Mesh;
    for (float2 c : {float2{-1, -1}, float2{1, -1}, float2{1, 1}, float2{-1, 1}}) e.sheet->pos.push_back({c.x, c.y, 0.f}), e.sheet->nrm.push_back({0, 0, 1}), e.sheet->uv.push_back(c * 0.5f + 0.5f);
    e.sheet->idx = {0, 1, 2, 0, 2, 3};
    e.look = add(s, e.sheet, shell ? "effected_solid.filamat" : (std::string(world ? "effected_world" : "effected") + (lay.empty() ? "" : "_" + lay) + ".filamat").c_str(), {mat4f{}}, 1, world);
    // Only the material is wanted here, so the sheet itself is scaled to nothing.
    if (shell) move(s, e.sheet, [](int, const mat4f&) { return mat4f::scaling(float3{0.f}); });
    // Give it an image from the start, as the image.mat sample does. Filament prepares every
    // material instance before any view renders, and the layer's own view is drawn first.
    e.look->setParameter("image", white_point(s), TextureSampler());
    // The place covers the whole stage until the layer is aimed.
    if (!world && !shell) e.look->setParameter("place", math::mat4f{});
    return e;
}

// Removes everything the layer created in the engine and resets `e`.
static void thing_fx_off(Stage& s, ThingFx& e) {
    thing_fx_into(s, e, s.scene);
    if (e.sheet) take_off(s, e.sheet), delete e.sheet;
    if (e.solid) take_off(s, e.solid), delete e.solid;
    if (e.view) s.engine->destroy(e.view->getScene()), s.engine->destroy(e.view);
    if (e.camera) s.engine->destroyCameraComponent(e.eye), utils::EntityManager::get().destroy(e.eye);
    e = ThingFx{};
}

// Aims the layer's camera at `said`, the box where the layer is seen: left, top, right, bottom
// in stage points. The camera is given the stage's projection and pose each frame, as the
// offscreen camera in samples/rendertarget.cpp is (setCustomProjection, setModelMatrix). The
// projection is narrowed to the box so that the box is the whole image. This matches After
// Effects, where a layer's effects work on the layer's own image, and an ISF effect's center
// is its middle. The image has as many pixels as the box covers on the stage's view. The
// sheet is laid on the box through the `place` parameter of effected.mat.
static void thing_fx_aim(Stage& s, ThingFx& e, const double* said) {
    const double ppp = (double)s.view->getViewport().width / std::max(1, s.w);
    double box[4] = {said[0], said[1], said[2], said[3]};
    // A solid reads its image point for point, so snap the box to the stage's pixels.
    if (e.shell) box[0] = std::floor(box[0] * ppp) / ppp, box[1] = std::floor(box[1] * ppp) / ppp, box[2] = std::ceil(box[2] * ppp) / ppp, box[3] = std::ceil(box[3] * ppp) / ppp;
    std::copy(box, box + 4, e.box), std::copy(box, box + 4, e.st.box);
    // The box in the stage's clip space, y up.
    const double x0 = 2 * box[0] / s.w - 1, x1 = 2 * box[2] / s.w - 1, y0 = 1 - 2 * box[3] / s.h, y1 = 1 - 2 * box[1] / s.h;
    math::mat4 crop;
    crop[0][0] = 2 / (x1 - x0), crop[1][1] = 2 / (y1 - y0), crop[3][0] = -(x0 + x1) / (x1 - x0), crop[3][1] = -(y0 + y1) / (y1 - y0);
    const Camera& c = *s.camera;
    e.camera->setCustomProjection(crop * c.getProjectionMatrix(), crop * c.getCullingProjectionMatrix(), c.getNear(), c.getCullingFar());
    e.camera->setModelMatrix(c.getModelMatrix());
    e.camera->setExposure(c.getAperture(), c.getShutterSpeed(), c.getSensitivity());
    e.view->setViewport({0, 0, (uint32_t)std::max(1L, std::lround((box[2] - box[0]) * ppp)), (uint32_t)std::max(1L, std::lround((box[3] - box[1]) * ppp))});
    math::mat4f place;
    place[0][0] = (float)((x1 - x0) / 2), place[1][1] = (float)((y1 - y0) / 2), place[3][0] = (float)((x0 + x1) / 2), place[3][1] = (float)((y0 + y1) / 2);
    if (e.shell) e.look->setParameter("box", float4{(float)(box[0] / s.w), (float)(box[1] / s.h), (float)((box[2] - box[0]) / s.w), (float)((box[3] - box[1]) / s.h)});
    else e.look->setParameter("place", place);
}

// Aims the layer's camera square at the layer's own face, for a solid's faces, so that the
// image is the same however the solid is turned. The camera is orthographic, on the layer's z
// axis, as wide and high as the layer (Filament's Camera::setProjection with ORTHO), and is
// updated each frame as in samples/rendertarget.cpp. The image is 2048 pixels along its
// longer side, or `dense` pixels per world unit if that is given, with `room` added around the
// layer. `sides`, if given, are the extents left, right, down, up instead of the layer's size.
static void thing_fx_face(Stage& s, ThingFx& e, const math::mat4& place, float2 half, double room = 0.0, double dense = 0.0, const double* sides = nullptr) {
    math::double3 x = place[0].xyz, y = place[1].xyz;
    const double sx = length(x), sy = length(y), wide = half.x * sx + room, high = half.y * sy + room;
    const double l = sides ? sides[0] : wide, r = sides ? sides[1] : wide, b = sides ? sides[2] : high, t = sides ? sides[3] : high, far = 4.0 * std::max({l, r, b, t}) + 1.0;
    if (wide < 1e-9 || high < 1e-9) return;
    x /= sx, y = normalize(y - dot(y, x) * x);
    const math::double3 z = cross(x, y);
    e.square = math::mat4(math::double4{x, 0}, math::double4{y, 0}, math::double4{z, 0}, place[3]);
    e.camera->setModelMatrix(e.square * math::mat4::translation(math::double3{0, 0, 0.5 * far}));
    e.camera->setProjection(Camera::Projection::ORTHO, -l, r, -b, t, 0.0, far);
    const Camera& c = *s.camera;
    e.camera->setExposure(c.getAperture(), c.getShutterSpeed(), c.getSensitivity());
    const double k = dense > 0.0 ? dense : 2048.0 / std::max(l + r, b + t);
    e.view->setViewport({0, 0, (uint32_t)std::max(1L, std::lround(k * (l + r))), (uint32_t)std::max(1L, std::lround(k * (b + t)))});
}

// Stands a flat layer's image in the world, as After Effects does for a layer with masks,
// effects and transformations. The image is filmed square to the layer's face and covers as
// much of the stage as e.sides says, plus a margin that the effects measure by: 128 stage
// points, as BAKE_MARGIN in sashimono-edit. The margin and extents are the same wherever the
// camera is, so what the effects produce stays attached to the layer. When the layer is near
// the camera, the image has as many pixels as the camera sees of it, so it stays sharp. `seen`
// is the number of stage points per world unit where the layer is. The sheet lies where the
// layer lies.
static void thing_fx_stand(Stage& s, ThingFx& e, const math::mat4& place, float2 half, double seen) {
    // `usual` is the number of stage points per world unit at the stage's own camera distance;
    // see document/evaluate.h.
    const double ppp = (double)s.view->getViewport().width / std::max(1, s.w), usual = s.h / (12.0 * std::tan(15.0 * M_PI / 180.0));
    const double room = 128.0 / usual, sx = length(place[0].xyz), sy = length(place[1].xyz), wide = half.x * sx + room, high = half.y * sy + room;
    const double c[4] = {std::max(wide, e.sides[0]), std::max(wide, e.sides[1]), std::max(high, e.sides[2]), std::max(high, e.sides[3])}, across = c[0] + c[1], tall = c[2] + c[3];
    // At most 4096 pixels.
    const double point = std::min(std::max(usual, seen), 4096.0 / (ppp * std::max(across, tall)));
    thing_fx_face(s, e, place, half, room, point * ppp, c);
    e.box[0] = e.box[1] = 0, e.box[2] = across * point, e.box[3] = tall * point;
    std::copy(e.box, e.box + 4, e.st.box);
    e.st.frame[0] = (c[0] - wide) / across, e.st.frame[1] = (c[3] - high) / tall, e.st.frame[2] = 2 * wide / across, e.st.frame[3] = 2 * high / tall;
    e.st.own[0] = (c[0] - wide + room) / across, e.st.own[1] = (c[3] - high + room) / tall, e.st.own[2] = 2 * (wide - room) / across, e.st.own[3] = 2 * (high - room) / tall;
    e.own[0] = c[0] * point, e.own[1] = c[3] * point, e.own[2] = 2 * half.x * sx * point, e.own[3] = 2 * half.y * sy * point, e.own[4] = point;
    const mat4f sheet = mat4f(e.square * math::mat4::translation(math::double3{(c[1] - c[0]) / 2, (c[3] - c[2]) / 2, 0.0}) * math::mat4::scaling(math::double3{across / 2, tall / 2, 1.0}));
    move(s, e.sheet, [&](int, const mat4f&) { return sheet; });
}

// Rebuilds the layer's solid when what it is made of has changed: the shape file, parameters,
// size or coverage. The solid goes in the stage's scene, casts and receives shadows, and is
// unlit when its Lit parameter is off. A solid that already exists only gets its new vertices
// through reshape. Within a frame, when `inFrame` is set, only that happens: a material
// created then is not ready until the next frame, because Filament prepares every material as a frame begins,
// in FEngine::prepare. So a new solid waits for the next frame.
static void thing_fx_solid(Stage& s, ThingFx& e, bool inFrame) {
    std::string said = e.solidFile + " " + std::to_string(e.size.x) + " " + std::to_string(e.size.y) + " " + std::to_string(e.cover->times);
    for (const auto& [n, v] : e.parameters) said += " " + n + "=" + std::to_string(v);
    for (const auto& [n, w] : e.words) said += " " + n + ":" + w;
    const auto lit = e.parameters.find("lit");
    const bool flat = lit != e.parameters.end() && lit->second == 0;
    const char* const look = flat ? "solid_image_flat.filamat" : "solid_image.filamat";
    const bool anew = !e.solid || e.solidAs != look;
    if (said == e.solidSaid || (anew && inFrame)) return;
    SolidMesh built;
    std::string why;
    if (!solid_three(e.solidFile, e.parameters, e.words, e.size.x, e.size.y, e.cover->a, e.cover->w, e.cover->h, built, why)) std::fprintf(stderr, "the solid %s is not built: %s\n", e.solidFile.c_str(), why.substr(0, 600).c_str());
    // Nothing is built yet, for example Raster Extrude before its image is read. Use a single
    // point so that the material is ready.
    if (built.idx.empty() || built.pos.size() != built.nrm.size() || built.uv.size() * 3 != built.pos.size() * 2) built = SolidMesh{{0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 1, 0, 0, 1}, {0, 0, 0, 0, 0, 0}, {0, 1, 2}};
    e.solidSaid = said;
    if (anew && e.solid) take_off(s, e.solid), delete e.solid, e.solid = nullptr;
    Mesh* m = e.solid ? e.solid : new Mesh;
    m->pos.resize(built.pos.size() / 3), m->nrm.resize(built.pos.size() / 3), m->uv.resize(built.uv.size() / 2);
    std::memcpy(m->pos.data(), built.pos.data(), built.pos.size() * sizeof(float)), std::memcpy(m->nrm.data(), built.nrm.data(), built.nrm.size() * sizeof(float));
    std::memcpy(m->uv.data(), built.uv.data(), built.uv.size() * sizeof(float));
    m->idx = std::move(built.idx);
    e.solidRepeat = built.repeat;
    if (!anew) return reshape(s, m, {(uint32_t)m->idx.size()});
    e.solid = m, e.solidAs = look;
    e.solidLook = add(s, m, look, {mat4f{}}, 1, true);
    if (!e.solidLook) return;
    // Give it an image from the start, as the sheet does.
    e.solidLook->setParameter("image", white_point(s), TextureSampler());
    if (!flat) e.solidLook->setParameter("roughness", 0.5f), e.solidLook->setParameter("metallic", 0.f);
}

// Reads back the coverage (alpha) of the layer's image, for a shape built from its outline.
// Uses Filament's Renderer::readPixels, whose callback runs on a later frame; the shape is
// built from the result then. Samples every so many pixels, at most `cells` along the longer
// side.
static void thing_fx_cover(Stage& s, ThingFx& e, int cells) {
    RenderTarget* const from = e.st.steps.empty() ? e.st.target : e.st.betweenTarget[(e.st.steps.size() - 1) % 2];
    const Viewport vp = e.view->getViewport();
    if (!from || !vp.width || !vp.height) return;
    auto* pixels = new std::vector<uint8_t>((size_t)vp.width * vp.height * 4);
    s.renderer->readPixels(from, 0, 0, vp.width, vp.height, backend::PixelBufferDescriptor::make(pixels->data(), pixels->size(), backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE,
        [pixels, cover = e.cover, w = (int)vp.width, h = (int)vp.height, cells](void const*, size_t) {
            const double every = (double)std::max(w, h) / std::max(2, cells);
            const int cw = std::max(2, (int)(w / every)), ch = std::max(2, (int)(h / every));
            std::vector<uint8_t> a((size_t)cw * ch);
            for (int y = 0; y < ch; ++y) for (int x = 0; x < cw; ++x) a[(size_t)(y * cw + x)] = (*pixels)[4 * ((size_t)std::min(h - 1, (int)(y * every)) * w + std::min(w - 1, (int)(x * every))) + 3];
            if (a != cover->a || cw != cover->w) cover->a = std::move(a), cover->w = cw, cover->h = ch, cover->times++;
            delete pixels;
        }));
}

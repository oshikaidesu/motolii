// Layer helpers for the stage: glass and other materials, mattes, drawing a frame, and removing
// meshes. Included by render.h; not self-contained.


// Returns a typical thickness of the solid: four times its volume divided by its surface area. That
// is two thirds of the width for a ball, the width for a bar, and twice the thickness for a sheet.
// The glass materials below take their depth from it, so the caller does not have to supply one.
static float usual_depth(const Mesh* m) {
    double volume = 0, surface = 0;
    for (size_t i = 0; i + 2 < m->idx.size(); i += 3) {
        const float3 a = m->pos[m->idx[i]], b = m->pos[m->idx[i + 1]], c = m->pos[m->idx[i + 2]];
        volume += dot(a, cross(b, c)) / 6.0;
        surface += length(cross(b - a, c - a)) / 2.0;
    }
    return (float)(4.0 * std::fabs(volume) / surface);
}

// Adds glass rendered with Filament's own refraction, absorption, dispersion and reflection of the
// environment (own_glass.mat). Its depth comes from the mesh itself. Returns the material instance,
// or nullptr if the material could not be built.
// colour: the colour white light has after travelling a typical depth of this glass. {1, 1, 1} is
// clear.
// crushed: how strongly the faces lean in different directions. 0 is smooth.
// Thin, bent solids such as blades, ribbons and sheets look good in it. Unlike thick_glass it does
// not show its own far side.
static MaterialInstance* own_glass(Stage& s, Mesh* m, std::vector<mat4f> places, float3 colour = float3{1.f}, float crushed = 0.f) {
    MaterialInstance* mi = add(s, m, "own_glass.filamat", places, 2);
    if (!mi) return nullptr;
    // The depth is exaggerated eight times so that what is behind the glass swims in it.
    const float deep = 8.f * usual_depth(m) * length(places[0][0].xyz);
    mi->setParameter("thickness", deep);
    mi->setParameter("absorb", float3{-std::log(std::max(colour.x, 1e-3f)), -std::log(std::max(colour.y, 1e-3f)), -std::log(std::max(colour.z, 1e-3f))} / deep);
    mi->setParameter("lean", crushed);
    mi->setParameter("film", 0.f);
    mi->setParameter("split", 0.5f);
    return mi;
}

// Adds a solid with one of the renderer's own materials, chosen by name in `wears`. See
// doc_material in doc.h for the Material group in the Create tab. Returns the material instance, or
// nullptr if the name is unknown or the build failed.
// "filament_glass": glass from own_glass above. ior is the refraction index, split how far the
// colours part, swim how far the faces lean, vivid the strength of the thin-film rainbow, and dark
// how deep the colour is.
// "lacquer": blade.mat, a hard clear coat over a colour that is dark at the root and as given at
// the tip. metal is 0 for lacquer and 1 for steel.
// "bubble": bubble.mat. vivid is the brightness of its rim.
// tone: the colour of the material.
static MaterialInstance* solid_wear(Stage& s, Mesh* m, std::vector<mat4f> places, const std::string& wears, float3 tone, float ior, float split, float swim, float dark, float vivid, float metal) {
    MaterialInstance* mi = nullptr;
    if (wears == "filament_glass") {
        // With dark at 4 the glass colour is exactly tone.
        const float3 left = float3{std::pow(tone.x, 0.25f * dark), std::pow(tone.y, 0.25f * dark), std::pow(tone.z, 0.25f * dark)};
        if (!(mi = own_glass(s, m, places, left, 0.06f * swim))) return nullptr;
        mi->setParameter("ior", ior), mi->setParameter("split", split), mi->setParameter("film", std::clamp(vivid / 3.f, 0.f, 1.f));
    } else if (wears == "lacquer") {
        if (!(mi = add(s, m, "blade.filamat", places))) return nullptr;
        const float3 own = Color::toLinear<ACCURATE>(sRGBColor{tone});
        mi->setParameter("dark", own * 0.3f), mi->setParameter("light", own), mi->setParameter("metal", metal), mi->setParameter("hatch", 0.f);
    } else if (wears == "bubble") {
        if (!(mi = add(s, m, "bubble_worn.filamat", places))) return nullptr;
        mi->setParameter("strength", vivid);
    }
    return mi;
}

// Adds glass seen through both of its sides (thick_glass.mat): the mesh at each of its places,
// drawn three times.
// 1. The far faces are drawn into an image of their own with the direction they face and their
//    distance (far_side.mat). Nothing else is in that image.
// 2. The far faces are also drawn as seen from inside, over the image of the scene without the
//    glass (far_look.mat).
// 3. The near faces, drawn on the screen, bend the view ray in, look up the far face there, and
//    bend the ray out again to the scene.
// The first call creates the far-side image. The caller has nothing else to set up. Returns the
// material instance of the near faces, or nullptr on failure.
static MaterialInstance* thick_glass(Stage& s, Mesh* m, std::vector<mat4f> places) {
    if (!s.view_through) {
        s.through = Texture::Builder().width(s.w).height(s.h).levels(1).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
                        .format(Texture::InternalFormat::RGBA16F).build(*s.engine);
        s.through_depth = Texture::Builder().width(s.w).height(s.h).levels(1).usage(Texture::Usage::DEPTH_ATTACHMENT | Texture::Usage::SAMPLEABLE)
                              .format(Texture::InternalFormat::DEPTH32F).build(*s.engine);
        s.view_through = s.engine->createView();
        s.view_through->setScene(s.scene);
        s.view_through->setCamera(s.camera);
        s.view_through->setViewport({0, 0, (uint32_t)s.w, (uint32_t)s.h});
        s.view_through->setRenderTarget(RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, s.through).texture(RenderTarget::AttachmentPoint::DEPTH, s.through_depth).build(*s.engine));
        s.view_through->setPostProcessingEnabled(false);
        s.view_through->setVisibleLayers(0xFF, 0x08);
    }
    MaterialInstance* back = add(s, m, "far_side.filamat", places, 8);
    // Layer 16 is drawn only in the image of the scene without the glass.
    MaterialInstance* look = add(s, m, "far_look.filamat", places, 16);
    MaterialInstance* front = add(s, m, "thick_glass.filamat", places, 2);
    if (!back || !look || !front) return nullptr;
    back->setCullingMode(backend::CullingMode::FRONT);
    look->setCullingMode(backend::CullingMode::FRONT);
    s.view_behind->setVisibleLayers(0x10, 0x10);
    const TextureSampler smooth(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR, TextureSampler::WrapMode::CLAMP_TO_EDGE);
    const TextureSampler exact(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST, TextureSampler::WrapMode::CLAMP_TO_EDGE);
    front->setParameter("behind", s.behind, smooth);
    s.behindRead = true;
    front->setParameter("farSide", s.through, smooth);
    front->setParameter("farDepth", s.through_depth, exact);
    // A typical thickness of the solid: four times its volume over its surface area. It is computed
    // once here. A path through the glass much longer than this is the glass seen along itself, and
    // goes dark.
    const float usual = usual_depth(m) * length(places[0][0].xyz);
    // A bar or a sheet has places where it is seen along itself. A lump such as a ball or a gem has
    // none: its longest path is straight through the middle, about 1.5 times `usual`. So the closer
    // the solid is to a lump, measured as its typical depth against how far it reaches, the longer
    // a path must be before it counts as long. This keeps the middle of a gem clear.
    float3 mid{0.f};
    for (float3 p : m->pos) mid += p;
    mid = mid / (float)m->pos.size();
    float reach = 0.f;
    for (float3 p : m->pos) reach = std::max(reach, length(p - mid));
    // lump is about 0.67 for a ball, 0.38 for a cube and 0.1 for a ring of bar.
    const float lump = usual / (2.f * reach * length(places[0][0].xyz));
    const float longFrom = 1.f + 0.7f * std::min(std::max((lump - 0.3f) / 0.25f, 0.f), 1.f);
    front->setParameter("ior", 1.5f);
    front->setParameter("thickness", 0.8f * usual);
    // What is behind the glass swims in it, exaggerated. At 1 letters melt.
    front->setParameter("swim", 0.5f);
    front->setParameter("usual", usual);
    front->setParameter("longFrom", longFrom);
    // How fast it darkens. At 7 a ring seen edge-on gets two navy bruises. At 3 the dark areas are
    // pale lilac.
    front->setParameter("dark", 4.f);
    // At 14 a yellow haze appears far beside every dark area. At 20 an orange stain runs along
    // every edge.
    front->setParameter("edgeFire", 13.f);
    // At 0.2 the colours turn to blocks.
    front->setParameter("split", 0.10f);
    // Each sample is one colour of the rainbow. 8 samples cost 0.6 ms more.
    front->setParameter("samples", 6.f);
    // Applied after the darkening, so the rainbow at the edge is the most vivid part. From 1.35 up
    // it looks neon.
    front->setParameter("vivid", 1.3f);
    // The glass's own environment light from studio.glsl. It is the same wherever the glass is put.
    front->setParameter("roomGain", 1.f);
    return front;
}

// Adds a matte as After Effects has them: a shape that is not itself visible and that cuts other
// layers. Any mesh can be one: a solid, or a sheet with an image on it from ThorVG. The sheet cuts
// by how opaque the image is, or by its brightness, like the After Effects luma matte. It is an
// entity like any other, so `move` moves it.
// on: where the matte is.
// nullptr: in the project camera's image, as a window on the screen. It cuts by where its shape is
//   seen from the project camera, whatever lies between, and stays in the image while layers move
//   behind it.
// A mesh on the stage: a sticker on that mesh. It rides on the mesh, using Filament's parent and
//   child transforms, and cuts by where its shape lies on the mesh, seen along the mesh's own z
//   axis.
// strength: the most it covers. 0.5 is a half-transparent matte.
// into: an existing matte that this shape joins. A negative value creates a new matte.
// Returns the index of the matte, or -1 on failure.
// Each matte is an image of its own, rendered before everything else (see `draw`) by its own
// camera. That is the project camera, or one riding on the mesh. Only the matte's shapes are in it.
// The layers it cuts look themselves up in it through that camera (matte.glsl), so they are cut the
// same whichever camera views the stage.
static int matte(Stage& s, Mesh* m, std::vector<mat4f> places, Texture* frameTexture = nullptr, bool byLight = false, float strength = 1.f, int into = -1, const Mesh* on = nullptr) {
    auto& tm = s.engine->getTransformManager();
    if (into < 0) {
        Stage::Matte built{};
        // A matte in the project camera's image has twice the resolution of the screen.
        uint32_t w = 2 * (uint32_t)s.w, h = 2 * (uint32_t)s.h;
        built.eye = s.film;
        built.onPlace = mat4f{};
        for (const Stage::Renderable& d : s.renderables) {
            if (!on || d.of != on) continue;
            float3 low = on->pos[0], high = on->pos[0];
            for (const float3& p : on->pos) { low = min(low, p); high = max(high, p); }
            // A camera in front of the mesh, looking along its z axis at all of it, that moves with
            // the mesh.
            utils::Entity e = utils::EntityManager::get().create();
            tm.create(e, tm.getInstance(d.thing), mat4f::translation(float3{0.f, 0.f, high.z + 1.f}));
            built.eye = s.engine->createCamera(e);
            built.eye->setProjection(Camera::Projection::ORTHO, low.x, high.x, low.y, high.y, 0.1, double(high.z - low.z) + 2.0);
            // Pixels per unit chosen so that the longer side has the screen's resolution.
            const float fine = (float)std::max(s.w, s.h) / std::max(high.x - low.x, high.y - low.y);
            w = 2 * (uint32_t)std::lround(0.5f * fine * (high.x - low.x));
            h = 2 * (uint32_t)std::lround(0.5f * fine * (high.y - low.y));
            built.on = d.thing;
            built.onPlace = d.place;
            break;
        }
        uint8_t levels = 1;
        while ((std::max(w, h) >> levels) > 0) ++levels;
        built.frameTexture = Texture::Builder().width(w).height(h).levels(levels).format(Texture::InternalFormat::R8)
                           .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE | Texture::Usage::GEN_MIPMAPPABLE).build(*s.engine);
        built.scene = s.engine->createScene();
        built.view = s.engine->createView();
        built.view->setScene(built.scene);
        built.view->setCamera(built.eye);
        built.view->setViewport({0, 0, w, h});
        built.view->setRenderTarget(RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, built.frameTexture).build(*s.engine));
        built.view->setPostProcessingEnabled(false);
        s.mattes.push_back(built);
        into = (int)s.mattes.size() - 1;
    }
    Stage::Matte& to = s.mattes[(size_t)into];
    MaterialInstance* shape = add(s, m, "matte.filamat", places);
    if (!shape) return -1;
    // Move the shape into the matte's own scene so that it appears in no other image.
    for (size_t i = s.renderables.size() - places.size(); i < s.renderables.size(); ++i) {
        s.scene->remove(s.renderables[i].thing);
        to.scene->addEntity(s.renderables[i].thing);
        s.renderables[i].matte = true;
        if (to.eye == s.film) continue;
        // For a matte on a mesh, the place is relative to that mesh from now on.
        s.renderables[i].place = inverse(to.onPlace) * s.renderables[i].place;
        tm.setParent(tm.getInstance(s.renderables[i].thing), tm.getInstance(to.on));
        tm.setTransform(tm.getInstance(s.renderables[i].thing), s.renderables[i].place);
    }
    shape->setParameter("picture", frameTexture ? frameTexture : white_point(s), TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
    shape->setParameter("byLight", byLight ? 1.f : 0.f);
    shape->setParameter("strength", strength);
    // A solid draws its near faces only, so that it covers once.
    if (!frameTexture) shape->setCullingMode(backend::CullingMode::BACK);
    return into;
}

// Cuts the layer with material instance `look` by matte number `matte`. The layer is visible only
// inside the matte, or only outside it when `inside` is false.
// soft: how far the edge is blurred, in screen pixels, or in pixels of the matte's own image if the
// matte is on a mesh. 0 is as sharp as the matte.
// Up to four mattes can cut one layer, by calling again. Only what all of them leave is visible.
// Returns false if the material cannot be cut because it does not read mattes (see matte.glsl), or
// if four mattes already cut it.
static bool matted(Stage& s, MaterialInstance* look, int matte, bool inside = true, float soft = 0.f) {
    static const char* const names[] = {"matte0", "matte1", "matte2", "matte3"};
    // Collect what already cuts this material instance from the stage's list.
    float4 use{0.f}, softs{0.f};
    int n = 0;
    for (const Stage::Cut& c : s.cuts)
        if (c.look == look) use[c.slot] = c.use, softs[c.slot] = c.soft, ++n;
    if (n == 4 || !look->getMaterial()->hasParameter("matteUse")) return false;
    look->setParameter(names[n], s.mattes[(size_t)matte].frameTexture,
                       TextureSampler(TextureSampler::MinFilter::LINEAR_MIPMAP_LINEAR, TextureSampler::MagFilter::LINEAR, TextureSampler::WrapMode::CLAMP_TO_EDGE));
    use[n] = inside ? 1.f : -1.f;
    // A mip level of the matte's image. Each level is half the size of the one before.
    softs[n] = std::log2(1.f + 2.f * std::max(soft, 0.f));
    look->setParameter("matteUse", use);
    look->setParameter("matteSoft", softs);
    if (soft > 0.f) s.mattes[(size_t)matte].soft = true;
    s.cuts.push_back({look, n, matte, use[n], softs[n]});
    return true;
}

// Switches the stage between the project camera and a second, free camera. When `on` is true the
// stage is viewed through the free camera (`camera`), like standing beside a set and watching. The
// project camera (`film`) keeps rendering the mattes that are in its image. When `on` is false the
// project camera is used again. Returns the camera now in use.
static Camera* god_view(Stage& s, bool on) {
    if (on && !s.god) {
        s.god = s.engine->createCamera(utils::EntityManager::get().create());
        s.god->setExposure(16.0f, 1.0f / 125.0f, 100.0f);
    }
    if (Camera* eye = on ? s.god : s.film; eye != s.camera) {
        s.camera = eye;
        for (View* v : {s.view, s.view_behind, s.view_through})
            if (v) v->setCamera(s.camera);
    }
    return s.camera;
}

// Sets the stage's time to `seconds`. Everything that advances by itself is moved to that time for
// the next frame drawn.
static void time_is(Stage& s, double seconds) {
    // A project with a given frame rate is seen only at whole frames, as with the project frame
    // rate in Alight Motion and the composition frame rate in After Effects.
    s.now = s.frames > 0.0 ? std::floor(seconds * s.frames + 1e-6) / s.frames : seconds;
    seconds = s.now;
    // Copy the keys first and look each one up again before calling it, because a callback can
    // recreate or remove entries while this loop runs. See doc_evaluate.
    std::vector<const void*> all;
    for (const auto& [who, goes] : s.playing) all.push_back(who);
    for (const void* who : all)
        if (const auto it = s.playing.find(who); it != s.playing.end()) it->second(seconds);
}

// Begins a frame (Filament's beginFrame). Returns false if this frame is to be skipped.
// Filament uploads material parameters when a frame begins, so the view-projection matrix of each
// matte's camera is set just before. Nothing else is passed.
static bool begins(Stage& s) {
    static const char* const eyes[] = {"matteEye0", "matteEye1", "matteEye2", "matteEye3"};
    // Aim the layers that have effects of their own and set the parameters of their material
    // instances, see layer_fx.h. This is the same as Filament's sample rendertarget.cpp, which aims
    // its offscreen camera before the frame.
    for (const auto& one : s.aim) one();
    for (const Stage::Cut& c : s.cuts) {
        const Camera* eye = s.mattes[(size_t)c.matte].eye;
        c.look->setParameter(eyes[c.slot], mat4f(eye->getProjectionMatrix() * eye->getViewMatrix()));
    }
    return s.renderer->beginFrame(s.swap);
}

// Renders all the images of one frame, the helper images first. This runs between Filament's
// beginFrame and endFrame. Every way of drawing the stage goes through here.
static void textures_of(Stage& s) {
    // The image of what is behind, for an effect that reads it as its backdrop, see screen_fx.h. It
    // is drawn before the effects, without the layers' own sheets.
    if (s.backdropRead) s.renderer->render(s.view_behind);
    for (const auto& [of, one] : s.once) one();
    s.once.clear();
    // Layers with effects of their own are each drawn alone first, as FilamentApp draws its
    // offscreen views before all others, see layer_fx.h.
    for (const auto& one : s.before) one();
    for (Stage::Matte& m : s.mattes) {
        s.renderer->render(m.view);
        if (m.soft) m.frameTexture->generateMipmaps(*s.engine);
    }
    // The image of what is behind is drawn only once glass or paper reads it, because it is a whole
    // pass over the points of every entity.
    if (s.behindRead) s.renderer->render(s.view_behind);
    if (s.view_through) s.renderer->render(s.view_through);
    // A single view, because everything is in the stage's own scene.
    s.renderer->render(s.view);
    for (const auto& one : s.after) one();
    if (s.over) s.over();
    if (s.lastly) s.lastly();
}

// Draws one frame of the stage, the helper images first. If `pic` is given, the image is read back
// into it as RGBA bytes. If `wait` is true, returns only after the GPU has finished.
static void draw(Stage& s, std::vector<uint8_t>* pic = nullptr, bool wait = true) {
    while (!begins(s)) {}
    textures_of(s);
    if (pic)
        s.renderer->readPixels(0, 0, (uint32_t)s.w, (uint32_t)s.h,
                               backend::PixelBufferDescriptor(pic->data(), pic->size(), backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE));
    s.renderer->endFrame();
    if (wait) s.engine->flushAndWait();
}


// Removes from the stage for good every entity made from mesh `m`.
static void take_off(Stage& s, const Mesh* m) {
    auto& looks = s.engine->getRenderableManager();
    MaterialInstance* look = nullptr;
    for (size_t i = s.renderables.size(); i-- > 0;) {
        if (s.renderables[i].of != m) continue;
        look = looks.getMaterialInstanceAt(looks.getInstance(s.renderables[i].thing), 0);
        s.scene->remove(s.renderables[i].thing);
        s.engine->destroy(s.renderables[i].thing);
        // The instance buffer is destroyed after the entity that draws with it.
        if (s.renderables[i].many) s.engine->destroy(s.renderables[i].many);
        s.renderables.erase(s.renderables.begin() + (long)i);
    }
    if (!look) return;
    // No matte camera matrix is set on it any more.
    std::erase_if(s.cuts, [look](const Stage::Cut& c) { return c.look == look; });
    // The material instance goes with its entities.
    s.engine->destroy(look);
}

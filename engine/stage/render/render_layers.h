// render_layers.h: part of render.h. Read only through render.h.


// How deep a solid is as a rule: four times its volume over its surface (a ball: two thirds of its width; a bar: its
// width; a sheet: twice its thickness). What the glasses below take their depth from, so that a scene gives none.
static float usual_depth(const Mesh* m) {
    double volume = 0, surface = 0;
    for (size_t i = 0; i + 2 < m->idx.size(); i += 3) {
        const float3 a = m->pos[m->idx[i]], b = m->pos[m->idx[i + 1]], c = m->pos[m->idx[i + 2]];
        volume += dot(a, cross(b, c)) / 6.0;
        surface += length(cross(b - a, c - a)) / 2.0;
    }
    return (float)(4.0 * std::fabs(volume) / surface);
}

// Glass by Filament's own means (own_glass.mat: its refraction, absorption, dispersion and mirroring of the room),
// put down as it comes: its depth is the mesh's own. colour: what white light is left as after a usual depth of
// this glass ({1, 1, 1}: clear). crushed: how far its faces lean this way and that (0: smooth).
// Thin, bent solids (blades, ribbons, sheets) read well in it; it does not show its own far side as thick_glass does.
static MaterialInstance* own_glass(Stage& s, Mesh* m, std::vector<mat4f> places, float3 colour = float3{1.f}, float crushed = 0.f) {
    MaterialInstance* mi = add(s, m, "own_glass.filamat", places, 2);
    if (!mi) return nullptr;
    const float deep = 8.f * usual_depth(m) * length(places[0][0].xyz);   // (overdone eight times: what is behind swims in it)
    mi->setParameter("thickness", deep);
    mi->setParameter("absorb", float3{-std::log(std::max(colour.x, 1e-3f)), -std::log(std::max(colour.y, 1e-3f)), -std::log(std::max(colour.z, 1e-3f))} / deep);
    mi->setParameter("lean", crushed);
    mi->setParameter("film", 0.f);
    mi->setParameter("split", 0.5f);
    return mi;
}

// A solid worn by one of the renderer's materials of its own (Create's Material group, doc.h doc_material): Filament's own
// glass (own_glass, above: ior its bend, split how far its colours part, swim how far its faces lean, vivid its thin
// film's rainbow, dark how deep its colour), lacquer (blade.mat: its colour dark at the root, as it is at the tip, under
// a hard clear coat; metal 0 lacquer, 1 steel) or a bubble (bubble.mat: vivid how bright its rim). tone: its colour.
static MaterialInstance* solid_wear(Stage& s, Mesh* m, std::vector<mat4f> places, const std::string& wears, float3 tone, float ior, float split, float swim, float dark, float vivid, float metal) {
    MaterialInstance* mi = nullptr;
    if (wears == "filament_glass") {
        const float3 left = float3{std::pow(tone.x, 0.25f * dark), std::pow(tone.y, 0.25f * dark), std::pow(tone.z, 0.25f * dark)};   // (dark 4: its colour itself)
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

// Glass seen through both of its sides (thick_glass.mat): the mesh at its places, drawn three times. Its far faces go
// into a picture of their own, which way they face and how far away they are (far_side.mat; nothing else is in that
// picture), and as they look from within over the picture of the scene without the glass (far_look.mat);
// its near faces, on the screen, bend the eye's way in, look the far face up there, and bend it out again to the scene.
// The first call makes the picture. Nothing is asked of the caller: the glass is put down as it comes.
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
    MaterialInstance* look = add(s, m, "far_look.filamat", places, 16);   // (layer 16: only in the picture of the scene without the glass)
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
    // How deep the solid is as a rule: four times its volume over its surface (a ball: two thirds of its width; a bar:
    // its width; a sheet: twice its thickness). Worked out once, here; a way through the glass much longer than this
    // is the glass seen along itself, and goes dark.
    const float usual = usual_depth(m) * length(places[0][0].xyz);
    // A bar or a sheet has places where it is seen along itself; a lump (a ball, a gem) has none: its longest way is
    // straight through its middle, about one and a half times `usual`. So the nearer to a lump the solid is (how deep
    // against how far it reaches), the longer a way must be before it counts as long: the middle of a gem stays clear.
    float3 mid{0.f};
    for (float3 p : m->pos) mid += p;
    mid = mid / (float)m->pos.size();
    float reach = 0.f;
    for (float3 p : m->pos) reach = std::max(reach, length(p - mid));
    const float lump = usual / (2.f * reach * length(places[0][0].xyz));   // (a ball: 0.67; a cube: 0.38; a ring of bar: about 0.1)
    const float longFrom = 1.f + 0.7f * std::min(std::max((lump - 0.3f) / 0.25f, 0.f), 1.f);
    front->setParameter("ior", 1.5f);
    front->setParameter("thickness", 0.8f * usual);
    front->setParameter("swim", 0.5f);       // (what is behind the glass swims in it, overdone; at 1 letters melt)
    front->setParameter("usual", usual);
    front->setParameter("longFrom", longFrom);
    front->setParameter("dark", 4.f);        // (how fast: at 7 a ring seen edge-on carries two navy bruises; at 3 the darks are pale lilac)
    front->setParameter("edgeFire", 13.f);   // (14: a yellow haze far beside every dark; 20: an orange stain along every edge)
    front->setParameter("split", 0.10f);     // (0.2: the colours turn to blocks)
    front->setParameter("samples", 6.f);     // (each one colour of the rainbow; 8: 0.6 ms dearer)
    front->setParameter("vivid", 1.3f);      // (laid on after the dark, so the rainbow at its edge is the most vivid thing; 1.35 and up: neon)
    front->setParameter("roomGain", 1.f);    // (the glass's own room, studio.glsl: the same wherever the glass is put)
    return front;
}

// A matte, as After Effects has them: a shape that is not seen itself and cuts other things. Any mesh is one: a solid,
// or a sheet with a picture on it (ThorVG's), which cuts by how clear the picture is, or by its light (After Effects'
// luma matte). It is a thing like any other: `move` moves it.
// on: where the matte is. nullptr: in the film's picture, a window on the screen: it cuts by where its shape is seen
// from the film's camera, whatever lies between, and stays in the picture while things move behind it. A mesh on the
// stage: on that thing, a sticker: it rides on the thing (Filament's own parent and child) and cuts by where its
// shape lies on it, seen along the thing's own z.
// strength: how much it covers at most (a half-clear matte). into: a matte made before, which this shape joins.
// What comes back names the matte. Each matte is a picture of its own, taken before all else (`draw`) by its own eye,
// the film's camera or one riding on the thing, with nothing but its shapes in it; the things it cuts look themselves
// up in it by that eye (matte.glsl), so they are cut the same whichever eye looks at the stage.
static int matte(Stage& s, Mesh* m, std::vector<mat4f> places, Texture* frameTexture = nullptr, bool byLight = false, float strength = 1.f, int into = -1, const Mesh* on = nullptr) {
    auto& tm = s.engine->getTransformManager();
    if (into < 0) {
        Stage::Matte built{};
        uint32_t w = 2 * (uint32_t)s.w, h = 2 * (uint32_t)s.h;   // (in the film's picture: twice as fine as the screen)
        built.eye = s.film;
        built.onPlace = mat4f{};
        for (const Stage::Renderable& d : s.renderables) {
            if (!on || d.of != on) continue;
            float3 low = on->pos[0], high = on->pos[0];
            for (const float3& p : on->pos) { low = min(low, p); high = max(high, p); }
            // an eye before the thing, looking along its z at all of it, and going where it goes
            utils::Entity e = utils::EntityManager::get().create();
            tm.create(e, tm.getInstance(d.thing), mat4f::translation(float3{0.f, 0.f, high.z + 1.f}));
            built.eye = s.engine->createCamera(e);
            built.eye->setProjection(Camera::Projection::ORTHO, low.x, high.x, low.y, high.y, 0.1, double(high.z - low.z) + 2.0);
            const float fine = (float)std::max(s.w, s.h) / std::max(high.x - low.x, high.y - low.y);   // (its longer side as fine as the screen's)
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
    for (size_t i = s.renderables.size() - places.size(); i < s.renderables.size(); ++i) {   // (its shape is in the matte's own scene, and in no other picture)
        s.scene->remove(s.renderables[i].thing);
        to.scene->addEntity(s.renderables[i].thing);
        s.renderables[i].matte = true;
        if (to.eye == s.film) continue;
        s.renderables[i].place = inverse(to.onPlace) * s.renderables[i].place;   // (on a thing: its place is told from the thing from now on)
        tm.setParent(tm.getInstance(s.renderables[i].thing), tm.getInstance(to.on));
        tm.setTransform(tm.getInstance(s.renderables[i].thing), s.renderables[i].place);
    }
    shape->setParameter("picture", frameTexture ? frameTexture : white_point(s), TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
    shape->setParameter("byLight", byLight ? 1.f : 0.f);
    shape->setParameter("strength", strength);
    if (!frameTexture) shape->setCullingMode(backend::CullingMode::BACK);   // (a solid: its near faces only, so that it covers once)
    return into;
}

// The thing with this look is cut by that matte: seen only inside it (or only outside it). soft: how far the edge is
// blurred, in pixels of the screen (of the matte's own picture, if it is on a thing; 0: as sharp as the matte is). Up to four mattes cut one thing (call again): what
// all of them leave is seen. false: the look's material cannot be cut (it does not read mattes: matte.glsl), or four cut it already.
static bool matted(Stage& s, MaterialInstance* look, int matte, bool inside = true, float soft = 0.f) {
    static const char* const names[] = {"matte0", "matte1", "matte2", "matte3"};
    float4 use{0.f}, softs{0.f};   // (what cuts this look already: the stage's own list says)
    int n = 0;
    for (const Stage::Cut& c : s.cuts)
        if (c.look == look) use[c.slot] = c.use, softs[c.slot] = c.soft, ++n;
    if (n == 4 || !look->getMaterial()->hasParameter("matteUse")) return false;
    look->setParameter(names[n], s.mattes[(size_t)matte].frameTexture,
                       TextureSampler(TextureSampler::MinFilter::LINEAR_MIPMAP_LINEAR, TextureSampler::MagFilter::LINEAR, TextureSampler::WrapMode::CLAMP_TO_EDGE));
    use[n] = inside ? 1.f : -1.f;
    softs[n] = std::log2(1.f + 2.f * std::max(soft, 0.f));   // (a level of the matte's picture: each is twice as coarse as the one before)
    look->setParameter("matteUse", use);
    look->setParameter("matteSoft", softs);
    if (soft > 0.f) s.mattes[(size_t)matte].soft = true;
    s.cuts.push_back({look, n, matte, use[n], softs[n]});
    return true;
}

// Another eye on the stage than the film's camera: on, the stage is looked at through it (`camera`), as one stands beside
// a set and watches; the film's own camera (`film`) goes on taking the mattes that are in the film's picture. Off, the film's again.
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

// Three frames, the last one read back and written as a .png.
// One picture of the stage drawn (the helper pictures first), and read back into `pic` if one is given.
// The stage's time set: everything that goes on by itself is at that moment for the picture drawn next.
static void time_is(Stage& s, double seconds) {
    s.now = s.frames > 0.0 ? std::floor(seconds * s.frames + 1e-6) / s.frames : seconds;   // (a document of so many frames a second is seen only at them: Alight Motion's project frame rate, After Effects' composition's)
    seconds = s.now;
    std::vector<const void*> all;   // (each by its key, looked for again as it comes: one may make things again, and take some off, as it goes (doc_evaluate))
    for (const auto& [who, goes] : s.playing) all.push_back(who);
    for (const void* who : all)
        if (const auto it = s.playing.find(who); it != s.playing.end()) it->second(seconds);
}

// A frame begins (Filament's beginFrame: false if this one is to be left out). What the looks are told is sent on
// as a frame begins, so each matte's eye is told just before: where it is now, a pose handed over, nothing more.
static bool begins(Stage& s) {
    static const char* const eyes[] = {"matteEye0", "matteEye1", "matteEye2", "matteEye3"};
    for (const auto& one : s.aim) one();   // (the things with effects of their own aimed, their looks told: layer_fx.h; as samples/rendertarget.cpp aims its offscreen camera before the frame)
    for (const Stage::Cut& c : s.cuts) {
        const Camera* eye = s.mattes[(size_t)c.matte].eye;
        c.look->setParameter(eyes[c.slot], mat4f(eye->getProjectionMatrix() * eye->getViewMatrix()));
    }
    return s.renderer->beginFrame(s.swap);
}

// All the pictures of one frame, the helper pictures first (between Filament's beginFrame and endFrame). Every way
// of drawing the stage goes through here.
static void textures_of(Stage& s) {
    if (s.backdropRead) s.renderer->render(s.view_behind);   // (what is behind, for an effect that reads it (screen_fx.h's backdrop): drawn before the effects, those things' own sheets left out of it)
    for (const auto& [of, one] : s.once) one();
    s.once.clear();
    for (const auto& one : s.before) one();   // (the things with effects of their own, each drawn alone first, as FilamentApp draws its offscreen views before every other: layer_fx.h)
    for (Stage::Matte& m : s.mattes) {
        s.renderer->render(m.view);
        if (m.soft) m.frameTexture->generateMipmaps(*s.engine);
    }
    if (s.behindRead) s.renderer->render(s.view_behind);   // (the picture of what is behind: only once glass or the paper reads it; a whole pass of every thing's points)
    if (s.view_through) s.renderer->render(s.view_through);
    s.renderer->render(s.view);   // (one view: everything is in the stage's own scene)
    for (const auto& one : s.after) one();
    if (s.over) s.over();
    if (s.lastly) s.lastly();
}

static void draw(Stage& s, std::vector<uint8_t>* pic = nullptr, bool wait = true) {
    while (!begins(s)) {}
    textures_of(s);
    if (pic)
        s.renderer->readPixels(0, 0, (uint32_t)s.w, (uint32_t)s.h,
                               backend::PixelBufferDescriptor(pic->data(), pic->size(), backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE));
    s.renderer->endFrame();
    if (wait) s.engine->flushAndWait();
}


// The things made of mesh `m` taken off the stage for good.
static void take_off(Stage& s, const Mesh* m) {
    auto& looks = s.engine->getRenderableManager();
    MaterialInstance* look = nullptr;
    for (size_t i = s.renderables.size(); i-- > 0;) {
        if (s.renderables[i].of != m) continue;
        look = looks.getMaterialInstanceAt(looks.getInstance(s.renderables[i].thing), 0);
        s.scene->remove(s.renderables[i].thing);
        s.engine->destroy(s.renderables[i].thing);
        if (s.renderables[i].many) s.engine->destroy(s.renderables[i].many);   // (after the thing that draws by it)
        s.renderables.erase(s.renderables.begin() + (long)i);
    }
    if (!look) return;
    std::erase_if(s.cuts, [look](const Stage::Cut& c) { return c.look == look; });   // (no matte's eye is told to it any more)
    s.engine->destroy(look);   // (its look goes with it)
}

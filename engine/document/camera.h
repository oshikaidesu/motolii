// camera.h: part of doc.h (where a camera looks from; the stage's eye, light and backdrop as the document says). Read only through doc.h.
// Where a camera looks from (none: the stage's own eye): it looks at where it is, from round about it as it is turned
// (y: about, x: up and down, z: its lean), `distance` times the stage's own way off, `zoom` times as near.
struct DocViewCamera { math::mat4 round; math::double3 look, eye, up; double far, fov; };
static DocViewCamera doc_view_camera_of(Doc& d, int camera, double now) {
    const auto turned = [&](const char* name, math::double3 about) { return camera ? math::mat4::rotation(doc_number(d, camera, name, now, 0) * (double)TAU / 360.0, about) : math::mat4{}; };
    DocViewCamera e;
    e.round = turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0}) * turned("rotate", {0, 0, 1});
    e.look = camera ? (doc_place(d, camera, now) * math::double4{0, 0, 0, 1}).xyz : math::double3{0.0};
    e.far = camera ? doc_number(d, camera, "distance", now, 1) : 1.0;
    e.fov = 2.0 * std::atan(std::tan(15.0 * (double)TAU / 360.0) / (camera ? doc_number(d, camera, "zoom", now, 1) : 1.0));
    e.eye = e.look + (e.round * math::double4{0, 0, 6.0 * e.far, 0}).xyz, e.up = (e.round * math::double4{0, 1, 0, 0}).xyz;
    return e;
}
static void doc_look(Doc& d) {
    Stage& s = *d.stage;
    const auto hex = [&](const char* name, float3 otherwise) { const std::string w = doc_word(d, 0, name); return w.size() == 6 ? float3{(float)((std::strtol(w.c_str(), nullptr, 16) >> 16) & 255), (float)((std::strtol(w.c_str(), nullptr, 16) >> 8) & 255), (float)(std::strtol(w.c_str(), nullptr, 16) & 255)} / 255.f : otherwise; };
    const std::string mapper = doc_word(d, 0, "tone_mapper");
    char grade[300];
    const float slope = (float)doc_number(d, 0, "slope", 0, 1), offset = (float)doc_number(d, 0, "offset", 0, 0), power = (float)doc_number(d, 0, "power", 0, 1);
    std::snprintf(grade, sizeof grade, "%s %g %g %g %g %g %g %g %g", mapper.c_str(), doc_number(d, 0, "exposure", 0, 0), doc_number(d, 0, "contrast", 0, 1), doc_number(d, 0, "saturation", 0, 1), doc_number(d, 0, "vibrance", 0, 1), doc_number(d, 0, "temperature", 0, 0), slope, offset, power);
    const auto tint = [&](const char* name) { const float3 c = hex(name, float3{1.f}); std::strncat(grade, (" " + doc_word(d, 0, name)).c_str(), 20); return float4{Color::toLinear<ACCURATE>(sRGBColor{c}), 0.f}; };
    const float4 low = tint("shadows_color"), mid = tint("midtones_color"), high = tint("highlights_color");
    std::vector<std::string> told;   // (Filament's own settings files, their knobs' values put in: viewer_settings.h; the whole view's, on the stage or on any layer's effects, as the shelf puts them)
    std::vector<int> holders{0};
    doc_rows(d, sqlite3_mprintf("select distinct layer from keyframe where name = 'fx' and value like '%%.json%%'"), [&](sqlite3_stmt* row) { holders.push_back(sqlite3_column_int(row, 0)); });
    for (const int h : holders)
        for (const std::string& file : script_files(doc_word(d, h, h == 0 ? "script" : "fx")))
            if (DocScript* sc = doc_script_of(d, file); sc && sc->viewer)
                told.push_back(viewer_said(file, sc->knobs, [&](size_t k) { return doc_number(d, h, sc->names[k].c_str(), s.now, sc->knobs[k].usual); }));
    const bool theirs = std::any_of(told.begin(), told.end(), [](const std::string& t) { return t.find("\"colorGrading\"") != std::string::npos; });
    std::string key = grade;
    if (theirs) for (const std::string& t : told) key += t;
    if (d.graded != key) {
        static LinearToneMapper linear; static ACESToneMapper aces; static FilmicToneMapper filmic; static AgxToneMapper agx; static PBRNeutralToneMapper neutral;
        const ToneMapper* tm = mapper == "aces" ? (const ToneMapper*)&aces : mapper == "filmic" ? (const ToneMapper*)&filmic : mapper == "agx" ? (const ToneMapper*)&agx : mapper == "pbr_neutral" ? (const ToneMapper*)&neutral : (const ToneMapper*)&linear;
        ColorGrading* was = const_cast<ColorGrading*>(s.view->getColorGrading());
        ColorGrading* now = nullptr;
        if (theirs) {   // (a file's grading is the whole grading, made as Filament's viewer makes it)
            filament::viewer::Settings in;
            filament::viewer::JsonSerializer read;
            for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
            now = filament::viewer::createColorGrading(in.view.colorGrading, s.engine);
        } else
            now = ColorGrading::Builder().toneMapper(tm).exposure((float)doc_number(d, 0, "exposure", 0, 0)).contrast((float)doc_number(d, 0, "contrast", 0, 1))
                                .saturation((float)doc_number(d, 0, "saturation", 0, 1)).vibrance((float)doc_number(d, 0, "vibrance", 0, 1)).whiteBalance((float)doc_number(d, 0, "temperature", 0, 0), 0.f)
                                .slopeOffsetPower(float3{slope}, float3{offset}, float3{power})
                                .shadowsMidtonesHighlights(low, mid, high, float4{0.f, 0.333f, 0.55f, 1.f}).build(*s.engine);   // (the ranges as Filament's own)
        s.view->setColorGrading(now);
        if (was) s.engine->destroy(was);
        d.graded = key;
    }
    View::BloomOptions glow = s.view->getBloomOptions();
    glow.enabled = doc_number(d, 0, "bloom", 0, 0) > 0.0, glow.strength = (float)doc_number(d, 0, "bloom", 0, 0);
    glow.lensFlare = glow.starburst = doc_number(d, 0, "lens_flare", 0, 0) > 0.0;
    glow.enabled = glow.enabled || glow.lensFlare;   // (a flare is drawn by the glow's own passes)
    glow.chromaticAberration = 0.005f * (float)doc_number(d, 0, "lens_flare", 0, 0), glow.ghostThreshold = glow.haloThreshold = 1.f;
    s.view->setBloomOptions(glow);
    const std::string smooth = doc_word(d, 0, "anti_aliasing");   // (on every picture laid: each smooths its own edges)
    for (View* v : std::vector<View*>{s.view}) {
        v->setAntiAliasing(smooth.empty() || smooth == "fxaa" ? View::AntiAliasing::FXAA : View::AntiAliasing::NONE);
        View::TemporalAntiAliasingOptions taa = v->getTemporalAntiAliasingOptions();
        taa.enabled = smooth == "taa";
        v->setTemporalAntiAliasingOptions(taa);
    }
    View::MultiSampleAntiAliasingOptions many = s.view->getMultiSampleAntiAliasingOptions();
    many.enabled = smooth == "msaa", many.sampleCount = 4;
    s.view->setMultiSampleAntiAliasingOptions(many);
    View::VignetteOptions corners = s.view->getVignetteOptions();
    corners.enabled = doc_number(d, 0, "vignette", 0, 0) > 0.0, corners.midPoint = 1.f - 0.9f * (float)doc_number(d, 0, "vignette", 0, 0), corners.color = LinearColorA{hex("vignette_color", float3{0.f}), 1.f};
    s.view->setVignetteOptions(corners);
    View::FogOptions haze = s.view->getFogOptions();
    const int fogBy = d.looking && doc_number(d, d.looking, "fog", 0, 0) > 0.0 ? d.looking : 0;   // (the camera seen through, if it says a fog of its own (Alight Motion's camera's Fog); else the stage's)
    const std::string fogColour = doc_word(d, fogBy, "fog_color");
    haze.enabled = !d.working && doc_number(d, fogBy, "fog", 0, 0) > 0.0, haze.density = 0.5f * (float)doc_number(d, fogBy, "fog", 0, 0), haze.distance = (float)doc_number(d, fogBy, "fog_near", 0, 2), haze.height = -1e3f, haze.heightFalloff = 0.f,
    haze.color = fogColour.size() == 6 ? float3{(float)((std::strtol(fogColour.c_str(), nullptr, 16) >> 16) & 255), (float)((std::strtol(fogColour.c_str(), nullptr, 16) >> 8) & 255), (float)(std::strtol(fogColour.c_str(), nullptr, 16) & 255)} / 255.f : float3{0.85f, 0.85f, 0.9f}, haze.fogColorFromIbl = false;
    if (const double far = doc_number(d, fogBy, "fog_far", 0, 0); far > haze.distance)   // (a far said, Alight Motion's: as thick as makes it 98% whole there, its fog times that (1 - e^-(density x the way past its start): Filament's own fog, uniform in height); as three.js's linear Fog's far set on its FogExp2)
        haze.density = (float)(doc_number(d, fogBy, "fog", 0, 0) * std::log(50.0) / (far - haze.distance));
    s.view->setFogOptions(haze);
    View::AmbientOcclusionOptions folds = s.view->getAmbientOcclusionOptions();
    folds.enabled = doc_number(d, 0, "ambient_occlusion", 0, 0) > 0.0, folds.intensity = 2.f * (float)doc_number(d, 0, "ambient_occlusion", 0, 0);
    s.view->setAmbientOcclusionOptions(folds);
    View::ScreenSpaceReflectionsOptions mirror = s.view->getScreenSpaceReflectionsOptions();
    mirror.enabled = doc_number(d, 0, "reflections", 0, 0) > 0.0;
    s.view->setScreenSpaceReflectionsOptions(mirror);
    if (!told.empty()) {   // (Filament's own settings over the stage's: begun from what the view has, so a part a file does not name stays)
        filament::viewer::Settings in;
        in.view.bloom = s.view->getBloomOptions(), in.view.vignette = s.view->getVignetteOptions(), in.view.fog = s.view->getFogOptions();
        in.view.ssao = s.view->getAmbientOcclusionOptions(), in.view.screenSpaceReflections = s.view->getScreenSpaceReflectionsOptions();
        filament::viewer::JsonSerializer read;
        for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
        s.view->setBloomOptions(in.view.bloom), s.view->setVignetteOptions(in.view.vignette), s.view->setFogOptions(in.view.fog);
        s.view->setAmbientOcclusionOptions(in.view.ssao), s.view->setScreenSpaceReflectionsOptions(in.view.screenSpaceReflections);
    }
    if (d.roomLight <= 0.f && s.scene->getIndirectLight()) d.roomLight = s.scene->getIndirectLight()->getIntensity();
    std::string which = doc_word(d, 0, "room");
    if (which.empty()) which = "small_studio";   // (as the stage was opened)
    if (which != d.roomIs) {   // (another room: made once from its file, then kept; every picture laid over the stage's own is lit by it too)
        static std::map<std::string, IndirectLight*> made;
        if (!d.roomIs.empty() || made.empty()) made.emplace(d.roomIs.empty() ? "small_studio" : d.roomIs, s.scene->getIndirectLight());
        const auto found = made.find(which);
        if (found != made.end()) s.scene->setIndirectLight(found->second);
        else if (room(s, ("out/" + which + "/" + which + "_ibl.ktx").c_str(), d.roomLight)) made[which] = s.scene->getIndirectLight();
        d.roomIs = which;
    }
    if (IndirectLight* room = s.scene->getIndirectLight()) {
        room->setIntensity(d.roomLight * (float)doc_number(d, 0, "environment", 0, 1));
        room->setRotation(math::mat3f::rotation((float)(doc_number(d, 0, "environment_rotate", 0, 0) * (double)TAU / 360.0), math::float3{0, 1, 0}));
    }
    d.screen.sounds = [&d](const std::string& file, const std::string& name, bool fft, int wide) { return doc_sound_now(d, 0, file, name, fft, wide); };
    screen_effects(s, d.screen, doc_word(d, 0, "script"), [&d](const std::string& file, const std::string& name, double usual) {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn, when the hand does not hold it)
        // (a mouse's knob, where the followed layer is on the picture: pointer as the web says it, -1 to 1 and up; the
        //  others from the top left, 0 to 1, as the effects' own uv)
        static const char* const mice[] = {"pointer", "center", "mouse", "point"};
        if (const int t = (int)doc_number(d, 0, "follow", 0, 0); t > 0 && name.size() > 2 && name[name.size() - 2] == '_')
            for (const char* mouse : mice)
                if (name.compare(0, name.size() - 2, mouse) == 0) {
                    double frame[8];
                    if (!doc_knows(d, t, nullptr, nullptr, nullptr, false) || !doc_frame(d, t, d.stage->now, frame)) break;
                    const bool across = name.back() == 'x';
                    const double at = across ? frame[0] / d.stage->w : frame[1] / d.stage->h;
                    return !strcmp(mouse, "pointer") ? (across ? 2.0 * at - 1.0 : 1.0 - 2.0 * at) : at;
                }
        if (name == "clip_time") return d.stage->now;   // (the stage's own clock and length: the document's)
        if (name == "clip_length") return doc_seconds(d);
        return doc_number(d, 0, doc_screen_knob(file, name).c_str(), d.stage->now, usual);
    });
    const std::string behind = doc_word(d, 0, "background");
    if (doc_word(d, 0, "behind") == "room") {   // (the room itself behind everything, as bright as it lights the stage: its own picture, made once a room)
        static std::map<std::string, Skybox*> shown;
        Skybox*& sky = shown[d.roomIs];
        if (!sky) {
            static std::vector<std::vector<uint8_t>> kept;
            kept.push_back(load_file(("out/" + d.roomIs + "/" + d.roomIs + "_skybox.ktx").c_str()));
            if (!kept.back().empty())
                if (Texture* tex = ktxreader::Ktx1Reader::createTexture(s.engine, new image::Ktx1Bundle(kept.back().data(), (uint32_t)kept.back().size()), false))
                    sky = Skybox::Builder().environment(tex).intensity(d.roomLight).showSun(true).build(*s.engine);   // (a sun among the lights: its disk in it)   // (Filament's sky takes its brightness as it is made)
        }
        if (sky) sky->setLayerMask(0xFF, 0x01);
        s.scene->setSkybox(sky);
    } else s.scene->setSkybox(nullptr);
    // A colour behind everything: a flat colour as large as the stage, stuck to the eye, drawn first in the stage's own
    // view and writing no depth, so every layer is drawn over it (Filament's sky is drawn after the layers it holds, and
    // a flat layer writes no depth, so a sky painted over them). It is opaque: Filament draws blended sheets after every
    // solid layer whatever their priority, so a blended backdrop was painted over the solids.
    const std::string colour = doc_word(d, 0, "behind") == "room" ? "" : behind;
    if (colour != d.backdropIs) {
        if (d.backdrop) picture_off(s, d.backdrop), d.backdrop = nullptr;
        if (!colour.empty()) {
            const math::double4 up = s.camera->getProjectionMatrix() * s.camera->getViewMatrix() * math::double4{0, 1, 0, 1};
            if ((d.backdrop = flat(s, "rect", (float)s.w / (float)s.h, mat4f{}, (float)(2.0 * up.w / up.y), hex("background", float3{0.f}), "opaque"))) {   // (opaque: Filament draws it with the solid layers, first by its priority, not over them with the sheets)
                auto& faces = s.engine->getRenderableManager();
                for (const Stage::Made& made : s.made)
                    if (made.of == d.backdrop->sheet) faces.setPriority(faces.getInstance(made.thing), 0), faces.setChannel(faces.getInstance(made.thing), 0);
                d.backdrop->look->setDepthWrite(false), d.backdrop->look->setDepthCulling(false);
            }
        }
        d.backdropIs = colour;
    }
    if (d.backdrop) move(s, d.backdrop->sheet, [&](int, const mat4f&) { return mat4f(d.rig); });
}


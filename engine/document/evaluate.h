// evaluate.h: part of doc.h (the stage told a moment). Read only through doc.h.
static int doc_bevel(Doc& d, int layer);
static void doc_evaluate(Doc& d, double now) {
    Stage& s = *d.stage;
    d.halves.clear(), d.talls.clear();   // (made again since: a flat layer's sheet is as large as its picture now)
    d.placing.clear(), d.evaluating = true;   // (nothing in the document changes while the stage is told a moment: what a layer's copies each ask, asked once)
    struct Told { Doc& d; ~Told() { d.evaluating = false, d.placing.clear(); } } told{d};
    if (now == s.now)   // (a text whose words AbsentMotion's text effects change as time goes, its Timecode or Count Up: told them in its own picture (words_at),
        for (auto& [layer, t] : d.shown)   //  or, wider than it, made again as they read now, it alone (doc_match), then seen)
            if (t.wordsMove)
                if (const std::string w = doc_text_shown(d, layer, now); w != t.words || (t.drawn && t.drawn->outgrown)) {
                    if (t.drawn && words_at(s, t.drawn, w)) t.words = w;
                    else return (void)doc_match(d);
                }
    if (now == s.now)   // (a level whose keys show another drawing now: it alone made again, as it reads now (doc_match))
        for (auto& [layer, t] : d.shown)
            if (t.celMove && doc_cel(d, layer, now) != t.cel) return (void)doc_match(d);
    const std::vector<int> lie = doc_laid(d);
    // Each layer as it is now, in the order they lie: whether it is on, and whether it is a solid layer.
    struct Lies { int layer; Doc::Shown* shown; bool on, solid; double since; bool open; };
    std::vector<Lies> lies;
    bool solo = false;   // (while any layer is solo, only those are seen)
    for (int layer : lie) solo = solo || doc_number(d, layer, "solo", 0, 0) > 0.5;
    const auto solo_of = [&](int layer) {   // (a group's solo is its layers': a Null's eye and opacity go down to them already, relations.h)
        for (int up = layer, n = 0; up > 0 && n < 64; up = (int)doc_number(d, up, "parent", 0, 0), ++n)
            if (doc_number(d, up, "solo", 0, 0) > 0.5 && (up == layer || doc_word(d, up, "shape") == "null")) return true;
        return false;
    };
    for (int layer : lie) {
        const auto found = d.shown.find(layer);
        if (found == d.shown.end() || found->second.camera) continue;
        const double since = doc_element_now(d, layer, now) - doc_number(d, layer, "start", 0, 0), lasts = doc_number(d, layer, "duration", 0, -1);   // (held in an element put in: at the moment it shows)
        const bool open = found->second.drawn && found->second.drawn->boxed.z > 0.f && doc_literal(d, layer, "scale_z", now, 1) != 0.0;   // (its box open by its Scale Z; at 0 shut, one sheet: deep.glsl)
        Lies one{layer, &found->second, since >= 0.0 && (lasts < 0.0 || since < lasts) && doc_number(d, layer, "visible", 0, 1) > 0.5 && (!solo || solo_of(layer)), found->second.space != 2 || open, since, open};   // (a sheet in the world settles depth with the solid layers)
        lies.push_back(one);
    }
    // The camera: the nearest one in the order of the layers that is on (the past repository's choice); none, the stage's own.
    {
        int camera = 0;
        for (int layer : lie)
            if (d.shown.count(layer) && d.shown[layer].camera) {
                const double since = now - doc_number(d, layer, "start", 0, 0), lasts = doc_number(d, layer, "duration", 0, -1);
                if (since >= 0.0 && (lasts < 0.0 || since < lasts) && doc_number(d, layer, "visible", 0, 1) > 0.5) camera = layer;
            }
        d.working = d.viewCameraAsked && camera && !d.writing;
        god_view(s, d.working);
        d.looking = d.working ? 0 : camera;   // (its fog, if it says one: doc_look)
        const DocViewCamera seen = doc_view_camera_of(d, camera, now);
        const math::double3 eye = seen.eye, look = seen.look, up = seen.up;
        const double far = seen.far, fov = seen.fov;
        s.film->lookAt(eye, look, up);
        if (camera && doc_word(d, camera, "projection") == "orthographic") {   // (as large at the point it looks at as the perspective one shows it there)
            const double high = 6.0 * far * std::tan(0.5 * fov), wide = high * double(s.w) / double(s.h);
            s.film->setProjection(Camera::Projection::ORTHO, -wide, wide, -high, high, 0.05, 60.0 * std::max(1.0, far));
        } else s.film->setProjection(fov * 360.0 / (double)TAU, double(s.w) / double(s.h), 0.05, 60.0 * std::max(1.0, far));
        s.film->setShift(camera ? math::double2{doc_number(d, camera, "shift_x", now, 0), doc_number(d, camera, "shift_y", now, 0)} : math::double2{0.0});
        d.rig = s.film->getModelMatrix() * math::mat4::translation(math::double3{0, 0, -6});   // (from the stage's own camera to this one)
        // (its lens, Filament's own: sharp at the focus, as blurred off it as the f-number says; the shutter goes with the
        //  f-number so the picture is as bright as at the stage's own f/16 and 1/125 s)
        const double said = camera ? doc_number(d, camera, "aperture", now, 0) : 0.0, focus = camera ? doc_number(d, camera, "focus", now, 0) : 0.0;
        d.blurred = !d.working && said > 0.0;
        const double stop = std::max(said, 0.5);   // (Filament's widest)
        View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();
        if (camera && lens.cocScale != (float)doc_number(d, camera, "blur_level", now, 1)) lens.cocScale = (float)doc_number(d, camera, "blur_level", now, 1), s.view->setDepthOfFieldOptions(lens);
        s.film->setExposure(d.blurred ? (float)stop : 16.f, d.blurred ? (float)(stop * stop / (16.0 * 16.0 * 125.0)) : 1.f / 125.f, 100.f);
        s.film->setFocusDistance((float)(focus > 0.0 ? focus : length(eye - look)));
        d.facing = math::mat4(d.rig.upperLeft());
        if (d.working) {   // (the film's camera stays where it is, and what faces it faces it. A 2D layer is in the camera's picture and in no world (Adobe's working 3D views))
            const math::mat4 about = math::mat4::rotation(d.viewCameraIs[0] * (double)TAU / 360.0, math::double3{0, 1, 0}) * math::mat4::rotation(d.viewCameraIs[1] * (double)TAU / 360.0, math::double3{1, 0, 0});
            s.camera->lookAt((about * math::double4{0, 0, 6.0 * d.viewCameraIs[2], 0}).xyz, math::double3{0.0}, (about * math::double4{0, 1, 0, 0}).xyz);
            s.camera->setProjection(30.0, double(s.w) / double(s.h), 0.05, 60.0 * std::max(1.0, d.viewCameraIs[2]));
            for (Lies& l : lies) l.on = l.on && l.shown->space != 2;
        }
    }
    doc_look(d);
    d.round = doc_seconds(d);
    // Who is before whom (the past repository's law of 2026-09-12: a flat layer is not in the world). Flat layers take
    // no part in depth and lie by the order of the layers alone; solid layers that follow one another settle depth
    // among themselves; a run of the one sort lies whole over the run before it. All in the stage's own view, the runs
    // kept in order by Filament's channels; within a run of flat layers, the blend order. A flat layer's looks neither
    // ask nor write depth.
    std::vector<int> runOf(lies.size(), -1), sorts;
    for (size_t i = 0; i < lies.size(); ++i) {
        if (!lies[i].on || lies[i].shown->camera || lies[i].shown->behaviour || !lies[i].shown->light.isNull()) continue;   // (a camera, a behaviour or a light is in no run: nothing of it is drawn)
        const int sort = lies[i].solid ? 1 : 0;
        if (sorts.empty() || sorts.back() != sort) sorts.push_back(sort);
        runOf[i] = (int)sorts.size() - 1;
    }
    const int base = sorts.size() > 1 && sorts[0] == 0 && sorts[1] == 1 ? 1 : 0;   // (the last run in the stage's own view: flat layers under the first solid ones)
    const auto made = [&](int layer, bool shows) -> ThingFx& {   // (its view and its sheet, lying on what is behind as it says: Filament's own blending; one that reads what is under, as normal yet)
        const std::string laid = doc_word(d, layer, "blend");
        return thing_fx_built(s, d.layerFx[layer], shows ? "" : laid == "add" || laid == "multiply" || laid == "screen" ? laid : "", !shows && doc_layer_stands(d, layer, d.layerFx[layer]), shows);
    };
    const auto holder = [&](int layer) -> Scene* {   // (the scene of the nearest group above it that has effects of its own and is on now: its layers drawn in it; none, the stage's)
        for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0; up > 0 && n < 64; up = (int)doc_number(d, up, "parent", 0, 0), ++n) {
            if (!doc_holds_fx(d, up)) continue;
            const auto at = std::find_if(lies.begin(), lies.end(), [&](const Lies& l) { return l.layer == up; });
            if (at != lies.end() && runOf[(size_t)(at - lies.begin())] >= 0) return made(up, false).view->getScene();
        }
        return s.scene;
    };
    for (size_t i = 0; i < lies.size(); ++i) {
        if (runOf[i] < 0) continue;
        const int run = runOf[i];
        Doc::Shown& t = *lies[i].shown;
        const bool own = doc_own_fx(d, lies[i].layer);   // (with effects of its own: drawn alone, its picture laid here: layer_fx.h)
        const bool shows = own && doc_layer_shows(d, lies[i].layer, d.layerFx[lies[i].layer]);   // (a solid that shows its picture itself stays in the stage's scene, and is filmed by its view too, the stage's lights with it)
        Scene* const above = holder(lies[i].layer);
        Scene* into = own ? made(lies[i].layer, shows).view->getScene() : above;
        if (shows) {
            s.scene->forEach([&, film = into](utils::Entity e) { if (s.engine->getLightManager().hasComponent(e)) film->addEntity(e); });
            doc_entities(s, t, [film = into](utils::Entity e) { film->addEntity(e); });
            into = above;
        }   // (one view: every other run in the stage's own scene, kept in order by Filament's channels)
        Scene* const was = t.scene ? t.scene : s.scene;
        if (was != into) {   // (into the scene of its run; one not seen goes in when it is seen)
            if (t.in) doc_entities(s, t, [&](utils::Entity e) { was->remove(e), into->addEntity(e); });
            t.scene = into;
        }
        if (const int channel = std::min(run, 7); channel != t.channel) {
            doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) { faces.setChannel(one, (uint8_t)channel); });
            t.channel = channel;
        }
        if (t.run < 0 && !lies[i].solid) doc_material_instances(s, t, [](MaterialInstance* look) { look->setDepthCulling(false), look->setDepthWrite(false); });
        if (t.lies != (int)i && !lies[i].solid)
            doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
                for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part) faces.setBlendOrderAt(one, part, (uint16_t)(i * 128)), faces.setGlobalBlendOrderEnabledAt(one, part, true);   // (128 places for each: its copies lie among themselves by how far off they are)
            });
        t.run = run, t.lies = (int)i;
        if (own) {   // (its sheet where it lies: the same channel and the same blend order as it has, in the scene of the group it is in)
            auto& faces = s.engine->getRenderableManager();
            thing_fx_into(s, d.layerFx[lies[i].layer], above);
            const bool stood = d.layerFx[lies[i].layer].world, deep = stood && lies[i].solid;   // (stood in the world: in depth as a sheet of its sort is, by how far off; a 2D layer's, by the order)
            if (stood) d.layerFx[lies[i].layer].look->setDepthCulling(deep), d.layerFx[lies[i].layer].look->setDepthWrite(deep);
            for (const Stage::Renderable& made : s.renderables)
                if (made.of == d.layerFx[lies[i].layer].sheet || (d.layerFx[lies[i].layer].solid && made.of == d.layerFx[lies[i].layer].solid)) {
                    const auto one = faces.getInstance(made.thing);
                    faces.setCulling(one, false), faces.setChannel(one, (uint8_t)std::min(run, 7)), faces.setBlendOrderAt(one, 0, (uint16_t)(i * 128)), faces.setGlobalBlendOrderEnabledAt(one, 0, !deep);   // (its points are the screen's corners: never culled, as image.mat's sheet is not)
                }
        }
    }
    for (auto e = d.layerFx.begin(); e != d.layerFx.end();) {   // (no longer with effects of its own, or gone: let go)
        const auto at = std::find_if(lies.begin(), lies.end(), [&](const auto& l) { return l.layer == e->first; });
        if (at == lies.end() || runOf[(size_t)(at - lies.begin())] < 0 || !doc_own_fx(d, e->first)) {
            // (a layer gone out of its time keeps its effects' scene as the one it is in: its parts taken out of it and it
            //  in none before the scene is let go, else the next moment takes them out of a scene that is gone; Filament's
            //  scene, destroyed, is touched no more: golf_noise.md 48, the window let go twice so in P15. A group's: every
            //  layer it held, and every sheet laid in it, the same)
            Scene* const gone = e->second.view ? e->second.view->getScene() : nullptr;
            for (auto& [layer, t] : d.shown)
                if (gone && t.scene == gone) {
                    if (t.in) doc_entities(s, t, [&](utils::Entity x) { gone->remove(x); });
                    t.scene = nullptr, t.in = false;
                }
            for (auto& [layer, other] : d.layerFx) if (gone && other.in == gone) thing_fx_into(s, other, s.scene);
            thing_fx_off(s, e->second), e = d.layerFx.erase(e);
        } else ++e;
    }
    doc_layers_fx(d);   // (each with effects of its own drawn alone first: moment_fx.h)
    {
        std::vector<std::pair<int, Doc::Shown*>> laid;
        for (size_t i = 0; i < lies.size(); ++i) if (runOf[i] >= 0) laid.emplace_back(lies[i].layer, lies[i].shown);
        doc_layers_read(d, laid);
    }
    {   // (a glow: Filament's own, a layer past 1 bright taken up by the stage's bloom (its threshold), as emissive is)
        float most = 0.f;
        for (size_t i = 0; i < lies.size(); ++i)
            if (runOf[i] >= 0 && !doc_word(d, lies[i].layer, "glow").empty()) most = std::max(most, (float)doc_number(d, lies[i].layer, "glow_opacity", now, 1));
        if (most > 0.f) {
            View::BloomOptions glow = s.view->getBloomOptions();
            glow.enabled = true, glow.threshold = true, glow.strength = std::max(glow.strength, std::clamp(0.35f * most, 0.f, 1.f));
            s.view->setBloomOptions(glow);
        }
    }
    View::DepthOfFieldOptions lens = s.view->getDepthOfFieldOptions();   // (the camera's lens, on the stage's own view when solid layers are in it)
    if (lens.enabled != (d.blurred && (base == 1 || (!sorts.empty() && sorts[0]))))
        lens.enabled = !lens.enabled, s.view->setDepthOfFieldOptions(lens);
    for (size_t i = 0; i < lies.size(); ++i) {
        const int layer = lies[i].layer;
        Doc::Shown& t = *lies[i].shown;
        const bool in = lies[i].on;
        const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
        if (t.sketch && in) doc_sketch_mesh(d, layer, t, now);
        if (in != t.in) {   // (in or out of the scene of its run)
            Scene* sc = t.scene ? t.scene : s.scene;
            doc_entities(s, t, [&](utils::Entity e) { in ? sc->addEntity(e) : sc->remove(e); });
            t.in = in;
        }
        if (!in) continue;
        if (t.video) {   // (the film at its moment: on a live stage once the document is let go)
            if (s.later) s.later->push_back([&s, video = t.video, since = (float)lies[i].since] { video_at(s, video, since); });
            else video_at(s, t.video, (float)lies[i].since);
        }
        if (t.video && t.video->look) {   // (its own look, in its material, as ThorVG's effects give a picture its: blurred (in points of the film), tinted, tritoned)
            Canvas2DFx fx;
            std::string why;
            doc_fx(d, layer, now, false, 1.0, fx, why);
            const std::string way = doc_word(d, layer, "blur_direction");
            const float blur = (float)doc_number(d, layer, "blur", now, 0);
            const float4 grade[6] = {{way == "vertical" ? 0.f : blur / (float)t.video->w, way == "horizontal" ? 0.f : blur / (float)t.video->h, fx.tint, fx.tritone},
                                     {fx.tints[0], 0.f}, {fx.tints[1], 0.f}, {fx.tones[0], 0.f}, {fx.tones[1], 0.f}, {fx.tones[2], 0.f}};
            t.video->look->setParameter("grade", grade, 6);
        }
        if (t.solid && !t.solid->moves.empty()) for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth) solid_at(t.solid, doc_word(d, layer, "animation"), (lies[i].since - doc_delay(d, layer, (int)nth)) * doc_number(d, layer, "speed", 0, 1), nth);   // (its own movement, from when it comes on)
        if (t.drawn && t.drawn->lottie)   // (its slots as their knobs are now)
            if (DocScript* sc = doc_script_of(d, doc_word(d, layer, "file")); sc && !sc->parameters.empty()) {
                std::vector<double> v;
                for (size_t k = 0; k < sc->parameters.size(); ++k) v.push_back(doc_number(d, layer, sc->names[k].c_str(), now, sc->parameters[k].usual));
                slots_at(s, t.drawn, lottie_slots_json(sc->parameters, v));
            }
        if (t.drawn && std::filesystem::path(doc_word(d, layer, "file")).extension() == ".mid") {   // (a MIDI roll's notes struck as ALMaMPlayer's note.gd strikes them: lit up over 0.17 s, held as long as the note (0.2 s longer if it is 0.4 s or less), down over 0.27 s; grown to 1.03 over 0.2 s and left so; dipped 0.25 + its velocity x 0.2 x 0.7 over 0.17 s, back over 0.27 s once held; sine in and out)
            const std::string file = doc_word(d, layer, "file");
            const double speed = doc_number(d, layer, "speed", 0, 1), now_in = lies[i].since;
            std::string why;
            static std::map<std::string, std::vector<MidiRollNote>> read;
            const std::string roll = midi_roll_file(file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why);
            if (!read.count(roll)) read[roll] = midi_roll_notes(roll);
            const auto ease = [](double x) { return godot::Sine::in_out(std::clamp(x, 0.0, 1.0), 0.0, 1.0, 1.0); };   // (Godot's Tween's TRANS_SINE, EASE_IN_OUT; a tweener stops at its end: tween.cpp)
            std::vector<float> lit;
            std::vector<tvg::Matrix> moves;
            for (const MidiRollNote& n : read[roll]) {
                const double hold = n.off - n.on > 0.4 ? n.off - n.on : n.off - n.on + 0.2;
                const double up = now_in < n.on ? 0.0 : now_in < n.on + hold ? ease((now_in - n.on) / 0.17) : 1.0 - ease((now_in - n.on - hold) / 0.27);
                const float grow = (float)(1.0 + 0.03 * (now_in < n.on ? 0.0 : ease((now_in - n.on) / 0.2))), dip = (float)(up * (0.25 + n.velocity * 0.2 * 0.7));
                const float x0 = (float)n.x, y0 = (float)(n.y + 0.5 * n.high);   // (grown about its left end's middle: where ALMaMPlayer's note is)
                lit.push_back((float)up);
                moves.push_back(tvg::Matrix{grow, 0.f, x0 * (1.f - grow), 0.f, grow, y0 * (1.f - grow) + dip, 0.f, 0.f, 1.f});
            }
            lit_at(s, t.drawn, lit, moves, float3{0xed, 0x9e, 0x85} / 255.f);
        }
        if (t.drawn && t.drawn->boxed.z > 0.f && lies[i].open != t.drawn->open) {   // (as anything in the world: it settles depth with the others)
            t.drawn->open = lies[i].open;
            const float4 box{t.drawn->boxed, lies[i].open ? 1.f : 0.f};
            t.drawn->look->setParameter("deep", box), t.drawn->look->setDepthCulling(lies[i].solid), t.drawn->look->setDepthWrite(lies[i].solid);
            for (const Stage::Renderable& made : s.renderables)
                if (const auto own = d.copyLooks.find(made.thing.getId()); made.of == t.drawn->sheet && own != d.copyLooks.end()) own->second->setParameter("deep", box), own->second->setDepthCulling(lies[i].solid), own->second->setDepthWrite(lies[i].solid);
        }
        if (t.drawn && t.drawn->edge[0]) {   // (its bevel as it is now, in the box's lengths; as far across as through in the world. 12 points as it comes: no source, After Effects' 2 is hardly seen on a title)
            Canvas2D& drawn = *t.drawn;
            const float told = (float)(doc_number(d, layer, "bevel_depth", now, 12) / t.units), z = (float)doc_literal(d, layer, "scale_z", now, 1);
            const float wide = (float)doc_literal(d, layer, "scale_x", now, 1), through = z != 0.f ? told * wide / std::fabs(z) : 0.f;
            const bool banded = doc_bevel(d, layer) == 5 && drawn.bands.w > 0.f;   // (Step on a word with strokes: a stair to each, as wide as it is; Bevel Depth how high)
            const float most = banded ? drawn.bands[(int)drawn.bands.w - 1] : 1.f;
            const float across = banded ? most * 2.f * drawn.boxed.x / (float)drawn.edgeW : told;
            const float4 cut{across, std::min(through, drawn.boxed.z), told > 0.f ? (float)doc_bevel(d, layer) : 0.f, wide != 0.f ? std::fabs(z / wide) : 1.f};
            const float4 stairs = banded ? float4{drawn.bands.x / most, drawn.bands.y / most, drawn.bands.z / most, drawn.bands.w} : float4{0.f};
            drawn.look->setParameter("deepBevel", cut), drawn.look->setParameter("deepSteps", stairs);
            for (const Stage::Renderable& made : s.renderables)
                if (const auto own = d.copyLooks.find(made.thing.getId()); made.of == drawn.sheet && own != d.copyLooks.end()) own->second->setParameter("deepBevel", cut), own->second->setParameter("deepSteps", stairs);
            const int reach = (int)std::ceil(across * (float)drawn.edgeW / (2.f * drawn.boxed.x));
            if (drawn.stale || reach > drawn.edgeReach) drawn.edgeReach = std::max(reach, drawn.edgeReach), edge_ask(s, &drawn, drawn.edgeReach);
        }
        if (t.drawn && t.drawn->inLight) {   // (a solid's three as they are now, and as a solid's as they come)
            const float3 surface{(float)doc_number(d, layer, "metallic", now, 0.08), (float)doc_number(d, layer, "roughness", now, 0.6), (float)doc_number(d, layer, "reflectance", now, 0.5)};
            t.drawn->look->setParameter("surface", surface);
            for (const Stage::Renderable& made : s.renderables)
                if (const auto own = d.copyLooks.find(made.thing.getId()); made.of == t.drawn->sheet && own != d.copyLooks.end()) own->second->setParameter("surface", surface);
        }
        if (const std::string material = t.drawn || t.video ? doc_sheet_material(d, layer) : ""; !material.empty()) {   // (the material its sheet wears, its knobs as they are now: flat.mat's wear, doc_sheet_material)
            const auto at = [&](const char* name, double usual) { return (float)doc_number(d, layer, name, now, usual); };
            const float vivid = at("vivid", 1.3);
            const float4 coat{material == "glass" ? vivid : at("clear_coat", 0), at("clear_coat_roughness", 0), at("sheen", 0), at("anisotropy", 0)};
            const float4 glass{at("ior", 1.5), at("thickness", 0.5), at("dispersion", 0.1), at("swim", 0.5)};
            const float dark = material == "bubble" ? vivid : at("dark", 4);
            const float3 surface{at("metallic", 0.08), at("roughness", 0.6), at("reflectance", 0.5)};
            doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
                for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
                    if (MaterialInstance* look = faces.getMaterialInstanceAt(one, part); look->getMaterial()->hasParameter("wearGlass")) {
                        look->setParameter("wear", coat), look->setParameter("wearGlass", glass), look->setParameter("wearDark", dark);
                        if (t.video) look->setParameter("surface", surface);   // (a film's own, as a drawn sheet's is told above)
                    }
            });
        }
        if (t.drawn && t.drawn->boxed.z > 0.f) {   // (After Effects' Bevel, Side and Back Color and their Metal; a part told nothing is as the front is)
            float4 colour[3], surface[3];
            const float3 front{(float)doc_number(d, layer, "metallic", now, 0.08), (float)doc_number(d, layer, "roughness", now, 0.6), (float)doc_number(d, layer, "reflectance", now, 0.5)};
            for (int p = 0; p < 3; ++p) {
                const std::string part = p == 0 ? "bevel_" : p == 1 ? "side_" : "back_", word = doc_word(d, layer, (part + "color").c_str());
                const long hex = word.size() == 6 ? std::strtol(word.c_str(), nullptr, 16) : 0;
                colour[p] = float4{(float)((hex >> 16) & 255) / 255.f, (float)((hex >> 8) & 255) / 255.f, (float)(hex & 255) / 255.f, word.size() == 6 ? 1.f : 0.f};
                surface[p] = float4{(float)doc_number(d, layer, (part + "metallic").c_str(), now, front.x), (float)doc_number(d, layer, (part + "roughness").c_str(), now, front.y), front.z, 0.f};
            }
            t.drawn->look->setParameter("partColour", colour, 3), t.drawn->look->setParameter("partSurface", surface, 3);
            for (const Stage::Renderable& made : s.renderables)
                if (const auto own = d.copyLooks.find(made.thing.getId()); made.of == t.drawn->sheet && own != d.copyLooks.end()) own->second->setParameter("partColour", colour, 3), own->second->setParameter("partSurface", surface, 3);
        }
        if (t.drawn && t.drawn->sketchLines) {   // (a sketch's lines as strong as they are now: what was drawn with them as they were goes)
            bool moved = false;
            for (auto& [line, strong] : *t.drawn->sketchLines) {
                const double is = doc_number(d, layer, ("js_line_" + std::to_string(line)).c_str(), now, 1);
                moved = moved || is != strong, strong = is;
            }
            if (moved) cache_drop(s, t.drawn), t.drawn->shownAt = t.drawn->sketchAt = -1;
        }
        if (t.drawn && t.drawn->seconds > 0.f) picture_at(s, t.drawn, std::fmod((float)doc_own_time(d, layer, now, lies[i].since), t.drawn->seconds));
        if (t.drawn && !t.drawn->effects.empty()) {   // (its effects as they are now: those that move are drawn again)
            Canvas2DFx fx;
            std::string why;
            if (doc_fx(d, layer, now, false, t.units, fx, why)) fx_at(s, t.drawn, fx);
        }
        if (t.drawn && t.drawn->shape) trim_at(s, t.drawn, (float)doc_number(d, layer, "trim", now, 0), (float)doc_number(d, layer, "trim_begin", now, 0), (float)doc_number(d, layer, "trim_offset", now, 0));
        if (t.drawn && t.drawn->cut) {   // (a shape in triangles: bent in its look, and its copies' own looks, nothing drawn again)
            const auto num = [&](const char* name, double otherwise) { return (float)doc_number(d, layer, name, now, otherwise); };
            const float deg = (float)(TAU / 360.0), since = (float)lies[i].since;
            bool driven = false;   // (a bend given each copy by a behaviour: each copy's own look told its own)
            float4 region{0.f};   // (a bend's behaviour's falloff, point by point in the look: a round where its shape lies, as large as it is)
            const auto bendsOf = [&](int copy, int n, float4* bends, const math::double3* where = nullptr) {
                const auto at = [&](const char* name, double otherwise) {
                    if (const int by = doc_driven_by(d, layer, name)) {
                        driven = true;
                        if (const int f = (int)doc_number(d, by, "region", 0, 0); f && d.shown.count(f) && d.shown[f].drawn) {   // (weighed point by point, not copy by copy)
                            const math::mat4 there = doc_place(d, f, now, 0, 0, false);
                            const math::double4 middle = there * math::double4{0, 0, 0, 1};
                            const double r = length((there * math::double4{0.5 * d.shown[f].drawn->sheetHigh, 0, 0, 0}).xyz), soft = doc_number(d, by, "falloff_soft", now, 0);
                            region = float4{(float)middle.x, (float)middle.y, (float)r, (float)(doc_number(d, by, "falloff_invert", 0, 0) > 0.5 ? -std::max(soft, 1e-4) : soft)};
                            return (float)doc_behaviour_at(d, by, copy, n, now);
                        }
                        return (float)doc_given(d, by, copy, n, now, num(name, otherwise), where);
                    }
                    return num(name, otherwise);
                };
                const float4 all[7] = {{at("warp", 0), at("warp_width", 0.5), at("warp_speed", 1) * since, at("warp_angle", 0) * deg},
                                       {at("bend", 0) * deg, doc_word(d, layer, "bend_direction") == "vertical" ? 1.f : 0.f, at("twist", 0) * deg, at("pinch", 0)},
                                       {at("skew", 0) * deg, at("skew_axis", 0) * deg, at("squash", 0), 0.5f * t.drawn->wideBy},
                                       {at("wiggle", 0), at("wiggle_detail", 3), at("wiggle_speed", 1) * since, num("seed", 0) * 7.31f},
                                       {0.f, 0.f, num("stretch", 0), 0.f},
                                       {at("pin_tl_x", 0), at("pin_tl_y", 0), at("pin_tr_x", 0), at("pin_tr_y", 0)},
                                       {at("pin_bl_x", 0), at("pin_bl_y", 0), at("pin_br_x", 0), at("pin_br_y", 0)}};
                std::copy(all, all + 7, bends);
                bends[7] = region;
            };
            float4 bends[8];
            bendsOf(0, 1, bends);
            if (bends[4].z != 0.f) {   // (how it moves: where its middle was a sixtieth of a second ago, seen as it is now turned and sized)
                const math::mat4 was = doc_place(d, layer, now - 1.0 / 60.0), is = doc_place(d, layer, now);
                const math::float4 back = inverse(is) * was * math::float4{0, 0, 0, 1};
                bends[4].x = (float)(-60.0 * back.x), bends[4].y = (float)(-60.0 * back.y);
            }
            t.drawn->look->setParameter("bends", bends, 8);
            if (t.drawn->edgeLook) t.drawn->edgeLook->setParameter("bends", bends, 8);
            // (another shape's path as it is now, where it lies, in this one's points: as shape_cut lays them; and each of its copies, `all`)
            const auto other = [&](int with, bool all) {
                Canvas2D::Other o;
                const auto found = d.shown.find(with);
                if (with == layer || found == d.shown.end() || !found->second.drawn || !found->second.drawn->cut) return o;
                const Canvas2D* a = t.drawn; const Canvas2D* b = found->second.drawn;
                const math::mat4 back = inverse(doc_place(d, layer, now));
                const tvg::PathCommand* cmds; const tvg::Point* pts; uint32_t cmdsCnt = 0, ptsCnt = 0;
                b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
                const int many = all ? doc_members(d, with) : 1;
                for (int copy = 0; copy < many; ++copy) {   // (a plate cut by a whole grid of them)
                    const math::mat4 to = back * (many > 1 ? doc_place(d, with, now, 0, copy, true) : doc_place(d, with, now));
                    o.by.insert(o.by.end(), cmds, cmds + cmdsCnt);
                    for (uint32_t k = 0; k < ptsCnt; ++k) {
                        const math::double4 on = to * math::double4{(pts[k].x - 0.5 * b->cutW) / b->plainHigh * b->sheetHigh, (0.5 * b->plainHigh - pts[k].y) / b->plainHigh * b->sheetHigh, 0.0, 1.0};
                        o.at.push_back({(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW), (float)(0.5 * a->plainHigh - on.y / a->sheetHigh * a->plainHigh)});
                    }
                }
                return o;
            };
            Canvas2D::Other join, morph;   // (put together with another, Skia's op in skia_path_operations.cpp's order; turned into another, so far)
            const std::string how = doc_word(d, layer, "boolean");
            for (int k = 0; k < 4; ++k)
                if (how == std::array<const char*, 4>{"subtract", "intersect", "union", "exclude"}[(size_t)k]) join = other((int)doc_number(d, layer, "boolean_with", 0, 0), true), join.how = k;
            if (const float much = num("morph", 0); much > 0.f) morph = other((int)doc_number(d, layer, "morph_to", 0, 0), false), morph.much = much;
            if (const int steps = (int)doc_number(d, layer, "morph_steps", 0, 0); steps > 1) morph = other((int)doc_number(d, layer, "morph_to", 0, 0), false), morph.much = 1.f, morph.how = std::min(steps, 64);   // (a blend: every step at once)
            Canvas2D::Other trace;   // (another's track over the last so many seconds, its middle where it was, as Cavalry's Trails: this one's path)
            if (const int with = (int)doc_number(d, layer, "trail", 0, 0); with && with != layer && d.shown.count(with)) {
                const math::mat4 back = inverse(doc_place(d, layer, now));
                const double length = std::max(1e-3, doc_number(d, layer, "trail_length", now, 1));
                const Canvas2D* a = t.drawn;
                // (on a grid of 64 ticks over its length, fixed in time: a tick worked out once is kept, so a moment only works out
                //  the ticks new since; its ends where the other was then and is now)
                const double step = length / 64.0, last = std::floor(now / step);
                if (d.tracks.size() > 200000) d.tracks.clear();
                const auto was = [&](double t, long long tick) {
                    if (tick < 0) return (doc_shown_at(d, with, t) * math::double4{0, 0, 0, 1}).xyz;
                    auto found = d.tracks.find({with, step, tick});
                    if (found == d.tracks.end()) found = d.tracks.emplace(std::make_tuple(with, step, tick), (doc_shown_at(d, with, t) * math::double4{0, 0, 0, 1}).xyz).first;
                    return found->second;
                };
                const auto put = [&](math::double3 world) {
                    const math::double4 on = back * math::double4{world, 1.0};
                    trace.by.push_back(trace.by.empty() ? tvg::PathCommand::MoveTo : tvg::PathCommand::LineTo);
                    trace.at.push_back({(float)(on.x / a->sheetHigh * a->plainHigh + 0.5 * a->cutW), (float)(0.5 * a->plainHigh - on.y / a->sheetHigh * a->plainHigh)});
                };
                put(was(now - length, -1));
                for (long long k = (long long)last - 63; k <= (long long)last; ++k) if ((double)k * step > now - length) put(was((double)k * step, k));
                put(was(now, -1));
            }
            if (const std::string drawn = trace.by.empty() ? doc_word(d, layer, "drawing") : std::string(); !drawn.empty() && doc_word(d, layer, "fx").find(".am") != std::string::npos) {
                // (a freehand stroke with AbsentMotion's drawing effects on it, Stroke Taper, Drawing Progress: its outline as they make it now
                //  (absent_drawing), its path's own units as its points; made again only when they say otherwise)
                std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
                std::erase_if(on, [](const AbsentEffect& e) { return e.id != "stroketaper" && e.id != "drawingprogress"; });
                std::string key = std::to_string(std::hash<std::string>{}(drawn));
                for (const AbsentEffect& e : on) for (const auto& [name, v] : e.params) for (const float one : v) key += " " + std::to_string(one);
                auto& kept = d.drawingKept[layer];
                if (!on.empty() && kept.first != key) {
                    kept = {key, absent_drawing(drawn, on, layer, 0.0, 1000.0, 0.0, false)};
                }
                std::vector<tvg::PathCommand> c;
                std::vector<tvg::Point> p;
                if (!on.empty() && sk_svg(kept.second.c_str(), c, p)) {
                    const Canvas2D* a = t.drawn;
                    for (tvg::Point& at : p) at = {0.5f * a->cutW + at.x * a->plainHigh, 0.5f * a->plainHigh + at.y * a->plainHigh};
                    trace.by = std::move(c), trace.at = std::move(p);
                }
            }
            cut_at(s, t.drawn, float3{num("trim", 0), num("trim_begin", 0), num("trim_offset", 0)},   // (its path anew, if it is told otherwise: cut again)
                   {num("round", 0), num("bloat", 0), num("zigzag", 0), num("zigzag_ridges", 5), num("zigzag_smooth", 0), num("offset", 0), num("rough", 0), num("rough_detail", 0.03), std::round(num("resample", 0)), num("voxel", 0)}, join, morph, trace);
            t.drivenLooks = driven;
            const int members = driven ? doc_members(d, layer) : 1;
            auto& faces = s.engine->getRenderableManager();
            for (const Stage::Renderable& made : s.renderables) {
                if (made.of != t.drawn->sheet || made.matte) continue;
                if (driven && !made.many) {   // (each copy its own bends, in its own look and its edge's)
                    float4 own[8];
                    const math::double3 where{made.place[3].x, made.place[3].y, made.place[3].z};   // (where this copy lies: what a falloff weighs)
                    bendsOf(std::max(0, made.nth), members, own, &where);
                    if (own[4].z == 0.f) own[4] = bends[4];
                    const auto one = faces.getInstance(made.thing);
                    MaterialInstance*& look = d.copyLooks[made.thing.getId()];
                    if (!look) look = MaterialInstance::duplicate(t.drawn->look), faces.setMaterialInstanceAt(one, 0, look);
                    look->setParameter("bends", own, 8);
                    if (t.drawn->edgeLook && faces.getPrimitiveCount(one) > 1) {
                        MaterialInstance*& edge = d.copyEdges[made.thing.getId()];
                        if (!edge) edge = MaterialInstance::duplicate(t.drawn->edgeLook), faces.setMaterialInstanceAt(one, 1, edge);
                        edge->setParameter("bends", own, 8);
                    }
                } else if (const auto own = d.copyLooks.find(made.thing.getId()); own != d.copyLooks.end()) own->second->setParameter("bends", bends, 8);
            }
        }
        if (t.drawn && t.drawn->shape)
            bend_at(s, t.drawn, (float)doc_number(d, layer, "round", now, 0), (float)doc_number(d, layer, "bloat", now, 0), (float)doc_number(d, layer, "zigzag", now, 0),
                    (float)doc_number(d, layer, "zigzag_ridges", now, 5), (float)doc_number(d, layer, "zigzag_smooth", now, 0), (float)doc_number(d, layer, "offset", now, 0));
        const mat4f place = mat4f(doc_place(d, layer, now));
        const bool staggered = doc_staggered(d, layer, now);   // (each copy, the first too, as late as its order says, waving as its place in the wave says)
        const std::vector<math::mat4> joins = doc_number(d, layer, "connect", 0, 0) != 0.0 ? doc_joins(d, layer, now) : std::vector<math::mat4>{};   // (a joining layer: its copies lie between another's)
        if (t.grains && t.look) t.look->setParameter("dissolve", (float)doc_number(d, layer, "dissolve", now, 0)), t.look->setParameter("grain", (float)doc_number(d, layer, "grain", now, 1));
        if (t.grains && t.look && t.splatFx) {   // (its effect's uniforms at its own time: the knobs as the document says them, then the effect's updateEffect)
            const auto said = t.splatFx->uniforms(std::max(0.0, now - doc_number(d, layer, "start", 0, 0)), 1.0 / 60.0, [&](const std::string& parameter, double usual) { return doc_number(d, layer, doc_screen_parameter(t.splatFxFile, parameter).c_str(), now, usual); });
            for (const auto& [n, f] : said) {
                if (f.size() == 1) t.look->setParameter(n.c_str(), f[0]);
                else if (f.size() == 2) t.look->setParameter(n.c_str(), float2{f[0], f[1]});
                else if (f.size() == 3) t.look->setParameter(n.c_str(), float3{f[0], f[1], f[2]});
                else if (f.size() >= 4) t.look->setParameter(n.c_str(), float4{f[0], f[1], f[2], f[3]});
            }
            if (t.splatPlain && t.splatFx->finished() != t.splatDone) {   // (finished: its plain look, as PlayCanvas takes the shader off; back before it: the effect's again)
                t.splatDone = t.splatFx->finished();
                doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) { faces.setMaterialInstanceAt(one, 0, t.splatDone ? t.splatPlain : t.look); });
            }
        }
        if (t.solid) for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth) solid_to(s, t.solid, nth || staggered ? mat4f(doc_place(d, layer, now, 0, (int)nth, staggered)) : place, nth);
        else if (doc_number(d, layer, "connect", 0, 0) != 0.0) move(s, m, [&](int nth, const mat4f&) { return (size_t)nth < joins.size() ? mat4f(joins[(size_t)nth]) : mat4f::scaling(float3{0.f}); });
        else {
            std::vector<float> far;   // (how far off each copy is from the eye: those further off drawn first, within the layer's own place)
            const mat4f eye = mat4f(s.camera->getViewMatrix());
            const std::string fills = doc_word(d, layer, "copy_fill");
            const bool flatLayer = !lies[i].solid && (fills.empty() || fills == "none");   // (coloured along their order: drawn in it, not by how far off)
            move(s, m, [&](int nth, const mat4f&) {
                const mat4f at = nth || staggered ? mat4f(doc_place(d, layer, now, 0, nth, staggered)) : place;
                if ((size_t)nth >= far.size()) far.resize((size_t)nth + 1, 0.f);
                far[(size_t)nth] = -(eye * at[3]).z;
                return at;
            }, flatLayer ? &eye : nullptr);   // (copies drawn in one go: those further off first, as each copy's own order does it below)
            if (far.size() > 1 && !lies[i].solid && t.lies >= 0) {
                std::vector<size_t> order(far.size());
                for (size_t k = 0; k < order.size(); ++k) order[k] = k;
                std::stable_sort(order.begin(), order.end(), [&](size_t a, size_t b) { return far[a] > far[b]; });
                std::vector<uint16_t> place_of(far.size());
                for (size_t k = 0; k < order.size(); ++k) place_of[order[k]] = (uint16_t)(k * 127 / std::max<size_t>(1, order.size() - 1));
                auto& faces = s.engine->getRenderableManager();
                for (const Stage::Renderable& made : s.renderables) {
                    if (made.of != m || made.nth < 0 || (size_t)made.nth >= place_of.size()) continue;
                    const auto one = faces.getInstance(made.thing);
                    for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part) faces.setBlendOrderAt(one, part, (uint16_t)(t.lies * 128 + place_of[(size_t)made.nth]));
                }
            }
        }
        if (const auto told = d.scripted.find(layer); told != d.scripted.end() && t.look && !t.drawn && !t.video) {   // (a solid's copies each the colour its sketch fills it with: a look of its own each)
            auto& faces = s.engine->getRenderableManager();
            for (const Stage::Renderable& made : s.renderables) {
                if (made.of != m || made.matte || made.nth < 0 || (size_t)made.nth >= told->second.copies.size() || told->second.copies[(size_t)made.nth].colour < 0.0) continue;
                MaterialInstance*& own = d.copyLooks[made.thing.getId()];
                if (!own) own = MaterialInstance::duplicate(t.look), faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
                const long hex = (long)told->second.copies[(size_t)made.nth].colour;
                own->setParameter("color", float4{Color::toLinear<ACCURATE>(sRGBColor{float3{(float)((hex >> 16) & 255), (float)((hex >> 8) & 255), (float)(hex & 255)} / 255.f}), 1.f});
            }
        }
        const double whole = doc_number(d, layer, "opacity", now, 1) * doc_absent_opacity(d, layer, now) * doc_group_opacity(d, layer, now);   // (AbsentMotion's Pulse Opacity too, and its groups')
        const auto fxOf = d.layerFx.find(layer);
        const bool sheetClear = fxOf != d.layerFx.end() && fxOf->second.look && fxOf->second.look->getMaterial()->hasParameter("opacity");   // (with effects of its own how clear it is comes after them, on its sheet: After Effects renders a layer's masks, effects, then transform)
        if (sheetClear) fxOf->second.look->setParameter("opacity", (float)whole);
        const double ownClear = sheetClear ? 1.0 : whole;
        if (MaterialInstance* look = t.video ? t.video->look : t.drawn ? t.drawn->look : nullptr) look->setParameter("opacity", (float)ownClear);
        if (t.drawn && t.drawn->edgeLook) t.drawn->edgeLook->setParameter("opacity", (float)ownClear);
        if (MaterialInstance* main = t.video ? t.video->look : t.drawn ? t.drawn->look : nullptr) {   // (its copies coloured each their own, along a ramp in their order: a look of its own each, told what the layer's is)
            std::vector<float3> ramp;
            std::istringstream said(doc_word(d, layer, "copy_fill"));
            for (std::string one; said >> one;) { if (one == "none") break; const long rgb = std::strtol(one.c_str(), nullptr, 16); ramp.push_back(Color::toLinear<ACCURATE>(sRGBColor{float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255), (float)(rgb & 255)} / 255.f})); }
            if (ramp.size() == 1) ramp.push_back(ramp[0]);   // (one colour: every copy in it)
            const std::vector<float2>& letters = t.drawn ? t.drawn->letters : std::vector<float2>{};
            const auto scripted = d.scripted.find(layer);   // (a script's copies each as clear as it says)
            const std::vector<AbsentCopy>& absent = doc_absent_copies(d, layer, now);   // (AbsentMotion's copies each as clear as its repeat lays them: a scatter field's far ones)
            const bool clears = (scripted != d.scripted.end() && std::any_of(scripted->second.copies.begin(), scripted->second.copies.end(), [](const ScriptCopy& c) { return c.opacity != 1.0; })) ||
                                std::any_of(absent.begin(), absent.end(), [](const AbsentCopy& c) { return c.alpha < 0.999; });
            const bool clearEach = doc_driven_by(d, layer, "opacity") != 0, pickEach = doc_driven_by(d, layer, "copy_fill_at") != 0;   // (given each copy by a behaviour)
            const double fadeTo = std::clamp(doc_number(d, layer, "copy_opacity_end", now, 1), 0.0, 1.0);   // (the last copy as clear as this, the first as the layer: After Effects' Repeater, End Opacity)
            const bool clearLate = !sheetClear && doc_number(d, layer, "stagger", 0, 0) > 0.0 && doc_key_times(d, layer, "opacity").size() > 1;   // (a staggered copy fades as late as it moves: GSAP's stagger takes every value of a tween, After Effects' range selector an Opacity with the rest)
            if (ramp.size() < 2 && letters.empty() && !clears && !t.drivenLooks && !clearEach && !pickEach && fadeTo == 1 && !clearLate) doc_copy_looks_off(d, m, main);
            else {
                auto& faces = s.engine->getRenderableManager();
                const int n = doc_members(d, layer);
                for (const Stage::Renderable& made : s.renderables) {
                    if (made.of != m || made.matte) continue;
                    MaterialInstance*& own = d.copyLooks[made.thing.getId()];
                    if (!own) own = MaterialInstance::duplicate(main), faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
                    if (made.many) {   // (drawn with others in one go: the ramp and where this draw's first copy lies along it, flat.mat colours each)
                        float4 colours[8] = {};
                        for (size_t k = 0; k < ramp.size() && k < 8; ++k) colours[k] = float4{ramp[k], 1.f};
                        own->setParameter("ramp", colours, 8);
                        own->setParameter("rampOf", ramp.size() >= 2 ? float4{(float)made.nth, (float)n, (float)std::min<size_t>(ramp.size(), 8), doc_word(d, layer, "copy_fill_way") == "cycle" ? 1.f : 0.f} : float4{0.f});
                        if (ramp.size() < 2) own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});
                        own->setParameter("copyFade", float4{(float)fadeTo, (float)n, (float)made.nth, fadeTo != 1 ? 1.f : 0.f});
                    }
                    else if (ramp.size() >= 2 && doc_word(d, layer, "copy_fill_way") == "cycle") own->setParameter("wash", float4{ramp[(size_t)made.nth % ramp.size()], 1.f});   // (one each in turn)
                    else if (ramp.size() >= 2) {   // (along the ramp in their order; or where a behaviour says, copy_fill_at, 0 its first colour, 1 its last)
                        const math::double3 where{made.place[3].x, made.place[3].y, made.place[3].z};
                        const double order = n > 1 ? (double)made.nth / (double)(n - 1) : 0.0;
                        const double pick = pickEach ? std::clamp(doc_given(d, doc_driven_by(d, layer, "copy_fill_at"), made.nth, n, now, order, &where), 0.0, 1.0) : order;
                        const float along = (float)pick * (float)(ramp.size() - 1);
                        const size_t i = std::min((size_t)along, ramp.size() - 2);
                        own->setParameter("wash", float4{mix(ramp[i], ramp[i + 1], along - (float)i), 1.f});
                    } else own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});   // (its own: a shape cut in triangles is filled by it)
                    if ((size_t)made.nth < letters.size()) own->setParameter("window", float4{letters[(size_t)made.nth].x, letters[(size_t)made.nth].y, 1.f, 0.f});   // (its own letter)
                    const double clear = (scripted != d.scripted.end() && (size_t)made.nth < scripted->second.copies.size() ? scripted->second.copies[(size_t)made.nth].opacity : 1.0) *
                                         ((size_t)made.nth < absent.size() ? absent[(size_t)made.nth].alpha : 1.0);
                    const math::double3 here{made.place[3].x, made.place[3].y, made.place[3].z};
                    const int clearBy = doc_driven_by(d, layer, "opacity");
                    const double opacity = clearLate ? ownClear / std::max(doc_number(d, layer, "opacity", now, 1), 1e-6) * doc_number(d, layer, "opacity", now - doc_delay(d, layer, made.nth), 1)
                                         : !clearEach ? ownClear
                                         : doc_among(doc_relations, doc_word(d, clearBy, "file")) ? std::clamp(doc_literal(d, layer, "opacity", now, 1), 0.0, 1.0)   // (a relation's: by the layer's place among its layers)
                                         : std::clamp(doc_given(d, clearBy, made.nth, n, now, doc_number(d, layer, "opacity", now, 1), &here), 0.0, 1.0);
                    const double fade = n > 1 ? 1 + (fadeTo - 1) * (double)made.nth / (double)(n - 1) : 1.0;
                    own->setParameter("opacity", (float)(opacity * std::clamp(clear, 0.0, 1.0) * fade));
                    if (t.drawn && t.drawn->edgeLook && !made.many) {   // (its edge's own look: a frame alone (filled with nothing) coloured each as its fill would be; each as clear)
                        const auto one = faces.getInstance(made.thing);
                        if (faces.getPrimitiveCount(one) > 1) {
                            MaterialInstance*& edge = d.copyEdges[made.thing.getId()];
                            if (!edge) edge = MaterialInstance::duplicate(t.drawn->edgeLook), faces.setMaterialInstanceAt(one, 1, edge);
                            if (t.drawn->hollow && ramp.size() >= 2) {
                                edge->setParameter("wash", own->getParameter<float4>("wash"));
                            }
                            edge->setParameter("opacity", (float)(opacity * std::clamp(clear, 0.0, 1.0)));
                        }
                    }
                    own->setParameter("glowing", (float)doc_number(d, layer, "emissive", now, 0));
                }
            }
        }
        const float shine = (float)doc_number(d, layer, "emissive", now, 0) + (doc_word(d, layer, "glow").empty() ? 0.f : 0.35f * (float)doc_number(d, layer, "glow_opacity", now, 1));   // (how much it lights itself now: a flat layer's sheet, a solid's own faces; a glow past 1, for the bloom)
        doc_material_instances(s, t, [&](MaterialInstance* look) { if (look->getMaterial()->hasParameter("glowing")) look->setParameter("glowing", shine); });
    }
    // Soft shadows (Filament's PCSS) on the stage's own view while any light that is on says so; else its crisp ones.
    {
        bool soft = false;
        for (const Lies& one : lies) soft = soft || (one.on && !one.shown->light.isNull() && doc_number(d, one.layer, "shadow_softness", 0, 0) > 0.0);
        s.view->setShadowType(soft ? View::ShadowType::PCSS : View::ShadowType::PCF);
    }
    // The lights: in every scene of the stage while each is on (the stage's own and every picture laid over it), where
    // it is, shining the way it is turned (ahead of it), as strong as it is now; 1 as bright as the stage's own light.
    for (const Lies& one : lies) {
        const utils::Entity e = one.shown->light;
        if (e.isNull()) continue;
        std::vector<Scene*> all{s.scene};
        for (const auto& [layer, e] : d.layerFx) if (e.view && doc_holds_fx(d, layer)) all.push_back(e.view->getScene());   // (and a group's with effects of its own: its layers lit as on the stage)
        for (Scene* sc : all) one.on ? (sc->hasEntity(e) ? void() : sc->addEntity(e)) : sc->remove(e);
        if (!one.on) continue;
        auto& lights = s.engine->getLightManager();
        const auto it = lights.getInstance(e);
        const math::mat4 place = doc_place(d, one.layer, now);
        lights.setPosition(it, math::float3((place * math::double4{0, 0, 0, 1}).xyz));
        lights.setDirection(it, normalize(math::float3((place * math::double4{0, 0, -1, 0}).xyz)));
        const float strong = (float)doc_number(d, one.layer, "intensity", now, 1);
        if (lights.getType(it) == LightManager::Type::SUN) lights.setIntensity(it, 60000.f * strong);   // (lux, as the room's own light)
        else lights.setIntensityCandela(it, 60000.f * 36.f * strong);   // (as bright as that six units off: where the stage's own eye stands)
        if (lights.getType(it) == LightManager::Type::SUN)
            lights.setSunAngularRadius(it, (float)doc_number(d, one.layer, "sun_size", now, 1.09) / 2.f), lights.setSunHaloSize(it, (float)doc_number(d, one.layer, "sun_halo", now, 10));
        if (lights.getType(it) == LightManager::Type::FOCUSED_SPOT) {
            const float cone = (float)(doc_number(d, one.layer, "cone", now, 30) * (double)TAU / 360.0);
            lights.setSpotLightCone(it, 0.8f * cone, cone);
        }
    }
    // A clipped layer is seen only inside the frame of the layer before it: Filament's own scissor on its looks, told
    // the rectangle of the picture that the layer before it covers now (turned or leaning: the upright box around it).
    // A group made to mask (its Null's group_mask: Alight Motion's Group and Mask, Group and Exclude): its top layer is
    // the shape, not seen itself; the others in it are seen inside it (or outside, to exclude), as a clipped layer is.
    std::map<int, int> tops;
    for (int layer : lie)
        if (const int g = (int)std::lround(doc_number(d, layer, "parent", 0, 0)); g > 0)
            if (const std::string& how = doc_word(d, g, "group_mask"); how == "mask" || how == "exclude") tops[g] = layer;   // (the last laid: the top)
    int before = 0;
    for (int layer : lie) {
        const auto found = d.shown.find(layer);
        if (found == d.shown.end()) continue;
        Doc::Shown& t = found->second;
        double box[4] = {0, 0, 0, 0};
        const int group = (int)std::lround(doc_number(d, layer, "parent", 0, 0));
        const auto top = tops.find(group);
        const bool grouped = top != tops.end() && top->second != layer;   // (in a group made to mask, not its top: cut by that)
        if (top != tops.end() && top->second == layer) {   // (the group's top: the shape only, as Alight Motion's is not seen)
            if (MaterialInstance* look = t.video ? t.video->look : t.drawn ? t.drawn->look : nullptr) look->setParameter("opacity", 0.f);
            if (t.drawn && t.drawn->edgeLook) t.drawn->edgeLook->setParameter("opacity", 0.f);
        }
        const int by = grouped ? top->second : before;
        const double invert = grouped ? (doc_word(d, group, "group_mask") == "exclude" ? 1.0 : 0.0) : doc_number(d, layer, "clip_invert", 0, 0);
        const bool clipped = t.in && by && (grouped || doc_number(d, layer, "clip", 0, 0) > 0.5) && doc_covers(d, by, now, box);
        // (clipped by a flat layer ThorVG draws, it is cut by that layer's own picture: the kit's matte, After Effects'
        //  alpha matte; by anything else, by the upright box of what that covers)
        const Doc::Shown* const a = clipped ? &d.shown[by] : nullptr;
        const bool shaped = a && a->drawn && (t.drawn || t.video || t.look);   // (a solid too, by its own look: the kit's glass, or its plain look made to be cut)
        Doc::Cut& cut = d.cuts[layer];
        MaterialInstance* const base = t.video ? t.video->look : t.drawn ? t.drawn->look : t.look;
        const auto fx = d.layerFx.find(layer);   // (with effects of its own: the sheet they made is cut, after them, as After Effects cuts a layer by its matte once its effects are on)
        MaterialInstance* const own = fx != d.layerFx.end() && fx->second.look && !fx->second.solid ? fx->second.look : base;
        const auto unmatte = [&](MaterialInstance* look, bool there) {   // (a look no longer cut: there, still made, told so too; a look made again is gone)
            if (!look) return;
            std::erase_if(s.cuts, [&](const Stage::Cut& c) { return c.look == look; });
            if (there) look->setParameter("matteUse", float4{0.f});
        };
        const std::string how = shaped ? doc_word(d, layer, "clip_matte") + " " + std::to_string(invert) + " " + std::to_string(doc_number(d, layer, "clip_feather", 0, 0)) : std::string();   // (said only for one that is cut)
        if (shaped && (cut.from != by || cut.by != a->drawn || cut.how != how)) {   // (its matte takes that picture's shape, at that layer's place, cut as it is said)
            unmatte(cut.look, cut.look == base || cut.look == own);   // (what cut its look before is let go of first)
            if (cut.matte >= 0) {
                Scene* sc = s.mattes[(size_t)cut.matte].scene;
                doc_unshape(s, [sc](const Stage::Renderable& made) { return sc->hasEntity(made.thing); });
            }
            cut.matte = matte(s, a->drawn->sheet, {mat4f(doc_place(d, by, now))}, a->drawn->texture ? a->drawn->texture : white_point(s), doc_word(d, layer, "clip_matte") == "luma", 1.f, cut.matte);
            cut.from = by, cut.by = a->drawn, cut.look = nullptr, cut.how = how;
        }
        if (shaped && cut.look != own && own && cut.matte >= 0) {
            unmatte(cut.look, false);   // (its look made again, or its effects come or gone: what was cut before let go)
            unmatte(base, base && base != own), unmatte(t.drawn ? t.drawn->edgeLook : nullptr, own != base);
            matted(s, own, cut.matte, invert < 0.5, (float)doc_number(d, layer, "clip_feather", 0, 0)), cut.look = own;
            if (own == base && t.drawn && t.drawn->edgeLook) matted(s, t.drawn->edgeLook, cut.matte, invert < 0.5, (float)doc_number(d, layer, "clip_feather", 0, 0));   // (its edge too)
        }   // (its look, or its look made again, is cut by it)
        if (!shaped && cut.look) {   // (no longer cut so: the matte is let go of)
            std::erase_if(s.cuts, [&](const Stage::Cut& c) { return c.look == cut.look; });
            if (cut.look == own) cut.look->setParameter("matteUse", float4{0.f});
            cut.look = nullptr, cut.from = 0, cut.by = nullptr;
            Scene* sc = s.mattes[(size_t)cut.matte].scene;
            doc_unshape(s, [sc](const Stage::Renderable& made) { return sc->hasEntity(made.thing); });
        }
        if (shaped) { if (t.clipped) doc_material_instances(s, t, [](MaterialInstance* look) { look->unsetScissor(); }), t.clipped = false; }
        else if (clipped || t.clipped) {
            const uint32_t left = (uint32_t)std::clamp(box[0], 0.0, (double)s.w), bottom = (uint32_t)std::clamp((double)s.h - (box[1] + box[3]), 0.0, (double)s.h);
            doc_material_instances(s, t, [&](MaterialInstance* look) { if (clipped) look->setScissor(left, bottom, (uint32_t)std::lround(std::max(box[2], 0.0)), (uint32_t)std::lround(std::max(box[3], 0.0))); else look->unsetScissor(); });
            t.clipped = clipped;
        }
        if (t.in) before = layer;
    }
    // An After Effects picture's 3D layers: each at the moment its picture is at, where its pose puts it over that
    // picture's sheet as the stage has it now (the composition's corner at the sheet's top left, a pixel a share of its height).
    for (auto& [layer, t] : d.shown) {
        if (t.deep.empty() || !t.drawn || !t.motion) continue;
        const double since = now - doc_number(d, layer, "start", 0, 0);
        const float sec = t.drawn->seconds > 0.f ? std::fmod((float)std::max(since, 0.0), t.drawn->seconds) : 0.f;
        const float frame = t.drawn->fromFrame + std::min(sec / std::max(t.drawn->seconds, 1e-6f) * t.drawn->frames, std::max(t.drawn->frames - 1.f, 0.f));
        motion_at(*t.motion, frame);
        mat4f sheetAt;
        bool found = false;
        auto& places = s.engine->getTransformManager();
        for (const Stage::Renderable& made : s.renderables)
            if (made.of == t.drawn->sheet && !made.matte && made.nth == 0) { sheetAt = places.getWorldTransform(places.getInstance(made.thing)); found = true; break; }
        const float px = 1.f / t.motion->h;
        const float3 corner{-0.5f * t.motion->w * px, 0.5f, 0.f}, right{px, 0.f, 0.f}, down{0.f, -px, 0.f};
        for (const auto& deep : t.deep) {
            layer_at(s, deep.sheet, frame);
            tvg::Matrix flat;
            float seen = 0.f;
            const bool there = t.in && found && motion_flat(*t.motion, deep.id, &flat, &seen) && seen > 0.f;
            const mat4f at = motion_built(*t.motion, deep.id);
            move(s, deep.sheet->sheet, [&](int, const mat4f&) {
                return there ? sheetAt * motion_in_scene(at, corner, right, down) * mat4f::translation(float3{(deep.box.x + 0.5f * deep.box.z) * px, (deep.box.y + 0.5f * deep.box.w) * px, 0.f}) * mat4f::scaling(float3{1, -1, 1})
                             : mat4f::scaling(0.f);
            });
        }
    }
}

// The stage made to match the document: a layer the document has and the stage has not is made (by the kit's own
// call for its kind), one the stage has and the document has not is taken off, one whose making is told otherwise now
// is made again. false: a layer could not be made (d.error says which, and why).
// All that a layer's making goes by: one changed, the layer is made again (doc_match), carried by a hand too (doc_carry).
static const char* const doc_making = "'kind','file','shape','path','blend','fx','fx_off','keyed','space','begin','duration','speed','text','fill','fill_media','fill_rule','wide','points','inner','round','crop_left','crop_top','crop_right','crop_bottom','bloat','zigzag','offset','warp','clip','stroke','stroke_width','stroke_2','stroke_2_width','stroke_3','stroke_3_width','align','copies','letter_spacing','line_spacing','italic','cap','join','heads','head_size','head_shape','head_start','dash','dash_offset','metallic','roughness','reflectance','clear_coat','clear_coat_roughness','falloff','shadows','shadow_softness','contact_shadows','sheen','anisotropy','shading','thickness','light_group','script','copy_fill','gradient','gradient_angle','gradient_scale','gradient_spread','wrap','wrap_at','split','ior','dispersion','swim','dark','vivid','marker','mosh','mosh_with','mosh_at'";
// A flat layer's effects (ThorVG's, doc_fx): told again at each moment (fx_at), never a reason to make it again. What
// they ask of its making is only which are on and how much room round it they reach (doc_fx_room).
static const char* const doc_fxing = "'blur','shadow','shadow_distance','shadow_angle','shadow_blur','shadow_opacity','glow','glow_blur','glow_opacity','tint','tint_black','tint_white','tritone','tritone_shadow','tritone_midtone','tritone_highlight'";
// How far a layer's effects reach round it at their most (what is carried too), in the document's units, rounded up to
// a power of two: the room its picture is made with, so a number changed within it is drawn again without making it
// again (as a texture atlas keeps power-of-two room). 0: none reach.
static double doc_fx_room(Doc& d, int layer) {
    const auto most = [&](const char* name, double otherwise) { return std::max(doc_most(d, layer, name, otherwise), doc_number(d, layer, name, 0, otherwise)); };
    double r = 3.0 * most("blur", 0);
    if (!doc_word(d, layer, "shadow").empty()) r = std::max(r, most("shadow_distance", 10) + 3.0 * most("shadow_blur", 10));
    return r <= 0.0 ? 0.0 : std::exp2(std::ceil(std::log2(std::max(r, 1.0))));
}

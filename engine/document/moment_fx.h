// moment_fx.h: part of doc.h (a layer with effects of its own, told a moment: layer_fx.h). Read only through doc.h.
// Each drawn alone into a picture of the box it is seen in, its effects run on it, before the stage's own view.
// One whose fx names a solid's shape (solids/*.js, Alight Motion's Box, Torus...): drawn alone square to its own face,
// its effects run on that, and the picture laid on the solid's faces where it lies; its sheet not seen.
static void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e) {   // (before the frame)
    Stage& s = *d.stage;
    math::mat4 place;
    float2 half{0.5f};
    {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
        place = doc_place(d, layer, d.stage->now), doc_half(d, layer, &half);
    }
    thing_fx_face(s, e, place, half);
    thing_fx_pictures(s, e.st, e.view);
    e.look->setParameter("place", mat4f::scaling(float3{0.f}));   // (its sheet: nowhere)
    if (!e.solid || !e.solidLook) return;
    move(s, e.solid, [&](int, const mat4f&) { return mat4f(place); });
    const auto wrap = e.solidRepeat ? TextureSampler::WrapMode::REPEAT : TextureSampler::WrapMode::CLAMP_TO_EDGE;
    e.solidLook->setParameter("image", thing_fx_seen(e.st), TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR, wrap));
}
// A group with effects of its own (a Null its layers go with, its fx saying any, ThorVG's own among them): its layers
// drawn together into its picture, its effects run on that, its sheet laid where it lies, as Alight Motion's group is a
// scene of its own the stage's size (AbsentMotion's StructureActions.kt grouped: an embedScene as wide and high as the
// scene) and After Effects' effects on a precomposed layer work on its layers together.
static bool doc_holds_fx(Doc& d, int layer) {
    if (doc_word(d, layer, "shape") != "null") return false;
    const std::vector<std::string> steps = doc_fx_steps(d, layer);
    return doc_fx_files(steps) || std::any_of(steps.begin(), steps.end(), [](const std::string& w) { return doc_thor_letter(w) != 0; });
}
static bool doc_own_fx(Doc& d, int layer) { return doc_fx_files(doc_fx_steps(d, layer)) || doc_holds_fx(d, layer); }
// Whether its picture stands in the world where it lies (thing_fx_stand): a flat layer, one alone, whose effects work on
// its own picture. Not one that reads what is behind it or draws on the whole stage (the stage's is their frame), nor a
// solid or a layer of many copies (not one face), nor a group (its layers where they are).
static bool doc_layer_stands(Doc& d, int layer, ThingFx& e) {
    thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
    if (e.st.readsBehind || e.st.wide || !e.st.aviutl.empty() || doc_holds_fx(d, layer)) return false;
    for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) return false;
    const auto shown = d.shown.find(layer);
    float2 half{0.f};
    float deep = 0.f;
    return shown != d.shown.end() && !shown->second.solid && doc_members(d, layer) == 1 && doc_half(d, layer, &half, &deep) && deep == 0.f;
}
// Whether a solid stays in the world and shows its picture itself (effected_solid.mat): one whose effects work on its own
// picture, as a stood layer's.
static bool doc_layer_shows(Doc& d, int layer, ThingFx& e) {
    thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
    for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) return false;
    const auto shown = d.shown.find(layer);
    float2 half{0.f};
    float deep = 0.f;
    return shown != d.shown.end() && shown->second.space != 2 && !e.st.readsBehind && !e.st.wide && e.st.aviutl.empty() && (shown->second.solid || (doc_half(d, layer, &half, &deep) && deep > 0.f));
}
// Its picture on its faces while the stage is drawn, or their own looks back, for it to be filmed and told by the document.
static void doc_layer_shell(Doc& d, int layer, ThingFx& e, bool on) {
    const auto t = d.shown.find(layer);
    if (t == d.shown.end() || on != e.looks.empty()) return;
    size_t n = 0;
    doc_parts(*d.stage, t->second, [&](RenderableManager& faces, RenderableManager::Instance one) {
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part, ++n) {
            if (on) e.looks.push_back(faces.getMaterialInstanceAt(one, part)), faces.setMaterialInstanceAt(one, part, e.look);
            else if (n < e.looks.size() && faces.getMaterialInstanceAt(one, part) == e.look) faces.setMaterialInstanceAt(one, part, e.looks[n]);
        }
    });
    if (!on) e.looks.clear();
}
// How far the stage is from a stood layer along its own face (e.sides): a stage's corner laid back on its face, as the eye
// sees a unit along it there; rounded out, so that its picture is made again only as it moves that far. A face seen
// edge on sees no further than the stage's length thrice.
static void doc_fx_sides(Doc& d, const math::mat4& place, double seen, double* sides) {
    const math::double3 x = normalize(place[0].xyz), y = normalize(place[1].xyz - dot(place[1].xyz, x) * x);
    const math::double2 at = doc_seen(d, place[3].xyz), across = doc_seen(d, place[3].xyz + x) - at, up = doc_seen(d, place[3].xyz + y) - at;
    const double det = across.x * up.y - across.y * up.x, w = d.stage->w, h = d.stage->h;
    std::fill(sides, sides + 4, 0.0);
    if (std::fabs(det) < 1e-9 || seen <= 0.0) return;
    const math::double2 corners[4] = {{0, 0}, {w, 0}, {0, h}, {w, h}};
    for (const math::double2& q : corners) {
        const math::double2 v = q - at;
        const double a = (v.x * up.y - v.y * up.x) / det, b = (across.x * v.y - across.y * v.x) / det;
        sides[0] = std::max(sides[0], -a), sides[1] = std::max(sides[1], a), sides[2] = std::max(sides[2], -b), sides[3] = std::max(sides[3], b);
    }
    const double most = 3.0 * std::max(w, h) / seen, step = 256.0 / seen;
    for (int i = 0; i < 4; ++i) sides[i] = std::ceil(std::min(sides[i], most) / step) * step;
}
static void doc_layer_stand(Doc& d, int layer, ThingFx& e) {   // (before the frame)
    math::mat4 place;
    float2 half{0.5f};
    double seen = 0.0;
    {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
        place = doc_shown_at(d, layer, d.stage->now), doc_half(d, layer, &half);
        const math::double2 a = doc_seen(d, place[3].xyz), b = doc_seen(d, place[3].xyz + normalize(d.facing[0].xyz));
        seen = length(b - a);   // (a unit across the eye's sight, where it is)
        doc_fx_sides(d, place, seen, e.sides);
    }
    thing_fx_stand(*d.stage, e, place, half, seen);
}
// Where it is on its picture, as doc_frame says it on the stage: stood, in the picture's middle, upright.
static bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame) {
    if (!e.world) return doc_frame(d, layer, d.stage->now, frame);
    std::copy(e.own, e.own + 4, frame), frame[4] = 0;
    return true;
}
static void doc_layer_solid(Doc& d, int layer, ThingFx& e, const ScreenNumbers& numbers, const std::function<DrawnFx()>& thorFx) {   // (in the frame)
    Stage& s = *d.stage;
    thing_effects_draw(s, e.st, e.view, numbers, thorFx);
    if (solid_reads(e.solidFile)) thing_fx_cover(s, e, (int)(e.parameters.count("precision") ? e.parameters["precision"] : 160)), thing_fx_solid(s, e, true);
}
// What an AviUtl2 script asks of the other layers (aviutl_fx.h): its layers are the document's layers in the order
// they lie, the furthest back layer 1 (doc_laid; AviUtl2 draws layer 1 first, the higher over it). "aviutl.layer":
// its own; "aviutl.layerN[.name][@seconds]": that one's value then, seconds from its start (lua.txt's obj.getvalue
// "layer1.x", time), x and y pixels of the script's frame from its middle (as its obj.x), rz its turn, alpha, time
// from its start; none there or not shown: NaN (nil). "aviutl.groupN": the layer of the Nth group it is in, 0 the
// nearest (obj.getoption "group_info").
static double doc_aviutl_asked(Doc& d, int layer, const double* box, const std::string& name, double usual) {
    const std::vector<int>& laid = doc_laid(d);
    const auto layerOf = [&](int t) { const auto at = std::find(laid.begin(), laid.end(), t); return at == laid.end() ? NAN : (double)(at - laid.begin() + 1); };
    if (name == "aviutl.layer") return std::isnan(layerOf(layer)) ? usual : layerOf(layer);
    if (name == "aviutl.layer_max") return (double)std::max<size_t>(1, laid.size());
    std::smatch m;
    if (std::regex_match(name, m, std::regex(R"(aviutl\.group(\d+))"))) {
        int in = layer;
        for (int n = std::stoi(m[1]); in && n >= 0; --n) in = (int)doc_number(d, in, "parent", d.stage->now, 0);
        return in ? layerOf(in) : NAN;
    }
    if (!std::regex_match(name, m, std::regex(R"(aviutl\.layer(\d+)(?:\.(\w+))?(?:@(.+))?)"))) return NAN;
    const size_t n = std::stoul(m[1]);
    if (n < 1 || n > laid.size()) return NAN;
    const int other = laid[n - 1];
    if (!m[2].matched) return 1;
    const double start = doc_number(d, other, "start", 0, 0), now = m[3].matched ? start + std::atof(m[3].str().c_str()) : d.stage->now;
    const std::string what = m[2];
    if (what == "time") return now - start;
    double frame[8];
    if (!doc_frame(d, other, now, frame)) return NAN;
    const double ppp = (double)d.stage->view->getViewport().width / std::max(1, d.stage->w);
    if (what == "x") return (frame[0] - (box[0] + box[2]) / 2) * ppp;
    if (what == "y") return (frame[1] - (box[1] + box[3]) / 2) * ppp;
    if (what == "z" || what == "rx" || what == "ry" || what == "cx" || what == "cy" || what == "cz") return 0;
    if (what == "rz") return frame[4];
    if (what == "alpha") return doc_number(d, other, "opacity", now, 1);
    if (what == "zoom") return 100;
    return NAN;
}

static void doc_layers_fx(Doc& d) {
    Stage& s = *d.stage;
    s.before.clear(), s.aim.clear(), s.after.clear(), d.beforeOf.clear();
    std::vector<std::pair<int, int>> order;   // (the deepest first: a layer's picture made before that of the group it lies in)
    for (const auto& [layer, e] : d.layerFx) {
        int deep = 0;
        for (int up = (int)doc_number(d, layer, "parent", 0, 0); up > 0 && deep < 64; up = (int)doc_number(d, up, "parent", 0, 0)) ++deep;
        order.emplace_back(-deep, layer);
    }
    std::stable_sort(order.begin(), order.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    for (const auto& [deep, layer] : order) {   // (each drawn alone into a picture, its effects run on it, before the stage's own view: layer_fx.h)
        ThingFx& e = d.layerFx.at(layer);
        thing_effects(s, e.st, doc_fx_join(doc_fx_steps(d, layer)));
        e.solidFile.clear();
        for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) e.solidFile = w;   // (a solid's shape among them: its picture laid on that, layer_fx.h; the last named)
        if (const DocScript* sc = e.solidFile.empty() ? nullptr : doc_script_of(d, e.solidFile)) {   // (its knobs as the document says them now, by their own names; the solid made with them, before the frame)
            e.parameters.clear(), e.words.clear();
            for (size_t i = 0; i < sc->parameters.size(); ++i) {
                const ScriptParameter& k = sc->parameters[i];
                const std::string w = doc_word(d, layer, sc->names[i].c_str());
                if (k.kind != "select") e.parameters[k.name] = doc_number(d, layer, sc->names[i].c_str(), d.stage->now, k.usual);
                else e.words[k.name] = w.empty() ? k.words.substr(0, k.words.find(' ')) : w;
            }
            float2 half{0.5f};
            doc_half(d, layer, &half);
            e.size = 2.f * half;
            thing_fx_solid(s, e, false);
        } else if (e.solid) take_off(s, e.solid), delete e.solid, e.solid = nullptr, e.solidSaid.clear();   // (no longer: its sheet again)
        e.st.sounds = [&d, layer = layer](const std::string& file, const std::string& name, bool fft, int wide) { return doc_sound_now(d, layer, file, name, fft, wide); };
        const ScreenNumbers numbers = [&d, layer = layer, &e = e](const std::string& file, const std::string& name, double usual) {
            std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
            if (name == "clip_time" || name == "clip_length") {   // (how far into it and how long it lasts, seconds: an ISF effect's clip_time and clip_length, isf.cpp, as Sashimono's u_time and u_duration are a clip's)
                const double start = doc_number(d, layer, "start", 0, 0), lasts = doc_number(d, layer, "duration", 0, -1);
                return name == "clip_time" ? d.stage->now - start : lasts > 0 ? lasts : std::max(0.0, doc_seconds(d) - start);
            }
            if (name.rfind("backdropBox_", 0) == 0) {   // (the box its picture is, on the stage's: left, top, width, height, each a share of it: what is behind it read there, effects/sources/from_absent.py)
                const Stage& s = *d.stage;
                const size_t i = std::string("xyzw").find(name.back());
                return i == 0 ? e.box[0] / s.w : i == 1 ? e.box[1] / s.h : i == 2 ? (e.box[2] - e.box[0]) / s.w : (e.box[3] - e.box[1]) / s.h;
            }
            if (name.rfind("layerRect_", 0) == 0) {   // (its own rectangle on its picture, in the picture's pixels: AbsentMotion's layer, where its corner is and how large: effects/sources/from_absent.py)
                double frame[8];
                if (!doc_fx_frame(d, layer, e, frame)) return 0.0;
                const Stage& s = *d.stage;
                const double ppp = (double)s.view->getViewport().width / std::max(1, s.w);
                const size_t i = std::string("xyzw").find(name.back());
                return ppp * (i == 0 ? frame[0] - frame[2] / 2 - e.box[0] : i == 1 ? frame[1] - frame[3] / 2 - e.box[1] : i == 2 ? frame[2] : frame[3]);
            }
            if (name.rfind("aviutl.", 0) == 0) return doc_aviutl_asked(d, layer, e.box, name, usual);   // (an AviUtl2 script asking of the other layers: its layers)
            if (name == "origin_x" || name == "origin_y" || name == "turn" || name == "extent") {   // (where the layer is on the picture now, how turned, how large: an effect's pattern stuck to it)
                double frame[8];
                if (!doc_fx_frame(d, layer, e, frame)) return usual;
                return name == "origin_x" ? frame[0] - e.box[0] : name == "origin_y" ? frame[1] - e.box[1] : name == "turn" ? frame[4] : std::max(frame[2], frame[3]);   // (on its own picture: the box it is seen in)
            }
            if ((name == "blurLength" || name == "angle") && file.ends_with("am_directionalblur.wgsl") && doc_word(d, layer, "fx").find("am_directionalblur.wgsl") == std::string::npos) {
                // (the step its Motion Blur is: as far and that way as its middle goes while its shutter is open, in its picture's pixels, as AbsentMotion's quick smear)
                double open = 0.0, was[8], is[8];
                bool moves = false;
                const double now = d.stage->now;
                if (!doc_shutter(d, layer, now, &open, &moves) || !moves || !doc_frame(d, layer, now - 0.5 * open, was) || !doc_frame(d, layer, now + 0.5 * open, is)) return 0.0;
                const double ppp = (double)d.stage->view->getViewport().width / std::max(1, d.stage->w);
                const math::double3 way = (doc_shown_at(d, layer, now + 0.5 * open)[3] - doc_shown_at(d, layer, now - 0.5 * open)[3]).xyz;
                const double dx = e.world ? dot(way, e.square[0].xyz) * e.own[4] : is[0] - was[0], dy = e.world ? -dot(way, e.square[1].xyz) * e.own[4] : is[1] - was[1];   // (stood: along its own picture)
                return name == "blurLength" ? ppp * std::hypot(dx, dy) : std::atan2(-dy, -dx) * 180.0 / M_PI;   // (its blur reads behind it along the way it is told: told back, it trails behind the way it goes)
            }
            return doc_number(d, layer, doc_screen_parameter(file, name).c_str(), d.stage->now, usual);
        };
        const auto thorFx = [&d, layer = layer, &e = e] {   // (ThorVG's own among its steps, as they are now: lengths in points of the stage)
            std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
            DrawnFx fx;
            std::string why;
            doc_fx(d, layer, d.stage->now, false, 1.0, fx, why, true);
            double frame[8];
            const auto t = d.shown.find(layer);
            if (t != d.shown.end() && t->second.drawn && t->second.drawn->fx.overHigh > 0.f && doc_fx_frame(d, layer, e, frame)) {
                const float k = (float)(frame[3] / (t->second.units * t->second.drawn->fx.overHigh));
                fx.blur *= k, fx.fall *= k, fx.soft *= k;
            }
            return fx;
        };
        s.aim.push_back([&s, &d, layer = layer, &e = e] {   // (before the frame: where it is seen, its pictures, what its sheet shows)
            double box[4] = {0, 0, (double)s.w, (double)s.h}, seen[4];
            {
                std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
                const bool found = !doc_holds_fx(d, layer) && doc_seen_box(d, layer, d.stage->now, seen);   // (a group's picture: the whole stage, as its scene is the stage's size)
                if (found) {   // (where it is seen, as much of it as is on the stage: its picture, After Effects' layer;
                    //  with room around it for what its effects draw outside it, sashimono-edit's BAKE_MARGIN: 128 pixels,
                    //  engine/render/script_bake.py)
                    const double m = 128.0 * s.w / std::max(1u, s.view->getViewport().width);
                    box[0] = std::max(0.0, seen[0] - m), box[1] = std::max(0.0, seen[1] - m), box[2] = std::min((double)s.w, seen[2] + m), box[3] = std::min((double)s.h, seen[3] + m);
                }
                if (box[2] - box[0] < 1 || box[3] - box[1] < 1) box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;   // (none of it on the stage: the whole)
                e.st.frame[0] = 0, e.st.frame[1] = 0, e.st.frame[2] = 1, e.st.frame[3] = 1;
                const bool shown = found && !e.shell && !e.st.wide;
                if (!e.shell && !e.st.wide) {   // (that its frame; its picture the whole stage, as AbsentMotion's effects are cut by the scene: effects.cpp EffectRuntime::draw)
                    e.st.frame[0] = box[0] / s.w, e.st.frame[1] = box[1] / s.h, e.st.frame[2] = (box[2] - box[0]) / s.w, e.st.frame[3] = (box[3] - box[1]) / s.h;
                    box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
                }
                std::copy(e.st.frame, e.st.frame + 4, e.st.own);
                if (shown) e.st.own[0] = seen[0] / s.w, e.st.own[1] = seen[1] / s.h, e.st.own[2] = (seen[2] - seen[0]) / s.w, e.st.own[3] = (seen[3] - seen[1]) / s.h;
                if (e.st.wide) {   // (an AviUtl2 script that draws it: the whole stage its frame, as AviUtl2's object is drawn on the screen and sashimono-edit lays a script's draws in the screen's pixels (engine/render/renderer.py _draw_calls); where it is seen told it)
                    std::copy(found ? seen : box, (found ? seen : box) + 4, e.st.thingSeen);
                    box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
                }
            }
            if (!e.solidFile.empty()) return doc_layer_solid_aim(d, layer, e);
            if (e.st.readsBehind) {   // (its sheet on the screen only, not in the picture of what is behind it that its effect reads: as the glass leaves itself out, render_layers.h)
                s.backdropRead = true;
                for (const Stage::Made& made : s.made) if (made.of == e.sheet) s.engine->getRenderableManager().setLayerMask(s.engine->getRenderableManager().getInstance(made.thing), 0xFF, 0x02);
            }
            e.st.ground = d.backdropIs.size() == 6 ? (int)std::strtol(d.backdropIs.c_str(), nullptr, 16) : -1;   // (the colour behind everything: what an effect reading the frame finds where nothing is drawn)
            if (e.world) doc_layer_stand(d, layer, e);
            else thing_fx_aim(s, e, box);
            thing_fx_pictures(s, e.st, e.view);
            if (e.look) e.look->setParameter("image", thing_fx_seen(e.st), e.shell ? TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST) : TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
            if (e.look) {   // (its glow over what its effects made: the stage's bloom, as a layer without effects glows (doc_evaluate))
                std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
                e.look->setParameter("glowing", (float)doc_number(d, layer, "emissive", d.stage->now, 0) + (doc_word(d, layer, "glow").empty() ? 0.f : 0.35f * (float)doc_number(d, layer, "glow_opacity", d.stage->now, 1)));
            }
        });
        d.beforeOf.push_back(layer);
        s.before.push_back([&d, layer = layer, &e = e, numbers, thorFx] {   // (in the frame: drawn alone, its effects run)
            if (!e.solidFile.empty()) return doc_layer_solid(d, layer, e, numbers, thorFx);
            thing_effects_draw(*d.stage, e.st, e.view, numbers, thorFx);
            if (e.shell) doc_layer_shell(d, layer, e, true);
        });
        if (e.shell) s.after.push_back([&d, layer = layer, &e = e] { doc_layer_shell(d, layer, e, false); });
    }
}

// Told a layer's way of reading what is under it, and the picture of that.
static void doc_reading(Stage& s, Doc::Shown& t, float way, float behind, Texture* picture) {
    const Camera& eye = s.view->getCamera();
    const mat4f seen = mat4f(eye.getProjectionMatrix() * eye.getViewMatrix());
    doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
            if (MaterialInstance* look = faces.getMaterialInstanceAt(one, part); look->getMaterial()->hasParameter("blendWay"))
                look->setParameter("blendWay", way), look->setParameter("behind", behind), look->setParameter("behindEye", seen), look->setParameter("backdrop", picture, TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST));
    });
}
// The same for a layer with effects: what it lays is its sheet, its way taken after its effects (After Effects: a layer's
// blending mode comes after its effects).
static void doc_sheet_reads(Doc& d, int layer, float way, Texture* picture) {
    const auto own = d.layerFx.find(layer);
    if (own == d.layerFx.end() || !own->second.look || !own->second.look->getMaterial()->hasParameter("blendWay")) return;
    own->second.look->setParameter("blendWay", way);
    own->second.look->setParameter("backdrop", picture, TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST));
}
// What a layer reads of what is under it, by a way of lying the GPU's own blending has not (the W3C's backdrop) or a fill
// of what is behind it (After Effects' Adjustment Layer): the stage without it and without all that lies over it, drawn
// into a picture of its own before it is drawn, in the order they lie, so one reads those under it as they are laid. The
// same view the glass is drawn over; Filament's layers leave the rest out for that one picture.
static void doc_layers_read(Doc& d, const std::vector<std::pair<int, Doc::Shown*>>& laid) {
    Stage& s = *d.stage;
    const auto reads = [&](int layer) { return doc_blend_way(doc_word(d, layer, "blend")) || doc_word(d, layer, "fill") == "behind" || doc_sheet_material(d, layer) == "glass"; };   // (a flat layer of glass sees what is behind it through itself: flat.mat)
    for (auto r = d.reads.begin(); r != d.reads.end();) {   // (no longer reading, or gone: let go)
        if (d.shown.count(r->first) && reads(r->first)) { ++r; continue; }
        if (const auto t = d.shown.find(r->first); t != d.shown.end()) doc_reading(s, t->second, 0.f, 0.f, white_point(s));
        doc_sheet_reads(d, r->first, 0.f, white_point(s));
        s.engine->destroy(r->second.into), s.engine->destroy(r->second.seen), r = d.reads.erase(r);
    }
    if (std::none_of(laid.begin(), laid.end(), [&](const auto& l) { return reads(l.first); })) return;
    std::vector<std::function<void()>> fx = std::move(s.before);
    s.before.clear();
    std::vector<utils::Entity> parts;
    std::vector<size_t> from(laid.size());
    for (size_t i = 0; i < laid.size(); ++i) {
        from[i] = parts.size();
        doc_entities(s, *laid[i].second, [&](utils::Entity e) { parts.push_back(e); });
        if (const auto own = d.layerFx.find(laid[i].first); own != d.layerFx.end())
            for (const Stage::Made& made : s.made) if (made.of == own->second.sheet) parts.push_back(made.thing);
    }
    for (size_t i = 0; i < laid.size(); ++i) {
        const int layer = laid[i].first;
        if (reads(layer)) {
            Doc::Read& r = d.reads[layer];
            if (!r.seen) {
                r.seen = Texture::Builder().width((uint32_t)s.w).height((uint32_t)s.h).levels(1).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).format(Texture::InternalFormat::RGBA16F).build(*s.engine);
                r.into = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, r.seen).texture(RenderTarget::AttachmentPoint::DEPTH, s.behindDepth).build(*s.engine);
            }
            const float way = (float)doc_blend_way(doc_word(d, layer, "blend"));
            doc_reading(s, *laid[i].second, d.layerFx.count(layer) ? 0.f : way, doc_word(d, layer, "fill") == "behind" ? 1.f : 0.f, r.seen);
            doc_sheet_reads(d, layer, way, r.seen);
            s.before.push_back([&s, over = std::vector<utils::Entity>(parts.begin() + (long)from[i], parts.end()), into = r.into] {
                auto& faces = s.engine->getRenderableManager();
                std::vector<uint8_t> masks;
                for (utils::Entity e : over) masks.push_back(faces.getLayerMask(faces.getInstance(e))), faces.setLayerMask(faces.getInstance(e), 0xFF, 0x02);
                RenderTarget* const was = s.view_behind->getRenderTarget();
                s.view_behind->setRenderTarget(into);
                s.renderer->render(s.view_behind);
                s.view_behind->setRenderTarget(was);
                for (size_t k = 0; k < over.size(); ++k) faces.setLayerMask(faces.getInstance(over[k]), 0xFF, masks[k]);
            });
        }
        for (size_t k = 0; k < fx.size() && k < d.beforeOf.size(); ++k) if (d.beforeOf[k] == layer) s.before.push_back(std::move(fx[k]));
    }
}

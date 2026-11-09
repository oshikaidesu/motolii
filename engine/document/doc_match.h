// doc_match.h: part of doc.h (the stage made again as the document says; its file opened, changed, undone). Read only through doc.h.
// The values that move a flat shape's points as it is drawn (flat.mat's vertex stage): a shape with any of them cut
// fine all along, one with none only round its curves (a long line in four points, not two thousand).
static const char* const doc_bending = "'warp','bend','twist','pinch','skew','squash','wiggle','stretch','pin_tl_x','pin_tl_y','pin_tr_x','pin_tr_y','pin_bl_x','pin_bl_y','pin_br_x','pin_br_y'";
// A text's words for a column (After Effects' Vertical Type): the signs that lie along a line, in their forms that stand,
// Unicode's own <vertical> table. The long vowel has none there: a stroke as heavy as the letters (no source: a font's vert feature would draw its own, and ThorVG reads no such feature).
static std::string doc_column(std::string words) {
    static const char* const forms[][2] = {{"，", "︐"}, {"、", "︑"}, {"。", "︒"}, {"：", "︓"}, {"；", "︔"}, {"！", "︕"}, {"？", "︖"}, {"〖", "︗"}, {"〗", "︘"}, {"…", "︙"}, {"‥", "︰"}, {"—", "︱"}, {"ー", "丨"}, {"–", "︲"},
                                           {"（", "︵"}, {"）", "︶"}, {"｛", "︷"}, {"｝", "︸"}, {"〔", "︹"}, {"〕", "︺"}, {"【", "︻"}, {"】", "︼"}, {"《", "︽"}, {"》", "︾"}, {"〈", "︿"}, {"〉", "﹀"}, {"「", "﹁"}, {"」", "﹂"}, {"『", "﹃"}, {"』", "﹄"}, {"［", "﹇"}, {"］", "﹈"}};
    for (const auto& form : forms)
        for (size_t at = 0; (at = words.find(form[0], at)) != std::string::npos; at += strlen(form[1])) words.replace(at, strlen(form[0]), form[1]);
    return words;
}

static bool doc_bends(Doc& d, int thing) {
    bool any = false;
    doc_rows(d, sqlite3_mprintf("select 1 from fact where thing = %d and (name in (%s) or (name glob '*_by' and substr(name, 1, length(name) - 3) in (%s))) and (value <> 0 or at <> 0) limit 1", thing, doc_bending, doc_bending),
             [&](sqlite3_stmt*) { any = true; });   // (a bend given by a behaviour bends it too)
    if (d.held.thing == thing)
        for (const auto& [name, is] : d.held.tried) any = any || (is != 0.0 && strstr(doc_bending, ("'" + name + "'").c_str()));
    return any;
}
// A film thing's real datamosh (mosh.h): the film made again with the other's motion poured in, once made; "" none
// (not on, no other film, or not made yet: its own film meanwhile).
// A level's drawing numbered `n`: the drawings of one folder told apart by the number at the end of their names,
// between the name and the ending, as OpenToonz reads a level (animation.0001.tif, animation_0001.tif: tfilepath.cpp's
// (\d+)), `file` one of them; its number as wide as that one's. "": -1, a timesheet's × (none); `file` itself when its
// name ends in no number.
static std::string doc_cel_file(const std::string& file, double n) {
    if (n < 0) return "";
    const std::filesystem::path p(file);
    const std::string stem = p.stem().string();
    size_t from = stem.size();
    while (from > 0 && std::isdigit((unsigned char)stem[from - 1])) --from;
    if (from == stem.size()) return file;
    std::string number = std::to_string((long long)std::llround(n));
    if (number.size() < stem.size() - from) number.insert(0, stem.size() - from - number.size(), '0');
    return (p.parent_path() / (stem.substr(0, from) + number + p.extension().string())).string();
}
static std::string doc_mosh(Doc& d, int thing) {
    if (!doc_on(d, thing, "mosh") || doc_word(d, thing, "kind") != "film") return "";
    const int with = (int)doc_number(d, thing, "mosh_with", 0, 0);
    const std::string file = doc_word(d, thing, "file"), other = with > 0 && with != thing ? doc_word(d, with, "file") : "";
    if (other.empty() || doc_word(d, with, "kind") != "film") return "";
    return mosh_file(file, doc_number(d, thing, "mosh_at", 0, 1), other);
}
// A thing in the lamps' light: as an After Effects 3D layer once its composition has a light; with none, as it is drawn,
// unless it is said to be metal: a metal is what it mirrors, and it mirrors the stage's room (Element 3D's reflection map).
static std::vector<int> doc_things(Doc& d);
// A thing's bevel: which of its ways, 0 none (and none but on a box).
static int doc_bevel(Doc& d, int thing) {
    const std::string way = doc_word(d, thing, "bevel");
    const char* const ways[] = {"angular", "convex", "concave", "ogee", "step"};
    for (int k = 0; k < 5; k++) if (way == ways[k] && doc_on(d, thing, "scale_z")) return k + 1;
    return 0;
}
static bool doc_lit(Doc& d, int thing) {
    const std::string space = doc_word(d, thing, "space");
    if (!doc_among("film text picture shape", doc_word(d, thing, "kind").c_str()) || (space != "3d" && space != "2.5d" && !doc_on(d, thing, "scale_z"))) return false;
    if (doc_on(d, thing, "metallic")) return true;
    for (const int t : doc_things(d)) if (doc_word(d, t, "kind") == "light") return true;
    return false;
}
// A solid is made by its metal, rough and shine; a sheet is told them each moment (doc_moment.h), its picture left alone.
static bool doc_sheet_told(Doc& d, int thing, const std::string& name) {
    return doc_among("metallic roughness reflectance", name.c_str()) && doc_word(d, thing, "kind") != "solid";
}
// A flat sketch as it was last written whole: what its thing is made from, so code typed at is made again once it runs,
// and code half typed leaves the thing as it stood and says why (Shadertoy's editor keeps the last picture that compiled).
static long long doc_sketch_written(Doc& d, const std::string& file) {
    DocSketch& one = doc_scripts_kept(d).sketches[file];
    std::error_code wrong;
    const long long stamp = (long long)std::filesystem::last_write_time(file, wrong).time_since_epoch().count();
    if (wrong || stamp == one.seen) return one.whole;
    one.seen = stamp;
    auto run = std::make_shared<Script>(file, (doc_engine("third_party/js/p5") / "p5.min.js").string());
    if (run->flat()) one.whole = stamp, one.ready = run;
    if (run->ok()) doc_scripts_kept(d).why.erase(file);
    else doc_scripts_kept(d).why[file] = d.trouble = run->trouble();
    return one.whole;
}
static bool doc_match(Doc& d) {
    Stage& s = *d.stage;
    s.frames = doc_number(d, 0, "frame_rate", 0, 0);   // (the document's frame rate: its time seen at its frames from the next picture on)
    std::map<int, std::string> told;   // every thing of the document, and all that its making goes by
    doc_rows(d, sqlite3_mprintf("select thing, group_concat(name || '=' || value, ' ') from (select * from fact where thing > 0 and (name in (%s) or name glob '*_by') and not (name in ('metallic', 'roughness', 'reflectance') and thing in (select thing from fact where name = 'kind' and value != 'solid')) order by thing, name) group by thing", doc_making),
             [&](sqlite3_stmt* row) { told[sqlite3_column_int(row, 0)] = (const char*)sqlite3_column_text(row, 1); });
    for (auto& [thing, of] : told)   // (one way that reads what is under is made as any other: going from one to another tells the look, it makes nothing again)
        if (const size_t at = of.find("blend="); at != std::string::npos) {
            const size_t end = of.find(' ', at);
            if (doc_blend_way(of.substr(at + 6, end == std::string::npos ? std::string::npos : end - at - 6))) of.replace(at + 6, (end == std::string::npos ? of.size() : end) - at - 6, "*");
        }
    for (auto& [thing, of] : told) {
        if (of.find("kind=picture") != std::string::npos)
            if (const std::string file = doc_word(d, thing, "file"); std::filesystem::path(file).extension() == ".js") of += " written=" + std::to_string(doc_sketch_written(d, file));
        if (of.find("kind=solid") != std::string::npos)   // (a three.js part made again from its code: doc_three_saved)
            if (const std::string file = doc_word(d, thing, "file"); std::filesystem::path(file).extension() == ".glb") {
                std::error_code wrong;
                of += " written=" + std::to_string((long long)std::filesystem::last_write_time(file, wrong).time_since_epoch().count());
            }
    }
    for (auto& [thing, of] : told) of += doc_bends(d, thing) ? " bent=1" : " bent=0";   // (bent or not: cut fine, or only round its curves)
    for (auto& [thing, of] : told) {   // (its effects: which are on and the room they reach, not their numbers (doc_fxing))
        const auto on = [&](const char* name) { return std::max(doc_most(d, thing, name, 0), doc_number(d, thing, name, 0, 0)) > 0.0; };
        if (doc_on(d, thing, "mosh")) of += " moshed=" + doc_mosh(d, thing);   // (made again once its datamosh is made)
        if (doc_on(d, thing, "scale_z")) of += " deep";   // (made once more as it is given depth: its sheet a box)
        if (doc_bevel(d, thing)) of += " bevel";
        if (doc_lit(d, thing)) of += " lit";   // (and as a lamp comes or goes)
        if (of.find("kind=text") != std::string::npos) of += " shown=" + doc_text_shown(d, thing, s.now);
        if (of.find("kind=picture") != std::string::npos && !doc_keys_of(d, thing, "cel").at.empty()) of += " cel=" + std::to_string(std::llround(doc_cel(d, thing, s.now)));   // (a level's drawing now: made again as its keys change it (doc_moment))   // (its words as AbsentMotion's text effects show them now: made again as they change (doc_moment))
        of += " order=" + doc_fx_join(doc_fx_list(d, thing)) + " fx=" + std::to_string((int)on("blur")) + (doc_word(d, thing, "shadow").empty() ? "0" : "1") + (doc_word(d, thing, "glow").empty() ? "0" : "1") + std::to_string((int)on("tint")) + std::to_string((int)on("tritone"))
            + " room=" + std::to_string(doc_fx_room(d, thing));
    }
    if (const auto held = told.find(d.held.thing); held != told.end())   // (what a hand carries of its making shows too: it is made again as it would be)
        for (const auto& [name, is] : d.held.said) if (name[0] != ' ') held->second += " " + name + "~" + is;
    if (const auto held = told.find(d.held.thing); held != told.end())
        for (const auto& [name, is] : d.held.tried)
            if (strstr(doc_making, ("'" + name + "'").c_str()) && !doc_sheet_told(d, d.held.thing, name)) {   // (one that moves is drawn again each moment anyway (doc_moment): made again only as it comes on or goes off)
                bool moves = false;
                for (const DocValue& one : doc_values) moves = moves || (one.moves && name == one.name);
                const auto from = d.held.from.find(name);
                if (!moves) held->second += " " + name + "~" + std::to_string(is);
                else if (from != d.held.from.end() && (from->second != 0.0) != (is != 0.0)) held->second += " " + name + "~" + (is != 0.0 ? "on" : "off");
            }
    for (auto it = d.shown.begin(); it != d.shown.end();) {
        const auto still = told.find(it->first);
        if (still != told.end() && still->second == it->second.of && !(it->second.drawn && it->second.drawn->outgrown)) { ++it; continue; }   // (a text told words wider than its picture: made again however it reads)
        if (it->second.scene && it->second.scene != s.scene)   // (out of the scene of its run first: the kit takes things out of the stage's own only)
            doc_entities(s, it->second, [&](utils::Entity e) { it->second.scene->remove(e); });
        if (const Mesh* m = it->second.film ? it->second.film->sheet : it->second.drawn ? it->second.drawn->sheet : it->second.shape)   // (its copies' own looks first, while its copies are still known)
            doc_copy_looks_off(d, m, it->second.film ? it->second.film->look : it->second.drawn ? it->second.drawn->look : it->second.look);
        if (const Mesh* m = it->second.film ? it->second.film->sheet : it->second.drawn ? it->second.drawn->sheet : it->second.shape)   // (and the shape it cuts a matte by: done away with first)
            doc_unshape(s, [m](const Stage::Made& made) { return made.of == m; });
        if (it->second.film) video_off(s, it->second.film);
        if (it->second.drawn) picture_off(s, it->second.drawn);
        for (const auto& deep : it->second.deep) picture_off(s, deep.sheet);
        if (it->second.solid) solid_off(s, it->second.solid);
        if (!it->second.light.isNull()) {   // (out of every scene, and done away with)
            s.scene->remove(it->second.light);
            s.engine->getLightManager().destroy(it->second.light), utils::EntityManager::get().destroy(it->second.light);
        }
        if (it->second.shape) s.playing.erase(it->second.shape), take_off(s, it->second.shape);   // (a cloud's sort goes with it)
        it = d.shown.erase(it);
    }
    bool all = true;
    for (const auto& [thing, of] : told) {
        if (d.shown.count(thing)) continue;
        Doc::Shown made{of};
        const std::string kind = doc_word(d, thing, "kind"), file = doc_word(d, thing, "file"), laid = doc_word(d, thing, "blend"), shape = doc_word(d, thing, "shape");
        const bool effected = doc_fx_files(doc_fx_steps(d, thing));   // (with effects of its own: drawn alone as normal, its way of lying on what is under taken once they are on: screen.h)
        const char* lay = effected || laid.empty() || laid == "normal" || doc_blend_way(laid) ? nullptr : laid.c_str();   // (one that reads what is under: drawn as normal, flat.mat mixes it)
        std::string why = "it could not be read";
        const std::string fill = doc_word(d, thing, "fill");
        // (a fill is a colour, six digits; or, of a text or a flat shape, two colours or more: a ramp down it, each of
        //  them six digits or eight, the last two how much of it is there: a colour fading to clear; each may say where
        //  it stands, @ and a share of the way, as CSS's colour stop positions: ff3366@0.35)
        std::vector<float4> ramp;
        std::vector<float> rampAt;
        long rgb = -1;
        {
            std::istringstream said(fill);
            for (std::string word; said >> word;) {
                const size_t mark = word.find('@');
                const std::string one = word.substr(0, mark);
                rampAt.push_back(mark == std::string::npos ? -1.f : std::clamp(std::strtof(word.c_str() + mark + 1, nullptr), 0.f, 1.f));
                const bool hex = (one.size() == 6 || one.size() == 8) && one.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos;
                const long c = hex ? std::strtol(one.substr(0, 6).c_str(), nullptr, 16) : -1;
                if (c < 0) { ramp.clear(), rgb = -1; break; }
                if (ramp.empty()) rgb = c;
                const float there = one.size() == 8 ? (float)std::strtol(one.substr(6).c_str(), nullptr, 16) / 255.f : 1.f;
                ramp.push_back(float4{(float)((c >> 16) & 255) / 255.f, (float)((c >> 8) & 255) / 255.f, (float)(c & 255) / 255.f, there});
            }
            if (ramp.size() == 1 && ramp[0].w < 1.f) ramp.clear(), rgb = -1;   // (eight digits only down a ramp)
        }
        const float3 colour = float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255), (float)(rgb & 255)} / 255.f;
        // (an edge, ThorVG's stroke: its colour said as a fill is, and its width as a share of the thing's own height,
        //  from points of the picture at size 1 where things stand at first)
        const std::string stroke = doc_word(d, thing, "stroke");
        const long edgeRgb = stroke.size() == 6 && stroke.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos ? std::strtol(stroke.c_str(), nullptr, 16) : -1;
        const math::double4 up = s.camera->getProjectionMatrix() * s.camera->getViewMatrix() * math::double4{0, 1, 0, 1};
        const float4 edge = edgeRgb < 0 ? float4{0.f} : float4{float3{(float)((edgeRgb >> 16) & 255), (float)((edgeRgb >> 8) & 255), (float)(edgeRgb & 255)} / 255.f, (float)(doc_number(d, thing, "stroke_width", 0, 0) / (0.5 * s.h * up.y / up.w))};
        if (!stroke.empty() && edgeRgb < 0) why = "a stroke is six digits, as ff3366";
        const double units = 0.5 * s.h * up.y / up.w;   // (points of the picture to one unit of the stage, where things stand at first)
        DrawnFx fx;
        fx.thick = doc_on(d, thing, "scale_z"), fx.lit = doc_lit(d, thing), fx.bevel = doc_bevel(d, thing) > 0;
        fx.wear = doc_sheet_wear(d, thing);   // (a material it wears: its sheet flat.mat's own for it, in Filament's light (glass reads what is behind, unlit))
        if (!fx.wear.empty() && fx.wear != "glass") fx.lit = true;
        for (const std::string rim : {"stroke_2", "stroke_3"})
            if (const std::string word = doc_word(d, thing, rim.c_str()); word.size() == 6) {
                const long hex = std::strtol(word.c_str(), nullptr, 16);
                const double wide = doc_number(d, thing, (rim + "_width").c_str(), 0, 0) / units;
                if (wide > 0.0) fx.rims.push_back(float4{(float)((hex >> 16) & 255) / 255.f, (float)((hex >> 8) & 255) / 255.f, (float)(hex & 255) / 255.f, (float)wide});
            }
        if (ramp.size() > 1) fx.ramp = ramp;
        if (ramp.size() > 1 && std::any_of(rampAt.begin(), rampAt.end(), [](float a) { return a >= 0.f; })) {   // (placed: one not said stands evenly; one before the one ahead of it stands where that one does, CSS Images 3's colour stop fix-up)
            for (size_t i = 0; i < rampAt.size(); ++i) {
                if (rampAt[i] < 0.f) rampAt[i] = (float)i / (float)(rampAt.size() - 1);
                if (i > 0) rampAt[i] = std::max(rampAt[i], rampAt[i - 1]);
            }
            fx.rampAt = rampAt;
        }
        fx.radial = doc_word(d, thing, "gradient") == "radial", fx.rampAngle = (float)doc_number(d, thing, "gradient_angle", 0, 0), fx.rampScale = (float)doc_number(d, thing, "gradient_scale", 0, 1);
        fx.spread = doc_word(d, thing, "gradient_spread") == "reflect" ? 1 : doc_word(d, thing, "gradient_spread") == "repeat" ? 2 : 0;
        const std::vector<AbsentCopy>& repeated = doc_absent_copies(d, thing, d.stage->now);
        fx.copies = repeated.empty() ? (int)doc_number(d, thing, "copies", 0, 1) : (int)repeated.size();   // (as many as AbsentMotion's repeat lays, as doc_members says)
        {   // (its copies drawn in one go where none is cleared of its own (no script that says opacity) and their colours are a ramp flat.mat knows; a picture's own 3D layers neither)
            const std::string fills = doc_word(d, thing, "copy_fill"), script = doc_word(d, thing, "script");
            std::istringstream said(fills);
            int colours = 0;
            for (std::string one; said >> one && one != "none";) ++colours;
            const DocScript* sc = doc_script_of(d, script);
            bool connected = false;   // (a value given each copy by a behaviour: each copy its own look, not drawn in one go)
            doc_rows(d, sqlite3_mprintf("select 1 from fact where thing = %d and name glob '*_by' and value <> 0 limit 1", thing), [&](sqlite3_stmt*) { connected = true; });
            const bool faded = std::any_of(repeated.begin(), repeated.end(), [](const AbsentCopy& c) { return c.alpha < 0.999; });   // (AbsentMotion's copies fading each, a scatter field's far ones: each its own)
            const std::vector<DocScript*> laying = doc_expressions_fx(d, thing);   // (its expressions: each may say opacity too)
            const bool clears = (sc && sc->clears) || std::any_of(laying.begin(), laying.end(), [](const DocScript* e) { return e->clears; });
            fx.together = fx.copies > 1 && (kind == "shape" || kind == "text") && colours <= 8 && !clears && !connected && !faded;   // (eight colours at most: flat.mat's ramp)
        }
        fx.wrapWidth = (float)doc_number(d, thing, "wrap_at", 0, 0);
        const std::string split = doc_word(d, thing, "split"), script = doc_word(d, thing, "script");
        fx.splitWords = split == "words";
        fx.split = split == "letters" || fx.splitWords || (split.empty() && ((!script.empty() && script != "none") || !doc_expressions_fx(d, thing).empty()));   // (a text given a script or an expression moves letter by letter, as Cavalry's are, unless said none)
        { const std::string w = doc_word(d, thing, "wrap"); fx.wrap = w == "character" || w == "vertical" ? 1 : w == "word" ? 2 : w == "smart" ? 3 : w == "ellipsis" ? 4 : fx.wrapWidth > 0.f ? 2 : 0; if (w == "vertical") fx.wrapWidth = 1.f, fx.column = true; }   // (ThorVG's TextWrap; a box said and no way: by words; vertical: a box a letter wide)
        fx.letters = (float)doc_number(d, thing, "letter_spacing", 0, 1), fx.lines = (float)doc_number(d, thing, "line_spacing", 0, 1), fx.italic = (float)doc_number(d, thing, "italic", 0, 0);
        const auto which = [&](const char* name, const char* words) { const std::string w = doc_word(d, thing, name); if (w.empty()) return -1; int n = 0; for (const char* at = words; *at; ++n) { const size_t len = strcspn(at, " "); if (w == std::string(at, len)) return n; at += len + (at[len] ? 1 : 0); } return -1; };
        fx.cap = which("cap", "butt round square"), fx.join = which("join", "miter round bevel");
        fx.rampBlend = std::max(0, which("gradient_blend", "rgb oklab hue steps"));   // (ThorVG's StrokeCap and StrokeJoin, in its order)
        fx.heads = std::max(0, which("heads", "none end start both")), fx.headSize = (float)doc_number(d, thing, "head_size", 0, 4), fx.headShape = std::max(0, which("head_shape", "arrow circle box chevron bar t_line square square_filled diamond diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled teardrop_hollow teardrop_filled")), fx.headStart = which("head_start", "arrow circle box chevron bar t_line square square_filled diamond diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled teardrop_hollow teardrop_filled");
        fx.dash = (float)(doc_number(d, thing, "dash", 0, 0) / units), fx.dashFrom = (float)(doc_number(d, thing, "dash_offset", 0, 0) / units);
        bool fxOk = doc_fx(d, thing, 0.0, true, units, fx, why);   // (made as large as its effects reach at their most; each moment tells them as they are then)
        if (!fxOk && doc_fx_files(doc_fx_steps(d, thing))) { d.trouble = why + ": the " + kind + " " + std::filesystem::path(file + shape).filename().string() + " could not be made"; all = false; continue; }   // (an effect file of any kind of thing, as a picture's own file is refused)
        made.units = units;
        if (doc_among("film picture text shape", kind)) made.space = doc_word(d, thing, "space") == "2.5d" ? 25 : doc_word(d, thing, "space") == "3d" ? 3 : 2;
        if (kind == "behaviour") made.behaviour = true;   // (nothing of it is seen: it says how values of others go)
        else if (kind == "camera") made.camera = true;   // (nothing of it is seen: it is how the rest is)
        else if (kind == "light") {   // (Filament's own light, made as the document says; placed and told how strong at each moment)
            const LightManager::Type type = file == "sun" ? LightManager::Type::SUN : file == "spot" ? LightManager::Type::FOCUSED_SPOT : LightManager::Type::POINT;
            if (!doc_among("sun point spot", file.c_str())) why = "a light is a sun, a point or a spot";
            else {
                made.light = utils::EntityManager::get().create();
                LightManager::ShadowOptions shade;   // (a finer map than as it comes, so the edge is not stepped; a lamp as large as its softness says)
                shade.mapSize = 2048;
                const float soft = (float)doc_number(d, thing, "shadow_softness", 0, 0);
                shade.screenSpaceContactShadows = doc_number(d, thing, "contact_shadows", 0, 0) > 0.5;
                if (soft > 0.f) shade.shadowBulbRadius = type == LightManager::Type::SUN ? 0.05f * soft : 0.5f * soft;
                LightManager::Builder(type).color(Color::toLinear<ACCURATE>(sRGBColor{fill.empty() ? float3{1.f} : colour})).falloff((float)doc_number(d, thing, "falloff", 0, 10))
                    .castShadows(doc_number(d, thing, "shadows", 0, 0) > 0.5).shadowOptions(shade).build(*s.engine, made.light);
                if (const int group = (int)doc_number(d, thing, "light_group", 0, 0); group > 0) {
                    auto& lights = s.engine->getLightManager();
                    lights.setLightChannel(lights.getInstance(made.light), 0, false), lights.setLightChannel(lights.getInstance(made.light), (unsigned)group, true);
                }
                made.in = false;   // (in the scenes when it is on)
            }
        }
        else if (shape.empty() && !std::filesystem::is_regular_file(file)) why = "there is no such file";
        else if (kind == "film") {
            const std::string moshed = doc_mosh(d, thing);   // (its datamosh, once made: played in its place, from its start)
            const double from = moshed.empty() ? doc_number(d, thing, "begin", 0, 0) : 0.0, length = doc_number(d, thing, "duration", 0, -1), speed = doc_number(d, thing, "speed", 0, 1);
            made.film = video(s, (moshed.empty() ? file : moshed).c_str(), mat4f{}, 1.f, (float)from, length < 0 ? -1.f : (float)(from + length * std::fabs(speed)), (float)speed, lay, fx.lit, fx.wear);
            if (!made.film) why = video_trouble;
            else if (const double keyed = doc_number(d, thing, "keyed", 0, -1); keyed != 0.0) key_own(made.film, keyed > 0.5);   // (not said: keyed if it has a ground of its own)
            if (made.film) s.playing.erase(made.film);   // (the document tells it its moment, and when its sound comes on)
            if (made.film && made.film->sound) s.sounding[made.film] = [&d, thing, v = made.film, file] {   // (counted from where the film being written begins: a sound already going then is heard from that far into it)
                const double on = doc_number(d, thing, "start", 0, 0) - d.written_from, lasts = doc_number(d, thing, "duration", 0, -1), late = std::max(0.0, -on);
                Stage::Sound a{file, v->from, v->to, v->speed, late, std::max(0.0, on), lasts < 0.0 ? lasts : std::max(1e-3, lasts - late), doc_number(d, thing, "volume", 0, 1)};
                if (doc_keys_of(d, thing, "volume").at.size() > 1)   // (keyed: Alight Motion's Volume with its keys and eases, read each 1/30 s, as the document reads it)
                    for (double t = 0.0, end = a.lasts >= 0.0 ? a.lasts : doc_seconds(d) - d.written_from - a.on; t <= end + 1e-9 && a.loud.size() < 30 * 3600; t += 1.0 / 30.0)
                        a.loud.push_back((float)doc_number(d, thing, "volume", d.written_from + a.on + t, 1));
                return a;
            };
        } else if (kind == "picture") {
            std::string shown = file;
            if (const Doc::Keys& cels = doc_keys_of(d, thing, "cel"); !cels.at.empty()) {   // (a level: the drawing its keys say now, held to the next as a timesheet holds it)
                made.cel = doc_cel(d, thing, s.now), made.celMove = cels.at.size() > 1;
                shown = doc_cel_file(file, made.cel);
                if (!shown.empty() && !std::filesystem::is_regular_file(shown)) why = "no drawing " + std::to_string((long long)made.cel) + " beside " + std::filesystem::path(file).filename().string(), shown.clear();   // (OpenToonz marks a drawing its level lacks, red; it is not filled in)
            }
            float rollHigh = 1.f;   // (a MIDI file: its piano roll, at its speed's tempo: midi_roll.cpp)
            if (std::filesystem::path(file).extension() == ".mid") {
                const double speed = doc_number(d, thing, "speed", 0, 1);
                shown = midi_roll_file(file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why);
                double w = 0, h = 0;   // (a point of it a point of the document, as ALMaMPlayer's 1920 x 1080 screen shows it)
                if (!shown.empty() && midi_roll_box(shown, w, h)) rollHigh = (float)(h / doc_point(d, thing, 0));
            }
            const std::string ext = std::filesystem::path(file).extension().string();
            const double cl = doc_number(d, thing, "crop_left", 0, 0), ct = doc_number(d, thing, "crop_top", 0, 0), cr = doc_number(d, thing, "crop_right", 0, 0), cb = doc_number(d, thing, "crop_bottom", 0, 0);
            const bool cropped = cl + ct + cr + cb > 0.0;
            const float aspect = doc_among(".jpg .jpeg .png .webp .bmp .JPG .JPEG .PNG", ext) && (edge.w > 0.f || doc_number(d, thing, "round", 0, 0) > 0.0 || cropped) ? picture_aspect(s, file.c_str()) : 0.f;
            if (ext == ".js") {   // (a p5.js sketch that paints in 2D, what it paints ThorVG's: drawn_sketch.h)
                std::string under;   // (the film under it: what its createCapture and createVideo see)
                for (int t : doc_laid(d)) { if (t == thing) break; if (doc_word(d, t, "kind") == "film") under = doc_word(d, t, "file"); }
                std::shared_ptr<Script>& ready = doc_scripts_kept(d).sketches[file].ready;   // (what was run to see it runs, where no film is under it)
                auto run = ready && under.empty() ? std::exchange(ready, nullptr) : std::make_shared<Script>(file, (doc_engine("third_party/js/p5") / "p5.min.js").string(), under);
                if (!run->flat()) why = run->ok() ? "not a 2D sketch: " + file : run->trouble();
                else if (fxOk && (made.drawn = sketch_picture(s, run, (doc_engine("third_party/filament_src/assets/fonts") / "Roboto-Medium.ttf").string(), 1.f, lay, fx))) s.playing.erase(made.drawn);
            } else if (fxOk && aspect > 0.f) {   // (a photo with an edge, round corners or cut in: a rect as wide as it is, its own file its fill, as a shape filled with media is (Alight Motion's media layers take a border as its shapes do))
                DrawnFx own = fx;
                own.media = file;
                char cut[256];   // (cut in: the rect it shows a path of its own within the whole photo, in its height from its middle, so what is left stays where it was)
                std::snprintf(cut, sizeof cut, "M%.5f %.5f L%.5f %.5f L%.5f %.5f L%.5f %.5f Z", aspect * (cl - 0.5), ct - 0.5, aspect * (0.5 - std::min(cr, 0.95 - cl)), ct - 0.5,
                              aspect * (0.5 - std::min(cr, 0.95 - cl)), 0.5 - std::min(cb, 0.95 - ct), aspect * (cl - 0.5), 0.5 - std::min(cb, 0.95 - ct));
                made.drawn = flat(s, cropped ? cut : "rect", aspect, mat4f{}, 1.f, float3{1.f}, lay, edge, own.over(1.f), 4, 0.5f, (float)doc_number(d, thing, "round", 0, 0));
            } else if (fxOk && !shown.empty() && (made.drawn = picture(s, shown.c_str(), mat4f{}, rollHigh, float3{-1.f}, true, lay, fx, doc_word(d, thing, "marker").c_str()))) s.playing.erase(made.drawn);
            if (made.drawn && made.drawn->lottie && !picture_deep(s, made.drawn).empty()) {   // (its 3D layers stood up where they are, as After Effects shows them)
                made.motion = std::make_shared<Motion>();
                if (motion_open(*made.motion, file.c_str()))
                    for (uint32_t id : made.drawn->deep) {
                        float4 box;
                        if (Drawn* own = layer_picture(s, file.c_str(), id, 1.f / made.motion->h, &box)) made.deep.push_back({id, own, box});
                    }
            }
        } else if (kind == "text") {   // (words in a font: said by `say N text ...`; until then, the font's own name)
            const std::string words = doc_text_shown(d, thing, s.now, &made.wordsMove);   // (as typed, or as AbsentMotion's text effects show them now)
            made.words = words;
            if (!fill.empty() && fill != "behind" && rgb < 0) why = "a text's fill is six digits, as ff3366, or behind (what is behind it)";
            else if ((stroke.empty() || edgeRgb >= 0) && fxOk) made.drawn = type(s, words.empty() ? std::filesystem::path(file).stem().string().c_str() : (fx.column ? doc_column(words) : words).c_str(), file.c_str(), mat4f{}, 1.f, fill.empty() ? float3{0x11 / 255.f} : colour, lay, edge, fx.column ? .5f : (float)doc_number(d, thing, "align", 0, 0), fx);
        } else if (kind == "shape") {   // (a flat shape in one colour: ThorVG's own rectangle or circle)
            if (!fill.empty() && fill != "none" && fill != "behind" && rgb < 0) why = "a shape's fill is six digits, as ff3366, none, or behind (what is behind it)";
            else if ((!stroke.empty() && edgeRgb < 0) || !fxOk) {}
            else if (shape == "solid") {   // (a flat colour as large as the stage, where it stands at first: as wide to its height, and as high in the stage's units)
                const float high = (float)(2.0 * up.w / up.y);
                made.drawn = flat(s, "rect", (float)s.w / (float)s.h, mat4f{}, high, fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour, lay, float4{edge.xyz, edge.w / high}, fx.over(high));
            } else {   // (a line is long and thin as it comes: 25 times as long as it is thick, a tenth of a unit thick)
                const bool line = shape == "line", wave = shape == "wave";   // (a wave: a line waving, ten times as long as it is high)
                fx.hollow = fill == "none";   // (filled with nothing: its edge alone, a frame)
                fx.media = doc_word(d, thing, "fill_media");   // (filled with a picture's file: drawn_made.h flat)
                fx.evenOdd = doc_word(d, thing, "fill_rule") == "evenodd";
                const float high = line ? 0.04f : wave ? 0.3f : 1.f;
                // (its outline alone, in one colour: cut into triangles and drawn by Filament as the scene's other things
                //  are, flat_mesh; with an edge, a ramp, a dash, effects, a trim or a bend made on the CPU: ThorVG's picture)
                const std::string drawn = doc_word(d, thing, "path"), form = shape != "path" ? shape : drawn.empty() ? "M0 0" : drawn;   // (a path shape: its own path is its form; none yet: nothing)
                const bool plain = !fx.thick && !wave && shape != "spiral" && shape != "null" && fx.media.empty() && fx.ramp.size() < 2 && fx.blur <= 0.f && fx.shadow.w <= 0.f && fx.tint <= 0.f && fx.tritone <= 0.f;
                if (plain)
                    made.drawn = flat_mesh(s, form.c_str(), (float)doc_number(d, thing, "wide", 0, line ? 25 : 1), mat4f{}, high, fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour, lay,
                                           float4{edge.xyz, edge.w / high}, fx.over(high), (int)doc_number(d, thing, "points", 0, shape == "star" ? 5 : shape == "arc" ? 270 : shape == "squircle" ? 4 : shape == "cog" ? 12 : shape == "spiral" ? 3 : 6), (float)doc_number(d, thing, "inner", 0, shape == "cog" ? 0.2 : shape == "arc" ? 0.3 : shape == "spiral" ? 0.1 : shape == "chamfer" ? 0.3 : 0.5), (float)doc_number(d, thing, "round", 0, 0), doc_bends(d, thing));
                else made.drawn = flat(s, form.c_str(), (float)doc_number(d, thing, "wide", 0, line ? 25 : wave ? 10 : 1), mat4f{}, high, fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour, lay,
                                  float4{edge.xyz, edge.w / high}, fx.over(high),
                                  (int)doc_number(d, thing, "points", 0, shape == "star" ? 5 : shape == "arc" ? 270 : shape == "squircle" ? 4 : shape == "cog" ? 12 : shape == "spiral" ? 3 : wave ? 4 : 6), (float)doc_number(d, thing, "inner", 0, shape == "cog" ? 0.2 : shape == "arc" ? 0.3 : shape == "spiral" ? 0.1 : shape == "chamfer" ? 0.3 : 0.5), (float)doc_number(d, thing, "round", 0, 0));
            }
        } else if (kind == "solid") {   // (one of the kit's shapes, or a file; its fill is its surface: a colour, or the material glass)
            const std::string wears = doc_material(d, thing);   // (its material: Create's Material group, or a fill of glass as before)
            const bool glass = wears == "glass", coloured = !fill.empty() && fill != "glass";
            const auto glassy = [&](MaterialInstance* look) {   // (the kit's glass as the document says it; not said, as it comes)
                look->setParameter("ior", (float)doc_number(d, thing, "ior", 0, 1.5)), look->setParameter("split", (float)doc_number(d, thing, "dispersion", 0, 0.1));
                look->setParameter("swim", (float)doc_number(d, thing, "swim", 0, 0.5)), look->setParameter("dark", (float)doc_number(d, thing, "dark", 0, 4));
                look->setParameter("vivid", (float)doc_number(d, thing, "vivid", 0, 1.3));
            };
            const Surface surface{(float)doc_number(d, thing, "metallic", 0, 0.08), (float)doc_number(d, thing, "roughness", 0, 0.6), (float)doc_number(d, thing, "reflectance", 0, 0.5),
                                  (float)doc_number(d, thing, "clear_coat", 0, 0), (float)doc_number(d, thing, "clear_coat_roughness", 0, 0), (float)doc_number(d, thing, "emissive", 0, 0),
                                  (float)doc_number(d, thing, "sheen", 0, 0), (float)doc_number(d, thing, "anisotropy", 0, 0), (float)doc_number(d, thing, "thickness", 0, 0.5)};
            const std::string shading = doc_word(d, thing, "shading");
            const char* model = doc_number(d, thing, "clip", 0, 0) > 0.5 && (shading.empty() || shading == "lit") ? "floor_lit_matte.filamat" : surface_model(shading);   // (clipped: one a matte can cut)
            const bool own = doc_among("filament_glass lacquer bubble", wears);   // (worn by a kit material of its own, not Filament's lit surface: solid_wear)
            const float3 tone = coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f;
            const auto wear = [&](Mesh* m, int copies) { return solid_wear(s, m, std::vector<mat4f>((size_t)std::max(1, copies), mat4f{}), wears, wears == "filament_glass" && !coloured ? float3{1.f} : tone, (float)doc_number(d, thing, "ior", 0, 1.5), (float)doc_number(d, thing, "dispersion", 0, 0.1),
                                                                         (float)doc_number(d, thing, "swim", 0, 0.5), (float)doc_number(d, thing, "dark", 0, 4), (float)doc_number(d, thing, "vivid", 0, 1.3), (float)doc_number(d, thing, "metallic", 0, 0.08)); };
            if (coloured && (rgb < 0 || ramp.size() > 1)) why = "a solid's fill is six digits, as ff3366, or glass";
            else if (!shape.empty()) {
                made.sketch = shape == "sketch";
                made.shape = made.sketch ? sketch_mesh() : shape == "gem" ? gem(0.5f) : shape == "cube" ? cube(0.1f) : shape == "ball" ? sphere(0.5f) : torus(0.37f, 0.13f);
                MaterialInstance* look = glass ? thick_glass(s, made.shape, {mat4f{}}) : own && !made.sketch ? wear(made.shape, (int)doc_number(d, thing, "copies", 0, 1)) : add(s, made.shape, made.sketch ? "sketch.filamat" : model, std::vector<mat4f>((size_t)std::max(1, (int)doc_number(d, thing, "copies", 0, 1)), mat4f{}));
                made.look = look;
                if (look && glass) glassy(look);
                if (look && made.sketch) for (int i = 0; i < 6; ++i) look->setParameter(("picture" + std::to_string(i)).c_str(), white_point(s), TextureSampler());
                if (!look) made.shape = nullptr;
                else if (!glass && !(own && !made.sketch)) plain(look, coloured ? colour : made.sketch ? float3{1.f} : float3{0xd9, 0xd2, 0xc3} / 255.f, surface);
            } else if (std::filesystem::path(file).extension() == ".ply") {   // (a point cloud: its grains, one buffer, points.h)
                for (const std::string& w : doc_fx_list(d, thing)) if (std::filesystem::path(w).extension() == ".mjs") made.splatFxFile = w;   // (a PlayCanvas splat effect on it: its look made with it)
                std::string effectWhy;
                Material* with = made.splatFxFile.empty() ? nullptr : points_effect(s, made.splatFxFile, made.splatFx, effectWhy);
                if (!effectWhy.empty()) std::fprintf(stderr, "%s\n", effectWhy.c_str());
                float3 box[2];
                made.shape = points(s, file.c_str(), why, &made.look, with, &made.splatPlain, box);
                if (made.splatFx)   // (a PlayCanvas effect's box, as it comes: the cloud's own)
                    for (int c = 0; c < 3; ++c) made.splatFx->usual(std::string("aabbMin_") + "xyz"[c], box[0][c]), made.splatFx->usual(std::string("aabbMax_") + "xyz"[c], box[1][c]);
                made.grains = made.shape != nullptr;
            } else if (glass || own) {   // (a file's shape as glass, or worn by a kit material of its own: its triangles alone, for the kit's glass, which draws a shape three times)
                MaterialInstance* look = (made.shape = solid_mesh(file.c_str())) ? glass ? thick_glass(s, made.shape, {mat4f{}}) : wear(made.shape, (int)doc_number(d, thing, "copies", 0, 1)) : nullptr;
                made.look = look;
                if (!look) made.shape = nullptr; else if (glass) glassy(look);
            }
            else if ((made.solid = solid(s, file.c_str(), mat4f{}, 1.f, (int)doc_number(d, thing, "copies", 0, 1))) && (rgb >= 0 || !shading.empty())) solid_fill(s, made.solid, coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f, surface, model);   // (its own look, unless it is coloured or wears a material)
            if (made.solid) s.playing.erase(made.solid);   // (the document tells it its moment)
        } else why = std::string("its kind is one of: ") + doc_kinds;
        if (made.celMove && !made.drawn) {   // (a level at a ×, or at a drawing it lacks: kept, nothing shown, so that its next drawing is seen)
            if (made.cel >= 0) d.trouble = why + ": the picture " + std::filesystem::path(file).filename().string(), all = false;
        } else if (!made.film && !made.drawn && !made.solid && !made.shape && !made.camera && made.light.isNull() && kind != "behaviour") { d.trouble = why + ": the " + kind + " " + std::filesystem::path(file + shape).filename().string() + " could not be made"; all = false; continue; }
        d.shown[thing] = made;
        if ((made.solid || made.shape) && !made.grains) {   // (a solid thing casts a shadow from a light that throws them, and takes one; a cloud's grains are their own light)
            const int group = (int)doc_number(d, thing, "light_group", 0, 0);
            doc_parts(s, d.shown[thing], [group](RenderableManager& faces, RenderableManager::Instance one) {
                faces.setCastShadows(one, true), faces.setReceiveShadows(one, true), faces.setScreenSpaceContactShadows(one, true);   // (contact shadows: Filament draws them only where the light asks too)
                if (group > 0) faces.setLightChannel(one, (unsigned)group, true);
            });
        }
    }
    doc_moment(d, s.now);
    return all;
}


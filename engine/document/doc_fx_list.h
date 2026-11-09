// doc_fx_list.h: part of doc.h (a thing's effects in the order they are laid, and as its stack runs them). Read only through doc.h.
static int doc_keys(Doc& d, int thing, const char* name, double at);
// A value at its most: the highest of its keys, or what it is said to be (how far a moving effect may reach).
static double doc_fx_room(Doc& d, int thing);
static bool doc_on(Doc& d, int thing, const char* name);
// A thing's effects in the order they are laid, After Effects' stack: its "fx" names them in turn, files (.wgsl) and
// ThorVG's own alike (doc_thor_names), any order; one of ThorVG's that is on and not named (a document from before)
// lies first, in the old order (colours, shadow, glow, blur).
// off: those turned off too (fx_off: Alight Motion's eye on an effect), as its cards list them; else only those on.
static std::vector<std::string> doc_fx_list(Doc& d, int thing, bool off) {
    std::vector<std::string> said, all;
    const std::string hidden = off ? std::string() : ";" + doc_word(d, thing, "fx_off") + ";";
    const auto seen = [&](const std::string& w) { return hidden.size() <= 2 || hidden.find(";" + doc_fx_title(w) + ";") == std::string::npos; };
    for (const std::string& w : script_files(doc_word(d, thing, "fx"))) if (w != "none" && w != "glow") said.push_back(w);   // (a glow is no step of the stack: Filament's bloom, doc_moment)
    for (const char* n : doc_thor_names) if (std::find(said.begin(), said.end(), n) == said.end() && doc_on(d, thing, n) && seen(n)) all.push_back(n);
    for (const std::string& w : said) if ((!doc_thor_letter(w) || doc_on(d, thing, w.c_str())) && seen(w)) all.push_back(w);
    if (!off && d.held.thing == thing)   // (and the one a hand carries, as it is drawn: doc_carry_effect)
        if (const auto e = d.held.said.find(" effect"); e != d.held.said.end() && std::find(all.begin(), all.end(), e->second) == all.end()) all.push_back(e->second);
    return all;
}
// Whether a thing's effects are laid on it as the camera sees it (one of them a file: then all of them, in turn, there:
// screen.h thing_effects_draw), not in its own picture as ThorVG draws it.
static bool doc_fx_files(const std::vector<std::string>& list) {
    return std::any_of(list.begin(), list.end(), [](const std::string& w) { const std::string ext = std::filesystem::path(w).extension().string(); return !doc_thor_letter(w) && ext != ".mjs" && ext != ".am" && ext != ".json"; });   // (a splat effect is in the cloud's own look; AbsentMotion's motion moves the thing, absent_motion.h; Filament's own settings are the stage's)
}
// Its effects as its stack runs them: as listed, AbsentMotion's Motion Blur and Shutter Blur each a step of AbsentMotion's
// own Directional Blur beside it on the shelf, told how far and which way the thing goes while its shutter is open
// (doc_moment_fx.h: AbsentMotion's quick smear, styles.cpp DrawShuttered's SmearFilter).
static std::vector<std::string> doc_fx_steps(Doc& d, int thing) {
    std::vector<std::string> steps = doc_fx_drawn(d, doc_fx_list(d, thing));   // (its expressions are not drawn: doc_expressions.h)
    for (std::string& w : steps)
        if (std::filesystem::path(w).extension() == ".am")
            if (const DocScript* sc = doc_script_of(d, w); sc && (sc->absent == "motionblur" || sc->absent == "shutterblur")) w = (std::filesystem::path(w).parent_path() / "am_directionalblur.wgsl").string();
    return steps;
}
static std::string doc_fx_join(const std::vector<std::string>& list) {
    std::string all;
    for (const std::string& w : list) all += (all.empty() ? "" : " ") + w;
    return all;
}
static double doc_most(Doc& d, int thing, const char* name, double otherwise) {
    double most = doc_number(d, thing, name, 0, otherwise);
    if (doc_keys(d, thing, name, -1.0)) doc_rows(d, sqlite3_mprintf("select max(value) from fact where thing = %d and name = %Q", thing, name), [&](sqlite3_stmt* row) { most = sqlite3_column_double(row, 0); });
    return most;
}
// The effects of a flat thing at a moment (or, `most`, as far as each reaches at its most), ThorVG's own: in shares of
// its height from points of the picture (`units` to a unit of the stage, as it was made). false: a colour is not
// six digits (why says which).
static bool doc_fx(Doc& d, int thing, double at, bool most, double units, DrawnFx& fx, std::string& why, bool camera = false) {
    const auto num = [&](const char* name, double otherwise) { return most ? doc_most(d, thing, name, otherwise) : doc_number(d, thing, name, at, otherwise); };
    bool ok = true;
    const auto hue = [&](const char* name, const char* otherwise, float3* to) {   // (a colour said as six digits; not said: as it comes)
        std::string said = doc_word(d, thing, name);
        if (said.empty()) said = otherwise;
        const long rgb = said.size() == 6 && said.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos ? std::strtol(said.c_str(), nullptr, 16) : -1;
        if (rgb < 0) return ok = false, why = std::string("a ") + name + " is six digits, as ff3366", void();
        *to = float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255), (float)(rgb & 255)} / 255.f;
    };
    fx.blur = (float)(num("blur", 0) / units);
    if (most) fx.room = (float)(doc_fx_room(d, thing) / units);   // (the room it is made with: a power of two, so a change within it makes nothing again)
    const std::string way = doc_word(d, thing, "blur_direction");
    fx.blurWay = way == "horizontal" ? 1 : way == "vertical" ? 2 : 0;
    if (!doc_word(d, thing, "shadow").empty()) {   // (After Effects' own drop shadow, as it comes: half of it, 135 degrees, 10 points away, 10 soft)
        float3 dark{0.f};
        hue("shadow", "000000", &dark);
        fx.shadow = float4{dark, (float)num("shadow_opacity", 0.5)};
        fx.fall = (float)(num("shadow_distance", 10) / units), fx.way = (float)num("shadow_angle", 135), fx.soft = (float)(num("shadow_blur", 10) / units);
    }
    if ((fx.tint = (float)num("tint", 0)) > 0.f) hue("tint_black", "1b1f5c", &fx.tints[0]), hue("tint_white", "ff8a65", &fx.tints[1]);   // (a deep blue and a warm pink, as it comes)
    if ((fx.tritone = (float)num("tritone", 0)) > 0.f) hue("tritone_shadow", "1b1f5c", &fx.tones[0]), hue("tritone_midtone", "c44569", &fx.tones[1]), hue("tritone_highlight", "ffd166", &fx.tones[2]);
    {   // (in the order its list lays them; with a file among them all are laid as the camera sees it, none in its picture)
        const std::vector<std::string> list = doc_fx_drawn(d, doc_fx_list(d, thing));   // (its expressions lay its copies, not drawn)
        int n = 0;
        for (const std::string& w : list) {
            if (doc_thor_letter(w)) continue;
            if (!std::filesystem::is_regular_file(aviutl_is(w) ? aviutl_path(w) : fx_source(w))) ok = false, why = "there is no such file: " + w;   // (as a picture's own file: doc_match; one put on again, its file's: fx_source)
            else if (isf_file(w).empty()) ok = false, why = "the ISF effect could not be made WGSL: " + w;   // (made once and kept, as the stage reads it: isf.cpp)
        }
        if (!doc_fx_files(list))
            for (const std::string& w : list) if (const char k = doc_thor_letter(w); k && n < 5) fx.order[n++] = k;
        fx.order[n] = 0;
        if (!n && !camera) fx.blur = 0.f, fx.shadow.w = 0.f, fx.tint = 0.f, fx.tritone = 0.f;   // (camera: as a step of its stack lays them, screen.h thing_thor)
    }
    fx.reach = (float)(std::max(0.0, num("offset", 0)) + std::fabs(num("zigzag", 0)) + 0.5 * std::max(0.0, num("bloat", 0)) + std::fabs(num("warp", 0)));
    return ok;
}

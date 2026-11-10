#include "document/evaluate/fx_list.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>

#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include "community/aviutl/aviutl.h"
#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "document/cards.h"
#include "document/evaluate/evaluate.h"
#include "document/scripts/expressions.h"
#include "document/edit/keys_put.h"
#include "document/scripts/scripts.h"
#include "document/evaluate/value_at.h"
#include "stage/effects/thorvg_effect_names.h"

using namespace filament;
using namespace filament::math;

std::vector<std::string> doc_fx_list(Doc& d, int layer, bool off) {
    std::vector<std::string> said, all;
    const std::string hidden = off ? std::string() : ";" + doc_word(d, layer, "fx_off") + ";";
    const auto seen = [&](const std::string& w) { return hidden.size() <= 2 || hidden.find(";" + doc_fx_title(w) + ";") == std::string::npos; };
    // Glow is not a step of the stack. It is Filament's bloom; see doc_evaluate.
    for (const std::string& w : script_files(doc_word(d, layer, "fx"))) if (w != "none" && w != "glow") said.push_back(w);
    for (const char* n : doc_thor_names) if (std::find(said.begin(), said.end(), n) == said.end() && doc_on(d, layer, n) && seen(n)) all.push_back(n);
    for (const std::string& w : said) if ((!doc_thor_letter(w) || doc_on(d, layer, w.c_str())) && seen(w)) all.push_back(w);
    // Add the effect being dragged onto the layer, as it is drawn; see doc_carry_effect.
    if (!off && d.held.layer == layer)
        if (const auto e = d.held.said.find(" effect"); e != d.held.said.end() && std::find(all.begin(), all.end(), e->second) == all.end()) all.push_back(e->second);
    return all;
}
bool doc_fx_files(const std::vector<std::string>& list) {
    // These file types are not effect files. A splat effect belongs to the point cloud's own look.
    // The motion of AbsentMotion moves the layer; see
    // engine/community/absent_motion/absent_motion.h.
    // Filament's own settings belong to the stage.
    return std::any_of(list.begin(), list.end(), [](const std::string& w) { const std::string ext = std::filesystem::path(w).extension().string(); return !doc_thor_letter(w) && ext != ".mjs" && ext != ".am" && ext != ".json"; });
}
std::vector<std::string> doc_fx_steps(Doc& d, int layer) {
    // Expressions are not drawn; see expressions.h.
    std::vector<std::string> steps = doc_fx_drawn(d, doc_fx_list(d, layer));
    for (std::string& w : steps)
        if (std::filesystem::path(w).extension() == ".am")
            if (const DocScript* sc = doc_script_of(d, w); sc && (sc->absent == "motionblur" || sc->absent == "shutterblur")) w = (std::filesystem::path(w).parent_path() / "am_directionalblur.wgsl").string();
    return steps;
}
std::string doc_fx_join(const std::vector<std::string>& list) {
    std::string all;
    for (const std::string& w : list) all += (all.empty() ? "" : " ") + w;
    return all;
}
double doc_most(Doc& d, int layer, const char* name, double otherwise) {
    double most = doc_number(d, layer, name, 0, otherwise);
    if (doc_keys(d, layer, name, -1.0)) doc_rows(d, sqlite3_mprintf("select max(value) from keyframe where layer = %d and name = %Q", layer, name), [&](sqlite3_stmt* row) { most = sqlite3_column_double(row, 0); });
    return most;
}
bool doc_fx(Doc& d, int layer, double at, bool most, double units, Canvas2DFx& fx, std::string& why, bool camera) {
    const auto num = [&](const char* name, double otherwise) { return most ? doc_most(d, layer, name, otherwise) : doc_number(d, layer, name, at, otherwise); };
    bool ok = true;
    // Reads a color property written as six hex digits into *to. When it is not set, `otherwise`
    // is used.
    const auto hue = [&](const char* name, const char* otherwise, float3* to) {
        std::string said = doc_word(d, layer, name);
        if (said.empty()) said = otherwise;
        const long rgb = said.size() == 6 && said.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos ? std::strtol(said.c_str(), nullptr, 16) : -1;
        if (rgb < 0) return ok = false, why = std::string("a ") + name + " is six digits, as ff3366", void();
        *to = float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255), (float)(rgb & 255)} / 255.f;
    };
    fx.blur = (float)(num("blur", 0) / units);
    // doc_fx_room is a power of two, so that a change within it does not rebuild the effect.
    if (most) fx.room = (float)(doc_fx_room(d, layer) / units);
    const std::string way = doc_word(d, layer, "blur_direction");
    fx.blurWay = way == "horizontal" ? 1 : way == "vertical" ? 2 : 0;
    // The defaults are those of the After Effects drop shadow: half opacity, 135 degrees, 10
    // points away and 10 soft.
    if (!doc_word(d, layer, "shadow").empty()) {
        float3 dark{0.f};
        hue("shadow", "000000", &dark);
        fx.shadow = float4{dark, (float)num("shadow_opacity", 0.5)};
        fx.fall = (float)(num("shadow_distance", 10) / units), fx.way = (float)num("shadow_angle", 135), fx.soft = (float)(num("shadow_blur", 10) / units);
    }
    // The default tint colors are a deep blue and a warm pink.
    if ((fx.tint = (float)num("tint", 0)) > 0.f) hue("tint_black", "1b1f5c", &fx.tints[0]), hue("tint_white", "ff8a65", &fx.tints[1]);
    if ((fx.tritone = (float)num("tritone", 0)) > 0.f) hue("tritone_shadow", "1b1f5c", &fx.tones[0]), hue("tritone_midtone", "c44569", &fx.tones[1]), hue("tritone_highlight", "ffd166", &fx.tones[2]);
    {
        // fx.order lists the built-in effects in the order of the layer's list. When a file
        // effect is among them, all effects are laid as the camera sees it and none in the
        // layer's canvas.
        // Expressions lay copies and are not drawn.
        const std::vector<std::string> list = doc_fx_drawn(d, doc_fx_list(d, layer));
        int n = 0;
        for (const std::string& w : list) {
            if (doc_thor_letter(w)) continue;
            // The file is resolved as a canvas layer's own file is, see doc_match. An effect put
            // on again uses its own file, see fx_source.
            if (!std::filesystem::is_regular_file(aviutl_is(w) ? aviutl_path(w) : fx_source(w))) ok = false, why = "there is no such file: " + w;
            // The ISF effect is converted to WGSL once and cached; see isf.cpp.
            else if (isf_file(w).empty()) ok = false, why = "the ISF effect could not be made WGSL: " + w;
        }
        if (!doc_fx_files(list))
            for (const std::string& w : list) if (const char k = doc_thor_letter(w); k && n < 5) fx.order[n++] = k;
        fx.order[n] = 0;
        // Effects missing from the list are switched off, except for a camera; see above.
        if (!n && !camera) fx.blur = 0.f, fx.shadow.w = 0.f, fx.tint = 0.f, fx.tritone = 0.f;
    }
    fx.reach = (float)(std::max(0.0, num("offset", 0)) + std::fabs(num("zigzag", 0)) + 0.5 * std::max(0.0, num("bloat", 0)) + std::fabs(num("warp", 0)));
    return ok;
}

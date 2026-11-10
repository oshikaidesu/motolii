#include "document/moment_fx.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <functional>
#include <mutex>
#include <regex>
#include <string>

#include <filament/Camera.h>
#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderTarget.h>
#include <filament/RenderableManager.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <filament/Viewport.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <utils/Entity.h>

#include "community/quickjs/script.h"
#include "community/three/solid_three.h"
#include "document/arrange.h"
#include "document/fx_list.h"
#include "document/marks.h"
#include "document/material.h"
#include "document/place.h"
#include "document/relations.h"
#include "document/scripts.h"
#include "document/shown.h"
#include "document/value_at.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/thorvg_effect_names.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace {

// Prepares a solid layer before the frame is rendered. Draws the layer square to its own face, runs
// its effects, and lays the result on the solid's faces where the solid lies.
void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e) {
    Stage& s = *d.stage;
    math::mat4 place;
    float2 half{0.5f};
    {
        // The render callback calls this while the frame is drawn, so lock the document first.
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        place = doc_place(d, layer, d.stage->now), doc_half(d, layer, &half);
    }
    thing_fx_face(s, e, place, half);
    thing_fx_textures(s, e.st, e.view);
    // Shrink the layer's own sheet to nothing so that it is not shown.
    e.look->setParameter("place", mat4f::scaling(float3{0.f}));
    if (!e.solid || !e.solidLook) return;
    move(s, e.solid, [&](int, const mat4f&) { return mat4f(place); });
    const auto wrap = e.solidRepeat ? TextureSampler::WrapMode::REPEAT : TextureSampler::WrapMode::CLAMP_TO_EDGE;
    e.solidLook->setParameter("image", thing_fx_seen(e.st), TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR, wrap));
}
// While the stage is drawn, puts the layer's effect image on its faces (on is true). When on is
// false, puts back the faces' original materials. Does nothing if the layer is not shown or is
// already in the requested state.
void doc_layer_shell(Doc& d, int layer, ThingFx& e, bool on) {
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
// Computes how far the stage reaches from a standing layer along each side of the layer's face, and
// writes four values to sides: toward -x, +x, -y and +y of the layer's own axes, in layer units.
// The stage's corners are projected back onto the layer's plane. seen is the length in stage points
// of one layer unit where the layer lies. Each value is rounded up to a multiple of 256 stage
// points, so the layer's image is made again only after the stage has moved that far. A face seen
// edge on reaches no further than three times the stage's longer side.
void doc_fx_sides(Doc& d, const math::mat4& place, double seen, double* sides) {
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
// Prepares a standing layer before the frame is rendered. Reads its placement and scale under the
// document lock, then sets up its effect image.
void doc_layer_stand(Doc& d, int layer, ThingFx& e) {
    math::mat4 place;
    float2 half{0.5f};
    double seen = 0.0;
    {
        // The render callback calls this while the frame is drawn, so lock the document first.
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        place = doc_shown_at(d, layer, d.stage->now), doc_half(d, layer, &half);
        const math::double2 a = doc_seen(d, place[3].xyz), b = doc_seen(d, place[3].xyz + normalize(d.facing[0].xyz));
        // Length in stage points of one layer unit where the layer lies, across the camera's line
        // of sight.
        seen = length(b - a);
        doc_fx_sides(d, place, seen, e.sides);
    }
    thing_fx_stand(*d.stage, e, place, half, seen);
}
// Writes where the layer lies on its effect image to frame, in the form doc_frame uses for the
// stage. A standing layer is in the middle of the image and upright. Returns false if the layer has
// no frame.
bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame) {
    if (!e.world) return doc_frame(d, layer, d.stage->now, frame);
    std::copy(e.own, e.own + 4, frame), frame[4] = 0;
    return true;
}
// Runs while the frame is rendered. Draws the effects of a solid layer. If the solid's file reads
// the image, also updates the solid from it, using the precision parameter (default 160).
void doc_layer_solid(Doc& d, int layer, ThingFx& e, const ScreenNumbers& numbers, const std::function<Canvas2DFx()>& thorFx) {
    Stage& s = *d.stage;
    thing_effects_draw(s, e.st, e.view, numbers, thorFx);
    if (solid_reads(e.solidFile)) thing_fx_cover(s, e, (int)(e.parameters.count("precision") ? e.parameters["precision"] : 160)), thing_fx_solid(s, e, true);
}
// Answers an AviUtl2 script's questions about the other layers (see
// engine/community/aviutl/aviutl_fx.h). The script's layers are the document's layers in stacking
// order, with the furthest back as layer 1. AviUtl2 draws layer 1 first and the higher layers over
// it (see doc_laid). box is the layer's box on the stage, and usual is the value to return when the
// layer has no number. The supported names are:
// - aviutl.layer: this layer's own number.
// - aviutl.layer_max: the number of layers.
// - aviutl.layerN[.name][@seconds]: the value of layer N, taken the given number of seconds from
//   its start, or now if there is no @seconds. This follows obj.getvalue("layer1.x", time) in
//   AviUtl2's script API. x and y are pixels of the script's frame measured from its middle, as
//   obj.x is. rz is the rotation, alpha is the opacity, and time is the time from the layer's
//   start.
// - aviutl.groupN: the layer of the Nth group this layer is in, where 0 is the nearest. This
//   follows obj.getoption("group_info").
// Returns NaN, which the script sees as nil, if the layer does not exist or is not shown.
double doc_aviutl_asked(Doc& d, int layer, const double* box, const std::string& name, double usual) {
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

// Sets how a layer reads what is under it: the blend mode way, whether it fills with what is behind
// it (behind), and the image of what lies under it (picture). It is set on every material of the
// layer that has a blendWay parameter.
void doc_reading(Stage& s, Doc::Shown& t, float way, float behind, Texture* picture) {
    const Camera& eye = s.view->getCamera();
    const mat4f seen = mat4f(eye.getProjectionMatrix() * eye.getViewMatrix());
    doc_parts(s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
            if (MaterialInstance* look = faces.getMaterialInstanceAt(one, part); look->getMaterial()->hasParameter("blendWay"))
                look->setParameter("blendWay", way), look->setParameter("behind", behind), look->setParameter("behindEye", seen), look->setParameter("backdrop", picture, TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST));
    });
}
// The same as doc_reading for a layer with effects. What such a layer lays on the stage is its
// sheet, so its blend mode is applied after its effects, as in After Effects, where a layer's
// blending mode comes after its effects.
void doc_sheet_reads(Doc& d, int layer, float way, Texture* picture) {
    const auto own = d.layerFx.find(layer);
    if (own == d.layerFx.end() || !own->second.look || !own->second.look->getMaterial()->hasParameter("blendWay")) return;
    own->second.look->setParameter("blendWay", way);
    own->second.look->setParameter("backdrop", picture, TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST));
}

}  // namespace

bool doc_holds_fx(Doc& d, int layer) {
    if (doc_word(d, layer, "shape") != "null") return false;
    const std::vector<std::string> steps = doc_fx_steps(d, layer);
    return doc_fx_files(steps) || std::any_of(steps.begin(), steps.end(), [](const std::string& w) { return doc_thor_letter(w) != 0; });
}
bool doc_own_fx(Doc& d, int layer) { return doc_fx_files(doc_fx_steps(d, layer)) || doc_holds_fx(d, layer); }
bool doc_layer_stands(Doc& d, int layer, ThingFx& e) {
    thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
    if (e.st.readsBehind || e.st.wide || !e.st.aviutl.empty() || doc_holds_fx(d, layer)) return false;
    for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) return false;
    const auto shown = d.shown.find(layer);
    float2 half{0.f};
    float deep = 0.f;
    return shown != d.shown.end() && !shown->second.solid && doc_members(d, layer) == 1 && doc_half(d, layer, &half, &deep) && deep == 0.f;
}
bool doc_layer_shows(Doc& d, int layer, ThingFx& e) {
    thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
    for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) return false;
    const auto shown = d.shown.find(layer);
    float2 half{0.f};
    float deep = 0.f;
    return shown != d.shown.end() && shown->second.space != 2 && !e.st.readsBehind && !e.st.wide && e.st.aviutl.empty() && (shown->second.solid || (doc_half(d, layer, &half, &deep) && deep > 0.f));
}

void doc_layers_fx(Doc& d) {
    Stage& s = *d.stage;
    s.before.clear(), s.aim.clear(), s.after.clear(), d.beforeOf.clear();
    // Pairs of negative depth and layer. Sorting them puts the deepest layers first, so a layer's
    // image is made before that of the group it lies in.
    std::vector<std::pair<int, int>> order;
    for (const auto& [layer, e] : d.layerFx) {
        int deep = 0;
        for (int up = (int)doc_number(d, layer, "parent", 0, 0); up > 0 && deep < 64; up = (int)doc_number(d, up, "parent", 0, 0)) ++deep;
        order.emplace_back(-deep, layer);
    }
    std::stable_sort(order.begin(), order.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    // Each layer is drawn alone into an image and its effects run on that image, before the stage's
    // own view. See engine/stage/effects/layer_fx.h.
    for (const auto& [deep, layer] : order) {
        ThingFx& e = d.layerFx.at(layer);
        thing_effects(s, e.st, doc_fx_join(doc_fx_steps(d, layer)));
        e.solidFile.clear();
        // If the fx names a solid's shape, the layer's image is laid on that solid. If several are
        // named, the last one is used.
        for (const std::string& w : doc_fx_list(d, layer)) if (solid_is(w)) e.solidFile = w;
        // If a solid is named, read its parameters as the document holds them now, by their own
        // names, and make the solid with them before the frame. If the layer no longer names a
        // solid, remove the old solid so that the layer's own sheet shows again.
        if (const DocScript* sc = e.solidFile.empty() ? nullptr : doc_script_of(d, e.solidFile)) {
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
        } else if (e.solid) take_off(s, e.solid), delete e.solid, e.solid = nullptr, e.solidSaid.clear();
        e.st.sounds = [&d, layer = layer](const std::string& file, const std::string& name, bool fft, int wide) { return doc_sound_now(d, layer, file, name, fft, wide); };
        // Answers an effect's questions about the layer by parameter name. The render callback
        // calls this while the image is drawn, so it locks the document.
        const ScreenNumbers numbers = [&d, layer = layer, &e = e](const std::string& file, const std::string& name, double usual) {
            std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
            // clip_time is the number of seconds into the layer's clip and clip_length is how long
            // the clip lasts. They are the ISF effect parameters of the same names (see
            // engine/community/isf/isf.cpp). A clip with no duration lasts until the end of the
            // project.
            if (name == "clip_time" || name == "clip_length") {
                const double start = doc_number(d, layer, "start", 0, 0), lasts = doc_number(d, layer, "duration", 0, -1);
                return name == "clip_time" ? d.stage->now - start : lasts > 0 ? lasts : std::max(0.0, doc_seconds(d) - start);
            }
            // The box of the layer's image on the stage as shares of the stage: left, top, width
            // and height, chosen by the last letter of the name. Effects use it to read what is
            // behind the layer (see shelves/effects/sources/from_absent.py).
            if (name.rfind("backdropBox_", 0) == 0) {
                const Stage& s = *d.stage;
                const size_t i = std::string("xyzw").find(name.back());
                return i == 0 ? e.box[0] / s.w : i == 1 ? e.box[1] / s.h : i == 2 ? (e.box[2] - e.box[0]) / s.w : (e.box[3] - e.box[1]) / s.h;
            }
            // The layer's own rectangle on its image, in the image's pixels: where its corner is
            // and how large it is, chosen by the last letter of the name. This is AbsentMotion's
            // layer rectangle (see shelves/effects/sources/from_absent.py).
            if (name.rfind("layerRect_", 0) == 0) {
                double frame[8];
                if (!doc_fx_frame(d, layer, e, frame)) return 0.0;
                const Stage& s = *d.stage;
                const double ppp = (double)s.view->getViewport().width / std::max(1, s.w);
                const size_t i = std::string("xyzw").find(name.back());
                return ppp * (i == 0 ? frame[0] - frame[2] / 2 - e.box[0] : i == 1 ? frame[1] - frame[3] / 2 - e.box[1] : i == 2 ? frame[2] : frame[3]);
            }
            // An AviUtl2 script asking about the other layers.
            if (name.rfind("aviutl.", 0) == 0) return doc_aviutl_asked(d, layer, e.box, name, usual);
            // Where the layer is on its image now, how it is turned and how large it is, so that an
            // effect's pattern can stay stuck to the layer. The image is the box where the layer is
            // seen, so positions are relative to that box.
            if (name == "origin_x" || name == "origin_y" || name == "turn" || name == "extent") {
                double frame[8];
                if (!doc_fx_frame(d, layer, e, frame)) return usual;
                return name == "origin_x" ? frame[0] - e.box[0] : name == "origin_y" ? frame[1] - e.box[1] : name == "turn" ? frame[4] : std::max(frame[2], frame[3]);
            }
            if ((name == "blurLength" || name == "angle") && file.ends_with("am_directionalblur.wgsl") && doc_word(d, layer, "fx").find("am_directionalblur.wgsl") == std::string::npos) {
                // The step of the layer's Motion Blur: as far, and in the same direction, as the
                // layer's middle moves while its shutter is open, in pixels of its image. This is
                // like AbsentMotion's quick smear. It applies only when the effect comes from the
                // Motion Blur setting and is not named in the layer's fx.
                double open = 0.0, was[8], is[8];
                bool moves = false;
                const double now = d.stage->now;
                if (!doc_shutter(d, layer, now, &open, &moves) || !moves || !doc_frame(d, layer, now - 0.5 * open, was) || !doc_frame(d, layer, now + 0.5 * open, is)) return 0.0;
                const double ppp = (double)d.stage->view->getViewport().width / std::max(1, d.stage->w);
                const math::double3 way = (doc_shown_at(d, layer, now + 0.5 * open)[3] - doc_shown_at(d, layer, now - 0.5 * open)[3]).xyz;
                // A standing layer moves along its own image, so project the movement onto the
                // image's axes.
                const double dx = e.world ? dot(way, e.square[0].xyz) * e.own[4] : is[0] - was[0], dy = e.world ? -dot(way, e.square[1].xyz) * e.own[4] : is[1] - was[1];
                // The blur effect reads behind the layer along the angle it is given. The angle
                // therefore points opposite to the direction of travel, so that the blur trails
                // behind the layer.
                return name == "blurLength" ? ppp * std::hypot(dx, dy) : std::atan2(-dy, -dx) * 180.0 / M_PI;
            }
            return doc_number(d, layer, doc_screen_parameter(file, name).c_str(), d.stage->now, usual);
        };
        // ThorVG's own effects among the layer's steps, as they are now. Lengths are in points of
        // the stage.
        const auto thorFx = [&d, layer = layer, &e = e] {
            std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
            Canvas2DFx fx;
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
        // Before the frame: works out where the layer is seen, what its images are, and what its
        // sheet shows.
        s.aim.push_back([&s, &d, layer = layer, &e = e] {
            double box[4] = {0, 0, (double)s.w, (double)s.h}, seen[4];
            {
                std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
                // A group's image is the whole stage, as an Alight Motion group's scene is as large
                // as the stage.
                const bool found = !doc_holds_fx(d, layer) && doc_seen_box(d, layer, d.stage->now, seen);
                // Where the layer is seen, limited to the part on the stage, is its image, as in
                // After Effects. Add room around it for what its effects draw outside it: a margin
                // of 128 pixels.
                if (found) {
                    const double m = 128.0 * s.w / std::max(1u, s.view->getViewport().width);
                    box[0] = std::max(0.0, seen[0] - m), box[1] = std::max(0.0, seen[1] - m), box[2] = std::min((double)s.w, seen[2] + m), box[3] = std::min((double)s.h, seen[3] + m);
                }
                // If none of the layer is on the stage, use the whole stage.
                if (box[2] - box[0] < 1 || box[3] - box[1] < 1) box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
                e.st.frame[0] = 0, e.st.frame[1] = 0, e.st.frame[2] = 1, e.st.frame[3] = 1;
                const bool shown = found && !e.shell && !e.st.wide;
                // Normally the frame is the box where the layer is seen, as shares of the stage,
                // and the image covers the whole stage. AbsentMotion's effects are cut by the scene
                // in the same way (engine/third_party/AbsentMotion/app/src/main/cpp/effects.cpp,
                // EffectRuntime::draw).
                if (!e.shell && !e.st.wide) {
                    e.st.frame[0] = box[0] / s.w, e.st.frame[1] = box[1] / s.h, e.st.frame[2] = (box[2] - box[0]) / s.w, e.st.frame[3] = (box[3] - box[1]) / s.h;
                    box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
                }
                std::copy(e.st.frame, e.st.frame + 4, e.st.own);
                if (shown) e.st.own[0] = seen[0] / s.w, e.st.own[1] = seen[1] / s.h, e.st.own[2] = (seen[2] - seen[0]) / s.w, e.st.own[3] = (seen[3] - seen[1]) / s.h;
                // An AviUtl2 script that draws the layer uses the whole stage as its frame, as an
                // AviUtl2 object is drawn on the screen. The box where the layer is seen is passed
                // to the effect in thingSeen.
                if (e.st.wide) {
                    std::copy(found ? seen : box, (found ? seen : box) + 4, e.st.thingSeen);
                    box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
                }
            }
            if (!e.solidFile.empty()) return doc_layer_solid_aim(d, layer, e);
            // The layer's sheet is shown on screen only, not in the image of what is behind it that
            // its effect reads. The glass material leaves itself out in the same way (see
            // engine/stage/render/render_layers.h).
            if (e.st.readsBehind) {
                s.backdropRead = true;
                for (const Stage::Renderable& made : s.renderables) if (made.of == e.sheet) s.engine->getRenderableManager().setLayerMask(s.engine->getRenderableManager().getInstance(made.thing), 0xFF, 0x02);
            }
            // The background color as hex RRGGBB, or -1 if there is none. An effect that reads the
            // frame sees it where nothing is drawn.
            e.st.ground = d.backdropIs.size() == 6 ? (int)std::strtol(d.backdropIs.c_str(), nullptr, 16) : -1;
            if (e.world) doc_layer_stand(d, layer, e);
            else thing_fx_aim(s, e, box);
            thing_fx_textures(s, e.st, e.view);
            if (e.look) e.look->setParameter("image", thing_fx_seen(e.st), e.shell ? TextureSampler(TextureSampler::MinFilter::NEAREST, TextureSampler::MagFilter::NEAREST) : TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
            // The glow of the effect result uses the stage's bloom, as a layer without effects does
            // (see doc_evaluate).
            if (e.look) {
                std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
                e.look->setParameter("glowing", (float)doc_number(d, layer, "emissive", d.stage->now, 0) + (doc_word(d, layer, "glow").empty() ? 0.f : 0.35f * (float)doc_number(d, layer, "glow_opacity", d.stage->now, 1)));
            }
        });
        d.beforeOf.push_back(layer);
        // In the frame: draws the layer alone and runs its effects.
        s.before.push_back([&d, layer = layer, &e = e, numbers, thorFx] {
            if (!e.solidFile.empty()) return doc_layer_solid(d, layer, e, numbers, thorFx);
            thing_effects_draw(*d.stage, e.st, e.view, numbers, thorFx);
            if (e.shell) doc_layer_shell(d, layer, e, true);
        });
        if (e.shell) s.after.push_back([&d, layer = layer, &e = e] { doc_layer_shell(d, layer, e, false); });
    }
}
void doc_layers_read(Doc& d, const std::vector<std::pair<int, Doc::Shown*>>& laid) {
    Stage& s = *d.stage;
    // A flat layer of glass sees what is behind it through itself (see engine/materials/flat.mat).
    const auto reads = [&](int layer) { return doc_blend_way(doc_word(d, layer, "blend")) || doc_word(d, layer, "fill") == "behind" || doc_sheet_material(d, layer) == "glass"; };
    // Release the backdrop of layers that no longer read or that are gone.
    for (auto r = d.reads.begin(); r != d.reads.end();) {
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
            for (const Stage::Renderable& made : s.renderables) if (made.of == own->second.sheet) parts.push_back(made.thing);
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

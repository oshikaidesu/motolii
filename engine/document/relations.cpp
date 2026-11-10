#include "document/relations.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <initializer_list>
#include <iterator>
#include <memory>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <math/mat4.h>
#include <math/quat.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <thorvg.h>

#include "community/absent_motion/absent_motion.h"
#include "community/quickjs/script.h"
#include "document/card_table.h"
#include "document/expressions.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/place.h"
#include "document/scripts.h"
#include "document/shown.h"
#include "document/value_at.h"
#include "document/world.h"
#include "physics/physics.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

double doc_behaviour_at(Doc& d, int by, int copy, int n, double t) {
    // Limits how deeply behaviours can drive each other, so that a cycle of them terminates.
    static int depth = 0;
    struct Deeper { Deeper() { ++depth; } ~Deeper() { --depth; } } deeper;
    // Returns the parameter `name` of this behaviour for this copy. When another behaviour drives
    // the parameter, that behaviour's value for this copy is used. Otherwise it is the stored
    // number, or `otherwise` when there is none.
    const auto parameter = [&](const char* name, double otherwise) {
        if (depth < 4) if (const int other = doc_driven_by(d, by, name); other && other != by) return doc_behaviour_at(d, other, copy, n, t);
        return doc_number(d, by, name, t, otherwise);
    };
    const std::string type = doc_word(d, by, "file");
    const double lo = parameter("minimum", 0), hi = parameter("maximum", 1), offset = parameter("offset", 0);
    const double frequency = parameter("frequency", 1), apart = parameter("stagger", 0) / 360.0;
    const uint32_t seed = (uint32_t)doc_number(d, by, "seed", 0, 0);
    // Returns a deterministic number from 0 to 1 for the seed and the integer `k`.
    const auto hash = [&](int64_t k) {
        uint32_t h = seed * 0x9E3779B9u ^ (uint32_t)k * 0x85EBCA6Bu ^ 0xC2B2AE35u;
        h ^= h >> 16, h *= 0x7FEB352Du, h ^= h >> 15, h *= 0x846CA68Bu, h ^= h >> 16;
        return (double)h / 4294967295.0;
    };
    double u = 0.0;
    // Stagger: the copy's position in the order, from 0 for the first copy to 1 for the last,
    // shifted by the offset.
    if (type == "stagger") u = std::clamp((n > 1 ? (double)copy / (n - 1) : 0.0) + offset, 0.0, 1.0);
    // Oscillator: a sine wave over time, mapped to the range 0 to 1. `apart` is the phase shift per
    // copy in turns.
    else if (type == "oscillator") u = 0.5 + 0.5 * std::sin((double)TAU * (frequency * t + offset + apart * copy));
    // Noise: smooth interpolation between hashed values at whole positions along time. Each copy
    // starts further along.
    else if (type == "noise") {
        const double x = frequency * t + offset + apart * copy * 4.0, f = std::floor(x), e = (x - f) * (x - f) * (3.0 - 2.0 * (x - f));
        u = hash((int64_t)f) * (1.0 - e) + hash((int64_t)f + 1) * e;
    }
    // Random: a fixed value for each copy, determined by the seed.
    else if (type == "random") u = hash(copy + 1);
    // Round to a multiple of `step` when it is positive.
    const double step = parameter("step", 0), v = lo + (hi - lo) * u;
    return step > 0.0 ? std::round(v / step) * step : v;
}

bool doc_connects(Doc& d, int layer) {
    if (const auto known = d.connects.find(layer); known != d.connects.end()) return known->second;
    bool any = false;
    doc_rows(d, sqlite3_mprintf("select 1 from keyframe where layer = %d and name glob '*_by' and value <> 0 limit 1", layer), [&](sqlite3_stmt*) { any = true; });
    return d.connects.emplace(layer, any).first->second;
}

int doc_driven_by(Doc& d, int layer, const char* name) {
    if (!doc_connects(d, layer)) return 0;
    const auto key = std::make_pair(layer, std::string(name));
    if (const auto known = d.drivers.find(key); known != d.drivers.end()) return known->second;
    int by = (int)doc_number(d, layer, (std::string(name) + "_by").c_str(), 0, 0);
    if (by && doc_word(d, by, "kind") != "behaviour") by = 0;
    return d.drivers.emplace(key, by).first->second;
}

double doc_falloff_at(Doc& d, int by, math::double3 at, double t) {
    const int f = (int)doc_number(d, by, "region", 0, 0);
    if (!f) return 1.0;
    const auto found = d.shown.find(f);
    const Canvas2D* b = found == d.shown.end() ? nullptr : found->second.drawn;
    if (!b || !b->cut || !b->outline) return 1.0;
    const math::mat4 place = doc_place(d, f, t, 0, 0, false);
    // The point in the falloff layer's own space.
    const math::double4 on = inverse(place) * math::double4{at, 1.0};
    const tvg::PathCommand* cmds; const tvg::Point* pts; uint32_t cmdsCnt = 0, ptsCnt = 0;
    b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
    float far = 0.f;
    // Convert to the units of the outline, which is plainHigh high with its origin at the top left.
    const bool inside = sk_inside(cmds, cmdsCnt, pts, (float)(on.x / b->sheetHigh * b->plainHigh + 0.5 * b->cutW), (float)(0.5 * b->plainHigh - on.y / b->sheetHigh * b->plainHigh), &far);
    // The softness is measured on the stage, so it does not grow with the shape. `away` is the
    // distance to the outline in stage units.
    const double soft = doc_number(d, by, "falloff_soft", t, 0), away = far / b->plainHigh * b->sheetHigh * std::sqrt(length(place[0].xyz) * length(place[1].xyz));
    const double w = inside ? 1.0 : soft > 0.0 ? std::max(0.0, 1.0 - away / soft) : 0.0;
    return doc_number(d, by, "falloff_invert", 0, 0) > 0.5 ? 1.0 - w : w;
}

double doc_given(Doc& d, int by, int copy, int n, double t, double own, const math::double3* at) {
    const double v = doc_behaviour_at(d, by, copy, n, t);
    if (!at) return v;
    const double w = doc_falloff_at(d, by, *at, t);
    return own + (v - own) * w;
}

void doc_copy_looks_off(Doc& d, const Mesh* m, MaterialInstance* main) {
    Stage& s = *d.stage;
    auto& faces = s.engine->getRenderableManager();
    for (const Stage::Renderable& made : s.renderables) {
        if (made.of != m) continue;
        const auto found = d.copyLooks.find(made.thing.getId());
        if (found == d.copyLooks.end()) continue;
        if (main) faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, main);
        s.engine->destroy(found->second);
        d.copyLooks.erase(found);
        // The copy's own edge material goes back to the layer's edge material in the same way.
        if (const auto edge = d.copyEdges.find(made.thing.getId()); edge != d.copyEdges.end()) {
            const Doc::Shown* t = nullptr;
            for (const auto& [id, one] : d.shown) if (one.drawn && one.drawn->sheet == m) t = &one;
            if (t && t->drawn->edgeLook) faces.setMaterialInstanceAt(faces.getInstance(made.thing), 1, t->drawn->edgeLook);
            s.engine->destroy(edge->second);
            d.copyEdges.erase(edge);
        }
    }
}

const Doc::Relation& doc_relation_of(Doc& d, int by) {
    if (const auto known = d.relationsOf.find(by); known != d.relationsOf.end()) return known->second;
    // Limits how deeply relations can build on relations, so that a cycle of them terminates.
    static int depth = 0;
    struct Deeper { Deeper() { ++depth; } ~Deeper() { --depth; } } deeper;
    Doc::Relation r;
    std::vector<int> connected;
    doc_rows(d, sqlite3_mprintf("select distinct layer from keyframe where name glob '*_by' and value = %d order by layer", by), [&](sqlite3_stmt* q) { connected.push_back(sqlite3_column_int(q, 0)); });
    // Splits the text value `name` of the relation into words.
    const auto words = [&](const char* name) { std::vector<std::string> all; std::istringstream said(doc_word(d, by, name)); for (std::string one; said >> one;) all.push_back(one); return all; };
    const std::vector<std::string> members = words("members"), under = words("under"), from = words("from");
    // Returns whether layer `t` is a member of this relation indirectly. Walks back through the
    // relations that the layer was in before, at most 8 steps, looking for this one.
    const auto reaches = [&](int t) {
        for (int cur = doc_driven_by(d, t, "x") ? doc_driven_by(d, t, "x") : doc_driven_by(d, t, "y"), n = 0; cur && n < 8 && depth < 6; ++n) {
            if (cur == by) return true;
            const Doc::Relation& above = doc_relation_of(d, cur);
            const auto at = std::find(above.members.begin(), above.members.end(), t);
            cur = at == above.members.end() || above.under.empty() ? 0 : above.under[(size_t)(at - above.members.begin())];
        }
        return false;
    };
    // Keep a listed member only when it is still connected or reachable. Otherwise leave a 0 slot.
    for (size_t k = 0; k < members.size(); ++k) {
        const int t = std::atoi(members[k].c_str());
        const bool in = t && std::find(r.members.begin(), r.members.end(), t) == r.members.end() && (std::find(connected.begin(), connected.end(), t) != connected.end() || reaches(t));
        r.members.push_back(in ? t : 0);
    }
    // Append the connected layers that are not listed.
    for (const int t : connected) if (std::find(r.members.begin(), r.members.end(), t) == r.members.end()) r.members.push_back(t);
    if (under.size() == members.size()) for (const std::string& u : under) r.under.push_back(std::atoi(u.c_str()));
    if (from.size() == 2 * members.size()) for (const std::string& f : from) r.from.push_back(std::atof(f.c_str()));
    // Keep `under` and `from` either empty or one entry per member, padding with 0 and NaN.
    r.under.resize(r.under.empty() ? 0 : r.members.size(), 0);
    r.from.resize(r.from.empty() ? 0 : 2 * r.members.size(), std::nan(""));
    return d.relationsOf.emplace(by, std::move(r)).first->second;
}

double doc_related(Doc& d, int by, int layer, const char* name, double t, double own) {
    // Limits recursion when a leader is itself in a relation that leads back to this one.
    static int depth = 0;
    struct Deeper { Deeper() { ++depth; } ~Deeper() { --depth; } } deeper;
    if (depth > 6) return own;
    const std::string type = doc_word(d, by, "file"), n = name;
    const Doc::Relation& rel = doc_relation_of(d, by);
    const auto found = std::find(rel.members.begin(), rel.members.end(), layer);
    if (found == rel.members.end()) return own;
    const size_t i = (size_t)(found - rel.members.begin());
    const int many = std::max(1, (int)rel.members.size()), was = rel.under.empty() ? 0 : rel.under[i];
    // The value before this relation: what the previous relation gives, or `mine`.
    const auto start = [&](const char* what, double mine) { return was ? doc_related(d, was, layer, what, t, mine) : mine; };
    // The time for this member. Each member lags the one before by "lag" seconds, as in Cavalry's
    // stagger. A follow relation uses the plain time here, because its lag is applied to the leader
    // instead.
    const double ti = type == "follow" ? t : t - doc_number(d, by, "lag", t, 0) * (double)i;
    // The strength may go below 0 and above 1 so that an easing that overshoots, such as Back or
    // Elastic, shows between two keyframes. It is held within -1 and 2.
    const double base = start(name, own), strength = std::clamp(doc_number(d, by, "strength", ti, 1), -1.0, 2.0);
    // A relation that is switched off leaves the value as it was. Its strength is kept.
    if (doc_number(d, by, "visible", 0, 1) <= 0.5) return base;
    // Where the layer appeared when it joined. Known for x and y only.
    const double came = rel.from.empty() || (n != "x" && n != "y") ? std::nan("") : rel.from[2 * i + (n == "y" ? 1 : 0)];
    // Returns the leader layer stored in the value `which`, or 0 when that is the layer itself.
    const auto leader = [&](const char* which) { const int l = (int)doc_number(d, by, which, 0, 0); return l != layer ? l : 0; };
    // A relation written as a file. When the file defines force(), the value comes from the
    // simulated world. Otherwise it comes from the file's relate() results, one number per member
    // and per name in doc_relate_names, blended by the strength.
    if (type == "relate") {
        if (d.settled) return base;
        const bool pushes = doc_pushes(d, by);
        const std::vector<double> none, &all = pushes ? none : doc_related_all(d, by, t);
        constexpr size_t many = std::size(doc_relate_names);
        for (size_t j = 0; j < many; ++j) if (n == doc_relate_names[j]) return pushes ? doc_world_value(d, layer, j, t, base) : many * i + j < all.size() ? base + (all[many * i + j] - base) * strength : base;
        return base;
    }
    // The strength scaled by the falloff at the layer's starting position. This follows Cavalry,
    // where Falloff is a multiplier on Strength. A relation written as a file applies its falloff
    // inside the file, see __relates in engine/community/p5/p5_stand.h.
    const double s = strength * (doc_number(d, by, "region", 0, 0) ? doc_falloff_at(d, by, {start("x", doc_number(d, layer, "x", t, 0)), start("y", doc_number(d, layer, "y", t, 0)), start("z", doc_number(d, layer, "z", t, 0))}, t) : 1.0);
    // The relation's own rotation is added to each member, scaled by strength and falloff.
    if ((type == "around" || type == "row" || type == "group") && (n == "rotate" || n == "rotate_x" || n == "rotate_y"))
        return base + doc_number(d, by, name, ti, 0) * s;
    // The relation's size and opacity are shares of each layer's own value, so they multiply it. An
    // opacity of 0 makes the layer disappear.
    if ((type == "around" || type == "row" || type == "group") && (n == "size" || n == "opacity"))
        return base * (1.0 + (doc_number(d, by, name, ti, 1) - 1.0) * s);
    // Group: moves x and y by the relation's own move, plus the layer's distance from the middle of
    // the group times the spread, plus a random scatter, all scaled by strength and falloff.
    if (type == "group") {
        if (n != "x" && n != "y") return base;
        const size_t axis = n == "x" ? 0 : 1;
        double middle = 0;
        int counted = 0;
        // The middle of the group is the average of where the members were when they joined.
        for (size_t k = 0; 2 * k + axis < rel.from.size(); ++k)
            if (!std::isnan(rel.from[2 * k + axis])) middle += rel.from[2 * k + axis], ++counted;
        // If that is not known, use their current places instead.
        if (!counted)
            for (const int t : rel.members) if (t) middle += doc_literal(d, t, name, ti, 0), ++counted;
        middle = counted ? middle / counted : base;
        // A fixed scatter in the range -1 to 1 for each member and axis, so the same scatter shows
        // each time. It uses the common fract-of-sine hash from GLSL.
        const double seed = std::sin((double)(i + 1) * (axis ? 78.233 : 12.9898)) * 43758.5453, scatter = (seed - std::floor(seed)) * 2 - 1;
        const double away = doc_number(d, by, name, ti, 0) + (base - middle) * (doc_number(d, by, "spread", ti, 1) - 1) + doc_number(d, by, "scatter", ti, 0) * scatter;
        return base + away * s;
    }
    // Around: members on a circle around a middle, the first at the top, each placed by its order.
    // Row: members in a line through the middle, `gap` apart.
    if (type == "around" || type == "row") {
        if (n != "x" && n != "y" && n != "z") return base;
        const int l = leader("leader");
        const double tilt = type == "around" ? doc_number(d, by, "tilt", t, 0) * TAU / 360.0 : 0.0;
        // A circle that faces the camera and has no leader leaves depth alone.
        if (n == "z" && tilt == 0.0 && !l) return base;
        // The middle of the circle or row: the centre values plus the leader's position, if there
        // is a leader.
        const double cx = doc_number(d, by, "centre_x", t, 0) + (l ? doc_literal(d, l, "x", t, 0) : 0.0), cy = doc_number(d, by, "centre_y", t, 0) + (l ? doc_literal(d, l, "y", t, 0) : 0.0);
        double place;
        // The circle is tipped back by `tilt` about the x axis. With a leader it is centred on the
        // leader in depth as well.
        if (type == "around") {
            const double turn = TAU * (doc_number(d, by, "offset", t, 0) + (double)i / many), r = doc_number(d, by, "radius", t, 0.5);
            const double cz = l ? doc_literal(d, l, "z", t, 0) : 0.0, up = r * std::cos(turn);
            if (n == "z") return base + (cz + up * std::sin(tilt) - base) * s;
            place = n == "x" ? cx + r * std::sin(turn) : cy + up * std::cos(tilt);
        } else if (n == "z") return base;
        // A row is centred on its middle, so a wider gap spreads it both ways.
        else place = n == "x" ? cx + doc_number(d, by, "gap", t, 0.2) * ((double)i - (many - 1) / 2.0) : cy;
        // When the starting position is known, add only the step from there to the new place.
        return std::isnan(came) ? base + (place - base) * s : base + (place - came) * s;
    }
    if ((type == "follow" || type == "push") && d.settled) return base;
    // Follow: the layer takes its leader's value from `lag` seconds ago, later for each member. A
    // second leader, if there is one, is mixed in by the "hand" value from 0 to 1.
    if (type == "follow") {
        const int a = leader("leader"), b = leader("leader_b");
        if (!a) return base;
        const double back = t - doc_number(d, by, "lag", t, 0) * (double)(i + 1), hand = b ? std::clamp(doc_number(d, by, "hand", t, 0), 0.0, 1.0) : 0.0;
        const double from = doc_literal(d, a, name, back, own), to = b ? doc_literal(d, b, name, back, own) : from, lead = from + (to - from) * hand;
        return std::isnan(came) ? base + lead * s : base + (lead - came) * s;
    }
    // Push: moves the layer out of its leader's way. Within `radius` of the leader the layer is
    // pushed out to between 0.6 and 1 times the radius, keeping the order of distance.
    if (type == "push") {
        const int l = leader("leader");
        if (!l || (n != "x" && n != "y")) return base;
        // The layer's x and y: this axis is `base`, and the other is read from its keyframes.
        const double bx = n == "x" ? base : start("x", doc_keys_at(d, doc_keys_of(d, layer, "x"), t, 0)), by_ = n == "y" ? base : start("y", doc_keys_at(d, doc_keys_of(d, layer, "y"), t, 0));
        const double lx = doc_literal(d, l, "x", t, 0), ly = doc_literal(d, l, "y", t, 0), r = doc_number(d, by, "radius", t, 0.5);
        double dx = bx - lx, dy = by_ - ly, far = std::hypot(dx, dy);
        if (far >= r || r <= 0.0) return base;
        // A layer exactly on its leader is pushed out in a direction chosen by its index.
        if (far < 1e-6) dx = std::sin(TAU * (double)i / many), dy = std::cos(TAU * (double)i / many), far = 1e-6;
        // Land in the outer part of the circle, ordered by distance, so that layers do not end up
        // on top of each other.
        const double out = r * (0.6 + 0.4 * far / r), v = n == "x" ? lx + dx / far * out : ly + dy / far * out;
        return base + (v - base) * s;
    }
    return base;
}

double doc_literal(Doc& d, int layer, const char* literal, double at, double otherwise) {
    // The layer is being dragged. Use its own value. If it is in a relation, the relation still
    // applies, because the drag moves the layer's own value.
    if (d.held.layer == layer) {
        const double own = doc_number(d, layer, literal, at, otherwise);
        const int by = doc_driven_by(d, layer, literal);
        return by && doc_among(doc_relations, doc_word(d, by, "file")) ? doc_related(d, by, layer, literal, at, own) : own;
    }
    // Driven by a behaviour or relation. For a behaviour, use the value for the copy being placed,
    // weighed by its falloff where the copy lies.
    if (const int by = doc_driven_by(d, layer, literal)) {
        const Doc::Keys& k = doc_keys_of(d, layer, literal);
        const double own = doc_keys_at(d, k, doc_stepped(d, layer, k, at), otherwise);
        // A relation applies by the layer's place among its layers, not by a copy's place.
        if (doc_among(doc_relations, doc_word(d, by, "file"))) return doc_related(d, by, layer, literal, at, own);
        return doc_given(d, by, d.ctxCopy, d.ctxN, at, own, d.ctxHasAt ? &d.ctxAt : nullptr);
    }
    const auto key = std::make_pair(layer, literal);
    auto kept = d.literals.find(key);
    if (kept == d.literals.end()) kept = d.literals.emplace(key, &doc_keys_of(d, layer, literal)).first;
    return doc_keys_at(d, *kept->second, doc_stepped(d, layer, *kept->second, at), otherwise);
}

const std::string& doc_literal_word(Doc& d, int layer, const char* literal) {
    const auto key = std::make_pair(layer, literal);
    if (const auto kept = d.heardWords.find(key); kept != d.heardWords.end()) return kept->second;
    return d.heardWords.emplace(key, doc_word(d, layer, literal)).first->second;
}

const std::vector<AbsentCopy>& doc_absent_copies(Doc& d, int layer, double now) {
    Doc::AbsentKept& k = d.absentKept[layer];
    const long changes = d.file ? (long)sqlite3_total_changes(d.file) : 0;
    if (k.at == now && k.changes == changes && k.seen == files_changed()) return k.copies;
    k.at = now, k.changes = changes, k.seen = files_changed();
    k.copies.clear();
    if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return k.copies;
    const double begins = doc_literal(d, layer, "start", 0, 0), lasts = doc_literal(d, layer, "duration", 0, -1);
    // `k2` converts points of the preview to pixels of the document.
    const double high = doc_number(d, 0, "high", 0, 1080), k2 = high / std::max(1, d.stage->h);
    const math::double2 at = doc_seen(d, (doc_above(d, layer, now, 0) * math::double4{doc_literal(d, layer, "x", now, 0), doc_literal(d, layer, "y", now, 0), doc_literal(d, layer, "z", now, 0), 1.0}).xyz) * k2;
    float2 half{0.5f};
    doc_half(d, layer, &half);
    // Distance from the layer's position to the farthest point of its box, computed as in CopiesOf:
    // half of the longer side times 1.415, about the square root of 2.
    const double reach = std::max(half.x, half.y) * doc_literal(d, layer, "size", now, 1) * doc_point(d, layer, now) * k2 * 1.415;
    // AbsentMotion measures time in milliseconds.
    k.copies = absent_copies(doc_absent_on(d, layer, now), layer, 1000.0 * begins, 1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now, (float)(d.stage->w * k2), (float)high, (float)at.x, (float)at.y, (float)reach);
    return k.copies;
}

std::string doc_text_shown(Doc& d, int layer, double now, bool* moves) {
    const std::string typed = doc_word(d, layer, "text");
    if (moves) *moves = false;
    if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return typed;
    const std::vector<AbsentEffect> on = doc_absent_on(d, layer, now);
    if (!absent_text_on(on)) return typed;
    if (moves) *moves = true;
    const double begins = doc_literal(d, layer, "start", 0, 0), lasts = doc_literal(d, layer, "duration", 0, -1);
    return absent_text(on, layer, 1000.0 * begins, 1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now, 60, typed);
}

bool doc_shutter(Doc& d, int layer, double now, double* open, bool* moves) {
    if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return false;
    const double begins = doc_literal(d, layer, "start", 0, 0), lasts = doc_literal(d, layer, "duration", 0, -1);
    return absent_shutter(doc_absent_on(d, layer, now), layer, 1000.0 * begins, 1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now, 60, open, moves);
}

double doc_group_opacity(Doc& d, int layer, double now) {
    double k = 1.0;
    // Stop after 64 levels so that a cycle of parents terminates.
    for (int up = (int)doc_number(d, layer, "parent", 0, 0), n = 0; up && n < 64 && k > 0.0; up = (int)doc_number(d, up, "parent", 0, 0), ++n)
        if (doc_word(d, up, "shape") == "null") k *= doc_number(d, up, "visible", 0, 1) > 0.5 ? std::clamp(doc_number(d, up, "opacity", now, 1), 0.0, 1.0) : 0.0;
    return k;
}

double doc_absent_opacity(Doc& d, int layer, double now) {
    if (doc_word(d, layer, "fx").find(".am") == std::string::npos) return 1.0;
    const double begins = doc_literal(d, layer, "start", 0, 0), lasts = doc_literal(d, layer, "duration", 0, -1);
    return absent_opacity(doc_absent_on(d, layer, now), layer, 1000.0 * begins, 1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * now);
}

int doc_members(Doc& d, int layer) {
    const auto t = d.shown.find(layer);
    if (t != d.shown.end() && t->second.drawn && !t->second.drawn->letters.empty()) return (int)t->second.drawn->letters.size();
    if (const std::vector<AbsentCopy>& copies = doc_absent_copies(d, layer, d.stage->now); !copies.empty()) return (int)copies.size();
    return std::max(1, (int)doc_literal(d, layer, "copies", 0, 1));
}

double doc_delay(Doc& d, int layer, int nth) {
    const double stagger = doc_literal(d, layer, "stagger", 0, 0);
    const int n = doc_members(d, layer);
    if (stagger <= 0.0 || n < 2) return 0.0;
    const double along = (double)nth / (double)(n - 1), centre = std::fabs(along - 0.5) * 2.0;
    const std::string& from = doc_literal_word(d, layer, "stagger_from");
    return stagger * (from == "centre" ? centre : from == "end" ? 1.0 - along : from == "edges" ? 1.0 - centre : along);
}

math::mat4 doc_above(Doc& d, int layer, double now, int deeper) {
    const int parent = (int)doc_literal(d, layer, "parent", 0, 0);
    const auto up = d.shown.find(parent), self = d.shown.find(layer);
    if (up != d.shown.end() && up->second.camera && self != d.shown.end() && self->second.space == 2) return math::mat4{};
    // Stop after 64 levels so that a document with a cycle of parents terminates.
    return parent && up != d.shown.end() && deeper < 64 ? doc_place(d, parent, now, deeper + 1) : math::mat4{};
}

double doc_letter_middle(Doc& d, int layer, int copy) {
    const auto sh = d.shown.find(layer);
    if (copy < 0 || sh == d.shown.end() || !sh->second.drawn || copy >= (int)sh->second.drawn->letters.size()) return 0.0;
    float2 half{0.5f};
    float deep = 0.f;
    doc_half(d, layer, &half, &deep);
    const float2 l = sh->second.drawn->letters[(size_t)copy];
    return ((double)(l.x + l.y) * 0.5 - 0.5) * 2.0 * half.x;
}

bool doc_physics(Doc& d, int layer, double now, PhysPose* pose, int copy) {
    // Rebuild the description of everything the world is made of: every value and keyframe of the
    // layers that have physics, and the gravity. A change in it discards the world.
    if (d.phys_stale) {
        d.phys_stale = false;
        std::string made;
        doc_rows(d, sqlite3_mprintf("select group_concat(layer || ' ' || name || ' ' || at || ' ' || quote(value) || ' ' || coalesce(easing, ''), ';') from (select * from keyframe where layer in "
                                    "(select layer from keyframe where name = 'physics' and value in ('moves', 'still')) or (layer = 0 and name = 'gravity') order by layer, name, at)"),
                 [&](sqlite3_stmt* row) { if (sqlite3_column_type(row, 0) == SQLITE_TEXT) made = (const char*)sqlite3_column_text(row, 0); });
        if (made != d.phys_made) d.phys.reset(), d.phys_of.clear(), d.phys_copy.clear(), d.phys_until.clear(), d.phys_made = made;
        d.phys_any = made.find(" physics ") != std::string::npos;
    }
    // No layer has physics, so nothing needs to be asked of the document at every place.
    if (!d.phys_any) return false;
    const std::string mine = doc_word(d, layer, "physics");
    // Only layers set to "moves" are placed by the world. Layers set to "still" are fixed
    // obstacles.
    if (mine != "moves") return false;
    if (!d.phys) {
        std::vector<PhysThing> made;
        d.phys_of.clear(), d.phys_copy.clear(), d.phys_until.clear();
        for (int t : doc_laid(d)) {
            const std::string how = doc_word(d, t, "physics");
            // Layers without physics, and layers with a parent, are not in the world.
            if ((how != "moves" && how != "still") || doc_number(d, t, "parent", 0, 0) != 0.0) continue;
            float2 half{0.5f};
            float deep = 0.f;
            if (!doc_half(d, t, &half, &deep)) continue;
            const double size = doc_number(d, t, "size", 0, 1);
            PhysThing one;
            one.still = how == "still", one.flat = deep == 0.f;
            one.ball = doc_word(d, t, "shape") == "ball";
            one.half[0] = (float)(half.x * size * std::fabs(doc_number(d, t, "scale_x", 0, 1)));
            one.half[1] = (float)(half.y * size * std::fabs(doc_number(d, t, "scale_y", 0, 1)));
            one.half[2] = one.flat ? 0.05f : (float)(deep * size * std::fabs(doc_number(d, t, "scale_z", 0, 1)));
            one.bounce = (float)doc_number(d, t, "bounce", 0, 0.3), one.friction = (float)doc_number(d, t, "friction", 0, 0.5);
            // The layer's keyframes control it until the last one of these properties.
            for (const char* name : {"x", "y", "z", "rotate", "rotate_x", "rotate_y"}) {
                doc_rows(d, sqlite3_mprintf("select max(at) from keyframe where layer = %d and name = %Q and " DOC_KEYED, t, name, t, name), [&](sqlite3_stmt* row) {
                    if (sqlite3_column_type(row, 0) != SQLITE_NULL) one.until = std::max(one.until, sqlite3_column_double(row, 0));
                });
            }
            const auto sh = d.shown.find(t);
            const std::vector<float2>* letters = sh != d.shown.end() && sh->second.drawn && !sh->second.drawn->letters.empty() ? &sh->second.drawn->letters : nullptr;
            // A split text gets one body for each letter, as wide as its ink but a little narrower,
            // so that neighbours do not start inside each other.
            const int copies = letters ? (int)letters->size() : 1;
            for (int c = 0; c < copies; ++c) {
                PhysThing each = one;
                if (letters) each.half[0] = std::max(0.01f, 0.92f * ((*letters)[(size_t)c].y - (*letters)[(size_t)c].x) * one.half[0]);
                made.push_back(each);
                d.phys_of.push_back(t), d.phys_copy.push_back(letters ? c : -1), d.phys_until.push_back(one.still ? 1e9 : one.until);
            }
        }
        // Returns the pose that the layer's keyframes give at time `at`: where its middle is, and
        // its rotation. The world calls this to place the layers that keyframes still control.
        const auto keyed = [&d](int index, double at) {
            const int t = d.phys_of[(size_t)index], copy = d.phys_copy[(size_t)index];
            d.phys_keyed = true;
            const math::double3 middle = (doc_place(d, t, at, 0, std::max(copy, 0), copy >= 0) * math::double4{doc_letter_middle(d, t, copy), 0, 0, 1}).xyz;
            d.phys_keyed = false;
            // Returns the quaternion for a rotation of `degrees` about the axis `about`.
            const auto half = [](double degrees, math::double3 about) { const double a = 0.5 * degrees * (double)TAU / 360.0; return math::quat{std::cos(a), about.x * std::sin(a), about.y * std::sin(a), about.z * std::sin(a)}; };
            const math::quat q = half(doc_number(d, t, "rotate", at, 0), {0, 0, 1}) * half(doc_number(d, t, "rotate_y", at, 0), {0, 1, 0}) * half(doc_number(d, t, "rotate_x", at, 0), {1, 0, 0});
            PhysPose p;
            p.at[0] = (float)middle.x, p.at[1] = (float)middle.y, p.at[2] = (float)middle.z;
            p.turn[0] = (float)q.x, p.turn[1] = (float)q.y, p.turn[2] = (float)q.z, p.turn[3] = (float)q.w;
            return p;
        };
        d.phys = std::make_unique<PhysWorld>(made, (float)doc_number(d, 0, "gravity", 0, 9.81), keyed);
    }
    size_t index = d.phys_of.size();
    // Copies of a layer that are not letters are not in the world, so they follow their keyframes.
    for (size_t i = 0; i < d.phys_of.size(); ++i) if (d.phys_of[i] == layer && d.phys_copy[i] == copy) { index = i; break; }
    if (index == d.phys_of.size()) return false;
    // The layer's keyframes still control it.
    if (now <= d.phys_until[index]) return false;
    // The world is stepped at 60 frames a second.
    *pose = d.phys->pose((int)index, (int)std::lround(now * 60.0));
    return true;
}

bool doc_staggered(Doc& d, int layer, double now) {
    // One box in a sketch is placed by the sketch in the same way.
    if (const DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script")); sc && sc->run && sc->run->sketch()) return true;
    // A layer with no copies but with expressions is its own single copy, index 0 of 1.
    if (!doc_expressions_fx(d, layer).empty()) return true;
    return doc_members(d, layer) > 1 || doc_number(d, layer, "stagger", 0, 0) > 0.0 || doc_number(d, layer, "field_radius", now, 0) > 0.0;
}

double doc_heading(Doc& d, int layer, double now) {
    if (doc_literal(d, layer, "orient", 0, 0) <= 0.5) return 0.0;
    // Computes the direction of motion between two times into `heading`. Returns false when the
    // layer did not move.
    const auto going = [&](double from, double to, double* heading) {
        const double ax = doc_literal(d, layer, "x", from, 0), ay = doc_literal(d, layer, "y", from, 0), bx = doc_literal(d, layer, "x", to, 0), by = doc_literal(d, layer, "y", to, 0);
        return std::hypot(bx - ax, by - ay) > 1e-6 && (*heading = std::atan2(by - ay, bx - ax), true);
    };
    double heading = 0.0;
    // Try a short window around the time first, then a longer one.
    for (const double step : {1.0 / 240.0, 1.0 / 30.0})
        if (going(now - step, now + step, &heading)) return heading;
    // The layer is standing still. Use the direction of motion as it reached the last keyframe
    // before the time, or else the direction it takes from the first keyframe after it.
    std::vector<double> keys = doc_key_times(d, layer, "x"), more = doc_key_times(d, layer, "y");
    keys.insert(keys.end(), more.begin(), more.end());
    std::sort(keys.begin(), keys.end());
    for (auto k = keys.rbegin(); k != keys.rend(); ++k)
        if (*k <= now && going(*k - 1.0 / 60.0, *k, &heading)) return heading;
    for (const double k : keys)
        if (k >= now && going(k, k + 1.0 / 60.0, &heading)) return heading;
    return 0.0;
}

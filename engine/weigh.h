// weigh.h: one way to say how a value changes across many things at once, as After Effects' text animators (a Range
// Selector and a property), Cinema 4D's Cloner with an Effector and a Falloff, CSS's selector and declaration, D3's
// select().attr(), Houdini's groups and attributes all do. One line of it answers three questions:
//   where  — which copies, how much: a weight 0 to 1 by a copy's place in the row or in space (Index, Distance,
//            Random, Noise); several multiply. None: every copy, whole.
//   when   — from when, over how long, and each copy how much later than the first: its order is a where of its
//            own (the most selected goes first; Index 1→0 unless said, so the row's first copy), so a wipe along the
//            letters, a random fade in and a ripple out from a point are one line each. None: always. `from` below 0
//            counts from the thing's end: an Out.
//   what   — which value, Set, Add or Mul, by how much; and an ease on the way there.
// A copy's weight is where × when(t), eased; the change is scaled by it. Lines stack in order, later over earlier.
//
// The pieces are few on purpose and closed: four where-kinds, one when, three ops, the eases Godot and interp.h
// already have. A new motion is a new JSON line made of these, never a new kind here. What this holds is checked by
// check/weigh.sh (After Effects' Fade In, a Cloner under a spherical Falloff, two CSS rules cascading, Texton's In and
// Out), each as JSON alone; and in the document by check/weigh_doc.sh and check/weigh_text.sh.
//
// The three columns are also where a window touches them: where on the stage (a point, a radius, a direction), when
// on the timeline (the copies' bars, each so much later), what in the inspector (a value and a number). The weight
// itself is never edited by hand; it is shown, as a colour on each copy.
//
// Nothing here draws or reads a document: a thing's copies hand it their index, place and values (doc_place.h) and
// take the values back.
#pragma once
#include "godot_easing.h"
#include <strings.h>   // (interp.h reads strcasecmp as the Mac has it)
#include "interp.h"   // (interp_bezier: the keys' own CSS curve, for an ease said as "bezier x1 y1 x2 y2")
#if __has_include("third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h")
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"   // (the copy the engine reads, as lottie_slots.h does)
#else
#include "rapidjson/document.h"   // (check/weigh.sh elsewhere: -I where rapidjson is)
#endif
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <map>
#include <string>
#include <vector>

namespace weigh {

struct Vec3 { double x = 0, y = 0, z = 0; };
using Props = std::map<std::string, double>;   // (named values: "x", "opacity", "stroke.width"; no list of them here, so a new one needs no new code)

// One of n copies at a moment: which, where, and its values as they are before the weighing.
struct Element {
    int index = 0, n = 1;
    Vec3 pos;
    Props props;
    double lasts = -1;   // (how long the thing lasts, seconds, for a `when` that counts from its end; -1: not known)
};

// where: a weight by a copy's place.
struct Where {
    enum Kind { Index, Distance, Random, Noise } kind = Index;
    double a = 0, b = 1;   // Index: the ramp from a to b along the row (a == b: a step; 1 to 0: backwards). Distance: whole within a, fading over b more.
                           // Random: a the seed. Noise: a how wide a lump is (0: the same for all), b how fast it drifts.
    Vec3 at;               // Distance: the middle
};

// when: from a moment, over a length, each copy so much later than the first by its order.
struct When {
    bool always = true;    // (no when said)
    double from = 0, over = 0, stagger = 0;   // seconds; from below 0: that long before the thing ends; over 0: a step
    std::vector<Where> order;                 // (the most selected by these goes first; none: the row's first copy)
};

// what: a value's change, scaled by the weight.
struct Effect {
    std::vector<Where> where;   // (multiplied; none: 1)
    When when;
    std::string ease;           // Godot's "Cubic.out", "Back.out", "Elastic.in_out"..., or "bezier x1 y1 x2 y2"; "": as it is
    std::string target;
    enum Op { Set, Add, Mul } op = Set;
    double value = 0;
};

static inline double clamp01(double v) { return v < 0 ? 0 : v > 1 ? 1 : v; }
static inline double hash01(uint32_t i, uint32_t seed, uint32_t k = 0) {   // (0 to 1: doc_place.h's roll, the same hash, so a scatter here and there agree)
    uint32_t h = seed * 0x9E3779B9u ^ (i + 1u) * 0x85EBCA6Bu ^ (k + 1u) * 0xC2B2AE35u;
    h ^= h >> 16, h *= 0x7FEB352Du, h ^= h >> 15, h *= 0x846CA68Bu, h ^= h >> 16;
    return (double)h / 4294967295.0;
}
static inline double noise01(Vec3 p, uint32_t seed) {   // (value noise on a lattice, eased between its corners: doc_place.h's wave noise)
    const double fx = std::floor(p.x), fy = std::floor(p.y), fz = std::floor(p.z);
    const double ux = p.x - fx, uy = p.y - fy, uz = p.z - fz;
    const double ex = ux * ux * (3 - 2 * ux), ey = uy * uy * (3 - 2 * uy), ez = uz * uz * (3 - 2 * uz);
    double sum = 0;
    for (int c = 0; c < 8; ++c) {
        const uint32_t i = (uint32_t)(int64_t)fx + (c & 1), j = (uint32_t)(int64_t)fy + ((c >> 1) & 1), k = (uint32_t)(int64_t)fz + ((c >> 2) & 1);
        sum += hash01(i * 73856093u ^ j * 19349663u, seed, k) * ((c & 1) ? ex : 1 - ex) * ((c & 2) ? ey : 1 - ey) * ((c & 4) ? ez : 1 - ez);
    }
    return sum;
}

// An ease by its Godot name, "Trans.ease" (Sine.in_out, Cubic.out, Elastic.out, Bounce.out, Back.in...), or the
// keys' own CSS curve, "bezier x1 y1 x2 y2" (Texton's easing editor, After Effects' graph editor): u → 0..1.
static inline double ease(const std::string& way, double u) {
    u = clamp01(u);
    if (way.rfind("bezier", 0) == 0) { double b[4] = {0.25, 0.1, 0.25, 1}; std::sscanf(way.c_str() + 6, "%lf %lf %lf %lf", &b[0], &b[1], &b[2], &b[3]); return interp_bezier(clamp01(b[0]), b[1], clamp01(b[2]), b[3], u); }
    const size_t dot = way.find('.');
    const std::string trans = way.substr(0, dot), kind = dot == std::string::npos ? "in" : way.substr(dot + 1);
#define WEIGH_EASE(T) if (trans == #T) { if (kind == "out") return godot::T::out(u, 0, 1, 1); if (kind == "in_out") return godot::T::in_out(u, 0, 1, 1); if (kind == "out_in") return godot::T::out_in(u, 0, 1, 1); return godot::T::in(u, 0, 1, 1); }
    WEIGH_EASE(Sine) WEIGH_EASE(Quint) WEIGH_EASE(Quart) WEIGH_EASE(Quad) WEIGH_EASE(Expo) WEIGH_EASE(Elastic) WEIGH_EASE(Cubic) WEIGH_EASE(Circ) WEIGH_EASE(Bounce) WEIGH_EASE(Back) WEIGH_EASE(Spring)
#undef WEIGH_EASE
    return u;   // ("", "Linear", or unknown: as it is)
}

// where: a copy's weight by its place, at a moment t (Noise drifts).
static double where(const Where& w, const Element& e, double t) {
    const double u = e.n > 1 ? (double)e.index / (e.n - 1) : 0;   // (how far along the row, 0 to 1)
    switch (w.kind) {
    case Where::Index:    return clamp01(w.b == w.a ? (u >= w.a ? 1 : 0) : (u - w.a) / (w.b - w.a));
    case Where::Distance: { const double dx = e.pos.x - w.at.x, dy = e.pos.y - w.at.y, dz = e.pos.z - w.at.z, far = std::sqrt(dx * dx + dy * dy + dz * dz);
                            return 1 - clamp01(w.b <= 0 ? (far > w.a ? 1 : 0) : (far - w.a) / w.b); }
    case Where::Random:   return hash01((uint32_t)e.index, (uint32_t)w.a);
    case Where::Noise:    return noise01({w.a > 0 ? e.pos.x / w.a : 0, w.a > 0 ? e.pos.y / w.a : 0, (w.a > 0 ? e.pos.z / w.a : 0) + t * w.b}, 0);
    }
    return 1;
}
static double where(const std::vector<Where>& all, const Element& e, double t) {
    double w = 1;
    for (const Where& one : all) w *= where(one, e, t);
    return w;
}
// when: how far through its moment a copy is, 0 to 1; it starts `stagger` × its order later than the first, its order
// how little its `order` selects it (the most selected goes first: the row's first copy for Index 1→0, the nearest
// for a Distance, any for Random).
static double when(const When& w, const Element& e, double t) {
    if (w.always) return 1;
    static const std::vector<Where> first{Where{Where::Index, 1, 0}};
    const double order = 1 - where(w.order.empty() ? first : w.order, e, t);
    const double from = (w.from < 0 && e.lasts >= 0 ? e.lasts + w.from : w.from) + w.stagger * order;
    return clamp01(w.over <= 0 ? (t >= from ? 1 : 0) : (t - from) / w.over);
}
// The weight of a copy at a moment: where × when, eased.
static double weight(const Effect& fx, const Element& e, double t) { return ease(fx.ease, where(fx.where, e, t) * when(fx.when, e, t)); }

// A value after a change, scaled by the weight: 0 leaves it, 1 is the whole change.
static inline double apply(const Effect& fx, double cur, double w) {
    switch (fx.op) {
    case Effect::Set: return cur + (fx.value - cur) * w;
    case Effect::Add: return cur + fx.value * w;
    case Effect::Mul: return cur * (1 + (fx.value - 1) * w);
    }
    return cur;
}

// A copy's values after the stack, in order. A target not in its values starts at 0 (a Mul of nothing is nothing).
static Props resolve(const Element& e, const std::vector<Effect>& stack, double t) {
    Props out = e.props;
    for (const Effect& fx : stack) {
        double& v = out[fx.target];
        v = apply(fx, v, weight(fx, e, t));
    }
    return out;
}

// --- As JSON, one line: { "where": {"kind":"Distance","at":[0,0],"a":0.1,"b":0.2} (or a list of them),
//                          "when":  {"from":0,"over":0.5,"stagger":0.6, "order":{"kind":"Random","a":50}},
//                          "ease":  "Back.out",
//                          "target":"x", "op":"Add", "value":-0.3 }     A stack is a list of lines, or one alone. ---
static Where where_of(const rapidjson::Value& j) {
    Where w;
    static const std::map<std::string, Where::Kind> kinds{{"Index", Where::Index}, {"Distance", Where::Distance}, {"Random", Where::Random}, {"Noise", Where::Noise}};
    if (!j.IsObject()) return w;
    if (auto k = j.FindMember("kind"); k != j.MemberEnd() && k->value.IsString()) if (auto it = kinds.find(k->value.GetString()); it != kinds.end()) w.kind = it->second;
    const auto num = [&](const char* name, double& into) { if (auto m = j.FindMember(name); m != j.MemberEnd() && m->value.IsNumber()) into = m->value.GetDouble(); };
    num("a", w.a), num("b", w.b);
    if (auto m = j.FindMember("at"); m != j.MemberEnd() && m->value.IsArray() && m->value.Size() >= 2) w.at = {m->value[0].GetDouble(), m->value[1].GetDouble(), m->value.Size() > 2 ? m->value[2].GetDouble() : 0.0};
    return w;
}
static Effect effect_of(const rapidjson::Value& j) {
    Effect fx;
    if (!j.IsObject()) return fx;
    if (auto m = j.FindMember("where"); m != j.MemberEnd()) {
        if (m->value.IsArray()) for (const auto& one : m->value.GetArray()) fx.where.push_back(where_of(one));
        else fx.where.push_back(where_of(m->value));
    }
    if (auto m = j.FindMember("when"); m != j.MemberEnd() && m->value.IsObject()) {
        fx.when.always = false;
        const auto num = [&](const char* name, double& into) { if (auto k = m->value.FindMember(name); k != m->value.MemberEnd() && k->value.IsNumber()) into = k->value.GetDouble(); };
        num("from", fx.when.from), num("over", fx.when.over), num("stagger", fx.when.stagger);
        if (auto k = m->value.FindMember("order"); k != m->value.MemberEnd()) {
            if (k->value.IsArray()) for (const auto& one : k->value.GetArray()) fx.when.order.push_back(where_of(one));
            else fx.when.order.push_back(where_of(k->value));
        }
    }
    if (auto m = j.FindMember("ease"); m != j.MemberEnd() && m->value.IsString()) fx.ease = m->value.GetString();
    if (auto m = j.FindMember("target"); m != j.MemberEnd() && m->value.IsString()) fx.target = m->value.GetString();
    if (auto m = j.FindMember("op"); m != j.MemberEnd() && m->value.IsString()) fx.op = std::string(m->value.GetString()) == "Add" ? Effect::Add : std::string(m->value.GetString()) == "Mul" ? Effect::Mul : Effect::Set;
    if (auto m = j.FindMember("value"); m != j.MemberEnd() && m->value.IsNumber()) fx.value = m->value.GetDouble();
    return fx;
}
static std::vector<Effect> stack_of(const char* json, std::string* trouble = nullptr) {
    rapidjson::Document d;
    d.Parse(json);
    std::vector<Effect> stack;
    if (d.HasParseError()) { if (trouble) *trouble = "not JSON at " + std::to_string(d.GetErrorOffset()); return stack; }
    if (d.IsArray()) for (const auto& one : d.GetArray()) stack.push_back(effect_of(one));
    else stack.push_back(effect_of(d));
    return stack;
}

// A thing's copies, each what the stack makes of it: ScriptCopy-shaped (x y z in the stage's units added, size and
// rotate multiplied and added, opacity multiplied), so a document feeds it where its scripts' copies go (doc_place.h).
// pos: where each copy lies before this (what a Distance weighs); t: the thing's own seconds; lasts: how long it lasts (a `when` from its end counts from there).
template <class Copy>
static std::vector<Copy> copies(const std::vector<Effect>& stack, const std::vector<Vec3>& pos, double t, double lasts = -1) {
    std::vector<Copy> out(pos.size());
    for (size_t i = 0; i < pos.size(); ++i) {
        Element e;
        e.index = (int)i, e.n = (int)pos.size(), e.pos = pos[i], e.lasts = lasts;
        e.props = {{"x", 0}, {"y", 0}, {"z", 0}, {"size", 1}, {"rotate", 0}, {"rotate_x", 0}, {"rotate_y", 0}, {"opacity", 1}, {"scale_x", 1}, {"scale_y", 1}, {"scale_z", 1}};
        const Props p = resolve(e, stack, t);
        Copy& c = out[i];
        c.x = p.at("x"), c.y = p.at("y"), c.z = p.at("z"), c.size = p.at("size"), c.rotate = p.at("rotate"), c.rotate_x = p.at("rotate_x"), c.rotate_y = p.at("rotate_y");
        c.opacity = clamp01(p.at("opacity")), c.scale_x = p.at("scale_x"), c.scale_y = p.at("scale_y"), c.scale_z = p.at("scale_z");
    }
    return out;
}

}   // namespace weigh

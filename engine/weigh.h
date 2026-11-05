// weigh.h: one way to say how a value changes across many things at once, as After Effects' text animators (a Range
// Selector and a property), Cinema 4D's Cloner with an Effector and a Falloff, CSS's selector and declaration, D3's
// select().attr(), Houdini's groups and attributes all do: pick (a weight, 0 to 1, for each of n copies at a moment),
// then change (a value's change, scaled by the weight), one over another in order. Everything is a multiplication:
// the change times the weight, and weights times each other.
//
// The pieces are few on purpose and closed: five weights (Index, Distance, Noise, Random, Time), three ways to put
// weights together (a Remap by one of Godot's eases, Min, Max; more than one inside any weight are multiplied), three
// changes (Set, Add, Mul). A new motion is a new JSON file made of these, never a new kind here. What this holds is
// checked by check/weigh.sh: After Effects' Fade In, a Cloner under a spherical Falloff, and CSS's :nth-child(odd),
// each as JSON alone.
//
// A Time weight is the one whose inner weights are not multipliers: they are its ORDER, how far along the row a copy
// is, so each copy starts `delay` later than the first by that much. That is the whole of a text animator's moving
// range selector (and of Cavalry's Animators, script.cpp's animate()): Time with Index inside wipes along the letters;
// Time with Random inside is Random Fade In.
//
// Nothing here draws or reads a document: a thing's copies hand it their index, place and values (doc_place.h) and
// take the values back.
#pragma once
#include "godot_easing.h"
#if __has_include("third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h")
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"   // (the copy the engine reads, as lottie_slots.h does)
#else
#include "rapidjson/document.h"   // (check/weigh.sh elsewhere: -I where rapidjson is)
#endif
#include <algorithm>
#include <cmath>
#include <cstdint>
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
};

// A weight, 0 to 1 for a copy at a moment.
struct Field {
    enum Kind { Index, Distance, Noise, Random, Time, Remap, Min, Max } kind = Index;
    double a = 0, b = 1;   // (what they mean, by kind, in weight() below)
    Vec3 at;               // Distance: the middle
    double delay = 0;      // Time: how much later the last copy starts than the first
    std::string way;       // Remap: one of Godot's eases, "Cubic.out", "Sine.in_out", "Bounce.out"...; "" is as it is
    std::vector<Field> in; // (multiplied together; Remap/Min/Max read them; Time's are its order)
};

// A change: a value's, by this much, scaled by the weight.
struct Effect {
    Field weight;
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

// An ease by its Godot name, "Trans.ease" (Sine.in_out, Cubic.out, Elastic.out, Bounce.out, Back.in...): u → 0..1.
static inline double ease(const std::string& way, double u) {
    u = clamp01(u);
    const size_t dot = way.find('.');
    const std::string trans = way.substr(0, dot), kind = dot == std::string::npos ? "in" : way.substr(dot + 1);
#define WEIGH_EASE(T) if (trans == #T) { if (kind == "out") return godot::T::out(u, 0, 1, 1); if (kind == "in_out") return godot::T::in_out(u, 0, 1, 1); if (kind == "out_in") return godot::T::out_in(u, 0, 1, 1); return godot::T::in(u, 0, 1, 1); }
    WEIGH_EASE(Sine) WEIGH_EASE(Quint) WEIGH_EASE(Quart) WEIGH_EASE(Quad) WEIGH_EASE(Expo) WEIGH_EASE(Elastic) WEIGH_EASE(Cubic) WEIGH_EASE(Circ) WEIGH_EASE(Bounce) WEIGH_EASE(Back) WEIGH_EASE(Spring)
#undef WEIGH_EASE
    return u;   // ("", "Linear", or unknown: as it is)
}

// The weight of a copy at a moment t (seconds).
static double weight(const Field& f, const Element& e, double t) {
    double w = 1;
    if (f.kind != Field::Time && f.kind != Field::Min && f.kind != Field::Max) for (const Field& c : f.in) w *= weight(c, e, t);
    const double u = e.n > 1 ? (double)e.index / (e.n - 1) : 0;   // (how far along the row, 0 to 1)
    switch (f.kind) {
    case Field::Index:    return w * clamp01(f.b == f.a ? (u >= f.a ? 1 : 0) : (u - f.a) / (f.b - f.a));   // (a ramp along the row from a to b; a == b: a step)
    case Field::Distance: {                                                                                   // (whole within radius a, fading over band b; the Field card's field_radius and field_band)
        const double dx = e.pos.x - f.at.x, dy = e.pos.y - f.at.y, dz = e.pos.z - f.at.z, far = std::sqrt(dx * dx + dy * dy + dz * dz);
        return w * (1 - clamp01(f.b <= 0 ? (far > f.a ? 1 : 0) : (far - f.a) / f.b));
    }
    case Field::Noise:    return w * noise01({f.a > 0 ? e.pos.x / f.a : 0, f.a > 0 ? e.pos.y / f.a : 0, (f.a > 0 ? e.pos.z / f.a : 0) + t * f.b}, 0);   // (a: how wide a lump is, 0 reads nothing of the place; b: how fast it drifts)
    case Field::Random:   return w * hash01((uint32_t)e.index, (uint32_t)f.a);                                   // (a: the seed)
    case Field::Time: {                                                                                       // (from a, over b seconds; its order inside: so much of delay later)
        double order = 1;
        for (const Field& c : f.in) order *= weight(c, e, t);
        return clamp01(f.b <= 0 ? (t >= f.a + f.delay * order ? 1 : 0) : (t - f.a - f.delay * order) / f.b);
    }
    case Field::Remap:    return ease(f.way, w);
    case Field::Min: { double m = 1; for (const Field& c : f.in) m = std::min(m, weight(c, e, t)); return m; }
    case Field::Max: { double m = 0; for (const Field& c : f.in) m = std::max(m, weight(c, e, t)); return m; }
    }
    return w;
}

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
        v = apply(fx, v, weight(fx.weight, e, t));
    }
    return out;
}

// --- As JSON: a field {"kind":"Time","a":0,"b":1,"delay":0.5,"in":[{"kind":"Index"}]}, an effect {"weight":{...},
// "target":"opacity","op":"Set","value":1}, a stack an array of effects (or one effect alone). ---
static Field field_of(const rapidjson::Value& j) {
    Field f;
    static const std::map<std::string, Field::Kind> kinds{{"Index", Field::Index}, {"Distance", Field::Distance}, {"Noise", Field::Noise}, {"Random", Field::Random}, {"Time", Field::Time}, {"Remap", Field::Remap}, {"Min", Field::Min}, {"Max", Field::Max}};
    if (!j.IsObject()) return f;
    if (auto k = j.FindMember("kind"); k != j.MemberEnd() && k->value.IsString()) if (auto it = kinds.find(k->value.GetString()); it != kinds.end()) f.kind = it->second;
    const auto num = [&](const char* name, double& into) { if (auto m = j.FindMember(name); m != j.MemberEnd() && m->value.IsNumber()) into = m->value.GetDouble(); };
    num("a", f.a), num("b", f.b), num("delay", f.delay);
    if (auto m = j.FindMember("at"); m != j.MemberEnd() && m->value.IsArray() && m->value.Size() >= 2) f.at = {m->value[0].GetDouble(), m->value[1].GetDouble(), m->value.Size() > 2 ? m->value[2].GetDouble() : 0.0};
    if (auto m = j.FindMember("way"); m != j.MemberEnd() && m->value.IsString()) f.way = m->value.GetString();
    if (auto m = j.FindMember("in"); m != j.MemberEnd() && m->value.IsArray()) for (const auto& c : m->value.GetArray()) f.in.push_back(field_of(c));
    return f;
}
static Effect effect_of(const rapidjson::Value& j) {
    Effect fx;
    if (!j.IsObject()) return fx;
    if (auto m = j.FindMember("weight"); m != j.MemberEnd()) fx.weight = field_of(m->value);
    else fx.weight.a = fx.weight.b = 0;   // (no weight said: 1 for every copy, as a CSS rule with no selector but the element's; a step at the row's start)
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
// pos: where each copy lies before this (what a Distance weighs); t: the thing's own seconds.
template <class Copy>
static std::vector<Copy> copies(const std::vector<Effect>& stack, const std::vector<Vec3>& pos, double t) {
    std::vector<Copy> out(pos.size());
    for (size_t i = 0; i < pos.size(); ++i) {
        Element e;
        e.index = (int)i, e.n = (int)pos.size(), e.pos = pos[i];
        e.props = {{"x", 0}, {"y", 0}, {"z", 0}, {"size", 1}, {"rotate", 0}, {"rotate_x", 0}, {"rotate_y", 0}, {"opacity", 1}, {"scale_x", 1}, {"scale_y", 1}, {"scale_z", 1}};
        const Props p = resolve(e, stack, t);
        Copy& c = out[i];
        c.x = p.at("x"), c.y = p.at("y"), c.z = p.at("z"), c.size = p.at("size"), c.rotate = p.at("rotate"), c.rotate_x = p.at("rotate_x"), c.rotate_y = p.at("rotate_y");
        c.opacity = clamp01(p.at("opacity")), c.scale_x = p.at("scale_x"), c.scale_y = p.at("scale_y"), c.scale_z = p.at("scale_z");
    }
    return out;
}

}   // namespace weigh

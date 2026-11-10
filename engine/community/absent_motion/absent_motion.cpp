// Implementation of absent_motion.h: AbsentMotion's motion, repeat, opacity, text and shutter
// effects (Auto Shake, Random Displace, Random Jitter, Oscillate, Swing, Spin, Pulse Size and
// others; motion.cpp ApplyMotion). AbsentMotion is Apache-2.0, Copyright 2026 The AbsentMotion
// authors.
//
// Each function builds an AbsentMotion layer (scene.h) from the caller's layer number, times and
// effects, and calls AbsentMotion's own code on it. This file is built apart (see
// CMakeLists.txt) together with AbsentMotion's motion.cpp, scene.cpp and easing.cpp,
// unchanged. The parts of scene.cpp that draw or read a scene are never called, and the linker
// removes them (dead stripping).
#include "community/absent_motion/absent_motion.h"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "easing.h"
#include "scene.h"
#include "textanim.h"

#include "community/absent_motion/absent_layer.h"

// See absent_layer.h.
am::Layer absent_layer(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs) {
    am::Layer l;
    l.id = l.noiseId = thing;
    l.startTime = (int)startMs, l.endTime = (int)endMs;
    for (const AbsentEffect& e : effects) {
        am::LayerEffect one;
        one.id = "absent." + e.id;
        for (const auto& [name, v] : e.params) {
            am::Property p;
            p.name = name, p.anim.value = v;
            one.props.push_back(p);
        }
        l.effects.push_back(one);
    }
    return l;
}

// See absent_motion.h. The placement starts at no movement, and ApplyMotion adds to it.
AbsentMoved absent_motion(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs) {
    const am::Layer l = absent_layer(effects, thing, startMs, endMs);
    am::Placement p{};
    p.location = SkPoint{0, 0}, p.pivot = SkPoint{0, 0}, p.scale = SkPoint{1, 1}, p.rotation = 0, p.z = 0;
    am::ApplyMotion(l, nowMs, &p);
    return {p.location.fX, p.location.fY, p.z, p.rotation, p.scale.fX, p.scale.fY};
}

// See absent_motion.h.
float absent_opacity(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs) {
    return am::MotionOpacity(absent_layer(effects, thing, startMs, endMs), nowMs);
}

namespace {

// Scatter Repeat is Alight Motion's own effect, which AbsentMotion has not converted. Its
// docs/ALIGHT_COMPATIBILITY.md says "Not converted yet", and no other implementation was found.
// It is therefore written here from what Alight Motion 6.2.60 shows of it, recorded in
// docs/internal/reports/alight_motion/alight_checklist.md:
//   - The layer itself stays, and Count copies of it lie in a disc of Radius around its place.
//   - Each copy has its own position, derived from its index and Seed. A copy keeps its place
//     when Count grows, and it moves smoothly as Evolution changes.
//   - Range Transform (Offset, Angle, Scale, Alpha) applies to the copies inside the Range, as
//     AbsentMotion's own Ranged does for its repeats (Start, End, Phase, Random Order).
// Not implemented yet, and not yet read from Alight Motion: Fill Color, Ease In, Ease Out,
// Overlap, Shape and Invert.

// Returns the value at index i of the parameter called name on effect e, or usual when the
// effect has no such parameter or its list is shorter than i + 1.
double scatter_parameter(const AbsentEffect& e, const char* name, size_t i, double usual) {
    for (const auto& [n, v] : e.params)
        if (n == name) return i < v.size() ? v[i] : usual;
    return usual;
}

// Returns a hash of seed and k as a number from 0 up to but not including 1 (splitmix64).
double scatter_unit(uint64_t seed, uint64_t k) {
    uint64_t x = seed + (k + 1) * 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull, x = (x ^ (x >> 27)) * 0x94d049bb133111ebull, x ^= x >> 31;
    return (double)(x >> 11) * (1.0 / 9007199254740992.0);
}

// Folds v back and forth into the range 0 to 1, so that a wandering value never leaves the disc.
double scatter_fold(double v) { return 1.0 - std::fabs(1.0 - std::fmod(std::fabs(v), 2.0)); }

// Returns the copies that Scatter Repeat effect e makes, first copy on top.
std::vector<am::RepeatCopy> scatter_repeat(const AbsentEffect& e) {
    const int n = (int)std::clamp<long long>(std::llround(scatter_parameter(e, "count", 0, 20)), 0, 5000);
    const double radius = std::max(0.0, scatter_parameter(e, "radius", 0, 300)), evolution = scatter_parameter(e, "evolution", 0, 0);
    const uint64_t seed = (uint64_t)std::llround(scatter_parameter(e, "seed", 0, 0) * 1000.0) * 0x2545f4914f6cdd1dull + 0x51ed27ull;
    const double phase = scatter_parameter(e, "rangePhase", 0, 0);
    const double start = scatter_parameter(e, "rangeStart", 0, 0) + phase, end = scatter_parameter(e, "rangeEnd", 0, 1) + phase;
    const SkPoint offset = {(float)scatter_parameter(e, "rangeOffset", 0, 0), (float)scatter_parameter(e, "rangeOffset", 1, 0)};
    const double angle = scatter_parameter(e, "rangeAngle", 0, 0), scale = std::max(0.0, scatter_parameter(e, "rangeScale", 0, 1)), alpha = std::clamp(scatter_parameter(e, "rangeAlpha", 0, 1), 0.0, 1.0);
    std::vector<size_t> order(n);
    for (int i = 0; i < n; i++) order[i] = i;
    // With Random Order, the Range reaches the copies in a shuffled order, sorted the way
    // AbsentMotion's Random Order sorts its spots.
    if (scatter_parameter(e, "randomOrder", 0, 0) >= 0.5 && n > 1) {
        const uint64_t rs = (uint64_t)std::llround(scatter_parameter(e, "randomSeed", 0, 0) * 1000.0) * 0x9e3779b97f4a7c15ull + 0x77ull;
        std::sort(order.begin(), order.end(), [&](size_t a, size_t b) { return scatter_unit(rs, a) < scatter_unit(rs, b); });
    }
    // How far along the Range each copy is, from 0 to 1.
    std::vector<double> reaches(n);
    for (int k = 0; k < n; k++) reaches[order[k]] = n > 1 ? (double)k / (n - 1) : 0.0;
    std::vector<am::RepeatCopy> out;
    out.reserve(n);
    // Counting down puts the first copy on top, as AbsentMotion's Ranged lays its spots.
    for (int i = n - 1; i >= 0; i--) {
        const double turn = 2.0 * M_PI * (scatter_unit(seed, 2 * i) + 0.5 * am::SimplexNoise2(evolution * 0.8, i * 3.17 + 0.5)), far = std::sqrt(scatter_fold(scatter_unit(seed, 2 * i + 1) + 0.5 * am::SimplexNoise2(evolution * 0.8 + 41.3, i * 3.17 + 9.1)));
        const double u = reaches[i], w = end - start > 1e-6 ? std::clamp((u - start) / (end - start), 0.0, 1.0) : (u >= start ? 1.0 : 0.0);
        am::RepeatCopy c;
        c.local = SkMatrix::Translate((float)(radius * far * std::cos(turn) + offset.fX * w), (float)(radius * far * std::sin(turn) + offset.fY * w));
        c.local.preRotate((float)(angle * w));
        const float k = (float)(1.0 + (scale - 1.0) * w);
        c.local.preScale(k, k);
        c.alpha = (float)(1.0 + (alpha - 1.0) * w);
        out.push_back(c);
    }
    return out;
}

// Lays a new repeat on the copies built before it: each copy of the new repeat is placed by
// each of the old copies, as AbsentMotion's RepeatCopies does. The total is capped at 25000.
std::vector<am::RepeatCopy> scatter_on(const std::vector<am::RepeatCopy>& built, const std::vector<am::RepeatCopy>& result) {
    std::vector<am::RepeatCopy> next;
    next.reserve(std::min<size_t>(25000, built.size() * result.size()));
    for (const am::RepeatCopy& m : built)
        for (const am::RepeatCopy& r : result) {
            if (next.size() >= 25000) break;
            am::RepeatCopy c = r;
            c.outer = m.outer * r.outer, c.local = m.local * r.local;
            if (!c.outer.isFinite() || !c.local.isFinite()) continue;
            c.shiftMs = r.shiftMs + m.shiftMs, c.alpha = r.alpha * m.alpha;
            next.push_back(c);
        }
    return next;
}

}  // namespace

// See absent_motion.h. The copies are laid as AbsentMotion's CopiesOf (styles.cpp) lays them:
// from the layer's matrix where it stands, with the layer's rotation and size taken from the
// caller's layer. Each copy is outer, then the layer, then local, and is reported relative to
// the layer's own place.
std::vector<AbsentCopy> absent_copies(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, float wide, float high, float atX, float atY, float reach) {
    // Scatter Repeat is built in this file. All other repeats are built by AbsentMotion.
    std::vector<AbsentEffect> others, scatters;
    for (const AbsentEffect& e : effects) (e.id == "scatterrepeat" ? scatters : others).push_back(e);
    const am::Layer l = absent_layer(others, thing, startMs, endMs);
    if (!am::HasRepeat(l) && scatters.empty()) return {};
    am::RepeatSpace space;
    space.width = wide, space.height = high, space.radius = reach;
    space.anchor = SkPoint{atX, atY}, space.layer = SkMatrix::Translate(atX, atY);
    std::vector<am::RepeatCopy> copies(1);
    if (am::HasRepeat(l)) am::RepeatCopies(l, nowMs, space, &copies);
    for (const AbsentEffect& e : scatters) copies = scatter_on(scatter_repeat(e), copies);
    std::vector<AbsentCopy> out;
    out.reserve(copies.size());
    for (const am::RepeatCopy& c : copies) {
        const SkMatrix m = SkMatrix::Translate(-atX, -atY) * c.outer * space.layer * c.local;
        out.push_back({m.getTranslateX(), m.getTranslateY(), std::atan2(m.getSkewY(), m.getScaleX()) * 180.0 / M_PI, std::hypot(m.getScaleX(), m.getSkewY()), c.alpha});
    }
    return out;
}

// See absent_motion.h.
double absent_ease(const char* type, const double* p, int n, double u) {
    static const struct { const char* name; am::Easing::Type type; } kinds[] = {{"bounce", am::Easing::kBounce}, {"elastic", am::Easing::kElastic}, {"cyclic", am::Easing::kCyclic}, {"random", am::Easing::kRandom}, {"step", am::Easing::kStep}, {"elasticStep", am::Easing::kElasticStep}};
    am::Easing e;
    for (const auto& k : kinds) if (!std::strcmp(k.name, type)) e.type = k.type;
    for (int i = 0; i < n && i < 8; ++i) e.p[e.count++] = (float)p[i];
    return am::Ease(e, (float)u);
}

// See absent_motion.h. Text effects are applied in their order on the layer, using
// textanim.cpp's CountNumbers, FormatTimecode and Scramble. This follows how AbsentMotion's
// text.cpp Shown changes a text layer's words, including its Choice and Seed helpers. Shown is
// not called because text.cpp also holds Skia paragraph code that is not built here.
//
// AbsentMotion's Text Randomizer takes a list of characters to draw from, but this adapter
// cannot pass a text parameter. Scramble therefore gets an empty list and uses its own default
// character set, as AbsentMotion does when none is given.
bool absent_text_on(const std::vector<AbsentEffect>& effects) {
    return std::any_of(effects.begin(), effects.end(), [](const AbsentEffect& e) { return e.id == "countupdown" || e.id == "timecode" || e.id == "textrandomizer"; });
}
std::string absent_text(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, int fps, std::string text) {
    const am::Layer l = absent_layer(effects, thing, startMs, endMs);
    const float t = l.localTime(nowMs);
    const auto Choice = [&](const am::LayerEffect& e, const char* name, int fallback, int last) { return std::clamp((int)std::lround(e.value(name, t, (float)fallback)), 0, last); };
    const auto Seed = [&](const am::LayerEffect& e) { return am::textanim::Mix((uint64_t)l.id ^ am::textanim::Mix((uint64_t)std::llround((double)e.value("seed", t, 1) * 1000))); };
    const double begin = am::textanim::FrameMs(l.startTime, fps);
    const double now = am::textanim::FrameMs(l.startTime + (double)t * std::max(0, l.endTime - l.startTime), fps);
    const double local = (now - (std::floor(begin) == l.startTime ? begin : l.startTime)) / 1000.0;
    for (const am::LayerEffect& e : l.effects) {
        if (e.hidden) continue;
        if (e.id == "absent.countupdown") {
            text = am::textanim::CountNumbers(text, e.value("add", t, 0), e.value("multiply", t, 1), Choice(e, "decimals", 0, 4) - 1, Choice(e, "separator", 0, 3));
        } else if (e.id == "absent.timecode") {
            const double clock = Choice(e, "source", 0, 1) == 1 ? now / 1000.0 : local;
            text = am::textanim::FormatTimecode(clock * e.value("speed", t, 1) + e.value("offset", t, 0), fps, Choice(e, "format", 0, 5));
        } else if (e.id == "absent.textrandomizer") {
            const int64_t tick = (int64_t)std::floor(local * std::max(0.0f, e.value("speed", t, 12)) + 1e-6);
            const float evolution = e.value("evolution", t, 0);
            const uint64_t seed = Seed(e) ^ (evolution == 0 ? 0 : am::textanim::Mix(std::bit_cast<uint32_t>(evolution)));
            text = am::textanim::Scramble(text, std::clamp(e.value("progress", t, 0), 0.0f, 1.0f), Choice(e, "direction", 0, 3), seed, tick, Choice(e, "charset", 0, 6), "",
                                      e.value("keepSpaces", t, 1) >= 0.5f, std::clamp(e.value("amount", t, 1), 0.0f, 1.0f), e.value("start", t, 0), e.value("end", t, 1));
        }
    }
    return text;
}

// See absent_motion.h.
bool absent_shutter(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, int fps, double* open, bool* moves) {
    am::ShutterBlur blur;
    if (!am::ShutterBlurOf(absent_layer(effects, thing, startMs, endMs), nowMs, &blur)) return false;
    // The shutter is open for the angle's share of one frame, as DrawShuttered opens it.
    *open = blur.angle / 360.0 / std::max(1, fps), *moves = blur.position;
    return true;
}

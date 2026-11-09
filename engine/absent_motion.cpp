// absent_motion.cpp: AbsentMotion's own motion effects (Auto Shake, Random Displace, Random Jitter, Oscillate, Swing,
// Spin, Pulse Size: its motion.cpp ApplyMotion; Apache-2.0, Copyright 2026 The AbsentMotion authors), run as AbsentMotion
// runs them: a layer of its own (scene.h) given the thing's time and its effects in order, its placement begun where
// nothing is moved. Built apart (gpu/kit_wgpu.sh), beside AbsentMotion's motion.cpp, scene.cpp and easing.cpp as
// they are (what of scene.cpp draws or reads a scene is not reached: the library is linked dead-stripped).
#include "absent_motion.h"
#include "scene.h"
#include "textanim.h"
#include <algorithm>
#include <bit>
#include <cmath>
#include <cstring>

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
AbsentMoved absent_motion(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs) {
    const am::Layer l = absent_layer(effects, thing, startMs, endMs);
    am::Placement p{};
    p.location = SkPoint{0, 0}, p.pivot = SkPoint{0, 0}, p.scale = SkPoint{1, 1}, p.rotation = 0, p.z = 0;
    am::ApplyMotion(l, nowMs, &p);
    return {p.location.fX, p.location.fY, p.z, p.rotation, p.scale.fX, p.scale.fY};
}
float absent_opacity(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs) {
    return am::MotionOpacity(absent_layer(effects, thing, startMs, endMs), nowMs);
}
// Scatter Repeat: Alight Motion's own, which AbsentMotion has not converted (its docs/ALIGHT_COMPATIBILITY.md says "Not
// converted yet"; no other implementation was found), so written here from what Alight Motion 6.2.60 shows of it
// (docs/reports/alight_checklist.md): the layer itself goes and Count copies of it lie in a disc of Radius about where it stood,
// each its own way by its number and Seed (one keeps its place when Count grows), moving smoothly as Evolution changes;
// Range Transform (Offset, Angle, Scale, Alpha) on the copies in its Range, as AbsentMotion's own Ranged does for its repeats
// (Start, End, Phase, Random Order). Not made yet, not yet read from Alight Motion: Fill Color, Ease In, Ease Out, Overlap,
// Shape, Invert.
static double scatter_knob(const AbsentEffect& e, const char* name, size_t i, double usual) {
    for (const auto& [n, v] : e.params)
        if (n == name) return i < v.size() ? v[i] : usual;
    return usual;
}
static double scatter_unit(uint64_t seed, uint64_t k) {   // (0 to 1, a hash of the seed and which: splitmix64)
    uint64_t x = seed + (k + 1) * 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull, x = (x ^ (x >> 27)) * 0x94d049bb133111ebull, x ^= x >> 31;
    return (double)(x >> 11) * (1.0 / 9007199254740992.0);
}
static double scatter_fold(double v) { return 1.0 - std::fabs(1.0 - std::fmod(std::fabs(v), 2.0)); }   // (back and forth inside 0 to 1: a wander never leaves the disc)
static std::vector<am::RepeatCopy> scatter_repeat(const AbsentEffect& e) {
    const int n = (int)std::clamp<long long>(std::llround(scatter_knob(e, "count", 0, 20)), 0, 5000);
    const double radius = std::max(0.0, scatter_knob(e, "radius", 0, 300)), evolution = scatter_knob(e, "evolution", 0, 0);
    const uint64_t seed = (uint64_t)std::llround(scatter_knob(e, "seed", 0, 0) * 1000.0) * 0x2545f4914f6cdd1dull + 0x51ed27ull;
    const double phase = scatter_knob(e, "rangePhase", 0, 0);
    const double start = scatter_knob(e, "rangeStart", 0, 0) + phase, end = scatter_knob(e, "rangeEnd", 0, 1) + phase;
    const SkPoint offset = {(float)scatter_knob(e, "rangeOffset", 0, 0), (float)scatter_knob(e, "rangeOffset", 1, 0)};
    const double angle = scatter_knob(e, "rangeAngle", 0, 0), scale = std::max(0.0, scatter_knob(e, "rangeScale", 0, 1)), alpha = std::clamp(scatter_knob(e, "rangeAlpha", 0, 1), 0.0, 1.0);
    std::vector<size_t> order(n);
    for (int i = 0; i < n; i++) order[i] = i;
    if (scatter_knob(e, "randomOrder", 0, 0) >= 0.5 && n > 1) {   // (the order the Range reaches them in, the way AbsentMotion's Random Order sorts its spots)
        const uint64_t rs = (uint64_t)std::llround(scatter_knob(e, "randomSeed", 0, 0) * 1000.0) * 0x9e3779b97f4a7c15ull + 0x77ull;
        std::sort(order.begin(), order.end(), [&](size_t a, size_t b) { return scatter_unit(rs, a) < scatter_unit(rs, b); });
    }
    std::vector<double> reaches(n);   // (how far along the Range each copy is, 0 to 1)
    for (int k = 0; k < n; k++) reaches[order[k]] = n > 1 ? (double)k / (n - 1) : 0.0;
    std::vector<am::RepeatCopy> out;
    out.reserve(n);
    for (int i = n - 1; i >= 0; i--) {   // (the first on top, as AbsentMotion's Ranged lays its spots)
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
// A repeat laid on those before it, each copy of the new by each of the old, as AbsentMotion's RepeatCopies does it.
static std::vector<am::RepeatCopy> scatter_on(const std::vector<am::RepeatCopy>& made, const std::vector<am::RepeatCopy>& result) {
    std::vector<am::RepeatCopy> next;
    next.reserve(std::min<size_t>(25000, made.size() * result.size()));
    for (const am::RepeatCopy& m : made)
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
// As AbsentMotion's CopiesOf (styles.cpp) lays them: its layer's matrix where it stands (its turn and size the thing's
// own), each copy outer by the layer by local, seen from the layer's own place.
std::vector<AbsentCopy> absent_copies(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, float wide, float high, float atX, float atY, float reach) {
    std::vector<AbsentEffect> others, scatters;   // (Scatter Repeat is made above; the rest AbsentMotion makes)
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
// One of AbsentMotion's eases at u, its numbers as Alight Motion says them (easing.h: bounce, elastic, cyclic, random, step, elasticStep).
double absent_ease(const char* type, const double* p, int n, double u) {
    static const struct { const char* name; am::Easing::Type type; } kinds[] = {{"bounce", am::Easing::kBounce}, {"elastic", am::Easing::kElastic}, {"cyclic", am::Easing::kCyclic}, {"random", am::Easing::kRandom}, {"step", am::Easing::kStep}, {"elasticStep", am::Easing::kElasticStep}};
    am::Easing e;
    for (const auto& k : kinds) if (!std::strcmp(k.name, type)) e.type = k.type;
    for (int i = 0; i < n && i < 8; ++i) e.p[e.count++] = (float)p[i];
    return am::Ease(e, (float)u);
}
// As AbsentMotion's text.cpp Shown changes a text layer's words, its Choice and Seed as there (they lie in text.cpp
// with its Skia paragraphs, not built here): each text effect in its order, by textanim.cpp's own CountNumbers,
// FormatTimecode and Scramble. Text Randomizer's own characters are none here (a knob of words is not had): Scramble's own
// set then, as AbsentMotion's when none is typed.
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
bool absent_shutter(const std::vector<AbsentEffect>& effects, int64_t thing, double startMs, double endMs, double nowMs, int fps, double* open, bool* moves) {
    am::ShutterBlur blur;
    if (!am::ShutterBlurOf(absent_layer(effects, thing, startMs, endMs), nowMs, &blur)) return false;
    *open = blur.angle / 360.0 / std::max(1, fps), *moves = blur.position;   // (as DrawShuttered opens it: a frame's time times its angle)
    return true;
}

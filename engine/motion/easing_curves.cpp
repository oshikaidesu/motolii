#include "motion/easing_curves.h"

#include <strings.h>

#include <cmath>
#include <cstdio>
#include <sstream>
#include <string>

namespace {

// Returns the standard smoothstep of x between edge0 and edge1, clamped to 0..1.
// Returns a hard step at edge0 when the two edges are equal.
double interp_smoothstep(double edge0, double edge1, double x) {
    if (std::fabs(edge1 - edge0) < 2.220446049250313e-16) return x < edge0 ? 0.0 : 1.0;
    const double t = std::fmin(std::fmax((x - edge0) / (edge1 - edge0), 0.0), 1.0);
    return t * t * (3.0 - 2.0 * t);
}
// Bounce easing. p[0] is the length of the first bounce and p[1] the factor by which each
// following bounce shrinks. Returns the eased value for progress u.
//
// This matches Alight Motion (as implemented in AbsentMotion, absent_motion.cpp) except in one
// case. Alight Motion does not draw a bounce that would end after the span, however high it is,
// so the room left at the end of the span stays flat and the value looks stuck short of the
// target. Here a final, lower bounce is fitted into that room, so the value lands on the second
// keyframe. Its height scales with the room and grows from zero as the room grows.
//
// No other tool cuts a bounce short this way: Dan Ebberts' version runs past the second
// keyframe, and Penner's and GSAP's are fitted to the span. Fitting all bounces, as GSAP does,
// would lose the length parameter and the stillness of a bounce that has died away, so it is
// not done. With the default parameters less than 0.05 of room is left, so the result is
// identical to Alight Motion's.
double interp_bounce(const double* p, double u) {
    // Same as kMinBounce in easing.cpp. A bounce lower than this has died away and the value is
    // held still.
    const double lowest = 0.0055;
    double start = p[0] / 2, length = p[0] * p[1], height = p[1];
    for (int i = 0; i < 10000 && height >= lowest && start + length <= 1; ++i) start += length, length *= p[1], height *= p[1];
    const double room = 1 - start;
    if (!(p[0] > 0) || height < lowest || room <= 0.05 || u < start) return absent_ease("bounce", p, 2, u);
    const double high = height * room / length * interp_smoothstep(0.05, 0.15, room);
    return 1 - 4 * high * (u - start) * (1 - u) / (room * room);
}

// Returns one coordinate of a cubic Bezier curve from (0, 0) to (1, 1) with control values p1
// and p2, at curve parameter s.
double interp_sample(double p1, double p2, double s) { const double inv = 1.0 - s; return 3.0 * inv * inv * s * p1 + 3.0 * inv * s * s * p2 + s * s * s; }

}  // namespace

double interp_bezier(double x1, double y1, double x2, double y2, double x) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    double s = x;
    for (int i = 0; i < 8; ++i) {
        const double err = interp_sample(x1, x2, s) - x, inv = 1.0 - s, d = 3.0 * inv * inv * x1 + 6.0 * inv * s * (x2 - x1) + 3.0 * s * s * (1.0 - x2);
        if (std::fabs(err) < 1e-7) return interp_sample(y1, y2, s);
        if (std::fabs(d) < 1e-6) break;
        s -= err / d;
    }
    double lo = 0.0, hi = 1.0;
    s = interp_clamp(x, lo, hi);
    while (hi - lo > 1e-7) {
        if (interp_sample(x1, x2, s) < x) lo = s; else hi = s;
        s = (lo + hi) / 2.0;
    }
    return interp_sample(y1, y2, s);
}

double interp_ease(const Interp& i, double u) {
    const double* p = i.p;
    switch (i.kind) {
        case Interp::Hold: return 0.0;
        case Interp::Linear: return interp_clamp(u, 0.0, 1.0);
        case Interp::Bezier: return interp_bezier(interp_clamp(p[0], 0.0, 1.0), p[1], interp_clamp(p[2], 0.0, 1.0), p[3], u);
        case Interp::Bounce: return interp_bounce(p, u);
        case Interp::Elastic: return absent_ease("elastic", p, 4, u);
        case Interp::Cyclic: return absent_ease("cyclic", p, 5, u);
        case Interp::Random: return absent_ease("random", p, 6, u);
        case Interp::Steps: return absent_ease("step", p, 2, u);
        case Interp::ElasticSteps: return absent_ease("elasticStep", p, 2, u);
    }
    return u;
}

std::string interp_words(const Interp& is) {
    const auto& kind = interp_kinds[(size_t)is.kind];
    std::string said = kind.name;
    char one[40];
    for (int j = 0; j < kind.numbers; ++j) std::snprintf(one, sizeof one, " %.9g", is.p[j]), said += one;
    return said;
}

int interp_said(const std::string& text, Interp* is, std::string* why) {
    std::istringstream said(text);
    std::string name, more;
    said >> name;
    for (size_t k = 0; k < sizeof interp_kinds / sizeof *interp_kinds; ++k) {
        const auto& kind = interp_kinds[k];
        if (strcasecmp(name.c_str(), kind.name)) continue;
        Interp built;
        built.kind = (Interp::Kind)k;
        int n = 0;
        for (double one = 0; n < 8 && said >> one;) built.p[n++] = one;
        said.clear();
        const bool right = !(said >> more) && (n == 0 || n == kind.numbers);
        if (n == 0) for (int j = 0; j < 8; ++j) built.p[j] = kind.usual[j];
        const double* p = built.p;
        bool finite = true;
        for (int j = 0; j < kind.numbers; ++j) finite = finite && std::isfinite(p[j]);
        // The first violated rule, as a message. Empty if the count of parameters is wrong,
        // and null if no rule is violated. The rules are those of the earlier implementation.
        const char* rule = !right ? "" : !finite ? "every number is a real one"
            : built.kind == Interp::Bezier && (p[0] < 0.0 || p[0] > 1.0 || p[2] < 0.0 || p[2] > 1.0) ? "x1 and x2 are from 0 to 1"
            : built.kind == Interp::Bounce && p[0] <= 0.0 ? "first_dip is above 0"
            : (built.kind == Interp::Elastic && p[1] <= 0.0) || (built.kind == Interp::Cyclic && p[0] <= 0.0) ? "period is above 0"
            : (built.kind == Interp::Steps || built.kind == Interp::ElasticSteps) && p[0] <= 0.0 ? "width is above 0"
            : built.kind == Interp::Steps && p[1] < 0.0 ? "smooth is 0 or more" : nullptr;
        if (rule) {
            if (why) *why = std::string(kind.name) + (kind.numbers ? std::string(" is said alone or with its ") + std::to_string(kind.numbers) + " numbers (" + kind.names + ")" : " takes no numbers") + (*rule ? std::string(": ") + rule : "");
            return 1;
        }
        *is = built;
        return 0;
    }
    return -1;
}

#ifndef MOTOLII_MOTION_EASING_CURVES_H_
#define MOTOLII_MOTION_EASING_CURVES_H_

// Easing kinds: how a value moves between two keyframes.
//
// The nine kinds are those of Alight Motion (help center, "Animation Easing Curves":
// Cubic Bezier, Bounce, Elastic, Cyclic, Random, Steps, Elastic Steps, plus Hold and Linear).
// They were ported unchanged from an earlier Motolii implementation
// (rust_ae/Motolii, motolii/crates/motolii-doc/src/eval/track.rs and bezier.rs), keeping the
// same names, parameter order, formulas and rejected parameter values.
//
// interp_ease() takes u, the progress through the span between two keyframes (0 to 1), and
// returns how far the value has moved from the first keyframe's value to the second's. The
// result is 0 at the start and 1 at the end (Cyclic ends wherever its wave ends). In between
// it may overshoot the end and come back.

#include <cmath>
#include <string>

// One easing: a kind and its parameters.
struct Interp {
    enum Kind { Hold, Linear, Bezier, Bounce, Elastic, Cyclic, Random, Steps, ElasticSteps } kind = Linear;
    // Parameters, in the order given by the names in interp_kinds.
    double p[8] = {0, 0, 0, 0, 0, 0, 0, 0};
};
// Describes each kind, indexed by Interp::Kind.
//
// name: the kind's name. numbers: how many parameters it has. names: the parameter names,
// separated by spaces. usual: the default parameters, used when none are given. lo and hi: the
// range the editor allows for each parameter. The values come from the earlier implementation
// (rust_ae/Motolii, motolii/ui/native/src/editor/ease_kinds.rs, which also has the handle
// limits used for lo and hi).
inline const struct { const char* name; int numbers; const char* names; double usual[8], lo[8], hi[8]; } interp_kinds[] = {
    {"Hold", 0, "", {}, {}, {}},
    {"Linear", 0, "", {}, {}, {}},
    {"Bezier", 4, "x1 y1 x2 y2", {0.42, 0.0, 0.58, 1.0}, {0, -0.4, 0, -0.4}, {1, 1.6, 1, 1.6}},
    // Bounce: the defaults match AbsentMotion's Alight Motion preset (Keyframes.kt) and run
    // through absent_ease() in its easing.cpp.
    {"Bounce", 2, "length bounce", {0.3, 0.8}, {0.01, 0}, {1, 1}},
    // Elastic: AbsentMotion's easing.cpp reads only a, c and d.
    {"Elastic", 4, "a b c d", {0.25, 1, 0.5, 1}, {0, 0, 0, 0}, {1, 2, 2, 2}},
    // Cyclic: the defaults match AbsentMotion's.
    {"Cyclic", 5, "a b c d e", {2.0 / 7.0, 0, 0.5, 0, 0}, {0.01, 0, 0, 0, 0}, {1, 1, 1, 1, 1}},
    // Random: the defaults match AbsentMotion's.
    {"Random", 6, "a b c d e f", {0.5, 0.5, 0.5, 0.5, 0.5, 0}, {0, 0, 0, 0, 0, 0}, {1, 1, 1, 1, 1, 1}},
    // Steps: the default length of 0.25 gives four steps, the last reaching 1 at the end, as in
    // Alight Motion (screenshot 135 in docs/design/alight_motion_ui.md). The earlier
    // implementation's 0.178 gave six steps.
    {"Steps", 2, "length smoothing", {0.25, 0.0}, {0.02, 0}, {1, 1}},
    // ElasticSteps: the defaults match AbsentMotion's.
    {"ElasticSteps", 2, "length magnitude", {0.2, 0.5}, {0.05, 0}, {1, 1}},
};

// Clamps x to the range low..high.
inline double interp_clamp(double x, double low, double high) { return std::fmin(std::fmax(x, low), high); }

// Cubic Bezier easing, as in CSS: the curve has control points (x1, y1) and (x2, y2). Returns y
// for the given x. To find the curve parameter for x it runs eight Newton iterations and falls
// back to bisection. This is the solver of the earlier implementation (bezier.rs) that its newer
// solver was checked against.
double interp_bezier(double x1, double y1, double x2, double y2, double x);

// Returns the eased value for progress u using easing i. Hold always returns 0, so the value
// stays at the first keyframe's value until the second keyframe.
double interp_ease(const Interp& i, double u);

// Formats an easing as text: the kind's name as in interp_kinds, followed by all its
// parameters. interp_said() reads this text back to the same easing.
std::string interp_words(const Interp& is);

// Parses an easing from text: a kind name, in any letter case, followed by either no parameters
// (the defaults are used) or all of them. Returns 0 and fills *is on success. Returns -1 if the
// text does not start with a kind name. Returns 1 if the kind is known but the parameters are
// wrong, and then fills *why, when given, with a description of the accepted form.
int interp_said(const std::string& text, Interp* is, std::string* why = nullptr);

#endif  // MOTOLII_MOTION_EASING_CURVES_H_

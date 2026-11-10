#ifndef MOTOLII_MOTION_EASING_NAMES_H_
#define MOTOLII_MOTION_EASING_NAMES_H_

// Named easings that use Cavalry's Magic Easing names.
//
// Each entry is an expression of u, the progress through the span between two
// keyframes (0 to 1), and evaluates to how far the value has moved (0 at the
// start, 1 at the end). The same table is used by keyframe evaluation
// (evaluated by SQLite) and by the script function ease(name, u) (script.cpp,
// evaluated as JavaScript), so the two cannot drift apart. Expressions may only
// use functions that both SQLite and JavaScript provide here: pow, exp, cos,
// abs and pi().

inline const struct {
  const char* name;
  const char* goes;
} named_ways[] = {
    {"SlowIn", "pow(u, 3)"},
    {"SlowOut", "1 - pow(1 - u, 3)"},
    {"SlowInSlowOut", "u * u * u * (u * (6 * u - 15) + 10)"},
    {"VerySlowIn", "pow(u, 5)"},
    {"VerySlowOut", "1 - pow(1 - u, 5)"},
    {"SpringOut", "1 - exp(-5 * u) * cos(3 * pi() * u) * (1 - u)"},
    {"SmallSpringOut", "1 - exp(-7 * u) * cos(2 * pi() * u) * (1 - u)"},
    {"BounceOut", "1 - abs(cos(3.5 * pi() * u)) * pow(1 - u, 2)"},
    {"Overshoot", "1 + 2.70158 * pow(u - 1, 3) + 1.70158 * pow(u - 1, 2)"},
};

#endif  // MOTOLII_MOTION_EASING_NAMES_H_

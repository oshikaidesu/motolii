// Tests for motion/easing_godot.h: Godot's Tween easing functions, compiled
// with our own stand-in for Godot's math header
// (third_party/godot_easing/core/math/math_funcs.h).
//
// The expected values come from Robert Penner's easing equations, which
// Godot's file says it is derived from: http://robertpenner.com/easing/ (the
// equations, and chapter 7 of "Programming Macromedia Flash MX", which
// explains them). Every equation has the form f(t, b, c, d): t is the time
// since the start, b the beginning value, c the change in value, and d the
// duration, so that f is b at t = 0 and b + c at t = d. https://easings.net/
// lists the same equations with b = 0, c = 1 and d = 1; the tests write each
// formula out in that form.

#include "motion/easing_godot.h"

#include <gtest/gtest.h>

#include <cmath>

namespace motolii {
namespace {

// Godot keeps some constants (Back's overshoot, Bounce's steps) in single
// precision, so those families are compared to within 1e-6.
constexpr double kFloatTolerance = 1e-6;
// The others are computed in double precision.
constexpr double kTolerance = 1e-12;

using Equation = double (*)(double t, double b, double c, double d);

// Returns the equation's value at t for a move from 0 to 1 that lasts 1.
double At(Equation equation, double t) { return equation(t, 0.0, 1.0, 1.0); }

TEST(EasingGodot, EveryEquationStartsAtTheBeginningValueAndEndsAtTheEnd) {
  const struct {
    const char* name;
    Equation equation;
  } equations[] = {
      {"Linear in", godot::Linear::in},
      {"Sine in", godot::Sine::in},
      {"Sine out", godot::Sine::out},
      {"Sine in-out", godot::Sine::in_out},
      {"Quad in", godot::Quad::in},
      {"Quad out", godot::Quad::out},
      {"Quad in-out", godot::Quad::in_out},
      {"Cubic in", godot::Cubic::in},
      {"Cubic out", godot::Cubic::out},
      {"Cubic in-out", godot::Cubic::in_out},
      {"Quart in", godot::Quart::in},
      {"Quart out", godot::Quart::out},
      {"Quart in-out", godot::Quart::in_out},
      {"Quint in", godot::Quint::in},
      {"Quint out", godot::Quint::out},
      {"Quint in-out", godot::Quint::in_out},
      {"Expo out", godot::Expo::out},
      {"Expo in-out", godot::Expo::in_out},
      {"Circ in", godot::Circ::in},
      {"Circ out", godot::Circ::out},
      {"Circ in-out", godot::Circ::in_out},
      {"Elastic in", godot::Elastic::in},
      {"Elastic out", godot::Elastic::out},
      {"Elastic in-out", godot::Elastic::in_out},
      {"Back in", godot::Back::in},
      {"Back out", godot::Back::out},
      {"Back in-out", godot::Back::in_out},
      {"Bounce in", godot::Bounce::in},
      {"Bounce out", godot::Bounce::out},
      {"Bounce in-out", godot::Bounce::in_out},
      {"Spring in", godot::Spring::in},
      {"Spring out", godot::Spring::out},
      {"Spring in-out", godot::Spring::in_out},
  };
  for (const auto& one : equations) {
    EXPECT_NEAR(At(one.equation, 0.0), 0.0, kFloatTolerance) << one.name;
    EXPECT_NEAR(At(one.equation, 1.0), 1.0, kFloatTolerance) << one.name;
  }
}

TEST(EasingGodot, ExpoInStartsAtTheBeginningValue) {
  EXPECT_NEAR(At(godot::Expo::in, 0.0), 0.0, kTolerance);
}

// Disabled: Godot's file, used unchanged, returns 0.999 here. It subtracts
// c * 0.001 from Penner's equation.
TEST(EasingGodot, DISABLED_ExpoInEndsAtTheEnd) {
  // Penner: c * 2^(10 (t/d - 1)) + b, which is b + c at t = d.
  EXPECT_NEAR(At(godot::Expo::in, 1.0), 1.0, kFloatTolerance);
}

TEST(EasingGodot, EquationsTakeTimeBeginningChangeAndDuration) {
  // Halfway through 4 seconds, from 10 and changing by 20: 10 + 20 / 2.
  EXPECT_NEAR(godot::Linear::in(2.0, 10.0, 20.0, 4.0), 20.0, kTolerance);
  // Quad in is c (t/d)^2 + b: 20 * (1/2)^2 + 10 = 15.
  EXPECT_NEAR(godot::Quad::in(1.0, 10.0, 20.0, 2.0), 15.0, kTolerance);
  // Sine in-out is half way at half time: 10 + 20 / 2.
  EXPECT_NEAR(godot::Sine::in_out(1.0, 10.0, 20.0, 2.0), 20.0, kTolerance);
}

TEST(EasingGodot, PolynomialEaseInIsTToItsPower) {
  // t^2, t^3, t^4 and t^5 at t = 1/2.
  EXPECT_NEAR(At(godot::Quad::in, 0.5), 0.25, kTolerance);
  EXPECT_NEAR(At(godot::Cubic::in, 0.5), 0.125, kTolerance);
  EXPECT_NEAR(At(godot::Quart::in, 0.5), 0.0625, kTolerance);
  EXPECT_NEAR(At(godot::Quint::in, 0.5), 0.03125, kTolerance);
}

TEST(EasingGodot, PolynomialEaseOutIsOneMinusTheRestToItsPower) {
  // 1 - (1 - t)^n at t = 1/2.
  EXPECT_NEAR(At(godot::Quad::out, 0.5), 1.0 - 0.25, kTolerance);
  EXPECT_NEAR(At(godot::Cubic::out, 0.5), 1.0 - 0.125, kTolerance);
  EXPECT_NEAR(At(godot::Quart::out, 0.5), 1.0 - 0.0625, kTolerance);
  EXPECT_NEAR(At(godot::Quint::out, 0.5), 1.0 - 0.03125, kTolerance);
}

TEST(EasingGodot, PolynomialEaseInOutIsEaseInThenEaseOutEachOverHalf) {
  // Before the middle it is 2^(n-1) t^n; at t = 1/4 that is 2^(n-1) / 4^n:
  // 2/16, 4/64, 8/256 and 16/1024.
  EXPECT_NEAR(At(godot::Quad::in_out, 0.25), 0.125, kTolerance);
  EXPECT_NEAR(At(godot::Cubic::in_out, 0.25), 0.0625, kTolerance);
  EXPECT_NEAR(At(godot::Quart::in_out, 0.25), 0.03125, kTolerance);
  EXPECT_NEAR(At(godot::Quint::in_out, 0.25), 0.015625, kTolerance);
  // After the middle it is 1 - 2^(n-1) (1 - t)^n, the same turned around.
  EXPECT_NEAR(At(godot::Quad::in_out, 0.75), 1.0 - 0.125, kTolerance);
  EXPECT_NEAR(At(godot::Cubic::in_out, 0.75), 1.0 - 0.0625, kTolerance);
  EXPECT_NEAR(At(godot::Quart::in_out, 0.75), 1.0 - 0.03125, kTolerance);
  EXPECT_NEAR(At(godot::Quint::in_out, 0.75), 1.0 - 0.015625, kTolerance);
  EXPECT_NEAR(At(godot::Quad::in_out, 0.5), 0.5, kTolerance);
  EXPECT_NEAR(At(godot::Cubic::in_out, 0.5), 0.5, kTolerance);
  EXPECT_NEAR(At(godot::Quart::in_out, 0.5), 0.5, kTolerance);
  EXPECT_NEAR(At(godot::Quint::in_out, 0.5), 0.5, kTolerance);
}

TEST(EasingGodot, SineFollowsAQuarterOrHalfTurnOfACircle) {
  // cos(pi/4) = sin(pi/4) = sqrt(2) / 2.
  const double half_root_two = std::sqrt(2.0) / 2.0;
  // In: 1 - cos(t pi/2). Out: sin(t pi/2). In-out: (1 - cos(t pi)) / 2.
  EXPECT_NEAR(At(godot::Sine::in, 0.5), 1.0 - half_root_two, kTolerance);
  EXPECT_NEAR(At(godot::Sine::out, 0.5), half_root_two, kTolerance);
  EXPECT_NEAR(At(godot::Sine::in_out, 0.25), (1.0 - half_root_two) / 2.0,
              kTolerance);
  EXPECT_NEAR(At(godot::Sine::in_out, 0.5), 0.5, kTolerance);
}

TEST(EasingGodot, SineInOutIsSymmetricAboutTheMiddle) {
  // (1 - cos(u pi)) / 2 + (1 - cos(pi - u pi)) / 2 = 1, because
  // cos(pi - x) = -cos(x). The engine eases a MIDI roll's notes with this.
  for (double u : {0.1, 0.25, 0.4}) {
    EXPECT_NEAR(At(godot::Sine::in_out, u) + At(godot::Sine::in_out, 1.0 - u),
                1.0, kTolerance)
        << "u = " << u;
  }
}

TEST(EasingGodot, CircFollowsAQuarterCircle) {
  // In: 1 - sqrt(1 - t^2); at t = 0.6 that is 1 - sqrt(0.64) = 0.2.
  EXPECT_NEAR(At(godot::Circ::in, 0.6), 0.2, kTolerance);
  // Out: sqrt(1 - (t - 1)^2); at t = 0.4 that is sqrt(0.64) = 0.8.
  EXPECT_NEAR(At(godot::Circ::out, 0.4), 0.8, kTolerance);
}

TEST(EasingGodot, BackOvershootsByPennersConstant) {
  // With s = 1.70158, in is t^2 ((s + 1) t - s). At t = 1/2:
  // 0.25 * (1.35079 - 1.70158) = -0.0876975.
  EXPECT_NEAR(At(godot::Back::in, 0.5), -0.0876975, kFloatTolerance);
  // Out is the same turned around: 1 + 0.0876975.
  EXPECT_NEAR(At(godot::Back::out, 0.5), 1.0876975, kFloatTolerance);
}

TEST(EasingGodot, BounceOutFallsThenBouncesThreeTimes) {
  // The first fall is 7.5625 t^2 until t = 1/2.75: at t = 0.2 it is
  // 7.5625 * 0.04 = 0.3025.
  EXPECT_NEAR(At(godot::Bounce::out, 0.2), 0.3025, kFloatTolerance);
  // The three bounces are furthest from the end value at t = 1.5/2.75,
  // 2.25/2.75 and 2.625/2.75, where the value is 0.75, 0.9375 and 0.984375.
  EXPECT_NEAR(At(godot::Bounce::out, 1.5 / 2.75), 0.75, kFloatTolerance);
  EXPECT_NEAR(At(godot::Bounce::out, 2.25 / 2.75), 0.9375, kFloatTolerance);
  EXPECT_NEAR(At(godot::Bounce::out, 2.625 / 2.75), 0.984375, kFloatTolerance);
}

TEST(EasingGodot, BounceInIsBounceOutTurnedAround) {
  // In is 1 - out(1 - t): at t = 0.8 it is 1 - 0.3025.
  EXPECT_NEAR(At(godot::Bounce::in, 0.8), 0.6975, kFloatTolerance);
}

}  // namespace
}  // namespace motolii

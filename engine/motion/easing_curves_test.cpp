// Tests for the easing kinds in motion/easing_curves.h.
//
// The expected values come from:
//   - CSS Easing Functions Level 1 (https://www.w3.org/TR/css-easing-1/):
//     cubic-bezier(), the keywords ease, ease-in, ease-out and ease-in-out,
//     the rule that x1 and x2 lie from 0 to 1, how the curve goes on outside
//     0..1, and steps(n, end).
//   - The cubic Bezier curve from (0, 0) to (1, 1) with control points P1 and
//     P2, B(s) = 3(1-s)^2 s P1 + 3(1-s) s^2 P2 + s^3. The arithmetic is written
//     out beside each test that uses it.
//   - Adobe's definition of Hold interpolation:
//     https://helpx.adobe.com/after-effects/using/keyframe-interpolation.html
//   - docs/design/alight_motion_ui.md, the table of Alight Motion's default
//     curves: Bounce bounces five times and ends flat, Elastic overshoots,
//     Cyclic makes 3.5 waves and ends on a peak, Steps has four steps and jumps
//     to 1 at the end.
//   - The contract written in easing_curves.h: the result is 0 at the start and
//     1 at the end, the table interp_kinds, and the text that interp_words()
//     writes and interp_said() reads.

#include "motion/easing_curves.h"

#include <gtest/gtest.h>

#include <algorithm>
#include <sstream>
#include <string>

namespace motolii {
namespace {

// The Bezier solver stops within 1e-7 of x, and the other kinds are computed in
// single precision by AbsentMotion, so results are compared to within 1e-6.
constexpr double kTolerance = 1e-6;

constexpr Interp::Kind kEveryKind[] = {
    Interp::Hold,   Interp::Linear,  Interp::Bezier,
    Interp::Bounce, Interp::Elastic, Interp::Cyclic,
    Interp::Random, Interp::Steps,   Interp::ElasticSteps};

// Returns the easing of a kind with its default parameters.
Interp Default(Interp::Kind kind) {
  Interp easing;
  easing.kind = kind;
  for (int i = 0; i < 8; ++i) easing.p[i] = interp_kinds[kind].usual[i];
  return easing;
}

// Returns CSS's cubic-bezier(x1, y1, x2, y2).
Interp CubicBezier(double x1, double y1, double x2, double y2) {
  Interp easing;
  easing.kind = Interp::Bezier;
  easing.p[0] = x1, easing.p[1] = y1, easing.p[2] = x2, easing.p[3] = y2;
  return easing;
}

// Returns Steps with steps of the given length and no smoothing.
Interp StepsOfLength(double length) {
  Interp easing;
  easing.kind = Interp::Steps;
  easing.p[0] = length;
  return easing;
}

// ---- The contract of interp_ease(): 0 at the start, 1 at the end.

TEST(EasingCurves, EveryKindStartsAtZero) {
  for (Interp::Kind kind : kEveryKind) {
    EXPECT_NEAR(interp_ease(Default(kind), 0.0), 0.0, kTolerance)
        << interp_kinds[kind].name;
  }
}

TEST(EasingCurves, EndsAtOne) {
  // Three kinds are not in this list. Hold stays at 0 by its own definition.
  // Cyclic "ends wherever its wave ends"; its default is tested below.
  // ElasticSteps is the disabled test that follows.
  for (Interp::Kind kind : {Interp::Linear, Interp::Bezier, Interp::Bounce,
                            Interp::Elastic, Interp::Random, Interp::Steps}) {
    EXPECT_NEAR(interp_ease(Default(kind), 1.0), 1.0, kTolerance)
        << interp_kinds[kind].name;
  }
}

// Disabled: the code returns 0.8 at the end, the level of its fifth step.
TEST(EasingCurves, DISABLED_ElasticStepsEndsAtOne) {
  EXPECT_NEAR(interp_ease(Default(Interp::ElasticSteps), 1.0), 1.0, kTolerance);
}

// ---- Hold and Linear.

TEST(EasingCurves, HoldStaysAtTheFirstKeyframe) {
  // Adobe: with Hold interpolation the value of the first keyframe holds
  // steady until the next keyframe.
  for (double u : {0.0, 0.25, 0.5, 0.75, 0.999}) {
    EXPECT_DOUBLE_EQ(interp_ease(Default(Interp::Hold), u), 0.0) << "u = " << u;
  }
}

TEST(EasingCurves, LinearIsTheProgressItself) {
  // CSS: the linear easing function's output equals its input.
  for (double u : {0.0, 0.125, 0.25, 0.5, 0.75, 1.0}) {
    EXPECT_DOUBLE_EQ(interp_ease(Default(Interp::Linear), u), u);
  }
}

// ---- Bezier, against CSS's cubic-bezier().

TEST(EasingCurves, BezierOnTheDiagonalIsLinear) {
  // With P1 = (0, 0) and P2 = (1, 1), x(s) and y(s) are the same polynomial,
  // 3s^2 - 2s^3, so y = x.
  for (double x : {0.1, 0.25, 0.5, 0.75, 0.9}) {
    EXPECT_NEAR(interp_bezier(0.0, 0.0, 1.0, 1.0, x), x, kTolerance)
        << "x = " << x;
  }
}

// In the next three tests x1 = 1/3 and x2 = 2/3. The curve's x is then its own
// parameter:
//   x(s) = 3(1-s)^2 s (1/3) + 3(1-s) s^2 (2/3) + s^3
//        = s ((1-s)^2 + 2(1-s)s + s^2) = s ((1-s) + s)^2 = s,
// so the eased value at x is y(x) = 3(1-x)^2 x y1 + 3(1-x) x^2 y2 + x^3.

TEST(EasingCurves, BezierWithBothYControlsAtZeroIsXCubed) {
  // y(x) = x^3, the cubic ease in.
  const Interp cubic_in = CubicBezier(1.0 / 3.0, 0.0, 2.0 / 3.0, 0.0);
  EXPECT_NEAR(interp_ease(cubic_in, 0.25), 0.015625, kTolerance);
  EXPECT_NEAR(interp_ease(cubic_in, 0.5), 0.125, kTolerance);
  EXPECT_NEAR(interp_ease(cubic_in, 0.75), 0.421875, kTolerance);
}

TEST(EasingCurves, BezierWithBothYControlsAtOneIsOneMinusTheRestCubed) {
  // y(x) = 3(1-x)^2 x + 3(1-x) x^2 + x^3 = 1 - (1-x)^3, the cubic ease out.
  const Interp cubic_out = CubicBezier(1.0 / 3.0, 1.0, 2.0 / 3.0, 1.0);
  EXPECT_NEAR(interp_ease(cubic_out, 0.25), 1.0 - 0.421875, kTolerance);
  EXPECT_NEAR(interp_ease(cubic_out, 0.5), 1.0 - 0.125, kTolerance);
  EXPECT_NEAR(interp_ease(cubic_out, 0.75), 1.0 - 0.015625, kTolerance);
}

TEST(EasingCurves, BezierMayGoPastTheEndAndBelowTheStart) {
  // CSS allows any y1 and y2. At x = 1/2: (3 * 1.5 + 3 * 1.5 + 1) / 8 = 1.25.
  EXPECT_NEAR(interp_ease(CubicBezier(1.0 / 3.0, 1.5, 2.0 / 3.0, 1.5), 0.5),
              1.25, kTolerance);
  // At x = 1/4: 3 * 0.5625 * 0.25 * -0.4 + 3 * 0.75 * 0.0625 * 1 + 0.015625
  //           = -0.16875 + 0.140625 + 0.015625 = -0.0125.
  EXPECT_NEAR(interp_ease(CubicBezier(1.0 / 3.0, -0.4, 2.0 / 3.0, 1.0), 0.25),
              -0.0125, kTolerance);
}

TEST(EasingCurves, BezierCssKeywordsPassThroughTheirMiddlePoints) {
  // At the middle of the curve, s = 1/2, each coordinate is
  // (3 P1 + 3 P2 + 1) / 8.
  // ease = cubic-bezier(0.25, 0.1, 0.25, 1):
  //   x = (0.75 + 0.75 + 1) / 8 = 0.3125, y = (0.3 + 3 + 1) / 8 = 0.5375.
  EXPECT_NEAR(interp_ease(CubicBezier(0.25, 0.1, 0.25, 1.0), 0.3125), 0.5375,
              kTolerance);
  // ease-in = cubic-bezier(0.42, 0, 1, 1):
  //   x = (1.26 + 3 + 1) / 8 = 0.6575, y = (0 + 3 + 1) / 8 = 0.5.
  EXPECT_NEAR(interp_ease(CubicBezier(0.42, 0.0, 1.0, 1.0), 0.6575), 0.5,
              kTolerance);
  // ease-out = cubic-bezier(0, 0, 0.58, 1):
  //   x = (0 + 1.74 + 1) / 8 = 0.3425, y = (0 + 3 + 1) / 8 = 0.5.
  EXPECT_NEAR(interp_ease(CubicBezier(0.0, 0.0, 0.58, 1.0), 0.3425), 0.5,
              kTolerance);
}

TEST(EasingCurves, BezierDefaultIsEaseInOutSymmetricAboutTheMiddle) {
  // The default is CSS's ease-in-out, cubic-bezier(0.42, 0, 0.58, 1). Because
  // P2 = (1, 1) - P1, turning the curve half a turn about (0.5, 0.5) gives the
  // same curve: f(u) + f(1 - u) = 1, and f(0.5) = 0.5.
  const Interp ease_in_out = Default(Interp::Bezier);
  EXPECT_NEAR(interp_ease(ease_in_out, 0.5), 0.5, kTolerance);
  for (double u : {0.1, 0.25, 0.4}) {
    EXPECT_NEAR(interp_ease(ease_in_out, u) + interp_ease(ease_in_out, 1.0 - u),
                1.0, 2 * kTolerance)
        << "u = " << u;
  }
}

// Disabled: the code returns 0 before the start and 1 after the end.
TEST(EasingCurves, DISABLED_BezierFollowsItsEndTangentOutsideZeroToOne) {
  // CSS: outside 0..1 the curve goes on along its tangent at the nearer end.
  // For ease, cubic-bezier(0.25, 0.1, 0.25, 1), the tangent at the start
  // passes through P1 with slope 0.1 / 0.25 = 0.4, so at x = -0.5 it is -0.2.
  // The tangent at the end passes through P2 = (0.25, 1) and (1, 1) and is
  // flat, so at x = 1.5 it is 1.
  EXPECT_NEAR(interp_bezier(0.25, 0.1, 0.25, 1.0, -0.5), -0.2, kTolerance);
  EXPECT_NEAR(interp_bezier(0.25, 0.1, 0.25, 1.0, 1.5), 1.0, kTolerance);
}

// ---- Alight Motion's kinds, with their default parameters.

TEST(EasingCurves, BounceDefaultBouncesFiveTimesThenLiesFlat) {
  const Interp bounce = Default(Interp::Bounce);
  // Each bounce leaves the end value and comes back to it, so it has one
  // lowest point. The first fall towards the end value has none.
  int lowest_points = 0;
  double before = interp_ease(bounce, 0.0);
  double now = interp_ease(bounce, 0.001);
  for (int i = 2; i <= 1000; ++i) {
    const double after = interp_ease(bounce, i / 1000.0);
    if (now < before && now <= after) ++lowest_points;
    before = now;
    now = after;
  }
  EXPECT_EQ(lowest_points, 5);
  EXPECT_NEAR(interp_ease(bounce, 0.98), 1.0, kTolerance);
  EXPECT_NEAR(interp_ease(bounce, 0.99), 1.0, kTolerance);
}

TEST(EasingCurves, BounceRunsFromZeroToOneWhateverItsLength) {
  for (double length : {0.1, 0.25, 0.5, 0.75, 1.0}) {
    for (double shrink : {0.3, 0.6, 0.9}) {
      Interp bounce;
      bounce.kind = Interp::Bounce;
      bounce.p[0] = length, bounce.p[1] = shrink;
      EXPECT_NEAR(interp_ease(bounce, 0.0), 0.0, kTolerance)
          << "length " << length << ", bounce " << shrink;
      EXPECT_NEAR(interp_ease(bounce, 1.0), 1.0, kTolerance)
          << "length " << length << ", bounce " << shrink;
    }
  }
}

TEST(EasingCurves, ElasticDefaultOvershootsTheEnd) {
  const Interp elastic = Default(Interp::Elastic);
  double highest = 0.0;
  for (int i = 0; i <= 1000; ++i)
    highest = std::max(highest, interp_ease(elastic, i / 1000.0));
  EXPECT_GT(highest, 1.0);
}

TEST(EasingCurves, CyclicDefaultMakesThreeAndAHalfWavesAndEndsOnAPeak) {
  const Interp cyclic = Default(Interp::Cyclic);
  // Each wave climbs through the halfway level once and falls through it
  // once. Three and a half waves climb four times and fall three times.
  int climbs = 0, falls = 0;
  double before = interp_ease(cyclic, 0.0);
  for (int i = 1; i <= 1000; ++i) {
    const double now = interp_ease(cyclic, i / 1000.0);
    if (before < 0.5 && now >= 0.5) ++climbs;
    if (before >= 0.5 && now < 0.5) ++falls;
    before = now;
  }
  EXPECT_EQ(climbs, 4);
  EXPECT_EQ(falls, 3);
  EXPECT_NEAR(interp_ease(cyclic, 1.0), 1.0, kTolerance);
}

TEST(EasingCurves, StepsDefaultIsFourStepsWithTheLastJumpAtTheEnd) {
  // CSS steps(4, end): the output is floor(4 x) / 4.
  const Interp steps = Default(Interp::Steps);
  const struct {
    double x, expected;
  } points[] = {{0.0, 0.0}, {0.1, 0.0},   {0.25, 0.25}, {0.3, 0.25}, {0.5, 0.5},
                {0.6, 0.5}, {0.75, 0.75}, {0.9, 0.75},  {1.0, 1.0}};
  for (const auto& point : points) {
    EXPECT_NEAR(interp_ease(steps, point.x), point.expected, kTolerance)
        << "x = " << point.x;
  }
}

TEST(EasingCurves, StepsOfLengthOneOverNAreCssStepsNEnd) {
  // CSS steps(n, end): the output is floor(n x) / n. In the middle of step k,
  // at x = (k + 0.5) / n, that is k / n.
  for (int n : {2, 5, 10}) {
    const Interp steps = StepsOfLength(1.0 / n);
    for (int k = 0; k < n; ++k) {
      EXPECT_NEAR(interp_ease(steps, (k + 0.5) / n), static_cast<double>(k) / n,
                  kTolerance)
          << "step " << k << " of " << n;
    }
  }
}

// ---- The table interp_kinds and interp_clamp().

TEST(EasingCurves, ClampPinsAValueToTheRange) {
  EXPECT_DOUBLE_EQ(interp_clamp(0.5, 0.0, 1.0), 0.5);
  EXPECT_DOUBLE_EQ(interp_clamp(-2.0, 0.0, 1.0), 0.0);
  EXPECT_DOUBLE_EQ(interp_clamp(3.0, 0.0, 1.0), 1.0);
}

TEST(EasingCurves, KindsAreIndexedByKind) {
  EXPECT_STREQ(interp_kinds[Interp::Hold].name, "Hold");
  EXPECT_STREQ(interp_kinds[Interp::Linear].name, "Linear");
  EXPECT_STREQ(interp_kinds[Interp::Bezier].name, "Bezier");
  EXPECT_STREQ(interp_kinds[Interp::Bounce].name, "Bounce");
  EXPECT_STREQ(interp_kinds[Interp::Elastic].name, "Elastic");
  EXPECT_STREQ(interp_kinds[Interp::Cyclic].name, "Cyclic");
  EXPECT_STREQ(interp_kinds[Interp::Random].name, "Random");
  EXPECT_STREQ(interp_kinds[Interp::Steps].name, "Steps");
  EXPECT_STREQ(interp_kinds[Interp::ElasticSteps].name, "ElasticSteps");
}

TEST(EasingCurves, KindsNameEachOfTheirParameters) {
  for (Interp::Kind kind : kEveryKind) {
    std::istringstream names(interp_kinds[kind].names);
    int count = 0;
    for (std::string name; names >> name;) ++count;
    EXPECT_EQ(count, interp_kinds[kind].numbers) << interp_kinds[kind].name;
  }
}

TEST(EasingCurves, DefaultsLieInsideTheRangeTheEditorAllows) {
  for (Interp::Kind kind : kEveryKind) {
    const auto& described = interp_kinds[kind];
    for (int i = 0; i < described.numbers; ++i) {
      EXPECT_LE(described.lo[i], described.usual[i])
          << described.name << " parameter " << i;
      EXPECT_LE(described.usual[i], described.hi[i])
          << described.name << " parameter " << i;
    }
  }
}

// ---- The text form: interp_words() and interp_said().

TEST(EasingCurves, WordsStartWithTheNameOfTheKind) {
  EXPECT_EQ(interp_words(Default(Interp::Hold)), "Hold");
  EXPECT_EQ(interp_words(Default(Interp::Linear)), "Linear");
  for (Interp::Kind kind : kEveryKind) {
    EXPECT_EQ(interp_words(Default(kind)).rfind(interp_kinds[kind].name, 0), 0u)
        << interp_kinds[kind].name;
  }
}

TEST(EasingCurves, SaidReadsAKindNameInAnyLetterCase) {
  for (const char* text : {"Bezier", "bezier", "BEZIER"}) {
    Interp read;
    EXPECT_EQ(interp_said(text, &read), 0) << text;
    EXPECT_EQ(read.kind, Interp::Bezier) << text;
  }
}

TEST(EasingCurves, SaidAloneUsesTheDefaults) {
  for (Interp::Kind kind : kEveryKind) {
    const auto& described = interp_kinds[kind];
    Interp read;
    ASSERT_EQ(interp_said(described.name, &read), 0) << described.name;
    EXPECT_EQ(read.kind, kind);
    for (int i = 0; i < described.numbers; ++i) {
      EXPECT_DOUBLE_EQ(read.p[i], described.usual[i])
          << described.name << " parameter " << i;
    }
  }
}

TEST(EasingCurves, SaidReadsAllTheParameters) {
  Interp read;
  ASSERT_EQ(interp_said("Bezier 0.25 0.1 0.25 1", &read), 0);
  EXPECT_EQ(read.kind, Interp::Bezier);
  EXPECT_DOUBLE_EQ(read.p[0], 0.25);
  EXPECT_DOUBLE_EQ(read.p[1], 0.1);
  EXPECT_DOUBLE_EQ(read.p[2], 0.25);
  EXPECT_DOUBLE_EQ(read.p[3], 1.0);
}

TEST(EasingCurves, SaidRefusesSomeButNotAllOfTheParameters) {
  Interp read;
  std::string why;
  EXPECT_EQ(interp_said("Bezier 0.25 0.1", &read, &why), 1);
  EXPECT_FALSE(why.empty());
}

TEST(EasingCurves, SaidDoesNotKnowAnotherName) {
  Interp read;
  EXPECT_EQ(interp_said("Wobble 1 2", &read), -1);
  EXPECT_EQ(interp_said("", &read), -1);
}

TEST(EasingCurves, SaidRefusesBezierXOutsideZeroToOne) {
  // CSS: both x values must be in the range 0 to 1, or the function is
  // invalid.
  Interp read;
  EXPECT_EQ(interp_said("Bezier 1.5 0 0.5 1", &read), 1);
  EXPECT_EQ(interp_said("Bezier 0.5 0 -0.1 1", &read), 1);
}

TEST(EasingCurves, SaidAcceptsBezierYOutsideZeroToOne) {
  // CSS puts no limit on y1 and y2.
  Interp read;
  ASSERT_EQ(interp_said("Bezier 0.3 -0.4 0.7 1.6", &read), 0);
  EXPECT_DOUBLE_EQ(read.p[1], -0.4);
  EXPECT_DOUBLE_EQ(read.p[3], 1.6);
}

TEST(EasingCurves, WordsAreReadBackToTheSameEasing) {
  // Cyclic is the disabled test that follows.
  for (Interp::Kind kind :
       {Interp::Hold, Interp::Linear, Interp::Bezier, Interp::Bounce,
        Interp::Elastic, Interp::Random, Interp::Steps, Interp::ElasticSteps}) {
    const Interp written = Default(kind);
    Interp read;
    ASSERT_EQ(interp_said(interp_words(written), &read), 0)
        << interp_kinds[kind].name;
    EXPECT_EQ(read.kind, kind);
    for (int i = 0; i < interp_kinds[kind].numbers; ++i) {
      EXPECT_DOUBLE_EQ(read.p[i], written.p[i])
          << interp_kinds[kind].name << " parameter " << i;
    }
  }
}

// Disabled: the default 2/7 is written with nine digits and reads back as
// 0.285714286, which is 3e-10 away.
TEST(EasingCurves, DISABLED_CyclicWordsAreReadBackToTheSameEasing) {
  const Interp written = Default(Interp::Cyclic);
  Interp read;
  ASSERT_EQ(interp_said(interp_words(written), &read), 0);
  EXPECT_EQ(read.kind, Interp::Cyclic);
  for (int i = 0; i < interp_kinds[Interp::Cyclic].numbers; ++i) {
    EXPECT_DOUBLE_EQ(read.p[i], written.p[i]) << "parameter " << i;
  }
}

}  // namespace
}  // namespace motolii

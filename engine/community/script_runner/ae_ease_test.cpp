// After Effects' ease(), easeIn() and easeOut() inside an expression a recipe
// holds (AE.compile, ae_expr.h), as shelves/create/repeats/ae_stagger.js
// uses them.
//
// The expected values are not Motolii's. lottie-web, which runs After Effects
// expressions on the web, draws the three as cubic Beziers
// (github.com/airbnb/lottie-web, player/js/utils/expressions/
// ExpressionManager.js): ease (0.33, 0, 0.667, 1), easeIn (0.333, 0, 0.833,
// 0.833), easeOut (0.167, 0.167, 0.667, 1). Each number below is that curve at
// u = 0.1 ... 0.9, solved by 100 steps of bisection in a script outside the
// engine (so no solver of ours made them). By those control points easeIn
// arrives at its end on a slope of 1 and easeOut leaves its start on a slope of
// 1: each eases one end only. lottie-web is a re-implementation, not After
// Effects; a table read off After Effects itself would settle the three.

#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

// A script holding the expression `fn(time, 0, 1, 0, 1)`, as ae_stagger.js
// holds its own: each() hands back what the expression gives at time t.
struct Expression {
  fs::path file;
  explicit Expression(const std::string& fn)
      : file(fs::temp_directory_path() / ("motolii_ae_" + fn + ".js")) {
    std::ofstream(file) << "const f = AE.compile(`" << fn
                        << "(time, 0, 1, 0, 1)`);\n"
                           "const c = { value: 0, comp: AE.comp({ width: 1920, "
                           "height: 1080 }, []) };\n"
                           "function each(i, n, t, k) { c.index = i + 1; "
                           "c.time = t; c.comp.numLayers = n; "
                           "return { x: AE.run(f, c) }; }\n";
  }
  ~Expression() { fs::remove(file); }
};

void Follows(const std::string& fn, const double (&want)[9]) {
  Expression e(fn);
  Script s(e.file.string(), P5());
  ASSERT_TRUE(s.ok()) << s.trouble();
  for (int i = 1; i <= 9; ++i) {
    const double u = i / 10.0;
    const auto copies = s.copies(1, u, {}, {}, 1.0);
    ASSERT_EQ(copies.size(), 1u);
    EXPECT_NEAR(copies[0].x, want[i - 1], 1e-6) << fn << " at " << u;
  }
}

TEST(AfterEffectsEase, EaseIsEasyEaseOnBothEnds) {
  Follows("ease", {0.028436759, 0.105204383, 0.217775820, 0.353933478,
                   0.501682861, 0.649170753, 0.784606343, 0.896183798,
                   0.972004855});
}

TEST(AfterEffectsEase, EaseInEasesOnlyTheStart) {
  Follows("easeIn", {0.021672612, 0.076857932, 0.155843743, 0.252638005,
                     0.363113733, 0.484105907, 0.612826557, 0.746234933,
                     0.879655959});
}

TEST(AfterEffectsEase, EaseOutEasesOnlyTheEnd) {
  Follows("easeOut", {0.120344041, 0.253765067, 0.387173443, 0.515894093,
                      0.636886267, 0.747361995, 0.844156257, 0.923142068,
                      0.978327388});
}

}  // namespace
}  // namespace motolii

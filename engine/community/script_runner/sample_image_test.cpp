// sampleImage() and fromWorld() as a script sees them: the two global functions
// that Script::reads_pictures answers (script_runner.h), and the same two on a
// layer of thisComp inside an After Effects expression (AE.compile, ae_expr.h).
//
// The values for arguments left out are After Effects' own:
// sampleImage(point, radius = [.5, .5], postEffect = true, t = time)
// (ae-expressions.docsforadobe.dev/layer/general/). Every other expected number
// is one this file put in: the arguments written in the script, and the fixed
// colour and point that the test's sampler and mapper answer with. The tests
// were written from the comments in script_runner.h and ae_expr.h, not from the
// code that implements them.

#include <gtest/gtest.h>

#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

// What the script last asked the engine for. Empty if it never asked.
struct Seen {
  std::vector<double> sampled;  // layer, x, y, rx, ry, post_effect (1 or 0), t
  std::vector<double> mapped;   // layer, x, y, z, t
};

// Runs the script `body` and returns the x of each of its n copies at second
// t. With `seen`, the script gets a sampler that answers the colour
// (0.1, 0.2, 0.3, 0.4) and a mapper that answers the point (640, 360), and both
// note in `seen` what they were asked. Without it, the script gets neither.
std::vector<double> Answers(const std::string& body, int n, double t,
                            Seen* seen) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file =
      fs::temp_directory_path() / (std::string("motolii_") +
                                   test->test_suite_name() + test->name() +
                                   ".js");
  std::ofstream(file) << body;
  std::vector<double> xs;
  {
    Script s(file.string(), P5());
    EXPECT_TRUE(s.ok()) << s.trouble();
    if (seen) {
      s.reads_pictures(
          [seen](int layer, double x, double y, double rx, double ry,
                 bool post_effect, double second) {
            seen->sampled = {double(layer),           x, y, rx, ry,
                             post_effect ? 1.0 : 0.0, second};
            return std::array<double, 4>{0.1, 0.2, 0.3, 0.4};
          },
          [seen](int layer, double x, double y, double z, double second) {
            seen->mapped = {double(layer), x, y, z, second};
            return std::array<double, 2>{640.0, 360.0};
          });
    }
    if (s.ok()) {
      for (const ScriptCopy& c : s.copies(n, t, {}, {}, 1.0)) xs.push_back(c.x);
    }
  }
  fs::remove(file);
  return xs;
}

void Same(const std::vector<double>& got, const std::vector<double>& want) {
  ASSERT_EQ(got.size(), want.size());
  for (size_t i = 0; i < want.size(); ++i)
    EXPECT_DOUBLE_EQ(got[i], want[i]) << "number " << i;
}

// A script whose each() works out the array `js` and hands back one of its
// numbers per copy, so n copies carry n numbers.
std::string Each(const std::string& js) {
  return "function each(i, n, t, k) { const out = " + js +
         "; return { x: out[i] }; }\n";
}

// A script holding the After Effects expression thisComp.layer("Video").<call>,
// where the layer "Video" has the engine's sampleImage and fromWorld for layer
// 9. Where the adapter hands the layer no argument, the layer passes on a mark
// (-1, or false) instead, so the defaults the sampler sees are the adapter's
// and not the global function's.
std::string Expression(const std::string& call) {
  return "const f = AE.compile(`thisComp.layer(\"Video\")." + call + "`);\n" +
         R"js(
const videoLayer = {
  name: "Video", index: 1, width: 1920, height: 1080,
  position: (t) => [960, 540],
  sampleImage: (p, r, post, t) => sampleImage(9, p,
      r === undefined ? [-1, -1] : r, post === undefined ? false : post,
      t === undefined ? -1 : t),
  fromWorld: (p, t) => fromWorld(9, p, t === undefined ? -1 : t),
};
const c = { value: 0, index: 1, comp: AE.comp(
    { width: 1920, height: 1080, numLayers: 1 }, [videoLayer]) };
function each(i, n, t, k) { c.time = t; return { x: AE.run(f, c)[i] }; }
)js";
}

TEST(SampleImage, HandsItsArgumentsToTheSamplerAndReturnsItsColour) {
  Seen seen;
  Same(Answers(Each("sampleImage(7, [120, 45], [3, 2], false, 1.5)"), 4, 0,
               &seen),
       {0.1, 0.2, 0.3, 0.4});
  Same(seen.sampled, {7, 120, 45, 3, 2, 0, 1.5});
}

TEST(SampleImage, RadiusLeftOutIsHalfAPixelAndPostEffectLeftOutIsTrue) {
  Seen seen;
  Answers(Each("sampleImage(7, [120, 45], undefined, undefined, 1.5)"), 4, 0,
          &seen);
  Same(seen.sampled, {7, 120, 45, 0.5, 0.5, 1, 1.5});
}

// The first number is the length of what came back, so that a script that
// failed (every copy's x is 0 then) does not pass for four zeros.
TEST(SampleImage, GivesFourZerosWhileNoSamplerIsSet) {
  Same(Answers(Each("((c) => [c.length, ...c])"
                    "(sampleImage(7, [120, 45], [3, 2], false, 1.5))"),
               5, 0, nullptr),
       {4, 0, 0, 0, 0});
}

TEST(FromWorld, HandsItsArgumentsToTheMapperAndReturnsItsPoint) {
  Seen seen;
  Same(Answers(Each("fromWorld(5, [1, 2, 3], 0.25)"), 2, 0, &seen),
       {640, 360});
  Same(seen.mapped, {5, 1, 2, 3, 0.25});
}

TEST(FromWorld, ThirdNumberLeftOutIsZero) {
  Seen seen;
  Answers(Each("fromWorld(5, [1, 2], 0.25)"), 2, 0, &seen);
  Same(seen.mapped, {5, 1, 2, 0, 0.25});
}

TEST(FromWorld, GivesTwoNaNWhileNoMapperIsSet) {
  const std::vector<double> got = Answers(
      Each("((p) => [p.length, ...p])(fromWorld(5, [1, 2, 3], 0.25))"), 3, 0,
      nullptr);
  ASSERT_EQ(got.size(), 3u);
  EXPECT_DOUBLE_EQ(got[0], 2);
  EXPECT_TRUE(std::isnan(got[1])) << got[1];
  EXPECT_TRUE(std::isnan(got[2])) << got[2];
}

TEST(AfterEffectsSampleImage, ArgumentsLeftOutAreAfterEffectsDefaults) {
  Seen seen;
  Same(Answers(Expression("sampleImage([120, 45])"), 4, 2.5, &seen),
       {0.1, 0.2, 0.3, 0.4});
  Same(seen.sampled, {9, 120, 45, 0.5, 0.5, 1, 2.5});
}

TEST(AfterEffectsSampleImage, ArgumentsGivenArePassedAsTheyAre) {
  Seen seen;
  Answers(Expression("sampleImage([120, 45], [3, 2], false, 0.75)"), 4, 2.5,
          &seen);
  Same(seen.sampled, {9, 120, 45, 3, 2, 0, 0.75});
}

TEST(AfterEffectsFromWorld, FromCompAsksTheLayerAtTheTimeOfTheExpression) {
  Seen seen;
  Same(Answers(Expression("fromComp([100, 200])"), 2, 2.5, &seen), {640, 360});
  Same(seen.mapped, {9, 100, 200, 0, 2.5});
}

TEST(AfterEffectsFromWorld, FromWorldAsksTheLayerAtTheTimeOfTheExpression) {
  Seen seen;
  Same(Answers(Expression("fromWorld([100, 200, 30])"), 2, 2.5, &seen),
       {640, 360});
  Same(seen.mapped, {9, 100, 200, 30, 2.5});
}

TEST(AfterEffectsFromWorld, ATimeGivenIsPassedOn) {
  Seen seen;
  Answers(Expression("fromComp([100, 200], 0.75)"), 2, 2.5, &seen);
  Same(seen.mapped, {9, 100, 200, 0, 0.75});
  seen.mapped.clear();
  Answers(Expression("fromWorld([100, 200], 0.75)"), 2, 2.5, &seen);
  Same(seen.mapped, {9, 100, 200, 0, 0.75});
}

}  // namespace
}  // namespace motolii

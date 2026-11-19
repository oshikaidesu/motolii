// Tests that `script_parameters` (script_parameters.h) pulls one track
// parameter out of every `effect("Name Control")("Slider")` reference inside
// an AE.compile(`...`) call, and that the slider value the user sets on the
// ValuesCard flows back into the expression at run time. This is "paste →
// card" from both sides: the card appears without a header, and moving its
// sliders moves what the expression evaluates to.

#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <map>
#include <string>
#include <vector>

#include "community/script_runner/script_parameters.h"
#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .generic_string();
}

std::vector<ScriptParameter> ParamsOf(const std::string& body) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file = fs::temp_directory_path() /
                        (std::string("motolii_params_") +
                         test->test_suite_name() + "_" + test->name() + ".js");
  std::ofstream(file) << body;
  auto out = script_parameters(file.generic_string());
  fs::remove(file);
  return out;
}

std::vector<ScriptCopy> RunCopies(const std::string& body, double t,
                                  std::map<std::string, double> numbers) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file = fs::temp_directory_path() /
                        (std::string("motolii_effect_slider_") +
                         test->test_suite_name() + "_" + test->name() + ".js");
  std::ofstream(file) << body;
  Script s(file.generic_string(), P5());
  EXPECT_TRUE(s.ok()) << s.trouble();
  auto out = s.copies(1, t, numbers, {}, 1.0);
  fs::remove(file);
  return out;
}

TEST(ScriptParametersAE, OneEffectSliderBecomesOneTrack) {
  const auto params = ParamsOf(
      "const f = AE.compile(`wiggle(effect(\"Frequency Control\")"
      "(\"Slider\"), 50)`);\n"
      "function each(i, n, t) { return { x: AE.run(f, { time: t }) }; }\n");
  ASSERT_EQ(params.size(), 1u);
  EXPECT_EQ(params[0].kind, "track");
  EXPECT_EQ(params[0].label, "Frequency Control");
  EXPECT_EQ(params[0].name, "frequency_control");
}

TEST(ScriptParametersAE, TwoDistinctEffectsBecomeTwoTracks) {
  const auto params = ParamsOf(
      "const f = AE.compile(`"
      "wiggle(effect(\"Speed Control\")(\"Slider\"), "
      "effect(\"Amplitude Control\")(\"Slider\"))`);\n"
      "function each(i, n, t) { return { x: AE.run(f, { time: t }) }; }\n");
  ASSERT_EQ(params.size(), 2u);
  EXPECT_EQ(params[0].label, "Speed Control");
  EXPECT_EQ(params[1].label, "Amplitude Control");
}

TEST(ScriptParametersAE, RepeatedReferenceIsDeduplicated) {
  const auto params = ParamsOf(
      "const f = AE.compile(`"
      "effect(\"Pan Control\")(\"Slider\") + "
      "effect(\"Pan Control\")(\"Slider\") * time`);\n"
      "function each(i, n, t) { return { x: AE.run(f, { time: t }) }; }\n");
  ASSERT_EQ(params.size(), 1u);
  EXPECT_EQ(params[0].label, "Pan Control");
}

TEST(ScriptParametersAE, NoEffectReferencesGivesNoParams) {
  const auto params = ParamsOf(
      "const f = AE.compile(`wiggle(2, 50)`);\n"
      "function each(i, n, t) { return { x: AE.run(f, { time: t }) }; }\n");
  EXPECT_TRUE(params.empty());
}

TEST(AfterEffectsEffectSlider, EffectValueMultipliesTime) {
  // effect("Freq Control")("Slider") * time, with Freq = 3 at t = 2, is 6.
  // k flows into ctx.k inside each(); the shim's elem.effect(...) looks the
  // value up by snake_name("Freq Control") = "freq_control".
  const std::string body =
      "const f = AE.compile(`effect(\"Freq Control\")(\"Slider\") * time`);\n"
      "const c = { value: 0, comp: AE.comp({ width: 1920, height: 1080 }, "
      "[]) };\n"
      "function each(i, n, t, k) { c.index = i + 1; c.time = t; c.k = k; "
      "return { x: AE.run(f, c) }; }\n";
  const auto copies = RunCopies(body, 2.0, {{"freq_control", 3.0}});
  ASSERT_EQ(copies.size(), 1u);
  EXPECT_NEAR(copies[0].x, 6.0, 1e-6);
}

TEST(AfterEffectsEffectSlider, EffectValueIsZeroWithoutSlider) {
  // With no slider moved (empty numbers map), the shim reports AE's Slider
  // default of 0, so any expression that multiplies by an effect value is 0.
  const std::string body =
      "const f = AE.compile(`effect(\"Pan Control\")(\"Slider\") * 10 + 5`);\n"
      "const c = { value: 0, comp: AE.comp({ width: 1920, height: 1080 }, "
      "[]) };\n"
      "function each(i, n, t, k) { c.index = i + 1; c.time = t; c.k = k; "
      "return { x: AE.run(f, c) }; }\n";
  const auto copies = RunCopies(body, 1.0, {});
  ASSERT_EQ(copies.size(), 1u);
  EXPECT_NEAR(copies[0].x, 5.0, 1e-6);
}

}  // namespace
}  // namespace motolii

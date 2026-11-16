// Tests that `script_parameters` (script_parameters.h) pulls one track
// parameter out of every `effect("Name Control")("Slider")` reference inside
// an AE.compile(`...`) call. This is the first step of "paste → card":
// a recipe that holds an AE expression doesn't need a parameter header any
// more — its slider controls appear on its ValuesCard on their own.

#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "community/script_runner/script_parameters.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::vector<ScriptParameter> ParamsOf(const std::string& body) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file = fs::temp_directory_path() /
                        (std::string("motolii_params_") +
                         test->test_suite_name() + "_" + test->name() + ".js");
  std::ofstream(file) << body;
  auto out = script_parameters(file.string());
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

}  // namespace
}  // namespace motolii

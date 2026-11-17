// Tests that `script_parameters` (script_parameters.h) pulls one track
// parameter out of every CSS custom property declaration in a pen whose
// adapter_form is "css" (community/sites/site_adapter.h). This is the CSS half
// of "paste → card": a pen's --duration / --radius / --angle appear as
// sliders on its ValuesCard, so the user can retime or resize what the
// pen does without editing the CSS text.

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
                        (std::string("motolii_css_params_") +
                         test->test_suite_name() + "_" + test->name() + ".js");
  std::ofstream(file) << body;
  auto out = script_parameters(file.generic_string());
  fs::remove(file);
  return out;
}

TEST(ScriptParametersCSS, OneCustomPropertyBecomesOneTrack) {
  const auto params = ParamsOf(
      ":root { --duration: 2s; }\n"
      "@keyframes spin { from { transform: rotate(0); } to { transform: "
      "rotate(360deg); } }\n");
  ASSERT_EQ(params.size(), 1u);
  EXPECT_EQ(params[0].kind, "track");
  EXPECT_EQ(params[0].label, "--duration");
  EXPECT_EQ(params[0].name, "duration");
  EXPECT_DOUBLE_EQ(params[0].usual, 2.0);
}

TEST(ScriptParametersCSS, MillisecondsFoldIntoSeconds) {
  const auto params = ParamsOf(
      ":root { --delay: 250ms; }\n@keyframes a { 0% {} 100% {} }\n");
  ASSERT_EQ(params.size(), 1u);
  EXPECT_DOUBLE_EQ(params[0].usual, 0.25);
  EXPECT_EQ(params[0].unit, "s");  // ms folded to seconds, unit kept as 's'
}

TEST(ScriptParametersCSS, UnitIsRememberedForEachProperty) {
  const auto params = ParamsOf(
      ":root { --duration: 2s; --angle: 30deg; --size: 100px; --ratio: 0.5; }\n"
      "@keyframes a { 0% {} 100% {} }\n");
  ASSERT_EQ(params.size(), 4u);
  EXPECT_EQ(params[0].label, "--duration");
  EXPECT_EQ(params[0].unit, "s");
  EXPECT_EQ(params[1].unit, "deg");
  EXPECT_EQ(params[2].unit, "px");
  EXPECT_EQ(params[3].unit, "");  // no unit
}

TEST(ScriptParametersCSS, RepeatedDeclarationIsDeduplicated) {
  const auto params = ParamsOf(
      ":root { --radius: 10px; } .ring { --radius: 20px; }\n"
      "@keyframes r { 0% {} 100% {} }\n");
  ASSERT_EQ(params.size(), 1u);
  EXPECT_EQ(params[0].label, "--radius");
}

TEST(ScriptParametersCSS, NoKeyframesLeavesCssUntouched) {
  // Without @keyframes the file isn't a CSS pen (adapter_form returns "").
  const auto params = ParamsOf(":root { --whatever: 5px; }\n");
  EXPECT_TRUE(params.empty());
}

}  // namespace
}  // namespace motolii

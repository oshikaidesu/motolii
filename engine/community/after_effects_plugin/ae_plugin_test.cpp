#include "community/after_effects_plugin/ae_plugin.h"

#include <gtest/gtest.h>

#include <filesystem>

#include "shelf/shelf_folders.h"

namespace motolii {
namespace {

TEST(AePlugin, ExtensionDetection) {
  EXPECT_TRUE(ae_plugin_is("/tmp/ZT_AnimeSmoke.plugin"));
  EXPECT_TRUE(ae_plugin_is("/tmp/DeepGlow2.aex"));
  EXPECT_TRUE(ae_plugin_is("a1b2c3:/tmp/Foo.PLUGIN"));
  EXPECT_FALSE(ae_plugin_is("/tmp/blur.wgsl"));
  EXPECT_FALSE(ae_plugin_is("/tmp/glow.fs"));
  EXPECT_FALSE(ae_plugin_is("/tmp/script.anm2"));
}

TEST(AePlugin, TitleFormatting) {
  EXPECT_EQ(ae_plugin_title("/tmp/ZT_AnimeSmoke.plugin"), "ZT AnimeSmoke");
  EXPECT_EQ(ae_plugin_title("a1b2c3:/tmp/my_blur.aex"), "My blur");
}

TEST(AePlugin, MissingPluginFailsSafely) {
  const AePluginInfo info = ae_plugin_probe("/nonexistent/Missing.plugin");
  EXPECT_FALSE(info.ok);
  EXPECT_TRUE(info.params.empty());
  EXPECT_TRUE(info.tags.empty());
}

#ifdef __APPLE__
TEST(AePlugin, ProbesBundledAexloFixture) {
  const std::filesystem::path fixture =
      doc_engine("third_party/aexlo_src/fixtures/plugins/macos/SDK_Noise.plugin");
  if (!std::filesystem::exists(fixture)) GTEST_SKIP() << "fixture not present";

  const AePluginInfo info = ae_plugin_probe(fixture.generic_string());
  ASSERT_TRUE(info.ok);
  EXPECT_FALSE(info.gpu);
  EXPECT_NE(info.tags.find("ae"), std::string::npos);
  EXPECT_NE(info.tags.find("cpu"), std::string::npos);
  EXPECT_FALSE(info.params.empty());
  EXPECT_FALSE(info.script_params.empty());
}
#endif

}  // namespace
}  // namespace motolii

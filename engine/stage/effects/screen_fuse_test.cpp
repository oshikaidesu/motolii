// Unit tests for pointwise WGSL shader analysis, zero-alpha preservation,
// dead-time detection, and pre-resolved uniform field classification.
#include <gtest/gtest.h>

#include <algorithm>
#include <filesystem>
#include <string>

#include "shelf/shelf_folders.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/screen_pool.h"

namespace motolii {
namespace {

std::string effect_path(const std::string& rel) {
  for (const auto& dir : doc_folders("effects")) {
    const auto full = dir / rel;
    if (std::filesystem::exists(full)) return full.generic_string();
  }
  return "";
}

ScreenFx analyze_effect(const std::string& rel) {
  ScreenFx fx;
  fx.file = effect_path(rel);
  EXPECT_FALSE(fx.file.empty()) << "missing shelf effect: " << rel;
  std::string code;
  EXPECT_TRUE(screen_read(fx, code)) << fx.trouble;
  screen_analyze_pointwise(fx, code);
  return fx;
}

TEST(ScreenFuse, ClassifiesPointwiseZeroAlphaColorShaders) {
  for (const char* rel : {
           "color/am_brightnesscontrast.wgsl",
           "color/am_exposure.wgsl",
           "color/am_huesaturation.wgsl",
           "color/am_colorbalance.wgsl",
           "color/am_temperature.wgsl",
           "color/am_levels.wgsl",
       }) {
    const ScreenFx fx = analyze_effect(rel);
    EXPECT_TRUE(fx.pointwise) << rel;
    EXPECT_TRUE(fx.pointwiseSksl) << rel;
    EXPECT_TRUE(fx.preservesZeroAlpha) << rel;
    EXPECT_FALSE(fx.usesTime) << rel;
  }
}

TEST(ScreenFuse, RejectsAlphaInvertingAndMultiSampleShaders) {
  const ScreenFx inv = analyze_effect("color/am_invert.wgsl");
  EXPECT_TRUE(inv.pointwise);
  EXPECT_FALSE(inv.preservesZeroAlpha);

  const ScreenFx blur = analyze_effect("blur/am_directionalblur.wgsl");
  EXPECT_FALSE(blur.pointwise);
  EXPECT_FALSE(blur.preservesZeroAlpha);
  EXPECT_EQ(blur.spillKind, ScreenFx::SpillKind::ParamPx);
  EXPECT_GE(blur.spillField, 0);

  const ScreenFx denoise = analyze_effect("blur/am_denoise.wgsl");
  EXPECT_FALSE(denoise.pointwise);
  EXPECT_TRUE(denoise.preservesZeroAlpha);
  EXPECT_EQ(denoise.spillKind, ScreenFx::SpillKind::Zero);

  const ScreenFx tile = analyze_effect("move/am_tile.wgsl");
  EXPECT_EQ(tile.spillKind, ScreenFx::SpillKind::Unbounded);
}

TEST(ScreenFuse, DetectsTimeDependentVsStaticShaders) {
  const ScreenFx grain = analyze_effect("generate/am_filmgrain.wgsl");
  EXPECT_TRUE(grain.pointwise);
  EXPECT_TRUE(grain.usesTime);

  const ScreenFx glow = analyze_effect("blur/Glow (Sashimono).fs");
  EXPECT_FALSE(glow.pointwise);
  EXPECT_FALSE(glow.usesTime);
  EXPECT_EQ(glow.spillKind, ScreenFx::SpillKind::ParamPx);
  EXPECT_FLOAT_EQ(glow.spillCap, 96.f);
  const bool hasClipTime = std::any_of(
      glow.fields.begin(), glow.fields.end(), [](const ScreenFx::Field& f) {
        return f.kind == ScreenFx::FieldKind::ClipTime;
      });
  EXPECT_TRUE(hasClipTime);

  const ScreenFx gblur = analyze_effect("blur/Multi Pass Gaussian Blur.fs");
  EXPECT_FALSE(gblur.pointwise);
  EXPECT_FALSE(gblur.usesTime);
  EXPECT_EQ(gblur.spillKind, ScreenFx::SpillKind::ParamPx);
  EXPECT_FLOAT_EQ(gblur.spillCap, 128.f);
}

}  // namespace
}  // namespace motolii

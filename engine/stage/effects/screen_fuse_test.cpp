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
  EXPECT_GE(gblur.bypassField, 0);
}

TEST(ScreenFuse, AuthorDirectivesAndModernShelfShadersWork) {
  const ScreenFx kawase = analyze_effect("blur/Dual Kawase Blur.fs");
  EXPECT_EQ(kawase.spillKind, ScreenFx::SpillKind::ParamPx);
  EXPECT_FLOAT_EQ(kawase.spillScale, 1.5f);
  EXPECT_FLOAT_EQ(kawase.spillBase, 8.f);
  EXPECT_FLOAT_EQ(kawase.spillCap, 192.f);
  EXPECT_GE(kawase.bypassField, 0);
  EXPECT_FALSE(kawase.usesTime);

  const ScreenFx bloom = analyze_effect("blur/Physical Bloom.fs");
  EXPECT_EQ(bloom.spillKind, ScreenFx::SpillKind::ParamPx);
  EXPECT_FLOAT_EQ(bloom.spillScale, 3.f);
  EXPECT_FLOAT_EQ(bloom.spillBase, 16.f);
  EXPECT_FLOAT_EQ(bloom.spillCap, 192.f);
  EXPECT_GE(bloom.bypassField, 0);
  EXPECT_FALSE(bloom.usesTime);

  const ScreenFx al = analyze_effect("stylize/AudioLink Pulse.wgsl");
  EXPECT_EQ(al.spillKind, ScreenFx::SpillKind::Zero);
  EXPECT_GE(al.bypassField, 0);
  ASSERT_EQ(al.sounds.size(), 1u);
  EXPECT_TRUE(al.sounds[0].audioLink);

  // Plain user-written WGSL (rewritten by screen_framed) fuses automatically
  // and detects zero-alpha preservation without any special directives.
  {
    ScreenFx custom;
    custom.textureCount = 1;
    const std::string framedUserWgsl =
        "struct Knobs { frameRect: vec4f, gain: f32, };\n"
        "@group(0) @binding(0) var image: texture_2d<f32>;\n"
        "@group(0) @binding(1) var near: sampler;\n"
        "@group(0) @binding(2) var<uniform> k: Knobs;\n"
        "fn frame_level(t: texture_2d<f32>, s: sampler, c: vec2f, l: f32) -> "
        "vec4f { return textureSampleLevel(t, s, c * k.frameRect.zw + "
        "k.frameRect.xy, l); }\n"
        "fn frame_sample(t: texture_2d<f32>, s: sampler, c: vec2f) -> vec4f { "
        "return textureSample(t, s, c * k.frameRect.zw + k.frameRect.xy); }\n"
        "@fragment fn main(@builtin(position) frag_on: vec4f, @location(0) "
        "uv_on: vec2f) -> @location(0) vec4f {\n"
        "  let uv = (uv_on - k.frameRect.xy) / k.frameRect.zw;\n"
        "  let c = frame_sample(image, near, uv);\n"
        "  if (c.a <= 0.0) { return vec4f(0.0); }\n"
        "  return vec4f(clamp(c.rgb * k.gain, vec3f(0.0), vec3f(1.0)) * c.a, "
        "c.a);\n"
        "}\n";
    screen_analyze_pointwise(custom, framedUserWgsl);
    EXPECT_TRUE(custom.pointwise);
    EXPECT_FALSE(custom.pointwiseSksl);
    EXPECT_TRUE(custom.preservesZeroAlpha);
    EXPECT_EQ(custom.spillKind, ScreenFx::SpillKind::Zero);
  }
}

TEST(ScreenFuse, ClassifiesSinglePassIsfColorShadersAsPointwise) {
  const ScreenFx exp = analyze_effect("color/Exposure Adjust.fs");
  EXPECT_TRUE(exp.pointwise);
  EXPECT_FALSE(exp.hasFrameRect);
  EXPECT_TRUE(exp.preservesAlpha);
  EXPECT_TRUE(exp.preservesZeroAlpha);
  EXPECT_EQ(exp.spillKind, ScreenFx::SpillKind::Zero);

  const ScreenFx gamma = analyze_effect("color/Gamma Correction.fs");
  EXPECT_TRUE(gamma.pointwise);
  EXPECT_FALSE(gamma.hasFrameRect);
  EXPECT_TRUE(gamma.preservesAlpha);
  EXPECT_TRUE(gamma.preservesZeroAlpha);
  EXPECT_EQ(gamma.spillKind, ScreenFx::SpillKind::Zero);

  const ScreenFx sashExp = analyze_effect("color/Exposure (Sashimono).fs");
  EXPECT_TRUE(sashExp.pointwise);
  EXPECT_FALSE(sashExp.hasFrameRect);
  EXPECT_TRUE(sashExp.preservesAlpha);
  EXPECT_TRUE(sashExp.preservesZeroAlpha);
  EXPECT_EQ(sashExp.spillKind, ScreenFx::SpillKind::Zero);

  const ScreenFx sashCC = analyze_effect("color/Color Correct (Sashimono).fs");
  EXPECT_TRUE(sashCC.pointwise);
  EXPECT_FALSE(sashCC.hasFrameRect);
  EXPECT_TRUE(sashCC.preservesAlpha);

  // Color Controls modifies alpha via contrast, so it fuses as pointwise while
  // staying safely unbounded (not alpha-preserving).
  const ScreenFx ctrl = analyze_effect("color/Color Controls.fs");
  EXPECT_TRUE(ctrl.pointwise);
  EXPECT_FALSE(ctrl.preservesAlpha);
  EXPECT_FALSE(ctrl.preservesZeroAlpha);
  EXPECT_EQ(ctrl.spillKind, ScreenFx::SpillKind::Unbounded);
}

}  // namespace
}  // namespace motolii

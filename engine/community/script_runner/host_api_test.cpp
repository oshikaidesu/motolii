// Tests the concise JS host API (host_prelude.js: stage, layer, audio, midi),
// live AE.compile host auto-wiring (lottie_shim.js), and dynamic FPS in
// Cavalry whole-file execution (run_cavalry.cpp).

#include <gtest/gtest.h>

#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <map>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .generic_string();
}

struct MockHost {
  // layer -> prop -> fn(t)
  std::map<std::pair<int, std::string>, std::function<double(double)>> values;
  std::map<std::pair<int, std::string>, std::vector<double>> keys;
  std::map<std::pair<int, std::string>, std::string> words;
  std::map<std::string, int> names;
  std::vector<int> layer_ids;
  std::map<int, std::vector<int>> child_ids;
  std::map<int, std::array<double, 8>> bounds_map;
  std::map<std::tuple<int, std::string, std::string>, double> effects;
  std::array<double, 12> cam = {0, 1, 8, 0, 0, 0, 0, 1, 0, 45, 1.5, 9};
  std::array<double, 5> bands = {0.8, 0.5, 0.3, 0.1, 0.52};
  std::array<double, 4> midi_state = {0.75, 60, 1, 128};
  int last_audio_layer = -999;
  double last_audio_t = -1;

  void bind(Script& s) {
    s.reads([this](int id, const std::string& name, double t, double otherwise,
                   int) {
      auto it = values.find({id, name});
      return it != values.end() ? it->second(t) : otherwise;
    });
    s.reads_keys(
        [this](int id, const std::string& name) {
          auto it = keys.find({id, name});
          return it != keys.end() ? it->second : std::vector<double>{};
        },
        [this](const std::string& name) {
          auto it = names.find(name);
          return it != names.end() ? it->second : 0;
        });
    s.reads_pictures(
        [](int, double, double, double, double, bool, double) {
          return std::array<double, 4>{0.2, 0.4, 0.6, 1.0};
        },
        [](int, double x, double y, double, double) {
          return std::array<double, 2>{x * 10.0, y * 10.0};
        });
    s.reads_sound([this](int id, bool spectrum, double t) {
      last_audio_layer = id;
      last_audio_t = t;
      return spectrum ? std::vector<float>{-30.f, -65.f, -100.f}
                      : std::vector<float>{0.25f, -0.5f, 0.75f};
    });
    Script::HostReads h;
    h.word = [this](int id, const std::string& name) {
      auto it = words.find({id, name});
      return it != words.end() ? it->second : std::string{};
    };
    h.bounds = [this](int id, double) {
      auto it = bounds_map.find(id);
      if (it != bounds_map.end()) return it->second;
      return std::array<double, 8>{NAN, NAN, NAN, NAN, NAN, NAN, NAN, NAN};
    };
    h.to_world = [](int, double x, double y, double z, double) {
      return std::array<double, 3>{x * 0.1, y * 0.1, z * 0.1};
    };
    h.to_screen = [](double x, double y, double, double) {
      return std::array<double, 2>{960.0 + x * 100.0, 540.0 - y * 100.0};
    };
    h.layers = [this]() { return layer_ids; };
    h.children = [this](int p) {
      auto it = child_ids.find(p);
      return it != child_ids.end() ? it->second : std::vector<int>{};
    };
    h.camera = [this](double) { return cam; };
    h.audio_bands = [this](int id, double t) {
      last_audio_layer = id;
      last_audio_t = t;
      return bands;
    };
    h.midi = [this](int, const std::string&, int, double) {
      return midi_state;
    };
    h.effect_param = [this](int id, const std::string& fx,
                            const std::string& param, double) {
      auto it = effects.find({id, fx, param});
      return it != effects.end() ? it->second : std::nan("");
    };
    s.reads_host(std::move(h));
  }
};

std::vector<double> RunScript(const std::string& body, int n, double t,
                              MockHost& host,
                              std::map<std::string, double> numbers = {}) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file = fs::temp_directory_path() /
                        (std::string("motolii_host_") +
                         test->test_suite_name() + "_" + test->name() + ".js");
  std::ofstream(file) << body;
  std::vector<double> xs;
  {
    Script s(file.generic_string(), P5());
    EXPECT_TRUE(s.ok()) << s.trouble();
    host.bind(s);
    if (s.ok()) {
      for (const ScriptCopy& c : s.copies(n, t, numbers, {}, 0.01))
        xs.push_back(c.x);
    }
  }
  fs::remove(file);
  return xs;
}

TEST(HostApi, LayerStageAudioMidiConciseSurface) {
  MockHost h;
  h.layer_ids = {1, 2};
  h.names["Leader"] = 1;
  h.names["Follower"] = 2;
  h.words[{1, "name"}] = "Leader";
  h.words[{1, "text"}] = "Hello";
  h.words[{2, "name"}] = "Follower";
  h.values[{1, "x"}] = [](double t) { return t * 2.0; };
  h.values[{1, "scale_x"}] = [](double) { return 1.5; };
  h.values[{2, "parent"}] = [](double) { return 1.0; };
  h.child_ids[1] = {2};
  h.bounds_map[1] = {960, 540, 400, 200, 0, 2.0, 1.0, 0.01};
  h.effects[{1, "Blur", "Radius"}] = 12.5;

  const std::string js = R"js(
    function each(i, n, t, k) {
      const L = layer("Leader");
      const out = [
        L.x,
        L.at(t - 0.5).x,
        L.scaleX,
        L.text.length,
        L.bounds.width,
        L.fx("Blur", "Radius"),
        L.children.length,
        layer().parent.id,
        stage.fps,
        stage.beat,
        stage.camera().fov,
        stage.toScreen([1, 0, 0])[0],
        audio.bass,
        audio.rms,
        midi.vel,
        midi.pitch,
      ];
      return { x: out[i] };
    }
  )js";
  const auto got = RunScript(
      js, 16, 1.5, h,
      {{"id", 2}, {"time", 1.5}, {"fps", 24}, {"bpm", 120}, {"bpm_from", 0}});
  ASSERT_EQ(got.size(), 16u);
  EXPECT_DOUBLE_EQ(got[0], 3.0);
  EXPECT_DOUBLE_EQ(got[1], 2.0);
  EXPECT_DOUBLE_EQ(got[2], 1.5);
  EXPECT_DOUBLE_EQ(got[3], 5.0);
  EXPECT_DOUBLE_EQ(got[4], 400.0);
  EXPECT_DOUBLE_EQ(got[5], 12.5);
  EXPECT_DOUBLE_EQ(got[6], 1.0);
  EXPECT_DOUBLE_EQ(got[7], 1.0);
  EXPECT_DOUBLE_EQ(got[8], 24.0);
  EXPECT_DOUBLE_EQ(got[9], 3.0);
  EXPECT_DOUBLE_EQ(got[10], 45.0);
  EXPECT_DOUBLE_EQ(got[11], 1060.0);
  EXPECT_DOUBLE_EQ(got[12], 0.8);
  EXPECT_DOUBLE_EQ(got[13], 0.52);
  EXPECT_DOUBLE_EQ(got[14], 0.75);
  EXPECT_DOUBLE_EQ(got[15], 60.0);
  EXPECT_EQ(h.last_audio_layer, 0);
  EXPECT_DOUBLE_EQ(h.last_audio_t, 1.5);
}

TEST(HostApi, AudioSpectrumAndWaveDefaultToMixedStage) {
  MockHost h;
  const std::string js = R"js(
    function each(i, n, t, k) {
      const s = audio.spectrum(new Uint8Array(3));
      const w = audio.wave(new Float32Array(3));
      const out = [s[0], s[2], w[0], w[1]];
      return { x: out[i] };
    }
  )js";
  const auto got = RunScript(js, 4, 2.0, h, {{"time", 2.0}});
  ASSERT_EQ(got.size(), 4u);
  EXPECT_DOUBLE_EQ(got[0], 255.0);
  EXPECT_DOUBLE_EQ(got[1], 0.0);
  EXPECT_NEAR(got[2], 0.25, 1e-6);
  EXPECT_NEAR(got[3], -0.5, 1e-6);
  EXPECT_EQ(h.last_audio_layer, 0);
}

TEST(HostApi, AeCompileAutoWiresCompLayerEffectRectToWorldAndFps) {
  MockHost h;
  h.layer_ids = {1, 2};
  h.names["Leader"] = 1;
  h.names["Title"] = 2;
  h.words[{1, "name"}] = "Leader";
  h.words[{2, "name"}] = "Title";
  h.words[{2, "text"}] = "Motolii";
  // px = 0.01 -> world x = 1.0 maps to W/2 + 100 = 1060.
  h.values[{1, "x"}] = [](double t) { return t; };
  h.values[{1, "y"}] = [](double) { return 0.0; };
  h.values[{1, "scale_x"}] = [](double) { return 2.0; };
  h.values[{1, "scale_y"}] = [](double) { return 0.5; };
  h.bounds_map[2] = {960, 540, 320, 80, 0, 1.6, 0.4, 0.01};
  h.effects[{1, "Glow", "Strength"}] = 0.75;

  const std::string js = R"js(
    const fPos = AE.compile(`thisComp.layer("Leader").transform.position.valueAtTime(time - 0.5)[0]`);
    const fScale = AE.compile(`thisComp.layer(1).transform.scale[0]`);
    const fFx = AE.compile(`thisComp.layer("Leader").effect("Glow")("Strength") * 10`);
    const fText = AE.compile(`thisComp.layer("Title").text.sourceText.length`);
    const fRect = AE.compile(`sourceRectAtTime().width`);
    const fWorld = AE.compile(`thisLayer.toWorld([50, 20])[0]`);
    const fFps = AE.compile(`Math.round(1 / thisComp.frameDuration)`);
    function each(i, n, t, k) {
      const ctx = { time: k.time, id: 2, k };
      const out = [
        AE.run(fPos, ctx),
        AE.run(fScale, ctx),
        AE.run(fFx, ctx),
        AE.run(fText, ctx),
        AE.run(fRect, ctx),
        AE.run(fWorld, ctx),
        AE.run(fFps, ctx),
      ];
      return { x: out[i] };
    }
  )js";
  const auto got = RunScript(
      js, 7, 1.5, h,
      {{"id", 2}, {"time", 1.5}, {"fps", 24}, {"wide", 1920}, {"high", 1080}});
  ASSERT_EQ(got.size(), 7u);
  // Leader x at t = 1.0 is 1.0 -> 960 + 1.0 / 0.01 = 1060.
  EXPECT_NEAR(got[0], 1060.0, 1e-6);
  EXPECT_NEAR(got[1], 200.0, 1e-6);
  EXPECT_NEAR(got[2], 7.5, 1e-6);
  EXPECT_DOUBLE_EQ(got[3], 7.0);
  EXPECT_DOUBLE_EQ(got[4], 320.0);
  EXPECT_NEAR(got[5], 5.0, 1e-6);
  EXPECT_DOUBLE_EQ(got[6], 24.0);
}

TEST(HostApi, AeLoopOutPingpongAndKeyframesUseHostKeys) {
  MockHost h;
  h.layer_ids = {1};
  // Rotation animates linearly 0 -> 90 deg over t = [0, 1], clamped outside.
  h.values[{1, "rotate"}] = [](double t) {
    const double u = std::clamp(t, 0.0, 1.0);
    return -90.0 * u;  // AE rotation is -rotate -> 0..90 deg.
  };
  h.keys[{1, "rotate"}] = {0.0, 1.0};

  const std::string js = R"js(
    const fPing = AE.compile(`loopOut("pingpong")`);
    const fCycle = AE.compile(`loopOut("cycle")`);
    const fKeys = AE.compile(`numKeys`);
    const fKey2 = AE.compile(`key(2).time`);
    const fVel = AE.compile(`velocityAtTime(0.5)`);
    function each(i, n, t, k) {
      const ctx = { time: k.time, id: 1, propertyName: 'rotation', k };
      const out = [
        AE.run(fPing, ctx),
        AE.run(fCycle, ctx),
        AE.run(fKeys, ctx),
        AE.run(fKey2, ctx),
        AE.run(fVel, ctx),
      ];
      return { x: out[i] };
    }
  )js";
  // At t = 1.25: pingpong walks back from 90 to 67.5; cycle wraps to 22.5.
  const auto got = RunScript(js, 5, 1.25, h, {{"id", 1}, {"time", 1.25}});
  ASSERT_EQ(got.size(), 5u);
  EXPECT_NEAR(got[0], 67.5, 1e-4);
  EXPECT_NEAR(got[1], 22.5, 1e-4);
  EXPECT_DOUBLE_EQ(got[2], 2.0);
  EXPECT_DOUBLE_EQ(got[3], 1.0);
  EXPECT_NEAR(got[4], 90.0, 1e-3);
}

TEST(HostApi, CavalryWholeFileUsesProjectFps) {
  const fs::path file =
      fs::temp_directory_path() / "motolii_cavalry_fps_test.js";
  std::ofstream(file) << R"js(
    var pc = new cavalry.PointCloud();
    pc.appendPoint(new cavalry.Point(frame, 0));
    pc;
  )js";
  Script s(file.generic_string(), P5());
  ASSERT_TRUE(s.ok()) << s.trouble();
  const auto copies = s.copies(1, 2.0, {{"fps", 24.0}}, {}, 1.0);
  fs::remove(file);
  ASSERT_EQ(copies.size(), 1u);
  EXPECT_DOUBLE_EQ(copies[0].x, 48.0);
}

}  // namespace
}  // namespace motolii

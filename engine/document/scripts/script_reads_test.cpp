// Integration tests for doc_script_reads + doc_expressions_lay against a real
// in-memory SQLite Doc: verifies non-relation property access, layer metadata,
// hierarchy, camera, real ISF effect parameters, and pasted AE expressions.

#include "document/scripts/script_reads.h"

#include <gtest/gtest.h>
#include <sqlite3.h>

#include <cmath>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "document/document.h"
#include "document/evaluate/place.h"
#include "document/evaluate/value_at.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

fs::path RepoRoot() {
  return fs::path(__FILE__)
      .parent_path()
      .parent_path()
      .parent_path()
      .parent_path();
}

struct MiniDoc {
  Doc* d = nullptr;
  MiniDoc() : d(new Doc) {
    sqlite3_open(":memory:", &d->file);
    sqlite3_exec(d->file,
                 "create table keyframe(layer integer, name text, at numeric, "
                 "value, easing text, primary key(layer, name, at)) "
                 "without rowid;",
                 nullptr, nullptr, nullptr);
  }
  void Say(int id, const char* name, const char* word) {
    sqlite3_exec(d->file,
                 sqlite3_mprintf("insert or replace into keyframe(layer, name, "
                                 "at, value) values(%d, %Q, 0.0, %Q)",
                                 id, name, word),
                 nullptr, nullptr, nullptr);
    doc_forget(*d);
  }
  void Put(int id, const char* name, double v, double at = 0.0) {
    sqlite3_exec(d->file,
                 sqlite3_mprintf("insert or replace into keyframe(layer, name, "
                                 "at, value) values(%d, %Q, %!.17g, %!.17g)",
                                 id, name, at, v),
                 nullptr, nullptr, nullptr);
    doc_forget(*d);
  }
};

struct TempJs {
  fs::path path;
  TempJs(const std::string& stem, const std::string& body)
      : path(fs::temp_directory_path() / ("motolii_doc_expr_" + stem + ".js")) {
    std::ofstream(path) << body;
  }
  ~TempJs() { fs::remove(path); }
};

TEST(ScriptReadsDoc, UnlocksAllPropertiesHierarchyCameraAndRealIsfEffect) {
  MiniDoc doc;
  // Stage settings: 24 fps, 120 BPM.
  doc.Put(0, "frame_rate", 24.0);
  doc.Put(0, "bpm", 120.0);
  doc.Put(0, "bpm_from", 0.5);

  // Layer 1: Leader shape with non-relation properties (scale_x, trim) and a
  // real ISF effect (Bright.fs).
  doc.Say(1, "kind", "shape");
  doc.Say(1, "name", "Leader");
  doc.Put(1, "scale_x", 1.0, 0.0);
  doc.Put(1, "scale_x", 3.0, 2.0);
  doc.Put(1, "trim", 0.42, 0.0);
  const std::string bright_fx =
      (RepoRoot() / "shelves" / "effects" / "color" / "Bright.fs")
          .generic_string();
  doc.Say(1, "fx", bright_fx.c_str());
  doc.Put(1, doc_screen_parameter(bright_fx, "bright").c_str(), 0.65, 0.0);

  // Layer 2: Child text layer parented to Leader.
  doc.Say(2, "kind", "text");
  doc.Say(2, "name", "Title");
  doc.Say(2, "text", "Motolii!");
  doc.Put(2, "parent", 1.0);

  // Layer 3: Active camera with custom distance & focal length.
  doc.Say(3, "kind", "camera");
  doc.Say(3, "name", "MainCam");
  doc.Put(3, "distance", 2.0);
  doc.Put(3, "focal_length", 24.0);

  TempJs js("all_props", R"js(
    function each(i, n, t, k) {
      const L = layer("Leader");
      const out = [
        L.scaleX,
        L.get("trim"),
        L.keys("scale_x").length,
        L.fx("Bright", "bright"),
        L.children.length,
        layer("Title").text.length,
        layer("Title").parent.id,
        stage.fps,
        stage.bpm,
        stage.beat,
        stage.camera().id,
        stage.camera().distance,
      ];
      return { x: out[i] };
    }
  )js");
  doc.Say(2, "script", js.path.generic_string().c_str());

  DocScript* sc = doc_script_of(*doc.d, js.path.generic_string());
  ASSERT_NE(sc, nullptr);
  ASSERT_NE(sc->run, nullptr);
  ASSERT_TRUE(sc->run->ok()) << sc->run->trouble();

  const auto copies = doc_copies_laid(*doc.d, 2, 12, 1.0);
  ASSERT_EQ(copies.size(), 12u);
  EXPECT_NEAR(copies[0].x, 2.0, 1e-6);   // scale_x linearly interpolated at t=1
  EXPECT_NEAR(copies[1].x, 0.42, 1e-6);  // trim
  EXPECT_DOUBLE_EQ(copies[2].x, 2.0);    // 2 keyframes on scale_x
  EXPECT_NEAR(copies[3].x, 0.65, 1e-6);  // Bright.fs -> bright
  EXPECT_DOUBLE_EQ(copies[4].x, 1.0);    // 1 child (Title)
  EXPECT_DOUBLE_EQ(copies[5].x, 8.0);    // "Motolii!".length
  EXPECT_DOUBLE_EQ(copies[6].x, 1.0);    // parent id
  EXPECT_DOUBLE_EQ(copies[7].x, 24.0);   // fps
  EXPECT_DOUBLE_EQ(copies[8].x, 120.0);  // bpm
  EXPECT_NEAR(copies[9].x, 1.0, 1e-6);   // (1.0 - 0.5) * 120 / 60 = 1 beat
  EXPECT_DOUBLE_EQ(copies[10].x, 3.0);   // camera layer id
  EXPECT_DOUBLE_EQ(copies[11].x, 2.0);   // camera distance
}

TEST(ScriptReadsDoc, PastedRawAeExpressionReadsOtherLayerAndLoopOut) {
  MiniDoc doc;
  doc.Put(0, "frame_rate", 30.0);

  // Layer 1: Leader animated in x from 0 to 2.0 over [0, 1].
  doc.Say(1, "kind", "shape");
  doc.Say(1, "name", "Leader");
  doc.Put(1, "x", 0.0, 0.0);
  doc.Put(1, "x", 2.0, 1.0);

  // Layer 2: Follower with a raw pasted AE expression (no each(), wrapped by
  // site_adapter.cpp) trailing Leader by 0.5 seconds!
  doc.Say(2, "kind", "shape");
  doc.Say(2, "name", "Follower");
  TempJs follow_ae(
      "raw_ae_follow",
      "thisComp.layer(\"Leader\").transform.position.valueAtTime(time - 0.5)");
  doc.Say(2, "script", follow_ae.path.generic_string().c_str());

  DocScript* sc = doc_script_of(*doc.d, follow_ae.path.generic_string());
  ASSERT_NE(sc, nullptr);
  ASSERT_NE(sc->run, nullptr);
  ASSERT_TRUE(sc->run->ok()) << sc->run->trouble();

  // At t = 1.0, Leader was at x = 1.0 at t = 0.5 -> Follower delta x == 1.0.
  const auto copies = doc_copies_laid(*doc.d, 2, 1, 1.0);
  ASSERT_EQ(copies.size(), 1u);
  EXPECT_NEAR(copies[0].x, 1.0, 1e-5);

  // Layer 3: Raw pasted AE loopOut("pingpong") on rotation.
  doc.Say(3, "kind", "shape");
  doc.Say(3, "name", "Spinner");
  doc.Put(3, "rotate", 0.0, 0.0);
  doc.Put(3, "rotate", -100.0, 1.0);
  TempJs loop_ae("raw_ae_loop",
                 "// --property:rotation\nloopOut(\"pingpong\")");
  doc.Say(3, "script", loop_ae.path.generic_string().c_str());

  DocScript* sc_loop = doc_script_of(*doc.d, loop_ae.path.generic_string());
  ASSERT_NE(sc_loop, nullptr);
  ASSERT_NE(sc_loop->run, nullptr);
  ASSERT_TRUE(sc_loop->run->ok()) << sc_loop->run->trouble();

  // At t = 1.25: base rotate is -100 (held), AE loopOut("pingpong") gives +75
  // -> target rotate = -75, so delta = +25 degrees!
  const auto loop_copies = doc_copies_laid(*doc.d, 3, 1, 1.25);
  ASSERT_EQ(loop_copies.size(), 1u);
  EXPECT_NEAR(loop_copies[0].rotate, 25.0, 1e-3);
}

}  // namespace
}  // namespace motolii

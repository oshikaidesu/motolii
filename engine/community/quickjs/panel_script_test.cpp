#include "community/quickjs/panel_script.h"

#include <gtest/gtest.h>

#include <string>

#include "shelf/shelf_folders.h"

namespace motolii {
namespace {

TEST(PanelScript, RendersDeclarativeUiTreeAndRunsActions) {
  const std::string src = R"JS(
    function render(ctx) {
      const step = (ctx.state && ctx.state.step) || 4;
      return ui.column([
        ui.badge(ctx.selected.length + " selected"),
        ui.number("Step", step, { id: "step", min: 1, max: 30, unit: "f" }),
        ui.button("Apply", "apply", { accent: true }),
      ]);
    }
    function onAction(action, ctx) {
      if (action.id === "step") return { state: { step: action.value } };
      if (action.id === "apply") {
        const step = (ctx.state && ctx.state.step) || 4;
        return {
          notice: "Applied",
          ops: ctx.selected.map((id, i) => ({
            op: "set", layer: id, name: "start", value: i * step / ctx.fps
          })),
        };
      }
      return {};
    }
  )JS";

  std::string err;
  const std::string ctx =
      R"JSON({"fps":30,"selected":[1,2],"state":{"step":6}})JSON";
  const std::string tree =
      panel_eval_render_source(src, "test.js", ctx, &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(tree.find("\"type\":\"column\""), std::string::npos) << tree;
  EXPECT_NE(tree.find("\"2 selected\""), std::string::npos) << tree;
  EXPECT_NE(tree.find("\"value\":6"), std::string::npos) << tree;

  const std::string res = panel_eval_action_source(
      src, "test.js", R"JSON({"id":"apply"})JSON", ctx, &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(res.find("\"notice\":\"Applied\""), std::string::npos) << res;
  EXPECT_NE(res.find("\"op\":\"set\""), std::string::npos) << res;
  EXPECT_NE(res.find("\"value\":0.2"), std::string::npos) << res;
}

TEST(PanelScript, StopsRunawayInfiniteLoopSafely) {
  const std::string src = "function render(ctx) { while (true) {} }";
  std::string err;
  const std::string out = panel_eval_render_source(src, "hang.js", "{}", &err);
  EXPECT_TRUE(out.empty());
  EXPECT_NE(err.find("timed out"), std::string::npos) << err;
}

TEST(PanelScript, ReportsMissingRenderFunctionCleanly) {
  std::string err;
  const std::string out =
      panel_eval_render_source("const x = 1;", "empty.js", "{}", &err);
  EXPECT_TRUE(out.empty());
  EXPECT_NE(err.find("render"), std::string::npos) << err;
}

TEST(PanelScript, ListsBundledShelfPanels) {
  const std::string listed = panel_list();
  EXPECT_NE(listed.find("Stagger\t"), std::string::npos) << listed;
  EXPECT_NE(listed.find("Quick Rig\t"), std::string::npos) << listed;
}

TEST(PanelScript, ResolvesSidecarCardUiAndEvaluatesVectorMapping) {
  const auto fx =
      doc_folders("effects").front() / "blur" / "Diagonal Blur.fs";
  const std::string ui = panel_card_ui_file(fx.generic_string());
  ASSERT_FALSE(ui.empty());
  EXPECT_NE(ui.find("Diagonal Blur.ui.js"), std::string::npos) << ui;

  std::string err;
  const std::string rendered = panel_eval_card_render(
      ui, R"JSON({"params":{"width":0.5,"angle":0}})JSON", &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(rendered.find("\"hide\":[\"width\",\"angle\"]"), std::string::npos)
      << rendered;
  EXPECT_NE(rendered.find("\"type\":\"svg\""), std::string::npos)
      << rendered;

  const std::string act = panel_eval_card_action(
      ui, R"JSON({"id":"compass","value":{"x":0.5,"y":0.71}})JSON", "{}", &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(act.find("\"width\":0.5"), std::string::npos) << act;
  EXPECT_NE(act.find("\"angle\":0.5"), std::string::npos) << act;
}

TEST(PanelScript, ExpressionSidecarsExcludeFromShelfAndRenderCleanly) {
  // Sidecar `.ui.js` files must never show up as standalone expressions or effects.
  for (const auto& p : doc_folder_files("expressions", ".js .css")) {
    const std::string name = p.filename().generic_string();
    EXPECT_FALSE(name.size() > 6 && name.compare(name.size() - 6, 6, ".ui.js") == 0)
        << name;
  }
  for (const auto& p : doc_folder_files("effects", ".wgsl .fs .mjs .js")) {
    const std::string name = p.filename().generic_string();
    EXPECT_FALSE(name.size() > 6 && name.compare(name.size() - 6, 6, ".ui.js") == 0)
        << name;
  }

  // Every bundled Expression `.ui.js` template resolves and renders a valid ui.svg tree.
  const auto exprDir = doc_folders("expressions").front();
  for (const char* expr : {"rigid_body.js", "wind.js", "Field.js", "wave.js",
                           "rise_to_sound.js", "Scale_Assist.js", "lyric.js"}) {
    const std::string uiFile = panel_card_ui_file((exprDir / expr).generic_string());
    ASSERT_FALSE(uiFile.empty()) << expr;
    std::string err;
    const std::string tree = panel_eval_card_render(uiFile, R"JSON({"params":{}})JSON", &err);
    ASSERT_TRUE(err.empty()) << expr << ": " << err;
    EXPECT_NE(tree.find("\"type\":\"svg\""), std::string::npos) << expr << ": " << tree;
  }

  // Jolt Rigid Body mode toggle switches Mass cleanly between 0 (Floor) and 1 (Dynamic).
  const std::string rbUi = panel_card_ui_file((exprDir / "rigid_body.js").generic_string());
  std::string err;
  const std::string floorAct = panel_eval_card_action(
      rbUi, R"JSON({"id":"mode","value":"Floor (Static)"})JSON", "{}", &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(floorAct.find("\"mass\":0"), std::string::npos) << floorAct;

  // Rise to Sound multi-handle drag (`ctx.state.drag`) and live `ctx.audio` rendering.
  const std::string audioUi =
      panel_card_ui_file((exprDir / "rise_to_sound.js").generic_string());
  const std::string liveTree = panel_eval_card_render(
      audioUi,
      R"JSON({"params":{"start":60,"end":1800},"audio":[0.2,0.5,0.9,0.7,0.4,0.3,0.2,0.1]})JSON",
      &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(liveTree.find("LIVE"), std::string::npos) << liveTree;

  // Grabbing near the lower edge (~u=0.17 for 60Hz) sets ephemeral `state.drag="lo"`.
  const std::string grabLo = panel_eval_card_action(
      audioUi,
      R"JSON({"id":"band","value":{"x":0.18,"y":0.5,"phase":"down"}})JSON",
      R"JSON({"params":{"start":60,"end":1800},"state":{}})JSON", &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(grabLo.find("\"drag\":\"lo\""), std::string::npos) << grabLo;
}

TEST(PanelScript, EvaluatesVstShowcaseAndNewUiPreludeHelpers) {
  const std::string listed = panel_list();
  EXPECT_NE(listed.find("VST Showcase\t"), std::string::npos) << listed;

  const auto panelPath = doc_folders("panels").front() / "VST Showcase.js";
  std::string err;
  for (const char* skin :
       {"Pop 3D", "Wavetable", "Hardware", "Studio", "Retro 98", "Kawaii"}) {
    const std::string ctx =
        std::string(R"JSON({"state":{"skin":")JSON") + skin + R"JSON("}})JSON";
    const std::string tree =
        panel_eval_render(panelPath.generic_string(), ctx, &err);
    ASSERT_TRUE(err.empty()) << skin << ": " << err;
    EXPECT_NE(tree.find("\"type\":\"scene3d\""), std::string::npos) << skin;
    EXPECT_NE(tree.find("\"type\":\"box\""), std::string::npos) << skin;
  }
}

}  // namespace
}  // namespace motolii

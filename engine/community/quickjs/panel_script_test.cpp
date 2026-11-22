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
  EXPECT_NE(rendered.find("\"type\":\"canvas\""), std::string::npos)
      << rendered;

  const std::string act = panel_eval_card_action(
      ui, R"JSON({"id":"compass","value":{"x":0.5,"y":0.71}})JSON", "{}", &err);
  ASSERT_TRUE(err.empty()) << err;
  EXPECT_NE(act.find("\"width\":0.5"), std::string::npos) << act;
  EXPECT_NE(act.find("\"angle\":0.5"), std::string::npos) << act;
}

}  // namespace
}  // namespace motolii

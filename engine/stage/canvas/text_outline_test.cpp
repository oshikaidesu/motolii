// tvg_text_outline() (stage/canvas/path_operations.h): the outlines of a text's
// letters as ThorVG sets them.
//
// The expected numbers are the font's own outlines as another reader of the
// same file gives them: fontTools 4.25 (TTFont, RecordingPen, BoundsPen) drew
// the glyphs of MOTOLII from Roboto-Medium.ttf one after another by their
// advances in hmtx (the font has no kern table), and gave each of the nine
// contours' left and right edges as fractions of the whole text's width. The
// font is the one Filament ships (third_party/filament_src/assets/fonts); the
// test is skipped where that file is not.

#include "stage/canvas/path_operations.h"

#include <gtest/gtest.h>
#include <thorvg.h>

#include <algorithm>
#include <filesystem>
#include <string>
#include <utility>
#include <vector>

namespace motolii {
namespace {

// The left and right edges of each contour of `words`, as fractions of the
// width of all of them. A curve is walked, since its handles lie outside it.
std::vector<std::pair<double, double>> Edges(const std::string& font,
                                             const char* words) {
  tvg::Initializer::init(0);
  std::vector<std::pair<double, double>> all;
  if (tvg::Text::load(font.c_str()) != tvg::Result::Success) return all;
  tvg::Text* t = tvg::Text::gen();
  t->font(std::filesystem::path(font).stem().string().c_str());
  t->size(100.f);
  t->text(words);
  std::vector<tvg::PathCommand> cmds;
  std::vector<tvg::Point> pts;
  tvg_text_outline(t, cmds, pts);
  tvg::Point at{0.f, 0.f};
  const auto reach = [&](double x) {
    all.back() = {std::min(all.back().first, x), std::max(all.back().second, x)};
  };
  for (size_t c = 0, p = 0; c < cmds.size(); ++c) switch (cmds[c]) {
      case tvg::PathCommand::MoveTo:
        at = pts[p++], all.push_back({at.x, at.x});
        break;
      case tvg::PathCommand::LineTo:
        at = pts[p++], reach(at.x);
        break;
      case tvg::PathCommand::CubicTo:
        for (int k = 1; k <= 32; ++k) {
          const double u = k / 32.0, v = 1.0 - u;
          reach(v * v * v * at.x + 3 * v * v * u * pts[p].x +
                3 * v * u * u * pts[p + 1].x + u * u * u * pts[p + 2].x);
        }
        at = pts[p + 2], p += 3;
        break;
      case tvg::PathCommand::Close:
        break;
    }
  tvg::Paint::rel(t);
  double low = 1e9, high = -1e9;
  for (const auto& e : all) low = std::min(low, e.first), high = std::max(high, e.second);
  for (auto& e : all)
    e = {(e.first - low) / (high - low), (e.second - low) / (high - low)};
  std::sort(all.begin(), all.end());
  return all;
}

TEST(TextOutline, LettersLieWhereTheFontsOwnOutlinesDo) {
  const std::string font =
      (std::filesystem::path(__FILE__).parent_path() /
       "../../third_party/filament_src/assets/fonts/Roboto-Medium.ttf")
          .lexically_normal()
          .string();
  if (!std::filesystem::is_regular_file(font)) GTEST_SKIP() << "no " << font;
  const std::vector<std::pair<double, double>> font_says = {
      {0.0, 0.1911},    {0.2235, 0.378},  {0.2559, 0.3457},
      {0.3971, 0.5448}, {0.5634, 0.7179}, {0.5958, 0.6856},
      {0.7502, 0.8671}, {0.8938, 0.9261}, {0.9678, 1.0}};
  const auto ours = Edges(font, "MOTOLII");
  ASSERT_EQ(ours.size(), font_says.size());
  for (size_t i = 0; i < ours.size(); ++i) {
    EXPECT_NEAR(ours[i].first, font_says[i].first, 1e-3) << "contour " << i;
    EXPECT_NEAR(ours[i].second, font_says[i].second, 1e-3) << "contour " << i;
  }
}

}  // namespace
}  // namespace motolii

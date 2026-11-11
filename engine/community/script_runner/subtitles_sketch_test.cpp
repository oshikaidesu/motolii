// A pasted .ass file runs as it is: the sites adapter recognises it by its
// [Script Info] section and wraps it into a sketch, and libass draws each frame
// (community/subtitles). The expected colours are read from the file by hand,
// not from the engine: ASS colours are &HAABBGGRR (the ASS specification,
// "Styles"), so SecondaryColour &H0000A0FF is orange (255, 160, 0), the colour
// of a syllable before \kf has filled it, PrimaryColour is white after, and
// \1c&H00FF60FF is (255, 96, 255), reached by \t(2000,2600,...) at 2.6 s.

#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

constexpr const char* kKaraoke = R"([Script Info]
ScriptType: v4.00+
PlayResX: 1280
PlayResY: 360

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Kara,Helvetica,96,&H00FFFFFF,&H0000A0FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:04.00,Kara,,0,0,0,,{\move(640,300,640,180,0,600)\fad(300,300)\frz-12\t(0,600,\frz0)\t(2000,2600,\fscx140\fscy140\1c&H00FF60FF&)}{\kf50}Mo{\kf40}to{\kf60}lii {\kf50}sings
)";

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

struct Counted {
  int orange = 0, pink = 0;
};
// Counts the frame's pixels of either colour, at `ms`.
Counted At(Script& s, int ms) {
  const std::vector<uint8_t> px = s.bytes(
      "{const f=__subtitles_frame(" + std::to_string(ms) +
      ");globalThis.__bytes=f?new Uint8Array(f.data):new Uint8Array(0)}");
  Counted c;
  for (size_t i = 0; i + 3 < px.size(); i += 4) {
    const int r = px[i], g = px[i + 1], b = px[i + 2], a = px[i + 3];
    if (a < 128) continue;
    if (r > 230 && g > 130 && g < 190 && b < 40) ++c.orange;
    if (r > 230 && g > 70 && g < 120 && b > 230) ++c.pink;
  }
  return c;
}

TEST(PastedSubtitles,
     AnAssFileIsASketchOfItsOwnSizeAndItsKaraokeFillsAndTurns) {
  const fs::path file = fs::temp_directory_path() / "motolii_karaoke.ass";
  std::ofstream(file) << kKaraoke;
  Script s(file.string(), P5());
  ASSERT_TRUE(s.ok()) << s.trouble();
  ASSERT_TRUE(s.sketch());
  EXPECT_TRUE(s.flat());
  EXPECT_EQ(s.width(), 1280);
  EXPECT_EQ(s.height(), 360);
  const Counted early = At(s, 400), sung = At(s, 3000);
  EXPECT_GT(early.orange, 200)
      << "after \\fad's 300 ms and before \\kf fills it, a syllable is orange";
  EXPECT_EQ(early.pink, 0);
  EXPECT_EQ(sung.orange, 0) << "by 2 s every syllable is sung";
  EXPECT_GT(sung.pink, 2000) << "\\t turned \\1c to pink by 2.6 s";
  EXPECT_EQ(s.said("__to(200),'drawn'"), "drawn");
  fs::remove(file);
}

}  // namespace
}  // namespace motolii

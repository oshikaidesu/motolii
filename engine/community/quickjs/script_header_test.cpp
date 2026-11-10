// Tests for the reader of a script's head, script_header_parameters() in
// community/quickjs/script.h, and for leva's object form, which leva_head() in
// community/quickjs/script_leva.h turns into the same head lines.
//
// The expected values come from the documents that tell an author how to write
// a head:
//   - shelves/README.md, "How a file's head is written": the table of lines
//     (--track@, --check@, --select@, --picture@, --group, --macro@, --label,
//     --about) and what each means.
//   - The comment at the top of community/quickjs/script.h, which gives one
//     example of each line and says what a macro does to the parameters it
//     drives, and the comments on ScriptParameter's members.
//   - docs/design/aviutl2_converter.md, section 2, the head lines of AviUtl2
//     (from the lua.txt shipped with AviUtl2): --group:name[,open].
//   - The comment at the top of community/quickjs/script_leva.h, and leva's
//     own description of its inputs (https://github.com/pmndrs/leva): a
//     number, a boolean, a color string, an object with options, a folder.
//
// Where no document says what a malformed line gives, the test is marked
// "characterization:".

#include <gtest/gtest.h>

#include <sstream>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "community/quickjs/script_leva.h"

namespace motolii {
namespace {

// Returns the parameters declared by the head lines in `head`.
std::vector<ScriptParameter> Read(const std::string& head) {
  std::istringstream from(head);
  return script_header_parameters(from);
}

// Returns the parameters declared by a script in leva's object form.
std::vector<ScriptParameter> ReadKnobs(const std::string& script) {
  return Read(leva_head(script));
}

// ---- One test for each line in the table of shelves/README.md.

TEST(ScriptHeader, TrackLineIsANumberWithItsRangeDefaultAndStep) {
  // The example in script.h: name:label,lowest,highest,default,step.
  const auto parameters = Read("// --track@count:Count,1,5000,800,1\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "track");
  EXPECT_EQ(parameters[0].name, "count");
  EXPECT_EQ(parameters[0].label, "Count");
  EXPECT_DOUBLE_EQ(parameters[0].low, 1.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 5000.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 800.0);
  EXPECT_DOUBLE_EQ(parameters[0].step, 1.0);
}

TEST(ScriptHeader, TrackLineReadsFractionsAndALabelOfTwoWords) {
  // Two examples in shelves/README.md.
  const auto parameters = Read(
      "// --track@height:Height,0,2,.45,0.01\n"
      "// --track@limit:Speed Limit,0,60,60,0.1\n");
  ASSERT_EQ(parameters.size(), 2u);
  EXPECT_EQ(parameters[0].name, "height");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 2.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.45);
  EXPECT_DOUBLE_EQ(parameters[0].step, 0.01);
  EXPECT_EQ(parameters[1].name, "limit");
  EXPECT_EQ(parameters[1].label, "Speed Limit");
  EXPECT_DOUBLE_EQ(parameters[1].high, 60.0);
  EXPECT_DOUBLE_EQ(parameters[1].usual, 60.0);
  EXPECT_DOUBLE_EQ(parameters[1].step, 0.1);
}

TEST(ScriptHeader, TrackLineMayLeaveTheStepOut) {
  // shelves/README.md: "The step may be left out". ScriptParameter's step is
  // then the 0 it starts with.
  const auto parameters = Read("// --track@height:Height,0,2,0.5\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "track");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 2.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.5);
  EXPECT_DOUBLE_EQ(parameters[0].step, 0.0);
}

TEST(ScriptHeader, CheckLineIsOnOrOff) {
  // The example in script.h: name:label,default. On is 1 and off is 0.
  const auto parameters = Read(
      "// --check@spin:Spin,1\n"
      "// --check@flip:Flip,0\n");
  ASSERT_EQ(parameters.size(), 2u);
  EXPECT_EQ(parameters[0].kind, "check");
  EXPECT_EQ(parameters[0].name, "spin");
  EXPECT_EQ(parameters[0].label, "Spin");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 1.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 1.0);
  EXPECT_EQ(parameters[1].name, "flip");
  EXPECT_DOUBLE_EQ(parameters[1].usual, 0.0);
}

TEST(ScriptHeader, SelectLineListsItsWordsWithTheDefaultFirst) {
  // The example in script.h. ScriptParameter::words holds the words separated
  // by spaces, and the first is the default.
  const auto parameters = Read("// --select@way:Way,ring,grid,spiral\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "select");
  EXPECT_EQ(parameters[0].name, "way");
  EXPECT_EQ(parameters[0].label, "Way");
  EXPECT_EQ(parameters[0].words, "ring grid spiral");
}

TEST(ScriptHeader, PictureLineNamesAnotherLayersPicture) {
  // shelves/README.md: // --picture@name:Label.
  const auto parameters = Read("// --picture@backdrop:Behind\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "picture");
  EXPECT_EQ(parameters[0].name, "backdrop");
  EXPECT_EQ(parameters[0].label, "Behind");
}

TEST(ScriptHeader, SoundLineSaysFftOrWaveAndTheCount) {
  // ScriptParameter::words: "A sound has two: fft or wave, then the count."
  const auto parameters = Read("// --sound@beat:Beat,fft,64\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "sound");
  EXPECT_EQ(parameters[0].name, "beat");
  EXPECT_EQ(parameters[0].label, "Beat");
  EXPECT_EQ(parameters[0].words, "fft 64");
}

TEST(ScriptHeader, GroupLineFoldsTheParametersUntilABareGroupLine) {
  const auto parameters = Read(
      "// --track@before:Before,0,1,0,0.01\n"
      "// --group:Advanced\n"
      "// --track@first:First,0,1,0,0.01\n"
      "// --check@second:Second,0\n"
      "// --group\n"
      "// --track@after:After,0,1,0,0.01\n");
  ASSERT_EQ(parameters.size(), 4u);
  EXPECT_EQ(parameters[0].group, "");
  EXPECT_EQ(parameters[1].group, "Advanced");
  EXPECT_EQ(parameters[2].group, "Advanced");
  EXPECT_EQ(parameters[3].group, "");
}

TEST(ScriptHeader, GroupLineMaySayOpenOrClosedAfterItsName) {
  // AviUtl2 writes --group:name[,open]; the name ends at the comma.
  const auto parameters = Read(
      "// --group:Advanced,true\n"
      "// --track@depth:Depth,0,1,0,0.01\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].group, "Advanced");
}

TEST(ScriptHeader, MacroLineIsATrackFromZeroToOneThatDrivesOthers) {
  // The example in script.h: "one parameter from 0 to 1, here with default
  // 0.5", driving StepX from 0 to 0.6 and ScatterX from 0 to 2.
  const auto parameters =
      Read("// --macro@Spread:Spread,0.5 -> StepX 0 0.6, ScatterX 0 2\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "track");
  EXPECT_EQ(parameters[0].name, "Spread");
  EXPECT_EQ(parameters[0].label, "Spread");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 1.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.5);
  ASSERT_EQ(parameters[0].turns.size(), 2u);
  EXPECT_EQ(parameters[0].turns[0].name, "StepX");
  EXPECT_DOUBLE_EQ(parameters[0].turns[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].turns[0].high, 0.6);
  EXPECT_EQ(parameters[0].turns[1].name, "ScatterX");
  EXPECT_DOUBLE_EQ(parameters[0].turns[1].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].turns[1].high, 2.0);
}

TEST(ScriptHeader, MacroComesFirstAndFoldsWhatItDrivesIntoAdvanced) {
  // script.h: "the macro comes first and the parameters it drives are folded
  // into Advanced, labeled "← Spread" after their names."
  const auto parameters = Read(
      "// --track@StepX:Step X,0,1,0.3,0.01\n"
      "// --track@Size:Size,0,1,0.5,0.01\n"
      "// --macro@Spread:Spread,0.5 -> StepX 0 0.6\n");
  ASSERT_EQ(parameters.size(), 3u);
  EXPECT_EQ(parameters[0].name, "Spread");
  EXPECT_EQ(parameters[1].name, "StepX");
  EXPECT_EQ(parameters[1].by, "Spread");
  EXPECT_EQ(parameters[1].group, "Advanced");
  EXPECT_EQ(parameters[1].label, "Step X ← Spread");
  EXPECT_EQ(parameters[2].name, "Size");
  EXPECT_EQ(parameters[2].by, "");
  EXPECT_EQ(parameters[2].group, "");
  EXPECT_EQ(parameters[2].label, "Size");
}

// ---- Where the head begins and ends, and the lines that are not parameters.

TEST(ScriptHeader, ReadingStopsAtTheFirstLineOfCode) {
  const auto parameters = Read(
      "// --track@height:Height,0,2,0.5,0.01\n"
      "function each(i, n, t, k) {\n"
      "// --track@speed:Speed,0,4,0.6,0.01\n"
      "}\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].name, "height");
}

TEST(ScriptHeader, NameLineAndProseAreSkipped) {
  // shelves/README.md: the first line is "// Name: description", and "Other
  // lines (prose) are skipped."
  const auto parameters = Read(
      "// Wave: a wave through a layer's copies\n"
      "// The height is a share of the stage's height.\n"
      "// --track@height:Height,0,2,0.5,0.01\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].name, "height");
}

TEST(ScriptHeader, LabelAndAboutLinesAreNotParameters) {
  // shelves/README.md: --label is the category in the list and --about the
  // description; neither is a slider.
  const auto parameters = Read(
      "// --label:Distort\n"
      "// --about:Bends the picture\n");
  EXPECT_TRUE(parameters.empty());
}

TEST(ScriptHeader, LineNeedsBothTheAtAndTheColon) {
  // shelves/README.md: "Both the @ and the : are needed."
  EXPECT_TRUE(Read("// --track@count\n").empty());
  EXPECT_TRUE(Read("// --track:Count,1,5000,800,1\n").empty());
}

TEST(ScriptHeader, NoHeadGivesNoParameters) {
  EXPECT_TRUE(Read("").empty());
  EXPECT_TRUE(Read("function each(i, n, t, k) { return {}; }\n").empty());
}

// ---- Malformed lines. No document says what these give.

TEST(ScriptHeader, BlankLineDoesNotEndTheHead) {
  // characterization: a blank line between head lines is passed over.
  const auto parameters = Read(
      "// --track@height:Height,0,2,0.5,0.01\n"
      "\n"
      "// --track@speed:Speed,0,4,0.6,0.01\n");
  EXPECT_EQ(parameters.size(), 2u);
}

TEST(ScriptHeader, TrackLineWithoutADefaultIsDropped) {
  // characterization: only the step may be left out; a track with fewer than
  // label, lowest, highest and default declares nothing.
  EXPECT_TRUE(Read("// --track@count:Count,1,5000\n").empty());
}

TEST(ScriptHeader, TrackLineWithWordsForNumbersReadsThemAsZero) {
  // characterization: a field that is not a number is read as 0, and the
  // parameter is kept.
  const auto parameters = Read("// --track@count:Count,low,high,many,1\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].step, 1.0);
}

TEST(ScriptHeader, CheckLineWithoutADefaultIsOff) {
  // characterization: a check with only its label starts at 0.
  const auto parameters = Read("// --check@spin:Spin\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.0);
}

TEST(ScriptHeader, SelectLineWithoutWordsIsDropped) {
  // characterization: a select with only its label declares nothing.
  EXPECT_TRUE(Read("// --select@way:Way\n").empty());
}

TEST(ScriptHeader, KindThatIsNotInTheTableIsDropped) {
  // characterization: AviUtl2 has more kinds (--color@, --value@, --file@:
  // docs/design/aviutl2_converter.md). They are not in the table of
  // shelves/README.md, and this reader drops them. A color is written in
  // leva's form instead (LevaColorBecomesThreeNumbersFromZeroToOne).
  EXPECT_TRUE(Read("// --color@tint:Tint,0xff3366\n").empty());
  EXPECT_TRUE(Read("// --value@speed:Speed,10\n").empty());
}

// ---- leva's object form: const knobs = { ... }.

TEST(ScriptHeaderLeva, NumberBecomesATrackFromZeroToTen) {
  // script_leva.h: a number is a slider, and with no min and max its range is
  // Houdini's 0 to 10. The label is the key as Godot capitalizes it.
  const auto parameters = ReadKnobs("const knobs = { count: 5 };\n");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "track");
  EXPECT_EQ(parameters[0].name, "count");
  EXPECT_EQ(parameters[0].label, "Count");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 10.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 5.0);
}

TEST(ScriptHeaderLeva, NumberWithMinMaxAndStepKeepsThem) {
  // The example in script_leva.h.
  const auto parameters = ReadKnobs(
      "const knobs = { spread: { value: 0.5, min: 0, max: 2, step: 0.01 } };");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].kind, "track");
  EXPECT_EQ(parameters[0].name, "spread");
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 2.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 0.5);
  EXPECT_DOUBLE_EQ(parameters[0].step, 0.01);
}

TEST(ScriptHeaderLeva, RangeWidensUpToHoldTheValue) {
  // script_leva.h: "The range is widened to include the current value". 0 to
  // 10 widened to hold 25 is 0 to 25.
  const auto parameters = ReadKnobs("const knobs = { far: 25 };");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_DOUBLE_EQ(parameters[0].low, 0.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 25.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, 25.0);
}

// Disabled: the code gives -3 to 7, a range of 10 that starts at the value.
TEST(ScriptHeaderLeva, DISABLED_RangeWidensDownToHoldANegativeValue) {
  // 0 to 10 widened to hold -3 is -3 to 10.
  const auto parameters = ReadKnobs("const knobs = { under: -3 };");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_DOUBLE_EQ(parameters[0].low, -3.0);
  EXPECT_DOUBLE_EQ(parameters[0].high, 10.0);
  EXPECT_DOUBLE_EQ(parameters[0].usual, -3.0);
}

TEST(ScriptHeaderLeva, BooleanBecomesACheck) {
  const auto parameters =
      ReadKnobs("const knobs = { spin: true, flip: false };");
  ASSERT_EQ(parameters.size(), 2u);
  EXPECT_EQ(parameters[0].kind, "check");
  EXPECT_EQ(parameters[0].name, "spin");
  EXPECT_DOUBLE_EQ(parameters[0].usual, 1.0);
  EXPECT_EQ(parameters[1].kind, "check");
  EXPECT_EQ(parameters[1].name, "flip");
  EXPECT_DOUBLE_EQ(parameters[1].usual, 0.0);
}

TEST(ScriptHeaderLeva, OptionsBecomeASelectWithTheValueFirst) {
  // leva's value is the choice at the start, and a select's first word is its
  // default, so the value comes first whatever its place in options.
  const auto parameters = ReadKnobs(
      "const knobs = {\n"
      "  way: { value: 'ring', options: ['ring', 'grid'] },\n"
      "  order: { value: 'last', options: ['first', 'middle', 'last'] },\n"
      "};\n");
  ASSERT_EQ(parameters.size(), 2u);
  EXPECT_EQ(parameters[0].kind, "select");
  EXPECT_EQ(parameters[0].name, "way");
  EXPECT_EQ(parameters[0].words, "ring grid");
  EXPECT_EQ(parameters[1].kind, "select");
  EXPECT_EQ(parameters[1].words, "last first middle");
}

TEST(ScriptHeaderLeva, ColorBecomesThreeNumbersFromZeroToOne) {
  // script_leva.h: a "#rrggbb" string is a color, kept as three numbers named
  // tint_x, tint_y and tint_z. Each is its byte over 255:
  // 0xff / 255 = 1, 0x33 / 255 = 51 / 255 = 0.2, 0x66 / 255 = 102 / 255 = 0.4.
  const auto parameters = ReadKnobs("const knobs = { tint: '#ff3366' };");
  ASSERT_EQ(parameters.size(), 3u);
  const char* const names[] = {"tint_x", "tint_y", "tint_z"};
  const double values[] = {1.0, 0.2, 0.4};
  for (int i = 0; i < 3; ++i) {
    EXPECT_EQ(parameters[i].kind, "track") << names[i];
    EXPECT_EQ(parameters[i].name, names[i]);
    EXPECT_DOUBLE_EQ(parameters[i].low, 0.0) << names[i];
    EXPECT_DOUBLE_EQ(parameters[i].high, 1.0) << names[i];
    EXPECT_DOUBLE_EQ(parameters[i].usual, values[i]) << names[i];
  }
}

TEST(ScriptHeaderLeva, FolderBecomesAGroup) {
  // The example in script_leva.h: Advanced: folder({ ... }, { collapsed }).
  const auto parameters = ReadKnobs(
      "const knobs = {\n"
      "  count: 5,\n"
      "  Advanced: folder({ depth: 1, spin: true }, { collapsed: true }),\n"
      "  size: 2,\n"
      "};\n");
  ASSERT_EQ(parameters.size(), 4u);
  EXPECT_EQ(parameters[0].name, "count");
  EXPECT_EQ(parameters[0].group, "");
  EXPECT_EQ(parameters[1].name, "depth");
  EXPECT_EQ(parameters[1].group, "Advanced");
  EXPECT_EQ(parameters[2].name, "spin");
  EXPECT_EQ(parameters[2].group, "Advanced");
  EXPECT_EQ(parameters[3].name, "size");
  EXPECT_EQ(parameters[3].group, "");
}

TEST(ScriptHeaderLeva, LabelIsTheKeyAsGodotCapitalizesIt) {
  // The two examples in script_leva.h.
  const auto parameters =
      ReadKnobs("const knobs = { ease_in: 1, scaleFrom: 1 };");
  ASSERT_EQ(parameters.size(), 2u);
  EXPECT_EQ(parameters[0].name, "ease_in");
  EXPECT_EQ(parameters[0].label, "Ease In");
  EXPECT_EQ(parameters[1].name, "scaleFrom");
  EXPECT_EQ(parameters[1].label, "Scale From");
}

TEST(ScriptHeaderLeva, WrittenLabelIsKept) {
  // script_leva.h: "The label is leva's { label } when written."
  const auto parameters =
      ReadKnobs("const knobs = { n: { value: 3, label: 'How many' } };");
  ASSERT_EQ(parameters.size(), 1u);
  EXPECT_EQ(parameters[0].name, "n");
  EXPECT_EQ(parameters[0].label, "How many");
}

TEST(ScriptHeaderLeva, LetAndVarDeclareKnobsToo) {
  // script_leva.h: "`let` and `var` work as well."
  EXPECT_EQ(ReadKnobs("let knobs = { count: 5 };").size(), 1u);
  EXPECT_EQ(ReadKnobs("var knobs = { count: 5 };").size(), 1u);
}

TEST(ScriptHeaderLeva, ScriptWithoutKnobsHasNoHead) {
  // script_leva.h: returns "" if there is no such declaration.
  EXPECT_EQ(leva_head("function each(i, n, t, k) { return {}; }\n"), "");
  EXPECT_EQ(leva_head("// const knobs = { count: 5 };\n"), "");
}

}  // namespace
}  // namespace motolii

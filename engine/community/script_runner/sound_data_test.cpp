// getByteFrequencyData() and getFloatTimeDomainData() as a script sees them:
// the two global functions that Script::reads_sound answers (script_runner.h).
//
// They are the methods of the Web's AnalyserNode of the same names
// (www.w3.org/TR/webaudio-1.1/#AnalyserNode-methods), with the layer's number
// in front and the second at the end. The rules checked here are that
// specification's: a byte is the floor of 255 times the strength, cut to 0 and
// 255; an array shorter than the data takes the first part; the part of an
// array past the end of the data is left as it was; an array of the wrong kind
// is a TypeError; nothing is returned. Every other expected number is one this
// file put in: the arguments written in the script, what the arrays held
// before, and the numbers the test's reader answers with. The tests were
// written from the comment in script_runner.h, not from the code that
// implements it.

#include <gtest/gtest.h>

#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

// What the test's reader answers with: one number per pitch, and the samples
// of the wave.
struct Sound {
  std::vector<float> spectrum;
  std::vector<float> wave;
};

// What the script last asked the reader for, of each kind. Empty if it never
// asked for that kind.
struct Seen {
  std::vector<double> spectrum;  // layer, t
  std::vector<double> wave;      // layer, t
};

// Runs the script `body` and returns the x of each of its n copies at second
// 0. With `sound`, the script gets a reader that answers with sound->spectrum
// or sound->wave and notes in `seen`, if given, what it was asked. Without it,
// the script gets no reader.
std::vector<double> Answers(const std::string& body, int n, const Sound* sound,
                            Seen* seen = nullptr) {
  const auto* test = ::testing::UnitTest::GetInstance()->current_test_info();
  const fs::path file = fs::temp_directory_path() /
                        (std::string("motolii_") + test->test_suite_name() +
                         test->name() + ".js");
  std::ofstream(file) << body;
  std::vector<double> xs;
  {
    Script s(file.string(), P5());
    EXPECT_TRUE(s.ok()) << s.trouble();
    if (sound) {
      s.reads_sound([sound, seen](int layer, bool spectrum, double second) {
        if (seen) {
          (spectrum ? seen->spectrum : seen->wave) = {double(layer), second};
        }
        return spectrum ? sound->spectrum : sound->wave;
      });
    }
    if (s.ok()) {
      for (const ScriptCopy& c : s.copies(n, 0, {}, {}, 1.0)) xs.push_back(c.x);
    }
  }
  fs::remove(file);
  return xs;
}

void Same(const std::vector<double>& got, const std::vector<double>& want) {
  ASSERT_EQ(got.size(), want.size());
  for (size_t i = 0; i < want.size(); ++i)
    EXPECT_DOUBLE_EQ(got[i], want[i]) << "number " << i;
}

// A script whose each() works out the array `js` and hands back one of its
// numbers per copy, so n copies carry n numbers.
std::string Each(const std::string& js) {
  return "function each(i, n, t, k) { const out = " + js +
         "; return { x: out[i] }; }\n";
}

// The JavaScript that makes `array`, has `function` fill it for layer 1 at
// second 0, and gives its length followed by what it holds then. The length
// comes first so that a script that failed (every copy's x is 0 then) does not
// pass for an array of zeros.
std::string Filled(const std::string& function, const std::string& array) {
  return "((a) => (" + function + "(1, a, 0), [a.length, ...a]))(" + array +
         ")";
}

// 255 * 0.5 is 127.5 and 255 * 0.999 is 254.745: the floor, not the nearest
// whole number. 255 * 0.25 is 63.75.
TEST(GetByteFrequencyData, AByteIsTheFloorOf255TimesTheNumberCutTo0And255) {
  const Sound sound{{0.0f, 1.0f, 0.5f, 0.999f, 1.5f, -0.2f, 0.25f}, {}};
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(7).fill(9)")),
              8, &sound),
      {7, 0, 255, 127, 254, 255, 0, 63});
}

// A Float32Array holds the reader's floats as they are, so each comes back as
// the same float, 0.123f included.
TEST(GetFloatTimeDomainData, TheSamplesArriveUnchanged) {
  const Sound sound{{}, {0.0f, 0.5f, -0.5f, 1.0f, -1.0f, 0.123f}};
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(6).fill(9)")),
               7, &sound),
       {6, 0, 0.5, -0.5, 1, -1, double(0.123f)});
}

// The copies are asked for at second 0, so 1.5 and 0.25 can only be the
// seconds written in the script.
TEST(SoundData, TheReaderIsToldTheLayerTheKindAndTheSecond) {
  const Sound sound{{0.5f, 0.5f}, {0.5f, 0.5f}};
  Seen seen;
  Same(Answers(Each("(getByteFrequencyData(7, new Uint8Array(2), 1.5), [1])"),
               1, &sound, &seen),
       {1});
  Same(seen.spectrum, {7, 1.5});
  Same(seen.wave, {});

  seen = Seen();
  Same(Answers(
           Each("(getFloatTimeDomainData(3, new Float32Array(2), 0.25), [1])"),
           1, &sound, &seen),
       {1});
  Same(seen.wave, {3, 0.25});
  Same(seen.spectrum, {});
}

TEST(SoundData, AnArrayShorterThanTheSoundTakesTheFirstPart) {
  const Sound sound{{1.0f, 0.5f, 0.25f, 0.75f}, {0.25f, -0.5f, 0.75f, 1.0f}};
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(2).fill(9)")),
              3, &sound),
      {2, 255, 127});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(2).fill(9)")),
               3, &sound),
       {2, 0.25, -0.5});
}

// The 9s and the 0.75s are what the arrays held before the call.
TEST(SoundData, AnArrayLongerThanTheSoundKeepsWhatItHeldInTheRest) {
  const Sound sound{{1.0f, 0.5f}, {0.25f, -0.5f}};
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(5).fill(9)")),
              6, &sound),
      {5, 255, 127, 9, 9, 9});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(5).fill(0.75)")),
               6, &sound),
       {5, 0.25, -0.5, 0.75, 0.75, 0.75});
}

TEST(SoundData, TheArrayIsFilledWithZerosWhileNoReaderIsSet) {
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(3).fill(9)")),
              4, nullptr),
      {3, 0, 0, 0});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(3).fill(0.75)")),
               4, nullptr),
       {3, 0, 0, 0});
}

// A reader that answers with no numbers at all is a layer with no sound.
TEST(SoundData, TheArrayIsFilledWithZerosWhenTheLayerHasNoSound) {
  const Sound none;
  Seen seen;
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(3).fill(9)")),
              4, &none, &seen),
      {3, 0, 0, 0});
  Same(seen.spectrum, {1, 0});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(3).fill(0.75)")),
               4, &none, &seen),
       {3, 0, 0, 0});
  Same(seen.wave, {1, 0});
}

// 1 is a call that threw nothing, 2 one that threw a TypeError and 3 one that
// threw something else, so that a script that failed (every copy's x is 0
// then) passes for none of them. The last two calls are given the right kind
// of array.
TEST(SoundData, TheWrongKindOfArrayThrowsATypeError) {
  const std::string threw =
      "function threw(call) {\n"
      "  try { call(); return 1; }\n"
      "  catch (e) { return e instanceof TypeError ? 2 : 3; }\n"
      "}\n";
  const std::string calls =
      "[threw(() => getByteFrequencyData(1, [9, 9, 9], 0)),"
      " threw(() => getByteFrequencyData(1, new Float32Array(3), 0)),"
      " threw(() => getFloatTimeDomainData(1, [9, 9, 9], 0)),"
      " threw(() => getFloatTimeDomainData(1, new Uint8Array(3), 0)),"
      " threw(() => getByteFrequencyData(1, new Uint8Array(3), 0)),"
      " threw(() => getFloatTimeDomainData(1, new Float32Array(3), 0))]";
  const Sound sound{{0.5f, 0.5f, 0.5f}, {0.5f, 0.5f, 0.5f}};
  Same(Answers(threw + Each(calls), 6, &sound), {2, 2, 2, 2, 1, 1});
  Same(Answers(threw + Each(calls), 6, nullptr), {2, 2, 2, 2, 1, 1});
}

// 1 is undefined and 2 anything else.
TEST(SoundData, BothReturnUndefined) {
  const std::string returned =
      "[getByteFrequencyData(1, new Uint8Array(2), 0) === undefined ? 1 : 2,"
      " getFloatTimeDomainData(1, new Float32Array(2), 0) === undefined"
      " ? 1 : 2]";
  const Sound sound{{0.5f, 0.5f}, {0.5f, 0.5f}};
  Same(Answers(Each(returned), 2, &sound), {1, 1});
  Same(Answers(Each(returned), 2, nullptr), {1, 1});
}

}  // namespace
}  // namespace motolii

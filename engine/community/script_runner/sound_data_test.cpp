// getFloatFrequencyData(), getByteFrequencyData() and getFloatTimeDomainData()
// as a script sees them: the three global functions that Script::reads_sound
// answers (script_runner.h).
//
// They are the methods of the Web's AnalyserNode of the same names
// (www.w3.org/TR/webaudio-1.1/#AnalyserNode-methods), with the layer's number
// in front and the second at the end. The rules checked here are that
// specification's, with the minDecibels of -100 and the maxDecibels of -30 an
// AnalyserNode starts with: a byte is the floor of 255 / 70 x (decibels + 100),
// cut to 0 and 255; an array shorter than the data takes the first part; the
// part of an array past the end of the data is left as it was; an array of the
// wrong kind is a TypeError; nothing is returned. Silence, which is what a
// layer with no sound gives, is bytes and samples of 0 and decibels of minus
// infinity. Every other expected number is one this file put in: the arguments
// written in the script, what the arrays held before, and the numbers the
// test's reader answers with. The tests were written from the comment in
// script_runner.h, not from the code that implements it.

#include <gtest/gtest.h>

#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <limits>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

// The decibels of a pitch with no sound.
const float kNoSound = -std::numeric_limits<float>::infinity();

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

// What the test's reader answers with: the decibels of each pitch, and the
// samples of the wave.
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

// The same, but each number the array holds then is given as 1 if it is minus
// infinity and 0 if it is anything else. Minus infinity is looked at inside
// the script because a copy's x may not carry it out.
std::string MinusInfinities(const std::string& function,
                            const std::string& array) {
  return "((a) => (" + function +
         "(1, a, 0),"
         " [a.length, ...Array.from(a, (v) => (v === -Infinity ? 1 : 0))]))(" +
         array + ")";
}

// The expected bytes, worked out by hand from 255 / 70 x (decibels + 100):
//   -100      255 / 70 x 0      = 0             0, the lower end
//   -30       255 / 70 x 70     = 255           255, the upper end
//   -120      under -100                        0
//   0         over -30                          255
//   -infinity under -100                        0
//   -65       255 / 70 x 35     = 127.5         127 (the nearest is 128)
//   -40       255 / 70 x 60     = 218.571...    218 (the nearest is 219)
//   -99       255 / 70 x 1      = 3.642...      3   (the nearest is 4)
//   -99.75    255 / 70 x 0.25   = 0.910...      0   (the nearest is 1)
//   -50       255 / 70 x 50     = 182.142...    182
//   -30.25    255 / 70 x 69.75  = 254.089...    254
// Every one of these decibels is a float exactly, and none of the products
// between the ends is nearer than 0.08 to a whole number, so rounding inside
// the arithmetic cannot move a byte.
TEST(GetByteFrequencyData, AByteIsTheFloorOf255Over70TimesDecibelsPlus100) {
  const Sound sound{{-100.0f, -30.0f, -120.0f, 0.0f, kNoSound, -65.0f, -40.0f,
                     -99.0f, -99.75f, -50.0f, -30.25f},
                    {}};
  Same(Answers(
           Each(Filled("getByteFrequencyData", "new Uint8Array(11).fill(9)")),
           12, &sound),
       {11, 0, 255, 0, 255, 0, 127, 218, 3, 0, 182, 254});
}

// A Float32Array holds the reader's floats as they are, so each comes back as
// the same float, -45.3f included, and no decibel is cut to the -100 and -30
// of the bytes. The second script looks for the minus infinity, which is the
// last of the eight; the array of seven stops before it.
TEST(GetFloatFrequencyData, TheDecibelsArriveUnchanged) {
  const Sound sound{
      {-100.0f, -30.0f, -65.5f, 0.0f, 12.25f, -160.0f, -45.3f, kNoSound}, {}};
  Same(Answers(
           Each(Filled("getFloatFrequencyData", "new Float32Array(7).fill(9)")),
           8, &sound),
       {7, -100, -30, -65.5, 0, 12.25, -160, double(-45.3f)});
  Same(Answers(Each(MinusInfinities("getFloatFrequencyData",
                                    "new Float32Array(8).fill(9)")),
               9, &sound),
       {8, 0, 0, 0, 0, 0, 0, 0, 1});
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

// The copies are asked for at second 0, so 1.5, 2.5 and 0.25 can only be the
// seconds written in the script.
TEST(SoundData, TheReaderIsToldTheLayerTheKindAndTheSecond) {
  const Sound sound{{-65.0f, -65.0f}, {0.5f, 0.5f}};
  Seen seen;
  Same(Answers(Each("(getByteFrequencyData(7, new Uint8Array(2), 1.5), [1])"),
               1, &sound, &seen),
       {1});
  Same(seen.spectrum, {7, 1.5});
  Same(seen.wave, {});

  seen = Seen();
  Same(
      Answers(Each("(getFloatFrequencyData(5, new Float32Array(2), 2.5), [1])"),
              1, &sound, &seen),
      {1});
  Same(seen.spectrum, {5, 2.5});
  Same(seen.wave, {});

  seen = Seen();
  Same(Answers(
           Each("(getFloatTimeDomainData(3, new Float32Array(2), 0.25), [1])"),
           1, &sound, &seen),
       {1});
  Same(seen.wave, {3, 0.25});
  Same(seen.spectrum, {});
}

// -30 dB is the byte 255 and -65 dB the byte 127, as worked out above.
TEST(SoundData, AnArrayShorterThanTheSoundTakesTheFirstPart) {
  const Sound sound{{-30.0f, -65.0f, -50.0f, -40.0f},
                    {0.25f, -0.5f, 0.75f, 1.0f}};
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(2).fill(9)")),
              3, &sound),
      {2, 255, 127});
  Same(Answers(
           Each(Filled("getFloatFrequencyData", "new Float32Array(2).fill(9)")),
           3, &sound),
       {2, -30, -65});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(2).fill(9)")),
               3, &sound),
       {2, 0.25, -0.5});
}

// The 9s and the 0.75s are what the arrays held before the call.
TEST(SoundData, AnArrayLongerThanTheSoundKeepsWhatItHeldInTheRest) {
  const Sound sound{{-30.0f, -65.0f}, {0.25f, -0.5f}};
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(5).fill(9)")),
              6, &sound),
      {5, 255, 127, 9, 9, 9});
  Same(Answers(Each(Filled("getFloatFrequencyData",
                           "new Float32Array(5).fill(0.75)")),
               6, &sound),
       {5, -30, -65, 0.75, 0.75, 0.75});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(5).fill(0.75)")),
               6, &sound),
       {5, 0.25, -0.5, 0.75, 0.75, 0.75});
}

// Silence is bytes of 0, samples of 0 and decibels of minus infinity, in the
// whole array: none of the 9s and 0.75s it held before is left.
TEST(SoundData, TheArrayIsFilledWithSilenceWhileNoReaderIsSet) {
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(3).fill(9)")),
              4, nullptr),
      {3, 0, 0, 0});
  Same(Answers(Each(MinusInfinities("getFloatFrequencyData",
                                    "new Float32Array(3).fill(0.75)")),
               4, nullptr),
       {3, 1, 1, 1});
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(3).fill(0.75)")),
               4, nullptr),
       {3, 0, 0, 0});
}

// A reader that answers with no numbers at all is a layer with no sound. It
// is still asked, each time.
TEST(SoundData, TheArrayIsFilledWithSilenceWhenTheLayerHasNoSound) {
  const Sound none;
  Seen seen;
  Same(
      Answers(Each(Filled("getByteFrequencyData", "new Uint8Array(3).fill(9)")),
              4, &none, &seen),
      {3, 0, 0, 0});
  Same(seen.spectrum, {1, 0});
  Same(seen.wave, {});

  seen = Seen();
  Same(Answers(Each(MinusInfinities("getFloatFrequencyData",
                                    "new Float32Array(3).fill(0.75)")),
               4, &none, &seen),
       {3, 1, 1, 1});
  Same(seen.spectrum, {1, 0});
  Same(seen.wave, {});

  seen = Seen();
  Same(Answers(Each(Filled("getFloatTimeDomainData",
                           "new Float32Array(3).fill(0.75)")),
               4, &none, &seen),
       {3, 0, 0, 0});
  Same(seen.wave, {1, 0});
  Same(seen.spectrum, {});
}

// 1 is a call that threw nothing, 2 one that threw a TypeError and 3 one that
// threw something else, so that a script that failed (every copy's x is 0
// then) passes for none of them. The last three calls are given the right
// kind of array.
TEST(SoundData, TheWrongKindOfArrayThrowsATypeError) {
  const std::string threw =
      "function threw(call) {\n"
      "  try { call(); return 1; }\n"
      "  catch (e) { return e instanceof TypeError ? 2 : 3; }\n"
      "}\n";
  const std::string calls =
      "[threw(() => getByteFrequencyData(1, [9, 9, 9], 0)),"
      " threw(() => getByteFrequencyData(1, new Float32Array(3), 0)),"
      " threw(() => getFloatFrequencyData(1, [9, 9, 9], 0)),"
      " threw(() => getFloatFrequencyData(1, new Uint8Array(3), 0)),"
      " threw(() => getFloatTimeDomainData(1, [9, 9, 9], 0)),"
      " threw(() => getFloatTimeDomainData(1, new Uint8Array(3), 0)),"
      " threw(() => getByteFrequencyData(1, new Uint8Array(3), 0)),"
      " threw(() => getFloatFrequencyData(1, new Float32Array(3), 0)),"
      " threw(() => getFloatTimeDomainData(1, new Float32Array(3), 0))]";
  const Sound sound{{-65.0f, -65.0f, -65.0f}, {0.5f, 0.5f, 0.5f}};
  Same(Answers(threw + Each(calls), 9, &sound), {2, 2, 2, 2, 2, 2, 1, 1, 1});
  Same(Answers(threw + Each(calls), 9, nullptr), {2, 2, 2, 2, 2, 2, 1, 1, 1});
}

// 1 is undefined and 2 anything else.
TEST(SoundData, AllThreeReturnUndefined) {
  const std::string returned =
      "[getByteFrequencyData(1, new Uint8Array(2), 0) === undefined ? 1 : 2,"
      " getFloatFrequencyData(1, new Float32Array(2), 0) === undefined"
      " ? 1 : 2,"
      " getFloatTimeDomainData(1, new Float32Array(2), 0) === undefined"
      " ? 1 : 2]";
  const Sound sound{{-65.0f, -65.0f}, {0.5f, 0.5f}};
  Same(Answers(Each(returned), 3, &sound), {1, 1, 1});
  Same(Answers(Each(returned), 3, nullptr), {1, 1, 1});
}

}  // namespace
}  // namespace motolii

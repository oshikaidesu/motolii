// image_pixels() and image_sample() (stage/canvas/image_pixels.h).
//
// The picture is a 4 x 2 PNG written below, 80 bytes made by a script outside
// the engine, with these pixels (red, green, blue, alpha out of 255):
//
//     x = 0            1            2            3
//   y = 0  red 255,0,0,255   red 255,0,0,255   blue 0,0,255,255   clear 0,0,0,0
//   y = 1  green (0,255,0,255) x3                          white 255,255,255,128
//
// The expected numbers are worked out from those pixels and from After Effects'
// sampleImage() (ae-expressions.docsforadobe.dev/layer/general/): [0, 0] is the
// centre of the upper-left pixel; the radius is the distance from the point to
// the edges of the rectangle; the result is the alpha-weighted average.
// Rectangles are given with their edges on pixel edges, where "the pixels whose
// centres are inside" and "the area covered" agree. The two tests that say
// "chosen" pin what the After Effects page leaves open.

#include "stage/canvas/image_pixels.h"

#include <gtest/gtest.h>

#include <cstdint>
#include <filesystem>
#include <fstream>

namespace motolii {
namespace {

namespace fs = std::filesystem;

constexpr uint8_t kPng[] = {
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x7f, 0xa8, 0x7d, 0x63, 0x00, 0x00, 0x00,
    0x17, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0xf8, 0xcf, 0xc0, 0xf0,
    0x1f, 0x84, 0x21, 0x14, 0x08, 0xfc, 0x47, 0x40, 0x20, 0x68, 0x00, 0x00,
    0xe7, 0xba, 0x0f, 0x72, 0x42, 0xb5, 0xbf, 0x42, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82};

struct Picture {
  fs::path file = fs::temp_directory_path() / "motolii_pixels4x2.png";
  Picture() {
    std::ofstream(file, std::ios::binary)
        .write(reinterpret_cast<const char*>(kPng), sizeof kPng);
  }
  ~Picture() { fs::remove(file); }
};

void Is(const std::array<double, 4>& got, double r, double g, double b,
        double a) {
  EXPECT_NEAR(got[0], r, 1e-9);
  EXPECT_NEAR(got[1], g, 1e-9);
  EXPECT_NEAR(got[2], b, 1e-9);
  EXPECT_NEAR(got[3], a, 1e-9);
}

TEST(ImagePixels, ReadsTheSizeAndKeepsTheFileDecodedOnce) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  EXPECT_EQ(image->w, 4);
  EXPECT_EQ(image->h, 2);
  EXPECT_EQ(image_pixels(p.file.string()), image);
}

TEST(ImagePixels, AFileThatIsNotThereIsNull) {
  EXPECT_EQ(image_pixels("/no/such/picture.png"), nullptr);
}

TEST(ImageSample, OnePixelByDefaultAtTheCentreOfThatPixel) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  Is(image_sample(*image, 0, 0), 1, 0, 0, 1);
  Is(image_sample(*image, 2, 0), 0, 0, 1, 1);
  Is(image_sample(*image, 1, 1), 0, 1, 0, 1);
}

TEST(ImageSample, ClearPixelGivesNothingAndHalfAlphaKeepsItsColour) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  Is(image_sample(*image, 3, 0), 0, 0, 0, 0);
  // The alpha is the file's. The colour is 255 in the file, but ThorVG holds a
  // picture's colours multiplied by alpha in 8 bits, and at alpha 128 that
  // gives back 253 (measured): so within 3/255, not exact. What the screen
  // shows comes through the same path.
  const auto half = image_sample(*image, 3, 1);
  EXPECT_NEAR(half[3], 128.0 / 255.0, 1e-9);
  for (int c = 0; c < 3; ++c) EXPECT_NEAR(half[c], 1.0, 3.0 / 255.0) << c;
}

TEST(ImageSample, AverageOverARectangleOfPixels) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  // x from -0.5 to 2.5, y from -0.5 to 0.5: red, red, blue.
  Is(image_sample(*image, 1, 0, 1.5, 0.5), 2.0 / 3.0, 0, 1.0 / 3.0, 1);
  // The two whole rows over the first column: red above green.
  Is(image_sample(*image, 0, 0.5, 0.5, 1), 0.5, 0.5, 0, 1);
}

TEST(ImageSample, AClearPixelWeighsNothingInTheColourButHalvesTheAlpha) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  // Pixels 2 (blue, opaque) and 3 (clear): the colour is blue, the alpha 1/2.
  Is(image_sample(*image, 2.5, 0, 1, 0.5), 0, 0, 1, 0.5);
}

// Chosen: the After Effects page does not say what lies outside the picture.
TEST(ImageSample, OutsideThePictureIsTransparentBlack) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  Is(image_sample(*image, 10, 10), 0, 0, 0, 0);
  // x from -1 to 1: half a unit outside, pixel 0 whole, half of pixel 1: red
  // over 1.5 of the 2 units of area.
  Is(image_sample(*image, 0, 0, 1, 0.5), 1, 0, 0, 0.75);
}

// Chosen: a pixel the rectangle covers in part counts by the area covered.
TEST(ImageSample, APartlyCoveredPixelCountsByItsArea) {
  Picture p;
  const auto image = image_pixels(p.file.string());
  ASSERT_NE(image, nullptr);
  // x from 1.0 to 2.0: pixel 1 spans 0.5 to 1.5 so the right half of it (red)
  // is in, and pixel 2 spans 1.5 to 2.5 so the left half of it (blue) is in.
  Is(image_sample(*image, 1.5, 0, 0.5, 0.5), 0.5, 0, 0.5, 1);
}

}  // namespace
}  // namespace motolii

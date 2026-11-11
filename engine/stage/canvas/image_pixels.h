#ifndef MOTOLII_STAGE_CANVAS_IMAGE_PIXELS_H_
#define MOTOLII_STAGE_CANVAS_IMAGE_PIXELS_H_

// A still picture file as pixels on the CPU, and After Effects' sampleImage()
// over them: what lets an expression read the colour of another layer.
//
// The semantics are those of After Effects' expression reference
// (ae-expressions.docsforadobe.dev/layer/general/, sampleImage): the point is
// in the picture's own space with [0, 0] at the centre of the upper-left pixel;
// the radius is the distance from the point to the edges of a rectangle (so
// [0.5, 0.5], the default, is one pixel); the result is [red, green, blue,
// alpha], the alpha-weighted average of the pixels in the rectangle.
//
// What that page does not say, and is chosen here: values are 0 to 1 as the
// picture is drawn (no colour-space conversion); a pixel the rectangle covers
// in part counts by the area it covers; what lies outside the picture counts as
// transparent black. ThorVG holds colours multiplied by alpha in 8 bits, so the
// colour of a partly transparent pixel can be a few 1/255 off the file's.

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace motolii {

struct ImagePixels {
  int w = 0, h = 0;
  // w * h pixels of red, green, blue, alpha (alpha not multiplied in), row 0
  // on top.
  std::vector<uint8_t> rgba;
};

// The picture in `file`, drawn by ThorVG at its own size (PNG, JPEG, SVG ...;
// at most 4096 either way), or null when it cannot be read. A file is decoded
// once and kept until it changes on disk. Safe to call from any thread.
std::shared_ptr<const ImagePixels> image_pixels(const std::string& file);

// sampleImage([x, y], [rx, ry]) of `image`: [red, green, blue, alpha], each 0
// to 1, alpha-weighted. [0, 0, 0, 0] when the rectangle holds nothing visible.
std::array<double, 4> image_sample(const ImagePixels& image, double x, double y,
                                   double rx = 0.5, double ry = 0.5);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_IMAGE_PIXELS_H_

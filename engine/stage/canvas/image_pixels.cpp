#include "stage/canvas/image_pixels.h"

#include <thorvg.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <map>
#include <mutex>

namespace motolii {
namespace {

namespace fs = std::filesystem;

struct Kept {
  fs::file_time_type changed;
  std::shared_ptr<const ImagePixels> image;  // null: the file could not be read
};

// Loads a picture file with ThorVG and draws it once at its own size, as
// stage/effects/screen_resources.cpp does for a texture, but asks for pixels
// that are not alpha-multiplied (ABGR8888S: in memory red, green, blue, alpha).
std::shared_ptr<const ImagePixels> decode(const std::string& file) {
  float w = 0, h = 0;
  // ThorVG reads no file until it is started (tvgTaskScheduler.cpp).
  tvg::Initializer::init(0);
  tvg::Picture* p = tvg::Picture::gen();
  if (p->load(file.c_str()) != tvg::Result::Success ||
      p->size(&w, &h) != tvg::Result::Success || w < 1 || h < 1 || w > 4096 ||
      h > 4096)
    return delete p, nullptr;
  auto image = std::make_shared<ImagePixels>();
  image->w = (int)w, image->h = (int)h;
  std::vector<uint32_t> pixels((size_t)image->w * (size_t)image->h, 0);
  tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
  const bool drew =
      canvas->target(pixels.data(), (uint32_t)image->w, (uint32_t)image->w,
                     (uint32_t)image->h,
                     tvg::ColorSpace::ABGR8888S) == tvg::Result::Success &&
      canvas->add(p) == tvg::Result::Success &&
      canvas->draw(true) == tvg::Result::Success &&
      canvas->sync() == tvg::Result::Success;
  delete canvas;
  if (!drew) return nullptr;
  image->rgba.resize(pixels.size() * 4);
  std::memcpy(image->rgba.data(), pixels.data(), image->rgba.size());
  return image;
}

// The index of the pixel that holds coordinate v, kept inside 0 .. n - 1.
// Pixel i holds v from i - 0.5 up to i + 0.5.
int pixel_at(double v, int n) {
  return (int)std::clamp(std::floor(v + 0.5), 0.0, (double)(n - 1));
}

}  // namespace

std::shared_ptr<const ImagePixels> image_pixels(const std::string& file) {
  std::error_code none;
  const fs::file_time_type changed = fs::last_write_time(file, none);
  if (none) return nullptr;
  static std::mutex lock;
  static std::map<std::string, Kept> kept;
  std::lock_guard<std::mutex> hold(lock);
  if (const auto had = kept.find(file);
      had != kept.end() && had->second.changed == changed)
    return had->second.image;
  return (kept[file] = Kept{changed, decode(file)}).image;
}

std::array<double, 4> image_sample(const ImagePixels& image, double x, double y,
                                   double rx, double ry) {
  if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(rx) ||
      !std::isfinite(ry) || image.w < 1 || image.h < 1)
    return {0, 0, 0, 0};
  rx = std::max(std::fabs(rx), 1e-9), ry = std::max(std::fabs(ry), 1e-9);
  const double x0 = x - rx, x1 = x + rx, y0 = y - ry, y1 = y + ry;
  // Each pixel counts by the area of it the rectangle covers, and by its
  // alpha. The area outside the picture is in the total and holds no alpha.
  double alpha = 0, red = 0, green = 0, blue = 0;
  for (int j = pixel_at(y0, image.h); j <= pixel_at(y1, image.h); ++j) {
    const double high = std::min(y1, j + 0.5) - std::max(y0, j - 0.5);
    if (high <= 0) continue;
    for (int i = pixel_at(x0, image.w); i <= pixel_at(x1, image.w); ++i) {
      const double wide = std::min(x1, i + 0.5) - std::max(x0, i - 0.5);
      if (wide <= 0) continue;
      const uint8_t* px = &image.rgba[((size_t)j * (size_t)image.w + (size_t)i) * 4];
      const double weight = wide * high * (px[3] / 255.0);
      alpha += weight;
      red += weight * (px[0] / 255.0);
      green += weight * (px[1] / 255.0);
      blue += weight * (px[2] / 255.0);
    }
  }
  if (alpha <= 0) return {0, 0, 0, 0};
  return {red / alpha, green / alpha, blue / alpha,
          alpha / ((x1 - x0) * (y1 - y0))};
}

}  // namespace motolii

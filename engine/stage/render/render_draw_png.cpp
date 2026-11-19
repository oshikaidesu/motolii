// shoot (render_draw.h) where there is no Cocoa: the frame written by
// stb_image_write, which Filament carries. On macOS render_draw.mm writes it
// with NSBitmapImageRep instead.
#include <cstdint>
#include <vector>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_WRITE_STATIC
#include <stb_image_write.h>

#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

bool shoot(Stage& s, const char* path) {
  // This buffer belongs to the call, as in render_draw.mm.
  std::vector<uint8_t> pic((size_t)s.w * s.h * 4);
  for (int i = 0; i < 3; ++i) draw(s, i == 2 ? &pic : nullptr);
  return stbi_write_png(path, s.w, s.h, 4, pic.data(), s.w * 4) != 0;
}

}  // namespace motolii

#include "stage/canvas/canvas_edge.h"

#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <algorithm>
#include <array>
#include <map>

#include "base/file_read.h"
#include "gpu/screen_interop.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Engine;
using filament::RenderTarget;
using filament::Texture;

namespace {

// The 3 WGSL passes (seeds, flood, length) that build a letter's signed
// distance field live beside this file as canvas_edge_{seeds,flood,length}
// .wgsl. Read once; the shader text never changes at runtime.
const std::string& edge_wgsl(const char* name) {
  static std::map<std::string, std::string> cache;
  if (auto it = cache.find(name); it != cache.end()) return it->second;
  return cache[name] =
             read_text(doc_engine((std::string("stage/canvas/") + name).c_str()));
}

}  // namespace

void edge_make(Stage& s, Canvas2D* d, uint32_t w, uint32_t h) {
  for (int k = 0; k < 3; k++) {
    d->edge[k] = Texture::Builder()
                     .width(w)
                     .height(h)
                     .levels(1)
                     .format(Texture::InternalFormat::RGBA16F)
                     .usage(Texture::Usage::COLOR_ATTACHMENT |
                            Texture::Usage::SAMPLEABLE)
                     .build(*s.engine);
    d->edgeInto[k] =
        RenderTarget::Builder()
            .texture(RenderTarget::AttachmentPoint::COLOR, d->edge[k])
            .build(*s.engine);
  }
  d->edgeW = w, d->edgeH = h;
}
void edge_off(Stage& s, Canvas2D* d) {
  s.once.erase(d);
  for (int k = 0; k < 3; k++)
    if (d->edge[k])
      s.engine->destroy(d->edgeInto[k]), s.engine->destroy(d->edge[k]),
          d->edge[k] = nullptr;
}
void edge_ask(Stage& s, Canvas2D* d, int reach) {
  d->stale = false;
  s.once[d] = [&s, d, reach] {
    auto& built = s.edge_screens;
    if (!built[0])
      built = {interop::screen(s.engine, "edge seeds",
                                edge_wgsl("canvas_edge_seeds.wgsl").c_str(), 0),
               interop::screen(s.engine, "edge flood",
                                edge_wgsl("canvas_edge_flood.wgsl").c_str(), 16),
               interop::screen(s.engine, "edge length",
                                edge_wgsl("canvas_edge_length.wgsl").c_str(), 0)};
    if (!built[0] || !built[1] || !built[2]) return;
    interop::draw(s.engine, built[0], d->texture, d->edgeInto[0], d->edgeW,
                  d->edgeH);
    int front = 0, pass = 0, step = 1;
    while (step < std::max(reach, 8))
      step *= 2;  // (8: the last pass reads 6 points round each, outside too)
    for (; step >= 1; step /= 2, pass++) {
      const float k[4] = {(float)step, 0.f, 0.f, 0.f};
      interop::parameters(s.engine, built[1], k, sizeof k, pass);
      Texture* from = d->edge[front];
      interop::draw(s.engine, built[1], &from, d->edgeInto[!front], d->edgeW,
                    d->edgeH, pass);
      front = !front;
    }
    interop::draw(s.engine, built[2], d->edge[front], d->edgeInto[2], d->edgeW,
                  d->edgeH);
  };
}

}  // namespace motolii

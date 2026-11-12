// Changing a live canvas: trimming its path, bending it, choosing which slots
// of its sheet show, lighting its letters and changing its words in place. Each
// drops the frames cached for the canvas (cache_drop) because they no longer
// match.
#include "gpu/gpu_interop.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

using filament::Texture;
using filament::TextureSampler;
using filament::math::float3;

void trim_at(Stage& s, Canvas2D* d, float cut, float begin, float offset) {
  const float3 is{cut, begin, offset};
  if (!d->shape || (is == d->trimmed)) return;
  d->trimmed = is;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, cut, begin, offset] {
    for (tvg::Shape* shape : {d->shape, d->letterEdge})
      if (shape)
        shape->trimpath(std::clamp(begin, 0.f, 1.f) + offset,
                        1.f - std::clamp(cut, 0.f, 1.f) + offset);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

void bend_at(Stage& s, Canvas2D* d, float round, float bloat, float zigzag,
             float ridges, float smooth, float offset) {
  const std::array<float, 10> is{round,  bloat, zigzag, ridges, smooth,
                                 offset, 0.f,   0.f,    0.f,    0.f};
  if (!d->shape || d->plain.empty() || is == d->bent) return;
  d->bent = is;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, is] {
    const float high = d->plainHigh, side = d->plainSide;
    tvg_bend(
        d->shape, d->plain.data(), (uint32_t)d->plain.size(), d->plainAt.data(),
        (uint32_t)d->plainAt.size(), std::clamp(is[0], 0.f, 0.5f) * side,
        100.f * std::clamp(is[1], -1.f, 1.f),
        std::clamp(is[2], -4.f, 4.f) * high, (int)std::clamp(is[3], 0.f, 100.f),
        is[4] > 0.5f, std::clamp(is[5], -4.f, 4.f) * high, d->fine);
    // A shape bent to more than 64 times the size of its image is not drawn.
    // None of it would be visible, and ThorVG can crash while measuring,
    // dashing and staging a path that large.
    float x = 0.f, y = 0.f, w = 0.f, h = 0.f;
    if (d->shape->bounds(&x, &y, &w, &h) == tvg::Result::Success &&
        !(std::max(w, h) < 64.f * std::max(1.f, d->canvasHigh)))
      d->shape->reset();
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

void slots_at(Stage& s, Canvas2D* d, const std::string& slots) {
  if (!d->lottie || slots == d->slots) return;
  d->slots = slots;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, slots] {
    if (d->slotsId) d->lottie->del(d->slotsId), d->slotsId = 0;
    if (!slots.empty() && (d->slotsId = d->lottie->gen(slots.c_str())))
      d->lottie->apply(d->slotsId);
    // Draw the current frame again.
    d->targetAt = -1;
  });
}

void lit_at(Stage& s, Canvas2D* d, const std::vector<float>& lit,
            const std::vector<tvg::Matrix>& moves, float3 colour) {
  if (!d->film || (lit == d->lit && moves.size() == d->moves.size() &&
                   std::equal(moves.begin(), moves.end(), d->moves.begin(),
                              [](const tvg::Matrix& a, const tvg::Matrix& b) {
                                return !std::memcmp(&a, &b, sizeof a);
                              })))
    return;
  d->lit = lit, d->moves = moves;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, lit, moves, colour] {
    for (size_t i = 0; i < lit.size(); ++i)
      if (auto* note = const_cast<tvg::Paint*>(d->film->picture()->paint(
              tvg::Accessor::id(("note" + std::to_string(i)).c_str())));
          note && note->type() == tvg::Type::Shape) {
        const float3 c = min(colour + 0.3f * lit[i], float3{1.f});
        static_cast<tvg::Shape*>(note)->fill((uint8_t)std::lround(c.x * 255.f),
                                             (uint8_t)std::lround(c.y * 255.f),
                                             (uint8_t)std::lround(c.z * 255.f));
        if (i < moves.size()) note->transform(moves[i]);
      }
    // ThorVG redraws a picture only if the picture itself is marked changed,
    // not its parts (see update in tvgPicture.h). Paint::opacity marks it.
    d->film->picture()->opacity(254), d->film->picture()->opacity(255);
    // Draws now even if the picture does not move.
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
}

bool words_at(Stage& s, Canvas2D* d, const std::string& words) {
  if (!d->retype || d->outgrown) return false;
  if (words == d->words) return true;
  // The font lacks a letter. The text is made again with the fallback font.
  if (!type_lacks(d->textFont, words).empty()) return false;
  d->words = words;
  cache_drop(s, d);
  interop::on_driver(s.engine, [d, words] {
    d->retype(words);
    d->canvas->update();
    d->canvas->draw(true), d->stale = true;
    d->canvas->sync();
  });
  return true;
}

}  // namespace motolii

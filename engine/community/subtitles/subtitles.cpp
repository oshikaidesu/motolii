#include "community/subtitles/subtitles.h"

#include <ass/ass.h>

#include <algorithm>
#include <climits>
#include <cstdarg>
#include <cstdio>

namespace motolii {

struct Subtitles::Own {
  ASS_Library* library = nullptr;
  ASS_Renderer* renderer = nullptr;
  ASS_Track* track = nullptr;
};

Subtitles::Subtitles(const std::string& text) : own(new Own) {
  own->library = ass_library_init();
  // Only its warnings and errors (levels 0 to 2 of ass_set_message_cb in
  // ass.h); libass prints all but its debugging otherwise.
  ass_set_message_cb(
      own->library,
      [](int level, const char* format, va_list said, void*) {
        if (level > 2) return;
        std::fputs("[libass] ", stderr), std::vfprintf(stderr, format, said),
            std::fputc('\n', stderr);
      },
      nullptr);
  own->renderer = ass_renderer_init(own->library);
  std::string copy = text;  // (ass_read_memory takes a char*)
  own->track = ass_read_memory(own->library, copy.data(), copy.size(), nullptr);
  if (!own->track)
    return;  // (a file with no PlayRes is 384 x 288 by now:
             // ass_lazy_track_init in libass's ass.c)
  ass_set_frame_size(own->renderer, width(), height());
  ass_set_storage_size(own->renderer, width(), height());
  // The fonts the file names, looked up on the system (CoreText on macOS,
  // fontconfig elsewhere), as players that use libass do.
  ass_set_fonts(own->renderer, nullptr, "sans-serif",
                ASS_FONTPROVIDER_AUTODETECT, nullptr, 1);
}

Subtitles::~Subtitles() {
  if (own->track) ass_free_track(own->track);
  ass_renderer_done(own->renderer);
  ass_library_done(own->library);
}

bool Subtitles::read() const { return own->track != nullptr; }
int Subtitles::width() const { return own->track ? own->track->PlayResX : 0; }
int Subtitles::height() const { return own->track ? own->track->PlayResY : 0; }

Subtitles::Frame Subtitles::at(long long ms) const {
  Frame f;
  if (!own->track) return f;
  ASS_Image* first = ass_render_frame(own->renderer, own->track, ms, nullptr);
  int x0 = INT_MAX, y0 = INT_MAX, x1 = INT_MIN, y1 = INT_MIN;
  for (ASS_Image* i = first; i; i = i->next)
    if (i->w > 0 && i->h > 0)
      x0 = std::min(x0, i->dst_x), y0 = std::min(y0, i->dst_y),
      x1 = std::max(x1, i->dst_x + i->w), y1 = std::max(y1, i->dst_y + i->h);
  if (x0 >= x1) return f;
  f.x = x0, f.y = y0, f.w = x1 - x0, f.h = y1 - y0;
  f.rgba.assign((size_t)f.w * f.h * 4, 0);
  // Each image is one colour with a coverage bitmap; its colour is RGBA with
  // the alpha inverted (ASS_Image in ass.h). Laid in order, each over the ones
  // before (the "over" operator, in straight alpha).
  for (ASS_Image* i = first; i; i = i->next) {
    const unsigned c = i->color, r = c >> 24, g = (c >> 16) & 255,
                   b = (c >> 8) & 255, opaque = 255 - (c & 255);
    for (int y = 0; y < i->h; ++y)
      for (int x = 0; x < i->w; ++x) {
        const float a = i->bitmap[y * i->stride + x] * opaque / (255.f * 255.f);
        if (a <= 0) continue;
        uint8_t* p = &f.rgba[(((size_t)(i->dst_y + y - f.y)) * f.w +
                              (i->dst_x + x - f.x)) *
                             4];
        const float under = p[3] / 255.f * (1 - a), all = a + under;
        p[0] = (uint8_t)((r * a + p[0] * under) / all + .5f);
        p[1] = (uint8_t)((g * a + p[1] * under) / all + .5f);
        p[2] = (uint8_t)((b * a + p[2] * under) / all + .5f);
        p[3] = (uint8_t)(all * 255 + .5f);
      }
  }
  return f;
}

}  // namespace motolii

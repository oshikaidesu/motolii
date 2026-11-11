#include "document/scripts/script_reads.h"

#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec4.h>

#include <array>
#include <cmath>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "community/script_runner/script_runner.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "media/video_frames_for_scripts.h"
#include "media/video_layer.h"
#include "stage/canvas/image_pixels.h"

namespace motolii {

namespace math = filament::math;
using filament::math::float2;

namespace {

// A video file read on the CPU for scripts, and the frame of it last asked for.
struct Film {
  bool tried = false, open = false;
  FilmRead read;
  ImagePixels now;
  long held = -2;  // which frame of `read` is in `now`
};

// Returns the picture layer `layer` shows at second `t` as pixels, or null when
// it has none to read (script_reads.h says which layers do). `keeps` holds a
// still's pixels for as long as the caller reads them.
const ImagePixels* layer_pixels(Doc& d, int layer, double t,
                                std::shared_ptr<const ImagePixels>& keeps) {
  const std::string kind = doc_word(d, layer, "kind"),
                    file = doc_word(d, layer, "file");
  if (kind == "image") return (keeps = image_pixels(file)).get();
  if (kind != "video") return nullptr;
  const auto shown = d.on_stage.shown.find(layer);
  const Video* v =
      shown == d.on_stage.shown.end() ? nullptr : shown->second.video;
  if (!v || v->seconds <= 0.f) return nullptr;
  // The second of the file the layer shows at t: how long the layer has been
  // on (evaluate.cpp's `since`), round its cut as video_at loops it, then into
  // the file as video_from seeks it.
  const double since = doc_element_now(d, layer, t) -
                       doc_number(d, layer, "start", 0, 0),
               in = std::fmod(std::max(0.0, since), (double)v->seconds) *
                    std::fabs((double)v->speed),
               second = v->speed > 0.f ? (double)v->from + in
                                       : (double)v->to - in;
  // One reader a file, kept for as long as the program runs: its GStreamer
  // pipeline is not taken down while the program exits.
  static auto& films = *new std::map<std::string, Film>;
  Film& f = films[file];
  if (!f.tried) f.tried = true, f.open = f.read.open(file, 0);
  if (!f.open || !f.read.at(second)) return nullptr;
  if (f.held != f.read.frame)
    f.now.w = f.read.w, f.now.h = f.read.h, f.now.rgba = f.read.last,
    f.held = f.read.frame;
  return &f.now;
}

}  // namespace

void doc_script_reads(Doc& d, Script& run) {
  // The script runs on this thread inside the call that holds the project, so
  // reading is safe; the lock is taken as well, as the render callback does.
  // Limits how deeply layers read each other, so that a cycle of them
  // terminates.
  run.reads([&d](int layer, const std::string& name, double at,
                 double otherwise, int copy) {
    static int depth = 0;
    for (const char* known : doc_relate_names) {
      if (name != known || depth >= 4) continue;
      std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
      ++depth;
      double v;
      // Where the middle of the copy is, everything that places it taken in (a
      // split text's letter as its CSS, its script or its delay moves it:
      // doc_place, doc_letter_middle); the other names are the layer's.
      if (copy >= 0 && name.size() == 1 && name[0] >= 'x')
        v = (doc_place(d, layer, at, 1, copy, true) *
             math::double4{doc_letter_middle(d, layer, copy), 0, 0,
                           1})[name[0] - 'x'];
      else
        v = doc_literal(d, layer, known, at, otherwise);
      --depth;
      return v;
    }
    return std::nan("");
  });
  run.reads_pictures(
      [&d](int layer, double x, double y, double rx, double ry, bool,
           double t) -> std::array<double, 4> {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        std::shared_ptr<const ImagePixels> keeps;
        const ImagePixels* picture = layer_pixels(d, layer, t, keeps);
        if (!picture) return {0, 0, 0, 0};
        return image_sample(*picture, x, y, rx, ry);
      },
      [&d](int layer, double x, double y, double z,
           double t) -> std::array<double, 2> {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        std::shared_ptr<const ImagePixels> keeps;
        const ImagePixels* picture = layer_pixels(d, layer, t, keeps);
        float2 half{0.f};
        if (!picture || !doc_half(d, layer, &half) || half.x <= 0.f ||
            half.y <= 0.f)
          return {std::nan(""), std::nan("")};
        // The layer's own box runs from -half to +half, y up. Its picture's
        // pixels run from the upper left, [0, 0] the centre of the first.
        const math::double4 in = inverse(doc_place(d, layer, t, 1)) *
                                 math::double4{x, y, z, 1};
        return {(in.x / (double)half.x + 1.0) * 0.5 * picture->w - 0.5,
                (1.0 - in.y / (double)half.y) * 0.5 * picture->h - 0.5};
      });
}

}  // namespace motolii

#include "document/match/match_image.h"

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <memory>
#include <string>
#include <system_error>
#include <utility>

#include "community/script_runner/script_runner.h"
#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/match/rebuild.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/midi_roll.h"
#include "motion/lottie_motion.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// Returns the path of drawing number n of the level that `file` belongs to. The
// drawings of a level are files in one folder, told apart by the number at the
// end of the file name, between the name and the extension, as OpenToonz reads
// a level (animation.0001.tif, animation_0001.tif; see tfilepath.cpp, pattern
// (\d+)). The number is padded to the width of the number in `file`. Returns
// "" when n is negative, which is a cross in the timesheet and means no
// drawing. Returns `file` itself when its name ends in no number.
std::string doc_cel_file(const std::string& file, double n) {
  if (n < 0) return "";
  const std::filesystem::path p(file);
  const std::string stem = p.stem().string();
  size_t from = stem.size();
  while (from > 0 && std::isdigit((unsigned char)stem[from - 1])) --from;
  if (from == stem.size()) return file;
  std::string number = std::to_string((long long)std::llround(n));
  if (number.size() < stem.size() - from)
    number.insert(0, stem.size() - from - number.size(), '0');
  return (p.parent_path() /
          (stem.substr(0, from) + number + p.extension().string()))
      .string();
}

// A level: sets `shown` to the drawing that its keyframes name now, held until
// the next, as a timesheet holds it.
void level_drawing(LayerBuild& build, std::string& shown) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  std::string& why = build.why;
  if (const DocKeys& cels = doc_keys_of(d, layer, "cel"); !cels.at.empty()) {
    made.cel = doc_cel(d, layer, s.now), made.celMove = cels.at.size() > 1;
    shown = doc_cel_file(file, made.cel);
    // OpenToonz marks a missing drawing of a level in red and does not fill
    // it in.
    if (!shown.empty() && !std::filesystem::is_regular_file(shown))
      why = "no drawing " + std::to_string((long long)made.cel) + " beside " +
            std::filesystem::path(file).filename().string(),
      shown.clear();
  }
}

// A MIDI file is drawn as a piano roll at the tempo its speed gives
// (midi_roll.cpp): sets `shown` to the roll and `rollHigh` to its height.
void piano_roll(LayerBuild& build, std::string& shown, float& rollHigh) {
  Doc& d = build.d;
  const int layer = build.layer;
  const std::string& file = build.file;
  std::string& why = build.why;
  if (std::filesystem::path(file).extension() == ".mid") {
    const double speed = build.number("speed", 1);
    shown = midi_roll_file(
        file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why);
    // One point of the roll is one point of the document, as the 1920 x
    // 1080 screen of ALMaMPlayer shows it.
    double w = 0, h = 0;
    if (!shown.empty() && midi_roll_box(shown, w, h))
      rollHigh = (float)(h / doc_point(d, layer, 0));
  }
}

// A p5.js sketch that paints in 2D. What it paints is drawn by ThorVG
// (canvas_sketch.h).
void sketch_picture(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  const bool fxOk = build.fxOk;
  const char* lay = build.lay;
  const Canvas2DFx& fx = build.fx;
  std::string& why = build.why;
  // The video layer below it, which is what createCapture and createVideo
  // in the sketch see.
  std::string under;
  for (int t : doc_laid(d)) {
    if (t == layer) break;
    if (doc_word(d, t, "kind") == "video") under = doc_word(d, t, "file");
  }
  // The instance already run to check the sketch. It is reused when no
  // video is under the sketch.
  std::shared_ptr<Script>& ready = doc_scripts_kept(d).sketches[file].ready;
  auto run =
      ready && under.empty()
          ? std::exchange(ready, nullptr)
          : std::make_shared<Script>(
                file, (doc_engine("third_party/js/p5") / "p5.min.js").string(),
                under);
  if (!run->flat())
    why = run->ok() ? "not a 2D sketch: " + file : run->trouble();
  else if (fxOk && (made.drawn = sketch_canvas(
                        s, run,
                        (doc_engine("third_party/filament_src/assets/fonts") /
                         "Roboto-Medium.ttf")
                            .string(),
                        1.f, lay, fx)))
    s.playing.erase(made.drawn);
}

// A photo `aspect` times as wide as it is high, with an edge, rounded corners
// or a crop. The crop is given as fractions of the photo cut from its left,
// top, right and bottom.
void edged_photo(LayerBuild& build, float aspect, bool cropped, double cl,
                 double ct, double cr, double cb) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  const char* lay = build.lay;
  const float4 edge = build.edge;
  const Canvas2DFx& fx = build.fx;
  // A photo with an edge, rounded corners or a crop is drawn as a
  // rectangle as wide as the photo, with the photo file as its fill, as a
  // shape filled with media is. Alight Motion's media layers take a
  // border as its shapes do.
  Canvas2DFx own = fx;
  own.media = file;
  // Crop: the rectangle shows a path within the whole photo, measured in
  // photo heights from its middle, so that what remains stays where it
  // was.
  char cut[256];
  std::snprintf(
      cut, sizeof cut, "M%.5f %.5f L%.5f %.5f L%.5f %.5f L%.5f %.5f Z",
      aspect * (cl - 0.5), ct - 0.5, aspect * (0.5 - std::min(cr, 0.95 - cl)),
      ct - 0.5, aspect * (0.5 - std::min(cr, 0.95 - cl)),
      0.5 - std::min(cb, 0.95 - ct), aspect * (cl - 0.5),
      0.5 - std::min(cb, 0.95 - ct));
  made.drawn = flat(s, cropped ? cut : "rect", aspect, mat4f{}, 1.f,
                    float3{1.f}, lay, edge, own.over(1.f), 4, 0.5f,
                    (float)doc_number(d, layer, "round", 0, 0));
}

// Stand up its 3D layers where they are, as After Effects shows them.
void deep_layers(LayerBuild& build) {
  Stage& s = build.s;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  if (made.drawn && made.drawn->lottie && !canvas_deep(s, made.drawn).empty()) {
    made.motion = std::make_shared<Motion>();
    if (motion_open(*made.motion, file.c_str()))
      for (uint32_t id : made.drawn->deep) {
        float4 box;
        if (Canvas2D* own =
                layer_canvas(s, file.c_str(), id, 1.f / made.motion->h, &box))
          made.deep.push_back({id, own, box});
      }
  }
}

}  // namespace

long long doc_sketch_written(Doc& d, const std::string& file) {
  DocSketch& one = doc_scripts_kept(d).sketches[file];
  std::error_code wrong;
  const long long stamp =
      (long long)std::filesystem::last_write_time(file, wrong)
          .time_since_epoch()
          .count();
  if (wrong || stamp == one.seen) return one.whole;
  one.seen = stamp;
  auto run = std::make_shared<Script>(
      file, (doc_engine("third_party/js/p5") / "p5.min.js").string());
  if (run->flat()) one.whole = stamp, one.ready = run;
  if (run->ok())
    doc_scripts_kept(d).why.erase(file);
  else
    doc_scripts_kept(d).why[file] = d.error = run->trouble();
  return one.whole;
}

void match_image(LayerBuild& build) {
  Stage& s = build.s;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  const bool fxOk = build.fxOk;
  const char* lay = build.lay;
  const float4 edge = build.edge;
  const Canvas2DFx& fx = build.fx;
  std::string shown = file;
  level_drawing(build, shown);
  float rollHigh = 1.f;
  piano_roll(build, shown, rollHigh);
  const std::string ext = std::filesystem::path(file).extension().string();
  const double cl = build.number("crop_left", 0),
               ct = build.number("crop_top", 0),
               cr = build.number("crop_right", 0),
               cb = build.number("crop_bottom", 0);
  const bool cropped = cl + ct + cr + cb > 0.0;
  const float aspect =
      doc_among(".jpg .jpeg .png .webp .bmp .JPG .JPEG .PNG", ext) &&
              (edge.w > 0.f || build.number("round", 0) > 0.0 ||
               cropped)
          ? canvas_aspect(s, file.c_str())
          : 0.f;
  if (ext == ".js")
    sketch_picture(build);
  else if (fxOk && aspect > 0.f)
    edged_photo(build, aspect, cropped, cl, ct, cr, cb);
  else if (fxOk && !shown.empty() &&
           (made.drawn = image_canvas(s, shown.c_str(), mat4f{}, rollHigh,
                                      float3{-1.f}, true, lay, fx,
                                      build.word("marker").c_str())))
    s.playing.erase(made.drawn);
  deep_layers(build);
}

}  // namespace motolii

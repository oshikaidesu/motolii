#include "document/match/match_video.h"

#include <math/mat4.h>

#include <algorithm>
#include <cmath>
#include <string>

#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/marks.h"
#include "document/match/rebuild.h"
#include "media/video_datamosh.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::math::mat4f;

namespace {

// Returns the sound of a video layer as it is heard in an exported video: the
// part of the file that plays, when it starts and how loud it is.
Stage::Sound video_sound(Doc& d, int layer, Video* v, const std::string& file) {
  const double on = doc_number(d, layer, "start", 0, 0) -
                    d.video_export.written_from,
               lasts = doc_number(d, layer, "duration", 0, -1),
               late = std::max(0.0, -on);
  Stage::Sound a{file,
                 v->from,
                 v->to,
                 v->speed,
                 late,
                 std::max(0.0, on),
                 lasts < 0.0 ? lasts : std::max(1e-3, lasts - late),
                 doc_number(d, layer, "volume", 0, 1)};
  // With keyframes on volume, sample Alight Motion's Volume with its
  // keyframes and easing every 1/30 s, as the document reads it.
  if (doc_keys_of(d, layer, "volume").at.size() > 1)
    for (double t = 0.0,
                end = a.lasts >= 0.0
                          ? a.lasts
                          : doc_seconds(d) - d.video_export.written_from - a.on;
         t <= end + 1e-9 && a.loud.size() < 30 * 3600; t += 1.0 / 30.0)
      a.loud.push_back((float)doc_number(
          d, layer, "volume", d.video_export.written_from + a.on + t, 1));
  return a;
}

}  // namespace

std::string doc_mosh(Doc& d, int layer) {
  if (!doc_on(d, layer, "mosh") || doc_word(d, layer, "kind") != "video")
    return "";
  const int with = (int)doc_number(d, layer, "mosh_with", 0, 0);
  const std::string file = doc_word(d, layer, "file"),
                    other = with > 0 && with != layer
                                ? doc_word(d, with, "file")
                                : "";
  if (other.empty() || doc_word(d, with, "kind") != "video") return "";
  return mosh_file(file, doc_number(d, layer, "mosh_at", 0, 1), other);
}

void match_video(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  const char* lay = build.lay;
  const Canvas2DFx& fx = build.fx;
  std::string& why = build.why;
  // The datamosh video, once rendered, plays in place of the video, from
  // its start.
  const std::string moshed = doc_mosh(d, layer);
  const double from =
                   moshed.empty() ? build.number("begin", 0) : 0.0,
               length = build.number("duration", -1),
               speed = build.number("speed", 1);
  made.video = video(
      s, (moshed.empty() ? file : moshed).c_str(), mat4f{}, 1.f, (float)from,
      length < 0 ? -1.f : (float)(from + length * std::fabs(speed)),
      (float)speed, lay, fx.lit, fx.wear);
  if (!made.video) why = video_trouble;
  // When not set, keying is on if the video has a background of its own.
  else if (const double keyed = build.number("keyed", -1);
           keyed != 0.0)
    key_own(made.video, keyed > 0.5);
  // The document sets its time and starts its sound; the video does not
  // advance by itself.
  if (made.video) s.playing.erase(made.video);
  // The start of the sound is counted from where the exported video begins.
  // A sound already playing at that point is heard from that far into it.
  if (made.video && made.video->sound)
    s.sounding[made.video] = [&d, layer, v = made.video, file] {
      return video_sound(d, layer, v, file);
    };
}

}  // namespace motolii

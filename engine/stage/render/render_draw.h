#ifndef MOTOLII_STAGE_RENDER_RENDER_DRAW_H_
#define MOTOLII_STAGE_RENDER_RENDER_DRAW_H_
// Posing renderables, writing a video or an image sequence, and saving a
// screenshot of the stage.
#include <math/mat4.h>

#include <functional>

#include "stage/render/render_stage.h"

namespace motolii {

// Sets the transform of every renderable of mesh `m`. `to` receives the index
// of the renderable within the mesh and its placement, and returns the new
// transform. Only transforms are set here; nothing that a frame is made of is
// computed. When `eye` is given, the instances of a group are ordered farthest
// first, so that flat shapes overlap correctly.
void move(Stage& s, const Mesh* m,
          const std::function<
              filament::math::mat4f(int, const filament::math::mat4f&)>& to,
          const filament::math::mat4f* eye = nullptr);

// Options for writing a video. A value of 0 (or false) keeps the default.
//   - high: output height in pixels (ffmpeg scale, aspect ratio kept, Lanczos).
//   - rate: frames per second (ffmpeg -r). Some of the 60 rendered frames per
//   second are
//     dropped.
//   - mbps: bit rate in megabits per second (-b:v), instead of VideoToolbox
//     -q:v 68 (.mp4) or -q:v 65 (.mov).
//   - blur: number of samples drawn for each frame and averaged, as After
//   Effects and
//     Blender motion blur does. The samples span a 180 degree shutter around
//     the time of the frame, like an After Effects shutter angle of 180 with
//     phase -90. Moving things are smeared along their path; still things stay
//     sharp.
//   - alpha: keep transparency, so that nothing drawn is clear. The view is
//   rendered
//     translucent and the frames are converted from premultiplied alpha for
//     ffmpeg. Kept by .png, .gif and .mov (HEVC with alpha through
//     VideoToolbox, as QuickTime and Final Cut read it). .mp4 and .jpg have no
//     alpha.
struct FilmWay {
  int high = 0, rate = 0;
  double mbps = 0.0;
  int blur = 0;
  bool alpha = false;
};
// Renders `frameCount` frames of the stage at 60 frames per second and writes
// them to `path` with ffmpeg. Returns true if ffmpeg succeeded. The format
// follows the file extension:
//   - .mp4: H.264 through the Mac's VideoToolbox encoder.
//   - .mov: HEVC through the Mac's VideoToolbox encoder, tagged hvc1 so that
//   QuickTime plays it.
//   - .gif: ffmpeg's palettegen and paletteuse at 15 frames per second, as
//   Alight Motion
//     writes a GIF.
//   - .png and .jpg: one image per frame, named name_0001.png and so on.
// There is no sound in .gif, .png and .jpg.
// Before each frame, `pose` is called with the progress through the video from
// 0 to 1, so that a loop can meet its start at the end. The audio is the sound
// of each entry of Stage::sounding: cut, sped up, reversed, looped and set to
// its volume with ffmpeg, then mixed by ffmpeg.
bool film(Stage& s, const char* path, int frameCount,
          const std::function<void(double)>& pose, const FilmWay& said = {});

// Renders the stage and saves it as a PNG at `path`. Returns true on success.
// Three frames are drawn and the pixels are read after the last one.
bool shoot(Stage& s, const char* path);

}  // namespace motolii

#endif  // MOTOLII_STAGE_RENDER_RENDER_DRAW_H_

#ifndef MOTOLII_MEDIA_SOUND_PLAYBACK_H_
#define MOTOLII_MEDIA_SOUND_PLAYBACK_H_

// Plays the sound of layers while the canvas plays.
//
// The layers that have sound are listed in Stage::sounding, the same sounds
// that an exported video mixes. Each one gets a GStreamer playbin that plays
// only the audio of its file. The playbin is sought to the position that the
// current time gives inside the layer's cut and plays at the layer's speed. It
// is paused when the canvas is stopped or the layer is not on. It is sought
// again when it strays from the position it should have, because the cut
// looped, the playhead was moved, or the clocks drifted apart. If the
// environment variable MOTOLII_MUTE is set, everything runs as usual but at
// zero volume, so that checks can run on a desktop machine without noise.

#include <gst/gst.h>

#include <map>
#include <string>

#include "stage/render/render_stage.h"

namespace motolii {

// The player of one layer's sound.
struct Heard {
  GstElement* bin = nullptr;
  std::string file;
  // True while the player is playing.
  bool on = false;
  // The position in the file, in seconds, that the current time gives. It is -1
  // when the sound is not to be heard.
  double wanted = -1.0;
};

// Stops and releases the player of `h`, if it has one.
void heard_off(Heard& h);

// Reads from the document how every layer with sound should sound now. The
// document is held only while it is read.
std::map<const void*, Stage::Sound> heard_told(Stage& s);

// Updates the players once for each frame of the live canvas. Every layer with
// sound is played at the position that the current time `now` gives, or not at
// all. `told` is the result of heard_told and `all` holds the players.
// `playing` is false when the canvas is stopped. The players are sought and
// played without holding the document, which heard_told has already read.
void heard(const std::map<const void*, Stage::Sound>& told,
           std::map<const void*, Heard>& all, double now, bool playing);

}  // namespace motolii

#endif  // MOTOLII_MEDIA_SOUND_PLAYBACK_H_

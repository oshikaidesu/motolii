#ifndef MOTOLII_ENTRY_CALLS_SOUND_H_
#define MOTOLII_ENTRY_CALLS_SOUND_H_
// Implements the sound calls of motolii.h: the loudness of a video's sound, the times where it
// strikes, and ducking it under other sounds as Audacity's Auto Duck does.
#include "entry/motolii.h"

// Keys a video layer's volume down by 12 dB while any other video's sound is louder than
// -30 dB, as Audacity's Auto Duck does (see its manual). The volume fades down over the half
// second before and back up over the half second after, and a pause shorter than one second
// between loud stretches is not let up. This is one undo step. Fails, with the reason in
// d.error, if the layer is not a video, its volume already has keyframes, another video's sound
// has not been read yet (motolii_loudness reads it), or no other sound is loud enough.
bool duck(Motolii* m, int layer);

#endif  // MOTOLII_ENTRY_CALLS_SOUND_H_

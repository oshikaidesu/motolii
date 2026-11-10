#ifndef MOTOLII_MEDIA_VIDEO_DATAMOSH_H_
#define MOTOLII_MEDIA_VIDEO_DATAMOSH_H_

// Datamosh done on the compressed video itself, not with a shader.
//
// FFmpeg re-encodes the video with its keyframes dropped, using its noise bitstream filter with
// drop='key*gt(n,0)'. After the cut, the motion of the other video is applied to the last
// image of this one, so the result has the pixels of one video and the movement of the other.
// The result is made once, on a thread of its own, into
// ~/Library/Caches/Motolii/mosh/<hash>.mp4. The name is a hash of the input files and the
// cut time. Until the file exists the layer plays its own video. This is a step on the video
// before it is decoded, so it runs first, before any effect of the layer.

#include <atomic>
#include <string>

// Set when a datamosh file has been made since the last time it was asked for. The canvas
// then has to be rebuilt to match; see motolii.mm.
extern std::atomic<bool> mosh_done;

// Returns the path of the datamoshed video made of `film` up to `at` seconds, followed by the
// motion of `with` applied to it. Returns "" until the file exists, and the first such call
// starts making it. Also returns "" if it could not be made.
std::string mosh_file(const std::string& film, double at, const std::string& with);

#endif  // MOTOLII_MEDIA_VIDEO_DATAMOSH_H_

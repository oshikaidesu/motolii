#ifndef MOTOLII_ENTRY_CALLS_FILES_H_
#define MOTOLII_ENTRY_CALLS_FILES_H_
// calls_files.h: the calls of motolii.h that read files without an open
// project. They make small thumbnails of videos with GStreamer, report what a
// media file is with the GStreamer discoverer, and report the kinds of a font
// with CoreText.

// Writes a frame of a video as a small PNG of width `wide`. A GStreamer
// pipeline decodes, scales and encodes to PNG, is paused at its first frame,
// and that frame is taken and written. The pipeline needs no stage, so any
// thread may call this.
//
// If `seconds` is greater than 0 the frame is that many seconds into the video.
// Otherwise, if `fraction` is greater than 0, it is that fraction of the
// video's duration, from 0 to 1 and at most 0.98, so that moving the pointer
// over a tile scrubs through the video. The timeline bar uses `seconds` to show
// the frames it plays. Returns nonzero if the PNG was written.
int thumbnail_at(const char* video, const char* png, int wide, double fraction,
                 double seconds = -1.0);

#endif  // MOTOLII_ENTRY_CALLS_FILES_H_

#ifndef MOTOLII_MEDIA_VIDEO_FRAMES_FOR_SCRIPTS_H_
#define MOTOLII_MEDIA_VIDEO_FRAMES_FOR_SCRIPTS_H_

// Reads the frames of a video one after another on the CPU, at a small size,
// for a script to read. Uses GStreamer's appsink, which pulls samples as in the
// GStreamer tutorial "Short-cutting the pipeline". video_layer.h keeps a video
// on the GPU, whereas a script asks for numbers.

#include <gst/app/gstappsink.h>
#include <gst/gst.h>

#include <cstdint>
#include <string>
#include <vector>

namespace motolii {

// A GStreamer pipeline that decodes a video file to RGBA frames at 60 fps and
// hands them out one by one.
struct FilmRead {
  GstElement* reader = nullptr;
  GstAppSink* out = nullptr;
  int w = 0, h = 0;
  // The frame read last, as RGBA. At the end of the video it stays as the last
  // frame.
  std::vector<uint8_t> last;
  ~FilmRead() {
    if (reader)
      gst_element_set_state(reader, GST_STATE_NULL), gst_object_unref(reader);
    if (out) gst_object_unref(out);
  }
  // The folder of the images that the script came with; see
  // document/scripts/adapter.h.
  std::string beside;
  // Opens `file` and reads its first frame. `wide` is the frame width in
  // pixels, or 0 for the size of the video. Returns false if the pipeline
  // cannot be made or no frame arrives.
  bool open(const std::string& file, int wide);
  // Reads the next frame, 1/60 s later, into `last`. Returns true if `last`
  // holds a frame. At the end of the video or after a 5 s wait with no frame,
  // the previous frame is kept.
  bool next();
};

}  // namespace motolii

#endif  // MOTOLII_MEDIA_VIDEO_FRAMES_FOR_SCRIPTS_H_

#include "entry/calls_files.h"

#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include "entry/motolii.h"
#include "media/video_flash_check.h"

using namespace motolii;

namespace motolii {

int thumbnail_at(const char* video, const char* png, int wide, double fraction,
                 double seconds) {
  gst_init(nullptr, nullptr);
  gchar* uri = gst_filename_to_uri(video, nullptr);
  if (!uri) return 0;
  gchar* line = g_strdup_printf(
      "uridecodebin uri=\"%s\" ! videoconvert ! videoscale ! "
      "video/x-raw,width=%d,pixel-aspect-ratio=1/1 ! pngenc ! appsink name=out",
      uri, wide);
  GstElement* pipeline = gst_parse_launch(line, nullptr);
  g_free(line), g_free(uri);
  if (!pipeline) return 0;
  GstElement* out = gst_bin_get_by_name(GST_BIN(pipeline), "out");
  gst_element_set_state(pipeline, GST_STATE_PAUSED);
  GstSample* first =
      gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
  if (first && seconds > 0.0) {
    gst_sample_unref(first);
    gst_element_seek_simple(
        pipeline, GST_FORMAT_TIME,
        (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
        (gint64)(seconds * (double)GST_SECOND));
    first = gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
  } else if (first && fraction > 0.0) {
    gint64 length = 0;
    if (gst_element_query_duration(pipeline, GST_FORMAT_TIME, &length) &&
        length > 0) {
      gst_sample_unref(first);
      gst_element_seek_simple(
          pipeline, GST_FORMAT_TIME,
          (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
          (gint64)(std::min(fraction, 0.98) * (double)length));
      first = gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
    }
  }
  bool done = false;
  GstMapInfo bytes;
  if (first &&
      gst_buffer_map(gst_sample_get_buffer(first), &bytes, GST_MAP_READ)) {
    done = g_file_set_contents(png, (const gchar*)bytes.data,
                               (gssize)bytes.size, nullptr);
    gst_buffer_unmap(gst_sample_get_buffer(first), &bytes);
  }
  if (first) gst_sample_unref(first);
  gst_element_set_state(pipeline, GST_STATE_NULL);
  gst_object_unref(out);
  gst_object_unref(pipeline);
  return done;
}

}  // namespace motolii

// Writes the thumbnail at `fraction`, from 0 to 1, of the video's duration. See
// thumbnail_at.
int motolii_thumbnail_at(const char* video, const char* png, int wide,
                         double fraction) {
  return thumbnail_at(video, png, wide, fraction);
}
// Writes the thumbnail `seconds` into the video. See thumbnail_at.
int motolii_thumbnail_seconds(const char* video, const char* png, int wide,
                              double seconds) {
  return thumbnail_at(video, png, wide, 0.0, seconds);
}
// Describes a media file as the GStreamer discoverer sees it, as
// gst-discoverer-1.0 does. Returns "wide high rate seconds format": the size of
// the first video frame, frames per second, the duration in seconds, and the
// container or codec description that GStreamer gives. An image has a rate and
// a duration of 0. Returns "" if the file cannot be read. Needs no project. The
// string is valid until the same thread calls again.
const char* motolii_media_info(const char* file) {
  static thread_local std::string out;
  out.clear();
  gst_init(nullptr, nullptr);
  // The timeout is 20 seconds, twice the default of gst-discoverer-1.0, so that
  // a busy machine does not fail.
  GstDiscoverer* discoverer = gst_discoverer_new(20 * GST_SECOND, nullptr);
  // Read images with a software decoder such as jpegdec or pngdec.
  // VideoToolbox's vtdec_hw is ranked above jpegdec, and to get a JPEG's size
  // it opens a GL context and asks for a hardware scaler. The virtual machines
  // of CI Macs have none and report "IOServiceMatching failed for:
  // AppleM2ScalerParavirtDriver". Videos keep VideoToolbox because no software
  // HEVC decoder is available here.
  // The handler below answers the autoplug-select signal of uridecodebin. For
  // image caps it skips hardware factories, which GStreamer 1.18 marks with the
  // HARDWARE factory type. Otherwise it tries the factory. The discoverer's
  // uridecodebin is the parent of its source at source-setup.
  if (discoverer)
    g_signal_connect(
        discoverer, "source-setup",
        G_CALLBACK(+[](GstDiscoverer*, GstElement* source, gpointer) {
          if (GstObject* bin = gst_object_get_parent(GST_OBJECT(source))) {
            g_signal_connect(
                bin, "autoplug-select",
                G_CALLBACK(+[](GstElement*, GstPad*, GstCaps* caps,
                               GstElementFactory* f, gpointer) -> gint {
                  const bool still =
                      gst_caps_get_size(caps) > 0 &&
                      g_str_has_prefix(gst_structure_get_name(
                                           gst_caps_get_structure(caps, 0)),
                                       "image/");
                  // Return GST_AUTOPLUG_SELECT_SKIP, 2, for a hardware decoder
                  // of an image, otherwise TRY, 0.
                  return still && gst_element_factory_list_is_type(
                                      f, GST_ELEMENT_FACTORY_TYPE_HARDWARE)
                             ? 2
                             : 0;
                }),
                nullptr);
            gst_object_unref(bin);
          }
        }),
        nullptr);
  gchar* uri = gst_filename_to_uri(file, nullptr);
  GstDiscovererInfo* info =
      discoverer && uri ? gst_discoverer_discover_uri(discoverer, uri, nullptr)
                        : nullptr;
  // A file that is missing or is not media gives an empty answer.
  if (info && gst_discoverer_info_get_result(info) != GST_DISCOVERER_OK)
    g_object_unref(info), info = nullptr;
  if (info) {
    unsigned wide = 0, high = 0, num = 0, den = 1;
    GList* streams = gst_discoverer_info_get_video_streams(info);
    if (streams) {
      GstDiscovererVideoInfo* v = (GstDiscovererVideoInfo*)streams->data;
      wide = gst_discoverer_video_info_get_width(v),
      high = gst_discoverer_video_info_get_height(v);
      if (!gst_discoverer_video_info_is_image(v))
        num = gst_discoverer_video_info_get_framerate_num(v),
        den = std::max(1u, gst_discoverer_video_info_get_framerate_denom(v));
    }
    std::string kind;
    if (GstDiscovererStreamInfo* top =
            gst_discoverer_info_get_stream_info(info)) {
      if (GstCaps* caps = gst_discoverer_stream_info_get_caps(top)) {
        gchar* said = gst_pb_utils_get_codec_description(caps);
        if (said) kind = said, g_free(said);
        gst_caps_unref(caps);
      }
      gst_discoverer_stream_info_unref(top);
    }
    char line[512];
    std::snprintf(line, sizeof line, "%u %u %g %g %s", wide, high,
                  (double)num / den,
                  (double)gst_discoverer_info_get_duration(info) / GST_SECOND,
                  kind.c_str());
    out = line;
    gst_discoverer_stream_info_list_free(streams), g_object_unref(info);
  }
  g_free(uri);
  if (discoverer) g_object_unref(discoverer);
  return out.c_str();
}
// Checks a video for flashes and patterns that may cause seizures. IRIS does
// the work; see media/video_flash_check.h.
const char* motolii_flashes(const char* film, const char* folder) {
  return video_flash_check(film, folder);
}
// motolii_font_tags lives in engine/entry/calls_fonts.cpp, the one file that
// talks to the platform's font API. Adding Windows / Linux swaps that file's
// body for a FreeType or HarfBuzz one and keeps every other call here.

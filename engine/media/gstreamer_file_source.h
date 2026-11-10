// Helper that points a GStreamer pipeline's source element at a file.
#pragma once
#include <gst/gst.h>

// Sets the "location" property of the filesrc element named "in" in `pipeline` to `file`.
// The path is set with g_object_set, as in the GStreamer tutorials, instead of being written
// into the pipeline description. A path with non-ASCII characters would otherwise come back
// escaped and the file would not be found.

static void gst_read_from(GstElement* pipeline, const char* file) {
    if (GstElement* in = gst_bin_get_by_name(GST_BIN(pipeline), "in")) g_object_set(in, "location", file, nullptr), gst_object_unref(in);
}

#ifndef MOTOLII_MEDIA_VIDEO_LAYER_H_
#define MOTOLII_MEDIA_VIDEO_LAYER_H_

// Video layers: plays a video file as a flat quad in the stage.
//
// Any file GStreamer can read is accepted; GStreamer chooses the demuxers and decoders. The quad
// is a normal layer in the stage, drawn with flat.mat like ThorVG images, so mattes, glass and
// chroma keying (`green`) all work on it.
//
// GStreamer decodes with the machine's hardware decoder. Each decoded frame stays on the GPU
// (an IOSurface on macOS) and is shared with Filament's WebGPU device without a copy, through
// Dawn's SharedTextureMemory. The luma and chroma planes of the frame are two planes of one
// texture, and flat.mat converts them to RGB. No frame data goes through the CPU. The frame to
// show is chosen by the video's own timestamps, because the frame rate of a phone video is not
// constant. A video that carries a rotation tag, such as one shot in portrait, is rotated.
//
// Works only on the WebGPU backend (BACKEND=webgpu, gpu/filament_webgpu.sh with KIT_EXTRA, see
// puppet.sh), where Filament requests the texture sharing (filament_dawn_compute.patch). Only the
// macOS interop is implemented so far.

#include <atomic>
#include <cstdint>
#include <map>
#include <string>

#include <CoreVideo/CoreVideo.h>

#include <filament/MaterialInstance.h>
#include <filament/Texture.h>
#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec4.h>
#include <webgpu/webgpu.h>

#include "stage/render/render_stage.h"

// State of one video layer: its GStreamer reader, the frames being shown, and the quad that
// displays them.
struct Video {
    // The GStreamer pipeline that reads this video.
    GstElement* reader = nullptr;
    GstAppSink* out = nullptr;
    // The current frame. It is kept referenced so that the decoder does not overwrite it.
    GstSample* held = nullptr;
    // The frame after `held`, once it has arrived. Its timestamp says until when `held` is the
    // current frame.
    GstSample* next = nullptr;
    // The frame that is on the quad. It equals `held`, except while a new surface is being shared.
    GstSample* on = nullptr;
    // Time at which `next` is due, in seconds of the reader's running time, including repeats.
    double nextAt = 0.0;
    // True after a seek back was requested and until its first frame has arrived. Only one seek
    // is in flight at a time, as in Pitivi.
    bool seeking = false;
    // The time requested while a seek was in flight, or -1 if none. It is sought once the
    // current seek has finished.
    float want = -1.f;
    // `origin` is the stage time at which the current run began. `last` is the stage time of the
    // most recent request.
    double origin = 0.0, last = 0.0;
    // `turned` is the number of clockwise quarter turns the video asks for before it is shown.
    int w = 0, h = 0, turned = 0;
    // Length of the video as shown, after the cut and the speed are applied.
    float seconds = 0.f;
    // How far into the cut the video is when the stage time is 0.
    float starts = 0.f;
    // The part of the file that is shown, in seconds of the file, and the playback speed.
    // A negative speed plays backwards.
    float from = 0.f, to = 0.f, speed = 1.f;
    // True if the file also has an audio stream.
    std::atomic<bool> sound{false};
    // True if the file is audio only. Its image is then a wavescope drawn by GStreamer, the way
    // playbin draws a visualization when there is no video (GST_PLAY_FLAG_VIS).
    bool heard = false;
    // True once the reader has read to the end of the cut. The end-of-segment event travels down
    // the frame stream after the last frame.
    std::atomic<bool> ended{false};
    // Chroma key parameters (see `green`). Until the first frame is on the quad the key makes the
    // quad fully transparent.
    filament::math::float4 key{0.f};
    filament::math::float2 keySoft{0.f};
    // Keying by the video's own background color, which is the color shared by its four corners.
    // 1 keys only if such a color exists. 2 keys always, using green if there is none.
    int own = 0;
    // Converts the luma and the two chroma values to red, green and blue.
    filament::math::mat4f rule;
    // The quad in the stage. It is moved like any other layer (see render.h: move).
    Mesh* sheet = nullptr;
    // The material instance of the quad.
    filament::MaterialInstance* look = nullptr;
    // A decoder surface that has been shared with Filament.
    struct Planes { std::atomic<WGPUTexture> shared{nullptr}; WGPUSharedTextureMemory lent = nullptr; filament::Texture* light = nullptr; filament::Texture* colour = nullptr; gint64 used = 0; };
    // ID of the surface that is on the quad.
    uint32_t shown = 0;
    // The element that receives the reader's frames: `out`, or a converter in front of it when
    // the video is read on the CPU.
    GstElement* into = nullptr;
    // Used when the video is read on the CPU because the hardware decoder had no capacity left.
    // The luma and chroma planes are uploaded to the GPU frame by frame.
    filament::Texture* cpuLight = nullptr;
    filament::Texture* cpuColour = nullptr;
    // The decoder reuses its surfaces, so each one is shared only once, keyed by surface ID.
    std::map<uint32_t, Planes> seen;
};

// The macOS GStreamer plugin attaches the decoder's pixel buffer to a GstBuffer under this meta
// name and layout. The layout is from gst-plugins-bad, sys/applemedia/corevideobuffer.h, which
// is not installed as a public header.
struct VideoCoreVideoMeta { GstMeta meta; CVBufferRef cvbuf; CVPixelBufferRef pixbuf; };

// Explains why the last video that could not be shown failed. Read by the caller when video()
// returns null.
extern const char* video_trouble;
// Counters for the statistics line. `video_asked` counts requests for a frame at a time.
// `video_late` counts requests where the decoder could not yet provide the frame for that time.
extern long video_asked, video_late;

// Adds the video in `file` to the stage as a quad `high` tall, as wide as the video's aspect
// ratio makes it, centered at `place` and facing along the z axis of `place`.
//   from, to: the part of the file to show, in seconds of the file. A `to` below 0 means the end.
//   speed: playback speed. 2 is twice as fast, 0.5 is half speed, below 0 plays backwards.
//   lay, lit, wear: passed to flat_laid() to choose the material. `wear` names a material from
//     doc_sheet_material.
// Returns null and sets video_trouble if the video cannot be shown.
Video* video(Stage& s, const char* file, const filament::math::mat4f& place, float high, float from = 0.f, float to = -1.f, float speed = 1.f, const char* lay = nullptr, bool lit = false, const std::string& wear = "");

// Removes a video from the stage for good. Its quad is removed, its reader is stopped, and its
// resources are released.
void video_off(Stage& s, Video* v);

// Keys the video by its own background color. This is the color its four corners share in the
// first frame, so a green screen of any shade works without being told which. With `always`
// the video is keyed even if it has no such color, and then it is keyed as a green screen.
void key_own(Video* v, bool always);

// Sets the video to `seconds` of the stage time, for the frame that is drawn next. The video
// loops when it ends. The frame for a time is the last one due by then, judged by the video's own
// timestamps.
void video_at(Stage& s, Video* v, float seconds);

#endif  // MOTOLII_MEDIA_VIDEO_LAYER_H_

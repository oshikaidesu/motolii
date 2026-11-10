#include "media/video_layer.h"

#include <CoreVideo/CoreVideo.h>
#include <IOSurface/IOSurface.h>
#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>
#include <gst/video/video.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <webgpu/webgpu.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <string>

#include "gpu/gpu_interop.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

const char* video_trouble = "";
long video_asked = 0, video_late = 0;

namespace {

bool video_counted = false;

// Returns the time at which a frame is due, in seconds of running time,
// including repeats. This is the frame's own timestamp.
double video_due(GstSample* sample) {
  const GstClockTime at = gst_segment_to_running_time(
      gst_sample_get_segment(sample), GST_FORMAT_TIME,
      GST_BUFFER_PTS(gst_sample_get_buffer(sample)));
  return GST_CLOCK_TIME_IS_VALID(at) ? (double)at / (double)GST_SECOND : 0.0;
}

// Number of decoder surfaces that are currently shared with Filament.
long video_shared = 0;
// Releases a surface that was shared. Filament's two texture views are
// destroyed first, then Dawn's end of the shared access is closed.
void video_give_back(Stage& s, Video::Planes& planes) {
  --video_shared;
  if (planes.light) s.engine->destroy(planes.light);
  if (planes.colour) s.engine->destroy(planes.colour);
  interop::on_driver(s.engine,
                     [lent = planes.lent, shared = planes.shared.load()] {
                       WGPUSharedTextureMemoryEndAccessState ended{};
                       wgpuSharedTextureMemoryEndAccess(lent, shared, &ended);
                       wgpuSharedTextureMemoryEndAccessStateFreeMembers(ended);
                       wgpuTextureRelease(shared);
                       wgpuSharedTextureMemoryRelease(lent);
                     });
}

// Returns the CoreVideo pixel buffer behind a frame, or null if the frame is in
// CPU memory.
CVPixelBufferRef video_surface(GstSample* sample) {
  const GType api = g_type_from_name("GstCoreVideoMetaAPI");
  VideoCoreVideoMeta* meta = api ? (VideoCoreVideoMeta*)gst_buffer_get_meta(
                                       gst_sample_get_buffer(sample), api)
                                 : nullptr;
  return meta ? meta->pixbuf : nullptr;
}
// Detects the background color of a video. This is the color that the frame has
// in all four corners, if the corners agree and the color is strongly
// saturated, such as a green or blue screen of any shade. Reads four small
// patches from the planes of the first frame, through GStreamer's
// gst_video_frame_map, which works the same on every platform. Returns true and
// fills `ground` (RGB) and `strong` (distance of its chroma from gray) if such
// a color exists.
bool video_ground(Video* v, GstSample* sample, float3* ground, float* strong) {
  GstVideoInfo info;
  GstVideoFrame planes;
  // Only NV12 is handled: a luma plane, and an interleaved chroma plane at half
  // the size.
  if (!gst_video_info_from_caps(&info, gst_sample_get_caps(sample)) ||
      GST_VIDEO_INFO_FORMAT(&info) != GST_VIDEO_FORMAT_NV12)
    return false;
  if (!gst_video_frame_map(&planes, &info, gst_sample_get_buffer(sample),
                           GST_MAP_READ))
    return false;
  const uint8_t* light = (const uint8_t*)GST_VIDEO_FRAME_PLANE_DATA(&planes, 0);
  const uint8_t* colours =
      (const uint8_t*)GST_VIDEO_FRAME_PLANE_DATA(&planes, 1);
  const size_t lightRow = (size_t)GST_VIDEO_FRAME_PLANE_STRIDE(&planes, 0),
               coloursRow = (size_t)GST_VIDEO_FRAME_PLANE_STRIDE(&planes, 1);
  // Sizes are in samples of the chroma plane. The patches sit a little inside
  // the edge.
  const int w = v->w / 2, h = v->h / 2, in = std::max(2, std::min(w, h) / 40);
  // Chroma of an RGB color. The weights are the same as in flat.mat.
  const auto hue = [](float3 c) {
    return float2{dot(c, float3{-0.1146f, -0.3854f, 0.5f}),
                  dot(c, float3{0.5f, -0.4542f, -0.0458f})};
  };
  float3 corner[4];
  for (int i = 0; i < 4; ++i) {
    const int x = i & 1 ? w - 1 - in : in, y = i & 2 ? h - 1 - in : in;
    float3 sum{0.f};
    for (int dy = 0; dy < 4; ++dy)
      for (int dx = 0; dx < 4; ++dx) {
        const int cx = std::clamp(x + dx - 2, 0, w - 1),
                  cy = std::clamp(y + dy - 2, 0, h - 1);
        sum += float3{
            (float)light[(size_t)(cy * 2) * lightRow + (size_t)(cx * 2)],
            (float)colours[(size_t)cy * coloursRow + (size_t)cx * 2],
            (float)colours[(size_t)cy * coloursRow + (size_t)cx * 2 + 1]};
      }
    corner[i] = clamp((v->rule * float4{sum / (16.f * 255.f), 1.f}).xyz,
                      float3{0.f}, float3{1.f});
  }
  gst_video_frame_unmap(&planes);
  const float3 mean = 0.25f * (corner[0] + corner[1] + corner[2] + corner[3]);
  float apart = 0.f;
  for (const float3& c : corner)
    apart = std::max(apart, distance(hue(c), hue(mean)));
  // Thresholds measured on 23 files that have a screen: the corners were at
  // most 0.003 apart, a bright green was 0.5 to 0.6 from gray, and a dark green
  // was 0.17.
  *ground = mean, *strong = length(hue(mean));
  return apart < 0.05f && *strong > 0.15f;
}
// Computes the key of a video that is keyed by its own background color, from
// the given frame. Falls back to pure green if the frame has no such color and
// `own` is 2.
void video_own_key(Video* v, GstSample* sample) {
  float3 ground{0.f, 1.f, 0.f};
  // Chroma distance from gray of pure green.
  float strong = 0.6f;
  const bool has = sample && video_ground(v, sample, &ground, &strong);
  if (!has) ground = float3{0.f, 1.f, 0.f}, strong = 0.6f;
  // The thresholds are the ones render.h uses for pure green, scaled by how far
  // this color is from gray. They set how near a color must be to count as the
  // screen, how wide the soft edge is, and how much of the color is removed. A
  // dark green has grays nearer to it, so its thresholds are smaller.
  if (v->own && (has || v->own == 2))
    v->key = float4{ground, 0.2f * strong},
    v->keySoft = float2{0.5f * strong, 1.5f * strong};
}
// Shows a frame that was read on the CPU. This is used when the hardware
// decoder had no capacity left. The luma and chroma planes are copied into two
// Filament textures, which are then bound in the same way as the shared planes
// of a GPU frame. Returns false if the frame cannot be read.
bool video_show_copied(Stage& s, Video* v) {
  GstVideoInfo info;
  GstVideoFrame frame;
  if (!gst_video_info_from_caps(&info, gst_sample_get_caps(v->held)) ||
      GST_VIDEO_INFO_FORMAT(&info) != GST_VIDEO_FORMAT_NV12 ||
      !gst_video_frame_map(&frame, &info, gst_sample_get_buffer(v->held),
                           GST_MAP_READ))
    return false;
  const int w = v->w, h = v->h, cw = (w + 1) / 2, ch = (h + 1) / 2;
  const TextureSampler smooth(TextureSampler::MinFilter::LINEAR,
                              TextureSampler::MagFilter::LINEAR,
                              TextureSampler::WrapMode::CLAMP_TO_EDGE);
  if (!v->cpuLight) {
    v->cpuLight = Texture::Builder()
                      .width((uint32_t)w)
                      .height((uint32_t)h)
                      .levels(1)
                      .format(Texture::InternalFormat::R8)
                      .build(*s.engine);
    v->cpuColour = Texture::Builder()
                       .width((uint32_t)cw)
                       .height((uint32_t)ch)
                       .levels(1)
                       .format(Texture::InternalFormat::RG8)
                       .build(*s.engine);
  }
  // Uploads one plane, packed without the decoder's row padding.
  const auto up = [&](Texture* t, int plane, int pw, int ph, int bytes,
                      Texture::Format as) {
    auto* copy = (uint8_t*)std::malloc((size_t)pw * ph * bytes);
    const uint8_t* from =
        (const uint8_t*)GST_VIDEO_FRAME_PLANE_DATA(&frame, plane);
    const int stride = GST_VIDEO_FRAME_PLANE_STRIDE(&frame, plane);
    for (int y = 0; y < ph; ++y)
      std::memcpy(copy + (size_t)y * pw * bytes, from + (size_t)y * stride,
                  (size_t)pw * bytes);
    t->setImage(
        *s.engine, 0,
        Texture::PixelBufferDescriptor(
            copy, (size_t)pw * ph * bytes, as, Texture::Type::UBYTE, 1, 0, 0, 0,
            [](void* buffer, size_t, void*) { std::free(buffer); }));
  };
  up(v->cpuLight, 0, w, h, 1, Texture::Format::R);
  up(v->cpuColour, 1, cw, ch, 2, Texture::Format::RG);
  gst_video_frame_unmap(&frame);
  v->look->setParameter("picture", v->cpuLight, smooth);
  v->look->setParameter("colours", v->cpuColour, smooth);
  // First frame: set the chroma key from now on.
  if (!v->on) {
    video_own_key(v, v->held);
    v->look->setParameter("key", v->key);
    v->look->setParameter("keySoft", v->keySoft);
  }
  if (v->on && v->on != v->held) gst_sample_unref(v->on);
  v->on = v->held;
  return true;
}
// Puts the held frame on the quad. A surface seen for the first time is shared
// with Filament's device on Filament's own thread, without waiting for it.
// Until that finishes, which takes a frame or two, the quad keeps the frame it
// had. Returns false if the held frame is not on the quad yet.
bool video_show(Stage& s, Video* v) {
  CVPixelBufferRef held = video_surface(v->held);
  IOSurfaceRef surface = held ? CVPixelBufferGetIOSurface(held) : nullptr;
  if (!surface) return video_show_copied(s, v);
  auto found = v->seen.find(IOSurfaceGetID(surface));
  if (found == v->seen.end()) {
    // A decoder cycles through a few surfaces and takes new ones when the video
    // loops. A surface that the decoder has not handed out for two seconds is
    // given back, except the one that is on the quad.
    for (auto it = v->seen.begin(); it != v->seen.end();)
      if (it->second.shared && it->first != v->shown &&
          g_get_monotonic_time() - it->second.used > 2 * G_USEC_PER_SEC) {
        video_give_back(s, it->second);
        it = v->seen.erase(it);
      } else
        ++it;
    Video::Planes* planes = &v->seen[IOSurfaceGetID(surface)];
    planes->used = g_get_monotonic_time();
    ++video_shared;
    CFRetain(surface);
    const uint32_t w = (uint32_t)v->w, h = (uint32_t)v->h;
    Engine* engine = s.engine;
    interop::on_driver(engine, [planes, surface, w, h, engine] {
      WGPUSharedTextureMemoryIOSurfaceDescriptor from{};
      from.chain.sType = WGPUSType_SharedTextureMemoryIOSurfaceDescriptor;
      from.ioSurface = surface;
      WGPUSharedTextureMemoryDescriptor what{};
      what.nextInChain = &from.chain;
      WGPUSharedTextureMemory memory = wgpuDeviceImportSharedTextureMemory(
          (WGPUDevice)interop::device(engine), &what);
      WGPUTextureDescriptor like{};
      like.size = {w, h, 1};
      // Luma plus chroma at half the size, which is what the decoder produces.
      like.format = WGPUTextureFormat_R8BG8Biplanar420Unorm;
      like.usage = WGPUTextureUsage_TextureBinding;
      like.dimension = WGPUTextureDimension_2D;
      like.mipLevelCount = 1;
      like.sampleCount = 1;
      WGPUTexture shared = wgpuSharedTextureMemoryCreateTexture(memory, &like);
      // Access is never ended while the surface is shared. The decoder writes a
      // surface only while nobody holds its frame, and the frame being shown is
      // held.
      WGPUSharedTextureMemoryBeginAccessDescriptor lend{};
      lend.initialized = true;
      wgpuSharedTextureMemoryBeginAccess(memory, shared, &lend);
      CFRelease(surface);
      planes->lent = memory;
      planes->shared = shared;
    });
    return false;
  }
  Video::Planes& planes = found->second;
  WGPUTexture shared = planes.shared;
  planes.used = g_get_monotonic_time();
  // The surface is still being shared on the driver thread.
  if (!shared) return false;
  v->shown = found->first;
  if (!planes.light) {
    const auto plane = [&](Texture::InternalFormat as, int w, int h) {
      return Texture::Builder()
          .width((uint32_t)w)
          .height((uint32_t)h)
          .levels(1)
          .sampler(Texture::Sampler::SAMPLER_2D)
          .format(as)
          .usage(Texture::Usage::SAMPLEABLE)
          .import((intptr_t)shared)
          .build(*s.engine);
    };
    planes.light = plane(Texture::InternalFormat::R8, v->w, v->h);
    planes.colour = plane(Texture::InternalFormat::RG8, v->w / 2, v->h / 2);
  }
  const TextureSampler smooth(TextureSampler::MinFilter::LINEAR,
                              TextureSampler::MagFilter::LINEAR,
                              TextureSampler::WrapMode::CLAMP_TO_EDGE);
  v->look->setParameter("picture", planes.light, smooth);
  v->look->setParameter("colours", planes.colour, smooth);
  // First frame: set the chroma key from now on.
  if (!v->on) {
    video_own_key(v, v->held);
    v->look->setParameter("key", v->key);
    v->look->setParameter("keySoft", v->keySoft);
  }
  if (v->on && v->on != v->held) gst_sample_unref(v->on);
  v->on = v->held;
  return true;
}

// Puts the held frame on the quad for the frame that is drawn next. When the
// stage is rendered frame by frame, this waits for a surface that is being
// shared. That takes a moment, once for each decoder surface. When the stage is
// played in real time it does not wait.
void video_put(Stage& s, Video* v) {
  if (v->on == v->held || video_show(s, v) || s.by_clock) return;
  s.engine->flushAndWait();
  video_show(s, v);
}

// Seeks the reader to `seconds` of the video as shown (into its cut, at its
// speed). Playback continues from there and loops without a gap at the end of
// the cut. This uses a GStreamer segment seek with a rate. At the end of the
// segment it posts a segment-done message on the bus instead of ending the
// stream. Played backwards, the segment runs from its end down to its start.
// With `afresh` the pipeline is flushed and the seek is accurate.
void video_from(Video* v, float seconds, bool afresh) {
  // How far into the cut, in seconds of the file.
  const double at = (double)seconds * std::fabs((double)v->speed);
  const double start = v->speed > 0.f ? (double)v->from + at : (double)v->from,
               stop = v->speed > 0.f ? (double)v->to : (double)v->to - at;
  gst_element_seek(
      v->reader, (double)v->speed, GST_FORMAT_TIME,
      (GstSeekFlags)((afresh ? GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE
                             : 0) |
                     GST_SEEK_FLAG_SEGMENT),
      GST_SEEK_TYPE_SET, (gint64)(start * (double)GST_SECOND),
      GST_SEEK_TYPE_SET, (gint64)(stop * (double)GST_SECOND));
}

// Pad probe that records the end of the cut. The segment-done event arrives
// down the frame stream. GStreamer also posts it on the bus, but only after
// every stream of the file has ended, and when played backwards the audio
// stream never ends.
GstPadProbeReturn video_ending(GstPad*, GstPadProbeInfo* info, gpointer film) {
  if (GST_EVENT_TYPE(GST_PAD_PROBE_INFO_EVENT(info)) == GST_EVENT_SEGMENT_DONE)
    ((Video*)film)->ended = true;
  return GST_PAD_PROBE_OK;
}

// Chooses which streams of the file the reader reads. GStreamer calls this once
// per stream. Normally only the video stream is read and the audio stream is
// not. Reading the audio and dropping it made 51 decoders do the work, and an
// HEVC video that played slower than it was shot then produced no frame at all.
// So GStreamer alone, 1.28.8, with only the wanted stream taken, is used. An
// audio-only file takes its audio stream instead.
gint video_wanted(GstElement*, GstStreamCollection*, GstStream* stream,
                  gpointer film) {
  // Record that the file has audio, which is played when the project is
  // exported (see render.h).
  if (gst_stream_get_stream_type(stream) & GST_STREAM_TYPE_AUDIO)
    ((Video*)film)->sound = true;
  return (gst_stream_get_stream_type(stream) &
          (((Video*)film)->heard ? GST_STREAM_TYPE_AUDIO
                                 : GST_STREAM_TYPE_VIDEO))
             ? 1
             : 0;
}

// Links the stream that the reader found in the file to the element that
// receives the frames.
void video_found(GstElement*, GstPad* stream, gpointer film) {
  GstPad* to = gst_element_get_static_pad(((Video*)film)->into, "sink");
  if (!gst_pad_is_linked(to)) gst_pad_link(stream, to);
  gst_object_unref(to);
}

// Returns the length of a file in nanoseconds as reported by GStreamer's
// discoverer, which reads on until it knows. This is what gst-discoverer-1.0
// does. Returns 0 if it cannot be found.
gint64 video_discovered(const char* file) {
  GstDiscoverer* looks = gst_discoverer_new(5 * GST_SECOND, nullptr);
  gchar* uri = gst_filename_to_uri(file, nullptr);
  GstDiscovererInfo* info =
      looks && uri ? gst_discoverer_discover_uri(looks, uri, nullptr) : nullptr;
  const gint64 length =
      info ? (gint64)gst_discoverer_info_get_duration(info) : 0;
  if (info) g_object_unref(info);
  if (looks) g_object_unref(looks);
  g_free(uri);
  return length;
}

}  // namespace

Video* video(Stage& s, const char* file, const mat4f& place, float high,
             float from, float to, float speed, const char* lay, bool lit,
             const std::string& wear) {
  // Another backend is in use.
  if (!interop::device(s.engine))
    return video_trouble = "not the WebGPU backend", nullptr;
  static const bool started = (gst_init(nullptr, nullptr), true);
  (void)started;
  Video* v = new Video;
  {
    // Detect an audio-only file. GStreamer's discoverer reports audio streams,
    // and for an album cover only still images, as gst-discoverer-1.0 shows.
    GstDiscoverer* looks = gst_discoverer_new(5 * GST_SECOND, nullptr);
    gchar* uri = gst_filename_to_uri(file, nullptr);
    if (GstDiscovererInfo* info =
            looks && uri ? gst_discoverer_discover_uri(looks, uri, nullptr)
                         : nullptr) {
      GList *videoStreams = gst_discoverer_info_get_video_streams(info),
            *sounds = gst_discoverer_info_get_audio_streams(info);
      bool moving = false;
      for (GList* p = videoStreams; p; p = p->next)
        moving = moving || !gst_discoverer_video_info_is_image(
                               (GstDiscovererVideoInfo*)p->data);
      v->heard = sounds && !moving;
      gst_discoverer_stream_info_list_free(videoStreams),
          gst_discoverer_stream_info_list_free(sounds), g_object_unref(info);
    }
    g_free(uri);
    if (looks) g_object_unref(looks);
  }
  // First try the hardware decoder. Where it has no capacity left, for example
  // with 59 videos at once on an M4, retry with a CPU decoder and copy the
  // frames up. The retry uses decodebin, told to skip the hardware decoders,
  // and a converter to NV12.
  for (int cpu = 0; cpu < 2; ++cpu) {
    if (v->reader)
      gst_element_set_state(v->reader, GST_STATE_NULL),
          gst_object_unref(v->reader), v->reader = nullptr;
    v->reader = gst_pipeline_new(nullptr);
    GstElement* opens = gst_element_factory_make("filesrc", nullptr);
    // Chooses the demuxers and decoders for whatever the file is.
    GstElement* reads =
        gst_element_factory_make(cpu ? "decodebin" : "decodebin3", nullptr);
    GstElement* turn = cpu && !v->heard
                           ? gst_element_factory_make("videoconvert", nullptr)
                           : nullptr;
    v->out = GST_APP_SINK(gst_element_factory_make("appsink", nullptr));
    if (!opens || !reads || !v->out || (cpu && !turn))
      return video_trouble =
                 "GStreamer lacks a part (filesrc, decodebin3, decodebin, "
                 "videoconvert or appsink)",
             nullptr;
    // Luma and chroma in separate planes, eight bits. This is the format
    // video_layer.h shares.
    GstCaps* wanted = gst_caps_from_string("video/x-raw,format=NV12");
    g_object_set(opens, "location", file, nullptr);
    g_object_set(v->out, "sync", FALSE, "max-buffers", 2, "caps", wanted,
                 nullptr);
    gst_caps_unref(wanted);
    gst_bin_add_many(GST_BIN(v->reader), opens, reads, GST_ELEMENT(v->out),
                     nullptr);
    gst_element_link(opens, reads);
    if (turn)
      gst_bin_add(GST_BIN(v->reader), turn),
          gst_element_link(turn, GST_ELEMENT(v->out));
    v->into = turn ? turn : GST_ELEMENT(v->out);
    if (v->heard) {
      // Draw the audio as a wave: audioconvert ! wavescope ! a 1280 by 720
      // frame ! videoconvert, into `out`.
      GstElement *a = gst_element_factory_make("audioconvert", nullptr),
                 *scope = gst_element_factory_make("wavescope", nullptr),
                 *size = gst_element_factory_make("capsfilter", nullptr),
                 *c = gst_element_factory_make("videoconvert", nullptr);
      if (!a || !scope || !size || !c)
        return video_trouble =
                   "GStreamer lacks a part (audioconvert, wavescope, "
                   "capsfilter or videoconvert)",
               nullptr;
      GstCaps* big = gst_caps_from_string(
          "video/x-raw,width=1280,height=720,framerate=30/1");
      g_object_set(size, "caps", big, nullptr), gst_caps_unref(big);
      gst_bin_add_many(GST_BIN(v->reader), a, scope, size, c, nullptr);
      gst_element_link_many(a, scope, size, c, GST_ELEMENT(v->out), nullptr);
      v->into = a;
      v->sound = true;
    }
    if (cpu)
      g_signal_connect(reads, "autoplug-select",
                       G_CALLBACK(+[](GstElement*, GstPad*, GstCaps*,
                                      GstElementFactory* part, gpointer) {
                         return g_str_has_prefix(GST_OBJECT_NAME(part), "vtdec")
                                    ? 2 /* GST_AUTOPLUG_SELECT_SKIP */
                                    : 0 /* TRY */;
                       }),
                       nullptr);
    else
      g_signal_connect(reads, "select-stream", G_CALLBACK(video_wanted), v);
    g_signal_connect(reads, "pad-added", G_CALLBACK(video_found), v);
    GstPad* in = gst_element_get_static_pad(GST_ELEMENT(v->out), "sink");
    gst_pad_add_probe(in, GST_PAD_PROBE_TYPE_EVENT_DOWNSTREAM, video_ending, v,
                      nullptr);
    gst_object_unref(in);
    gst_element_set_state(v->reader, GST_STATE_PAUSED);
    // Wait until the file is open and its first frame is there.
    if (gst_element_get_state(v->reader, nullptr, nullptr, 5 * GST_SECOND) ==
        GST_STATE_CHANGE_FAILURE)
      continue;
    gint64 length = 0;
    // An .mp3 reports no length: its parser estimates one from the frames it
    // has seen, and the appsink stopped it after the first. The discoverer is
    // used instead.
    if (!gst_element_query_duration(v->reader, GST_FORMAT_TIME, &length) ||
        length <= 0)
      length = video_discovered(file);
    if (length <= 0)
      return video_trouble = "the file does not open as a film (no length)",
             nullptr;
    v->from = std::max(0.f, from);
    v->to = to < 0.f
                ? (float)((double)length / (double)GST_SECOND)
                : std::min(to, (float)((double)length / (double)GST_SECOND));
    if (speed == 0.f)
      return video_trouble =
                 "a speed of 0 shows nothing: a film goes forwards or "
                 "backwards",
             nullptr;
    v->speed = speed;
    v->seconds = (v->to - v->from) / std::fabs(v->speed);
    if (v->seconds <= 0.f) return video_trouble = "the cut is empty", nullptr;
    video_from(v, 0.f, true);
    gst_element_set_state(v->reader, GST_STATE_PLAYING);
    // The first frame tells how large the video is.
    if ((v->held =
             gst_app_sink_try_pull_sample(v->out, (cpu ? 5 : 2) * GST_SECOND)))
      break;
  }
  if (!v->held)
    return video_trouble = "no frame came within 5 seconds", nullptr;
  const GstStructure* said =
      gst_caps_get_structure(gst_sample_get_caps(v->held), 0);
  if (!gst_structure_get_int(said, "width", &v->w) ||
      !gst_structure_get_int(said, "height", &v->h))
    return video_trouble = "the frame does not say its size", nullptr;
  // Build the video's own color conversion, as GStreamer read it from the file.
  // It consists of the two luma weights (Kr, Kb) of BT.601, BT.709 or BT.2020,
  // and the positions of black, white and zero chroma in its sample values,
  // which depend on the narrow or full range.
  GstVideoInfo told;
  gdouble kr = 0.2126, kb = 0.0722;
  gint zero[GST_VIDEO_MAX_COMPONENTS] = {16, 128, 128},
       span[GST_VIDEO_MAX_COMPONENTS] = {219, 224, 224};
  if (gst_video_info_from_caps(&told, gst_sample_get_caps(v->held))) {
    gst_video_color_matrix_get_Kr_Kb(told.colorimetry.matrix, &kr, &kb);
    // The range is read from the pixel buffer itself where possible. The macOS
    // decoder delivers the narrow range whatever the file used, and the caps
    // keep naming the file's.
    CVPixelBufferRef first = video_surface(v->held);
    const GstVideoColorRange range =
        !first ? told.colorimetry.range
        : CVPixelBufferGetPixelFormatType(first) ==
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ? GST_VIDEO_COLOR_RANGE_0_255
            : GST_VIDEO_COLOR_RANGE_16_235;
    gst_video_color_range_offsets(range, told.finfo, zero, span);
  }
  const float kg = 1.f - (float)kr - (float)kb, red = 2.f * (1.f - (float)kr),
              blue = 2.f * (1.f - (float)kb);
  const float3 gain{255.f / (float)span[0], 255.f / (float)span[1],
                    255.f / (float)span[2]},
      base{-(float)zero[0] / (float)span[0], -(float)zero[1] / (float)span[1],
           -(float)zero[2] / (float)span[2]};
  // What the two chroma values add to red, green and blue.
  const float3 byBlue{0.f, -blue * (float)kb / kg, blue},
      byRed{red, -red * (float)kr / kg, 0.f};
  const mat4f rule(
      float4{float3{gain.x}, 0.f}, float4{gain.y * byBlue, 0.f},
      float4{gain.z * byRed, 0.f},
      float4{float3{base.x} + base.y * byBlue + base.z * byRed, 1.f});
  GstBus* bus = gst_element_get_bus(v->reader);
  // A video shot in portrait carries a tag that says which way to rotate it.
  while (GstMessage* said = gst_bus_pop_filtered(bus, GST_MESSAGE_TAG)) {
    GstTagList* tags = nullptr;
    GstVideoOrientationMethod way = GST_VIDEO_ORIENTATION_IDENTITY;
    gst_message_parse_tag(said, &tags);
    if (gst_video_orientation_from_tag(tags, &way))
      v->turned = way == GST_VIDEO_ORIENTATION_90R   ? 1
                  : way == GST_VIDEO_ORIENTATION_180 ? 2
                  : way == GST_VIDEO_ORIENTATION_90L ? 3
                                                     : 0;
    gst_tag_list_unref(tags);
    gst_message_unref(said);
  }
  // Nothing more is read from the bus. Later messages are dropped instead of
  // queued.
  gst_bus_set_flushing(bus, TRUE);
  gst_object_unref(bus);
  // Aspect ratio as shown, after the rotation.
  const float wide =
      v->turned % 2 ? (float)v->h / (float)v->w : (float)v->w / (float)v->h;
  v->sheet = new Mesh;
  for (float2 c :
       {float2{-1, -1}, float2{1, -1}, float2{1, 1}, float2{-1, 1}}) {
    v->sheet->pos.push_back({0.5f * high * wide * c.x, 0.5f * high * c.y, 0.f});
    v->sheet->nrm.push_back({0, 0, 1});
    // The point of the video at this corner: the corner rotated back the other
    // way.
    const float2 of = v->turned == 1   ? float2{-c.y, c.x}
                      : v->turned == 2 ? float2{-c.x, -c.y}
                      : v->turned == 3 ? float2{c.y, -c.x}
                                       : c;
    // The first row of a video is its top. Filament flips v for a quad itself.
    v->sheet->uv.push_back(of * 0.5f + 0.5f);
  }
  v->sheet->idx = {0, 1, 2, 0, 2, 3};
  v->look =
      add(s, v->sheet, flat_laid(lay, lit, wear).c_str(), {place}, 1, lit);
  // A solid's default surface color.
  if (lit) v->look->setParameter("surface", float3{0.08f, 0.6f, 0.5f});
  if (!v->look) return video_trouble = "flat.filamat", nullptr;
  v->look->setParameter("filmed", 1.f);
  v->look->setParameter("filmRule", rule);
  v->rule = rule;
  // Until the first frame is shared, show a white that is keyed out completely,
  // so the quad is not visible.
  v->look->setParameter("picture", white_point(s), TextureSampler());
  v->look->setParameter("key", float4{1.f, 0.5f, 1.f, 9.f});
  v->look->setParameter("keySoft", float2{1.f, 1.f});
  video_put(s, v);
  // The video advances by itself as the stage time does.
  s.playing[v] = [&s, v](double now) {
    video_at(s, v, (float)now + v->starts);
  };
  if (v->sound)
    s.sounding[v] = [v, name = std::string(file)] {
      return Stage::Sound{name, v->from, v->to, v->speed, v->starts, 0.0, -1.0};
    };
  if (s.said_after.empty() || !video_counted) {
    video_counted = true;
    // Reports, for the requests in that period, how often a video could not yet
    // provide the frame for the requested time.
    s.said_after.push_back([] {
      std::printf(
          "    films late %ld of %ld times asked (%.2f %%); surfaces shared "
          "now %ld\n",
          video_late, video_asked,
          video_asked ? 100.0 * (double)video_late / (double)video_asked : 0.0,
          video_shared);
      video_asked = video_late = 0;
    });
  }
  return v;
}

void video_off(Stage& s, Video* v) {
  s.playing.erase(v);
  s.sounding.erase(v);
  take_off(s, v->sheet);
  // A surface may still be in the middle of being shared.
  s.engine->flushAndWait();
  gst_element_set_state(v->reader, GST_STATE_NULL);
  if (v->next) gst_sample_unref(v->next);
  if (v->held && v->held != v->on) gst_sample_unref(v->held);
  if (v->on) gst_sample_unref(v->on);
  gst_object_unref(v->reader);
  for (auto& [surface, planes] : v->seen)
    if (planes.shared) video_give_back(s, planes);
  s.engine->flushAndWait();
  delete v;
}

void key_own(Video* v, bool always) {
  v->own = always ? 2 : 1;
  // The first frame is not on the quad yet. The key is computed when it
  // arrives.
  if (!v->on) return;
  video_own_key(v, v->on);
  v->look->setParameter("key", v->key);
  v->look->setParameter("keySoft", v->keySoft);
}

void video_at(Stage& s, Video* v, float seconds) {
  // Restarts the reader at `to`. This must be called on this thread. When it
  // was tried from another thread, it dropped as many frames and the videos
  // took longer to settle.
  const auto back = [v](float to) {
    video_from(v, std::fmod(to, v->seconds), true);
    v->origin = to;
    v->ended = false;
    v->seeking = true;
    if (v->next) {
      gst_sample_unref(v->next);
      v->next = nullptr;
    }
  };
  // While a seek is in flight, only the latest requested time is kept, as
  // Pitivi keeps its next seek until ASYNC_DONE.
  if (v->seeking)
    v->want = seconds;
  else if (seconds < v->last)
    back(seconds);
  v->last = seconds;
  const double now = (double)seconds - v->origin;
  // A stage played in real time does not wait for a video. A video that is not
  // ready keeps its frame for that frame and catches up at the next. When
  // rendering frame by frame, every frame is waited for, up to half a second. A
  // seek in flight is not waited for: the held frame is shown until the first
  // frame of the seek arrives.
  const gint64 until =
      g_get_monotonic_time() + (s.by_clock || v->seeking ? 0 : 500000);
  // True once it is known that the held frame is the one for the current time.
  bool sure = false;
  while (true) {
    if (!v->next &&
        (v->next = gst_app_sink_try_pull_sample(
             v->out, s.by_clock || v->seeking ? 0 : 2 * GST_MSECOND)))
      v->nextAt = video_due(v->next);
    // The first frame of a seek has arrived. Show it, then seek to the time
    // requested meanwhile.
    if (v->next && v->seeking) {
      if (v->held != v->on) gst_sample_unref(v->held);
      v->held = v->next, v->next = nullptr, v->seeking = false;
      if (v->want >= 0.f && v->want != (float)v->origin) {
        const float to = v->want;
        v->want = -1.f;
        back(to);
      } else
        v->want = -1.f;
      break;
    }
    if (v->next) {
      if (v->nextAt > now) {
        sure = true;
        break;
      }
      // The next frame is due, so it becomes the current frame.
      if (v->held != v->on) gst_sample_unref(v->held);
      v->held = v->next;
      v->next = nullptr;
      continue;
    }
    if (v->ended) {
      v->ended = false;
      // Loop again without a gap. The restart is requested from another thread,
      // which is GStreamer's own way. The reader cannot be turned back while it
      // waits to hand a frame on, and this thread is the one that takes the
      // frames.
      gst_element_call_async(
          v->reader,
          [](GstElement*, gpointer film) {
            video_from((Video*)film, 0.f, false);
          },
          v, nullptr);
      continue;
    }
    if (g_get_monotonic_time() >= until) break;
  }
  ++video_asked;
  video_late += !sure;
  video_put(s, v);
}

// Showing a decoded frame: the surface the decoder hands over is shared with
// Filament without a copy, or copied when it cannot be shared, and the layer's
// ground colour and key are read from it.

#include <filament/TextureSampler.h>
#include <gst/video/video.h>

#include "gpu/gpu_interop.h"
#include "media/video_layer.h"

namespace motolii {

using filament::Engine;
using filament::Texture;
using filament::TextureSampler;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

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

namespace {

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
}  // namespace

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

namespace {

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
}  // namespace

// Puts the held frame on the quad for the frame that is drawn next. When the
// stage is rendered frame by frame, this waits for a surface that is being
// shared. That takes a moment, once for each decoder surface. When the stage is
// played in real time it does not wait.
void video_put(Stage& s, Video* v) {
  if (v->on == v->held || video_show(s, v) || s.by_clock) return;
  s.engine->flushAndWait();
  video_show(s, v);
}

}  // namespace motolii

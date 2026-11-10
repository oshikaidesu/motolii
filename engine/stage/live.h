#ifndef MOTOLII_STAGE_LIVE_H_
#define MOTOLII_STAGE_LIVE_H_

// Presents the stage's frames to the app without copying them.
//
// The main view draws into one of three pixel buffers that the GPU and the app share
// (CVPixelBuffers on IOSurfaces, as Filament's Metal backend creates them). Each buffer is
// exposed to Dawn as a texture, the same call video_layer.h uses to read video, but here the
// buffer is the destination. The texture is then made a Filament render target through the
// interop that the patch already provides (Texture::Builder::import). A frame counts as
// finished once a Filament fence created after it has signalled. macOS only.

#include <atomic>
#include <cstdint>

#include <CoreVideo/CoreVideo.h>

#include <filament/Fence.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <webgpu/webgpu.h>

#include "stage/render/render_stage.h"

// The set of shared buffers that the stage draws into, and the state of the frame in flight.
struct Live {
    // Number of buffers. They are used round-robin.
    static constexpr int N = 3;
    CVPixelBufferRef buffer[N] = {};
    WGPUSharedTextureMemory lent[N] = {};
    WGPUTexture shared[N] = {};
    filament::Texture* seen[N] = {};
    filament::RenderTarget* target[N] = {};
    // Index of the buffer that the next frame is drawn into.
    int next = 0;
    // Index of the last finished buffer, or -1 if none has finished yet.
    std::atomic<int> front{-1};
    // Number of frames finished so far.
    std::atomic<uint64_t> frames{0};
    // Seconds spent waiting for the GPU to finish frames. Used for measuring.
    double waited = 0;
    // filament::Fence of the frame that has been started but that the GPU has not finished, or null.
    filament::Fence* pending = nullptr;
    // Index of the buffer that the pending frame is drawn into, or -1 if it is not in this Live.
    int pendingIn = -1;
    // One ThorVG canvas per buffer, used by desk_marks to draw the overlay. Only used on the Live
    // that belongs to the editing window.
    void* marks[N] = {};
    // The Live that covers the editing window's whole stage pane (see desk_lay in render.h).
    // While it is set, the stage is drawn there instead of into this Live's own buffers.
    Live* desk = nullptr;
};

// Creates the shared buffers and wraps them as Filament render targets. A size of 0 means the
// stage's own size. Returns null if a buffer or texture cannot be created.
Live* live_open(Stage& s, uint32_t w = 0, uint32_t h = 0);

// Destroys the buffers after the GPU has finished with them. Also used to drop the old Live when
// the editing window's Live is recreated at another size.
void live_close(Stage& s, Live* l);

// Draws the stage's current frame into the next buffer. The buffer becomes the front one once the
// GPU has finished it; see live_ready.
void live_draw(Stage& s, Live* l);

// Presents a frame rendered earlier (see preview/playback_cache.h) instead of drawing the stage again.
// In the editing window it is placed where the stage lies, since the area outside the stage is
// not part of the frame, and the overlay is drawn over it as live_draw does.
void live_show(Stage& s, Live* l, filament::Texture* frameTexture);
// Returns true if the most recently started frame has finished, or if none is pending. A finished
// frame becomes the front buffer and is offered to the app. The render thread polls this instead
// of blocking on the GPU, and starts no new frame until it returns true. This follows Thermion's
// approach.
bool live_ready(Stage& s, Live* l);

// Returns the last finished frame as a retained CVPixelBufferRef, or null if there is none yet.
// The caller must release it. Safe to call from any thread.
void* live_front(Live* l);

#endif  // MOTOLII_STAGE_LIVE_H_

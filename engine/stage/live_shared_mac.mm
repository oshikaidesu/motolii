// The live buffers on macOS: CVPixelBuffers on IOSurfaces, which a Flutter external texture reads
// (app/macos/Runner/MainFlutterWindow.swift) and Dawn shares by its IOSurface (see live.h).
#include <CoreVideo/CoreVideo.h>
#include <Foundation/Foundation.h>
#include <IOSurface/IOSurface.h>
#include <webgpu/webgpu.h>

#include "stage/live.h"

namespace motolii {

bool live_buffers(Live* l) {
  NSDictionary* like = @{
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    (id)kCVPixelBufferMetalCompatibilityKey : @YES
  };
  for (void*& b : l->buffer)
    if (CVPixelBufferCreate(kCFAllocatorDefault, (size_t)l->w, (size_t)l->h,
                            kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)like,
                            (CVPixelBufferRef*)&b) != kCVReturnSuccess)
      return false;
  return true;
}

WGPUSharedTextureMemory live_share(Live* l, int i, void* device) {
  WGPUSharedTextureMemoryIOSurfaceDescriptor from{};
  from.chain.sType = WGPUSType_SharedTextureMemoryIOSurfaceDescriptor;
  from.ioSurface = CVPixelBufferGetIOSurface((CVPixelBufferRef)l->buffer[i]);
  WGPUSharedTextureMemoryDescriptor what{};
  what.nextInChain = &from.chain;
  return wgpuDeviceImportSharedTextureMemory((WGPUDevice)device, &what);
}

void live_unshare(Live* l) {
  // An app that still holds a buffer keeps it alive until it releases it.
  for (void* b : l->buffer)
    if (b) CVPixelBufferRelease((CVPixelBufferRef)b);
}

void* live_front(Live* l) {
  const int i = l->front;
  return i < 0 ? nullptr : (void*)CVPixelBufferRetain((CVPixelBufferRef)l->buffer[i]);
}

}  // namespace motolii

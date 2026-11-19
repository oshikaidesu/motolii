// The live buffers on Windows: D3D12 textures on Dawn's own device, each with a
// DXGI shared (NT) handle. Dawn opens the handle as a SharedTextureMemory (see
// live.h); the app hands the same handle to Flutter's texture registrar as a
// kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle
// (app/windows/runner/live_texture.cpp), whose ANGLE opens it on its D3D11
// device.
#include <d3d12.h>
#include <dawn/native/D3D12Backend.h>
#include <webgpu/webgpu.h>
#include <windows.h>
#include <wrl/client.h>

#include "stage/live.h"

namespace motolii {

// The textures are made on Dawn's device, which the render thread has:
// live_share makes each.
bool live_buffers(Live*) { return true; }

WGPUSharedTextureMemory live_share(Live* l, int i, void* device) {
  Microsoft::WRL::ComPtr<ID3D12Device> d3d =
      dawn::native::d3d12::GetD3D12Device((WGPUDevice)device);
  if (!d3d) return nullptr;
  D3D12_HEAP_PROPERTIES heap{};
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
  D3D12_RESOURCE_DESC like{};
  like.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
  like.Width = l->w, like.Height = l->h;
  like.DepthOrArraySize = 1, like.MipLevels = 1;
  like.Format = DXGI_FORMAT_B8G8R8A8_UNORM;  // (BGRA8888, which Flutter's GPU
                                             // surface textures take)
  like.SampleDesc.Count = 1;
  like.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET |
               D3D12_RESOURCE_FLAG_ALLOW_SIMULTANEOUS_ACCESS;
  ID3D12Resource* made = nullptr;
  HANDLE handle = nullptr;
  if (FAILED(d3d->CreateCommittedResource(&heap, D3D12_HEAP_FLAG_SHARED, &like,
                                          D3D12_RESOURCE_STATE_COMMON, nullptr,
                                          IID_PPV_ARGS(&made))))
    return nullptr;
  if (FAILED(d3d->CreateSharedHandle(made, nullptr, GENERIC_ALL, nullptr,
                                     &handle))) {
    made->Release();
    return nullptr;
  }
  l->buffer[i] = made, l->handle[i] = handle;
  WGPUSharedTextureMemoryDXGISharedHandleDescriptor from{};
  from.chain.sType = WGPUSType_SharedTextureMemoryDXGISharedHandleDescriptor;
  from.handle = handle;
  from.useKeyedMutex = false;
  WGPUSharedTextureMemoryDescriptor what{};
  what.nextInChain = &from.chain;
  return wgpuDeviceImportSharedTextureMemory((WGPUDevice)device, &what);
}

void live_unshare(Live* l) {
  // ANGLE holds its own reference to a texture it opened, so the app keeps a
  // frame it still shows.
  for (int i = 0; i < Live::N; ++i) {
    if (l->handle[i]) CloseHandle(l->handle[i]);
    if (l->buffer[i]) static_cast<ID3D12Resource*>(l->buffer[i])->Release();
  }
}

void* live_front(Live* l) {
  const int i = l->front;
  return i < 0 ? nullptr : l->handle[i];
}

}  // namespace motolii

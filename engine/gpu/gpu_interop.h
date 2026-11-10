// Shares Filament's WebGPU device with other code that draws with WebGPU (ThorVG) and
// orders that code's drawing relative to Filament's.
//
// Filament 1.77.2 has no public API for either. With filament_dawn_compute.patch, its
// WebGPU platform remembers the device it created, and Texture::Builder::import accepts
// a WGPUTexture from that device.
//
// Like compute_interop, this code is built inside Filament's own build because it needs
// the engine's private headers. It is part of libmotolii_door.a.
#pragma once
#include <functional>

namespace filament {
class Engine;
}

namespace interop {
// Returns the WGPUDevice Filament draws with, or null on another backend.
void* device(filament::Engine*);
// Returns the WGPUInstance of that device, or null on another backend.
void* instance(filament::Engine*);
// Queues `work` like any other Filament call. It runs on Filament's driver thread, in
// order with the calls made before and after it. Whatever it draws on the device is
// therefore ready for the frame rendered after this call.
void on_driver(filament::Engine*, std::function<void()> work);
// Hands everything Filament has drawn so far to the GPU queue, using the driver's own
// flush, queued in order. Code that draws on the device afterwards (ThorVG submits at
// once) then sees that work as finished, not still waiting in Filament's encoder.
void submit(filament::Engine*);
}  // namespace interop

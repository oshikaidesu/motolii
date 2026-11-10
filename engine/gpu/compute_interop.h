// Compute shader access through Filament's driver.
//
// Filament 1.77.2 has no public API for compute shaders or storage buffers. Its WebGPU
// backend can run them once filament_dawn_compute.patch is applied. This header exposes
// only that access: a program (WGSL), buffers, a set of buffers bound to a program, and
// a dispatch. When Filament gets a public API, only compute_interop.cpp needs to change.
//
// This code is built inside Filament's own build because it needs the engine's private
// headers. It is part of libmotolii_door.a; see CMakeLists.txt.
//
// Calls are queued like any other Filament call. A `run` issued between beginFrame and
// the render that uses its result executes in order on the GPU, and nothing waits.
// `read` is for tests only and waits for the GPU.
#pragma once
#include <cstdint>

namespace filament {
class Engine;
class BufferObject;
}  // namespace filament

namespace interop {
struct Program;
struct Buffer;
struct Set;
enum class Kind { UNIFORM, STORAGE };

// Creates a compute program from WGSL source with `count` buffer slots. Slot i is
// Filament's binding i, which is `@group(0) @binding(2 * i)` in the WGSL. A storage slot
// must be declared `var<storage, read_write>` because the layout declares all of them so.
Program* program(filament::Engine*, const char* name, const char* wgsl, const Kind* slots, int count);
// Creates a buffer of the given kind. The size is rounded up to a multiple of 16 bytes.
Buffer* buffer(filament::Engine*, Kind, uint32_t bytes);
// Wraps a Filament vertex buffer object so that compute can write to it.
Buffer* buffer(filament::Engine*, filament::BufferObject* vertices);
// Queues a write of `bytes` bytes at offset `at`. The data is copied before returning.
void write(filament::Engine*, Buffer*, const void* data, uint32_t bytes, uint32_t at = 0);
// Binds one buffer per slot of `Program` and returns the resulting set.
Set* set(filament::Engine*, Program*, Buffer* const* buffers);
// Queues a dispatch of the given number of workgroups.
void run(filament::Engine*, Program*, Set*, uint32_t groupsX, uint32_t groupsY = 1, uint32_t groupsZ = 1);
// Reads `bytes` bytes at offset `at` into `into`. For tests only: it waits for the GPU.
void read(filament::Engine*, Buffer*, uint32_t at, uint32_t bytes, void* into);
}  // namespace interop

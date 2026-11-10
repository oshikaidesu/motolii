// Implements screen_interop.h.
#include "screen_interop.h"

#include <backend/PipelineState.h>
#include <backend/Program.h>
#include <filament/Engine.h>
#include <filament/IndexBuffer.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <filament/VertexBuffer.h>
#include <webgpu/webgpu.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <thread>
#include <vector>

#include "details/Engine.h"
#include "details/IndexBuffer.h"
#include "details/RenderTarget.h"
#include "details/Texture.h"
#include "details/VertexBuffer.h"
#include "gpu_interop.h"

namespace interop {
using namespace filament;
using namespace filament::backend;

// Vertex shader for Filament's full-screen triangle. The position arrives at
// location 0 and runs from (-1,-1) past the far corners. The uv is derived from
// it with (0,0) at the top left.
static const char* const sVertex = R"(
struct Out { @builtin(position) position: vec4f, @location(0) uv: vec2f };
@vertex fn main(@location(0) p: vec4f) -> Out {
  var o: Out;
  o.position = vec4f(p.xy, 0.0, 1.0);
  o.uv = vec2f(0.5 * p.x + 0.5, 0.5 - 0.5 * p.y);
  return o;
}
)";

// Vertex shader for mesh passes. The position (x, y, z, w) is passed through
// unchanged, so the GPU's divide by w lays the image in perspective. The colour
// and uv follow. The attribute locations are the ones Filament's WebGPU backend
// assigns: shaderLocation equals the attribute index, so POSITION is 0, COLOR
// is 2 and UV0 is 3. See WebGPUVertexBufferInfo.cpp.
static const char* const sMeshVertex = R"(
struct Out { @builtin(position) position: vec4f, @location(0) uv: vec2f, @location(1) colour: vec4f };
@vertex fn main(@location(0) p: vec4f, @location(2) c: vec4f, @location(3) uv: vec2f) -> Out {
  var o: Out;
  o.position = p;
  o.uv = uv;
  o.colour = c;
  return o;
}
)";

// A compiled shader with the buffers its passes share.
struct Screen {
  ProgramHandle program;
  DescriptorSetLayoutHandle layout;
  int textureCount = 1;
  // Parameters of all passes in one buffer, each pass at its own offset. A pass
  // may be written several times in one frame, and a single shared slot would
  // show only the last write. This follows Filament's per-renderable uniforms,
  // one buffer with an offset per renderable (FScene's mRenderableUBO). One
  // buffer per pass would need one handle per pass, which overflows the
  // driver's handle arena when a script draws 30,000 times a frame.
  BufferObjectHandle parameters;
  // parameterRoom is the number of passes the buffer has room for.
  // parameterStride is the distance between consecutive passes, rounded up to
  // the device's uniform offset alignment.
  uint32_t parameterRoom = 0, parameterStride = 0;
  uint32_t parameterBytes = 0;
  // Vertex and index buffers and the render primitive made from them, with the
  // number of corners they have room for.
  struct Mesh {
    VertexBuffer* vb = nullptr;
    IndexBuffer* ib = nullptr;
    RenderPrimitiveHandle primitive;
    uint32_t room = 0;
  };
  // Corners of all passes in one mesh, stored one pass after another in draw
  // order and restarting from 0 each frame. Each pass draws from its own range.
  // As with the parameters, a separate mesh per pass would take three handles
  // each.
  Mesh corners;
  // Index of the first corner for the next pass.
  uint32_t cursor = 0;
  bool mesh = false;
};

// Returns the driver command stream of `engine`.
static DriverApi& driver(Engine* engine) {
  return downcast(engine)->getDriverApi();
}

// Returns whether Dawn accepts the fragment shader. The shader module is
// created once on Filament's own device, on its driver thread, inside an error
// scope. On failure the message is stored in `why` if it is not null. Returns
// true when there is no WebGPU device.
static bool takes(Engine* engine, const char* fragment, std::string* why) {
  WGPUDevice device = (WGPUDevice)interop::device(engine);
  WGPUInstance instance = (WGPUInstance)interop::instance(engine);
  if (!device || !instance) return true;
  struct Said {
    bool done = false, ok = true;
    std::string message;
  } said;
  interop::on_driver(engine, [&] {
    wgpuDevicePushErrorScope(device, WGPUErrorFilter_Validation);
    WGPUShaderSourceWGSL code{};
    code.chain.sType = WGPUSType_ShaderSourceWGSL;
    code.code = {fragment, WGPU_STRLEN};
    WGPUShaderModuleDescriptor built{};
    built.nextInChain = &code.chain;
    WGPUShaderModule module = wgpuDeviceCreateShaderModule(device, &built);
    WGPUPopErrorScopeCallbackInfo told{};
    told.mode = WGPUCallbackMode_AllowProcessEvents;
    told.callback = [](WGPUPopErrorScopeStatus, WGPUErrorType type,
                       WGPUStringView message, void* to, void*) {
      Said& s = *(Said*)to;
      s.done = true, s.ok = type == WGPUErrorType_NoError;
      if (!s.ok && message.data)
        s.message.assign(message.data, message.length == WGPU_STRLEN
                                           ? std::strlen(message.data)
                                           : message.length);
    };
    told.userdata1 = &said;
    wgpuDevicePopErrorScope(device, told);
    // Dawn normally reports within a moment; wait two seconds at most.
    for (int i = 0; i < 2000 && !said.done; ++i) {
      wgpuInstanceProcessEvents(instance);
      if (!said.done) std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    if (module) wgpuShaderModuleRelease(module);
  });
  engine->flushAndWait();
  if (!said.ok && why) *why = said.message;
  return said.ok;
}

// Creates the program and descriptor layout for the shader. Returns nullptr if
// Dawn rejects it. Parameter size is rounded up to a multiple of 16 bytes.
Screen* screen(Engine* engine, const char* name, const char* fragment,
               uint32_t parameterBytes, std::string* why, int textureCount,
               unsigned layered, bool mesh) {
  if (!takes(engine, fragment, why)) return nullptr;
  DriverApi& d = driver(engine);
  auto* s = new Screen;
  s->parameterBytes = (parameterBytes + 15u) & ~15u;
  s->textureCount = textureCount < 1 ? 1 : textureCount;
  s->mesh = mesh;
  backend::Program p;
  p.shaderLanguage(ShaderLanguage::WGSL);
  p.diagnostics(
      utils::CString(name),
      [](utils::CString const&,
         utils::io::ostream& out) -> utils::io::ostream& { return out; });
  p.shader(ShaderStage::VERTEX, mesh ? sMeshVertex : sVertex,
           std::strlen(mesh ? sMeshVertex : sVertex) + 1);
  p.shader(ShaderStage::FRAGMENT, fragment, std::strlen(fragment) + 1);
  const size_t n = (size_t)s->textureCount + 1;
  backend::Program::DescriptorBindingsInfo bindings =
      backend::Program::DescriptorBindingsInfo::with_capacity(n);
  backend::DescriptorSetLayout layout;
  layout.label = utils::CString(name);
  layout.descriptors =
      utils::FixedCapacityVector<DescriptorSetLayoutDescriptor>::with_capacity(
          n);
  for (int i = 0; i < s->textureCount; ++i) {
    const DescriptorType kind = (layered >> i) & 1u
                                    ? DescriptorType::SAMPLER_2D_ARRAY_FLOAT
                                    : DescriptorType::SAMPLER_2D_FLOAT;
    bindings.push_back(
        {utils::CString("picture"), kind, descriptor_binding_t(i)});
    layout.descriptors.push_back(
        {kind, ShaderStageFlags::FRAGMENT, descriptor_binding_t(i)});
  }
  if (s->parameterBytes) {
    bindings.push_back({utils::CString("knobs"), DescriptorType::UNIFORM_BUFFER,
                        descriptor_binding_t(s->textureCount)});
    layout.descriptors.push_back({DescriptorType::UNIFORM_BUFFER,
                                  ShaderStageFlags::FRAGMENT,
                                  descriptor_binding_t(s->textureCount)});
  }
  p.descriptorBindings(0, std::move(bindings));
  s->program = d.createProgram(std::move(p), utils::ImmutableCString{name});
  s->layout = d.createDescriptorSetLayout(std::move(layout),
                                          utils::ImmutableCString{name});
  return s;
}

// Returns the parameter buffer, growing it if `pass` does not fit.
static BufferObjectHandle parametersOf(Engine* engine, Screen* s, int pass) {
  DriverApi& d = driver(engine);
  if (!s->parameterStride) {
    const uint32_t align =
        (uint32_t)std::max<size_t>(d.getUniformBufferOffsetAlignment(), 4);
    s->parameterStride = (s->parameterBytes + align - 1) / align * align;
  }
  if ((uint32_t)pass >= s->parameterRoom) {
    // Grow by doubling. The old buffer is released in command order, after the
    // draws already queued that read it.
    if (s->parameterRoom) d.destroyBufferObject(s->parameters);
    uint32_t room = std::max(s->parameterRoom, 16u);
    while (room <= (uint32_t)pass) room *= 2;
    s->parameterRoom = room;
    s->parameters = d.createBufferObject(
        room * s->parameterStride, BufferObjectBinding::UNIFORM,
        BufferUsage::DYNAMIC, utils::ImmutableCString{"screen"});
  }
  return s->parameters;
}

// Queues an upload of a pass's parameters, padded with zeros up to the
// parameter size.
void parameters(Engine* engine, Screen* s, const void* data, uint32_t bytes,
                int pass) {
  if (!s->parameterBytes || !bytes) return;
  const BufferObjectHandle to = parametersOf(engine, s, pass);
  bytes = bytes < s->parameterBytes ? bytes : s->parameterBytes;
  void* copy = std::calloc(1, s->parameterBytes);
  std::memcpy(copy, data, bytes);
  driver(engine).updateBufferObject(
      to,
      BufferDescriptor(copy, s->parameterBytes,
                       [](void* p, size_t, void*) { std::free(p); }),
      (uint32_t)pass * s->parameterStride);
}

// Appends `count` corners after those of earlier passes in this frame and
// returns the render primitive. `first` receives the index of the first
// appended corner. If they do not fit, the mesh is recreated twice as large and
// the old one is released after the draws already queued that read it. Pass 0
// restarts from the beginning of the buffer.
static RenderPrimitiveHandle meshOf(Engine* engine, Screen* s, int pass,
                                    const float* corners, uint32_t count,
                                    uint32_t* first) {
  if (pass == 0) s->cursor = 0;
  Screen::Mesh& m = s->corners;
  if (m.room < s->cursor + count) {
    if (m.vb)
      driver(engine).destroyRenderPrimitive(m.primitive), engine->destroy(m.vb),
          engine->destroy(m.ib);
    m.room = std::max(m.room, 64u);
    while (m.room < s->cursor + count) m.room *= 2;
    m.vb = VertexBuffer::Builder()
               .vertexCount(m.room)
               .bufferCount(1)
               .attribute(VertexAttribute::POSITION, 0,
                          VertexBuffer::AttributeType::FLOAT4, 0,
                          MESH_CORNER * sizeof(float))
               .attribute(VertexAttribute::COLOR, 0,
                          VertexBuffer::AttributeType::FLOAT4,
                          4 * sizeof(float), MESH_CORNER * sizeof(float))
               .attribute(VertexAttribute::UV0, 0,
                          VertexBuffer::AttributeType::FLOAT2,
                          8 * sizeof(float), MESH_CORNER * sizeof(float))
               .build(*engine);
    m.ib = IndexBuffer::Builder()
               .indexCount(m.room)
               .bufferType(IndexBuffer::IndexType::UINT)
               .build(*engine);
    auto* order = (uint32_t*)std::malloc(m.room * sizeof(uint32_t));
    for (uint32_t i = 0; i < m.room; ++i) order[i] = i;
    m.ib->setBuffer(*engine, IndexBuffer::BufferDescriptor(
                                 order, m.room * sizeof(uint32_t),
                                 [](void* p, size_t, void*) { std::free(p); }));
    m.primitive = driver(engine).createRenderPrimitive(
        downcast(m.vb)->getHwHandle(), downcast(m.ib)->getHwHandle(),
        PrimitiveType::TRIANGLES);
  }
  void* copy = std::malloc(count * MESH_CORNER * sizeof(float));
  std::memcpy(copy, corners, count * MESH_CORNER * sizeof(float));
  m.vb->setBufferAt(*engine, 0,
                    VertexBuffer::BufferDescriptor(
                        copy, count * MESH_CORNER * sizeof(float),
                        [](void* p, size_t, void*) { std::free(p); }),
                    s->cursor * MESH_CORNER * sizeof(float));
  *first = s->cursor, s->cursor += count;
  return m.primitive;
}

// Queues one pass: sets up the descriptor set, blending and viewport, then
// draws a full-screen triangle or the mesh.
void draw(Engine* engine, Screen* s, Texture* const* from, RenderTarget* to,
          uint32_t w, uint32_t h, int pass, const int* at, bool over, int blend,
          int sampler, const float* corners, uint32_t count) {
  DriverApi& d = driver(engine);
  if (s->mesh && (!corners || count < 3)) return;
  uint32_t first = 0;
  const RenderPrimitiveHandle primitive =
      s->mesh ? meshOf(engine, s, pass, corners, count, &first)
              : downcast(engine)->getFullScreenRenderPrimitive();
  // Make a new descriptor set for every draw, as Filament's
  // DescriptorSet::commitSlow does when its inputs change. Filament's WebGPU
  // backend caches what it builds from a set, so changing a used set is not
  // seen. Caching sets by the handles they read would also be wrong, because a
  // reused handle could pick up another image's old contents. Handles carry
  // only 4 bits of age; see HandleAllocator.h.
  SamplerParams linear{};
  linear.filterMag =
      sampler == 1 ? SamplerMagFilter::NEAREST : SamplerMagFilter::LINEAR,
  linear.filterMin =
      sampler == 1 ? SamplerMinFilter::NEAREST : SamplerMinFilter::LINEAR;
  linear.wrapS = linear.wrapT = sampler == 2 ? SamplerWrapMode::REPEAT
                                : sampler == 3
                                    ? SamplerWrapMode::MIRRORED_REPEAT
                                    : SamplerWrapMode::CLAMP_TO_EDGE;
  DescriptorSetHandle set =
      d.createDescriptorSet(s->layout, utils::ImmutableCString{"screen"});
  for (int i = 0; i < s->textureCount; ++i)
    d.updateDescriptorSetTexture(set, descriptor_binding_t(i),
                                 downcast(from[i])->getHwHandle(), linear);
  if (s->parameterBytes)
    d.updateDescriptorSetBuffer(set, descriptor_binding_t(s->textureCount),
                                parametersOf(engine, s, pass),
                                (uint32_t)pass * s->parameterStride,
                                s->parameterBytes);
  RenderPassParams params{};
  params.viewport =
      at ? backend::Viewport{at[0], at[1], (uint32_t)at[2], (uint32_t)at[3]}
         : backend::Viewport{0, 0, w, h};
  // When laying over, keep what is already in the target.
  params.flags.discardStart =
      over ? TargetBufferFlags::NONE : TargetBufferFlags::ALL;
  // Drawing only inside a rectangle: clear everything else to transparent.
  if (at)
    params.flags.clear = TargetBufferFlags::COLOR,
    params.clearColor = {0.f, 0.f, 0.f, 0.f};
  PipelineState pipeline{};
  pipeline.program = s->program;
  pipeline.pipelineLayout.setLayout = {s->layout};
  pipeline.rasterState.culling = CullingMode::NONE;
  pipeline.rasterState.depthWrite = false;
  pipeline.rasterState.depthFunc = RasterState::DepthFunc::A;
  pipeline.rasterState.colorWrite = true;
  // Filament's own way to lay a translucent image over another: premultiplied
  // alpha, with the top image over what is under it.
  if (over) {
    pipeline.rasterState.blendFunctionSrcRGB = BlendFunction::ONE,
    pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ONE;
    pipeline.rasterState.blendFunctionDstRGB =
        BlendFunction::ONE_MINUS_SRC_ALPHA,
    pipeline.rasterState.blendFunctionDstAlpha =
        BlendFunction::ONE_MINUS_SRC_ALPHA;
    if (blend == 1)
      pipeline.rasterState.blendFunctionDstRGB =
          pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::ONE;
    if (blend == 2)
      pipeline.rasterState.blendFunctionSrcRGB =
          pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ZERO,
      pipeline.rasterState.blendFunctionDstRGB =
          pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::SRC_ALPHA;
    // Keeps what is there outside what is drawn: Porter-Duff "out", the W3C
    // destination-out.
    if (blend == 3)
      pipeline.rasterState.blendFunctionSrcRGB =
          pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ZERO;
    // Colours are laid over as usual, but the alphas are added.
    if (blend == 4)
      pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::ONE;
    // Screen: the same as Filament's BlendingMode::SCREEN in
    // MaterialDefinition.cpp.
    if (blend == 5)
      pipeline.rasterState.blendFunctionDstRGB =
          BlendFunction::ONE_MINUS_SRC_COLOR;
    // Multiply, treating what is under as opaque: Cs * Cb + Cb * (1 - as),
    // where Cs is the source colour, Cb the backdrop colour and as the source
    // alpha. This matches how LAY_multiply in flat.mat lays a sheet.
    if (blend == 6)
      pipeline.rasterState.blendFunctionSrcRGB = BlendFunction::DST_COLOR;
  }
  d.bindDescriptorSet(set, 0, {});
  // A null target means the screen, as with the frame's swap chain.
  d.beginRenderPass(to ? downcast(to)->getHwHandle()
                       : downcast(engine)->getDefaultRenderTarget(),
                    params);
  d.draw(pipeline, primitive, first, s->mesh ? count : 3, 1);
  d.endRenderPass();
  d.bindDescriptorSet({}, 0, {});
  d.destroyDescriptorSet(std::move(set));
  // A destroyed set is only freed when the driver thread reaches the command. A
  // script that draws 30,000 times a frame would hold that many sets at once,
  // which exceeds Filament's handle arena (HandleAllocator, 8 MB on WebGPU).
  // Every 1024 draws, flush and wait so the sets are freed as the frame goes.
  static uint32_t since = 0;
  if (++since >= 1024) since = 0, engine->flushAndWait();
}

// Destroys the GPU objects of `s` and deletes it.
void drop(Engine* engine, Screen* s) {
  DriverApi& d = driver(engine);
  if (s->parameterRoom) d.destroyBufferObject(s->parameters);
  if (const Screen::Mesh& m = s->corners; m.vb)
    d.destroyRenderPrimitive(m.primitive), engine->destroy(m.vb),
        engine->destroy(m.ib);
  d.destroyDescriptorSetLayout(s->layout);
  d.destroyProgram(s->program);
  delete s;
}
}  // namespace interop

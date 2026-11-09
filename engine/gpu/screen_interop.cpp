// See screen_interop.h.
#include "screen_interop.h"

#include <filament/Engine.h>
#include <filament/IndexBuffer.h>
#include <filament/RenderTarget.h>
#include <filament/VertexBuffer.h>
#include <filament/Texture.h>

#include <backend/PipelineState.h>
#include <backend/Program.h>

#include "details/Engine.h"
#include "details/IndexBuffer.h"
#include "details/RenderTarget.h"
#include "details/Texture.h"
#include "details/VertexBuffer.h"
#include "gpu_interop.h"

#include <webgpu/webgpu.h>

#include <algorithm>
#include <chrono>
#include <thread>

#include <cstdlib>
#include <cstring>
#include <vector>

namespace interop {
using namespace filament;
using namespace filament::backend;

// Filament's full-screen triangle (its POSITION at location 0, from -1,-1 past the far corners), as uv from the top left.
static const char* const sVertex = R"(
struct Out { @builtin(position) position: vec4f, @location(0) uv: vec2f };
@vertex fn main(@location(0) p: vec4f) -> Out {
  var o: Out;
  o.position = vec4f(p.xy, 0.0, 1.0);
  o.uv = vec2f(0.5 * p.x + 0.5, 0.5 - 0.5 * p.y);
  return o;
}
)";

// A mesh's: each corner's place as it is (x, y, z, w: its w the GPU's own divide, the picture between them laid in
// perspective), its colour and uv after it; at the locations Filament's WebGPU gives its attributes, their own
// numbers (WebGPUVertexBufferInfo.cpp: shaderLocation = attributeIndex; POSITION 0, COLOR 2, UV0 3).
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

struct Screen {
    ProgramHandle program;
    DescriptorSetLayoutHandle layout;
    int pictures = 1;
    BufferObjectHandle parameters;   // every pass's in one, each at a place of its own (written several times in one frame, one place would show its last): Filament's own per-renderable uniforms, one buffer and an offset each (FScene's mRenderableUBO); a buffer a pass held a handle each, past the driver's handle arena for a script drawing 30,000 times a frame (tim's もじゃもじゃT)
    uint32_t parameterRoom = 0, parameterStride = 0;   // (how many passes it has places for; from one's place to the next, the device's uniform offset alignment)
    uint32_t parameterBytes = 0;
    struct Mesh { VertexBuffer* vb = nullptr; IndexBuffer* ib = nullptr; RenderPrimitiveHandle primitive; uint32_t room = 0; };
    Mesh corners;   // every pass's corners in one, one after another as the frame's passes come (from 0 each frame), each drawn from its own (as the parameters: a mesh a pass held three handles each)
    uint32_t cursor = 0;   // (where the next pass's go)
    bool mesh = false;
};

static DriverApi& driver(Engine* engine) { return downcast(engine)->getDriverApi(); }

// Whether Dawn takes the fragment shader: made once on Filament's own device, on its driver's thread, inside an error scope.
static bool takes(Engine* engine, const char* fragment, std::string* why) {
    WGPUDevice device = (WGPUDevice)interop::device(engine);
    WGPUInstance instance = (WGPUInstance)interop::instance(engine);
    if (!device || !instance) return true;
    struct Said { bool done = false, ok = true; std::string message; } said;
    interop::on_driver(engine, [&] {
        wgpuDevicePushErrorScope(device, WGPUErrorFilter_Validation);
        WGPUShaderSourceWGSL code{};
        code.chain.sType = WGPUSType_ShaderSourceWGSL;
        code.code = {fragment, WGPU_STRLEN};
        WGPUShaderModuleDescriptor made{};
        made.nextInChain = &code.chain;
        WGPUShaderModule module = wgpuDeviceCreateShaderModule(device, &made);
        WGPUPopErrorScopeCallbackInfo told{};
        told.mode = WGPUCallbackMode_AllowProcessEvents;
        told.callback = [](WGPUPopErrorScopeStatus, WGPUErrorType type, WGPUStringView message, void* to, void*) {
            Said& s = *(Said*)to;
            s.done = true, s.ok = type == WGPUErrorType_NoError;
            if (!s.ok && message.data) s.message.assign(message.data, message.length == WGPU_STRLEN ? std::strlen(message.data) : message.length);
        };
        told.userdata1 = &said;
        wgpuDevicePopErrorScope(device, told);
        for (int i = 0; i < 2000 && !said.done; ++i) {   // (Dawn says it within a moment; two seconds at most)
            wgpuInstanceProcessEvents(instance);
            if (!said.done) std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        if (module) wgpuShaderModuleRelease(module);
    });
    engine->flushAndWait();
    if (!said.ok && why) *why = said.message;
    return said.ok;
}

Screen* screen(Engine* engine, const char* name, const char* fragment, uint32_t parameterBytes, std::string* why, int pictures, unsigned layered, bool mesh) {
    if (!takes(engine, fragment, why)) return nullptr;
    DriverApi& d = driver(engine);
    auto* s = new Screen;
    s->parameterBytes = (parameterBytes + 15u) & ~15u;
    s->pictures = pictures < 1 ? 1 : pictures;
    s->mesh = mesh;
    backend::Program p;
    p.shaderLanguage(ShaderLanguage::WGSL);
    p.diagnostics(utils::CString(name), [](utils::CString const&, utils::io::ostream& out) -> utils::io::ostream& { return out; });
    p.shader(ShaderStage::VERTEX, mesh ? sMeshVertex : sVertex, std::strlen(mesh ? sMeshVertex : sVertex) + 1);
    p.shader(ShaderStage::FRAGMENT, fragment, std::strlen(fragment) + 1);
    const size_t n = (size_t)s->pictures + 1;
    backend::Program::DescriptorBindingsInfo bindings = backend::Program::DescriptorBindingsInfo::with_capacity(n);
    backend::DescriptorSetLayout layout;
    layout.label = utils::CString(name);
    layout.descriptors = utils::FixedCapacityVector<DescriptorSetLayoutDescriptor>::with_capacity(n);
    for (int i = 0; i < s->pictures; ++i) {
        const DescriptorType kind = (layered >> i) & 1u ? DescriptorType::SAMPLER_2D_ARRAY_FLOAT : DescriptorType::SAMPLER_2D_FLOAT;
        bindings.push_back({utils::CString("picture"), kind, descriptor_binding_t(i)});
        layout.descriptors.push_back({kind, ShaderStageFlags::FRAGMENT, descriptor_binding_t(i)});
    }
    if (s->parameterBytes) {
        bindings.push_back({utils::CString("knobs"), DescriptorType::UNIFORM_BUFFER, descriptor_binding_t(s->pictures)});
        layout.descriptors.push_back({DescriptorType::UNIFORM_BUFFER, ShaderStageFlags::FRAGMENT, descriptor_binding_t(s->pictures)});
    }
    p.descriptorBindings(0, std::move(bindings));
    s->program = d.createProgram(std::move(p), utils::ImmutableCString{name});
    s->layout = d.createDescriptorSetLayout(std::move(layout), utils::ImmutableCString{name});
    return s;
}

static BufferObjectHandle parametersOf(Engine* engine, Screen* s, int pass) {
    DriverApi& d = driver(engine);
    if (!s->parameterStride) {
        const uint32_t align = (uint32_t)std::max<size_t>(d.getUniformBufferOffsetAlignment(), 4);
        s->parameterStride = (s->parameterBytes + align - 1) / align * align;
    }
    if ((uint32_t)pass >= s->parameterRoom) {   // (made again, twice as roomy; the old one let go after the draws already told to read it, in the order told)
        if (s->parameterRoom) d.destroyBufferObject(s->parameters);
        uint32_t room = std::max(s->parameterRoom, 16u);
        while (room <= (uint32_t)pass) room *= 2;
        s->parameterRoom = room;
        s->parameters = d.createBufferObject(room * s->parameterStride, BufferObjectBinding::UNIFORM, BufferUsage::DYNAMIC, utils::ImmutableCString{"screen"});
    }
    return s->parameters;
}

void parameters(Engine* engine, Screen* s, const void* data, uint32_t bytes, int pass) {
    if (!s->parameterBytes || !bytes) return;
    const BufferObjectHandle to = parametersOf(engine, s, pass);
    bytes = bytes < s->parameterBytes ? bytes : s->parameterBytes;
    void* copy = std::calloc(1, s->parameterBytes);
    std::memcpy(copy, data, bytes);
    driver(engine).updateBufferObject(to, BufferDescriptor(copy, s->parameterBytes, [](void* p, size_t, void*) { std::free(p); }), (uint32_t)pass * s->parameterStride);
}

// A pass's `count` corners after the passes' before it this frame (`first`, where they start): the mesh made again,
// twice as roomy, when they would not fit, the old one let go after the draws already told to read it.
static RenderPrimitiveHandle meshOf(Engine* engine, Screen* s, int pass, const float* corners, uint32_t count, uint32_t* first) {
    if (pass == 0) s->cursor = 0;
    Screen::Mesh& m = s->corners;
    if (m.room < s->cursor + count) {
        if (m.vb) driver(engine).destroyRenderPrimitive(m.primitive), engine->destroy(m.vb), engine->destroy(m.ib);
        m.room = std::max(m.room, 64u);
        while (m.room < s->cursor + count) m.room *= 2;
        m.vb = VertexBuffer::Builder().vertexCount(m.room).bufferCount(1)
                   .attribute(VertexAttribute::POSITION, 0, VertexBuffer::AttributeType::FLOAT4, 0, MESH_CORNER * sizeof(float))
                   .attribute(VertexAttribute::COLOR, 0, VertexBuffer::AttributeType::FLOAT4, 4 * sizeof(float), MESH_CORNER * sizeof(float))
                   .attribute(VertexAttribute::UV0, 0, VertexBuffer::AttributeType::FLOAT2, 8 * sizeof(float), MESH_CORNER * sizeof(float)).build(*engine);
        m.ib = IndexBuffer::Builder().indexCount(m.room).bufferType(IndexBuffer::IndexType::UINT).build(*engine);
        auto* order = (uint32_t*)std::malloc(m.room * sizeof(uint32_t));
        for (uint32_t i = 0; i < m.room; ++i) order[i] = i;
        m.ib->setBuffer(*engine, IndexBuffer::BufferDescriptor(order, m.room * sizeof(uint32_t), [](void* p, size_t, void*) { std::free(p); }));
        m.primitive = driver(engine).createRenderPrimitive(downcast(m.vb)->getHwHandle(), downcast(m.ib)->getHwHandle(), PrimitiveType::TRIANGLES);
    }
    void* copy = std::malloc(count * MESH_CORNER * sizeof(float));
    std::memcpy(copy, corners, count * MESH_CORNER * sizeof(float));
    m.vb->setBufferAt(*engine, 0, VertexBuffer::BufferDescriptor(copy, count * MESH_CORNER * sizeof(float), [](void* p, size_t, void*) { std::free(p); }), s->cursor * MESH_CORNER * sizeof(float));
    *first = s->cursor, s->cursor += count;
    return m.primitive;
}

void draw(Engine* engine, Screen* s, Texture* const* from, RenderTarget* to, uint32_t w, uint32_t h, int pass, const int* at, bool over, int blend, int sampler, const float* corners, uint32_t count) {
    DriverApi& d = driver(engine);
    if (s->mesh && (!corners || count < 3)) return;
    uint32_t first = 0;
    const RenderPrimitiveHandle primitive = s->mesh ? meshOf(engine, s, pass, corners, count, &first) : downcast(engine)->getFullScreenRenderPrimitive();
    // A set of its own each time, as Filament's DescriptorSet::commitSlow makes one when what it reads has changed: a set
    // once used is not told otherwise (Filament's WebGPU keeps what it made of it), and one kept by the handles it read
    // would read another's old picture when a handle comes round (HandleAllocator.h: 4 bits of age).
    SamplerParams linear{};
    linear.filterMag = sampler == 1 ? SamplerMagFilter::NEAREST : SamplerMagFilter::LINEAR, linear.filterMin = sampler == 1 ? SamplerMinFilter::NEAREST : SamplerMinFilter::LINEAR;
    linear.wrapS = linear.wrapT = sampler == 2 ? SamplerWrapMode::REPEAT : sampler == 3 ? SamplerWrapMode::MIRRORED_REPEAT : SamplerWrapMode::CLAMP_TO_EDGE;
    DescriptorSetHandle set = d.createDescriptorSet(s->layout, utils::ImmutableCString{"screen"});
    for (int i = 0; i < s->pictures; ++i) d.updateDescriptorSetTexture(set, descriptor_binding_t(i), downcast(from[i])->getHwHandle(), linear);
    if (s->parameterBytes) d.updateDescriptorSetBuffer(set, descriptor_binding_t(s->pictures), parametersOf(engine, s, pass), (uint32_t)pass * s->parameterStride, s->parameterBytes);
    RenderPassParams params{};
    params.viewport = at ? backend::Viewport{at[0], at[1], (uint32_t)at[2], (uint32_t)at[3]} : backend::Viewport{0, 0, w, h};
    params.flags.discardStart = over ? TargetBufferFlags::NONE : TargetBufferFlags::ALL;   // (laid over: what is there is kept)
    if (at) params.flags.clear = TargetBufferFlags::COLOR, params.clearColor = {0.f, 0.f, 0.f, 0.f};   // (only there: all else clear)
    PipelineState pipeline{};
    pipeline.program = s->program;
    pipeline.pipelineLayout.setLayout = {s->layout};
    pipeline.rasterState.culling = CullingMode::NONE;
    pipeline.rasterState.depthWrite = false;
    pipeline.rasterState.depthFunc = RasterState::DepthFunc::A;
    pipeline.rasterState.colorWrite = true;
    if (over) {   // (Filament's own way of laying a translucent picture over: premultiplied, the one on top over what is under)
        pipeline.rasterState.blendFunctionSrcRGB = BlendFunction::ONE, pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ONE;
        pipeline.rasterState.blendFunctionDstRGB = BlendFunction::ONE_MINUS_SRC_ALPHA, pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::ONE_MINUS_SRC_ALPHA;
        if (blend == 1) pipeline.rasterState.blendFunctionDstRGB = pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::ONE;
        if (blend == 2) pipeline.rasterState.blendFunctionSrcRGB = pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ZERO, pipeline.rasterState.blendFunctionDstRGB = pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::SRC_ALPHA;
        if (blend == 3) pipeline.rasterState.blendFunctionSrcRGB = pipeline.rasterState.blendFunctionSrcAlpha = BlendFunction::ZERO;   // (what is there kept outside what is drawn: Porter-Duff's "out", the W3C's destination-out)
        if (blend == 4) pipeline.rasterState.blendFunctionDstAlpha = BlendFunction::ONE;   // (colours laid over as ever, their alphas added)
        if (blend == 5) pipeline.rasterState.blendFunctionDstRGB = BlendFunction::ONE_MINUS_SRC_COLOR;   // (screen: Filament's own BlendingMode::SCREEN, MaterialDefinition.cpp)
        if (blend == 6) pipeline.rasterState.blendFunctionSrcRGB = BlendFunction::DST_COLOR;   // (multiply, what is under taken as opaque: Cs Cb + Cb (1 - as), as flat.mat's LAY_multiply lays a sheet)
    }
    d.bindDescriptorSet(set, 0, {});
    d.beginRenderPass(to ? downcast(to)->getHwHandle() : downcast(engine)->getDefaultRenderTarget(), params);   // (none: the screen, as the frame's swap chain is)
    d.draw(pipeline, primitive, first, s->mesh ? count : 3, 1);
    d.endRenderPass();
    d.bindDescriptorSet({}, 0, {});
    d.destroyDescriptorSet(std::move(set));
    // (a set let go is let go when the driver's thread comes to it, after the commands are handed over: a script drawing
    // 30,000 times a frame held as many, past Filament's handle arena (HandleAllocator, 8 MB on WebGPU); handed over and
    // caught up with every so many, Engine::flushAndWait, they are let go as they come)
    static uint32_t since = 0;
    if (++since >= 1024) since = 0, engine->flushAndWait();
}

void drop(Engine* engine, Screen* s) {
    DriverApi& d = driver(engine);
    if (s->parameterRoom) d.destroyBufferObject(s->parameters);
    if (const Screen::Mesh& m = s->corners; m.vb) d.destroyRenderPrimitive(m.primitive), engine->destroy(m.vb), engine->destroy(m.ib);
    d.destroyDescriptorSetLayout(s->layout);
    d.destroyProgram(s->program);
    delete s;
}
}  // namespace interop

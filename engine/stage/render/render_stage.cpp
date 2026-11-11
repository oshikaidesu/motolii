#include "stage/render/render_stage.h"

#include <filament/BufferObject.h>
#include <filament/IndirectLight.h>
#include <filament/RenderableManager.h>
#include <filament/TextureSampler.h>
#include <filament/TransformManager.h>
#include <filament/Viewport.h>
#include <geometry/SurfaceOrientation.h>
#include <ktxreader/Ktx1Reader.h>
#include <utils/EntityManager.h>

#include <fstream>

namespace motolii {

using filament::Box;
using filament::BufferObject;
using filament::Engine;
using filament::IndexBuffer;
using filament::IndirectLight;
using filament::InstanceBuffer;
using filament::Material;
using filament::MaterialInstance;
using filament::RenderableManager;
using filament::Renderer;
using filament::RenderTarget;
using filament::Texture;
using filament::TextureSampler;
using filament::VertexAttribute;
using filament::VertexBuffer;
using filament::View;
using filament::Viewport;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
using filament::math::quatf;
namespace backend = filament::backend;
namespace geometry = filament::geometry;
namespace math = filament::math;

backend::BufferDescriptor copied(const void* from, size_t bytes) {
  void* copy = malloc(bytes);
  memcpy(copy, from, bytes);
  return backend::BufferDescriptor(
      copy, bytes, [](void* buffer, size_t, void*) { free(buffer); });
}

std::vector<uint8_t> load_file(const char* path) {
  std::ifstream in(path, std::ios::binary);
  return std::vector<uint8_t>((std::istreambuf_iterator<char>(in)), {});
}

Stage open_stage(int w, int h) {
  Stage s{w, h};
  // BACKEND=webgpu selects Filament's WebGPU backend, Dawn, which is the way to
  // Windows. It needs Filament built from source, see gpu/filament_webgpu.sh.
  const char* backend = getenv("BACKEND");
  s.engine = Engine::Builder()
                 .backend(backend && !strcmp(backend, "webgpu")
                              ? Engine::Backend::WEBGPU
                              : Engine::Backend::METAL)
                 .build();
  // An image that does nothing to its colours gets them through exactly.
  // Filament may then use its one-dimensional lookup table instead of a coarse
  // block of values. With the block a white of 255 comes out as 249.
  s.engine->setFeatureFlag("engine.color_grading.use_1d_lut", true);
  s.renderer = s.engine->createRenderer();
  s.scene = s.engine->createScene();
  s.view = s.engine->createView();
  s.swap = s.engine->createSwapChain((uint32_t)w, (uint32_t)h, 0);
  s.camera = s.engine->createCamera(utils::EntityManager::get().create());
  s.camera->setExposure(16.0f, 1.0f / 125.0f, 100.0f);
  s.film = s.camera;
  s.view->setScene(s.scene);
  s.view->setCamera(s.camera);
  s.view->setViewport({0, 0, (uint32_t)w, (uint32_t)h});
  s.view->setDithering(View::Dithering::NONE);
  s.view->setAntiAliasing(View::AntiAliasing::FXAA);
  // Anti-aliases the edges of flat shapes drawn as triangles, see flat_mesh in
  // canvas.h, as Unity and three.js do.
  s.view->setMultiSampleAntiAliasingOptions(
      {.enabled = true, .sampleCount = 4});
  s.view->setScreenSpaceRefractionEnabled(true);
  s.view->setVisibleLayers(0x03, 0x03);
  Renderer::ClearOptions clear{};
  // Clear to transparent, not black. The stage's own view covers all of it
  // anyway, and an image of one layer alone shows the card where the layer is
  // not.
  clear.clearColor = {0, 0, 0, 0};
  clear.clear = true;
  s.renderer->setClearOptions(clear);
  s.behind =
      Texture::Builder()
          .width(w)
          .height(h)
          .levels(1)
          .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE)
          .format(Texture::InternalFormat::RGBA16F)
          .build(*s.engine);
  Texture* depth = s.behindDepth = Texture::Builder()
                                       .width(w)
                                       .height(h)
                                       .levels(1)
                                       .usage(Texture::Usage::DEPTH_ATTACHMENT)
                                       .format(Texture::InternalFormat::DEPTH24)
                                       .build(*s.engine);
  s.view_behind = s.engine->createView();
  s.view_behind->setScene(s.scene);
  s.view_behind->setCamera(s.camera);
  s.view_behind->setViewport({0, 0, (uint32_t)w, (uint32_t)h});
  s.view_behind->setRenderTarget(
      RenderTarget::Builder()
          .texture(RenderTarget::AttachmentPoint::COLOR, s.behind)
          .texture(RenderTarget::AttachmentPoint::DEPTH, depth)
          .build(*s.engine));
  s.view_behind->setPostProcessingEnabled(false);
  s.view_behind->setScreenSpaceRefractionEnabled(false);
  return s;
}

void desk_lay(Stage& s, bool on) {
  const Viewport at = on ? Viewport{0, 0, s.desk.w, s.desk.h}
                         : Viewport{0, 0, (uint32_t)s.w, (uint32_t)s.h};
  for (View* v : {s.view, s.view_behind, s.view_through})
    if (v) v->setViewport(at);
  const double near = s.camera->getNear(), far = s.camera->getCullingFar();
  if (!on)
    return s.camera->setCustomProjection(s.desk.was, s.desk.wasCulled, near,
                                         far);
  s.desk.was = s.camera->getProjectionMatrix(),
  s.desk.wasCulled = s.camera->getCullingProjectionMatrix();
  const double wide = s.w * s.desk.scale, high = s.h * s.desk.scale;
  // Maps the stage's -1..1 range to where the stage lies in the panel's.
  math::mat4 further;
  further[0][0] = wide / s.desk.w, further[1][1] = high / s.desk.h;
  further[3][0] = 2.0 * (s.desk.x + 0.5 * wide) / s.desk.w - 1.0,
  further[3][1] = 1.0 - 2.0 * (s.desk.y + 0.5 * high) / s.desk.h;
  s.camera->setCustomProjection(further * s.desk.was,
                                further * s.desk.wasCulled, near, far);
}

bool room(Stage& s, const char* ktx, float intensity) {
  static std::vector<std::vector<uint8_t>> ktxs;
  ktxs.push_back(load_file(ktx));
  if (ktxs.back().empty()) return false;
  auto* bundle =
      new image::Ktx1Bundle(ktxs.back().data(), (uint32_t)ktxs.back().size());
  float3 sh[9];
  if (!bundle->getSphericalHarmonics(sh)) return false;
  Texture* tex = ktxreader::Ktx1Reader::createTexture(s.engine, bundle, false);
  s.scene->setIndirectLight(IndirectLight::Builder()
                                .reflections(tex)
                                .irradiance(3, sh)
                                .intensity(intensity)
                                .build(*s.engine));
  return true;
}

Texture* white_point(Stage& s) {
  static const uint8_t one[4] = {255, 255, 255, 255};
  if (!s.white) {
    s.white = Texture::Builder()
                  .width(1)
                  .height(1)
                  .levels(1)
                  .format(Texture::InternalFormat::RGBA8)
                  .build(*s.engine);
    s.white->setImage(
        *s.engine, 0,
        backend::PixelBufferDescriptor(one, 4, backend::PixelDataFormat::RGBA,
                                       backend::PixelDataType::UBYTE));
  }
  return s.white;
}

std::string flat_laid(const char* lay, bool lit, const std::string& wear) {
  // A sheet with its own material has its own blend mode, see
  // doc_sheet_material.
  if (!wear.empty()) return "flat_" + wear + ".filamat";
  if (lit)
    return std::string("flat_lit_") + (lay ? lay : "transparent") + ".filamat";
  return lay ? std::string("flat_") + lay + ".filamat" : "flat.filamat";
}

Material* material(Stage& s, const char* filamat) {
  auto& built = s.materials;
  if (!built.count(filamat)) {
    const std::vector<uint8_t> pkg = load_file(filamat);
    built[filamat] = pkg.empty() ? nullptr
                                 : Material::Builder()
                                       .package(pkg.data(), pkg.size())
                                       .build(*s.engine);
    // Compile the shader programs now, not at the first frame that needs them.
    // In the crowd's first minute this dropped 1 to 4 frames, against 3 to 16
    // without.
    if (built[filamat])
      built[filamat]->compile(Material::CompilerPriorityQueue::HIGH);
  }
  return built[filamat];
}

namespace {
// Creates the vertex buffer of mesh `m` with room for `room` points. A mesh
// with per-point colours has two more buffers, for the colours and the second
// texture coordinates.
VertexBuffer* mesh_buffers(Stage& s, Mesh& m, uint32_t room) {
  VertexBuffer::Builder make;
  make.vertexCount(room)
      .bufferCount(m.color.empty() ? 3 : 5)
      .attribute(VertexAttribute::POSITION, 0,
                 VertexBuffer::AttributeType::FLOAT3)
      .attribute(VertexAttribute::TANGENTS, 1,
                 VertexBuffer::AttributeType::FLOAT4)
      .attribute(VertexAttribute::UV0, 2, VertexBuffer::AttributeType::FLOAT2);
  if (!m.color.empty())
    make.attribute(VertexAttribute::COLOR, 3,
                   VertexBuffer::AttributeType::FLOAT4)
        .attribute(VertexAttribute::UV1, 4,
                   VertexBuffer::AttributeType::FLOAT2);
  if (!m.objects) return make.build(*s.engine);
  // One buffer object for each attribute. The caller destroys the old ones.
  VertexBuffer* vb = make.enableBufferObjects().build(*s.engine);
  const uint32_t bytes[3] = {sizeof(float3), sizeof(quatf), sizeof(float2)};
  for (int i = 0; i < 3; ++i) {
    m.object[i] = BufferObject::Builder()
                      .size(room * bytes[i])
                      .bindingType(BufferObject::BindingType::VERTEX)
                      .build(*s.engine);
    vb->setBufferObjectAt(*s.engine, i, m.object[i]);
  }
  return vb;
}

// Writes the first n points of `m` into the buffers of `vb`.
void mesh_points(Stage& s, const Mesh& m, VertexBuffer* vb, size_t n) {
  if (m.objects) {
    m.object[0]->setBuffer(*s.engine, copied(m.pos.data(), n * sizeof(float3)));
    m.object[1]->setBuffer(*s.engine, copied(m.quat.data(), n * sizeof(quatf)));
    m.object[2]->setBuffer(*s.engine, copied(m.uv.data(), n * sizeof(float2)));
    return;
  }
  vb->setBufferAt(*s.engine, 0, copied(m.pos.data(), n * sizeof(float3)));
  vb->setBufferAt(*s.engine, 1, copied(m.quat.data(), n * sizeof(quatf)));
  vb->setBufferAt(*s.engine, 2, copied(m.uv.data(), n * sizeof(float2)));
  if (!m.color.empty())
    vb->setBufferAt(*s.engine, 3, copied(m.color.data(), n * sizeof(float4))),
        vb->setBufferAt(*s.engine, 4, copied(m.uv1.data(), n * sizeof(float2)));
}
}  // namespace

Mesh* sketch_mesh() {
  Mesh* m = new Mesh;
  m->pos.assign(3, float3{0.f}), m->nrm.assign(3, float3{0.f, 0.f, 1.f}),
      m->uv.assign(3, float2{0.f}), m->color.assign(3, float4{0.f}),
      m->uv1.assign(3, float2{0.f}), m->idx = {0, 1, 2};
  return m;
}

std::vector<MaterialInstance*> add_parts(Stage& s, Mesh* m, const char* filamat,
                                         std::vector<mat4f> places,
                                         std::vector<uint32_t> ends,
                                         uint8_t layer, bool shadows,
                                         int copies, int order, bool together) {
  Material* mat = material(s, filamat);
  if (!mat) return {};
  if (ends.empty()) ends = {(uint32_t)m->idx.size()};
  const size_t n = m->pos.size();
  auto* frames = geometry::SurfaceOrientation::Builder()
                     .vertexCount(n)
                     .normals(m->nrm.data())
                     .build();
  m->quat.resize(n);
  frames->getQuats(m->quat.data(), n);
  delete frames;
  VertexBuffer* vb = mesh_buffers(s, *m, (uint32_t)n);
  mesh_points(s, *m, vb, n);
  IndexBuffer* ib =
      IndexBuffer::Builder()
          .indexCount((uint32_t)std::max<size_t>(1, m->idx.size()))
          .bufferType(IndexBuffer::IndexType::UINT)
          .build(*s.engine);
  if (!m->idx.empty())
    ib->setBuffer(*s.engine,
                  copied(m->idx.data(), m->idx.size() * sizeof(uint32_t)));
  m->vb = vb, m->ib = ib, m->vbRoom = (uint32_t)n,
  m->ibRoom = (uint32_t)std::max<size_t>(1, m->idx.size());
  std::vector<MaterialInstance*> looks;
  for (size_t k = 0; k < ends.size(); ++k) {
    MaterialInstance* mi = mat->createInstance();
    // Fully opaque until told otherwise.
    if (mat->hasParameter("opacity")) mi->setParameter("opacity", 1.f);
    // A material that can be cut is cut by nothing until `matted` says so.
    if (mat->hasParameter("matteUse")) {
      for (const char* name : {"matte0", "matte1", "matte2", "matte3"})
        mi->setParameter(name, white_point(s), TextureSampler());
      for (const char* name :
           {"matteEye0", "matteEye1", "matteEye2", "matteEye3"})
        mi->setParameter(name, mat4f{});
      // A video's second plane, see video_layer.h.
      if (mat->hasParameter("colours"))
        mi->setParameter("colours", white_point(s), TextureSampler());
      mi->setParameter("matteUse", float4{0.f});
      mi->setParameter("matteSoft", float4{0.f});
    }
    // Nothing is read until the project says which, and there is no bevel until
    // canvas_renderables.h makes one. Filament refuses a sampler that is left
    // unset.
    for (const char* name : {"backdrop", "edge"})
      if (mat->hasParameter(name))
        mi->setParameter(name, white_point(s), TextureSampler());
    looks.push_back(mi);
  }
  // Filament wants a rough bounding box if the entity casts or receives
  // shadows.
  float3 low = n ? m->pos[0] : float3{0.f}, high = low;
  for (const float3& p : m->pos) {
    low = min(low, p);
    high = max(high, p);
  }
  // With `together`, the places are drawn in groups of as many as Filament
  // draws in one go, 64, each place being an instance of one entity. A GPU pays
  // for each draw, not for each triangle, so a thousand copies take sixteen
  // draws instead of a thousand. A mesh of two parts, such as a fill and its
  // edge, is not grouped. Filament draws a part for all its instances before
  // the next part, so every edge would lie over every fill, where one copy's
  // fill hid the edge of the copy under it.
  const size_t group =
      together && places.size() > 1 && ends.size() == 1
          ? std::min<size_t>(places.size(),
                             s.engine->getMaxAutomaticInstances())
          : 1;
  for (const mat4f& place : places) {
    const size_t at = (size_t)(&place - places.data());
    if (at % group) continue;
    const size_t count = std::min(group, places.size() - at);
    InstanceBuffer* many = nullptr;
    if (group > 1) {
      many = InstanceBuffer::Builder(count).build(*s.engine);
      many->setLocalTransforms(places.data() + at, count);
    }
    utils::Entity e = utils::EntityManager::get().create();
    s.engine->getTransformManager().create(e, {}, many ? mat4f{} : place);
    RenderableManager::Builder b(ends.size());
    for (size_t k = 0; k < ends.size(); ++k) {
      const uint32_t from = k ? ends[k - 1] : 0;
      b.geometry(k, RenderableManager::PrimitiveType::TRIANGLES, vb, ib, from,
                 ends[k] - from)
          .material(k, looks[k]);
    }
    b.boundingBox(
         {(low + high) * 0.5f, max((high - low) * 0.5f, float3{1e-3f})})
        .culling(false)
        .castShadows(shadows)
        .receiveShadows(shadows)
        .layerMask(0xFF, layer);
    if (many)
      b.instances(count, many);
    else
      b.instances((size_t)copies);
    b.priority((uint8_t)order).build(*s.engine, e);
    s.scene->addEntity(e);
    s.renderables.push_back({e, m, (int)at, place, false, many, (int)count});
  }
  return looks;
}

MaterialInstance* add(Stage& s, Mesh* m, const char* filamat,
                      std::vector<mat4f> places, uint8_t layer, bool shadows,
                      int copies, int order, bool together) {
  const std::vector<MaterialInstance*> looks = add_parts(
      s, m, filamat, places, {}, layer, shadows, copies, order, together);
  return looks.empty() ? nullptr : looks[0];
}

void more_parts(Stage& s, Mesh* m, size_t parts, MaterialInstance* look) {
  auto& faces = s.engine->getRenderableManager();
  for (const Stage::Renderable& built : s.renderables) {
    if (built.of != m) continue;
    const auto at = faces.getInstance(built.thing);
    const uint8_t mask = faces.getLayerMask(at), order = faces.getPriority(at),
                  channel = faces.getChannel(at);
    const uint16_t blend = faces.getBlendOrderAt(at, 0);
    const bool everywhere = faces.isGlobalBlendOrderEnabledAt(at, 0);
    const Box box = faces.getAxisAlignedBoundingBox(at);
    RenderableManager::Builder b(parts);
    for (size_t k = 0; k < parts; ++k)
      b.geometry(k, RenderableManager::PrimitiveType::TRIANGLES, m->vb, m->ib,
                 0, 0)
          .material(k, look)
          .blendOrder(k, blend)
          .globalBlendOrderEnabled(k, everywhere);
    b.boundingBox(box)
        .culling(false)
        .castShadows(false)
        .receiveShadows(false)
        .layerMask(0xFF, mask)
        .priority(order)
        .channel(channel)
        .build(*s.engine, built.thing);
  }
}

void reshape(Stage& s, Mesh* m, const std::vector<uint32_t>& ends) {
  VertexBuffer* oldVb = nullptr;
  IndexBuffer* oldIb = nullptr;
  const size_t n = m->pos.size();
  if (!n || m->idx.empty()) return;
  m->quat.resize(n);
  // All normals face one way, a flat shape, so one tangent frame serves every
  // point.
  if (std::all_of(m->nrm.begin(), m->nrm.end(),
                  [&](const float3& v) { return v == m->nrm[0]; })) {
    auto* frames = geometry::SurfaceOrientation::Builder()
                       .vertexCount(1)
                       .normals(m->nrm.data())
                       .build();
    frames->getQuats(m->quat.data(), 1);
    delete frames;
    std::fill(m->quat.begin() + 1, m->quat.end(), m->quat[0]);
  } else {
    auto* frames = geometry::SurfaceOrientation::Builder()
                       .vertexCount(n)
                       .normals(m->nrm.data())
                       .build();
    frames->getQuats(m->quat.data(), n);
    delete frames;
  }
  filament::BufferObject* oldObject[3] = {nullptr, nullptr, nullptr};
  if (!m->vb || n > m->vbRoom) {
    oldVb = m->vb, m->vbRoom = (uint32_t)(n + n / 4 + 16);
    std::copy(m->object, m->object + 3, oldObject);
    m->vb = mesh_buffers(s, *m, m->vbRoom);
  }
  if (!m->ib || m->idx.size() > m->ibRoom) {
    oldIb = m->ib,
    m->ibRoom = (uint32_t)(m->idx.size() + m->idx.size() / 4 + 48);
    m->ib = IndexBuffer::Builder()
                .indexCount(m->ibRoom)
                .bufferType(IndexBuffer::IndexType::UINT)
                .build(*s.engine);
  }
  mesh_points(s, *m, m->vb, n);
  m->ib->setBuffer(*s.engine,
                   copied(m->idx.data(), m->idx.size() * sizeof(uint32_t)));
  auto& faces = s.engine->getRenderableManager();
  for (const Stage::Renderable& built : s.renderables) {
    if (built.of != m) continue;
    const auto at = faces.getInstance(built.thing);
    for (size_t k = 0; k < ends.size() && k < faces.getPrimitiveCount(at);
         ++k) {
      const uint32_t from = k ? ends[k - 1] : 0;
      faces.setGeometryAt(at, k, RenderableManager::PrimitiveType::TRIANGLES,
                          m->vb, m->ib, from, ends[k] - from);
    }
  }
  if (oldVb) s.engine->destroy(oldVb);
  for (filament::BufferObject* o : oldObject)
    if (o) s.engine->destroy(o);
  if (oldIb) s.engine->destroy(oldIb);
}

}  // namespace motolii

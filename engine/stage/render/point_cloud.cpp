#include "stage/render/point_cloud.h"

#include <backend/DriverEnums.h>
#include <backend/PixelBufferDescriptor.h>
#include <dlfcn.h>
#include <filament/Camera.h>
#include <filament/Engine.h>
#include <filament/IndexBuffer.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/Texture.h>
#include <filament/TextureSampler.h>
#include <filament/TransformManager.h>
#include <filament/VertexBuffer.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <utils/EntityManager.h>

#include <algorithm>
#include <cmath>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <map>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

#include "community/playcanvas/splatfx.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::IndexBuffer;
using filament::Material;
using filament::MaterialInstance;
using filament::RenderableManager;
using filament::Texture;
using filament::TextureSampler;
using filament::VertexAttribute;
using filament::VertexBuffer;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
namespace backend = filament::backend;
namespace math = filament::math;

namespace {
// Wraps floats in a pixel buffer for a texture upload. Filament frees the
// vector when it has finished with the data.
backend::PixelBufferDescriptor points_pixels(std::vector<float>&& from,
                                             backend::PixelDataFormat format) {
  auto* held = new std::vector<float>(std::move(from));
  return backend::PixelBufferDescriptor(
      held->data(), held->size() * sizeof(float), format,
      backend::PixelDataType::FLOAT,
      [](void*, size_t, void* user) { delete (std::vector<float>*)user; },
      held);
}
}  // namespace

Mesh* points(Stage& s, const char* file, std::string& why,
             MaterialInstance** looks, Material* with,
             MaterialInstance** plainLook, float3* bounds) {
  std::ifstream in(file, std::ios::binary);
  std::string line, format;
  size_t n = 0;
  struct Prop {
    std::string name, type;
    size_t at = 0;
  };
  std::vector<Prop> props;
  size_t stride = 0;
  bool inVertex = false;
  const auto bytes = [](const std::string& t) -> size_t {
    return t == "double" || t == "float64" ? 8
           : t == "float" || t == "float32" || t == "int" || t == "uint" ||
                   t == "int32" || t == "uint32"
               ? 4
           : t == "short" || t == "ushort" || t == "int16" || t == "uint16" ? 2
                                                                            : 1;
  };
  // Read the header: which properties a point has, in order.
  while (std::getline(in, line)) {
    if (!line.empty() && line.back() == '\r') line.pop_back();
    std::istringstream w(line);
    std::string word;
    w >> word;
    if (word == "format")
      w >> format;
    else if (word == "element") {
      std::string what;
      w >> what >> n;
      inVertex = what == "vertex";
      if (!inVertex && !props.empty()) break;
    } else if (word == "property" && inVertex) {
      Prop p;
      w >> p.type;
      if (p.type == "list")
        return why = "a point cloud's points have no lists", nullptr;
      w >> p.name;
      p.at = stride;
      stride += bytes(p.type);
      props.push_back(p);
    } else if (word == "end_header")
      break;
  }
  if (format != "binary_little_endian" || !n || !stride)
    return why = "a point cloud is a binary .ply (little-endian)", nullptr;
  std::vector<uint8_t> raw(n * stride);
  if (!in.read((char*)raw.data(), (std::streamsize)raw.size()))
    return why = "the point cloud is shorter than its header says", nullptr;
  const auto find = [&](const char* name) -> const Prop* {
    for (const Prop& p : props)
      if (p.name == name) return &p;
    return nullptr;
  };
  const auto get = [&](const Prop* p, size_t i) -> double {
    const uint8_t* at = raw.data() + i * stride + p->at;
    if (p->type == "float" || p->type == "float32") {
      float v;
      memcpy(&v, at, 4);
      return v;
    }
    if (p->type == "double" || p->type == "float64") {
      double v;
      memcpy(&v, at, 8);
      return v;
    }
    if (p->type == "uchar" || p->type == "uint8") return *at;
    if (p->type == "ushort" || p->type == "uint16") {
      uint16_t v;
      memcpy(&v, at, 2);
      return v;
    }
    return 0;
  };
  const Prop *x = find("x"), *y = find("y"), *z = find("z"), *r = find("red"),
             *g = find("green"), *b = find("blue"), *d0 = find("f_dc_0"),
             *d1 = find("f_dc_1"), *d2 = find("f_dc_2"), *op = find("opacity"),
             *s0 = find("scale_0"), *s1 = find("scale_1"),
             *s2 = find("scale_2"), *r0 = find("rot_0"), *r1 = find("rot_1"),
             *r2 = find("rot_2"), *r3 = find("rot_3");
  if (!x || !y || !z)
    return why = "a point cloud's points have x, y and z", nullptr;
  // Indices of the points to draw. A splat that is nearly clear (opacity below
  // 0.05) is left out.
  std::vector<uint32_t> visible;
  visible.reserve(n);
  for (size_t i = 0; i < n; ++i)
    if (!op || 1.0 / (1.0 + std::exp(-get(op, i))) >= 0.05)
      visible.push_back((uint32_t)i);
  if (visible.empty())
    return why = "the point cloud has no points to see", nullptr;
  // Bounding box of the middle 98% of the points: the lowest and highest 1%
  // along each axis are ignored. A few far-off specks, such as the sky and
  // floaters of a capture, would otherwise shrink the rest. Those points are
  // still drawn where they are.
  float3 lo, hi;
  for (int a = 0; a < 3; ++a) {
    const Prop* along = a == 0 ? x : a == 1 ? y : z;
    std::vector<float> v(visible.size());
    // The scan's y points down, as in COLMAP, so negate it to make y point up.
    for (size_t k = 0; k < visible.size(); ++k)
      v[k] = (float)(a == 1 ? -get(along, visible[k]) : get(along, visible[k]));
    std::nth_element(v.begin(), v.begin() + (long)(v.size() / 100), v.end());
    lo[a] = v[v.size() / 100];
    std::nth_element(
        v.begin(), v.begin() + (long)(v.size() - 1 - v.size() / 100), v.end());
    hi[a] = v[v.size() - 1 - v.size() / 100];
  }
  // Scale so that the largest of the height, half the width and half the depth
  // becomes 1. For a scan of a room or a street, that is its height.
  const float3 mid = 0.5f * (lo + hi);
  const float tall = std::max(
      1e-6f,
      std::max({hi.y - lo.y, 0.5f * (hi.x - lo.x), 0.5f * (hi.z - lo.z)}));
  // Point size of a plain scan, relative to `tall`: 1.2 times the cube root of
  // the box volume per point, which approximates the distance to the neighbors.
  const float plain = 1.2f *
                      std::cbrt((hi.x - lo.x) * (hi.y - lo.y) * (hi.z - lo.z) /
                                (float)visible.size()) /
                      tall;
  const size_t m = visible.size();
  // Each splat takes four RGBA32F texels, the layout PlayCanvas uses, so that
  // its effects read them unchanged (see points.mat).
  //   - Texel 0: center in the file's units with y up, and opacity.
  //   - Texel 1: rotation quaternion x, y, z, w.
  //   - Texel 2: size along each axis, and red.
  //   - Texel 3: green and blue.
  // The fit to 1 tall is applied only when drawing, through the `fit` parameter
  // of the material.
  const uint32_t wide = 4096, rows = (uint32_t)((m * 4 + wide - 1) / wide);
  std::vector<float> data((size_t)wide * rows * 4, 0.f);
  std::vector<float3> middles(m);
  for (size_t k = 0; k < m; ++k) {
    const size_t i = visible[k];
    const float3 p{(float)get(x, i), (float)-get(y, i), (float)get(z, i)};
    float3 colour{1.f};
    if (r && g && b)
      colour =
          float3{(float)get(r, i), (float)get(g, i), (float)get(b, i)} / 255.f;
    // 3DGS stores color as the zero-order spherical harmonic: color = 0.5 +
    // 0.2820948 * f_dc.
    else if (d0 && d1 && d2)
      colour =
          clamp(0.5f + 0.2820948f * float3{(float)get(d0, i), (float)get(d1, i),
                                           (float)get(d2, i)},
                0.f, 1.f);
    // Rotation quaternion, x y z w.
    float4 turn{0, 0, 0, 1};
    // A plain scan point is round, with a radius of half the gap to its
    // neighbors.
    float3 size{0.5f * plain * tall};
    if (s0 && s1 && s2) {
      // 3DGS writes the quaternion with w first.
      float4 q = r0 && r1 && r2 && r3
                     ? float4{(float)get(r1, i), (float)get(r2, i),
                              (float)get(r3, i), (float)get(r0, i)}
                     : float4{0, 0, 0, 1};
      q = length(q) > 1e-12f ? normalize(q) : float4{0, 0, 0, 1};
      // The same rotation seen with the y axis flipped.
      turn = float4{-q.x, q.y, -q.z, q.w};
      size = float3{std::exp((float)get(s0, i)), std::exp((float)get(s1, i)),
                    std::exp((float)get(s2, i))};
    }
    const float seen = op ? 1.f / (1.f + std::exp(-(float)get(op, i))) : 1.f;
    middles[k] = p;
    const float four[16] = {
        p.x,    p.y,    p.z,    seen,     turn.x,   turn.y,   turn.z, turn.w,
        size.x, size.y, size.z, colour.r, colour.g, colour.b, 0,      0};
    memcpy(&data[k * 16], four, sizeof four);
  }
  const mat4f fit =
      mat4f::scaling(float3{1.f / tall}) * mat4f::translation(-mid);
  // Report the trimmed box in the file's units, y up, for the caller to hand to
  // effects.
  if (bounds) bounds[0] = lo, bounds[1] = hi;
  // Use the given material, which has an effect compiled in (see
  // points_effect), or the plain one.
  Material* mat = with ? with : material(s, "points.filamat");
  if (!mat) return why = "points.filamat is not built", nullptr;
  Texture* splats = Texture::Builder()
                        .width(wide)
                        .height(rows)
                        .levels(1)
                        .format(Texture::InternalFormat::RGBA32F)
                        .sampler(Texture::Sampler::SAMPLER_2D)
                        .build(*s.engine);
  splats->setImage(
      *s.engine, 0,
      points_pixels(std::move(data), backend::PixelDataFormat::RGBA));
  const uint32_t slotRows = (uint32_t)((m + wide - 1) / wide);
  Texture* order = Texture::Builder()
                       .width(wide)
                       .height(slotRows)
                       .levels(1)
                       .format(Texture::InternalFormat::R32F)
                       .sampler(Texture::Sampler::SAMPLER_2D)
                       .build(*s.engine);
  // Until the first sort arrives, the slots hold the splats in file order.
  {
    std::vector<float> first((size_t)wide * slotRows, 0.f);
    for (size_t k = 0; k < m; ++k) first[k] = (float)k;
    order->setImage(
        *s.engine, 0,
        points_pixels(std::move(first), backend::PixelDataFormat::R));
  }
  // Four corners and six indices per splat. They never change after this.
  std::vector<float3> corners(m * 4);
  std::vector<uint32_t> idx(m * 6);
  // The corners are two spreads away from the center in each direction. Beyond
  // that the splat has all but faded out.
  static const float2 c4[4] = {{-2, -2}, {2, -2}, {2, 2}, {-2, 2}};
  for (size_t k = 0; k < m; ++k) {
    for (int c = 0; c < 4; ++c)
      corners[k * 4 + (size_t)c] = float3{c4[c].x, c4[c].y, (float)k};
    const uint32_t v = (uint32_t)(k * 4);
    const uint32_t six[6] = {v, v + 1, v + 2, v, v + 2, v + 3};
    memcpy(&idx[k * 6], six, sizeof six);
  }
  VertexBuffer* vb = VertexBuffer::Builder()
                         .vertexCount((uint32_t)corners.size())
                         .bufferCount(1)
                         .attribute(VertexAttribute::POSITION, 0,
                                    VertexBuffer::AttributeType::FLOAT3)
                         .build(*s.engine);
  vb->setBufferAt(*s.engine, 0,
                  copied(corners.data(), corners.size() * sizeof(float3)));
  IndexBuffer* ib = IndexBuffer::Builder()
                        .indexCount((uint32_t)idx.size())
                        .bufferType(IndexBuffer::IndexType::UINT)
                        .build(*s.engine);
  ib->setBuffer(*s.engine, copied(idx.data(), idx.size() * sizeof(uint32_t)));
  MaterialInstance* look = mat->createInstance();
  TextureSampler exact(TextureSampler::MinFilter::NEAREST,
                       TextureSampler::MagFilter::NEAREST);
  look->setParameter("splats", splats, exact);
  look->setParameter("order", order, exact);
  look->setParameter("fit", fit);
  Mesh* name = new Mesh;
  name->vb = vb, name->ib = ib;
  utils::Entity e = utils::EntityManager::get().create();
  const float3 box = 0.5f * (hi - lo) / tall + float3{0.05f};
  RenderableManager::Builder(1)
      .boundingBox({float3{0.f}, box * 3.f})
      .geometry(0, RenderableManager::PrimitiveType::TRIANGLES, vb, ib, 0,
                idx.size())
      .material(0, look)
      .castShadows(false)
      .receiveShadows(false)
      .culling(false)
      .build(*s.engine, e);
  s.engine->getTransformManager().create(e);
  s.scene->addEntity(e);
  s.renderables.push_back({e, name, 0, mat4f{}});

  // The depth sort, after antimatter15/splat. The depth of each splat along the
  // viewing direction is quantized to 16 bits between the nearest and the
  // farthest splat and ordered with one counting pass. It runs on a separate
  // thread and is requested again whenever the camera has moved. The resulting
  // order is farthest first. State shared between the render thread and the
  // sorting thread.
  struct Sorter {
    // Splat centers in the file's units.
    std::vector<float3> middles;
    // Guards the fields below.
    std::mutex lock;
    // Signalled when a sort is requested or the thread must stop.
    std::condition_variable told;
    // `asked` is the depth row of the latest request. `done` is the row of the
    // latest finished sort.
    float4 asked{0.f}, done{1e9f};
    // `fresh`: a request is waiting. `ready`: a finished sort is waiting to be
    // uploaded. `stop`: the thread must exit.
    bool fresh = false, ready = false, stop = false;
    // The finished slot table: splat indices ordered back to front.
    std::vector<float> slots;
    std::thread worker;
  };
  // Owns the sorter. The deleter stops and joins the thread before freeing the
  // state. The last owner is the callback registered in s.playing, so the
  // sorter ends when that is erased.
  std::shared_ptr<Sorter> sort(new Sorter, [](Sorter* p) {
    {
      std::lock_guard<std::mutex> hold(p->lock);
      p->stop = true;
    }
    p->told.notify_one();
    p->worker.join();
    delete p;
  });
  sort->middles = std::move(middles);
  sort->worker = std::thread([sort = sort.get(), wide, slotRows] {
    std::vector<int32_t> depth(sort->middles.size());
    std::vector<uint32_t> counts(65536), starts(65536);
    for (;;) {
      float4 row;
      {
        std::unique_lock<std::mutex> hold(sort->lock);
        sort->told.wait(hold, [sort] { return sort->fresh || sort->stop; });
        if (sort->stop) return;
        row = sort->asked, sort->fresh = false;
      }
      int32_t least = INT32_MAX, most = INT32_MIN;
      for (size_t i = 0; i < depth.size(); ++i) {
        const float3& p = sort->middles[i];
        // Camera-space z scaled by 4096 and truncated to an integer.
        // Farther splats get smaller values.
        depth[i] = (int32_t)((row.x * p.x + row.y * p.y + row.z * p.z + row.w) *
                             4096.f);
        least = std::min(least, depth[i]), most = std::max(most, depth[i]);
      }
      const float inv = 65535.f / (float)std::max(1, most - least);
      std::fill(counts.begin(), counts.end(), 0u);
      for (int32_t& d : depth)
        d = (int32_t)((float)(d - least) * inv), ++counts[(size_t)d];
      starts[0] = 0;
      for (size_t k = 1; k < 65536; ++k)
        starts[k] = starts[k - 1] + counts[k - 1];
      std::vector<float> slots((size_t)wide * slotRows, 0.f);
      for (size_t i = 0; i < depth.size(); ++i)
        slots[starts[(size_t)depth[i]]++] = (float)i;
      std::lock_guard<std::mutex> hold(sort->lock);
      sort->slots = std::move(slots), sort->done = row, sort->ready = true;
    }
  });
  // Called on every update. Computes the depth row of the camera relative to
  // the cloud, requests a new sort if the row has changed, and uploads a
  // finished sort.
  s.playing[name] = [&s, sort, e, order, wide, slotRows, fit](double) {
    const auto& places = s.engine->getTransformManager();
    const math::mat4 eye =
        s.camera->getViewMatrix() *
        math::mat4(places.getWorldTransform(places.getInstance(e))) *
        math::mat4(fit);
    const float4 row{(float)eye[0][2], (float)eye[1][2], (float)eye[2][2],
                     (float)eye[3][2]};
    std::lock_guard<std::mutex> hold(sort->lock);
    if (sort->ready) {
      order->setImage(
          *s.engine, 0,
          points_pixels(std::move(sort->slots), backend::PixelDataFormat::R));
      sort->ready = false;
    }
    if (length(row - sort->asked) > 1e-4f)
      sort->asked = row, sort->fresh = true, sort->told.notify_one();
  };
  if (looks) *looks = look;
  // With an effect, also build the plain material instance over the same
  // textures, for use once the effect has finished.
  if (plainLook && with)
    if (Material* plain = material(s, "points.filamat")) {
      MaterialInstance* p = plain->createInstance();
      p->setParameter("splats", splats, exact),
          p->setParameter("order", order, exact), p->setParameter("fit", fit);
      p->setParameter("dissolve", 0.f), p->setParameter("grain", 1.f);
      *plainLook = p;
    }
  return name;
}

Material* points_effect(Stage& s, const std::string& file,
                        std::shared_ptr<SplatEffect>& fx, std::string& why) {
  fx = std::make_shared<SplatEffect>(file);
  if (!fx->ok()) return why = fx->trouble(), fx.reset(), nullptr;
  static std::map<std::string, Material*> built;
  Material*& m = built[fx->glsl()];
  if (m) return m;
  Dl_info lib{};
  dladdr((const void*)&points_effect, &lib);
  std::error_code wrong;
  const std::filesystem::path source =
      std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".",
                                        wrong)
          .parent_path()
          .parent_path() /
      "materials" / "points.mat";
  std::ifstream in(source);
  std::stringstream text;
  text << in.rdbuf();
  const std::vector<uint8_t> bytes =
      splat_effect_look(text.str(), fx->glsl(), s.engine->getJobSystem(), why);
  if (bytes.empty()) return nullptr;
  return m = Material::Builder()
                 .package(bytes.data(), bytes.size())
                 .build(*s.engine);
}

}  // namespace motolii

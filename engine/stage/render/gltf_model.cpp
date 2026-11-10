#include "stage/render/gltf_model.h"

#include <filament/Box.h>
#include <filament/Color.h>
#include <filament/Engine.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/TransformManager.h>
#include <gltfio/Animator.h>
#include <gltfio/AssetLoader.h>
#include <gltfio/FilamentAsset.h>
#include <gltfio/FilamentInstance.h>
#include <gltfio/ResourceLoader.h>
#include <gltfio/TextureProvider.h>
#include <gltfio/materials/uberarchive.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <utils/Entity.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>
// cgltf is the glTF parser that gltfio is built on. It is already part of
// Filament's library.
#include "stage/render/render_stage.h"
#include "third_party/filament_src/third_party/cgltf/cgltf.h"

namespace motolii {

using filament::Aabb;
using filament::ACCURATE;
using filament::Color;
using filament::Material;
using filament::MaterialInstance;
using filament::sRGBColor;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
namespace gltfio = filament::gltfio;

void solid_at(Solid* d, const std::string& name, double seconds, size_t nth) {
  gltfio::Animator* moves = d->asset->getAssetInstances()[nth]->getAnimator();
  if (!moves->getAnimationCount()) return;
  size_t which = 0;
  for (size_t i = 0; i < d->moves.size(); ++i)
    if (d->moves[i] == name) which = i;
  const float lasts = moves->getAnimationDuration(which);
  if (lasts <= 0.f) return;
  moves->applyAnimation(which,
                        (float)(seconds - lasts * std::floor(seconds / lasts)));
  moves->updateBoneMatrices();
}

namespace {
// Returns the stage's gltfio AssetLoader, creating it with the default
// ubershader provider on first use.
gltfio::AssetLoader* solid_loader(Stage& s) {
  if (!s.solids)
    s.solids = gltfio::AssetLoader::create(
        {s.engine,
         gltfio::createUbershaderProvider(s.engine, UBERARCHIVE_DEFAULT_DATA,
                                          UBERARCHIVE_DEFAULT_SIZE)});
  return (gltfio::AssetLoader*)s.solids;
}
}  // namespace

void solid_to(Stage& s, Solid* d, const mat4f& place, size_t nth) {
  auto& tm = s.engine->getTransformManager();
  tm.setTransform(tm.getInstance(d->asset->getAssetInstances()[nth]->getRoot()),
                  place * d->fit);
}

Solid* solid(Stage& s, const char* file, const mat4f& place, float high,
             int many) {
  const std::vector<uint8_t> bytes = load_file(file);
  Solid* d = new Solid;
  std::vector<gltfio::FilamentInstance*> ones((size_t)std::max(1, many));
  d->asset = bytes.empty() ? nullptr
                           : solid_loader(s)->createInstancedAsset(
                                 bytes.data(), (uint32_t)bytes.size(),
                                 ones.data(), ones.size());
  if (!d->asset) return nullptr;
  // Filament's gltf_viewer sets gltfPath so that the resources of a .gltf file
  // are found.
  gltfio::ResourceLoader resources(
      {.engine = s.engine, .gltfPath = file, .normalizeSkinningWeights = true});
  // The external resources of a .gltf, such as .bin files next to it. They are
  // read here and handed to gltfio, as it requires.
  std::vector<std::vector<uint8_t>> beside(d->asset->getResourceUriCount());
  for (size_t i = 0; i < beside.size(); ++i) {
    const char* part = d->asset->getResourceUris()[i];
    beside[i] = load_file(
        (std::filesystem::path(file).parent_path() / part).string().c_str());
    resources.addResourceData(part, gltfio::ResourceLoader::BufferDescriptor(
                                        beside[i].data(), beside[i].size()));
  }
  if (!s.solidTextures) s.solidTextures = gltfio::createStbProvider(s.engine);
  gltfio::TextureProvider* reader = (gltfio::TextureProvider*)s.solidTextures;
  resources.addTextureProvider("image/png", reader);
  resources.addTextureProvider("image/jpeg", reader);
  if (!resources.loadResources(d->asset)) return nullptr;
  d->asset->releaseSourceData();
  const Aabb box = d->asset->getBoundingBox();
  d->fit = mat4f::scaling(high / std::max(box.max.y - box.min.y, 1e-6f)) *
           mat4f::translation(-0.5f * (box.min + box.max));
  solid_to(s, d, place);
  for (size_t i = 0; i < d->asset->getEntityCount(); ++i)
    if (s.engine->getRenderableManager().hasComponent(
            d->asset->getEntities()[i]))
      d->parts.push_back(d->asset->getEntities()[i]);
  s.scene->addEntities(d->parts.data(), d->parts.size());
  gltfio::Animator* moves = d->asset->getInstance()->getAnimator();
  // Name each animation. An unnamed one is called move<number>, and spaces
  // become underscores.
  for (size_t i = 0; i < moves->getAnimationCount(); ++i) {
    const char* name = moves->getAnimationName(i);
    std::string word = name && *name ? name : "move" + std::to_string(i + 1);
    std::replace(word.begin(), word.end(), ' ', '_');
    d->moves.push_back(word);
  }
  // Loop the first animation as the stage's time advances.
  if (moves->getAnimationCount()) {
    d->seconds = moves->getAnimationDuration(0);
    s.playing[d] = [d, moves](double now) {
      moves->applyAnimation(0, std::fmod((float)now + d->starts, d->seconds));
      moves->updateBoneMatrices();
    };
  }
  return d;
}

Mesh* solid_mesh(const char* file) {
  cgltf_options how{};
  cgltf_data* read = nullptr;
  if (cgltf_parse_file(&how, file, &read) != cgltf_result_success)
    return nullptr;
  if (cgltf_load_buffers(&how, read, file) != cgltf_result_success)
    return cgltf_free(read), nullptr;
  Mesh* m = new Mesh;
  for (cgltf_size n = 0; n < read->nodes_count; ++n) {
    const cgltf_node& node = read->nodes[n];
    if (!node.mesh) continue;
    float to[16];
    cgltf_node_transform_world(&node, to);
    const mat4f world(float4{to[0], to[1], to[2], to[3]},
                      float4{to[4], to[5], to[6], to[7]},
                      float4{to[8], to[9], to[10], to[11]},
                      float4{to[12], to[13], to[14], to[15]});
    for (cgltf_size p = 0; p < node.mesh->primitives_count; ++p) {
      const cgltf_primitive& part = node.mesh->primitives[p];
      const cgltf_accessor* places = nullptr;
      const cgltf_accessor* ways = nullptr;
      for (cgltf_size a = 0; a < part.attributes_count; ++a) {
        if (part.attributes[a].type == cgltf_attribute_type_position)
          places = part.attributes[a].data;
        if (part.attributes[a].type == cgltf_attribute_type_normal)
          ways = part.attributes[a].data;
      }
      if (part.type != cgltf_primitive_type_triangles || !places) continue;
      const uint32_t first = (uint32_t)m->pos.size();
      for (cgltf_size v = 0; v < places->count; ++v) {
        float at[3] = {0, 0, 0}, faces[3] = {0, 0, 1};
        cgltf_accessor_read_float(places, v, at, 3);
        if (ways) cgltf_accessor_read_float(ways, v, faces, 3);
        m->pos.push_back((world * float4{at[0], at[1], at[2], 1.f}).xyz);
        m->nrm.push_back(
            normalize((world * float4{faces[0], faces[1], faces[2], 0.f}).xyz));
        m->uv.push_back(float2{0.f});
      }
      const cgltf_size corners =
          part.indices ? part.indices->count : places->count;
      for (cgltf_size i = 0; i < corners; ++i)
        m->idx.push_back(
            first + (uint32_t)(part.indices
                                   ? cgltf_accessor_read_index(part.indices, i)
                                   : i));
      // The file has no normals, so each corner gets the flat normal of its
      // triangle.
      if (!ways)
        for (size_t i = m->idx.size() - corners; i + 2 < m->idx.size();
             i += 3) {
          const float3 flat =
              normalize(cross(m->pos[m->idx[i + 1]] - m->pos[m->idx[i]],
                              m->pos[m->idx[i + 2]] - m->pos[m->idx[i]]));
          for (int k = 0; k < 3; ++k) m->nrm[m->idx[i + (size_t)k]] = flat;
        }
    }
  }
  cgltf_free(read);
  if (m->idx.empty()) return delete m, nullptr;
  float3 low = m->pos[0], high = m->pos[0];
  for (const float3& p : m->pos) low = min(low, p), high = max(high, p);
  const float fit = 1.f / std::max(high.y - low.y, 1e-6f);
  for (float3& p : m->pos) p = (p - 0.5f * (low + high)) * fit;
  return m;
}

void plain(MaterialInstance* look, float3 colour, const Surface& is) {
  const auto put = [&](const char* name, float v) {
    if (look->getMaterial()->hasParameter(name)) look->setParameter(name, v);
  };
  look->setParameter("color",
                     float4{Color::toLinear<ACCURATE>(sRGBColor{colour}), 1.f});
  put("roughness", is.roughness);
  put("metalOff", is.metallic - 0.08f);
  put("reflectanceOff", is.reflectance - 0.5f);
  put("clearCoat", is.coat);
  put("clearCoatRoughness", is.coatRoughness);
  put("glowing", is.glow);
  put("sheen", is.sheen);
  put("anisotropy", is.anisotropy);
  put("thickness", is.thickness);
}

void solid_fill(Stage& s, Solid* d, float3 colour, const Surface& is,
                const char* model) {
  Material* lit = material(s, model);
  if (!lit) return;
  MaterialInstance* look = lit->createInstance();
  plain(look, colour, is);
  auto& faces = s.engine->getRenderableManager();
  for (const utils::Entity part : d->parts) {
    const auto one = faces.getInstance(part);
    for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
      faces.setMaterialInstanceAt(one, part, look);
  }
}

namespace {
// Adds the model to the scene or removes it, according to `in`.
void solid_seen(Stage& s, Solid* d, bool in) {
  if (in)
    s.scene->addEntities(d->parts.data(), d->parts.size());
  else
    s.scene->removeEntities(d->parts.data(), d->parts.size());
}
}  // namespace

void solid_off(Stage& s, Solid* d) {
  s.playing.erase(d);
  solid_seen(s, d, false);
  solid_loader(s)->destroyAsset(d->asset);
  delete d;
}

}  // namespace motolii

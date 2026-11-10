// Loads a glTF 3D file (.glb or .gltf) into the stage's scene using Filament's gltfio.
// gltfio reads the file and supplies the ready-made glTF materials, which are lit by the
// stage's lighting. If the file contains animations, they advance with the stage's time
// through gltfio's Animator.
// Included by render.h; not self-contained.
#include <filament/Color.h>
#include <filesystem>
#include <gltfio/Animator.h>
#include <gltfio/AssetLoader.h>
#include <gltfio/FilamentAsset.h>
#include <gltfio/ResourceLoader.h>
#include <gltfio/TextureProvider.h>
#include <gltfio/materials/uberarchive.h>
// cgltf is the glTF parser that gltfio is built on. It is already part of Filament's library.
#include "third_party/filament_src/third_party/cgltf/cgltf.h"

// A glTF model placed in the scene.
struct Solid {
    gltfio::FilamentAsset* asset = nullptr;
    // Transform that scales the model to 1 unit tall and centers it on the origin of its placement.
    mat4f fit;
    // Length in seconds of the model's first animation, or 0 if it has none.
    float seconds = 0.f;
    // Offset into the animation, in seconds, at stage time 0.
    float starts = 0.f;
    // Animation names. A file may have several; gltfio's Animator exposes them.
    std::vector<std::string> moves;
    // Renderable entities of every instance. gltfio's getRenderableEntities returns only one
    // instance's worth.
    std::vector<utils::Entity> parts;
};

// Poses instance `nth` of the model at `seconds`, looping the animation. Plays the animation
// called `name`, or the first one if the name is empty or unknown. Does nothing if the model
// has no animation.
static void solid_at(Solid* d, const std::string& name, double seconds, size_t nth = 0) {
    gltfio::Animator* moves = d->asset->getAssetInstances()[nth]->getAnimator();
    if (!moves->getAnimationCount()) return;
    size_t which = 0;
    for (size_t i = 0; i < d->moves.size(); ++i) if (d->moves[i] == name) which = i;
    const float lasts = moves->getAnimationDuration(which);
    if (lasts <= 0.f) return;
    moves->applyAnimation(which, (float)(seconds - lasts * std::floor(seconds / lasts)));
    moves->updateBoneMatrices();
}

// Returns the stage's gltfio AssetLoader, creating it with the default ubershader provider on
// first use.
static gltfio::AssetLoader* solid_loader(Stage& s) {
    if (!s.solids) s.solids = gltfio::AssetLoader::create({s.engine, gltfio::createUbershaderProvider(s.engine, UBERARCHIVE_DEFAULT_DATA, UBERARCHIVE_DEFAULT_SIZE)});
    return (gltfio::AssetLoader*)s.solids;
}

// Places instance `nth` of the model at `place`. `place` may include scaling.
static void solid_to(Stage& s, Solid* d, const mat4f& place, size_t nth = 0) {
    auto& tm = s.engine->getTransformManager();
    tm.setTransform(tm.getInstance(d->asset->getAssetInstances()[nth]->getRoot()), place * d->fit);
}

// Adds the glTF file to the scene, scaled to `high` tall and centered at `place`. Creates
// `many` instances that share one source and can be placed and animated separately; gltfio
// needs the count up front (AssetLoader::createInstance). Returns nullptr if the file cannot
// be read.
static Solid* solid(Stage& s, const char* file, const mat4f& place, float high, int many = 1) {
    const std::vector<uint8_t> bytes = load_file(file);
    Solid* d = new Solid;
    std::vector<gltfio::FilamentInstance*> ones((size_t)std::max(1, many));
    d->asset = bytes.empty() ? nullptr : solid_loader(s)->createInstancedAsset(bytes.data(), (uint32_t)bytes.size(), ones.data(), ones.size());
    if (!d->asset) return nullptr;
    // Filament's gltf_viewer sets gltfPath so that the resources of a .gltf file are found.
    gltfio::ResourceLoader resources({.engine = s.engine, .gltfPath = file, .normalizeSkinningWeights = true});
    // The external resources of a .gltf, such as .bin files next to it. They are read here and
    // handed to gltfio, as it requires.
    std::vector<std::vector<uint8_t>> beside(d->asset->getResourceUriCount());
    for (size_t i = 0; i < beside.size(); ++i) {
        const char* part = d->asset->getResourceUris()[i];
        beside[i] = load_file((std::filesystem::path(file).parent_path() / part).string().c_str());
        resources.addResourceData(part, gltfio::ResourceLoader::BufferDescriptor(beside[i].data(), beside[i].size()));
    }
    if (!s.solidTextures) s.solidTextures = gltfio::createStbProvider(s.engine);
    gltfio::TextureProvider* reader = (gltfio::TextureProvider*)s.solidTextures;
    resources.addTextureProvider("image/png", reader);
    resources.addTextureProvider("image/jpeg", reader);
    if (!resources.loadResources(d->asset)) return nullptr;
    d->asset->releaseSourceData();
    const Aabb box = d->asset->getBoundingBox();
    d->fit = mat4f::scaling(high / std::max(box.max.y - box.min.y, 1e-6f)) * mat4f::translation(-0.5f * (box.min + box.max));
    solid_to(s, d, place);
    for (size_t i = 0; i < d->asset->getEntityCount(); ++i)
        if (s.engine->getRenderableManager().hasComponent(d->asset->getEntities()[i])) d->parts.push_back(d->asset->getEntities()[i]);
    s.scene->addEntities(d->parts.data(), d->parts.size());
    gltfio::Animator* moves = d->asset->getInstance()->getAnimator();
    // Name each animation. An unnamed one is called move<number>, and spaces become underscores.
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

// Reads the shape of a glTF file as a Mesh, without materials. Every triangle is placed where
// the file puts it, then the mesh is scaled to 1 tall and centered on the origin, the same
// fit that `solid` applies. This is for renderer-made looks that draw a shape more than once,
// such as glass. The mesh is the rest pose; the file's animations are ignored. Returns nullptr
// if the file cannot be read.
static Mesh* solid_mesh(const char* file) {
    cgltf_options how{};
    cgltf_data* read = nullptr;
    if (cgltf_parse_file(&how, file, &read) != cgltf_result_success) return nullptr;
    if (cgltf_load_buffers(&how, read, file) != cgltf_result_success) return cgltf_free(read), nullptr;
    Mesh* m = new Mesh;
    for (cgltf_size n = 0; n < read->nodes_count; ++n) {
        const cgltf_node& node = read->nodes[n];
        if (!node.mesh) continue;
        float to[16];
        cgltf_node_transform_world(&node, to);
        const mat4f world(float4{to[0], to[1], to[2], to[3]}, float4{to[4], to[5], to[6], to[7]}, float4{to[8], to[9], to[10], to[11]}, float4{to[12], to[13], to[14], to[15]});
        for (cgltf_size p = 0; p < node.mesh->primitives_count; ++p) {
            const cgltf_primitive& part = node.mesh->primitives[p];
            const cgltf_accessor* places = nullptr;
            const cgltf_accessor* ways = nullptr;
            for (cgltf_size a = 0; a < part.attributes_count; ++a) {
                if (part.attributes[a].type == cgltf_attribute_type_position) places = part.attributes[a].data;
                if (part.attributes[a].type == cgltf_attribute_type_normal) ways = part.attributes[a].data;
            }
            if (part.type != cgltf_primitive_type_triangles || !places) continue;
            const uint32_t first = (uint32_t)m->pos.size();
            for (cgltf_size v = 0; v < places->count; ++v) {
                float at[3] = {0, 0, 0}, faces[3] = {0, 0, 1};
                cgltf_accessor_read_float(places, v, at, 3);
                if (ways) cgltf_accessor_read_float(ways, v, faces, 3);
                m->pos.push_back((world * float4{at[0], at[1], at[2], 1.f}).xyz);
                m->nrm.push_back(normalize((world * float4{faces[0], faces[1], faces[2], 0.f}).xyz));
                m->uv.push_back(float2{0.f});
            }
            const cgltf_size corners = part.indices ? part.indices->count : places->count;
            for (cgltf_size i = 0; i < corners; ++i) m->idx.push_back(first + (uint32_t)(part.indices ? cgltf_accessor_read_index(part.indices, i) : i));
            // The file has no normals, so each corner gets the flat normal of its triangle.
            if (!ways)
                for (size_t i = m->idx.size() - corners; i + 2 < m->idx.size(); i += 3) {
                    const float3 flat = normalize(cross(m->pos[m->idx[i + 1]] - m->pos[m->idx[i]], m->pos[m->idx[i + 2]] - m->pos[m->idx[i]]));
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

// Surface parameters of a Filament material: metallic, roughness, reflectance, clear coat
// and its roughness, glow, cloth sheen, anisotropy and subsurface thickness. `glow` is how
// much the surface lights itself: 1 shows its own color, larger values are brighter.
// Returns the material file for a shading model: "cloth", "subsurface", or the default lit
// model (floor_lit.filamat, lit by the stage's lighting).
struct Surface { float metallic = 0.08f, roughness = 0.6f, reflectance = 0.5f, coat = 0.f, coatRoughness = 0.f, glow = 0.f, sheen = 0.f, anisotropy = 0.f, thickness = 0.5f; };
static const char* surface_model(const std::string& shading) { return shading == "cloth" ? "solid_cloth.filamat" : shading == "subsurface" ? "solid_subsurface.filamat" : "floor_lit.filamat"; }
// Sets the parameters of a material instance for a flat `colour` (sRGB) and the given surface.
// The material stores metallic and reflectance as offsets from the defaults 0.08 and 0.5.
// Parameters that the material does not declare are skipped.
static void plain(MaterialInstance* look, float3 colour, const Surface& is = {}) {
    const auto put = [&](const char* name, float v) { if (look->getMaterial()->hasParameter(name)) look->setParameter(name, v); };
    look->setParameter("color", float4{Color::toLinear<ACCURATE>(sRGBColor{colour}), 1.f});
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
// Gives every primitive of the model one material instance made from `model`, with the given
// color and surface. This replaces the materials named in the file. Does nothing if the
// material is not available.
static void solid_fill(Stage& s, Solid* d, float3 colour, const Surface& is = {}, const char* model = "floor_lit.filamat") {
    Material* lit = material(s, model);
    if (!lit) return;
    MaterialInstance* look = lit->createInstance();
    plain(look, colour, is);
    auto& faces = s.engine->getRenderableManager();
    for (const utils::Entity part : d->parts) {
        const auto one = faces.getInstance(part);
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part) faces.setMaterialInstanceAt(one, part, look);
    }
}

// Adds the model to the scene or removes it, according to `in`.
static void solid_seen(Stage& s, Solid* d, bool in) {
    if (in) s.scene->addEntities(d->parts.data(), d->parts.size());
    else s.scene->removeEntities(d->parts.data(), d->parts.size());
}
// Removes the model from the scene and destroys it. The pointer is invalid afterwards.
static void solid_off(Stage& s, Solid* d) {
    s.playing.erase(d);
    solid_seen(s, d, false);
    solid_loader(s)->destroyAsset(d->asset);
    delete d;
}

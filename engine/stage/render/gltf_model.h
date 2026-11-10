#ifndef MOTOLII_STAGE_RENDER_GLTF_MODEL_H_
#define MOTOLII_STAGE_RENDER_GLTF_MODEL_H_
// Loads a glTF 3D file (.glb or .gltf) into the stage's scene using Filament's
// gltfio. gltfio reads the file and supplies the ready-made glTF materials,
// which are lit by the stage's lighting. If the file contains animations, they
// advance with the stage's time through gltfio's Animator.
#include <filament/MaterialInstance.h>
#include <gltfio/FilamentAsset.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <utils/Entity.h>

#include <cstddef>
#include <string>
#include <vector>

#include "stage/render/render_stage.h"

namespace motolii {

// A glTF model placed in the scene.
struct Solid {
  filament::gltfio::FilamentAsset* asset = nullptr;
  // Transform that scales the model to 1 unit tall and centers it on the origin
  // of its placement.
  filament::math::mat4f fit;
  // Length in seconds of the model's first animation, or 0 if it has none.
  float seconds = 0.f;
  // Offset into the animation, in seconds, at stage time 0.
  float starts = 0.f;
  // Animation names. A file may have several; gltfio's Animator exposes them.
  std::vector<std::string> moves;
  // Renderable entities of every instance. gltfio's getRenderableEntities
  // returns only one instance's worth.
  std::vector<utils::Entity> parts;
};

// Poses instance `nth` of the model at `seconds`, looping the animation. Plays
// the animation called `name`, or the first one if the name is empty or
// unknown. Does nothing if the model has no animation.
void solid_at(Solid* d, const std::string& name, double seconds,
              size_t nth = 0);

// Places instance `nth` of the model at `place`. `place` may include scaling.
void solid_to(Stage& s, Solid* d, const filament::math::mat4f& place,
              size_t nth = 0);

// Adds the glTF file to the scene, scaled to `high` tall and centered at
// `place`. Creates `many` instances that share one source and can be placed and
// animated separately; gltfio needs the count up front
// (AssetLoader::createInstance). Returns nullptr if the file cannot be read.
Solid* solid(Stage& s, const char* file, const filament::math::mat4f& place,
             float high, int many = 1);

// Reads the shape of a glTF file as a Mesh, without materials. Every triangle
// is placed where the file puts it, then the mesh is scaled to 1 tall and
// centered on the origin, the same fit that `solid` applies. This is for
// renderer-made looks that draw a shape more than once, such as glass. The mesh
// is the rest pose; the file's animations are ignored. Returns nullptr if the
// file cannot be read.
Mesh* solid_mesh(const char* file);

// Surface parameters of a Filament material: metallic, roughness, reflectance,
// clear coat and its roughness, glow, cloth sheen, anisotropy and subsurface
// thickness. `glow` is how much the surface lights itself: 1 shows its own
// color, larger values are brighter. Returns the material file for a shading
// model: "cloth", "subsurface", or the default lit model (floor_lit.filamat,
// lit by the stage's lighting).
struct Surface {
  float metallic = 0.08f, roughness = 0.6f, reflectance = 0.5f, coat = 0.f,
        coatRoughness = 0.f, glow = 0.f, sheen = 0.f, anisotropy = 0.f,
        thickness = 0.5f;
};
inline const char* surface_model(const std::string& shading) {
  return shading == "cloth"        ? "solid_cloth.filamat"
         : shading == "subsurface" ? "solid_subsurface.filamat"
                                   : "floor_lit.filamat";
}
// Sets the parameters of a material instance for a flat `colour` (sRGB) and the
// given surface. The material stores metallic and reflectance as offsets from
// the defaults 0.08 and 0.5. Parameters that the material does not declare are
// skipped.
void plain(filament::MaterialInstance* look, filament::math::float3 colour,
           const Surface& is = {});
// Gives every primitive of the model one material instance made from `model`,
// with the given color and surface. This replaces the materials named in the
// file. Does nothing if the material is not available.
void solid_fill(Stage& s, Solid* d, filament::math::float3 colour,
                const Surface& is = {},
                const char* model = "floor_lit.filamat");

// Removes the model from the scene and destroys it. The pointer is invalid
// afterwards.
void solid_off(Stage& s, Solid* d);

}  // namespace motolii

#endif  // MOTOLII_STAGE_RENDER_GLTF_MODEL_H_

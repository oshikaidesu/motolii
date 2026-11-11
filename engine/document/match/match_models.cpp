#include "document/match/match_models.h"

#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/TextureSampler.h>
#include <math/mat4.h>
#include <math/vec3.h>

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <filesystem>
#include <string>
#include <vector>

#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/value_at.h"
#include "document/match/rebuild.h"
#include "stage/render/gltf_model.h"
#include "stage/render/point_cloud.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Material;
using filament::MaterialInstance;
using filament::TextureSampler;
using filament::math::float3;
using filament::math::mat4f;

namespace {

// What the surface of a solid layer is made of, as the project says.
// material: the name of the material it wears. glass: that material is glass.
// coloured: its fill is a colour. surface: the parameters of Filament's lit
// surface. shading: the shading model, and model: the material file for it.
// own: the material is one of the built-in ones rather than Filament's lit
// surface. tone: the colour of the surface.
struct ModelSurface {
  std::string material;
  bool glass, coloured;
  Surface surface;
  std::string shading;
  const char* model;
  bool own;
  float3 tone;
};

// Reads what the surface of the layer is made of.
ModelSurface model_surface(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const std::string& fill = build.fill;
  const float3 colour = build.colour;
  const std::string material = doc_material(d, layer);
  const bool glass = material == "glass",
             coloured = !fill.empty() && fill != "glass";
  const Surface surface{
      (float)build.number("metallic", 0.08),
      (float)build.number("roughness", 0.6),
      (float)build.number("reflectance", 0.5),
      (float)build.number("clear_coat", 0),
      (float)build.number("clear_coat_roughness", 0),
      (float)build.number("emissive", 0),
      (float)build.number("sheen", 0),
      (float)build.number("anisotropy", 0),
      (float)build.number("thickness", 0.5)};
  const std::string shading = build.word("shading");
  // With clip on, use the material variant that a matte can cut.
  const char* model = build.number("clip", 0) > 0.5 &&
                              (shading.empty() || shading == "lit")
                          ? "floor_lit_matte.filamat"
                          : surface_model(shading);
  // True when the material is one of the built-in ones rather than
  // Filament's lit surface. It is applied by solid_wear.
  const bool own = doc_among("filament_glass lacquer bubble", material);
  const float3 tone = coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f;
  return ModelSurface{material, glass, coloured, surface,
                      shading,  model, own,      tone};
}

// Sets the glass material parameters from the document, with defaults
// when they are not set.
void glassy(Doc& d, int layer, MaterialInstance* look) {
  look->setParameter("ior", (float)doc_number(d, layer, "ior", 0, 1.5)),
      look->setParameter("split",
                         (float)doc_number(d, layer, "dispersion", 0, 0.1));
  look->setParameter("swim", (float)doc_number(d, layer, "swim", 0, 0.5)),
      look->setParameter("dark", (float)doc_number(d, layer, "dark", 0, 4));
  look->setParameter("vivid", (float)doc_number(d, layer, "vivid", 0, 1.3));
}

// Puts the mesh on the stage in `copies` copies, wearing the built-in material
// of the layer.
MaterialInstance* with_material(LayerBuild& build, const ModelSurface& wear,
                                Mesh* m, int copies) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  const std::string& material = wear.material;
  const bool coloured = wear.coloured;
  const float3 tone = wear.tone;
  return solid_wear(
      s, m, std::vector<mat4f>((size_t)std::max(1, copies), mat4f{}), material,
      material == "filament_glass" && !coloured ? float3{1.f} : tone,
      (float)doc_number(d, layer, "ior", 0, 1.5),
      (float)doc_number(d, layer, "dispersion", 0, 0.1),
      (float)doc_number(d, layer, "swim", 0, 0.5),
      (float)doc_number(d, layer, "dark", 0, 4),
      (float)doc_number(d, layer, "vivid", 0, 1.3),
      (float)doc_number(d, layer, "metallic", 0, 0.08));
}

// One of the built-in shapes: a gem, a cube, a ball, a ring, or the mesh a
// p5.js sketch draws.
void built_in_model(LayerBuild& build, const ModelSurface& wear) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& shape = build.shape;
  const float3 colour = build.colour;
  const bool glass = wear.glass, coloured = wear.coloured, own = wear.own;
  const Surface& surface = wear.surface;
  const char* model = wear.model;
  made.sketch = shape == "sketch";
  made.shape = made.sketch       ? sketch_mesh()
               : shape == "gem"  ? gem(0.5f)
               : shape == "cube" ? cube(0.1f)
               : shape == "ball" ? sphere(0.5f)
                                 : torus(0.37f, 0.13f);
  MaterialInstance* look =
      glass ? thick_glass(s, made.shape, {mat4f{}})
      : own && !made.sketch
          ? with_material(build, wear, made.shape,
                          (int)build.number("copies", 1))
          : add(s, made.shape, made.sketch ? "sketch.filamat" : model,
                std::vector<mat4f>(
                    (size_t)std::max(1,
                                     (int)build.number("copies", 1)),
                    mat4f{}));
  made.look = look;
  if (look && glass) glassy(d, layer, look);
  if (look && made.sketch)
    for (int i = 0; i < 6; ++i)
      look->setParameter(("picture" + std::to_string(i)).c_str(),
                         white_point(s), TextureSampler());
  if (!look)
    made.shape = nullptr;
  else if (!glass && !(own && !made.sketch))
    plain(look,
          coloured      ? colour
          : made.sketch ? float3{1.f}
                        : float3{0xd9, 0xd2, 0xc3} / 255.f,
          surface);
}

// A point cloud: its grains are drawn from one buffer (point_cloud.h).
void point_cloud(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  std::string& why = build.why;
  // A PlayCanvas splat effect on the cloud. The look is built with it.
  for (const std::string& w : doc_fx_list(d, layer))
    if (std::filesystem::path(w).extension() == ".mjs") made.splatFxFile = w;
  std::string effectWhy;
  Material* with =
      made.splatFxFile.empty()
          ? nullptr
          : points_effect(s, made.splatFxFile, made.splatFx, effectWhy);
  if (!effectWhy.empty()) std::fprintf(stderr, "%s\n", effectWhy.c_str());
  float3 box[2];
  made.shape =
      points(s, file.c_str(), why, &made.look, with, &made.splatPlain, box);
  // The effect gets the bounding box of the cloud itself.
  if (made.splatFx)
    for (int c = 0; c < 3; ++c)
      made.splatFx->usual(std::string("aabbMin_") + "xyz"[c], box[0][c]),
          made.splatFx->usual(std::string("aabbMax_") + "xyz"[c], box[1][c]);
  made.grains = made.shape != nullptr;
}

// A file's shape as glass, or with a built-in material: only its triangles are
// used, because the glass draws a shape three times.
void file_model_with_material(LayerBuild& build, const ModelSurface& wear) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string& file = build.file;
  const bool glass = wear.glass;
  MaterialInstance* look =
      (made.shape = solid_mesh(file.c_str()))
          ? glass ? thick_glass(s, made.shape, {mat4f{}})
                  : with_material(build, wear, made.shape,
                                  (int)build.number("copies", 1))
          : nullptr;
  made.look = look;
  if (!look)
    made.shape = nullptr;
  else if (glass)
    glassy(d, layer, look);
}

}  // namespace

void match_model(LayerBuild& build) {
  Stage& s = build.s;
  DocShownLayer& made = build.made;
  const std::string &file = build.file, &shape = build.shape;
  const long rgb = build.rgb;
  const std::vector<filament::math::float4>& ramp = build.ramp;
  const float3 colour = build.colour;
  std::string& why = build.why;
  // One of the built-in shapes, or a file. Its fill is its surface: a
  // colour, or the material glass. The material comes from the Material
  // group of the Create tab, or from a fill of glass as in older documents.
  const ModelSurface wear = model_surface(build);
  const bool glass = wear.glass, coloured = wear.coloured, own = wear.own;
  const Surface& surface = wear.surface;
  const std::string& shading = wear.shading;
  const char* model = wear.model;
  if (coloured && (rgb < 0 || ramp.size() > 1))
    why = "a solid's fill is six digits, as ff3366, or glass";
  else if (!shape.empty())
    built_in_model(build, wear);
  else if (std::filesystem::path(file).extension() == ".ply")
    point_cloud(build);
  else if (glass || own)
    file_model_with_material(build, wear);
  // Keep the file's own look unless a fill colour, a shading or a material
  // is given.
  else if ((made.solid = solid(s, file.c_str(), mat4f{}, 1.f,
                               (int)build.number("copies", 1))) &&
           (rgb >= 0 || !shading.empty()))
    solid_fill(s, made.solid,
               coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f, surface,
               model);
  // The document sets its time.
  if (made.solid) s.playing.erase(made.solid);
}

}  // namespace motolii

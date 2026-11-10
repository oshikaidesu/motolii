#ifndef MOTOLII_STAGE_RENDER_POINT_CLOUD_H_
#define MOTOLII_STAGE_RENDER_POINT_CLOUD_H_
// Loads a point cloud from a .ply file and draws it as a Filament renderable.
// The file holds either plain points (a position and a red, green and blue
// color, as a scan produces) or Gaussian splats as written by 3D Gaussian
// Splatting (f_dc color, logit opacity, log scales and a rotation quaternion).
//
// Splats are drawn the way antimatter15/splat draws them (MIT license,
// Copyright (c) 2023 Kevin Kwok):
//   - The data of every splat is stored once in a float texture: center,
//   opacity, rotation,
//     scale and color.
//   - Each splat is one square. points.mat turns it into the ellipse that the
//   splat's 3D spread
//     projects to on the screen, faded out by exp(-r^2).
//   - Splats are ordered by depth with a 16-bit counting sort on a separate
//   thread, rerun
//     whenever the camera has moved. Only the table that says which splat is in
//     which slot is uploaded again.
//   - Splats are blended from the farthest to the nearest with Filament's
//   transparent blending.
//
// A point of a plain scan is drawn round, with a size taken from the distance
// to its neighbors. The cloud is scaled to 1 tall and centered at its
// placement, as gltf_model.h does for a glTF file. The returned Mesh is only a
// handle that the renderer uses to identify the cloud.
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <math/vec3.h>

#include <memory>
#include <string>

#include "community/playcanvas/splatfx.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Loads the .ply `file` and adds it to the stage as one renderable with a
// square for each visible point. Returns a Mesh handle for the cloud, or
// nullptr with the reason in `why`. The remaining arguments are optional
// outputs and overrides:
//   - `looks` receives the material instance of the cloud.
//   - `with` is a material to use instead of points.filamat, such as one made
//   by
//     points_effect.
//   - `plainLook` receives a second instance of the plain material over the
//   same data, for
//     use once an effect has finished. It is filled only when `with` is given.
//   - `bounds` receives the lowest and highest corner of the trimmed bounding
//   box (see below)
//     in the file's units, with y up.
Mesh* points(Stage& s, const char* file, std::string& why,
             filament::MaterialInstance** looks = nullptr,
             filament::Material* with = nullptr,
             filament::MaterialInstance** plainLook = nullptr,
             filament::math::float3* bounds = nullptr);

// Builds the points material with the PlayCanvas splat effect `fx` (see
// splatfx.h) inserted into the text of points.mat, which is found in the
// materials folder next to the folder that holds this library. The material is
// built once for each distinct effect GLSL. Returns nullptr with the reason in
// `why` on failure, in which case the caller uses the plain material.
filament::Material* points_effect(Stage& s, const std::string& file,
                                  std::shared_ptr<SplatEffect>& fx,
                                  std::string& why);

}  // namespace motolii

#endif  // MOTOLII_STAGE_RENDER_POINT_CLOUD_H_

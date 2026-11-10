#ifndef MOTOLII_MOTION_LOTTIE_MOTION_H_
#define MOTOLII_MOTION_LOTTIE_MOTION_H_

// Motion of layers taken from a Lottie file, in After Effects' conventions.
//
// The Lottie file is what After Effects writes out, or any tool that writes the
// same format. ThorVG reads it and computes where each layer is at a given
// time. Keyframes, easing, paths, parents, precompositions, time remapping,
// loops and expressions are all handled by ThorVG, and nothing is recomputed
// here. The only thing taken from ThorVG is the placement of a layer found by
// its id. ThorVG draws nothing for this.
//
// Flat layers and 3D layers share one world. Every placement is a 4x4 matrix in
// the composition's own space, which follows After Effects: units are pixels, x
// points right, y points down and z points away from the viewer. ThorVG draws
// only the flat part of a 3D layer, but with deps/patches/thorvg/thorvg_z.patch
// it keeps the full numbers and exposes them through LottieAnimation::pose. The
// placement is rebuilt from those numbers in After Effects' order, checked
// against lottie-web's results in motion_test.mm:
//   placement = position * rotate x * rotate y * rotate z * skew * scale *
//   anchor offset.
// The orientation is applied before the three rotations. If the layer
// auto-orients along its path, that rotation is applied before the orientation.
// A child layer is placed under its parent.

#include <math/mat4.h>
#include <math/vec3.h>
#include <thorvg.h>
#include <thorvg_lottie.h>

#include <cstdint>

namespace motolii {

// A loaded Lottie animation. All fields are filled by motion_open().
struct Motion {
  tvg::LottieAnimation* film = nullptr;
  // The animation's picture, which holds its layers.
  tvg::Picture* image = nullptr;
  // Composition size in pixels, length in frames, and length in seconds.
  float w = 0.f, h = 0.f, frames = 0.f, seconds = 0.f;
};

// Loads the Lottie file at path `lottie` into m. Returns false if ThorVG cannot
// start, the file cannot be loaded, or the animation has no frames.
bool motion_open(Motion& m, const char* lottie);

// Sets the current time to `frame` of the composition. Fractional frames are
// allowed.
inline void motion_at(Motion& m, float frame) { m.film->frame(frame); }

// Gets the flat placement of layer `id` in composition pixels, as ThorVG
// computes it.
//
// The result is the layer's own matrix, which already includes its parents,
// combined with the matrices of the precompositions that contain it. If
// `opacity` is not null it receives the layer's opacity multiplied by those of
// the precompositions. Returns false when the layer does not exist at the
// current time, that is before its in point or after its out point.
bool motion_flat(Motion& m, uint32_t id, tvg::Matrix* place,
                 float* opacity = nullptr);

// Returns the 4x4 placement of layer `id` in the composition's space, including
// its parents.
//
// A 3D layer or camera is rebuilt from the full numbers that ThorVG exposes
// through LottieAnimation::pose. A flat layer uses ThorVG's own matrix. If
// `zoom` is not null and the layer is 3D, it receives the camera zoom.
filament::math::mat4f motion_built(Motion& m, uint32_t id,
                                   float* zoom = nullptr);

// Maps a composition placement into the scene.
//
// The composition corner (0, 0, 0) lies at `corner`, one pixel to the right is
// the vector `right`, and one pixel down is the vector `down`. One pixel away
// from the viewer is perpendicular to both. The returned matrix takes a point
// given in the layer's own axes (x right, y down, z away, in scene units) to
// its position in the scene.
filament::math::mat4f motion_in_scene(const filament::math::mat4f& place,
                                      filament::math::float3 corner,
                                      filament::math::float3 right,
                                      filament::math::float3 down);

}  // namespace motolii

#endif  // MOTOLII_MOTION_LOTTIE_MOTION_H_

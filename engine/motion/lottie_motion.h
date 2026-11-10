// Motion of layers taken from a Lottie file, in After Effects' conventions.
//
// The Lottie file is what After Effects writes out, or any tool that writes the same format.
// ThorVG reads it and computes where each layer is at a given time. Keyframes, easing, paths,
// parents, precompositions, time remapping, loops and expressions are all handled by ThorVG,
// and nothing is recomputed here. The only thing taken from ThorVG is the placement of a layer
// found by its id. ThorVG draws nothing for this.
//
// Flat layers and 3D layers share one world. Every placement is a 4x4 matrix in the
// composition's own space, which follows After Effects: units are pixels, x points right, y
// points down and z points away from the viewer. ThorVG draws only the flat part of a 3D layer,
// but with deps/patches/thorvg/thorvg_z.patch it keeps the full numbers and exposes them through
// LottieAnimation::pose. The placement is rebuilt from those numbers in After Effects' order,
// checked against lottie-web's results in motion_test.mm:
//   placement = position * rotate x * rotate y * rotate z * skew * scale * anchor offset.
// The orientation is applied before the three rotations. If the layer auto-orients along its
// path, that rotation is applied before the orientation. A child layer is placed under its
// parent.
//
// Included by kinds.h; not self-contained.
#include <math/mat4.h>
#include <math/vec3.h>
#include <thorvg.h>
#include <thorvg_lottie.h>
#include <cmath>
#include <cstdio>

// A loaded Lottie animation. All fields are filled by motion_open().
struct Motion {
    tvg::LottieAnimation* film = nullptr;
    // The animation's picture, which holds its layers.
    tvg::Picture* image = nullptr;
    // Composition size in pixels, length in frames, and length in seconds.
    float w = 0.f, h = 0.f, frames = 0.f, seconds = 0.f;
};

// Loads the Lottie file at path `lottie` into m. Returns false if ThorVG cannot start, the file
// cannot be loaded, or the animation has no frames.
static bool motion_open(Motion& m, const char* lottie) {
    // Zero threads: each time is computed on request, on the calling thread.
    static const bool started = tvg::Initializer::init(0) == tvg::Result::Success;
    if (!started) return false;
    m.film = tvg::LottieAnimation::gen();
    m.image = m.film->picture();
    if (m.image->load(lottie) != tvg::Result::Success) return false;
    m.image->size(&m.w, &m.h);
    m.frames = m.film->totalFrame();
    m.seconds = m.film->duration();
    return m.frames > 0.f;
}

// Sets the current time to `frame` of the composition. Fractional frames are allowed.
static void motion_at(Motion& m, float frame) { m.film->frame(frame); }

// Gets the flat placement of layer `id` in composition pixels, as ThorVG computes it.
//
// The result is the layer's own matrix, which already includes its parents, combined with the
// matrices of the precompositions that contain it. If `opacity` is not null it receives the
// layer's opacity multiplied by those of the precompositions. Returns false when the layer does
// not exist at the current time, that is before its in point or after its out point.
static bool motion_flat(Motion& m, uint32_t id, tvg::Matrix* place, float* opacity = nullptr) {
    // Found by walking the layers. Picture::accessible, ThorVG's lookup by name, finds nothing in
    // a Lottie file in ThorVG 1.1.2.
    const tvg::Paint* p = m.image->paint(id);
    if (!p) return false;
    tvg::Matrix all = const_cast<tvg::Paint*>(p)->transform();
    float seen = (float)p->opacity() / 255.f;
    for (const tvg::Paint* up = p->parent(); up && up->type() != tvg::Type::Picture; up = up->parent()) {
        const tvg::Matrix o = const_cast<tvg::Paint*>(up)->transform();
        all = {o.e11 * all.e11 + o.e12 * all.e21, o.e11 * all.e12 + o.e12 * all.e22, o.e11 * all.e13 + o.e12 * all.e23 + o.e13,
               o.e21 * all.e11 + o.e22 * all.e21, o.e21 * all.e12 + o.e22 * all.e22, o.e21 * all.e13 + o.e22 * all.e23 + o.e23, 0.f, 0.f, 1.f};
        seen *= (float)up->opacity() / 255.f;
    }
    *place = all;
    if (opacity) *opacity = seen;
    return true;
}


// Converts a flat 2D matrix to a 4x4 matrix in the shared 3D world. The z scale is the
// geometric mean of the x and y scales, so a cube stays a cube.
static filament::math::mat4f motion_deep(const tvg::Matrix& f) {
    using namespace filament::math;
    return mat4f(float4{f.e11, f.e21, 0.f, 0.f}, float4{f.e12, f.e22, 0.f, 0.f}, float4{0.f, 0.f, std::sqrt(std::fabs(f.e11 * f.e22 - f.e12 * f.e21)), 0.f},
                 float4{f.e13, f.e23, 0.f, 1.f});
}

// Returns the 4x4 placement of layer `id` in the composition's space, including its parents.
//
// A 3D layer or camera is rebuilt from the full numbers that ThorVG exposes through
// LottieAnimation::pose. A flat layer uses ThorVG's own matrix. If `zoom` is not null and the
// layer is 3D, it receives the camera zoom.
static filament::math::mat4f motion_built(Motion& m, uint32_t id, float* zoom = nullptr) {
    using namespace filament::math;
    float n[19] = {};
    uint32_t above = 0;
    int kind = 0;
    if (m.film->pose(id, n, &above, &kind) != tvg::Result::Success || kind == 0) {
        tvg::Matrix f{1, 0, 0, 0, 1, 0, 0, 0, 1};
        motion_flat(m, id, &f);
        return motion_deep(f);
    }
    const float deg = 3.14159265f / 180.f;
    const float3 p{n[0], n[1], n[2]}, a{n[3], n[4], n[5]}, s{n[6], n[7], n[8]}, o{n[9], n[10], n[11]}, r{n[12], n[13], n[14]};
    const float skew = n[15], axis = n[16];
    if (zoom) *zoom = n[18];
    // Auto-orient along the path: a rotation about z.
    const mat4f facing = mat4f::rotation(n[17] * deg, float3{0, 0, 1});
    const auto turns = [&](float3 by) {
        return mat4f::rotation(by.x * deg, float3{1, 0, 0}) * mat4f::rotation(by.y * deg, float3{0, 1, 0}) * mat4f::rotation(by.z * deg, float3{0, 0, 1});
    };
    // The skew: a shear along x, applied about the skew axis.
    mat4f lean;
    lean[1][0] = std::tan(-skew * deg);
    lean = mat4f::rotation(-axis * deg, float3{0, 0, 1}) * lean * mat4f::rotation(axis * deg, float3{0, 0, 1});
    mat4f own;
    if (kind == 1) own = mat4f::translation(p) * facing * turns(o) * turns(r) * lean * mat4f::scaling(s * 0.01f) * mat4f::translation(-a);
    else {
        // A camera has no scale and no anchor. A camera that looks at a point
        // is first turned to face it, with no roll.
        mat4f towards;
        if (kind == 2 && length(a - p) > 1e-4f) {
            const float3 z = normalize(a - p), x = normalize(cross(float3{0, 1, 0}, z)), y = cross(z, x);
            towards = mat4f(float4{x, 0.f}, float4{y, 0.f}, float4{z, 0.f}, float4{0.f, 0.f, 0.f, 1.f});
        }
        own = mat4f::translation(p) * towards * turns(o) * turns(r);
    }
    return above ? motion_built(m, above) * own : own;
}

// Maps a composition placement into the scene.
//
// The composition corner (0, 0, 0) lies at `corner`, one pixel to the right is the vector
// `right`, and one pixel down is the vector `down`. One pixel away from the viewer is
// perpendicular to both. The returned matrix takes a point given in the layer's own axes
// (x right, y down, z away, in scene units) to its position in the scene.
static filament::math::mat4f motion_in_scene(const filament::math::mat4f& place, filament::math::float3 corner, filament::math::float3 right, filament::math::float3 down) {
    using namespace filament::math;
    const float pixel = length(right);
    const float3 x = right / pixel, y = normalize(down), z = cross(x, y);
    return mat4f(float4{x * pixel, 0.f}, float4{y * pixel, 0.f}, float4{z * pixel, 0.f}, float4{corner, 1.f}) * place * mat4f::scaling(1.f / pixel);
}


#ifndef MOTOLII_COMMUNITY_PLAYCANVAS_SPLATFX_H_
#define MOTOLII_COMMUNITY_PLAYCANVAS_SPLATFX_H_

// Runs a PlayCanvas Gaussian splat shader effect unchanged.
//
// The effects come from playcanvas/engine, scripts/esm/gsplat (MIT), for example
// reveal-radial.mjs, reveal-rain.mjs and shader-effect-dissolve.mjs. The effect's module runs in
// QuickJS-ng. The few PlayCanvas classes it imports (Vec3, Color and the GSplatShaderEffect base
// class, which stores uniforms by name and the effect time) are small stand-ins. The effect's
// GLSL is spliced into the point cloud material (point_cloud.h, points.mat), its attributes
// become parameters, and its updateEffect is called once per evaluated time.
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "community/quickjs/script.h"

namespace utils { class JobSystem; }

// One loaded splat effect script: its GLSL, its parameters and its per-time uniforms.
class SplatEffect {
public:
    // Loads and instantiates the effect module at `file`. On failure ok() is false.
    explicit SplatEffect(const std::string& file);
    ~SplatEffect();
    // Returns true if the effect loaded and can be evaluated.
    bool ok() const;
    // Returns the error text when ok() is false, otherwise an empty string.
    const std::string& trouble() const;
    // Returns the effect's getShaderGLSL() text: its uniforms and the modifySplat functions.
    const std::string& glsl() const;
    // Returns one parameter per number attribute of the effect, and three per Vec3 or Color
    // attribute, named with the suffixes _x _y _z or _r _g _b.
    const std::vector<ScriptParameter>& parameters() const;
    // Evaluates the effect at `time` seconds from its start and returns its uniforms by name.
    // Each parameter is first set from value(name, default), then updateEffect(time, dt) is
    // called.
    std::vector<std::pair<std::string, std::vector<float>>> uniforms(double time, double dt, const std::function<double(const std::string&, double)>& value);

    // Returns true once the effect has set enabled to false in its last updateEffect. PlayCanvas
    // removes the effect's shader at that point.
    bool finished() const;
    // Sets the default of `parameter` to `is` and widens its range to include it. Used for an
    // effect's aabbMin and aabbMax, so that they match the point cloud's own bounding box and the
    // effect works as soon as it is applied.
    void usual(const std::string& parameter, double is);

private:
    struct Own;
    std::unique_ptr<Own> own;
};

// Builds the point cloud material from `mat` (the text of points.mat) with an effect's GLSL
// spliced in, the same way matc builds it, using Filament's matp and filamat for WebGPU and
// Metal. The effect's uniforms become material parameters. Returns the material package bytes.
// A package is built once and cached in ~/Library/Caches/Motolii/splatfx, in a file named by a
// hash of `mat` and `glsl`. `jobs` is the job system of the Filament engine. On failure returns
// an empty vector and sets `why`.
std::vector<uint8_t> splat_effect_look(const std::string& mat, const std::string& glsl, utils::JobSystem& jobs, std::string& why);

#endif  // MOTOLII_COMMUNITY_PLAYCANVAS_SPLATFX_H_

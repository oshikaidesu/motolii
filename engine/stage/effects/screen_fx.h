#ifndef MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_
#define MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_
// Whole-screen WGSL effects. Parameters are declared in leading comment lines
// (see script.h). Built-in struct members: time, frame, aspect, resolution,
// width, height. Stage draws into a texture, effects chain through it via
// Filament's driver (gpu/screen_interop.h).
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "gpu/screen_interop.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Returns a parameter's current value. The file is part of the key because
// two effects may share a parameter name.
using ScreenNumbers = std::function<double(
    const std::string& file, const std::string& parameter, double usual)>;
// Returns another layer's image that an effect reads as an input.
using ScreenTextures = std::function<filament::Texture*(
    const std::string& file, const std::string& name)>;

// One loaded effect: source, parameters, uniform layout, GPU objects, per-frame
// state. `trouble` is the last error text, empty when none.
struct ScreenFx {
  std::string file, instance_id, trouble;
  // With an instance ID, keys as "id:file" so parameters are per-instance.
  std::string numbers_key() const {
    return instance_id.empty() ? file : instance_id + ":" + file;
  }
  std::vector<ScriptParameter> parameters;
  // A uniform struct member. whole = i32 or u32, stored as integer.
  struct Field {
    std::string name;
    uint32_t at = 0, floats = 1;
    bool whole = false;
  };
  std::vector<Field> fields;
  uint32_t bytes = 0;
  interop::Screen* interop = nullptr;
  // Image count: stage image + one per ISF pass target.
  int textureCount = 1;
  // `// --spill`: effect adds light beyond the layer's shape (rays, trails).
  bool spill = false;
  // `// --alpha`: the effect's own alpha replaces the layer's shape.
  bool alpha = false;
  // ISF pass targets. Double-buffered; persistent ones keep their image across
  // frames. `fine` = 16-bit float. Size is either a share of stage or fixed
  // points.
  struct Target {
    std::string name;
    bool persistent = false, fine = false;
    double share[2] = {1, 1};
    int points[2] = {0, 0};
    filament::Texture* textures[2] = {nullptr, nullptr};
    filament::RenderTarget* into[2] = {nullptr, nullptr};
    int front = 0;
    uint32_t w = 0, h = 0;
  };
  std::vector<Target> targets;
  // -1 = output.
  std::vector<int> passes;
  // `// --history@frames:share`. texture_2d_array; newest at `head`.
  // Bitmask of textures that are the history array.
  unsigned layered = 0;
  int historyFrames = 0, head = -1;
  // Share of stage size for kept frames.
  double historyShare = 1;
  filament::Texture* history = nullptr;
  std::vector<filament::RenderTarget*> historyInto;
  // `// --picture@name` inputs. Read last, after targets and history.
  std::vector<std::string> others;
  // nullptr = effect's own input.
  std::vector<filament::Texture*> othersNow;
  std::vector<bool> othersOwn;
  // `// --image@name:file` (ISF IMPORTED). Empty = not an image file.
  std::vector<std::string> images;
  std::vector<filament::Texture*> imagesBuilt;
  // ISF generator.
  bool source = false;
  // {left, top, width, height} as shares. `pass` for a fixed-size target
  // covers its whole side.
  double frame[4] = {0, 0, 1, 1}, pass[4] = {0, 0, 1, 1};
  // `// --sound@name`. Half-float row of `wide` values. `fft` = spectrum.
  struct Sound {
    bool is = false, fft = false;
    int wide = 0;
    filament::Texture* texture = nullptr;
  };
  std::vector<Sound> sounds;
  uint32_t hw = 0, hh = 0;
  // Rebuilt when the file's mtime changes.
  std::filesystem::file_time_type stamp{};
  int seen = -1;
};
// Returns the effect file's last write time, or the minimum when unreadable.
std::filesystem::file_time_type screen_stamp(const std::string& file);

// Reads and compiles the effect. Image k at binding 2k, sampler at 2k+1,
// params after. Returns false and sets fx.trouble on failure.
bool screen_read(ScreenFx& fx, std::string& code);

// The effect chain on the stage or a layer. Effects chain through two
// alternating intermediate images. Unbuildable effects are skipped (stderr).
struct ScreenStack {
  std::string files;
  std::vector<ScreenFx*> fx;
  // True if an effect reads the image behind the layer.
  bool readsBehind = false;
  // True if an effect draws to the full stage (e.g. AviUtl2 obj.draw).
  bool wide = false;
  double thingSeen[4] = {0, 0, 0, 0};
  // The layer's own rectangle on the image; a generator measures by this.
  double own[4] = {0, 0, 1, 1};
  // The share of the image that effects measure by (layer vs full image).
  double frame[4] = {0, 0, 1, 1};
  double box[4] = {0, 0, 0, 0};
  int ground = -1;
  // Kept because shader compilation can take several frames.
  std::map<std::string, ScreenFx*> built;
  filament::Texture* shot = nullptr;
  filament::Texture* depth = nullptr;
  // A transition's end image when none is chosen: transparent.
  filament::Texture* clear = nullptr;
  filament::RenderTarget* target = nullptr;
  filament::Texture* between[2] = {nullptr, nullptr};
  filament::RenderTarget* betweenTarget[2] = {nullptr, nullptr};
  // Passthrough copy for effects whose last pass draws into their own target.
  interop::Screen* copy = nullptr;
  // Steps in order: 0 = next GPU effect, 'a' = AviUtl2 script,
  // 'p' = After Effects plugin.
  std::vector<char> steps;
  std::vector<std::shared_ptr<struct AviutlRun>> aviutl;
  std::vector<std::shared_ptr<struct AePluginRun>> aePlugins;
  void* device[3] = {nullptr, nullptr, nullptr};
  filament::Texture* seen = nullptr;
  // Audio input values at the current time. Empty/null = silent.
  std::function<std::vector<float>(const std::string& file,
                                   const std::string& name, bool fft, int wide)>
      sounds;
};
filament::Texture* screen_texture(Stage& s);
// The frame rate effects see: the document's frame_rate, or 60 when none.
inline double screen_rate(const Stage& s) {
  return s.frames > 0.0 ? s.frames : 60.0;
}
// Copies `from` to `to` at rectangle `at`, clearing the rest.
void screen_place(Stage& s, filament::Texture* from, filament::RenderTarget* to,
                  uint32_t w, uint32_t h, const int* at);
// Converts between linear light and sRGB (IEC 61966-2-1). Layer images are in
// linear (post-processing off); effects expect sRGB. Unpremultiplies, converts,
// premultiplies.
void screen_tone(Stage& s, filament::Texture* from, filament::RenderTarget* to,
                 uint32_t w, uint32_t h, bool toSrgb);
// Upscales `from` into `to` (w x h) using AMD FidelityFX FSR 1.0 (EASU + RCAS,
// MIT). Falls back to screen_place when `from` is already at target size.
void screen_upscale(Stage& s, filament::Texture* from,
                    filament::RenderTarget* to, uint32_t w, uint32_t h,
                    float sharpness = 0.2f);
// Draws one effect through its passes. w,h default to stage size. over: blend
// the last pass over `to` instead of replacing it.
void screen_draw(Stage& s, ScreenStack& st, ScreenFx& fx,
                 filament::Texture* from, filament::RenderTarget* to,
                 const ScreenNumbers& numbers, uint32_t w = 0, uint32_t h = 0,
                 bool over = false);
// Hot-reloads an effect from its file. Previous version stays on failure.
void screen_fresh(Stage& s, ScreenFx& fx);
// True if any effect file changed since it was built (wakes a sleeping stage).
bool screen_moved(const ScreenStack& st);
// Returns the built effect for `file`, building on first access. Failed files
// are remembered (null interop) so they are not retried.
ScreenFx* screen_built(Stage& s, ScreenStack& st, const std::string& file);
// Sets the stack to `files` (space-separated). No-op if unchanged.
void screen_effects(Stage& s, ScreenStack& st, const std::string& files,
                    ScreenNumbers numbers);

// Builds input textures for the current frame (images once, audio each frame).
void screen_sounds(Stage& s, ScreenStack& st, ScreenFx& fx);
// Fills and uploads the parameter uniform for one pass. pw/ph = 0 → stage size.
void screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers,
                       int pass = 0, double pw = 0, double ph = 0);
// Creates or destroys target textures. drop = destroy only. pw/ph = 0 → stage.
void screen_targets(Stage& s, ScreenFx& fx, bool drop = false, uint32_t pw = 0,
                    uint32_t ph = 0);

}  // namespace motolii

#endif  // MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_

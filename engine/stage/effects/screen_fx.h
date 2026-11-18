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
  // Where the layer itself is seen, in stage points: left, top, right, bottom.
  double thingSeen[4] = {0, 0, 0, 0};
  // Where the layer itself lies, in the form of `frame`. A generator paints
  // only there, so this is what it measures by, like the width and height of
  double own[4] = {0, 0, 1, 1};
  // For a layer: the rectangle (left, top, width, height, each a share of the
  // image) that its effects measure by, inside the larger image they draw on.
  // This is After Effects' width and height as against its buffer (PF_InData).
  double frame[4] = {0, 0, 1, 1};
  // For a layer: where it is seen, in stage points (see thing_fx_aim in
  // layer_fx.h).
  double box[4] = {0, 0, 0, 0};
  // The stage's background color as 0xRRGGBB, or -1 for none.
  int ground = -1;
  // Every effect built so far, by file. They are kept because building a shader
  // can take as long as drawing several frames.
  std::map<std::string, ScreenFx*> built;
  // The stage's image, drawn to a texture instead of the screen.
  filament::Texture* shot = nullptr;
  filament::Texture* depth = nullptr;
  // A transition's end image when none is chosen: nothing, as the Transition
  // effects of After Effects (Linear Wipe, Radial Wipe) reveal. Made once and
  // kept.
  filament::Texture* clear = nullptr;
  // The render target that draws into `shot` and `depth`.
  filament::RenderTarget* target = nullptr;
  // Two intermediate images, used in turn between effects.
  filament::Texture* between[2] = {nullptr, nullptr};
  filament::RenderTarget* betweenTarget[2] = {nullptr, nullptr};
  // Draws an image unchanged, for an effect whose last pass draws into its own
  // target.
  interop::Screen* copy = nullptr;
  // A layer's effects as steps in order
  // thing_effects_draw in layer_fx.h). A step of 0 is the next entry of `fx`,
  // drawn by Filament; 'a' is an AviUtl2 script.
  std::vector<char> steps;
  // The AviUtl2 scripts to run in order, for step 'a' (see
  // community/aviutl/aviutl_fx.h).
  std::vector<std::shared_ptr<struct AviutlRun>> aviutl;
  // The native WGPUTexture handles of shot, between[0] and between[1].
  void* device[3] = {nullptr, nullptr, nullptr};
  // The layer's image as the camera sees it, with its effects applied, for the
  // current frame.
  filament::Texture* seen = nullptr;
  // Returns the values of an audio input at the current time, given the
  // effect's file, the input's name, whether the spectrum (fft) or the waveform
  // is wanted, and how many values (0 means as many as are read). If the
  // function is empty or returns nothing, the input is silent.
  std::function<std::vector<float>(const std::string& file,
                                   const std::string& name, bool fft, int wide)>
      sounds;
};
// Creates a stage-sized RGBA8 texture that can be drawn into and sampled.
filament::Texture* screen_texture(Stage& s);
// Returns the frame rate an effect is told (ISF's FRAMEINDEX and TIMEDELTA,
// Shadertoy's iFrameRate, AviUtl's obj.framerate). It is the document's frame
// rate, at which its time is sampled (see time_is); when none is set, the 60
// per second the stage draws at.
inline double screen_rate(const Stage& s) {
  return s.frames > 0.0 ? s.frames : 60.0;
}
// Copies image `from` to `to` at the rectangle `at` (left, bottom, width,
// height) as it is, and leaves the rest of `to` clear. Used by the app's stage
// to draw its whole-screen effects as an exported video has them (see
// stage/live.h). One copy effect is created per engine and reused.
void screen_place(Stage& s, filament::Texture* from, filament::RenderTarget* to,
                  uint32_t w, uint32_t h, const int* at);
// Converts an image's colors from linear light to sRGB, or from sRGB to linear
// when `toSrgb` is false, using the transfer function of IEC 61966-2-1. The
// colors are unpremultiplied for the conversion and premultiplied again. A
// layer's own image is drawn in linear light (its view's post-processing is
// off, see layer_fx.h), while the effects laid on it are written for sRGB, as
// their original hosts provide them (Skia for AbsentMotion, ISF, ThorVG,
// AviUtl2). The stage's own whole-screen effects are drawn after its
// post-processing, so they are in sRGB already.
void screen_tone(Stage& s, filament::Texture* from, filament::RenderTarget* to,
                 uint32_t w, uint32_t h, bool toSrgb);
// Draws one effect: reads `from` (the stage's image or the output of the effect
// before) and draws to `to` through the effect's passes. The images the shader
// reads are, in order, `from`, then each target (ISF) or the array of past
// frames, then the other inputs. w, h: the size of the image drawn into; the
// stage's size by default, or a layer's own image size. over: lay the last pass
// over what `to` already holds, as a layer's effects are laid over what is
// under the layer, instead of replacing it.
void screen_draw(Stage& s, ScreenStack& st, ScreenFx& fx,
                 filament::Texture* from, filament::RenderTarget* to,
                 const ScreenNumbers& numbers, uint32_t w = 0, uint32_t h = 0,
                 bool over = false);
// Rebuilds an effect in place when its file has been written over, so that a
// saved shader shows at once. It is checked only when the window reports that a
// file changed. If the new file cannot be read or built, the previous version
// stays and the reason is printed to stderr.
void screen_fresh(Stage& s, ScreenFx& fx);
// Returns true if any effect file of the stack has been written over since the
// effect was built. This is what wakes a stage that is not drawing.
bool screen_moved(const ScreenStack& st);
// Returns the effect of `file` in the stack, read and built the first time it
// is asked for. A file that cannot be read or built is remembered with a null
// interop and the reason in trouble (printed to stderr once), so it is not read
// again each time.
ScreenFx* screen_built(Stage& s, ScreenStack& st, const std::string& file);
// Sets the stack's effects to `files` (paths separated by spaces), building
// those that are not built yet, and routes the stage's drawing through them.
// Does nothing if `files` is unchanged.
void screen_effects(Stage& s, ScreenStack& st, const std::string& files,
                    ScreenNumbers numbers);

// The parts of an effect that its passes read and write, set up for
// screen_fx.cpp (defined in screen_resources.cpp).
// Builds the input textures of an effect for the current frame: image files
// once, audio inputs again each frame.
void screen_sounds(Stage& s, ScreenStack& st, ScreenFx& fx);
// Fills the parameter uniform struct of `fx` for one pass and uploads it.
// `pass` is the pass index. pw and ph give the size of the image drawn into in
// pixels, or 0 for the stage size.
void screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers,
                       int pass = 0, double pw = 0, double ph = 0);
// Makes or drops the textures of the effect's targets. If `drop` is true the
// textures are destroyed and not recreated. pw and ph give the size of the
// image drawn into, or 0 for the stage size.
void screen_targets(Stage& s, ScreenFx& fx, bool drop = false, uint32_t pw = 0,
                    uint32_t ph = 0);

}  // namespace motolii

#endif  // MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_

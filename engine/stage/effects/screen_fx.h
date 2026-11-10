#ifndef MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_
#define MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_
// Whole-screen effects on the stage. An effect is one WGSL file in the vgpu
// style: a fragment shader only, with the entry point `fn
// fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) ->
// @location(0) vec4f`, the input image as a `texture_2d<f32>`, a `sampler`, and
// the parameters in one `var<uniform>` struct. The parameters are declared in
// the leading comment lines of the file, as a script's are (see script.h, for
// example "// --track@name:...").
//
// The stage draws its image into a texture of its own instead of the screen,
// and the effect draws that texture to the screen through Filament's driver
// (see gpu/screen_interop.h), in order with the stage's other images.
//
// A struct member that the leading comments do not declare is filled in by the
// stage when it has one of these names: `time` (seconds), `frame` (frame number
// at 60 per second), `aspect` (width over height), `resolution`, `width` and
// `height` (points). Any other member is read as a parameter of the same name.
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

// Returns the current value of a parameter, given the effect's file, the
// parameter's name, and its default value. The file is part of the key because
// two effects may each have a parameter of the same name.
using ScreenNumbers = std::function<double(
    const std::string& file, const std::string& parameter, double usual)>;
// Returns the image of another layer that an effect reads as one of its inputs,
// given the effect's file and the name of the parameter that selects the layer.
using ScreenTextures = std::function<filament::Texture*(
    const std::string& file, const std::string& name)>;

// One whole-screen effect that has been loaded: its source file, parameters,
// uniform layout, GPU objects and per-frame state. `trouble` holds the text of
// the last error, empty when none.
struct ScreenFx {
  std::string file, trouble;
  std::vector<ScriptParameter> parameters;
  // A member of the parameter struct: its name, byte offset, number of floats,
  // and whether it is an integer type (i32 or u32) and so is stored as an
  // integer.
  struct Field {
    std::string name;
    uint32_t at = 0, floats = 1;
    bool whole = false;
  };
  // The members of the parameter struct, laid out as WGSL lays out a uniform.
  std::vector<Field> fields;
  // Size of the parameter struct in bytes.
  uint32_t bytes = 0;
  // The effect as compiled in Filament's driver.
  interop::Screen* interop = nullptr;
  // Number of images the shader reads: the stage's image, then one per target
  // (ISF passes).
  int textureCount = 1;
  // Set by the leading comment `// --spill`. On a layer, the effect adds light
  // laid over what is under it, in places where the layer is not (rays, trails,
  // a shifted copy).
  bool spill = false;
  // Set by the leading comment `// --alpha`. On a layer, the transparency the
  // effect itself produces (for example grains) is what is laid down, not the
  // layer's shape.
  bool alpha = false;
  // ISF passes are drawn in turn (see the parameter `pass`). Each pass draws
  // into a target owned by the effect or, for the last pass, to the output.
  //
  // A target is double-buffered: one texture is read while the other is drawn
  // into, then they swap. A persistent target keeps its last image, which is
  // read on the next frame. A `fine` target uses a 16-bit float format. The
  // size is either a fraction of the stage size (share) or a fixed number of
  // points. `front` is the texture that is read; w and h are its size in
  // pixels.
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
  // The target index of each pass; -1 means the pass draws to the output.
  std::vector<int> passes;
  // Past frames of the stage, when the leading comments ask for them with
  // `// --history@frames:share`. They are an array of layers read as a
  // `texture_2d_array<f32>`. The newest frame is at layer `head`, which the
  // shader sees as the parameter `history_head`, and `history_count` frames are
  // kept. Bit mask of the textures the shader reads that are the history array.
  unsigned layered = 0;
  // Number of kept frames, and the layer of the newest one (-1 before the first
  // is drawn).
  int historyFrames = 0, head = -1;
  // Share of the stage size at which past frames are kept.
  double historyShare = 1;
  filament::Texture* history = nullptr;
  std::vector<filament::RenderTarget*> historyInto;
  // Other input images (`// --picture@name`, ISF's images after the first).
  // Each is the image of another layer as the camera sees it, chosen on the
  // effect's card. They are read last, after the pass targets and the past
  // frames.
  std::vector<std::string> others;
  // The texture each input uses this frame, set before drawing; none means the
  // effect's own input.
  std::vector<filament::Texture*> othersNow;
  // Whether each input is the effect's own input image this frame.
  std::vector<bool> othersOwn;
  // The inputs that are image files next to the effect (`// --image@name:file`,
  // ISF's IMPORTED): the path of each, empty for the others.
  std::vector<std::string> images;
  // The textures loaded from `images`.
  std::vector<filament::Texture*> imagesBuilt;
  // True for an ISF generator (see isf_tags).
  bool source = false;
  // Rectangles as {left, top, width, height}, each a share of the image.
  // `frame` is the layer's frame on the image (see ScreenStack). `pass` is the
  // same on the image the current pass draws into; a pass of a fixed size
  // covers the whole of that side.
  double frame[4] = {0, 0, 1, 1}, pass[4] = {0, 0, 1, 1};
  // Audio inputs (`// --sound@name`, ISF's audio and audioFFT), placed among
  // the other inputs. Each is the sound of another layer at the current time, a
  // row of `wide` values (the ISF spec uses one image row per channel). The
  // values are half floats, since the spec asks for high-precision 32- or
  // 16-bit float textures; WebGPU filters a 16-bit one as it is. `is` tells
  // whether the input is audio at all, and `fft` whether it is the spectrum
  // rather than the waveform.
  struct Sound {
    bool is = false, fft = false;
    int wide = 0;
    filament::Texture* texture = nullptr;
  };
  std::vector<Sound> sounds;
  // Size in pixels of the history texture.
  uint32_t hw = 0, hh = 0;
  // Modification time of the file when the effect was built; if it changes, the
  // effect is rebuilt.
  std::filesystem::file_time_type stamp{};
  // The value of files_changed() when the file was last checked.
  int seen = -1;
};
// Returns the last write time of the effect's file, or the minimum time when it
// cannot be read.
std::filesystem::file_time_type screen_stamp(const std::string& file);

// Reads the effect's file into `code` in the form Filament's driver takes, and
// fills in `fx`. Image k is bound at 2k and its sampler at 2k+1, and the
// parameters follow at 2 times the number of images; the entry point is renamed
// `main`. `fx` also receives the layout of the parameter struct, the passes and
// targets, the other inputs and the history request. Returns false and sets
// fx.trouble when the file cannot be used.
bool screen_read(ScreenFx& fx, std::string& code);

// The whole-screen effects applied to the stage or to one layer, one over
// another. `files` is a list of effect file paths separated by spaces, or "" or
// "none" for no effects. The first effect reads the stage's image, each next
// one reads the output of the one before, and the last draws on the screen; two
// intermediate images are used in turn. An effect that cannot be built is left
// out and the reason is printed to stderr.
struct ScreenStack {
  std::string files;
  std::vector<ScreenFx*> fx;
  // True if one of the effects reads what is behind the layer: AbsentMotion's
  // backdrop, or the stage's image behind it.
  bool readsBehind = false;
  // True if one of the effects draws the layer anywhere on the screen, such as
  // an AviUtl2 script calling obj.draw; its box is then the whole stage.
  bool wide = false;
  // Where the layer itself is seen, in stage points: left, top, right, bottom.
  double thingSeen[4] = {0, 0, 0, 0};
  // Where the layer itself lies, in the form of `frame`. A generator paints
  // only there, so this is what it measures by, like the width and height of
  // After Effects' PF_InData.
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
  // A layer's effects as steps in order, like After Effects' effect stack (see
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
// Fills the parameter uniform struct of `fx` for one pass and uploads it. `pass`
// is the pass index. pw and ph give the size of the image drawn into in pixels,
// or 0 for the stage size.
void screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers,
                       int pass = 0, double pw = 0, double ph = 0);
// Makes or drops the textures of the effect's targets. If `drop` is true the
// textures are destroyed and not recreated. pw and ph give the size of the image
// drawn into, or 0 for the stage size.
void screen_targets(Stage& s, ScreenFx& fx, bool drop = false, uint32_t pw = 0,
                    uint32_t ph = 0);

}  // namespace motolii

#endif  // MOTOLII_STAGE_EFFECTS_SCREEN_FX_H_

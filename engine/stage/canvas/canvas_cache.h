#ifndef MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_

// Per-layer ThorVG canvas state and the GPU/disk frame cache.

#include <filament/MaterialInstance.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <thorvg.h>
#include <thorvg_lottie.h>
#include <webgpu/webgpu.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "stage/canvas/path_operations.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Drawing options of a flat layer drawn by ThorVG. Lengths are fractions of the
// layer height unless noted; see over().
struct Canvas2DFx {
  bool split = false;  // each letter as a separate copy
  bool splitWords = false;
  bool splitLines = false;
  // Draws all copies in one instanced draw, so no copy gets its own color or
  // clear. See add_parts in render.h.
  bool together = false;
  // The layer has depth: the sheet becomes a box and the image is pushed
  // through it. See deep.glsl.
  bool thick = false;
  // The layer is lit by the scene's lights. See flat_lit in flat.mat and
  // doc_lit.
  bool lit = false;
  // Name of the material applied to the layer, with the image as its color.
  // Selects flat_<wear> in flat.mat. See doc_sheet_material. Empty means none.
  std::string wear;
  // Cuts the edges of the box as the project says. See deep.glsl and
  // canvas_edge.h.
  bool bevel = false;
  // Extra outlines, each outside the previous one.
  struct Rim {
    filament::math::float4 color;  // rgb + width fraction of layer height
    std::vector<filament::math::float4> ramp;
    std::vector<float> rampAt;
    int cap = -1, join = -1,
        align = 0;  // align: -1 inside, 0 center, 1 outside
    // dash is the length of each dash; gap is the gap between them. When gap
    // is 0 it equals dash, so a dash set alone draws evenly spaced dashes.
    float dash = 0.f, gap = 0.f, dashFrom = 0.f;
  };
  std::vector<Rim> rims;
  // Primary stroke alignment (-1 inside, 0 center, 1 outside) and optional
  // gradient ramp.
  int edgeAlign = 0;
  std::vector<filament::math::float4> edgeRamp;
  std::vector<float> edgeRampAt;
  // Stacks the letters vertically, one letter height apart.
  bool column = false;
  // letters: thousandths of an em (css-inline-3). lines: CSS line-height.
  // italic: CSS oblique angle in degrees. wrapWidth: letter heights (0 = no
  // wrap).
  float letters = 0.f, lines = 1.2f, italic = 0.f, wrapWidth = 0.f;
  int wrap = 0;
  // ThorVG stroke options. -1 for cap/join = ThorVG default. gap 0 = same as
  // dash.
  float dash = 0.f, gap = 0.f, dashFrom = 0.f;
  int cap = -1, join = -1;
  // heads: 1 end, 2 start, 3 both. headShape: 0 arrow, 1 circle, 2 box,
  // 3 chevron, 4 bar; 5+ see canvas_flat.h. headStart: -1 = same as headShape.
  int heads = 0;
  float headSize = 4.f;
  int headShape = 0, headStart = -1;
  float overHigh = 1.f;
  int copies = 1;
  // Two or more colors. The shape is filled with ThorVG's linear gradient from
  // the first color at the top to the last at the bottom.
  std::vector<filament::math::float4> ramp;
  // Position of each ramp color as a fraction of the way along the gradient,
  // like CSS color stop positions and SVG stop offsets. Empty means evenly
  // spaced.
  std::vector<float> rampAt;
  // How colors are mixed between stops: 0 sRGB, 1 OKLab, 2 around the hue, 3
  // not at all. See ramp_of.
  int rampBlend = 0;
  // A flat shape filled with nothing, so only its edge is visible.
  bool hollow = false;
  // File of an image that fills a flat shape instead of its color.
  std::string media;
  // Where outlines overlap, leaves a hole every other time, like SVG's
  // fill-rule evenodd. Otherwise the fill rule is nonzero.
  bool evenOdd = false;
  // Max path-operator values over the animation. The image is enlarged to hold
  // the bent outline so it is never cut by the box. 0 = plain size.
  float round = 0.f, bloat = 0.f, zigzag = 0.f;
  float ridges = 5.f, smooth = 0.f, offset = 0.f;
  // radial selects ThorVG's radial gradient, from the middle outward, instead
  // of a linear one. rampAngle is the rotation, clockwise. rampScale is the
  // length as a fraction of reach. spread is how the gradient continues past
  // its ends: padded, reflected or repeated.
  bool radial = false;
  float rampAngle = 0.f, rampScale = 1.f;
  int spread = 0;
  // Returns a copy for a layer `high` units tall.
  Canvas2DFx over(float high) const {
    Canvas2DFx f = *this;
    f.overHigh = high;
    return f;
  }
};

struct Canvas2D {
  // Driver thread only.
  tvg::WgCanvas* canvas = nullptr;
  // The texture the canvas draws into. A cached frame is copied from it.
  WGPUTexture target = nullptr;
  // Per-layer GPU frame cache. cache_drop discards when the layer changes.
  // `cached`: keyed by frame, main thread. `keeping`: driver→main handoff.
  std::map<int, filament::Texture*> cached;
  // The WebGPU texture behind each cached frame. They are released when the
  // frames are discarded, after Filament has finished with them.
  std::vector<WGPUTexture> cachedTextures;
  // Guards `keeping`.
  std::mutex keepingLock;
  std::vector<std::pair<int, WGPUTexture>> keeping;
  // The frame currently shown, or -1.
  int shownAt = -1;
  // The frame that `target` holds. Driver thread only.
  int targetAt = -1;
  // Frames that are being written to disk only, while the user is idle. See
  // frames_ahead. Main thread.
  std::set<int> ahead;
  // Disk cache key base. Empty = no disk caching.
  std::string keyBase;
  // Lottie slot overrides as last set. See lottie_slots.h.
  std::string slots;
  // For a MIDI roll: how lit each note is, as last set. See midi_roll.cpp.
  std::vector<float> lit;
  // For a MIDI roll: the transform of each note, as last set.
  std::vector<tvg::Matrix> moves;
  // ThorVG's id of the applied slots. Driver thread only.
  uint32_t slotsId = 0;
  // Incremented each time the cached frames are discarded. A copy made before
  // that is not cached.
  std::atomic<int> keepAge{0};
  // The animation. Driver thread only.
  tvg::Animation* film = nullptr;
  // Redraws each frame (e.g. CSS-animated SVG, see image_canvas). Driver
  // thread.
  std::function<void(int)> redraw;
  // 2D sketch frame producer (see canvas_sketch.h). Main thread.
  std::function<std::vector<double>(int, int)> sketch;
  // Sketch line activation (see sketch_marked in script.h). Main thread.
  std::shared_ptr<std::map<int, double>> sketchLines;
  // The frame last requested from `sketch`, which the canvas will hold. Main
  // thread.
  int sketchAt = -1;
  // The ThorVG scene the sketch's paints are added to. Driver thread only.
  tvg::Scene* sketchScene = nullptr;
  // ThorVG's name of the font the sketch's text is set in.
  std::string sketchFont;
  // Sketch images by id (__bitmaps in p5_stand.h). Requested on main, read on
  // driver.
  std::map<int, std::shared_ptr<std::vector<uint8_t>>> sketchPics;
  // Guards `sketchPics`.
  std::mutex sketchPicsLock;
  // The texture Filament samples.
  filament::Texture* texture = nullptr;
  // Edge distance field for bevel (canvas_edge.h).
  filament::Texture* edge[3] = {};
  filament::RenderTarget* edgeInto[3] = {};
  uint32_t edgeW = 0, edgeH = 0;
  // Stroke end positions for Step bevel stairs (deep.glsl).
  filament::math::float4 bands{0.f};
  // flat_lit: surface lighting updated every frame (evaluate.h).
  bool inLight = false;
  // How far the edge distances are known, in points.
  int edgeReach = 0;
  // Set when the canvas was redrawn since edge distances were computed.
  std::atomic<bool> stale{true};
  // The layer's scene mesh (see move in render.h).
  Mesh* sheet = nullptr;
  // Half-extents when the layer has depth.
  filament::math::float3 boxed{0.f};
  // True when the box is open.
  bool open = false;
  // The layer's material instance. Null if the layer is not shown.
  filament::MaterialInstance* look = nullptr;
  // Length of the animation in seconds and in frames. 0 for a still image.
  float seconds = 0.f, frames = 0.f;
  // How far into the animation it is when the stage time is 0.
  float starts = 0.f;
  // A flat shape's own path. Driver thread only.
  tvg::Shape* shape = nullptr;
  // Text outline over colour sheet, trimmed with `shape`. Driver thread.
  tvg::Shape* letterEdge = nullptr;
  // As last trimmed: how much was cut off the end, off the beginning, and the
  // offset along the path.
  filament::math::float3 trimmed{0.f};
  // The path as made, before it is bent. See bend_at.
  std::vector<tvg::PathCommand> plain;
  std::vector<tvg::Point> plainAt;
  // The height the path was drawn at and its shorter side, in the layer's own
  // points.
  float plainHigh = 0.f, plainSide = 0.f;
  // Image size in texture pixels, including room for effects.
  float canvasHigh = 0.f, canvasWide = 0.f;
  // Bent outline bounds in sheet UV (0..1). The selection box tracks this, not
  // the padded quad. May exceed 0..1 on overflow (canvas_measure_bent).
  filament::math::float4 bentBox{0.f, 0.f, 1.f, 1.f};
  bool bentSeen = false;
  // Lines are cut into pieces no longer than this many points.
  float fine = 0.f;
  // Flat shape drawn as triangles (flat_mesh), no canvas. Bending in material.
  bool cut = false;
  // Layer color overlaid on its material.
  filament::math::float4 wash{0.f};
  // Width divided by height. Bends are counted across this width.
  float wideBy = 1.f;
  // ThorVG path, CPU only (not drawn).
  tvg::Shape* outline = nullptr;
  // Width of the path in points, height of the sheet on the stage, and width of
  // the edge in points.
  float cutW = 0.f, sheetHigh = 1.f, edgeWide = 0.f;
  bool hollow = false;
  // Where the fill's points and triangles end in the sheet. The edge comes
  // after them.
  uint32_t fillPoints = 0, fillEnd = 0;
  // The edge's own material instance, for the second part of the triangles.
  filament::MaterialInstance* edgeLook = nullptr;
  // One layer of a Lottie file, drawn alone (layer_canvas).
  tvg::Animation* source = nullptr;
  uint32_t layerId = 0;
  tvg::Scene* holder = nullptr;
  tvg::Matrix fit{1, 0, 0, 0, 1, 0, 0, 0, 1};
  // The Lottie animation, used to read layer poses.
  tvg::LottieAnimation* lottie = nullptr;
  // 3D layer ids from a Lottie file; each gets its own sheet (canvas_deep).
  std::vector<uint32_t> deep;
  // Parameters as last applied by bend_at: round, bloat, zigzag, ridges,
  // smooth, offset. The remaining four are for roughening: how far and how
  // fine, the number of points walked again, and the square size.
  std::array<float, 10> bent{};
  // Ordered path-operator stack as last applied (supports reorder & repeats).
  std::vector<PathOpStep> bentSteps;
  // True when the last applied operator produced pure voxel squares.
  bool bentVoxel = false;
  // Another shape's path: combined (how: skia_path_operations.cpp op, -1 none)
  // or morphed (much: 0–1; how>1: that many blend steps).
  struct Other {
    int how = -1;
    float much = 0.f;
    std::vector<tvg::PathCommand> by;
    std::vector<tvg::Point> at;
    bool operator==(const Other& o) const {
      return how == o.how && much == o.much && by == o.by &&
             at.size() == o.at.size() &&
             std::equal(at.begin(), at.end(), o.at.begin(),
                        [](tvg::Point a, tvg::Point b) {
                          return a.x == b.x && a.y == b.y;
                        });
    }
  } joined, morphed,
      traced;  // (as last put together with, as last turned into, as last
               // tracing: its whole path another's track)
  // Triangulated path cache. A frame cut once is reused. Total capped at
  // cuts_most.
  struct Cut {
    std::vector<tvg::PathCommand> by;
    std::vector<tvg::Point> at;
    std::vector<filament::math::float3> pos;
    std::vector<filament::math::float2> uv;
    std::vector<uint32_t> idx, ends;
    uint32_t fillPoints = 0, fillEnd = 0;
    size_t bytes = 0;
  };
  struct Cuts {
    std::unordered_map<uint64_t, Cut> all;
    std::deque<uint64_t> order;
    size_t bytes = 0;
    ~Cuts();
  } cuts;
  // ThorVG Lottie markers (named sections).
  std::vector<std::string> markers;
  // Per-letter or per-line position as fraction of image width (or height if
  // lettersDown). Each copy shows one letter/line.
  std::vector<filament::math::float2> letters;
  bool lettersDown = false;
  // For a text split into lines: how far one line's base lies below the one
  // before, as a fraction of the image's height.
  float linePitch = 0.f;
  // Per-letter/line bounding box (x, width) as fractions of image width.
  std::vector<filament::math::float2> boxes;
  // The section that plays when one is named, in frames of the file.
  float fromFrame = 0.f, toFrame = 0.f;
  // Text height as a multiple of one line.
  float tallBy = 1.f;
  // em: letter size as fraction of image height. line: ascent..descent as
  // fractions of image height (CSS 2.1 §10.6.1 content area).
  float em = 0.f;
  filament::math::float2 line{0.f, 1.f};
  // The drawing options the layer was made with.
  Canvas2DFx fx;
  // Sets replacement words into `shape` (driver thread, via words_at).
  // Empty when split/wrapped/aligned or has text_styles.
  std::function<void(const std::string&)> retype;
  // As last set.
  std::string words;
  // Font file. Missing glyphs fall back to the system font.
  std::string textFont;
  // Width of the image and the vertical position of the words in it, in its own
  // points.
  float textWide = 0.f, textAt = 0.f;
  // Set when new words outgrew the image; the text must be remade.
  std::atomic<bool> outgrown{false};
};

// Trims the path via ThorVG's trimpath. Wraps past either end. No-op if
// unchanged.
void trim_at(Stage& s, Canvas2D* d, float cut, float begin = 0.f,
             float offset = 0.f);

// Bends the shape of `d` with the given parameters, with the units of tvg_bend,
// and draws it again for the next frame. Does nothing if the parameters are
// unchanged. When `steps` is non-empty, applies those operators in order.
void bend_at(Stage& s, Canvas2D* d, float round, float bloat, float zigzag,
             float ridges, float smooth, float offset,
             const std::vector<PathOpStep>& steps = {});

// Applies Lottie slot overrides (lottie_slots_json) via ThorVG's slot API.
// No-op if unchanged.
void slots_at(Stage& s, Canvas2D* d, const std::string& slots);
// Updates MIDI roll notes. lit[i]: 0 keeps color, 1 raises by 0.3. moves[i]:
// per-note transform. Note i = SVG "note<i>" (midi_roll.cpp). No-op if
// unchanged.
void lit_at(Stage& s, Canvas2D* d, const std::vector<float>& lit,
            const std::vector<tvg::Matrix>& moves,
            filament::math::float3 colour);
// Sets the displayed words of a text (doc_text_shown). No-op if unchanged.
// Returns false if the layer has no retype function or the text outgrew the
// image.
bool words_at(Stage& s, Canvas2D* d, const std::string& words);
// Disk cache: ~/Library/Caches/Motolii/frames. Each frame is one zstd file,
// named by a hash of its inputs. cache_dir creates the folder on first use and
// trims it to 20 GB.
const std::filesystem::path& cache_dir();
// Number of frames on their way to disk: waiting to be written or still being
// read back.
extern std::atomic<int> cache_unwritten;
// Queues `pixels` to be written to `file` by a thread of its own. The data is
// compressed, written to a file ending in .part, and then renamed.
void cache_write(std::filesystem::path file, std::vector<uint8_t> pixels);
// Reads and decompresses `file` into `pixels`, which is resized to `size`
// bytes. Returns true only if the whole file was read and decompressed to
// exactly `size` bytes.
bool cache_read(const std::filesystem::path& file, std::vector<uint8_t>& pixels,
                size_t size);

// Discards the frames cached for `d`, because what it draws has changed.
void cache_drop(Stage& s, Canvas2D* d);

// Counts how each frame was shown: from the GPU cache, from disk, or freshly
// rendered. For diagnostics.
extern std::atomic<long> films_cached, films_disk, films_rendered;
// Shows the animation at `seconds`. Time is rounded to file frames so a frame
// already drawn is reused from the GPU or disk cache.
void canvas_at(Stage& s, Canvas2D* d, float seconds);

// Pre-caches up to `many` frames ahead while the user is idle. Returns 0 when
// nothing more can be done now.
int frames_ahead(Stage& s, Canvas2D* d, int many);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_

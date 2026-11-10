#ifndef MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_
#define MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_

// Per-layer ThorVG canvas state and the frame cache for canvas.h. Holds the
// Canvas2D and Canvas2DFx structs, the functions that redraw a canvas when its
// effects or path change, and the GPU and disk caches of rendered animation
// frames.

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

#include "stage/render/render_stage.h"

namespace motolii {

// Drawing options of a flat layer drawn by ThorVG. Lengths are fractions of the
// layer height unless noted; see over().
//
// split makes a text draw each letter as a copy of its own.
struct Canvas2DFx {
  bool split = false;  // (a text's letters each a copy of their own)
  // Splits a text into words instead of letters. Matches After Effects' Based
  // On Words and Alight Motion's Text Transform.
  bool splitWords = false;
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
  // Extra outlines, each outside the previous one. x, y and z are the color and
  // w is the width as a fraction of the layer height.
  std::vector<filament::math::float4> rims;
  // Stacks the letters vertically, one letter height apart.
  bool column = false;
  // A text's lines are broken in a box wrapWidth letter heights wide, using
  // ThorVG's text layout and wrap. wrap 0 keeps the text as typed. letters and
  // italic correspond to ThorVG's Text::spacing and Text::italic.
  float letters = 1.f, lines = 1.f, italic = 0.f, wrapWidth = 0.f;
  int wrap = 0;
  // Stroke options passed to ThorVG's Shape::strokeDash, strokeCap and
  // strokeJoin. -1 for cap and join keeps ThorVG's default.
  float dash = 0.f, dashFrom = 0.f;
  int cap = -1, join = -1;
  // Heads on the ends of an open edge, as in Cavalry. heads is 1 for the end, 2
  // for the start and 3 for both. headSize scales the heads relative to the
  // edge. headShape is 0 arrow, 1 circle, 2 box, 3 chevron, 4 bar; 5 and above
  // are Alight Motion shapes drawn by AbsentMotion (canvas_flat.h). headStart
  // is the shape for the start; -1 uses headShape.
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
  // File of an image that fills a flat shape instead of its color, visible only
  // where the shape is filled. Matches Alight Motion's Fill > Media.
  std::string media;
  // Where outlines overlap, leaves a hole every other time, like SVG's
  // fill-rule evenodd. Otherwise the fill rule is nonzero.
  bool evenOdd = false;
  // The most a bent shape extends past its box, as a fraction of its height.
  // See bend_at. The image is made larger on all sides by this amount.
  float reach = 0.f;
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
  // Rendered frames of the animation, cached on the GPU so that a frame drawn
  // once is shown again instead of drawn again. This is like After Effects' RAM
  // preview, but per layer. cache_drop discards them when what the layer draws
  // changes. `cached` is keyed by frame and used on the main thread. `keeping`
  // holds the copies just made on the driver thread, which the main thread
  // takes.
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
  // Identifies the layer's frames on disk: the source file as it is. Empty
  // means frames are not cached on disk.
  std::string keyBase;
  // The After Effects file's slots as last set. See lottie_slots.h.
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
  // For a 2D sketch: produces the paints of a frame on a canvas that holds
  // another canvas, from the script's paints. Main thread. See canvas_sketch.h.
  std::function<std::vector<double>(int, int)> sketch;
  // How strongly each drawing line of the sketch is active now. Main thread.
  // See sketch_marked in script.h.
  std::shared_ptr<std::map<int, double>> sketchLines;
  // The frame last requested from `sketch`, which the canvas will hold. Main
  // thread.
  int sketchAt = -1;
  // The ThorVG scene the sketch's paints are added to. Driver thread only.
  tvg::Scene* sketchScene = nullptr;
  // ThorVG's name of the font the sketch's text is set in.
  std::string sketchFont;
  // Images the sketch paints, by id from __bitmaps in p5_stand.h. They are
  // requested on the main thread and read on the driver thread.
  std::map<int, std::shared_ptr<std::vector<uint8_t>>> sketchPics;
  // Guards `sketchPics`.
  std::mutex sketchPicsLock;
  // The texture Filament samples.
  filament::Texture* texture = nullptr;
  // Distance from each point to the edge of the image, used for the bevel. See
  // canvas_edge.h.
  filament::Texture* edge[3] = {};
  filament::RenderTarget* edgeInto[3] = {};
  uint32_t edgeW = 0, edgeH = 0;
  // Where each stroke ends, in points from its outside; w is how many. Used for
  // the stairs of a Step bevel. See deep.glsl.
  filament::math::float4 bands{0.f};
  // True for flat_lit: the lighting of the surface is updated every frame by
  // document/evaluate/evaluate.h.
  bool inLight = false;
  // How far the edge distances are known, in points.
  int edgeReach = 0;
  // True when the canvas has been drawn again since the edge distances were
  // computed. Set on the driver thread.
  std::atomic<bool> stale{true};
  // The layer in the scene, moved like any other layer. See move in render.h.
  Mesh* sheet = nullptr;
  // Half the box size across, up and through, when the layer has depth. See
  // document/evaluate/evaluate.h.
  filament::math::float3 boxed{0.f};
  // True when the box is open. See document/evaluate/evaluate.h.
  bool open = false;
  // The layer's material instance. Null if the layer is not shown.
  filament::MaterialInstance* look = nullptr;
  // Length of the animation in seconds and in frames. 0 for a still image.
  float seconds = 0.f, frames = 0.f;
  // How far into the animation it is when the stage time is 0.
  float starts = 0.f;
  // A flat shape's own path. Driver thread only.
  tvg::Shape* shape = nullptr;
  // As last trimmed: how much was cut off the end, off the beginning, and the
  // offset along the path.
  filament::math::float3 trimmed{0.f};
  // The path as made, before it is bent. See bend_at.
  std::vector<tvg::PathCommand> plain;
  std::vector<tvg::Point> plainAt;
  // The height the path was drawn at and its shorter side, in the layer's own
  // points.
  float plainHigh = 0.f, plainSide = 0.f;
  // Height of the image, including room for effects, in the same points.
  float canvasHigh = 0.f;
  // Lines are cut into pieces no longer than this many points.
  float fine = 0.f;
  // True for a flat shape that Filament draws as its own triangles (flat_mesh),
  // with no image and no canvas. Its bending is done in its material.
  bool cut = false;
  // The layer's own color laid over its material, as a copy's is. A shape cut
  // into triangles is filled this way.
  filament::math::float4 wash{0.f};
  // Width divided by height. Bends are counted across this width.
  float wideBy = 1.f;
  // For a shape drawn as triangles: its ThorVG path, kept on the CPU only and
  // never drawn.
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
  // One layer of an After Effects file, drawn alone. See layer_canvas. source
  // is the file, layerId the layer, holder the scene that holds it and fit how
  // it is fitted.
  tvg::Animation* source = nullptr;
  uint32_t layerId = 0;
  tvg::Scene* holder = nullptr;
  tvg::Matrix fit{1, 0, 0, 0, 1, 0, 0, 0, 1};
  // The Lottie animation, when the layer is an After Effects file. Used to read
  // the poses of its layers.
  tvg::LottieAnimation* lottie = nullptr;
  // Ids of the 3D layers of an After Effects file. They are not drawn in its
  // own image; each gets a sheet of its own. See canvas_deep.
  std::vector<uint32_t> deep;
  // Parameters as last applied by bend_at: round, bloat, zigzag, ridges,
  // smooth, offset. The remaining four are for roughening: how far and how
  // fine, the number of points walked again, and the square size.
  std::array<float, 10> bent{};
  // Another shape's path, in this shape's points, and what to do with it. It is
  // either combined (how: the operation from skia_path_operations.cpp, -1 for
  // none) or morphed into (much: how far, 0 for none; how above 1: that many
  // steps from this shape to it, all at once, as a blend).
  //
  // joined, morphed and traced hold the other path as last combined with, as
  // last morphed into, and as last traced. Tracing makes the whole path follow
  // another's track.
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
  // Paths already cut into triangles, keyed by what they were cut from, as PAG
  // keeps the shapes of a frame and Beutl keeps a path by its version. A time
  // cut once is not cut again while the entry is cached. All shapes together
  // hold at most cuts_most.
  struct Cut {
    std::vector<tvg::PathCommand> by;
    std::vector<tvg::Point> at;
    std::vector<filament::math::float3> pos;
    std::vector<filament::math::float2> uv;
    std::vector<uint32_t> idx, ends;
    uint32_t fillPoints, fillEnd;
    size_t bytes;
  };
  struct Cuts {
    std::unordered_map<uint64_t, Cut> all;
    std::deque<uint64_t> order;
    size_t bytes = 0;
    ~Cuts();
  } cuts;
  // Named sections of an After Effects file, which are ThorVG's Lottie markers.
  std::vector<std::string> markers;
  // For a text split into letters: where each letter lies across the image, as
  // fractions of its width. Each copy shows one letter.
  std::vector<filament::math::float2> letters;
  // The section that plays when one is named, in frames of the file.
  float fromFrame = 0.f, toFrame = 0.f;
  // For a text: how many times as tall as one line the text is. The size gives
  // the height of a line.
  float tallBy = 1.f;
  // The drawing options the layer was made with.
  Canvas2DFx fx;
  // The text's own words as a ThorVG text. Driver thread only. words_at updates
  // it in place. Null when the text is split, wrapped or aligned.
  tvg::Text* text = nullptr;
  // As last set.
  std::string words;
  // The font file the words are set in. Words that contain letters it lacks are
  // made again with the fallback font.
  std::string textFont;
  // Width of the image and the vertical position of the words in it, in its own
  // points.
  float textWide = 0.f, textAt = 0.f;
  // Set when words set since are wider than the image. The text must then be
  // made again.
  std::atomic<bool> outgrown{false};
};

// Trims a flat shape's path. `cut` of it is removed from the end and `begin`
// from the beginning, and the part left is slid along the path by `offset` of
// the way round. This uses ThorVG's trimpath, which wraps past either end, like
// After Effects' Trim Paths. The shape is drawn again for the next frame. Does
// nothing if the trim is unchanged.
void trim_at(Stage& s, Canvas2D* d, float cut, float begin = 0.f,
             float offset = 0.f);

// Bends the shape of `d` with the given parameters, with the units of tvg_bend,
// and draws it again for the next frame. Does nothing if the parameters are
// unchanged.
void bend_at(Stage& s, Canvas2D* d, float round, float bloat, float zigzag,
             float ridges, float smooth, float offset);

// Applies the slots of an After Effects file (lottie_slots_json) and draws it
// again for the next frame. Does nothing if the
// slots are unchanged. Uses ThorVG's own slot API: generate the slots, then
// apply them.
void slots_at(Stage& s, Canvas2D* d, const std::string& slots);
// Updates the notes of a MIDI roll and draws them again for the next frame, as
// slots_at does. lit[i] is how lit note i is: 0 keeps its color and 1 raises it
// by 0.3, as ALMaMPlayer does (note.gd modulate). moves[i] is the transform of
// note i, grown and dipped as the tweens in note.gd do. Note i is the SVG
// element "note<i>" (midi_roll.cpp), found with ThorVG's Accessor::id. Does
// nothing if nothing changed.
void lit_at(Stage& s, Canvas2D* d, const std::vector<float>& lit,
            const std::vector<tvg::Matrix>& moves,
            filament::math::float3 colour);
// Sets the words of a text, as AbsentMotion's text effects produce them
// (doc_text_shown), and draws them again for the next frame, as slots_at does
// for a Lottie file. The words are centered across the image at the height they
// were set at. Does nothing if the words are unchanged. Returns false if the
// layer has no words of its own to set, or if the last words did not fit the
// image (outgrown).
bool words_at(Stage& s, Canvas2D* d, const std::string& words);
// Frames are also cached on disk in ~/Library/Caches/Motolii/frames, so that a
// reopened project shows frames drawn earlier without drawing them again. Each
// frame is one file, compressed with zstd as Filament builds it. A file is
// named by a hash of what produced the frame: the source file, the drawn size,
// the effects, the section and the frame number. Nuke names its cache by its
// inputs in the same way.
//
// cache_dir returns the folder and creates it on first use. At that time it
// also deletes the oldest files, on a background thread, until the folder is
// under 20 GB.
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
// Shows the animation `seconds` from its start, for the next frame. After its
// end it holds the last frame. The time is rounded to the frames of the file,
// as After Effects plays it, so a time within the frame already drawn draws
// nothing again. ThorVG's frame() reports when the frame is the same. This is
// the advice of the ThorVG author for Lottie on a GPU
// (godotengine/godot#91580). A frame drawn once is shown again from the cache,
// on the GPU or on disk.
void canvas_at(Stage& s, Canvas2D* d, float seconds);

// While the user is idle, caches a few frames after the one shown before they
// are asked for, as Final Cut Pro renders when the user stops, and as DaVinci
// Resolve's Smart Cache and After Effects' Cache Frames When Idle do. Each
// frame is read from disk if it is there, and otherwise drawn into the texture
// the canvas draws into, which is free while the frame shown comes from the
// cache. `many` is the most frames to start. Returns how many were started; 0
// means nothing more can be done now.
int frames_ahead(Stage& s, Canvas2D* d, int many);

}  // namespace motolii

#endif  // MOTOLII_STAGE_CANVAS_CANVAS_CACHE_H_

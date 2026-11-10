// Per-layer ThorVG canvas state and the frame cache for canvas.h. Holds the Canvas2D and Canvas2DFx
// structs, the functions that redraw a canvas when its effects or path change, and the GPU and disk
// caches of rendered animation frames. Included by canvas.h; not self-contained.
#include "gpu/gpu_interop.h"
#include <thorvg.h>
#include <thorvg_lottie.h>
#include <tesselator.h>
#include <webgpu/webgpu.h>

#include <array>
#include <set>
#include <condition_variable>
#include <cstring>
#include <deque>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <thread>
#include "third_party/filament_src/third_party/zstd/lib/zstd.h"

// Effects and drawing options of a flat layer drawn by ThorVG. Lengths are fractions of the layer
// height unless noted; see over().
//
// tint is how strongly dark and light areas are mapped to two colors; 0 means off. tritone is how
// strongly dark, middle and light areas are mapped to three colors; 0 means off.
//
// split makes a text draw each letter as a copy of its own.
struct Canvas2DFx { bool split = false;   // (a text's letters each a copy of their own)
    // Splits a text into words instead of letters. Matches After Effects' Based On Words and Alight
    // Motion's Text Transform.
    bool splitWords = false;
    // Draws all copies in one instanced draw, so no copy gets its own color or clear. See add_parts
    // in render.h.
    bool together = false;
    // The layer has depth: the sheet becomes a box and the image is pushed through it. See
    // deep.glsl.
    bool thick = false;
    // The layer is lit by the scene's lights. See flat_lit in flat.mat and doc_lit.
    bool lit = false;
    // Name of the material applied to the layer, with the image as its color. Selects flat_<wear>
    // in flat.mat. See doc_sheet_material. Empty means none.
    std::string wear;
    // Cuts the edges of the box as the project says. See deep.glsl and canvas_edge.h.
    bool bevel = false;
    // Extra outlines, each outside the previous one. x, y and z are the color and w is the width as
    // a fraction of the layer height.
    std::vector<float4> rims;
    // Stacks the letters vertically, one letter height apart.
    bool column = false;
    // A text's lines are broken in a box wrapWidth letter heights wide, using ThorVG's text layout
    // and wrap. wrap 0 keeps the text as typed. letters and italic correspond to ThorVG's
    // Text::spacing and Text::italic.
    float letters = 1.f, lines = 1.f, italic = 0.f, wrapWidth = 0.f; int wrap = 0;
    // Stroke options passed to ThorVG's Shape::strokeDash, strokeCap and strokeJoin. -1 for cap and
    // join keeps ThorVG's default.
    float dash = 0.f, dashFrom = 0.f; int cap = -1, join = -1;
    // Heads on the ends of an open edge, as in Cavalry. heads is 1 for the end, 2 for the start and
    // 3 for both. headSize scales the heads relative to the edge. headShape is 0 arrow, 1 circle, 2
    // box, 3 chevron, 4 bar; 5 and above are Alight Motion shapes drawn by AbsentMotion
    // (canvas_flat.h). headStart is the shape for the start; -1 uses headShape.
    int heads = 0; float headSize = 4.f; int headShape = 0, headStart = -1;
    // shadow is the RGBA color of the drop shadow. way, fall and soft are its angle, distance and
    // softness, the last two as fractions of the layer height. blurWay is the blur direction passed
    // to ThorVG.
    float blur = 0.f; int blurWay = 0; float overHigh = 1.f; float4 shadow{0.f}; float fall = 0.f, way = 0.f, soft = 0.f; float tint = 0.f; float3 tints[2]{}; float tritone = 0.f; float3 tones[3]{}; int copies = 1;
                 // Two or more colors. The shape is filled with ThorVG's linear gradient from the
                 // first color at the top to the last at the bottom.
                 std::vector<float4> ramp;
                 // Position of each ramp color as a fraction of the way along the gradient, like
                 // CSS color stop positions and SVG stop offsets. Empty means evenly spaced.
                 std::vector<float> rampAt;
                 // How colors are mixed between stops: 0 sRGB, 1 OKLab, 2 around the hue, 3 not at
                 // all. See ramp_of.
                 int rampBlend = 0;
                 // A flat shape filled with nothing, so only its edge is visible.
                 bool hollow = false;
                 // File of an image that fills a flat shape instead of its color, visible only
                 // where the shape is filled. Matches Alight Motion's Fill > Media.
                 std::string media;
                 // Where outlines overlap, leaves a hole every other time, like SVG's fill-rule
                 // evenodd. Otherwise the fill rule is nonzero.
                 bool evenOdd = false;
                 // The most a bent shape extends past its box, as a fraction of its height. See
                 // bend_at. The image is made larger on all sides by this amount.
                 float reach = 0.f;
                 // How far effects may reach around the layer, as a fraction of its height. Space
                 // for it is made in the image (doc_fx_room). Changes within it are redrawn without
                 // rebuilding the image.
                 float room = 0.f;
                 // Effects in the order they are laid out in the layer's effect list (doc_fx_list):
                 // t tint, r tritone, s shadow, b blur.
                 char order[5] = "trsb";
                 // radial selects ThorVG's radial gradient, from the middle outward, instead of a
                 // linear one. rampAngle is the rotation, clockwise. rampScale is the length as a
                 // fraction of reach. spread is how the gradient continues past its ends: padded,
                 // reflected or repeated.
                 bool radial = false; float rampAngle = 0.f, rampScale = 1.f; int spread = 0;
                 // Returns a copy for a layer `high` units tall, with the lengths divided by `high`
                 // so they become fractions of the height.
                 Canvas2DFx over(float high) const {
                     Canvas2DFx f = *this;
                     f.blur /= high, f.fall /= high, f.soft /= high, f.room /= high, f.overHigh = high;
                     return f;
                 } };

struct Canvas2D {
    // Driver thread only.
    tvg::WgCanvas* canvas = nullptr;
    // The texture the canvas draws into. A cached frame is copied from it.
    WGPUTexture target = nullptr;
    // Rendered frames of the animation, cached on the GPU so that a frame drawn once is shown again
    // instead of drawn again. This is like After Effects' RAM preview, but per layer. cache_drop
    // discards them when what the layer draws changes. `cached` is keyed by frame and used on the
    // main thread. `keeping` holds the copies just made on the driver thread, which the main thread
    // takes.
    std::map<int, Texture*> cached;
    // The WebGPU texture behind each cached frame. They are released when the frames are discarded,
    // after Filament has finished with them.
    std::vector<WGPUTexture> cachedTextures;
    // Guards `keeping`.
    std::mutex keepingLock;
    std::vector<std::pair<int, WGPUTexture>> keeping;
    // The frame currently shown, or -1.
    int shownAt = -1;
    // The frame that `target` holds. Driver thread only.
    int targetAt = -1;
    // Frames that are being written to disk only, while the user is idle. See frames_ahead. Main
    // thread.
    std::set<int> ahead;
    // Identifies the layer's frames on disk: the source file as it is. Empty means frames are not
    // cached on disk.
    std::string keyBase;
    // The After Effects file's slots as last set. See lottie_slots.h.
    std::string slots;
    // For a MIDI roll: how lit each note is, as last set. See midi_roll.cpp.
    std::vector<float> lit;
    // For a MIDI roll: the transform of each note, as last set.
    std::vector<tvg::Matrix> moves;
    // ThorVG's id of the applied slots. Driver thread only.
    uint32_t slotsId = 0;
    // Incremented each time the cached frames are discarded. A copy made before that is not cached.
    std::atomic<int> keepAge{0};
    // The animation. Driver thread only.
    tvg::Animation* film = nullptr;
    // For a 2D sketch: produces the paints of a frame on a canvas that holds another canvas, from
    // the script's paints. Main thread. See canvas_sketch.h.
    std::function<std::vector<double>(int, int)> sketch;
    // How strongly each drawing line of the sketch is active now. Main thread. See sketch_marked in
    // script.h.
    std::shared_ptr<std::map<int, double>> sketchLines;
    // The frame last requested from `sketch`, which the canvas will hold. Main thread.
    int sketchAt = -1;
    // The ThorVG scene the sketch's paints are added to. Driver thread only.
    tvg::Scene* sketchScene = nullptr;
    // ThorVG's name of the font the sketch's text is set in.
    std::string sketchFont;
    // Images the sketch paints, by id from __bitmaps in p5_stand.h. They are requested on the main
    // thread and read on the driver thread.
    std::map<int, std::shared_ptr<std::vector<uint8_t>>> sketchPics;
    // Guards `sketchPics`.
    std::mutex sketchPicsLock;
    // The texture Filament samples.
    Texture* texture = nullptr;
    // Distance from each point to the edge of the image, used for the bevel. See canvas_edge.h.
    Texture* edge[3] = {};
    RenderTarget* edgeInto[3] = {};
    uint32_t edgeW = 0, edgeH = 0;
    // Where each stroke ends, in points from its outside; w is how many. Used for the stairs of a
    // Step bevel. See deep.glsl.
    float4 bands{0.f};
    // True for flat_lit: the lighting of the surface is updated every frame by document/evaluate.h.
    bool inLight = false;
    // How far the edge distances are known, in points.
    int edgeReach = 0;
    // True when the canvas has been drawn again since the edge distances were computed. Set on the
    // driver thread.
    std::atomic<bool> stale{true};
    // The layer in the scene, moved like any other layer. See move in render.h.
    Mesh* sheet = nullptr;
    // Half the box size across, up and through, when the layer has depth. See document/evaluate.h.
    float3 boxed{0.f};
    // True when the box is open. See document/evaluate.h.
    bool open = false;
    // The layer's material instance. Null if the layer is not shown.
    MaterialInstance* look = nullptr;
    // Length of the animation in seconds and in frames. 0 for a still image.
    float seconds = 0.f, frames = 0.f;
    // How far into the animation it is when the stage time is 0.
    float starts = 0.f;
    // A flat shape's own path. Driver thread only.
    tvg::Shape* shape = nullptr;
    // As last trimmed: how much was cut off the end, off the beginning, and the offset along the
    // path.
    float3 trimmed{0.f};
    // The path as made, before it is bent. See bend_at.
    std::vector<tvg::PathCommand> plain; std::vector<tvg::Point> plainAt;
    // The height the path was drawn at and its shorter side, in the layer's own points.
    float plainHigh = 0.f, plainSide = 0.f;
    // Height of the image, including room for effects, in the same points.
    float canvasHigh = 0.f;
    // Lines are cut into pieces no longer than this many points.
    float fine = 0.f;
    // True for a flat shape that Filament draws as its own triangles (flat_mesh), with no image and
    // no canvas. Its bending is done in its material.
    bool cut = false;
    // The layer's own color laid over its material, as a copy's is. A shape cut into triangles is
    // filled this way.
    float4 wash{0.f};
    // Width divided by height. Bends are counted across this width.
    float wideBy = 1.f;
    // For a shape drawn as triangles: its ThorVG path, kept on the CPU only and never drawn.
    tvg::Shape* outline = nullptr;
    // Width of the path in points, height of the sheet on the stage, and width of the edge in
    // points.
    float cutW = 0.f, sheetHigh = 1.f, edgeWide = 0.f;
    bool hollow = false;
    // Where the fill's points and triangles end in the sheet. The edge comes after them.
    uint32_t fillPoints = 0, fillEnd = 0;
    // The edge's own material instance, for the second part of the triangles.
    MaterialInstance* edgeLook = nullptr;
    // One layer of an After Effects file, drawn alone. See layer_canvas. source is the file,
    // layerId the layer, holder the scene that holds it and fit how it is fitted.
    tvg::Animation* source = nullptr;
    uint32_t layerId = 0;
    tvg::Scene* holder = nullptr;
    tvg::Matrix fit{1, 0, 0, 0, 1, 0, 0, 0, 1};
    // The Lottie animation, when the layer is an After Effects file. Used to read the poses of its
    // layers.
    tvg::LottieAnimation* lottie = nullptr;
    // Ids of the 3D layers of an After Effects file. They are not drawn in its own image; each gets
    // a sheet of its own. See canvas_deep.
    std::vector<uint32_t> deep;
    // Parameters as last applied by bend_at: round, bloat, zigzag, ridges, smooth, offset. The
    // remaining four are for roughening: how far and how fine, the number of points walked again,
    // and the square size.
    std::array<float, 10> bent{};
    // Another shape's path, in this shape's points, and what to do with it. It is either combined
    // (how: the operation from skia_path_operations.cpp, -1 for none) or morphed into (much: how
    // far, 0 for none; how above 1: that many steps from this shape to it, all at once, as a
    // blend).
    //
    // joined, morphed and traced hold the other path as last combined with, as last morphed into,
    // and as last traced. Tracing makes the whole path follow another's track.
    struct Other {
        int how = -1; float much = 0.f; std::vector<tvg::PathCommand> by; std::vector<tvg::Point> at;
        bool operator==(const Other& o) const {
            return how == o.how && much == o.much && by == o.by && at.size() == o.at.size() && std::equal(at.begin(), at.end(), o.at.begin(), [](tvg::Point a, tvg::Point b) { return a.x == b.x && a.y == b.y; });
        }
    } joined, morphed, traced;   // (as last put together with, as last turned into, as last tracing: its whole path another's track)
    // Paths already cut into triangles, keyed by what they were cut from, as PAG keeps the shapes
    // of a frame and Beutl keeps a path by its version. A time cut once is not cut again while the
    // entry is cached. All shapes together hold at most cuts_most.
    struct Cut { std::vector<tvg::PathCommand> by; std::vector<tvg::Point> at; std::vector<float3> pos; std::vector<float2> uv; std::vector<uint32_t> idx, ends; uint32_t fillPoints, fillEnd; size_t bytes; };
    struct Cuts { std::unordered_map<uint64_t, Cut> all; std::deque<uint64_t> order; size_t bytes = 0; ~Cuts(); } cuts;
    // Named sections of an After Effects file, which are ThorVG's Lottie markers.
    std::vector<std::string> markers;
    // For a text split into letters: where each letter lies across the image, as fractions of its
    // width. Each copy shows one letter.
    std::vector<float2> letters;
    // The section that plays when one is named, in frames of the file.
    float fromFrame = 0.f, toFrame = 0.f;
    // The ThorVG scenes the effects are applied to. Driver thread only.
    std::vector<tvg::Scene*> effects;
    // The height it was drawn at, in its own points. Effect lengths are fractions of it.
    float tall = 0.f;
    // For a text: how many times as tall as one line the text is. The size gives the height of a
    // line.
    float tallBy = 1.f;
    // The effects as last set.
    Canvas2DFx fx;
    // The text's own words as a ThorVG text. Driver thread only. words_at updates it in place. Null
    // when the text is split, wrapped or aligned.
    tvg::Text* text = nullptr;
    // As last set.
    std::string words;
    // The font file the words are set in. Words that contain letters it lacks are made again with
    // the fallback font.
    std::string textFont;
    // Width of the image and the vertical position of the words in it, in its own points.
    float textWide = 0.f, textAt = 0.f;
    // Set when words set since are wider than the image. The text must then be made again.
    std::atomic<bool> outgrown{false};
};

static void cache_drop(Stage& s, Canvas2D* d);

// Adds one of ThorVG's own effects to the scene `on`. `k` is a letter of Canvas2DFx::order. Lengths
// in `fx` are fractions of `tall` points.
static void effect_on(tvg::Scene* on, char k, const Canvas2DFx& fx, float tall) {
    const auto c = [](float v) { return (int)std::lround(255.f * v); };
    if (k == 't' && fx.tint > 0.f) on->add(tvg::SceneEffect::Tint, c(fx.tints[0].x), c(fx.tints[0].y), c(fx.tints[0].z), c(fx.tints[1].x), c(fx.tints[1].y), c(fx.tints[1].z), (double)(100.f * fx.tint));
    if (k == 'r' && fx.tritone > 0.f)
        on->add(tvg::SceneEffect::Tritone, c(fx.tones[0].x), c(fx.tones[0].y), c(fx.tones[0].z), c(fx.tones[1].x), c(fx.tones[1].y), c(fx.tones[1].z), c(fx.tones[2].x), c(fx.tones[2].y), c(fx.tones[2].z), c(1.f - fx.tritone));
    if (k == 's' && fx.shadow.w > 0.f) on->add(tvg::SceneEffect::DropShadow, c(fx.shadow.x), c(fx.shadow.y), c(fx.shadow.z), c(fx.shadow.w), (double)fx.way, (double)(fx.fall * tall), (double)std::max(fx.soft * tall, 0.01f), 75);
    // blurWay is the blur direction: both, across, or up and down.
    if (k == 'b' && fx.blur > 0.f) on->add(tvg::SceneEffect::GaussianBlur, (double)(fx.blur * tall), fx.blurWay, 0, 75);
}
// Replaces the effects on chain[0] with those in `fx`, in the order of fx.order. Lengths are
// fractions of `tall` points.
static void effects_on(const std::vector<tvg::Scene*>& chain, const Canvas2DFx& fx, float tall) {
    tvg::Scene* on = chain[0];
    on->add(tvg::SceneEffect::Clear);
    for (const char* k = fx.order; *k; ++k) effect_on(on, *k, fx, tall);
}

// Trims a flat shape's path. `cut` of it is removed from the end and `begin` from the beginning,
// and the part left is slid along the path by `offset` of the way round. This uses ThorVG's
// trimpath, which wraps past either end, like After Effects' Trim Paths. The shape is drawn again
// for the next frame. Does nothing if the trim is unchanged.
static void trim_at(Stage& s, Canvas2D* d, float cut, float begin = 0.f, float offset = 0.f) {
    const float3 is{cut, begin, offset};
    if (!d->shape || (is == d->trimmed)) return;
    d->trimmed = is;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, cut, begin, offset] {
        d->shape->trimpath(std::clamp(begin, 0.f, 1.f) + offset, 1.f - std::clamp(cut, 0.f, 1.f) + offset);
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
    });
}

// Bends the shape of `d` with the given parameters, with the units of tvg_bend, and draws it again
// for the next frame. Does nothing if the parameters are unchanged.
static void bend_at(Stage& s, Canvas2D* d, float round, float bloat, float zigzag, float ridges, float smooth, float offset) {
    const std::array<float, 10> is{round, bloat, zigzag, ridges, smooth, offset, 0.f, 0.f, 0.f, 0.f};
    if (!d->shape || d->plain.empty() || is == d->bent) return;
    d->bent = is;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, is] {
        const float high = d->plainHigh, side = d->plainSide;
        tvg_bend(d->shape, d->plain.data(), (uint32_t)d->plain.size(), d->plainAt.data(), (uint32_t)d->plainAt.size(), std::clamp(is[0], 0.f, 0.5f) * side,
                 100.f * std::clamp(is[1], -1.f, 1.f), std::clamp(is[2], -4.f, 4.f) * high, (int)std::clamp(is[3], 0.f, 100.f), is[4] > 0.5f, std::clamp(is[5], -4.f, 4.f) * high, d->fine);
        // A shape bent to more than 64 times the size of its image is not drawn. None of it would
        // be visible, and ThorVG can crash while measuring, dashing and staging a path that large.
        float x = 0.f, y = 0.f, w = 0.f, h = 0.f;
        if (d->shape->bounds(&x, &y, &w, &h) == tvg::Result::Success && !(std::max(w, h) < 64.f * std::max(1.f, d->canvasHigh))) d->shape->reset();
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
    });
}

// Applies the slots of an After Effects file (lottie_slots_json) and draws it again for the next
// frame, as fx_at does for effects. Does nothing if the slots are unchanged. Uses ThorVG's own slot
// API: generate the slots, then apply them.
static void slots_at(Stage& s, Canvas2D* d, const std::string& slots) {
    if (!d->lottie || slots == d->slots) return;
    d->slots = slots;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, slots] {
        if (d->slotsId) d->lottie->del(d->slotsId), d->slotsId = 0;
        if (!slots.empty() && (d->slotsId = d->lottie->gen(slots.c_str()))) d->lottie->apply(d->slotsId);
        // Draw the current frame again.
        d->targetAt = -1;
    });
}
// Updates the notes of a MIDI roll and draws them again for the next frame, as slots_at does.
// lit[i] is how lit note i is: 0 keeps its color and 1 raises it by 0.3, as ALMaMPlayer does
// (note.gd modulate). moves[i] is the transform of note i, grown and dipped as the tweens in
// note.gd do. Note i is the SVG element "note<i>" (midi_roll.cpp), found with ThorVG's
// Accessor::id. Does nothing if nothing changed.
static void lit_at(Stage& s, Canvas2D* d, const std::vector<float>& lit, const std::vector<tvg::Matrix>& moves, float3 colour) {
    if (!d->film || (lit == d->lit && moves.size() == d->moves.size() && std::equal(moves.begin(), moves.end(), d->moves.begin(), [](const tvg::Matrix& a, const tvg::Matrix& b) { return !std::memcmp(&a, &b, sizeof a); }))) return;
    d->lit = lit, d->moves = moves;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, lit, moves, colour] {
        for (size_t i = 0; i < lit.size(); ++i)
            if (auto* note = const_cast<tvg::Paint*>(d->film->picture()->paint(tvg::Accessor::id(("note" + std::to_string(i)).c_str()))); note && note->type() == tvg::Type::Shape) {
                const float3 c = min(colour + 0.3f * lit[i], float3{1.f});
                static_cast<tvg::Shape*>(note)->fill((uint8_t)std::lround(c.x * 255.f), (uint8_t)std::lround(c.y * 255.f), (uint8_t)std::lround(c.z * 255.f));
                if (i < moves.size()) note->transform(moves[i]);
            }
        // ThorVG redraws a picture only if the picture itself is marked changed, not its parts (see
        // update in tvgPicture.h). Paint::opacity marks it.
        d->film->picture()->opacity(254), d->film->picture()->opacity(255);
        // Draws now even if the picture does not move, as fx_at does.
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
    });
}
// Returns the letters of `words` that the font file lacks.
static std::string type_lacks(const std::string& fontFile, const std::string& words);
// Sets the words of a text, as AbsentMotion's text effects produce them (doc_text_shown), and draws
// them again for the next frame, as slots_at does for a Lottie file. The words are centered across
// the image at the height they were set at. Does nothing if the words are unchanged. Returns false
// if the layer has no words of its own to set, or if the last words did not fit the image
// (outgrown).
static bool words_at(Stage& s, Canvas2D* d, const std::string& words) {
    if (!d->text || d->outgrown) return false;
    if (words == d->words) return true;
    // The font lacks a letter. The text is made again with the fallback font.
    if (!type_lacks(d->textFont, words).empty()) return false;
    d->words = words;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, words] {
        d->text->translate(0.f, 0.f);
        d->text->text(words.c_str());
        float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
        if (d->text->bounds(&x, &y, &wide, &tall) != tvg::Result::Success) return;
        d->outgrown = wide > d->textWide + 0.5f;
        d->text->translate(0.5f * (d->textWide - wide) - x, d->textAt);
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
    });
    return true;
}
// Applies the effects of a flat layer, with lengths as fractions of its height at the time it was
// made, and draws it again for the next frame. Does nothing if the effects are unchanged. Effects
// reach no further than they did at their most.
static void fx_at(Stage& s, Canvas2D* d, const Canvas2DFx& told) {
    if (d->effects.empty()) return;
    const Canvas2DFx fx = told.over(d->fx.overHigh);
    const Canvas2DFx& was = d->fx;
    if (fx.blur == was.blur && fx.blurWay == was.blurWay && (fx.shadow == was.shadow) && fx.fall == was.fall && fx.way == was.way && fx.soft == was.soft && fx.tint == was.tint && fx.tritone == was.tritone
        && !strcmp(fx.order, was.order) && (fx.tints[0] == was.tints[0]) && (fx.tints[1] == was.tints[1]) && (fx.tones[0] == was.tones[0]) && (fx.tones[1] == was.tones[1]) && (fx.tones[2] == was.tones[2]))
        return;
    d->fx = fx;
    cache_drop(s, d);
    interop::on_driver(s.engine, [d, fx] {
        effects_on(d->effects, fx, d->tall);
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
    });
}


// Frames are also cached on disk in ~/Library/Caches/Motolii/frames, so that a reopened project
// shows frames drawn earlier without drawing them again. Each frame is one file, compressed with
// zstd as Filament builds it. A file is named by a hash of what produced the frame: the source
// file, the drawn size, the effects, the section and the frame number. Nuke names its cache by its
// inputs in the same way.
//
// cache_dir returns the folder and creates it on first use. At that time it also deletes the oldest
// files, on a background thread, until the folder is under 20 GB.
static const std::filesystem::path& cache_dir() {
    static const std::filesystem::path dir = [] {
        const char* home = std::getenv("HOME");
        const std::filesystem::path p = std::filesystem::path(home ? home : "/tmp") / "Library/Caches/Motolii/frames";
        std::error_code e;
        std::filesystem::create_directories(p, e);
        std::thread([p] {
            std::vector<std::pair<std::filesystem::file_time_type, std::filesystem::path>> files;
            uintmax_t total = 0;
            std::error_code e;
            for (const auto& f : std::filesystem::directory_iterator(p, e))
                if (f.is_regular_file(e)) files.push_back({f.last_write_time(e), f.path()}), total += f.file_size(e);
            std::sort(files.begin(), files.end());
            for (const auto& [when, f] : files) {
                if (total <= (uintmax_t(20) << 30)) break;
                total -= std::filesystem::file_size(f, e);
                std::filesystem::remove(f, e);
            }
        }).detach();
        return p;
    }();
    return dir;
}
// Returns the disk cache file for frame `at`, or an empty path if the frames of `d` are not cached
// on disk.
static std::filesystem::path cache_file(const Canvas2D* d, int at) {
    if (d->keyBase.empty() || !d->target) return {};
    std::string all = d->keyBase;
    const auto add = [&](float v) { all += "|" + std::to_string(v); };
    const Canvas2DFx& f = d->fx;
    add((float)wgpuTextureGetWidth(d->target)), add((float)wgpuTextureGetHeight(d->target));
    for (float v : {f.blur, (float)f.blurWay, f.shadow.x, f.shadow.y, f.shadow.z, f.shadow.w, f.fall, f.way, f.soft, f.tint, f.tritone, d->fromFrame, d->toFrame}) add(v);
    for (const float3& c : f.tints) add(c.x), add(c.y), add(c.z);
    for (const float3& c : f.tones) add(c.x), add(c.y), add(c.z);
    for (uint32_t id : d->deep) add((float)id);
    all += "|" + d->slots;
    // FNV-1a, 64 bit.
    uint64_t hash = 1469598103934665603ull;
    for (unsigned char c : all) hash = (hash ^ c) * 1099511628211ull;
    char name[64];
    std::snprintf(name, sizeof name, "%016llx_%05d.zst", (unsigned long long)hash, at);
    return cache_dir() / name;
}
// The queue of frames waiting to be compressed and written, with its lock and the condition that
// wakes the writer thread.
static std::mutex cache_writing_lock;
static std::condition_variable cache_writing_wake;
static std::deque<std::pair<std::filesystem::path, std::vector<uint8_t>>> cache_writing;
// Number of frames on their way to disk: waiting to be written or still being read back.
static std::atomic<int> cache_unwritten{0};
// Queues `pixels` to be written to `file` by a thread of its own. The data is compressed, written
// to a file ending in .part, and then renamed.
static void cache_write(std::filesystem::path file, std::vector<uint8_t> pixels) {
    static std::once_flag started;
    std::call_once(started, [] {
        std::thread([] {
            for (;;) {
                std::unique_lock<std::mutex> hold(cache_writing_lock);
                cache_writing_wake.wait(hold, [] { return !cache_writing.empty(); });
                auto job = std::move(cache_writing.front());
                cache_writing.pop_front();
                hold.unlock();
                std::vector<uint8_t> packed(ZSTD_compressBound(job.second.size()));
                const size_t n = ZSTD_compress(packed.data(), packed.size(), job.second.data(), job.second.size(), 1);
                if (ZSTD_isError(n)) { --cache_unwritten; continue; }
                std::filesystem::path part = job.first;
                part += ".part";
                if (FILE* f = std::fopen(part.c_str(), "wb")) {
                    const bool whole = std::fwrite(packed.data(), 1, n, f) == n;
                    std::fclose(f);
                    std::error_code e;
                    if (whole) std::filesystem::rename(part, job.first, e);
                    else std::filesystem::remove(part, e);
                }
                --cache_unwritten;
            }
        }).detach();
        // At exit, waits for the queued frames to be written, for at most ten seconds.
        std::atexit([] {
            for (int i = 0; i < 1000 && cache_unwritten > 0; ++i) std::this_thread::sleep_for(std::chrono::milliseconds(10));
        });
    });
    {
        std::lock_guard<std::mutex> hold(cache_writing_lock);
        cache_writing.push_back({std::move(file), std::move(pixels)});
    }
    cache_writing_wake.notify_one();
}
// Reads and decompresses `file` into `pixels`, which is resized to `size` bytes. Returns true only
// if the whole file was read and decompressed to exactly `size` bytes.
static bool cache_read(const std::filesystem::path& file, std::vector<uint8_t>& pixels, size_t size) {
    FILE* f = file.empty() ? nullptr : std::fopen(file.c_str(), "rb");
    if (!f) return false;
    std::fseek(f, 0, SEEK_END);
    std::vector<uint8_t> packed((size_t)std::max(0L, std::ftell(f)));
    std::fseek(f, 0, SEEK_SET);
    const bool whole = std::fread(packed.data(), 1, packed.size(), f) == packed.size();
    std::fclose(f);
    pixels.resize(size);
    const size_t n = whole ? ZSTD_decompress(pixels.data(), size, packed.data(), packed.size()) : 0;
    return whole && !ZSTD_isError(n) && n == size;
}
// A pending readback of a cached frame's texture: the buffer, the size, the row length in bytes and
// the file to write to.
struct CacheReadBack { WGPUBuffer buffer; uint32_t w, h, row; std::filesystem::path file; };
// Records a copy of `texture` into a CPU-readable buffer on `encoder`, to be written to `file`.
// Call cache_map after the encoder is submitted. Counts the frame in cache_unwritten.
static CacheReadBack* cache_read_back(WGPUDevice device, WGPUCommandEncoder encoder, WGPUTexture texture, std::filesystem::path file) {
    // WebGPU requires rows of a texture copy to be aligned to 256 bytes.
    const uint32_t w = wgpuTextureGetWidth(texture), h = wgpuTextureGetHeight(texture), row = (4 * w + 255) / 256 * 256;
    WGPUBufferDescriptor like{};
    like.size = (uint64_t)row * h;
    like.usage = WGPUBufferUsage_CopyDst | WGPUBufferUsage_MapRead;
    const WGPUBuffer buffer = wgpuDeviceCreateBuffer(device, &like);
    WGPUTexelCopyTextureInfo from{};
    from.texture = texture;
    WGPUTexelCopyBufferInfo to{};
    to.buffer = buffer;
    to.layout.bytesPerRow = row, to.layout.rowsPerImage = h;
    const WGPUExtent3D size{w, h, 1};
    wgpuCommandEncoderCopyTextureToBuffer(encoder, &from, &to, &size);
    ++cache_unwritten;
    return new CacheReadBack{buffer, w, h, row, std::move(file)};
}
// Maps the buffer once the encoder that fills it has been submitted. When the GPU finishes, removes
// the row padding and queues the pixels to be written. Frees `job`.
static void cache_map(CacheReadBack* job) {
    WGPUBufferMapCallbackInfo done{};
    done.mode = WGPUCallbackMode_AllowSpontaneous;
    done.callback = [](WGPUMapAsyncStatus status, WGPUStringView, void* one, void*) {
        auto* job = (CacheReadBack*)one;
        if (status == WGPUMapAsyncStatus_Success) {
            const auto* at = (const uint8_t*)wgpuBufferGetConstMappedRange(job->buffer, 0, (size_t)job->row * job->h);
            std::vector<uint8_t> pixels((size_t)4 * job->w * job->h);
            if (at)
                for (uint32_t y = 0; y < job->h; ++y) std::memcpy(pixels.data() + (size_t)4 * job->w * y, at + (size_t)job->row * y, (size_t)4 * job->w);
            wgpuBufferUnmap(job->buffer);
            if (at) cache_write(std::move(job->file), std::move(pixels));
            else --cache_unwritten;
        } else {
            --cache_unwritten;
        }
        wgpuBufferRelease(job->buffer);
        delete job;
    };
    done.userdata1 = job;
    wgpuBufferMapAsync(job->buffer, WGPUMapMode_Read, 0, (size_t)job->row * job->h, done);
}

// Total bytes of GPU memory used by the cached frames of all animations.
static std::atomic<size_t> cache_bytes{0};
// Upper limit for cache_bytes: 2 GB.
static constexpr size_t cache_most = size_t(2) << 30;
// Size in bytes of one cached frame of `d`, four bytes a pixel.
static size_t cache_one(const Canvas2D* d) { return d->target ? 4 * (size_t)wgpuTextureGetWidth(d->target) * wgpuTextureGetHeight(d->target) : 0; }
// Discards the frames cached for `d`, because what it draws has changed.
static void cache_drop(Stage& s, Canvas2D* d) {
    {
        std::lock_guard<std::mutex> hold(d->keepingLock);
        for (auto& [at, built] : d->keeping) d->cached[at] = nullptr, wgpuTextureRelease(built);
        d->keeping.clear();
    }
    const size_t one = d->target ? 4 * (size_t)wgpuTextureGetWidth(d->target) * wgpuTextureGetHeight(d->target) : 0;
    for (auto& [at, texture] : d->cached) {
        if (texture) s.engine->destroy(texture);
        cache_bytes -= one;
    }
    d->cached.clear();
    d->ahead.clear();
    // Released on the driver thread, after Filament has taken and released them.
    interop::on_driver(s.engine, [built = std::move(d->cachedTextures)] { for (WGPUTexture t : built) wgpuTextureRelease(t); });
    d->cachedTextures.clear();
    d->shownAt = -1;
    ++d->keepAge;
    if (d->look) d->look->setParameter("picture", d->texture, TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
}

// Takes the cached frames that the driver thread made since the last call and makes them Filament
// textures. Main thread.
static void cache_take(Stage& s, Canvas2D* d) {
    std::lock_guard<std::mutex> hold(d->keepingLock);
    for (auto& [frame, built] : d->keeping) {
        d->cached[frame] = Texture::Builder().width(wgpuTextureGetWidth(built)).height(wgpuTextureGetHeight(built)).levels(1).sampler(Texture::Sampler::SAMPLER_2D)
                             .format(Texture::InternalFormat::RGBA8).usage(Texture::Usage::SAMPLEABLE).import((intptr_t)built).build(*s.engine);
        d->cachedTextures.push_back(built);
    }
    d->keeping.clear();
}
// Uploads a frame read from disk. Driver thread. The frame goes into the texture the canvas draws
// into if `shown`, meaning it is what is displayed now, and into a texture of its own if `keep`,
// which caches it. `age` is the keepAge when the work was requested. If it has changed since, the
// copy is released instead of cached.
static void cache_put(Stage& s, Canvas2D* d, int at, const std::vector<uint8_t>& pixels, bool shown, bool keep, int age) {
    const uint32_t w = wgpuTextureGetWidth(d->target), h = wgpuTextureGetHeight(d->target);
    const WGPUDevice device = (WGPUDevice)interop::device(s.engine);
    WGPUTextureDescriptor like{};
    like.size = {w, h, 1};
    like.format = wgpuTextureGetFormat(d->target);
    like.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst | WGPUTextureUsage_CopySrc;
    like.dimension = WGPUTextureDimension_2D;
    like.mipLevelCount = 1;
    like.sampleCount = 1;
    const WGPUTexture copy = keep ? wgpuDeviceCreateTexture(device, &like) : nullptr;
    WGPUTexelCopyBufferLayout rows{};
    rows.bytesPerRow = 4 * w, rows.rowsPerImage = h;
    for (WGPUTexture t : {shown ? d->target : nullptr, copy}) {
        if (!t) continue;
        WGPUTexelCopyTextureInfo to{};
        to.texture = t;
        wgpuQueueWriteTexture(wgpuDeviceGetQueue(device), &to, pixels.data(), pixels.size(), &rows, &like.size);
    }
    if (shown) d->targetAt = at;
    if (!copy) return;
    std::lock_guard<std::mutex> hold(d->keepingLock);
    if (age == d->keepAge) d->keeping.push_back({at, copy});
    else wgpuTextureRelease(copy);
}
// Draws the paints of a sketch onto the canvas of `d`.
static void sketch_draw(Canvas2D* d, const std::vector<double>& paints);
// Has ThorVG draw frame `at` into the texture the canvas draws into. Driver thread. If `keep`, also
// copies the frame on the GPU to a texture of its own that caches it. If `file` does not exist yet,
// also writes the frame to disk. If `paints` is not null, draws the sketch from them instead of the
// animation. `age` is as in cache_put.
static void cache_draw(Stage& s, Canvas2D* d, int at, bool keep, const std::filesystem::path& file, int age, const std::vector<double>* paints = nullptr) {
    if (paints) sketch_draw(d, *paints), d->targetAt = at;
    else if (d->film->frame(d->fromFrame + (float)at) == tvg::Result::Success || d->targetAt != at) {
        // The 3D layers have sheets of their own and are not drawn flat here.
        for (uint32_t id : d->deep)
            if (const tvg::Paint* one = d->film->picture()->paint(id)) const_cast<tvg::Paint*>(one)->visible(false);
        d->canvas->update();
        d->canvas->draw(true), d->stale = true;
        d->canvas->sync();
        d->targetAt = at;
    }
    std::error_code e;
    const bool toDisk = d->look && !file.empty() && !std::filesystem::exists(file, e);
    if (!keep && !toDisk) return;
    const WGPUDevice device = (WGPUDevice)interop::device(s.engine);
    WGPUCommandEncoder encoder = wgpuDeviceCreateCommandEncoder(device, nullptr);
    WGPUTexture copy = nullptr;
    if (keep) {
        WGPUTextureDescriptor like{};
        like.size = {wgpuTextureGetWidth(d->target), wgpuTextureGetHeight(d->target), 1};
        like.format = wgpuTextureGetFormat(d->target);
        like.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst | WGPUTextureUsage_CopySrc;
        like.dimension = WGPUTextureDimension_2D;
        like.mipLevelCount = 1;
        like.sampleCount = 1;
        copy = wgpuDeviceCreateTexture(device, &like);
        WGPUTexelCopyTextureInfo from{}, to{};
        from.texture = d->target, to.texture = copy;
        wgpuCommandEncoderCopyTextureToTexture(encoder, &from, &to, &like.size);
    }
    CacheReadBack* back = toDisk ? cache_read_back(device, encoder, copy ? copy : d->target, file) : nullptr;
    WGPUCommandBuffer commands = wgpuCommandEncoderFinish(encoder, nullptr);
    wgpuQueueSubmit(wgpuDeviceGetQueue(device), 1, &commands);
    wgpuCommandBufferRelease(commands);
    wgpuCommandEncoderRelease(encoder);
    if (back) cache_map(back);
    if (!copy) return;
    std::lock_guard<std::mutex> hold(d->keepingLock);
    if (age == d->keepAge) d->keeping.push_back({at, copy});
    // What the layer draws changed while this frame was drawn.
    else wgpuTextureRelease(copy);
}

// Shows the animation `seconds` from its start, for the next frame. After its end it holds the last
// frame. The time is rounded to the frames of the file, as After Effects plays it, so a time within
// the frame already drawn draws nothing again. ThorVG's frame() reports when the frame is the same.
// This is the advice of the ThorVG author for Lottie on a GPU (godotengine/godot#91580). A frame
// drawn once is shown again from the cache, on the GPU or on disk.
// Counts how each frame was shown: from the GPU cache, from disk, or freshly rendered. For
// diagnostics.
static std::atomic<long> films_cached{0}, films_disk{0}, films_rendered{0};
static void canvas_at(Stage& s, Canvas2D* d, float seconds) {
    const int at = (int)std::floor(std::min(seconds / d->seconds * d->frames, d->frames - 1.f) + 1e-3f);
    if (at == d->shownAt) return;
    d->shownAt = at;
    const TextureSampler smooth(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR);
    cache_take(s, d);
    // Cached on the GPU: show it.
    if (const auto k = d->cached.find(at); k != d->cached.end() && k->second) {
        if (d->look) d->look->setParameter("picture", k->second, smooth);
        ++films_cached;
        return;
    }
    if (d->look) d->look->setParameter("picture", d->texture, smooth);
    const bool keep = d->look && d->cached.find(at) == d->cached.end() && cache_bytes < cache_most;
    // Reserves the entry so the frame is cached only once. It is filled when the driver thread is
    // done.
    if (keep) d->cached[at] = nullptr, cache_bytes += cache_one(d);
    const std::filesystem::path file = cache_file(d, at);
    auto pixels = std::make_shared<std::vector<uint8_t>>();
    // Cached on disk: upload it as it is instead of drawing it.
    if (d->look && cache_read(file, *pixels, cache_one(d)))
        ++films_disk, interop::on_driver(s.engine, [&s, d, at, pixels, keep, age = d->keepAge.load()] { cache_put(s, d, at, *pixels, true, keep, age); });
    else {
        std::shared_ptr<std::vector<double>> paints;
        if (d->sketch) paints = std::make_shared<std::vector<double>>(d->sketch(at, d->sketchAt)), d->sketchAt = at;
        ++films_rendered, interop::on_driver(s.engine, [&s, d, at, keep, file, paints, age = d->keepAge.load()] { cache_draw(s, d, at, keep, file, age, paints.get()); });
    }
}

// While the user is idle, caches a few frames after the one shown before they are asked for, as
// Final Cut Pro renders when the user stops, and as DaVinci Resolve's Smart Cache and After
// Effects' Cache Frames When Idle do. Each frame is read from disk if it is there, and otherwise
// drawn into the texture the canvas draws into, which is free while the frame shown comes from the
// cache. `many` is the most frames to start. Returns how many were started; 0 means nothing more
// can be done now.
static int frames_ahead(Stage& s, Canvas2D* d, int many) {
    if (!d->look || !d->film || d->frames <= 1.f || d->shownAt < 0 || !d->target) return 0;
    cache_take(s, d);
    const auto now = d->cached.find(d->shownAt);
    // The frame shown does not yet come from the cache, so the texture the canvas draws into is in
    // use.
    if (now == d->cached.end() || !now->second) return 0;
    d->look->setParameter("picture", now->second, TextureSampler(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR));
    const int frames = (int)d->frames;
    int begun = 0;
    std::error_code e;
    for (int i = 1; i < frames && begun < many; ++i) {
        const int at = (d->shownAt + i) % frames;
        if (d->cached.count(at) || d->ahead.count(at)) continue;
        const std::filesystem::path file = cache_file(d, at);
        const bool keep = cache_bytes + cache_one(d) <= cache_most;
        const bool onDisk = !file.empty() && std::filesystem::exists(file, e);
        // There is no room on the GPU and the frame is on disk already, so there is nothing to do.
        if (!keep && (onDisk || file.empty())) continue;
        if (keep) d->cached[at] = nullptr, cache_bytes += cache_one(d);
        // Only onto disk. Not asked again while it is written.
        else d->ahead.insert(at);
        auto pixels = std::make_shared<std::vector<uint8_t>>();
        if (onDisk && cache_read(file, *pixels, cache_one(d)))
            interop::on_driver(s.engine, [&s, d, at, pixels, age = d->keepAge.load()] { cache_put(s, d, at, *pixels, false, true, age); });
        else
            interop::on_driver(s.engine, [&s, d, at, keep, file, age = d->keepAge.load()] { cache_draw(s, d, at, keep, file, age); });
        ++begun;
    }
    return begun;
}

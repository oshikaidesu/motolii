#include "document/evaluate/evaluate_clipping.h"

#include <filament/MaterialInstance.h>
#include <filament/Scene.h>
#include <math/mat4.h>
#include <math/vec4.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "document/document.h"
#include "document/edit/arrange.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/material.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/place.h"
#include "document/evaluate/value_at.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::MaterialInstance;
using filament::Scene;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// Returns the top layer of each group made to mask, by the group's Null.
std::map<int, int> mask_group_tops(Doc& d, const std::vector<int>& lie) {
  std::map<int, int> tops;
  for (int layer : lie)
    if (const int g = (int)std::lround(doc_number(d, layer, "parent", 0, 0));
        g > 0)
      // The last layer laid in the group is its top.
      if (const std::string& how = doc_word(d, g, "group_mask");
          how == "mask" || how == "exclude")
        tops[g] = layer;
  return tops;
}

// Stops a material from being cut. With `there` true the material still
// exists, so it is also told to stop using its matte. A material that was
// made again is gone.
void unmatte(Stage& s, MaterialInstance* look, bool there) {
  if (!look) return;
  std::erase_if(s.cuts, [&](const Stage::Cut& c) { return c.look == look; });
  if (there) look->setParameter("matteUse", float4{0.f});
}

// Releases the matte of a layer that is no longer cut.
void matte_released(Stage& s, DocOnStage::Cut& cut, MaterialInstance* own) {
  std::erase_if(s.cuts,
                [&](const Stage::Cut& c) { return c.look == cut.look; });
  if (cut.look == own) cut.look->setParameter("matteUse", float4{0.f});
  cut.look = nullptr, cut.from = 0, cut.by = nullptr;
  Scene* sc = s.mattes[(size_t)cut.matte].scene;
  doc_unshape(s, [sc](const Stage::Renderable& made) {
    return sc->hasEntity(made.thing);
  });
}

// Cuts a layer by the image of the layer `by` when that layer clips it and is a
// flat layer, and stops cutting it that way when not. Returns true when the
// layer is cut by that image, and false when a scissor rectangle is to clip it.
bool layer_matted(Doc& d, int layer, DocShownLayer& t, int by, bool clipped,
                  double invert, double now) {
  Stage& s = *d.stage;
  // When the clipping layer is a flat layer drawn by ThorVG, the layer is cut
  // by that layer's own image, like an After Effects alpha matte. Otherwise
  // it is cut by the upright box of what the clipping layer covers.
  const DocShownLayer* const a = clipped ? &d.on_stage.shown[by] : nullptr;
  // A solid can be cut too, through its own material.
  const bool shaped = a && a->drawn && (t.drawn || t.video || t.look);
  DocOnStage::Cut& cut = d.on_stage.cuts[layer];
  MaterialInstance* const base = t.video   ? t.video->look
                                 : t.drawn ? t.drawn->look
                                           : t.look;
  // With effects of its own, the sheet they made is cut after them, as After
  // Effects cuts a layer by its matte once its effects are applied.
  const auto fx = d.effects.layerFx.find(layer);
  MaterialInstance* const own =
      fx != d.effects.layerFx.end() && fx->second.look && !fx->second.solid
          ? fx->second.look
          : base;
  // A key describing how the layer is cut. It is set only for a layer that is
  // cut.
  const std::string how =
      shaped
          ? doc_word(d, layer, "clip_matte") + " " + std::to_string(invert) +
                " " + std::to_string(doc_number(d, layer, "clip_feather", 0, 0))
          : std::string();
  // When the clipping layer or the way of cutting changed, the matte takes
  // the shape of that layer's image, at that layer's place.
  if (shaped && (cut.from != by || cut.by != a->drawn || cut.how != how)) {
    // Release what cut the material before.
    unmatte(s, cut.look, cut.look == base || cut.look == own);
    if (cut.matte >= 0) {
      Scene* sc = s.mattes[(size_t)cut.matte].scene;
      doc_unshape(s, [sc](const Stage::Renderable& made) {
        return sc->hasEntity(made.thing);
      });
    }
    cut.matte =
        matte(s, a->drawn->sheet, {mat4f(doc_place(d, by, now))},
              a->drawn->texture ? a->drawn->texture : white_point(s),
              doc_word(d, layer, "clip_matte") == "luma", 1.f, cut.matte);
    cut.from = by, cut.by = a->drawn, cut.look = nullptr, cut.how = how;
  }
  if (shaped && cut.look != own && own && cut.matte >= 0) {
    // The material was made again, or its effects came or went. Release what
    // was cut before.
    unmatte(s, cut.look, false);
    unmatte(s, base, base && base != own),
        unmatte(s, t.drawn ? t.drawn->edgeLook : nullptr, own != base);
    matted(s, own, cut.matte, invert < 0.5,
           (float)doc_number(d, layer, "clip_feather", 0, 0)),
        cut.look = own;
    // The edge material is cut too.
    if (own == base && t.drawn && t.drawn->edgeLook)
      matted(s, t.drawn->edgeLook, cut.matte, invert < 0.5,
             (float)doc_number(d, layer, "clip_feather", 0, 0));
  }
  if (!shaped && cut.look) matte_released(s, cut, own);
  return shaped;
}

// Clips a layer to `box`, the upright rectangle its clipping layer covers, with
// Filament's scissor, or stops clipping it. A layer cut by an image (`shaped`)
// needs no scissor.
void layer_scissored(Stage& s, DocShownLayer& t, bool shaped, bool clipped,
                     const double* box) {
  if (shaped) {
    if (t.clipped)
      doc_material_instances(
          s, t, [](MaterialInstance* look) { look->unsetScissor(); }),
          t.clipped = false;
  } else if (clipped || t.clipped) {
    const uint32_t left = (uint32_t)std::clamp(box[0], 0.0, (double)s.w),
                   bottom = (uint32_t)std::clamp(
                       (double)s.h - (box[1] + box[3]), 0.0, (double)s.h);
    doc_material_instances(s, t, [&](MaterialInstance* look) {
      if (clipped)
        look->setScissor(left, bottom,
                         (uint32_t)std::lround(std::max(box[2], 0.0)),
                         (uint32_t)std::lround(std::max(box[3], 0.0)));
      else
        look->unsetScissor();
    });
    t.clipped = clipped;
  }
}

// Clips one layer by the top of its mask group, or by `before`, the layer
// shown before it.
void layer_clipped(Doc& d, int layer, DocShownLayer& t,
                   const std::map<int, int>& tops, int before, double now) {
  double box[4] = {0, 0, 0, 0};
  const int group = (int)std::lround(doc_number(d, layer, "parent", 0, 0));
  const auto top = tops.find(group);
  // True for a layer in a mask group other than its top. The top cuts it.
  const bool grouped = top != tops.end() && top->second != layer;
  // The group's top is only a shape and is not seen, as in Alight Motion.
  if (top != tops.end() && top->second == layer) {
    if (MaterialInstance* look = t.video   ? t.video->look
                                 : t.drawn ? t.drawn->look
                                           : nullptr)
      look->setParameter("opacity", 0.f);
    if (t.drawn && t.drawn->edgeLook)
      t.drawn->edgeLook->setParameter("opacity", 0.f);
  }
  const int by = grouped ? top->second : before;
  const double invert =
      grouped ? (doc_word(d, group, "group_mask") == "exclude" ? 1.0 : 0.0)
              : doc_number(d, layer, "clip_invert", 0, 0);
  const bool clipped = t.in && by &&
                       (grouped || doc_number(d, layer, "clip", 0, 0) > 0.5) &&
                       doc_covers(d, by, now, box);
  const bool shaped = layer_matted(d, layer, t, by, clipped, invert, now);
  layer_scissored(*d.stage, t, shaped, clipped, box);
}

}  // namespace

// A clipped layer is seen only inside the frame of the layer before it. This
// uses Filament's scissor on the layer's materials, set to the rectangle that
// the previous layer covers now. When that layer is turned or leaning, the
// rectangle is the upright box around it.
//
// A group made to mask, through its Null's group_mask as in Alight Motion's
// Group and Mask and Group and Exclude, works the same way. Its top layer is
// the shape and is not seen itself. The other layers in the group are seen
// inside it, or outside it to exclude.
void evaluate_clipping(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  const double now = evaluation.now;
  const std::vector<int>& lie = evaluation.lie;
  const std::map<int, int> tops = mask_group_tops(d, lie);
  int before = 0;
  for (int layer : lie) {
    const auto found = d.on_stage.shown.find(layer);
    if (found == d.on_stage.shown.end()) continue;
    DocShownLayer& t = found->second;
    layer_clipped(d, layer, t, tops, before, now);
    if (t.in) before = layer;
  }
}

}  // namespace motolii

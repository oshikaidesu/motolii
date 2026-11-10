#include "document/evaluate/evaluate_materials.h"

#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <string>

#include "community/playcanvas/splatfx.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/material.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/scripts/scripts.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::MaterialInstance;
using filament::RenderableManager;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;

// When the 3D box opens or shuts, update the deep parameter and the depth
// settings of the layer's material and of its copies' materials.
void evaluate_box(Doc& d, DocShownLayer& t, bool open, bool solid) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->boxed.z > 0.f && open != t.drawn->open) {
    t.drawn->open = open;
    const float4 box{t.drawn->boxed, open ? 1.f : 0.f};
    t.drawn->look->setParameter("deep", box),
        t.drawn->look->setDepthCulling(solid),
        t.drawn->look->setDepthWrite(solid);
    for (const Stage::Renderable& made : s.renderables)
      if (const auto own = d.copy_materials.looks.find(made.thing.getId());
          made.of == t.drawn->sheet && own != d.copy_materials.looks.end())
        own->second->setParameter("deep", box),
            own->second->setDepthCulling(solid),
            own->second->setDepthWrite(solid);
  }
}

// Bevel, in the box's units and as far across the face as it is deep in the
// world. The default depth of 12 points has no outside source. The After
// Effects default of 2 is hardly visible on a title.
void evaluate_bevel(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->edge[0]) {
    Canvas2D& drawn = *t.drawn;
    const float told = (float)(doc_number(d, layer, "bevel_depth", now, 12) /
                               t.units),
                z = (float)doc_literal(d, layer, "scale_z", now, 1);
    const float wide = (float)doc_literal(d, layer, "scale_x", now, 1),
                through = z != 0.f ? told * wide / std::fabs(z) : 0.f;
    // The Step bevel on text with strokes has one stair per stroke band, each
    // as wide as the band. Bevel Depth is the height.
    const bool banded = doc_bevel(d, layer) == 5 && drawn.bands.w > 0.f;
    const float most = banded ? drawn.bands[(int)drawn.bands.w - 1] : 1.f;
    const float across =
        banded ? most * 2.f * drawn.boxed.x / (float)drawn.edgeW : told;
    const float4 cut{across, std::min(through, drawn.boxed.z),
                     told > 0.f ? (float)doc_bevel(d, layer) : 0.f,
                     wide != 0.f ? std::fabs(z / wide) : 1.f};
    const float4 stairs =
        banded ? float4{drawn.bands.x / most, drawn.bands.y / most,
                        drawn.bands.z / most, drawn.bands.w}
               : float4{0.f};
    drawn.look->setParameter("deepBevel", cut),
        drawn.look->setParameter("deepSteps", stairs);
    for (const Stage::Renderable& made : s.renderables)
      if (const auto own = d.copy_materials.looks.find(made.thing.getId());
          made.of == drawn.sheet && own != d.copy_materials.looks.end())
        own->second->setParameter("deepBevel", cut),
            own->second->setParameter("deepSteps", stairs);
    const int reach =
        (int)std::ceil(across * (float)drawn.edgeW / (2.f * drawn.boxed.x));
    if (drawn.stale || reach > drawn.edgeReach)
      drawn.edgeReach = std::max(reach, drawn.edgeReach),
      edge_ask(s, &drawn, drawn.edgeReach);
  }
}

// Surface values of a lit solid, with the same defaults as other solids.
void evaluate_lit_surface(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->inLight) {
    const float3 surface{(float)doc_number(d, layer, "metallic", now, 0.08),
                         (float)doc_number(d, layer, "roughness", now, 0.6),
                         (float)doc_number(d, layer, "reflectance", now, 0.5)};
    t.drawn->look->setParameter("surface", surface);
    for (const Stage::Renderable& made : s.renderables)
      if (const auto own = d.copy_materials.looks.find(made.thing.getId());
          made.of == t.drawn->sheet && own != d.copy_materials.looks.end())
        own->second->setParameter("surface", surface);
  }
}

// The material the layer's sheet is given, with its parameters as they are
// now; see flat.mat and doc_sheet_material.
void evaluate_sheet_material(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (const std::string material =
          t.drawn || t.video ? doc_sheet_material(d, layer) : "";
      !material.empty()) {
    const auto at = [&](const char* name, double usual) {
      return (float)doc_number(d, layer, name, now, usual);
    };
    const float vivid = at("vivid", 1.3);
    const float4 coat{material == "glass" ? vivid : at("clear_coat", 0),
                      at("clear_coat_roughness", 0), at("sheen", 0),
                      at("anisotropy", 0)};
    const float4 glass{at("ior", 1.5), at("thickness", 0.5),
                       at("dispersion", 0.1), at("swim", 0.5)};
    const float dark = material == "bubble" ? vivid : at("dark", 4);
    const float3 surface{at("metallic", 0.08), at("roughness", 0.6),
                         at("reflectance", 0.5)};
    doc_parts(
        s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
          for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
            if (MaterialInstance* look = faces.getMaterialInstanceAt(one, part);
                look->getMaterial()->hasParameter("wearGlass")) {
              look->setParameter("wear", coat),
                  look->setParameter("wearGlass", glass),
                  look->setParameter("wearDark", dark);
              // For a video layer the surface values are set here, as for a
              // drawn sheet above.
              if (t.video) look->setParameter("surface", surface);
            }
        });
  }
}

// After Effects' Bevel, Side and Back colors and their Metal. A part with
// no value looks like the front.
void evaluate_part_colours(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (t.drawn && t.drawn->boxed.z > 0.f) {
    float4 colour[3], surface[3];
    const float3 front{(float)doc_number(d, layer, "metallic", now, 0.08),
                       (float)doc_number(d, layer, "roughness", now, 0.6),
                       (float)doc_number(d, layer, "reflectance", now, 0.5)};
    for (int p = 0; p < 3; ++p) {
      const std::string part = p == 0   ? "bevel_"
                               : p == 1 ? "side_"
                                        : "back_",
                        word = doc_word(d, layer, (part + "color").c_str());
      const long hex =
          word.size() == 6 ? std::strtol(word.c_str(), nullptr, 16) : 0;
      colour[p] = float4{
          (float)((hex >> 16) & 255) / 255.f, (float)((hex >> 8) & 255) / 255.f,
          (float)(hex & 255) / 255.f, word.size() == 6 ? 1.f : 0.f};
      surface[p] =
          float4{(float)doc_number(d, layer, (part + "metallic").c_str(), now,
                                   front.x),
                 (float)doc_number(d, layer, (part + "roughness").c_str(), now,
                                   front.y),
                 front.z, 0.f};
    }
    t.drawn->look->setParameter("partColour", colour, 3),
        t.drawn->look->setParameter("partSurface", surface, 3);
    for (const Stage::Renderable& made : s.renderables)
      if (const auto own = d.copy_materials.looks.find(made.thing.getId());
          made.of == t.drawn->sheet && own != d.copy_materials.looks.end())
        own->second->setParameter("partColour", colour, 3),
            own->second->setParameter("partSurface", surface, 3);
  }
}

void evaluate_splat(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  if (t.grains && t.look)
    t.look->setParameter("dissolve",
                         (float)doc_number(d, layer, "dissolve", now, 0)),
        t.look->setParameter("grain",
                             (float)doc_number(d, layer, "grain", now, 1));
  // The effect of a splat layer: its uniforms are evaluated at the layer's
  // own time. The parameters come from the document, then the effect's own
  // updateEffect runs.
  if (t.grains && t.look && t.splatFx) {
    const auto said = t.splatFx->uniforms(
        std::max(0.0, now - doc_number(d, layer, "start", 0, 0)), 1.0 / 60.0,
        [&](const std::string& parameter, double usual) {
          return doc_number(
              d, layer, doc_screen_parameter(t.splatFxFile, parameter).c_str(),
              now, usual);
        });
    for (const auto& [n, f] : said) {
      if (f.size() == 1)
        t.look->setParameter(n.c_str(), f[0]);
      else if (f.size() == 2)
        t.look->setParameter(n.c_str(), float2{f[0], f[1]});
      else if (f.size() == 3)
        t.look->setParameter(n.c_str(), float3{f[0], f[1], f[2]});
      else if (f.size() >= 4)
        t.look->setParameter(n.c_str(), float4{f[0], f[1], f[2], f[3]});
    }
    // When the effect finishes, switch to the plain material, as PlayCanvas
    // takes the shader off. If time goes back before the end, switch back to
    // the effect's material.
    if (t.splatPlain && t.splatFx->finished() != t.splatDone) {
      t.splatDone = t.splatFx->finished();
      doc_parts(s, t,
                [&](RenderableManager& faces, RenderableManager::Instance one) {
                  faces.setMaterialInstanceAt(
                      one, 0, t.splatDone ? t.splatPlain : t.look);
                });
    }
  }
}

// The opacity includes AbsentMotion's Pulse Opacity and the opacity of the
// groups the layer is in.
LayerOpacity evaluate_opacity(Doc& d, int layer, DocShownLayer& t, double now) {
  const double whole = doc_number(d, layer, "opacity", now, 1) *
                       doc_absent_opacity(d, layer, now) *
                       doc_group_opacity(d, layer, now);
  const auto fxOf = d.effects.layerFx.find(layer);
  // With effects of its own, opacity is applied after the effects, on the
  // effects sheet. After Effects renders a layer's masks, effects and then
  // transform in that order.
  const bool sheetClear =
      fxOf != d.effects.layerFx.end() && fxOf->second.look &&
      fxOf->second.look->getMaterial()->hasParameter("opacity");
  if (sheetClear) fxOf->second.look->setParameter("opacity", (float)whole);
  const double ownClear = sheetClear ? 1.0 : whole;
  if (MaterialInstance* look = t.video   ? t.video->look
                               : t.drawn ? t.drawn->look
                                         : nullptr)
    look->setParameter("opacity", (float)ownClear);
  if (t.drawn && t.drawn->edgeLook)
    t.drawn->edgeLook->setParameter("opacity", (float)ownClear);
  return {sheetClear, ownClear};
}

// How much the layer lights itself now: emissive, plus a share of the glow
// opacity that the bloom picks up when it is past 1. This applies to a flat
// layer's sheet and a solid's own faces.
void evaluate_glow(Doc& d, int layer, DocShownLayer& t, double now) {
  Stage& s = *d.stage;
  const float shine =
      (float)doc_number(d, layer, "emissive", now, 0) +
      (doc_word(d, layer, "glow").empty()
           ? 0.f
           : 0.35f * (float)doc_number(d, layer, "glow_opacity", now, 1));
  doc_material_instances(s, t, [&](MaterialInstance* look) {
    if (look->getMaterial()->hasParameter("glowing"))
      look->setParameter("glowing", shine);
  });
}

}  // namespace motolii

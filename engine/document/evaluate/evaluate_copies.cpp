#include "document/evaluate/evaluate_copies.h"

#include <filament/Camera.h>
#include <filament/Color.h>
#include <filament/Engine.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <sstream>
#include <string>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/quickjs/script.h"
#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluate_materials.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "media/video_layer.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_stage.h"

namespace motolii {

namespace math = filament::math;
using filament::ACCURATE;
using filament::Color;
using filament::MaterialInstance;
using filament::sRGBColor;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// Gives the copies of a flat layer their blend order: the farthest from the
// camera is drawn first. `far` is the distance of each copy.
void copies_ordered_by_distance(Stage& s, const DocShownLayer& t, const Mesh* m,
                                const std::vector<float>& far) {
  std::vector<size_t> order(far.size());
  for (size_t k = 0; k < order.size(); ++k) order[k] = k;
  std::stable_sort(order.begin(), order.end(),
                   [&](size_t a, size_t b) { return far[a] > far[b]; });
  std::vector<uint16_t> place_of(far.size());
  for (size_t k = 0; k < order.size(); ++k)
    place_of[order[k]] =
        (uint16_t)(k * 127 / std::max<size_t>(1, order.size() - 1));
  auto& faces = s.engine->getRenderableManager();
  for (const Stage::Renderable& made : s.renderables) {
    if (made.of != m || made.nth < 0 || (size_t)made.nth >= place_of.size())
      continue;
    const auto one = faces.getInstance(made.thing);
    for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
      faces.setBlendOrderAt(
          one, part, (uint16_t)(t.lies * 128 + place_of[(size_t)made.nth]));
  }
}

// Returns the colors of a layer's copy_fill, in linear RGB. A ramp has two or
// more.
std::vector<float3> copy_fill_ramp(Doc& d, int layer) {
  std::vector<float3> ramp;
  std::istringstream said(doc_word(d, layer, "copy_fill"));
  for (std::string one; said >> one;) {
    if (one == "none") break;
    const long rgb = std::strtol(one.c_str(), nullptr, 16);
    ramp.push_back(Color::toLinear<ACCURATE>(
        sRGBColor{float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255),
                         (float)(rgb & 255)} /
                  255.f}));
  }
  // With one colour, every copy uses it.
  if (ramp.size() == 1) ramp.push_back(ramp[0]);
  return ramp;
}

// What colors and fades the copies of one layer, worked out once for all of
// them.
struct CopyLooks {
  Doc& d;
  const int layer;
  // The layer as it is on the stage.
  const DocShownLayer& t;
  const double now;
  // The colors of the layer's copy_fill (copy_fill_ramp).
  const std::vector<float3>& ramp;
  // How many copies the layer has.
  const int n;
  // True when a behaviour gives each copy its own opacity, and its own place on
  // the ramp.
  const bool clearEach, pickEach;
  // The opacity of the last copy as a share of the layer's.
  const double fadeTo;
  // True when a staggered copy fades as late as it moves.
  const bool clearLate;
  // The opacity of the layer's own materials (LayerOpacity).
  const double ownClear;
};

// Colors one copy in `own`, its own material.
void copy_filled(const CopyLooks& looks, const Stage::Renderable& made,
                 MaterialInstance* own) {
  Doc& d = looks.d;
  const int layer = looks.layer;
  const DocShownLayer& t = looks.t;
  const double now = looks.now;
  const std::vector<float3>& ramp = looks.ramp;
  const int n = looks.n;
  const bool pickEach = looks.pickEach;
  const double fadeTo = looks.fadeTo;
  // Copies drawn together in one batch: set the ramp and where this
  // batch's first copy lies on it. flat.mat colours each copy.
  if (made.many) {
    float4 colours[8] = {};
    for (size_t k = 0; k < ramp.size() && k < 8; ++k)
      colours[k] = float4{ramp[k], 1.f};
    own->setParameter("ramp", colours, 8);
    own->setParameter(
        "rampOf",
        ramp.size() >= 2
            ? float4{(float)made.nth, (float)n,
                     (float)std::min<size_t>(ramp.size(), 8),
                     doc_word(d, layer, "copy_fill_way") == "cycle" ? 1.f : 0.f}
            : float4{0.f});
    if (ramp.size() < 2)
      own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});
    own->setParameter("copyFade",
                      float4{(float)fadeTo, (float)n, (float)made.nth,
                             fadeTo != 1 ? 1.f : 0.f});
  }
  // Copies drawn one by one. With copy_fill_way set to cycle, each copy
  // takes the ramp colours in turn. Otherwise the colour is picked
  // along the ramp in their order, or where the copy_fill_at behaviour
  // says, 0 for the first colour and 1 for the last. With no ramp the
  // layer's own wash is used, which also fills a shape cut into
  // triangles.
  else if (ramp.size() >= 2 && doc_word(d, layer, "copy_fill_way") == "cycle")
    own->setParameter("wash",
                      float4{ramp[(size_t)made.nth % ramp.size()], 1.f});
  else if (ramp.size() >= 2) {
    const math::double3 where{made.place[3].x, made.place[3].y,
                              made.place[3].z};
    const double order = n > 1 ? (double)made.nth / (double)(n - 1) : 0.0;
    const double pick =
        pickEach
            ? std::clamp(doc_given(d, doc_driven_by(d, layer, "copy_fill_at"),
                                   made.nth, n, now, order, &where),
                         0.0, 1.0)
            : order;
    const float along = (float)pick * (float)(ramp.size() - 1);
    const size_t i = std::min((size_t)along, ramp.size() - 2);
    own->setParameter("wash",
                      float4{mix(ramp[i], ramp[i + 1], along - (float)i), 1.f});
  } else
    own->setParameter("wash", t.drawn ? t.drawn->wash : float4{0.f});
}

// Returns the opacity of one copy before its own fade.
double copy_opacity(const CopyLooks& looks, const Stage::Renderable& made) {
  Doc& d = looks.d;
  const int layer = looks.layer;
  const double now = looks.now;
  const int n = looks.n;
  const bool clearEach = looks.clearEach, clearLate = looks.clearLate;
  const double ownClear = looks.ownClear;
  const math::double3 here{made.place[3].x, made.place[3].y, made.place[3].z};
  const int clearBy = doc_driven_by(d, layer, "opacity");
  // A staggered copy's opacity is delayed by its stagger. Otherwise a
  // behaviour that drives opacity decides, and a relation chooses by
  // the layer's place among its layers. With neither, the layer's
  // opacity is used.
  const double opacity =
      clearLate
          ? ownClear / std::max(doc_number(d, layer, "opacity", now, 1), 1e-6) *
                doc_number(d, layer, "opacity",
                           now - doc_delay(d, layer, made.nth), 1)
      : !clearEach ? ownClear
      : doc_among(doc_relations, doc_word(d, clearBy, "file"))
          ? std::clamp(doc_literal(d, layer, "opacity", now, 1), 0.0, 1.0)
          : std::clamp(
                doc_given(d, clearBy, made.nth, n, now,
                          doc_number(d, layer, "opacity", now, 1), &here),
                0.0, 1.0);
  return opacity;
}

// The edge's own material: a frame alone, filled with nothing, is
// coloured per copy as its fill would be, and gets the copy's
// opacity.
void copy_edge_looked(const CopyLooks& looks, const Stage::Renderable& made,
                      MaterialInstance* own, double opacity, double clear) {
  Doc& d = looks.d;
  const DocShownLayer& t = looks.t;
  const std::vector<float3>& ramp = looks.ramp;
  auto& faces = d.stage->engine->getRenderableManager();
  if (t.drawn && t.drawn->edgeLook && !made.many) {
    const auto one = faces.getInstance(made.thing);
    if (faces.getPrimitiveCount(one) > 1) {
      MaterialInstance*& edge = d.copy_materials.edges[made.thing.getId()];
      if (!edge)
        edge = MaterialInstance::duplicate(t.drawn->edgeLook),
        faces.setMaterialInstanceAt(one, 1, edge);
      if (t.drawn->hollow && ramp.size() >= 2) {
        edge->setParameter("wash", own->getParameter<float4>("wash"));
      }
      edge->setParameter("opacity",
                         (float)(opacity * std::clamp(clear, 0.0, 1.0)));
    }
  }
}

}  // namespace

CopyPlaces evaluate_copy_places(Doc& d, int layer, double now) {
  CopyPlaces places;
  places.place = mat4f(doc_place(d, layer, now));
  // Each copy, the first included, is delayed as late as its order says and
  // placed as its expressions say.
  places.staggered = doc_staggered(d, layer, now);
  // A joining layer's copies lie between another layer's copies.
  places.joins = doc_number(d, layer, "connect", 0, 0) != 0.0
                     ? doc_joins(d, layer, now)
                     : std::vector<math::mat4>{};
  return places;
}

void evaluate_copies_placed(Doc& d, int layer, DocShownLayer& t, const Mesh* m,
                            double now, bool solid, const CopyPlaces& places) {
  Stage& s = *d.stage;
  const mat4f& place = places.place;
  const bool staggered = places.staggered;
  const std::vector<math::mat4>& joins = places.joins;
  if (t.solid)
    for (size_t nth = 0; nth < t.solid->asset->getAssetInstanceCount(); ++nth)
      solid_to(s, t.solid,
               nth || staggered
                   ? mat4f(doc_place(d, layer, now, 0, (int)nth, staggered))
                   : place,
               nth);
  else if (doc_number(d, layer, "connect", 0, 0) != 0.0)
    move(s, m, [&](int nth, const mat4f&) {
      return (size_t)nth < joins.size() ? mat4f(joins[(size_t)nth])
                                        : mat4f::scaling(float3{0.f});
    });
  else {
    // Distance of each copy from the camera. Copies further away are drawn
    // first, within the layer's own place.
    std::vector<float> far;
    const mat4f eye = mat4f(s.camera->getViewMatrix());
    const std::string fills = doc_word(d, layer, "copy_fill");
    // Copies coloured along their order are drawn in that order and not
    // sorted by distance.
    const bool flatLayer = !solid && (fills.empty() || fills == "none");
    // Copies drawn in one batch are sorted with the farthest first. Each
    // copy's own order does the same below.
    move(
        s, m,
        [&](int nth, const mat4f&) {
          const mat4f at =
              nth || staggered
                  ? mat4f(doc_place(d, layer, now, 0, nth, staggered))
                  : place;
          if ((size_t)nth >= far.size()) far.resize((size_t)nth + 1, 0.f);
          far[(size_t)nth] = -(eye * at[3]).z;
          return at;
        },
        flatLayer ? &eye : nullptr);
    if (far.size() > 1 && !solid && t.lies >= 0)
      copies_ordered_by_distance(s, t, m, far);
  }
}

// A solid whose sketch gives each copy a colour: each such copy gets a
// material of its own.
void evaluate_scripted_copy_colours(Doc& d, int layer, DocShownLayer& t,
                                    const Mesh* m) {
  Stage& s = *d.stage;
  if (const auto told = d.place_cache.scripted.find(layer);
      told != d.place_cache.scripted.end() && t.look && !t.drawn && !t.video) {
    auto& faces = s.engine->getRenderableManager();
    for (const Stage::Renderable& made : s.renderables) {
      if (made.of != m || made.matte || made.nth < 0 ||
          (size_t)made.nth >= told->second.copies.size() ||
          told->second.copies[(size_t)made.nth].colour < 0.0)
        continue;
      MaterialInstance*& own = d.copy_materials.looks[made.thing.getId()];
      if (!own)
        own = MaterialInstance::duplicate(t.look),
        faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
      const long hex = (long)told->second.copies[(size_t)made.nth].colour;
      own->setParameter(
          "color",
          float4{Color::toLinear<ACCURATE>(sRGBColor{
                     float3{(float)((hex >> 16) & 255),
                            (float)((hex >> 8) & 255), (float)(hex & 255)} /
                     255.f}),
                 1.f});
    }
  }
}

// Copies coloured along a ramp in their order each get a material of their
// own, initialised from the layer's material.
void evaluate_copy_looks(Doc& d, int layer, DocShownLayer& t, const Mesh* m,
                         double now, const LayerOpacity& layer_opacity) {
  Stage& s = *d.stage;
  const bool sheetClear = layer_opacity.sheetClear;
  const double ownClear = layer_opacity.ownClear;
  if (MaterialInstance* main = t.video   ? t.video->look
                               : t.drawn ? t.drawn->look
                                         : nullptr) {
    const std::vector<float3> ramp = copy_fill_ramp(d, layer);
    const std::vector<float2>& letters =
        t.drawn ? t.drawn->letters : std::vector<float2>{};
    // A script can give each copy its own opacity.
    const auto scripted = d.place_cache.scripted.find(layer);
    // AbsentMotion's repeat gives each copy its own opacity, for example the
    // far copies of a scatter field.
    const std::vector<AbsentCopy>& absent = doc_absent_copies(d, layer, now);
    const bool clears =
        (scripted != d.place_cache.scripted.end() &&
         std::any_of(scripted->second.copies.begin(),
                     scripted->second.copies.end(),
                     [](const ScriptCopy& c) { return c.opacity != 1.0; })) ||
        std::any_of(absent.begin(), absent.end(),
                    [](const AbsentCopy& c) { return c.alpha < 0.999; });
    // A behaviour can give each copy its own opacity or its own place on the
    // ramp.
    const bool clearEach = doc_driven_by(d, layer, "opacity") != 0,
               pickEach = doc_driven_by(d, layer, "copy_fill_at") != 0;
    // The last copy has this opacity and the first has the layer's, as in
    // After Effects' Repeater End Opacity.
    const double fadeTo =
        std::clamp(doc_number(d, layer, "copy_opacity_end", now, 1), 0.0, 1.0);
    // A staggered copy fades as late as it moves. GSAP's stagger applies
    // every value of a tween, and After Effects' range selector applies
    // Opacity together with the rest.
    const bool clearLate = !sheetClear &&
                           doc_number(d, layer, "stagger", 0, 0) > 0.0 &&
                           doc_key_times(d, layer, "opacity").size() > 1;
    if (ramp.size() < 2 && letters.empty() && !clears && !t.drivenLooks &&
        !clearEach && !pickEach && fadeTo == 1 && !clearLate)
      doc_copy_looks_off(d, m, main);
    else {
      auto& faces = s.engine->getRenderableManager();
      const int n = doc_members(d, layer);
      const CopyLooks looks{d,         layer,    t,      now,       ramp,    n,
                            clearEach, pickEach, fadeTo, clearLate, ownClear};
      for (const Stage::Renderable& made : s.renderables) {
        if (made.of != m || made.matte) continue;
        MaterialInstance*& own = d.copy_materials.looks[made.thing.getId()];
        if (!own)
          own = MaterialInstance::duplicate(main),
          faces.setMaterialInstanceAt(faces.getInstance(made.thing), 0, own);
        copy_filled(looks, made, own);
        // The copy's own letter.
        if ((size_t)made.nth < letters.size())
          own->setParameter("window",
                            float4{letters[(size_t)made.nth].x,
                                   letters[(size_t)made.nth].y, 1.f, 0.f});
        const double clear =
            (scripted != d.place_cache.scripted.end() &&
                     (size_t)made.nth < scripted->second.copies.size()
                 ? scripted->second.copies[(size_t)made.nth].opacity
                 : 1.0) *
            ((size_t)made.nth < absent.size() ? absent[(size_t)made.nth].alpha
                                              : 1.0);
        const double opacity = copy_opacity(looks, made);
        const double fade =
            n > 1 ? 1 + (fadeTo - 1) * (double)made.nth / (double)(n - 1) : 1.0;
        own->setParameter(
            "opacity", (float)(opacity * std::clamp(clear, 0.0, 1.0) * fade));
        copy_edge_looked(looks, made, own, opacity, clear);
        own->setParameter("glowing",
                          (float)doc_number(d, layer, "emissive", now, 0));
      }
    }
  }
}

}  // namespace motolii

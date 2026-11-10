// The parts of one layer's effects that moment_fx.cpp puts together: a solid
// prepared before the frame, its shell and stand, the sides and frame it is
// seen from, and how a layer reads what is under it.
#include <filament/TextureSampler.h>
#include <filament/Viewport.h>

#include <regex>

#include "community/three/solid_three.h"
#include "document/evaluate/material.h"
#include "document/evaluate/shown.h"
#include "document/scripts/scripts.h"
#include "stage/render/render_draw.h"

namespace motolii {

namespace math = filament::math;
using filament::Camera;
using filament::MaterialInstance;
using filament::RenderableManager;
using filament::RenderTarget;
using filament::Texture;
using filament::TextureSampler;
using filament::math::float2;
using filament::math::float3;
using filament::math::mat4f;

// Prepares a solid layer before the frame is rendered. Draws the layer square
// to its own face, runs its effects, and lays the result on the solid's faces
// where the solid lies.
void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e) {
  Stage& s = *d.stage;
  math::mat4 place;
  float2 half{0.5f};
  {
    // The render callback calls this while the frame is drawn, so lock the
    // document first.
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    place = doc_place(d, layer, d.stage->now), doc_half(d, layer, &half);
  }
  thing_fx_face(s, e, place, half);
  thing_fx_textures(s, e.st, e.view);
  // Shrink the layer's own sheet to nothing so that it is not shown.
  e.look->setParameter("place", mat4f::scaling(float3{0.f}));
  if (!e.solid || !e.solidLook) return;
  move(s, e.solid, [&](int, const mat4f&) { return mat4f(place); });
  const auto wrap = e.solidRepeat ? TextureSampler::WrapMode::REPEAT
                                  : TextureSampler::WrapMode::CLAMP_TO_EDGE;
  e.solidLook->setParameter(
      "image", thing_fx_seen(e.st),
      TextureSampler(TextureSampler::MinFilter::LINEAR,
                     TextureSampler::MagFilter::LINEAR, wrap));
}
// While the stage is drawn, puts the layer's effect image on its faces (on is
// true). When on is false, puts back the faces' original materials. Does
// nothing if the layer is not shown or is already in the requested state.
void doc_layer_shell(Doc& d, int layer, ThingFx& e, bool on) {
  const auto t = d.on_stage.shown.find(layer);
  if (t == d.on_stage.shown.end() || on != e.looks.empty()) return;
  size_t n = 0;
  doc_parts(*d.stage, t->second,
            [&](RenderableManager& faces, RenderableManager::Instance one) {
              for (size_t part = 0; part < faces.getPrimitiveCount(one);
                   ++part, ++n) {
                if (on)
                  e.looks.push_back(faces.getMaterialInstanceAt(one, part)),
                      faces.setMaterialInstanceAt(one, part, e.look);
                else if (n < e.looks.size() &&
                         faces.getMaterialInstanceAt(one, part) == e.look)
                  faces.setMaterialInstanceAt(one, part, e.looks[n]);
              }
            });
  if (!on) e.looks.clear();
}
// Computes how far the stage reaches from a standing layer along each side of
// the layer's face, and writes four values to sides: toward -x, +x, -y and +y
// of the layer's own axes, in layer units. The stage's corners are projected
// back onto the layer's plane. seen is the length in stage points of one layer
// unit where the layer lies. Each value is rounded up to a multiple of 256
// stage points, so the layer's image is made again only after the stage has
// moved that far. A face seen edge on reaches no further than three times the
// stage's longer side.
void doc_fx_sides(Doc& d, const math::mat4& place, double seen, double* sides) {
  const math::double3 x = normalize(place[0].xyz),
                      y = normalize(place[1].xyz - dot(place[1].xyz, x) * x);
  const math::double2 at = doc_seen(d, place[3].xyz),
                      across = doc_seen(d, place[3].xyz + x) - at,
                      up = doc_seen(d, place[3].xyz + y) - at;
  const double det = across.x * up.y - across.y * up.x, w = d.stage->w,
               h = d.stage->h;
  std::fill(sides, sides + 4, 0.0);
  if (std::fabs(det) < 1e-9 || seen <= 0.0) return;
  const math::double2 corners[4] = {{0, 0}, {w, 0}, {0, h}, {w, h}};
  for (const math::double2& q : corners) {
    const math::double2 v = q - at;
    const double a = (v.x * up.y - v.y * up.x) / det,
                 b = (across.x * v.y - across.y * v.x) / det;
    sides[0] = std::max(sides[0], -a), sides[1] = std::max(sides[1], a),
    sides[2] = std::max(sides[2], -b), sides[3] = std::max(sides[3], b);
  }
  const double most = 3.0 * std::max(w, h) / seen, step = 256.0 / seen;
  for (int i = 0; i < 4; ++i)
    sides[i] = std::ceil(std::min(sides[i], most) / step) * step;
}
// Prepares a standing layer before the frame is rendered. Reads its placement
// and scale under the document lock, then sets up its effect image.
void doc_layer_stand(Doc& d, int layer, ThingFx& e) {
  math::mat4 place;
  float2 half{0.5f};
  double seen = 0.0;
  {
    // The render callback calls this while the frame is drawn, so lock the
    // document first.
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    place = doc_shown_at(d, layer, d.stage->now), doc_half(d, layer, &half);
    const math::double2 a = doc_seen(d, place[3].xyz),
                        b = doc_seen(d, place[3].xyz +
                                            normalize(d.camera.facing[0].xyz));
    // Length in stage points of one layer unit where the layer lies, across the
    // camera's line of sight.
    seen = length(b - a);
    doc_fx_sides(d, place, seen, e.sides);
  }
  thing_fx_stand(*d.stage, e, place, half, seen);
}
// Writes where the layer lies on its effect image to frame, in the form
// doc_frame uses for the stage. A standing layer is in the middle of the image
// and upright. Returns false if the layer has no frame.
bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame) {
  if (!e.world) return doc_frame(d, layer, d.stage->now, frame);
  std::copy(e.own, e.own + 4, frame), frame[4] = 0;
  return true;
}
// Runs while the frame is rendered. Draws the effects of a solid layer. If the
// solid's file reads the image, also updates the solid from it, using the
// precision parameter (default 160).
void doc_layer_solid(Doc& d, int layer, ThingFx& e,
                     const ScreenNumbers& numbers) {
  Stage& s = *d.stage;
  thing_effects_draw(s, e.st, e.view, numbers);
  if (solid_reads(e.solidFile))
    thing_fx_cover(
        s, e,
        (int)(e.parameters.count("precision") ? e.parameters["precision"]
                                              : 160)),
        thing_fx_solid(s, e, true);
}
// Answers an AviUtl2 script's questions about the other layers (see
// engine/community/aviutl/aviutl_fx.h). The script's layers are the document's
// layers in stacking order, with the furthest back as layer 1. AviUtl2 draws
// layer 1 first and the higher layers over it (see doc_laid). box is the
// layer's box on the stage, and usual is the value to return when the layer has
// no number. The supported names are:
// - aviutl.layer: this layer's own number.
// - aviutl.layer_max: the number of layers.
// - aviutl.layerN[.name][@seconds]: the value of layer N, taken the given
// number of seconds from
//   its start, or now if there is no @seconds. This follows
//   obj.getvalue("layer1.x", time) in AviUtl2's script API. x and y are pixels
//   of the script's frame measured from its middle, as obj.x is. rz is the
//   rotation, alpha is the opacity, and time is the time from the layer's
//   start.
// - aviutl.groupN: the layer of the Nth group this layer is in, where 0 is the
// nearest. This
//   follows obj.getoption("group_info").
// Returns NaN, which the script sees as nil, if the layer does not exist or is
// not shown.
double doc_aviutl_asked(Doc& d, int layer, const double* box,
                        const std::string& name, double usual) {
  const std::vector<int>& laid = doc_laid(d);
  const auto layerOf = [&](int t) {
    const auto at = std::find(laid.begin(), laid.end(), t);
    return at == laid.end() ? NAN : (double)(at - laid.begin() + 1);
  };
  if (name == "aviutl.layer")
    return std::isnan(layerOf(layer)) ? usual : layerOf(layer);
  if (name == "aviutl.layer_max")
    return (double)std::max<size_t>(1, laid.size());
  std::smatch m;
  if (std::regex_match(name, m, std::regex(R"(aviutl\.group(\d+))"))) {
    int in = layer;
    for (int n = std::stoi(m[1]); in && n >= 0; --n)
      in = (int)doc_number(d, in, "parent", d.stage->now, 0);
    return in ? layerOf(in) : NAN;
  }
  if (!std::regex_match(
          name, m, std::regex(R"(aviutl\.layer(\d+)(?:\.(\w+))?(?:@(.+))?)")))
    return NAN;
  const size_t n = std::stoul(m[1]);
  if (n < 1 || n > laid.size()) return NAN;
  const int other = laid[n - 1];
  if (!m[2].matched) return 1;
  const double start = doc_number(d, other, "start", 0, 0),
               now = m[3].matched ? start + std::atof(m[3].str().c_str())
                                  : d.stage->now;
  const std::string what = m[2];
  if (what == "time") return now - start;
  double frame[8];
  if (!doc_frame(d, other, now, frame)) return NAN;
  const double ppp =
      (double)d.stage->view->getViewport().width / std::max(1, d.stage->w);
  if (what == "x") return (frame[0] - (box[0] + box[2]) / 2) * ppp;
  if (what == "y") return (frame[1] - (box[1] + box[3]) / 2) * ppp;
  if (what == "z" || what == "rx" || what == "ry" || what == "cx" ||
      what == "cy" || what == "cz")
    return 0;
  if (what == "rz") return frame[4];
  if (what == "alpha") return doc_number(d, other, "opacity", now, 1);
  if (what == "zoom") return 100;
  return NAN;
}

// Sets how a layer reads what is under it: the blend mode way, whether it fills
// with what is behind it (behind), and the image of what lies under it
// (picture). It is set on every material of the layer that has a blendWay
// parameter.
void doc_reading(Stage& s, DocShownLayer& t, float way, float behind,
                 Texture* picture) {
  const Camera& eye = s.view->getCamera();
  const mat4f seen = mat4f(eye.getProjectionMatrix() * eye.getViewMatrix());
  doc_parts(
      s, t, [&](RenderableManager& faces, RenderableManager::Instance one) {
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part)
          if (MaterialInstance* look = faces.getMaterialInstanceAt(one, part);
              look->getMaterial()->hasParameter("blendWay"))
            look->setParameter("blendWay", way),
                look->setParameter("behind", behind),
                look->setParameter("behindEye", seen),
                look->setParameter(
                    "backdrop", picture,
                    TextureSampler(TextureSampler::MinFilter::NEAREST,
                                   TextureSampler::MagFilter::NEAREST));
      });
}
// The same as doc_reading for a layer with effects. What such a layer lays on
// the stage is its sheet, so its blend mode is applied after its effects, as in
// After Effects, where a layer's blending mode comes after its effects.
void doc_sheet_reads(Doc& d, int layer, float way, Texture* picture) {
  const auto own = d.effects.layerFx.find(layer);
  if (own == d.effects.layerFx.end() || !own->second.look ||
      !own->second.look->getMaterial()->hasParameter("blendWay"))
    return;
  own->second.look->setParameter("blendWay", way);
  own->second.look->setParameter(
      "backdrop", picture,
      TextureSampler(TextureSampler::MinFilter::NEAREST,
                     TextureSampler::MagFilter::NEAREST));
}

}  // namespace motolii

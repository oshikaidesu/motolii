#include "document/evaluate/moment_fx.h"

#include <filament/TextureSampler.h>
#include <filament/Viewport.h>

#include <filesystem>

#include "community/three/solid_three.h"
#include "document/edit/arrange.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/shown.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "shelf/shelf_folders.h"
#include "stage/render/render_layers.h"

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

bool doc_holds_fx(Doc& d, int layer) {
  if (doc_word(d, layer, "shape") != "null") return false;
  return doc_fx_files(doc_fx_steps(d, layer));
}
bool doc_own_fx(Doc& d, int layer) {
  return doc_fx_files(doc_fx_steps(d, layer));
}
bool doc_layer_stands(Doc& d, int layer, ThingFx& e) {
  thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
  if (e.st.readsBehind || e.st.wide || !e.st.aviutl.empty() ||
      doc_holds_fx(d, layer))
    return false;
  for (const std::string& w : doc_fx_list(d, layer))
    if (solid_is(w) || points_is(w)) return false;
  const auto shown = d.on_stage.shown.find(layer);
  float2 half{0.f};
  float deep = 0.f;
  return shown != d.on_stage.shown.end() && !shown->second.solid &&
         doc_members(d, layer) == 1 && doc_half(d, layer, &half, &deep) &&
         deep == 0.f;
}
bool doc_layer_shows(Doc& d, int layer, ThingFx& e) {
  thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps(d, layer)));
  for (const std::string& w : doc_fx_list(d, layer))
    if (solid_is(w) || points_is(w)) return false;
  const auto shown = d.on_stage.shown.find(layer);
  float2 half{0.f};
  float deep = 0.f;
  return shown != d.on_stage.shown.end() && shown->second.space != 2 &&
         !e.st.readsBehind && !e.st.wide && e.st.aviutl.empty() &&
         (shown->second.solid ||
          (doc_half(d, layer, &half, &deep) && deep > 0.f));
}

void doc_layers_fx(Doc& d) {
  Stage& s = *d.stage;
  s.before.clear(), s.aim.clear(), s.after.clear(), d.effects.beforeOf.clear();
  // Pairs of negative depth and layer. Sorting them puts the deepest layers
  // first, so a layer's image is made before that of the group it lies in.
  std::vector<std::pair<int, int>> order;
  for (const auto& [layer, e] : d.effects.layerFx) {
    int deep = 0;
    for (int up = (int)doc_number(d, layer, "parent", 0, 0);
         up > 0 && deep < 64; up = (int)doc_number(d, up, "parent", 0, 0))
      ++deep;
    order.emplace_back(-deep, layer);
  }
  std::stable_sort(
      order.begin(), order.end(),
      [](const auto& a, const auto& b) { return a.first < b.first; });
  // Each layer is drawn alone into an image and its effects run on that image,
  // before the stage's own view. See engine/stage/layer_effects/layer_fx.h.
  for (const auto& [deep, layer] : order) {
    ThingFx& e = d.effects.layerFx.at(layer);
    thing_effects(s, e.st, doc_fx_join(doc_fx_steps(d, layer)));
    e.solidFile.clear();
    // If the fx names a solid's shape, the layer's image is laid on that solid.
    // If several are named, the last one is used.
    for (const std::string& w : doc_fx_list(d, layer))
      if (solid_is(w)) e.solidFile = w;
    e.pointsFile.clear();
    for (const std::string& w : doc_fx_list(d, layer))
      if (points_is(w)) e.pointsFile = w;
    // A flat layer has four corners and nothing between them to move: with a
    // points file and no solid of its own, it is laid on the shelf's Plane, a
    // sheet of many points (the user's own solids/Plane.js first).
    if (e.solidFile.empty() && !e.pointsFile.empty()) {
      std::string plane;
      for (const std::filesystem::path& folder : doc_folders("solids"))
        if (std::error_code wrong;
            std::filesystem::exists(folder / "Plane.js", wrong))
          plane = (folder / "Plane.js").string();
      e.solidFile = plane;
    }
    // If a solid is named, read its parameters as the document holds them now,
    // by their own names, and make the solid with them before the frame. If the
    // layer no longer names a solid, remove the old solid so that the layer's
    // own sheet shows again.
    if (const DocScript* sc =
            e.solidFile.empty() ? nullptr : doc_script_of(d, e.solidFile)) {
      e.parameters.clear(), e.words.clear();
      for (size_t i = 0; i < sc->parameters.size(); ++i) {
        const ScriptParameter& k = sc->parameters[i];
        const std::string w = doc_word(d, layer, sc->names[i].c_str());
        if (k.kind != "select")
          e.parameters[k.name] =
              doc_number(d, layer, sc->names[i].c_str(), d.stage->now, k.usual);
        else
          e.words[k.name] =
              w.empty() ? k.words.substr(0, k.words.find(' ')) : w;
      }
      float2 half{0.5f};
      doc_half(d, layer, &half);
      e.size = 2.f * half;
      thing_fx_solid(s, e, false);
    } else if (e.solid)
      take_off(s, e.solid), delete e.solid, e.solid = nullptr,
                                            e.solidSaid.clear();
    // If the fx names a file that moves a solid's points, run it on the solid
    // with its numbers as the document holds them now.
    if (const DocScript* sc =
            e.pointsFile.empty() ? nullptr : doc_script_of(d, e.pointsFile)) {
      e.pointsKnobs.clear();
      for (size_t i = 0; i < sc->parameters.size(); ++i)
        if (sc->parameters[i].kind != "select")
          e.pointsKnobs.push_back(
              (float)doc_number(d, layer, sc->names[i].c_str(), d.stage->now,
                                sc->parameters[i].usual));
      thing_fx_points(s, e);
    }
    e.st.sounds = [&d, layer = layer](const std::string& file,
                                      const std::string& name, bool fft,
                                      int wide) {
      return doc_sound_now(d, layer, file, name, fft, wide);
    };
    // Answers an effect's questions about the layer by parameter name. The
    // render callback calls this while the image is drawn, so it locks the
    // document.
    const ScreenNumbers numbers = [&d, layer = layer, &e = e](
                                      const std::string& file,
                                      const std::string& name, double usual) {
      std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
      // clip_time is the number of seconds into the layer's clip and
      // clip_length is how long the clip lasts. They are the ISF effect
      // parameters of the same names (see engine/community/isf/isf.cpp). A clip
      // with no duration lasts until the end of the project.
      if (name == "clip_time" || name == "clip_length") {
        const double start = doc_number(d, layer, "start", 0, 0),
                     lasts = doc_number(d, layer, "duration", 0, -1);
        return name == "clip_time" ? d.stage->now - start
               : lasts > 0         ? lasts
                                   : std::max(0.0, doc_seconds(d) - start);
      }
      // The box of the layer's image on the stage as shares of the stage: left,
      // top, width and height, chosen by the last letter of the name. Effects
      // use it to read what is behind the layer (see
      // shelves/effects/sources/from_absent.py).
      if (name.rfind("backdropBox_", 0) == 0) {
        const Stage& s = *d.stage;
        const size_t i = std::string("xyzw").find(name.back());
        return i == 0   ? e.box[0] / s.w
               : i == 1 ? e.box[1] / s.h
               : i == 2 ? (e.box[2] - e.box[0]) / s.w
                        : (e.box[3] - e.box[1]) / s.h;
      }
      // The layer's own rectangle on its image, in the image's pixels: where
      // its corner is and how large it is, chosen by the last letter of the
      // name. This is AbsentMotion's layer rectangle (see
      // shelves/effects/sources/from_absent.py).
      if (name.rfind("layerRect_", 0) == 0) {
        double frame[8];
        if (!doc_fx_frame(d, layer, e, frame)) return 0.0;
        const Stage& s = *d.stage;
        const double ppp =
            (double)s.view->getViewport().width / std::max(1, s.w);
        const size_t i = std::string("xyzw").find(name.back());
        return ppp * (i == 0   ? frame[0] - frame[2] / 2 - e.box[0]
                      : i == 1 ? frame[1] - frame[3] / 2 - e.box[1]
                      : i == 2 ? frame[2]
                               : frame[3]);
      }
      // An AviUtl2 script asking about the other layers.
      if (name.rfind("aviutl.", 0) == 0)
        return doc_aviutl_asked(d, layer, e.box, name, usual);
      // Where the layer is on its image now, how it is turned and how large it
      // is, so that an effect's pattern can stay stuck to the layer. The image
      // is the box where the layer is seen, so positions are relative to that
      // box.
      if (name == "origin_x" || name == "origin_y" || name == "turn" ||
          name == "extent") {
        double frame[8];
        if (!doc_fx_frame(d, layer, e, frame)) return usual;
        return name == "origin_x"   ? frame[0] - e.box[0]
               : name == "origin_y" ? frame[1] - e.box[1]
               : name == "turn"     ? frame[4]
                                    : std::max(frame[2], frame[3]);
      }
      if ((name == "blurLength" || name == "angle") &&
          file.ends_with("am_directionalblur.wgsl") &&
          doc_word(d, layer, "fx").find("am_directionalblur.wgsl") ==
              std::string::npos) {
        // The step of the layer's Motion Blur: as far, and in the same
        // direction, as the layer's middle moves while its shutter is open, in
        // pixels of its image. This is like AbsentMotion's quick smear. It
        // applies only when the effect comes from the Motion Blur setting and
        // is not named in the layer's fx.
        double open = 0.0, was[8], is[8];
        bool moves = false;
        const double now = d.stage->now;
        if (!doc_shutter(d, layer, now, &open, &moves) || !moves ||
            !doc_frame(d, layer, now - 0.5 * open, was) ||
            !doc_frame(d, layer, now + 0.5 * open, is))
          return 0.0;
        const double ppp = (double)d.stage->view->getViewport().width /
                           std::max(1, d.stage->w);
        const math::double3 way = (doc_shown_at(d, layer, now + 0.5 * open)[3] -
                                   doc_shown_at(d, layer, now - 0.5 * open)[3])
                                      .xyz;
        // A standing layer moves along its own image, so project the movement
        // onto the image's axes.
        const double dx = e.world ? dot(way, e.square[0].xyz) * e.own[4]
                                  : is[0] - was[0],
                     dy = e.world ? -dot(way, e.square[1].xyz) * e.own[4]
                                  : is[1] - was[1];
        // The blur effect reads behind the layer along the angle it is given.
        // The angle therefore points opposite to the direction of travel, so
        // that the blur trails behind the layer.
        return name == "blurLength" ? ppp * std::hypot(dx, dy)
                                    : std::atan2(-dy, -dx) * 180.0 / M_PI;
      }
      return doc_number(d, layer, doc_screen_parameter(file, name).c_str(),
                        d.stage->now, usual);
    };
    // Before the frame: works out where the layer is seen, what its images are,
    // and what its sheet shows.
    s.aim.push_back([&s, &d, layer = layer, &e = e] {
      double box[4] = {0, 0, (double)s.w, (double)s.h}, seen[4];
      {
        std::lock_guard<std::recursive_timed_mutex> hold(
            d.lock);  // (asked while the picture is drawn)
        // A group's image is the whole stage, as an Alight Motion group's scene
        // is as large as the stage.
        const bool found = !doc_holds_fx(d, layer) &&
                           doc_seen_box(d, layer, d.stage->now, seen);
        // Where the layer is seen, limited to the part on the stage, is its
        // image, as in After Effects. Add room around it for what its effects
        // draw outside it: a margin of 128 pixels.
        if (found) {
          const double m =
              128.0 * s.w / std::max(1u, s.view->getViewport().width);
          box[0] = std::max(0.0, seen[0] - m),
          box[1] = std::max(0.0, seen[1] - m),
          box[2] = std::min((double)s.w, seen[2] + m),
          box[3] = std::min((double)s.h, seen[3] + m);
        }
        // If none of the layer is on the stage, use the whole stage.
        if (box[2] - box[0] < 1 || box[3] - box[1] < 1)
          box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
        e.st.frame[0] = 0, e.st.frame[1] = 0, e.st.frame[2] = 1,
        e.st.frame[3] = 1;
        const bool shown = found && !e.shell && !e.st.wide;
        // Normally the frame is the box where the layer is seen, as shares of
        // the stage, and the image covers the whole stage. AbsentMotion's
        // effects are cut by the scene in the same way
        // (engine/third_party/AbsentMotion/app/src/main/cpp/effects.cpp,
        // EffectRuntime::draw).
        if (!e.shell && !e.st.wide) {
          e.st.frame[0] = box[0] / s.w, e.st.frame[1] = box[1] / s.h,
          e.st.frame[2] = (box[2] - box[0]) / s.w,
          e.st.frame[3] = (box[3] - box[1]) / s.h;
          box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
        }
        std::copy(e.st.frame, e.st.frame + 4, e.st.own);
        if (shown)
          e.st.own[0] = seen[0] / s.w, e.st.own[1] = seen[1] / s.h,
          e.st.own[2] = (seen[2] - seen[0]) / s.w,
          e.st.own[3] = (seen[3] - seen[1]) / s.h;
        // An AviUtl2 script that draws the layer uses the whole stage as its
        // frame, as an AviUtl2 object is drawn on the screen. The box where the
        // layer is seen is passed to the effect in thingSeen.
        if (e.st.wide) {
          std::copy(found ? seen : box, (found ? seen : box) + 4,
                    e.st.thingSeen);
          box[0] = box[1] = 0, box[2] = s.w, box[3] = s.h;
        }
      }
      if (!e.solidFile.empty()) return doc_layer_solid_aim(d, layer, e);
      // The layer's sheet is shown on screen only, not in the image of what is
      // behind it that its effect reads. The glass material leaves itself out
      // in the same way (see engine/stage/render/render_layers.h).
      if (e.st.readsBehind) {
        s.backdropRead = true;
        for (const Stage::Renderable& made : s.renderables)
          if (made.of == e.sheet)
            s.engine->getRenderableManager().setLayerMask(
                s.engine->getRenderableManager().getInstance(made.thing), 0xFF,
                0x02);
      }
      // The background color as hex RRGGBB, or -1 if there is none. An effect
      // that reads the frame sees it where nothing is drawn.
      e.st.ground =
          d.look.backdropIs.size() == 6
              ? (int)std::strtol(d.look.backdropIs.c_str(), nullptr, 16)
              : -1;
      if (e.world)
        doc_layer_stand(d, layer, e);
      else
        thing_fx_aim(s, e, box);
      thing_fx_textures(s, e.st, e.view);
      if (e.look)
        e.look->setParameter(
            "image", thing_fx_seen(e.st),
            e.shell ? TextureSampler(TextureSampler::MinFilter::NEAREST,
                                     TextureSampler::MagFilter::NEAREST)
                    : TextureSampler(TextureSampler::MinFilter::LINEAR,
                                     TextureSampler::MagFilter::LINEAR));
      // The emissive of the effect result is picked up by the stage's bloom,
      // as a layer without effects is (see evaluate_glow).
      if (e.look) {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        e.look->setParameter("glowing", (float)doc_number(d, layer, "emissive",
                                                          d.stage->now, 0));
      }
    });
    d.effects.beforeOf.push_back(layer);
    // In the frame: draws the layer alone and runs its effects.
    s.before.push_back([&d, layer = layer, &e = e, numbers] {
      if (!e.solidFile.empty()) return doc_layer_solid(d, layer, e, numbers);
      thing_effects_draw(*d.stage, e.st, e.view, numbers);
      if (e.shell) doc_layer_shell(d, layer, e, true);
    });
    if (e.shell)
      s.after.push_back(
          [&d, layer = layer, &e = e] { doc_layer_shell(d, layer, e, false); });
  }
}
void doc_layers_read(Doc& d,
                     const std::vector<std::pair<int, DocShownLayer*>>& laid) {
  Stage& s = *d.stage;
  // A flat layer of glass sees what is behind it through itself (see
  // engine/materials/flat.mat).
  const auto reads = [&](int layer) {
    return doc_blend_way(doc_word(d, layer, "blend")) ||
           doc_word(d, layer, "fill") == "behind" ||
           doc_sheet_material(d, layer) == "glass";
  };
  // Release the backdrop of layers that no longer read or that are gone.
  for (auto r = d.effects.reads.begin(); r != d.effects.reads.end();) {
    if (d.on_stage.shown.count(r->first) && reads(r->first)) {
      ++r;
      continue;
    }
    if (const auto t = d.on_stage.shown.find(r->first);
        t != d.on_stage.shown.end())
      doc_reading(s, t->second, 0.f, 0.f, white_point(s));
    doc_sheet_reads(d, r->first, 0.f, white_point(s));
    s.engine->destroy(r->second.into), s.engine->destroy(r->second.seen),
        r = d.effects.reads.erase(r);
  }
  if (std::none_of(laid.begin(), laid.end(),
                   [&](const auto& l) { return reads(l.first); }))
    return;
  std::vector<std::function<void()>> fx = std::move(s.before);
  s.before.clear();
  std::vector<utils::Entity> parts;
  std::vector<size_t> from(laid.size());
  for (size_t i = 0; i < laid.size(); ++i) {
    from[i] = parts.size();
    doc_entities(s, *laid[i].second,
                 [&](utils::Entity e) { parts.push_back(e); });
    if (const auto own = d.effects.layerFx.find(laid[i].first);
        own != d.effects.layerFx.end())
      for (const Stage::Renderable& made : s.renderables)
        if (made.of == own->second.sheet) parts.push_back(made.thing);
  }
  for (size_t i = 0; i < laid.size(); ++i) {
    const int layer = laid[i].first;
    if (reads(layer)) {
      DocEffects::Read& r = d.effects.reads[layer];
      if (!r.seen) {
        r.seen = Texture::Builder()
                     .width((uint32_t)s.w)
                     .height((uint32_t)s.h)
                     .levels(1)
                     .usage(Texture::Usage::COLOR_ATTACHMENT |
                            Texture::Usage::SAMPLEABLE)
                     .format(Texture::InternalFormat::RGBA16F)
                     .build(*s.engine);
        r.into =
            RenderTarget::Builder()
                .texture(RenderTarget::AttachmentPoint::COLOR, r.seen)
                .texture(RenderTarget::AttachmentPoint::DEPTH, s.behindDepth)
                .build(*s.engine);
      }
      const float way = (float)doc_blend_way(doc_word(d, layer, "blend"));
      doc_reading(s, *laid[i].second,
                  d.effects.layerFx.count(layer) ? 0.f : way,
                  doc_word(d, layer, "fill") == "behind" ? 1.f : 0.f, r.seen);
      doc_sheet_reads(d, layer, way, r.seen);
      s.before.push_back([&s,
                          over = std::vector<utils::Entity>(
                              parts.begin() + (long)from[i], parts.end()),
                          into = r.into] {
        auto& faces = s.engine->getRenderableManager();
        std::vector<uint8_t> masks;
        for (utils::Entity e : over)
          masks.push_back(faces.getLayerMask(faces.getInstance(e))),
              faces.setLayerMask(faces.getInstance(e), 0xFF, 0x02);
        RenderTarget* const was = s.view_behind->getRenderTarget();
        s.view_behind->setRenderTarget(into);
        s.renderer->render(s.view_behind);
        s.view_behind->setRenderTarget(was);
        for (size_t k = 0; k < over.size(); ++k)
          faces.setLayerMask(faces.getInstance(over[k]), 0xFF, masks[k]);
      });
    }
    for (size_t k = 0; k < fx.size() && k < d.effects.beforeOf.size(); ++k)
      if (d.effects.beforeOf[k] == layer) s.before.push_back(std::move(fx[k]));
  }
}

}  // namespace motolii

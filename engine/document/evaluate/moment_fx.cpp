#include "document/evaluate/moment_fx.h"

#include <filament/TextureSampler.h>
#include <filament/Viewport.h>

#include <filesystem>
#include <regex>

#include "community/three/solid_three.h"
#include "document/edit/arrange.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/shown.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "shelf/shelf_folders.h"
#include "stage/render/render_draw.h"
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

namespace {
// Rebinds any clipping matte sampling `layer`'s post-effect image after
// thing_fx_textures recreates its textures in s.aim (before render).
void refresh_matte_picture(Doc& d, int layer, Texture* pic) {
  if (!pic) return;
  std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
  for (auto& [cutLayer, cut] : d.on_stage.cuts) {
    if (cut.from == layer && cut.matte >= 0 && cut.tex != pic) {
      matte_picture(*d.stage, cut.matte, pic);
      cut.tex = pic;
    }
  }
}
}  // namespace

bool doc_holds_fx(Doc& d, int layer) {
  if (doc_word(d, layer, "shape") != "null") return false;
  return doc_fx_files(doc_fx_steps(d, layer));
}
bool doc_own_fx(Doc& d, int layer) {
  return doc_fx_files(doc_fx_steps(d, layer));
}
bool doc_layer_stands(Doc& d, int layer, ThingFx& e) {
  thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps_with_ids(d, layer)));
  if (e.st.readsBehind || e.st.wide || !e.st.aviutl.empty() ||
      !e.st.aePlugins.empty() || doc_holds_fx(d, layer))
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
  thing_effects(*d.stage, e.st, doc_fx_join(doc_fx_steps_with_ids(d, layer)));
  for (const std::string& w : doc_fx_list(d, layer))
    if (solid_is(w) || points_is(w)) return false;
  const auto shown = d.on_stage.shown.find(layer);
  float2 half{0.f};
  float deep = 0.f;
  return shown != d.on_stage.shown.end() && shown->second.space != 2 &&
         !e.st.readsBehind && !e.st.wide && e.st.aviutl.empty() &&
         e.st.aePlugins.empty() &&
         (shown->second.solid ||
          (doc_half(d, layer, &half, &deep) && deep > 0.f));
}

void doc_layers_fx(Doc& d) {
  Stage& s = *d.stage;
  s.before.clear(), s.aim.clear(), s.after.clear(), d.effects.beforeOf.clear();
  // Sort deepest first so a group's children render before the group itself.
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
  // Each layer is drawn alone, effects applied, before the stage's own view.
  for (const auto& [deep, layer] : order) {
    ThingFx& e = d.effects.layerFx.at(layer);
    thing_effects(s, e.st, doc_fx_join(doc_fx_steps_with_ids(d, layer)));
    e.solidFile.clear();
    // Last solid shape in the fx list wins.
    for (const std::string& w : doc_fx_list(d, layer))
      if (solid_is(w)) e.solidFile = w;
    e.pointsFile.clear();
    for (const std::string& w : doc_fx_list(d, layer))
      if (points_is(w)) e.pointsFile = w;
    // A flat layer with a points file but no solid uses the shelf's Plane.
    if (e.solidFile.empty() && !e.pointsFile.empty()) {
      std::string plane;
      for (const std::filesystem::path& folder : doc_folders("solids"))
        if (std::error_code wrong;
            std::filesystem::exists(folder / "Plane.js", wrong))
          plane = (folder / "Plane.js").generic_string();
      e.solidFile = plane;
    }
    // Build the solid with current parameters; remove it if no longer named.
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
    // Run the points file on the solid with current parameters.
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
    // Called from the render callback; locks the document only when needed.
    const ScreenNumbers numbers = [&d, layer = layer, &e = e](
                                      const std::string& file,
                                      const std::string& name, double usual) {
      // Fast lock-free paths using values cached once per frame in `s.aim`.
      if (name == "clip_time") return e.cachedClipTime;
      if (name == "clip_length") return e.cachedClipLength;
      if (name.rfind("layerRect_", 0) == 0) {
        if (!e.hasCachedLayerRect) return 0.0;
        const size_t i = std::string("xyzw").find(name.back());
        return i < 4 ? e.cachedLayerRect[i] : 0.0;
      }
      // Layer's box on the stage as shares, by last letter (xyzw).
      if (name.rfind("backdropBox_", 0) == 0) {
        const Stage& s = *d.stage;
        double work[4];
        thing_fx_work(s, work);
        const size_t i = std::string("xyzw").find(name.back());
        return i == 0   ? (e.box[0] - work[0]) / (work[2] - work[0])
               : i == 1 ? (e.box[1] - work[1]) / (work[3] - work[1])
               : i == 2 ? (e.box[2] - e.box[0]) / (work[2] - work[0])
                        : (e.box[3] - e.box[1]) / (work[3] - work[1]);
      }
      std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
      // An AviUtl2 script asking about the other layers.
      if (name.rfind("aviutl.", 0) == 0)
        return doc_aviutl_asked(d, layer, e.box, name, usual);
      // Position on image, rotation, extent — relative to the effect's box.
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
        // Motion Blur: length and angle from the layer's movement while the
        // shutter is open. Only when the effect is from the setting, not fx.
        double open = 0.0, was[8], is[8];
        bool moves = false;
        const double now = d.stage->now;
        if (!doc_shutter(d, layer, now, &open, &moves) || !moves ||
            !doc_frame(d, layer, now - 0.5 * open, was) ||
            !doc_frame(d, layer, now + 0.5 * open, is))
          return 0.0;
        const double ppp = thing_fx_ppp(*d.stage);
        const math::double3 way = (doc_shown_at(d, layer, now + 0.5 * open)[3] -
                                   doc_shown_at(d, layer, now - 0.5 * open)[3])
                                      .xyz;
        // Project movement onto the image's axes for a standing layer.
        const double dx = e.world ? dot(way, e.square[0].xyz) * e.own[4]
                                  : is[0] - was[0],
                     dy = e.world ? -dot(way, e.square[1].xyz) * e.own[4]
                                  : is[1] - was[1];
        // Angle points opposite to travel so blur trails behind the layer.
        return name == "blurLength" ? ppp * std::hypot(dx, dy)
                                    : std::atan2(-dy, -dx) * 180.0 / M_PI;
      }
      // `file` is the numbers_key() — either "id:path" or just "path".
      // Extract the instance ID so the parameter is looked up under the
      // instance-keyed name ("a1b2c3:js_blur_intensity") when present.
      return doc_number(
          d, layer,
          doc_screen_parameter(fx_entry_path(file), name, fx_entry_id(file))
              .c_str(),
          d.stage->now, usual);
    };
    // Before the frame: works out where the layer is seen, what its images are,
    // and what its sheet shows.
    s.aim.push_back([&s, &d, layer = layer, &e = e] {
      // The effect image covers the work box (see thing_fx_work).
      double work[4], box[4], seen[4];
      thing_fx_work(s, work);
      std::copy(work, work + 4, box);
      {
        std::lock_guard<std::recursive_timed_mutex> hold(
            d.lock);  // (asked while the picture is drawn)
        // A group's image is the whole stage.
        const bool found = !doc_holds_fx(d, layer) &&
                           doc_seen_box(d, layer, d.stage->now, seen);
        // 128-pixel margin around the visible box for effects that draw
        // outside.
        if (found) {
          const double m = 128.0 / thing_fx_ppp(s);
          box[0] = std::max(work[0], seen[0] - m),
          box[1] = std::max(work[1], seen[1] - m),
          box[2] = std::min(work[2], seen[2] + m),
          box[3] = std::min(work[3], seen[3] + m);
        }
        // Fall back to the whole work box if nothing is visible.
        if (box[2] - box[0] < 1 || box[3] - box[1] < 1)
          std::copy(work, work + 4, box);
        e.st.frame[0] = 0, e.st.frame[1] = 0, e.st.frame[2] = 1,
        e.st.frame[3] = 1;
        const bool shown = found && !e.shell && !e.st.wide;
        // Frame = layer's visible box as shares of the stage.
        if (!e.shell && !e.st.wide) {
          e.st.frame[0] = (box[0] - work[0]) / (work[2] - work[0]),
          e.st.frame[1] = (box[1] - work[1]) / (work[3] - work[1]),
          e.st.frame[2] = (box[2] - box[0]) / (work[2] - work[0]),
          e.st.frame[3] = (box[3] - box[1]) / (work[3] - work[1]);
          std::copy(work, work + 4, box);
        }
        std::copy(e.st.frame, e.st.frame + 4, e.st.own);
        if (shown)
          e.st.own[0] = (seen[0] - work[0]) / (work[2] - work[0]),
          e.st.own[1] = (seen[1] - work[1]) / (work[3] - work[1]),
          e.st.own[2] = (seen[2] - seen[0]) / (work[2] - work[0]),
          e.st.own[3] = (seen[3] - seen[1]) / (work[3] - work[1]);
        // AviUtl2 scripts use the whole stage as their frame.
        if (e.st.wide) {
          std::copy(found ? seen : box, (found ? seen : box) + 4,
                    e.st.thingSeen);
          std::copy(work, work + 4, box);
        }
      }
      if (!e.solidFile.empty()) return doc_layer_solid_aim(d, layer, e);
      // Hide the sheet from the backdrop image (same as glass self-exclusion).
      if (e.st.readsBehind) {
        s.backdropRead = true;
        for (const Stage::Renderable& made : s.renderables)
          if (made.of == e.sheet)
            s.engine->getRenderableManager().setLayerMask(
                s.engine->getRenderableManager().getInstance(made.thing), 0xFF,
                0x02);
      }
      // -1 when transparent.
      e.st.ground =
          d.look.backdropIs.size() == 6
              ? (int)std::strtol(d.look.backdropIs.c_str(), nullptr, 16)
              : -1;
      // Batch-evaluate all GPU effect user parameters under one `d.lock` using
      // precomputed keys (avoiding per-parameter mutex + path stem parsing) and
      // compute the stack's exact bounded spill margin before aiming the view.
      {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        const std::string fxWord = doc_word(d, layer, "fx");
        const double now = d.stage->now;
        const bool baseBounded = !e.st.steps.empty() && e.st.aviutl.empty() &&
                                 e.st.aePlugins.empty() && !e.st.readsBehind &&
                                 !e.st.wide;
        bool bounded = baseBounded;
        bool anyFrame = false;
        double totalPadPx = 0.0;
        for (ScreenFx* fx : e.st.fx) {
          screen_fresh(s, *fx);
          anyFrame |= fx->hasFrameRect;
          const bool synthMotionBlur =
              fx->file.ends_with("am_directionalblur.wgsl") &&
              fxWord.find("am_directionalblur.wgsl") == std::string::npos;
          for (ScreenFx::Field& f : fx->fields) {
            if (f.kind != ScreenFx::FieldKind::Param) continue;
            if (f.hasDynamicKey ||
                (synthMotionBlur &&
                 (f.name == "blurLength" || f.name == "angle"))) {
              f.useCachedVal = false;
              continue;
            }
            for (uint32_t i = 0; i < f.floats && i < 4; ++i)
              f.paramVal[i] = (float)doc_number(
                  d, layer, f.docParamKeys[i].c_str(), now, f.usual[i]);
            f.useCachedVal = true;
          }
          fx->paramValsFrame = s.frameCount;
          if (!bounded) continue;
          if (fx->spillKind == ScreenFx::SpillKind::Zero) {
            continue;
          } else if (fx->spillKind == ScreenFx::SpillKind::FixedPx) {
            double pad = fx->spillBase;
            if (fx->spillCap > 0.f) pad = std::min(pad, (double)fx->spillCap);
            totalPadPx += pad;
          } else if (fx->spillKind == ScreenFx::SpillKind::ParamPx &&
                     fx->spillField >= 0 &&
                     (size_t)fx->spillField < fx->fields.size() &&
                     fx->fields[(size_t)fx->spillField].useCachedVal) {
            double pad =
                std::fabs(
                    (double)fx->fields[(size_t)fx->spillField].paramVal[0]) *
                    fx->spillScale +
                fx->spillBase;
            if (fx->spillCap > 0.f) pad = std::min(pad, (double)fx->spillCap);
            totalPadPx += pad;
          } else {
            bounded = false;
          }
        }
        // Pure pointwise chains whose steps all preserve input alpha end in
        // `toLinear` (which zeroes every `a <= 0` pixel), so tight bounds are
        // exact even for straight-alpha ISF color shaders.
        const bool purePointwiseAlpha =
            baseBounded && !e.st.fx.empty() &&
            std::all_of(e.st.fx.begin(), e.st.fx.end(), [](const ScreenFx* fx) {
              return fx && fx->pointwise &&
                     (fx->preservesZeroAlpha || fx->preservesAlpha);
            });
        if (purePointwiseAlpha) bounded = true, totalPadPx = 0.0;
        e.st.boundPadPx = bounded ? totalPadPx : -1.0;
        e.st.anyHasFrameRect = anyFrame;
        // Domain culling: skip all offscreen rendering & effect passes when the
        // layer is invisible (opacity <= 0) or its bounded effect footprint
        // lies completely outside the visible stage work box (unless used as
        // matte).
        bool isMatteSource = false;
        for (const auto& [cutLayer, cut] : d.on_stage.cuts)
          if (cut.from == layer) isMatteSource = true;
        bool cull = false;
        if (!isMatteSource && !e.shell && e.solidFile.empty() &&
            d.held.layer != layer) {
          const double op = doc_number(d, layer, "opacity", now, 1.0);
          if (op <= 0.0) {
            cull = true;
          } else if (bounded) {
            double seenNow[4];
            if (!doc_holds_fx(d, layer) &&
                doc_seen_box(d, layer, now, seenNow)) {
              const double padPts = (totalPadPx + 16.0) / thing_fx_ppp(s);
              if (seenNow[2] + padPts < work[0] ||
                  seenNow[0] - padPts > work[2] ||
                  seenNow[3] + padPts < work[1] ||
                  seenNow[1] - padPts > work[3])
                cull = true;
            }
          }
        }
        e.culled = cull;
      }
      if (e.culled) {
        // Hide the layer's result sheet so culled layers draw nothing even
        // before their first on-screen frame.
        if (e.world && e.sheet)
          move(s, e.sheet,
               [](int, const mat4f&) { return mat4f::scaling(float3{0.f}); });
        else if (!e.world && e.look)
          e.look->setParameter("place", mat4f::scaling(float3{0.f}));
        return;
      }
      if (e.world)
        doc_layer_stand(d, layer, e);
      else
        thing_fx_aim(s, e, box);
      // Populate per-frame cached layerRect and clip timing once under lock so
      // `numbers` never re-locks or recomputes `doc_fx_frame` per component.
      {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        const double start = doc_number(d, layer, "start", 0, 0),
                     lasts = doc_number(d, layer, "duration", 0, -1);
        e.cachedClipTime = d.stage->now - start;
        e.cachedClipLength =
            lasts >= 0 ? lasts : std::max(0.0, doc_seconds(d) - start);
        double frame[8];
        if (doc_fx_frame(d, layer, e, frame)) {
          const double ppp = thing_fx_ppp(s);
          e.cachedLayerRect[0] = ppp * (frame[0] - frame[2] / 2 - e.box[0]);
          e.cachedLayerRect[1] = ppp * (frame[1] - frame[3] / 2 - e.box[1]);
          e.cachedLayerRect[2] = ppp * frame[2];
          e.cachedLayerRect[3] = ppp * frame[3];
          e.hasCachedLayerRect = true;
        } else {
          e.hasCachedLayerRect = false;
        }
        // Flat 2D single-layer renderLayer bypass: when a standing flat
        // Canvas2D layer has no 3D/lit/wear/cut/copy/emissive/scissor/mask-top
        // modifiers, feed its straight-sRGB Canvas2D::texture directly into
        // the effect chain, skipping Filament's 3D Renderer::render(v) and
        // per-layer st.shot allocation.
        e.flatBypass = false;
        e.flatTex = nullptr;
        const auto shownIt = d.on_stage.shown.find(layer);
        const int parentLayer =
            (int)std::lround(doc_number(d, layer, "parent", 0, 0));
        const std::string parentMask =
            parentLayer > 0 ? doc_word(d, parentLayer, "group_mask")
                            : std::string();
        const bool isGroupMask =
            parentMask == "mask" || parentMask == "exclude";
        if (e.world && !e.shell && e.solidFile.empty() && !e.st.steps.empty() &&
            !isGroupMask && shownIt != d.on_stage.shown.end() &&
            doc_members(d, layer) == 1 &&
            doc_sheet_material(d, layer).empty() &&
            doc_word(d, layer, "fill") != "behind" &&
            doc_number(d, layer, "emissive", d.stage->now, 0) == 0.0 &&
            e.look && e.look->getMaterial()->hasParameter("opacity")) {
          const DocShownLayer& sh = shownIt->second;
          if (sh.drawn && sh.drawn->texture && sh.drawn->sheet &&
              sh.drawn->sheet->pos.size() >= 4 && !sh.video && !sh.sketch &&
              !sh.solid && !sh.grains && sh.deep.empty() && !sh.clipped) {
            const Canvas2D& c = *sh.drawn;
            if (!c.cut && !c.inLight && c.boxed.z == 0.f && c.fx.wear.empty() &&
                !c.edgeLook && c.letters.empty()) {
              const math::mat4 place = doc_shown_at(d, layer, d.stage->now);
              const double sx = length(place[0].xyz), sy = length(place[1].xyz);
              const double across = e.ortho[0] + e.ortho[1],
                           tall = e.ortho[2] + e.ortho[3];
              if (sx > 1e-6 && sy > 1e-6 && across > 1e-9 && tall > 1e-9 &&
                  std::fabs(dot(place[0].xyz, place[1].xyz)) <=
                      1e-5 * sx * sy) {
                float2 shHalf{0.f};
                for (const float3& p : c.sheet->pos) {
                  shHalf.x = std::max(shHalf.x, std::fabs(p.x));
                  shHalf.y = std::max(shHalf.y, std::fabs(p.y));
                }
                const double hx = shHalf.x * sx, hy = shHalf.y * sy;
                const double u0 = (e.ortho[0] - hx) / across;
                const double v0 = (e.ortho[3] - hy) / tall;
                const double uw = (2.0 * hx) / across;
                const double vh = (2.0 * hy) / tall;
                if (uw > 1e-6 && vh > 1e-6) {
                  Texture* tex = c.texture;
                  if (c.shownAt >= 0) {
                    if (const auto k = c.cached.find(c.shownAt);
                        k != c.cached.end() && k->second)
                      tex = k->second;
                  }
                  e.flatBypass = true;
                  e.flatTex = tex;
                  e.flatRect[0] = (float)u0;
                  e.flatRect[1] = (float)v0;
                  e.flatRect[2] = (float)(1.0 / uw);
                  e.flatRect[3] = (float)(1.0 / vh);
                  e.flatWash[0] = c.wash.x;
                  e.flatWash[1] = c.wash.y;
                  e.flatWash[2] = c.wash.z;
                  e.flatWash[3] = c.wash.w;
                }
              }
            }
          }
        }
      }
      thing_fx_textures(s, e.st, e.view, !e.flatBypass);
      // Compute static-layer cache eligibility and base fingerprint under lock
      // so `thing_effects_draw` can skip re-rendering unchanged layers safely.
      {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        const auto found = d.on_stage.shown.find(layer);
        const bool fxCacheable =
            !e.st.steps.empty() && e.st.aviutl.empty() &&
            e.st.aePlugins.empty() && !e.st.readsBehind &&
            std::all_of(e.st.fx.begin(), e.st.fx.end(), [](const ScreenFx* f) {
              if (!f || f->historyFrames != 0 || !f->others.empty())
                return false;
              for (const auto& t : f->targets)
                if (t.persistent) return false;
              return true;
            });
        bool layerCacheable =
            fxCacheable && e.solidFile.empty() && !e.shell &&
            d.held.layer != layer && found != d.on_stage.shown.end() &&
            doc_members(d, layer) == 1 && doc_sheet_material(d, layer).empty();
        if (layerCacheable) {
          const DocShownLayer& sh = found->second;
          if (sh.video || sh.sketch || sh.solid || sh.grains ||
              !sh.deep.empty() || sh.wordsMove || sh.textMove || sh.celMove)
            layerCacheable = false;
          if (layerCacheable && sh.drawn) {
            const Canvas2D& c = *sh.drawn;
            if (c.seconds > 0.f || c.lottie || c.sketchLines || c.redraw ||
                c.film || c.inLight || c.boxed.z != 0.f || !c.fx.wear.empty())
              layerCacheable = false;
          }
        }
        e.cacheEligible = layerCacheable;
        if (layerCacheable) {
          uint64_t h = 14695981039346656037ull;
          const auto mix = [&](const void* p, size_t n) {
            const auto* b = static_cast<const uint8_t*>(p);
            for (size_t i = 0; i < n; ++i) h = (h ^ b[i]) * 1099511628211ull;
          };
          const DocShownLayer& sh = found->second;
          mix(&sh.drawn, sizeof(sh.drawn));
          mix(&sh.shape, sizeof(sh.shape));
          mix(&sh.in, sizeof(sh.in));
          mix(sh.of.data(), sh.of.size());
          if (sh.drawn) {
            const Canvas2D& c = *sh.drawn;
            mix(&c.texture, sizeof(c.texture));
            mix(&c.sheet, sizeof(c.sheet));
            mix(&c.wash, sizeof(c.wash));
            mix(&c.trimmed, sizeof(c.trimmed));
            mix(c.bent.data(), sizeof(c.bent));
            const size_t nSteps = c.bentSteps.size();
            mix(&nSteps, sizeof(nSteps));
            for (const PathOpStep& ps : c.bentSteps) mix(&ps, sizeof(ps));
            mix(&c.bentVoxel, sizeof(c.bentVoxel));
            mix(&c.joined.how, sizeof(c.joined.how));
            mix(&c.joined.much, sizeof(c.joined.much));
            const size_t jn = c.joined.at.size(), mn = c.morphed.at.size(),
                         tn = c.traced.at.size();
            mix(&jn, sizeof(jn));
            mix(&c.morphed.how, sizeof(c.morphed.how));
            mix(&c.morphed.much, sizeof(c.morphed.much));
            mix(&mn, sizeof(mn));
            mix(&c.traced.how, sizeof(c.traced.how));
            mix(&tn, sizeof(tn));
            mix(&s.bentChanges, sizeof(s.bentChanges));
          }
          const math::mat4 worldAt = doc_shown_at(d, layer, d.stage->now);
          mix(&worldAt, sizeof(worldAt));
          const double opacity =
              doc_number(d, layer, "opacity", d.stage->now, 1);
          mix(&opacity, sizeof(opacity));
          const std::string col = doc_word(d, layer, "color");
          mix(col.data(), col.size());
          const math::mat4 proj = e.camera->getProjectionMatrix();
          const math::mat4 model = e.camera->getModelMatrix();
          mix(&proj, sizeof(proj));
          mix(&model, sizeof(model));
          const float ap = e.camera->getAperture(),
                      shutter = e.camera->getShutterSpeed(),
                      sens = e.camera->getSensitivity();
          mix(&ap, sizeof(ap));
          mix(&shutter, sizeof(shutter));
          mix(&sens, sizeof(sens));
          const filament::Viewport vp = e.view->getViewport();
          mix(&vp, sizeof(vp));
          mix(e.st.files.data(), e.st.files.size());
          mix(e.st.frame, sizeof(e.st.frame));
          mix(e.st.own, sizeof(e.st.own));
          mix(&e.st.ground, sizeof(e.st.ground));
          e.cacheBaseKey = h;
        } else {
          e.cacheValid = false;
        }
      }
      refresh_matte_picture(d, layer, thing_fx_seen(e.st));
      if (e.look)
        e.look->setParameter(
            "image", thing_fx_seen(e.st),
            e.shell ? TextureSampler(TextureSampler::MinFilter::NEAREST,
                                     TextureSampler::MagFilter::NEAREST)
                    : TextureSampler(TextureSampler::MinFilter::LINEAR,
                                     TextureSampler::MagFilter::LINEAR));
      // Feed emissive to bloom (see evaluate_glow).
      if (e.look) {
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        e.look->setParameter("glowing", (float)doc_number(d, layer, "emissive",
                                                          d.stage->now, 0));
      }
    });
    d.effects.beforeOf.push_back(layer);
    // In the frame: draw the layer alone, run its effects.
    s.before.push_back([&d, layer = layer, &e = e, numbers] {
      if (!e.solidFile.empty()) return doc_layer_solid(d, layer, e, numbers);
      thing_effects_draw(*d.stage, e.st, e.view, numbers, nullptr, &e);
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
  // Glass and blend-mode layers read the backdrop (see flat.mat).
  const auto reads = [&](int layer) {
    return doc_blend_way(doc_word(d, layer, "blend")) ||
           doc_word(d, layer, "fill") == "behind" ||
           doc_sheet_material(d, layer) == "glass";
  };
  // Release backdrops of layers that stopped reading or were removed.
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
        s.engine->destroy(r->second.deep), r = d.effects.reads.erase(r);
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
      // Sized to the view (desk in editor, comp on export). Already aimed by
      // desk_lay; see thing_fx_work and backdropBox_.
      const uint32_t rw = s.desk.w ? s.desk.w : (uint32_t)s.w,
                     rh = s.desk.w ? s.desk.h : (uint32_t)s.h;
      if (!r.seen || r.w != rw || r.h != rh) {
        if (r.into) s.engine->destroy(r.into);
        if (r.seen) s.engine->destroy(r.seen);
        if (r.deep) s.engine->destroy(r.deep);
        r.w = rw, r.h = rh;
        r.seen = Texture::Builder()
                     .width(rw)
                     .height(rh)
                     .levels(1)
                     .usage(Texture::Usage::COLOR_ATTACHMENT |
                            Texture::Usage::SAMPLEABLE)
                     .format(Texture::InternalFormat::RGBA16F)
                     .build(*s.engine);
        r.deep = Texture::Builder()
                     .width(rw)
                     .height(rh)
                     .levels(1)
                     .usage(Texture::Usage::DEPTH_ATTACHMENT)
                     .format(Texture::InternalFormat::DEPTH24)
                     .build(*s.engine);
        r.into = RenderTarget::Builder()
                     .texture(RenderTarget::AttachmentPoint::COLOR, r.seen)
                     .texture(RenderTarget::AttachmentPoint::DEPTH, r.deep)
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

// -- per-layer effect parts --

// Prepares a solid layer: draws square to its face, runs effects, maps to
// solid.
void doc_layer_solid_aim(Doc& d, int layer, ThingFx& e) {
  Stage& s = *d.stage;
  math::mat4 place;
  float2 half{0.5f};
  {
    // Render callback runs mid-draw; lock first.
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    place = doc_place(d, layer, d.stage->now), doc_half(d, layer, &half);
    const double start = doc_number(d, layer, "start", 0, 0),
                 lasts = doc_number(d, layer, "duration", 0, -1);
    e.cachedClipTime = d.stage->now - start;
    e.cachedClipLength =
        lasts >= 0 ? lasts : std::max(0.0, doc_seconds(d) - start);
    e.hasCachedLayerRect = false;
  }
  thing_fx_face(s, e, place, half);
  thing_fx_textures(s, e.st, e.view);
  refresh_matte_picture(d, layer, thing_fx_seen(e.st));
  // Hide the layer's own sheet.
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
// Swaps the faces' materials to/from the effect image. No-op if already set.
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
// How far the stage extends from a standing layer along its face axes, in layer
// units. Rounded to 256-point steps so the image is reused across small moves.
// Capped at 3× the stage's longer side for edge-on faces.
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
// Prepares a standing layer: reads placement under lock, sets up effect image.
void doc_layer_stand(Doc& d, int layer, ThingFx& e) {
  math::mat4 place;
  float2 half{0.5f};
  double seen = 0.0;
  {
    // Render callback runs mid-draw; lock first.
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
    place = doc_shown_at(d, layer, d.stage->now), doc_half(d, layer, &half);
    const math::double2 a = doc_seen(d, place[3].xyz),
                        b = doc_seen(d, place[3].xyz +
                                            normalize(d.camera.facing[0].xyz));
    seen = length(b - a);
    if (e.st.boundPadPx >= 0.0) {
      double stageSides[4];
      doc_fx_sides(d, place, seen, stageSides);
      if (e.st.boundPadPx <= 0.0 && !e.st.anyHasFrameRect) {
        std::fill(e.sides, e.sides + 4, 0.0);
      } else {
        // Quantize spill margin to 64px steps so smoothly animating blur/glow
        // radii keep stable texture dimensions without reallocations.
        const double padPx = std::ceil((e.st.boundPadPx + 8.0) / 64.0) * 64.0;
        const double padWorld = padPx / std::max(seen, 1.0);
        const double hx = half.x * length(place[0].xyz),
                     hy = half.y * length(place[1].xyz);
        e.sides[0] = std::min(stageSides[0], hx + padWorld);
        e.sides[1] = std::min(stageSides[1], hx + padWorld);
        e.sides[2] = std::min(stageSides[2], hy + padWorld);
        e.sides[3] = std::min(stageSides[3], hy + padWorld);
      }
    } else if (e.st.allPointwiseTight) {
      std::fill(e.sides, e.sides + 4, 0.0);
    } else {
      doc_fx_sides(d, place, seen, e.sides);
    }
  }
  thing_fx_stand(*d.stage, e, place, half, seen);
}
// Where the layer lies on its effect image. false if no frame.
bool doc_fx_frame(Doc& d, int layer, const ThingFx& e, double* frame) {
  if (!e.world) return doc_frame(d, layer, d.stage->now, frame);
  std::copy(e.own, e.own + 4, frame), frame[4] = 0;
  return true;
}
// Draws a solid layer's effects; updates the solid from the image if needed.
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
// AviUtl2 script queries about other layers (see aviutl_fx.h). Layers are in
// stacking order, 1 = furthest back (doc_laid). Returns NaN for missing layers.
// Names: aviutl.layer, aviutl.layer_max, aviutl.layerN[.prop][@seconds],
// aviutl.groupN.
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

// Sets backdrop reading on every material that has a blendWay parameter.
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
// doc_reading for a layer with effects: blend mode is applied after effects.
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

#include "stage/layer_effects/layer_fx.h"

#include <filament/TextureSampler.h>
#include <filament/Viewport.h>
#include <utils/EntityManager.h>

#include "community/after_effects_plugin/ae_plugin.h"
#include "community/after_effects_plugin/ae_plugin_fx.h"
#include "community/aviutl/aviutl_run.h"
#include "community/three/solid_three.h"
#include "gpu/gpu_interop.h"
#include "stage/effects/screen_pool.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_layers.h"

namespace motolii {

using filament::Camera;
using filament::Renderer;
using filament::RenderTarget;
using filament::Scene;
using filament::Texture;
using filament::TextureSampler;
using filament::View;
using filament::Viewport;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
namespace backend = filament::backend;
namespace math = filament::math;

void thing_effects(Stage& s, ScreenStack& st, const std::string& files) {
  if (st.files == files) return;
  st.files = files;
  st.fx.clear();
  st.steps.clear();
  st.readsBehind = false, st.wide = false;
  std::vector<std::shared_ptr<AviutlRun>> scripts;
  std::vector<std::shared_ptr<AePluginRun>> plugins;
  for (const std::string& entry : script_files(files)) {
    if (entry == "none") continue;
    // Each entry may carry a per-instance ID prefix ("a1b2c3:blur.wgsl"); the
    // bare path is what the file-type gates and filesystem look-ups need, while
    // screen_built keyes its cache on the whole entry to keep instances apart.
    const std::string path = fx_entry_path(entry);
    // A native After Effects plugin (.plugin / .aex), run in an isolated
    // worker.
    if (ae_plugin_is(path)) {
      const auto found = std::find_if(
          st.aePlugins.begin(), st.aePlugins.end(),
          [&](const auto& r) { return r->numbers_key() == entry; });
      plugins.push_back(found != st.aePlugins.end() ? *found
                                                    : ae_plugin_open(s, entry));
      st.steps.push_back('p');
      continue;
    }
    // An AviUtl2 script. It runs each frame on the layer's image.
    if (aviutl_is(path)) {
      const auto found =
          std::find_if(st.aviutl.begin(), st.aviutl.end(),
                       [&](const auto& r) { return r->file == path; });
      // All scripts of a layer share one Lua state. AviUtl2 runs an object's
      // effects one after another in one Lua, so a global set by one script is
      // read by the next. For example the CrEasy background blur reads the ox
      // that CrEasy set.
      const auto first = !scripts.empty()     ? scripts.front()
                         : !st.aviutl.empty() ? st.aviutl.front()
                                              : nullptr;
      scripts.push_back(found != st.aviutl.end()
                            ? *found
                            : aviutl_open(s, path, first ? first->L : nullptr)),
          st.steps.push_back('a');
      // A script that reads its frame needs what is behind the layer: the stage
      // drawn without this layer's own sheet.
      st.readsBehind |= scripts.back()->behind;
      // A script that draws works on the whole stage, as AviUtl2 draws an
      // object on its screen.
      st.wide |= scripts.back()->wide;
      continue;
    }
    // A splat effect. The point cloud applies it; see render/point_cloud.h.
    if (std::filesystem::path(path).extension() == ".mjs") continue;
    // .am is AbsentMotion's own motion that moves the layer; see
    // absent_motion.h. .json is Filament's settings for the stage; see
    // viewer_settings.h. Neither is an effect here.
    if (const std::string ext =
            std::filesystem::path(path).extension().generic_string();
        ext == ".am" || ext == ".json")
      continue;
    // A solid's shape. The layer's image is laid on the solid, not run through
    // an effect; see thing_fx_solid.
    if (solid_is(path)) continue;
    // A file that moves the solid's points; see thing_fx_points.
    if (points_is(path)) continue;
    ScreenFx* built = screen_built(s, st, entry);
    if (built->interop) st.fx.push_back(built), st.steps.push_back(0);
    // AbsentMotion's backdrop reads what is behind the layer, the stage drawn
    // without it; see screen_fx.h.
    if (built->interop && std::find(built->others.begin(), built->others.end(),
                                    "backdrop") != built->others.end())
      st.readsBehind = true;
  }
  // Returns the effect's name: for an @ file the part after '#', otherwise the
  // file stem. Entries may carry an instance-ID prefix, so strip it first.
  const auto nameOf = [](const std::string& entry) {
    const std::string path = fx_entry_path(entry);
    const size_t hash = path.rfind('#');
    return hash != std::string::npos
               ? aviutl_unword(path.substr(hash + 1))
               : std::filesystem::path(path).stem().generic_string();
  };
  // The effect names in order. A script can ask for its neighbours with
  // obj.getoption("script_name").
  std::vector<std::string> names;
  for (const std::string& entry : script_files(files))
    if (entry != "none") names.push_back(nameOf(entry));
  for (const auto& r : scripts)
    r->chain = names,
    r->at = (int)(std::find(names.begin(), names.end(), nameOf(r->file)) -
                  names.begin());
  st.aviutl = scripts;
  st.aePlugins = plugins;
  st.allPointwiseTight =
      !st.steps.empty() && st.aviutl.empty() && st.aePlugins.empty() &&
      !st.readsBehind && !st.wide &&
      std::all_of(st.fx.begin(), st.fx.end(), [](const ScreenFx* f) {
        return f && f->pointwise && f->preservesZeroAlpha;
      });
}

void thing_fx_textures(Stage& s, ScreenStack& st, View* v, bool needShot) {
  const Viewport vp = v->getViewport();
  const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width),
                 h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
  const bool needOut = !st.steps.empty();
  const bool wantShot = needShot || !needOut;
  const bool shotOk = !wantShot || (st.shot && st.shot->getWidth() == w &&
                                    st.shot->getHeight() == h);
  const bool outOk =
      !needOut || (st.between[0] && st.between[0]->getWidth() == w &&
                   st.between[0]->getHeight() == h);
  if (shotOk && outOk) return;

  const auto newTexture = [&](int slot, const char* label) {
    WGPUTextureDescriptor like{};
    like.size = {w, h, 1};
    like.format = WGPUTextureFormat_BGRA8Unorm;
    like.usage = WGPUTextureUsage_RenderAttachment |
                 WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc |
                 WGPUTextureUsage_CopyDst;
    like.dimension = WGPUTextureDimension_2D;
    like.mipLevelCount = 1, like.sampleCount = 1;
    like.label = {label, WGPU_STRLEN};
    void* built = st.device[slot] =
        wgpuDeviceCreateTexture((WGPUDevice)interop::device(s.engine), &like);
    return Texture::Builder()
        .width(w)
        .height(h)
        .levels(1)
        .format(Texture::InternalFormat::RGBA8)
        .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE |
               Texture::Usage::BLIT_SRC)
        .import((intptr_t)built)
        .build(*s.engine);
  };

  // Lazily add `st.shot` without reallocating `st.between[0]` when a previously
  // flat-bypassed layer falls back to Filament rendering at the same size.
  if (wantShot && !st.shot && outOk && st.between[0]) {
    st.shot = newTexture(0, "thing shot");
    st.target = RenderTarget::Builder()
                    .texture(RenderTarget::AttachmentPoint::COLOR, st.shot)
                    .texture(RenderTarget::AttachmentPoint::DEPTH,
                             screen_pool_depth(s, w, h))
                    .build(*s.engine);
    return;
  }

  if (st.shot || st.between[0] || st.between[1])
    interop::invalidate_textures(s.engine);
  st.seen = nullptr;
  for (Texture*& t : {std::ref(st.shot), std::ref(st.depth),
                      std::ref(st.between[0]), std::ref(st.between[1])})
    if (t) s.engine->destroy(t), t = nullptr;
  for (RenderTarget*& r : {std::ref(st.target), std::ref(st.betweenTarget[0]),
                           std::ref(st.betweenTarget[1])})
    if (r) s.engine->destroy(r), r = nullptr;
  interop::on_driver(s.engine,
                     [built = std::vector<void*>(st.device, st.device + 3)] {
                       for (void* t : built)
                         if (t) wgpuTextureRelease((WGPUTexture)t);
                     });
  st.device[0] = st.device[1] = st.device[2] = nullptr;

  if (wantShot) {
    st.shot = newTexture(0, "thing shot");
    // Depth is shared across all layers of size w x h via StageFxCache.
    st.target = RenderTarget::Builder()
                    .texture(RenderTarget::AttachmentPoint::COLOR, st.shot)
                    .texture(RenderTarget::AttachmentPoint::DEPTH,
                             screen_pool_depth(s, w, h))
                    .build(*s.engine);
  }
  if (needOut) {
    st.between[0] = newTexture(1, "thing out");
    st.betweenTarget[0] =
        RenderTarget::Builder()
            .texture(RenderTarget::AttachmentPoint::COLOR, st.between[0])
            .build(*s.engine);
  }
}

namespace {
inline void fnv_mix(uint64_t& h, const void* data, size_t n) {
  const auto* p = static_cast<const uint8_t*>(data);
  for (size_t i = 0; i < n; ++i) h = (h ^ p[i]) * 1099511628211ull;
}
}  // namespace

void thing_effects_draw(Stage& s, ScreenStack& st, View* v,
                        const ScreenNumbers& numbers,
                        const ScreenTextures& textures, ThingFx* owner) {
  if (owner && owner->culled) return;
  screen_frame_begin(s);
  const bool useFlat =
      owner && owner->flatBypass && owner->flatTex && !st.steps.empty();
  thing_fx_textures(s, st, v, !useFlat);
  const Viewport vp = v->getViewport();
  const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width),
                 h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
  const auto renderLayer = [&](RenderTarget* target) {
    RenderTarget* const was = v->getRenderTarget();
    const Renderer::ClearOptions clearWas = s.renderer->getClearOptions();
    Renderer::ClearOptions clear = clearWas;
    clear.clearColor = {0, 0, 0, 0}, clear.clear = true, clear.discard = true;
    s.renderer->setClearOptions(clear);
    v->setRenderTarget(target);
    s.renderer->render(v);
    v->setRenderTarget(was);
    s.renderer->setClearOptions(clearWas);
  };

  if (st.steps.empty()) {
    renderLayer(st.target);
    st.seen = st.shot;
    if (owner) owner->cacheValid = false;
    return;
  }

  // Refresh compiled GPU steps before building the fused execution plan.
  for (ScreenFx* fx : st.fx) screen_fresh(s, *fx);
  st.allPointwiseTight =
      st.aviutl.empty() && st.aePlugins.empty() && !st.readsBehind &&
      !st.wide &&
      std::all_of(st.fx.begin(), st.fx.end(), [](const ScreenFx* f) {
        return f && f->pointwise && f->preservesZeroAlpha;
      });

  // Skip re-rendering static unchanged layers whose cached output in
  // `st.between[0]` still matches every transform, material, camera, and
  // evaluated effect parameter.
  uint64_t fullKey = 0;
  const bool canCache = owner && owner->cacheEligible && st.between[0] &&
                        st.between[0]->getWidth() == w &&
                        st.between[0]->getHeight() == h;
  if (canCache) {
    fullKey = owner->cacheBaseKey;
    fnv_mix(fullKey, &w, sizeof(w));
    fnv_mix(fullKey, &h, sizeof(h));
    for (ScreenFx* fx : st.fx) {
      const auto stampTicks = fx->stamp.time_since_epoch().count();
      fnv_mix(fullKey, &stampTicks, sizeof(stampTicks));
      fnv_mix(fullKey, &fx->interop, sizeof(fx->interop));
      if (fx->bytes > 0) {
        std::copy(fx->source ? st.own : st.frame,
                  (fx->source ? st.own : st.frame) + 4, fx->frame);
        std::copy(fx->frame, fx->frame + 4, fx->pass);
        fx->paramBuf.resize(fx->bytes / 4);
        screen_fill_parameters(s, *fx, numbers, fx->paramBuf.data(), 0, w, h);
        fx->paramBufFrame = s.frameCount;
        fx->paramBufW = w;
        fx->paramBufH = h;
        fx->paramBufPass = 0;
        // Skip unused `time`/`frame`/`clip_time` uniform slots while hashing
        // without mutating `paramBuf`, so `screen_draw_fused`/`screen_draw`
        // reuse the already-filled buffer directly on cache misses.
        if (fx->usesTime) {
          fnv_mix(fullKey, fx->paramBuf.data(), fx->bytes);
        } else {
          const size_t nFloats = fx->bytes / 4;
          for (size_t fi = 0; fi < nFloats; ++fi) {
            bool skip = false;
            for (const ScreenFx::Field& f : fx->fields) {
              if ((f.kind == ScreenFx::FieldKind::Time ||
                   f.kind == ScreenFx::FieldKind::ClipTime ||
                   f.kind == ScreenFx::FieldKind::Frame) &&
                  fi >= f.at / 4 && fi < f.at / 4 + f.floats) {
                skip = true;
                break;
              }
            }
            if (!skip) fnv_mix(fullKey, &fx->paramBuf[fi], sizeof(float));
          }
        }
      }
    }
    if (owner->cacheValid && st.seen == st.between[0] && owner->cacheW == w &&
        owner->cacheH == h && owner->cacheLastKey == fullKey) {
      return;
    }
  } else if (owner) {
    owner->cacheValid = false;
  }

  // Build an ordered list of logical passes, skipping GPU steps whose
  // zero-strength bypass condition (`--bypass:<param>`) holds this frame:
  // - Contiguous pointwise GPU steps are fused into a single WGSL shader pass.
  // - If step 0 is pointwise, linear->sRGB is folded into that pass.
  // - If the final step is pointwise, sRGB->linear is folded into that pass.
  const auto is_bypassed = [&](const ScreenFx& fx) -> bool {
    if (fx.bypassField < 0 || (size_t)fx.bypassField >= fx.fields.size())
      return false;
    const ScreenFx::Field& f = fx.fields[(size_t)fx.bypassField];
    const float val =
        (fx.paramValsFrame == s.frameCount && f.useCachedVal)
            ? f.paramVal[0]
            : (float)numbers(fx.numbers_key(), f.paramNames[0], f.usual[0]);
    return val <= fx.bypassBelow;
  };
  struct ActiveStep {
    char kind = 0;
    size_t idx = 0;
  };
  std::vector<ActiveStep> active;
  active.reserve(st.steps.size());
  {
    size_t fi = 0, ai = 0, pi = 0;
    for (char stepKind : st.steps) {
      if (stepKind == 0) {
        if (fi < st.fx.size() && !is_bypassed(*st.fx[fi]))
          active.push_back({0, fi});
        ++fi;
      } else if (stepKind == 'a') {
        active.push_back({'a', ai++});
      } else if (stepKind == 'p') {
        active.push_back({'p', pi++});
      }
    }
  }
  if (active.empty()) {
    if (useFlat) {
      screen_blit_flat(s, owner->flatTex, st.betweenTarget[0], w, h,
                       owner->flatRect, owner->flatWash, /*toLinear=*/true);
    } else {
      renderLayer(st.target);
      screen_place(s, st.shot, st.betweenTarget[0], w, h, nullptr);
    }
    st.seen = st.between[0];
    if (canCache) {
      owner->cacheValid = true;
      owner->cacheLastKey = fullKey;
      owner->cacheW = w;
      owner->cacheH = h;
    }
    return;
  }

  struct PlanStep {
    enum Kind { ToSrgb, FlatBlit, Fused, Gpu, Aviutl, AePlugin, ToLinear } kind;
    std::vector<ScreenFx*> fusedNodes;
    size_t fxIdx = 0;
    bool foldSrgb = false, foldLinear = false, foldFlat = false;
    size_t subIdx = 0;
  };
  std::vector<PlanStep> plan;
  bool srgbFolded = false, linearFolded = false;
  for (size_t i = 0; i < active.size();) {
    if (active[i].kind == 0 && st.fx[active[i].idx]->pointwise) {
      std::vector<ScreenFx*> nodes;
      size_t j = i;
      while (j < active.size() && active[j].kind == 0 &&
             st.fx[active[j].idx]->pointwise) {
        nodes.push_back(st.fx[active[j].idx]);
        ++j;
      }
      const bool atStart = (i == 0);
      const bool atEnd = (j == active.size());
      if (atStart || atEnd || nodes.size() >= 2) {
        if (atStart) srgbFolded = true;
        if (atEnd) linearFolded = true;
        PlanStep ps{PlanStep::Fused, std::move(nodes),   0, atStart && !useFlat,
                    atEnd,           atStart && useFlat, 0};
        plan.push_back(std::move(ps));
      } else {
        for (size_t k = i; k < j; ++k)
          plan.push_back(
              {PlanStep::Gpu, {}, active[k].idx, false, false, false, 0});
      }
      i = j;
      continue;
    }
    if (active[i].kind == 0)
      plan.push_back(
          {PlanStep::Gpu, {}, active[i].idx, false, false, false, 0});
    else if (active[i].kind == 'a')
      plan.push_back(
          {PlanStep::Aviutl, {}, 0, false, false, false, active[i].idx});
    else if (active[i].kind == 'p')
      plan.push_back(
          {PlanStep::AePlugin, {}, 0, false, false, false, active[i].idx});
    ++i;
  }
  if (!srgbFolded)
    plan.insert(plan.begin(),
                {useFlat ? PlanStep::FlatBlit : PlanStep::ToSrgb});
  if (!linearFolded) plan.push_back({PlanStep::ToLinear});

  if (!useFlat) renderLayer(st.target);
  PooledLayerSlot* scratchSlot =
      plan.size() > 1 ? screen_pool_acquire_layer(s, w, h, false) : nullptr;

  Texture* cur = useFlat ? owner->flatTex : st.shot;
  // Choose the first output target by parity so the final pass always lands
  // directly in `st.between[0]` (the layer's single owned output texture).
  const size_t total = plan.size();
  for (size_t k = 0; k < total; ++k) {
    const bool toOut = ((total - k) % 2) == 1;
    RenderTarget* destRt =
        toOut ? st.betweenTarget[0] : scratchSlot->colorTarget;
    Texture* destTex = toOut ? st.between[0] : scratchSlot->tex;
    const PlanStep& step = plan[k];
    switch (step.kind) {
      case PlanStep::ToSrgb:
        screen_tone(s, cur, destRt, w, h, true);
        break;
      case PlanStep::FlatBlit:
        screen_blit_flat(s, cur, destRt, w, h, owner->flatRect, owner->flatWash,
                         /*toLinear=*/false);
        break;
      case PlanStep::ToLinear:
        screen_tone(s, cur, destRt, w, h, false);
        break;
      case PlanStep::Fused: {
        const size_t n = step.fusedNodes.size();
        if (!screen_draw_fused(s, st, step.fusedNodes.data(), n, step.foldSrgb,
                               step.foldLinear, cur, destRt, numbers, w, h,
                               false, step.foldFlat ? owner->flatRect : nullptr,
                               step.foldFlat ? owner->flatWash : nullptr)) {
          // Rare fallback if Dawn rejects the fused shader: run nodes cleanly
          // through ping-pong scratch and land in `destRt`.
          PooledLayerSlot* tmp =
              scratchSlot ? nullptr : screen_pool_acquire_layer(s, w, h, false);
          PooledLayerSlot* alt = scratchSlot ? scratchSlot : tmp;
          Texture* fCur = cur;
          const size_t subTotal = n +
                                  ((step.foldSrgb || step.foldFlat) ? 1 : 0) +
                                  (step.foldLinear ? 1 : 0);
          size_t subIdx = 0;
          const auto subDest = [&]() -> std::pair<RenderTarget*, Texture*> {
            const bool landOnDest = ((subTotal - subIdx) % 2) == 1;
            ++subIdx;
            if (landOnDest) return {destRt, destTex};
            return destTex == st.between[0]
                       ? std::make_pair(alt->colorTarget, alt->tex)
                       : std::make_pair(st.betweenTarget[0], st.between[0]);
          };
          if (step.foldFlat) {
            auto [rt, tx] = subDest();
            screen_blit_flat(s, fCur, rt, w, h, owner->flatRect,
                             owner->flatWash, /*toLinear=*/false);
            fCur = tx;
          } else if (step.foldSrgb) {
            auto [rt, tx] = subDest();
            screen_tone(s, fCur, rt, w, h, true);
            fCur = tx;
          }
          for (ScreenFx* node : step.fusedNodes) {
            auto [rt, tx] = subDest();
            node->othersNow.clear();
            screen_draw(s, st, *node, fCur, rt, numbers, w, h);
            fCur = tx;
          }
          if (step.foldLinear) {
            auto [rt, tx] = subDest();
            screen_tone(s, fCur, rt, w, h, false);
            fCur = tx;
          }
          if (tmp) screen_pool_release_layer(s, tmp);
        }
        break;
      }
      case PlanStep::Gpu: {
        ScreenFx& one = *st.fx[step.fxIdx];
        one.othersNow.clear();
        for (const std::string& nm : one.others)
          one.othersNow.push_back(textures ? textures(one.file, nm) : nullptr);
        screen_draw(s, st, one, cur, destRt, numbers, w, h);
        break;
      }
      case PlanStep::Aviutl: {
        auto& run = st.aviutl[step.subIdx];
        std::copy(st.box, st.box + 4, run->box);
        std::copy(st.thingSeen, st.thingSeen + 4, run->seen);
        run->ground = st.ground;
        run->sounds = &st.sounds;
        aviutl_draw_step(s, *run, cur, destRt, numbers, w, h);
        break;
      }
      case PlanStep::AePlugin:
        ae_plugin_draw_step(s, *st.aePlugins[step.subIdx], cur, destRt, numbers,
                            textures, w, h);
        break;
    }
    cur = destTex;
  }

  if (scratchSlot) screen_pool_release_layer(s, scratchSlot);
  st.seen = st.between[0];
  if (canCache) {
    owner->cacheValid = true;
    owner->cacheLastKey = fullKey;
    owner->cacheW = w;
    owner->cacheH = h;
  }
}

namespace {
// Creates the view a layer is drawn alone in. It follows the offscreen view of
// samples/rendertarget.cpp: a scene of its own, a camera that follows the
// stage's, and post-processing off, since the stage's own view applies it once
// over everything.
View* thing_fx_view(Stage& s, ThingFx& e) {
  View* v = s.engine->createView();
  v->setScene(s.engine->createScene());
  v->getScene()->setIndirectLight(s.scene->getIndirectLight());
  e.eye = utils::EntityManager::get().create();
  e.camera = s.engine->createCamera(e.eye);
  v->setCamera(e.camera);
  v->setViewport(s.view->getViewport());
  v->setPostProcessingEnabled(false);
  // Both layer groups of the stage are visible, as in the stage's own view.
  v->setVisibleLayers(0x03, 0x03);
  v->setBlendMode(View::BlendMode::TRANSLUCENT);
  return v;
}
}  // namespace

void thing_fx_into(Stage& s, ThingFx& e, Scene* into) {
  Scene* const to = into ? into : s.scene;
  // Renderables created since then in the stage's scene are moved too.
  for (const Stage::Renderable& built : s.renderables)
    if ((built.of == e.sheet || (e.solid && built.of == e.solid)) &&
        !to->hasEntity(built.thing))
      (e.in ? e.in : s.scene)->remove(built.thing),
          s.scene->remove(built.thing), to->addEntity(built.thing);
  e.in = to == s.scene ? nullptr : to;
}

ThingFx& thing_fx_built(Stage& s, ThingFx& e, const std::string& lay,
                        bool world, bool shell) {
  if (e.view && e.lay == lay && e.world == world && e.shell == shell) return e;
  if (!e.view) e.view = thing_fx_view(s, e);
  thing_fx_into(s, e, s.scene);
  // A different way of lying needs the sheet made again.
  if (e.sheet) take_off(s, e.sheet), delete e.sheet;
  e.lay = lay, e.world = world, e.shell = shell;
  e.sheet = new Mesh;
  for (float2 c : {float2{-1, -1}, float2{1, -1}, float2{1, 1}, float2{-1, 1}})
    e.sheet->pos.push_back({c.x, c.y, 0.f}), e.sheet->nrm.push_back({0, 0, 1}),
        e.sheet->uv.push_back(c * 0.5f + 0.5f);
  e.sheet->idx = {0, 1, 2, 0, 2, 3};
  e.look = add(s, e.sheet,
               shell ? "effected_solid.filamat"
                     : (std::string(world ? "effected_world" : "effected") +
                        (lay.empty() ? "" : "_" + lay) + ".filamat")
                           .c_str(),
               {mat4f{}}, 1, world);
  // Only the material is wanted here, so the sheet itself is scaled to nothing.
  if (shell)
    move(s, e.sheet,
         [](int, const mat4f&) { return mat4f::scaling(float3{0.f}); });
  // Give it an image from the start, as the image.mat sample does. Filament
  // prepares every material instance before any view renders, and the layer's
  // own view is drawn first.
  e.look->setParameter("image", white_point(s), TextureSampler());
  // The place covers the whole stage until the layer is aimed.
  if (!world && !shell) e.look->setParameter("place", math::mat4f{});
  return e;
}

void thing_fx_off(Stage& s, ThingFx& e) {
  thing_fx_into(s, e, s.scene);
  if (s.engine && (e.st.device[0] || e.st.device[1] || e.st.device[2])) {
    interop::on_driver(
        s.engine, [built = std::vector<void*>(e.st.device, e.st.device + 3)] {
          for (void* t : built)
            if (t) wgpuTextureRelease((WGPUTexture)t);
        });
    e.st.device[0] = e.st.device[1] = e.st.device[2] = nullptr;
  }
  screen_stack_off(s, e.st);
  if (e.sheet) take_off(s, e.sheet), delete e.sheet;
  if (e.solid) take_off(s, e.solid), delete e.solid;
  if (e.view) s.engine->destroy(e.view->getScene()), s.engine->destroy(e.view);
  if (e.camera)
    s.engine->destroyCameraComponent(e.eye),
        utils::EntityManager::get().destroy(e.eye);
  e = ThingFx{};
}

}  // namespace motolii

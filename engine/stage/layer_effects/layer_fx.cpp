#include "stage/layer_effects/layer_fx.h"

#include <filament/TextureSampler.h>
#include <filament/Viewport.h>
#include <utils/EntityManager.h>

#include "community/aviutl/aviutl_run.h"
#include "community/three/solid_three.h"
#include "gpu/gpu_interop.h"
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
  for (const std::string& file : script_files(files)) {
    if (file == "none") continue;
    // An AviUtl2 script. It runs each frame on the layer's image.
    if (aviutl_is(file)) {
      const auto found =
          std::find_if(st.aviutl.begin(), st.aviutl.end(),
                       [&](const auto& r) { return r->file == file; });
      // All scripts of a layer share one Lua state. AviUtl2 runs an object's
      // effects one after another in one Lua, so a global set by one script is
      // read by the next. For example the CrEasy background blur reads the ox
      // that CrEasy set.
      const auto first = !scripts.empty()     ? scripts.front()
                         : !st.aviutl.empty() ? st.aviutl.front()
                                              : nullptr;
      scripts.push_back(found != st.aviutl.end()
                            ? *found
                            : aviutl_open(s, file, first ? first->L : nullptr)),
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
    if (std::filesystem::path(file).extension() == ".mjs") continue;
    // .am is AbsentMotion's own motion that moves the layer; see
    // absent_motion.h. .json is Filament's settings for the stage; see
    // viewer_settings.h. Neither is an effect here.
    if (const std::string ext =
            std::filesystem::path(file).extension().string();
        ext == ".am" || ext == ".json")
      continue;
    // A solid's shape. The layer's image is laid on the solid, not run through
    // an effect; see thing_fx_solid.
    if (solid_is(file)) continue;
    // A file that moves the solid's points; see thing_fx_points.
    if (points_is(file)) continue;
    ScreenFx* built = screen_built(s, st, file);
    if (built->interop) st.fx.push_back(built), st.steps.push_back(0);
    // AbsentMotion's backdrop reads what is behind the layer, the stage drawn
    // without it; see screen_fx.h.
    if (built->interop && std::find(built->others.begin(), built->others.end(),
                                    "backdrop") != built->others.end())
      st.readsBehind = true;
  }
  // Returns the effect's name: for an @ file the part after '#', otherwise the
  // file stem.
  const auto nameOf = [](const std::string& file) {
    const size_t hash = file.rfind('#');
    return hash != std::string::npos
               ? aviutl_unword(file.substr(hash + 1))
               : std::filesystem::path(file).stem().string();
  };
  // The effect names in order. A script can ask for its neighbours with
  // obj.getoption("script_name").
  std::vector<std::string> names;
  for (const std::string& file : script_files(files))
    if (file != "none") names.push_back(nameOf(file));
  for (const auto& r : scripts)
    r->chain = names,
    r->at = (int)(std::find(names.begin(), names.end(), nameOf(r->file)) -
                  names.begin());
  st.aviutl = scripts;
}

void thing_fx_textures(Stage& s, ScreenStack& st, View* v) {
  const Viewport vp = v->getViewport();
  const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width),
                 h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
  // Recreate everything when the viewport size changes.
  if (!st.shot || st.shot->getWidth() != w || st.shot->getHeight() != h) {
    for (Texture*& t : {std::ref(st.shot), std::ref(st.depth),
                        std::ref(st.between[0]), std::ref(st.between[1])})
      if (t) s.engine->destroy(t), t = nullptr;
    for (RenderTarget*& r : {std::ref(st.target), std::ref(st.betweenTarget[0]),
                             std::ref(st.betweenTarget[1])})
      if (r) s.engine->destroy(r), r = nullptr;
    // Release the device textures only after the drawing that uses them has
    // finished.
    interop::on_driver(s.engine,
                       [built = std::vector<void*>(st.device, st.device + 3)] {
                         for (void* t : built)
                           if (t) wgpuTextureRelease((WGPUTexture)t);
                       });
    int n = 0;
    // Creates a texture on the device so that ThorVG can read and draw it, and
    // imports it into Filament.
    const auto newTexture = [&] {
      WGPUTextureDescriptor like{};
      like.size = {w, h, 1};
      // The format ThorVG's last step writes, as for an image of its own; see
      // canvas.h.
      like.format = WGPUTextureFormat_BGRA8Unorm;
      like.usage = WGPUTextureUsage_RenderAttachment |
                   WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopySrc |
                   WGPUTextureUsage_CopyDst;
      like.dimension = WGPUTextureDimension_2D;
      like.mipLevelCount = 1, like.sampleCount = 1;
      static const char* const names[3] = {"thing shot", "thing between 0",
                                           "thing between 1"};
      like.label = {names[n], WGPU_STRLEN};
      void* built = st.device[n++] =
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
    st.shot = newTexture();
    st.depth = Texture::Builder()
                   .width(w)
                   .height(h)
                   .levels(1)
                   .usage(Texture::Usage::DEPTH_ATTACHMENT)
                   .format(Texture::InternalFormat::DEPTH24)
                   .build(*s.engine);
    st.target = RenderTarget::Builder()
                    .texture(RenderTarget::AttachmentPoint::COLOR, st.shot)
                    .texture(RenderTarget::AttachmentPoint::DEPTH, st.depth)
                    .build(*s.engine);
    for (int k = 0; k < 2; ++k)
      st.between[k] = newTexture(),
      st.betweenTarget[k] =
          RenderTarget::Builder()
              .texture(RenderTarget::AttachmentPoint::COLOR, st.between[k])
              .build(*s.engine);
  }
}

void thing_effects_draw(Stage& s, ScreenStack& st, View* v,
                        const ScreenNumbers& numbers,
                        const ScreenTextures& textures) {
  // The textures already exist if the layer was aimed; otherwise they are
  // created here.
  thing_fx_textures(s, st, v);
  const Viewport vp = v->getViewport();
  const uint32_t w = (uint32_t)std::max(1, vp.left + (int)vp.width),
                 h = (uint32_t)std::max(1, vp.bottom + (int)vp.height);
  RenderTarget* const was = v->getRenderTarget();
  const Renderer::ClearOptions clearWas = s.renderer->getClearOptions();
  Renderer::ClearOptions clear = clearWas;
  // Draw the layer alone, on a transparent background.
  clear.clearColor = {0, 0, 0, 0}, clear.clear = true, clear.discard = true;
  s.renderer->setClearOptions(clear);
  v->setRenderTarget(st.target);
  s.renderer->render(v);
  v->setRenderTarget(was);
  s.renderer->setClearOptions(clearWas);
  st.seen = st.shot;
  // With no effects only the layer's own image is needed, for other layers to
  // use.
  if (st.steps.empty()) return;
  // Convert the image to sRGB for the effects; see screen_tone in screen_fx.h.
  screen_tone(s, st.shot, st.betweenTarget[1], w, h, true);
  // Each step draws into one of the two alternating textures. The effects take
  // the whole texture as their input and fill what is clear.
  for (size_t i = 0, f = 0, a = 0; i < st.steps.size(); ++i) {
    Texture* from = i == 0 ? st.between[1] : st.between[(i - 1) % 2];
    // An AviUtl2 script, told where the layer is seen.
    if (st.steps[i] == 'a') {
      std::copy(st.box, st.box + 4, st.aviutl[a]->box),
          std::copy(st.thingSeen, st.thingSeen + 4, st.aviutl[a]->seen),
          st.aviutl[a]->ground = st.ground, st.aviutl[a]->sounds = &st.sounds;
      aviutl_draw_step(s, *st.aviutl[a++], from, st.betweenTarget[i % 2],
                       numbers, w, h);
      continue;
    }
    screen_fresh(s, *st.fx[f]);
    ScreenFx& one = *st.fx[f++];
    one.othersNow.clear();
    for (const std::string& n : one.others)
      one.othersNow.push_back(textures ? textures(one.file, n) : nullptr);
    screen_draw(s, st, one, from, st.betweenTarget[i % 2], numbers, w, h);
  }
  // Convert back to linear light, as the stage expects.
  screen_tone(s, st.between[(st.steps.size() - 1) % 2],
              st.betweenTarget[st.steps.size() % 2], w, h, false);
  st.seen = thing_fx_seen(st);
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
  if (e.sheet) take_off(s, e.sheet), delete e.sheet;
  if (e.solid) take_off(s, e.solid), delete e.solid;
  if (e.view) s.engine->destroy(e.view->getScene()), s.engine->destroy(e.view);
  if (e.camera)
    s.engine->destroyCameraComponent(e.eye),
        utils::EntityManager::get().destroy(e.eye);
  e = ThingFx{};
}

}  // namespace motolii

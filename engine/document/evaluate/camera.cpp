#include "document/evaluate/camera.h"

#include <filament/Camera.h>
#include <filament/Color.h>
#include <filament/ColorGrading.h>
#include <filament/Engine.h>
#include <filament/IndirectLight.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/Scene.h>
#include <filament/Skybox.h>
#include <filament/Texture.h>
#include <filament/ToneMapper.h>
#include <filament/View.h>
#include <image/Ktx1Bundle.h>
#include <ktxreader/Ktx1Reader.h>
#include <math/mat3.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <viewer/Settings.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/place.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/scripts/scripts.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/viewer_settings.h"
#include "stage/render/render_draw.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace motolii {

DocViewCamera doc_view_camera_of(Doc& d, int camera, double now) {
  const auto turned = [&](const char* name, math::double3 about) {
    return camera ? math::mat4::rotation(doc_number(d, camera, name, now, 0) *
                                             (double)TAU / 360.0,
                                         about)
                  : math::mat4{};
  };
  DocViewCamera e;
  e.round = turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0}) *
            turned("rotate", {0, 0, 1});
  e.look = camera ? (doc_place(d, camera, now) * math::double4{0, 0, 0, 1}).xyz
                  : math::double3{0.0};
  e.far = camera ? doc_number(d, camera, "distance", now, 1) : 1.0;
  e.fov =
      2.0 * std::atan(std::tan(15.0 * (double)TAU / 360.0) /
                      (camera ? doc_number(d, camera, "zoom", now, 1) : 1.0));
  e.eye = e.look + (e.round * math::double4{0, 0, 6.0 * e.far, 0}).xyz,
  e.up = (e.round * math::double4{0, 1, 0, 0}).xyz;
  return e;
}

void doc_look(Doc& d) {
  Stage& s = *d.stage;
  // Reads a six digit RRGGBB hex property as a color with components from 0
  // to 1. Returns `otherwise` when the property is not six digits.
  const auto hex = [&](const char* name, float3 otherwise) {
    const std::string w = doc_word(d, 0, name);
    return w.size() == 6
               ? float3{(float)((std::strtol(w.c_str(), nullptr, 16) >> 16) &
                                255),
                        (float)((std::strtol(w.c_str(), nullptr, 16) >> 8) &
                                255),
                        (float)(std::strtol(w.c_str(), nullptr, 16) & 255)} /
                     255.f
               : otherwise;
  };
  const std::string mapper = doc_word(d, 0, "tone_mapper");
  // All the grading values as one string. It is the key that detects a change,
  // so the color grading is rebuilt only when this differs from the last one.
  char grade[300];
  // Slope, offset and power are the ASC CDL values of the grading.
  const float slope = (float)doc_number(d, 0, "slope", 0, 1),
              offset = (float)doc_number(d, 0, "offset", 0, 0),
              power = (float)doc_number(d, 0, "power", 0, 1);
  std::snprintf(
      grade, sizeof grade, "%s %g %g %g %g %g %g %g %g", mapper.c_str(),
      doc_number(d, 0, "exposure", 0, 0), doc_number(d, 0, "contrast", 0, 1),
      doc_number(d, 0, "saturation", 0, 1), doc_number(d, 0, "vibrance", 0, 1),
      doc_number(d, 0, "temperature", 0, 0), slope, offset, power);
  // Reads the shadows, midtones or highlights color, appends its text to the
  // key and converts the color from sRGB to linear.
  const auto tint = [&](const char* name) {
    const float3 c = hex(name, float3{1.f});
    std::strncat(grade, (" " + doc_word(d, 0, name)).c_str(), 20);
    return float4{Color::toLinear<ACCURATE>(sRGBColor{c}), 0.f};
  };
  const float4 low = tint("shadows_color"), mid = tint("midtones_color"),
               high = tint("highlights_color");
  // Filament viewer settings files (JSON) with the parameter values of their
  // effects filled in, see stage/effects/viewer_settings.h. They can be on the
  // canvas or on the effects of any layer, as the shelf puts them.
  std::vector<std::string> told;
  // The layers that may carry settings files: the canvas, and every layer whose
  // fx names a .json file.
  std::vector<int> holders{0};
  doc_rows(d,
           sqlite3_mprintf("select distinct layer from keyframe where name = "
                           "'fx' and value like '%%.json%%'"),
           [&](sqlite3_stmt* row) {
             holders.push_back(sqlite3_column_int(row, 0));
           });
  for (const int h : holders)
    for (const std::string& file :
         script_files(doc_word(d, h, h == 0 ? "script" : "fx")))
      if (DocScript* sc = doc_script_of(d, file); sc && sc->viewer)
        told.push_back(viewer_said(file, sc->parameters, [&](size_t k) {
          return doc_number(d, h, sc->names[k].c_str(), s.now,
                            sc->parameters[k].usual);
        }));
  // True when a settings file sets color grading.
  const bool theirs =
      std::any_of(told.begin(), told.end(), [](const std::string& t) {
        return t.find("\"colorGrading\"") != std::string::npos;
      });
  std::string key = grade;
  // A settings file's grading replaces the canvas's, so its text is part of the
  // key.
  if (theirs)
    for (const std::string& t : told) key += t;
  if (d.graded != key) {
    static LinearToneMapper linear;
    static ACESToneMapper aces;
    static FilmicToneMapper filmic;
    static AgxToneMapper agx;
    static PBRNeutralToneMapper neutral;
    const ToneMapper* tm = mapper == "aces"     ? (const ToneMapper*)&aces
                           : mapper == "filmic" ? (const ToneMapper*)&filmic
                           : mapper == "agx"    ? (const ToneMapper*)&agx
                           : mapper == "pbr_neutral"
                               ? (const ToneMapper*)&neutral
                               : (const ToneMapper*)&linear;
    // The previous grading, destroyed once the new one is set.
    ColorGrading* was = const_cast<ColorGrading*>(s.view->getColorGrading());
    ColorGrading* now = nullptr;
    // A settings file's grading is the whole grading, built as Filament's
    // viewer builds it.
    if (theirs) {
      filament::viewer::Settings in;
      filament::viewer::JsonSerializer read;
      for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
      now =
          filament::viewer::createColorGrading(in.view.colorGrading, s.engine);
    } else
      now = ColorGrading::Builder()
                .toneMapper(tm)
                .exposure((float)doc_number(d, 0, "exposure", 0, 0))
                .contrast((float)doc_number(d, 0, "contrast", 0, 1))
                .saturation((float)doc_number(d, 0, "saturation", 0, 1))
                .vibrance((float)doc_number(d, 0, "vibrance", 0, 1))
                .whiteBalance((float)doc_number(d, 0, "temperature", 0, 0), 0.f)
                .slopeOffsetPower(float3{slope}, float3{offset}, float3{power})
                // The ranges of shadows, midtones and highlights are Filament's
                // defaults.
                .shadowsMidtonesHighlights(low, mid, high,
                                           float4{0.f, 0.333f, 0.55f, 1.f})
                .build(*s.engine);
    s.view->setColorGrading(now);
    if (was) s.engine->destroy(was);
    d.graded = key;
  }
  View::BloomOptions glow = s.view->getBloomOptions();
  glow.enabled = doc_number(d, 0, "bloom", 0, 0) > 0.0,
  glow.strength = (float)doc_number(d, 0, "bloom", 0, 0);
  glow.lensFlare = glow.starburst = doc_number(d, 0, "lens_flare", 0, 0) > 0.0;
  // A lens flare is drawn by the passes of the bloom, so bloom is switched on
  // with it.
  glow.enabled = glow.enabled || glow.lensFlare;
  glow.chromaticAberration =
      0.005f * (float)doc_number(d, 0, "lens_flare", 0, 0),
  glow.ghostThreshold = glow.haloThreshold = 1.f;
  s.view->setBloomOptions(glow);
  // The anti-aliasing mode of the canvas view. Each image layer smooths its own
  // edges separately.
  const std::string smooth = doc_word(d, 0, "anti_aliasing");
  for (View* v : std::vector<View*>{s.view}) {
    v->setAntiAliasing(smooth.empty() || smooth == "fxaa"
                           ? View::AntiAliasing::FXAA
                           : View::AntiAliasing::NONE);
    View::TemporalAntiAliasingOptions taa = v->getTemporalAntiAliasingOptions();
    taa.enabled = smooth == "taa";
    v->setTemporalAntiAliasingOptions(taa);
  }
  View::MultiSampleAntiAliasingOptions many =
      s.view->getMultiSampleAntiAliasingOptions();
  many.enabled = smooth == "msaa", many.sampleCount = 4;
  s.view->setMultiSampleAntiAliasingOptions(many);
  View::VignetteOptions corners = s.view->getVignetteOptions();
  corners.enabled = doc_number(d, 0, "vignette", 0, 0) > 0.0,
  corners.midPoint = 1.f - 0.9f * (float)doc_number(d, 0, "vignette", 0, 0),
  corners.color = LinearColorA{hex("vignette_color", float3{0.f}), 1.f};
  s.view->setVignetteOptions(corners);
  View::FogOptions haze = s.view->getFogOptions();
  // The layer whose fog is used. It is the camera that the window looks through
  // if that camera sets a fog of its own, as Alight Motion's camera Fog does.
  // Otherwise it is the canvas.
  const int fogBy =
      d.looking && doc_number(d, d.looking, "fog", 0, 0) > 0.0 ? d.looking : 0;
  const std::string fogColour = doc_word(d, fogBy, "fog_color");
  // Fog is uniform in height: the height is far below the canvas and the height
  // falloff is 0.
  haze.enabled = !d.working && doc_number(d, fogBy, "fog", 0, 0) > 0.0,
  haze.density = 0.5f * (float)doc_number(d, fogBy, "fog", 0, 0),
  haze.distance = (float)doc_number(d, fogBy, "fog_near", 0, 2),
  haze.height = -1e3f, haze.heightFalloff = 0.f,
  haze.color =
      fogColour.size() == 6
          ? float3{(float)((std::strtol(fogColour.c_str(), nullptr, 16) >> 16) &
                           255),
                   (float)((std::strtol(fogColour.c_str(), nullptr, 16) >> 8) &
                           255),
                   (float)(std::strtol(fogColour.c_str(), nullptr, 16) & 255)} /
                255.f
          : float3{0.85f, 0.85f, 0.9f},
  haze.fogColorFromIbl = false;
  // When `fog_far` is set, as in Alight Motion, the density is chosen so that
  // the fog is 98 percent opaque at that distance. Filament's fog transmits
  // e^(-density * distance past its start), so the density is ln(50) divided by
  // the distance. This is also how three.js's linear Fog far maps onto its
  // FogExp2.
  if (const double far = doc_number(d, fogBy, "fog_far", 0, 0);
      far > haze.distance)
    haze.density = (float)(doc_number(d, fogBy, "fog", 0, 0) * std::log(50.0) /
                           (far - haze.distance));
  s.view->setFogOptions(haze);
  View::AmbientOcclusionOptions folds = s.view->getAmbientOcclusionOptions();
  folds.enabled = doc_number(d, 0, "ambient_occlusion", 0, 0) > 0.0,
  folds.intensity = 2.f * (float)doc_number(d, 0, "ambient_occlusion", 0, 0);
  s.view->setAmbientOcclusionOptions(folds);
  View::ScreenSpaceReflectionsOptions mirror =
      s.view->getScreenSpaceReflectionsOptions();
  mirror.enabled = doc_number(d, 0, "reflections", 0, 0) > 0.0;
  s.view->setScreenSpaceReflectionsOptions(mirror);
  // Filament settings files are applied over the canvas settings. They start
  // from the options the view has now, so any section that a file does not name
  // keeps its value.
  if (!told.empty()) {
    filament::viewer::Settings in;
    in.view.bloom = s.view->getBloomOptions(),
    in.view.vignette = s.view->getVignetteOptions(),
    in.view.fog = s.view->getFogOptions();
    in.view.ssao = s.view->getAmbientOcclusionOptions(),
    in.view.screenSpaceReflections = s.view->getScreenSpaceReflectionsOptions();
    filament::viewer::JsonSerializer read;
    for (const std::string& t : told) read.readJson(t.c_str(), t.size(), &in);
    s.view->setBloomOptions(in.view.bloom),
        s.view->setVignetteOptions(in.view.vignette),
        s.view->setFogOptions(in.view.fog);
    s.view->setAmbientOcclusionOptions(in.view.ssao),
        s.view->setScreenSpaceReflectionsOptions(
            in.view.screenSpaceReflections);
  }
  // Remember the intensity of the light that the canvas was opened with.
  if (d.roomLight <= 0.f && s.scene->getIndirectLight())
    d.roomLight = s.scene->getIndirectLight()->getIntensity();
  std::string which = doc_word(d, 0, "room");
  // The room that the canvas was opened with.
  if (which.empty()) which = "small_studio";
  // Another room: its light is made once from its file and then reused. Every
  // image laid over the canvas is lit by it too.
  if (which != d.roomIs) {
    static std::map<std::string, IndirectLight*> made;
    // The first time, register the light in use under the current room name, so
    // that the canvas can switch back to it.
    if (!d.roomIs.empty() || made.empty())
      made.emplace(d.roomIs.empty() ? "small_studio" : d.roomIs,
                   s.scene->getIndirectLight());
    const auto found = made.find(which);
    if (found != made.end())
      s.scene->setIndirectLight(found->second);
    else if (room(s, ("out/" + which + "/" + which + "_ibl.ktx").c_str(),
                  d.roomLight))
      made[which] = s.scene->getIndirectLight();
    d.roomIs = which;
  }
  if (IndirectLight* room = s.scene->getIndirectLight()) {
    room->setIntensity(d.roomLight *
                       (float)doc_number(d, 0, "environment", 0, 1));
    room->setRotation(math::mat3f::rotation(
        (float)(doc_number(d, 0, "environment_rotate", 0, 0) * (double)TAU /
                360.0),
        math::float3{0, 1, 0}));
  }
  // Gives the canvas effects access to the analysis of a sound file.
  d.screen.sounds = [&d](const std::string& file, const std::string& name,
                         bool fft, int wide) {
    return doc_sound_now(d, 0, file, name, fft, wide);
  };
  // Supplies the parameter values of the canvas effects.
  screen_effects(
      s, d.screen, doc_word(d, 0, "script"),
      [&d](const std::string& file, const std::string& name, double usual) {
        // Called while the frame is drawn, when the render thread does not hold
        // the lock.
        std::lock_guard<std::recursive_timed_mutex> hold(d.lock);
        // Parameters of a mouse: when the followed layer is on the canvas, the
        // value is that layer's position. `pointer` is as on the web, from -1
        // to 1 with y up. The others are from 0 to 1 from the top left, as the
        // uv of the effects.
        static const char* const mice[] = {"pointer", "center", "mouse",
                                           "point"};
        if (const int t = (int)doc_number(d, 0, "follow", 0, 0);
            t > 0 && name.size() > 2 && name[name.size() - 2] == '_')
          for (const char* mouse : mice)
            if (name.compare(0, name.size() - 2, mouse) == 0) {
              double frame[8];
              if (!doc_knows(d, t, nullptr, nullptr, nullptr, false) ||
                  !doc_frame(d, t, d.stage->now, frame))
                break;
              const bool across = name.back() == 'x';
              const double at =
                  across ? frame[0] / d.stage->w : frame[1] / d.stage->h;
              return !strcmp(mouse, "pointer")
                         ? (across ? 2.0 * at - 1.0 : 1.0 - 2.0 * at)
                         : at;
            }
        // The canvas's own time and length are the project's.
        if (name == "clip_time") return d.stage->now;
        if (name == "clip_length") return doc_seconds(d);
        return doc_number(d, 0, doc_screen_parameter(file, name).c_str(),
                          d.stage->now, usual);
      });
  // The background color.
  const std::string behind = doc_word(d, 0, "background");
  // The room itself is shown behind everything, as bright as it lights the
  // canvas. Its sky image is made once for each room.
  if (doc_word(d, 0, "behind") == "room") {
    static std::map<std::string, Skybox*> shown;
    Skybox*& sky = shown[d.roomIs];
    if (!sky) {
      // The sky image refers to this memory, so it must stay alive.
      static std::vector<std::vector<uint8_t>> kept;
      kept.push_back(load_file(
          ("out/" + d.roomIs + "/" + d.roomIs + "_skybox.ktx").c_str()));
      if (!kept.back().empty())
        if (Texture* tex = ktxreader::Ktx1Reader::createTexture(
                s.engine,
                new image::Ktx1Bundle(kept.back().data(),
                                      (uint32_t)kept.back().size()),
                false))
          // The sky shows the sun disc, which is one of the lights. Filament
          // takes the brightness of the sky when it is made.
          sky = Skybox::Builder()
                    .environment(tex)
                    .intensity(d.roomLight)
                    .showSun(true)
                    .build(*s.engine);
    }
    if (sky) sky->setLayerMask(0xFF, 0x01);
    s.scene->setSkybox(sky);
  } else
    s.scene->setSkybox(nullptr);
  // A background color is a flat rectangle as large as the canvas, attached to
  // the camera, drawn first in the canvas view without writing depth, so every
  // layer is drawn over it. Filament's sky is drawn after the layers it
  // contains and a flat layer writes no depth, so a sky would be painted over
  // them. The rectangle is opaque, because Filament draws blended sheets after
  // all solid layers whatever their priority, so a blended backdrop was painted
  // over the solids. There is no color when the room is the background.
  const std::string colour = doc_word(d, 0, "behind") == "room" ? "" : behind;
  if (colour != d.backdropIs) {
    if (d.backdrop) canvas_off(s, d.backdrop), d.backdrop = nullptr;
    if (!colour.empty()) {
      const math::double4 up = s.camera->getProjectionMatrix() *
                               s.camera->getViewMatrix() *
                               math::double4{0, 1, 0, 1};
      // Opaque, so that Filament draws it with the solid layers, first by its
      // priority, and not over them with the blended sheets.
      if ((d.backdrop = flat(s, "rect", (float)s.w / (float)s.h, mat4f{},
                             (float)(2.0 * up.w / up.y),
                             hex("background", float3{0.f}), "opaque"))) {
        auto& faces = s.engine->getRenderableManager();
        for (const Stage::Renderable& made : s.renderables)
          if (made.of == d.backdrop->sheet)
            faces.setPriority(faces.getInstance(made.thing), 0),
                faces.setChannel(faces.getInstance(made.thing), 0);
        d.backdrop->look->setDepthWrite(false),
            d.backdrop->look->setDepthCulling(false);
      }
    }
    d.backdropIs = colour;
  }
  if (d.backdrop)
    move(s, d.backdrop->sheet, [&](int, const mat4f&) { return mat4f(d.rig); });
}

}  // namespace motolii

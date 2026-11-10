#include "document/match.h"

#include <filament/Color.h>
#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/TextureSampler.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <utils/Entity.h>
#include <utils/EntityManager.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <map>
#include <memory>
#include <sstream>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/script_runner/script_runner.h"
#include "document/card_table.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
#include "document/match/match_describe.h"
#include "document/match/match_layers.h"
#include "document/match/match_look.h"
#include "document/match/match_shape.h"
#include "document/match/match_video.h"
#include "document/match/rebuild.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "media/midi_notes.h"
#include "media/midi_roll.h"
#include "media/video_datamosh.h"
#include "media/video_layer.h"
#include "motion/lottie_motion.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/canvas_sketch.h"
#include "stage/render/gltf_model.h"
#include "stage/render/point_cloud.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::Engine;
using filament::LightManager;
using filament::Material;
using filament::MaterialInstance;
using filament::RenderableManager;
using filament::TextureSampler;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4;
using filament::math::mat4f;
namespace math = filament::math;

namespace {

// Converts text for a column of vertical writing, like After Effects' Vertical
// Type. Punctuation that lies along a line is replaced by its Unicode
// <vertical> presentation form. The long vowel mark has no such form there, so
// it becomes a stroke as heavy as the letters. There is no outside source for
// that choice: a font's vert feature would draw its own glyph, and ThorVG reads
// no such feature.
std::string doc_column(std::string words) {
  static const char* const forms[][2] = {
      {"，", "︐"}, {"、", "︑"}, {"。", "︒"}, {"：", "︓"}, {"；", "︔"},
      {"！", "︕"}, {"？", "︖"}, {"〖", "︗"}, {"〗", "︘"}, {"…", "︙"},
      {"‥", "︰"},  {"—", "︱"},  {"ー", "丨"}, {"–", "︲"},  {"（", "︵"},
      {"）", "︶"}, {"｛", "︷"}, {"｝", "︸"}, {"〔", "︹"}, {"〕", "︺"},
      {"【", "︻"}, {"】", "︼"}, {"《", "︽"}, {"》", "︾"}, {"〈", "︿"},
      {"〉", "﹀"}, {"「", "﹁"}, {"」", "﹂"}, {"『", "﹃"}, {"』", "﹄"},
      {"［", "﹇"}, {"］", "﹈"}};
  for (const auto& form : forms)
    for (size_t at = 0; (at = words.find(form[0], at)) != std::string::npos;
         at += strlen(form[1]))
      words.replace(at, strlen(form[0]), form[1]);
  return words;
}
// Returns the path of drawing number n of the level that `file` belongs to. The
// drawings of a level are files in one folder, told apart by the number at the
// end of the file name, between the name and the extension, as OpenToonz reads
// a level (animation.0001.tif, animation_0001.tif; see tfilepath.cpp, pattern
// (\d+)). The number is padded to the width of the number in `file`. Returns
// "" when n is negative, which is a cross in the timesheet and means no
// drawing. Returns `file` itself when its name ends in no number.
std::string doc_cel_file(const std::string& file, double n) {
  if (n < 0) return "";
  const std::filesystem::path p(file);
  const std::string stem = p.stem().string();
  size_t from = stem.size();
  while (from > 0 && std::isdigit((unsigned char)stem[from - 1])) --from;
  if (from == stem.size()) return file;
  std::string number = std::to_string((long long)std::llround(n));
  if (number.size() < stem.size() - from)
    number.insert(0, stem.size() - from - number.size(), '0');
  return (p.parent_path() /
          (stem.substr(0, from) + number + p.extension().string()))
      .string();
}

}  // namespace

long long doc_sketch_written(Doc& d, const std::string& file) {
  DocSketch& one = doc_scripts_kept(d).sketches[file];
  std::error_code wrong;
  const long long stamp =
      (long long)std::filesystem::last_write_time(file, wrong)
          .time_since_epoch()
          .count();
  if (wrong || stamp == one.seen) return one.whole;
  one.seen = stamp;
  auto run = std::make_shared<Script>(
      file, (doc_engine("third_party/js/p5") / "p5.min.js").string());
  if (run->flat()) one.whole = stamp, one.ready = run;
  if (run->ok())
    doc_scripts_kept(d).why.erase(file);
  else
    doc_scripts_kept(d).why[file] = d.error = run->trouble();
  return one.whole;
}
bool doc_match(Doc& d) {
  Stage& s = *d.stage;
  // The frame rate of the document. Time is shown in whole frames from the next
  // frame on.
  s.frames = doc_number(d, 0, "frame_rate", 0, 0);
  Rebuild rebuild{d, s};
  match_describe_layers(rebuild);
  match_tear_down_changed(rebuild);
  const std::map<int, std::string>& told = rebuild.told;
  bool& all = rebuild.all;
  for (const auto& [layer, of] : told) {
    if (d.on_stage.shown.count(layer)) continue;
    LayerBuild build{d, s, layer, DocShownLayer{of}};
    DocShownLayer& made = build.made;
    build.kind = doc_word(d, layer, "kind");
    build.file = doc_word(d, layer, "file");
    build.laid = doc_word(d, layer, "blend");
    build.shape = doc_word(d, layer, "shape");
    const std::string &kind = build.kind, &file = build.file,
                      &laid = build.laid, &shape = build.shape;
    // A layer with effect files of its own is drawn alone as normal. Its blend
    // mode is applied once the effects are on (screen_fx.h).
    const bool effected = doc_fx_files(doc_fx_steps(d, layer));
    // lay is the blend mode for the GPU, or null when the layer is drawn as
    // normal. That is the case with effects, with no blend mode, or with a mode
    // that reads the pixels underneath, which flat.mat mixes itself.
    build.lay =
        effected || laid.empty() || laid == "normal" || doc_blend_way(laid)
            ? nullptr
            : laid.c_str();
    const char* lay = build.lay;
    std::string& why = build.why;
    match_fill(build);
    const std::string& fill = build.fill;
    const std::vector<float4>& ramp = build.ramp;
    const long rgb = build.rgb;
    const float3 colour = build.colour;
    match_stroke(build);
    const std::string& stroke = build.stroke;
    const long edgeRgb = build.edgeRgb;
    const math::double4 up = build.up;
    const float4 edge = build.edge;
    const double units = build.units;
    match_flat_look(build);
    Canvas2DFx& fx = build.fx;
    const bool fxOk = build.fxOk;
    // An effect file that cannot be built refuses the layer of any kind, as an
    // image's own file is refused.
    if (!fxOk && doc_fx_files(doc_fx_steps(d, layer))) {
      d.error = why + ": the " + kind + " " +
                std::filesystem::path(file + shape).filename().string() +
                " could not be made";
      all = false;
      continue;
    }
    made.units = units;
    if (doc_among("video image text shape", kind))
      made.space = doc_word(d, layer, "space") == "2.5d" ? 25
                   : doc_word(d, layer, "space") == "3d" ? 3
                                                         : 2;
    // A behaviour and a camera draw nothing. A behaviour changes how the values
    // of other layers move. A camera is the viewpoint of the rest.
    if (kind == "behaviour")
      made.behaviour = true;
    else if (kind == "camera")
      made.camera = true;
    // A Filament light built as the document says. Its position and strength
    // are set at each time.
    else if (kind == "light") {
      const LightManager::Type type = file == "sun" ? LightManager::Type::SUN
                                      : file == "spot"
                                          ? LightManager::Type::FOCUSED_SPOT
                                          : LightManager::Type::POINT;
      if (!doc_among("sun point spot", file.c_str()))
        why = "a light is a sun, a point or a spot";
      else {
        made.light = utils::EntityManager::get().create();
        // Use a finer shadow map than the default so the edge is not stepped,
        // and a bulb as large as the softness says.
        LightManager::ShadowOptions shade;
        shade.mapSize = 2048;
        const float soft = (float)doc_number(d, layer, "shadow_softness", 0, 0);
        shade.screenSpaceContactShadows =
            doc_number(d, layer, "contact_shadows", 0, 0) > 0.5;
        if (soft > 0.f)
          shade.shadowBulbRadius =
              type == LightManager::Type::SUN ? 0.05f * soft : 0.5f * soft;
        LightManager::Builder(type)
            .color(filament::Color::toLinear<filament::ACCURATE>(
                filament::sRGBColor{fill.empty() ? float3{1.f} : colour}))
            .falloff((float)doc_number(d, layer, "falloff", 0, 10))
            .castShadows(doc_number(d, layer, "shadows", 0, 0) > 0.5)
            .shadowOptions(shade)
            .build(*s.engine, made.light);
        if (const int group = (int)doc_number(d, layer, "light_group", 0, 0);
            group > 0) {
          auto& lights = s.engine->getLightManager();
          lights.setLightChannel(lights.getInstance(made.light), 0, false),
              lights.setLightChannel(lights.getInstance(made.light),
                                     (unsigned)group, true);
        }
        // The light enters the scenes only when it is on.
        made.in = false;
      }
    } else if (shape.empty() && !std::filesystem::is_regular_file(file))
      why = "there is no such file";
    else if (kind == "video") {
      // The datamosh video, once rendered, plays in place of the video, from
      // its start.
      const std::string moshed = doc_mosh(d, layer);
      const double from = moshed.empty() ? doc_number(d, layer, "begin", 0, 0)
                                         : 0.0,
                   length = doc_number(d, layer, "duration", 0, -1),
                   speed = doc_number(d, layer, "speed", 0, 1);
      made.video =
          video(s, (moshed.empty() ? file : moshed).c_str(), mat4f{}, 1.f,
                (float)from,
                length < 0 ? -1.f : (float)(from + length * std::fabs(speed)),
                (float)speed, lay, fx.lit, fx.wear);
      if (!made.video) why = video_trouble;
      // When not set, keying is on if the video has a background of its own.
      else if (const double keyed = doc_number(d, layer, "keyed", 0, -1);
               keyed != 0.0)
        key_own(made.video, keyed > 0.5);
      // The document sets its time and starts its sound; the video does not
      // advance by itself.
      if (made.video) s.playing.erase(made.video);
      // The start of the sound is counted from where the exported video begins.
      // A sound already playing at that point is heard from that far into it.
      if (made.video && made.video->sound)
        s.sounding[made.video] = [&d, layer, v = made.video, file] {
          const double on = doc_number(d, layer, "start", 0, 0) -
                            d.video_export.written_from,
                       lasts = doc_number(d, layer, "duration", 0, -1),
                       late = std::max(0.0, -on);
          Stage::Sound a{file,
                         v->from,
                         v->to,
                         v->speed,
                         late,
                         std::max(0.0, on),
                         lasts < 0.0 ? lasts : std::max(1e-3, lasts - late),
                         doc_number(d, layer, "volume", 0, 1)};
          // With keyframes on volume, sample Alight Motion's Volume with its
          // keyframes and easing every 1/30 s, as the document reads it.
          if (doc_keys_of(d, layer, "volume").at.size() > 1)
            for (double t = 0.0, end = a.lasts >= 0.0
                                           ? a.lasts
                                           : doc_seconds(d) -
                                                 d.video_export.written_from -
                                                 a.on;
                 t <= end + 1e-9 && a.loud.size() < 30 * 3600; t += 1.0 / 30.0)
              a.loud.push_back(
                  (float)doc_number(d, layer, "volume",
                                    d.video_export.written_from + a.on + t, 1));
          return a;
        };
    } else if (kind == "image") {
      std::string shown = file;
      // A level: show the drawing that its keyframes name now, held until the
      // next, as a timesheet holds it.
      if (const DocKeys& cels = doc_keys_of(d, layer, "cel");
          !cels.at.empty()) {
        made.cel = doc_cel(d, layer, s.now), made.celMove = cels.at.size() > 1;
        shown = doc_cel_file(file, made.cel);
        // OpenToonz marks a missing drawing of a level in red and does not fill
        // it in.
        if (!shown.empty() && !std::filesystem::is_regular_file(shown))
          why = "no drawing " + std::to_string((long long)made.cel) +
                " beside " + std::filesystem::path(file).filename().string(),
          shown.clear();
      }
      // A MIDI file is drawn as a piano roll at the tempo its speed gives
      // (midi_roll.cpp).
      float rollHigh = 1.f;
      if (std::filesystem::path(file).extension() == ".mid") {
        const double speed = doc_number(d, layer, "speed", 0, 1);
        shown = midi_roll_file(
            file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why);
        // One point of the roll is one point of the document, as the 1920 x
        // 1080 screen of ALMaMPlayer shows it.
        double w = 0, h = 0;
        if (!shown.empty() && midi_roll_box(shown, w, h))
          rollHigh = (float)(h / doc_point(d, layer, 0));
      }
      const std::string ext = std::filesystem::path(file).extension().string();
      const double cl = doc_number(d, layer, "crop_left", 0, 0),
                   ct = doc_number(d, layer, "crop_top", 0, 0),
                   cr = doc_number(d, layer, "crop_right", 0, 0),
                   cb = doc_number(d, layer, "crop_bottom", 0, 0);
      const bool cropped = cl + ct + cr + cb > 0.0;
      const float aspect =
          doc_among(".jpg .jpeg .png .webp .bmp .JPG .JPEG .PNG", ext) &&
                  (edge.w > 0.f || doc_number(d, layer, "round", 0, 0) > 0.0 ||
                   cropped)
              ? canvas_aspect(s, file.c_str())
              : 0.f;
      // A p5.js sketch that paints in 2D. What it paints is drawn by ThorVG
      // (canvas_sketch.h).
      if (ext == ".js") {
        // The video layer below it, which is what createCapture and createVideo
        // in the sketch see.
        std::string under;
        for (int t : doc_laid(d)) {
          if (t == layer) break;
          if (doc_word(d, t, "kind") == "video") under = doc_word(d, t, "file");
        }
        // The instance already run to check the sketch. It is reused when no
        // video is under the sketch.
        std::shared_ptr<Script>& ready =
            doc_scripts_kept(d).sketches[file].ready;
        auto run =
            ready && under.empty()
                ? std::exchange(ready, nullptr)
                : std::make_shared<Script>(
                      file,
                      (doc_engine("third_party/js/p5") / "p5.min.js").string(),
                      under);
        if (!run->flat())
          why = run->ok() ? "not a 2D sketch: " + file : run->trouble();
        else if (fxOk &&
                 (made.drawn = sketch_canvas(
                      s, run,
                      (doc_engine("third_party/filament_src/assets/fonts") /
                       "Roboto-Medium.ttf")
                          .string(),
                      1.f, lay, fx)))
          s.playing.erase(made.drawn);
      } else if (fxOk && aspect > 0.f) {
        // A photo with an edge, rounded corners or a crop is drawn as a
        // rectangle as wide as the photo, with the photo file as its fill, as a
        // shape filled with media is. Alight Motion's media layers take a
        // border as its shapes do.
        Canvas2DFx own = fx;
        own.media = file;
        // Crop: the rectangle shows a path within the whole photo, measured in
        // photo heights from its middle, so that what remains stays where it
        // was.
        char cut[256];
        std::snprintf(cut, sizeof cut,
                      "M%.5f %.5f L%.5f %.5f L%.5f %.5f L%.5f %.5f Z",
                      aspect * (cl - 0.5), ct - 0.5,
                      aspect * (0.5 - std::min(cr, 0.95 - cl)), ct - 0.5,
                      aspect * (0.5 - std::min(cr, 0.95 - cl)),
                      0.5 - std::min(cb, 0.95 - ct), aspect * (cl - 0.5),
                      0.5 - std::min(cb, 0.95 - ct));
        made.drawn = flat(s, cropped ? cut : "rect", aspect, mat4f{}, 1.f,
                          float3{1.f}, lay, edge, own.over(1.f), 4, 0.5f,
                          (float)doc_number(d, layer, "round", 0, 0));
      } else if (fxOk && !shown.empty() &&
                 (made.drawn = image_canvas(
                      s, shown.c_str(), mat4f{}, rollHigh, float3{-1.f}, true,
                      lay, fx, doc_word(d, layer, "marker").c_str())))
        s.playing.erase(made.drawn);
      // Stand up its 3D layers where they are, as After Effects shows them.
      if (made.drawn && made.drawn->lottie &&
          !canvas_deep(s, made.drawn).empty()) {
        made.motion = std::make_shared<Motion>();
        if (motion_open(*made.motion, file.c_str()))
          for (uint32_t id : made.drawn->deep) {
            float4 box;
            if (Canvas2D* own = layer_canvas(s, file.c_str(), id,
                                             1.f / made.motion->h, &box))
              made.deep.push_back({id, own, box});
          }
      }
    } else if (kind == "text") {
      // Words in a font, set by `say N text ...`. Until then the text is the
      // name of the font. The words as typed, or as the text effects show them
      // now.
      const std::string words =
          doc_text_shown(d, layer, s.now, &made.wordsMove);
      made.words = words;
      if (!fill.empty() && fill != "behind" && rgb < 0)
        why =
            "a text's fill is six digits, as ff3366, or behind (what is behind "
            "it)";
      else if ((stroke.empty() || edgeRgb >= 0) && fxOk)
        made.drawn = type(
            s,
            words.empty() ? std::filesystem::path(file).stem().string().c_str()
                          : (fx.column ? doc_column(words) : words).c_str(),
            file.c_str(), mat4f{}, 1.f,
            fill.empty() ? float3{0x11 / 255.f} : colour, lay, edge,
            fx.column ? .5f : (float)doc_number(d, layer, "align", 0, 0), fx);
    } else if (kind == "shape") {
      // A flat shape in one colour, drawn as a ThorVG rectangle or circle.
      if (!fill.empty() && fill != "none" && fill != "behind" && rgb < 0)
        why =
            "a shape's fill is six digits, as ff3366, none, or behind (what is "
            "behind it)";
      else if ((!stroke.empty() && edgeRgb < 0) || !fxOk) {
      } else if (shape == "solid") {
        // A flat colour as large as the stage where layers start: as wide in
        // proportion to its height, and as high in stage units.
        const float high = (float)(2.0 * up.w / up.y);
        made.drawn =
            flat(s, "rect", (float)s.w / (float)s.h, mat4f{}, high,
                 fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour, lay,
                 float4{edge.xyz, edge.w / high}, fx.over(high));
      } else {
        // By default a line is long and thin: 25 times as long as it is thick.
        // Its height is 0.04 units. A wave is a wavy line, ten times as long as
        // it is high.
        const bool line = shape == "line", wave = shape == "wave";
        // No fill: only the edge is drawn, which gives a frame.
        fx.hollow = fill == "none";
        // Filled with an image file; see flat in canvas_renderables.h.
        fx.media = doc_word(d, layer, "fill_media");
        fx.evenOdd = doc_word(d, layer, "fill_rule") == "evenodd";
        const float high = line ? 0.04f : wave ? 0.3f : 1.f;
        // A plain shape with only an outline in one colour is cut into
        // triangles and drawn by Filament like the other layers of the scene
        // (flat_mesh). A shape with an edge, a ramp, a dash, effects, a trim or
        // a bend is rendered on the CPU as a ThorVG image. A path shape uses
        // its own path as its form. With no path yet it is an empty path.
        const std::string drawn = doc_word(d, layer, "path"),
                          form = shape != "path" ? shape
                                 : drawn.empty() ? "M0 0"
                                                 : drawn;
        const bool plain =
            !fx.thick && !wave && shape != "spiral" && shape != "null" &&
            fx.media.empty() && fx.ramp.size() < 2 && fx.blur <= 0.f &&
            fx.shadow.w <= 0.f && fx.tint <= 0.f && fx.tritone <= 0.f;
        if (plain)
          made.drawn = flat_mesh(
              s, form.c_str(),
              (float)doc_number(d, layer, "wide", 0, line ? 25 : 1), mat4f{},
              high, fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour,
              lay, float4{edge.xyz, edge.w / high}, fx.over(high),
              (int)doc_number(d, layer, "points", 0,
                              shape == "star"       ? 5
                              : shape == "arc"      ? 270
                              : shape == "squircle" ? 4
                              : shape == "cog"      ? 12
                              : shape == "spiral"   ? 3
                                                    : 6),
              (float)doc_number(d, layer, "inner", 0,
                                shape == "cog"       ? 0.2
                                : shape == "arc"     ? 0.3
                                : shape == "spiral"  ? 0.1
                                : shape == "chamfer" ? 0.3
                                                     : 0.5),
              (float)doc_number(d, layer, "round", 0, 0), doc_bends(d, layer));
        else
          made.drawn =
              flat(s, form.c_str(),
                   (float)doc_number(d, layer, "wide", 0,
                                     line   ? 25
                                     : wave ? 10
                                            : 1),
                   mat4f{}, high,
                   fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour,
                   lay, float4{edge.xyz, edge.w / high}, fx.over(high),
                   (int)doc_number(d, layer, "points", 0,
                                   shape == "star"       ? 5
                                   : shape == "arc"      ? 270
                                   : shape == "squircle" ? 4
                                   : shape == "cog"      ? 12
                                   : shape == "spiral"   ? 3
                                   : wave                ? 4
                                                         : 6),
                   (float)doc_number(d, layer, "inner", 0,
                                     shape == "cog"       ? 0.2
                                     : shape == "arc"     ? 0.3
                                     : shape == "spiral"  ? 0.1
                                     : shape == "chamfer" ? 0.3
                                                          : 0.5),
                   (float)doc_number(d, layer, "round", 0, 0));
      }
    } else if (kind == "solid") {
      // One of the built-in shapes, or a file. Its fill is its surface: a
      // colour, or the material glass. The material comes from the Material
      // group of the Create tab, or from a fill of glass as in older documents.
      const std::string material = doc_material(d, layer);
      const bool glass = material == "glass",
                 coloured = !fill.empty() && fill != "glass";
      // Sets the glass material parameters from the document, with defaults
      // when they are not set.
      const auto glassy = [&](MaterialInstance* look) {
        look->setParameter("ior", (float)doc_number(d, layer, "ior", 0, 1.5)),
            look->setParameter(
                "split", (float)doc_number(d, layer, "dispersion", 0, 0.1));
        look->setParameter("swim", (float)doc_number(d, layer, "swim", 0, 0.5)),
            look->setParameter("dark",
                               (float)doc_number(d, layer, "dark", 0, 4));
        look->setParameter("vivid",
                           (float)doc_number(d, layer, "vivid", 0, 1.3));
      };
      const Surface surface{
          (float)doc_number(d, layer, "metallic", 0, 0.08),
          (float)doc_number(d, layer, "roughness", 0, 0.6),
          (float)doc_number(d, layer, "reflectance", 0, 0.5),
          (float)doc_number(d, layer, "clear_coat", 0, 0),
          (float)doc_number(d, layer, "clear_coat_roughness", 0, 0),
          (float)doc_number(d, layer, "emissive", 0, 0),
          (float)doc_number(d, layer, "sheen", 0, 0),
          (float)doc_number(d, layer, "anisotropy", 0, 0),
          (float)doc_number(d, layer, "thickness", 0, 0.5)};
      const std::string shading = doc_word(d, layer, "shading");
      // With clip on, use the material variant that a matte can cut.
      const char* model = doc_number(d, layer, "clip", 0, 0) > 0.5 &&
                                  (shading.empty() || shading == "lit")
                              ? "floor_lit_matte.filamat"
                              : surface_model(shading);
      // True when the material is one of the built-in ones rather than
      // Filament's lit surface. It is applied by solid_wear.
      const bool own = doc_among("filament_glass lacquer bubble", material);
      const float3 tone = coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f;
      const auto with_material = [&](Mesh* m, int copies) {
        return solid_wear(
            s, m, std::vector<mat4f>((size_t)std::max(1, copies), mat4f{}),
            material,
            material == "filament_glass" && !coloured ? float3{1.f} : tone,
            (float)doc_number(d, layer, "ior", 0, 1.5),
            (float)doc_number(d, layer, "dispersion", 0, 0.1),
            (float)doc_number(d, layer, "swim", 0, 0.5),
            (float)doc_number(d, layer, "dark", 0, 4),
            (float)doc_number(d, layer, "vivid", 0, 1.3),
            (float)doc_number(d, layer, "metallic", 0, 0.08));
      };
      if (coloured && (rgb < 0 || ramp.size() > 1))
        why = "a solid's fill is six digits, as ff3366, or glass";
      else if (!shape.empty()) {
        made.sketch = shape == "sketch";
        made.shape = made.sketch       ? sketch_mesh()
                     : shape == "gem"  ? gem(0.5f)
                     : shape == "cube" ? cube(0.1f)
                     : shape == "ball" ? sphere(0.5f)
                                       : torus(0.37f, 0.13f);
        MaterialInstance* look =
            glass ? thick_glass(s, made.shape, {mat4f{}})
            : own && !made.sketch
                ? with_material(made.shape,
                                (int)doc_number(d, layer, "copies", 0, 1))
                : add(s, made.shape, made.sketch ? "sketch.filamat" : model,
                      std::vector<mat4f>(
                          (size_t)std::max(
                              1, (int)doc_number(d, layer, "copies", 0, 1)),
                          mat4f{}));
        made.look = look;
        if (look && glass) glassy(look);
        if (look && made.sketch)
          for (int i = 0; i < 6; ++i)
            look->setParameter(("picture" + std::to_string(i)).c_str(),
                               white_point(s), TextureSampler());
        if (!look)
          made.shape = nullptr;
        else if (!glass && !(own && !made.sketch))
          plain(look,
                coloured      ? colour
                : made.sketch ? float3{1.f}
                              : float3{0xd9, 0xd2, 0xc3} / 255.f,
                surface);
      } else if (std::filesystem::path(file).extension() == ".ply") {
        // A point cloud: its grains are drawn from one buffer (point_cloud.h).
        // A PlayCanvas splat effect on the cloud. The look is built with it.
        for (const std::string& w : doc_fx_list(d, layer))
          if (std::filesystem::path(w).extension() == ".mjs")
            made.splatFxFile = w;
        std::string effectWhy;
        Material* with =
            made.splatFxFile.empty()
                ? nullptr
                : points_effect(s, made.splatFxFile, made.splatFx, effectWhy);
        if (!effectWhy.empty()) std::fprintf(stderr, "%s\n", effectWhy.c_str());
        float3 box[2];
        made.shape = points(s, file.c_str(), why, &made.look, with,
                            &made.splatPlain, box);
        // The effect gets the bounding box of the cloud itself.
        if (made.splatFx)
          for (int c = 0; c < 3; ++c)
            made.splatFx->usual(std::string("aabbMin_") + "xyz"[c], box[0][c]),
                made.splatFx->usual(std::string("aabbMax_") + "xyz"[c],
                                    box[1][c]);
        made.grains = made.shape != nullptr;
      } else if (glass || own) {
        // A file's shape as glass, or with a built-in material: only its
        // triangles are used, because the glass draws a shape three times.
        MaterialInstance* look =
            (made.shape = solid_mesh(file.c_str()))
                ? glass
                      ? thick_glass(s, made.shape, {mat4f{}})
                      : with_material(made.shape,
                                      (int)doc_number(d, layer, "copies", 0, 1))
                : nullptr;
        made.look = look;
        if (!look)
          made.shape = nullptr;
        else if (glass)
          glassy(look);
      }
      // Keep the file's own look unless a fill colour, a shading or a material
      // is given.
      else if ((made.solid =
                    solid(s, file.c_str(), mat4f{}, 1.f,
                          (int)doc_number(d, layer, "copies", 0, 1))) &&
               (rgb >= 0 || !shading.empty()))
        solid_fill(s, made.solid,
                   coloured ? colour : float3{0xd9, 0xd2, 0xc3} / 255.f,
                   surface, model);
      // The document sets its time.
      if (made.solid) s.playing.erase(made.solid);
    } else
      why = std::string("its kind is one of: ") + doc_kinds;
    // A level at a cross, or at a drawing it lacks, shows nothing but is kept
    // so that its next drawing is seen.
    if (made.celMove && !made.drawn) {
      if (made.cel >= 0)
        d.error = why + ": the picture " +
                  std::filesystem::path(file).filename().string(),
        all = false;
    } else if (!made.video && !made.drawn && !made.solid && !made.shape &&
               !made.camera && made.light.isNull() && kind != "behaviour") {
      d.error = why + ": the " + kind + " " +
                std::filesystem::path(file + shape).filename().string() +
                " could not be made";
      all = false;
      continue;
    }
    d.on_stage.shown[layer] = made;
    // A solid layer casts shadows from lights that throw them, and receives
    // them. The grains of a point cloud are their own light.
    if ((made.solid || made.shape) && !made.grains) {
      const int group = (int)doc_number(d, layer, "light_group", 0, 0);
      doc_parts(
          s, d.on_stage.shown[layer],
          [group](RenderableManager& faces, RenderableManager::Instance one) {
            // Filament draws contact shadows only where the light asks for them
            // as well.
            faces.setCastShadows(one, true), faces.setReceiveShadows(one, true),
                faces.setScreenSpaceContactShadows(one, true);
            if (group > 0) faces.setLightChannel(one, (unsigned)group, true);
          });
    }
  }
  doc_evaluate(d, s.now);
  return rebuild.all;
}

}  // namespace motolii

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
#include "document/evaluate/evaluate.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/kinds.h"
#include "document/marks.h"
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

using namespace filament;
using namespace filament::math;

namespace motolii {

namespace {

// The property names that move the points of a flat shape as it is drawn (the
// vertex stage of flat.mat). A shape with any of them set is tessellated finely
// along its whole length. A shape with none is subdivided only around its
// curves, so a long line takes four points rather than two thousand.
const char* const doc_bending =
    "'warp','bend','twist','pinch','skew','squash','wiggle','stretch','pin_tl_"
    "x','pin_tl_y','pin_tr_x','pin_tr_y','pin_bl_x','pin_bl_y','pin_br_x','pin_"
    "br_y'";
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

// Returns true if the layer has any bending property set, either in its
// keyframes or in the values held by a drag in progress.
bool doc_bends(Doc& d, int layer) {
  bool any = false;
  // A property driven by a behaviour (name_by) bends the layer too.
  doc_rows(d,
           sqlite3_mprintf(
               "select 1 from keyframe where layer = %d and (name in (%s) or "
               "(name glob '*_by' and substr(name, 1, length(name) - 3) in "
               "(%s))) and (value <> 0 or at <> 0) limit 1",
               layer, doc_bending, doc_bending),
           [&](sqlite3_stmt*) { any = true; });
  if (d.held.layer == layer)
    for (const auto& [name, is] : d.held.tried)
      any =
          any || (is != 0.0 && strstr(doc_bending, ("'" + name + "'").c_str()));
  return any;
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
// Returns the path of the datamosh of a video layer (video_datamosh.h): the
// video rendered again with the motion of another video poured in. Returns ""
// when mosh is off, there is no other video, or the result is not rendered yet.
// The layer then plays its own video meanwhile.
std::string doc_mosh(Doc& d, int layer) {
  if (!doc_on(d, layer, "mosh") || doc_word(d, layer, "kind") != "video")
    return "";
  const int with = (int)doc_number(d, layer, "mosh_with", 0, 0);
  const std::string file = doc_word(d, layer, "file"),
                    other = with > 0 && with != layer
                                ? doc_word(d, with, "file")
                                : "";
  if (other.empty() || doc_word(d, with, "kind") != "video") return "";
  return mosh_file(file, doc_number(d, layer, "mosh_at", 0, 1), other);
}
// Returns true if the layer is lit by the scene's lights. It is lit like an
// After Effects 3D layer once the project has a light layer. With no light it
// is drawn as it is, unless it is metallic: a metal shows what it mirrors, and
// it mirrors the stage's environment, like the reflection map of Element 3D.
bool doc_lit(Doc& d, int layer) {
  const std::string space = doc_word(d, layer, "space");
  if (!doc_among("video text image shape",
                 doc_word(d, layer, "kind").c_str()) ||
      (space != "3d" && space != "2.5d" && !doc_on(d, layer, "scale_z")))
    return false;
  if (doc_on(d, layer, "metallic")) return true;
  for (const int t : doc_layers(d))
    if (doc_word(d, t, "kind") == "light") return true;
  return false;
}
// Returns true for metallic, roughness and reflectance on a layer that is not a
// solid. A solid is rebuilt when these change. A flat layer (a sheet) has them
// evaluated at each time (evaluate.h) and its image is left alone.
bool doc_sheet_told(Doc& d, int layer, const std::string& name) {
  return doc_among("metallic roughness reflectance", name.c_str()) &&
         doc_word(d, layer, "kind") != "solid";
}

}  // namespace

int doc_bevel(Doc& d, int layer) {
  const std::string way = doc_word(d, layer, "bevel");
  const char* const ways[] = {"angular", "convex", "concave", "ogee", "step"};
  for (int k = 0; k < 5; k++)
    if (way == ways[k] && doc_on(d, layer, "scale_z")) return k + 1;
  return 0;
}
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
  // For each layer, the text of every property its construction depends on.
  std::map<int, std::string> told;
  doc_rows(
      d,
      sqlite3_mprintf(
          "select layer, group_concat(name || '=' || value, ' ') from (select "
          "* from keyframe where layer > 0 and (name in (%s) or name glob "
          "'*_by') and not (name in ('metallic', 'roughness', 'reflectance') "
          "and layer in (select layer from keyframe where name = 'kind' and "
          "value != 'solid')) order by layer, name) group by layer",
          doc_making),
      [&](sqlite3_stmt* row) {
        told[sqlite3_column_int(row, 0)] =
            (const char*)sqlite3_column_text(row, 1);
      });
  // Every blend mode that reads the pixels underneath is drawn the same way, as
  // normal, and flat.mat mixes it. Switching between them changes only the look
  // and needs no rebuild, so replace the mode with * to make them compare
  // equal.
  for (auto& [layer, of] : told)
    if (const size_t at = of.find("blend="); at != std::string::npos) {
      const size_t end = of.find(' ', at);
      if (doc_blend_way(of.substr(at + 6, end == std::string::npos
                                              ? std::string::npos
                                              : end - at - 6)))
        of.replace(at + 6,
                   (end == std::string::npos ? of.size() : end) - at - 6, "*");
    }
  for (auto& [layer, of] : told) {
    if (of.find("kind=image") != std::string::npos)
      if (const std::string file = doc_word(d, layer, "file");
          std::filesystem::path(file).extension() == ".js")
        of += " written=" + std::to_string(doc_sketch_written(d, file));
    // A three.js part is rebuilt from its code when the file changes; see
    // doc_three_saved.
    if (of.find("kind=solid") != std::string::npos)
      if (const std::string file = doc_word(d, layer, "file");
          std::filesystem::path(file).extension() == ".glb") {
        std::error_code wrong;
        of += " written=" +
              std::to_string(
                  (long long)std::filesystem::last_write_time(file, wrong)
                      .time_since_epoch()
                      .count());
      }
  }
  // Whether the layer bends: tessellated finely, or subdivided only around its
  // curves.
  for (auto& [layer, of] : told)
    of += doc_bends(d, layer) ? " bent=1" : " bent=0";
  // Effects: record which are on and how much room they need, but not their
  // parameter values.
  for (auto& [layer, of] : told) {
    const auto on = [&](const char* name) {
      return std::max(doc_most(d, layer, name, 0),
                      doc_number(d, layer, name, 0, 0)) > 0.0;
    };
    // Rebuilt once its datamosh has been rendered.
    if (doc_on(d, layer, "mosh")) of += " moshed=" + doc_mosh(d, layer);
    // Rebuilt when it is given depth, because its sheet then becomes a box.
    if (doc_on(d, layer, "scale_z")) of += " deep";
    if (doc_bevel(d, layer)) of += " bevel";
    // Rebuilt when a light is added or removed.
    if (doc_lit(d, layer)) of += " lit";
    // The text as the text effects show it now. Rebuilt when it changes.
    if (of.find("kind=text") != std::string::npos)
      of += " shown=" + doc_text_shown(d, layer, s.now);
    // The drawing of a level shown now. Rebuilt when its keyframes change it.
    if (of.find("kind=image") != std::string::npos &&
        !doc_keys_of(d, layer, "cel").at.empty())
      of += " cel=" + std::to_string(std::llround(doc_cel(d, layer, s.now)));
    of += " order=" + doc_fx_join(doc_fx_list(d, layer)) +
          " fx=" + std::to_string((int)on("blur")) +
          (doc_word(d, layer, "shadow").empty() ? "0" : "1") +
          (doc_word(d, layer, "glow").empty() ? "0" : "1") +
          std::to_string((int)on("tint")) + std::to_string((int)on("tritone")) +
          " room=" + std::to_string(doc_fx_room(d, layer));
  }
  // Values held by a drag in progress also count, so the layer is rebuilt as it
  // will be after the drag.
  if (const auto held = told.find(d.held.layer); held != told.end())
    for (const auto& [name, is] : d.held.said)
      if (name[0] != ' ') held->second += " " + name + "~" + is;
  if (const auto held = told.find(d.held.layer); held != told.end())
    for (const auto& [name, is] : d.held.tried)
      // A property that moves is redrawn at every time by doc_evaluate anyway.
      // It triggers a rebuild only when it switches on or off.
      if (strstr(doc_making, ("'" + name + "'").c_str()) &&
          !doc_sheet_told(d, d.held.layer, name)) {
        bool moves = false;
        for (const DocValue& one : doc_values)
          moves = moves || (one.moves && name == one.name);
        const auto from = d.held.from.find(name);
        if (!moves)
          held->second += " " + name + "~" + std::to_string(is);
        else if (from != d.held.from.end() &&
                 (from->second != 0.0) != (is != 0.0))
          held->second += " " + name + "~" + (is != 0.0 ? "on" : "off");
      }
  for (auto it = d.shown.begin(); it != d.shown.end();) {
    const auto still = told.find(it->first);
    // A text whose words came out wider than its image is always rebuilt.
    if (still != told.end() && still->second == it->second.of &&
        !(it->second.drawn && it->second.drawn->outgrown)) {
      ++it;
      continue;
    }
    // Remove it from the scene of its run first, because the removal code below
    // takes layers only out of the stage's own scene.
    if (it->second.scene && it->second.scene != s.scene)
      doc_entities(s, it->second,
                   [&](utils::Entity e) { it->second.scene->remove(e); });
    // Give the copies back their own materials first, while the copies are
    // still known.
    if (const Mesh* m = it->second.video   ? it->second.video->sheet
                        : it->second.drawn ? it->second.drawn->sheet
                                           : it->second.shape)
      doc_copy_looks_off(d, m,
                         it->second.video   ? it->second.video->look
                         : it->second.drawn ? it->second.drawn->look
                                            : it->second.look);
    // Then remove the shape it uses to cut a matte.
    if (const Mesh* m = it->second.video   ? it->second.video->sheet
                        : it->second.drawn ? it->second.drawn->sheet
                                           : it->second.shape)
      doc_unshape(s,
                  [m](const Stage::Renderable& made) { return made.of == m; });
    if (it->second.video) video_off(s, it->second.video);
    if (it->second.drawn) canvas_off(s, it->second.drawn);
    for (const auto& deep : it->second.deep) canvas_off(s, deep.sheet);
    if (it->second.solid) solid_off(s, it->second.solid);
    // Remove the light from every scene and destroy it.
    if (!it->second.light.isNull()) {
      s.scene->remove(it->second.light);
      s.engine->getLightManager().destroy(it->second.light),
          utils::EntityManager::get().destroy(it->second.light);
    }
    // The sorting of a point cloud is dropped with it.
    if (it->second.shape)
      s.playing.erase(it->second.shape), take_off(s, it->second.shape);
    it = d.shown.erase(it);
  }
  bool all = true;
  for (const auto& [layer, of] : told) {
    if (d.shown.count(layer)) continue;
    Doc::Shown made{of};
    const std::string kind = doc_word(d, layer, "kind"),
                      file = doc_word(d, layer, "file"),
                      laid = doc_word(d, layer, "blend"),
                      shape = doc_word(d, layer, "shape");
    // A layer with effect files of its own is drawn alone as normal. Its blend
    // mode is applied once the effects are on (screen_fx.h).
    const bool effected = doc_fx_files(doc_fx_steps(d, layer));
    // lay is the blend mode for the GPU, or null when the layer is drawn as
    // normal. That is the case with effects, with no blend mode, or with a mode
    // that reads the pixels underneath, which flat.mat mixes itself.
    const char* lay =
        effected || laid.empty() || laid == "normal" || doc_blend_way(laid)
            ? nullptr
            : laid.c_str();
    std::string why = "it could not be read";
    const std::string fill = doc_word(d, layer, "fill");
    // A fill is one colour of six hex digits. For text or a flat shape it can
    // also be two or more colours that form a ramp. Each colour is six or eight
    // hex digits, and the last two are the alpha, so a colour can fade to
    // clear. Each colour may also carry a position, @ followed by a fraction of
    // the way, as in CSS colour stop positions: ff3366@0.35.
    std::vector<float4> ramp;
    std::vector<float> rampAt;
    long rgb = -1;
    {
      std::istringstream said(fill);
      for (std::string word; said >> word;) {
        const size_t mark = word.find('@');
        const std::string one = word.substr(0, mark);
        rampAt.push_back(
            mark == std::string::npos
                ? -1.f
                : std::clamp(std::strtof(word.c_str() + mark + 1, nullptr), 0.f,
                             1.f));
        const bool hex = (one.size() == 6 || one.size() == 8) &&
                         one.find_first_not_of("0123456789abcdefABCDEF") ==
                             std::string::npos;
        const long c =
            hex ? std::strtol(one.substr(0, 6).c_str(), nullptr, 16) : -1;
        if (c < 0) {
          ramp.clear(), rgb = -1;
          break;
        }
        if (ramp.empty()) rgb = c;
        const float there =
            one.size() == 8
                ? (float)std::strtol(one.substr(6).c_str(), nullptr, 16) / 255.f
                : 1.f;
        ramp.push_back(float4{(float)((c >> 16) & 255) / 255.f,
                              (float)((c >> 8) & 255) / 255.f,
                              (float)(c & 255) / 255.f, there});
      }
      // Eight digits (with alpha) are accepted only in a ramp of two colours or
      // more.
      if (ramp.size() == 1 && ramp[0].w < 1.f) ramp.clear(), rgb = -1;
    }
    const float3 colour =
        float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255),
               (float)(rgb & 255)} /
        255.f;
    // The edge is ThorVG's stroke. Its colour is written like a fill. Its width
    // is converted from points of the image to a fraction of the layer's own
    // height, at scale 1 where layers start.
    const std::string stroke = doc_word(d, layer, "stroke");
    const long edgeRgb =
        stroke.size() == 6 && stroke.find_first_not_of(
                                  "0123456789abcdefABCDEF") == std::string::npos
            ? std::strtol(stroke.c_str(), nullptr, 16)
            : -1;
    const math::double4 up = s.camera->getProjectionMatrix() *
                             s.camera->getViewMatrix() *
                             math::double4{0, 1, 0, 1};
    const float4 edge =
        edgeRgb < 0
            ? float4{0.f}
            : float4{float3{(float)((edgeRgb >> 16) & 255),
                            (float)((edgeRgb >> 8) & 255),
                            (float)(edgeRgb & 255)} /
                         255.f,
                     (float)(doc_number(d, layer, "stroke_width", 0, 0) /
                             (0.5 * s.h * up.y / up.w))};
    if (!stroke.empty() && edgeRgb < 0)
      why = "a stroke is six digits, as ff3366";
    // Image points per stage unit, where layers start.
    const double units = 0.5 * s.h * up.y / up.w;
    Canvas2DFx fx;
    fx.thick = doc_on(d, layer, "scale_z"), fx.lit = doc_lit(d, layer),
    fx.bevel = doc_bevel(d, layer) > 0;
    // The material the layer wears: its sheet uses the variant of flat.mat for
    // it, lit by Filament's lights. Glass reads what is behind it and is not
    // lit.
    fx.wear = doc_sheet_material(d, layer);
    if (!fx.wear.empty() && fx.wear != "glass") fx.lit = true;
    for (const std::string rim : {"stroke_2", "stroke_3"})
      if (const std::string word = doc_word(d, layer, rim.c_str());
          word.size() == 6) {
        const long hex = std::strtol(word.c_str(), nullptr, 16);
        const double wide =
            doc_number(d, layer, (rim + "_width").c_str(), 0, 0) / units;
        if (wide > 0.0)
          fx.rims.push_back(float4{(float)((hex >> 16) & 255) / 255.f,
                                   (float)((hex >> 8) & 255) / 255.f,
                                   (float)(hex & 255) / 255.f, (float)wide});
      }
    if (ramp.size() > 1) fx.ramp = ramp;
    // Positions were given. A stop without a position is spread evenly. A stop
    // positioned before the one ahead of it moves to that one's position, as in
    // the colour stop fix-up of CSS Images Level 3.
    if (ramp.size() > 1 && std::any_of(rampAt.begin(), rampAt.end(),
                                       [](float a) { return a >= 0.f; })) {
      for (size_t i = 0; i < rampAt.size(); ++i) {
        if (rampAt[i] < 0.f) rampAt[i] = (float)i / (float)(rampAt.size() - 1);
        if (i > 0) rampAt[i] = std::max(rampAt[i], rampAt[i - 1]);
      }
      fx.rampAt = rampAt;
    }
    fx.radial = doc_word(d, layer, "gradient") == "radial",
    fx.rampAngle = (float)doc_number(d, layer, "gradient_angle", 0, 0),
    fx.rampScale = (float)doc_number(d, layer, "gradient_scale", 0, 1);
    fx.spread = doc_word(d, layer, "gradient_spread") == "reflect"  ? 1
                : doc_word(d, layer, "gradient_spread") == "repeat" ? 2
                                                                    : 0;
    const std::vector<AbsentCopy>& repeated =
        doc_absent_copies(d, layer, d.stage->now);
    // The number of copies is the number that the repeat effect lays down, if
    // there is one.
    fx.copies = repeated.empty() ? (int)doc_number(d, layer, "copies", 0, 1)
                                 : (int)repeated.size();
    // Draw the copies in one pass when no copy is cleared on its own (no script
    // sets opacity) and their colours form a ramp that flat.mat supports. The
    // 3D layers inside an image do not qualify either.
    {
      const std::string fills = doc_word(d, layer, "copy_fill"),
                        script = doc_word(d, layer, "script");
      std::istringstream said(fills);
      int colours = 0;
      for (std::string one; said >> one && one != "none";) ++colours;
      const DocScript* sc = doc_script_of(d, script);
      // True when a behaviour gives each copy its own value. Each copy then has
      // its own look and cannot be drawn in one pass.
      bool connected = false;
      doc_rows(d,
               sqlite3_mprintf("select 1 from keyframe where layer = %d and "
                               "name glob '*_by' and value <> 0 limit 1",
                               layer),
               [&](sqlite3_stmt*) { connected = true; });
      // Copies that fade individually, such as those of the repeat effect or
      // the far ones of a scatter field, each need their own alpha.
      const bool faded =
          std::any_of(repeated.begin(), repeated.end(),
                      [](const AbsentCopy& c) { return c.alpha < 0.999; });
      // Expressions on the layer. Each may set opacity too.
      const std::vector<DocScript*> laying = doc_expressions_fx(d, layer);
      const bool clears =
          (sc && sc->clears) ||
          std::any_of(laying.begin(), laying.end(),
                      [](const DocScript* e) { return e->clears; });
      // At most eight colours, the size of the ramp in flat.mat.
      fx.together = fx.copies > 1 && (kind == "shape" || kind == "text") &&
                    colours <= 8 && !clears && !connected && !faded;
    }
    fx.wrapWidth = (float)doc_number(d, layer, "wrap_at", 0, 0);
    const std::string split = doc_word(d, layer, "split"),
                      script = doc_word(d, layer, "script");
    fx.splitWords = split == "words";
    // A text with a script or an expression moves letter by letter, as in
    // Cavalry, unless split is none.
    fx.split = split == "letters" || fx.splitWords ||
               (split.empty() && ((!script.empty() && script != "none") ||
                                  !doc_expressions_fx(d, layer).empty()));
    // Maps to ThorVG's TextWrap. A wrap width without a wrap mode wraps by
    // words. Vertical wrapping makes a box one letter wide.
    {
      const std::string w = doc_word(d, layer, "wrap");
      fx.wrap = w == "character" || w == "vertical" ? 1
                : w == "word"                       ? 2
                : w == "smart"                      ? 3
                : w == "ellipsis"                   ? 4
                : fx.wrapWidth > 0.f                ? 2
                                                    : 0;
      if (w == "vertical") fx.wrapWidth = 1.f, fx.column = true;
    }
    fx.letters = (float)doc_number(d, layer, "letter_spacing", 0, 1),
    fx.lines = (float)doc_number(d, layer, "line_spacing", 0, 1),
    fx.italic = (float)doc_number(d, layer, "italic", 0, 0);
    const auto which = [&](const char* name, const char* words) {
      const std::string w = doc_word(d, layer, name);
      if (w.empty()) return -1;
      int n = 0;
      for (const char* at = words; *at; ++n) {
        const size_t len = strcspn(at, " ");
        if (w == std::string(at, len)) return n;
        at += len + (at[len] ? 1 : 0);
      }
      return -1;
    };
    // Indices into ThorVG's StrokeCap and StrokeJoin, in its order.
    fx.cap = which("cap", "butt round square"),
    fx.join = which("join", "miter round bevel");
    fx.rampBlend = std::max(0, which("gradient_blend", "rgb oklab hue steps"));
    fx.heads = std::max(0, which("heads", "none end start both")),
    fx.headSize = (float)doc_number(d, layer, "head_size", 0, 4),
    fx.headShape = std::max(
        0,
        which("head_shape",
              "arrow circle box chevron bar t_line square square_filled "
              "diamond diamond_filled arrow_hollow arrow_filled circle_hollow "
              "circle_filled teardrop_hollow teardrop_filled")),
    fx.headStart =
        which("head_start",
              "arrow circle box chevron bar t_line square square_filled "
              "diamond diamond_filled arrow_hollow arrow_filled circle_hollow "
              "circle_filled teardrop_hollow teardrop_filled");
    fx.dash = (float)(doc_number(d, layer, "dash", 0, 0) / units),
    fx.dashFrom = (float)(doc_number(d, layer, "dash_offset", 0, 0) / units);
    // Build at the largest size the effects reach. Each time then evaluates
    // them as they are at that time.
    bool fxOk = doc_fx(d, layer, 0.0, true, units, fx, why);
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
            .color(Color::toLinear<ACCURATE>(
                sRGBColor{fill.empty() ? float3{1.f} : colour}))
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
          const double on =
                           doc_number(d, layer, "start", 0, 0) - d.written_from,
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
            for (double t = 0.0,
                        end = a.lasts >= 0.0
                                  ? a.lasts
                                  : doc_seconds(d) - d.written_from - a.on;
                 t <= end + 1e-9 && a.loud.size() < 30 * 3600; t += 1.0 / 30.0)
              a.loud.push_back((float)doc_number(d, layer, "volume",
                                                 d.written_from + a.on + t, 1));
          return a;
        };
    } else if (kind == "image") {
      std::string shown = file;
      // A level: show the drawing that its keyframes name now, held until the
      // next, as a timesheet holds it.
      if (const Doc::Keys& cels = doc_keys_of(d, layer, "cel");
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
    d.shown[layer] = made;
    // A solid layer casts shadows from lights that throw them, and receives
    // them. The grains of a point cloud are their own light.
    if ((made.solid || made.shape) && !made.grains) {
      const int group = (int)doc_number(d, layer, "light_group", 0, 0);
      doc_parts(
          s, d.shown[layer],
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
  return all;
}

}  // namespace motolii

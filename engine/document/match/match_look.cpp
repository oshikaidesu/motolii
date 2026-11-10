#include "document/match/match_look.h"

#include <filament/Camera.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include <algorithm>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <string>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "document/card_table.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/fx_list.h"
#include "document/evaluate/material.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/match/rebuild.h"
#include "document/scripts/expressions.h"
#include "document/scripts/scripts.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;
namespace math = filament::math;

namespace {

// Reads the layer's depth, light and material, and its extra outlines.
void look_material(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const double units = build.units;
  Canvas2DFx& fx = build.fx;
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
}

// Reads how the colours of the layer's ramp are laid out.
void look_ramp(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const std::vector<float4>& ramp = build.ramp;
  std::vector<float>& rampAt = build.rampAt;
  Canvas2DFx& fx = build.fx;
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
}

// Reads how many copies the layer has and whether they can be drawn in one
// pass.
void look_copies(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const std::string& kind = build.kind;
  Canvas2DFx& fx = build.fx;
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
}

// Reads how a text is set: how it is split, wrapped and spaced.
void look_text(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  Canvas2DFx& fx = build.fx;
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
}

// Returns which of the space-separated `words` the layer's property `name` is,
// counted from 0, or -1 when it is not set or is none of them.
int which(Doc& d, int layer, const char* name, const char* words) {
  const std::string w = doc_word(d, layer, name);
  if (w.empty()) return -1;
  int n = 0;
  for (const char* at = words; *at; ++n) {
    const size_t len = strcspn(at, " ");
    if (w == std::string(at, len)) return n;
    at += len + (at[len] ? 1 : 0);
  }
  return -1;
}

// Reads the ends and joins of the layer's edge, its heads and its dashes, and
// how the colours of its ramp are mixed.
void look_edge_ends(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const double units = build.units;
  Canvas2DFx& fx = build.fx;
  // Indices into ThorVG's StrokeCap and StrokeJoin, in its order.
  fx.cap = which(d, layer, "cap", "butt round square"),
  fx.join = which(d, layer, "join", "miter round bevel");
  fx.rampBlend =
      std::max(0, which(d, layer, "gradient_blend", "rgb oklab hue steps"));
  fx.heads = std::max(0, which(d, layer, "heads", "none end start both")),
  fx.headSize = (float)doc_number(d, layer, "head_size", 0, 4),
  fx.headShape = std::max(
      0, which(d, layer, "head_shape",
               "arrow circle box chevron bar t_line square square_filled "
               "diamond diamond_filled arrow_hollow arrow_filled circle_hollow "
               "circle_filled teardrop_hollow teardrop_filled")),
  fx.headStart =
      which(d, layer, "head_start",
            "arrow circle box chevron bar t_line square square_filled "
            "diamond diamond_filled arrow_hollow arrow_filled circle_hollow "
            "circle_filled teardrop_hollow teardrop_filled");
  fx.dash = (float)(doc_number(d, layer, "dash", 0, 0) / units),
  fx.dashFrom = (float)(doc_number(d, layer, "dash_offset", 0, 0) / units);
}

}  // namespace

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

int doc_bevel(Doc& d, int layer) {
  const std::string way = doc_word(d, layer, "bevel");
  const char* const ways[] = {"angular", "convex", "concave", "ogee", "step"};
  for (int k = 0; k < 5; k++)
    if (way == ways[k] && doc_on(d, layer, "scale_z")) return k + 1;
  return 0;
}

void match_fill(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  build.fill = doc_word(d, layer, "fill");
  const std::string& fill = build.fill;
  // A fill is one colour of six hex digits. For text or a flat shape it can
  // also be two or more colours that form a ramp. Each colour is six or eight
  // hex digits, and the last two are the alpha, so a colour can fade to
  // clear. Each colour may also carry a position, @ followed by a fraction of
  // the way, as in CSS colour stop positions: ff3366@0.35.
  std::vector<float4>& ramp = build.ramp;
  std::vector<float>& rampAt = build.rampAt;
  long& rgb = build.rgb;
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
      const bool hex =
          (one.size() == 6 || one.size() == 8) &&
          one.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos;
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
  build.colour = float3{(float)((rgb >> 16) & 255), (float)((rgb >> 8) & 255),
                        (float)(rgb & 255)} /
                 255.f;
}

void match_stroke(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  // The edge is ThorVG's stroke. Its colour is written like a fill. Its width
  // is converted from points of the image to a fraction of the layer's own
  // height, at scale 1 where layers start.
  build.stroke = doc_word(d, layer, "stroke");
  const std::string& stroke = build.stroke;
  build.edgeRgb = stroke.size() == 6 &&
                          stroke.find_first_not_of("0123456789abcdefABCDEF") ==
                              std::string::npos
                      ? std::strtol(stroke.c_str(), nullptr, 16)
                      : -1;
  const long edgeRgb = build.edgeRgb;
  build.up = s.camera->getProjectionMatrix() * s.camera->getViewMatrix() *
             math::double4{0, 1, 0, 1};
  const math::double4& up = build.up;
  build.edge = edgeRgb < 0
                   ? float4{0.f}
                   : float4{float3{(float)((edgeRgb >> 16) & 255),
                                   (float)((edgeRgb >> 8) & 255),
                                   (float)(edgeRgb & 255)} /
                                255.f,
                            (float)(doc_number(d, layer, "stroke_width", 0, 0) /
                                    (0.5 * s.h * up.y / up.w))};
  if (!stroke.empty() && edgeRgb < 0)
    build.why = "a stroke is six digits, as ff3366";
  // Image points per stage unit, where layers start.
  build.units = 0.5 * s.h * up.y / up.w;
}

void match_flat_look(LayerBuild& build) {
  look_material(build);
  look_ramp(build);
  look_copies(build);
  look_text(build);
  look_edge_ends(build);
  // Build at the largest size the effects reach. Each time then evaluates
  // them as they are at that time.
  build.fxOk =
      doc_fx(build.d, build.layer, 0.0, true, build.units, build.fx, build.why);
}

}  // namespace motolii

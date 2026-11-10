#include "document/match/match_shape.h"

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>

#include <cstring>
#include <string>

#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/match/rebuild.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_flat.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;
namespace math = filament::math;

namespace {

// The property names that move the points of a flat shape as it is drawn (the
// vertex stage of flat.mat). A shape with any of them set is tessellated finely
// along its whole length. A shape with none is subdivided only around its
// curves, so a long line takes four points rather than two thousand.
const char* const doc_bending =
    "'warp','bend','twist','pinch','skew','squash','wiggle','stretch','pin_tl_"
    "x','pin_tl_y','pin_tr_x','pin_tr_y','pin_bl_x','pin_bl_y','pin_br_x','pin_"
    "br_y'";

// A flat colour as large as the stage where layers start: as wide in
// proportion to its height, and as high in stage units.
void stage_sized_colour(LayerBuild& build) {
  Stage& s = build.s;
  DocShownLayer& made = build.made;
  const std::string& fill = build.fill;
  const float3 colour = build.colour;
  const char* lay = build.lay;
  const math::double4 up = build.up;
  const float4 edge = build.edge;
  const Canvas2DFx& fx = build.fx;
  const float high = (float)(2.0 * up.w / up.y);
  made.drawn = flat(s, "rect", (float)s.w / (float)s.h, mat4f{}, high,
                    fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour,
                    lay, float4{edge.xyz, edge.w / high}, fx.over(high));
}

// A plain shape, cut into triangles and drawn by Filament like the other
// layers of the scene (flat_mesh).
void mesh_shape(LayerBuild& build, const std::string& form, bool line,
                float high) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string &shape = build.shape, &fill = build.fill;
  const float3 colour = build.colour;
  const char* lay = build.lay;
  const float4 edge = build.edge;
  const Canvas2DFx& fx = build.fx;
  made.drawn = flat_mesh(
      s, form.c_str(), (float)doc_number(d, layer, "wide", 0, line ? 25 : 1),
      mat4f{}, high, fill.empty() ? float3{0xd9, 0xd2, 0xc3} / 255.f : colour,
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
}

// A shape rendered on the CPU as a ThorVG image.
void canvas_shape(LayerBuild& build, const std::string& form, bool line,
                  bool wave, float high) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string &shape = build.shape, &fill = build.fill;
  const float3 colour = build.colour;
  const char* lay = build.lay;
  const float4 edge = build.edge;
  const Canvas2DFx& fx = build.fx;
  made.drawn = flat(s, form.c_str(),
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

// A built-in shape or a path, with its fill, as a mesh when it is plain and
// as a ThorVG image when it is not.
void drawn_shape(LayerBuild& build) {
  Doc& d = build.d;
  const int layer = build.layer;
  const std::string &shape = build.shape, &fill = build.fill;
  Canvas2DFx& fx = build.fx;
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
  const bool plain = !fx.thick && !wave && shape != "spiral" &&
                     shape != "null" && fx.media.empty() &&
                     fx.ramp.size() < 2;
  if (plain)
    mesh_shape(build, form, line, high);
  else
    canvas_shape(build, form, line, wave, high);
}

}  // namespace

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

void match_shape(LayerBuild& build) {
  const std::string &shape = build.shape, &fill = build.fill,
                    &stroke = build.stroke;
  const long rgb = build.rgb, edgeRgb = build.edgeRgb;
  const bool fxOk = build.fxOk;
  std::string& why = build.why;
  // A flat shape in one colour, drawn as a ThorVG rectangle or circle.
  if (!fill.empty() && fill != "none" && fill != "behind" && rgb < 0)
    why =
        "a shape's fill is six digits, as ff3366, none, or behind (what is "
        "behind it)";
  else if ((!stroke.empty() && edgeRgb < 0) || !fxOk) {
  } else if (shape == "solid")
    stage_sized_colour(build);
  else
    drawn_shape(build);
}

}  // namespace motolii

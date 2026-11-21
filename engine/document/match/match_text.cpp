#include "document/match/match_text.h"

#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include <cstddef>
#include <cstring>
#include <filesystem>
#include <string>

#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/match/rebuild.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

void match_text(LayerBuild& build) {
  Doc& d = build.d;
  Stage& s = build.s;
  const int layer = build.layer;
  DocShownLayer& made = build.made;
  const std::string &file = build.file, &fill = build.fill,
                    &stroke = build.stroke;
  const long rgb = build.rgb, edgeRgb = build.edgeRgb;
  const bool fxOk = build.fxOk;
  const float3 colour = build.colour;
  const char* lay = build.lay;
  const float4 edge = build.edge;
  Canvas2DFx& fx = build.fx;
  std::string& why = build.why;
  // No fill: only the stroke is drawn, as for a shape.
  fx.hollow = fill == "none";
  // Words in a font, set by `say N text ...`. Until then the text is the
  // name of the font. The words as typed, or as the text effects show them
  // now.
  const std::string words = doc_text_shown(d, layer, s.now, &made.wordsMove);
  made.words = words;
  if (!fill.empty() && fill != "behind" && !fx.hollow && rgb < 0)
    why =
        "a text's fill is six digits, as ff3366, none, or behind (what is "
        "behind it)";
  else if ((stroke.empty() || edgeRgb >= 0) && fxOk)
    made.drawn =
        type(s,
             words.empty()
                 ? std::filesystem::path(file).stem().generic_string().c_str()
                 : words.c_str(),
             file.c_str(), build.word("text_styles").c_str(), mat4f{}, 1.f,
             fill.empty() ? float3{0x11 / 255.f} : colour, lay, edge,
             (float)build.number("align", 0), fx);
}

}  // namespace motolii

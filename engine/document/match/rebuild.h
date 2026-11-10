#ifndef MOTOLII_DOCUMENT_MATCH_REBUILD_H_
#define MOTOLII_DOCUMENT_MATCH_REBUILD_H_

// Rebuild: what one call of doc_match works out early and its later steps
// read. It lives for that call only. The steps are listed, in order, in
// doc_match (match.cpp).

#include <math/vec3.h>
#include <math/vec4.h>

#include <map>
#include <string>
#include <vector>

#include "document/evaluate/evaluate.h"
#include "stage/canvas/canvas_cache.h"

namespace motolii {

struct Doc;
struct Stage;

// One rebuild of the stage from the project.
struct Rebuild {
  Doc& d;
  // The stage of `d`.
  Stage& s;
  // For each layer of the project, the text of every property its construction
  // depends on. A layer whose text is the one it was made of stays on the
  // stage as it is.
  std::map<int, std::string> told;
  // False once a layer could not be built. d.error then holds the reason.
  bool all = true;
};

// One layer while it is being built: what the project says about it, read once
// and shared by the code that builds each kind of layer. It is filled in place
// and never copied, because `lay` points into `laid`.
struct LayerBuild {
  Doc& d;
  // The stage of `d`.
  Stage& s;
  const int layer;
  // What the layer becomes on the stage.
  DocShownLayer made;
  // The layer's kind, its file, its blend mode and its built-in shape.
  std::string kind, file, laid, shape;
  // The blend mode for the GPU, or null when the layer is drawn as normal.
  const char* lay = nullptr;
  // Why the layer could not be made, for d.error.
  std::string why = "it could not be read";
  // The fill as written, and as read: the colours of a ramp with their
  // positions (-1 where none is given), the first colour as 0xRRGGBB or -1 when
  // the fill is not a colour, and that colour as red, green and blue from 0 to
  // 1.
  std::string fill;
  std::vector<filament::math::float4> ramp;
  std::vector<float> rampAt;
  long rgb = -1;
  filament::math::float3 colour;
  // The edge as written, and its colour as 0xRRGGBB or -1.
  std::string stroke;
  long edgeRgb = -1;
  // The point one unit above the middle of the stage, as the camera projects
  // it.
  filament::math::double4 up;
  // The edge: its colour, and its width as a fraction of the layer's height.
  filament::math::float4 edge;
  // Image points per stage unit, where layers start.
  double units = 0.0;
  // The effects and drawing options of a flat layer, and whether its effects
  // could be read.
  Canvas2DFx fx;
  bool fxOk = false;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_REBUILD_H_

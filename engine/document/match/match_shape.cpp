#include "document/match/match_shape.h"

#include <sqlite3.h>

#include <cstring>
#include <string>

#include "document/document.h"
#include "document/evaluate/value_at.h"

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

}  // namespace motolii

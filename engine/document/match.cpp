#include "document/match.h"

#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/match/match_describe.h"
#include "document/match/match_layers.h"
#include "document/match/rebuild.h"
#include "stage/render/render_stage.h"

namespace motolii {

bool doc_match(Doc& d) {
  Stage& s = *d.stage;
  // The frame rate of the document. Time is shown in whole frames from the next
  // frame on.
  s.frames = doc_number(d, 0, "frame_rate", 0, 0);
  Rebuild rebuild{d, s};
  match_describe_layers(rebuild);
  match_tear_down_changed(rebuild);
  match_build_layers(rebuild);
  doc_evaluate(d, s.now);
  return rebuild.all;
}

}  // namespace motolii

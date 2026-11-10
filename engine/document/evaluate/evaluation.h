#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATION_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATION_H_

// Evaluation: what one call of doc_evaluate works out early and its later
// phases read. It lives for that call only. The phases are listed, in order, in
// doc_evaluate (evaluate.cpp).

#include <vector>

namespace motolii {

struct Doc;
struct DocShownLayer;
struct Stage;

// The state of one layer at the evaluated time. `on` says whether the layer is
// shown now. `solid` says whether the layer takes part in depth sorting with
// other solid layers. `since` is the time in seconds since the layer started.
// `open` says whether its 3D box is open.
struct EvaluatedLayer {
  int layer;
  DocShownLayer* shown;
  bool on, solid;
  double since;
  bool open;
};

// One evaluation of the document at one time.
struct Evaluation {
  Doc& d;
  // The stage of `d`.
  Stage& s;
  // The time the document is evaluated at, in seconds.
  const double now;
  // Every layer of the document in stacking order, cameras included.
  std::vector<int> lie;
  // The state of each layer that is on the stage and is not a camera, in
  // stacking order.
  std::vector<EvaluatedLayer> lies;
  // Depth ordering. Layers that follow one another and are of one sort, flat or
  // solid, form a run. `runOf` gives for each entry of `lies` the index of its
  // run, or -1 when nothing of the layer is drawn. `sorts` gives for each run 1
  // when its layers are solid and 0 when they are flat.
  std::vector<int> runOf, sorts;
  // 1 when flat layers lie under the first solid layers.
  int base = 0;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATION_H_

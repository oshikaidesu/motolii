#ifndef MOTOLII_DOCUMENT_EVALUATE_KEPT_FRAMES_H_
#define MOTOLII_DOCUMENT_EVALUATE_KEPT_FRAMES_H_
// Frames that are worked out one after the other and kept: each frame is made
// from the one before, 60 a second from the start of the project, so going
// back costs nothing and a change makes only the frames after it again. The
// world of the relations that push (world.h) and the rigid bodies
// (bodies.h) keep theirs this way.

#include <sqlite3.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <functional>
#include <string>
#include <utility>
#include <vector>

#include "document/document.h"
#include "document/scripts/scripts.h"

namespace motolii {

// Returns true if a cached solve has used up its 5 ms time slice for this
// image, so it should yield, as React's Scheduler does. The app then shows the
// frames it already has until the rest are computed. Video export, still-image
// export, cached images and Bake never yield and wait for the whole solve (see
// DocExact).
inline bool doc_spent(const Doc& d) {
  return d.solver.live && !d.solver.exact && !d.video_export.writing &&
         std::chrono::steady_clock::now() - d.solver.slice >
             std::chrono::milliseconds(5);
}
// While alive, copies the layers that a cached solve read into
// d.solver.reading, so that the caller's own dependency tracking sees them even
// when the cached result is returned.
struct DocKeptTells {
  Doc& d;
  DocSolver::RelatedKept& k;
  ~DocKeptTells() {
    if (d.solver.reading)
      d.solver.reading->insert(k.reads.begin(), k.reads.end());
  }
};
// Returns true if the cache `k` is still valid for time `t`. An undo step that
// changes nothing the solve read leaves the cache alone. What the solve read is
// found by watching it run, like the dynamic dependencies of a build system,
// and changes are detected with SQLite's changeset (see doc_note). Any other
// change invalidates the cache only from the first frame whose input differs,
// as GGPO's rollback returns to the first differing input and runs forward from
// there.
inline bool doc_kept_stands(Doc& d, DocSolver::RelatedKept& k, double t) {
  const long changes = d.file ? (long)sqlite3_total_changes(d.file) : 0;
  const bool same = k.changes == changes && k.made == doc_scripts_made(d) &&
                    k.seen == d.changes.touched.size();
  if (k.at == t && same && d.held.layer < 0 && (!k.behind || doc_spent(d))) {
    d.solver.behind = d.solver.behind || k.behind;
    return true;
  }
  if (k.made != doc_scripts_made(d))
    k.frames.clear(), k.told.clear(), k.sure = k.fresh = 0;
  if (!same) k.solves = -1;
  for (; k.seen < d.changes.touched.size(); ++k.seen)
    if (d.changes.touched[k.seen] < 0 ||
        k.reads.count(d.changes.touched[k.seen]))
      k.sure = 0;
  k.at = t, k.changes = changes, k.made = doc_scripts_made(d), k.behind = false;
  return false;
}
// Solves frames one at a time from the start of the stage at 60 frames per
// second, the rate of p5_stand.h, and caches each so that going back costs
// nothing. tell(f) returns the input for frame f. make(input, f) computes the
// frame and is called only when the input differs from the cached one. Returns
// false if no frame can be shown.
template <class Tell, class Make>
bool doc_kept_walk(Doc& d, DocSolver::RelatedKept& k, double t, Tell tell,
                   Make make) {
  const size_t frame = (size_t)std::max(0.0, std::round(t * 60.0));
  while (k.sure <= frame) {
    if (doc_spent(d)) {
      k.behind = d.solver.behind = true;
      break;
    }
    const std::string js = tell(k.sure);
    const size_t heard = std::hash<std::string>{}(js);
    if (k.sure < k.fresh && k.told[k.sure] == heard) {
      ++k.sure;
      continue;
    }
    std::vector<double> next = make(js, k.sure);
    if (next.empty()) return false;
    k.frames.resize(std::max(k.frames.size(), k.sure + 1)),
        k.told.resize(k.frames.size());
    k.frames[k.sure] = std::move(next), k.told[k.sure] = heard;
    k.fresh = ++k.sure;
  }
  return !k.frames.empty();
}

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_KEPT_FRAMES_H_

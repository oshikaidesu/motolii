#ifndef MOTOLII_DOCUMENT_MATCH_REBUILD_H_
#define MOTOLII_DOCUMENT_MATCH_REBUILD_H_

// Rebuild: what one call of doc_match works out early and its later steps
// read. It lives for that call only. The steps are listed, in order, in
// doc_match (match.cpp).

#include <map>
#include <string>

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

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_REBUILD_H_

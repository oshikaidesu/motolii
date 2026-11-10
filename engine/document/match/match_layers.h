#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_LAYERS_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_LAYERS_H_

// The steps of doc_match that take layers off the stage and put layers on it.

namespace motolii {

struct Rebuild;

// Takes off the stage every layer that is gone from the project or whose text
// in `told` is no longer the one it was made of, with everything that was made
// for it.
void match_tear_down_changed(Rebuild& rebuild);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_LAYERS_H_

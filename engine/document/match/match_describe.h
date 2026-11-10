#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_DESCRIBE_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_DESCRIBE_H_

// The first step of doc_match: for each layer of the project, a text of
// everything that affects how the layer is built. A layer is built again only
// when its text changes.

namespace motolii {

struct Rebuild;

// Fills `told` of the rebuild with the text of each layer: the properties its
// construction depends on, when its file was last written,
// which of its effects are on and how much room they need, and the values held
// by a drag in progress.
void match_describe_layers(Rebuild& rebuild);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_DESCRIBE_H_

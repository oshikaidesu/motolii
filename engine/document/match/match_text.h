#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_TEXT_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_TEXT_H_

// How doc_match builds a text layer.

namespace motolii {

struct LayerBuild;

// Builds a text layer: its words in its font, as typed or as the text effects
// show them now, in its fill and edge. A text without words shows the name of
// its font.
void match_text(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_TEXT_H_

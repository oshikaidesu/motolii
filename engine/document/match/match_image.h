#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_IMAGE_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_IMAGE_H_

// How doc_match builds an image layer: a picture, a drawing of a level, a
// MIDI file as a piano roll, a p5.js sketch that paints in 2D, or an After
// Effects image with its 3D layers.

namespace motolii {

struct LayerBuild;

// Builds an image layer from its file, as the kind of file says.
void match_image(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_IMAGE_H_

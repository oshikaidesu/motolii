#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_LIGHT_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_LIGHT_H_

// How doc_match builds a light layer.

namespace motolii {

struct LayerBuild;

// Builds a Filament light as the project says: a sun, a point or a spot, with
// its colour, falloff and shadows. Its position and strength are set at each
// time, and it enters the scenes only when it is on.
void match_light(LayerBuild& build);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_LIGHT_H_

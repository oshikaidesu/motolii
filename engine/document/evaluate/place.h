#ifndef MOTOLII_DOCUMENT_EVALUATE_PLACE_H_
#define MOTOLII_DOCUMENT_EVALUATE_PLACE_H_
// place.h: computes where each layer, and each copy of a layer, is placed on
// the stage, and the lines that join copies.

#include <math/mat4.h>

#include <functional>
#include <string>
#include <vector>

#include "document/kinds.h"
#include "stage/render/render_stage.h"

// Returns the matrix that places `layer` on the stage at time `now`. `deeper`
// is nonzero when the result is wanted before the layer's space (2D, 2.5D or
// 3D) is applied. With `member`, the matrix is for copy number `copy` of the
// layer's copies, shown with that copy's delay. The layer is moved, rotated
// about z, y and x, and scaled, all about its anchor. The anchor is a point of
// the layer's own box: 0 is its middle and 1 is its edge on that side. It is
// keyed as the older `anchor` property was.
filament::math::mat4 doc_place(Doc& d, int layer, double now, int deeper = 0,
                               int copy = 0, bool member = false);
// Returns one matrix per line that joins copies of the layer named by "connect"
// to copies of the layer named by "connect_to", or to other copies of the same
// layer. Each line is stretched along the direction between the two copies and
// gets thinner the farther apart they are. Copies left over are not shown. The
// lines are the layer's own copies, placed like those of any layer and drawn
// with its own fill.
std::vector<filament::math::mat4> doc_joins(Doc& d, int layer, double now);
// Removes the matte shapes selected by `which` from every matte scene and
// destroys them together with their material instances. A material instance
// holds the texture it reads, and Filament will not release that texture while
// the instance exists.
void doc_unshape(Stage& s,
                 const std::function<bool(const Stage::Renderable&)>& which);
// Returns the values of an ISF audio input at the current time (see the sounds
// in screen_fx.h). The sound comes from the layer whose number the effect
// parameter `name` holds, set on the effect's card in the same way as an image
// input. It is read at that layer's own time in its video, counted from the
// layer's start, offset by where the clip begins and scaled by its speed, the
// same as motolii_loudness_over. The audio is decoded once, separately
// (sound_level.h). `fft` selects the spectrum instead of the waveform, and
// `wide` is the number of values wanted. Returns an empty vector, meaning
// silence, when no layer is named or its audio is not yet read.
std::vector<float> doc_sound_now(Doc& d, int layer, const std::string& file,
                                 const std::string& name, bool fft, int wide);
#endif  // MOTOLII_DOCUMENT_EVALUATE_PLACE_H_

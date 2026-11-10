#ifndef MOTOLII_DOCUMENT_EVALUATE_SKETCH_H_
#define MOTOLII_DOCUMENT_EVALUATE_SKETCH_H_

// Draws a p5.js sketch that runs in WEBGL mode. Each frame the script reports
// the shapes, vertices and camera view that the sketch has drawn (__mesh_at in
// p5_mesh.h). This file rebuilds them as one mesh in the scene, the same way a
// sheet's mesh is rebuilt (reshape in render_stage.h).
//
// Each shape is fetched from the script once and laid out here, because a
// script is too slow to repeat a thousand spheres every frame. A sketch can
// therefore draw any number of copies, and every shape matches what p5 itself
// would draw. A line is drawn as a thin band that faces the camera, as p5's
// line shader does. What the sketch draws stays on screen from frame to frame
// until the sketch clears it.

namespace motolii {

struct Doc;
struct DocShownLayer;

// Rebuilds the mesh of layer `layer` from its p5 sketch at time `now`. `t`
// holds the layer's mesh, its material and the sketch state cached between
// frames. Does nothing if the layer has no running script. The mesh is only
// rebuilt when the sketch frame, the scripts, the camera position or a line
// strength has changed since the last call.
void doc_sketch_mesh(Doc& d, int layer, DocShownLayer& t, double now);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_SKETCH_H_

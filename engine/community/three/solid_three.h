#ifndef MOTOLII_COMMUNITY_THREE_SOLID_THREE_H_
#define MOTOLII_COMMUNITY_THREE_SOLID_THREE_H_

// Declares the interface for building a layer's 3D shape with three.js. The
// shape comes from a script in solids/*.js and is run by solid_three.cpp. The
// layer's image is then mapped onto the faces of the resulting mesh (see
// layer_fx.h).
#include <cstdint>
#include <map>
#include <string>
#include <vector>
// Returns true if the file is a shape script: a .js file containing
// `export function solid`.
bool solid_is(const std::string& file);
// Returns true if the shape is built from the layer's own outline (it reads
// `k.alpha`, as Raster Extrude does). The caller must then read the layer's
// image back and pass its coverage to solid_three().
bool solid_reads(const std::string& file);
// A triangle mesh produced by a shape script.
//   pos, nrm: vertex positions and normals, three floats per vertex.
//   uv: texture coordinates, two floats per vertex, with three.js's v pointing
//   up. idx: triangle vertex indices, three per triangle. repeat: true if the
//   image tiles across the mesh (geometry.userData.repeat).
struct SolidMesh {
  std::vector<float> pos, nrm, uv;
  std::vector<uint32_t> idx;
  bool repeat = false;
};
// Runs the shape script `file` and stores the mesh it builds in `out`.
// `numbers` and `words` are the script's current parameter values. `wide` and
// `high` are the layer's width and height in layer units. `cover` is the
// layer's image coverage (0-255 per pixel, coverW by coverH, rows from the
// top); it is only used by scripts for which solid_reads() is true. Returns
// true on success. On failure returns false and sets `why` to the error.
bool solid_three(const std::string& file,
                 const std::map<std::string, double>& numbers,
                 const std::map<std::string, std::string>& words, double wide,
                 double high, const std::vector<uint8_t>& cover, int coverW,
                 int coverH, SolidMesh& out, std::string& why);

#endif  // MOTOLII_COMMUNITY_THREE_SOLID_THREE_H_

#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_LOAD_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_LOAD_H_
// obj.load for AviUtl2 scripts.
//
// Implements obj.load as described in AviUtl2's lua.txt for a figure, an image file (also used by
// obj.copybuffer's "image:"), text, and the frame. The argument forms follow the AviUtl2 script
// skill's references/api.md (gasdyueer, MIT): "figure", name[, color, size, line, round] and
// "image", file, true or false.
//
// Pixels are drawn on ThorVG's CPU canvas (tvg::SwCanvas, from the ThorVG bundled with Motolii) and
// stored in the object as premultiplied pixels, unchanged. Results are cached by the request, so
// the same request is not drawn twice.
//
// Figures follow sashimono-edit (MIT; engine/sources.py _shape_path, _polygon_path, _star_path;
// objapi.py FIGURE_NAMES, MAX_FIGURE_SIZE 4096, FILLED_LINE 4000):
//   - A figure is a square image `size` wide. The background figure instead covers the screen.
//   - Polygons and the star have one corner pointing up and fit inside a circle of that size, which
//     is sashimono's measurement of AviUtl2: a triangle of size 400 spans x +-173, y -200..+99.
//   - A line is drawn inward, so the outer edge is the figure's own edge (_inside_outline: the
//     stroke cut by the figure).
//   - A line as thick as the figure, or 4000, gives a filled figure.
#include <string>

#include <lua.hpp>

#include "community/aviutl/aviutl_fx.h"

// Loads an image file with ThorVG and returns it as a cached image. A relative name refers to a
// file beside the script. Returns nullptr when the name is empty, the file does not exist or
// ThorVG cannot read it; the script then receives false, as lua.txt specifies. The cache key
// includes the file's modification time, so a changed file is read again.
const AviutlBuf* aviutl_image(AviutlRun& r, std::string file);
// Implements obj.load(kind, ...) for the kinds "tempbuffer", "figure", "image", "framebuffer",
// "text.layout" and "text". Pushes true if the object was loaded and false if nothing could be
// loaded. A form that is not implemented raises "not yet: ..." through aviutl_no.
int aviutl_load(lua_State* L);

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_LOAD_H_

#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_DRAW_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_DRAW_H_
// aviutl_obj_draw.h: obj.draw and obj.drawpoly of the AviUtl adapter. They place an image in depth
// on the interop's mesh, using the blend and sampler that were set.
#include <lua.hpp>

#include "community/aviutl/aviutl_fx.h"

// Draws an image placed in depth, as obj.draw and the frame's own placement do with z, rx or ry.
// The four corners are rotated about the centre (cx, cy) by X, then Y, then Z, in degrees, then
// moved by (x, y, z) and seen by the camera. The rotation follows sashimono-edit's
// engine/gpu/compositor.py Transform.corners and projection.py rotate: positive X tips the top
// away, positive Y tips the right side away, and positive Z turns clockwise.
void aviutl_placed(AviutlRun& r, const AviutlBuf& from, const AviutlBuf& to, double x, double y, double z, double sx, double sy, double rx, double ry, double rz, double cx, double cy, double fade, int way, int sampler);
// obj.draw(ox, oy, oz, zoom, alpha, rx, ry, rz) draws the object into the current draw target. The
// object's own oz, rx and ry are added to the arguments. If any of the sums is not 0 the object is
// drawn in depth (aviutl_placed); otherwise it is drawn flat.
int aviutl_draw(lua_State* L);
// obj.drawpoly, as lua.txt describes it (references/api.md of the AviUtl2 script skill). The
// corners are placed from the object's position into the frame, including oz, as they are into the
// temporary buffer, in depth (aviutl_mesh). The frame's alpha also applies to the object
// (sashimono-edit's lua_drawpoly).
//
// The corners are either 12 numbers (x, y, z for each of four corners) followed by 8 numbers of u,
// v in pixels, or a table. Without u, v, the four corners of the image are used. The alpha is the
// 13th or the 21st argument.
//
// A table holds faces in one of three forms. Items of 20 numbers are faces ({x0 .. z3, u0 .. v3},
// with an optional alpha as the second argument). Items of 5 numbers {x, y, z, u, v} with u, v from
// 0 to 1, or of 7 numbers {x, y, z, r, g, b, a} coloured, are corners that make faces of 4 or 3
// corners (optional arguments: count, alpha), as sashimono-edit's _drawpoly_table does. Items of 28
// numbers are coloured faces ({x0 .. z3, r0, g0, b0, a0 .. a3}), as used by 連結ライン.obj2.
int aviutl_drawpoly(lua_State* L);

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_DRAW_H_

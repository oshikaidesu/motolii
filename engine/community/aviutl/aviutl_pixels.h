#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_PIXELS_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_PIXELS_H_
// aviutl_pixels.h: obj.getpixeldata, obj.putpixeldata, obj.pixeloption and
// obj.getpixel of the AviUtl adapter.
//
// obj.getpixeldata and obj.putpixeldata follow lua.txt (references/api.md of
// the AviUtl2 script skill by gasdyueer, MIT). The buffer is "object",
// "tempbuffer" or "cache:...". The order is "rgba" or "bgra", with 8 bits per
// channel. The call returns a pointer, w and h. The pixels are kept as
// sashimono-edit keeps them (MIT; objapi.py lua_getpixeldata and _pixel_source,
// native.py PixelData): straight colour, rows from the top. A buffer that does
// not exist gives nil, 0, 0. The frame cannot be read. The values are the
// buffer's own, as its shaders read them.
//
// Each call hands out a new userdata that Lua may keep (aviutl2_modern_docs,
// docs/lua: the image data pointer is a userdata). Scripts rely on this. The
// 遅延 parameter of どこでもバッファ by zopty keeps a ring of them and puts
// them back frames later. zopty's OpticalFlowMotionBlur keeps the previous
// frame, and teruyoshii's noise_Te keeps its last one. ColorJellyFish's
// 破线縁取り raises "putpixeldata requires AviUtl userdata from getpixeldata
// (raw ffi.new is rejected)", so raw memory is refused here too. The requested
// order (rgba or bgra) is stored in the last byte of the userdata.
//
// Read: the buffer is converted back to straight alpha in an 8-bit image (blend
// mode 2 of the placing shader) and read back with Filament's
// Renderer::readPixels, as layer_fx.h reads a layer's image. It waits where the
// caller asks for the result (Engine::flushAndWait runs the callback:
// details/Engine.cpp, purge).
//
// Put: any w x h pixels the pointer holds are accepted, as AviUtl2 accepts
// them. sigma's Path_S passes its own, with numbers packed in them for its
// shaders. They become an image, are premultiplied (blend mode 1), and replace
// the contents of the buffer.
#include <lua.hpp>

namespace motolii {

// obj.getpixeldata(target, order) returns a userdata holding the pixels, then w
// and h. If the buffer does not exist it returns nil, 0, 0.
int aviutl_getpixeldata(lua_State* L);
// obj.pixeloption, as lua.txt describes it. "get" chooses the buffer that
// obj.getpixel reads, "obj" or "frm", and saying it again makes the buffer be
// read again. TextBackplate.anm2 relies on this: it specifies "get" again to
// refresh the getpixel cache. "type" chooses how a pixel is returned, "col" or
// "rgb". "put" and "blend" are stored, but putting by pixel is not implemented
// yet.
int aviutl_pixeloption(lua_State* L);
// obj.getpixel. With no arguments it returns the size of the buffer it reads.
// With (x, y[, "col" or "rgb"]) it returns one pixel, as sashimono-edit does
// (MIT, objapi.py _pixel): straight alpha, and either a packed colour and alpha
// from 0 to 1, or red, green and blue from 0 to 255 and alpha. Outside the
// image it returns 0, 0. The buffer is read back once, until obj.pixeloption
// "get" is called again.
int aviutl_getpixel(lua_State* L);
// obj.putpixeldata(target, userdata, w, h[, order]) replaces the buffer with
// the pixels in the userdata. It does nothing if the userdata holds fewer than
// w x h pixels or if w or h is 0 or above 8192.
int aviutl_putpixeldata(lua_State* L);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_PIXELS_H_

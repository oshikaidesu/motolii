#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_H_
// aviutl_obj.h: the Lua obj functions of the AviUtl adapter that read and set
// state: shaders and buffers (pixelshader, clearbuffer, copybuffer), options,
// values, audio, anchors and font.
//
// The functions below follow lua.txt. Any obj function not implemented here
// raises an error naming it.
#include <lua.hpp>

namespace motolii {

// obj.module(name) loads a script module (.mod2), which lua.txt describes as a
// way to get the functions of an AviUtl2 script module. A module is a Windows
// DLL, so none can be loaded here. The script stops with an error naming the
// module it wanted.
int aviutl_module(lua_State* L);
// Stands in for the clock of ffi.load("kernel32"). Returns the monotonic clock
// in 100 ns ticks, 10,000,000 per second, as Wine's NtQueryPerformanceCounter
// does (dlls/ntdll/unix/sync.c). HexScript's Particle_H.lua uses it to time its
// own frames (M.clock). No other Windows library and no other kernel32 call is
// provided. A script that asks for one stops with an error naming it (see the
// sandbox in aviutl_open).
int aviutl_ticks(lua_State* L);
// obj.pixelshader(name, target, {resource...}, {constant...}, blend, sampler)
// draws the named shader into the target buffer, reading the resource buffers.
// The blend is copy, draw, add or mask. The sampler is clip, dot, loop or
// mirror. Anything else raises an error.
int aviutl_pixelshader(lua_State* L);
// obj.clearbuffer(target[, w, h][, colour]) clears a buffer, creating it at the
// given size first if a size is given. Only cache buffers, object, tempbuffer
// and a framebuffer without a size are allowed.
int aviutl_clearbuffer(lua_State* L);
// obj.copybuffer(dst, src) copies one buffer to another. A src of the form
// "image:<file>" is an image file, read as obj.load reads one (lua.txt).
// Returns true on success and false if src does not exist.
int aviutl_copybuffer(lua_State* L);
// obj.setoption(name, value...) sets the draw target, blend, draw state or
// sampler.
int aviutl_setoption(lua_State* L);
// obj.getoption(name[, index]) returns the current value of an option.
int aviutl_getoption(lua_State* L);
// obj.getinfo(name) returns information about the host.
int aviutl_getinfo(lua_State* L);
// obj.getvalue(target) returns one of the script's own tracks, the time, a
// value of another layer, or a base value of this layer. Base values are those
// of a flat layer: position, rotation and centre are 0, scale and alpha are 1,
// and zoom is 100.
int aviutl_getvalue(lua_State* L);
// obj.getaudio(buffer, "audiobuffer"[, kind[, count]]), as described by
// YMM4-LuaScript's LuaScript.ja-jp.txt (routersys, MIT).
//
// Reads the project's sound at the current time: the audible videos
// (doc_sound_now in document/evaluate/place.h). The kind "pcm" gives the
// waveform scaled to 16 bits. The kind "spectrum" gives count bands (default
// 32, at most 512) with values from 0 to 32768. The kind "fourier" gives count
// bands (default 1024) with values from 0 to 1. Motolii reads sound for ISF the
// same way (sound_level.h): GStreamer's spectrum element presented like the
// Web's AnalyserNode, with 512 bands and a waveform of 1024 samples at 24000
// Hz. A ".l" or ".r" suffix on the kind is accepted and both channels are used.
//
// The values go into buffer[1..n], or into a new table when the first argument
// is not a table. Returns the count, the sample rate (24000), and the new table
// if one was made. If nothing is heard, or if any other file is asked for, the
// count is 0. YMM4 specifies the same: when the data cannot be obtained it
// returns a count of 0 and raises no error.
int aviutl_getaudio(lua_State* L);
// obj.data returns nil, because nothing is stored with the object here. The
// script 波形ライン.obj2 calls it inside pcall and draws from its parameters
// when there is no data.
int aviutl_data(lua_State* L);
// obj.setanchor(name, num, options...), as described by AviUtl2's lua.txt
// (aviutl2_modern_docs, MIT: docs/lua/index.md).
//
// The global table `name` receives num points. When the table has too few
// points for num, the {table} option is used if given. Otherwise the points are
// generated here, where AviUtl itself would generate them. There is no handle
// on the canvas yet for the user to move the points. Points that all sit on one
// spot, such as the usual {0,0,...} table of BezierPath, would make a path of
// no length, so they are generated too.
//
// The generated points start a third of the canvas from the object's centre.
// With "line" they are laid across the canvas and joined, as one wave over and
// under. With "loop", "star" and "arm" they are laid around the centre. With
// "mesh" they are laid on a grid.
//
// Points for tracks ("track", or a name like "x,y") are not generated; for now
// the parameters' values stand for them and one point is reported. Returns num.
int aviutl_setanchor(lua_State* L);
// obj.setfont(name, size, decoration, colour, edge colour, bold, italic) sets
// the font used for text. These are the first seven of the nine values of
// obj.getfont, as sashimono-edit reads them from AviUtl2's lua.txt (MIT,
// objapi.py lua_getfont). The spacing values after them are not read yet. The
// defaults are size 48, white colour and black edge.
int aviutl_setfont(lua_State* L);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_H_

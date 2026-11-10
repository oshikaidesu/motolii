#include "community/aviutl/aviutl_pixels.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Renderer.h>
#include <filament/Texture.h>
#include <lua.hpp>

#include "community/aviutl/aviutl_fx.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace {

// Creates an 8-bit RGBA image and render target of the given size, for one call. Release it with
// aviutl_let_go when done. Filament drops it after the draws that used it have finished.
AviutlBuf aviutl_bytes(AviutlRun& r, uint32_t w, uint32_t h) {
    AviutlBuf b;
    b.w = w, b.h = h;
    b.t = Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA8).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE | Texture::Usage::BLIT_SRC | Texture::Usage::UPLOADABLE).build(*r.s->engine);
    b.rt = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, b.t).build(*r.s->engine);
    return b;
}
// Destroys a buffer made by aviutl_bytes.
void aviutl_let_go(AviutlRun& r, const AviutlBuf& b) { r.s->engine->destroy(b.rt), r.s->engine->destroy(b.t); }
// Swaps the red and blue bytes of every pixel, converting between rgba and bgra.
void aviutl_swap(std::vector<uint8_t>& p) { for (size_t i = 0; i + 3 < p.size(); i += 4) std::swap(p[i], p[i + 2]); }

// Reads back the buffer `target` as described above. The pixels go into `p` and the size into `w`
// and `h`. Returns false if the buffer does not exist.
bool aviutl_read(AviutlRun& r, const std::string& target, std::vector<uint8_t>& p, uint32_t& w, uint32_t& h) {
    if (!r.bufs.count(target) || !r.bufs[target].t) return false;
    const AviutlBuf& from = r.bufs[target];
    const AviutlBuf b = aviutl_bytes(r, from.w, from.h);
    aviutl_lay(r, from, b.rt, b.w, b.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, 2);
    p.assign((size_t)b.w * b.h * 4, 0);
    r.s->renderer->readPixels(b.rt, 0, 0, b.w, b.h, backend::PixelBufferDescriptor::make(p.data(), p.size(), backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE, [](void const*, size_t) {}));
    r.s->engine->flushAndWait();
    aviutl_let_go(r, b);
    return w = b.w, h = b.h, true;
}

}  // namespace

int aviutl_getpixeldata(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    const std::string target = aviutl_name(lua_isstring(L, 1) ? lua_tostring(L, 1) : "object"), order = lua_isstring(L, 2) ? lua_tostring(L, 2) : "rgba";
    if (order != "rgba" && order != "bgra") return aviutl_no(L, "obj.getpixeldata as " + order);
    if (target != "object" && target != "tempbuffer" && target.rfind("cache:", 0) != 0) return aviutl_no(L, "obj.getpixeldata of " + target);
    std::vector<uint8_t> p;
    uint32_t w = 0, h = 0;
    if (!aviutl_read(r, target, p, w, h)) return lua_pushnil(L), lua_pushinteger(L, 0), lua_pushinteger(L, 0), 3;
    if (order == "bgra") aviutl_swap(p);
    uint8_t* copy = (uint8_t*)lua_newuserdata(L, p.size() + 1);
    std::copy(p.begin(), p.end(), copy), copy[p.size()] = order == "bgra";
    return lua_pushinteger(L, w), lua_pushinteger(L, h), 3;
}

int aviutl_pixeloption(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    const std::string n = aviutl_str(L, 1);
    if (n == "get") r.pixelFrom = aviutl_name(aviutl_str(L, 2)), r.pixelRead = false;
    else if (n == "type") r.pixelType = aviutl_str(L, 2);
    else if (n != "put" && n != "blend") return aviutl_no(L, "obj.pixeloption " + n);
    return 0;
}
int aviutl_getpixel(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    if (!lua_gettop(L)) return lua_pushinteger(L, r.bufs[r.pixelFrom].w), lua_pushinteger(L, r.bufs[r.pixelFrom].h), 2;
    if (!r.pixelRead) r.pixelRead = true, r.pixelW = r.pixelH = 0, aviutl_read(r, r.pixelFrom, r.pixelSeen, r.pixelW, r.pixelH);
    const long x = (long)std::floor(aviutl_num(L, 1)), y = (long)std::floor(aviutl_num(L, 2));
    const std::string kind = lua_isstring(L, 3) ? lua_tostring(L, 3) : r.pixelType;
    if (x < 0 || y < 0 || x >= (long)r.pixelW || y >= (long)r.pixelH) return lua_pushinteger(L, 0), lua_pushnumber(L, 0), 2;
    const uint8_t* p = r.pixelSeen.data() + ((size_t)y * r.pixelW + (size_t)x) * 4;
    if (kind == "rgb") return lua_pushinteger(L, p[0]), lua_pushinteger(L, p[1]), lua_pushinteger(L, p[2]), lua_pushnumber(L, p[3] / 255.0), 4;
    return lua_pushinteger(L, (p[0] << 16) | (p[1] << 8) | p[2]), lua_pushnumber(L, p[3] / 255.0), 2;
}

int aviutl_putpixeldata(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    const std::string target = aviutl_name(aviutl_str(L, 1));
    if (target != "object" && target != "tempbuffer" && target.rfind("cache:", 0) != 0) return aviutl_no(L, "obj.putpixeldata into " + target);
    // Only userdata that obj.getpixeldata handed out is accepted, as AviUtl2 accepts only its own.
    if (lua_type(L, 2) != LUA_TUSERDATA) return aviutl_no(L, "obj.putpixeldata of a " + std::string(luaL_typename(L, 2)));
    const uint8_t* data = (const uint8_t*)lua_touserdata(L, 2);
    const size_t held = lua_objlen(L, 2) - 1;
    const uint32_t w = (uint32_t)aviutl_num(L, 3), h = (uint32_t)aviutl_num(L, 4);
    // Never read more than the userdata holds.
    if (!data || !w || !h || w > 8192 || h > 8192 || (size_t)w * h * 4 > held) return 0;
    const std::string order = lua_isstring(L, 5) ? lua_tostring(L, 5) : data[held] ? "bgra" : "rgba";
    auto* p = new std::vector<uint8_t>(data, data + (size_t)w * h * 4);
    if (order == "bgra") aviutl_swap(*p);
    const AviutlBuf img = aviutl_bytes(r, w, h);
    img.t->setImage(*r.s->engine, 0, backend::PixelBufferDescriptor(p->data(), p->size(), backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE, [](void*, size_t, void* u) { delete (std::vector<uint8_t>*)u; }, p));
    const AviutlBuf& to = aviutl_buf(r, target, w, h);
    aviutl_lay(r, img, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, 1);
    aviutl_let_go(r, img);
    return 0;
}

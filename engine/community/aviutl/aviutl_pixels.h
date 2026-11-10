// aviutl_pixels.h: obj.getpixeldata, obj.putpixeldata, obj.pixeloption and obj.getpixel of the
// AviUtl adapter.
//
// Included by aviutl_fx.h; not self-contained.
//
// obj.getpixeldata and obj.putpixeldata follow lua.txt (references/api.md of the AviUtl2 script
// skill by gasdyueer, MIT). The buffer is "object", "tempbuffer" or "cache:...". The order is
// "rgba" or "bgra", with 8 bits per channel. The call returns a pointer, w and h. The pixels are
// kept as sashimono-edit keeps them (MIT; objapi.py lua_getpixeldata and _pixel_source, native.py
// PixelData): straight colour, rows from the top. A buffer that does not exist gives nil, 0, 0. The
// frame cannot be read. The values are the buffer's own, as its shaders read them.
//
// Each call hands out a new userdata that Lua may keep (aviutl2_modern_docs, docs/lua: the image
// data pointer is a userdata). Scripts rely on this. The 遅延 parameter of どこでもバッファ by zopty keeps a
// ring of them and puts them back frames later. zopty's OpticalFlowMotionBlur keeps the previous
// frame, and teruyoshii's noise_Te keeps its last one. ColorJellyFish's 破线縁取り raises "putpixeldata
// requires AviUtl userdata from getpixeldata (raw ffi.new is rejected)", so raw memory is refused
// here too. The requested order (rgba or bgra) is stored in the last byte of the userdata.
//
// Read: the buffer is converted back to straight alpha in an 8-bit image (blend mode 2 of the
// placing shader) and read back with Filament's Renderer::readPixels, as layer_fx.h reads a layer's
// image. It waits where the caller asks for the result (Engine::flushAndWait runs the callback:
// details/Engine.cpp, purge).
//
// Put: any w x h pixels the pointer holds are accepted, as AviUtl2 accepts them. sigma's Path_S
// passes its own, with numbers packed in them for its shaders. They become an image, are
// premultiplied (blend mode 1), and replace the contents of the buffer.

// Creates an 8-bit RGBA image and render target of the given size, for one call. Release it with
// aviutl_let_go when done. Filament drops it after the draws that used it have finished.
static AviutlBuf aviutl_bytes(AviutlRun& r, uint32_t w, uint32_t h) {
    AviutlBuf b;
    b.w = w, b.h = h;
    b.t = Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA8).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE | Texture::Usage::BLIT_SRC | Texture::Usage::UPLOADABLE).build(*r.s->engine);
    b.rt = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, b.t).build(*r.s->engine);
    return b;
}
// Destroys a buffer made by aviutl_bytes.
static void aviutl_let_go(AviutlRun& r, const AviutlBuf& b) { r.s->engine->destroy(b.rt), r.s->engine->destroy(b.t); }
// Swaps the red and blue bytes of every pixel, converting between rgba and bgra.
static void aviutl_swap(std::vector<uint8_t>& p) { for (size_t i = 0; i + 3 < p.size(); i += 4) std::swap(p[i], p[i + 2]); }

// Reads back the buffer `target` as described above. The pixels go into `p` and the size into `w`
// and `h`. Returns false if the buffer does not exist.
static bool aviutl_read(AviutlRun& r, const std::string& target, std::vector<uint8_t>& p, uint32_t& w, uint32_t& h) {
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

// obj.getpixeldata(target, order) returns a userdata holding the pixels, then w and h. If the
// buffer does not exist it returns nil, 0, 0.
static int aviutl_getpixeldata(lua_State* L) {
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

// obj.pixeloption, as lua.txt describes it. "get" chooses the buffer that obj.getpixel reads, "obj"
// or "frm", and saying it again makes the buffer be read again. TextBackplate.anm2 relies on this:
// it specifies "get" again to refresh the getpixel cache. "type" chooses how a pixel is returned,
// "col" or "rgb". "put" and "blend" are stored, but putting by pixel is not implemented yet.
static int aviutl_pixeloption(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    const std::string n = aviutl_str(L, 1);
    if (n == "get") r.pixelFrom = aviutl_name(aviutl_str(L, 2)), r.pixelRead = false;
    else if (n == "type") r.pixelType = aviutl_str(L, 2);
    else if (n != "put" && n != "blend") return aviutl_no(L, "obj.pixeloption " + n);
    return 0;
}
// obj.getpixel. With no arguments it returns the size of the buffer it reads. With (x, y[, "col" or
// "rgb"]) it returns one pixel, as sashimono-edit does (MIT, objapi.py _pixel): straight alpha, and
// either a packed colour and alpha from 0 to 1, or red, green and blue from 0 to 255 and alpha.
// Outside the image it returns 0, 0. The buffer is read back once, until obj.pixeloption "get" is
// called again.
static int aviutl_getpixel(lua_State* L) {
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

// obj.putpixeldata(target, userdata, w, h[, order]) replaces the buffer with the pixels in the
// userdata. It does nothing if the userdata holds fewer than w x h pixels or if w or h is 0 or
// above 8192.
static int aviutl_putpixeldata(lua_State* L) {
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

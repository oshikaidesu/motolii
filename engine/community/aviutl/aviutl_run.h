// aviutl_run.h: part of aviutl_fx.h. Read only through aviutl_fx.h. the Lua state made once for a file (AviUtl's globals, obj, its shaders) and one frame of it run on the thing's picture.
static const char* const aviutl_globals = R"(
local bit = require("bit")
local function byte(v) return math.max(0, math.min(255, math.floor(v))) end
function RGB(r, g, b, ...)
  if select("#", ...) > 0 then error("not yet: RGB between two colours") end
  if g == nil then r = math.floor(r); return bit.band(bit.rshift(r, 16), 255), bit.band(bit.rshift(r, 8), 255), bit.band(r, 255) end
  return bit.bor(bit.lshift(byte(r), 16), bit.lshift(byte(g), 8), byte(b))
end
function OR(a, b) return bit.bor(a, b) end
function AND(a, b) return bit.band(a, b) end
function XOR(a, b) return bit.bxor(a, b) end
function SHIFT(a, s) if s >= 0 then return bit.lshift(a, s) end return bit.arshift(a, -s) end
-- HSV(h, s, v): sashimono-edit's hsv_to_number (MIT, compat/aviutl/objapi.py), as AviUtl has it: h 0 to 360, s and v 0 to 255.
function HSV(h, s, v)
  h = ((tonumber(h) or 0) % 360) / 60
  s = math.min(math.max(tonumber(s) or 0, 0), 255) / 255
  v = math.min(math.max(tonumber(v) or 0, 0), 255)
  local function rgb(r, g, b) return RGB(math.floor(r), math.floor(g), math.floor(b)) end
  if s <= 0 then return rgb(v, v, v) end
  local sector = math.floor(h)
  local f = h - sector
  local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
  local c = ({{v, t, p}, {q, v, p}, {p, v, t}, {p, q, v}, {t, p, v}, {v, p, q}})[sector % 6 + 1]
  return rgb(c[1], c[2], c[3])
end
-- obj.interpolation(t, x0,y0,z0, x1,y1,z1, x2,y2,z2, x3,y3,z3): four points' Catmull-Rom, t 0 to 1 from the second to the
-- third, y and z left out as wanted (the AviUtl2 script skill's references/api.md, gasdyueer, MIT); each axis by
-- sashimono-edit's _catmull_rom (MIT, compat/aviutl/objapi.py), of the four points around it.
function aviutl_interpolation(t, ...)
  local p, n = {...}, select("#", ...)
  local d = math.floor(n / 4)
  if d < 1 then return 0 end
  local out = {}
  for a = 1, d do
    local p0, p1, p2, p3 = p[a], p[a + d], p[a + 2 * d], p[a + 3 * d]
    out[a] = 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
  end
  return unpack(out)
end
function rotation() error("not yet: rotation") end
debug_print = print
global = {}
-- obj.rand: YMM4-LuaScript's, as it is (native/shim.lua 4-14, 310-328; native/worker.lua 445-447).
-- MIT License, Copyright (c) 2026 routersys (https://github.com/routersys/YMM4-LuaScript).
local i64 = ffi.typeof("int64_t")
local u32 = ffi.typeof("uint32_t")
local u64 = ffi.typeof("uint64_t")

local function tou(d)
    return tonumber(u32(i64(d)))
end

local function umul32(a, b)
    return tonumber(u32(u64(a) * u64(b)))
end
local floor = math.floor
function aviutl_rand(a, b, seed, frame)
    local ps = ffi.new("double[1]", seed)
    local ws = ffi.cast("uint32_t*", ps)
    local s = tou(bit.bxor(ws[0], ws[1]))
    local pf = ffi.new("double[1]", frame)
    local wf = ffi.cast("uint32_t*", pf)
    local f = tou(bit.bxor(wf[0], wf[1]))
    local h = tou(umul32(s, 374761393) + umul32(f, 668265263))
    h = umul32(tou(bit.bxor(h, bit.rshift(h, 13))), 1274126177)
    h = tou(bit.bxor(h, bit.rshift(h, 16)))
    local r = h / 4294967295.0
    local lo = floor(math.min(a, b))
    local hi = floor(math.max(a, b))
    local span = hi - lo + 1
    if span <= 1 then return lo end
    local v = lo + floor(r * span)
    if v > hi then return hi end
    return v
end
function rand(a, b, seed, frame)
    return aviutl_rand(a or 0, b or 0, seed or 0, frame or obj.frame or 0)
end
-- obj.rand1: lua.txt's 0.0 up to (not) 1.0, from the same
function rand1(seed, frame) return aviutl_rand(0, 4294967294, seed or 0, frame or obj.frame or 0) / 4294967295 end
)";

// Made once a file: its Lua state (the libraries lua.txt leaves, require from its own folder), obj, its parameters' first
// values, and each of its shaders made (said on stderr: one that cannot be is "not yet" when it is used).
static std::shared_ptr<AviutlRun> aviutl_made(Stage& s, const std::string& file, lua_State* with = nullptr) {
    auto r = std::make_shared<AviutlRun>();
    r->file = file, r->s = &s;
    if (!aviutl_text(file, r->own, r->all, r->trouble)) return std::fprintf(stderr, "the AviUtl2 script %s is not taken: %s\n", file.c_str(), r->trouble.c_str()), r;
    r->vars = aviutl_vars(r->own);
    r->behind = std::regex_search(r->all, std::regex(R"re(copybuffer\s*\([^)]*"(framebuffer|frm)"|getoption\s*\(\s*"drawtarget"\s*\)|load\s*\(\s*"framebuffer"|pixeloption\s*\(\s*"get"\s*,\s*"(framebuffer|frm)")re"));   // (it reads the frame: its picture there is the stage's behind it)
    r->wide = std::regex_search(r->all, std::regex(R"(obj\.draw(poly)?\s*\()"));   // (it draws the object itself: where it will on the screen)
    for (const ScriptParameter& k : aviutl_parameters(file)) r->usual[k.name] = k.usual;
    std::string& path = r->path;   // (require: its own folder, then the Script folder's others: aviutl_shared)
    for (const std::filesystem::path& dir : aviutl_shared(std::filesystem::path(file).parent_path())) path += (path.empty() ? "" : ";") + dir.string() + "/?.lua;" + dir.string() + "/?/init.lua";
    lua_State* L = r->L = with ? with : luaL_newstate();
    if (!with) {   // (the thing's first: its Lua made, the libraries lua.txt leaves; those after it on the thing run in this one)
        luaL_openlibs(L);
        lua_pushcfunction(L, aviutl_ticks), lua_setglobal(L, "__motolii_ticks");
        const std::string sandbox = "os, io, debug, dofile, loadfile = nil, nil, nil, nil, nil\npackage.loaded.os, package.loaded.io, package.loaded.debug = nil, nil, nil\n"
                                    "local ffi = require('ffi'); ffi.C = nil\nlocal ticks = __motolii_ticks; __motolii_ticks = nil\n"
                                    "local clock = setmetatable({QueryPerformanceFrequency = function(p) p[0] = 10000000 return 1 end, QueryPerformanceCounter = function(p) p[0] = ticks() return 1 end},\n"
                                    "  {__index = function(_, k) error('needs Windows: kernel32 ' .. tostring(k) .. ', a Windows call', 2) end})\n"
                                    "ffi.load = function(name) if (tostring(name):lower():gsub('%.dll$', '')) == 'kernel32' then return clock end error('needs Windows: ' .. tostring(name) .. '.dll, a Windows library', 2) end\n"
                                    "package.loadlib, package.cpath = nil, ''\npackage.path = [==[" + path + "]==]\n";
        if (luaL_dostring(L, (sandbox + aviutl_globals).c_str())) r->trouble = lua_tostring(L, -1);
    }
    lua_newtable(L);
    const std::pair<const char*, lua_CFunction> calls[] = {{"pixelshader", aviutl_pixelshader}, {"clearbuffer", aviutl_clearbuffer}, {"copybuffer", aviutl_copybuffer}, {"load", aviutl_load}, {"setoption", aviutl_setoption}, {"getoption", aviutl_getoption},
        {"getinfo", aviutl_getinfo}, {"getvalue", aviutl_getvalue}, {"setanchor", aviutl_setanchor}, {"getpixel", aviutl_getpixel}, {"setfont", aviutl_setfont}, {"draw", aviutl_draw}, {"drawpoly", aviutl_drawpoly}, {"effect", aviutl_effect},
        {"getpixeldata", aviutl_getpixeldata}, {"putpixeldata", aviutl_putpixeldata}, {"pixeloption", aviutl_pixeloption}, {"getaudio", aviutl_getaudio}, {"data", aviutl_data}, {"module", aviutl_module}};
    for (const auto& [n, f] : calls) lua_pushlightuserdata(L, r.get()), lua_pushcclosure(L, f, 1), lua_setfield(L, -2, n);
    // (any other name of obj: one lua.txt has (every obj. name of aviutl2_modern_docs' docs/lua/index.md, MIT, and its old
    //  form's track0 to track3 and check0) is not made here yet; one it has not is the script's own slip, stopping AviUtl2 too)
    luaL_dostring(L, "local named = {}\n"
        "for n in ('alpha aspect clearbuffer computeshader copybuffer copypixel cx cy cz data draw drawpoly effect effect_id effect_layer frame frame_e frame_s '\n"
        "  .. 'framerate getaudio getfont getinfo getoption getpixel getpixeldata getpoint getvalue h id index interpolation layer load mes module multiobject num '\n"
        "  .. 'originframe ox oy oz pixeloption pixelshader putpixel putpixeldata rand rand1 rx ry rz scene_id screen_h screen_w setanchor setfont setoption sx sy sz '\n"
        "  .. 'time totalframe totaltime track0 track1 track2 track3 check0 w x y z zoom'):gmatch('%S+') do named[n] = true end\n"
        "return { __index = function(_, k) if named[k] then error('not yet: obj.' .. tostring(k), 2) end\n"
        "  error('not in AviUtl2: obj.' .. tostring(k) .. ' (its lua.txt has no such name: it stops there too)', 2) end }");
    lua_setmetatable(L, -2);
    lua_setglobal(L, "obj");
    luaL_dostring(L, "obj.rand, obj.rand1, obj.interpolation = rand, rand1, aviutl_interpolation");   // (lua.txt: obj. or not)
    lua_getglobal(L, "obj"), r->obj = luaL_ref(L, LUA_REGISTRYINDEX);
    std::string text = r->own.rfind("\xEF\xBB\xBF", 0) == 0 ? r->own.substr(3) : r->own;
    if (luaL_loadbuffer(L, text.data(), text.size(), ("@" + std::filesystem::path(file).filename().string()).c_str())) r->trouble = lua_tostring(L, -1);
    else r->chunk = luaL_ref(L, LUA_REGISTRYINDEX);
    std::string why;
    if (!(r->place = interop::screen(s.engine, "aviutl place", aviutl_placing, 64, &why))) r->trouble = "its placing shader: " + why;
    if (!(r->poly = interop::screen(s.engine, "aviutl drawpoly", aviutl_poly, 16, &why, 1, 0, true))) r->trouble = "its drawpoly shader: " + why;
    if (!(r->blur = interop::screen(s.engine, "aviutl blur", aviutl_blur, 16, &why))) r->trouble = "its blur shader: " + why;
    r->none = Texture::Builder().width(1).height(1).levels(1).format(Texture::InternalFormat::RGBA8).build(*s.engine);
    r->none->setImage(*s.engine, 0, backend::PixelBufferDescriptor(new uint32_t(0), 4, backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE, [](void* p, size_t, void*) { delete (uint32_t*)p; }));
    auto* noise = new std::vector<math::half>(256 * 256);   // ("random": 256 x 256 of 0 to 1 (R32F there; a half float here, as an interop's picture is filtered))
    std::mt19937 rng(1);
    for (math::half& h : *noise) h = math::half(std::uniform_real_distribution<float>(0.f, 1.f)(rng));
    r->random = Texture::Builder().width(256).height(256).levels(1).format(Texture::InternalFormat::R16F).build(*s.engine);
    r->random->setImage(*s.engine, 0, backend::PixelBufferDescriptor(noise->data(), noise->size() * 2, backend::PixelDataFormat::R, backend::PixelDataType::HALF, [](void*, size_t, void* u) { delete (std::vector<math::half>*)u; }, noise));
    int made = 0, all = 0;
    const std::regex shader(R"(--\[\[pixelshader@(\w+):)");
    for (std::sregex_iterator m(r->all.begin(), r->all.end(), shader), end; m != end; ++m, ++all) {
        std::string why;
        if (aviutl_interop(*r, (*m)[1], false, why) && (aviutl_interop(*r, (*m)[1], true, why) || true)) ++made;   // (and the way it samples "clip", made now: not inside a frame)
        else std::fprintf(stderr, "the AviUtl2 shader %s of %s is not made: %s\n", (*m)[1].str().c_str(), file.c_str(), why.substr(0, 400).c_str());
    }
    std::fprintf(stderr, "AviUtl2 script %s: %d of %d shaders made%s%s\n", file.c_str(), made, all, r->trouble.empty() ? "" : ", not taken: ", r->trouble.substr(0, 300).c_str());
    return r;
}

// One frame of it: the thing's picture `from` (w x h) its object, its parameters and obj's values told, the script run, and
// what it leaves (the frame it drew, else the object as obj now places it) drawn into `to`.
static void aviutl_draw_step(Stage& s, AviutlRun& r, Texture* from, RenderTarget* to, const ScreenNumbers& numbers, uint32_t w, uint32_t h) {
    r.s = &s, r.target = "framebuffer", r.blend = "none", r.sampler.clear(), r.drew = false, r.draws.clear(), r.font = {}, r.numbers = &numbers, r.pixelFrom = "object", r.pixelType = "col", r.pixelRead = false;
    for (auto at = r.loaded.begin(); at != r.loaded.end();)
        if (at->first.rfind("text|", 0) == 0 && !r.worded.count(at->first)) s.engine->destroy(at->second.t), at = r.loaded.erase(at);
        else ++at;
    r.worded.clear();
    if (!r.place) return screen_place(s, from, to, w, h, nullptr);   // (none made: the picture as it came)
    AviutlBuf in{from, nullptr, w, h};
    // (one that draws: the object the thing's own picture, as large as it is seen, at obj.x, obj.y from the frame's
    //  middle, the frame the stage's: AviUtl2's object, its coordinates from the screen's middle, lua.txt's obj.x)
    const bool tight = r.wide && r.seen[2] > r.seen[0] && r.seen[3] > r.seen[1] && r.box[2] > r.box[0] && r.box[3] > r.box[1];
    const double kx = tight ? w / (r.box[2] - r.box[0]) : 1, ky = tight ? h / (r.box[3] - r.box[1]) : 1;   // (its edges on whole pixels of the frame: cut out and laid back, not blurred)
    const long left = tight ? std::lround((r.seen[0] - r.box[0]) * kx) : 0, top = tight ? std::lround((r.seen[1] - r.box[1]) * ky) : 0;
    const uint32_t ow = tight ? (uint32_t)std::max(1L, std::lround((r.seen[2] - r.box[0]) * kx) - left) : w, oh = tight ? (uint32_t)std::max(1L, std::lround((r.seen[3] - r.box[1]) * ky) - top) : h;
    const double atX = left + ow / 2.0 - w / 2.0, atY = top + oh / 2.0 - h / 2.0;
    const AviutlBuf& object = aviutl_buf(r, "object", ow, oh);
    aviutl_lay(r, in, object.rt, ow, oh, -atX, -atY, 1, 1, 0, 1, 0, 0, -1, 1, 0, 1);   // (premultiplied, as AviUtl2's pictures are)
    const AviutlBuf& frame = aviutl_buf(r, "framebuffer", w, h);
    const bool behind = r.behind && s.behind && r.box[2] > r.box[0] && r.box[3] > r.box[1];
    aviutl_clear(r, frame, behind ? std::max(r.ground, 0) : 0, behind && r.ground >= 0);
    if (behind) {   // (what is drawn before it, there: the stage's colour, then the stage's picture without the thing (render_layers.h, as AbsentMotion's backdrop reads it) in sRGB as the thing's own picture is given (screen_tone), over it)
        const double bw = s.behind->getWidth(), bh = s.behind->getHeight(), kx = bw / std::max(1, s.w), ky = bh / std::max(1, s.h);
        const AviutlBuf all{s.behind, nullptr, (uint32_t)bw, (uint32_t)bh};
        const AviutlBuf& there = aviutl_buf(r, "~behind", w, h);
        aviutl_lay(r, all, there.rt, w, h, 0, 0, w / ((r.box[2] - r.box[0]) * kx), h / ((r.box[3] - r.box[1]) * ky), 0, 1, (r.box[0] + r.box[2]) / 2 * kx - bw / 2, (r.box[1] + r.box[3]) / 2 * ky - bh / 2, -1, 1);
        const AviutlBuf& toned = aviutl_buf(r, "~behind_srgb", w, h);
        screen_tone(s, there.t, toned.rt, w, h, true);
        aviutl_lay(r, toned, frame.rt, w, h, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1);
    }
    std::string trouble = r.trouble;
    lua_State* L = r.L;
    if (trouble.empty()) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, r.obj), lua_setglobal(L, "obj");   // (its own obj, its clock (aviutl_late's) and where its require looks, in the Lua it shares)
        lua_pushlightuserdata(L, &r), lua_setfield(L, LUA_REGISTRYINDEX, "motolii.run");
        lua_getglobal(L, "package"), lua_pushstring(L, r.path.c_str()), lua_setfield(L, -2, "path"), lua_pop(L, 1);
        for (const AviutlVar& v : r.vars) aviutl_set(L, v, [&](const std::string& k) { return numbers(r.file, k, r.usual.count(k) ? r.usual[k] : v.usual); });
        lua_getglobal(L, "obj");
        const double frame = std::round(s.now * screen_rate(s));
        const std::pair<const char*, double> values[] = {{"ox", 0}, {"oy", 0}, {"oz", 0}, {"rx", 0}, {"ry", 0}, {"rz", 0}, {"cx", 0}, {"cy", 0}, {"cz", 0}, {"sx", 1}, {"sy", 1}, {"sz", 1}, {"zoom", 1}, {"aspect", 0}, {"alpha", 1},
            {"x", atX}, {"y", atY}, {"z", 0}, {"w", (double)ow}, {"h", (double)oh}, {"screen_w", (double)s.w}, {"screen_h", (double)s.h}, {"framerate", screen_rate(s)}, {"frame", frame}, {"time", s.now}, {"totalframe", frame + 1}, {"totaltime", s.now},
            {"layer", numbers(r.file, "aviutl.layer", 1)}, {"index", 0}, {"num", 1}, {"id", 1}, {"effect_id", 1}, {"frame_s", 0}, {"frame_e", frame}, {"effect_layer", 1}, {"originframe", 0}, {"scene_id", 0}};
        for (const auto& [n, v] : values) lua_pushnumber(L, v), lua_setfield(L, -2, n);
        lua_pop(L, 1);
        std::string with;   // (its parameters' values now)
        for (const AviutlVar& v : r.vars) with += std::to_string(numbers(r.file, v.var, NAN)) + ",";
        if (with == r.late) trouble = aviutl_too_long;
        else {
            r.until = std::chrono::steady_clock::now() + std::chrono::milliseconds(5000);
            lua_sethook(L, aviutl_late, LUA_MASKCOUNT, 100000);
            lua_rawgeti(L, LUA_REGISTRYINDEX, r.chunk);
            if (lua_pcall(L, 0, 0, 0)) trouble = lua_tostring(L, -1) ? lua_tostring(L, -1) : "?", lua_pop(L, 1);
            lua_sethook(L, nullptr, 0, 0);
            r.until = std::chrono::steady_clock::time_point::max();
            if (trouble.find(aviutl_too_long) != std::string::npos) r.late = with;
        }
    }
    if (!trouble.empty()) {   // (the picture as it came, the reason said once)
        if (r.said.insert(trouble).second) std::fprintf(stderr, "the AviUtl2 script %s stops: %s\n", r.file.c_str(), trouble.substr(0, 400).c_str());
        return aviutl_lay(r, in, to, w, h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
    }
    const AviutlBuf& out = aviutl_buf(r, "~out", w, h);   // (what it drew, the object over it unless it drew it, made straight again into `to`)
    aviutl_lay(r, r.bufs["framebuffer"], out.rt, w, h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
    lua_getglobal(L, "obj");
    const auto f = [&](const char* k, double otherwise) { lua_getfield(L, -1, k); const double v = aviutl_num(L, -1, otherwise); lua_pop(L, 1); return v; };
    const double zoom = f("zoom", 1), aspect = f("aspect", 0);
    if (!r.drew && r.poly && (f("rx", 0) != 0 || f("ry", 0) != 0 || f("oz", 0) != 0))   // (in depth: aviutl_placed)
        aviutl_placed(r, r.bufs["object"], out, f("x", 0) + f("ox", 0), f("y", 0) + f("oy", 0), f("oz", 0), zoom * f("sx", 1) * (aspect > 0 ? 1 - aspect : 1), zoom * f("sy", 1) * (aspect < 0 ? 1 + aspect : 1), f("rx", 0), f("ry", 0), f("rz", 0), f("cx", 0), f("cy", 0), f("alpha", 1), 0, 0);
    else if (!r.drew) aviutl_lay(r, r.bufs["object"], out.rt, w, h, f("x", 0) + f("ox", 0), f("y", 0) + f("oy", 0), zoom * f("sx", 1) * (aspect > 0 ? 1 - aspect : 1), zoom * f("sy", 1) * (aspect < 0 ? 1 + aspect : 1), f("rz", 0), f("alpha", 1), f("cx", 0), f("cy", 0), 0, 0);
    lua_pop(L, 1);
    aviutl_lay(r, out, to, w, h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, 2);
}

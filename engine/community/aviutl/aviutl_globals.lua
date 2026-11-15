-- aviutl_globals.lua: the AviUtl2 globals (RGB, HSV, bit helpers, rand) and the
-- obj functions that need no engine access. Loaded into every script's Lua
-- state by aviutl_run.cpp. Kept as .lua so lua.txt's own ways can be edited
-- here without re-building the engine.

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

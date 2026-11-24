// Host-level GPU spatial upscaler using AMD FidelityFX FSR 1.0 (EASU + RCAS).
// Source: https://github.com/GPUOpen-Effects/FidelityFX-FSR (MIT, Copyright (c)
// 2021 Advanced Micro Devices, Inc., ffx-fsr/ffx_fsr1.h: FsrEasuF & FsrRcasF).

#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <cstdint>

#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::RenderTarget;
using filament::Texture;

namespace {

static const char* const kFsrEasuWgsl = R"wgsl(
@group(0) @binding(0) var source: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;

fn luma2(c: vec3f) -> f32 {
  return c.b * 0.5 + (c.r * 0.5 + c.g);
}

fn load_src(p: vec2i, dims: vec2i) -> vec4f {
  return textureLoad(source, clamp(p, vec2i(0), dims - vec2i(1)), 0);
}

fn easu_set(dir: ptr<function, vec2f>, len: ptr<function, f32>, w: f32,
            lA: f32, lB: f32, lC: f32, lD: f32, lE: f32) {
  let dc = lD - lC;
  let cb = lC - lB;
  let lenX0 = max(abs(dc), abs(cb));
  let dirX = lD - lB;
  (*dir).x += dirX * w;
  var lenX = select(0.0, clamp(abs(dirX) / lenX0, 0.0, 1.0), lenX0 > 1e-6);
  lenX *= lenX;
  *len += lenX * w;

  let ec = lE - lC;
  let ca = lC - lA;
  let lenY0 = max(abs(ec), abs(ca));
  let dirY = lE - lA;
  (*dir).y += dirY * w;
  var lenY = select(0.0, clamp(abs(dirY) / lenY0, 0.0, 1.0), lenY0 > 1e-6);
  lenY *= lenY;
  *len += lenY * w;
}

fn easu_tap(aC: ptr<function, vec4f>, aW: ptr<function, f32>, off: vec2f,
            dir: vec2f, len2: vec2f, lob: f32, clp: f32, c: vec4f) {
  var v = vec2f(off.x * dir.x + off.y * dir.y, off.x * (-dir.y) + off.y * dir.x);
  v *= len2;
  let d2 = min(dot(v, v), clp);
  var wB = 0.4 * d2 - 1.0;
  var wA = lob * d2 - 1.0;
  wB *= wB;
  wA *= wA;
  wB = (25.0 / 16.0) * wB - (9.0 / 16.0);
  let w = wB * wA;
  *aC += c * w;
  *aW += w;
}

@fragment
fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let dims_u = textureDimensions(source, 0);
  let dims = vec2i(dims_u);
  let p_src = uv * vec2f(dims_u) - vec2f(0.5);
  let fp = floor(p_src);
  let pp = p_src - fp;
  let base = vec2i(fp);

  let b = load_src(base + vec2i( 0, -1), dims);
  let c = load_src(base + vec2i( 1, -1), dims);
  let e = load_src(base + vec2i(-1,  0), dims);
  let f = load_src(base + vec2i( 0,  0), dims);
  let g = load_src(base + vec2i( 1,  0), dims);
  let h = load_src(base + vec2i( 2,  0), dims);
  let i = load_src(base + vec2i(-1,  1), dims);
  let j = load_src(base + vec2i( 0,  1), dims);
  let k = load_src(base + vec2i( 1,  1), dims);
  let l = load_src(base + vec2i( 2,  1), dims);
  let n = load_src(base + vec2i( 0,  2), dims);
  let o = load_src(base + vec2i( 1,  2), dims);

  var dir = vec2f(0.0);
  var len: f32 = 0.0;
  easu_set(&dir, &len, (1.0 - pp.x) * (1.0 - pp.y), luma2(b.rgb), luma2(e.rgb), luma2(f.rgb), luma2(g.rgb), luma2(j.rgb));
  easu_set(&dir, &len, pp.x * (1.0 - pp.y),         luma2(c.rgb), luma2(f.rgb), luma2(g.rgb), luma2(h.rgb), luma2(k.rgb));
  easu_set(&dir, &len, (1.0 - pp.x) * pp.y,         luma2(f.rgb), luma2(i.rgb), luma2(j.rgb), luma2(k.rgb), luma2(n.rgb));
  easu_set(&dir, &len, pp.x * pp.y,                 luma2(g.rgb), luma2(j.rgb), luma2(k.rgb), luma2(l.rgb), luma2(o.rgb));

  let dirR0 = dot(dir, dir);
  if (dirR0 < (1.0 / 32768.0)) {
    dir = vec2f(1.0, 0.0);
  } else {
    dir *= inverseSqrt(dirR0);
  }

  len = len * 0.5;
  len *= len;
  let stretch = dot(dir, dir) / max(max(abs(dir.x), abs(dir.y)), 1e-6);
  let len2 = vec2f(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
  let lob = 0.5 + ((0.25 - 0.04) - 0.5) * len;
  let clp = 1.0 / lob;

  let min4 = min(min(f, g), min(j, k));
  let max4 = max(max(f, g), max(j, k));

  var aC = vec4f(0.0);
  var aW: f32 = 0.0;
  easu_tap(&aC, &aW, vec2f( 0.0, -1.0) - pp, dir, len2, lob, clp, b);
  easu_tap(&aC, &aW, vec2f( 1.0, -1.0) - pp, dir, len2, lob, clp, c);
  easu_tap(&aC, &aW, vec2f(-1.0,  1.0) - pp, dir, len2, lob, clp, i);
  easu_tap(&aC, &aW, vec2f( 0.0,  1.0) - pp, dir, len2, lob, clp, j);
  easu_tap(&aC, &aW, vec2f( 0.0,  0.0) - pp, dir, len2, lob, clp, f);
  easu_tap(&aC, &aW, vec2f(-1.0,  0.0) - pp, dir, len2, lob, clp, e);
  easu_tap(&aC, &aW, vec2f( 1.0,  1.0) - pp, dir, len2, lob, clp, k);
  easu_tap(&aC, &aW, vec2f( 2.0,  1.0) - pp, dir, len2, lob, clp, l);
  easu_tap(&aC, &aW, vec2f( 2.0,  0.0) - pp, dir, len2, lob, clp, h);
  easu_tap(&aC, &aW, vec2f( 1.0,  0.0) - pp, dir, len2, lob, clp, g);
  easu_tap(&aC, &aW, vec2f( 1.0,  2.0) - pp, dir, len2, lob, clp, o);
  easu_tap(&aC, &aW, vec2f( 0.0,  2.0) - pp, dir, len2, lob, clp, n);

  return clamp(aC / max(aW, 1e-6), min4, max4);
}
)wgsl";

static const char* const kFsrRcasWgsl = R"wgsl(
struct RcasParams {
  sharpness: f32,
  _pad0: f32,
  _pad1: f32,
  _pad2: f32,
};

@group(0) @binding(0) var source: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> params: RcasParams;

const FSR_RCAS_LIMIT: f32 = 0.1875;

fn luma2(c: vec3f) -> f32 {
  return c.b * 0.5 + (c.r * 0.5 + c.g);
}

fn load_px(p: vec2i, dims: vec2i) -> vec4f {
  return textureLoad(source, clamp(p, vec2i(0), dims - vec2i(1)), 0);
}

@fragment
fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let dims = vec2i(textureDimensions(source, 0));
  let sp = vec2i(frag.xy);
  let b = load_px(sp + vec2i( 0, -1), dims).rgb;
  let d = load_px(sp + vec2i(-1,  0), dims).rgb;
  let ee = load_px(sp, dims);
  let e = ee.rgb;
  let f = load_px(sp + vec2i( 1,  0), dims).rgb;
  let h = load_px(sp + vec2i( 0,  1), dims).rgb;

  let bL = luma2(b); let dL = luma2(d); let eL = luma2(e); let fL = luma2(f); let hL = luma2(h);
  let span = max(max(max(bL, dL), max(eL, fL)), hL) - min(min(min(bL, dL), min(eL, fL)), hL);
  var nz = 0.25 * (bL + dL + fL + hL) - eL;
  nz = select(0.0, clamp(abs(nz) / span, 0.0, 1.0), span > 1e-6);
  nz = -0.5 * nz + 1.0;

  let mn4 = min(min(b, d), min(f, h));
  let mx4 = max(max(b, d), max(f, h));
  let hitMin = min(mn4, e) / max(4.0 * mx4, vec3f(1e-6));
  let hitMax = (vec3f(1.0) - max(mx4, e)) / min(4.0 * mn4 - vec3f(4.0), vec3f(-1e-6));
  let lobeRGB = max(-hitMin, hitMax);
  let sharp = exp2(-clamp(params.sharpness, 0.0, 2.0));
  var lobe = max(-FSR_RCAS_LIMIT, min(max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b)), 0.0)) * sharp;
  lobe *= nz;

  let rcpL = 1.0 / (4.0 * lobe + 1.0);
  let rgb = (lobe * (b + d + h + f) + e) * rcpL;
  let a = clamp(ee.a, 0.0, 1.0);
  // Keep premultiplied alpha invariant (rgb <= a) to avoid fringing on alpha edges.
  return vec4f(clamp(rgb, vec3f(0.0), vec3f(a)), a);
}
)wgsl";

}  // namespace

void screen_upscale(Stage& s, Texture* from, RenderTarget* to, uint32_t w,
                    uint32_t h, float sharpness) {
  if (!from || !w || !h) return;
  if (from->getWidth() >= w && from->getHeight() >= h)
    return screen_place(s, from, to, w, h, nullptr);

  if (!s.place_fsr[0])
    s.place_fsr[0] = interop::screen(s.engine, "fsr1_easu", kFsrEasuWgsl, 0);
  if (!s.place_fsr[1])
    s.place_fsr[1] = interop::screen(s.engine, "fsr1_rcas", kFsrRcasWgsl, 16);
  if (!s.place_fsr[0] || !s.place_fsr[1])
    return screen_place(s, from, to, w, h, nullptr);

  if (!s.fsr_mid_tex || s.fsr_mid_w != w || s.fsr_mid_h != h) {
    if (s.fsr_mid_rt) s.engine->destroy(s.fsr_mid_rt), s.fsr_mid_rt = nullptr;
    if (s.fsr_mid_tex) {
      interop::invalidate_textures(s.engine);
      s.engine->destroy(s.fsr_mid_tex), s.fsr_mid_tex = nullptr;
    }
    s.fsr_mid_tex = Texture::Builder()
                        .width(w)
                        .height(h)
                        .levels(1)
                        .format(Texture::InternalFormat::RGBA8)
                        .usage(Texture::Usage::COLOR_ATTACHMENT |
                               Texture::Usage::SAMPLEABLE)
                        .build(*s.engine);
    s.fsr_mid_rt =
        RenderTarget::Builder()
            .texture(RenderTarget::AttachmentPoint::COLOR, s.fsr_mid_tex)
            .build(*s.engine);
    s.fsr_mid_w = w, s.fsr_mid_h = h;
  }

  interop::draw(s.engine, s.place_fsr[0], from, s.fsr_mid_rt, w, h, nullptr);
  const float u[4] = {sharpness, 0.0f, 0.0f, 0.0f};
  interop::parameters(s.engine, s.place_fsr[1], u, sizeof u, 0);
  interop::draw(s.engine, s.place_fsr[1], s.fsr_mid_tex, to, w, h, nullptr);
}

}  // namespace motolii

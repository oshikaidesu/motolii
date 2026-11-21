// Halo Glow: ported from HaloGlow v1.0.0 (MIT, Copyright (c) 2026 PALF MovieWorks, https://github.com/palf-gh/HaloGlow, GPU/HG_PixelMath.h & GPU/HG_Kernels.h; shelves/effects/sources/HaloGlow-LICENSE.txt)
// --label:Stylize
// --about:Multi-scale screen glow with soft-knee extraction, HDR-safe octave roll-off, and two-colour tint.
// --tag:glow basic
// --spill
// --pass@d0:0,1,s1,s1
// --pass@d1:0,1,s0.5,s0.5
// --pass@d2:0,1,s0.25,s0.25
// --pass@d3:0,1,s0.125,s0.125
// --pass@d4:0,1,s0.0625,s0.0625
// --pass@d5:0,1,s0.03125,s0.03125
// --pass@g5:0,1,s0.03125,s0.03125
// --pass@g4:0,1,s0.0625,s0.0625
// --pass@g3:0,1,s0.125,s0.125
// --pass@g2:0,1,s0.25,s0.25
// --pass@g1:0,1,s0.5,s0.5
// --pass@:0,0,s1,s1
diagnostic(off, derivative_uniformity);

struct Knobs {
  @auto passindex: f32,
  @auto resolution: vec2<f32>,
  @auto frameRect: vec4<f32>,
  @auto passRect: vec4<f32>,
  @range(0, 8, 0.01, 1)    intensity: f32,
  @range(0, 512, 0.5, 64)  size: f32,
  @range(0, 200, 0.5, 25)  threshold: f32,
  @label("Threshold Softness")
  @range(0, 100, 0.5, 50)  softness: f32,
  @group("Shape")
  @range(10, 400, 1, 100)  width: f32,
  @range(10, 400, 1, 100)  height: f32,
  @range(0, 100, 0.5, 50)  falloff: f32,
  @group("Tone")
  @range(0.1, 3, 0.01, 1)  gamma: f32,
  @range(0, 200, 1, 100)   saturation: f32,
  @range(0, 100, 1, 0)     colourStrength: f32,
  @color(1.0, 0.894, 0.769) colour1: vec3<f32>,
  @color(1.0, 1.0, 1.0)     colour2: vec3<f32>,
  @group("Output")
  @range(0, 100, 1, 100)   glowOpacity: f32,
  @range(0, 100, 1, 100)   sourceOpacity: f32,
  @toggle(0)               glowOnly: u32,
};

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var d0: texture_2d<f32>;
@group(0) @binding(3) var d0_sampler: sampler;
@group(0) @binding(4) var d1: texture_2d<f32>;
@group(0) @binding(5) var d1_sampler: sampler;
@group(0) @binding(6) var d2: texture_2d<f32>;
@group(0) @binding(7) var d2_sampler: sampler;
@group(0) @binding(8) var d3: texture_2d<f32>;
@group(0) @binding(9) var d3_sampler: sampler;
@group(0) @binding(10) var d4: texture_2d<f32>;
@group(0) @binding(11) var d4_sampler: sampler;
@group(0) @binding(12) var d5: texture_2d<f32>;
@group(0) @binding(13) var d5_sampler: sampler;
@group(0) @binding(14) var g5: texture_2d<f32>;
@group(0) @binding(15) var g5_sampler: sampler;
@group(0) @binding(16) var g4: texture_2d<f32>;
@group(0) @binding(17) var g4_sampler: sampler;
@group(0) @binding(18) var g3: texture_2d<f32>;
@group(0) @binding(19) var g3_sampler: sampler;
@group(0) @binding(20) var g2: texture_2d<f32>;
@group(0) @binding(21) var g2_sampler: sampler;
@group(0) @binding(22) var g1: texture_2d<f32>;
@group(0) @binding(23) var g1_sampler: sampler;
@group(0) @binding(24) var<uniform> knobs: Knobs;

const LUM = vec3<f32>(0.2126390, 0.7151687, 0.0721923);

fn to_linear(c: vec3<f32>) -> vec3<f32> {
  return select(pow((c + 0.055) / 1.055, vec3<f32>(2.4)), c / 12.92, c <= vec3<f32>(0.04045));
}

fn to_srgb(c: vec3<f32>) -> vec3<f32> {
  return select(1.055 * pow(c, vec3<f32>(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3<f32>(0.0031308));
}

fn framed(uv: vec2<f32>) -> vec2<f32> {
  return uv * knobs.frameRect.zw + knobs.frameRect.xy;
}

// Reads premultiplied sRGB input and converts to premultiplied linear RGBA.
fn read_source_linear(uv: vec2<f32>) -> vec4<f32> {
  let p = textureSampleLevel(picture, picture_sampler, framed(uv), 0.0);
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  let a = clamp(p.a, 0.0, 1.0);
  let straight = clamp(p.rgb / a, vec3<f32>(0.0), vec3<f32>(1.0));
  return vec4<f32>(to_linear(straight) * a, a);
}

fn sample_t(t: texture_2d<f32>, s: sampler, uv: vec2<f32>) -> vec4<f32> {
  if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) { return vec4<f32>(0.0); }
  return textureSampleLevel(t, s, framed(uv), 0.0);
}

fn hg_luma(rgb: vec3<f32>) -> f32 {
  return dot(LUM, rgb);
}

// HaloGlow v2 soft-knee extraction (HG_PixelMath.h: hg_extract).
fn hg_extract(src: vec4<f32>) -> vec4<f32> {
  let a = clamp(src.a, 0.0, 1.0);
  if (a <= 0.0) { return vec4<f32>(0.0); }
  let pr = max(src.rgb, vec3<f32>(0.0));
  let thresh = max(knobs.threshold, 0.0) * 0.01;
  if (thresh <= 0.0) {
    let ye = hg_luma(pr);
    return vec4<f32>(pr, min(a, max(ye, 0.0)));
  }
  let knee = thresh * clamp(knobs.softness, 0.0, 100.0) * 0.01;
  let t = a * thresh;
  let k = a * knee;
  var ch = vec3<f32>(0.0);
  if (k > 0.0) {
    let z = clamp(pr - vec3<f32>(t) + vec3<f32>(k), vec3<f32>(0.0), vec3<f32>(2.0 * k));
    let kr = z * (0.25 * (z / k));
    ch = clamp(max(pr - vec3<f32>(t), kr), vec3<f32>(0.0), pr);
  } else {
    ch = clamp(pr - vec3<f32>(t), vec3<f32>(0.0), pr);
  }
  let y = hg_luma(pr);
  var excess = max(y - t, 0.0);
  if (k > 0.0) {
    let zy = clamp(y - t + k, 0.0, 2.0 * k);
    let ky = zy * (0.25 * (zy / k));
    excess = max(y - t, ky);
  }
  let mask = select(0.0, clamp(excess / y, 0.0, 1.0), y > 0.0);
  let e_rgb = 0.85 * (mask * pr) + 0.15 * ch;
  let ye = hg_luma(e_rgb);
  return vec4<f32>(e_rgb, min(a, max(ye, 0.0)));
}

fn hg_one_minus_exp_neg(x: f32) -> f32 {
  if (x < 1.0e-3) { return x * (1.0 - x * (0.5 - x * (1.0 / 6.0))); }
  return 1.0 - exp(-x);
}

fn hg_gamma_curve(y: f32) -> f32 {
  let g = clamp(knobs.gamma, 0.1, 3.0);
  if (y <= 1.0) { return pow(max(y, 0.0), 1.0 / g); }
  return 1.0 + (y - 1.0) / g;
}

// HaloGlow v2 octave gain and shoulder (HG_PixelMath.h).
fn hg_octave_span() -> f32 {
  let s = max(knobs.size, 0.0);
  if (s <= 0.0) { return 0.0; }
  return clamp(log2(max(s, 1.0)) - 1.0, 0.5, 5.5);
}

fn hg_scale_gain(octave: f32) -> f32 {
  let span = hg_octave_span();
  if (span <= 0.0) { return 0.0; }
  // Smoothly taper octaves past the active Size radius so Size varies continuously.
  let reach = clamp(span - octave + 0.75, 0.0, 1.0);
  if (reach <= 0.0) { return 0.0; }
  let f = clamp(knobs.falloff, 0.0, 100.0) * 0.01;
  let tail = 0.04 + 0.16 * f;
  let t = clamp(octave / max(span, 1.0), 0.0, 1.0);
  return reach * 8.0 * pow(tail, t);
}

fn hg_scale_shoulder(gain: f32, x: f32) -> f32 {
  let u = gain * x;
  if (!(gain > 1.0)) { return u; }
  return u / (1.0 + (gain - 1.0) * clamp(x, 0.0, 1.0));
}

fn hg_tone_scale(v: vec4<f32>, gain: f32) -> vec4<f32> {
  if (gain <= 0.0) { return vec4<f32>(0.0); }
  let p = max(v, vec4<f32>(0.0));
  return vec4<f32>(
    hg_gamma_curve(hg_scale_shoulder(gain, p.r)),
    hg_gamma_curve(hg_scale_shoulder(gain, p.g)),
    hg_gamma_curve(hg_scale_shoulder(gain, p.b)),
    hg_gamma_curve(hg_scale_shoulder(gain, p.a))
  );
}

fn hg_screen(a: vec4<f32>, b: vec4<f32>) -> vec4<f32> {
  return a + b - clamp(a, vec4<f32>(0.0), vec4<f32>(1.0)) * clamp(b, vec4<f32>(0.0), vec4<f32>(1.0));
}

fn aniso_scale() -> vec2<f32> {
  return vec2<f32>(
    clamp(knobs.width, 10.0, 400.0) * 0.01,
    clamp(knobs.height, 10.0, 400.0) * 0.01
  );
}

// 13-tap Jimenez/HaloGlow downsample kernel at exact 1-texel lattice (no aliasing).
fn downsample_13(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, texel: vec2<f32>) -> vec4<f32> {
  let d = texel;
  let a = sample_t(t, s, uv + vec2<f32>(-2.0, -2.0) * d);
  let b = sample_t(t, s, uv + vec2<f32>( 0.0, -2.0) * d);
  let c = sample_t(t, s, uv + vec2<f32>( 2.0, -2.0) * d);
  let d0s = sample_t(t, s, uv + vec2<f32>(-1.0, -1.0) * d);
  let e = sample_t(t, s, uv + vec2<f32>( 1.0, -1.0) * d);
  let f = sample_t(t, s, uv + vec2<f32>(-2.0,  0.0) * d);
  let g = sample_t(t, s, uv);
  let h = sample_t(t, s, uv + vec2<f32>( 2.0,  0.0) * d);
  let i = sample_t(t, s, uv + vec2<f32>(-1.0,  1.0) * d);
  let j = sample_t(t, s, uv + vec2<f32>( 1.0,  1.0) * d);
  let k = sample_t(t, s, uv + vec2<f32>(-2.0,  2.0) * d);
  let l = sample_t(t, s, uv + vec2<f32>( 0.0,  2.0) * d);
  let m = sample_t(t, s, uv + vec2<f32>( 2.0,  2.0) * d);
  return g * 0.125
       + (d0s + e + i + j) * 0.125
       + (b + f + h + l) * 0.0625
       + (a + c + k + m) * 0.03125;
}

// Separable 5x5 binomial low-pass [1, 4, 6, 4, 1] / 16 (HG_Kernels.h: bin5).
fn binomial5(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, texel: vec2<f32>) -> vec4<f32> {
  let w = array<f32, 5>(0.0625, 0.25, 0.375, 0.25, 0.0625);
  let d = texel * clamp(aniso_scale(), vec2<f32>(0.25), vec2<f32>(2.0));
  var acc = vec4<f32>(0.0);
  for (var j = -2; j <= 2; j = j + 1) {
    var row = vec4<f32>(0.0);
    for (var i = -2; i <= 2; i = i + 1) {
      row = row + sample_t(t, s, uv + vec2<f32>(f32(i), f32(j)) * d) * w[i + 2];
    }
    acc = acc + row * w[j + 2];
  }
  return acc;
}

// 9-tap tent upsample (HG_Kernels.h: hg_upsample in UV space).
fn upsample_tent(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, texel: vec2<f32>) -> vec4<f32> {
  let d = texel * clamp(aniso_scale(), vec2<f32>(0.5), vec2<f32>(1.5));
  var acc = sample_t(t, s, uv) * 4.0;
  acc = acc + (sample_t(t, s, uv + vec2<f32>(-d.x, 0.0)) + sample_t(t, s, uv + vec2<f32>(d.x, 0.0))
             + sample_t(t, s, uv + vec2<f32>(0.0, -d.y)) + sample_t(t, s, uv + vec2<f32>(0.0, d.y))) * 2.0;
  acc = acc + (sample_t(t, s, uv + vec2<f32>(-d.x, -d.y)) + sample_t(t, s, uv + vec2<f32>(d.x, -d.y))
             + sample_t(t, s, uv + vec2<f32>(-d.x,  d.y)) + sample_t(t, s, uv + vec2<f32>(d.x,  d.y)));
  return acc * 0.0625;
}

fn hg_glow_from_filtered(b_in: vec4<f32>) -> vec4<f32> {
  let gain = max(knobs.intensity, 0.0) * 0.75;
  let u = gain * b_in.rgb;
  let yu = hg_luma(u);
  let sat = max(knobs.saturation, 0.0) * 0.01;
  let l0 = max(sat * u + (1.0 - sat) * vec3<f32>(yu), vec3<f32>(0.0));
  let y0 = hg_luma(l0);
  let t = clamp(y0, 0.0, 1.0);
  let c1 = to_linear(clamp(knobs.colour1, vec3<f32>(0.0), vec3<f32>(1.0)));
  let c2 = to_linear(clamp(knobs.colour2, vec3<f32>(0.0), vec3<f32>(1.0)));
  let tint = mix(c1, c2, t);
  let cs = clamp(knobs.colourStrength, 0.0, 100.0) * 0.01;
  let l = mix(l0, vec3<f32>(y0) * tint, cs);

  let aux = gain * b_in.a;
  let ylight = hg_luma(l);
  let x_alpha = max(min(aux, ylight), 0.0);
  var a_light = hg_one_minus_exp_neg(x_alpha);
  let coverage = clamp(max(l.r, max(l.g, l.b)), 0.0, 1.0);
  a_light = max(a_light, coverage);

  let q = clamp(knobs.glowOpacity, 0.0, 100.0) * 0.01;
  return vec4<f32>(l * q, a_light * q);
}

fn hg_composite(src: vec4<f32>, glow: vec4<f32>) -> vec4<f32> {
  if (knobs.glowOnly != 0u) { return glow; }
  let sp = clamp(knobs.sourceOpacity, 0.0, 100.0) * 0.01;
  let s_rgb = src.rgb * sp;
  let sa = clamp(src.a, 0.0, 1.0) * sp;
  let o_rgb = s_rgb + glow.rgb - 0.95 * clamp(glow.rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * clamp(s_rgb, vec3<f32>(0.0), vec3<f32>(1.0));
  var oa = sa + (1.0 - sa) * glow.a;
  let src_max = max(s_rgb.r, max(s_rgb.g, s_rgb.b));
  let out_max = max(o_rgb.r, max(o_rgb.g, o_rgb.b));
  let base = max(clamp(src_max, 0.0, 1.0), sa);
  let excess = max(clamp(out_max, 0.0, 1.0) - base, 0.0);
  oa = max(oa, clamp(sa + excess, 0.0, 1.0));
  return vec4<f32>(o_rgb, clamp(oa, 0.0, 1.0));
}

fn linear_premul_to_srgb(p: vec4<f32>) -> vec4<f32> {
  let a = clamp(p.a, 0.0, 1.0);
  if (a <= 0.0) { return vec4<f32>(0.0); }
  let straight = clamp(p.rgb / a, vec3<f32>(0.0), vec3<f32>(1.0));
  return vec4<f32>(to_srgb(straight) * a, a);
}

@fragment
fn main(@location(0) door_on: vec2<f32>) -> @location(0) vec4<f32> {
  let uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  let base_texel = 1.0 / max(knobs.resolution, vec2<f32>(1.0));
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return hg_extract(read_source_linear(uv)); }
    case 1u: { return downsample_13(d0, d0_sampler, uv, base_texel); }
    case 2u: { return downsample_13(d1, d1_sampler, uv, base_texel * 2.0); }
    case 3u: { return downsample_13(d2, d2_sampler, uv, base_texel * 4.0); }
    case 4u: { return downsample_13(d3, d3_sampler, uv, base_texel * 8.0); }
    case 5u: { return downsample_13(d4, d4_sampler, uv, base_texel * 16.0); }
    case 6u: { return hg_tone_scale(binomial5(d5, d5_sampler, uv, base_texel * 32.0), hg_scale_gain(5.0)); }
    case 7u: {
      let fine = hg_tone_scale(binomial5(d4, d4_sampler, uv, base_texel * 16.0), hg_scale_gain(4.0));
      let up = upsample_tent(g5, g5_sampler, uv, base_texel * 32.0);
      return hg_screen(up, fine);
    }
    case 8u: {
      let fine = hg_tone_scale(binomial5(d3, d3_sampler, uv, base_texel * 8.0), hg_scale_gain(3.0));
      let up = upsample_tent(g4, g4_sampler, uv, base_texel * 16.0);
      return hg_screen(up, fine);
    }
    case 9u: {
      let fine = hg_tone_scale(binomial5(d2, d2_sampler, uv, base_texel * 4.0), hg_scale_gain(2.0));
      let up = upsample_tent(g3, g3_sampler, uv, base_texel * 8.0);
      return hg_screen(up, fine);
    }
    case 10u: {
      let fine = hg_tone_scale(binomial5(d1, d1_sampler, uv, base_texel * 2.0), hg_scale_gain(1.0));
      let up = upsample_tent(g2, g2_sampler, uv, base_texel * 4.0);
      return hg_screen(up, fine);
    }
    default: {}
  }

  let src = read_source_linear(uv);
  if (knobs.intensity <= 0.0 || knobs.size <= 0.0 || knobs.glowOpacity <= 0.0) {
    if (knobs.glowOnly != 0u) { return vec4<f32>(0.0); }
    let sp = clamp(knobs.sourceOpacity, 0.0, 100.0) * 0.01;
    return linear_premul_to_srgb(src * sp);
  }
  let local = hg_tone_scale(binomial5(d0, d0_sampler, uv, base_texel), hg_scale_gain(0.0));
  let wide = upsample_tent(g1, g1_sampler, uv, base_texel * 2.0);
  let b = hg_screen(wide, local);
  let glow = hg_glow_from_filtered(b);
  return linear_premul_to_srgb(hg_composite(src, glow));
}

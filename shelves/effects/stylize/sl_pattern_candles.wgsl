// Pattern Candles: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Rebuilds the image from repeating graphic patterns, light to dark.
diagnostic(off, derivative_uniformity);
struct Knobs {
  @auto time: f32,
  @auto passindex: f32,
  @auto resolution: vec2<f32>,
  @auto frameRect: vec4<f32>,
  @auto passRect: vec4<f32>,
  @range(4, 48, 1, 12)         cellSize: f32,
  @range(0, 4, 1, 0)           colorMode: f32,
  @label("Tint r")
  @range(0, 1, 0.001, 0.913099, 0.913099, 0.871367) monoColor: vec3<f32>,
  @label("Background")
  @range(0, 1, 0.01, 0)        bgOpacity: f32,
  @toggle(0)                   invert: f32,
  @label("Color Count")
  @range(2, 4, 1, 4)           customColorCount: f32,
  @label("Luminance Bias")
  @range(-1, 1, 0.01, 0)       customLuminanceBias: f32,
  @label("Background r")
  @range(0, 1, 0.001, 0.913099, 0.913099, 0.871367) customBgColor: vec3<f32>,
  @label("Shadows r")
  @range(0, 1, 0.001, 0.00402472, 0.00518152, 0.00699541) customColor1: vec3<f32>,
  @label("Midtones / Highlights r")
  @range(0, 1, 0.001, 0.0742136, 0.0802198, 0.0953075) customColor2: vec3<f32>,
  @label("High Mids r")
  @range(0, 1, 0.001, 0.304987, 0.323143, 0.361307) customColor3: vec3<f32>,
  @label("Highlights r")
  @range(0, 1, 0.001, 0.752942, 0.760525, 0.730461) customColor4: vec3<f32>,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;
fn to_linear(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }
fn to_srgb(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }
fn framed(uv: vec2f) -> vec2f { return uv * knobs.frameRect.zw + knobs.frameRect.xy; }
fn picture_read(uv: vec2f) -> vec4f { return picture_read_level(uv, 0.0); }
fn picture_read_level(uv: vec2f, level: f32) -> vec4f {
  let p = textureSampleLevel(picture, picture_sampler, framed(uv), level);
  if (p.a <= 0.0) { return vec4f(0.0); }
  return vec4f(to_linear(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))), p.a);
}
fn picture_load(p: vec2i, level: u32) -> vec4f { return picture_read_level((vec2f(p) + 0.5) / knobs.resolution, 0.0); }
fn target_read(t: texture_2d<f32>, s: sampler, uv: vec2f) -> vec4f { return textureSampleLevel(t, s, framed(uv), 0.0); }
fn target_load(t: texture_2d<f32>, p: vec2i, level: u32) -> vec4f { return textureLoad(t, p + vec2i(knobs.frameRect.xy * vec2f(textureDimensions(t)) + 0.5), level); }
fn target_read_level(t: texture_2d<f32>, s: sampler, uv: vec2f, level: f32) -> vec4f { return textureSampleLevel(t, s, framed(uv), level); }
fn to_shelf(p: vec4f) -> vec4f { return vec4f(to_srgb(clamp(p.rgb, vec3f(0.0), vec3f(1.0))) * p.a, p.a); }
fn none(uv: vec2f) -> vec4f { return vec4f(0.0); }
fn none_level(uv: vec2f, level: f32) -> vec4f { return vec4f(0.0); }
fn none_load(p: vec2i, level: u32) -> vec4f { return vec4f(0.0); }
const own0_read_texels = array<vec4f, 1024>(vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(0.0,0.0,0.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(0.0,0.0,0.0,1.0));
fn own0_read_at(x: i32, y: i32) -> vec4f { return own0_read_texels[clamp(y, 0, 15) * 64 + clamp(x, 0, 63)]; }
fn own0_read(uv: vec2f) -> vec4f {
  let p = vec2f(clamp(uv.x, 0.0, 1.0), clamp(uv.y, 0.0, 1.0)) * vec2f(64.0, 16.0) - vec2f(0.5);
  let a = vec2i(floor(p)); let f = fract(p);
  return own0_read_at(a.x + i32(f.x + 0.5), a.y + i32(f.y + 0.5));
}
fn own0_read_load(p: vec2i, level: u32) -> vec4f { return own0_read((vec2f(p) + 0.5) / vec2f(64.0, 16.0)); }
fn own0_read_level(uv: vec2f, level: f32) -> vec4f { return own0_read(uv); }

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : vec3<f32>;
var<private> p0_nodeVar2 : bool;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : vec4<f32>;
var<private> p0_nodeVar5 : vec3<f32>;
var<private> p0_nodeVar6 : vec3<f32>;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : vec2<f32>;
var<private> p0_nodeVar14 : vec4<f32>;
var<private> p0_nodeVar15 : vec3<f32>;
var<private> p0_nodeVar16 : vec2<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_nodeVar18 : vec3<f32>;
var<private> p0_nodeVar19 : vec2<f32>;
var<private> p0_nodeVar20 : vec4<f32>;
var<private> p0_nodeVar21 : vec3<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : vec3<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : vec2<f32>;
var<private> p0_nodeVar26 : vec4<f32>;
var<private> p0_nodeVar27 : vec2<f32>;
var<private> p0_nodeVar28 : vec4<f32>;
var<private> p0_nodeVar29 : vec3<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec3<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : vec2<f32>;
var<private> p0_nodeVar34 : vec4<f32>;
var<private> p0_nodeVar35 : vec2<f32>;
var<private> p0_nodeVar36 : vec4<f32>;
var<private> p0_nodeVar37 : vec3<f32>;
var<private> p0_nodeVar38 : vec3<f32>;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : vec2<f32>;
var<private> p0_nodeVar41 : vec4<f32>;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : vec4<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : vec3<f32>;
var<private> p0_nodeVar46 : vec3<f32>;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec2<f32>;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : vec4<f32>;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec3<f32>;
var<private> p0_nodeVar54 : vec3<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : vec2<f32>;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : vec4<f32>;
var<private> p0_nodeVar60 : vec2<f32>;
var<private> p0_nodeVar61 : vec2<f32>;
var<private> p0_nodeVar62 : vec4<f32>;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : vec3<f32>;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : vec3<f32>;
var<private> p0_nodeVar67 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar68 : vec4<f32>;

// codes
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar2 = ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) > 3.5 );

	if ( ( ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) < 0.5 ) || p0_nodeVar2 ) ) {

		p0_nodeVar3 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
		p0_nodeVar4 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar3 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar3 ) );
		p0_nodeVar1 = ( vec3<f32>( p0_nodeVar4.x, p0_nodeVar4.y, p0_nodeVar4.z ) * vec3<f32>( f32(knobs.bgOpacity) ) );

	} else {


		if ( ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) < 2.5 ) ) {

			p0_nodeVar5 = vec3<f32>( 0.0, 0.0, 0.0 );

		} else {

			p0_nodeVar5 = vec3<f32>( vec3<f32>(knobs.customBgColor.x, knobs.customBgColor.y, knobs.customBgColor.z).x, vec3<f32>(knobs.customBgColor.x, knobs.customBgColor.y, knobs.customBgColor.z).y, vec3<f32>(knobs.customBgColor.x, knobs.customBgColor.y, knobs.customBgColor.z).z );

		}

		p0_nodeVar1 = p0_nodeVar5;

	}


	if ( p0_nodeVar2 ) {


		if ( ( f32(knobs.invert) > 0.5 ) ) {

			p0_nodeVar8 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
			p0_nodeVar9 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar8 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar8 ) );
			p0_nodeVar7 = ( 1.0 - ( ( ( p0_nodeVar9.x * 0.299 ) + ( p0_nodeVar9.y * 0.45 ) ) + ( p0_nodeVar9.z * 0.114 ) ) );

		} else {

			p0_nodeVar10 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
			p0_nodeVar11 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar10 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar10 ) );
			p0_nodeVar7 = ( ( ( p0_nodeVar11.x * 0.299 ) + ( p0_nodeVar11.y * 0.45 ) ) + ( p0_nodeVar11.z * 0.114 ) );

		}

		p0_nodeVar12 = floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) * vec2<f32>( f32(2048.0), f32(1024.0) ) ) );
		p0_nodeVar13 = vec2<f32>( p0_tsl_mod_float( p0_nodeVar12.x, f32(knobs.cellSize) ), p0_tsl_mod_float( p0_nodeVar12.y, f32(knobs.cellSize) ) );
		p0_nodeVar14 = own0_read( vec2<f32>( ( ( ( ( floor( clamp( ( p0_nodeVar7 * ( f32(4.0) - 1.0 ) ), 0.0, ( f32(4.0) - 1.0 ) ) ) * f32(knobs.cellSize) ) + p0_nodeVar13.x ) + 0.5 ) / ( f32(4.0) * f32(knobs.cellSize) ) ), ( ( p0_nodeVar13.y + 0.5 ) / f32(knobs.cellSize) ) ) );
		p0_nodeVar6 = vec3<f32>( p0_nodeVar14.x, p0_nodeVar14.y, p0_nodeVar14.z );

	} else {


		if ( ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) < 0.5 ) ) {

			p0_nodeVar16 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
			p0_nodeVar17 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar16 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar16 ) );
			p0_nodeVar15 = vec3<f32>( p0_nodeVar17.x, p0_nodeVar17.y, p0_nodeVar17.z );

		} else {


			if ( ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) < 1.5 ) ) {

				p0_nodeVar19 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
				p0_nodeVar20 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar19 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar19 ) );
				p0_nodeVar21 = ( floor( ( ( vec3<f32>( p0_nodeVar20.x, p0_nodeVar20.y, p0_nodeVar20.z ) * vec3<f32>( 7.0, 7.0, 3.0 ) ) + vec3<f32>( 0.5, 0.5, 0.5 ) ) ) * vec3<f32>( 0.14285714285714285, 0.14285714285714285, 0.3333333333333333 ) );
				p0_nodeVar22 = ( ( ( p0_nodeVar21.x * 0.299 ) + ( p0_nodeVar21.y * 0.45 ) ) + ( p0_nodeVar21.z * 0.114 ) );
				p0_nodeVar18 = clamp( mix( vec3<f32>( p0_nodeVar22, p0_nodeVar22, p0_nodeVar22 ), p0_nodeVar21, 1.2 ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) );

			} else {


				if ( ( f32(array<f32, 5>(0.0, 1.0, 2.0, 3.0, 0.0)[u32(knobs.colorMode)]) < 2.5 ) ) {


					if ( ( f32(knobs.invert) > 0.5 ) ) {

						p0_nodeVar25 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
						p0_nodeVar26 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar25 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar25 ) );
						p0_nodeVar24 = ( 1.0 - ( ( ( p0_nodeVar26.x * 0.299 ) + ( p0_nodeVar26.y * 0.45 ) ) + ( p0_nodeVar26.z * 0.114 ) ) );

					} else {

						p0_nodeVar27 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
						p0_nodeVar28 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar27 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar27 ) );
						p0_nodeVar24 = ( ( ( p0_nodeVar28.x * 0.299 ) + ( p0_nodeVar28.y * 0.45 ) ) + ( p0_nodeVar28.z * 0.114 ) );

					}

					p0_nodeVar23 = ( vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ) * vec3<f32>( p0_nodeVar24 ) );

				} else {

					p0_nodeVar30 = clamp( f32(knobs.customColorCount), 2.0, 4.0 );

					if ( ( p0_nodeVar30 < 2.5 ) ) {


						if ( ( f32(knobs.invert) > 0.5 ) ) {

							p0_nodeVar33 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
							p0_nodeVar34 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar33 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar33 ) );
							p0_nodeVar32 = ( 1.0 - ( ( ( p0_nodeVar34.x * 0.299 ) + ( p0_nodeVar34.y * 0.45 ) ) + ( p0_nodeVar34.z * 0.114 ) ) );

						} else {

							p0_nodeVar35 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
							p0_nodeVar36 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar35 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar35 ) );
							p0_nodeVar32 = ( ( ( p0_nodeVar36.x * 0.299 ) + ( p0_nodeVar36.y * 0.45 ) ) + ( p0_nodeVar36.z * 0.114 ) );

						}


						if ( ( clamp( ( p0_nodeVar32 + ( f32(knobs.customLuminanceBias) * 0.35 ) ), 0.0, 1.0 ) < 0.5 ) ) {

							p0_nodeVar31 = vec3<f32>( vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).x, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).y, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).z );

						} else {

							p0_nodeVar31 = vec3<f32>( vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).x, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).y, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).z );

						}

						p0_nodeVar29 = p0_nodeVar31;

					} else {


						if ( ( p0_nodeVar30 < 3.5 ) ) {


							if ( ( f32(knobs.invert) > 0.5 ) ) {

								p0_nodeVar40 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
								p0_nodeVar41 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar40 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar40 ) );
								p0_nodeVar39 = ( 1.0 - ( ( ( p0_nodeVar41.x * 0.299 ) + ( p0_nodeVar41.y * 0.45 ) ) + ( p0_nodeVar41.z * 0.114 ) ) );

							} else {

								p0_nodeVar42 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
								p0_nodeVar43 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar42 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar42 ) );
								p0_nodeVar39 = ( ( ( p0_nodeVar43.x * 0.299 ) + ( p0_nodeVar43.y * 0.45 ) ) + ( p0_nodeVar43.z * 0.114 ) );

							}

							p0_nodeVar44 = clamp( ( p0_nodeVar39 + ( f32(knobs.customLuminanceBias) * 0.35 ) ), 0.0, 1.0 );

							if ( ( p0_nodeVar44 < 0.3333333333333333 ) ) {

								p0_nodeVar38 = vec3<f32>( vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).x, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).y, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).z );

							} else {


								if ( ( p0_nodeVar44 < 0.6666666666666666 ) ) {

									p0_nodeVar45 = vec3<f32>( vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).x, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).y, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).z );

								} else {

									p0_nodeVar45 = vec3<f32>( vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).x, vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).y, vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).z );

								}

								p0_nodeVar38 = p0_nodeVar45;

							}

							p0_nodeVar37 = p0_nodeVar38;

						} else {


							if ( ( f32(knobs.invert) > 0.5 ) ) {

								p0_nodeVar48 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
								p0_nodeVar49 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar48 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar48 ) );
								p0_nodeVar47 = ( 1.0 - ( ( ( p0_nodeVar49.x * 0.299 ) + ( p0_nodeVar49.y * 0.45 ) ) + ( p0_nodeVar49.z * 0.114 ) ) );

							} else {

								p0_nodeVar50 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
								p0_nodeVar51 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar50 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar50 ) );
								p0_nodeVar47 = ( ( ( p0_nodeVar51.x * 0.299 ) + ( p0_nodeVar51.y * 0.45 ) ) + ( p0_nodeVar51.z * 0.114 ) );

							}

							p0_nodeVar52 = clamp( ( p0_nodeVar47 + ( f32(knobs.customLuminanceBias) * 0.35 ) ), 0.0, 1.0 );

							if ( ( p0_nodeVar52 < 0.25 ) ) {

								p0_nodeVar46 = vec3<f32>( vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).x, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).y, vec3<f32>(knobs.customColor1.x, knobs.customColor1.y, knobs.customColor1.z).z );

							} else {


								if ( ( p0_nodeVar52 < 0.5 ) ) {

									p0_nodeVar53 = vec3<f32>( vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).x, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).y, vec3<f32>(knobs.customColor2.x, knobs.customColor2.y, knobs.customColor2.z).z );

								} else {


									if ( ( p0_nodeVar52 < 0.75 ) ) {

										p0_nodeVar54 = vec3<f32>( vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).x, vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).y, vec3<f32>(knobs.customColor3.x, knobs.customColor3.y, knobs.customColor3.z).z );

									} else {

										p0_nodeVar54 = vec3<f32>( vec3<f32>(knobs.customColor4.x, knobs.customColor4.y, knobs.customColor4.z).x, vec3<f32>(knobs.customColor4.x, knobs.customColor4.y, knobs.customColor4.z).y, vec3<f32>(knobs.customColor4.x, knobs.customColor4.y, knobs.customColor4.z).z );

									}

									p0_nodeVar53 = p0_nodeVar54;

								}

								p0_nodeVar46 = p0_nodeVar53;

							}

							p0_nodeVar37 = p0_nodeVar46;

						}

						p0_nodeVar29 = p0_nodeVar37;

					}

					p0_nodeVar23 = p0_nodeVar29;

				}

				p0_nodeVar18 = p0_nodeVar23;

			}

			p0_nodeVar15 = p0_nodeVar18;

		}

		p0_nodeVar6 = p0_nodeVar15;

	}


	if ( ( f32(knobs.invert) > 0.5 ) ) {

		p0_nodeVar56 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
		p0_nodeVar57 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar56 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar56 ) );
		p0_nodeVar55 = ( 1.0 - ( ( ( p0_nodeVar57.x * 0.299 ) + ( p0_nodeVar57.y * 0.45 ) ) + ( p0_nodeVar57.z * 0.114 ) ) );

	} else {

		p0_nodeVar58 = ( vec2<f32>( f32(knobs.cellSize), f32(knobs.cellSize) ) / vec2<f32>( f32(2048.0), f32(1024.0) ) );
		p0_nodeVar59 = picture_read( ( ( floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) / p0_nodeVar58 ) ) + vec2<f32>( 0.5, 0.5 ) ) * p0_nodeVar58 ) );
		p0_nodeVar55 = ( ( ( p0_nodeVar59.x * 0.299 ) + ( p0_nodeVar59.y * 0.45 ) ) + ( p0_nodeVar59.z * 0.114 ) );

	}

	p0_nodeVar60 = floor( ( clamp( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) * vec2<f32>( f32(2048.0), f32(1024.0) ) ) );
	p0_nodeVar61 = vec2<f32>( p0_tsl_mod_float( p0_nodeVar60.x, f32(knobs.cellSize) ), p0_tsl_mod_float( p0_nodeVar60.y, f32(knobs.cellSize) ) );
	p0_nodeVar62 = own0_read( vec2<f32>( ( ( ( ( floor( clamp( ( p0_nodeVar55 * ( f32(4.0) - 1.0 ) ), 0.0, ( f32(4.0) - 1.0 ) ) ) * f32(knobs.cellSize) ) + p0_nodeVar61.x ) + 0.5 ) / ( f32(4.0) * f32(knobs.cellSize) ) ), ( ( p0_nodeVar61.y + 0.5 ) / f32(knobs.cellSize) ) ) );
	p0_nodeVar63 = vec4<f32>( mix( p0_nodeVar1, p0_nodeVar6, p0_nodeVar62.x ), 1.0 );
	p0_nodeVar64 = vec3<f32>( p0_nodeVar63.x, p0_nodeVar63.y, p0_nodeVar63.z );
	p0_nodeVar65 = ( ( ( p0_nodeVar64.x * 0.2126 ) + ( p0_nodeVar64.y * 0.7152 ) ) + ( p0_nodeVar64.z * 0.0722 ) );
	p0_nodeVar66 = mix( vec3<f32>( p0_nodeVar65, p0_nodeVar65, p0_nodeVar65 ), p0_nodeVar64, f32(1.0) );
	p0_nodeVar67 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar66.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar66.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar66.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar66.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar66.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar66.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar66.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar66.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar66.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar63.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar67.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar67.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar68 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar68;

	// result

	p0_output.color = p0_nodeVar68;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

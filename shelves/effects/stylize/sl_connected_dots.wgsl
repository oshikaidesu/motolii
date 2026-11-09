// Connected Dots: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Turns the image into points linked to their neighbors: tone graphs, ink blobs or fading plexus lines. Points can drift so links form and break.
// --pass@t0:0,1,s0.36953125000000003,s0.37812500000000004
// --pass@:0,0,s1,s1
// --track@mode:Mode,0,3,0,1
// --track@spacing:Spacing,3,120,10,1
// --track@jitter:Jitter,0,1,0.9,0.01
// --track@cutoff:Cutoff,0,1,0.05,0.01
// --check@invert:Invert,0
// --track@dotShape:Dot Shape,0,3,0,1
// --track@minSize:Min Size,0,1,0.46,0.01
// --track@maxSize:Max Size,0,1,0.74,0.01
// --track@links:Links,0,1,0.85,0.01
// --track@linkThreshold:Link Threshold,0,1,0.5,0.01
// --track@linkMin:Thin Links,0,1,0.3,0.01
// --track@linkMax:Thick Links,0,1.5,0.46,0.01
// --track@blobiness:Blobiness,0,1,0.5,0.01
// --track@range:Range,1,2.9,1.6,0.01
// --track@lineWidth:Line Width,0.25,6,0.8,0.05
// --track@colorMode:Color,0,2,0,1
// --track@ink_x:Ink r,0,1,0.005605391621829108,0.001
// --track@ink_y:Ink g,0,1,0.005605391621829108,0.001
// --track@ink_z:Ink b,0,1,0.005605391621829108,0.001
// --track@background:Background,0,2,0,1
// --track@backgroundColor_x:Background Color r,0,1,0.55201140150344,0.001
// --track@backgroundColor_y:Background Color g,0,1,0.55201140150344,0.001
// --track@backgroundColor_z:Background Color b,0,1,0.55201140150344,0.001
// --track@drift:Drift,0,1,0,0.01
// --track@seed:Seed,0,999,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  mode: f32,
  spacing: f32,
  jitter: f32,
  cutoff: f32,
  invert: f32,
  dotShape: f32,
  minSize: f32,
  maxSize: f32,
  links: f32,
  linkThreshold: f32,
  linkMin: f32,
  linkMax: f32,
  blobiness: f32,
  range: f32,
  lineWidth: f32,
  colorMode: f32,
  ink: vec3<f32>,
  background: f32,
  backgroundColor: vec3<f32>,
  drift: f32,
  seed: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var<uniform> knobs: Knobs;
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
const own1_read_texels = array<vec4f, 256>(vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.010960093699395657,0.011612244881689548,0.01599629409611225,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.024157632142305374,0.21223075687885284,0.672443151473999,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.15896083414554596,0.4507857859134674,0.8631572127342224,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.3324515223503113,0.5520114302635193,0.1946178376674652,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.8069522380828857,0.17464740574359894,0.1441284716129303,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(0.5711248517036438,0.26635560393333435,0.7454041838645935,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0),vec4f(1.0,1.0,1.0,1.0));
fn own1_read_at(x: i32, y: i32) -> vec4f { return own1_read_texels[clamp(y, 0, 0) * 256 + clamp(x, 0, 255)]; }
fn own1_read(uv: vec2f) -> vec4f {
  let p = vec2f(clamp(uv.x, 0.0, 1.0), clamp(uv.y, 0.0, 1.0)) * vec2f(256.0, 1.0) - vec2f(0.5);
  let a = vec2i(floor(p)); let f = fract(p);
  return own1_read_at(a.x + i32(f.x + 0.5), a.y + i32(f.y + 0.5));
}
fn own1_read_load(p: vec2i, level: u32) -> vec4f { return own1_read((vec2f(p) + 0.5) / vec2f(256.0, 1.0)); }
fn own1_read_level(uv: vec2f, level: f32) -> vec4f { return own1_read(uv); }

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : vec2<f32>;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : vec2<f32>;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : vec2<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec4<f32>;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : vec4<f32>;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : vec2<f32>;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : vec2<f32>;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec2<f32>;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : vec4<f32>;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : vec2<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : vec4<f32>;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec2<f32>;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : vec4<f32>;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec2<f32>;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : vec4<f32>;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : vec4<f32>;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : vec2<f32>;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : vec4<f32>;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : vec2<f32>;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : vec4<f32>;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : vec2<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : vec4<f32>;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : vec2<f32>;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : vec4<f32>;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : vec2<f32>;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : vec4<f32>;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : vec2<f32>;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : vec4<f32>;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : f32;
var<private> p0_nodeVar95 : vec2<f32>;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : vec4<f32>;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : vec4<f32>;
var<private> p0_nodeVar102 : f32;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : vec4<f32>;
var<private> p0_nodeVar106 : vec2<f32>;
var<private> p0_nodeVar107 : vec2<f32>;
var<private> p0_nodeVar108 : vec2<f32>;
var<private> p0_nodeVar109 : vec2<f32>;
var<private> p0_nodeVar110 : vec2<f32>;
var<private> p0_nodeVar111 : vec2<f32>;
var<private> p0_nodeVar112 : vec2<f32>;
var<private> p0_nodeVar113 : vec2<f32>;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : vec4<f32>;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : f32;
var<private> p0_nodeVar119 : vec4<f32>;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : f32;
var<private> p0_nodeVar122 : f32;
var<private> p0_nodeVar123 : vec4<f32>;
var<private> p0_nodeVar124 : vec2<f32>;
var<private> p0_nodeVar125 : vec2<f32>;
var<private> p0_nodeVar126 : vec2<f32>;
var<private> p0_nodeVar127 : vec2<f32>;
var<private> p0_nodeVar128 : vec2<f32>;
var<private> p0_nodeVar129 : vec2<f32>;
var<private> p0_nodeVar130 : vec2<f32>;
var<private> p0_nodeVar131 : vec2<f32>;
var<private> p0_nodeVar132 : f32;
var<private> p0_nodeVar133 : f32;
var<private> p0_nodeVar134 : vec4<f32>;
var<private> p0_nodeVar135 : f32;
var<private> p0_nodeVar136 : f32;
var<private> p0_nodeVar137 : vec4<f32>;
var<private> p0_nodeVar138 : f32;
var<private> p0_nodeVar139 : f32;
var<private> p0_nodeVar140 : f32;
var<private> p0_nodeVar141 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );

	if ( ( f32(0.0) > 0.0 ) ) {

		p0_nodeVar1 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 2.0 ) );
		p0_nodeVar2 = ( p0_nodeVar1 + vec2<f32>( ( f32(knobs.seed) * 13.1 ) ) );
		p0_nodeVar3 = fract( ( sin( vec2<f32>( dot( p0_nodeVar2, vec2<f32>( 127.1, 311.7 ) ), dot( p0_nodeVar2, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) );
		p0_nodeVar4 = vec2<f32>( 0.0, 0.0 );

		if ( ( f32(knobs.drift) > 0.0 ) ) {


			if ( ( f32(knobs.mode) > 2.5 ) ) {

				p0_nodeVar6 = ( p0_nodeVar3 * vec2<f32>( 6.2831853 ) );
				p0_nodeVar5 = ( ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar6.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar6.y ) ) ) * ( vec2<f32>( 0.5, 0.5 ) - abs( ( ( p0_nodeVar3 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) ) ) ) * vec2<f32>( f32(knobs.drift) ) );

			} else {

				p0_nodeVar7 = ( p0_nodeVar3 * vec2<f32>( 6.2831853 ) );
				p0_nodeVar5 = ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar7.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar7.y ) ) ) * vec2<f32>( ( f32(knobs.drift) * 0.35 ) ) );

			}

			p0_nodeVar4 = p0_nodeVar5;
			

		}

		p0_nodeVar8 = ( ( p0_nodeVar1 + ( ( ( ( p0_nodeVar3 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) + vec2<f32>( 0.5 ) ) + p0_nodeVar4 ) ) * vec2<f32>( f32(knobs.spacing) ) );
		p0_nodeVar9 = ( ( p0_nodeVar8 / vec2<f32>( f32(knobs.spacing) ) ) - p0_nodeVar1 );
		p0_nodeVar10 = ( ( p0_nodeVar1 + vec2<f32>( 2.0 ) ) * vec2<f32>( 4.0 ) );
		p0_nodeVar11 = vec2<f32>( 0.0, 0.0 );
		p0_nodeVar12 = 0.0;
		p0_nodeVar13 = 0.0;
		p0_nodeVar14 = 0.0;
		p0_nodeVar15 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 0.0, 0.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar16 = p0_nodeVar15.x;
		p0_nodeVar17 = ( p0_nodeVar16 * p0_nodeVar16 );
		p0_nodeVar18 = ( vec2<f32>( 0.125, 0.125 ) - p0_nodeVar9 );
		p0_nodeVar19 = ( ( p0_nodeVar17 * p0_nodeVar17 ) * exp( ( dot( p0_nodeVar18, p0_nodeVar18 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.125, 0.125 ) * vec2<f32>( p0_nodeVar19 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar19 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar16 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar16 );
		p0_nodeVar20 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 1.0, 0.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar21 = p0_nodeVar20.x;
		p0_nodeVar22 = ( p0_nodeVar21 * p0_nodeVar21 );
		p0_nodeVar23 = ( vec2<f32>( 0.375, 0.125 ) - p0_nodeVar9 );
		p0_nodeVar24 = ( ( p0_nodeVar22 * p0_nodeVar22 ) * exp( ( dot( p0_nodeVar23, p0_nodeVar23 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.375, 0.125 ) * vec2<f32>( p0_nodeVar24 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar24 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar21 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar21 );
		p0_nodeVar25 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 2.0, 0.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar26 = p0_nodeVar25.x;
		p0_nodeVar27 = ( p0_nodeVar26 * p0_nodeVar26 );
		p0_nodeVar28 = ( vec2<f32>( 0.625, 0.125 ) - p0_nodeVar9 );
		p0_nodeVar29 = ( ( p0_nodeVar27 * p0_nodeVar27 ) * exp( ( dot( p0_nodeVar28, p0_nodeVar28 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.625, 0.125 ) * vec2<f32>( p0_nodeVar29 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar29 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar26 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar26 );
		p0_nodeVar30 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 3.0, 0.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar31 = p0_nodeVar30.x;
		p0_nodeVar32 = ( p0_nodeVar31 * p0_nodeVar31 );
		p0_nodeVar33 = ( vec2<f32>( 0.875, 0.125 ) - p0_nodeVar9 );
		p0_nodeVar34 = ( ( p0_nodeVar32 * p0_nodeVar32 ) * exp( ( dot( p0_nodeVar33, p0_nodeVar33 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.875, 0.125 ) * vec2<f32>( p0_nodeVar34 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar34 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar31 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar31 );
		p0_nodeVar35 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 0.0, 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar36 = p0_nodeVar35.x;
		p0_nodeVar37 = ( p0_nodeVar36 * p0_nodeVar36 );
		p0_nodeVar38 = ( vec2<f32>( 0.125, 0.375 ) - p0_nodeVar9 );
		p0_nodeVar39 = ( ( p0_nodeVar37 * p0_nodeVar37 ) * exp( ( dot( p0_nodeVar38, p0_nodeVar38 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.125, 0.375 ) * vec2<f32>( p0_nodeVar39 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar39 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar36 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar36 );
		p0_nodeVar40 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 1.0, 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar41 = p0_nodeVar40.x;
		p0_nodeVar42 = ( p0_nodeVar41 * p0_nodeVar41 );
		p0_nodeVar43 = ( vec2<f32>( 0.375, 0.375 ) - p0_nodeVar9 );
		p0_nodeVar44 = ( ( p0_nodeVar42 * p0_nodeVar42 ) * exp( ( dot( p0_nodeVar43, p0_nodeVar43 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.375, 0.375 ) * vec2<f32>( p0_nodeVar44 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar44 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar41 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar41 );
		p0_nodeVar45 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 2.0, 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar46 = p0_nodeVar45.x;
		p0_nodeVar47 = ( p0_nodeVar46 * p0_nodeVar46 );
		p0_nodeVar48 = ( vec2<f32>( 0.625, 0.375 ) - p0_nodeVar9 );
		p0_nodeVar49 = ( ( p0_nodeVar47 * p0_nodeVar47 ) * exp( ( dot( p0_nodeVar48, p0_nodeVar48 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.625, 0.375 ) * vec2<f32>( p0_nodeVar49 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar49 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar46 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar46 );
		p0_nodeVar50 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 3.0, 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar51 = p0_nodeVar50.x;
		p0_nodeVar52 = ( p0_nodeVar51 * p0_nodeVar51 );
		p0_nodeVar53 = ( vec2<f32>( 0.875, 0.375 ) - p0_nodeVar9 );
		p0_nodeVar54 = ( ( p0_nodeVar52 * p0_nodeVar52 ) * exp( ( dot( p0_nodeVar53, p0_nodeVar53 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.875, 0.375 ) * vec2<f32>( p0_nodeVar54 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar54 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar51 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar51 );
		p0_nodeVar55 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 0.0, 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar56 = p0_nodeVar55.x;
		p0_nodeVar57 = ( p0_nodeVar56 * p0_nodeVar56 );
		p0_nodeVar58 = ( vec2<f32>( 0.125, 0.625 ) - p0_nodeVar9 );
		p0_nodeVar59 = ( ( p0_nodeVar57 * p0_nodeVar57 ) * exp( ( dot( p0_nodeVar58, p0_nodeVar58 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.125, 0.625 ) * vec2<f32>( p0_nodeVar59 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar59 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar56 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar56 );
		p0_nodeVar60 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 1.0, 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar61 = p0_nodeVar60.x;
		p0_nodeVar62 = ( p0_nodeVar61 * p0_nodeVar61 );
		p0_nodeVar63 = ( vec2<f32>( 0.375, 0.625 ) - p0_nodeVar9 );
		p0_nodeVar64 = ( ( p0_nodeVar62 * p0_nodeVar62 ) * exp( ( dot( p0_nodeVar63, p0_nodeVar63 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.375, 0.625 ) * vec2<f32>( p0_nodeVar64 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar64 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar61 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar61 );
		p0_nodeVar65 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 2.0, 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar66 = p0_nodeVar65.x;
		p0_nodeVar67 = ( p0_nodeVar66 * p0_nodeVar66 );
		p0_nodeVar68 = ( vec2<f32>( 0.625, 0.625 ) - p0_nodeVar9 );
		p0_nodeVar69 = ( ( p0_nodeVar67 * p0_nodeVar67 ) * exp( ( dot( p0_nodeVar68, p0_nodeVar68 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.625, 0.625 ) * vec2<f32>( p0_nodeVar69 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar69 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar66 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar66 );
		p0_nodeVar70 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 3.0, 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar71 = p0_nodeVar70.x;
		p0_nodeVar72 = ( p0_nodeVar71 * p0_nodeVar71 );
		p0_nodeVar73 = ( vec2<f32>( 0.875, 0.625 ) - p0_nodeVar9 );
		p0_nodeVar74 = ( ( p0_nodeVar72 * p0_nodeVar72 ) * exp( ( dot( p0_nodeVar73, p0_nodeVar73 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.875, 0.625 ) * vec2<f32>( p0_nodeVar74 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar74 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar71 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar71 );
		p0_nodeVar75 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 0.0, 3.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar76 = p0_nodeVar75.x;
		p0_nodeVar77 = ( p0_nodeVar76 * p0_nodeVar76 );
		p0_nodeVar78 = ( vec2<f32>( 0.125, 0.875 ) - p0_nodeVar9 );
		p0_nodeVar79 = ( ( p0_nodeVar77 * p0_nodeVar77 ) * exp( ( dot( p0_nodeVar78, p0_nodeVar78 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.125, 0.875 ) * vec2<f32>( p0_nodeVar79 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar79 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar76 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar76 );
		p0_nodeVar80 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 1.0, 3.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar81 = p0_nodeVar80.x;
		p0_nodeVar82 = ( p0_nodeVar81 * p0_nodeVar81 );
		p0_nodeVar83 = ( vec2<f32>( 0.375, 0.875 ) - p0_nodeVar9 );
		p0_nodeVar84 = ( ( p0_nodeVar82 * p0_nodeVar82 ) * exp( ( dot( p0_nodeVar83, p0_nodeVar83 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.375, 0.875 ) * vec2<f32>( p0_nodeVar84 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar84 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar81 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar81 );
		p0_nodeVar85 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 2.0, 3.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar86 = p0_nodeVar85.x;
		p0_nodeVar87 = ( p0_nodeVar86 * p0_nodeVar86 );
		p0_nodeVar88 = ( vec2<f32>( 0.625, 0.875 ) - p0_nodeVar9 );
		p0_nodeVar89 = ( ( p0_nodeVar87 * p0_nodeVar87 ) * exp( ( dot( p0_nodeVar88, p0_nodeVar88 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.625, 0.875 ) * vec2<f32>( p0_nodeVar89 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar89 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar86 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar86 );
		p0_nodeVar90 = none_load( vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p0_nodeVar10 + vec2<f32>( 3.0, 3.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p0_nodeVar91 = p0_nodeVar90.x;
		p0_nodeVar92 = ( p0_nodeVar91 * p0_nodeVar91 );
		p0_nodeVar93 = ( vec2<f32>( 0.875, 0.875 ) - p0_nodeVar9 );
		p0_nodeVar94 = ( ( p0_nodeVar92 * p0_nodeVar92 ) * exp( ( dot( p0_nodeVar93, p0_nodeVar93 ) * -5.0 ) ) );
		p0_nodeVar11 = ( p0_nodeVar11 + ( vec2<f32>( 0.875, 0.875 ) * vec2<f32>( p0_nodeVar94 ) ) );
		p0_nodeVar12 = ( p0_nodeVar12 + p0_nodeVar94 );
		p0_nodeVar13 = ( p0_nodeVar13 + p0_nodeVar91 );
		p0_nodeVar14 = max( p0_nodeVar14, p0_nodeVar91 );

		if ( ( f32(knobs.mode) > 2.5 ) ) {

			p0_nodeVar95 = mix( p0_nodeVar8, ( ( p0_nodeVar1 + ( p0_nodeVar11 / vec2<f32>( max( p0_nodeVar12, 1e-10 ) ) ) ) * vec2<f32>( f32(knobs.spacing) ) ), ( f32(0.0) * smoothstep( 0.0, 0.15, ( p0_nodeVar14 - ( p0_nodeVar13 / 16.0 ) ) ) ) );

		} else {

			p0_nodeVar95 = ( mix( p0_nodeVar8, ( ( p0_nodeVar1 + ( p0_nodeVar11 / vec2<f32>( max( p0_nodeVar12, 1e-10 ) ) ) ) * vec2<f32>( f32(knobs.spacing) ) ), ( f32(0.0) * smoothstep( 0.0, 0.15, ( p0_nodeVar14 - ( p0_nodeVar13 / 16.0 ) ) ) ) ) / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) );

		}


		if ( ( f32(knobs.invert) > 0.5 ) ) {

			p0_nodeVar98 = picture_read_level( ( mix( p0_nodeVar8, ( ( p0_nodeVar1 + ( p0_nodeVar11 / vec2<f32>( max( p0_nodeVar12, 1e-10 ) ) ) ) * vec2<f32>( f32(knobs.spacing) ) ), ( f32(0.0) * smoothstep( 0.0, 0.15, ( p0_nodeVar14 - ( p0_nodeVar13 / 16.0 ) ) ) ) ) / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );
			p0_nodeVar99 = clamp( dot( vec3<f32>( p0_nodeVar98.x, p0_nodeVar98.y, p0_nodeVar98.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar99 <= 0.0031308 ) ) {

				p0_nodeVar97 = ( p0_nodeVar99 * 12.92 );

			} else {

				p0_nodeVar97 = ( ( pow( p0_nodeVar99, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar96 = p0_nodeVar97;

		} else {

			p0_nodeVar101 = picture_read_level( ( mix( p0_nodeVar8, ( ( p0_nodeVar1 + ( p0_nodeVar11 / vec2<f32>( max( p0_nodeVar12, 1e-10 ) ) ) ) * vec2<f32>( f32(knobs.spacing) ) ), ( f32(0.0) * smoothstep( 0.0, 0.15, ( p0_nodeVar14 - ( p0_nodeVar13 / 16.0 ) ) ) ) ) / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );
			p0_nodeVar102 = clamp( dot( vec3<f32>( p0_nodeVar101.x, p0_nodeVar101.y, p0_nodeVar101.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar102 <= 0.0031308 ) ) {

				p0_nodeVar100 = ( p0_nodeVar102 * 12.92 );

			} else {

				p0_nodeVar100 = ( ( pow( p0_nodeVar102, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar96 = ( 1.0 - p0_nodeVar100 );

		}


		if ( ( p0_nodeVar96 >= f32(knobs.cutoff) ) ) {

			p0_nodeVar103 = 1.0;

		} else {

			p0_nodeVar103 = 0.0;

		}

		p0_nodeVar105 = picture_read_level( ( mix( p0_nodeVar8, ( ( p0_nodeVar1 + ( p0_nodeVar11 / vec2<f32>( max( p0_nodeVar12, 1e-10 ) ) ) ) * vec2<f32>( f32(knobs.spacing) ) ), ( f32(0.0) * smoothstep( 0.0, 0.15, ( p0_nodeVar14 - ( p0_nodeVar13 / 16.0 ) ) ) ) ) / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );

		if ( ( p0_nodeVar105.w > 0.5 ) ) {

			p0_nodeVar104 = 1.0;

		} else {

			p0_nodeVar104 = 0.0;

		}

		p0_nodeVar0 = vec4<f32>( p0_nodeVar95, p0_nodeVar96, ( p0_nodeVar103 * p0_nodeVar104 ) );
		

	} else {


		if ( ( f32(knobs.mode) > 2.5 ) ) {

			p0_nodeVar106 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 2.0 ) );
			p0_nodeVar107 = ( p0_nodeVar106 + vec2<f32>( ( f32(knobs.seed) * 13.1 ) ) );
			p0_nodeVar108 = fract( ( sin( vec2<f32>( dot( p0_nodeVar107, vec2<f32>( 127.1, 311.7 ) ), dot( p0_nodeVar107, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) );
			p0_nodeVar109 = vec2<f32>( 0.0, 0.0 );

			if ( ( f32(knobs.drift) > 0.0 ) ) {


				if ( ( f32(knobs.mode) > 2.5 ) ) {

					p0_nodeVar111 = ( p0_nodeVar108 * vec2<f32>( 6.2831853 ) );
					p0_nodeVar110 = ( ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar111.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar111.y ) ) ) * ( vec2<f32>( 0.5, 0.5 ) - abs( ( ( p0_nodeVar108 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) ) ) ) * vec2<f32>( f32(knobs.drift) ) );

				} else {

					p0_nodeVar112 = ( p0_nodeVar108 * vec2<f32>( 6.2831853 ) );
					p0_nodeVar110 = ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar112.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar112.y ) ) ) * vec2<f32>( ( f32(knobs.drift) * 0.35 ) ) );

				}

				p0_nodeVar109 = p0_nodeVar110;
				

			}

			p0_nodeVar113 = ( ( p0_nodeVar106 + ( ( ( ( p0_nodeVar108 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) + vec2<f32>( 0.5 ) ) + p0_nodeVar109 ) ) * vec2<f32>( f32(knobs.spacing) ) );

			if ( ( f32(knobs.invert) > 0.5 ) ) {

				p0_nodeVar116 = picture_read_level( ( p0_nodeVar113 / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );
				p0_nodeVar117 = clamp( dot( vec3<f32>( p0_nodeVar116.x, p0_nodeVar116.y, p0_nodeVar116.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar117 <= 0.0031308 ) ) {

					p0_nodeVar115 = ( p0_nodeVar117 * 12.92 );

				} else {

					p0_nodeVar115 = ( ( pow( p0_nodeVar117, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar114 = p0_nodeVar115;

			} else {

				p0_nodeVar119 = picture_read_level( ( p0_nodeVar113 / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );
				p0_nodeVar120 = clamp( dot( vec3<f32>( p0_nodeVar119.x, p0_nodeVar119.y, p0_nodeVar119.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar120 <= 0.0031308 ) ) {

					p0_nodeVar118 = ( p0_nodeVar120 * 12.92 );

				} else {

					p0_nodeVar118 = ( ( pow( p0_nodeVar120, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar114 = ( 1.0 - p0_nodeVar118 );

			}


			if ( ( p0_nodeVar114 >= f32(knobs.cutoff) ) ) {

				p0_nodeVar121 = 1.0;

			} else {

				p0_nodeVar121 = 0.0;

			}

			p0_nodeVar123 = picture_read_level( ( p0_nodeVar113 / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) ), 0.0 );

			if ( ( p0_nodeVar123.w > 0.5 ) ) {

				p0_nodeVar122 = 1.0;

			} else {

				p0_nodeVar122 = 0.0;

			}

			p0_nodeVar0 = vec4<f32>( p0_nodeVar113, p0_nodeVar114, ( p0_nodeVar121 * p0_nodeVar122 ) );
			

		} else {

			p0_nodeVar124 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 2.0 ) );
			p0_nodeVar125 = ( p0_nodeVar124 + vec2<f32>( ( f32(knobs.seed) * 13.1 ) ) );
			p0_nodeVar126 = fract( ( sin( vec2<f32>( dot( p0_nodeVar125, vec2<f32>( 127.1, 311.7 ) ), dot( p0_nodeVar125, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) );
			p0_nodeVar127 = vec2<f32>( 0.0, 0.0 );

			if ( ( f32(knobs.drift) > 0.0 ) ) {


				if ( ( f32(knobs.mode) > 2.5 ) ) {

					p0_nodeVar129 = ( p0_nodeVar126 * vec2<f32>( 6.2831853 ) );
					p0_nodeVar128 = ( ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar129.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar129.y ) ) ) * ( vec2<f32>( 0.5, 0.5 ) - abs( ( ( p0_nodeVar126 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) ) ) ) * vec2<f32>( f32(knobs.drift) ) );

				} else {

					p0_nodeVar130 = ( p0_nodeVar126 * vec2<f32>( 6.2831853 ) );
					p0_nodeVar128 = ( vec2<f32>( sin( ( f32((0.5 * knobs.time + 0)) + p0_nodeVar130.x ) ), cos( ( ( f32((0.5 * knobs.time + 0)) * 0.8 ) + p0_nodeVar130.y ) ) ) * vec2<f32>( ( f32(knobs.drift) * 0.35 ) ) );

				}

				p0_nodeVar127 = p0_nodeVar128;
				

			}

			p0_nodeVar131 = ( ( ( p0_nodeVar124 + ( ( ( ( p0_nodeVar126 - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.jitter) ) ) + vec2<f32>( 0.5 ) ) + p0_nodeVar127 ) ) * vec2<f32>( f32(knobs.spacing) ) ) / vec2<f32>((knobs.resolution.x / 0.36953125000000003), (knobs.resolution.y / 0.37812500000000004)) );

			if ( ( f32(knobs.invert) > 0.5 ) ) {

				p0_nodeVar134 = picture_read_level( p0_nodeVar131, 0.0 );
				p0_nodeVar135 = clamp( dot( vec3<f32>( p0_nodeVar134.x, p0_nodeVar134.y, p0_nodeVar134.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar135 <= 0.0031308 ) ) {

					p0_nodeVar133 = ( p0_nodeVar135 * 12.92 );

				} else {

					p0_nodeVar133 = ( ( pow( p0_nodeVar135, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar132 = p0_nodeVar133;

			} else {

				p0_nodeVar137 = picture_read_level( p0_nodeVar131, 0.0 );
				p0_nodeVar138 = clamp( dot( vec3<f32>( p0_nodeVar137.x, p0_nodeVar137.y, p0_nodeVar137.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar138 <= 0.0031308 ) ) {

					p0_nodeVar136 = ( p0_nodeVar138 * 12.92 );

				} else {

					p0_nodeVar136 = ( ( pow( p0_nodeVar138, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar132 = ( 1.0 - p0_nodeVar136 );

			}


			if ( ( p0_nodeVar132 >= f32(knobs.cutoff) ) ) {

				p0_nodeVar139 = 1.0;

			} else {

				p0_nodeVar139 = 0.0;

			}

			p0_nodeVar141 = picture_read_level( p0_nodeVar131, 0.0 );

			if ( ( p0_nodeVar141.w > 0.5 ) ) {

				p0_nodeVar140 = 1.0;

			} else {

				p0_nodeVar140 = 0.0;

			}

			p0_nodeVar0 = vec4<f32>( p0_nodeVar131, p0_nodeVar132, ( p0_nodeVar139 * p0_nodeVar140 ) );
			

		}

		

	}


	// result

	p0_output.color = p0_nodeVar0;

	return p0_output;

}

// structs

struct p1_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p1_output : p1_OutputStruct;

// uniforms


// vars
var<private> p1_DiffuseColor : vec4<f32>;
var<private> p1_nodeVar0 : vec4<f32>;
var<private> p1_nodeVar1 : vec2<f32>;
var<private> p1_nodeVar2 : vec2<f32>;
var<private> p1_nodeVar3 : vec2<f32>;
var<private> p1_nodeVar4 : bool;
var<private> p1_nodeVar5 : bool;
var<private> p1_nodeVar6 : bool;
var<private> p1_nodeVar7 : f32;
var<private> p1_nodeVar8 : f32;
var<private> p1_nodeVar9 : f32;
var<private> p1_nodeVar10 : f32;
var<private> p1_nodeVar11 : f32;
var<private> p1_nodeVar12 : f32;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : vec3<f32>;
var<private> p1_nodeVar15 : f32;
var<private> p1_nodeVar16 : f32;
var<private> p1_nodeVar17 : vec3<f32>;
var<private> p1_nodeVar18 : f32;
var<private> p1_nodeVar19 : vec3<f32>;
var<private> p1_nodeVar20 : f32;
var<private> p1_nodeVar21 : f32;
var<private> p1_nodeVar22 : vec2<f32>;
var<private> p1_nodeVar23 : vec4<f32>;
var<private> p1_nodeVar24 : vec4<f32>;
var<private> p1_nodeVar25 : vec2<f32>;
var<private> p1_nodeVar26 : vec3<f32>;
var<private> p1_nodeVar27 : vec4<f32>;
var<private> p1_nodeVar28 : vec2<f32>;
var<private> p1_nodeVar29 : f32;
var<private> p1_nodeVar30 : f32;
var<private> p1_nodeVar31 : f32;
var<private> p1_nodeVar32 : f32;
var<private> p1_nodeVar33 : f32;
var<private> p1_nodeVar34 : f32;
var<private> p1_nodeVar35 : f32;
var<private> p1_nodeVar36 : f32;
var<private> p1_nodeVar37 : vec4<f32>;
var<private> p1_nodeVar38 : vec4<f32>;
var<private> p1_nodeVar39 : f32;
var<private> p1_nodeVar40 : vec2<f32>;
var<private> p1_nodeVar41 : f32;
var<private> p1_nodeVar42 : f32;
var<private> p1_nodeVar43 : f32;
var<private> p1_nodeVar44 : bool;
var<private> p1_nodeVar45 : f32;
var<private> p1_nodeVar46 : vec3<f32>;
var<private> p1_nodeVar47 : vec4<f32>;
var<private> p1_nodeVar48 : f32;
var<private> p1_nodeVar49 : f32;
var<private> p1_nodeVar50 : vec2<f32>;
var<private> p1_nodeVar51 : f32;
var<private> p1_nodeVar52 : f32;
var<private> p1_nodeVar53 : f32;
var<private> p1_nodeVar54 : f32;
var<private> p1_nodeVar55 : f32;
var<private> p1_nodeVar56 : f32;
var<private> p1_nodeVar57 : vec4<f32>;
var<private> p1_nodeVar58 : f32;
var<private> p1_nodeVar59 : vec4<f32>;
var<private> p1_nodeVar60 : vec4<f32>;
var<private> p1_nodeVar61 : f32;
var<private> p1_nodeVar62 : vec2<f32>;
var<private> p1_nodeVar63 : f32;
var<private> p1_nodeVar64 : f32;
var<private> p1_nodeVar65 : f32;
var<private> p1_nodeVar66 : bool;
var<private> p1_nodeVar67 : f32;
var<private> p1_nodeVar68 : vec3<f32>;
var<private> p1_nodeVar69 : vec4<f32>;
var<private> p1_nodeVar70 : f32;
var<private> p1_nodeVar71 : f32;
var<private> p1_nodeVar72 : vec2<f32>;
var<private> p1_nodeVar73 : f32;
var<private> p1_nodeVar74 : f32;
var<private> p1_nodeVar75 : f32;
var<private> p1_nodeVar76 : f32;
var<private> p1_nodeVar77 : f32;
var<private> p1_nodeVar78 : f32;
var<private> p1_nodeVar79 : vec4<f32>;
var<private> p1_nodeVar80 : f32;
var<private> p1_nodeVar81 : vec4<f32>;
var<private> p1_nodeVar82 : vec4<f32>;
var<private> p1_nodeVar83 : f32;
var<private> p1_nodeVar84 : vec2<f32>;
var<private> p1_nodeVar85 : f32;
var<private> p1_nodeVar86 : f32;
var<private> p1_nodeVar87 : f32;
var<private> p1_nodeVar88 : bool;
var<private> p1_nodeVar89 : f32;
var<private> p1_nodeVar90 : vec3<f32>;
var<private> p1_nodeVar91 : vec4<f32>;
var<private> p1_nodeVar92 : f32;
var<private> p1_nodeVar93 : f32;
var<private> p1_nodeVar94 : vec2<f32>;
var<private> p1_nodeVar95 : f32;
var<private> p1_nodeVar96 : f32;
var<private> p1_nodeVar97 : f32;
var<private> p1_nodeVar98 : f32;
var<private> p1_nodeVar99 : f32;
var<private> p1_nodeVar100 : f32;
var<private> p1_nodeVar101 : vec4<f32>;
var<private> p1_nodeVar102 : f32;
var<private> p1_nodeVar103 : vec4<f32>;
var<private> p1_nodeVar104 : vec4<f32>;
var<private> p1_nodeVar105 : f32;
var<private> p1_nodeVar106 : vec2<f32>;
var<private> p1_nodeVar107 : f32;
var<private> p1_nodeVar108 : f32;
var<private> p1_nodeVar109 : f32;
var<private> p1_nodeVar110 : bool;
var<private> p1_nodeVar111 : f32;
var<private> p1_nodeVar112 : vec3<f32>;
var<private> p1_nodeVar113 : vec4<f32>;
var<private> p1_nodeVar114 : f32;
var<private> p1_nodeVar115 : f32;
var<private> p1_nodeVar116 : vec2<f32>;
var<private> p1_nodeVar117 : f32;
var<private> p1_nodeVar118 : f32;
var<private> p1_nodeVar119 : f32;
var<private> p1_nodeVar120 : f32;
var<private> p1_nodeVar121 : f32;
var<private> p1_nodeVar122 : f32;
var<private> p1_nodeVar123 : vec4<f32>;
var<private> p1_nodeVar124 : f32;
var<private> p1_nodeVar125 : vec4<f32>;
var<private> p1_nodeVar126 : vec4<f32>;
var<private> p1_nodeVar127 : f32;
var<private> p1_nodeVar128 : vec2<f32>;
var<private> p1_nodeVar129 : f32;
var<private> p1_nodeVar130 : f32;
var<private> p1_nodeVar131 : f32;
var<private> p1_nodeVar132 : bool;
var<private> p1_nodeVar133 : f32;
var<private> p1_nodeVar134 : vec3<f32>;
var<private> p1_nodeVar135 : vec4<f32>;
var<private> p1_nodeVar136 : f32;
var<private> p1_nodeVar137 : f32;
var<private> p1_nodeVar138 : vec2<f32>;
var<private> p1_nodeVar139 : f32;
var<private> p1_nodeVar140 : f32;
var<private> p1_nodeVar141 : f32;
var<private> p1_nodeVar142 : f32;
var<private> p1_nodeVar143 : f32;
var<private> p1_nodeVar144 : f32;
var<private> p1_nodeVar145 : vec4<f32>;
var<private> p1_nodeVar146 : f32;
var<private> p1_nodeVar147 : vec4<f32>;
var<private> p1_nodeVar148 : vec4<f32>;
var<private> p1_nodeVar149 : f32;
var<private> p1_nodeVar150 : vec2<f32>;
var<private> p1_nodeVar151 : f32;
var<private> p1_nodeVar152 : f32;
var<private> p1_nodeVar153 : f32;
var<private> p1_nodeVar154 : bool;
var<private> p1_nodeVar155 : f32;
var<private> p1_nodeVar156 : vec3<f32>;
var<private> p1_nodeVar157 : vec4<f32>;
var<private> p1_nodeVar158 : f32;
var<private> p1_nodeVar159 : f32;
var<private> p1_nodeVar160 : vec2<f32>;
var<private> p1_nodeVar161 : f32;
var<private> p1_nodeVar162 : f32;
var<private> p1_nodeVar163 : f32;
var<private> p1_nodeVar164 : f32;
var<private> p1_nodeVar165 : f32;
var<private> p1_nodeVar166 : f32;
var<private> p1_nodeVar167 : vec4<f32>;
var<private> p1_nodeVar168 : f32;
var<private> p1_nodeVar169 : vec4<f32>;
var<private> p1_nodeVar170 : vec4<f32>;
var<private> p1_nodeVar171 : f32;
var<private> p1_nodeVar172 : vec2<f32>;
var<private> p1_nodeVar173 : f32;
var<private> p1_nodeVar174 : f32;
var<private> p1_nodeVar175 : f32;
var<private> p1_nodeVar176 : bool;
var<private> p1_nodeVar177 : f32;
var<private> p1_nodeVar178 : vec3<f32>;
var<private> p1_nodeVar179 : vec4<f32>;
var<private> p1_nodeVar180 : f32;
var<private> p1_nodeVar181 : f32;
var<private> p1_nodeVar182 : vec2<f32>;
var<private> p1_nodeVar183 : f32;
var<private> p1_nodeVar184 : f32;
var<private> p1_nodeVar185 : f32;
var<private> p1_nodeVar186 : f32;
var<private> p1_nodeVar187 : f32;
var<private> p1_nodeVar188 : f32;
var<private> p1_nodeVar189 : vec4<f32>;
var<private> p1_nodeVar190 : f32;
var<private> p1_nodeVar191 : vec4<f32>;
var<private> p1_nodeVar192 : vec4<f32>;
var<private> p1_nodeVar193 : f32;
var<private> p1_nodeVar194 : vec2<f32>;
var<private> p1_nodeVar195 : f32;
var<private> p1_nodeVar196 : f32;
var<private> p1_nodeVar197 : f32;
var<private> p1_nodeVar198 : bool;
var<private> p1_nodeVar199 : f32;
var<private> p1_nodeVar200 : vec3<f32>;
var<private> p1_nodeVar201 : vec4<f32>;
var<private> p1_nodeVar202 : f32;
var<private> p1_nodeVar203 : f32;
var<private> p1_nodeVar204 : vec2<f32>;
var<private> p1_nodeVar205 : f32;
var<private> p1_nodeVar206 : f32;
var<private> p1_nodeVar207 : f32;
var<private> p1_nodeVar208 : f32;
var<private> p1_nodeVar209 : f32;
var<private> p1_nodeVar210 : f32;
var<private> p1_nodeVar211 : vec4<f32>;
var<private> p1_nodeVar212 : f32;
var<private> p1_nodeVar213 : vec3<f32>;
var<private> p1_nodeVar214 : f32;
var<private> p1_nodeVar215 : vec4<f32>;
var<private> p1_nodeVar216 : f32;
var<private> p1_nodeVar217 : vec3<f32>;
var<private> p1_nodeVar218 : f32;
var<private> p1_nodeVar219 : vec3<f32>;
var<private> p1_nodeVar220 : vec3<f32>;
var<private> p1_nodeVar221 : vec4<f32>;
var<private> p1_nodeVar222 : vec3<f32>;
var<private> p1_nodeVar223 : vec3<f32>;
var<private> p1_nodeVar224 : vec4<f32>;
var<private> p1_nodeVar225 : vec3<f32>;
var<private> p1_nodeVar226 : f32;
var<private> p1_nodeVar227 : vec4<f32>;
var<private> p1_nodeVar228 : vec3<f32>;
var<private> p1_nodeVar229 : f32;
var<private> p1_nodeVar230 : vec3<f32>;
var<private> p1_nodeVar231 : vec4<f32>;
var<private> p1_nodeVar232 : f32;
var<private> p1_nodeVar233 : f32;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar234 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p1_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar2 = ( p1_nodeVar1 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p1_nodeVar3 = floor( ( p1_nodeVar2 / vec2<f32>( f32(knobs.spacing) ) ) );
	p1_nodeVar4 = ( ( f32(knobs.mode) > 0.5 ) && ( f32(knobs.mode) < 1.5 ) );
	p1_nodeVar5 = ( f32(knobs.mode) > 1.5 );
	p1_nodeVar6 = ( ( f32(knobs.colorMode) >= 0.5 ) && ( f32(knobs.colorMode) < 1.5 ) );

	if ( p1_nodeVar4 ) {

		p1_nodeVar7 = ( ( ( f32(knobs.blobiness) * f32(knobs.spacing) ) * 0.6 ) + 0.001 );

	} else {

		p1_nodeVar7 = 0.001;

	}

	p1_nodeVar8 = p1_nodeVar7;

	if ( p1_nodeVar4 ) {

		p1_nodeVar9 = p1_nodeVar8;

	} else {

		p1_nodeVar9 = 0.6;

	}

	p1_nodeVar10 = p1_nodeVar9;
	p1_nodeVar11 = 100000.0;
	p1_nodeVar12 = 0.0;
	p1_nodeVar13 = 0.0;
	p1_nodeVar14 = vec3<f32>( 0.0, 0.0, 0.0 );
	p1_nodeVar15 = 0.0;
	p1_nodeVar16 = 0.0;
	p1_nodeVar17 = vec3<f32>( 0.0, 0.0, 0.0 );
	p1_nodeVar18 = 0.0;
	p1_nodeVar19 = vec3<f32>( 0.0, 0.0, 0.0 );
	p1_nodeVar20 = 100000.0;
	p1_nodeVar21 = 0.0;

	for ( var centerIndex : i32 = 0; centerIndex < 9; centerIndex ++ ) {

		p1_nodeVar22 = ( p1_nodeVar3 + vec2<f32>( ( f32( ( centerIndex % 3 ) ) - 1.0 ), ( f32( ( centerIndex / 3 ) ) - 1.0 ) ) );
		p1_nodeVar23 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p1_nodeVar22 + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar24 = p1_nodeVar23;
		p1_nodeVar25 = ( p1_nodeVar24.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p1_nodeVar26 = vec3<f32>( 0.0, 0.0, 0.0 );

		if ( p1_nodeVar6 ) {

			p1_nodeVar27 = picture_read_level( p1_nodeVar24.xy, 0.0 );
			p1_nodeVar26 = vec3<f32>( p1_nodeVar27.x, p1_nodeVar27.y, p1_nodeVar27.z );
			

		}


		if ( ( p1_nodeVar24.w > 0.5 ) ) {

			p1_nodeVar28 = ( p1_nodeVar2 - p1_nodeVar25 );

			if ( p1_nodeVar5 ) {

				p1_nodeVar29 = ( ( ( mix( f32(knobs.minSize), f32(knobs.maxSize), p1_nodeVar24.z ) * f32(knobs.spacing) ) * 0.5 ) * 0.5 );

			} else {

				p1_nodeVar29 = ( ( mix( f32(knobs.minSize), f32(knobs.maxSize), p1_nodeVar24.z ) * f32(knobs.spacing) ) * 0.5 );

			}

			p1_nodeVar30 = p1_nodeVar29;
			p1_nodeVar31 = 0.0;

			if ( ( f32(knobs.dotShape) < 0.5 ) ) {

				p1_nodeVar31 = ( length( p1_nodeVar28 ) - p1_nodeVar30 );
				

			} else {


				if ( ( f32(knobs.dotShape) < 1.5 ) ) {

					p1_nodeVar31 = ( max( abs( p1_nodeVar28.x ), abs( p1_nodeVar28.y ) ) - p1_nodeVar30 );
					

				} else {


					if ( ( f32(knobs.dotShape) < 2.5 ) ) {

						p1_nodeVar32 = ( p1_nodeVar30 * 0.32 );
						p1_nodeVar31 = min( max( ( abs( p1_nodeVar28.x ) - p1_nodeVar30 ), ( abs( p1_nodeVar28.y ) - p1_nodeVar32 ) ), max( ( abs( p1_nodeVar28.y ) - p1_nodeVar30 ), ( abs( p1_nodeVar28.x ) - p1_nodeVar32 ) ) );
						

					} else {

						p1_nodeVar31 = ( abs( ( length( p1_nodeVar28 ) - ( p1_nodeVar30 * 0.72 ) ) ) - ( p1_nodeVar30 * 0.28 ) );
						

					}

					

				}

				

			}

			p1_nodeVar33 = p1_nodeVar31;

			if ( p1_nodeVar4 ) {

				p1_nodeVar34 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar33 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
				p1_nodeVar11 = ( mix( p1_nodeVar33, p1_nodeVar11, p1_nodeVar34 ) - ( ( p1_nodeVar8 * p1_nodeVar34 ) * ( 1.0 - p1_nodeVar34 ) ) );
				

			} else {

				p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar33 );
				

			}

			p1_nodeVar35 = exp( ( ( - max( p1_nodeVar33, 0.0 ) ) / p1_nodeVar10 ) );
			p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar35 );
			p1_nodeVar13 = ( p1_nodeVar13 + ( p1_nodeVar24.z * p1_nodeVar35 ) );

			if ( p1_nodeVar6 ) {

				p1_nodeVar14 = ( p1_nodeVar14 + ( p1_nodeVar26 * vec3<f32>( p1_nodeVar35 ) ) );
				

			}

			

		} else {


			if ( p1_nodeVar4 ) {


				if ( p1_nodeVar4 ) {

					p1_nodeVar36 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar36 ) - ( ( p1_nodeVar8 * p1_nodeVar36 ) * ( 1.0 - p1_nodeVar36 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
					

				}

				

			}

			

		}

		p1_nodeVar37 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( 1.0, 0.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar38 = p1_nodeVar37;
		p1_nodeVar39 = ( p1_nodeVar24.w * p1_nodeVar38.w );
		p1_nodeVar40 = ( ( p1_nodeVar38.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar41 = ( clamp( ( 1.0 - ( length( p1_nodeVar40 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar39 );

			if ( ( p1_nodeVar41 > 0.0 ) ) {

				p1_nodeVar42 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar40 ) / max( dot( p1_nodeVar40, p1_nodeVar40 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar43 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar40 * vec2<f32>( p1_nodeVar42 ) ) ) ) ) ) * p1_nodeVar41 );
				p1_nodeVar44 = ( p1_nodeVar43 > p1_nodeVar15 );

				if ( p1_nodeVar44 ) {

					p1_nodeVar45 = mix( p1_nodeVar24.z, p1_nodeVar38.z, p1_nodeVar42 );

				} else {

					p1_nodeVar45 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar45;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar44 ) {

						p1_nodeVar47 = picture_read_level( p1_nodeVar38.xy, 0.0 );
						p1_nodeVar46 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar47.x, p1_nodeVar47.y, p1_nodeVar47.z ), p1_nodeVar42 );

					} else {

						p1_nodeVar46 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar46;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar43 );
				

			}

			

		} else {

			p1_nodeVar48 = ( ( p1_nodeVar24.z + p1_nodeVar38.z ) * 0.5 );
			p1_nodeVar50 = ( ( ( ( p1_nodeVar22 + vec2<f32>( 0.0, 0.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 1.0, 0.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar50, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar50, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar48 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar49 = 1.0;

			} else {

				p1_nodeVar49 = 0.0;

			}

			p1_nodeVar51 = ( p1_nodeVar49 * p1_nodeVar39 );
			p1_nodeVar52 = 0.0;

			if ( ( p1_nodeVar51 > 0.5 ) ) {

				p1_nodeVar53 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar40 ) / max( dot( p1_nodeVar40, p1_nodeVar40 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar52 = p1_nodeVar53;
				p1_nodeVar54 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar40 * vec2<f32>( p1_nodeVar52 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar48, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar55 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar54 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar54, p1_nodeVar11, p1_nodeVar55 ) - ( ( p1_nodeVar8 * p1_nodeVar55 ) * ( 1.0 - p1_nodeVar55 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar54 );
					

				}

				p1_nodeVar56 = exp( ( ( - max( p1_nodeVar54, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar56 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar38.z, p1_nodeVar52 ) * p1_nodeVar56 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar57 = picture_read_level( p1_nodeVar38.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar57.x, p1_nodeVar57.y, p1_nodeVar57.z ), p1_nodeVar52 ) * vec3<f32>( p1_nodeVar56 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar58 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar58 ) - ( ( p1_nodeVar8 * p1_nodeVar58 ) * ( 1.0 - p1_nodeVar58 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar59 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( 1.0, 1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar60 = p1_nodeVar59;
		p1_nodeVar61 = ( p1_nodeVar24.w * p1_nodeVar60.w );
		p1_nodeVar62 = ( ( p1_nodeVar60.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar63 = ( clamp( ( 1.0 - ( length( p1_nodeVar62 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar61 );

			if ( ( p1_nodeVar63 > 0.0 ) ) {

				p1_nodeVar64 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar62 ) / max( dot( p1_nodeVar62, p1_nodeVar62 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar65 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar62 * vec2<f32>( p1_nodeVar64 ) ) ) ) ) ) * p1_nodeVar63 );
				p1_nodeVar66 = ( p1_nodeVar65 > p1_nodeVar15 );

				if ( p1_nodeVar66 ) {

					p1_nodeVar67 = mix( p1_nodeVar24.z, p1_nodeVar60.z, p1_nodeVar64 );

				} else {

					p1_nodeVar67 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar67;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar66 ) {

						p1_nodeVar69 = picture_read_level( p1_nodeVar60.xy, 0.0 );
						p1_nodeVar68 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar69.x, p1_nodeVar69.y, p1_nodeVar69.z ), p1_nodeVar64 );

					} else {

						p1_nodeVar68 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar68;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar65 );
				

			}

			

		} else {

			p1_nodeVar70 = ( ( p1_nodeVar24.z + p1_nodeVar60.z ) * 0.5 );
			p1_nodeVar72 = ( ( ( ( p1_nodeVar22 + vec2<f32>( 0.0, 0.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 1.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar72, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar72, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar70 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar71 = 1.0;

			} else {

				p1_nodeVar71 = 0.0;

			}

			p1_nodeVar73 = ( p1_nodeVar71 * p1_nodeVar61 );
			p1_nodeVar74 = 0.0;

			if ( ( p1_nodeVar73 > 0.5 ) ) {

				p1_nodeVar75 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar62 ) / max( dot( p1_nodeVar62, p1_nodeVar62 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar74 = p1_nodeVar75;
				p1_nodeVar76 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar62 * vec2<f32>( p1_nodeVar74 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar70, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar77 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar76 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar76, p1_nodeVar11, p1_nodeVar77 ) - ( ( p1_nodeVar8 * p1_nodeVar77 ) * ( 1.0 - p1_nodeVar77 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar76 );
					

				}

				p1_nodeVar78 = exp( ( ( - max( p1_nodeVar76, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar78 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar60.z, p1_nodeVar74 ) * p1_nodeVar78 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar79 = picture_read_level( p1_nodeVar60.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar79.x, p1_nodeVar79.y, p1_nodeVar79.z ), p1_nodeVar74 ) * vec3<f32>( p1_nodeVar78 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar80 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar80 ) - ( ( p1_nodeVar8 * p1_nodeVar80 ) * ( 1.0 - p1_nodeVar80 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar81 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( 0.0, 1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar82 = p1_nodeVar81;
		p1_nodeVar83 = ( p1_nodeVar24.w * p1_nodeVar82.w );
		p1_nodeVar84 = ( ( p1_nodeVar82.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar85 = ( clamp( ( 1.0 - ( length( p1_nodeVar84 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar83 );

			if ( ( p1_nodeVar85 > 0.0 ) ) {

				p1_nodeVar86 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar84 ) / max( dot( p1_nodeVar84, p1_nodeVar84 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar87 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar84 * vec2<f32>( p1_nodeVar86 ) ) ) ) ) ) * p1_nodeVar85 );
				p1_nodeVar88 = ( p1_nodeVar87 > p1_nodeVar15 );

				if ( p1_nodeVar88 ) {

					p1_nodeVar89 = mix( p1_nodeVar24.z, p1_nodeVar82.z, p1_nodeVar86 );

				} else {

					p1_nodeVar89 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar89;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar88 ) {

						p1_nodeVar91 = picture_read_level( p1_nodeVar82.xy, 0.0 );
						p1_nodeVar90 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar91.x, p1_nodeVar91.y, p1_nodeVar91.z ), p1_nodeVar86 );

					} else {

						p1_nodeVar90 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar90;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar87 );
				

			}

			

		} else {

			p1_nodeVar92 = ( ( p1_nodeVar24.z + p1_nodeVar82.z ) * 0.5 );
			p1_nodeVar94 = ( ( ( ( p1_nodeVar22 + vec2<f32>( 0.0, 0.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 0.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar94, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar94, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar92 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar93 = 1.0;

			} else {

				p1_nodeVar93 = 0.0;

			}

			p1_nodeVar95 = ( p1_nodeVar93 * p1_nodeVar83 );
			p1_nodeVar96 = 0.0;

			if ( ( p1_nodeVar95 > 0.5 ) ) {

				p1_nodeVar97 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar84 ) / max( dot( p1_nodeVar84, p1_nodeVar84 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar96 = p1_nodeVar97;
				p1_nodeVar98 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar84 * vec2<f32>( p1_nodeVar96 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar92, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar99 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar98 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar98, p1_nodeVar11, p1_nodeVar99 ) - ( ( p1_nodeVar8 * p1_nodeVar99 ) * ( 1.0 - p1_nodeVar99 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar98 );
					

				}

				p1_nodeVar100 = exp( ( ( - max( p1_nodeVar98, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar100 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar82.z, p1_nodeVar96 ) * p1_nodeVar100 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar101 = picture_read_level( p1_nodeVar82.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar101.x, p1_nodeVar101.y, p1_nodeVar101.z ), p1_nodeVar96 ) * vec3<f32>( p1_nodeVar100 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar102 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar102 ) - ( ( p1_nodeVar8 * p1_nodeVar102 ) * ( 1.0 - p1_nodeVar102 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar103 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( -1.0, 1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar104 = p1_nodeVar103;
		p1_nodeVar105 = ( p1_nodeVar24.w * p1_nodeVar104.w );
		p1_nodeVar106 = ( ( p1_nodeVar104.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar107 = ( clamp( ( 1.0 - ( length( p1_nodeVar106 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar105 );

			if ( ( p1_nodeVar107 > 0.0 ) ) {

				p1_nodeVar108 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar106 ) / max( dot( p1_nodeVar106, p1_nodeVar106 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar109 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar106 * vec2<f32>( p1_nodeVar108 ) ) ) ) ) ) * p1_nodeVar107 );
				p1_nodeVar110 = ( p1_nodeVar109 > p1_nodeVar15 );

				if ( p1_nodeVar110 ) {

					p1_nodeVar111 = mix( p1_nodeVar24.z, p1_nodeVar104.z, p1_nodeVar108 );

				} else {

					p1_nodeVar111 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar111;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar110 ) {

						p1_nodeVar113 = picture_read_level( p1_nodeVar104.xy, 0.0 );
						p1_nodeVar112 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar113.x, p1_nodeVar113.y, p1_nodeVar113.z ), p1_nodeVar108 );

					} else {

						p1_nodeVar112 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar112;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar109 );
				

			}

			

		} else {

			p1_nodeVar114 = ( ( p1_nodeVar24.z + p1_nodeVar104.z ) * 0.5 );
			p1_nodeVar116 = ( ( ( ( p1_nodeVar22 + vec2<f32>( -1.0, 0.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 6.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar116, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar116, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar114 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar115 = 1.0;

			} else {

				p1_nodeVar115 = 0.0;

			}

			p1_nodeVar117 = ( p1_nodeVar115 * p1_nodeVar105 );
			p1_nodeVar118 = 0.0;

			if ( ( p1_nodeVar117 > 0.5 ) ) {

				p1_nodeVar119 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar106 ) / max( dot( p1_nodeVar106, p1_nodeVar106 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar118 = p1_nodeVar119;
				p1_nodeVar120 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar106 * vec2<f32>( p1_nodeVar118 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar114, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar121 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar120 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar120, p1_nodeVar11, p1_nodeVar121 ) - ( ( p1_nodeVar8 * p1_nodeVar121 ) * ( 1.0 - p1_nodeVar121 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar120 );
					

				}

				p1_nodeVar122 = exp( ( ( - max( p1_nodeVar120, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar122 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar104.z, p1_nodeVar118 ) * p1_nodeVar122 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar123 = picture_read_level( p1_nodeVar104.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar123.x, p1_nodeVar123.y, p1_nodeVar123.z ), p1_nodeVar118 ) * vec3<f32>( p1_nodeVar122 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar124 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar124 ) - ( ( p1_nodeVar8 * p1_nodeVar124 ) * ( 1.0 - p1_nodeVar124 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar125 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( -1.0, 0.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar126 = p1_nodeVar125;
		p1_nodeVar127 = ( p1_nodeVar24.w * p1_nodeVar126.w );
		p1_nodeVar128 = ( ( p1_nodeVar126.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar129 = ( clamp( ( 1.0 - ( length( p1_nodeVar128 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar127 );

			if ( ( p1_nodeVar129 > 0.0 ) ) {

				p1_nodeVar130 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar128 ) / max( dot( p1_nodeVar128, p1_nodeVar128 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar131 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar128 * vec2<f32>( p1_nodeVar130 ) ) ) ) ) ) * p1_nodeVar129 );
				p1_nodeVar132 = ( p1_nodeVar131 > p1_nodeVar15 );

				if ( p1_nodeVar132 ) {

					p1_nodeVar133 = mix( p1_nodeVar24.z, p1_nodeVar126.z, p1_nodeVar130 );

				} else {

					p1_nodeVar133 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar133;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar132 ) {

						p1_nodeVar135 = picture_read_level( p1_nodeVar126.xy, 0.0 );
						p1_nodeVar134 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar135.x, p1_nodeVar135.y, p1_nodeVar135.z ), p1_nodeVar130 );

					} else {

						p1_nodeVar134 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar134;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar131 );
				

			}

			

		} else {

			p1_nodeVar136 = ( ( p1_nodeVar24.z + p1_nodeVar126.z ) * 0.5 );
			p1_nodeVar138 = ( ( ( ( p1_nodeVar22 + vec2<f32>( -1.0, 0.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 1.0, 0.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar138, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar138, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar136 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar137 = 1.0;

			} else {

				p1_nodeVar137 = 0.0;

			}

			p1_nodeVar139 = ( p1_nodeVar137 * p1_nodeVar127 );
			p1_nodeVar140 = 0.0;

			if ( ( p1_nodeVar139 > 0.5 ) ) {

				p1_nodeVar141 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar128 ) / max( dot( p1_nodeVar128, p1_nodeVar128 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar140 = p1_nodeVar141;
				p1_nodeVar142 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar128 * vec2<f32>( p1_nodeVar140 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar136, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar143 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar142 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar142, p1_nodeVar11, p1_nodeVar143 ) - ( ( p1_nodeVar8 * p1_nodeVar143 ) * ( 1.0 - p1_nodeVar143 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar142 );
					

				}

				p1_nodeVar144 = exp( ( ( - max( p1_nodeVar142, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar144 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar126.z, p1_nodeVar140 ) * p1_nodeVar144 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar145 = picture_read_level( p1_nodeVar126.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar145.x, p1_nodeVar145.y, p1_nodeVar145.z ), p1_nodeVar140 ) * vec3<f32>( p1_nodeVar144 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar146 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar146 ) - ( ( p1_nodeVar8 * p1_nodeVar146 ) * ( 1.0 - p1_nodeVar146 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar147 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( -1.0, -1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar148 = p1_nodeVar147;
		p1_nodeVar149 = ( p1_nodeVar24.w * p1_nodeVar148.w );
		p1_nodeVar150 = ( ( p1_nodeVar148.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar151 = ( clamp( ( 1.0 - ( length( p1_nodeVar150 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar149 );

			if ( ( p1_nodeVar151 > 0.0 ) ) {

				p1_nodeVar152 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar150 ) / max( dot( p1_nodeVar150, p1_nodeVar150 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar153 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar150 * vec2<f32>( p1_nodeVar152 ) ) ) ) ) ) * p1_nodeVar151 );
				p1_nodeVar154 = ( p1_nodeVar153 > p1_nodeVar15 );

				if ( p1_nodeVar154 ) {

					p1_nodeVar155 = mix( p1_nodeVar24.z, p1_nodeVar148.z, p1_nodeVar152 );

				} else {

					p1_nodeVar155 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar155;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar154 ) {

						p1_nodeVar157 = picture_read_level( p1_nodeVar148.xy, 0.0 );
						p1_nodeVar156 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar157.x, p1_nodeVar157.y, p1_nodeVar157.z ), p1_nodeVar152 );

					} else {

						p1_nodeVar156 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar156;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar153 );
				

			}

			

		} else {

			p1_nodeVar158 = ( ( p1_nodeVar24.z + p1_nodeVar148.z ) * 0.5 );
			p1_nodeVar160 = ( ( ( ( p1_nodeVar22 + vec2<f32>( -1.0, -1.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 1.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar160, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar160, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar158 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar159 = 1.0;

			} else {

				p1_nodeVar159 = 0.0;

			}

			p1_nodeVar161 = ( p1_nodeVar159 * p1_nodeVar149 );
			p1_nodeVar162 = 0.0;

			if ( ( p1_nodeVar161 > 0.5 ) ) {

				p1_nodeVar163 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar150 ) / max( dot( p1_nodeVar150, p1_nodeVar150 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar162 = p1_nodeVar163;
				p1_nodeVar164 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar150 * vec2<f32>( p1_nodeVar162 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar158, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar165 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar164 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar164, p1_nodeVar11, p1_nodeVar165 ) - ( ( p1_nodeVar8 * p1_nodeVar165 ) * ( 1.0 - p1_nodeVar165 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar164 );
					

				}

				p1_nodeVar166 = exp( ( ( - max( p1_nodeVar164, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar166 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar148.z, p1_nodeVar162 ) * p1_nodeVar166 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar167 = picture_read_level( p1_nodeVar148.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar167.x, p1_nodeVar167.y, p1_nodeVar167.z ), p1_nodeVar162 ) * vec3<f32>( p1_nodeVar166 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar168 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar168 ) - ( ( p1_nodeVar8 * p1_nodeVar168 ) * ( 1.0 - p1_nodeVar168 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar169 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( 0.0, -1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar170 = p1_nodeVar169;
		p1_nodeVar171 = ( p1_nodeVar24.w * p1_nodeVar170.w );
		p1_nodeVar172 = ( ( p1_nodeVar170.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar173 = ( clamp( ( 1.0 - ( length( p1_nodeVar172 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar171 );

			if ( ( p1_nodeVar173 > 0.0 ) ) {

				p1_nodeVar174 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar172 ) / max( dot( p1_nodeVar172, p1_nodeVar172 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar175 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar172 * vec2<f32>( p1_nodeVar174 ) ) ) ) ) ) * p1_nodeVar173 );
				p1_nodeVar176 = ( p1_nodeVar175 > p1_nodeVar15 );

				if ( p1_nodeVar176 ) {

					p1_nodeVar177 = mix( p1_nodeVar24.z, p1_nodeVar170.z, p1_nodeVar174 );

				} else {

					p1_nodeVar177 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar177;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar176 ) {

						p1_nodeVar179 = picture_read_level( p1_nodeVar170.xy, 0.0 );
						p1_nodeVar178 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar179.x, p1_nodeVar179.y, p1_nodeVar179.z ), p1_nodeVar174 );

					} else {

						p1_nodeVar178 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar178;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar175 );
				

			}

			

		} else {

			p1_nodeVar180 = ( ( p1_nodeVar24.z + p1_nodeVar170.z ) * 0.5 );
			p1_nodeVar182 = ( ( ( ( p1_nodeVar22 + vec2<f32>( 0.0, -1.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 0.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar182, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar182, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar180 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar181 = 1.0;

			} else {

				p1_nodeVar181 = 0.0;

			}

			p1_nodeVar183 = ( p1_nodeVar181 * p1_nodeVar171 );
			p1_nodeVar184 = 0.0;

			if ( ( p1_nodeVar183 > 0.5 ) ) {

				p1_nodeVar185 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar172 ) / max( dot( p1_nodeVar172, p1_nodeVar172 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar184 = p1_nodeVar185;
				p1_nodeVar186 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar172 * vec2<f32>( p1_nodeVar184 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar180, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar187 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar186 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar186, p1_nodeVar11, p1_nodeVar187 ) - ( ( p1_nodeVar8 * p1_nodeVar187 ) * ( 1.0 - p1_nodeVar187 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar186 );
					

				}

				p1_nodeVar188 = exp( ( ( - max( p1_nodeVar186, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar188 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar170.z, p1_nodeVar184 ) * p1_nodeVar188 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar189 = picture_read_level( p1_nodeVar170.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar189.x, p1_nodeVar189.y, p1_nodeVar189.z ), p1_nodeVar184 ) * vec3<f32>( p1_nodeVar188 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar190 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar190 ) - ( ( p1_nodeVar8 * p1_nodeVar190 ) * ( 1.0 - p1_nodeVar190 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}

		p1_nodeVar191 = target_load( t0, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( ( p1_nodeVar22 + vec2<f32>( 1.0, -1.0 ) ) + vec2<f32>( 2.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p1_nodeVar192 = p1_nodeVar191;
		p1_nodeVar193 = ( p1_nodeVar24.w * p1_nodeVar192.w );
		p1_nodeVar194 = ( ( p1_nodeVar192.xy * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - p1_nodeVar25 );

		if ( p1_nodeVar5 ) {

			p1_nodeVar195 = ( clamp( ( 1.0 - ( length( p1_nodeVar194 ) / ( f32(knobs.range) * f32(knobs.spacing) ) ) ), 0.0, 1.0 ) * p1_nodeVar193 );

			if ( ( p1_nodeVar195 > 0.0 ) ) {

				p1_nodeVar196 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar194 ) / max( dot( p1_nodeVar194, p1_nodeVar194 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar197 = ( ( 1.0 - smoothstep( ( ( f32(knobs.lineWidth) * 0.5 ) - 0.6 ), ( ( f32(knobs.lineWidth) * 0.5 ) + 0.6 ), length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar194 * vec2<f32>( p1_nodeVar196 ) ) ) ) ) ) * p1_nodeVar195 );
				p1_nodeVar198 = ( p1_nodeVar197 > p1_nodeVar15 );

				if ( p1_nodeVar198 ) {

					p1_nodeVar199 = mix( p1_nodeVar24.z, p1_nodeVar192.z, p1_nodeVar196 );

				} else {

					p1_nodeVar199 = p1_nodeVar16;

				}

				p1_nodeVar16 = p1_nodeVar199;

				if ( p1_nodeVar6 ) {


					if ( p1_nodeVar198 ) {

						p1_nodeVar201 = picture_read_level( p1_nodeVar192.xy, 0.0 );
						p1_nodeVar200 = mix( p1_nodeVar26, vec3<f32>( p1_nodeVar201.x, p1_nodeVar201.y, p1_nodeVar201.z ), p1_nodeVar196 );

					} else {

						p1_nodeVar200 = p1_nodeVar17;

					}

					p1_nodeVar17 = p1_nodeVar200;
					

				}

				p1_nodeVar15 = max( p1_nodeVar15, p1_nodeVar197 );
				

			}

			

		} else {

			p1_nodeVar202 = ( ( p1_nodeVar24.z + p1_nodeVar192.z ) * 0.5 );
			p1_nodeVar204 = ( ( ( ( p1_nodeVar22 + vec2<f32>( 0.0, -1.0 ) ) * vec2<f32>( 2.0 ) ) + vec2<f32>( 6.0, 1.0 ) ) + vec2<f32>( ( f32(knobs.seed) * 7.7 ) ) );

			if ( ( fract( ( sin( vec2<f32>( dot( p1_nodeVar204, vec2<f32>( 127.1, 311.7 ) ), dot( p1_nodeVar204, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ).x < ( smoothstep( ( f32(knobs.linkThreshold) - 0.15 ), ( f32(knobs.linkThreshold) + 0.15 ), p1_nodeVar202 ) * f32(knobs.links) ) ) ) {

				p1_nodeVar203 = 1.0;

			} else {

				p1_nodeVar203 = 0.0;

			}

			p1_nodeVar205 = ( p1_nodeVar203 * p1_nodeVar193 );
			p1_nodeVar206 = 0.0;

			if ( ( p1_nodeVar205 > 0.5 ) ) {

				p1_nodeVar207 = clamp( ( dot( ( p1_nodeVar2 - p1_nodeVar25 ), p1_nodeVar194 ) / max( dot( p1_nodeVar194, p1_nodeVar194 ), 0.0001 ) ), 0.0, 1.0 );
				p1_nodeVar206 = p1_nodeVar207;
				p1_nodeVar208 = ( length( ( ( p1_nodeVar2 - p1_nodeVar25 ) - ( p1_nodeVar194 * vec2<f32>( p1_nodeVar206 ) ) ) ) - ( ( mix( f32(knobs.linkMin), f32(knobs.linkMax), pow( p1_nodeVar202, 1.5 ) ) * f32(knobs.spacing) ) * 0.5 ) );

				if ( p1_nodeVar4 ) {

					p1_nodeVar209 = clamp( ( 0.5 + ( ( 0.5 * ( p1_nodeVar208 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
					p1_nodeVar11 = ( mix( p1_nodeVar208, p1_nodeVar11, p1_nodeVar209 ) - ( ( p1_nodeVar8 * p1_nodeVar209 ) * ( 1.0 - p1_nodeVar209 ) ) );
					

				} else {

					p1_nodeVar11 = min( p1_nodeVar11, p1_nodeVar208 );
					

				}

				p1_nodeVar210 = exp( ( ( - max( p1_nodeVar208, 0.0 ) ) / p1_nodeVar10 ) );
				p1_nodeVar12 = ( p1_nodeVar12 + p1_nodeVar210 );
				p1_nodeVar13 = ( p1_nodeVar13 + ( mix( p1_nodeVar24.z, p1_nodeVar192.z, p1_nodeVar206 ) * p1_nodeVar210 ) );

				if ( p1_nodeVar6 ) {

					p1_nodeVar211 = picture_read_level( p1_nodeVar192.xy, 0.0 );
					p1_nodeVar14 = ( p1_nodeVar14 + ( mix( p1_nodeVar26, vec3<f32>( p1_nodeVar211.x, p1_nodeVar211.y, p1_nodeVar211.z ), p1_nodeVar206 ) * vec3<f32>( p1_nodeVar210 ) ) );
					

				}

				

			} else {


				if ( p1_nodeVar4 ) {


					if ( p1_nodeVar4 ) {

						p1_nodeVar212 = clamp( ( 0.5 + ( ( 0.5 * ( 100000.0 - p1_nodeVar11 ) ) / p1_nodeVar8 ) ), 0.0, 1.0 );
						p1_nodeVar11 = ( mix( 100000.0, p1_nodeVar11, p1_nodeVar212 ) - ( ( p1_nodeVar8 * p1_nodeVar212 ) * ( 1.0 - p1_nodeVar212 ) ) );
						

					} else {

						p1_nodeVar11 = min( p1_nodeVar11, 100000.0 );
						

					}

					

				}

				

			}

			

		}


	}

	p1_nodeVar213 = vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z);
	p1_nodeVar214 = 1.0;

	if ( ( f32(knobs.background) >= 0.5 ) ) {

		p1_nodeVar215 = picture_read_level( p1_nodeVar1, 0.0 );
		p1_nodeVar213 = vec3<f32>( p1_nodeVar215.x, p1_nodeVar215.y, p1_nodeVar215.z );

		if ( ( f32(knobs.background) < 1.5 ) ) {

			p1_nodeVar216 = p1_nodeVar215.w;

		} else {

			p1_nodeVar216 = 0.0;

		}

		p1_nodeVar214 = p1_nodeVar216;
		

	}

	p1_nodeVar217 = vec3<f32>( 0.0, 0.0, 0.0 );
	p1_nodeVar218 = 0.0;
	p1_nodeVar219 = ( p1_nodeVar213 * vec3<f32>( p1_nodeVar214 ) );

	if ( p1_nodeVar5 ) {


		if ( ( f32(knobs.colorMode) < 0.5 ) ) {

			p1_nodeVar221 = own1_read_level( vec2<f32>( ( 1.0 - p1_nodeVar16 ), 0.5 ), 0.0 );
			p1_nodeVar220 = vec3<f32>( p1_nodeVar221.x, p1_nodeVar221.y, p1_nodeVar221.z );

		} else {


			if ( ( f32(knobs.colorMode) < 1.5 ) ) {

				p1_nodeVar222 = p1_nodeVar17;

			} else {

				p1_nodeVar222 = vec3<f32>(knobs.ink.x, knobs.ink.y, knobs.ink.z);

			}

			p1_nodeVar220 = p1_nodeVar222;

		}

		p1_nodeVar219 = mix( p1_nodeVar219, p1_nodeVar220, p1_nodeVar15 );
		

	}


	if ( ( f32(knobs.colorMode) < 0.5 ) ) {

		p1_nodeVar224 = own1_read_level( vec2<f32>( ( 1.0 - ( p1_nodeVar13 / max( p1_nodeVar12, 0.0001 ) ) ), 0.5 ), 0.0 );
		p1_nodeVar223 = vec3<f32>( p1_nodeVar224.x, p1_nodeVar224.y, p1_nodeVar224.z );

	} else {


		if ( ( f32(knobs.colorMode) < 1.5 ) ) {

			p1_nodeVar225 = ( p1_nodeVar14 / vec3<f32>( max( p1_nodeVar12, 0.0001 ) ) );

		} else {

			p1_nodeVar225 = vec3<f32>(knobs.ink.x, knobs.ink.y, knobs.ink.z);

		}

		p1_nodeVar223 = p1_nodeVar225;

	}

	p1_nodeVar226 = ( 1.0 - smoothstep( -0.7, 0.7, p1_nodeVar11 ) );
	p1_nodeVar217 = mix( p1_nodeVar219, p1_nodeVar223, p1_nodeVar226 );
	p1_nodeVar218 = mix( mix( p1_nodeVar214, 1.0, p1_nodeVar15 ), 1.0, p1_nodeVar226 );
	p1_nodeVar227 = vec4<f32>( ( p1_nodeVar217 / vec3<f32>( max( p1_nodeVar218, 0.0001 ) ) ), p1_nodeVar218 );
	p1_nodeVar228 = vec3<f32>( p1_nodeVar227.x, p1_nodeVar227.y, p1_nodeVar227.z );
	p1_nodeVar229 = ( ( ( p1_nodeVar228.x * 0.2126 ) + ( p1_nodeVar228.y * 0.7152 ) ) + ( p1_nodeVar228.z * 0.0722 ) );
	p1_nodeVar230 = mix( vec3<f32>( p1_nodeVar229, p1_nodeVar229, p1_nodeVar229 ), p1_nodeVar228, f32(1.0) );
	p1_nodeVar231 = vec4<f32>( clamp( vec3<f32>( ( ( ( p1_nodeVar230.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p1_nodeVar230.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p1_nodeVar230.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p1_nodeVar230.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p1_nodeVar230.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p1_nodeVar230.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p1_nodeVar230.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p1_nodeVar230.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p1_nodeVar230.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p1_nodeVar227.w, 0.0, 1.0 ) );
	p1_nodeVar233 = mix( clamp( p1_nodeVar0.w, 0.0, 1.0 ), clamp( p1_nodeVar231.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p1_nodeVar233 > 0.0 ) ) {

		p1_nodeVar232 = p1_nodeVar233;

	} else {

		p1_nodeVar232 = 1.0;

	}

	p1_DiffuseColor = vec4<f32>( ( mix( ( p1_nodeVar0.xyz * vec3<f32>( clamp( p1_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p1_nodeVar231.xyz, p1_nodeVar231.xyz, clamp( p1_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p1_nodeVar231.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p1_nodeVar232 ) ), p1_nodeVar233 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_nodeVar234 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar234;

	// result

	p1_output.color = p1_nodeVar234;

	return p1_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p1_main(door_uv).color);
}

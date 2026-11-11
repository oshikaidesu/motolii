// Perlin Noise: TypeGPU's "Three.js - Simple" example by Software Mansion (MIT, github.com/software-mansion/TypeGPU), by TypeGPU's toTSL and three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_typegpu.ts)
// --label:Generate
// --about:Uses TypeGPU shader functions and procedural noise inside a minimal Three.js WebGPU material.
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,

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

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms



// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;

// codes
var<private> p0_var_1: vec2f;

fn p0_hash(value: u32) -> u32 {
  {
    var x = (value ^ (value >> 17u));
    x *= 3982152891u;
    x ^= (x >> 11u);
    x *= 2890668881u;
    x ^= (x >> 15u);
    x *= 830770091u;
    x ^= (x >> 14u);
    return x;
  }
}

fn p0_scrambleSeed3(value: vec3f) -> vec3u {
  let u32Value = bitcast<vec3u>(value);
  return vec3u(p0_hash((u32Value.x ^ 1253408251u)), p0_hash((u32Value.y ^ 2900286023u)), p0_hash((u32Value.z ^ 3164612939u)));
}

fn p0_rotl(x: u32, k: u32) -> u32 {
  return ((x << k) | (x >> (32u - k)));
}

var<private> p0_gpuSeed: vec2u;

fn p0_seed3(value: vec3f) {
  let scrambled = p0_scrambleSeed3(value);
  let newSeed = vec2u(p0_hash((scrambled.x ^ p0_rotl(scrambled.z, 16u))), p0_hash((p0_rotl(scrambled.y, 16u) ^ scrambled.z)));
  p0_gpuSeed = newSeed;
}

fn p0_randSeed3(seed: vec3f) {
  p0_seed3(seed);
}

fn p0_next() -> u32 {
  {
    let s0 = p0_gpuSeed.x;
    var s1 = p0_gpuSeed.y;
    s1 ^= s0;
    p0_gpuSeed.x = ((p0_rotl(s0, 26u) ^ s1) ^ (s1 << 9u));
    p0_gpuSeed.y = p0_rotl(s1, 13u);
    return (p0_rotl((p0_gpuSeed.x * 2654435771u), 5u) * 5u);
  }
}

fn p0_u32To01F32(value: u32) -> f32 {
  let mantissa = (value & 8388607u);
  let bits = (1065353216u | mantissa);
  let f = bitcast<f32>(bits);
  return (f - 1f);
}

fn p0_sample_1() -> f32 {
  let r = p0_next();
  return p0_u32To01F32(r);
}

fn p0_randOnUnitSphere() -> vec3f {
  let z = ((2f * p0_sample_1()) - 1f);
  let oneMinusZSq = sqrt((1f - (z * z)));
  let theta = (6.283185307179586f * p0_sample_1());
  let x = (cos(theta) * oneMinusZSq);
  let y = (sin(theta) * oneMinusZSq);
  return vec3f(x, y, z);
}

fn p0_computeJunctionGradient(pos: vec3i) -> vec3f {
  p0_randSeed3((1e-3f * vec3f(pos)));
  return p0_randOnUnitSphere();
}

fn p0_dotProdGrid(pos: vec3f, junction: vec3f) -> f32 {
  let relative = (pos - junction);
  let gridVector = p0_computeJunctionGradient(vec3i(junction));
  return dot(relative, gridVector);
}

fn p0_quinticInterpolation(t: vec3f) -> vec3f {
  return (((t * t) * t) * ((t * ((t * 6f) - 15f)) + 10f));
}

fn p0_sample(pos: vec3f) -> f32 {
  let minJunction = floor(pos);
  let xyz = p0_dotProdGrid(pos, minJunction);
  let xyZ = p0_dotProdGrid(pos, (minJunction + vec3f(0, 0, 1)));
  let xYz = p0_dotProdGrid(pos, (minJunction + vec3f(0, 1, 0)));
  let xYZ = p0_dotProdGrid(pos, (minJunction + vec3f(0, 1, 1)));
  let Xyz = p0_dotProdGrid(pos, (minJunction + vec3f(1, 0, 0)));
  let XyZ = p0_dotProdGrid(pos, (minJunction + vec3f(1, 0, 1)));
  let XYz = p0_dotProdGrid(pos, (minJunction + vec3f(1, 1, 0)));
  let XYZ = p0_dotProdGrid(pos, (minJunction + vec3f(1)));
  let partial = (pos - minJunction);
  let smoothPartial = p0_quinticInterpolation(partial);
  let xy = mix(xyz, xyZ, smoothPartial.z);
  let xY = mix(xYz, xYZ, smoothPartial.z);
  let Xy = mix(Xyz, XyZ, smoothPartial.z);
  let XY = mix(XYz, XYZ, smoothPartial.z);
  let x = mix(xy, xY, smoothPartial.y);
  let X = mix(Xy, XY, smoothPartial.y);
  return mix(x, X, smoothPartial.x);
}

fn p0_item() -> vec4f {
  let coords = (p0_var_1 * 2f);
  let pattern = p0_sample(vec3f(coords, (f32(knobs.time) * 0.2f)));
  return vec4f(tanh((pattern * 5f)), 0.2f, 0.4f, 1f);
}


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_var_1 = nodeVarying4;
	p0_DiffuseColor = p0_item();
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar0 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar0;

	// result

	p0_output.color = p0_nodeVar0;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

// Perlin Noise Wobble: the points of a solid moved by noise. TypeGPU's "Three.js - Simple" example by Software Mansion (MIT, github.com/software-mansion/TypeGPU), by TypeGPU's toTSL and three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_typegpu.ts)
// --label:3d
struct Knobs {
  time: f32,
};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
@group(0) @binding(8) var<storage, read_write> shape_normals: array<f32>;

// structs


// uniforms



// varyings

struct VaryingsStruct {
	@location( 0 ) nodeVarying4 : vec2<f32>,
	@builtin( position ) builtinClipSpace : vec4<f32>
};
var<private> varyings : VaryingsStruct;

// vars
var<private> modelViewMatrix : mat4x4<f32>;
var<private> VERTEX_nodeVar1 : vec4<f32>;
var<private> positionLocal : vec3<f32>;
var<private> v_modelViewProjection : vec4<f32>;
var<private> v_positionView : vec3<f32>;
var<private> VERTEX_v_modelViewProjection : vec4<f32>;

// codes
var<private> var_1: vec3f;

fn hash(value: u32) -> u32 {
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

fn scrambleSeed3(value: vec3f) -> vec3u {
  let u32Value = bitcast<vec3u>(value);
  return vec3u(hash((u32Value.x ^ 1253408251u)), hash((u32Value.y ^ 2900286023u)), hash((u32Value.z ^ 3164612939u)));
}

fn rotl(x: u32, k: u32) -> u32 {
  return ((x << k) | (x >> (32u - k)));
}

var<private> gpuSeed: vec2u;

fn seed3(value: vec3f) {
  let scrambled = scrambleSeed3(value);
  let newSeed = vec2u(hash((scrambled.x ^ rotl(scrambled.z, 16u))), hash((rotl(scrambled.y, 16u) ^ scrambled.z)));
  gpuSeed = newSeed;
}

fn randSeed3(seed: vec3f) {
  seed3(seed);
}

fn next() -> u32 {
  {
    let s0 = gpuSeed.x;
    var s1 = gpuSeed.y;
    s1 ^= s0;
    gpuSeed.x = ((rotl(s0, 26u) ^ s1) ^ (s1 << 9u));
    gpuSeed.y = rotl(s1, 13u);
    return (rotl((gpuSeed.x * 2654435771u), 5u) * 5u);
  }
}

fn u32To01F32(value: u32) -> f32 {
  let mantissa = (value & 8388607u);
  let bits = (1065353216u | mantissa);
  let f = bitcast<f32>(bits);
  return (f - 1f);
}

fn sample_1() -> f32 {
  let r = next();
  return u32To01F32(r);
}

fn randOnUnitSphere() -> vec3f {
  let z = ((2f * sample_1()) - 1f);
  let oneMinusZSq = sqrt((1f - (z * z)));
  let theta = (6.283185307179586f * sample_1());
  let x = (cos(theta) * oneMinusZSq);
  let y = (sin(theta) * oneMinusZSq);
  return vec3f(x, y, z);
}

fn computeJunctionGradient(pos: vec3i) -> vec3f {
  randSeed3((1e-3f * vec3f(pos)));
  return randOnUnitSphere();
}

fn dotProdGrid(pos: vec3f, junction: vec3f) -> f32 {
  let relative = (pos - junction);
  let gridVector = computeJunctionGradient(vec3i(junction));
  return dot(relative, gridVector);
}

fn quinticInterpolation(t: vec3f) -> vec3f {
  return (((t * t) * t) * ((t * ((t * 6f) - 15f)) + 10f));
}

fn sample(pos: vec3f) -> f32 {
  let minJunction = floor(pos);
  let xyz = dotProdGrid(pos, minJunction);
  let xyZ = dotProdGrid(pos, (minJunction + vec3f(0, 0, 1)));
  let xYz = dotProdGrid(pos, (minJunction + vec3f(0, 1, 0)));
  let xYZ = dotProdGrid(pos, (minJunction + vec3f(0, 1, 1)));
  let Xyz = dotProdGrid(pos, (minJunction + vec3f(1, 0, 0)));
  let XyZ = dotProdGrid(pos, (minJunction + vec3f(1, 0, 1)));
  let XYz = dotProdGrid(pos, (minJunction + vec3f(1, 1, 0)));
  let XYZ = dotProdGrid(pos, (minJunction + vec3f(1)));
  let partial = (pos - minJunction);
  let smoothPartial = quinticInterpolation(partial);
  let xy = mix(xyz, xyZ, smoothPartial.z);
  let xY = mix(xYz, xYZ, smoothPartial.z);
  let Xy = mix(Xyz, XyZ, smoothPartial.z);
  let XY = mix(XYz, XYZ, smoothPartial.z);
  let x = mix(xy, xY, smoothPartial.y);
  let X = mix(Xy, XY, smoothPartial.y);
  return mix(x, X, smoothPartial.x);
}

fn item() -> vec3f {
  let localPos = (&var_1);
  let t = knobs.time;
  let patternX = sample(((*localPos) + vec3f(t, 0f, 0f)));
  let patternY = sample(((*localPos) + vec3f(t, 0f, 1f)));
  let patternZ = sample(((*localPos) + vec3f(t, 0f, 2f)));
  return ((*localPos) + (vec3f(patternX, patternY, patternZ) * 0.5f));
}


fn point_moved( position : vec3<f32>,
	uv : vec2<f32> ) -> vec3<f32> {

	// flow
	// code

	positionLocal = position;
	var_1 = position;
	positionLocal = item();
	varyings.nodeVarying4 = uv;
	modelViewMatrix = ( mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) * mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) );
	v_positionView = ( modelViewMatrix * vec4<f32>( positionLocal, 1.0 ) ).xyz;
	VERTEX_nodeVar1 = ( mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.0, 1.0) * vec4<f32>( v_positionView, 1.0 ) );
	VERTEX_v_modelViewProjection = VERTEX_nodeVar1;

	// result

	varyings.builtinClipSpace = VERTEX_v_modelViewProjection;

	return positionLocal;

}

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&points) || 3u * i + 2u >= arrayLength(&shape_points) || 2u * i + 1u >= arrayLength(&shape_uvs) || 3u * i + 2u >= arrayLength(&shape_normals)) { return; }
  let p = point_moved(vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u]), vec2f(shape_uvs[2u * i], shape_uvs[2u * i + 1u]));
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
}

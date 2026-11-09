// Glass: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Textured glass in front of the image: reeded, hammered, pyramid, hex or frosted. Every cell acts as a small lens.
// --pass@t0:0,1,s0.5,s0.5
// --pass@t1:0,1,s0.25,s0.25
// --pass@t2:0,1,s0.125,s0.125
// --pass@t3:0,1,s0.0625,s0.0625
// --pass@t4:0,1,s0.03125,s0.03125
// --pass@t5:0,1,s0.015625,s0.015625
// --pass@t6:0,1,s0.0078125,s0.0078125
// --pass@t7:0,1,s0.00390625,s0.00390625
// --pass@t8:0,1,s0.001953125,s0.001953125
// --pass@t9:0,1,s0.0009765625,s0.0009765625
// --pass@:0,0,s1,s1
// --track@pattern:Pattern,0,4,0,1
// --check@profile:Profile,0
// --track@irregularity:Irregularity,0,1,0.7,0.01
// --track@cellSize:Cell Size,3,240,22,1
// --track@angle:Angle,-180,180,0,1
// --track@refraction:Refraction,0,3,0.3,0.01
// --check@distanceFrom:Distance From,0
// --track@distance:Distance,0,240,10,1
// --track@frost:Frost,0,1,0.1,0.01
// --track@frostSize:Frost Size,0.5,8,1.5,0.05
// --track@highlights:Highlights,0,3,0.8,0.01
// --track@lightAngle:Light Angle,0,360,135,1
// --track@edges:Edges,0,1,0.35,0.01
// --track@dispersion:Dispersion,0,1,0.15,0.01
// --track@tint_x:Tint r,0,1,1,0.001
// --track@tint_y:Tint g,0,1,1,0.001
// --track@tint_z:Tint b,0,1,1,0.001
// --track@tintAmount:Tint Amount,0,1,0,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  pattern: f32,
  profile: f32,
  irregularity: f32,
  cellSize: f32,
  angle: f32,
  refraction: f32,
  distanceFrom: f32,
  distance: f32,
  frost: f32,
  frostSize: f32,
  highlights: f32,
  lightAngle: f32,
  edges: f32,
  dispersion: f32,
  tint: vec3<f32>,
  tintAmount: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var t1: texture_2d<f32>;
@group(0) @binding(5) var t1_sampler: sampler;
@group(0) @binding(6) var t2: texture_2d<f32>;
@group(0) @binding(7) var t2_sampler: sampler;
@group(0) @binding(8) var t3: texture_2d<f32>;
@group(0) @binding(9) var t3_sampler: sampler;
@group(0) @binding(10) var t4: texture_2d<f32>;
@group(0) @binding(11) var t4_sampler: sampler;
@group(0) @binding(12) var t5: texture_2d<f32>;
@group(0) @binding(13) var t5_sampler: sampler;
@group(0) @binding(14) var t6: texture_2d<f32>;
@group(0) @binding(15) var t6_sampler: sampler;
@group(0) @binding(16) var t7: texture_2d<f32>;
@group(0) @binding(17) var t7_sampler: sampler;
@group(0) @binding(18) var t8: texture_2d<f32>;
@group(0) @binding(19) var t8_sampler: sampler;
@group(0) @binding(20) var t9: texture_2d<f32>;
@group(0) @binding(21) var t9_sampler: sampler;
@group(0) @binding(22) var<uniform> knobs: Knobs;
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
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec4<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : vec4<f32>;
var<private> p0_nodeVar4 : vec4<f32>;
var<private> p0_nodeVar5 : vec4<f32>;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : vec4<f32>;
var<private> p0_nodeVar8 : vec4<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar14 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar1 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 0.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 0.0 ) ) ) );
	p0_nodeVar2 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * -1.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * -1.0 ) ) ) );
	p0_nodeVar3 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 1.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * -1.0 ) ) ) );
	p0_nodeVar4 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * -1.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 1.0 ) ) ) );
	p0_nodeVar5 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 1.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 1.0 ) ) ) );
	p0_nodeVar6 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * -2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 0.0 ) ) ) );
	p0_nodeVar7 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 0.0 ) ) ) );
	p0_nodeVar8 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 0.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * -2.0 ) ) ) );
	p0_nodeVar9 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 0.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 2.0 ) ) ) );
	p0_nodeVar10 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * -2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * -2.0 ) ) ) );
	p0_nodeVar11 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * -2.0 ) ) ) );
	p0_nodeVar12 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * -2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 2.0 ) ) ) );
	p0_nodeVar13 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).x * 2.0 ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.5)), (1.0 / (knobs.resolution.y / 0.5))).y * 2.0 ) ) ) );
	p0_DiffuseColor = ( ( ( ( vec4<f32>( ( vec3<f32>( p0_nodeVar1.x, p0_nodeVar1.y, p0_nodeVar1.z ) * vec3<f32>( p0_nodeVar1.w ) ), p0_nodeVar1.w ) * vec4<f32>( 0.125 ) ) + ( ( ( vec4<f32>( ( vec3<f32>( p0_nodeVar2.x, p0_nodeVar2.y, p0_nodeVar2.z ) * vec3<f32>( p0_nodeVar2.w ) ), p0_nodeVar2.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ) * vec3<f32>( p0_nodeVar3.w ) ), p0_nodeVar3.w ) ) + ( vec4<f32>( ( vec3<f32>( p0_nodeVar4.x, p0_nodeVar4.y, p0_nodeVar4.z ) * vec3<f32>( p0_nodeVar4.w ) ), p0_nodeVar4.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar5.x, p0_nodeVar5.y, p0_nodeVar5.z ) * vec3<f32>( p0_nodeVar5.w ) ), p0_nodeVar5.w ) ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( vec4<f32>( ( vec3<f32>( p0_nodeVar6.x, p0_nodeVar6.y, p0_nodeVar6.z ) * vec3<f32>( p0_nodeVar6.w ) ), p0_nodeVar6.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar7.x, p0_nodeVar7.y, p0_nodeVar7.z ) * vec3<f32>( p0_nodeVar7.w ) ), p0_nodeVar7.w ) ) + ( vec4<f32>( ( vec3<f32>( p0_nodeVar8.x, p0_nodeVar8.y, p0_nodeVar8.z ) * vec3<f32>( p0_nodeVar8.w ) ), p0_nodeVar8.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z ) * vec3<f32>( p0_nodeVar9.w ) ), p0_nodeVar9.w ) ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( vec4<f32>( ( vec3<f32>( p0_nodeVar10.x, p0_nodeVar10.y, p0_nodeVar10.z ) * vec3<f32>( p0_nodeVar10.w ) ), p0_nodeVar10.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar11.x, p0_nodeVar11.y, p0_nodeVar11.z ) * vec3<f32>( p0_nodeVar11.w ) ), p0_nodeVar11.w ) ) + ( vec4<f32>( ( vec3<f32>( p0_nodeVar12.x, p0_nodeVar12.y, p0_nodeVar12.z ) * vec3<f32>( p0_nodeVar12.w ) ), p0_nodeVar12.w ) + vec4<f32>( ( vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z ) * vec3<f32>( p0_nodeVar13.w ) ), p0_nodeVar13.w ) ) ) * vec4<f32>( 0.03125 ) ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar14 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar14;

	// result

	p0_output.color = p0_nodeVar14;

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
var<private> p1_nodeVar0 : vec2<f32>;
var<private> p1_nodeVar1 : vec4<f32>;
var<private> p1_nodeVar2 : vec4<f32>;
var<private> p1_nodeVar3 : vec4<f32>;
var<private> p1_nodeVar4 : vec4<f32>;
var<private> p1_nodeVar5 : vec4<f32>;
var<private> p1_nodeVar6 : vec4<f32>;
var<private> p1_nodeVar7 : vec4<f32>;
var<private> p1_nodeVar8 : vec4<f32>;
var<private> p1_nodeVar9 : vec4<f32>;
var<private> p1_nodeVar10 : vec4<f32>;
var<private> p1_nodeVar11 : vec4<f32>;
var<private> p1_nodeVar12 : vec4<f32>;
var<private> p1_nodeVar13 : vec4<f32>;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar14 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar1 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p1_nodeVar2 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p1_nodeVar3 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p1_nodeVar4 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p1_nodeVar5 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p1_nodeVar6 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p1_nodeVar7 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p1_nodeVar8 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p1_nodeVar9 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p1_nodeVar10 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p1_nodeVar11 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p1_nodeVar12 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p1_nodeVar13 = target_read( t0, t0_sampler, ( p1_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p1_DiffuseColor = ( ( ( ( p1_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p1_nodeVar2 + p1_nodeVar3 ) + ( p1_nodeVar4 + p1_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p1_nodeVar6 + p1_nodeVar7 ) + ( p1_nodeVar8 + p1_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p1_nodeVar10 + p1_nodeVar11 ) + ( p1_nodeVar12 + p1_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_nodeVar14 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar14;

	// result

	p1_output.color = p1_nodeVar14;

	return p1_output;

}

// structs

struct p2_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p2_output : p2_OutputStruct;

// uniforms


// vars
var<private> p2_DiffuseColor : vec4<f32>;
var<private> p2_nodeVar0 : vec2<f32>;
var<private> p2_nodeVar1 : vec4<f32>;
var<private> p2_nodeVar2 : vec4<f32>;
var<private> p2_nodeVar3 : vec4<f32>;
var<private> p2_nodeVar4 : vec4<f32>;
var<private> p2_nodeVar5 : vec4<f32>;
var<private> p2_nodeVar6 : vec4<f32>;
var<private> p2_nodeVar7 : vec4<f32>;
var<private> p2_nodeVar8 : vec4<f32>;
var<private> p2_nodeVar9 : vec4<f32>;
var<private> p2_nodeVar10 : vec4<f32>;
var<private> p2_nodeVar11 : vec4<f32>;
var<private> p2_nodeVar12 : vec4<f32>;
var<private> p2_nodeVar13 : vec4<f32>;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar14 : vec4<f32>;

// codes


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p2_nodeVar1 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar2 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p2_nodeVar3 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p2_nodeVar4 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p2_nodeVar5 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p2_nodeVar6 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar7 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar8 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar9 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p2_nodeVar10 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar11 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar12 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p2_nodeVar13 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p2_DiffuseColor = ( ( ( ( p2_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p2_nodeVar2 + p2_nodeVar3 ) + ( p2_nodeVar4 + p2_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p2_nodeVar6 + p2_nodeVar7 ) + ( p2_nodeVar8 + p2_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p2_nodeVar10 + p2_nodeVar11 ) + ( p2_nodeVar12 + p2_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_nodeVar14 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar14;

	// result

	p2_output.color = p2_nodeVar14;

	return p2_output;

}

// structs

struct p3_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p3_output : p3_OutputStruct;

// uniforms


// vars
var<private> p3_DiffuseColor : vec4<f32>;
var<private> p3_nodeVar0 : vec2<f32>;
var<private> p3_nodeVar1 : vec4<f32>;
var<private> p3_nodeVar2 : vec4<f32>;
var<private> p3_nodeVar3 : vec4<f32>;
var<private> p3_nodeVar4 : vec4<f32>;
var<private> p3_nodeVar5 : vec4<f32>;
var<private> p3_nodeVar6 : vec4<f32>;
var<private> p3_nodeVar7 : vec4<f32>;
var<private> p3_nodeVar8 : vec4<f32>;
var<private> p3_nodeVar9 : vec4<f32>;
var<private> p3_nodeVar10 : vec4<f32>;
var<private> p3_nodeVar11 : vec4<f32>;
var<private> p3_nodeVar12 : vec4<f32>;
var<private> p3_nodeVar13 : vec4<f32>;
var<private> p3_Output : vec4<f32>;
var<private> p3_nodeVar14 : vec4<f32>;

// codes


fn p3_main(door_uv: vec2f) -> p3_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p3_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p3_nodeVar1 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar2 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -1.0 ) ) ) );
	p3_nodeVar3 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -1.0 ) ) ) );
	p3_nodeVar4 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 1.0 ) ) ) );
	p3_nodeVar5 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 1.0 ) ) ) );
	p3_nodeVar6 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar7 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar8 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar9 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p3_nodeVar10 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar11 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar12 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p3_nodeVar13 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p3_DiffuseColor = ( ( ( ( p3_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p3_nodeVar2 + p3_nodeVar3 ) + ( p3_nodeVar4 + p3_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p3_nodeVar6 + p3_nodeVar7 ) + ( p3_nodeVar8 + p3_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p3_nodeVar10 + p3_nodeVar11 ) + ( p3_nodeVar12 + p3_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_nodeVar14 = max( vec4<f32>( p3_DiffuseColor.xyz, p3_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p3_Output = p3_nodeVar14;

	// result

	p3_output.color = p3_nodeVar14;

	return p3_output;

}

// structs

struct p4_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p4_output : p4_OutputStruct;

// uniforms


// vars
var<private> p4_DiffuseColor : vec4<f32>;
var<private> p4_nodeVar0 : vec2<f32>;
var<private> p4_nodeVar1 : vec4<f32>;
var<private> p4_nodeVar2 : vec4<f32>;
var<private> p4_nodeVar3 : vec4<f32>;
var<private> p4_nodeVar4 : vec4<f32>;
var<private> p4_nodeVar5 : vec4<f32>;
var<private> p4_nodeVar6 : vec4<f32>;
var<private> p4_nodeVar7 : vec4<f32>;
var<private> p4_nodeVar8 : vec4<f32>;
var<private> p4_nodeVar9 : vec4<f32>;
var<private> p4_nodeVar10 : vec4<f32>;
var<private> p4_nodeVar11 : vec4<f32>;
var<private> p4_nodeVar12 : vec4<f32>;
var<private> p4_nodeVar13 : vec4<f32>;
var<private> p4_Output : vec4<f32>;
var<private> p4_nodeVar14 : vec4<f32>;

// codes


fn p4_main(door_uv: vec2f) -> p4_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p4_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p4_nodeVar1 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar2 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * -1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * -1.0 ) ) ) );
	p4_nodeVar3 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * -1.0 ) ) ) );
	p4_nodeVar4 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * -1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 1.0 ) ) ) );
	p4_nodeVar5 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 1.0 ) ) ) );
	p4_nodeVar6 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * -2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar7 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar8 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar9 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 2.0 ) ) ) );
	p4_nodeVar10 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * -2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar11 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar12 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * -2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 2.0 ) ) ) );
	p4_nodeVar13 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).x * 2.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.03125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.03125)) + 0)).y * 2.0 ) ) ) );
	p4_DiffuseColor = ( ( ( ( p4_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p4_nodeVar2 + p4_nodeVar3 ) + ( p4_nodeVar4 + p4_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p4_nodeVar6 + p4_nodeVar7 ) + ( p4_nodeVar8 + p4_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p4_nodeVar10 + p4_nodeVar11 ) + ( p4_nodeVar12 + p4_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p4_DiffuseColor.w = ( p4_DiffuseColor.w * f32(1.0) );
	p4_nodeVar14 = max( vec4<f32>( p4_DiffuseColor.xyz, p4_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p4_Output = p4_nodeVar14;

	// result

	p4_output.color = p4_nodeVar14;

	return p4_output;

}

// structs

struct p5_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p5_output : p5_OutputStruct;

// uniforms


// vars
var<private> p5_DiffuseColor : vec4<f32>;
var<private> p5_nodeVar0 : vec2<f32>;
var<private> p5_nodeVar1 : vec4<f32>;
var<private> p5_nodeVar2 : vec4<f32>;
var<private> p5_nodeVar3 : vec4<f32>;
var<private> p5_nodeVar4 : vec4<f32>;
var<private> p5_nodeVar5 : vec4<f32>;
var<private> p5_nodeVar6 : vec4<f32>;
var<private> p5_nodeVar7 : vec4<f32>;
var<private> p5_nodeVar8 : vec4<f32>;
var<private> p5_nodeVar9 : vec4<f32>;
var<private> p5_nodeVar10 : vec4<f32>;
var<private> p5_nodeVar11 : vec4<f32>;
var<private> p5_nodeVar12 : vec4<f32>;
var<private> p5_nodeVar13 : vec4<f32>;
var<private> p5_Output : vec4<f32>;
var<private> p5_nodeVar14 : vec4<f32>;

// codes


fn p5_main(door_uv: vec2f) -> p5_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p5_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p5_nodeVar1 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 0.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar2 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * -1.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * -1.0 ) ) ) );
	p5_nodeVar3 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 1.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * -1.0 ) ) ) );
	p5_nodeVar4 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * -1.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 1.0 ) ) ) );
	p5_nodeVar5 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 1.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 1.0 ) ) ) );
	p5_nodeVar6 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * -2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar7 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar8 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 0.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * -2.0 ) ) ) );
	p5_nodeVar9 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 0.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 2.0 ) ) ) );
	p5_nodeVar10 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * -2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * -2.0 ) ) ) );
	p5_nodeVar11 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * -2.0 ) ) ) );
	p5_nodeVar12 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * -2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 2.0 ) ) ) );
	p5_nodeVar13 = target_read( t4, t4_sampler, ( p5_nodeVar0 + vec2<f32>( ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).x * 2.0 ), ( vec2<f32>((32 * (1.0 / (knobs.resolution.x / 0.015625)) + 0), (32 * (1.0 / (knobs.resolution.y / 0.015625)) + 0)).y * 2.0 ) ) ) );
	p5_DiffuseColor = ( ( ( ( p5_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p5_nodeVar2 + p5_nodeVar3 ) + ( p5_nodeVar4 + p5_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p5_nodeVar6 + p5_nodeVar7 ) + ( p5_nodeVar8 + p5_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p5_nodeVar10 + p5_nodeVar11 ) + ( p5_nodeVar12 + p5_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p5_DiffuseColor.w = ( p5_DiffuseColor.w * f32(1.0) );
	p5_nodeVar14 = max( vec4<f32>( p5_DiffuseColor.xyz, p5_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p5_Output = p5_nodeVar14;

	// result

	p5_output.color = p5_nodeVar14;

	return p5_output;

}

// structs

struct p6_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p6_output : p6_OutputStruct;

// uniforms


// vars
var<private> p6_DiffuseColor : vec4<f32>;
var<private> p6_nodeVar0 : vec2<f32>;
var<private> p6_nodeVar1 : vec4<f32>;
var<private> p6_nodeVar2 : vec4<f32>;
var<private> p6_nodeVar3 : vec4<f32>;
var<private> p6_nodeVar4 : vec4<f32>;
var<private> p6_nodeVar5 : vec4<f32>;
var<private> p6_nodeVar6 : vec4<f32>;
var<private> p6_nodeVar7 : vec4<f32>;
var<private> p6_nodeVar8 : vec4<f32>;
var<private> p6_nodeVar9 : vec4<f32>;
var<private> p6_nodeVar10 : vec4<f32>;
var<private> p6_nodeVar11 : vec4<f32>;
var<private> p6_nodeVar12 : vec4<f32>;
var<private> p6_nodeVar13 : vec4<f32>;
var<private> p6_Output : vec4<f32>;
var<private> p6_nodeVar14 : vec4<f32>;

// codes


fn p6_main(door_uv: vec2f) -> p6_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p6_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p6_nodeVar1 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 0.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar2 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * -1.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * -1.0 ) ) ) );
	p6_nodeVar3 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 1.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * -1.0 ) ) ) );
	p6_nodeVar4 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * -1.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 1.0 ) ) ) );
	p6_nodeVar5 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 1.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 1.0 ) ) ) );
	p6_nodeVar6 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * -2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar7 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar8 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 0.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * -2.0 ) ) ) );
	p6_nodeVar9 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 0.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 2.0 ) ) ) );
	p6_nodeVar10 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * -2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * -2.0 ) ) ) );
	p6_nodeVar11 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * -2.0 ) ) ) );
	p6_nodeVar12 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * -2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 2.0 ) ) ) );
	p6_nodeVar13 = target_read( t5, t5_sampler, ( p6_nodeVar0 + vec2<f32>( ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).x * 2.0 ), ( vec2<f32>((64 * (1.0 / (knobs.resolution.x / 0.0078125)) + 0), (64 * (1.0 / (knobs.resolution.y / 0.0078125)) + 0)).y * 2.0 ) ) ) );
	p6_DiffuseColor = ( ( ( ( p6_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p6_nodeVar2 + p6_nodeVar3 ) + ( p6_nodeVar4 + p6_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p6_nodeVar6 + p6_nodeVar7 ) + ( p6_nodeVar8 + p6_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p6_nodeVar10 + p6_nodeVar11 ) + ( p6_nodeVar12 + p6_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p6_DiffuseColor.w = ( p6_DiffuseColor.w * f32(1.0) );
	p6_nodeVar14 = max( vec4<f32>( p6_DiffuseColor.xyz, p6_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p6_Output = p6_nodeVar14;

	// result

	p6_output.color = p6_nodeVar14;

	return p6_output;

}

// structs

struct p7_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p7_output : p7_OutputStruct;

// uniforms


// vars
var<private> p7_DiffuseColor : vec4<f32>;
var<private> p7_nodeVar0 : vec2<f32>;
var<private> p7_nodeVar1 : vec4<f32>;
var<private> p7_nodeVar2 : vec4<f32>;
var<private> p7_nodeVar3 : vec4<f32>;
var<private> p7_nodeVar4 : vec4<f32>;
var<private> p7_nodeVar5 : vec4<f32>;
var<private> p7_nodeVar6 : vec4<f32>;
var<private> p7_nodeVar7 : vec4<f32>;
var<private> p7_nodeVar8 : vec4<f32>;
var<private> p7_nodeVar9 : vec4<f32>;
var<private> p7_nodeVar10 : vec4<f32>;
var<private> p7_nodeVar11 : vec4<f32>;
var<private> p7_nodeVar12 : vec4<f32>;
var<private> p7_nodeVar13 : vec4<f32>;
var<private> p7_Output : vec4<f32>;
var<private> p7_nodeVar14 : vec4<f32>;

// codes


fn p7_main(door_uv: vec2f) -> p7_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p7_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p7_nodeVar1 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 0.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 0.0 ) ) ) );
	p7_nodeVar2 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * -1.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * -1.0 ) ) ) );
	p7_nodeVar3 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 1.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * -1.0 ) ) ) );
	p7_nodeVar4 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * -1.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 1.0 ) ) ) );
	p7_nodeVar5 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 1.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 1.0 ) ) ) );
	p7_nodeVar6 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * -2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 0.0 ) ) ) );
	p7_nodeVar7 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 0.0 ) ) ) );
	p7_nodeVar8 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 0.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * -2.0 ) ) ) );
	p7_nodeVar9 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 0.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 2.0 ) ) ) );
	p7_nodeVar10 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * -2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * -2.0 ) ) ) );
	p7_nodeVar11 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * -2.0 ) ) ) );
	p7_nodeVar12 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * -2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 2.0 ) ) ) );
	p7_nodeVar13 = target_read( t6, t6_sampler, ( p7_nodeVar0 + vec2<f32>( ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).x * 2.0 ), ( vec2<f32>((128 * (1.0 / (knobs.resolution.x / 0.00390625)) + 0), (128 * (1.0 / (knobs.resolution.y / 0.00390625)) + 0)).y * 2.0 ) ) ) );
	p7_DiffuseColor = ( ( ( ( p7_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p7_nodeVar2 + p7_nodeVar3 ) + ( p7_nodeVar4 + p7_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p7_nodeVar6 + p7_nodeVar7 ) + ( p7_nodeVar8 + p7_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p7_nodeVar10 + p7_nodeVar11 ) + ( p7_nodeVar12 + p7_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p7_DiffuseColor.w = ( p7_DiffuseColor.w * f32(1.0) );
	p7_nodeVar14 = max( vec4<f32>( p7_DiffuseColor.xyz, p7_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p7_Output = p7_nodeVar14;

	// result

	p7_output.color = p7_nodeVar14;

	return p7_output;

}

// structs

struct p8_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p8_output : p8_OutputStruct;

// uniforms


// vars
var<private> p8_DiffuseColor : vec4<f32>;
var<private> p8_nodeVar0 : vec2<f32>;
var<private> p8_nodeVar1 : vec4<f32>;
var<private> p8_nodeVar2 : vec4<f32>;
var<private> p8_nodeVar3 : vec4<f32>;
var<private> p8_nodeVar4 : vec4<f32>;
var<private> p8_nodeVar5 : vec4<f32>;
var<private> p8_nodeVar6 : vec4<f32>;
var<private> p8_nodeVar7 : vec4<f32>;
var<private> p8_nodeVar8 : vec4<f32>;
var<private> p8_nodeVar9 : vec4<f32>;
var<private> p8_nodeVar10 : vec4<f32>;
var<private> p8_nodeVar11 : vec4<f32>;
var<private> p8_nodeVar12 : vec4<f32>;
var<private> p8_nodeVar13 : vec4<f32>;
var<private> p8_Output : vec4<f32>;
var<private> p8_nodeVar14 : vec4<f32>;

// codes


fn p8_main(door_uv: vec2f) -> p8_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p8_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p8_nodeVar1 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 0.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 0.0 ) ) ) );
	p8_nodeVar2 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * -1.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * -1.0 ) ) ) );
	p8_nodeVar3 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 1.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * -1.0 ) ) ) );
	p8_nodeVar4 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * -1.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 1.0 ) ) ) );
	p8_nodeVar5 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 1.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 1.0 ) ) ) );
	p8_nodeVar6 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * -2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 0.0 ) ) ) );
	p8_nodeVar7 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 0.0 ) ) ) );
	p8_nodeVar8 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 0.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * -2.0 ) ) ) );
	p8_nodeVar9 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 0.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 2.0 ) ) ) );
	p8_nodeVar10 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * -2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * -2.0 ) ) ) );
	p8_nodeVar11 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * -2.0 ) ) ) );
	p8_nodeVar12 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * -2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 2.0 ) ) ) );
	p8_nodeVar13 = target_read( t7, t7_sampler, ( p8_nodeVar0 + vec2<f32>( ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).x * 2.0 ), ( vec2<f32>((256 * (1.0 / (knobs.resolution.x / 0.001953125)) + 0), (256 * (1.0 / (knobs.resolution.y / 0.001953125)) + 0)).y * 2.0 ) ) ) );
	p8_DiffuseColor = ( ( ( ( p8_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p8_nodeVar2 + p8_nodeVar3 ) + ( p8_nodeVar4 + p8_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p8_nodeVar6 + p8_nodeVar7 ) + ( p8_nodeVar8 + p8_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p8_nodeVar10 + p8_nodeVar11 ) + ( p8_nodeVar12 + p8_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p8_DiffuseColor.w = ( p8_DiffuseColor.w * f32(1.0) );
	p8_nodeVar14 = max( vec4<f32>( p8_DiffuseColor.xyz, p8_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p8_Output = p8_nodeVar14;

	// result

	p8_output.color = p8_nodeVar14;

	return p8_output;

}

// structs

struct p9_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p9_output : p9_OutputStruct;

// uniforms


// vars
var<private> p9_DiffuseColor : vec4<f32>;
var<private> p9_nodeVar0 : vec2<f32>;
var<private> p9_nodeVar1 : vec4<f32>;
var<private> p9_nodeVar2 : vec4<f32>;
var<private> p9_nodeVar3 : vec4<f32>;
var<private> p9_nodeVar4 : vec4<f32>;
var<private> p9_nodeVar5 : vec4<f32>;
var<private> p9_nodeVar6 : vec4<f32>;
var<private> p9_nodeVar7 : vec4<f32>;
var<private> p9_nodeVar8 : vec4<f32>;
var<private> p9_nodeVar9 : vec4<f32>;
var<private> p9_nodeVar10 : vec4<f32>;
var<private> p9_nodeVar11 : vec4<f32>;
var<private> p9_nodeVar12 : vec4<f32>;
var<private> p9_nodeVar13 : vec4<f32>;
var<private> p9_Output : vec4<f32>;
var<private> p9_nodeVar14 : vec4<f32>;

// codes


fn p9_main(door_uv: vec2f) -> p9_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p9_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p9_nodeVar1 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 0.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 0.0 ) ) ) );
	p9_nodeVar2 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * -1.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * -1.0 ) ) ) );
	p9_nodeVar3 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 1.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * -1.0 ) ) ) );
	p9_nodeVar4 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * -1.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 1.0 ) ) ) );
	p9_nodeVar5 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 1.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 1.0 ) ) ) );
	p9_nodeVar6 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * -2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 0.0 ) ) ) );
	p9_nodeVar7 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 0.0 ) ) ) );
	p9_nodeVar8 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 0.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * -2.0 ) ) ) );
	p9_nodeVar9 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 0.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 2.0 ) ) ) );
	p9_nodeVar10 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * -2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * -2.0 ) ) ) );
	p9_nodeVar11 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * -2.0 ) ) ) );
	p9_nodeVar12 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * -2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 2.0 ) ) ) );
	p9_nodeVar13 = target_read( t8, t8_sampler, ( p9_nodeVar0 + vec2<f32>( ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).x * 2.0 ), ( vec2<f32>((512 * (1.0 / (knobs.resolution.x / 0.0009765625)) + 0), (512 * (1.0 / (knobs.resolution.y / 0.0009765625)) + 0)).y * 2.0 ) ) ) );
	p9_DiffuseColor = ( ( ( ( p9_nodeVar1 * vec4<f32>( 0.125 ) ) + ( ( ( p9_nodeVar2 + p9_nodeVar3 ) + ( p9_nodeVar4 + p9_nodeVar5 ) ) * vec4<f32>( 0.125 ) ) ) + ( ( ( p9_nodeVar6 + p9_nodeVar7 ) + ( p9_nodeVar8 + p9_nodeVar9 ) ) * vec4<f32>( 0.0625 ) ) ) + ( ( ( p9_nodeVar10 + p9_nodeVar11 ) + ( p9_nodeVar12 + p9_nodeVar13 ) ) * vec4<f32>( 0.03125 ) ) );
	p9_DiffuseColor.w = ( p9_DiffuseColor.w * f32(1.0) );
	p9_nodeVar14 = max( vec4<f32>( p9_DiffuseColor.xyz, p9_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p9_Output = p9_nodeVar14;

	// result

	p9_output.color = p9_nodeVar14;

	return p9_output;

}

// structs

struct p10_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p10_output : p10_OutputStruct;

// uniforms


// vars
var<private> p10_DiffuseColor : vec4<f32>;
var<private> p10_nodeVar0 : vec4<f32>;
var<private> p10_nodeVar1 : vec2<f32>;
var<private> p10_nodeVar2 : vec2<f32>;
var<private> p10_nodeVar3 : f32;
var<private> p10_nodeVar4 : f32;
var<private> p10_nodeVar5 : vec2<f32>;
var<private> p10_nodeVar6 : vec2<f32>;
var<private> p10_nodeVar7 : vec2<f32>;
var<private> p10_nodeVar8 : f32;
var<private> p10_nodeVar9 : f32;
var<private> p10_nodeVar10 : f32;
var<private> p10_nodeVar11 : f32;
var<private> p10_nodeVar12 : f32;
var<private> p10_nodeVar13 : f32;
var<private> p10_nodeVar14 : vec2<f32>;
var<private> p10_nodeVar15 : vec2<f32>;
var<private> p10_nodeVar16 : vec2<f32>;
var<private> p10_nodeVar17 : vec2<f32>;
var<private> p10_nodeVar18 : vec2<f32>;
var<private> p10_nodeVar19 : vec2<f32>;
var<private> p10_nodeVar20 : f32;
var<private> p10_nodeVar21 : f32;
var<private> p10_nodeVar22 : vec2<f32>;
var<private> p10_nodeVar23 : vec2<f32>;
var<private> p10_nodeVar24 : f32;
var<private> p10_nodeVar25 : f32;
var<private> p10_nodeVar26 : vec2<f32>;
var<private> p10_nodeVar27 : vec2<f32>;
var<private> p10_nodeVar28 : f32;
var<private> p10_nodeVar29 : f32;
var<private> p10_nodeVar30 : vec2<f32>;
var<private> p10_nodeVar31 : vec2<f32>;
var<private> p10_nodeVar32 : f32;
var<private> p10_nodeVar33 : f32;
var<private> p10_nodeVar34 : vec2<f32>;
var<private> p10_nodeVar35 : vec2<f32>;
var<private> p10_nodeVar36 : f32;
var<private> p10_nodeVar37 : f32;
var<private> p10_nodeVar38 : vec2<f32>;
var<private> p10_nodeVar39 : vec2<f32>;
var<private> p10_nodeVar40 : f32;
var<private> p10_nodeVar41 : f32;
var<private> p10_nodeVar42 : vec2<f32>;
var<private> p10_nodeVar43 : vec2<f32>;
var<private> p10_nodeVar44 : f32;
var<private> p10_nodeVar45 : f32;
var<private> p10_nodeVar46 : vec2<f32>;
var<private> p10_nodeVar47 : vec2<f32>;
var<private> p10_nodeVar48 : f32;
var<private> p10_nodeVar49 : f32;
var<private> p10_nodeVar50 : vec2<f32>;
var<private> p10_nodeVar51 : vec2<f32>;
var<private> p10_nodeVar52 : f32;
var<private> p10_nodeVar53 : bool;
var<private> p10_nodeVar54 : bool;
var<private> p10_nodeVar55 : bool;
var<private> p10_nodeVar56 : bool;
var<private> p10_nodeVar57 : bool;
var<private> p10_nodeVar58 : bool;
var<private> p10_nodeVar59 : bool;
var<private> p10_nodeVar60 : bool;
var<private> p10_nodeVar61 : bool;
var<private> p10_nodeVar62 : vec2<f32>;
var<private> p10_nodeVar63 : vec2<f32>;
var<private> p10_nodeVar64 : vec2<f32>;
var<private> p10_nodeVar65 : vec2<f32>;
var<private> p10_nodeVar66 : vec2<f32>;
var<private> p10_nodeVar67 : vec2<f32>;
var<private> p10_nodeVar68 : vec2<f32>;
var<private> p10_nodeVar69 : vec2<f32>;
var<private> p10_nodeVar70 : vec2<f32>;
var<private> p10_nodeVar71 : f32;
var<private> p10_nodeVar72 : f32;
var<private> p10_nodeVar73 : f32;
var<private> p10_nodeVar74 : f32;
var<private> p10_nodeVar75 : f32;
var<private> p10_nodeVar76 : f32;
var<private> p10_nodeVar77 : f32;
var<private> p10_nodeVar78 : f32;
var<private> p10_nodeVar79 : f32;
var<private> p10_nodeVar80 : f32;
var<private> p10_nodeVar81 : vec2<f32>;
var<private> p10_nodeVar82 : vec2<f32>;
var<private> p10_nodeVar83 : f32;
var<private> p10_nodeVar84 : f32;
var<private> p10_nodeVar85 : vec2<f32>;
var<private> p10_nodeVar86 : vec2<f32>;
var<private> p10_nodeVar87 : vec2<f32>;
var<private> p10_nodeVar88 : vec2<f32>;
var<private> p10_nodeVar89 : vec2<f32>;
var<private> p10_nodeVar90 : vec2<f32>;
var<private> p10_nodeVar91 : vec2<f32>;
var<private> p10_nodeVar92 : f32;
var<private> p10_nodeVar93 : vec2<f32>;
var<private> p10_nodeVar94 : vec2<f32>;
var<private> p10_nodeVar95 : vec2<f32>;
var<private> p10_nodeVar96 : vec3<f32>;
var<private> p10_nodeVar97 : vec3<f32>;
var<private> p10_nodeVar98 : vec2<f32>;
var<private> p10_nodeVar99 : vec3<f32>;
var<private> p10_nodeVar100 : vec3<f32>;
var<private> p10_nodeVar101 : vec2<f32>;
var<private> p10_nodeVar102 : vec2<f32>;
var<private> p10_nodeVar103 : vec2<f32>;
var<private> p10_nodeVar104 : vec3<f32>;
var<private> p10_nodeVar105 : vec3<f32>;
var<private> p10_nodeVar106 : vec2<f32>;
var<private> p10_nodeVar107 : vec3<f32>;
var<private> p10_nodeVar108 : vec3<f32>;
var<private> p10_nodeVar109 : vec2<f32>;
var<private> p10_nodeVar110 : vec2<f32>;
var<private> p10_nodeVar111 : vec3<f32>;
var<private> p10_nodeVar112 : vec3<f32>;
var<private> p10_nodeVar113 : vec2<f32>;
var<private> p10_nodeVar114 : vec3<f32>;
var<private> p10_nodeVar115 : vec3<f32>;
var<private> p10_nodeVar116 : vec2<f32>;
var<private> p10_nodeVar117 : vec2<f32>;
var<private> p10_nodeVar118 : vec2<f32>;
var<private> p10_nodeVar119 : vec3<f32>;
var<private> p10_nodeVar120 : vec3<f32>;
var<private> p10_nodeVar121 : vec2<f32>;
var<private> p10_nodeVar122 : vec3<f32>;
var<private> p10_nodeVar123 : vec3<f32>;
var<private> p10_nodeVar124 : vec2<f32>;
var<private> p10_nodeVar125 : vec2<f32>;
var<private> p10_nodeVar126 : vec3<f32>;
var<private> p10_nodeVar127 : vec3<f32>;
var<private> p10_nodeVar128 : vec2<f32>;
var<private> p10_nodeVar129 : vec3<f32>;
var<private> p10_nodeVar130 : vec3<f32>;
var<private> p10_nodeVar131 : vec2<f32>;
var<private> p10_nodeVar132 : vec2<f32>;
var<private> p10_nodeVar133 : vec2<f32>;
var<private> p10_nodeVar134 : vec3<f32>;
var<private> p10_nodeVar135 : vec3<f32>;
var<private> p10_nodeVar136 : vec2<f32>;
var<private> p10_nodeVar137 : vec3<f32>;
var<private> p10_nodeVar138 : vec3<f32>;
var<private> p10_nodeVar139 : vec2<f32>;
var<private> p10_nodeVar140 : vec2<f32>;
var<private> p10_nodeVar141 : vec3<f32>;
var<private> p10_nodeVar142 : vec3<f32>;
var<private> p10_nodeVar143 : vec2<f32>;
var<private> p10_nodeVar144 : vec3<f32>;
var<private> p10_nodeVar145 : vec3<f32>;
var<private> p10_nodeVar146 : vec2<f32>;
var<private> p10_nodeVar147 : vec2<f32>;
var<private> p10_nodeVar148 : vec2<f32>;
var<private> p10_nodeVar149 : vec3<f32>;
var<private> p10_nodeVar150 : vec3<f32>;
var<private> p10_nodeVar151 : vec2<f32>;
var<private> p10_nodeVar152 : vec3<f32>;
var<private> p10_nodeVar153 : vec3<f32>;
var<private> p10_nodeVar154 : vec2<f32>;
var<private> p10_nodeVar155 : vec2<f32>;
var<private> p10_nodeVar156 : vec3<f32>;
var<private> p10_nodeVar157 : vec3<f32>;
var<private> p10_nodeVar158 : vec2<f32>;
var<private> p10_nodeVar159 : vec3<f32>;
var<private> p10_nodeVar160 : vec3<f32>;
var<private> p10_nodeVar161 : vec2<f32>;
var<private> p10_nodeVar162 : vec2<f32>;
var<private> p10_nodeVar163 : vec2<f32>;
var<private> p10_nodeVar164 : vec3<f32>;
var<private> p10_nodeVar165 : vec3<f32>;
var<private> p10_nodeVar166 : vec2<f32>;
var<private> p10_nodeVar167 : vec3<f32>;
var<private> p10_nodeVar168 : vec3<f32>;
var<private> p10_nodeVar169 : vec2<f32>;
var<private> p10_nodeVar170 : vec2<f32>;
var<private> p10_nodeVar171 : vec2<f32>;
var<private> p10_nodeVar172 : f32;
var<private> p10_nodeVar173 : vec4<f32>;
var<private> p10_nodeVar174 : f32;
var<private> p10_nodeVar175 : vec4<f32>;
var<private> p10_nodeVar176 : f32;
var<private> p10_nodeVar177 : f32;
var<private> p10_nodeVar178 : f32;
var<private> p10_nodeVar179 : vec4<f32>;
var<private> p10_nodeVar180 : vec2<f32>;
var<private> p10_nodeVar181 : vec2<f32>;
var<private> p10_nodeVar182 : vec2<f32>;
var<private> p10_nodeVar183 : vec2<f32>;
var<private> p10_nodeVar184 : vec2<f32>;
var<private> p10_nodeVar185 : vec2<f32>;
var<private> p10_nodeVar186 : vec2<f32>;
var<private> p10_nodeVar187 : vec4<f32>;
var<private> p10_nodeVar188 : vec2<f32>;
var<private> p10_nodeVar189 : vec2<f32>;
var<private> p10_nodeVar190 : vec2<f32>;
var<private> p10_nodeVar191 : vec4<f32>;
var<private> p10_nodeVar192 : vec4<f32>;
var<private> p10_nodeVar193 : vec4<f32>;
var<private> p10_nodeVar194 : vec2<f32>;
var<private> p10_nodeVar195 : vec2<f32>;
var<private> p10_nodeVar196 : vec2<f32>;
var<private> p10_nodeVar197 : vec2<f32>;
var<private> p10_nodeVar198 : vec2<f32>;
var<private> p10_nodeVar199 : vec2<f32>;
var<private> p10_nodeVar200 : vec2<f32>;
var<private> p10_nodeVar201 : vec4<f32>;
var<private> p10_nodeVar202 : vec2<f32>;
var<private> p10_nodeVar203 : vec2<f32>;
var<private> p10_nodeVar204 : vec2<f32>;
var<private> p10_nodeVar205 : vec4<f32>;
var<private> p10_nodeVar206 : vec4<f32>;
var<private> p10_nodeVar207 : vec4<f32>;
var<private> p10_nodeVar208 : vec2<f32>;
var<private> p10_nodeVar209 : vec2<f32>;
var<private> p10_nodeVar210 : vec2<f32>;
var<private> p10_nodeVar211 : vec2<f32>;
var<private> p10_nodeVar212 : vec2<f32>;
var<private> p10_nodeVar213 : vec2<f32>;
var<private> p10_nodeVar214 : vec2<f32>;
var<private> p10_nodeVar215 : vec4<f32>;
var<private> p10_nodeVar216 : vec2<f32>;
var<private> p10_nodeVar217 : vec2<f32>;
var<private> p10_nodeVar218 : vec2<f32>;
var<private> p10_nodeVar219 : vec4<f32>;
var<private> p10_nodeVar220 : vec4<f32>;
var<private> p10_nodeVar221 : vec4<f32>;
var<private> p10_nodeVar222 : vec2<f32>;
var<private> p10_nodeVar223 : vec2<f32>;
var<private> p10_nodeVar224 : vec2<f32>;
var<private> p10_nodeVar225 : vec2<f32>;
var<private> p10_nodeVar226 : vec2<f32>;
var<private> p10_nodeVar227 : vec2<f32>;
var<private> p10_nodeVar228 : vec2<f32>;
var<private> p10_nodeVar229 : vec4<f32>;
var<private> p10_nodeVar230 : vec2<f32>;
var<private> p10_nodeVar231 : vec2<f32>;
var<private> p10_nodeVar232 : vec2<f32>;
var<private> p10_nodeVar233 : vec4<f32>;
var<private> p10_nodeVar234 : vec4<f32>;
var<private> p10_nodeVar235 : vec4<f32>;
var<private> p10_nodeVar236 : vec2<f32>;
var<private> p10_nodeVar237 : vec2<f32>;
var<private> p10_nodeVar238 : vec2<f32>;
var<private> p10_nodeVar239 : vec2<f32>;
var<private> p10_nodeVar240 : vec2<f32>;
var<private> p10_nodeVar241 : vec2<f32>;
var<private> p10_nodeVar242 : vec2<f32>;
var<private> p10_nodeVar243 : vec4<f32>;
var<private> p10_nodeVar244 : vec2<f32>;
var<private> p10_nodeVar245 : vec2<f32>;
var<private> p10_nodeVar246 : vec2<f32>;
var<private> p10_nodeVar247 : vec4<f32>;
var<private> p10_nodeVar248 : vec4<f32>;
var<private> p10_nodeVar249 : vec4<f32>;
var<private> p10_nodeVar250 : vec2<f32>;
var<private> p10_nodeVar251 : vec2<f32>;
var<private> p10_nodeVar252 : vec2<f32>;
var<private> p10_nodeVar253 : vec2<f32>;
var<private> p10_nodeVar254 : vec2<f32>;
var<private> p10_nodeVar255 : vec2<f32>;
var<private> p10_nodeVar256 : vec2<f32>;
var<private> p10_nodeVar257 : vec4<f32>;
var<private> p10_nodeVar258 : vec2<f32>;
var<private> p10_nodeVar259 : vec2<f32>;
var<private> p10_nodeVar260 : vec2<f32>;
var<private> p10_nodeVar261 : vec4<f32>;
var<private> p10_nodeVar262 : vec4<f32>;
var<private> p10_nodeVar263 : vec4<f32>;
var<private> p10_nodeVar264 : vec2<f32>;
var<private> p10_nodeVar265 : vec2<f32>;
var<private> p10_nodeVar266 : vec2<f32>;
var<private> p10_nodeVar267 : vec2<f32>;
var<private> p10_nodeVar268 : vec2<f32>;
var<private> p10_nodeVar269 : vec2<f32>;
var<private> p10_nodeVar270 : vec2<f32>;
var<private> p10_nodeVar271 : vec4<f32>;
var<private> p10_nodeVar272 : vec2<f32>;
var<private> p10_nodeVar273 : vec2<f32>;
var<private> p10_nodeVar274 : vec2<f32>;
var<private> p10_nodeVar275 : vec4<f32>;
var<private> p10_nodeVar276 : vec4<f32>;
var<private> p10_nodeVar277 : vec4<f32>;
var<private> p10_nodeVar278 : vec2<f32>;
var<private> p10_nodeVar279 : vec2<f32>;
var<private> p10_nodeVar280 : vec2<f32>;
var<private> p10_nodeVar281 : vec2<f32>;
var<private> p10_nodeVar282 : vec2<f32>;
var<private> p10_nodeVar283 : vec2<f32>;
var<private> p10_nodeVar284 : vec2<f32>;
var<private> p10_nodeVar285 : vec4<f32>;
var<private> p10_nodeVar286 : vec2<f32>;
var<private> p10_nodeVar287 : vec2<f32>;
var<private> p10_nodeVar288 : vec2<f32>;
var<private> p10_nodeVar289 : vec4<f32>;
var<private> p10_nodeVar290 : vec4<f32>;
var<private> p10_nodeVar291 : vec4<f32>;
var<private> p10_nodeVar292 : vec2<f32>;
var<private> p10_nodeVar293 : vec2<f32>;
var<private> p10_nodeVar294 : vec2<f32>;
var<private> p10_nodeVar295 : vec2<f32>;
var<private> p10_nodeVar296 : vec2<f32>;
var<private> p10_nodeVar297 : vec2<f32>;
var<private> p10_nodeVar298 : vec2<f32>;
var<private> p10_nodeVar299 : vec4<f32>;
var<private> p10_nodeVar300 : vec2<f32>;
var<private> p10_nodeVar301 : vec2<f32>;
var<private> p10_nodeVar302 : vec2<f32>;
var<private> p10_nodeVar303 : vec4<f32>;
var<private> p10_nodeVar304 : vec4<f32>;
var<private> p10_nodeVar305 : vec4<f32>;
var<private> p10_nodeVar306 : vec2<f32>;
var<private> p10_nodeVar307 : vec2<f32>;
var<private> p10_nodeVar308 : vec2<f32>;
var<private> p10_nodeVar309 : vec2<f32>;
var<private> p10_nodeVar310 : vec2<f32>;
var<private> p10_nodeVar311 : vec2<f32>;
var<private> p10_nodeVar312 : vec2<f32>;
var<private> p10_nodeVar313 : vec4<f32>;
var<private> p10_nodeVar314 : vec2<f32>;
var<private> p10_nodeVar315 : vec2<f32>;
var<private> p10_nodeVar316 : vec2<f32>;
var<private> p10_nodeVar317 : vec4<f32>;
var<private> p10_nodeVar318 : vec4<f32>;
var<private> p10_nodeVar319 : vec4<f32>;
var<private> p10_nodeVar320 : vec2<f32>;
var<private> p10_nodeVar321 : vec2<f32>;
var<private> p10_nodeVar322 : vec2<f32>;
var<private> p10_nodeVar323 : vec2<f32>;
var<private> p10_nodeVar324 : vec2<f32>;
var<private> p10_nodeVar325 : vec2<f32>;
var<private> p10_nodeVar326 : vec2<f32>;
var<private> p10_nodeVar327 : vec4<f32>;
var<private> p10_nodeVar328 : vec2<f32>;
var<private> p10_nodeVar329 : vec2<f32>;
var<private> p10_nodeVar330 : vec2<f32>;
var<private> p10_nodeVar331 : vec4<f32>;
var<private> p10_nodeVar332 : vec4<f32>;
var<private> p10_nodeVar333 : vec4<f32>;
var<private> p10_nodeVar334 : vec2<f32>;
var<private> p10_nodeVar335 : vec2<f32>;
var<private> p10_nodeVar336 : vec2<f32>;
var<private> p10_nodeVar337 : vec2<f32>;
var<private> p10_nodeVar338 : vec2<f32>;
var<private> p10_nodeVar339 : vec2<f32>;
var<private> p10_nodeVar340 : vec2<f32>;
var<private> p10_nodeVar341 : vec4<f32>;
var<private> p10_nodeVar342 : vec2<f32>;
var<private> p10_nodeVar343 : vec2<f32>;
var<private> p10_nodeVar344 : vec2<f32>;
var<private> p10_nodeVar345 : vec4<f32>;
var<private> p10_nodeVar346 : vec4<f32>;
var<private> p10_nodeVar347 : vec4<f32>;
var<private> p10_nodeVar348 : vec2<f32>;
var<private> p10_nodeVar349 : vec2<f32>;
var<private> p10_nodeVar350 : vec2<f32>;
var<private> p10_nodeVar351 : vec2<f32>;
var<private> p10_nodeVar352 : vec2<f32>;
var<private> p10_nodeVar353 : vec2<f32>;
var<private> p10_nodeVar354 : vec2<f32>;
var<private> p10_nodeVar355 : vec4<f32>;
var<private> p10_nodeVar356 : vec2<f32>;
var<private> p10_nodeVar357 : vec2<f32>;
var<private> p10_nodeVar358 : vec2<f32>;
var<private> p10_nodeVar359 : vec4<f32>;
var<private> p10_nodeVar360 : vec4<f32>;
var<private> p10_nodeVar361 : vec4<f32>;
var<private> p10_nodeVar362 : vec2<f32>;
var<private> p10_nodeVar363 : vec2<f32>;
var<private> p10_nodeVar364 : vec2<f32>;
var<private> p10_nodeVar365 : vec2<f32>;
var<private> p10_nodeVar366 : vec2<f32>;
var<private> p10_nodeVar367 : vec2<f32>;
var<private> p10_nodeVar368 : vec2<f32>;
var<private> p10_nodeVar369 : vec4<f32>;
var<private> p10_nodeVar370 : vec2<f32>;
var<private> p10_nodeVar371 : vec2<f32>;
var<private> p10_nodeVar372 : vec2<f32>;
var<private> p10_nodeVar373 : vec4<f32>;
var<private> p10_nodeVar374 : vec4<f32>;
var<private> p10_nodeVar375 : vec4<f32>;
var<private> p10_nodeVar376 : vec2<f32>;
var<private> p10_nodeVar377 : vec2<f32>;
var<private> p10_nodeVar378 : vec2<f32>;
var<private> p10_nodeVar379 : vec2<f32>;
var<private> p10_nodeVar380 : vec2<f32>;
var<private> p10_nodeVar381 : vec2<f32>;
var<private> p10_nodeVar382 : vec2<f32>;
var<private> p10_nodeVar383 : vec4<f32>;
var<private> p10_nodeVar384 : vec2<f32>;
var<private> p10_nodeVar385 : vec2<f32>;
var<private> p10_nodeVar386 : vec2<f32>;
var<private> p10_nodeVar387 : vec4<f32>;
var<private> p10_nodeVar388 : vec4<f32>;
var<private> p10_nodeVar389 : vec4<f32>;
var<private> p10_nodeVar390 : vec2<f32>;
var<private> p10_nodeVar391 : vec2<f32>;
var<private> p10_nodeVar392 : vec2<f32>;
var<private> p10_nodeVar393 : vec2<f32>;
var<private> p10_nodeVar394 : vec2<f32>;
var<private> p10_nodeVar395 : vec2<f32>;
var<private> p10_nodeVar396 : vec2<f32>;
var<private> p10_nodeVar397 : vec4<f32>;
var<private> p10_nodeVar398 : vec2<f32>;
var<private> p10_nodeVar399 : vec2<f32>;
var<private> p10_nodeVar400 : vec2<f32>;
var<private> p10_nodeVar401 : vec4<f32>;
var<private> p10_nodeVar402 : vec4<f32>;
var<private> p10_nodeVar403 : vec4<f32>;
var<private> p10_nodeVar404 : vec2<f32>;
var<private> p10_nodeVar405 : vec2<f32>;
var<private> p10_nodeVar406 : vec2<f32>;
var<private> p10_nodeVar407 : vec2<f32>;
var<private> p10_nodeVar408 : vec2<f32>;
var<private> p10_nodeVar409 : vec2<f32>;
var<private> p10_nodeVar410 : vec2<f32>;
var<private> p10_nodeVar411 : vec4<f32>;
var<private> p10_nodeVar412 : vec2<f32>;
var<private> p10_nodeVar413 : vec2<f32>;
var<private> p10_nodeVar414 : vec2<f32>;
var<private> p10_nodeVar415 : vec4<f32>;
var<private> p10_nodeVar416 : vec4<f32>;
var<private> p10_nodeVar417 : vec4<f32>;
var<private> p10_nodeVar418 : vec2<f32>;
var<private> p10_nodeVar419 : vec2<f32>;
var<private> p10_nodeVar420 : vec2<f32>;
var<private> p10_nodeVar421 : vec2<f32>;
var<private> p10_nodeVar422 : vec2<f32>;
var<private> p10_nodeVar423 : vec2<f32>;
var<private> p10_nodeVar424 : vec2<f32>;
var<private> p10_nodeVar425 : vec4<f32>;
var<private> p10_nodeVar426 : vec2<f32>;
var<private> p10_nodeVar427 : vec2<f32>;
var<private> p10_nodeVar428 : vec2<f32>;
var<private> p10_nodeVar429 : vec4<f32>;
var<private> p10_nodeVar430 : vec4<f32>;
var<private> p10_nodeVar431 : vec4<f32>;
var<private> p10_nodeVar432 : vec2<f32>;
var<private> p10_nodeVar433 : vec2<f32>;
var<private> p10_nodeVar434 : vec2<f32>;
var<private> p10_nodeVar435 : vec2<f32>;
var<private> p10_nodeVar436 : vec2<f32>;
var<private> p10_nodeVar437 : vec2<f32>;
var<private> p10_nodeVar438 : vec2<f32>;
var<private> p10_nodeVar439 : vec4<f32>;
var<private> p10_nodeVar440 : vec2<f32>;
var<private> p10_nodeVar441 : vec2<f32>;
var<private> p10_nodeVar442 : vec2<f32>;
var<private> p10_nodeVar443 : vec4<f32>;
var<private> p10_nodeVar444 : vec4<f32>;
var<private> p10_nodeVar445 : vec4<f32>;
var<private> p10_nodeVar446 : vec2<f32>;
var<private> p10_nodeVar447 : vec2<f32>;
var<private> p10_nodeVar448 : vec2<f32>;
var<private> p10_nodeVar449 : vec2<f32>;
var<private> p10_nodeVar450 : vec2<f32>;
var<private> p10_nodeVar451 : vec2<f32>;
var<private> p10_nodeVar452 : vec2<f32>;
var<private> p10_nodeVar453 : vec4<f32>;
var<private> p10_nodeVar454 : vec2<f32>;
var<private> p10_nodeVar455 : vec2<f32>;
var<private> p10_nodeVar456 : vec2<f32>;
var<private> p10_nodeVar457 : vec4<f32>;
var<private> p10_nodeVar458 : vec4<f32>;
var<private> p10_nodeVar459 : vec4<f32>;
var<private> p10_nodeVar460 : f32;
var<private> p10_nodeVar461 : f32;
var<private> p10_nodeVar462 : vec3<f32>;
var<private> p10_nodeVar463 : vec4<f32>;
var<private> p10_nodeVar464 : f32;
var<private> p10_nodeVar465 : f32;
var<private> p10_nodeVar466 : f32;
var<private> p10_nodeVar467 : vec2<f32>;
var<private> p10_nodeVar468 : vec4<f32>;
var<private> p10_nodeVar469 : vec2<f32>;
var<private> p10_nodeVar470 : vec2<f32>;
var<private> p10_nodeVar471 : vec2<f32>;
var<private> p10_nodeVar472 : vec2<f32>;
var<private> p10_nodeVar473 : vec2<f32>;
var<private> p10_nodeVar474 : vec2<f32>;
var<private> p10_nodeVar475 : vec2<f32>;
var<private> p10_nodeVar476 : vec4<f32>;
var<private> p10_nodeVar477 : vec2<f32>;
var<private> p10_nodeVar478 : vec2<f32>;
var<private> p10_nodeVar479 : vec2<f32>;
var<private> p10_nodeVar480 : vec4<f32>;
var<private> p10_nodeVar481 : vec4<f32>;
var<private> p10_nodeVar482 : vec4<f32>;
var<private> p10_nodeVar483 : vec2<f32>;
var<private> p10_nodeVar484 : vec2<f32>;
var<private> p10_nodeVar485 : vec2<f32>;
var<private> p10_nodeVar486 : vec2<f32>;
var<private> p10_nodeVar487 : vec2<f32>;
var<private> p10_nodeVar488 : vec2<f32>;
var<private> p10_nodeVar489 : vec2<f32>;
var<private> p10_nodeVar490 : vec2<f32>;
var<private> p10_nodeVar491 : vec4<f32>;
var<private> p10_nodeVar492 : vec2<f32>;
var<private> p10_nodeVar493 : vec2<f32>;
var<private> p10_nodeVar494 : vec2<f32>;
var<private> p10_nodeVar495 : vec4<f32>;
var<private> p10_nodeVar496 : vec4<f32>;
var<private> p10_nodeVar497 : vec4<f32>;
var<private> p10_nodeVar498 : vec2<f32>;
var<private> p10_nodeVar499 : vec2<f32>;
var<private> p10_nodeVar500 : vec2<f32>;
var<private> p10_nodeVar501 : vec2<f32>;
var<private> p10_nodeVar502 : vec2<f32>;
var<private> p10_nodeVar503 : vec2<f32>;
var<private> p10_nodeVar504 : vec2<f32>;
var<private> p10_nodeVar505 : vec4<f32>;
var<private> p10_nodeVar506 : vec2<f32>;
var<private> p10_nodeVar507 : vec2<f32>;
var<private> p10_nodeVar508 : vec2<f32>;
var<private> p10_nodeVar509 : vec4<f32>;
var<private> p10_nodeVar510 : vec4<f32>;
var<private> p10_nodeVar511 : vec4<f32>;
var<private> p10_nodeVar512 : vec2<f32>;
var<private> p10_nodeVar513 : vec2<f32>;
var<private> p10_nodeVar514 : vec2<f32>;
var<private> p10_nodeVar515 : vec2<f32>;
var<private> p10_nodeVar516 : vec2<f32>;
var<private> p10_nodeVar517 : vec2<f32>;
var<private> p10_nodeVar518 : vec2<f32>;
var<private> p10_nodeVar519 : vec2<f32>;
var<private> p10_nodeVar520 : vec4<f32>;
var<private> p10_nodeVar521 : vec2<f32>;
var<private> p10_nodeVar522 : vec2<f32>;
var<private> p10_nodeVar523 : vec2<f32>;
var<private> p10_nodeVar524 : vec4<f32>;
var<private> p10_nodeVar525 : vec4<f32>;
var<private> p10_nodeVar526 : vec4<f32>;
var<private> p10_nodeVar527 : vec2<f32>;
var<private> p10_nodeVar528 : vec2<f32>;
var<private> p10_nodeVar529 : vec2<f32>;
var<private> p10_nodeVar530 : vec2<f32>;
var<private> p10_nodeVar531 : vec2<f32>;
var<private> p10_nodeVar532 : vec2<f32>;
var<private> p10_nodeVar533 : vec2<f32>;
var<private> p10_nodeVar534 : vec4<f32>;
var<private> p10_nodeVar535 : vec2<f32>;
var<private> p10_nodeVar536 : vec2<f32>;
var<private> p10_nodeVar537 : vec2<f32>;
var<private> p10_nodeVar538 : vec4<f32>;
var<private> p10_nodeVar539 : vec4<f32>;
var<private> p10_nodeVar540 : vec4<f32>;
var<private> p10_nodeVar541 : vec2<f32>;
var<private> p10_nodeVar542 : vec2<f32>;
var<private> p10_nodeVar543 : vec2<f32>;
var<private> p10_nodeVar544 : vec2<f32>;
var<private> p10_nodeVar545 : vec2<f32>;
var<private> p10_nodeVar546 : vec2<f32>;
var<private> p10_nodeVar547 : vec2<f32>;
var<private> p10_nodeVar548 : vec2<f32>;
var<private> p10_nodeVar549 : vec4<f32>;
var<private> p10_nodeVar550 : vec2<f32>;
var<private> p10_nodeVar551 : vec2<f32>;
var<private> p10_nodeVar552 : vec2<f32>;
var<private> p10_nodeVar553 : vec4<f32>;
var<private> p10_nodeVar554 : vec4<f32>;
var<private> p10_nodeVar555 : vec4<f32>;
var<private> p10_nodeVar556 : vec2<f32>;
var<private> p10_nodeVar557 : vec2<f32>;
var<private> p10_nodeVar558 : vec2<f32>;
var<private> p10_nodeVar559 : vec2<f32>;
var<private> p10_nodeVar560 : vec2<f32>;
var<private> p10_nodeVar561 : vec2<f32>;
var<private> p10_nodeVar562 : vec2<f32>;
var<private> p10_nodeVar563 : vec4<f32>;
var<private> p10_nodeVar564 : vec2<f32>;
var<private> p10_nodeVar565 : vec2<f32>;
var<private> p10_nodeVar566 : vec2<f32>;
var<private> p10_nodeVar567 : vec4<f32>;
var<private> p10_nodeVar568 : vec4<f32>;
var<private> p10_nodeVar569 : vec4<f32>;
var<private> p10_nodeVar570 : vec2<f32>;
var<private> p10_nodeVar571 : vec2<f32>;
var<private> p10_nodeVar572 : vec2<f32>;
var<private> p10_nodeVar573 : vec2<f32>;
var<private> p10_nodeVar574 : vec2<f32>;
var<private> p10_nodeVar575 : vec2<f32>;
var<private> p10_nodeVar576 : vec2<f32>;
var<private> p10_nodeVar577 : vec2<f32>;
var<private> p10_nodeVar578 : vec4<f32>;
var<private> p10_nodeVar579 : vec2<f32>;
var<private> p10_nodeVar580 : vec2<f32>;
var<private> p10_nodeVar581 : vec2<f32>;
var<private> p10_nodeVar582 : vec4<f32>;
var<private> p10_nodeVar583 : vec4<f32>;
var<private> p10_nodeVar584 : vec4<f32>;
var<private> p10_nodeVar585 : vec2<f32>;
var<private> p10_nodeVar586 : vec2<f32>;
var<private> p10_nodeVar587 : vec2<f32>;
var<private> p10_nodeVar588 : vec2<f32>;
var<private> p10_nodeVar589 : vec2<f32>;
var<private> p10_nodeVar590 : vec2<f32>;
var<private> p10_nodeVar591 : vec2<f32>;
var<private> p10_nodeVar592 : vec4<f32>;
var<private> p10_nodeVar593 : vec2<f32>;
var<private> p10_nodeVar594 : vec2<f32>;
var<private> p10_nodeVar595 : vec2<f32>;
var<private> p10_nodeVar596 : vec4<f32>;
var<private> p10_nodeVar597 : vec4<f32>;
var<private> p10_nodeVar598 : vec4<f32>;
var<private> p10_nodeVar599 : vec2<f32>;
var<private> p10_nodeVar600 : vec2<f32>;
var<private> p10_nodeVar601 : vec2<f32>;
var<private> p10_nodeVar602 : vec2<f32>;
var<private> p10_nodeVar603 : vec2<f32>;
var<private> p10_nodeVar604 : vec2<f32>;
var<private> p10_nodeVar605 : vec2<f32>;
var<private> p10_nodeVar606 : vec2<f32>;
var<private> p10_nodeVar607 : vec4<f32>;
var<private> p10_nodeVar608 : vec2<f32>;
var<private> p10_nodeVar609 : vec2<f32>;
var<private> p10_nodeVar610 : vec2<f32>;
var<private> p10_nodeVar611 : vec4<f32>;
var<private> p10_nodeVar612 : vec4<f32>;
var<private> p10_nodeVar613 : vec4<f32>;
var<private> p10_nodeVar614 : vec2<f32>;
var<private> p10_nodeVar615 : vec2<f32>;
var<private> p10_nodeVar616 : vec2<f32>;
var<private> p10_nodeVar617 : vec2<f32>;
var<private> p10_nodeVar618 : vec2<f32>;
var<private> p10_nodeVar619 : vec2<f32>;
var<private> p10_nodeVar620 : vec2<f32>;
var<private> p10_nodeVar621 : vec4<f32>;
var<private> p10_nodeVar622 : vec2<f32>;
var<private> p10_nodeVar623 : vec2<f32>;
var<private> p10_nodeVar624 : vec2<f32>;
var<private> p10_nodeVar625 : vec4<f32>;
var<private> p10_nodeVar626 : vec4<f32>;
var<private> p10_nodeVar627 : vec4<f32>;
var<private> p10_nodeVar628 : vec2<f32>;
var<private> p10_nodeVar629 : vec2<f32>;
var<private> p10_nodeVar630 : vec2<f32>;
var<private> p10_nodeVar631 : vec2<f32>;
var<private> p10_nodeVar632 : vec2<f32>;
var<private> p10_nodeVar633 : vec2<f32>;
var<private> p10_nodeVar634 : vec2<f32>;
var<private> p10_nodeVar635 : vec2<f32>;
var<private> p10_nodeVar636 : vec4<f32>;
var<private> p10_nodeVar637 : vec2<f32>;
var<private> p10_nodeVar638 : vec2<f32>;
var<private> p10_nodeVar639 : vec2<f32>;
var<private> p10_nodeVar640 : vec4<f32>;
var<private> p10_nodeVar641 : vec4<f32>;
var<private> p10_nodeVar642 : vec4<f32>;
var<private> p10_nodeVar643 : vec2<f32>;
var<private> p10_nodeVar644 : vec2<f32>;
var<private> p10_nodeVar645 : vec2<f32>;
var<private> p10_nodeVar646 : vec2<f32>;
var<private> p10_nodeVar647 : vec2<f32>;
var<private> p10_nodeVar648 : vec2<f32>;
var<private> p10_nodeVar649 : vec2<f32>;
var<private> p10_nodeVar650 : vec4<f32>;
var<private> p10_nodeVar651 : vec2<f32>;
var<private> p10_nodeVar652 : vec2<f32>;
var<private> p10_nodeVar653 : vec2<f32>;
var<private> p10_nodeVar654 : vec4<f32>;
var<private> p10_nodeVar655 : vec4<f32>;
var<private> p10_nodeVar656 : vec4<f32>;
var<private> p10_nodeVar657 : vec2<f32>;
var<private> p10_nodeVar658 : vec2<f32>;
var<private> p10_nodeVar659 : vec2<f32>;
var<private> p10_nodeVar660 : vec2<f32>;
var<private> p10_nodeVar661 : vec2<f32>;
var<private> p10_nodeVar662 : vec2<f32>;
var<private> p10_nodeVar663 : vec2<f32>;
var<private> p10_nodeVar664 : vec2<f32>;
var<private> p10_nodeVar665 : vec4<f32>;
var<private> p10_nodeVar666 : vec2<f32>;
var<private> p10_nodeVar667 : vec2<f32>;
var<private> p10_nodeVar668 : vec2<f32>;
var<private> p10_nodeVar669 : vec4<f32>;
var<private> p10_nodeVar670 : vec4<f32>;
var<private> p10_nodeVar671 : vec4<f32>;
var<private> p10_nodeVar672 : vec2<f32>;
var<private> p10_nodeVar673 : vec2<f32>;
var<private> p10_nodeVar674 : vec2<f32>;
var<private> p10_nodeVar675 : vec2<f32>;
var<private> p10_nodeVar676 : vec2<f32>;
var<private> p10_nodeVar677 : vec2<f32>;
var<private> p10_nodeVar678 : vec2<f32>;
var<private> p10_nodeVar679 : vec4<f32>;
var<private> p10_nodeVar680 : vec2<f32>;
var<private> p10_nodeVar681 : vec2<f32>;
var<private> p10_nodeVar682 : vec2<f32>;
var<private> p10_nodeVar683 : vec4<f32>;
var<private> p10_nodeVar684 : vec4<f32>;
var<private> p10_nodeVar685 : vec4<f32>;
var<private> p10_nodeVar686 : vec2<f32>;
var<private> p10_nodeVar687 : vec2<f32>;
var<private> p10_nodeVar688 : vec2<f32>;
var<private> p10_nodeVar689 : vec2<f32>;
var<private> p10_nodeVar690 : vec2<f32>;
var<private> p10_nodeVar691 : vec2<f32>;
var<private> p10_nodeVar692 : vec2<f32>;
var<private> p10_nodeVar693 : vec2<f32>;
var<private> p10_nodeVar694 : vec4<f32>;
var<private> p10_nodeVar695 : vec2<f32>;
var<private> p10_nodeVar696 : vec2<f32>;
var<private> p10_nodeVar697 : vec2<f32>;
var<private> p10_nodeVar698 : vec4<f32>;
var<private> p10_nodeVar699 : vec4<f32>;
var<private> p10_nodeVar700 : vec4<f32>;
var<private> p10_nodeVar701 : vec2<f32>;
var<private> p10_nodeVar702 : vec2<f32>;
var<private> p10_nodeVar703 : vec2<f32>;
var<private> p10_nodeVar704 : vec2<f32>;
var<private> p10_nodeVar705 : vec2<f32>;
var<private> p10_nodeVar706 : vec2<f32>;
var<private> p10_nodeVar707 : vec2<f32>;
var<private> p10_nodeVar708 : vec4<f32>;
var<private> p10_nodeVar709 : vec2<f32>;
var<private> p10_nodeVar710 : vec2<f32>;
var<private> p10_nodeVar711 : vec2<f32>;
var<private> p10_nodeVar712 : vec4<f32>;
var<private> p10_nodeVar713 : vec4<f32>;
var<private> p10_nodeVar714 : vec4<f32>;
var<private> p10_nodeVar715 : vec2<f32>;
var<private> p10_nodeVar716 : vec2<f32>;
var<private> p10_nodeVar717 : vec2<f32>;
var<private> p10_nodeVar718 : vec2<f32>;
var<private> p10_nodeVar719 : vec2<f32>;
var<private> p10_nodeVar720 : vec2<f32>;
var<private> p10_nodeVar721 : vec2<f32>;
var<private> p10_nodeVar722 : vec2<f32>;
var<private> p10_nodeVar723 : vec4<f32>;
var<private> p10_nodeVar724 : vec2<f32>;
var<private> p10_nodeVar725 : vec2<f32>;
var<private> p10_nodeVar726 : vec2<f32>;
var<private> p10_nodeVar727 : vec4<f32>;
var<private> p10_nodeVar728 : vec4<f32>;
var<private> p10_nodeVar729 : vec4<f32>;
var<private> p10_nodeVar730 : vec2<f32>;
var<private> p10_nodeVar731 : vec2<f32>;
var<private> p10_nodeVar732 : vec2<f32>;
var<private> p10_nodeVar733 : vec2<f32>;
var<private> p10_nodeVar734 : vec2<f32>;
var<private> p10_nodeVar735 : vec2<f32>;
var<private> p10_nodeVar736 : vec2<f32>;
var<private> p10_nodeVar737 : vec4<f32>;
var<private> p10_nodeVar738 : vec2<f32>;
var<private> p10_nodeVar739 : vec2<f32>;
var<private> p10_nodeVar740 : vec2<f32>;
var<private> p10_nodeVar741 : vec4<f32>;
var<private> p10_nodeVar742 : vec4<f32>;
var<private> p10_nodeVar743 : vec4<f32>;
var<private> p10_nodeVar744 : vec2<f32>;
var<private> p10_nodeVar745 : vec2<f32>;
var<private> p10_nodeVar746 : vec2<f32>;
var<private> p10_nodeVar747 : vec2<f32>;
var<private> p10_nodeVar748 : vec2<f32>;
var<private> p10_nodeVar749 : vec2<f32>;
var<private> p10_nodeVar750 : vec2<f32>;
var<private> p10_nodeVar751 : vec4<f32>;
var<private> p10_nodeVar752 : vec2<f32>;
var<private> p10_nodeVar753 : vec2<f32>;
var<private> p10_nodeVar754 : vec2<f32>;
var<private> p10_nodeVar755 : vec4<f32>;
var<private> p10_nodeVar756 : vec4<f32>;
var<private> p10_nodeVar757 : vec4<f32>;
var<private> p10_nodeVar758 : vec4<f32>;
var<private> p10_nodeVar759 : f32;
var<private> p10_nodeVar760 : f32;
var<private> p10_nodeVar761 : f32;
var<private> p10_nodeVar762 : vec2<f32>;
var<private> p10_nodeVar763 : vec4<f32>;
var<private> p10_nodeVar764 : vec2<f32>;
var<private> p10_nodeVar765 : vec2<f32>;
var<private> p10_nodeVar766 : vec2<f32>;
var<private> p10_nodeVar767 : vec2<f32>;
var<private> p10_nodeVar768 : vec2<f32>;
var<private> p10_nodeVar769 : vec2<f32>;
var<private> p10_nodeVar770 : vec2<f32>;
var<private> p10_nodeVar771 : vec4<f32>;
var<private> p10_nodeVar772 : vec2<f32>;
var<private> p10_nodeVar773 : vec2<f32>;
var<private> p10_nodeVar774 : vec2<f32>;
var<private> p10_nodeVar775 : vec4<f32>;
var<private> p10_nodeVar776 : vec4<f32>;
var<private> p10_nodeVar777 : vec4<f32>;
var<private> p10_nodeVar778 : vec2<f32>;
var<private> p10_nodeVar779 : vec2<f32>;
var<private> p10_nodeVar780 : vec2<f32>;
var<private> p10_nodeVar781 : vec2<f32>;
var<private> p10_nodeVar782 : vec2<f32>;
var<private> p10_nodeVar783 : vec2<f32>;
var<private> p10_nodeVar784 : vec2<f32>;
var<private> p10_nodeVar785 : vec2<f32>;
var<private> p10_nodeVar786 : vec4<f32>;
var<private> p10_nodeVar787 : vec2<f32>;
var<private> p10_nodeVar788 : vec2<f32>;
var<private> p10_nodeVar789 : vec2<f32>;
var<private> p10_nodeVar790 : vec4<f32>;
var<private> p10_nodeVar791 : vec4<f32>;
var<private> p10_nodeVar792 : vec4<f32>;
var<private> p10_nodeVar793 : vec2<f32>;
var<private> p10_nodeVar794 : vec2<f32>;
var<private> p10_nodeVar795 : vec2<f32>;
var<private> p10_nodeVar796 : vec2<f32>;
var<private> p10_nodeVar797 : vec2<f32>;
var<private> p10_nodeVar798 : vec2<f32>;
var<private> p10_nodeVar799 : vec2<f32>;
var<private> p10_nodeVar800 : vec4<f32>;
var<private> p10_nodeVar801 : vec2<f32>;
var<private> p10_nodeVar802 : vec2<f32>;
var<private> p10_nodeVar803 : vec2<f32>;
var<private> p10_nodeVar804 : vec4<f32>;
var<private> p10_nodeVar805 : vec4<f32>;
var<private> p10_nodeVar806 : vec4<f32>;
var<private> p10_nodeVar807 : vec2<f32>;
var<private> p10_nodeVar808 : vec2<f32>;
var<private> p10_nodeVar809 : vec2<f32>;
var<private> p10_nodeVar810 : vec2<f32>;
var<private> p10_nodeVar811 : vec2<f32>;
var<private> p10_nodeVar812 : vec2<f32>;
var<private> p10_nodeVar813 : vec2<f32>;
var<private> p10_nodeVar814 : vec2<f32>;
var<private> p10_nodeVar815 : vec4<f32>;
var<private> p10_nodeVar816 : vec2<f32>;
var<private> p10_nodeVar817 : vec2<f32>;
var<private> p10_nodeVar818 : vec2<f32>;
var<private> p10_nodeVar819 : vec4<f32>;
var<private> p10_nodeVar820 : vec4<f32>;
var<private> p10_nodeVar821 : vec4<f32>;
var<private> p10_nodeVar822 : vec2<f32>;
var<private> p10_nodeVar823 : vec2<f32>;
var<private> p10_nodeVar824 : vec2<f32>;
var<private> p10_nodeVar825 : vec2<f32>;
var<private> p10_nodeVar826 : vec2<f32>;
var<private> p10_nodeVar827 : vec2<f32>;
var<private> p10_nodeVar828 : vec2<f32>;
var<private> p10_nodeVar829 : vec4<f32>;
var<private> p10_nodeVar830 : vec2<f32>;
var<private> p10_nodeVar831 : vec2<f32>;
var<private> p10_nodeVar832 : vec2<f32>;
var<private> p10_nodeVar833 : vec4<f32>;
var<private> p10_nodeVar834 : vec4<f32>;
var<private> p10_nodeVar835 : vec4<f32>;
var<private> p10_nodeVar836 : vec2<f32>;
var<private> p10_nodeVar837 : vec2<f32>;
var<private> p10_nodeVar838 : vec2<f32>;
var<private> p10_nodeVar839 : vec2<f32>;
var<private> p10_nodeVar840 : vec2<f32>;
var<private> p10_nodeVar841 : vec2<f32>;
var<private> p10_nodeVar842 : vec2<f32>;
var<private> p10_nodeVar843 : vec2<f32>;
var<private> p10_nodeVar844 : vec4<f32>;
var<private> p10_nodeVar845 : vec2<f32>;
var<private> p10_nodeVar846 : vec2<f32>;
var<private> p10_nodeVar847 : vec2<f32>;
var<private> p10_nodeVar848 : vec4<f32>;
var<private> p10_nodeVar849 : vec4<f32>;
var<private> p10_nodeVar850 : vec4<f32>;
var<private> p10_nodeVar851 : vec2<f32>;
var<private> p10_nodeVar852 : vec2<f32>;
var<private> p10_nodeVar853 : vec2<f32>;
var<private> p10_nodeVar854 : vec2<f32>;
var<private> p10_nodeVar855 : vec2<f32>;
var<private> p10_nodeVar856 : vec2<f32>;
var<private> p10_nodeVar857 : vec2<f32>;
var<private> p10_nodeVar858 : vec4<f32>;
var<private> p10_nodeVar859 : vec2<f32>;
var<private> p10_nodeVar860 : vec2<f32>;
var<private> p10_nodeVar861 : vec2<f32>;
var<private> p10_nodeVar862 : vec4<f32>;
var<private> p10_nodeVar863 : vec4<f32>;
var<private> p10_nodeVar864 : vec4<f32>;
var<private> p10_nodeVar865 : vec2<f32>;
var<private> p10_nodeVar866 : vec2<f32>;
var<private> p10_nodeVar867 : vec2<f32>;
var<private> p10_nodeVar868 : vec2<f32>;
var<private> p10_nodeVar869 : vec2<f32>;
var<private> p10_nodeVar870 : vec2<f32>;
var<private> p10_nodeVar871 : vec2<f32>;
var<private> p10_nodeVar872 : vec2<f32>;
var<private> p10_nodeVar873 : vec4<f32>;
var<private> p10_nodeVar874 : vec2<f32>;
var<private> p10_nodeVar875 : vec2<f32>;
var<private> p10_nodeVar876 : vec2<f32>;
var<private> p10_nodeVar877 : vec4<f32>;
var<private> p10_nodeVar878 : vec4<f32>;
var<private> p10_nodeVar879 : vec4<f32>;
var<private> p10_nodeVar880 : vec2<f32>;
var<private> p10_nodeVar881 : vec2<f32>;
var<private> p10_nodeVar882 : vec2<f32>;
var<private> p10_nodeVar883 : vec2<f32>;
var<private> p10_nodeVar884 : vec2<f32>;
var<private> p10_nodeVar885 : vec2<f32>;
var<private> p10_nodeVar886 : vec2<f32>;
var<private> p10_nodeVar887 : vec4<f32>;
var<private> p10_nodeVar888 : vec2<f32>;
var<private> p10_nodeVar889 : vec2<f32>;
var<private> p10_nodeVar890 : vec2<f32>;
var<private> p10_nodeVar891 : vec4<f32>;
var<private> p10_nodeVar892 : vec4<f32>;
var<private> p10_nodeVar893 : vec4<f32>;
var<private> p10_nodeVar894 : vec2<f32>;
var<private> p10_nodeVar895 : vec2<f32>;
var<private> p10_nodeVar896 : vec2<f32>;
var<private> p10_nodeVar897 : vec2<f32>;
var<private> p10_nodeVar898 : vec2<f32>;
var<private> p10_nodeVar899 : vec2<f32>;
var<private> p10_nodeVar900 : vec2<f32>;
var<private> p10_nodeVar901 : vec2<f32>;
var<private> p10_nodeVar902 : vec4<f32>;
var<private> p10_nodeVar903 : vec2<f32>;
var<private> p10_nodeVar904 : vec2<f32>;
var<private> p10_nodeVar905 : vec2<f32>;
var<private> p10_nodeVar906 : vec4<f32>;
var<private> p10_nodeVar907 : vec4<f32>;
var<private> p10_nodeVar908 : vec4<f32>;
var<private> p10_nodeVar909 : vec2<f32>;
var<private> p10_nodeVar910 : vec2<f32>;
var<private> p10_nodeVar911 : vec2<f32>;
var<private> p10_nodeVar912 : vec2<f32>;
var<private> p10_nodeVar913 : vec2<f32>;
var<private> p10_nodeVar914 : vec2<f32>;
var<private> p10_nodeVar915 : vec2<f32>;
var<private> p10_nodeVar916 : vec4<f32>;
var<private> p10_nodeVar917 : vec2<f32>;
var<private> p10_nodeVar918 : vec2<f32>;
var<private> p10_nodeVar919 : vec2<f32>;
var<private> p10_nodeVar920 : vec4<f32>;
var<private> p10_nodeVar921 : vec4<f32>;
var<private> p10_nodeVar922 : vec4<f32>;
var<private> p10_nodeVar923 : vec2<f32>;
var<private> p10_nodeVar924 : vec2<f32>;
var<private> p10_nodeVar925 : vec2<f32>;
var<private> p10_nodeVar926 : vec2<f32>;
var<private> p10_nodeVar927 : vec2<f32>;
var<private> p10_nodeVar928 : vec2<f32>;
var<private> p10_nodeVar929 : vec2<f32>;
var<private> p10_nodeVar930 : vec2<f32>;
var<private> p10_nodeVar931 : vec4<f32>;
var<private> p10_nodeVar932 : vec2<f32>;
var<private> p10_nodeVar933 : vec2<f32>;
var<private> p10_nodeVar934 : vec2<f32>;
var<private> p10_nodeVar935 : vec4<f32>;
var<private> p10_nodeVar936 : vec4<f32>;
var<private> p10_nodeVar937 : vec4<f32>;
var<private> p10_nodeVar938 : vec2<f32>;
var<private> p10_nodeVar939 : vec2<f32>;
var<private> p10_nodeVar940 : vec2<f32>;
var<private> p10_nodeVar941 : vec2<f32>;
var<private> p10_nodeVar942 : vec2<f32>;
var<private> p10_nodeVar943 : vec2<f32>;
var<private> p10_nodeVar944 : vec2<f32>;
var<private> p10_nodeVar945 : vec4<f32>;
var<private> p10_nodeVar946 : vec2<f32>;
var<private> p10_nodeVar947 : vec2<f32>;
var<private> p10_nodeVar948 : vec2<f32>;
var<private> p10_nodeVar949 : vec4<f32>;
var<private> p10_nodeVar950 : vec4<f32>;
var<private> p10_nodeVar951 : vec4<f32>;
var<private> p10_nodeVar952 : vec2<f32>;
var<private> p10_nodeVar953 : vec2<f32>;
var<private> p10_nodeVar954 : vec2<f32>;
var<private> p10_nodeVar955 : vec2<f32>;
var<private> p10_nodeVar956 : vec2<f32>;
var<private> p10_nodeVar957 : vec2<f32>;
var<private> p10_nodeVar958 : vec2<f32>;
var<private> p10_nodeVar959 : vec2<f32>;
var<private> p10_nodeVar960 : vec4<f32>;
var<private> p10_nodeVar961 : vec2<f32>;
var<private> p10_nodeVar962 : vec2<f32>;
var<private> p10_nodeVar963 : vec2<f32>;
var<private> p10_nodeVar964 : vec4<f32>;
var<private> p10_nodeVar965 : vec4<f32>;
var<private> p10_nodeVar966 : vec4<f32>;
var<private> p10_nodeVar967 : vec2<f32>;
var<private> p10_nodeVar968 : vec2<f32>;
var<private> p10_nodeVar969 : vec2<f32>;
var<private> p10_nodeVar970 : vec2<f32>;
var<private> p10_nodeVar971 : vec2<f32>;
var<private> p10_nodeVar972 : vec2<f32>;
var<private> p10_nodeVar973 : vec2<f32>;
var<private> p10_nodeVar974 : vec4<f32>;
var<private> p10_nodeVar975 : vec2<f32>;
var<private> p10_nodeVar976 : vec2<f32>;
var<private> p10_nodeVar977 : vec2<f32>;
var<private> p10_nodeVar978 : vec4<f32>;
var<private> p10_nodeVar979 : vec4<f32>;
var<private> p10_nodeVar980 : vec4<f32>;
var<private> p10_nodeVar981 : vec2<f32>;
var<private> p10_nodeVar982 : vec2<f32>;
var<private> p10_nodeVar983 : vec2<f32>;
var<private> p10_nodeVar984 : vec2<f32>;
var<private> p10_nodeVar985 : vec2<f32>;
var<private> p10_nodeVar986 : vec2<f32>;
var<private> p10_nodeVar987 : vec2<f32>;
var<private> p10_nodeVar988 : vec2<f32>;
var<private> p10_nodeVar989 : vec4<f32>;
var<private> p10_nodeVar990 : vec2<f32>;
var<private> p10_nodeVar991 : vec2<f32>;
var<private> p10_nodeVar992 : vec2<f32>;
var<private> p10_nodeVar993 : vec4<f32>;
var<private> p10_nodeVar994 : vec4<f32>;
var<private> p10_nodeVar995 : vec4<f32>;
var<private> p10_nodeVar996 : vec2<f32>;
var<private> p10_nodeVar997 : vec2<f32>;
var<private> p10_nodeVar998 : vec2<f32>;
var<private> p10_nodeVar999 : vec2<f32>;
var<private> p10_nodeVar1000 : vec2<f32>;
var<private> p10_nodeVar1001 : vec2<f32>;
var<private> p10_nodeVar1002 : vec2<f32>;
var<private> p10_nodeVar1003 : vec4<f32>;
var<private> p10_nodeVar1004 : vec2<f32>;
var<private> p10_nodeVar1005 : vec2<f32>;
var<private> p10_nodeVar1006 : vec2<f32>;
var<private> p10_nodeVar1007 : vec4<f32>;
var<private> p10_nodeVar1008 : vec4<f32>;
var<private> p10_nodeVar1009 : vec4<f32>;
var<private> p10_nodeVar1010 : vec2<f32>;
var<private> p10_nodeVar1011 : vec2<f32>;
var<private> p10_nodeVar1012 : vec2<f32>;
var<private> p10_nodeVar1013 : vec2<f32>;
var<private> p10_nodeVar1014 : vec2<f32>;
var<private> p10_nodeVar1015 : vec2<f32>;
var<private> p10_nodeVar1016 : vec2<f32>;
var<private> p10_nodeVar1017 : vec2<f32>;
var<private> p10_nodeVar1018 : vec4<f32>;
var<private> p10_nodeVar1019 : vec2<f32>;
var<private> p10_nodeVar1020 : vec2<f32>;
var<private> p10_nodeVar1021 : vec2<f32>;
var<private> p10_nodeVar1022 : vec4<f32>;
var<private> p10_nodeVar1023 : vec4<f32>;
var<private> p10_nodeVar1024 : vec4<f32>;
var<private> p10_nodeVar1025 : vec2<f32>;
var<private> p10_nodeVar1026 : vec2<f32>;
var<private> p10_nodeVar1027 : vec2<f32>;
var<private> p10_nodeVar1028 : vec2<f32>;
var<private> p10_nodeVar1029 : vec2<f32>;
var<private> p10_nodeVar1030 : vec2<f32>;
var<private> p10_nodeVar1031 : vec2<f32>;
var<private> p10_nodeVar1032 : vec4<f32>;
var<private> p10_nodeVar1033 : vec2<f32>;
var<private> p10_nodeVar1034 : vec2<f32>;
var<private> p10_nodeVar1035 : vec2<f32>;
var<private> p10_nodeVar1036 : vec4<f32>;
var<private> p10_nodeVar1037 : vec4<f32>;
var<private> p10_nodeVar1038 : vec4<f32>;
var<private> p10_nodeVar1039 : vec2<f32>;
var<private> p10_nodeVar1040 : vec2<f32>;
var<private> p10_nodeVar1041 : vec2<f32>;
var<private> p10_nodeVar1042 : vec2<f32>;
var<private> p10_nodeVar1043 : vec2<f32>;
var<private> p10_nodeVar1044 : vec2<f32>;
var<private> p10_nodeVar1045 : vec2<f32>;
var<private> p10_nodeVar1046 : vec4<f32>;
var<private> p10_nodeVar1047 : vec2<f32>;
var<private> p10_nodeVar1048 : vec2<f32>;
var<private> p10_nodeVar1049 : vec2<f32>;
var<private> p10_nodeVar1050 : vec4<f32>;
var<private> p10_nodeVar1051 : vec4<f32>;
var<private> p10_nodeVar1052 : vec4<f32>;
var<private> p10_nodeVar1053 : vec2<f32>;
var<private> p10_nodeVar1054 : vec2<f32>;
var<private> p10_nodeVar1055 : vec3<f32>;
var<private> p10_nodeVar1056 : vec2<f32>;
var<private> p10_nodeVar1057 : vec3<f32>;
var<private> p10_nodeVar1058 : f32;
var<private> p10_nodeVar1059 : f32;
var<private> p10_nodeVar1060 : vec3<f32>;
var<private> p10_nodeVar1061 : vec4<f32>;
var<private> p10_nodeVar1062 : vec3<f32>;
var<private> p10_nodeVar1063 : f32;
var<private> p10_nodeVar1064 : vec3<f32>;
var<private> p10_nodeVar1065 : vec4<f32>;
var<private> p10_nodeVar1066 : f32;
var<private> p10_nodeVar1067 : f32;
var<private> p10_Output : vec4<f32>;
var<private> p10_nodeVar1068 : vec4<f32>;

// codes


fn p10_main(door_uv: vec2f) -> p10_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p10_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p10_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p10_nodeVar2 = ( p10_nodeVar1 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p10_nodeVar3 = cos( f32((0.017453292519943295 * knobs.angle + 0)) );
	p10_nodeVar4 = sin( f32((0.017453292519943295 * knobs.angle + 0)) );
	p10_nodeVar5 = vec2<f32>( ( ( p10_nodeVar2.x * p10_nodeVar3 ) + ( p10_nodeVar2.y * p10_nodeVar4 ) ), ( ( p10_nodeVar2.y * p10_nodeVar3 ) - ( p10_nodeVar2.x * p10_nodeVar4 ) ) );
	p10_nodeVar6 = vec2<f32>( 0.0, 0.0 );
	p10_nodeVar7 = vec2<f32>( 0.0, 0.0 );
	p10_nodeVar8 = 1.0;

	if ( ( f32(knobs.pattern) < 0.5 ) ) {


		if ( ( f32(knobs.profile) > 0.5 ) ) {


			if ( ( ( fract( ( p10_nodeVar5.x / f32(knobs.cellSize) ) ) - 0.5 ) < 0.0 ) ) {

				p10_nodeVar10 = -1.0;

			} else {

				p10_nodeVar10 = 1.0;

			}

			p10_nodeVar9 = ( ( p10_nodeVar10 * 0.9 ) * 0.5 );

		} else {

			p10_nodeVar9 = ( ( fract( ( p10_nodeVar5.x / f32(knobs.cellSize) ) ) - 0.5 ) * 2.0 );

		}

		p10_nodeVar6 = vec2<f32>( p10_nodeVar9, 0.0 );

		if ( ( f32(knobs.profile) > 0.5 ) ) {


			if ( ( ( fract( ( p10_nodeVar5.x / f32(knobs.cellSize) ) ) - 0.5 ) < 0.0 ) ) {

				p10_nodeVar12 = -1.0;

			} else {

				p10_nodeVar12 = 1.0;

			}

			p10_nodeVar11 = ( p10_nodeVar12 * 0.9 );

		} else {

			p10_nodeVar13 = ( fract( ( p10_nodeVar5.x / f32(knobs.cellSize) ) ) - 0.5 );
			p10_nodeVar11 = ( ( p10_nodeVar13 / sqrt( max( ( 0.25 - ( p10_nodeVar13 * p10_nodeVar13 ) ), 0.012 ) ) ) * 0.5 );

		}

		p10_nodeVar7 = vec2<f32>( p10_nodeVar11, 0.0 );
		p10_nodeVar8 = ( 0.5 - abs( ( fract( ( p10_nodeVar5.x / f32(knobs.cellSize) ) ) - 0.5 ) ) );
		

	} else {


		if ( ( f32(knobs.pattern) < 1.5 ) ) {

			p10_nodeVar15 = ( p10_nodeVar5 / vec2<f32>( f32(knobs.cellSize) ) );
			p10_nodeVar16 = floor( p10_nodeVar15 );
			p10_nodeVar17 = ( p10_nodeVar16 + vec2<f32>( 1.0, 1.0 ) );
			p10_nodeVar18 = fract( p10_nodeVar15 );
			p10_nodeVar19 = ( ( vec2<f32>( 1.0, 1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar17, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar17, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar20 = dot( p10_nodeVar19, p10_nodeVar19 );
			p10_nodeVar22 = ( p10_nodeVar16 + vec2<f32>( 0.0, 1.0 ) );
			p10_nodeVar23 = ( ( vec2<f32>( 0.0, 1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar22, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar22, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar24 = dot( p10_nodeVar23, p10_nodeVar23 );
			p10_nodeVar26 = ( p10_nodeVar16 + vec2<f32>( -1.0, 1.0 ) );
			p10_nodeVar27 = ( ( vec2<f32>( -1.0, 1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar26, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar26, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar28 = dot( p10_nodeVar27, p10_nodeVar27 );
			p10_nodeVar30 = ( p10_nodeVar16 + vec2<f32>( 1.0, 0.0 ) );
			p10_nodeVar31 = ( ( vec2<f32>( 1.0, 0.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar30, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar30, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar32 = dot( p10_nodeVar31, p10_nodeVar31 );
			p10_nodeVar34 = ( p10_nodeVar16 + vec2<f32>( 0.0, 0.0 ) );
			p10_nodeVar35 = ( ( vec2<f32>( 0.0, 0.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar34, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar34, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar36 = dot( p10_nodeVar35, p10_nodeVar35 );
			p10_nodeVar38 = ( p10_nodeVar16 + vec2<f32>( -1.0, 0.0 ) );
			p10_nodeVar39 = ( ( vec2<f32>( -1.0, 0.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar38, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar38, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar40 = dot( p10_nodeVar39, p10_nodeVar39 );
			p10_nodeVar42 = ( p10_nodeVar16 + vec2<f32>( 1.0, -1.0 ) );
			p10_nodeVar43 = ( ( vec2<f32>( 1.0, -1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar42, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar42, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar44 = dot( p10_nodeVar43, p10_nodeVar43 );
			p10_nodeVar46 = ( p10_nodeVar16 + vec2<f32>( 0.0, -1.0 ) );
			p10_nodeVar47 = ( ( vec2<f32>( 0.0, -1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar46, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar46, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar48 = dot( p10_nodeVar47, p10_nodeVar47 );
			p10_nodeVar50 = ( p10_nodeVar16 + vec2<f32>( -1.0, -1.0 ) );
			p10_nodeVar51 = ( ( vec2<f32>( -1.0, -1.0 ) + ( ( ( fract( ( sin( vec2<f32>( dot( p10_nodeVar50, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar50, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.irregularity) ) ) + vec2<f32>( 0.5 ) ) ) - p10_nodeVar18 );
			p10_nodeVar52 = dot( p10_nodeVar51, p10_nodeVar51 );
			p10_nodeVar53 = ( p10_nodeVar52 < 8.0 );

			if ( p10_nodeVar53 ) {

				p10_nodeVar49 = p10_nodeVar52;

			} else {

				p10_nodeVar49 = 8.0;

			}

			p10_nodeVar54 = ( p10_nodeVar48 < p10_nodeVar49 );

			if ( p10_nodeVar54 ) {

				p10_nodeVar45 = p10_nodeVar48;

			} else {

				p10_nodeVar45 = p10_nodeVar49;

			}

			p10_nodeVar55 = ( p10_nodeVar44 < p10_nodeVar45 );

			if ( p10_nodeVar55 ) {

				p10_nodeVar41 = p10_nodeVar44;

			} else {

				p10_nodeVar41 = p10_nodeVar45;

			}

			p10_nodeVar56 = ( p10_nodeVar40 < p10_nodeVar41 );

			if ( p10_nodeVar56 ) {

				p10_nodeVar37 = p10_nodeVar40;

			} else {

				p10_nodeVar37 = p10_nodeVar41;

			}

			p10_nodeVar57 = ( p10_nodeVar36 < p10_nodeVar37 );

			if ( p10_nodeVar57 ) {

				p10_nodeVar33 = p10_nodeVar36;

			} else {

				p10_nodeVar33 = p10_nodeVar37;

			}

			p10_nodeVar58 = ( p10_nodeVar32 < p10_nodeVar33 );

			if ( p10_nodeVar58 ) {

				p10_nodeVar29 = p10_nodeVar32;

			} else {

				p10_nodeVar29 = p10_nodeVar33;

			}

			p10_nodeVar59 = ( p10_nodeVar28 < p10_nodeVar29 );

			if ( p10_nodeVar59 ) {

				p10_nodeVar25 = p10_nodeVar28;

			} else {

				p10_nodeVar25 = p10_nodeVar29;

			}

			p10_nodeVar60 = ( p10_nodeVar24 < p10_nodeVar25 );

			if ( p10_nodeVar60 ) {

				p10_nodeVar21 = p10_nodeVar24;

			} else {

				p10_nodeVar21 = p10_nodeVar25;

			}

			p10_nodeVar61 = ( p10_nodeVar20 < p10_nodeVar21 );

			if ( p10_nodeVar61 ) {

				p10_nodeVar14 = p10_nodeVar19;

			} else {


				if ( p10_nodeVar60 ) {

					p10_nodeVar62 = p10_nodeVar23;

				} else {


					if ( p10_nodeVar59 ) {

						p10_nodeVar63 = p10_nodeVar27;

					} else {


						if ( p10_nodeVar58 ) {

							p10_nodeVar64 = p10_nodeVar31;

						} else {


							if ( p10_nodeVar57 ) {

								p10_nodeVar65 = p10_nodeVar35;

							} else {


								if ( p10_nodeVar56 ) {

									p10_nodeVar66 = p10_nodeVar39;

								} else {


									if ( p10_nodeVar55 ) {

										p10_nodeVar67 = p10_nodeVar43;

									} else {


										if ( p10_nodeVar54 ) {

											p10_nodeVar68 = p10_nodeVar47;

										} else {


											if ( p10_nodeVar53 ) {

												p10_nodeVar69 = p10_nodeVar51;

											} else {

												p10_nodeVar69 = vec2<f32>( 0.0, 0.0 );

											}

											p10_nodeVar68 = p10_nodeVar69;

										}

										p10_nodeVar67 = p10_nodeVar68;

									}

									p10_nodeVar66 = p10_nodeVar67;

								}

								p10_nodeVar65 = p10_nodeVar66;

							}

							p10_nodeVar64 = p10_nodeVar65;

						}

						p10_nodeVar63 = p10_nodeVar64;

					}

					p10_nodeVar62 = p10_nodeVar63;

				}

				p10_nodeVar14 = p10_nodeVar62;

			}

			p10_nodeVar70 = ( - p10_nodeVar14 );
			p10_nodeVar6 = ( p10_nodeVar70 * vec2<f32>( 2.0 ) );
			p10_nodeVar7 = ( p10_nodeVar70 * vec2<f32>( 1.6 ) );

			if ( p10_nodeVar61 ) {

				p10_nodeVar71 = p10_nodeVar21;

			} else {


				if ( p10_nodeVar60 ) {

					p10_nodeVar72 = p10_nodeVar25;

				} else {


					if ( p10_nodeVar59 ) {

						p10_nodeVar73 = p10_nodeVar29;

					} else {


						if ( p10_nodeVar58 ) {

							p10_nodeVar74 = p10_nodeVar33;

						} else {


							if ( p10_nodeVar57 ) {

								p10_nodeVar75 = p10_nodeVar37;

							} else {


								if ( p10_nodeVar56 ) {

									p10_nodeVar76 = p10_nodeVar41;

								} else {


									if ( p10_nodeVar55 ) {

										p10_nodeVar77 = p10_nodeVar45;

									} else {


										if ( p10_nodeVar54 ) {

											p10_nodeVar78 = p10_nodeVar49;

										} else {


											if ( p10_nodeVar53 ) {

												p10_nodeVar79 = 8.0;

											} else {

												p10_nodeVar79 = min( 8.0, p10_nodeVar52 );

											}

											p10_nodeVar78 = min( p10_nodeVar79, p10_nodeVar48 );

										}

										p10_nodeVar77 = min( p10_nodeVar78, p10_nodeVar44 );

									}

									p10_nodeVar76 = min( p10_nodeVar77, p10_nodeVar40 );

								}

								p10_nodeVar75 = min( p10_nodeVar76, p10_nodeVar36 );

							}

							p10_nodeVar74 = min( p10_nodeVar75, p10_nodeVar32 );

						}

						p10_nodeVar73 = min( p10_nodeVar74, p10_nodeVar28 );

					}

					p10_nodeVar72 = min( p10_nodeVar73, p10_nodeVar24 );

				}

				p10_nodeVar71 = min( p10_nodeVar72, p10_nodeVar20 );

			}


			if ( p10_nodeVar61 ) {

				p10_nodeVar80 = p10_nodeVar20;

			} else {

				p10_nodeVar80 = p10_nodeVar21;

			}

			p10_nodeVar8 = ( ( sqrt( p10_nodeVar71 ) - sqrt( p10_nodeVar80 ) ) * 0.5 );
			

		} else {


			if ( ( f32(knobs.pattern) < 2.5 ) ) {

				p10_nodeVar81 = ( fract( ( p10_nodeVar5 / vec2<f32>( f32(knobs.cellSize) ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar6 = ( p10_nodeVar81 * vec2<f32>( 2.0 ) );

				if ( ( abs( p10_nodeVar81.x ) > abs( p10_nodeVar81.y ) ) ) {


					if ( ( p10_nodeVar81.x < 0.0 ) ) {

						p10_nodeVar83 = -1.0;

					} else {

						p10_nodeVar83 = 1.0;

					}

					p10_nodeVar82 = vec2<f32>( p10_nodeVar83, 0.0 );

				} else {


					if ( ( p10_nodeVar81.y < 0.0 ) ) {

						p10_nodeVar84 = -1.0;

					} else {

						p10_nodeVar84 = 1.0;

					}

					p10_nodeVar82 = vec2<f32>( 0.0, p10_nodeVar84 );

				}

				p10_nodeVar7 = ( p10_nodeVar82 * vec2<f32>( 0.8 ) );
				p10_nodeVar8 = ( 0.5 - max( abs( p10_nodeVar81.x ), abs( p10_nodeVar81.y ) ) );
				

			} else {


				if ( ( f32(knobs.pattern) < 3.5 ) ) {

					p10_nodeVar86 = ( p10_nodeVar5 / vec2<f32>( f32(knobs.cellSize) ) );
					p10_nodeVar87 = ( p10_nodeVar86 - ( ( floor( ( p10_nodeVar86 / vec2<f32>( 1.0, 1.7320508 ) ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>( 1.0, 1.7320508 ) ) );
					p10_nodeVar88 = ( vec2<f32>( 1.0, 1.7320508 ) * vec2<f32>( 0.5 ) );
					p10_nodeVar89 = ( ( p10_nodeVar86 - ( ( floor( ( ( p10_nodeVar86 - p10_nodeVar88 ) / vec2<f32>( 1.0, 1.7320508 ) ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>( 1.0, 1.7320508 ) ) ) - p10_nodeVar88 );

					if ( ( dot( p10_nodeVar87, p10_nodeVar87 ) < dot( p10_nodeVar89, p10_nodeVar89 ) ) ) {

						p10_nodeVar85 = p10_nodeVar87;

					} else {

						p10_nodeVar85 = p10_nodeVar89;

					}

					p10_nodeVar6 = ( p10_nodeVar85 * vec2<f32>( 2.0 ) );
					p10_nodeVar7 = ( ( p10_nodeVar85 / vec2<f32>( sqrt( max( ( 0.3 - dot( p10_nodeVar85, p10_nodeVar85 ) ), 0.03 ) ) ) ) * vec2<f32>( 0.5 ) );
					p10_nodeVar90 = abs( p10_nodeVar85 );
					p10_nodeVar8 = ( 0.5 - max( dot( p10_nodeVar90, vec2<f32>( 0.5, 0.8660254 ) ), p10_nodeVar90.x ) );
					

				}

				

			}

			

		}

		

	}

	p10_nodeVar91 = vec2<f32>( 0.0, 0.0 );
	p10_nodeVar92 = 1.0;

	if ( ( f32(knobs.frost) > 0.0 ) ) {

		p10_nodeVar93 = ( p10_nodeVar2 / vec2<f32>( f32(knobs.frostSize) ) );
		p10_nodeVar94 = ( p10_nodeVar93 + vec2<f32>( 0.5, 0.0 ) );
		p10_nodeVar95 = floor( p10_nodeVar94 );
		p10_nodeVar96 = fract( ( vec3<f32>( p10_nodeVar95.x, p10_nodeVar95.y, p10_nodeVar95.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar97 = ( p10_nodeVar96 + vec3<f32>( dot( p10_nodeVar96, ( vec3<f32>( p10_nodeVar96.y, p10_nodeVar96.z, p10_nodeVar96.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar98 = ( p10_nodeVar95 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar99 = fract( ( vec3<f32>( p10_nodeVar98.x, p10_nodeVar98.y, p10_nodeVar98.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar100 = ( p10_nodeVar99 + vec3<f32>( dot( p10_nodeVar99, ( vec3<f32>( p10_nodeVar99.y, p10_nodeVar99.z, p10_nodeVar99.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar101 = fract( p10_nodeVar94 );
		p10_nodeVar102 = ( ( p10_nodeVar101 * p10_nodeVar101 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar101 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar103 = ( p10_nodeVar95 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar104 = fract( ( vec3<f32>( p10_nodeVar103.x, p10_nodeVar103.y, p10_nodeVar103.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar105 = ( p10_nodeVar104 + vec3<f32>( dot( p10_nodeVar104, ( vec3<f32>( p10_nodeVar104.y, p10_nodeVar104.z, p10_nodeVar104.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar106 = ( p10_nodeVar95 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar107 = fract( ( vec3<f32>( p10_nodeVar106.x, p10_nodeVar106.y, p10_nodeVar106.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar108 = ( p10_nodeVar107 + vec3<f32>( dot( p10_nodeVar107, ( vec3<f32>( p10_nodeVar107.y, p10_nodeVar107.z, p10_nodeVar107.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar109 = ( p10_nodeVar93 - vec2<f32>( 0.5, 0.0 ) );
		p10_nodeVar110 = floor( p10_nodeVar109 );
		p10_nodeVar111 = fract( ( vec3<f32>( p10_nodeVar110.x, p10_nodeVar110.y, p10_nodeVar110.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar112 = ( p10_nodeVar111 + vec3<f32>( dot( p10_nodeVar111, ( vec3<f32>( p10_nodeVar111.y, p10_nodeVar111.z, p10_nodeVar111.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar113 = ( p10_nodeVar110 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar114 = fract( ( vec3<f32>( p10_nodeVar113.x, p10_nodeVar113.y, p10_nodeVar113.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar115 = ( p10_nodeVar114 + vec3<f32>( dot( p10_nodeVar114, ( vec3<f32>( p10_nodeVar114.y, p10_nodeVar114.z, p10_nodeVar114.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar116 = fract( p10_nodeVar109 );
		p10_nodeVar117 = ( ( p10_nodeVar116 * p10_nodeVar116 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar116 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar118 = ( p10_nodeVar110 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar119 = fract( ( vec3<f32>( p10_nodeVar118.x, p10_nodeVar118.y, p10_nodeVar118.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar120 = ( p10_nodeVar119 + vec3<f32>( dot( p10_nodeVar119, ( vec3<f32>( p10_nodeVar119.y, p10_nodeVar119.z, p10_nodeVar119.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar121 = ( p10_nodeVar110 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar122 = fract( ( vec3<f32>( p10_nodeVar121.x, p10_nodeVar121.y, p10_nodeVar121.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar123 = ( p10_nodeVar122 + vec3<f32>( dot( p10_nodeVar122, ( vec3<f32>( p10_nodeVar122.y, p10_nodeVar122.z, p10_nodeVar122.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar124 = ( p10_nodeVar93 + vec2<f32>( 0.0, 0.5 ) );
		p10_nodeVar125 = floor( p10_nodeVar124 );
		p10_nodeVar126 = fract( ( vec3<f32>( p10_nodeVar125.x, p10_nodeVar125.y, p10_nodeVar125.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar127 = ( p10_nodeVar126 + vec3<f32>( dot( p10_nodeVar126, ( vec3<f32>( p10_nodeVar126.y, p10_nodeVar126.z, p10_nodeVar126.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar128 = ( p10_nodeVar125 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar129 = fract( ( vec3<f32>( p10_nodeVar128.x, p10_nodeVar128.y, p10_nodeVar128.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar130 = ( p10_nodeVar129 + vec3<f32>( dot( p10_nodeVar129, ( vec3<f32>( p10_nodeVar129.y, p10_nodeVar129.z, p10_nodeVar129.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar131 = fract( p10_nodeVar124 );
		p10_nodeVar132 = ( ( p10_nodeVar131 * p10_nodeVar131 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar131 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar133 = ( p10_nodeVar125 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar134 = fract( ( vec3<f32>( p10_nodeVar133.x, p10_nodeVar133.y, p10_nodeVar133.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar135 = ( p10_nodeVar134 + vec3<f32>( dot( p10_nodeVar134, ( vec3<f32>( p10_nodeVar134.y, p10_nodeVar134.z, p10_nodeVar134.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar136 = ( p10_nodeVar125 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar137 = fract( ( vec3<f32>( p10_nodeVar136.x, p10_nodeVar136.y, p10_nodeVar136.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar138 = ( p10_nodeVar137 + vec3<f32>( dot( p10_nodeVar137, ( vec3<f32>( p10_nodeVar137.y, p10_nodeVar137.z, p10_nodeVar137.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar139 = ( p10_nodeVar93 - vec2<f32>( 0.0, 0.5 ) );
		p10_nodeVar140 = floor( p10_nodeVar139 );
		p10_nodeVar141 = fract( ( vec3<f32>( p10_nodeVar140.x, p10_nodeVar140.y, p10_nodeVar140.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar142 = ( p10_nodeVar141 + vec3<f32>( dot( p10_nodeVar141, ( vec3<f32>( p10_nodeVar141.y, p10_nodeVar141.z, p10_nodeVar141.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar143 = ( p10_nodeVar140 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar144 = fract( ( vec3<f32>( p10_nodeVar143.x, p10_nodeVar143.y, p10_nodeVar143.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar145 = ( p10_nodeVar144 + vec3<f32>( dot( p10_nodeVar144, ( vec3<f32>( p10_nodeVar144.y, p10_nodeVar144.z, p10_nodeVar144.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar146 = fract( p10_nodeVar139 );
		p10_nodeVar147 = ( ( p10_nodeVar146 * p10_nodeVar146 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar146 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar148 = ( p10_nodeVar140 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar149 = fract( ( vec3<f32>( p10_nodeVar148.x, p10_nodeVar148.y, p10_nodeVar148.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar150 = ( p10_nodeVar149 + vec3<f32>( dot( p10_nodeVar149, ( vec3<f32>( p10_nodeVar149.y, p10_nodeVar149.z, p10_nodeVar149.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar151 = ( p10_nodeVar140 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar152 = fract( ( vec3<f32>( p10_nodeVar151.x, p10_nodeVar151.y, p10_nodeVar151.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar153 = ( p10_nodeVar152 + vec3<f32>( dot( p10_nodeVar152, ( vec3<f32>( p10_nodeVar152.y, p10_nodeVar152.z, p10_nodeVar152.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar91 = ( ( vec2<f32>( ( mix( mix( fract( ( ( p10_nodeVar97.x + p10_nodeVar97.y ) * p10_nodeVar97.z ) ), fract( ( ( p10_nodeVar100.x + p10_nodeVar100.y ) * p10_nodeVar100.z ) ), p10_nodeVar102.x ), mix( fract( ( ( p10_nodeVar105.x + p10_nodeVar105.y ) * p10_nodeVar105.z ) ), fract( ( ( p10_nodeVar108.x + p10_nodeVar108.y ) * p10_nodeVar108.z ) ), p10_nodeVar102.x ), p10_nodeVar102.y ) - mix( mix( fract( ( ( p10_nodeVar112.x + p10_nodeVar112.y ) * p10_nodeVar112.z ) ), fract( ( ( p10_nodeVar115.x + p10_nodeVar115.y ) * p10_nodeVar115.z ) ), p10_nodeVar117.x ), mix( fract( ( ( p10_nodeVar120.x + p10_nodeVar120.y ) * p10_nodeVar120.z ) ), fract( ( ( p10_nodeVar123.x + p10_nodeVar123.y ) * p10_nodeVar123.z ) ), p10_nodeVar117.x ), p10_nodeVar117.y ) ), ( mix( mix( fract( ( ( p10_nodeVar127.x + p10_nodeVar127.y ) * p10_nodeVar127.z ) ), fract( ( ( p10_nodeVar130.x + p10_nodeVar130.y ) * p10_nodeVar130.z ) ), p10_nodeVar132.x ), mix( fract( ( ( p10_nodeVar135.x + p10_nodeVar135.y ) * p10_nodeVar135.z ) ), fract( ( ( p10_nodeVar138.x + p10_nodeVar138.y ) * p10_nodeVar138.z ) ), p10_nodeVar132.x ), p10_nodeVar132.y ) - mix( mix( fract( ( ( p10_nodeVar142.x + p10_nodeVar142.y ) * p10_nodeVar142.z ) ), fract( ( ( p10_nodeVar145.x + p10_nodeVar145.y ) * p10_nodeVar145.z ) ), p10_nodeVar147.x ), mix( fract( ( ( p10_nodeVar150.x + p10_nodeVar150.y ) * p10_nodeVar150.z ) ), fract( ( ( p10_nodeVar153.x + p10_nodeVar153.y ) * p10_nodeVar153.z ) ), p10_nodeVar147.x ), p10_nodeVar147.y ) ) ) * vec2<f32>( f32(knobs.frost) ) ) * vec2<f32>( 1.2 ) );
		p10_nodeVar154 = ( ( p10_nodeVar93 * vec2<f32>( 1.7 ) ) + vec2<f32>( 11.3 ) );
		p10_nodeVar155 = floor( p10_nodeVar154 );
		p10_nodeVar156 = fract( ( vec3<f32>( p10_nodeVar155.x, p10_nodeVar155.y, p10_nodeVar155.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar157 = ( p10_nodeVar156 + vec3<f32>( dot( p10_nodeVar156, ( vec3<f32>( p10_nodeVar156.y, p10_nodeVar156.z, p10_nodeVar156.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar158 = ( p10_nodeVar155 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar159 = fract( ( vec3<f32>( p10_nodeVar158.x, p10_nodeVar158.y, p10_nodeVar158.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar160 = ( p10_nodeVar159 + vec3<f32>( dot( p10_nodeVar159, ( vec3<f32>( p10_nodeVar159.y, p10_nodeVar159.z, p10_nodeVar159.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar161 = fract( p10_nodeVar154 );
		p10_nodeVar162 = ( ( p10_nodeVar161 * p10_nodeVar161 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar161 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar163 = ( p10_nodeVar155 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar164 = fract( ( vec3<f32>( p10_nodeVar163.x, p10_nodeVar163.y, p10_nodeVar163.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar165 = ( p10_nodeVar164 + vec3<f32>( dot( p10_nodeVar164, ( vec3<f32>( p10_nodeVar164.y, p10_nodeVar164.z, p10_nodeVar164.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar166 = ( p10_nodeVar155 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar167 = fract( ( vec3<f32>( p10_nodeVar166.x, p10_nodeVar166.y, p10_nodeVar166.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar168 = ( p10_nodeVar167 + vec3<f32>( dot( p10_nodeVar167, ( vec3<f32>( p10_nodeVar167.y, p10_nodeVar167.z, p10_nodeVar167.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar92 = ( 1.0 + ( ( ( mix( mix( fract( ( ( p10_nodeVar157.x + p10_nodeVar157.y ) * p10_nodeVar157.z ) ), fract( ( ( p10_nodeVar160.x + p10_nodeVar160.y ) * p10_nodeVar160.z ) ), p10_nodeVar162.x ), mix( fract( ( ( p10_nodeVar165.x + p10_nodeVar165.y ) * p10_nodeVar165.z ) ), fract( ( ( p10_nodeVar168.x + p10_nodeVar168.y ) * p10_nodeVar168.z ) ), p10_nodeVar162.x ), p10_nodeVar162.y ) - 0.5 ) * f32(knobs.frost) ) * 0.14 ) );
		

	}

	p10_nodeVar169 = ( ( ( ( p10_nodeVar6 * vec2<f32>( f32(knobs.refraction) ) ) * vec2<f32>( f32(knobs.cellSize) ) ) * vec2<f32>( -1.0 ) ) + ( ( ( p10_nodeVar91 * vec2<f32>( f32(knobs.frostSize) ) ) * vec2<f32>( f32(knobs.frost) ) ) * vec2<f32>( 2.0 ) ) );
	p10_nodeVar170 = ( vec2<f32>( ( ( p10_nodeVar169.x * p10_nodeVar3 ) - ( p10_nodeVar169.y * p10_nodeVar4 ) ), ( ( p10_nodeVar169.x * p10_nodeVar4 ) + ( p10_nodeVar169.y * p10_nodeVar3 ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p10_nodeVar171 = ( p10_nodeVar1 + p10_nodeVar170 );
	p10_nodeVar172 = 1.0;

	if ( ( ( f32(knobs.distanceFrom) > 0.5 ) && ( f32(0.0) > 0.5 ) ) ) {

		p10_nodeVar173 = picture_read_level( p10_nodeVar171, 0.0 );
		p10_nodeVar172 = ( 1.0 - p10_nodeVar173.x );
		

	}

	p10_nodeVar174 = log2( max( ( ( ( ( f32(knobs.distance) * p10_nodeVar172 ) + ( f32(knobs.frost) * 6.0 ) ) * f32(1.0) ) / 1.2 ), 1.0 ) );
	p10_nodeVar175 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
	p10_nodeVar176 = clamp( p10_nodeVar174, 0.0, 10.0 );
	p10_nodeVar177 = floor( p10_nodeVar176 );
	p10_nodeVar178 = ( p10_nodeVar176 - p10_nodeVar177 );

	if ( ( p10_nodeVar177 == 0.0 ) ) {

		p10_nodeVar179 = picture_read_level( p10_nodeVar171, 0.0 );
		p10_nodeVar175 = vec4<f32>( ( vec3<f32>( p10_nodeVar179.x, p10_nodeVar179.y, p10_nodeVar179.z ) * vec3<f32>( p10_nodeVar179.w ) ), p10_nodeVar179.w );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar180 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar181 = floor( p10_nodeVar180 );
			p10_nodeVar182 = ( p10_nodeVar180 - p10_nodeVar181 );
			p10_nodeVar183 = ( p10_nodeVar182 * p10_nodeVar182 );
			p10_nodeVar184 = ( p10_nodeVar183 * p10_nodeVar182 );
			p10_nodeVar185 = ( ( ( ( p10_nodeVar184 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar183 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar186 = ( ( ( p10_nodeVar181 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar185 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar182 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar182 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar182 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar185 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar187 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar186.x, p10_nodeVar186.y ), 0.0 );
			p10_nodeVar188 = ( p10_nodeVar184 / vec2<f32>( 6.0 ) );
			p10_nodeVar189 = ( ( ( ( ( ( p10_nodeVar184 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar183 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar182 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar188 );
			p10_nodeVar190 = ( ( ( p10_nodeVar181 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar188 / p10_nodeVar189 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar191 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar190.x, p10_nodeVar186.y ), 0.0 );
			p10_nodeVar192 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar186.x, p10_nodeVar190.y ), 0.0 );
			p10_nodeVar193 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar190.x, p10_nodeVar190.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar187, p10_nodeVar191, p10_nodeVar189.x ), mix( p10_nodeVar192, p10_nodeVar193, p10_nodeVar189.x ), p10_nodeVar189.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 1.0 ) ) {

		p10_nodeVar194 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar195 = floor( p10_nodeVar194 );
		p10_nodeVar196 = ( p10_nodeVar194 - p10_nodeVar195 );
		p10_nodeVar197 = ( p10_nodeVar196 * p10_nodeVar196 );
		p10_nodeVar198 = ( p10_nodeVar197 * p10_nodeVar196 );
		p10_nodeVar199 = ( ( ( ( p10_nodeVar198 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar197 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar200 = ( ( ( p10_nodeVar195 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar199 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar196 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar196 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar196 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar199 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar201 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar200.x, p10_nodeVar200.y ), 0.0 );
		p10_nodeVar202 = ( p10_nodeVar198 / vec2<f32>( 6.0 ) );
		p10_nodeVar203 = ( ( ( ( ( ( p10_nodeVar198 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar197 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar196 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar202 );
		p10_nodeVar204 = ( ( ( p10_nodeVar195 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar202 / p10_nodeVar203 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar205 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar204.x, p10_nodeVar200.y ), 0.0 );
		p10_nodeVar206 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar200.x, p10_nodeVar204.y ), 0.0 );
		p10_nodeVar207 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar204.x, p10_nodeVar204.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar201, p10_nodeVar205, p10_nodeVar203.x ), mix( p10_nodeVar206, p10_nodeVar207, p10_nodeVar203.x ), p10_nodeVar203.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar208 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar209 = floor( p10_nodeVar208 );
			p10_nodeVar210 = ( p10_nodeVar208 - p10_nodeVar209 );
			p10_nodeVar211 = ( p10_nodeVar210 * p10_nodeVar210 );
			p10_nodeVar212 = ( p10_nodeVar211 * p10_nodeVar210 );
			p10_nodeVar213 = ( ( ( ( p10_nodeVar212 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar211 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar214 = ( ( ( p10_nodeVar209 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar213 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar210 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar210 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar210 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar213 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar215 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar214.x, p10_nodeVar214.y ), 0.0 );
			p10_nodeVar216 = ( p10_nodeVar212 / vec2<f32>( 6.0 ) );
			p10_nodeVar217 = ( ( ( ( ( ( p10_nodeVar212 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar211 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar210 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar216 );
			p10_nodeVar218 = ( ( ( p10_nodeVar209 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar216 / p10_nodeVar217 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar219 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar218.x, p10_nodeVar214.y ), 0.0 );
			p10_nodeVar220 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar214.x, p10_nodeVar218.y ), 0.0 );
			p10_nodeVar221 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar218.x, p10_nodeVar218.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar215, p10_nodeVar219, p10_nodeVar217.x ), mix( p10_nodeVar220, p10_nodeVar221, p10_nodeVar217.x ), p10_nodeVar217.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 2.0 ) ) {

		p10_nodeVar222 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar223 = floor( p10_nodeVar222 );
		p10_nodeVar224 = ( p10_nodeVar222 - p10_nodeVar223 );
		p10_nodeVar225 = ( p10_nodeVar224 * p10_nodeVar224 );
		p10_nodeVar226 = ( p10_nodeVar225 * p10_nodeVar224 );
		p10_nodeVar227 = ( ( ( ( p10_nodeVar226 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar225 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar228 = ( ( ( p10_nodeVar223 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar227 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar224 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar224 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar224 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar227 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar229 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar228.x, p10_nodeVar228.y ), 0.0 );
		p10_nodeVar230 = ( p10_nodeVar226 / vec2<f32>( 6.0 ) );
		p10_nodeVar231 = ( ( ( ( ( ( p10_nodeVar226 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar225 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar224 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar230 );
		p10_nodeVar232 = ( ( ( p10_nodeVar223 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar230 / p10_nodeVar231 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar233 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar232.x, p10_nodeVar228.y ), 0.0 );
		p10_nodeVar234 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar228.x, p10_nodeVar232.y ), 0.0 );
		p10_nodeVar235 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar232.x, p10_nodeVar232.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar229, p10_nodeVar233, p10_nodeVar231.x ), mix( p10_nodeVar234, p10_nodeVar235, p10_nodeVar231.x ), p10_nodeVar231.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar236 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar237 = floor( p10_nodeVar236 );
			p10_nodeVar238 = ( p10_nodeVar236 - p10_nodeVar237 );
			p10_nodeVar239 = ( p10_nodeVar238 * p10_nodeVar238 );
			p10_nodeVar240 = ( p10_nodeVar239 * p10_nodeVar238 );
			p10_nodeVar241 = ( ( ( ( p10_nodeVar240 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar239 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar242 = ( ( ( p10_nodeVar237 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar241 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar238 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar238 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar238 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar241 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar243 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar242.x, p10_nodeVar242.y ), 0.0 );
			p10_nodeVar244 = ( p10_nodeVar240 / vec2<f32>( 6.0 ) );
			p10_nodeVar245 = ( ( ( ( ( ( p10_nodeVar240 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar239 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar238 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar244 );
			p10_nodeVar246 = ( ( ( p10_nodeVar237 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar244 / p10_nodeVar245 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar247 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar246.x, p10_nodeVar242.y ), 0.0 );
			p10_nodeVar248 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar242.x, p10_nodeVar246.y ), 0.0 );
			p10_nodeVar249 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar246.x, p10_nodeVar246.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar243, p10_nodeVar247, p10_nodeVar245.x ), mix( p10_nodeVar248, p10_nodeVar249, p10_nodeVar245.x ), p10_nodeVar245.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 3.0 ) ) {

		p10_nodeVar250 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar251 = floor( p10_nodeVar250 );
		p10_nodeVar252 = ( p10_nodeVar250 - p10_nodeVar251 );
		p10_nodeVar253 = ( p10_nodeVar252 * p10_nodeVar252 );
		p10_nodeVar254 = ( p10_nodeVar253 * p10_nodeVar252 );
		p10_nodeVar255 = ( ( ( ( p10_nodeVar254 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar253 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar256 = ( ( ( p10_nodeVar251 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar255 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar252 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar252 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar252 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar255 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar257 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar256.x, p10_nodeVar256.y ), 0.0 );
		p10_nodeVar258 = ( p10_nodeVar254 / vec2<f32>( 6.0 ) );
		p10_nodeVar259 = ( ( ( ( ( ( p10_nodeVar254 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar253 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar252 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar258 );
		p10_nodeVar260 = ( ( ( p10_nodeVar251 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar258 / p10_nodeVar259 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar261 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar260.x, p10_nodeVar256.y ), 0.0 );
		p10_nodeVar262 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar256.x, p10_nodeVar260.y ), 0.0 );
		p10_nodeVar263 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar260.x, p10_nodeVar260.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar257, p10_nodeVar261, p10_nodeVar259.x ), mix( p10_nodeVar262, p10_nodeVar263, p10_nodeVar259.x ), p10_nodeVar259.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar264 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar265 = floor( p10_nodeVar264 );
			p10_nodeVar266 = ( p10_nodeVar264 - p10_nodeVar265 );
			p10_nodeVar267 = ( p10_nodeVar266 * p10_nodeVar266 );
			p10_nodeVar268 = ( p10_nodeVar267 * p10_nodeVar266 );
			p10_nodeVar269 = ( ( ( ( p10_nodeVar268 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar267 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar270 = ( ( ( p10_nodeVar265 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar269 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar266 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar266 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar266 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar269 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar271 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar270.x, p10_nodeVar270.y ), 0.0 );
			p10_nodeVar272 = ( p10_nodeVar268 / vec2<f32>( 6.0 ) );
			p10_nodeVar273 = ( ( ( ( ( ( p10_nodeVar268 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar267 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar266 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar272 );
			p10_nodeVar274 = ( ( ( p10_nodeVar265 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar272 / p10_nodeVar273 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar275 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar274.x, p10_nodeVar270.y ), 0.0 );
			p10_nodeVar276 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar270.x, p10_nodeVar274.y ), 0.0 );
			p10_nodeVar277 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar274.x, p10_nodeVar274.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar271, p10_nodeVar275, p10_nodeVar273.x ), mix( p10_nodeVar276, p10_nodeVar277, p10_nodeVar273.x ), p10_nodeVar273.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 4.0 ) ) {

		p10_nodeVar278 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar279 = floor( p10_nodeVar278 );
		p10_nodeVar280 = ( p10_nodeVar278 - p10_nodeVar279 );
		p10_nodeVar281 = ( p10_nodeVar280 * p10_nodeVar280 );
		p10_nodeVar282 = ( p10_nodeVar281 * p10_nodeVar280 );
		p10_nodeVar283 = ( ( ( ( p10_nodeVar282 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar281 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar284 = ( ( ( p10_nodeVar279 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar283 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar280 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar280 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar280 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar283 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar285 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar284.x, p10_nodeVar284.y ), 0.0 );
		p10_nodeVar286 = ( p10_nodeVar282 / vec2<f32>( 6.0 ) );
		p10_nodeVar287 = ( ( ( ( ( ( p10_nodeVar282 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar281 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar280 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar286 );
		p10_nodeVar288 = ( ( ( p10_nodeVar279 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar286 / p10_nodeVar287 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar289 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar288.x, p10_nodeVar284.y ), 0.0 );
		p10_nodeVar290 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar284.x, p10_nodeVar288.y ), 0.0 );
		p10_nodeVar291 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar288.x, p10_nodeVar288.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar285, p10_nodeVar289, p10_nodeVar287.x ), mix( p10_nodeVar290, p10_nodeVar291, p10_nodeVar287.x ), p10_nodeVar287.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar292 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar293 = floor( p10_nodeVar292 );
			p10_nodeVar294 = ( p10_nodeVar292 - p10_nodeVar293 );
			p10_nodeVar295 = ( p10_nodeVar294 * p10_nodeVar294 );
			p10_nodeVar296 = ( p10_nodeVar295 * p10_nodeVar294 );
			p10_nodeVar297 = ( ( ( ( p10_nodeVar296 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar295 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar298 = ( ( ( p10_nodeVar293 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar297 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar297 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar299 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar298.x, p10_nodeVar298.y ), 0.0 );
			p10_nodeVar300 = ( p10_nodeVar296 / vec2<f32>( 6.0 ) );
			p10_nodeVar301 = ( ( ( ( ( ( p10_nodeVar296 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar295 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar294 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar300 );
			p10_nodeVar302 = ( ( ( p10_nodeVar293 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar300 / p10_nodeVar301 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar303 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar302.x, p10_nodeVar298.y ), 0.0 );
			p10_nodeVar304 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar298.x, p10_nodeVar302.y ), 0.0 );
			p10_nodeVar305 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar302.x, p10_nodeVar302.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar299, p10_nodeVar303, p10_nodeVar301.x ), mix( p10_nodeVar304, p10_nodeVar305, p10_nodeVar301.x ), p10_nodeVar301.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 5.0 ) ) {

		p10_nodeVar306 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar307 = floor( p10_nodeVar306 );
		p10_nodeVar308 = ( p10_nodeVar306 - p10_nodeVar307 );
		p10_nodeVar309 = ( p10_nodeVar308 * p10_nodeVar308 );
		p10_nodeVar310 = ( p10_nodeVar309 * p10_nodeVar308 );
		p10_nodeVar311 = ( ( ( ( p10_nodeVar310 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar309 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar312 = ( ( ( p10_nodeVar307 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar311 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar308 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar308 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar308 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar311 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar313 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar312.x, p10_nodeVar312.y ), 0.0 );
		p10_nodeVar314 = ( p10_nodeVar310 / vec2<f32>( 6.0 ) );
		p10_nodeVar315 = ( ( ( ( ( ( p10_nodeVar310 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar309 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar308 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar314 );
		p10_nodeVar316 = ( ( ( p10_nodeVar307 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar314 / p10_nodeVar315 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar317 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar316.x, p10_nodeVar312.y ), 0.0 );
		p10_nodeVar318 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar312.x, p10_nodeVar316.y ), 0.0 );
		p10_nodeVar319 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar316.x, p10_nodeVar316.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar313, p10_nodeVar317, p10_nodeVar315.x ), mix( p10_nodeVar318, p10_nodeVar319, p10_nodeVar315.x ), p10_nodeVar315.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar320 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar321 = floor( p10_nodeVar320 );
			p10_nodeVar322 = ( p10_nodeVar320 - p10_nodeVar321 );
			p10_nodeVar323 = ( p10_nodeVar322 * p10_nodeVar322 );
			p10_nodeVar324 = ( p10_nodeVar323 * p10_nodeVar322 );
			p10_nodeVar325 = ( ( ( ( p10_nodeVar324 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar323 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar326 = ( ( ( p10_nodeVar321 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar325 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar322 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar322 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar322 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar325 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar327 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar326.x, p10_nodeVar326.y ), 0.0 );
			p10_nodeVar328 = ( p10_nodeVar324 / vec2<f32>( 6.0 ) );
			p10_nodeVar329 = ( ( ( ( ( ( p10_nodeVar324 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar323 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar322 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar328 );
			p10_nodeVar330 = ( ( ( p10_nodeVar321 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar328 / p10_nodeVar329 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar331 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar330.x, p10_nodeVar326.y ), 0.0 );
			p10_nodeVar332 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar326.x, p10_nodeVar330.y ), 0.0 );
			p10_nodeVar333 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar330.x, p10_nodeVar330.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar327, p10_nodeVar331, p10_nodeVar329.x ), mix( p10_nodeVar332, p10_nodeVar333, p10_nodeVar329.x ), p10_nodeVar329.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 6.0 ) ) {

		p10_nodeVar334 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar335 = floor( p10_nodeVar334 );
		p10_nodeVar336 = ( p10_nodeVar334 - p10_nodeVar335 );
		p10_nodeVar337 = ( p10_nodeVar336 * p10_nodeVar336 );
		p10_nodeVar338 = ( p10_nodeVar337 * p10_nodeVar336 );
		p10_nodeVar339 = ( ( ( ( p10_nodeVar338 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar337 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar340 = ( ( ( p10_nodeVar335 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar339 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar336 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar336 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar336 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar339 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar341 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar340.x, p10_nodeVar340.y ), 0.0 );
		p10_nodeVar342 = ( p10_nodeVar338 / vec2<f32>( 6.0 ) );
		p10_nodeVar343 = ( ( ( ( ( ( p10_nodeVar338 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar337 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar336 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar342 );
		p10_nodeVar344 = ( ( ( p10_nodeVar335 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar342 / p10_nodeVar343 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar345 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar344.x, p10_nodeVar340.y ), 0.0 );
		p10_nodeVar346 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar340.x, p10_nodeVar344.y ), 0.0 );
		p10_nodeVar347 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar344.x, p10_nodeVar344.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar341, p10_nodeVar345, p10_nodeVar343.x ), mix( p10_nodeVar346, p10_nodeVar347, p10_nodeVar343.x ), p10_nodeVar343.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar348 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar349 = floor( p10_nodeVar348 );
			p10_nodeVar350 = ( p10_nodeVar348 - p10_nodeVar349 );
			p10_nodeVar351 = ( p10_nodeVar350 * p10_nodeVar350 );
			p10_nodeVar352 = ( p10_nodeVar351 * p10_nodeVar350 );
			p10_nodeVar353 = ( ( ( ( p10_nodeVar352 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar351 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar354 = ( ( ( p10_nodeVar349 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar353 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar350 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar350 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar350 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar353 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar355 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar354.x, p10_nodeVar354.y ), 0.0 );
			p10_nodeVar356 = ( p10_nodeVar352 / vec2<f32>( 6.0 ) );
			p10_nodeVar357 = ( ( ( ( ( ( p10_nodeVar352 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar351 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar350 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar356 );
			p10_nodeVar358 = ( ( ( p10_nodeVar349 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar356 / p10_nodeVar357 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar359 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar358.x, p10_nodeVar354.y ), 0.0 );
			p10_nodeVar360 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar354.x, p10_nodeVar358.y ), 0.0 );
			p10_nodeVar361 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar358.x, p10_nodeVar358.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar355, p10_nodeVar359, p10_nodeVar357.x ), mix( p10_nodeVar360, p10_nodeVar361, p10_nodeVar357.x ), p10_nodeVar357.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 7.0 ) ) {

		p10_nodeVar362 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar363 = floor( p10_nodeVar362 );
		p10_nodeVar364 = ( p10_nodeVar362 - p10_nodeVar363 );
		p10_nodeVar365 = ( p10_nodeVar364 * p10_nodeVar364 );
		p10_nodeVar366 = ( p10_nodeVar365 * p10_nodeVar364 );
		p10_nodeVar367 = ( ( ( ( p10_nodeVar366 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar365 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar368 = ( ( ( p10_nodeVar363 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar367 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar364 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar364 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar364 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar367 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar369 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar368.x, p10_nodeVar368.y ), 0.0 );
		p10_nodeVar370 = ( p10_nodeVar366 / vec2<f32>( 6.0 ) );
		p10_nodeVar371 = ( ( ( ( ( ( p10_nodeVar366 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar365 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar364 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar370 );
		p10_nodeVar372 = ( ( ( p10_nodeVar363 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar370 / p10_nodeVar371 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar373 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar372.x, p10_nodeVar368.y ), 0.0 );
		p10_nodeVar374 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar368.x, p10_nodeVar372.y ), 0.0 );
		p10_nodeVar375 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar372.x, p10_nodeVar372.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar369, p10_nodeVar373, p10_nodeVar371.x ), mix( p10_nodeVar374, p10_nodeVar375, p10_nodeVar371.x ), p10_nodeVar371.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar376 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar377 = floor( p10_nodeVar376 );
			p10_nodeVar378 = ( p10_nodeVar376 - p10_nodeVar377 );
			p10_nodeVar379 = ( p10_nodeVar378 * p10_nodeVar378 );
			p10_nodeVar380 = ( p10_nodeVar379 * p10_nodeVar378 );
			p10_nodeVar381 = ( ( ( ( p10_nodeVar380 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar379 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar382 = ( ( ( p10_nodeVar377 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar381 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar378 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar378 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar378 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar381 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar383 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar382.x, p10_nodeVar382.y ), 0.0 );
			p10_nodeVar384 = ( p10_nodeVar380 / vec2<f32>( 6.0 ) );
			p10_nodeVar385 = ( ( ( ( ( ( p10_nodeVar380 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar379 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar378 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar384 );
			p10_nodeVar386 = ( ( ( p10_nodeVar377 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar384 / p10_nodeVar385 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar387 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar386.x, p10_nodeVar382.y ), 0.0 );
			p10_nodeVar388 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar382.x, p10_nodeVar386.y ), 0.0 );
			p10_nodeVar389 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar386.x, p10_nodeVar386.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar383, p10_nodeVar387, p10_nodeVar385.x ), mix( p10_nodeVar388, p10_nodeVar389, p10_nodeVar385.x ), p10_nodeVar385.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 8.0 ) ) {

		p10_nodeVar390 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar391 = floor( p10_nodeVar390 );
		p10_nodeVar392 = ( p10_nodeVar390 - p10_nodeVar391 );
		p10_nodeVar393 = ( p10_nodeVar392 * p10_nodeVar392 );
		p10_nodeVar394 = ( p10_nodeVar393 * p10_nodeVar392 );
		p10_nodeVar395 = ( ( ( ( p10_nodeVar394 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar393 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar396 = ( ( ( p10_nodeVar391 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar395 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar392 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar392 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar392 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar395 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar397 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar396.x, p10_nodeVar396.y ), 0.0 );
		p10_nodeVar398 = ( p10_nodeVar394 / vec2<f32>( 6.0 ) );
		p10_nodeVar399 = ( ( ( ( ( ( p10_nodeVar394 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar393 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar392 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar398 );
		p10_nodeVar400 = ( ( ( p10_nodeVar391 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar398 / p10_nodeVar399 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar401 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar400.x, p10_nodeVar396.y ), 0.0 );
		p10_nodeVar402 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar396.x, p10_nodeVar400.y ), 0.0 );
		p10_nodeVar403 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar400.x, p10_nodeVar400.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar397, p10_nodeVar401, p10_nodeVar399.x ), mix( p10_nodeVar402, p10_nodeVar403, p10_nodeVar399.x ), p10_nodeVar399.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar404 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar405 = floor( p10_nodeVar404 );
			p10_nodeVar406 = ( p10_nodeVar404 - p10_nodeVar405 );
			p10_nodeVar407 = ( p10_nodeVar406 * p10_nodeVar406 );
			p10_nodeVar408 = ( p10_nodeVar407 * p10_nodeVar406 );
			p10_nodeVar409 = ( ( ( ( p10_nodeVar408 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar407 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar410 = ( ( ( p10_nodeVar405 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar409 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar406 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar406 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar406 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar409 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar411 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar410.x, p10_nodeVar410.y ), 0.0 );
			p10_nodeVar412 = ( p10_nodeVar408 / vec2<f32>( 6.0 ) );
			p10_nodeVar413 = ( ( ( ( ( ( p10_nodeVar408 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar407 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar406 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar412 );
			p10_nodeVar414 = ( ( ( p10_nodeVar405 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar412 / p10_nodeVar413 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar415 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar414.x, p10_nodeVar410.y ), 0.0 );
			p10_nodeVar416 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar410.x, p10_nodeVar414.y ), 0.0 );
			p10_nodeVar417 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar414.x, p10_nodeVar414.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar411, p10_nodeVar415, p10_nodeVar413.x ), mix( p10_nodeVar416, p10_nodeVar417, p10_nodeVar413.x ), p10_nodeVar413.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 == 9.0 ) ) {

		p10_nodeVar418 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar419 = floor( p10_nodeVar418 );
		p10_nodeVar420 = ( p10_nodeVar418 - p10_nodeVar419 );
		p10_nodeVar421 = ( p10_nodeVar420 * p10_nodeVar420 );
		p10_nodeVar422 = ( p10_nodeVar421 * p10_nodeVar420 );
		p10_nodeVar423 = ( ( ( ( p10_nodeVar422 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar421 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar424 = ( ( ( p10_nodeVar419 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar423 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar420 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar420 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar420 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar423 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar425 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar424.x, p10_nodeVar424.y ), 0.0 );
		p10_nodeVar426 = ( p10_nodeVar422 / vec2<f32>( 6.0 ) );
		p10_nodeVar427 = ( ( ( ( ( ( p10_nodeVar422 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar421 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar420 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar426 );
		p10_nodeVar428 = ( ( ( p10_nodeVar419 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar426 / p10_nodeVar427 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar429 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar428.x, p10_nodeVar424.y ), 0.0 );
		p10_nodeVar430 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar424.x, p10_nodeVar428.y ), 0.0 );
		p10_nodeVar431 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar428.x, p10_nodeVar428.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar425, p10_nodeVar429, p10_nodeVar427.x ), mix( p10_nodeVar430, p10_nodeVar431, p10_nodeVar427.x ), p10_nodeVar427.y );

		if ( ( p10_nodeVar178 > 0.0 ) ) {

			p10_nodeVar432 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar433 = floor( p10_nodeVar432 );
			p10_nodeVar434 = ( p10_nodeVar432 - p10_nodeVar433 );
			p10_nodeVar435 = ( p10_nodeVar434 * p10_nodeVar434 );
			p10_nodeVar436 = ( p10_nodeVar435 * p10_nodeVar434 );
			p10_nodeVar437 = ( ( ( ( p10_nodeVar436 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar435 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar438 = ( ( ( p10_nodeVar433 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar437 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar434 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar434 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar434 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar437 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar439 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar438.x, p10_nodeVar438.y ), 0.0 );
			p10_nodeVar440 = ( p10_nodeVar436 / vec2<f32>( 6.0 ) );
			p10_nodeVar441 = ( ( ( ( ( ( p10_nodeVar436 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar435 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar434 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar440 );
			p10_nodeVar442 = ( ( ( p10_nodeVar433 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar440 / p10_nodeVar441 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar443 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar442.x, p10_nodeVar438.y ), 0.0 );
			p10_nodeVar444 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar438.x, p10_nodeVar442.y ), 0.0 );
			p10_nodeVar445 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar442.x, p10_nodeVar442.y ), 0.0 );
			p10_nodeVar175 = mix( p10_nodeVar175, mix( mix( p10_nodeVar439, p10_nodeVar443, p10_nodeVar441.x ), mix( p10_nodeVar444, p10_nodeVar445, p10_nodeVar441.x ), p10_nodeVar441.y ), p10_nodeVar178 );
			

		}

		

	}


	if ( ( p10_nodeVar177 >= 10.0 ) ) {

		p10_nodeVar446 = ( ( p10_nodeVar171 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar447 = floor( p10_nodeVar446 );
		p10_nodeVar448 = ( p10_nodeVar446 - p10_nodeVar447 );
		p10_nodeVar449 = ( p10_nodeVar448 * p10_nodeVar448 );
		p10_nodeVar450 = ( p10_nodeVar449 * p10_nodeVar448 );
		p10_nodeVar451 = ( ( ( ( p10_nodeVar450 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar449 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar452 = ( ( ( p10_nodeVar447 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar451 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar448 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar448 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar448 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar451 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p10_nodeVar453 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar452.x, p10_nodeVar452.y ), 0.0 );
		p10_nodeVar454 = ( p10_nodeVar450 / vec2<f32>( 6.0 ) );
		p10_nodeVar455 = ( ( ( ( ( ( p10_nodeVar450 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar449 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar448 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar454 );
		p10_nodeVar456 = ( ( ( p10_nodeVar447 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar454 / p10_nodeVar455 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p10_nodeVar457 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar456.x, p10_nodeVar452.y ), 0.0 );
		p10_nodeVar458 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar452.x, p10_nodeVar456.y ), 0.0 );
		p10_nodeVar459 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar456.x, p10_nodeVar456.y ), 0.0 );
		p10_nodeVar175 = mix( mix( p10_nodeVar453, p10_nodeVar457, p10_nodeVar455.x ), mix( p10_nodeVar458, p10_nodeVar459, p10_nodeVar455.x ), p10_nodeVar455.y );
		

	}

	p10_nodeVar460 = max( p10_nodeVar175.w, 0.0001 );
	p10_nodeVar461 = p10_nodeVar175.w;
	p10_nodeVar462 = vec3<f32>( 0.0, 0.0, 0.0 );

	if ( ( f32(knobs.dispersion) > 0.0 ) ) {

		p10_nodeVar463 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p10_nodeVar464 = clamp( p10_nodeVar174, 0.0, 10.0 );
		p10_nodeVar465 = floor( p10_nodeVar464 );
		p10_nodeVar466 = ( p10_nodeVar464 - p10_nodeVar465 );

		if ( ( p10_nodeVar465 == 0.0 ) ) {

			p10_nodeVar467 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar468 = picture_read_level( p10_nodeVar467, 0.0 );
			p10_nodeVar463 = vec4<f32>( ( vec3<f32>( p10_nodeVar468.x, p10_nodeVar468.y, p10_nodeVar468.z ) * vec3<f32>( p10_nodeVar468.w ) ), p10_nodeVar468.w );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar469 = ( ( p10_nodeVar467 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar470 = floor( p10_nodeVar469 );
				p10_nodeVar471 = ( p10_nodeVar469 - p10_nodeVar470 );
				p10_nodeVar472 = ( p10_nodeVar471 * p10_nodeVar471 );
				p10_nodeVar473 = ( p10_nodeVar472 * p10_nodeVar471 );
				p10_nodeVar474 = ( ( ( ( p10_nodeVar473 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar472 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar475 = ( ( ( p10_nodeVar470 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar474 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar471 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar471 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar471 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar474 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar476 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar475.x, p10_nodeVar475.y ), 0.0 );
				p10_nodeVar477 = ( p10_nodeVar473 / vec2<f32>( 6.0 ) );
				p10_nodeVar478 = ( ( ( ( ( ( p10_nodeVar473 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar472 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar471 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar477 );
				p10_nodeVar479 = ( ( ( p10_nodeVar470 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar477 / p10_nodeVar478 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar480 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar479.x, p10_nodeVar475.y ), 0.0 );
				p10_nodeVar481 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar475.x, p10_nodeVar479.y ), 0.0 );
				p10_nodeVar482 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar479.x, p10_nodeVar479.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar476, p10_nodeVar480, p10_nodeVar478.x ), mix( p10_nodeVar481, p10_nodeVar482, p10_nodeVar478.x ), p10_nodeVar478.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 1.0 ) ) {

			p10_nodeVar483 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar484 = ( ( p10_nodeVar483 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar485 = floor( p10_nodeVar484 );
			p10_nodeVar486 = ( p10_nodeVar484 - p10_nodeVar485 );
			p10_nodeVar487 = ( p10_nodeVar486 * p10_nodeVar486 );
			p10_nodeVar488 = ( p10_nodeVar487 * p10_nodeVar486 );
			p10_nodeVar489 = ( ( ( ( p10_nodeVar488 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar487 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar490 = ( ( ( p10_nodeVar485 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar489 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar486 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar486 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar486 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar489 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar491 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar490.x, p10_nodeVar490.y ), 0.0 );
			p10_nodeVar492 = ( p10_nodeVar488 / vec2<f32>( 6.0 ) );
			p10_nodeVar493 = ( ( ( ( ( ( p10_nodeVar488 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar487 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar486 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar492 );
			p10_nodeVar494 = ( ( ( p10_nodeVar485 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar492 / p10_nodeVar493 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar495 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar494.x, p10_nodeVar490.y ), 0.0 );
			p10_nodeVar496 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar490.x, p10_nodeVar494.y ), 0.0 );
			p10_nodeVar497 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar494.x, p10_nodeVar494.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar491, p10_nodeVar495, p10_nodeVar493.x ), mix( p10_nodeVar496, p10_nodeVar497, p10_nodeVar493.x ), p10_nodeVar493.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar498 = ( ( p10_nodeVar483 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar499 = floor( p10_nodeVar498 );
				p10_nodeVar500 = ( p10_nodeVar498 - p10_nodeVar499 );
				p10_nodeVar501 = ( p10_nodeVar500 * p10_nodeVar500 );
				p10_nodeVar502 = ( p10_nodeVar501 * p10_nodeVar500 );
				p10_nodeVar503 = ( ( ( ( p10_nodeVar502 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar501 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar504 = ( ( ( p10_nodeVar499 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar503 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar500 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar500 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar500 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar503 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar505 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar504.x, p10_nodeVar504.y ), 0.0 );
				p10_nodeVar506 = ( p10_nodeVar502 / vec2<f32>( 6.0 ) );
				p10_nodeVar507 = ( ( ( ( ( ( p10_nodeVar502 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar501 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar500 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar506 );
				p10_nodeVar508 = ( ( ( p10_nodeVar499 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar506 / p10_nodeVar507 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar509 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar508.x, p10_nodeVar504.y ), 0.0 );
				p10_nodeVar510 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar504.x, p10_nodeVar508.y ), 0.0 );
				p10_nodeVar511 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar508.x, p10_nodeVar508.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar505, p10_nodeVar509, p10_nodeVar507.x ), mix( p10_nodeVar510, p10_nodeVar511, p10_nodeVar507.x ), p10_nodeVar507.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 2.0 ) ) {

			p10_nodeVar512 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar513 = ( ( p10_nodeVar512 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar514 = floor( p10_nodeVar513 );
			p10_nodeVar515 = ( p10_nodeVar513 - p10_nodeVar514 );
			p10_nodeVar516 = ( p10_nodeVar515 * p10_nodeVar515 );
			p10_nodeVar517 = ( p10_nodeVar516 * p10_nodeVar515 );
			p10_nodeVar518 = ( ( ( ( p10_nodeVar517 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar516 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar519 = ( ( ( p10_nodeVar514 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar518 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar515 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar515 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar515 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar518 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar520 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar519.x, p10_nodeVar519.y ), 0.0 );
			p10_nodeVar521 = ( p10_nodeVar517 / vec2<f32>( 6.0 ) );
			p10_nodeVar522 = ( ( ( ( ( ( p10_nodeVar517 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar516 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar515 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar521 );
			p10_nodeVar523 = ( ( ( p10_nodeVar514 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar521 / p10_nodeVar522 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar524 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar523.x, p10_nodeVar519.y ), 0.0 );
			p10_nodeVar525 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar519.x, p10_nodeVar523.y ), 0.0 );
			p10_nodeVar526 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar523.x, p10_nodeVar523.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar520, p10_nodeVar524, p10_nodeVar522.x ), mix( p10_nodeVar525, p10_nodeVar526, p10_nodeVar522.x ), p10_nodeVar522.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar527 = ( ( p10_nodeVar512 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar528 = floor( p10_nodeVar527 );
				p10_nodeVar529 = ( p10_nodeVar527 - p10_nodeVar528 );
				p10_nodeVar530 = ( p10_nodeVar529 * p10_nodeVar529 );
				p10_nodeVar531 = ( p10_nodeVar530 * p10_nodeVar529 );
				p10_nodeVar532 = ( ( ( ( p10_nodeVar531 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar530 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar533 = ( ( ( p10_nodeVar528 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar532 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar529 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar529 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar529 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar532 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar534 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar533.x, p10_nodeVar533.y ), 0.0 );
				p10_nodeVar535 = ( p10_nodeVar531 / vec2<f32>( 6.0 ) );
				p10_nodeVar536 = ( ( ( ( ( ( p10_nodeVar531 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar530 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar529 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar535 );
				p10_nodeVar537 = ( ( ( p10_nodeVar528 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar535 / p10_nodeVar536 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar538 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar537.x, p10_nodeVar533.y ), 0.0 );
				p10_nodeVar539 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar533.x, p10_nodeVar537.y ), 0.0 );
				p10_nodeVar540 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar537.x, p10_nodeVar537.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar534, p10_nodeVar538, p10_nodeVar536.x ), mix( p10_nodeVar539, p10_nodeVar540, p10_nodeVar536.x ), p10_nodeVar536.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 3.0 ) ) {

			p10_nodeVar541 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar542 = ( ( p10_nodeVar541 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar543 = floor( p10_nodeVar542 );
			p10_nodeVar544 = ( p10_nodeVar542 - p10_nodeVar543 );
			p10_nodeVar545 = ( p10_nodeVar544 * p10_nodeVar544 );
			p10_nodeVar546 = ( p10_nodeVar545 * p10_nodeVar544 );
			p10_nodeVar547 = ( ( ( ( p10_nodeVar546 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar545 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar548 = ( ( ( p10_nodeVar543 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar547 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar544 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar544 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar544 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar547 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar549 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar548.x, p10_nodeVar548.y ), 0.0 );
			p10_nodeVar550 = ( p10_nodeVar546 / vec2<f32>( 6.0 ) );
			p10_nodeVar551 = ( ( ( ( ( ( p10_nodeVar546 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar545 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar544 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar550 );
			p10_nodeVar552 = ( ( ( p10_nodeVar543 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar550 / p10_nodeVar551 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar553 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar552.x, p10_nodeVar548.y ), 0.0 );
			p10_nodeVar554 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar548.x, p10_nodeVar552.y ), 0.0 );
			p10_nodeVar555 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar552.x, p10_nodeVar552.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar549, p10_nodeVar553, p10_nodeVar551.x ), mix( p10_nodeVar554, p10_nodeVar555, p10_nodeVar551.x ), p10_nodeVar551.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar556 = ( ( p10_nodeVar541 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar557 = floor( p10_nodeVar556 );
				p10_nodeVar558 = ( p10_nodeVar556 - p10_nodeVar557 );
				p10_nodeVar559 = ( p10_nodeVar558 * p10_nodeVar558 );
				p10_nodeVar560 = ( p10_nodeVar559 * p10_nodeVar558 );
				p10_nodeVar561 = ( ( ( ( p10_nodeVar560 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar559 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar562 = ( ( ( p10_nodeVar557 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar561 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar558 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar558 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar558 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar561 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar563 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar562.x, p10_nodeVar562.y ), 0.0 );
				p10_nodeVar564 = ( p10_nodeVar560 / vec2<f32>( 6.0 ) );
				p10_nodeVar565 = ( ( ( ( ( ( p10_nodeVar560 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar559 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar558 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar564 );
				p10_nodeVar566 = ( ( ( p10_nodeVar557 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar564 / p10_nodeVar565 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar567 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar566.x, p10_nodeVar562.y ), 0.0 );
				p10_nodeVar568 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar562.x, p10_nodeVar566.y ), 0.0 );
				p10_nodeVar569 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar566.x, p10_nodeVar566.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar563, p10_nodeVar567, p10_nodeVar565.x ), mix( p10_nodeVar568, p10_nodeVar569, p10_nodeVar565.x ), p10_nodeVar565.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 4.0 ) ) {

			p10_nodeVar570 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar571 = ( ( p10_nodeVar570 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar572 = floor( p10_nodeVar571 );
			p10_nodeVar573 = ( p10_nodeVar571 - p10_nodeVar572 );
			p10_nodeVar574 = ( p10_nodeVar573 * p10_nodeVar573 );
			p10_nodeVar575 = ( p10_nodeVar574 * p10_nodeVar573 );
			p10_nodeVar576 = ( ( ( ( p10_nodeVar575 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar574 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar577 = ( ( ( p10_nodeVar572 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar576 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar573 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar573 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar573 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar576 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar578 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar577.x, p10_nodeVar577.y ), 0.0 );
			p10_nodeVar579 = ( p10_nodeVar575 / vec2<f32>( 6.0 ) );
			p10_nodeVar580 = ( ( ( ( ( ( p10_nodeVar575 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar574 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar573 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar579 );
			p10_nodeVar581 = ( ( ( p10_nodeVar572 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar579 / p10_nodeVar580 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar582 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar581.x, p10_nodeVar577.y ), 0.0 );
			p10_nodeVar583 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar577.x, p10_nodeVar581.y ), 0.0 );
			p10_nodeVar584 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar581.x, p10_nodeVar581.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar578, p10_nodeVar582, p10_nodeVar580.x ), mix( p10_nodeVar583, p10_nodeVar584, p10_nodeVar580.x ), p10_nodeVar580.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar585 = ( ( p10_nodeVar570 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar586 = floor( p10_nodeVar585 );
				p10_nodeVar587 = ( p10_nodeVar585 - p10_nodeVar586 );
				p10_nodeVar588 = ( p10_nodeVar587 * p10_nodeVar587 );
				p10_nodeVar589 = ( p10_nodeVar588 * p10_nodeVar587 );
				p10_nodeVar590 = ( ( ( ( p10_nodeVar589 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar588 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar591 = ( ( ( p10_nodeVar586 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar590 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar587 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar587 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar587 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar590 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar592 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar591.x, p10_nodeVar591.y ), 0.0 );
				p10_nodeVar593 = ( p10_nodeVar589 / vec2<f32>( 6.0 ) );
				p10_nodeVar594 = ( ( ( ( ( ( p10_nodeVar589 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar588 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar587 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar593 );
				p10_nodeVar595 = ( ( ( p10_nodeVar586 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar593 / p10_nodeVar594 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar596 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar595.x, p10_nodeVar591.y ), 0.0 );
				p10_nodeVar597 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar591.x, p10_nodeVar595.y ), 0.0 );
				p10_nodeVar598 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar595.x, p10_nodeVar595.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar592, p10_nodeVar596, p10_nodeVar594.x ), mix( p10_nodeVar597, p10_nodeVar598, p10_nodeVar594.x ), p10_nodeVar594.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 5.0 ) ) {

			p10_nodeVar599 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar600 = ( ( p10_nodeVar599 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar601 = floor( p10_nodeVar600 );
			p10_nodeVar602 = ( p10_nodeVar600 - p10_nodeVar601 );
			p10_nodeVar603 = ( p10_nodeVar602 * p10_nodeVar602 );
			p10_nodeVar604 = ( p10_nodeVar603 * p10_nodeVar602 );
			p10_nodeVar605 = ( ( ( ( p10_nodeVar604 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar603 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar606 = ( ( ( p10_nodeVar601 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar605 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar602 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar602 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar602 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar605 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar607 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar606.x, p10_nodeVar606.y ), 0.0 );
			p10_nodeVar608 = ( p10_nodeVar604 / vec2<f32>( 6.0 ) );
			p10_nodeVar609 = ( ( ( ( ( ( p10_nodeVar604 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar603 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar602 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar608 );
			p10_nodeVar610 = ( ( ( p10_nodeVar601 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar608 / p10_nodeVar609 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar611 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar610.x, p10_nodeVar606.y ), 0.0 );
			p10_nodeVar612 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar606.x, p10_nodeVar610.y ), 0.0 );
			p10_nodeVar613 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar610.x, p10_nodeVar610.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar607, p10_nodeVar611, p10_nodeVar609.x ), mix( p10_nodeVar612, p10_nodeVar613, p10_nodeVar609.x ), p10_nodeVar609.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar614 = ( ( p10_nodeVar599 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar615 = floor( p10_nodeVar614 );
				p10_nodeVar616 = ( p10_nodeVar614 - p10_nodeVar615 );
				p10_nodeVar617 = ( p10_nodeVar616 * p10_nodeVar616 );
				p10_nodeVar618 = ( p10_nodeVar617 * p10_nodeVar616 );
				p10_nodeVar619 = ( ( ( ( p10_nodeVar618 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar617 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar620 = ( ( ( p10_nodeVar615 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar619 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar616 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar616 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar616 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar619 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar621 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar620.x, p10_nodeVar620.y ), 0.0 );
				p10_nodeVar622 = ( p10_nodeVar618 / vec2<f32>( 6.0 ) );
				p10_nodeVar623 = ( ( ( ( ( ( p10_nodeVar618 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar617 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar616 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar622 );
				p10_nodeVar624 = ( ( ( p10_nodeVar615 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar622 / p10_nodeVar623 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar625 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar624.x, p10_nodeVar620.y ), 0.0 );
				p10_nodeVar626 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar620.x, p10_nodeVar624.y ), 0.0 );
				p10_nodeVar627 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar624.x, p10_nodeVar624.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar621, p10_nodeVar625, p10_nodeVar623.x ), mix( p10_nodeVar626, p10_nodeVar627, p10_nodeVar623.x ), p10_nodeVar623.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 6.0 ) ) {

			p10_nodeVar628 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar629 = ( ( p10_nodeVar628 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar630 = floor( p10_nodeVar629 );
			p10_nodeVar631 = ( p10_nodeVar629 - p10_nodeVar630 );
			p10_nodeVar632 = ( p10_nodeVar631 * p10_nodeVar631 );
			p10_nodeVar633 = ( p10_nodeVar632 * p10_nodeVar631 );
			p10_nodeVar634 = ( ( ( ( p10_nodeVar633 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar632 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar635 = ( ( ( p10_nodeVar630 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar634 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar631 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar631 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar631 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar634 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar636 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar635.x, p10_nodeVar635.y ), 0.0 );
			p10_nodeVar637 = ( p10_nodeVar633 / vec2<f32>( 6.0 ) );
			p10_nodeVar638 = ( ( ( ( ( ( p10_nodeVar633 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar632 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar631 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar637 );
			p10_nodeVar639 = ( ( ( p10_nodeVar630 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar637 / p10_nodeVar638 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar640 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar639.x, p10_nodeVar635.y ), 0.0 );
			p10_nodeVar641 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar635.x, p10_nodeVar639.y ), 0.0 );
			p10_nodeVar642 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar639.x, p10_nodeVar639.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar636, p10_nodeVar640, p10_nodeVar638.x ), mix( p10_nodeVar641, p10_nodeVar642, p10_nodeVar638.x ), p10_nodeVar638.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar643 = ( ( p10_nodeVar628 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar644 = floor( p10_nodeVar643 );
				p10_nodeVar645 = ( p10_nodeVar643 - p10_nodeVar644 );
				p10_nodeVar646 = ( p10_nodeVar645 * p10_nodeVar645 );
				p10_nodeVar647 = ( p10_nodeVar646 * p10_nodeVar645 );
				p10_nodeVar648 = ( ( ( ( p10_nodeVar647 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar646 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar649 = ( ( ( p10_nodeVar644 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar648 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar645 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar645 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar645 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar648 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar650 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar649.x, p10_nodeVar649.y ), 0.0 );
				p10_nodeVar651 = ( p10_nodeVar647 / vec2<f32>( 6.0 ) );
				p10_nodeVar652 = ( ( ( ( ( ( p10_nodeVar647 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar646 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar645 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar651 );
				p10_nodeVar653 = ( ( ( p10_nodeVar644 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar651 / p10_nodeVar652 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar654 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar653.x, p10_nodeVar649.y ), 0.0 );
				p10_nodeVar655 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar649.x, p10_nodeVar653.y ), 0.0 );
				p10_nodeVar656 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar653.x, p10_nodeVar653.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar650, p10_nodeVar654, p10_nodeVar652.x ), mix( p10_nodeVar655, p10_nodeVar656, p10_nodeVar652.x ), p10_nodeVar652.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 7.0 ) ) {

			p10_nodeVar657 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar658 = ( ( p10_nodeVar657 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar659 = floor( p10_nodeVar658 );
			p10_nodeVar660 = ( p10_nodeVar658 - p10_nodeVar659 );
			p10_nodeVar661 = ( p10_nodeVar660 * p10_nodeVar660 );
			p10_nodeVar662 = ( p10_nodeVar661 * p10_nodeVar660 );
			p10_nodeVar663 = ( ( ( ( p10_nodeVar662 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar661 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar664 = ( ( ( p10_nodeVar659 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar663 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar660 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar660 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar660 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar663 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar665 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar664.x, p10_nodeVar664.y ), 0.0 );
			p10_nodeVar666 = ( p10_nodeVar662 / vec2<f32>( 6.0 ) );
			p10_nodeVar667 = ( ( ( ( ( ( p10_nodeVar662 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar661 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar660 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar666 );
			p10_nodeVar668 = ( ( ( p10_nodeVar659 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar666 / p10_nodeVar667 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar669 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar668.x, p10_nodeVar664.y ), 0.0 );
			p10_nodeVar670 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar664.x, p10_nodeVar668.y ), 0.0 );
			p10_nodeVar671 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar668.x, p10_nodeVar668.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar665, p10_nodeVar669, p10_nodeVar667.x ), mix( p10_nodeVar670, p10_nodeVar671, p10_nodeVar667.x ), p10_nodeVar667.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar672 = ( ( p10_nodeVar657 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar673 = floor( p10_nodeVar672 );
				p10_nodeVar674 = ( p10_nodeVar672 - p10_nodeVar673 );
				p10_nodeVar675 = ( p10_nodeVar674 * p10_nodeVar674 );
				p10_nodeVar676 = ( p10_nodeVar675 * p10_nodeVar674 );
				p10_nodeVar677 = ( ( ( ( p10_nodeVar676 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar675 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar678 = ( ( ( p10_nodeVar673 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar677 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar674 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar674 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar674 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar677 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar679 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar678.x, p10_nodeVar678.y ), 0.0 );
				p10_nodeVar680 = ( p10_nodeVar676 / vec2<f32>( 6.0 ) );
				p10_nodeVar681 = ( ( ( ( ( ( p10_nodeVar676 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar675 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar674 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar680 );
				p10_nodeVar682 = ( ( ( p10_nodeVar673 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar680 / p10_nodeVar681 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar683 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar682.x, p10_nodeVar678.y ), 0.0 );
				p10_nodeVar684 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar678.x, p10_nodeVar682.y ), 0.0 );
				p10_nodeVar685 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar682.x, p10_nodeVar682.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar679, p10_nodeVar683, p10_nodeVar681.x ), mix( p10_nodeVar684, p10_nodeVar685, p10_nodeVar681.x ), p10_nodeVar681.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 8.0 ) ) {

			p10_nodeVar686 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar687 = ( ( p10_nodeVar686 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar688 = floor( p10_nodeVar687 );
			p10_nodeVar689 = ( p10_nodeVar687 - p10_nodeVar688 );
			p10_nodeVar690 = ( p10_nodeVar689 * p10_nodeVar689 );
			p10_nodeVar691 = ( p10_nodeVar690 * p10_nodeVar689 );
			p10_nodeVar692 = ( ( ( ( p10_nodeVar691 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar690 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar693 = ( ( ( p10_nodeVar688 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar692 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar689 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar689 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar689 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar692 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar694 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar693.x, p10_nodeVar693.y ), 0.0 );
			p10_nodeVar695 = ( p10_nodeVar691 / vec2<f32>( 6.0 ) );
			p10_nodeVar696 = ( ( ( ( ( ( p10_nodeVar691 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar690 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar689 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar695 );
			p10_nodeVar697 = ( ( ( p10_nodeVar688 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar695 / p10_nodeVar696 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar698 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar697.x, p10_nodeVar693.y ), 0.0 );
			p10_nodeVar699 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar693.x, p10_nodeVar697.y ), 0.0 );
			p10_nodeVar700 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar697.x, p10_nodeVar697.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar694, p10_nodeVar698, p10_nodeVar696.x ), mix( p10_nodeVar699, p10_nodeVar700, p10_nodeVar696.x ), p10_nodeVar696.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar701 = ( ( p10_nodeVar686 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar702 = floor( p10_nodeVar701 );
				p10_nodeVar703 = ( p10_nodeVar701 - p10_nodeVar702 );
				p10_nodeVar704 = ( p10_nodeVar703 * p10_nodeVar703 );
				p10_nodeVar705 = ( p10_nodeVar704 * p10_nodeVar703 );
				p10_nodeVar706 = ( ( ( ( p10_nodeVar705 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar704 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar707 = ( ( ( p10_nodeVar702 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar706 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar703 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar703 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar703 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar706 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar708 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar707.x, p10_nodeVar707.y ), 0.0 );
				p10_nodeVar709 = ( p10_nodeVar705 / vec2<f32>( 6.0 ) );
				p10_nodeVar710 = ( ( ( ( ( ( p10_nodeVar705 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar704 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar703 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar709 );
				p10_nodeVar711 = ( ( ( p10_nodeVar702 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar709 / p10_nodeVar710 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar712 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar711.x, p10_nodeVar707.y ), 0.0 );
				p10_nodeVar713 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar707.x, p10_nodeVar711.y ), 0.0 );
				p10_nodeVar714 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar711.x, p10_nodeVar711.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar708, p10_nodeVar712, p10_nodeVar710.x ), mix( p10_nodeVar713, p10_nodeVar714, p10_nodeVar710.x ), p10_nodeVar710.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 == 9.0 ) ) {

			p10_nodeVar715 = ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar716 = ( ( p10_nodeVar715 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar717 = floor( p10_nodeVar716 );
			p10_nodeVar718 = ( p10_nodeVar716 - p10_nodeVar717 );
			p10_nodeVar719 = ( p10_nodeVar718 * p10_nodeVar718 );
			p10_nodeVar720 = ( p10_nodeVar719 * p10_nodeVar718 );
			p10_nodeVar721 = ( ( ( ( p10_nodeVar720 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar719 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar722 = ( ( ( p10_nodeVar717 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar721 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar718 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar718 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar718 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar721 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar723 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar722.x, p10_nodeVar722.y ), 0.0 );
			p10_nodeVar724 = ( p10_nodeVar720 / vec2<f32>( 6.0 ) );
			p10_nodeVar725 = ( ( ( ( ( ( p10_nodeVar720 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar719 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar718 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar724 );
			p10_nodeVar726 = ( ( ( p10_nodeVar717 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar724 / p10_nodeVar725 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar727 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar726.x, p10_nodeVar722.y ), 0.0 );
			p10_nodeVar728 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar722.x, p10_nodeVar726.y ), 0.0 );
			p10_nodeVar729 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar726.x, p10_nodeVar726.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar723, p10_nodeVar727, p10_nodeVar725.x ), mix( p10_nodeVar728, p10_nodeVar729, p10_nodeVar725.x ), p10_nodeVar725.y );

			if ( ( p10_nodeVar466 > 0.0 ) ) {

				p10_nodeVar730 = ( ( p10_nodeVar715 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar731 = floor( p10_nodeVar730 );
				p10_nodeVar732 = ( p10_nodeVar730 - p10_nodeVar731 );
				p10_nodeVar733 = ( p10_nodeVar732 * p10_nodeVar732 );
				p10_nodeVar734 = ( p10_nodeVar733 * p10_nodeVar732 );
				p10_nodeVar735 = ( ( ( ( p10_nodeVar734 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar733 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar736 = ( ( ( p10_nodeVar731 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar735 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar732 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar732 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar732 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar735 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar737 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar736.x, p10_nodeVar736.y ), 0.0 );
				p10_nodeVar738 = ( p10_nodeVar734 / vec2<f32>( 6.0 ) );
				p10_nodeVar739 = ( ( ( ( ( ( p10_nodeVar734 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar733 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar732 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar738 );
				p10_nodeVar740 = ( ( ( p10_nodeVar731 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar738 / p10_nodeVar739 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar741 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar740.x, p10_nodeVar736.y ), 0.0 );
				p10_nodeVar742 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar736.x, p10_nodeVar740.y ), 0.0 );
				p10_nodeVar743 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar740.x, p10_nodeVar740.y ), 0.0 );
				p10_nodeVar463 = mix( p10_nodeVar463, mix( mix( p10_nodeVar737, p10_nodeVar741, p10_nodeVar739.x ), mix( p10_nodeVar742, p10_nodeVar743, p10_nodeVar739.x ), p10_nodeVar739.y ), p10_nodeVar466 );
				

			}

			

		}


		if ( ( p10_nodeVar465 >= 10.0 ) ) {

			p10_nodeVar744 = ( ( ( p10_nodeVar171 + ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar745 = floor( p10_nodeVar744 );
			p10_nodeVar746 = ( p10_nodeVar744 - p10_nodeVar745 );
			p10_nodeVar747 = ( p10_nodeVar746 * p10_nodeVar746 );
			p10_nodeVar748 = ( p10_nodeVar747 * p10_nodeVar746 );
			p10_nodeVar749 = ( ( ( ( p10_nodeVar748 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar747 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar750 = ( ( ( p10_nodeVar745 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar749 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar746 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar746 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar746 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar749 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar751 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar750.x, p10_nodeVar750.y ), 0.0 );
			p10_nodeVar752 = ( p10_nodeVar748 / vec2<f32>( 6.0 ) );
			p10_nodeVar753 = ( ( ( ( ( ( p10_nodeVar748 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar747 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar746 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar752 );
			p10_nodeVar754 = ( ( ( p10_nodeVar745 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar752 / p10_nodeVar753 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar755 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar754.x, p10_nodeVar750.y ), 0.0 );
			p10_nodeVar756 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar750.x, p10_nodeVar754.y ), 0.0 );
			p10_nodeVar757 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar754.x, p10_nodeVar754.y ), 0.0 );
			p10_nodeVar463 = mix( mix( p10_nodeVar751, p10_nodeVar755, p10_nodeVar753.x ), mix( p10_nodeVar756, p10_nodeVar757, p10_nodeVar753.x ), p10_nodeVar753.y );
			

		}

		p10_nodeVar758 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p10_nodeVar759 = clamp( p10_nodeVar174, 0.0, 10.0 );
		p10_nodeVar760 = floor( p10_nodeVar759 );
		p10_nodeVar761 = ( p10_nodeVar759 - p10_nodeVar760 );

		if ( ( p10_nodeVar760 == 0.0 ) ) {

			p10_nodeVar762 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar763 = picture_read_level( p10_nodeVar762, 0.0 );
			p10_nodeVar758 = vec4<f32>( ( vec3<f32>( p10_nodeVar763.x, p10_nodeVar763.y, p10_nodeVar763.z ) * vec3<f32>( p10_nodeVar763.w ) ), p10_nodeVar763.w );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar764 = ( ( p10_nodeVar762 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar765 = floor( p10_nodeVar764 );
				p10_nodeVar766 = ( p10_nodeVar764 - p10_nodeVar765 );
				p10_nodeVar767 = ( p10_nodeVar766 * p10_nodeVar766 );
				p10_nodeVar768 = ( p10_nodeVar767 * p10_nodeVar766 );
				p10_nodeVar769 = ( ( ( ( p10_nodeVar768 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar767 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar770 = ( ( ( p10_nodeVar765 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar769 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar766 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar766 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar766 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar769 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar771 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar770.x, p10_nodeVar770.y ), 0.0 );
				p10_nodeVar772 = ( p10_nodeVar768 / vec2<f32>( 6.0 ) );
				p10_nodeVar773 = ( ( ( ( ( ( p10_nodeVar768 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar767 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar766 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar772 );
				p10_nodeVar774 = ( ( ( p10_nodeVar765 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar772 / p10_nodeVar773 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar775 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar774.x, p10_nodeVar770.y ), 0.0 );
				p10_nodeVar776 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar770.x, p10_nodeVar774.y ), 0.0 );
				p10_nodeVar777 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar774.x, p10_nodeVar774.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar771, p10_nodeVar775, p10_nodeVar773.x ), mix( p10_nodeVar776, p10_nodeVar777, p10_nodeVar773.x ), p10_nodeVar773.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 1.0 ) ) {

			p10_nodeVar778 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar779 = ( ( p10_nodeVar778 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar780 = floor( p10_nodeVar779 );
			p10_nodeVar781 = ( p10_nodeVar779 - p10_nodeVar780 );
			p10_nodeVar782 = ( p10_nodeVar781 * p10_nodeVar781 );
			p10_nodeVar783 = ( p10_nodeVar782 * p10_nodeVar781 );
			p10_nodeVar784 = ( ( ( ( p10_nodeVar783 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar782 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar785 = ( ( ( p10_nodeVar780 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar784 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar781 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar781 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar781 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar784 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar786 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar785.x, p10_nodeVar785.y ), 0.0 );
			p10_nodeVar787 = ( p10_nodeVar783 / vec2<f32>( 6.0 ) );
			p10_nodeVar788 = ( ( ( ( ( ( p10_nodeVar783 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar782 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar781 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar787 );
			p10_nodeVar789 = ( ( ( p10_nodeVar780 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar787 / p10_nodeVar788 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar790 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar789.x, p10_nodeVar785.y ), 0.0 );
			p10_nodeVar791 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar785.x, p10_nodeVar789.y ), 0.0 );
			p10_nodeVar792 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar789.x, p10_nodeVar789.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar786, p10_nodeVar790, p10_nodeVar788.x ), mix( p10_nodeVar791, p10_nodeVar792, p10_nodeVar788.x ), p10_nodeVar788.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar793 = ( ( p10_nodeVar778 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar794 = floor( p10_nodeVar793 );
				p10_nodeVar795 = ( p10_nodeVar793 - p10_nodeVar794 );
				p10_nodeVar796 = ( p10_nodeVar795 * p10_nodeVar795 );
				p10_nodeVar797 = ( p10_nodeVar796 * p10_nodeVar795 );
				p10_nodeVar798 = ( ( ( ( p10_nodeVar797 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar796 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar799 = ( ( ( p10_nodeVar794 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar798 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar795 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar795 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar795 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar798 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar800 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar799.x, p10_nodeVar799.y ), 0.0 );
				p10_nodeVar801 = ( p10_nodeVar797 / vec2<f32>( 6.0 ) );
				p10_nodeVar802 = ( ( ( ( ( ( p10_nodeVar797 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar796 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar795 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar801 );
				p10_nodeVar803 = ( ( ( p10_nodeVar794 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar801 / p10_nodeVar802 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar804 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar803.x, p10_nodeVar799.y ), 0.0 );
				p10_nodeVar805 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar799.x, p10_nodeVar803.y ), 0.0 );
				p10_nodeVar806 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar803.x, p10_nodeVar803.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar800, p10_nodeVar804, p10_nodeVar802.x ), mix( p10_nodeVar805, p10_nodeVar806, p10_nodeVar802.x ), p10_nodeVar802.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 2.0 ) ) {

			p10_nodeVar807 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar808 = ( ( p10_nodeVar807 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar809 = floor( p10_nodeVar808 );
			p10_nodeVar810 = ( p10_nodeVar808 - p10_nodeVar809 );
			p10_nodeVar811 = ( p10_nodeVar810 * p10_nodeVar810 );
			p10_nodeVar812 = ( p10_nodeVar811 * p10_nodeVar810 );
			p10_nodeVar813 = ( ( ( ( p10_nodeVar812 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar811 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar814 = ( ( ( p10_nodeVar809 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar813 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar810 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar810 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar810 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar813 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar815 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar814.x, p10_nodeVar814.y ), 0.0 );
			p10_nodeVar816 = ( p10_nodeVar812 / vec2<f32>( 6.0 ) );
			p10_nodeVar817 = ( ( ( ( ( ( p10_nodeVar812 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar811 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar810 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar816 );
			p10_nodeVar818 = ( ( ( p10_nodeVar809 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar816 / p10_nodeVar817 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar819 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar818.x, p10_nodeVar814.y ), 0.0 );
			p10_nodeVar820 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar814.x, p10_nodeVar818.y ), 0.0 );
			p10_nodeVar821 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar818.x, p10_nodeVar818.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar815, p10_nodeVar819, p10_nodeVar817.x ), mix( p10_nodeVar820, p10_nodeVar821, p10_nodeVar817.x ), p10_nodeVar817.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar822 = ( ( p10_nodeVar807 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar823 = floor( p10_nodeVar822 );
				p10_nodeVar824 = ( p10_nodeVar822 - p10_nodeVar823 );
				p10_nodeVar825 = ( p10_nodeVar824 * p10_nodeVar824 );
				p10_nodeVar826 = ( p10_nodeVar825 * p10_nodeVar824 );
				p10_nodeVar827 = ( ( ( ( p10_nodeVar826 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar825 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar828 = ( ( ( p10_nodeVar823 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar827 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar824 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar824 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar824 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar827 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar829 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar828.x, p10_nodeVar828.y ), 0.0 );
				p10_nodeVar830 = ( p10_nodeVar826 / vec2<f32>( 6.0 ) );
				p10_nodeVar831 = ( ( ( ( ( ( p10_nodeVar826 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar825 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar824 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar830 );
				p10_nodeVar832 = ( ( ( p10_nodeVar823 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar830 / p10_nodeVar831 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar833 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar832.x, p10_nodeVar828.y ), 0.0 );
				p10_nodeVar834 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar828.x, p10_nodeVar832.y ), 0.0 );
				p10_nodeVar835 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar832.x, p10_nodeVar832.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar829, p10_nodeVar833, p10_nodeVar831.x ), mix( p10_nodeVar834, p10_nodeVar835, p10_nodeVar831.x ), p10_nodeVar831.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 3.0 ) ) {

			p10_nodeVar836 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar837 = ( ( p10_nodeVar836 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar838 = floor( p10_nodeVar837 );
			p10_nodeVar839 = ( p10_nodeVar837 - p10_nodeVar838 );
			p10_nodeVar840 = ( p10_nodeVar839 * p10_nodeVar839 );
			p10_nodeVar841 = ( p10_nodeVar840 * p10_nodeVar839 );
			p10_nodeVar842 = ( ( ( ( p10_nodeVar841 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar840 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar843 = ( ( ( p10_nodeVar838 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar842 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar839 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar839 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar839 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar842 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar844 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar843.x, p10_nodeVar843.y ), 0.0 );
			p10_nodeVar845 = ( p10_nodeVar841 / vec2<f32>( 6.0 ) );
			p10_nodeVar846 = ( ( ( ( ( ( p10_nodeVar841 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar840 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar839 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar845 );
			p10_nodeVar847 = ( ( ( p10_nodeVar838 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar845 / p10_nodeVar846 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar848 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar847.x, p10_nodeVar843.y ), 0.0 );
			p10_nodeVar849 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar843.x, p10_nodeVar847.y ), 0.0 );
			p10_nodeVar850 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar847.x, p10_nodeVar847.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar844, p10_nodeVar848, p10_nodeVar846.x ), mix( p10_nodeVar849, p10_nodeVar850, p10_nodeVar846.x ), p10_nodeVar846.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar851 = ( ( p10_nodeVar836 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar852 = floor( p10_nodeVar851 );
				p10_nodeVar853 = ( p10_nodeVar851 - p10_nodeVar852 );
				p10_nodeVar854 = ( p10_nodeVar853 * p10_nodeVar853 );
				p10_nodeVar855 = ( p10_nodeVar854 * p10_nodeVar853 );
				p10_nodeVar856 = ( ( ( ( p10_nodeVar855 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar854 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar857 = ( ( ( p10_nodeVar852 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar856 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar853 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar853 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar853 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar856 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar858 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar857.x, p10_nodeVar857.y ), 0.0 );
				p10_nodeVar859 = ( p10_nodeVar855 / vec2<f32>( 6.0 ) );
				p10_nodeVar860 = ( ( ( ( ( ( p10_nodeVar855 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar854 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar853 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar859 );
				p10_nodeVar861 = ( ( ( p10_nodeVar852 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar859 / p10_nodeVar860 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar862 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar861.x, p10_nodeVar857.y ), 0.0 );
				p10_nodeVar863 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar857.x, p10_nodeVar861.y ), 0.0 );
				p10_nodeVar864 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar861.x, p10_nodeVar861.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar858, p10_nodeVar862, p10_nodeVar860.x ), mix( p10_nodeVar863, p10_nodeVar864, p10_nodeVar860.x ), p10_nodeVar860.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 4.0 ) ) {

			p10_nodeVar865 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar866 = ( ( p10_nodeVar865 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar867 = floor( p10_nodeVar866 );
			p10_nodeVar868 = ( p10_nodeVar866 - p10_nodeVar867 );
			p10_nodeVar869 = ( p10_nodeVar868 * p10_nodeVar868 );
			p10_nodeVar870 = ( p10_nodeVar869 * p10_nodeVar868 );
			p10_nodeVar871 = ( ( ( ( p10_nodeVar870 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar869 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar872 = ( ( ( p10_nodeVar867 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar871 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar868 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar868 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar868 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar871 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar873 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar872.x, p10_nodeVar872.y ), 0.0 );
			p10_nodeVar874 = ( p10_nodeVar870 / vec2<f32>( 6.0 ) );
			p10_nodeVar875 = ( ( ( ( ( ( p10_nodeVar870 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar869 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar868 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar874 );
			p10_nodeVar876 = ( ( ( p10_nodeVar867 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar874 / p10_nodeVar875 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar877 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar876.x, p10_nodeVar872.y ), 0.0 );
			p10_nodeVar878 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar872.x, p10_nodeVar876.y ), 0.0 );
			p10_nodeVar879 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar876.x, p10_nodeVar876.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar873, p10_nodeVar877, p10_nodeVar875.x ), mix( p10_nodeVar878, p10_nodeVar879, p10_nodeVar875.x ), p10_nodeVar875.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar880 = ( ( p10_nodeVar865 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar881 = floor( p10_nodeVar880 );
				p10_nodeVar882 = ( p10_nodeVar880 - p10_nodeVar881 );
				p10_nodeVar883 = ( p10_nodeVar882 * p10_nodeVar882 );
				p10_nodeVar884 = ( p10_nodeVar883 * p10_nodeVar882 );
				p10_nodeVar885 = ( ( ( ( p10_nodeVar884 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar883 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar886 = ( ( ( p10_nodeVar881 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar885 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar882 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar882 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar882 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar885 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar887 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar886.x, p10_nodeVar886.y ), 0.0 );
				p10_nodeVar888 = ( p10_nodeVar884 / vec2<f32>( 6.0 ) );
				p10_nodeVar889 = ( ( ( ( ( ( p10_nodeVar884 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar883 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar882 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar888 );
				p10_nodeVar890 = ( ( ( p10_nodeVar881 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar888 / p10_nodeVar889 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar891 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar890.x, p10_nodeVar886.y ), 0.0 );
				p10_nodeVar892 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar886.x, p10_nodeVar890.y ), 0.0 );
				p10_nodeVar893 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar890.x, p10_nodeVar890.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar887, p10_nodeVar891, p10_nodeVar889.x ), mix( p10_nodeVar892, p10_nodeVar893, p10_nodeVar889.x ), p10_nodeVar889.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 5.0 ) ) {

			p10_nodeVar894 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar895 = ( ( p10_nodeVar894 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar896 = floor( p10_nodeVar895 );
			p10_nodeVar897 = ( p10_nodeVar895 - p10_nodeVar896 );
			p10_nodeVar898 = ( p10_nodeVar897 * p10_nodeVar897 );
			p10_nodeVar899 = ( p10_nodeVar898 * p10_nodeVar897 );
			p10_nodeVar900 = ( ( ( ( p10_nodeVar899 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar898 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar901 = ( ( ( p10_nodeVar896 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar900 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar897 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar897 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar897 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar900 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar902 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar901.x, p10_nodeVar901.y ), 0.0 );
			p10_nodeVar903 = ( p10_nodeVar899 / vec2<f32>( 6.0 ) );
			p10_nodeVar904 = ( ( ( ( ( ( p10_nodeVar899 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar898 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar897 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar903 );
			p10_nodeVar905 = ( ( ( p10_nodeVar896 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar903 / p10_nodeVar904 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar906 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar905.x, p10_nodeVar901.y ), 0.0 );
			p10_nodeVar907 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar901.x, p10_nodeVar905.y ), 0.0 );
			p10_nodeVar908 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar905.x, p10_nodeVar905.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar902, p10_nodeVar906, p10_nodeVar904.x ), mix( p10_nodeVar907, p10_nodeVar908, p10_nodeVar904.x ), p10_nodeVar904.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar909 = ( ( p10_nodeVar894 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar910 = floor( p10_nodeVar909 );
				p10_nodeVar911 = ( p10_nodeVar909 - p10_nodeVar910 );
				p10_nodeVar912 = ( p10_nodeVar911 * p10_nodeVar911 );
				p10_nodeVar913 = ( p10_nodeVar912 * p10_nodeVar911 );
				p10_nodeVar914 = ( ( ( ( p10_nodeVar913 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar912 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar915 = ( ( ( p10_nodeVar910 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar914 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar911 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar911 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar911 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar914 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar916 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar915.x, p10_nodeVar915.y ), 0.0 );
				p10_nodeVar917 = ( p10_nodeVar913 / vec2<f32>( 6.0 ) );
				p10_nodeVar918 = ( ( ( ( ( ( p10_nodeVar913 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar912 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar911 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar917 );
				p10_nodeVar919 = ( ( ( p10_nodeVar910 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar917 / p10_nodeVar918 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar920 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar919.x, p10_nodeVar915.y ), 0.0 );
				p10_nodeVar921 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar915.x, p10_nodeVar919.y ), 0.0 );
				p10_nodeVar922 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar919.x, p10_nodeVar919.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar916, p10_nodeVar920, p10_nodeVar918.x ), mix( p10_nodeVar921, p10_nodeVar922, p10_nodeVar918.x ), p10_nodeVar918.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 6.0 ) ) {

			p10_nodeVar923 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar924 = ( ( p10_nodeVar923 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar925 = floor( p10_nodeVar924 );
			p10_nodeVar926 = ( p10_nodeVar924 - p10_nodeVar925 );
			p10_nodeVar927 = ( p10_nodeVar926 * p10_nodeVar926 );
			p10_nodeVar928 = ( p10_nodeVar927 * p10_nodeVar926 );
			p10_nodeVar929 = ( ( ( ( p10_nodeVar928 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar927 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar930 = ( ( ( p10_nodeVar925 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar929 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar926 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar926 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar926 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar929 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar931 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar930.x, p10_nodeVar930.y ), 0.0 );
			p10_nodeVar932 = ( p10_nodeVar928 / vec2<f32>( 6.0 ) );
			p10_nodeVar933 = ( ( ( ( ( ( p10_nodeVar928 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar927 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar926 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar932 );
			p10_nodeVar934 = ( ( ( p10_nodeVar925 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar932 / p10_nodeVar933 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar935 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar934.x, p10_nodeVar930.y ), 0.0 );
			p10_nodeVar936 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar930.x, p10_nodeVar934.y ), 0.0 );
			p10_nodeVar937 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar934.x, p10_nodeVar934.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar931, p10_nodeVar935, p10_nodeVar933.x ), mix( p10_nodeVar936, p10_nodeVar937, p10_nodeVar933.x ), p10_nodeVar933.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar938 = ( ( p10_nodeVar923 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar939 = floor( p10_nodeVar938 );
				p10_nodeVar940 = ( p10_nodeVar938 - p10_nodeVar939 );
				p10_nodeVar941 = ( p10_nodeVar940 * p10_nodeVar940 );
				p10_nodeVar942 = ( p10_nodeVar941 * p10_nodeVar940 );
				p10_nodeVar943 = ( ( ( ( p10_nodeVar942 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar941 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar944 = ( ( ( p10_nodeVar939 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar943 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar940 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar940 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar940 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar943 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar945 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar944.x, p10_nodeVar944.y ), 0.0 );
				p10_nodeVar946 = ( p10_nodeVar942 / vec2<f32>( 6.0 ) );
				p10_nodeVar947 = ( ( ( ( ( ( p10_nodeVar942 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar941 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar940 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar946 );
				p10_nodeVar948 = ( ( ( p10_nodeVar939 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar946 / p10_nodeVar947 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar949 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar948.x, p10_nodeVar944.y ), 0.0 );
				p10_nodeVar950 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar944.x, p10_nodeVar948.y ), 0.0 );
				p10_nodeVar951 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar948.x, p10_nodeVar948.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar945, p10_nodeVar949, p10_nodeVar947.x ), mix( p10_nodeVar950, p10_nodeVar951, p10_nodeVar947.x ), p10_nodeVar947.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 7.0 ) ) {

			p10_nodeVar952 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar953 = ( ( p10_nodeVar952 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar954 = floor( p10_nodeVar953 );
			p10_nodeVar955 = ( p10_nodeVar953 - p10_nodeVar954 );
			p10_nodeVar956 = ( p10_nodeVar955 * p10_nodeVar955 );
			p10_nodeVar957 = ( p10_nodeVar956 * p10_nodeVar955 );
			p10_nodeVar958 = ( ( ( ( p10_nodeVar957 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar956 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar959 = ( ( ( p10_nodeVar954 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar958 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar955 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar955 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar955 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar958 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar960 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar959.x, p10_nodeVar959.y ), 0.0 );
			p10_nodeVar961 = ( p10_nodeVar957 / vec2<f32>( 6.0 ) );
			p10_nodeVar962 = ( ( ( ( ( ( p10_nodeVar957 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar956 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar955 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar961 );
			p10_nodeVar963 = ( ( ( p10_nodeVar954 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar961 / p10_nodeVar962 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar964 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar963.x, p10_nodeVar959.y ), 0.0 );
			p10_nodeVar965 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar959.x, p10_nodeVar963.y ), 0.0 );
			p10_nodeVar966 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar963.x, p10_nodeVar963.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar960, p10_nodeVar964, p10_nodeVar962.x ), mix( p10_nodeVar965, p10_nodeVar966, p10_nodeVar962.x ), p10_nodeVar962.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar967 = ( ( p10_nodeVar952 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar968 = floor( p10_nodeVar967 );
				p10_nodeVar969 = ( p10_nodeVar967 - p10_nodeVar968 );
				p10_nodeVar970 = ( p10_nodeVar969 * p10_nodeVar969 );
				p10_nodeVar971 = ( p10_nodeVar970 * p10_nodeVar969 );
				p10_nodeVar972 = ( ( ( ( p10_nodeVar971 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar970 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar973 = ( ( ( p10_nodeVar968 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar972 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar969 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar969 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar969 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar972 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar974 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar973.x, p10_nodeVar973.y ), 0.0 );
				p10_nodeVar975 = ( p10_nodeVar971 / vec2<f32>( 6.0 ) );
				p10_nodeVar976 = ( ( ( ( ( ( p10_nodeVar971 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar970 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar969 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar975 );
				p10_nodeVar977 = ( ( ( p10_nodeVar968 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar975 / p10_nodeVar976 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar978 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar977.x, p10_nodeVar973.y ), 0.0 );
				p10_nodeVar979 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar973.x, p10_nodeVar977.y ), 0.0 );
				p10_nodeVar980 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar977.x, p10_nodeVar977.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar974, p10_nodeVar978, p10_nodeVar976.x ), mix( p10_nodeVar979, p10_nodeVar980, p10_nodeVar976.x ), p10_nodeVar976.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 8.0 ) ) {

			p10_nodeVar981 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar982 = ( ( p10_nodeVar981 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar983 = floor( p10_nodeVar982 );
			p10_nodeVar984 = ( p10_nodeVar982 - p10_nodeVar983 );
			p10_nodeVar985 = ( p10_nodeVar984 * p10_nodeVar984 );
			p10_nodeVar986 = ( p10_nodeVar985 * p10_nodeVar984 );
			p10_nodeVar987 = ( ( ( ( p10_nodeVar986 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar985 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar988 = ( ( ( p10_nodeVar983 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar987 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar984 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar984 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar984 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar987 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar989 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar988.x, p10_nodeVar988.y ), 0.0 );
			p10_nodeVar990 = ( p10_nodeVar986 / vec2<f32>( 6.0 ) );
			p10_nodeVar991 = ( ( ( ( ( ( p10_nodeVar986 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar985 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar984 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar990 );
			p10_nodeVar992 = ( ( ( p10_nodeVar983 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar990 / p10_nodeVar991 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar993 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar992.x, p10_nodeVar988.y ), 0.0 );
			p10_nodeVar994 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar988.x, p10_nodeVar992.y ), 0.0 );
			p10_nodeVar995 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar992.x, p10_nodeVar992.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar989, p10_nodeVar993, p10_nodeVar991.x ), mix( p10_nodeVar994, p10_nodeVar995, p10_nodeVar991.x ), p10_nodeVar991.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar996 = ( ( p10_nodeVar981 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar997 = floor( p10_nodeVar996 );
				p10_nodeVar998 = ( p10_nodeVar996 - p10_nodeVar997 );
				p10_nodeVar999 = ( p10_nodeVar998 * p10_nodeVar998 );
				p10_nodeVar1000 = ( p10_nodeVar999 * p10_nodeVar998 );
				p10_nodeVar1001 = ( ( ( ( p10_nodeVar1000 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar999 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar1002 = ( ( ( p10_nodeVar997 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar1001 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar998 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar998 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar998 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1001 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar1003 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1002.x, p10_nodeVar1002.y ), 0.0 );
				p10_nodeVar1004 = ( p10_nodeVar1000 / vec2<f32>( 6.0 ) );
				p10_nodeVar1005 = ( ( ( ( ( ( p10_nodeVar1000 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar999 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar998 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1004 );
				p10_nodeVar1006 = ( ( ( p10_nodeVar997 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar1004 / p10_nodeVar1005 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar1007 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1006.x, p10_nodeVar1002.y ), 0.0 );
				p10_nodeVar1008 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1002.x, p10_nodeVar1006.y ), 0.0 );
				p10_nodeVar1009 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1006.x, p10_nodeVar1006.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar1003, p10_nodeVar1007, p10_nodeVar1005.x ), mix( p10_nodeVar1008, p10_nodeVar1009, p10_nodeVar1005.x ), p10_nodeVar1005.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 == 9.0 ) ) {

			p10_nodeVar1010 = ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) );
			p10_nodeVar1011 = ( ( p10_nodeVar1010 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar1012 = floor( p10_nodeVar1011 );
			p10_nodeVar1013 = ( p10_nodeVar1011 - p10_nodeVar1012 );
			p10_nodeVar1014 = ( p10_nodeVar1013 * p10_nodeVar1013 );
			p10_nodeVar1015 = ( p10_nodeVar1014 * p10_nodeVar1013 );
			p10_nodeVar1016 = ( ( ( ( p10_nodeVar1015 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar1014 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar1017 = ( ( ( p10_nodeVar1012 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar1016 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1013 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1013 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1013 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1016 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar1018 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1017.x, p10_nodeVar1017.y ), 0.0 );
			p10_nodeVar1019 = ( p10_nodeVar1015 / vec2<f32>( 6.0 ) );
			p10_nodeVar1020 = ( ( ( ( ( ( p10_nodeVar1015 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar1014 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar1013 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1019 );
			p10_nodeVar1021 = ( ( ( p10_nodeVar1012 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar1019 / p10_nodeVar1020 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar1022 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1021.x, p10_nodeVar1017.y ), 0.0 );
			p10_nodeVar1023 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1017.x, p10_nodeVar1021.y ), 0.0 );
			p10_nodeVar1024 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar1021.x, p10_nodeVar1021.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar1018, p10_nodeVar1022, p10_nodeVar1020.x ), mix( p10_nodeVar1023, p10_nodeVar1024, p10_nodeVar1020.x ), p10_nodeVar1020.y );

			if ( ( p10_nodeVar761 > 0.0 ) ) {

				p10_nodeVar1025 = ( ( p10_nodeVar1010 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar1026 = floor( p10_nodeVar1025 );
				p10_nodeVar1027 = ( p10_nodeVar1025 - p10_nodeVar1026 );
				p10_nodeVar1028 = ( p10_nodeVar1027 * p10_nodeVar1027 );
				p10_nodeVar1029 = ( p10_nodeVar1028 * p10_nodeVar1027 );
				p10_nodeVar1030 = ( ( ( ( p10_nodeVar1029 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar1028 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar1031 = ( ( ( p10_nodeVar1026 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar1030 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1027 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1027 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1027 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1030 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar1032 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1031.x, p10_nodeVar1031.y ), 0.0 );
				p10_nodeVar1033 = ( p10_nodeVar1029 / vec2<f32>( 6.0 ) );
				p10_nodeVar1034 = ( ( ( ( ( ( p10_nodeVar1029 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar1028 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar1027 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1033 );
				p10_nodeVar1035 = ( ( ( p10_nodeVar1026 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar1033 / p10_nodeVar1034 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar1036 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1035.x, p10_nodeVar1031.y ), 0.0 );
				p10_nodeVar1037 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1031.x, p10_nodeVar1035.y ), 0.0 );
				p10_nodeVar1038 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1035.x, p10_nodeVar1035.y ), 0.0 );
				p10_nodeVar758 = mix( p10_nodeVar758, mix( mix( p10_nodeVar1032, p10_nodeVar1036, p10_nodeVar1034.x ), mix( p10_nodeVar1037, p10_nodeVar1038, p10_nodeVar1034.x ), p10_nodeVar1034.y ), p10_nodeVar761 );
				

			}

			

		}


		if ( ( p10_nodeVar760 >= 10.0 ) ) {

			p10_nodeVar1039 = ( ( ( p10_nodeVar171 - ( ( p10_nodeVar170 * vec2<f32>( f32(knobs.dispersion) ) ) * vec2<f32>( 0.35 ) ) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar1040 = floor( p10_nodeVar1039 );
			p10_nodeVar1041 = ( p10_nodeVar1039 - p10_nodeVar1040 );
			p10_nodeVar1042 = ( p10_nodeVar1041 * p10_nodeVar1041 );
			p10_nodeVar1043 = ( p10_nodeVar1042 * p10_nodeVar1041 );
			p10_nodeVar1044 = ( ( ( ( p10_nodeVar1043 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar1042 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar1045 = ( ( ( p10_nodeVar1040 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar1044 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1041 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1041 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar1041 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1044 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar1046 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1045.x, p10_nodeVar1045.y ), 0.0 );
			p10_nodeVar1047 = ( p10_nodeVar1043 / vec2<f32>( 6.0 ) );
			p10_nodeVar1048 = ( ( ( ( ( ( p10_nodeVar1043 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar1042 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar1041 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar1047 );
			p10_nodeVar1049 = ( ( ( p10_nodeVar1040 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar1047 / p10_nodeVar1048 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar1050 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1049.x, p10_nodeVar1045.y ), 0.0 );
			p10_nodeVar1051 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1045.x, p10_nodeVar1049.y ), 0.0 );
			p10_nodeVar1052 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar1049.x, p10_nodeVar1049.y ), 0.0 );
			p10_nodeVar758 = mix( mix( p10_nodeVar1046, p10_nodeVar1050, p10_nodeVar1048.x ), mix( p10_nodeVar1051, p10_nodeVar1052, p10_nodeVar1048.x ), p10_nodeVar1048.y );
			

		}

		p10_nodeVar461 = max( max( p10_nodeVar463.w, p10_nodeVar175.w ), p10_nodeVar758.w );
		p10_nodeVar462 = vec3<f32>( ( p10_nodeVar463.x / max( p10_nodeVar463.w, 0.0001 ) ), ( p10_nodeVar175.y / p10_nodeVar460 ), ( p10_nodeVar758.z / max( p10_nodeVar758.w, 0.0001 ) ) );
		

	} else {

		p10_nodeVar462 = vec3<f32>( ( p10_nodeVar175.x / p10_nodeVar460 ), ( p10_nodeVar175.y / p10_nodeVar460 ), ( p10_nodeVar175.z / p10_nodeVar460 ) );
		

	}

	p10_nodeVar1053 = ( p10_nodeVar7 + p10_nodeVar91 );
	p10_nodeVar1054 = vec2<f32>( ( ( p10_nodeVar1053.x * p10_nodeVar3 ) - ( p10_nodeVar1053.y * p10_nodeVar4 ) ), ( ( p10_nodeVar1053.x * p10_nodeVar4 ) + ( p10_nodeVar1053.y * p10_nodeVar3 ) ) );
	p10_nodeVar1055 = normalize( vec3<f32>( ( - p10_nodeVar1054.x ), p10_nodeVar1054.y, 1.0 ) );
	p10_nodeVar1056 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.lightAngle + 0)) ), ( - sin( f32((0.017453292519943295 * knobs.lightAngle + 0)) ) ) );
	p10_nodeVar1057 = normalize( vec3<f32>( ( p10_nodeVar1056.x * 0.6 ), ( ( - p10_nodeVar1056.y ) * 0.6 ), 0.8 ) );
	p10_nodeVar1058 = ( smoothstep( 0.55, 1.6, length( p10_nodeVar1054 ) ) * f32(knobs.highlights) );
	p10_nodeVar1059 = clamp( ( ( ( - dot( ( p10_nodeVar1054 / vec2<f32>( max( length( p10_nodeVar1054 ), 0.0001 ) ) ), p10_nodeVar1056 ) ) * 0.5 ) + 0.5 ), 0.0, 1.0 );
	p10_nodeVar1060 = ( ( ( ( ( p10_nodeVar462 * vec3<f32>( ( 1.0 + ( ( ( ( dot( p10_nodeVar1055, p10_nodeVar1057 ) / p10_nodeVar1057.z ) - 1.0 ) * 0.06 ) * ( f32(knobs.highlights) + ( f32(knobs.frost) * 1.5 ) ) ) ) ) ) * vec3<f32>( ( 1.0 - ( ( ( 1.0 - smoothstep( 0.0, 1.4, ( p10_nodeVar8 * f32(knobs.cellSize) ) ) ) * f32(knobs.edges) ) * 0.7 ) ) ) ) * vec3<f32>( ( 1.0 - ( ( p10_nodeVar1058 * ( 1.0 - p10_nodeVar1059 ) ) * 0.2 ) ) ) ) + vec3<f32>( ( ( ( p10_nodeVar1058 * p10_nodeVar1059 ) * 0.45 ) + ( ( pow( max( dot( p10_nodeVar1055, normalize( ( p10_nodeVar1057 + vec3<f32>( 0.0, 0.0, 1.0 ) ) ) ), 0.0 ), 60.0 ) * f32(knobs.highlights) ) * 0.12 ) ) ) ) * vec3<f32>( p10_nodeVar92 ) );
	p10_nodeVar1061 = vec4<f32>( clamp( mix( p10_nodeVar1060, ( p10_nodeVar1060 * vec3<f32>(knobs.tint.x, knobs.tint.y, knobs.tint.z) ), f32(knobs.tintAmount) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), clamp( p10_nodeVar461, 0.0, 1.0 ) );
	p10_nodeVar1062 = vec3<f32>( p10_nodeVar1061.x, p10_nodeVar1061.y, p10_nodeVar1061.z );
	p10_nodeVar1063 = ( ( ( p10_nodeVar1062.x * 0.2126 ) + ( p10_nodeVar1062.y * 0.7152 ) ) + ( p10_nodeVar1062.z * 0.0722 ) );
	p10_nodeVar1064 = mix( vec3<f32>( p10_nodeVar1063, p10_nodeVar1063, p10_nodeVar1063 ), p10_nodeVar1062, f32(1.0) );
	p10_nodeVar1065 = vec4<f32>( clamp( vec3<f32>( ( ( ( p10_nodeVar1064.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p10_nodeVar1064.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar1064.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p10_nodeVar1064.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p10_nodeVar1064.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p10_nodeVar1064.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p10_nodeVar1064.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p10_nodeVar1064.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar1064.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p10_nodeVar1061.w, 0.0, 1.0 ) );
	p10_nodeVar1067 = mix( clamp( p10_nodeVar0.w, 0.0, 1.0 ), clamp( p10_nodeVar1065.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p10_nodeVar1067 > 0.0 ) ) {

		p10_nodeVar1066 = p10_nodeVar1067;

	} else {

		p10_nodeVar1066 = 1.0;

	}

	p10_DiffuseColor = vec4<f32>( ( mix( ( p10_nodeVar0.xyz * vec3<f32>( clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p10_nodeVar1065.xyz, p10_nodeVar1065.xyz, clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p10_nodeVar1065.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p10_nodeVar1066 ) ), p10_nodeVar1067 );
	p10_DiffuseColor.w = ( p10_DiffuseColor.w * f32(1.0) );
	p10_nodeVar1068 = max( vec4<f32>( p10_DiffuseColor.xyz, p10_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p10_Output = p10_nodeVar1068;

	// result

	p10_output.color = p10_nodeVar1068;

	return p10_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    case 1u: { return p1_main(door_uv).color; }
    case 2u: { return p2_main(door_uv).color; }
    case 3u: { return p3_main(door_uv).color; }
    case 4u: { return p4_main(door_uv).color; }
    case 5u: { return p5_main(door_uv).color; }
    case 6u: { return p6_main(door_uv).color; }
    case 7u: { return p7_main(door_uv).color; }
    case 8u: { return p8_main(door_uv).color; }
    case 9u: { return p9_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p10_main(door_uv).color);
}

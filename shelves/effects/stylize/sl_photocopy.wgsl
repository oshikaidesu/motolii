// Photocopy: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:A worn photocopy: crushed toner, speckle, streaks, misregistration and folds. Copies of copies degrade further.
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
// --track@threshold:Threshold,0,1,0.5,0.01
// --track@contrast:Contrast,0,1,0.7,0.01
// --track@generations:Generations,1,8,2,0.1
// --track@amount:Amount,0,1,1,0.01
// --track@tonerColor_x:Toner Color r,0,1,0.0069954101845983935,0.001
// --track@tonerColor_y:Toner Color g,0,1,0.0069954101845983935,0.001
// --track@tonerColor_z:Toner Color b,0,1,0.0069954101845983935,0.001
// --track@fill:Uneven Fill,0,1,0.4,0.01
// --track@speckle:Speckle,0,1,0.3,0.01
// --track@streaks:Streaks,0,1,0.2,0.01
// --track@shift:Misregistration,0,20,1,0.1
// --check@paper:Paper,0
// --track@paperColor_x:Paper Color r,0,1,0.8631572134510892,0.001
// --track@paperColor_y:Paper Color g,0,1,0.8387990117372213,0.001
// --track@paperColor_z:Paper Color b,0,1,0.775822218312646,0.001
// --track@grain:Grain,0,1,0.4,0.01
// --track@creases:Creases,0,1,0,0.01
// --track@seed:Seed,0,999,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  threshold: f32,
  contrast: f32,
  generations: f32,
  amount: f32,
  tonerColor: vec3<f32>,
  fill: f32,
  speckle: f32,
  streaks: f32,
  shift: f32,
  paper: f32,
  paperColor: vec3<f32>,
  grain: f32,
  creases: f32,
  seed: f32,
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
var<private> p10_nodeVar1 : vec4<f32>;
var<private> p10_nodeVar2 : f32;
var<private> p10_nodeVar3 : f32;
var<private> p10_nodeVar4 : f32;
var<private> p10_nodeVar5 : f32;
var<private> p10_nodeVar6 : vec2<f32>;
var<private> p10_nodeVar7 : vec4<f32>;
var<private> p10_nodeVar8 : vec2<f32>;
var<private> p10_nodeVar9 : vec2<f32>;
var<private> p10_nodeVar10 : vec2<f32>;
var<private> p10_nodeVar11 : vec2<f32>;
var<private> p10_nodeVar12 : vec2<f32>;
var<private> p10_nodeVar13 : vec2<f32>;
var<private> p10_nodeVar14 : vec2<f32>;
var<private> p10_nodeVar15 : vec4<f32>;
var<private> p10_nodeVar16 : vec2<f32>;
var<private> p10_nodeVar17 : vec2<f32>;
var<private> p10_nodeVar18 : vec2<f32>;
var<private> p10_nodeVar19 : vec4<f32>;
var<private> p10_nodeVar20 : vec4<f32>;
var<private> p10_nodeVar21 : vec4<f32>;
var<private> p10_nodeVar22 : vec2<f32>;
var<private> p10_nodeVar23 : vec2<f32>;
var<private> p10_nodeVar24 : vec2<f32>;
var<private> p10_nodeVar25 : vec2<f32>;
var<private> p10_nodeVar26 : vec2<f32>;
var<private> p10_nodeVar27 : vec2<f32>;
var<private> p10_nodeVar28 : vec2<f32>;
var<private> p10_nodeVar29 : vec2<f32>;
var<private> p10_nodeVar30 : vec4<f32>;
var<private> p10_nodeVar31 : vec2<f32>;
var<private> p10_nodeVar32 : vec2<f32>;
var<private> p10_nodeVar33 : vec2<f32>;
var<private> p10_nodeVar34 : vec4<f32>;
var<private> p10_nodeVar35 : vec4<f32>;
var<private> p10_nodeVar36 : vec4<f32>;
var<private> p10_nodeVar37 : vec2<f32>;
var<private> p10_nodeVar38 : vec2<f32>;
var<private> p10_nodeVar39 : vec2<f32>;
var<private> p10_nodeVar40 : vec2<f32>;
var<private> p10_nodeVar41 : vec2<f32>;
var<private> p10_nodeVar42 : vec2<f32>;
var<private> p10_nodeVar43 : vec2<f32>;
var<private> p10_nodeVar44 : vec4<f32>;
var<private> p10_nodeVar45 : vec2<f32>;
var<private> p10_nodeVar46 : vec2<f32>;
var<private> p10_nodeVar47 : vec2<f32>;
var<private> p10_nodeVar48 : vec4<f32>;
var<private> p10_nodeVar49 : vec4<f32>;
var<private> p10_nodeVar50 : vec4<f32>;
var<private> p10_nodeVar51 : vec2<f32>;
var<private> p10_nodeVar52 : vec2<f32>;
var<private> p10_nodeVar53 : vec2<f32>;
var<private> p10_nodeVar54 : vec2<f32>;
var<private> p10_nodeVar55 : vec2<f32>;
var<private> p10_nodeVar56 : vec2<f32>;
var<private> p10_nodeVar57 : vec2<f32>;
var<private> p10_nodeVar58 : vec2<f32>;
var<private> p10_nodeVar59 : vec4<f32>;
var<private> p10_nodeVar60 : vec2<f32>;
var<private> p10_nodeVar61 : vec2<f32>;
var<private> p10_nodeVar62 : vec2<f32>;
var<private> p10_nodeVar63 : vec4<f32>;
var<private> p10_nodeVar64 : vec4<f32>;
var<private> p10_nodeVar65 : vec4<f32>;
var<private> p10_nodeVar66 : vec2<f32>;
var<private> p10_nodeVar67 : vec2<f32>;
var<private> p10_nodeVar68 : vec2<f32>;
var<private> p10_nodeVar69 : vec2<f32>;
var<private> p10_nodeVar70 : vec2<f32>;
var<private> p10_nodeVar71 : vec2<f32>;
var<private> p10_nodeVar72 : vec2<f32>;
var<private> p10_nodeVar73 : vec4<f32>;
var<private> p10_nodeVar74 : vec2<f32>;
var<private> p10_nodeVar75 : vec2<f32>;
var<private> p10_nodeVar76 : vec2<f32>;
var<private> p10_nodeVar77 : vec4<f32>;
var<private> p10_nodeVar78 : vec4<f32>;
var<private> p10_nodeVar79 : vec4<f32>;
var<private> p10_nodeVar80 : vec2<f32>;
var<private> p10_nodeVar81 : vec2<f32>;
var<private> p10_nodeVar82 : vec2<f32>;
var<private> p10_nodeVar83 : vec2<f32>;
var<private> p10_nodeVar84 : vec2<f32>;
var<private> p10_nodeVar85 : vec2<f32>;
var<private> p10_nodeVar86 : vec2<f32>;
var<private> p10_nodeVar87 : vec2<f32>;
var<private> p10_nodeVar88 : vec4<f32>;
var<private> p10_nodeVar89 : vec2<f32>;
var<private> p10_nodeVar90 : vec2<f32>;
var<private> p10_nodeVar91 : vec2<f32>;
var<private> p10_nodeVar92 : vec4<f32>;
var<private> p10_nodeVar93 : vec4<f32>;
var<private> p10_nodeVar94 : vec4<f32>;
var<private> p10_nodeVar95 : vec2<f32>;
var<private> p10_nodeVar96 : vec2<f32>;
var<private> p10_nodeVar97 : vec2<f32>;
var<private> p10_nodeVar98 : vec2<f32>;
var<private> p10_nodeVar99 : vec2<f32>;
var<private> p10_nodeVar100 : vec2<f32>;
var<private> p10_nodeVar101 : vec2<f32>;
var<private> p10_nodeVar102 : vec4<f32>;
var<private> p10_nodeVar103 : vec2<f32>;
var<private> p10_nodeVar104 : vec2<f32>;
var<private> p10_nodeVar105 : vec2<f32>;
var<private> p10_nodeVar106 : vec4<f32>;
var<private> p10_nodeVar107 : vec4<f32>;
var<private> p10_nodeVar108 : vec4<f32>;
var<private> p10_nodeVar109 : vec2<f32>;
var<private> p10_nodeVar110 : vec2<f32>;
var<private> p10_nodeVar111 : vec2<f32>;
var<private> p10_nodeVar112 : vec2<f32>;
var<private> p10_nodeVar113 : vec2<f32>;
var<private> p10_nodeVar114 : vec2<f32>;
var<private> p10_nodeVar115 : vec2<f32>;
var<private> p10_nodeVar116 : vec2<f32>;
var<private> p10_nodeVar117 : vec4<f32>;
var<private> p10_nodeVar118 : vec2<f32>;
var<private> p10_nodeVar119 : vec2<f32>;
var<private> p10_nodeVar120 : vec2<f32>;
var<private> p10_nodeVar121 : vec4<f32>;
var<private> p10_nodeVar122 : vec4<f32>;
var<private> p10_nodeVar123 : vec4<f32>;
var<private> p10_nodeVar124 : vec2<f32>;
var<private> p10_nodeVar125 : vec2<f32>;
var<private> p10_nodeVar126 : vec2<f32>;
var<private> p10_nodeVar127 : vec2<f32>;
var<private> p10_nodeVar128 : vec2<f32>;
var<private> p10_nodeVar129 : vec2<f32>;
var<private> p10_nodeVar130 : vec2<f32>;
var<private> p10_nodeVar131 : vec4<f32>;
var<private> p10_nodeVar132 : vec2<f32>;
var<private> p10_nodeVar133 : vec2<f32>;
var<private> p10_nodeVar134 : vec2<f32>;
var<private> p10_nodeVar135 : vec4<f32>;
var<private> p10_nodeVar136 : vec4<f32>;
var<private> p10_nodeVar137 : vec4<f32>;
var<private> p10_nodeVar138 : vec2<f32>;
var<private> p10_nodeVar139 : vec2<f32>;
var<private> p10_nodeVar140 : vec2<f32>;
var<private> p10_nodeVar141 : vec2<f32>;
var<private> p10_nodeVar142 : vec2<f32>;
var<private> p10_nodeVar143 : vec2<f32>;
var<private> p10_nodeVar144 : vec2<f32>;
var<private> p10_nodeVar145 : vec2<f32>;
var<private> p10_nodeVar146 : vec4<f32>;
var<private> p10_nodeVar147 : vec2<f32>;
var<private> p10_nodeVar148 : vec2<f32>;
var<private> p10_nodeVar149 : vec2<f32>;
var<private> p10_nodeVar150 : vec4<f32>;
var<private> p10_nodeVar151 : vec4<f32>;
var<private> p10_nodeVar152 : vec4<f32>;
var<private> p10_nodeVar153 : vec2<f32>;
var<private> p10_nodeVar154 : vec2<f32>;
var<private> p10_nodeVar155 : vec2<f32>;
var<private> p10_nodeVar156 : vec2<f32>;
var<private> p10_nodeVar157 : vec2<f32>;
var<private> p10_nodeVar158 : vec2<f32>;
var<private> p10_nodeVar159 : vec2<f32>;
var<private> p10_nodeVar160 : vec4<f32>;
var<private> p10_nodeVar161 : vec2<f32>;
var<private> p10_nodeVar162 : vec2<f32>;
var<private> p10_nodeVar163 : vec2<f32>;
var<private> p10_nodeVar164 : vec4<f32>;
var<private> p10_nodeVar165 : vec4<f32>;
var<private> p10_nodeVar166 : vec4<f32>;
var<private> p10_nodeVar167 : vec2<f32>;
var<private> p10_nodeVar168 : vec2<f32>;
var<private> p10_nodeVar169 : vec2<f32>;
var<private> p10_nodeVar170 : vec2<f32>;
var<private> p10_nodeVar171 : vec2<f32>;
var<private> p10_nodeVar172 : vec2<f32>;
var<private> p10_nodeVar173 : vec2<f32>;
var<private> p10_nodeVar174 : vec2<f32>;
var<private> p10_nodeVar175 : vec4<f32>;
var<private> p10_nodeVar176 : vec2<f32>;
var<private> p10_nodeVar177 : vec2<f32>;
var<private> p10_nodeVar178 : vec2<f32>;
var<private> p10_nodeVar179 : vec4<f32>;
var<private> p10_nodeVar180 : vec4<f32>;
var<private> p10_nodeVar181 : vec4<f32>;
var<private> p10_nodeVar182 : vec2<f32>;
var<private> p10_nodeVar183 : vec2<f32>;
var<private> p10_nodeVar184 : vec2<f32>;
var<private> p10_nodeVar185 : vec2<f32>;
var<private> p10_nodeVar186 : vec2<f32>;
var<private> p10_nodeVar187 : vec2<f32>;
var<private> p10_nodeVar188 : vec2<f32>;
var<private> p10_nodeVar189 : vec4<f32>;
var<private> p10_nodeVar190 : vec2<f32>;
var<private> p10_nodeVar191 : vec2<f32>;
var<private> p10_nodeVar192 : vec2<f32>;
var<private> p10_nodeVar193 : vec4<f32>;
var<private> p10_nodeVar194 : vec4<f32>;
var<private> p10_nodeVar195 : vec4<f32>;
var<private> p10_nodeVar196 : vec2<f32>;
var<private> p10_nodeVar197 : vec2<f32>;
var<private> p10_nodeVar198 : vec2<f32>;
var<private> p10_nodeVar199 : vec2<f32>;
var<private> p10_nodeVar200 : vec2<f32>;
var<private> p10_nodeVar201 : vec2<f32>;
var<private> p10_nodeVar202 : vec2<f32>;
var<private> p10_nodeVar203 : vec2<f32>;
var<private> p10_nodeVar204 : vec4<f32>;
var<private> p10_nodeVar205 : vec2<f32>;
var<private> p10_nodeVar206 : vec2<f32>;
var<private> p10_nodeVar207 : vec2<f32>;
var<private> p10_nodeVar208 : vec4<f32>;
var<private> p10_nodeVar209 : vec4<f32>;
var<private> p10_nodeVar210 : vec4<f32>;
var<private> p10_nodeVar211 : vec2<f32>;
var<private> p10_nodeVar212 : vec2<f32>;
var<private> p10_nodeVar213 : vec2<f32>;
var<private> p10_nodeVar214 : vec2<f32>;
var<private> p10_nodeVar215 : vec2<f32>;
var<private> p10_nodeVar216 : vec2<f32>;
var<private> p10_nodeVar217 : vec2<f32>;
var<private> p10_nodeVar218 : vec4<f32>;
var<private> p10_nodeVar219 : vec2<f32>;
var<private> p10_nodeVar220 : vec2<f32>;
var<private> p10_nodeVar221 : vec2<f32>;
var<private> p10_nodeVar222 : vec4<f32>;
var<private> p10_nodeVar223 : vec4<f32>;
var<private> p10_nodeVar224 : vec4<f32>;
var<private> p10_nodeVar225 : vec2<f32>;
var<private> p10_nodeVar226 : vec2<f32>;
var<private> p10_nodeVar227 : vec2<f32>;
var<private> p10_nodeVar228 : vec2<f32>;
var<private> p10_nodeVar229 : vec2<f32>;
var<private> p10_nodeVar230 : vec2<f32>;
var<private> p10_nodeVar231 : vec2<f32>;
var<private> p10_nodeVar232 : vec2<f32>;
var<private> p10_nodeVar233 : vec4<f32>;
var<private> p10_nodeVar234 : vec2<f32>;
var<private> p10_nodeVar235 : vec2<f32>;
var<private> p10_nodeVar236 : vec2<f32>;
var<private> p10_nodeVar237 : vec4<f32>;
var<private> p10_nodeVar238 : vec4<f32>;
var<private> p10_nodeVar239 : vec4<f32>;
var<private> p10_nodeVar240 : vec2<f32>;
var<private> p10_nodeVar241 : vec2<f32>;
var<private> p10_nodeVar242 : vec2<f32>;
var<private> p10_nodeVar243 : vec2<f32>;
var<private> p10_nodeVar244 : vec2<f32>;
var<private> p10_nodeVar245 : vec2<f32>;
var<private> p10_nodeVar246 : vec2<f32>;
var<private> p10_nodeVar247 : vec4<f32>;
var<private> p10_nodeVar248 : vec2<f32>;
var<private> p10_nodeVar249 : vec2<f32>;
var<private> p10_nodeVar250 : vec2<f32>;
var<private> p10_nodeVar251 : vec4<f32>;
var<private> p10_nodeVar252 : vec4<f32>;
var<private> p10_nodeVar253 : vec4<f32>;
var<private> p10_nodeVar254 : vec2<f32>;
var<private> p10_nodeVar255 : vec2<f32>;
var<private> p10_nodeVar256 : vec2<f32>;
var<private> p10_nodeVar257 : vec2<f32>;
var<private> p10_nodeVar258 : vec2<f32>;
var<private> p10_nodeVar259 : vec2<f32>;
var<private> p10_nodeVar260 : vec2<f32>;
var<private> p10_nodeVar261 : vec2<f32>;
var<private> p10_nodeVar262 : vec4<f32>;
var<private> p10_nodeVar263 : vec2<f32>;
var<private> p10_nodeVar264 : vec2<f32>;
var<private> p10_nodeVar265 : vec2<f32>;
var<private> p10_nodeVar266 : vec4<f32>;
var<private> p10_nodeVar267 : vec4<f32>;
var<private> p10_nodeVar268 : vec4<f32>;
var<private> p10_nodeVar269 : vec2<f32>;
var<private> p10_nodeVar270 : vec2<f32>;
var<private> p10_nodeVar271 : vec2<f32>;
var<private> p10_nodeVar272 : vec2<f32>;
var<private> p10_nodeVar273 : vec2<f32>;
var<private> p10_nodeVar274 : vec2<f32>;
var<private> p10_nodeVar275 : vec2<f32>;
var<private> p10_nodeVar276 : vec4<f32>;
var<private> p10_nodeVar277 : vec2<f32>;
var<private> p10_nodeVar278 : vec2<f32>;
var<private> p10_nodeVar279 : vec2<f32>;
var<private> p10_nodeVar280 : vec4<f32>;
var<private> p10_nodeVar281 : vec4<f32>;
var<private> p10_nodeVar282 : vec4<f32>;
var<private> p10_nodeVar283 : vec2<f32>;
var<private> p10_nodeVar284 : vec2<f32>;
var<private> p10_nodeVar285 : vec2<f32>;
var<private> p10_nodeVar286 : vec2<f32>;
var<private> p10_nodeVar287 : vec2<f32>;
var<private> p10_nodeVar288 : vec2<f32>;
var<private> p10_nodeVar289 : vec2<f32>;
var<private> p10_nodeVar290 : vec4<f32>;
var<private> p10_nodeVar291 : vec2<f32>;
var<private> p10_nodeVar292 : vec2<f32>;
var<private> p10_nodeVar293 : vec2<f32>;
var<private> p10_nodeVar294 : vec4<f32>;
var<private> p10_nodeVar295 : vec4<f32>;
var<private> p10_nodeVar296 : vec4<f32>;
var<private> p10_nodeVar297 : f32;
var<private> p10_nodeVar298 : f32;
var<private> p10_nodeVar299 : vec4<f32>;
var<private> p10_nodeVar300 : f32;
var<private> p10_nodeVar301 : vec2<f32>;
var<private> p10_nodeVar302 : vec2<f32>;
var<private> p10_nodeVar303 : vec2<f32>;
var<private> p10_nodeVar304 : vec2<f32>;
var<private> p10_nodeVar305 : vec3<f32>;
var<private> p10_nodeVar306 : vec3<f32>;
var<private> p10_nodeVar307 : vec2<f32>;
var<private> p10_nodeVar308 : vec2<f32>;
var<private> p10_nodeVar309 : vec3<f32>;
var<private> p10_nodeVar310 : vec3<f32>;
var<private> p10_nodeVar311 : vec2<f32>;
var<private> p10_nodeVar312 : vec3<f32>;
var<private> p10_nodeVar313 : vec3<f32>;
var<private> p10_nodeVar314 : vec2<f32>;
var<private> p10_nodeVar315 : vec2<f32>;
var<private> p10_nodeVar316 : vec2<f32>;
var<private> p10_nodeVar317 : vec3<f32>;
var<private> p10_nodeVar318 : vec3<f32>;
var<private> p10_nodeVar319 : vec2<f32>;
var<private> p10_nodeVar320 : vec3<f32>;
var<private> p10_nodeVar321 : vec3<f32>;
var<private> p10_nodeVar322 : vec2<f32>;
var<private> p10_nodeVar323 : vec2<f32>;
var<private> p10_nodeVar324 : vec3<f32>;
var<private> p10_nodeVar325 : vec3<f32>;
var<private> p10_nodeVar326 : vec2<f32>;
var<private> p10_nodeVar327 : vec3<f32>;
var<private> p10_nodeVar328 : vec3<f32>;
var<private> p10_nodeVar329 : vec2<f32>;
var<private> p10_nodeVar330 : vec2<f32>;
var<private> p10_nodeVar331 : vec2<f32>;
var<private> p10_nodeVar332 : vec3<f32>;
var<private> p10_nodeVar333 : vec3<f32>;
var<private> p10_nodeVar334 : vec2<f32>;
var<private> p10_nodeVar335 : vec3<f32>;
var<private> p10_nodeVar336 : vec3<f32>;
var<private> p10_nodeVar337 : f32;
var<private> p10_nodeVar338 : vec2<f32>;
var<private> p10_nodeVar339 : vec2<f32>;
var<private> p10_nodeVar340 : vec3<f32>;
var<private> p10_nodeVar341 : vec3<f32>;
var<private> p10_nodeVar342 : f32;
var<private> p10_nodeVar343 : vec2<f32>;
var<private> p10_nodeVar344 : vec3<f32>;
var<private> p10_nodeVar345 : vec3<f32>;
var<private> p10_nodeVar346 : f32;
var<private> p10_nodeVar347 : f32;
var<private> p10_nodeVar348 : vec2<f32>;
var<private> p10_nodeVar349 : vec3<f32>;
var<private> p10_nodeVar350 : vec3<f32>;
var<private> p10_nodeVar351 : f32;
var<private> p10_nodeVar352 : vec2<f32>;
var<private> p10_nodeVar353 : vec2<f32>;
var<private> p10_nodeVar354 : vec3<f32>;
var<private> p10_nodeVar355 : vec3<f32>;
var<private> p10_nodeVar356 : vec2<f32>;
var<private> p10_nodeVar357 : vec3<f32>;
var<private> p10_nodeVar358 : vec3<f32>;
var<private> p10_nodeVar359 : vec2<f32>;
var<private> p10_nodeVar360 : vec2<f32>;
var<private> p10_nodeVar361 : vec2<f32>;
var<private> p10_nodeVar362 : vec3<f32>;
var<private> p10_nodeVar363 : vec3<f32>;
var<private> p10_nodeVar364 : vec2<f32>;
var<private> p10_nodeVar365 : vec3<f32>;
var<private> p10_nodeVar366 : vec3<f32>;
var<private> p10_nodeVar367 : vec2<f32>;
var<private> p10_nodeVar368 : vec2<f32>;
var<private> p10_nodeVar369 : vec3<f32>;
var<private> p10_nodeVar370 : vec3<f32>;
var<private> p10_nodeVar371 : vec2<f32>;
var<private> p10_nodeVar372 : vec3<f32>;
var<private> p10_nodeVar373 : vec3<f32>;
var<private> p10_nodeVar374 : vec2<f32>;
var<private> p10_nodeVar375 : vec2<f32>;
var<private> p10_nodeVar376 : vec2<f32>;
var<private> p10_nodeVar377 : vec3<f32>;
var<private> p10_nodeVar378 : vec3<f32>;
var<private> p10_nodeVar379 : vec2<f32>;
var<private> p10_nodeVar380 : vec3<f32>;
var<private> p10_nodeVar381 : vec3<f32>;
var<private> p10_nodeVar382 : f32;
var<private> p10_nodeVar383 : f32;
var<private> p10_nodeVar384 : f32;
var<private> p10_nodeVar385 : vec2<f32>;
var<private> p10_nodeVar386 : vec3<f32>;
var<private> p10_nodeVar387 : vec3<f32>;
var<private> p10_nodeVar388 : f32;
var<private> p10_nodeVar389 : vec2<f32>;
var<private> p10_nodeVar390 : vec2<f32>;
var<private> p10_nodeVar391 : vec3<f32>;
var<private> p10_nodeVar392 : vec3<f32>;
var<private> p10_nodeVar393 : vec2<f32>;
var<private> p10_nodeVar394 : vec2<f32>;
var<private> p10_nodeVar395 : vec3<f32>;
var<private> p10_nodeVar396 : vec3<f32>;
var<private> p10_nodeVar397 : vec2<f32>;
var<private> p10_nodeVar398 : vec3<f32>;
var<private> p10_nodeVar399 : vec3<f32>;
var<private> p10_nodeVar400 : vec2<f32>;
var<private> p10_nodeVar401 : vec2<f32>;
var<private> p10_nodeVar402 : vec2<f32>;
var<private> p10_nodeVar403 : vec3<f32>;
var<private> p10_nodeVar404 : vec3<f32>;
var<private> p10_nodeVar405 : vec2<f32>;
var<private> p10_nodeVar406 : vec3<f32>;
var<private> p10_nodeVar407 : vec3<f32>;
var<private> p10_nodeVar408 : f32;
var<private> p10_nodeVar409 : f32;
var<private> p10_nodeVar410 : vec2<f32>;
var<private> p10_nodeVar411 : vec3<f32>;
var<private> p10_nodeVar412 : vec3<f32>;
var<private> p10_nodeVar413 : f32;
var<private> p10_nodeVar414 : vec2<f32>;
var<private> p10_nodeVar415 : vec2<f32>;
var<private> p10_nodeVar416 : vec3<f32>;
var<private> p10_nodeVar417 : vec3<f32>;
var<private> p10_nodeVar418 : vec2<f32>;
var<private> p10_nodeVar419 : vec2<f32>;
var<private> p10_nodeVar420 : vec3<f32>;
var<private> p10_nodeVar421 : vec3<f32>;
var<private> p10_nodeVar422 : vec2<f32>;
var<private> p10_nodeVar423 : vec3<f32>;
var<private> p10_nodeVar424 : vec3<f32>;
var<private> p10_nodeVar425 : vec2<f32>;
var<private> p10_nodeVar426 : vec2<f32>;
var<private> p10_nodeVar427 : vec2<f32>;
var<private> p10_nodeVar428 : vec3<f32>;
var<private> p10_nodeVar429 : vec3<f32>;
var<private> p10_nodeVar430 : vec2<f32>;
var<private> p10_nodeVar431 : vec3<f32>;
var<private> p10_nodeVar432 : vec3<f32>;
var<private> p10_nodeVar433 : f32;
var<private> p10_nodeVar434 : f32;
var<private> p10_nodeVar435 : vec2<f32>;
var<private> p10_nodeVar436 : vec3<f32>;
var<private> p10_nodeVar437 : vec3<f32>;
var<private> p10_nodeVar438 : f32;
var<private> p10_nodeVar439 : vec2<f32>;
var<private> p10_nodeVar440 : vec2<f32>;
var<private> p10_nodeVar441 : vec3<f32>;
var<private> p10_nodeVar442 : vec3<f32>;
var<private> p10_nodeVar443 : vec2<f32>;
var<private> p10_nodeVar444 : vec2<f32>;
var<private> p10_nodeVar445 : vec3<f32>;
var<private> p10_nodeVar446 : vec3<f32>;
var<private> p10_nodeVar447 : vec2<f32>;
var<private> p10_nodeVar448 : vec3<f32>;
var<private> p10_nodeVar449 : vec3<f32>;
var<private> p10_nodeVar450 : vec2<f32>;
var<private> p10_nodeVar451 : vec2<f32>;
var<private> p10_nodeVar452 : vec2<f32>;
var<private> p10_nodeVar453 : vec3<f32>;
var<private> p10_nodeVar454 : vec3<f32>;
var<private> p10_nodeVar455 : vec2<f32>;
var<private> p10_nodeVar456 : vec3<f32>;
var<private> p10_nodeVar457 : vec3<f32>;
var<private> p10_nodeVar458 : f32;
var<private> p10_nodeVar459 : f32;
var<private> p10_nodeVar460 : vec2<f32>;
var<private> p10_nodeVar461 : vec3<f32>;
var<private> p10_nodeVar462 : vec3<f32>;
var<private> p10_nodeVar463 : f32;
var<private> p10_nodeVar464 : vec2<f32>;
var<private> p10_nodeVar465 : vec2<f32>;
var<private> p10_nodeVar466 : vec3<f32>;
var<private> p10_nodeVar467 : vec3<f32>;
var<private> p10_nodeVar468 : vec2<f32>;
var<private> p10_nodeVar469 : vec2<f32>;
var<private> p10_nodeVar470 : vec3<f32>;
var<private> p10_nodeVar471 : vec3<f32>;
var<private> p10_nodeVar472 : vec2<f32>;
var<private> p10_nodeVar473 : vec3<f32>;
var<private> p10_nodeVar474 : vec3<f32>;
var<private> p10_nodeVar475 : vec2<f32>;
var<private> p10_nodeVar476 : vec2<f32>;
var<private> p10_nodeVar477 : vec2<f32>;
var<private> p10_nodeVar478 : vec3<f32>;
var<private> p10_nodeVar479 : vec3<f32>;
var<private> p10_nodeVar480 : vec2<f32>;
var<private> p10_nodeVar481 : vec3<f32>;
var<private> p10_nodeVar482 : vec3<f32>;
var<private> p10_nodeVar483 : f32;
var<private> p10_nodeVar484 : vec4<f32>;
var<private> p10_nodeVar485 : vec3<f32>;
var<private> p10_nodeVar486 : bool;
var<private> p10_nodeVar487 : vec2<f32>;
var<private> p10_nodeVar488 : vec2<f32>;
var<private> p10_nodeVar489 : vec3<f32>;
var<private> p10_nodeVar490 : vec3<f32>;
var<private> p10_nodeVar491 : vec2<f32>;
var<private> p10_nodeVar492 : vec3<f32>;
var<private> p10_nodeVar493 : vec3<f32>;
var<private> p10_nodeVar494 : vec2<f32>;
var<private> p10_nodeVar495 : vec2<f32>;
var<private> p10_nodeVar496 : vec2<f32>;
var<private> p10_nodeVar497 : vec3<f32>;
var<private> p10_nodeVar498 : vec3<f32>;
var<private> p10_nodeVar499 : vec2<f32>;
var<private> p10_nodeVar500 : vec3<f32>;
var<private> p10_nodeVar501 : vec3<f32>;
var<private> p10_nodeVar502 : f32;
var<private> p10_nodeVar503 : f32;
var<private> p10_nodeVar504 : vec4<f32>;
var<private> p10_nodeVar505 : vec3<f32>;
var<private> p10_nodeVar506 : f32;
var<private> p10_nodeVar507 : vec3<f32>;
var<private> p10_nodeVar508 : vec4<f32>;
var<private> p10_nodeVar509 : f32;
var<private> p10_nodeVar510 : f32;
var<private> p10_Output : vec4<f32>;
var<private> p10_nodeVar511 : vec4<f32>;

// codes


fn p10_main(door_uv: vec2f) -> p10_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p10_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p10_nodeVar1 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
	p10_nodeVar2 = ( f32(knobs.generations) - 1.0 );
	p10_nodeVar3 = clamp( log2( max( ( ( ( ( p10_nodeVar2 * 0.55 ) + 0.25 ) * f32(1.0) ) / 1.2 ), 1.0 ) ), 0.0, 10.0 );
	p10_nodeVar4 = floor( p10_nodeVar3 );
	p10_nodeVar5 = ( p10_nodeVar3 - p10_nodeVar4 );

	if ( ( p10_nodeVar4 == 0.0 ) ) {

		p10_nodeVar6 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar7 = picture_read_level( p10_nodeVar6, 0.0 );
		p10_nodeVar1 = vec4<f32>( ( vec3<f32>( p10_nodeVar7.x, p10_nodeVar7.y, p10_nodeVar7.z ) * vec3<f32>( p10_nodeVar7.w ) ), p10_nodeVar7.w );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar8 = ( ( p10_nodeVar6 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar9 = floor( p10_nodeVar8 );
			p10_nodeVar10 = ( p10_nodeVar8 - p10_nodeVar9 );
			p10_nodeVar11 = ( p10_nodeVar10 * p10_nodeVar10 );
			p10_nodeVar12 = ( p10_nodeVar11 * p10_nodeVar10 );
			p10_nodeVar13 = ( ( ( ( p10_nodeVar12 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar11 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar14 = ( ( ( p10_nodeVar9 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar13 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar10 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar10 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar10 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar13 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar15 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar14.x, p10_nodeVar14.y ), 0.0 );
			p10_nodeVar16 = ( p10_nodeVar12 / vec2<f32>( 6.0 ) );
			p10_nodeVar17 = ( ( ( ( ( ( p10_nodeVar12 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar11 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar10 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar16 );
			p10_nodeVar18 = ( ( ( p10_nodeVar9 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar16 / p10_nodeVar17 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar19 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar18.x, p10_nodeVar14.y ), 0.0 );
			p10_nodeVar20 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar14.x, p10_nodeVar18.y ), 0.0 );
			p10_nodeVar21 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar18.x, p10_nodeVar18.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar15, p10_nodeVar19, p10_nodeVar17.x ), mix( p10_nodeVar20, p10_nodeVar21, p10_nodeVar17.x ), p10_nodeVar17.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 1.0 ) ) {

		p10_nodeVar22 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar23 = ( ( p10_nodeVar22 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar24 = floor( p10_nodeVar23 );
		p10_nodeVar25 = ( p10_nodeVar23 - p10_nodeVar24 );
		p10_nodeVar26 = ( p10_nodeVar25 * p10_nodeVar25 );
		p10_nodeVar27 = ( p10_nodeVar26 * p10_nodeVar25 );
		p10_nodeVar28 = ( ( ( ( p10_nodeVar27 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar26 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar29 = ( ( ( p10_nodeVar24 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar28 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar28 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar30 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar29.y ), 0.0 );
		p10_nodeVar31 = ( p10_nodeVar27 / vec2<f32>( 6.0 ) );
		p10_nodeVar32 = ( ( ( ( ( ( p10_nodeVar27 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar26 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar25 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar31 );
		p10_nodeVar33 = ( ( ( p10_nodeVar24 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar31 / p10_nodeVar32 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar34 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar33.x, p10_nodeVar29.y ), 0.0 );
		p10_nodeVar35 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar33.y ), 0.0 );
		p10_nodeVar36 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar33.x, p10_nodeVar33.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar30, p10_nodeVar34, p10_nodeVar32.x ), mix( p10_nodeVar35, p10_nodeVar36, p10_nodeVar32.x ), p10_nodeVar32.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar37 = ( ( p10_nodeVar22 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar38 = floor( p10_nodeVar37 );
			p10_nodeVar39 = ( p10_nodeVar37 - p10_nodeVar38 );
			p10_nodeVar40 = ( p10_nodeVar39 * p10_nodeVar39 );
			p10_nodeVar41 = ( p10_nodeVar40 * p10_nodeVar39 );
			p10_nodeVar42 = ( ( ( ( p10_nodeVar41 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar40 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar43 = ( ( ( p10_nodeVar38 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar42 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar42 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar44 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar45 = ( p10_nodeVar41 / vec2<f32>( 6.0 ) );
			p10_nodeVar46 = ( ( ( ( ( ( p10_nodeVar41 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar40 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar39 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar45 );
			p10_nodeVar47 = ( ( ( p10_nodeVar38 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar45 / p10_nodeVar46 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar48 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar47.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar49 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar47.y ), 0.0 );
			p10_nodeVar50 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar47.x, p10_nodeVar47.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar44, p10_nodeVar48, p10_nodeVar46.x ), mix( p10_nodeVar49, p10_nodeVar50, p10_nodeVar46.x ), p10_nodeVar46.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 2.0 ) ) {

		p10_nodeVar51 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar52 = ( ( p10_nodeVar51 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar53 = floor( p10_nodeVar52 );
		p10_nodeVar54 = ( p10_nodeVar52 - p10_nodeVar53 );
		p10_nodeVar55 = ( p10_nodeVar54 * p10_nodeVar54 );
		p10_nodeVar56 = ( p10_nodeVar55 * p10_nodeVar54 );
		p10_nodeVar57 = ( ( ( ( p10_nodeVar56 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar55 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar58 = ( ( ( p10_nodeVar53 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar57 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar54 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar54 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar54 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar57 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar59 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar58.x, p10_nodeVar58.y ), 0.0 );
		p10_nodeVar60 = ( p10_nodeVar56 / vec2<f32>( 6.0 ) );
		p10_nodeVar61 = ( ( ( ( ( ( p10_nodeVar56 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar55 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar54 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar60 );
		p10_nodeVar62 = ( ( ( p10_nodeVar53 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar60 / p10_nodeVar61 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar63 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar62.x, p10_nodeVar58.y ), 0.0 );
		p10_nodeVar64 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar58.x, p10_nodeVar62.y ), 0.0 );
		p10_nodeVar65 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar62.x, p10_nodeVar62.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar59, p10_nodeVar63, p10_nodeVar61.x ), mix( p10_nodeVar64, p10_nodeVar65, p10_nodeVar61.x ), p10_nodeVar61.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar66 = ( ( p10_nodeVar51 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar67 = floor( p10_nodeVar66 );
			p10_nodeVar68 = ( p10_nodeVar66 - p10_nodeVar67 );
			p10_nodeVar69 = ( p10_nodeVar68 * p10_nodeVar68 );
			p10_nodeVar70 = ( p10_nodeVar69 * p10_nodeVar68 );
			p10_nodeVar71 = ( ( ( ( p10_nodeVar70 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar69 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar72 = ( ( ( p10_nodeVar67 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar71 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar68 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar68 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar68 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar71 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar73 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar72.x, p10_nodeVar72.y ), 0.0 );
			p10_nodeVar74 = ( p10_nodeVar70 / vec2<f32>( 6.0 ) );
			p10_nodeVar75 = ( ( ( ( ( ( p10_nodeVar70 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar69 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar68 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar74 );
			p10_nodeVar76 = ( ( ( p10_nodeVar67 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar74 / p10_nodeVar75 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar77 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar76.x, p10_nodeVar72.y ), 0.0 );
			p10_nodeVar78 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar72.x, p10_nodeVar76.y ), 0.0 );
			p10_nodeVar79 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar76.x, p10_nodeVar76.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar73, p10_nodeVar77, p10_nodeVar75.x ), mix( p10_nodeVar78, p10_nodeVar79, p10_nodeVar75.x ), p10_nodeVar75.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 3.0 ) ) {

		p10_nodeVar80 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar81 = ( ( p10_nodeVar80 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar82 = floor( p10_nodeVar81 );
		p10_nodeVar83 = ( p10_nodeVar81 - p10_nodeVar82 );
		p10_nodeVar84 = ( p10_nodeVar83 * p10_nodeVar83 );
		p10_nodeVar85 = ( p10_nodeVar84 * p10_nodeVar83 );
		p10_nodeVar86 = ( ( ( ( p10_nodeVar85 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar84 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar87 = ( ( ( p10_nodeVar82 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar86 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar83 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar83 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar83 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar86 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar88 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar87.x, p10_nodeVar87.y ), 0.0 );
		p10_nodeVar89 = ( p10_nodeVar85 / vec2<f32>( 6.0 ) );
		p10_nodeVar90 = ( ( ( ( ( ( p10_nodeVar85 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar84 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar83 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar89 );
		p10_nodeVar91 = ( ( ( p10_nodeVar82 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar89 / p10_nodeVar90 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar92 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar91.x, p10_nodeVar87.y ), 0.0 );
		p10_nodeVar93 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar87.x, p10_nodeVar91.y ), 0.0 );
		p10_nodeVar94 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar91.x, p10_nodeVar91.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar88, p10_nodeVar92, p10_nodeVar90.x ), mix( p10_nodeVar93, p10_nodeVar94, p10_nodeVar90.x ), p10_nodeVar90.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar95 = ( ( p10_nodeVar80 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar96 = floor( p10_nodeVar95 );
			p10_nodeVar97 = ( p10_nodeVar95 - p10_nodeVar96 );
			p10_nodeVar98 = ( p10_nodeVar97 * p10_nodeVar97 );
			p10_nodeVar99 = ( p10_nodeVar98 * p10_nodeVar97 );
			p10_nodeVar100 = ( ( ( ( p10_nodeVar99 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar98 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar101 = ( ( ( p10_nodeVar96 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar100 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar97 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar97 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar97 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar100 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar102 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar101.x, p10_nodeVar101.y ), 0.0 );
			p10_nodeVar103 = ( p10_nodeVar99 / vec2<f32>( 6.0 ) );
			p10_nodeVar104 = ( ( ( ( ( ( p10_nodeVar99 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar98 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar97 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar103 );
			p10_nodeVar105 = ( ( ( p10_nodeVar96 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar103 / p10_nodeVar104 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar106 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar105.x, p10_nodeVar101.y ), 0.0 );
			p10_nodeVar107 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar101.x, p10_nodeVar105.y ), 0.0 );
			p10_nodeVar108 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar105.x, p10_nodeVar105.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar102, p10_nodeVar106, p10_nodeVar104.x ), mix( p10_nodeVar107, p10_nodeVar108, p10_nodeVar104.x ), p10_nodeVar104.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 4.0 ) ) {

		p10_nodeVar109 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar110 = ( ( p10_nodeVar109 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar111 = floor( p10_nodeVar110 );
		p10_nodeVar112 = ( p10_nodeVar110 - p10_nodeVar111 );
		p10_nodeVar113 = ( p10_nodeVar112 * p10_nodeVar112 );
		p10_nodeVar114 = ( p10_nodeVar113 * p10_nodeVar112 );
		p10_nodeVar115 = ( ( ( ( p10_nodeVar114 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar113 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar116 = ( ( ( p10_nodeVar111 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar115 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar112 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar112 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar112 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar115 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar117 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar116.x, p10_nodeVar116.y ), 0.0 );
		p10_nodeVar118 = ( p10_nodeVar114 / vec2<f32>( 6.0 ) );
		p10_nodeVar119 = ( ( ( ( ( ( p10_nodeVar114 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar113 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar112 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar118 );
		p10_nodeVar120 = ( ( ( p10_nodeVar111 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar118 / p10_nodeVar119 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar121 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar120.x, p10_nodeVar116.y ), 0.0 );
		p10_nodeVar122 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar116.x, p10_nodeVar120.y ), 0.0 );
		p10_nodeVar123 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar120.x, p10_nodeVar120.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar117, p10_nodeVar121, p10_nodeVar119.x ), mix( p10_nodeVar122, p10_nodeVar123, p10_nodeVar119.x ), p10_nodeVar119.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar124 = ( ( p10_nodeVar109 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar125 = floor( p10_nodeVar124 );
			p10_nodeVar126 = ( p10_nodeVar124 - p10_nodeVar125 );
			p10_nodeVar127 = ( p10_nodeVar126 * p10_nodeVar126 );
			p10_nodeVar128 = ( p10_nodeVar127 * p10_nodeVar126 );
			p10_nodeVar129 = ( ( ( ( p10_nodeVar128 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar127 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar130 = ( ( ( p10_nodeVar125 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar129 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar126 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar126 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar126 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar129 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar131 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar130.x, p10_nodeVar130.y ), 0.0 );
			p10_nodeVar132 = ( p10_nodeVar128 / vec2<f32>( 6.0 ) );
			p10_nodeVar133 = ( ( ( ( ( ( p10_nodeVar128 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar127 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar126 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar132 );
			p10_nodeVar134 = ( ( ( p10_nodeVar125 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar132 / p10_nodeVar133 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar135 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar134.x, p10_nodeVar130.y ), 0.0 );
			p10_nodeVar136 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar130.x, p10_nodeVar134.y ), 0.0 );
			p10_nodeVar137 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar134.x, p10_nodeVar134.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar131, p10_nodeVar135, p10_nodeVar133.x ), mix( p10_nodeVar136, p10_nodeVar137, p10_nodeVar133.x ), p10_nodeVar133.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 5.0 ) ) {

		p10_nodeVar138 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar139 = ( ( p10_nodeVar138 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar140 = floor( p10_nodeVar139 );
		p10_nodeVar141 = ( p10_nodeVar139 - p10_nodeVar140 );
		p10_nodeVar142 = ( p10_nodeVar141 * p10_nodeVar141 );
		p10_nodeVar143 = ( p10_nodeVar142 * p10_nodeVar141 );
		p10_nodeVar144 = ( ( ( ( p10_nodeVar143 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar142 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar145 = ( ( ( p10_nodeVar140 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar144 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar141 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar141 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar141 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar144 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar146 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar145.x, p10_nodeVar145.y ), 0.0 );
		p10_nodeVar147 = ( p10_nodeVar143 / vec2<f32>( 6.0 ) );
		p10_nodeVar148 = ( ( ( ( ( ( p10_nodeVar143 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar142 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar141 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar147 );
		p10_nodeVar149 = ( ( ( p10_nodeVar140 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar147 / p10_nodeVar148 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar150 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar149.x, p10_nodeVar145.y ), 0.0 );
		p10_nodeVar151 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar145.x, p10_nodeVar149.y ), 0.0 );
		p10_nodeVar152 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar149.x, p10_nodeVar149.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar146, p10_nodeVar150, p10_nodeVar148.x ), mix( p10_nodeVar151, p10_nodeVar152, p10_nodeVar148.x ), p10_nodeVar148.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar153 = ( ( p10_nodeVar138 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar154 = floor( p10_nodeVar153 );
			p10_nodeVar155 = ( p10_nodeVar153 - p10_nodeVar154 );
			p10_nodeVar156 = ( p10_nodeVar155 * p10_nodeVar155 );
			p10_nodeVar157 = ( p10_nodeVar156 * p10_nodeVar155 );
			p10_nodeVar158 = ( ( ( ( p10_nodeVar157 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar156 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar159 = ( ( ( p10_nodeVar154 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar158 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar155 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar155 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar155 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar158 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar160 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar159.x, p10_nodeVar159.y ), 0.0 );
			p10_nodeVar161 = ( p10_nodeVar157 / vec2<f32>( 6.0 ) );
			p10_nodeVar162 = ( ( ( ( ( ( p10_nodeVar157 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar156 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar155 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar161 );
			p10_nodeVar163 = ( ( ( p10_nodeVar154 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar161 / p10_nodeVar162 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar164 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar163.x, p10_nodeVar159.y ), 0.0 );
			p10_nodeVar165 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar159.x, p10_nodeVar163.y ), 0.0 );
			p10_nodeVar166 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar163.x, p10_nodeVar163.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar160, p10_nodeVar164, p10_nodeVar162.x ), mix( p10_nodeVar165, p10_nodeVar166, p10_nodeVar162.x ), p10_nodeVar162.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 6.0 ) ) {

		p10_nodeVar167 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar168 = ( ( p10_nodeVar167 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar169 = floor( p10_nodeVar168 );
		p10_nodeVar170 = ( p10_nodeVar168 - p10_nodeVar169 );
		p10_nodeVar171 = ( p10_nodeVar170 * p10_nodeVar170 );
		p10_nodeVar172 = ( p10_nodeVar171 * p10_nodeVar170 );
		p10_nodeVar173 = ( ( ( ( p10_nodeVar172 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar171 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar174 = ( ( ( p10_nodeVar169 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar173 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar170 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar170 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar170 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar173 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar175 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar174.x, p10_nodeVar174.y ), 0.0 );
		p10_nodeVar176 = ( p10_nodeVar172 / vec2<f32>( 6.0 ) );
		p10_nodeVar177 = ( ( ( ( ( ( p10_nodeVar172 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar171 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar170 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar176 );
		p10_nodeVar178 = ( ( ( p10_nodeVar169 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar176 / p10_nodeVar177 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar179 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar178.x, p10_nodeVar174.y ), 0.0 );
		p10_nodeVar180 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar174.x, p10_nodeVar178.y ), 0.0 );
		p10_nodeVar181 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar178.x, p10_nodeVar178.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar175, p10_nodeVar179, p10_nodeVar177.x ), mix( p10_nodeVar180, p10_nodeVar181, p10_nodeVar177.x ), p10_nodeVar177.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar182 = ( ( p10_nodeVar167 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar183 = floor( p10_nodeVar182 );
			p10_nodeVar184 = ( p10_nodeVar182 - p10_nodeVar183 );
			p10_nodeVar185 = ( p10_nodeVar184 * p10_nodeVar184 );
			p10_nodeVar186 = ( p10_nodeVar185 * p10_nodeVar184 );
			p10_nodeVar187 = ( ( ( ( p10_nodeVar186 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar185 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar188 = ( ( ( p10_nodeVar183 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar187 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar184 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar184 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar184 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar187 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar189 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar188.x, p10_nodeVar188.y ), 0.0 );
			p10_nodeVar190 = ( p10_nodeVar186 / vec2<f32>( 6.0 ) );
			p10_nodeVar191 = ( ( ( ( ( ( p10_nodeVar186 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar185 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar184 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar190 );
			p10_nodeVar192 = ( ( ( p10_nodeVar183 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar190 / p10_nodeVar191 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar193 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar192.x, p10_nodeVar188.y ), 0.0 );
			p10_nodeVar194 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar188.x, p10_nodeVar192.y ), 0.0 );
			p10_nodeVar195 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar192.x, p10_nodeVar192.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar189, p10_nodeVar193, p10_nodeVar191.x ), mix( p10_nodeVar194, p10_nodeVar195, p10_nodeVar191.x ), p10_nodeVar191.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 7.0 ) ) {

		p10_nodeVar196 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar197 = ( ( p10_nodeVar196 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar198 = floor( p10_nodeVar197 );
		p10_nodeVar199 = ( p10_nodeVar197 - p10_nodeVar198 );
		p10_nodeVar200 = ( p10_nodeVar199 * p10_nodeVar199 );
		p10_nodeVar201 = ( p10_nodeVar200 * p10_nodeVar199 );
		p10_nodeVar202 = ( ( ( ( p10_nodeVar201 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar200 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar203 = ( ( ( p10_nodeVar198 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar202 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar199 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar199 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar199 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar202 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar204 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar203.x, p10_nodeVar203.y ), 0.0 );
		p10_nodeVar205 = ( p10_nodeVar201 / vec2<f32>( 6.0 ) );
		p10_nodeVar206 = ( ( ( ( ( ( p10_nodeVar201 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar200 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar199 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar205 );
		p10_nodeVar207 = ( ( ( p10_nodeVar198 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar205 / p10_nodeVar206 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar208 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar207.x, p10_nodeVar203.y ), 0.0 );
		p10_nodeVar209 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar203.x, p10_nodeVar207.y ), 0.0 );
		p10_nodeVar210 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar207.x, p10_nodeVar207.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar204, p10_nodeVar208, p10_nodeVar206.x ), mix( p10_nodeVar209, p10_nodeVar210, p10_nodeVar206.x ), p10_nodeVar206.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar211 = ( ( p10_nodeVar196 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar212 = floor( p10_nodeVar211 );
			p10_nodeVar213 = ( p10_nodeVar211 - p10_nodeVar212 );
			p10_nodeVar214 = ( p10_nodeVar213 * p10_nodeVar213 );
			p10_nodeVar215 = ( p10_nodeVar214 * p10_nodeVar213 );
			p10_nodeVar216 = ( ( ( ( p10_nodeVar215 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar214 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar217 = ( ( ( p10_nodeVar212 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar216 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar213 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar213 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar213 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar216 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar218 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar217.x, p10_nodeVar217.y ), 0.0 );
			p10_nodeVar219 = ( p10_nodeVar215 / vec2<f32>( 6.0 ) );
			p10_nodeVar220 = ( ( ( ( ( ( p10_nodeVar215 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar214 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar213 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar219 );
			p10_nodeVar221 = ( ( ( p10_nodeVar212 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar219 / p10_nodeVar220 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar222 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar221.x, p10_nodeVar217.y ), 0.0 );
			p10_nodeVar223 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar217.x, p10_nodeVar221.y ), 0.0 );
			p10_nodeVar224 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar221.x, p10_nodeVar221.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar218, p10_nodeVar222, p10_nodeVar220.x ), mix( p10_nodeVar223, p10_nodeVar224, p10_nodeVar220.x ), p10_nodeVar220.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 8.0 ) ) {

		p10_nodeVar225 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar226 = ( ( p10_nodeVar225 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar227 = floor( p10_nodeVar226 );
		p10_nodeVar228 = ( p10_nodeVar226 - p10_nodeVar227 );
		p10_nodeVar229 = ( p10_nodeVar228 * p10_nodeVar228 );
		p10_nodeVar230 = ( p10_nodeVar229 * p10_nodeVar228 );
		p10_nodeVar231 = ( ( ( ( p10_nodeVar230 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar229 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar232 = ( ( ( p10_nodeVar227 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar231 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar228 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar228 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar228 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar231 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar233 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar232.x, p10_nodeVar232.y ), 0.0 );
		p10_nodeVar234 = ( p10_nodeVar230 / vec2<f32>( 6.0 ) );
		p10_nodeVar235 = ( ( ( ( ( ( p10_nodeVar230 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar229 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar228 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar234 );
		p10_nodeVar236 = ( ( ( p10_nodeVar227 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar234 / p10_nodeVar235 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar237 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar236.x, p10_nodeVar232.y ), 0.0 );
		p10_nodeVar238 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar232.x, p10_nodeVar236.y ), 0.0 );
		p10_nodeVar239 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar236.x, p10_nodeVar236.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar233, p10_nodeVar237, p10_nodeVar235.x ), mix( p10_nodeVar238, p10_nodeVar239, p10_nodeVar235.x ), p10_nodeVar235.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar240 = ( ( p10_nodeVar225 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar241 = floor( p10_nodeVar240 );
			p10_nodeVar242 = ( p10_nodeVar240 - p10_nodeVar241 );
			p10_nodeVar243 = ( p10_nodeVar242 * p10_nodeVar242 );
			p10_nodeVar244 = ( p10_nodeVar243 * p10_nodeVar242 );
			p10_nodeVar245 = ( ( ( ( p10_nodeVar244 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar243 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar246 = ( ( ( p10_nodeVar241 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar245 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar242 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar242 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar242 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar245 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar247 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar246.x, p10_nodeVar246.y ), 0.0 );
			p10_nodeVar248 = ( p10_nodeVar244 / vec2<f32>( 6.0 ) );
			p10_nodeVar249 = ( ( ( ( ( ( p10_nodeVar244 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar243 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar242 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar248 );
			p10_nodeVar250 = ( ( ( p10_nodeVar241 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar248 / p10_nodeVar249 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar251 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar250.x, p10_nodeVar246.y ), 0.0 );
			p10_nodeVar252 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar246.x, p10_nodeVar250.y ), 0.0 );
			p10_nodeVar253 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar250.x, p10_nodeVar250.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar247, p10_nodeVar251, p10_nodeVar249.x ), mix( p10_nodeVar252, p10_nodeVar253, p10_nodeVar249.x ), p10_nodeVar249.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 == 9.0 ) ) {

		p10_nodeVar254 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p10_nodeVar255 = ( ( p10_nodeVar254 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar256 = floor( p10_nodeVar255 );
		p10_nodeVar257 = ( p10_nodeVar255 - p10_nodeVar256 );
		p10_nodeVar258 = ( p10_nodeVar257 * p10_nodeVar257 );
		p10_nodeVar259 = ( p10_nodeVar258 * p10_nodeVar257 );
		p10_nodeVar260 = ( ( ( ( p10_nodeVar259 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar258 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar261 = ( ( ( p10_nodeVar256 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar260 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar257 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar257 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar257 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar260 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar262 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar261.x, p10_nodeVar261.y ), 0.0 );
		p10_nodeVar263 = ( p10_nodeVar259 / vec2<f32>( 6.0 ) );
		p10_nodeVar264 = ( ( ( ( ( ( p10_nodeVar259 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar258 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar257 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar263 );
		p10_nodeVar265 = ( ( ( p10_nodeVar256 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar263 / p10_nodeVar264 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p10_nodeVar266 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar265.x, p10_nodeVar261.y ), 0.0 );
		p10_nodeVar267 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar261.x, p10_nodeVar265.y ), 0.0 );
		p10_nodeVar268 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar265.x, p10_nodeVar265.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar262, p10_nodeVar266, p10_nodeVar264.x ), mix( p10_nodeVar267, p10_nodeVar268, p10_nodeVar264.x ), p10_nodeVar264.y );

		if ( ( p10_nodeVar5 > 0.0 ) ) {

			p10_nodeVar269 = ( ( p10_nodeVar254 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar270 = floor( p10_nodeVar269 );
			p10_nodeVar271 = ( p10_nodeVar269 - p10_nodeVar270 );
			p10_nodeVar272 = ( p10_nodeVar271 * p10_nodeVar271 );
			p10_nodeVar273 = ( p10_nodeVar272 * p10_nodeVar271 );
			p10_nodeVar274 = ( ( ( ( p10_nodeVar273 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar272 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar275 = ( ( ( p10_nodeVar270 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar274 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar271 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar271 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar271 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar274 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar276 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar275.x, p10_nodeVar275.y ), 0.0 );
			p10_nodeVar277 = ( p10_nodeVar273 / vec2<f32>( 6.0 ) );
			p10_nodeVar278 = ( ( ( ( ( ( p10_nodeVar273 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar272 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar271 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar277 );
			p10_nodeVar279 = ( ( ( p10_nodeVar270 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar277 / p10_nodeVar278 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar280 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar279.x, p10_nodeVar275.y ), 0.0 );
			p10_nodeVar281 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar275.x, p10_nodeVar279.y ), 0.0 );
			p10_nodeVar282 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar279.x, p10_nodeVar279.y ), 0.0 );
			p10_nodeVar1 = mix( p10_nodeVar1, mix( mix( p10_nodeVar276, p10_nodeVar280, p10_nodeVar278.x ), mix( p10_nodeVar281, p10_nodeVar282, p10_nodeVar278.x ), p10_nodeVar278.y ), p10_nodeVar5 );
			

		}

		

	}


	if ( ( p10_nodeVar4 >= 10.0 ) ) {

		p10_nodeVar283 = ( ( ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar284 = floor( p10_nodeVar283 );
		p10_nodeVar285 = ( p10_nodeVar283 - p10_nodeVar284 );
		p10_nodeVar286 = ( p10_nodeVar285 * p10_nodeVar285 );
		p10_nodeVar287 = ( p10_nodeVar286 * p10_nodeVar285 );
		p10_nodeVar288 = ( ( ( ( p10_nodeVar287 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar286 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar289 = ( ( ( p10_nodeVar284 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar288 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar285 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar285 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar285 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar288 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p10_nodeVar290 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar289.x, p10_nodeVar289.y ), 0.0 );
		p10_nodeVar291 = ( p10_nodeVar287 / vec2<f32>( 6.0 ) );
		p10_nodeVar292 = ( ( ( ( ( ( p10_nodeVar287 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar286 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar285 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar291 );
		p10_nodeVar293 = ( ( ( p10_nodeVar284 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar291 / p10_nodeVar292 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p10_nodeVar294 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar293.x, p10_nodeVar289.y ), 0.0 );
		p10_nodeVar295 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar289.x, p10_nodeVar293.y ), 0.0 );
		p10_nodeVar296 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar293.x, p10_nodeVar293.y ), 0.0 );
		p10_nodeVar1 = mix( mix( p10_nodeVar290, p10_nodeVar294, p10_nodeVar292.x ), mix( p10_nodeVar295, p10_nodeVar296, p10_nodeVar292.x ), p10_nodeVar292.y );
		

	}

	p10_nodeVar297 = ( mix( 0.45, 0.015, f32(knobs.contrast) ) / ( 1.0 + ( p10_nodeVar2 * 0.25 ) ) );
	p10_nodeVar299 = vec4<f32>( ( p10_nodeVar1.xyz / vec3<f32>( max( p10_nodeVar1.w, 0.0001 ) ) ), p10_nodeVar1.w );
	p10_nodeVar300 = clamp( dot( vec3<f32>( p10_nodeVar299.x, p10_nodeVar299.y, p10_nodeVar299.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p10_nodeVar300 <= 0.0031308 ) ) {

		p10_nodeVar298 = ( p10_nodeVar300 * 12.92 );

	} else {

		p10_nodeVar298 = ( ( pow( p10_nodeVar300, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p10_nodeVar301 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p10_nodeVar302 = ( p10_nodeVar301 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p10_nodeVar303 = vec2<f32>( ( f32(knobs.seed) * 13.7 ), ( f32(knobs.seed) * -7.3 ) );
	p10_nodeVar304 = ( floor( p10_nodeVar302 ) + p10_nodeVar303 );
	p10_nodeVar305 = fract( ( vec3<f32>( p10_nodeVar304.x, p10_nodeVar304.y, p10_nodeVar304.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar306 = ( p10_nodeVar305 + vec3<f32>( dot( p10_nodeVar305, ( vec3<f32>( p10_nodeVar305.y, p10_nodeVar305.z, p10_nodeVar305.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar307 = ( ( p10_nodeVar302 / vec2<f32>( 38.0 ) ) + p10_nodeVar303 );
	p10_nodeVar308 = floor( p10_nodeVar307 );
	p10_nodeVar309 = fract( ( vec3<f32>( p10_nodeVar308.x, p10_nodeVar308.y, p10_nodeVar308.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar310 = ( p10_nodeVar309 + vec3<f32>( dot( p10_nodeVar309, ( vec3<f32>( p10_nodeVar309.y, p10_nodeVar309.z, p10_nodeVar309.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar311 = ( p10_nodeVar308 + vec2<f32>( 1.0, 0.0 ) );
	p10_nodeVar312 = fract( ( vec3<f32>( p10_nodeVar311.x, p10_nodeVar311.y, p10_nodeVar311.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar313 = ( p10_nodeVar312 + vec3<f32>( dot( p10_nodeVar312, ( vec3<f32>( p10_nodeVar312.y, p10_nodeVar312.z, p10_nodeVar312.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar314 = fract( p10_nodeVar307 );
	p10_nodeVar315 = ( ( p10_nodeVar314 * p10_nodeVar314 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar314 * vec2<f32>( 2.0 ) ) ) );
	p10_nodeVar316 = ( p10_nodeVar308 + vec2<f32>( 0.0, 1.0 ) );
	p10_nodeVar317 = fract( ( vec3<f32>( p10_nodeVar316.x, p10_nodeVar316.y, p10_nodeVar316.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar318 = ( p10_nodeVar317 + vec3<f32>( dot( p10_nodeVar317, ( vec3<f32>( p10_nodeVar317.y, p10_nodeVar317.z, p10_nodeVar317.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar319 = ( p10_nodeVar308 + vec2<f32>( 1.0, 1.0 ) );
	p10_nodeVar320 = fract( ( vec3<f32>( p10_nodeVar319.x, p10_nodeVar319.y, p10_nodeVar319.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar321 = ( p10_nodeVar320 + vec3<f32>( dot( p10_nodeVar320, ( vec3<f32>( p10_nodeVar320.y, p10_nodeVar320.z, p10_nodeVar320.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar322 = ( ( p10_nodeVar302 / vec2<f32>( 11.0 ) ) + ( p10_nodeVar303 * vec2<f32>( 2.0 ) ) );
	p10_nodeVar323 = floor( p10_nodeVar322 );
	p10_nodeVar324 = fract( ( vec3<f32>( p10_nodeVar323.x, p10_nodeVar323.y, p10_nodeVar323.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar325 = ( p10_nodeVar324 + vec3<f32>( dot( p10_nodeVar324, ( vec3<f32>( p10_nodeVar324.y, p10_nodeVar324.z, p10_nodeVar324.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar326 = ( p10_nodeVar323 + vec2<f32>( 1.0, 0.0 ) );
	p10_nodeVar327 = fract( ( vec3<f32>( p10_nodeVar326.x, p10_nodeVar326.y, p10_nodeVar326.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar328 = ( p10_nodeVar327 + vec3<f32>( dot( p10_nodeVar327, ( vec3<f32>( p10_nodeVar327.y, p10_nodeVar327.z, p10_nodeVar327.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar329 = fract( p10_nodeVar322 );
	p10_nodeVar330 = ( ( p10_nodeVar329 * p10_nodeVar329 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar329 * vec2<f32>( 2.0 ) ) ) );
	p10_nodeVar331 = ( p10_nodeVar323 + vec2<f32>( 0.0, 1.0 ) );
	p10_nodeVar332 = fract( ( vec3<f32>( p10_nodeVar331.x, p10_nodeVar331.y, p10_nodeVar331.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar333 = ( p10_nodeVar332 + vec3<f32>( dot( p10_nodeVar332, ( vec3<f32>( p10_nodeVar332.y, p10_nodeVar332.z, p10_nodeVar332.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar334 = ( p10_nodeVar323 + vec2<f32>( 1.0, 1.0 ) );
	p10_nodeVar335 = fract( ( vec3<f32>( p10_nodeVar334.x, p10_nodeVar334.y, p10_nodeVar334.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar336 = ( p10_nodeVar335 + vec3<f32>( dot( p10_nodeVar335, ( vec3<f32>( p10_nodeVar335.y, p10_nodeVar335.z, p10_nodeVar335.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar337 = ( ( mix( mix( fract( ( ( p10_nodeVar310.x + p10_nodeVar310.y ) * p10_nodeVar310.z ) ), fract( ( ( p10_nodeVar313.x + p10_nodeVar313.y ) * p10_nodeVar313.z ) ), p10_nodeVar315.x ), mix( fract( ( ( p10_nodeVar318.x + p10_nodeVar318.y ) * p10_nodeVar318.z ) ), fract( ( ( p10_nodeVar321.x + p10_nodeVar321.y ) * p10_nodeVar321.z ) ), p10_nodeVar315.x ), p10_nodeVar315.y ) * 0.6 ) + ( mix( mix( fract( ( ( p10_nodeVar325.x + p10_nodeVar325.y ) * p10_nodeVar325.z ) ), fract( ( ( p10_nodeVar328.x + p10_nodeVar328.y ) * p10_nodeVar328.z ) ), p10_nodeVar330.x ), mix( fract( ( ( p10_nodeVar333.x + p10_nodeVar333.y ) * p10_nodeVar333.z ) ), fract( ( ( p10_nodeVar336.x + p10_nodeVar336.y ) * p10_nodeVar336.z ) ), p10_nodeVar330.x ), p10_nodeVar330.y ) * 0.4 ) );
	p10_nodeVar338 = ( ( p10_nodeVar302 - ( vec2<f32>( f32(knobs.shift), ( f32(knobs.shift) * -0.35 ) ) * vec2<f32>( ( 0.6 + ( p10_nodeVar2 * 0.4 ) ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p10_nodeVar339 = ( floor( ( p10_nodeVar302 / vec2<f32>( 1.5 ) ) ) + ( p10_nodeVar303 + vec2<f32>( 3.1 ) ) );
	p10_nodeVar340 = fract( ( vec3<f32>( p10_nodeVar339.x, p10_nodeVar339.y, p10_nodeVar339.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar341 = ( p10_nodeVar340 + vec3<f32>( dot( p10_nodeVar340, ( vec3<f32>( p10_nodeVar340.y, p10_nodeVar340.z, p10_nodeVar340.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar342 = ( f32(knobs.speckle) * ( 0.012 + ( p10_nodeVar2 * 0.006 ) ) );
	p10_nodeVar343 = ( floor( ( p10_nodeVar302 / vec2<f32>( 1.2 ) ) ) + ( p10_nodeVar303 + vec2<f32>( 8.7 ) ) );
	p10_nodeVar344 = fract( ( vec3<f32>( p10_nodeVar343.x, p10_nodeVar343.y, p10_nodeVar343.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar345 = ( p10_nodeVar344 + vec3<f32>( dot( p10_nodeVar344, ( vec3<f32>( p10_nodeVar344.y, p10_nodeVar344.z, p10_nodeVar344.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar346 = ( max( ( clamp( ( ( 1.0 - smoothstep( ( f32(knobs.threshold) - p10_nodeVar297 ), ( f32(knobs.threshold) + p10_nodeVar297 ), ( ( p10_nodeVar298 + ( ( ( fract( ( ( p10_nodeVar306.x + p10_nodeVar306.y ) * p10_nodeVar306.z ) ) - 0.5 ) * f32(knobs.grain) ) * 0.18 ) ) + ( ( ( p10_nodeVar337 - 0.5 ) * f32(knobs.fill) ) * 0.25 ) ) ) ) * mix( 1.0, ( ( p10_nodeVar337 * 0.5 ) + 0.62 ), f32(knobs.fill) ) ), 0.0, 1.0 ) * ( ( ( step( 0.0, p10_nodeVar338.x ) * step( p10_nodeVar338.x, 1.0 ) ) * step( 0.0, p10_nodeVar338.y ) ) * step( p10_nodeVar338.y, 1.0 ) ) ), step( fract( ( ( p10_nodeVar341.x + p10_nodeVar341.y ) * p10_nodeVar341.z ) ), p10_nodeVar342 ) ) * ( 1.0 - step( fract( ( ( p10_nodeVar345.x + p10_nodeVar345.y ) * p10_nodeVar345.z ) ), ( p10_nodeVar342 * 1.6 ) ) ) );
	p10_nodeVar347 = floor( ( p10_nodeVar302.x / 2.0 ) );
	p10_nodeVar348 = vec2<f32>( p10_nodeVar347, ( f32(knobs.seed) + 4.4 ) );
	p10_nodeVar349 = fract( ( vec3<f32>( p10_nodeVar348.x, p10_nodeVar348.y, p10_nodeVar348.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar350 = ( p10_nodeVar349 + vec3<f32>( dot( p10_nodeVar349, ( vec3<f32>( p10_nodeVar349.y, p10_nodeVar349.z, p10_nodeVar349.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar351 = step( fract( ( ( p10_nodeVar350.x + p10_nodeVar350.y ) * p10_nodeVar350.z ) ), ( f32(knobs.streaks) * 0.05 ) );

	if ( ( p10_nodeVar351 > 0.0 ) ) {

		p10_nodeVar352 = ( vec2<f32>( ( p10_nodeVar347 * 0.37 ), ( p10_nodeVar302.y / 90.0 ) ) + p10_nodeVar303 );
		p10_nodeVar353 = floor( p10_nodeVar352 );
		p10_nodeVar354 = fract( ( vec3<f32>( p10_nodeVar353.x, p10_nodeVar353.y, p10_nodeVar353.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar355 = ( p10_nodeVar354 + vec3<f32>( dot( p10_nodeVar354, ( vec3<f32>( p10_nodeVar354.y, p10_nodeVar354.z, p10_nodeVar354.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar356 = ( p10_nodeVar353 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar357 = fract( ( vec3<f32>( p10_nodeVar356.x, p10_nodeVar356.y, p10_nodeVar356.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar358 = ( p10_nodeVar357 + vec3<f32>( dot( p10_nodeVar357, ( vec3<f32>( p10_nodeVar357.y, p10_nodeVar357.z, p10_nodeVar357.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar359 = fract( p10_nodeVar352 );
		p10_nodeVar360 = ( ( p10_nodeVar359 * p10_nodeVar359 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar359 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar361 = ( p10_nodeVar353 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar362 = fract( ( vec3<f32>( p10_nodeVar361.x, p10_nodeVar361.y, p10_nodeVar361.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar363 = ( p10_nodeVar362 + vec3<f32>( dot( p10_nodeVar362, ( vec3<f32>( p10_nodeVar362.y, p10_nodeVar362.z, p10_nodeVar362.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar364 = ( p10_nodeVar353 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar365 = fract( ( vec3<f32>( p10_nodeVar364.x, p10_nodeVar364.y, p10_nodeVar364.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar366 = ( p10_nodeVar365 + vec3<f32>( dot( p10_nodeVar365, ( vec3<f32>( p10_nodeVar365.y, p10_nodeVar365.z, p10_nodeVar365.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar346 = max( p10_nodeVar346, ( ( p10_nodeVar351 * smoothstep( 0.25, 0.75, mix( mix( fract( ( ( p10_nodeVar355.x + p10_nodeVar355.y ) * p10_nodeVar355.z ) ), fract( ( ( p10_nodeVar358.x + p10_nodeVar358.y ) * p10_nodeVar358.z ) ), p10_nodeVar360.x ), mix( fract( ( ( p10_nodeVar363.x + p10_nodeVar363.y ) * p10_nodeVar363.z ) ), fract( ( ( p10_nodeVar366.x + p10_nodeVar366.y ) * p10_nodeVar366.z ) ), p10_nodeVar360.x ), p10_nodeVar360.y ) ) ) * 0.85 ) );
		

	}


	if ( ( f32(knobs.streaks) > 0.0 ) ) {

		p10_nodeVar367 = ( vec2<f32>( ( p10_nodeVar302.x / 220.0 ), 1.7 ) + p10_nodeVar303 );
		p10_nodeVar368 = floor( p10_nodeVar367 );
		p10_nodeVar369 = fract( ( vec3<f32>( p10_nodeVar368.x, p10_nodeVar368.y, p10_nodeVar368.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar370 = ( p10_nodeVar369 + vec3<f32>( dot( p10_nodeVar369, ( vec3<f32>( p10_nodeVar369.y, p10_nodeVar369.z, p10_nodeVar369.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar371 = ( p10_nodeVar368 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar372 = fract( ( vec3<f32>( p10_nodeVar371.x, p10_nodeVar371.y, p10_nodeVar371.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar373 = ( p10_nodeVar372 + vec3<f32>( dot( p10_nodeVar372, ( vec3<f32>( p10_nodeVar372.y, p10_nodeVar372.z, p10_nodeVar372.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar374 = fract( p10_nodeVar367 );
		p10_nodeVar375 = ( ( p10_nodeVar374 * p10_nodeVar374 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar374 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar376 = ( p10_nodeVar368 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar377 = fract( ( vec3<f32>( p10_nodeVar376.x, p10_nodeVar376.y, p10_nodeVar376.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar378 = ( p10_nodeVar377 + vec3<f32>( dot( p10_nodeVar377, ( vec3<f32>( p10_nodeVar377.y, p10_nodeVar377.z, p10_nodeVar377.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar379 = ( p10_nodeVar368 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar380 = fract( ( vec3<f32>( p10_nodeVar379.x, p10_nodeVar379.y, p10_nodeVar379.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar381 = ( p10_nodeVar380 + vec3<f32>( dot( p10_nodeVar380, ( vec3<f32>( p10_nodeVar380.y, p10_nodeVar380.z, p10_nodeVar380.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar346 = clamp( ( p10_nodeVar346 + ( ( ( mix( mix( fract( ( ( p10_nodeVar370.x + p10_nodeVar370.y ) * p10_nodeVar370.z ) ), fract( ( ( p10_nodeVar373.x + p10_nodeVar373.y ) * p10_nodeVar373.z ) ), p10_nodeVar375.x ), mix( fract( ( ( p10_nodeVar378.x + p10_nodeVar378.y ) * p10_nodeVar378.z ) ), fract( ( ( p10_nodeVar381.x + p10_nodeVar381.y ) * p10_nodeVar381.z ) ), p10_nodeVar375.x ), p10_nodeVar375.y ) * ( f32(knobs.streaks) * 0.18 ) ) * ( 1.0 - p10_nodeVar346 ) ) * 0.6 ) ), 0.0, 1.0 );
		

	}

	p10_nodeVar382 = 0.0;
	p10_nodeVar383 = 0.0;
	p10_nodeVar384 = step( 0.5, ( f32(knobs.creases) * 4.0 ) );

	if ( ( p10_nodeVar384 > 0.0 ) ) {

		p10_nodeVar385 = vec2<f32>( 0.0, ( f32(knobs.seed) + 1.9 ) );
		p10_nodeVar386 = fract( ( vec3<f32>( p10_nodeVar385.x, p10_nodeVar385.y, p10_nodeVar385.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar387 = ( p10_nodeVar386 + vec3<f32>( dot( p10_nodeVar386, ( vec3<f32>( p10_nodeVar386.y, p10_nodeVar386.z, p10_nodeVar386.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar388 = ( fract( ( ( p10_nodeVar387.x + p10_nodeVar387.y ) * p10_nodeVar387.z ) ) * 3.141592653589793 );
		p10_nodeVar389 = vec2<f32>( cos( p10_nodeVar388 ), sin( p10_nodeVar388 ) );
		p10_nodeVar390 = vec2<f32>( 0.0, ( f32(knobs.seed) + 6.2 ) );
		p10_nodeVar391 = fract( ( vec3<f32>( p10_nodeVar390.x, p10_nodeVar390.y, p10_nodeVar390.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar392 = ( p10_nodeVar391 + vec3<f32>( dot( p10_nodeVar391, ( vec3<f32>( p10_nodeVar391.y, p10_nodeVar391.z, p10_nodeVar391.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar393 = ( vec2<f32>( ( dot( p10_nodeVar302, vec2<f32>( ( - p10_nodeVar389.y ), p10_nodeVar389.x ) ) / 40.0 ), 0.0 ) + p10_nodeVar303 );
		p10_nodeVar394 = floor( p10_nodeVar393 );
		p10_nodeVar395 = fract( ( vec3<f32>( p10_nodeVar394.x, p10_nodeVar394.y, p10_nodeVar394.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar396 = ( p10_nodeVar395 + vec3<f32>( dot( p10_nodeVar395, ( vec3<f32>( p10_nodeVar395.y, p10_nodeVar395.z, p10_nodeVar395.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar397 = ( p10_nodeVar394 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar398 = fract( ( vec3<f32>( p10_nodeVar397.x, p10_nodeVar397.y, p10_nodeVar397.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar399 = ( p10_nodeVar398 + vec3<f32>( dot( p10_nodeVar398, ( vec3<f32>( p10_nodeVar398.y, p10_nodeVar398.z, p10_nodeVar398.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar400 = fract( p10_nodeVar393 );
		p10_nodeVar401 = ( ( p10_nodeVar400 * p10_nodeVar400 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar400 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar402 = ( p10_nodeVar394 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar403 = fract( ( vec3<f32>( p10_nodeVar402.x, p10_nodeVar402.y, p10_nodeVar402.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar404 = ( p10_nodeVar403 + vec3<f32>( dot( p10_nodeVar403, ( vec3<f32>( p10_nodeVar403.y, p10_nodeVar403.z, p10_nodeVar403.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar405 = ( p10_nodeVar394 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar406 = fract( ( vec3<f32>( p10_nodeVar405.x, p10_nodeVar405.y, p10_nodeVar405.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar407 = ( p10_nodeVar406 + vec3<f32>( dot( p10_nodeVar406, ( vec3<f32>( p10_nodeVar406.y, p10_nodeVar406.z, p10_nodeVar406.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar408 = ( ( dot( ( p10_nodeVar302 - ( vec2<f32>(knobs.resolution.x, knobs.resolution.y) * vec2<f32>( 0.5 ) ) ), p10_nodeVar389 ) - ( ( ( fract( ( ( p10_nodeVar392.x + p10_nodeVar392.y ) * p10_nodeVar392.z ) ) - 0.5 ) * min( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x, vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.8 ) ) + ( ( mix( mix( fract( ( ( p10_nodeVar396.x + p10_nodeVar396.y ) * p10_nodeVar396.z ) ), fract( ( ( p10_nodeVar399.x + p10_nodeVar399.y ) * p10_nodeVar399.z ) ), p10_nodeVar401.x ), mix( fract( ( ( p10_nodeVar404.x + p10_nodeVar404.y ) * p10_nodeVar404.z ) ), fract( ( ( p10_nodeVar407.x + p10_nodeVar407.y ) * p10_nodeVar407.z ) ), p10_nodeVar401.x ), p10_nodeVar401.y ) - 0.5 ) * 3.0 ) );
		p10_nodeVar382 = max( p10_nodeVar382, ( ( 1.0 - smoothstep( 0.0, 2.2, abs( p10_nodeVar408 ) ) ) * p10_nodeVar384 ) );
		p10_nodeVar383 = max( p10_nodeVar383, ( ( ( 1.0 - smoothstep( 0.0, 9.0, abs( ( p10_nodeVar408 - 3.0 ) ) ) ) * step( 0.0, p10_nodeVar408 ) ) * p10_nodeVar384 ) );
		

	}

	p10_nodeVar409 = step( 1.5, ( f32(knobs.creases) * 4.0 ) );

	if ( ( p10_nodeVar409 > 0.0 ) ) {

		p10_nodeVar410 = vec2<f32>( 3.1, ( f32(knobs.seed) + 1.9 ) );
		p10_nodeVar411 = fract( ( vec3<f32>( p10_nodeVar410.x, p10_nodeVar410.y, p10_nodeVar410.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar412 = ( p10_nodeVar411 + vec3<f32>( dot( p10_nodeVar411, ( vec3<f32>( p10_nodeVar411.y, p10_nodeVar411.z, p10_nodeVar411.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar413 = ( fract( ( ( p10_nodeVar412.x + p10_nodeVar412.y ) * p10_nodeVar412.z ) ) * 3.141592653589793 );
		p10_nodeVar414 = vec2<f32>( cos( p10_nodeVar413 ), sin( p10_nodeVar413 ) );
		p10_nodeVar415 = vec2<f32>( 5.7, ( f32(knobs.seed) + 6.2 ) );
		p10_nodeVar416 = fract( ( vec3<f32>( p10_nodeVar415.x, p10_nodeVar415.y, p10_nodeVar415.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar417 = ( p10_nodeVar416 + vec3<f32>( dot( p10_nodeVar416, ( vec3<f32>( p10_nodeVar416.y, p10_nodeVar416.z, p10_nodeVar416.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar418 = ( vec2<f32>( ( dot( p10_nodeVar302, vec2<f32>( ( - p10_nodeVar414.y ), p10_nodeVar414.x ) ) / 40.0 ), 1.0 ) + p10_nodeVar303 );
		p10_nodeVar419 = floor( p10_nodeVar418 );
		p10_nodeVar420 = fract( ( vec3<f32>( p10_nodeVar419.x, p10_nodeVar419.y, p10_nodeVar419.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar421 = ( p10_nodeVar420 + vec3<f32>( dot( p10_nodeVar420, ( vec3<f32>( p10_nodeVar420.y, p10_nodeVar420.z, p10_nodeVar420.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar422 = ( p10_nodeVar419 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar423 = fract( ( vec3<f32>( p10_nodeVar422.x, p10_nodeVar422.y, p10_nodeVar422.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar424 = ( p10_nodeVar423 + vec3<f32>( dot( p10_nodeVar423, ( vec3<f32>( p10_nodeVar423.y, p10_nodeVar423.z, p10_nodeVar423.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar425 = fract( p10_nodeVar418 );
		p10_nodeVar426 = ( ( p10_nodeVar425 * p10_nodeVar425 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar425 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar427 = ( p10_nodeVar419 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar428 = fract( ( vec3<f32>( p10_nodeVar427.x, p10_nodeVar427.y, p10_nodeVar427.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar429 = ( p10_nodeVar428 + vec3<f32>( dot( p10_nodeVar428, ( vec3<f32>( p10_nodeVar428.y, p10_nodeVar428.z, p10_nodeVar428.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar430 = ( p10_nodeVar419 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar431 = fract( ( vec3<f32>( p10_nodeVar430.x, p10_nodeVar430.y, p10_nodeVar430.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar432 = ( p10_nodeVar431 + vec3<f32>( dot( p10_nodeVar431, ( vec3<f32>( p10_nodeVar431.y, p10_nodeVar431.z, p10_nodeVar431.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar433 = ( ( dot( ( p10_nodeVar302 - ( vec2<f32>(knobs.resolution.x, knobs.resolution.y) * vec2<f32>( 0.5 ) ) ), p10_nodeVar414 ) - ( ( ( fract( ( ( p10_nodeVar417.x + p10_nodeVar417.y ) * p10_nodeVar417.z ) ) - 0.5 ) * min( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x, vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.8 ) ) + ( ( mix( mix( fract( ( ( p10_nodeVar421.x + p10_nodeVar421.y ) * p10_nodeVar421.z ) ), fract( ( ( p10_nodeVar424.x + p10_nodeVar424.y ) * p10_nodeVar424.z ) ), p10_nodeVar426.x ), mix( fract( ( ( p10_nodeVar429.x + p10_nodeVar429.y ) * p10_nodeVar429.z ) ), fract( ( ( p10_nodeVar432.x + p10_nodeVar432.y ) * p10_nodeVar432.z ) ), p10_nodeVar426.x ), p10_nodeVar426.y ) - 0.5 ) * 3.0 ) );
		p10_nodeVar382 = max( p10_nodeVar382, ( ( 1.0 - smoothstep( 0.0, 2.2, abs( p10_nodeVar433 ) ) ) * p10_nodeVar409 ) );
		p10_nodeVar383 = max( p10_nodeVar383, ( ( ( 1.0 - smoothstep( 0.0, 9.0, abs( ( p10_nodeVar433 - 3.0 ) ) ) ) * step( 0.0, p10_nodeVar433 ) ) * p10_nodeVar409 ) );
		

	}

	p10_nodeVar434 = step( 2.5, ( f32(knobs.creases) * 4.0 ) );

	if ( ( p10_nodeVar434 > 0.0 ) ) {

		p10_nodeVar435 = vec2<f32>( 6.2, ( f32(knobs.seed) + 1.9 ) );
		p10_nodeVar436 = fract( ( vec3<f32>( p10_nodeVar435.x, p10_nodeVar435.y, p10_nodeVar435.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar437 = ( p10_nodeVar436 + vec3<f32>( dot( p10_nodeVar436, ( vec3<f32>( p10_nodeVar436.y, p10_nodeVar436.z, p10_nodeVar436.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar438 = ( fract( ( ( p10_nodeVar437.x + p10_nodeVar437.y ) * p10_nodeVar437.z ) ) * 3.141592653589793 );
		p10_nodeVar439 = vec2<f32>( cos( p10_nodeVar438 ), sin( p10_nodeVar438 ) );
		p10_nodeVar440 = vec2<f32>( 11.4, ( f32(knobs.seed) + 6.2 ) );
		p10_nodeVar441 = fract( ( vec3<f32>( p10_nodeVar440.x, p10_nodeVar440.y, p10_nodeVar440.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar442 = ( p10_nodeVar441 + vec3<f32>( dot( p10_nodeVar441, ( vec3<f32>( p10_nodeVar441.y, p10_nodeVar441.z, p10_nodeVar441.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar443 = ( vec2<f32>( ( dot( p10_nodeVar302, vec2<f32>( ( - p10_nodeVar439.y ), p10_nodeVar439.x ) ) / 40.0 ), 2.0 ) + p10_nodeVar303 );
		p10_nodeVar444 = floor( p10_nodeVar443 );
		p10_nodeVar445 = fract( ( vec3<f32>( p10_nodeVar444.x, p10_nodeVar444.y, p10_nodeVar444.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar446 = ( p10_nodeVar445 + vec3<f32>( dot( p10_nodeVar445, ( vec3<f32>( p10_nodeVar445.y, p10_nodeVar445.z, p10_nodeVar445.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar447 = ( p10_nodeVar444 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar448 = fract( ( vec3<f32>( p10_nodeVar447.x, p10_nodeVar447.y, p10_nodeVar447.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar449 = ( p10_nodeVar448 + vec3<f32>( dot( p10_nodeVar448, ( vec3<f32>( p10_nodeVar448.y, p10_nodeVar448.z, p10_nodeVar448.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar450 = fract( p10_nodeVar443 );
		p10_nodeVar451 = ( ( p10_nodeVar450 * p10_nodeVar450 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar450 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar452 = ( p10_nodeVar444 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar453 = fract( ( vec3<f32>( p10_nodeVar452.x, p10_nodeVar452.y, p10_nodeVar452.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar454 = ( p10_nodeVar453 + vec3<f32>( dot( p10_nodeVar453, ( vec3<f32>( p10_nodeVar453.y, p10_nodeVar453.z, p10_nodeVar453.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar455 = ( p10_nodeVar444 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar456 = fract( ( vec3<f32>( p10_nodeVar455.x, p10_nodeVar455.y, p10_nodeVar455.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar457 = ( p10_nodeVar456 + vec3<f32>( dot( p10_nodeVar456, ( vec3<f32>( p10_nodeVar456.y, p10_nodeVar456.z, p10_nodeVar456.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar458 = ( ( dot( ( p10_nodeVar302 - ( vec2<f32>(knobs.resolution.x, knobs.resolution.y) * vec2<f32>( 0.5 ) ) ), p10_nodeVar439 ) - ( ( ( fract( ( ( p10_nodeVar442.x + p10_nodeVar442.y ) * p10_nodeVar442.z ) ) - 0.5 ) * min( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x, vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.8 ) ) + ( ( mix( mix( fract( ( ( p10_nodeVar446.x + p10_nodeVar446.y ) * p10_nodeVar446.z ) ), fract( ( ( p10_nodeVar449.x + p10_nodeVar449.y ) * p10_nodeVar449.z ) ), p10_nodeVar451.x ), mix( fract( ( ( p10_nodeVar454.x + p10_nodeVar454.y ) * p10_nodeVar454.z ) ), fract( ( ( p10_nodeVar457.x + p10_nodeVar457.y ) * p10_nodeVar457.z ) ), p10_nodeVar451.x ), p10_nodeVar451.y ) - 0.5 ) * 3.0 ) );
		p10_nodeVar382 = max( p10_nodeVar382, ( ( 1.0 - smoothstep( 0.0, 2.2, abs( p10_nodeVar458 ) ) ) * p10_nodeVar434 ) );
		p10_nodeVar383 = max( p10_nodeVar383, ( ( ( 1.0 - smoothstep( 0.0, 9.0, abs( ( p10_nodeVar458 - 3.0 ) ) ) ) * step( 0.0, p10_nodeVar458 ) ) * p10_nodeVar434 ) );
		

	}

	p10_nodeVar459 = step( 3.5, ( f32(knobs.creases) * 4.0 ) );

	if ( ( p10_nodeVar459 > 0.0 ) ) {

		p10_nodeVar460 = vec2<f32>( 9.3, ( f32(knobs.seed) + 1.9 ) );
		p10_nodeVar461 = fract( ( vec3<f32>( p10_nodeVar460.x, p10_nodeVar460.y, p10_nodeVar460.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar462 = ( p10_nodeVar461 + vec3<f32>( dot( p10_nodeVar461, ( vec3<f32>( p10_nodeVar461.y, p10_nodeVar461.z, p10_nodeVar461.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar463 = ( fract( ( ( p10_nodeVar462.x + p10_nodeVar462.y ) * p10_nodeVar462.z ) ) * 3.141592653589793 );
		p10_nodeVar464 = vec2<f32>( cos( p10_nodeVar463 ), sin( p10_nodeVar463 ) );
		p10_nodeVar465 = vec2<f32>( 17.1, ( f32(knobs.seed) + 6.2 ) );
		p10_nodeVar466 = fract( ( vec3<f32>( p10_nodeVar465.x, p10_nodeVar465.y, p10_nodeVar465.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar467 = ( p10_nodeVar466 + vec3<f32>( dot( p10_nodeVar466, ( vec3<f32>( p10_nodeVar466.y, p10_nodeVar466.z, p10_nodeVar466.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar468 = ( vec2<f32>( ( dot( p10_nodeVar302, vec2<f32>( ( - p10_nodeVar464.y ), p10_nodeVar464.x ) ) / 40.0 ), 3.0 ) + p10_nodeVar303 );
		p10_nodeVar469 = floor( p10_nodeVar468 );
		p10_nodeVar470 = fract( ( vec3<f32>( p10_nodeVar469.x, p10_nodeVar469.y, p10_nodeVar469.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar471 = ( p10_nodeVar470 + vec3<f32>( dot( p10_nodeVar470, ( vec3<f32>( p10_nodeVar470.y, p10_nodeVar470.z, p10_nodeVar470.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar472 = ( p10_nodeVar469 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar473 = fract( ( vec3<f32>( p10_nodeVar472.x, p10_nodeVar472.y, p10_nodeVar472.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar474 = ( p10_nodeVar473 + vec3<f32>( dot( p10_nodeVar473, ( vec3<f32>( p10_nodeVar473.y, p10_nodeVar473.z, p10_nodeVar473.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar475 = fract( p10_nodeVar468 );
		p10_nodeVar476 = ( ( p10_nodeVar475 * p10_nodeVar475 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar475 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar477 = ( p10_nodeVar469 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar478 = fract( ( vec3<f32>( p10_nodeVar477.x, p10_nodeVar477.y, p10_nodeVar477.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar479 = ( p10_nodeVar478 + vec3<f32>( dot( p10_nodeVar478, ( vec3<f32>( p10_nodeVar478.y, p10_nodeVar478.z, p10_nodeVar478.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar480 = ( p10_nodeVar469 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar481 = fract( ( vec3<f32>( p10_nodeVar480.x, p10_nodeVar480.y, p10_nodeVar480.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar482 = ( p10_nodeVar481 + vec3<f32>( dot( p10_nodeVar481, ( vec3<f32>( p10_nodeVar481.y, p10_nodeVar481.z, p10_nodeVar481.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar483 = ( ( dot( ( p10_nodeVar302 - ( vec2<f32>(knobs.resolution.x, knobs.resolution.y) * vec2<f32>( 0.5 ) ) ), p10_nodeVar464 ) - ( ( ( fract( ( ( p10_nodeVar467.x + p10_nodeVar467.y ) * p10_nodeVar467.z ) ) - 0.5 ) * min( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x, vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.8 ) ) + ( ( mix( mix( fract( ( ( p10_nodeVar471.x + p10_nodeVar471.y ) * p10_nodeVar471.z ) ), fract( ( ( p10_nodeVar474.x + p10_nodeVar474.y ) * p10_nodeVar474.z ) ), p10_nodeVar476.x ), mix( fract( ( ( p10_nodeVar479.x + p10_nodeVar479.y ) * p10_nodeVar479.z ) ), fract( ( ( p10_nodeVar482.x + p10_nodeVar482.y ) * p10_nodeVar482.z ) ), p10_nodeVar476.x ), p10_nodeVar476.y ) - 0.5 ) * 3.0 ) );
		p10_nodeVar382 = max( p10_nodeVar382, ( ( 1.0 - smoothstep( 0.0, 2.2, abs( p10_nodeVar483 ) ) ) * p10_nodeVar459 ) );
		p10_nodeVar383 = max( p10_nodeVar383, ( ( ( 1.0 - smoothstep( 0.0, 9.0, abs( ( p10_nodeVar483 - 3.0 ) ) ) ) * step( 0.0, p10_nodeVar483 ) ) * p10_nodeVar459 ) );
		

	}

	p10_nodeVar484 = picture_read_level( p10_nodeVar301, 0.0 );
	p10_nodeVar486 = ( f32(knobs.paper) > 0.5 );

	if ( p10_nodeVar486 ) {

		p10_nodeVar485 = vec3<f32>(knobs.tonerColor.x, knobs.tonerColor.y, knobs.tonerColor.z);

	} else {

		p10_nodeVar487 = ( ( p10_nodeVar302 / vec2<f32>( 2.3 ) ) + ( p10_nodeVar303 * vec2<f32>( 3.0 ) ) );
		p10_nodeVar488 = floor( p10_nodeVar487 );
		p10_nodeVar489 = fract( ( vec3<f32>( p10_nodeVar488.x, p10_nodeVar488.y, p10_nodeVar488.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar490 = ( p10_nodeVar489 + vec3<f32>( dot( p10_nodeVar489, ( vec3<f32>( p10_nodeVar489.y, p10_nodeVar489.z, p10_nodeVar489.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar491 = ( p10_nodeVar488 + vec2<f32>( 1.0, 0.0 ) );
		p10_nodeVar492 = fract( ( vec3<f32>( p10_nodeVar491.x, p10_nodeVar491.y, p10_nodeVar491.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar493 = ( p10_nodeVar492 + vec3<f32>( dot( p10_nodeVar492, ( vec3<f32>( p10_nodeVar492.y, p10_nodeVar492.z, p10_nodeVar492.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar494 = fract( p10_nodeVar487 );
		p10_nodeVar495 = ( ( p10_nodeVar494 * p10_nodeVar494 ) * ( vec2<f32>( 3.0 ) - ( p10_nodeVar494 * vec2<f32>( 2.0 ) ) ) );
		p10_nodeVar496 = ( p10_nodeVar488 + vec2<f32>( 0.0, 1.0 ) );
		p10_nodeVar497 = fract( ( vec3<f32>( p10_nodeVar496.x, p10_nodeVar496.y, p10_nodeVar496.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar498 = ( p10_nodeVar497 + vec3<f32>( dot( p10_nodeVar497, ( vec3<f32>( p10_nodeVar497.y, p10_nodeVar497.z, p10_nodeVar497.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar499 = ( p10_nodeVar488 + vec2<f32>( 1.0, 1.0 ) );
		p10_nodeVar500 = fract( ( vec3<f32>( p10_nodeVar499.x, p10_nodeVar499.y, p10_nodeVar499.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar501 = ( p10_nodeVar500 + vec3<f32>( dot( p10_nodeVar500, ( vec3<f32>( p10_nodeVar500.y, p10_nodeVar500.z, p10_nodeVar500.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar485 = mix( clamp( ( ( ( vec3<f32>(knobs.paperColor.x, knobs.paperColor.y, knobs.paperColor.z) + vec3<f32>( ( ( ( mix( mix( fract( ( ( p10_nodeVar490.x + p10_nodeVar490.y ) * p10_nodeVar490.z ) ), fract( ( ( p10_nodeVar493.x + p10_nodeVar493.y ) * p10_nodeVar493.z ) ), p10_nodeVar495.x ), mix( fract( ( ( p10_nodeVar498.x + p10_nodeVar498.y ) * p10_nodeVar498.z ) ), fract( ( ( p10_nodeVar501.x + p10_nodeVar501.y ) * p10_nodeVar501.z ) ), p10_nodeVar495.x ), p10_nodeVar495.y ) - 0.5 ) * f32(knobs.grain) ) * 0.05 ) ) ) + vec3<f32>( ( p10_nodeVar383 * 0.05 ) ) ) - vec3<f32>( ( p10_nodeVar382 * 0.08 ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), vec3<f32>(knobs.tonerColor.x, knobs.tonerColor.y, knobs.tonerColor.z), clamp( ( p10_nodeVar346 + ( p10_nodeVar382 * 0.55 ) ), 0.0, 1.0 ) );

	}


	if ( p10_nodeVar486 ) {

		p10_nodeVar502 = ( clamp( ( p10_nodeVar346 + ( p10_nodeVar382 * 0.55 ) ), 0.0, 1.0 ) * p10_nodeVar1.w );

	} else {

		p10_nodeVar502 = 1.0;

	}

	p10_nodeVar503 = mix( p10_nodeVar484.w, p10_nodeVar502, f32(knobs.amount) );
	p10_nodeVar504 = vec4<f32>( ( mix( vec3<f32>( p10_nodeVar484.x, p10_nodeVar484.y, p10_nodeVar484.z ), ( p10_nodeVar485 * vec3<f32>( p10_nodeVar502 ) ), f32(knobs.amount) ) / vec3<f32>( max( p10_nodeVar503, 0.0001 ) ) ), p10_nodeVar503 );
	p10_nodeVar505 = vec3<f32>( p10_nodeVar504.x, p10_nodeVar504.y, p10_nodeVar504.z );
	p10_nodeVar506 = ( ( ( p10_nodeVar505.x * 0.2126 ) + ( p10_nodeVar505.y * 0.7152 ) ) + ( p10_nodeVar505.z * 0.0722 ) );
	p10_nodeVar507 = mix( vec3<f32>( p10_nodeVar506, p10_nodeVar506, p10_nodeVar506 ), p10_nodeVar505, f32(1.0) );
	p10_nodeVar508 = vec4<f32>( clamp( vec3<f32>( ( ( ( p10_nodeVar507.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p10_nodeVar507.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar507.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p10_nodeVar507.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p10_nodeVar507.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p10_nodeVar507.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p10_nodeVar507.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p10_nodeVar507.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar507.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p10_nodeVar504.w, 0.0, 1.0 ) );
	p10_nodeVar510 = mix( clamp( p10_nodeVar0.w, 0.0, 1.0 ), clamp( p10_nodeVar508.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p10_nodeVar510 > 0.0 ) ) {

		p10_nodeVar509 = p10_nodeVar510;

	} else {

		p10_nodeVar509 = 1.0;

	}

	p10_DiffuseColor = vec4<f32>( ( mix( ( p10_nodeVar0.xyz * vec3<f32>( clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p10_nodeVar508.xyz, p10_nodeVar508.xyz, clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p10_nodeVar508.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p10_nodeVar509 ) ), p10_nodeVar510 );
	p10_DiffuseColor.w = ( p10_DiffuseColor.w * f32(1.0) );
	p10_nodeVar511 = max( vec4<f32>( p10_DiffuseColor.xyz, p10_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p10_Output = p10_nodeVar511;

	// result

	p10_output.color = p10_nodeVar511;

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

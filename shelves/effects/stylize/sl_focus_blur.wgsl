// Blur: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Blur that varies across the frame: depth of field, tilt-shift, radial focus or tone-based, with Gaussian, lens bokeh or motion streaks.
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
// --track@blurFrom:Blur From,0,4,1,1
// --track@kind:Kind,0,2,1,1
// --track@radius:Radius,0,400,70,1
// --track@motionAngle:Motion Angle,-180,180,0,1
// --track@highlights:Highlights,0,3,0.4,0.01
// --track@angle:Band Angle,-180,180,0,1
// --track@focus:Focus,0,1,0.85,0.01
// --track@range:Focus Range,0,2,0.12,0.01
// --track@transition:Transition,0.01,2,0.45,0.01
// --check@invertFocus:Invert Focus,0
// --track@grain:Grain,0,1,0.35,0.01
// --track@grainSize:Grain Size,0.5,6,1.2,0.05
// --track@grainFollow:Grain in Blur,0,1,0.6,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  blurFrom: f32,
  kind: f32,
  radius: f32,
  motionAngle: f32,
  highlights: f32,
  angle: f32,
  focus: f32,
  range: f32,
  transition: f32,
  invertFocus: f32,
  grain: f32,
  grainSize: f32,
  grainFollow: f32,
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
var<private> p10_nodeVar5 : f32;
var<private> p10_nodeVar6 : vec4<f32>;
var<private> p10_nodeVar7 : f32;
var<private> p10_nodeVar8 : vec4<f32>;
var<private> p10_nodeVar9 : f32;
var<private> p10_nodeVar10 : f32;
var<private> p10_nodeVar11 : f32;
var<private> p10_nodeVar12 : f32;
var<private> p10_nodeVar13 : vec4<f32>;
var<private> p10_nodeVar14 : vec4<f32>;
var<private> p10_nodeVar15 : f32;
var<private> p10_nodeVar16 : f32;
var<private> p10_nodeVar17 : f32;
var<private> p10_nodeVar18 : vec4<f32>;
var<private> p10_nodeVar19 : vec2<f32>;
var<private> p10_nodeVar20 : vec2<f32>;
var<private> p10_nodeVar21 : vec2<f32>;
var<private> p10_nodeVar22 : vec2<f32>;
var<private> p10_nodeVar23 : vec2<f32>;
var<private> p10_nodeVar24 : vec2<f32>;
var<private> p10_nodeVar25 : vec2<f32>;
var<private> p10_nodeVar26 : vec4<f32>;
var<private> p10_nodeVar27 : vec2<f32>;
var<private> p10_nodeVar28 : vec2<f32>;
var<private> p10_nodeVar29 : vec2<f32>;
var<private> p10_nodeVar30 : vec4<f32>;
var<private> p10_nodeVar31 : vec4<f32>;
var<private> p10_nodeVar32 : vec4<f32>;
var<private> p10_nodeVar33 : vec2<f32>;
var<private> p10_nodeVar34 : vec2<f32>;
var<private> p10_nodeVar35 : vec2<f32>;
var<private> p10_nodeVar36 : vec2<f32>;
var<private> p10_nodeVar37 : vec2<f32>;
var<private> p10_nodeVar38 : vec2<f32>;
var<private> p10_nodeVar39 : vec2<f32>;
var<private> p10_nodeVar40 : vec4<f32>;
var<private> p10_nodeVar41 : vec2<f32>;
var<private> p10_nodeVar42 : vec2<f32>;
var<private> p10_nodeVar43 : vec2<f32>;
var<private> p10_nodeVar44 : vec4<f32>;
var<private> p10_nodeVar45 : vec4<f32>;
var<private> p10_nodeVar46 : vec4<f32>;
var<private> p10_nodeVar47 : vec2<f32>;
var<private> p10_nodeVar48 : vec2<f32>;
var<private> p10_nodeVar49 : vec2<f32>;
var<private> p10_nodeVar50 : vec2<f32>;
var<private> p10_nodeVar51 : vec2<f32>;
var<private> p10_nodeVar52 : vec2<f32>;
var<private> p10_nodeVar53 : vec2<f32>;
var<private> p10_nodeVar54 : vec4<f32>;
var<private> p10_nodeVar55 : vec2<f32>;
var<private> p10_nodeVar56 : vec2<f32>;
var<private> p10_nodeVar57 : vec2<f32>;
var<private> p10_nodeVar58 : vec4<f32>;
var<private> p10_nodeVar59 : vec4<f32>;
var<private> p10_nodeVar60 : vec4<f32>;
var<private> p10_nodeVar61 : vec2<f32>;
var<private> p10_nodeVar62 : vec2<f32>;
var<private> p10_nodeVar63 : vec2<f32>;
var<private> p10_nodeVar64 : vec2<f32>;
var<private> p10_nodeVar65 : vec2<f32>;
var<private> p10_nodeVar66 : vec2<f32>;
var<private> p10_nodeVar67 : vec2<f32>;
var<private> p10_nodeVar68 : vec4<f32>;
var<private> p10_nodeVar69 : vec2<f32>;
var<private> p10_nodeVar70 : vec2<f32>;
var<private> p10_nodeVar71 : vec2<f32>;
var<private> p10_nodeVar72 : vec4<f32>;
var<private> p10_nodeVar73 : vec4<f32>;
var<private> p10_nodeVar74 : vec4<f32>;
var<private> p10_nodeVar75 : vec2<f32>;
var<private> p10_nodeVar76 : vec2<f32>;
var<private> p10_nodeVar77 : vec2<f32>;
var<private> p10_nodeVar78 : vec2<f32>;
var<private> p10_nodeVar79 : vec2<f32>;
var<private> p10_nodeVar80 : vec2<f32>;
var<private> p10_nodeVar81 : vec2<f32>;
var<private> p10_nodeVar82 : vec4<f32>;
var<private> p10_nodeVar83 : vec2<f32>;
var<private> p10_nodeVar84 : vec2<f32>;
var<private> p10_nodeVar85 : vec2<f32>;
var<private> p10_nodeVar86 : vec4<f32>;
var<private> p10_nodeVar87 : vec4<f32>;
var<private> p10_nodeVar88 : vec4<f32>;
var<private> p10_nodeVar89 : vec2<f32>;
var<private> p10_nodeVar90 : vec2<f32>;
var<private> p10_nodeVar91 : vec2<f32>;
var<private> p10_nodeVar92 : vec2<f32>;
var<private> p10_nodeVar93 : vec2<f32>;
var<private> p10_nodeVar94 : vec2<f32>;
var<private> p10_nodeVar95 : vec2<f32>;
var<private> p10_nodeVar96 : vec4<f32>;
var<private> p10_nodeVar97 : vec2<f32>;
var<private> p10_nodeVar98 : vec2<f32>;
var<private> p10_nodeVar99 : vec2<f32>;
var<private> p10_nodeVar100 : vec4<f32>;
var<private> p10_nodeVar101 : vec4<f32>;
var<private> p10_nodeVar102 : vec4<f32>;
var<private> p10_nodeVar103 : vec2<f32>;
var<private> p10_nodeVar104 : vec2<f32>;
var<private> p10_nodeVar105 : vec2<f32>;
var<private> p10_nodeVar106 : vec2<f32>;
var<private> p10_nodeVar107 : vec2<f32>;
var<private> p10_nodeVar108 : vec2<f32>;
var<private> p10_nodeVar109 : vec2<f32>;
var<private> p10_nodeVar110 : vec4<f32>;
var<private> p10_nodeVar111 : vec2<f32>;
var<private> p10_nodeVar112 : vec2<f32>;
var<private> p10_nodeVar113 : vec2<f32>;
var<private> p10_nodeVar114 : vec4<f32>;
var<private> p10_nodeVar115 : vec4<f32>;
var<private> p10_nodeVar116 : vec4<f32>;
var<private> p10_nodeVar117 : vec2<f32>;
var<private> p10_nodeVar118 : vec2<f32>;
var<private> p10_nodeVar119 : vec2<f32>;
var<private> p10_nodeVar120 : vec2<f32>;
var<private> p10_nodeVar121 : vec2<f32>;
var<private> p10_nodeVar122 : vec2<f32>;
var<private> p10_nodeVar123 : vec2<f32>;
var<private> p10_nodeVar124 : vec4<f32>;
var<private> p10_nodeVar125 : vec2<f32>;
var<private> p10_nodeVar126 : vec2<f32>;
var<private> p10_nodeVar127 : vec2<f32>;
var<private> p10_nodeVar128 : vec4<f32>;
var<private> p10_nodeVar129 : vec4<f32>;
var<private> p10_nodeVar130 : vec4<f32>;
var<private> p10_nodeVar131 : vec2<f32>;
var<private> p10_nodeVar132 : vec2<f32>;
var<private> p10_nodeVar133 : vec2<f32>;
var<private> p10_nodeVar134 : vec2<f32>;
var<private> p10_nodeVar135 : vec2<f32>;
var<private> p10_nodeVar136 : vec2<f32>;
var<private> p10_nodeVar137 : vec2<f32>;
var<private> p10_nodeVar138 : vec4<f32>;
var<private> p10_nodeVar139 : vec2<f32>;
var<private> p10_nodeVar140 : vec2<f32>;
var<private> p10_nodeVar141 : vec2<f32>;
var<private> p10_nodeVar142 : vec4<f32>;
var<private> p10_nodeVar143 : vec4<f32>;
var<private> p10_nodeVar144 : vec4<f32>;
var<private> p10_nodeVar145 : vec2<f32>;
var<private> p10_nodeVar146 : vec2<f32>;
var<private> p10_nodeVar147 : vec2<f32>;
var<private> p10_nodeVar148 : vec2<f32>;
var<private> p10_nodeVar149 : vec2<f32>;
var<private> p10_nodeVar150 : vec2<f32>;
var<private> p10_nodeVar151 : vec2<f32>;
var<private> p10_nodeVar152 : vec4<f32>;
var<private> p10_nodeVar153 : vec2<f32>;
var<private> p10_nodeVar154 : vec2<f32>;
var<private> p10_nodeVar155 : vec2<f32>;
var<private> p10_nodeVar156 : vec4<f32>;
var<private> p10_nodeVar157 : vec4<f32>;
var<private> p10_nodeVar158 : vec4<f32>;
var<private> p10_nodeVar159 : vec2<f32>;
var<private> p10_nodeVar160 : vec2<f32>;
var<private> p10_nodeVar161 : vec2<f32>;
var<private> p10_nodeVar162 : vec2<f32>;
var<private> p10_nodeVar163 : vec2<f32>;
var<private> p10_nodeVar164 : vec2<f32>;
var<private> p10_nodeVar165 : vec2<f32>;
var<private> p10_nodeVar166 : vec4<f32>;
var<private> p10_nodeVar167 : vec2<f32>;
var<private> p10_nodeVar168 : vec2<f32>;
var<private> p10_nodeVar169 : vec2<f32>;
var<private> p10_nodeVar170 : vec4<f32>;
var<private> p10_nodeVar171 : vec4<f32>;
var<private> p10_nodeVar172 : vec4<f32>;
var<private> p10_nodeVar173 : vec2<f32>;
var<private> p10_nodeVar174 : vec2<f32>;
var<private> p10_nodeVar175 : vec2<f32>;
var<private> p10_nodeVar176 : vec2<f32>;
var<private> p10_nodeVar177 : vec2<f32>;
var<private> p10_nodeVar178 : vec2<f32>;
var<private> p10_nodeVar179 : vec2<f32>;
var<private> p10_nodeVar180 : vec4<f32>;
var<private> p10_nodeVar181 : vec2<f32>;
var<private> p10_nodeVar182 : vec2<f32>;
var<private> p10_nodeVar183 : vec2<f32>;
var<private> p10_nodeVar184 : vec4<f32>;
var<private> p10_nodeVar185 : vec4<f32>;
var<private> p10_nodeVar186 : vec4<f32>;
var<private> p10_nodeVar187 : vec2<f32>;
var<private> p10_nodeVar188 : vec2<f32>;
var<private> p10_nodeVar189 : vec2<f32>;
var<private> p10_nodeVar190 : vec2<f32>;
var<private> p10_nodeVar191 : vec2<f32>;
var<private> p10_nodeVar192 : vec2<f32>;
var<private> p10_nodeVar193 : vec2<f32>;
var<private> p10_nodeVar194 : vec4<f32>;
var<private> p10_nodeVar195 : vec2<f32>;
var<private> p10_nodeVar196 : vec2<f32>;
var<private> p10_nodeVar197 : vec2<f32>;
var<private> p10_nodeVar198 : vec4<f32>;
var<private> p10_nodeVar199 : vec4<f32>;
var<private> p10_nodeVar200 : vec4<f32>;
var<private> p10_nodeVar201 : vec2<f32>;
var<private> p10_nodeVar202 : vec2<f32>;
var<private> p10_nodeVar203 : vec2<f32>;
var<private> p10_nodeVar204 : vec2<f32>;
var<private> p10_nodeVar205 : vec2<f32>;
var<private> p10_nodeVar206 : vec2<f32>;
var<private> p10_nodeVar207 : vec2<f32>;
var<private> p10_nodeVar208 : vec4<f32>;
var<private> p10_nodeVar209 : vec2<f32>;
var<private> p10_nodeVar210 : vec2<f32>;
var<private> p10_nodeVar211 : vec2<f32>;
var<private> p10_nodeVar212 : vec4<f32>;
var<private> p10_nodeVar213 : vec4<f32>;
var<private> p10_nodeVar214 : vec4<f32>;
var<private> p10_nodeVar215 : vec2<f32>;
var<private> p10_nodeVar216 : vec2<f32>;
var<private> p10_nodeVar217 : vec2<f32>;
var<private> p10_nodeVar218 : vec2<f32>;
var<private> p10_nodeVar219 : vec2<f32>;
var<private> p10_nodeVar220 : vec2<f32>;
var<private> p10_nodeVar221 : vec2<f32>;
var<private> p10_nodeVar222 : vec4<f32>;
var<private> p10_nodeVar223 : vec2<f32>;
var<private> p10_nodeVar224 : vec2<f32>;
var<private> p10_nodeVar225 : vec2<f32>;
var<private> p10_nodeVar226 : vec4<f32>;
var<private> p10_nodeVar227 : vec4<f32>;
var<private> p10_nodeVar228 : vec4<f32>;
var<private> p10_nodeVar229 : vec2<f32>;
var<private> p10_nodeVar230 : vec2<f32>;
var<private> p10_nodeVar231 : vec2<f32>;
var<private> p10_nodeVar232 : vec2<f32>;
var<private> p10_nodeVar233 : vec2<f32>;
var<private> p10_nodeVar234 : vec2<f32>;
var<private> p10_nodeVar235 : vec2<f32>;
var<private> p10_nodeVar236 : vec4<f32>;
var<private> p10_nodeVar237 : vec2<f32>;
var<private> p10_nodeVar238 : vec2<f32>;
var<private> p10_nodeVar239 : vec2<f32>;
var<private> p10_nodeVar240 : vec4<f32>;
var<private> p10_nodeVar241 : vec4<f32>;
var<private> p10_nodeVar242 : vec4<f32>;
var<private> p10_nodeVar243 : vec2<f32>;
var<private> p10_nodeVar244 : vec2<f32>;
var<private> p10_nodeVar245 : vec2<f32>;
var<private> p10_nodeVar246 : vec2<f32>;
var<private> p10_nodeVar247 : vec2<f32>;
var<private> p10_nodeVar248 : vec2<f32>;
var<private> p10_nodeVar249 : vec2<f32>;
var<private> p10_nodeVar250 : vec4<f32>;
var<private> p10_nodeVar251 : vec2<f32>;
var<private> p10_nodeVar252 : vec2<f32>;
var<private> p10_nodeVar253 : vec2<f32>;
var<private> p10_nodeVar254 : vec4<f32>;
var<private> p10_nodeVar255 : vec4<f32>;
var<private> p10_nodeVar256 : vec4<f32>;
var<private> p10_nodeVar257 : vec2<f32>;
var<private> p10_nodeVar258 : vec2<f32>;
var<private> p10_nodeVar259 : vec2<f32>;
var<private> p10_nodeVar260 : vec2<f32>;
var<private> p10_nodeVar261 : vec2<f32>;
var<private> p10_nodeVar262 : vec2<f32>;
var<private> p10_nodeVar263 : vec2<f32>;
var<private> p10_nodeVar264 : vec4<f32>;
var<private> p10_nodeVar265 : vec2<f32>;
var<private> p10_nodeVar266 : vec2<f32>;
var<private> p10_nodeVar267 : vec2<f32>;
var<private> p10_nodeVar268 : vec4<f32>;
var<private> p10_nodeVar269 : vec4<f32>;
var<private> p10_nodeVar270 : vec4<f32>;
var<private> p10_nodeVar271 : vec2<f32>;
var<private> p10_nodeVar272 : vec2<f32>;
var<private> p10_nodeVar273 : vec2<f32>;
var<private> p10_nodeVar274 : vec2<f32>;
var<private> p10_nodeVar275 : vec2<f32>;
var<private> p10_nodeVar276 : vec2<f32>;
var<private> p10_nodeVar277 : vec2<f32>;
var<private> p10_nodeVar278 : vec4<f32>;
var<private> p10_nodeVar279 : vec2<f32>;
var<private> p10_nodeVar280 : vec2<f32>;
var<private> p10_nodeVar281 : vec2<f32>;
var<private> p10_nodeVar282 : vec4<f32>;
var<private> p10_nodeVar283 : vec4<f32>;
var<private> p10_nodeVar284 : vec4<f32>;
var<private> p10_nodeVar285 : vec2<f32>;
var<private> p10_nodeVar286 : vec2<f32>;
var<private> p10_nodeVar287 : vec2<f32>;
var<private> p10_nodeVar288 : vec2<f32>;
var<private> p10_nodeVar289 : vec2<f32>;
var<private> p10_nodeVar290 : vec2<f32>;
var<private> p10_nodeVar291 : vec2<f32>;
var<private> p10_nodeVar292 : vec4<f32>;
var<private> p10_nodeVar293 : vec2<f32>;
var<private> p10_nodeVar294 : vec2<f32>;
var<private> p10_nodeVar295 : vec2<f32>;
var<private> p10_nodeVar296 : vec4<f32>;
var<private> p10_nodeVar297 : vec4<f32>;
var<private> p10_nodeVar298 : vec4<f32>;
var<private> p10_nodeVar299 : vec2<f32>;
var<private> p10_nodeVar300 : vec2<f32>;
var<private> p10_nodeVar301 : vec3<f32>;
var<private> p10_nodeVar302 : vec3<f32>;
var<private> p10_nodeVar303 : f32;
var<private> p10_nodeVar304 : f32;
var<private> p10_nodeVar305 : vec4<f32>;
var<private> p10_nodeVar306 : f32;
var<private> p10_nodeVar307 : vec4<f32>;
var<private> p10_nodeVar308 : f32;
var<private> p10_nodeVar309 : f32;
var<private> p10_nodeVar310 : f32;
var<private> p10_nodeVar311 : f32;
var<private> p10_nodeVar312 : vec2<f32>;
var<private> p10_nodeVar313 : vec4<f32>;
var<private> p10_nodeVar314 : vec4<f32>;
var<private> p10_nodeVar315 : f32;
var<private> p10_nodeVar316 : vec2<f32>;
var<private> p10_nodeVar317 : vec4<f32>;
var<private> p10_nodeVar318 : vec4<f32>;
var<private> p10_nodeVar319 : f32;
var<private> p10_nodeVar320 : vec2<f32>;
var<private> p10_nodeVar321 : vec4<f32>;
var<private> p10_nodeVar322 : vec4<f32>;
var<private> p10_nodeVar323 : f32;
var<private> p10_nodeVar324 : vec2<f32>;
var<private> p10_nodeVar325 : vec4<f32>;
var<private> p10_nodeVar326 : vec4<f32>;
var<private> p10_nodeVar327 : f32;
var<private> p10_nodeVar328 : vec2<f32>;
var<private> p10_nodeVar329 : vec4<f32>;
var<private> p10_nodeVar330 : vec4<f32>;
var<private> p10_nodeVar331 : f32;
var<private> p10_nodeVar332 : vec2<f32>;
var<private> p10_nodeVar333 : vec4<f32>;
var<private> p10_nodeVar334 : vec4<f32>;
var<private> p10_nodeVar335 : f32;
var<private> p10_nodeVar336 : vec2<f32>;
var<private> p10_nodeVar337 : vec4<f32>;
var<private> p10_nodeVar338 : vec4<f32>;
var<private> p10_nodeVar339 : f32;
var<private> p10_nodeVar340 : vec2<f32>;
var<private> p10_nodeVar341 : vec4<f32>;
var<private> p10_nodeVar342 : vec4<f32>;
var<private> p10_nodeVar343 : f32;
var<private> p10_nodeVar344 : vec2<f32>;
var<private> p10_nodeVar345 : vec4<f32>;
var<private> p10_nodeVar346 : vec4<f32>;
var<private> p10_nodeVar347 : f32;
var<private> p10_nodeVar348 : vec2<f32>;
var<private> p10_nodeVar349 : vec4<f32>;
var<private> p10_nodeVar350 : vec4<f32>;
var<private> p10_nodeVar351 : f32;
var<private> p10_nodeVar352 : vec4<f32>;
var<private> p10_nodeVar353 : f32;
var<private> p10_nodeVar354 : f32;
var<private> p10_nodeVar355 : vec4<f32>;
var<private> p10_nodeVar356 : f32;
var<private> p10_nodeVar357 : vec4<f32>;
var<private> p10_nodeVar358 : vec2<f32>;
var<private> p10_nodeVar359 : vec2<f32>;
var<private> p10_nodeVar360 : f32;
var<private> p10_nodeVar361 : vec4<f32>;
var<private> p10_nodeVar362 : vec4<f32>;
var<private> p10_nodeVar363 : f32;
var<private> p10_nodeVar364 : f32;
var<private> p10_nodeVar365 : f32;
var<private> p10_nodeVar366 : vec2<f32>;
var<private> p10_nodeVar367 : vec4<f32>;
var<private> p10_nodeVar368 : vec4<f32>;
var<private> p10_nodeVar369 : vec2<f32>;
var<private> p10_nodeVar370 : vec4<f32>;
var<private> p10_nodeVar371 : vec4<f32>;
var<private> p10_nodeVar372 : vec2<f32>;
var<private> p10_nodeVar373 : vec4<f32>;
var<private> p10_nodeVar374 : vec4<f32>;
var<private> p10_nodeVar375 : vec2<f32>;
var<private> p10_nodeVar376 : vec4<f32>;
var<private> p10_nodeVar377 : vec4<f32>;
var<private> p10_nodeVar378 : vec2<f32>;
var<private> p10_nodeVar379 : vec4<f32>;
var<private> p10_nodeVar380 : vec4<f32>;
var<private> p10_nodeVar381 : vec2<f32>;
var<private> p10_nodeVar382 : vec4<f32>;
var<private> p10_nodeVar383 : vec4<f32>;
var<private> p10_nodeVar384 : vec2<f32>;
var<private> p10_nodeVar385 : vec4<f32>;
var<private> p10_nodeVar386 : vec4<f32>;
var<private> p10_nodeVar387 : vec2<f32>;
var<private> p10_nodeVar388 : vec4<f32>;
var<private> p10_nodeVar389 : vec4<f32>;
var<private> p10_nodeVar390 : vec2<f32>;
var<private> p10_nodeVar391 : vec4<f32>;
var<private> p10_nodeVar392 : vec4<f32>;
var<private> p10_nodeVar393 : vec2<f32>;
var<private> p10_nodeVar394 : vec4<f32>;
var<private> p10_nodeVar395 : vec4<f32>;
var<private> p10_nodeVar396 : vec4<f32>;
var<private> p10_nodeVar397 : vec4<f32>;
var<private> p10_nodeVar398 : vec3<f32>;
var<private> p10_nodeVar399 : vec2<f32>;
var<private> p10_nodeVar400 : vec3<f32>;
var<private> p10_nodeVar401 : vec3<f32>;
var<private> p10_nodeVar402 : vec2<f32>;
var<private> p10_nodeVar403 : vec3<f32>;
var<private> p10_nodeVar404 : vec3<f32>;
var<private> p10_nodeVar405 : vec4<f32>;
var<private> p10_nodeVar406 : vec3<f32>;
var<private> p10_nodeVar407 : f32;
var<private> p10_nodeVar408 : vec3<f32>;
var<private> p10_nodeVar409 : vec4<f32>;
var<private> p10_nodeVar410 : f32;
var<private> p10_nodeVar411 : f32;
var<private> p10_Output : vec4<f32>;
var<private> p10_nodeVar412 : vec4<f32>;

// codes


fn p10_main(door_uv: vec2f) -> p10_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p10_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p10_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p10_nodeVar2 = ( ( ( p10_nodeVar1 - vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) - ( ( vec2<f32>( vec2<f32>(0.0, 0.0).x, ( - vec2<f32>(0.0, 0.0).y ) ) * vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) );
	p10_nodeVar3 = ( f32(knobs.range) * 0.5 );
	p10_nodeVar4 = max( f32(knobs.transition), 0.001 );
	p10_nodeVar5 = 1.0;

	if ( ( f32(knobs.blurFrom) < 1.5 ) ) {


		if ( ( f32(knobs.blurFrom) > 0.5 ) ) {


			if ( ( f32(0.0) > 0.5 ) ) {

				p10_nodeVar6 = picture_read_level( p10_nodeVar1, 0.0 );
				p10_nodeVar5 = clamp( ( ( abs( ( p10_nodeVar6.x - f32(knobs.focus) ) ) - p10_nodeVar3 ) / p10_nodeVar4 ), 0.0, 1.0 );
				

			} else {

				p10_nodeVar5 = 0.0;
				

			}

			

		}

		

	} else {


		if ( ( f32(knobs.blurFrom) < 2.5 ) ) {

			p10_nodeVar5 = clamp( ( ( abs( dot( p10_nodeVar2, vec2<f32>( sin( f32((0.017453292519943295 * knobs.angle + 0)) ), cos( f32((0.017453292519943295 * knobs.angle + 0)) ) ) ) ) - p10_nodeVar3 ) / p10_nodeVar4 ), 0.0, 1.0 );
			

		} else {


			if ( ( f32(knobs.blurFrom) < 3.5 ) ) {

				p10_nodeVar5 = clamp( ( ( length( p10_nodeVar2 ) - p10_nodeVar3 ) / p10_nodeVar4 ), 0.0, 1.0 );
				

			} else {

				p10_nodeVar8 = picture_read_level( p10_nodeVar1, 0.0 );
				p10_nodeVar9 = clamp( dot( vec3<f32>( p10_nodeVar8.x, p10_nodeVar8.y, p10_nodeVar8.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p10_nodeVar9 <= 0.0031308 ) ) {

					p10_nodeVar7 = ( p10_nodeVar9 * 12.92 );

				} else {

					p10_nodeVar7 = ( ( pow( p10_nodeVar9, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p10_nodeVar5 = smoothstep( ( f32(knobs.focus) - ( p10_nodeVar4 * 0.5 ) ), ( f32(knobs.focus) + ( p10_nodeVar4 * 0.5 ) ), p10_nodeVar7 );
				

			}

			

		}

		

	}


	if ( ( ( f32(knobs.invertFocus) > 0.5 ) && ( f32(knobs.blurFrom) > 0.5 ) ) ) {

		p10_nodeVar10 = ( 1.0 - p10_nodeVar5 );

	} else {

		p10_nodeVar10 = p10_nodeVar5;

	}

	p10_nodeVar11 = p10_nodeVar10;
	p10_nodeVar12 = ( ( f32(knobs.radius) * f32(1.0) ) * p10_nodeVar11 );
	p10_nodeVar13 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );

	if ( ( f32(knobs.kind) < 0.5 ) ) {

		p10_nodeVar14 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p10_nodeVar15 = clamp( log2( max( ( p10_nodeVar12 / 1.2 ), 1.0 ) ), 0.0, 10.0 );
		p10_nodeVar16 = floor( p10_nodeVar15 );
		p10_nodeVar17 = ( p10_nodeVar15 - p10_nodeVar16 );

		if ( ( p10_nodeVar16 == 0.0 ) ) {

			p10_nodeVar18 = picture_read_level( p10_nodeVar1, 0.0 );
			p10_nodeVar14 = vec4<f32>( ( vec3<f32>( p10_nodeVar18.x, p10_nodeVar18.y, p10_nodeVar18.z ) * vec3<f32>( p10_nodeVar18.w ) ), p10_nodeVar18.w );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar19 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar20 = floor( p10_nodeVar19 );
				p10_nodeVar21 = ( p10_nodeVar19 - p10_nodeVar20 );
				p10_nodeVar22 = ( p10_nodeVar21 * p10_nodeVar21 );
				p10_nodeVar23 = ( p10_nodeVar22 * p10_nodeVar21 );
				p10_nodeVar24 = ( ( ( ( p10_nodeVar23 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar22 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar25 = ( ( ( p10_nodeVar20 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar24 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar21 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar21 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar21 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar24 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar26 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar25.x, p10_nodeVar25.y ), 0.0 );
				p10_nodeVar27 = ( p10_nodeVar23 / vec2<f32>( 6.0 ) );
				p10_nodeVar28 = ( ( ( ( ( ( p10_nodeVar23 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar22 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar21 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar27 );
				p10_nodeVar29 = ( ( ( p10_nodeVar20 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar27 / p10_nodeVar28 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar30 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar25.y ), 0.0 );
				p10_nodeVar31 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar25.x, p10_nodeVar29.y ), 0.0 );
				p10_nodeVar32 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar29.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar26, p10_nodeVar30, p10_nodeVar28.x ), mix( p10_nodeVar31, p10_nodeVar32, p10_nodeVar28.x ), p10_nodeVar28.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 1.0 ) ) {

			p10_nodeVar33 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar34 = floor( p10_nodeVar33 );
			p10_nodeVar35 = ( p10_nodeVar33 - p10_nodeVar34 );
			p10_nodeVar36 = ( p10_nodeVar35 * p10_nodeVar35 );
			p10_nodeVar37 = ( p10_nodeVar36 * p10_nodeVar35 );
			p10_nodeVar38 = ( ( ( ( p10_nodeVar37 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar36 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar39 = ( ( ( p10_nodeVar34 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar38 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar35 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar35 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar35 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar38 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar40 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar39.x, p10_nodeVar39.y ), 0.0 );
			p10_nodeVar41 = ( p10_nodeVar37 / vec2<f32>( 6.0 ) );
			p10_nodeVar42 = ( ( ( ( ( ( p10_nodeVar37 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar36 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar35 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar41 );
			p10_nodeVar43 = ( ( ( p10_nodeVar34 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar41 / p10_nodeVar42 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar44 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar39.y ), 0.0 );
			p10_nodeVar45 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar39.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar46 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar40, p10_nodeVar44, p10_nodeVar42.x ), mix( p10_nodeVar45, p10_nodeVar46, p10_nodeVar42.x ), p10_nodeVar42.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar47 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar48 = floor( p10_nodeVar47 );
				p10_nodeVar49 = ( p10_nodeVar47 - p10_nodeVar48 );
				p10_nodeVar50 = ( p10_nodeVar49 * p10_nodeVar49 );
				p10_nodeVar51 = ( p10_nodeVar50 * p10_nodeVar49 );
				p10_nodeVar52 = ( ( ( ( p10_nodeVar51 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar50 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar53 = ( ( ( p10_nodeVar48 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar52 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar49 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar49 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar49 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar52 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar54 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar53.x, p10_nodeVar53.y ), 0.0 );
				p10_nodeVar55 = ( p10_nodeVar51 / vec2<f32>( 6.0 ) );
				p10_nodeVar56 = ( ( ( ( ( ( p10_nodeVar51 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar50 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar49 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar55 );
				p10_nodeVar57 = ( ( ( p10_nodeVar48 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar55 / p10_nodeVar56 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar58 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar57.x, p10_nodeVar53.y ), 0.0 );
				p10_nodeVar59 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar53.x, p10_nodeVar57.y ), 0.0 );
				p10_nodeVar60 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar57.x, p10_nodeVar57.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar54, p10_nodeVar58, p10_nodeVar56.x ), mix( p10_nodeVar59, p10_nodeVar60, p10_nodeVar56.x ), p10_nodeVar56.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 2.0 ) ) {

			p10_nodeVar61 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar62 = floor( p10_nodeVar61 );
			p10_nodeVar63 = ( p10_nodeVar61 - p10_nodeVar62 );
			p10_nodeVar64 = ( p10_nodeVar63 * p10_nodeVar63 );
			p10_nodeVar65 = ( p10_nodeVar64 * p10_nodeVar63 );
			p10_nodeVar66 = ( ( ( ( p10_nodeVar65 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar64 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar67 = ( ( ( p10_nodeVar62 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar66 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar63 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar63 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar63 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar66 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar68 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar67.x, p10_nodeVar67.y ), 0.0 );
			p10_nodeVar69 = ( p10_nodeVar65 / vec2<f32>( 6.0 ) );
			p10_nodeVar70 = ( ( ( ( ( ( p10_nodeVar65 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar64 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar63 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar69 );
			p10_nodeVar71 = ( ( ( p10_nodeVar62 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar69 / p10_nodeVar70 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar72 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar71.x, p10_nodeVar67.y ), 0.0 );
			p10_nodeVar73 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar67.x, p10_nodeVar71.y ), 0.0 );
			p10_nodeVar74 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar71.x, p10_nodeVar71.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar68, p10_nodeVar72, p10_nodeVar70.x ), mix( p10_nodeVar73, p10_nodeVar74, p10_nodeVar70.x ), p10_nodeVar70.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar75 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar76 = floor( p10_nodeVar75 );
				p10_nodeVar77 = ( p10_nodeVar75 - p10_nodeVar76 );
				p10_nodeVar78 = ( p10_nodeVar77 * p10_nodeVar77 );
				p10_nodeVar79 = ( p10_nodeVar78 * p10_nodeVar77 );
				p10_nodeVar80 = ( ( ( ( p10_nodeVar79 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar78 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar81 = ( ( ( p10_nodeVar76 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar80 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar77 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar77 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar77 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar80 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar82 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar81.x, p10_nodeVar81.y ), 0.0 );
				p10_nodeVar83 = ( p10_nodeVar79 / vec2<f32>( 6.0 ) );
				p10_nodeVar84 = ( ( ( ( ( ( p10_nodeVar79 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar78 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar77 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar83 );
				p10_nodeVar85 = ( ( ( p10_nodeVar76 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar83 / p10_nodeVar84 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar86 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar85.x, p10_nodeVar81.y ), 0.0 );
				p10_nodeVar87 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar81.x, p10_nodeVar85.y ), 0.0 );
				p10_nodeVar88 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar85.x, p10_nodeVar85.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar82, p10_nodeVar86, p10_nodeVar84.x ), mix( p10_nodeVar87, p10_nodeVar88, p10_nodeVar84.x ), p10_nodeVar84.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 3.0 ) ) {

			p10_nodeVar89 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar90 = floor( p10_nodeVar89 );
			p10_nodeVar91 = ( p10_nodeVar89 - p10_nodeVar90 );
			p10_nodeVar92 = ( p10_nodeVar91 * p10_nodeVar91 );
			p10_nodeVar93 = ( p10_nodeVar92 * p10_nodeVar91 );
			p10_nodeVar94 = ( ( ( ( p10_nodeVar93 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar92 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar95 = ( ( ( p10_nodeVar90 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar94 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar91 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar91 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar91 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar94 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar96 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar95.x, p10_nodeVar95.y ), 0.0 );
			p10_nodeVar97 = ( p10_nodeVar93 / vec2<f32>( 6.0 ) );
			p10_nodeVar98 = ( ( ( ( ( ( p10_nodeVar93 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar92 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar91 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar97 );
			p10_nodeVar99 = ( ( ( p10_nodeVar90 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar97 / p10_nodeVar98 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar100 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar99.x, p10_nodeVar95.y ), 0.0 );
			p10_nodeVar101 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar95.x, p10_nodeVar99.y ), 0.0 );
			p10_nodeVar102 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar99.x, p10_nodeVar99.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar96, p10_nodeVar100, p10_nodeVar98.x ), mix( p10_nodeVar101, p10_nodeVar102, p10_nodeVar98.x ), p10_nodeVar98.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar103 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar104 = floor( p10_nodeVar103 );
				p10_nodeVar105 = ( p10_nodeVar103 - p10_nodeVar104 );
				p10_nodeVar106 = ( p10_nodeVar105 * p10_nodeVar105 );
				p10_nodeVar107 = ( p10_nodeVar106 * p10_nodeVar105 );
				p10_nodeVar108 = ( ( ( ( p10_nodeVar107 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar106 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar109 = ( ( ( p10_nodeVar104 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar108 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar105 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar105 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar105 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar108 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar110 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar109.x, p10_nodeVar109.y ), 0.0 );
				p10_nodeVar111 = ( p10_nodeVar107 / vec2<f32>( 6.0 ) );
				p10_nodeVar112 = ( ( ( ( ( ( p10_nodeVar107 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar106 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar105 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar111 );
				p10_nodeVar113 = ( ( ( p10_nodeVar104 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar111 / p10_nodeVar112 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar114 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar113.x, p10_nodeVar109.y ), 0.0 );
				p10_nodeVar115 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar109.x, p10_nodeVar113.y ), 0.0 );
				p10_nodeVar116 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar113.x, p10_nodeVar113.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar110, p10_nodeVar114, p10_nodeVar112.x ), mix( p10_nodeVar115, p10_nodeVar116, p10_nodeVar112.x ), p10_nodeVar112.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 4.0 ) ) {

			p10_nodeVar117 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar118 = floor( p10_nodeVar117 );
			p10_nodeVar119 = ( p10_nodeVar117 - p10_nodeVar118 );
			p10_nodeVar120 = ( p10_nodeVar119 * p10_nodeVar119 );
			p10_nodeVar121 = ( p10_nodeVar120 * p10_nodeVar119 );
			p10_nodeVar122 = ( ( ( ( p10_nodeVar121 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar120 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar123 = ( ( ( p10_nodeVar118 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar122 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar119 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar119 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar119 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar122 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar124 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar123.x, p10_nodeVar123.y ), 0.0 );
			p10_nodeVar125 = ( p10_nodeVar121 / vec2<f32>( 6.0 ) );
			p10_nodeVar126 = ( ( ( ( ( ( p10_nodeVar121 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar120 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar119 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar125 );
			p10_nodeVar127 = ( ( ( p10_nodeVar118 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar125 / p10_nodeVar126 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar128 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar127.x, p10_nodeVar123.y ), 0.0 );
			p10_nodeVar129 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar123.x, p10_nodeVar127.y ), 0.0 );
			p10_nodeVar130 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar127.x, p10_nodeVar127.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar124, p10_nodeVar128, p10_nodeVar126.x ), mix( p10_nodeVar129, p10_nodeVar130, p10_nodeVar126.x ), p10_nodeVar126.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar131 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar132 = floor( p10_nodeVar131 );
				p10_nodeVar133 = ( p10_nodeVar131 - p10_nodeVar132 );
				p10_nodeVar134 = ( p10_nodeVar133 * p10_nodeVar133 );
				p10_nodeVar135 = ( p10_nodeVar134 * p10_nodeVar133 );
				p10_nodeVar136 = ( ( ( ( p10_nodeVar135 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar134 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar137 = ( ( ( p10_nodeVar132 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar136 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar133 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar133 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar133 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar136 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar138 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar137.x, p10_nodeVar137.y ), 0.0 );
				p10_nodeVar139 = ( p10_nodeVar135 / vec2<f32>( 6.0 ) );
				p10_nodeVar140 = ( ( ( ( ( ( p10_nodeVar135 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar134 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar133 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar139 );
				p10_nodeVar141 = ( ( ( p10_nodeVar132 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar139 / p10_nodeVar140 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar142 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar141.x, p10_nodeVar137.y ), 0.0 );
				p10_nodeVar143 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar137.x, p10_nodeVar141.y ), 0.0 );
				p10_nodeVar144 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar141.x, p10_nodeVar141.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar138, p10_nodeVar142, p10_nodeVar140.x ), mix( p10_nodeVar143, p10_nodeVar144, p10_nodeVar140.x ), p10_nodeVar140.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 5.0 ) ) {

			p10_nodeVar145 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar146 = floor( p10_nodeVar145 );
			p10_nodeVar147 = ( p10_nodeVar145 - p10_nodeVar146 );
			p10_nodeVar148 = ( p10_nodeVar147 * p10_nodeVar147 );
			p10_nodeVar149 = ( p10_nodeVar148 * p10_nodeVar147 );
			p10_nodeVar150 = ( ( ( ( p10_nodeVar149 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar148 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar151 = ( ( ( p10_nodeVar146 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar150 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar147 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar147 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar147 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar150 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar152 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar151.x, p10_nodeVar151.y ), 0.0 );
			p10_nodeVar153 = ( p10_nodeVar149 / vec2<f32>( 6.0 ) );
			p10_nodeVar154 = ( ( ( ( ( ( p10_nodeVar149 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar148 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar147 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar153 );
			p10_nodeVar155 = ( ( ( p10_nodeVar146 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar153 / p10_nodeVar154 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar156 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar155.x, p10_nodeVar151.y ), 0.0 );
			p10_nodeVar157 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar151.x, p10_nodeVar155.y ), 0.0 );
			p10_nodeVar158 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar155.x, p10_nodeVar155.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar152, p10_nodeVar156, p10_nodeVar154.x ), mix( p10_nodeVar157, p10_nodeVar158, p10_nodeVar154.x ), p10_nodeVar154.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar159 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar160 = floor( p10_nodeVar159 );
				p10_nodeVar161 = ( p10_nodeVar159 - p10_nodeVar160 );
				p10_nodeVar162 = ( p10_nodeVar161 * p10_nodeVar161 );
				p10_nodeVar163 = ( p10_nodeVar162 * p10_nodeVar161 );
				p10_nodeVar164 = ( ( ( ( p10_nodeVar163 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar162 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar165 = ( ( ( p10_nodeVar160 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar164 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar161 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar161 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar161 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar164 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar166 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar165.x, p10_nodeVar165.y ), 0.0 );
				p10_nodeVar167 = ( p10_nodeVar163 / vec2<f32>( 6.0 ) );
				p10_nodeVar168 = ( ( ( ( ( ( p10_nodeVar163 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar162 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar161 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar167 );
				p10_nodeVar169 = ( ( ( p10_nodeVar160 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar167 / p10_nodeVar168 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar170 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar169.x, p10_nodeVar165.y ), 0.0 );
				p10_nodeVar171 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar165.x, p10_nodeVar169.y ), 0.0 );
				p10_nodeVar172 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar169.x, p10_nodeVar169.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar166, p10_nodeVar170, p10_nodeVar168.x ), mix( p10_nodeVar171, p10_nodeVar172, p10_nodeVar168.x ), p10_nodeVar168.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 6.0 ) ) {

			p10_nodeVar173 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar174 = floor( p10_nodeVar173 );
			p10_nodeVar175 = ( p10_nodeVar173 - p10_nodeVar174 );
			p10_nodeVar176 = ( p10_nodeVar175 * p10_nodeVar175 );
			p10_nodeVar177 = ( p10_nodeVar176 * p10_nodeVar175 );
			p10_nodeVar178 = ( ( ( ( p10_nodeVar177 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar176 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar179 = ( ( ( p10_nodeVar174 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar178 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar178 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar180 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar179.x, p10_nodeVar179.y ), 0.0 );
			p10_nodeVar181 = ( p10_nodeVar177 / vec2<f32>( 6.0 ) );
			p10_nodeVar182 = ( ( ( ( ( ( p10_nodeVar177 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar176 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar175 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar181 );
			p10_nodeVar183 = ( ( ( p10_nodeVar174 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar181 / p10_nodeVar182 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar184 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar183.x, p10_nodeVar179.y ), 0.0 );
			p10_nodeVar185 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar179.x, p10_nodeVar183.y ), 0.0 );
			p10_nodeVar186 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar183.x, p10_nodeVar183.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar180, p10_nodeVar184, p10_nodeVar182.x ), mix( p10_nodeVar185, p10_nodeVar186, p10_nodeVar182.x ), p10_nodeVar182.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar187 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar188 = floor( p10_nodeVar187 );
				p10_nodeVar189 = ( p10_nodeVar187 - p10_nodeVar188 );
				p10_nodeVar190 = ( p10_nodeVar189 * p10_nodeVar189 );
				p10_nodeVar191 = ( p10_nodeVar190 * p10_nodeVar189 );
				p10_nodeVar192 = ( ( ( ( p10_nodeVar191 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar190 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar193 = ( ( ( p10_nodeVar188 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar192 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar192 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar194 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar193.x, p10_nodeVar193.y ), 0.0 );
				p10_nodeVar195 = ( p10_nodeVar191 / vec2<f32>( 6.0 ) );
				p10_nodeVar196 = ( ( ( ( ( ( p10_nodeVar191 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar190 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar189 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar195 );
				p10_nodeVar197 = ( ( ( p10_nodeVar188 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar195 / p10_nodeVar196 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar198 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar197.x, p10_nodeVar193.y ), 0.0 );
				p10_nodeVar199 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar193.x, p10_nodeVar197.y ), 0.0 );
				p10_nodeVar200 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar197.x, p10_nodeVar197.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar194, p10_nodeVar198, p10_nodeVar196.x ), mix( p10_nodeVar199, p10_nodeVar200, p10_nodeVar196.x ), p10_nodeVar196.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 7.0 ) ) {

			p10_nodeVar201 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar202 = floor( p10_nodeVar201 );
			p10_nodeVar203 = ( p10_nodeVar201 - p10_nodeVar202 );
			p10_nodeVar204 = ( p10_nodeVar203 * p10_nodeVar203 );
			p10_nodeVar205 = ( p10_nodeVar204 * p10_nodeVar203 );
			p10_nodeVar206 = ( ( ( ( p10_nodeVar205 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar204 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar207 = ( ( ( p10_nodeVar202 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar206 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar203 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar203 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar203 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar206 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar208 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar207.x, p10_nodeVar207.y ), 0.0 );
			p10_nodeVar209 = ( p10_nodeVar205 / vec2<f32>( 6.0 ) );
			p10_nodeVar210 = ( ( ( ( ( ( p10_nodeVar205 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar204 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar203 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar209 );
			p10_nodeVar211 = ( ( ( p10_nodeVar202 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar209 / p10_nodeVar210 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar212 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar211.x, p10_nodeVar207.y ), 0.0 );
			p10_nodeVar213 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar207.x, p10_nodeVar211.y ), 0.0 );
			p10_nodeVar214 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar211.x, p10_nodeVar211.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar208, p10_nodeVar212, p10_nodeVar210.x ), mix( p10_nodeVar213, p10_nodeVar214, p10_nodeVar210.x ), p10_nodeVar210.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar215 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar216 = floor( p10_nodeVar215 );
				p10_nodeVar217 = ( p10_nodeVar215 - p10_nodeVar216 );
				p10_nodeVar218 = ( p10_nodeVar217 * p10_nodeVar217 );
				p10_nodeVar219 = ( p10_nodeVar218 * p10_nodeVar217 );
				p10_nodeVar220 = ( ( ( ( p10_nodeVar219 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar218 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar221 = ( ( ( p10_nodeVar216 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar220 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar217 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar217 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar217 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar220 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar222 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar221.x, p10_nodeVar221.y ), 0.0 );
				p10_nodeVar223 = ( p10_nodeVar219 / vec2<f32>( 6.0 ) );
				p10_nodeVar224 = ( ( ( ( ( ( p10_nodeVar219 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar218 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar217 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar223 );
				p10_nodeVar225 = ( ( ( p10_nodeVar216 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar223 / p10_nodeVar224 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar226 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar225.x, p10_nodeVar221.y ), 0.0 );
				p10_nodeVar227 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar221.x, p10_nodeVar225.y ), 0.0 );
				p10_nodeVar228 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar225.x, p10_nodeVar225.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar222, p10_nodeVar226, p10_nodeVar224.x ), mix( p10_nodeVar227, p10_nodeVar228, p10_nodeVar224.x ), p10_nodeVar224.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 8.0 ) ) {

			p10_nodeVar229 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar230 = floor( p10_nodeVar229 );
			p10_nodeVar231 = ( p10_nodeVar229 - p10_nodeVar230 );
			p10_nodeVar232 = ( p10_nodeVar231 * p10_nodeVar231 );
			p10_nodeVar233 = ( p10_nodeVar232 * p10_nodeVar231 );
			p10_nodeVar234 = ( ( ( ( p10_nodeVar233 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar232 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar235 = ( ( ( p10_nodeVar230 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar234 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar231 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar231 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar231 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar234 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar236 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar235.x, p10_nodeVar235.y ), 0.0 );
			p10_nodeVar237 = ( p10_nodeVar233 / vec2<f32>( 6.0 ) );
			p10_nodeVar238 = ( ( ( ( ( ( p10_nodeVar233 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar232 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar231 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar237 );
			p10_nodeVar239 = ( ( ( p10_nodeVar230 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar237 / p10_nodeVar238 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar240 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar239.x, p10_nodeVar235.y ), 0.0 );
			p10_nodeVar241 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar235.x, p10_nodeVar239.y ), 0.0 );
			p10_nodeVar242 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar239.x, p10_nodeVar239.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar236, p10_nodeVar240, p10_nodeVar238.x ), mix( p10_nodeVar241, p10_nodeVar242, p10_nodeVar238.x ), p10_nodeVar238.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar243 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar244 = floor( p10_nodeVar243 );
				p10_nodeVar245 = ( p10_nodeVar243 - p10_nodeVar244 );
				p10_nodeVar246 = ( p10_nodeVar245 * p10_nodeVar245 );
				p10_nodeVar247 = ( p10_nodeVar246 * p10_nodeVar245 );
				p10_nodeVar248 = ( ( ( ( p10_nodeVar247 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar246 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar249 = ( ( ( p10_nodeVar244 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar248 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar245 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar245 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar245 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar248 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar250 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar249.x, p10_nodeVar249.y ), 0.0 );
				p10_nodeVar251 = ( p10_nodeVar247 / vec2<f32>( 6.0 ) );
				p10_nodeVar252 = ( ( ( ( ( ( p10_nodeVar247 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar246 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar245 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar251 );
				p10_nodeVar253 = ( ( ( p10_nodeVar244 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar251 / p10_nodeVar252 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p10_nodeVar254 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar253.x, p10_nodeVar249.y ), 0.0 );
				p10_nodeVar255 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar249.x, p10_nodeVar253.y ), 0.0 );
				p10_nodeVar256 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar253.x, p10_nodeVar253.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar250, p10_nodeVar254, p10_nodeVar252.x ), mix( p10_nodeVar255, p10_nodeVar256, p10_nodeVar252.x ), p10_nodeVar252.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 == 9.0 ) ) {

			p10_nodeVar257 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar258 = floor( p10_nodeVar257 );
			p10_nodeVar259 = ( p10_nodeVar257 - p10_nodeVar258 );
			p10_nodeVar260 = ( p10_nodeVar259 * p10_nodeVar259 );
			p10_nodeVar261 = ( p10_nodeVar260 * p10_nodeVar259 );
			p10_nodeVar262 = ( ( ( ( p10_nodeVar261 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar260 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar263 = ( ( ( p10_nodeVar258 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar262 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar259 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar259 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar259 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar262 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar264 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar263.x, p10_nodeVar263.y ), 0.0 );
			p10_nodeVar265 = ( p10_nodeVar261 / vec2<f32>( 6.0 ) );
			p10_nodeVar266 = ( ( ( ( ( ( p10_nodeVar261 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar260 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar259 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar265 );
			p10_nodeVar267 = ( ( ( p10_nodeVar258 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar265 / p10_nodeVar266 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p10_nodeVar268 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar267.x, p10_nodeVar263.y ), 0.0 );
			p10_nodeVar269 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar263.x, p10_nodeVar267.y ), 0.0 );
			p10_nodeVar270 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar267.x, p10_nodeVar267.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar264, p10_nodeVar268, p10_nodeVar266.x ), mix( p10_nodeVar269, p10_nodeVar270, p10_nodeVar266.x ), p10_nodeVar266.y );

			if ( ( p10_nodeVar17 > 0.0 ) ) {

				p10_nodeVar271 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p10_nodeVar272 = floor( p10_nodeVar271 );
				p10_nodeVar273 = ( p10_nodeVar271 - p10_nodeVar272 );
				p10_nodeVar274 = ( p10_nodeVar273 * p10_nodeVar273 );
				p10_nodeVar275 = ( p10_nodeVar274 * p10_nodeVar273 );
				p10_nodeVar276 = ( ( ( ( p10_nodeVar275 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar274 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p10_nodeVar277 = ( ( ( p10_nodeVar272 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar276 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar273 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar273 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar273 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar276 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar278 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar277.x, p10_nodeVar277.y ), 0.0 );
				p10_nodeVar279 = ( p10_nodeVar275 / vec2<f32>( 6.0 ) );
				p10_nodeVar280 = ( ( ( ( ( ( p10_nodeVar275 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar274 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar273 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar279 );
				p10_nodeVar281 = ( ( ( p10_nodeVar272 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar279 / p10_nodeVar280 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p10_nodeVar282 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar281.x, p10_nodeVar277.y ), 0.0 );
				p10_nodeVar283 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar277.x, p10_nodeVar281.y ), 0.0 );
				p10_nodeVar284 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar281.x, p10_nodeVar281.y ), 0.0 );
				p10_nodeVar14 = mix( p10_nodeVar14, mix( mix( p10_nodeVar278, p10_nodeVar282, p10_nodeVar280.x ), mix( p10_nodeVar283, p10_nodeVar284, p10_nodeVar280.x ), p10_nodeVar280.y ), p10_nodeVar17 );
				

			}

			

		}


		if ( ( p10_nodeVar16 >= 10.0 ) ) {

			p10_nodeVar285 = ( ( p10_nodeVar1 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar286 = floor( p10_nodeVar285 );
			p10_nodeVar287 = ( p10_nodeVar285 - p10_nodeVar286 );
			p10_nodeVar288 = ( p10_nodeVar287 * p10_nodeVar287 );
			p10_nodeVar289 = ( p10_nodeVar288 * p10_nodeVar287 );
			p10_nodeVar290 = ( ( ( ( p10_nodeVar289 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar288 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar291 = ( ( ( p10_nodeVar286 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar290 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar287 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar287 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar287 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar290 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar292 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar291.x, p10_nodeVar291.y ), 0.0 );
			p10_nodeVar293 = ( p10_nodeVar289 / vec2<f32>( 6.0 ) );
			p10_nodeVar294 = ( ( ( ( ( ( p10_nodeVar289 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar288 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar287 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar293 );
			p10_nodeVar295 = ( ( ( p10_nodeVar286 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar293 / p10_nodeVar294 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p10_nodeVar296 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar295.x, p10_nodeVar291.y ), 0.0 );
			p10_nodeVar297 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar291.x, p10_nodeVar295.y ), 0.0 );
			p10_nodeVar298 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar295.x, p10_nodeVar295.y ), 0.0 );
			p10_nodeVar14 = mix( mix( p10_nodeVar292, p10_nodeVar296, p10_nodeVar294.x ), mix( p10_nodeVar297, p10_nodeVar298, p10_nodeVar294.x ), p10_nodeVar294.y );
			

		}

		p10_nodeVar13 = p10_nodeVar14;
		

	}


	if ( ( ( f32(knobs.kind) > 0.5 ) && ( f32(knobs.kind) < 1.5 ) ) ) {


		if ( ( p10_nodeVar12 > 0.0 ) ) {

			p10_nodeVar299 = vec2<f32>( ( 1.0 / ( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x * f32(1.0) ) ), ( 1.0 / ( vec2<f32>(knobs.resolution.x, knobs.resolution.y).y * f32(1.0) ) ) );
			p10_nodeVar300 = ( ( p10_nodeVar1 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) + vec2<f32>( 17.3 ) );
			p10_nodeVar301 = fract( ( vec3<f32>( p10_nodeVar300.x, p10_nodeVar300.y, p10_nodeVar300.x ) * vec3<f32>( 0.1031 ) ) );
			p10_nodeVar302 = ( p10_nodeVar301 + vec3<f32>( dot( p10_nodeVar301, ( vec3<f32>( p10_nodeVar301.y, p10_nodeVar301.z, p10_nodeVar301.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p10_nodeVar303 = ( fract( ( ( p10_nodeVar302.x + p10_nodeVar302.y ) * p10_nodeVar302.z ) ) * 6.2831853 );
			p10_nodeVar304 = log2( max( ( ( p10_nodeVar12 / 4.409081537009721 ) / 1.2 ), 1.0 ) );
			p10_nodeVar305 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
			p10_nodeVar306 = 0.0;

			for ( var lensTap : i32 = 0; lensTap < 24; lensTap ++ ) {

				p10_nodeVar307 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
				p10_nodeVar308 = clamp( p10_nodeVar304, 0.0, 10.0 );
				p10_nodeVar309 = floor( p10_nodeVar308 );
				p10_nodeVar310 = ( p10_nodeVar308 - p10_nodeVar309 );

				if ( ( p10_nodeVar309 == 0.0 ) ) {

					p10_nodeVar311 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar312 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar311 ), sin( p10_nodeVar311 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar313 = picture_read_level( p10_nodeVar312, 0.0 );
					p10_nodeVar307 = vec4<f32>( ( vec3<f32>( p10_nodeVar313.x, p10_nodeVar313.y, p10_nodeVar313.z ) * vec3<f32>( p10_nodeVar313.w ) ), p10_nodeVar313.w );

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar314 = target_read_level( t0, t0_sampler, p10_nodeVar312, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar314, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 1.0 ) ) {

					p10_nodeVar315 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar316 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar315 ), sin( p10_nodeVar315 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar317 = target_read_level( t0, t0_sampler, p10_nodeVar316, 0.0 );
					p10_nodeVar307 = p10_nodeVar317;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar318 = target_read_level( t1, t1_sampler, p10_nodeVar316, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar318, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 2.0 ) ) {

					p10_nodeVar319 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar320 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar319 ), sin( p10_nodeVar319 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar321 = target_read_level( t1, t1_sampler, p10_nodeVar320, 0.0 );
					p10_nodeVar307 = p10_nodeVar321;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar322 = target_read_level( t2, t2_sampler, p10_nodeVar320, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar322, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 3.0 ) ) {

					p10_nodeVar323 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar324 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar323 ), sin( p10_nodeVar323 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar325 = target_read_level( t2, t2_sampler, p10_nodeVar324, 0.0 );
					p10_nodeVar307 = p10_nodeVar325;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar326 = target_read_level( t3, t3_sampler, p10_nodeVar324, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar326, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 4.0 ) ) {

					p10_nodeVar327 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar328 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar327 ), sin( p10_nodeVar327 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar329 = target_read_level( t3, t3_sampler, p10_nodeVar328, 0.0 );
					p10_nodeVar307 = p10_nodeVar329;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar330 = target_read_level( t4, t4_sampler, p10_nodeVar328, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar330, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 5.0 ) ) {

					p10_nodeVar331 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar332 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar331 ), sin( p10_nodeVar331 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar333 = target_read_level( t4, t4_sampler, p10_nodeVar332, 0.0 );
					p10_nodeVar307 = p10_nodeVar333;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar334 = target_read_level( t5, t5_sampler, p10_nodeVar332, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar334, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 6.0 ) ) {

					p10_nodeVar335 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar336 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar335 ), sin( p10_nodeVar335 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar337 = target_read_level( t5, t5_sampler, p10_nodeVar336, 0.0 );
					p10_nodeVar307 = p10_nodeVar337;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar338 = target_read_level( t6, t6_sampler, p10_nodeVar336, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar338, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 7.0 ) ) {

					p10_nodeVar339 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar340 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar339 ), sin( p10_nodeVar339 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar341 = target_read_level( t6, t6_sampler, p10_nodeVar340, 0.0 );
					p10_nodeVar307 = p10_nodeVar341;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar342 = target_read_level( t7, t7_sampler, p10_nodeVar340, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar342, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 8.0 ) ) {

					p10_nodeVar343 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar344 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar343 ), sin( p10_nodeVar343 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar345 = target_read_level( t7, t7_sampler, p10_nodeVar344, 0.0 );
					p10_nodeVar307 = p10_nodeVar345;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar346 = target_read_level( t8, t8_sampler, p10_nodeVar344, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar346, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 == 9.0 ) ) {

					p10_nodeVar347 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar348 = ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar347 ), sin( p10_nodeVar347 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) );
					p10_nodeVar349 = target_read_level( t8, t8_sampler, p10_nodeVar348, 0.0 );
					p10_nodeVar307 = p10_nodeVar349;

					if ( ( p10_nodeVar310 > 0.0 ) ) {

						p10_nodeVar350 = target_read_level( t9, t9_sampler, p10_nodeVar348, 0.0 );
						p10_nodeVar307 = mix( p10_nodeVar307, p10_nodeVar350, p10_nodeVar310 );
						

					}

					

				}


				if ( ( p10_nodeVar309 >= 10.0 ) ) {

					p10_nodeVar351 = ( ( f32( lensTap ) * 2.399963229728653 ) + p10_nodeVar303 );
					p10_nodeVar352 = target_read_level( t9, t9_sampler, ( p10_nodeVar1 + ( ( ( vec2<f32>( cos( p10_nodeVar351 ), sin( p10_nodeVar351 ) ) * vec2<f32>( sqrt( ( ( f32( lensTap ) + 0.5 ) / 24.0 ) ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar299 ) ), 0.0 );
					p10_nodeVar307 = p10_nodeVar352;
					

				}

				p10_nodeVar353 = 1.0;

				if ( ( f32(knobs.highlights) > 0.0 ) ) {

					p10_nodeVar355 = vec4<f32>( ( p10_nodeVar307.xyz / vec3<f32>( max( p10_nodeVar307.w, 0.0001 ) ) ), p10_nodeVar307.w );
					p10_nodeVar356 = clamp( dot( vec3<f32>( p10_nodeVar355.x, p10_nodeVar355.y, p10_nodeVar355.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p10_nodeVar356 <= 0.0031308 ) ) {

						p10_nodeVar354 = ( p10_nodeVar356 * 12.92 );

					} else {

						p10_nodeVar354 = ( ( pow( p10_nodeVar356, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p10_nodeVar353 = ( 1.0 + ( ( pow( p10_nodeVar354, 4.0 ) * f32(knobs.highlights) ) * 8.0 ) );
					

				}

				p10_nodeVar305 = ( p10_nodeVar305 + ( p10_nodeVar307 * vec4<f32>( p10_nodeVar353 ) ) );
				p10_nodeVar306 = ( p10_nodeVar306 + p10_nodeVar353 );

			}

			p10_nodeVar13 = ( p10_nodeVar305 / vec4<f32>( p10_nodeVar306 ) );
			

		} else {

			p10_nodeVar357 = picture_read_level( p10_nodeVar1, 0.0 );
			p10_nodeVar13 = vec4<f32>( ( vec3<f32>( p10_nodeVar357.x, p10_nodeVar357.y, p10_nodeVar357.z ) * vec3<f32>( p10_nodeVar357.w ) ), p10_nodeVar357.w );
			

		}

		

	}


	if ( ( f32(knobs.kind) > 1.5 ) ) {


		if ( ( p10_nodeVar12 > 0.0 ) ) {

			p10_nodeVar358 = vec2<f32>( ( 1.0 / ( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x * f32(1.0) ) ), ( 1.0 / ( vec2<f32>(knobs.resolution.x, knobs.resolution.y).y * f32(1.0) ) ) );
			p10_nodeVar359 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.motionAngle + 0)) ), ( - sin( f32((0.017453292519943295 * knobs.motionAngle + 0)) ) ) );
			p10_nodeVar360 = log2( max( ( ( p10_nodeVar12 / 12.0 ) / 1.2 ), 1.0 ) );
			p10_nodeVar361 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );

			for ( var motionTap : i32 = 0; motionTap < 24; motionTap ++ ) {

				p10_nodeVar362 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
				p10_nodeVar363 = clamp( p10_nodeVar360, 0.0, 10.0 );
				p10_nodeVar364 = floor( p10_nodeVar363 );
				p10_nodeVar365 = ( p10_nodeVar363 - p10_nodeVar364 );

				if ( ( p10_nodeVar364 == 0.0 ) ) {

					p10_nodeVar366 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar367 = picture_read_level( p10_nodeVar366, 0.0 );
					p10_nodeVar362 = vec4<f32>( ( vec3<f32>( p10_nodeVar367.x, p10_nodeVar367.y, p10_nodeVar367.z ) * vec3<f32>( p10_nodeVar367.w ) ), p10_nodeVar367.w );

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar368 = target_read_level( t0, t0_sampler, p10_nodeVar366, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar368, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 1.0 ) ) {

					p10_nodeVar369 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar370 = target_read_level( t0, t0_sampler, p10_nodeVar369, 0.0 );
					p10_nodeVar362 = p10_nodeVar370;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar371 = target_read_level( t1, t1_sampler, p10_nodeVar369, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar371, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 2.0 ) ) {

					p10_nodeVar372 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar373 = target_read_level( t1, t1_sampler, p10_nodeVar372, 0.0 );
					p10_nodeVar362 = p10_nodeVar373;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar374 = target_read_level( t2, t2_sampler, p10_nodeVar372, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar374, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 3.0 ) ) {

					p10_nodeVar375 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar376 = target_read_level( t2, t2_sampler, p10_nodeVar375, 0.0 );
					p10_nodeVar362 = p10_nodeVar376;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar377 = target_read_level( t3, t3_sampler, p10_nodeVar375, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar377, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 4.0 ) ) {

					p10_nodeVar378 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar379 = target_read_level( t3, t3_sampler, p10_nodeVar378, 0.0 );
					p10_nodeVar362 = p10_nodeVar379;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar380 = target_read_level( t4, t4_sampler, p10_nodeVar378, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar380, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 5.0 ) ) {

					p10_nodeVar381 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar382 = target_read_level( t4, t4_sampler, p10_nodeVar381, 0.0 );
					p10_nodeVar362 = p10_nodeVar382;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar383 = target_read_level( t5, t5_sampler, p10_nodeVar381, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar383, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 6.0 ) ) {

					p10_nodeVar384 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar385 = target_read_level( t5, t5_sampler, p10_nodeVar384, 0.0 );
					p10_nodeVar362 = p10_nodeVar385;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar386 = target_read_level( t6, t6_sampler, p10_nodeVar384, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar386, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 7.0 ) ) {

					p10_nodeVar387 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar388 = target_read_level( t6, t6_sampler, p10_nodeVar387, 0.0 );
					p10_nodeVar362 = p10_nodeVar388;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar389 = target_read_level( t7, t7_sampler, p10_nodeVar387, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar389, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 8.0 ) ) {

					p10_nodeVar390 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar391 = target_read_level( t7, t7_sampler, p10_nodeVar390, 0.0 );
					p10_nodeVar362 = p10_nodeVar391;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar392 = target_read_level( t8, t8_sampler, p10_nodeVar390, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar392, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 == 9.0 ) ) {

					p10_nodeVar393 = ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) );
					p10_nodeVar394 = target_read_level( t8, t8_sampler, p10_nodeVar393, 0.0 );
					p10_nodeVar362 = p10_nodeVar394;

					if ( ( p10_nodeVar365 > 0.0 ) ) {

						p10_nodeVar395 = target_read_level( t9, t9_sampler, p10_nodeVar393, 0.0 );
						p10_nodeVar362 = mix( p10_nodeVar362, p10_nodeVar395, p10_nodeVar365 );
						

					}

					

				}


				if ( ( p10_nodeVar364 >= 10.0 ) ) {

					p10_nodeVar396 = target_read_level( t9, t9_sampler, ( p10_nodeVar1 + ( ( ( p10_nodeVar359 * vec2<f32>( ( ( ( ( f32( motionTap ) + 0.5 ) / 24.0 ) - 0.5 ) * 2.0 ) ) ) * vec2<f32>( p10_nodeVar12 ) ) * p10_nodeVar358 ) ), 0.0 );
					p10_nodeVar362 = p10_nodeVar396;
					

				}

				p10_nodeVar361 = ( p10_nodeVar361 + p10_nodeVar362 );

			}

			p10_nodeVar13 = ( p10_nodeVar361 / vec4<f32>( 24.0 ) );
			

		} else {

			p10_nodeVar397 = picture_read_level( p10_nodeVar1, 0.0 );
			p10_nodeVar13 = vec4<f32>( ( vec3<f32>( p10_nodeVar397.x, p10_nodeVar397.y, p10_nodeVar397.z ) * vec3<f32>( p10_nodeVar397.w ) ), p10_nodeVar397.w );
			

		}

		

	}

	p10_nodeVar398 = ( p10_nodeVar13.xyz / vec3<f32>( max( p10_nodeVar13.w, 0.0001 ) ) );

	if ( ( f32(knobs.grain) > 0.0 ) ) {

		p10_nodeVar399 = floor( ( ( p10_nodeVar1 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) / vec2<f32>( f32(knobs.grainSize) ) ) );
		p10_nodeVar400 = fract( ( vec3<f32>( p10_nodeVar399.x, p10_nodeVar399.y, p10_nodeVar399.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar401 = ( p10_nodeVar400 + vec3<f32>( dot( p10_nodeVar400, ( vec3<f32>( p10_nodeVar400.y, p10_nodeVar400.z, p10_nodeVar400.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar402 = ( p10_nodeVar399 + vec2<f32>( 31.7 ) );
		p10_nodeVar403 = fract( ( vec3<f32>( p10_nodeVar402.x, p10_nodeVar402.y, p10_nodeVar402.x ) * vec3<f32>( 0.1031 ) ) );
		p10_nodeVar404 = ( p10_nodeVar403 + vec3<f32>( dot( p10_nodeVar403, ( vec3<f32>( p10_nodeVar403.y, p10_nodeVar403.z, p10_nodeVar403.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p10_nodeVar398 = ( p10_nodeVar398 + vec3<f32>( ( ( ( ( ( fract( ( ( p10_nodeVar401.x + p10_nodeVar401.y ) * p10_nodeVar401.z ) ) + fract( ( ( p10_nodeVar404.x + p10_nodeVar404.y ) * p10_nodeVar404.z ) ) ) - 1.0 ) * f32(knobs.grain) ) * 0.25 ) * mix( 1.0, p10_nodeVar11, f32(knobs.grainFollow) ) ) ) );
		

	}

	p10_nodeVar405 = vec4<f32>( clamp( p10_nodeVar398, vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), min( clamp( p10_nodeVar13.w, 0.0, 1.0 ), 1.0 ) );
	p10_nodeVar406 = vec3<f32>( p10_nodeVar405.x, p10_nodeVar405.y, p10_nodeVar405.z );
	p10_nodeVar407 = ( ( ( p10_nodeVar406.x * 0.2126 ) + ( p10_nodeVar406.y * 0.7152 ) ) + ( p10_nodeVar406.z * 0.0722 ) );
	p10_nodeVar408 = mix( vec3<f32>( p10_nodeVar407, p10_nodeVar407, p10_nodeVar407 ), p10_nodeVar406, f32(1.0) );
	p10_nodeVar409 = vec4<f32>( clamp( vec3<f32>( ( ( ( p10_nodeVar408.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p10_nodeVar408.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar408.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p10_nodeVar408.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p10_nodeVar408.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p10_nodeVar408.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p10_nodeVar408.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p10_nodeVar408.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p10_nodeVar408.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p10_nodeVar405.w, 0.0, 1.0 ) );
	p10_nodeVar411 = mix( clamp( p10_nodeVar0.w, 0.0, 1.0 ), clamp( p10_nodeVar409.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p10_nodeVar411 > 0.0 ) ) {

		p10_nodeVar410 = p10_nodeVar411;

	} else {

		p10_nodeVar410 = 1.0;

	}

	p10_DiffuseColor = vec4<f32>( ( mix( ( p10_nodeVar0.xyz * vec3<f32>( clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p10_nodeVar409.xyz, p10_nodeVar409.xyz, clamp( p10_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p10_nodeVar409.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p10_nodeVar410 ) ), p10_nodeVar411 );
	p10_DiffuseColor.w = ( p10_DiffuseColor.w * f32(1.0) );
	p10_nodeVar412 = max( vec4<f32>( p10_DiffuseColor.xyz, p10_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p10_Output = p10_nodeVar412;

	// result

	p10_output.color = p10_nodeVar412;

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

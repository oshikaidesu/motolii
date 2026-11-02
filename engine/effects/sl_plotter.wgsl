// Plotter: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Redraws the image as a pen plotter would: hatching, flow lines, contours, squiggles, a spiral or stipple.
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
// --pass@t10:0,0,s1.1042968750000002,s1.10859375
// --pass@:0,0,s1,s1
// --track@mode:Mode,0,5,0,1
// --track@angle:Angle,0,180,90,1
// --track@gap:Spacing,2,120,12,1
// --track@weight:Pen Width,0.25,12,1.5,0.05
// --track@pressure:Pressure,0,1,0.5,0.01
// --track@threshold:Threshold,0,1,0.5,0.01
// --track@smoothing:Smoothing,0,80,4,0.5
// --check@crosshatch:Crosshatch,1
// --track@crossAngle:Cross Angle,0,180,135,1
// --track@levels:Levels,1,60,8,1
// --track@amplitude:Amplitude,0,1,0.45,0.01
// --track@frequency:Frequency,0.05,2,0.5,0.01
// --track@wobble:Wobble,0,1,0.3,0.01
// --track@bleed:Ink Bleed,0,1,0.3,0.01
// --track@colorMode:Color,0,2,0,1
// --track@inkColor_x:Ink Color r,0,1,0.010329823026364548,0.001
// --track@inkColor_y:Ink Color g,0,1,0.010329823026364548,0.001
// --track@inkColor_z:Ink Color b,0,1,0.010329823026364548,0.001
// --track@pen2Color_x:Pen 2 r,0,1,0.6866853124288864,0.001
// --track@pen2Color_y:Pen 2 g,0,1,0.059511238155621766,0.001
// --track@pen2Color_z:Pen 2 b,0,1,0.028426039499072558,0.001
// --track@pen3Color_x:Pen 3 r,0,1,0.028426039499072558,0.001
// --track@pen3Color_y:Pen 3 g,0,1,0.11443537381770343,0.001
// --track@pen3Color_z:Pen 3 b,0,1,0.6866853124288864,0.001
// --check@paper:Paper,0
// --track@paperColor_x:Paper Color r,0,1,0.913098651791473,0.001
// --track@paperColor_y:Paper Color g,0,1,0.8713671191959567,0.001
// --track@paperColor_z:Paper Color b,0,1,0.8069522576650873,0.001
// --track@paperGrain:Paper Grain,0,1,0.2,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  mode: f32,
  angle: f32,
  gap: f32,
  weight: f32,
  pressure: f32,
  threshold: f32,
  smoothing: f32,
  crosshatch: f32,
  crossAngle: f32,
  levels: f32,
  amplitude: f32,
  frequency: f32,
  wobble: f32,
  bleed: f32,
  colorMode: f32,
  inkColor: vec3<f32>,
  pen2Color: vec3<f32>,
  pen3Color: vec3<f32>,
  paper: f32,
  paperColor: vec3<f32>,
  paperGrain: f32,
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
@group(0) @binding(22) var t10: texture_2d<f32>;
@group(0) @binding(23) var t10_sampler: sampler;
@group(0) @binding(24) var<uniform> knobs: Knobs;
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
var<private> p10_nodeVar0 : vec4<f32>;
var<private> p10_nodeVar1 : f32;
var<private> p10_nodeVar2 : f32;
var<private> p10_nodeVar3 : f32;
var<private> p10_nodeVar4 : vec2<f32>;
var<private> p10_nodeVar5 : vec2<f32>;
var<private> p10_nodeVar6 : vec4<f32>;
var<private> p10_nodeVar7 : vec2<f32>;
var<private> p10_nodeVar8 : vec2<f32>;
var<private> p10_nodeVar9 : vec2<f32>;
var<private> p10_nodeVar10 : vec2<f32>;
var<private> p10_nodeVar11 : vec2<f32>;
var<private> p10_nodeVar12 : vec2<f32>;
var<private> p10_nodeVar13 : vec2<f32>;
var<private> p10_nodeVar14 : vec4<f32>;
var<private> p10_nodeVar15 : vec2<f32>;
var<private> p10_nodeVar16 : vec2<f32>;
var<private> p10_nodeVar17 : vec2<f32>;
var<private> p10_nodeVar18 : vec4<f32>;
var<private> p10_nodeVar19 : vec4<f32>;
var<private> p10_nodeVar20 : vec4<f32>;
var<private> p10_nodeVar21 : vec2<f32>;
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
var<private> p10_nodeVar59 : vec2<f32>;
var<private> p10_nodeVar60 : vec4<f32>;
var<private> p10_nodeVar61 : vec2<f32>;
var<private> p10_nodeVar62 : vec2<f32>;
var<private> p10_nodeVar63 : vec2<f32>;
var<private> p10_nodeVar64 : vec4<f32>;
var<private> p10_nodeVar65 : vec4<f32>;
var<private> p10_nodeVar66 : vec4<f32>;
var<private> p10_nodeVar67 : vec2<f32>;
var<private> p10_nodeVar68 : vec2<f32>;
var<private> p10_nodeVar69 : vec2<f32>;
var<private> p10_nodeVar70 : vec2<f32>;
var<private> p10_nodeVar71 : vec2<f32>;
var<private> p10_nodeVar72 : vec2<f32>;
var<private> p10_nodeVar73 : vec2<f32>;
var<private> p10_nodeVar74 : vec4<f32>;
var<private> p10_nodeVar75 : vec2<f32>;
var<private> p10_nodeVar76 : vec2<f32>;
var<private> p10_nodeVar77 : vec2<f32>;
var<private> p10_nodeVar78 : vec4<f32>;
var<private> p10_nodeVar79 : vec4<f32>;
var<private> p10_nodeVar80 : vec4<f32>;
var<private> p10_nodeVar81 : vec2<f32>;
var<private> p10_nodeVar82 : vec2<f32>;
var<private> p10_nodeVar83 : vec2<f32>;
var<private> p10_nodeVar84 : vec2<f32>;
var<private> p10_nodeVar85 : vec2<f32>;
var<private> p10_nodeVar86 : vec2<f32>;
var<private> p10_nodeVar87 : vec2<f32>;
var<private> p10_nodeVar88 : vec2<f32>;
var<private> p10_nodeVar89 : vec2<f32>;
var<private> p10_nodeVar90 : vec4<f32>;
var<private> p10_nodeVar91 : vec2<f32>;
var<private> p10_nodeVar92 : vec2<f32>;
var<private> p10_nodeVar93 : vec2<f32>;
var<private> p10_nodeVar94 : vec4<f32>;
var<private> p10_nodeVar95 : vec4<f32>;
var<private> p10_nodeVar96 : vec4<f32>;
var<private> p10_nodeVar97 : vec2<f32>;
var<private> p10_nodeVar98 : vec2<f32>;
var<private> p10_nodeVar99 : vec2<f32>;
var<private> p10_nodeVar100 : vec2<f32>;
var<private> p10_nodeVar101 : vec2<f32>;
var<private> p10_nodeVar102 : vec2<f32>;
var<private> p10_nodeVar103 : vec2<f32>;
var<private> p10_nodeVar104 : vec4<f32>;
var<private> p10_nodeVar105 : vec2<f32>;
var<private> p10_nodeVar106 : vec2<f32>;
var<private> p10_nodeVar107 : vec2<f32>;
var<private> p10_nodeVar108 : vec4<f32>;
var<private> p10_nodeVar109 : vec4<f32>;
var<private> p10_nodeVar110 : vec4<f32>;
var<private> p10_nodeVar111 : vec2<f32>;
var<private> p10_nodeVar112 : vec2<f32>;
var<private> p10_nodeVar113 : vec2<f32>;
var<private> p10_nodeVar114 : vec2<f32>;
var<private> p10_nodeVar115 : vec2<f32>;
var<private> p10_nodeVar116 : vec2<f32>;
var<private> p10_nodeVar117 : vec2<f32>;
var<private> p10_nodeVar118 : vec2<f32>;
var<private> p10_nodeVar119 : vec2<f32>;
var<private> p10_nodeVar120 : vec4<f32>;
var<private> p10_nodeVar121 : vec2<f32>;
var<private> p10_nodeVar122 : vec2<f32>;
var<private> p10_nodeVar123 : vec2<f32>;
var<private> p10_nodeVar124 : vec4<f32>;
var<private> p10_nodeVar125 : vec4<f32>;
var<private> p10_nodeVar126 : vec4<f32>;
var<private> p10_nodeVar127 : vec2<f32>;
var<private> p10_nodeVar128 : vec2<f32>;
var<private> p10_nodeVar129 : vec2<f32>;
var<private> p10_nodeVar130 : vec2<f32>;
var<private> p10_nodeVar131 : vec2<f32>;
var<private> p10_nodeVar132 : vec2<f32>;
var<private> p10_nodeVar133 : vec2<f32>;
var<private> p10_nodeVar134 : vec4<f32>;
var<private> p10_nodeVar135 : vec2<f32>;
var<private> p10_nodeVar136 : vec2<f32>;
var<private> p10_nodeVar137 : vec2<f32>;
var<private> p10_nodeVar138 : vec4<f32>;
var<private> p10_nodeVar139 : vec4<f32>;
var<private> p10_nodeVar140 : vec4<f32>;
var<private> p10_nodeVar141 : vec2<f32>;
var<private> p10_nodeVar142 : vec2<f32>;
var<private> p10_nodeVar143 : vec2<f32>;
var<private> p10_nodeVar144 : vec2<f32>;
var<private> p10_nodeVar145 : vec2<f32>;
var<private> p10_nodeVar146 : vec2<f32>;
var<private> p10_nodeVar147 : vec2<f32>;
var<private> p10_nodeVar148 : vec2<f32>;
var<private> p10_nodeVar149 : vec2<f32>;
var<private> p10_nodeVar150 : vec4<f32>;
var<private> p10_nodeVar151 : vec2<f32>;
var<private> p10_nodeVar152 : vec2<f32>;
var<private> p10_nodeVar153 : vec2<f32>;
var<private> p10_nodeVar154 : vec4<f32>;
var<private> p10_nodeVar155 : vec4<f32>;
var<private> p10_nodeVar156 : vec4<f32>;
var<private> p10_nodeVar157 : vec2<f32>;
var<private> p10_nodeVar158 : vec2<f32>;
var<private> p10_nodeVar159 : vec2<f32>;
var<private> p10_nodeVar160 : vec2<f32>;
var<private> p10_nodeVar161 : vec2<f32>;
var<private> p10_nodeVar162 : vec2<f32>;
var<private> p10_nodeVar163 : vec2<f32>;
var<private> p10_nodeVar164 : vec4<f32>;
var<private> p10_nodeVar165 : vec2<f32>;
var<private> p10_nodeVar166 : vec2<f32>;
var<private> p10_nodeVar167 : vec2<f32>;
var<private> p10_nodeVar168 : vec4<f32>;
var<private> p10_nodeVar169 : vec4<f32>;
var<private> p10_nodeVar170 : vec4<f32>;
var<private> p10_nodeVar171 : vec2<f32>;
var<private> p10_nodeVar172 : vec2<f32>;
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
var<private> p10_nodeVar208 : vec2<f32>;
var<private> p10_nodeVar209 : vec2<f32>;
var<private> p10_nodeVar210 : vec4<f32>;
var<private> p10_nodeVar211 : vec2<f32>;
var<private> p10_nodeVar212 : vec2<f32>;
var<private> p10_nodeVar213 : vec2<f32>;
var<private> p10_nodeVar214 : vec4<f32>;
var<private> p10_nodeVar215 : vec4<f32>;
var<private> p10_nodeVar216 : vec4<f32>;
var<private> p10_nodeVar217 : vec2<f32>;
var<private> p10_nodeVar218 : vec2<f32>;
var<private> p10_nodeVar219 : vec2<f32>;
var<private> p10_nodeVar220 : vec2<f32>;
var<private> p10_nodeVar221 : vec2<f32>;
var<private> p10_nodeVar222 : vec2<f32>;
var<private> p10_nodeVar223 : vec2<f32>;
var<private> p10_nodeVar224 : vec4<f32>;
var<private> p10_nodeVar225 : vec2<f32>;
var<private> p10_nodeVar226 : vec2<f32>;
var<private> p10_nodeVar227 : vec2<f32>;
var<private> p10_nodeVar228 : vec4<f32>;
var<private> p10_nodeVar229 : vec4<f32>;
var<private> p10_nodeVar230 : vec4<f32>;
var<private> p10_nodeVar231 : vec2<f32>;
var<private> p10_nodeVar232 : vec2<f32>;
var<private> p10_nodeVar233 : vec2<f32>;
var<private> p10_nodeVar234 : vec2<f32>;
var<private> p10_nodeVar235 : vec2<f32>;
var<private> p10_nodeVar236 : vec2<f32>;
var<private> p10_nodeVar237 : vec2<f32>;
var<private> p10_nodeVar238 : vec2<f32>;
var<private> p10_nodeVar239 : vec2<f32>;
var<private> p10_nodeVar240 : vec4<f32>;
var<private> p10_nodeVar241 : vec2<f32>;
var<private> p10_nodeVar242 : vec2<f32>;
var<private> p10_nodeVar243 : vec2<f32>;
var<private> p10_nodeVar244 : vec4<f32>;
var<private> p10_nodeVar245 : vec4<f32>;
var<private> p10_nodeVar246 : vec4<f32>;
var<private> p10_nodeVar247 : vec2<f32>;
var<private> p10_nodeVar248 : vec2<f32>;
var<private> p10_nodeVar249 : vec2<f32>;
var<private> p10_nodeVar250 : vec2<f32>;
var<private> p10_nodeVar251 : vec2<f32>;
var<private> p10_nodeVar252 : vec2<f32>;
var<private> p10_nodeVar253 : vec2<f32>;
var<private> p10_nodeVar254 : vec4<f32>;
var<private> p10_nodeVar255 : vec2<f32>;
var<private> p10_nodeVar256 : vec2<f32>;
var<private> p10_nodeVar257 : vec2<f32>;
var<private> p10_nodeVar258 : vec4<f32>;
var<private> p10_nodeVar259 : vec4<f32>;
var<private> p10_nodeVar260 : vec4<f32>;
var<private> p10_nodeVar261 : vec2<f32>;
var<private> p10_nodeVar262 : vec2<f32>;
var<private> p10_nodeVar263 : vec2<f32>;
var<private> p10_nodeVar264 : vec2<f32>;
var<private> p10_nodeVar265 : vec2<f32>;
var<private> p10_nodeVar266 : vec2<f32>;
var<private> p10_nodeVar267 : vec2<f32>;
var<private> p10_nodeVar268 : vec2<f32>;
var<private> p10_nodeVar269 : vec2<f32>;
var<private> p10_nodeVar270 : vec4<f32>;
var<private> p10_nodeVar271 : vec2<f32>;
var<private> p10_nodeVar272 : vec2<f32>;
var<private> p10_nodeVar273 : vec2<f32>;
var<private> p10_nodeVar274 : vec4<f32>;
var<private> p10_nodeVar275 : vec4<f32>;
var<private> p10_nodeVar276 : vec4<f32>;
var<private> p10_nodeVar277 : vec2<f32>;
var<private> p10_nodeVar278 : vec2<f32>;
var<private> p10_nodeVar279 : vec2<f32>;
var<private> p10_nodeVar280 : vec2<f32>;
var<private> p10_nodeVar281 : vec2<f32>;
var<private> p10_nodeVar282 : vec2<f32>;
var<private> p10_nodeVar283 : vec2<f32>;
var<private> p10_nodeVar284 : vec4<f32>;
var<private> p10_nodeVar285 : vec2<f32>;
var<private> p10_nodeVar286 : vec2<f32>;
var<private> p10_nodeVar287 : vec2<f32>;
var<private> p10_nodeVar288 : vec4<f32>;
var<private> p10_nodeVar289 : vec4<f32>;
var<private> p10_nodeVar290 : vec4<f32>;
var<private> p10_nodeVar291 : vec2<f32>;
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
var<private> p10_nodeVar306 : f32;
var<private> p10_nodeVar307 : vec2<f32>;
var<private> p10_nodeVar308 : vec3<f32>;
var<private> p10_nodeVar309 : vec3<f32>;
var<private> p10_nodeVar310 : f32;
var<private> p10_nodeVar311 : vec4<f32>;
var<private> p10_nodeVar312 : f32;

// codes


fn p10_main(door_uv: vec2f) -> p10_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p10_nodeVar0 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
	p10_nodeVar1 = clamp( log2( max( ( ( f32(knobs.smoothing) * f32(1.0) ) / 1.2 ), 1.0 ) ), 0.0, 10.0 );
	p10_nodeVar2 = floor( p10_nodeVar1 );
	p10_nodeVar3 = ( p10_nodeVar1 - p10_nodeVar2 );

	if ( ( p10_nodeVar2 == 0.0 ) ) {

		p10_nodeVar4 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar5 = ( ( ( p10_nodeVar4 + fract( ( sin( vec2<f32>( dot( p10_nodeVar4, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar4, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar6 = picture_read_level( p10_nodeVar5, 0.0 );
		p10_nodeVar0 = vec4<f32>( ( vec3<f32>( p10_nodeVar6.x, p10_nodeVar6.y, p10_nodeVar6.z ) * vec3<f32>( p10_nodeVar6.w ) ), p10_nodeVar6.w );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar7 = ( ( p10_nodeVar5 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar8 = floor( p10_nodeVar7 );
			p10_nodeVar9 = ( p10_nodeVar7 - p10_nodeVar8 );
			p10_nodeVar10 = ( p10_nodeVar9 * p10_nodeVar9 );
			p10_nodeVar11 = ( p10_nodeVar10 * p10_nodeVar9 );
			p10_nodeVar12 = ( ( ( ( p10_nodeVar11 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar10 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar13 = ( ( ( p10_nodeVar8 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar12 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar9 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar9 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar9 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar12 ) ) ) * vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar14 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar13.x, p10_nodeVar13.y ), 0.0 );
			p10_nodeVar15 = ( p10_nodeVar11 / vec2<f32>( 6.0 ) );
			p10_nodeVar16 = ( ( ( ( ( ( p10_nodeVar11 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar10 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar9 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar15 );
			p10_nodeVar17 = ( ( ( p10_nodeVar8 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar15 / p10_nodeVar16 ) ) * vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar18 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar17.x, p10_nodeVar13.y ), 0.0 );
			p10_nodeVar19 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar13.x, p10_nodeVar17.y ), 0.0 );
			p10_nodeVar20 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar17.x, p10_nodeVar17.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar14, p10_nodeVar18, p10_nodeVar16.x ), mix( p10_nodeVar19, p10_nodeVar20, p10_nodeVar16.x ), p10_nodeVar16.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 1.0 ) ) {

		p10_nodeVar21 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar22 = ( ( ( p10_nodeVar21 + fract( ( sin( vec2<f32>( dot( p10_nodeVar21, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar21, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar23 = ( ( p10_nodeVar22 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar24 = floor( p10_nodeVar23 );
		p10_nodeVar25 = ( p10_nodeVar23 - p10_nodeVar24 );
		p10_nodeVar26 = ( p10_nodeVar25 * p10_nodeVar25 );
		p10_nodeVar27 = ( p10_nodeVar26 * p10_nodeVar25 );
		p10_nodeVar28 = ( ( ( ( p10_nodeVar27 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar26 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar29 = ( ( ( p10_nodeVar24 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar28 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar25 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar28 ) ) ) * vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar30 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar29.y ), 0.0 );
		p10_nodeVar31 = ( p10_nodeVar27 / vec2<f32>( 6.0 ) );
		p10_nodeVar32 = ( ( ( ( ( ( p10_nodeVar27 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar26 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar25 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar31 );
		p10_nodeVar33 = ( ( ( p10_nodeVar24 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar31 / p10_nodeVar32 ) ) * vec2<f32>((2 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (2 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar34 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar33.x, p10_nodeVar29.y ), 0.0 );
		p10_nodeVar35 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar29.x, p10_nodeVar33.y ), 0.0 );
		p10_nodeVar36 = target_read_level( t0, t0_sampler, vec2<f32>( p10_nodeVar33.x, p10_nodeVar33.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar30, p10_nodeVar34, p10_nodeVar32.x ), mix( p10_nodeVar35, p10_nodeVar36, p10_nodeVar32.x ), p10_nodeVar32.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar37 = ( ( p10_nodeVar22 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar38 = floor( p10_nodeVar37 );
			p10_nodeVar39 = ( p10_nodeVar37 - p10_nodeVar38 );
			p10_nodeVar40 = ( p10_nodeVar39 * p10_nodeVar39 );
			p10_nodeVar41 = ( p10_nodeVar40 * p10_nodeVar39 );
			p10_nodeVar42 = ( ( ( ( p10_nodeVar41 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar40 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar43 = ( ( ( p10_nodeVar38 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar42 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar39 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar42 ) ) ) * vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar44 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar45 = ( p10_nodeVar41 / vec2<f32>( 6.0 ) );
			p10_nodeVar46 = ( ( ( ( ( ( p10_nodeVar41 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar40 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar39 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar45 );
			p10_nodeVar47 = ( ( ( p10_nodeVar38 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar45 / p10_nodeVar46 ) ) * vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar48 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar47.x, p10_nodeVar43.y ), 0.0 );
			p10_nodeVar49 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar43.x, p10_nodeVar47.y ), 0.0 );
			p10_nodeVar50 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar47.x, p10_nodeVar47.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar44, p10_nodeVar48, p10_nodeVar46.x ), mix( p10_nodeVar49, p10_nodeVar50, p10_nodeVar46.x ), p10_nodeVar46.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 2.0 ) ) {

		p10_nodeVar51 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar52 = ( ( ( p10_nodeVar51 + fract( ( sin( vec2<f32>( dot( p10_nodeVar51, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar51, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar53 = ( ( p10_nodeVar52 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar54 = floor( p10_nodeVar53 );
		p10_nodeVar55 = ( p10_nodeVar53 - p10_nodeVar54 );
		p10_nodeVar56 = ( p10_nodeVar55 * p10_nodeVar55 );
		p10_nodeVar57 = ( p10_nodeVar56 * p10_nodeVar55 );
		p10_nodeVar58 = ( ( ( ( p10_nodeVar57 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar56 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar59 = ( ( ( p10_nodeVar54 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar58 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar55 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar55 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar55 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar58 ) ) ) * vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar60 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar59.x, p10_nodeVar59.y ), 0.0 );
		p10_nodeVar61 = ( p10_nodeVar57 / vec2<f32>( 6.0 ) );
		p10_nodeVar62 = ( ( ( ( ( ( p10_nodeVar57 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar56 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar55 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar61 );
		p10_nodeVar63 = ( ( ( p10_nodeVar54 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar61 / p10_nodeVar62 ) ) * vec2<f32>((4 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (4 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar64 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar63.x, p10_nodeVar59.y ), 0.0 );
		p10_nodeVar65 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar59.x, p10_nodeVar63.y ), 0.0 );
		p10_nodeVar66 = target_read_level( t1, t1_sampler, vec2<f32>( p10_nodeVar63.x, p10_nodeVar63.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar60, p10_nodeVar64, p10_nodeVar62.x ), mix( p10_nodeVar65, p10_nodeVar66, p10_nodeVar62.x ), p10_nodeVar62.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar67 = ( ( p10_nodeVar52 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar68 = floor( p10_nodeVar67 );
			p10_nodeVar69 = ( p10_nodeVar67 - p10_nodeVar68 );
			p10_nodeVar70 = ( p10_nodeVar69 * p10_nodeVar69 );
			p10_nodeVar71 = ( p10_nodeVar70 * p10_nodeVar69 );
			p10_nodeVar72 = ( ( ( ( p10_nodeVar71 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar70 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar73 = ( ( ( p10_nodeVar68 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar72 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar69 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar69 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar69 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar72 ) ) ) * vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar74 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar73.x, p10_nodeVar73.y ), 0.0 );
			p10_nodeVar75 = ( p10_nodeVar71 / vec2<f32>( 6.0 ) );
			p10_nodeVar76 = ( ( ( ( ( ( p10_nodeVar71 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar70 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar69 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar75 );
			p10_nodeVar77 = ( ( ( p10_nodeVar68 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar75 / p10_nodeVar76 ) ) * vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar78 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar77.x, p10_nodeVar73.y ), 0.0 );
			p10_nodeVar79 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar73.x, p10_nodeVar77.y ), 0.0 );
			p10_nodeVar80 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar77.x, p10_nodeVar77.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar74, p10_nodeVar78, p10_nodeVar76.x ), mix( p10_nodeVar79, p10_nodeVar80, p10_nodeVar76.x ), p10_nodeVar76.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 3.0 ) ) {

		p10_nodeVar81 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar82 = ( ( ( p10_nodeVar81 + fract( ( sin( vec2<f32>( dot( p10_nodeVar81, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar81, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar83 = ( ( p10_nodeVar82 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar84 = floor( p10_nodeVar83 );
		p10_nodeVar85 = ( p10_nodeVar83 - p10_nodeVar84 );
		p10_nodeVar86 = ( p10_nodeVar85 * p10_nodeVar85 );
		p10_nodeVar87 = ( p10_nodeVar86 * p10_nodeVar85 );
		p10_nodeVar88 = ( ( ( ( p10_nodeVar87 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar86 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar89 = ( ( ( p10_nodeVar84 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar88 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar85 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar85 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar85 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar88 ) ) ) * vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar90 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar89.x, p10_nodeVar89.y ), 0.0 );
		p10_nodeVar91 = ( p10_nodeVar87 / vec2<f32>( 6.0 ) );
		p10_nodeVar92 = ( ( ( ( ( ( p10_nodeVar87 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar86 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar85 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar91 );
		p10_nodeVar93 = ( ( ( p10_nodeVar84 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar91 / p10_nodeVar92 ) ) * vec2<f32>((8 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (8 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar94 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar93.x, p10_nodeVar89.y ), 0.0 );
		p10_nodeVar95 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar89.x, p10_nodeVar93.y ), 0.0 );
		p10_nodeVar96 = target_read_level( t2, t2_sampler, vec2<f32>( p10_nodeVar93.x, p10_nodeVar93.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar90, p10_nodeVar94, p10_nodeVar92.x ), mix( p10_nodeVar95, p10_nodeVar96, p10_nodeVar92.x ), p10_nodeVar92.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar97 = ( ( p10_nodeVar82 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar98 = floor( p10_nodeVar97 );
			p10_nodeVar99 = ( p10_nodeVar97 - p10_nodeVar98 );
			p10_nodeVar100 = ( p10_nodeVar99 * p10_nodeVar99 );
			p10_nodeVar101 = ( p10_nodeVar100 * p10_nodeVar99 );
			p10_nodeVar102 = ( ( ( ( p10_nodeVar101 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar100 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar103 = ( ( ( p10_nodeVar98 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar102 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar99 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar99 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar99 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar102 ) ) ) * vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar104 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar103.x, p10_nodeVar103.y ), 0.0 );
			p10_nodeVar105 = ( p10_nodeVar101 / vec2<f32>( 6.0 ) );
			p10_nodeVar106 = ( ( ( ( ( ( p10_nodeVar101 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar100 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar99 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar105 );
			p10_nodeVar107 = ( ( ( p10_nodeVar98 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar105 / p10_nodeVar106 ) ) * vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar108 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar107.x, p10_nodeVar103.y ), 0.0 );
			p10_nodeVar109 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar103.x, p10_nodeVar107.y ), 0.0 );
			p10_nodeVar110 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar107.x, p10_nodeVar107.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar104, p10_nodeVar108, p10_nodeVar106.x ), mix( p10_nodeVar109, p10_nodeVar110, p10_nodeVar106.x ), p10_nodeVar106.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 4.0 ) ) {

		p10_nodeVar111 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar112 = ( ( ( p10_nodeVar111 + fract( ( sin( vec2<f32>( dot( p10_nodeVar111, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar111, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar113 = ( ( p10_nodeVar112 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar114 = floor( p10_nodeVar113 );
		p10_nodeVar115 = ( p10_nodeVar113 - p10_nodeVar114 );
		p10_nodeVar116 = ( p10_nodeVar115 * p10_nodeVar115 );
		p10_nodeVar117 = ( p10_nodeVar116 * p10_nodeVar115 );
		p10_nodeVar118 = ( ( ( ( p10_nodeVar117 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar116 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar119 = ( ( ( p10_nodeVar114 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar118 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar115 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar115 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar115 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar118 ) ) ) * vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar120 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar119.x, p10_nodeVar119.y ), 0.0 );
		p10_nodeVar121 = ( p10_nodeVar117 / vec2<f32>( 6.0 ) );
		p10_nodeVar122 = ( ( ( ( ( ( p10_nodeVar117 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar116 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar115 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar121 );
		p10_nodeVar123 = ( ( ( p10_nodeVar114 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar121 / p10_nodeVar122 ) ) * vec2<f32>((16 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (16 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar124 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar123.x, p10_nodeVar119.y ), 0.0 );
		p10_nodeVar125 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar119.x, p10_nodeVar123.y ), 0.0 );
		p10_nodeVar126 = target_read_level( t3, t3_sampler, vec2<f32>( p10_nodeVar123.x, p10_nodeVar123.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar120, p10_nodeVar124, p10_nodeVar122.x ), mix( p10_nodeVar125, p10_nodeVar126, p10_nodeVar122.x ), p10_nodeVar122.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar127 = ( ( p10_nodeVar112 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar128 = floor( p10_nodeVar127 );
			p10_nodeVar129 = ( p10_nodeVar127 - p10_nodeVar128 );
			p10_nodeVar130 = ( p10_nodeVar129 * p10_nodeVar129 );
			p10_nodeVar131 = ( p10_nodeVar130 * p10_nodeVar129 );
			p10_nodeVar132 = ( ( ( ( p10_nodeVar131 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar130 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar133 = ( ( ( p10_nodeVar128 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar132 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar129 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar129 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar129 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar132 ) ) ) * vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar134 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar133.x, p10_nodeVar133.y ), 0.0 );
			p10_nodeVar135 = ( p10_nodeVar131 / vec2<f32>( 6.0 ) );
			p10_nodeVar136 = ( ( ( ( ( ( p10_nodeVar131 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar130 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar129 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar135 );
			p10_nodeVar137 = ( ( ( p10_nodeVar128 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar135 / p10_nodeVar136 ) ) * vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar138 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar137.x, p10_nodeVar133.y ), 0.0 );
			p10_nodeVar139 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar133.x, p10_nodeVar137.y ), 0.0 );
			p10_nodeVar140 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar137.x, p10_nodeVar137.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar134, p10_nodeVar138, p10_nodeVar136.x ), mix( p10_nodeVar139, p10_nodeVar140, p10_nodeVar136.x ), p10_nodeVar136.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 5.0 ) ) {

		p10_nodeVar141 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar142 = ( ( ( p10_nodeVar141 + fract( ( sin( vec2<f32>( dot( p10_nodeVar141, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar141, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar143 = ( ( p10_nodeVar142 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar144 = floor( p10_nodeVar143 );
		p10_nodeVar145 = ( p10_nodeVar143 - p10_nodeVar144 );
		p10_nodeVar146 = ( p10_nodeVar145 * p10_nodeVar145 );
		p10_nodeVar147 = ( p10_nodeVar146 * p10_nodeVar145 );
		p10_nodeVar148 = ( ( ( ( p10_nodeVar147 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar146 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar149 = ( ( ( p10_nodeVar144 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar148 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar145 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar145 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar145 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar148 ) ) ) * vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar150 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar149.x, p10_nodeVar149.y ), 0.0 );
		p10_nodeVar151 = ( p10_nodeVar147 / vec2<f32>( 6.0 ) );
		p10_nodeVar152 = ( ( ( ( ( ( p10_nodeVar147 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar146 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar145 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar151 );
		p10_nodeVar153 = ( ( ( p10_nodeVar144 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar151 / p10_nodeVar152 ) ) * vec2<f32>((32 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (32 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar154 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar153.x, p10_nodeVar149.y ), 0.0 );
		p10_nodeVar155 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar149.x, p10_nodeVar153.y ), 0.0 );
		p10_nodeVar156 = target_read_level( t4, t4_sampler, vec2<f32>( p10_nodeVar153.x, p10_nodeVar153.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar150, p10_nodeVar154, p10_nodeVar152.x ), mix( p10_nodeVar155, p10_nodeVar156, p10_nodeVar152.x ), p10_nodeVar152.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar157 = ( ( p10_nodeVar142 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar158 = floor( p10_nodeVar157 );
			p10_nodeVar159 = ( p10_nodeVar157 - p10_nodeVar158 );
			p10_nodeVar160 = ( p10_nodeVar159 * p10_nodeVar159 );
			p10_nodeVar161 = ( p10_nodeVar160 * p10_nodeVar159 );
			p10_nodeVar162 = ( ( ( ( p10_nodeVar161 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar160 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar163 = ( ( ( p10_nodeVar158 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar162 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar159 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar159 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar159 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar162 ) ) ) * vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar164 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar163.x, p10_nodeVar163.y ), 0.0 );
			p10_nodeVar165 = ( p10_nodeVar161 / vec2<f32>( 6.0 ) );
			p10_nodeVar166 = ( ( ( ( ( ( p10_nodeVar161 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar160 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar159 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar165 );
			p10_nodeVar167 = ( ( ( p10_nodeVar158 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar165 / p10_nodeVar166 ) ) * vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar168 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar167.x, p10_nodeVar163.y ), 0.0 );
			p10_nodeVar169 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar163.x, p10_nodeVar167.y ), 0.0 );
			p10_nodeVar170 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar167.x, p10_nodeVar167.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar164, p10_nodeVar168, p10_nodeVar166.x ), mix( p10_nodeVar169, p10_nodeVar170, p10_nodeVar166.x ), p10_nodeVar166.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 6.0 ) ) {

		p10_nodeVar171 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar172 = ( ( ( p10_nodeVar171 + fract( ( sin( vec2<f32>( dot( p10_nodeVar171, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar171, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar173 = ( ( p10_nodeVar172 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar174 = floor( p10_nodeVar173 );
		p10_nodeVar175 = ( p10_nodeVar173 - p10_nodeVar174 );
		p10_nodeVar176 = ( p10_nodeVar175 * p10_nodeVar175 );
		p10_nodeVar177 = ( p10_nodeVar176 * p10_nodeVar175 );
		p10_nodeVar178 = ( ( ( ( p10_nodeVar177 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar176 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar179 = ( ( ( p10_nodeVar174 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar178 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar175 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar178 ) ) ) * vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar180 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar179.x, p10_nodeVar179.y ), 0.0 );
		p10_nodeVar181 = ( p10_nodeVar177 / vec2<f32>( 6.0 ) );
		p10_nodeVar182 = ( ( ( ( ( ( p10_nodeVar177 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar176 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar175 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar181 );
		p10_nodeVar183 = ( ( ( p10_nodeVar174 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar181 / p10_nodeVar182 ) ) * vec2<f32>((64 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (64 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar184 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar183.x, p10_nodeVar179.y ), 0.0 );
		p10_nodeVar185 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar179.x, p10_nodeVar183.y ), 0.0 );
		p10_nodeVar186 = target_read_level( t5, t5_sampler, vec2<f32>( p10_nodeVar183.x, p10_nodeVar183.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar180, p10_nodeVar184, p10_nodeVar182.x ), mix( p10_nodeVar185, p10_nodeVar186, p10_nodeVar182.x ), p10_nodeVar182.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar187 = ( ( p10_nodeVar172 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar188 = floor( p10_nodeVar187 );
			p10_nodeVar189 = ( p10_nodeVar187 - p10_nodeVar188 );
			p10_nodeVar190 = ( p10_nodeVar189 * p10_nodeVar189 );
			p10_nodeVar191 = ( p10_nodeVar190 * p10_nodeVar189 );
			p10_nodeVar192 = ( ( ( ( p10_nodeVar191 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar190 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar193 = ( ( ( p10_nodeVar188 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar192 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar189 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar192 ) ) ) * vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar194 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar193.x, p10_nodeVar193.y ), 0.0 );
			p10_nodeVar195 = ( p10_nodeVar191 / vec2<f32>( 6.0 ) );
			p10_nodeVar196 = ( ( ( ( ( ( p10_nodeVar191 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar190 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar189 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar195 );
			p10_nodeVar197 = ( ( ( p10_nodeVar188 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar195 / p10_nodeVar196 ) ) * vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar198 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar197.x, p10_nodeVar193.y ), 0.0 );
			p10_nodeVar199 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar193.x, p10_nodeVar197.y ), 0.0 );
			p10_nodeVar200 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar197.x, p10_nodeVar197.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar194, p10_nodeVar198, p10_nodeVar196.x ), mix( p10_nodeVar199, p10_nodeVar200, p10_nodeVar196.x ), p10_nodeVar196.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 7.0 ) ) {

		p10_nodeVar201 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar202 = ( ( ( p10_nodeVar201 + fract( ( sin( vec2<f32>( dot( p10_nodeVar201, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar201, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar203 = ( ( p10_nodeVar202 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar204 = floor( p10_nodeVar203 );
		p10_nodeVar205 = ( p10_nodeVar203 - p10_nodeVar204 );
		p10_nodeVar206 = ( p10_nodeVar205 * p10_nodeVar205 );
		p10_nodeVar207 = ( p10_nodeVar206 * p10_nodeVar205 );
		p10_nodeVar208 = ( ( ( ( p10_nodeVar207 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar206 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar209 = ( ( ( p10_nodeVar204 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar208 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar205 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar205 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar205 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar208 ) ) ) * vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar210 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar209.x, p10_nodeVar209.y ), 0.0 );
		p10_nodeVar211 = ( p10_nodeVar207 / vec2<f32>( 6.0 ) );
		p10_nodeVar212 = ( ( ( ( ( ( p10_nodeVar207 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar206 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar205 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar211 );
		p10_nodeVar213 = ( ( ( p10_nodeVar204 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar211 / p10_nodeVar212 ) ) * vec2<f32>((128 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (128 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar214 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar213.x, p10_nodeVar209.y ), 0.0 );
		p10_nodeVar215 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar209.x, p10_nodeVar213.y ), 0.0 );
		p10_nodeVar216 = target_read_level( t6, t6_sampler, vec2<f32>( p10_nodeVar213.x, p10_nodeVar213.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar210, p10_nodeVar214, p10_nodeVar212.x ), mix( p10_nodeVar215, p10_nodeVar216, p10_nodeVar212.x ), p10_nodeVar212.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar217 = ( ( p10_nodeVar202 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar218 = floor( p10_nodeVar217 );
			p10_nodeVar219 = ( p10_nodeVar217 - p10_nodeVar218 );
			p10_nodeVar220 = ( p10_nodeVar219 * p10_nodeVar219 );
			p10_nodeVar221 = ( p10_nodeVar220 * p10_nodeVar219 );
			p10_nodeVar222 = ( ( ( ( p10_nodeVar221 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar220 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar223 = ( ( ( p10_nodeVar218 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar222 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar219 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar219 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar219 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar222 ) ) ) * vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar224 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar223.x, p10_nodeVar223.y ), 0.0 );
			p10_nodeVar225 = ( p10_nodeVar221 / vec2<f32>( 6.0 ) );
			p10_nodeVar226 = ( ( ( ( ( ( p10_nodeVar221 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar220 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar219 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar225 );
			p10_nodeVar227 = ( ( ( p10_nodeVar218 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar225 / p10_nodeVar226 ) ) * vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar228 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar227.x, p10_nodeVar223.y ), 0.0 );
			p10_nodeVar229 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar223.x, p10_nodeVar227.y ), 0.0 );
			p10_nodeVar230 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar227.x, p10_nodeVar227.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar224, p10_nodeVar228, p10_nodeVar226.x ), mix( p10_nodeVar229, p10_nodeVar230, p10_nodeVar226.x ), p10_nodeVar226.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 8.0 ) ) {

		p10_nodeVar231 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar232 = ( ( ( p10_nodeVar231 + fract( ( sin( vec2<f32>( dot( p10_nodeVar231, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar231, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar233 = ( ( p10_nodeVar232 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar234 = floor( p10_nodeVar233 );
		p10_nodeVar235 = ( p10_nodeVar233 - p10_nodeVar234 );
		p10_nodeVar236 = ( p10_nodeVar235 * p10_nodeVar235 );
		p10_nodeVar237 = ( p10_nodeVar236 * p10_nodeVar235 );
		p10_nodeVar238 = ( ( ( ( p10_nodeVar237 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar236 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar239 = ( ( ( p10_nodeVar234 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar238 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar235 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar235 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar235 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar238 ) ) ) * vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar240 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar239.x, p10_nodeVar239.y ), 0.0 );
		p10_nodeVar241 = ( p10_nodeVar237 / vec2<f32>( 6.0 ) );
		p10_nodeVar242 = ( ( ( ( ( ( p10_nodeVar237 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar236 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar235 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar241 );
		p10_nodeVar243 = ( ( ( p10_nodeVar234 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar241 / p10_nodeVar242 ) ) * vec2<f32>((256 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (256 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar244 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar243.x, p10_nodeVar239.y ), 0.0 );
		p10_nodeVar245 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar239.x, p10_nodeVar243.y ), 0.0 );
		p10_nodeVar246 = target_read_level( t7, t7_sampler, vec2<f32>( p10_nodeVar243.x, p10_nodeVar243.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar240, p10_nodeVar244, p10_nodeVar242.x ), mix( p10_nodeVar245, p10_nodeVar246, p10_nodeVar242.x ), p10_nodeVar242.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar247 = ( ( p10_nodeVar232 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar248 = floor( p10_nodeVar247 );
			p10_nodeVar249 = ( p10_nodeVar247 - p10_nodeVar248 );
			p10_nodeVar250 = ( p10_nodeVar249 * p10_nodeVar249 );
			p10_nodeVar251 = ( p10_nodeVar250 * p10_nodeVar249 );
			p10_nodeVar252 = ( ( ( ( p10_nodeVar251 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar250 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar253 = ( ( ( p10_nodeVar248 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar252 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar249 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar249 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar249 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar252 ) ) ) * vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar254 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar253.x, p10_nodeVar253.y ), 0.0 );
			p10_nodeVar255 = ( p10_nodeVar251 / vec2<f32>( 6.0 ) );
			p10_nodeVar256 = ( ( ( ( ( ( p10_nodeVar251 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar250 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar249 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar255 );
			p10_nodeVar257 = ( ( ( p10_nodeVar248 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar255 / p10_nodeVar256 ) ) * vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
			p10_nodeVar258 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar257.x, p10_nodeVar253.y ), 0.0 );
			p10_nodeVar259 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar253.x, p10_nodeVar257.y ), 0.0 );
			p10_nodeVar260 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar257.x, p10_nodeVar257.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar254, p10_nodeVar258, p10_nodeVar256.x ), mix( p10_nodeVar259, p10_nodeVar260, p10_nodeVar256.x ), p10_nodeVar256.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 == 9.0 ) ) {

		p10_nodeVar261 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar262 = ( ( ( p10_nodeVar261 + fract( ( sin( vec2<f32>( dot( p10_nodeVar261, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar261, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) );
		p10_nodeVar263 = ( ( p10_nodeVar262 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar264 = floor( p10_nodeVar263 );
		p10_nodeVar265 = ( p10_nodeVar263 - p10_nodeVar264 );
		p10_nodeVar266 = ( p10_nodeVar265 * p10_nodeVar265 );
		p10_nodeVar267 = ( p10_nodeVar266 * p10_nodeVar265 );
		p10_nodeVar268 = ( ( ( ( p10_nodeVar267 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar266 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar269 = ( ( ( p10_nodeVar264 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar268 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar265 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar265 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar265 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar268 ) ) ) * vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar270 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar269.x, p10_nodeVar269.y ), 0.0 );
		p10_nodeVar271 = ( p10_nodeVar267 / vec2<f32>( 6.0 ) );
		p10_nodeVar272 = ( ( ( ( ( ( p10_nodeVar267 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar266 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar265 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar271 );
		p10_nodeVar273 = ( ( ( p10_nodeVar264 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar271 / p10_nodeVar272 ) ) * vec2<f32>((512 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), (512 * (1.0 / (knobs.resolution.y / 1.10859375)) + 0)) );
		p10_nodeVar274 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar273.x, p10_nodeVar269.y ), 0.0 );
		p10_nodeVar275 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar269.x, p10_nodeVar273.y ), 0.0 );
		p10_nodeVar276 = target_read_level( t8, t8_sampler, vec2<f32>( p10_nodeVar273.x, p10_nodeVar273.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar270, p10_nodeVar274, p10_nodeVar272.x ), mix( p10_nodeVar275, p10_nodeVar276, p10_nodeVar272.x ), p10_nodeVar272.y );

		if ( ( p10_nodeVar3 > 0.0 ) ) {

			p10_nodeVar277 = ( ( p10_nodeVar262 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p10_nodeVar278 = floor( p10_nodeVar277 );
			p10_nodeVar279 = ( p10_nodeVar277 - p10_nodeVar278 );
			p10_nodeVar280 = ( p10_nodeVar279 * p10_nodeVar279 );
			p10_nodeVar281 = ( p10_nodeVar280 * p10_nodeVar279 );
			p10_nodeVar282 = ( ( ( ( p10_nodeVar281 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar280 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p10_nodeVar283 = ( ( ( p10_nodeVar278 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar282 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar279 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar279 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar279 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar282 ) ) ) * vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0) );
			p10_nodeVar284 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar283.x, p10_nodeVar283.y ), 0.0 );
			p10_nodeVar285 = ( p10_nodeVar281 / vec2<f32>( 6.0 ) );
			p10_nodeVar286 = ( ( ( ( ( ( p10_nodeVar281 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar280 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar279 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar285 );
			p10_nodeVar287 = ( ( ( p10_nodeVar278 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar285 / p10_nodeVar286 ) ) * vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0) );
			p10_nodeVar288 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar287.x, p10_nodeVar283.y ), 0.0 );
			p10_nodeVar289 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar283.x, p10_nodeVar287.y ), 0.0 );
			p10_nodeVar290 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar287.x, p10_nodeVar287.y ), 0.0 );
			p10_nodeVar0 = mix( p10_nodeVar0, mix( mix( p10_nodeVar284, p10_nodeVar288, p10_nodeVar286.x ), mix( p10_nodeVar289, p10_nodeVar290, p10_nodeVar286.x ), p10_nodeVar286.y ), p10_nodeVar3 );
			

		}

		

	}


	if ( ( p10_nodeVar2 >= 10.0 ) ) {

		p10_nodeVar291 = ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) );
		p10_nodeVar292 = ( ( ( ( ( p10_nodeVar291 + fract( ( sin( vec2<f32>( dot( p10_nodeVar291, vec2<f32>( 127.1, 311.7 ) ), dot( p10_nodeVar291, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( ( f32(knobs.gap) * 0.5 ) ) ) / vec2<f32>((knobs.resolution.x / 1.1042968750000002), (knobs.resolution.y / 1.10859375)) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
		p10_nodeVar293 = floor( p10_nodeVar292 );
		p10_nodeVar294 = ( p10_nodeVar292 - p10_nodeVar293 );
		p10_nodeVar295 = ( p10_nodeVar294 * p10_nodeVar294 );
		p10_nodeVar296 = ( p10_nodeVar295 * p10_nodeVar294 );
		p10_nodeVar297 = ( ( ( ( p10_nodeVar296 * vec2<f32>( 3.0 ) ) - ( p10_nodeVar295 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p10_nodeVar298 = ( ( ( p10_nodeVar293 - vec2<f32>( 0.5 ) ) + ( p10_nodeVar297 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p10_nodeVar294 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar297 ) ) ) * vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0) );
		p10_nodeVar299 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar298.x, p10_nodeVar298.y ), 0.0 );
		p10_nodeVar300 = ( p10_nodeVar296 / vec2<f32>( 6.0 ) );
		p10_nodeVar301 = ( ( ( ( ( ( p10_nodeVar296 * vec2<f32>( -3.0 ) ) + ( p10_nodeVar295 * vec2<f32>( 3.0 ) ) ) + ( p10_nodeVar294 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p10_nodeVar300 );
		p10_nodeVar302 = ( ( ( p10_nodeVar293 + vec2<f32>( 1.5 ) ) + ( p10_nodeVar300 / p10_nodeVar301 ) ) * vec2<f32>((1024 * (1.0 / (knobs.resolution.x / 1.1042968750000002)) + 0), 1.0) );
		p10_nodeVar303 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar302.x, p10_nodeVar298.y ), 0.0 );
		p10_nodeVar304 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar298.x, p10_nodeVar302.y ), 0.0 );
		p10_nodeVar305 = target_read_level( t9, t9_sampler, vec2<f32>( p10_nodeVar302.x, p10_nodeVar302.y ), 0.0 );
		p10_nodeVar0 = mix( mix( p10_nodeVar299, p10_nodeVar303, p10_nodeVar301.x ), mix( p10_nodeVar304, p10_nodeVar305, p10_nodeVar301.x ), p10_nodeVar301.y );
		

	}

	p10_nodeVar307 = ( ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) ) - vec2<f32>( 1.0 ) ) + vec2<f32>( 9.1 ) );
	p10_nodeVar308 = fract( ( vec3<f32>( p10_nodeVar307.x, p10_nodeVar307.y, p10_nodeVar307.x ) * vec3<f32>( 0.1031 ) ) );
	p10_nodeVar309 = ( p10_nodeVar308 + vec3<f32>( dot( p10_nodeVar308, ( vec3<f32>( p10_nodeVar308.y, p10_nodeVar308.z, p10_nodeVar308.x ) + vec3<f32>( 33.33 ) ) ) ) );
	p10_nodeVar311 = vec4<f32>( ( p10_nodeVar0.xyz / vec3<f32>( max( p10_nodeVar0.w, 0.0001 ) ) ), p10_nodeVar0.w );
	p10_nodeVar312 = clamp( dot( vec3<f32>( p10_nodeVar311.x, p10_nodeVar311.y, p10_nodeVar311.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p10_nodeVar312 <= 0.0031308 ) ) {

		p10_nodeVar310 = ( p10_nodeVar312 * 12.92 );

	} else {

		p10_nodeVar310 = ( ( pow( p10_nodeVar312, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}


	if ( ( fract( ( ( p10_nodeVar309.x + p10_nodeVar309.y ) * p10_nodeVar309.z ) ) < pow( ( ( 1.0 - p10_nodeVar310 ) * clamp( p10_nodeVar0.w, 0.0, 1.0 ) ), ( 1.0 + ( f32(knobs.threshold) * 2.0 ) ) ) ) ) {

		p10_nodeVar306 = 1.0;

	} else {

		p10_nodeVar306 = 0.0;

	}


	// result

	p10_output.color = vec4<f32>( p10_nodeVar306, 0.0, 0.0, 1.0 );

	return p10_output;

}

// structs

struct p11_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p11_output : p11_OutputStruct;

// uniforms


// vars
var<private> p11_DiffuseColor : vec4<f32>;
var<private> p11_nodeVar0 : vec4<f32>;
var<private> p11_nodeVar1 : vec2<f32>;
var<private> p11_nodeVar2 : vec2<f32>;
var<private> p11_nodeVar3 : vec2<f32>;
var<private> p11_nodeVar4 : vec2<f32>;
var<private> p11_nodeVar5 : vec3<f32>;
var<private> p11_nodeVar6 : vec3<f32>;
var<private> p11_nodeVar7 : vec2<f32>;
var<private> p11_nodeVar8 : vec3<f32>;
var<private> p11_nodeVar9 : vec3<f32>;
var<private> p11_nodeVar10 : vec2<f32>;
var<private> p11_nodeVar11 : vec2<f32>;
var<private> p11_nodeVar12 : vec2<f32>;
var<private> p11_nodeVar13 : vec3<f32>;
var<private> p11_nodeVar14 : vec3<f32>;
var<private> p11_nodeVar15 : vec2<f32>;
var<private> p11_nodeVar16 : vec3<f32>;
var<private> p11_nodeVar17 : vec3<f32>;
var<private> p11_nodeVar18 : vec2<f32>;
var<private> p11_nodeVar19 : vec2<f32>;
var<private> p11_nodeVar20 : vec3<f32>;
var<private> p11_nodeVar21 : vec3<f32>;
var<private> p11_nodeVar22 : vec2<f32>;
var<private> p11_nodeVar23 : vec3<f32>;
var<private> p11_nodeVar24 : vec3<f32>;
var<private> p11_nodeVar25 : vec2<f32>;
var<private> p11_nodeVar26 : vec2<f32>;
var<private> p11_nodeVar27 : vec2<f32>;
var<private> p11_nodeVar28 : vec3<f32>;
var<private> p11_nodeVar29 : vec3<f32>;
var<private> p11_nodeVar30 : vec2<f32>;
var<private> p11_nodeVar31 : vec3<f32>;
var<private> p11_nodeVar32 : vec3<f32>;
var<private> p11_nodeVar33 : vec2<f32>;
var<private> p11_nodeVar34 : vec2<f32>;
var<private> p11_nodeVar35 : vec2<f32>;
var<private> p11_nodeVar36 : vec4<f32>;
var<private> p11_nodeVar37 : f32;
var<private> p11_nodeVar38 : f32;
var<private> p11_nodeVar39 : f32;
var<private> p11_nodeVar40 : f32;
var<private> p11_nodeVar41 : vec2<f32>;
var<private> p11_nodeVar42 : vec4<f32>;
var<private> p11_nodeVar43 : vec2<f32>;
var<private> p11_nodeVar44 : vec2<f32>;
var<private> p11_nodeVar45 : vec2<f32>;
var<private> p11_nodeVar46 : vec2<f32>;
var<private> p11_nodeVar47 : vec2<f32>;
var<private> p11_nodeVar48 : vec2<f32>;
var<private> p11_nodeVar49 : vec2<f32>;
var<private> p11_nodeVar50 : vec4<f32>;
var<private> p11_nodeVar51 : vec2<f32>;
var<private> p11_nodeVar52 : vec2<f32>;
var<private> p11_nodeVar53 : vec2<f32>;
var<private> p11_nodeVar54 : vec4<f32>;
var<private> p11_nodeVar55 : vec4<f32>;
var<private> p11_nodeVar56 : vec4<f32>;
var<private> p11_nodeVar57 : vec2<f32>;
var<private> p11_nodeVar58 : vec2<f32>;
var<private> p11_nodeVar59 : vec2<f32>;
var<private> p11_nodeVar60 : vec2<f32>;
var<private> p11_nodeVar61 : vec2<f32>;
var<private> p11_nodeVar62 : vec2<f32>;
var<private> p11_nodeVar63 : vec2<f32>;
var<private> p11_nodeVar64 : vec2<f32>;
var<private> p11_nodeVar65 : vec4<f32>;
var<private> p11_nodeVar66 : vec2<f32>;
var<private> p11_nodeVar67 : vec2<f32>;
var<private> p11_nodeVar68 : vec2<f32>;
var<private> p11_nodeVar69 : vec4<f32>;
var<private> p11_nodeVar70 : vec4<f32>;
var<private> p11_nodeVar71 : vec4<f32>;
var<private> p11_nodeVar72 : vec2<f32>;
var<private> p11_nodeVar73 : vec2<f32>;
var<private> p11_nodeVar74 : vec2<f32>;
var<private> p11_nodeVar75 : vec2<f32>;
var<private> p11_nodeVar76 : vec2<f32>;
var<private> p11_nodeVar77 : vec2<f32>;
var<private> p11_nodeVar78 : vec2<f32>;
var<private> p11_nodeVar79 : vec4<f32>;
var<private> p11_nodeVar80 : vec2<f32>;
var<private> p11_nodeVar81 : vec2<f32>;
var<private> p11_nodeVar82 : vec2<f32>;
var<private> p11_nodeVar83 : vec4<f32>;
var<private> p11_nodeVar84 : vec4<f32>;
var<private> p11_nodeVar85 : vec4<f32>;
var<private> p11_nodeVar86 : vec2<f32>;
var<private> p11_nodeVar87 : vec2<f32>;
var<private> p11_nodeVar88 : vec2<f32>;
var<private> p11_nodeVar89 : vec2<f32>;
var<private> p11_nodeVar90 : vec2<f32>;
var<private> p11_nodeVar91 : vec2<f32>;
var<private> p11_nodeVar92 : vec2<f32>;
var<private> p11_nodeVar93 : vec2<f32>;
var<private> p11_nodeVar94 : vec4<f32>;
var<private> p11_nodeVar95 : vec2<f32>;
var<private> p11_nodeVar96 : vec2<f32>;
var<private> p11_nodeVar97 : vec2<f32>;
var<private> p11_nodeVar98 : vec4<f32>;
var<private> p11_nodeVar99 : vec4<f32>;
var<private> p11_nodeVar100 : vec4<f32>;
var<private> p11_nodeVar101 : vec2<f32>;
var<private> p11_nodeVar102 : vec2<f32>;
var<private> p11_nodeVar103 : vec2<f32>;
var<private> p11_nodeVar104 : vec2<f32>;
var<private> p11_nodeVar105 : vec2<f32>;
var<private> p11_nodeVar106 : vec2<f32>;
var<private> p11_nodeVar107 : vec2<f32>;
var<private> p11_nodeVar108 : vec4<f32>;
var<private> p11_nodeVar109 : vec2<f32>;
var<private> p11_nodeVar110 : vec2<f32>;
var<private> p11_nodeVar111 : vec2<f32>;
var<private> p11_nodeVar112 : vec4<f32>;
var<private> p11_nodeVar113 : vec4<f32>;
var<private> p11_nodeVar114 : vec4<f32>;
var<private> p11_nodeVar115 : vec2<f32>;
var<private> p11_nodeVar116 : vec2<f32>;
var<private> p11_nodeVar117 : vec2<f32>;
var<private> p11_nodeVar118 : vec2<f32>;
var<private> p11_nodeVar119 : vec2<f32>;
var<private> p11_nodeVar120 : vec2<f32>;
var<private> p11_nodeVar121 : vec2<f32>;
var<private> p11_nodeVar122 : vec2<f32>;
var<private> p11_nodeVar123 : vec4<f32>;
var<private> p11_nodeVar124 : vec2<f32>;
var<private> p11_nodeVar125 : vec2<f32>;
var<private> p11_nodeVar126 : vec2<f32>;
var<private> p11_nodeVar127 : vec4<f32>;
var<private> p11_nodeVar128 : vec4<f32>;
var<private> p11_nodeVar129 : vec4<f32>;
var<private> p11_nodeVar130 : vec2<f32>;
var<private> p11_nodeVar131 : vec2<f32>;
var<private> p11_nodeVar132 : vec2<f32>;
var<private> p11_nodeVar133 : vec2<f32>;
var<private> p11_nodeVar134 : vec2<f32>;
var<private> p11_nodeVar135 : vec2<f32>;
var<private> p11_nodeVar136 : vec2<f32>;
var<private> p11_nodeVar137 : vec4<f32>;
var<private> p11_nodeVar138 : vec2<f32>;
var<private> p11_nodeVar139 : vec2<f32>;
var<private> p11_nodeVar140 : vec2<f32>;
var<private> p11_nodeVar141 : vec4<f32>;
var<private> p11_nodeVar142 : vec4<f32>;
var<private> p11_nodeVar143 : vec4<f32>;
var<private> p11_nodeVar144 : vec2<f32>;
var<private> p11_nodeVar145 : vec2<f32>;
var<private> p11_nodeVar146 : vec2<f32>;
var<private> p11_nodeVar147 : vec2<f32>;
var<private> p11_nodeVar148 : vec2<f32>;
var<private> p11_nodeVar149 : vec2<f32>;
var<private> p11_nodeVar150 : vec2<f32>;
var<private> p11_nodeVar151 : vec2<f32>;
var<private> p11_nodeVar152 : vec4<f32>;
var<private> p11_nodeVar153 : vec2<f32>;
var<private> p11_nodeVar154 : vec2<f32>;
var<private> p11_nodeVar155 : vec2<f32>;
var<private> p11_nodeVar156 : vec4<f32>;
var<private> p11_nodeVar157 : vec4<f32>;
var<private> p11_nodeVar158 : vec4<f32>;
var<private> p11_nodeVar159 : vec2<f32>;
var<private> p11_nodeVar160 : vec2<f32>;
var<private> p11_nodeVar161 : vec2<f32>;
var<private> p11_nodeVar162 : vec2<f32>;
var<private> p11_nodeVar163 : vec2<f32>;
var<private> p11_nodeVar164 : vec2<f32>;
var<private> p11_nodeVar165 : vec2<f32>;
var<private> p11_nodeVar166 : vec4<f32>;
var<private> p11_nodeVar167 : vec2<f32>;
var<private> p11_nodeVar168 : vec2<f32>;
var<private> p11_nodeVar169 : vec2<f32>;
var<private> p11_nodeVar170 : vec4<f32>;
var<private> p11_nodeVar171 : vec4<f32>;
var<private> p11_nodeVar172 : vec4<f32>;
var<private> p11_nodeVar173 : vec2<f32>;
var<private> p11_nodeVar174 : vec2<f32>;
var<private> p11_nodeVar175 : vec2<f32>;
var<private> p11_nodeVar176 : vec2<f32>;
var<private> p11_nodeVar177 : vec2<f32>;
var<private> p11_nodeVar178 : vec2<f32>;
var<private> p11_nodeVar179 : vec2<f32>;
var<private> p11_nodeVar180 : vec2<f32>;
var<private> p11_nodeVar181 : vec4<f32>;
var<private> p11_nodeVar182 : vec2<f32>;
var<private> p11_nodeVar183 : vec2<f32>;
var<private> p11_nodeVar184 : vec2<f32>;
var<private> p11_nodeVar185 : vec4<f32>;
var<private> p11_nodeVar186 : vec4<f32>;
var<private> p11_nodeVar187 : vec4<f32>;
var<private> p11_nodeVar188 : vec2<f32>;
var<private> p11_nodeVar189 : vec2<f32>;
var<private> p11_nodeVar190 : vec2<f32>;
var<private> p11_nodeVar191 : vec2<f32>;
var<private> p11_nodeVar192 : vec2<f32>;
var<private> p11_nodeVar193 : vec2<f32>;
var<private> p11_nodeVar194 : vec2<f32>;
var<private> p11_nodeVar195 : vec4<f32>;
var<private> p11_nodeVar196 : vec2<f32>;
var<private> p11_nodeVar197 : vec2<f32>;
var<private> p11_nodeVar198 : vec2<f32>;
var<private> p11_nodeVar199 : vec4<f32>;
var<private> p11_nodeVar200 : vec4<f32>;
var<private> p11_nodeVar201 : vec4<f32>;
var<private> p11_nodeVar202 : vec2<f32>;
var<private> p11_nodeVar203 : vec2<f32>;
var<private> p11_nodeVar204 : vec2<f32>;
var<private> p11_nodeVar205 : vec2<f32>;
var<private> p11_nodeVar206 : vec2<f32>;
var<private> p11_nodeVar207 : vec2<f32>;
var<private> p11_nodeVar208 : vec2<f32>;
var<private> p11_nodeVar209 : vec2<f32>;
var<private> p11_nodeVar210 : vec4<f32>;
var<private> p11_nodeVar211 : vec2<f32>;
var<private> p11_nodeVar212 : vec2<f32>;
var<private> p11_nodeVar213 : vec2<f32>;
var<private> p11_nodeVar214 : vec4<f32>;
var<private> p11_nodeVar215 : vec4<f32>;
var<private> p11_nodeVar216 : vec4<f32>;
var<private> p11_nodeVar217 : vec2<f32>;
var<private> p11_nodeVar218 : vec2<f32>;
var<private> p11_nodeVar219 : vec2<f32>;
var<private> p11_nodeVar220 : vec2<f32>;
var<private> p11_nodeVar221 : vec2<f32>;
var<private> p11_nodeVar222 : vec2<f32>;
var<private> p11_nodeVar223 : vec2<f32>;
var<private> p11_nodeVar224 : vec4<f32>;
var<private> p11_nodeVar225 : vec2<f32>;
var<private> p11_nodeVar226 : vec2<f32>;
var<private> p11_nodeVar227 : vec2<f32>;
var<private> p11_nodeVar228 : vec4<f32>;
var<private> p11_nodeVar229 : vec4<f32>;
var<private> p11_nodeVar230 : vec4<f32>;
var<private> p11_nodeVar231 : vec2<f32>;
var<private> p11_nodeVar232 : vec2<f32>;
var<private> p11_nodeVar233 : vec2<f32>;
var<private> p11_nodeVar234 : vec2<f32>;
var<private> p11_nodeVar235 : vec2<f32>;
var<private> p11_nodeVar236 : vec2<f32>;
var<private> p11_nodeVar237 : vec2<f32>;
var<private> p11_nodeVar238 : vec2<f32>;
var<private> p11_nodeVar239 : vec4<f32>;
var<private> p11_nodeVar240 : vec2<f32>;
var<private> p11_nodeVar241 : vec2<f32>;
var<private> p11_nodeVar242 : vec2<f32>;
var<private> p11_nodeVar243 : vec4<f32>;
var<private> p11_nodeVar244 : vec4<f32>;
var<private> p11_nodeVar245 : vec4<f32>;
var<private> p11_nodeVar246 : vec2<f32>;
var<private> p11_nodeVar247 : vec2<f32>;
var<private> p11_nodeVar248 : vec2<f32>;
var<private> p11_nodeVar249 : vec2<f32>;
var<private> p11_nodeVar250 : vec2<f32>;
var<private> p11_nodeVar251 : vec2<f32>;
var<private> p11_nodeVar252 : vec2<f32>;
var<private> p11_nodeVar253 : vec4<f32>;
var<private> p11_nodeVar254 : vec2<f32>;
var<private> p11_nodeVar255 : vec2<f32>;
var<private> p11_nodeVar256 : vec2<f32>;
var<private> p11_nodeVar257 : vec4<f32>;
var<private> p11_nodeVar258 : vec4<f32>;
var<private> p11_nodeVar259 : vec4<f32>;
var<private> p11_nodeVar260 : vec2<f32>;
var<private> p11_nodeVar261 : vec2<f32>;
var<private> p11_nodeVar262 : vec2<f32>;
var<private> p11_nodeVar263 : vec2<f32>;
var<private> p11_nodeVar264 : vec2<f32>;
var<private> p11_nodeVar265 : vec2<f32>;
var<private> p11_nodeVar266 : vec2<f32>;
var<private> p11_nodeVar267 : vec2<f32>;
var<private> p11_nodeVar268 : vec4<f32>;
var<private> p11_nodeVar269 : vec2<f32>;
var<private> p11_nodeVar270 : vec2<f32>;
var<private> p11_nodeVar271 : vec2<f32>;
var<private> p11_nodeVar272 : vec4<f32>;
var<private> p11_nodeVar273 : vec4<f32>;
var<private> p11_nodeVar274 : vec4<f32>;
var<private> p11_nodeVar275 : vec2<f32>;
var<private> p11_nodeVar276 : vec2<f32>;
var<private> p11_nodeVar277 : vec2<f32>;
var<private> p11_nodeVar278 : vec2<f32>;
var<private> p11_nodeVar279 : vec2<f32>;
var<private> p11_nodeVar280 : vec2<f32>;
var<private> p11_nodeVar281 : vec2<f32>;
var<private> p11_nodeVar282 : vec4<f32>;
var<private> p11_nodeVar283 : vec2<f32>;
var<private> p11_nodeVar284 : vec2<f32>;
var<private> p11_nodeVar285 : vec2<f32>;
var<private> p11_nodeVar286 : vec4<f32>;
var<private> p11_nodeVar287 : vec4<f32>;
var<private> p11_nodeVar288 : vec4<f32>;
var<private> p11_nodeVar289 : vec2<f32>;
var<private> p11_nodeVar290 : vec2<f32>;
var<private> p11_nodeVar291 : vec2<f32>;
var<private> p11_nodeVar292 : vec2<f32>;
var<private> p11_nodeVar293 : vec2<f32>;
var<private> p11_nodeVar294 : vec2<f32>;
var<private> p11_nodeVar295 : vec2<f32>;
var<private> p11_nodeVar296 : vec2<f32>;
var<private> p11_nodeVar297 : vec4<f32>;
var<private> p11_nodeVar298 : vec2<f32>;
var<private> p11_nodeVar299 : vec2<f32>;
var<private> p11_nodeVar300 : vec2<f32>;
var<private> p11_nodeVar301 : vec4<f32>;
var<private> p11_nodeVar302 : vec4<f32>;
var<private> p11_nodeVar303 : vec4<f32>;
var<private> p11_nodeVar304 : vec2<f32>;
var<private> p11_nodeVar305 : vec2<f32>;
var<private> p11_nodeVar306 : vec2<f32>;
var<private> p11_nodeVar307 : vec2<f32>;
var<private> p11_nodeVar308 : vec2<f32>;
var<private> p11_nodeVar309 : vec2<f32>;
var<private> p11_nodeVar310 : vec2<f32>;
var<private> p11_nodeVar311 : vec4<f32>;
var<private> p11_nodeVar312 : vec2<f32>;
var<private> p11_nodeVar313 : vec2<f32>;
var<private> p11_nodeVar314 : vec2<f32>;
var<private> p11_nodeVar315 : vec4<f32>;
var<private> p11_nodeVar316 : vec4<f32>;
var<private> p11_nodeVar317 : vec4<f32>;
var<private> p11_nodeVar318 : vec2<f32>;
var<private> p11_nodeVar319 : vec2<f32>;
var<private> p11_nodeVar320 : vec2<f32>;
var<private> p11_nodeVar321 : vec2<f32>;
var<private> p11_nodeVar322 : vec2<f32>;
var<private> p11_nodeVar323 : vec2<f32>;
var<private> p11_nodeVar324 : vec2<f32>;
var<private> p11_nodeVar325 : vec4<f32>;
var<private> p11_nodeVar326 : vec2<f32>;
var<private> p11_nodeVar327 : vec2<f32>;
var<private> p11_nodeVar328 : vec2<f32>;
var<private> p11_nodeVar329 : vec4<f32>;
var<private> p11_nodeVar330 : vec4<f32>;
var<private> p11_nodeVar331 : vec4<f32>;
var<private> p11_nodeVar332 : f32;
var<private> p11_nodeVar333 : vec2<f32>;
var<private> p11_nodeVar334 : vec2<f32>;
var<private> p11_nodeVar335 : vec3<f32>;
var<private> p11_nodeVar336 : vec3<f32>;
var<private> p11_nodeVar337 : vec2<f32>;
var<private> p11_nodeVar338 : vec3<f32>;
var<private> p11_nodeVar339 : vec3<f32>;
var<private> p11_nodeVar340 : vec2<f32>;
var<private> p11_nodeVar341 : vec2<f32>;
var<private> p11_nodeVar342 : vec2<f32>;
var<private> p11_nodeVar343 : vec3<f32>;
var<private> p11_nodeVar344 : vec3<f32>;
var<private> p11_nodeVar345 : vec2<f32>;
var<private> p11_nodeVar346 : vec3<f32>;
var<private> p11_nodeVar347 : vec3<f32>;
var<private> p11_nodeVar348 : f32;
var<private> p11_nodeVar349 : f32;
var<private> p11_nodeVar350 : f32;
var<private> p11_nodeVar351 : f32;
var<private> p11_nodeVar352 : vec4<f32>;
var<private> p11_nodeVar353 : f32;
var<private> p11_nodeVar354 : f32;
var<private> p11_nodeVar355 : f32;
var<private> p11_nodeVar356 : f32;
var<private> p11_nodeVar357 : f32;
var<private> p11_nodeVar358 : f32;
var<private> p11_nodeVar359 : f32;
var<private> p11_nodeVar360 : f32;
var<private> p11_nodeVar361 : f32;
var<private> p11_nodeVar362 : f32;
var<private> p11_nodeVar363 : f32;
var<private> p11_nodeVar364 : f32;
var<private> p11_nodeVar365 : vec4<f32>;
var<private> p11_nodeVar366 : f32;
var<private> p11_nodeVar367 : f32;
var<private> p11_nodeVar368 : f32;
var<private> p11_nodeVar369 : vec2<f32>;
var<private> p11_nodeVar370 : vec2<f32>;
var<private> p11_nodeVar371 : vec2<f32>;
var<private> p11_nodeVar372 : vec4<f32>;
var<private> p11_nodeVar373 : vec2<f32>;
var<private> p11_nodeVar374 : vec2<f32>;
var<private> p11_nodeVar375 : vec2<f32>;
var<private> p11_nodeVar376 : vec2<f32>;
var<private> p11_nodeVar377 : vec2<f32>;
var<private> p11_nodeVar378 : vec2<f32>;
var<private> p11_nodeVar379 : vec2<f32>;
var<private> p11_nodeVar380 : vec4<f32>;
var<private> p11_nodeVar381 : vec2<f32>;
var<private> p11_nodeVar382 : vec2<f32>;
var<private> p11_nodeVar383 : vec2<f32>;
var<private> p11_nodeVar384 : vec4<f32>;
var<private> p11_nodeVar385 : vec4<f32>;
var<private> p11_nodeVar386 : vec4<f32>;
var<private> p11_nodeVar387 : vec2<f32>;
var<private> p11_nodeVar388 : vec2<f32>;
var<private> p11_nodeVar389 : vec2<f32>;
var<private> p11_nodeVar390 : vec2<f32>;
var<private> p11_nodeVar391 : vec2<f32>;
var<private> p11_nodeVar392 : vec2<f32>;
var<private> p11_nodeVar393 : vec2<f32>;
var<private> p11_nodeVar394 : vec2<f32>;
var<private> p11_nodeVar395 : vec2<f32>;
var<private> p11_nodeVar396 : vec2<f32>;
var<private> p11_nodeVar397 : vec4<f32>;
var<private> p11_nodeVar398 : vec2<f32>;
var<private> p11_nodeVar399 : vec2<f32>;
var<private> p11_nodeVar400 : vec2<f32>;
var<private> p11_nodeVar401 : vec4<f32>;
var<private> p11_nodeVar402 : vec4<f32>;
var<private> p11_nodeVar403 : vec4<f32>;
var<private> p11_nodeVar404 : vec2<f32>;
var<private> p11_nodeVar405 : vec2<f32>;
var<private> p11_nodeVar406 : vec2<f32>;
var<private> p11_nodeVar407 : vec2<f32>;
var<private> p11_nodeVar408 : vec2<f32>;
var<private> p11_nodeVar409 : vec2<f32>;
var<private> p11_nodeVar410 : vec2<f32>;
var<private> p11_nodeVar411 : vec4<f32>;
var<private> p11_nodeVar412 : vec2<f32>;
var<private> p11_nodeVar413 : vec2<f32>;
var<private> p11_nodeVar414 : vec2<f32>;
var<private> p11_nodeVar415 : vec4<f32>;
var<private> p11_nodeVar416 : vec4<f32>;
var<private> p11_nodeVar417 : vec4<f32>;
var<private> p11_nodeVar418 : vec2<f32>;
var<private> p11_nodeVar419 : vec2<f32>;
var<private> p11_nodeVar420 : vec2<f32>;
var<private> p11_nodeVar421 : vec2<f32>;
var<private> p11_nodeVar422 : vec2<f32>;
var<private> p11_nodeVar423 : vec2<f32>;
var<private> p11_nodeVar424 : vec2<f32>;
var<private> p11_nodeVar425 : vec2<f32>;
var<private> p11_nodeVar426 : vec2<f32>;
var<private> p11_nodeVar427 : vec2<f32>;
var<private> p11_nodeVar428 : vec4<f32>;
var<private> p11_nodeVar429 : vec2<f32>;
var<private> p11_nodeVar430 : vec2<f32>;
var<private> p11_nodeVar431 : vec2<f32>;
var<private> p11_nodeVar432 : vec4<f32>;
var<private> p11_nodeVar433 : vec4<f32>;
var<private> p11_nodeVar434 : vec4<f32>;
var<private> p11_nodeVar435 : vec2<f32>;
var<private> p11_nodeVar436 : vec2<f32>;
var<private> p11_nodeVar437 : vec2<f32>;
var<private> p11_nodeVar438 : vec2<f32>;
var<private> p11_nodeVar439 : vec2<f32>;
var<private> p11_nodeVar440 : vec2<f32>;
var<private> p11_nodeVar441 : vec2<f32>;
var<private> p11_nodeVar442 : vec4<f32>;
var<private> p11_nodeVar443 : vec2<f32>;
var<private> p11_nodeVar444 : vec2<f32>;
var<private> p11_nodeVar445 : vec2<f32>;
var<private> p11_nodeVar446 : vec4<f32>;
var<private> p11_nodeVar447 : vec4<f32>;
var<private> p11_nodeVar448 : vec4<f32>;
var<private> p11_nodeVar449 : vec2<f32>;
var<private> p11_nodeVar450 : vec2<f32>;
var<private> p11_nodeVar451 : vec2<f32>;
var<private> p11_nodeVar452 : vec2<f32>;
var<private> p11_nodeVar453 : vec2<f32>;
var<private> p11_nodeVar454 : vec2<f32>;
var<private> p11_nodeVar455 : vec2<f32>;
var<private> p11_nodeVar456 : vec2<f32>;
var<private> p11_nodeVar457 : vec2<f32>;
var<private> p11_nodeVar458 : vec2<f32>;
var<private> p11_nodeVar459 : vec4<f32>;
var<private> p11_nodeVar460 : vec2<f32>;
var<private> p11_nodeVar461 : vec2<f32>;
var<private> p11_nodeVar462 : vec2<f32>;
var<private> p11_nodeVar463 : vec4<f32>;
var<private> p11_nodeVar464 : vec4<f32>;
var<private> p11_nodeVar465 : vec4<f32>;
var<private> p11_nodeVar466 : vec2<f32>;
var<private> p11_nodeVar467 : vec2<f32>;
var<private> p11_nodeVar468 : vec2<f32>;
var<private> p11_nodeVar469 : vec2<f32>;
var<private> p11_nodeVar470 : vec2<f32>;
var<private> p11_nodeVar471 : vec2<f32>;
var<private> p11_nodeVar472 : vec2<f32>;
var<private> p11_nodeVar473 : vec4<f32>;
var<private> p11_nodeVar474 : vec2<f32>;
var<private> p11_nodeVar475 : vec2<f32>;
var<private> p11_nodeVar476 : vec2<f32>;
var<private> p11_nodeVar477 : vec4<f32>;
var<private> p11_nodeVar478 : vec4<f32>;
var<private> p11_nodeVar479 : vec4<f32>;
var<private> p11_nodeVar480 : vec2<f32>;
var<private> p11_nodeVar481 : vec2<f32>;
var<private> p11_nodeVar482 : vec2<f32>;
var<private> p11_nodeVar483 : vec2<f32>;
var<private> p11_nodeVar484 : vec2<f32>;
var<private> p11_nodeVar485 : vec2<f32>;
var<private> p11_nodeVar486 : vec2<f32>;
var<private> p11_nodeVar487 : vec2<f32>;
var<private> p11_nodeVar488 : vec2<f32>;
var<private> p11_nodeVar489 : vec2<f32>;
var<private> p11_nodeVar490 : vec4<f32>;
var<private> p11_nodeVar491 : vec2<f32>;
var<private> p11_nodeVar492 : vec2<f32>;
var<private> p11_nodeVar493 : vec2<f32>;
var<private> p11_nodeVar494 : vec4<f32>;
var<private> p11_nodeVar495 : vec4<f32>;
var<private> p11_nodeVar496 : vec4<f32>;
var<private> p11_nodeVar497 : vec2<f32>;
var<private> p11_nodeVar498 : vec2<f32>;
var<private> p11_nodeVar499 : vec2<f32>;
var<private> p11_nodeVar500 : vec2<f32>;
var<private> p11_nodeVar501 : vec2<f32>;
var<private> p11_nodeVar502 : vec2<f32>;
var<private> p11_nodeVar503 : vec2<f32>;
var<private> p11_nodeVar504 : vec4<f32>;
var<private> p11_nodeVar505 : vec2<f32>;
var<private> p11_nodeVar506 : vec2<f32>;
var<private> p11_nodeVar507 : vec2<f32>;
var<private> p11_nodeVar508 : vec4<f32>;
var<private> p11_nodeVar509 : vec4<f32>;
var<private> p11_nodeVar510 : vec4<f32>;
var<private> p11_nodeVar511 : vec2<f32>;
var<private> p11_nodeVar512 : vec2<f32>;
var<private> p11_nodeVar513 : vec2<f32>;
var<private> p11_nodeVar514 : vec2<f32>;
var<private> p11_nodeVar515 : vec2<f32>;
var<private> p11_nodeVar516 : vec2<f32>;
var<private> p11_nodeVar517 : vec2<f32>;
var<private> p11_nodeVar518 : vec2<f32>;
var<private> p11_nodeVar519 : vec2<f32>;
var<private> p11_nodeVar520 : vec2<f32>;
var<private> p11_nodeVar521 : vec4<f32>;
var<private> p11_nodeVar522 : vec2<f32>;
var<private> p11_nodeVar523 : vec2<f32>;
var<private> p11_nodeVar524 : vec2<f32>;
var<private> p11_nodeVar525 : vec4<f32>;
var<private> p11_nodeVar526 : vec4<f32>;
var<private> p11_nodeVar527 : vec4<f32>;
var<private> p11_nodeVar528 : vec2<f32>;
var<private> p11_nodeVar529 : vec2<f32>;
var<private> p11_nodeVar530 : vec2<f32>;
var<private> p11_nodeVar531 : vec2<f32>;
var<private> p11_nodeVar532 : vec2<f32>;
var<private> p11_nodeVar533 : vec2<f32>;
var<private> p11_nodeVar534 : vec2<f32>;
var<private> p11_nodeVar535 : vec4<f32>;
var<private> p11_nodeVar536 : vec2<f32>;
var<private> p11_nodeVar537 : vec2<f32>;
var<private> p11_nodeVar538 : vec2<f32>;
var<private> p11_nodeVar539 : vec4<f32>;
var<private> p11_nodeVar540 : vec4<f32>;
var<private> p11_nodeVar541 : vec4<f32>;
var<private> p11_nodeVar542 : vec2<f32>;
var<private> p11_nodeVar543 : vec2<f32>;
var<private> p11_nodeVar544 : vec2<f32>;
var<private> p11_nodeVar545 : vec2<f32>;
var<private> p11_nodeVar546 : vec2<f32>;
var<private> p11_nodeVar547 : vec2<f32>;
var<private> p11_nodeVar548 : vec2<f32>;
var<private> p11_nodeVar549 : vec2<f32>;
var<private> p11_nodeVar550 : vec2<f32>;
var<private> p11_nodeVar551 : vec2<f32>;
var<private> p11_nodeVar552 : vec4<f32>;
var<private> p11_nodeVar553 : vec2<f32>;
var<private> p11_nodeVar554 : vec2<f32>;
var<private> p11_nodeVar555 : vec2<f32>;
var<private> p11_nodeVar556 : vec4<f32>;
var<private> p11_nodeVar557 : vec4<f32>;
var<private> p11_nodeVar558 : vec4<f32>;
var<private> p11_nodeVar559 : vec2<f32>;
var<private> p11_nodeVar560 : vec2<f32>;
var<private> p11_nodeVar561 : vec2<f32>;
var<private> p11_nodeVar562 : vec2<f32>;
var<private> p11_nodeVar563 : vec2<f32>;
var<private> p11_nodeVar564 : vec2<f32>;
var<private> p11_nodeVar565 : vec2<f32>;
var<private> p11_nodeVar566 : vec4<f32>;
var<private> p11_nodeVar567 : vec2<f32>;
var<private> p11_nodeVar568 : vec2<f32>;
var<private> p11_nodeVar569 : vec2<f32>;
var<private> p11_nodeVar570 : vec4<f32>;
var<private> p11_nodeVar571 : vec4<f32>;
var<private> p11_nodeVar572 : vec4<f32>;
var<private> p11_nodeVar573 : vec2<f32>;
var<private> p11_nodeVar574 : vec2<f32>;
var<private> p11_nodeVar575 : vec2<f32>;
var<private> p11_nodeVar576 : vec2<f32>;
var<private> p11_nodeVar577 : vec2<f32>;
var<private> p11_nodeVar578 : vec2<f32>;
var<private> p11_nodeVar579 : vec2<f32>;
var<private> p11_nodeVar580 : vec2<f32>;
var<private> p11_nodeVar581 : vec2<f32>;
var<private> p11_nodeVar582 : vec2<f32>;
var<private> p11_nodeVar583 : vec4<f32>;
var<private> p11_nodeVar584 : vec2<f32>;
var<private> p11_nodeVar585 : vec2<f32>;
var<private> p11_nodeVar586 : vec2<f32>;
var<private> p11_nodeVar587 : vec4<f32>;
var<private> p11_nodeVar588 : vec4<f32>;
var<private> p11_nodeVar589 : vec4<f32>;
var<private> p11_nodeVar590 : vec2<f32>;
var<private> p11_nodeVar591 : vec2<f32>;
var<private> p11_nodeVar592 : vec2<f32>;
var<private> p11_nodeVar593 : vec2<f32>;
var<private> p11_nodeVar594 : vec2<f32>;
var<private> p11_nodeVar595 : vec2<f32>;
var<private> p11_nodeVar596 : vec2<f32>;
var<private> p11_nodeVar597 : vec4<f32>;
var<private> p11_nodeVar598 : vec2<f32>;
var<private> p11_nodeVar599 : vec2<f32>;
var<private> p11_nodeVar600 : vec2<f32>;
var<private> p11_nodeVar601 : vec4<f32>;
var<private> p11_nodeVar602 : vec4<f32>;
var<private> p11_nodeVar603 : vec4<f32>;
var<private> p11_nodeVar604 : vec2<f32>;
var<private> p11_nodeVar605 : vec2<f32>;
var<private> p11_nodeVar606 : vec2<f32>;
var<private> p11_nodeVar607 : vec2<f32>;
var<private> p11_nodeVar608 : vec2<f32>;
var<private> p11_nodeVar609 : vec2<f32>;
var<private> p11_nodeVar610 : vec2<f32>;
var<private> p11_nodeVar611 : vec2<f32>;
var<private> p11_nodeVar612 : vec2<f32>;
var<private> p11_nodeVar613 : vec2<f32>;
var<private> p11_nodeVar614 : vec4<f32>;
var<private> p11_nodeVar615 : vec2<f32>;
var<private> p11_nodeVar616 : vec2<f32>;
var<private> p11_nodeVar617 : vec2<f32>;
var<private> p11_nodeVar618 : vec4<f32>;
var<private> p11_nodeVar619 : vec4<f32>;
var<private> p11_nodeVar620 : vec4<f32>;
var<private> p11_nodeVar621 : vec2<f32>;
var<private> p11_nodeVar622 : vec2<f32>;
var<private> p11_nodeVar623 : vec2<f32>;
var<private> p11_nodeVar624 : vec2<f32>;
var<private> p11_nodeVar625 : vec2<f32>;
var<private> p11_nodeVar626 : vec2<f32>;
var<private> p11_nodeVar627 : vec2<f32>;
var<private> p11_nodeVar628 : vec4<f32>;
var<private> p11_nodeVar629 : vec2<f32>;
var<private> p11_nodeVar630 : vec2<f32>;
var<private> p11_nodeVar631 : vec2<f32>;
var<private> p11_nodeVar632 : vec4<f32>;
var<private> p11_nodeVar633 : vec4<f32>;
var<private> p11_nodeVar634 : vec4<f32>;
var<private> p11_nodeVar635 : vec2<f32>;
var<private> p11_nodeVar636 : vec2<f32>;
var<private> p11_nodeVar637 : vec2<f32>;
var<private> p11_nodeVar638 : vec2<f32>;
var<private> p11_nodeVar639 : vec2<f32>;
var<private> p11_nodeVar640 : vec2<f32>;
var<private> p11_nodeVar641 : vec2<f32>;
var<private> p11_nodeVar642 : vec2<f32>;
var<private> p11_nodeVar643 : vec2<f32>;
var<private> p11_nodeVar644 : vec2<f32>;
var<private> p11_nodeVar645 : vec4<f32>;
var<private> p11_nodeVar646 : vec2<f32>;
var<private> p11_nodeVar647 : vec2<f32>;
var<private> p11_nodeVar648 : vec2<f32>;
var<private> p11_nodeVar649 : vec4<f32>;
var<private> p11_nodeVar650 : vec4<f32>;
var<private> p11_nodeVar651 : vec4<f32>;
var<private> p11_nodeVar652 : vec2<f32>;
var<private> p11_nodeVar653 : vec2<f32>;
var<private> p11_nodeVar654 : vec2<f32>;
var<private> p11_nodeVar655 : vec2<f32>;
var<private> p11_nodeVar656 : vec2<f32>;
var<private> p11_nodeVar657 : vec2<f32>;
var<private> p11_nodeVar658 : vec2<f32>;
var<private> p11_nodeVar659 : vec4<f32>;
var<private> p11_nodeVar660 : vec2<f32>;
var<private> p11_nodeVar661 : vec2<f32>;
var<private> p11_nodeVar662 : vec2<f32>;
var<private> p11_nodeVar663 : vec4<f32>;
var<private> p11_nodeVar664 : vec4<f32>;
var<private> p11_nodeVar665 : vec4<f32>;
var<private> p11_nodeVar666 : vec2<f32>;
var<private> p11_nodeVar667 : vec2<f32>;
var<private> p11_nodeVar668 : vec2<f32>;
var<private> p11_nodeVar669 : vec2<f32>;
var<private> p11_nodeVar670 : vec2<f32>;
var<private> p11_nodeVar671 : vec2<f32>;
var<private> p11_nodeVar672 : vec2<f32>;
var<private> p11_nodeVar673 : vec2<f32>;
var<private> p11_nodeVar674 : vec2<f32>;
var<private> p11_nodeVar675 : vec4<f32>;
var<private> p11_nodeVar676 : vec2<f32>;
var<private> p11_nodeVar677 : vec2<f32>;
var<private> p11_nodeVar678 : vec2<f32>;
var<private> p11_nodeVar679 : vec4<f32>;
var<private> p11_nodeVar680 : vec4<f32>;
var<private> p11_nodeVar681 : vec4<f32>;
var<private> p11_nodeVar682 : f32;
var<private> p11_nodeVar683 : vec4<f32>;
var<private> p11_nodeVar684 : f32;
var<private> p11_nodeVar685 : f32;
var<private> p11_nodeVar686 : f32;
var<private> p11_nodeVar687 : vec2<f32>;
var<private> p11_nodeVar688 : f32;
var<private> p11_nodeVar689 : f32;
var<private> p11_nodeVar690 : f32;
var<private> p11_nodeVar691 : vec4<f32>;
var<private> p11_nodeVar692 : f32;
var<private> p11_nodeVar693 : f32;
var<private> p11_nodeVar694 : f32;
var<private> p11_nodeVar695 : f32;
var<private> p11_nodeVar696 : f32;
var<private> p11_nodeVar697 : f32;
var<private> p11_nodeVar698 : vec4<f32>;
var<private> p11_nodeVar699 : f32;
var<private> p11_nodeVar700 : f32;
var<private> p11_nodeVar701 : f32;
var<private> p11_nodeVar702 : vec2<f32>;
var<private> p11_nodeVar703 : vec4<f32>;
var<private> p11_nodeVar704 : vec2<f32>;
var<private> p11_nodeVar705 : vec2<f32>;
var<private> p11_nodeVar706 : vec2<f32>;
var<private> p11_nodeVar707 : vec2<f32>;
var<private> p11_nodeVar708 : vec2<f32>;
var<private> p11_nodeVar709 : vec2<f32>;
var<private> p11_nodeVar710 : vec2<f32>;
var<private> p11_nodeVar711 : vec4<f32>;
var<private> p11_nodeVar712 : vec2<f32>;
var<private> p11_nodeVar713 : vec2<f32>;
var<private> p11_nodeVar714 : vec2<f32>;
var<private> p11_nodeVar715 : vec4<f32>;
var<private> p11_nodeVar716 : vec4<f32>;
var<private> p11_nodeVar717 : vec4<f32>;
var<private> p11_nodeVar718 : vec2<f32>;
var<private> p11_nodeVar719 : vec2<f32>;
var<private> p11_nodeVar720 : vec2<f32>;
var<private> p11_nodeVar721 : vec2<f32>;
var<private> p11_nodeVar722 : vec2<f32>;
var<private> p11_nodeVar723 : vec2<f32>;
var<private> p11_nodeVar724 : vec2<f32>;
var<private> p11_nodeVar725 : vec2<f32>;
var<private> p11_nodeVar726 : vec4<f32>;
var<private> p11_nodeVar727 : vec2<f32>;
var<private> p11_nodeVar728 : vec2<f32>;
var<private> p11_nodeVar729 : vec2<f32>;
var<private> p11_nodeVar730 : vec4<f32>;
var<private> p11_nodeVar731 : vec4<f32>;
var<private> p11_nodeVar732 : vec4<f32>;
var<private> p11_nodeVar733 : vec2<f32>;
var<private> p11_nodeVar734 : vec2<f32>;
var<private> p11_nodeVar735 : vec2<f32>;
var<private> p11_nodeVar736 : vec2<f32>;
var<private> p11_nodeVar737 : vec2<f32>;
var<private> p11_nodeVar738 : vec2<f32>;
var<private> p11_nodeVar739 : vec2<f32>;
var<private> p11_nodeVar740 : vec4<f32>;
var<private> p11_nodeVar741 : vec2<f32>;
var<private> p11_nodeVar742 : vec2<f32>;
var<private> p11_nodeVar743 : vec2<f32>;
var<private> p11_nodeVar744 : vec4<f32>;
var<private> p11_nodeVar745 : vec4<f32>;
var<private> p11_nodeVar746 : vec4<f32>;
var<private> p11_nodeVar747 : vec2<f32>;
var<private> p11_nodeVar748 : vec2<f32>;
var<private> p11_nodeVar749 : vec2<f32>;
var<private> p11_nodeVar750 : vec2<f32>;
var<private> p11_nodeVar751 : vec2<f32>;
var<private> p11_nodeVar752 : vec2<f32>;
var<private> p11_nodeVar753 : vec2<f32>;
var<private> p11_nodeVar754 : vec2<f32>;
var<private> p11_nodeVar755 : vec4<f32>;
var<private> p11_nodeVar756 : vec2<f32>;
var<private> p11_nodeVar757 : vec2<f32>;
var<private> p11_nodeVar758 : vec2<f32>;
var<private> p11_nodeVar759 : vec4<f32>;
var<private> p11_nodeVar760 : vec4<f32>;
var<private> p11_nodeVar761 : vec4<f32>;
var<private> p11_nodeVar762 : vec2<f32>;
var<private> p11_nodeVar763 : vec2<f32>;
var<private> p11_nodeVar764 : vec2<f32>;
var<private> p11_nodeVar765 : vec2<f32>;
var<private> p11_nodeVar766 : vec2<f32>;
var<private> p11_nodeVar767 : vec2<f32>;
var<private> p11_nodeVar768 : vec2<f32>;
var<private> p11_nodeVar769 : vec4<f32>;
var<private> p11_nodeVar770 : vec2<f32>;
var<private> p11_nodeVar771 : vec2<f32>;
var<private> p11_nodeVar772 : vec2<f32>;
var<private> p11_nodeVar773 : vec4<f32>;
var<private> p11_nodeVar774 : vec4<f32>;
var<private> p11_nodeVar775 : vec4<f32>;
var<private> p11_nodeVar776 : vec2<f32>;
var<private> p11_nodeVar777 : vec2<f32>;
var<private> p11_nodeVar778 : vec2<f32>;
var<private> p11_nodeVar779 : vec2<f32>;
var<private> p11_nodeVar780 : vec2<f32>;
var<private> p11_nodeVar781 : vec2<f32>;
var<private> p11_nodeVar782 : vec2<f32>;
var<private> p11_nodeVar783 : vec2<f32>;
var<private> p11_nodeVar784 : vec4<f32>;
var<private> p11_nodeVar785 : vec2<f32>;
var<private> p11_nodeVar786 : vec2<f32>;
var<private> p11_nodeVar787 : vec2<f32>;
var<private> p11_nodeVar788 : vec4<f32>;
var<private> p11_nodeVar789 : vec4<f32>;
var<private> p11_nodeVar790 : vec4<f32>;
var<private> p11_nodeVar791 : vec2<f32>;
var<private> p11_nodeVar792 : vec2<f32>;
var<private> p11_nodeVar793 : vec2<f32>;
var<private> p11_nodeVar794 : vec2<f32>;
var<private> p11_nodeVar795 : vec2<f32>;
var<private> p11_nodeVar796 : vec2<f32>;
var<private> p11_nodeVar797 : vec2<f32>;
var<private> p11_nodeVar798 : vec4<f32>;
var<private> p11_nodeVar799 : vec2<f32>;
var<private> p11_nodeVar800 : vec2<f32>;
var<private> p11_nodeVar801 : vec2<f32>;
var<private> p11_nodeVar802 : vec4<f32>;
var<private> p11_nodeVar803 : vec4<f32>;
var<private> p11_nodeVar804 : vec4<f32>;
var<private> p11_nodeVar805 : vec2<f32>;
var<private> p11_nodeVar806 : vec2<f32>;
var<private> p11_nodeVar807 : vec2<f32>;
var<private> p11_nodeVar808 : vec2<f32>;
var<private> p11_nodeVar809 : vec2<f32>;
var<private> p11_nodeVar810 : vec2<f32>;
var<private> p11_nodeVar811 : vec2<f32>;
var<private> p11_nodeVar812 : vec2<f32>;
var<private> p11_nodeVar813 : vec4<f32>;
var<private> p11_nodeVar814 : vec2<f32>;
var<private> p11_nodeVar815 : vec2<f32>;
var<private> p11_nodeVar816 : vec2<f32>;
var<private> p11_nodeVar817 : vec4<f32>;
var<private> p11_nodeVar818 : vec4<f32>;
var<private> p11_nodeVar819 : vec4<f32>;
var<private> p11_nodeVar820 : vec2<f32>;
var<private> p11_nodeVar821 : vec2<f32>;
var<private> p11_nodeVar822 : vec2<f32>;
var<private> p11_nodeVar823 : vec2<f32>;
var<private> p11_nodeVar824 : vec2<f32>;
var<private> p11_nodeVar825 : vec2<f32>;
var<private> p11_nodeVar826 : vec2<f32>;
var<private> p11_nodeVar827 : vec4<f32>;
var<private> p11_nodeVar828 : vec2<f32>;
var<private> p11_nodeVar829 : vec2<f32>;
var<private> p11_nodeVar830 : vec2<f32>;
var<private> p11_nodeVar831 : vec4<f32>;
var<private> p11_nodeVar832 : vec4<f32>;
var<private> p11_nodeVar833 : vec4<f32>;
var<private> p11_nodeVar834 : vec2<f32>;
var<private> p11_nodeVar835 : vec2<f32>;
var<private> p11_nodeVar836 : vec2<f32>;
var<private> p11_nodeVar837 : vec2<f32>;
var<private> p11_nodeVar838 : vec2<f32>;
var<private> p11_nodeVar839 : vec2<f32>;
var<private> p11_nodeVar840 : vec2<f32>;
var<private> p11_nodeVar841 : vec2<f32>;
var<private> p11_nodeVar842 : vec4<f32>;
var<private> p11_nodeVar843 : vec2<f32>;
var<private> p11_nodeVar844 : vec2<f32>;
var<private> p11_nodeVar845 : vec2<f32>;
var<private> p11_nodeVar846 : vec4<f32>;
var<private> p11_nodeVar847 : vec4<f32>;
var<private> p11_nodeVar848 : vec4<f32>;
var<private> p11_nodeVar849 : vec2<f32>;
var<private> p11_nodeVar850 : vec2<f32>;
var<private> p11_nodeVar851 : vec2<f32>;
var<private> p11_nodeVar852 : vec2<f32>;
var<private> p11_nodeVar853 : vec2<f32>;
var<private> p11_nodeVar854 : vec2<f32>;
var<private> p11_nodeVar855 : vec2<f32>;
var<private> p11_nodeVar856 : vec4<f32>;
var<private> p11_nodeVar857 : vec2<f32>;
var<private> p11_nodeVar858 : vec2<f32>;
var<private> p11_nodeVar859 : vec2<f32>;
var<private> p11_nodeVar860 : vec4<f32>;
var<private> p11_nodeVar861 : vec4<f32>;
var<private> p11_nodeVar862 : vec4<f32>;
var<private> p11_nodeVar863 : vec2<f32>;
var<private> p11_nodeVar864 : vec2<f32>;
var<private> p11_nodeVar865 : vec2<f32>;
var<private> p11_nodeVar866 : vec2<f32>;
var<private> p11_nodeVar867 : vec2<f32>;
var<private> p11_nodeVar868 : vec2<f32>;
var<private> p11_nodeVar869 : vec2<f32>;
var<private> p11_nodeVar870 : vec2<f32>;
var<private> p11_nodeVar871 : vec4<f32>;
var<private> p11_nodeVar872 : vec2<f32>;
var<private> p11_nodeVar873 : vec2<f32>;
var<private> p11_nodeVar874 : vec2<f32>;
var<private> p11_nodeVar875 : vec4<f32>;
var<private> p11_nodeVar876 : vec4<f32>;
var<private> p11_nodeVar877 : vec4<f32>;
var<private> p11_nodeVar878 : vec2<f32>;
var<private> p11_nodeVar879 : vec2<f32>;
var<private> p11_nodeVar880 : vec2<f32>;
var<private> p11_nodeVar881 : vec2<f32>;
var<private> p11_nodeVar882 : vec2<f32>;
var<private> p11_nodeVar883 : vec2<f32>;
var<private> p11_nodeVar884 : vec2<f32>;
var<private> p11_nodeVar885 : vec4<f32>;
var<private> p11_nodeVar886 : vec2<f32>;
var<private> p11_nodeVar887 : vec2<f32>;
var<private> p11_nodeVar888 : vec2<f32>;
var<private> p11_nodeVar889 : vec4<f32>;
var<private> p11_nodeVar890 : vec4<f32>;
var<private> p11_nodeVar891 : vec4<f32>;
var<private> p11_nodeVar892 : vec2<f32>;
var<private> p11_nodeVar893 : vec2<f32>;
var<private> p11_nodeVar894 : vec2<f32>;
var<private> p11_nodeVar895 : vec2<f32>;
var<private> p11_nodeVar896 : vec2<f32>;
var<private> p11_nodeVar897 : vec2<f32>;
var<private> p11_nodeVar898 : vec2<f32>;
var<private> p11_nodeVar899 : vec2<f32>;
var<private> p11_nodeVar900 : vec4<f32>;
var<private> p11_nodeVar901 : vec2<f32>;
var<private> p11_nodeVar902 : vec2<f32>;
var<private> p11_nodeVar903 : vec2<f32>;
var<private> p11_nodeVar904 : vec4<f32>;
var<private> p11_nodeVar905 : vec4<f32>;
var<private> p11_nodeVar906 : vec4<f32>;
var<private> p11_nodeVar907 : vec2<f32>;
var<private> p11_nodeVar908 : vec2<f32>;
var<private> p11_nodeVar909 : vec2<f32>;
var<private> p11_nodeVar910 : vec2<f32>;
var<private> p11_nodeVar911 : vec2<f32>;
var<private> p11_nodeVar912 : vec2<f32>;
var<private> p11_nodeVar913 : vec2<f32>;
var<private> p11_nodeVar914 : vec4<f32>;
var<private> p11_nodeVar915 : vec2<f32>;
var<private> p11_nodeVar916 : vec2<f32>;
var<private> p11_nodeVar917 : vec2<f32>;
var<private> p11_nodeVar918 : vec4<f32>;
var<private> p11_nodeVar919 : vec4<f32>;
var<private> p11_nodeVar920 : vec4<f32>;
var<private> p11_nodeVar921 : vec2<f32>;
var<private> p11_nodeVar922 : vec2<f32>;
var<private> p11_nodeVar923 : vec2<f32>;
var<private> p11_nodeVar924 : vec2<f32>;
var<private> p11_nodeVar925 : vec2<f32>;
var<private> p11_nodeVar926 : vec2<f32>;
var<private> p11_nodeVar927 : vec2<f32>;
var<private> p11_nodeVar928 : vec2<f32>;
var<private> p11_nodeVar929 : vec4<f32>;
var<private> p11_nodeVar930 : vec2<f32>;
var<private> p11_nodeVar931 : vec2<f32>;
var<private> p11_nodeVar932 : vec2<f32>;
var<private> p11_nodeVar933 : vec4<f32>;
var<private> p11_nodeVar934 : vec4<f32>;
var<private> p11_nodeVar935 : vec4<f32>;
var<private> p11_nodeVar936 : vec2<f32>;
var<private> p11_nodeVar937 : vec2<f32>;
var<private> p11_nodeVar938 : vec2<f32>;
var<private> p11_nodeVar939 : vec2<f32>;
var<private> p11_nodeVar940 : vec2<f32>;
var<private> p11_nodeVar941 : vec2<f32>;
var<private> p11_nodeVar942 : vec2<f32>;
var<private> p11_nodeVar943 : vec4<f32>;
var<private> p11_nodeVar944 : vec2<f32>;
var<private> p11_nodeVar945 : vec2<f32>;
var<private> p11_nodeVar946 : vec2<f32>;
var<private> p11_nodeVar947 : vec4<f32>;
var<private> p11_nodeVar948 : vec4<f32>;
var<private> p11_nodeVar949 : vec4<f32>;
var<private> p11_nodeVar950 : vec2<f32>;
var<private> p11_nodeVar951 : vec2<f32>;
var<private> p11_nodeVar952 : vec2<f32>;
var<private> p11_nodeVar953 : vec2<f32>;
var<private> p11_nodeVar954 : vec2<f32>;
var<private> p11_nodeVar955 : vec2<f32>;
var<private> p11_nodeVar956 : vec2<f32>;
var<private> p11_nodeVar957 : vec2<f32>;
var<private> p11_nodeVar958 : vec4<f32>;
var<private> p11_nodeVar959 : vec2<f32>;
var<private> p11_nodeVar960 : vec2<f32>;
var<private> p11_nodeVar961 : vec2<f32>;
var<private> p11_nodeVar962 : vec4<f32>;
var<private> p11_nodeVar963 : vec4<f32>;
var<private> p11_nodeVar964 : vec4<f32>;
var<private> p11_nodeVar965 : vec2<f32>;
var<private> p11_nodeVar966 : vec2<f32>;
var<private> p11_nodeVar967 : vec2<f32>;
var<private> p11_nodeVar968 : vec2<f32>;
var<private> p11_nodeVar969 : vec2<f32>;
var<private> p11_nodeVar970 : vec2<f32>;
var<private> p11_nodeVar971 : vec2<f32>;
var<private> p11_nodeVar972 : vec4<f32>;
var<private> p11_nodeVar973 : vec2<f32>;
var<private> p11_nodeVar974 : vec2<f32>;
var<private> p11_nodeVar975 : vec2<f32>;
var<private> p11_nodeVar976 : vec4<f32>;
var<private> p11_nodeVar977 : vec4<f32>;
var<private> p11_nodeVar978 : vec4<f32>;
var<private> p11_nodeVar979 : vec2<f32>;
var<private> p11_nodeVar980 : vec2<f32>;
var<private> p11_nodeVar981 : vec2<f32>;
var<private> p11_nodeVar982 : vec2<f32>;
var<private> p11_nodeVar983 : vec2<f32>;
var<private> p11_nodeVar984 : vec2<f32>;
var<private> p11_nodeVar985 : vec2<f32>;
var<private> p11_nodeVar986 : vec4<f32>;
var<private> p11_nodeVar987 : vec2<f32>;
var<private> p11_nodeVar988 : vec2<f32>;
var<private> p11_nodeVar989 : vec2<f32>;
var<private> p11_nodeVar990 : vec4<f32>;
var<private> p11_nodeVar991 : vec4<f32>;
var<private> p11_nodeVar992 : vec4<f32>;
var<private> p11_nodeVar993 : vec4<f32>;
var<private> p11_nodeVar994 : f32;
var<private> p11_nodeVar995 : f32;
var<private> p11_nodeVar996 : f32;
var<private> p11_nodeVar997 : vec2<f32>;
var<private> p11_nodeVar998 : vec4<f32>;
var<private> p11_nodeVar999 : vec2<f32>;
var<private> p11_nodeVar1000 : vec2<f32>;
var<private> p11_nodeVar1001 : vec2<f32>;
var<private> p11_nodeVar1002 : vec2<f32>;
var<private> p11_nodeVar1003 : vec2<f32>;
var<private> p11_nodeVar1004 : vec2<f32>;
var<private> p11_nodeVar1005 : vec2<f32>;
var<private> p11_nodeVar1006 : vec4<f32>;
var<private> p11_nodeVar1007 : vec2<f32>;
var<private> p11_nodeVar1008 : vec2<f32>;
var<private> p11_nodeVar1009 : vec2<f32>;
var<private> p11_nodeVar1010 : vec4<f32>;
var<private> p11_nodeVar1011 : vec4<f32>;
var<private> p11_nodeVar1012 : vec4<f32>;
var<private> p11_nodeVar1013 : vec2<f32>;
var<private> p11_nodeVar1014 : vec2<f32>;
var<private> p11_nodeVar1015 : vec2<f32>;
var<private> p11_nodeVar1016 : vec2<f32>;
var<private> p11_nodeVar1017 : vec2<f32>;
var<private> p11_nodeVar1018 : vec2<f32>;
var<private> p11_nodeVar1019 : vec2<f32>;
var<private> p11_nodeVar1020 : vec2<f32>;
var<private> p11_nodeVar1021 : vec4<f32>;
var<private> p11_nodeVar1022 : vec2<f32>;
var<private> p11_nodeVar1023 : vec2<f32>;
var<private> p11_nodeVar1024 : vec2<f32>;
var<private> p11_nodeVar1025 : vec4<f32>;
var<private> p11_nodeVar1026 : vec4<f32>;
var<private> p11_nodeVar1027 : vec4<f32>;
var<private> p11_nodeVar1028 : vec2<f32>;
var<private> p11_nodeVar1029 : vec2<f32>;
var<private> p11_nodeVar1030 : vec2<f32>;
var<private> p11_nodeVar1031 : vec2<f32>;
var<private> p11_nodeVar1032 : vec2<f32>;
var<private> p11_nodeVar1033 : vec2<f32>;
var<private> p11_nodeVar1034 : vec2<f32>;
var<private> p11_nodeVar1035 : vec4<f32>;
var<private> p11_nodeVar1036 : vec2<f32>;
var<private> p11_nodeVar1037 : vec2<f32>;
var<private> p11_nodeVar1038 : vec2<f32>;
var<private> p11_nodeVar1039 : vec4<f32>;
var<private> p11_nodeVar1040 : vec4<f32>;
var<private> p11_nodeVar1041 : vec4<f32>;
var<private> p11_nodeVar1042 : vec2<f32>;
var<private> p11_nodeVar1043 : vec2<f32>;
var<private> p11_nodeVar1044 : vec2<f32>;
var<private> p11_nodeVar1045 : vec2<f32>;
var<private> p11_nodeVar1046 : vec2<f32>;
var<private> p11_nodeVar1047 : vec2<f32>;
var<private> p11_nodeVar1048 : vec2<f32>;
var<private> p11_nodeVar1049 : vec2<f32>;
var<private> p11_nodeVar1050 : vec4<f32>;
var<private> p11_nodeVar1051 : vec2<f32>;
var<private> p11_nodeVar1052 : vec2<f32>;
var<private> p11_nodeVar1053 : vec2<f32>;
var<private> p11_nodeVar1054 : vec4<f32>;
var<private> p11_nodeVar1055 : vec4<f32>;
var<private> p11_nodeVar1056 : vec4<f32>;
var<private> p11_nodeVar1057 : vec2<f32>;
var<private> p11_nodeVar1058 : vec2<f32>;
var<private> p11_nodeVar1059 : vec2<f32>;
var<private> p11_nodeVar1060 : vec2<f32>;
var<private> p11_nodeVar1061 : vec2<f32>;
var<private> p11_nodeVar1062 : vec2<f32>;
var<private> p11_nodeVar1063 : vec2<f32>;
var<private> p11_nodeVar1064 : vec4<f32>;
var<private> p11_nodeVar1065 : vec2<f32>;
var<private> p11_nodeVar1066 : vec2<f32>;
var<private> p11_nodeVar1067 : vec2<f32>;
var<private> p11_nodeVar1068 : vec4<f32>;
var<private> p11_nodeVar1069 : vec4<f32>;
var<private> p11_nodeVar1070 : vec4<f32>;
var<private> p11_nodeVar1071 : vec2<f32>;
var<private> p11_nodeVar1072 : vec2<f32>;
var<private> p11_nodeVar1073 : vec2<f32>;
var<private> p11_nodeVar1074 : vec2<f32>;
var<private> p11_nodeVar1075 : vec2<f32>;
var<private> p11_nodeVar1076 : vec2<f32>;
var<private> p11_nodeVar1077 : vec2<f32>;
var<private> p11_nodeVar1078 : vec2<f32>;
var<private> p11_nodeVar1079 : vec4<f32>;
var<private> p11_nodeVar1080 : vec2<f32>;
var<private> p11_nodeVar1081 : vec2<f32>;
var<private> p11_nodeVar1082 : vec2<f32>;
var<private> p11_nodeVar1083 : vec4<f32>;
var<private> p11_nodeVar1084 : vec4<f32>;
var<private> p11_nodeVar1085 : vec4<f32>;
var<private> p11_nodeVar1086 : vec2<f32>;
var<private> p11_nodeVar1087 : vec2<f32>;
var<private> p11_nodeVar1088 : vec2<f32>;
var<private> p11_nodeVar1089 : vec2<f32>;
var<private> p11_nodeVar1090 : vec2<f32>;
var<private> p11_nodeVar1091 : vec2<f32>;
var<private> p11_nodeVar1092 : vec2<f32>;
var<private> p11_nodeVar1093 : vec4<f32>;
var<private> p11_nodeVar1094 : vec2<f32>;
var<private> p11_nodeVar1095 : vec2<f32>;
var<private> p11_nodeVar1096 : vec2<f32>;
var<private> p11_nodeVar1097 : vec4<f32>;
var<private> p11_nodeVar1098 : vec4<f32>;
var<private> p11_nodeVar1099 : vec4<f32>;
var<private> p11_nodeVar1100 : vec2<f32>;
var<private> p11_nodeVar1101 : vec2<f32>;
var<private> p11_nodeVar1102 : vec2<f32>;
var<private> p11_nodeVar1103 : vec2<f32>;
var<private> p11_nodeVar1104 : vec2<f32>;
var<private> p11_nodeVar1105 : vec2<f32>;
var<private> p11_nodeVar1106 : vec2<f32>;
var<private> p11_nodeVar1107 : vec2<f32>;
var<private> p11_nodeVar1108 : vec4<f32>;
var<private> p11_nodeVar1109 : vec2<f32>;
var<private> p11_nodeVar1110 : vec2<f32>;
var<private> p11_nodeVar1111 : vec2<f32>;
var<private> p11_nodeVar1112 : vec4<f32>;
var<private> p11_nodeVar1113 : vec4<f32>;
var<private> p11_nodeVar1114 : vec4<f32>;
var<private> p11_nodeVar1115 : vec2<f32>;
var<private> p11_nodeVar1116 : vec2<f32>;
var<private> p11_nodeVar1117 : vec2<f32>;
var<private> p11_nodeVar1118 : vec2<f32>;
var<private> p11_nodeVar1119 : vec2<f32>;
var<private> p11_nodeVar1120 : vec2<f32>;
var<private> p11_nodeVar1121 : vec2<f32>;
var<private> p11_nodeVar1122 : vec4<f32>;
var<private> p11_nodeVar1123 : vec2<f32>;
var<private> p11_nodeVar1124 : vec2<f32>;
var<private> p11_nodeVar1125 : vec2<f32>;
var<private> p11_nodeVar1126 : vec4<f32>;
var<private> p11_nodeVar1127 : vec4<f32>;
var<private> p11_nodeVar1128 : vec4<f32>;
var<private> p11_nodeVar1129 : vec2<f32>;
var<private> p11_nodeVar1130 : vec2<f32>;
var<private> p11_nodeVar1131 : vec2<f32>;
var<private> p11_nodeVar1132 : vec2<f32>;
var<private> p11_nodeVar1133 : vec2<f32>;
var<private> p11_nodeVar1134 : vec2<f32>;
var<private> p11_nodeVar1135 : vec2<f32>;
var<private> p11_nodeVar1136 : vec2<f32>;
var<private> p11_nodeVar1137 : vec4<f32>;
var<private> p11_nodeVar1138 : vec2<f32>;
var<private> p11_nodeVar1139 : vec2<f32>;
var<private> p11_nodeVar1140 : vec2<f32>;
var<private> p11_nodeVar1141 : vec4<f32>;
var<private> p11_nodeVar1142 : vec4<f32>;
var<private> p11_nodeVar1143 : vec4<f32>;
var<private> p11_nodeVar1144 : vec2<f32>;
var<private> p11_nodeVar1145 : vec2<f32>;
var<private> p11_nodeVar1146 : vec2<f32>;
var<private> p11_nodeVar1147 : vec2<f32>;
var<private> p11_nodeVar1148 : vec2<f32>;
var<private> p11_nodeVar1149 : vec2<f32>;
var<private> p11_nodeVar1150 : vec2<f32>;
var<private> p11_nodeVar1151 : vec4<f32>;
var<private> p11_nodeVar1152 : vec2<f32>;
var<private> p11_nodeVar1153 : vec2<f32>;
var<private> p11_nodeVar1154 : vec2<f32>;
var<private> p11_nodeVar1155 : vec4<f32>;
var<private> p11_nodeVar1156 : vec4<f32>;
var<private> p11_nodeVar1157 : vec4<f32>;
var<private> p11_nodeVar1158 : vec2<f32>;
var<private> p11_nodeVar1159 : vec2<f32>;
var<private> p11_nodeVar1160 : vec2<f32>;
var<private> p11_nodeVar1161 : vec2<f32>;
var<private> p11_nodeVar1162 : vec2<f32>;
var<private> p11_nodeVar1163 : vec2<f32>;
var<private> p11_nodeVar1164 : vec2<f32>;
var<private> p11_nodeVar1165 : vec2<f32>;
var<private> p11_nodeVar1166 : vec4<f32>;
var<private> p11_nodeVar1167 : vec2<f32>;
var<private> p11_nodeVar1168 : vec2<f32>;
var<private> p11_nodeVar1169 : vec2<f32>;
var<private> p11_nodeVar1170 : vec4<f32>;
var<private> p11_nodeVar1171 : vec4<f32>;
var<private> p11_nodeVar1172 : vec4<f32>;
var<private> p11_nodeVar1173 : vec2<f32>;
var<private> p11_nodeVar1174 : vec2<f32>;
var<private> p11_nodeVar1175 : vec2<f32>;
var<private> p11_nodeVar1176 : vec2<f32>;
var<private> p11_nodeVar1177 : vec2<f32>;
var<private> p11_nodeVar1178 : vec2<f32>;
var<private> p11_nodeVar1179 : vec2<f32>;
var<private> p11_nodeVar1180 : vec4<f32>;
var<private> p11_nodeVar1181 : vec2<f32>;
var<private> p11_nodeVar1182 : vec2<f32>;
var<private> p11_nodeVar1183 : vec2<f32>;
var<private> p11_nodeVar1184 : vec4<f32>;
var<private> p11_nodeVar1185 : vec4<f32>;
var<private> p11_nodeVar1186 : vec4<f32>;
var<private> p11_nodeVar1187 : vec2<f32>;
var<private> p11_nodeVar1188 : vec2<f32>;
var<private> p11_nodeVar1189 : vec2<f32>;
var<private> p11_nodeVar1190 : vec2<f32>;
var<private> p11_nodeVar1191 : vec2<f32>;
var<private> p11_nodeVar1192 : vec2<f32>;
var<private> p11_nodeVar1193 : vec2<f32>;
var<private> p11_nodeVar1194 : vec2<f32>;
var<private> p11_nodeVar1195 : vec4<f32>;
var<private> p11_nodeVar1196 : vec2<f32>;
var<private> p11_nodeVar1197 : vec2<f32>;
var<private> p11_nodeVar1198 : vec2<f32>;
var<private> p11_nodeVar1199 : vec4<f32>;
var<private> p11_nodeVar1200 : vec4<f32>;
var<private> p11_nodeVar1201 : vec4<f32>;
var<private> p11_nodeVar1202 : vec2<f32>;
var<private> p11_nodeVar1203 : vec2<f32>;
var<private> p11_nodeVar1204 : vec2<f32>;
var<private> p11_nodeVar1205 : vec2<f32>;
var<private> p11_nodeVar1206 : vec2<f32>;
var<private> p11_nodeVar1207 : vec2<f32>;
var<private> p11_nodeVar1208 : vec2<f32>;
var<private> p11_nodeVar1209 : vec4<f32>;
var<private> p11_nodeVar1210 : vec2<f32>;
var<private> p11_nodeVar1211 : vec2<f32>;
var<private> p11_nodeVar1212 : vec2<f32>;
var<private> p11_nodeVar1213 : vec4<f32>;
var<private> p11_nodeVar1214 : vec4<f32>;
var<private> p11_nodeVar1215 : vec4<f32>;
var<private> p11_nodeVar1216 : vec2<f32>;
var<private> p11_nodeVar1217 : vec2<f32>;
var<private> p11_nodeVar1218 : vec2<f32>;
var<private> p11_nodeVar1219 : vec2<f32>;
var<private> p11_nodeVar1220 : vec2<f32>;
var<private> p11_nodeVar1221 : vec2<f32>;
var<private> p11_nodeVar1222 : vec2<f32>;
var<private> p11_nodeVar1223 : vec2<f32>;
var<private> p11_nodeVar1224 : vec4<f32>;
var<private> p11_nodeVar1225 : vec2<f32>;
var<private> p11_nodeVar1226 : vec2<f32>;
var<private> p11_nodeVar1227 : vec2<f32>;
var<private> p11_nodeVar1228 : vec4<f32>;
var<private> p11_nodeVar1229 : vec4<f32>;
var<private> p11_nodeVar1230 : vec4<f32>;
var<private> p11_nodeVar1231 : vec2<f32>;
var<private> p11_nodeVar1232 : vec2<f32>;
var<private> p11_nodeVar1233 : vec2<f32>;
var<private> p11_nodeVar1234 : vec2<f32>;
var<private> p11_nodeVar1235 : vec2<f32>;
var<private> p11_nodeVar1236 : vec2<f32>;
var<private> p11_nodeVar1237 : vec2<f32>;
var<private> p11_nodeVar1238 : vec4<f32>;
var<private> p11_nodeVar1239 : vec2<f32>;
var<private> p11_nodeVar1240 : vec2<f32>;
var<private> p11_nodeVar1241 : vec2<f32>;
var<private> p11_nodeVar1242 : vec4<f32>;
var<private> p11_nodeVar1243 : vec4<f32>;
var<private> p11_nodeVar1244 : vec4<f32>;
var<private> p11_nodeVar1245 : vec2<f32>;
var<private> p11_nodeVar1246 : vec2<f32>;
var<private> p11_nodeVar1247 : vec2<f32>;
var<private> p11_nodeVar1248 : vec2<f32>;
var<private> p11_nodeVar1249 : vec2<f32>;
var<private> p11_nodeVar1250 : vec2<f32>;
var<private> p11_nodeVar1251 : vec2<f32>;
var<private> p11_nodeVar1252 : vec2<f32>;
var<private> p11_nodeVar1253 : vec4<f32>;
var<private> p11_nodeVar1254 : vec2<f32>;
var<private> p11_nodeVar1255 : vec2<f32>;
var<private> p11_nodeVar1256 : vec2<f32>;
var<private> p11_nodeVar1257 : vec4<f32>;
var<private> p11_nodeVar1258 : vec4<f32>;
var<private> p11_nodeVar1259 : vec4<f32>;
var<private> p11_nodeVar1260 : vec2<f32>;
var<private> p11_nodeVar1261 : vec2<f32>;
var<private> p11_nodeVar1262 : vec2<f32>;
var<private> p11_nodeVar1263 : vec2<f32>;
var<private> p11_nodeVar1264 : vec2<f32>;
var<private> p11_nodeVar1265 : vec2<f32>;
var<private> p11_nodeVar1266 : vec2<f32>;
var<private> p11_nodeVar1267 : vec4<f32>;
var<private> p11_nodeVar1268 : vec2<f32>;
var<private> p11_nodeVar1269 : vec2<f32>;
var<private> p11_nodeVar1270 : vec2<f32>;
var<private> p11_nodeVar1271 : vec4<f32>;
var<private> p11_nodeVar1272 : vec4<f32>;
var<private> p11_nodeVar1273 : vec4<f32>;
var<private> p11_nodeVar1274 : vec2<f32>;
var<private> p11_nodeVar1275 : vec2<f32>;
var<private> p11_nodeVar1276 : vec2<f32>;
var<private> p11_nodeVar1277 : vec2<f32>;
var<private> p11_nodeVar1278 : vec2<f32>;
var<private> p11_nodeVar1279 : vec2<f32>;
var<private> p11_nodeVar1280 : vec2<f32>;
var<private> p11_nodeVar1281 : vec4<f32>;
var<private> p11_nodeVar1282 : vec2<f32>;
var<private> p11_nodeVar1283 : vec2<f32>;
var<private> p11_nodeVar1284 : vec2<f32>;
var<private> p11_nodeVar1285 : vec4<f32>;
var<private> p11_nodeVar1286 : vec4<f32>;
var<private> p11_nodeVar1287 : vec4<f32>;
var<private> p11_nodeVar1288 : vec4<f32>;
var<private> p11_nodeVar1289 : f32;
var<private> p11_nodeVar1290 : f32;
var<private> p11_nodeVar1291 : f32;
var<private> p11_nodeVar1292 : vec2<f32>;
var<private> p11_nodeVar1293 : vec4<f32>;
var<private> p11_nodeVar1294 : vec2<f32>;
var<private> p11_nodeVar1295 : vec2<f32>;
var<private> p11_nodeVar1296 : vec2<f32>;
var<private> p11_nodeVar1297 : vec2<f32>;
var<private> p11_nodeVar1298 : vec2<f32>;
var<private> p11_nodeVar1299 : vec2<f32>;
var<private> p11_nodeVar1300 : vec2<f32>;
var<private> p11_nodeVar1301 : vec4<f32>;
var<private> p11_nodeVar1302 : vec2<f32>;
var<private> p11_nodeVar1303 : vec2<f32>;
var<private> p11_nodeVar1304 : vec2<f32>;
var<private> p11_nodeVar1305 : vec4<f32>;
var<private> p11_nodeVar1306 : vec4<f32>;
var<private> p11_nodeVar1307 : vec4<f32>;
var<private> p11_nodeVar1308 : vec2<f32>;
var<private> p11_nodeVar1309 : vec2<f32>;
var<private> p11_nodeVar1310 : vec2<f32>;
var<private> p11_nodeVar1311 : vec2<f32>;
var<private> p11_nodeVar1312 : vec2<f32>;
var<private> p11_nodeVar1313 : vec2<f32>;
var<private> p11_nodeVar1314 : vec2<f32>;
var<private> p11_nodeVar1315 : vec2<f32>;
var<private> p11_nodeVar1316 : vec4<f32>;
var<private> p11_nodeVar1317 : vec2<f32>;
var<private> p11_nodeVar1318 : vec2<f32>;
var<private> p11_nodeVar1319 : vec2<f32>;
var<private> p11_nodeVar1320 : vec4<f32>;
var<private> p11_nodeVar1321 : vec4<f32>;
var<private> p11_nodeVar1322 : vec4<f32>;
var<private> p11_nodeVar1323 : vec2<f32>;
var<private> p11_nodeVar1324 : vec2<f32>;
var<private> p11_nodeVar1325 : vec2<f32>;
var<private> p11_nodeVar1326 : vec2<f32>;
var<private> p11_nodeVar1327 : vec2<f32>;
var<private> p11_nodeVar1328 : vec2<f32>;
var<private> p11_nodeVar1329 : vec2<f32>;
var<private> p11_nodeVar1330 : vec4<f32>;
var<private> p11_nodeVar1331 : vec2<f32>;
var<private> p11_nodeVar1332 : vec2<f32>;
var<private> p11_nodeVar1333 : vec2<f32>;
var<private> p11_nodeVar1334 : vec4<f32>;
var<private> p11_nodeVar1335 : vec4<f32>;
var<private> p11_nodeVar1336 : vec4<f32>;
var<private> p11_nodeVar1337 : vec2<f32>;
var<private> p11_nodeVar1338 : vec2<f32>;
var<private> p11_nodeVar1339 : vec2<f32>;
var<private> p11_nodeVar1340 : vec2<f32>;
var<private> p11_nodeVar1341 : vec2<f32>;
var<private> p11_nodeVar1342 : vec2<f32>;
var<private> p11_nodeVar1343 : vec2<f32>;
var<private> p11_nodeVar1344 : vec2<f32>;
var<private> p11_nodeVar1345 : vec4<f32>;
var<private> p11_nodeVar1346 : vec2<f32>;
var<private> p11_nodeVar1347 : vec2<f32>;
var<private> p11_nodeVar1348 : vec2<f32>;
var<private> p11_nodeVar1349 : vec4<f32>;
var<private> p11_nodeVar1350 : vec4<f32>;
var<private> p11_nodeVar1351 : vec4<f32>;
var<private> p11_nodeVar1352 : vec2<f32>;
var<private> p11_nodeVar1353 : vec2<f32>;
var<private> p11_nodeVar1354 : vec2<f32>;
var<private> p11_nodeVar1355 : vec2<f32>;
var<private> p11_nodeVar1356 : vec2<f32>;
var<private> p11_nodeVar1357 : vec2<f32>;
var<private> p11_nodeVar1358 : vec2<f32>;
var<private> p11_nodeVar1359 : vec4<f32>;
var<private> p11_nodeVar1360 : vec2<f32>;
var<private> p11_nodeVar1361 : vec2<f32>;
var<private> p11_nodeVar1362 : vec2<f32>;
var<private> p11_nodeVar1363 : vec4<f32>;
var<private> p11_nodeVar1364 : vec4<f32>;
var<private> p11_nodeVar1365 : vec4<f32>;
var<private> p11_nodeVar1366 : vec2<f32>;
var<private> p11_nodeVar1367 : vec2<f32>;
var<private> p11_nodeVar1368 : vec2<f32>;
var<private> p11_nodeVar1369 : vec2<f32>;
var<private> p11_nodeVar1370 : vec2<f32>;
var<private> p11_nodeVar1371 : vec2<f32>;
var<private> p11_nodeVar1372 : vec2<f32>;
var<private> p11_nodeVar1373 : vec2<f32>;
var<private> p11_nodeVar1374 : vec4<f32>;
var<private> p11_nodeVar1375 : vec2<f32>;
var<private> p11_nodeVar1376 : vec2<f32>;
var<private> p11_nodeVar1377 : vec2<f32>;
var<private> p11_nodeVar1378 : vec4<f32>;
var<private> p11_nodeVar1379 : vec4<f32>;
var<private> p11_nodeVar1380 : vec4<f32>;
var<private> p11_nodeVar1381 : vec2<f32>;
var<private> p11_nodeVar1382 : vec2<f32>;
var<private> p11_nodeVar1383 : vec2<f32>;
var<private> p11_nodeVar1384 : vec2<f32>;
var<private> p11_nodeVar1385 : vec2<f32>;
var<private> p11_nodeVar1386 : vec2<f32>;
var<private> p11_nodeVar1387 : vec2<f32>;
var<private> p11_nodeVar1388 : vec4<f32>;
var<private> p11_nodeVar1389 : vec2<f32>;
var<private> p11_nodeVar1390 : vec2<f32>;
var<private> p11_nodeVar1391 : vec2<f32>;
var<private> p11_nodeVar1392 : vec4<f32>;
var<private> p11_nodeVar1393 : vec4<f32>;
var<private> p11_nodeVar1394 : vec4<f32>;
var<private> p11_nodeVar1395 : vec2<f32>;
var<private> p11_nodeVar1396 : vec2<f32>;
var<private> p11_nodeVar1397 : vec2<f32>;
var<private> p11_nodeVar1398 : vec2<f32>;
var<private> p11_nodeVar1399 : vec2<f32>;
var<private> p11_nodeVar1400 : vec2<f32>;
var<private> p11_nodeVar1401 : vec2<f32>;
var<private> p11_nodeVar1402 : vec2<f32>;
var<private> p11_nodeVar1403 : vec4<f32>;
var<private> p11_nodeVar1404 : vec2<f32>;
var<private> p11_nodeVar1405 : vec2<f32>;
var<private> p11_nodeVar1406 : vec2<f32>;
var<private> p11_nodeVar1407 : vec4<f32>;
var<private> p11_nodeVar1408 : vec4<f32>;
var<private> p11_nodeVar1409 : vec4<f32>;
var<private> p11_nodeVar1410 : vec2<f32>;
var<private> p11_nodeVar1411 : vec2<f32>;
var<private> p11_nodeVar1412 : vec2<f32>;
var<private> p11_nodeVar1413 : vec2<f32>;
var<private> p11_nodeVar1414 : vec2<f32>;
var<private> p11_nodeVar1415 : vec2<f32>;
var<private> p11_nodeVar1416 : vec2<f32>;
var<private> p11_nodeVar1417 : vec4<f32>;
var<private> p11_nodeVar1418 : vec2<f32>;
var<private> p11_nodeVar1419 : vec2<f32>;
var<private> p11_nodeVar1420 : vec2<f32>;
var<private> p11_nodeVar1421 : vec4<f32>;
var<private> p11_nodeVar1422 : vec4<f32>;
var<private> p11_nodeVar1423 : vec4<f32>;
var<private> p11_nodeVar1424 : vec2<f32>;
var<private> p11_nodeVar1425 : vec2<f32>;
var<private> p11_nodeVar1426 : vec2<f32>;
var<private> p11_nodeVar1427 : vec2<f32>;
var<private> p11_nodeVar1428 : vec2<f32>;
var<private> p11_nodeVar1429 : vec2<f32>;
var<private> p11_nodeVar1430 : vec2<f32>;
var<private> p11_nodeVar1431 : vec2<f32>;
var<private> p11_nodeVar1432 : vec4<f32>;
var<private> p11_nodeVar1433 : vec2<f32>;
var<private> p11_nodeVar1434 : vec2<f32>;
var<private> p11_nodeVar1435 : vec2<f32>;
var<private> p11_nodeVar1436 : vec4<f32>;
var<private> p11_nodeVar1437 : vec4<f32>;
var<private> p11_nodeVar1438 : vec4<f32>;
var<private> p11_nodeVar1439 : vec2<f32>;
var<private> p11_nodeVar1440 : vec2<f32>;
var<private> p11_nodeVar1441 : vec2<f32>;
var<private> p11_nodeVar1442 : vec2<f32>;
var<private> p11_nodeVar1443 : vec2<f32>;
var<private> p11_nodeVar1444 : vec2<f32>;
var<private> p11_nodeVar1445 : vec2<f32>;
var<private> p11_nodeVar1446 : vec4<f32>;
var<private> p11_nodeVar1447 : vec2<f32>;
var<private> p11_nodeVar1448 : vec2<f32>;
var<private> p11_nodeVar1449 : vec2<f32>;
var<private> p11_nodeVar1450 : vec4<f32>;
var<private> p11_nodeVar1451 : vec4<f32>;
var<private> p11_nodeVar1452 : vec4<f32>;
var<private> p11_nodeVar1453 : vec2<f32>;
var<private> p11_nodeVar1454 : vec2<f32>;
var<private> p11_nodeVar1455 : vec2<f32>;
var<private> p11_nodeVar1456 : vec2<f32>;
var<private> p11_nodeVar1457 : vec2<f32>;
var<private> p11_nodeVar1458 : vec2<f32>;
var<private> p11_nodeVar1459 : vec2<f32>;
var<private> p11_nodeVar1460 : vec2<f32>;
var<private> p11_nodeVar1461 : vec4<f32>;
var<private> p11_nodeVar1462 : vec2<f32>;
var<private> p11_nodeVar1463 : vec2<f32>;
var<private> p11_nodeVar1464 : vec2<f32>;
var<private> p11_nodeVar1465 : vec4<f32>;
var<private> p11_nodeVar1466 : vec4<f32>;
var<private> p11_nodeVar1467 : vec4<f32>;
var<private> p11_nodeVar1468 : vec2<f32>;
var<private> p11_nodeVar1469 : vec2<f32>;
var<private> p11_nodeVar1470 : vec2<f32>;
var<private> p11_nodeVar1471 : vec2<f32>;
var<private> p11_nodeVar1472 : vec2<f32>;
var<private> p11_nodeVar1473 : vec2<f32>;
var<private> p11_nodeVar1474 : vec2<f32>;
var<private> p11_nodeVar1475 : vec4<f32>;
var<private> p11_nodeVar1476 : vec2<f32>;
var<private> p11_nodeVar1477 : vec2<f32>;
var<private> p11_nodeVar1478 : vec2<f32>;
var<private> p11_nodeVar1479 : vec4<f32>;
var<private> p11_nodeVar1480 : vec4<f32>;
var<private> p11_nodeVar1481 : vec4<f32>;
var<private> p11_nodeVar1482 : vec2<f32>;
var<private> p11_nodeVar1483 : vec2<f32>;
var<private> p11_nodeVar1484 : vec2<f32>;
var<private> p11_nodeVar1485 : vec2<f32>;
var<private> p11_nodeVar1486 : vec2<f32>;
var<private> p11_nodeVar1487 : vec2<f32>;
var<private> p11_nodeVar1488 : vec2<f32>;
var<private> p11_nodeVar1489 : vec2<f32>;
var<private> p11_nodeVar1490 : vec4<f32>;
var<private> p11_nodeVar1491 : vec2<f32>;
var<private> p11_nodeVar1492 : vec2<f32>;
var<private> p11_nodeVar1493 : vec2<f32>;
var<private> p11_nodeVar1494 : vec4<f32>;
var<private> p11_nodeVar1495 : vec4<f32>;
var<private> p11_nodeVar1496 : vec4<f32>;
var<private> p11_nodeVar1497 : vec2<f32>;
var<private> p11_nodeVar1498 : vec2<f32>;
var<private> p11_nodeVar1499 : vec2<f32>;
var<private> p11_nodeVar1500 : vec2<f32>;
var<private> p11_nodeVar1501 : vec2<f32>;
var<private> p11_nodeVar1502 : vec2<f32>;
var<private> p11_nodeVar1503 : vec2<f32>;
var<private> p11_nodeVar1504 : vec4<f32>;
var<private> p11_nodeVar1505 : vec2<f32>;
var<private> p11_nodeVar1506 : vec2<f32>;
var<private> p11_nodeVar1507 : vec2<f32>;
var<private> p11_nodeVar1508 : vec4<f32>;
var<private> p11_nodeVar1509 : vec4<f32>;
var<private> p11_nodeVar1510 : vec4<f32>;
var<private> p11_nodeVar1511 : vec2<f32>;
var<private> p11_nodeVar1512 : vec2<f32>;
var<private> p11_nodeVar1513 : vec2<f32>;
var<private> p11_nodeVar1514 : vec2<f32>;
var<private> p11_nodeVar1515 : vec2<f32>;
var<private> p11_nodeVar1516 : vec2<f32>;
var<private> p11_nodeVar1517 : vec2<f32>;
var<private> p11_nodeVar1518 : vec2<f32>;
var<private> p11_nodeVar1519 : vec4<f32>;
var<private> p11_nodeVar1520 : vec2<f32>;
var<private> p11_nodeVar1521 : vec2<f32>;
var<private> p11_nodeVar1522 : vec2<f32>;
var<private> p11_nodeVar1523 : vec4<f32>;
var<private> p11_nodeVar1524 : vec4<f32>;
var<private> p11_nodeVar1525 : vec4<f32>;
var<private> p11_nodeVar1526 : vec2<f32>;
var<private> p11_nodeVar1527 : vec2<f32>;
var<private> p11_nodeVar1528 : vec2<f32>;
var<private> p11_nodeVar1529 : vec2<f32>;
var<private> p11_nodeVar1530 : vec2<f32>;
var<private> p11_nodeVar1531 : vec2<f32>;
var<private> p11_nodeVar1532 : vec2<f32>;
var<private> p11_nodeVar1533 : vec4<f32>;
var<private> p11_nodeVar1534 : vec2<f32>;
var<private> p11_nodeVar1535 : vec2<f32>;
var<private> p11_nodeVar1536 : vec2<f32>;
var<private> p11_nodeVar1537 : vec4<f32>;
var<private> p11_nodeVar1538 : vec4<f32>;
var<private> p11_nodeVar1539 : vec4<f32>;
var<private> p11_nodeVar1540 : vec2<f32>;
var<private> p11_nodeVar1541 : vec2<f32>;
var<private> p11_nodeVar1542 : vec2<f32>;
var<private> p11_nodeVar1543 : vec2<f32>;
var<private> p11_nodeVar1544 : vec2<f32>;
var<private> p11_nodeVar1545 : vec2<f32>;
var<private> p11_nodeVar1546 : vec2<f32>;
var<private> p11_nodeVar1547 : vec2<f32>;
var<private> p11_nodeVar1548 : vec4<f32>;
var<private> p11_nodeVar1549 : vec2<f32>;
var<private> p11_nodeVar1550 : vec2<f32>;
var<private> p11_nodeVar1551 : vec2<f32>;
var<private> p11_nodeVar1552 : vec4<f32>;
var<private> p11_nodeVar1553 : vec4<f32>;
var<private> p11_nodeVar1554 : vec4<f32>;
var<private> p11_nodeVar1555 : vec2<f32>;
var<private> p11_nodeVar1556 : vec2<f32>;
var<private> p11_nodeVar1557 : vec2<f32>;
var<private> p11_nodeVar1558 : vec2<f32>;
var<private> p11_nodeVar1559 : vec2<f32>;
var<private> p11_nodeVar1560 : vec2<f32>;
var<private> p11_nodeVar1561 : vec2<f32>;
var<private> p11_nodeVar1562 : vec4<f32>;
var<private> p11_nodeVar1563 : vec2<f32>;
var<private> p11_nodeVar1564 : vec2<f32>;
var<private> p11_nodeVar1565 : vec2<f32>;
var<private> p11_nodeVar1566 : vec4<f32>;
var<private> p11_nodeVar1567 : vec4<f32>;
var<private> p11_nodeVar1568 : vec4<f32>;
var<private> p11_nodeVar1569 : vec2<f32>;
var<private> p11_nodeVar1570 : vec2<f32>;
var<private> p11_nodeVar1571 : vec2<f32>;
var<private> p11_nodeVar1572 : vec2<f32>;
var<private> p11_nodeVar1573 : vec2<f32>;
var<private> p11_nodeVar1574 : vec2<f32>;
var<private> p11_nodeVar1575 : vec2<f32>;
var<private> p11_nodeVar1576 : vec4<f32>;
var<private> p11_nodeVar1577 : vec2<f32>;
var<private> p11_nodeVar1578 : vec2<f32>;
var<private> p11_nodeVar1579 : vec2<f32>;
var<private> p11_nodeVar1580 : vec4<f32>;
var<private> p11_nodeVar1581 : vec4<f32>;
var<private> p11_nodeVar1582 : vec4<f32>;
var<private> p11_nodeVar1583 : vec4<f32>;
var<private> p11_nodeVar1584 : f32;
var<private> p11_nodeVar1585 : f32;
var<private> p11_nodeVar1586 : f32;
var<private> p11_nodeVar1587 : vec2<f32>;
var<private> p11_nodeVar1588 : vec4<f32>;
var<private> p11_nodeVar1589 : vec2<f32>;
var<private> p11_nodeVar1590 : vec2<f32>;
var<private> p11_nodeVar1591 : vec2<f32>;
var<private> p11_nodeVar1592 : vec2<f32>;
var<private> p11_nodeVar1593 : vec2<f32>;
var<private> p11_nodeVar1594 : vec2<f32>;
var<private> p11_nodeVar1595 : vec2<f32>;
var<private> p11_nodeVar1596 : vec4<f32>;
var<private> p11_nodeVar1597 : vec2<f32>;
var<private> p11_nodeVar1598 : vec2<f32>;
var<private> p11_nodeVar1599 : vec2<f32>;
var<private> p11_nodeVar1600 : vec4<f32>;
var<private> p11_nodeVar1601 : vec4<f32>;
var<private> p11_nodeVar1602 : vec4<f32>;
var<private> p11_nodeVar1603 : vec2<f32>;
var<private> p11_nodeVar1604 : vec2<f32>;
var<private> p11_nodeVar1605 : vec2<f32>;
var<private> p11_nodeVar1606 : vec2<f32>;
var<private> p11_nodeVar1607 : vec2<f32>;
var<private> p11_nodeVar1608 : vec2<f32>;
var<private> p11_nodeVar1609 : vec2<f32>;
var<private> p11_nodeVar1610 : vec2<f32>;
var<private> p11_nodeVar1611 : vec4<f32>;
var<private> p11_nodeVar1612 : vec2<f32>;
var<private> p11_nodeVar1613 : vec2<f32>;
var<private> p11_nodeVar1614 : vec2<f32>;
var<private> p11_nodeVar1615 : vec4<f32>;
var<private> p11_nodeVar1616 : vec4<f32>;
var<private> p11_nodeVar1617 : vec4<f32>;
var<private> p11_nodeVar1618 : vec2<f32>;
var<private> p11_nodeVar1619 : vec2<f32>;
var<private> p11_nodeVar1620 : vec2<f32>;
var<private> p11_nodeVar1621 : vec2<f32>;
var<private> p11_nodeVar1622 : vec2<f32>;
var<private> p11_nodeVar1623 : vec2<f32>;
var<private> p11_nodeVar1624 : vec2<f32>;
var<private> p11_nodeVar1625 : vec4<f32>;
var<private> p11_nodeVar1626 : vec2<f32>;
var<private> p11_nodeVar1627 : vec2<f32>;
var<private> p11_nodeVar1628 : vec2<f32>;
var<private> p11_nodeVar1629 : vec4<f32>;
var<private> p11_nodeVar1630 : vec4<f32>;
var<private> p11_nodeVar1631 : vec4<f32>;
var<private> p11_nodeVar1632 : vec2<f32>;
var<private> p11_nodeVar1633 : vec2<f32>;
var<private> p11_nodeVar1634 : vec2<f32>;
var<private> p11_nodeVar1635 : vec2<f32>;
var<private> p11_nodeVar1636 : vec2<f32>;
var<private> p11_nodeVar1637 : vec2<f32>;
var<private> p11_nodeVar1638 : vec2<f32>;
var<private> p11_nodeVar1639 : vec2<f32>;
var<private> p11_nodeVar1640 : vec4<f32>;
var<private> p11_nodeVar1641 : vec2<f32>;
var<private> p11_nodeVar1642 : vec2<f32>;
var<private> p11_nodeVar1643 : vec2<f32>;
var<private> p11_nodeVar1644 : vec4<f32>;
var<private> p11_nodeVar1645 : vec4<f32>;
var<private> p11_nodeVar1646 : vec4<f32>;
var<private> p11_nodeVar1647 : vec2<f32>;
var<private> p11_nodeVar1648 : vec2<f32>;
var<private> p11_nodeVar1649 : vec2<f32>;
var<private> p11_nodeVar1650 : vec2<f32>;
var<private> p11_nodeVar1651 : vec2<f32>;
var<private> p11_nodeVar1652 : vec2<f32>;
var<private> p11_nodeVar1653 : vec2<f32>;
var<private> p11_nodeVar1654 : vec4<f32>;
var<private> p11_nodeVar1655 : vec2<f32>;
var<private> p11_nodeVar1656 : vec2<f32>;
var<private> p11_nodeVar1657 : vec2<f32>;
var<private> p11_nodeVar1658 : vec4<f32>;
var<private> p11_nodeVar1659 : vec4<f32>;
var<private> p11_nodeVar1660 : vec4<f32>;
var<private> p11_nodeVar1661 : vec2<f32>;
var<private> p11_nodeVar1662 : vec2<f32>;
var<private> p11_nodeVar1663 : vec2<f32>;
var<private> p11_nodeVar1664 : vec2<f32>;
var<private> p11_nodeVar1665 : vec2<f32>;
var<private> p11_nodeVar1666 : vec2<f32>;
var<private> p11_nodeVar1667 : vec2<f32>;
var<private> p11_nodeVar1668 : vec2<f32>;
var<private> p11_nodeVar1669 : vec4<f32>;
var<private> p11_nodeVar1670 : vec2<f32>;
var<private> p11_nodeVar1671 : vec2<f32>;
var<private> p11_nodeVar1672 : vec2<f32>;
var<private> p11_nodeVar1673 : vec4<f32>;
var<private> p11_nodeVar1674 : vec4<f32>;
var<private> p11_nodeVar1675 : vec4<f32>;
var<private> p11_nodeVar1676 : vec2<f32>;
var<private> p11_nodeVar1677 : vec2<f32>;
var<private> p11_nodeVar1678 : vec2<f32>;
var<private> p11_nodeVar1679 : vec2<f32>;
var<private> p11_nodeVar1680 : vec2<f32>;
var<private> p11_nodeVar1681 : vec2<f32>;
var<private> p11_nodeVar1682 : vec2<f32>;
var<private> p11_nodeVar1683 : vec4<f32>;
var<private> p11_nodeVar1684 : vec2<f32>;
var<private> p11_nodeVar1685 : vec2<f32>;
var<private> p11_nodeVar1686 : vec2<f32>;
var<private> p11_nodeVar1687 : vec4<f32>;
var<private> p11_nodeVar1688 : vec4<f32>;
var<private> p11_nodeVar1689 : vec4<f32>;
var<private> p11_nodeVar1690 : vec2<f32>;
var<private> p11_nodeVar1691 : vec2<f32>;
var<private> p11_nodeVar1692 : vec2<f32>;
var<private> p11_nodeVar1693 : vec2<f32>;
var<private> p11_nodeVar1694 : vec2<f32>;
var<private> p11_nodeVar1695 : vec2<f32>;
var<private> p11_nodeVar1696 : vec2<f32>;
var<private> p11_nodeVar1697 : vec2<f32>;
var<private> p11_nodeVar1698 : vec4<f32>;
var<private> p11_nodeVar1699 : vec2<f32>;
var<private> p11_nodeVar1700 : vec2<f32>;
var<private> p11_nodeVar1701 : vec2<f32>;
var<private> p11_nodeVar1702 : vec4<f32>;
var<private> p11_nodeVar1703 : vec4<f32>;
var<private> p11_nodeVar1704 : vec4<f32>;
var<private> p11_nodeVar1705 : vec2<f32>;
var<private> p11_nodeVar1706 : vec2<f32>;
var<private> p11_nodeVar1707 : vec2<f32>;
var<private> p11_nodeVar1708 : vec2<f32>;
var<private> p11_nodeVar1709 : vec2<f32>;
var<private> p11_nodeVar1710 : vec2<f32>;
var<private> p11_nodeVar1711 : vec2<f32>;
var<private> p11_nodeVar1712 : vec4<f32>;
var<private> p11_nodeVar1713 : vec2<f32>;
var<private> p11_nodeVar1714 : vec2<f32>;
var<private> p11_nodeVar1715 : vec2<f32>;
var<private> p11_nodeVar1716 : vec4<f32>;
var<private> p11_nodeVar1717 : vec4<f32>;
var<private> p11_nodeVar1718 : vec4<f32>;
var<private> p11_nodeVar1719 : vec2<f32>;
var<private> p11_nodeVar1720 : vec2<f32>;
var<private> p11_nodeVar1721 : vec2<f32>;
var<private> p11_nodeVar1722 : vec2<f32>;
var<private> p11_nodeVar1723 : vec2<f32>;
var<private> p11_nodeVar1724 : vec2<f32>;
var<private> p11_nodeVar1725 : vec2<f32>;
var<private> p11_nodeVar1726 : vec2<f32>;
var<private> p11_nodeVar1727 : vec4<f32>;
var<private> p11_nodeVar1728 : vec2<f32>;
var<private> p11_nodeVar1729 : vec2<f32>;
var<private> p11_nodeVar1730 : vec2<f32>;
var<private> p11_nodeVar1731 : vec4<f32>;
var<private> p11_nodeVar1732 : vec4<f32>;
var<private> p11_nodeVar1733 : vec4<f32>;
var<private> p11_nodeVar1734 : vec2<f32>;
var<private> p11_nodeVar1735 : vec2<f32>;
var<private> p11_nodeVar1736 : vec2<f32>;
var<private> p11_nodeVar1737 : vec2<f32>;
var<private> p11_nodeVar1738 : vec2<f32>;
var<private> p11_nodeVar1739 : vec2<f32>;
var<private> p11_nodeVar1740 : vec2<f32>;
var<private> p11_nodeVar1741 : vec4<f32>;
var<private> p11_nodeVar1742 : vec2<f32>;
var<private> p11_nodeVar1743 : vec2<f32>;
var<private> p11_nodeVar1744 : vec2<f32>;
var<private> p11_nodeVar1745 : vec4<f32>;
var<private> p11_nodeVar1746 : vec4<f32>;
var<private> p11_nodeVar1747 : vec4<f32>;
var<private> p11_nodeVar1748 : vec2<f32>;
var<private> p11_nodeVar1749 : vec2<f32>;
var<private> p11_nodeVar1750 : vec2<f32>;
var<private> p11_nodeVar1751 : vec2<f32>;
var<private> p11_nodeVar1752 : vec2<f32>;
var<private> p11_nodeVar1753 : vec2<f32>;
var<private> p11_nodeVar1754 : vec2<f32>;
var<private> p11_nodeVar1755 : vec2<f32>;
var<private> p11_nodeVar1756 : vec4<f32>;
var<private> p11_nodeVar1757 : vec2<f32>;
var<private> p11_nodeVar1758 : vec2<f32>;
var<private> p11_nodeVar1759 : vec2<f32>;
var<private> p11_nodeVar1760 : vec4<f32>;
var<private> p11_nodeVar1761 : vec4<f32>;
var<private> p11_nodeVar1762 : vec4<f32>;
var<private> p11_nodeVar1763 : vec2<f32>;
var<private> p11_nodeVar1764 : vec2<f32>;
var<private> p11_nodeVar1765 : vec2<f32>;
var<private> p11_nodeVar1766 : vec2<f32>;
var<private> p11_nodeVar1767 : vec2<f32>;
var<private> p11_nodeVar1768 : vec2<f32>;
var<private> p11_nodeVar1769 : vec2<f32>;
var<private> p11_nodeVar1770 : vec4<f32>;
var<private> p11_nodeVar1771 : vec2<f32>;
var<private> p11_nodeVar1772 : vec2<f32>;
var<private> p11_nodeVar1773 : vec2<f32>;
var<private> p11_nodeVar1774 : vec4<f32>;
var<private> p11_nodeVar1775 : vec4<f32>;
var<private> p11_nodeVar1776 : vec4<f32>;
var<private> p11_nodeVar1777 : vec2<f32>;
var<private> p11_nodeVar1778 : vec2<f32>;
var<private> p11_nodeVar1779 : vec2<f32>;
var<private> p11_nodeVar1780 : vec2<f32>;
var<private> p11_nodeVar1781 : vec2<f32>;
var<private> p11_nodeVar1782 : vec2<f32>;
var<private> p11_nodeVar1783 : vec2<f32>;
var<private> p11_nodeVar1784 : vec2<f32>;
var<private> p11_nodeVar1785 : vec4<f32>;
var<private> p11_nodeVar1786 : vec2<f32>;
var<private> p11_nodeVar1787 : vec2<f32>;
var<private> p11_nodeVar1788 : vec2<f32>;
var<private> p11_nodeVar1789 : vec4<f32>;
var<private> p11_nodeVar1790 : vec4<f32>;
var<private> p11_nodeVar1791 : vec4<f32>;
var<private> p11_nodeVar1792 : vec2<f32>;
var<private> p11_nodeVar1793 : vec2<f32>;
var<private> p11_nodeVar1794 : vec2<f32>;
var<private> p11_nodeVar1795 : vec2<f32>;
var<private> p11_nodeVar1796 : vec2<f32>;
var<private> p11_nodeVar1797 : vec2<f32>;
var<private> p11_nodeVar1798 : vec2<f32>;
var<private> p11_nodeVar1799 : vec4<f32>;
var<private> p11_nodeVar1800 : vec2<f32>;
var<private> p11_nodeVar1801 : vec2<f32>;
var<private> p11_nodeVar1802 : vec2<f32>;
var<private> p11_nodeVar1803 : vec4<f32>;
var<private> p11_nodeVar1804 : vec4<f32>;
var<private> p11_nodeVar1805 : vec4<f32>;
var<private> p11_nodeVar1806 : vec2<f32>;
var<private> p11_nodeVar1807 : vec2<f32>;
var<private> p11_nodeVar1808 : vec2<f32>;
var<private> p11_nodeVar1809 : vec2<f32>;
var<private> p11_nodeVar1810 : vec2<f32>;
var<private> p11_nodeVar1811 : vec2<f32>;
var<private> p11_nodeVar1812 : vec2<f32>;
var<private> p11_nodeVar1813 : vec2<f32>;
var<private> p11_nodeVar1814 : vec4<f32>;
var<private> p11_nodeVar1815 : vec2<f32>;
var<private> p11_nodeVar1816 : vec2<f32>;
var<private> p11_nodeVar1817 : vec2<f32>;
var<private> p11_nodeVar1818 : vec4<f32>;
var<private> p11_nodeVar1819 : vec4<f32>;
var<private> p11_nodeVar1820 : vec4<f32>;
var<private> p11_nodeVar1821 : vec2<f32>;
var<private> p11_nodeVar1822 : vec2<f32>;
var<private> p11_nodeVar1823 : vec2<f32>;
var<private> p11_nodeVar1824 : vec2<f32>;
var<private> p11_nodeVar1825 : vec2<f32>;
var<private> p11_nodeVar1826 : vec2<f32>;
var<private> p11_nodeVar1827 : vec2<f32>;
var<private> p11_nodeVar1828 : vec4<f32>;
var<private> p11_nodeVar1829 : vec2<f32>;
var<private> p11_nodeVar1830 : vec2<f32>;
var<private> p11_nodeVar1831 : vec2<f32>;
var<private> p11_nodeVar1832 : vec4<f32>;
var<private> p11_nodeVar1833 : vec4<f32>;
var<private> p11_nodeVar1834 : vec4<f32>;
var<private> p11_nodeVar1835 : vec2<f32>;
var<private> p11_nodeVar1836 : vec2<f32>;
var<private> p11_nodeVar1837 : vec2<f32>;
var<private> p11_nodeVar1838 : vec2<f32>;
var<private> p11_nodeVar1839 : vec2<f32>;
var<private> p11_nodeVar1840 : vec2<f32>;
var<private> p11_nodeVar1841 : vec2<f32>;
var<private> p11_nodeVar1842 : vec2<f32>;
var<private> p11_nodeVar1843 : vec4<f32>;
var<private> p11_nodeVar1844 : vec2<f32>;
var<private> p11_nodeVar1845 : vec2<f32>;
var<private> p11_nodeVar1846 : vec2<f32>;
var<private> p11_nodeVar1847 : vec4<f32>;
var<private> p11_nodeVar1848 : vec4<f32>;
var<private> p11_nodeVar1849 : vec4<f32>;
var<private> p11_nodeVar1850 : vec2<f32>;
var<private> p11_nodeVar1851 : vec2<f32>;
var<private> p11_nodeVar1852 : vec2<f32>;
var<private> p11_nodeVar1853 : vec2<f32>;
var<private> p11_nodeVar1854 : vec2<f32>;
var<private> p11_nodeVar1855 : vec2<f32>;
var<private> p11_nodeVar1856 : vec2<f32>;
var<private> p11_nodeVar1857 : vec4<f32>;
var<private> p11_nodeVar1858 : vec2<f32>;
var<private> p11_nodeVar1859 : vec2<f32>;
var<private> p11_nodeVar1860 : vec2<f32>;
var<private> p11_nodeVar1861 : vec4<f32>;
var<private> p11_nodeVar1862 : vec4<f32>;
var<private> p11_nodeVar1863 : vec4<f32>;
var<private> p11_nodeVar1864 : vec2<f32>;
var<private> p11_nodeVar1865 : vec2<f32>;
var<private> p11_nodeVar1866 : vec2<f32>;
var<private> p11_nodeVar1867 : vec2<f32>;
var<private> p11_nodeVar1868 : vec2<f32>;
var<private> p11_nodeVar1869 : vec2<f32>;
var<private> p11_nodeVar1870 : vec2<f32>;
var<private> p11_nodeVar1871 : vec4<f32>;
var<private> p11_nodeVar1872 : vec2<f32>;
var<private> p11_nodeVar1873 : vec2<f32>;
var<private> p11_nodeVar1874 : vec2<f32>;
var<private> p11_nodeVar1875 : vec4<f32>;
var<private> p11_nodeVar1876 : vec4<f32>;
var<private> p11_nodeVar1877 : vec4<f32>;
var<private> p11_nodeVar1878 : f32;
var<private> p11_nodeVar1879 : bool;
var<private> p11_nodeVar1880 : f32;
var<private> p11_nodeVar1881 : vec4<f32>;
var<private> p11_nodeVar1882 : f32;
var<private> p11_nodeVar1883 : f32;
var<private> p11_nodeVar1884 : f32;
var<private> p11_nodeVar1885 : vec4<f32>;
var<private> p11_nodeVar1886 : f32;
var<private> p11_nodeVar1887 : f32;
var<private> p11_nodeVar1888 : f32;
var<private> p11_nodeVar1889 : f32;
var<private> p11_nodeVar1890 : vec4<f32>;
var<private> p11_nodeVar1891 : f32;
var<private> p11_nodeVar1892 : f32;
var<private> p11_nodeVar1893 : f32;
var<private> p11_nodeVar1894 : f32;
var<private> p11_nodeVar1895 : vec4<f32>;
var<private> p11_nodeVar1896 : f32;
var<private> p11_nodeVar1897 : f32;
var<private> p11_nodeVar1898 : vec4<f32>;
var<private> p11_nodeVar1899 : f32;
var<private> p11_nodeVar1900 : f32;
var<private> p11_nodeVar1901 : f32;
var<private> p11_nodeVar1902 : vec4<f32>;
var<private> p11_nodeVar1903 : f32;
var<private> p11_nodeVar1904 : f32;
var<private> p11_nodeVar1905 : vec4<f32>;
var<private> p11_nodeVar1906 : f32;
var<private> p11_nodeVar1907 : f32;
var<private> p11_nodeVar1908 : f32;
var<private> p11_nodeVar1909 : f32;
var<private> p11_nodeVar1910 : vec4<f32>;
var<private> p11_nodeVar1911 : f32;
var<private> p11_nodeVar1912 : f32;
var<private> p11_nodeVar1913 : f32;
var<private> p11_nodeVar1914 : f32;
var<private> p11_nodeVar1915 : f32;
var<private> p11_nodeVar1916 : vec2<f32>;
var<private> p11_nodeVar1917 : vec2<f32>;
var<private> p11_nodeVar1918 : vec4<f32>;
var<private> p11_nodeVar1919 : f32;
var<private> p11_nodeVar1920 : f32;
var<private> p11_nodeVar1921 : vec2<f32>;
var<private> p11_nodeVar1922 : vec4<f32>;
var<private> p11_nodeVar1923 : f32;
var<private> p11_nodeVar1924 : f32;
var<private> p11_nodeVar1925 : vec2<f32>;
var<private> p11_nodeVar1926 : vec4<f32>;
var<private> p11_nodeVar1927 : f32;
var<private> p11_nodeVar1928 : f32;
var<private> p11_nodeVar1929 : vec2<f32>;
var<private> p11_nodeVar1930 : vec4<f32>;
var<private> p11_nodeVar1931 : f32;
var<private> p11_nodeVar1932 : f32;
var<private> p11_nodeVar1933 : vec2<f32>;
var<private> p11_nodeVar1934 : vec4<f32>;
var<private> p11_nodeVar1935 : f32;
var<private> p11_nodeVar1936 : f32;
var<private> p11_nodeVar1937 : vec2<f32>;
var<private> p11_nodeVar1938 : vec4<f32>;
var<private> p11_nodeVar1939 : f32;
var<private> p11_nodeVar1940 : f32;
var<private> p11_nodeVar1941 : vec2<f32>;
var<private> p11_nodeVar1942 : vec4<f32>;
var<private> p11_nodeVar1943 : f32;
var<private> p11_nodeVar1944 : f32;
var<private> p11_nodeVar1945 : vec2<f32>;
var<private> p11_nodeVar1946 : vec4<f32>;
var<private> p11_nodeVar1947 : f32;
var<private> p11_nodeVar1948 : f32;
var<private> p11_nodeVar1949 : vec2<f32>;
var<private> p11_nodeVar1950 : vec4<f32>;
var<private> p11_nodeVar1951 : f32;
var<private> p11_nodeVar1952 : vec4<f32>;
var<private> p11_nodeVar1953 : f32;
var<private> p11_nodeVar1954 : f32;
var<private> p11_nodeVar1955 : f32;
var<private> p11_nodeVar1956 : f32;
var<private> p11_nodeVar1957 : vec2<f32>;
var<private> p11_nodeVar1958 : f32;
var<private> p11_nodeVar1959 : vec2<f32>;
var<private> p11_nodeVar1960 : vec2<f32>;
var<private> p11_nodeVar1961 : vec3<f32>;
var<private> p11_nodeVar1962 : vec3<f32>;
var<private> p11_nodeVar1963 : vec2<f32>;
var<private> p11_nodeVar1964 : vec3<f32>;
var<private> p11_nodeVar1965 : vec3<f32>;
var<private> p11_nodeVar1966 : vec2<f32>;
var<private> p11_nodeVar1967 : vec2<f32>;
var<private> p11_nodeVar1968 : vec2<f32>;
var<private> p11_nodeVar1969 : vec3<f32>;
var<private> p11_nodeVar1970 : vec3<f32>;
var<private> p11_nodeVar1971 : vec2<f32>;
var<private> p11_nodeVar1972 : vec3<f32>;
var<private> p11_nodeVar1973 : vec3<f32>;
var<private> p11_nodeVar1974 : vec3<f32>;
var<private> p11_nodeVar1975 : bool;
var<private> p11_nodeVar1976 : vec3<f32>;
var<private> p11_nodeVar1977 : vec3<f32>;
var<private> p11_nodeVar1978 : vec4<f32>;
var<private> p11_nodeVar1979 : vec3<f32>;
var<private> p11_nodeVar1980 : vec3<f32>;
var<private> p11_nodeVar1981 : vec3<f32>;
var<private> p11_nodeVar1982 : vec3<f32>;
var<private> p11_nodeVar1983 : vec3<f32>;
var<private> p11_nodeVar1984 : vec3<f32>;
var<private> p11_nodeVar1985 : vec3<f32>;
var<private> p11_nodeVar1986 : vec4<f32>;
var<private> p11_nodeVar1987 : vec3<f32>;
var<private> p11_nodeVar1988 : vec3<f32>;
var<private> p11_nodeVar1989 : vec3<f32>;
var<private> p11_nodeVar1990 : vec3<f32>;
var<private> p11_nodeVar1991 : f32;
var<private> p11_nodeVar1992 : vec4<f32>;
var<private> p11_nodeVar1993 : vec3<f32>;
var<private> p11_nodeVar1994 : f32;
var<private> p11_nodeVar1995 : vec3<f32>;
var<private> p11_nodeVar1996 : vec4<f32>;
var<private> p11_nodeVar1997 : f32;
var<private> p11_nodeVar1998 : f32;
var<private> p11_Output : vec4<f32>;
var<private> p11_nodeVar1999 : vec4<f32>;

// codes


fn p11_main(door_uv: vec2f) -> p11_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p11_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p11_nodeVar1 = vec2<f32>( 0.0, 0.0 );

	if ( ( f32(knobs.wobble) > 0.0 ) ) {

		p11_nodeVar2 = ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar3 = ( ( p11_nodeVar2 / vec2<f32>( ( f32(knobs.gap) * 3.0 ) ) ) + vec2<f32>( 3.1 ) );
		p11_nodeVar4 = floor( p11_nodeVar3 );
		p11_nodeVar5 = fract( ( vec3<f32>( p11_nodeVar4.x, p11_nodeVar4.y, p11_nodeVar4.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar6 = ( p11_nodeVar5 + vec3<f32>( dot( p11_nodeVar5, ( vec3<f32>( p11_nodeVar5.y, p11_nodeVar5.z, p11_nodeVar5.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar7 = ( p11_nodeVar4 + vec2<f32>( 1.0, 0.0 ) );
		p11_nodeVar8 = fract( ( vec3<f32>( p11_nodeVar7.x, p11_nodeVar7.y, p11_nodeVar7.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar9 = ( p11_nodeVar8 + vec3<f32>( dot( p11_nodeVar8, ( vec3<f32>( p11_nodeVar8.y, p11_nodeVar8.z, p11_nodeVar8.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar10 = fract( p11_nodeVar3 );
		p11_nodeVar11 = ( ( p11_nodeVar10 * p11_nodeVar10 ) * ( vec2<f32>( 3.0 ) - ( p11_nodeVar10 * vec2<f32>( 2.0 ) ) ) );
		p11_nodeVar12 = ( p11_nodeVar4 + vec2<f32>( 0.0, 1.0 ) );
		p11_nodeVar13 = fract( ( vec3<f32>( p11_nodeVar12.x, p11_nodeVar12.y, p11_nodeVar12.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar14 = ( p11_nodeVar13 + vec3<f32>( dot( p11_nodeVar13, ( vec3<f32>( p11_nodeVar13.y, p11_nodeVar13.z, p11_nodeVar13.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar15 = ( p11_nodeVar4 + vec2<f32>( 1.0, 1.0 ) );
		p11_nodeVar16 = fract( ( vec3<f32>( p11_nodeVar15.x, p11_nodeVar15.y, p11_nodeVar15.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar17 = ( p11_nodeVar16 + vec3<f32>( dot( p11_nodeVar16, ( vec3<f32>( p11_nodeVar16.y, p11_nodeVar16.z, p11_nodeVar16.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar18 = ( ( p11_nodeVar2 / vec2<f32>( ( f32(knobs.gap) * 3.0 ) ) ) + vec2<f32>( 17.9 ) );
		p11_nodeVar19 = floor( p11_nodeVar18 );
		p11_nodeVar20 = fract( ( vec3<f32>( p11_nodeVar19.x, p11_nodeVar19.y, p11_nodeVar19.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar21 = ( p11_nodeVar20 + vec3<f32>( dot( p11_nodeVar20, ( vec3<f32>( p11_nodeVar20.y, p11_nodeVar20.z, p11_nodeVar20.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar22 = ( p11_nodeVar19 + vec2<f32>( 1.0, 0.0 ) );
		p11_nodeVar23 = fract( ( vec3<f32>( p11_nodeVar22.x, p11_nodeVar22.y, p11_nodeVar22.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar24 = ( p11_nodeVar23 + vec3<f32>( dot( p11_nodeVar23, ( vec3<f32>( p11_nodeVar23.y, p11_nodeVar23.z, p11_nodeVar23.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar25 = fract( p11_nodeVar18 );
		p11_nodeVar26 = ( ( p11_nodeVar25 * p11_nodeVar25 ) * ( vec2<f32>( 3.0 ) - ( p11_nodeVar25 * vec2<f32>( 2.0 ) ) ) );
		p11_nodeVar27 = ( p11_nodeVar19 + vec2<f32>( 0.0, 1.0 ) );
		p11_nodeVar28 = fract( ( vec3<f32>( p11_nodeVar27.x, p11_nodeVar27.y, p11_nodeVar27.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar29 = ( p11_nodeVar28 + vec3<f32>( dot( p11_nodeVar28, ( vec3<f32>( p11_nodeVar28.y, p11_nodeVar28.z, p11_nodeVar28.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar30 = ( p11_nodeVar19 + vec2<f32>( 1.0, 1.0 ) );
		p11_nodeVar31 = fract( ( vec3<f32>( p11_nodeVar30.x, p11_nodeVar30.y, p11_nodeVar30.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar32 = ( p11_nodeVar31 + vec3<f32>( dot( p11_nodeVar31, ( vec3<f32>( p11_nodeVar31.y, p11_nodeVar31.z, p11_nodeVar31.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar1 = ( ( ( ( vec2<f32>( mix( mix( fract( ( ( p11_nodeVar6.x + p11_nodeVar6.y ) * p11_nodeVar6.z ) ), fract( ( ( p11_nodeVar9.x + p11_nodeVar9.y ) * p11_nodeVar9.z ) ), p11_nodeVar11.x ), mix( fract( ( ( p11_nodeVar14.x + p11_nodeVar14.y ) * p11_nodeVar14.z ) ), fract( ( ( p11_nodeVar17.x + p11_nodeVar17.y ) * p11_nodeVar17.z ) ), p11_nodeVar11.x ), p11_nodeVar11.y ), mix( mix( fract( ( ( p11_nodeVar21.x + p11_nodeVar21.y ) * p11_nodeVar21.z ) ), fract( ( ( p11_nodeVar24.x + p11_nodeVar24.y ) * p11_nodeVar24.z ) ), p11_nodeVar26.x ), mix( fract( ( ( p11_nodeVar29.x + p11_nodeVar29.y ) * p11_nodeVar29.z ) ), fract( ( ( p11_nodeVar32.x + p11_nodeVar32.y ) * p11_nodeVar32.z ) ), p11_nodeVar26.x ), p11_nodeVar26.y ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.wobble) ) ) * vec2<f32>( f32(knobs.gap) ) ) * vec2<f32>( 0.6 ) );
		

	}

	p11_nodeVar33 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p11_nodeVar34 = ( p11_nodeVar33 * vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
	p11_nodeVar35 = ( p11_nodeVar34 + p11_nodeVar1 );
	p11_nodeVar36 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
	p11_nodeVar37 = log2( max( ( ( f32(knobs.smoothing) * f32(1.0) ) / 1.2 ), 1.0 ) );
	p11_nodeVar38 = clamp( p11_nodeVar37, 0.0, 10.0 );
	p11_nodeVar39 = floor( p11_nodeVar38 );
	p11_nodeVar40 = ( p11_nodeVar38 - p11_nodeVar39 );

	if ( ( p11_nodeVar39 == 0.0 ) ) {

		p11_nodeVar41 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar42 = picture_read_level( p11_nodeVar41, 0.0 );
		p11_nodeVar36 = vec4<f32>( ( vec3<f32>( p11_nodeVar42.x, p11_nodeVar42.y, p11_nodeVar42.z ) * vec3<f32>( p11_nodeVar42.w ) ), p11_nodeVar42.w );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar43 = ( ( p11_nodeVar41 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar44 = floor( p11_nodeVar43 );
			p11_nodeVar45 = ( p11_nodeVar43 - p11_nodeVar44 );
			p11_nodeVar46 = ( p11_nodeVar45 * p11_nodeVar45 );
			p11_nodeVar47 = ( p11_nodeVar46 * p11_nodeVar45 );
			p11_nodeVar48 = ( ( ( ( p11_nodeVar47 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar46 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar49 = ( ( ( p11_nodeVar44 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar48 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar45 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar45 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar45 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar48 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar50 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar49.x, p11_nodeVar49.y ), 0.0 );
			p11_nodeVar51 = ( p11_nodeVar47 / vec2<f32>( 6.0 ) );
			p11_nodeVar52 = ( ( ( ( ( ( p11_nodeVar47 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar46 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar45 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar51 );
			p11_nodeVar53 = ( ( ( p11_nodeVar44 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar51 / p11_nodeVar52 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar54 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar53.x, p11_nodeVar49.y ), 0.0 );
			p11_nodeVar55 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar49.x, p11_nodeVar53.y ), 0.0 );
			p11_nodeVar56 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar53.x, p11_nodeVar53.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar50, p11_nodeVar54, p11_nodeVar52.x ), mix( p11_nodeVar55, p11_nodeVar56, p11_nodeVar52.x ), p11_nodeVar52.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 1.0 ) ) {

		p11_nodeVar57 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar58 = ( ( p11_nodeVar57 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar59 = floor( p11_nodeVar58 );
		p11_nodeVar60 = ( p11_nodeVar58 - p11_nodeVar59 );
		p11_nodeVar61 = ( p11_nodeVar60 * p11_nodeVar60 );
		p11_nodeVar62 = ( p11_nodeVar61 * p11_nodeVar60 );
		p11_nodeVar63 = ( ( ( ( p11_nodeVar62 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar61 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar64 = ( ( ( p11_nodeVar59 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar63 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar60 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar60 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar60 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar63 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar65 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar64.x, p11_nodeVar64.y ), 0.0 );
		p11_nodeVar66 = ( p11_nodeVar62 / vec2<f32>( 6.0 ) );
		p11_nodeVar67 = ( ( ( ( ( ( p11_nodeVar62 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar61 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar60 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar66 );
		p11_nodeVar68 = ( ( ( p11_nodeVar59 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar66 / p11_nodeVar67 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar69 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar68.x, p11_nodeVar64.y ), 0.0 );
		p11_nodeVar70 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar64.x, p11_nodeVar68.y ), 0.0 );
		p11_nodeVar71 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar68.x, p11_nodeVar68.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar65, p11_nodeVar69, p11_nodeVar67.x ), mix( p11_nodeVar70, p11_nodeVar71, p11_nodeVar67.x ), p11_nodeVar67.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar72 = ( ( p11_nodeVar57 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar73 = floor( p11_nodeVar72 );
			p11_nodeVar74 = ( p11_nodeVar72 - p11_nodeVar73 );
			p11_nodeVar75 = ( p11_nodeVar74 * p11_nodeVar74 );
			p11_nodeVar76 = ( p11_nodeVar75 * p11_nodeVar74 );
			p11_nodeVar77 = ( ( ( ( p11_nodeVar76 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar75 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar78 = ( ( ( p11_nodeVar73 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar77 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar74 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar74 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar74 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar77 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar79 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar78.x, p11_nodeVar78.y ), 0.0 );
			p11_nodeVar80 = ( p11_nodeVar76 / vec2<f32>( 6.0 ) );
			p11_nodeVar81 = ( ( ( ( ( ( p11_nodeVar76 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar75 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar74 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar80 );
			p11_nodeVar82 = ( ( ( p11_nodeVar73 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar80 / p11_nodeVar81 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar83 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar82.x, p11_nodeVar78.y ), 0.0 );
			p11_nodeVar84 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar78.x, p11_nodeVar82.y ), 0.0 );
			p11_nodeVar85 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar82.x, p11_nodeVar82.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar79, p11_nodeVar83, p11_nodeVar81.x ), mix( p11_nodeVar84, p11_nodeVar85, p11_nodeVar81.x ), p11_nodeVar81.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 2.0 ) ) {

		p11_nodeVar86 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar87 = ( ( p11_nodeVar86 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar88 = floor( p11_nodeVar87 );
		p11_nodeVar89 = ( p11_nodeVar87 - p11_nodeVar88 );
		p11_nodeVar90 = ( p11_nodeVar89 * p11_nodeVar89 );
		p11_nodeVar91 = ( p11_nodeVar90 * p11_nodeVar89 );
		p11_nodeVar92 = ( ( ( ( p11_nodeVar91 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar90 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar93 = ( ( ( p11_nodeVar88 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar92 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar89 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar89 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar89 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar92 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar94 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar93.x, p11_nodeVar93.y ), 0.0 );
		p11_nodeVar95 = ( p11_nodeVar91 / vec2<f32>( 6.0 ) );
		p11_nodeVar96 = ( ( ( ( ( ( p11_nodeVar91 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar90 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar89 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar95 );
		p11_nodeVar97 = ( ( ( p11_nodeVar88 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar95 / p11_nodeVar96 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar98 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar97.x, p11_nodeVar93.y ), 0.0 );
		p11_nodeVar99 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar93.x, p11_nodeVar97.y ), 0.0 );
		p11_nodeVar100 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar97.x, p11_nodeVar97.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar94, p11_nodeVar98, p11_nodeVar96.x ), mix( p11_nodeVar99, p11_nodeVar100, p11_nodeVar96.x ), p11_nodeVar96.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar101 = ( ( p11_nodeVar86 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar102 = floor( p11_nodeVar101 );
			p11_nodeVar103 = ( p11_nodeVar101 - p11_nodeVar102 );
			p11_nodeVar104 = ( p11_nodeVar103 * p11_nodeVar103 );
			p11_nodeVar105 = ( p11_nodeVar104 * p11_nodeVar103 );
			p11_nodeVar106 = ( ( ( ( p11_nodeVar105 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar104 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar107 = ( ( ( p11_nodeVar102 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar106 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar103 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar103 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar103 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar106 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar108 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar107.x, p11_nodeVar107.y ), 0.0 );
			p11_nodeVar109 = ( p11_nodeVar105 / vec2<f32>( 6.0 ) );
			p11_nodeVar110 = ( ( ( ( ( ( p11_nodeVar105 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar104 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar103 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar109 );
			p11_nodeVar111 = ( ( ( p11_nodeVar102 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar109 / p11_nodeVar110 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar112 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar111.x, p11_nodeVar107.y ), 0.0 );
			p11_nodeVar113 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar107.x, p11_nodeVar111.y ), 0.0 );
			p11_nodeVar114 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar111.x, p11_nodeVar111.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar108, p11_nodeVar112, p11_nodeVar110.x ), mix( p11_nodeVar113, p11_nodeVar114, p11_nodeVar110.x ), p11_nodeVar110.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 3.0 ) ) {

		p11_nodeVar115 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar116 = ( ( p11_nodeVar115 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar117 = floor( p11_nodeVar116 );
		p11_nodeVar118 = ( p11_nodeVar116 - p11_nodeVar117 );
		p11_nodeVar119 = ( p11_nodeVar118 * p11_nodeVar118 );
		p11_nodeVar120 = ( p11_nodeVar119 * p11_nodeVar118 );
		p11_nodeVar121 = ( ( ( ( p11_nodeVar120 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar119 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar122 = ( ( ( p11_nodeVar117 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar121 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar118 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar118 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar118 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar121 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar123 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar122.x, p11_nodeVar122.y ), 0.0 );
		p11_nodeVar124 = ( p11_nodeVar120 / vec2<f32>( 6.0 ) );
		p11_nodeVar125 = ( ( ( ( ( ( p11_nodeVar120 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar119 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar118 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar124 );
		p11_nodeVar126 = ( ( ( p11_nodeVar117 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar124 / p11_nodeVar125 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar127 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar126.x, p11_nodeVar122.y ), 0.0 );
		p11_nodeVar128 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar122.x, p11_nodeVar126.y ), 0.0 );
		p11_nodeVar129 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar126.x, p11_nodeVar126.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar123, p11_nodeVar127, p11_nodeVar125.x ), mix( p11_nodeVar128, p11_nodeVar129, p11_nodeVar125.x ), p11_nodeVar125.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar130 = ( ( p11_nodeVar115 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar131 = floor( p11_nodeVar130 );
			p11_nodeVar132 = ( p11_nodeVar130 - p11_nodeVar131 );
			p11_nodeVar133 = ( p11_nodeVar132 * p11_nodeVar132 );
			p11_nodeVar134 = ( p11_nodeVar133 * p11_nodeVar132 );
			p11_nodeVar135 = ( ( ( ( p11_nodeVar134 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar133 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar136 = ( ( ( p11_nodeVar131 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar135 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar132 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar132 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar132 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar135 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar137 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar136.x, p11_nodeVar136.y ), 0.0 );
			p11_nodeVar138 = ( p11_nodeVar134 / vec2<f32>( 6.0 ) );
			p11_nodeVar139 = ( ( ( ( ( ( p11_nodeVar134 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar133 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar132 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar138 );
			p11_nodeVar140 = ( ( ( p11_nodeVar131 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar138 / p11_nodeVar139 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar141 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar140.x, p11_nodeVar136.y ), 0.0 );
			p11_nodeVar142 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar136.x, p11_nodeVar140.y ), 0.0 );
			p11_nodeVar143 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar140.x, p11_nodeVar140.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar137, p11_nodeVar141, p11_nodeVar139.x ), mix( p11_nodeVar142, p11_nodeVar143, p11_nodeVar139.x ), p11_nodeVar139.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 4.0 ) ) {

		p11_nodeVar144 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar145 = ( ( p11_nodeVar144 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar146 = floor( p11_nodeVar145 );
		p11_nodeVar147 = ( p11_nodeVar145 - p11_nodeVar146 );
		p11_nodeVar148 = ( p11_nodeVar147 * p11_nodeVar147 );
		p11_nodeVar149 = ( p11_nodeVar148 * p11_nodeVar147 );
		p11_nodeVar150 = ( ( ( ( p11_nodeVar149 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar148 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar151 = ( ( ( p11_nodeVar146 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar150 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar147 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar147 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar147 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar150 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar152 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar151.x, p11_nodeVar151.y ), 0.0 );
		p11_nodeVar153 = ( p11_nodeVar149 / vec2<f32>( 6.0 ) );
		p11_nodeVar154 = ( ( ( ( ( ( p11_nodeVar149 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar148 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar147 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar153 );
		p11_nodeVar155 = ( ( ( p11_nodeVar146 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar153 / p11_nodeVar154 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar156 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar155.x, p11_nodeVar151.y ), 0.0 );
		p11_nodeVar157 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar151.x, p11_nodeVar155.y ), 0.0 );
		p11_nodeVar158 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar155.x, p11_nodeVar155.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar152, p11_nodeVar156, p11_nodeVar154.x ), mix( p11_nodeVar157, p11_nodeVar158, p11_nodeVar154.x ), p11_nodeVar154.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar159 = ( ( p11_nodeVar144 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar160 = floor( p11_nodeVar159 );
			p11_nodeVar161 = ( p11_nodeVar159 - p11_nodeVar160 );
			p11_nodeVar162 = ( p11_nodeVar161 * p11_nodeVar161 );
			p11_nodeVar163 = ( p11_nodeVar162 * p11_nodeVar161 );
			p11_nodeVar164 = ( ( ( ( p11_nodeVar163 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar162 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar165 = ( ( ( p11_nodeVar160 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar164 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar161 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar161 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar161 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar164 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar166 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar165.x, p11_nodeVar165.y ), 0.0 );
			p11_nodeVar167 = ( p11_nodeVar163 / vec2<f32>( 6.0 ) );
			p11_nodeVar168 = ( ( ( ( ( ( p11_nodeVar163 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar162 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar161 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar167 );
			p11_nodeVar169 = ( ( ( p11_nodeVar160 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar167 / p11_nodeVar168 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar170 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar169.x, p11_nodeVar165.y ), 0.0 );
			p11_nodeVar171 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar165.x, p11_nodeVar169.y ), 0.0 );
			p11_nodeVar172 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar169.x, p11_nodeVar169.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar166, p11_nodeVar170, p11_nodeVar168.x ), mix( p11_nodeVar171, p11_nodeVar172, p11_nodeVar168.x ), p11_nodeVar168.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 5.0 ) ) {

		p11_nodeVar173 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar174 = ( ( p11_nodeVar173 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar175 = floor( p11_nodeVar174 );
		p11_nodeVar176 = ( p11_nodeVar174 - p11_nodeVar175 );
		p11_nodeVar177 = ( p11_nodeVar176 * p11_nodeVar176 );
		p11_nodeVar178 = ( p11_nodeVar177 * p11_nodeVar176 );
		p11_nodeVar179 = ( ( ( ( p11_nodeVar178 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar177 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar180 = ( ( ( p11_nodeVar175 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar179 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar176 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar176 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar176 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar179 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar181 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar180.x, p11_nodeVar180.y ), 0.0 );
		p11_nodeVar182 = ( p11_nodeVar178 / vec2<f32>( 6.0 ) );
		p11_nodeVar183 = ( ( ( ( ( ( p11_nodeVar178 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar177 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar176 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar182 );
		p11_nodeVar184 = ( ( ( p11_nodeVar175 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar182 / p11_nodeVar183 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar185 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar184.x, p11_nodeVar180.y ), 0.0 );
		p11_nodeVar186 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar180.x, p11_nodeVar184.y ), 0.0 );
		p11_nodeVar187 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar184.x, p11_nodeVar184.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar181, p11_nodeVar185, p11_nodeVar183.x ), mix( p11_nodeVar186, p11_nodeVar187, p11_nodeVar183.x ), p11_nodeVar183.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar188 = ( ( p11_nodeVar173 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar189 = floor( p11_nodeVar188 );
			p11_nodeVar190 = ( p11_nodeVar188 - p11_nodeVar189 );
			p11_nodeVar191 = ( p11_nodeVar190 * p11_nodeVar190 );
			p11_nodeVar192 = ( p11_nodeVar191 * p11_nodeVar190 );
			p11_nodeVar193 = ( ( ( ( p11_nodeVar192 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar191 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar194 = ( ( ( p11_nodeVar189 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar193 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar190 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar190 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar190 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar193 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar195 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar194.x, p11_nodeVar194.y ), 0.0 );
			p11_nodeVar196 = ( p11_nodeVar192 / vec2<f32>( 6.0 ) );
			p11_nodeVar197 = ( ( ( ( ( ( p11_nodeVar192 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar191 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar190 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar196 );
			p11_nodeVar198 = ( ( ( p11_nodeVar189 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar196 / p11_nodeVar197 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar199 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar198.x, p11_nodeVar194.y ), 0.0 );
			p11_nodeVar200 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar194.x, p11_nodeVar198.y ), 0.0 );
			p11_nodeVar201 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar198.x, p11_nodeVar198.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar195, p11_nodeVar199, p11_nodeVar197.x ), mix( p11_nodeVar200, p11_nodeVar201, p11_nodeVar197.x ), p11_nodeVar197.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 6.0 ) ) {

		p11_nodeVar202 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar203 = ( ( p11_nodeVar202 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar204 = floor( p11_nodeVar203 );
		p11_nodeVar205 = ( p11_nodeVar203 - p11_nodeVar204 );
		p11_nodeVar206 = ( p11_nodeVar205 * p11_nodeVar205 );
		p11_nodeVar207 = ( p11_nodeVar206 * p11_nodeVar205 );
		p11_nodeVar208 = ( ( ( ( p11_nodeVar207 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar206 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar209 = ( ( ( p11_nodeVar204 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar208 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar205 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar205 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar205 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar208 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar210 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar209.x, p11_nodeVar209.y ), 0.0 );
		p11_nodeVar211 = ( p11_nodeVar207 / vec2<f32>( 6.0 ) );
		p11_nodeVar212 = ( ( ( ( ( ( p11_nodeVar207 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar206 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar205 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar211 );
		p11_nodeVar213 = ( ( ( p11_nodeVar204 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar211 / p11_nodeVar212 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar214 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar213.x, p11_nodeVar209.y ), 0.0 );
		p11_nodeVar215 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar209.x, p11_nodeVar213.y ), 0.0 );
		p11_nodeVar216 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar213.x, p11_nodeVar213.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar210, p11_nodeVar214, p11_nodeVar212.x ), mix( p11_nodeVar215, p11_nodeVar216, p11_nodeVar212.x ), p11_nodeVar212.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar217 = ( ( p11_nodeVar202 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar218 = floor( p11_nodeVar217 );
			p11_nodeVar219 = ( p11_nodeVar217 - p11_nodeVar218 );
			p11_nodeVar220 = ( p11_nodeVar219 * p11_nodeVar219 );
			p11_nodeVar221 = ( p11_nodeVar220 * p11_nodeVar219 );
			p11_nodeVar222 = ( ( ( ( p11_nodeVar221 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar220 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar223 = ( ( ( p11_nodeVar218 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar222 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar219 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar219 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar219 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar222 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar224 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar223.x, p11_nodeVar223.y ), 0.0 );
			p11_nodeVar225 = ( p11_nodeVar221 / vec2<f32>( 6.0 ) );
			p11_nodeVar226 = ( ( ( ( ( ( p11_nodeVar221 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar220 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar219 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar225 );
			p11_nodeVar227 = ( ( ( p11_nodeVar218 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar225 / p11_nodeVar226 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar228 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar227.x, p11_nodeVar223.y ), 0.0 );
			p11_nodeVar229 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar223.x, p11_nodeVar227.y ), 0.0 );
			p11_nodeVar230 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar227.x, p11_nodeVar227.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar224, p11_nodeVar228, p11_nodeVar226.x ), mix( p11_nodeVar229, p11_nodeVar230, p11_nodeVar226.x ), p11_nodeVar226.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 7.0 ) ) {

		p11_nodeVar231 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar232 = ( ( p11_nodeVar231 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar233 = floor( p11_nodeVar232 );
		p11_nodeVar234 = ( p11_nodeVar232 - p11_nodeVar233 );
		p11_nodeVar235 = ( p11_nodeVar234 * p11_nodeVar234 );
		p11_nodeVar236 = ( p11_nodeVar235 * p11_nodeVar234 );
		p11_nodeVar237 = ( ( ( ( p11_nodeVar236 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar235 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar238 = ( ( ( p11_nodeVar233 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar237 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar234 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar234 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar234 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar237 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar239 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar238.x, p11_nodeVar238.y ), 0.0 );
		p11_nodeVar240 = ( p11_nodeVar236 / vec2<f32>( 6.0 ) );
		p11_nodeVar241 = ( ( ( ( ( ( p11_nodeVar236 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar235 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar234 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar240 );
		p11_nodeVar242 = ( ( ( p11_nodeVar233 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar240 / p11_nodeVar241 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar243 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar242.x, p11_nodeVar238.y ), 0.0 );
		p11_nodeVar244 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar238.x, p11_nodeVar242.y ), 0.0 );
		p11_nodeVar245 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar242.x, p11_nodeVar242.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar239, p11_nodeVar243, p11_nodeVar241.x ), mix( p11_nodeVar244, p11_nodeVar245, p11_nodeVar241.x ), p11_nodeVar241.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar246 = ( ( p11_nodeVar231 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar247 = floor( p11_nodeVar246 );
			p11_nodeVar248 = ( p11_nodeVar246 - p11_nodeVar247 );
			p11_nodeVar249 = ( p11_nodeVar248 * p11_nodeVar248 );
			p11_nodeVar250 = ( p11_nodeVar249 * p11_nodeVar248 );
			p11_nodeVar251 = ( ( ( ( p11_nodeVar250 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar249 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar252 = ( ( ( p11_nodeVar247 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar251 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar248 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar248 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar248 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar251 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar253 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar252.x, p11_nodeVar252.y ), 0.0 );
			p11_nodeVar254 = ( p11_nodeVar250 / vec2<f32>( 6.0 ) );
			p11_nodeVar255 = ( ( ( ( ( ( p11_nodeVar250 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar249 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar248 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar254 );
			p11_nodeVar256 = ( ( ( p11_nodeVar247 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar254 / p11_nodeVar255 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar257 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar256.x, p11_nodeVar252.y ), 0.0 );
			p11_nodeVar258 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar252.x, p11_nodeVar256.y ), 0.0 );
			p11_nodeVar259 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar256.x, p11_nodeVar256.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar253, p11_nodeVar257, p11_nodeVar255.x ), mix( p11_nodeVar258, p11_nodeVar259, p11_nodeVar255.x ), p11_nodeVar255.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 8.0 ) ) {

		p11_nodeVar260 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar261 = ( ( p11_nodeVar260 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar262 = floor( p11_nodeVar261 );
		p11_nodeVar263 = ( p11_nodeVar261 - p11_nodeVar262 );
		p11_nodeVar264 = ( p11_nodeVar263 * p11_nodeVar263 );
		p11_nodeVar265 = ( p11_nodeVar264 * p11_nodeVar263 );
		p11_nodeVar266 = ( ( ( ( p11_nodeVar265 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar264 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar267 = ( ( ( p11_nodeVar262 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar266 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar263 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar263 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar263 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar266 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar268 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar267.x, p11_nodeVar267.y ), 0.0 );
		p11_nodeVar269 = ( p11_nodeVar265 / vec2<f32>( 6.0 ) );
		p11_nodeVar270 = ( ( ( ( ( ( p11_nodeVar265 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar264 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar263 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar269 );
		p11_nodeVar271 = ( ( ( p11_nodeVar262 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar269 / p11_nodeVar270 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar272 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar271.x, p11_nodeVar267.y ), 0.0 );
		p11_nodeVar273 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar267.x, p11_nodeVar271.y ), 0.0 );
		p11_nodeVar274 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar271.x, p11_nodeVar271.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar268, p11_nodeVar272, p11_nodeVar270.x ), mix( p11_nodeVar273, p11_nodeVar274, p11_nodeVar270.x ), p11_nodeVar270.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar275 = ( ( p11_nodeVar260 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar276 = floor( p11_nodeVar275 );
			p11_nodeVar277 = ( p11_nodeVar275 - p11_nodeVar276 );
			p11_nodeVar278 = ( p11_nodeVar277 * p11_nodeVar277 );
			p11_nodeVar279 = ( p11_nodeVar278 * p11_nodeVar277 );
			p11_nodeVar280 = ( ( ( ( p11_nodeVar279 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar278 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar281 = ( ( ( p11_nodeVar276 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar280 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar277 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar277 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar277 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar280 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar282 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar281.x, p11_nodeVar281.y ), 0.0 );
			p11_nodeVar283 = ( p11_nodeVar279 / vec2<f32>( 6.0 ) );
			p11_nodeVar284 = ( ( ( ( ( ( p11_nodeVar279 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar278 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar277 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar283 );
			p11_nodeVar285 = ( ( ( p11_nodeVar276 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar283 / p11_nodeVar284 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar286 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar285.x, p11_nodeVar281.y ), 0.0 );
			p11_nodeVar287 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar281.x, p11_nodeVar285.y ), 0.0 );
			p11_nodeVar288 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar285.x, p11_nodeVar285.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar282, p11_nodeVar286, p11_nodeVar284.x ), mix( p11_nodeVar287, p11_nodeVar288, p11_nodeVar284.x ), p11_nodeVar284.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 == 9.0 ) ) {

		p11_nodeVar289 = ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
		p11_nodeVar290 = ( ( p11_nodeVar289 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar291 = floor( p11_nodeVar290 );
		p11_nodeVar292 = ( p11_nodeVar290 - p11_nodeVar291 );
		p11_nodeVar293 = ( p11_nodeVar292 * p11_nodeVar292 );
		p11_nodeVar294 = ( p11_nodeVar293 * p11_nodeVar292 );
		p11_nodeVar295 = ( ( ( ( p11_nodeVar294 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar293 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar296 = ( ( ( p11_nodeVar291 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar295 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar292 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar292 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar292 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar295 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar297 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar296.x, p11_nodeVar296.y ), 0.0 );
		p11_nodeVar298 = ( p11_nodeVar294 / vec2<f32>( 6.0 ) );
		p11_nodeVar299 = ( ( ( ( ( ( p11_nodeVar294 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar293 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar292 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar298 );
		p11_nodeVar300 = ( ( ( p11_nodeVar291 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar298 / p11_nodeVar299 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
		p11_nodeVar301 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar300.x, p11_nodeVar296.y ), 0.0 );
		p11_nodeVar302 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar296.x, p11_nodeVar300.y ), 0.0 );
		p11_nodeVar303 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar300.x, p11_nodeVar300.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar297, p11_nodeVar301, p11_nodeVar299.x ), mix( p11_nodeVar302, p11_nodeVar303, p11_nodeVar299.x ), p11_nodeVar299.y );

		if ( ( p11_nodeVar40 > 0.0 ) ) {

			p11_nodeVar304 = ( ( p11_nodeVar289 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar305 = floor( p11_nodeVar304 );
			p11_nodeVar306 = ( p11_nodeVar304 - p11_nodeVar305 );
			p11_nodeVar307 = ( p11_nodeVar306 * p11_nodeVar306 );
			p11_nodeVar308 = ( p11_nodeVar307 * p11_nodeVar306 );
			p11_nodeVar309 = ( ( ( ( p11_nodeVar308 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar307 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar310 = ( ( ( p11_nodeVar305 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar309 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar306 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar306 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar306 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar309 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar311 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar310.x, p11_nodeVar310.y ), 0.0 );
			p11_nodeVar312 = ( p11_nodeVar308 / vec2<f32>( 6.0 ) );
			p11_nodeVar313 = ( ( ( ( ( ( p11_nodeVar308 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar307 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar306 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar312 );
			p11_nodeVar314 = ( ( ( p11_nodeVar305 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar312 / p11_nodeVar313 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar315 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar314.x, p11_nodeVar310.y ), 0.0 );
			p11_nodeVar316 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar310.x, p11_nodeVar314.y ), 0.0 );
			p11_nodeVar317 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar314.x, p11_nodeVar314.y ), 0.0 );
			p11_nodeVar36 = mix( p11_nodeVar36, mix( mix( p11_nodeVar311, p11_nodeVar315, p11_nodeVar313.x ), mix( p11_nodeVar316, p11_nodeVar317, p11_nodeVar313.x ), p11_nodeVar313.y ), p11_nodeVar40 );
			

		}

		

	}


	if ( ( p11_nodeVar39 >= 10.0 ) ) {

		p11_nodeVar318 = ( ( ( p11_nodeVar35 / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
		p11_nodeVar319 = floor( p11_nodeVar318 );
		p11_nodeVar320 = ( p11_nodeVar318 - p11_nodeVar319 );
		p11_nodeVar321 = ( p11_nodeVar320 * p11_nodeVar320 );
		p11_nodeVar322 = ( p11_nodeVar321 * p11_nodeVar320 );
		p11_nodeVar323 = ( ( ( ( p11_nodeVar322 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar321 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
		p11_nodeVar324 = ( ( ( p11_nodeVar319 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar323 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar320 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar320 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar320 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar323 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p11_nodeVar325 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar324.x, p11_nodeVar324.y ), 0.0 );
		p11_nodeVar326 = ( p11_nodeVar322 / vec2<f32>( 6.0 ) );
		p11_nodeVar327 = ( ( ( ( ( ( p11_nodeVar322 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar321 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar320 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar326 );
		p11_nodeVar328 = ( ( ( p11_nodeVar319 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar326 / p11_nodeVar327 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
		p11_nodeVar329 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar328.x, p11_nodeVar324.y ), 0.0 );
		p11_nodeVar330 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar324.x, p11_nodeVar328.y ), 0.0 );
		p11_nodeVar331 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar328.x, p11_nodeVar328.y ), 0.0 );
		p11_nodeVar36 = mix( mix( p11_nodeVar325, p11_nodeVar329, p11_nodeVar327.x ), mix( p11_nodeVar330, p11_nodeVar331, p11_nodeVar327.x ), p11_nodeVar327.y );
		

	}

	p11_nodeVar332 = ( 1.0 - ( f32(knobs.bleed) * 0.2 ) );

	if ( ( f32(knobs.bleed) > 0.0 ) ) {

		p11_nodeVar333 = ( ( p11_nodeVar35 / vec2<f32>( ( f32(knobs.gap) * 0.7 ) ) ) + vec2<f32>( 41.2 ) );
		p11_nodeVar334 = floor( p11_nodeVar333 );
		p11_nodeVar335 = fract( ( vec3<f32>( p11_nodeVar334.x, p11_nodeVar334.y, p11_nodeVar334.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar336 = ( p11_nodeVar335 + vec3<f32>( dot( p11_nodeVar335, ( vec3<f32>( p11_nodeVar335.y, p11_nodeVar335.z, p11_nodeVar335.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar337 = ( p11_nodeVar334 + vec2<f32>( 1.0, 0.0 ) );
		p11_nodeVar338 = fract( ( vec3<f32>( p11_nodeVar337.x, p11_nodeVar337.y, p11_nodeVar337.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar339 = ( p11_nodeVar338 + vec3<f32>( dot( p11_nodeVar338, ( vec3<f32>( p11_nodeVar338.y, p11_nodeVar338.z, p11_nodeVar338.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar340 = fract( p11_nodeVar333 );
		p11_nodeVar341 = ( ( p11_nodeVar340 * p11_nodeVar340 ) * ( vec2<f32>( 3.0 ) - ( p11_nodeVar340 * vec2<f32>( 2.0 ) ) ) );
		p11_nodeVar342 = ( p11_nodeVar334 + vec2<f32>( 0.0, 1.0 ) );
		p11_nodeVar343 = fract( ( vec3<f32>( p11_nodeVar342.x, p11_nodeVar342.y, p11_nodeVar342.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar344 = ( p11_nodeVar343 + vec3<f32>( dot( p11_nodeVar343, ( vec3<f32>( p11_nodeVar343.y, p11_nodeVar343.z, p11_nodeVar343.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar345 = ( p11_nodeVar334 + vec2<f32>( 1.0, 1.0 ) );
		p11_nodeVar346 = fract( ( vec3<f32>( p11_nodeVar345.x, p11_nodeVar345.y, p11_nodeVar345.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar347 = ( p11_nodeVar346 + vec3<f32>( dot( p11_nodeVar346, ( vec3<f32>( p11_nodeVar346.y, p11_nodeVar346.z, p11_nodeVar346.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar332 = ( ( ( mix( mix( fract( ( ( p11_nodeVar336.x + p11_nodeVar336.y ) * p11_nodeVar336.z ) ), fract( ( ( p11_nodeVar339.x + p11_nodeVar339.y ) * p11_nodeVar339.z ) ), p11_nodeVar341.x ), mix( fract( ( ( p11_nodeVar344.x + p11_nodeVar344.y ) * p11_nodeVar344.z ) ), fract( ( ( p11_nodeVar347.x + p11_nodeVar347.y ) * p11_nodeVar347.z ) ), p11_nodeVar341.x ), p11_nodeVar341.y ) * f32(knobs.bleed) ) * 0.35 ) + ( 1.0 - ( f32(knobs.bleed) * 0.2 ) ) );
		

	}

	p11_nodeVar348 = 0.0;
	p11_nodeVar349 = 0.0;
	p11_nodeVar350 = 0.0;

	if ( ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) < 0.5 ) ) {

		p11_nodeVar352 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
		p11_nodeVar353 = clamp( dot( vec3<f32>( p11_nodeVar352.x, p11_nodeVar352.y, p11_nodeVar352.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar353 <= 0.0031308 ) ) {

			p11_nodeVar351 = ( p11_nodeVar353 * 12.92 );

		} else {

			p11_nodeVar351 = ( ( pow( p11_nodeVar353, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar354 = ( ( 1.0 - p11_nodeVar351 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) );
		p11_nodeVar355 = mix( f32(knobs.weight), ( f32(knobs.weight) * 2.2 ), ( f32(knobs.pressure) * p11_nodeVar354 ) );
		p11_nodeVar356 = ( p11_nodeVar355 * 0.5 );
		p11_nodeVar357 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar358 = ( f32(knobs.threshold) * 0.5 );
		p11_nodeVar348 = ( ( 1.0 - smoothstep( ( p11_nodeVar356 - p11_nodeVar357 ), ( p11_nodeVar356 + p11_nodeVar357 ), ( abs( ( fract( ( dot( p11_nodeVar35, vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) ) ) / f32(knobs.gap) ) ) - 0.5 ) ) * f32(knobs.gap) ) ) ) * smoothstep( p11_nodeVar358, ( p11_nodeVar358 + 0.08 ), p11_nodeVar354 ) );
		p11_nodeVar359 = ( p11_nodeVar355 * 0.5 );
		p11_nodeVar360 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar349 = ( ( ( 1.0 - smoothstep( ( p11_nodeVar359 - p11_nodeVar360 ), ( p11_nodeVar359 + p11_nodeVar360 ), ( abs( ( fract( ( dot( p11_nodeVar35, vec2<f32>( cos( f32((0.017453292519943295 * knobs.crossAngle + 0)) ), sin( f32((0.017453292519943295 * knobs.crossAngle + 0)) ) ) ) / f32(knobs.gap) ) ) - 0.5 ) ) * f32(knobs.gap) ) ) ) * smoothstep( f32(knobs.threshold), ( f32(knobs.threshold) + 0.08 ), p11_nodeVar354 ) ) * f32(knobs.crosshatch) );
		p11_nodeVar361 = ( p11_nodeVar355 * 0.5 );
		p11_nodeVar362 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar363 = ( ( ( f32((0.017453292519943295 * knobs.angle + 0)) + f32((0.017453292519943295 * knobs.crossAngle + 0)) ) * 0.5 ) + 1.5707963267948966 );
		p11_nodeVar364 = ( f32(knobs.threshold) + ( ( 1.0 - f32(knobs.threshold) ) * 0.5 ) );
		p11_nodeVar350 = ( ( ( 1.0 - smoothstep( ( p11_nodeVar361 - p11_nodeVar362 ), ( p11_nodeVar361 + p11_nodeVar362 ), ( abs( ( fract( ( dot( p11_nodeVar35, vec2<f32>( cos( p11_nodeVar363 ), sin( p11_nodeVar363 ) ) ) / f32(knobs.gap) ) ) - 0.5 ) ) * f32(knobs.gap) ) ) ) * smoothstep( p11_nodeVar364, ( p11_nodeVar364 + 0.08 ), p11_nodeVar354 ) ) * f32(knobs.crosshatch) );
		

	}


	if ( ( ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) > 0.5 ) && ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) < 1.5 ) ) ) {

		p11_nodeVar365 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p11_nodeVar366 = clamp( p11_nodeVar37, 0.0, 10.0 );
		p11_nodeVar367 = floor( p11_nodeVar366 );
		p11_nodeVar368 = ( p11_nodeVar366 - p11_nodeVar367 );

		if ( ( p11_nodeVar367 == 0.0 ) ) {

			p11_nodeVar369 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar370 = vec2<f32>( ( - p11_nodeVar369.y ), p11_nodeVar369.x );
			p11_nodeVar371 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar369 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar369 ) + ( p11_nodeVar370 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar370 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar372 = picture_read_level( p11_nodeVar371, 0.0 );
			p11_nodeVar365 = vec4<f32>( ( vec3<f32>( p11_nodeVar372.x, p11_nodeVar372.y, p11_nodeVar372.z ) * vec3<f32>( p11_nodeVar372.w ) ), p11_nodeVar372.w );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar373 = ( ( p11_nodeVar371 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar374 = floor( p11_nodeVar373 );
				p11_nodeVar375 = ( p11_nodeVar373 - p11_nodeVar374 );
				p11_nodeVar376 = ( p11_nodeVar375 * p11_nodeVar375 );
				p11_nodeVar377 = ( p11_nodeVar376 * p11_nodeVar375 );
				p11_nodeVar378 = ( ( ( ( p11_nodeVar377 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar376 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar379 = ( ( ( p11_nodeVar374 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar378 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar375 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar375 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar375 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar378 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar380 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar379.x, p11_nodeVar379.y ), 0.0 );
				p11_nodeVar381 = ( p11_nodeVar377 / vec2<f32>( 6.0 ) );
				p11_nodeVar382 = ( ( ( ( ( ( p11_nodeVar377 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar376 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar375 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar381 );
				p11_nodeVar383 = ( ( ( p11_nodeVar374 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar381 / p11_nodeVar382 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar384 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar383.x, p11_nodeVar379.y ), 0.0 );
				p11_nodeVar385 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar379.x, p11_nodeVar383.y ), 0.0 );
				p11_nodeVar386 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar383.x, p11_nodeVar383.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar380, p11_nodeVar384, p11_nodeVar382.x ), mix( p11_nodeVar385, p11_nodeVar386, p11_nodeVar382.x ), p11_nodeVar382.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 1.0 ) ) {

			p11_nodeVar387 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar388 = vec2<f32>( ( - p11_nodeVar387.y ), p11_nodeVar387.x );
			p11_nodeVar389 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar387 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar387 ) + ( p11_nodeVar388 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar388 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar390 = ( ( p11_nodeVar389 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar391 = floor( p11_nodeVar390 );
			p11_nodeVar392 = ( p11_nodeVar390 - p11_nodeVar391 );
			p11_nodeVar393 = ( p11_nodeVar392 * p11_nodeVar392 );
			p11_nodeVar394 = ( p11_nodeVar393 * p11_nodeVar392 );
			p11_nodeVar395 = ( ( ( ( p11_nodeVar394 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar393 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar396 = ( ( ( p11_nodeVar391 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar395 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar392 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar392 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar392 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar395 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar397 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar396.x, p11_nodeVar396.y ), 0.0 );
			p11_nodeVar398 = ( p11_nodeVar394 / vec2<f32>( 6.0 ) );
			p11_nodeVar399 = ( ( ( ( ( ( p11_nodeVar394 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar393 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar392 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar398 );
			p11_nodeVar400 = ( ( ( p11_nodeVar391 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar398 / p11_nodeVar399 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar401 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar400.x, p11_nodeVar396.y ), 0.0 );
			p11_nodeVar402 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar396.x, p11_nodeVar400.y ), 0.0 );
			p11_nodeVar403 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar400.x, p11_nodeVar400.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar397, p11_nodeVar401, p11_nodeVar399.x ), mix( p11_nodeVar402, p11_nodeVar403, p11_nodeVar399.x ), p11_nodeVar399.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar404 = ( ( p11_nodeVar389 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar405 = floor( p11_nodeVar404 );
				p11_nodeVar406 = ( p11_nodeVar404 - p11_nodeVar405 );
				p11_nodeVar407 = ( p11_nodeVar406 * p11_nodeVar406 );
				p11_nodeVar408 = ( p11_nodeVar407 * p11_nodeVar406 );
				p11_nodeVar409 = ( ( ( ( p11_nodeVar408 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar407 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar410 = ( ( ( p11_nodeVar405 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar409 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar406 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar406 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar406 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar409 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar411 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar410.x, p11_nodeVar410.y ), 0.0 );
				p11_nodeVar412 = ( p11_nodeVar408 / vec2<f32>( 6.0 ) );
				p11_nodeVar413 = ( ( ( ( ( ( p11_nodeVar408 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar407 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar406 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar412 );
				p11_nodeVar414 = ( ( ( p11_nodeVar405 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar412 / p11_nodeVar413 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar415 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar414.x, p11_nodeVar410.y ), 0.0 );
				p11_nodeVar416 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar410.x, p11_nodeVar414.y ), 0.0 );
				p11_nodeVar417 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar414.x, p11_nodeVar414.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar411, p11_nodeVar415, p11_nodeVar413.x ), mix( p11_nodeVar416, p11_nodeVar417, p11_nodeVar413.x ), p11_nodeVar413.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 2.0 ) ) {

			p11_nodeVar418 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar419 = vec2<f32>( ( - p11_nodeVar418.y ), p11_nodeVar418.x );
			p11_nodeVar420 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar418 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar418 ) + ( p11_nodeVar419 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar419 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar421 = ( ( p11_nodeVar420 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar422 = floor( p11_nodeVar421 );
			p11_nodeVar423 = ( p11_nodeVar421 - p11_nodeVar422 );
			p11_nodeVar424 = ( p11_nodeVar423 * p11_nodeVar423 );
			p11_nodeVar425 = ( p11_nodeVar424 * p11_nodeVar423 );
			p11_nodeVar426 = ( ( ( ( p11_nodeVar425 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar424 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar427 = ( ( ( p11_nodeVar422 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar426 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar423 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar423 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar423 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar426 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar428 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar427.x, p11_nodeVar427.y ), 0.0 );
			p11_nodeVar429 = ( p11_nodeVar425 / vec2<f32>( 6.0 ) );
			p11_nodeVar430 = ( ( ( ( ( ( p11_nodeVar425 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar424 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar423 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar429 );
			p11_nodeVar431 = ( ( ( p11_nodeVar422 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar429 / p11_nodeVar430 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar432 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar431.x, p11_nodeVar427.y ), 0.0 );
			p11_nodeVar433 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar427.x, p11_nodeVar431.y ), 0.0 );
			p11_nodeVar434 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar431.x, p11_nodeVar431.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar428, p11_nodeVar432, p11_nodeVar430.x ), mix( p11_nodeVar433, p11_nodeVar434, p11_nodeVar430.x ), p11_nodeVar430.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar435 = ( ( p11_nodeVar420 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar436 = floor( p11_nodeVar435 );
				p11_nodeVar437 = ( p11_nodeVar435 - p11_nodeVar436 );
				p11_nodeVar438 = ( p11_nodeVar437 * p11_nodeVar437 );
				p11_nodeVar439 = ( p11_nodeVar438 * p11_nodeVar437 );
				p11_nodeVar440 = ( ( ( ( p11_nodeVar439 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar438 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar441 = ( ( ( p11_nodeVar436 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar440 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar437 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar437 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar437 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar440 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar442 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar441.x, p11_nodeVar441.y ), 0.0 );
				p11_nodeVar443 = ( p11_nodeVar439 / vec2<f32>( 6.0 ) );
				p11_nodeVar444 = ( ( ( ( ( ( p11_nodeVar439 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar438 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar437 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar443 );
				p11_nodeVar445 = ( ( ( p11_nodeVar436 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar443 / p11_nodeVar444 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar446 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar445.x, p11_nodeVar441.y ), 0.0 );
				p11_nodeVar447 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar441.x, p11_nodeVar445.y ), 0.0 );
				p11_nodeVar448 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar445.x, p11_nodeVar445.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar442, p11_nodeVar446, p11_nodeVar444.x ), mix( p11_nodeVar447, p11_nodeVar448, p11_nodeVar444.x ), p11_nodeVar444.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 3.0 ) ) {

			p11_nodeVar449 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar450 = vec2<f32>( ( - p11_nodeVar449.y ), p11_nodeVar449.x );
			p11_nodeVar451 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar449 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar449 ) + ( p11_nodeVar450 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar450 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar452 = ( ( p11_nodeVar451 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar453 = floor( p11_nodeVar452 );
			p11_nodeVar454 = ( p11_nodeVar452 - p11_nodeVar453 );
			p11_nodeVar455 = ( p11_nodeVar454 * p11_nodeVar454 );
			p11_nodeVar456 = ( p11_nodeVar455 * p11_nodeVar454 );
			p11_nodeVar457 = ( ( ( ( p11_nodeVar456 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar455 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar458 = ( ( ( p11_nodeVar453 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar457 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar454 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar454 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar454 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar457 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar459 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar458.x, p11_nodeVar458.y ), 0.0 );
			p11_nodeVar460 = ( p11_nodeVar456 / vec2<f32>( 6.0 ) );
			p11_nodeVar461 = ( ( ( ( ( ( p11_nodeVar456 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar455 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar454 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar460 );
			p11_nodeVar462 = ( ( ( p11_nodeVar453 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar460 / p11_nodeVar461 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar463 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar462.x, p11_nodeVar458.y ), 0.0 );
			p11_nodeVar464 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar458.x, p11_nodeVar462.y ), 0.0 );
			p11_nodeVar465 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar462.x, p11_nodeVar462.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar459, p11_nodeVar463, p11_nodeVar461.x ), mix( p11_nodeVar464, p11_nodeVar465, p11_nodeVar461.x ), p11_nodeVar461.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar466 = ( ( p11_nodeVar451 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar467 = floor( p11_nodeVar466 );
				p11_nodeVar468 = ( p11_nodeVar466 - p11_nodeVar467 );
				p11_nodeVar469 = ( p11_nodeVar468 * p11_nodeVar468 );
				p11_nodeVar470 = ( p11_nodeVar469 * p11_nodeVar468 );
				p11_nodeVar471 = ( ( ( ( p11_nodeVar470 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar469 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar472 = ( ( ( p11_nodeVar467 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar471 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar468 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar468 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar468 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar471 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar473 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar472.x, p11_nodeVar472.y ), 0.0 );
				p11_nodeVar474 = ( p11_nodeVar470 / vec2<f32>( 6.0 ) );
				p11_nodeVar475 = ( ( ( ( ( ( p11_nodeVar470 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar469 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar468 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar474 );
				p11_nodeVar476 = ( ( ( p11_nodeVar467 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar474 / p11_nodeVar475 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar477 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar476.x, p11_nodeVar472.y ), 0.0 );
				p11_nodeVar478 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar472.x, p11_nodeVar476.y ), 0.0 );
				p11_nodeVar479 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar476.x, p11_nodeVar476.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar473, p11_nodeVar477, p11_nodeVar475.x ), mix( p11_nodeVar478, p11_nodeVar479, p11_nodeVar475.x ), p11_nodeVar475.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 4.0 ) ) {

			p11_nodeVar480 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar481 = vec2<f32>( ( - p11_nodeVar480.y ), p11_nodeVar480.x );
			p11_nodeVar482 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar480 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar480 ) + ( p11_nodeVar481 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar481 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar483 = ( ( p11_nodeVar482 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar484 = floor( p11_nodeVar483 );
			p11_nodeVar485 = ( p11_nodeVar483 - p11_nodeVar484 );
			p11_nodeVar486 = ( p11_nodeVar485 * p11_nodeVar485 );
			p11_nodeVar487 = ( p11_nodeVar486 * p11_nodeVar485 );
			p11_nodeVar488 = ( ( ( ( p11_nodeVar487 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar486 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar489 = ( ( ( p11_nodeVar484 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar488 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar485 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar485 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar485 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar488 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar490 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar489.x, p11_nodeVar489.y ), 0.0 );
			p11_nodeVar491 = ( p11_nodeVar487 / vec2<f32>( 6.0 ) );
			p11_nodeVar492 = ( ( ( ( ( ( p11_nodeVar487 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar486 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar485 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar491 );
			p11_nodeVar493 = ( ( ( p11_nodeVar484 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar491 / p11_nodeVar492 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar494 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar493.x, p11_nodeVar489.y ), 0.0 );
			p11_nodeVar495 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar489.x, p11_nodeVar493.y ), 0.0 );
			p11_nodeVar496 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar493.x, p11_nodeVar493.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar490, p11_nodeVar494, p11_nodeVar492.x ), mix( p11_nodeVar495, p11_nodeVar496, p11_nodeVar492.x ), p11_nodeVar492.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar497 = ( ( p11_nodeVar482 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar498 = floor( p11_nodeVar497 );
				p11_nodeVar499 = ( p11_nodeVar497 - p11_nodeVar498 );
				p11_nodeVar500 = ( p11_nodeVar499 * p11_nodeVar499 );
				p11_nodeVar501 = ( p11_nodeVar500 * p11_nodeVar499 );
				p11_nodeVar502 = ( ( ( ( p11_nodeVar501 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar500 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar503 = ( ( ( p11_nodeVar498 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar502 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar499 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar499 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar499 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar502 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar504 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar503.x, p11_nodeVar503.y ), 0.0 );
				p11_nodeVar505 = ( p11_nodeVar501 / vec2<f32>( 6.0 ) );
				p11_nodeVar506 = ( ( ( ( ( ( p11_nodeVar501 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar500 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar499 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar505 );
				p11_nodeVar507 = ( ( ( p11_nodeVar498 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar505 / p11_nodeVar506 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar508 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar507.x, p11_nodeVar503.y ), 0.0 );
				p11_nodeVar509 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar503.x, p11_nodeVar507.y ), 0.0 );
				p11_nodeVar510 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar507.x, p11_nodeVar507.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar504, p11_nodeVar508, p11_nodeVar506.x ), mix( p11_nodeVar509, p11_nodeVar510, p11_nodeVar506.x ), p11_nodeVar506.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 5.0 ) ) {

			p11_nodeVar511 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar512 = vec2<f32>( ( - p11_nodeVar511.y ), p11_nodeVar511.x );
			p11_nodeVar513 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar511 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar511 ) + ( p11_nodeVar512 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar512 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar514 = ( ( p11_nodeVar513 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar515 = floor( p11_nodeVar514 );
			p11_nodeVar516 = ( p11_nodeVar514 - p11_nodeVar515 );
			p11_nodeVar517 = ( p11_nodeVar516 * p11_nodeVar516 );
			p11_nodeVar518 = ( p11_nodeVar517 * p11_nodeVar516 );
			p11_nodeVar519 = ( ( ( ( p11_nodeVar518 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar517 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar520 = ( ( ( p11_nodeVar515 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar519 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar516 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar516 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar516 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar519 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar521 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar520.x, p11_nodeVar520.y ), 0.0 );
			p11_nodeVar522 = ( p11_nodeVar518 / vec2<f32>( 6.0 ) );
			p11_nodeVar523 = ( ( ( ( ( ( p11_nodeVar518 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar517 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar516 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar522 );
			p11_nodeVar524 = ( ( ( p11_nodeVar515 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar522 / p11_nodeVar523 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar525 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar524.x, p11_nodeVar520.y ), 0.0 );
			p11_nodeVar526 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar520.x, p11_nodeVar524.y ), 0.0 );
			p11_nodeVar527 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar524.x, p11_nodeVar524.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar521, p11_nodeVar525, p11_nodeVar523.x ), mix( p11_nodeVar526, p11_nodeVar527, p11_nodeVar523.x ), p11_nodeVar523.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar528 = ( ( p11_nodeVar513 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar529 = floor( p11_nodeVar528 );
				p11_nodeVar530 = ( p11_nodeVar528 - p11_nodeVar529 );
				p11_nodeVar531 = ( p11_nodeVar530 * p11_nodeVar530 );
				p11_nodeVar532 = ( p11_nodeVar531 * p11_nodeVar530 );
				p11_nodeVar533 = ( ( ( ( p11_nodeVar532 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar531 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar534 = ( ( ( p11_nodeVar529 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar533 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar530 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar530 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar530 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar533 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar535 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar534.x, p11_nodeVar534.y ), 0.0 );
				p11_nodeVar536 = ( p11_nodeVar532 / vec2<f32>( 6.0 ) );
				p11_nodeVar537 = ( ( ( ( ( ( p11_nodeVar532 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar531 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar530 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar536 );
				p11_nodeVar538 = ( ( ( p11_nodeVar529 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar536 / p11_nodeVar537 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar539 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar538.x, p11_nodeVar534.y ), 0.0 );
				p11_nodeVar540 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar534.x, p11_nodeVar538.y ), 0.0 );
				p11_nodeVar541 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar538.x, p11_nodeVar538.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar535, p11_nodeVar539, p11_nodeVar537.x ), mix( p11_nodeVar540, p11_nodeVar541, p11_nodeVar537.x ), p11_nodeVar537.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 6.0 ) ) {

			p11_nodeVar542 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar543 = vec2<f32>( ( - p11_nodeVar542.y ), p11_nodeVar542.x );
			p11_nodeVar544 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar542 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar542 ) + ( p11_nodeVar543 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar543 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar545 = ( ( p11_nodeVar544 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar546 = floor( p11_nodeVar545 );
			p11_nodeVar547 = ( p11_nodeVar545 - p11_nodeVar546 );
			p11_nodeVar548 = ( p11_nodeVar547 * p11_nodeVar547 );
			p11_nodeVar549 = ( p11_nodeVar548 * p11_nodeVar547 );
			p11_nodeVar550 = ( ( ( ( p11_nodeVar549 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar548 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar551 = ( ( ( p11_nodeVar546 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar550 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar547 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar547 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar547 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar550 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar552 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar551.x, p11_nodeVar551.y ), 0.0 );
			p11_nodeVar553 = ( p11_nodeVar549 / vec2<f32>( 6.0 ) );
			p11_nodeVar554 = ( ( ( ( ( ( p11_nodeVar549 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar548 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar547 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar553 );
			p11_nodeVar555 = ( ( ( p11_nodeVar546 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar553 / p11_nodeVar554 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar556 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar555.x, p11_nodeVar551.y ), 0.0 );
			p11_nodeVar557 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar551.x, p11_nodeVar555.y ), 0.0 );
			p11_nodeVar558 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar555.x, p11_nodeVar555.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar552, p11_nodeVar556, p11_nodeVar554.x ), mix( p11_nodeVar557, p11_nodeVar558, p11_nodeVar554.x ), p11_nodeVar554.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar559 = ( ( p11_nodeVar544 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar560 = floor( p11_nodeVar559 );
				p11_nodeVar561 = ( p11_nodeVar559 - p11_nodeVar560 );
				p11_nodeVar562 = ( p11_nodeVar561 * p11_nodeVar561 );
				p11_nodeVar563 = ( p11_nodeVar562 * p11_nodeVar561 );
				p11_nodeVar564 = ( ( ( ( p11_nodeVar563 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar562 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar565 = ( ( ( p11_nodeVar560 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar564 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar561 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar561 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar561 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar564 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar566 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar565.x, p11_nodeVar565.y ), 0.0 );
				p11_nodeVar567 = ( p11_nodeVar563 / vec2<f32>( 6.0 ) );
				p11_nodeVar568 = ( ( ( ( ( ( p11_nodeVar563 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar562 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar561 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar567 );
				p11_nodeVar569 = ( ( ( p11_nodeVar560 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar567 / p11_nodeVar568 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar570 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar569.x, p11_nodeVar565.y ), 0.0 );
				p11_nodeVar571 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar565.x, p11_nodeVar569.y ), 0.0 );
				p11_nodeVar572 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar569.x, p11_nodeVar569.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar566, p11_nodeVar570, p11_nodeVar568.x ), mix( p11_nodeVar571, p11_nodeVar572, p11_nodeVar568.x ), p11_nodeVar568.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 7.0 ) ) {

			p11_nodeVar573 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar574 = vec2<f32>( ( - p11_nodeVar573.y ), p11_nodeVar573.x );
			p11_nodeVar575 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar573 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar573 ) + ( p11_nodeVar574 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar574 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar576 = ( ( p11_nodeVar575 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar577 = floor( p11_nodeVar576 );
			p11_nodeVar578 = ( p11_nodeVar576 - p11_nodeVar577 );
			p11_nodeVar579 = ( p11_nodeVar578 * p11_nodeVar578 );
			p11_nodeVar580 = ( p11_nodeVar579 * p11_nodeVar578 );
			p11_nodeVar581 = ( ( ( ( p11_nodeVar580 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar579 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar582 = ( ( ( p11_nodeVar577 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar581 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar578 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar578 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar578 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar581 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar583 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar582.x, p11_nodeVar582.y ), 0.0 );
			p11_nodeVar584 = ( p11_nodeVar580 / vec2<f32>( 6.0 ) );
			p11_nodeVar585 = ( ( ( ( ( ( p11_nodeVar580 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar579 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar578 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar584 );
			p11_nodeVar586 = ( ( ( p11_nodeVar577 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar584 / p11_nodeVar585 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar587 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar586.x, p11_nodeVar582.y ), 0.0 );
			p11_nodeVar588 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar582.x, p11_nodeVar586.y ), 0.0 );
			p11_nodeVar589 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar586.x, p11_nodeVar586.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar583, p11_nodeVar587, p11_nodeVar585.x ), mix( p11_nodeVar588, p11_nodeVar589, p11_nodeVar585.x ), p11_nodeVar585.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar590 = ( ( p11_nodeVar575 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar591 = floor( p11_nodeVar590 );
				p11_nodeVar592 = ( p11_nodeVar590 - p11_nodeVar591 );
				p11_nodeVar593 = ( p11_nodeVar592 * p11_nodeVar592 );
				p11_nodeVar594 = ( p11_nodeVar593 * p11_nodeVar592 );
				p11_nodeVar595 = ( ( ( ( p11_nodeVar594 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar593 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar596 = ( ( ( p11_nodeVar591 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar595 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar592 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar592 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar592 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar595 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar597 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar596.x, p11_nodeVar596.y ), 0.0 );
				p11_nodeVar598 = ( p11_nodeVar594 / vec2<f32>( 6.0 ) );
				p11_nodeVar599 = ( ( ( ( ( ( p11_nodeVar594 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar593 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar592 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar598 );
				p11_nodeVar600 = ( ( ( p11_nodeVar591 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar598 / p11_nodeVar599 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar601 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar600.x, p11_nodeVar596.y ), 0.0 );
				p11_nodeVar602 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar596.x, p11_nodeVar600.y ), 0.0 );
				p11_nodeVar603 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar600.x, p11_nodeVar600.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar597, p11_nodeVar601, p11_nodeVar599.x ), mix( p11_nodeVar602, p11_nodeVar603, p11_nodeVar599.x ), p11_nodeVar599.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 8.0 ) ) {

			p11_nodeVar604 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar605 = vec2<f32>( ( - p11_nodeVar604.y ), p11_nodeVar604.x );
			p11_nodeVar606 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar604 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar604 ) + ( p11_nodeVar605 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar605 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar607 = ( ( p11_nodeVar606 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar608 = floor( p11_nodeVar607 );
			p11_nodeVar609 = ( p11_nodeVar607 - p11_nodeVar608 );
			p11_nodeVar610 = ( p11_nodeVar609 * p11_nodeVar609 );
			p11_nodeVar611 = ( p11_nodeVar610 * p11_nodeVar609 );
			p11_nodeVar612 = ( ( ( ( p11_nodeVar611 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar610 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar613 = ( ( ( p11_nodeVar608 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar612 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar609 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar609 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar609 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar612 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar614 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar613.x, p11_nodeVar613.y ), 0.0 );
			p11_nodeVar615 = ( p11_nodeVar611 / vec2<f32>( 6.0 ) );
			p11_nodeVar616 = ( ( ( ( ( ( p11_nodeVar611 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar610 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar609 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar615 );
			p11_nodeVar617 = ( ( ( p11_nodeVar608 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar615 / p11_nodeVar616 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar618 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar617.x, p11_nodeVar613.y ), 0.0 );
			p11_nodeVar619 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar613.x, p11_nodeVar617.y ), 0.0 );
			p11_nodeVar620 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar617.x, p11_nodeVar617.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar614, p11_nodeVar618, p11_nodeVar616.x ), mix( p11_nodeVar619, p11_nodeVar620, p11_nodeVar616.x ), p11_nodeVar616.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar621 = ( ( p11_nodeVar606 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar622 = floor( p11_nodeVar621 );
				p11_nodeVar623 = ( p11_nodeVar621 - p11_nodeVar622 );
				p11_nodeVar624 = ( p11_nodeVar623 * p11_nodeVar623 );
				p11_nodeVar625 = ( p11_nodeVar624 * p11_nodeVar623 );
				p11_nodeVar626 = ( ( ( ( p11_nodeVar625 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar624 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar627 = ( ( ( p11_nodeVar622 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar626 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar623 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar623 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar623 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar626 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar628 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar627.x, p11_nodeVar627.y ), 0.0 );
				p11_nodeVar629 = ( p11_nodeVar625 / vec2<f32>( 6.0 ) );
				p11_nodeVar630 = ( ( ( ( ( ( p11_nodeVar625 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar624 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar623 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar629 );
				p11_nodeVar631 = ( ( ( p11_nodeVar622 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar629 / p11_nodeVar630 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar632 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar631.x, p11_nodeVar627.y ), 0.0 );
				p11_nodeVar633 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar627.x, p11_nodeVar631.y ), 0.0 );
				p11_nodeVar634 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar631.x, p11_nodeVar631.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar628, p11_nodeVar632, p11_nodeVar630.x ), mix( p11_nodeVar633, p11_nodeVar634, p11_nodeVar630.x ), p11_nodeVar630.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 == 9.0 ) ) {

			p11_nodeVar635 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar636 = vec2<f32>( ( - p11_nodeVar635.y ), p11_nodeVar635.x );
			p11_nodeVar637 = ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar635 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar635 ) + ( p11_nodeVar636 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar636 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar638 = ( ( p11_nodeVar637 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar639 = floor( p11_nodeVar638 );
			p11_nodeVar640 = ( p11_nodeVar638 - p11_nodeVar639 );
			p11_nodeVar641 = ( p11_nodeVar640 * p11_nodeVar640 );
			p11_nodeVar642 = ( p11_nodeVar641 * p11_nodeVar640 );
			p11_nodeVar643 = ( ( ( ( p11_nodeVar642 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar641 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar644 = ( ( ( p11_nodeVar639 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar643 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar640 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar640 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar640 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar643 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar645 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar644.x, p11_nodeVar644.y ), 0.0 );
			p11_nodeVar646 = ( p11_nodeVar642 / vec2<f32>( 6.0 ) );
			p11_nodeVar647 = ( ( ( ( ( ( p11_nodeVar642 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar641 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar640 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar646 );
			p11_nodeVar648 = ( ( ( p11_nodeVar639 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar646 / p11_nodeVar647 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar649 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar648.x, p11_nodeVar644.y ), 0.0 );
			p11_nodeVar650 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar644.x, p11_nodeVar648.y ), 0.0 );
			p11_nodeVar651 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar648.x, p11_nodeVar648.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar645, p11_nodeVar649, p11_nodeVar647.x ), mix( p11_nodeVar650, p11_nodeVar651, p11_nodeVar647.x ), p11_nodeVar647.y );

			if ( ( p11_nodeVar368 > 0.0 ) ) {

				p11_nodeVar652 = ( ( p11_nodeVar637 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar653 = floor( p11_nodeVar652 );
				p11_nodeVar654 = ( p11_nodeVar652 - p11_nodeVar653 );
				p11_nodeVar655 = ( p11_nodeVar654 * p11_nodeVar654 );
				p11_nodeVar656 = ( p11_nodeVar655 * p11_nodeVar654 );
				p11_nodeVar657 = ( ( ( ( p11_nodeVar656 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar655 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar658 = ( ( ( p11_nodeVar653 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar657 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar654 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar654 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar654 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar657 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar659 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar658.x, p11_nodeVar658.y ), 0.0 );
				p11_nodeVar660 = ( p11_nodeVar656 / vec2<f32>( 6.0 ) );
				p11_nodeVar661 = ( ( ( ( ( ( p11_nodeVar656 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar655 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar654 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar660 );
				p11_nodeVar662 = ( ( ( p11_nodeVar653 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar660 / p11_nodeVar661 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar663 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar662.x, p11_nodeVar658.y ), 0.0 );
				p11_nodeVar664 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar658.x, p11_nodeVar662.y ), 0.0 );
				p11_nodeVar665 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar662.x, p11_nodeVar662.y ), 0.0 );
				p11_nodeVar365 = mix( p11_nodeVar365, mix( mix( p11_nodeVar659, p11_nodeVar663, p11_nodeVar661.x ), mix( p11_nodeVar664, p11_nodeVar665, p11_nodeVar661.x ), p11_nodeVar661.y ), p11_nodeVar368 );
				

			}

			

		}


		if ( ( p11_nodeVar367 >= 10.0 ) ) {

			p11_nodeVar666 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
			p11_nodeVar667 = vec2<f32>( ( - p11_nodeVar666.y ), p11_nodeVar666.x );
			p11_nodeVar668 = ( ( ( ( ( vec2<f32>( ( floor( ( ( dot( p11_nodeVar35, p11_nodeVar666 ) / f32(knobs.gap) ) + 0.5 ) ) * f32(knobs.gap) ) ) * p11_nodeVar666 ) + ( p11_nodeVar667 * vec2<f32>( dot( p11_nodeVar35, p11_nodeVar667 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar669 = floor( p11_nodeVar668 );
			p11_nodeVar670 = ( p11_nodeVar668 - p11_nodeVar669 );
			p11_nodeVar671 = ( p11_nodeVar670 * p11_nodeVar670 );
			p11_nodeVar672 = ( p11_nodeVar671 * p11_nodeVar670 );
			p11_nodeVar673 = ( ( ( ( p11_nodeVar672 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar671 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar674 = ( ( ( p11_nodeVar669 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar673 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar670 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar670 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar670 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar673 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar675 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar674.x, p11_nodeVar674.y ), 0.0 );
			p11_nodeVar676 = ( p11_nodeVar672 / vec2<f32>( 6.0 ) );
			p11_nodeVar677 = ( ( ( ( ( ( p11_nodeVar672 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar671 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar670 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar676 );
			p11_nodeVar678 = ( ( ( p11_nodeVar669 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar676 / p11_nodeVar677 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar679 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar678.x, p11_nodeVar674.y ), 0.0 );
			p11_nodeVar680 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar674.x, p11_nodeVar678.y ), 0.0 );
			p11_nodeVar681 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar678.x, p11_nodeVar678.y ), 0.0 );
			p11_nodeVar365 = mix( mix( p11_nodeVar675, p11_nodeVar679, p11_nodeVar677.x ), mix( p11_nodeVar680, p11_nodeVar681, p11_nodeVar677.x ), p11_nodeVar677.y );
			

		}

		p11_nodeVar683 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
		p11_nodeVar684 = clamp( dot( vec3<f32>( p11_nodeVar683.x, p11_nodeVar683.y, p11_nodeVar683.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar684 <= 0.0031308 ) ) {

			p11_nodeVar682 = ( p11_nodeVar684 * 12.92 );

		} else {

			p11_nodeVar682 = ( ( pow( p11_nodeVar684, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar685 = ( mix( f32(knobs.weight), ( f32(knobs.weight) * 2.2 ), ( f32(knobs.pressure) * ( ( 1.0 - p11_nodeVar682 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) ) ) ) * 0.5 );
		p11_nodeVar686 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar687 = vec2<f32>( cos( f32((0.017453292519943295 * knobs.angle + 0)) ), sin( f32((0.017453292519943295 * knobs.angle + 0)) ) );
		p11_nodeVar688 = ( dot( p11_nodeVar35, p11_nodeVar687 ) / f32(knobs.gap) );
		p11_nodeVar689 = floor( ( p11_nodeVar688 + 0.5 ) );
		p11_nodeVar691 = vec4<f32>( ( p11_nodeVar365.xyz / vec3<f32>( max( p11_nodeVar365.w, 0.0001 ) ) ), p11_nodeVar365.w );
		p11_nodeVar692 = clamp( dot( vec3<f32>( p11_nodeVar691.x, p11_nodeVar691.y, p11_nodeVar691.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar692 <= 0.0031308 ) ) {

			p11_nodeVar690 = ( p11_nodeVar692 * 12.92 );

		} else {

			p11_nodeVar690 = ( ( pow( p11_nodeVar692, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar693 = ( ( 1.0 - p11_nodeVar690 ) * clamp( p11_nodeVar365.w, 0.0, 1.0 ) );
		p11_nodeVar694 = ( ( ( pow( p11_nodeVar693, 1.6 ) * f32(knobs.amplitude) ) * f32(knobs.gap) ) * 0.95 );
		p11_nodeVar695 = dot( p11_nodeVar35, vec2<f32>( ( - p11_nodeVar687.y ), p11_nodeVar687.x ) );
		p11_nodeVar696 = ( ( f32(knobs.frequency) * 6.283185307179586 ) / f32(knobs.gap) );
		p11_nodeVar697 = ( ( p11_nodeVar694 * p11_nodeVar696 ) * cos( ( ( p11_nodeVar695 * p11_nodeVar696 ) + ( p11_nodeVar689 * 1.7 ) ) ) );
		p11_nodeVar348 = ( ( 1.0 - smoothstep( ( p11_nodeVar685 - p11_nodeVar686 ), ( p11_nodeVar685 + p11_nodeVar686 ), ( abs( ( ( ( p11_nodeVar688 - p11_nodeVar689 ) * f32(knobs.gap) ) - ( p11_nodeVar694 * sin( ( ( p11_nodeVar695 * p11_nodeVar696 ) + ( p11_nodeVar689 * 1.7 ) ) ) ) ) ) / sqrt( ( 1.0 + ( p11_nodeVar697 * p11_nodeVar697 ) ) ) ) ) ) * smoothstep( 0.02, 0.12, ( p11_nodeVar693 + ( f32(knobs.threshold) * 0.1 ) ) ) );
		

	}


	if ( ( ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) > 1.5 ) && ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) < 3.5 ) ) ) {

		p11_nodeVar698 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p11_nodeVar699 = clamp( p11_nodeVar37, 0.0, 10.0 );
		p11_nodeVar700 = floor( p11_nodeVar699 );
		p11_nodeVar701 = ( p11_nodeVar699 - p11_nodeVar700 );

		if ( ( p11_nodeVar700 == 0.0 ) ) {

			p11_nodeVar702 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar703 = picture_read_level( p11_nodeVar702, 0.0 );
			p11_nodeVar698 = vec4<f32>( ( vec3<f32>( p11_nodeVar703.x, p11_nodeVar703.y, p11_nodeVar703.z ) * vec3<f32>( p11_nodeVar703.w ) ), p11_nodeVar703.w );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar704 = ( ( p11_nodeVar702 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar705 = floor( p11_nodeVar704 );
				p11_nodeVar706 = ( p11_nodeVar704 - p11_nodeVar705 );
				p11_nodeVar707 = ( p11_nodeVar706 * p11_nodeVar706 );
				p11_nodeVar708 = ( p11_nodeVar707 * p11_nodeVar706 );
				p11_nodeVar709 = ( ( ( ( p11_nodeVar708 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar707 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar710 = ( ( ( p11_nodeVar705 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar709 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar706 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar706 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar706 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar709 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar711 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar710.x, p11_nodeVar710.y ), 0.0 );
				p11_nodeVar712 = ( p11_nodeVar708 / vec2<f32>( 6.0 ) );
				p11_nodeVar713 = ( ( ( ( ( ( p11_nodeVar708 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar707 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar706 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar712 );
				p11_nodeVar714 = ( ( ( p11_nodeVar705 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar712 / p11_nodeVar713 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar715 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar714.x, p11_nodeVar710.y ), 0.0 );
				p11_nodeVar716 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar710.x, p11_nodeVar714.y ), 0.0 );
				p11_nodeVar717 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar714.x, p11_nodeVar714.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar711, p11_nodeVar715, p11_nodeVar713.x ), mix( p11_nodeVar716, p11_nodeVar717, p11_nodeVar713.x ), p11_nodeVar713.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 1.0 ) ) {

			p11_nodeVar718 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar719 = ( ( p11_nodeVar718 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar720 = floor( p11_nodeVar719 );
			p11_nodeVar721 = ( p11_nodeVar719 - p11_nodeVar720 );
			p11_nodeVar722 = ( p11_nodeVar721 * p11_nodeVar721 );
			p11_nodeVar723 = ( p11_nodeVar722 * p11_nodeVar721 );
			p11_nodeVar724 = ( ( ( ( p11_nodeVar723 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar722 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar725 = ( ( ( p11_nodeVar720 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar724 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar721 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar721 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar721 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar724 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar726 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar725.x, p11_nodeVar725.y ), 0.0 );
			p11_nodeVar727 = ( p11_nodeVar723 / vec2<f32>( 6.0 ) );
			p11_nodeVar728 = ( ( ( ( ( ( p11_nodeVar723 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar722 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar721 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar727 );
			p11_nodeVar729 = ( ( ( p11_nodeVar720 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar727 / p11_nodeVar728 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar730 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar729.x, p11_nodeVar725.y ), 0.0 );
			p11_nodeVar731 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar725.x, p11_nodeVar729.y ), 0.0 );
			p11_nodeVar732 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar729.x, p11_nodeVar729.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar726, p11_nodeVar730, p11_nodeVar728.x ), mix( p11_nodeVar731, p11_nodeVar732, p11_nodeVar728.x ), p11_nodeVar728.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar733 = ( ( p11_nodeVar718 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar734 = floor( p11_nodeVar733 );
				p11_nodeVar735 = ( p11_nodeVar733 - p11_nodeVar734 );
				p11_nodeVar736 = ( p11_nodeVar735 * p11_nodeVar735 );
				p11_nodeVar737 = ( p11_nodeVar736 * p11_nodeVar735 );
				p11_nodeVar738 = ( ( ( ( p11_nodeVar737 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar736 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar739 = ( ( ( p11_nodeVar734 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar738 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar735 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar735 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar735 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar738 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar740 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar739.x, p11_nodeVar739.y ), 0.0 );
				p11_nodeVar741 = ( p11_nodeVar737 / vec2<f32>( 6.0 ) );
				p11_nodeVar742 = ( ( ( ( ( ( p11_nodeVar737 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar736 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar735 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar741 );
				p11_nodeVar743 = ( ( ( p11_nodeVar734 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar741 / p11_nodeVar742 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar744 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar743.x, p11_nodeVar739.y ), 0.0 );
				p11_nodeVar745 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar739.x, p11_nodeVar743.y ), 0.0 );
				p11_nodeVar746 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar743.x, p11_nodeVar743.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar740, p11_nodeVar744, p11_nodeVar742.x ), mix( p11_nodeVar745, p11_nodeVar746, p11_nodeVar742.x ), p11_nodeVar742.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 2.0 ) ) {

			p11_nodeVar747 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar748 = ( ( p11_nodeVar747 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar749 = floor( p11_nodeVar748 );
			p11_nodeVar750 = ( p11_nodeVar748 - p11_nodeVar749 );
			p11_nodeVar751 = ( p11_nodeVar750 * p11_nodeVar750 );
			p11_nodeVar752 = ( p11_nodeVar751 * p11_nodeVar750 );
			p11_nodeVar753 = ( ( ( ( p11_nodeVar752 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar751 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar754 = ( ( ( p11_nodeVar749 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar753 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar750 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar750 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar750 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar753 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar755 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar754.x, p11_nodeVar754.y ), 0.0 );
			p11_nodeVar756 = ( p11_nodeVar752 / vec2<f32>( 6.0 ) );
			p11_nodeVar757 = ( ( ( ( ( ( p11_nodeVar752 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar751 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar750 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar756 );
			p11_nodeVar758 = ( ( ( p11_nodeVar749 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar756 / p11_nodeVar757 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar759 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar758.x, p11_nodeVar754.y ), 0.0 );
			p11_nodeVar760 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar754.x, p11_nodeVar758.y ), 0.0 );
			p11_nodeVar761 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar758.x, p11_nodeVar758.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar755, p11_nodeVar759, p11_nodeVar757.x ), mix( p11_nodeVar760, p11_nodeVar761, p11_nodeVar757.x ), p11_nodeVar757.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar762 = ( ( p11_nodeVar747 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar763 = floor( p11_nodeVar762 );
				p11_nodeVar764 = ( p11_nodeVar762 - p11_nodeVar763 );
				p11_nodeVar765 = ( p11_nodeVar764 * p11_nodeVar764 );
				p11_nodeVar766 = ( p11_nodeVar765 * p11_nodeVar764 );
				p11_nodeVar767 = ( ( ( ( p11_nodeVar766 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar765 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar768 = ( ( ( p11_nodeVar763 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar767 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar764 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar764 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar764 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar767 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar769 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar768.x, p11_nodeVar768.y ), 0.0 );
				p11_nodeVar770 = ( p11_nodeVar766 / vec2<f32>( 6.0 ) );
				p11_nodeVar771 = ( ( ( ( ( ( p11_nodeVar766 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar765 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar764 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar770 );
				p11_nodeVar772 = ( ( ( p11_nodeVar763 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar770 / p11_nodeVar771 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar773 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar772.x, p11_nodeVar768.y ), 0.0 );
				p11_nodeVar774 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar768.x, p11_nodeVar772.y ), 0.0 );
				p11_nodeVar775 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar772.x, p11_nodeVar772.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar769, p11_nodeVar773, p11_nodeVar771.x ), mix( p11_nodeVar774, p11_nodeVar775, p11_nodeVar771.x ), p11_nodeVar771.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 3.0 ) ) {

			p11_nodeVar776 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar777 = ( ( p11_nodeVar776 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar778 = floor( p11_nodeVar777 );
			p11_nodeVar779 = ( p11_nodeVar777 - p11_nodeVar778 );
			p11_nodeVar780 = ( p11_nodeVar779 * p11_nodeVar779 );
			p11_nodeVar781 = ( p11_nodeVar780 * p11_nodeVar779 );
			p11_nodeVar782 = ( ( ( ( p11_nodeVar781 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar780 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar783 = ( ( ( p11_nodeVar778 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar782 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar779 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar779 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar779 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar782 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar784 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar783.x, p11_nodeVar783.y ), 0.0 );
			p11_nodeVar785 = ( p11_nodeVar781 / vec2<f32>( 6.0 ) );
			p11_nodeVar786 = ( ( ( ( ( ( p11_nodeVar781 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar780 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar779 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar785 );
			p11_nodeVar787 = ( ( ( p11_nodeVar778 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar785 / p11_nodeVar786 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar788 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar787.x, p11_nodeVar783.y ), 0.0 );
			p11_nodeVar789 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar783.x, p11_nodeVar787.y ), 0.0 );
			p11_nodeVar790 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar787.x, p11_nodeVar787.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar784, p11_nodeVar788, p11_nodeVar786.x ), mix( p11_nodeVar789, p11_nodeVar790, p11_nodeVar786.x ), p11_nodeVar786.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar791 = ( ( p11_nodeVar776 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar792 = floor( p11_nodeVar791 );
				p11_nodeVar793 = ( p11_nodeVar791 - p11_nodeVar792 );
				p11_nodeVar794 = ( p11_nodeVar793 * p11_nodeVar793 );
				p11_nodeVar795 = ( p11_nodeVar794 * p11_nodeVar793 );
				p11_nodeVar796 = ( ( ( ( p11_nodeVar795 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar794 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar797 = ( ( ( p11_nodeVar792 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar796 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar793 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar793 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar793 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar796 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar798 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar797.x, p11_nodeVar797.y ), 0.0 );
				p11_nodeVar799 = ( p11_nodeVar795 / vec2<f32>( 6.0 ) );
				p11_nodeVar800 = ( ( ( ( ( ( p11_nodeVar795 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar794 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar793 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar799 );
				p11_nodeVar801 = ( ( ( p11_nodeVar792 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar799 / p11_nodeVar800 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar802 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar801.x, p11_nodeVar797.y ), 0.0 );
				p11_nodeVar803 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar797.x, p11_nodeVar801.y ), 0.0 );
				p11_nodeVar804 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar801.x, p11_nodeVar801.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar798, p11_nodeVar802, p11_nodeVar800.x ), mix( p11_nodeVar803, p11_nodeVar804, p11_nodeVar800.x ), p11_nodeVar800.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 4.0 ) ) {

			p11_nodeVar805 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar806 = ( ( p11_nodeVar805 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar807 = floor( p11_nodeVar806 );
			p11_nodeVar808 = ( p11_nodeVar806 - p11_nodeVar807 );
			p11_nodeVar809 = ( p11_nodeVar808 * p11_nodeVar808 );
			p11_nodeVar810 = ( p11_nodeVar809 * p11_nodeVar808 );
			p11_nodeVar811 = ( ( ( ( p11_nodeVar810 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar809 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar812 = ( ( ( p11_nodeVar807 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar811 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar808 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar808 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar808 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar811 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar813 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar812.x, p11_nodeVar812.y ), 0.0 );
			p11_nodeVar814 = ( p11_nodeVar810 / vec2<f32>( 6.0 ) );
			p11_nodeVar815 = ( ( ( ( ( ( p11_nodeVar810 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar809 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar808 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar814 );
			p11_nodeVar816 = ( ( ( p11_nodeVar807 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar814 / p11_nodeVar815 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar817 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar816.x, p11_nodeVar812.y ), 0.0 );
			p11_nodeVar818 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar812.x, p11_nodeVar816.y ), 0.0 );
			p11_nodeVar819 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar816.x, p11_nodeVar816.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar813, p11_nodeVar817, p11_nodeVar815.x ), mix( p11_nodeVar818, p11_nodeVar819, p11_nodeVar815.x ), p11_nodeVar815.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar820 = ( ( p11_nodeVar805 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar821 = floor( p11_nodeVar820 );
				p11_nodeVar822 = ( p11_nodeVar820 - p11_nodeVar821 );
				p11_nodeVar823 = ( p11_nodeVar822 * p11_nodeVar822 );
				p11_nodeVar824 = ( p11_nodeVar823 * p11_nodeVar822 );
				p11_nodeVar825 = ( ( ( ( p11_nodeVar824 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar823 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar826 = ( ( ( p11_nodeVar821 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar825 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar822 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar822 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar822 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar825 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar827 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar826.x, p11_nodeVar826.y ), 0.0 );
				p11_nodeVar828 = ( p11_nodeVar824 / vec2<f32>( 6.0 ) );
				p11_nodeVar829 = ( ( ( ( ( ( p11_nodeVar824 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar823 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar822 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar828 );
				p11_nodeVar830 = ( ( ( p11_nodeVar821 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar828 / p11_nodeVar829 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar831 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar830.x, p11_nodeVar826.y ), 0.0 );
				p11_nodeVar832 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar826.x, p11_nodeVar830.y ), 0.0 );
				p11_nodeVar833 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar830.x, p11_nodeVar830.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar827, p11_nodeVar831, p11_nodeVar829.x ), mix( p11_nodeVar832, p11_nodeVar833, p11_nodeVar829.x ), p11_nodeVar829.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 5.0 ) ) {

			p11_nodeVar834 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar835 = ( ( p11_nodeVar834 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar836 = floor( p11_nodeVar835 );
			p11_nodeVar837 = ( p11_nodeVar835 - p11_nodeVar836 );
			p11_nodeVar838 = ( p11_nodeVar837 * p11_nodeVar837 );
			p11_nodeVar839 = ( p11_nodeVar838 * p11_nodeVar837 );
			p11_nodeVar840 = ( ( ( ( p11_nodeVar839 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar838 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar841 = ( ( ( p11_nodeVar836 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar840 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar837 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar837 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar837 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar840 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar842 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar841.x, p11_nodeVar841.y ), 0.0 );
			p11_nodeVar843 = ( p11_nodeVar839 / vec2<f32>( 6.0 ) );
			p11_nodeVar844 = ( ( ( ( ( ( p11_nodeVar839 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar838 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar837 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar843 );
			p11_nodeVar845 = ( ( ( p11_nodeVar836 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar843 / p11_nodeVar844 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar846 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar845.x, p11_nodeVar841.y ), 0.0 );
			p11_nodeVar847 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar841.x, p11_nodeVar845.y ), 0.0 );
			p11_nodeVar848 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar845.x, p11_nodeVar845.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar842, p11_nodeVar846, p11_nodeVar844.x ), mix( p11_nodeVar847, p11_nodeVar848, p11_nodeVar844.x ), p11_nodeVar844.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar849 = ( ( p11_nodeVar834 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar850 = floor( p11_nodeVar849 );
				p11_nodeVar851 = ( p11_nodeVar849 - p11_nodeVar850 );
				p11_nodeVar852 = ( p11_nodeVar851 * p11_nodeVar851 );
				p11_nodeVar853 = ( p11_nodeVar852 * p11_nodeVar851 );
				p11_nodeVar854 = ( ( ( ( p11_nodeVar853 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar852 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar855 = ( ( ( p11_nodeVar850 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar854 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar851 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar851 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar851 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar854 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar856 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar855.x, p11_nodeVar855.y ), 0.0 );
				p11_nodeVar857 = ( p11_nodeVar853 / vec2<f32>( 6.0 ) );
				p11_nodeVar858 = ( ( ( ( ( ( p11_nodeVar853 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar852 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar851 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar857 );
				p11_nodeVar859 = ( ( ( p11_nodeVar850 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar857 / p11_nodeVar858 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar860 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar859.x, p11_nodeVar855.y ), 0.0 );
				p11_nodeVar861 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar855.x, p11_nodeVar859.y ), 0.0 );
				p11_nodeVar862 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar859.x, p11_nodeVar859.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar856, p11_nodeVar860, p11_nodeVar858.x ), mix( p11_nodeVar861, p11_nodeVar862, p11_nodeVar858.x ), p11_nodeVar858.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 6.0 ) ) {

			p11_nodeVar863 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar864 = ( ( p11_nodeVar863 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar865 = floor( p11_nodeVar864 );
			p11_nodeVar866 = ( p11_nodeVar864 - p11_nodeVar865 );
			p11_nodeVar867 = ( p11_nodeVar866 * p11_nodeVar866 );
			p11_nodeVar868 = ( p11_nodeVar867 * p11_nodeVar866 );
			p11_nodeVar869 = ( ( ( ( p11_nodeVar868 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar867 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar870 = ( ( ( p11_nodeVar865 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar869 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar866 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar866 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar866 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar869 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar871 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar870.x, p11_nodeVar870.y ), 0.0 );
			p11_nodeVar872 = ( p11_nodeVar868 / vec2<f32>( 6.0 ) );
			p11_nodeVar873 = ( ( ( ( ( ( p11_nodeVar868 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar867 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar866 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar872 );
			p11_nodeVar874 = ( ( ( p11_nodeVar865 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar872 / p11_nodeVar873 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar875 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar874.x, p11_nodeVar870.y ), 0.0 );
			p11_nodeVar876 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar870.x, p11_nodeVar874.y ), 0.0 );
			p11_nodeVar877 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar874.x, p11_nodeVar874.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar871, p11_nodeVar875, p11_nodeVar873.x ), mix( p11_nodeVar876, p11_nodeVar877, p11_nodeVar873.x ), p11_nodeVar873.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar878 = ( ( p11_nodeVar863 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar879 = floor( p11_nodeVar878 );
				p11_nodeVar880 = ( p11_nodeVar878 - p11_nodeVar879 );
				p11_nodeVar881 = ( p11_nodeVar880 * p11_nodeVar880 );
				p11_nodeVar882 = ( p11_nodeVar881 * p11_nodeVar880 );
				p11_nodeVar883 = ( ( ( ( p11_nodeVar882 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar881 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar884 = ( ( ( p11_nodeVar879 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar883 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar880 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar880 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar880 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar883 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar885 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar884.x, p11_nodeVar884.y ), 0.0 );
				p11_nodeVar886 = ( p11_nodeVar882 / vec2<f32>( 6.0 ) );
				p11_nodeVar887 = ( ( ( ( ( ( p11_nodeVar882 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar881 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar880 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar886 );
				p11_nodeVar888 = ( ( ( p11_nodeVar879 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar886 / p11_nodeVar887 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar889 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar888.x, p11_nodeVar884.y ), 0.0 );
				p11_nodeVar890 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar884.x, p11_nodeVar888.y ), 0.0 );
				p11_nodeVar891 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar888.x, p11_nodeVar888.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar885, p11_nodeVar889, p11_nodeVar887.x ), mix( p11_nodeVar890, p11_nodeVar891, p11_nodeVar887.x ), p11_nodeVar887.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 7.0 ) ) {

			p11_nodeVar892 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar893 = ( ( p11_nodeVar892 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar894 = floor( p11_nodeVar893 );
			p11_nodeVar895 = ( p11_nodeVar893 - p11_nodeVar894 );
			p11_nodeVar896 = ( p11_nodeVar895 * p11_nodeVar895 );
			p11_nodeVar897 = ( p11_nodeVar896 * p11_nodeVar895 );
			p11_nodeVar898 = ( ( ( ( p11_nodeVar897 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar896 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar899 = ( ( ( p11_nodeVar894 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar898 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar895 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar895 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar895 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar898 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar900 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar899.x, p11_nodeVar899.y ), 0.0 );
			p11_nodeVar901 = ( p11_nodeVar897 / vec2<f32>( 6.0 ) );
			p11_nodeVar902 = ( ( ( ( ( ( p11_nodeVar897 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar896 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar895 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar901 );
			p11_nodeVar903 = ( ( ( p11_nodeVar894 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar901 / p11_nodeVar902 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar904 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar903.x, p11_nodeVar899.y ), 0.0 );
			p11_nodeVar905 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar899.x, p11_nodeVar903.y ), 0.0 );
			p11_nodeVar906 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar903.x, p11_nodeVar903.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar900, p11_nodeVar904, p11_nodeVar902.x ), mix( p11_nodeVar905, p11_nodeVar906, p11_nodeVar902.x ), p11_nodeVar902.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar907 = ( ( p11_nodeVar892 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar908 = floor( p11_nodeVar907 );
				p11_nodeVar909 = ( p11_nodeVar907 - p11_nodeVar908 );
				p11_nodeVar910 = ( p11_nodeVar909 * p11_nodeVar909 );
				p11_nodeVar911 = ( p11_nodeVar910 * p11_nodeVar909 );
				p11_nodeVar912 = ( ( ( ( p11_nodeVar911 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar910 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar913 = ( ( ( p11_nodeVar908 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar912 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar909 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar909 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar909 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar912 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar914 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar913.x, p11_nodeVar913.y ), 0.0 );
				p11_nodeVar915 = ( p11_nodeVar911 / vec2<f32>( 6.0 ) );
				p11_nodeVar916 = ( ( ( ( ( ( p11_nodeVar911 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar910 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar909 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar915 );
				p11_nodeVar917 = ( ( ( p11_nodeVar908 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar915 / p11_nodeVar916 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar918 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar917.x, p11_nodeVar913.y ), 0.0 );
				p11_nodeVar919 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar913.x, p11_nodeVar917.y ), 0.0 );
				p11_nodeVar920 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar917.x, p11_nodeVar917.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar914, p11_nodeVar918, p11_nodeVar916.x ), mix( p11_nodeVar919, p11_nodeVar920, p11_nodeVar916.x ), p11_nodeVar916.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 8.0 ) ) {

			p11_nodeVar921 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar922 = ( ( p11_nodeVar921 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar923 = floor( p11_nodeVar922 );
			p11_nodeVar924 = ( p11_nodeVar922 - p11_nodeVar923 );
			p11_nodeVar925 = ( p11_nodeVar924 * p11_nodeVar924 );
			p11_nodeVar926 = ( p11_nodeVar925 * p11_nodeVar924 );
			p11_nodeVar927 = ( ( ( ( p11_nodeVar926 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar925 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar928 = ( ( ( p11_nodeVar923 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar927 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar924 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar924 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar924 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar927 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar929 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar928.x, p11_nodeVar928.y ), 0.0 );
			p11_nodeVar930 = ( p11_nodeVar926 / vec2<f32>( 6.0 ) );
			p11_nodeVar931 = ( ( ( ( ( ( p11_nodeVar926 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar925 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar924 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar930 );
			p11_nodeVar932 = ( ( ( p11_nodeVar923 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar930 / p11_nodeVar931 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar933 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar932.x, p11_nodeVar928.y ), 0.0 );
			p11_nodeVar934 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar928.x, p11_nodeVar932.y ), 0.0 );
			p11_nodeVar935 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar932.x, p11_nodeVar932.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar929, p11_nodeVar933, p11_nodeVar931.x ), mix( p11_nodeVar934, p11_nodeVar935, p11_nodeVar931.x ), p11_nodeVar931.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar936 = ( ( p11_nodeVar921 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar937 = floor( p11_nodeVar936 );
				p11_nodeVar938 = ( p11_nodeVar936 - p11_nodeVar937 );
				p11_nodeVar939 = ( p11_nodeVar938 * p11_nodeVar938 );
				p11_nodeVar940 = ( p11_nodeVar939 * p11_nodeVar938 );
				p11_nodeVar941 = ( ( ( ( p11_nodeVar940 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar939 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar942 = ( ( ( p11_nodeVar937 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar941 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar938 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar938 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar938 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar941 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar943 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar942.x, p11_nodeVar942.y ), 0.0 );
				p11_nodeVar944 = ( p11_nodeVar940 / vec2<f32>( 6.0 ) );
				p11_nodeVar945 = ( ( ( ( ( ( p11_nodeVar940 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar939 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar938 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar944 );
				p11_nodeVar946 = ( ( ( p11_nodeVar937 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar944 / p11_nodeVar945 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar947 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar946.x, p11_nodeVar942.y ), 0.0 );
				p11_nodeVar948 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar942.x, p11_nodeVar946.y ), 0.0 );
				p11_nodeVar949 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar946.x, p11_nodeVar946.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar943, p11_nodeVar947, p11_nodeVar945.x ), mix( p11_nodeVar948, p11_nodeVar949, p11_nodeVar945.x ), p11_nodeVar945.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 == 9.0 ) ) {

			p11_nodeVar950 = ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar951 = ( ( p11_nodeVar950 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar952 = floor( p11_nodeVar951 );
			p11_nodeVar953 = ( p11_nodeVar951 - p11_nodeVar952 );
			p11_nodeVar954 = ( p11_nodeVar953 * p11_nodeVar953 );
			p11_nodeVar955 = ( p11_nodeVar954 * p11_nodeVar953 );
			p11_nodeVar956 = ( ( ( ( p11_nodeVar955 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar954 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar957 = ( ( ( p11_nodeVar952 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar956 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar953 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar953 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar953 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar956 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar958 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar957.x, p11_nodeVar957.y ), 0.0 );
			p11_nodeVar959 = ( p11_nodeVar955 / vec2<f32>( 6.0 ) );
			p11_nodeVar960 = ( ( ( ( ( ( p11_nodeVar955 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar954 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar953 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar959 );
			p11_nodeVar961 = ( ( ( p11_nodeVar952 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar959 / p11_nodeVar960 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar962 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar961.x, p11_nodeVar957.y ), 0.0 );
			p11_nodeVar963 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar957.x, p11_nodeVar961.y ), 0.0 );
			p11_nodeVar964 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar961.x, p11_nodeVar961.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar958, p11_nodeVar962, p11_nodeVar960.x ), mix( p11_nodeVar963, p11_nodeVar964, p11_nodeVar960.x ), p11_nodeVar960.y );

			if ( ( p11_nodeVar701 > 0.0 ) ) {

				p11_nodeVar965 = ( ( p11_nodeVar950 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar966 = floor( p11_nodeVar965 );
				p11_nodeVar967 = ( p11_nodeVar965 - p11_nodeVar966 );
				p11_nodeVar968 = ( p11_nodeVar967 * p11_nodeVar967 );
				p11_nodeVar969 = ( p11_nodeVar968 * p11_nodeVar967 );
				p11_nodeVar970 = ( ( ( ( p11_nodeVar969 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar968 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar971 = ( ( ( p11_nodeVar966 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar970 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar967 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar967 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar967 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar970 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar972 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar971.x, p11_nodeVar971.y ), 0.0 );
				p11_nodeVar973 = ( p11_nodeVar969 / vec2<f32>( 6.0 ) );
				p11_nodeVar974 = ( ( ( ( ( ( p11_nodeVar969 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar968 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar967 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar973 );
				p11_nodeVar975 = ( ( ( p11_nodeVar966 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar973 / p11_nodeVar974 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar976 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar975.x, p11_nodeVar971.y ), 0.0 );
				p11_nodeVar977 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar971.x, p11_nodeVar975.y ), 0.0 );
				p11_nodeVar978 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar975.x, p11_nodeVar975.y ), 0.0 );
				p11_nodeVar698 = mix( p11_nodeVar698, mix( mix( p11_nodeVar972, p11_nodeVar976, p11_nodeVar974.x ), mix( p11_nodeVar977, p11_nodeVar978, p11_nodeVar974.x ), p11_nodeVar974.y ), p11_nodeVar701 );
				

			}

			

		}


		if ( ( p11_nodeVar700 >= 10.0 ) ) {

			p11_nodeVar979 = ( ( ( ( p11_nodeVar35 + vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar980 = floor( p11_nodeVar979 );
			p11_nodeVar981 = ( p11_nodeVar979 - p11_nodeVar980 );
			p11_nodeVar982 = ( p11_nodeVar981 * p11_nodeVar981 );
			p11_nodeVar983 = ( p11_nodeVar982 * p11_nodeVar981 );
			p11_nodeVar984 = ( ( ( ( p11_nodeVar983 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar982 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar985 = ( ( ( p11_nodeVar980 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar984 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar981 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar981 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar981 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar984 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar986 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar985.x, p11_nodeVar985.y ), 0.0 );
			p11_nodeVar987 = ( p11_nodeVar983 / vec2<f32>( 6.0 ) );
			p11_nodeVar988 = ( ( ( ( ( ( p11_nodeVar983 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar982 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar981 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar987 );
			p11_nodeVar989 = ( ( ( p11_nodeVar980 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar987 / p11_nodeVar988 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar990 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar989.x, p11_nodeVar985.y ), 0.0 );
			p11_nodeVar991 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar985.x, p11_nodeVar989.y ), 0.0 );
			p11_nodeVar992 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar989.x, p11_nodeVar989.y ), 0.0 );
			p11_nodeVar698 = mix( mix( p11_nodeVar986, p11_nodeVar990, p11_nodeVar988.x ), mix( p11_nodeVar991, p11_nodeVar992, p11_nodeVar988.x ), p11_nodeVar988.y );
			

		}

		p11_nodeVar993 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p11_nodeVar994 = clamp( p11_nodeVar37, 0.0, 10.0 );
		p11_nodeVar995 = floor( p11_nodeVar994 );
		p11_nodeVar996 = ( p11_nodeVar994 - p11_nodeVar995 );

		if ( ( p11_nodeVar995 == 0.0 ) ) {

			p11_nodeVar997 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar998 = picture_read_level( p11_nodeVar997, 0.0 );
			p11_nodeVar993 = vec4<f32>( ( vec3<f32>( p11_nodeVar998.x, p11_nodeVar998.y, p11_nodeVar998.z ) * vec3<f32>( p11_nodeVar998.w ) ), p11_nodeVar998.w );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar999 = ( ( p11_nodeVar997 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1000 = floor( p11_nodeVar999 );
				p11_nodeVar1001 = ( p11_nodeVar999 - p11_nodeVar1000 );
				p11_nodeVar1002 = ( p11_nodeVar1001 * p11_nodeVar1001 );
				p11_nodeVar1003 = ( p11_nodeVar1002 * p11_nodeVar1001 );
				p11_nodeVar1004 = ( ( ( ( p11_nodeVar1003 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1002 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1005 = ( ( ( p11_nodeVar1000 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1004 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1001 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1001 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1001 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1004 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1006 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1005.x, p11_nodeVar1005.y ), 0.0 );
				p11_nodeVar1007 = ( p11_nodeVar1003 / vec2<f32>( 6.0 ) );
				p11_nodeVar1008 = ( ( ( ( ( ( p11_nodeVar1003 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1002 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1001 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1007 );
				p11_nodeVar1009 = ( ( ( p11_nodeVar1000 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1007 / p11_nodeVar1008 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1010 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1009.x, p11_nodeVar1005.y ), 0.0 );
				p11_nodeVar1011 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1005.x, p11_nodeVar1009.y ), 0.0 );
				p11_nodeVar1012 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1009.x, p11_nodeVar1009.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1006, p11_nodeVar1010, p11_nodeVar1008.x ), mix( p11_nodeVar1011, p11_nodeVar1012, p11_nodeVar1008.x ), p11_nodeVar1008.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 1.0 ) ) {

			p11_nodeVar1013 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1014 = ( ( p11_nodeVar1013 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1015 = floor( p11_nodeVar1014 );
			p11_nodeVar1016 = ( p11_nodeVar1014 - p11_nodeVar1015 );
			p11_nodeVar1017 = ( p11_nodeVar1016 * p11_nodeVar1016 );
			p11_nodeVar1018 = ( p11_nodeVar1017 * p11_nodeVar1016 );
			p11_nodeVar1019 = ( ( ( ( p11_nodeVar1018 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1017 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1020 = ( ( ( p11_nodeVar1015 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1019 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1016 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1016 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1016 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1019 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1021 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1020.x, p11_nodeVar1020.y ), 0.0 );
			p11_nodeVar1022 = ( p11_nodeVar1018 / vec2<f32>( 6.0 ) );
			p11_nodeVar1023 = ( ( ( ( ( ( p11_nodeVar1018 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1017 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1016 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1022 );
			p11_nodeVar1024 = ( ( ( p11_nodeVar1015 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1022 / p11_nodeVar1023 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1025 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1024.x, p11_nodeVar1020.y ), 0.0 );
			p11_nodeVar1026 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1020.x, p11_nodeVar1024.y ), 0.0 );
			p11_nodeVar1027 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1024.x, p11_nodeVar1024.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1021, p11_nodeVar1025, p11_nodeVar1023.x ), mix( p11_nodeVar1026, p11_nodeVar1027, p11_nodeVar1023.x ), p11_nodeVar1023.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1028 = ( ( p11_nodeVar1013 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1029 = floor( p11_nodeVar1028 );
				p11_nodeVar1030 = ( p11_nodeVar1028 - p11_nodeVar1029 );
				p11_nodeVar1031 = ( p11_nodeVar1030 * p11_nodeVar1030 );
				p11_nodeVar1032 = ( p11_nodeVar1031 * p11_nodeVar1030 );
				p11_nodeVar1033 = ( ( ( ( p11_nodeVar1032 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1031 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1034 = ( ( ( p11_nodeVar1029 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1033 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1030 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1030 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1030 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1033 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1035 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1034.x, p11_nodeVar1034.y ), 0.0 );
				p11_nodeVar1036 = ( p11_nodeVar1032 / vec2<f32>( 6.0 ) );
				p11_nodeVar1037 = ( ( ( ( ( ( p11_nodeVar1032 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1031 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1030 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1036 );
				p11_nodeVar1038 = ( ( ( p11_nodeVar1029 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1036 / p11_nodeVar1037 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1039 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1038.x, p11_nodeVar1034.y ), 0.0 );
				p11_nodeVar1040 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1034.x, p11_nodeVar1038.y ), 0.0 );
				p11_nodeVar1041 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1038.x, p11_nodeVar1038.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1035, p11_nodeVar1039, p11_nodeVar1037.x ), mix( p11_nodeVar1040, p11_nodeVar1041, p11_nodeVar1037.x ), p11_nodeVar1037.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 2.0 ) ) {

			p11_nodeVar1042 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1043 = ( ( p11_nodeVar1042 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1044 = floor( p11_nodeVar1043 );
			p11_nodeVar1045 = ( p11_nodeVar1043 - p11_nodeVar1044 );
			p11_nodeVar1046 = ( p11_nodeVar1045 * p11_nodeVar1045 );
			p11_nodeVar1047 = ( p11_nodeVar1046 * p11_nodeVar1045 );
			p11_nodeVar1048 = ( ( ( ( p11_nodeVar1047 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1046 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1049 = ( ( ( p11_nodeVar1044 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1048 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1045 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1045 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1045 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1048 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1050 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1049.x, p11_nodeVar1049.y ), 0.0 );
			p11_nodeVar1051 = ( p11_nodeVar1047 / vec2<f32>( 6.0 ) );
			p11_nodeVar1052 = ( ( ( ( ( ( p11_nodeVar1047 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1046 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1045 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1051 );
			p11_nodeVar1053 = ( ( ( p11_nodeVar1044 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1051 / p11_nodeVar1052 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1054 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1053.x, p11_nodeVar1049.y ), 0.0 );
			p11_nodeVar1055 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1049.x, p11_nodeVar1053.y ), 0.0 );
			p11_nodeVar1056 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1053.x, p11_nodeVar1053.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1050, p11_nodeVar1054, p11_nodeVar1052.x ), mix( p11_nodeVar1055, p11_nodeVar1056, p11_nodeVar1052.x ), p11_nodeVar1052.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1057 = ( ( p11_nodeVar1042 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1058 = floor( p11_nodeVar1057 );
				p11_nodeVar1059 = ( p11_nodeVar1057 - p11_nodeVar1058 );
				p11_nodeVar1060 = ( p11_nodeVar1059 * p11_nodeVar1059 );
				p11_nodeVar1061 = ( p11_nodeVar1060 * p11_nodeVar1059 );
				p11_nodeVar1062 = ( ( ( ( p11_nodeVar1061 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1060 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1063 = ( ( ( p11_nodeVar1058 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1062 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1059 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1059 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1059 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1062 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1064 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1063.x, p11_nodeVar1063.y ), 0.0 );
				p11_nodeVar1065 = ( p11_nodeVar1061 / vec2<f32>( 6.0 ) );
				p11_nodeVar1066 = ( ( ( ( ( ( p11_nodeVar1061 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1060 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1059 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1065 );
				p11_nodeVar1067 = ( ( ( p11_nodeVar1058 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1065 / p11_nodeVar1066 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1068 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1067.x, p11_nodeVar1063.y ), 0.0 );
				p11_nodeVar1069 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1063.x, p11_nodeVar1067.y ), 0.0 );
				p11_nodeVar1070 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1067.x, p11_nodeVar1067.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1064, p11_nodeVar1068, p11_nodeVar1066.x ), mix( p11_nodeVar1069, p11_nodeVar1070, p11_nodeVar1066.x ), p11_nodeVar1066.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 3.0 ) ) {

			p11_nodeVar1071 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1072 = ( ( p11_nodeVar1071 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1073 = floor( p11_nodeVar1072 );
			p11_nodeVar1074 = ( p11_nodeVar1072 - p11_nodeVar1073 );
			p11_nodeVar1075 = ( p11_nodeVar1074 * p11_nodeVar1074 );
			p11_nodeVar1076 = ( p11_nodeVar1075 * p11_nodeVar1074 );
			p11_nodeVar1077 = ( ( ( ( p11_nodeVar1076 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1075 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1078 = ( ( ( p11_nodeVar1073 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1077 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1074 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1074 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1074 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1077 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1079 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1078.x, p11_nodeVar1078.y ), 0.0 );
			p11_nodeVar1080 = ( p11_nodeVar1076 / vec2<f32>( 6.0 ) );
			p11_nodeVar1081 = ( ( ( ( ( ( p11_nodeVar1076 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1075 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1074 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1080 );
			p11_nodeVar1082 = ( ( ( p11_nodeVar1073 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1080 / p11_nodeVar1081 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1083 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1082.x, p11_nodeVar1078.y ), 0.0 );
			p11_nodeVar1084 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1078.x, p11_nodeVar1082.y ), 0.0 );
			p11_nodeVar1085 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1082.x, p11_nodeVar1082.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1079, p11_nodeVar1083, p11_nodeVar1081.x ), mix( p11_nodeVar1084, p11_nodeVar1085, p11_nodeVar1081.x ), p11_nodeVar1081.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1086 = ( ( p11_nodeVar1071 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1087 = floor( p11_nodeVar1086 );
				p11_nodeVar1088 = ( p11_nodeVar1086 - p11_nodeVar1087 );
				p11_nodeVar1089 = ( p11_nodeVar1088 * p11_nodeVar1088 );
				p11_nodeVar1090 = ( p11_nodeVar1089 * p11_nodeVar1088 );
				p11_nodeVar1091 = ( ( ( ( p11_nodeVar1090 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1089 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1092 = ( ( ( p11_nodeVar1087 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1091 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1088 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1088 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1088 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1091 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1093 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1092.x, p11_nodeVar1092.y ), 0.0 );
				p11_nodeVar1094 = ( p11_nodeVar1090 / vec2<f32>( 6.0 ) );
				p11_nodeVar1095 = ( ( ( ( ( ( p11_nodeVar1090 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1089 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1088 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1094 );
				p11_nodeVar1096 = ( ( ( p11_nodeVar1087 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1094 / p11_nodeVar1095 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1097 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1096.x, p11_nodeVar1092.y ), 0.0 );
				p11_nodeVar1098 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1092.x, p11_nodeVar1096.y ), 0.0 );
				p11_nodeVar1099 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1096.x, p11_nodeVar1096.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1093, p11_nodeVar1097, p11_nodeVar1095.x ), mix( p11_nodeVar1098, p11_nodeVar1099, p11_nodeVar1095.x ), p11_nodeVar1095.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 4.0 ) ) {

			p11_nodeVar1100 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1101 = ( ( p11_nodeVar1100 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1102 = floor( p11_nodeVar1101 );
			p11_nodeVar1103 = ( p11_nodeVar1101 - p11_nodeVar1102 );
			p11_nodeVar1104 = ( p11_nodeVar1103 * p11_nodeVar1103 );
			p11_nodeVar1105 = ( p11_nodeVar1104 * p11_nodeVar1103 );
			p11_nodeVar1106 = ( ( ( ( p11_nodeVar1105 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1104 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1107 = ( ( ( p11_nodeVar1102 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1106 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1103 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1103 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1103 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1106 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1108 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1107.x, p11_nodeVar1107.y ), 0.0 );
			p11_nodeVar1109 = ( p11_nodeVar1105 / vec2<f32>( 6.0 ) );
			p11_nodeVar1110 = ( ( ( ( ( ( p11_nodeVar1105 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1104 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1103 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1109 );
			p11_nodeVar1111 = ( ( ( p11_nodeVar1102 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1109 / p11_nodeVar1110 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1112 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1111.x, p11_nodeVar1107.y ), 0.0 );
			p11_nodeVar1113 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1107.x, p11_nodeVar1111.y ), 0.0 );
			p11_nodeVar1114 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1111.x, p11_nodeVar1111.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1108, p11_nodeVar1112, p11_nodeVar1110.x ), mix( p11_nodeVar1113, p11_nodeVar1114, p11_nodeVar1110.x ), p11_nodeVar1110.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1115 = ( ( p11_nodeVar1100 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1116 = floor( p11_nodeVar1115 );
				p11_nodeVar1117 = ( p11_nodeVar1115 - p11_nodeVar1116 );
				p11_nodeVar1118 = ( p11_nodeVar1117 * p11_nodeVar1117 );
				p11_nodeVar1119 = ( p11_nodeVar1118 * p11_nodeVar1117 );
				p11_nodeVar1120 = ( ( ( ( p11_nodeVar1119 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1118 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1121 = ( ( ( p11_nodeVar1116 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1120 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1117 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1117 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1117 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1120 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1122 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1121.x, p11_nodeVar1121.y ), 0.0 );
				p11_nodeVar1123 = ( p11_nodeVar1119 / vec2<f32>( 6.0 ) );
				p11_nodeVar1124 = ( ( ( ( ( ( p11_nodeVar1119 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1118 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1117 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1123 );
				p11_nodeVar1125 = ( ( ( p11_nodeVar1116 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1123 / p11_nodeVar1124 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1126 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1125.x, p11_nodeVar1121.y ), 0.0 );
				p11_nodeVar1127 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1121.x, p11_nodeVar1125.y ), 0.0 );
				p11_nodeVar1128 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1125.x, p11_nodeVar1125.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1122, p11_nodeVar1126, p11_nodeVar1124.x ), mix( p11_nodeVar1127, p11_nodeVar1128, p11_nodeVar1124.x ), p11_nodeVar1124.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 5.0 ) ) {

			p11_nodeVar1129 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1130 = ( ( p11_nodeVar1129 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1131 = floor( p11_nodeVar1130 );
			p11_nodeVar1132 = ( p11_nodeVar1130 - p11_nodeVar1131 );
			p11_nodeVar1133 = ( p11_nodeVar1132 * p11_nodeVar1132 );
			p11_nodeVar1134 = ( p11_nodeVar1133 * p11_nodeVar1132 );
			p11_nodeVar1135 = ( ( ( ( p11_nodeVar1134 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1133 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1136 = ( ( ( p11_nodeVar1131 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1135 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1132 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1132 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1132 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1135 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1137 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1136.x, p11_nodeVar1136.y ), 0.0 );
			p11_nodeVar1138 = ( p11_nodeVar1134 / vec2<f32>( 6.0 ) );
			p11_nodeVar1139 = ( ( ( ( ( ( p11_nodeVar1134 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1133 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1132 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1138 );
			p11_nodeVar1140 = ( ( ( p11_nodeVar1131 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1138 / p11_nodeVar1139 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1141 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1140.x, p11_nodeVar1136.y ), 0.0 );
			p11_nodeVar1142 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1136.x, p11_nodeVar1140.y ), 0.0 );
			p11_nodeVar1143 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1140.x, p11_nodeVar1140.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1137, p11_nodeVar1141, p11_nodeVar1139.x ), mix( p11_nodeVar1142, p11_nodeVar1143, p11_nodeVar1139.x ), p11_nodeVar1139.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1144 = ( ( p11_nodeVar1129 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1145 = floor( p11_nodeVar1144 );
				p11_nodeVar1146 = ( p11_nodeVar1144 - p11_nodeVar1145 );
				p11_nodeVar1147 = ( p11_nodeVar1146 * p11_nodeVar1146 );
				p11_nodeVar1148 = ( p11_nodeVar1147 * p11_nodeVar1146 );
				p11_nodeVar1149 = ( ( ( ( p11_nodeVar1148 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1147 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1150 = ( ( ( p11_nodeVar1145 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1149 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1146 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1146 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1146 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1149 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1151 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1150.x, p11_nodeVar1150.y ), 0.0 );
				p11_nodeVar1152 = ( p11_nodeVar1148 / vec2<f32>( 6.0 ) );
				p11_nodeVar1153 = ( ( ( ( ( ( p11_nodeVar1148 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1147 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1146 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1152 );
				p11_nodeVar1154 = ( ( ( p11_nodeVar1145 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1152 / p11_nodeVar1153 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1155 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1154.x, p11_nodeVar1150.y ), 0.0 );
				p11_nodeVar1156 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1150.x, p11_nodeVar1154.y ), 0.0 );
				p11_nodeVar1157 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1154.x, p11_nodeVar1154.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1151, p11_nodeVar1155, p11_nodeVar1153.x ), mix( p11_nodeVar1156, p11_nodeVar1157, p11_nodeVar1153.x ), p11_nodeVar1153.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 6.0 ) ) {

			p11_nodeVar1158 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1159 = ( ( p11_nodeVar1158 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1160 = floor( p11_nodeVar1159 );
			p11_nodeVar1161 = ( p11_nodeVar1159 - p11_nodeVar1160 );
			p11_nodeVar1162 = ( p11_nodeVar1161 * p11_nodeVar1161 );
			p11_nodeVar1163 = ( p11_nodeVar1162 * p11_nodeVar1161 );
			p11_nodeVar1164 = ( ( ( ( p11_nodeVar1163 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1162 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1165 = ( ( ( p11_nodeVar1160 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1164 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1161 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1161 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1161 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1164 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1166 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1165.x, p11_nodeVar1165.y ), 0.0 );
			p11_nodeVar1167 = ( p11_nodeVar1163 / vec2<f32>( 6.0 ) );
			p11_nodeVar1168 = ( ( ( ( ( ( p11_nodeVar1163 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1162 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1161 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1167 );
			p11_nodeVar1169 = ( ( ( p11_nodeVar1160 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1167 / p11_nodeVar1168 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1170 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1169.x, p11_nodeVar1165.y ), 0.0 );
			p11_nodeVar1171 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1165.x, p11_nodeVar1169.y ), 0.0 );
			p11_nodeVar1172 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1169.x, p11_nodeVar1169.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1166, p11_nodeVar1170, p11_nodeVar1168.x ), mix( p11_nodeVar1171, p11_nodeVar1172, p11_nodeVar1168.x ), p11_nodeVar1168.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1173 = ( ( p11_nodeVar1158 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1174 = floor( p11_nodeVar1173 );
				p11_nodeVar1175 = ( p11_nodeVar1173 - p11_nodeVar1174 );
				p11_nodeVar1176 = ( p11_nodeVar1175 * p11_nodeVar1175 );
				p11_nodeVar1177 = ( p11_nodeVar1176 * p11_nodeVar1175 );
				p11_nodeVar1178 = ( ( ( ( p11_nodeVar1177 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1176 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1179 = ( ( ( p11_nodeVar1174 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1178 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1175 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1175 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1175 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1178 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1180 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1179.x, p11_nodeVar1179.y ), 0.0 );
				p11_nodeVar1181 = ( p11_nodeVar1177 / vec2<f32>( 6.0 ) );
				p11_nodeVar1182 = ( ( ( ( ( ( p11_nodeVar1177 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1176 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1175 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1181 );
				p11_nodeVar1183 = ( ( ( p11_nodeVar1174 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1181 / p11_nodeVar1182 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1184 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1183.x, p11_nodeVar1179.y ), 0.0 );
				p11_nodeVar1185 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1179.x, p11_nodeVar1183.y ), 0.0 );
				p11_nodeVar1186 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1183.x, p11_nodeVar1183.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1180, p11_nodeVar1184, p11_nodeVar1182.x ), mix( p11_nodeVar1185, p11_nodeVar1186, p11_nodeVar1182.x ), p11_nodeVar1182.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 7.0 ) ) {

			p11_nodeVar1187 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1188 = ( ( p11_nodeVar1187 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1189 = floor( p11_nodeVar1188 );
			p11_nodeVar1190 = ( p11_nodeVar1188 - p11_nodeVar1189 );
			p11_nodeVar1191 = ( p11_nodeVar1190 * p11_nodeVar1190 );
			p11_nodeVar1192 = ( p11_nodeVar1191 * p11_nodeVar1190 );
			p11_nodeVar1193 = ( ( ( ( p11_nodeVar1192 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1191 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1194 = ( ( ( p11_nodeVar1189 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1193 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1190 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1190 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1190 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1193 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1195 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1194.x, p11_nodeVar1194.y ), 0.0 );
			p11_nodeVar1196 = ( p11_nodeVar1192 / vec2<f32>( 6.0 ) );
			p11_nodeVar1197 = ( ( ( ( ( ( p11_nodeVar1192 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1191 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1190 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1196 );
			p11_nodeVar1198 = ( ( ( p11_nodeVar1189 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1196 / p11_nodeVar1197 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1199 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1198.x, p11_nodeVar1194.y ), 0.0 );
			p11_nodeVar1200 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1194.x, p11_nodeVar1198.y ), 0.0 );
			p11_nodeVar1201 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1198.x, p11_nodeVar1198.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1195, p11_nodeVar1199, p11_nodeVar1197.x ), mix( p11_nodeVar1200, p11_nodeVar1201, p11_nodeVar1197.x ), p11_nodeVar1197.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1202 = ( ( p11_nodeVar1187 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1203 = floor( p11_nodeVar1202 );
				p11_nodeVar1204 = ( p11_nodeVar1202 - p11_nodeVar1203 );
				p11_nodeVar1205 = ( p11_nodeVar1204 * p11_nodeVar1204 );
				p11_nodeVar1206 = ( p11_nodeVar1205 * p11_nodeVar1204 );
				p11_nodeVar1207 = ( ( ( ( p11_nodeVar1206 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1205 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1208 = ( ( ( p11_nodeVar1203 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1207 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1204 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1204 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1204 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1207 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1209 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1208.x, p11_nodeVar1208.y ), 0.0 );
				p11_nodeVar1210 = ( p11_nodeVar1206 / vec2<f32>( 6.0 ) );
				p11_nodeVar1211 = ( ( ( ( ( ( p11_nodeVar1206 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1205 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1204 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1210 );
				p11_nodeVar1212 = ( ( ( p11_nodeVar1203 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1210 / p11_nodeVar1211 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1213 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1212.x, p11_nodeVar1208.y ), 0.0 );
				p11_nodeVar1214 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1208.x, p11_nodeVar1212.y ), 0.0 );
				p11_nodeVar1215 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1212.x, p11_nodeVar1212.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1209, p11_nodeVar1213, p11_nodeVar1211.x ), mix( p11_nodeVar1214, p11_nodeVar1215, p11_nodeVar1211.x ), p11_nodeVar1211.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 8.0 ) ) {

			p11_nodeVar1216 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1217 = ( ( p11_nodeVar1216 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1218 = floor( p11_nodeVar1217 );
			p11_nodeVar1219 = ( p11_nodeVar1217 - p11_nodeVar1218 );
			p11_nodeVar1220 = ( p11_nodeVar1219 * p11_nodeVar1219 );
			p11_nodeVar1221 = ( p11_nodeVar1220 * p11_nodeVar1219 );
			p11_nodeVar1222 = ( ( ( ( p11_nodeVar1221 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1220 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1223 = ( ( ( p11_nodeVar1218 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1222 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1219 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1219 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1219 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1222 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1224 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1223.x, p11_nodeVar1223.y ), 0.0 );
			p11_nodeVar1225 = ( p11_nodeVar1221 / vec2<f32>( 6.0 ) );
			p11_nodeVar1226 = ( ( ( ( ( ( p11_nodeVar1221 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1220 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1219 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1225 );
			p11_nodeVar1227 = ( ( ( p11_nodeVar1218 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1225 / p11_nodeVar1226 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1228 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1227.x, p11_nodeVar1223.y ), 0.0 );
			p11_nodeVar1229 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1223.x, p11_nodeVar1227.y ), 0.0 );
			p11_nodeVar1230 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1227.x, p11_nodeVar1227.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1224, p11_nodeVar1228, p11_nodeVar1226.x ), mix( p11_nodeVar1229, p11_nodeVar1230, p11_nodeVar1226.x ), p11_nodeVar1226.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1231 = ( ( p11_nodeVar1216 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1232 = floor( p11_nodeVar1231 );
				p11_nodeVar1233 = ( p11_nodeVar1231 - p11_nodeVar1232 );
				p11_nodeVar1234 = ( p11_nodeVar1233 * p11_nodeVar1233 );
				p11_nodeVar1235 = ( p11_nodeVar1234 * p11_nodeVar1233 );
				p11_nodeVar1236 = ( ( ( ( p11_nodeVar1235 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1234 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1237 = ( ( ( p11_nodeVar1232 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1236 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1233 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1233 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1233 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1236 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1238 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1237.x, p11_nodeVar1237.y ), 0.0 );
				p11_nodeVar1239 = ( p11_nodeVar1235 / vec2<f32>( 6.0 ) );
				p11_nodeVar1240 = ( ( ( ( ( ( p11_nodeVar1235 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1234 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1233 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1239 );
				p11_nodeVar1241 = ( ( ( p11_nodeVar1232 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1239 / p11_nodeVar1240 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1242 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1241.x, p11_nodeVar1237.y ), 0.0 );
				p11_nodeVar1243 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1237.x, p11_nodeVar1241.y ), 0.0 );
				p11_nodeVar1244 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1241.x, p11_nodeVar1241.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1238, p11_nodeVar1242, p11_nodeVar1240.x ), mix( p11_nodeVar1243, p11_nodeVar1244, p11_nodeVar1240.x ), p11_nodeVar1240.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 == 9.0 ) ) {

			p11_nodeVar1245 = ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1246 = ( ( p11_nodeVar1245 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1247 = floor( p11_nodeVar1246 );
			p11_nodeVar1248 = ( p11_nodeVar1246 - p11_nodeVar1247 );
			p11_nodeVar1249 = ( p11_nodeVar1248 * p11_nodeVar1248 );
			p11_nodeVar1250 = ( p11_nodeVar1249 * p11_nodeVar1248 );
			p11_nodeVar1251 = ( ( ( ( p11_nodeVar1250 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1249 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1252 = ( ( ( p11_nodeVar1247 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1251 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1248 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1248 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1248 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1251 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1253 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1252.x, p11_nodeVar1252.y ), 0.0 );
			p11_nodeVar1254 = ( p11_nodeVar1250 / vec2<f32>( 6.0 ) );
			p11_nodeVar1255 = ( ( ( ( ( ( p11_nodeVar1250 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1249 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1248 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1254 );
			p11_nodeVar1256 = ( ( ( p11_nodeVar1247 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1254 / p11_nodeVar1255 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1257 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1256.x, p11_nodeVar1252.y ), 0.0 );
			p11_nodeVar1258 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1252.x, p11_nodeVar1256.y ), 0.0 );
			p11_nodeVar1259 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1256.x, p11_nodeVar1256.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1253, p11_nodeVar1257, p11_nodeVar1255.x ), mix( p11_nodeVar1258, p11_nodeVar1259, p11_nodeVar1255.x ), p11_nodeVar1255.y );

			if ( ( p11_nodeVar996 > 0.0 ) ) {

				p11_nodeVar1260 = ( ( p11_nodeVar1245 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1261 = floor( p11_nodeVar1260 );
				p11_nodeVar1262 = ( p11_nodeVar1260 - p11_nodeVar1261 );
				p11_nodeVar1263 = ( p11_nodeVar1262 * p11_nodeVar1262 );
				p11_nodeVar1264 = ( p11_nodeVar1263 * p11_nodeVar1262 );
				p11_nodeVar1265 = ( ( ( ( p11_nodeVar1264 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1263 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1266 = ( ( ( p11_nodeVar1261 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1265 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1262 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1262 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1262 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1265 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1267 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1266.x, p11_nodeVar1266.y ), 0.0 );
				p11_nodeVar1268 = ( p11_nodeVar1264 / vec2<f32>( 6.0 ) );
				p11_nodeVar1269 = ( ( ( ( ( ( p11_nodeVar1264 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1263 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1262 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1268 );
				p11_nodeVar1270 = ( ( ( p11_nodeVar1261 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1268 / p11_nodeVar1269 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1271 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1270.x, p11_nodeVar1266.y ), 0.0 );
				p11_nodeVar1272 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1266.x, p11_nodeVar1270.y ), 0.0 );
				p11_nodeVar1273 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1270.x, p11_nodeVar1270.y ), 0.0 );
				p11_nodeVar993 = mix( p11_nodeVar993, mix( mix( p11_nodeVar1267, p11_nodeVar1271, p11_nodeVar1269.x ), mix( p11_nodeVar1272, p11_nodeVar1273, p11_nodeVar1269.x ), p11_nodeVar1269.y ), p11_nodeVar996 );
				

			}

			

		}


		if ( ( p11_nodeVar995 >= 10.0 ) ) {

			p11_nodeVar1274 = ( ( ( ( p11_nodeVar35 - vec2<f32>( max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ), 0.0 ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1275 = floor( p11_nodeVar1274 );
			p11_nodeVar1276 = ( p11_nodeVar1274 - p11_nodeVar1275 );
			p11_nodeVar1277 = ( p11_nodeVar1276 * p11_nodeVar1276 );
			p11_nodeVar1278 = ( p11_nodeVar1277 * p11_nodeVar1276 );
			p11_nodeVar1279 = ( ( ( ( p11_nodeVar1278 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1277 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1280 = ( ( ( p11_nodeVar1275 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1279 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1276 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1276 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1276 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1279 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1281 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1280.x, p11_nodeVar1280.y ), 0.0 );
			p11_nodeVar1282 = ( p11_nodeVar1278 / vec2<f32>( 6.0 ) );
			p11_nodeVar1283 = ( ( ( ( ( ( p11_nodeVar1278 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1277 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1276 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1282 );
			p11_nodeVar1284 = ( ( ( p11_nodeVar1275 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1282 / p11_nodeVar1283 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1285 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1284.x, p11_nodeVar1280.y ), 0.0 );
			p11_nodeVar1286 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1280.x, p11_nodeVar1284.y ), 0.0 );
			p11_nodeVar1287 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1284.x, p11_nodeVar1284.y ), 0.0 );
			p11_nodeVar993 = mix( mix( p11_nodeVar1281, p11_nodeVar1285, p11_nodeVar1283.x ), mix( p11_nodeVar1286, p11_nodeVar1287, p11_nodeVar1283.x ), p11_nodeVar1283.y );
			

		}

		p11_nodeVar1288 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p11_nodeVar1289 = clamp( p11_nodeVar37, 0.0, 10.0 );
		p11_nodeVar1290 = floor( p11_nodeVar1289 );
		p11_nodeVar1291 = ( p11_nodeVar1289 - p11_nodeVar1290 );

		if ( ( p11_nodeVar1290 == 0.0 ) ) {

			p11_nodeVar1292 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1293 = picture_read_level( p11_nodeVar1292, 0.0 );
			p11_nodeVar1288 = vec4<f32>( ( vec3<f32>( p11_nodeVar1293.x, p11_nodeVar1293.y, p11_nodeVar1293.z ) * vec3<f32>( p11_nodeVar1293.w ) ), p11_nodeVar1293.w );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1294 = ( ( p11_nodeVar1292 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1295 = floor( p11_nodeVar1294 );
				p11_nodeVar1296 = ( p11_nodeVar1294 - p11_nodeVar1295 );
				p11_nodeVar1297 = ( p11_nodeVar1296 * p11_nodeVar1296 );
				p11_nodeVar1298 = ( p11_nodeVar1297 * p11_nodeVar1296 );
				p11_nodeVar1299 = ( ( ( ( p11_nodeVar1298 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1297 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1300 = ( ( ( p11_nodeVar1295 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1299 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1296 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1296 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1296 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1299 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1301 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1300.x, p11_nodeVar1300.y ), 0.0 );
				p11_nodeVar1302 = ( p11_nodeVar1298 / vec2<f32>( 6.0 ) );
				p11_nodeVar1303 = ( ( ( ( ( ( p11_nodeVar1298 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1297 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1296 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1302 );
				p11_nodeVar1304 = ( ( ( p11_nodeVar1295 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1302 / p11_nodeVar1303 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1305 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1304.x, p11_nodeVar1300.y ), 0.0 );
				p11_nodeVar1306 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1300.x, p11_nodeVar1304.y ), 0.0 );
				p11_nodeVar1307 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1304.x, p11_nodeVar1304.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1301, p11_nodeVar1305, p11_nodeVar1303.x ), mix( p11_nodeVar1306, p11_nodeVar1307, p11_nodeVar1303.x ), p11_nodeVar1303.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 1.0 ) ) {

			p11_nodeVar1308 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1309 = ( ( p11_nodeVar1308 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1310 = floor( p11_nodeVar1309 );
			p11_nodeVar1311 = ( p11_nodeVar1309 - p11_nodeVar1310 );
			p11_nodeVar1312 = ( p11_nodeVar1311 * p11_nodeVar1311 );
			p11_nodeVar1313 = ( p11_nodeVar1312 * p11_nodeVar1311 );
			p11_nodeVar1314 = ( ( ( ( p11_nodeVar1313 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1312 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1315 = ( ( ( p11_nodeVar1310 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1314 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1311 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1311 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1311 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1314 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1316 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1315.x, p11_nodeVar1315.y ), 0.0 );
			p11_nodeVar1317 = ( p11_nodeVar1313 / vec2<f32>( 6.0 ) );
			p11_nodeVar1318 = ( ( ( ( ( ( p11_nodeVar1313 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1312 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1311 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1317 );
			p11_nodeVar1319 = ( ( ( p11_nodeVar1310 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1317 / p11_nodeVar1318 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1320 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1319.x, p11_nodeVar1315.y ), 0.0 );
			p11_nodeVar1321 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1315.x, p11_nodeVar1319.y ), 0.0 );
			p11_nodeVar1322 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1319.x, p11_nodeVar1319.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1316, p11_nodeVar1320, p11_nodeVar1318.x ), mix( p11_nodeVar1321, p11_nodeVar1322, p11_nodeVar1318.x ), p11_nodeVar1318.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1323 = ( ( p11_nodeVar1308 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1324 = floor( p11_nodeVar1323 );
				p11_nodeVar1325 = ( p11_nodeVar1323 - p11_nodeVar1324 );
				p11_nodeVar1326 = ( p11_nodeVar1325 * p11_nodeVar1325 );
				p11_nodeVar1327 = ( p11_nodeVar1326 * p11_nodeVar1325 );
				p11_nodeVar1328 = ( ( ( ( p11_nodeVar1327 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1326 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1329 = ( ( ( p11_nodeVar1324 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1328 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1325 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1325 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1325 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1328 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1330 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1329.x, p11_nodeVar1329.y ), 0.0 );
				p11_nodeVar1331 = ( p11_nodeVar1327 / vec2<f32>( 6.0 ) );
				p11_nodeVar1332 = ( ( ( ( ( ( p11_nodeVar1327 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1326 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1325 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1331 );
				p11_nodeVar1333 = ( ( ( p11_nodeVar1324 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1331 / p11_nodeVar1332 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1334 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1333.x, p11_nodeVar1329.y ), 0.0 );
				p11_nodeVar1335 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1329.x, p11_nodeVar1333.y ), 0.0 );
				p11_nodeVar1336 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1333.x, p11_nodeVar1333.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1330, p11_nodeVar1334, p11_nodeVar1332.x ), mix( p11_nodeVar1335, p11_nodeVar1336, p11_nodeVar1332.x ), p11_nodeVar1332.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 2.0 ) ) {

			p11_nodeVar1337 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1338 = ( ( p11_nodeVar1337 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1339 = floor( p11_nodeVar1338 );
			p11_nodeVar1340 = ( p11_nodeVar1338 - p11_nodeVar1339 );
			p11_nodeVar1341 = ( p11_nodeVar1340 * p11_nodeVar1340 );
			p11_nodeVar1342 = ( p11_nodeVar1341 * p11_nodeVar1340 );
			p11_nodeVar1343 = ( ( ( ( p11_nodeVar1342 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1341 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1344 = ( ( ( p11_nodeVar1339 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1343 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1340 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1340 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1340 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1343 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1345 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1344.x, p11_nodeVar1344.y ), 0.0 );
			p11_nodeVar1346 = ( p11_nodeVar1342 / vec2<f32>( 6.0 ) );
			p11_nodeVar1347 = ( ( ( ( ( ( p11_nodeVar1342 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1341 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1340 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1346 );
			p11_nodeVar1348 = ( ( ( p11_nodeVar1339 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1346 / p11_nodeVar1347 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1349 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1348.x, p11_nodeVar1344.y ), 0.0 );
			p11_nodeVar1350 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1344.x, p11_nodeVar1348.y ), 0.0 );
			p11_nodeVar1351 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1348.x, p11_nodeVar1348.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1345, p11_nodeVar1349, p11_nodeVar1347.x ), mix( p11_nodeVar1350, p11_nodeVar1351, p11_nodeVar1347.x ), p11_nodeVar1347.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1352 = ( ( p11_nodeVar1337 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1353 = floor( p11_nodeVar1352 );
				p11_nodeVar1354 = ( p11_nodeVar1352 - p11_nodeVar1353 );
				p11_nodeVar1355 = ( p11_nodeVar1354 * p11_nodeVar1354 );
				p11_nodeVar1356 = ( p11_nodeVar1355 * p11_nodeVar1354 );
				p11_nodeVar1357 = ( ( ( ( p11_nodeVar1356 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1355 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1358 = ( ( ( p11_nodeVar1353 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1357 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1354 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1354 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1354 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1357 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1359 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1358.x, p11_nodeVar1358.y ), 0.0 );
				p11_nodeVar1360 = ( p11_nodeVar1356 / vec2<f32>( 6.0 ) );
				p11_nodeVar1361 = ( ( ( ( ( ( p11_nodeVar1356 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1355 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1354 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1360 );
				p11_nodeVar1362 = ( ( ( p11_nodeVar1353 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1360 / p11_nodeVar1361 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1363 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1362.x, p11_nodeVar1358.y ), 0.0 );
				p11_nodeVar1364 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1358.x, p11_nodeVar1362.y ), 0.0 );
				p11_nodeVar1365 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1362.x, p11_nodeVar1362.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1359, p11_nodeVar1363, p11_nodeVar1361.x ), mix( p11_nodeVar1364, p11_nodeVar1365, p11_nodeVar1361.x ), p11_nodeVar1361.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 3.0 ) ) {

			p11_nodeVar1366 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1367 = ( ( p11_nodeVar1366 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1368 = floor( p11_nodeVar1367 );
			p11_nodeVar1369 = ( p11_nodeVar1367 - p11_nodeVar1368 );
			p11_nodeVar1370 = ( p11_nodeVar1369 * p11_nodeVar1369 );
			p11_nodeVar1371 = ( p11_nodeVar1370 * p11_nodeVar1369 );
			p11_nodeVar1372 = ( ( ( ( p11_nodeVar1371 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1370 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1373 = ( ( ( p11_nodeVar1368 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1372 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1369 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1369 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1369 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1372 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1374 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1373.x, p11_nodeVar1373.y ), 0.0 );
			p11_nodeVar1375 = ( p11_nodeVar1371 / vec2<f32>( 6.0 ) );
			p11_nodeVar1376 = ( ( ( ( ( ( p11_nodeVar1371 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1370 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1369 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1375 );
			p11_nodeVar1377 = ( ( ( p11_nodeVar1368 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1375 / p11_nodeVar1376 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1378 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1377.x, p11_nodeVar1373.y ), 0.0 );
			p11_nodeVar1379 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1373.x, p11_nodeVar1377.y ), 0.0 );
			p11_nodeVar1380 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1377.x, p11_nodeVar1377.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1374, p11_nodeVar1378, p11_nodeVar1376.x ), mix( p11_nodeVar1379, p11_nodeVar1380, p11_nodeVar1376.x ), p11_nodeVar1376.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1381 = ( ( p11_nodeVar1366 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1382 = floor( p11_nodeVar1381 );
				p11_nodeVar1383 = ( p11_nodeVar1381 - p11_nodeVar1382 );
				p11_nodeVar1384 = ( p11_nodeVar1383 * p11_nodeVar1383 );
				p11_nodeVar1385 = ( p11_nodeVar1384 * p11_nodeVar1383 );
				p11_nodeVar1386 = ( ( ( ( p11_nodeVar1385 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1384 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1387 = ( ( ( p11_nodeVar1382 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1386 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1383 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1383 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1383 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1386 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1388 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1387.x, p11_nodeVar1387.y ), 0.0 );
				p11_nodeVar1389 = ( p11_nodeVar1385 / vec2<f32>( 6.0 ) );
				p11_nodeVar1390 = ( ( ( ( ( ( p11_nodeVar1385 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1384 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1383 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1389 );
				p11_nodeVar1391 = ( ( ( p11_nodeVar1382 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1389 / p11_nodeVar1390 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1392 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1391.x, p11_nodeVar1387.y ), 0.0 );
				p11_nodeVar1393 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1387.x, p11_nodeVar1391.y ), 0.0 );
				p11_nodeVar1394 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1391.x, p11_nodeVar1391.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1388, p11_nodeVar1392, p11_nodeVar1390.x ), mix( p11_nodeVar1393, p11_nodeVar1394, p11_nodeVar1390.x ), p11_nodeVar1390.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 4.0 ) ) {

			p11_nodeVar1395 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1396 = ( ( p11_nodeVar1395 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1397 = floor( p11_nodeVar1396 );
			p11_nodeVar1398 = ( p11_nodeVar1396 - p11_nodeVar1397 );
			p11_nodeVar1399 = ( p11_nodeVar1398 * p11_nodeVar1398 );
			p11_nodeVar1400 = ( p11_nodeVar1399 * p11_nodeVar1398 );
			p11_nodeVar1401 = ( ( ( ( p11_nodeVar1400 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1399 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1402 = ( ( ( p11_nodeVar1397 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1401 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1398 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1398 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1398 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1401 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1403 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1402.x, p11_nodeVar1402.y ), 0.0 );
			p11_nodeVar1404 = ( p11_nodeVar1400 / vec2<f32>( 6.0 ) );
			p11_nodeVar1405 = ( ( ( ( ( ( p11_nodeVar1400 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1399 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1398 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1404 );
			p11_nodeVar1406 = ( ( ( p11_nodeVar1397 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1404 / p11_nodeVar1405 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1407 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1406.x, p11_nodeVar1402.y ), 0.0 );
			p11_nodeVar1408 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1402.x, p11_nodeVar1406.y ), 0.0 );
			p11_nodeVar1409 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1406.x, p11_nodeVar1406.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1403, p11_nodeVar1407, p11_nodeVar1405.x ), mix( p11_nodeVar1408, p11_nodeVar1409, p11_nodeVar1405.x ), p11_nodeVar1405.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1410 = ( ( p11_nodeVar1395 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1411 = floor( p11_nodeVar1410 );
				p11_nodeVar1412 = ( p11_nodeVar1410 - p11_nodeVar1411 );
				p11_nodeVar1413 = ( p11_nodeVar1412 * p11_nodeVar1412 );
				p11_nodeVar1414 = ( p11_nodeVar1413 * p11_nodeVar1412 );
				p11_nodeVar1415 = ( ( ( ( p11_nodeVar1414 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1413 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1416 = ( ( ( p11_nodeVar1411 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1415 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1412 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1412 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1412 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1415 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1417 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1416.x, p11_nodeVar1416.y ), 0.0 );
				p11_nodeVar1418 = ( p11_nodeVar1414 / vec2<f32>( 6.0 ) );
				p11_nodeVar1419 = ( ( ( ( ( ( p11_nodeVar1414 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1413 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1412 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1418 );
				p11_nodeVar1420 = ( ( ( p11_nodeVar1411 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1418 / p11_nodeVar1419 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1421 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1420.x, p11_nodeVar1416.y ), 0.0 );
				p11_nodeVar1422 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1416.x, p11_nodeVar1420.y ), 0.0 );
				p11_nodeVar1423 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1420.x, p11_nodeVar1420.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1417, p11_nodeVar1421, p11_nodeVar1419.x ), mix( p11_nodeVar1422, p11_nodeVar1423, p11_nodeVar1419.x ), p11_nodeVar1419.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 5.0 ) ) {

			p11_nodeVar1424 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1425 = ( ( p11_nodeVar1424 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1426 = floor( p11_nodeVar1425 );
			p11_nodeVar1427 = ( p11_nodeVar1425 - p11_nodeVar1426 );
			p11_nodeVar1428 = ( p11_nodeVar1427 * p11_nodeVar1427 );
			p11_nodeVar1429 = ( p11_nodeVar1428 * p11_nodeVar1427 );
			p11_nodeVar1430 = ( ( ( ( p11_nodeVar1429 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1428 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1431 = ( ( ( p11_nodeVar1426 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1430 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1427 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1427 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1427 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1430 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1432 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1431.x, p11_nodeVar1431.y ), 0.0 );
			p11_nodeVar1433 = ( p11_nodeVar1429 / vec2<f32>( 6.0 ) );
			p11_nodeVar1434 = ( ( ( ( ( ( p11_nodeVar1429 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1428 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1427 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1433 );
			p11_nodeVar1435 = ( ( ( p11_nodeVar1426 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1433 / p11_nodeVar1434 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1436 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1435.x, p11_nodeVar1431.y ), 0.0 );
			p11_nodeVar1437 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1431.x, p11_nodeVar1435.y ), 0.0 );
			p11_nodeVar1438 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1435.x, p11_nodeVar1435.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1432, p11_nodeVar1436, p11_nodeVar1434.x ), mix( p11_nodeVar1437, p11_nodeVar1438, p11_nodeVar1434.x ), p11_nodeVar1434.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1439 = ( ( p11_nodeVar1424 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1440 = floor( p11_nodeVar1439 );
				p11_nodeVar1441 = ( p11_nodeVar1439 - p11_nodeVar1440 );
				p11_nodeVar1442 = ( p11_nodeVar1441 * p11_nodeVar1441 );
				p11_nodeVar1443 = ( p11_nodeVar1442 * p11_nodeVar1441 );
				p11_nodeVar1444 = ( ( ( ( p11_nodeVar1443 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1442 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1445 = ( ( ( p11_nodeVar1440 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1444 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1441 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1441 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1441 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1444 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1446 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1445.x, p11_nodeVar1445.y ), 0.0 );
				p11_nodeVar1447 = ( p11_nodeVar1443 / vec2<f32>( 6.0 ) );
				p11_nodeVar1448 = ( ( ( ( ( ( p11_nodeVar1443 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1442 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1441 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1447 );
				p11_nodeVar1449 = ( ( ( p11_nodeVar1440 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1447 / p11_nodeVar1448 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1450 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1449.x, p11_nodeVar1445.y ), 0.0 );
				p11_nodeVar1451 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1445.x, p11_nodeVar1449.y ), 0.0 );
				p11_nodeVar1452 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1449.x, p11_nodeVar1449.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1446, p11_nodeVar1450, p11_nodeVar1448.x ), mix( p11_nodeVar1451, p11_nodeVar1452, p11_nodeVar1448.x ), p11_nodeVar1448.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 6.0 ) ) {

			p11_nodeVar1453 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1454 = ( ( p11_nodeVar1453 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1455 = floor( p11_nodeVar1454 );
			p11_nodeVar1456 = ( p11_nodeVar1454 - p11_nodeVar1455 );
			p11_nodeVar1457 = ( p11_nodeVar1456 * p11_nodeVar1456 );
			p11_nodeVar1458 = ( p11_nodeVar1457 * p11_nodeVar1456 );
			p11_nodeVar1459 = ( ( ( ( p11_nodeVar1458 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1457 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1460 = ( ( ( p11_nodeVar1455 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1459 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1456 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1456 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1456 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1459 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1461 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1460.x, p11_nodeVar1460.y ), 0.0 );
			p11_nodeVar1462 = ( p11_nodeVar1458 / vec2<f32>( 6.0 ) );
			p11_nodeVar1463 = ( ( ( ( ( ( p11_nodeVar1458 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1457 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1456 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1462 );
			p11_nodeVar1464 = ( ( ( p11_nodeVar1455 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1462 / p11_nodeVar1463 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1465 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1464.x, p11_nodeVar1460.y ), 0.0 );
			p11_nodeVar1466 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1460.x, p11_nodeVar1464.y ), 0.0 );
			p11_nodeVar1467 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1464.x, p11_nodeVar1464.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1461, p11_nodeVar1465, p11_nodeVar1463.x ), mix( p11_nodeVar1466, p11_nodeVar1467, p11_nodeVar1463.x ), p11_nodeVar1463.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1468 = ( ( p11_nodeVar1453 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1469 = floor( p11_nodeVar1468 );
				p11_nodeVar1470 = ( p11_nodeVar1468 - p11_nodeVar1469 );
				p11_nodeVar1471 = ( p11_nodeVar1470 * p11_nodeVar1470 );
				p11_nodeVar1472 = ( p11_nodeVar1471 * p11_nodeVar1470 );
				p11_nodeVar1473 = ( ( ( ( p11_nodeVar1472 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1471 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1474 = ( ( ( p11_nodeVar1469 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1473 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1470 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1470 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1470 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1473 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1475 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1474.x, p11_nodeVar1474.y ), 0.0 );
				p11_nodeVar1476 = ( p11_nodeVar1472 / vec2<f32>( 6.0 ) );
				p11_nodeVar1477 = ( ( ( ( ( ( p11_nodeVar1472 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1471 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1470 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1476 );
				p11_nodeVar1478 = ( ( ( p11_nodeVar1469 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1476 / p11_nodeVar1477 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1479 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1478.x, p11_nodeVar1474.y ), 0.0 );
				p11_nodeVar1480 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1474.x, p11_nodeVar1478.y ), 0.0 );
				p11_nodeVar1481 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1478.x, p11_nodeVar1478.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1475, p11_nodeVar1479, p11_nodeVar1477.x ), mix( p11_nodeVar1480, p11_nodeVar1481, p11_nodeVar1477.x ), p11_nodeVar1477.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 7.0 ) ) {

			p11_nodeVar1482 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1483 = ( ( p11_nodeVar1482 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1484 = floor( p11_nodeVar1483 );
			p11_nodeVar1485 = ( p11_nodeVar1483 - p11_nodeVar1484 );
			p11_nodeVar1486 = ( p11_nodeVar1485 * p11_nodeVar1485 );
			p11_nodeVar1487 = ( p11_nodeVar1486 * p11_nodeVar1485 );
			p11_nodeVar1488 = ( ( ( ( p11_nodeVar1487 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1486 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1489 = ( ( ( p11_nodeVar1484 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1488 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1485 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1485 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1485 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1488 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1490 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1489.x, p11_nodeVar1489.y ), 0.0 );
			p11_nodeVar1491 = ( p11_nodeVar1487 / vec2<f32>( 6.0 ) );
			p11_nodeVar1492 = ( ( ( ( ( ( p11_nodeVar1487 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1486 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1485 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1491 );
			p11_nodeVar1493 = ( ( ( p11_nodeVar1484 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1491 / p11_nodeVar1492 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1494 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1493.x, p11_nodeVar1489.y ), 0.0 );
			p11_nodeVar1495 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1489.x, p11_nodeVar1493.y ), 0.0 );
			p11_nodeVar1496 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1493.x, p11_nodeVar1493.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1490, p11_nodeVar1494, p11_nodeVar1492.x ), mix( p11_nodeVar1495, p11_nodeVar1496, p11_nodeVar1492.x ), p11_nodeVar1492.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1497 = ( ( p11_nodeVar1482 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1498 = floor( p11_nodeVar1497 );
				p11_nodeVar1499 = ( p11_nodeVar1497 - p11_nodeVar1498 );
				p11_nodeVar1500 = ( p11_nodeVar1499 * p11_nodeVar1499 );
				p11_nodeVar1501 = ( p11_nodeVar1500 * p11_nodeVar1499 );
				p11_nodeVar1502 = ( ( ( ( p11_nodeVar1501 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1500 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1503 = ( ( ( p11_nodeVar1498 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1502 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1499 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1499 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1499 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1502 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1504 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1503.x, p11_nodeVar1503.y ), 0.0 );
				p11_nodeVar1505 = ( p11_nodeVar1501 / vec2<f32>( 6.0 ) );
				p11_nodeVar1506 = ( ( ( ( ( ( p11_nodeVar1501 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1500 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1499 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1505 );
				p11_nodeVar1507 = ( ( ( p11_nodeVar1498 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1505 / p11_nodeVar1506 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1508 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1507.x, p11_nodeVar1503.y ), 0.0 );
				p11_nodeVar1509 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1503.x, p11_nodeVar1507.y ), 0.0 );
				p11_nodeVar1510 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1507.x, p11_nodeVar1507.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1504, p11_nodeVar1508, p11_nodeVar1506.x ), mix( p11_nodeVar1509, p11_nodeVar1510, p11_nodeVar1506.x ), p11_nodeVar1506.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 8.0 ) ) {

			p11_nodeVar1511 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1512 = ( ( p11_nodeVar1511 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1513 = floor( p11_nodeVar1512 );
			p11_nodeVar1514 = ( p11_nodeVar1512 - p11_nodeVar1513 );
			p11_nodeVar1515 = ( p11_nodeVar1514 * p11_nodeVar1514 );
			p11_nodeVar1516 = ( p11_nodeVar1515 * p11_nodeVar1514 );
			p11_nodeVar1517 = ( ( ( ( p11_nodeVar1516 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1515 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1518 = ( ( ( p11_nodeVar1513 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1517 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1514 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1514 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1514 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1517 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1519 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1518.x, p11_nodeVar1518.y ), 0.0 );
			p11_nodeVar1520 = ( p11_nodeVar1516 / vec2<f32>( 6.0 ) );
			p11_nodeVar1521 = ( ( ( ( ( ( p11_nodeVar1516 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1515 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1514 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1520 );
			p11_nodeVar1522 = ( ( ( p11_nodeVar1513 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1520 / p11_nodeVar1521 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1523 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1522.x, p11_nodeVar1518.y ), 0.0 );
			p11_nodeVar1524 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1518.x, p11_nodeVar1522.y ), 0.0 );
			p11_nodeVar1525 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1522.x, p11_nodeVar1522.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1519, p11_nodeVar1523, p11_nodeVar1521.x ), mix( p11_nodeVar1524, p11_nodeVar1525, p11_nodeVar1521.x ), p11_nodeVar1521.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1526 = ( ( p11_nodeVar1511 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1527 = floor( p11_nodeVar1526 );
				p11_nodeVar1528 = ( p11_nodeVar1526 - p11_nodeVar1527 );
				p11_nodeVar1529 = ( p11_nodeVar1528 * p11_nodeVar1528 );
				p11_nodeVar1530 = ( p11_nodeVar1529 * p11_nodeVar1528 );
				p11_nodeVar1531 = ( ( ( ( p11_nodeVar1530 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1529 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1532 = ( ( ( p11_nodeVar1527 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1531 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1528 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1528 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1528 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1531 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1533 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1532.x, p11_nodeVar1532.y ), 0.0 );
				p11_nodeVar1534 = ( p11_nodeVar1530 / vec2<f32>( 6.0 ) );
				p11_nodeVar1535 = ( ( ( ( ( ( p11_nodeVar1530 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1529 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1528 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1534 );
				p11_nodeVar1536 = ( ( ( p11_nodeVar1527 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1534 / p11_nodeVar1535 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1537 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1536.x, p11_nodeVar1532.y ), 0.0 );
				p11_nodeVar1538 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1532.x, p11_nodeVar1536.y ), 0.0 );
				p11_nodeVar1539 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1536.x, p11_nodeVar1536.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1533, p11_nodeVar1537, p11_nodeVar1535.x ), mix( p11_nodeVar1538, p11_nodeVar1539, p11_nodeVar1535.x ), p11_nodeVar1535.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 == 9.0 ) ) {

			p11_nodeVar1540 = ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1541 = ( ( p11_nodeVar1540 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1542 = floor( p11_nodeVar1541 );
			p11_nodeVar1543 = ( p11_nodeVar1541 - p11_nodeVar1542 );
			p11_nodeVar1544 = ( p11_nodeVar1543 * p11_nodeVar1543 );
			p11_nodeVar1545 = ( p11_nodeVar1544 * p11_nodeVar1543 );
			p11_nodeVar1546 = ( ( ( ( p11_nodeVar1545 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1544 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1547 = ( ( ( p11_nodeVar1542 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1546 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1543 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1543 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1543 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1546 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1548 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1547.x, p11_nodeVar1547.y ), 0.0 );
			p11_nodeVar1549 = ( p11_nodeVar1545 / vec2<f32>( 6.0 ) );
			p11_nodeVar1550 = ( ( ( ( ( ( p11_nodeVar1545 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1544 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1543 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1549 );
			p11_nodeVar1551 = ( ( ( p11_nodeVar1542 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1549 / p11_nodeVar1550 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1552 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1551.x, p11_nodeVar1547.y ), 0.0 );
			p11_nodeVar1553 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1547.x, p11_nodeVar1551.y ), 0.0 );
			p11_nodeVar1554 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1551.x, p11_nodeVar1551.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1548, p11_nodeVar1552, p11_nodeVar1550.x ), mix( p11_nodeVar1553, p11_nodeVar1554, p11_nodeVar1550.x ), p11_nodeVar1550.y );

			if ( ( p11_nodeVar1291 > 0.0 ) ) {

				p11_nodeVar1555 = ( ( p11_nodeVar1540 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1556 = floor( p11_nodeVar1555 );
				p11_nodeVar1557 = ( p11_nodeVar1555 - p11_nodeVar1556 );
				p11_nodeVar1558 = ( p11_nodeVar1557 * p11_nodeVar1557 );
				p11_nodeVar1559 = ( p11_nodeVar1558 * p11_nodeVar1557 );
				p11_nodeVar1560 = ( ( ( ( p11_nodeVar1559 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1558 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1561 = ( ( ( p11_nodeVar1556 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1560 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1557 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1557 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1557 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1560 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1562 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1561.x, p11_nodeVar1561.y ), 0.0 );
				p11_nodeVar1563 = ( p11_nodeVar1559 / vec2<f32>( 6.0 ) );
				p11_nodeVar1564 = ( ( ( ( ( ( p11_nodeVar1559 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1558 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1557 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1563 );
				p11_nodeVar1565 = ( ( ( p11_nodeVar1556 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1563 / p11_nodeVar1564 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1566 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1565.x, p11_nodeVar1561.y ), 0.0 );
				p11_nodeVar1567 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1561.x, p11_nodeVar1565.y ), 0.0 );
				p11_nodeVar1568 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1565.x, p11_nodeVar1565.y ), 0.0 );
				p11_nodeVar1288 = mix( p11_nodeVar1288, mix( mix( p11_nodeVar1562, p11_nodeVar1566, p11_nodeVar1564.x ), mix( p11_nodeVar1567, p11_nodeVar1568, p11_nodeVar1564.x ), p11_nodeVar1564.y ), p11_nodeVar1291 );
				

			}

			

		}


		if ( ( p11_nodeVar1290 >= 10.0 ) ) {

			p11_nodeVar1569 = ( ( ( ( p11_nodeVar35 + vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1570 = floor( p11_nodeVar1569 );
			p11_nodeVar1571 = ( p11_nodeVar1569 - p11_nodeVar1570 );
			p11_nodeVar1572 = ( p11_nodeVar1571 * p11_nodeVar1571 );
			p11_nodeVar1573 = ( p11_nodeVar1572 * p11_nodeVar1571 );
			p11_nodeVar1574 = ( ( ( ( p11_nodeVar1573 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1572 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1575 = ( ( ( p11_nodeVar1570 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1574 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1571 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1571 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1571 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1574 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1576 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1575.x, p11_nodeVar1575.y ), 0.0 );
			p11_nodeVar1577 = ( p11_nodeVar1573 / vec2<f32>( 6.0 ) );
			p11_nodeVar1578 = ( ( ( ( ( ( p11_nodeVar1573 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1572 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1571 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1577 );
			p11_nodeVar1579 = ( ( ( p11_nodeVar1570 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1577 / p11_nodeVar1578 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1580 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1579.x, p11_nodeVar1575.y ), 0.0 );
			p11_nodeVar1581 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1575.x, p11_nodeVar1579.y ), 0.0 );
			p11_nodeVar1582 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1579.x, p11_nodeVar1579.y ), 0.0 );
			p11_nodeVar1288 = mix( mix( p11_nodeVar1576, p11_nodeVar1580, p11_nodeVar1578.x ), mix( p11_nodeVar1581, p11_nodeVar1582, p11_nodeVar1578.x ), p11_nodeVar1578.y );
			

		}

		p11_nodeVar1583 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );
		p11_nodeVar1584 = clamp( p11_nodeVar37, 0.0, 10.0 );
		p11_nodeVar1585 = floor( p11_nodeVar1584 );
		p11_nodeVar1586 = ( p11_nodeVar1584 - p11_nodeVar1585 );

		if ( ( p11_nodeVar1585 == 0.0 ) ) {

			p11_nodeVar1587 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1588 = picture_read_level( p11_nodeVar1587, 0.0 );
			p11_nodeVar1583 = vec4<f32>( ( vec3<f32>( p11_nodeVar1588.x, p11_nodeVar1588.y, p11_nodeVar1588.z ) * vec3<f32>( p11_nodeVar1588.w ) ), p11_nodeVar1588.w );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1589 = ( ( p11_nodeVar1587 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1590 = floor( p11_nodeVar1589 );
				p11_nodeVar1591 = ( p11_nodeVar1589 - p11_nodeVar1590 );
				p11_nodeVar1592 = ( p11_nodeVar1591 * p11_nodeVar1591 );
				p11_nodeVar1593 = ( p11_nodeVar1592 * p11_nodeVar1591 );
				p11_nodeVar1594 = ( ( ( ( p11_nodeVar1593 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1592 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1595 = ( ( ( p11_nodeVar1590 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1594 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1591 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1591 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1591 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1594 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1596 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1595.x, p11_nodeVar1595.y ), 0.0 );
				p11_nodeVar1597 = ( p11_nodeVar1593 / vec2<f32>( 6.0 ) );
				p11_nodeVar1598 = ( ( ( ( ( ( p11_nodeVar1593 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1592 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1591 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1597 );
				p11_nodeVar1599 = ( ( ( p11_nodeVar1590 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1597 / p11_nodeVar1598 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1600 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1599.x, p11_nodeVar1595.y ), 0.0 );
				p11_nodeVar1601 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1595.x, p11_nodeVar1599.y ), 0.0 );
				p11_nodeVar1602 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1599.x, p11_nodeVar1599.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1596, p11_nodeVar1600, p11_nodeVar1598.x ), mix( p11_nodeVar1601, p11_nodeVar1602, p11_nodeVar1598.x ), p11_nodeVar1598.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 1.0 ) ) {

			p11_nodeVar1603 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1604 = ( ( p11_nodeVar1603 * vec2<f32>( ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1605 = floor( p11_nodeVar1604 );
			p11_nodeVar1606 = ( p11_nodeVar1604 - p11_nodeVar1605 );
			p11_nodeVar1607 = ( p11_nodeVar1606 * p11_nodeVar1606 );
			p11_nodeVar1608 = ( p11_nodeVar1607 * p11_nodeVar1606 );
			p11_nodeVar1609 = ( ( ( ( p11_nodeVar1608 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1607 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1610 = ( ( ( p11_nodeVar1605 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1609 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1606 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1606 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1606 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1609 ) ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1611 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1610.x, p11_nodeVar1610.y ), 0.0 );
			p11_nodeVar1612 = ( p11_nodeVar1608 / vec2<f32>( 6.0 ) );
			p11_nodeVar1613 = ( ( ( ( ( ( p11_nodeVar1608 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1607 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1606 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1612 );
			p11_nodeVar1614 = ( ( ( p11_nodeVar1605 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1612 / p11_nodeVar1613 ) ) * vec2<f32>((2 * (1.0 / knobs.resolution.x) + 0), (2 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1615 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1614.x, p11_nodeVar1610.y ), 0.0 );
			p11_nodeVar1616 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1610.x, p11_nodeVar1614.y ), 0.0 );
			p11_nodeVar1617 = target_read_level( t0, t0_sampler, vec2<f32>( p11_nodeVar1614.x, p11_nodeVar1614.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1611, p11_nodeVar1615, p11_nodeVar1613.x ), mix( p11_nodeVar1616, p11_nodeVar1617, p11_nodeVar1613.x ), p11_nodeVar1613.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1618 = ( ( p11_nodeVar1603 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1619 = floor( p11_nodeVar1618 );
				p11_nodeVar1620 = ( p11_nodeVar1618 - p11_nodeVar1619 );
				p11_nodeVar1621 = ( p11_nodeVar1620 * p11_nodeVar1620 );
				p11_nodeVar1622 = ( p11_nodeVar1621 * p11_nodeVar1620 );
				p11_nodeVar1623 = ( ( ( ( p11_nodeVar1622 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1621 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1624 = ( ( ( p11_nodeVar1619 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1623 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1620 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1620 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1620 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1623 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1625 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1624.x, p11_nodeVar1624.y ), 0.0 );
				p11_nodeVar1626 = ( p11_nodeVar1622 / vec2<f32>( 6.0 ) );
				p11_nodeVar1627 = ( ( ( ( ( ( p11_nodeVar1622 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1621 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1620 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1626 );
				p11_nodeVar1628 = ( ( ( p11_nodeVar1619 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1626 / p11_nodeVar1627 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1629 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1628.x, p11_nodeVar1624.y ), 0.0 );
				p11_nodeVar1630 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1624.x, p11_nodeVar1628.y ), 0.0 );
				p11_nodeVar1631 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1628.x, p11_nodeVar1628.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1625, p11_nodeVar1629, p11_nodeVar1627.x ), mix( p11_nodeVar1630, p11_nodeVar1631, p11_nodeVar1627.x ), p11_nodeVar1627.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 2.0 ) ) {

			p11_nodeVar1632 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1633 = ( ( p11_nodeVar1632 * vec2<f32>( ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1634 = floor( p11_nodeVar1633 );
			p11_nodeVar1635 = ( p11_nodeVar1633 - p11_nodeVar1634 );
			p11_nodeVar1636 = ( p11_nodeVar1635 * p11_nodeVar1635 );
			p11_nodeVar1637 = ( p11_nodeVar1636 * p11_nodeVar1635 );
			p11_nodeVar1638 = ( ( ( ( p11_nodeVar1637 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1636 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1639 = ( ( ( p11_nodeVar1634 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1638 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1635 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1635 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1635 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1638 ) ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1640 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1639.x, p11_nodeVar1639.y ), 0.0 );
			p11_nodeVar1641 = ( p11_nodeVar1637 / vec2<f32>( 6.0 ) );
			p11_nodeVar1642 = ( ( ( ( ( ( p11_nodeVar1637 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1636 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1635 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1641 );
			p11_nodeVar1643 = ( ( ( p11_nodeVar1634 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1641 / p11_nodeVar1642 ) ) * vec2<f32>((4 * (1.0 / knobs.resolution.x) + 0), (4 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1644 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1643.x, p11_nodeVar1639.y ), 0.0 );
			p11_nodeVar1645 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1639.x, p11_nodeVar1643.y ), 0.0 );
			p11_nodeVar1646 = target_read_level( t1, t1_sampler, vec2<f32>( p11_nodeVar1643.x, p11_nodeVar1643.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1640, p11_nodeVar1644, p11_nodeVar1642.x ), mix( p11_nodeVar1645, p11_nodeVar1646, p11_nodeVar1642.x ), p11_nodeVar1642.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1647 = ( ( p11_nodeVar1632 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1648 = floor( p11_nodeVar1647 );
				p11_nodeVar1649 = ( p11_nodeVar1647 - p11_nodeVar1648 );
				p11_nodeVar1650 = ( p11_nodeVar1649 * p11_nodeVar1649 );
				p11_nodeVar1651 = ( p11_nodeVar1650 * p11_nodeVar1649 );
				p11_nodeVar1652 = ( ( ( ( p11_nodeVar1651 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1650 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1653 = ( ( ( p11_nodeVar1648 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1652 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1649 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1649 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1649 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1652 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1654 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1653.x, p11_nodeVar1653.y ), 0.0 );
				p11_nodeVar1655 = ( p11_nodeVar1651 / vec2<f32>( 6.0 ) );
				p11_nodeVar1656 = ( ( ( ( ( ( p11_nodeVar1651 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1650 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1649 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1655 );
				p11_nodeVar1657 = ( ( ( p11_nodeVar1648 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1655 / p11_nodeVar1656 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1658 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1657.x, p11_nodeVar1653.y ), 0.0 );
				p11_nodeVar1659 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1653.x, p11_nodeVar1657.y ), 0.0 );
				p11_nodeVar1660 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1657.x, p11_nodeVar1657.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1654, p11_nodeVar1658, p11_nodeVar1656.x ), mix( p11_nodeVar1659, p11_nodeVar1660, p11_nodeVar1656.x ), p11_nodeVar1656.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 3.0 ) ) {

			p11_nodeVar1661 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1662 = ( ( p11_nodeVar1661 * vec2<f32>( ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1663 = floor( p11_nodeVar1662 );
			p11_nodeVar1664 = ( p11_nodeVar1662 - p11_nodeVar1663 );
			p11_nodeVar1665 = ( p11_nodeVar1664 * p11_nodeVar1664 );
			p11_nodeVar1666 = ( p11_nodeVar1665 * p11_nodeVar1664 );
			p11_nodeVar1667 = ( ( ( ( p11_nodeVar1666 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1665 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1668 = ( ( ( p11_nodeVar1663 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1667 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1664 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1664 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1664 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1667 ) ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1669 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1668.x, p11_nodeVar1668.y ), 0.0 );
			p11_nodeVar1670 = ( p11_nodeVar1666 / vec2<f32>( 6.0 ) );
			p11_nodeVar1671 = ( ( ( ( ( ( p11_nodeVar1666 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1665 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1664 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1670 );
			p11_nodeVar1672 = ( ( ( p11_nodeVar1663 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1670 / p11_nodeVar1671 ) ) * vec2<f32>((8 * (1.0 / knobs.resolution.x) + 0), (8 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1673 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1672.x, p11_nodeVar1668.y ), 0.0 );
			p11_nodeVar1674 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1668.x, p11_nodeVar1672.y ), 0.0 );
			p11_nodeVar1675 = target_read_level( t2, t2_sampler, vec2<f32>( p11_nodeVar1672.x, p11_nodeVar1672.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1669, p11_nodeVar1673, p11_nodeVar1671.x ), mix( p11_nodeVar1674, p11_nodeVar1675, p11_nodeVar1671.x ), p11_nodeVar1671.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1676 = ( ( p11_nodeVar1661 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1677 = floor( p11_nodeVar1676 );
				p11_nodeVar1678 = ( p11_nodeVar1676 - p11_nodeVar1677 );
				p11_nodeVar1679 = ( p11_nodeVar1678 * p11_nodeVar1678 );
				p11_nodeVar1680 = ( p11_nodeVar1679 * p11_nodeVar1678 );
				p11_nodeVar1681 = ( ( ( ( p11_nodeVar1680 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1679 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1682 = ( ( ( p11_nodeVar1677 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1681 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1678 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1678 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1678 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1681 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1683 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1682.x, p11_nodeVar1682.y ), 0.0 );
				p11_nodeVar1684 = ( p11_nodeVar1680 / vec2<f32>( 6.0 ) );
				p11_nodeVar1685 = ( ( ( ( ( ( p11_nodeVar1680 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1679 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1678 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1684 );
				p11_nodeVar1686 = ( ( ( p11_nodeVar1677 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1684 / p11_nodeVar1685 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1687 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1686.x, p11_nodeVar1682.y ), 0.0 );
				p11_nodeVar1688 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1682.x, p11_nodeVar1686.y ), 0.0 );
				p11_nodeVar1689 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1686.x, p11_nodeVar1686.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1683, p11_nodeVar1687, p11_nodeVar1685.x ), mix( p11_nodeVar1688, p11_nodeVar1689, p11_nodeVar1685.x ), p11_nodeVar1685.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 4.0 ) ) {

			p11_nodeVar1690 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1691 = ( ( p11_nodeVar1690 * vec2<f32>( ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1692 = floor( p11_nodeVar1691 );
			p11_nodeVar1693 = ( p11_nodeVar1691 - p11_nodeVar1692 );
			p11_nodeVar1694 = ( p11_nodeVar1693 * p11_nodeVar1693 );
			p11_nodeVar1695 = ( p11_nodeVar1694 * p11_nodeVar1693 );
			p11_nodeVar1696 = ( ( ( ( p11_nodeVar1695 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1694 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1697 = ( ( ( p11_nodeVar1692 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1696 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1693 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1693 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1693 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1696 ) ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1698 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1697.x, p11_nodeVar1697.y ), 0.0 );
			p11_nodeVar1699 = ( p11_nodeVar1695 / vec2<f32>( 6.0 ) );
			p11_nodeVar1700 = ( ( ( ( ( ( p11_nodeVar1695 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1694 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1693 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1699 );
			p11_nodeVar1701 = ( ( ( p11_nodeVar1692 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1699 / p11_nodeVar1700 ) ) * vec2<f32>((16 * (1.0 / knobs.resolution.x) + 0), (16 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1702 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1701.x, p11_nodeVar1697.y ), 0.0 );
			p11_nodeVar1703 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1697.x, p11_nodeVar1701.y ), 0.0 );
			p11_nodeVar1704 = target_read_level( t3, t3_sampler, vec2<f32>( p11_nodeVar1701.x, p11_nodeVar1701.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1698, p11_nodeVar1702, p11_nodeVar1700.x ), mix( p11_nodeVar1703, p11_nodeVar1704, p11_nodeVar1700.x ), p11_nodeVar1700.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1705 = ( ( p11_nodeVar1690 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1706 = floor( p11_nodeVar1705 );
				p11_nodeVar1707 = ( p11_nodeVar1705 - p11_nodeVar1706 );
				p11_nodeVar1708 = ( p11_nodeVar1707 * p11_nodeVar1707 );
				p11_nodeVar1709 = ( p11_nodeVar1708 * p11_nodeVar1707 );
				p11_nodeVar1710 = ( ( ( ( p11_nodeVar1709 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1708 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1711 = ( ( ( p11_nodeVar1706 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1710 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1707 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1707 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1707 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1710 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1712 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1711.x, p11_nodeVar1711.y ), 0.0 );
				p11_nodeVar1713 = ( p11_nodeVar1709 / vec2<f32>( 6.0 ) );
				p11_nodeVar1714 = ( ( ( ( ( ( p11_nodeVar1709 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1708 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1707 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1713 );
				p11_nodeVar1715 = ( ( ( p11_nodeVar1706 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1713 / p11_nodeVar1714 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1716 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1715.x, p11_nodeVar1711.y ), 0.0 );
				p11_nodeVar1717 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1711.x, p11_nodeVar1715.y ), 0.0 );
				p11_nodeVar1718 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1715.x, p11_nodeVar1715.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1712, p11_nodeVar1716, p11_nodeVar1714.x ), mix( p11_nodeVar1717, p11_nodeVar1718, p11_nodeVar1714.x ), p11_nodeVar1714.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 5.0 ) ) {

			p11_nodeVar1719 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1720 = ( ( p11_nodeVar1719 * vec2<f32>( ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1721 = floor( p11_nodeVar1720 );
			p11_nodeVar1722 = ( p11_nodeVar1720 - p11_nodeVar1721 );
			p11_nodeVar1723 = ( p11_nodeVar1722 * p11_nodeVar1722 );
			p11_nodeVar1724 = ( p11_nodeVar1723 * p11_nodeVar1722 );
			p11_nodeVar1725 = ( ( ( ( p11_nodeVar1724 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1723 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1726 = ( ( ( p11_nodeVar1721 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1725 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1722 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1722 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1722 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1725 ) ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1727 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1726.x, p11_nodeVar1726.y ), 0.0 );
			p11_nodeVar1728 = ( p11_nodeVar1724 / vec2<f32>( 6.0 ) );
			p11_nodeVar1729 = ( ( ( ( ( ( p11_nodeVar1724 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1723 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1722 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1728 );
			p11_nodeVar1730 = ( ( ( p11_nodeVar1721 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1728 / p11_nodeVar1729 ) ) * vec2<f32>((32 * (1.0 / knobs.resolution.x) + 0), (32 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1731 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1730.x, p11_nodeVar1726.y ), 0.0 );
			p11_nodeVar1732 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1726.x, p11_nodeVar1730.y ), 0.0 );
			p11_nodeVar1733 = target_read_level( t4, t4_sampler, vec2<f32>( p11_nodeVar1730.x, p11_nodeVar1730.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1727, p11_nodeVar1731, p11_nodeVar1729.x ), mix( p11_nodeVar1732, p11_nodeVar1733, p11_nodeVar1729.x ), p11_nodeVar1729.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1734 = ( ( p11_nodeVar1719 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1735 = floor( p11_nodeVar1734 );
				p11_nodeVar1736 = ( p11_nodeVar1734 - p11_nodeVar1735 );
				p11_nodeVar1737 = ( p11_nodeVar1736 * p11_nodeVar1736 );
				p11_nodeVar1738 = ( p11_nodeVar1737 * p11_nodeVar1736 );
				p11_nodeVar1739 = ( ( ( ( p11_nodeVar1738 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1737 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1740 = ( ( ( p11_nodeVar1735 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1739 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1736 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1736 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1736 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1739 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1741 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1740.x, p11_nodeVar1740.y ), 0.0 );
				p11_nodeVar1742 = ( p11_nodeVar1738 / vec2<f32>( 6.0 ) );
				p11_nodeVar1743 = ( ( ( ( ( ( p11_nodeVar1738 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1737 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1736 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1742 );
				p11_nodeVar1744 = ( ( ( p11_nodeVar1735 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1742 / p11_nodeVar1743 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1745 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1744.x, p11_nodeVar1740.y ), 0.0 );
				p11_nodeVar1746 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1740.x, p11_nodeVar1744.y ), 0.0 );
				p11_nodeVar1747 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1744.x, p11_nodeVar1744.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1741, p11_nodeVar1745, p11_nodeVar1743.x ), mix( p11_nodeVar1746, p11_nodeVar1747, p11_nodeVar1743.x ), p11_nodeVar1743.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 6.0 ) ) {

			p11_nodeVar1748 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1749 = ( ( p11_nodeVar1748 * vec2<f32>( ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1750 = floor( p11_nodeVar1749 );
			p11_nodeVar1751 = ( p11_nodeVar1749 - p11_nodeVar1750 );
			p11_nodeVar1752 = ( p11_nodeVar1751 * p11_nodeVar1751 );
			p11_nodeVar1753 = ( p11_nodeVar1752 * p11_nodeVar1751 );
			p11_nodeVar1754 = ( ( ( ( p11_nodeVar1753 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1752 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1755 = ( ( ( p11_nodeVar1750 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1754 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1751 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1751 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1751 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1754 ) ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1756 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1755.x, p11_nodeVar1755.y ), 0.0 );
			p11_nodeVar1757 = ( p11_nodeVar1753 / vec2<f32>( 6.0 ) );
			p11_nodeVar1758 = ( ( ( ( ( ( p11_nodeVar1753 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1752 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1751 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1757 );
			p11_nodeVar1759 = ( ( ( p11_nodeVar1750 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1757 / p11_nodeVar1758 ) ) * vec2<f32>((64 * (1.0 / knobs.resolution.x) + 0), (64 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1760 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1759.x, p11_nodeVar1755.y ), 0.0 );
			p11_nodeVar1761 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1755.x, p11_nodeVar1759.y ), 0.0 );
			p11_nodeVar1762 = target_read_level( t5, t5_sampler, vec2<f32>( p11_nodeVar1759.x, p11_nodeVar1759.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1756, p11_nodeVar1760, p11_nodeVar1758.x ), mix( p11_nodeVar1761, p11_nodeVar1762, p11_nodeVar1758.x ), p11_nodeVar1758.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1763 = ( ( p11_nodeVar1748 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1764 = floor( p11_nodeVar1763 );
				p11_nodeVar1765 = ( p11_nodeVar1763 - p11_nodeVar1764 );
				p11_nodeVar1766 = ( p11_nodeVar1765 * p11_nodeVar1765 );
				p11_nodeVar1767 = ( p11_nodeVar1766 * p11_nodeVar1765 );
				p11_nodeVar1768 = ( ( ( ( p11_nodeVar1767 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1766 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1769 = ( ( ( p11_nodeVar1764 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1768 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1765 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1765 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1765 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1768 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1770 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1769.x, p11_nodeVar1769.y ), 0.0 );
				p11_nodeVar1771 = ( p11_nodeVar1767 / vec2<f32>( 6.0 ) );
				p11_nodeVar1772 = ( ( ( ( ( ( p11_nodeVar1767 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1766 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1765 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1771 );
				p11_nodeVar1773 = ( ( ( p11_nodeVar1764 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1771 / p11_nodeVar1772 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1774 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1773.x, p11_nodeVar1769.y ), 0.0 );
				p11_nodeVar1775 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1769.x, p11_nodeVar1773.y ), 0.0 );
				p11_nodeVar1776 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1773.x, p11_nodeVar1773.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1770, p11_nodeVar1774, p11_nodeVar1772.x ), mix( p11_nodeVar1775, p11_nodeVar1776, p11_nodeVar1772.x ), p11_nodeVar1772.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 7.0 ) ) {

			p11_nodeVar1777 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1778 = ( ( p11_nodeVar1777 * vec2<f32>( ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1779 = floor( p11_nodeVar1778 );
			p11_nodeVar1780 = ( p11_nodeVar1778 - p11_nodeVar1779 );
			p11_nodeVar1781 = ( p11_nodeVar1780 * p11_nodeVar1780 );
			p11_nodeVar1782 = ( p11_nodeVar1781 * p11_nodeVar1780 );
			p11_nodeVar1783 = ( ( ( ( p11_nodeVar1782 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1781 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1784 = ( ( ( p11_nodeVar1779 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1783 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1780 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1780 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1780 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1783 ) ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1785 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1784.x, p11_nodeVar1784.y ), 0.0 );
			p11_nodeVar1786 = ( p11_nodeVar1782 / vec2<f32>( 6.0 ) );
			p11_nodeVar1787 = ( ( ( ( ( ( p11_nodeVar1782 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1781 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1780 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1786 );
			p11_nodeVar1788 = ( ( ( p11_nodeVar1779 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1786 / p11_nodeVar1787 ) ) * vec2<f32>((128 * (1.0 / knobs.resolution.x) + 0), (128 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1789 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1788.x, p11_nodeVar1784.y ), 0.0 );
			p11_nodeVar1790 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1784.x, p11_nodeVar1788.y ), 0.0 );
			p11_nodeVar1791 = target_read_level( t6, t6_sampler, vec2<f32>( p11_nodeVar1788.x, p11_nodeVar1788.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1785, p11_nodeVar1789, p11_nodeVar1787.x ), mix( p11_nodeVar1790, p11_nodeVar1791, p11_nodeVar1787.x ), p11_nodeVar1787.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1792 = ( ( p11_nodeVar1777 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1793 = floor( p11_nodeVar1792 );
				p11_nodeVar1794 = ( p11_nodeVar1792 - p11_nodeVar1793 );
				p11_nodeVar1795 = ( p11_nodeVar1794 * p11_nodeVar1794 );
				p11_nodeVar1796 = ( p11_nodeVar1795 * p11_nodeVar1794 );
				p11_nodeVar1797 = ( ( ( ( p11_nodeVar1796 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1795 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1798 = ( ( ( p11_nodeVar1793 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1797 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1794 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1794 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1794 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1797 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1799 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1798.x, p11_nodeVar1798.y ), 0.0 );
				p11_nodeVar1800 = ( p11_nodeVar1796 / vec2<f32>( 6.0 ) );
				p11_nodeVar1801 = ( ( ( ( ( ( p11_nodeVar1796 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1795 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1794 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1800 );
				p11_nodeVar1802 = ( ( ( p11_nodeVar1793 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1800 / p11_nodeVar1801 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1803 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1802.x, p11_nodeVar1798.y ), 0.0 );
				p11_nodeVar1804 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1798.x, p11_nodeVar1802.y ), 0.0 );
				p11_nodeVar1805 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1802.x, p11_nodeVar1802.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1799, p11_nodeVar1803, p11_nodeVar1801.x ), mix( p11_nodeVar1804, p11_nodeVar1805, p11_nodeVar1801.x ), p11_nodeVar1801.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 8.0 ) ) {

			p11_nodeVar1806 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1807 = ( ( p11_nodeVar1806 * vec2<f32>( ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1808 = floor( p11_nodeVar1807 );
			p11_nodeVar1809 = ( p11_nodeVar1807 - p11_nodeVar1808 );
			p11_nodeVar1810 = ( p11_nodeVar1809 * p11_nodeVar1809 );
			p11_nodeVar1811 = ( p11_nodeVar1810 * p11_nodeVar1809 );
			p11_nodeVar1812 = ( ( ( ( p11_nodeVar1811 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1810 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1813 = ( ( ( p11_nodeVar1808 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1812 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1809 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1809 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1809 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1812 ) ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1814 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1813.x, p11_nodeVar1813.y ), 0.0 );
			p11_nodeVar1815 = ( p11_nodeVar1811 / vec2<f32>( 6.0 ) );
			p11_nodeVar1816 = ( ( ( ( ( ( p11_nodeVar1811 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1810 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1809 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1815 );
			p11_nodeVar1817 = ( ( ( p11_nodeVar1808 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1815 / p11_nodeVar1816 ) ) * vec2<f32>((256 * (1.0 / knobs.resolution.x) + 0), (256 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1818 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1817.x, p11_nodeVar1813.y ), 0.0 );
			p11_nodeVar1819 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1813.x, p11_nodeVar1817.y ), 0.0 );
			p11_nodeVar1820 = target_read_level( t7, t7_sampler, vec2<f32>( p11_nodeVar1817.x, p11_nodeVar1817.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1814, p11_nodeVar1818, p11_nodeVar1816.x ), mix( p11_nodeVar1819, p11_nodeVar1820, p11_nodeVar1816.x ), p11_nodeVar1816.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1821 = ( ( p11_nodeVar1806 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1822 = floor( p11_nodeVar1821 );
				p11_nodeVar1823 = ( p11_nodeVar1821 - p11_nodeVar1822 );
				p11_nodeVar1824 = ( p11_nodeVar1823 * p11_nodeVar1823 );
				p11_nodeVar1825 = ( p11_nodeVar1824 * p11_nodeVar1823 );
				p11_nodeVar1826 = ( ( ( ( p11_nodeVar1825 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1824 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1827 = ( ( ( p11_nodeVar1822 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1826 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1823 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1823 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1823 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1826 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1828 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1827.x, p11_nodeVar1827.y ), 0.0 );
				p11_nodeVar1829 = ( p11_nodeVar1825 / vec2<f32>( 6.0 ) );
				p11_nodeVar1830 = ( ( ( ( ( ( p11_nodeVar1825 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1824 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1823 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1829 );
				p11_nodeVar1831 = ( ( ( p11_nodeVar1822 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1829 / p11_nodeVar1830 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
				p11_nodeVar1832 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1831.x, p11_nodeVar1827.y ), 0.0 );
				p11_nodeVar1833 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1827.x, p11_nodeVar1831.y ), 0.0 );
				p11_nodeVar1834 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1831.x, p11_nodeVar1831.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1828, p11_nodeVar1832, p11_nodeVar1830.x ), mix( p11_nodeVar1833, p11_nodeVar1834, p11_nodeVar1830.x ), p11_nodeVar1830.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 == 9.0 ) ) {

			p11_nodeVar1835 = ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
			p11_nodeVar1836 = ( ( p11_nodeVar1835 * vec2<f32>( ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).x ), ( 1.0 / vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1837 = floor( p11_nodeVar1836 );
			p11_nodeVar1838 = ( p11_nodeVar1836 - p11_nodeVar1837 );
			p11_nodeVar1839 = ( p11_nodeVar1838 * p11_nodeVar1838 );
			p11_nodeVar1840 = ( p11_nodeVar1839 * p11_nodeVar1838 );
			p11_nodeVar1841 = ( ( ( ( p11_nodeVar1840 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1839 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1842 = ( ( ( p11_nodeVar1837 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1841 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1838 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1838 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1838 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1841 ) ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1843 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1842.x, p11_nodeVar1842.y ), 0.0 );
			p11_nodeVar1844 = ( p11_nodeVar1840 / vec2<f32>( 6.0 ) );
			p11_nodeVar1845 = ( ( ( ( ( ( p11_nodeVar1840 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1839 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1838 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1844 );
			p11_nodeVar1846 = ( ( ( p11_nodeVar1837 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1844 / p11_nodeVar1845 ) ) * vec2<f32>((512 * (1.0 / knobs.resolution.x) + 0), (512 * (1.0 / knobs.resolution.y) + 0)) );
			p11_nodeVar1847 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1846.x, p11_nodeVar1842.y ), 0.0 );
			p11_nodeVar1848 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1842.x, p11_nodeVar1846.y ), 0.0 );
			p11_nodeVar1849 = target_read_level( t8, t8_sampler, vec2<f32>( p11_nodeVar1846.x, p11_nodeVar1846.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1843, p11_nodeVar1847, p11_nodeVar1845.x ), mix( p11_nodeVar1848, p11_nodeVar1849, p11_nodeVar1845.x ), p11_nodeVar1845.y );

			if ( ( p11_nodeVar1586 > 0.0 ) ) {

				p11_nodeVar1850 = ( ( p11_nodeVar1835 * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
				p11_nodeVar1851 = floor( p11_nodeVar1850 );
				p11_nodeVar1852 = ( p11_nodeVar1850 - p11_nodeVar1851 );
				p11_nodeVar1853 = ( p11_nodeVar1852 * p11_nodeVar1852 );
				p11_nodeVar1854 = ( p11_nodeVar1853 * p11_nodeVar1852 );
				p11_nodeVar1855 = ( ( ( ( p11_nodeVar1854 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1853 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
				p11_nodeVar1856 = ( ( ( p11_nodeVar1851 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1855 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1852 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1852 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1852 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1855 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1857 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1856.x, p11_nodeVar1856.y ), 0.0 );
				p11_nodeVar1858 = ( p11_nodeVar1854 / vec2<f32>( 6.0 ) );
				p11_nodeVar1859 = ( ( ( ( ( ( p11_nodeVar1854 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1853 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1852 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1858 );
				p11_nodeVar1860 = ( ( ( p11_nodeVar1851 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1858 / p11_nodeVar1859 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
				p11_nodeVar1861 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1860.x, p11_nodeVar1856.y ), 0.0 );
				p11_nodeVar1862 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1856.x, p11_nodeVar1860.y ), 0.0 );
				p11_nodeVar1863 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1860.x, p11_nodeVar1860.y ), 0.0 );
				p11_nodeVar1583 = mix( p11_nodeVar1583, mix( mix( p11_nodeVar1857, p11_nodeVar1861, p11_nodeVar1859.x ), mix( p11_nodeVar1862, p11_nodeVar1863, p11_nodeVar1859.x ), p11_nodeVar1859.y ), p11_nodeVar1586 );
				

			}

			

		}


		if ( ( p11_nodeVar1585 >= 10.0 ) ) {

			p11_nodeVar1864 = ( ( ( ( p11_nodeVar35 - vec2<f32>( 0.0, max( 1.0, ( f32(knobs.smoothing) * 0.5 ) ) ) ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) * vec2<f32>( ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).x ), ( 1.0 / vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0).y ) ) ) - vec2<f32>( 0.5 ) );
			p11_nodeVar1865 = floor( p11_nodeVar1864 );
			p11_nodeVar1866 = ( p11_nodeVar1864 - p11_nodeVar1865 );
			p11_nodeVar1867 = ( p11_nodeVar1866 * p11_nodeVar1866 );
			p11_nodeVar1868 = ( p11_nodeVar1867 * p11_nodeVar1866 );
			p11_nodeVar1869 = ( ( ( ( p11_nodeVar1868 * vec2<f32>( 3.0 ) ) - ( p11_nodeVar1867 * vec2<f32>( 6.0 ) ) ) + vec2<f32>( 4.0 ) ) / vec2<f32>( 6.0 ) );
			p11_nodeVar1870 = ( ( ( p11_nodeVar1865 - vec2<f32>( 0.5 ) ) + ( p11_nodeVar1869 / ( ( ( ( ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1866 ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1866 ) ) * ( vec2<f32>( 1.0, 1.0 ) - p11_nodeVar1866 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1869 ) ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1871 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1870.x, p11_nodeVar1870.y ), 0.0 );
			p11_nodeVar1872 = ( p11_nodeVar1868 / vec2<f32>( 6.0 ) );
			p11_nodeVar1873 = ( ( ( ( ( ( p11_nodeVar1868 * vec2<f32>( -3.0 ) ) + ( p11_nodeVar1867 * vec2<f32>( 3.0 ) ) ) + ( p11_nodeVar1866 * vec2<f32>( 3.0 ) ) ) + vec2<f32>( 1.0 ) ) / vec2<f32>( 6.0 ) ) + p11_nodeVar1872 );
			p11_nodeVar1874 = ( ( ( p11_nodeVar1865 + vec2<f32>( 1.5 ) ) + ( p11_nodeVar1872 / p11_nodeVar1873 ) ) * vec2<f32>((1024 * (1.0 / knobs.resolution.x) + 0), 1.0) );
			p11_nodeVar1875 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1874.x, p11_nodeVar1870.y ), 0.0 );
			p11_nodeVar1876 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1870.x, p11_nodeVar1874.y ), 0.0 );
			p11_nodeVar1877 = target_read_level( t9, t9_sampler, vec2<f32>( p11_nodeVar1874.x, p11_nodeVar1874.y ), 0.0 );
			p11_nodeVar1583 = mix( mix( p11_nodeVar1871, p11_nodeVar1875, p11_nodeVar1873.x ), mix( p11_nodeVar1876, p11_nodeVar1877, p11_nodeVar1873.x ), p11_nodeVar1873.y );
			

		}

		p11_nodeVar1879 = ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) < 2.5 );

		if ( p11_nodeVar1879 ) {

			p11_nodeVar1881 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
			p11_nodeVar1882 = clamp( dot( vec3<f32>( p11_nodeVar1881.x, p11_nodeVar1881.y, p11_nodeVar1881.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p11_nodeVar1882 <= 0.0031308 ) ) {

				p11_nodeVar1880 = ( p11_nodeVar1882 * 12.92 );

			} else {

				p11_nodeVar1880 = ( ( pow( p11_nodeVar1882, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p11_nodeVar1883 = ( ( 1.0 - p11_nodeVar1880 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) );
			p11_nodeVar1878 = ( mix( f32(knobs.weight), ( f32(knobs.weight) * 2.2 ), ( f32(knobs.pressure) * p11_nodeVar1883 ) ) * mix( 0.5, 1.3, p11_nodeVar1883 ) );

		} else {

			p11_nodeVar1885 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
			p11_nodeVar1886 = clamp( dot( vec3<f32>( p11_nodeVar1885.x, p11_nodeVar1885.y, p11_nodeVar1885.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p11_nodeVar1886 <= 0.0031308 ) ) {

				p11_nodeVar1884 = ( p11_nodeVar1886 * 12.92 );

			} else {

				p11_nodeVar1884 = ( ( pow( p11_nodeVar1886, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p11_nodeVar1878 = mix( f32(knobs.weight), ( f32(knobs.weight) * 2.2 ), ( f32(knobs.pressure) * ( ( 1.0 - p11_nodeVar1884 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) ) ) );

		}

		p11_nodeVar1887 = ( p11_nodeVar1878 * 0.5 );
		p11_nodeVar1888 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1890 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
		p11_nodeVar1891 = clamp( dot( vec3<f32>( p11_nodeVar1890.x, p11_nodeVar1890.y, p11_nodeVar1890.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1891 <= 0.0031308 ) ) {

			p11_nodeVar1889 = ( p11_nodeVar1891 * 12.92 );

		} else {

			p11_nodeVar1889 = ( ( pow( p11_nodeVar1891, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1892 = ( ( 1.0 - p11_nodeVar1889 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) );

		if ( p11_nodeVar1879 ) {

			p11_nodeVar1893 = ( ( vec2<f32>(knobs.resolution.x, knobs.resolution.y).x / f32(knobs.gap) ) * 0.25 );

		} else {

			p11_nodeVar1893 = f32(knobs.levels);

		}

		p11_nodeVar1895 = vec4<f32>( ( p11_nodeVar698.xyz / vec3<f32>( max( p11_nodeVar698.w, 0.0001 ) ) ), p11_nodeVar698.w );
		p11_nodeVar1896 = clamp( dot( vec3<f32>( p11_nodeVar1895.x, p11_nodeVar1895.y, p11_nodeVar1895.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1896 <= 0.0031308 ) ) {

			p11_nodeVar1894 = ( p11_nodeVar1896 * 12.92 );

		} else {

			p11_nodeVar1894 = ( ( pow( p11_nodeVar1896, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1898 = vec4<f32>( ( p11_nodeVar993.xyz / vec3<f32>( max( p11_nodeVar993.w, 0.0001 ) ) ), p11_nodeVar993.w );
		p11_nodeVar1899 = clamp( dot( vec3<f32>( p11_nodeVar1898.x, p11_nodeVar1898.y, p11_nodeVar1898.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1899 <= 0.0031308 ) ) {

			p11_nodeVar1897 = ( p11_nodeVar1899 * 12.92 );

		} else {

			p11_nodeVar1897 = ( ( pow( p11_nodeVar1899, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1900 = max( 1.0, ( f32(knobs.smoothing) * 0.5 ) );
		p11_nodeVar1902 = vec4<f32>( ( p11_nodeVar1288.xyz / vec3<f32>( max( p11_nodeVar1288.w, 0.0001 ) ) ), p11_nodeVar1288.w );
		p11_nodeVar1903 = clamp( dot( vec3<f32>( p11_nodeVar1902.x, p11_nodeVar1902.y, p11_nodeVar1902.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1903 <= 0.0031308 ) ) {

			p11_nodeVar1901 = ( p11_nodeVar1903 * 12.92 );

		} else {

			p11_nodeVar1901 = ( ( pow( p11_nodeVar1903, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1905 = vec4<f32>( ( p11_nodeVar1583.xyz / vec3<f32>( max( p11_nodeVar1583.w, 0.0001 ) ) ), p11_nodeVar1583.w );
		p11_nodeVar1906 = clamp( dot( vec3<f32>( p11_nodeVar1905.x, p11_nodeVar1905.y, p11_nodeVar1905.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1906 <= 0.0031308 ) ) {

			p11_nodeVar1904 = ( p11_nodeVar1906 * 12.92 );

		} else {

			p11_nodeVar1904 = ( ( pow( p11_nodeVar1906, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}


		if ( p11_nodeVar1879 ) {

			p11_nodeVar1907 = smoothstep( ( f32(knobs.threshold) * 0.3 ), ( ( f32(knobs.threshold) * 0.3 ) + 0.12 ), p11_nodeVar1892 );

		} else {

			p11_nodeVar1907 = 1.0;

		}

		p11_nodeVar348 = ( ( 1.0 - smoothstep( ( p11_nodeVar1887 - p11_nodeVar1888 ), ( p11_nodeVar1887 + p11_nodeVar1888 ), ( abs( ( fract( ( p11_nodeVar1892 * p11_nodeVar1893 ) ) - 0.5 ) ) / ( max( length( vec2<f32>( ( ( ( ( 1.0 - p11_nodeVar1894 ) * clamp( p11_nodeVar698.w, 0.0, 1.0 ) ) - ( ( 1.0 - p11_nodeVar1897 ) * clamp( p11_nodeVar993.w, 0.0, 1.0 ) ) ) / ( p11_nodeVar1900 * 2.0 ) ), ( ( ( ( 1.0 - p11_nodeVar1901 ) * clamp( p11_nodeVar1288.w, 0.0, 1.0 ) ) - ( ( 1.0 - p11_nodeVar1904 ) * clamp( p11_nodeVar1583.w, 0.0, 1.0 ) ) ) / ( p11_nodeVar1900 * 2.0 ) ) ) ), 0.0005 ) * p11_nodeVar1893 ) ) ) ) * p11_nodeVar1907 );
		

	}


	if ( ( ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) > 3.5 ) && ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) < 4.5 ) ) ) {

		p11_nodeVar1908 = 0.0;
		p11_nodeVar1910 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
		p11_nodeVar1911 = clamp( dot( vec3<f32>( p11_nodeVar1910.x, p11_nodeVar1910.y, p11_nodeVar1910.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1911 <= 0.0031308 ) ) {

			p11_nodeVar1909 = ( p11_nodeVar1911 * 12.92 );

		} else {

			p11_nodeVar1909 = ( ( pow( p11_nodeVar1911, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1912 = mix( f32(knobs.weight), ( f32(knobs.weight) * 2.2 ), ( f32(knobs.pressure) * ( ( 1.0 - p11_nodeVar1909 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) ) ) );
		p11_nodeVar1913 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1914 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1915 = ( f32(knobs.gap) * 0.5 );
		p11_nodeVar1916 = floor( ( p11_nodeVar34 / vec2<f32>( p11_nodeVar1915 ) ) );
		p11_nodeVar1917 = ( p11_nodeVar1916 + vec2<f32>( -1.0, -1.0 ) );
		p11_nodeVar1918 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1917 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1913 - p11_nodeVar1914 ), ( p11_nodeVar1913 + p11_nodeVar1914 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1917 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1917, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1917, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1918.x ) );
		p11_nodeVar1919 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1920 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1921 = ( p11_nodeVar1916 + vec2<f32>( 0.0, -1.0 ) );
		p11_nodeVar1922 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1921 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1919 - p11_nodeVar1920 ), ( p11_nodeVar1919 + p11_nodeVar1920 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1921 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1921, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1921, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1922.x ) );
		p11_nodeVar1923 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1924 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1925 = ( p11_nodeVar1916 + vec2<f32>( 1.0, -1.0 ) );
		p11_nodeVar1926 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1925 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1923 - p11_nodeVar1924 ), ( p11_nodeVar1923 + p11_nodeVar1924 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1925 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1925, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1925, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1926.x ) );
		p11_nodeVar1927 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1928 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1929 = ( p11_nodeVar1916 + vec2<f32>( -1.0, 0.0 ) );
		p11_nodeVar1930 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1929 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1927 - p11_nodeVar1928 ), ( p11_nodeVar1927 + p11_nodeVar1928 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1929 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1929, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1929, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1930.x ) );
		p11_nodeVar1931 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1932 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1933 = ( p11_nodeVar1916 + vec2<f32>( 0.0, 0.0 ) );
		p11_nodeVar1934 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1933 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1931 - p11_nodeVar1932 ), ( p11_nodeVar1931 + p11_nodeVar1932 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1933 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1933, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1933, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1934.x ) );
		p11_nodeVar1935 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1936 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1937 = ( p11_nodeVar1916 + vec2<f32>( 1.0, 0.0 ) );
		p11_nodeVar1938 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1937 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1935 - p11_nodeVar1936 ), ( p11_nodeVar1935 + p11_nodeVar1936 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1937 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1937, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1937, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1938.x ) );
		p11_nodeVar1939 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1940 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1941 = ( p11_nodeVar1916 + vec2<f32>( -1.0, 1.0 ) );
		p11_nodeVar1942 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1941 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1939 - p11_nodeVar1940 ), ( p11_nodeVar1939 + p11_nodeVar1940 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1941 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1941, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1941, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1942.x ) );
		p11_nodeVar1943 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1944 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1945 = ( p11_nodeVar1916 + vec2<f32>( 0.0, 1.0 ) );
		p11_nodeVar1946 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1945 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1943 - p11_nodeVar1944 ), ( p11_nodeVar1943 + p11_nodeVar1944 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1945 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1945, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1945, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1946.x ) );
		p11_nodeVar1947 = ( ( p11_nodeVar1912 * 1.4 ) * 0.5 );
		p11_nodeVar1948 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1949 = ( p11_nodeVar1916 + vec2<f32>( 1.0, 1.0 ) );
		p11_nodeVar1950 = target_load( t10, vec2<i32>( ( mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0) * vec3<f32>( ( p11_nodeVar1949 + vec2<f32>( 1.0 ) ), 1.0 ) ).xy ), u32( 0u ) );
		p11_nodeVar1908 = max( p11_nodeVar1908, ( ( 1.0 - smoothstep( ( p11_nodeVar1947 - p11_nodeVar1948 ), ( p11_nodeVar1947 + p11_nodeVar1948 ), length( ( p11_nodeVar34 - ( ( p11_nodeVar1949 + fract( ( sin( vec2<f32>( dot( p11_nodeVar1949, vec2<f32>( 127.1, 311.7 ) ), dot( p11_nodeVar1949, vec2<f32>( 269.5, 183.3 ) ) ) ) * vec2<f32>( 43758.5453 ) ) ) ) * vec2<f32>( p11_nodeVar1915 ) ) ) ) ) ) * p11_nodeVar1950.x ) );
		p11_nodeVar348 = p11_nodeVar1908;
		

	}


	if ( ( f32(array<f32, 6>(0.0, 2.0, 3.0, 1.0, 5.0, 4.0)[u32(knobs.mode)]) > 4.5 ) ) {

		p11_nodeVar1952 = vec4<f32>( ( p11_nodeVar36.xyz / vec3<f32>( max( p11_nodeVar36.w, 0.0001 ) ) ), p11_nodeVar36.w );
		p11_nodeVar1953 = clamp( dot( vec3<f32>( p11_nodeVar1952.x, p11_nodeVar1952.y, p11_nodeVar1952.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p11_nodeVar1953 <= 0.0031308 ) ) {

			p11_nodeVar1951 = ( p11_nodeVar1953 * 12.92 );

		} else {

			p11_nodeVar1951 = ( ( pow( p11_nodeVar1953, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p11_nodeVar1954 = ( ( 1.0 - p11_nodeVar1951 ) * clamp( p11_nodeVar36.w, 0.0, 1.0 ) );
		p11_nodeVar1955 = ( mix( ( f32(knobs.weight) * 0.3 ), ( f32(knobs.gap) * 0.9 ), pow( p11_nodeVar1954, 1.2 ) ) * 0.5 );
		p11_nodeVar1956 = ( f32(0.8) + ( f32(knobs.bleed) * 0.6 ) );
		p11_nodeVar1957 = ( p11_nodeVar35 - ( ( ( vec2<f32>( vec2<f32>(0.0, 0.0).x, ( - vec2<f32>(0.0, 0.0).y ) ) * vec2<f32>( 0.5 ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>(knobs.resolution.x, knobs.resolution.y) ) );
		p11_nodeVar348 = ( ( 1.0 - smoothstep( ( p11_nodeVar1955 - p11_nodeVar1956 ), ( p11_nodeVar1955 + p11_nodeVar1956 ), ( abs( ( fract( ( ( length( p11_nodeVar1957 ) / f32(knobs.gap) ) - ( atan2( p11_nodeVar1957.y, p11_nodeVar1957.x ) / 6.283185307179586 ) ) ) - 0.5 ) ) * f32(knobs.gap) ) ) ) * smoothstep( 0.01, 0.06, p11_nodeVar1954 ) );
		

	}

	p11_nodeVar1958 = 0.0;

	if ( ( f32(knobs.paperGrain) > 0.0 ) ) {

		p11_nodeVar1959 = ( p11_nodeVar34 / vec2<f32>( 1.3 ) );
		p11_nodeVar1960 = floor( p11_nodeVar1959 );
		p11_nodeVar1961 = fract( ( vec3<f32>( p11_nodeVar1960.x, p11_nodeVar1960.y, p11_nodeVar1960.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar1962 = ( p11_nodeVar1961 + vec3<f32>( dot( p11_nodeVar1961, ( vec3<f32>( p11_nodeVar1961.y, p11_nodeVar1961.z, p11_nodeVar1961.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar1963 = ( p11_nodeVar1960 + vec2<f32>( 1.0, 0.0 ) );
		p11_nodeVar1964 = fract( ( vec3<f32>( p11_nodeVar1963.x, p11_nodeVar1963.y, p11_nodeVar1963.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar1965 = ( p11_nodeVar1964 + vec3<f32>( dot( p11_nodeVar1964, ( vec3<f32>( p11_nodeVar1964.y, p11_nodeVar1964.z, p11_nodeVar1964.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar1966 = fract( p11_nodeVar1959 );
		p11_nodeVar1967 = ( ( p11_nodeVar1966 * p11_nodeVar1966 ) * ( vec2<f32>( 3.0 ) - ( p11_nodeVar1966 * vec2<f32>( 2.0 ) ) ) );
		p11_nodeVar1968 = ( p11_nodeVar1960 + vec2<f32>( 0.0, 1.0 ) );
		p11_nodeVar1969 = fract( ( vec3<f32>( p11_nodeVar1968.x, p11_nodeVar1968.y, p11_nodeVar1968.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar1970 = ( p11_nodeVar1969 + vec3<f32>( dot( p11_nodeVar1969, ( vec3<f32>( p11_nodeVar1969.y, p11_nodeVar1969.z, p11_nodeVar1969.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar1971 = ( p11_nodeVar1960 + vec2<f32>( 1.0, 1.0 ) );
		p11_nodeVar1972 = fract( ( vec3<f32>( p11_nodeVar1971.x, p11_nodeVar1971.y, p11_nodeVar1971.x ) * vec3<f32>( 0.1031 ) ) );
		p11_nodeVar1973 = ( p11_nodeVar1972 + vec3<f32>( dot( p11_nodeVar1972, ( vec3<f32>( p11_nodeVar1972.y, p11_nodeVar1972.z, p11_nodeVar1972.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p11_nodeVar1958 = ( ( ( mix( mix( fract( ( ( p11_nodeVar1962.x + p11_nodeVar1962.y ) * p11_nodeVar1962.z ) ), fract( ( ( p11_nodeVar1965.x + p11_nodeVar1965.y ) * p11_nodeVar1965.z ) ), p11_nodeVar1967.x ), mix( fract( ( ( p11_nodeVar1970.x + p11_nodeVar1970.y ) * p11_nodeVar1970.z ) ), fract( ( ( p11_nodeVar1973.x + p11_nodeVar1973.y ) * p11_nodeVar1973.z ) ), p11_nodeVar1967.x ), p11_nodeVar1967.y ) - 0.5 ) * f32(knobs.paperGrain) ) * 0.08 );
		

	}

	p11_nodeVar1975 = ( f32(knobs.paper) > 0.5 );

	if ( p11_nodeVar1975 ) {


		if ( ( f32(knobs.colorMode) < 0.5 ) ) {

			p11_nodeVar1976 = vec3<f32>(knobs.inkColor.x, knobs.inkColor.y, knobs.inkColor.z);

		} else {


			if ( ( f32(knobs.colorMode) < 1.5 ) ) {

				p11_nodeVar1978 = picture_read_level( p11_nodeVar33, 0.0 );
				p11_nodeVar1977 = vec3<f32>( p11_nodeVar1978.x, p11_nodeVar1978.y, p11_nodeVar1978.z );

			} else {

				p11_nodeVar1977 = vec3<f32>(knobs.inkColor.x, knobs.inkColor.y, knobs.inkColor.z);

			}

			p11_nodeVar1976 = p11_nodeVar1977;

		}

		p11_nodeVar1979 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), ( vec3<f32>( 1.0, 1.0, 1.0 ) * p11_nodeVar1976 ), clamp( ( p11_nodeVar348 * p11_nodeVar332 ), 0.0, 1.0 ) );

		if ( ( f32(knobs.colorMode) > 1.5 ) ) {

			p11_nodeVar1980 = vec3<f32>(knobs.pen2Color.x, knobs.pen2Color.y, knobs.pen2Color.z);

		} else {

			p11_nodeVar1980 = p11_nodeVar1976;

		}

		p11_nodeVar1981 = mix( p11_nodeVar1979, ( p11_nodeVar1979 * p11_nodeVar1980 ), clamp( ( p11_nodeVar349 * p11_nodeVar332 ), 0.0, 1.0 ) );

		if ( ( f32(knobs.colorMode) > 1.5 ) ) {

			p11_nodeVar1982 = vec3<f32>(knobs.pen3Color.x, knobs.pen3Color.y, knobs.pen3Color.z);

		} else {

			p11_nodeVar1982 = p11_nodeVar1976;

		}

		p11_nodeVar1974 = clamp( ( vec3<f32>( 1.0 ) - ( ( vec3<f32>( 1.0 ) - mix( p11_nodeVar1981, ( p11_nodeVar1981 * p11_nodeVar1982 ), clamp( ( p11_nodeVar350 * p11_nodeVar332 ), 0.0, 1.0 ) ) ) / vec3<f32>( max( clamp( ( 1.0 - ( ( ( 1.0 - clamp( p11_nodeVar348, 0.0, 1.0 ) ) * ( 1.0 - clamp( p11_nodeVar349, 0.0, 1.0 ) ) ) * ( 1.0 - clamp( p11_nodeVar350, 0.0, 1.0 ) ) ) ), 0.0, 1.0 ), 0.0001 ) ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) );

	} else {

		p11_nodeVar1983 = clamp( ( vec3<f32>(knobs.paperColor.x, knobs.paperColor.y, knobs.paperColor.z) + vec3<f32>( p11_nodeVar1958 ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) );

		if ( ( f32(knobs.colorMode) < 0.5 ) ) {

			p11_nodeVar1984 = vec3<f32>(knobs.inkColor.x, knobs.inkColor.y, knobs.inkColor.z);

		} else {


			if ( ( f32(knobs.colorMode) < 1.5 ) ) {

				p11_nodeVar1986 = picture_read_level( p11_nodeVar33, 0.0 );
				p11_nodeVar1985 = vec3<f32>( p11_nodeVar1986.x, p11_nodeVar1986.y, p11_nodeVar1986.z );

			} else {

				p11_nodeVar1985 = vec3<f32>(knobs.inkColor.x, knobs.inkColor.y, knobs.inkColor.z);

			}

			p11_nodeVar1984 = p11_nodeVar1985;

		}

		p11_nodeVar1987 = mix( p11_nodeVar1983, ( p11_nodeVar1983 * p11_nodeVar1984 ), clamp( ( p11_nodeVar348 * p11_nodeVar332 ), 0.0, 1.0 ) );

		if ( ( f32(knobs.colorMode) > 1.5 ) ) {

			p11_nodeVar1988 = vec3<f32>(knobs.pen2Color.x, knobs.pen2Color.y, knobs.pen2Color.z);

		} else {

			p11_nodeVar1988 = p11_nodeVar1984;

		}

		p11_nodeVar1989 = mix( p11_nodeVar1987, ( p11_nodeVar1987 * p11_nodeVar1988 ), clamp( ( p11_nodeVar349 * p11_nodeVar332 ), 0.0, 1.0 ) );

		if ( ( f32(knobs.colorMode) > 1.5 ) ) {

			p11_nodeVar1990 = vec3<f32>(knobs.pen3Color.x, knobs.pen3Color.y, knobs.pen3Color.z);

		} else {

			p11_nodeVar1990 = p11_nodeVar1984;

		}

		p11_nodeVar1974 = mix( p11_nodeVar1989, ( p11_nodeVar1989 * p11_nodeVar1990 ), clamp( ( p11_nodeVar350 * p11_nodeVar332 ), 0.0, 1.0 ) );

	}


	if ( p11_nodeVar1975 ) {

		p11_nodeVar1991 = clamp( ( 1.0 - ( ( ( 1.0 - clamp( p11_nodeVar348, 0.0, 1.0 ) ) * ( 1.0 - clamp( p11_nodeVar349, 0.0, 1.0 ) ) ) * ( 1.0 - clamp( p11_nodeVar350, 0.0, 1.0 ) ) ) ), 0.0, 1.0 );

	} else {

		p11_nodeVar1991 = 1.0;

	}

	p11_nodeVar1992 = vec4<f32>( p11_nodeVar1974, p11_nodeVar1991 );
	p11_nodeVar1993 = vec3<f32>( p11_nodeVar1992.x, p11_nodeVar1992.y, p11_nodeVar1992.z );
	p11_nodeVar1994 = ( ( ( p11_nodeVar1993.x * 0.2126 ) + ( p11_nodeVar1993.y * 0.7152 ) ) + ( p11_nodeVar1993.z * 0.0722 ) );
	p11_nodeVar1995 = mix( vec3<f32>( p11_nodeVar1994, p11_nodeVar1994, p11_nodeVar1994 ), p11_nodeVar1993, f32(1.0) );
	p11_nodeVar1996 = vec4<f32>( clamp( vec3<f32>( ( ( ( p11_nodeVar1995.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p11_nodeVar1995.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p11_nodeVar1995.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p11_nodeVar1995.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p11_nodeVar1995.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p11_nodeVar1995.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p11_nodeVar1995.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p11_nodeVar1995.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p11_nodeVar1995.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p11_nodeVar1992.w, 0.0, 1.0 ) );
	p11_nodeVar1998 = mix( clamp( p11_nodeVar0.w, 0.0, 1.0 ), clamp( p11_nodeVar1996.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p11_nodeVar1998 > 0.0 ) ) {

		p11_nodeVar1997 = p11_nodeVar1998;

	} else {

		p11_nodeVar1997 = 1.0;

	}

	p11_DiffuseColor = vec4<f32>( ( mix( ( p11_nodeVar0.xyz * vec3<f32>( clamp( p11_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p11_nodeVar1996.xyz, p11_nodeVar1996.xyz, clamp( p11_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p11_nodeVar1996.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p11_nodeVar1997 ) ), p11_nodeVar1998 );
	p11_DiffuseColor.w = ( p11_DiffuseColor.w * f32(1.0) );
	p11_nodeVar1999 = max( vec4<f32>( p11_DiffuseColor.xyz, p11_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p11_Output = p11_nodeVar1999;

	// result

	p11_output.color = p11_nodeVar1999;

	return p11_output;

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
    case 10u: { return p10_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p11_main(door_uv).color);
}

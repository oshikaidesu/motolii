// Bloom: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Makes bright areas glow and bleed into their surroundings.
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s0.5,s0.5
// --pass@t2:0,1,s0.25,s0.25
// --pass@t3:0,1,s0.125,s0.125
// --pass@t4:0,1,s0.0625,s0.0625
// --pass@t5:0,1,s0.125,s0.125
// --pass@t6:0,1,s0.25,s0.25
// --pass@:0,0,s1,s1
// --track@bloomIntensity:Intensity,0,2,1.25,0.01
// --track@bloomThreshold:Threshold,0,1,0.6,0.01
// --track@bloomSoftness:Softness,0,1,0.35,0.01
// --track@bloomKnee:Knee,0,0.5,0.2,0.01
// --track@highlightDrive:Highlight Drive,1,4,1.5,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  bloomIntensity: f32,
  bloomThreshold: f32,
  bloomSoftness: f32,
  bloomKnee: f32,
  highlightDrive: f32,
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
@group(0) @binding(16) var<uniform> knobs: Knobs;
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
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar2 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = max( f32(knobs.bloomKnee), 0.0001 );
	p0_DiffuseColor = vec4<f32>( ( ( vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z ) * vec3<f32>( smoothstep( ( f32(knobs.bloomThreshold) - p0_nodeVar1 ), ( f32(knobs.bloomThreshold) + p0_nodeVar1 ), ( ( ( p0_nodeVar0.x * 0.2126 ) + ( p0_nodeVar0.y * 0.7152 ) ) + ( p0_nodeVar0.z * 0.0722 ) ) ) ) ) * vec3<f32>( f32(knobs.highlightDrive) ) ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar2 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar2;

	// result

	p0_output.color = p0_nodeVar2;

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
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar1 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p1_DiffuseColor = vec4<f32>( ( p1_nodeVar0.xyz * vec3<f32>( smoothstep( f32(knobs.bloomThreshold), ( f32(knobs.bloomThreshold) + max( f32((0.25 * knobs.bloomSoftness + 0)), 0.0001 ) ), dot( p1_nodeVar0.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) ) ), 1.0 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_DiffuseColor.w = 1.0;
	p1_nodeVar1 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar1;

	// result

	p1_output.color = p1_nodeVar1;

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
	p2_nodeVar1 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar2 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p2_nodeVar3 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p2_nodeVar4 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p2_nodeVar5 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p2_nodeVar6 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar7 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p2_nodeVar8 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar9 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p2_nodeVar10 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar11 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p2_nodeVar12 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p2_nodeVar13 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p2_DiffuseColor = vec4<f32>( ( ( ( ( p2_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p2_nodeVar2.xyz + p2_nodeVar3.xyz ) + ( p2_nodeVar4.xyz + p2_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p2_nodeVar6.xyz + p2_nodeVar7.xyz ) + ( p2_nodeVar8.xyz + p2_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p2_nodeVar10.xyz + p2_nodeVar11.xyz ) + ( p2_nodeVar12.xyz + p2_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_DiffuseColor.w = 1.0;
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
	p3_nodeVar1 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar2 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p3_nodeVar3 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p3_nodeVar4 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p3_nodeVar5 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p3_nodeVar6 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar7 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p3_nodeVar8 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar9 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p3_nodeVar10 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar11 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -2.0 ) ) ) );
	p3_nodeVar12 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p3_nodeVar13 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 2.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 2.0 ) ) ) );
	p3_DiffuseColor = vec4<f32>( ( ( ( ( p3_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p3_nodeVar2.xyz + p3_nodeVar3.xyz ) + ( p3_nodeVar4.xyz + p3_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p3_nodeVar6.xyz + p3_nodeVar7.xyz ) + ( p3_nodeVar8.xyz + p3_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p3_nodeVar10.xyz + p3_nodeVar11.xyz ) + ( p3_nodeVar12.xyz + p3_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_DiffuseColor.w = 1.0;
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
	p4_nodeVar1 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar2 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -1.0 ) ) ) );
	p4_nodeVar3 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -1.0 ) ) ) );
	p4_nodeVar4 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 1.0 ) ) ) );
	p4_nodeVar5 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 1.0 ) ) ) );
	p4_nodeVar6 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar7 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 0.0 ) ) ) );
	p4_nodeVar8 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar9 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p4_nodeVar10 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar11 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * -2.0 ) ) ) );
	p4_nodeVar12 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * -2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p4_nodeVar13 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).x * 2.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.0625)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.0625)) + 0)).y * 2.0 ) ) ) );
	p4_DiffuseColor = vec4<f32>( ( ( ( ( p4_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p4_nodeVar2.xyz + p4_nodeVar3.xyz ) + ( p4_nodeVar4.xyz + p4_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p4_nodeVar6.xyz + p4_nodeVar7.xyz ) + ( p4_nodeVar8.xyz + p4_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p4_nodeVar10.xyz + p4_nodeVar11.xyz ) + ( p4_nodeVar12.xyz + p4_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p4_DiffuseColor.w = ( p4_DiffuseColor.w * f32(1.0) );
	p4_DiffuseColor.w = 1.0;
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
var<private> p5_nodeVar0 : vec4<f32>;
var<private> p5_nodeVar1 : vec2<f32>;
var<private> p5_nodeVar2 : vec4<f32>;
var<private> p5_nodeVar3 : vec4<f32>;
var<private> p5_nodeVar4 : vec4<f32>;
var<private> p5_nodeVar5 : vec4<f32>;
var<private> p5_nodeVar6 : vec4<f32>;
var<private> p5_nodeVar7 : vec4<f32>;
var<private> p5_nodeVar8 : vec4<f32>;
var<private> p5_nodeVar9 : vec4<f32>;
var<private> p5_nodeVar10 : vec4<f32>;
var<private> p5_Output : vec4<f32>;
var<private> p5_nodeVar11 : vec4<f32>;

// codes


fn p5_main(door_uv: vec2f) -> p5_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p5_nodeVar0 = target_read( t3, t3_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p5_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p5_nodeVar2 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar3 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar4 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 0.0 ) ) ) );
	p5_nodeVar5 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p5_nodeVar6 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 0.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p5_nodeVar7 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p5_nodeVar8 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * -1.0 ) ) ) );
	p5_nodeVar9 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * -1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p5_nodeVar10 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).x * 1.0 ), ( vec2<f32>((16 * (1.0 / (knobs.resolution.x / 0.125)) + 0), (16 * (1.0 / (knobs.resolution.y / 0.125)) + 0)).y * 1.0 ) ) ) );
	p5_DiffuseColor = vec4<f32>( ( p5_nodeVar0.xyz + ( ( ( p5_nodeVar2.xyz * vec3<f32>( 0.25 ) ) + ( ( ( p5_nodeVar3.xyz + p5_nodeVar4.xyz ) + ( p5_nodeVar5.xyz + p5_nodeVar6.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p5_nodeVar7.xyz + p5_nodeVar8.xyz ) + ( p5_nodeVar9.xyz + p5_nodeVar10.xyz ) ) * vec3<f32>( 0.0625 ) ) ) ), 1.0 );
	p5_DiffuseColor.w = ( p5_DiffuseColor.w * f32(1.0) );
	p5_DiffuseColor.w = 1.0;
	p5_nodeVar11 = max( vec4<f32>( p5_DiffuseColor.xyz, p5_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p5_Output = p5_nodeVar11;

	// result

	p5_output.color = p5_nodeVar11;

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
var<private> p6_nodeVar0 : vec4<f32>;
var<private> p6_nodeVar1 : vec2<f32>;
var<private> p6_nodeVar2 : vec4<f32>;
var<private> p6_nodeVar3 : vec4<f32>;
var<private> p6_nodeVar4 : vec4<f32>;
var<private> p6_nodeVar5 : vec4<f32>;
var<private> p6_nodeVar6 : vec4<f32>;
var<private> p6_nodeVar7 : vec4<f32>;
var<private> p6_nodeVar8 : vec4<f32>;
var<private> p6_nodeVar9 : vec4<f32>;
var<private> p6_nodeVar10 : vec4<f32>;
var<private> p6_Output : vec4<f32>;
var<private> p6_nodeVar11 : vec4<f32>;

// codes


fn p6_main(door_uv: vec2f) -> p6_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p6_nodeVar0 = target_read( t2, t2_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p6_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p6_nodeVar2 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar3 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar4 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p6_nodeVar5 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p6_nodeVar6 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p6_nodeVar7 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p6_nodeVar8 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p6_nodeVar9 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p6_nodeVar10 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((8 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (8 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p6_DiffuseColor = vec4<f32>( ( p6_nodeVar0.xyz + ( ( ( p6_nodeVar2.xyz * vec3<f32>( 0.25 ) ) + ( ( ( p6_nodeVar3.xyz + p6_nodeVar4.xyz ) + ( p6_nodeVar5.xyz + p6_nodeVar6.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p6_nodeVar7.xyz + p6_nodeVar8.xyz ) + ( p6_nodeVar9.xyz + p6_nodeVar10.xyz ) ) * vec3<f32>( 0.0625 ) ) ) ), 1.0 );
	p6_DiffuseColor.w = ( p6_DiffuseColor.w * f32(1.0) );
	p6_DiffuseColor.w = 1.0;
	p6_nodeVar11 = max( vec4<f32>( p6_DiffuseColor.xyz, p6_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p6_Output = p6_nodeVar11;

	// result

	p6_output.color = p6_nodeVar11;

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
var<private> p7_nodeVar0 : vec4<f32>;
var<private> p7_nodeVar1 : vec4<f32>;
var<private> p7_nodeVar2 : vec4<f32>;
var<private> p7_nodeVar3 : vec3<f32>;
var<private> p7_nodeVar4 : f32;
var<private> p7_nodeVar5 : vec3<f32>;
var<private> p7_nodeVar6 : vec4<f32>;
var<private> p7_Output : vec4<f32>;
var<private> p7_nodeVar7 : vec4<f32>;

// codes


fn p7_main(door_uv: vec2f) -> p7_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p7_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_nodeVar1 = target_read( t6, t6_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_nodeVar2 = vec4<f32>( clamp( ( vec3<f32>( p7_nodeVar0.x, p7_nodeVar0.y, p7_nodeVar0.z ) + clamp( ( ( p7_nodeVar1.xyz * vec3<f32>( f32(1.1) ) ) * vec3<f32>( f32(knobs.bloomIntensity) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 2.0, 2.0, 2.0 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p7_nodeVar3 = vec3<f32>( p7_nodeVar2.x, p7_nodeVar2.y, p7_nodeVar2.z );
	p7_nodeVar4 = ( ( ( p7_nodeVar3.x * 0.2126 ) + ( p7_nodeVar3.y * 0.7152 ) ) + ( p7_nodeVar3.z * 0.0722 ) );
	p7_nodeVar5 = mix( vec3<f32>( p7_nodeVar4, p7_nodeVar4, p7_nodeVar4 ), p7_nodeVar3, f32(1.0) );
	p7_nodeVar6 = vec4<f32>( clamp( vec3<f32>( ( ( ( p7_nodeVar5.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p7_nodeVar5.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p7_nodeVar5.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p7_nodeVar5.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p7_nodeVar5.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p7_nodeVar5.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p7_nodeVar5.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p7_nodeVar5.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p7_nodeVar5.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p7_nodeVar2.w, 0.0, 1.0 ) );
	p7_DiffuseColor = vec4<f32>( mix( p7_nodeVar0.xyz, p7_nodeVar6.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p7_nodeVar6.w, 0.0, 1.0 ) ) ), clamp( p7_nodeVar0.w, 0.0, 1.0 ) );
	p7_DiffuseColor.w = ( p7_DiffuseColor.w * f32(1.0) );
	p7_nodeVar7 = max( vec4<f32>( p7_DiffuseColor.xyz, p7_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p7_Output = p7_nodeVar7;

	// result

	p7_output.color = p7_nodeVar7;

	return p7_output;

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
    default: {}
  }
  return to_shelf(p7_main(door_uv).color);
}

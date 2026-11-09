// Slice: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Shifts horizontal slices of the image sideways into glitchy bands.
// --track@amount:Amount,0,480,180,1
// --track@sliceHeight:Slice Height,2,240,28,1
// --track@blockWidth:Block Width,8,640,120,1
// --track@density:Density,0,1,0.58,0.01
// --track@dispersion:Dispersion,0,0.5,0.18,0.01
// --track@speed:Speed,0,2,0.2,0.01
// --track@direction:Direction,0,2,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  amount: f32,
  sliceHeight: f32,
  blockWidth: f32,
  density: f32,
  dispersion: f32,
  speed: f32,
  direction: f32,
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
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : vec4<f32>;
var<private> p0_nodeVar14 : vec3<f32>;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : vec3<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar18 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = vec2<f32>( ( p0_nodeVar1.x * f32(knobs.resolution.x) ), ( p0_nodeVar1.y * f32(knobs.resolution.y) ) );
	p0_nodeVar3 = floor( ( p0_nodeVar2.y / f32(knobs.sliceHeight) ) );
	p0_nodeVar4 = floor( ( ( f32(knobs.time) * f32(knobs.speed) ) * 6.0 ) );
	p0_nodeVar5 = fract( ( sin( dot( vec2<f32>( ( p0_nodeVar3 + 0.37 ), ( p0_nodeVar4 + 11.13 ) ), vec2<f32>( 127.1, 311.7 ) ) ) * 43758.5453123 ) );
	p0_nodeVar6 = step( ( 1.0 - f32(knobs.density) ), fract( ( sin( dot( vec2<f32>( ( ( floor( ( p0_nodeVar2.x / f32(knobs.blockWidth) ) ) + ( p0_nodeVar4 * 0.73 ) ) + 2.4 ), ( p0_nodeVar3 + 19.7 ) ), vec2<f32>( 127.1, 311.7 ) ) ) * 43758.5453123 ) ) );

	if ( ( f32(array<f32, 3>(1.0, 2.0, 0.0)[u32(knobs.direction)]) > 1.5 ) ) {

		p0_nodeVar7 = -1.0;

	} else {


		if ( ( f32(array<f32, 3>(1.0, 2.0, 0.0)[u32(knobs.direction)]) > 0.5 ) ) {

			p0_nodeVar8 = 1.0;

		} else {

			p0_nodeVar8 = ( ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar3 + 7.2 ), ( p0_nodeVar4 + 31.4 ) ), vec2<f32>( 127.1, 311.7 ) ) ) * 43758.5453123 ) ) * 2.0 ) - 1.0 );

		}

		p0_nodeVar7 = p0_nodeVar8;

	}

	p0_nodeVar9 = picture_read( vec2<f32>( ( ( p0_nodeVar1.x + vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x ) + vec2<f32>( ( vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x * f32(knobs.dispersion) ), 0.0 ).x ), p0_nodeVar1.y ) );
	p0_nodeVar10 = picture_read( vec2<f32>( ( p0_nodeVar1.x + vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x ), p0_nodeVar1.y ) );
	p0_nodeVar11 = picture_read( vec2<f32>( ( ( p0_nodeVar1.x + vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x ) - vec2<f32>( ( vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x * f32(knobs.dispersion) ), 0.0 ).x ), p0_nodeVar1.y ) );
	p0_nodeVar12 = picture_read( vec2<f32>( ( p0_nodeVar1.x + vec2<f32>( ( vec2<f32>( ( ( ( ( pow( p0_nodeVar5, 1.35 ) * f32(knobs.amount) ) * p0_nodeVar6 ) * p0_nodeVar7 ) / f32(knobs.resolution.x) ), 0.0 ).x * 0.35 ), 0.0 ).x ), p0_nodeVar1.y ) );
	p0_nodeVar13 = vec4<f32>( mix( vec3<f32>( p0_nodeVar9.x, p0_nodeVar10.y, p0_nodeVar11.z ), p0_nodeVar12.xyz, ( p0_nodeVar6 * ( ( p0_nodeVar5 * 0.42 ) + 0.18 ) ) ), 1.0 );
	p0_nodeVar14 = vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z );
	p0_nodeVar15 = ( ( ( p0_nodeVar14.x * 0.2126 ) + ( p0_nodeVar14.y * 0.7152 ) ) + ( p0_nodeVar14.z * 0.0722 ) );
	p0_nodeVar16 = mix( vec3<f32>( p0_nodeVar15, p0_nodeVar15, p0_nodeVar15 ), p0_nodeVar14, f32(1.0) );
	p0_nodeVar17 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar16.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar16.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar16.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar16.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar16.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar16.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar16.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar16.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar16.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar13.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar17.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar17.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar18 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar18;

	// result

	p0_output.color = p0_nodeVar18;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

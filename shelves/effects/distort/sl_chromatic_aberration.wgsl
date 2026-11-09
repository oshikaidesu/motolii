// Chromatic Aberration: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Splits the color channels apart for lens fringing.
// --track@intensity:Intensity,0,50,5,0.5
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  intensity: f32,
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
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec4<f32>;
var<private> p0_nodeVar8 : vec4<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_nodeVar11 : vec3<f32>;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : vec3<f32>;
var<private> p0_nodeVar14 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar15 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = vec2<f32>( f32(0.5), ( 1.0 - f32(0.5) ) );
	p0_nodeVar3 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar2.x ), ( p0_nodeVar1.y - p0_nodeVar2.y ) );
	p0_nodeVar4 = length( p0_nodeVar3 );
	p0_nodeVar5 = vec2<f32>( ( ( p0_nodeVar3.x / ( p0_nodeVar4 + 0.0001 ) ) * p0_nodeVar4 ), ( ( p0_nodeVar3.y / ( p0_nodeVar4 + 0.0001 ) ) * p0_nodeVar4 ) );
	p0_nodeVar6 = vec2<f32>( ( p0_nodeVar5.x * ( f32(knobs.intensity) / f32(knobs.resolution.x) ) ), ( p0_nodeVar5.y * ( f32(knobs.intensity) / f32(knobs.resolution.y) ) ) );
	p0_nodeVar7 = picture_read( clamp( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar6.x ), ( p0_nodeVar1.y + p0_nodeVar6.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar8 = picture_read( p0_nodeVar1 );
	p0_nodeVar9 = picture_read( clamp( vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar6.x ), ( p0_nodeVar1.y - p0_nodeVar6.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar10 = vec4<f32>( p0_nodeVar7.x, p0_nodeVar8.y, p0_nodeVar9.z, 1.0 );
	p0_nodeVar11 = vec3<f32>( p0_nodeVar10.x, p0_nodeVar10.y, p0_nodeVar10.z );
	p0_nodeVar12 = ( ( ( p0_nodeVar11.x * 0.2126 ) + ( p0_nodeVar11.y * 0.7152 ) ) + ( p0_nodeVar11.z * 0.0722 ) );
	p0_nodeVar13 = mix( vec3<f32>( p0_nodeVar12, p0_nodeVar12, p0_nodeVar12 ), p0_nodeVar11, f32(1.0) );
	p0_nodeVar14 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar13.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar13.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar13.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar13.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar13.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar13.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar13.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar13.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar13.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar10.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar14.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar14.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar15 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar15;

	// result

	p0_output.color = p0_nodeVar15;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

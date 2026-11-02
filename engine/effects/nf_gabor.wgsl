// Gabor noise: threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions), by three.js's own builder (engine/tsl/noise_fx_shelf.ts)
// --label:Generate
// --track@scale:Scale,0,24,6,0.1
// --track@pace:Pace,0,4,1,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  pace: f32,
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
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : u32;
var<private> p0_nodeVar3 : u32;
var<private> p0_nodeVar4 : u32;
var<private> p0_nodeVar5 : u32;
var<private> p0_nodeVar6 : u32;
var<private> p0_nodeVar7 : u32;
var<private> p0_nodeVar8 : u32;
var<private> p0_nodeVar9 : u32;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : vec2<f32>;
var<private> p0_nodeVar12 : u32;
var<private> p0_nodeVar13 : u32;
var<private> p0_nodeVar14 : u32;
var<private> p0_nodeVar15 : u32;
var<private> p0_nodeVar16 : u32;
var<private> p0_nodeVar17 : u32;
var<private> p0_nodeVar18 : u32;
var<private> p0_nodeVar19 : u32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar20 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_nodeVar0 = ( ( ( nodeVarying4.xy + vec2<f32>( 3.0 ) ) * vec2<f32>( ( f32(knobs.scale) / 2.0 ) ) ) + vec2<f32>( ( sin( ( f32(knobs.time) * f32(knobs.pace) ) ) + 1.0 ) ) );
	p0_nodeVar1 = floor( p0_nodeVar0 );
	p0_nodeVar2 = ( ( vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 0.0, 0.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 0.0, 0.0 ) ) ) ).y );
	p0_nodeVar3 = ( ( p0_nodeVar2 ^ ( p0_nodeVar2 >> 16u ) ) * 2146121005u );
	p0_nodeVar4 = ( ( p0_nodeVar3 ^ ( p0_nodeVar3 >> 15u ) ) * 2221713035u );
	p0_nodeVar5 = ( ( p0_nodeVar3 ^ ( p0_nodeVar3 >> 13u ) ) * 2654435769u );
	p0_nodeVar6 = ( ( vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 1.0, 0.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 1.0, 0.0 ) ) ) ).y );
	p0_nodeVar7 = ( ( p0_nodeVar6 ^ ( p0_nodeVar6 >> 16u ) ) * 2146121005u );
	p0_nodeVar8 = ( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 15u ) ) * 2221713035u );
	p0_nodeVar9 = ( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 13u ) ) * 2654435769u );
	p0_nodeVar10 = ( p0_nodeVar0 - p0_nodeVar1 );
	p0_nodeVar11 = ( ( p0_nodeVar10 * p0_nodeVar10 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar10 * vec2<f32>( 2.0 ) ) ) );
	p0_nodeVar12 = ( ( vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 0.0, 1.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 0.0, 1.0 ) ) ) ).y );
	p0_nodeVar13 = ( ( p0_nodeVar12 ^ ( p0_nodeVar12 >> 16u ) ) * 2146121005u );
	p0_nodeVar14 = ( ( p0_nodeVar13 ^ ( p0_nodeVar13 >> 15u ) ) * 2221713035u );
	p0_nodeVar15 = ( ( p0_nodeVar13 ^ ( p0_nodeVar13 >> 13u ) ) * 2654435769u );
	p0_nodeVar16 = ( ( vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 1.0, 1.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar1 + vec2<f32>( 1.0, 1.0 ) ) ) ).y );
	p0_nodeVar17 = ( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 16u ) ) * 2146121005u );
	p0_nodeVar18 = ( ( p0_nodeVar17 ^ ( p0_nodeVar17 >> 15u ) ) * 2221713035u );
	p0_nodeVar19 = ( ( p0_nodeVar17 ^ ( p0_nodeVar17 >> 13u ) ) * 2654435769u );
	p0_DiffuseColor = vec4<f32>( ( ( mix( mix( sin( ( 8.0 * dot( p0_nodeVar0, ( vec2<f32>( f32( ( p0_nodeVar4 ^ ( p0_nodeVar4 >> 16u ) ) ), f32( ( p0_nodeVar5 ^ ( p0_nodeVar5 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) ) ) ), sin( ( 8.0 * dot( p0_nodeVar0, ( vec2<f32>( f32( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 16u ) ) ), f32( ( p0_nodeVar9 ^ ( p0_nodeVar9 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) ) ) ), p0_nodeVar11.x ), mix( sin( ( 8.0 * dot( p0_nodeVar0, ( vec2<f32>( f32( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 16u ) ) ), f32( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) ) ) ), sin( ( 8.0 * dot( p0_nodeVar0, ( vec2<f32>( f32( ( p0_nodeVar18 ^ ( p0_nodeVar18 >> 16u ) ) ), f32( ( p0_nodeVar19 ^ ( p0_nodeVar19 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) ) ) ), p0_nodeVar11.x ), p0_nodeVar11.y ) * 0.5 ) + 0.5 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar20 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar20;

	// result

	p0_output.color = p0_nodeVar20;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

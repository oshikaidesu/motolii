// Chromatic Aberration: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Splits the color channels apart for lens fringing.
// --track@intensity:Intensity,0,50,5,0.5
// Three.js r185 - Node System

// global
diagnostic( off, derivative_uniformity );


// structs

struct OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> output : OutputStruct;

// uniforms
struct Knobs {
  time: f32,
  intensity: f32,
  resolution: vec2<f32>,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;
fn to_linear(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }
fn to_srgb(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }
fn picture_read(uv: vec2<f32>) -> vec4<f32> { return picture_read_level(uv, 0.0); }
fn picture_read_level(uv: vec2<f32>, level: f32) -> vec4<f32> {
  let p = textureSampleLevel(picture, picture_sampler, uv, level);
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_linear(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}
fn to_shelf(p: vec4<f32>) -> vec4<f32> {
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_srgb(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}


// vars
var<private> DiffuseColor : vec4<f32>;
var<private> nodeVar0 : vec4<f32>;
var<private> nodeVar1 : vec2<f32>;
var<private> nodeVar2 : vec2<f32>;
var<private> nodeVar3 : vec2<f32>;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec4<f32>;
var<private> nodeVar8 : vec4<f32>;
var<private> nodeVar9 : vec4<f32>;
var<private> nodeVar10 : vec4<f32>;
var<private> nodeVar11 : vec3<f32>;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : vec3<f32>;
var<private> nodeVar14 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar15 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = vec2<f32>( f32(0.5), ( 1.0 - f32(0.5) ) );
	nodeVar3 = vec2<f32>( ( nodeVar1.x - nodeVar2.x ), ( nodeVar1.y - nodeVar2.y ) );
	nodeVar4 = length( nodeVar3 );
	nodeVar5 = vec2<f32>( ( ( nodeVar3.x / ( nodeVar4 + 0.0001 ) ) * nodeVar4 ), ( ( nodeVar3.y / ( nodeVar4 + 0.0001 ) ) * nodeVar4 ) );
	nodeVar6 = vec2<f32>( ( nodeVar5.x * ( knobs.intensity / knobs.resolution.x ) ), ( nodeVar5.y * ( knobs.intensity / knobs.resolution.y ) ) );
	nodeVar7 = picture_read( clamp( vec2<f32>( ( nodeVar1.x + nodeVar6.x ), ( nodeVar1.y + nodeVar6.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	nodeVar8 = picture_read( nodeVar1 );
	nodeVar9 = picture_read( clamp( vec2<f32>( ( nodeVar1.x - nodeVar6.x ), ( nodeVar1.y - nodeVar6.y ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	nodeVar10 = vec4<f32>( nodeVar7.x, nodeVar8.y, nodeVar9.z, 1.0 );
	nodeVar11 = vec3<f32>( nodeVar10.x, nodeVar10.y, nodeVar10.z );
	nodeVar12 = ( ( ( nodeVar11.x * 0.2126 ) + ( nodeVar11.y * 0.7152 ) ) + ( nodeVar11.z * 0.0722 ) );
	nodeVar13 = mix( vec3<f32>( nodeVar12, nodeVar12, nodeVar12 ), nodeVar11, f32(1.0) );
	nodeVar14 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar13.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar13.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar13.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar13.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar13.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar13.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar13.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar13.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar13.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar10.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar14.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar14.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar15 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar15;

	// result

	output.color = nodeVar15;

	output.color = to_shelf(output.color);
	return output;

}

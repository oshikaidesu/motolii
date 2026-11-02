// Edge Detect: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Finds edges in the image and draws them as outlines.
// --track@threshold:Threshold,0,1,0.1,0.01
// --track@strength:Strength,0.1,5,1,0.1
// --check@invert:Invert,0
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
  resolution: vec2<f32>,
  strength: f32,
  threshold: f32,
  invert: f32,
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
var<private> nodeVar2 : vec4<f32>;
var<private> nodeVar3 : f32;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : vec4<f32>;
var<private> nodeVar7 : f32;
var<private> nodeVar8 : vec4<f32>;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : vec4<f32>;
var<private> nodeVar11 : vec4<f32>;
var<private> nodeVar12 : vec4<f32>;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : vec4<f32>;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : vec4<f32>;
var<private> nodeVar18 : vec4<f32>;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec4<f32>;
var<private> nodeVar22 : vec3<f32>;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : vec3<f32>;
var<private> nodeVar25 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar26 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = picture_read( nodeVar1 );
	nodeVar4 = ( 1.0 / knobs.resolution.x );
	nodeVar5 = ( 1.0 / knobs.resolution.y );
	nodeVar6 = picture_read( vec2<f32>( ( nodeVar1.x + ( - nodeVar4 ) ), ( nodeVar1.y + ( - nodeVar5 ) ) ) );
	nodeVar7 = ( ( ( nodeVar6.x * 0.2126 ) + ( nodeVar6.y * 0.7152 ) ) + ( nodeVar6.z * 0.0722 ) );
	nodeVar8 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar4 ), ( nodeVar1.y + ( - nodeVar5 ) ) ) );
	nodeVar9 = ( ( ( nodeVar8.x * 0.2126 ) + ( nodeVar8.y * 0.7152 ) ) + ( nodeVar8.z * 0.0722 ) );
	nodeVar10 = picture_read( vec2<f32>( ( nodeVar1.x + ( - nodeVar4 ) ), ( nodeVar1.y + 0.0 ) ) );
	nodeVar11 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar4 ), ( nodeVar1.y + 0.0 ) ) );
	nodeVar12 = picture_read( vec2<f32>( ( nodeVar1.x + ( - nodeVar4 ) ), ( nodeVar1.y + nodeVar5 ) ) );
	nodeVar13 = ( ( ( nodeVar12.x * 0.2126 ) + ( nodeVar12.y * 0.7152 ) ) + ( nodeVar12.z * 0.0722 ) );
	nodeVar14 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar4 ), ( nodeVar1.y + nodeVar5 ) ) );
	nodeVar15 = ( ( ( nodeVar14.x * 0.2126 ) + ( nodeVar14.y * 0.7152 ) ) + ( nodeVar14.z * 0.0722 ) );
	nodeVar16 = ( ( ( ( ( ( nodeVar7 * -1.0 ) + nodeVar9 ) + ( ( ( ( nodeVar10.x * 0.2126 ) + ( nodeVar10.y * 0.7152 ) ) + ( nodeVar10.z * 0.0722 ) ) * -2.0 ) ) + ( ( ( ( nodeVar11.x * 0.2126 ) + ( nodeVar11.y * 0.7152 ) ) + ( nodeVar11.z * 0.0722 ) ) * 2.0 ) ) + ( nodeVar13 * -1.0 ) ) + nodeVar15 );
	nodeVar17 = picture_read( vec2<f32>( ( nodeVar1.x + 0.0 ), ( nodeVar1.y + ( - nodeVar5 ) ) ) );
	nodeVar18 = picture_read( vec2<f32>( ( nodeVar1.x + 0.0 ), ( nodeVar1.y + nodeVar5 ) ) );
	nodeVar19 = ( ( ( ( ( ( nodeVar7 * -1.0 ) + ( ( ( ( nodeVar17.x * 0.2126 ) + ( nodeVar17.y * 0.7152 ) ) + ( nodeVar17.z * 0.0722 ) ) * -2.0 ) ) + ( nodeVar9 * -1.0 ) ) + nodeVar13 ) + ( ( ( ( nodeVar18.x * 0.2126 ) + ( nodeVar18.y * 0.7152 ) ) + ( nodeVar18.z * 0.0722 ) ) * 2.0 ) ) + nodeVar15 );
	nodeVar20 = clamp( ( sqrt( ( ( nodeVar16 * nodeVar16 ) + ( nodeVar19 * nodeVar19 ) ) ) * knobs.strength ), 0.0, 1.0 );

	if ( ( nodeVar20 > knobs.threshold ) ) {

		nodeVar3 = nodeVar20;

	} else {

		nodeVar3 = 0.0;

	}

	nodeVar21 = vec4<f32>( mix( nodeVar2.xyz, vec3<f32>( 1.0, 1.0, 1.0 ), mix( nodeVar3, ( 1.0 - nodeVar3 ), (1 * knobs.invert + 0) ) ), 1.0 );
	nodeVar22 = vec3<f32>( nodeVar21.x, nodeVar21.y, nodeVar21.z );
	nodeVar23 = ( ( ( nodeVar22.x * 0.2126 ) + ( nodeVar22.y * 0.7152 ) ) + ( nodeVar22.z * 0.0722 ) );
	nodeVar24 = mix( vec3<f32>( nodeVar23, nodeVar23, nodeVar23 ), nodeVar22, f32(1.0) );
	nodeVar25 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar24.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar24.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar24.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar24.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar24.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar24.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar24.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar24.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar24.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar21.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar25.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar25.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar26 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar26;

	// result

	output.color = nodeVar26;

	output.color = to_shelf(output.color);
	return output;

}

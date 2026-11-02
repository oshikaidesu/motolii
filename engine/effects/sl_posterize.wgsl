// Posterize: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Flattens the image into a few bands of color.
// --track@levels:Levels,2,16,5,1
// --track@gamma:Gamma,0.4,2.5,1,0.01
// --check@mode:Mode,0
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
  mode: f32,
  gamma: f32,
  levels: f32,
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
var<private> nodeVar1 : f32;
var<private> nodeVar2 : bool;
var<private> nodeVar3 : vec3<f32>;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : f32;
var<private> nodeVar7 : vec3<f32>;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : vec3<f32>;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : vec3<f32>;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : vec3<f32>;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec3<f32>;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : vec4<f32>;
var<private> nodeVar24 : vec3<f32>;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : vec3<f32>;
var<private> nodeVar27 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar28 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar2 = ( (1 * knobs.mode + 0) > 0.5 );

	if ( nodeVar2 ) {

		nodeVar3 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar4 = dot( nodeVar3, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		nodeVar5 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar6 = ( pow( ( floor( ( ( pow( clamp( nodeVar4, 0.0, 1.0 ), knobs.gamma ) * nodeVar5 ) + 0.5 ) ) / nodeVar5 ), f32(1.0) ) / max( nodeVar4, 0.001 ) );
		nodeVar1 = clamp( vec3<f32>( ( nodeVar3.x * nodeVar6 ), ( nodeVar3.y * nodeVar6 ), ( nodeVar3.z * nodeVar6 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).x;

	} else {

		nodeVar7 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar8 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar1 = vec3<f32>( pow( ( floor( ( ( pow( clamp( nodeVar7.x, 0.0, 1.0 ), knobs.gamma ) * nodeVar8 ) + 0.5 ) ) / nodeVar8 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar7.y, 0.0, 1.0 ), knobs.gamma ) * nodeVar8 ) + 0.5 ) ) / nodeVar8 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar7.z, 0.0, 1.0 ), knobs.gamma ) * nodeVar8 ) + 0.5 ) ) / nodeVar8 ), f32(1.0) ) ).x;

	}


	if ( nodeVar2 ) {

		nodeVar10 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar11 = dot( nodeVar10, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		nodeVar12 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar13 = ( pow( ( floor( ( ( pow( clamp( nodeVar11, 0.0, 1.0 ), knobs.gamma ) * nodeVar12 ) + 0.5 ) ) / nodeVar12 ), f32(1.0) ) / max( nodeVar11, 0.001 ) );
		nodeVar9 = clamp( vec3<f32>( ( nodeVar10.x * nodeVar13 ), ( nodeVar10.y * nodeVar13 ), ( nodeVar10.z * nodeVar13 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).y;

	} else {

		nodeVar14 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar15 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar9 = vec3<f32>( pow( ( floor( ( ( pow( clamp( nodeVar14.x, 0.0, 1.0 ), knobs.gamma ) * nodeVar15 ) + 0.5 ) ) / nodeVar15 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar14.y, 0.0, 1.0 ), knobs.gamma ) * nodeVar15 ) + 0.5 ) ) / nodeVar15 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar14.z, 0.0, 1.0 ), knobs.gamma ) * nodeVar15 ) + 0.5 ) ) / nodeVar15 ), f32(1.0) ) ).y;

	}


	if ( nodeVar2 ) {

		nodeVar17 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar18 = dot( nodeVar17, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		nodeVar19 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar20 = ( pow( ( floor( ( ( pow( clamp( nodeVar18, 0.0, 1.0 ), knobs.gamma ) * nodeVar19 ) + 0.5 ) ) / nodeVar19 ), f32(1.0) ) / max( nodeVar18, 0.001 ) );
		nodeVar16 = clamp( vec3<f32>( ( nodeVar17.x * nodeVar20 ), ( nodeVar17.y * nodeVar20 ), ( nodeVar17.z * nodeVar20 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).z;

	} else {

		nodeVar21 = vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z );
		nodeVar22 = max( ( knobs.levels - 1.0 ), 1.0 );
		nodeVar16 = vec3<f32>( pow( ( floor( ( ( pow( clamp( nodeVar21.x, 0.0, 1.0 ), knobs.gamma ) * nodeVar22 ) + 0.5 ) ) / nodeVar22 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar21.y, 0.0, 1.0 ), knobs.gamma ) * nodeVar22 ) + 0.5 ) ) / nodeVar22 ), f32(1.0) ), pow( ( floor( ( ( pow( clamp( nodeVar21.z, 0.0, 1.0 ), knobs.gamma ) * nodeVar22 ) + 0.5 ) ) / nodeVar22 ), f32(1.0) ) ).z;

	}

	nodeVar23 = vec4<f32>( vec3<f32>( nodeVar1, nodeVar9, nodeVar16 ), 1.0 );
	nodeVar24 = vec3<f32>( nodeVar23.x, nodeVar23.y, nodeVar23.z );
	nodeVar25 = ( ( ( nodeVar24.x * 0.2126 ) + ( nodeVar24.y * 0.7152 ) ) + ( nodeVar24.z * 0.0722 ) );
	nodeVar26 = mix( vec3<f32>( nodeVar25, nodeVar25, nodeVar25 ), nodeVar24, f32(1.0) );
	nodeVar27 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar26.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar26.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar26.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar26.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar26.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar26.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar26.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar26.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar26.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar23.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar27.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar27.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar28 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar28;

	// result

	output.color = nodeVar28;

	output.color = to_shelf(output.color);
	return output;

}

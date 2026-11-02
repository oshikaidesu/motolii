// Dot Grid: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:A precise grid of dots locked to the artboard, each sized by the tone beneath it.
// --check@shape:Shape,0
// --track@spacing:Spacing,3,120,12,1
// --track@minDot:Min Dot,0,1,0.16,0.01
// --track@maxDot:Max Dot,0,1.5,1.08,0.01
// --track@level:Level,0,1,0.62,0.01
// --track@contrast:Contrast,0.2,4,2.4,0.01
// --track@softness:Softness,0,4,0.9,0.01
// --check@invert:Invert,0
// --check@inkMode:Ink,0
// --track@inkColor_x:Ink Color r,0,1,0.0069954101845983935,0.001
// --track@inkColor_y:Ink Color g,0,1,0.0069954101845983935,0.001
// --track@inkColor_z:Ink Color b,0,1,0.0069954101845983935,0.001
// --track@backgroundColor_x:Background r,0,1,0.6938717612856897,0.001
// --track@backgroundColor_y:Background g,0,1,0.8069522576650873,0.001
// --track@backgroundColor_z:Background b,0,1,0.8631572134510892,0.001
// --track@underlay:Underlay,0,1,0.45,0.01
// --track@underlayBlur:Underlay Blur,0,120,28,1
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
  spacing: f32,
  softness: f32,
  minDot: f32,
  maxDot: f32,
  invert: f32,
  level: f32,
  contrast: f32,
  shape: f32,
  backgroundColor: vec3<f32>,
  underlay: f32,
  underlayBlur: f32,
  inkMode: f32,
  inkColor: vec3<f32>,
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
var<private> nodeVar4 : vec2<f32>;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec2<f32>;
var<private> nodeVar8 : vec2<f32>;
var<private> nodeVar9 : vec4<f32>;
var<private> nodeVar10 : vec3<f32>;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : vec4<f32>;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : vec4<f32>;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec4<f32>;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : vec4<f32>;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : vec4<f32>;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : f32;
var<private> nodeVar32 : vec4<f32>;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : vec4<f32>;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : vec4<f32>;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : f32;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : vec2<f32>;
var<private> nodeVar43 : f32;
var<private> nodeVar44 : vec3<f32>;
var<private> nodeVar45 : vec2<f32>;
var<private> nodeVar46 : vec4<f32>;
var<private> nodeVar47 : vec4<f32>;
var<private> nodeVar48 : vec4<f32>;
var<private> nodeVar49 : vec4<f32>;
var<private> nodeVar50 : vec4<f32>;
var<private> nodeVar51 : vec4<f32>;
var<private> nodeVar52 : vec4<f32>;
var<private> nodeVar53 : vec4<f32>;
var<private> nodeVar54 : vec4<f32>;
var<private> nodeVar55 : vec4<f32>;
var<private> nodeVar56 : vec4<f32>;
var<private> nodeVar57 : vec4<f32>;
var<private> nodeVar58 : vec3<f32>;
var<private> nodeVar59 : vec4<f32>;
var<private> nodeVar60 : vec3<f32>;
var<private> nodeVar61 : f32;
var<private> nodeVar62 : vec3<f32>;
var<private> nodeVar63 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar64 : vec4<f32>;

// codes
fn tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
	nodeVar3 = ( nodeVar1 * nodeVar2 );
	nodeVar4 = ( vec2<f32>( tsl_mod_float( nodeVar2.x, knobs.spacing ), tsl_mod_float( nodeVar2.y, knobs.spacing ) ) * vec2<f32>( 0.5 ) );
	nodeVar5 = ( ( ( floor( ( ( nodeVar3 - nodeVar4 ) / vec2<f32>( knobs.spacing ) ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>( knobs.spacing ) ) + nodeVar4 );
	nodeVar6 = vec2<f32>( ( 1.0 / nodeVar2.x ), ( 1.0 / nodeVar2.y ) );
	nodeVar7 = ( nodeVar5 * nodeVar6 );
	nodeVar8 = ( ( nodeVar6 * vec2<f32>( knobs.spacing ) ) * vec2<f32>( knobs.softness ) );
	nodeVar9 = picture_read( ( nodeVar7 + ( vec2<f32>( 0.0, 0.0 ) * nodeVar8 ) ) );
	nodeVar10 = vec3<f32>( nodeVar9.x, nodeVar9.y, nodeVar9.z );

	if ( ( (1 * knobs.invert + 0) > 0.5 ) ) {

		nodeVar13 = clamp( dot( vec3<f32>( nodeVar9.x, nodeVar9.y, nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar13 <= 0.0031308 ) ) {

			nodeVar12 = ( nodeVar13 * 12.92 );

		} else {

			nodeVar12 = ( ( pow( nodeVar13, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar15 = picture_read( ( nodeVar7 + ( vec2<f32>( 1.0, 0.0 ) * nodeVar8 ) ) );
		nodeVar16 = clamp( dot( vec3<f32>( nodeVar15.x, nodeVar15.y, nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar16 <= 0.0031308 ) ) {

			nodeVar14 = ( nodeVar16 * 12.92 );

		} else {

			nodeVar14 = ( ( pow( nodeVar16, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar18 = picture_read( ( nodeVar7 + ( vec2<f32>( -1.0, 0.0 ) * nodeVar8 ) ) );
		nodeVar19 = clamp( dot( vec3<f32>( nodeVar18.x, nodeVar18.y, nodeVar18.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar19 <= 0.0031308 ) ) {

			nodeVar17 = ( nodeVar19 * 12.92 );

		} else {

			nodeVar17 = ( ( pow( nodeVar19, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar21 = picture_read( ( nodeVar7 + ( vec2<f32>( 0.0, 1.0 ) * nodeVar8 ) ) );
		nodeVar22 = clamp( dot( vec3<f32>( nodeVar21.x, nodeVar21.y, nodeVar21.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar22 <= 0.0031308 ) ) {

			nodeVar20 = ( nodeVar22 * 12.92 );

		} else {

			nodeVar20 = ( ( pow( nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar24 = picture_read( ( nodeVar7 + ( vec2<f32>( 0.0, -1.0 ) * nodeVar8 ) ) );
		nodeVar25 = clamp( dot( vec3<f32>( nodeVar24.x, nodeVar24.y, nodeVar24.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar25 <= 0.0031308 ) ) {

			nodeVar23 = ( nodeVar25 * 12.92 );

		} else {

			nodeVar23 = ( ( pow( nodeVar25, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar11 = ( ( ( ( ( ( 0.0 + nodeVar12 ) + nodeVar14 ) + nodeVar17 ) + nodeVar20 ) + nodeVar23 ) / 5.0 );

	} else {

		nodeVar27 = clamp( dot( vec3<f32>( nodeVar9.x, nodeVar9.y, nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar27 <= 0.0031308 ) ) {

			nodeVar26 = ( nodeVar27 * 12.92 );

		} else {

			nodeVar26 = ( ( pow( nodeVar27, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar29 = picture_read( ( nodeVar7 + ( vec2<f32>( 1.0, 0.0 ) * nodeVar8 ) ) );
		nodeVar30 = clamp( dot( vec3<f32>( nodeVar29.x, nodeVar29.y, nodeVar29.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar30 <= 0.0031308 ) ) {

			nodeVar28 = ( nodeVar30 * 12.92 );

		} else {

			nodeVar28 = ( ( pow( nodeVar30, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar32 = picture_read( ( nodeVar7 + ( vec2<f32>( -1.0, 0.0 ) * nodeVar8 ) ) );
		nodeVar33 = clamp( dot( vec3<f32>( nodeVar32.x, nodeVar32.y, nodeVar32.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar33 <= 0.0031308 ) ) {

			nodeVar31 = ( nodeVar33 * 12.92 );

		} else {

			nodeVar31 = ( ( pow( nodeVar33, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar35 = picture_read( ( nodeVar7 + ( vec2<f32>( 0.0, 1.0 ) * nodeVar8 ) ) );
		nodeVar36 = clamp( dot( vec3<f32>( nodeVar35.x, nodeVar35.y, nodeVar35.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar36 <= 0.0031308 ) ) {

			nodeVar34 = ( nodeVar36 * 12.92 );

		} else {

			nodeVar34 = ( ( pow( nodeVar36, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar38 = picture_read( ( nodeVar7 + ( vec2<f32>( 0.0, -1.0 ) * nodeVar8 ) ) );
		nodeVar39 = clamp( dot( vec3<f32>( nodeVar38.x, nodeVar38.y, nodeVar38.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar39 <= 0.0031308 ) ) {

			nodeVar37 = ( nodeVar39 * 12.92 );

		} else {

			nodeVar37 = ( ( pow( nodeVar39, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar11 = ( 1.0 - ( ( ( ( ( ( 0.0 + nodeVar26 ) + nodeVar28 ) + nodeVar31 ) + nodeVar34 ) + nodeVar37 ) / 5.0 ) );

	}

	nodeVar40 = ( ( mix( knobs.minDot, knobs.maxDot, clamp( ( ( ( nodeVar11 - knobs.level ) * knobs.contrast ) + 0.5 ), 0.0, 1.0 ) ) * knobs.spacing ) * 0.5 );

	if ( ( (1 * knobs.shape + 0) > 0.5 ) ) {

		nodeVar42 = ( nodeVar3 - nodeVar5 );
		nodeVar41 = max( abs( nodeVar42.x ), abs( nodeVar42.y ) );

	} else {

		nodeVar41 = length( ( nodeVar3 - nodeVar5 ) );

	}

	nodeVar43 = ( ( 1.0 - smoothstep( ( nodeVar40 - 0.6 ), ( nodeVar40 + 0.6 ), nodeVar41 ) ) * smoothstep( 0.05, 0.35, nodeVar40 ) );
	nodeVar44 = knobs.backgroundColor;

	if ( ( knobs.underlay > 0.0 ) ) {

		nodeVar45 = ( nodeVar6 * vec2<f32>( knobs.underlayBlur ) );
		nodeVar46 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.2041241452319315, 0.0 ) * nodeVar45 ) ) );
		nodeVar47 = picture_read( ( nodeVar1 + ( vec2<f32>( -0.26069926696254825, 0.23882188384900999 ) * nodeVar45 ) ) );
		nodeVar48 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.03990420127809657, -0.45468779184588903 ) * nodeVar45 ) ) );
		nodeVar49 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.3285945407365531, 0.4285933905985957 ) * nodeVar45 ) ) );
		nodeVar50 = picture_read( ( nodeVar1 + ( vec2<f32>( -0.603011395465104, -0.10666422520802309 ) * nodeVar45 ) ) );
		nodeVar51 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.5712250349309043, -0.36336660936514303 ) * nodeVar45 ) ) );
		nodeVar52 = picture_read( ( nodeVar1 + ( vec2<f32>( -0.19106359506326742, 0.7107470501579071 ) * nodeVar45 ) ) );
		nodeVar53 = picture_read( ( nodeVar1 + ( vec2<f32>( -0.36437899691644066, -0.7015895855884469 ) * nodeVar45 ) ) );
		nodeVar54 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.7905566725778416, 0.2887100288801633 ) * nodeVar45 ) ) );
		nodeVar55 = picture_read( ( nodeVar1 + ( vec2<f32>( -0.8224424862333952, 0.3394923025709098 ) * nodeVar45 ) ) );
		nodeVar56 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.3964716245563916, -0.8472368328405084 ) * nodeVar45 ) ) );
		nodeVar57 = picture_read( ( nodeVar1 + ( vec2<f32>( 0.2929824457833262, 0.9340742046519397 ) * nodeVar45 ) ) );
		nodeVar44 = mix( knobs.backgroundColor, ( ( ( ( ( ( ( ( ( ( ( ( ( vec3<f32>( 0.0, 0.0, 0.0 ) + vec3<f32>( nodeVar46.x, nodeVar46.y, nodeVar46.z ) ) + vec3<f32>( nodeVar47.x, nodeVar47.y, nodeVar47.z ) ) + vec3<f32>( nodeVar48.x, nodeVar48.y, nodeVar48.z ) ) + vec3<f32>( nodeVar49.x, nodeVar49.y, nodeVar49.z ) ) + vec3<f32>( nodeVar50.x, nodeVar50.y, nodeVar50.z ) ) + vec3<f32>( nodeVar51.x, nodeVar51.y, nodeVar51.z ) ) + vec3<f32>( nodeVar52.x, nodeVar52.y, nodeVar52.z ) ) + vec3<f32>( nodeVar53.x, nodeVar53.y, nodeVar53.z ) ) + vec3<f32>( nodeVar54.x, nodeVar54.y, nodeVar54.z ) ) + vec3<f32>( nodeVar55.x, nodeVar55.y, nodeVar55.z ) ) + vec3<f32>( nodeVar56.x, nodeVar56.y, nodeVar56.z ) ) + vec3<f32>( nodeVar57.x, nodeVar57.y, nodeVar57.z ) ) / vec3<f32>( 12.0 ) ), knobs.underlay );
		

	}


	if ( ( (1 * knobs.inkMode + 0) > 0.5 ) ) {

		nodeVar58 = nodeVar10;

	} else {

		nodeVar58 = knobs.inkColor;

	}

	nodeVar59 = vec4<f32>( mix( nodeVar44, nodeVar58, nodeVar43 ), 1.0 );
	nodeVar60 = vec3<f32>( nodeVar59.x, nodeVar59.y, nodeVar59.z );
	nodeVar61 = ( ( ( nodeVar60.x * 0.2126 ) + ( nodeVar60.y * 0.7152 ) ) + ( nodeVar60.z * 0.0722 ) );
	nodeVar62 = mix( vec3<f32>( nodeVar61, nodeVar61, nodeVar61 ), nodeVar60, f32(1.0) );
	nodeVar63 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar62.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar62.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar62.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar62.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar62.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar62.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar62.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar62.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar62.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar59.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar63.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar63.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar64 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar64;

	// result

	output.color = nodeVar64;

	output.color = to_shelf(output.color);
	return output;

}

// Dot Grid: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
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
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  shape: f32,
  spacing: f32,
  minDot: f32,
  maxDot: f32,
  level: f32,
  contrast: f32,
  softness: f32,
  invert: f32,
  inkMode: f32,
  inkColor: vec3<f32>,
  backgroundColor: vec3<f32>,
  underlay: f32,
  underlayBlur: f32,
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
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec3<f32>;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec4<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : vec4<f32>;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec4<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec4<f32>;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : vec2<f32>;
var<private> p0_nodeVar46 : vec4<f32>;
var<private> p0_nodeVar47 : vec4<f32>;
var<private> p0_nodeVar48 : vec4<f32>;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : vec4<f32>;
var<private> p0_nodeVar51 : vec4<f32>;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : vec4<f32>;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : vec4<f32>;
var<private> p0_nodeVar56 : vec4<f32>;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : vec3<f32>;
var<private> p0_nodeVar59 : vec4<f32>;
var<private> p0_nodeVar60 : vec3<f32>;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : vec3<f32>;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar64 : vec4<f32>;

// codes
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar3 = ( p0_nodeVar1 * p0_nodeVar2 );
	p0_nodeVar4 = ( vec2<f32>( p0_tsl_mod_float( p0_nodeVar2.x, f32(knobs.spacing) ), p0_tsl_mod_float( p0_nodeVar2.y, f32(knobs.spacing) ) ) * vec2<f32>( 0.5 ) );
	p0_nodeVar5 = ( ( ( floor( ( ( p0_nodeVar3 - p0_nodeVar4 ) / vec2<f32>( f32(knobs.spacing) ) ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>( f32(knobs.spacing) ) ) + p0_nodeVar4 );
	p0_nodeVar6 = vec2<f32>( ( 1.0 / p0_nodeVar2.x ), ( 1.0 / p0_nodeVar2.y ) );
	p0_nodeVar7 = ( p0_nodeVar5 * p0_nodeVar6 );
	p0_nodeVar8 = ( ( p0_nodeVar6 * vec2<f32>( f32(knobs.spacing) ) ) * vec2<f32>( f32(knobs.softness) ) );
	p0_nodeVar9 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 0.0, 0.0 ) * p0_nodeVar8 ) ) );
	p0_nodeVar10 = vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z );

	if ( ( f32(knobs.invert) > 0.5 ) ) {

		p0_nodeVar13 = clamp( dot( vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar13 <= 0.0031308 ) ) {

			p0_nodeVar12 = ( p0_nodeVar13 * 12.92 );

		} else {

			p0_nodeVar12 = ( ( pow( p0_nodeVar13, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar15 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 1.0, 0.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar16 = clamp( dot( vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar16 <= 0.0031308 ) ) {

			p0_nodeVar14 = ( p0_nodeVar16 * 12.92 );

		} else {

			p0_nodeVar14 = ( ( pow( p0_nodeVar16, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar18 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( -1.0, 0.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar19 = clamp( dot( vec3<f32>( p0_nodeVar18.x, p0_nodeVar18.y, p0_nodeVar18.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar19 <= 0.0031308 ) ) {

			p0_nodeVar17 = ( p0_nodeVar19 * 12.92 );

		} else {

			p0_nodeVar17 = ( ( pow( p0_nodeVar19, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar21 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 0.0, 1.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar22 = clamp( dot( vec3<f32>( p0_nodeVar21.x, p0_nodeVar21.y, p0_nodeVar21.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar22 <= 0.0031308 ) ) {

			p0_nodeVar20 = ( p0_nodeVar22 * 12.92 );

		} else {

			p0_nodeVar20 = ( ( pow( p0_nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar24 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 0.0, -1.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar25 = clamp( dot( vec3<f32>( p0_nodeVar24.x, p0_nodeVar24.y, p0_nodeVar24.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar25 <= 0.0031308 ) ) {

			p0_nodeVar23 = ( p0_nodeVar25 * 12.92 );

		} else {

			p0_nodeVar23 = ( ( pow( p0_nodeVar25, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar11 = ( ( ( ( ( ( 0.0 + p0_nodeVar12 ) + p0_nodeVar14 ) + p0_nodeVar17 ) + p0_nodeVar20 ) + p0_nodeVar23 ) / 5.0 );

	} else {

		p0_nodeVar27 = clamp( dot( vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar27 <= 0.0031308 ) ) {

			p0_nodeVar26 = ( p0_nodeVar27 * 12.92 );

		} else {

			p0_nodeVar26 = ( ( pow( p0_nodeVar27, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar29 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 1.0, 0.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar30 = clamp( dot( vec3<f32>( p0_nodeVar29.x, p0_nodeVar29.y, p0_nodeVar29.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar30 <= 0.0031308 ) ) {

			p0_nodeVar28 = ( p0_nodeVar30 * 12.92 );

		} else {

			p0_nodeVar28 = ( ( pow( p0_nodeVar30, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar32 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( -1.0, 0.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar33 = clamp( dot( vec3<f32>( p0_nodeVar32.x, p0_nodeVar32.y, p0_nodeVar32.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar33 <= 0.0031308 ) ) {

			p0_nodeVar31 = ( p0_nodeVar33 * 12.92 );

		} else {

			p0_nodeVar31 = ( ( pow( p0_nodeVar33, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar35 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 0.0, 1.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar36 = clamp( dot( vec3<f32>( p0_nodeVar35.x, p0_nodeVar35.y, p0_nodeVar35.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar36 <= 0.0031308 ) ) {

			p0_nodeVar34 = ( p0_nodeVar36 * 12.92 );

		} else {

			p0_nodeVar34 = ( ( pow( p0_nodeVar36, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar38 = picture_read( ( p0_nodeVar7 + ( vec2<f32>( 0.0, -1.0 ) * p0_nodeVar8 ) ) );
		p0_nodeVar39 = clamp( dot( vec3<f32>( p0_nodeVar38.x, p0_nodeVar38.y, p0_nodeVar38.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar39 <= 0.0031308 ) ) {

			p0_nodeVar37 = ( p0_nodeVar39 * 12.92 );

		} else {

			p0_nodeVar37 = ( ( pow( p0_nodeVar39, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar11 = ( 1.0 - ( ( ( ( ( ( 0.0 + p0_nodeVar26 ) + p0_nodeVar28 ) + p0_nodeVar31 ) + p0_nodeVar34 ) + p0_nodeVar37 ) / 5.0 ) );

	}

	p0_nodeVar40 = ( ( mix( f32(knobs.minDot), f32(knobs.maxDot), clamp( ( ( ( p0_nodeVar11 - f32(knobs.level) ) * f32(knobs.contrast) ) + 0.5 ), 0.0, 1.0 ) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) > 0.5 ) ) {

		p0_nodeVar42 = ( p0_nodeVar3 - p0_nodeVar5 );
		p0_nodeVar41 = max( abs( p0_nodeVar42.x ), abs( p0_nodeVar42.y ) );

	} else {

		p0_nodeVar41 = length( ( p0_nodeVar3 - p0_nodeVar5 ) );

	}

	p0_nodeVar43 = ( ( 1.0 - smoothstep( ( p0_nodeVar40 - 0.6 ), ( p0_nodeVar40 + 0.6 ), p0_nodeVar41 ) ) * smoothstep( 0.05, 0.35, p0_nodeVar40 ) );
	p0_nodeVar44 = vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z);

	if ( ( f32(knobs.underlay) > 0.0 ) ) {

		p0_nodeVar45 = ( p0_nodeVar6 * vec2<f32>( f32(knobs.underlayBlur) ) );
		p0_nodeVar46 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.2041241452319315, 0.0 ) * p0_nodeVar45 ) ) );
		p0_nodeVar47 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( -0.26069926696254825, 0.23882188384900999 ) * p0_nodeVar45 ) ) );
		p0_nodeVar48 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.03990420127809657, -0.45468779184588903 ) * p0_nodeVar45 ) ) );
		p0_nodeVar49 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.3285945407365531, 0.4285933905985957 ) * p0_nodeVar45 ) ) );
		p0_nodeVar50 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( -0.603011395465104, -0.10666422520802309 ) * p0_nodeVar45 ) ) );
		p0_nodeVar51 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.5712250349309043, -0.36336660936514303 ) * p0_nodeVar45 ) ) );
		p0_nodeVar52 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( -0.19106359506326742, 0.7107470501579071 ) * p0_nodeVar45 ) ) );
		p0_nodeVar53 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( -0.36437899691644066, -0.7015895855884469 ) * p0_nodeVar45 ) ) );
		p0_nodeVar54 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.7905566725778416, 0.2887100288801633 ) * p0_nodeVar45 ) ) );
		p0_nodeVar55 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( -0.8224424862333952, 0.3394923025709098 ) * p0_nodeVar45 ) ) );
		p0_nodeVar56 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.3964716245563916, -0.8472368328405084 ) * p0_nodeVar45 ) ) );
		p0_nodeVar57 = picture_read( ( p0_nodeVar1 + ( vec2<f32>( 0.2929824457833262, 0.9340742046519397 ) * p0_nodeVar45 ) ) );
		p0_nodeVar44 = mix( vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z), ( ( ( ( ( ( ( ( ( ( ( ( ( vec3<f32>( 0.0, 0.0, 0.0 ) + vec3<f32>( p0_nodeVar46.x, p0_nodeVar46.y, p0_nodeVar46.z ) ) + vec3<f32>( p0_nodeVar47.x, p0_nodeVar47.y, p0_nodeVar47.z ) ) + vec3<f32>( p0_nodeVar48.x, p0_nodeVar48.y, p0_nodeVar48.z ) ) + vec3<f32>( p0_nodeVar49.x, p0_nodeVar49.y, p0_nodeVar49.z ) ) + vec3<f32>( p0_nodeVar50.x, p0_nodeVar50.y, p0_nodeVar50.z ) ) + vec3<f32>( p0_nodeVar51.x, p0_nodeVar51.y, p0_nodeVar51.z ) ) + vec3<f32>( p0_nodeVar52.x, p0_nodeVar52.y, p0_nodeVar52.z ) ) + vec3<f32>( p0_nodeVar53.x, p0_nodeVar53.y, p0_nodeVar53.z ) ) + vec3<f32>( p0_nodeVar54.x, p0_nodeVar54.y, p0_nodeVar54.z ) ) + vec3<f32>( p0_nodeVar55.x, p0_nodeVar55.y, p0_nodeVar55.z ) ) + vec3<f32>( p0_nodeVar56.x, p0_nodeVar56.y, p0_nodeVar56.z ) ) + vec3<f32>( p0_nodeVar57.x, p0_nodeVar57.y, p0_nodeVar57.z ) ) / vec3<f32>( 12.0 ) ), f32(knobs.underlay) );
		

	}


	if ( ( f32(knobs.inkMode) > 0.5 ) ) {

		p0_nodeVar58 = p0_nodeVar10;

	} else {

		p0_nodeVar58 = vec3<f32>(knobs.inkColor.x, knobs.inkColor.y, knobs.inkColor.z);

	}

	p0_nodeVar59 = vec4<f32>( mix( p0_nodeVar44, p0_nodeVar58, p0_nodeVar43 ), 1.0 );
	p0_nodeVar60 = vec3<f32>( p0_nodeVar59.x, p0_nodeVar59.y, p0_nodeVar59.z );
	p0_nodeVar61 = ( ( ( p0_nodeVar60.x * 0.2126 ) + ( p0_nodeVar60.y * 0.7152 ) ) + ( p0_nodeVar60.z * 0.0722 ) );
	p0_nodeVar62 = mix( vec3<f32>( p0_nodeVar61, p0_nodeVar61, p0_nodeVar61 ), p0_nodeVar60, f32(1.0) );
	p0_nodeVar63 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar62.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar62.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar62.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar62.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar62.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar62.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar62.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar62.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar62.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar59.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar63.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar63.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar64 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar64;

	// result

	p0_output.color = p0_nodeVar64;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

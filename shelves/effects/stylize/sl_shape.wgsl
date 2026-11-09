// Shape: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:A flat color silhouette: ellipse, rectangle, triangle, polygon, star, ring or blades. Blend it over photography or mask it.
// --track@shape:Shape,0,7,0,1
// --check@svgColorMode:SVG Colors,0
// --track@cornerRadius:Corner Radius,0,1,0.1,0.01
// --track@sides:Sides,3,12,6,1
// --track@points:Points,3,12,5,1
// --track@innerRadius:Inner Radius,0.1,0.9,0.45,0.01
// --track@thickness:Thickness,0.05,1,0.3,0.01
// --track@blades:Blades,2,8,4,1
// --track@twist:Twist,-2,2,0.6,0.01
// --track@bladeWidth:Blade Width,0.1,1,0.7,0.01
// --track@hub:Hub,0,0.6,0.12,0.01
// --track@rotation:Rotation,-180,180,0,1
// --track@color_x:Color r,0,1,1,0.001
// --track@color_y:Color g,0,1,0.06847816983662762,0.001
// --track@color_z:Color b,0,1,0.023153366173251363,0.001
// --track@outline:Outline,0,0.3,0,0.005
// --track@softness:Softness,0,0.2,0,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  shape: f32,
  svgColorMode: f32,
  cornerRadius: f32,
  sides: f32,
  points: f32,
  innerRadius: f32,
  thickness: f32,
  blades: f32,
  twist: f32,
  bladeWidth: f32,
  hub: f32,
  rotation: f32,
  color: vec3<f32>,
  outline: f32,
  softness: f32,
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
fn own0_read(uv: vec2f) -> vec4f { return vec4f(0.0,0.0,0.0,1.0); }
fn own0_read_load(p: vec2i, level: u32) -> vec4f { return own0_read((vec2f(p) + 0.5) / vec2f(1.0, 1.0)); }
fn own0_read_level(uv: vec2f, level: f32) -> vec4f { return own0_read(uv); }
fn own1_read(uv: vec2f) -> vec4f { return vec4f(0.0,0.0,0.0,1.0); }
fn own1_read_load(p: vec2i, level: u32) -> vec4f { return own1_read((vec2f(p) + 0.5) / vec2f(1.0, 1.0)); }
fn own1_read_level(uv: vec2f, level: f32) -> vec4f { return own1_read(uv); }

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec3<f32>;
var<private> p0_nodeVar1 : vec4<f32>;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec3<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : vec2<f32>;
var<private> p0_nodeVar33 : vec2<f32>;
var<private> p0_nodeVar34 : vec4<f32>;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : vec2<f32>;
var<private> p0_nodeVar37 : vec4<f32>;
var<private> p0_nodeVar38 : vec4<f32>;
var<private> p0_nodeVar39 : vec4<f32>;
var<private> p0_nodeVar40 : vec4<f32>;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : vec4<f32>;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : bool;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : vec3<f32>;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : vec3<f32>;
var<private> p0_nodeVar53 : vec4<f32>;
var<private> p0_nodeVar54 : vec2<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : vec2<f32>;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : vec2<f32>;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : vec2<f32>;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : vec3<f32>;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : vec2<f32>;
var<private> p0_nodeVar84 : vec2<f32>;
var<private> p0_nodeVar85 : vec2<f32>;
var<private> p0_nodeVar86 : vec4<f32>;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : vec2<f32>;
var<private> p0_nodeVar89 : vec4<f32>;
var<private> p0_nodeVar90 : vec4<f32>;
var<private> p0_nodeVar91 : vec4<f32>;
var<private> p0_nodeVar92 : vec4<f32>;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : vec2<f32>;
var<private> p0_nodeVar95 : vec4<f32>;
var<private> p0_nodeVar96 : vec3<f32>;
var<private> p0_nodeVar97 : bool;
var<private> p0_nodeVar98 : f32;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : vec4<f32>;
var<private> p0_nodeVar102 : vec3<f32>;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : vec3<f32>;
var<private> p0_nodeVar105 : vec4<f32>;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : f32;
var<private> p0_nodeVar108 : f32;
var<private> p0_nodeVar109 : vec2<f32>;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : vec2<f32>;
var<private> p0_nodeVar113 : vec2<f32>;
var<private> p0_nodeVar114 : vec2<f32>;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : f32;
var<private> p0_nodeVar119 : vec2<f32>;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : f32;
var<private> p0_nodeVar122 : f32;
var<private> p0_nodeVar123 : f32;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : f32;
var<private> p0_nodeVar126 : f32;
var<private> p0_nodeVar127 : f32;
var<private> p0_nodeVar128 : f32;
var<private> p0_nodeVar129 : f32;
var<private> p0_nodeVar130 : f32;
var<private> p0_nodeVar131 : f32;
var<private> p0_nodeVar132 : f32;
var<private> p0_nodeVar133 : f32;
var<private> p0_nodeVar134 : f32;
var<private> p0_nodeVar135 : f32;
var<private> p0_nodeVar136 : vec3<f32>;
var<private> p0_nodeVar137 : f32;
var<private> p0_nodeVar138 : vec2<f32>;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : vec2<f32>;
var<private> p0_nodeVar141 : vec4<f32>;
var<private> p0_nodeVar142 : f32;
var<private> p0_nodeVar143 : vec2<f32>;
var<private> p0_nodeVar144 : vec4<f32>;
var<private> p0_nodeVar145 : vec4<f32>;
var<private> p0_nodeVar146 : vec4<f32>;
var<private> p0_nodeVar147 : vec4<f32>;
var<private> p0_nodeVar148 : vec2<f32>;
var<private> p0_nodeVar149 : vec2<f32>;
var<private> p0_nodeVar150 : vec4<f32>;
var<private> p0_nodeVar151 : vec3<f32>;
var<private> p0_nodeVar152 : bool;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : f32;
var<private> p0_nodeVar155 : f32;
var<private> p0_nodeVar156 : vec4<f32>;
var<private> p0_nodeVar157 : vec3<f32>;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : vec3<f32>;
var<private> p0_nodeVar160 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar161 : vec4<f32>;

// codes
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar1 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );

	if ( ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) == 1.0 ) ) {

		p0_nodeVar2 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) - vec2<f32>(0.0, 0.0) );
		p0_nodeVar3 = cos( f32((0.017453292519943295 * knobs.rotation + 0)) );
		p0_nodeVar4 = sin( f32((0.017453292519943295 * knobs.rotation + 0)) );
		p0_nodeVar5 = vec2<f32>( ( ( p0_nodeVar2.x * p0_nodeVar3 ) + ( p0_nodeVar2.y * p0_nodeVar4 ) ), ( ( p0_nodeVar2.y * p0_nodeVar3 ) - ( p0_nodeVar2.x * p0_nodeVar4 ) ) );
		p0_nodeVar6 = ( vec2<f32>(0.6, 0.6) * vec2<f32>( 0.5 ) );
		p0_nodeVar7 = ( p0_nodeVar5 / p0_nodeVar6 );
		p0_nodeVar8 = length( p0_nodeVar7 );
		p0_nodeVar9 = min( p0_nodeVar6.x, p0_nodeVar6.y );
		p0_nodeVar10 = ( ( p0_nodeVar8 - 1.0 ) * p0_nodeVar9 );

		if ( ( f32(knobs.shape) == 1.0 ) ) {

			p0_nodeVar11 = ( f32(knobs.cornerRadius) * p0_nodeVar9 );
			p0_nodeVar12 = ( ( abs( p0_nodeVar5 ) - p0_nodeVar6 ) + vec2<f32>( p0_nodeVar11 ) );
			p0_nodeVar10 = ( ( length( max( p0_nodeVar12, vec2<f32>( 0.0, 0.0 ) ) ) + min( max( p0_nodeVar12.x, p0_nodeVar12.y ), 0.0 ) ) - p0_nodeVar11 );
			

		}


		if ( ( f32(knobs.shape) == 2.0 ) ) {

			p0_nodeVar13 = ( 3.141592653589793 / 3.0 );
			p0_nodeVar15 = ( - p0_nodeVar7.y );

			if ( ( p0_nodeVar15 >= 0.0 ) ) {

				p0_nodeVar14 = atan( ( p0_nodeVar7.x / p0_nodeVar15 ) );

			} else {


				if ( ( p0_nodeVar7.x >= 0.0 ) ) {

					p0_nodeVar16 = 3.141592653589793;

				} else {

					p0_nodeVar16 = ( - 3.141592653589793 );

				}

				p0_nodeVar14 = ( atan( ( p0_nodeVar7.x / p0_nodeVar15 ) ) + p0_nodeVar16 );

			}

			p0_nodeVar10 = ( ( p0_nodeVar8 - ( cos( p0_nodeVar13 ) / cos( ( p0_tsl_mod_float( p0_nodeVar14, ( ( 2.0 * 3.141592653589793 ) / 3.0 ) ) - p0_nodeVar13 ) ) ) ) * p0_nodeVar9 );
			

		}


		if ( ( f32(knobs.shape) == 3.0 ) ) {

			p0_nodeVar17 = ( 3.141592653589793 / f32(knobs.sides) );
			p0_nodeVar19 = ( - p0_nodeVar7.y );

			if ( ( p0_nodeVar19 >= 0.0 ) ) {

				p0_nodeVar18 = atan( ( p0_nodeVar7.x / p0_nodeVar19 ) );

			} else {


				if ( ( p0_nodeVar7.x >= 0.0 ) ) {

					p0_nodeVar20 = 3.141592653589793;

				} else {

					p0_nodeVar20 = ( - 3.141592653589793 );

				}

				p0_nodeVar18 = ( atan( ( p0_nodeVar7.x / p0_nodeVar19 ) ) + p0_nodeVar20 );

			}

			p0_nodeVar10 = ( ( p0_nodeVar8 - ( cos( p0_nodeVar17 ) / cos( ( p0_tsl_mod_float( p0_nodeVar18, ( ( 2.0 * 3.141592653589793 ) / f32(knobs.sides) ) ) - p0_nodeVar17 ) ) ) ) * p0_nodeVar9 );
			

		}


		if ( ( f32(knobs.shape) == 4.0 ) ) {

			p0_nodeVar22 = ( - p0_nodeVar7.y );

			if ( ( p0_nodeVar22 >= 0.0 ) ) {

				p0_nodeVar21 = atan( ( p0_nodeVar7.x / p0_nodeVar22 ) );

			} else {


				if ( ( p0_nodeVar7.x >= 0.0 ) ) {

					p0_nodeVar23 = 3.141592653589793;

				} else {

					p0_nodeVar23 = ( - 3.141592653589793 );

				}

				p0_nodeVar21 = ( atan( ( p0_nodeVar7.x / p0_nodeVar22 ) ) + p0_nodeVar23 );

			}

			p0_nodeVar24 = ( ( 2.0 * 3.141592653589793 ) / f32(knobs.points) );
			p0_nodeVar10 = ( ( p0_nodeVar8 - ( 1.0 - ( ( 1.0 - f32(knobs.innerRadius) ) * ( abs( ( p0_tsl_mod_float( ( p0_nodeVar21 + ( p0_nodeVar24 * 0.5 ) ), p0_nodeVar24 ) - ( p0_nodeVar24 * 0.5 ) ) ) / ( p0_nodeVar24 * 0.5 ) ) ) ) ) * p0_nodeVar9 );
			

		}


		if ( ( f32(knobs.shape) == 5.0 ) ) {

			p0_nodeVar25 = ( f32(knobs.thickness) * 0.5 );
			p0_nodeVar10 = ( ( abs( ( p0_nodeVar8 - ( 1.0 - p0_nodeVar25 ) ) ) - p0_nodeVar25 ) * p0_nodeVar9 );
			

		}


		if ( ( f32(knobs.shape) == 6.0 ) ) {

			p0_nodeVar27 = ( - p0_nodeVar7.y );

			if ( ( p0_nodeVar27 >= 0.0 ) ) {

				p0_nodeVar26 = atan( ( p0_nodeVar7.x / p0_nodeVar27 ) );

			} else {


				if ( ( p0_nodeVar7.x >= 0.0 ) ) {

					p0_nodeVar28 = 3.141592653589793;

				} else {

					p0_nodeVar28 = ( - 3.141592653589793 );

				}

				p0_nodeVar26 = ( atan( ( p0_nodeVar7.x / p0_nodeVar27 ) ) + p0_nodeVar28 );

			}

			p0_nodeVar10 = ( ( p0_nodeVar8 - ( f32(knobs.hub) + ( ( 1.0 - f32(knobs.hub) ) * pow( max( cos( ( f32(knobs.blades) * ( p0_nodeVar26 + ( f32(knobs.twist) * p0_nodeVar8 ) ) ) ), 0.0 ), ( 6.0 - ( f32(knobs.bladeWidth) * 5.5 ) ) ) ) ) ) * p0_nodeVar9 );
			

		}

		p0_nodeVar29 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);
		p0_nodeVar30 = 1.0;

		if ( ( f32(knobs.shape) == 7.0 ) ) {

			p0_nodeVar10 = 1000.0;

			if ( ( f32(0.0) > 0.5 ) ) {

				p0_nodeVar31 = ( vec2<f32>(0.0, 0.0) + ( ( ( p0_nodeVar7 * vec2<f32>( 0.5 ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>(1.0, 1.0) ) );
				p0_nodeVar32 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(1.0, 1.0) );
				p0_nodeVar33 = clamp( p0_nodeVar31, p0_nodeVar32, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar32 ) );
				p0_nodeVar34 = own0_read_level( p0_nodeVar33, 0.0 );
				p0_nodeVar36 = ( vec2<f32>( 1.0, 1.0 ) / vec2<f32>(1.0, 1.0) );
				p0_nodeVar37 = own0_read_level( ( p0_nodeVar33 + vec2<f32>( p0_nodeVar36.x, 0.0 ) ), 0.0 );
				p0_nodeVar38 = own0_read_level( ( p0_nodeVar33 - vec2<f32>( p0_nodeVar36.x, 0.0 ) ), 0.0 );
				p0_nodeVar39 = own0_read_level( ( p0_nodeVar33 + vec2<f32>( 0.0, p0_nodeVar36.y ) ), 0.0 );
				p0_nodeVar40 = own0_read_level( ( p0_nodeVar33 - vec2<f32>( 0.0, p0_nodeVar36.y ) ), 0.0 );
				p0_nodeVar41 = vec2<f32>( ( p0_nodeVar37.x - p0_nodeVar38.x ), ( p0_nodeVar39.x - p0_nodeVar40.x ) );

				if ( ( length( p0_nodeVar41 ) > 0.0001 ) ) {

					p0_nodeVar35 = length( ( ( p0_nodeVar41 / vec2<f32>( max( length( p0_nodeVar41 ), 0.0001 ) ) ) * vec2<f32>( ( ( p0_nodeVar6.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar6.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) ) ) );

				} else {

					p0_nodeVar42 = vec2<f32>( ( ( p0_nodeVar6.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar6.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) );
					p0_nodeVar35 = min( p0_nodeVar42.x, p0_nodeVar42.y );

				}

				p0_nodeVar10 = ( ( p0_nodeVar34.x + length( ( ( p0_nodeVar31 - p0_nodeVar33 ) * vec2<f32>(1.0, 1.0) ) ) ) * p0_nodeVar35 );
				p0_nodeVar43 = own1_read_level( p0_nodeVar33, 0.0 );
				p0_nodeVar29 = p0_nodeVar43.xyz;
				p0_nodeVar30 = p0_nodeVar43.w;
				

			}

			

		}

		p0_nodeVar45 = ( ( ( f32(knobs.shape) == 7.0 ) && ( f32((-1 * knobs.svgColorMode + 1)) > 0.5 ) ) && ( f32(knobs.outline) <= 0.0 ) );

		if ( p0_nodeVar45 ) {

			p0_nodeVar44 = p0_nodeVar29;

		} else {

			p0_nodeVar44 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);

		}

		p0_nodeVar46 = max( f32(knobs.softness), ( f32((1.0 / knobs.resolution.y)) * 0.75 ) );

		if ( ( f32(knobs.outline) > 0.0 ) ) {

			p0_nodeVar47 = ( abs( p0_nodeVar10 ) - ( f32(knobs.outline) * 0.5 ) );

		} else {

			p0_nodeVar47 = p0_nodeVar10;

		}


		if ( p0_nodeVar45 ) {

			p0_nodeVar48 = p0_nodeVar30;

		} else {

			p0_nodeVar48 = 1.0;

		}

		p0_nodeVar49 = vec4<f32>( p0_nodeVar44, clamp( ( ( 1.0 - smoothstep( ( - p0_nodeVar46 ), p0_nodeVar46, p0_nodeVar47 ) ) * p0_nodeVar48 ), 0.0, 1.0 ) );
		p0_nodeVar50 = vec3<f32>( p0_nodeVar49.x, p0_nodeVar49.y, p0_nodeVar49.z );
		p0_nodeVar51 = ( ( ( p0_nodeVar50.x * 0.2126 ) + ( p0_nodeVar50.y * 0.7152 ) ) + ( p0_nodeVar50.z * 0.0722 ) );
		p0_nodeVar52 = mix( vec3<f32>( p0_nodeVar51, p0_nodeVar51, p0_nodeVar51 ), p0_nodeVar50, f32(1.0) );
		p0_nodeVar53 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar52.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar52.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar52.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar52.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar52.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar52.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar52.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar52.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar52.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar49.w, 0.0, 1.0 ) );
		p0_nodeVar0 = mix( p0_nodeVar1.xyz, p0_nodeVar53.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar53.w, 0.0, 1.0 ) ) );

	} else {

		p0_nodeVar54 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) - vec2<f32>(0.0, 0.0) );
		p0_nodeVar55 = cos( f32((0.017453292519943295 * knobs.rotation + 0)) );
		p0_nodeVar56 = sin( f32((0.017453292519943295 * knobs.rotation + 0)) );
		p0_nodeVar57 = vec2<f32>( ( ( p0_nodeVar54.x * p0_nodeVar55 ) + ( p0_nodeVar54.y * p0_nodeVar56 ) ), ( ( p0_nodeVar54.y * p0_nodeVar55 ) - ( p0_nodeVar54.x * p0_nodeVar56 ) ) );
		p0_nodeVar58 = ( vec2<f32>(0.6, 0.6) * vec2<f32>( 0.5 ) );
		p0_nodeVar59 = ( p0_nodeVar57 / p0_nodeVar58 );
		p0_nodeVar60 = length( p0_nodeVar59 );
		p0_nodeVar61 = min( p0_nodeVar58.x, p0_nodeVar58.y );
		p0_nodeVar62 = ( ( p0_nodeVar60 - 1.0 ) * p0_nodeVar61 );

		if ( ( f32(knobs.shape) == 1.0 ) ) {

			p0_nodeVar63 = ( f32(knobs.cornerRadius) * p0_nodeVar61 );
			p0_nodeVar64 = ( ( abs( p0_nodeVar57 ) - p0_nodeVar58 ) + vec2<f32>( p0_nodeVar63 ) );
			p0_nodeVar62 = ( ( length( max( p0_nodeVar64, vec2<f32>( 0.0, 0.0 ) ) ) + min( max( p0_nodeVar64.x, p0_nodeVar64.y ), 0.0 ) ) - p0_nodeVar63 );
			

		}


		if ( ( f32(knobs.shape) == 2.0 ) ) {

			p0_nodeVar65 = ( 3.141592653589793 / 3.0 );
			p0_nodeVar67 = ( - p0_nodeVar59.y );

			if ( ( p0_nodeVar67 >= 0.0 ) ) {

				p0_nodeVar66 = atan( ( p0_nodeVar59.x / p0_nodeVar67 ) );

			} else {


				if ( ( p0_nodeVar59.x >= 0.0 ) ) {

					p0_nodeVar68 = 3.141592653589793;

				} else {

					p0_nodeVar68 = ( - 3.141592653589793 );

				}

				p0_nodeVar66 = ( atan( ( p0_nodeVar59.x / p0_nodeVar67 ) ) + p0_nodeVar68 );

			}

			p0_nodeVar62 = ( ( p0_nodeVar60 - ( cos( p0_nodeVar65 ) / cos( ( p0_tsl_mod_float( p0_nodeVar66, ( ( 2.0 * 3.141592653589793 ) / 3.0 ) ) - p0_nodeVar65 ) ) ) ) * p0_nodeVar61 );
			

		}


		if ( ( f32(knobs.shape) == 3.0 ) ) {

			p0_nodeVar69 = ( 3.141592653589793 / f32(knobs.sides) );
			p0_nodeVar71 = ( - p0_nodeVar59.y );

			if ( ( p0_nodeVar71 >= 0.0 ) ) {

				p0_nodeVar70 = atan( ( p0_nodeVar59.x / p0_nodeVar71 ) );

			} else {


				if ( ( p0_nodeVar59.x >= 0.0 ) ) {

					p0_nodeVar72 = 3.141592653589793;

				} else {

					p0_nodeVar72 = ( - 3.141592653589793 );

				}

				p0_nodeVar70 = ( atan( ( p0_nodeVar59.x / p0_nodeVar71 ) ) + p0_nodeVar72 );

			}

			p0_nodeVar62 = ( ( p0_nodeVar60 - ( cos( p0_nodeVar69 ) / cos( ( p0_tsl_mod_float( p0_nodeVar70, ( ( 2.0 * 3.141592653589793 ) / f32(knobs.sides) ) ) - p0_nodeVar69 ) ) ) ) * p0_nodeVar61 );
			

		}


		if ( ( f32(knobs.shape) == 4.0 ) ) {

			p0_nodeVar74 = ( - p0_nodeVar59.y );

			if ( ( p0_nodeVar74 >= 0.0 ) ) {

				p0_nodeVar73 = atan( ( p0_nodeVar59.x / p0_nodeVar74 ) );

			} else {


				if ( ( p0_nodeVar59.x >= 0.0 ) ) {

					p0_nodeVar75 = 3.141592653589793;

				} else {

					p0_nodeVar75 = ( - 3.141592653589793 );

				}

				p0_nodeVar73 = ( atan( ( p0_nodeVar59.x / p0_nodeVar74 ) ) + p0_nodeVar75 );

			}

			p0_nodeVar76 = ( ( 2.0 * 3.141592653589793 ) / f32(knobs.points) );
			p0_nodeVar62 = ( ( p0_nodeVar60 - ( 1.0 - ( ( 1.0 - f32(knobs.innerRadius) ) * ( abs( ( p0_tsl_mod_float( ( p0_nodeVar73 + ( p0_nodeVar76 * 0.5 ) ), p0_nodeVar76 ) - ( p0_nodeVar76 * 0.5 ) ) ) / ( p0_nodeVar76 * 0.5 ) ) ) ) ) * p0_nodeVar61 );
			

		}


		if ( ( f32(knobs.shape) == 5.0 ) ) {

			p0_nodeVar77 = ( f32(knobs.thickness) * 0.5 );
			p0_nodeVar62 = ( ( abs( ( p0_nodeVar60 - ( 1.0 - p0_nodeVar77 ) ) ) - p0_nodeVar77 ) * p0_nodeVar61 );
			

		}


		if ( ( f32(knobs.shape) == 6.0 ) ) {

			p0_nodeVar79 = ( - p0_nodeVar59.y );

			if ( ( p0_nodeVar79 >= 0.0 ) ) {

				p0_nodeVar78 = atan( ( p0_nodeVar59.x / p0_nodeVar79 ) );

			} else {


				if ( ( p0_nodeVar59.x >= 0.0 ) ) {

					p0_nodeVar80 = 3.141592653589793;

				} else {

					p0_nodeVar80 = ( - 3.141592653589793 );

				}

				p0_nodeVar78 = ( atan( ( p0_nodeVar59.x / p0_nodeVar79 ) ) + p0_nodeVar80 );

			}

			p0_nodeVar62 = ( ( p0_nodeVar60 - ( f32(knobs.hub) + ( ( 1.0 - f32(knobs.hub) ) * pow( max( cos( ( f32(knobs.blades) * ( p0_nodeVar78 + ( f32(knobs.twist) * p0_nodeVar60 ) ) ) ), 0.0 ), ( 6.0 - ( f32(knobs.bladeWidth) * 5.5 ) ) ) ) ) ) * p0_nodeVar61 );
			

		}

		p0_nodeVar81 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);
		p0_nodeVar82 = 1.0;

		if ( ( f32(knobs.shape) == 7.0 ) ) {

			p0_nodeVar62 = 1000.0;

			if ( ( f32(0.0) > 0.5 ) ) {

				p0_nodeVar83 = ( vec2<f32>(0.0, 0.0) + ( ( ( p0_nodeVar59 * vec2<f32>( 0.5 ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>(1.0, 1.0) ) );
				p0_nodeVar84 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(1.0, 1.0) );
				p0_nodeVar85 = clamp( p0_nodeVar83, p0_nodeVar84, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar84 ) );
				p0_nodeVar86 = own0_read_level( p0_nodeVar85, 0.0 );
				p0_nodeVar88 = ( vec2<f32>( 1.0, 1.0 ) / vec2<f32>(1.0, 1.0) );
				p0_nodeVar89 = own0_read_level( ( p0_nodeVar85 + vec2<f32>( p0_nodeVar88.x, 0.0 ) ), 0.0 );
				p0_nodeVar90 = own0_read_level( ( p0_nodeVar85 - vec2<f32>( p0_nodeVar88.x, 0.0 ) ), 0.0 );
				p0_nodeVar91 = own0_read_level( ( p0_nodeVar85 + vec2<f32>( 0.0, p0_nodeVar88.y ) ), 0.0 );
				p0_nodeVar92 = own0_read_level( ( p0_nodeVar85 - vec2<f32>( 0.0, p0_nodeVar88.y ) ), 0.0 );
				p0_nodeVar93 = vec2<f32>( ( p0_nodeVar89.x - p0_nodeVar90.x ), ( p0_nodeVar91.x - p0_nodeVar92.x ) );

				if ( ( length( p0_nodeVar93 ) > 0.0001 ) ) {

					p0_nodeVar87 = length( ( ( p0_nodeVar93 / vec2<f32>( max( length( p0_nodeVar93 ), 0.0001 ) ) ) * vec2<f32>( ( ( p0_nodeVar58.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar58.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) ) ) );

				} else {

					p0_nodeVar94 = vec2<f32>( ( ( p0_nodeVar58.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar58.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) );
					p0_nodeVar87 = min( p0_nodeVar94.x, p0_nodeVar94.y );

				}

				p0_nodeVar62 = ( ( p0_nodeVar86.x + length( ( ( p0_nodeVar83 - p0_nodeVar85 ) * vec2<f32>(1.0, 1.0) ) ) ) * p0_nodeVar87 );
				p0_nodeVar95 = own1_read_level( p0_nodeVar85, 0.0 );
				p0_nodeVar81 = p0_nodeVar95.xyz;
				p0_nodeVar82 = p0_nodeVar95.w;
				

			}

			

		}

		p0_nodeVar97 = ( ( ( f32(knobs.shape) == 7.0 ) && ( f32((-1 * knobs.svgColorMode + 1)) > 0.5 ) ) && ( f32(knobs.outline) <= 0.0 ) );

		if ( p0_nodeVar97 ) {

			p0_nodeVar96 = p0_nodeVar81;

		} else {

			p0_nodeVar96 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);

		}

		p0_nodeVar98 = max( f32(knobs.softness), ( f32((1.0 / knobs.resolution.y)) * 0.75 ) );

		if ( ( f32(knobs.outline) > 0.0 ) ) {

			p0_nodeVar99 = ( abs( p0_nodeVar62 ) - ( f32(knobs.outline) * 0.5 ) );

		} else {

			p0_nodeVar99 = p0_nodeVar62;

		}


		if ( p0_nodeVar97 ) {

			p0_nodeVar100 = p0_nodeVar82;

		} else {

			p0_nodeVar100 = 1.0;

		}

		p0_nodeVar101 = vec4<f32>( p0_nodeVar96, clamp( ( ( 1.0 - smoothstep( ( - p0_nodeVar98 ), p0_nodeVar98, p0_nodeVar99 ) ) * p0_nodeVar100 ), 0.0, 1.0 ) );
		p0_nodeVar102 = vec3<f32>( p0_nodeVar101.x, p0_nodeVar101.y, p0_nodeVar101.z );
		p0_nodeVar103 = ( ( ( p0_nodeVar102.x * 0.2126 ) + ( p0_nodeVar102.y * 0.7152 ) ) + ( p0_nodeVar102.z * 0.0722 ) );
		p0_nodeVar104 = mix( vec3<f32>( p0_nodeVar103, p0_nodeVar103, p0_nodeVar103 ), p0_nodeVar102, f32(1.0) );
		p0_nodeVar105 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar104.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar104.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar104.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar104.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar104.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar104.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar104.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar104.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar104.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar101.w, 0.0, 1.0 ) );
		p0_nodeVar106 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar105.w, 0.0, 1.0 ) );
		p0_nodeVar108 = ( p0_nodeVar106 + ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - p0_nodeVar106 ) ) );

		if ( ( p0_nodeVar108 > 0.0 ) ) {

			p0_nodeVar107 = p0_nodeVar108;

		} else {

			p0_nodeVar107 = 1.0;

		}

		p0_nodeVar0 = ( ( ( mix( p0_nodeVar105.xyz, p0_nodeVar105.xyz, clamp( p0_nodeVar1.w, 0.0, 1.0 ) ) * vec3<f32>( p0_nodeVar106 ) ) + ( ( p0_nodeVar1.xyz * vec3<f32>( clamp( p0_nodeVar1.w, 0.0, 1.0 ) ) ) * vec3<f32>( ( 1.0 - p0_nodeVar106 ) ) ) ) / vec3<f32>( p0_nodeVar107 ) );

	}

	p0_nodeVar109 = ( ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) - vec2<f32>(0.0, 0.0) );
	p0_nodeVar110 = cos( f32((0.017453292519943295 * knobs.rotation + 0)) );
	p0_nodeVar111 = sin( f32((0.017453292519943295 * knobs.rotation + 0)) );
	p0_nodeVar112 = vec2<f32>( ( ( p0_nodeVar109.x * p0_nodeVar110 ) + ( p0_nodeVar109.y * p0_nodeVar111 ) ), ( ( p0_nodeVar109.y * p0_nodeVar110 ) - ( p0_nodeVar109.x * p0_nodeVar111 ) ) );
	p0_nodeVar113 = ( vec2<f32>(0.6, 0.6) * vec2<f32>( 0.5 ) );
	p0_nodeVar114 = ( p0_nodeVar112 / p0_nodeVar113 );
	p0_nodeVar115 = length( p0_nodeVar114 );
	p0_nodeVar116 = min( p0_nodeVar113.x, p0_nodeVar113.y );
	p0_nodeVar117 = ( ( p0_nodeVar115 - 1.0 ) * p0_nodeVar116 );

	if ( ( f32(knobs.shape) == 1.0 ) ) {

		p0_nodeVar118 = ( f32(knobs.cornerRadius) * p0_nodeVar116 );
		p0_nodeVar119 = ( ( abs( p0_nodeVar112 ) - p0_nodeVar113 ) + vec2<f32>( p0_nodeVar118 ) );
		p0_nodeVar117 = ( ( length( max( p0_nodeVar119, vec2<f32>( 0.0, 0.0 ) ) ) + min( max( p0_nodeVar119.x, p0_nodeVar119.y ), 0.0 ) ) - p0_nodeVar118 );
		

	}


	if ( ( f32(knobs.shape) == 2.0 ) ) {

		p0_nodeVar120 = ( 3.141592653589793 / 3.0 );
		p0_nodeVar122 = ( - p0_nodeVar114.y );

		if ( ( p0_nodeVar122 >= 0.0 ) ) {

			p0_nodeVar121 = atan( ( p0_nodeVar114.x / p0_nodeVar122 ) );

		} else {


			if ( ( p0_nodeVar114.x >= 0.0 ) ) {

				p0_nodeVar123 = 3.141592653589793;

			} else {

				p0_nodeVar123 = ( - 3.141592653589793 );

			}

			p0_nodeVar121 = ( atan( ( p0_nodeVar114.x / p0_nodeVar122 ) ) + p0_nodeVar123 );

		}

		p0_nodeVar117 = ( ( p0_nodeVar115 - ( cos( p0_nodeVar120 ) / cos( ( p0_tsl_mod_float( p0_nodeVar121, ( ( 2.0 * 3.141592653589793 ) / 3.0 ) ) - p0_nodeVar120 ) ) ) ) * p0_nodeVar116 );
		

	}


	if ( ( f32(knobs.shape) == 3.0 ) ) {

		p0_nodeVar124 = ( 3.141592653589793 / f32(knobs.sides) );
		p0_nodeVar126 = ( - p0_nodeVar114.y );

		if ( ( p0_nodeVar126 >= 0.0 ) ) {

			p0_nodeVar125 = atan( ( p0_nodeVar114.x / p0_nodeVar126 ) );

		} else {


			if ( ( p0_nodeVar114.x >= 0.0 ) ) {

				p0_nodeVar127 = 3.141592653589793;

			} else {

				p0_nodeVar127 = ( - 3.141592653589793 );

			}

			p0_nodeVar125 = ( atan( ( p0_nodeVar114.x / p0_nodeVar126 ) ) + p0_nodeVar127 );

		}

		p0_nodeVar117 = ( ( p0_nodeVar115 - ( cos( p0_nodeVar124 ) / cos( ( p0_tsl_mod_float( p0_nodeVar125, ( ( 2.0 * 3.141592653589793 ) / f32(knobs.sides) ) ) - p0_nodeVar124 ) ) ) ) * p0_nodeVar116 );
		

	}


	if ( ( f32(knobs.shape) == 4.0 ) ) {

		p0_nodeVar129 = ( - p0_nodeVar114.y );

		if ( ( p0_nodeVar129 >= 0.0 ) ) {

			p0_nodeVar128 = atan( ( p0_nodeVar114.x / p0_nodeVar129 ) );

		} else {


			if ( ( p0_nodeVar114.x >= 0.0 ) ) {

				p0_nodeVar130 = 3.141592653589793;

			} else {

				p0_nodeVar130 = ( - 3.141592653589793 );

			}

			p0_nodeVar128 = ( atan( ( p0_nodeVar114.x / p0_nodeVar129 ) ) + p0_nodeVar130 );

		}

		p0_nodeVar131 = ( ( 2.0 * 3.141592653589793 ) / f32(knobs.points) );
		p0_nodeVar117 = ( ( p0_nodeVar115 - ( 1.0 - ( ( 1.0 - f32(knobs.innerRadius) ) * ( abs( ( p0_tsl_mod_float( ( p0_nodeVar128 + ( p0_nodeVar131 * 0.5 ) ), p0_nodeVar131 ) - ( p0_nodeVar131 * 0.5 ) ) ) / ( p0_nodeVar131 * 0.5 ) ) ) ) ) * p0_nodeVar116 );
		

	}


	if ( ( f32(knobs.shape) == 5.0 ) ) {

		p0_nodeVar132 = ( f32(knobs.thickness) * 0.5 );
		p0_nodeVar117 = ( ( abs( ( p0_nodeVar115 - ( 1.0 - p0_nodeVar132 ) ) ) - p0_nodeVar132 ) * p0_nodeVar116 );
		

	}


	if ( ( f32(knobs.shape) == 6.0 ) ) {

		p0_nodeVar134 = ( - p0_nodeVar114.y );

		if ( ( p0_nodeVar134 >= 0.0 ) ) {

			p0_nodeVar133 = atan( ( p0_nodeVar114.x / p0_nodeVar134 ) );

		} else {


			if ( ( p0_nodeVar114.x >= 0.0 ) ) {

				p0_nodeVar135 = 3.141592653589793;

			} else {

				p0_nodeVar135 = ( - 3.141592653589793 );

			}

			p0_nodeVar133 = ( atan( ( p0_nodeVar114.x / p0_nodeVar134 ) ) + p0_nodeVar135 );

		}

		p0_nodeVar117 = ( ( p0_nodeVar115 - ( f32(knobs.hub) + ( ( 1.0 - f32(knobs.hub) ) * pow( max( cos( ( f32(knobs.blades) * ( p0_nodeVar133 + ( f32(knobs.twist) * p0_nodeVar115 ) ) ) ), 0.0 ), ( 6.0 - ( f32(knobs.bladeWidth) * 5.5 ) ) ) ) ) ) * p0_nodeVar116 );
		

	}

	p0_nodeVar136 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);
	p0_nodeVar137 = 1.0;

	if ( ( f32(knobs.shape) == 7.0 ) ) {

		p0_nodeVar117 = 1000.0;

		if ( ( f32(0.0) > 0.5 ) ) {

			p0_nodeVar138 = ( vec2<f32>(0.0, 0.0) + ( ( ( p0_nodeVar114 * vec2<f32>( 0.5 ) ) + vec2<f32>( 0.5 ) ) * vec2<f32>(1.0, 1.0) ) );
			p0_nodeVar139 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(1.0, 1.0) );
			p0_nodeVar140 = clamp( p0_nodeVar138, p0_nodeVar139, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar139 ) );
			p0_nodeVar141 = own0_read_level( p0_nodeVar140, 0.0 );
			p0_nodeVar143 = ( vec2<f32>( 1.0, 1.0 ) / vec2<f32>(1.0, 1.0) );
			p0_nodeVar144 = own0_read_level( ( p0_nodeVar140 + vec2<f32>( p0_nodeVar143.x, 0.0 ) ), 0.0 );
			p0_nodeVar145 = own0_read_level( ( p0_nodeVar140 - vec2<f32>( p0_nodeVar143.x, 0.0 ) ), 0.0 );
			p0_nodeVar146 = own0_read_level( ( p0_nodeVar140 + vec2<f32>( 0.0, p0_nodeVar143.y ) ), 0.0 );
			p0_nodeVar147 = own0_read_level( ( p0_nodeVar140 - vec2<f32>( 0.0, p0_nodeVar143.y ) ), 0.0 );
			p0_nodeVar148 = vec2<f32>( ( p0_nodeVar144.x - p0_nodeVar145.x ), ( p0_nodeVar146.x - p0_nodeVar147.x ) );

			if ( ( length( p0_nodeVar148 ) > 0.0001 ) ) {

				p0_nodeVar142 = length( ( ( p0_nodeVar148 / vec2<f32>( max( length( p0_nodeVar148 ), 0.0001 ) ) ) * vec2<f32>( ( ( p0_nodeVar113.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar113.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) ) ) );

			} else {

				p0_nodeVar149 = vec2<f32>( ( ( p0_nodeVar113.x * 2.0 ) / vec2<f32>(1.0, 1.0).x ), ( ( p0_nodeVar113.y * 2.0 ) / vec2<f32>(1.0, 1.0).y ) );
				p0_nodeVar142 = min( p0_nodeVar149.x, p0_nodeVar149.y );

			}

			p0_nodeVar117 = ( ( p0_nodeVar141.x + length( ( ( p0_nodeVar138 - p0_nodeVar140 ) * vec2<f32>(1.0, 1.0) ) ) ) * p0_nodeVar142 );
			p0_nodeVar150 = own1_read_level( p0_nodeVar140, 0.0 );
			p0_nodeVar136 = p0_nodeVar150.xyz;
			p0_nodeVar137 = p0_nodeVar150.w;
			

		}

		

	}

	p0_nodeVar152 = ( ( ( f32(knobs.shape) == 7.0 ) && ( f32((-1 * knobs.svgColorMode + 1)) > 0.5 ) ) && ( f32(knobs.outline) <= 0.0 ) );

	if ( p0_nodeVar152 ) {

		p0_nodeVar151 = p0_nodeVar136;

	} else {

		p0_nodeVar151 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);

	}

	p0_nodeVar153 = max( f32(knobs.softness), ( f32((1.0 / knobs.resolution.y)) * 0.75 ) );

	if ( ( f32(knobs.outline) > 0.0 ) ) {

		p0_nodeVar154 = ( abs( p0_nodeVar117 ) - ( f32(knobs.outline) * 0.5 ) );

	} else {

		p0_nodeVar154 = p0_nodeVar117;

	}


	if ( p0_nodeVar152 ) {

		p0_nodeVar155 = p0_nodeVar137;

	} else {

		p0_nodeVar155 = 1.0;

	}

	p0_nodeVar156 = vec4<f32>( p0_nodeVar151, clamp( ( ( 1.0 - smoothstep( ( - p0_nodeVar153 ), p0_nodeVar153, p0_nodeVar154 ) ) * p0_nodeVar155 ), 0.0, 1.0 ) );
	p0_nodeVar157 = vec3<f32>( p0_nodeVar156.x, p0_nodeVar156.y, p0_nodeVar156.z );
	p0_nodeVar158 = ( ( ( p0_nodeVar157.x * 0.2126 ) + ( p0_nodeVar157.y * 0.7152 ) ) + ( p0_nodeVar157.z * 0.0722 ) );
	p0_nodeVar159 = mix( vec3<f32>( p0_nodeVar158, p0_nodeVar158, p0_nodeVar158 ), p0_nodeVar157, f32(1.0) );
	p0_nodeVar160 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar159.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar159.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar159.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar159.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar159.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar159.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar159.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar159.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar159.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar156.w, 0.0, 1.0 ) ).w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( p0_nodeVar0, ( p0_nodeVar160 + ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - p0_nodeVar160 ) ) ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar161 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar161;

	// result

	p0_output.color = p0_nodeVar161;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

// Erosion: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Distort
// --about:Crumbles the image into speckle along edges, tones or a cutout's border, throwing fragments outward.
// --track@mode:Erode From,0,3,0,1
// --track@erode:Erode,0,1,0.6,0.01
// --track@edgeWidth:Edge Width,0.5,64,6,0.5
// --track@speckleSize:Speckle Size,1,32,3,0.5
// --track@clumping:Clumping,0,1,0.35,0.01
// --track@scatter:Scatter,0,1,0.5,0.01
// --check@output:Reveal,0
// --track@paperColor_x:Paper Color r,0,1,0.8879231178794776,0.001
// --track@paperColor_y:Paper Color g,0,1,0.8631572134510892,0.001
// --track@paperColor_z:Paper Color b,0,1,0.8069522576650873,0.001
// --track@seed:Seed,0,999,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  mode: f32,
  erode: f32,
  edgeWidth: f32,
  speckleSize: f32,
  clumping: f32,
  scatter: f32,
  output: f32,
  paperColor: vec3<f32>,
  seed: f32,
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
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : vec4<f32>;
var<private> p0_nodeVar4 : vec4<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : vec2<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : vec4<f32>;
var<private> p0_nodeVar14 : vec4<f32>;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : vec4<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : vec4<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : vec3<f32>;
var<private> p0_nodeVar52 : vec3<f32>;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : vec2<f32>;
var<private> p0_nodeVar57 : vec3<f32>;
var<private> p0_nodeVar58 : vec3<f32>;
var<private> p0_nodeVar59 : vec2<f32>;
var<private> p0_nodeVar60 : vec3<f32>;
var<private> p0_nodeVar61 : vec3<f32>;
var<private> p0_nodeVar62 : vec2<f32>;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : vec4<f32>;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : vec4<f32>;
var<private> p0_nodeVar67 : vec4<f32>;
var<private> p0_nodeVar68 : vec4<f32>;
var<private> p0_nodeVar69 : vec4<f32>;
var<private> p0_nodeVar70 : vec4<f32>;
var<private> p0_nodeVar71 : vec4<f32>;
var<private> p0_nodeVar72 : vec4<f32>;
var<private> p0_nodeVar73 : vec4<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : f32;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : f32;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : f32;
var<private> p0_nodeVar94 : f32;
var<private> p0_nodeVar95 : f32;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : f32;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : f32;
var<private> p0_nodeVar102 : f32;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : vec3<f32>;
var<private> p0_nodeVar105 : bool;
var<private> p0_nodeVar106 : vec3<f32>;
var<private> p0_nodeVar107 : vec3<f32>;
var<private> p0_nodeVar108 : vec2<f32>;
var<private> p0_nodeVar109 : vec2<f32>;
var<private> p0_nodeVar110 : vec3<f32>;
var<private> p0_nodeVar111 : vec3<f32>;
var<private> p0_nodeVar112 : vec2<f32>;
var<private> p0_nodeVar113 : vec3<f32>;
var<private> p0_nodeVar114 : vec3<f32>;
var<private> p0_nodeVar115 : vec2<f32>;
var<private> p0_nodeVar116 : vec2<f32>;
var<private> p0_nodeVar117 : vec2<f32>;
var<private> p0_nodeVar118 : vec3<f32>;
var<private> p0_nodeVar119 : vec3<f32>;
var<private> p0_nodeVar120 : vec2<f32>;
var<private> p0_nodeVar121 : vec3<f32>;
var<private> p0_nodeVar122 : vec3<f32>;
var<private> p0_nodeVar123 : vec2<f32>;
var<private> p0_nodeVar124 : vec3<f32>;
var<private> p0_nodeVar125 : vec3<f32>;
var<private> p0_nodeVar126 : f32;
var<private> p0_nodeVar127 : f32;
var<private> p0_nodeVar128 : vec3<f32>;
var<private> p0_nodeVar129 : vec3<f32>;
var<private> p0_nodeVar130 : vec2<f32>;
var<private> p0_nodeVar131 : vec2<f32>;
var<private> p0_nodeVar132 : vec3<f32>;
var<private> p0_nodeVar133 : vec3<f32>;
var<private> p0_nodeVar134 : vec2<f32>;
var<private> p0_nodeVar135 : vec3<f32>;
var<private> p0_nodeVar136 : vec3<f32>;
var<private> p0_nodeVar137 : vec2<f32>;
var<private> p0_nodeVar138 : vec2<f32>;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : vec3<f32>;
var<private> p0_nodeVar141 : vec3<f32>;
var<private> p0_nodeVar142 : vec2<f32>;
var<private> p0_nodeVar143 : vec3<f32>;
var<private> p0_nodeVar144 : vec3<f32>;
var<private> p0_nodeVar145 : vec2<f32>;
var<private> p0_nodeVar146 : vec3<f32>;
var<private> p0_nodeVar147 : vec3<f32>;
var<private> p0_nodeVar148 : vec3<f32>;
var<private> p0_nodeVar149 : f32;
var<private> p0_nodeVar150 : vec3<f32>;
var<private> p0_nodeVar151 : vec4<f32>;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar154 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = picture_read_level( p0_nodeVar1, 0.0 );
	p0_nodeVar3 = p0_nodeVar2;
	p0_nodeVar4 = vec4<f32>( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), p0_nodeVar3.w );

	if ( ( f32(knobs.erode) >= 0.0001 ) ) {

		p0_nodeVar5 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar6 = vec2<f32>( ( 1.0 / p0_nodeVar5.x ), ( 1.0 / p0_nodeVar5.y ) );
		p0_nodeVar7 = ( p0_nodeVar1 * p0_nodeVar5 );
		p0_nodeVar8 = ( f32(knobs.seed) * 13.7 );
		p0_nodeVar9 = floor( ( f32(0.0) * 8.0 ) );
		p0_nodeVar10 = ( floor( ( p0_nodeVar7 / vec2<f32>( f32(knobs.speckleSize) ) ) ) + vec2<f32>( p0_nodeVar8, ( p0_nodeVar9 * 1.37 ) ) );
		p0_nodeVar11 = ( p0_nodeVar6 * vec2<f32>( f32(knobs.edgeWidth) ) );
		p0_nodeVar12 = picture_read_level( ( p0_nodeVar1 + vec2<f32>( p0_nodeVar11.x, 0.0 ) ), 0.0 );
		p0_nodeVar13 = p0_nodeVar12;
		p0_nodeVar14 = picture_read_level( ( p0_nodeVar1 - vec2<f32>( p0_nodeVar11.x, 0.0 ) ), 0.0 );
		p0_nodeVar15 = p0_nodeVar14;
		p0_nodeVar16 = picture_read_level( ( p0_nodeVar1 + vec2<f32>( 0.0, p0_nodeVar11.y ) ), 0.0 );
		p0_nodeVar17 = p0_nodeVar16;
		p0_nodeVar18 = picture_read_level( ( p0_nodeVar1 - vec2<f32>( 0.0, p0_nodeVar11.y ) ), 0.0 );
		p0_nodeVar19 = p0_nodeVar18;
		p0_nodeVar20 = 0.0;

		if ( ( f32(knobs.mode) < 0.5 ) ) {

			p0_nodeVar22 = clamp( dot( vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar22 <= 0.0031308 ) ) {

				p0_nodeVar21 = ( p0_nodeVar22 * 12.92 );

			} else {

				p0_nodeVar21 = ( ( pow( p0_nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar24 = clamp( dot( vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar24 <= 0.0031308 ) ) {

				p0_nodeVar23 = ( p0_nodeVar24 * 12.92 );

			} else {

				p0_nodeVar23 = ( ( pow( p0_nodeVar24, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar26 = clamp( dot( vec3<f32>( p0_nodeVar17.x, p0_nodeVar17.y, p0_nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar26 <= 0.0031308 ) ) {

				p0_nodeVar25 = ( p0_nodeVar26 * 12.92 );

			} else {

				p0_nodeVar25 = ( ( pow( p0_nodeVar26, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar28 = clamp( dot( vec3<f32>( p0_nodeVar19.x, p0_nodeVar19.y, p0_nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar28 <= 0.0031308 ) ) {

				p0_nodeVar27 = ( p0_nodeVar28 * 12.92 );

			} else {

				p0_nodeVar27 = ( ( pow( p0_nodeVar28, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar20 = smoothstep( 0.1, 0.5, ( abs( ( p0_nodeVar21 - p0_nodeVar23 ) ) + abs( ( p0_nodeVar25 - p0_nodeVar27 ) ) ) );
			

		} else {


			if ( ( f32(knobs.mode) < 2.5 ) ) {


				if ( ( f32(knobs.mode) < 1.5 ) ) {

					p0_nodeVar31 = clamp( dot( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar31 <= 0.0031308 ) ) {

						p0_nodeVar30 = ( p0_nodeVar31 * 12.92 );

					} else {

						p0_nodeVar30 = ( ( pow( p0_nodeVar31, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar33 = clamp( dot( vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar33 <= 0.0031308 ) ) {

						p0_nodeVar32 = ( p0_nodeVar33 * 12.92 );

					} else {

						p0_nodeVar32 = ( ( pow( p0_nodeVar33, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar35 = clamp( dot( vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar35 <= 0.0031308 ) ) {

						p0_nodeVar34 = ( p0_nodeVar35 * 12.92 );

					} else {

						p0_nodeVar34 = ( ( pow( p0_nodeVar35, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar37 = clamp( dot( vec3<f32>( p0_nodeVar17.x, p0_nodeVar17.y, p0_nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar37 <= 0.0031308 ) ) {

						p0_nodeVar36 = ( p0_nodeVar37 * 12.92 );

					} else {

						p0_nodeVar36 = ( ( pow( p0_nodeVar37, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar39 = clamp( dot( vec3<f32>( p0_nodeVar19.x, p0_nodeVar19.y, p0_nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar39 <= 0.0031308 ) ) {

						p0_nodeVar38 = ( p0_nodeVar39 * 12.92 );

					} else {

						p0_nodeVar38 = ( ( pow( p0_nodeVar39, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar29 = smoothstep( 0.35, 0.95, ( ( ( ( ( ( p0_nodeVar30 * 2.0 ) + p0_nodeVar32 ) + p0_nodeVar34 ) + p0_nodeVar36 ) + p0_nodeVar38 ) / 6.0 ) );

				} else {

					p0_nodeVar41 = clamp( dot( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar41 <= 0.0031308 ) ) {

						p0_nodeVar40 = ( p0_nodeVar41 * 12.92 );

					} else {

						p0_nodeVar40 = ( ( pow( p0_nodeVar41, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar43 = clamp( dot( vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar43 <= 0.0031308 ) ) {

						p0_nodeVar42 = ( p0_nodeVar43 * 12.92 );

					} else {

						p0_nodeVar42 = ( ( pow( p0_nodeVar43, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar45 = clamp( dot( vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar45 <= 0.0031308 ) ) {

						p0_nodeVar44 = ( p0_nodeVar45 * 12.92 );

					} else {

						p0_nodeVar44 = ( ( pow( p0_nodeVar45, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar47 = clamp( dot( vec3<f32>( p0_nodeVar17.x, p0_nodeVar17.y, p0_nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar47 <= 0.0031308 ) ) {

						p0_nodeVar46 = ( p0_nodeVar47 * 12.92 );

					} else {

						p0_nodeVar46 = ( ( pow( p0_nodeVar47, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar49 = clamp( dot( vec3<f32>( p0_nodeVar19.x, p0_nodeVar19.y, p0_nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( p0_nodeVar49 <= 0.0031308 ) ) {

						p0_nodeVar48 = ( p0_nodeVar49 * 12.92 );

					} else {

						p0_nodeVar48 = ( ( pow( p0_nodeVar49, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					p0_nodeVar29 = ( 1.0 - smoothstep( 0.05, 0.65, ( ( ( ( ( ( p0_nodeVar40 * 2.0 ) + p0_nodeVar42 ) + p0_nodeVar44 ) + p0_nodeVar46 ) + p0_nodeVar48 ) / 6.0 ) ) );

				}

				p0_nodeVar20 = p0_nodeVar29;
				

			} else {

				p0_nodeVar20 = ( 1.0 - smoothstep( 0.02, 0.98, ( ( ( ( ( ( p0_nodeVar3.w * 2.0 ) + p0_nodeVar13.w ) + p0_nodeVar15.w ) + p0_nodeVar17.w ) + p0_nodeVar19.w ) / 6.0 ) ) );
				

			}

			

		}

		p0_nodeVar50 = ( p0_nodeVar10 + vec2<f32>( 7.7 ) );
		p0_nodeVar51 = fract( ( vec3<f32>( p0_nodeVar50.x, p0_nodeVar50.y, p0_nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar52 = ( p0_nodeVar51 + vec3<f32>( dot( p0_nodeVar51, ( vec3<f32>( p0_nodeVar51.y, p0_nodeVar51.z, p0_nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar53 = ( ( ( ( f32(knobs.scatter) * min( p0_nodeVar5.x, p0_nodeVar5.y ) ) * 0.06 ) * p0_nodeVar20 ) * fract( ( ( p0_nodeVar52.x + p0_nodeVar52.y ) * p0_nodeVar52.z ) ) );
		p0_nodeVar54 = p0_nodeVar3;
		p0_nodeVar55 = p0_nodeVar20;

		if ( ( abs( p0_nodeVar53 ) > 0.0 ) ) {

			p0_nodeVar56 = ( p0_nodeVar10 + vec2<f32>( 1.3 ) );
			p0_nodeVar57 = fract( ( vec3<f32>( p0_nodeVar56.x, p0_nodeVar56.y, p0_nodeVar56.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar58 = ( p0_nodeVar57 + vec3<f32>( dot( p0_nodeVar57, ( vec3<f32>( p0_nodeVar57.y, p0_nodeVar57.z, p0_nodeVar57.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar59 = ( p0_nodeVar10 + vec2<f32>( 2.9 ) );
			p0_nodeVar60 = fract( ( vec3<f32>( p0_nodeVar59.x, p0_nodeVar59.y, p0_nodeVar59.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar61 = ( p0_nodeVar60 + vec3<f32>( dot( p0_nodeVar60, ( vec3<f32>( p0_nodeVar60.y, p0_nodeVar60.z, p0_nodeVar60.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar62 = ( p0_nodeVar1 + ( ( ( ( vec2<f32>( fract( ( ( p0_nodeVar58.x + p0_nodeVar58.y ) * p0_nodeVar58.z ) ), fract( ( ( p0_nodeVar61.x + p0_nodeVar61.y ) * p0_nodeVar61.z ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( 2.0 ) ) * vec2<f32>( p0_nodeVar53 ) ) * p0_nodeVar6 ) );
			p0_nodeVar63 = picture_read_level( p0_nodeVar62, 0.0 );
			p0_nodeVar64 = p0_nodeVar63;
			p0_nodeVar65 = ( p0_nodeVar6 * vec2<f32>( f32(knobs.edgeWidth) ) );
			p0_nodeVar66 = picture_read_level( ( p0_nodeVar62 + vec2<f32>( p0_nodeVar65.x, 0.0 ) ), 0.0 );
			p0_nodeVar67 = p0_nodeVar66;
			p0_nodeVar68 = picture_read_level( ( p0_nodeVar62 - vec2<f32>( p0_nodeVar65.x, 0.0 ) ), 0.0 );
			p0_nodeVar69 = p0_nodeVar68;
			p0_nodeVar70 = picture_read_level( ( p0_nodeVar62 + vec2<f32>( 0.0, p0_nodeVar65.y ) ), 0.0 );
			p0_nodeVar71 = p0_nodeVar70;
			p0_nodeVar72 = picture_read_level( ( p0_nodeVar62 - vec2<f32>( 0.0, p0_nodeVar65.y ) ), 0.0 );
			p0_nodeVar73 = p0_nodeVar72;
			p0_nodeVar74 = 0.0;

			if ( ( f32(knobs.mode) < 0.5 ) ) {

				p0_nodeVar76 = clamp( dot( vec3<f32>( p0_nodeVar67.x, p0_nodeVar67.y, p0_nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar76 <= 0.0031308 ) ) {

					p0_nodeVar75 = ( p0_nodeVar76 * 12.92 );

				} else {

					p0_nodeVar75 = ( ( pow( p0_nodeVar76, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar78 = clamp( dot( vec3<f32>( p0_nodeVar69.x, p0_nodeVar69.y, p0_nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar78 <= 0.0031308 ) ) {

					p0_nodeVar77 = ( p0_nodeVar78 * 12.92 );

				} else {

					p0_nodeVar77 = ( ( pow( p0_nodeVar78, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar80 = clamp( dot( vec3<f32>( p0_nodeVar71.x, p0_nodeVar71.y, p0_nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar80 <= 0.0031308 ) ) {

					p0_nodeVar79 = ( p0_nodeVar80 * 12.92 );

				} else {

					p0_nodeVar79 = ( ( pow( p0_nodeVar80, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar82 = clamp( dot( vec3<f32>( p0_nodeVar73.x, p0_nodeVar73.y, p0_nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( p0_nodeVar82 <= 0.0031308 ) ) {

					p0_nodeVar81 = ( p0_nodeVar82 * 12.92 );

				} else {

					p0_nodeVar81 = ( ( pow( p0_nodeVar82, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				p0_nodeVar74 = smoothstep( 0.1, 0.5, ( abs( ( p0_nodeVar75 - p0_nodeVar77 ) ) + abs( ( p0_nodeVar79 - p0_nodeVar81 ) ) ) );
				

			} else {


				if ( ( f32(knobs.mode) < 2.5 ) ) {


					if ( ( f32(knobs.mode) < 1.5 ) ) {

						p0_nodeVar85 = clamp( dot( vec3<f32>( p0_nodeVar64.x, p0_nodeVar64.y, p0_nodeVar64.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar85 <= 0.0031308 ) ) {

							p0_nodeVar84 = ( p0_nodeVar85 * 12.92 );

						} else {

							p0_nodeVar84 = ( ( pow( p0_nodeVar85, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar87 = clamp( dot( vec3<f32>( p0_nodeVar67.x, p0_nodeVar67.y, p0_nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar87 <= 0.0031308 ) ) {

							p0_nodeVar86 = ( p0_nodeVar87 * 12.92 );

						} else {

							p0_nodeVar86 = ( ( pow( p0_nodeVar87, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar89 = clamp( dot( vec3<f32>( p0_nodeVar69.x, p0_nodeVar69.y, p0_nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar89 <= 0.0031308 ) ) {

							p0_nodeVar88 = ( p0_nodeVar89 * 12.92 );

						} else {

							p0_nodeVar88 = ( ( pow( p0_nodeVar89, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar91 = clamp( dot( vec3<f32>( p0_nodeVar71.x, p0_nodeVar71.y, p0_nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar91 <= 0.0031308 ) ) {

							p0_nodeVar90 = ( p0_nodeVar91 * 12.92 );

						} else {

							p0_nodeVar90 = ( ( pow( p0_nodeVar91, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar93 = clamp( dot( vec3<f32>( p0_nodeVar73.x, p0_nodeVar73.y, p0_nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar93 <= 0.0031308 ) ) {

							p0_nodeVar92 = ( p0_nodeVar93 * 12.92 );

						} else {

							p0_nodeVar92 = ( ( pow( p0_nodeVar93, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar83 = smoothstep( 0.35, 0.95, ( ( ( ( ( ( p0_nodeVar84 * 2.0 ) + p0_nodeVar86 ) + p0_nodeVar88 ) + p0_nodeVar90 ) + p0_nodeVar92 ) / 6.0 ) );

					} else {

						p0_nodeVar95 = clamp( dot( vec3<f32>( p0_nodeVar64.x, p0_nodeVar64.y, p0_nodeVar64.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar95 <= 0.0031308 ) ) {

							p0_nodeVar94 = ( p0_nodeVar95 * 12.92 );

						} else {

							p0_nodeVar94 = ( ( pow( p0_nodeVar95, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar97 = clamp( dot( vec3<f32>( p0_nodeVar67.x, p0_nodeVar67.y, p0_nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar97 <= 0.0031308 ) ) {

							p0_nodeVar96 = ( p0_nodeVar97 * 12.92 );

						} else {

							p0_nodeVar96 = ( ( pow( p0_nodeVar97, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar99 = clamp( dot( vec3<f32>( p0_nodeVar69.x, p0_nodeVar69.y, p0_nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar99 <= 0.0031308 ) ) {

							p0_nodeVar98 = ( p0_nodeVar99 * 12.92 );

						} else {

							p0_nodeVar98 = ( ( pow( p0_nodeVar99, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar101 = clamp( dot( vec3<f32>( p0_nodeVar71.x, p0_nodeVar71.y, p0_nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar101 <= 0.0031308 ) ) {

							p0_nodeVar100 = ( p0_nodeVar101 * 12.92 );

						} else {

							p0_nodeVar100 = ( ( pow( p0_nodeVar101, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar103 = clamp( dot( vec3<f32>( p0_nodeVar73.x, p0_nodeVar73.y, p0_nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( p0_nodeVar103 <= 0.0031308 ) ) {

							p0_nodeVar102 = ( p0_nodeVar103 * 12.92 );

						} else {

							p0_nodeVar102 = ( ( pow( p0_nodeVar103, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						p0_nodeVar83 = ( 1.0 - smoothstep( 0.05, 0.65, ( ( ( ( ( ( p0_nodeVar94 * 2.0 ) + p0_nodeVar96 ) + p0_nodeVar98 ) + p0_nodeVar100 ) + p0_nodeVar102 ) / 6.0 ) ) );

					}

					p0_nodeVar74 = p0_nodeVar83;
					

				} else {

					p0_nodeVar74 = ( 1.0 - smoothstep( 0.02, 0.98, ( ( ( ( ( ( p0_nodeVar64.w * 2.0 ) + p0_nodeVar67.w ) + p0_nodeVar69.w ) + p0_nodeVar71.w ) + p0_nodeVar73.w ) / 6.0 ) ) );
					

				}

				

			}

			p0_nodeVar55 = p0_nodeVar74;
			p0_nodeVar54 = p0_nodeVar64;
			

		}

		p0_nodeVar105 = ( f32(knobs.output) > 0.5 );

		if ( p0_nodeVar105 ) {

			p0_nodeVar104 = vec3<f32>( p0_nodeVar54.x, p0_nodeVar54.y, p0_nodeVar54.z );

		} else {

			p0_nodeVar106 = fract( ( vec3<f32>( p0_nodeVar10.x, p0_nodeVar10.y, p0_nodeVar10.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar107 = ( p0_nodeVar106 + vec3<f32>( dot( p0_nodeVar106, ( vec3<f32>( p0_nodeVar106.y, p0_nodeVar106.z, p0_nodeVar106.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar108 = ( ( p0_nodeVar7 / vec2<f32>( ( f32(knobs.speckleSize) * 7.0 ) ) ) + vec2<f32>( p0_nodeVar8, p0_nodeVar9 ) );
			p0_nodeVar109 = floor( p0_nodeVar108 );
			p0_nodeVar110 = fract( ( vec3<f32>( p0_nodeVar109.x, p0_nodeVar109.y, p0_nodeVar109.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar111 = ( p0_nodeVar110 + vec3<f32>( dot( p0_nodeVar110, ( vec3<f32>( p0_nodeVar110.y, p0_nodeVar110.z, p0_nodeVar110.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar112 = ( p0_nodeVar109 + vec2<f32>( 1.0, 0.0 ) );
			p0_nodeVar113 = fract( ( vec3<f32>( p0_nodeVar112.x, p0_nodeVar112.y, p0_nodeVar112.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar114 = ( p0_nodeVar113 + vec3<f32>( dot( p0_nodeVar113, ( vec3<f32>( p0_nodeVar113.y, p0_nodeVar113.z, p0_nodeVar113.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar115 = fract( p0_nodeVar108 );
			p0_nodeVar116 = ( ( p0_nodeVar115 * p0_nodeVar115 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar115 * vec2<f32>( 2.0 ) ) ) );
			p0_nodeVar117 = ( p0_nodeVar109 + vec2<f32>( 0.0, 1.0 ) );
			p0_nodeVar118 = fract( ( vec3<f32>( p0_nodeVar117.x, p0_nodeVar117.y, p0_nodeVar117.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar119 = ( p0_nodeVar118 + vec3<f32>( dot( p0_nodeVar118, ( vec3<f32>( p0_nodeVar118.y, p0_nodeVar118.z, p0_nodeVar118.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar120 = ( p0_nodeVar109 + vec2<f32>( 1.0, 1.0 ) );
			p0_nodeVar121 = fract( ( vec3<f32>( p0_nodeVar120.x, p0_nodeVar120.y, p0_nodeVar120.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar122 = ( p0_nodeVar121 + vec3<f32>( dot( p0_nodeVar121, ( vec3<f32>( p0_nodeVar121.y, p0_nodeVar121.z, p0_nodeVar121.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar123 = ( p0_nodeVar10 + vec2<f32>( 5.3 ) );
			p0_nodeVar124 = fract( ( vec3<f32>( p0_nodeVar123.x, p0_nodeVar123.y, p0_nodeVar123.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar125 = ( p0_nodeVar124 + vec3<f32>( dot( p0_nodeVar124, ( vec3<f32>( p0_nodeVar124.y, p0_nodeVar124.z, p0_nodeVar124.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar104 = mix( vec3<f32>( p0_nodeVar54.x, p0_nodeVar54.y, p0_nodeVar54.z ), vec3<f32>(knobs.paperColor.x, knobs.paperColor.y, knobs.paperColor.z), ( ( ( 1.0 - step( clamp( ( ( p0_nodeVar55 * ( f32(knobs.erode) * 2.5 ) ) - ( ( 1.0 - f32(knobs.erode) ) * 0.25 ) ), 0.0, 1.0 ), mix( fract( ( ( p0_nodeVar107.x + p0_nodeVar107.y ) * p0_nodeVar107.z ) ), mix( mix( fract( ( ( p0_nodeVar111.x + p0_nodeVar111.y ) * p0_nodeVar111.z ) ), fract( ( ( p0_nodeVar114.x + p0_nodeVar114.y ) * p0_nodeVar114.z ) ), p0_nodeVar116.x ), mix( fract( ( ( p0_nodeVar119.x + p0_nodeVar119.y ) * p0_nodeVar119.z ) ), fract( ( ( p0_nodeVar122.x + p0_nodeVar122.y ) * p0_nodeVar122.z ) ), p0_nodeVar116.x ), p0_nodeVar116.y ), f32(knobs.clumping) ) ) ) * ( 1.0 - ( 1.0 - step( ( ( f32(knobs.scatter) * 0.55 ) * p0_nodeVar20 ), fract( ( ( p0_nodeVar125.x + p0_nodeVar125.y ) * p0_nodeVar125.z ) ) ) ) ) ) * step( 0.0001, f32(knobs.erode) ) ) );

		}

		p0_nodeVar126 = step( 0.0001, f32(knobs.erode) );

		if ( p0_nodeVar105 ) {

			p0_nodeVar128 = fract( ( vec3<f32>( p0_nodeVar10.x, p0_nodeVar10.y, p0_nodeVar10.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar129 = ( p0_nodeVar128 + vec3<f32>( dot( p0_nodeVar128, ( vec3<f32>( p0_nodeVar128.y, p0_nodeVar128.z, p0_nodeVar128.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar130 = ( ( p0_nodeVar7 / vec2<f32>( ( f32(knobs.speckleSize) * 7.0 ) ) ) + vec2<f32>( p0_nodeVar8, p0_nodeVar9 ) );
			p0_nodeVar131 = floor( p0_nodeVar130 );
			p0_nodeVar132 = fract( ( vec3<f32>( p0_nodeVar131.x, p0_nodeVar131.y, p0_nodeVar131.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar133 = ( p0_nodeVar132 + vec3<f32>( dot( p0_nodeVar132, ( vec3<f32>( p0_nodeVar132.y, p0_nodeVar132.z, p0_nodeVar132.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar134 = ( p0_nodeVar131 + vec2<f32>( 1.0, 0.0 ) );
			p0_nodeVar135 = fract( ( vec3<f32>( p0_nodeVar134.x, p0_nodeVar134.y, p0_nodeVar134.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar136 = ( p0_nodeVar135 + vec3<f32>( dot( p0_nodeVar135, ( vec3<f32>( p0_nodeVar135.y, p0_nodeVar135.z, p0_nodeVar135.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar137 = fract( p0_nodeVar130 );
			p0_nodeVar138 = ( ( p0_nodeVar137 * p0_nodeVar137 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar137 * vec2<f32>( 2.0 ) ) ) );
			p0_nodeVar139 = ( p0_nodeVar131 + vec2<f32>( 0.0, 1.0 ) );
			p0_nodeVar140 = fract( ( vec3<f32>( p0_nodeVar139.x, p0_nodeVar139.y, p0_nodeVar139.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar141 = ( p0_nodeVar140 + vec3<f32>( dot( p0_nodeVar140, ( vec3<f32>( p0_nodeVar140.y, p0_nodeVar140.z, p0_nodeVar140.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar142 = ( p0_nodeVar131 + vec2<f32>( 1.0, 1.0 ) );
			p0_nodeVar143 = fract( ( vec3<f32>( p0_nodeVar142.x, p0_nodeVar142.y, p0_nodeVar142.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar144 = ( p0_nodeVar143 + vec3<f32>( dot( p0_nodeVar143, ( vec3<f32>( p0_nodeVar143.y, p0_nodeVar143.z, p0_nodeVar143.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar145 = ( p0_nodeVar10 + vec2<f32>( 5.3 ) );
			p0_nodeVar146 = fract( ( vec3<f32>( p0_nodeVar145.x, p0_nodeVar145.y, p0_nodeVar145.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar147 = ( p0_nodeVar146 + vec3<f32>( dot( p0_nodeVar146, ( vec3<f32>( p0_nodeVar146.y, p0_nodeVar146.z, p0_nodeVar146.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar127 = ( clamp( p0_nodeVar54.w, 0.0, 1.0 ) * ( 1.0 - ( ( ( 1.0 - step( clamp( ( ( p0_nodeVar55 * ( f32(knobs.erode) * 2.5 ) ) - ( ( 1.0 - f32(knobs.erode) ) * 0.25 ) ), 0.0, 1.0 ), mix( fract( ( ( p0_nodeVar129.x + p0_nodeVar129.y ) * p0_nodeVar129.z ) ), mix( mix( fract( ( ( p0_nodeVar133.x + p0_nodeVar133.y ) * p0_nodeVar133.z ) ), fract( ( ( p0_nodeVar136.x + p0_nodeVar136.y ) * p0_nodeVar136.z ) ), p0_nodeVar138.x ), mix( fract( ( ( p0_nodeVar141.x + p0_nodeVar141.y ) * p0_nodeVar141.z ) ), fract( ( ( p0_nodeVar144.x + p0_nodeVar144.y ) * p0_nodeVar144.z ) ), p0_nodeVar138.x ), p0_nodeVar138.y ), f32(knobs.clumping) ) ) ) * ( 1.0 - ( 1.0 - step( ( ( f32(knobs.scatter) * 0.55 ) * p0_nodeVar20 ), fract( ( ( p0_nodeVar147.x + p0_nodeVar147.y ) * p0_nodeVar147.z ) ) ) ) ) ) * p0_nodeVar126 ) ) );

		} else {

			p0_nodeVar127 = clamp( p0_nodeVar54.w, 0.0, 1.0 );

		}

		p0_nodeVar4 = vec4<f32>( mix( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), p0_nodeVar104, p0_nodeVar126 ), mix( p0_nodeVar3.w, p0_nodeVar127, p0_nodeVar126 ) );
		

	}

	p0_nodeVar148 = vec3<f32>( p0_nodeVar4.x, p0_nodeVar4.y, p0_nodeVar4.z );
	p0_nodeVar149 = ( ( ( p0_nodeVar148.x * 0.2126 ) + ( p0_nodeVar148.y * 0.7152 ) ) + ( p0_nodeVar148.z * 0.0722 ) );
	p0_nodeVar150 = mix( vec3<f32>( p0_nodeVar149, p0_nodeVar149, p0_nodeVar149 ), p0_nodeVar148, f32(1.0) );
	p0_nodeVar151 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar150.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar150.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar150.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar150.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar150.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar150.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar150.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar150.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar150.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar4.w, 0.0, 1.0 ) );
	p0_nodeVar153 = mix( clamp( p0_nodeVar0.w, 0.0, 1.0 ), clamp( p0_nodeVar151.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p0_nodeVar153 > 0.0 ) ) {

		p0_nodeVar152 = p0_nodeVar153;

	} else {

		p0_nodeVar152 = 1.0;

	}

	p0_DiffuseColor = vec4<f32>( ( mix( ( p0_nodeVar0.xyz * vec3<f32>( clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p0_nodeVar151.xyz, p0_nodeVar151.xyz, clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p0_nodeVar151.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p0_nodeVar152 ) ), p0_nodeVar153 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar154 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar154;

	// result

	p0_output.color = p0_nodeVar154;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

// Erosion: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
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
  erode: f32,
  resolution: vec2<f32>,
  seed: f32,
  speckleSize: f32,
  edgeWidth: f32,
  mode: f32,
  scatter: f32,
  output: f32,
  paperColor: vec3<f32>,
  clumping: f32,
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
var<private> nodeVar3 : vec4<f32>;
var<private> nodeVar4 : vec4<f32>;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec2<f32>;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : vec2<f32>;
var<private> nodeVar11 : vec2<f32>;
var<private> nodeVar12 : vec4<f32>;
var<private> nodeVar13 : vec4<f32>;
var<private> nodeVar14 : vec4<f32>;
var<private> nodeVar15 : vec4<f32>;
var<private> nodeVar16 : vec4<f32>;
var<private> nodeVar17 : vec4<f32>;
var<private> nodeVar18 : vec4<f32>;
var<private> nodeVar19 : vec4<f32>;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : f32;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : f32;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : f32;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : f32;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : f32;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : f32;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : f32;
var<private> nodeVar43 : f32;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : f32;
var<private> nodeVar47 : f32;
var<private> nodeVar48 : f32;
var<private> nodeVar49 : f32;
var<private> nodeVar50 : vec2<f32>;
var<private> nodeVar51 : vec3<f32>;
var<private> nodeVar52 : vec3<f32>;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : vec4<f32>;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : vec2<f32>;
var<private> nodeVar57 : vec3<f32>;
var<private> nodeVar58 : vec3<f32>;
var<private> nodeVar59 : vec2<f32>;
var<private> nodeVar60 : vec3<f32>;
var<private> nodeVar61 : vec3<f32>;
var<private> nodeVar62 : vec2<f32>;
var<private> nodeVar63 : vec4<f32>;
var<private> nodeVar64 : vec4<f32>;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : vec4<f32>;
var<private> nodeVar67 : vec4<f32>;
var<private> nodeVar68 : vec4<f32>;
var<private> nodeVar69 : vec4<f32>;
var<private> nodeVar70 : vec4<f32>;
var<private> nodeVar71 : vec4<f32>;
var<private> nodeVar72 : vec4<f32>;
var<private> nodeVar73 : vec4<f32>;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : f32;
var<private> nodeVar78 : f32;
var<private> nodeVar79 : f32;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : f32;
var<private> nodeVar82 : f32;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : f32;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : f32;
var<private> nodeVar89 : f32;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : f32;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : f32;
var<private> nodeVar94 : f32;
var<private> nodeVar95 : f32;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : f32;
var<private> nodeVar98 : f32;
var<private> nodeVar99 : f32;
var<private> nodeVar100 : f32;
var<private> nodeVar101 : f32;
var<private> nodeVar102 : f32;
var<private> nodeVar103 : f32;
var<private> nodeVar104 : vec3<f32>;
var<private> nodeVar105 : bool;
var<private> nodeVar106 : vec3<f32>;
var<private> nodeVar107 : vec3<f32>;
var<private> nodeVar108 : vec2<f32>;
var<private> nodeVar109 : vec2<f32>;
var<private> nodeVar110 : vec3<f32>;
var<private> nodeVar111 : vec3<f32>;
var<private> nodeVar112 : vec2<f32>;
var<private> nodeVar113 : vec3<f32>;
var<private> nodeVar114 : vec3<f32>;
var<private> nodeVar115 : vec2<f32>;
var<private> nodeVar116 : vec2<f32>;
var<private> nodeVar117 : vec2<f32>;
var<private> nodeVar118 : vec3<f32>;
var<private> nodeVar119 : vec3<f32>;
var<private> nodeVar120 : vec2<f32>;
var<private> nodeVar121 : vec3<f32>;
var<private> nodeVar122 : vec3<f32>;
var<private> nodeVar123 : vec2<f32>;
var<private> nodeVar124 : vec3<f32>;
var<private> nodeVar125 : vec3<f32>;
var<private> nodeVar126 : f32;
var<private> nodeVar127 : f32;
var<private> nodeVar128 : vec3<f32>;
var<private> nodeVar129 : vec3<f32>;
var<private> nodeVar130 : vec2<f32>;
var<private> nodeVar131 : vec2<f32>;
var<private> nodeVar132 : vec3<f32>;
var<private> nodeVar133 : vec3<f32>;
var<private> nodeVar134 : vec2<f32>;
var<private> nodeVar135 : vec3<f32>;
var<private> nodeVar136 : vec3<f32>;
var<private> nodeVar137 : vec2<f32>;
var<private> nodeVar138 : vec2<f32>;
var<private> nodeVar139 : vec2<f32>;
var<private> nodeVar140 : vec3<f32>;
var<private> nodeVar141 : vec3<f32>;
var<private> nodeVar142 : vec2<f32>;
var<private> nodeVar143 : vec3<f32>;
var<private> nodeVar144 : vec3<f32>;
var<private> nodeVar145 : vec2<f32>;
var<private> nodeVar146 : vec3<f32>;
var<private> nodeVar147 : vec3<f32>;
var<private> nodeVar148 : vec3<f32>;
var<private> nodeVar149 : f32;
var<private> nodeVar150 : vec3<f32>;
var<private> nodeVar151 : vec4<f32>;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : f32;
var<private> Output : vec4<f32>;
var<private> nodeVar154 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = picture_read_level( nodeVar1, 0.0 );
	nodeVar3 = nodeVar2;
	nodeVar4 = vec4<f32>( vec3<f32>( nodeVar3.x, nodeVar3.y, nodeVar3.z ), nodeVar3.w );

	if ( ( knobs.erode >= 0.0001 ) ) {

		nodeVar5 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
		nodeVar6 = vec2<f32>( ( 1.0 / nodeVar5.x ), ( 1.0 / nodeVar5.y ) );
		nodeVar7 = ( nodeVar1 * nodeVar5 );
		nodeVar8 = ( knobs.seed * 13.7 );
		nodeVar9 = floor( ( f32(0.0) * 8.0 ) );
		nodeVar10 = ( floor( ( nodeVar7 / vec2<f32>( knobs.speckleSize ) ) ) + vec2<f32>( nodeVar8, ( nodeVar9 * 1.37 ) ) );
		nodeVar11 = ( nodeVar6 * vec2<f32>( knobs.edgeWidth ) );
		nodeVar12 = picture_read_level( ( nodeVar1 + vec2<f32>( nodeVar11.x, 0.0 ) ), 0.0 );
		nodeVar13 = nodeVar12;
		nodeVar14 = picture_read_level( ( nodeVar1 - vec2<f32>( nodeVar11.x, 0.0 ) ), 0.0 );
		nodeVar15 = nodeVar14;
		nodeVar16 = picture_read_level( ( nodeVar1 + vec2<f32>( 0.0, nodeVar11.y ) ), 0.0 );
		nodeVar17 = nodeVar16;
		nodeVar18 = picture_read_level( ( nodeVar1 - vec2<f32>( 0.0, nodeVar11.y ) ), 0.0 );
		nodeVar19 = nodeVar18;
		nodeVar20 = 0.0;

		if ( ( knobs.mode < 0.5 ) ) {

			nodeVar22 = clamp( dot( vec3<f32>( nodeVar13.x, nodeVar13.y, nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( nodeVar22 <= 0.0031308 ) ) {

				nodeVar21 = ( nodeVar22 * 12.92 );

			} else {

				nodeVar21 = ( ( pow( nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			nodeVar24 = clamp( dot( vec3<f32>( nodeVar15.x, nodeVar15.y, nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( nodeVar24 <= 0.0031308 ) ) {

				nodeVar23 = ( nodeVar24 * 12.92 );

			} else {

				nodeVar23 = ( ( pow( nodeVar24, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			nodeVar26 = clamp( dot( vec3<f32>( nodeVar17.x, nodeVar17.y, nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( nodeVar26 <= 0.0031308 ) ) {

				nodeVar25 = ( nodeVar26 * 12.92 );

			} else {

				nodeVar25 = ( ( pow( nodeVar26, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			nodeVar28 = clamp( dot( vec3<f32>( nodeVar19.x, nodeVar19.y, nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( nodeVar28 <= 0.0031308 ) ) {

				nodeVar27 = ( nodeVar28 * 12.92 );

			} else {

				nodeVar27 = ( ( pow( nodeVar28, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			nodeVar20 = smoothstep( 0.1, 0.5, ( abs( ( nodeVar21 - nodeVar23 ) ) + abs( ( nodeVar25 - nodeVar27 ) ) ) );
			

		} else {


			if ( ( knobs.mode < 2.5 ) ) {


				if ( ( knobs.mode < 1.5 ) ) {

					nodeVar31 = clamp( dot( vec3<f32>( nodeVar3.x, nodeVar3.y, nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar31 <= 0.0031308 ) ) {

						nodeVar30 = ( nodeVar31 * 12.92 );

					} else {

						nodeVar30 = ( ( pow( nodeVar31, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar33 = clamp( dot( vec3<f32>( nodeVar13.x, nodeVar13.y, nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar33 <= 0.0031308 ) ) {

						nodeVar32 = ( nodeVar33 * 12.92 );

					} else {

						nodeVar32 = ( ( pow( nodeVar33, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar35 = clamp( dot( vec3<f32>( nodeVar15.x, nodeVar15.y, nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar35 <= 0.0031308 ) ) {

						nodeVar34 = ( nodeVar35 * 12.92 );

					} else {

						nodeVar34 = ( ( pow( nodeVar35, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar37 = clamp( dot( vec3<f32>( nodeVar17.x, nodeVar17.y, nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar37 <= 0.0031308 ) ) {

						nodeVar36 = ( nodeVar37 * 12.92 );

					} else {

						nodeVar36 = ( ( pow( nodeVar37, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar39 = clamp( dot( vec3<f32>( nodeVar19.x, nodeVar19.y, nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar39 <= 0.0031308 ) ) {

						nodeVar38 = ( nodeVar39 * 12.92 );

					} else {

						nodeVar38 = ( ( pow( nodeVar39, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar29 = smoothstep( 0.35, 0.95, ( ( ( ( ( ( nodeVar30 * 2.0 ) + nodeVar32 ) + nodeVar34 ) + nodeVar36 ) + nodeVar38 ) / 6.0 ) );

				} else {

					nodeVar41 = clamp( dot( vec3<f32>( nodeVar3.x, nodeVar3.y, nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar41 <= 0.0031308 ) ) {

						nodeVar40 = ( nodeVar41 * 12.92 );

					} else {

						nodeVar40 = ( ( pow( nodeVar41, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar43 = clamp( dot( vec3<f32>( nodeVar13.x, nodeVar13.y, nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar43 <= 0.0031308 ) ) {

						nodeVar42 = ( nodeVar43 * 12.92 );

					} else {

						nodeVar42 = ( ( pow( nodeVar43, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar45 = clamp( dot( vec3<f32>( nodeVar15.x, nodeVar15.y, nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar45 <= 0.0031308 ) ) {

						nodeVar44 = ( nodeVar45 * 12.92 );

					} else {

						nodeVar44 = ( ( pow( nodeVar45, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar47 = clamp( dot( vec3<f32>( nodeVar17.x, nodeVar17.y, nodeVar17.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar47 <= 0.0031308 ) ) {

						nodeVar46 = ( nodeVar47 * 12.92 );

					} else {

						nodeVar46 = ( ( pow( nodeVar47, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar49 = clamp( dot( vec3<f32>( nodeVar19.x, nodeVar19.y, nodeVar19.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

					if ( ( nodeVar49 <= 0.0031308 ) ) {

						nodeVar48 = ( nodeVar49 * 12.92 );

					} else {

						nodeVar48 = ( ( pow( nodeVar49, 0.4166666666666667 ) * 1.055 ) - 0.055 );

					}

					nodeVar29 = ( 1.0 - smoothstep( 0.05, 0.65, ( ( ( ( ( ( nodeVar40 * 2.0 ) + nodeVar42 ) + nodeVar44 ) + nodeVar46 ) + nodeVar48 ) / 6.0 ) ) );

				}

				nodeVar20 = nodeVar29;
				

			} else {

				nodeVar20 = ( 1.0 - smoothstep( 0.02, 0.98, ( ( ( ( ( ( nodeVar3.w * 2.0 ) + nodeVar13.w ) + nodeVar15.w ) + nodeVar17.w ) + nodeVar19.w ) / 6.0 ) ) );
				

			}

			

		}

		nodeVar50 = ( nodeVar10 + vec2<f32>( 7.7 ) );
		nodeVar51 = fract( ( vec3<f32>( nodeVar50.x, nodeVar50.y, nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar52 = ( nodeVar51 + vec3<f32>( dot( nodeVar51, ( vec3<f32>( nodeVar51.y, nodeVar51.z, nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar53 = ( ( ( ( knobs.scatter * min( nodeVar5.x, nodeVar5.y ) ) * 0.06 ) * nodeVar20 ) * fract( ( ( nodeVar52.x + nodeVar52.y ) * nodeVar52.z ) ) );
		nodeVar54 = nodeVar3;
		nodeVar55 = nodeVar20;

		if ( ( abs( nodeVar53 ) > 0.0 ) ) {

			nodeVar56 = ( nodeVar10 + vec2<f32>( 1.3 ) );
			nodeVar57 = fract( ( vec3<f32>( nodeVar56.x, nodeVar56.y, nodeVar56.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar58 = ( nodeVar57 + vec3<f32>( dot( nodeVar57, ( vec3<f32>( nodeVar57.y, nodeVar57.z, nodeVar57.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar59 = ( nodeVar10 + vec2<f32>( 2.9 ) );
			nodeVar60 = fract( ( vec3<f32>( nodeVar59.x, nodeVar59.y, nodeVar59.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar61 = ( nodeVar60 + vec3<f32>( dot( nodeVar60, ( vec3<f32>( nodeVar60.y, nodeVar60.z, nodeVar60.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar62 = ( nodeVar1 + ( ( ( ( vec2<f32>( fract( ( ( nodeVar58.x + nodeVar58.y ) * nodeVar58.z ) ), fract( ( ( nodeVar61.x + nodeVar61.y ) * nodeVar61.z ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( 2.0 ) ) * vec2<f32>( nodeVar53 ) ) * nodeVar6 ) );
			nodeVar63 = picture_read_level( nodeVar62, 0.0 );
			nodeVar64 = nodeVar63;
			nodeVar65 = ( nodeVar6 * vec2<f32>( knobs.edgeWidth ) );
			nodeVar66 = picture_read_level( ( nodeVar62 + vec2<f32>( nodeVar65.x, 0.0 ) ), 0.0 );
			nodeVar67 = nodeVar66;
			nodeVar68 = picture_read_level( ( nodeVar62 - vec2<f32>( nodeVar65.x, 0.0 ) ), 0.0 );
			nodeVar69 = nodeVar68;
			nodeVar70 = picture_read_level( ( nodeVar62 + vec2<f32>( 0.0, nodeVar65.y ) ), 0.0 );
			nodeVar71 = nodeVar70;
			nodeVar72 = picture_read_level( ( nodeVar62 - vec2<f32>( 0.0, nodeVar65.y ) ), 0.0 );
			nodeVar73 = nodeVar72;
			nodeVar74 = 0.0;

			if ( ( knobs.mode < 0.5 ) ) {

				nodeVar76 = clamp( dot( vec3<f32>( nodeVar67.x, nodeVar67.y, nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( nodeVar76 <= 0.0031308 ) ) {

					nodeVar75 = ( nodeVar76 * 12.92 );

				} else {

					nodeVar75 = ( ( pow( nodeVar76, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				nodeVar78 = clamp( dot( vec3<f32>( nodeVar69.x, nodeVar69.y, nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( nodeVar78 <= 0.0031308 ) ) {

					nodeVar77 = ( nodeVar78 * 12.92 );

				} else {

					nodeVar77 = ( ( pow( nodeVar78, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				nodeVar80 = clamp( dot( vec3<f32>( nodeVar71.x, nodeVar71.y, nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( nodeVar80 <= 0.0031308 ) ) {

					nodeVar79 = ( nodeVar80 * 12.92 );

				} else {

					nodeVar79 = ( ( pow( nodeVar80, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				nodeVar82 = clamp( dot( vec3<f32>( nodeVar73.x, nodeVar73.y, nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				if ( ( nodeVar82 <= 0.0031308 ) ) {

					nodeVar81 = ( nodeVar82 * 12.92 );

				} else {

					nodeVar81 = ( ( pow( nodeVar82, 0.4166666666666667 ) * 1.055 ) - 0.055 );

				}

				nodeVar74 = smoothstep( 0.1, 0.5, ( abs( ( nodeVar75 - nodeVar77 ) ) + abs( ( nodeVar79 - nodeVar81 ) ) ) );
				

			} else {


				if ( ( knobs.mode < 2.5 ) ) {


					if ( ( knobs.mode < 1.5 ) ) {

						nodeVar85 = clamp( dot( vec3<f32>( nodeVar64.x, nodeVar64.y, nodeVar64.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar85 <= 0.0031308 ) ) {

							nodeVar84 = ( nodeVar85 * 12.92 );

						} else {

							nodeVar84 = ( ( pow( nodeVar85, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar87 = clamp( dot( vec3<f32>( nodeVar67.x, nodeVar67.y, nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar87 <= 0.0031308 ) ) {

							nodeVar86 = ( nodeVar87 * 12.92 );

						} else {

							nodeVar86 = ( ( pow( nodeVar87, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar89 = clamp( dot( vec3<f32>( nodeVar69.x, nodeVar69.y, nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar89 <= 0.0031308 ) ) {

							nodeVar88 = ( nodeVar89 * 12.92 );

						} else {

							nodeVar88 = ( ( pow( nodeVar89, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar91 = clamp( dot( vec3<f32>( nodeVar71.x, nodeVar71.y, nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar91 <= 0.0031308 ) ) {

							nodeVar90 = ( nodeVar91 * 12.92 );

						} else {

							nodeVar90 = ( ( pow( nodeVar91, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar93 = clamp( dot( vec3<f32>( nodeVar73.x, nodeVar73.y, nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar93 <= 0.0031308 ) ) {

							nodeVar92 = ( nodeVar93 * 12.92 );

						} else {

							nodeVar92 = ( ( pow( nodeVar93, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar83 = smoothstep( 0.35, 0.95, ( ( ( ( ( ( nodeVar84 * 2.0 ) + nodeVar86 ) + nodeVar88 ) + nodeVar90 ) + nodeVar92 ) / 6.0 ) );

					} else {

						nodeVar95 = clamp( dot( vec3<f32>( nodeVar64.x, nodeVar64.y, nodeVar64.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar95 <= 0.0031308 ) ) {

							nodeVar94 = ( nodeVar95 * 12.92 );

						} else {

							nodeVar94 = ( ( pow( nodeVar95, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar97 = clamp( dot( vec3<f32>( nodeVar67.x, nodeVar67.y, nodeVar67.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar97 <= 0.0031308 ) ) {

							nodeVar96 = ( nodeVar97 * 12.92 );

						} else {

							nodeVar96 = ( ( pow( nodeVar97, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar99 = clamp( dot( vec3<f32>( nodeVar69.x, nodeVar69.y, nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar99 <= 0.0031308 ) ) {

							nodeVar98 = ( nodeVar99 * 12.92 );

						} else {

							nodeVar98 = ( ( pow( nodeVar99, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar101 = clamp( dot( vec3<f32>( nodeVar71.x, nodeVar71.y, nodeVar71.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar101 <= 0.0031308 ) ) {

							nodeVar100 = ( nodeVar101 * 12.92 );

						} else {

							nodeVar100 = ( ( pow( nodeVar101, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar103 = clamp( dot( vec3<f32>( nodeVar73.x, nodeVar73.y, nodeVar73.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

						if ( ( nodeVar103 <= 0.0031308 ) ) {

							nodeVar102 = ( nodeVar103 * 12.92 );

						} else {

							nodeVar102 = ( ( pow( nodeVar103, 0.4166666666666667 ) * 1.055 ) - 0.055 );

						}

						nodeVar83 = ( 1.0 - smoothstep( 0.05, 0.65, ( ( ( ( ( ( nodeVar94 * 2.0 ) + nodeVar96 ) + nodeVar98 ) + nodeVar100 ) + nodeVar102 ) / 6.0 ) ) );

					}

					nodeVar74 = nodeVar83;
					

				} else {

					nodeVar74 = ( 1.0 - smoothstep( 0.02, 0.98, ( ( ( ( ( ( nodeVar64.w * 2.0 ) + nodeVar67.w ) + nodeVar69.w ) + nodeVar71.w ) + nodeVar73.w ) / 6.0 ) ) );
					

				}

				

			}

			nodeVar55 = nodeVar74;
			nodeVar54 = nodeVar64;
			

		}

		nodeVar105 = ( (1 * knobs.output + 0) > 0.5 );

		if ( nodeVar105 ) {

			nodeVar104 = vec3<f32>( nodeVar54.x, nodeVar54.y, nodeVar54.z );

		} else {

			nodeVar106 = fract( ( vec3<f32>( nodeVar10.x, nodeVar10.y, nodeVar10.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar107 = ( nodeVar106 + vec3<f32>( dot( nodeVar106, ( vec3<f32>( nodeVar106.y, nodeVar106.z, nodeVar106.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar108 = ( ( nodeVar7 / vec2<f32>( ( knobs.speckleSize * 7.0 ) ) ) + vec2<f32>( nodeVar8, nodeVar9 ) );
			nodeVar109 = floor( nodeVar108 );
			nodeVar110 = fract( ( vec3<f32>( nodeVar109.x, nodeVar109.y, nodeVar109.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar111 = ( nodeVar110 + vec3<f32>( dot( nodeVar110, ( vec3<f32>( nodeVar110.y, nodeVar110.z, nodeVar110.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar112 = ( nodeVar109 + vec2<f32>( 1.0, 0.0 ) );
			nodeVar113 = fract( ( vec3<f32>( nodeVar112.x, nodeVar112.y, nodeVar112.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar114 = ( nodeVar113 + vec3<f32>( dot( nodeVar113, ( vec3<f32>( nodeVar113.y, nodeVar113.z, nodeVar113.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar115 = fract( nodeVar108 );
			nodeVar116 = ( ( nodeVar115 * nodeVar115 ) * ( vec2<f32>( 3.0 ) - ( nodeVar115 * vec2<f32>( 2.0 ) ) ) );
			nodeVar117 = ( nodeVar109 + vec2<f32>( 0.0, 1.0 ) );
			nodeVar118 = fract( ( vec3<f32>( nodeVar117.x, nodeVar117.y, nodeVar117.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar119 = ( nodeVar118 + vec3<f32>( dot( nodeVar118, ( vec3<f32>( nodeVar118.y, nodeVar118.z, nodeVar118.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar120 = ( nodeVar109 + vec2<f32>( 1.0, 1.0 ) );
			nodeVar121 = fract( ( vec3<f32>( nodeVar120.x, nodeVar120.y, nodeVar120.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar122 = ( nodeVar121 + vec3<f32>( dot( nodeVar121, ( vec3<f32>( nodeVar121.y, nodeVar121.z, nodeVar121.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar123 = ( nodeVar10 + vec2<f32>( 5.3 ) );
			nodeVar124 = fract( ( vec3<f32>( nodeVar123.x, nodeVar123.y, nodeVar123.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar125 = ( nodeVar124 + vec3<f32>( dot( nodeVar124, ( vec3<f32>( nodeVar124.y, nodeVar124.z, nodeVar124.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar104 = mix( vec3<f32>( nodeVar54.x, nodeVar54.y, nodeVar54.z ), knobs.paperColor, ( ( ( 1.0 - step( clamp( ( ( nodeVar55 * ( knobs.erode * 2.5 ) ) - ( ( 1.0 - knobs.erode ) * 0.25 ) ), 0.0, 1.0 ), mix( fract( ( ( nodeVar107.x + nodeVar107.y ) * nodeVar107.z ) ), mix( mix( fract( ( ( nodeVar111.x + nodeVar111.y ) * nodeVar111.z ) ), fract( ( ( nodeVar114.x + nodeVar114.y ) * nodeVar114.z ) ), nodeVar116.x ), mix( fract( ( ( nodeVar119.x + nodeVar119.y ) * nodeVar119.z ) ), fract( ( ( nodeVar122.x + nodeVar122.y ) * nodeVar122.z ) ), nodeVar116.x ), nodeVar116.y ), knobs.clumping ) ) ) * ( 1.0 - ( 1.0 - step( ( ( knobs.scatter * 0.55 ) * nodeVar20 ), fract( ( ( nodeVar125.x + nodeVar125.y ) * nodeVar125.z ) ) ) ) ) ) * step( 0.0001, knobs.erode ) ) );

		}

		nodeVar126 = step( 0.0001, knobs.erode );

		if ( nodeVar105 ) {

			nodeVar128 = fract( ( vec3<f32>( nodeVar10.x, nodeVar10.y, nodeVar10.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar129 = ( nodeVar128 + vec3<f32>( dot( nodeVar128, ( vec3<f32>( nodeVar128.y, nodeVar128.z, nodeVar128.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar130 = ( ( nodeVar7 / vec2<f32>( ( knobs.speckleSize * 7.0 ) ) ) + vec2<f32>( nodeVar8, nodeVar9 ) );
			nodeVar131 = floor( nodeVar130 );
			nodeVar132 = fract( ( vec3<f32>( nodeVar131.x, nodeVar131.y, nodeVar131.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar133 = ( nodeVar132 + vec3<f32>( dot( nodeVar132, ( vec3<f32>( nodeVar132.y, nodeVar132.z, nodeVar132.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar134 = ( nodeVar131 + vec2<f32>( 1.0, 0.0 ) );
			nodeVar135 = fract( ( vec3<f32>( nodeVar134.x, nodeVar134.y, nodeVar134.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar136 = ( nodeVar135 + vec3<f32>( dot( nodeVar135, ( vec3<f32>( nodeVar135.y, nodeVar135.z, nodeVar135.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar137 = fract( nodeVar130 );
			nodeVar138 = ( ( nodeVar137 * nodeVar137 ) * ( vec2<f32>( 3.0 ) - ( nodeVar137 * vec2<f32>( 2.0 ) ) ) );
			nodeVar139 = ( nodeVar131 + vec2<f32>( 0.0, 1.0 ) );
			nodeVar140 = fract( ( vec3<f32>( nodeVar139.x, nodeVar139.y, nodeVar139.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar141 = ( nodeVar140 + vec3<f32>( dot( nodeVar140, ( vec3<f32>( nodeVar140.y, nodeVar140.z, nodeVar140.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar142 = ( nodeVar131 + vec2<f32>( 1.0, 1.0 ) );
			nodeVar143 = fract( ( vec3<f32>( nodeVar142.x, nodeVar142.y, nodeVar142.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar144 = ( nodeVar143 + vec3<f32>( dot( nodeVar143, ( vec3<f32>( nodeVar143.y, nodeVar143.z, nodeVar143.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar145 = ( nodeVar10 + vec2<f32>( 5.3 ) );
			nodeVar146 = fract( ( vec3<f32>( nodeVar145.x, nodeVar145.y, nodeVar145.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar147 = ( nodeVar146 + vec3<f32>( dot( nodeVar146, ( vec3<f32>( nodeVar146.y, nodeVar146.z, nodeVar146.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar127 = ( clamp( nodeVar54.w, 0.0, 1.0 ) * ( 1.0 - ( ( ( 1.0 - step( clamp( ( ( nodeVar55 * ( knobs.erode * 2.5 ) ) - ( ( 1.0 - knobs.erode ) * 0.25 ) ), 0.0, 1.0 ), mix( fract( ( ( nodeVar129.x + nodeVar129.y ) * nodeVar129.z ) ), mix( mix( fract( ( ( nodeVar133.x + nodeVar133.y ) * nodeVar133.z ) ), fract( ( ( nodeVar136.x + nodeVar136.y ) * nodeVar136.z ) ), nodeVar138.x ), mix( fract( ( ( nodeVar141.x + nodeVar141.y ) * nodeVar141.z ) ), fract( ( ( nodeVar144.x + nodeVar144.y ) * nodeVar144.z ) ), nodeVar138.x ), nodeVar138.y ), knobs.clumping ) ) ) * ( 1.0 - ( 1.0 - step( ( ( knobs.scatter * 0.55 ) * nodeVar20 ), fract( ( ( nodeVar147.x + nodeVar147.y ) * nodeVar147.z ) ) ) ) ) ) * nodeVar126 ) ) );

		} else {

			nodeVar127 = clamp( nodeVar54.w, 0.0, 1.0 );

		}

		nodeVar4 = vec4<f32>( mix( vec3<f32>( nodeVar3.x, nodeVar3.y, nodeVar3.z ), nodeVar104, nodeVar126 ), mix( nodeVar3.w, nodeVar127, nodeVar126 ) );
		

	}

	nodeVar148 = vec3<f32>( nodeVar4.x, nodeVar4.y, nodeVar4.z );
	nodeVar149 = ( ( ( nodeVar148.x * 0.2126 ) + ( nodeVar148.y * 0.7152 ) ) + ( nodeVar148.z * 0.0722 ) );
	nodeVar150 = mix( vec3<f32>( nodeVar149, nodeVar149, nodeVar149 ), nodeVar148, f32(1.0) );
	nodeVar151 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar150.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar150.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar150.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar150.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar150.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar150.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar150.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar150.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar150.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar4.w, 0.0, 1.0 ) );
	nodeVar153 = mix( clamp( nodeVar0.w, 0.0, 1.0 ), clamp( nodeVar151.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( nodeVar153 > 0.0 ) ) {

		nodeVar152 = nodeVar153;

	} else {

		nodeVar152 = 1.0;

	}

	DiffuseColor = vec4<f32>( ( mix( ( nodeVar0.xyz * vec3<f32>( clamp( nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( nodeVar151.xyz, nodeVar151.xyz, clamp( nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( nodeVar151.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( nodeVar152 ) ), nodeVar153 );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar154 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar154;

	// result

	output.color = nodeVar154;

	output.color = to_shelf(output.color);
	return output;

}

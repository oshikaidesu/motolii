// Signal Rot: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:A failing scan: dragged streaks, wobble, torn bands, color drift and line noise.
// --check@direction:Streaks,0
// --track@drag:Drag,0,1,0.55,0.01
// --track@dragLength:Drag Length,0.01,1,0.35,0.01
// --track@stretch:Stretch,0,1,0.35,0.01
// --track@wobble:Wobble,0,1,0.45,0.01
// --track@wobbleScale:Wobble Scale,0.02,2,0.35,0.01
// --track@tear:Tear,0,1,0.25,0.01
// --track@bandSize:Band Size,0.01,0.5,0.14,0.01
// --track@dropout:Dropout,0,1,0.3,0.01
// --track@dropoutColor_x:Dropout Color r,0,1,1,0.001
// --track@dropoutColor_y:Dropout Color g,0,1,1,0.001
// --track@dropoutColor_z:Dropout Color b,0,1,1,0.001
// --track@chroma:Chroma Shift,0,1,0,0.01
// --track@crush:Crush,0,1,0,0.01
// --track@lineNoise:Line Noise,0,1,0,0.01
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
  resolution: vec2<f32>,
  direction: f32,
  seed: f32,
  tear: f32,
  dropout: f32,
  bandSize: f32,
  wobble: f32,
  wobbleScale: f32,
  stretch: f32,
  drag: f32,
  dragLength: f32,
  lineNoise: f32,
  chroma: f32,
  crush: f32,
  dropoutColor: vec3<f32>,
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
var<private> nodeVar3 : f32;
var<private> nodeVar4 : bool;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : f32;
var<private> nodeVar7 : f32;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : f32;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : vec2<f32>;
var<private> nodeVar21 : vec3<f32>;
var<private> nodeVar22 : vec3<f32>;
var<private> nodeVar23 : vec2<f32>;
var<private> nodeVar24 : vec3<f32>;
var<private> nodeVar25 : vec3<f32>;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : vec2<f32>;
var<private> nodeVar30 : vec3<f32>;
var<private> nodeVar31 : vec3<f32>;
var<private> nodeVar32 : vec2<f32>;
var<private> nodeVar33 : vec3<f32>;
var<private> nodeVar34 : vec3<f32>;
var<private> nodeVar35 : f32;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : vec2<f32>;
var<private> nodeVar39 : vec3<f32>;
var<private> nodeVar40 : vec3<f32>;
var<private> nodeVar41 : vec2<f32>;
var<private> nodeVar42 : vec3<f32>;
var<private> nodeVar43 : vec3<f32>;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : f32;
var<private> nodeVar47 : vec2<f32>;
var<private> nodeVar48 : vec3<f32>;
var<private> nodeVar49 : vec3<f32>;
var<private> nodeVar50 : vec2<f32>;
var<private> nodeVar51 : vec3<f32>;
var<private> nodeVar52 : vec3<f32>;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : vec2<f32>;
var<private> nodeVar55 : vec3<f32>;
var<private> nodeVar56 : vec3<f32>;
var<private> nodeVar57 : vec2<f32>;
var<private> nodeVar58 : vec3<f32>;
var<private> nodeVar59 : vec3<f32>;
var<private> nodeVar60 : vec2<f32>;
var<private> nodeVar61 : vec3<f32>;
var<private> nodeVar62 : vec3<f32>;
var<private> nodeVar63 : vec2<f32>;
var<private> nodeVar64 : vec3<f32>;
var<private> nodeVar65 : vec3<f32>;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : vec2<f32>;
var<private> nodeVar69 : vec3<f32>;
var<private> nodeVar70 : vec3<f32>;
var<private> nodeVar71 : vec2<f32>;
var<private> nodeVar72 : vec3<f32>;
var<private> nodeVar73 : vec3<f32>;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : vec2<f32>;
var<private> nodeVar78 : vec3<f32>;
var<private> nodeVar79 : vec3<f32>;
var<private> nodeVar80 : vec2<f32>;
var<private> nodeVar81 : vec3<f32>;
var<private> nodeVar82 : vec3<f32>;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : f32;
var<private> nodeVar86 : vec2<f32>;
var<private> nodeVar87 : vec3<f32>;
var<private> nodeVar88 : vec3<f32>;
var<private> nodeVar89 : vec2<f32>;
var<private> nodeVar90 : vec3<f32>;
var<private> nodeVar91 : vec3<f32>;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : vec2<f32>;
var<private> nodeVar94 : vec3<f32>;
var<private> nodeVar95 : vec3<f32>;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : f32;
var<private> nodeVar98 : vec2<f32>;
var<private> nodeVar99 : vec3<f32>;
var<private> nodeVar100 : vec3<f32>;
var<private> nodeVar101 : vec2<f32>;
var<private> nodeVar102 : vec3<f32>;
var<private> nodeVar103 : vec3<f32>;
var<private> nodeVar104 : f32;
var<private> nodeVar105 : f32;
var<private> nodeVar106 : f32;
var<private> nodeVar107 : vec2<f32>;
var<private> nodeVar108 : vec3<f32>;
var<private> nodeVar109 : vec3<f32>;
var<private> nodeVar110 : vec2<f32>;
var<private> nodeVar111 : vec3<f32>;
var<private> nodeVar112 : vec3<f32>;
var<private> nodeVar113 : f32;
var<private> nodeVar114 : f32;
var<private> nodeVar115 : f32;
var<private> nodeVar116 : vec2<f32>;
var<private> nodeVar117 : vec3<f32>;
var<private> nodeVar118 : vec3<f32>;
var<private> nodeVar119 : vec2<f32>;
var<private> nodeVar120 : vec3<f32>;
var<private> nodeVar121 : vec3<f32>;
var<private> nodeVar122 : f32;
var<private> nodeVar123 : f32;
var<private> nodeVar124 : f32;
var<private> nodeVar125 : f32;
var<private> nodeVar126 : vec2<f32>;
var<private> nodeVar127 : vec3<f32>;
var<private> nodeVar128 : vec3<f32>;
var<private> nodeVar129 : vec2<f32>;
var<private> nodeVar130 : vec3<f32>;
var<private> nodeVar131 : vec3<f32>;
var<private> nodeVar132 : f32;
var<private> nodeVar133 : f32;
var<private> nodeVar134 : f32;
var<private> nodeVar135 : vec2<f32>;
var<private> nodeVar136 : vec3<f32>;
var<private> nodeVar137 : vec3<f32>;
var<private> nodeVar138 : vec2<f32>;
var<private> nodeVar139 : vec3<f32>;
var<private> nodeVar140 : vec3<f32>;
var<private> nodeVar141 : f32;
var<private> nodeVar142 : f32;
var<private> nodeVar143 : f32;
var<private> nodeVar144 : vec2<f32>;
var<private> nodeVar145 : vec3<f32>;
var<private> nodeVar146 : vec3<f32>;
var<private> nodeVar147 : vec2<f32>;
var<private> nodeVar148 : vec3<f32>;
var<private> nodeVar149 : vec3<f32>;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : f32;
var<private> nodeVar154 : vec2<f32>;
var<private> nodeVar155 : vec3<f32>;
var<private> nodeVar156 : vec3<f32>;
var<private> nodeVar157 : vec2<f32>;
var<private> nodeVar158 : vec3<f32>;
var<private> nodeVar159 : vec3<f32>;
var<private> nodeVar160 : f32;
var<private> nodeVar161 : f32;
var<private> nodeVar162 : f32;
var<private> nodeVar163 : vec2<f32>;
var<private> nodeVar164 : vec3<f32>;
var<private> nodeVar165 : vec3<f32>;
var<private> nodeVar166 : vec2<f32>;
var<private> nodeVar167 : vec3<f32>;
var<private> nodeVar168 : vec3<f32>;
var<private> nodeVar169 : f32;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : vec2<f32>;
var<private> nodeVar173 : vec3<f32>;
var<private> nodeVar174 : vec3<f32>;
var<private> nodeVar175 : vec2<f32>;
var<private> nodeVar176 : vec3<f32>;
var<private> nodeVar177 : vec3<f32>;
var<private> nodeVar178 : f32;
var<private> nodeVar179 : f32;
var<private> nodeVar180 : f32;
var<private> nodeVar181 : vec2<f32>;
var<private> nodeVar182 : vec3<f32>;
var<private> nodeVar183 : vec3<f32>;
var<private> nodeVar184 : vec2<f32>;
var<private> nodeVar185 : vec3<f32>;
var<private> nodeVar186 : vec3<f32>;
var<private> nodeVar187 : f32;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : f32;
var<private> nodeVar190 : vec2<f32>;
var<private> nodeVar191 : vec3<f32>;
var<private> nodeVar192 : vec3<f32>;
var<private> nodeVar193 : f32;
var<private> nodeVar194 : vec2<f32>;
var<private> nodeVar195 : vec3<f32>;
var<private> nodeVar196 : vec3<f32>;
var<private> nodeVar197 : vec2<f32>;
var<private> nodeVar198 : vec3<f32>;
var<private> nodeVar199 : vec3<f32>;
var<private> nodeVar200 : vec2<f32>;
var<private> nodeVar201 : vec4<f32>;
var<private> nodeVar202 : vec4<f32>;
var<private> nodeVar203 : vec3<f32>;
var<private> nodeVar204 : f32;
var<private> nodeVar205 : vec2<f32>;
var<private> nodeVar206 : vec4<f32>;
var<private> nodeVar207 : vec2<f32>;
var<private> nodeVar208 : vec4<f32>;
var<private> nodeVar209 : f32;
var<private> nodeVar210 : vec2<f32>;
var<private> nodeVar211 : vec3<f32>;
var<private> nodeVar212 : vec3<f32>;
var<private> nodeVar213 : vec4<f32>;
var<private> nodeVar214 : vec3<f32>;
var<private> nodeVar215 : f32;
var<private> nodeVar216 : vec3<f32>;
var<private> nodeVar217 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar218 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
	nodeVar2 = ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * nodeVar1 );
	nodeVar4 = ( (-1 * knobs.direction + 1) > 0.5 );

	if ( nodeVar4 ) {

		nodeVar3 = nodeVar2.y;

	} else {

		nodeVar3 = nodeVar2.x;

	}

	nodeVar5 = nodeVar3;

	if ( nodeVar4 ) {

		nodeVar6 = nodeVar2.x;

	} else {

		nodeVar6 = nodeVar2.y;

	}

	nodeVar7 = nodeVar6;

	if ( nodeVar4 ) {

		nodeVar8 = nodeVar1.y;

	} else {

		nodeVar8 = nodeVar1.x;

	}

	nodeVar9 = nodeVar8;

	if ( nodeVar4 ) {

		nodeVar10 = nodeVar1.x;

	} else {

		nodeVar10 = nodeVar1.y;

	}

	nodeVar11 = nodeVar10;
	nodeVar12 = min( nodeVar1.x, nodeVar1.y );
	nodeVar13 = ( knobs.seed * 7.31 );
	nodeVar14 = floor( ( f32(0.0) * 8.0 ) );
	nodeVar15 = nodeVar7;
	nodeVar16 = 0.0;

	if ( ( ( knobs.tear > 0.0 ) || ( knobs.dropout >= 0.0001 ) ) ) {

		nodeVar17 = ( knobs.bandSize * nodeVar9 );
		nodeVar18 = ( ( nodeVar7 / ( nodeVar12 * 0.08 ) ) + nodeVar13 );
		nodeVar19 = floor( nodeVar18 );
		nodeVar20 = vec2<f32>( nodeVar19, 11.0 );
		nodeVar21 = fract( ( vec3<f32>( nodeVar20.x, nodeVar20.y, nodeVar20.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar22 = ( nodeVar21 + vec3<f32>( dot( nodeVar21, ( vec3<f32>( nodeVar21.y, nodeVar21.z, nodeVar21.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar23 = vec2<f32>( ( nodeVar19 + 1.0 ), 11.0 );
		nodeVar24 = fract( ( vec3<f32>( nodeVar23.x, nodeVar23.y, nodeVar23.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar25 = ( nodeVar24 + vec3<f32>( dot( nodeVar24, ( vec3<f32>( nodeVar24.y, nodeVar24.z, nodeVar24.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar26 = fract( nodeVar18 );
		nodeVar27 = ( ( nodeVar18 * 2.3 ) + 17.1 );
		nodeVar28 = floor( nodeVar27 );
		nodeVar29 = vec2<f32>( nodeVar28, 12.0 );
		nodeVar30 = fract( ( vec3<f32>( nodeVar29.x, nodeVar29.y, nodeVar29.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar31 = ( nodeVar30 + vec3<f32>( dot( nodeVar30, ( vec3<f32>( nodeVar30.y, nodeVar30.z, nodeVar30.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar32 = vec2<f32>( ( nodeVar28 + 1.0 ), 12.0 );
		nodeVar33 = fract( ( vec3<f32>( nodeVar32.x, nodeVar32.y, nodeVar32.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar34 = ( nodeVar33 + vec3<f32>( dot( nodeVar33, ( vec3<f32>( nodeVar33.y, nodeVar33.z, nodeVar33.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar35 = fract( nodeVar27 );
		nodeVar36 = ( ( nodeVar18 * 5.1 ) + 3.7 );
		nodeVar37 = floor( nodeVar36 );
		nodeVar38 = vec2<f32>( nodeVar37, 13.0 );
		nodeVar39 = fract( ( vec3<f32>( nodeVar38.x, nodeVar38.y, nodeVar38.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar40 = ( nodeVar39 + vec3<f32>( dot( nodeVar39, ( vec3<f32>( nodeVar39.y, nodeVar39.z, nodeVar39.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar41 = vec2<f32>( ( nodeVar37 + 1.0 ), 13.0 );
		nodeVar42 = fract( ( vec3<f32>( nodeVar41.x, nodeVar41.y, nodeVar41.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar43 = ( nodeVar42 + vec3<f32>( dot( nodeVar42, ( vec3<f32>( nodeVar42.y, nodeVar42.z, nodeVar42.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar44 = fract( nodeVar36 );
		nodeVar45 = ( ( nodeVar7 / 3.0 ) + nodeVar13 );
		nodeVar46 = floor( nodeVar45 );
		nodeVar47 = vec2<f32>( nodeVar46, 14.0 );
		nodeVar48 = fract( ( vec3<f32>( nodeVar47.x, nodeVar47.y, nodeVar47.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar49 = ( nodeVar48 + vec3<f32>( dot( nodeVar48, ( vec3<f32>( nodeVar48.y, nodeVar48.z, nodeVar48.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar50 = vec2<f32>( ( nodeVar46 + 1.0 ), 14.0 );
		nodeVar51 = fract( ( vec3<f32>( nodeVar50.x, nodeVar50.y, nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar52 = ( nodeVar51 + vec3<f32>( dot( nodeVar51, ( vec3<f32>( nodeVar51.y, nodeVar51.z, nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar53 = fract( nodeVar45 );
		nodeVar54 = vec2<f32>( ( floor( ( ( nodeVar5 + ( ( ( ( ( ( mix( fract( ( ( nodeVar22.x + nodeVar22.y ) * nodeVar22.z ) ), fract( ( ( nodeVar25.x + nodeVar25.y ) * nodeVar25.z ) ), ( ( nodeVar26 * nodeVar26 ) * ( 3.0 - ( nodeVar26 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( nodeVar31.x + nodeVar31.y ) * nodeVar31.z ) ), fract( ( ( nodeVar34.x + nodeVar34.y ) * nodeVar34.z ) ), ( ( nodeVar35 * nodeVar35 ) * ( 3.0 - ( nodeVar35 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( nodeVar40.x + nodeVar40.y ) * nodeVar40.z ) ), fract( ( ( nodeVar43.x + nodeVar43.y ) * nodeVar43.z ) ), ( ( nodeVar44 * nodeVar44 ) * ( 3.0 - ( nodeVar44 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * ( nodeVar17 * 0.4 ) ) + ( ( mix( fract( ( ( nodeVar49.x + nodeVar49.y ) * nodeVar49.z ) ), fract( ( ( nodeVar52.x + nodeVar52.y ) * nodeVar52.z ) ), ( ( nodeVar53 * nodeVar53 ) * ( 3.0 - ( nodeVar53 * 2.0 ) ) ) ) - 0.5 ) * ( nodeVar17 * 0.04 ) ) ) ) / nodeVar17 ) ) + nodeVar13 ), nodeVar14 );

		if ( ( knobs.tear > 0.0 ) ) {

			nodeVar55 = fract( ( vec3<f32>( nodeVar54.x, nodeVar54.y, nodeVar54.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar56 = ( nodeVar55 + vec3<f32>( dot( nodeVar55, ( vec3<f32>( nodeVar55.y, nodeVar55.z, nodeVar55.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar57 = ( nodeVar54 + vec2<f32>( 4.1 ) );
			nodeVar58 = fract( ( vec3<f32>( nodeVar57.x, nodeVar57.y, nodeVar57.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar59 = ( nodeVar58 + vec3<f32>( dot( nodeVar58, ( vec3<f32>( nodeVar58.y, nodeVar58.z, nodeVar58.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar15 = ( nodeVar7 + ( ( ( ( ( ( fract( ( ( nodeVar56.x + nodeVar56.y ) * nodeVar56.z ) ) - 0.5 ) * 2.0 ) * knobs.tear ) * nodeVar11 ) * 0.3 ) * step( fract( ( ( nodeVar59.x + nodeVar59.y ) * nodeVar59.z ) ), ( ( knobs.tear * 0.6 ) + 0.4 ) ) ) );
			

		}


		if ( ( knobs.dropout >= 0.0001 ) ) {

			nodeVar60 = ( nodeVar54 + vec2<f32>( 2.3 ) );
			nodeVar61 = fract( ( vec3<f32>( nodeVar60.x, nodeVar60.y, nodeVar60.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar62 = ( nodeVar61 + vec3<f32>( dot( nodeVar61, ( vec3<f32>( nodeVar61.y, nodeVar61.z, nodeVar61.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar63 = ( nodeVar54 + vec2<f32>( 9.7 ) );
			nodeVar64 = fract( ( vec3<f32>( nodeVar63.x, nodeVar63.y, nodeVar63.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar65 = ( nodeVar64 + vec3<f32>( dot( nodeVar64, ( vec3<f32>( nodeVar64.y, nodeVar64.z, nodeVar64.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar66 = ( ( nodeVar5 / 19.0 ) + nodeVar13 );
			nodeVar67 = floor( nodeVar66 );
			nodeVar68 = vec2<f32>( nodeVar67, 23.0 );
			nodeVar69 = fract( ( vec3<f32>( nodeVar68.x, nodeVar68.y, nodeVar68.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar70 = ( nodeVar69 + vec3<f32>( dot( nodeVar69, ( vec3<f32>( nodeVar69.y, nodeVar69.z, nodeVar69.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar71 = vec2<f32>( ( nodeVar67 + 1.0 ), 23.0 );
			nodeVar72 = fract( ( vec3<f32>( nodeVar71.x, nodeVar71.y, nodeVar71.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar73 = ( nodeVar72 + vec3<f32>( dot( nodeVar72, ( vec3<f32>( nodeVar72.y, nodeVar72.z, nodeVar72.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar74 = fract( nodeVar66 );
			nodeVar75 = ( ( nodeVar66 * 2.3 ) + 17.1 );
			nodeVar76 = floor( nodeVar75 );
			nodeVar77 = vec2<f32>( nodeVar76, 24.0 );
			nodeVar78 = fract( ( vec3<f32>( nodeVar77.x, nodeVar77.y, nodeVar77.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar79 = ( nodeVar78 + vec3<f32>( dot( nodeVar78, ( vec3<f32>( nodeVar78.y, nodeVar78.z, nodeVar78.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar80 = vec2<f32>( ( nodeVar76 + 1.0 ), 24.0 );
			nodeVar81 = fract( ( vec3<f32>( nodeVar80.x, nodeVar80.y, nodeVar80.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar82 = ( nodeVar81 + vec3<f32>( dot( nodeVar81, ( vec3<f32>( nodeVar81.y, nodeVar81.z, nodeVar81.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar83 = fract( nodeVar75 );
			nodeVar84 = ( ( nodeVar66 * 5.1 ) + 3.7 );
			nodeVar85 = floor( nodeVar84 );
			nodeVar86 = vec2<f32>( nodeVar85, 25.0 );
			nodeVar87 = fract( ( vec3<f32>( nodeVar86.x, nodeVar86.y, nodeVar86.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar88 = ( nodeVar87 + vec3<f32>( dot( nodeVar87, ( vec3<f32>( nodeVar87.y, nodeVar87.z, nodeVar87.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar89 = vec2<f32>( ( nodeVar85 + 1.0 ), 25.0 );
			nodeVar90 = fract( ( vec3<f32>( nodeVar89.x, nodeVar89.y, nodeVar89.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar91 = ( nodeVar90 + vec3<f32>( dot( nodeVar90, ( vec3<f32>( nodeVar90.y, nodeVar90.z, nodeVar90.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar92 = fract( nodeVar84 );
			nodeVar93 = vec2<f32>( floor( ( nodeVar5 / 1.5 ) ), ( nodeVar13 + 23.0 ) );
			nodeVar94 = fract( ( vec3<f32>( nodeVar93.x, nodeVar93.y, nodeVar93.x ) * vec3<f32>( 0.1031 ) ) );
			nodeVar95 = ( nodeVar94 + vec3<f32>( dot( nodeVar94, ( vec3<f32>( nodeVar94.y, nodeVar94.z, nodeVar94.x ) + vec3<f32>( 33.33 ) ) ) ) );
			nodeVar16 = ( ( step( fract( ( ( nodeVar62.x + nodeVar62.y ) * nodeVar62.z ) ), knobs.dropout ) * step( ( nodeVar7 / nodeVar11 ), ( ( ( fract( ( ( nodeVar65.x + nodeVar65.y ) * nodeVar65.z ) ) * 0.7 ) + ( ( ( ( ( mix( fract( ( ( nodeVar70.x + nodeVar70.y ) * nodeVar70.z ) ), fract( ( ( nodeVar73.x + nodeVar73.y ) * nodeVar73.z ) ), ( ( nodeVar74 * nodeVar74 ) * ( 3.0 - ( nodeVar74 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( nodeVar79.x + nodeVar79.y ) * nodeVar79.z ) ), fract( ( ( nodeVar82.x + nodeVar82.y ) * nodeVar82.z ) ), ( ( nodeVar83 * nodeVar83 ) * ( 3.0 - ( nodeVar83 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( nodeVar88.x + nodeVar88.y ) * nodeVar88.z ) ), fract( ( ( nodeVar91.x + nodeVar91.y ) * nodeVar91.z ) ), ( ( nodeVar92 * nodeVar92 ) * ( 3.0 - ( nodeVar92 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * 0.06 ) ) + ( fract( ( ( nodeVar95.x + nodeVar95.y ) * nodeVar95.z ) ) * 0.012 ) ) ) ) * step( 0.0001, knobs.dropout ) );
			

		}

		

	}


	if ( ( knobs.wobble > 0.0 ) ) {

		nodeVar96 = ( ( ( nodeVar5 / ( knobs.wobbleScale * nodeVar12 ) ) + nodeVar13 ) + ( f32(0.0) * 0.6 ) );
		nodeVar97 = floor( nodeVar96 );
		nodeVar98 = vec2<f32>( nodeVar97, 31.0 );
		nodeVar99 = fract( ( vec3<f32>( nodeVar98.x, nodeVar98.y, nodeVar98.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar100 = ( nodeVar99 + vec3<f32>( dot( nodeVar99, ( vec3<f32>( nodeVar99.y, nodeVar99.z, nodeVar99.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar101 = vec2<f32>( ( nodeVar97 + 1.0 ), 31.0 );
		nodeVar102 = fract( ( vec3<f32>( nodeVar101.x, nodeVar101.y, nodeVar101.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar103 = ( nodeVar102 + vec3<f32>( dot( nodeVar102, ( vec3<f32>( nodeVar102.y, nodeVar102.z, nodeVar102.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar104 = fract( nodeVar96 );
		nodeVar105 = ( ( nodeVar96 * 2.3 ) + 17.1 );
		nodeVar106 = floor( nodeVar105 );
		nodeVar107 = vec2<f32>( nodeVar106, 32.0 );
		nodeVar108 = fract( ( vec3<f32>( nodeVar107.x, nodeVar107.y, nodeVar107.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar109 = ( nodeVar108 + vec3<f32>( dot( nodeVar108, ( vec3<f32>( nodeVar108.y, nodeVar108.z, nodeVar108.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar110 = vec2<f32>( ( nodeVar106 + 1.0 ), 32.0 );
		nodeVar111 = fract( ( vec3<f32>( nodeVar110.x, nodeVar110.y, nodeVar110.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar112 = ( nodeVar111 + vec3<f32>( dot( nodeVar111, ( vec3<f32>( nodeVar111.y, nodeVar111.z, nodeVar111.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar113 = fract( nodeVar105 );
		nodeVar114 = ( ( nodeVar96 * 5.1 ) + 3.7 );
		nodeVar115 = floor( nodeVar114 );
		nodeVar116 = vec2<f32>( nodeVar115, 33.0 );
		nodeVar117 = fract( ( vec3<f32>( nodeVar116.x, nodeVar116.y, nodeVar116.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar118 = ( nodeVar117 + vec3<f32>( dot( nodeVar117, ( vec3<f32>( nodeVar117.y, nodeVar117.z, nodeVar117.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar119 = vec2<f32>( ( nodeVar115 + 1.0 ), 33.0 );
		nodeVar120 = fract( ( vec3<f32>( nodeVar119.x, nodeVar119.y, nodeVar119.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar121 = ( nodeVar120 + vec3<f32>( dot( nodeVar120, ( vec3<f32>( nodeVar120.y, nodeVar120.z, nodeVar120.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar122 = fract( nodeVar114 );
		nodeVar15 = ( nodeVar15 + ( ( ( ( ( ( ( ( mix( fract( ( ( nodeVar100.x + nodeVar100.y ) * nodeVar100.z ) ), fract( ( ( nodeVar103.x + nodeVar103.y ) * nodeVar103.z ) ), ( ( nodeVar104 * nodeVar104 ) * ( 3.0 - ( nodeVar104 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( nodeVar109.x + nodeVar109.y ) * nodeVar109.z ) ), fract( ( ( nodeVar112.x + nodeVar112.y ) * nodeVar112.z ) ), ( ( nodeVar113 * nodeVar113 ) * ( 3.0 - ( nodeVar113 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( nodeVar118.x + nodeVar118.y ) * nodeVar118.z ) ), fract( ( ( nodeVar121.x + nodeVar121.y ) * nodeVar121.z ) ), ( ( nodeVar122 * nodeVar122 ) * ( 3.0 - ( nodeVar122 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * 2.0 ) * knobs.wobble ) * nodeVar12 ) * 0.12 ) );
		

	}

	nodeVar123 = nodeVar5;

	if ( ( knobs.stretch > 0.0 ) ) {

		nodeVar124 = ( ( nodeVar5 / ( nodeVar12 * 0.45 ) ) + ( nodeVar13 * 1.3 ) );
		nodeVar125 = floor( nodeVar124 );
		nodeVar126 = vec2<f32>( nodeVar125, 41.0 );
		nodeVar127 = fract( ( vec3<f32>( nodeVar126.x, nodeVar126.y, nodeVar126.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar128 = ( nodeVar127 + vec3<f32>( dot( nodeVar127, ( vec3<f32>( nodeVar127.y, nodeVar127.z, nodeVar127.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar129 = vec2<f32>( ( nodeVar125 + 1.0 ), 41.0 );
		nodeVar130 = fract( ( vec3<f32>( nodeVar129.x, nodeVar129.y, nodeVar129.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar131 = ( nodeVar130 + vec3<f32>( dot( nodeVar130, ( vec3<f32>( nodeVar130.y, nodeVar130.z, nodeVar130.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar132 = fract( nodeVar124 );
		nodeVar133 = ( ( nodeVar124 * 2.3 ) + 17.1 );
		nodeVar134 = floor( nodeVar133 );
		nodeVar135 = vec2<f32>( nodeVar134, 42.0 );
		nodeVar136 = fract( ( vec3<f32>( nodeVar135.x, nodeVar135.y, nodeVar135.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar137 = ( nodeVar136 + vec3<f32>( dot( nodeVar136, ( vec3<f32>( nodeVar136.y, nodeVar136.z, nodeVar136.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar138 = vec2<f32>( ( nodeVar134 + 1.0 ), 42.0 );
		nodeVar139 = fract( ( vec3<f32>( nodeVar138.x, nodeVar138.y, nodeVar138.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar140 = ( nodeVar139 + vec3<f32>( dot( nodeVar139, ( vec3<f32>( nodeVar139.y, nodeVar139.z, nodeVar139.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar141 = fract( nodeVar133 );
		nodeVar142 = ( ( nodeVar124 * 5.1 ) + 3.7 );
		nodeVar143 = floor( nodeVar142 );
		nodeVar144 = vec2<f32>( nodeVar143, 43.0 );
		nodeVar145 = fract( ( vec3<f32>( nodeVar144.x, nodeVar144.y, nodeVar144.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar146 = ( nodeVar145 + vec3<f32>( dot( nodeVar145, ( vec3<f32>( nodeVar145.y, nodeVar145.z, nodeVar145.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar147 = vec2<f32>( ( nodeVar143 + 1.0 ), 43.0 );
		nodeVar148 = fract( ( vec3<f32>( nodeVar147.x, nodeVar147.y, nodeVar147.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar149 = ( nodeVar148 + vec3<f32>( dot( nodeVar148, ( vec3<f32>( nodeVar148.y, nodeVar148.z, nodeVar148.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar150 = fract( nodeVar142 );
		nodeVar123 = ( nodeVar5 + ( ( ( ( ( ( ( mix( fract( ( ( nodeVar128.x + nodeVar128.y ) * nodeVar128.z ) ), fract( ( ( nodeVar131.x + nodeVar131.y ) * nodeVar131.z ) ), ( ( nodeVar132 * nodeVar132 ) * ( 3.0 - ( nodeVar132 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( nodeVar137.x + nodeVar137.y ) * nodeVar137.z ) ), fract( ( ( nodeVar140.x + nodeVar140.y ) * nodeVar140.z ) ), ( ( nodeVar141 * nodeVar141 ) * ( 3.0 - ( nodeVar141 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( nodeVar146.x + nodeVar146.y ) * nodeVar146.z ) ), fract( ( ( nodeVar149.x + nodeVar149.y ) * nodeVar149.z ) ), ( ( nodeVar150 * nodeVar150 ) * ( 3.0 - ( nodeVar150 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * knobs.stretch ) * nodeVar12 ) * 0.35 ) );
		

	}


	if ( ( knobs.drag >= 0.0001 ) ) {

		nodeVar151 = ( knobs.dragLength * nodeVar9 );
		nodeVar152 = ( ( nodeVar7 / ( nodeVar12 * 0.12 ) ) + nodeVar13 );
		nodeVar153 = floor( nodeVar152 );
		nodeVar154 = vec2<f32>( nodeVar153, 51.0 );
		nodeVar155 = fract( ( vec3<f32>( nodeVar154.x, nodeVar154.y, nodeVar154.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar156 = ( nodeVar155 + vec3<f32>( dot( nodeVar155, ( vec3<f32>( nodeVar155.y, nodeVar155.z, nodeVar155.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar157 = vec2<f32>( ( nodeVar153 + 1.0 ), 51.0 );
		nodeVar158 = fract( ( vec3<f32>( nodeVar157.x, nodeVar157.y, nodeVar157.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar159 = ( nodeVar158 + vec3<f32>( dot( nodeVar158, ( vec3<f32>( nodeVar158.y, nodeVar158.z, nodeVar158.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar160 = fract( nodeVar152 );
		nodeVar161 = ( ( nodeVar152 * 2.3 ) + 17.1 );
		nodeVar162 = floor( nodeVar161 );
		nodeVar163 = vec2<f32>( nodeVar162, 52.0 );
		nodeVar164 = fract( ( vec3<f32>( nodeVar163.x, nodeVar163.y, nodeVar163.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar165 = ( nodeVar164 + vec3<f32>( dot( nodeVar164, ( vec3<f32>( nodeVar164.y, nodeVar164.z, nodeVar164.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar166 = vec2<f32>( ( nodeVar162 + 1.0 ), 52.0 );
		nodeVar167 = fract( ( vec3<f32>( nodeVar166.x, nodeVar166.y, nodeVar166.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar168 = ( nodeVar167 + vec3<f32>( dot( nodeVar167, ( vec3<f32>( nodeVar167.y, nodeVar167.z, nodeVar167.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar169 = fract( nodeVar161 );
		nodeVar170 = ( ( nodeVar152 * 5.1 ) + 3.7 );
		nodeVar171 = floor( nodeVar170 );
		nodeVar172 = vec2<f32>( nodeVar171, 53.0 );
		nodeVar173 = fract( ( vec3<f32>( nodeVar172.x, nodeVar172.y, nodeVar172.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar174 = ( nodeVar173 + vec3<f32>( dot( nodeVar173, ( vec3<f32>( nodeVar173.y, nodeVar173.z, nodeVar173.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar175 = vec2<f32>( ( nodeVar171 + 1.0 ), 53.0 );
		nodeVar176 = fract( ( vec3<f32>( nodeVar175.x, nodeVar175.y, nodeVar175.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar177 = ( nodeVar176 + vec3<f32>( dot( nodeVar176, ( vec3<f32>( nodeVar176.y, nodeVar176.z, nodeVar176.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar178 = fract( nodeVar170 );
		nodeVar179 = ( ( nodeVar7 / 4.0 ) + nodeVar13 );
		nodeVar180 = floor( nodeVar179 );
		nodeVar181 = vec2<f32>( nodeVar180, 54.0 );
		nodeVar182 = fract( ( vec3<f32>( nodeVar181.x, nodeVar181.y, nodeVar181.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar183 = ( nodeVar182 + vec3<f32>( dot( nodeVar182, ( vec3<f32>( nodeVar182.y, nodeVar182.z, nodeVar182.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar184 = vec2<f32>( ( nodeVar180 + 1.0 ), 54.0 );
		nodeVar185 = fract( ( vec3<f32>( nodeVar184.x, nodeVar184.y, nodeVar184.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar186 = ( nodeVar185 + vec3<f32>( dot( nodeVar185, ( vec3<f32>( nodeVar185.y, nodeVar185.z, nodeVar185.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar187 = fract( nodeVar179 );
		nodeVar188 = ( ( ( ( ( ( mix( fract( ( ( nodeVar156.x + nodeVar156.y ) * nodeVar156.z ) ), fract( ( ( nodeVar159.x + nodeVar159.y ) * nodeVar159.z ) ), ( ( nodeVar160 * nodeVar160 ) * ( 3.0 - ( nodeVar160 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( nodeVar165.x + nodeVar165.y ) * nodeVar165.z ) ), fract( ( ( nodeVar168.x + nodeVar168.y ) * nodeVar168.z ) ), ( ( nodeVar169 * nodeVar169 ) * ( 3.0 - ( nodeVar169 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( nodeVar174.x + nodeVar174.y ) * nodeVar174.z ) ), fract( ( ( nodeVar177.x + nodeVar177.y ) * nodeVar177.z ) ), ( ( nodeVar178 * nodeVar178 ) * ( 3.0 - ( nodeVar178 * 2.0 ) ) ) ) * 0.1 ) ) * 0.35 ) + ( mix( fract( ( ( nodeVar183.x + nodeVar183.y ) * nodeVar183.z ) ), fract( ( ( nodeVar186.x + nodeVar186.y ) * nodeVar186.z ) ), ( ( nodeVar187 * nodeVar187 ) * ( 3.0 - ( nodeVar187 * 2.0 ) ) ) ) * 0.03 ) ) * nodeVar151 );
		nodeVar189 = floor( ( ( nodeVar123 + nodeVar188 ) / nodeVar151 ) );
		nodeVar190 = vec2<f32>( ( nodeVar189 + nodeVar13 ), ( nodeVar14 * 3.0 ) );
		nodeVar191 = fract( ( vec3<f32>( nodeVar190.x, nodeVar190.y, nodeVar190.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar192 = ( nodeVar191 + vec3<f32>( dot( nodeVar191, ( vec3<f32>( nodeVar191.y, nodeVar191.z, nodeVar191.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar123 = mix( nodeVar123, ( ( nodeVar189 * nodeVar151 ) - nodeVar188 ), ( step( fract( ( ( nodeVar192.x + nodeVar192.y ) * nodeVar192.z ) ), knobs.drag ) * step( 0.0001, knobs.drag ) ) );
		

	}

	nodeVar193 = floor( ( nodeVar7 / 2.0 ) );

	if ( ( knobs.lineNoise > 0.0 ) ) {

		nodeVar194 = vec2<f32>( ( nodeVar193 + nodeVar13 ), ( nodeVar14 + 1.0 ) );
		nodeVar195 = fract( ( vec3<f32>( nodeVar194.x, nodeVar194.y, nodeVar194.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar196 = ( nodeVar195 + vec3<f32>( dot( nodeVar195, ( vec3<f32>( nodeVar195.y, nodeVar195.z, nodeVar195.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar197 = ( nodeVar194 + vec2<f32>( 6.6 ) );
		nodeVar198 = fract( ( vec3<f32>( nodeVar197.x, nodeVar197.y, nodeVar197.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar199 = ( nodeVar198 + vec3<f32>( dot( nodeVar198, ( vec3<f32>( nodeVar198.y, nodeVar198.z, nodeVar198.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar123 = ( nodeVar123 + ( ( ( ( ( fract( ( ( nodeVar196.x + nodeVar196.y ) * nodeVar196.z ) ) - 0.5 ) * knobs.lineNoise ) * nodeVar12 ) * 0.06 ) * step( fract( ( ( nodeVar199.x + nodeVar199.y ) * nodeVar199.z ) ), ( knobs.lineNoise * 0.5 ) ) ) );
		

	}


	if ( nodeVar4 ) {

		nodeVar200 = vec2<f32>( nodeVar15, nodeVar123 );

	} else {

		nodeVar200 = vec2<f32>( nodeVar123, nodeVar15 );

	}

	nodeVar201 = picture_read_level( ( nodeVar200 / nodeVar1 ), 0.0 );
	nodeVar202 = nodeVar201;
	nodeVar203 = vec3<f32>( nodeVar202.x, nodeVar202.y, nodeVar202.z );

	if ( ( knobs.chroma > 0.0 ) ) {

		nodeVar204 = ( ( knobs.chroma * nodeVar12 ) * 0.02 );

		if ( nodeVar4 ) {

			nodeVar205 = vec2<f32>( nodeVar15, ( nodeVar123 + nodeVar204 ) );

		} else {

			nodeVar205 = vec2<f32>( ( nodeVar123 + nodeVar204 ), nodeVar15 );

		}

		nodeVar206 = picture_read_level( ( nodeVar205 / nodeVar1 ), 0.0 );

		if ( nodeVar4 ) {

			nodeVar207 = vec2<f32>( nodeVar15, ( nodeVar123 - nodeVar204 ) );

		} else {

			nodeVar207 = vec2<f32>( ( nodeVar123 - nodeVar204 ), nodeVar15 );

		}

		nodeVar208 = picture_read_level( ( nodeVar207 / nodeVar1 ), 0.0 );
		nodeVar203 = vec3<f32>( nodeVar206.x, nodeVar202.y, nodeVar208.z );
		

	}


	if ( ( knobs.crush >= 0.0001 ) ) {

		nodeVar209 = mix( 64.0, 3.0, knobs.crush );
		nodeVar203 = mix( nodeVar203, pow( ( floor( ( ( pow( max( nodeVar203, vec3<f32>( 0.0, 0.0, 0.0 ) ), vec3<f32>( 0.45454545454545453, 0.45454545454545453, 0.45454545454545453 ) ) * vec3<f32>( nodeVar209 ) ) + vec3<f32>( 0.5 ) ) ) / vec3<f32>( nodeVar209 ) ), vec3<f32>( 2.2, 2.2, 2.2 ) ), step( 0.0001, knobs.crush ) );
		

	}


	if ( ( knobs.lineNoise >= 0.0001 ) ) {

		nodeVar210 = vec2<f32>( ( nodeVar193 + ( nodeVar13 * 2.0 ) ), ( nodeVar14 + 2.0 ) );
		nodeVar211 = fract( ( vec3<f32>( nodeVar210.x, nodeVar210.y, nodeVar210.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar212 = ( nodeVar211 + vec3<f32>( dot( nodeVar211, ( vec3<f32>( nodeVar211.y, nodeVar211.z, nodeVar211.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar203 = mix( nodeVar203, clamp( ( nodeVar203 + vec3<f32>( ( ( ( fract( ( ( nodeVar212.x + nodeVar212.y ) * nodeVar212.z ) ) - 0.5 ) * knobs.lineNoise ) * 0.35 ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), step( 0.0001, knobs.lineNoise ) );
		

	}

	nodeVar213 = vec4<f32>( mix( nodeVar203, knobs.dropoutColor, nodeVar16 ), 1.0 );
	nodeVar214 = vec3<f32>( nodeVar213.x, nodeVar213.y, nodeVar213.z );
	nodeVar215 = ( ( ( nodeVar214.x * 0.2126 ) + ( nodeVar214.y * 0.7152 ) ) + ( nodeVar214.z * 0.0722 ) );
	nodeVar216 = mix( vec3<f32>( nodeVar215, nodeVar215, nodeVar215 ), nodeVar214, f32(1.0) );
	nodeVar217 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar216.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar216.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar216.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar216.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar216.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar216.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar216.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar216.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar216.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar213.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar217.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar217.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar218 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar218;

	// result

	output.color = nodeVar218;

	output.color = to_shelf(output.color);
	return output;

}

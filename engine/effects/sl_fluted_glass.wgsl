// Fluted Glass: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Ribbed glass that slices the image into vertical strips with a slight color split.
// --check@preset:Preset,0
// --track@frequency:Frequency,2,100,20,1
// --track@amplitude:Amplitude,0,0.1,0.02,0.001
// --track@warp:Warp,0,1,0.28,0.01
// --track@irregularity:Irregularity,0,1,0.35,0.01
// --track@angle:Angle,0,360,0,1
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
  angle: f32,
  preset: f32,
  irregularity: f32,
  frequency: f32,
  warp: f32,
  amplitude: f32,
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
var<private> nodeVar2 : f32;
var<private> nodeVar3 : f32;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : bool;
var<private> nodeVar6 : f32;
var<private> nodeVar7 : f32;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : vec3<f32>;
var<private> nodeVar10 : vec3<f32>;
var<private> nodeVar11 : vec3<f32>;
var<private> nodeVar12 : vec3<f32>;
var<private> nodeVar13 : vec3<f32>;
var<private> nodeVar14 : vec3<f32>;
var<private> nodeVar15 : vec3<f32>;
var<private> nodeVar16 : vec3<f32>;
var<private> nodeVar17 : vec3<f32>;
var<private> nodeVar18 : vec3<f32>;
var<private> nodeVar19 : vec4<f32>;
var<private> nodeVar20 : vec4<f32>;
var<private> nodeVar21 : vec4<f32>;
var<private> nodeVar22 : vec4<f32>;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : vec3<f32>;
var<private> nodeVar25 : vec4<f32>;
var<private> nodeVar26 : vec4<f32>;
var<private> nodeVar27 : vec4<f32>;
var<private> nodeVar28 : vec4<f32>;
var<private> nodeVar29 : vec4<f32>;
var<private> nodeVar30 : vec4<f32>;
var<private> nodeVar31 : vec4<f32>;
var<private> nodeVar32 : vec4<f32>;
var<private> nodeVar33 : vec4<f32>;
var<private> nodeVar34 : vec4<f32>;
var<private> nodeVar35 : vec4<f32>;
var<private> nodeVar36 : vec3<f32>;
var<private> nodeVar37 : vec3<f32>;
var<private> nodeVar38 : vec3<f32>;
var<private> nodeVar39 : vec3<f32>;
var<private> nodeVar40 : vec4<f32>;
var<private> nodeVar41 : vec4<f32>;
var<private> nodeVar42 : vec3<f32>;
var<private> nodeVar43 : vec3<f32>;
var<private> nodeVar44 : vec3<f32>;
var<private> nodeVar45 : vec3<f32>;
var<private> nodeVar46 : vec3<f32>;
var<private> nodeVar47 : vec3<f32>;
var<private> nodeVar48 : vec3<f32>;
var<private> nodeVar49 : vec3<f32>;
var<private> nodeVar50 : vec3<f32>;
var<private> nodeVar51 : vec3<f32>;
var<private> nodeVar52 : vec4<f32>;
var<private> nodeVar53 : vec4<f32>;
var<private> nodeVar54 : vec4<f32>;
var<private> nodeVar55 : vec4<f32>;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : vec3<f32>;
var<private> nodeVar58 : vec4<f32>;
var<private> nodeVar59 : vec4<f32>;
var<private> nodeVar60 : vec4<f32>;
var<private> nodeVar61 : vec4<f32>;
var<private> nodeVar62 : vec4<f32>;
var<private> nodeVar63 : vec4<f32>;
var<private> nodeVar64 : vec4<f32>;
var<private> nodeVar65 : vec4<f32>;
var<private> nodeVar66 : vec4<f32>;
var<private> nodeVar67 : vec4<f32>;
var<private> nodeVar68 : vec4<f32>;
var<private> nodeVar69 : vec3<f32>;
var<private> nodeVar70 : vec3<f32>;
var<private> nodeVar71 : vec3<f32>;
var<private> nodeVar72 : vec3<f32>;
var<private> nodeVar73 : vec4<f32>;
var<private> nodeVar74 : vec4<f32>;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : vec3<f32>;
var<private> nodeVar77 : vec3<f32>;
var<private> nodeVar78 : vec3<f32>;
var<private> nodeVar79 : vec3<f32>;
var<private> nodeVar80 : vec3<f32>;
var<private> nodeVar81 : vec3<f32>;
var<private> nodeVar82 : vec3<f32>;
var<private> nodeVar83 : vec3<f32>;
var<private> nodeVar84 : vec3<f32>;
var<private> nodeVar85 : vec3<f32>;
var<private> nodeVar86 : vec4<f32>;
var<private> nodeVar87 : vec4<f32>;
var<private> nodeVar88 : vec4<f32>;
var<private> nodeVar89 : vec4<f32>;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : vec3<f32>;
var<private> nodeVar92 : vec4<f32>;
var<private> nodeVar93 : vec4<f32>;
var<private> nodeVar94 : vec4<f32>;
var<private> nodeVar95 : vec4<f32>;
var<private> nodeVar96 : vec4<f32>;
var<private> nodeVar97 : vec4<f32>;
var<private> nodeVar98 : vec4<f32>;
var<private> nodeVar99 : vec4<f32>;
var<private> nodeVar100 : vec4<f32>;
var<private> nodeVar101 : vec4<f32>;
var<private> nodeVar102 : vec4<f32>;
var<private> nodeVar103 : vec3<f32>;
var<private> nodeVar104 : vec3<f32>;
var<private> nodeVar105 : vec3<f32>;
var<private> nodeVar106 : vec3<f32>;
var<private> nodeVar107 : vec4<f32>;
var<private> nodeVar108 : vec4<f32>;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : f32;
var<private> nodeVar111 : f32;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : f32;
var<private> nodeVar114 : vec3<f32>;
var<private> nodeVar115 : vec3<f32>;
var<private> nodeVar116 : vec3<f32>;
var<private> nodeVar117 : vec3<f32>;
var<private> nodeVar118 : vec3<f32>;
var<private> nodeVar119 : vec3<f32>;
var<private> nodeVar120 : vec3<f32>;
var<private> nodeVar121 : vec3<f32>;
var<private> nodeVar122 : vec3<f32>;
var<private> nodeVar123 : vec3<f32>;
var<private> nodeVar124 : vec4<f32>;
var<private> nodeVar125 : vec4<f32>;
var<private> nodeVar126 : vec4<f32>;
var<private> nodeVar127 : vec4<f32>;
var<private> nodeVar128 : f32;
var<private> nodeVar129 : vec3<f32>;
var<private> nodeVar130 : vec4<f32>;
var<private> nodeVar131 : vec4<f32>;
var<private> nodeVar132 : vec4<f32>;
var<private> nodeVar133 : vec4<f32>;
var<private> nodeVar134 : vec4<f32>;
var<private> nodeVar135 : vec4<f32>;
var<private> nodeVar136 : vec4<f32>;
var<private> nodeVar137 : vec4<f32>;
var<private> nodeVar138 : vec4<f32>;
var<private> nodeVar139 : vec4<f32>;
var<private> nodeVar140 : vec4<f32>;
var<private> nodeVar141 : vec3<f32>;
var<private> nodeVar142 : vec3<f32>;
var<private> nodeVar143 : vec3<f32>;
var<private> nodeVar144 : vec3<f32>;
var<private> nodeVar145 : vec4<f32>;
var<private> nodeVar146 : vec4<f32>;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : f32;
var<private> nodeVar149 : f32;
var<private> nodeVar150 : vec3<f32>;
var<private> nodeVar151 : vec3<f32>;
var<private> nodeVar152 : vec3<f32>;
var<private> nodeVar153 : vec3<f32>;
var<private> nodeVar154 : vec3<f32>;
var<private> nodeVar155 : vec3<f32>;
var<private> nodeVar156 : vec3<f32>;
var<private> nodeVar157 : vec3<f32>;
var<private> nodeVar158 : vec3<f32>;
var<private> nodeVar159 : vec3<f32>;
var<private> nodeVar160 : vec4<f32>;
var<private> nodeVar161 : vec4<f32>;
var<private> nodeVar162 : vec4<f32>;
var<private> nodeVar163 : vec4<f32>;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : vec3<f32>;
var<private> nodeVar166 : vec4<f32>;
var<private> nodeVar167 : vec4<f32>;
var<private> nodeVar168 : vec4<f32>;
var<private> nodeVar169 : vec4<f32>;
var<private> nodeVar170 : vec4<f32>;
var<private> nodeVar171 : vec4<f32>;
var<private> nodeVar172 : vec4<f32>;
var<private> nodeVar173 : vec4<f32>;
var<private> nodeVar174 : vec4<f32>;
var<private> nodeVar175 : vec4<f32>;
var<private> nodeVar176 : vec4<f32>;
var<private> nodeVar177 : vec3<f32>;
var<private> nodeVar178 : vec3<f32>;
var<private> nodeVar179 : vec3<f32>;
var<private> nodeVar180 : vec3<f32>;
var<private> nodeVar181 : vec4<f32>;
var<private> nodeVar182 : vec4<f32>;
var<private> nodeVar183 : f32;
var<private> nodeVar184 : f32;
var<private> nodeVar185 : f32;
var<private> nodeVar186 : vec3<f32>;
var<private> nodeVar187 : vec3<f32>;
var<private> nodeVar188 : vec3<f32>;
var<private> nodeVar189 : vec3<f32>;
var<private> nodeVar190 : vec3<f32>;
var<private> nodeVar191 : vec3<f32>;
var<private> nodeVar192 : vec3<f32>;
var<private> nodeVar193 : vec3<f32>;
var<private> nodeVar194 : vec3<f32>;
var<private> nodeVar195 : vec3<f32>;
var<private> nodeVar196 : vec4<f32>;
var<private> nodeVar197 : vec4<f32>;
var<private> nodeVar198 : vec4<f32>;
var<private> nodeVar199 : vec4<f32>;
var<private> nodeVar200 : f32;
var<private> nodeVar201 : vec3<f32>;
var<private> nodeVar202 : vec4<f32>;
var<private> nodeVar203 : vec4<f32>;
var<private> nodeVar204 : vec4<f32>;
var<private> nodeVar205 : vec4<f32>;
var<private> nodeVar206 : vec4<f32>;
var<private> nodeVar207 : vec4<f32>;
var<private> nodeVar208 : vec4<f32>;
var<private> nodeVar209 : vec4<f32>;
var<private> nodeVar210 : vec4<f32>;
var<private> nodeVar211 : vec4<f32>;
var<private> nodeVar212 : vec4<f32>;
var<private> nodeVar213 : vec3<f32>;
var<private> nodeVar214 : vec3<f32>;
var<private> nodeVar215 : vec3<f32>;
var<private> nodeVar216 : vec3<f32>;
var<private> nodeVar217 : vec4<f32>;
var<private> nodeVar218 : vec4<f32>;
var<private> nodeVar219 : f32;
var<private> nodeVar220 : vec4<f32>;
var<private> nodeVar221 : vec4<f32>;
var<private> nodeVar222 : f32;
var<private> nodeVar223 : vec4<f32>;
var<private> nodeVar224 : vec3<f32>;
var<private> nodeVar225 : f32;
var<private> nodeVar226 : vec3<f32>;
var<private> nodeVar227 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar228 : vec4<f32>;

// codes
fn tsl_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }
fn tsl_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = ( knobs.angle * 0.017453292519943295 );
	nodeVar3 = sin( nodeVar2 );
	nodeVar5 = ( (1 * knobs.preset + 0) > 0.5 );

	if ( nodeVar5 ) {

		nodeVar6 = cos( nodeVar2 );
		nodeVar7 = ( ( nodeVar1.x * nodeVar6 ) + ( nodeVar1.y * nodeVar3 ) );
		nodeVar8 = ( ( nodeVar1.x * ( - nodeVar3 ) ) + ( nodeVar1.y * nodeVar6 ) );
		nodeVar9 = vec3<f32>( ( nodeVar7 * 1.35 ), ( nodeVar8 * 1.1 ), 0.17 );
		nodeVar10 = floor( ( nodeVar9 + vec3<f32>( dot( nodeVar9, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar11 = ( ( nodeVar9 - nodeVar10 ) + vec3<f32>( dot( nodeVar10, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar12 = step( nodeVar11.yzx, nodeVar11 );
		nodeVar13 = ( vec3<f32>( 1.0 ) - nodeVar12 );
		nodeVar14 = min( nodeVar12, nodeVar13.zxy );
		nodeVar15 = max( nodeVar12, nodeVar13.zxy );
		nodeVar16 = ( ( nodeVar11 - nodeVar14 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar17 = ( ( nodeVar11 - nodeVar15 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar18 = ( ( nodeVar11 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar10 = tsl_mod_vec3( nodeVar10, vec3<f32>( 289.0 ) );
		nodeVar19 = ( vec4<f32>( nodeVar10.z ) + vec4<f32>( 0.0, nodeVar14.z, nodeVar15.z, 1.0 ) );
		nodeVar20 = ( tsl_mod_vec4( ( ( ( nodeVar19 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar19 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar10.y ) + vec4<f32>( 0.0, nodeVar14.y, nodeVar15.y, 1.0 ) ) );
		nodeVar21 = ( tsl_mod_vec4( ( ( ( nodeVar20 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar20 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar10.x ) + vec4<f32>( 0.0, nodeVar14.x, nodeVar15.x, 1.0 ) ) );
		nodeVar22 = tsl_mod_vec4( ( ( ( nodeVar21 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar21 ), vec4<f32>( 289.0 ) );
		nodeVar23 = 0.14285714285714285;
		nodeVar24 = ( ( vec3<f32>( nodeVar23 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar25 = ( nodeVar22 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar22 * vec4<f32>( ( nodeVar24.z * nodeVar24.z ) ) ) ) ) );
		nodeVar26 = ( ( floor( ( nodeVar25 * vec4<f32>( nodeVar24.z ) ) ) * vec4<f32>( nodeVar24.x ) ) + vec4<f32>( nodeVar24, 1.0 ).yyyy );
		nodeVar27 = ( ( floor( ( nodeVar25 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar25 * vec4<f32>( nodeVar24.z ) ) ) ) ) ) * vec4<f32>( nodeVar24.x ) ) + vec4<f32>( nodeVar24, 1.0 ).yyyy );
		nodeVar28 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar26 ) - abs( nodeVar27 ) ) );
		nodeVar29 = vec4<f32>( nodeVar26.xy, nodeVar27.xy );
		nodeVar30 = vec4<f32>( nodeVar26.zw, nodeVar27.zw );
		nodeVar31 = ( ( floor( nodeVar29 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar32 = ( ( floor( nodeVar30 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar33 = ( - step( nodeVar28, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar34 = ( nodeVar29.xzyw + ( nodeVar31.xzyw * nodeVar33.xxyy ) );
		nodeVar35 = ( nodeVar30.xzyw + ( nodeVar32.xzyw * nodeVar33.zzww ) );
		nodeVar36 = vec3<f32>( nodeVar34.xy, nodeVar28.x );
		nodeVar37 = vec3<f32>( nodeVar34.zw, nodeVar28.y );
		nodeVar38 = vec3<f32>( nodeVar35.xy, nodeVar28.z );
		nodeVar39 = vec3<f32>( nodeVar35.zw, nodeVar28.w );
		nodeVar40 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar36, nodeVar36 ), dot( nodeVar37, nodeVar37 ), dot( nodeVar38, nodeVar38 ), dot( nodeVar39, nodeVar39 ) ) ) );
		nodeVar36 = ( nodeVar36 * vec3<f32>( nodeVar40.x ) );
		nodeVar37 = ( nodeVar37 * vec3<f32>( nodeVar40.y ) );
		nodeVar38 = ( nodeVar38 * vec3<f32>( nodeVar40.z ) );
		nodeVar39 = ( nodeVar39 * vec3<f32>( nodeVar40.w ) );
		nodeVar41 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar11, nodeVar11 ), dot( nodeVar16, nodeVar16 ), dot( nodeVar17, nodeVar17 ), dot( nodeVar18, nodeVar18 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar41 = ( nodeVar41 * nodeVar41 );
		nodeVar42 = vec3<f32>( ( floor( ( nodeVar7 * knobs.frequency ) ) * 0.19 ), ( nodeVar8 * 0.45 ), 5.11 );
		nodeVar43 = floor( ( nodeVar42 + vec3<f32>( dot( nodeVar42, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar44 = ( ( nodeVar42 - nodeVar43 ) + vec3<f32>( dot( nodeVar43, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar45 = step( nodeVar44.yzx, nodeVar44 );
		nodeVar46 = ( vec3<f32>( 1.0 ) - nodeVar45 );
		nodeVar47 = min( nodeVar45, nodeVar46.zxy );
		nodeVar48 = max( nodeVar45, nodeVar46.zxy );
		nodeVar49 = ( ( nodeVar44 - nodeVar47 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar50 = ( ( nodeVar44 - nodeVar48 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar51 = ( ( nodeVar44 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar43 = tsl_mod_vec3( nodeVar43, vec3<f32>( 289.0 ) );
		nodeVar52 = ( vec4<f32>( nodeVar43.z ) + vec4<f32>( 0.0, nodeVar47.z, nodeVar48.z, 1.0 ) );
		nodeVar53 = ( tsl_mod_vec4( ( ( ( nodeVar52 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar52 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar43.y ) + vec4<f32>( 0.0, nodeVar47.y, nodeVar48.y, 1.0 ) ) );
		nodeVar54 = ( tsl_mod_vec4( ( ( ( nodeVar53 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar53 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar43.x ) + vec4<f32>( 0.0, nodeVar47.x, nodeVar48.x, 1.0 ) ) );
		nodeVar55 = tsl_mod_vec4( ( ( ( nodeVar54 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar54 ), vec4<f32>( 289.0 ) );
		nodeVar56 = 0.14285714285714285;
		nodeVar57 = ( ( vec3<f32>( nodeVar56 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar58 = ( nodeVar55 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar55 * vec4<f32>( ( nodeVar57.z * nodeVar57.z ) ) ) ) ) );
		nodeVar59 = ( ( floor( ( nodeVar58 * vec4<f32>( nodeVar57.z ) ) ) * vec4<f32>( nodeVar57.x ) ) + vec4<f32>( nodeVar57, 1.0 ).yyyy );
		nodeVar60 = ( ( floor( ( nodeVar58 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar58 * vec4<f32>( nodeVar57.z ) ) ) ) ) ) * vec4<f32>( nodeVar57.x ) ) + vec4<f32>( nodeVar57, 1.0 ).yyyy );
		nodeVar61 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar59 ) - abs( nodeVar60 ) ) );
		nodeVar62 = vec4<f32>( nodeVar59.xy, nodeVar60.xy );
		nodeVar63 = vec4<f32>( nodeVar59.zw, nodeVar60.zw );
		nodeVar64 = ( ( floor( nodeVar62 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar65 = ( ( floor( nodeVar63 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar66 = ( - step( nodeVar61, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar67 = ( nodeVar62.xzyw + ( nodeVar64.xzyw * nodeVar66.xxyy ) );
		nodeVar68 = ( nodeVar63.xzyw + ( nodeVar65.xzyw * nodeVar66.zzww ) );
		nodeVar69 = vec3<f32>( nodeVar67.xy, nodeVar61.x );
		nodeVar70 = vec3<f32>( nodeVar67.zw, nodeVar61.y );
		nodeVar71 = vec3<f32>( nodeVar68.xy, nodeVar61.z );
		nodeVar72 = vec3<f32>( nodeVar68.zw, nodeVar61.w );
		nodeVar73 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar69, nodeVar69 ), dot( nodeVar70, nodeVar70 ), dot( nodeVar71, nodeVar71 ), dot( nodeVar72, nodeVar72 ) ) ) );
		nodeVar69 = ( nodeVar69 * vec3<f32>( nodeVar73.x ) );
		nodeVar70 = ( nodeVar70 * vec3<f32>( nodeVar73.y ) );
		nodeVar71 = ( nodeVar71 * vec3<f32>( nodeVar73.z ) );
		nodeVar72 = ( nodeVar72 * vec3<f32>( nodeVar73.w ) );
		nodeVar74 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar44, nodeVar44 ), dot( nodeVar49, nodeVar49 ), dot( nodeVar50, nodeVar50 ), dot( nodeVar51, nodeVar51 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar74 = ( nodeVar74 * nodeVar74 );
		nodeVar75 = ( 42.0 * dot( ( nodeVar74 * nodeVar74 ), vec4<f32>( dot( nodeVar69, nodeVar44 ), dot( nodeVar70, nodeVar49 ), dot( nodeVar71, nodeVar50 ), dot( nodeVar72, nodeVar51 ) ) ) );
		nodeVar76 = vec3<f32>( ( ( nodeVar7 * 1.6 ) - 8.2 ), ( ( nodeVar8 * 4.8 ) + 2.7 ), 3.73 );
		nodeVar77 = floor( ( nodeVar76 + vec3<f32>( dot( nodeVar76, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar78 = ( ( nodeVar76 - nodeVar77 ) + vec3<f32>( dot( nodeVar77, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar79 = step( nodeVar78.yzx, nodeVar78 );
		nodeVar80 = ( vec3<f32>( 1.0 ) - nodeVar79 );
		nodeVar81 = min( nodeVar79, nodeVar80.zxy );
		nodeVar82 = max( nodeVar79, nodeVar80.zxy );
		nodeVar83 = ( ( nodeVar78 - nodeVar81 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar84 = ( ( nodeVar78 - nodeVar82 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar85 = ( ( nodeVar78 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar77 = tsl_mod_vec3( nodeVar77, vec3<f32>( 289.0 ) );
		nodeVar86 = ( vec4<f32>( nodeVar77.z ) + vec4<f32>( 0.0, nodeVar81.z, nodeVar82.z, 1.0 ) );
		nodeVar87 = ( tsl_mod_vec4( ( ( ( nodeVar86 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar86 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar77.y ) + vec4<f32>( 0.0, nodeVar81.y, nodeVar82.y, 1.0 ) ) );
		nodeVar88 = ( tsl_mod_vec4( ( ( ( nodeVar87 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar87 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar77.x ) + vec4<f32>( 0.0, nodeVar81.x, nodeVar82.x, 1.0 ) ) );
		nodeVar89 = tsl_mod_vec4( ( ( ( nodeVar88 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar88 ), vec4<f32>( 289.0 ) );
		nodeVar90 = 0.14285714285714285;
		nodeVar91 = ( ( vec3<f32>( nodeVar90 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar92 = ( nodeVar89 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar89 * vec4<f32>( ( nodeVar91.z * nodeVar91.z ) ) ) ) ) );
		nodeVar93 = ( ( floor( ( nodeVar92 * vec4<f32>( nodeVar91.z ) ) ) * vec4<f32>( nodeVar91.x ) ) + vec4<f32>( nodeVar91, 1.0 ).yyyy );
		nodeVar94 = ( ( floor( ( nodeVar92 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar92 * vec4<f32>( nodeVar91.z ) ) ) ) ) ) * vec4<f32>( nodeVar91.x ) ) + vec4<f32>( nodeVar91, 1.0 ).yyyy );
		nodeVar95 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar93 ) - abs( nodeVar94 ) ) );
		nodeVar96 = vec4<f32>( nodeVar93.xy, nodeVar94.xy );
		nodeVar97 = vec4<f32>( nodeVar93.zw, nodeVar94.zw );
		nodeVar98 = ( ( floor( nodeVar96 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar99 = ( ( floor( nodeVar97 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar100 = ( - step( nodeVar95, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar101 = ( nodeVar96.xzyw + ( nodeVar98.xzyw * nodeVar100.xxyy ) );
		nodeVar102 = ( nodeVar97.xzyw + ( nodeVar99.xzyw * nodeVar100.zzww ) );
		nodeVar103 = vec3<f32>( nodeVar101.xy, nodeVar95.x );
		nodeVar104 = vec3<f32>( nodeVar101.zw, nodeVar95.y );
		nodeVar105 = vec3<f32>( nodeVar102.xy, nodeVar95.z );
		nodeVar106 = vec3<f32>( nodeVar102.zw, nodeVar95.w );
		nodeVar107 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar103, nodeVar103 ), dot( nodeVar104, nodeVar104 ), dot( nodeVar105, nodeVar105 ), dot( nodeVar106, nodeVar106 ) ) ) );
		nodeVar103 = ( nodeVar103 * vec3<f32>( nodeVar107.x ) );
		nodeVar104 = ( nodeVar104 * vec3<f32>( nodeVar107.y ) );
		nodeVar105 = ( nodeVar105 * vec3<f32>( nodeVar107.z ) );
		nodeVar106 = ( nodeVar106 * vec3<f32>( nodeVar107.w ) );
		nodeVar108 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar78, nodeVar78 ), dot( nodeVar83, nodeVar83 ), dot( nodeVar84, nodeVar84 ), dot( nodeVar85, nodeVar85 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar108 = ( nodeVar108 * nodeVar108 );
		nodeVar109 = ( 42.0 * dot( ( nodeVar108 * nodeVar108 ), vec4<f32>( dot( nodeVar103, nodeVar78 ), dot( nodeVar104, nodeVar83 ), dot( nodeVar105, nodeVar84 ), dot( nodeVar106, nodeVar85 ) ) ) );
		nodeVar110 = ( ( fract( ( ( ( ( ( nodeVar7 + ( ( ( 42.0 * dot( ( nodeVar41 * nodeVar41 ), vec4<f32>( dot( nodeVar36, nodeVar11 ), dot( nodeVar37, nodeVar16 ), dot( nodeVar38, nodeVar17 ), dot( nodeVar39, nodeVar18 ) ) ) ) * knobs.irregularity ) * 0.055 ) ) + ( ( nodeVar75 * knobs.irregularity ) * 0.045 ) ) + ( ( nodeVar109 * knobs.warp ) * 0.02 ) ) * knobs.frequency ) + ( ( nodeVar75 * knobs.irregularity ) * 0.85 ) ) ) * 2.0 ) - 1.0 );
		nodeVar111 = max( 0.0, ( 1.0 - ( nodeVar110 * nodeVar110 ) ) );
		nodeVar112 = abs( nodeVar110 );
		nodeVar113 = ( smoothstep( 0.08, 0.52, nodeVar112 ) * ( 1.0 - smoothstep( 0.62, 0.98, nodeVar112 ) ) );
		nodeVar114 = vec3<f32>( ( ( nodeVar7 * 3.9 ) + 11.7 ), ( ( nodeVar8 * 2.4 ) - 4.3 ), 1.91 );
		nodeVar115 = floor( ( nodeVar114 + vec3<f32>( dot( nodeVar114, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar116 = ( ( nodeVar114 - nodeVar115 ) + vec3<f32>( dot( nodeVar115, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar117 = step( nodeVar116.yzx, nodeVar116 );
		nodeVar118 = ( vec3<f32>( 1.0 ) - nodeVar117 );
		nodeVar119 = min( nodeVar117, nodeVar118.zxy );
		nodeVar120 = max( nodeVar117, nodeVar118.zxy );
		nodeVar121 = ( ( nodeVar116 - nodeVar119 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar122 = ( ( nodeVar116 - nodeVar120 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar123 = ( ( nodeVar116 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar115 = tsl_mod_vec3( nodeVar115, vec3<f32>( 289.0 ) );
		nodeVar124 = ( vec4<f32>( nodeVar115.z ) + vec4<f32>( 0.0, nodeVar119.z, nodeVar120.z, 1.0 ) );
		nodeVar125 = ( tsl_mod_vec4( ( ( ( nodeVar124 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar124 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar115.y ) + vec4<f32>( 0.0, nodeVar119.y, nodeVar120.y, 1.0 ) ) );
		nodeVar126 = ( tsl_mod_vec4( ( ( ( nodeVar125 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar125 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar115.x ) + vec4<f32>( 0.0, nodeVar119.x, nodeVar120.x, 1.0 ) ) );
		nodeVar127 = tsl_mod_vec4( ( ( ( nodeVar126 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar126 ), vec4<f32>( 289.0 ) );
		nodeVar128 = 0.14285714285714285;
		nodeVar129 = ( ( vec3<f32>( nodeVar128 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar130 = ( nodeVar127 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar127 * vec4<f32>( ( nodeVar129.z * nodeVar129.z ) ) ) ) ) );
		nodeVar131 = ( ( floor( ( nodeVar130 * vec4<f32>( nodeVar129.z ) ) ) * vec4<f32>( nodeVar129.x ) ) + vec4<f32>( nodeVar129, 1.0 ).yyyy );
		nodeVar132 = ( ( floor( ( nodeVar130 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar130 * vec4<f32>( nodeVar129.z ) ) ) ) ) ) * vec4<f32>( nodeVar129.x ) ) + vec4<f32>( nodeVar129, 1.0 ).yyyy );
		nodeVar133 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar131 ) - abs( nodeVar132 ) ) );
		nodeVar134 = vec4<f32>( nodeVar131.xy, nodeVar132.xy );
		nodeVar135 = vec4<f32>( nodeVar131.zw, nodeVar132.zw );
		nodeVar136 = ( ( floor( nodeVar134 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar137 = ( ( floor( nodeVar135 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar138 = ( - step( nodeVar133, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar139 = ( nodeVar134.xzyw + ( nodeVar136.xzyw * nodeVar138.xxyy ) );
		nodeVar140 = ( nodeVar135.xzyw + ( nodeVar137.xzyw * nodeVar138.zzww ) );
		nodeVar141 = vec3<f32>( nodeVar139.xy, nodeVar133.x );
		nodeVar142 = vec3<f32>( nodeVar139.zw, nodeVar133.y );
		nodeVar143 = vec3<f32>( nodeVar140.xy, nodeVar133.z );
		nodeVar144 = vec3<f32>( nodeVar140.zw, nodeVar133.w );
		nodeVar145 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar141, nodeVar141 ), dot( nodeVar142, nodeVar142 ), dot( nodeVar143, nodeVar143 ), dot( nodeVar144, nodeVar144 ) ) ) );
		nodeVar141 = ( nodeVar141 * vec3<f32>( nodeVar145.x ) );
		nodeVar142 = ( nodeVar142 * vec3<f32>( nodeVar145.y ) );
		nodeVar143 = ( nodeVar143 * vec3<f32>( nodeVar145.z ) );
		nodeVar144 = ( nodeVar144 * vec3<f32>( nodeVar145.w ) );
		nodeVar146 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar116, nodeVar116 ), dot( nodeVar121, nodeVar121 ), dot( nodeVar122, nodeVar122 ), dot( nodeVar123, nodeVar123 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar146 = ( nodeVar146 * nodeVar146 );
		nodeVar147 = ( 42.0 * dot( ( nodeVar146 * nodeVar146 ), vec4<f32>( dot( nodeVar141, nodeVar116 ), dot( nodeVar142, nodeVar121 ), dot( nodeVar143, nodeVar122 ), dot( nodeVar144, nodeVar123 ) ) ) );
		nodeVar4 = ( ( nodeVar110 * ( ( ( nodeVar111 * 0.38 ) + ( nodeVar113 * 0.84 ) ) * ( 1.0 + ( ( nodeVar147 * knobs.warp ) * 0.35 ) ) ) ) + ( ( ( ( nodeVar147 * knobs.warp ) * nodeVar111 ) * 0.55 ) + ( ( ( nodeVar109 * knobs.irregularity ) * nodeVar113 ) * 0.24 ) ) );

	} else {

		nodeVar148 = cos( nodeVar2 );
		nodeVar149 = ( ( nodeVar1.x * nodeVar148 ) + ( nodeVar1.y * nodeVar3 ) );
		nodeVar150 = vec3<f32>( ( nodeVar149 * 1.35 ), ( ( ( nodeVar1.x * ( - nodeVar3 ) ) + ( nodeVar1.y * nodeVar148 ) ) * 1.1 ), 0.17 );
		nodeVar151 = floor( ( nodeVar150 + vec3<f32>( dot( nodeVar150, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar152 = ( ( nodeVar150 - nodeVar151 ) + vec3<f32>( dot( nodeVar151, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar153 = step( nodeVar152.yzx, nodeVar152 );
		nodeVar154 = ( vec3<f32>( 1.0 ) - nodeVar153 );
		nodeVar155 = min( nodeVar153, nodeVar154.zxy );
		nodeVar156 = max( nodeVar153, nodeVar154.zxy );
		nodeVar157 = ( ( nodeVar152 - nodeVar155 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar158 = ( ( nodeVar152 - nodeVar156 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar159 = ( ( nodeVar152 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar151 = tsl_mod_vec3( nodeVar151, vec3<f32>( 289.0 ) );
		nodeVar160 = ( vec4<f32>( nodeVar151.z ) + vec4<f32>( 0.0, nodeVar155.z, nodeVar156.z, 1.0 ) );
		nodeVar161 = ( tsl_mod_vec4( ( ( ( nodeVar160 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar160 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar151.y ) + vec4<f32>( 0.0, nodeVar155.y, nodeVar156.y, 1.0 ) ) );
		nodeVar162 = ( tsl_mod_vec4( ( ( ( nodeVar161 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar161 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar151.x ) + vec4<f32>( 0.0, nodeVar155.x, nodeVar156.x, 1.0 ) ) );
		nodeVar163 = tsl_mod_vec4( ( ( ( nodeVar162 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar162 ), vec4<f32>( 289.0 ) );
		nodeVar164 = 0.14285714285714285;
		nodeVar165 = ( ( vec3<f32>( nodeVar164 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar166 = ( nodeVar163 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar163 * vec4<f32>( ( nodeVar165.z * nodeVar165.z ) ) ) ) ) );
		nodeVar167 = ( ( floor( ( nodeVar166 * vec4<f32>( nodeVar165.z ) ) ) * vec4<f32>( nodeVar165.x ) ) + vec4<f32>( nodeVar165, 1.0 ).yyyy );
		nodeVar168 = ( ( floor( ( nodeVar166 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar166 * vec4<f32>( nodeVar165.z ) ) ) ) ) ) * vec4<f32>( nodeVar165.x ) ) + vec4<f32>( nodeVar165, 1.0 ).yyyy );
		nodeVar169 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar167 ) - abs( nodeVar168 ) ) );
		nodeVar170 = vec4<f32>( nodeVar167.xy, nodeVar168.xy );
		nodeVar171 = vec4<f32>( nodeVar167.zw, nodeVar168.zw );
		nodeVar172 = ( ( floor( nodeVar170 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar173 = ( ( floor( nodeVar171 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar174 = ( - step( nodeVar169, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar175 = ( nodeVar170.xzyw + ( nodeVar172.xzyw * nodeVar174.xxyy ) );
		nodeVar176 = ( nodeVar171.xzyw + ( nodeVar173.xzyw * nodeVar174.zzww ) );
		nodeVar177 = vec3<f32>( nodeVar175.xy, nodeVar169.x );
		nodeVar178 = vec3<f32>( nodeVar175.zw, nodeVar169.y );
		nodeVar179 = vec3<f32>( nodeVar176.xy, nodeVar169.z );
		nodeVar180 = vec3<f32>( nodeVar176.zw, nodeVar169.w );
		nodeVar181 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar177, nodeVar177 ), dot( nodeVar178, nodeVar178 ), dot( nodeVar179, nodeVar179 ), dot( nodeVar180, nodeVar180 ) ) ) );
		nodeVar177 = ( nodeVar177 * vec3<f32>( nodeVar181.x ) );
		nodeVar178 = ( nodeVar178 * vec3<f32>( nodeVar181.y ) );
		nodeVar179 = ( nodeVar179 * vec3<f32>( nodeVar181.z ) );
		nodeVar180 = ( nodeVar180 * vec3<f32>( nodeVar181.w ) );
		nodeVar182 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar152, nodeVar152 ), dot( nodeVar157, nodeVar157 ), dot( nodeVar158, nodeVar158 ), dot( nodeVar159, nodeVar159 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar182 = ( nodeVar182 * nodeVar182 );
		nodeVar183 = ( ( fract( ( ( nodeVar149 + ( ( ( 42.0 * dot( ( nodeVar182 * nodeVar182 ), vec4<f32>( dot( nodeVar177, nodeVar152 ), dot( nodeVar178, nodeVar157 ), dot( nodeVar179, nodeVar158 ), dot( nodeVar180, nodeVar159 ) ) ) ) * knobs.irregularity ) * 0.028 ) ) * knobs.frequency ) ) * 2.0 ) - 1.0 );
		nodeVar4 = ( nodeVar183 * ( ( pow( max( 0.0, ( 1.0 - ( nodeVar183 * nodeVar183 ) ) ), 1.08 ) * 0.7 ) * ( 1.0 - ( ( abs( nodeVar183 ) * knobs.irregularity ) * 0.18 ) ) ) );

	}


	if ( nodeVar5 ) {

		nodeVar184 = 2.7;

	} else {

		nodeVar184 = 1.7;

	}

	nodeVar185 = cos( nodeVar2 );
	nodeVar186 = vec3<f32>( ( ( ( ( nodeVar1.x * nodeVar185 ) + ( nodeVar1.y * nodeVar3 ) ) * 1.6 ) - 8.2 ), ( ( ( ( nodeVar1.x * ( - nodeVar3 ) ) + ( nodeVar1.y * nodeVar185 ) ) * 4.8 ) + 2.7 ), 3.73 );
	nodeVar187 = floor( ( nodeVar186 + vec3<f32>( dot( nodeVar186, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	nodeVar188 = ( ( nodeVar186 - nodeVar187 ) + vec3<f32>( dot( nodeVar187, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	nodeVar189 = step( nodeVar188.yzx, nodeVar188 );
	nodeVar190 = ( vec3<f32>( 1.0 ) - nodeVar189 );
	nodeVar191 = min( nodeVar189, nodeVar190.zxy );
	nodeVar192 = max( nodeVar189, nodeVar190.zxy );
	nodeVar193 = ( ( nodeVar188 - nodeVar191 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar194 = ( ( nodeVar188 - nodeVar192 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar195 = ( ( nodeVar188 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar187 = tsl_mod_vec3( nodeVar187, vec3<f32>( 289.0 ) );
	nodeVar196 = ( vec4<f32>( nodeVar187.z ) + vec4<f32>( 0.0, nodeVar191.z, nodeVar192.z, 1.0 ) );
	nodeVar197 = ( tsl_mod_vec4( ( ( ( nodeVar196 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar196 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar187.y ) + vec4<f32>( 0.0, nodeVar191.y, nodeVar192.y, 1.0 ) ) );
	nodeVar198 = ( tsl_mod_vec4( ( ( ( nodeVar197 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar197 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar187.x ) + vec4<f32>( 0.0, nodeVar191.x, nodeVar192.x, 1.0 ) ) );
	nodeVar199 = tsl_mod_vec4( ( ( ( nodeVar198 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar198 ), vec4<f32>( 289.0 ) );
	nodeVar200 = 0.14285714285714285;
	nodeVar201 = ( ( vec3<f32>( nodeVar200 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	nodeVar202 = ( nodeVar199 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar199 * vec4<f32>( ( nodeVar201.z * nodeVar201.z ) ) ) ) ) );
	nodeVar203 = ( ( floor( ( nodeVar202 * vec4<f32>( nodeVar201.z ) ) ) * vec4<f32>( nodeVar201.x ) ) + vec4<f32>( nodeVar201, 1.0 ).yyyy );
	nodeVar204 = ( ( floor( ( nodeVar202 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar202 * vec4<f32>( nodeVar201.z ) ) ) ) ) ) * vec4<f32>( nodeVar201.x ) ) + vec4<f32>( nodeVar201, 1.0 ).yyyy );
	nodeVar205 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar203 ) - abs( nodeVar204 ) ) );
	nodeVar206 = vec4<f32>( nodeVar203.xy, nodeVar204.xy );
	nodeVar207 = vec4<f32>( nodeVar203.zw, nodeVar204.zw );
	nodeVar208 = ( ( floor( nodeVar206 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar209 = ( ( floor( nodeVar207 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar210 = ( - step( nodeVar205, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	nodeVar211 = ( nodeVar206.xzyw + ( nodeVar208.xzyw * nodeVar210.xxyy ) );
	nodeVar212 = ( nodeVar207.xzyw + ( nodeVar209.xzyw * nodeVar210.zzww ) );
	nodeVar213 = vec3<f32>( nodeVar211.xy, nodeVar205.x );
	nodeVar214 = vec3<f32>( nodeVar211.zw, nodeVar205.y );
	nodeVar215 = vec3<f32>( nodeVar212.xy, nodeVar205.z );
	nodeVar216 = vec3<f32>( nodeVar212.zw, nodeVar205.w );
	nodeVar217 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar213, nodeVar213 ), dot( nodeVar214, nodeVar214 ), dot( nodeVar215, nodeVar215 ), dot( nodeVar216, nodeVar216 ) ) ) );
	nodeVar213 = ( nodeVar213 * vec3<f32>( nodeVar217.x ) );
	nodeVar214 = ( nodeVar214 * vec3<f32>( nodeVar217.y ) );
	nodeVar215 = ( nodeVar215 * vec3<f32>( nodeVar217.z ) );
	nodeVar216 = ( nodeVar216 * vec3<f32>( nodeVar217.w ) );
	nodeVar218 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar188, nodeVar188 ), dot( nodeVar193, nodeVar193 ), dot( nodeVar194, nodeVar194 ), dot( nodeVar195, nodeVar195 ) ) ), vec4<f32>( 0.0 ) );
	nodeVar218 = ( nodeVar218 * nodeVar218 );
	nodeVar219 = ( ( nodeVar4 * ( knobs.amplitude * nodeVar184 ) ) + ( ( ( ( 42.0 * dot( ( nodeVar218 * nodeVar218 ), vec4<f32>( dot( nodeVar213, nodeVar188 ), dot( nodeVar214, nodeVar193 ), dot( nodeVar215, nodeVar194 ), dot( nodeVar216, nodeVar195 ) ) ) ) * knobs.warp ) * knobs.amplitude ) * 0.22 ) );
	nodeVar220 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( - nodeVar3 ) * nodeVar219 ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( nodeVar185 * nodeVar219 ) ), 0.0, 1.0 ) ) );
	nodeVar221 = picture_read( nodeVar1 );

	if ( nodeVar5 ) {

		nodeVar222 = 0.08;

	} else {

		nodeVar222 = 0.14;

	}

	nodeVar223 = vec4<f32>( clamp( mix( vec3<f32>( nodeVar220.x, nodeVar220.y, nodeVar220.z ), vec3<f32>( nodeVar221.x, nodeVar221.y, nodeVar221.z ), ( nodeVar222 * ( 1.0 - clamp( ( knobs.amplitude * 8.0 ), 0.0, 0.85 ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	nodeVar224 = vec3<f32>( nodeVar223.x, nodeVar223.y, nodeVar223.z );
	nodeVar225 = ( ( ( nodeVar224.x * 0.2126 ) + ( nodeVar224.y * 0.7152 ) ) + ( nodeVar224.z * 0.0722 ) );
	nodeVar226 = mix( vec3<f32>( nodeVar225, nodeVar225, nodeVar225 ), nodeVar224, f32(1.0) );
	nodeVar227 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar226.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar226.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar226.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar226.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar226.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar226.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar226.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar226.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar226.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar223.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar227.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar227.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar228 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar228;

	// result

	output.color = nodeVar228;

	output.color = to_shelf(output.color);
	return output;

}

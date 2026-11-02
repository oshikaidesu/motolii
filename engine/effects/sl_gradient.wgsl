// Mesh Gradient: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --track@activePoints:Active Points,2,5,5,1
// --track@point1Weight:Point 1 Weight,0,3,1.2,0.01
// --track@point2Weight:Point 2 Weight,0,3,1,0.01
// --track@point3Weight:Point 3 Weight,0,3,0.9,0.01
// --track@point4Weight:Point 4 Weight,0,3,1,0.01
// --track@point5Weight:Point 5 Weight,0,3,1.1,0.01
// --check@distortionMode:Mode,0
// --track@softness:Softness,0,1,0.7,0.01
// --track@warp:Warp,0,1,0.3,0.01
// --track@detail:Detail,0,1,0.1,0.01
// --track@motionAmount:Amount,0,1,0.4,0.01
// --track@glowStrength:Glow Strength,0,1,0,0.01
// --track@glowThreshold:Glow Threshold,0,1,0,0.01
// --track@grainAmount:Grain,0,1,0.04,0.01
// --track@vignetteStrength:Vignette Strength,0,1,0,0.01
// --track@vignetteRadius:Vignette Radius,0,1.5,1.5,0.01
// --track@vignetteSoftness:Vignette Softness,0.01,1,1,0.01
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
  motionAmount: f32,
  warp: f32,
  detail: f32,
  distortionMode: f32,
  softness: f32,
  point1Weight: f32,
  activePoints: f32,
  point2Weight: f32,
  point3Weight: f32,
  point4Weight: f32,
  point5Weight: f32,
  glowThreshold: f32,
  glowStrength: f32,
  grainAmount: f32,
  vignetteRadius: f32,
  vignetteSoftness: f32,
  vignetteStrength: f32,
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
var<private> nodeVar0 : vec3<f32>;
var<private> nodeVar1 : vec4<f32>;
var<private> nodeVar2 : f32;
var<private> nodeVar3 : vec2<f32>;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec3<f32>;
var<private> nodeVar7 : vec3<f32>;
var<private> nodeVar8 : vec3<f32>;
var<private> nodeVar9 : vec3<f32>;
var<private> nodeVar10 : vec3<f32>;
var<private> nodeVar11 : vec3<f32>;
var<private> nodeVar12 : vec3<f32>;
var<private> nodeVar13 : vec3<f32>;
var<private> nodeVar14 : vec3<f32>;
var<private> nodeVar15 : vec3<f32>;
var<private> nodeVar16 : vec4<f32>;
var<private> nodeVar17 : vec4<f32>;
var<private> nodeVar18 : vec4<f32>;
var<private> nodeVar19 : vec4<f32>;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec3<f32>;
var<private> nodeVar22 : vec4<f32>;
var<private> nodeVar23 : vec4<f32>;
var<private> nodeVar24 : vec4<f32>;
var<private> nodeVar25 : vec4<f32>;
var<private> nodeVar26 : vec4<f32>;
var<private> nodeVar27 : vec4<f32>;
var<private> nodeVar28 : vec4<f32>;
var<private> nodeVar29 : vec4<f32>;
var<private> nodeVar30 : vec4<f32>;
var<private> nodeVar31 : vec4<f32>;
var<private> nodeVar32 : vec4<f32>;
var<private> nodeVar33 : vec3<f32>;
var<private> nodeVar34 : vec3<f32>;
var<private> nodeVar35 : vec3<f32>;
var<private> nodeVar36 : vec3<f32>;
var<private> nodeVar37 : vec4<f32>;
var<private> nodeVar38 : vec4<f32>;
var<private> nodeVar39 : vec3<f32>;
var<private> nodeVar40 : vec3<f32>;
var<private> nodeVar41 : vec3<f32>;
var<private> nodeVar42 : vec3<f32>;
var<private> nodeVar43 : vec3<f32>;
var<private> nodeVar44 : vec3<f32>;
var<private> nodeVar45 : vec3<f32>;
var<private> nodeVar46 : vec3<f32>;
var<private> nodeVar47 : vec3<f32>;
var<private> nodeVar48 : vec3<f32>;
var<private> nodeVar49 : vec4<f32>;
var<private> nodeVar50 : vec4<f32>;
var<private> nodeVar51 : vec4<f32>;
var<private> nodeVar52 : vec4<f32>;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : vec3<f32>;
var<private> nodeVar55 : vec4<f32>;
var<private> nodeVar56 : vec4<f32>;
var<private> nodeVar57 : vec4<f32>;
var<private> nodeVar58 : vec4<f32>;
var<private> nodeVar59 : vec4<f32>;
var<private> nodeVar60 : vec4<f32>;
var<private> nodeVar61 : vec4<f32>;
var<private> nodeVar62 : vec4<f32>;
var<private> nodeVar63 : vec4<f32>;
var<private> nodeVar64 : vec4<f32>;
var<private> nodeVar65 : vec4<f32>;
var<private> nodeVar66 : vec3<f32>;
var<private> nodeVar67 : vec3<f32>;
var<private> nodeVar68 : vec3<f32>;
var<private> nodeVar69 : vec3<f32>;
var<private> nodeVar70 : vec4<f32>;
var<private> nodeVar71 : vec4<f32>;
var<private> nodeVar72 : vec3<f32>;
var<private> nodeVar73 : f32;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : vec2<f32>;
var<private> nodeVar76 : vec2<f32>;
var<private> nodeVar77 : f32;
var<private> nodeVar78 : f32;
var<private> nodeVar79 : vec2<f32>;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : f32;
var<private> nodeVar82 : vec2<f32>;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : vec2<f32>;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : vec2<f32>;
var<private> nodeVar89 : f32;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : f32;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : vec2<f32>;
var<private> nodeVar94 : vec4<f32>;
var<private> nodeVar95 : vec3<f32>;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : vec3<f32>;
var<private> nodeVar98 : vec4<f32>;
var<private> nodeVar99 : f32;
var<private> nodeVar100 : vec2<f32>;
var<private> nodeVar101 : f32;
var<private> nodeVar102 : vec2<f32>;
var<private> nodeVar103 : vec3<f32>;
var<private> nodeVar104 : vec3<f32>;
var<private> nodeVar105 : vec3<f32>;
var<private> nodeVar106 : vec3<f32>;
var<private> nodeVar107 : vec3<f32>;
var<private> nodeVar108 : vec3<f32>;
var<private> nodeVar109 : vec3<f32>;
var<private> nodeVar110 : vec3<f32>;
var<private> nodeVar111 : vec3<f32>;
var<private> nodeVar112 : vec3<f32>;
var<private> nodeVar113 : vec4<f32>;
var<private> nodeVar114 : vec4<f32>;
var<private> nodeVar115 : vec4<f32>;
var<private> nodeVar116 : vec4<f32>;
var<private> nodeVar117 : f32;
var<private> nodeVar118 : vec3<f32>;
var<private> nodeVar119 : vec4<f32>;
var<private> nodeVar120 : vec4<f32>;
var<private> nodeVar121 : vec4<f32>;
var<private> nodeVar122 : vec4<f32>;
var<private> nodeVar123 : vec4<f32>;
var<private> nodeVar124 : vec4<f32>;
var<private> nodeVar125 : vec4<f32>;
var<private> nodeVar126 : vec4<f32>;
var<private> nodeVar127 : vec4<f32>;
var<private> nodeVar128 : vec4<f32>;
var<private> nodeVar129 : vec4<f32>;
var<private> nodeVar130 : vec3<f32>;
var<private> nodeVar131 : vec3<f32>;
var<private> nodeVar132 : vec3<f32>;
var<private> nodeVar133 : vec3<f32>;
var<private> nodeVar134 : vec4<f32>;
var<private> nodeVar135 : vec4<f32>;
var<private> nodeVar136 : vec3<f32>;
var<private> nodeVar137 : vec3<f32>;
var<private> nodeVar138 : vec3<f32>;
var<private> nodeVar139 : vec3<f32>;
var<private> nodeVar140 : vec3<f32>;
var<private> nodeVar141 : vec3<f32>;
var<private> nodeVar142 : vec3<f32>;
var<private> nodeVar143 : vec3<f32>;
var<private> nodeVar144 : vec3<f32>;
var<private> nodeVar145 : vec3<f32>;
var<private> nodeVar146 : vec4<f32>;
var<private> nodeVar147 : vec4<f32>;
var<private> nodeVar148 : vec4<f32>;
var<private> nodeVar149 : vec4<f32>;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : vec3<f32>;
var<private> nodeVar152 : vec4<f32>;
var<private> nodeVar153 : vec4<f32>;
var<private> nodeVar154 : vec4<f32>;
var<private> nodeVar155 : vec4<f32>;
var<private> nodeVar156 : vec4<f32>;
var<private> nodeVar157 : vec4<f32>;
var<private> nodeVar158 : vec4<f32>;
var<private> nodeVar159 : vec4<f32>;
var<private> nodeVar160 : vec4<f32>;
var<private> nodeVar161 : vec4<f32>;
var<private> nodeVar162 : vec4<f32>;
var<private> nodeVar163 : vec3<f32>;
var<private> nodeVar164 : vec3<f32>;
var<private> nodeVar165 : vec3<f32>;
var<private> nodeVar166 : vec3<f32>;
var<private> nodeVar167 : vec4<f32>;
var<private> nodeVar168 : vec4<f32>;
var<private> nodeVar169 : vec3<f32>;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : vec2<f32>;
var<private> nodeVar173 : vec2<f32>;
var<private> nodeVar174 : f32;
var<private> nodeVar175 : f32;
var<private> nodeVar176 : vec2<f32>;
var<private> nodeVar177 : f32;
var<private> nodeVar178 : f32;
var<private> nodeVar179 : vec2<f32>;
var<private> nodeVar180 : f32;
var<private> nodeVar181 : f32;
var<private> nodeVar182 : vec2<f32>;
var<private> nodeVar183 : f32;
var<private> nodeVar184 : f32;
var<private> nodeVar185 : vec2<f32>;
var<private> nodeVar186 : f32;
var<private> nodeVar187 : f32;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : f32;
var<private> nodeVar190 : vec2<f32>;
var<private> nodeVar191 : vec4<f32>;
var<private> nodeVar192 : vec3<f32>;
var<private> nodeVar193 : f32;
var<private> nodeVar194 : vec3<f32>;
var<private> nodeVar195 : vec4<f32>;
var<private> nodeVar196 : f32;
var<private> nodeVar197 : f32;
var<private> nodeVar198 : f32;
var<private> nodeVar199 : f32;
var<private> nodeVar200 : vec2<f32>;
var<private> nodeVar201 : f32;
var<private> nodeVar202 : vec2<f32>;
var<private> nodeVar203 : vec3<f32>;
var<private> nodeVar204 : vec3<f32>;
var<private> nodeVar205 : vec3<f32>;
var<private> nodeVar206 : vec3<f32>;
var<private> nodeVar207 : vec3<f32>;
var<private> nodeVar208 : vec3<f32>;
var<private> nodeVar209 : vec3<f32>;
var<private> nodeVar210 : vec3<f32>;
var<private> nodeVar211 : vec3<f32>;
var<private> nodeVar212 : vec3<f32>;
var<private> nodeVar213 : vec4<f32>;
var<private> nodeVar214 : vec4<f32>;
var<private> nodeVar215 : vec4<f32>;
var<private> nodeVar216 : vec4<f32>;
var<private> nodeVar217 : f32;
var<private> nodeVar218 : vec3<f32>;
var<private> nodeVar219 : vec4<f32>;
var<private> nodeVar220 : vec4<f32>;
var<private> nodeVar221 : vec4<f32>;
var<private> nodeVar222 : vec4<f32>;
var<private> nodeVar223 : vec4<f32>;
var<private> nodeVar224 : vec4<f32>;
var<private> nodeVar225 : vec4<f32>;
var<private> nodeVar226 : vec4<f32>;
var<private> nodeVar227 : vec4<f32>;
var<private> nodeVar228 : vec4<f32>;
var<private> nodeVar229 : vec4<f32>;
var<private> nodeVar230 : vec3<f32>;
var<private> nodeVar231 : vec3<f32>;
var<private> nodeVar232 : vec3<f32>;
var<private> nodeVar233 : vec3<f32>;
var<private> nodeVar234 : vec4<f32>;
var<private> nodeVar235 : vec4<f32>;
var<private> nodeVar236 : vec3<f32>;
var<private> nodeVar237 : vec3<f32>;
var<private> nodeVar238 : vec3<f32>;
var<private> nodeVar239 : vec3<f32>;
var<private> nodeVar240 : vec3<f32>;
var<private> nodeVar241 : vec3<f32>;
var<private> nodeVar242 : vec3<f32>;
var<private> nodeVar243 : vec3<f32>;
var<private> nodeVar244 : vec3<f32>;
var<private> nodeVar245 : vec3<f32>;
var<private> nodeVar246 : vec4<f32>;
var<private> nodeVar247 : vec4<f32>;
var<private> nodeVar248 : vec4<f32>;
var<private> nodeVar249 : vec4<f32>;
var<private> nodeVar250 : f32;
var<private> nodeVar251 : vec3<f32>;
var<private> nodeVar252 : vec4<f32>;
var<private> nodeVar253 : vec4<f32>;
var<private> nodeVar254 : vec4<f32>;
var<private> nodeVar255 : vec4<f32>;
var<private> nodeVar256 : vec4<f32>;
var<private> nodeVar257 : vec4<f32>;
var<private> nodeVar258 : vec4<f32>;
var<private> nodeVar259 : vec4<f32>;
var<private> nodeVar260 : vec4<f32>;
var<private> nodeVar261 : vec4<f32>;
var<private> nodeVar262 : vec4<f32>;
var<private> nodeVar263 : vec3<f32>;
var<private> nodeVar264 : vec3<f32>;
var<private> nodeVar265 : vec3<f32>;
var<private> nodeVar266 : vec3<f32>;
var<private> nodeVar267 : vec4<f32>;
var<private> nodeVar268 : vec4<f32>;
var<private> nodeVar269 : vec3<f32>;
var<private> nodeVar270 : f32;
var<private> nodeVar271 : f32;
var<private> nodeVar272 : vec2<f32>;
var<private> nodeVar273 : vec2<f32>;
var<private> nodeVar274 : f32;
var<private> nodeVar275 : f32;
var<private> nodeVar276 : vec2<f32>;
var<private> nodeVar277 : f32;
var<private> nodeVar278 : f32;
var<private> nodeVar279 : vec2<f32>;
var<private> nodeVar280 : f32;
var<private> nodeVar281 : f32;
var<private> nodeVar282 : vec2<f32>;
var<private> nodeVar283 : f32;
var<private> nodeVar284 : f32;
var<private> nodeVar285 : vec2<f32>;
var<private> nodeVar286 : f32;
var<private> nodeVar287 : f32;
var<private> nodeVar288 : f32;
var<private> nodeVar289 : f32;
var<private> nodeVar290 : vec2<f32>;
var<private> nodeVar291 : vec4<f32>;
var<private> nodeVar292 : vec3<f32>;
var<private> nodeVar293 : f32;
var<private> nodeVar294 : vec3<f32>;
var<private> nodeVar295 : f32;
var<private> Output : vec4<f32>;
var<private> nodeVar296 : vec4<f32>;

// codes
fn tsl_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }
fn tsl_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar1 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );

	if ( ( clamp( nodeVar1.w, 0.0, 1.0 ) == 1.0 ) ) {

		nodeVar2 = ( ( knobs.time * f32(1.2566370614359172) ) * f32(1.0) );
		nodeVar3 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * (0.0009259259259259262 * knobs.resolution.x + -2.220446049250313e-16) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( nodeVar2 ) * knobs.motionAmount ) * 0.06 ) ) ) );
		nodeVar4 = ( (0.75 * knobs.warp + 0) / pow( 1.0, (-0.7999999999999998 * knobs.detail + 1.6) ) );
		nodeVar5 = ( ( ( nodeVar3 * vec2<f32>( (1.6000000000000005 * knobs.detail + 0.7299999999999998) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
		nodeVar6 = vec3<f32>( nodeVar5, 100.0 );
		nodeVar7 = floor( ( nodeVar6 + vec3<f32>( dot( nodeVar6, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar8 = ( ( nodeVar6 - nodeVar7 ) + vec3<f32>( dot( nodeVar7, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar9 = step( nodeVar8.yzx, nodeVar8 );
		nodeVar10 = ( vec3<f32>( 1.0 ) - nodeVar9 );
		nodeVar11 = min( nodeVar9, nodeVar10.zxy );
		nodeVar12 = max( nodeVar9, nodeVar10.zxy );
		nodeVar13 = ( ( nodeVar8 - nodeVar11 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar14 = ( ( nodeVar8 - nodeVar12 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar15 = ( ( nodeVar8 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar7 = tsl_mod_vec3( nodeVar7, vec3<f32>( 289.0 ) );
		nodeVar16 = ( vec4<f32>( nodeVar7.z ) + vec4<f32>( 0.0, nodeVar11.z, nodeVar12.z, 1.0 ) );
		nodeVar17 = ( tsl_mod_vec4( ( ( ( nodeVar16 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar16 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar7.y ) + vec4<f32>( 0.0, nodeVar11.y, nodeVar12.y, 1.0 ) ) );
		nodeVar18 = ( tsl_mod_vec4( ( ( ( nodeVar17 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar17 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar7.x ) + vec4<f32>( 0.0, nodeVar11.x, nodeVar12.x, 1.0 ) ) );
		nodeVar19 = tsl_mod_vec4( ( ( ( nodeVar18 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar18 ), vec4<f32>( 289.0 ) );
		nodeVar20 = 0.14285714285714285;
		nodeVar21 = ( ( vec3<f32>( nodeVar20 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar22 = ( nodeVar19 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar19 * vec4<f32>( ( nodeVar21.z * nodeVar21.z ) ) ) ) ) );
		nodeVar23 = ( ( floor( ( nodeVar22 * vec4<f32>( nodeVar21.z ) ) ) * vec4<f32>( nodeVar21.x ) ) + vec4<f32>( nodeVar21, 1.0 ).yyyy );
		nodeVar24 = ( ( floor( ( nodeVar22 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar22 * vec4<f32>( nodeVar21.z ) ) ) ) ) ) * vec4<f32>( nodeVar21.x ) ) + vec4<f32>( nodeVar21, 1.0 ).yyyy );
		nodeVar25 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar23 ) - abs( nodeVar24 ) ) );
		nodeVar26 = vec4<f32>( nodeVar23.xy, nodeVar24.xy );
		nodeVar27 = vec4<f32>( nodeVar23.zw, nodeVar24.zw );
		nodeVar28 = ( ( floor( nodeVar26 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar29 = ( ( floor( nodeVar27 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar30 = ( - step( nodeVar25, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar31 = ( nodeVar26.xzyw + ( nodeVar28.xzyw * nodeVar30.xxyy ) );
		nodeVar32 = ( nodeVar27.xzyw + ( nodeVar29.xzyw * nodeVar30.zzww ) );
		nodeVar33 = vec3<f32>( nodeVar31.xy, nodeVar25.x );
		nodeVar34 = vec3<f32>( nodeVar31.zw, nodeVar25.y );
		nodeVar35 = vec3<f32>( nodeVar32.xy, nodeVar25.z );
		nodeVar36 = vec3<f32>( nodeVar32.zw, nodeVar25.w );
		nodeVar37 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar33, nodeVar33 ), dot( nodeVar34, nodeVar34 ), dot( nodeVar35, nodeVar35 ), dot( nodeVar36, nodeVar36 ) ) ) );
		nodeVar33 = ( nodeVar33 * vec3<f32>( nodeVar37.x ) );
		nodeVar34 = ( nodeVar34 * vec3<f32>( nodeVar37.y ) );
		nodeVar35 = ( nodeVar35 * vec3<f32>( nodeVar37.z ) );
		nodeVar36 = ( nodeVar36 * vec3<f32>( nodeVar37.w ) );
		nodeVar38 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar8, nodeVar8 ), dot( nodeVar13, nodeVar13 ), dot( nodeVar14, nodeVar14 ), dot( nodeVar15, nodeVar15 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar38 = ( nodeVar38 * nodeVar38 );
		nodeVar3.x = ( nodeVar3.x + ( ( nodeVar4 * ( 42.0 * dot( ( nodeVar38 * nodeVar38 ), vec4<f32>( dot( nodeVar33, nodeVar8 ), dot( nodeVar34, nodeVar13 ), dot( nodeVar35, nodeVar14 ), dot( nodeVar36, nodeVar15 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
		nodeVar39 = vec3<f32>( ( nodeVar5 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
		nodeVar40 = floor( ( nodeVar39 + vec3<f32>( dot( nodeVar39, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar41 = ( ( nodeVar39 - nodeVar40 ) + vec3<f32>( dot( nodeVar40, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar42 = step( nodeVar41.yzx, nodeVar41 );
		nodeVar43 = ( vec3<f32>( 1.0 ) - nodeVar42 );
		nodeVar44 = min( nodeVar42, nodeVar43.zxy );
		nodeVar45 = max( nodeVar42, nodeVar43.zxy );
		nodeVar46 = ( ( nodeVar41 - nodeVar44 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar47 = ( ( nodeVar41 - nodeVar45 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar48 = ( ( nodeVar41 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar40 = tsl_mod_vec3( nodeVar40, vec3<f32>( 289.0 ) );
		nodeVar49 = ( vec4<f32>( nodeVar40.z ) + vec4<f32>( 0.0, nodeVar44.z, nodeVar45.z, 1.0 ) );
		nodeVar50 = ( tsl_mod_vec4( ( ( ( nodeVar49 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar49 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar40.y ) + vec4<f32>( 0.0, nodeVar44.y, nodeVar45.y, 1.0 ) ) );
		nodeVar51 = ( tsl_mod_vec4( ( ( ( nodeVar50 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar50 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar40.x ) + vec4<f32>( 0.0, nodeVar44.x, nodeVar45.x, 1.0 ) ) );
		nodeVar52 = tsl_mod_vec4( ( ( ( nodeVar51 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar51 ), vec4<f32>( 289.0 ) );
		nodeVar53 = 0.14285714285714285;
		nodeVar54 = ( ( vec3<f32>( nodeVar53 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar55 = ( nodeVar52 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar52 * vec4<f32>( ( nodeVar54.z * nodeVar54.z ) ) ) ) ) );
		nodeVar56 = ( ( floor( ( nodeVar55 * vec4<f32>( nodeVar54.z ) ) ) * vec4<f32>( nodeVar54.x ) ) + vec4<f32>( nodeVar54, 1.0 ).yyyy );
		nodeVar57 = ( ( floor( ( nodeVar55 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar55 * vec4<f32>( nodeVar54.z ) ) ) ) ) ) * vec4<f32>( nodeVar54.x ) ) + vec4<f32>( nodeVar54, 1.0 ).yyyy );
		nodeVar58 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar56 ) - abs( nodeVar57 ) ) );
		nodeVar59 = vec4<f32>( nodeVar56.xy, nodeVar57.xy );
		nodeVar60 = vec4<f32>( nodeVar56.zw, nodeVar57.zw );
		nodeVar61 = ( ( floor( nodeVar59 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar62 = ( ( floor( nodeVar60 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar63 = ( - step( nodeVar58, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar64 = ( nodeVar59.xzyw + ( nodeVar61.xzyw * nodeVar63.xxyy ) );
		nodeVar65 = ( nodeVar60.xzyw + ( nodeVar62.xzyw * nodeVar63.zzww ) );
		nodeVar66 = vec3<f32>( nodeVar64.xy, nodeVar58.x );
		nodeVar67 = vec3<f32>( nodeVar64.zw, nodeVar58.y );
		nodeVar68 = vec3<f32>( nodeVar65.xy, nodeVar58.z );
		nodeVar69 = vec3<f32>( nodeVar65.zw, nodeVar58.w );
		nodeVar70 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar66, nodeVar66 ), dot( nodeVar67, nodeVar67 ), dot( nodeVar68, nodeVar68 ), dot( nodeVar69, nodeVar69 ) ) ) );
		nodeVar66 = ( nodeVar66 * vec3<f32>( nodeVar70.x ) );
		nodeVar67 = ( nodeVar67 * vec3<f32>( nodeVar70.y ) );
		nodeVar68 = ( nodeVar68 * vec3<f32>( nodeVar70.z ) );
		nodeVar69 = ( nodeVar69 * vec3<f32>( nodeVar70.w ) );
		nodeVar71 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar41, nodeVar41 ), dot( nodeVar46, nodeVar46 ), dot( nodeVar47, nodeVar47 ), dot( nodeVar48, nodeVar48 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar71 = ( nodeVar71 * nodeVar71 );
		nodeVar3.y = ( nodeVar3.y + ( ( nodeVar4 * ( 42.0 * dot( ( nodeVar71 * nodeVar71 ), vec4<f32>( dot( nodeVar66, nodeVar41 ), dot( nodeVar67, nodeVar46 ), dot( nodeVar68, nodeVar47 ), dot( nodeVar69, nodeVar48 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
		nodeVar72 = vec3<f32>( 0.0, 0.0, 0.0 );
		nodeVar73 = 0.0;
		nodeVar74 = ( sqrt( max( dot( nodeVar3, nodeVar3 ), 0.0001 ) ) * (0.69 * knobs.distortionMode + 0) );
		nodeVar75 = vec2<f32>( ( ( nodeVar3.x * cos( nodeVar74 ) ) - ( nodeVar3.y * sin( nodeVar74 ) ) ), ( ( nodeVar3.x * sin( nodeVar74 ) ) + ( nodeVar3.y * cos( nodeVar74 ) ) ) );
		nodeVar76 = ( nodeVar75 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 1.0 ) ) {

			nodeVar77 = 1.0;

		} else {

			nodeVar77 = 0.0;

		}

		nodeVar78 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar76, nodeVar76 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point1Weight ) * ( 1.0 + ( ( sin( ( nodeVar2 + ( 1.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar77 );
		nodeVar72 = ( nodeVar72 + ( vec3<f32>( f32(1.0), f32(0.19461783043107173), f32(0.09989872823822872) ) * vec3<f32>( nodeVar78 ) ) );
		nodeVar73 = ( nodeVar73 + nodeVar78 );
		nodeVar79 = ( nodeVar75 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 2.0 ) ) {

			nodeVar80 = 1.0;

		} else {

			nodeVar80 = 0.0;

		}

		nodeVar81 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar79, nodeVar79 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point2Weight ) * ( 1.0 + ( ( sin( ( nodeVar2 + ( 2.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar80 );
		nodeVar72 = ( nodeVar72 + ( vec3<f32>( f32(1.0), f32(0.6938717612856897), f32(0.4793201830913402) ) * vec3<f32>( nodeVar81 ) ) );
		nodeVar73 = ( nodeVar73 + nodeVar81 );
		nodeVar82 = ( nodeVar75 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 3.0 ) ) {

			nodeVar83 = 1.0;

		} else {

			nodeVar83 = 0.0;

		}

		nodeVar84 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar82, nodeVar82 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point3Weight ) * ( 1.0 + ( ( sin( ( nodeVar2 + ( 3.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar83 );
		nodeVar72 = ( nodeVar72 + ( vec3<f32>( f32(1.0), f32(0.450785782828426), f32(0.5711248294565854) ) * vec3<f32>( nodeVar84 ) ) );
		nodeVar73 = ( nodeVar73 + nodeVar84 );
		nodeVar85 = ( nodeVar75 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 4.0 ) ) {

			nodeVar86 = 1.0;

		} else {

			nodeVar86 = 0.0;

		}

		nodeVar87 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar85, nodeVar85 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point4Weight ) * ( 1.0 + ( ( sin( ( nodeVar2 + ( 4.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar86 );
		nodeVar72 = ( nodeVar72 + ( vec3<f32>( f32(1.0), f32(0.5775804404214573), f32(0.09530746662221588) ) * vec3<f32>( nodeVar87 ) ) );
		nodeVar73 = ( nodeVar73 + nodeVar87 );
		nodeVar88 = ( nodeVar75 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 5.0 ) ) {

			nodeVar89 = 1.0;

		} else {

			nodeVar89 = 0.0;

		}

		nodeVar90 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar88, nodeVar88 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point5Weight ) * ( 1.0 + ( ( sin( ( nodeVar2 + ( 5.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar89 );
		nodeVar72 = ( nodeVar72 + ( vec3<f32>( f32(1.0), f32(0.8796223968851662), f32(0.7681511472425809) ) * vec3<f32>( nodeVar90 ) ) );
		nodeVar73 = ( nodeVar73 + nodeVar90 );
		nodeVar72 = ( nodeVar72 / vec3<f32>( max( nodeVar73, 0.0001 ) ) );
		nodeVar91 = ( smoothstep( knobs.glowThreshold, 1.0, dot( nodeVar72, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * knobs.glowStrength );
		nodeVar72 = ( nodeVar72 + vec3<f32>( nodeVar91, nodeVar91, nodeVar91 ) );
		nodeVar92 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * knobs.grainAmount );
		nodeVar72 = ( nodeVar72 + vec3<f32>( nodeVar92, nodeVar92, nodeVar92 ) );
		nodeVar93 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
		nodeVar72 = ( nodeVar72 * vec3<f32>( mix( 1.0, smoothstep( knobs.vignetteRadius, ( knobs.vignetteRadius - knobs.vignetteSoftness ), sqrt( max( dot( nodeVar93, nodeVar93 ), 0.0001 ) ) ), knobs.vignetteStrength ) ) );
		nodeVar94 = vec4<f32>( clamp( nodeVar72, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
		nodeVar95 = vec3<f32>( nodeVar94.x, nodeVar94.y, nodeVar94.z );
		nodeVar96 = ( ( ( nodeVar95.x * 0.2126 ) + ( nodeVar95.y * 0.7152 ) ) + ( nodeVar95.z * 0.0722 ) );
		nodeVar97 = mix( vec3<f32>( nodeVar96, nodeVar96, nodeVar96 ), nodeVar95, f32(1.0) );
		nodeVar98 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar97.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar97.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar97.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar97.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar97.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar97.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar97.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar97.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar97.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar94.w, 0.0, 1.0 ) );
		nodeVar0 = mix( nodeVar1.xyz, nodeVar98.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar98.w, 0.0, 1.0 ) ) );

	} else {

		nodeVar99 = ( ( knobs.time * f32(1.2566370614359172) ) * f32(1.0) );
		nodeVar100 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * (0.0009259259259259262 * knobs.resolution.x + -2.220446049250313e-16) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( nodeVar99 ) * knobs.motionAmount ) * 0.06 ) ) ) );
		nodeVar101 = ( (0.75 * knobs.warp + 0) / pow( 1.0, (-0.7999999999999998 * knobs.detail + 1.6) ) );
		nodeVar102 = ( ( ( nodeVar100 * vec2<f32>( (1.6000000000000005 * knobs.detail + 0.7299999999999998) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
		nodeVar103 = vec3<f32>( nodeVar102, 100.0 );
		nodeVar104 = floor( ( nodeVar103 + vec3<f32>( dot( nodeVar103, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar105 = ( ( nodeVar103 - nodeVar104 ) + vec3<f32>( dot( nodeVar104, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar106 = step( nodeVar105.yzx, nodeVar105 );
		nodeVar107 = ( vec3<f32>( 1.0 ) - nodeVar106 );
		nodeVar108 = min( nodeVar106, nodeVar107.zxy );
		nodeVar109 = max( nodeVar106, nodeVar107.zxy );
		nodeVar110 = ( ( nodeVar105 - nodeVar108 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar111 = ( ( nodeVar105 - nodeVar109 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar112 = ( ( nodeVar105 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar104 = tsl_mod_vec3( nodeVar104, vec3<f32>( 289.0 ) );
		nodeVar113 = ( vec4<f32>( nodeVar104.z ) + vec4<f32>( 0.0, nodeVar108.z, nodeVar109.z, 1.0 ) );
		nodeVar114 = ( tsl_mod_vec4( ( ( ( nodeVar113 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar113 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar104.y ) + vec4<f32>( 0.0, nodeVar108.y, nodeVar109.y, 1.0 ) ) );
		nodeVar115 = ( tsl_mod_vec4( ( ( ( nodeVar114 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar114 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar104.x ) + vec4<f32>( 0.0, nodeVar108.x, nodeVar109.x, 1.0 ) ) );
		nodeVar116 = tsl_mod_vec4( ( ( ( nodeVar115 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar115 ), vec4<f32>( 289.0 ) );
		nodeVar117 = 0.14285714285714285;
		nodeVar118 = ( ( vec3<f32>( nodeVar117 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar119 = ( nodeVar116 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar116 * vec4<f32>( ( nodeVar118.z * nodeVar118.z ) ) ) ) ) );
		nodeVar120 = ( ( floor( ( nodeVar119 * vec4<f32>( nodeVar118.z ) ) ) * vec4<f32>( nodeVar118.x ) ) + vec4<f32>( nodeVar118, 1.0 ).yyyy );
		nodeVar121 = ( ( floor( ( nodeVar119 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar119 * vec4<f32>( nodeVar118.z ) ) ) ) ) ) * vec4<f32>( nodeVar118.x ) ) + vec4<f32>( nodeVar118, 1.0 ).yyyy );
		nodeVar122 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar120 ) - abs( nodeVar121 ) ) );
		nodeVar123 = vec4<f32>( nodeVar120.xy, nodeVar121.xy );
		nodeVar124 = vec4<f32>( nodeVar120.zw, nodeVar121.zw );
		nodeVar125 = ( ( floor( nodeVar123 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar126 = ( ( floor( nodeVar124 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar127 = ( - step( nodeVar122, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar128 = ( nodeVar123.xzyw + ( nodeVar125.xzyw * nodeVar127.xxyy ) );
		nodeVar129 = ( nodeVar124.xzyw + ( nodeVar126.xzyw * nodeVar127.zzww ) );
		nodeVar130 = vec3<f32>( nodeVar128.xy, nodeVar122.x );
		nodeVar131 = vec3<f32>( nodeVar128.zw, nodeVar122.y );
		nodeVar132 = vec3<f32>( nodeVar129.xy, nodeVar122.z );
		nodeVar133 = vec3<f32>( nodeVar129.zw, nodeVar122.w );
		nodeVar134 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar130, nodeVar130 ), dot( nodeVar131, nodeVar131 ), dot( nodeVar132, nodeVar132 ), dot( nodeVar133, nodeVar133 ) ) ) );
		nodeVar130 = ( nodeVar130 * vec3<f32>( nodeVar134.x ) );
		nodeVar131 = ( nodeVar131 * vec3<f32>( nodeVar134.y ) );
		nodeVar132 = ( nodeVar132 * vec3<f32>( nodeVar134.z ) );
		nodeVar133 = ( nodeVar133 * vec3<f32>( nodeVar134.w ) );
		nodeVar135 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar105, nodeVar105 ), dot( nodeVar110, nodeVar110 ), dot( nodeVar111, nodeVar111 ), dot( nodeVar112, nodeVar112 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar135 = ( nodeVar135 * nodeVar135 );
		nodeVar100.x = ( nodeVar100.x + ( ( nodeVar101 * ( 42.0 * dot( ( nodeVar135 * nodeVar135 ), vec4<f32>( dot( nodeVar130, nodeVar105 ), dot( nodeVar131, nodeVar110 ), dot( nodeVar132, nodeVar111 ), dot( nodeVar133, nodeVar112 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
		nodeVar136 = vec3<f32>( ( nodeVar102 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
		nodeVar137 = floor( ( nodeVar136 + vec3<f32>( dot( nodeVar136, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		nodeVar138 = ( ( nodeVar136 - nodeVar137 ) + vec3<f32>( dot( nodeVar137, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		nodeVar139 = step( nodeVar138.yzx, nodeVar138 );
		nodeVar140 = ( vec3<f32>( 1.0 ) - nodeVar139 );
		nodeVar141 = min( nodeVar139, nodeVar140.zxy );
		nodeVar142 = max( nodeVar139, nodeVar140.zxy );
		nodeVar143 = ( ( nodeVar138 - nodeVar141 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar144 = ( ( nodeVar138 - nodeVar142 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar145 = ( ( nodeVar138 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		nodeVar137 = tsl_mod_vec3( nodeVar137, vec3<f32>( 289.0 ) );
		nodeVar146 = ( vec4<f32>( nodeVar137.z ) + vec4<f32>( 0.0, nodeVar141.z, nodeVar142.z, 1.0 ) );
		nodeVar147 = ( tsl_mod_vec4( ( ( ( nodeVar146 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar146 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar137.y ) + vec4<f32>( 0.0, nodeVar141.y, nodeVar142.y, 1.0 ) ) );
		nodeVar148 = ( tsl_mod_vec4( ( ( ( nodeVar147 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar147 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar137.x ) + vec4<f32>( 0.0, nodeVar141.x, nodeVar142.x, 1.0 ) ) );
		nodeVar149 = tsl_mod_vec4( ( ( ( nodeVar148 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar148 ), vec4<f32>( 289.0 ) );
		nodeVar150 = 0.14285714285714285;
		nodeVar151 = ( ( vec3<f32>( nodeVar150 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		nodeVar152 = ( nodeVar149 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar149 * vec4<f32>( ( nodeVar151.z * nodeVar151.z ) ) ) ) ) );
		nodeVar153 = ( ( floor( ( nodeVar152 * vec4<f32>( nodeVar151.z ) ) ) * vec4<f32>( nodeVar151.x ) ) + vec4<f32>( nodeVar151, 1.0 ).yyyy );
		nodeVar154 = ( ( floor( ( nodeVar152 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar152 * vec4<f32>( nodeVar151.z ) ) ) ) ) ) * vec4<f32>( nodeVar151.x ) ) + vec4<f32>( nodeVar151, 1.0 ).yyyy );
		nodeVar155 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar153 ) - abs( nodeVar154 ) ) );
		nodeVar156 = vec4<f32>( nodeVar153.xy, nodeVar154.xy );
		nodeVar157 = vec4<f32>( nodeVar153.zw, nodeVar154.zw );
		nodeVar158 = ( ( floor( nodeVar156 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar159 = ( ( floor( nodeVar157 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		nodeVar160 = ( - step( nodeVar155, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		nodeVar161 = ( nodeVar156.xzyw + ( nodeVar158.xzyw * nodeVar160.xxyy ) );
		nodeVar162 = ( nodeVar157.xzyw + ( nodeVar159.xzyw * nodeVar160.zzww ) );
		nodeVar163 = vec3<f32>( nodeVar161.xy, nodeVar155.x );
		nodeVar164 = vec3<f32>( nodeVar161.zw, nodeVar155.y );
		nodeVar165 = vec3<f32>( nodeVar162.xy, nodeVar155.z );
		nodeVar166 = vec3<f32>( nodeVar162.zw, nodeVar155.w );
		nodeVar167 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar163, nodeVar163 ), dot( nodeVar164, nodeVar164 ), dot( nodeVar165, nodeVar165 ), dot( nodeVar166, nodeVar166 ) ) ) );
		nodeVar163 = ( nodeVar163 * vec3<f32>( nodeVar167.x ) );
		nodeVar164 = ( nodeVar164 * vec3<f32>( nodeVar167.y ) );
		nodeVar165 = ( nodeVar165 * vec3<f32>( nodeVar167.z ) );
		nodeVar166 = ( nodeVar166 * vec3<f32>( nodeVar167.w ) );
		nodeVar168 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar138, nodeVar138 ), dot( nodeVar143, nodeVar143 ), dot( nodeVar144, nodeVar144 ), dot( nodeVar145, nodeVar145 ) ) ), vec4<f32>( 0.0 ) );
		nodeVar168 = ( nodeVar168 * nodeVar168 );
		nodeVar100.y = ( nodeVar100.y + ( ( nodeVar101 * ( 42.0 * dot( ( nodeVar168 * nodeVar168 ), vec4<f32>( dot( nodeVar163, nodeVar138 ), dot( nodeVar164, nodeVar143 ), dot( nodeVar165, nodeVar144 ), dot( nodeVar166, nodeVar145 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
		nodeVar169 = vec3<f32>( 0.0, 0.0, 0.0 );
		nodeVar170 = 0.0;
		nodeVar171 = ( sqrt( max( dot( nodeVar100, nodeVar100 ), 0.0001 ) ) * (0.69 * knobs.distortionMode + 0) );
		nodeVar172 = vec2<f32>( ( ( nodeVar100.x * cos( nodeVar171 ) ) - ( nodeVar100.y * sin( nodeVar171 ) ) ), ( ( nodeVar100.x * sin( nodeVar171 ) ) + ( nodeVar100.y * cos( nodeVar171 ) ) ) );
		nodeVar173 = ( nodeVar172 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 1.0 ) ) {

			nodeVar174 = 1.0;

		} else {

			nodeVar174 = 0.0;

		}

		nodeVar175 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar173, nodeVar173 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point1Weight ) * ( 1.0 + ( ( sin( ( nodeVar99 + ( 1.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar174 );
		nodeVar169 = ( nodeVar169 + ( vec3<f32>( f32(1.0), f32(0.19461783043107173), f32(0.09989872823822872) ) * vec3<f32>( nodeVar175 ) ) );
		nodeVar170 = ( nodeVar170 + nodeVar175 );
		nodeVar176 = ( nodeVar172 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 2.0 ) ) {

			nodeVar177 = 1.0;

		} else {

			nodeVar177 = 0.0;

		}

		nodeVar178 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar176, nodeVar176 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point2Weight ) * ( 1.0 + ( ( sin( ( nodeVar99 + ( 2.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar177 );
		nodeVar169 = ( nodeVar169 + ( vec3<f32>( f32(1.0), f32(0.6938717612856897), f32(0.4793201830913402) ) * vec3<f32>( nodeVar178 ) ) );
		nodeVar170 = ( nodeVar170 + nodeVar178 );
		nodeVar179 = ( nodeVar172 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 3.0 ) ) {

			nodeVar180 = 1.0;

		} else {

			nodeVar180 = 0.0;

		}

		nodeVar181 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar179, nodeVar179 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point3Weight ) * ( 1.0 + ( ( sin( ( nodeVar99 + ( 3.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar180 );
		nodeVar169 = ( nodeVar169 + ( vec3<f32>( f32(1.0), f32(0.450785782828426), f32(0.5711248294565854) ) * vec3<f32>( nodeVar181 ) ) );
		nodeVar170 = ( nodeVar170 + nodeVar181 );
		nodeVar182 = ( nodeVar172 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 4.0 ) ) {

			nodeVar183 = 1.0;

		} else {

			nodeVar183 = 0.0;

		}

		nodeVar184 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar182, nodeVar182 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point4Weight ) * ( 1.0 + ( ( sin( ( nodeVar99 + ( 4.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar183 );
		nodeVar169 = ( nodeVar169 + ( vec3<f32>( f32(1.0), f32(0.5775804404214573), f32(0.09530746662221588) ) * vec3<f32>( nodeVar184 ) ) );
		nodeVar170 = ( nodeVar170 + nodeVar184 );
		nodeVar185 = ( nodeVar172 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( knobs.activePoints >= 5.0 ) ) {

			nodeVar186 = 1.0;

		} else {

			nodeVar186 = 0.0;

		}

		nodeVar187 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar185, nodeVar185 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point5Weight ) * ( 1.0 + ( ( sin( ( nodeVar99 + ( 5.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar186 );
		nodeVar169 = ( nodeVar169 + ( vec3<f32>( f32(1.0), f32(0.8796223968851662), f32(0.7681511472425809) ) * vec3<f32>( nodeVar187 ) ) );
		nodeVar170 = ( nodeVar170 + nodeVar187 );
		nodeVar169 = ( nodeVar169 / vec3<f32>( max( nodeVar170, 0.0001 ) ) );
		nodeVar188 = ( smoothstep( knobs.glowThreshold, 1.0, dot( nodeVar169, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * knobs.glowStrength );
		nodeVar169 = ( nodeVar169 + vec3<f32>( nodeVar188, nodeVar188, nodeVar188 ) );
		nodeVar189 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * knobs.grainAmount );
		nodeVar169 = ( nodeVar169 + vec3<f32>( nodeVar189, nodeVar189, nodeVar189 ) );
		nodeVar190 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
		nodeVar169 = ( nodeVar169 * vec3<f32>( mix( 1.0, smoothstep( knobs.vignetteRadius, ( knobs.vignetteRadius - knobs.vignetteSoftness ), sqrt( max( dot( nodeVar190, nodeVar190 ), 0.0001 ) ) ), knobs.vignetteStrength ) ) );
		nodeVar191 = vec4<f32>( clamp( nodeVar169, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
		nodeVar192 = vec3<f32>( nodeVar191.x, nodeVar191.y, nodeVar191.z );
		nodeVar193 = ( ( ( nodeVar192.x * 0.2126 ) + ( nodeVar192.y * 0.7152 ) ) + ( nodeVar192.z * 0.0722 ) );
		nodeVar194 = mix( vec3<f32>( nodeVar193, nodeVar193, nodeVar193 ), nodeVar192, f32(1.0) );
		nodeVar195 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar194.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar194.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar194.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar194.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar194.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar194.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar194.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar194.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar194.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar191.w, 0.0, 1.0 ) );
		nodeVar196 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar195.w, 0.0, 1.0 ) );
		nodeVar198 = ( nodeVar196 + ( clamp( nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - nodeVar196 ) ) );

		if ( ( nodeVar198 > 0.0 ) ) {

			nodeVar197 = nodeVar198;

		} else {

			nodeVar197 = 1.0;

		}

		nodeVar0 = ( ( ( mix( nodeVar195.xyz, nodeVar195.xyz, clamp( nodeVar1.w, 0.0, 1.0 ) ) * vec3<f32>( nodeVar196 ) ) + ( ( nodeVar1.xyz * vec3<f32>( clamp( nodeVar1.w, 0.0, 1.0 ) ) ) * vec3<f32>( ( 1.0 - nodeVar196 ) ) ) ) / vec3<f32>( nodeVar197 ) );

	}

	nodeVar199 = ( ( knobs.time * f32(1.2566370614359172) ) * f32(1.0) );
	nodeVar200 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * (0.0009259259259259262 * knobs.resolution.x + -2.220446049250313e-16) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( nodeVar199 ) * knobs.motionAmount ) * 0.06 ) ) ) );
	nodeVar201 = ( (0.75 * knobs.warp + 0) / pow( 1.0, (-0.7999999999999998 * knobs.detail + 1.6) ) );
	nodeVar202 = ( ( ( nodeVar200 * vec2<f32>( (1.6000000000000005 * knobs.detail + 0.7299999999999998) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
	nodeVar203 = vec3<f32>( nodeVar202, 100.0 );
	nodeVar204 = floor( ( nodeVar203 + vec3<f32>( dot( nodeVar203, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	nodeVar205 = ( ( nodeVar203 - nodeVar204 ) + vec3<f32>( dot( nodeVar204, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	nodeVar206 = step( nodeVar205.yzx, nodeVar205 );
	nodeVar207 = ( vec3<f32>( 1.0 ) - nodeVar206 );
	nodeVar208 = min( nodeVar206, nodeVar207.zxy );
	nodeVar209 = max( nodeVar206, nodeVar207.zxy );
	nodeVar210 = ( ( nodeVar205 - nodeVar208 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar211 = ( ( nodeVar205 - nodeVar209 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar212 = ( ( nodeVar205 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar204 = tsl_mod_vec3( nodeVar204, vec3<f32>( 289.0 ) );
	nodeVar213 = ( vec4<f32>( nodeVar204.z ) + vec4<f32>( 0.0, nodeVar208.z, nodeVar209.z, 1.0 ) );
	nodeVar214 = ( tsl_mod_vec4( ( ( ( nodeVar213 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar213 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar204.y ) + vec4<f32>( 0.0, nodeVar208.y, nodeVar209.y, 1.0 ) ) );
	nodeVar215 = ( tsl_mod_vec4( ( ( ( nodeVar214 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar214 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar204.x ) + vec4<f32>( 0.0, nodeVar208.x, nodeVar209.x, 1.0 ) ) );
	nodeVar216 = tsl_mod_vec4( ( ( ( nodeVar215 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar215 ), vec4<f32>( 289.0 ) );
	nodeVar217 = 0.14285714285714285;
	nodeVar218 = ( ( vec3<f32>( nodeVar217 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	nodeVar219 = ( nodeVar216 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar216 * vec4<f32>( ( nodeVar218.z * nodeVar218.z ) ) ) ) ) );
	nodeVar220 = ( ( floor( ( nodeVar219 * vec4<f32>( nodeVar218.z ) ) ) * vec4<f32>( nodeVar218.x ) ) + vec4<f32>( nodeVar218, 1.0 ).yyyy );
	nodeVar221 = ( ( floor( ( nodeVar219 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar219 * vec4<f32>( nodeVar218.z ) ) ) ) ) ) * vec4<f32>( nodeVar218.x ) ) + vec4<f32>( nodeVar218, 1.0 ).yyyy );
	nodeVar222 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar220 ) - abs( nodeVar221 ) ) );
	nodeVar223 = vec4<f32>( nodeVar220.xy, nodeVar221.xy );
	nodeVar224 = vec4<f32>( nodeVar220.zw, nodeVar221.zw );
	nodeVar225 = ( ( floor( nodeVar223 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar226 = ( ( floor( nodeVar224 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar227 = ( - step( nodeVar222, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	nodeVar228 = ( nodeVar223.xzyw + ( nodeVar225.xzyw * nodeVar227.xxyy ) );
	nodeVar229 = ( nodeVar224.xzyw + ( nodeVar226.xzyw * nodeVar227.zzww ) );
	nodeVar230 = vec3<f32>( nodeVar228.xy, nodeVar222.x );
	nodeVar231 = vec3<f32>( nodeVar228.zw, nodeVar222.y );
	nodeVar232 = vec3<f32>( nodeVar229.xy, nodeVar222.z );
	nodeVar233 = vec3<f32>( nodeVar229.zw, nodeVar222.w );
	nodeVar234 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar230, nodeVar230 ), dot( nodeVar231, nodeVar231 ), dot( nodeVar232, nodeVar232 ), dot( nodeVar233, nodeVar233 ) ) ) );
	nodeVar230 = ( nodeVar230 * vec3<f32>( nodeVar234.x ) );
	nodeVar231 = ( nodeVar231 * vec3<f32>( nodeVar234.y ) );
	nodeVar232 = ( nodeVar232 * vec3<f32>( nodeVar234.z ) );
	nodeVar233 = ( nodeVar233 * vec3<f32>( nodeVar234.w ) );
	nodeVar235 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar205, nodeVar205 ), dot( nodeVar210, nodeVar210 ), dot( nodeVar211, nodeVar211 ), dot( nodeVar212, nodeVar212 ) ) ), vec4<f32>( 0.0 ) );
	nodeVar235 = ( nodeVar235 * nodeVar235 );
	nodeVar200.x = ( nodeVar200.x + ( ( nodeVar201 * ( 42.0 * dot( ( nodeVar235 * nodeVar235 ), vec4<f32>( dot( nodeVar230, nodeVar205 ), dot( nodeVar231, nodeVar210 ), dot( nodeVar232, nodeVar211 ), dot( nodeVar233, nodeVar212 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
	nodeVar236 = vec3<f32>( ( nodeVar202 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
	nodeVar237 = floor( ( nodeVar236 + vec3<f32>( dot( nodeVar236, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	nodeVar238 = ( ( nodeVar236 - nodeVar237 ) + vec3<f32>( dot( nodeVar237, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	nodeVar239 = step( nodeVar238.yzx, nodeVar238 );
	nodeVar240 = ( vec3<f32>( 1.0 ) - nodeVar239 );
	nodeVar241 = min( nodeVar239, nodeVar240.zxy );
	nodeVar242 = max( nodeVar239, nodeVar240.zxy );
	nodeVar243 = ( ( nodeVar238 - nodeVar241 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar244 = ( ( nodeVar238 - nodeVar242 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar245 = ( ( nodeVar238 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	nodeVar237 = tsl_mod_vec3( nodeVar237, vec3<f32>( 289.0 ) );
	nodeVar246 = ( vec4<f32>( nodeVar237.z ) + vec4<f32>( 0.0, nodeVar241.z, nodeVar242.z, 1.0 ) );
	nodeVar247 = ( tsl_mod_vec4( ( ( ( nodeVar246 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar246 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar237.y ) + vec4<f32>( 0.0, nodeVar241.y, nodeVar242.y, 1.0 ) ) );
	nodeVar248 = ( tsl_mod_vec4( ( ( ( nodeVar247 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar247 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( nodeVar237.x ) + vec4<f32>( 0.0, nodeVar241.x, nodeVar242.x, 1.0 ) ) );
	nodeVar249 = tsl_mod_vec4( ( ( ( nodeVar248 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * nodeVar248 ), vec4<f32>( 289.0 ) );
	nodeVar250 = 0.14285714285714285;
	nodeVar251 = ( ( vec3<f32>( nodeVar250 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	nodeVar252 = ( nodeVar249 - ( vec4<f32>( 49.0 ) * floor( ( nodeVar249 * vec4<f32>( ( nodeVar251.z * nodeVar251.z ) ) ) ) ) );
	nodeVar253 = ( ( floor( ( nodeVar252 * vec4<f32>( nodeVar251.z ) ) ) * vec4<f32>( nodeVar251.x ) ) + vec4<f32>( nodeVar251, 1.0 ).yyyy );
	nodeVar254 = ( ( floor( ( nodeVar252 - ( vec4<f32>( 7.0 ) * floor( ( nodeVar252 * vec4<f32>( nodeVar251.z ) ) ) ) ) ) * vec4<f32>( nodeVar251.x ) ) + vec4<f32>( nodeVar251, 1.0 ).yyyy );
	nodeVar255 = ( vec4<f32>( 1.0 ) - ( abs( nodeVar253 ) - abs( nodeVar254 ) ) );
	nodeVar256 = vec4<f32>( nodeVar253.xy, nodeVar254.xy );
	nodeVar257 = vec4<f32>( nodeVar253.zw, nodeVar254.zw );
	nodeVar258 = ( ( floor( nodeVar256 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar259 = ( ( floor( nodeVar257 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	nodeVar260 = ( - step( nodeVar255, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	nodeVar261 = ( nodeVar256.xzyw + ( nodeVar258.xzyw * nodeVar260.xxyy ) );
	nodeVar262 = ( nodeVar257.xzyw + ( nodeVar259.xzyw * nodeVar260.zzww ) );
	nodeVar263 = vec3<f32>( nodeVar261.xy, nodeVar255.x );
	nodeVar264 = vec3<f32>( nodeVar261.zw, nodeVar255.y );
	nodeVar265 = vec3<f32>( nodeVar262.xy, nodeVar255.z );
	nodeVar266 = vec3<f32>( nodeVar262.zw, nodeVar255.w );
	nodeVar267 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( nodeVar263, nodeVar263 ), dot( nodeVar264, nodeVar264 ), dot( nodeVar265, nodeVar265 ), dot( nodeVar266, nodeVar266 ) ) ) );
	nodeVar263 = ( nodeVar263 * vec3<f32>( nodeVar267.x ) );
	nodeVar264 = ( nodeVar264 * vec3<f32>( nodeVar267.y ) );
	nodeVar265 = ( nodeVar265 * vec3<f32>( nodeVar267.z ) );
	nodeVar266 = ( nodeVar266 * vec3<f32>( nodeVar267.w ) );
	nodeVar268 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( nodeVar238, nodeVar238 ), dot( nodeVar243, nodeVar243 ), dot( nodeVar244, nodeVar244 ), dot( nodeVar245, nodeVar245 ) ) ), vec4<f32>( 0.0 ) );
	nodeVar268 = ( nodeVar268 * nodeVar268 );
	nodeVar200.y = ( nodeVar200.y + ( ( nodeVar201 * ( 42.0 * dot( ( nodeVar268 * nodeVar268 ), vec4<f32>( dot( nodeVar263, nodeVar238 ), dot( nodeVar264, nodeVar243 ), dot( nodeVar265, nodeVar244 ), dot( nodeVar266, nodeVar245 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
	nodeVar269 = vec3<f32>( 0.0, 0.0, 0.0 );
	nodeVar270 = 0.0;
	nodeVar271 = ( sqrt( max( dot( nodeVar200, nodeVar200 ), 0.0001 ) ) * (0.69 * knobs.distortionMode + 0) );
	nodeVar272 = vec2<f32>( ( ( nodeVar200.x * cos( nodeVar271 ) ) - ( nodeVar200.y * sin( nodeVar271 ) ) ), ( ( nodeVar200.x * sin( nodeVar271 ) ) + ( nodeVar200.y * cos( nodeVar271 ) ) ) );
	nodeVar273 = ( nodeVar272 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( knobs.activePoints >= 1.0 ) ) {

		nodeVar274 = 1.0;

	} else {

		nodeVar274 = 0.0;

	}

	nodeVar275 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar273, nodeVar273 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point1Weight ) * ( 1.0 + ( ( sin( ( nodeVar199 + ( 1.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar274 );
	nodeVar269 = ( nodeVar269 + ( vec3<f32>( f32(1.0), f32(0.19461783043107173), f32(0.09989872823822872) ) * vec3<f32>( nodeVar275 ) ) );
	nodeVar270 = ( nodeVar270 + nodeVar275 );
	nodeVar276 = ( nodeVar272 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( knobs.activePoints >= 2.0 ) ) {

		nodeVar277 = 1.0;

	} else {

		nodeVar277 = 0.0;

	}

	nodeVar278 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar276, nodeVar276 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point2Weight ) * ( 1.0 + ( ( sin( ( nodeVar199 + ( 2.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar277 );
	nodeVar269 = ( nodeVar269 + ( vec3<f32>( f32(1.0), f32(0.6938717612856897), f32(0.4793201830913402) ) * vec3<f32>( nodeVar278 ) ) );
	nodeVar270 = ( nodeVar270 + nodeVar278 );
	nodeVar279 = ( nodeVar272 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( knobs.activePoints >= 3.0 ) ) {

		nodeVar280 = 1.0;

	} else {

		nodeVar280 = 0.0;

	}

	nodeVar281 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar279, nodeVar279 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point3Weight ) * ( 1.0 + ( ( sin( ( nodeVar199 + ( 3.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar280 );
	nodeVar269 = ( nodeVar269 + ( vec3<f32>( f32(1.0), f32(0.450785782828426), f32(0.5711248294565854) ) * vec3<f32>( nodeVar281 ) ) );
	nodeVar270 = ( nodeVar270 + nodeVar281 );
	nodeVar282 = ( nodeVar272 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( knobs.activePoints >= 4.0 ) ) {

		nodeVar283 = 1.0;

	} else {

		nodeVar283 = 0.0;

	}

	nodeVar284 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar282, nodeVar282 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point4Weight ) * ( 1.0 + ( ( sin( ( nodeVar199 + ( 4.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar283 );
	nodeVar269 = ( nodeVar269 + ( vec3<f32>( f32(1.0), f32(0.5775804404214573), f32(0.09530746662221588) ) * vec3<f32>( nodeVar284 ) ) );
	nodeVar270 = ( nodeVar270 + nodeVar284 );
	nodeVar285 = ( nodeVar272 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( knobs.activePoints >= 5.0 ) ) {

		nodeVar286 = 1.0;

	} else {

		nodeVar286 = 0.0;

	}

	nodeVar287 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( nodeVar285, nodeVar285 ) + ( (0.21999999999999997 * knobs.softness + 0.08000000000000002) * (0.21999999999999997 * knobs.softness + 0.08000000000000002) ) ), 0.0001 ) ), (-3.4000000000000004 * knobs.softness + 4.6) ), 0.0001 ) ) * knobs.point5Weight ) * ( 1.0 + ( ( sin( ( nodeVar199 + ( 5.0 * 1.25 ) ) ) * knobs.motionAmount ) * 0.6 ) ) ) * nodeVar286 );
	nodeVar269 = ( nodeVar269 + ( vec3<f32>( f32(1.0), f32(0.8796223968851662), f32(0.7681511472425809) ) * vec3<f32>( nodeVar287 ) ) );
	nodeVar270 = ( nodeVar270 + nodeVar287 );
	nodeVar269 = ( nodeVar269 / vec3<f32>( max( nodeVar270, 0.0001 ) ) );
	nodeVar288 = ( smoothstep( knobs.glowThreshold, 1.0, dot( nodeVar269, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * knobs.glowStrength );
	nodeVar269 = ( nodeVar269 + vec3<f32>( nodeVar288, nodeVar288, nodeVar288 ) );
	nodeVar289 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * knobs.grainAmount );
	nodeVar269 = ( nodeVar269 + vec3<f32>( nodeVar289, nodeVar289, nodeVar289 ) );
	nodeVar290 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
	nodeVar269 = ( nodeVar269 * vec3<f32>( mix( 1.0, smoothstep( knobs.vignetteRadius, ( knobs.vignetteRadius - knobs.vignetteSoftness ), sqrt( max( dot( nodeVar290, nodeVar290 ), 0.0001 ) ) ), knobs.vignetteStrength ) ) );
	nodeVar291 = vec4<f32>( clamp( nodeVar269, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	nodeVar292 = vec3<f32>( nodeVar291.x, nodeVar291.y, nodeVar291.z );
	nodeVar293 = ( ( ( nodeVar292.x * 0.2126 ) + ( nodeVar292.y * 0.7152 ) ) + ( nodeVar292.z * 0.0722 ) );
	nodeVar294 = mix( vec3<f32>( nodeVar293, nodeVar293, nodeVar293 ), nodeVar292, f32(1.0) );
	nodeVar295 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar294.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar294.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar294.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar294.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar294.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar294.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar294.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar294.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar294.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar291.w, 0.0, 1.0 ) ).w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( nodeVar0, ( nodeVar295 + ( clamp( nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - nodeVar295 ) ) ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar296 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar296;

	// result

	output.color = nodeVar296;

	output.color = to_shelf(output.color);
	return output;

}

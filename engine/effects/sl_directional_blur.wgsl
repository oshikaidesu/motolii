// Directional Blur: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Smears the image in one direction or out from a center, for motion and speed.
// --check@mode:Mode,0
// --track@strength:Strength,0,96,18,0.5
// --track@samples:Samples,1,16,8,1
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
  mode: f32,
  angle: f32,
  strength: f32,
  resolution: vec2<f32>,
  samples: f32,
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
var<private> nodeVar3 : bool;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec2<f32>;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : vec2<f32>;
var<private> nodeVar11 : vec2<f32>;
var<private> nodeVar12 : vec2<f32>;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : vec2<f32>;
var<private> nodeVar17 : vec2<f32>;
var<private> nodeVar18 : vec2<f32>;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec2<f32>;
var<private> nodeVar22 : vec2<f32>;
var<private> nodeVar23 : vec2<f32>;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : vec4<f32>;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : vec2<f32>;
var<private> nodeVar30 : vec2<f32>;
var<private> nodeVar31 : vec2<f32>;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : vec2<f32>;
var<private> nodeVar35 : vec2<f32>;
var<private> nodeVar36 : vec2<f32>;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : f32;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : vec2<f32>;
var<private> nodeVar41 : vec2<f32>;
var<private> nodeVar42 : vec2<f32>;
var<private> nodeVar43 : f32;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : vec2<f32>;
var<private> nodeVar46 : vec2<f32>;
var<private> nodeVar47 : vec2<f32>;
var<private> nodeVar48 : f32;
var<private> nodeVar49 : vec4<f32>;
var<private> nodeVar50 : f32;
var<private> nodeVar51 : f32;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : vec2<f32>;
var<private> nodeVar54 : vec2<f32>;
var<private> nodeVar55 : vec2<f32>;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : f32;
var<private> nodeVar58 : vec2<f32>;
var<private> nodeVar59 : vec2<f32>;
var<private> nodeVar60 : vec2<f32>;
var<private> nodeVar61 : f32;
var<private> nodeVar62 : f32;
var<private> nodeVar63 : f32;
var<private> nodeVar64 : vec2<f32>;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : vec2<f32>;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : f32;
var<private> nodeVar69 : vec2<f32>;
var<private> nodeVar70 : vec2<f32>;
var<private> nodeVar71 : vec2<f32>;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : vec4<f32>;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : vec2<f32>;
var<private> nodeVar78 : vec2<f32>;
var<private> nodeVar79 : vec2<f32>;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : f32;
var<private> nodeVar82 : vec2<f32>;
var<private> nodeVar83 : vec2<f32>;
var<private> nodeVar84 : vec2<f32>;
var<private> nodeVar85 : f32;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : vec2<f32>;
var<private> nodeVar89 : vec2<f32>;
var<private> nodeVar90 : vec2<f32>;
var<private> nodeVar91 : f32;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : vec2<f32>;
var<private> nodeVar94 : vec2<f32>;
var<private> nodeVar95 : vec2<f32>;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : vec4<f32>;
var<private> nodeVar98 : f32;
var<private> nodeVar99 : f32;
var<private> nodeVar100 : f32;
var<private> nodeVar101 : vec2<f32>;
var<private> nodeVar102 : vec2<f32>;
var<private> nodeVar103 : vec2<f32>;
var<private> nodeVar104 : f32;
var<private> nodeVar105 : f32;
var<private> nodeVar106 : vec2<f32>;
var<private> nodeVar107 : vec2<f32>;
var<private> nodeVar108 : vec2<f32>;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : f32;
var<private> nodeVar111 : f32;
var<private> nodeVar112 : vec2<f32>;
var<private> nodeVar113 : vec2<f32>;
var<private> nodeVar114 : vec2<f32>;
var<private> nodeVar115 : f32;
var<private> nodeVar116 : f32;
var<private> nodeVar117 : vec2<f32>;
var<private> nodeVar118 : vec2<f32>;
var<private> nodeVar119 : vec2<f32>;
var<private> nodeVar120 : f32;
var<private> nodeVar121 : vec4<f32>;
var<private> nodeVar122 : f32;
var<private> nodeVar123 : f32;
var<private> nodeVar124 : f32;
var<private> nodeVar125 : vec2<f32>;
var<private> nodeVar126 : vec2<f32>;
var<private> nodeVar127 : vec2<f32>;
var<private> nodeVar128 : f32;
var<private> nodeVar129 : f32;
var<private> nodeVar130 : vec2<f32>;
var<private> nodeVar131 : vec2<f32>;
var<private> nodeVar132 : vec2<f32>;
var<private> nodeVar133 : f32;
var<private> nodeVar134 : f32;
var<private> nodeVar135 : f32;
var<private> nodeVar136 : vec2<f32>;
var<private> nodeVar137 : vec2<f32>;
var<private> nodeVar138 : vec2<f32>;
var<private> nodeVar139 : f32;
var<private> nodeVar140 : f32;
var<private> nodeVar141 : vec2<f32>;
var<private> nodeVar142 : vec2<f32>;
var<private> nodeVar143 : vec2<f32>;
var<private> nodeVar144 : f32;
var<private> nodeVar145 : vec4<f32>;
var<private> nodeVar146 : f32;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : f32;
var<private> nodeVar149 : vec2<f32>;
var<private> nodeVar150 : vec2<f32>;
var<private> nodeVar151 : vec2<f32>;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : f32;
var<private> nodeVar154 : vec2<f32>;
var<private> nodeVar155 : vec2<f32>;
var<private> nodeVar156 : vec2<f32>;
var<private> nodeVar157 : f32;
var<private> nodeVar158 : f32;
var<private> nodeVar159 : f32;
var<private> nodeVar160 : vec2<f32>;
var<private> nodeVar161 : vec2<f32>;
var<private> nodeVar162 : vec2<f32>;
var<private> nodeVar163 : f32;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : vec2<f32>;
var<private> nodeVar166 : vec2<f32>;
var<private> nodeVar167 : vec2<f32>;
var<private> nodeVar168 : f32;
var<private> nodeVar169 : vec4<f32>;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : f32;
var<private> nodeVar173 : vec2<f32>;
var<private> nodeVar174 : vec2<f32>;
var<private> nodeVar175 : vec2<f32>;
var<private> nodeVar176 : f32;
var<private> nodeVar177 : f32;
var<private> nodeVar178 : vec2<f32>;
var<private> nodeVar179 : vec2<f32>;
var<private> nodeVar180 : vec2<f32>;
var<private> nodeVar181 : f32;
var<private> nodeVar182 : f32;
var<private> nodeVar183 : f32;
var<private> nodeVar184 : vec2<f32>;
var<private> nodeVar185 : vec2<f32>;
var<private> nodeVar186 : vec2<f32>;
var<private> nodeVar187 : f32;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : vec2<f32>;
var<private> nodeVar190 : vec2<f32>;
var<private> nodeVar191 : vec2<f32>;
var<private> nodeVar192 : f32;
var<private> nodeVar193 : vec4<f32>;
var<private> nodeVar194 : f32;
var<private> nodeVar195 : f32;
var<private> nodeVar196 : f32;
var<private> nodeVar197 : vec2<f32>;
var<private> nodeVar198 : vec2<f32>;
var<private> nodeVar199 : vec2<f32>;
var<private> nodeVar200 : f32;
var<private> nodeVar201 : f32;
var<private> nodeVar202 : vec2<f32>;
var<private> nodeVar203 : vec2<f32>;
var<private> nodeVar204 : vec2<f32>;
var<private> nodeVar205 : f32;
var<private> nodeVar206 : f32;
var<private> nodeVar207 : f32;
var<private> nodeVar208 : vec2<f32>;
var<private> nodeVar209 : vec2<f32>;
var<private> nodeVar210 : vec2<f32>;
var<private> nodeVar211 : f32;
var<private> nodeVar212 : f32;
var<private> nodeVar213 : vec2<f32>;
var<private> nodeVar214 : vec2<f32>;
var<private> nodeVar215 : vec2<f32>;
var<private> nodeVar216 : f32;
var<private> nodeVar217 : vec4<f32>;
var<private> nodeVar218 : f32;
var<private> nodeVar219 : f32;
var<private> nodeVar220 : f32;
var<private> nodeVar221 : vec2<f32>;
var<private> nodeVar222 : vec2<f32>;
var<private> nodeVar223 : vec2<f32>;
var<private> nodeVar224 : f32;
var<private> nodeVar225 : f32;
var<private> nodeVar226 : vec2<f32>;
var<private> nodeVar227 : vec2<f32>;
var<private> nodeVar228 : vec2<f32>;
var<private> nodeVar229 : f32;
var<private> nodeVar230 : f32;
var<private> nodeVar231 : f32;
var<private> nodeVar232 : vec2<f32>;
var<private> nodeVar233 : vec2<f32>;
var<private> nodeVar234 : vec2<f32>;
var<private> nodeVar235 : f32;
var<private> nodeVar236 : f32;
var<private> nodeVar237 : vec2<f32>;
var<private> nodeVar238 : vec2<f32>;
var<private> nodeVar239 : vec2<f32>;
var<private> nodeVar240 : f32;
var<private> nodeVar241 : vec4<f32>;
var<private> nodeVar242 : f32;
var<private> nodeVar243 : f32;
var<private> nodeVar244 : f32;
var<private> nodeVar245 : vec2<f32>;
var<private> nodeVar246 : vec2<f32>;
var<private> nodeVar247 : vec2<f32>;
var<private> nodeVar248 : f32;
var<private> nodeVar249 : f32;
var<private> nodeVar250 : vec2<f32>;
var<private> nodeVar251 : vec2<f32>;
var<private> nodeVar252 : vec2<f32>;
var<private> nodeVar253 : f32;
var<private> nodeVar254 : f32;
var<private> nodeVar255 : f32;
var<private> nodeVar256 : vec2<f32>;
var<private> nodeVar257 : vec2<f32>;
var<private> nodeVar258 : vec2<f32>;
var<private> nodeVar259 : f32;
var<private> nodeVar260 : f32;
var<private> nodeVar261 : vec2<f32>;
var<private> nodeVar262 : vec2<f32>;
var<private> nodeVar263 : vec2<f32>;
var<private> nodeVar264 : f32;
var<private> nodeVar265 : vec4<f32>;
var<private> nodeVar266 : f32;
var<private> nodeVar267 : f32;
var<private> nodeVar268 : f32;
var<private> nodeVar269 : vec2<f32>;
var<private> nodeVar270 : vec2<f32>;
var<private> nodeVar271 : vec2<f32>;
var<private> nodeVar272 : f32;
var<private> nodeVar273 : f32;
var<private> nodeVar274 : vec2<f32>;
var<private> nodeVar275 : vec2<f32>;
var<private> nodeVar276 : vec2<f32>;
var<private> nodeVar277 : f32;
var<private> nodeVar278 : f32;
var<private> nodeVar279 : f32;
var<private> nodeVar280 : vec2<f32>;
var<private> nodeVar281 : vec2<f32>;
var<private> nodeVar282 : vec2<f32>;
var<private> nodeVar283 : f32;
var<private> nodeVar284 : f32;
var<private> nodeVar285 : vec2<f32>;
var<private> nodeVar286 : vec2<f32>;
var<private> nodeVar287 : vec2<f32>;
var<private> nodeVar288 : f32;
var<private> nodeVar289 : vec4<f32>;
var<private> nodeVar290 : f32;
var<private> nodeVar291 : f32;
var<private> nodeVar292 : f32;
var<private> nodeVar293 : vec2<f32>;
var<private> nodeVar294 : vec2<f32>;
var<private> nodeVar295 : vec2<f32>;
var<private> nodeVar296 : f32;
var<private> nodeVar297 : f32;
var<private> nodeVar298 : vec2<f32>;
var<private> nodeVar299 : vec2<f32>;
var<private> nodeVar300 : vec2<f32>;
var<private> nodeVar301 : f32;
var<private> nodeVar302 : f32;
var<private> nodeVar303 : f32;
var<private> nodeVar304 : vec2<f32>;
var<private> nodeVar305 : vec2<f32>;
var<private> nodeVar306 : vec2<f32>;
var<private> nodeVar307 : f32;
var<private> nodeVar308 : f32;
var<private> nodeVar309 : vec2<f32>;
var<private> nodeVar310 : vec2<f32>;
var<private> nodeVar311 : vec2<f32>;
var<private> nodeVar312 : f32;
var<private> nodeVar313 : vec4<f32>;
var<private> nodeVar314 : f32;
var<private> nodeVar315 : f32;
var<private> nodeVar316 : f32;
var<private> nodeVar317 : vec2<f32>;
var<private> nodeVar318 : vec2<f32>;
var<private> nodeVar319 : vec2<f32>;
var<private> nodeVar320 : f32;
var<private> nodeVar321 : f32;
var<private> nodeVar322 : vec2<f32>;
var<private> nodeVar323 : vec2<f32>;
var<private> nodeVar324 : vec2<f32>;
var<private> nodeVar325 : f32;
var<private> nodeVar326 : f32;
var<private> nodeVar327 : f32;
var<private> nodeVar328 : vec2<f32>;
var<private> nodeVar329 : vec2<f32>;
var<private> nodeVar330 : vec2<f32>;
var<private> nodeVar331 : f32;
var<private> nodeVar332 : f32;
var<private> nodeVar333 : vec2<f32>;
var<private> nodeVar334 : vec2<f32>;
var<private> nodeVar335 : vec2<f32>;
var<private> nodeVar336 : f32;
var<private> nodeVar337 : vec4<f32>;
var<private> nodeVar338 : f32;
var<private> nodeVar339 : f32;
var<private> nodeVar340 : f32;
var<private> nodeVar341 : vec2<f32>;
var<private> nodeVar342 : vec2<f32>;
var<private> nodeVar343 : vec2<f32>;
var<private> nodeVar344 : f32;
var<private> nodeVar345 : f32;
var<private> nodeVar346 : vec2<f32>;
var<private> nodeVar347 : vec2<f32>;
var<private> nodeVar348 : vec2<f32>;
var<private> nodeVar349 : f32;
var<private> nodeVar350 : f32;
var<private> nodeVar351 : f32;
var<private> nodeVar352 : vec2<f32>;
var<private> nodeVar353 : vec2<f32>;
var<private> nodeVar354 : vec2<f32>;
var<private> nodeVar355 : f32;
var<private> nodeVar356 : f32;
var<private> nodeVar357 : vec2<f32>;
var<private> nodeVar358 : vec2<f32>;
var<private> nodeVar359 : vec2<f32>;
var<private> nodeVar360 : f32;
var<private> nodeVar361 : vec4<f32>;
var<private> nodeVar362 : f32;
var<private> nodeVar363 : f32;
var<private> nodeVar364 : f32;
var<private> nodeVar365 : vec2<f32>;
var<private> nodeVar366 : vec2<f32>;
var<private> nodeVar367 : vec2<f32>;
var<private> nodeVar368 : f32;
var<private> nodeVar369 : f32;
var<private> nodeVar370 : vec2<f32>;
var<private> nodeVar371 : vec2<f32>;
var<private> nodeVar372 : vec2<f32>;
var<private> nodeVar373 : f32;
var<private> nodeVar374 : f32;
var<private> nodeVar375 : f32;
var<private> nodeVar376 : vec2<f32>;
var<private> nodeVar377 : vec2<f32>;
var<private> nodeVar378 : vec2<f32>;
var<private> nodeVar379 : f32;
var<private> nodeVar380 : f32;
var<private> nodeVar381 : vec2<f32>;
var<private> nodeVar382 : vec2<f32>;
var<private> nodeVar383 : vec2<f32>;
var<private> nodeVar384 : f32;
var<private> nodeVar385 : vec4<f32>;
var<private> nodeVar386 : f32;
var<private> nodeVar387 : f32;
var<private> nodeVar388 : vec4<f32>;
var<private> nodeVar389 : vec3<f32>;
var<private> nodeVar390 : f32;
var<private> nodeVar391 : vec3<f32>;
var<private> nodeVar392 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar393 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar3 = ( (1 * knobs.mode + 0) > 0.5 );

	if ( nodeVar3 ) {

		nodeVar4 = ( knobs.angle * 0.017453292519943295 );
		nodeVar5 = vec2<f32>( cos( nodeVar4 ), sin( nodeVar4 ) );
		nodeVar6 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar7 = vec2<f32>( ( nodeVar1.x - nodeVar6.x ), ( nodeVar1.y - nodeVar6.y ) );
		nodeVar8 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar2 = vec2<f32>( ( vec2<f32>( ( nodeVar5.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar5.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.5 ), ( vec2<f32>( ( nodeVar7.x * ( knobs.strength / nodeVar8 ) ), ( nodeVar7.y * ( knobs.strength / nodeVar8 ) ) ).x * -0.5 ) ).y;

	} else {

		nodeVar9 = ( knobs.angle * 0.017453292519943295 );
		nodeVar10 = vec2<f32>( cos( nodeVar9 ), sin( nodeVar9 ) );
		nodeVar11 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar12 = vec2<f32>( ( nodeVar1.x - nodeVar11.x ), ( nodeVar1.y - nodeVar11.y ) );
		nodeVar13 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar2 = vec2<f32>( ( vec2<f32>( ( nodeVar10.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar10.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.5 ), ( vec2<f32>( ( nodeVar12.x * ( knobs.strength / nodeVar13 ) ), ( nodeVar12.y * ( knobs.strength / nodeVar13 ) ) ).x * -0.5 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar15 = ( knobs.angle * 0.017453292519943295 );
		nodeVar16 = vec2<f32>( cos( nodeVar15 ), sin( nodeVar15 ) );
		nodeVar17 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar18 = vec2<f32>( ( nodeVar1.x - nodeVar17.x ), ( nodeVar1.y - nodeVar17.y ) );
		nodeVar19 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar14 = vec2<f32>( ( vec2<f32>( ( nodeVar16.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar16.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.5 ), ( vec2<f32>( ( nodeVar18.x * ( knobs.strength / nodeVar19 ) ), ( nodeVar18.y * ( knobs.strength / nodeVar19 ) ) ).y * -0.5 ) ).y;

	} else {

		nodeVar20 = ( knobs.angle * 0.017453292519943295 );
		nodeVar21 = vec2<f32>( cos( nodeVar20 ), sin( nodeVar20 ) );
		nodeVar22 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar23 = vec2<f32>( ( nodeVar1.x - nodeVar22.x ), ( nodeVar1.y - nodeVar22.y ) );
		nodeVar24 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar14 = vec2<f32>( ( vec2<f32>( ( nodeVar21.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar21.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.5 ), ( vec2<f32>( ( nodeVar23.x * ( knobs.strength / nodeVar24 ) ), ( nodeVar23.y * ( knobs.strength / nodeVar24 ) ) ).y * -0.5 ) ).x;

	}

	nodeVar25 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar2 ), ( nodeVar1.y + nodeVar14 ) ) );
	nodeVar26 = step( 0.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar28 = ( knobs.angle * 0.017453292519943295 );
		nodeVar29 = vec2<f32>( cos( nodeVar28 ), sin( nodeVar28 ) );
		nodeVar30 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar31 = vec2<f32>( ( nodeVar1.x - nodeVar30.x ), ( nodeVar1.y - nodeVar30.y ) );
		nodeVar32 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar27 = vec2<f32>( ( vec2<f32>( ( nodeVar29.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar29.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.43333333333333335 ), ( vec2<f32>( ( nodeVar31.x * ( knobs.strength / nodeVar32 ) ), ( nodeVar31.y * ( knobs.strength / nodeVar32 ) ) ).x * -0.43333333333333335 ) ).y;

	} else {

		nodeVar33 = ( knobs.angle * 0.017453292519943295 );
		nodeVar34 = vec2<f32>( cos( nodeVar33 ), sin( nodeVar33 ) );
		nodeVar35 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar36 = vec2<f32>( ( nodeVar1.x - nodeVar35.x ), ( nodeVar1.y - nodeVar35.y ) );
		nodeVar37 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar27 = vec2<f32>( ( vec2<f32>( ( nodeVar34.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar34.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.43333333333333335 ), ( vec2<f32>( ( nodeVar36.x * ( knobs.strength / nodeVar37 ) ), ( nodeVar36.y * ( knobs.strength / nodeVar37 ) ) ).x * -0.43333333333333335 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar39 = ( knobs.angle * 0.017453292519943295 );
		nodeVar40 = vec2<f32>( cos( nodeVar39 ), sin( nodeVar39 ) );
		nodeVar41 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar42 = vec2<f32>( ( nodeVar1.x - nodeVar41.x ), ( nodeVar1.y - nodeVar41.y ) );
		nodeVar43 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar38 = vec2<f32>( ( vec2<f32>( ( nodeVar40.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar40.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.43333333333333335 ), ( vec2<f32>( ( nodeVar42.x * ( knobs.strength / nodeVar43 ) ), ( nodeVar42.y * ( knobs.strength / nodeVar43 ) ) ).y * -0.43333333333333335 ) ).y;

	} else {

		nodeVar44 = ( knobs.angle * 0.017453292519943295 );
		nodeVar45 = vec2<f32>( cos( nodeVar44 ), sin( nodeVar44 ) );
		nodeVar46 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar47 = vec2<f32>( ( nodeVar1.x - nodeVar46.x ), ( nodeVar1.y - nodeVar46.y ) );
		nodeVar48 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar38 = vec2<f32>( ( vec2<f32>( ( nodeVar45.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar45.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.43333333333333335 ), ( vec2<f32>( ( nodeVar47.x * ( knobs.strength / nodeVar48 ) ), ( nodeVar47.y * ( knobs.strength / nodeVar48 ) ) ).y * -0.43333333333333335 ) ).x;

	}

	nodeVar49 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar27 ), ( nodeVar1.y + nodeVar38 ) ) );
	nodeVar50 = step( 1.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar52 = ( knobs.angle * 0.017453292519943295 );
		nodeVar53 = vec2<f32>( cos( nodeVar52 ), sin( nodeVar52 ) );
		nodeVar54 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar55 = vec2<f32>( ( nodeVar1.x - nodeVar54.x ), ( nodeVar1.y - nodeVar54.y ) );
		nodeVar56 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar51 = vec2<f32>( ( vec2<f32>( ( nodeVar53.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar53.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.3666666666666667 ), ( vec2<f32>( ( nodeVar55.x * ( knobs.strength / nodeVar56 ) ), ( nodeVar55.y * ( knobs.strength / nodeVar56 ) ) ).x * -0.3666666666666667 ) ).y;

	} else {

		nodeVar57 = ( knobs.angle * 0.017453292519943295 );
		nodeVar58 = vec2<f32>( cos( nodeVar57 ), sin( nodeVar57 ) );
		nodeVar59 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar60 = vec2<f32>( ( nodeVar1.x - nodeVar59.x ), ( nodeVar1.y - nodeVar59.y ) );
		nodeVar61 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar51 = vec2<f32>( ( vec2<f32>( ( nodeVar58.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar58.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.3666666666666667 ), ( vec2<f32>( ( nodeVar60.x * ( knobs.strength / nodeVar61 ) ), ( nodeVar60.y * ( knobs.strength / nodeVar61 ) ) ).x * -0.3666666666666667 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar63 = ( knobs.angle * 0.017453292519943295 );
		nodeVar64 = vec2<f32>( cos( nodeVar63 ), sin( nodeVar63 ) );
		nodeVar65 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar66 = vec2<f32>( ( nodeVar1.x - nodeVar65.x ), ( nodeVar1.y - nodeVar65.y ) );
		nodeVar67 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar62 = vec2<f32>( ( vec2<f32>( ( nodeVar64.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar64.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.3666666666666667 ), ( vec2<f32>( ( nodeVar66.x * ( knobs.strength / nodeVar67 ) ), ( nodeVar66.y * ( knobs.strength / nodeVar67 ) ) ).y * -0.3666666666666667 ) ).y;

	} else {

		nodeVar68 = ( knobs.angle * 0.017453292519943295 );
		nodeVar69 = vec2<f32>( cos( nodeVar68 ), sin( nodeVar68 ) );
		nodeVar70 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar71 = vec2<f32>( ( nodeVar1.x - nodeVar70.x ), ( nodeVar1.y - nodeVar70.y ) );
		nodeVar72 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar62 = vec2<f32>( ( vec2<f32>( ( nodeVar69.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar69.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.3666666666666667 ), ( vec2<f32>( ( nodeVar71.x * ( knobs.strength / nodeVar72 ) ), ( nodeVar71.y * ( knobs.strength / nodeVar72 ) ) ).y * -0.3666666666666667 ) ).x;

	}

	nodeVar73 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar51 ), ( nodeVar1.y + nodeVar62 ) ) );
	nodeVar74 = step( 2.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar76 = ( knobs.angle * 0.017453292519943295 );
		nodeVar77 = vec2<f32>( cos( nodeVar76 ), sin( nodeVar76 ) );
		nodeVar78 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar79 = vec2<f32>( ( nodeVar1.x - nodeVar78.x ), ( nodeVar1.y - nodeVar78.y ) );
		nodeVar80 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar75 = vec2<f32>( ( vec2<f32>( ( nodeVar77.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar77.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.3 ), ( vec2<f32>( ( nodeVar79.x * ( knobs.strength / nodeVar80 ) ), ( nodeVar79.y * ( knobs.strength / nodeVar80 ) ) ).x * -0.3 ) ).y;

	} else {

		nodeVar81 = ( knobs.angle * 0.017453292519943295 );
		nodeVar82 = vec2<f32>( cos( nodeVar81 ), sin( nodeVar81 ) );
		nodeVar83 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar84 = vec2<f32>( ( nodeVar1.x - nodeVar83.x ), ( nodeVar1.y - nodeVar83.y ) );
		nodeVar85 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar75 = vec2<f32>( ( vec2<f32>( ( nodeVar82.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar82.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.3 ), ( vec2<f32>( ( nodeVar84.x * ( knobs.strength / nodeVar85 ) ), ( nodeVar84.y * ( knobs.strength / nodeVar85 ) ) ).x * -0.3 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar87 = ( knobs.angle * 0.017453292519943295 );
		nodeVar88 = vec2<f32>( cos( nodeVar87 ), sin( nodeVar87 ) );
		nodeVar89 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar90 = vec2<f32>( ( nodeVar1.x - nodeVar89.x ), ( nodeVar1.y - nodeVar89.y ) );
		nodeVar91 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar86 = vec2<f32>( ( vec2<f32>( ( nodeVar88.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar88.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.3 ), ( vec2<f32>( ( nodeVar90.x * ( knobs.strength / nodeVar91 ) ), ( nodeVar90.y * ( knobs.strength / nodeVar91 ) ) ).y * -0.3 ) ).y;

	} else {

		nodeVar92 = ( knobs.angle * 0.017453292519943295 );
		nodeVar93 = vec2<f32>( cos( nodeVar92 ), sin( nodeVar92 ) );
		nodeVar94 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar95 = vec2<f32>( ( nodeVar1.x - nodeVar94.x ), ( nodeVar1.y - nodeVar94.y ) );
		nodeVar96 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar86 = vec2<f32>( ( vec2<f32>( ( nodeVar93.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar93.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.3 ), ( vec2<f32>( ( nodeVar95.x * ( knobs.strength / nodeVar96 ) ), ( nodeVar95.y * ( knobs.strength / nodeVar96 ) ) ).y * -0.3 ) ).x;

	}

	nodeVar97 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar75 ), ( nodeVar1.y + nodeVar86 ) ) );
	nodeVar98 = step( 3.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar100 = ( knobs.angle * 0.017453292519943295 );
		nodeVar101 = vec2<f32>( cos( nodeVar100 ), sin( nodeVar100 ) );
		nodeVar102 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar103 = vec2<f32>( ( nodeVar1.x - nodeVar102.x ), ( nodeVar1.y - nodeVar102.y ) );
		nodeVar104 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar99 = vec2<f32>( ( vec2<f32>( ( nodeVar101.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar101.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.23333333333333334 ), ( vec2<f32>( ( nodeVar103.x * ( knobs.strength / nodeVar104 ) ), ( nodeVar103.y * ( knobs.strength / nodeVar104 ) ) ).x * -0.23333333333333334 ) ).y;

	} else {

		nodeVar105 = ( knobs.angle * 0.017453292519943295 );
		nodeVar106 = vec2<f32>( cos( nodeVar105 ), sin( nodeVar105 ) );
		nodeVar107 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar108 = vec2<f32>( ( nodeVar1.x - nodeVar107.x ), ( nodeVar1.y - nodeVar107.y ) );
		nodeVar109 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar99 = vec2<f32>( ( vec2<f32>( ( nodeVar106.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar106.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.23333333333333334 ), ( vec2<f32>( ( nodeVar108.x * ( knobs.strength / nodeVar109 ) ), ( nodeVar108.y * ( knobs.strength / nodeVar109 ) ) ).x * -0.23333333333333334 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar111 = ( knobs.angle * 0.017453292519943295 );
		nodeVar112 = vec2<f32>( cos( nodeVar111 ), sin( nodeVar111 ) );
		nodeVar113 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar114 = vec2<f32>( ( nodeVar1.x - nodeVar113.x ), ( nodeVar1.y - nodeVar113.y ) );
		nodeVar115 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar110 = vec2<f32>( ( vec2<f32>( ( nodeVar112.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar112.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.23333333333333334 ), ( vec2<f32>( ( nodeVar114.x * ( knobs.strength / nodeVar115 ) ), ( nodeVar114.y * ( knobs.strength / nodeVar115 ) ) ).y * -0.23333333333333334 ) ).y;

	} else {

		nodeVar116 = ( knobs.angle * 0.017453292519943295 );
		nodeVar117 = vec2<f32>( cos( nodeVar116 ), sin( nodeVar116 ) );
		nodeVar118 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar119 = vec2<f32>( ( nodeVar1.x - nodeVar118.x ), ( nodeVar1.y - nodeVar118.y ) );
		nodeVar120 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar110 = vec2<f32>( ( vec2<f32>( ( nodeVar117.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar117.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.23333333333333334 ), ( vec2<f32>( ( nodeVar119.x * ( knobs.strength / nodeVar120 ) ), ( nodeVar119.y * ( knobs.strength / nodeVar120 ) ) ).y * -0.23333333333333334 ) ).x;

	}

	nodeVar121 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar99 ), ( nodeVar1.y + nodeVar110 ) ) );
	nodeVar122 = step( 4.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar124 = ( knobs.angle * 0.017453292519943295 );
		nodeVar125 = vec2<f32>( cos( nodeVar124 ), sin( nodeVar124 ) );
		nodeVar126 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar127 = vec2<f32>( ( nodeVar1.x - nodeVar126.x ), ( nodeVar1.y - nodeVar126.y ) );
		nodeVar128 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar123 = vec2<f32>( ( vec2<f32>( ( nodeVar125.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar125.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.16666666666666669 ), ( vec2<f32>( ( nodeVar127.x * ( knobs.strength / nodeVar128 ) ), ( nodeVar127.y * ( knobs.strength / nodeVar128 ) ) ).x * -0.16666666666666669 ) ).y;

	} else {

		nodeVar129 = ( knobs.angle * 0.017453292519943295 );
		nodeVar130 = vec2<f32>( cos( nodeVar129 ), sin( nodeVar129 ) );
		nodeVar131 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar132 = vec2<f32>( ( nodeVar1.x - nodeVar131.x ), ( nodeVar1.y - nodeVar131.y ) );
		nodeVar133 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar123 = vec2<f32>( ( vec2<f32>( ( nodeVar130.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar130.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.16666666666666669 ), ( vec2<f32>( ( nodeVar132.x * ( knobs.strength / nodeVar133 ) ), ( nodeVar132.y * ( knobs.strength / nodeVar133 ) ) ).x * -0.16666666666666669 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar135 = ( knobs.angle * 0.017453292519943295 );
		nodeVar136 = vec2<f32>( cos( nodeVar135 ), sin( nodeVar135 ) );
		nodeVar137 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar138 = vec2<f32>( ( nodeVar1.x - nodeVar137.x ), ( nodeVar1.y - nodeVar137.y ) );
		nodeVar139 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar134 = vec2<f32>( ( vec2<f32>( ( nodeVar136.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar136.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.16666666666666669 ), ( vec2<f32>( ( nodeVar138.x * ( knobs.strength / nodeVar139 ) ), ( nodeVar138.y * ( knobs.strength / nodeVar139 ) ) ).y * -0.16666666666666669 ) ).y;

	} else {

		nodeVar140 = ( knobs.angle * 0.017453292519943295 );
		nodeVar141 = vec2<f32>( cos( nodeVar140 ), sin( nodeVar140 ) );
		nodeVar142 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar143 = vec2<f32>( ( nodeVar1.x - nodeVar142.x ), ( nodeVar1.y - nodeVar142.y ) );
		nodeVar144 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar134 = vec2<f32>( ( vec2<f32>( ( nodeVar141.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar141.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.16666666666666669 ), ( vec2<f32>( ( nodeVar143.x * ( knobs.strength / nodeVar144 ) ), ( nodeVar143.y * ( knobs.strength / nodeVar144 ) ) ).y * -0.16666666666666669 ) ).x;

	}

	nodeVar145 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar123 ), ( nodeVar1.y + nodeVar134 ) ) );
	nodeVar146 = step( 5.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar148 = ( knobs.angle * 0.017453292519943295 );
		nodeVar149 = vec2<f32>( cos( nodeVar148 ), sin( nodeVar148 ) );
		nodeVar150 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar151 = vec2<f32>( ( nodeVar1.x - nodeVar150.x ), ( nodeVar1.y - nodeVar150.y ) );
		nodeVar152 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar147 = vec2<f32>( ( vec2<f32>( ( nodeVar149.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar149.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.09999999999999998 ), ( vec2<f32>( ( nodeVar151.x * ( knobs.strength / nodeVar152 ) ), ( nodeVar151.y * ( knobs.strength / nodeVar152 ) ) ).x * -0.09999999999999998 ) ).y;

	} else {

		nodeVar153 = ( knobs.angle * 0.017453292519943295 );
		nodeVar154 = vec2<f32>( cos( nodeVar153 ), sin( nodeVar153 ) );
		nodeVar155 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar156 = vec2<f32>( ( nodeVar1.x - nodeVar155.x ), ( nodeVar1.y - nodeVar155.y ) );
		nodeVar157 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar147 = vec2<f32>( ( vec2<f32>( ( nodeVar154.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar154.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.09999999999999998 ), ( vec2<f32>( ( nodeVar156.x * ( knobs.strength / nodeVar157 ) ), ( nodeVar156.y * ( knobs.strength / nodeVar157 ) ) ).x * -0.09999999999999998 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar159 = ( knobs.angle * 0.017453292519943295 );
		nodeVar160 = vec2<f32>( cos( nodeVar159 ), sin( nodeVar159 ) );
		nodeVar161 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar162 = vec2<f32>( ( nodeVar1.x - nodeVar161.x ), ( nodeVar1.y - nodeVar161.y ) );
		nodeVar163 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar158 = vec2<f32>( ( vec2<f32>( ( nodeVar160.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar160.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.09999999999999998 ), ( vec2<f32>( ( nodeVar162.x * ( knobs.strength / nodeVar163 ) ), ( nodeVar162.y * ( knobs.strength / nodeVar163 ) ) ).y * -0.09999999999999998 ) ).y;

	} else {

		nodeVar164 = ( knobs.angle * 0.017453292519943295 );
		nodeVar165 = vec2<f32>( cos( nodeVar164 ), sin( nodeVar164 ) );
		nodeVar166 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar167 = vec2<f32>( ( nodeVar1.x - nodeVar166.x ), ( nodeVar1.y - nodeVar166.y ) );
		nodeVar168 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar158 = vec2<f32>( ( vec2<f32>( ( nodeVar165.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar165.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.09999999999999998 ), ( vec2<f32>( ( nodeVar167.x * ( knobs.strength / nodeVar168 ) ), ( nodeVar167.y * ( knobs.strength / nodeVar168 ) ) ).y * -0.09999999999999998 ) ).x;

	}

	nodeVar169 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar147 ), ( nodeVar1.y + nodeVar158 ) ) );
	nodeVar170 = step( 6.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar172 = ( knobs.angle * 0.017453292519943295 );
		nodeVar173 = vec2<f32>( cos( nodeVar172 ), sin( nodeVar172 ) );
		nodeVar174 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar175 = vec2<f32>( ( nodeVar1.x - nodeVar174.x ), ( nodeVar1.y - nodeVar174.y ) );
		nodeVar176 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar171 = vec2<f32>( ( vec2<f32>( ( nodeVar173.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar173.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.033333333333333326 ), ( vec2<f32>( ( nodeVar175.x * ( knobs.strength / nodeVar176 ) ), ( nodeVar175.y * ( knobs.strength / nodeVar176 ) ) ).x * -0.033333333333333326 ) ).y;

	} else {

		nodeVar177 = ( knobs.angle * 0.017453292519943295 );
		nodeVar178 = vec2<f32>( cos( nodeVar177 ), sin( nodeVar177 ) );
		nodeVar179 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar180 = vec2<f32>( ( nodeVar1.x - nodeVar179.x ), ( nodeVar1.y - nodeVar179.y ) );
		nodeVar181 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar171 = vec2<f32>( ( vec2<f32>( ( nodeVar178.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar178.y * ( knobs.strength / knobs.resolution.y ) ) ).x * -0.033333333333333326 ), ( vec2<f32>( ( nodeVar180.x * ( knobs.strength / nodeVar181 ) ), ( nodeVar180.y * ( knobs.strength / nodeVar181 ) ) ).x * -0.033333333333333326 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar183 = ( knobs.angle * 0.017453292519943295 );
		nodeVar184 = vec2<f32>( cos( nodeVar183 ), sin( nodeVar183 ) );
		nodeVar185 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar186 = vec2<f32>( ( nodeVar1.x - nodeVar185.x ), ( nodeVar1.y - nodeVar185.y ) );
		nodeVar187 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar182 = vec2<f32>( ( vec2<f32>( ( nodeVar184.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar184.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.033333333333333326 ), ( vec2<f32>( ( nodeVar186.x * ( knobs.strength / nodeVar187 ) ), ( nodeVar186.y * ( knobs.strength / nodeVar187 ) ) ).y * -0.033333333333333326 ) ).y;

	} else {

		nodeVar188 = ( knobs.angle * 0.017453292519943295 );
		nodeVar189 = vec2<f32>( cos( nodeVar188 ), sin( nodeVar188 ) );
		nodeVar190 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar191 = vec2<f32>( ( nodeVar1.x - nodeVar190.x ), ( nodeVar1.y - nodeVar190.y ) );
		nodeVar192 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar182 = vec2<f32>( ( vec2<f32>( ( nodeVar189.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar189.y * ( knobs.strength / knobs.resolution.y ) ) ).y * -0.033333333333333326 ), ( vec2<f32>( ( nodeVar191.x * ( knobs.strength / nodeVar192 ) ), ( nodeVar191.y * ( knobs.strength / nodeVar192 ) ) ).y * -0.033333333333333326 ) ).x;

	}

	nodeVar193 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar171 ), ( nodeVar1.y + nodeVar182 ) ) );
	nodeVar194 = step( 7.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar196 = ( knobs.angle * 0.017453292519943295 );
		nodeVar197 = vec2<f32>( cos( nodeVar196 ), sin( nodeVar196 ) );
		nodeVar198 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar199 = vec2<f32>( ( nodeVar1.x - nodeVar198.x ), ( nodeVar1.y - nodeVar198.y ) );
		nodeVar200 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar195 = vec2<f32>( ( vec2<f32>( ( nodeVar197.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar197.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.033333333333333326 ), ( vec2<f32>( ( nodeVar199.x * ( knobs.strength / nodeVar200 ) ), ( nodeVar199.y * ( knobs.strength / nodeVar200 ) ) ).x * 0.033333333333333326 ) ).y;

	} else {

		nodeVar201 = ( knobs.angle * 0.017453292519943295 );
		nodeVar202 = vec2<f32>( cos( nodeVar201 ), sin( nodeVar201 ) );
		nodeVar203 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar204 = vec2<f32>( ( nodeVar1.x - nodeVar203.x ), ( nodeVar1.y - nodeVar203.y ) );
		nodeVar205 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar195 = vec2<f32>( ( vec2<f32>( ( nodeVar202.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar202.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.033333333333333326 ), ( vec2<f32>( ( nodeVar204.x * ( knobs.strength / nodeVar205 ) ), ( nodeVar204.y * ( knobs.strength / nodeVar205 ) ) ).x * 0.033333333333333326 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar207 = ( knobs.angle * 0.017453292519943295 );
		nodeVar208 = vec2<f32>( cos( nodeVar207 ), sin( nodeVar207 ) );
		nodeVar209 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar210 = vec2<f32>( ( nodeVar1.x - nodeVar209.x ), ( nodeVar1.y - nodeVar209.y ) );
		nodeVar211 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar206 = vec2<f32>( ( vec2<f32>( ( nodeVar208.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar208.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.033333333333333326 ), ( vec2<f32>( ( nodeVar210.x * ( knobs.strength / nodeVar211 ) ), ( nodeVar210.y * ( knobs.strength / nodeVar211 ) ) ).y * 0.033333333333333326 ) ).y;

	} else {

		nodeVar212 = ( knobs.angle * 0.017453292519943295 );
		nodeVar213 = vec2<f32>( cos( nodeVar212 ), sin( nodeVar212 ) );
		nodeVar214 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar215 = vec2<f32>( ( nodeVar1.x - nodeVar214.x ), ( nodeVar1.y - nodeVar214.y ) );
		nodeVar216 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar206 = vec2<f32>( ( vec2<f32>( ( nodeVar213.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar213.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.033333333333333326 ), ( vec2<f32>( ( nodeVar215.x * ( knobs.strength / nodeVar216 ) ), ( nodeVar215.y * ( knobs.strength / nodeVar216 ) ) ).y * 0.033333333333333326 ) ).x;

	}

	nodeVar217 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar195 ), ( nodeVar1.y + nodeVar206 ) ) );
	nodeVar218 = step( 8.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar220 = ( knobs.angle * 0.017453292519943295 );
		nodeVar221 = vec2<f32>( cos( nodeVar220 ), sin( nodeVar220 ) );
		nodeVar222 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar223 = vec2<f32>( ( nodeVar1.x - nodeVar222.x ), ( nodeVar1.y - nodeVar222.y ) );
		nodeVar224 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar219 = vec2<f32>( ( vec2<f32>( ( nodeVar221.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar221.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.09999999999999998 ), ( vec2<f32>( ( nodeVar223.x * ( knobs.strength / nodeVar224 ) ), ( nodeVar223.y * ( knobs.strength / nodeVar224 ) ) ).x * 0.09999999999999998 ) ).y;

	} else {

		nodeVar225 = ( knobs.angle * 0.017453292519943295 );
		nodeVar226 = vec2<f32>( cos( nodeVar225 ), sin( nodeVar225 ) );
		nodeVar227 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar228 = vec2<f32>( ( nodeVar1.x - nodeVar227.x ), ( nodeVar1.y - nodeVar227.y ) );
		nodeVar229 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar219 = vec2<f32>( ( vec2<f32>( ( nodeVar226.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar226.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.09999999999999998 ), ( vec2<f32>( ( nodeVar228.x * ( knobs.strength / nodeVar229 ) ), ( nodeVar228.y * ( knobs.strength / nodeVar229 ) ) ).x * 0.09999999999999998 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar231 = ( knobs.angle * 0.017453292519943295 );
		nodeVar232 = vec2<f32>( cos( nodeVar231 ), sin( nodeVar231 ) );
		nodeVar233 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar234 = vec2<f32>( ( nodeVar1.x - nodeVar233.x ), ( nodeVar1.y - nodeVar233.y ) );
		nodeVar235 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar230 = vec2<f32>( ( vec2<f32>( ( nodeVar232.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar232.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.09999999999999998 ), ( vec2<f32>( ( nodeVar234.x * ( knobs.strength / nodeVar235 ) ), ( nodeVar234.y * ( knobs.strength / nodeVar235 ) ) ).y * 0.09999999999999998 ) ).y;

	} else {

		nodeVar236 = ( knobs.angle * 0.017453292519943295 );
		nodeVar237 = vec2<f32>( cos( nodeVar236 ), sin( nodeVar236 ) );
		nodeVar238 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar239 = vec2<f32>( ( nodeVar1.x - nodeVar238.x ), ( nodeVar1.y - nodeVar238.y ) );
		nodeVar240 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar230 = vec2<f32>( ( vec2<f32>( ( nodeVar237.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar237.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.09999999999999998 ), ( vec2<f32>( ( nodeVar239.x * ( knobs.strength / nodeVar240 ) ), ( nodeVar239.y * ( knobs.strength / nodeVar240 ) ) ).y * 0.09999999999999998 ) ).x;

	}

	nodeVar241 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar219 ), ( nodeVar1.y + nodeVar230 ) ) );
	nodeVar242 = step( 9.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar244 = ( knobs.angle * 0.017453292519943295 );
		nodeVar245 = vec2<f32>( cos( nodeVar244 ), sin( nodeVar244 ) );
		nodeVar246 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar247 = vec2<f32>( ( nodeVar1.x - nodeVar246.x ), ( nodeVar1.y - nodeVar246.y ) );
		nodeVar248 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar243 = vec2<f32>( ( vec2<f32>( ( nodeVar245.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar245.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.16666666666666663 ), ( vec2<f32>( ( nodeVar247.x * ( knobs.strength / nodeVar248 ) ), ( nodeVar247.y * ( knobs.strength / nodeVar248 ) ) ).x * 0.16666666666666663 ) ).y;

	} else {

		nodeVar249 = ( knobs.angle * 0.017453292519943295 );
		nodeVar250 = vec2<f32>( cos( nodeVar249 ), sin( nodeVar249 ) );
		nodeVar251 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar252 = vec2<f32>( ( nodeVar1.x - nodeVar251.x ), ( nodeVar1.y - nodeVar251.y ) );
		nodeVar253 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar243 = vec2<f32>( ( vec2<f32>( ( nodeVar250.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar250.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.16666666666666663 ), ( vec2<f32>( ( nodeVar252.x * ( knobs.strength / nodeVar253 ) ), ( nodeVar252.y * ( knobs.strength / nodeVar253 ) ) ).x * 0.16666666666666663 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar255 = ( knobs.angle * 0.017453292519943295 );
		nodeVar256 = vec2<f32>( cos( nodeVar255 ), sin( nodeVar255 ) );
		nodeVar257 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar258 = vec2<f32>( ( nodeVar1.x - nodeVar257.x ), ( nodeVar1.y - nodeVar257.y ) );
		nodeVar259 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar254 = vec2<f32>( ( vec2<f32>( ( nodeVar256.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar256.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.16666666666666663 ), ( vec2<f32>( ( nodeVar258.x * ( knobs.strength / nodeVar259 ) ), ( nodeVar258.y * ( knobs.strength / nodeVar259 ) ) ).y * 0.16666666666666663 ) ).y;

	} else {

		nodeVar260 = ( knobs.angle * 0.017453292519943295 );
		nodeVar261 = vec2<f32>( cos( nodeVar260 ), sin( nodeVar260 ) );
		nodeVar262 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar263 = vec2<f32>( ( nodeVar1.x - nodeVar262.x ), ( nodeVar1.y - nodeVar262.y ) );
		nodeVar264 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar254 = vec2<f32>( ( vec2<f32>( ( nodeVar261.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar261.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.16666666666666663 ), ( vec2<f32>( ( nodeVar263.x * ( knobs.strength / nodeVar264 ) ), ( nodeVar263.y * ( knobs.strength / nodeVar264 ) ) ).y * 0.16666666666666663 ) ).x;

	}

	nodeVar265 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar243 ), ( nodeVar1.y + nodeVar254 ) ) );
	nodeVar266 = step( 10.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar268 = ( knobs.angle * 0.017453292519943295 );
		nodeVar269 = vec2<f32>( cos( nodeVar268 ), sin( nodeVar268 ) );
		nodeVar270 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar271 = vec2<f32>( ( nodeVar1.x - nodeVar270.x ), ( nodeVar1.y - nodeVar270.y ) );
		nodeVar272 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar267 = vec2<f32>( ( vec2<f32>( ( nodeVar269.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar269.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.23333333333333328 ), ( vec2<f32>( ( nodeVar271.x * ( knobs.strength / nodeVar272 ) ), ( nodeVar271.y * ( knobs.strength / nodeVar272 ) ) ).x * 0.23333333333333328 ) ).y;

	} else {

		nodeVar273 = ( knobs.angle * 0.017453292519943295 );
		nodeVar274 = vec2<f32>( cos( nodeVar273 ), sin( nodeVar273 ) );
		nodeVar275 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar276 = vec2<f32>( ( nodeVar1.x - nodeVar275.x ), ( nodeVar1.y - nodeVar275.y ) );
		nodeVar277 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar267 = vec2<f32>( ( vec2<f32>( ( nodeVar274.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar274.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.23333333333333328 ), ( vec2<f32>( ( nodeVar276.x * ( knobs.strength / nodeVar277 ) ), ( nodeVar276.y * ( knobs.strength / nodeVar277 ) ) ).x * 0.23333333333333328 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar279 = ( knobs.angle * 0.017453292519943295 );
		nodeVar280 = vec2<f32>( cos( nodeVar279 ), sin( nodeVar279 ) );
		nodeVar281 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar282 = vec2<f32>( ( nodeVar1.x - nodeVar281.x ), ( nodeVar1.y - nodeVar281.y ) );
		nodeVar283 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar278 = vec2<f32>( ( vec2<f32>( ( nodeVar280.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar280.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.23333333333333328 ), ( vec2<f32>( ( nodeVar282.x * ( knobs.strength / nodeVar283 ) ), ( nodeVar282.y * ( knobs.strength / nodeVar283 ) ) ).y * 0.23333333333333328 ) ).y;

	} else {

		nodeVar284 = ( knobs.angle * 0.017453292519943295 );
		nodeVar285 = vec2<f32>( cos( nodeVar284 ), sin( nodeVar284 ) );
		nodeVar286 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar287 = vec2<f32>( ( nodeVar1.x - nodeVar286.x ), ( nodeVar1.y - nodeVar286.y ) );
		nodeVar288 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar278 = vec2<f32>( ( vec2<f32>( ( nodeVar285.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar285.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.23333333333333328 ), ( vec2<f32>( ( nodeVar287.x * ( knobs.strength / nodeVar288 ) ), ( nodeVar287.y * ( knobs.strength / nodeVar288 ) ) ).y * 0.23333333333333328 ) ).x;

	}

	nodeVar289 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar267 ), ( nodeVar1.y + nodeVar278 ) ) );
	nodeVar290 = step( 11.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar292 = ( knobs.angle * 0.017453292519943295 );
		nodeVar293 = vec2<f32>( cos( nodeVar292 ), sin( nodeVar292 ) );
		nodeVar294 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar295 = vec2<f32>( ( nodeVar1.x - nodeVar294.x ), ( nodeVar1.y - nodeVar294.y ) );
		nodeVar296 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar291 = vec2<f32>( ( vec2<f32>( ( nodeVar293.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar293.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.30000000000000004 ), ( vec2<f32>( ( nodeVar295.x * ( knobs.strength / nodeVar296 ) ), ( nodeVar295.y * ( knobs.strength / nodeVar296 ) ) ).x * 0.30000000000000004 ) ).y;

	} else {

		nodeVar297 = ( knobs.angle * 0.017453292519943295 );
		nodeVar298 = vec2<f32>( cos( nodeVar297 ), sin( nodeVar297 ) );
		nodeVar299 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar300 = vec2<f32>( ( nodeVar1.x - nodeVar299.x ), ( nodeVar1.y - nodeVar299.y ) );
		nodeVar301 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar291 = vec2<f32>( ( vec2<f32>( ( nodeVar298.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar298.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.30000000000000004 ), ( vec2<f32>( ( nodeVar300.x * ( knobs.strength / nodeVar301 ) ), ( nodeVar300.y * ( knobs.strength / nodeVar301 ) ) ).x * 0.30000000000000004 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar303 = ( knobs.angle * 0.017453292519943295 );
		nodeVar304 = vec2<f32>( cos( nodeVar303 ), sin( nodeVar303 ) );
		nodeVar305 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar306 = vec2<f32>( ( nodeVar1.x - nodeVar305.x ), ( nodeVar1.y - nodeVar305.y ) );
		nodeVar307 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar302 = vec2<f32>( ( vec2<f32>( ( nodeVar304.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar304.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.30000000000000004 ), ( vec2<f32>( ( nodeVar306.x * ( knobs.strength / nodeVar307 ) ), ( nodeVar306.y * ( knobs.strength / nodeVar307 ) ) ).y * 0.30000000000000004 ) ).y;

	} else {

		nodeVar308 = ( knobs.angle * 0.017453292519943295 );
		nodeVar309 = vec2<f32>( cos( nodeVar308 ), sin( nodeVar308 ) );
		nodeVar310 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar311 = vec2<f32>( ( nodeVar1.x - nodeVar310.x ), ( nodeVar1.y - nodeVar310.y ) );
		nodeVar312 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar302 = vec2<f32>( ( vec2<f32>( ( nodeVar309.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar309.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.30000000000000004 ), ( vec2<f32>( ( nodeVar311.x * ( knobs.strength / nodeVar312 ) ), ( nodeVar311.y * ( knobs.strength / nodeVar312 ) ) ).y * 0.30000000000000004 ) ).x;

	}

	nodeVar313 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar291 ), ( nodeVar1.y + nodeVar302 ) ) );
	nodeVar314 = step( 12.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar316 = ( knobs.angle * 0.017453292519943295 );
		nodeVar317 = vec2<f32>( cos( nodeVar316 ), sin( nodeVar316 ) );
		nodeVar318 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar319 = vec2<f32>( ( nodeVar1.x - nodeVar318.x ), ( nodeVar1.y - nodeVar318.y ) );
		nodeVar320 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar315 = vec2<f32>( ( vec2<f32>( ( nodeVar317.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar317.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.3666666666666667 ), ( vec2<f32>( ( nodeVar319.x * ( knobs.strength / nodeVar320 ) ), ( nodeVar319.y * ( knobs.strength / nodeVar320 ) ) ).x * 0.3666666666666667 ) ).y;

	} else {

		nodeVar321 = ( knobs.angle * 0.017453292519943295 );
		nodeVar322 = vec2<f32>( cos( nodeVar321 ), sin( nodeVar321 ) );
		nodeVar323 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar324 = vec2<f32>( ( nodeVar1.x - nodeVar323.x ), ( nodeVar1.y - nodeVar323.y ) );
		nodeVar325 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar315 = vec2<f32>( ( vec2<f32>( ( nodeVar322.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar322.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.3666666666666667 ), ( vec2<f32>( ( nodeVar324.x * ( knobs.strength / nodeVar325 ) ), ( nodeVar324.y * ( knobs.strength / nodeVar325 ) ) ).x * 0.3666666666666667 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar327 = ( knobs.angle * 0.017453292519943295 );
		nodeVar328 = vec2<f32>( cos( nodeVar327 ), sin( nodeVar327 ) );
		nodeVar329 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar330 = vec2<f32>( ( nodeVar1.x - nodeVar329.x ), ( nodeVar1.y - nodeVar329.y ) );
		nodeVar331 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar326 = vec2<f32>( ( vec2<f32>( ( nodeVar328.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar328.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.3666666666666667 ), ( vec2<f32>( ( nodeVar330.x * ( knobs.strength / nodeVar331 ) ), ( nodeVar330.y * ( knobs.strength / nodeVar331 ) ) ).y * 0.3666666666666667 ) ).y;

	} else {

		nodeVar332 = ( knobs.angle * 0.017453292519943295 );
		nodeVar333 = vec2<f32>( cos( nodeVar332 ), sin( nodeVar332 ) );
		nodeVar334 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar335 = vec2<f32>( ( nodeVar1.x - nodeVar334.x ), ( nodeVar1.y - nodeVar334.y ) );
		nodeVar336 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar326 = vec2<f32>( ( vec2<f32>( ( nodeVar333.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar333.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.3666666666666667 ), ( vec2<f32>( ( nodeVar335.x * ( knobs.strength / nodeVar336 ) ), ( nodeVar335.y * ( knobs.strength / nodeVar336 ) ) ).y * 0.3666666666666667 ) ).x;

	}

	nodeVar337 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar315 ), ( nodeVar1.y + nodeVar326 ) ) );
	nodeVar338 = step( 13.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar340 = ( knobs.angle * 0.017453292519943295 );
		nodeVar341 = vec2<f32>( cos( nodeVar340 ), sin( nodeVar340 ) );
		nodeVar342 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar343 = vec2<f32>( ( nodeVar1.x - nodeVar342.x ), ( nodeVar1.y - nodeVar342.y ) );
		nodeVar344 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar339 = vec2<f32>( ( vec2<f32>( ( nodeVar341.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar341.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.43333333333333335 ), ( vec2<f32>( ( nodeVar343.x * ( knobs.strength / nodeVar344 ) ), ( nodeVar343.y * ( knobs.strength / nodeVar344 ) ) ).x * 0.43333333333333335 ) ).y;

	} else {

		nodeVar345 = ( knobs.angle * 0.017453292519943295 );
		nodeVar346 = vec2<f32>( cos( nodeVar345 ), sin( nodeVar345 ) );
		nodeVar347 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar348 = vec2<f32>( ( nodeVar1.x - nodeVar347.x ), ( nodeVar1.y - nodeVar347.y ) );
		nodeVar349 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar339 = vec2<f32>( ( vec2<f32>( ( nodeVar346.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar346.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.43333333333333335 ), ( vec2<f32>( ( nodeVar348.x * ( knobs.strength / nodeVar349 ) ), ( nodeVar348.y * ( knobs.strength / nodeVar349 ) ) ).x * 0.43333333333333335 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar351 = ( knobs.angle * 0.017453292519943295 );
		nodeVar352 = vec2<f32>( cos( nodeVar351 ), sin( nodeVar351 ) );
		nodeVar353 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar354 = vec2<f32>( ( nodeVar1.x - nodeVar353.x ), ( nodeVar1.y - nodeVar353.y ) );
		nodeVar355 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar350 = vec2<f32>( ( vec2<f32>( ( nodeVar352.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar352.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.43333333333333335 ), ( vec2<f32>( ( nodeVar354.x * ( knobs.strength / nodeVar355 ) ), ( nodeVar354.y * ( knobs.strength / nodeVar355 ) ) ).y * 0.43333333333333335 ) ).y;

	} else {

		nodeVar356 = ( knobs.angle * 0.017453292519943295 );
		nodeVar357 = vec2<f32>( cos( nodeVar356 ), sin( nodeVar356 ) );
		nodeVar358 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar359 = vec2<f32>( ( nodeVar1.x - nodeVar358.x ), ( nodeVar1.y - nodeVar358.y ) );
		nodeVar360 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar350 = vec2<f32>( ( vec2<f32>( ( nodeVar357.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar357.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.43333333333333335 ), ( vec2<f32>( ( nodeVar359.x * ( knobs.strength / nodeVar360 ) ), ( nodeVar359.y * ( knobs.strength / nodeVar360 ) ) ).y * 0.43333333333333335 ) ).x;

	}

	nodeVar361 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar339 ), ( nodeVar1.y + nodeVar350 ) ) );
	nodeVar362 = step( 14.5, knobs.samples );

	if ( nodeVar3 ) {

		nodeVar364 = ( knobs.angle * 0.017453292519943295 );
		nodeVar365 = vec2<f32>( cos( nodeVar364 ), sin( nodeVar364 ) );
		nodeVar366 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar367 = vec2<f32>( ( nodeVar1.x - nodeVar366.x ), ( nodeVar1.y - nodeVar366.y ) );
		nodeVar368 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar363 = vec2<f32>( ( vec2<f32>( ( nodeVar365.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar365.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.5 ), ( vec2<f32>( ( nodeVar367.x * ( knobs.strength / nodeVar368 ) ), ( nodeVar367.y * ( knobs.strength / nodeVar368 ) ) ).x * 0.5 ) ).y;

	} else {

		nodeVar369 = ( knobs.angle * 0.017453292519943295 );
		nodeVar370 = vec2<f32>( cos( nodeVar369 ), sin( nodeVar369 ) );
		nodeVar371 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar372 = vec2<f32>( ( nodeVar1.x - nodeVar371.x ), ( nodeVar1.y - nodeVar371.y ) );
		nodeVar373 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar363 = vec2<f32>( ( vec2<f32>( ( nodeVar370.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar370.y * ( knobs.strength / knobs.resolution.y ) ) ).x * 0.5 ), ( vec2<f32>( ( nodeVar372.x * ( knobs.strength / nodeVar373 ) ), ( nodeVar372.y * ( knobs.strength / nodeVar373 ) ) ).x * 0.5 ) ).x;

	}


	if ( nodeVar3 ) {

		nodeVar375 = ( knobs.angle * 0.017453292519943295 );
		nodeVar376 = vec2<f32>( cos( nodeVar375 ), sin( nodeVar375 ) );
		nodeVar377 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar378 = vec2<f32>( ( nodeVar1.x - nodeVar377.x ), ( nodeVar1.y - nodeVar377.y ) );
		nodeVar379 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar374 = vec2<f32>( ( vec2<f32>( ( nodeVar376.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar376.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.5 ), ( vec2<f32>( ( nodeVar378.x * ( knobs.strength / nodeVar379 ) ), ( nodeVar378.y * ( knobs.strength / nodeVar379 ) ) ).y * 0.5 ) ).y;

	} else {

		nodeVar380 = ( knobs.angle * 0.017453292519943295 );
		nodeVar381 = vec2<f32>( cos( nodeVar380 ), sin( nodeVar380 ) );
		nodeVar382 = vec2<f32>( f32(0.5), f32(0.5) );
		nodeVar383 = vec2<f32>( ( nodeVar1.x - nodeVar382.x ), ( nodeVar1.y - nodeVar382.y ) );
		nodeVar384 = min( knobs.resolution.x, knobs.resolution.y );
		nodeVar374 = vec2<f32>( ( vec2<f32>( ( nodeVar381.x * ( knobs.strength / knobs.resolution.x ) ), ( nodeVar381.y * ( knobs.strength / knobs.resolution.y ) ) ).y * 0.5 ), ( vec2<f32>( ( nodeVar383.x * ( knobs.strength / nodeVar384 ) ), ( nodeVar383.y * ( knobs.strength / nodeVar384 ) ) ).y * 0.5 ) ).x;

	}

	nodeVar385 = picture_read( vec2<f32>( ( nodeVar1.x + nodeVar363 ), ( nodeVar1.y + nodeVar374 ) ) );
	nodeVar386 = step( 15.5, knobs.samples );
	nodeVar387 = max( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + nodeVar26 ) + nodeVar50 ) + nodeVar74 ) + nodeVar98 ) + nodeVar122 ) + nodeVar146 ) + nodeVar170 ) + nodeVar194 ) + nodeVar218 ) + nodeVar242 ) + nodeVar266 ) + nodeVar290 ) + nodeVar314 ) + nodeVar338 ) + nodeVar362 ) + nodeVar386 ), 1.0 );
	nodeVar388 = vec4<f32>( vec3<f32>( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar25.x * nodeVar26 ) ) + ( nodeVar49.x * nodeVar50 ) ) + ( nodeVar73.x * nodeVar74 ) ) + ( nodeVar97.x * nodeVar98 ) ) + ( nodeVar121.x * nodeVar122 ) ) + ( nodeVar145.x * nodeVar146 ) ) + ( nodeVar169.x * nodeVar170 ) ) + ( nodeVar193.x * nodeVar194 ) ) + ( nodeVar217.x * nodeVar218 ) ) + ( nodeVar241.x * nodeVar242 ) ) + ( nodeVar265.x * nodeVar266 ) ) + ( nodeVar289.x * nodeVar290 ) ) + ( nodeVar313.x * nodeVar314 ) ) + ( nodeVar337.x * nodeVar338 ) ) + ( nodeVar361.x * nodeVar362 ) ) + ( nodeVar385.x * nodeVar386 ) ) / nodeVar387 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar25.y * nodeVar26 ) ) + ( nodeVar49.y * nodeVar50 ) ) + ( nodeVar73.y * nodeVar74 ) ) + ( nodeVar97.y * nodeVar98 ) ) + ( nodeVar121.y * nodeVar122 ) ) + ( nodeVar145.y * nodeVar146 ) ) + ( nodeVar169.y * nodeVar170 ) ) + ( nodeVar193.y * nodeVar194 ) ) + ( nodeVar217.y * nodeVar218 ) ) + ( nodeVar241.y * nodeVar242 ) ) + ( nodeVar265.y * nodeVar266 ) ) + ( nodeVar289.y * nodeVar290 ) ) + ( nodeVar313.y * nodeVar314 ) ) + ( nodeVar337.y * nodeVar338 ) ) + ( nodeVar361.y * nodeVar362 ) ) + ( nodeVar385.y * nodeVar386 ) ) / nodeVar387 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar25.z * nodeVar26 ) ) + ( nodeVar49.z * nodeVar50 ) ) + ( nodeVar73.z * nodeVar74 ) ) + ( nodeVar97.z * nodeVar98 ) ) + ( nodeVar121.z * nodeVar122 ) ) + ( nodeVar145.z * nodeVar146 ) ) + ( nodeVar169.z * nodeVar170 ) ) + ( nodeVar193.z * nodeVar194 ) ) + ( nodeVar217.z * nodeVar218 ) ) + ( nodeVar241.z * nodeVar242 ) ) + ( nodeVar265.z * nodeVar266 ) ) + ( nodeVar289.z * nodeVar290 ) ) + ( nodeVar313.z * nodeVar314 ) ) + ( nodeVar337.z * nodeVar338 ) ) + ( nodeVar361.z * nodeVar362 ) ) + ( nodeVar385.z * nodeVar386 ) ) / nodeVar387 ) ), 1.0 );
	nodeVar389 = vec3<f32>( nodeVar388.x, nodeVar388.y, nodeVar388.z );
	nodeVar390 = ( ( ( nodeVar389.x * 0.2126 ) + ( nodeVar389.y * 0.7152 ) ) + ( nodeVar389.z * 0.0722 ) );
	nodeVar391 = mix( vec3<f32>( nodeVar390, nodeVar390, nodeVar390 ), nodeVar389, f32(1.0) );
	nodeVar392 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar391.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar391.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar391.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar391.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar391.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar391.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar391.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar391.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar391.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar388.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar392.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar392.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar393 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar393;

	// result

	output.color = nodeVar393;

	output.color = to_shelf(output.color);
	return output;

}

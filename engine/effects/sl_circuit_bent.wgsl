// Circuit Bent: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Turns the image into scanlines and bends them around a point that pulls or pushes.
// --check@colorMode:Color Mode,0
// --check@invert:Invert,0
// --track@signalBlackPoint:Black Point,0,1,0,0.01
// --track@signalWhitePoint:White Point,0,1,0.22,0.01
// --track@signalGamma:Gamma,0.1,5,3.07,0.01
// --track@presenceThreshold:Presence,0,1,0.37,0.01
// --track@presenceSoftness:Presence Softness,0,1,0.64,0.01
// --track@linePitch:Pitch,2,48,6.4,0.1
// --track@lineThickness:Thickness,0.5,8,0.5,0.1
// --track@lineAngle:Angle,0,180,0,1
// --track@noiseMode:Noise Type,0,2,2,1
// --track@noiseAmount:Amount,0,1,1,0.01
// --track@scrollSpeed:Scroll Speed,0,4,4,0.01
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
  colorMode: f32,
  lineAngle: f32,
  resolution: vec2<f32>,
  scrollSpeed: f32,
  linePitch: f32,
  lineThickness: f32,
  invert: f32,
  signalBlackPoint: f32,
  signalWhitePoint: f32,
  signalGamma: f32,
  noiseMode: f32,
  noiseAmount: f32,
  presenceThreshold: f32,
  presenceSoftness: f32,
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
var<private> nodeVar3 : f32;
var<private> nodeVar4 : vec2<f32>;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : f32;
var<private> nodeVar8 : vec2<f32>;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : f32;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : vec4<f32>;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : bool;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : vec2<f32>;
var<private> nodeVar18 : vec2<f32>;
var<private> nodeVar19 : vec2<f32>;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec2<f32>;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : vec4<f32>;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : vec2<f32>;
var<private> nodeVar28 : vec2<f32>;
var<private> nodeVar29 : vec2<f32>;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : vec2<f32>;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : vec4<f32>;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : f32;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : vec2<f32>;
var<private> nodeVar41 : vec2<f32>;
var<private> nodeVar42 : f32;
var<private> nodeVar43 : vec2<f32>;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : f32;
var<private> nodeVar47 : f32;
var<private> nodeVar48 : f32;
var<private> nodeVar49 : f32;
var<private> nodeVar50 : f32;
var<private> nodeVar51 : bool;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : f32;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : f32;
var<private> nodeVar58 : f32;
var<private> nodeVar59 : f32;
var<private> nodeVar60 : f32;
var<private> nodeVar61 : f32;
var<private> nodeVar62 : f32;
var<private> nodeVar63 : f32;
var<private> nodeVar64 : f32;
var<private> nodeVar65 : f32;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : f32;
var<private> nodeVar69 : f32;
var<private> nodeVar70 : f32;
var<private> nodeVar71 : f32;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : f32;
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
var<private> nodeVar104 : f32;
var<private> nodeVar105 : vec2<f32>;
var<private> nodeVar106 : f32;
var<private> nodeVar107 : f32;
var<private> nodeVar108 : vec4<f32>;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : vec2<f32>;
var<private> nodeVar111 : f32;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : vec4<f32>;
var<private> nodeVar114 : vec2<f32>;
var<private> nodeVar115 : f32;
var<private> nodeVar116 : f32;
var<private> nodeVar117 : vec4<f32>;
var<private> nodeVar118 : f32;
var<private> nodeVar119 : f32;
var<private> nodeVar120 : f32;
var<private> nodeVar121 : f32;
var<private> nodeVar122 : f32;
var<private> nodeVar123 : f32;
var<private> nodeVar124 : f32;
var<private> nodeVar125 : f32;
var<private> nodeVar126 : f32;
var<private> nodeVar127 : f32;
var<private> nodeVar128 : f32;
var<private> nodeVar129 : f32;
var<private> nodeVar130 : f32;
var<private> nodeVar131 : f32;
var<private> nodeVar132 : f32;
var<private> nodeVar133 : f32;
var<private> nodeVar134 : f32;
var<private> nodeVar135 : f32;
var<private> nodeVar136 : f32;
var<private> nodeVar137 : f32;
var<private> nodeVar138 : f32;
var<private> nodeVar139 : f32;
var<private> nodeVar140 : f32;
var<private> nodeVar141 : f32;
var<private> nodeVar142 : f32;
var<private> nodeVar143 : f32;
var<private> nodeVar144 : f32;
var<private> nodeVar145 : f32;
var<private> nodeVar146 : f32;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : f32;
var<private> nodeVar149 : f32;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : f32;
var<private> nodeVar154 : f32;
var<private> nodeVar155 : f32;
var<private> nodeVar156 : f32;
var<private> nodeVar157 : f32;
var<private> nodeVar158 : f32;
var<private> nodeVar159 : f32;
var<private> nodeVar160 : f32;
var<private> nodeVar161 : f32;
var<private> nodeVar162 : f32;
var<private> nodeVar163 : f32;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : f32;
var<private> nodeVar166 : f32;
var<private> nodeVar167 : f32;
var<private> nodeVar168 : f32;
var<private> nodeVar169 : f32;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : vec2<f32>;
var<private> nodeVar173 : f32;
var<private> nodeVar174 : f32;
var<private> nodeVar175 : vec4<f32>;
var<private> nodeVar176 : f32;
var<private> nodeVar177 : vec2<f32>;
var<private> nodeVar178 : f32;
var<private> nodeVar179 : f32;
var<private> nodeVar180 : vec4<f32>;
var<private> nodeVar181 : vec2<f32>;
var<private> nodeVar182 : f32;
var<private> nodeVar183 : f32;
var<private> nodeVar184 : vec4<f32>;
var<private> nodeVar185 : f32;
var<private> nodeVar186 : f32;
var<private> nodeVar187 : f32;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : f32;
var<private> nodeVar190 : f32;
var<private> nodeVar191 : f32;
var<private> nodeVar192 : f32;
var<private> nodeVar193 : f32;
var<private> nodeVar194 : f32;
var<private> nodeVar195 : f32;
var<private> nodeVar196 : f32;
var<private> nodeVar197 : f32;
var<private> nodeVar198 : f32;
var<private> nodeVar199 : f32;
var<private> nodeVar200 : f32;
var<private> nodeVar201 : f32;
var<private> nodeVar202 : f32;
var<private> nodeVar203 : f32;
var<private> nodeVar204 : f32;
var<private> nodeVar205 : f32;
var<private> nodeVar206 : f32;
var<private> nodeVar207 : f32;
var<private> nodeVar208 : f32;
var<private> nodeVar209 : f32;
var<private> nodeVar210 : f32;
var<private> nodeVar211 : f32;
var<private> nodeVar212 : f32;
var<private> nodeVar213 : f32;
var<private> nodeVar214 : f32;
var<private> nodeVar215 : f32;
var<private> nodeVar216 : f32;
var<private> nodeVar217 : f32;
var<private> nodeVar218 : f32;
var<private> nodeVar219 : f32;
var<private> nodeVar220 : f32;
var<private> nodeVar221 : f32;
var<private> nodeVar222 : f32;
var<private> nodeVar223 : f32;
var<private> nodeVar224 : f32;
var<private> nodeVar225 : f32;
var<private> nodeVar226 : f32;
var<private> nodeVar227 : f32;
var<private> nodeVar228 : f32;
var<private> nodeVar229 : f32;
var<private> nodeVar230 : f32;
var<private> nodeVar231 : f32;
var<private> nodeVar232 : f32;
var<private> nodeVar233 : f32;
var<private> nodeVar234 : f32;
var<private> nodeVar235 : f32;
var<private> nodeVar236 : f32;
var<private> nodeVar237 : f32;
var<private> nodeVar238 : f32;
var<private> nodeVar239 : vec2<f32>;
var<private> nodeVar240 : f32;
var<private> nodeVar241 : f32;
var<private> nodeVar242 : vec4<f32>;
var<private> nodeVar243 : f32;
var<private> nodeVar244 : vec2<f32>;
var<private> nodeVar245 : f32;
var<private> nodeVar246 : f32;
var<private> nodeVar247 : vec4<f32>;
var<private> nodeVar248 : vec2<f32>;
var<private> nodeVar249 : f32;
var<private> nodeVar250 : f32;
var<private> nodeVar251 : vec4<f32>;
var<private> nodeVar252 : f32;
var<private> nodeVar253 : f32;
var<private> nodeVar254 : f32;
var<private> nodeVar255 : f32;
var<private> nodeVar256 : f32;
var<private> nodeVar257 : f32;
var<private> nodeVar258 : f32;
var<private> nodeVar259 : f32;
var<private> nodeVar260 : f32;
var<private> nodeVar261 : f32;
var<private> nodeVar262 : f32;
var<private> nodeVar263 : f32;
var<private> nodeVar264 : f32;
var<private> nodeVar265 : f32;
var<private> nodeVar266 : f32;
var<private> nodeVar267 : f32;
var<private> nodeVar268 : f32;
var<private> nodeVar269 : f32;
var<private> nodeVar270 : f32;
var<private> nodeVar271 : f32;
var<private> nodeVar272 : f32;
var<private> nodeVar273 : f32;
var<private> nodeVar274 : f32;
var<private> nodeVar275 : f32;
var<private> nodeVar276 : f32;
var<private> nodeVar277 : f32;
var<private> nodeVar278 : f32;
var<private> nodeVar279 : f32;
var<private> nodeVar280 : f32;
var<private> nodeVar281 : f32;
var<private> nodeVar282 : f32;
var<private> nodeVar283 : f32;
var<private> nodeVar284 : f32;
var<private> nodeVar285 : f32;
var<private> nodeVar286 : f32;
var<private> nodeVar287 : f32;
var<private> nodeVar288 : f32;
var<private> nodeVar289 : f32;
var<private> nodeVar290 : f32;
var<private> nodeVar291 : f32;
var<private> nodeVar292 : f32;
var<private> nodeVar293 : f32;
var<private> nodeVar294 : f32;
var<private> nodeVar295 : f32;
var<private> nodeVar296 : f32;
var<private> nodeVar297 : f32;
var<private> nodeVar298 : f32;
var<private> nodeVar299 : f32;
var<private> nodeVar300 : f32;
var<private> nodeVar301 : f32;
var<private> nodeVar302 : f32;
var<private> nodeVar303 : f32;
var<private> nodeVar304 : f32;
var<private> nodeVar305 : f32;
var<private> nodeVar306 : vec2<f32>;
var<private> nodeVar307 : f32;
var<private> nodeVar308 : f32;
var<private> nodeVar309 : vec4<f32>;
var<private> nodeVar310 : f32;
var<private> nodeVar311 : vec2<f32>;
var<private> nodeVar312 : f32;
var<private> nodeVar313 : f32;
var<private> nodeVar314 : vec4<f32>;
var<private> nodeVar315 : vec2<f32>;
var<private> nodeVar316 : f32;
var<private> nodeVar317 : f32;
var<private> nodeVar318 : vec4<f32>;
var<private> nodeVar319 : f32;
var<private> nodeVar320 : f32;
var<private> nodeVar321 : f32;
var<private> nodeVar322 : f32;
var<private> nodeVar323 : f32;
var<private> nodeVar324 : f32;
var<private> nodeVar325 : f32;
var<private> nodeVar326 : f32;
var<private> nodeVar327 : f32;
var<private> nodeVar328 : f32;
var<private> nodeVar329 : f32;
var<private> nodeVar330 : f32;
var<private> nodeVar331 : f32;
var<private> nodeVar332 : f32;
var<private> nodeVar333 : f32;
var<private> nodeVar334 : f32;
var<private> nodeVar335 : f32;
var<private> nodeVar336 : f32;
var<private> nodeVar337 : f32;
var<private> nodeVar338 : f32;
var<private> nodeVar339 : f32;
var<private> nodeVar340 : f32;
var<private> nodeVar341 : f32;
var<private> nodeVar342 : f32;
var<private> nodeVar343 : f32;
var<private> nodeVar344 : f32;
var<private> nodeVar345 : f32;
var<private> nodeVar346 : f32;
var<private> nodeVar347 : f32;
var<private> nodeVar348 : f32;
var<private> nodeVar349 : f32;
var<private> nodeVar350 : f32;
var<private> nodeVar351 : f32;
var<private> nodeVar352 : f32;
var<private> nodeVar353 : f32;
var<private> nodeVar354 : f32;
var<private> nodeVar355 : f32;
var<private> nodeVar356 : f32;
var<private> nodeVar357 : f32;
var<private> nodeVar358 : f32;
var<private> nodeVar359 : f32;
var<private> nodeVar360 : f32;
var<private> nodeVar361 : f32;
var<private> nodeVar362 : f32;
var<private> nodeVar363 : f32;
var<private> nodeVar364 : f32;
var<private> nodeVar365 : f32;
var<private> nodeVar366 : f32;
var<private> nodeVar367 : f32;
var<private> nodeVar368 : f32;
var<private> nodeVar369 : f32;
var<private> nodeVar370 : f32;
var<private> nodeVar371 : f32;
var<private> nodeVar372 : f32;
var<private> nodeVar373 : vec2<f32>;
var<private> nodeVar374 : f32;
var<private> nodeVar375 : f32;
var<private> nodeVar376 : vec4<f32>;
var<private> nodeVar377 : f32;
var<private> nodeVar378 : vec2<f32>;
var<private> nodeVar379 : f32;
var<private> nodeVar380 : f32;
var<private> nodeVar381 : vec4<f32>;
var<private> nodeVar382 : vec2<f32>;
var<private> nodeVar383 : f32;
var<private> nodeVar384 : f32;
var<private> nodeVar385 : vec4<f32>;
var<private> nodeVar386 : f32;
var<private> nodeVar387 : f32;
var<private> nodeVar388 : f32;
var<private> nodeVar389 : f32;
var<private> nodeVar390 : f32;
var<private> nodeVar391 : f32;
var<private> nodeVar392 : f32;
var<private> nodeVar393 : f32;
var<private> nodeVar394 : f32;
var<private> nodeVar395 : f32;
var<private> nodeVar396 : f32;
var<private> nodeVar397 : f32;
var<private> nodeVar398 : f32;
var<private> nodeVar399 : f32;
var<private> nodeVar400 : f32;
var<private> nodeVar401 : f32;
var<private> nodeVar402 : f32;
var<private> nodeVar403 : f32;
var<private> nodeVar404 : f32;
var<private> nodeVar405 : f32;
var<private> nodeVar406 : f32;
var<private> nodeVar407 : f32;
var<private> nodeVar408 : f32;
var<private> nodeVar409 : f32;
var<private> nodeVar410 : f32;
var<private> nodeVar411 : f32;
var<private> nodeVar412 : f32;
var<private> nodeVar413 : f32;
var<private> nodeVar414 : f32;
var<private> nodeVar415 : f32;
var<private> nodeVar416 : f32;
var<private> nodeVar417 : f32;
var<private> nodeVar418 : f32;
var<private> nodeVar419 : f32;
var<private> nodeVar420 : f32;
var<private> nodeVar421 : f32;
var<private> nodeVar422 : f32;
var<private> nodeVar423 : f32;
var<private> nodeVar424 : f32;
var<private> nodeVar425 : f32;
var<private> nodeVar426 : f32;
var<private> nodeVar427 : f32;
var<private> nodeVar428 : f32;
var<private> nodeVar429 : f32;
var<private> nodeVar430 : f32;
var<private> nodeVar431 : f32;
var<private> nodeVar432 : f32;
var<private> nodeVar433 : f32;
var<private> nodeVar434 : f32;
var<private> nodeVar435 : f32;
var<private> nodeVar436 : f32;
var<private> nodeVar437 : f32;
var<private> nodeVar438 : f32;
var<private> nodeVar439 : f32;
var<private> nodeVar440 : vec2<f32>;
var<private> nodeVar441 : f32;
var<private> nodeVar442 : f32;
var<private> nodeVar443 : vec4<f32>;
var<private> nodeVar444 : f32;
var<private> nodeVar445 : vec2<f32>;
var<private> nodeVar446 : f32;
var<private> nodeVar447 : f32;
var<private> nodeVar448 : vec4<f32>;
var<private> nodeVar449 : vec2<f32>;
var<private> nodeVar450 : f32;
var<private> nodeVar451 : f32;
var<private> nodeVar452 : vec4<f32>;
var<private> nodeVar453 : f32;
var<private> nodeVar454 : f32;
var<private> nodeVar455 : f32;
var<private> nodeVar456 : f32;
var<private> nodeVar457 : f32;
var<private> nodeVar458 : f32;
var<private> nodeVar459 : f32;
var<private> nodeVar460 : f32;
var<private> nodeVar461 : f32;
var<private> nodeVar462 : f32;
var<private> nodeVar463 : f32;
var<private> nodeVar464 : f32;
var<private> nodeVar465 : f32;
var<private> nodeVar466 : f32;
var<private> nodeVar467 : f32;
var<private> nodeVar468 : f32;
var<private> nodeVar469 : f32;
var<private> nodeVar470 : f32;
var<private> nodeVar471 : f32;
var<private> nodeVar472 : f32;
var<private> nodeVar473 : f32;
var<private> nodeVar474 : f32;
var<private> nodeVar475 : f32;
var<private> nodeVar476 : f32;
var<private> nodeVar477 : f32;
var<private> nodeVar478 : f32;
var<private> nodeVar479 : f32;
var<private> nodeVar480 : f32;
var<private> nodeVar481 : f32;
var<private> nodeVar482 : f32;
var<private> nodeVar483 : f32;
var<private> nodeVar484 : f32;
var<private> nodeVar485 : f32;
var<private> nodeVar486 : f32;
var<private> nodeVar487 : f32;
var<private> nodeVar488 : f32;
var<private> nodeVar489 : f32;
var<private> nodeVar490 : f32;
var<private> nodeVar491 : f32;
var<private> nodeVar492 : f32;
var<private> nodeVar493 : f32;
var<private> nodeVar494 : f32;
var<private> nodeVar495 : f32;
var<private> nodeVar496 : f32;
var<private> nodeVar497 : f32;
var<private> nodeVar498 : f32;
var<private> nodeVar499 : f32;
var<private> nodeVar500 : f32;
var<private> nodeVar501 : f32;
var<private> nodeVar502 : f32;
var<private> nodeVar503 : f32;
var<private> nodeVar504 : f32;
var<private> nodeVar505 : f32;
var<private> nodeVar506 : f32;
var<private> nodeVar507 : vec2<f32>;
var<private> nodeVar508 : f32;
var<private> nodeVar509 : f32;
var<private> nodeVar510 : vec4<f32>;
var<private> nodeVar511 : f32;
var<private> nodeVar512 : vec2<f32>;
var<private> nodeVar513 : f32;
var<private> nodeVar514 : f32;
var<private> nodeVar515 : vec4<f32>;
var<private> nodeVar516 : vec2<f32>;
var<private> nodeVar517 : f32;
var<private> nodeVar518 : f32;
var<private> nodeVar519 : vec4<f32>;
var<private> nodeVar520 : f32;
var<private> nodeVar521 : f32;
var<private> nodeVar522 : f32;
var<private> nodeVar523 : f32;
var<private> nodeVar524 : f32;
var<private> nodeVar525 : f32;
var<private> nodeVar526 : f32;
var<private> nodeVar527 : f32;
var<private> nodeVar528 : f32;
var<private> nodeVar529 : f32;
var<private> nodeVar530 : f32;
var<private> nodeVar531 : f32;
var<private> nodeVar532 : f32;
var<private> nodeVar533 : f32;
var<private> nodeVar534 : f32;
var<private> nodeVar535 : f32;
var<private> nodeVar536 : f32;
var<private> nodeVar537 : f32;
var<private> nodeVar538 : f32;
var<private> nodeVar539 : f32;
var<private> nodeVar540 : f32;
var<private> nodeVar541 : f32;
var<private> nodeVar542 : f32;
var<private> nodeVar543 : f32;
var<private> nodeVar544 : f32;
var<private> nodeVar545 : f32;
var<private> nodeVar546 : f32;
var<private> nodeVar547 : f32;
var<private> nodeVar548 : f32;
var<private> nodeVar549 : f32;
var<private> nodeVar550 : f32;
var<private> nodeVar551 : f32;
var<private> nodeVar552 : f32;
var<private> nodeVar553 : f32;
var<private> nodeVar554 : f32;
var<private> nodeVar555 : f32;
var<private> nodeVar556 : f32;
var<private> nodeVar557 : f32;
var<private> nodeVar558 : f32;
var<private> nodeVar559 : f32;
var<private> nodeVar560 : f32;
var<private> nodeVar561 : f32;
var<private> nodeVar562 : f32;
var<private> nodeVar563 : f32;
var<private> nodeVar564 : f32;
var<private> nodeVar565 : f32;
var<private> nodeVar566 : f32;
var<private> nodeVar567 : f32;
var<private> nodeVar568 : f32;
var<private> nodeVar569 : f32;
var<private> nodeVar570 : f32;
var<private> nodeVar571 : f32;
var<private> nodeVar572 : f32;
var<private> nodeVar573 : f32;
var<private> nodeVar574 : vec2<f32>;
var<private> nodeVar575 : f32;
var<private> nodeVar576 : f32;
var<private> nodeVar577 : vec4<f32>;
var<private> nodeVar578 : f32;
var<private> nodeVar579 : vec2<f32>;
var<private> nodeVar580 : f32;
var<private> nodeVar581 : f32;
var<private> nodeVar582 : vec4<f32>;
var<private> nodeVar583 : vec2<f32>;
var<private> nodeVar584 : f32;
var<private> nodeVar585 : f32;
var<private> nodeVar586 : vec4<f32>;
var<private> nodeVar587 : f32;
var<private> nodeVar588 : f32;
var<private> nodeVar589 : f32;
var<private> nodeVar590 : f32;
var<private> nodeVar591 : f32;
var<private> nodeVar592 : f32;
var<private> nodeVar593 : f32;
var<private> nodeVar594 : f32;
var<private> nodeVar595 : f32;
var<private> nodeVar596 : f32;
var<private> nodeVar597 : f32;
var<private> nodeVar598 : f32;
var<private> nodeVar599 : f32;
var<private> nodeVar600 : f32;
var<private> nodeVar601 : f32;
var<private> nodeVar602 : f32;
var<private> nodeVar603 : f32;
var<private> nodeVar604 : f32;
var<private> nodeVar605 : f32;
var<private> nodeVar606 : f32;
var<private> nodeVar607 : f32;
var<private> nodeVar608 : f32;
var<private> nodeVar609 : f32;
var<private> nodeVar610 : f32;
var<private> nodeVar611 : f32;
var<private> nodeVar612 : f32;
var<private> nodeVar613 : f32;
var<private> nodeVar614 : f32;
var<private> nodeVar615 : f32;
var<private> nodeVar616 : f32;
var<private> nodeVar617 : f32;
var<private> nodeVar618 : f32;
var<private> nodeVar619 : f32;
var<private> nodeVar620 : f32;
var<private> nodeVar621 : f32;
var<private> nodeVar622 : f32;
var<private> nodeVar623 : f32;
var<private> nodeVar624 : f32;
var<private> nodeVar625 : f32;
var<private> nodeVar626 : f32;
var<private> nodeVar627 : f32;
var<private> nodeVar628 : f32;
var<private> nodeVar629 : f32;
var<private> nodeVar630 : f32;
var<private> nodeVar631 : f32;
var<private> nodeVar632 : f32;
var<private> nodeVar633 : f32;
var<private> nodeVar634 : f32;
var<private> nodeVar635 : f32;
var<private> nodeVar636 : f32;
var<private> nodeVar637 : f32;
var<private> nodeVar638 : f32;
var<private> nodeVar639 : f32;
var<private> nodeVar640 : f32;
var<private> nodeVar641 : vec2<f32>;
var<private> nodeVar642 : f32;
var<private> nodeVar643 : f32;
var<private> nodeVar644 : vec4<f32>;
var<private> nodeVar645 : f32;
var<private> nodeVar646 : vec2<f32>;
var<private> nodeVar647 : f32;
var<private> nodeVar648 : f32;
var<private> nodeVar649 : vec4<f32>;
var<private> nodeVar650 : vec2<f32>;
var<private> nodeVar651 : f32;
var<private> nodeVar652 : f32;
var<private> nodeVar653 : vec4<f32>;
var<private> nodeVar654 : f32;
var<private> nodeVar655 : f32;
var<private> nodeVar656 : f32;
var<private> nodeVar657 : f32;
var<private> nodeVar658 : f32;
var<private> nodeVar659 : f32;
var<private> nodeVar660 : f32;
var<private> nodeVar661 : f32;
var<private> nodeVar662 : f32;
var<private> nodeVar663 : f32;
var<private> nodeVar664 : f32;
var<private> nodeVar665 : f32;
var<private> nodeVar666 : f32;
var<private> nodeVar667 : f32;
var<private> nodeVar668 : f32;
var<private> nodeVar669 : f32;
var<private> nodeVar670 : f32;
var<private> nodeVar671 : f32;
var<private> nodeVar672 : f32;
var<private> nodeVar673 : f32;
var<private> nodeVar674 : f32;
var<private> nodeVar675 : f32;
var<private> nodeVar676 : f32;
var<private> nodeVar677 : f32;
var<private> nodeVar678 : f32;
var<private> nodeVar679 : f32;
var<private> nodeVar680 : f32;
var<private> nodeVar681 : f32;
var<private> nodeVar682 : f32;
var<private> nodeVar683 : f32;
var<private> nodeVar684 : f32;
var<private> nodeVar685 : f32;
var<private> nodeVar686 : f32;
var<private> nodeVar687 : f32;
var<private> nodeVar688 : f32;
var<private> nodeVar689 : f32;
var<private> nodeVar690 : f32;
var<private> nodeVar691 : f32;
var<private> nodeVar692 : f32;
var<private> nodeVar693 : f32;
var<private> nodeVar694 : f32;
var<private> nodeVar695 : f32;
var<private> nodeVar696 : f32;
var<private> nodeVar697 : f32;
var<private> nodeVar698 : f32;
var<private> nodeVar699 : f32;
var<private> nodeVar700 : f32;
var<private> nodeVar701 : f32;
var<private> nodeVar702 : f32;
var<private> nodeVar703 : f32;
var<private> nodeVar704 : f32;
var<private> nodeVar705 : f32;
var<private> nodeVar706 : f32;
var<private> nodeVar707 : f32;
var<private> nodeVar708 : vec2<f32>;
var<private> nodeVar709 : f32;
var<private> nodeVar710 : f32;
var<private> nodeVar711 : vec4<f32>;
var<private> nodeVar712 : f32;
var<private> nodeVar713 : vec2<f32>;
var<private> nodeVar714 : f32;
var<private> nodeVar715 : f32;
var<private> nodeVar716 : vec4<f32>;
var<private> nodeVar717 : vec2<f32>;
var<private> nodeVar718 : f32;
var<private> nodeVar719 : f32;
var<private> nodeVar720 : vec4<f32>;
var<private> nodeVar721 : f32;
var<private> nodeVar722 : f32;
var<private> nodeVar723 : f32;
var<private> nodeVar724 : f32;
var<private> nodeVar725 : f32;
var<private> nodeVar726 : f32;
var<private> nodeVar727 : f32;
var<private> nodeVar728 : f32;
var<private> nodeVar729 : f32;
var<private> nodeVar730 : f32;
var<private> nodeVar731 : f32;
var<private> nodeVar732 : f32;
var<private> nodeVar733 : f32;
var<private> nodeVar734 : f32;
var<private> nodeVar735 : f32;
var<private> nodeVar736 : f32;
var<private> nodeVar737 : f32;
var<private> nodeVar738 : f32;
var<private> nodeVar739 : f32;
var<private> nodeVar740 : f32;
var<private> nodeVar741 : f32;
var<private> nodeVar742 : f32;
var<private> nodeVar743 : f32;
var<private> nodeVar744 : f32;
var<private> nodeVar745 : f32;
var<private> nodeVar746 : f32;
var<private> nodeVar747 : f32;
var<private> nodeVar748 : f32;
var<private> nodeVar749 : f32;
var<private> nodeVar750 : f32;
var<private> nodeVar751 : f32;
var<private> nodeVar752 : f32;
var<private> nodeVar753 : f32;
var<private> nodeVar754 : f32;
var<private> nodeVar755 : f32;
var<private> nodeVar756 : f32;
var<private> nodeVar757 : f32;
var<private> nodeVar758 : f32;
var<private> nodeVar759 : f32;
var<private> nodeVar760 : f32;
var<private> nodeVar761 : f32;
var<private> nodeVar762 : f32;
var<private> nodeVar763 : f32;
var<private> nodeVar764 : f32;
var<private> nodeVar765 : f32;
var<private> nodeVar766 : f32;
var<private> nodeVar767 : f32;
var<private> nodeVar768 : f32;
var<private> nodeVar769 : f32;
var<private> nodeVar770 : f32;
var<private> nodeVar771 : f32;
var<private> nodeVar772 : f32;
var<private> nodeVar773 : f32;
var<private> nodeVar774 : f32;
var<private> nodeVar775 : vec2<f32>;
var<private> nodeVar776 : f32;
var<private> nodeVar777 : f32;
var<private> nodeVar778 : vec4<f32>;
var<private> nodeVar779 : f32;
var<private> nodeVar780 : vec2<f32>;
var<private> nodeVar781 : f32;
var<private> nodeVar782 : f32;
var<private> nodeVar783 : vec4<f32>;
var<private> nodeVar784 : f32;
var<private> nodeVar785 : vec2<f32>;
var<private> nodeVar786 : f32;
var<private> nodeVar787 : f32;
var<private> nodeVar788 : vec4<f32>;
var<private> nodeVar789 : f32;
var<private> nodeVar790 : vec2<f32>;
var<private> nodeVar791 : f32;
var<private> nodeVar792 : f32;
var<private> nodeVar793 : vec4<f32>;
var<private> nodeVar794 : f32;
var<private> nodeVar795 : vec2<f32>;
var<private> nodeVar796 : f32;
var<private> nodeVar797 : f32;
var<private> nodeVar798 : vec4<f32>;
var<private> nodeVar799 : f32;
var<private> nodeVar800 : vec2<f32>;
var<private> nodeVar801 : f32;
var<private> nodeVar802 : f32;
var<private> nodeVar803 : vec4<f32>;
var<private> nodeVar804 : f32;
var<private> nodeVar805 : vec2<f32>;
var<private> nodeVar806 : f32;
var<private> nodeVar807 : f32;
var<private> nodeVar808 : vec4<f32>;
var<private> nodeVar809 : f32;
var<private> nodeVar810 : vec2<f32>;
var<private> nodeVar811 : f32;
var<private> nodeVar812 : f32;
var<private> nodeVar813 : vec4<f32>;
var<private> nodeVar814 : f32;
var<private> nodeVar815 : vec2<f32>;
var<private> nodeVar816 : f32;
var<private> nodeVar817 : f32;
var<private> nodeVar818 : vec4<f32>;
var<private> nodeVar819 : f32;
var<private> nodeVar820 : vec2<f32>;
var<private> nodeVar821 : f32;
var<private> nodeVar822 : f32;
var<private> nodeVar823 : vec4<f32>;
var<private> nodeVar824 : f32;
var<private> nodeVar825 : vec2<f32>;
var<private> nodeVar826 : f32;
var<private> nodeVar827 : f32;
var<private> nodeVar828 : vec4<f32>;
var<private> nodeVar829 : f32;
var<private> nodeVar830 : vec2<f32>;
var<private> nodeVar831 : f32;
var<private> nodeVar832 : f32;
var<private> nodeVar833 : vec4<f32>;
var<private> nodeVar834 : f32;
var<private> nodeVar835 : vec2<f32>;
var<private> nodeVar836 : f32;
var<private> nodeVar837 : f32;
var<private> nodeVar838 : vec4<f32>;
var<private> nodeVar839 : f32;
var<private> nodeVar840 : vec2<f32>;
var<private> nodeVar841 : f32;
var<private> nodeVar842 : f32;
var<private> nodeVar843 : vec4<f32>;
var<private> nodeVar844 : f32;
var<private> nodeVar845 : vec2<f32>;
var<private> nodeVar846 : f32;
var<private> nodeVar847 : f32;
var<private> nodeVar848 : vec4<f32>;
var<private> nodeVar849 : f32;
var<private> nodeVar850 : vec2<f32>;
var<private> nodeVar851 : f32;
var<private> nodeVar852 : f32;
var<private> nodeVar853 : vec4<f32>;
var<private> nodeVar854 : f32;
var<private> nodeVar855 : vec2<f32>;
var<private> nodeVar856 : f32;
var<private> nodeVar857 : f32;
var<private> nodeVar858 : vec4<f32>;
var<private> nodeVar859 : f32;
var<private> nodeVar860 : vec2<f32>;
var<private> nodeVar861 : f32;
var<private> nodeVar862 : f32;
var<private> nodeVar863 : vec4<f32>;
var<private> nodeVar864 : f32;
var<private> nodeVar865 : vec2<f32>;
var<private> nodeVar866 : f32;
var<private> nodeVar867 : f32;
var<private> nodeVar868 : vec4<f32>;
var<private> nodeVar869 : f32;
var<private> nodeVar870 : vec2<f32>;
var<private> nodeVar871 : f32;
var<private> nodeVar872 : f32;
var<private> nodeVar873 : vec4<f32>;
var<private> nodeVar874 : f32;
var<private> nodeVar875 : vec2<f32>;
var<private> nodeVar876 : f32;
var<private> nodeVar877 : f32;
var<private> nodeVar878 : vec4<f32>;
var<private> nodeVar879 : f32;
var<private> nodeVar880 : vec2<f32>;
var<private> nodeVar881 : f32;
var<private> nodeVar882 : f32;
var<private> nodeVar883 : vec4<f32>;
var<private> nodeVar884 : vec4<f32>;
var<private> nodeVar885 : vec3<f32>;
var<private> nodeVar886 : f32;
var<private> nodeVar887 : vec3<f32>;
var<private> nodeVar888 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar889 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar2 = ( (1 * knobs.colorMode + 0) > 0.5 );

	if ( nodeVar2 ) {

		nodeVar1 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar3 = ( knobs.lineAngle * 0.017453292519943295 );
		nodeVar4 = vec2<f32>( cos( nodeVar3 ), sin( nodeVar3 ) );
		nodeVar5 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		nodeVar6 = vec2<f32>( ( nodeVar5.x * knobs.resolution.x ), ( nodeVar5.y * knobs.resolution.y ) );
		nodeVar7 = dot( nodeVar6, nodeVar4 );
		nodeVar8 = vec2<f32>( ( - sin( nodeVar3 ) ), cos( nodeVar3 ) );
		nodeVar9 = max( knobs.linePitch, 1.0 );
		nodeVar10 = ( ( ( knobs.time * knobs.scrollSpeed ) * nodeVar9 ) * 2.0 );
		nodeVar11 = ( ( ( ( floor( ( ( dot( nodeVar6, nodeVar8 ) + nodeVar10 ) / nodeVar9 ) ) + -5.0 ) * nodeVar9 ) + ( nodeVar9 * 0.5 ) ) - nodeVar10 );
		nodeVar12 = picture_read( vec2<f32>( ( ( ( nodeVar4.x * nodeVar7 ) + ( nodeVar8.x * nodeVar11 ) ) / knobs.resolution.x ), ( ( ( nodeVar4.y * nodeVar7 ) + ( nodeVar8.y * nodeVar11 ) ) / knobs.resolution.y ) ) );
		nodeVar1 = vec3<f32>( nodeVar12.x, nodeVar12.y, nodeVar12.z ).x;

	}

	nodeVar13 = ( knobs.lineThickness * 0.5 );
	nodeVar15 = ( (1 * knobs.invert + 0) > 0.5 );

	if ( nodeVar15 ) {

		nodeVar16 = ( knobs.lineAngle * 0.017453292519943295 );
		nodeVar17 = vec2<f32>( cos( nodeVar16 ), sin( nodeVar16 ) );
		nodeVar18 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		nodeVar19 = vec2<f32>( ( nodeVar18.x * knobs.resolution.x ), ( nodeVar18.y * knobs.resolution.y ) );
		nodeVar20 = dot( nodeVar19, nodeVar17 );
		nodeVar21 = vec2<f32>( ( - sin( nodeVar16 ) ), cos( nodeVar16 ) );
		nodeVar22 = max( knobs.linePitch, 1.0 );
		nodeVar23 = ( ( ( knobs.time * knobs.scrollSpeed ) * nodeVar22 ) * 2.0 );
		nodeVar24 = ( ( ( ( floor( ( ( dot( nodeVar19, nodeVar21 ) + nodeVar23 ) / nodeVar22 ) ) + -5.0 ) * nodeVar22 ) + ( nodeVar22 * 0.5 ) ) - nodeVar23 );
		nodeVar25 = picture_read( vec2<f32>( ( ( ( nodeVar17.x * nodeVar20 ) + ( nodeVar21.x * nodeVar24 ) ) / knobs.resolution.x ), ( ( ( nodeVar17.y * nodeVar20 ) + ( nodeVar21.y * nodeVar24 ) ) / knobs.resolution.y ) ) );
		nodeVar14 = ( 1.0 - dot( vec3<f32>( nodeVar25.x, nodeVar25.y, nodeVar25.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar26 = ( knobs.lineAngle * 0.017453292519943295 );
		nodeVar27 = vec2<f32>( cos( nodeVar26 ), sin( nodeVar26 ) );
		nodeVar28 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		nodeVar29 = vec2<f32>( ( nodeVar28.x * knobs.resolution.x ), ( nodeVar28.y * knobs.resolution.y ) );
		nodeVar30 = dot( nodeVar29, nodeVar27 );
		nodeVar31 = vec2<f32>( ( - sin( nodeVar26 ) ), cos( nodeVar26 ) );
		nodeVar32 = max( knobs.linePitch, 1.0 );
		nodeVar33 = ( ( ( knobs.time * knobs.scrollSpeed ) * nodeVar32 ) * 2.0 );
		nodeVar34 = ( ( ( ( floor( ( ( dot( nodeVar29, nodeVar31 ) + nodeVar33 ) / nodeVar32 ) ) + -5.0 ) * nodeVar32 ) + ( nodeVar32 * 0.5 ) ) - nodeVar33 );
		nodeVar35 = picture_read( vec2<f32>( ( ( ( nodeVar27.x * nodeVar30 ) + ( nodeVar31.x * nodeVar34 ) ) / knobs.resolution.x ), ( ( ( nodeVar27.y * nodeVar30 ) + ( nodeVar31.y * nodeVar34 ) ) / knobs.resolution.y ) ) );
		nodeVar14 = dot( vec3<f32>( nodeVar35.x, nodeVar35.y, nodeVar35.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar36 = max( ( knobs.signalWhitePoint - knobs.signalBlackPoint ), 0.001 );
	nodeVar37 = ( 1.0 / knobs.signalGamma );
	nodeVar38 = pow( clamp( ( ( nodeVar14 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar39 = ( nodeVar13 + ( nodeVar38 * 0.5 ) );
	nodeVar40 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar41 = vec2<f32>( ( nodeVar40.x * knobs.resolution.x ), ( nodeVar40.y * knobs.resolution.y ) );
	nodeVar42 = ( knobs.lineAngle * 0.017453292519943295 );
	nodeVar43 = vec2<f32>( ( - sin( nodeVar42 ) ), cos( nodeVar42 ) );
	nodeVar44 = max( knobs.linePitch, 1.0 );
	nodeVar45 = ( ( ( knobs.time * knobs.scrollSpeed ) * nodeVar44 ) * 2.0 );
	nodeVar46 = ( dot( nodeVar41, nodeVar43 ) + nodeVar45 );
	nodeVar47 = floor( ( nodeVar46 / nodeVar44 ) );
	nodeVar48 = ( nodeVar47 + -5.0 );
	nodeVar49 = ( ( nodeVar48 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );
	nodeVar51 = ( knobs.noiseMode > 1.5 );

	if ( nodeVar51 ) {

		nodeVar52 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar53 = floor( nodeVar52 );
		nodeVar54 = ( ( nodeVar48 * 0.37 ) + 17.3 );
		nodeVar55 = floor( nodeVar54 );
		nodeVar56 = fract( nodeVar52 );
		nodeVar57 = ( ( nodeVar56 * nodeVar56 ) * ( 3.0 - ( nodeVar56 * 2.0 ) ) );
		nodeVar58 = fract( nodeVar54 );
		nodeVar59 = ( nodeVar52 * 2.1 );
		nodeVar60 = floor( nodeVar59 );
		nodeVar61 = ( nodeVar54 * 2.1 );
		nodeVar62 = floor( nodeVar61 );
		nodeVar63 = fract( nodeVar59 );
		nodeVar64 = ( ( nodeVar63 * nodeVar63 ) * ( 3.0 - ( nodeVar63 * 2.0 ) ) );
		nodeVar65 = fract( nodeVar61 );
		nodeVar66 = ( nodeVar52 * 4.3 );
		nodeVar67 = floor( nodeVar66 );
		nodeVar68 = ( nodeVar54 * 4.3 );
		nodeVar69 = floor( nodeVar68 );
		nodeVar70 = fract( nodeVar66 );
		nodeVar71 = ( ( nodeVar70 * nodeVar70 ) * ( 3.0 - ( nodeVar70 * 2.0 ) ) );
		nodeVar72 = fract( nodeVar68 );
		nodeVar50 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar53 * 127.1 ) + ( nodeVar55 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar53 + 1.0 ) * 127.1 ) + ( nodeVar55 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar57 ), mix( fract( ( sin( ( ( nodeVar53 * 127.1 ) + ( ( nodeVar55 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar53 + 1.0 ) * 127.1 ) + ( ( nodeVar55 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar57 ), ( ( nodeVar58 * nodeVar58 ) * ( 3.0 - ( nodeVar58 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar60 * 127.1 ) + ( nodeVar62 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar60 + 1.0 ) * 127.1 ) + ( nodeVar62 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar64 ), mix( fract( ( sin( ( ( nodeVar60 * 127.1 ) + ( ( nodeVar62 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar60 + 1.0 ) * 127.1 ) + ( ( nodeVar62 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar64 ), ( ( nodeVar65 * nodeVar65 ) * ( 3.0 - ( nodeVar65 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar67 * 127.1 ) + ( nodeVar69 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar67 + 1.0 ) * 127.1 ) + ( nodeVar69 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar71 ), mix( fract( ( sin( ( ( nodeVar67 * 127.1 ) + ( ( nodeVar69 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar67 + 1.0 ) * 127.1 ) + ( ( nodeVar69 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar71 ), ( ( nodeVar72 * nodeVar72 ) * ( 3.0 - ( nodeVar72 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar74 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar75 = floor( nodeVar74 );
			nodeVar76 = ( ( nodeVar48 * 0.37 ) + 17.3 );
			nodeVar77 = floor( nodeVar76 );
			nodeVar78 = fract( nodeVar74 );
			nodeVar79 = ( ( nodeVar78 * nodeVar78 ) * ( 3.0 - ( nodeVar78 * 2.0 ) ) );
			nodeVar80 = fract( nodeVar76 );
			nodeVar81 = ( nodeVar74 * 2.1 );
			nodeVar82 = floor( nodeVar81 );
			nodeVar83 = ( nodeVar76 * 2.1 );
			nodeVar84 = floor( nodeVar83 );
			nodeVar85 = fract( nodeVar81 );
			nodeVar86 = ( ( nodeVar85 * nodeVar85 ) * ( 3.0 - ( nodeVar85 * 2.0 ) ) );
			nodeVar87 = fract( nodeVar83 );
			nodeVar88 = ( nodeVar74 * 4.3 );
			nodeVar89 = floor( nodeVar88 );
			nodeVar90 = ( nodeVar76 * 4.3 );
			nodeVar91 = floor( nodeVar90 );
			nodeVar92 = fract( nodeVar88 );
			nodeVar93 = ( ( nodeVar92 * nodeVar92 ) * ( 3.0 - ( nodeVar92 * 2.0 ) ) );
			nodeVar94 = fract( nodeVar90 );
			nodeVar73 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar75 * 127.1 ) + ( nodeVar77 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar75 + 1.0 ) * 127.1 ) + ( nodeVar77 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar79 ), mix( fract( ( sin( ( ( nodeVar75 * 127.1 ) + ( ( nodeVar77 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar75 + 1.0 ) * 127.1 ) + ( ( nodeVar77 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar79 ), ( ( nodeVar80 * nodeVar80 ) * ( 3.0 - ( nodeVar80 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar82 * 127.1 ) + ( nodeVar84 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar82 + 1.0 ) * 127.1 ) + ( nodeVar84 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar86 ), mix( fract( ( sin( ( ( nodeVar82 * 127.1 ) + ( ( nodeVar84 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar82 + 1.0 ) * 127.1 ) + ( ( nodeVar84 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar86 ), ( ( nodeVar87 * nodeVar87 ) * ( 3.0 - ( nodeVar87 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar89 * 127.1 ) + ( nodeVar91 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar89 + 1.0 ) * 127.1 ) + ( nodeVar91 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar93 ), mix( fract( ( sin( ( ( nodeVar89 * 127.1 ) + ( ( nodeVar91 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar89 + 1.0 ) * 127.1 ) + ( ( nodeVar91 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar93 ), ( ( nodeVar94 * nodeVar94 ) * ( 3.0 - ( nodeVar94 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar95 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar73 = ( ( ( sin( ( ( nodeVar95 * 0.004 ) + ( nodeVar48 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar95 * 0.011 ) + ( nodeVar48 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar95 * 0.0023 ) + ( nodeVar48 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar50 = nodeVar73;

	}

	nodeVar96 = abs( ( nodeVar46 - ( nodeVar49 + ( ( ( nodeVar38 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar50 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar97 = ( 1.0 - knobs.presenceThreshold );
	nodeVar98 = max( ( knobs.presenceSoftness * 0.5 ), 0.001 );
	nodeVar99 = ( nodeVar97 - nodeVar98 );
	nodeVar100 = ( nodeVar97 + nodeVar98 );
	nodeVar101 = smoothstep( nodeVar99, nodeVar100, nodeVar38 );
	nodeVar102 = ( nodeVar39 + ( ( nodeVar38 * nodeVar44 ) * 0.08 ) );
	nodeVar103 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar39 - 1.0 ) ), ( nodeVar39 + 1.0 ), nodeVar96 ) ) * nodeVar101 ) * nodeVar38 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar102 - 2.0 ) ), ( nodeVar102 + 2.0 ), nodeVar96 ) ) * nodeVar101 ) * ( nodeVar38 * nodeVar38 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar104 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar105 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar106 = dot( nodeVar41, nodeVar105 );
		nodeVar107 = ( ( ( ( nodeVar47 + -4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar108 = picture_read( vec2<f32>( ( ( ( nodeVar105.x * nodeVar106 ) + ( nodeVar43.x * nodeVar107 ) ) / knobs.resolution.x ), ( ( ( nodeVar105.y * nodeVar106 ) + ( nodeVar43.y * nodeVar107 ) ) / knobs.resolution.y ) ) );
		nodeVar104 = vec3<f32>( nodeVar108.x, nodeVar108.y, nodeVar108.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar110 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar111 = dot( nodeVar41, nodeVar110 );
		nodeVar112 = ( ( ( ( nodeVar47 + -4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar113 = picture_read( vec2<f32>( ( ( ( nodeVar110.x * nodeVar111 ) + ( nodeVar43.x * nodeVar112 ) ) / knobs.resolution.x ), ( ( ( nodeVar110.y * nodeVar111 ) + ( nodeVar43.y * nodeVar112 ) ) / knobs.resolution.y ) ) );
		nodeVar109 = ( 1.0 - dot( vec3<f32>( nodeVar113.x, nodeVar113.y, nodeVar113.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar114 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar115 = dot( nodeVar41, nodeVar114 );
		nodeVar116 = ( ( ( ( nodeVar47 + -4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar117 = picture_read( vec2<f32>( ( ( ( nodeVar114.x * nodeVar115 ) + ( nodeVar43.x * nodeVar116 ) ) / knobs.resolution.x ), ( ( ( nodeVar114.y * nodeVar115 ) + ( nodeVar43.y * nodeVar116 ) ) / knobs.resolution.y ) ) );
		nodeVar109 = dot( vec3<f32>( nodeVar117.x, nodeVar117.y, nodeVar117.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar118 = pow( clamp( ( ( nodeVar109 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar119 = ( nodeVar13 + ( nodeVar118 * 0.5 ) );
	nodeVar120 = ( nodeVar47 + -4.0 );
	nodeVar121 = ( ( nodeVar120 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar123 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar124 = floor( nodeVar123 );
		nodeVar125 = ( ( nodeVar120 * 0.37 ) + 17.3 );
		nodeVar126 = floor( nodeVar125 );
		nodeVar127 = fract( nodeVar123 );
		nodeVar128 = ( ( nodeVar127 * nodeVar127 ) * ( 3.0 - ( nodeVar127 * 2.0 ) ) );
		nodeVar129 = fract( nodeVar125 );
		nodeVar130 = ( nodeVar123 * 2.1 );
		nodeVar131 = floor( nodeVar130 );
		nodeVar132 = ( nodeVar125 * 2.1 );
		nodeVar133 = floor( nodeVar132 );
		nodeVar134 = fract( nodeVar130 );
		nodeVar135 = ( ( nodeVar134 * nodeVar134 ) * ( 3.0 - ( nodeVar134 * 2.0 ) ) );
		nodeVar136 = fract( nodeVar132 );
		nodeVar137 = ( nodeVar123 * 4.3 );
		nodeVar138 = floor( nodeVar137 );
		nodeVar139 = ( nodeVar125 * 4.3 );
		nodeVar140 = floor( nodeVar139 );
		nodeVar141 = fract( nodeVar137 );
		nodeVar142 = ( ( nodeVar141 * nodeVar141 ) * ( 3.0 - ( nodeVar141 * 2.0 ) ) );
		nodeVar143 = fract( nodeVar139 );
		nodeVar122 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar124 * 127.1 ) + ( nodeVar126 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar124 + 1.0 ) * 127.1 ) + ( nodeVar126 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar128 ), mix( fract( ( sin( ( ( nodeVar124 * 127.1 ) + ( ( nodeVar126 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar124 + 1.0 ) * 127.1 ) + ( ( nodeVar126 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar128 ), ( ( nodeVar129 * nodeVar129 ) * ( 3.0 - ( nodeVar129 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar131 * 127.1 ) + ( nodeVar133 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar131 + 1.0 ) * 127.1 ) + ( nodeVar133 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar135 ), mix( fract( ( sin( ( ( nodeVar131 * 127.1 ) + ( ( nodeVar133 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar131 + 1.0 ) * 127.1 ) + ( ( nodeVar133 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar135 ), ( ( nodeVar136 * nodeVar136 ) * ( 3.0 - ( nodeVar136 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar138 * 127.1 ) + ( nodeVar140 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar138 + 1.0 ) * 127.1 ) + ( nodeVar140 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar142 ), mix( fract( ( sin( ( ( nodeVar138 * 127.1 ) + ( ( nodeVar140 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar138 + 1.0 ) * 127.1 ) + ( ( nodeVar140 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar142 ), ( ( nodeVar143 * nodeVar143 ) * ( 3.0 - ( nodeVar143 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar145 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar146 = floor( nodeVar145 );
			nodeVar147 = ( ( nodeVar120 * 0.37 ) + 17.3 );
			nodeVar148 = floor( nodeVar147 );
			nodeVar149 = fract( nodeVar145 );
			nodeVar150 = ( ( nodeVar149 * nodeVar149 ) * ( 3.0 - ( nodeVar149 * 2.0 ) ) );
			nodeVar151 = fract( nodeVar147 );
			nodeVar152 = ( nodeVar145 * 2.1 );
			nodeVar153 = floor( nodeVar152 );
			nodeVar154 = ( nodeVar147 * 2.1 );
			nodeVar155 = floor( nodeVar154 );
			nodeVar156 = fract( nodeVar152 );
			nodeVar157 = ( ( nodeVar156 * nodeVar156 ) * ( 3.0 - ( nodeVar156 * 2.0 ) ) );
			nodeVar158 = fract( nodeVar154 );
			nodeVar159 = ( nodeVar145 * 4.3 );
			nodeVar160 = floor( nodeVar159 );
			nodeVar161 = ( nodeVar147 * 4.3 );
			nodeVar162 = floor( nodeVar161 );
			nodeVar163 = fract( nodeVar159 );
			nodeVar164 = ( ( nodeVar163 * nodeVar163 ) * ( 3.0 - ( nodeVar163 * 2.0 ) ) );
			nodeVar165 = fract( nodeVar161 );
			nodeVar144 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar146 * 127.1 ) + ( nodeVar148 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar146 + 1.0 ) * 127.1 ) + ( nodeVar148 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar150 ), mix( fract( ( sin( ( ( nodeVar146 * 127.1 ) + ( ( nodeVar148 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar146 + 1.0 ) * 127.1 ) + ( ( nodeVar148 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar150 ), ( ( nodeVar151 * nodeVar151 ) * ( 3.0 - ( nodeVar151 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar153 * 127.1 ) + ( nodeVar155 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar153 + 1.0 ) * 127.1 ) + ( nodeVar155 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar157 ), mix( fract( ( sin( ( ( nodeVar153 * 127.1 ) + ( ( nodeVar155 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar153 + 1.0 ) * 127.1 ) + ( ( nodeVar155 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar157 ), ( ( nodeVar158 * nodeVar158 ) * ( 3.0 - ( nodeVar158 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar160 * 127.1 ) + ( nodeVar162 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar160 + 1.0 ) * 127.1 ) + ( nodeVar162 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar164 ), mix( fract( ( sin( ( ( nodeVar160 * 127.1 ) + ( ( nodeVar162 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar160 + 1.0 ) * 127.1 ) + ( ( nodeVar162 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar164 ), ( ( nodeVar165 * nodeVar165 ) * ( 3.0 - ( nodeVar165 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar166 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar144 = ( ( ( sin( ( ( nodeVar166 * 0.004 ) + ( nodeVar120 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar166 * 0.011 ) + ( nodeVar120 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar166 * 0.0023 ) + ( nodeVar120 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar122 = nodeVar144;

	}

	nodeVar167 = abs( ( nodeVar46 - ( nodeVar121 + ( ( ( nodeVar118 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar122 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar168 = smoothstep( nodeVar99, nodeVar100, nodeVar118 );
	nodeVar169 = ( nodeVar119 + ( ( nodeVar118 * nodeVar44 ) * 0.08 ) );
	nodeVar170 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar119 - 1.0 ) ), ( nodeVar119 + 1.0 ), nodeVar167 ) ) * nodeVar168 ) * nodeVar118 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar169 - 2.0 ) ), ( nodeVar169 + 2.0 ), nodeVar167 ) ) * nodeVar168 ) * ( nodeVar118 * nodeVar118 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar171 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar172 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar173 = dot( nodeVar41, nodeVar172 );
		nodeVar174 = ( ( ( ( nodeVar47 + -3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar175 = picture_read( vec2<f32>( ( ( ( nodeVar172.x * nodeVar173 ) + ( nodeVar43.x * nodeVar174 ) ) / knobs.resolution.x ), ( ( ( nodeVar172.y * nodeVar173 ) + ( nodeVar43.y * nodeVar174 ) ) / knobs.resolution.y ) ) );
		nodeVar171 = vec3<f32>( nodeVar175.x, nodeVar175.y, nodeVar175.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar177 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar178 = dot( nodeVar41, nodeVar177 );
		nodeVar179 = ( ( ( ( nodeVar47 + -3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar180 = picture_read( vec2<f32>( ( ( ( nodeVar177.x * nodeVar178 ) + ( nodeVar43.x * nodeVar179 ) ) / knobs.resolution.x ), ( ( ( nodeVar177.y * nodeVar178 ) + ( nodeVar43.y * nodeVar179 ) ) / knobs.resolution.y ) ) );
		nodeVar176 = ( 1.0 - dot( vec3<f32>( nodeVar180.x, nodeVar180.y, nodeVar180.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar181 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar182 = dot( nodeVar41, nodeVar181 );
		nodeVar183 = ( ( ( ( nodeVar47 + -3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar184 = picture_read( vec2<f32>( ( ( ( nodeVar181.x * nodeVar182 ) + ( nodeVar43.x * nodeVar183 ) ) / knobs.resolution.x ), ( ( ( nodeVar181.y * nodeVar182 ) + ( nodeVar43.y * nodeVar183 ) ) / knobs.resolution.y ) ) );
		nodeVar176 = dot( vec3<f32>( nodeVar184.x, nodeVar184.y, nodeVar184.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar185 = pow( clamp( ( ( nodeVar176 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar186 = ( nodeVar13 + ( nodeVar185 * 0.5 ) );
	nodeVar187 = ( nodeVar47 + -3.0 );
	nodeVar188 = ( ( nodeVar187 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar190 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar191 = floor( nodeVar190 );
		nodeVar192 = ( ( nodeVar187 * 0.37 ) + 17.3 );
		nodeVar193 = floor( nodeVar192 );
		nodeVar194 = fract( nodeVar190 );
		nodeVar195 = ( ( nodeVar194 * nodeVar194 ) * ( 3.0 - ( nodeVar194 * 2.0 ) ) );
		nodeVar196 = fract( nodeVar192 );
		nodeVar197 = ( nodeVar190 * 2.1 );
		nodeVar198 = floor( nodeVar197 );
		nodeVar199 = ( nodeVar192 * 2.1 );
		nodeVar200 = floor( nodeVar199 );
		nodeVar201 = fract( nodeVar197 );
		nodeVar202 = ( ( nodeVar201 * nodeVar201 ) * ( 3.0 - ( nodeVar201 * 2.0 ) ) );
		nodeVar203 = fract( nodeVar199 );
		nodeVar204 = ( nodeVar190 * 4.3 );
		nodeVar205 = floor( nodeVar204 );
		nodeVar206 = ( nodeVar192 * 4.3 );
		nodeVar207 = floor( nodeVar206 );
		nodeVar208 = fract( nodeVar204 );
		nodeVar209 = ( ( nodeVar208 * nodeVar208 ) * ( 3.0 - ( nodeVar208 * 2.0 ) ) );
		nodeVar210 = fract( nodeVar206 );
		nodeVar189 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar191 * 127.1 ) + ( nodeVar193 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar191 + 1.0 ) * 127.1 ) + ( nodeVar193 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar195 ), mix( fract( ( sin( ( ( nodeVar191 * 127.1 ) + ( ( nodeVar193 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar191 + 1.0 ) * 127.1 ) + ( ( nodeVar193 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar195 ), ( ( nodeVar196 * nodeVar196 ) * ( 3.0 - ( nodeVar196 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar198 * 127.1 ) + ( nodeVar200 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar198 + 1.0 ) * 127.1 ) + ( nodeVar200 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar202 ), mix( fract( ( sin( ( ( nodeVar198 * 127.1 ) + ( ( nodeVar200 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar198 + 1.0 ) * 127.1 ) + ( ( nodeVar200 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar202 ), ( ( nodeVar203 * nodeVar203 ) * ( 3.0 - ( nodeVar203 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar205 * 127.1 ) + ( nodeVar207 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar205 + 1.0 ) * 127.1 ) + ( nodeVar207 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar209 ), mix( fract( ( sin( ( ( nodeVar205 * 127.1 ) + ( ( nodeVar207 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar205 + 1.0 ) * 127.1 ) + ( ( nodeVar207 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar209 ), ( ( nodeVar210 * nodeVar210 ) * ( 3.0 - ( nodeVar210 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar212 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar213 = floor( nodeVar212 );
			nodeVar214 = ( ( nodeVar187 * 0.37 ) + 17.3 );
			nodeVar215 = floor( nodeVar214 );
			nodeVar216 = fract( nodeVar212 );
			nodeVar217 = ( ( nodeVar216 * nodeVar216 ) * ( 3.0 - ( nodeVar216 * 2.0 ) ) );
			nodeVar218 = fract( nodeVar214 );
			nodeVar219 = ( nodeVar212 * 2.1 );
			nodeVar220 = floor( nodeVar219 );
			nodeVar221 = ( nodeVar214 * 2.1 );
			nodeVar222 = floor( nodeVar221 );
			nodeVar223 = fract( nodeVar219 );
			nodeVar224 = ( ( nodeVar223 * nodeVar223 ) * ( 3.0 - ( nodeVar223 * 2.0 ) ) );
			nodeVar225 = fract( nodeVar221 );
			nodeVar226 = ( nodeVar212 * 4.3 );
			nodeVar227 = floor( nodeVar226 );
			nodeVar228 = ( nodeVar214 * 4.3 );
			nodeVar229 = floor( nodeVar228 );
			nodeVar230 = fract( nodeVar226 );
			nodeVar231 = ( ( nodeVar230 * nodeVar230 ) * ( 3.0 - ( nodeVar230 * 2.0 ) ) );
			nodeVar232 = fract( nodeVar228 );
			nodeVar211 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar213 * 127.1 ) + ( nodeVar215 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar213 + 1.0 ) * 127.1 ) + ( nodeVar215 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar217 ), mix( fract( ( sin( ( ( nodeVar213 * 127.1 ) + ( ( nodeVar215 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar213 + 1.0 ) * 127.1 ) + ( ( nodeVar215 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar217 ), ( ( nodeVar218 * nodeVar218 ) * ( 3.0 - ( nodeVar218 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar220 * 127.1 ) + ( nodeVar222 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar220 + 1.0 ) * 127.1 ) + ( nodeVar222 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar224 ), mix( fract( ( sin( ( ( nodeVar220 * 127.1 ) + ( ( nodeVar222 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar220 + 1.0 ) * 127.1 ) + ( ( nodeVar222 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar224 ), ( ( nodeVar225 * nodeVar225 ) * ( 3.0 - ( nodeVar225 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar227 * 127.1 ) + ( nodeVar229 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar227 + 1.0 ) * 127.1 ) + ( nodeVar229 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar231 ), mix( fract( ( sin( ( ( nodeVar227 * 127.1 ) + ( ( nodeVar229 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar227 + 1.0 ) * 127.1 ) + ( ( nodeVar229 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar231 ), ( ( nodeVar232 * nodeVar232 ) * ( 3.0 - ( nodeVar232 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar233 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar211 = ( ( ( sin( ( ( nodeVar233 * 0.004 ) + ( nodeVar187 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar233 * 0.011 ) + ( nodeVar187 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar233 * 0.0023 ) + ( nodeVar187 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar189 = nodeVar211;

	}

	nodeVar234 = abs( ( nodeVar46 - ( nodeVar188 + ( ( ( nodeVar185 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar189 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar235 = smoothstep( nodeVar99, nodeVar100, nodeVar185 );
	nodeVar236 = ( nodeVar186 + ( ( nodeVar185 * nodeVar44 ) * 0.08 ) );
	nodeVar237 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar186 - 1.0 ) ), ( nodeVar186 + 1.0 ), nodeVar234 ) ) * nodeVar235 ) * nodeVar185 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar236 - 2.0 ) ), ( nodeVar236 + 2.0 ), nodeVar234 ) ) * nodeVar235 ) * ( nodeVar185 * nodeVar185 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar238 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar239 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar240 = dot( nodeVar41, nodeVar239 );
		nodeVar241 = ( ( ( ( nodeVar47 + -2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar242 = picture_read( vec2<f32>( ( ( ( nodeVar239.x * nodeVar240 ) + ( nodeVar43.x * nodeVar241 ) ) / knobs.resolution.x ), ( ( ( nodeVar239.y * nodeVar240 ) + ( nodeVar43.y * nodeVar241 ) ) / knobs.resolution.y ) ) );
		nodeVar238 = vec3<f32>( nodeVar242.x, nodeVar242.y, nodeVar242.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar244 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar245 = dot( nodeVar41, nodeVar244 );
		nodeVar246 = ( ( ( ( nodeVar47 + -2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar247 = picture_read( vec2<f32>( ( ( ( nodeVar244.x * nodeVar245 ) + ( nodeVar43.x * nodeVar246 ) ) / knobs.resolution.x ), ( ( ( nodeVar244.y * nodeVar245 ) + ( nodeVar43.y * nodeVar246 ) ) / knobs.resolution.y ) ) );
		nodeVar243 = ( 1.0 - dot( vec3<f32>( nodeVar247.x, nodeVar247.y, nodeVar247.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar248 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar249 = dot( nodeVar41, nodeVar248 );
		nodeVar250 = ( ( ( ( nodeVar47 + -2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar251 = picture_read( vec2<f32>( ( ( ( nodeVar248.x * nodeVar249 ) + ( nodeVar43.x * nodeVar250 ) ) / knobs.resolution.x ), ( ( ( nodeVar248.y * nodeVar249 ) + ( nodeVar43.y * nodeVar250 ) ) / knobs.resolution.y ) ) );
		nodeVar243 = dot( vec3<f32>( nodeVar251.x, nodeVar251.y, nodeVar251.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar252 = pow( clamp( ( ( nodeVar243 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar253 = ( nodeVar13 + ( nodeVar252 * 0.5 ) );
	nodeVar254 = ( nodeVar47 + -2.0 );
	nodeVar255 = ( ( nodeVar254 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar257 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar258 = floor( nodeVar257 );
		nodeVar259 = ( ( nodeVar254 * 0.37 ) + 17.3 );
		nodeVar260 = floor( nodeVar259 );
		nodeVar261 = fract( nodeVar257 );
		nodeVar262 = ( ( nodeVar261 * nodeVar261 ) * ( 3.0 - ( nodeVar261 * 2.0 ) ) );
		nodeVar263 = fract( nodeVar259 );
		nodeVar264 = ( nodeVar257 * 2.1 );
		nodeVar265 = floor( nodeVar264 );
		nodeVar266 = ( nodeVar259 * 2.1 );
		nodeVar267 = floor( nodeVar266 );
		nodeVar268 = fract( nodeVar264 );
		nodeVar269 = ( ( nodeVar268 * nodeVar268 ) * ( 3.0 - ( nodeVar268 * 2.0 ) ) );
		nodeVar270 = fract( nodeVar266 );
		nodeVar271 = ( nodeVar257 * 4.3 );
		nodeVar272 = floor( nodeVar271 );
		nodeVar273 = ( nodeVar259 * 4.3 );
		nodeVar274 = floor( nodeVar273 );
		nodeVar275 = fract( nodeVar271 );
		nodeVar276 = ( ( nodeVar275 * nodeVar275 ) * ( 3.0 - ( nodeVar275 * 2.0 ) ) );
		nodeVar277 = fract( nodeVar273 );
		nodeVar256 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar258 * 127.1 ) + ( nodeVar260 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar258 + 1.0 ) * 127.1 ) + ( nodeVar260 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar262 ), mix( fract( ( sin( ( ( nodeVar258 * 127.1 ) + ( ( nodeVar260 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar258 + 1.0 ) * 127.1 ) + ( ( nodeVar260 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar262 ), ( ( nodeVar263 * nodeVar263 ) * ( 3.0 - ( nodeVar263 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar265 * 127.1 ) + ( nodeVar267 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar265 + 1.0 ) * 127.1 ) + ( nodeVar267 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar269 ), mix( fract( ( sin( ( ( nodeVar265 * 127.1 ) + ( ( nodeVar267 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar265 + 1.0 ) * 127.1 ) + ( ( nodeVar267 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar269 ), ( ( nodeVar270 * nodeVar270 ) * ( 3.0 - ( nodeVar270 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar272 * 127.1 ) + ( nodeVar274 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar272 + 1.0 ) * 127.1 ) + ( nodeVar274 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar276 ), mix( fract( ( sin( ( ( nodeVar272 * 127.1 ) + ( ( nodeVar274 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar272 + 1.0 ) * 127.1 ) + ( ( nodeVar274 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar276 ), ( ( nodeVar277 * nodeVar277 ) * ( 3.0 - ( nodeVar277 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar279 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar280 = floor( nodeVar279 );
			nodeVar281 = ( ( nodeVar254 * 0.37 ) + 17.3 );
			nodeVar282 = floor( nodeVar281 );
			nodeVar283 = fract( nodeVar279 );
			nodeVar284 = ( ( nodeVar283 * nodeVar283 ) * ( 3.0 - ( nodeVar283 * 2.0 ) ) );
			nodeVar285 = fract( nodeVar281 );
			nodeVar286 = ( nodeVar279 * 2.1 );
			nodeVar287 = floor( nodeVar286 );
			nodeVar288 = ( nodeVar281 * 2.1 );
			nodeVar289 = floor( nodeVar288 );
			nodeVar290 = fract( nodeVar286 );
			nodeVar291 = ( ( nodeVar290 * nodeVar290 ) * ( 3.0 - ( nodeVar290 * 2.0 ) ) );
			nodeVar292 = fract( nodeVar288 );
			nodeVar293 = ( nodeVar279 * 4.3 );
			nodeVar294 = floor( nodeVar293 );
			nodeVar295 = ( nodeVar281 * 4.3 );
			nodeVar296 = floor( nodeVar295 );
			nodeVar297 = fract( nodeVar293 );
			nodeVar298 = ( ( nodeVar297 * nodeVar297 ) * ( 3.0 - ( nodeVar297 * 2.0 ) ) );
			nodeVar299 = fract( nodeVar295 );
			nodeVar278 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar280 * 127.1 ) + ( nodeVar282 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar280 + 1.0 ) * 127.1 ) + ( nodeVar282 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar284 ), mix( fract( ( sin( ( ( nodeVar280 * 127.1 ) + ( ( nodeVar282 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar280 + 1.0 ) * 127.1 ) + ( ( nodeVar282 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar284 ), ( ( nodeVar285 * nodeVar285 ) * ( 3.0 - ( nodeVar285 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar287 * 127.1 ) + ( nodeVar289 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar287 + 1.0 ) * 127.1 ) + ( nodeVar289 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar291 ), mix( fract( ( sin( ( ( nodeVar287 * 127.1 ) + ( ( nodeVar289 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar287 + 1.0 ) * 127.1 ) + ( ( nodeVar289 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar291 ), ( ( nodeVar292 * nodeVar292 ) * ( 3.0 - ( nodeVar292 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar294 * 127.1 ) + ( nodeVar296 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar294 + 1.0 ) * 127.1 ) + ( nodeVar296 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar298 ), mix( fract( ( sin( ( ( nodeVar294 * 127.1 ) + ( ( nodeVar296 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar294 + 1.0 ) * 127.1 ) + ( ( nodeVar296 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar298 ), ( ( nodeVar299 * nodeVar299 ) * ( 3.0 - ( nodeVar299 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar300 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar278 = ( ( ( sin( ( ( nodeVar300 * 0.004 ) + ( nodeVar254 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar300 * 0.011 ) + ( nodeVar254 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar300 * 0.0023 ) + ( nodeVar254 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar256 = nodeVar278;

	}

	nodeVar301 = abs( ( nodeVar46 - ( nodeVar255 + ( ( ( nodeVar252 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar256 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar302 = smoothstep( nodeVar99, nodeVar100, nodeVar252 );
	nodeVar303 = ( nodeVar253 + ( ( nodeVar252 * nodeVar44 ) * 0.08 ) );
	nodeVar304 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar253 - 1.0 ) ), ( nodeVar253 + 1.0 ), nodeVar301 ) ) * nodeVar302 ) * nodeVar252 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar303 - 2.0 ) ), ( nodeVar303 + 2.0 ), nodeVar301 ) ) * nodeVar302 ) * ( nodeVar252 * nodeVar252 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar305 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar306 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar307 = dot( nodeVar41, nodeVar306 );
		nodeVar308 = ( ( ( ( nodeVar47 + -1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar309 = picture_read( vec2<f32>( ( ( ( nodeVar306.x * nodeVar307 ) + ( nodeVar43.x * nodeVar308 ) ) / knobs.resolution.x ), ( ( ( nodeVar306.y * nodeVar307 ) + ( nodeVar43.y * nodeVar308 ) ) / knobs.resolution.y ) ) );
		nodeVar305 = vec3<f32>( nodeVar309.x, nodeVar309.y, nodeVar309.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar311 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar312 = dot( nodeVar41, nodeVar311 );
		nodeVar313 = ( ( ( ( nodeVar47 + -1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar314 = picture_read( vec2<f32>( ( ( ( nodeVar311.x * nodeVar312 ) + ( nodeVar43.x * nodeVar313 ) ) / knobs.resolution.x ), ( ( ( nodeVar311.y * nodeVar312 ) + ( nodeVar43.y * nodeVar313 ) ) / knobs.resolution.y ) ) );
		nodeVar310 = ( 1.0 - dot( vec3<f32>( nodeVar314.x, nodeVar314.y, nodeVar314.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar315 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar316 = dot( nodeVar41, nodeVar315 );
		nodeVar317 = ( ( ( ( nodeVar47 + -1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar318 = picture_read( vec2<f32>( ( ( ( nodeVar315.x * nodeVar316 ) + ( nodeVar43.x * nodeVar317 ) ) / knobs.resolution.x ), ( ( ( nodeVar315.y * nodeVar316 ) + ( nodeVar43.y * nodeVar317 ) ) / knobs.resolution.y ) ) );
		nodeVar310 = dot( vec3<f32>( nodeVar318.x, nodeVar318.y, nodeVar318.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar319 = pow( clamp( ( ( nodeVar310 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar320 = ( nodeVar13 + ( nodeVar319 * 0.5 ) );
	nodeVar321 = ( nodeVar47 + -1.0 );
	nodeVar322 = ( ( nodeVar321 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar324 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar325 = floor( nodeVar324 );
		nodeVar326 = ( ( nodeVar321 * 0.37 ) + 17.3 );
		nodeVar327 = floor( nodeVar326 );
		nodeVar328 = fract( nodeVar324 );
		nodeVar329 = ( ( nodeVar328 * nodeVar328 ) * ( 3.0 - ( nodeVar328 * 2.0 ) ) );
		nodeVar330 = fract( nodeVar326 );
		nodeVar331 = ( nodeVar324 * 2.1 );
		nodeVar332 = floor( nodeVar331 );
		nodeVar333 = ( nodeVar326 * 2.1 );
		nodeVar334 = floor( nodeVar333 );
		nodeVar335 = fract( nodeVar331 );
		nodeVar336 = ( ( nodeVar335 * nodeVar335 ) * ( 3.0 - ( nodeVar335 * 2.0 ) ) );
		nodeVar337 = fract( nodeVar333 );
		nodeVar338 = ( nodeVar324 * 4.3 );
		nodeVar339 = floor( nodeVar338 );
		nodeVar340 = ( nodeVar326 * 4.3 );
		nodeVar341 = floor( nodeVar340 );
		nodeVar342 = fract( nodeVar338 );
		nodeVar343 = ( ( nodeVar342 * nodeVar342 ) * ( 3.0 - ( nodeVar342 * 2.0 ) ) );
		nodeVar344 = fract( nodeVar340 );
		nodeVar323 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar325 * 127.1 ) + ( nodeVar327 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar325 + 1.0 ) * 127.1 ) + ( nodeVar327 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar329 ), mix( fract( ( sin( ( ( nodeVar325 * 127.1 ) + ( ( nodeVar327 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar325 + 1.0 ) * 127.1 ) + ( ( nodeVar327 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar329 ), ( ( nodeVar330 * nodeVar330 ) * ( 3.0 - ( nodeVar330 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar332 * 127.1 ) + ( nodeVar334 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar332 + 1.0 ) * 127.1 ) + ( nodeVar334 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar336 ), mix( fract( ( sin( ( ( nodeVar332 * 127.1 ) + ( ( nodeVar334 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar332 + 1.0 ) * 127.1 ) + ( ( nodeVar334 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar336 ), ( ( nodeVar337 * nodeVar337 ) * ( 3.0 - ( nodeVar337 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar339 * 127.1 ) + ( nodeVar341 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar339 + 1.0 ) * 127.1 ) + ( nodeVar341 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar343 ), mix( fract( ( sin( ( ( nodeVar339 * 127.1 ) + ( ( nodeVar341 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar339 + 1.0 ) * 127.1 ) + ( ( nodeVar341 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar343 ), ( ( nodeVar344 * nodeVar344 ) * ( 3.0 - ( nodeVar344 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar346 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar347 = floor( nodeVar346 );
			nodeVar348 = ( ( nodeVar321 * 0.37 ) + 17.3 );
			nodeVar349 = floor( nodeVar348 );
			nodeVar350 = fract( nodeVar346 );
			nodeVar351 = ( ( nodeVar350 * nodeVar350 ) * ( 3.0 - ( nodeVar350 * 2.0 ) ) );
			nodeVar352 = fract( nodeVar348 );
			nodeVar353 = ( nodeVar346 * 2.1 );
			nodeVar354 = floor( nodeVar353 );
			nodeVar355 = ( nodeVar348 * 2.1 );
			nodeVar356 = floor( nodeVar355 );
			nodeVar357 = fract( nodeVar353 );
			nodeVar358 = ( ( nodeVar357 * nodeVar357 ) * ( 3.0 - ( nodeVar357 * 2.0 ) ) );
			nodeVar359 = fract( nodeVar355 );
			nodeVar360 = ( nodeVar346 * 4.3 );
			nodeVar361 = floor( nodeVar360 );
			nodeVar362 = ( nodeVar348 * 4.3 );
			nodeVar363 = floor( nodeVar362 );
			nodeVar364 = fract( nodeVar360 );
			nodeVar365 = ( ( nodeVar364 * nodeVar364 ) * ( 3.0 - ( nodeVar364 * 2.0 ) ) );
			nodeVar366 = fract( nodeVar362 );
			nodeVar345 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar347 * 127.1 ) + ( nodeVar349 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar347 + 1.0 ) * 127.1 ) + ( nodeVar349 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar351 ), mix( fract( ( sin( ( ( nodeVar347 * 127.1 ) + ( ( nodeVar349 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar347 + 1.0 ) * 127.1 ) + ( ( nodeVar349 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar351 ), ( ( nodeVar352 * nodeVar352 ) * ( 3.0 - ( nodeVar352 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar354 * 127.1 ) + ( nodeVar356 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar354 + 1.0 ) * 127.1 ) + ( nodeVar356 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar358 ), mix( fract( ( sin( ( ( nodeVar354 * 127.1 ) + ( ( nodeVar356 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar354 + 1.0 ) * 127.1 ) + ( ( nodeVar356 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar358 ), ( ( nodeVar359 * nodeVar359 ) * ( 3.0 - ( nodeVar359 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar361 * 127.1 ) + ( nodeVar363 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar361 + 1.0 ) * 127.1 ) + ( nodeVar363 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar365 ), mix( fract( ( sin( ( ( nodeVar361 * 127.1 ) + ( ( nodeVar363 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar361 + 1.0 ) * 127.1 ) + ( ( nodeVar363 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar365 ), ( ( nodeVar366 * nodeVar366 ) * ( 3.0 - ( nodeVar366 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar367 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar345 = ( ( ( sin( ( ( nodeVar367 * 0.004 ) + ( nodeVar321 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar367 * 0.011 ) + ( nodeVar321 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar367 * 0.0023 ) + ( nodeVar321 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar323 = nodeVar345;

	}

	nodeVar368 = abs( ( nodeVar46 - ( nodeVar322 + ( ( ( nodeVar319 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar323 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar369 = smoothstep( nodeVar99, nodeVar100, nodeVar319 );
	nodeVar370 = ( nodeVar320 + ( ( nodeVar319 * nodeVar44 ) * 0.08 ) );
	nodeVar371 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar320 - 1.0 ) ), ( nodeVar320 + 1.0 ), nodeVar368 ) ) * nodeVar369 ) * nodeVar319 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar370 - 2.0 ) ), ( nodeVar370 + 2.0 ), nodeVar368 ) ) * nodeVar369 ) * ( nodeVar319 * nodeVar319 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar372 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar373 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar374 = dot( nodeVar41, nodeVar373 );
		nodeVar375 = ( ( ( ( nodeVar47 + 0.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar376 = picture_read( vec2<f32>( ( ( ( nodeVar373.x * nodeVar374 ) + ( nodeVar43.x * nodeVar375 ) ) / knobs.resolution.x ), ( ( ( nodeVar373.y * nodeVar374 ) + ( nodeVar43.y * nodeVar375 ) ) / knobs.resolution.y ) ) );
		nodeVar372 = vec3<f32>( nodeVar376.x, nodeVar376.y, nodeVar376.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar378 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar379 = dot( nodeVar41, nodeVar378 );
		nodeVar380 = ( ( ( ( nodeVar47 + 0.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar381 = picture_read( vec2<f32>( ( ( ( nodeVar378.x * nodeVar379 ) + ( nodeVar43.x * nodeVar380 ) ) / knobs.resolution.x ), ( ( ( nodeVar378.y * nodeVar379 ) + ( nodeVar43.y * nodeVar380 ) ) / knobs.resolution.y ) ) );
		nodeVar377 = ( 1.0 - dot( vec3<f32>( nodeVar381.x, nodeVar381.y, nodeVar381.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar382 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar383 = dot( nodeVar41, nodeVar382 );
		nodeVar384 = ( ( ( ( nodeVar47 + 0.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar385 = picture_read( vec2<f32>( ( ( ( nodeVar382.x * nodeVar383 ) + ( nodeVar43.x * nodeVar384 ) ) / knobs.resolution.x ), ( ( ( nodeVar382.y * nodeVar383 ) + ( nodeVar43.y * nodeVar384 ) ) / knobs.resolution.y ) ) );
		nodeVar377 = dot( vec3<f32>( nodeVar385.x, nodeVar385.y, nodeVar385.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar386 = pow( clamp( ( ( nodeVar377 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar387 = ( nodeVar13 + ( nodeVar386 * 0.5 ) );
	nodeVar388 = ( nodeVar47 + 0.0 );
	nodeVar389 = ( ( nodeVar388 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar391 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar392 = floor( nodeVar391 );
		nodeVar393 = ( ( nodeVar388 * 0.37 ) + 17.3 );
		nodeVar394 = floor( nodeVar393 );
		nodeVar395 = fract( nodeVar391 );
		nodeVar396 = ( ( nodeVar395 * nodeVar395 ) * ( 3.0 - ( nodeVar395 * 2.0 ) ) );
		nodeVar397 = fract( nodeVar393 );
		nodeVar398 = ( nodeVar391 * 2.1 );
		nodeVar399 = floor( nodeVar398 );
		nodeVar400 = ( nodeVar393 * 2.1 );
		nodeVar401 = floor( nodeVar400 );
		nodeVar402 = fract( nodeVar398 );
		nodeVar403 = ( ( nodeVar402 * nodeVar402 ) * ( 3.0 - ( nodeVar402 * 2.0 ) ) );
		nodeVar404 = fract( nodeVar400 );
		nodeVar405 = ( nodeVar391 * 4.3 );
		nodeVar406 = floor( nodeVar405 );
		nodeVar407 = ( nodeVar393 * 4.3 );
		nodeVar408 = floor( nodeVar407 );
		nodeVar409 = fract( nodeVar405 );
		nodeVar410 = ( ( nodeVar409 * nodeVar409 ) * ( 3.0 - ( nodeVar409 * 2.0 ) ) );
		nodeVar411 = fract( nodeVar407 );
		nodeVar390 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar392 * 127.1 ) + ( nodeVar394 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar392 + 1.0 ) * 127.1 ) + ( nodeVar394 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar396 ), mix( fract( ( sin( ( ( nodeVar392 * 127.1 ) + ( ( nodeVar394 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar392 + 1.0 ) * 127.1 ) + ( ( nodeVar394 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar396 ), ( ( nodeVar397 * nodeVar397 ) * ( 3.0 - ( nodeVar397 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar399 * 127.1 ) + ( nodeVar401 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar399 + 1.0 ) * 127.1 ) + ( nodeVar401 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar403 ), mix( fract( ( sin( ( ( nodeVar399 * 127.1 ) + ( ( nodeVar401 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar399 + 1.0 ) * 127.1 ) + ( ( nodeVar401 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar403 ), ( ( nodeVar404 * nodeVar404 ) * ( 3.0 - ( nodeVar404 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar406 * 127.1 ) + ( nodeVar408 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar406 + 1.0 ) * 127.1 ) + ( nodeVar408 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar410 ), mix( fract( ( sin( ( ( nodeVar406 * 127.1 ) + ( ( nodeVar408 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar406 + 1.0 ) * 127.1 ) + ( ( nodeVar408 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar410 ), ( ( nodeVar411 * nodeVar411 ) * ( 3.0 - ( nodeVar411 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar413 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar414 = floor( nodeVar413 );
			nodeVar415 = ( ( nodeVar388 * 0.37 ) + 17.3 );
			nodeVar416 = floor( nodeVar415 );
			nodeVar417 = fract( nodeVar413 );
			nodeVar418 = ( ( nodeVar417 * nodeVar417 ) * ( 3.0 - ( nodeVar417 * 2.0 ) ) );
			nodeVar419 = fract( nodeVar415 );
			nodeVar420 = ( nodeVar413 * 2.1 );
			nodeVar421 = floor( nodeVar420 );
			nodeVar422 = ( nodeVar415 * 2.1 );
			nodeVar423 = floor( nodeVar422 );
			nodeVar424 = fract( nodeVar420 );
			nodeVar425 = ( ( nodeVar424 * nodeVar424 ) * ( 3.0 - ( nodeVar424 * 2.0 ) ) );
			nodeVar426 = fract( nodeVar422 );
			nodeVar427 = ( nodeVar413 * 4.3 );
			nodeVar428 = floor( nodeVar427 );
			nodeVar429 = ( nodeVar415 * 4.3 );
			nodeVar430 = floor( nodeVar429 );
			nodeVar431 = fract( nodeVar427 );
			nodeVar432 = ( ( nodeVar431 * nodeVar431 ) * ( 3.0 - ( nodeVar431 * 2.0 ) ) );
			nodeVar433 = fract( nodeVar429 );
			nodeVar412 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar414 * 127.1 ) + ( nodeVar416 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar414 + 1.0 ) * 127.1 ) + ( nodeVar416 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar418 ), mix( fract( ( sin( ( ( nodeVar414 * 127.1 ) + ( ( nodeVar416 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar414 + 1.0 ) * 127.1 ) + ( ( nodeVar416 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar418 ), ( ( nodeVar419 * nodeVar419 ) * ( 3.0 - ( nodeVar419 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar421 * 127.1 ) + ( nodeVar423 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar421 + 1.0 ) * 127.1 ) + ( nodeVar423 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar425 ), mix( fract( ( sin( ( ( nodeVar421 * 127.1 ) + ( ( nodeVar423 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar421 + 1.0 ) * 127.1 ) + ( ( nodeVar423 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar425 ), ( ( nodeVar426 * nodeVar426 ) * ( 3.0 - ( nodeVar426 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar428 * 127.1 ) + ( nodeVar430 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar428 + 1.0 ) * 127.1 ) + ( nodeVar430 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar432 ), mix( fract( ( sin( ( ( nodeVar428 * 127.1 ) + ( ( nodeVar430 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar428 + 1.0 ) * 127.1 ) + ( ( nodeVar430 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar432 ), ( ( nodeVar433 * nodeVar433 ) * ( 3.0 - ( nodeVar433 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar434 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar412 = ( ( ( sin( ( ( nodeVar434 * 0.004 ) + ( nodeVar388 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar434 * 0.011 ) + ( nodeVar388 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar434 * 0.0023 ) + ( nodeVar388 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar390 = nodeVar412;

	}

	nodeVar435 = abs( ( nodeVar46 - ( nodeVar389 + ( ( ( nodeVar386 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar390 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar436 = smoothstep( nodeVar99, nodeVar100, nodeVar386 );
	nodeVar437 = ( nodeVar387 + ( ( nodeVar386 * nodeVar44 ) * 0.08 ) );
	nodeVar438 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar387 - 1.0 ) ), ( nodeVar387 + 1.0 ), nodeVar435 ) ) * nodeVar436 ) * nodeVar386 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar437 - 2.0 ) ), ( nodeVar437 + 2.0 ), nodeVar435 ) ) * nodeVar436 ) * ( nodeVar386 * nodeVar386 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar439 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar440 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar441 = dot( nodeVar41, nodeVar440 );
		nodeVar442 = ( ( ( ( nodeVar47 + 1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar443 = picture_read( vec2<f32>( ( ( ( nodeVar440.x * nodeVar441 ) + ( nodeVar43.x * nodeVar442 ) ) / knobs.resolution.x ), ( ( ( nodeVar440.y * nodeVar441 ) + ( nodeVar43.y * nodeVar442 ) ) / knobs.resolution.y ) ) );
		nodeVar439 = vec3<f32>( nodeVar443.x, nodeVar443.y, nodeVar443.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar445 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar446 = dot( nodeVar41, nodeVar445 );
		nodeVar447 = ( ( ( ( nodeVar47 + 1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar448 = picture_read( vec2<f32>( ( ( ( nodeVar445.x * nodeVar446 ) + ( nodeVar43.x * nodeVar447 ) ) / knobs.resolution.x ), ( ( ( nodeVar445.y * nodeVar446 ) + ( nodeVar43.y * nodeVar447 ) ) / knobs.resolution.y ) ) );
		nodeVar444 = ( 1.0 - dot( vec3<f32>( nodeVar448.x, nodeVar448.y, nodeVar448.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar449 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar450 = dot( nodeVar41, nodeVar449 );
		nodeVar451 = ( ( ( ( nodeVar47 + 1.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar452 = picture_read( vec2<f32>( ( ( ( nodeVar449.x * nodeVar450 ) + ( nodeVar43.x * nodeVar451 ) ) / knobs.resolution.x ), ( ( ( nodeVar449.y * nodeVar450 ) + ( nodeVar43.y * nodeVar451 ) ) / knobs.resolution.y ) ) );
		nodeVar444 = dot( vec3<f32>( nodeVar452.x, nodeVar452.y, nodeVar452.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar453 = pow( clamp( ( ( nodeVar444 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar454 = ( nodeVar13 + ( nodeVar453 * 0.5 ) );
	nodeVar455 = ( nodeVar47 + 1.0 );
	nodeVar456 = ( ( nodeVar455 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar458 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar459 = floor( nodeVar458 );
		nodeVar460 = ( ( nodeVar455 * 0.37 ) + 17.3 );
		nodeVar461 = floor( nodeVar460 );
		nodeVar462 = fract( nodeVar458 );
		nodeVar463 = ( ( nodeVar462 * nodeVar462 ) * ( 3.0 - ( nodeVar462 * 2.0 ) ) );
		nodeVar464 = fract( nodeVar460 );
		nodeVar465 = ( nodeVar458 * 2.1 );
		nodeVar466 = floor( nodeVar465 );
		nodeVar467 = ( nodeVar460 * 2.1 );
		nodeVar468 = floor( nodeVar467 );
		nodeVar469 = fract( nodeVar465 );
		nodeVar470 = ( ( nodeVar469 * nodeVar469 ) * ( 3.0 - ( nodeVar469 * 2.0 ) ) );
		nodeVar471 = fract( nodeVar467 );
		nodeVar472 = ( nodeVar458 * 4.3 );
		nodeVar473 = floor( nodeVar472 );
		nodeVar474 = ( nodeVar460 * 4.3 );
		nodeVar475 = floor( nodeVar474 );
		nodeVar476 = fract( nodeVar472 );
		nodeVar477 = ( ( nodeVar476 * nodeVar476 ) * ( 3.0 - ( nodeVar476 * 2.0 ) ) );
		nodeVar478 = fract( nodeVar474 );
		nodeVar457 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar459 * 127.1 ) + ( nodeVar461 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar459 + 1.0 ) * 127.1 ) + ( nodeVar461 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar463 ), mix( fract( ( sin( ( ( nodeVar459 * 127.1 ) + ( ( nodeVar461 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar459 + 1.0 ) * 127.1 ) + ( ( nodeVar461 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar463 ), ( ( nodeVar464 * nodeVar464 ) * ( 3.0 - ( nodeVar464 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar466 * 127.1 ) + ( nodeVar468 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar466 + 1.0 ) * 127.1 ) + ( nodeVar468 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar470 ), mix( fract( ( sin( ( ( nodeVar466 * 127.1 ) + ( ( nodeVar468 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar466 + 1.0 ) * 127.1 ) + ( ( nodeVar468 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar470 ), ( ( nodeVar471 * nodeVar471 ) * ( 3.0 - ( nodeVar471 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar473 * 127.1 ) + ( nodeVar475 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar473 + 1.0 ) * 127.1 ) + ( nodeVar475 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar477 ), mix( fract( ( sin( ( ( nodeVar473 * 127.1 ) + ( ( nodeVar475 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar473 + 1.0 ) * 127.1 ) + ( ( nodeVar475 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar477 ), ( ( nodeVar478 * nodeVar478 ) * ( 3.0 - ( nodeVar478 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar480 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar481 = floor( nodeVar480 );
			nodeVar482 = ( ( nodeVar455 * 0.37 ) + 17.3 );
			nodeVar483 = floor( nodeVar482 );
			nodeVar484 = fract( nodeVar480 );
			nodeVar485 = ( ( nodeVar484 * nodeVar484 ) * ( 3.0 - ( nodeVar484 * 2.0 ) ) );
			nodeVar486 = fract( nodeVar482 );
			nodeVar487 = ( nodeVar480 * 2.1 );
			nodeVar488 = floor( nodeVar487 );
			nodeVar489 = ( nodeVar482 * 2.1 );
			nodeVar490 = floor( nodeVar489 );
			nodeVar491 = fract( nodeVar487 );
			nodeVar492 = ( ( nodeVar491 * nodeVar491 ) * ( 3.0 - ( nodeVar491 * 2.0 ) ) );
			nodeVar493 = fract( nodeVar489 );
			nodeVar494 = ( nodeVar480 * 4.3 );
			nodeVar495 = floor( nodeVar494 );
			nodeVar496 = ( nodeVar482 * 4.3 );
			nodeVar497 = floor( nodeVar496 );
			nodeVar498 = fract( nodeVar494 );
			nodeVar499 = ( ( nodeVar498 * nodeVar498 ) * ( 3.0 - ( nodeVar498 * 2.0 ) ) );
			nodeVar500 = fract( nodeVar496 );
			nodeVar479 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar481 * 127.1 ) + ( nodeVar483 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar481 + 1.0 ) * 127.1 ) + ( nodeVar483 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar485 ), mix( fract( ( sin( ( ( nodeVar481 * 127.1 ) + ( ( nodeVar483 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar481 + 1.0 ) * 127.1 ) + ( ( nodeVar483 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar485 ), ( ( nodeVar486 * nodeVar486 ) * ( 3.0 - ( nodeVar486 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar488 * 127.1 ) + ( nodeVar490 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar488 + 1.0 ) * 127.1 ) + ( nodeVar490 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar492 ), mix( fract( ( sin( ( ( nodeVar488 * 127.1 ) + ( ( nodeVar490 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar488 + 1.0 ) * 127.1 ) + ( ( nodeVar490 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar492 ), ( ( nodeVar493 * nodeVar493 ) * ( 3.0 - ( nodeVar493 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar495 * 127.1 ) + ( nodeVar497 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar495 + 1.0 ) * 127.1 ) + ( nodeVar497 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar499 ), mix( fract( ( sin( ( ( nodeVar495 * 127.1 ) + ( ( nodeVar497 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar495 + 1.0 ) * 127.1 ) + ( ( nodeVar497 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar499 ), ( ( nodeVar500 * nodeVar500 ) * ( 3.0 - ( nodeVar500 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar501 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar479 = ( ( ( sin( ( ( nodeVar501 * 0.004 ) + ( nodeVar455 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar501 * 0.011 ) + ( nodeVar455 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar501 * 0.0023 ) + ( nodeVar455 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar457 = nodeVar479;

	}

	nodeVar502 = abs( ( nodeVar46 - ( nodeVar456 + ( ( ( nodeVar453 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar457 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar503 = smoothstep( nodeVar99, nodeVar100, nodeVar453 );
	nodeVar504 = ( nodeVar454 + ( ( nodeVar453 * nodeVar44 ) * 0.08 ) );
	nodeVar505 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar454 - 1.0 ) ), ( nodeVar454 + 1.0 ), nodeVar502 ) ) * nodeVar503 ) * nodeVar453 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar504 - 2.0 ) ), ( nodeVar504 + 2.0 ), nodeVar502 ) ) * nodeVar503 ) * ( nodeVar453 * nodeVar453 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar506 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar507 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar508 = dot( nodeVar41, nodeVar507 );
		nodeVar509 = ( ( ( ( nodeVar47 + 2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar510 = picture_read( vec2<f32>( ( ( ( nodeVar507.x * nodeVar508 ) + ( nodeVar43.x * nodeVar509 ) ) / knobs.resolution.x ), ( ( ( nodeVar507.y * nodeVar508 ) + ( nodeVar43.y * nodeVar509 ) ) / knobs.resolution.y ) ) );
		nodeVar506 = vec3<f32>( nodeVar510.x, nodeVar510.y, nodeVar510.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar512 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar513 = dot( nodeVar41, nodeVar512 );
		nodeVar514 = ( ( ( ( nodeVar47 + 2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar515 = picture_read( vec2<f32>( ( ( ( nodeVar512.x * nodeVar513 ) + ( nodeVar43.x * nodeVar514 ) ) / knobs.resolution.x ), ( ( ( nodeVar512.y * nodeVar513 ) + ( nodeVar43.y * nodeVar514 ) ) / knobs.resolution.y ) ) );
		nodeVar511 = ( 1.0 - dot( vec3<f32>( nodeVar515.x, nodeVar515.y, nodeVar515.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar516 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar517 = dot( nodeVar41, nodeVar516 );
		nodeVar518 = ( ( ( ( nodeVar47 + 2.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar519 = picture_read( vec2<f32>( ( ( ( nodeVar516.x * nodeVar517 ) + ( nodeVar43.x * nodeVar518 ) ) / knobs.resolution.x ), ( ( ( nodeVar516.y * nodeVar517 ) + ( nodeVar43.y * nodeVar518 ) ) / knobs.resolution.y ) ) );
		nodeVar511 = dot( vec3<f32>( nodeVar519.x, nodeVar519.y, nodeVar519.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar520 = pow( clamp( ( ( nodeVar511 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar521 = ( nodeVar13 + ( nodeVar520 * 0.5 ) );
	nodeVar522 = ( nodeVar47 + 2.0 );
	nodeVar523 = ( ( nodeVar522 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar525 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar526 = floor( nodeVar525 );
		nodeVar527 = ( ( nodeVar522 * 0.37 ) + 17.3 );
		nodeVar528 = floor( nodeVar527 );
		nodeVar529 = fract( nodeVar525 );
		nodeVar530 = ( ( nodeVar529 * nodeVar529 ) * ( 3.0 - ( nodeVar529 * 2.0 ) ) );
		nodeVar531 = fract( nodeVar527 );
		nodeVar532 = ( nodeVar525 * 2.1 );
		nodeVar533 = floor( nodeVar532 );
		nodeVar534 = ( nodeVar527 * 2.1 );
		nodeVar535 = floor( nodeVar534 );
		nodeVar536 = fract( nodeVar532 );
		nodeVar537 = ( ( nodeVar536 * nodeVar536 ) * ( 3.0 - ( nodeVar536 * 2.0 ) ) );
		nodeVar538 = fract( nodeVar534 );
		nodeVar539 = ( nodeVar525 * 4.3 );
		nodeVar540 = floor( nodeVar539 );
		nodeVar541 = ( nodeVar527 * 4.3 );
		nodeVar542 = floor( nodeVar541 );
		nodeVar543 = fract( nodeVar539 );
		nodeVar544 = ( ( nodeVar543 * nodeVar543 ) * ( 3.0 - ( nodeVar543 * 2.0 ) ) );
		nodeVar545 = fract( nodeVar541 );
		nodeVar524 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar526 * 127.1 ) + ( nodeVar528 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar526 + 1.0 ) * 127.1 ) + ( nodeVar528 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar530 ), mix( fract( ( sin( ( ( nodeVar526 * 127.1 ) + ( ( nodeVar528 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar526 + 1.0 ) * 127.1 ) + ( ( nodeVar528 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar530 ), ( ( nodeVar531 * nodeVar531 ) * ( 3.0 - ( nodeVar531 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar533 * 127.1 ) + ( nodeVar535 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar533 + 1.0 ) * 127.1 ) + ( nodeVar535 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar537 ), mix( fract( ( sin( ( ( nodeVar533 * 127.1 ) + ( ( nodeVar535 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar533 + 1.0 ) * 127.1 ) + ( ( nodeVar535 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar537 ), ( ( nodeVar538 * nodeVar538 ) * ( 3.0 - ( nodeVar538 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar540 * 127.1 ) + ( nodeVar542 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar540 + 1.0 ) * 127.1 ) + ( nodeVar542 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar544 ), mix( fract( ( sin( ( ( nodeVar540 * 127.1 ) + ( ( nodeVar542 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar540 + 1.0 ) * 127.1 ) + ( ( nodeVar542 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar544 ), ( ( nodeVar545 * nodeVar545 ) * ( 3.0 - ( nodeVar545 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar547 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar548 = floor( nodeVar547 );
			nodeVar549 = ( ( nodeVar522 * 0.37 ) + 17.3 );
			nodeVar550 = floor( nodeVar549 );
			nodeVar551 = fract( nodeVar547 );
			nodeVar552 = ( ( nodeVar551 * nodeVar551 ) * ( 3.0 - ( nodeVar551 * 2.0 ) ) );
			nodeVar553 = fract( nodeVar549 );
			nodeVar554 = ( nodeVar547 * 2.1 );
			nodeVar555 = floor( nodeVar554 );
			nodeVar556 = ( nodeVar549 * 2.1 );
			nodeVar557 = floor( nodeVar556 );
			nodeVar558 = fract( nodeVar554 );
			nodeVar559 = ( ( nodeVar558 * nodeVar558 ) * ( 3.0 - ( nodeVar558 * 2.0 ) ) );
			nodeVar560 = fract( nodeVar556 );
			nodeVar561 = ( nodeVar547 * 4.3 );
			nodeVar562 = floor( nodeVar561 );
			nodeVar563 = ( nodeVar549 * 4.3 );
			nodeVar564 = floor( nodeVar563 );
			nodeVar565 = fract( nodeVar561 );
			nodeVar566 = ( ( nodeVar565 * nodeVar565 ) * ( 3.0 - ( nodeVar565 * 2.0 ) ) );
			nodeVar567 = fract( nodeVar563 );
			nodeVar546 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar548 * 127.1 ) + ( nodeVar550 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar548 + 1.0 ) * 127.1 ) + ( nodeVar550 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar552 ), mix( fract( ( sin( ( ( nodeVar548 * 127.1 ) + ( ( nodeVar550 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar548 + 1.0 ) * 127.1 ) + ( ( nodeVar550 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar552 ), ( ( nodeVar553 * nodeVar553 ) * ( 3.0 - ( nodeVar553 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar555 * 127.1 ) + ( nodeVar557 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar555 + 1.0 ) * 127.1 ) + ( nodeVar557 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar559 ), mix( fract( ( sin( ( ( nodeVar555 * 127.1 ) + ( ( nodeVar557 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar555 + 1.0 ) * 127.1 ) + ( ( nodeVar557 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar559 ), ( ( nodeVar560 * nodeVar560 ) * ( 3.0 - ( nodeVar560 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar562 * 127.1 ) + ( nodeVar564 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar562 + 1.0 ) * 127.1 ) + ( nodeVar564 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar566 ), mix( fract( ( sin( ( ( nodeVar562 * 127.1 ) + ( ( nodeVar564 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar562 + 1.0 ) * 127.1 ) + ( ( nodeVar564 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar566 ), ( ( nodeVar567 * nodeVar567 ) * ( 3.0 - ( nodeVar567 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar568 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar546 = ( ( ( sin( ( ( nodeVar568 * 0.004 ) + ( nodeVar522 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar568 * 0.011 ) + ( nodeVar522 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar568 * 0.0023 ) + ( nodeVar522 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar524 = nodeVar546;

	}

	nodeVar569 = abs( ( nodeVar46 - ( nodeVar523 + ( ( ( nodeVar520 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar524 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar570 = smoothstep( nodeVar99, nodeVar100, nodeVar520 );
	nodeVar571 = ( nodeVar521 + ( ( nodeVar520 * nodeVar44 ) * 0.08 ) );
	nodeVar572 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar521 - 1.0 ) ), ( nodeVar521 + 1.0 ), nodeVar569 ) ) * nodeVar570 ) * nodeVar520 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar571 - 2.0 ) ), ( nodeVar571 + 2.0 ), nodeVar569 ) ) * nodeVar570 ) * ( nodeVar520 * nodeVar520 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar573 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar574 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar575 = dot( nodeVar41, nodeVar574 );
		nodeVar576 = ( ( ( ( nodeVar47 + 3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar577 = picture_read( vec2<f32>( ( ( ( nodeVar574.x * nodeVar575 ) + ( nodeVar43.x * nodeVar576 ) ) / knobs.resolution.x ), ( ( ( nodeVar574.y * nodeVar575 ) + ( nodeVar43.y * nodeVar576 ) ) / knobs.resolution.y ) ) );
		nodeVar573 = vec3<f32>( nodeVar577.x, nodeVar577.y, nodeVar577.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar579 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar580 = dot( nodeVar41, nodeVar579 );
		nodeVar581 = ( ( ( ( nodeVar47 + 3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar582 = picture_read( vec2<f32>( ( ( ( nodeVar579.x * nodeVar580 ) + ( nodeVar43.x * nodeVar581 ) ) / knobs.resolution.x ), ( ( ( nodeVar579.y * nodeVar580 ) + ( nodeVar43.y * nodeVar581 ) ) / knobs.resolution.y ) ) );
		nodeVar578 = ( 1.0 - dot( vec3<f32>( nodeVar582.x, nodeVar582.y, nodeVar582.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar583 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar584 = dot( nodeVar41, nodeVar583 );
		nodeVar585 = ( ( ( ( nodeVar47 + 3.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar586 = picture_read( vec2<f32>( ( ( ( nodeVar583.x * nodeVar584 ) + ( nodeVar43.x * nodeVar585 ) ) / knobs.resolution.x ), ( ( ( nodeVar583.y * nodeVar584 ) + ( nodeVar43.y * nodeVar585 ) ) / knobs.resolution.y ) ) );
		nodeVar578 = dot( vec3<f32>( nodeVar586.x, nodeVar586.y, nodeVar586.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar587 = pow( clamp( ( ( nodeVar578 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar588 = ( nodeVar13 + ( nodeVar587 * 0.5 ) );
	nodeVar589 = ( nodeVar47 + 3.0 );
	nodeVar590 = ( ( nodeVar589 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar592 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar593 = floor( nodeVar592 );
		nodeVar594 = ( ( nodeVar589 * 0.37 ) + 17.3 );
		nodeVar595 = floor( nodeVar594 );
		nodeVar596 = fract( nodeVar592 );
		nodeVar597 = ( ( nodeVar596 * nodeVar596 ) * ( 3.0 - ( nodeVar596 * 2.0 ) ) );
		nodeVar598 = fract( nodeVar594 );
		nodeVar599 = ( nodeVar592 * 2.1 );
		nodeVar600 = floor( nodeVar599 );
		nodeVar601 = ( nodeVar594 * 2.1 );
		nodeVar602 = floor( nodeVar601 );
		nodeVar603 = fract( nodeVar599 );
		nodeVar604 = ( ( nodeVar603 * nodeVar603 ) * ( 3.0 - ( nodeVar603 * 2.0 ) ) );
		nodeVar605 = fract( nodeVar601 );
		nodeVar606 = ( nodeVar592 * 4.3 );
		nodeVar607 = floor( nodeVar606 );
		nodeVar608 = ( nodeVar594 * 4.3 );
		nodeVar609 = floor( nodeVar608 );
		nodeVar610 = fract( nodeVar606 );
		nodeVar611 = ( ( nodeVar610 * nodeVar610 ) * ( 3.0 - ( nodeVar610 * 2.0 ) ) );
		nodeVar612 = fract( nodeVar608 );
		nodeVar591 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar593 * 127.1 ) + ( nodeVar595 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar593 + 1.0 ) * 127.1 ) + ( nodeVar595 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar597 ), mix( fract( ( sin( ( ( nodeVar593 * 127.1 ) + ( ( nodeVar595 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar593 + 1.0 ) * 127.1 ) + ( ( nodeVar595 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar597 ), ( ( nodeVar598 * nodeVar598 ) * ( 3.0 - ( nodeVar598 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar600 * 127.1 ) + ( nodeVar602 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar600 + 1.0 ) * 127.1 ) + ( nodeVar602 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar604 ), mix( fract( ( sin( ( ( nodeVar600 * 127.1 ) + ( ( nodeVar602 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar600 + 1.0 ) * 127.1 ) + ( ( nodeVar602 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar604 ), ( ( nodeVar605 * nodeVar605 ) * ( 3.0 - ( nodeVar605 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar607 * 127.1 ) + ( nodeVar609 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar607 + 1.0 ) * 127.1 ) + ( nodeVar609 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar611 ), mix( fract( ( sin( ( ( nodeVar607 * 127.1 ) + ( ( nodeVar609 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar607 + 1.0 ) * 127.1 ) + ( ( nodeVar609 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar611 ), ( ( nodeVar612 * nodeVar612 ) * ( 3.0 - ( nodeVar612 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar614 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar615 = floor( nodeVar614 );
			nodeVar616 = ( ( nodeVar589 * 0.37 ) + 17.3 );
			nodeVar617 = floor( nodeVar616 );
			nodeVar618 = fract( nodeVar614 );
			nodeVar619 = ( ( nodeVar618 * nodeVar618 ) * ( 3.0 - ( nodeVar618 * 2.0 ) ) );
			nodeVar620 = fract( nodeVar616 );
			nodeVar621 = ( nodeVar614 * 2.1 );
			nodeVar622 = floor( nodeVar621 );
			nodeVar623 = ( nodeVar616 * 2.1 );
			nodeVar624 = floor( nodeVar623 );
			nodeVar625 = fract( nodeVar621 );
			nodeVar626 = ( ( nodeVar625 * nodeVar625 ) * ( 3.0 - ( nodeVar625 * 2.0 ) ) );
			nodeVar627 = fract( nodeVar623 );
			nodeVar628 = ( nodeVar614 * 4.3 );
			nodeVar629 = floor( nodeVar628 );
			nodeVar630 = ( nodeVar616 * 4.3 );
			nodeVar631 = floor( nodeVar630 );
			nodeVar632 = fract( nodeVar628 );
			nodeVar633 = ( ( nodeVar632 * nodeVar632 ) * ( 3.0 - ( nodeVar632 * 2.0 ) ) );
			nodeVar634 = fract( nodeVar630 );
			nodeVar613 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar615 * 127.1 ) + ( nodeVar617 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar615 + 1.0 ) * 127.1 ) + ( nodeVar617 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar619 ), mix( fract( ( sin( ( ( nodeVar615 * 127.1 ) + ( ( nodeVar617 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar615 + 1.0 ) * 127.1 ) + ( ( nodeVar617 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar619 ), ( ( nodeVar620 * nodeVar620 ) * ( 3.0 - ( nodeVar620 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar622 * 127.1 ) + ( nodeVar624 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar622 + 1.0 ) * 127.1 ) + ( nodeVar624 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar626 ), mix( fract( ( sin( ( ( nodeVar622 * 127.1 ) + ( ( nodeVar624 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar622 + 1.0 ) * 127.1 ) + ( ( nodeVar624 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar626 ), ( ( nodeVar627 * nodeVar627 ) * ( 3.0 - ( nodeVar627 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar629 * 127.1 ) + ( nodeVar631 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar629 + 1.0 ) * 127.1 ) + ( nodeVar631 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar633 ), mix( fract( ( sin( ( ( nodeVar629 * 127.1 ) + ( ( nodeVar631 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar629 + 1.0 ) * 127.1 ) + ( ( nodeVar631 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar633 ), ( ( nodeVar634 * nodeVar634 ) * ( 3.0 - ( nodeVar634 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar635 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar613 = ( ( ( sin( ( ( nodeVar635 * 0.004 ) + ( nodeVar589 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar635 * 0.011 ) + ( nodeVar589 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar635 * 0.0023 ) + ( nodeVar589 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar591 = nodeVar613;

	}

	nodeVar636 = abs( ( nodeVar46 - ( nodeVar590 + ( ( ( nodeVar587 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar591 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar637 = smoothstep( nodeVar99, nodeVar100, nodeVar587 );
	nodeVar638 = ( nodeVar588 + ( ( nodeVar587 * nodeVar44 ) * 0.08 ) );
	nodeVar639 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar588 - 1.0 ) ), ( nodeVar588 + 1.0 ), nodeVar636 ) ) * nodeVar637 ) * nodeVar587 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar638 - 2.0 ) ), ( nodeVar638 + 2.0 ), nodeVar636 ) ) * nodeVar637 ) * ( nodeVar587 * nodeVar587 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar640 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar641 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar642 = dot( nodeVar41, nodeVar641 );
		nodeVar643 = ( ( ( ( nodeVar47 + 4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar644 = picture_read( vec2<f32>( ( ( ( nodeVar641.x * nodeVar642 ) + ( nodeVar43.x * nodeVar643 ) ) / knobs.resolution.x ), ( ( ( nodeVar641.y * nodeVar642 ) + ( nodeVar43.y * nodeVar643 ) ) / knobs.resolution.y ) ) );
		nodeVar640 = vec3<f32>( nodeVar644.x, nodeVar644.y, nodeVar644.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar646 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar647 = dot( nodeVar41, nodeVar646 );
		nodeVar648 = ( ( ( ( nodeVar47 + 4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar649 = picture_read( vec2<f32>( ( ( ( nodeVar646.x * nodeVar647 ) + ( nodeVar43.x * nodeVar648 ) ) / knobs.resolution.x ), ( ( ( nodeVar646.y * nodeVar647 ) + ( nodeVar43.y * nodeVar648 ) ) / knobs.resolution.y ) ) );
		nodeVar645 = ( 1.0 - dot( vec3<f32>( nodeVar649.x, nodeVar649.y, nodeVar649.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar650 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar651 = dot( nodeVar41, nodeVar650 );
		nodeVar652 = ( ( ( ( nodeVar47 + 4.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar653 = picture_read( vec2<f32>( ( ( ( nodeVar650.x * nodeVar651 ) + ( nodeVar43.x * nodeVar652 ) ) / knobs.resolution.x ), ( ( ( nodeVar650.y * nodeVar651 ) + ( nodeVar43.y * nodeVar652 ) ) / knobs.resolution.y ) ) );
		nodeVar645 = dot( vec3<f32>( nodeVar653.x, nodeVar653.y, nodeVar653.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar654 = pow( clamp( ( ( nodeVar645 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar655 = ( nodeVar13 + ( nodeVar654 * 0.5 ) );
	nodeVar656 = ( nodeVar47 + 4.0 );
	nodeVar657 = ( ( nodeVar656 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar659 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar660 = floor( nodeVar659 );
		nodeVar661 = ( ( nodeVar656 * 0.37 ) + 17.3 );
		nodeVar662 = floor( nodeVar661 );
		nodeVar663 = fract( nodeVar659 );
		nodeVar664 = ( ( nodeVar663 * nodeVar663 ) * ( 3.0 - ( nodeVar663 * 2.0 ) ) );
		nodeVar665 = fract( nodeVar661 );
		nodeVar666 = ( nodeVar659 * 2.1 );
		nodeVar667 = floor( nodeVar666 );
		nodeVar668 = ( nodeVar661 * 2.1 );
		nodeVar669 = floor( nodeVar668 );
		nodeVar670 = fract( nodeVar666 );
		nodeVar671 = ( ( nodeVar670 * nodeVar670 ) * ( 3.0 - ( nodeVar670 * 2.0 ) ) );
		nodeVar672 = fract( nodeVar668 );
		nodeVar673 = ( nodeVar659 * 4.3 );
		nodeVar674 = floor( nodeVar673 );
		nodeVar675 = ( nodeVar661 * 4.3 );
		nodeVar676 = floor( nodeVar675 );
		nodeVar677 = fract( nodeVar673 );
		nodeVar678 = ( ( nodeVar677 * nodeVar677 ) * ( 3.0 - ( nodeVar677 * 2.0 ) ) );
		nodeVar679 = fract( nodeVar675 );
		nodeVar658 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar660 * 127.1 ) + ( nodeVar662 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar660 + 1.0 ) * 127.1 ) + ( nodeVar662 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar664 ), mix( fract( ( sin( ( ( nodeVar660 * 127.1 ) + ( ( nodeVar662 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar660 + 1.0 ) * 127.1 ) + ( ( nodeVar662 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar664 ), ( ( nodeVar665 * nodeVar665 ) * ( 3.0 - ( nodeVar665 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar667 * 127.1 ) + ( nodeVar669 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar667 + 1.0 ) * 127.1 ) + ( nodeVar669 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar671 ), mix( fract( ( sin( ( ( nodeVar667 * 127.1 ) + ( ( nodeVar669 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar667 + 1.0 ) * 127.1 ) + ( ( nodeVar669 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar671 ), ( ( nodeVar672 * nodeVar672 ) * ( 3.0 - ( nodeVar672 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar674 * 127.1 ) + ( nodeVar676 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar674 + 1.0 ) * 127.1 ) + ( nodeVar676 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar678 ), mix( fract( ( sin( ( ( nodeVar674 * 127.1 ) + ( ( nodeVar676 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar674 + 1.0 ) * 127.1 ) + ( ( nodeVar676 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar678 ), ( ( nodeVar679 * nodeVar679 ) * ( 3.0 - ( nodeVar679 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar681 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar682 = floor( nodeVar681 );
			nodeVar683 = ( ( nodeVar656 * 0.37 ) + 17.3 );
			nodeVar684 = floor( nodeVar683 );
			nodeVar685 = fract( nodeVar681 );
			nodeVar686 = ( ( nodeVar685 * nodeVar685 ) * ( 3.0 - ( nodeVar685 * 2.0 ) ) );
			nodeVar687 = fract( nodeVar683 );
			nodeVar688 = ( nodeVar681 * 2.1 );
			nodeVar689 = floor( nodeVar688 );
			nodeVar690 = ( nodeVar683 * 2.1 );
			nodeVar691 = floor( nodeVar690 );
			nodeVar692 = fract( nodeVar688 );
			nodeVar693 = ( ( nodeVar692 * nodeVar692 ) * ( 3.0 - ( nodeVar692 * 2.0 ) ) );
			nodeVar694 = fract( nodeVar690 );
			nodeVar695 = ( nodeVar681 * 4.3 );
			nodeVar696 = floor( nodeVar695 );
			nodeVar697 = ( nodeVar683 * 4.3 );
			nodeVar698 = floor( nodeVar697 );
			nodeVar699 = fract( nodeVar695 );
			nodeVar700 = ( ( nodeVar699 * nodeVar699 ) * ( 3.0 - ( nodeVar699 * 2.0 ) ) );
			nodeVar701 = fract( nodeVar697 );
			nodeVar680 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar682 * 127.1 ) + ( nodeVar684 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar682 + 1.0 ) * 127.1 ) + ( nodeVar684 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar686 ), mix( fract( ( sin( ( ( nodeVar682 * 127.1 ) + ( ( nodeVar684 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar682 + 1.0 ) * 127.1 ) + ( ( nodeVar684 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar686 ), ( ( nodeVar687 * nodeVar687 ) * ( 3.0 - ( nodeVar687 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar689 * 127.1 ) + ( nodeVar691 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar689 + 1.0 ) * 127.1 ) + ( nodeVar691 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar693 ), mix( fract( ( sin( ( ( nodeVar689 * 127.1 ) + ( ( nodeVar691 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar689 + 1.0 ) * 127.1 ) + ( ( nodeVar691 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar693 ), ( ( nodeVar694 * nodeVar694 ) * ( 3.0 - ( nodeVar694 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar696 * 127.1 ) + ( nodeVar698 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar696 + 1.0 ) * 127.1 ) + ( nodeVar698 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar700 ), mix( fract( ( sin( ( ( nodeVar696 * 127.1 ) + ( ( nodeVar698 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar696 + 1.0 ) * 127.1 ) + ( ( nodeVar698 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar700 ), ( ( nodeVar701 * nodeVar701 ) * ( 3.0 - ( nodeVar701 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar702 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar680 = ( ( ( sin( ( ( nodeVar702 * 0.004 ) + ( nodeVar656 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar702 * 0.011 ) + ( nodeVar656 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar702 * 0.0023 ) + ( nodeVar656 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar658 = nodeVar680;

	}

	nodeVar703 = abs( ( nodeVar46 - ( nodeVar657 + ( ( ( nodeVar654 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar658 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar704 = smoothstep( nodeVar99, nodeVar100, nodeVar654 );
	nodeVar705 = ( nodeVar655 + ( ( nodeVar654 * nodeVar44 ) * 0.08 ) );
	nodeVar706 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar655 - 1.0 ) ), ( nodeVar655 + 1.0 ), nodeVar703 ) ) * nodeVar704 ) * nodeVar654 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar705 - 2.0 ) ), ( nodeVar705 + 2.0 ), nodeVar703 ) ) * nodeVar704 ) * ( nodeVar654 * nodeVar654 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar707 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).x;

	} else {

		nodeVar708 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar709 = dot( nodeVar41, nodeVar708 );
		nodeVar710 = ( ( ( ( nodeVar47 + 5.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar711 = picture_read( vec2<f32>( ( ( ( nodeVar708.x * nodeVar709 ) + ( nodeVar43.x * nodeVar710 ) ) / knobs.resolution.x ), ( ( ( nodeVar708.y * nodeVar709 ) + ( nodeVar43.y * nodeVar710 ) ) / knobs.resolution.y ) ) );
		nodeVar707 = vec3<f32>( nodeVar711.x, nodeVar711.y, nodeVar711.z ).x;

	}


	if ( nodeVar15 ) {

		nodeVar713 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar714 = dot( nodeVar41, nodeVar713 );
		nodeVar715 = ( ( ( ( nodeVar47 + 5.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar716 = picture_read( vec2<f32>( ( ( ( nodeVar713.x * nodeVar714 ) + ( nodeVar43.x * nodeVar715 ) ) / knobs.resolution.x ), ( ( ( nodeVar713.y * nodeVar714 ) + ( nodeVar43.y * nodeVar715 ) ) / knobs.resolution.y ) ) );
		nodeVar712 = ( 1.0 - dot( vec3<f32>( nodeVar716.x, nodeVar716.y, nodeVar716.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		nodeVar717 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar718 = dot( nodeVar41, nodeVar717 );
		nodeVar719 = ( ( ( ( nodeVar47 + 5.0 ) * nodeVar44 ) + ( nodeVar44 * 0.5 ) ) - nodeVar45 );
		nodeVar720 = picture_read( vec2<f32>( ( ( ( nodeVar717.x * nodeVar718 ) + ( nodeVar43.x * nodeVar719 ) ) / knobs.resolution.x ), ( ( ( nodeVar717.y * nodeVar718 ) + ( nodeVar43.y * nodeVar719 ) ) / knobs.resolution.y ) ) );
		nodeVar712 = dot( vec3<f32>( nodeVar720.x, nodeVar720.y, nodeVar720.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	nodeVar721 = pow( clamp( ( ( nodeVar712 - knobs.signalBlackPoint ) / nodeVar36 ), 0.0, 1.0 ), nodeVar37 );
	nodeVar722 = ( nodeVar13 + ( nodeVar721 * 0.5 ) );
	nodeVar723 = ( nodeVar47 + 5.0 );
	nodeVar724 = ( ( nodeVar723 * nodeVar44 ) + ( nodeVar44 * 0.5 ) );

	if ( nodeVar51 ) {

		nodeVar726 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
		nodeVar727 = floor( nodeVar726 );
		nodeVar728 = ( ( nodeVar723 * 0.37 ) + 17.3 );
		nodeVar729 = floor( nodeVar728 );
		nodeVar730 = fract( nodeVar726 );
		nodeVar731 = ( ( nodeVar730 * nodeVar730 ) * ( 3.0 - ( nodeVar730 * 2.0 ) ) );
		nodeVar732 = fract( nodeVar728 );
		nodeVar733 = ( nodeVar726 * 2.1 );
		nodeVar734 = floor( nodeVar733 );
		nodeVar735 = ( nodeVar728 * 2.1 );
		nodeVar736 = floor( nodeVar735 );
		nodeVar737 = fract( nodeVar733 );
		nodeVar738 = ( ( nodeVar737 * nodeVar737 ) * ( 3.0 - ( nodeVar737 * 2.0 ) ) );
		nodeVar739 = fract( nodeVar735 );
		nodeVar740 = ( nodeVar726 * 4.3 );
		nodeVar741 = floor( nodeVar740 );
		nodeVar742 = ( nodeVar728 * 4.3 );
		nodeVar743 = floor( nodeVar742 );
		nodeVar744 = fract( nodeVar740 );
		nodeVar745 = ( ( nodeVar744 * nodeVar744 ) * ( 3.0 - ( nodeVar744 * 2.0 ) ) );
		nodeVar746 = fract( nodeVar742 );
		nodeVar725 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar727 * 127.1 ) + ( nodeVar729 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar727 + 1.0 ) * 127.1 ) + ( nodeVar729 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar731 ), mix( fract( ( sin( ( ( nodeVar727 * 127.1 ) + ( ( nodeVar729 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar727 + 1.0 ) * 127.1 ) + ( ( nodeVar729 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar731 ), ( ( nodeVar732 * nodeVar732 ) * ( 3.0 - ( nodeVar732 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar734 * 127.1 ) + ( nodeVar736 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar734 + 1.0 ) * 127.1 ) + ( nodeVar736 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar738 ), mix( fract( ( sin( ( ( nodeVar734 * 127.1 ) + ( ( nodeVar736 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar734 + 1.0 ) * 127.1 ) + ( ( nodeVar736 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar738 ), ( ( nodeVar739 * nodeVar739 ) * ( 3.0 - ( nodeVar739 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( nodeVar741 * 127.1 ) + ( nodeVar743 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar741 + 1.0 ) * 127.1 ) + ( nodeVar743 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar745 ), mix( fract( ( sin( ( ( nodeVar741 * 127.1 ) + ( ( nodeVar743 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar741 + 1.0 ) * 127.1 ) + ( ( nodeVar743 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar745 ), ( ( nodeVar746 * nodeVar746 ) * ( 3.0 - ( nodeVar746 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( knobs.noiseMode > 0.5 ) ) {

			nodeVar748 = ( dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) ) * 0.012 );
			nodeVar749 = floor( nodeVar748 );
			nodeVar750 = ( ( nodeVar723 * 0.37 ) + 17.3 );
			nodeVar751 = floor( nodeVar750 );
			nodeVar752 = fract( nodeVar748 );
			nodeVar753 = ( ( nodeVar752 * nodeVar752 ) * ( 3.0 - ( nodeVar752 * 2.0 ) ) );
			nodeVar754 = fract( nodeVar750 );
			nodeVar755 = ( nodeVar748 * 2.1 );
			nodeVar756 = floor( nodeVar755 );
			nodeVar757 = ( nodeVar750 * 2.1 );
			nodeVar758 = floor( nodeVar757 );
			nodeVar759 = fract( nodeVar755 );
			nodeVar760 = ( ( nodeVar759 * nodeVar759 ) * ( 3.0 - ( nodeVar759 * 2.0 ) ) );
			nodeVar761 = fract( nodeVar757 );
			nodeVar762 = ( nodeVar748 * 4.3 );
			nodeVar763 = floor( nodeVar762 );
			nodeVar764 = ( nodeVar750 * 4.3 );
			nodeVar765 = floor( nodeVar764 );
			nodeVar766 = fract( nodeVar762 );
			nodeVar767 = ( ( nodeVar766 * nodeVar766 ) * ( 3.0 - ( nodeVar766 * 2.0 ) ) );
			nodeVar768 = fract( nodeVar764 );
			nodeVar747 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( nodeVar749 * 127.1 ) + ( nodeVar751 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar749 + 1.0 ) * 127.1 ) + ( nodeVar751 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar753 ), mix( fract( ( sin( ( ( nodeVar749 * 127.1 ) + ( ( nodeVar751 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar749 + 1.0 ) * 127.1 ) + ( ( nodeVar751 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar753 ), ( ( nodeVar754 * nodeVar754 ) * ( 3.0 - ( nodeVar754 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( nodeVar756 * 127.1 ) + ( nodeVar758 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar756 + 1.0 ) * 127.1 ) + ( nodeVar758 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar760 ), mix( fract( ( sin( ( ( nodeVar756 * 127.1 ) + ( ( nodeVar758 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar756 + 1.0 ) * 127.1 ) + ( ( nodeVar758 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar760 ), ( ( nodeVar761 * nodeVar761 ) * ( 3.0 - ( nodeVar761 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( nodeVar763 * 127.1 ) + ( nodeVar765 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar763 + 1.0 ) * 127.1 ) + ( nodeVar765 * 311.7 ) ) ) * 43758.5453 ) ), nodeVar767 ), mix( fract( ( sin( ( ( nodeVar763 * 127.1 ) + ( ( nodeVar765 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( nodeVar763 + 1.0 ) * 127.1 ) + ( ( nodeVar765 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), nodeVar767 ), ( ( nodeVar768 * nodeVar768 ) * ( 3.0 - ( nodeVar768 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			nodeVar769 = dot( nodeVar41, vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) ) );
			nodeVar747 = ( ( ( sin( ( ( nodeVar769 * 0.004 ) + ( nodeVar723 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( nodeVar769 * 0.011 ) + ( nodeVar723 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( nodeVar769 * 0.0023 ) + ( nodeVar723 * 0.71 ) ) ) * 0.25 ) );

		}

		nodeVar725 = nodeVar747;

	}

	nodeVar770 = abs( ( nodeVar46 - ( nodeVar724 + ( ( ( nodeVar721 * nodeVar44 ) * 5.0 ) + ( ( ( nodeVar725 * nodeVar44 ) * knobs.noiseAmount ) * 2.0 ) ) ) ) );
	nodeVar771 = smoothstep( nodeVar99, nodeVar100, nodeVar721 );
	nodeVar772 = ( nodeVar722 + ( ( nodeVar721 * nodeVar44 ) * 0.08 ) );
	nodeVar773 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar722 - 1.0 ) ), ( nodeVar722 + 1.0 ), nodeVar770 ) ) * nodeVar771 ) * nodeVar721 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( nodeVar772 - 2.0 ) ), ( nodeVar772 + 2.0 ), nodeVar770 ) ) * nodeVar771 ) * ( nodeVar721 * nodeVar721 ) ) * 0.35 ) );

	if ( nodeVar2 ) {

		nodeVar774 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar775 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar776 = dot( nodeVar41, nodeVar775 );
		nodeVar777 = ( nodeVar49 - nodeVar45 );
		nodeVar778 = picture_read( vec2<f32>( ( ( ( nodeVar775.x * nodeVar776 ) + ( nodeVar43.x * nodeVar777 ) ) / knobs.resolution.x ), ( ( ( nodeVar775.y * nodeVar776 ) + ( nodeVar43.y * nodeVar777 ) ) / knobs.resolution.y ) ) );
		nodeVar774 = vec3<f32>( nodeVar778.x, nodeVar778.y, nodeVar778.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar779 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar780 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar781 = dot( nodeVar41, nodeVar780 );
		nodeVar782 = ( nodeVar121 - nodeVar45 );
		nodeVar783 = picture_read( vec2<f32>( ( ( ( nodeVar780.x * nodeVar781 ) + ( nodeVar43.x * nodeVar782 ) ) / knobs.resolution.x ), ( ( ( nodeVar780.y * nodeVar781 ) + ( nodeVar43.y * nodeVar782 ) ) / knobs.resolution.y ) ) );
		nodeVar779 = vec3<f32>( nodeVar783.x, nodeVar783.y, nodeVar783.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar784 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar785 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar786 = dot( nodeVar41, nodeVar785 );
		nodeVar787 = ( nodeVar188 - nodeVar45 );
		nodeVar788 = picture_read( vec2<f32>( ( ( ( nodeVar785.x * nodeVar786 ) + ( nodeVar43.x * nodeVar787 ) ) / knobs.resolution.x ), ( ( ( nodeVar785.y * nodeVar786 ) + ( nodeVar43.y * nodeVar787 ) ) / knobs.resolution.y ) ) );
		nodeVar784 = vec3<f32>( nodeVar788.x, nodeVar788.y, nodeVar788.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar789 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar790 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar791 = dot( nodeVar41, nodeVar790 );
		nodeVar792 = ( nodeVar255 - nodeVar45 );
		nodeVar793 = picture_read( vec2<f32>( ( ( ( nodeVar790.x * nodeVar791 ) + ( nodeVar43.x * nodeVar792 ) ) / knobs.resolution.x ), ( ( ( nodeVar790.y * nodeVar791 ) + ( nodeVar43.y * nodeVar792 ) ) / knobs.resolution.y ) ) );
		nodeVar789 = vec3<f32>( nodeVar793.x, nodeVar793.y, nodeVar793.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar794 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar795 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar796 = dot( nodeVar41, nodeVar795 );
		nodeVar797 = ( nodeVar322 - nodeVar45 );
		nodeVar798 = picture_read( vec2<f32>( ( ( ( nodeVar795.x * nodeVar796 ) + ( nodeVar43.x * nodeVar797 ) ) / knobs.resolution.x ), ( ( ( nodeVar795.y * nodeVar796 ) + ( nodeVar43.y * nodeVar797 ) ) / knobs.resolution.y ) ) );
		nodeVar794 = vec3<f32>( nodeVar798.x, nodeVar798.y, nodeVar798.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar799 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar800 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar801 = dot( nodeVar41, nodeVar800 );
		nodeVar802 = ( nodeVar389 - nodeVar45 );
		nodeVar803 = picture_read( vec2<f32>( ( ( ( nodeVar800.x * nodeVar801 ) + ( nodeVar43.x * nodeVar802 ) ) / knobs.resolution.x ), ( ( ( nodeVar800.y * nodeVar801 ) + ( nodeVar43.y * nodeVar802 ) ) / knobs.resolution.y ) ) );
		nodeVar799 = vec3<f32>( nodeVar803.x, nodeVar803.y, nodeVar803.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar804 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar805 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar806 = dot( nodeVar41, nodeVar805 );
		nodeVar807 = ( nodeVar456 - nodeVar45 );
		nodeVar808 = picture_read( vec2<f32>( ( ( ( nodeVar805.x * nodeVar806 ) + ( nodeVar43.x * nodeVar807 ) ) / knobs.resolution.x ), ( ( ( nodeVar805.y * nodeVar806 ) + ( nodeVar43.y * nodeVar807 ) ) / knobs.resolution.y ) ) );
		nodeVar804 = vec3<f32>( nodeVar808.x, nodeVar808.y, nodeVar808.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar809 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar810 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar811 = dot( nodeVar41, nodeVar810 );
		nodeVar812 = ( nodeVar523 - nodeVar45 );
		nodeVar813 = picture_read( vec2<f32>( ( ( ( nodeVar810.x * nodeVar811 ) + ( nodeVar43.x * nodeVar812 ) ) / knobs.resolution.x ), ( ( ( nodeVar810.y * nodeVar811 ) + ( nodeVar43.y * nodeVar812 ) ) / knobs.resolution.y ) ) );
		nodeVar809 = vec3<f32>( nodeVar813.x, nodeVar813.y, nodeVar813.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar814 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar815 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar816 = dot( nodeVar41, nodeVar815 );
		nodeVar817 = ( nodeVar590 - nodeVar45 );
		nodeVar818 = picture_read( vec2<f32>( ( ( ( nodeVar815.x * nodeVar816 ) + ( nodeVar43.x * nodeVar817 ) ) / knobs.resolution.x ), ( ( ( nodeVar815.y * nodeVar816 ) + ( nodeVar43.y * nodeVar817 ) ) / knobs.resolution.y ) ) );
		nodeVar814 = vec3<f32>( nodeVar818.x, nodeVar818.y, nodeVar818.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar819 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar820 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar821 = dot( nodeVar41, nodeVar820 );
		nodeVar822 = ( nodeVar657 - nodeVar45 );
		nodeVar823 = picture_read( vec2<f32>( ( ( ( nodeVar820.x * nodeVar821 ) + ( nodeVar43.x * nodeVar822 ) ) / knobs.resolution.x ), ( ( ( nodeVar820.y * nodeVar821 ) + ( nodeVar43.y * nodeVar822 ) ) / knobs.resolution.y ) ) );
		nodeVar819 = vec3<f32>( nodeVar823.x, nodeVar823.y, nodeVar823.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar824 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).y;

	} else {

		nodeVar825 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar826 = dot( nodeVar41, nodeVar825 );
		nodeVar827 = ( nodeVar724 - nodeVar45 );
		nodeVar828 = picture_read( vec2<f32>( ( ( ( nodeVar825.x * nodeVar826 ) + ( nodeVar43.x * nodeVar827 ) ) / knobs.resolution.x ), ( ( ( nodeVar825.y * nodeVar826 ) + ( nodeVar43.y * nodeVar827 ) ) / knobs.resolution.y ) ) );
		nodeVar824 = vec3<f32>( nodeVar828.x, nodeVar828.y, nodeVar828.z ).y;

	}


	if ( nodeVar2 ) {

		nodeVar829 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar830 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar831 = dot( nodeVar41, nodeVar830 );
		nodeVar832 = ( nodeVar49 - nodeVar45 );
		nodeVar833 = picture_read( vec2<f32>( ( ( ( nodeVar830.x * nodeVar831 ) + ( nodeVar43.x * nodeVar832 ) ) / knobs.resolution.x ), ( ( ( nodeVar830.y * nodeVar831 ) + ( nodeVar43.y * nodeVar832 ) ) / knobs.resolution.y ) ) );
		nodeVar829 = vec3<f32>( nodeVar833.x, nodeVar833.y, nodeVar833.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar834 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar835 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar836 = dot( nodeVar41, nodeVar835 );
		nodeVar837 = ( nodeVar121 - nodeVar45 );
		nodeVar838 = picture_read( vec2<f32>( ( ( ( nodeVar835.x * nodeVar836 ) + ( nodeVar43.x * nodeVar837 ) ) / knobs.resolution.x ), ( ( ( nodeVar835.y * nodeVar836 ) + ( nodeVar43.y * nodeVar837 ) ) / knobs.resolution.y ) ) );
		nodeVar834 = vec3<f32>( nodeVar838.x, nodeVar838.y, nodeVar838.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar839 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar840 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar841 = dot( nodeVar41, nodeVar840 );
		nodeVar842 = ( nodeVar188 - nodeVar45 );
		nodeVar843 = picture_read( vec2<f32>( ( ( ( nodeVar840.x * nodeVar841 ) + ( nodeVar43.x * nodeVar842 ) ) / knobs.resolution.x ), ( ( ( nodeVar840.y * nodeVar841 ) + ( nodeVar43.y * nodeVar842 ) ) / knobs.resolution.y ) ) );
		nodeVar839 = vec3<f32>( nodeVar843.x, nodeVar843.y, nodeVar843.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar844 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar845 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar846 = dot( nodeVar41, nodeVar845 );
		nodeVar847 = ( nodeVar255 - nodeVar45 );
		nodeVar848 = picture_read( vec2<f32>( ( ( ( nodeVar845.x * nodeVar846 ) + ( nodeVar43.x * nodeVar847 ) ) / knobs.resolution.x ), ( ( ( nodeVar845.y * nodeVar846 ) + ( nodeVar43.y * nodeVar847 ) ) / knobs.resolution.y ) ) );
		nodeVar844 = vec3<f32>( nodeVar848.x, nodeVar848.y, nodeVar848.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar849 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar850 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar851 = dot( nodeVar41, nodeVar850 );
		nodeVar852 = ( nodeVar322 - nodeVar45 );
		nodeVar853 = picture_read( vec2<f32>( ( ( ( nodeVar850.x * nodeVar851 ) + ( nodeVar43.x * nodeVar852 ) ) / knobs.resolution.x ), ( ( ( nodeVar850.y * nodeVar851 ) + ( nodeVar43.y * nodeVar852 ) ) / knobs.resolution.y ) ) );
		nodeVar849 = vec3<f32>( nodeVar853.x, nodeVar853.y, nodeVar853.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar854 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar855 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar856 = dot( nodeVar41, nodeVar855 );
		nodeVar857 = ( nodeVar389 - nodeVar45 );
		nodeVar858 = picture_read( vec2<f32>( ( ( ( nodeVar855.x * nodeVar856 ) + ( nodeVar43.x * nodeVar857 ) ) / knobs.resolution.x ), ( ( ( nodeVar855.y * nodeVar856 ) + ( nodeVar43.y * nodeVar857 ) ) / knobs.resolution.y ) ) );
		nodeVar854 = vec3<f32>( nodeVar858.x, nodeVar858.y, nodeVar858.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar859 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar860 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar861 = dot( nodeVar41, nodeVar860 );
		nodeVar862 = ( nodeVar456 - nodeVar45 );
		nodeVar863 = picture_read( vec2<f32>( ( ( ( nodeVar860.x * nodeVar861 ) + ( nodeVar43.x * nodeVar862 ) ) / knobs.resolution.x ), ( ( ( nodeVar860.y * nodeVar861 ) + ( nodeVar43.y * nodeVar862 ) ) / knobs.resolution.y ) ) );
		nodeVar859 = vec3<f32>( nodeVar863.x, nodeVar863.y, nodeVar863.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar864 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar865 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar866 = dot( nodeVar41, nodeVar865 );
		nodeVar867 = ( nodeVar523 - nodeVar45 );
		nodeVar868 = picture_read( vec2<f32>( ( ( ( nodeVar865.x * nodeVar866 ) + ( nodeVar43.x * nodeVar867 ) ) / knobs.resolution.x ), ( ( ( nodeVar865.y * nodeVar866 ) + ( nodeVar43.y * nodeVar867 ) ) / knobs.resolution.y ) ) );
		nodeVar864 = vec3<f32>( nodeVar868.x, nodeVar868.y, nodeVar868.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar869 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar870 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar871 = dot( nodeVar41, nodeVar870 );
		nodeVar872 = ( nodeVar590 - nodeVar45 );
		nodeVar873 = picture_read( vec2<f32>( ( ( ( nodeVar870.x * nodeVar871 ) + ( nodeVar43.x * nodeVar872 ) ) / knobs.resolution.x ), ( ( ( nodeVar870.y * nodeVar871 ) + ( nodeVar43.y * nodeVar872 ) ) / knobs.resolution.y ) ) );
		nodeVar869 = vec3<f32>( nodeVar873.x, nodeVar873.y, nodeVar873.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar874 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar875 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar876 = dot( nodeVar41, nodeVar875 );
		nodeVar877 = ( nodeVar657 - nodeVar45 );
		nodeVar878 = picture_read( vec2<f32>( ( ( ( nodeVar875.x * nodeVar876 ) + ( nodeVar43.x * nodeVar877 ) ) / knobs.resolution.x ), ( ( ( nodeVar875.y * nodeVar876 ) + ( nodeVar43.y * nodeVar877 ) ) / knobs.resolution.y ) ) );
		nodeVar874 = vec3<f32>( nodeVar878.x, nodeVar878.y, nodeVar878.z ).z;

	}


	if ( nodeVar2 ) {

		nodeVar879 = vec3<f32>( f32(0.9215686274509803), f32(0.9607843137254902), f32(1.0) ).z;

	} else {

		nodeVar880 = vec2<f32>( cos( nodeVar42 ), sin( nodeVar42 ) );
		nodeVar881 = dot( nodeVar41, nodeVar880 );
		nodeVar882 = ( nodeVar724 - nodeVar45 );
		nodeVar883 = picture_read( vec2<f32>( ( ( ( nodeVar880.x * nodeVar881 ) + ( nodeVar43.x * nodeVar882 ) ) / knobs.resolution.x ), ( ( ( nodeVar880.y * nodeVar881 ) + ( nodeVar43.y * nodeVar882 ) ) / knobs.resolution.y ) ) );
		nodeVar879 = vec3<f32>( nodeVar883.x, nodeVar883.y, nodeVar883.z ).z;

	}

	nodeVar884 = vec4<f32>( clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar1 * nodeVar103 ) ) + ( nodeVar104 * nodeVar170 ) ) + ( nodeVar171 * nodeVar237 ) ) + ( nodeVar238 * nodeVar304 ) ) + ( nodeVar305 * nodeVar371 ) ) + ( nodeVar372 * nodeVar438 ) ) + ( nodeVar439 * nodeVar505 ) ) + ( nodeVar506 * nodeVar572 ) ) + ( nodeVar573 * nodeVar639 ) ) + ( nodeVar640 * nodeVar706 ) ) + ( nodeVar707 * nodeVar773 ) ), 0.0, 1.0 ), clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar774 * nodeVar103 ) ) + ( nodeVar779 * nodeVar170 ) ) + ( nodeVar784 * nodeVar237 ) ) + ( nodeVar789 * nodeVar304 ) ) + ( nodeVar794 * nodeVar371 ) ) + ( nodeVar799 * nodeVar438 ) ) + ( nodeVar804 * nodeVar505 ) ) + ( nodeVar809 * nodeVar572 ) ) + ( nodeVar814 * nodeVar639 ) ) + ( nodeVar819 * nodeVar706 ) ) + ( nodeVar824 * nodeVar773 ) ), 0.0, 1.0 ), clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar829 * nodeVar103 ) ) + ( nodeVar834 * nodeVar170 ) ) + ( nodeVar839 * nodeVar237 ) ) + ( nodeVar844 * nodeVar304 ) ) + ( nodeVar849 * nodeVar371 ) ) + ( nodeVar854 * nodeVar438 ) ) + ( nodeVar859 * nodeVar505 ) ) + ( nodeVar864 * nodeVar572 ) ) + ( nodeVar869 * nodeVar639 ) ) + ( nodeVar874 * nodeVar706 ) ) + ( nodeVar879 * nodeVar773 ) ), 0.0, 1.0 ), 1.0 );
	nodeVar885 = vec3<f32>( nodeVar884.x, nodeVar884.y, nodeVar884.z );
	nodeVar886 = ( ( ( nodeVar885.x * 0.2126 ) + ( nodeVar885.y * 0.7152 ) ) + ( nodeVar885.z * 0.0722 ) );
	nodeVar887 = mix( vec3<f32>( nodeVar886, nodeVar886, nodeVar886 ), nodeVar885, f32(1.0) );
	nodeVar888 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar887.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar887.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar887.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar887.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar887.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar887.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar887.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar887.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar887.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar884.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar888.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar888.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar889 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar889;

	// result

	output.color = nodeVar889;

	output.color = to_shelf(output.color);
	return output;

}

// Halftone: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Turns the image into printed dot screens.
// --track@shape:Shape,0,3,0,1
// --track@spacing:Spacing,2,48,5,1
// --track@dotSize:Dot Size,0.1,3,1,0.01
// --track@dotMin:Dot Min,0,0.5,0,0.01
// --track@contrast:Contrast,0,2,1,0.01
// --track@softness:Softness,0,1,0.25,0.01
// --track@dotGain:Dot Gain,0,1,0,0.01
// --track@dotMorph:Dot Morph,0,1,0,0.01
// --check@invertLuma:Invert,0
// --track@gcr:Black Generation,0,1,0.5,0.01
// --track@cyanAngle:Cyan Angle,0,90,15,1
// --track@magentaAngle:Magenta Angle,0,90,75,1
// --track@yellowAngle:Yellow Angle,0,90,0,1
// --track@keyAngle:Key Angle,0,90,45,1
// --track@paperGrain:Paper Grain,0,0.5,0.15,0.01
// --track@registration:Registration,0,5,0,0.1
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
  paperGrain: f32,
  dotMin: f32,
  invertLuma: f32,
  cyanAngle: f32,
  registration: f32,
  spacing: f32,
  gcr: f32,
  contrast: f32,
  dotSize: f32,
  dotGain: f32,
  softness: f32,
  shape: f32,
  dotMorph: f32,
  magentaAngle: f32,
  yellowAngle: f32,
  keyAngle: f32,
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
var<private> nodeVar4 : vec3<f32>;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec4<f32>;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : vec2<f32>;
var<private> nodeVar10 : vec4<f32>;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : vec2<f32>;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : vec2<f32>;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : f32;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : vec2<f32>;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : vec2<f32>;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : vec2<f32>;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : vec4<f32>;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : vec2<f32>;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : vec4<f32>;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : f32;
var<private> nodeVar39 : vec2<f32>;
var<private> nodeVar40 : f32;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : f32;
var<private> nodeVar43 : vec2<f32>;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : f32;
var<private> nodeVar47 : vec2<f32>;
var<private> nodeVar48 : f32;
var<private> nodeVar49 : f32;
var<private> nodeVar50 : vec2<f32>;
var<private> nodeVar51 : f32;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : vec2<f32>;
var<private> nodeVar54 : vec4<f32>;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : vec2<f32>;
var<private> nodeVar57 : vec4<f32>;
var<private> nodeVar58 : f32;
var<private> nodeVar59 : f32;
var<private> nodeVar60 : f32;
var<private> nodeVar61 : vec2<f32>;
var<private> nodeVar62 : f32;
var<private> nodeVar63 : f32;
var<private> nodeVar64 : f32;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : f32;
var<private> nodeVar69 : vec2<f32>;
var<private> nodeVar70 : f32;
var<private> nodeVar71 : f32;
var<private> nodeVar72 : vec2<f32>;
var<private> nodeVar73 : f32;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : vec2<f32>;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : vec4<f32>;
var<private> nodeVar78 : f32;
var<private> nodeVar79 : vec2<f32>;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : vec4<f32>;
var<private> nodeVar82 : f32;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : vec2<f32>;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : f32;
var<private> nodeVar89 : vec2<f32>;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : f32;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : vec2<f32>;
var<private> nodeVar94 : f32;
var<private> nodeVar95 : f32;
var<private> nodeVar96 : vec2<f32>;
var<private> nodeVar97 : f32;
var<private> nodeVar98 : f32;
var<private> nodeVar99 : vec2<f32>;
var<private> nodeVar100 : f32;
var<private> nodeVar101 : f32;
var<private> nodeVar102 : vec4<f32>;
var<private> nodeVar103 : f32;
var<private> nodeVar104 : vec2<f32>;
var<private> nodeVar105 : f32;
var<private> nodeVar106 : f32;
var<private> nodeVar107 : vec4<f32>;
var<private> nodeVar108 : f32;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : f32;
var<private> nodeVar111 : vec2<f32>;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : f32;
var<private> nodeVar114 : f32;
var<private> nodeVar115 : vec2<f32>;
var<private> nodeVar116 : f32;
var<private> nodeVar117 : f32;
var<private> nodeVar118 : f32;
var<private> nodeVar119 : vec2<f32>;
var<private> nodeVar120 : f32;
var<private> nodeVar121 : f32;
var<private> nodeVar122 : vec2<f32>;
var<private> nodeVar123 : f32;
var<private> nodeVar124 : f32;
var<private> nodeVar125 : vec2<f32>;
var<private> nodeVar126 : f32;
var<private> nodeVar127 : vec4<f32>;
var<private> nodeVar128 : f32;
var<private> nodeVar129 : vec2<f32>;
var<private> nodeVar130 : f32;
var<private> nodeVar131 : vec4<f32>;
var<private> nodeVar132 : f32;
var<private> nodeVar133 : f32;
var<private> nodeVar134 : f32;
var<private> nodeVar135 : vec2<f32>;
var<private> nodeVar136 : f32;
var<private> nodeVar137 : f32;
var<private> nodeVar138 : f32;
var<private> nodeVar139 : vec2<f32>;
var<private> nodeVar140 : f32;
var<private> nodeVar141 : f32;
var<private> nodeVar142 : f32;
var<private> nodeVar143 : vec2<f32>;
var<private> nodeVar144 : f32;
var<private> nodeVar145 : f32;
var<private> nodeVar146 : vec2<f32>;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : f32;
var<private> nodeVar149 : vec2<f32>;
var<private> nodeVar150 : vec4<f32>;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : vec2<f32>;
var<private> nodeVar153 : vec4<f32>;
var<private> nodeVar154 : f32;
var<private> nodeVar155 : f32;
var<private> nodeVar156 : f32;
var<private> nodeVar157 : vec2<f32>;
var<private> nodeVar158 : f32;
var<private> nodeVar159 : f32;
var<private> nodeVar160 : f32;
var<private> nodeVar161 : vec2<f32>;
var<private> nodeVar162 : f32;
var<private> nodeVar163 : f32;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : vec2<f32>;
var<private> nodeVar166 : f32;
var<private> nodeVar167 : f32;
var<private> nodeVar168 : vec2<f32>;
var<private> nodeVar169 : f32;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : vec2<f32>;
var<private> nodeVar172 : f32;
var<private> nodeVar173 : vec4<f32>;
var<private> nodeVar174 : f32;
var<private> nodeVar175 : vec2<f32>;
var<private> nodeVar176 : f32;
var<private> nodeVar177 : vec4<f32>;
var<private> nodeVar178 : f32;
var<private> nodeVar179 : f32;
var<private> nodeVar180 : f32;
var<private> nodeVar181 : vec2<f32>;
var<private> nodeVar182 : f32;
var<private> nodeVar183 : f32;
var<private> nodeVar184 : f32;
var<private> nodeVar185 : vec2<f32>;
var<private> nodeVar186 : f32;
var<private> nodeVar187 : f32;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : vec2<f32>;
var<private> nodeVar190 : f32;
var<private> nodeVar191 : f32;
var<private> nodeVar192 : vec2<f32>;
var<private> nodeVar193 : f32;
var<private> nodeVar194 : f32;
var<private> nodeVar195 : vec2<f32>;
var<private> nodeVar196 : vec4<f32>;
var<private> nodeVar197 : f32;
var<private> nodeVar198 : vec2<f32>;
var<private> nodeVar199 : vec4<f32>;
var<private> nodeVar200 : f32;
var<private> nodeVar201 : f32;
var<private> nodeVar202 : f32;
var<private> nodeVar203 : vec2<f32>;
var<private> nodeVar204 : f32;
var<private> nodeVar205 : f32;
var<private> nodeVar206 : f32;
var<private> nodeVar207 : vec2<f32>;
var<private> nodeVar208 : f32;
var<private> nodeVar209 : f32;
var<private> nodeVar210 : f32;
var<private> nodeVar211 : vec2<f32>;
var<private> nodeVar212 : f32;
var<private> nodeVar213 : f32;
var<private> nodeVar214 : vec2<f32>;
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
var<private> nodeVar228 : vec3<f32>;
var<private> nodeVar229 : vec3<f32>;
var<private> nodeVar230 : f32;
var<private> nodeVar231 : vec2<f32>;
var<private> nodeVar232 : vec4<f32>;
var<private> nodeVar233 : f32;
var<private> nodeVar234 : vec2<f32>;
var<private> nodeVar235 : vec4<f32>;
var<private> nodeVar236 : f32;
var<private> nodeVar237 : f32;
var<private> nodeVar238 : f32;
var<private> nodeVar239 : f32;
var<private> nodeVar240 : vec2<f32>;
var<private> nodeVar241 : f32;
var<private> nodeVar242 : f32;
var<private> nodeVar243 : f32;
var<private> nodeVar244 : vec2<f32>;
var<private> nodeVar245 : f32;
var<private> nodeVar246 : f32;
var<private> nodeVar247 : f32;
var<private> nodeVar248 : vec2<f32>;
var<private> nodeVar249 : f32;
var<private> nodeVar250 : f32;
var<private> nodeVar251 : vec2<f32>;
var<private> nodeVar252 : f32;
var<private> nodeVar253 : f32;
var<private> nodeVar254 : vec2<f32>;
var<private> nodeVar255 : f32;
var<private> nodeVar256 : vec4<f32>;
var<private> nodeVar257 : f32;
var<private> nodeVar258 : vec2<f32>;
var<private> nodeVar259 : f32;
var<private> nodeVar260 : vec4<f32>;
var<private> nodeVar261 : f32;
var<private> nodeVar262 : f32;
var<private> nodeVar263 : f32;
var<private> nodeVar264 : vec2<f32>;
var<private> nodeVar265 : f32;
var<private> nodeVar266 : f32;
var<private> nodeVar267 : f32;
var<private> nodeVar268 : vec2<f32>;
var<private> nodeVar269 : f32;
var<private> nodeVar270 : f32;
var<private> nodeVar271 : f32;
var<private> nodeVar272 : vec2<f32>;
var<private> nodeVar273 : f32;
var<private> nodeVar274 : f32;
var<private> nodeVar275 : vec2<f32>;
var<private> nodeVar276 : f32;
var<private> nodeVar277 : f32;
var<private> nodeVar278 : vec2<f32>;
var<private> nodeVar279 : vec4<f32>;
var<private> nodeVar280 : f32;
var<private> nodeVar281 : vec2<f32>;
var<private> nodeVar282 : vec4<f32>;
var<private> nodeVar283 : f32;
var<private> nodeVar284 : f32;
var<private> nodeVar285 : f32;
var<private> nodeVar286 : vec2<f32>;
var<private> nodeVar287 : f32;
var<private> nodeVar288 : f32;
var<private> nodeVar289 : f32;
var<private> nodeVar290 : vec2<f32>;
var<private> nodeVar291 : f32;
var<private> nodeVar292 : f32;
var<private> nodeVar293 : f32;
var<private> nodeVar294 : vec2<f32>;
var<private> nodeVar295 : f32;
var<private> nodeVar296 : f32;
var<private> nodeVar297 : vec2<f32>;
var<private> nodeVar298 : f32;
var<private> nodeVar299 : f32;
var<private> nodeVar300 : vec2<f32>;
var<private> nodeVar301 : f32;
var<private> nodeVar302 : vec4<f32>;
var<private> nodeVar303 : f32;
var<private> nodeVar304 : vec2<f32>;
var<private> nodeVar305 : f32;
var<private> nodeVar306 : vec4<f32>;
var<private> nodeVar307 : f32;
var<private> nodeVar308 : f32;
var<private> nodeVar309 : f32;
var<private> nodeVar310 : vec2<f32>;
var<private> nodeVar311 : f32;
var<private> nodeVar312 : f32;
var<private> nodeVar313 : f32;
var<private> nodeVar314 : vec2<f32>;
var<private> nodeVar315 : f32;
var<private> nodeVar316 : f32;
var<private> nodeVar317 : f32;
var<private> nodeVar318 : vec2<f32>;
var<private> nodeVar319 : f32;
var<private> nodeVar320 : f32;
var<private> nodeVar321 : vec2<f32>;
var<private> nodeVar322 : f32;
var<private> nodeVar323 : f32;
var<private> nodeVar324 : vec2<f32>;
var<private> nodeVar325 : f32;
var<private> nodeVar326 : f32;
var<private> nodeVar327 : vec4<f32>;
var<private> nodeVar328 : f32;
var<private> nodeVar329 : vec2<f32>;
var<private> nodeVar330 : f32;
var<private> nodeVar331 : f32;
var<private> nodeVar332 : vec4<f32>;
var<private> nodeVar333 : f32;
var<private> nodeVar334 : f32;
var<private> nodeVar335 : f32;
var<private> nodeVar336 : vec2<f32>;
var<private> nodeVar337 : f32;
var<private> nodeVar338 : f32;
var<private> nodeVar339 : f32;
var<private> nodeVar340 : vec2<f32>;
var<private> nodeVar341 : f32;
var<private> nodeVar342 : f32;
var<private> nodeVar343 : f32;
var<private> nodeVar344 : vec2<f32>;
var<private> nodeVar345 : f32;
var<private> nodeVar346 : f32;
var<private> nodeVar347 : vec2<f32>;
var<private> nodeVar348 : f32;
var<private> nodeVar349 : f32;
var<private> nodeVar350 : vec2<f32>;
var<private> nodeVar351 : f32;
var<private> nodeVar352 : vec4<f32>;
var<private> nodeVar353 : f32;
var<private> nodeVar354 : vec2<f32>;
var<private> nodeVar355 : f32;
var<private> nodeVar356 : vec4<f32>;
var<private> nodeVar357 : f32;
var<private> nodeVar358 : f32;
var<private> nodeVar359 : f32;
var<private> nodeVar360 : vec2<f32>;
var<private> nodeVar361 : f32;
var<private> nodeVar362 : f32;
var<private> nodeVar363 : f32;
var<private> nodeVar364 : vec2<f32>;
var<private> nodeVar365 : f32;
var<private> nodeVar366 : f32;
var<private> nodeVar367 : f32;
var<private> nodeVar368 : vec2<f32>;
var<private> nodeVar369 : f32;
var<private> nodeVar370 : f32;
var<private> nodeVar371 : vec2<f32>;
var<private> nodeVar372 : f32;
var<private> nodeVar373 : f32;
var<private> nodeVar374 : vec2<f32>;
var<private> nodeVar375 : vec4<f32>;
var<private> nodeVar376 : f32;
var<private> nodeVar377 : vec2<f32>;
var<private> nodeVar378 : vec4<f32>;
var<private> nodeVar379 : f32;
var<private> nodeVar380 : f32;
var<private> nodeVar381 : f32;
var<private> nodeVar382 : vec2<f32>;
var<private> nodeVar383 : f32;
var<private> nodeVar384 : f32;
var<private> nodeVar385 : f32;
var<private> nodeVar386 : vec2<f32>;
var<private> nodeVar387 : f32;
var<private> nodeVar388 : f32;
var<private> nodeVar389 : f32;
var<private> nodeVar390 : vec2<f32>;
var<private> nodeVar391 : f32;
var<private> nodeVar392 : f32;
var<private> nodeVar393 : vec2<f32>;
var<private> nodeVar394 : f32;
var<private> nodeVar395 : f32;
var<private> nodeVar396 : vec2<f32>;
var<private> nodeVar397 : f32;
var<private> nodeVar398 : vec4<f32>;
var<private> nodeVar399 : f32;
var<private> nodeVar400 : vec2<f32>;
var<private> nodeVar401 : f32;
var<private> nodeVar402 : vec4<f32>;
var<private> nodeVar403 : f32;
var<private> nodeVar404 : f32;
var<private> nodeVar405 : f32;
var<private> nodeVar406 : vec2<f32>;
var<private> nodeVar407 : f32;
var<private> nodeVar408 : f32;
var<private> nodeVar409 : f32;
var<private> nodeVar410 : vec2<f32>;
var<private> nodeVar411 : f32;
var<private> nodeVar412 : f32;
var<private> nodeVar413 : f32;
var<private> nodeVar414 : vec2<f32>;
var<private> nodeVar415 : f32;
var<private> nodeVar416 : f32;
var<private> nodeVar417 : vec2<f32>;
var<private> nodeVar418 : f32;
var<private> nodeVar419 : f32;
var<private> nodeVar420 : vec2<f32>;
var<private> nodeVar421 : vec4<f32>;
var<private> nodeVar422 : f32;
var<private> nodeVar423 : vec2<f32>;
var<private> nodeVar424 : vec4<f32>;
var<private> nodeVar425 : f32;
var<private> nodeVar426 : f32;
var<private> nodeVar427 : f32;
var<private> nodeVar428 : vec2<f32>;
var<private> nodeVar429 : f32;
var<private> nodeVar430 : f32;
var<private> nodeVar431 : f32;
var<private> nodeVar432 : vec2<f32>;
var<private> nodeVar433 : f32;
var<private> nodeVar434 : f32;
var<private> nodeVar435 : f32;
var<private> nodeVar436 : vec2<f32>;
var<private> nodeVar437 : f32;
var<private> nodeVar438 : f32;
var<private> nodeVar439 : vec2<f32>;
var<private> nodeVar440 : f32;
var<private> nodeVar441 : f32;
var<private> nodeVar442 : f32;
var<private> nodeVar443 : f32;
var<private> nodeVar444 : f32;
var<private> nodeVar445 : f32;
var<private> nodeVar446 : f32;
var<private> nodeVar447 : f32;
var<private> nodeVar448 : f32;
var<private> nodeVar449 : f32;
var<private> nodeVar450 : f32;
var<private> nodeVar451 : f32;
var<private> nodeVar452 : f32;
var<private> nodeVar453 : vec3<f32>;
var<private> nodeVar454 : vec3<f32>;
var<private> nodeVar455 : f32;
var<private> nodeVar456 : vec2<f32>;
var<private> nodeVar457 : vec4<f32>;
var<private> nodeVar458 : f32;
var<private> nodeVar459 : vec2<f32>;
var<private> nodeVar460 : vec4<f32>;
var<private> nodeVar461 : f32;
var<private> nodeVar462 : f32;
var<private> nodeVar463 : f32;
var<private> nodeVar464 : f32;
var<private> nodeVar465 : vec2<f32>;
var<private> nodeVar466 : f32;
var<private> nodeVar467 : f32;
var<private> nodeVar468 : f32;
var<private> nodeVar469 : vec2<f32>;
var<private> nodeVar470 : f32;
var<private> nodeVar471 : f32;
var<private> nodeVar472 : f32;
var<private> nodeVar473 : vec2<f32>;
var<private> nodeVar474 : f32;
var<private> nodeVar475 : f32;
var<private> nodeVar476 : vec2<f32>;
var<private> nodeVar477 : f32;
var<private> nodeVar478 : f32;
var<private> nodeVar479 : vec2<f32>;
var<private> nodeVar480 : f32;
var<private> nodeVar481 : vec4<f32>;
var<private> nodeVar482 : f32;
var<private> nodeVar483 : vec2<f32>;
var<private> nodeVar484 : f32;
var<private> nodeVar485 : vec4<f32>;
var<private> nodeVar486 : f32;
var<private> nodeVar487 : f32;
var<private> nodeVar488 : f32;
var<private> nodeVar489 : vec2<f32>;
var<private> nodeVar490 : f32;
var<private> nodeVar491 : f32;
var<private> nodeVar492 : f32;
var<private> nodeVar493 : vec2<f32>;
var<private> nodeVar494 : f32;
var<private> nodeVar495 : f32;
var<private> nodeVar496 : f32;
var<private> nodeVar497 : vec2<f32>;
var<private> nodeVar498 : f32;
var<private> nodeVar499 : f32;
var<private> nodeVar500 : vec2<f32>;
var<private> nodeVar501 : f32;
var<private> nodeVar502 : f32;
var<private> nodeVar503 : vec2<f32>;
var<private> nodeVar504 : vec4<f32>;
var<private> nodeVar505 : f32;
var<private> nodeVar506 : vec2<f32>;
var<private> nodeVar507 : vec4<f32>;
var<private> nodeVar508 : f32;
var<private> nodeVar509 : f32;
var<private> nodeVar510 : f32;
var<private> nodeVar511 : vec2<f32>;
var<private> nodeVar512 : f32;
var<private> nodeVar513 : f32;
var<private> nodeVar514 : f32;
var<private> nodeVar515 : vec2<f32>;
var<private> nodeVar516 : f32;
var<private> nodeVar517 : f32;
var<private> nodeVar518 : f32;
var<private> nodeVar519 : vec2<f32>;
var<private> nodeVar520 : f32;
var<private> nodeVar521 : f32;
var<private> nodeVar522 : vec2<f32>;
var<private> nodeVar523 : f32;
var<private> nodeVar524 : f32;
var<private> nodeVar525 : vec2<f32>;
var<private> nodeVar526 : f32;
var<private> nodeVar527 : vec4<f32>;
var<private> nodeVar528 : f32;
var<private> nodeVar529 : vec2<f32>;
var<private> nodeVar530 : f32;
var<private> nodeVar531 : vec4<f32>;
var<private> nodeVar532 : f32;
var<private> nodeVar533 : f32;
var<private> nodeVar534 : f32;
var<private> nodeVar535 : vec2<f32>;
var<private> nodeVar536 : f32;
var<private> nodeVar537 : f32;
var<private> nodeVar538 : f32;
var<private> nodeVar539 : vec2<f32>;
var<private> nodeVar540 : f32;
var<private> nodeVar541 : f32;
var<private> nodeVar542 : f32;
var<private> nodeVar543 : vec2<f32>;
var<private> nodeVar544 : f32;
var<private> nodeVar545 : f32;
var<private> nodeVar546 : vec2<f32>;
var<private> nodeVar547 : f32;
var<private> nodeVar548 : f32;
var<private> nodeVar549 : vec2<f32>;
var<private> nodeVar550 : f32;
var<private> nodeVar551 : f32;
var<private> nodeVar552 : vec4<f32>;
var<private> nodeVar553 : f32;
var<private> nodeVar554 : vec2<f32>;
var<private> nodeVar555 : f32;
var<private> nodeVar556 : f32;
var<private> nodeVar557 : vec4<f32>;
var<private> nodeVar558 : f32;
var<private> nodeVar559 : f32;
var<private> nodeVar560 : f32;
var<private> nodeVar561 : vec2<f32>;
var<private> nodeVar562 : f32;
var<private> nodeVar563 : f32;
var<private> nodeVar564 : f32;
var<private> nodeVar565 : vec2<f32>;
var<private> nodeVar566 : f32;
var<private> nodeVar567 : f32;
var<private> nodeVar568 : f32;
var<private> nodeVar569 : vec2<f32>;
var<private> nodeVar570 : f32;
var<private> nodeVar571 : f32;
var<private> nodeVar572 : vec2<f32>;
var<private> nodeVar573 : f32;
var<private> nodeVar574 : f32;
var<private> nodeVar575 : vec2<f32>;
var<private> nodeVar576 : f32;
var<private> nodeVar577 : vec4<f32>;
var<private> nodeVar578 : f32;
var<private> nodeVar579 : vec2<f32>;
var<private> nodeVar580 : f32;
var<private> nodeVar581 : vec4<f32>;
var<private> nodeVar582 : f32;
var<private> nodeVar583 : f32;
var<private> nodeVar584 : f32;
var<private> nodeVar585 : vec2<f32>;
var<private> nodeVar586 : f32;
var<private> nodeVar587 : f32;
var<private> nodeVar588 : f32;
var<private> nodeVar589 : vec2<f32>;
var<private> nodeVar590 : f32;
var<private> nodeVar591 : f32;
var<private> nodeVar592 : f32;
var<private> nodeVar593 : vec2<f32>;
var<private> nodeVar594 : f32;
var<private> nodeVar595 : f32;
var<private> nodeVar596 : vec2<f32>;
var<private> nodeVar597 : f32;
var<private> nodeVar598 : f32;
var<private> nodeVar599 : vec2<f32>;
var<private> nodeVar600 : vec4<f32>;
var<private> nodeVar601 : f32;
var<private> nodeVar602 : vec2<f32>;
var<private> nodeVar603 : vec4<f32>;
var<private> nodeVar604 : f32;
var<private> nodeVar605 : f32;
var<private> nodeVar606 : f32;
var<private> nodeVar607 : vec2<f32>;
var<private> nodeVar608 : f32;
var<private> nodeVar609 : f32;
var<private> nodeVar610 : f32;
var<private> nodeVar611 : vec2<f32>;
var<private> nodeVar612 : f32;
var<private> nodeVar613 : f32;
var<private> nodeVar614 : f32;
var<private> nodeVar615 : vec2<f32>;
var<private> nodeVar616 : f32;
var<private> nodeVar617 : f32;
var<private> nodeVar618 : vec2<f32>;
var<private> nodeVar619 : f32;
var<private> nodeVar620 : f32;
var<private> nodeVar621 : vec2<f32>;
var<private> nodeVar622 : f32;
var<private> nodeVar623 : vec4<f32>;
var<private> nodeVar624 : f32;
var<private> nodeVar625 : vec2<f32>;
var<private> nodeVar626 : f32;
var<private> nodeVar627 : vec4<f32>;
var<private> nodeVar628 : f32;
var<private> nodeVar629 : f32;
var<private> nodeVar630 : f32;
var<private> nodeVar631 : vec2<f32>;
var<private> nodeVar632 : f32;
var<private> nodeVar633 : f32;
var<private> nodeVar634 : f32;
var<private> nodeVar635 : vec2<f32>;
var<private> nodeVar636 : f32;
var<private> nodeVar637 : f32;
var<private> nodeVar638 : f32;
var<private> nodeVar639 : vec2<f32>;
var<private> nodeVar640 : f32;
var<private> nodeVar641 : f32;
var<private> nodeVar642 : vec2<f32>;
var<private> nodeVar643 : f32;
var<private> nodeVar644 : f32;
var<private> nodeVar645 : vec2<f32>;
var<private> nodeVar646 : vec4<f32>;
var<private> nodeVar647 : f32;
var<private> nodeVar648 : vec2<f32>;
var<private> nodeVar649 : vec4<f32>;
var<private> nodeVar650 : f32;
var<private> nodeVar651 : f32;
var<private> nodeVar652 : f32;
var<private> nodeVar653 : vec2<f32>;
var<private> nodeVar654 : f32;
var<private> nodeVar655 : f32;
var<private> nodeVar656 : f32;
var<private> nodeVar657 : vec2<f32>;
var<private> nodeVar658 : f32;
var<private> nodeVar659 : f32;
var<private> nodeVar660 : f32;
var<private> nodeVar661 : vec2<f32>;
var<private> nodeVar662 : f32;
var<private> nodeVar663 : f32;
var<private> nodeVar664 : vec2<f32>;
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
var<private> nodeVar678 : vec3<f32>;
var<private> nodeVar679 : vec3<f32>;
var<private> nodeVar680 : f32;
var<private> nodeVar681 : vec2<f32>;
var<private> nodeVar682 : vec4<f32>;
var<private> nodeVar683 : vec2<f32>;
var<private> nodeVar684 : vec4<f32>;
var<private> nodeVar685 : f32;
var<private> nodeVar686 : f32;
var<private> nodeVar687 : f32;
var<private> nodeVar688 : vec2<f32>;
var<private> nodeVar689 : f32;
var<private> nodeVar690 : f32;
var<private> nodeVar691 : f32;
var<private> nodeVar692 : vec2<f32>;
var<private> nodeVar693 : f32;
var<private> nodeVar694 : f32;
var<private> nodeVar695 : f32;
var<private> nodeVar696 : vec2<f32>;
var<private> nodeVar697 : f32;
var<private> nodeVar698 : f32;
var<private> nodeVar699 : vec2<f32>;
var<private> nodeVar700 : f32;
var<private> nodeVar701 : f32;
var<private> nodeVar702 : vec2<f32>;
var<private> nodeVar703 : f32;
var<private> nodeVar704 : vec4<f32>;
var<private> nodeVar705 : vec2<f32>;
var<private> nodeVar706 : f32;
var<private> nodeVar707 : vec4<f32>;
var<private> nodeVar708 : f32;
var<private> nodeVar709 : f32;
var<private> nodeVar710 : vec2<f32>;
var<private> nodeVar711 : f32;
var<private> nodeVar712 : f32;
var<private> nodeVar713 : f32;
var<private> nodeVar714 : vec2<f32>;
var<private> nodeVar715 : f32;
var<private> nodeVar716 : f32;
var<private> nodeVar717 : f32;
var<private> nodeVar718 : vec2<f32>;
var<private> nodeVar719 : f32;
var<private> nodeVar720 : f32;
var<private> nodeVar721 : vec2<f32>;
var<private> nodeVar722 : f32;
var<private> nodeVar723 : f32;
var<private> nodeVar724 : vec2<f32>;
var<private> nodeVar725 : vec4<f32>;
var<private> nodeVar726 : vec2<f32>;
var<private> nodeVar727 : vec4<f32>;
var<private> nodeVar728 : f32;
var<private> nodeVar729 : f32;
var<private> nodeVar730 : vec2<f32>;
var<private> nodeVar731 : f32;
var<private> nodeVar732 : f32;
var<private> nodeVar733 : f32;
var<private> nodeVar734 : vec2<f32>;
var<private> nodeVar735 : f32;
var<private> nodeVar736 : f32;
var<private> nodeVar737 : f32;
var<private> nodeVar738 : vec2<f32>;
var<private> nodeVar739 : f32;
var<private> nodeVar740 : f32;
var<private> nodeVar741 : vec2<f32>;
var<private> nodeVar742 : f32;
var<private> nodeVar743 : f32;
var<private> nodeVar744 : vec2<f32>;
var<private> nodeVar745 : f32;
var<private> nodeVar746 : vec4<f32>;
var<private> nodeVar747 : vec2<f32>;
var<private> nodeVar748 : f32;
var<private> nodeVar749 : vec4<f32>;
var<private> nodeVar750 : f32;
var<private> nodeVar751 : f32;
var<private> nodeVar752 : vec2<f32>;
var<private> nodeVar753 : f32;
var<private> nodeVar754 : f32;
var<private> nodeVar755 : f32;
var<private> nodeVar756 : vec2<f32>;
var<private> nodeVar757 : f32;
var<private> nodeVar758 : f32;
var<private> nodeVar759 : f32;
var<private> nodeVar760 : vec2<f32>;
var<private> nodeVar761 : f32;
var<private> nodeVar762 : f32;
var<private> nodeVar763 : vec2<f32>;
var<private> nodeVar764 : f32;
var<private> nodeVar765 : f32;
var<private> nodeVar766 : vec2<f32>;
var<private> nodeVar767 : f32;
var<private> nodeVar768 : f32;
var<private> nodeVar769 : vec4<f32>;
var<private> nodeVar770 : vec2<f32>;
var<private> nodeVar771 : f32;
var<private> nodeVar772 : f32;
var<private> nodeVar773 : vec4<f32>;
var<private> nodeVar774 : f32;
var<private> nodeVar775 : f32;
var<private> nodeVar776 : vec2<f32>;
var<private> nodeVar777 : f32;
var<private> nodeVar778 : f32;
var<private> nodeVar779 : f32;
var<private> nodeVar780 : vec2<f32>;
var<private> nodeVar781 : f32;
var<private> nodeVar782 : f32;
var<private> nodeVar783 : f32;
var<private> nodeVar784 : vec2<f32>;
var<private> nodeVar785 : f32;
var<private> nodeVar786 : f32;
var<private> nodeVar787 : vec2<f32>;
var<private> nodeVar788 : f32;
var<private> nodeVar789 : f32;
var<private> nodeVar790 : vec2<f32>;
var<private> nodeVar791 : f32;
var<private> nodeVar792 : vec4<f32>;
var<private> nodeVar793 : vec2<f32>;
var<private> nodeVar794 : f32;
var<private> nodeVar795 : vec4<f32>;
var<private> nodeVar796 : f32;
var<private> nodeVar797 : f32;
var<private> nodeVar798 : vec2<f32>;
var<private> nodeVar799 : f32;
var<private> nodeVar800 : f32;
var<private> nodeVar801 : f32;
var<private> nodeVar802 : vec2<f32>;
var<private> nodeVar803 : f32;
var<private> nodeVar804 : f32;
var<private> nodeVar805 : f32;
var<private> nodeVar806 : vec2<f32>;
var<private> nodeVar807 : f32;
var<private> nodeVar808 : f32;
var<private> nodeVar809 : vec2<f32>;
var<private> nodeVar810 : f32;
var<private> nodeVar811 : f32;
var<private> nodeVar812 : vec2<f32>;
var<private> nodeVar813 : vec4<f32>;
var<private> nodeVar814 : vec2<f32>;
var<private> nodeVar815 : vec4<f32>;
var<private> nodeVar816 : f32;
var<private> nodeVar817 : f32;
var<private> nodeVar818 : vec2<f32>;
var<private> nodeVar819 : f32;
var<private> nodeVar820 : f32;
var<private> nodeVar821 : f32;
var<private> nodeVar822 : vec2<f32>;
var<private> nodeVar823 : f32;
var<private> nodeVar824 : f32;
var<private> nodeVar825 : f32;
var<private> nodeVar826 : vec2<f32>;
var<private> nodeVar827 : f32;
var<private> nodeVar828 : f32;
var<private> nodeVar829 : vec2<f32>;
var<private> nodeVar830 : f32;
var<private> nodeVar831 : f32;
var<private> nodeVar832 : vec2<f32>;
var<private> nodeVar833 : f32;
var<private> nodeVar834 : vec4<f32>;
var<private> nodeVar835 : vec2<f32>;
var<private> nodeVar836 : f32;
var<private> nodeVar837 : vec4<f32>;
var<private> nodeVar838 : f32;
var<private> nodeVar839 : f32;
var<private> nodeVar840 : vec2<f32>;
var<private> nodeVar841 : f32;
var<private> nodeVar842 : f32;
var<private> nodeVar843 : f32;
var<private> nodeVar844 : vec2<f32>;
var<private> nodeVar845 : f32;
var<private> nodeVar846 : f32;
var<private> nodeVar847 : f32;
var<private> nodeVar848 : vec2<f32>;
var<private> nodeVar849 : f32;
var<private> nodeVar850 : f32;
var<private> nodeVar851 : vec2<f32>;
var<private> nodeVar852 : f32;
var<private> nodeVar853 : f32;
var<private> nodeVar854 : vec2<f32>;
var<private> nodeVar855 : vec4<f32>;
var<private> nodeVar856 : vec2<f32>;
var<private> nodeVar857 : vec4<f32>;
var<private> nodeVar858 : f32;
var<private> nodeVar859 : f32;
var<private> nodeVar860 : vec2<f32>;
var<private> nodeVar861 : f32;
var<private> nodeVar862 : f32;
var<private> nodeVar863 : f32;
var<private> nodeVar864 : vec2<f32>;
var<private> nodeVar865 : f32;
var<private> nodeVar866 : f32;
var<private> nodeVar867 : f32;
var<private> nodeVar868 : vec2<f32>;
var<private> nodeVar869 : f32;
var<private> nodeVar870 : f32;
var<private> nodeVar871 : vec2<f32>;
var<private> nodeVar872 : f32;
var<private> nodeVar873 : f32;
var<private> nodeVar874 : f32;
var<private> nodeVar875 : f32;
var<private> nodeVar876 : f32;
var<private> nodeVar877 : f32;
var<private> nodeVar878 : f32;
var<private> nodeVar879 : f32;
var<private> nodeVar880 : f32;
var<private> nodeVar881 : f32;
var<private> nodeVar882 : f32;
var<private> nodeVar883 : f32;
var<private> nodeVar884 : f32;
var<private> nodeVar885 : vec3<f32>;
var<private> nodeVar886 : vec3<f32>;
var<private> nodeVar887 : vec4<f32>;
var<private> nodeVar888 : vec3<f32>;
var<private> nodeVar889 : f32;
var<private> nodeVar890 : vec3<f32>;
var<private> nodeVar891 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar892 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
	nodeVar3 = ( ( fract( ( sin( dot( ( nodeVar1 * nodeVar2 ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * knobs.paperGrain );
	nodeVar4 = vec3<f32>( clamp( ( f32(0.913098651791473) + nodeVar3 ), 0.0, 1.0 ), clamp( ( f32(0.913098651791473) + nodeVar3 ), 0.0, 1.0 ), clamp( ( f32(0.8713671191959567) + nodeVar3 ), 0.0, 1.0 ) );

	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar6 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar7 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar6.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar8 = ( ( 1.0 - max( max( nodeVar7.x, nodeVar7.y ), nodeVar7.z ) ) * knobs.gcr );
		nodeVar5 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar7.x ) - nodeVar8 ) / max( ( 1.0 - nodeVar8 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar9 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar10 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar9.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar11 = ( ( 1.0 - max( max( nodeVar10.x, nodeVar10.y ), nodeVar10.z ) ) * knobs.gcr );
		nodeVar5 = clamp( ( clamp( ( ( ( 1.0 - nodeVar10.x ) - nodeVar11 ) / max( ( 1.0 - nodeVar11 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar12 = ( ( ( ( knobs.dotMin + ( nodeVar5 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );
	nodeVar13 = max( 0.5, ( ( knobs.softness * knobs.spacing ) * 0.3 ) );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar15 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar16 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar15.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar15.y ) );
		nodeVar17 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar15.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar15.x ) );
		nodeVar14 = length( vec2<f32>( ( nodeVar16 - ( ( floor( ( ( nodeVar16 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar17 - ( ( floor( ( ( nodeVar17 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar19 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar20 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar19.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar19.y ) );
			nodeVar21 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar19.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar19.x ) );
			nodeVar18 = max( abs( ( nodeVar20 - ( ( floor( ( ( nodeVar20 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar21 - ( ( floor( ( ( nodeVar21 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar23 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar24 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar23.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar23.y ) );
				nodeVar25 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar23.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar23.x ) );
				nodeVar22 = ( abs( ( nodeVar24 - ( ( floor( ( ( nodeVar24 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar25 - ( ( floor( ( ( nodeVar25 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar26 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar27 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar26.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar26.x ) );
				nodeVar22 = abs( ( nodeVar27 - ( ( floor( ( ( nodeVar27 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar18 = nodeVar22;

		}

		nodeVar14 = nodeVar18;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar29 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar30 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar31 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar30 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar30 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar29.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar32 = ( ( 1.0 - max( max( nodeVar31.x, nodeVar31.y ), nodeVar31.z ) ) * knobs.gcr );
		nodeVar28 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar31.x ) - nodeVar32 ) / max( ( 1.0 - nodeVar32 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar33 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar34 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar35 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar34 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar34 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar33.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar36 = ( ( 1.0 - max( max( nodeVar35.x, nodeVar35.y ), nodeVar35.z ) ) * knobs.gcr );
		nodeVar28 = clamp( ( clamp( ( ( ( 1.0 - nodeVar35.x ) - nodeVar36 ) / max( ( 1.0 - nodeVar36 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar37 = ( ( ( ( knobs.dotMin + ( nodeVar28 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar39 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar40 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar39.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar39.y ) );
		nodeVar41 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar39.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar39.x ) );
		nodeVar38 = length( vec2<f32>( ( nodeVar40 - ( floor( ( ( nodeVar40 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar41 - ( ( floor( ( ( nodeVar41 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar43 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar44 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar43.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar43.y ) );
			nodeVar45 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar43.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar43.x ) );
			nodeVar42 = max( abs( ( nodeVar44 - ( floor( ( ( nodeVar44 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar45 - ( ( floor( ( ( nodeVar45 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar47 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar48 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar47.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar47.y ) );
				nodeVar49 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar47.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar47.x ) );
				nodeVar46 = ( abs( ( nodeVar48 - ( floor( ( ( nodeVar48 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar49 - ( ( floor( ( ( nodeVar49 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar50 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar51 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar50.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar50.x ) );
				nodeVar46 = abs( ( nodeVar51 - ( ( floor( ( ( nodeVar51 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar42 = nodeVar46;

		}

		nodeVar38 = nodeVar42;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar53 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar54 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar53.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar55 = ( ( 1.0 - max( max( nodeVar54.x, nodeVar54.y ), nodeVar54.z ) ) * knobs.gcr );
		nodeVar52 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar54.x ) - nodeVar55 ) / max( ( 1.0 - nodeVar55 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar56 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar57 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar56.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar58 = ( ( 1.0 - max( max( nodeVar57.x, nodeVar57.y ), nodeVar57.z ) ) * knobs.gcr );
		nodeVar52 = clamp( ( clamp( ( ( ( 1.0 - nodeVar57.x ) - nodeVar58 ) / max( ( 1.0 - nodeVar58 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar59 = ( ( ( ( knobs.dotMin + ( nodeVar52 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar61 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar62 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar61.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar61.y ) );
		nodeVar63 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar61.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar61.x ) );
		nodeVar60 = length( vec2<f32>( ( nodeVar62 - ( ( floor( ( ( nodeVar62 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar63 - ( ( floor( ( ( nodeVar63 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar65 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar66 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar65.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar65.y ) );
			nodeVar67 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar65.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar65.x ) );
			nodeVar64 = max( abs( ( nodeVar66 - ( ( floor( ( ( nodeVar66 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar67 - ( ( floor( ( ( nodeVar67 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar69 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar70 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar69.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar69.y ) );
				nodeVar71 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar69.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar69.x ) );
				nodeVar68 = ( abs( ( nodeVar70 - ( ( floor( ( ( nodeVar70 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar71 - ( ( floor( ( ( nodeVar71 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar72 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar73 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar72.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar72.x ) );
				nodeVar68 = abs( ( nodeVar73 - ( ( floor( ( ( nodeVar73 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar64 = nodeVar68;

		}

		nodeVar60 = nodeVar64;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar75 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar76 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar77 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar76 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar75.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar76 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar78 = ( ( 1.0 - max( max( nodeVar77.x, nodeVar77.y ), nodeVar77.z ) ) * knobs.gcr );
		nodeVar74 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar77.x ) - nodeVar78 ) / max( ( 1.0 - nodeVar78 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar79 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar80 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar81 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar80 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar79.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar80 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar82 = ( ( 1.0 - max( max( nodeVar81.x, nodeVar81.y ), nodeVar81.z ) ) * knobs.gcr );
		nodeVar74 = clamp( ( clamp( ( ( ( 1.0 - nodeVar81.x ) - nodeVar82 ) / max( ( 1.0 - nodeVar82 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar83 = ( ( ( ( knobs.dotMin + ( nodeVar74 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar85 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar86 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar85.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar85.y ) );
		nodeVar87 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar85.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar85.x ) );
		nodeVar84 = length( vec2<f32>( ( nodeVar86 - ( ( floor( ( ( nodeVar86 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar87 - ( floor( ( ( nodeVar87 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar89 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar90 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar89.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar89.y ) );
			nodeVar91 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar89.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar89.x ) );
			nodeVar88 = max( abs( ( nodeVar90 - ( ( floor( ( ( nodeVar90 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar91 - ( floor( ( ( nodeVar91 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar93 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar94 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar93.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar93.y ) );
				nodeVar95 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar93.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar93.x ) );
				nodeVar92 = ( abs( ( nodeVar94 - ( ( floor( ( ( nodeVar94 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar95 - ( floor( ( ( nodeVar95 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar96 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar97 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar96.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar96.x ) );
				nodeVar92 = abs( ( nodeVar97 - ( floor( ( ( nodeVar97 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar88 = nodeVar92;

		}

		nodeVar84 = nodeVar88;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar99 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar100 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar99.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar99.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar101 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar99.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar99.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar102 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar100 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar101 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar100 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar101 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar103 = ( ( 1.0 - max( max( nodeVar102.x, nodeVar102.y ), nodeVar102.z ) ) * knobs.gcr );
		nodeVar98 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar102.x ) - nodeVar103 ) / max( ( 1.0 - nodeVar103 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar104 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar105 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar104.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar104.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar106 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar104.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar104.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar107 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar105 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar106 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar105 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar106 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar108 = ( ( 1.0 - max( max( nodeVar107.x, nodeVar107.y ), nodeVar107.z ) ) * knobs.gcr );
		nodeVar98 = clamp( ( clamp( ( ( ( 1.0 - nodeVar107.x ) - nodeVar108 ) / max( ( 1.0 - nodeVar108 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar109 = ( ( ( ( knobs.dotMin + ( nodeVar98 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar111 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar112 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar111.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar111.y ) );
		nodeVar113 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar111.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar111.x ) );
		nodeVar110 = length( vec2<f32>( ( nodeVar112 - ( floor( ( ( nodeVar112 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar113 - ( floor( ( ( nodeVar113 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar115 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar116 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar115.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar115.y ) );
			nodeVar117 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar115.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar115.x ) );
			nodeVar114 = max( abs( ( nodeVar116 - ( floor( ( ( nodeVar116 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar117 - ( floor( ( ( nodeVar117 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar119 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar120 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar119.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar119.y ) );
				nodeVar121 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar119.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar119.x ) );
				nodeVar118 = ( abs( ( nodeVar120 - ( floor( ( ( nodeVar120 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar121 - ( floor( ( ( nodeVar121 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar122 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar123 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar122.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar122.x ) );
				nodeVar118 = abs( ( nodeVar123 - ( floor( ( ( nodeVar123 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar114 = nodeVar118;

		}

		nodeVar110 = nodeVar114;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar125 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar126 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar127 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar126 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar125.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar126 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar128 = ( ( 1.0 - max( max( nodeVar127.x, nodeVar127.y ), nodeVar127.z ) ) * knobs.gcr );
		nodeVar124 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar127.x ) - nodeVar128 ) / max( ( 1.0 - nodeVar128 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar129 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar130 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar131 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar130 ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar129.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar130 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar132 = ( ( 1.0 - max( max( nodeVar131.x, nodeVar131.y ), nodeVar131.z ) ) * knobs.gcr );
		nodeVar124 = clamp( ( clamp( ( ( ( 1.0 - nodeVar131.x ) - nodeVar132 ) / max( ( 1.0 - nodeVar132 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar133 = ( ( ( ( knobs.dotMin + ( nodeVar124 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar135 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar136 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar135.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar135.y ) );
		nodeVar137 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar135.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar135.x ) );
		nodeVar134 = length( vec2<f32>( ( nodeVar136 - ( ( floor( ( ( nodeVar136 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar137 - ( floor( ( ( nodeVar137 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar139 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar140 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar139.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar139.y ) );
			nodeVar141 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar139.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar139.x ) );
			nodeVar138 = max( abs( ( nodeVar140 - ( ( floor( ( ( nodeVar140 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar141 - ( floor( ( ( nodeVar141 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar143 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar144 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar143.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar143.y ) );
				nodeVar145 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar143.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar143.x ) );
				nodeVar142 = ( abs( ( nodeVar144 - ( ( floor( ( ( nodeVar144 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar145 - ( floor( ( ( nodeVar145 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar146 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar147 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar146.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar146.x ) );
				nodeVar142 = abs( ( nodeVar147 - ( floor( ( ( nodeVar147 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar138 = nodeVar142;

		}

		nodeVar134 = nodeVar138;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar149 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar150 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar149.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar151 = ( ( 1.0 - max( max( nodeVar150.x, nodeVar150.y ), nodeVar150.z ) ) * knobs.gcr );
		nodeVar148 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar150.x ) - nodeVar151 ) / max( ( 1.0 - nodeVar151 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar152 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar153 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar152.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar154 = ( ( 1.0 - max( max( nodeVar153.x, nodeVar153.y ), nodeVar153.z ) ) * knobs.gcr );
		nodeVar148 = clamp( ( clamp( ( ( ( 1.0 - nodeVar153.x ) - nodeVar154 ) / max( ( 1.0 - nodeVar154 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar155 = ( ( ( ( knobs.dotMin + ( nodeVar148 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar157 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar158 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar157.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar157.y ) );
		nodeVar159 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar157.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar157.x ) );
		nodeVar156 = length( vec2<f32>( ( nodeVar158 - ( ( floor( ( ( nodeVar158 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar159 - ( ( floor( ( ( nodeVar159 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar161 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar162 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar161.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar161.y ) );
			nodeVar163 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar161.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar161.x ) );
			nodeVar160 = max( abs( ( nodeVar162 - ( ( floor( ( ( nodeVar162 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar163 - ( ( floor( ( ( nodeVar163 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar165 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar166 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar165.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar165.y ) );
				nodeVar167 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar165.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar165.x ) );
				nodeVar164 = ( abs( ( nodeVar166 - ( ( floor( ( ( nodeVar166 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar167 - ( ( floor( ( ( nodeVar167 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar168 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar169 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar168.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar168.x ) );
				nodeVar164 = abs( ( nodeVar169 - ( ( floor( ( ( nodeVar169 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar160 = nodeVar164;

		}

		nodeVar156 = nodeVar160;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar171 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar172 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar173 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar172 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar172 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar171.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar174 = ( ( 1.0 - max( max( nodeVar173.x, nodeVar173.y ), nodeVar173.z ) ) * knobs.gcr );
		nodeVar170 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar173.x ) - nodeVar174 ) / max( ( 1.0 - nodeVar174 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar175 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar176 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar177 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar176 ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar176 ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar175.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar178 = ( ( 1.0 - max( max( nodeVar177.x, nodeVar177.y ), nodeVar177.z ) ) * knobs.gcr );
		nodeVar170 = clamp( ( clamp( ( ( ( 1.0 - nodeVar177.x ) - nodeVar178 ) / max( ( 1.0 - nodeVar178 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar179 = ( ( ( ( knobs.dotMin + ( nodeVar170 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar181 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar182 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar181.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar181.y ) );
		nodeVar183 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar181.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar181.x ) );
		nodeVar180 = length( vec2<f32>( ( nodeVar182 - ( floor( ( ( nodeVar182 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar183 - ( ( floor( ( ( nodeVar183 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar185 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar186 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar185.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar185.y ) );
			nodeVar187 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar185.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar185.x ) );
			nodeVar184 = max( abs( ( nodeVar186 - ( floor( ( ( nodeVar186 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar187 - ( ( floor( ( ( nodeVar187 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar189 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar190 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar189.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar189.y ) );
				nodeVar191 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar189.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar189.x ) );
				nodeVar188 = ( abs( ( nodeVar190 - ( floor( ( ( nodeVar190 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar191 - ( ( floor( ( ( nodeVar191 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar192 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar193 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar192.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar192.x ) );
				nodeVar188 = abs( ( nodeVar193 - ( ( floor( ( ( nodeVar193 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar184 = nodeVar188;

		}

		nodeVar180 = nodeVar184;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar195 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar196 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar195.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar197 = ( ( 1.0 - max( max( nodeVar196.x, nodeVar196.y ), nodeVar196.z ) ) * knobs.gcr );
		nodeVar194 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar196.x ) - nodeVar197 ) / max( ( 1.0 - nodeVar197 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar198 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar199 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar198.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar200 = ( ( 1.0 - max( max( nodeVar199.x, nodeVar199.y ), nodeVar199.z ) ) * knobs.gcr );
		nodeVar194 = clamp( ( clamp( ( ( ( 1.0 - nodeVar199.x ) - nodeVar200 ) / max( ( 1.0 - nodeVar200 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar201 = ( ( ( ( knobs.dotMin + ( nodeVar194 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar203 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
		nodeVar204 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar203.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar203.y ) );
		nodeVar205 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar203.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar203.x ) );
		nodeVar202 = length( vec2<f32>( ( nodeVar204 - ( ( floor( ( ( nodeVar204 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar205 - ( ( floor( ( ( nodeVar205 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar207 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
			nodeVar208 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar207.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar207.y ) );
			nodeVar209 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar207.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar207.x ) );
			nodeVar206 = max( abs( ( nodeVar208 - ( ( floor( ( ( nodeVar208 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar209 - ( ( floor( ( ( nodeVar209 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar211 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar212 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar211.x ) + ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar211.y ) );
				nodeVar213 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar211.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar211.x ) );
				nodeVar210 = ( abs( ( nodeVar212 - ( ( floor( ( ( nodeVar212 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar213 - ( ( floor( ( ( nodeVar213 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar214 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( knobs.registration, 0.0 ) );
				nodeVar215 = ( ( cos( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar214.y ) - ( sin( (0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17) ) * nodeVar214.x ) );
				nodeVar210 = abs( ( nodeVar215 - ( ( floor( ( ( nodeVar215 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar206 = nodeVar210;

		}

		nodeVar202 = nodeVar206;

	}

	nodeVar216 = max( 0.01, ( ( nodeVar13 / knobs.spacing ) * 0.5 ) );
	nodeVar217 = clamp( knobs.dotMorph, 0.0, 1.0 );
	nodeVar218 = ( ( knobs.spacing * nodeVar217 ) * 0.6 );
	nodeVar219 = clamp( ( 1.0 - ( nodeVar202 / max( ( nodeVar201 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar220 = clamp( ( 1.0 - ( nodeVar180 / max( ( nodeVar179 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar221 = clamp( ( 1.0 - ( nodeVar156 / max( ( nodeVar155 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar222 = clamp( ( 1.0 - ( nodeVar134 / max( ( nodeVar133 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar223 = clamp( ( 1.0 - ( nodeVar110 / max( ( nodeVar109 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar224 = clamp( ( 1.0 - ( nodeVar84 / max( ( nodeVar83 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar225 = clamp( ( 1.0 - ( nodeVar60 / max( ( nodeVar59 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar226 = clamp( ( 1.0 - ( nodeVar38 / max( ( nodeVar37 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar227 = clamp( ( 1.0 - ( nodeVar14 / max( ( nodeVar12 + nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar228 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(0.0, 0.4232676699760063, 0.8631572134510892).x, vec3<f32>(0.0, 0.4232676699760063, 0.8631572134510892).y, vec3<f32>(0.0, 0.4232676699760063, 0.8631572134510892).z ), mix( max( smoothstep( ( nodeVar12 + nodeVar13 ), ( nodeVar12 - nodeVar13 ), nodeVar14 ), max( smoothstep( ( nodeVar37 + nodeVar13 ), ( nodeVar37 - nodeVar13 ), nodeVar38 ), max( smoothstep( ( nodeVar59 + nodeVar13 ), ( nodeVar59 - nodeVar13 ), nodeVar60 ), max( smoothstep( ( nodeVar83 + nodeVar13 ), ( nodeVar83 - nodeVar13 ), nodeVar84 ), max( smoothstep( ( nodeVar109 + nodeVar13 ), ( nodeVar109 - nodeVar13 ), nodeVar110 ), max( smoothstep( ( nodeVar133 + nodeVar13 ), ( nodeVar133 - nodeVar13 ), nodeVar134 ), max( smoothstep( ( nodeVar155 + nodeVar13 ), ( nodeVar155 - nodeVar13 ), nodeVar156 ), max( smoothstep( ( nodeVar179 + nodeVar13 ), ( nodeVar179 - nodeVar13 ), nodeVar180 ), max( smoothstep( ( nodeVar201 + nodeVar13 ), ( nodeVar201 - nodeVar13 ), nodeVar202 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - nodeVar216 ), ( 0.5 + nodeVar216 ), ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar219 * nodeVar219 ) ) + ( nodeVar220 * nodeVar220 ) ) + ( nodeVar221 * nodeVar221 ) ) + ( nodeVar222 * nodeVar222 ) ) + ( nodeVar223 * nodeVar223 ) ) + ( nodeVar224 * nodeVar224 ) ) + ( nodeVar225 * nodeVar225 ) ) + ( nodeVar226 * nodeVar226 ) ) + ( nodeVar227 * nodeVar227 ) ) ), nodeVar217 ) );
	nodeVar229 = vec3<f32>( ( nodeVar4.x * nodeVar228.x ), ( nodeVar4.y * nodeVar228.y ), ( nodeVar4.z * nodeVar228.z ) );

	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar231 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar232 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar231.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar233 = ( ( 1.0 - max( max( nodeVar232.x, nodeVar232.y ), nodeVar232.z ) ) * knobs.gcr );
		nodeVar230 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar232.y ) - nodeVar233 ) / max( ( 1.0 - nodeVar233 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar234 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar235 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar234.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar236 = ( ( 1.0 - max( max( nodeVar235.x, nodeVar235.y ), nodeVar235.z ) ) * knobs.gcr );
		nodeVar230 = clamp( ( clamp( ( ( ( 1.0 - nodeVar235.y ) - nodeVar236 ) / max( ( 1.0 - nodeVar236 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar237 = ( ( ( ( knobs.dotMin + ( nodeVar230 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );
	nodeVar238 = max( 0.5, ( ( knobs.softness * knobs.spacing ) * 0.3 ) );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar240 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar241 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar240.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar240.y ) );
		nodeVar242 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar240.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar240.x ) );
		nodeVar239 = length( vec2<f32>( ( nodeVar241 - ( ( floor( ( ( nodeVar241 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar242 - ( ( floor( ( ( nodeVar242 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar244 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar245 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar244.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar244.y ) );
			nodeVar246 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar244.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar244.x ) );
			nodeVar243 = max( abs( ( nodeVar245 - ( ( floor( ( ( nodeVar245 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar246 - ( ( floor( ( ( nodeVar246 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar248 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar249 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar248.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar248.y ) );
				nodeVar250 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar248.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar248.x ) );
				nodeVar247 = ( abs( ( nodeVar249 - ( ( floor( ( ( nodeVar249 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar250 - ( ( floor( ( ( nodeVar250 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar251 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar252 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar251.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar251.x ) );
				nodeVar247 = abs( ( nodeVar252 - ( ( floor( ( ( nodeVar252 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar243 = nodeVar247;

		}

		nodeVar239 = nodeVar243;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar254 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar255 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar256 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar255 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar255 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar254.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar257 = ( ( 1.0 - max( max( nodeVar256.x, nodeVar256.y ), nodeVar256.z ) ) * knobs.gcr );
		nodeVar253 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar256.y ) - nodeVar257 ) / max( ( 1.0 - nodeVar257 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar258 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar259 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar260 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar259 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar259 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar258.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar261 = ( ( 1.0 - max( max( nodeVar260.x, nodeVar260.y ), nodeVar260.z ) ) * knobs.gcr );
		nodeVar253 = clamp( ( clamp( ( ( ( 1.0 - nodeVar260.y ) - nodeVar261 ) / max( ( 1.0 - nodeVar261 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar262 = ( ( ( ( knobs.dotMin + ( nodeVar253 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar264 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar265 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar264.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar264.y ) );
		nodeVar266 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar264.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar264.x ) );
		nodeVar263 = length( vec2<f32>( ( nodeVar265 - ( floor( ( ( nodeVar265 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar266 - ( ( floor( ( ( nodeVar266 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar268 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar269 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar268.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar268.y ) );
			nodeVar270 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar268.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar268.x ) );
			nodeVar267 = max( abs( ( nodeVar269 - ( floor( ( ( nodeVar269 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar270 - ( ( floor( ( ( nodeVar270 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar272 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar273 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar272.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar272.y ) );
				nodeVar274 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar272.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar272.x ) );
				nodeVar271 = ( abs( ( nodeVar273 - ( floor( ( ( nodeVar273 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar274 - ( ( floor( ( ( nodeVar274 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar275 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar276 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar275.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar275.x ) );
				nodeVar271 = abs( ( nodeVar276 - ( ( floor( ( ( nodeVar276 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar267 = nodeVar271;

		}

		nodeVar263 = nodeVar267;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar278 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar279 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar278.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar280 = ( ( 1.0 - max( max( nodeVar279.x, nodeVar279.y ), nodeVar279.z ) ) * knobs.gcr );
		nodeVar277 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar279.y ) - nodeVar280 ) / max( ( 1.0 - nodeVar280 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar281 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar282 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar281.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar283 = ( ( 1.0 - max( max( nodeVar282.x, nodeVar282.y ), nodeVar282.z ) ) * knobs.gcr );
		nodeVar277 = clamp( ( clamp( ( ( ( 1.0 - nodeVar282.y ) - nodeVar283 ) / max( ( 1.0 - nodeVar283 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar284 = ( ( ( ( knobs.dotMin + ( nodeVar277 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar286 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar287 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar286.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar286.y ) );
		nodeVar288 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar286.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar286.x ) );
		nodeVar285 = length( vec2<f32>( ( nodeVar287 - ( ( floor( ( ( nodeVar287 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar288 - ( ( floor( ( ( nodeVar288 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar290 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar291 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar290.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar290.y ) );
			nodeVar292 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar290.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar290.x ) );
			nodeVar289 = max( abs( ( nodeVar291 - ( ( floor( ( ( nodeVar291 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar292 - ( ( floor( ( ( nodeVar292 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar294 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar295 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar294.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar294.y ) );
				nodeVar296 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar294.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar294.x ) );
				nodeVar293 = ( abs( ( nodeVar295 - ( ( floor( ( ( nodeVar295 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar296 - ( ( floor( ( ( nodeVar296 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar297 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar298 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar297.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar297.x ) );
				nodeVar293 = abs( ( nodeVar298 - ( ( floor( ( ( nodeVar298 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar289 = nodeVar293;

		}

		nodeVar285 = nodeVar289;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar300 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar301 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar302 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar301 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar300.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar301 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar303 = ( ( 1.0 - max( max( nodeVar302.x, nodeVar302.y ), nodeVar302.z ) ) * knobs.gcr );
		nodeVar299 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar302.y ) - nodeVar303 ) / max( ( 1.0 - nodeVar303 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar304 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar305 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar306 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar305 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar304.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar305 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar307 = ( ( 1.0 - max( max( nodeVar306.x, nodeVar306.y ), nodeVar306.z ) ) * knobs.gcr );
		nodeVar299 = clamp( ( clamp( ( ( ( 1.0 - nodeVar306.y ) - nodeVar307 ) / max( ( 1.0 - nodeVar307 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar308 = ( ( ( ( knobs.dotMin + ( nodeVar299 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar310 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar311 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar310.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar310.y ) );
		nodeVar312 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar310.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar310.x ) );
		nodeVar309 = length( vec2<f32>( ( nodeVar311 - ( ( floor( ( ( nodeVar311 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar312 - ( floor( ( ( nodeVar312 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar314 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar315 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar314.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar314.y ) );
			nodeVar316 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar314.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar314.x ) );
			nodeVar313 = max( abs( ( nodeVar315 - ( ( floor( ( ( nodeVar315 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar316 - ( floor( ( ( nodeVar316 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar318 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar319 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar318.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar318.y ) );
				nodeVar320 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar318.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar318.x ) );
				nodeVar317 = ( abs( ( nodeVar319 - ( ( floor( ( ( nodeVar319 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar320 - ( floor( ( ( nodeVar320 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar321 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar322 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar321.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar321.x ) );
				nodeVar317 = abs( ( nodeVar322 - ( floor( ( ( nodeVar322 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar313 = nodeVar317;

		}

		nodeVar309 = nodeVar313;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar324 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar325 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar324.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar324.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar326 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar324.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar324.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar327 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar325 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar326 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar325 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar326 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar328 = ( ( 1.0 - max( max( nodeVar327.x, nodeVar327.y ), nodeVar327.z ) ) * knobs.gcr );
		nodeVar323 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar327.y ) - nodeVar328 ) / max( ( 1.0 - nodeVar328 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar329 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar330 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar329.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar329.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar331 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar329.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar329.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar332 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar330 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar331 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar330 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar331 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar333 = ( ( 1.0 - max( max( nodeVar332.x, nodeVar332.y ), nodeVar332.z ) ) * knobs.gcr );
		nodeVar323 = clamp( ( clamp( ( ( ( 1.0 - nodeVar332.y ) - nodeVar333 ) / max( ( 1.0 - nodeVar333 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar334 = ( ( ( ( knobs.dotMin + ( nodeVar323 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar336 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar337 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar336.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar336.y ) );
		nodeVar338 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar336.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar336.x ) );
		nodeVar335 = length( vec2<f32>( ( nodeVar337 - ( floor( ( ( nodeVar337 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar338 - ( floor( ( ( nodeVar338 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar340 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar341 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar340.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar340.y ) );
			nodeVar342 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar340.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar340.x ) );
			nodeVar339 = max( abs( ( nodeVar341 - ( floor( ( ( nodeVar341 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar342 - ( floor( ( ( nodeVar342 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar344 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar345 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar344.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar344.y ) );
				nodeVar346 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar344.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar344.x ) );
				nodeVar343 = ( abs( ( nodeVar345 - ( floor( ( ( nodeVar345 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar346 - ( floor( ( ( nodeVar346 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar347 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar348 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar347.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar347.x ) );
				nodeVar343 = abs( ( nodeVar348 - ( floor( ( ( nodeVar348 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar339 = nodeVar343;

		}

		nodeVar335 = nodeVar339;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar350 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar351 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar352 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar351 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar350.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar351 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar353 = ( ( 1.0 - max( max( nodeVar352.x, nodeVar352.y ), nodeVar352.z ) ) * knobs.gcr );
		nodeVar349 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar352.y ) - nodeVar353 ) / max( ( 1.0 - nodeVar353 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar354 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar355 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar356 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar355 ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar354.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar355 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar357 = ( ( 1.0 - max( max( nodeVar356.x, nodeVar356.y ), nodeVar356.z ) ) * knobs.gcr );
		nodeVar349 = clamp( ( clamp( ( ( ( 1.0 - nodeVar356.y ) - nodeVar357 ) / max( ( 1.0 - nodeVar357 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar358 = ( ( ( ( knobs.dotMin + ( nodeVar349 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar360 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar361 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar360.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar360.y ) );
		nodeVar362 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar360.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar360.x ) );
		nodeVar359 = length( vec2<f32>( ( nodeVar361 - ( ( floor( ( ( nodeVar361 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar362 - ( floor( ( ( nodeVar362 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar364 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar365 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar364.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar364.y ) );
			nodeVar366 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar364.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar364.x ) );
			nodeVar363 = max( abs( ( nodeVar365 - ( ( floor( ( ( nodeVar365 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar366 - ( floor( ( ( nodeVar366 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar368 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar369 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar368.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar368.y ) );
				nodeVar370 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar368.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar368.x ) );
				nodeVar367 = ( abs( ( nodeVar369 - ( ( floor( ( ( nodeVar369 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar370 - ( floor( ( ( nodeVar370 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar371 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar372 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar371.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar371.x ) );
				nodeVar367 = abs( ( nodeVar372 - ( floor( ( ( nodeVar372 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar363 = nodeVar367;

		}

		nodeVar359 = nodeVar363;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar374 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar375 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar374.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar376 = ( ( 1.0 - max( max( nodeVar375.x, nodeVar375.y ), nodeVar375.z ) ) * knobs.gcr );
		nodeVar373 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar375.y ) - nodeVar376 ) / max( ( 1.0 - nodeVar376 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar377 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar378 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar377.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar379 = ( ( 1.0 - max( max( nodeVar378.x, nodeVar378.y ), nodeVar378.z ) ) * knobs.gcr );
		nodeVar373 = clamp( ( clamp( ( ( ( 1.0 - nodeVar378.y ) - nodeVar379 ) / max( ( 1.0 - nodeVar379 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar380 = ( ( ( ( knobs.dotMin + ( nodeVar373 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar382 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar383 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar382.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar382.y ) );
		nodeVar384 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar382.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar382.x ) );
		nodeVar381 = length( vec2<f32>( ( nodeVar383 - ( ( floor( ( ( nodeVar383 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar384 - ( ( floor( ( ( nodeVar384 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar386 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar387 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar386.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar386.y ) );
			nodeVar388 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar386.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar386.x ) );
			nodeVar385 = max( abs( ( nodeVar387 - ( ( floor( ( ( nodeVar387 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar388 - ( ( floor( ( ( nodeVar388 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar390 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar391 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar390.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar390.y ) );
				nodeVar392 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar390.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar390.x ) );
				nodeVar389 = ( abs( ( nodeVar391 - ( ( floor( ( ( nodeVar391 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar392 - ( ( floor( ( ( nodeVar392 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar393 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar394 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar393.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar393.x ) );
				nodeVar389 = abs( ( nodeVar394 - ( ( floor( ( ( nodeVar394 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar385 = nodeVar389;

		}

		nodeVar381 = nodeVar385;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar396 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar397 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar398 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar397 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar397 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar396.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar399 = ( ( 1.0 - max( max( nodeVar398.x, nodeVar398.y ), nodeVar398.z ) ) * knobs.gcr );
		nodeVar395 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar398.y ) - nodeVar399 ) / max( ( 1.0 - nodeVar399 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar400 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar401 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar402 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar401 ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar401 ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar400.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar403 = ( ( 1.0 - max( max( nodeVar402.x, nodeVar402.y ), nodeVar402.z ) ) * knobs.gcr );
		nodeVar395 = clamp( ( clamp( ( ( ( 1.0 - nodeVar402.y ) - nodeVar403 ) / max( ( 1.0 - nodeVar403 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar404 = ( ( ( ( knobs.dotMin + ( nodeVar395 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar406 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar407 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar406.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar406.y ) );
		nodeVar408 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar406.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar406.x ) );
		nodeVar405 = length( vec2<f32>( ( nodeVar407 - ( floor( ( ( nodeVar407 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar408 - ( ( floor( ( ( nodeVar408 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar410 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar411 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar410.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar410.y ) );
			nodeVar412 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar410.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar410.x ) );
			nodeVar409 = max( abs( ( nodeVar411 - ( floor( ( ( nodeVar411 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar412 - ( ( floor( ( ( nodeVar412 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar414 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar415 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar414.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar414.y ) );
				nodeVar416 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar414.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar414.x ) );
				nodeVar413 = ( abs( ( nodeVar415 - ( floor( ( ( nodeVar415 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar416 - ( ( floor( ( ( nodeVar416 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar417 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar418 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar417.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar417.x ) );
				nodeVar413 = abs( ( nodeVar418 - ( ( floor( ( ( nodeVar418 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar409 = nodeVar413;

		}

		nodeVar405 = nodeVar409;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar420 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar421 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar420.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar422 = ( ( 1.0 - max( max( nodeVar421.x, nodeVar421.y ), nodeVar421.z ) ) * knobs.gcr );
		nodeVar419 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar421.y ) - nodeVar422 ) / max( ( 1.0 - nodeVar422 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar423 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar424 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar423.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar425 = ( ( 1.0 - max( max( nodeVar424.x, nodeVar424.y ), nodeVar424.z ) ) * knobs.gcr );
		nodeVar419 = clamp( ( clamp( ( ( ( 1.0 - nodeVar424.y ) - nodeVar425 ) / max( ( 1.0 - nodeVar425 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar426 = ( ( ( ( knobs.dotMin + ( nodeVar419 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar428 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
		nodeVar429 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar428.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar428.y ) );
		nodeVar430 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar428.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar428.x ) );
		nodeVar427 = length( vec2<f32>( ( nodeVar429 - ( ( floor( ( ( nodeVar429 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar430 - ( ( floor( ( ( nodeVar430 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar432 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
			nodeVar433 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar432.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar432.y ) );
			nodeVar434 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar432.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar432.x ) );
			nodeVar431 = max( abs( ( nodeVar433 - ( ( floor( ( ( nodeVar433 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar434 - ( ( floor( ( ( nodeVar434 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar436 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar437 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar436.x ) + ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar436.y ) );
				nodeVar438 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar436.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar436.x ) );
				nodeVar435 = ( abs( ( nodeVar437 - ( ( floor( ( ( nodeVar437 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar438 - ( ( floor( ( ( nodeVar438 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar439 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * 0.866 ) ) );
				nodeVar440 = ( ( cos( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar439.y ) - ( sin( (0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17) ) * nodeVar439.x ) );
				nodeVar435 = abs( ( nodeVar440 - ( ( floor( ( ( nodeVar440 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar431 = nodeVar435;

		}

		nodeVar427 = nodeVar431;

	}

	nodeVar441 = max( 0.01, ( ( nodeVar238 / knobs.spacing ) * 0.5 ) );
	nodeVar442 = clamp( knobs.dotMorph, 0.0, 1.0 );
	nodeVar443 = ( ( knobs.spacing * nodeVar442 ) * 0.6 );
	nodeVar444 = clamp( ( 1.0 - ( nodeVar427 / max( ( nodeVar426 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar445 = clamp( ( 1.0 - ( nodeVar405 / max( ( nodeVar404 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar446 = clamp( ( 1.0 - ( nodeVar381 / max( ( nodeVar380 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar447 = clamp( ( 1.0 - ( nodeVar359 / max( ( nodeVar358 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar448 = clamp( ( 1.0 - ( nodeVar335 / max( ( nodeVar334 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar449 = clamp( ( 1.0 - ( nodeVar309 / max( ( nodeVar308 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar450 = clamp( ( 1.0 - ( nodeVar285 / max( ( nodeVar284 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar451 = clamp( ( 1.0 - ( nodeVar263 / max( ( nodeVar262 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar452 = clamp( ( 1.0 - ( nodeVar239 / max( ( nodeVar237 + nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar453 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(0.8387990117372213, 0.0, 0.26225065751888765).x, vec3<f32>(0.8387990117372213, 0.0, 0.26225065751888765).y, vec3<f32>(0.8387990117372213, 0.0, 0.26225065751888765).z ), mix( max( smoothstep( ( nodeVar237 + nodeVar238 ), ( nodeVar237 - nodeVar238 ), nodeVar239 ), max( smoothstep( ( nodeVar262 + nodeVar238 ), ( nodeVar262 - nodeVar238 ), nodeVar263 ), max( smoothstep( ( nodeVar284 + nodeVar238 ), ( nodeVar284 - nodeVar238 ), nodeVar285 ), max( smoothstep( ( nodeVar308 + nodeVar238 ), ( nodeVar308 - nodeVar238 ), nodeVar309 ), max( smoothstep( ( nodeVar334 + nodeVar238 ), ( nodeVar334 - nodeVar238 ), nodeVar335 ), max( smoothstep( ( nodeVar358 + nodeVar238 ), ( nodeVar358 - nodeVar238 ), nodeVar359 ), max( smoothstep( ( nodeVar380 + nodeVar238 ), ( nodeVar380 - nodeVar238 ), nodeVar381 ), max( smoothstep( ( nodeVar404 + nodeVar238 ), ( nodeVar404 - nodeVar238 ), nodeVar405 ), max( smoothstep( ( nodeVar426 + nodeVar238 ), ( nodeVar426 - nodeVar238 ), nodeVar427 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - nodeVar441 ), ( 0.5 + nodeVar441 ), ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar444 * nodeVar444 ) ) + ( nodeVar445 * nodeVar445 ) ) + ( nodeVar446 * nodeVar446 ) ) + ( nodeVar447 * nodeVar447 ) ) + ( nodeVar448 * nodeVar448 ) ) + ( nodeVar449 * nodeVar449 ) ) + ( nodeVar450 * nodeVar450 ) ) + ( nodeVar451 * nodeVar451 ) ) + ( nodeVar452 * nodeVar452 ) ) ), nodeVar442 ) );
	nodeVar454 = vec3<f32>( ( nodeVar4.x * nodeVar453.x ), ( nodeVar4.y * nodeVar453.y ), ( nodeVar4.z * nodeVar453.z ) );

	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar456 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar457 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar456.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar458 = ( ( 1.0 - max( max( nodeVar457.x, nodeVar457.y ), nodeVar457.z ) ) * knobs.gcr );
		nodeVar455 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar457.z ) - nodeVar458 ) / max( ( 1.0 - nodeVar458 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar459 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar460 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar459.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar461 = ( ( 1.0 - max( max( nodeVar460.x, nodeVar460.y ), nodeVar460.z ) ) * knobs.gcr );
		nodeVar455 = clamp( ( clamp( ( ( ( 1.0 - nodeVar460.z ) - nodeVar461 ) / max( ( 1.0 - nodeVar461 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar462 = ( ( ( ( knobs.dotMin + ( nodeVar455 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );
	nodeVar463 = max( 0.5, ( ( knobs.softness * knobs.spacing ) * 0.3 ) );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar465 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar466 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar465.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar465.y ) );
		nodeVar467 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar465.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar465.x ) );
		nodeVar464 = length( vec2<f32>( ( nodeVar466 - ( ( floor( ( ( nodeVar466 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar467 - ( ( floor( ( ( nodeVar467 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar469 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar470 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar469.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar469.y ) );
			nodeVar471 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar469.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar469.x ) );
			nodeVar468 = max( abs( ( nodeVar470 - ( ( floor( ( ( nodeVar470 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar471 - ( ( floor( ( ( nodeVar471 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar473 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar474 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar473.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar473.y ) );
				nodeVar475 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar473.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar473.x ) );
				nodeVar472 = ( abs( ( nodeVar474 - ( ( floor( ( ( nodeVar474 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar475 - ( ( floor( ( ( nodeVar475 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar476 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar477 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar476.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar476.x ) );
				nodeVar472 = abs( ( nodeVar477 - ( ( floor( ( ( nodeVar477 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar468 = nodeVar472;

		}

		nodeVar464 = nodeVar468;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar479 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar480 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar481 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar480 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar480 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar479.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar482 = ( ( 1.0 - max( max( nodeVar481.x, nodeVar481.y ), nodeVar481.z ) ) * knobs.gcr );
		nodeVar478 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar481.z ) - nodeVar482 ) / max( ( 1.0 - nodeVar482 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar483 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar484 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar485 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar484 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar484 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar483.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar486 = ( ( 1.0 - max( max( nodeVar485.x, nodeVar485.y ), nodeVar485.z ) ) * knobs.gcr );
		nodeVar478 = clamp( ( clamp( ( ( ( 1.0 - nodeVar485.z ) - nodeVar486 ) / max( ( 1.0 - nodeVar486 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar487 = ( ( ( ( knobs.dotMin + ( nodeVar478 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar489 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar490 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar489.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar489.y ) );
		nodeVar491 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar489.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar489.x ) );
		nodeVar488 = length( vec2<f32>( ( nodeVar490 - ( floor( ( ( nodeVar490 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar491 - ( ( floor( ( ( nodeVar491 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar493 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar494 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar493.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar493.y ) );
			nodeVar495 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar493.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar493.x ) );
			nodeVar492 = max( abs( ( nodeVar494 - ( floor( ( ( nodeVar494 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar495 - ( ( floor( ( ( nodeVar495 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar497 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar498 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar497.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar497.y ) );
				nodeVar499 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar497.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar497.x ) );
				nodeVar496 = ( abs( ( nodeVar498 - ( floor( ( ( nodeVar498 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar499 - ( ( floor( ( ( nodeVar499 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar500 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar501 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar500.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar500.x ) );
				nodeVar496 = abs( ( nodeVar501 - ( ( floor( ( ( nodeVar501 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar492 = nodeVar496;

		}

		nodeVar488 = nodeVar492;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar503 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar504 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar503.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar505 = ( ( 1.0 - max( max( nodeVar504.x, nodeVar504.y ), nodeVar504.z ) ) * knobs.gcr );
		nodeVar502 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar504.z ) - nodeVar505 ) / max( ( 1.0 - nodeVar505 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar506 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar507 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar506.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar508 = ( ( 1.0 - max( max( nodeVar507.x, nodeVar507.y ), nodeVar507.z ) ) * knobs.gcr );
		nodeVar502 = clamp( ( clamp( ( ( ( 1.0 - nodeVar507.z ) - nodeVar508 ) / max( ( 1.0 - nodeVar508 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar509 = ( ( ( ( knobs.dotMin + ( nodeVar502 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar511 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar512 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar511.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar511.y ) );
		nodeVar513 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar511.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar511.x ) );
		nodeVar510 = length( vec2<f32>( ( nodeVar512 - ( ( floor( ( ( nodeVar512 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar513 - ( ( floor( ( ( nodeVar513 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar515 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar516 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar515.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar515.y ) );
			nodeVar517 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar515.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar515.x ) );
			nodeVar514 = max( abs( ( nodeVar516 - ( ( floor( ( ( nodeVar516 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar517 - ( ( floor( ( ( nodeVar517 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar519 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar520 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar519.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar519.y ) );
				nodeVar521 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar519.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar519.x ) );
				nodeVar518 = ( abs( ( nodeVar520 - ( ( floor( ( ( nodeVar520 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar521 - ( ( floor( ( ( nodeVar521 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar522 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar523 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar522.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar522.x ) );
				nodeVar518 = abs( ( nodeVar523 - ( ( floor( ( ( nodeVar523 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar514 = nodeVar518;

		}

		nodeVar510 = nodeVar514;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar525 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar526 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar527 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar526 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar525.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar526 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar528 = ( ( 1.0 - max( max( nodeVar527.x, nodeVar527.y ), nodeVar527.z ) ) * knobs.gcr );
		nodeVar524 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar527.z ) - nodeVar528 ) / max( ( 1.0 - nodeVar528 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar529 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar530 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar531 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar530 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar529.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar530 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar532 = ( ( 1.0 - max( max( nodeVar531.x, nodeVar531.y ), nodeVar531.z ) ) * knobs.gcr );
		nodeVar524 = clamp( ( clamp( ( ( ( 1.0 - nodeVar531.z ) - nodeVar532 ) / max( ( 1.0 - nodeVar532 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar533 = ( ( ( ( knobs.dotMin + ( nodeVar524 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar535 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar536 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar535.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar535.y ) );
		nodeVar537 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar535.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar535.x ) );
		nodeVar534 = length( vec2<f32>( ( nodeVar536 - ( ( floor( ( ( nodeVar536 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar537 - ( floor( ( ( nodeVar537 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar539 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar540 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar539.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar539.y ) );
			nodeVar541 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar539.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar539.x ) );
			nodeVar538 = max( abs( ( nodeVar540 - ( ( floor( ( ( nodeVar540 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar541 - ( floor( ( ( nodeVar541 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar543 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar544 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar543.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar543.y ) );
				nodeVar545 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar543.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar543.x ) );
				nodeVar542 = ( abs( ( nodeVar544 - ( ( floor( ( ( nodeVar544 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar545 - ( floor( ( ( nodeVar545 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar546 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar547 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar546.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar546.x ) );
				nodeVar542 = abs( ( nodeVar547 - ( floor( ( ( nodeVar547 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar538 = nodeVar542;

		}

		nodeVar534 = nodeVar538;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar549 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar550 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar549.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar549.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar551 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar549.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar549.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar552 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar550 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar551 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar550 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar551 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar553 = ( ( 1.0 - max( max( nodeVar552.x, nodeVar552.y ), nodeVar552.z ) ) * knobs.gcr );
		nodeVar548 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar552.z ) - nodeVar553 ) / max( ( 1.0 - nodeVar553 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar554 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar555 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar554.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar554.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar556 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar554.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar554.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar557 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar555 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar556 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar555 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar556 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar558 = ( ( 1.0 - max( max( nodeVar557.x, nodeVar557.y ), nodeVar557.z ) ) * knobs.gcr );
		nodeVar548 = clamp( ( clamp( ( ( ( 1.0 - nodeVar557.z ) - nodeVar558 ) / max( ( 1.0 - nodeVar558 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar559 = ( ( ( ( knobs.dotMin + ( nodeVar548 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar561 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar562 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar561.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar561.y ) );
		nodeVar563 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar561.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar561.x ) );
		nodeVar560 = length( vec2<f32>( ( nodeVar562 - ( floor( ( ( nodeVar562 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar563 - ( floor( ( ( nodeVar563 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar565 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar566 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar565.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar565.y ) );
			nodeVar567 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar565.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar565.x ) );
			nodeVar564 = max( abs( ( nodeVar566 - ( floor( ( ( nodeVar566 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar567 - ( floor( ( ( nodeVar567 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar569 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar570 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar569.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar569.y ) );
				nodeVar571 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar569.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar569.x ) );
				nodeVar568 = ( abs( ( nodeVar570 - ( floor( ( ( nodeVar570 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar571 - ( floor( ( ( nodeVar571 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar572 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar573 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar572.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar572.x ) );
				nodeVar568 = abs( ( nodeVar573 - ( floor( ( ( nodeVar573 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar564 = nodeVar568;

		}

		nodeVar560 = nodeVar564;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar575 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar576 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar577 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar576 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar575.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar576 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar578 = ( ( 1.0 - max( max( nodeVar577.x, nodeVar577.y ), nodeVar577.z ) ) * knobs.gcr );
		nodeVar574 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar577.z ) - nodeVar578 ) / max( ( 1.0 - nodeVar578 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar579 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar580 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar581 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar580 ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar579.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar580 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar582 = ( ( 1.0 - max( max( nodeVar581.x, nodeVar581.y ), nodeVar581.z ) ) * knobs.gcr );
		nodeVar574 = clamp( ( clamp( ( ( ( 1.0 - nodeVar581.z ) - nodeVar582 ) / max( ( 1.0 - nodeVar582 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar583 = ( ( ( ( knobs.dotMin + ( nodeVar574 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar585 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar586 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar585.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar585.y ) );
		nodeVar587 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar585.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar585.x ) );
		nodeVar584 = length( vec2<f32>( ( nodeVar586 - ( ( floor( ( ( nodeVar586 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar587 - ( floor( ( ( nodeVar587 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar589 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar590 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar589.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar589.y ) );
			nodeVar591 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar589.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar589.x ) );
			nodeVar588 = max( abs( ( nodeVar590 - ( ( floor( ( ( nodeVar590 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar591 - ( floor( ( ( nodeVar591 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar593 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar594 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar593.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar593.y ) );
				nodeVar595 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar593.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar593.x ) );
				nodeVar592 = ( abs( ( nodeVar594 - ( ( floor( ( ( nodeVar594 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar595 - ( floor( ( ( nodeVar595 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar596 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar597 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar596.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar596.x ) );
				nodeVar592 = abs( ( nodeVar597 - ( floor( ( ( nodeVar597 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar588 = nodeVar592;

		}

		nodeVar584 = nodeVar588;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar599 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar600 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar599.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar601 = ( ( 1.0 - max( max( nodeVar600.x, nodeVar600.y ), nodeVar600.z ) ) * knobs.gcr );
		nodeVar598 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar600.z ) - nodeVar601 ) / max( ( 1.0 - nodeVar601 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar602 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar603 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar602.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar604 = ( ( 1.0 - max( max( nodeVar603.x, nodeVar603.y ), nodeVar603.z ) ) * knobs.gcr );
		nodeVar598 = clamp( ( clamp( ( ( ( 1.0 - nodeVar603.z ) - nodeVar604 ) / max( ( 1.0 - nodeVar604 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar605 = ( ( ( ( knobs.dotMin + ( nodeVar598 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar607 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar608 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar607.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar607.y ) );
		nodeVar609 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar607.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar607.x ) );
		nodeVar606 = length( vec2<f32>( ( nodeVar608 - ( ( floor( ( ( nodeVar608 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar609 - ( ( floor( ( ( nodeVar609 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar611 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar612 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar611.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar611.y ) );
			nodeVar613 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar611.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar611.x ) );
			nodeVar610 = max( abs( ( nodeVar612 - ( ( floor( ( ( nodeVar612 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar613 - ( ( floor( ( ( nodeVar613 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar615 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar616 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar615.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar615.y ) );
				nodeVar617 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar615.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar615.x ) );
				nodeVar614 = ( abs( ( nodeVar616 - ( ( floor( ( ( nodeVar616 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar617 - ( ( floor( ( ( nodeVar617 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar618 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar619 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar618.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar618.x ) );
				nodeVar614 = abs( ( nodeVar619 - ( ( floor( ( ( nodeVar619 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar610 = nodeVar614;

		}

		nodeVar606 = nodeVar610;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar621 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar622 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar623 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar622 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar622 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar621.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar624 = ( ( 1.0 - max( max( nodeVar623.x, nodeVar623.y ), nodeVar623.z ) ) * knobs.gcr );
		nodeVar620 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar623.z ) - nodeVar624 ) / max( ( 1.0 - nodeVar624 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar625 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar626 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar627 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar626 ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar626 ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar625.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar628 = ( ( 1.0 - max( max( nodeVar627.x, nodeVar627.y ), nodeVar627.z ) ) * knobs.gcr );
		nodeVar620 = clamp( ( clamp( ( ( ( 1.0 - nodeVar627.z ) - nodeVar628 ) / max( ( 1.0 - nodeVar628 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar629 = ( ( ( ( knobs.dotMin + ( nodeVar620 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar631 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar632 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar631.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar631.y ) );
		nodeVar633 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar631.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar631.x ) );
		nodeVar630 = length( vec2<f32>( ( nodeVar632 - ( floor( ( ( nodeVar632 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar633 - ( ( floor( ( ( nodeVar633 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar635 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar636 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar635.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar635.y ) );
			nodeVar637 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar635.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar635.x ) );
			nodeVar634 = max( abs( ( nodeVar636 - ( floor( ( ( nodeVar636 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar637 - ( ( floor( ( ( nodeVar637 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar639 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar640 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar639.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar639.y ) );
				nodeVar641 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar639.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar639.x ) );
				nodeVar638 = ( abs( ( nodeVar640 - ( floor( ( ( nodeVar640 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar641 - ( ( floor( ( ( nodeVar641 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar642 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar643 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar642.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar642.x ) );
				nodeVar638 = abs( ( nodeVar643 - ( ( floor( ( ( nodeVar643 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar634 = nodeVar638;

		}

		nodeVar630 = nodeVar634;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar645 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar646 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar645.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar647 = ( ( 1.0 - max( max( nodeVar646.x, nodeVar646.y ), nodeVar646.z ) ) * knobs.gcr );
		nodeVar644 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - nodeVar646.z ) - nodeVar647 ) / max( ( 1.0 - nodeVar647 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar648 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar649 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar648.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar650 = ( ( 1.0 - max( max( nodeVar649.x, nodeVar649.y ), nodeVar649.z ) ) * knobs.gcr );
		nodeVar644 = clamp( ( clamp( ( ( ( 1.0 - nodeVar649.z ) - nodeVar650 ) / max( ( 1.0 - nodeVar650 ), 0.001 ) ), 0.0, 1.0 ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar651 = ( ( ( ( knobs.dotMin + ( nodeVar644 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar653 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
		nodeVar654 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar653.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar653.y ) );
		nodeVar655 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar653.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar653.x ) );
		nodeVar652 = length( vec2<f32>( ( nodeVar654 - ( ( floor( ( ( nodeVar654 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar655 - ( ( floor( ( ( nodeVar655 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar657 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
			nodeVar658 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar657.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar657.y ) );
			nodeVar659 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar657.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar657.x ) );
			nodeVar656 = max( abs( ( nodeVar658 - ( ( floor( ( ( nodeVar658 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar659 - ( ( floor( ( ( nodeVar659 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar661 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar662 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar661.x ) + ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar661.y ) );
				nodeVar663 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar661.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar661.x ) );
				nodeVar660 = ( abs( ( nodeVar662 - ( ( floor( ( ( nodeVar662 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar663 - ( ( floor( ( ( nodeVar663 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar664 = ( ( nodeVar1 * nodeVar2 ) + vec2<f32>( ( knobs.registration * -0.5 ), ( knobs.registration * -0.866 ) ) );
				nodeVar665 = ( ( cos( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar664.y ) - ( sin( (0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17) ) * nodeVar664.x ) );
				nodeVar660 = abs( ( nodeVar665 - ( ( floor( ( ( nodeVar665 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar656 = nodeVar660;

		}

		nodeVar652 = nodeVar656;

	}

	nodeVar666 = max( 0.01, ( ( nodeVar463 / knobs.spacing ) * 0.5 ) );
	nodeVar667 = clamp( knobs.dotMorph, 0.0, 1.0 );
	nodeVar668 = ( ( knobs.spacing * nodeVar667 ) * 0.6 );
	nodeVar669 = clamp( ( 1.0 - ( nodeVar652 / max( ( nodeVar651 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar670 = clamp( ( 1.0 - ( nodeVar630 / max( ( nodeVar629 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar671 = clamp( ( 1.0 - ( nodeVar606 / max( ( nodeVar605 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar672 = clamp( ( 1.0 - ( nodeVar584 / max( ( nodeVar583 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar673 = clamp( ( 1.0 - ( nodeVar560 / max( ( nodeVar559 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar674 = clamp( ( 1.0 - ( nodeVar534 / max( ( nodeVar533 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar675 = clamp( ( 1.0 - ( nodeVar510 / max( ( nodeVar509 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar676 = clamp( ( 1.0 - ( nodeVar488 / max( ( nodeVar487 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar677 = clamp( ( 1.0 - ( nodeVar464 / max( ( nodeVar462 + nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar678 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(1.0, 0.8879231178794776, 0.0).x, vec3<f32>(1.0, 0.8879231178794776, 0.0).y, vec3<f32>(1.0, 0.8879231178794776, 0.0).z ), mix( max( smoothstep( ( nodeVar462 + nodeVar463 ), ( nodeVar462 - nodeVar463 ), nodeVar464 ), max( smoothstep( ( nodeVar487 + nodeVar463 ), ( nodeVar487 - nodeVar463 ), nodeVar488 ), max( smoothstep( ( nodeVar509 + nodeVar463 ), ( nodeVar509 - nodeVar463 ), nodeVar510 ), max( smoothstep( ( nodeVar533 + nodeVar463 ), ( nodeVar533 - nodeVar463 ), nodeVar534 ), max( smoothstep( ( nodeVar559 + nodeVar463 ), ( nodeVar559 - nodeVar463 ), nodeVar560 ), max( smoothstep( ( nodeVar583 + nodeVar463 ), ( nodeVar583 - nodeVar463 ), nodeVar584 ), max( smoothstep( ( nodeVar605 + nodeVar463 ), ( nodeVar605 - nodeVar463 ), nodeVar606 ), max( smoothstep( ( nodeVar629 + nodeVar463 ), ( nodeVar629 - nodeVar463 ), nodeVar630 ), max( smoothstep( ( nodeVar651 + nodeVar463 ), ( nodeVar651 - nodeVar463 ), nodeVar652 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - nodeVar666 ), ( 0.5 + nodeVar666 ), ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar669 * nodeVar669 ) ) + ( nodeVar670 * nodeVar670 ) ) + ( nodeVar671 * nodeVar671 ) ) + ( nodeVar672 * nodeVar672 ) ) + ( nodeVar673 * nodeVar673 ) ) + ( nodeVar674 * nodeVar674 ) ) + ( nodeVar675 * nodeVar675 ) ) + ( nodeVar676 * nodeVar676 ) ) + ( nodeVar677 * nodeVar677 ) ) ), nodeVar667 ) );
	nodeVar679 = vec3<f32>( ( nodeVar4.x * nodeVar678.x ), ( nodeVar4.y * nodeVar678.y ), ( nodeVar4.z * nodeVar678.z ) );

	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar681 = ( nodeVar1 * nodeVar2 );
		nodeVar682 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar681.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar680 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar682.x, nodeVar682.y ), nodeVar682.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar683 = ( nodeVar1 * nodeVar2 );
		nodeVar684 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar683.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar680 = clamp( ( ( ( 1.0 - max( max( nodeVar684.x, nodeVar684.y ), nodeVar684.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar685 = ( ( ( ( knobs.dotMin + ( nodeVar680 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );
	nodeVar686 = max( 0.5, ( ( knobs.softness * knobs.spacing ) * 0.3 ) );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar688 = ( nodeVar1 * nodeVar2 );
		nodeVar689 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar688.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar688.y ) );
		nodeVar690 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar688.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar688.x ) );
		nodeVar687 = length( vec2<f32>( ( nodeVar689 - ( ( floor( ( ( nodeVar689 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar690 - ( ( floor( ( ( nodeVar690 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar692 = ( nodeVar1 * nodeVar2 );
			nodeVar693 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar692.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar692.y ) );
			nodeVar694 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar692.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar692.x ) );
			nodeVar691 = max( abs( ( nodeVar693 - ( ( floor( ( ( nodeVar693 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar694 - ( ( floor( ( ( nodeVar694 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar696 = ( nodeVar1 * nodeVar2 );
				nodeVar697 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar696.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar696.y ) );
				nodeVar698 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar696.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar696.x ) );
				nodeVar695 = ( abs( ( nodeVar697 - ( ( floor( ( ( nodeVar697 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar698 - ( ( floor( ( ( nodeVar698 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar699 = ( nodeVar1 * nodeVar2 );
				nodeVar700 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar699.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar699.x ) );
				nodeVar695 = abs( ( nodeVar700 - ( ( floor( ( ( nodeVar700 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar691 = nodeVar695;

		}

		nodeVar687 = nodeVar691;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar702 = ( nodeVar1 * nodeVar2 );
		nodeVar703 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar704 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar703 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar703 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar702.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar701 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar704.x, nodeVar704.y ), nodeVar704.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar705 = ( nodeVar1 * nodeVar2 );
		nodeVar706 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar707 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar706 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar706 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar705.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar701 = clamp( ( ( ( 1.0 - max( max( nodeVar707.x, nodeVar707.y ), nodeVar707.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar708 = ( ( ( ( knobs.dotMin + ( nodeVar701 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar710 = ( nodeVar1 * nodeVar2 );
		nodeVar711 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar710.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar710.y ) );
		nodeVar712 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar710.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar710.x ) );
		nodeVar709 = length( vec2<f32>( ( nodeVar711 - ( floor( ( ( nodeVar711 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar712 - ( ( floor( ( ( nodeVar712 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar714 = ( nodeVar1 * nodeVar2 );
			nodeVar715 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar714.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar714.y ) );
			nodeVar716 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar714.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar714.x ) );
			nodeVar713 = max( abs( ( nodeVar715 - ( floor( ( ( nodeVar715 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar716 - ( ( floor( ( ( nodeVar716 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar718 = ( nodeVar1 * nodeVar2 );
				nodeVar719 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar718.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar718.y ) );
				nodeVar720 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar718.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar718.x ) );
				nodeVar717 = ( abs( ( nodeVar719 - ( floor( ( ( nodeVar719 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar720 - ( ( floor( ( ( nodeVar720 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar721 = ( nodeVar1 * nodeVar2 );
				nodeVar722 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar721.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar721.x ) );
				nodeVar717 = abs( ( nodeVar722 - ( ( floor( ( ( nodeVar722 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar713 = nodeVar717;

		}

		nodeVar709 = nodeVar713;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar724 = ( nodeVar1 * nodeVar2 );
		nodeVar725 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar724.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar723 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar725.x, nodeVar725.y ), nodeVar725.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar726 = ( nodeVar1 * nodeVar2 );
		nodeVar727 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar726.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar723 = clamp( ( ( ( 1.0 - max( max( nodeVar727.x, nodeVar727.y ), nodeVar727.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar728 = ( ( ( ( knobs.dotMin + ( nodeVar723 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar730 = ( nodeVar1 * nodeVar2 );
		nodeVar731 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar730.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar730.y ) );
		nodeVar732 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar730.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar730.x ) );
		nodeVar729 = length( vec2<f32>( ( nodeVar731 - ( ( floor( ( ( nodeVar731 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar732 - ( ( floor( ( ( nodeVar732 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar734 = ( nodeVar1 * nodeVar2 );
			nodeVar735 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar734.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar734.y ) );
			nodeVar736 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar734.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar734.x ) );
			nodeVar733 = max( abs( ( nodeVar735 - ( ( floor( ( ( nodeVar735 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar736 - ( ( floor( ( ( nodeVar736 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar738 = ( nodeVar1 * nodeVar2 );
				nodeVar739 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar738.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar738.y ) );
				nodeVar740 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar738.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar738.x ) );
				nodeVar737 = ( abs( ( nodeVar739 - ( ( floor( ( ( nodeVar739 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar740 - ( ( floor( ( ( nodeVar740 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) );

			} else {

				nodeVar741 = ( nodeVar1 * nodeVar2 );
				nodeVar742 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar741.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar741.x ) );
				nodeVar737 = abs( ( nodeVar742 - ( ( floor( ( ( nodeVar742 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) );

			}

			nodeVar733 = nodeVar737;

		}

		nodeVar729 = nodeVar733;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar744 = ( nodeVar1 * nodeVar2 );
		nodeVar745 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar746 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar745 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar744.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar745 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar743 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar746.x, nodeVar746.y ), nodeVar746.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar747 = ( nodeVar1 * nodeVar2 );
		nodeVar748 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar749 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar748 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar747.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar748 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar743 = clamp( ( ( ( 1.0 - max( max( nodeVar749.x, nodeVar749.y ), nodeVar749.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar750 = ( ( ( ( knobs.dotMin + ( nodeVar743 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar752 = ( nodeVar1 * nodeVar2 );
		nodeVar753 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar752.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar752.y ) );
		nodeVar754 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar752.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar752.x ) );
		nodeVar751 = length( vec2<f32>( ( nodeVar753 - ( ( floor( ( ( nodeVar753 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar754 - ( floor( ( ( nodeVar754 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar756 = ( nodeVar1 * nodeVar2 );
			nodeVar757 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar756.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar756.y ) );
			nodeVar758 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar756.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar756.x ) );
			nodeVar755 = max( abs( ( nodeVar757 - ( ( floor( ( ( nodeVar757 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar758 - ( floor( ( ( nodeVar758 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar760 = ( nodeVar1 * nodeVar2 );
				nodeVar761 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar760.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar760.y ) );
				nodeVar762 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar760.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar760.x ) );
				nodeVar759 = ( abs( ( nodeVar761 - ( ( floor( ( ( nodeVar761 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar762 - ( floor( ( ( nodeVar762 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar763 = ( nodeVar1 * nodeVar2 );
				nodeVar764 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar763.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar763.x ) );
				nodeVar759 = abs( ( nodeVar764 - ( floor( ( ( nodeVar764 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar755 = nodeVar759;

		}

		nodeVar751 = nodeVar755;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar766 = ( nodeVar1 * nodeVar2 );
		nodeVar767 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar766.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar766.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar768 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar766.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar766.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar769 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar767 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar768 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar767 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar768 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar765 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar769.x, nodeVar769.y ), nodeVar769.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar770 = ( nodeVar1 * nodeVar2 );
		nodeVar771 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar770.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar770.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar772 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar770.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar770.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar773 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar771 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar772 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar771 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar772 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar765 = clamp( ( ( ( 1.0 - max( max( nodeVar773.x, nodeVar773.y ), nodeVar773.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar774 = ( ( ( ( knobs.dotMin + ( nodeVar765 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar776 = ( nodeVar1 * nodeVar2 );
		nodeVar777 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar776.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar776.y ) );
		nodeVar778 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar776.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar776.x ) );
		nodeVar775 = length( vec2<f32>( ( nodeVar777 - ( floor( ( ( nodeVar777 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar778 - ( floor( ( ( nodeVar778 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar780 = ( nodeVar1 * nodeVar2 );
			nodeVar781 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar780.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar780.y ) );
			nodeVar782 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar780.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar780.x ) );
			nodeVar779 = max( abs( ( nodeVar781 - ( floor( ( ( nodeVar781 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar782 - ( floor( ( ( nodeVar782 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar784 = ( nodeVar1 * nodeVar2 );
				nodeVar785 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar784.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar784.y ) );
				nodeVar786 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar784.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar784.x ) );
				nodeVar783 = ( abs( ( nodeVar785 - ( floor( ( ( nodeVar785 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar786 - ( floor( ( ( nodeVar786 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar787 = ( nodeVar1 * nodeVar2 );
				nodeVar788 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar787.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar787.x ) );
				nodeVar783 = abs( ( nodeVar788 - ( floor( ( ( nodeVar788 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar779 = nodeVar783;

		}

		nodeVar775 = nodeVar779;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar790 = ( nodeVar1 * nodeVar2 );
		nodeVar791 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar792 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar791 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar790.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar791 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar789 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar792.x, nodeVar792.y ), nodeVar792.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar793 = ( nodeVar1 * nodeVar2 );
		nodeVar794 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar795 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar794 ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar793.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar794 ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar789 = clamp( ( ( ( 1.0 - max( max( nodeVar795.x, nodeVar795.y ), nodeVar795.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar796 = ( ( ( ( knobs.dotMin + ( nodeVar789 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar798 = ( nodeVar1 * nodeVar2 );
		nodeVar799 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar798.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar798.y ) );
		nodeVar800 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar798.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar798.x ) );
		nodeVar797 = length( vec2<f32>( ( nodeVar799 - ( ( floor( ( ( nodeVar799 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar800 - ( floor( ( ( nodeVar800 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar802 = ( nodeVar1 * nodeVar2 );
			nodeVar803 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar802.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar802.y ) );
			nodeVar804 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar802.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar802.x ) );
			nodeVar801 = max( abs( ( nodeVar803 - ( ( floor( ( ( nodeVar803 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar804 - ( floor( ( ( nodeVar804 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar806 = ( nodeVar1 * nodeVar2 );
				nodeVar807 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar806.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar806.y ) );
				nodeVar808 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar806.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar806.x ) );
				nodeVar805 = ( abs( ( nodeVar807 - ( ( floor( ( ( nodeVar807 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar808 - ( floor( ( ( nodeVar808 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) );

			} else {

				nodeVar809 = ( nodeVar1 * nodeVar2 );
				nodeVar810 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar809.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar809.x ) );
				nodeVar805 = abs( ( nodeVar810 - ( floor( ( ( nodeVar810 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) );

			}

			nodeVar801 = nodeVar805;

		}

		nodeVar797 = nodeVar801;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar812 = ( nodeVar1 * nodeVar2 );
		nodeVar813 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar812.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar811 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar813.x, nodeVar813.y ), nodeVar813.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar814 = ( nodeVar1 * nodeVar2 );
		nodeVar815 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar814.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar811 = clamp( ( ( ( 1.0 - max( max( nodeVar815.x, nodeVar815.y ), nodeVar815.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar816 = ( ( ( ( knobs.dotMin + ( nodeVar811 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar818 = ( nodeVar1 * nodeVar2 );
		nodeVar819 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar818.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar818.y ) );
		nodeVar820 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar818.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar818.x ) );
		nodeVar817 = length( vec2<f32>( ( nodeVar819 - ( ( floor( ( ( nodeVar819 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ), ( nodeVar820 - ( ( floor( ( ( nodeVar820 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar822 = ( nodeVar1 * nodeVar2 );
			nodeVar823 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar822.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar822.y ) );
			nodeVar824 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar822.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar822.x ) );
			nodeVar821 = max( abs( ( nodeVar823 - ( ( floor( ( ( nodeVar823 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ), abs( ( nodeVar824 - ( ( floor( ( ( nodeVar824 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar826 = ( nodeVar1 * nodeVar2 );
				nodeVar827 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar826.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar826.y ) );
				nodeVar828 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar826.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar826.x ) );
				nodeVar825 = ( abs( ( nodeVar827 - ( ( floor( ( ( nodeVar827 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * 1.0 ) ) ) ) + abs( ( nodeVar828 - ( ( floor( ( ( nodeVar828 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar829 = ( nodeVar1 * nodeVar2 );
				nodeVar830 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar829.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar829.x ) );
				nodeVar825 = abs( ( nodeVar830 - ( ( floor( ( ( nodeVar830 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar821 = nodeVar825;

		}

		nodeVar817 = nodeVar821;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar832 = ( nodeVar1 * nodeVar2 );
		nodeVar833 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar834 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar833 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar833 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar832.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar831 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar834.x, nodeVar834.y ), nodeVar834.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar835 = ( nodeVar1 * nodeVar2 );
		nodeVar836 = ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing );
		nodeVar837 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar836 ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar836 ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar835.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar831 = clamp( ( ( ( 1.0 - max( max( nodeVar837.x, nodeVar837.y ), nodeVar837.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar838 = ( ( ( ( knobs.dotMin + ( nodeVar831 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar840 = ( nodeVar1 * nodeVar2 );
		nodeVar841 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar840.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar840.y ) );
		nodeVar842 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar840.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar840.x ) );
		nodeVar839 = length( vec2<f32>( ( nodeVar841 - ( floor( ( ( nodeVar841 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ), ( nodeVar842 - ( ( floor( ( ( nodeVar842 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar844 = ( nodeVar1 * nodeVar2 );
			nodeVar845 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar844.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar844.y ) );
			nodeVar846 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar844.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar844.x ) );
			nodeVar843 = max( abs( ( nodeVar845 - ( floor( ( ( nodeVar845 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ), abs( ( nodeVar846 - ( ( floor( ( ( nodeVar846 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar848 = ( nodeVar1 * nodeVar2 );
				nodeVar849 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar848.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar848.y ) );
				nodeVar850 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar848.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar848.x ) );
				nodeVar847 = ( abs( ( nodeVar849 - ( floor( ( ( nodeVar849 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) ) ) + abs( ( nodeVar850 - ( ( floor( ( ( nodeVar850 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar851 = ( nodeVar1 * nodeVar2 );
				nodeVar852 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar851.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar851.x ) );
				nodeVar847 = abs( ( nodeVar852 - ( ( floor( ( ( nodeVar852 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar843 = nodeVar847;

		}

		nodeVar839 = nodeVar843;

	}


	if ( ( (1 * knobs.invertLuma + 0) > 0.5 ) ) {

		nodeVar854 = ( nodeVar1 * nodeVar2 );
		nodeVar855 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar854.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar853 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( nodeVar855.x, nodeVar855.y ), nodeVar855.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 ) );

	} else {

		nodeVar856 = ( nodeVar1 * nodeVar2 );
		nodeVar857 = picture_read( ( vec2<f32>( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), ( ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.y ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) + ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * ( ( floor( ( ( ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar856.x ) ) / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) ) / vec2<f32>( knobs.resolution.x, knobs.resolution.y ) ) );
		nodeVar853 = clamp( ( ( ( 1.0 - max( max( nodeVar857.x, nodeVar857.y ), nodeVar857.z ) ) * knobs.gcr ) * knobs.contrast ), 0.0, 1.0 );

	}

	nodeVar858 = ( ( ( ( knobs.dotMin + ( nodeVar853 * knobs.dotSize ) ) + knobs.dotGain ) * knobs.spacing ) * 0.5 );

	if ( ( knobs.shape < 0.5 ) ) {

		nodeVar860 = ( nodeVar1 * nodeVar2 );
		nodeVar861 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar860.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar860.y ) );
		nodeVar862 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar860.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar860.x ) );
		nodeVar859 = length( vec2<f32>( ( nodeVar861 - ( ( floor( ( ( nodeVar861 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ), ( nodeVar862 - ( ( floor( ( ( nodeVar862 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

	} else {


		if ( ( knobs.shape < 1.5 ) ) {

			nodeVar864 = ( nodeVar1 * nodeVar2 );
			nodeVar865 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar864.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar864.y ) );
			nodeVar866 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar864.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar864.x ) );
			nodeVar863 = max( abs( ( nodeVar865 - ( ( floor( ( ( nodeVar865 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ), abs( ( nodeVar866 - ( ( floor( ( ( nodeVar866 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

		} else {


			if ( ( knobs.shape < 2.5 ) ) {

				nodeVar868 = ( nodeVar1 * nodeVar2 );
				nodeVar869 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar868.x ) + ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar868.y ) );
				nodeVar870 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar868.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar868.x ) );
				nodeVar867 = ( abs( ( nodeVar869 - ( ( floor( ( ( nodeVar869 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) + abs( ( nodeVar870 - ( ( floor( ( ( nodeVar870 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) ) );

			} else {

				nodeVar871 = ( nodeVar1 * nodeVar2 );
				nodeVar872 = ( ( cos( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar871.y ) - ( sin( (0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17) ) * nodeVar871.x ) );
				nodeVar867 = abs( ( nodeVar872 - ( ( floor( ( ( nodeVar872 / knobs.spacing ) + 0.5 ) ) * knobs.spacing ) + ( knobs.spacing * -1.0 ) ) ) );

			}

			nodeVar863 = nodeVar867;

		}

		nodeVar859 = nodeVar863;

	}

	nodeVar873 = max( 0.01, ( ( nodeVar686 / knobs.spacing ) * 0.5 ) );
	nodeVar874 = clamp( knobs.dotMorph, 0.0, 1.0 );
	nodeVar875 = ( ( knobs.spacing * nodeVar874 ) * 0.6 );
	nodeVar876 = clamp( ( 1.0 - ( nodeVar859 / max( ( nodeVar858 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar877 = clamp( ( 1.0 - ( nodeVar839 / max( ( nodeVar838 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar878 = clamp( ( 1.0 - ( nodeVar817 / max( ( nodeVar816 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar879 = clamp( ( 1.0 - ( nodeVar797 / max( ( nodeVar796 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar880 = clamp( ( 1.0 - ( nodeVar775 / max( ( nodeVar774 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar881 = clamp( ( 1.0 - ( nodeVar751 / max( ( nodeVar750 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar882 = clamp( ( 1.0 - ( nodeVar729 / max( ( nodeVar728 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar883 = clamp( ( 1.0 - ( nodeVar709 / max( ( nodeVar708 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar884 = clamp( ( 1.0 - ( nodeVar687 / max( ( nodeVar685 + nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	nodeVar885 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(0.010329823026364548, 0.010329823026364548, 0.010329823026364548).x, vec3<f32>(0.010329823026364548, 0.010329823026364548, 0.010329823026364548).y, vec3<f32>(0.010329823026364548, 0.010329823026364548, 0.010329823026364548).z ), mix( max( smoothstep( ( nodeVar685 + nodeVar686 ), ( nodeVar685 - nodeVar686 ), nodeVar687 ), max( smoothstep( ( nodeVar708 + nodeVar686 ), ( nodeVar708 - nodeVar686 ), nodeVar709 ), max( smoothstep( ( nodeVar728 + nodeVar686 ), ( nodeVar728 - nodeVar686 ), nodeVar729 ), max( smoothstep( ( nodeVar750 + nodeVar686 ), ( nodeVar750 - nodeVar686 ), nodeVar751 ), max( smoothstep( ( nodeVar774 + nodeVar686 ), ( nodeVar774 - nodeVar686 ), nodeVar775 ), max( smoothstep( ( nodeVar796 + nodeVar686 ), ( nodeVar796 - nodeVar686 ), nodeVar797 ), max( smoothstep( ( nodeVar816 + nodeVar686 ), ( nodeVar816 - nodeVar686 ), nodeVar817 ), max( smoothstep( ( nodeVar838 + nodeVar686 ), ( nodeVar838 - nodeVar686 ), nodeVar839 ), max( smoothstep( ( nodeVar858 + nodeVar686 ), ( nodeVar858 - nodeVar686 ), nodeVar859 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - nodeVar873 ), ( 0.5 + nodeVar873 ), ( ( ( ( ( ( ( ( ( 0.0 + ( nodeVar876 * nodeVar876 ) ) + ( nodeVar877 * nodeVar877 ) ) + ( nodeVar878 * nodeVar878 ) ) + ( nodeVar879 * nodeVar879 ) ) + ( nodeVar880 * nodeVar880 ) ) + ( nodeVar881 * nodeVar881 ) ) + ( nodeVar882 * nodeVar882 ) ) + ( nodeVar883 * nodeVar883 ) ) + ( nodeVar884 * nodeVar884 ) ) ), nodeVar874 ) );
	nodeVar886 = vec3<f32>( ( nodeVar4.x * nodeVar885.x ), ( nodeVar4.y * nodeVar885.y ), ( nodeVar4.z * nodeVar885.z ) );
	nodeVar887 = vec4<f32>( vec3<f32>( clamp( min( min( nodeVar229.x, nodeVar454.x ), min( nodeVar679.x, nodeVar886.x ) ), 0.0, 1.0 ), clamp( min( min( nodeVar229.y, nodeVar454.y ), min( nodeVar679.y, nodeVar886.y ) ), 0.0, 1.0 ), clamp( min( min( nodeVar229.z, nodeVar454.z ), min( nodeVar679.z, nodeVar886.z ) ), 0.0, 1.0 ) ), 1.0 );
	nodeVar888 = vec3<f32>( nodeVar887.x, nodeVar887.y, nodeVar887.z );
	nodeVar889 = ( ( ( nodeVar888.x * 0.2126 ) + ( nodeVar888.y * 0.7152 ) ) + ( nodeVar888.z * 0.0722 ) );
	nodeVar890 = mix( vec3<f32>( nodeVar889, nodeVar889, nodeVar889 ), nodeVar888, f32(1.0) );
	nodeVar891 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar890.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar890.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar890.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar890.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar890.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar890.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar890.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar890.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar890.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar887.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar891.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar891.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar892 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar892;

	// result

	output.color = nodeVar892;

	output.color = to_shelf(output.color);
	return output;

}

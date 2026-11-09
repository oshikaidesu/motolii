// Circuit Bent: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Turns the image into scanlines and bends them around a point that pulls or pushes.
// --check@colorMode:Color Mode,0
// --track@monoColor_x:Tint r,0,1,0.9215686274509803,0.001
// --track@monoColor_y:Tint g,0,1,0.9607843137254902,0.001
// --track@monoColor_z:Tint b,0,1,1,0.001
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
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  colorMode: f32,
  monoColor: vec3<f32>,
  invert: f32,
  signalBlackPoint: f32,
  signalWhitePoint: f32,
  signalGamma: f32,
  presenceThreshold: f32,
  presenceSoftness: f32,
  linePitch: f32,
  lineThickness: f32,
  lineAngle: f32,
  noiseMode: f32,
  noiseAmount: f32,
  scrollSpeed: f32,
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
var<private> p0_nodeVar1 : f32;
var<private> p0_nodeVar2 : bool;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : bool;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : vec2<f32>;
var<private> p0_nodeVar18 : vec2<f32>;
var<private> p0_nodeVar19 : vec2<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : vec4<f32>;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : vec2<f32>;
var<private> p0_nodeVar28 : vec2<f32>;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : vec2<f32>;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : vec2<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : bool;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
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
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : vec2<f32>;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : f32;
var<private> p0_nodeVar108 : vec4<f32>;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : vec2<f32>;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : vec4<f32>;
var<private> p0_nodeVar114 : vec2<f32>;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : vec4<f32>;
var<private> p0_nodeVar118 : f32;
var<private> p0_nodeVar119 : f32;
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
var<private> p0_nodeVar136 : f32;
var<private> p0_nodeVar137 : f32;
var<private> p0_nodeVar138 : f32;
var<private> p0_nodeVar139 : f32;
var<private> p0_nodeVar140 : f32;
var<private> p0_nodeVar141 : f32;
var<private> p0_nodeVar142 : f32;
var<private> p0_nodeVar143 : f32;
var<private> p0_nodeVar144 : f32;
var<private> p0_nodeVar145 : f32;
var<private> p0_nodeVar146 : f32;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : f32;
var<private> p0_nodeVar149 : f32;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : f32;
var<private> p0_nodeVar155 : f32;
var<private> p0_nodeVar156 : f32;
var<private> p0_nodeVar157 : f32;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : f32;
var<private> p0_nodeVar161 : f32;
var<private> p0_nodeVar162 : f32;
var<private> p0_nodeVar163 : f32;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : f32;
var<private> p0_nodeVar166 : f32;
var<private> p0_nodeVar167 : f32;
var<private> p0_nodeVar168 : f32;
var<private> p0_nodeVar169 : f32;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : vec2<f32>;
var<private> p0_nodeVar173 : f32;
var<private> p0_nodeVar174 : f32;
var<private> p0_nodeVar175 : vec4<f32>;
var<private> p0_nodeVar176 : f32;
var<private> p0_nodeVar177 : vec2<f32>;
var<private> p0_nodeVar178 : f32;
var<private> p0_nodeVar179 : f32;
var<private> p0_nodeVar180 : vec4<f32>;
var<private> p0_nodeVar181 : vec2<f32>;
var<private> p0_nodeVar182 : f32;
var<private> p0_nodeVar183 : f32;
var<private> p0_nodeVar184 : vec4<f32>;
var<private> p0_nodeVar185 : f32;
var<private> p0_nodeVar186 : f32;
var<private> p0_nodeVar187 : f32;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : f32;
var<private> p0_nodeVar190 : f32;
var<private> p0_nodeVar191 : f32;
var<private> p0_nodeVar192 : f32;
var<private> p0_nodeVar193 : f32;
var<private> p0_nodeVar194 : f32;
var<private> p0_nodeVar195 : f32;
var<private> p0_nodeVar196 : f32;
var<private> p0_nodeVar197 : f32;
var<private> p0_nodeVar198 : f32;
var<private> p0_nodeVar199 : f32;
var<private> p0_nodeVar200 : f32;
var<private> p0_nodeVar201 : f32;
var<private> p0_nodeVar202 : f32;
var<private> p0_nodeVar203 : f32;
var<private> p0_nodeVar204 : f32;
var<private> p0_nodeVar205 : f32;
var<private> p0_nodeVar206 : f32;
var<private> p0_nodeVar207 : f32;
var<private> p0_nodeVar208 : f32;
var<private> p0_nodeVar209 : f32;
var<private> p0_nodeVar210 : f32;
var<private> p0_nodeVar211 : f32;
var<private> p0_nodeVar212 : f32;
var<private> p0_nodeVar213 : f32;
var<private> p0_nodeVar214 : f32;
var<private> p0_nodeVar215 : f32;
var<private> p0_nodeVar216 : f32;
var<private> p0_nodeVar217 : f32;
var<private> p0_nodeVar218 : f32;
var<private> p0_nodeVar219 : f32;
var<private> p0_nodeVar220 : f32;
var<private> p0_nodeVar221 : f32;
var<private> p0_nodeVar222 : f32;
var<private> p0_nodeVar223 : f32;
var<private> p0_nodeVar224 : f32;
var<private> p0_nodeVar225 : f32;
var<private> p0_nodeVar226 : f32;
var<private> p0_nodeVar227 : f32;
var<private> p0_nodeVar228 : f32;
var<private> p0_nodeVar229 : f32;
var<private> p0_nodeVar230 : f32;
var<private> p0_nodeVar231 : f32;
var<private> p0_nodeVar232 : f32;
var<private> p0_nodeVar233 : f32;
var<private> p0_nodeVar234 : f32;
var<private> p0_nodeVar235 : f32;
var<private> p0_nodeVar236 : f32;
var<private> p0_nodeVar237 : f32;
var<private> p0_nodeVar238 : f32;
var<private> p0_nodeVar239 : vec2<f32>;
var<private> p0_nodeVar240 : f32;
var<private> p0_nodeVar241 : f32;
var<private> p0_nodeVar242 : vec4<f32>;
var<private> p0_nodeVar243 : f32;
var<private> p0_nodeVar244 : vec2<f32>;
var<private> p0_nodeVar245 : f32;
var<private> p0_nodeVar246 : f32;
var<private> p0_nodeVar247 : vec4<f32>;
var<private> p0_nodeVar248 : vec2<f32>;
var<private> p0_nodeVar249 : f32;
var<private> p0_nodeVar250 : f32;
var<private> p0_nodeVar251 : vec4<f32>;
var<private> p0_nodeVar252 : f32;
var<private> p0_nodeVar253 : f32;
var<private> p0_nodeVar254 : f32;
var<private> p0_nodeVar255 : f32;
var<private> p0_nodeVar256 : f32;
var<private> p0_nodeVar257 : f32;
var<private> p0_nodeVar258 : f32;
var<private> p0_nodeVar259 : f32;
var<private> p0_nodeVar260 : f32;
var<private> p0_nodeVar261 : f32;
var<private> p0_nodeVar262 : f32;
var<private> p0_nodeVar263 : f32;
var<private> p0_nodeVar264 : f32;
var<private> p0_nodeVar265 : f32;
var<private> p0_nodeVar266 : f32;
var<private> p0_nodeVar267 : f32;
var<private> p0_nodeVar268 : f32;
var<private> p0_nodeVar269 : f32;
var<private> p0_nodeVar270 : f32;
var<private> p0_nodeVar271 : f32;
var<private> p0_nodeVar272 : f32;
var<private> p0_nodeVar273 : f32;
var<private> p0_nodeVar274 : f32;
var<private> p0_nodeVar275 : f32;
var<private> p0_nodeVar276 : f32;
var<private> p0_nodeVar277 : f32;
var<private> p0_nodeVar278 : f32;
var<private> p0_nodeVar279 : f32;
var<private> p0_nodeVar280 : f32;
var<private> p0_nodeVar281 : f32;
var<private> p0_nodeVar282 : f32;
var<private> p0_nodeVar283 : f32;
var<private> p0_nodeVar284 : f32;
var<private> p0_nodeVar285 : f32;
var<private> p0_nodeVar286 : f32;
var<private> p0_nodeVar287 : f32;
var<private> p0_nodeVar288 : f32;
var<private> p0_nodeVar289 : f32;
var<private> p0_nodeVar290 : f32;
var<private> p0_nodeVar291 : f32;
var<private> p0_nodeVar292 : f32;
var<private> p0_nodeVar293 : f32;
var<private> p0_nodeVar294 : f32;
var<private> p0_nodeVar295 : f32;
var<private> p0_nodeVar296 : f32;
var<private> p0_nodeVar297 : f32;
var<private> p0_nodeVar298 : f32;
var<private> p0_nodeVar299 : f32;
var<private> p0_nodeVar300 : f32;
var<private> p0_nodeVar301 : f32;
var<private> p0_nodeVar302 : f32;
var<private> p0_nodeVar303 : f32;
var<private> p0_nodeVar304 : f32;
var<private> p0_nodeVar305 : f32;
var<private> p0_nodeVar306 : vec2<f32>;
var<private> p0_nodeVar307 : f32;
var<private> p0_nodeVar308 : f32;
var<private> p0_nodeVar309 : vec4<f32>;
var<private> p0_nodeVar310 : f32;
var<private> p0_nodeVar311 : vec2<f32>;
var<private> p0_nodeVar312 : f32;
var<private> p0_nodeVar313 : f32;
var<private> p0_nodeVar314 : vec4<f32>;
var<private> p0_nodeVar315 : vec2<f32>;
var<private> p0_nodeVar316 : f32;
var<private> p0_nodeVar317 : f32;
var<private> p0_nodeVar318 : vec4<f32>;
var<private> p0_nodeVar319 : f32;
var<private> p0_nodeVar320 : f32;
var<private> p0_nodeVar321 : f32;
var<private> p0_nodeVar322 : f32;
var<private> p0_nodeVar323 : f32;
var<private> p0_nodeVar324 : f32;
var<private> p0_nodeVar325 : f32;
var<private> p0_nodeVar326 : f32;
var<private> p0_nodeVar327 : f32;
var<private> p0_nodeVar328 : f32;
var<private> p0_nodeVar329 : f32;
var<private> p0_nodeVar330 : f32;
var<private> p0_nodeVar331 : f32;
var<private> p0_nodeVar332 : f32;
var<private> p0_nodeVar333 : f32;
var<private> p0_nodeVar334 : f32;
var<private> p0_nodeVar335 : f32;
var<private> p0_nodeVar336 : f32;
var<private> p0_nodeVar337 : f32;
var<private> p0_nodeVar338 : f32;
var<private> p0_nodeVar339 : f32;
var<private> p0_nodeVar340 : f32;
var<private> p0_nodeVar341 : f32;
var<private> p0_nodeVar342 : f32;
var<private> p0_nodeVar343 : f32;
var<private> p0_nodeVar344 : f32;
var<private> p0_nodeVar345 : f32;
var<private> p0_nodeVar346 : f32;
var<private> p0_nodeVar347 : f32;
var<private> p0_nodeVar348 : f32;
var<private> p0_nodeVar349 : f32;
var<private> p0_nodeVar350 : f32;
var<private> p0_nodeVar351 : f32;
var<private> p0_nodeVar352 : f32;
var<private> p0_nodeVar353 : f32;
var<private> p0_nodeVar354 : f32;
var<private> p0_nodeVar355 : f32;
var<private> p0_nodeVar356 : f32;
var<private> p0_nodeVar357 : f32;
var<private> p0_nodeVar358 : f32;
var<private> p0_nodeVar359 : f32;
var<private> p0_nodeVar360 : f32;
var<private> p0_nodeVar361 : f32;
var<private> p0_nodeVar362 : f32;
var<private> p0_nodeVar363 : f32;
var<private> p0_nodeVar364 : f32;
var<private> p0_nodeVar365 : f32;
var<private> p0_nodeVar366 : f32;
var<private> p0_nodeVar367 : f32;
var<private> p0_nodeVar368 : f32;
var<private> p0_nodeVar369 : f32;
var<private> p0_nodeVar370 : f32;
var<private> p0_nodeVar371 : f32;
var<private> p0_nodeVar372 : f32;
var<private> p0_nodeVar373 : vec2<f32>;
var<private> p0_nodeVar374 : f32;
var<private> p0_nodeVar375 : f32;
var<private> p0_nodeVar376 : vec4<f32>;
var<private> p0_nodeVar377 : f32;
var<private> p0_nodeVar378 : vec2<f32>;
var<private> p0_nodeVar379 : f32;
var<private> p0_nodeVar380 : f32;
var<private> p0_nodeVar381 : vec4<f32>;
var<private> p0_nodeVar382 : vec2<f32>;
var<private> p0_nodeVar383 : f32;
var<private> p0_nodeVar384 : f32;
var<private> p0_nodeVar385 : vec4<f32>;
var<private> p0_nodeVar386 : f32;
var<private> p0_nodeVar387 : f32;
var<private> p0_nodeVar388 : f32;
var<private> p0_nodeVar389 : f32;
var<private> p0_nodeVar390 : f32;
var<private> p0_nodeVar391 : f32;
var<private> p0_nodeVar392 : f32;
var<private> p0_nodeVar393 : f32;
var<private> p0_nodeVar394 : f32;
var<private> p0_nodeVar395 : f32;
var<private> p0_nodeVar396 : f32;
var<private> p0_nodeVar397 : f32;
var<private> p0_nodeVar398 : f32;
var<private> p0_nodeVar399 : f32;
var<private> p0_nodeVar400 : f32;
var<private> p0_nodeVar401 : f32;
var<private> p0_nodeVar402 : f32;
var<private> p0_nodeVar403 : f32;
var<private> p0_nodeVar404 : f32;
var<private> p0_nodeVar405 : f32;
var<private> p0_nodeVar406 : f32;
var<private> p0_nodeVar407 : f32;
var<private> p0_nodeVar408 : f32;
var<private> p0_nodeVar409 : f32;
var<private> p0_nodeVar410 : f32;
var<private> p0_nodeVar411 : f32;
var<private> p0_nodeVar412 : f32;
var<private> p0_nodeVar413 : f32;
var<private> p0_nodeVar414 : f32;
var<private> p0_nodeVar415 : f32;
var<private> p0_nodeVar416 : f32;
var<private> p0_nodeVar417 : f32;
var<private> p0_nodeVar418 : f32;
var<private> p0_nodeVar419 : f32;
var<private> p0_nodeVar420 : f32;
var<private> p0_nodeVar421 : f32;
var<private> p0_nodeVar422 : f32;
var<private> p0_nodeVar423 : f32;
var<private> p0_nodeVar424 : f32;
var<private> p0_nodeVar425 : f32;
var<private> p0_nodeVar426 : f32;
var<private> p0_nodeVar427 : f32;
var<private> p0_nodeVar428 : f32;
var<private> p0_nodeVar429 : f32;
var<private> p0_nodeVar430 : f32;
var<private> p0_nodeVar431 : f32;
var<private> p0_nodeVar432 : f32;
var<private> p0_nodeVar433 : f32;
var<private> p0_nodeVar434 : f32;
var<private> p0_nodeVar435 : f32;
var<private> p0_nodeVar436 : f32;
var<private> p0_nodeVar437 : f32;
var<private> p0_nodeVar438 : f32;
var<private> p0_nodeVar439 : f32;
var<private> p0_nodeVar440 : vec2<f32>;
var<private> p0_nodeVar441 : f32;
var<private> p0_nodeVar442 : f32;
var<private> p0_nodeVar443 : vec4<f32>;
var<private> p0_nodeVar444 : f32;
var<private> p0_nodeVar445 : vec2<f32>;
var<private> p0_nodeVar446 : f32;
var<private> p0_nodeVar447 : f32;
var<private> p0_nodeVar448 : vec4<f32>;
var<private> p0_nodeVar449 : vec2<f32>;
var<private> p0_nodeVar450 : f32;
var<private> p0_nodeVar451 : f32;
var<private> p0_nodeVar452 : vec4<f32>;
var<private> p0_nodeVar453 : f32;
var<private> p0_nodeVar454 : f32;
var<private> p0_nodeVar455 : f32;
var<private> p0_nodeVar456 : f32;
var<private> p0_nodeVar457 : f32;
var<private> p0_nodeVar458 : f32;
var<private> p0_nodeVar459 : f32;
var<private> p0_nodeVar460 : f32;
var<private> p0_nodeVar461 : f32;
var<private> p0_nodeVar462 : f32;
var<private> p0_nodeVar463 : f32;
var<private> p0_nodeVar464 : f32;
var<private> p0_nodeVar465 : f32;
var<private> p0_nodeVar466 : f32;
var<private> p0_nodeVar467 : f32;
var<private> p0_nodeVar468 : f32;
var<private> p0_nodeVar469 : f32;
var<private> p0_nodeVar470 : f32;
var<private> p0_nodeVar471 : f32;
var<private> p0_nodeVar472 : f32;
var<private> p0_nodeVar473 : f32;
var<private> p0_nodeVar474 : f32;
var<private> p0_nodeVar475 : f32;
var<private> p0_nodeVar476 : f32;
var<private> p0_nodeVar477 : f32;
var<private> p0_nodeVar478 : f32;
var<private> p0_nodeVar479 : f32;
var<private> p0_nodeVar480 : f32;
var<private> p0_nodeVar481 : f32;
var<private> p0_nodeVar482 : f32;
var<private> p0_nodeVar483 : f32;
var<private> p0_nodeVar484 : f32;
var<private> p0_nodeVar485 : f32;
var<private> p0_nodeVar486 : f32;
var<private> p0_nodeVar487 : f32;
var<private> p0_nodeVar488 : f32;
var<private> p0_nodeVar489 : f32;
var<private> p0_nodeVar490 : f32;
var<private> p0_nodeVar491 : f32;
var<private> p0_nodeVar492 : f32;
var<private> p0_nodeVar493 : f32;
var<private> p0_nodeVar494 : f32;
var<private> p0_nodeVar495 : f32;
var<private> p0_nodeVar496 : f32;
var<private> p0_nodeVar497 : f32;
var<private> p0_nodeVar498 : f32;
var<private> p0_nodeVar499 : f32;
var<private> p0_nodeVar500 : f32;
var<private> p0_nodeVar501 : f32;
var<private> p0_nodeVar502 : f32;
var<private> p0_nodeVar503 : f32;
var<private> p0_nodeVar504 : f32;
var<private> p0_nodeVar505 : f32;
var<private> p0_nodeVar506 : f32;
var<private> p0_nodeVar507 : vec2<f32>;
var<private> p0_nodeVar508 : f32;
var<private> p0_nodeVar509 : f32;
var<private> p0_nodeVar510 : vec4<f32>;
var<private> p0_nodeVar511 : f32;
var<private> p0_nodeVar512 : vec2<f32>;
var<private> p0_nodeVar513 : f32;
var<private> p0_nodeVar514 : f32;
var<private> p0_nodeVar515 : vec4<f32>;
var<private> p0_nodeVar516 : vec2<f32>;
var<private> p0_nodeVar517 : f32;
var<private> p0_nodeVar518 : f32;
var<private> p0_nodeVar519 : vec4<f32>;
var<private> p0_nodeVar520 : f32;
var<private> p0_nodeVar521 : f32;
var<private> p0_nodeVar522 : f32;
var<private> p0_nodeVar523 : f32;
var<private> p0_nodeVar524 : f32;
var<private> p0_nodeVar525 : f32;
var<private> p0_nodeVar526 : f32;
var<private> p0_nodeVar527 : f32;
var<private> p0_nodeVar528 : f32;
var<private> p0_nodeVar529 : f32;
var<private> p0_nodeVar530 : f32;
var<private> p0_nodeVar531 : f32;
var<private> p0_nodeVar532 : f32;
var<private> p0_nodeVar533 : f32;
var<private> p0_nodeVar534 : f32;
var<private> p0_nodeVar535 : f32;
var<private> p0_nodeVar536 : f32;
var<private> p0_nodeVar537 : f32;
var<private> p0_nodeVar538 : f32;
var<private> p0_nodeVar539 : f32;
var<private> p0_nodeVar540 : f32;
var<private> p0_nodeVar541 : f32;
var<private> p0_nodeVar542 : f32;
var<private> p0_nodeVar543 : f32;
var<private> p0_nodeVar544 : f32;
var<private> p0_nodeVar545 : f32;
var<private> p0_nodeVar546 : f32;
var<private> p0_nodeVar547 : f32;
var<private> p0_nodeVar548 : f32;
var<private> p0_nodeVar549 : f32;
var<private> p0_nodeVar550 : f32;
var<private> p0_nodeVar551 : f32;
var<private> p0_nodeVar552 : f32;
var<private> p0_nodeVar553 : f32;
var<private> p0_nodeVar554 : f32;
var<private> p0_nodeVar555 : f32;
var<private> p0_nodeVar556 : f32;
var<private> p0_nodeVar557 : f32;
var<private> p0_nodeVar558 : f32;
var<private> p0_nodeVar559 : f32;
var<private> p0_nodeVar560 : f32;
var<private> p0_nodeVar561 : f32;
var<private> p0_nodeVar562 : f32;
var<private> p0_nodeVar563 : f32;
var<private> p0_nodeVar564 : f32;
var<private> p0_nodeVar565 : f32;
var<private> p0_nodeVar566 : f32;
var<private> p0_nodeVar567 : f32;
var<private> p0_nodeVar568 : f32;
var<private> p0_nodeVar569 : f32;
var<private> p0_nodeVar570 : f32;
var<private> p0_nodeVar571 : f32;
var<private> p0_nodeVar572 : f32;
var<private> p0_nodeVar573 : f32;
var<private> p0_nodeVar574 : vec2<f32>;
var<private> p0_nodeVar575 : f32;
var<private> p0_nodeVar576 : f32;
var<private> p0_nodeVar577 : vec4<f32>;
var<private> p0_nodeVar578 : f32;
var<private> p0_nodeVar579 : vec2<f32>;
var<private> p0_nodeVar580 : f32;
var<private> p0_nodeVar581 : f32;
var<private> p0_nodeVar582 : vec4<f32>;
var<private> p0_nodeVar583 : vec2<f32>;
var<private> p0_nodeVar584 : f32;
var<private> p0_nodeVar585 : f32;
var<private> p0_nodeVar586 : vec4<f32>;
var<private> p0_nodeVar587 : f32;
var<private> p0_nodeVar588 : f32;
var<private> p0_nodeVar589 : f32;
var<private> p0_nodeVar590 : f32;
var<private> p0_nodeVar591 : f32;
var<private> p0_nodeVar592 : f32;
var<private> p0_nodeVar593 : f32;
var<private> p0_nodeVar594 : f32;
var<private> p0_nodeVar595 : f32;
var<private> p0_nodeVar596 : f32;
var<private> p0_nodeVar597 : f32;
var<private> p0_nodeVar598 : f32;
var<private> p0_nodeVar599 : f32;
var<private> p0_nodeVar600 : f32;
var<private> p0_nodeVar601 : f32;
var<private> p0_nodeVar602 : f32;
var<private> p0_nodeVar603 : f32;
var<private> p0_nodeVar604 : f32;
var<private> p0_nodeVar605 : f32;
var<private> p0_nodeVar606 : f32;
var<private> p0_nodeVar607 : f32;
var<private> p0_nodeVar608 : f32;
var<private> p0_nodeVar609 : f32;
var<private> p0_nodeVar610 : f32;
var<private> p0_nodeVar611 : f32;
var<private> p0_nodeVar612 : f32;
var<private> p0_nodeVar613 : f32;
var<private> p0_nodeVar614 : f32;
var<private> p0_nodeVar615 : f32;
var<private> p0_nodeVar616 : f32;
var<private> p0_nodeVar617 : f32;
var<private> p0_nodeVar618 : f32;
var<private> p0_nodeVar619 : f32;
var<private> p0_nodeVar620 : f32;
var<private> p0_nodeVar621 : f32;
var<private> p0_nodeVar622 : f32;
var<private> p0_nodeVar623 : f32;
var<private> p0_nodeVar624 : f32;
var<private> p0_nodeVar625 : f32;
var<private> p0_nodeVar626 : f32;
var<private> p0_nodeVar627 : f32;
var<private> p0_nodeVar628 : f32;
var<private> p0_nodeVar629 : f32;
var<private> p0_nodeVar630 : f32;
var<private> p0_nodeVar631 : f32;
var<private> p0_nodeVar632 : f32;
var<private> p0_nodeVar633 : f32;
var<private> p0_nodeVar634 : f32;
var<private> p0_nodeVar635 : f32;
var<private> p0_nodeVar636 : f32;
var<private> p0_nodeVar637 : f32;
var<private> p0_nodeVar638 : f32;
var<private> p0_nodeVar639 : f32;
var<private> p0_nodeVar640 : f32;
var<private> p0_nodeVar641 : vec2<f32>;
var<private> p0_nodeVar642 : f32;
var<private> p0_nodeVar643 : f32;
var<private> p0_nodeVar644 : vec4<f32>;
var<private> p0_nodeVar645 : f32;
var<private> p0_nodeVar646 : vec2<f32>;
var<private> p0_nodeVar647 : f32;
var<private> p0_nodeVar648 : f32;
var<private> p0_nodeVar649 : vec4<f32>;
var<private> p0_nodeVar650 : vec2<f32>;
var<private> p0_nodeVar651 : f32;
var<private> p0_nodeVar652 : f32;
var<private> p0_nodeVar653 : vec4<f32>;
var<private> p0_nodeVar654 : f32;
var<private> p0_nodeVar655 : f32;
var<private> p0_nodeVar656 : f32;
var<private> p0_nodeVar657 : f32;
var<private> p0_nodeVar658 : f32;
var<private> p0_nodeVar659 : f32;
var<private> p0_nodeVar660 : f32;
var<private> p0_nodeVar661 : f32;
var<private> p0_nodeVar662 : f32;
var<private> p0_nodeVar663 : f32;
var<private> p0_nodeVar664 : f32;
var<private> p0_nodeVar665 : f32;
var<private> p0_nodeVar666 : f32;
var<private> p0_nodeVar667 : f32;
var<private> p0_nodeVar668 : f32;
var<private> p0_nodeVar669 : f32;
var<private> p0_nodeVar670 : f32;
var<private> p0_nodeVar671 : f32;
var<private> p0_nodeVar672 : f32;
var<private> p0_nodeVar673 : f32;
var<private> p0_nodeVar674 : f32;
var<private> p0_nodeVar675 : f32;
var<private> p0_nodeVar676 : f32;
var<private> p0_nodeVar677 : f32;
var<private> p0_nodeVar678 : f32;
var<private> p0_nodeVar679 : f32;
var<private> p0_nodeVar680 : f32;
var<private> p0_nodeVar681 : f32;
var<private> p0_nodeVar682 : f32;
var<private> p0_nodeVar683 : f32;
var<private> p0_nodeVar684 : f32;
var<private> p0_nodeVar685 : f32;
var<private> p0_nodeVar686 : f32;
var<private> p0_nodeVar687 : f32;
var<private> p0_nodeVar688 : f32;
var<private> p0_nodeVar689 : f32;
var<private> p0_nodeVar690 : f32;
var<private> p0_nodeVar691 : f32;
var<private> p0_nodeVar692 : f32;
var<private> p0_nodeVar693 : f32;
var<private> p0_nodeVar694 : f32;
var<private> p0_nodeVar695 : f32;
var<private> p0_nodeVar696 : f32;
var<private> p0_nodeVar697 : f32;
var<private> p0_nodeVar698 : f32;
var<private> p0_nodeVar699 : f32;
var<private> p0_nodeVar700 : f32;
var<private> p0_nodeVar701 : f32;
var<private> p0_nodeVar702 : f32;
var<private> p0_nodeVar703 : f32;
var<private> p0_nodeVar704 : f32;
var<private> p0_nodeVar705 : f32;
var<private> p0_nodeVar706 : f32;
var<private> p0_nodeVar707 : f32;
var<private> p0_nodeVar708 : vec2<f32>;
var<private> p0_nodeVar709 : f32;
var<private> p0_nodeVar710 : f32;
var<private> p0_nodeVar711 : vec4<f32>;
var<private> p0_nodeVar712 : f32;
var<private> p0_nodeVar713 : vec2<f32>;
var<private> p0_nodeVar714 : f32;
var<private> p0_nodeVar715 : f32;
var<private> p0_nodeVar716 : vec4<f32>;
var<private> p0_nodeVar717 : vec2<f32>;
var<private> p0_nodeVar718 : f32;
var<private> p0_nodeVar719 : f32;
var<private> p0_nodeVar720 : vec4<f32>;
var<private> p0_nodeVar721 : f32;
var<private> p0_nodeVar722 : f32;
var<private> p0_nodeVar723 : f32;
var<private> p0_nodeVar724 : f32;
var<private> p0_nodeVar725 : f32;
var<private> p0_nodeVar726 : f32;
var<private> p0_nodeVar727 : f32;
var<private> p0_nodeVar728 : f32;
var<private> p0_nodeVar729 : f32;
var<private> p0_nodeVar730 : f32;
var<private> p0_nodeVar731 : f32;
var<private> p0_nodeVar732 : f32;
var<private> p0_nodeVar733 : f32;
var<private> p0_nodeVar734 : f32;
var<private> p0_nodeVar735 : f32;
var<private> p0_nodeVar736 : f32;
var<private> p0_nodeVar737 : f32;
var<private> p0_nodeVar738 : f32;
var<private> p0_nodeVar739 : f32;
var<private> p0_nodeVar740 : f32;
var<private> p0_nodeVar741 : f32;
var<private> p0_nodeVar742 : f32;
var<private> p0_nodeVar743 : f32;
var<private> p0_nodeVar744 : f32;
var<private> p0_nodeVar745 : f32;
var<private> p0_nodeVar746 : f32;
var<private> p0_nodeVar747 : f32;
var<private> p0_nodeVar748 : f32;
var<private> p0_nodeVar749 : f32;
var<private> p0_nodeVar750 : f32;
var<private> p0_nodeVar751 : f32;
var<private> p0_nodeVar752 : f32;
var<private> p0_nodeVar753 : f32;
var<private> p0_nodeVar754 : f32;
var<private> p0_nodeVar755 : f32;
var<private> p0_nodeVar756 : f32;
var<private> p0_nodeVar757 : f32;
var<private> p0_nodeVar758 : f32;
var<private> p0_nodeVar759 : f32;
var<private> p0_nodeVar760 : f32;
var<private> p0_nodeVar761 : f32;
var<private> p0_nodeVar762 : f32;
var<private> p0_nodeVar763 : f32;
var<private> p0_nodeVar764 : f32;
var<private> p0_nodeVar765 : f32;
var<private> p0_nodeVar766 : f32;
var<private> p0_nodeVar767 : f32;
var<private> p0_nodeVar768 : f32;
var<private> p0_nodeVar769 : f32;
var<private> p0_nodeVar770 : f32;
var<private> p0_nodeVar771 : f32;
var<private> p0_nodeVar772 : f32;
var<private> p0_nodeVar773 : f32;
var<private> p0_nodeVar774 : f32;
var<private> p0_nodeVar775 : vec2<f32>;
var<private> p0_nodeVar776 : f32;
var<private> p0_nodeVar777 : f32;
var<private> p0_nodeVar778 : vec4<f32>;
var<private> p0_nodeVar779 : f32;
var<private> p0_nodeVar780 : vec2<f32>;
var<private> p0_nodeVar781 : f32;
var<private> p0_nodeVar782 : f32;
var<private> p0_nodeVar783 : vec4<f32>;
var<private> p0_nodeVar784 : f32;
var<private> p0_nodeVar785 : vec2<f32>;
var<private> p0_nodeVar786 : f32;
var<private> p0_nodeVar787 : f32;
var<private> p0_nodeVar788 : vec4<f32>;
var<private> p0_nodeVar789 : f32;
var<private> p0_nodeVar790 : vec2<f32>;
var<private> p0_nodeVar791 : f32;
var<private> p0_nodeVar792 : f32;
var<private> p0_nodeVar793 : vec4<f32>;
var<private> p0_nodeVar794 : f32;
var<private> p0_nodeVar795 : vec2<f32>;
var<private> p0_nodeVar796 : f32;
var<private> p0_nodeVar797 : f32;
var<private> p0_nodeVar798 : vec4<f32>;
var<private> p0_nodeVar799 : f32;
var<private> p0_nodeVar800 : vec2<f32>;
var<private> p0_nodeVar801 : f32;
var<private> p0_nodeVar802 : f32;
var<private> p0_nodeVar803 : vec4<f32>;
var<private> p0_nodeVar804 : f32;
var<private> p0_nodeVar805 : vec2<f32>;
var<private> p0_nodeVar806 : f32;
var<private> p0_nodeVar807 : f32;
var<private> p0_nodeVar808 : vec4<f32>;
var<private> p0_nodeVar809 : f32;
var<private> p0_nodeVar810 : vec2<f32>;
var<private> p0_nodeVar811 : f32;
var<private> p0_nodeVar812 : f32;
var<private> p0_nodeVar813 : vec4<f32>;
var<private> p0_nodeVar814 : f32;
var<private> p0_nodeVar815 : vec2<f32>;
var<private> p0_nodeVar816 : f32;
var<private> p0_nodeVar817 : f32;
var<private> p0_nodeVar818 : vec4<f32>;
var<private> p0_nodeVar819 : f32;
var<private> p0_nodeVar820 : vec2<f32>;
var<private> p0_nodeVar821 : f32;
var<private> p0_nodeVar822 : f32;
var<private> p0_nodeVar823 : vec4<f32>;
var<private> p0_nodeVar824 : f32;
var<private> p0_nodeVar825 : vec2<f32>;
var<private> p0_nodeVar826 : f32;
var<private> p0_nodeVar827 : f32;
var<private> p0_nodeVar828 : vec4<f32>;
var<private> p0_nodeVar829 : f32;
var<private> p0_nodeVar830 : vec2<f32>;
var<private> p0_nodeVar831 : f32;
var<private> p0_nodeVar832 : f32;
var<private> p0_nodeVar833 : vec4<f32>;
var<private> p0_nodeVar834 : f32;
var<private> p0_nodeVar835 : vec2<f32>;
var<private> p0_nodeVar836 : f32;
var<private> p0_nodeVar837 : f32;
var<private> p0_nodeVar838 : vec4<f32>;
var<private> p0_nodeVar839 : f32;
var<private> p0_nodeVar840 : vec2<f32>;
var<private> p0_nodeVar841 : f32;
var<private> p0_nodeVar842 : f32;
var<private> p0_nodeVar843 : vec4<f32>;
var<private> p0_nodeVar844 : f32;
var<private> p0_nodeVar845 : vec2<f32>;
var<private> p0_nodeVar846 : f32;
var<private> p0_nodeVar847 : f32;
var<private> p0_nodeVar848 : vec4<f32>;
var<private> p0_nodeVar849 : f32;
var<private> p0_nodeVar850 : vec2<f32>;
var<private> p0_nodeVar851 : f32;
var<private> p0_nodeVar852 : f32;
var<private> p0_nodeVar853 : vec4<f32>;
var<private> p0_nodeVar854 : f32;
var<private> p0_nodeVar855 : vec2<f32>;
var<private> p0_nodeVar856 : f32;
var<private> p0_nodeVar857 : f32;
var<private> p0_nodeVar858 : vec4<f32>;
var<private> p0_nodeVar859 : f32;
var<private> p0_nodeVar860 : vec2<f32>;
var<private> p0_nodeVar861 : f32;
var<private> p0_nodeVar862 : f32;
var<private> p0_nodeVar863 : vec4<f32>;
var<private> p0_nodeVar864 : f32;
var<private> p0_nodeVar865 : vec2<f32>;
var<private> p0_nodeVar866 : f32;
var<private> p0_nodeVar867 : f32;
var<private> p0_nodeVar868 : vec4<f32>;
var<private> p0_nodeVar869 : f32;
var<private> p0_nodeVar870 : vec2<f32>;
var<private> p0_nodeVar871 : f32;
var<private> p0_nodeVar872 : f32;
var<private> p0_nodeVar873 : vec4<f32>;
var<private> p0_nodeVar874 : f32;
var<private> p0_nodeVar875 : vec2<f32>;
var<private> p0_nodeVar876 : f32;
var<private> p0_nodeVar877 : f32;
var<private> p0_nodeVar878 : vec4<f32>;
var<private> p0_nodeVar879 : f32;
var<private> p0_nodeVar880 : vec2<f32>;
var<private> p0_nodeVar881 : f32;
var<private> p0_nodeVar882 : f32;
var<private> p0_nodeVar883 : vec4<f32>;
var<private> p0_nodeVar884 : vec4<f32>;
var<private> p0_nodeVar885 : vec3<f32>;
var<private> p0_nodeVar886 : f32;
var<private> p0_nodeVar887 : vec3<f32>;
var<private> p0_nodeVar888 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar889 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar2 = ( f32(knobs.colorMode) > 0.5 );

	if ( p0_nodeVar2 ) {

		p0_nodeVar1 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar3 = ( f32(knobs.lineAngle) * 0.017453292519943295 );
		p0_nodeVar4 = vec2<f32>( cos( p0_nodeVar3 ), sin( p0_nodeVar3 ) );
		p0_nodeVar5 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		p0_nodeVar6 = vec2<f32>( ( p0_nodeVar5.x * f32(knobs.resolution.x) ), ( p0_nodeVar5.y * f32(knobs.resolution.y) ) );
		p0_nodeVar7 = dot( p0_nodeVar6, p0_nodeVar4 );
		p0_nodeVar8 = vec2<f32>( ( - sin( p0_nodeVar3 ) ), cos( p0_nodeVar3 ) );
		p0_nodeVar9 = max( f32(knobs.linePitch), 1.0 );
		p0_nodeVar10 = ( ( ( f32(knobs.time) * f32(knobs.scrollSpeed) ) * p0_nodeVar9 ) * 2.0 );
		p0_nodeVar11 = ( ( ( ( floor( ( ( dot( p0_nodeVar6, p0_nodeVar8 ) + p0_nodeVar10 ) / p0_nodeVar9 ) ) + -5.0 ) * p0_nodeVar9 ) + ( p0_nodeVar9 * 0.5 ) ) - p0_nodeVar10 );
		p0_nodeVar12 = picture_read( vec2<f32>( ( ( ( p0_nodeVar4.x * p0_nodeVar7 ) + ( p0_nodeVar8.x * p0_nodeVar11 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar4.y * p0_nodeVar7 ) + ( p0_nodeVar8.y * p0_nodeVar11 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar1 = vec3<f32>( p0_nodeVar12.x, p0_nodeVar12.y, p0_nodeVar12.z ).x;

	}

	p0_nodeVar13 = ( f32(knobs.lineThickness) * 0.5 );
	p0_nodeVar15 = ( f32(knobs.invert) > 0.5 );

	if ( p0_nodeVar15 ) {

		p0_nodeVar16 = ( f32(knobs.lineAngle) * 0.017453292519943295 );
		p0_nodeVar17 = vec2<f32>( cos( p0_nodeVar16 ), sin( p0_nodeVar16 ) );
		p0_nodeVar18 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		p0_nodeVar19 = vec2<f32>( ( p0_nodeVar18.x * f32(knobs.resolution.x) ), ( p0_nodeVar18.y * f32(knobs.resolution.y) ) );
		p0_nodeVar20 = dot( p0_nodeVar19, p0_nodeVar17 );
		p0_nodeVar21 = vec2<f32>( ( - sin( p0_nodeVar16 ) ), cos( p0_nodeVar16 ) );
		p0_nodeVar22 = max( f32(knobs.linePitch), 1.0 );
		p0_nodeVar23 = ( ( ( f32(knobs.time) * f32(knobs.scrollSpeed) ) * p0_nodeVar22 ) * 2.0 );
		p0_nodeVar24 = ( ( ( ( floor( ( ( dot( p0_nodeVar19, p0_nodeVar21 ) + p0_nodeVar23 ) / p0_nodeVar22 ) ) + -5.0 ) * p0_nodeVar22 ) + ( p0_nodeVar22 * 0.5 ) ) - p0_nodeVar23 );
		p0_nodeVar25 = picture_read( vec2<f32>( ( ( ( p0_nodeVar17.x * p0_nodeVar20 ) + ( p0_nodeVar21.x * p0_nodeVar24 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar17.y * p0_nodeVar20 ) + ( p0_nodeVar21.y * p0_nodeVar24 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar14 = ( 1.0 - dot( vec3<f32>( p0_nodeVar25.x, p0_nodeVar25.y, p0_nodeVar25.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar26 = ( f32(knobs.lineAngle) * 0.017453292519943295 );
		p0_nodeVar27 = vec2<f32>( cos( p0_nodeVar26 ), sin( p0_nodeVar26 ) );
		p0_nodeVar28 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		p0_nodeVar29 = vec2<f32>( ( p0_nodeVar28.x * f32(knobs.resolution.x) ), ( p0_nodeVar28.y * f32(knobs.resolution.y) ) );
		p0_nodeVar30 = dot( p0_nodeVar29, p0_nodeVar27 );
		p0_nodeVar31 = vec2<f32>( ( - sin( p0_nodeVar26 ) ), cos( p0_nodeVar26 ) );
		p0_nodeVar32 = max( f32(knobs.linePitch), 1.0 );
		p0_nodeVar33 = ( ( ( f32(knobs.time) * f32(knobs.scrollSpeed) ) * p0_nodeVar32 ) * 2.0 );
		p0_nodeVar34 = ( ( ( ( floor( ( ( dot( p0_nodeVar29, p0_nodeVar31 ) + p0_nodeVar33 ) / p0_nodeVar32 ) ) + -5.0 ) * p0_nodeVar32 ) + ( p0_nodeVar32 * 0.5 ) ) - p0_nodeVar33 );
		p0_nodeVar35 = picture_read( vec2<f32>( ( ( ( p0_nodeVar27.x * p0_nodeVar30 ) + ( p0_nodeVar31.x * p0_nodeVar34 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar27.y * p0_nodeVar30 ) + ( p0_nodeVar31.y * p0_nodeVar34 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar14 = dot( vec3<f32>( p0_nodeVar35.x, p0_nodeVar35.y, p0_nodeVar35.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar36 = max( ( f32(knobs.signalWhitePoint) - f32(knobs.signalBlackPoint) ), 0.001 );
	p0_nodeVar37 = ( 1.0 / f32(knobs.signalGamma) );
	p0_nodeVar38 = pow( clamp( ( ( p0_nodeVar14 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar39 = ( p0_nodeVar13 + ( p0_nodeVar38 * 0.5 ) );
	p0_nodeVar40 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar41 = vec2<f32>( ( p0_nodeVar40.x * f32(knobs.resolution.x) ), ( p0_nodeVar40.y * f32(knobs.resolution.y) ) );
	p0_nodeVar42 = ( f32(knobs.lineAngle) * 0.017453292519943295 );
	p0_nodeVar43 = vec2<f32>( ( - sin( p0_nodeVar42 ) ), cos( p0_nodeVar42 ) );
	p0_nodeVar44 = max( f32(knobs.linePitch), 1.0 );
	p0_nodeVar45 = ( ( ( f32(knobs.time) * f32(knobs.scrollSpeed) ) * p0_nodeVar44 ) * 2.0 );
	p0_nodeVar46 = ( dot( p0_nodeVar41, p0_nodeVar43 ) + p0_nodeVar45 );
	p0_nodeVar47 = floor( ( p0_nodeVar46 / p0_nodeVar44 ) );
	p0_nodeVar48 = ( p0_nodeVar47 + -5.0 );
	p0_nodeVar49 = ( ( p0_nodeVar48 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );
	p0_nodeVar51 = ( f32(knobs.noiseMode) > 1.5 );

	if ( p0_nodeVar51 ) {

		p0_nodeVar52 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar53 = floor( p0_nodeVar52 );
		p0_nodeVar54 = ( ( p0_nodeVar48 * 0.37 ) + 17.3 );
		p0_nodeVar55 = floor( p0_nodeVar54 );
		p0_nodeVar56 = fract( p0_nodeVar52 );
		p0_nodeVar57 = ( ( p0_nodeVar56 * p0_nodeVar56 ) * ( 3.0 - ( p0_nodeVar56 * 2.0 ) ) );
		p0_nodeVar58 = fract( p0_nodeVar54 );
		p0_nodeVar59 = ( p0_nodeVar52 * 2.1 );
		p0_nodeVar60 = floor( p0_nodeVar59 );
		p0_nodeVar61 = ( p0_nodeVar54 * 2.1 );
		p0_nodeVar62 = floor( p0_nodeVar61 );
		p0_nodeVar63 = fract( p0_nodeVar59 );
		p0_nodeVar64 = ( ( p0_nodeVar63 * p0_nodeVar63 ) * ( 3.0 - ( p0_nodeVar63 * 2.0 ) ) );
		p0_nodeVar65 = fract( p0_nodeVar61 );
		p0_nodeVar66 = ( p0_nodeVar52 * 4.3 );
		p0_nodeVar67 = floor( p0_nodeVar66 );
		p0_nodeVar68 = ( p0_nodeVar54 * 4.3 );
		p0_nodeVar69 = floor( p0_nodeVar68 );
		p0_nodeVar70 = fract( p0_nodeVar66 );
		p0_nodeVar71 = ( ( p0_nodeVar70 * p0_nodeVar70 ) * ( 3.0 - ( p0_nodeVar70 * 2.0 ) ) );
		p0_nodeVar72 = fract( p0_nodeVar68 );
		p0_nodeVar50 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar53 * 127.1 ) + ( p0_nodeVar55 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar53 + 1.0 ) * 127.1 ) + ( p0_nodeVar55 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar57 ), mix( fract( ( sin( ( ( p0_nodeVar53 * 127.1 ) + ( ( p0_nodeVar55 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar53 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar55 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar57 ), ( ( p0_nodeVar58 * p0_nodeVar58 ) * ( 3.0 - ( p0_nodeVar58 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar60 * 127.1 ) + ( p0_nodeVar62 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar60 + 1.0 ) * 127.1 ) + ( p0_nodeVar62 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar64 ), mix( fract( ( sin( ( ( p0_nodeVar60 * 127.1 ) + ( ( p0_nodeVar62 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar60 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar62 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar64 ), ( ( p0_nodeVar65 * p0_nodeVar65 ) * ( 3.0 - ( p0_nodeVar65 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar67 * 127.1 ) + ( p0_nodeVar69 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar67 + 1.0 ) * 127.1 ) + ( p0_nodeVar69 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar71 ), mix( fract( ( sin( ( ( p0_nodeVar67 * 127.1 ) + ( ( p0_nodeVar69 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar67 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar69 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar71 ), ( ( p0_nodeVar72 * p0_nodeVar72 ) * ( 3.0 - ( p0_nodeVar72 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar74 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar75 = floor( p0_nodeVar74 );
			p0_nodeVar76 = ( ( p0_nodeVar48 * 0.37 ) + 17.3 );
			p0_nodeVar77 = floor( p0_nodeVar76 );
			p0_nodeVar78 = fract( p0_nodeVar74 );
			p0_nodeVar79 = ( ( p0_nodeVar78 * p0_nodeVar78 ) * ( 3.0 - ( p0_nodeVar78 * 2.0 ) ) );
			p0_nodeVar80 = fract( p0_nodeVar76 );
			p0_nodeVar81 = ( p0_nodeVar74 * 2.1 );
			p0_nodeVar82 = floor( p0_nodeVar81 );
			p0_nodeVar83 = ( p0_nodeVar76 * 2.1 );
			p0_nodeVar84 = floor( p0_nodeVar83 );
			p0_nodeVar85 = fract( p0_nodeVar81 );
			p0_nodeVar86 = ( ( p0_nodeVar85 * p0_nodeVar85 ) * ( 3.0 - ( p0_nodeVar85 * 2.0 ) ) );
			p0_nodeVar87 = fract( p0_nodeVar83 );
			p0_nodeVar88 = ( p0_nodeVar74 * 4.3 );
			p0_nodeVar89 = floor( p0_nodeVar88 );
			p0_nodeVar90 = ( p0_nodeVar76 * 4.3 );
			p0_nodeVar91 = floor( p0_nodeVar90 );
			p0_nodeVar92 = fract( p0_nodeVar88 );
			p0_nodeVar93 = ( ( p0_nodeVar92 * p0_nodeVar92 ) * ( 3.0 - ( p0_nodeVar92 * 2.0 ) ) );
			p0_nodeVar94 = fract( p0_nodeVar90 );
			p0_nodeVar73 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar75 * 127.1 ) + ( p0_nodeVar77 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar75 + 1.0 ) * 127.1 ) + ( p0_nodeVar77 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar79 ), mix( fract( ( sin( ( ( p0_nodeVar75 * 127.1 ) + ( ( p0_nodeVar77 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar75 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar77 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar79 ), ( ( p0_nodeVar80 * p0_nodeVar80 ) * ( 3.0 - ( p0_nodeVar80 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar82 * 127.1 ) + ( p0_nodeVar84 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar82 + 1.0 ) * 127.1 ) + ( p0_nodeVar84 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar86 ), mix( fract( ( sin( ( ( p0_nodeVar82 * 127.1 ) + ( ( p0_nodeVar84 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar82 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar84 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar86 ), ( ( p0_nodeVar87 * p0_nodeVar87 ) * ( 3.0 - ( p0_nodeVar87 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar89 * 127.1 ) + ( p0_nodeVar91 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar89 + 1.0 ) * 127.1 ) + ( p0_nodeVar91 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar93 ), mix( fract( ( sin( ( ( p0_nodeVar89 * 127.1 ) + ( ( p0_nodeVar91 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar89 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar91 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar93 ), ( ( p0_nodeVar94 * p0_nodeVar94 ) * ( 3.0 - ( p0_nodeVar94 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar95 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar73 = ( ( ( sin( ( ( p0_nodeVar95 * 0.004 ) + ( p0_nodeVar48 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar95 * 0.011 ) + ( p0_nodeVar48 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar95 * 0.0023 ) + ( p0_nodeVar48 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar50 = p0_nodeVar73;

	}

	p0_nodeVar96 = abs( ( p0_nodeVar46 - ( p0_nodeVar49 + ( ( ( p0_nodeVar38 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar50 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar97 = ( 1.0 - f32(knobs.presenceThreshold) );
	p0_nodeVar98 = max( ( f32(knobs.presenceSoftness) * 0.5 ), 0.001 );
	p0_nodeVar99 = ( p0_nodeVar97 - p0_nodeVar98 );
	p0_nodeVar100 = ( p0_nodeVar97 + p0_nodeVar98 );
	p0_nodeVar101 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar38 );
	p0_nodeVar102 = ( p0_nodeVar39 + ( ( p0_nodeVar38 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar103 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar39 - 1.0 ) ), ( p0_nodeVar39 + 1.0 ), p0_nodeVar96 ) ) * p0_nodeVar101 ) * p0_nodeVar38 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar102 - 2.0 ) ), ( p0_nodeVar102 + 2.0 ), p0_nodeVar96 ) ) * p0_nodeVar101 ) * ( p0_nodeVar38 * p0_nodeVar38 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar104 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar105 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar106 = dot( p0_nodeVar41, p0_nodeVar105 );
		p0_nodeVar107 = ( ( ( ( p0_nodeVar47 + -4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar108 = picture_read( vec2<f32>( ( ( ( p0_nodeVar105.x * p0_nodeVar106 ) + ( p0_nodeVar43.x * p0_nodeVar107 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar105.y * p0_nodeVar106 ) + ( p0_nodeVar43.y * p0_nodeVar107 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar104 = vec3<f32>( p0_nodeVar108.x, p0_nodeVar108.y, p0_nodeVar108.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar110 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar111 = dot( p0_nodeVar41, p0_nodeVar110 );
		p0_nodeVar112 = ( ( ( ( p0_nodeVar47 + -4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar113 = picture_read( vec2<f32>( ( ( ( p0_nodeVar110.x * p0_nodeVar111 ) + ( p0_nodeVar43.x * p0_nodeVar112 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar110.y * p0_nodeVar111 ) + ( p0_nodeVar43.y * p0_nodeVar112 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar109 = ( 1.0 - dot( vec3<f32>( p0_nodeVar113.x, p0_nodeVar113.y, p0_nodeVar113.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar114 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar115 = dot( p0_nodeVar41, p0_nodeVar114 );
		p0_nodeVar116 = ( ( ( ( p0_nodeVar47 + -4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar117 = picture_read( vec2<f32>( ( ( ( p0_nodeVar114.x * p0_nodeVar115 ) + ( p0_nodeVar43.x * p0_nodeVar116 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar114.y * p0_nodeVar115 ) + ( p0_nodeVar43.y * p0_nodeVar116 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar109 = dot( vec3<f32>( p0_nodeVar117.x, p0_nodeVar117.y, p0_nodeVar117.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar118 = pow( clamp( ( ( p0_nodeVar109 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar119 = ( p0_nodeVar13 + ( p0_nodeVar118 * 0.5 ) );
	p0_nodeVar120 = ( p0_nodeVar47 + -4.0 );
	p0_nodeVar121 = ( ( p0_nodeVar120 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar123 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar124 = floor( p0_nodeVar123 );
		p0_nodeVar125 = ( ( p0_nodeVar120 * 0.37 ) + 17.3 );
		p0_nodeVar126 = floor( p0_nodeVar125 );
		p0_nodeVar127 = fract( p0_nodeVar123 );
		p0_nodeVar128 = ( ( p0_nodeVar127 * p0_nodeVar127 ) * ( 3.0 - ( p0_nodeVar127 * 2.0 ) ) );
		p0_nodeVar129 = fract( p0_nodeVar125 );
		p0_nodeVar130 = ( p0_nodeVar123 * 2.1 );
		p0_nodeVar131 = floor( p0_nodeVar130 );
		p0_nodeVar132 = ( p0_nodeVar125 * 2.1 );
		p0_nodeVar133 = floor( p0_nodeVar132 );
		p0_nodeVar134 = fract( p0_nodeVar130 );
		p0_nodeVar135 = ( ( p0_nodeVar134 * p0_nodeVar134 ) * ( 3.0 - ( p0_nodeVar134 * 2.0 ) ) );
		p0_nodeVar136 = fract( p0_nodeVar132 );
		p0_nodeVar137 = ( p0_nodeVar123 * 4.3 );
		p0_nodeVar138 = floor( p0_nodeVar137 );
		p0_nodeVar139 = ( p0_nodeVar125 * 4.3 );
		p0_nodeVar140 = floor( p0_nodeVar139 );
		p0_nodeVar141 = fract( p0_nodeVar137 );
		p0_nodeVar142 = ( ( p0_nodeVar141 * p0_nodeVar141 ) * ( 3.0 - ( p0_nodeVar141 * 2.0 ) ) );
		p0_nodeVar143 = fract( p0_nodeVar139 );
		p0_nodeVar122 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar124 * 127.1 ) + ( p0_nodeVar126 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar124 + 1.0 ) * 127.1 ) + ( p0_nodeVar126 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar128 ), mix( fract( ( sin( ( ( p0_nodeVar124 * 127.1 ) + ( ( p0_nodeVar126 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar124 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar126 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar128 ), ( ( p0_nodeVar129 * p0_nodeVar129 ) * ( 3.0 - ( p0_nodeVar129 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar131 * 127.1 ) + ( p0_nodeVar133 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar131 + 1.0 ) * 127.1 ) + ( p0_nodeVar133 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar135 ), mix( fract( ( sin( ( ( p0_nodeVar131 * 127.1 ) + ( ( p0_nodeVar133 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar131 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar133 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar135 ), ( ( p0_nodeVar136 * p0_nodeVar136 ) * ( 3.0 - ( p0_nodeVar136 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar138 * 127.1 ) + ( p0_nodeVar140 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar138 + 1.0 ) * 127.1 ) + ( p0_nodeVar140 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar142 ), mix( fract( ( sin( ( ( p0_nodeVar138 * 127.1 ) + ( ( p0_nodeVar140 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar138 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar140 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar142 ), ( ( p0_nodeVar143 * p0_nodeVar143 ) * ( 3.0 - ( p0_nodeVar143 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar145 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar146 = floor( p0_nodeVar145 );
			p0_nodeVar147 = ( ( p0_nodeVar120 * 0.37 ) + 17.3 );
			p0_nodeVar148 = floor( p0_nodeVar147 );
			p0_nodeVar149 = fract( p0_nodeVar145 );
			p0_nodeVar150 = ( ( p0_nodeVar149 * p0_nodeVar149 ) * ( 3.0 - ( p0_nodeVar149 * 2.0 ) ) );
			p0_nodeVar151 = fract( p0_nodeVar147 );
			p0_nodeVar152 = ( p0_nodeVar145 * 2.1 );
			p0_nodeVar153 = floor( p0_nodeVar152 );
			p0_nodeVar154 = ( p0_nodeVar147 * 2.1 );
			p0_nodeVar155 = floor( p0_nodeVar154 );
			p0_nodeVar156 = fract( p0_nodeVar152 );
			p0_nodeVar157 = ( ( p0_nodeVar156 * p0_nodeVar156 ) * ( 3.0 - ( p0_nodeVar156 * 2.0 ) ) );
			p0_nodeVar158 = fract( p0_nodeVar154 );
			p0_nodeVar159 = ( p0_nodeVar145 * 4.3 );
			p0_nodeVar160 = floor( p0_nodeVar159 );
			p0_nodeVar161 = ( p0_nodeVar147 * 4.3 );
			p0_nodeVar162 = floor( p0_nodeVar161 );
			p0_nodeVar163 = fract( p0_nodeVar159 );
			p0_nodeVar164 = ( ( p0_nodeVar163 * p0_nodeVar163 ) * ( 3.0 - ( p0_nodeVar163 * 2.0 ) ) );
			p0_nodeVar165 = fract( p0_nodeVar161 );
			p0_nodeVar144 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar146 * 127.1 ) + ( p0_nodeVar148 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar146 + 1.0 ) * 127.1 ) + ( p0_nodeVar148 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar150 ), mix( fract( ( sin( ( ( p0_nodeVar146 * 127.1 ) + ( ( p0_nodeVar148 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar146 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar148 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar150 ), ( ( p0_nodeVar151 * p0_nodeVar151 ) * ( 3.0 - ( p0_nodeVar151 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar153 * 127.1 ) + ( p0_nodeVar155 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar153 + 1.0 ) * 127.1 ) + ( p0_nodeVar155 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar157 ), mix( fract( ( sin( ( ( p0_nodeVar153 * 127.1 ) + ( ( p0_nodeVar155 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar153 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar155 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar157 ), ( ( p0_nodeVar158 * p0_nodeVar158 ) * ( 3.0 - ( p0_nodeVar158 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar160 * 127.1 ) + ( p0_nodeVar162 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar160 + 1.0 ) * 127.1 ) + ( p0_nodeVar162 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar164 ), mix( fract( ( sin( ( ( p0_nodeVar160 * 127.1 ) + ( ( p0_nodeVar162 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar160 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar162 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar164 ), ( ( p0_nodeVar165 * p0_nodeVar165 ) * ( 3.0 - ( p0_nodeVar165 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar166 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar144 = ( ( ( sin( ( ( p0_nodeVar166 * 0.004 ) + ( p0_nodeVar120 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar166 * 0.011 ) + ( p0_nodeVar120 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar166 * 0.0023 ) + ( p0_nodeVar120 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar122 = p0_nodeVar144;

	}

	p0_nodeVar167 = abs( ( p0_nodeVar46 - ( p0_nodeVar121 + ( ( ( p0_nodeVar118 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar122 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar168 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar118 );
	p0_nodeVar169 = ( p0_nodeVar119 + ( ( p0_nodeVar118 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar170 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar119 - 1.0 ) ), ( p0_nodeVar119 + 1.0 ), p0_nodeVar167 ) ) * p0_nodeVar168 ) * p0_nodeVar118 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar169 - 2.0 ) ), ( p0_nodeVar169 + 2.0 ), p0_nodeVar167 ) ) * p0_nodeVar168 ) * ( p0_nodeVar118 * p0_nodeVar118 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar171 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar172 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar173 = dot( p0_nodeVar41, p0_nodeVar172 );
		p0_nodeVar174 = ( ( ( ( p0_nodeVar47 + -3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar175 = picture_read( vec2<f32>( ( ( ( p0_nodeVar172.x * p0_nodeVar173 ) + ( p0_nodeVar43.x * p0_nodeVar174 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar172.y * p0_nodeVar173 ) + ( p0_nodeVar43.y * p0_nodeVar174 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar171 = vec3<f32>( p0_nodeVar175.x, p0_nodeVar175.y, p0_nodeVar175.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar177 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar178 = dot( p0_nodeVar41, p0_nodeVar177 );
		p0_nodeVar179 = ( ( ( ( p0_nodeVar47 + -3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar180 = picture_read( vec2<f32>( ( ( ( p0_nodeVar177.x * p0_nodeVar178 ) + ( p0_nodeVar43.x * p0_nodeVar179 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar177.y * p0_nodeVar178 ) + ( p0_nodeVar43.y * p0_nodeVar179 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar176 = ( 1.0 - dot( vec3<f32>( p0_nodeVar180.x, p0_nodeVar180.y, p0_nodeVar180.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar181 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar182 = dot( p0_nodeVar41, p0_nodeVar181 );
		p0_nodeVar183 = ( ( ( ( p0_nodeVar47 + -3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar184 = picture_read( vec2<f32>( ( ( ( p0_nodeVar181.x * p0_nodeVar182 ) + ( p0_nodeVar43.x * p0_nodeVar183 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar181.y * p0_nodeVar182 ) + ( p0_nodeVar43.y * p0_nodeVar183 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar176 = dot( vec3<f32>( p0_nodeVar184.x, p0_nodeVar184.y, p0_nodeVar184.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar185 = pow( clamp( ( ( p0_nodeVar176 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar186 = ( p0_nodeVar13 + ( p0_nodeVar185 * 0.5 ) );
	p0_nodeVar187 = ( p0_nodeVar47 + -3.0 );
	p0_nodeVar188 = ( ( p0_nodeVar187 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar190 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar191 = floor( p0_nodeVar190 );
		p0_nodeVar192 = ( ( p0_nodeVar187 * 0.37 ) + 17.3 );
		p0_nodeVar193 = floor( p0_nodeVar192 );
		p0_nodeVar194 = fract( p0_nodeVar190 );
		p0_nodeVar195 = ( ( p0_nodeVar194 * p0_nodeVar194 ) * ( 3.0 - ( p0_nodeVar194 * 2.0 ) ) );
		p0_nodeVar196 = fract( p0_nodeVar192 );
		p0_nodeVar197 = ( p0_nodeVar190 * 2.1 );
		p0_nodeVar198 = floor( p0_nodeVar197 );
		p0_nodeVar199 = ( p0_nodeVar192 * 2.1 );
		p0_nodeVar200 = floor( p0_nodeVar199 );
		p0_nodeVar201 = fract( p0_nodeVar197 );
		p0_nodeVar202 = ( ( p0_nodeVar201 * p0_nodeVar201 ) * ( 3.0 - ( p0_nodeVar201 * 2.0 ) ) );
		p0_nodeVar203 = fract( p0_nodeVar199 );
		p0_nodeVar204 = ( p0_nodeVar190 * 4.3 );
		p0_nodeVar205 = floor( p0_nodeVar204 );
		p0_nodeVar206 = ( p0_nodeVar192 * 4.3 );
		p0_nodeVar207 = floor( p0_nodeVar206 );
		p0_nodeVar208 = fract( p0_nodeVar204 );
		p0_nodeVar209 = ( ( p0_nodeVar208 * p0_nodeVar208 ) * ( 3.0 - ( p0_nodeVar208 * 2.0 ) ) );
		p0_nodeVar210 = fract( p0_nodeVar206 );
		p0_nodeVar189 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar191 * 127.1 ) + ( p0_nodeVar193 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar191 + 1.0 ) * 127.1 ) + ( p0_nodeVar193 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar195 ), mix( fract( ( sin( ( ( p0_nodeVar191 * 127.1 ) + ( ( p0_nodeVar193 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar191 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar193 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar195 ), ( ( p0_nodeVar196 * p0_nodeVar196 ) * ( 3.0 - ( p0_nodeVar196 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar198 * 127.1 ) + ( p0_nodeVar200 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar198 + 1.0 ) * 127.1 ) + ( p0_nodeVar200 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar202 ), mix( fract( ( sin( ( ( p0_nodeVar198 * 127.1 ) + ( ( p0_nodeVar200 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar198 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar200 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar202 ), ( ( p0_nodeVar203 * p0_nodeVar203 ) * ( 3.0 - ( p0_nodeVar203 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar205 * 127.1 ) + ( p0_nodeVar207 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar205 + 1.0 ) * 127.1 ) + ( p0_nodeVar207 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar209 ), mix( fract( ( sin( ( ( p0_nodeVar205 * 127.1 ) + ( ( p0_nodeVar207 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar205 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar207 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar209 ), ( ( p0_nodeVar210 * p0_nodeVar210 ) * ( 3.0 - ( p0_nodeVar210 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar212 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar213 = floor( p0_nodeVar212 );
			p0_nodeVar214 = ( ( p0_nodeVar187 * 0.37 ) + 17.3 );
			p0_nodeVar215 = floor( p0_nodeVar214 );
			p0_nodeVar216 = fract( p0_nodeVar212 );
			p0_nodeVar217 = ( ( p0_nodeVar216 * p0_nodeVar216 ) * ( 3.0 - ( p0_nodeVar216 * 2.0 ) ) );
			p0_nodeVar218 = fract( p0_nodeVar214 );
			p0_nodeVar219 = ( p0_nodeVar212 * 2.1 );
			p0_nodeVar220 = floor( p0_nodeVar219 );
			p0_nodeVar221 = ( p0_nodeVar214 * 2.1 );
			p0_nodeVar222 = floor( p0_nodeVar221 );
			p0_nodeVar223 = fract( p0_nodeVar219 );
			p0_nodeVar224 = ( ( p0_nodeVar223 * p0_nodeVar223 ) * ( 3.0 - ( p0_nodeVar223 * 2.0 ) ) );
			p0_nodeVar225 = fract( p0_nodeVar221 );
			p0_nodeVar226 = ( p0_nodeVar212 * 4.3 );
			p0_nodeVar227 = floor( p0_nodeVar226 );
			p0_nodeVar228 = ( p0_nodeVar214 * 4.3 );
			p0_nodeVar229 = floor( p0_nodeVar228 );
			p0_nodeVar230 = fract( p0_nodeVar226 );
			p0_nodeVar231 = ( ( p0_nodeVar230 * p0_nodeVar230 ) * ( 3.0 - ( p0_nodeVar230 * 2.0 ) ) );
			p0_nodeVar232 = fract( p0_nodeVar228 );
			p0_nodeVar211 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar213 * 127.1 ) + ( p0_nodeVar215 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar213 + 1.0 ) * 127.1 ) + ( p0_nodeVar215 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar217 ), mix( fract( ( sin( ( ( p0_nodeVar213 * 127.1 ) + ( ( p0_nodeVar215 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar213 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar215 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar217 ), ( ( p0_nodeVar218 * p0_nodeVar218 ) * ( 3.0 - ( p0_nodeVar218 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar220 * 127.1 ) + ( p0_nodeVar222 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar220 + 1.0 ) * 127.1 ) + ( p0_nodeVar222 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar224 ), mix( fract( ( sin( ( ( p0_nodeVar220 * 127.1 ) + ( ( p0_nodeVar222 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar220 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar222 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar224 ), ( ( p0_nodeVar225 * p0_nodeVar225 ) * ( 3.0 - ( p0_nodeVar225 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar227 * 127.1 ) + ( p0_nodeVar229 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar227 + 1.0 ) * 127.1 ) + ( p0_nodeVar229 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar231 ), mix( fract( ( sin( ( ( p0_nodeVar227 * 127.1 ) + ( ( p0_nodeVar229 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar227 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar229 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar231 ), ( ( p0_nodeVar232 * p0_nodeVar232 ) * ( 3.0 - ( p0_nodeVar232 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar233 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar211 = ( ( ( sin( ( ( p0_nodeVar233 * 0.004 ) + ( p0_nodeVar187 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar233 * 0.011 ) + ( p0_nodeVar187 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar233 * 0.0023 ) + ( p0_nodeVar187 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar189 = p0_nodeVar211;

	}

	p0_nodeVar234 = abs( ( p0_nodeVar46 - ( p0_nodeVar188 + ( ( ( p0_nodeVar185 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar189 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar235 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar185 );
	p0_nodeVar236 = ( p0_nodeVar186 + ( ( p0_nodeVar185 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar237 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar186 - 1.0 ) ), ( p0_nodeVar186 + 1.0 ), p0_nodeVar234 ) ) * p0_nodeVar235 ) * p0_nodeVar185 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar236 - 2.0 ) ), ( p0_nodeVar236 + 2.0 ), p0_nodeVar234 ) ) * p0_nodeVar235 ) * ( p0_nodeVar185 * p0_nodeVar185 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar238 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar239 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar240 = dot( p0_nodeVar41, p0_nodeVar239 );
		p0_nodeVar241 = ( ( ( ( p0_nodeVar47 + -2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar242 = picture_read( vec2<f32>( ( ( ( p0_nodeVar239.x * p0_nodeVar240 ) + ( p0_nodeVar43.x * p0_nodeVar241 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar239.y * p0_nodeVar240 ) + ( p0_nodeVar43.y * p0_nodeVar241 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar238 = vec3<f32>( p0_nodeVar242.x, p0_nodeVar242.y, p0_nodeVar242.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar244 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar245 = dot( p0_nodeVar41, p0_nodeVar244 );
		p0_nodeVar246 = ( ( ( ( p0_nodeVar47 + -2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar247 = picture_read( vec2<f32>( ( ( ( p0_nodeVar244.x * p0_nodeVar245 ) + ( p0_nodeVar43.x * p0_nodeVar246 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar244.y * p0_nodeVar245 ) + ( p0_nodeVar43.y * p0_nodeVar246 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar243 = ( 1.0 - dot( vec3<f32>( p0_nodeVar247.x, p0_nodeVar247.y, p0_nodeVar247.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar248 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar249 = dot( p0_nodeVar41, p0_nodeVar248 );
		p0_nodeVar250 = ( ( ( ( p0_nodeVar47 + -2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar251 = picture_read( vec2<f32>( ( ( ( p0_nodeVar248.x * p0_nodeVar249 ) + ( p0_nodeVar43.x * p0_nodeVar250 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar248.y * p0_nodeVar249 ) + ( p0_nodeVar43.y * p0_nodeVar250 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar243 = dot( vec3<f32>( p0_nodeVar251.x, p0_nodeVar251.y, p0_nodeVar251.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar252 = pow( clamp( ( ( p0_nodeVar243 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar253 = ( p0_nodeVar13 + ( p0_nodeVar252 * 0.5 ) );
	p0_nodeVar254 = ( p0_nodeVar47 + -2.0 );
	p0_nodeVar255 = ( ( p0_nodeVar254 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar257 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar258 = floor( p0_nodeVar257 );
		p0_nodeVar259 = ( ( p0_nodeVar254 * 0.37 ) + 17.3 );
		p0_nodeVar260 = floor( p0_nodeVar259 );
		p0_nodeVar261 = fract( p0_nodeVar257 );
		p0_nodeVar262 = ( ( p0_nodeVar261 * p0_nodeVar261 ) * ( 3.0 - ( p0_nodeVar261 * 2.0 ) ) );
		p0_nodeVar263 = fract( p0_nodeVar259 );
		p0_nodeVar264 = ( p0_nodeVar257 * 2.1 );
		p0_nodeVar265 = floor( p0_nodeVar264 );
		p0_nodeVar266 = ( p0_nodeVar259 * 2.1 );
		p0_nodeVar267 = floor( p0_nodeVar266 );
		p0_nodeVar268 = fract( p0_nodeVar264 );
		p0_nodeVar269 = ( ( p0_nodeVar268 * p0_nodeVar268 ) * ( 3.0 - ( p0_nodeVar268 * 2.0 ) ) );
		p0_nodeVar270 = fract( p0_nodeVar266 );
		p0_nodeVar271 = ( p0_nodeVar257 * 4.3 );
		p0_nodeVar272 = floor( p0_nodeVar271 );
		p0_nodeVar273 = ( p0_nodeVar259 * 4.3 );
		p0_nodeVar274 = floor( p0_nodeVar273 );
		p0_nodeVar275 = fract( p0_nodeVar271 );
		p0_nodeVar276 = ( ( p0_nodeVar275 * p0_nodeVar275 ) * ( 3.0 - ( p0_nodeVar275 * 2.0 ) ) );
		p0_nodeVar277 = fract( p0_nodeVar273 );
		p0_nodeVar256 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar258 * 127.1 ) + ( p0_nodeVar260 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar258 + 1.0 ) * 127.1 ) + ( p0_nodeVar260 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar262 ), mix( fract( ( sin( ( ( p0_nodeVar258 * 127.1 ) + ( ( p0_nodeVar260 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar258 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar260 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar262 ), ( ( p0_nodeVar263 * p0_nodeVar263 ) * ( 3.0 - ( p0_nodeVar263 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar265 * 127.1 ) + ( p0_nodeVar267 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar265 + 1.0 ) * 127.1 ) + ( p0_nodeVar267 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar269 ), mix( fract( ( sin( ( ( p0_nodeVar265 * 127.1 ) + ( ( p0_nodeVar267 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar265 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar267 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar269 ), ( ( p0_nodeVar270 * p0_nodeVar270 ) * ( 3.0 - ( p0_nodeVar270 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar272 * 127.1 ) + ( p0_nodeVar274 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar272 + 1.0 ) * 127.1 ) + ( p0_nodeVar274 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar276 ), mix( fract( ( sin( ( ( p0_nodeVar272 * 127.1 ) + ( ( p0_nodeVar274 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar272 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar274 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar276 ), ( ( p0_nodeVar277 * p0_nodeVar277 ) * ( 3.0 - ( p0_nodeVar277 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar279 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar280 = floor( p0_nodeVar279 );
			p0_nodeVar281 = ( ( p0_nodeVar254 * 0.37 ) + 17.3 );
			p0_nodeVar282 = floor( p0_nodeVar281 );
			p0_nodeVar283 = fract( p0_nodeVar279 );
			p0_nodeVar284 = ( ( p0_nodeVar283 * p0_nodeVar283 ) * ( 3.0 - ( p0_nodeVar283 * 2.0 ) ) );
			p0_nodeVar285 = fract( p0_nodeVar281 );
			p0_nodeVar286 = ( p0_nodeVar279 * 2.1 );
			p0_nodeVar287 = floor( p0_nodeVar286 );
			p0_nodeVar288 = ( p0_nodeVar281 * 2.1 );
			p0_nodeVar289 = floor( p0_nodeVar288 );
			p0_nodeVar290 = fract( p0_nodeVar286 );
			p0_nodeVar291 = ( ( p0_nodeVar290 * p0_nodeVar290 ) * ( 3.0 - ( p0_nodeVar290 * 2.0 ) ) );
			p0_nodeVar292 = fract( p0_nodeVar288 );
			p0_nodeVar293 = ( p0_nodeVar279 * 4.3 );
			p0_nodeVar294 = floor( p0_nodeVar293 );
			p0_nodeVar295 = ( p0_nodeVar281 * 4.3 );
			p0_nodeVar296 = floor( p0_nodeVar295 );
			p0_nodeVar297 = fract( p0_nodeVar293 );
			p0_nodeVar298 = ( ( p0_nodeVar297 * p0_nodeVar297 ) * ( 3.0 - ( p0_nodeVar297 * 2.0 ) ) );
			p0_nodeVar299 = fract( p0_nodeVar295 );
			p0_nodeVar278 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar280 * 127.1 ) + ( p0_nodeVar282 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar280 + 1.0 ) * 127.1 ) + ( p0_nodeVar282 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar284 ), mix( fract( ( sin( ( ( p0_nodeVar280 * 127.1 ) + ( ( p0_nodeVar282 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar280 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar282 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar284 ), ( ( p0_nodeVar285 * p0_nodeVar285 ) * ( 3.0 - ( p0_nodeVar285 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar287 * 127.1 ) + ( p0_nodeVar289 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar287 + 1.0 ) * 127.1 ) + ( p0_nodeVar289 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar291 ), mix( fract( ( sin( ( ( p0_nodeVar287 * 127.1 ) + ( ( p0_nodeVar289 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar287 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar289 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar291 ), ( ( p0_nodeVar292 * p0_nodeVar292 ) * ( 3.0 - ( p0_nodeVar292 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar294 * 127.1 ) + ( p0_nodeVar296 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar294 + 1.0 ) * 127.1 ) + ( p0_nodeVar296 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar298 ), mix( fract( ( sin( ( ( p0_nodeVar294 * 127.1 ) + ( ( p0_nodeVar296 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar294 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar296 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar298 ), ( ( p0_nodeVar299 * p0_nodeVar299 ) * ( 3.0 - ( p0_nodeVar299 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar300 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar278 = ( ( ( sin( ( ( p0_nodeVar300 * 0.004 ) + ( p0_nodeVar254 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar300 * 0.011 ) + ( p0_nodeVar254 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar300 * 0.0023 ) + ( p0_nodeVar254 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar256 = p0_nodeVar278;

	}

	p0_nodeVar301 = abs( ( p0_nodeVar46 - ( p0_nodeVar255 + ( ( ( p0_nodeVar252 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar256 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar302 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar252 );
	p0_nodeVar303 = ( p0_nodeVar253 + ( ( p0_nodeVar252 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar304 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar253 - 1.0 ) ), ( p0_nodeVar253 + 1.0 ), p0_nodeVar301 ) ) * p0_nodeVar302 ) * p0_nodeVar252 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar303 - 2.0 ) ), ( p0_nodeVar303 + 2.0 ), p0_nodeVar301 ) ) * p0_nodeVar302 ) * ( p0_nodeVar252 * p0_nodeVar252 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar305 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar306 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar307 = dot( p0_nodeVar41, p0_nodeVar306 );
		p0_nodeVar308 = ( ( ( ( p0_nodeVar47 + -1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar309 = picture_read( vec2<f32>( ( ( ( p0_nodeVar306.x * p0_nodeVar307 ) + ( p0_nodeVar43.x * p0_nodeVar308 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar306.y * p0_nodeVar307 ) + ( p0_nodeVar43.y * p0_nodeVar308 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar305 = vec3<f32>( p0_nodeVar309.x, p0_nodeVar309.y, p0_nodeVar309.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar311 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar312 = dot( p0_nodeVar41, p0_nodeVar311 );
		p0_nodeVar313 = ( ( ( ( p0_nodeVar47 + -1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar314 = picture_read( vec2<f32>( ( ( ( p0_nodeVar311.x * p0_nodeVar312 ) + ( p0_nodeVar43.x * p0_nodeVar313 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar311.y * p0_nodeVar312 ) + ( p0_nodeVar43.y * p0_nodeVar313 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar310 = ( 1.0 - dot( vec3<f32>( p0_nodeVar314.x, p0_nodeVar314.y, p0_nodeVar314.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar315 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar316 = dot( p0_nodeVar41, p0_nodeVar315 );
		p0_nodeVar317 = ( ( ( ( p0_nodeVar47 + -1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar318 = picture_read( vec2<f32>( ( ( ( p0_nodeVar315.x * p0_nodeVar316 ) + ( p0_nodeVar43.x * p0_nodeVar317 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar315.y * p0_nodeVar316 ) + ( p0_nodeVar43.y * p0_nodeVar317 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar310 = dot( vec3<f32>( p0_nodeVar318.x, p0_nodeVar318.y, p0_nodeVar318.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar319 = pow( clamp( ( ( p0_nodeVar310 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar320 = ( p0_nodeVar13 + ( p0_nodeVar319 * 0.5 ) );
	p0_nodeVar321 = ( p0_nodeVar47 + -1.0 );
	p0_nodeVar322 = ( ( p0_nodeVar321 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar324 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar325 = floor( p0_nodeVar324 );
		p0_nodeVar326 = ( ( p0_nodeVar321 * 0.37 ) + 17.3 );
		p0_nodeVar327 = floor( p0_nodeVar326 );
		p0_nodeVar328 = fract( p0_nodeVar324 );
		p0_nodeVar329 = ( ( p0_nodeVar328 * p0_nodeVar328 ) * ( 3.0 - ( p0_nodeVar328 * 2.0 ) ) );
		p0_nodeVar330 = fract( p0_nodeVar326 );
		p0_nodeVar331 = ( p0_nodeVar324 * 2.1 );
		p0_nodeVar332 = floor( p0_nodeVar331 );
		p0_nodeVar333 = ( p0_nodeVar326 * 2.1 );
		p0_nodeVar334 = floor( p0_nodeVar333 );
		p0_nodeVar335 = fract( p0_nodeVar331 );
		p0_nodeVar336 = ( ( p0_nodeVar335 * p0_nodeVar335 ) * ( 3.0 - ( p0_nodeVar335 * 2.0 ) ) );
		p0_nodeVar337 = fract( p0_nodeVar333 );
		p0_nodeVar338 = ( p0_nodeVar324 * 4.3 );
		p0_nodeVar339 = floor( p0_nodeVar338 );
		p0_nodeVar340 = ( p0_nodeVar326 * 4.3 );
		p0_nodeVar341 = floor( p0_nodeVar340 );
		p0_nodeVar342 = fract( p0_nodeVar338 );
		p0_nodeVar343 = ( ( p0_nodeVar342 * p0_nodeVar342 ) * ( 3.0 - ( p0_nodeVar342 * 2.0 ) ) );
		p0_nodeVar344 = fract( p0_nodeVar340 );
		p0_nodeVar323 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar325 * 127.1 ) + ( p0_nodeVar327 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar325 + 1.0 ) * 127.1 ) + ( p0_nodeVar327 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar329 ), mix( fract( ( sin( ( ( p0_nodeVar325 * 127.1 ) + ( ( p0_nodeVar327 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar325 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar327 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar329 ), ( ( p0_nodeVar330 * p0_nodeVar330 ) * ( 3.0 - ( p0_nodeVar330 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar332 * 127.1 ) + ( p0_nodeVar334 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar332 + 1.0 ) * 127.1 ) + ( p0_nodeVar334 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar336 ), mix( fract( ( sin( ( ( p0_nodeVar332 * 127.1 ) + ( ( p0_nodeVar334 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar332 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar334 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar336 ), ( ( p0_nodeVar337 * p0_nodeVar337 ) * ( 3.0 - ( p0_nodeVar337 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar339 * 127.1 ) + ( p0_nodeVar341 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar339 + 1.0 ) * 127.1 ) + ( p0_nodeVar341 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar343 ), mix( fract( ( sin( ( ( p0_nodeVar339 * 127.1 ) + ( ( p0_nodeVar341 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar339 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar341 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar343 ), ( ( p0_nodeVar344 * p0_nodeVar344 ) * ( 3.0 - ( p0_nodeVar344 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar346 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar347 = floor( p0_nodeVar346 );
			p0_nodeVar348 = ( ( p0_nodeVar321 * 0.37 ) + 17.3 );
			p0_nodeVar349 = floor( p0_nodeVar348 );
			p0_nodeVar350 = fract( p0_nodeVar346 );
			p0_nodeVar351 = ( ( p0_nodeVar350 * p0_nodeVar350 ) * ( 3.0 - ( p0_nodeVar350 * 2.0 ) ) );
			p0_nodeVar352 = fract( p0_nodeVar348 );
			p0_nodeVar353 = ( p0_nodeVar346 * 2.1 );
			p0_nodeVar354 = floor( p0_nodeVar353 );
			p0_nodeVar355 = ( p0_nodeVar348 * 2.1 );
			p0_nodeVar356 = floor( p0_nodeVar355 );
			p0_nodeVar357 = fract( p0_nodeVar353 );
			p0_nodeVar358 = ( ( p0_nodeVar357 * p0_nodeVar357 ) * ( 3.0 - ( p0_nodeVar357 * 2.0 ) ) );
			p0_nodeVar359 = fract( p0_nodeVar355 );
			p0_nodeVar360 = ( p0_nodeVar346 * 4.3 );
			p0_nodeVar361 = floor( p0_nodeVar360 );
			p0_nodeVar362 = ( p0_nodeVar348 * 4.3 );
			p0_nodeVar363 = floor( p0_nodeVar362 );
			p0_nodeVar364 = fract( p0_nodeVar360 );
			p0_nodeVar365 = ( ( p0_nodeVar364 * p0_nodeVar364 ) * ( 3.0 - ( p0_nodeVar364 * 2.0 ) ) );
			p0_nodeVar366 = fract( p0_nodeVar362 );
			p0_nodeVar345 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar347 * 127.1 ) + ( p0_nodeVar349 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar347 + 1.0 ) * 127.1 ) + ( p0_nodeVar349 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar351 ), mix( fract( ( sin( ( ( p0_nodeVar347 * 127.1 ) + ( ( p0_nodeVar349 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar347 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar349 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar351 ), ( ( p0_nodeVar352 * p0_nodeVar352 ) * ( 3.0 - ( p0_nodeVar352 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar354 * 127.1 ) + ( p0_nodeVar356 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar354 + 1.0 ) * 127.1 ) + ( p0_nodeVar356 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar358 ), mix( fract( ( sin( ( ( p0_nodeVar354 * 127.1 ) + ( ( p0_nodeVar356 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar354 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar356 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar358 ), ( ( p0_nodeVar359 * p0_nodeVar359 ) * ( 3.0 - ( p0_nodeVar359 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar361 * 127.1 ) + ( p0_nodeVar363 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar361 + 1.0 ) * 127.1 ) + ( p0_nodeVar363 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar365 ), mix( fract( ( sin( ( ( p0_nodeVar361 * 127.1 ) + ( ( p0_nodeVar363 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar361 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar363 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar365 ), ( ( p0_nodeVar366 * p0_nodeVar366 ) * ( 3.0 - ( p0_nodeVar366 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar367 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar345 = ( ( ( sin( ( ( p0_nodeVar367 * 0.004 ) + ( p0_nodeVar321 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar367 * 0.011 ) + ( p0_nodeVar321 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar367 * 0.0023 ) + ( p0_nodeVar321 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar323 = p0_nodeVar345;

	}

	p0_nodeVar368 = abs( ( p0_nodeVar46 - ( p0_nodeVar322 + ( ( ( p0_nodeVar319 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar323 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar369 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar319 );
	p0_nodeVar370 = ( p0_nodeVar320 + ( ( p0_nodeVar319 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar371 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar320 - 1.0 ) ), ( p0_nodeVar320 + 1.0 ), p0_nodeVar368 ) ) * p0_nodeVar369 ) * p0_nodeVar319 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar370 - 2.0 ) ), ( p0_nodeVar370 + 2.0 ), p0_nodeVar368 ) ) * p0_nodeVar369 ) * ( p0_nodeVar319 * p0_nodeVar319 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar372 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar373 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar374 = dot( p0_nodeVar41, p0_nodeVar373 );
		p0_nodeVar375 = ( ( ( ( p0_nodeVar47 + 0.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar376 = picture_read( vec2<f32>( ( ( ( p0_nodeVar373.x * p0_nodeVar374 ) + ( p0_nodeVar43.x * p0_nodeVar375 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar373.y * p0_nodeVar374 ) + ( p0_nodeVar43.y * p0_nodeVar375 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar372 = vec3<f32>( p0_nodeVar376.x, p0_nodeVar376.y, p0_nodeVar376.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar378 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar379 = dot( p0_nodeVar41, p0_nodeVar378 );
		p0_nodeVar380 = ( ( ( ( p0_nodeVar47 + 0.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar381 = picture_read( vec2<f32>( ( ( ( p0_nodeVar378.x * p0_nodeVar379 ) + ( p0_nodeVar43.x * p0_nodeVar380 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar378.y * p0_nodeVar379 ) + ( p0_nodeVar43.y * p0_nodeVar380 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar377 = ( 1.0 - dot( vec3<f32>( p0_nodeVar381.x, p0_nodeVar381.y, p0_nodeVar381.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar382 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar383 = dot( p0_nodeVar41, p0_nodeVar382 );
		p0_nodeVar384 = ( ( ( ( p0_nodeVar47 + 0.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar385 = picture_read( vec2<f32>( ( ( ( p0_nodeVar382.x * p0_nodeVar383 ) + ( p0_nodeVar43.x * p0_nodeVar384 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar382.y * p0_nodeVar383 ) + ( p0_nodeVar43.y * p0_nodeVar384 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar377 = dot( vec3<f32>( p0_nodeVar385.x, p0_nodeVar385.y, p0_nodeVar385.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar386 = pow( clamp( ( ( p0_nodeVar377 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar387 = ( p0_nodeVar13 + ( p0_nodeVar386 * 0.5 ) );
	p0_nodeVar388 = ( p0_nodeVar47 + 0.0 );
	p0_nodeVar389 = ( ( p0_nodeVar388 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar391 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar392 = floor( p0_nodeVar391 );
		p0_nodeVar393 = ( ( p0_nodeVar388 * 0.37 ) + 17.3 );
		p0_nodeVar394 = floor( p0_nodeVar393 );
		p0_nodeVar395 = fract( p0_nodeVar391 );
		p0_nodeVar396 = ( ( p0_nodeVar395 * p0_nodeVar395 ) * ( 3.0 - ( p0_nodeVar395 * 2.0 ) ) );
		p0_nodeVar397 = fract( p0_nodeVar393 );
		p0_nodeVar398 = ( p0_nodeVar391 * 2.1 );
		p0_nodeVar399 = floor( p0_nodeVar398 );
		p0_nodeVar400 = ( p0_nodeVar393 * 2.1 );
		p0_nodeVar401 = floor( p0_nodeVar400 );
		p0_nodeVar402 = fract( p0_nodeVar398 );
		p0_nodeVar403 = ( ( p0_nodeVar402 * p0_nodeVar402 ) * ( 3.0 - ( p0_nodeVar402 * 2.0 ) ) );
		p0_nodeVar404 = fract( p0_nodeVar400 );
		p0_nodeVar405 = ( p0_nodeVar391 * 4.3 );
		p0_nodeVar406 = floor( p0_nodeVar405 );
		p0_nodeVar407 = ( p0_nodeVar393 * 4.3 );
		p0_nodeVar408 = floor( p0_nodeVar407 );
		p0_nodeVar409 = fract( p0_nodeVar405 );
		p0_nodeVar410 = ( ( p0_nodeVar409 * p0_nodeVar409 ) * ( 3.0 - ( p0_nodeVar409 * 2.0 ) ) );
		p0_nodeVar411 = fract( p0_nodeVar407 );
		p0_nodeVar390 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar392 * 127.1 ) + ( p0_nodeVar394 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar392 + 1.0 ) * 127.1 ) + ( p0_nodeVar394 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar396 ), mix( fract( ( sin( ( ( p0_nodeVar392 * 127.1 ) + ( ( p0_nodeVar394 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar392 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar394 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar396 ), ( ( p0_nodeVar397 * p0_nodeVar397 ) * ( 3.0 - ( p0_nodeVar397 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar399 * 127.1 ) + ( p0_nodeVar401 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar399 + 1.0 ) * 127.1 ) + ( p0_nodeVar401 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar403 ), mix( fract( ( sin( ( ( p0_nodeVar399 * 127.1 ) + ( ( p0_nodeVar401 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar399 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar401 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar403 ), ( ( p0_nodeVar404 * p0_nodeVar404 ) * ( 3.0 - ( p0_nodeVar404 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar406 * 127.1 ) + ( p0_nodeVar408 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar406 + 1.0 ) * 127.1 ) + ( p0_nodeVar408 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar410 ), mix( fract( ( sin( ( ( p0_nodeVar406 * 127.1 ) + ( ( p0_nodeVar408 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar406 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar408 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar410 ), ( ( p0_nodeVar411 * p0_nodeVar411 ) * ( 3.0 - ( p0_nodeVar411 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar413 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar414 = floor( p0_nodeVar413 );
			p0_nodeVar415 = ( ( p0_nodeVar388 * 0.37 ) + 17.3 );
			p0_nodeVar416 = floor( p0_nodeVar415 );
			p0_nodeVar417 = fract( p0_nodeVar413 );
			p0_nodeVar418 = ( ( p0_nodeVar417 * p0_nodeVar417 ) * ( 3.0 - ( p0_nodeVar417 * 2.0 ) ) );
			p0_nodeVar419 = fract( p0_nodeVar415 );
			p0_nodeVar420 = ( p0_nodeVar413 * 2.1 );
			p0_nodeVar421 = floor( p0_nodeVar420 );
			p0_nodeVar422 = ( p0_nodeVar415 * 2.1 );
			p0_nodeVar423 = floor( p0_nodeVar422 );
			p0_nodeVar424 = fract( p0_nodeVar420 );
			p0_nodeVar425 = ( ( p0_nodeVar424 * p0_nodeVar424 ) * ( 3.0 - ( p0_nodeVar424 * 2.0 ) ) );
			p0_nodeVar426 = fract( p0_nodeVar422 );
			p0_nodeVar427 = ( p0_nodeVar413 * 4.3 );
			p0_nodeVar428 = floor( p0_nodeVar427 );
			p0_nodeVar429 = ( p0_nodeVar415 * 4.3 );
			p0_nodeVar430 = floor( p0_nodeVar429 );
			p0_nodeVar431 = fract( p0_nodeVar427 );
			p0_nodeVar432 = ( ( p0_nodeVar431 * p0_nodeVar431 ) * ( 3.0 - ( p0_nodeVar431 * 2.0 ) ) );
			p0_nodeVar433 = fract( p0_nodeVar429 );
			p0_nodeVar412 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar414 * 127.1 ) + ( p0_nodeVar416 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar414 + 1.0 ) * 127.1 ) + ( p0_nodeVar416 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar418 ), mix( fract( ( sin( ( ( p0_nodeVar414 * 127.1 ) + ( ( p0_nodeVar416 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar414 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar416 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar418 ), ( ( p0_nodeVar419 * p0_nodeVar419 ) * ( 3.0 - ( p0_nodeVar419 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar421 * 127.1 ) + ( p0_nodeVar423 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar421 + 1.0 ) * 127.1 ) + ( p0_nodeVar423 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar425 ), mix( fract( ( sin( ( ( p0_nodeVar421 * 127.1 ) + ( ( p0_nodeVar423 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar421 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar423 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar425 ), ( ( p0_nodeVar426 * p0_nodeVar426 ) * ( 3.0 - ( p0_nodeVar426 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar428 * 127.1 ) + ( p0_nodeVar430 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar428 + 1.0 ) * 127.1 ) + ( p0_nodeVar430 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar432 ), mix( fract( ( sin( ( ( p0_nodeVar428 * 127.1 ) + ( ( p0_nodeVar430 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar428 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar430 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar432 ), ( ( p0_nodeVar433 * p0_nodeVar433 ) * ( 3.0 - ( p0_nodeVar433 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar434 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar412 = ( ( ( sin( ( ( p0_nodeVar434 * 0.004 ) + ( p0_nodeVar388 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar434 * 0.011 ) + ( p0_nodeVar388 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar434 * 0.0023 ) + ( p0_nodeVar388 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar390 = p0_nodeVar412;

	}

	p0_nodeVar435 = abs( ( p0_nodeVar46 - ( p0_nodeVar389 + ( ( ( p0_nodeVar386 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar390 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar436 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar386 );
	p0_nodeVar437 = ( p0_nodeVar387 + ( ( p0_nodeVar386 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar438 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar387 - 1.0 ) ), ( p0_nodeVar387 + 1.0 ), p0_nodeVar435 ) ) * p0_nodeVar436 ) * p0_nodeVar386 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar437 - 2.0 ) ), ( p0_nodeVar437 + 2.0 ), p0_nodeVar435 ) ) * p0_nodeVar436 ) * ( p0_nodeVar386 * p0_nodeVar386 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar439 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar440 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar441 = dot( p0_nodeVar41, p0_nodeVar440 );
		p0_nodeVar442 = ( ( ( ( p0_nodeVar47 + 1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar443 = picture_read( vec2<f32>( ( ( ( p0_nodeVar440.x * p0_nodeVar441 ) + ( p0_nodeVar43.x * p0_nodeVar442 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar440.y * p0_nodeVar441 ) + ( p0_nodeVar43.y * p0_nodeVar442 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar439 = vec3<f32>( p0_nodeVar443.x, p0_nodeVar443.y, p0_nodeVar443.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar445 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar446 = dot( p0_nodeVar41, p0_nodeVar445 );
		p0_nodeVar447 = ( ( ( ( p0_nodeVar47 + 1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar448 = picture_read( vec2<f32>( ( ( ( p0_nodeVar445.x * p0_nodeVar446 ) + ( p0_nodeVar43.x * p0_nodeVar447 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar445.y * p0_nodeVar446 ) + ( p0_nodeVar43.y * p0_nodeVar447 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar444 = ( 1.0 - dot( vec3<f32>( p0_nodeVar448.x, p0_nodeVar448.y, p0_nodeVar448.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar449 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar450 = dot( p0_nodeVar41, p0_nodeVar449 );
		p0_nodeVar451 = ( ( ( ( p0_nodeVar47 + 1.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar452 = picture_read( vec2<f32>( ( ( ( p0_nodeVar449.x * p0_nodeVar450 ) + ( p0_nodeVar43.x * p0_nodeVar451 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar449.y * p0_nodeVar450 ) + ( p0_nodeVar43.y * p0_nodeVar451 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar444 = dot( vec3<f32>( p0_nodeVar452.x, p0_nodeVar452.y, p0_nodeVar452.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar453 = pow( clamp( ( ( p0_nodeVar444 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar454 = ( p0_nodeVar13 + ( p0_nodeVar453 * 0.5 ) );
	p0_nodeVar455 = ( p0_nodeVar47 + 1.0 );
	p0_nodeVar456 = ( ( p0_nodeVar455 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar458 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar459 = floor( p0_nodeVar458 );
		p0_nodeVar460 = ( ( p0_nodeVar455 * 0.37 ) + 17.3 );
		p0_nodeVar461 = floor( p0_nodeVar460 );
		p0_nodeVar462 = fract( p0_nodeVar458 );
		p0_nodeVar463 = ( ( p0_nodeVar462 * p0_nodeVar462 ) * ( 3.0 - ( p0_nodeVar462 * 2.0 ) ) );
		p0_nodeVar464 = fract( p0_nodeVar460 );
		p0_nodeVar465 = ( p0_nodeVar458 * 2.1 );
		p0_nodeVar466 = floor( p0_nodeVar465 );
		p0_nodeVar467 = ( p0_nodeVar460 * 2.1 );
		p0_nodeVar468 = floor( p0_nodeVar467 );
		p0_nodeVar469 = fract( p0_nodeVar465 );
		p0_nodeVar470 = ( ( p0_nodeVar469 * p0_nodeVar469 ) * ( 3.0 - ( p0_nodeVar469 * 2.0 ) ) );
		p0_nodeVar471 = fract( p0_nodeVar467 );
		p0_nodeVar472 = ( p0_nodeVar458 * 4.3 );
		p0_nodeVar473 = floor( p0_nodeVar472 );
		p0_nodeVar474 = ( p0_nodeVar460 * 4.3 );
		p0_nodeVar475 = floor( p0_nodeVar474 );
		p0_nodeVar476 = fract( p0_nodeVar472 );
		p0_nodeVar477 = ( ( p0_nodeVar476 * p0_nodeVar476 ) * ( 3.0 - ( p0_nodeVar476 * 2.0 ) ) );
		p0_nodeVar478 = fract( p0_nodeVar474 );
		p0_nodeVar457 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar459 * 127.1 ) + ( p0_nodeVar461 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar459 + 1.0 ) * 127.1 ) + ( p0_nodeVar461 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar463 ), mix( fract( ( sin( ( ( p0_nodeVar459 * 127.1 ) + ( ( p0_nodeVar461 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar459 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar461 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar463 ), ( ( p0_nodeVar464 * p0_nodeVar464 ) * ( 3.0 - ( p0_nodeVar464 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar466 * 127.1 ) + ( p0_nodeVar468 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar466 + 1.0 ) * 127.1 ) + ( p0_nodeVar468 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar470 ), mix( fract( ( sin( ( ( p0_nodeVar466 * 127.1 ) + ( ( p0_nodeVar468 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar466 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar468 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar470 ), ( ( p0_nodeVar471 * p0_nodeVar471 ) * ( 3.0 - ( p0_nodeVar471 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar473 * 127.1 ) + ( p0_nodeVar475 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar473 + 1.0 ) * 127.1 ) + ( p0_nodeVar475 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar477 ), mix( fract( ( sin( ( ( p0_nodeVar473 * 127.1 ) + ( ( p0_nodeVar475 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar473 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar475 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar477 ), ( ( p0_nodeVar478 * p0_nodeVar478 ) * ( 3.0 - ( p0_nodeVar478 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar480 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar481 = floor( p0_nodeVar480 );
			p0_nodeVar482 = ( ( p0_nodeVar455 * 0.37 ) + 17.3 );
			p0_nodeVar483 = floor( p0_nodeVar482 );
			p0_nodeVar484 = fract( p0_nodeVar480 );
			p0_nodeVar485 = ( ( p0_nodeVar484 * p0_nodeVar484 ) * ( 3.0 - ( p0_nodeVar484 * 2.0 ) ) );
			p0_nodeVar486 = fract( p0_nodeVar482 );
			p0_nodeVar487 = ( p0_nodeVar480 * 2.1 );
			p0_nodeVar488 = floor( p0_nodeVar487 );
			p0_nodeVar489 = ( p0_nodeVar482 * 2.1 );
			p0_nodeVar490 = floor( p0_nodeVar489 );
			p0_nodeVar491 = fract( p0_nodeVar487 );
			p0_nodeVar492 = ( ( p0_nodeVar491 * p0_nodeVar491 ) * ( 3.0 - ( p0_nodeVar491 * 2.0 ) ) );
			p0_nodeVar493 = fract( p0_nodeVar489 );
			p0_nodeVar494 = ( p0_nodeVar480 * 4.3 );
			p0_nodeVar495 = floor( p0_nodeVar494 );
			p0_nodeVar496 = ( p0_nodeVar482 * 4.3 );
			p0_nodeVar497 = floor( p0_nodeVar496 );
			p0_nodeVar498 = fract( p0_nodeVar494 );
			p0_nodeVar499 = ( ( p0_nodeVar498 * p0_nodeVar498 ) * ( 3.0 - ( p0_nodeVar498 * 2.0 ) ) );
			p0_nodeVar500 = fract( p0_nodeVar496 );
			p0_nodeVar479 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar481 * 127.1 ) + ( p0_nodeVar483 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar481 + 1.0 ) * 127.1 ) + ( p0_nodeVar483 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar485 ), mix( fract( ( sin( ( ( p0_nodeVar481 * 127.1 ) + ( ( p0_nodeVar483 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar481 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar483 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar485 ), ( ( p0_nodeVar486 * p0_nodeVar486 ) * ( 3.0 - ( p0_nodeVar486 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar488 * 127.1 ) + ( p0_nodeVar490 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar488 + 1.0 ) * 127.1 ) + ( p0_nodeVar490 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar492 ), mix( fract( ( sin( ( ( p0_nodeVar488 * 127.1 ) + ( ( p0_nodeVar490 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar488 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar490 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar492 ), ( ( p0_nodeVar493 * p0_nodeVar493 ) * ( 3.0 - ( p0_nodeVar493 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar495 * 127.1 ) + ( p0_nodeVar497 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar495 + 1.0 ) * 127.1 ) + ( p0_nodeVar497 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar499 ), mix( fract( ( sin( ( ( p0_nodeVar495 * 127.1 ) + ( ( p0_nodeVar497 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar495 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar497 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar499 ), ( ( p0_nodeVar500 * p0_nodeVar500 ) * ( 3.0 - ( p0_nodeVar500 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar501 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar479 = ( ( ( sin( ( ( p0_nodeVar501 * 0.004 ) + ( p0_nodeVar455 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar501 * 0.011 ) + ( p0_nodeVar455 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar501 * 0.0023 ) + ( p0_nodeVar455 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar457 = p0_nodeVar479;

	}

	p0_nodeVar502 = abs( ( p0_nodeVar46 - ( p0_nodeVar456 + ( ( ( p0_nodeVar453 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar457 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar503 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar453 );
	p0_nodeVar504 = ( p0_nodeVar454 + ( ( p0_nodeVar453 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar505 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar454 - 1.0 ) ), ( p0_nodeVar454 + 1.0 ), p0_nodeVar502 ) ) * p0_nodeVar503 ) * p0_nodeVar453 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar504 - 2.0 ) ), ( p0_nodeVar504 + 2.0 ), p0_nodeVar502 ) ) * p0_nodeVar503 ) * ( p0_nodeVar453 * p0_nodeVar453 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar506 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar507 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar508 = dot( p0_nodeVar41, p0_nodeVar507 );
		p0_nodeVar509 = ( ( ( ( p0_nodeVar47 + 2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar510 = picture_read( vec2<f32>( ( ( ( p0_nodeVar507.x * p0_nodeVar508 ) + ( p0_nodeVar43.x * p0_nodeVar509 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar507.y * p0_nodeVar508 ) + ( p0_nodeVar43.y * p0_nodeVar509 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar506 = vec3<f32>( p0_nodeVar510.x, p0_nodeVar510.y, p0_nodeVar510.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar512 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar513 = dot( p0_nodeVar41, p0_nodeVar512 );
		p0_nodeVar514 = ( ( ( ( p0_nodeVar47 + 2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar515 = picture_read( vec2<f32>( ( ( ( p0_nodeVar512.x * p0_nodeVar513 ) + ( p0_nodeVar43.x * p0_nodeVar514 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar512.y * p0_nodeVar513 ) + ( p0_nodeVar43.y * p0_nodeVar514 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar511 = ( 1.0 - dot( vec3<f32>( p0_nodeVar515.x, p0_nodeVar515.y, p0_nodeVar515.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar516 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar517 = dot( p0_nodeVar41, p0_nodeVar516 );
		p0_nodeVar518 = ( ( ( ( p0_nodeVar47 + 2.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar519 = picture_read( vec2<f32>( ( ( ( p0_nodeVar516.x * p0_nodeVar517 ) + ( p0_nodeVar43.x * p0_nodeVar518 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar516.y * p0_nodeVar517 ) + ( p0_nodeVar43.y * p0_nodeVar518 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar511 = dot( vec3<f32>( p0_nodeVar519.x, p0_nodeVar519.y, p0_nodeVar519.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar520 = pow( clamp( ( ( p0_nodeVar511 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar521 = ( p0_nodeVar13 + ( p0_nodeVar520 * 0.5 ) );
	p0_nodeVar522 = ( p0_nodeVar47 + 2.0 );
	p0_nodeVar523 = ( ( p0_nodeVar522 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar525 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar526 = floor( p0_nodeVar525 );
		p0_nodeVar527 = ( ( p0_nodeVar522 * 0.37 ) + 17.3 );
		p0_nodeVar528 = floor( p0_nodeVar527 );
		p0_nodeVar529 = fract( p0_nodeVar525 );
		p0_nodeVar530 = ( ( p0_nodeVar529 * p0_nodeVar529 ) * ( 3.0 - ( p0_nodeVar529 * 2.0 ) ) );
		p0_nodeVar531 = fract( p0_nodeVar527 );
		p0_nodeVar532 = ( p0_nodeVar525 * 2.1 );
		p0_nodeVar533 = floor( p0_nodeVar532 );
		p0_nodeVar534 = ( p0_nodeVar527 * 2.1 );
		p0_nodeVar535 = floor( p0_nodeVar534 );
		p0_nodeVar536 = fract( p0_nodeVar532 );
		p0_nodeVar537 = ( ( p0_nodeVar536 * p0_nodeVar536 ) * ( 3.0 - ( p0_nodeVar536 * 2.0 ) ) );
		p0_nodeVar538 = fract( p0_nodeVar534 );
		p0_nodeVar539 = ( p0_nodeVar525 * 4.3 );
		p0_nodeVar540 = floor( p0_nodeVar539 );
		p0_nodeVar541 = ( p0_nodeVar527 * 4.3 );
		p0_nodeVar542 = floor( p0_nodeVar541 );
		p0_nodeVar543 = fract( p0_nodeVar539 );
		p0_nodeVar544 = ( ( p0_nodeVar543 * p0_nodeVar543 ) * ( 3.0 - ( p0_nodeVar543 * 2.0 ) ) );
		p0_nodeVar545 = fract( p0_nodeVar541 );
		p0_nodeVar524 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar526 * 127.1 ) + ( p0_nodeVar528 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar526 + 1.0 ) * 127.1 ) + ( p0_nodeVar528 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar530 ), mix( fract( ( sin( ( ( p0_nodeVar526 * 127.1 ) + ( ( p0_nodeVar528 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar526 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar528 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar530 ), ( ( p0_nodeVar531 * p0_nodeVar531 ) * ( 3.0 - ( p0_nodeVar531 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar533 * 127.1 ) + ( p0_nodeVar535 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar533 + 1.0 ) * 127.1 ) + ( p0_nodeVar535 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar537 ), mix( fract( ( sin( ( ( p0_nodeVar533 * 127.1 ) + ( ( p0_nodeVar535 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar533 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar535 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar537 ), ( ( p0_nodeVar538 * p0_nodeVar538 ) * ( 3.0 - ( p0_nodeVar538 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar540 * 127.1 ) + ( p0_nodeVar542 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar540 + 1.0 ) * 127.1 ) + ( p0_nodeVar542 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar544 ), mix( fract( ( sin( ( ( p0_nodeVar540 * 127.1 ) + ( ( p0_nodeVar542 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar540 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar542 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar544 ), ( ( p0_nodeVar545 * p0_nodeVar545 ) * ( 3.0 - ( p0_nodeVar545 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar547 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar548 = floor( p0_nodeVar547 );
			p0_nodeVar549 = ( ( p0_nodeVar522 * 0.37 ) + 17.3 );
			p0_nodeVar550 = floor( p0_nodeVar549 );
			p0_nodeVar551 = fract( p0_nodeVar547 );
			p0_nodeVar552 = ( ( p0_nodeVar551 * p0_nodeVar551 ) * ( 3.0 - ( p0_nodeVar551 * 2.0 ) ) );
			p0_nodeVar553 = fract( p0_nodeVar549 );
			p0_nodeVar554 = ( p0_nodeVar547 * 2.1 );
			p0_nodeVar555 = floor( p0_nodeVar554 );
			p0_nodeVar556 = ( p0_nodeVar549 * 2.1 );
			p0_nodeVar557 = floor( p0_nodeVar556 );
			p0_nodeVar558 = fract( p0_nodeVar554 );
			p0_nodeVar559 = ( ( p0_nodeVar558 * p0_nodeVar558 ) * ( 3.0 - ( p0_nodeVar558 * 2.0 ) ) );
			p0_nodeVar560 = fract( p0_nodeVar556 );
			p0_nodeVar561 = ( p0_nodeVar547 * 4.3 );
			p0_nodeVar562 = floor( p0_nodeVar561 );
			p0_nodeVar563 = ( p0_nodeVar549 * 4.3 );
			p0_nodeVar564 = floor( p0_nodeVar563 );
			p0_nodeVar565 = fract( p0_nodeVar561 );
			p0_nodeVar566 = ( ( p0_nodeVar565 * p0_nodeVar565 ) * ( 3.0 - ( p0_nodeVar565 * 2.0 ) ) );
			p0_nodeVar567 = fract( p0_nodeVar563 );
			p0_nodeVar546 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar548 * 127.1 ) + ( p0_nodeVar550 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar548 + 1.0 ) * 127.1 ) + ( p0_nodeVar550 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar552 ), mix( fract( ( sin( ( ( p0_nodeVar548 * 127.1 ) + ( ( p0_nodeVar550 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar548 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar550 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar552 ), ( ( p0_nodeVar553 * p0_nodeVar553 ) * ( 3.0 - ( p0_nodeVar553 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar555 * 127.1 ) + ( p0_nodeVar557 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar555 + 1.0 ) * 127.1 ) + ( p0_nodeVar557 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar559 ), mix( fract( ( sin( ( ( p0_nodeVar555 * 127.1 ) + ( ( p0_nodeVar557 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar555 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar557 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar559 ), ( ( p0_nodeVar560 * p0_nodeVar560 ) * ( 3.0 - ( p0_nodeVar560 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar562 * 127.1 ) + ( p0_nodeVar564 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar562 + 1.0 ) * 127.1 ) + ( p0_nodeVar564 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar566 ), mix( fract( ( sin( ( ( p0_nodeVar562 * 127.1 ) + ( ( p0_nodeVar564 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar562 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar564 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar566 ), ( ( p0_nodeVar567 * p0_nodeVar567 ) * ( 3.0 - ( p0_nodeVar567 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar568 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar546 = ( ( ( sin( ( ( p0_nodeVar568 * 0.004 ) + ( p0_nodeVar522 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar568 * 0.011 ) + ( p0_nodeVar522 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar568 * 0.0023 ) + ( p0_nodeVar522 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar524 = p0_nodeVar546;

	}

	p0_nodeVar569 = abs( ( p0_nodeVar46 - ( p0_nodeVar523 + ( ( ( p0_nodeVar520 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar524 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar570 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar520 );
	p0_nodeVar571 = ( p0_nodeVar521 + ( ( p0_nodeVar520 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar572 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar521 - 1.0 ) ), ( p0_nodeVar521 + 1.0 ), p0_nodeVar569 ) ) * p0_nodeVar570 ) * p0_nodeVar520 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar571 - 2.0 ) ), ( p0_nodeVar571 + 2.0 ), p0_nodeVar569 ) ) * p0_nodeVar570 ) * ( p0_nodeVar520 * p0_nodeVar520 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar573 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar574 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar575 = dot( p0_nodeVar41, p0_nodeVar574 );
		p0_nodeVar576 = ( ( ( ( p0_nodeVar47 + 3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar577 = picture_read( vec2<f32>( ( ( ( p0_nodeVar574.x * p0_nodeVar575 ) + ( p0_nodeVar43.x * p0_nodeVar576 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar574.y * p0_nodeVar575 ) + ( p0_nodeVar43.y * p0_nodeVar576 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar573 = vec3<f32>( p0_nodeVar577.x, p0_nodeVar577.y, p0_nodeVar577.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar579 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar580 = dot( p0_nodeVar41, p0_nodeVar579 );
		p0_nodeVar581 = ( ( ( ( p0_nodeVar47 + 3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar582 = picture_read( vec2<f32>( ( ( ( p0_nodeVar579.x * p0_nodeVar580 ) + ( p0_nodeVar43.x * p0_nodeVar581 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar579.y * p0_nodeVar580 ) + ( p0_nodeVar43.y * p0_nodeVar581 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar578 = ( 1.0 - dot( vec3<f32>( p0_nodeVar582.x, p0_nodeVar582.y, p0_nodeVar582.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar583 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar584 = dot( p0_nodeVar41, p0_nodeVar583 );
		p0_nodeVar585 = ( ( ( ( p0_nodeVar47 + 3.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar586 = picture_read( vec2<f32>( ( ( ( p0_nodeVar583.x * p0_nodeVar584 ) + ( p0_nodeVar43.x * p0_nodeVar585 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar583.y * p0_nodeVar584 ) + ( p0_nodeVar43.y * p0_nodeVar585 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar578 = dot( vec3<f32>( p0_nodeVar586.x, p0_nodeVar586.y, p0_nodeVar586.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar587 = pow( clamp( ( ( p0_nodeVar578 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar588 = ( p0_nodeVar13 + ( p0_nodeVar587 * 0.5 ) );
	p0_nodeVar589 = ( p0_nodeVar47 + 3.0 );
	p0_nodeVar590 = ( ( p0_nodeVar589 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar592 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar593 = floor( p0_nodeVar592 );
		p0_nodeVar594 = ( ( p0_nodeVar589 * 0.37 ) + 17.3 );
		p0_nodeVar595 = floor( p0_nodeVar594 );
		p0_nodeVar596 = fract( p0_nodeVar592 );
		p0_nodeVar597 = ( ( p0_nodeVar596 * p0_nodeVar596 ) * ( 3.0 - ( p0_nodeVar596 * 2.0 ) ) );
		p0_nodeVar598 = fract( p0_nodeVar594 );
		p0_nodeVar599 = ( p0_nodeVar592 * 2.1 );
		p0_nodeVar600 = floor( p0_nodeVar599 );
		p0_nodeVar601 = ( p0_nodeVar594 * 2.1 );
		p0_nodeVar602 = floor( p0_nodeVar601 );
		p0_nodeVar603 = fract( p0_nodeVar599 );
		p0_nodeVar604 = ( ( p0_nodeVar603 * p0_nodeVar603 ) * ( 3.0 - ( p0_nodeVar603 * 2.0 ) ) );
		p0_nodeVar605 = fract( p0_nodeVar601 );
		p0_nodeVar606 = ( p0_nodeVar592 * 4.3 );
		p0_nodeVar607 = floor( p0_nodeVar606 );
		p0_nodeVar608 = ( p0_nodeVar594 * 4.3 );
		p0_nodeVar609 = floor( p0_nodeVar608 );
		p0_nodeVar610 = fract( p0_nodeVar606 );
		p0_nodeVar611 = ( ( p0_nodeVar610 * p0_nodeVar610 ) * ( 3.0 - ( p0_nodeVar610 * 2.0 ) ) );
		p0_nodeVar612 = fract( p0_nodeVar608 );
		p0_nodeVar591 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar593 * 127.1 ) + ( p0_nodeVar595 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar593 + 1.0 ) * 127.1 ) + ( p0_nodeVar595 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar597 ), mix( fract( ( sin( ( ( p0_nodeVar593 * 127.1 ) + ( ( p0_nodeVar595 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar593 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar595 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar597 ), ( ( p0_nodeVar598 * p0_nodeVar598 ) * ( 3.0 - ( p0_nodeVar598 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar600 * 127.1 ) + ( p0_nodeVar602 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar600 + 1.0 ) * 127.1 ) + ( p0_nodeVar602 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar604 ), mix( fract( ( sin( ( ( p0_nodeVar600 * 127.1 ) + ( ( p0_nodeVar602 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar600 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar602 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar604 ), ( ( p0_nodeVar605 * p0_nodeVar605 ) * ( 3.0 - ( p0_nodeVar605 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar607 * 127.1 ) + ( p0_nodeVar609 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar607 + 1.0 ) * 127.1 ) + ( p0_nodeVar609 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar611 ), mix( fract( ( sin( ( ( p0_nodeVar607 * 127.1 ) + ( ( p0_nodeVar609 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar607 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar609 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar611 ), ( ( p0_nodeVar612 * p0_nodeVar612 ) * ( 3.0 - ( p0_nodeVar612 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar614 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar615 = floor( p0_nodeVar614 );
			p0_nodeVar616 = ( ( p0_nodeVar589 * 0.37 ) + 17.3 );
			p0_nodeVar617 = floor( p0_nodeVar616 );
			p0_nodeVar618 = fract( p0_nodeVar614 );
			p0_nodeVar619 = ( ( p0_nodeVar618 * p0_nodeVar618 ) * ( 3.0 - ( p0_nodeVar618 * 2.0 ) ) );
			p0_nodeVar620 = fract( p0_nodeVar616 );
			p0_nodeVar621 = ( p0_nodeVar614 * 2.1 );
			p0_nodeVar622 = floor( p0_nodeVar621 );
			p0_nodeVar623 = ( p0_nodeVar616 * 2.1 );
			p0_nodeVar624 = floor( p0_nodeVar623 );
			p0_nodeVar625 = fract( p0_nodeVar621 );
			p0_nodeVar626 = ( ( p0_nodeVar625 * p0_nodeVar625 ) * ( 3.0 - ( p0_nodeVar625 * 2.0 ) ) );
			p0_nodeVar627 = fract( p0_nodeVar623 );
			p0_nodeVar628 = ( p0_nodeVar614 * 4.3 );
			p0_nodeVar629 = floor( p0_nodeVar628 );
			p0_nodeVar630 = ( p0_nodeVar616 * 4.3 );
			p0_nodeVar631 = floor( p0_nodeVar630 );
			p0_nodeVar632 = fract( p0_nodeVar628 );
			p0_nodeVar633 = ( ( p0_nodeVar632 * p0_nodeVar632 ) * ( 3.0 - ( p0_nodeVar632 * 2.0 ) ) );
			p0_nodeVar634 = fract( p0_nodeVar630 );
			p0_nodeVar613 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar615 * 127.1 ) + ( p0_nodeVar617 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar615 + 1.0 ) * 127.1 ) + ( p0_nodeVar617 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar619 ), mix( fract( ( sin( ( ( p0_nodeVar615 * 127.1 ) + ( ( p0_nodeVar617 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar615 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar617 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar619 ), ( ( p0_nodeVar620 * p0_nodeVar620 ) * ( 3.0 - ( p0_nodeVar620 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar622 * 127.1 ) + ( p0_nodeVar624 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar622 + 1.0 ) * 127.1 ) + ( p0_nodeVar624 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar626 ), mix( fract( ( sin( ( ( p0_nodeVar622 * 127.1 ) + ( ( p0_nodeVar624 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar622 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar624 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar626 ), ( ( p0_nodeVar627 * p0_nodeVar627 ) * ( 3.0 - ( p0_nodeVar627 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar629 * 127.1 ) + ( p0_nodeVar631 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar629 + 1.0 ) * 127.1 ) + ( p0_nodeVar631 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar633 ), mix( fract( ( sin( ( ( p0_nodeVar629 * 127.1 ) + ( ( p0_nodeVar631 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar629 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar631 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar633 ), ( ( p0_nodeVar634 * p0_nodeVar634 ) * ( 3.0 - ( p0_nodeVar634 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar635 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar613 = ( ( ( sin( ( ( p0_nodeVar635 * 0.004 ) + ( p0_nodeVar589 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar635 * 0.011 ) + ( p0_nodeVar589 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar635 * 0.0023 ) + ( p0_nodeVar589 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar591 = p0_nodeVar613;

	}

	p0_nodeVar636 = abs( ( p0_nodeVar46 - ( p0_nodeVar590 + ( ( ( p0_nodeVar587 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar591 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar637 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar587 );
	p0_nodeVar638 = ( p0_nodeVar588 + ( ( p0_nodeVar587 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar639 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar588 - 1.0 ) ), ( p0_nodeVar588 + 1.0 ), p0_nodeVar636 ) ) * p0_nodeVar637 ) * p0_nodeVar587 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar638 - 2.0 ) ), ( p0_nodeVar638 + 2.0 ), p0_nodeVar636 ) ) * p0_nodeVar637 ) * ( p0_nodeVar587 * p0_nodeVar587 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar640 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar641 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar642 = dot( p0_nodeVar41, p0_nodeVar641 );
		p0_nodeVar643 = ( ( ( ( p0_nodeVar47 + 4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar644 = picture_read( vec2<f32>( ( ( ( p0_nodeVar641.x * p0_nodeVar642 ) + ( p0_nodeVar43.x * p0_nodeVar643 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar641.y * p0_nodeVar642 ) + ( p0_nodeVar43.y * p0_nodeVar643 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar640 = vec3<f32>( p0_nodeVar644.x, p0_nodeVar644.y, p0_nodeVar644.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar646 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar647 = dot( p0_nodeVar41, p0_nodeVar646 );
		p0_nodeVar648 = ( ( ( ( p0_nodeVar47 + 4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar649 = picture_read( vec2<f32>( ( ( ( p0_nodeVar646.x * p0_nodeVar647 ) + ( p0_nodeVar43.x * p0_nodeVar648 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar646.y * p0_nodeVar647 ) + ( p0_nodeVar43.y * p0_nodeVar648 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar645 = ( 1.0 - dot( vec3<f32>( p0_nodeVar649.x, p0_nodeVar649.y, p0_nodeVar649.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar650 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar651 = dot( p0_nodeVar41, p0_nodeVar650 );
		p0_nodeVar652 = ( ( ( ( p0_nodeVar47 + 4.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar653 = picture_read( vec2<f32>( ( ( ( p0_nodeVar650.x * p0_nodeVar651 ) + ( p0_nodeVar43.x * p0_nodeVar652 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar650.y * p0_nodeVar651 ) + ( p0_nodeVar43.y * p0_nodeVar652 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar645 = dot( vec3<f32>( p0_nodeVar653.x, p0_nodeVar653.y, p0_nodeVar653.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar654 = pow( clamp( ( ( p0_nodeVar645 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar655 = ( p0_nodeVar13 + ( p0_nodeVar654 * 0.5 ) );
	p0_nodeVar656 = ( p0_nodeVar47 + 4.0 );
	p0_nodeVar657 = ( ( p0_nodeVar656 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar659 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar660 = floor( p0_nodeVar659 );
		p0_nodeVar661 = ( ( p0_nodeVar656 * 0.37 ) + 17.3 );
		p0_nodeVar662 = floor( p0_nodeVar661 );
		p0_nodeVar663 = fract( p0_nodeVar659 );
		p0_nodeVar664 = ( ( p0_nodeVar663 * p0_nodeVar663 ) * ( 3.0 - ( p0_nodeVar663 * 2.0 ) ) );
		p0_nodeVar665 = fract( p0_nodeVar661 );
		p0_nodeVar666 = ( p0_nodeVar659 * 2.1 );
		p0_nodeVar667 = floor( p0_nodeVar666 );
		p0_nodeVar668 = ( p0_nodeVar661 * 2.1 );
		p0_nodeVar669 = floor( p0_nodeVar668 );
		p0_nodeVar670 = fract( p0_nodeVar666 );
		p0_nodeVar671 = ( ( p0_nodeVar670 * p0_nodeVar670 ) * ( 3.0 - ( p0_nodeVar670 * 2.0 ) ) );
		p0_nodeVar672 = fract( p0_nodeVar668 );
		p0_nodeVar673 = ( p0_nodeVar659 * 4.3 );
		p0_nodeVar674 = floor( p0_nodeVar673 );
		p0_nodeVar675 = ( p0_nodeVar661 * 4.3 );
		p0_nodeVar676 = floor( p0_nodeVar675 );
		p0_nodeVar677 = fract( p0_nodeVar673 );
		p0_nodeVar678 = ( ( p0_nodeVar677 * p0_nodeVar677 ) * ( 3.0 - ( p0_nodeVar677 * 2.0 ) ) );
		p0_nodeVar679 = fract( p0_nodeVar675 );
		p0_nodeVar658 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar660 * 127.1 ) + ( p0_nodeVar662 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar660 + 1.0 ) * 127.1 ) + ( p0_nodeVar662 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar664 ), mix( fract( ( sin( ( ( p0_nodeVar660 * 127.1 ) + ( ( p0_nodeVar662 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar660 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar662 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar664 ), ( ( p0_nodeVar665 * p0_nodeVar665 ) * ( 3.0 - ( p0_nodeVar665 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar667 * 127.1 ) + ( p0_nodeVar669 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar667 + 1.0 ) * 127.1 ) + ( p0_nodeVar669 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar671 ), mix( fract( ( sin( ( ( p0_nodeVar667 * 127.1 ) + ( ( p0_nodeVar669 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar667 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar669 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar671 ), ( ( p0_nodeVar672 * p0_nodeVar672 ) * ( 3.0 - ( p0_nodeVar672 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar674 * 127.1 ) + ( p0_nodeVar676 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar674 + 1.0 ) * 127.1 ) + ( p0_nodeVar676 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar678 ), mix( fract( ( sin( ( ( p0_nodeVar674 * 127.1 ) + ( ( p0_nodeVar676 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar674 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar676 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar678 ), ( ( p0_nodeVar679 * p0_nodeVar679 ) * ( 3.0 - ( p0_nodeVar679 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar681 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar682 = floor( p0_nodeVar681 );
			p0_nodeVar683 = ( ( p0_nodeVar656 * 0.37 ) + 17.3 );
			p0_nodeVar684 = floor( p0_nodeVar683 );
			p0_nodeVar685 = fract( p0_nodeVar681 );
			p0_nodeVar686 = ( ( p0_nodeVar685 * p0_nodeVar685 ) * ( 3.0 - ( p0_nodeVar685 * 2.0 ) ) );
			p0_nodeVar687 = fract( p0_nodeVar683 );
			p0_nodeVar688 = ( p0_nodeVar681 * 2.1 );
			p0_nodeVar689 = floor( p0_nodeVar688 );
			p0_nodeVar690 = ( p0_nodeVar683 * 2.1 );
			p0_nodeVar691 = floor( p0_nodeVar690 );
			p0_nodeVar692 = fract( p0_nodeVar688 );
			p0_nodeVar693 = ( ( p0_nodeVar692 * p0_nodeVar692 ) * ( 3.0 - ( p0_nodeVar692 * 2.0 ) ) );
			p0_nodeVar694 = fract( p0_nodeVar690 );
			p0_nodeVar695 = ( p0_nodeVar681 * 4.3 );
			p0_nodeVar696 = floor( p0_nodeVar695 );
			p0_nodeVar697 = ( p0_nodeVar683 * 4.3 );
			p0_nodeVar698 = floor( p0_nodeVar697 );
			p0_nodeVar699 = fract( p0_nodeVar695 );
			p0_nodeVar700 = ( ( p0_nodeVar699 * p0_nodeVar699 ) * ( 3.0 - ( p0_nodeVar699 * 2.0 ) ) );
			p0_nodeVar701 = fract( p0_nodeVar697 );
			p0_nodeVar680 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar682 * 127.1 ) + ( p0_nodeVar684 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar682 + 1.0 ) * 127.1 ) + ( p0_nodeVar684 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar686 ), mix( fract( ( sin( ( ( p0_nodeVar682 * 127.1 ) + ( ( p0_nodeVar684 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar682 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar684 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar686 ), ( ( p0_nodeVar687 * p0_nodeVar687 ) * ( 3.0 - ( p0_nodeVar687 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar689 * 127.1 ) + ( p0_nodeVar691 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar689 + 1.0 ) * 127.1 ) + ( p0_nodeVar691 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar693 ), mix( fract( ( sin( ( ( p0_nodeVar689 * 127.1 ) + ( ( p0_nodeVar691 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar689 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar691 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar693 ), ( ( p0_nodeVar694 * p0_nodeVar694 ) * ( 3.0 - ( p0_nodeVar694 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar696 * 127.1 ) + ( p0_nodeVar698 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar696 + 1.0 ) * 127.1 ) + ( p0_nodeVar698 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar700 ), mix( fract( ( sin( ( ( p0_nodeVar696 * 127.1 ) + ( ( p0_nodeVar698 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar696 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar698 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar700 ), ( ( p0_nodeVar701 * p0_nodeVar701 ) * ( 3.0 - ( p0_nodeVar701 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar702 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar680 = ( ( ( sin( ( ( p0_nodeVar702 * 0.004 ) + ( p0_nodeVar656 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar702 * 0.011 ) + ( p0_nodeVar656 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar702 * 0.0023 ) + ( p0_nodeVar656 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar658 = p0_nodeVar680;

	}

	p0_nodeVar703 = abs( ( p0_nodeVar46 - ( p0_nodeVar657 + ( ( ( p0_nodeVar654 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar658 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar704 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar654 );
	p0_nodeVar705 = ( p0_nodeVar655 + ( ( p0_nodeVar654 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar706 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar655 - 1.0 ) ), ( p0_nodeVar655 + 1.0 ), p0_nodeVar703 ) ) * p0_nodeVar704 ) * p0_nodeVar654 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar705 - 2.0 ) ), ( p0_nodeVar705 + 2.0 ), p0_nodeVar703 ) ) * p0_nodeVar704 ) * ( p0_nodeVar654 * p0_nodeVar654 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar707 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).x;

	} else {

		p0_nodeVar708 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar709 = dot( p0_nodeVar41, p0_nodeVar708 );
		p0_nodeVar710 = ( ( ( ( p0_nodeVar47 + 5.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar711 = picture_read( vec2<f32>( ( ( ( p0_nodeVar708.x * p0_nodeVar709 ) + ( p0_nodeVar43.x * p0_nodeVar710 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar708.y * p0_nodeVar709 ) + ( p0_nodeVar43.y * p0_nodeVar710 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar707 = vec3<f32>( p0_nodeVar711.x, p0_nodeVar711.y, p0_nodeVar711.z ).x;

	}


	if ( p0_nodeVar15 ) {

		p0_nodeVar713 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar714 = dot( p0_nodeVar41, p0_nodeVar713 );
		p0_nodeVar715 = ( ( ( ( p0_nodeVar47 + 5.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar716 = picture_read( vec2<f32>( ( ( ( p0_nodeVar713.x * p0_nodeVar714 ) + ( p0_nodeVar43.x * p0_nodeVar715 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar713.y * p0_nodeVar714 ) + ( p0_nodeVar43.y * p0_nodeVar715 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar712 = ( 1.0 - dot( vec3<f32>( p0_nodeVar716.x, p0_nodeVar716.y, p0_nodeVar716.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) );

	} else {

		p0_nodeVar717 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar718 = dot( p0_nodeVar41, p0_nodeVar717 );
		p0_nodeVar719 = ( ( ( ( p0_nodeVar47 + 5.0 ) * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) ) - p0_nodeVar45 );
		p0_nodeVar720 = picture_read( vec2<f32>( ( ( ( p0_nodeVar717.x * p0_nodeVar718 ) + ( p0_nodeVar43.x * p0_nodeVar719 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar717.y * p0_nodeVar718 ) + ( p0_nodeVar43.y * p0_nodeVar719 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar712 = dot( vec3<f32>( p0_nodeVar720.x, p0_nodeVar720.y, p0_nodeVar720.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	}

	p0_nodeVar721 = pow( clamp( ( ( p0_nodeVar712 - f32(knobs.signalBlackPoint) ) / p0_nodeVar36 ), 0.0, 1.0 ), p0_nodeVar37 );
	p0_nodeVar722 = ( p0_nodeVar13 + ( p0_nodeVar721 * 0.5 ) );
	p0_nodeVar723 = ( p0_nodeVar47 + 5.0 );
	p0_nodeVar724 = ( ( p0_nodeVar723 * p0_nodeVar44 ) + ( p0_nodeVar44 * 0.5 ) );

	if ( p0_nodeVar51 ) {

		p0_nodeVar726 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
		p0_nodeVar727 = floor( p0_nodeVar726 );
		p0_nodeVar728 = ( ( p0_nodeVar723 * 0.37 ) + 17.3 );
		p0_nodeVar729 = floor( p0_nodeVar728 );
		p0_nodeVar730 = fract( p0_nodeVar726 );
		p0_nodeVar731 = ( ( p0_nodeVar730 * p0_nodeVar730 ) * ( 3.0 - ( p0_nodeVar730 * 2.0 ) ) );
		p0_nodeVar732 = fract( p0_nodeVar728 );
		p0_nodeVar733 = ( p0_nodeVar726 * 2.1 );
		p0_nodeVar734 = floor( p0_nodeVar733 );
		p0_nodeVar735 = ( p0_nodeVar728 * 2.1 );
		p0_nodeVar736 = floor( p0_nodeVar735 );
		p0_nodeVar737 = fract( p0_nodeVar733 );
		p0_nodeVar738 = ( ( p0_nodeVar737 * p0_nodeVar737 ) * ( 3.0 - ( p0_nodeVar737 * 2.0 ) ) );
		p0_nodeVar739 = fract( p0_nodeVar735 );
		p0_nodeVar740 = ( p0_nodeVar726 * 4.3 );
		p0_nodeVar741 = floor( p0_nodeVar740 );
		p0_nodeVar742 = ( p0_nodeVar728 * 4.3 );
		p0_nodeVar743 = floor( p0_nodeVar742 );
		p0_nodeVar744 = fract( p0_nodeVar740 );
		p0_nodeVar745 = ( ( p0_nodeVar744 * p0_nodeVar744 ) * ( 3.0 - ( p0_nodeVar744 * 2.0 ) ) );
		p0_nodeVar746 = fract( p0_nodeVar742 );
		p0_nodeVar725 = ( ( ( ( ( ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar727 * 127.1 ) + ( p0_nodeVar729 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar727 + 1.0 ) * 127.1 ) + ( p0_nodeVar729 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar731 ), mix( fract( ( sin( ( ( p0_nodeVar727 * 127.1 ) + ( ( p0_nodeVar729 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar727 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar729 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar731 ), ( ( p0_nodeVar732 * p0_nodeVar732 ) * ( 3.0 - ( p0_nodeVar732 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 4.0 ) + ( abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar734 * 127.1 ) + ( p0_nodeVar736 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar734 + 1.0 ) * 127.1 ) + ( p0_nodeVar736 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar738 ), mix( fract( ( sin( ( ( p0_nodeVar734 * 127.1 ) + ( ( p0_nodeVar736 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar734 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar736 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar738 ), ( ( p0_nodeVar739 * p0_nodeVar739 ) * ( 3.0 - ( p0_nodeVar739 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) * 2.0 ) ) + abs( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar741 * 127.1 ) + ( p0_nodeVar743 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar741 + 1.0 ) * 127.1 ) + ( p0_nodeVar743 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar745 ), mix( fract( ( sin( ( ( p0_nodeVar741 * 127.1 ) + ( ( p0_nodeVar743 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar741 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar743 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar745 ), ( ( p0_nodeVar746 * p0_nodeVar746 ) * ( 3.0 - ( p0_nodeVar746 * 2.0 ) ) ) ) * 2.0 ) - 1.0 ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

	} else {


		if ( ( f32(knobs.noiseMode) > 0.5 ) ) {

			p0_nodeVar748 = ( dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) ) * 0.012 );
			p0_nodeVar749 = floor( p0_nodeVar748 );
			p0_nodeVar750 = ( ( p0_nodeVar723 * 0.37 ) + 17.3 );
			p0_nodeVar751 = floor( p0_nodeVar750 );
			p0_nodeVar752 = fract( p0_nodeVar748 );
			p0_nodeVar753 = ( ( p0_nodeVar752 * p0_nodeVar752 ) * ( 3.0 - ( p0_nodeVar752 * 2.0 ) ) );
			p0_nodeVar754 = fract( p0_nodeVar750 );
			p0_nodeVar755 = ( p0_nodeVar748 * 2.1 );
			p0_nodeVar756 = floor( p0_nodeVar755 );
			p0_nodeVar757 = ( p0_nodeVar750 * 2.1 );
			p0_nodeVar758 = floor( p0_nodeVar757 );
			p0_nodeVar759 = fract( p0_nodeVar755 );
			p0_nodeVar760 = ( ( p0_nodeVar759 * p0_nodeVar759 ) * ( 3.0 - ( p0_nodeVar759 * 2.0 ) ) );
			p0_nodeVar761 = fract( p0_nodeVar757 );
			p0_nodeVar762 = ( p0_nodeVar748 * 4.3 );
			p0_nodeVar763 = floor( p0_nodeVar762 );
			p0_nodeVar764 = ( p0_nodeVar750 * 4.3 );
			p0_nodeVar765 = floor( p0_nodeVar764 );
			p0_nodeVar766 = fract( p0_nodeVar762 );
			p0_nodeVar767 = ( ( p0_nodeVar766 * p0_nodeVar766 ) * ( 3.0 - ( p0_nodeVar766 * 2.0 ) ) );
			p0_nodeVar768 = fract( p0_nodeVar764 );
			p0_nodeVar747 = ( ( ( ( ( ( mix( mix( fract( ( sin( ( ( p0_nodeVar749 * 127.1 ) + ( p0_nodeVar751 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar749 + 1.0 ) * 127.1 ) + ( p0_nodeVar751 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar753 ), mix( fract( ( sin( ( ( p0_nodeVar749 * 127.1 ) + ( ( p0_nodeVar751 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar749 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar751 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar753 ), ( ( p0_nodeVar754 * p0_nodeVar754 ) * ( 3.0 - ( p0_nodeVar754 * 2.0 ) ) ) ) * 4.0 ) + ( mix( mix( fract( ( sin( ( ( p0_nodeVar756 * 127.1 ) + ( p0_nodeVar758 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar756 + 1.0 ) * 127.1 ) + ( p0_nodeVar758 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar760 ), mix( fract( ( sin( ( ( p0_nodeVar756 * 127.1 ) + ( ( p0_nodeVar758 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar756 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar758 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar760 ), ( ( p0_nodeVar761 * p0_nodeVar761 ) * ( 3.0 - ( p0_nodeVar761 * 2.0 ) ) ) ) * 2.0 ) ) + mix( mix( fract( ( sin( ( ( p0_nodeVar763 * 127.1 ) + ( p0_nodeVar765 * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar763 + 1.0 ) * 127.1 ) + ( p0_nodeVar765 * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar767 ), mix( fract( ( sin( ( ( p0_nodeVar763 * 127.1 ) + ( ( p0_nodeVar765 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( ( ( p0_nodeVar763 + 1.0 ) * 127.1 ) + ( ( p0_nodeVar765 + 1.0 ) * 311.7 ) ) ) * 43758.5453 ) ), p0_nodeVar767 ), ( ( p0_nodeVar768 * p0_nodeVar768 ) * ( 3.0 - ( p0_nodeVar768 * 2.0 ) ) ) ) ) / 7.0 ) * 2.0 ) - 1.0 );

		} else {

			p0_nodeVar769 = dot( p0_nodeVar41, vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) ) );
			p0_nodeVar747 = ( ( ( sin( ( ( p0_nodeVar769 * 0.004 ) + ( p0_nodeVar723 * 1.31 ) ) ) * 0.5 ) + ( sin( ( ( p0_nodeVar769 * 0.011 ) + ( p0_nodeVar723 * 2.47 ) ) ) * 0.25 ) ) + ( sin( ( ( p0_nodeVar769 * 0.0023 ) + ( p0_nodeVar723 * 0.71 ) ) ) * 0.25 ) );

		}

		p0_nodeVar725 = p0_nodeVar747;

	}

	p0_nodeVar770 = abs( ( p0_nodeVar46 - ( p0_nodeVar724 + ( ( ( p0_nodeVar721 * p0_nodeVar44 ) * 5.0 ) + ( ( ( p0_nodeVar725 * p0_nodeVar44 ) * f32(knobs.noiseAmount) ) * 2.0 ) ) ) ) );
	p0_nodeVar771 = smoothstep( p0_nodeVar99, p0_nodeVar100, p0_nodeVar721 );
	p0_nodeVar772 = ( p0_nodeVar722 + ( ( p0_nodeVar721 * p0_nodeVar44 ) * 0.08 ) );
	p0_nodeVar773 = ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar722 - 1.0 ) ), ( p0_nodeVar722 + 1.0 ), p0_nodeVar770 ) ) * p0_nodeVar771 ) * p0_nodeVar721 ) + ( ( ( ( 1.0 - smoothstep( max( 0.0, ( p0_nodeVar772 - 2.0 ) ), ( p0_nodeVar772 + 2.0 ), p0_nodeVar770 ) ) * p0_nodeVar771 ) * ( p0_nodeVar721 * p0_nodeVar721 ) ) * 0.35 ) );

	if ( p0_nodeVar2 ) {

		p0_nodeVar774 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar775 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar776 = dot( p0_nodeVar41, p0_nodeVar775 );
		p0_nodeVar777 = ( p0_nodeVar49 - p0_nodeVar45 );
		p0_nodeVar778 = picture_read( vec2<f32>( ( ( ( p0_nodeVar775.x * p0_nodeVar776 ) + ( p0_nodeVar43.x * p0_nodeVar777 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar775.y * p0_nodeVar776 ) + ( p0_nodeVar43.y * p0_nodeVar777 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar774 = vec3<f32>( p0_nodeVar778.x, p0_nodeVar778.y, p0_nodeVar778.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar779 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar780 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar781 = dot( p0_nodeVar41, p0_nodeVar780 );
		p0_nodeVar782 = ( p0_nodeVar121 - p0_nodeVar45 );
		p0_nodeVar783 = picture_read( vec2<f32>( ( ( ( p0_nodeVar780.x * p0_nodeVar781 ) + ( p0_nodeVar43.x * p0_nodeVar782 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar780.y * p0_nodeVar781 ) + ( p0_nodeVar43.y * p0_nodeVar782 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar779 = vec3<f32>( p0_nodeVar783.x, p0_nodeVar783.y, p0_nodeVar783.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar784 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar785 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar786 = dot( p0_nodeVar41, p0_nodeVar785 );
		p0_nodeVar787 = ( p0_nodeVar188 - p0_nodeVar45 );
		p0_nodeVar788 = picture_read( vec2<f32>( ( ( ( p0_nodeVar785.x * p0_nodeVar786 ) + ( p0_nodeVar43.x * p0_nodeVar787 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar785.y * p0_nodeVar786 ) + ( p0_nodeVar43.y * p0_nodeVar787 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar784 = vec3<f32>( p0_nodeVar788.x, p0_nodeVar788.y, p0_nodeVar788.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar789 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar790 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar791 = dot( p0_nodeVar41, p0_nodeVar790 );
		p0_nodeVar792 = ( p0_nodeVar255 - p0_nodeVar45 );
		p0_nodeVar793 = picture_read( vec2<f32>( ( ( ( p0_nodeVar790.x * p0_nodeVar791 ) + ( p0_nodeVar43.x * p0_nodeVar792 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar790.y * p0_nodeVar791 ) + ( p0_nodeVar43.y * p0_nodeVar792 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar789 = vec3<f32>( p0_nodeVar793.x, p0_nodeVar793.y, p0_nodeVar793.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar794 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar795 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar796 = dot( p0_nodeVar41, p0_nodeVar795 );
		p0_nodeVar797 = ( p0_nodeVar322 - p0_nodeVar45 );
		p0_nodeVar798 = picture_read( vec2<f32>( ( ( ( p0_nodeVar795.x * p0_nodeVar796 ) + ( p0_nodeVar43.x * p0_nodeVar797 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar795.y * p0_nodeVar796 ) + ( p0_nodeVar43.y * p0_nodeVar797 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar794 = vec3<f32>( p0_nodeVar798.x, p0_nodeVar798.y, p0_nodeVar798.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar799 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar800 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar801 = dot( p0_nodeVar41, p0_nodeVar800 );
		p0_nodeVar802 = ( p0_nodeVar389 - p0_nodeVar45 );
		p0_nodeVar803 = picture_read( vec2<f32>( ( ( ( p0_nodeVar800.x * p0_nodeVar801 ) + ( p0_nodeVar43.x * p0_nodeVar802 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar800.y * p0_nodeVar801 ) + ( p0_nodeVar43.y * p0_nodeVar802 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar799 = vec3<f32>( p0_nodeVar803.x, p0_nodeVar803.y, p0_nodeVar803.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar804 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar805 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar806 = dot( p0_nodeVar41, p0_nodeVar805 );
		p0_nodeVar807 = ( p0_nodeVar456 - p0_nodeVar45 );
		p0_nodeVar808 = picture_read( vec2<f32>( ( ( ( p0_nodeVar805.x * p0_nodeVar806 ) + ( p0_nodeVar43.x * p0_nodeVar807 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar805.y * p0_nodeVar806 ) + ( p0_nodeVar43.y * p0_nodeVar807 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar804 = vec3<f32>( p0_nodeVar808.x, p0_nodeVar808.y, p0_nodeVar808.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar809 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar810 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar811 = dot( p0_nodeVar41, p0_nodeVar810 );
		p0_nodeVar812 = ( p0_nodeVar523 - p0_nodeVar45 );
		p0_nodeVar813 = picture_read( vec2<f32>( ( ( ( p0_nodeVar810.x * p0_nodeVar811 ) + ( p0_nodeVar43.x * p0_nodeVar812 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar810.y * p0_nodeVar811 ) + ( p0_nodeVar43.y * p0_nodeVar812 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar809 = vec3<f32>( p0_nodeVar813.x, p0_nodeVar813.y, p0_nodeVar813.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar814 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar815 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar816 = dot( p0_nodeVar41, p0_nodeVar815 );
		p0_nodeVar817 = ( p0_nodeVar590 - p0_nodeVar45 );
		p0_nodeVar818 = picture_read( vec2<f32>( ( ( ( p0_nodeVar815.x * p0_nodeVar816 ) + ( p0_nodeVar43.x * p0_nodeVar817 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar815.y * p0_nodeVar816 ) + ( p0_nodeVar43.y * p0_nodeVar817 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar814 = vec3<f32>( p0_nodeVar818.x, p0_nodeVar818.y, p0_nodeVar818.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar819 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar820 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar821 = dot( p0_nodeVar41, p0_nodeVar820 );
		p0_nodeVar822 = ( p0_nodeVar657 - p0_nodeVar45 );
		p0_nodeVar823 = picture_read( vec2<f32>( ( ( ( p0_nodeVar820.x * p0_nodeVar821 ) + ( p0_nodeVar43.x * p0_nodeVar822 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar820.y * p0_nodeVar821 ) + ( p0_nodeVar43.y * p0_nodeVar822 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar819 = vec3<f32>( p0_nodeVar823.x, p0_nodeVar823.y, p0_nodeVar823.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar824 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).y;

	} else {

		p0_nodeVar825 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar826 = dot( p0_nodeVar41, p0_nodeVar825 );
		p0_nodeVar827 = ( p0_nodeVar724 - p0_nodeVar45 );
		p0_nodeVar828 = picture_read( vec2<f32>( ( ( ( p0_nodeVar825.x * p0_nodeVar826 ) + ( p0_nodeVar43.x * p0_nodeVar827 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar825.y * p0_nodeVar826 ) + ( p0_nodeVar43.y * p0_nodeVar827 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar824 = vec3<f32>( p0_nodeVar828.x, p0_nodeVar828.y, p0_nodeVar828.z ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar829 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar830 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar831 = dot( p0_nodeVar41, p0_nodeVar830 );
		p0_nodeVar832 = ( p0_nodeVar49 - p0_nodeVar45 );
		p0_nodeVar833 = picture_read( vec2<f32>( ( ( ( p0_nodeVar830.x * p0_nodeVar831 ) + ( p0_nodeVar43.x * p0_nodeVar832 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar830.y * p0_nodeVar831 ) + ( p0_nodeVar43.y * p0_nodeVar832 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar829 = vec3<f32>( p0_nodeVar833.x, p0_nodeVar833.y, p0_nodeVar833.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar834 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar835 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar836 = dot( p0_nodeVar41, p0_nodeVar835 );
		p0_nodeVar837 = ( p0_nodeVar121 - p0_nodeVar45 );
		p0_nodeVar838 = picture_read( vec2<f32>( ( ( ( p0_nodeVar835.x * p0_nodeVar836 ) + ( p0_nodeVar43.x * p0_nodeVar837 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar835.y * p0_nodeVar836 ) + ( p0_nodeVar43.y * p0_nodeVar837 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar834 = vec3<f32>( p0_nodeVar838.x, p0_nodeVar838.y, p0_nodeVar838.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar839 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar840 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar841 = dot( p0_nodeVar41, p0_nodeVar840 );
		p0_nodeVar842 = ( p0_nodeVar188 - p0_nodeVar45 );
		p0_nodeVar843 = picture_read( vec2<f32>( ( ( ( p0_nodeVar840.x * p0_nodeVar841 ) + ( p0_nodeVar43.x * p0_nodeVar842 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar840.y * p0_nodeVar841 ) + ( p0_nodeVar43.y * p0_nodeVar842 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar839 = vec3<f32>( p0_nodeVar843.x, p0_nodeVar843.y, p0_nodeVar843.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar844 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar845 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar846 = dot( p0_nodeVar41, p0_nodeVar845 );
		p0_nodeVar847 = ( p0_nodeVar255 - p0_nodeVar45 );
		p0_nodeVar848 = picture_read( vec2<f32>( ( ( ( p0_nodeVar845.x * p0_nodeVar846 ) + ( p0_nodeVar43.x * p0_nodeVar847 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar845.y * p0_nodeVar846 ) + ( p0_nodeVar43.y * p0_nodeVar847 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar844 = vec3<f32>( p0_nodeVar848.x, p0_nodeVar848.y, p0_nodeVar848.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar849 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar850 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar851 = dot( p0_nodeVar41, p0_nodeVar850 );
		p0_nodeVar852 = ( p0_nodeVar322 - p0_nodeVar45 );
		p0_nodeVar853 = picture_read( vec2<f32>( ( ( ( p0_nodeVar850.x * p0_nodeVar851 ) + ( p0_nodeVar43.x * p0_nodeVar852 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar850.y * p0_nodeVar851 ) + ( p0_nodeVar43.y * p0_nodeVar852 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar849 = vec3<f32>( p0_nodeVar853.x, p0_nodeVar853.y, p0_nodeVar853.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar854 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar855 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar856 = dot( p0_nodeVar41, p0_nodeVar855 );
		p0_nodeVar857 = ( p0_nodeVar389 - p0_nodeVar45 );
		p0_nodeVar858 = picture_read( vec2<f32>( ( ( ( p0_nodeVar855.x * p0_nodeVar856 ) + ( p0_nodeVar43.x * p0_nodeVar857 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar855.y * p0_nodeVar856 ) + ( p0_nodeVar43.y * p0_nodeVar857 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar854 = vec3<f32>( p0_nodeVar858.x, p0_nodeVar858.y, p0_nodeVar858.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar859 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar860 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar861 = dot( p0_nodeVar41, p0_nodeVar860 );
		p0_nodeVar862 = ( p0_nodeVar456 - p0_nodeVar45 );
		p0_nodeVar863 = picture_read( vec2<f32>( ( ( ( p0_nodeVar860.x * p0_nodeVar861 ) + ( p0_nodeVar43.x * p0_nodeVar862 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar860.y * p0_nodeVar861 ) + ( p0_nodeVar43.y * p0_nodeVar862 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar859 = vec3<f32>( p0_nodeVar863.x, p0_nodeVar863.y, p0_nodeVar863.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar864 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar865 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar866 = dot( p0_nodeVar41, p0_nodeVar865 );
		p0_nodeVar867 = ( p0_nodeVar523 - p0_nodeVar45 );
		p0_nodeVar868 = picture_read( vec2<f32>( ( ( ( p0_nodeVar865.x * p0_nodeVar866 ) + ( p0_nodeVar43.x * p0_nodeVar867 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar865.y * p0_nodeVar866 ) + ( p0_nodeVar43.y * p0_nodeVar867 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar864 = vec3<f32>( p0_nodeVar868.x, p0_nodeVar868.y, p0_nodeVar868.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar869 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar870 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar871 = dot( p0_nodeVar41, p0_nodeVar870 );
		p0_nodeVar872 = ( p0_nodeVar590 - p0_nodeVar45 );
		p0_nodeVar873 = picture_read( vec2<f32>( ( ( ( p0_nodeVar870.x * p0_nodeVar871 ) + ( p0_nodeVar43.x * p0_nodeVar872 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar870.y * p0_nodeVar871 ) + ( p0_nodeVar43.y * p0_nodeVar872 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar869 = vec3<f32>( p0_nodeVar873.x, p0_nodeVar873.y, p0_nodeVar873.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar874 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar875 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar876 = dot( p0_nodeVar41, p0_nodeVar875 );
		p0_nodeVar877 = ( p0_nodeVar657 - p0_nodeVar45 );
		p0_nodeVar878 = picture_read( vec2<f32>( ( ( ( p0_nodeVar875.x * p0_nodeVar876 ) + ( p0_nodeVar43.x * p0_nodeVar877 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar875.y * p0_nodeVar876 ) + ( p0_nodeVar43.y * p0_nodeVar877 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar874 = vec3<f32>( p0_nodeVar878.x, p0_nodeVar878.y, p0_nodeVar878.z ).z;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar879 = vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ).z;

	} else {

		p0_nodeVar880 = vec2<f32>( cos( p0_nodeVar42 ), sin( p0_nodeVar42 ) );
		p0_nodeVar881 = dot( p0_nodeVar41, p0_nodeVar880 );
		p0_nodeVar882 = ( p0_nodeVar724 - p0_nodeVar45 );
		p0_nodeVar883 = picture_read( vec2<f32>( ( ( ( p0_nodeVar880.x * p0_nodeVar881 ) + ( p0_nodeVar43.x * p0_nodeVar882 ) ) / f32(knobs.resolution.x) ), ( ( ( p0_nodeVar880.y * p0_nodeVar881 ) + ( p0_nodeVar43.y * p0_nodeVar882 ) ) / f32(knobs.resolution.y) ) ) );
		p0_nodeVar879 = vec3<f32>( p0_nodeVar883.x, p0_nodeVar883.y, p0_nodeVar883.z ).z;

	}

	p0_nodeVar884 = vec4<f32>( clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar1 * p0_nodeVar103 ) ) + ( p0_nodeVar104 * p0_nodeVar170 ) ) + ( p0_nodeVar171 * p0_nodeVar237 ) ) + ( p0_nodeVar238 * p0_nodeVar304 ) ) + ( p0_nodeVar305 * p0_nodeVar371 ) ) + ( p0_nodeVar372 * p0_nodeVar438 ) ) + ( p0_nodeVar439 * p0_nodeVar505 ) ) + ( p0_nodeVar506 * p0_nodeVar572 ) ) + ( p0_nodeVar573 * p0_nodeVar639 ) ) + ( p0_nodeVar640 * p0_nodeVar706 ) ) + ( p0_nodeVar707 * p0_nodeVar773 ) ), 0.0, 1.0 ), clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar774 * p0_nodeVar103 ) ) + ( p0_nodeVar779 * p0_nodeVar170 ) ) + ( p0_nodeVar784 * p0_nodeVar237 ) ) + ( p0_nodeVar789 * p0_nodeVar304 ) ) + ( p0_nodeVar794 * p0_nodeVar371 ) ) + ( p0_nodeVar799 * p0_nodeVar438 ) ) + ( p0_nodeVar804 * p0_nodeVar505 ) ) + ( p0_nodeVar809 * p0_nodeVar572 ) ) + ( p0_nodeVar814 * p0_nodeVar639 ) ) + ( p0_nodeVar819 * p0_nodeVar706 ) ) + ( p0_nodeVar824 * p0_nodeVar773 ) ), 0.0, 1.0 ), clamp( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar829 * p0_nodeVar103 ) ) + ( p0_nodeVar834 * p0_nodeVar170 ) ) + ( p0_nodeVar839 * p0_nodeVar237 ) ) + ( p0_nodeVar844 * p0_nodeVar304 ) ) + ( p0_nodeVar849 * p0_nodeVar371 ) ) + ( p0_nodeVar854 * p0_nodeVar438 ) ) + ( p0_nodeVar859 * p0_nodeVar505 ) ) + ( p0_nodeVar864 * p0_nodeVar572 ) ) + ( p0_nodeVar869 * p0_nodeVar639 ) ) + ( p0_nodeVar874 * p0_nodeVar706 ) ) + ( p0_nodeVar879 * p0_nodeVar773 ) ), 0.0, 1.0 ), 1.0 );
	p0_nodeVar885 = vec3<f32>( p0_nodeVar884.x, p0_nodeVar884.y, p0_nodeVar884.z );
	p0_nodeVar886 = ( ( ( p0_nodeVar885.x * 0.2126 ) + ( p0_nodeVar885.y * 0.7152 ) ) + ( p0_nodeVar885.z * 0.0722 ) );
	p0_nodeVar887 = mix( vec3<f32>( p0_nodeVar886, p0_nodeVar886, p0_nodeVar886 ), p0_nodeVar885, f32(1.0) );
	p0_nodeVar888 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar887.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar887.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar887.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar887.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar887.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar887.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar887.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar887.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar887.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar884.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar888.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar888.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar889 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar889;

	// result

	p0_output.color = p0_nodeVar889;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

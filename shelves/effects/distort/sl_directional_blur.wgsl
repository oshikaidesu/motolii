// Directional Blur: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Smears the image in one direction or out from a center, for motion and speed.
// --check@mode:Mode,0
// --track@strength:Strength,0,96,18,0.5
// --track@samples:Samples,1,16,8,1
// --track@angle:Angle,0,360,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  mode: f32,
  strength: f32,
  samples: f32,
  angle: f32,
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
var<private> p0_nodeVar2 : f32;
var<private> p0_nodeVar3 : bool;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : vec2<f32>;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : vec2<f32>;
var<private> p0_nodeVar17 : vec2<f32>;
var<private> p0_nodeVar18 : vec2<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : vec2<f32>;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : vec4<f32>;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : vec2<f32>;
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : vec2<f32>;
var<private> p0_nodeVar35 : vec2<f32>;
var<private> p0_nodeVar36 : vec2<f32>;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : vec2<f32>;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : vec2<f32>;
var<private> p0_nodeVar46 : vec2<f32>;
var<private> p0_nodeVar47 : vec2<f32>;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec2<f32>;
var<private> p0_nodeVar54 : vec2<f32>;
var<private> p0_nodeVar55 : vec2<f32>;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : vec2<f32>;
var<private> p0_nodeVar60 : vec2<f32>;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : vec2<f32>;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : vec2<f32>;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : vec2<f32>;
var<private> p0_nodeVar70 : vec2<f32>;
var<private> p0_nodeVar71 : vec2<f32>;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : vec4<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : vec2<f32>;
var<private> p0_nodeVar78 : vec2<f32>;
var<private> p0_nodeVar79 : vec2<f32>;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : vec2<f32>;
var<private> p0_nodeVar83 : vec2<f32>;
var<private> p0_nodeVar84 : vec2<f32>;
var<private> p0_nodeVar85 : f32;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : vec2<f32>;
var<private> p0_nodeVar89 : vec2<f32>;
var<private> p0_nodeVar90 : vec2<f32>;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : vec2<f32>;
var<private> p0_nodeVar95 : vec2<f32>;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : vec4<f32>;
var<private> p0_nodeVar98 : f32;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : vec2<f32>;
var<private> p0_nodeVar102 : vec2<f32>;
var<private> p0_nodeVar103 : vec2<f32>;
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : vec2<f32>;
var<private> p0_nodeVar107 : vec2<f32>;
var<private> p0_nodeVar108 : vec2<f32>;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : vec2<f32>;
var<private> p0_nodeVar113 : vec2<f32>;
var<private> p0_nodeVar114 : vec2<f32>;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : vec2<f32>;
var<private> p0_nodeVar118 : vec2<f32>;
var<private> p0_nodeVar119 : vec2<f32>;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : vec4<f32>;
var<private> p0_nodeVar122 : f32;
var<private> p0_nodeVar123 : f32;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : vec2<f32>;
var<private> p0_nodeVar126 : vec2<f32>;
var<private> p0_nodeVar127 : vec2<f32>;
var<private> p0_nodeVar128 : f32;
var<private> p0_nodeVar129 : f32;
var<private> p0_nodeVar130 : vec2<f32>;
var<private> p0_nodeVar131 : vec2<f32>;
var<private> p0_nodeVar132 : vec2<f32>;
var<private> p0_nodeVar133 : f32;
var<private> p0_nodeVar134 : f32;
var<private> p0_nodeVar135 : f32;
var<private> p0_nodeVar136 : vec2<f32>;
var<private> p0_nodeVar137 : vec2<f32>;
var<private> p0_nodeVar138 : vec2<f32>;
var<private> p0_nodeVar139 : f32;
var<private> p0_nodeVar140 : f32;
var<private> p0_nodeVar141 : vec2<f32>;
var<private> p0_nodeVar142 : vec2<f32>;
var<private> p0_nodeVar143 : vec2<f32>;
var<private> p0_nodeVar144 : f32;
var<private> p0_nodeVar145 : vec4<f32>;
var<private> p0_nodeVar146 : f32;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : f32;
var<private> p0_nodeVar149 : vec2<f32>;
var<private> p0_nodeVar150 : vec2<f32>;
var<private> p0_nodeVar151 : vec2<f32>;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : vec2<f32>;
var<private> p0_nodeVar155 : vec2<f32>;
var<private> p0_nodeVar156 : vec2<f32>;
var<private> p0_nodeVar157 : f32;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : vec2<f32>;
var<private> p0_nodeVar161 : vec2<f32>;
var<private> p0_nodeVar162 : vec2<f32>;
var<private> p0_nodeVar163 : f32;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : vec2<f32>;
var<private> p0_nodeVar166 : vec2<f32>;
var<private> p0_nodeVar167 : vec2<f32>;
var<private> p0_nodeVar168 : f32;
var<private> p0_nodeVar169 : vec4<f32>;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : f32;
var<private> p0_nodeVar173 : vec2<f32>;
var<private> p0_nodeVar174 : vec2<f32>;
var<private> p0_nodeVar175 : vec2<f32>;
var<private> p0_nodeVar176 : f32;
var<private> p0_nodeVar177 : f32;
var<private> p0_nodeVar178 : vec2<f32>;
var<private> p0_nodeVar179 : vec2<f32>;
var<private> p0_nodeVar180 : vec2<f32>;
var<private> p0_nodeVar181 : f32;
var<private> p0_nodeVar182 : f32;
var<private> p0_nodeVar183 : f32;
var<private> p0_nodeVar184 : vec2<f32>;
var<private> p0_nodeVar185 : vec2<f32>;
var<private> p0_nodeVar186 : vec2<f32>;
var<private> p0_nodeVar187 : f32;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : vec2<f32>;
var<private> p0_nodeVar190 : vec2<f32>;
var<private> p0_nodeVar191 : vec2<f32>;
var<private> p0_nodeVar192 : f32;
var<private> p0_nodeVar193 : vec4<f32>;
var<private> p0_nodeVar194 : f32;
var<private> p0_nodeVar195 : f32;
var<private> p0_nodeVar196 : f32;
var<private> p0_nodeVar197 : vec2<f32>;
var<private> p0_nodeVar198 : vec2<f32>;
var<private> p0_nodeVar199 : vec2<f32>;
var<private> p0_nodeVar200 : f32;
var<private> p0_nodeVar201 : f32;
var<private> p0_nodeVar202 : vec2<f32>;
var<private> p0_nodeVar203 : vec2<f32>;
var<private> p0_nodeVar204 : vec2<f32>;
var<private> p0_nodeVar205 : f32;
var<private> p0_nodeVar206 : f32;
var<private> p0_nodeVar207 : f32;
var<private> p0_nodeVar208 : vec2<f32>;
var<private> p0_nodeVar209 : vec2<f32>;
var<private> p0_nodeVar210 : vec2<f32>;
var<private> p0_nodeVar211 : f32;
var<private> p0_nodeVar212 : f32;
var<private> p0_nodeVar213 : vec2<f32>;
var<private> p0_nodeVar214 : vec2<f32>;
var<private> p0_nodeVar215 : vec2<f32>;
var<private> p0_nodeVar216 : f32;
var<private> p0_nodeVar217 : vec4<f32>;
var<private> p0_nodeVar218 : f32;
var<private> p0_nodeVar219 : f32;
var<private> p0_nodeVar220 : f32;
var<private> p0_nodeVar221 : vec2<f32>;
var<private> p0_nodeVar222 : vec2<f32>;
var<private> p0_nodeVar223 : vec2<f32>;
var<private> p0_nodeVar224 : f32;
var<private> p0_nodeVar225 : f32;
var<private> p0_nodeVar226 : vec2<f32>;
var<private> p0_nodeVar227 : vec2<f32>;
var<private> p0_nodeVar228 : vec2<f32>;
var<private> p0_nodeVar229 : f32;
var<private> p0_nodeVar230 : f32;
var<private> p0_nodeVar231 : f32;
var<private> p0_nodeVar232 : vec2<f32>;
var<private> p0_nodeVar233 : vec2<f32>;
var<private> p0_nodeVar234 : vec2<f32>;
var<private> p0_nodeVar235 : f32;
var<private> p0_nodeVar236 : f32;
var<private> p0_nodeVar237 : vec2<f32>;
var<private> p0_nodeVar238 : vec2<f32>;
var<private> p0_nodeVar239 : vec2<f32>;
var<private> p0_nodeVar240 : f32;
var<private> p0_nodeVar241 : vec4<f32>;
var<private> p0_nodeVar242 : f32;
var<private> p0_nodeVar243 : f32;
var<private> p0_nodeVar244 : f32;
var<private> p0_nodeVar245 : vec2<f32>;
var<private> p0_nodeVar246 : vec2<f32>;
var<private> p0_nodeVar247 : vec2<f32>;
var<private> p0_nodeVar248 : f32;
var<private> p0_nodeVar249 : f32;
var<private> p0_nodeVar250 : vec2<f32>;
var<private> p0_nodeVar251 : vec2<f32>;
var<private> p0_nodeVar252 : vec2<f32>;
var<private> p0_nodeVar253 : f32;
var<private> p0_nodeVar254 : f32;
var<private> p0_nodeVar255 : f32;
var<private> p0_nodeVar256 : vec2<f32>;
var<private> p0_nodeVar257 : vec2<f32>;
var<private> p0_nodeVar258 : vec2<f32>;
var<private> p0_nodeVar259 : f32;
var<private> p0_nodeVar260 : f32;
var<private> p0_nodeVar261 : vec2<f32>;
var<private> p0_nodeVar262 : vec2<f32>;
var<private> p0_nodeVar263 : vec2<f32>;
var<private> p0_nodeVar264 : f32;
var<private> p0_nodeVar265 : vec4<f32>;
var<private> p0_nodeVar266 : f32;
var<private> p0_nodeVar267 : f32;
var<private> p0_nodeVar268 : f32;
var<private> p0_nodeVar269 : vec2<f32>;
var<private> p0_nodeVar270 : vec2<f32>;
var<private> p0_nodeVar271 : vec2<f32>;
var<private> p0_nodeVar272 : f32;
var<private> p0_nodeVar273 : f32;
var<private> p0_nodeVar274 : vec2<f32>;
var<private> p0_nodeVar275 : vec2<f32>;
var<private> p0_nodeVar276 : vec2<f32>;
var<private> p0_nodeVar277 : f32;
var<private> p0_nodeVar278 : f32;
var<private> p0_nodeVar279 : f32;
var<private> p0_nodeVar280 : vec2<f32>;
var<private> p0_nodeVar281 : vec2<f32>;
var<private> p0_nodeVar282 : vec2<f32>;
var<private> p0_nodeVar283 : f32;
var<private> p0_nodeVar284 : f32;
var<private> p0_nodeVar285 : vec2<f32>;
var<private> p0_nodeVar286 : vec2<f32>;
var<private> p0_nodeVar287 : vec2<f32>;
var<private> p0_nodeVar288 : f32;
var<private> p0_nodeVar289 : vec4<f32>;
var<private> p0_nodeVar290 : f32;
var<private> p0_nodeVar291 : f32;
var<private> p0_nodeVar292 : f32;
var<private> p0_nodeVar293 : vec2<f32>;
var<private> p0_nodeVar294 : vec2<f32>;
var<private> p0_nodeVar295 : vec2<f32>;
var<private> p0_nodeVar296 : f32;
var<private> p0_nodeVar297 : f32;
var<private> p0_nodeVar298 : vec2<f32>;
var<private> p0_nodeVar299 : vec2<f32>;
var<private> p0_nodeVar300 : vec2<f32>;
var<private> p0_nodeVar301 : f32;
var<private> p0_nodeVar302 : f32;
var<private> p0_nodeVar303 : f32;
var<private> p0_nodeVar304 : vec2<f32>;
var<private> p0_nodeVar305 : vec2<f32>;
var<private> p0_nodeVar306 : vec2<f32>;
var<private> p0_nodeVar307 : f32;
var<private> p0_nodeVar308 : f32;
var<private> p0_nodeVar309 : vec2<f32>;
var<private> p0_nodeVar310 : vec2<f32>;
var<private> p0_nodeVar311 : vec2<f32>;
var<private> p0_nodeVar312 : f32;
var<private> p0_nodeVar313 : vec4<f32>;
var<private> p0_nodeVar314 : f32;
var<private> p0_nodeVar315 : f32;
var<private> p0_nodeVar316 : f32;
var<private> p0_nodeVar317 : vec2<f32>;
var<private> p0_nodeVar318 : vec2<f32>;
var<private> p0_nodeVar319 : vec2<f32>;
var<private> p0_nodeVar320 : f32;
var<private> p0_nodeVar321 : f32;
var<private> p0_nodeVar322 : vec2<f32>;
var<private> p0_nodeVar323 : vec2<f32>;
var<private> p0_nodeVar324 : vec2<f32>;
var<private> p0_nodeVar325 : f32;
var<private> p0_nodeVar326 : f32;
var<private> p0_nodeVar327 : f32;
var<private> p0_nodeVar328 : vec2<f32>;
var<private> p0_nodeVar329 : vec2<f32>;
var<private> p0_nodeVar330 : vec2<f32>;
var<private> p0_nodeVar331 : f32;
var<private> p0_nodeVar332 : f32;
var<private> p0_nodeVar333 : vec2<f32>;
var<private> p0_nodeVar334 : vec2<f32>;
var<private> p0_nodeVar335 : vec2<f32>;
var<private> p0_nodeVar336 : f32;
var<private> p0_nodeVar337 : vec4<f32>;
var<private> p0_nodeVar338 : f32;
var<private> p0_nodeVar339 : f32;
var<private> p0_nodeVar340 : f32;
var<private> p0_nodeVar341 : vec2<f32>;
var<private> p0_nodeVar342 : vec2<f32>;
var<private> p0_nodeVar343 : vec2<f32>;
var<private> p0_nodeVar344 : f32;
var<private> p0_nodeVar345 : f32;
var<private> p0_nodeVar346 : vec2<f32>;
var<private> p0_nodeVar347 : vec2<f32>;
var<private> p0_nodeVar348 : vec2<f32>;
var<private> p0_nodeVar349 : f32;
var<private> p0_nodeVar350 : f32;
var<private> p0_nodeVar351 : f32;
var<private> p0_nodeVar352 : vec2<f32>;
var<private> p0_nodeVar353 : vec2<f32>;
var<private> p0_nodeVar354 : vec2<f32>;
var<private> p0_nodeVar355 : f32;
var<private> p0_nodeVar356 : f32;
var<private> p0_nodeVar357 : vec2<f32>;
var<private> p0_nodeVar358 : vec2<f32>;
var<private> p0_nodeVar359 : vec2<f32>;
var<private> p0_nodeVar360 : f32;
var<private> p0_nodeVar361 : vec4<f32>;
var<private> p0_nodeVar362 : f32;
var<private> p0_nodeVar363 : f32;
var<private> p0_nodeVar364 : f32;
var<private> p0_nodeVar365 : vec2<f32>;
var<private> p0_nodeVar366 : vec2<f32>;
var<private> p0_nodeVar367 : vec2<f32>;
var<private> p0_nodeVar368 : f32;
var<private> p0_nodeVar369 : f32;
var<private> p0_nodeVar370 : vec2<f32>;
var<private> p0_nodeVar371 : vec2<f32>;
var<private> p0_nodeVar372 : vec2<f32>;
var<private> p0_nodeVar373 : f32;
var<private> p0_nodeVar374 : f32;
var<private> p0_nodeVar375 : f32;
var<private> p0_nodeVar376 : vec2<f32>;
var<private> p0_nodeVar377 : vec2<f32>;
var<private> p0_nodeVar378 : vec2<f32>;
var<private> p0_nodeVar379 : f32;
var<private> p0_nodeVar380 : f32;
var<private> p0_nodeVar381 : vec2<f32>;
var<private> p0_nodeVar382 : vec2<f32>;
var<private> p0_nodeVar383 : vec2<f32>;
var<private> p0_nodeVar384 : f32;
var<private> p0_nodeVar385 : vec4<f32>;
var<private> p0_nodeVar386 : f32;
var<private> p0_nodeVar387 : f32;
var<private> p0_nodeVar388 : vec4<f32>;
var<private> p0_nodeVar389 : vec3<f32>;
var<private> p0_nodeVar390 : f32;
var<private> p0_nodeVar391 : vec3<f32>;
var<private> p0_nodeVar392 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar393 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar3 = ( f32(knobs.mode) > 0.5 );

	if ( p0_nodeVar3 ) {

		p0_nodeVar4 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar5 = vec2<f32>( cos( p0_nodeVar4 ), sin( p0_nodeVar4 ) );
		p0_nodeVar6 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar7 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar6.x ), ( p0_nodeVar1.y - p0_nodeVar6.y ) );
		p0_nodeVar8 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar2 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar5.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar5.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.5 ), ( vec2<f32>( ( p0_nodeVar7.x * ( f32(knobs.strength) / p0_nodeVar8 ) ), ( p0_nodeVar7.y * ( f32(knobs.strength) / p0_nodeVar8 ) ) ).x * -0.5 ) ).y;

	} else {

		p0_nodeVar9 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar10 = vec2<f32>( cos( p0_nodeVar9 ), sin( p0_nodeVar9 ) );
		p0_nodeVar11 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar12 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar11.x ), ( p0_nodeVar1.y - p0_nodeVar11.y ) );
		p0_nodeVar13 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar2 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar10.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar10.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.5 ), ( vec2<f32>( ( p0_nodeVar12.x * ( f32(knobs.strength) / p0_nodeVar13 ) ), ( p0_nodeVar12.y * ( f32(knobs.strength) / p0_nodeVar13 ) ) ).x * -0.5 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar15 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar16 = vec2<f32>( cos( p0_nodeVar15 ), sin( p0_nodeVar15 ) );
		p0_nodeVar17 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar18 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar17.x ), ( p0_nodeVar1.y - p0_nodeVar17.y ) );
		p0_nodeVar19 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar14 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar16.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar16.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.5 ), ( vec2<f32>( ( p0_nodeVar18.x * ( f32(knobs.strength) / p0_nodeVar19 ) ), ( p0_nodeVar18.y * ( f32(knobs.strength) / p0_nodeVar19 ) ) ).y * -0.5 ) ).y;

	} else {

		p0_nodeVar20 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar21 = vec2<f32>( cos( p0_nodeVar20 ), sin( p0_nodeVar20 ) );
		p0_nodeVar22 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar23 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar22.x ), ( p0_nodeVar1.y - p0_nodeVar22.y ) );
		p0_nodeVar24 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar14 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar21.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar21.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.5 ), ( vec2<f32>( ( p0_nodeVar23.x * ( f32(knobs.strength) / p0_nodeVar24 ) ), ( p0_nodeVar23.y * ( f32(knobs.strength) / p0_nodeVar24 ) ) ).y * -0.5 ) ).x;

	}

	p0_nodeVar25 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar2 ), ( p0_nodeVar1.y + p0_nodeVar14 ) ) );
	p0_nodeVar26 = step( 0.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar28 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar29 = vec2<f32>( cos( p0_nodeVar28 ), sin( p0_nodeVar28 ) );
		p0_nodeVar30 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar31 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar30.x ), ( p0_nodeVar1.y - p0_nodeVar30.y ) );
		p0_nodeVar32 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar27 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar29.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar29.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar31.x * ( f32(knobs.strength) / p0_nodeVar32 ) ), ( p0_nodeVar31.y * ( f32(knobs.strength) / p0_nodeVar32 ) ) ).x * -0.43333333333333335 ) ).y;

	} else {

		p0_nodeVar33 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar34 = vec2<f32>( cos( p0_nodeVar33 ), sin( p0_nodeVar33 ) );
		p0_nodeVar35 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar36 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar35.x ), ( p0_nodeVar1.y - p0_nodeVar35.y ) );
		p0_nodeVar37 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar27 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar34.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar34.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar36.x * ( f32(knobs.strength) / p0_nodeVar37 ) ), ( p0_nodeVar36.y * ( f32(knobs.strength) / p0_nodeVar37 ) ) ).x * -0.43333333333333335 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar39 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar40 = vec2<f32>( cos( p0_nodeVar39 ), sin( p0_nodeVar39 ) );
		p0_nodeVar41 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar42 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar41.x ), ( p0_nodeVar1.y - p0_nodeVar41.y ) );
		p0_nodeVar43 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar38 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar40.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar40.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar42.x * ( f32(knobs.strength) / p0_nodeVar43 ) ), ( p0_nodeVar42.y * ( f32(knobs.strength) / p0_nodeVar43 ) ) ).y * -0.43333333333333335 ) ).y;

	} else {

		p0_nodeVar44 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar45 = vec2<f32>( cos( p0_nodeVar44 ), sin( p0_nodeVar44 ) );
		p0_nodeVar46 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar47 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar46.x ), ( p0_nodeVar1.y - p0_nodeVar46.y ) );
		p0_nodeVar48 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar38 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar45.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar45.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar47.x * ( f32(knobs.strength) / p0_nodeVar48 ) ), ( p0_nodeVar47.y * ( f32(knobs.strength) / p0_nodeVar48 ) ) ).y * -0.43333333333333335 ) ).x;

	}

	p0_nodeVar49 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar27 ), ( p0_nodeVar1.y + p0_nodeVar38 ) ) );
	p0_nodeVar50 = step( 1.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar52 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar53 = vec2<f32>( cos( p0_nodeVar52 ), sin( p0_nodeVar52 ) );
		p0_nodeVar54 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar55 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar54.x ), ( p0_nodeVar1.y - p0_nodeVar54.y ) );
		p0_nodeVar56 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar51 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar53.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar53.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar55.x * ( f32(knobs.strength) / p0_nodeVar56 ) ), ( p0_nodeVar55.y * ( f32(knobs.strength) / p0_nodeVar56 ) ) ).x * -0.3666666666666667 ) ).y;

	} else {

		p0_nodeVar57 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar58 = vec2<f32>( cos( p0_nodeVar57 ), sin( p0_nodeVar57 ) );
		p0_nodeVar59 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar60 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar59.x ), ( p0_nodeVar1.y - p0_nodeVar59.y ) );
		p0_nodeVar61 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar51 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar58.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar58.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar60.x * ( f32(knobs.strength) / p0_nodeVar61 ) ), ( p0_nodeVar60.y * ( f32(knobs.strength) / p0_nodeVar61 ) ) ).x * -0.3666666666666667 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar63 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar64 = vec2<f32>( cos( p0_nodeVar63 ), sin( p0_nodeVar63 ) );
		p0_nodeVar65 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar66 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar65.x ), ( p0_nodeVar1.y - p0_nodeVar65.y ) );
		p0_nodeVar67 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar62 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar64.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar64.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar66.x * ( f32(knobs.strength) / p0_nodeVar67 ) ), ( p0_nodeVar66.y * ( f32(knobs.strength) / p0_nodeVar67 ) ) ).y * -0.3666666666666667 ) ).y;

	} else {

		p0_nodeVar68 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar69 = vec2<f32>( cos( p0_nodeVar68 ), sin( p0_nodeVar68 ) );
		p0_nodeVar70 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar71 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar70.x ), ( p0_nodeVar1.y - p0_nodeVar70.y ) );
		p0_nodeVar72 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar62 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar69.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar69.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar71.x * ( f32(knobs.strength) / p0_nodeVar72 ) ), ( p0_nodeVar71.y * ( f32(knobs.strength) / p0_nodeVar72 ) ) ).y * -0.3666666666666667 ) ).x;

	}

	p0_nodeVar73 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar51 ), ( p0_nodeVar1.y + p0_nodeVar62 ) ) );
	p0_nodeVar74 = step( 2.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar76 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar77 = vec2<f32>( cos( p0_nodeVar76 ), sin( p0_nodeVar76 ) );
		p0_nodeVar78 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar79 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar78.x ), ( p0_nodeVar1.y - p0_nodeVar78.y ) );
		p0_nodeVar80 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar75 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar77.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar77.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.3 ), ( vec2<f32>( ( p0_nodeVar79.x * ( f32(knobs.strength) / p0_nodeVar80 ) ), ( p0_nodeVar79.y * ( f32(knobs.strength) / p0_nodeVar80 ) ) ).x * -0.3 ) ).y;

	} else {

		p0_nodeVar81 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar82 = vec2<f32>( cos( p0_nodeVar81 ), sin( p0_nodeVar81 ) );
		p0_nodeVar83 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar84 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar83.x ), ( p0_nodeVar1.y - p0_nodeVar83.y ) );
		p0_nodeVar85 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar75 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar82.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar82.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.3 ), ( vec2<f32>( ( p0_nodeVar84.x * ( f32(knobs.strength) / p0_nodeVar85 ) ), ( p0_nodeVar84.y * ( f32(knobs.strength) / p0_nodeVar85 ) ) ).x * -0.3 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar87 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar88 = vec2<f32>( cos( p0_nodeVar87 ), sin( p0_nodeVar87 ) );
		p0_nodeVar89 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar90 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar89.x ), ( p0_nodeVar1.y - p0_nodeVar89.y ) );
		p0_nodeVar91 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar86 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar88.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar88.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.3 ), ( vec2<f32>( ( p0_nodeVar90.x * ( f32(knobs.strength) / p0_nodeVar91 ) ), ( p0_nodeVar90.y * ( f32(knobs.strength) / p0_nodeVar91 ) ) ).y * -0.3 ) ).y;

	} else {

		p0_nodeVar92 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar93 = vec2<f32>( cos( p0_nodeVar92 ), sin( p0_nodeVar92 ) );
		p0_nodeVar94 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar95 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar94.x ), ( p0_nodeVar1.y - p0_nodeVar94.y ) );
		p0_nodeVar96 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar86 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar93.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar93.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.3 ), ( vec2<f32>( ( p0_nodeVar95.x * ( f32(knobs.strength) / p0_nodeVar96 ) ), ( p0_nodeVar95.y * ( f32(knobs.strength) / p0_nodeVar96 ) ) ).y * -0.3 ) ).x;

	}

	p0_nodeVar97 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar75 ), ( p0_nodeVar1.y + p0_nodeVar86 ) ) );
	p0_nodeVar98 = step( 3.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar100 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar101 = vec2<f32>( cos( p0_nodeVar100 ), sin( p0_nodeVar100 ) );
		p0_nodeVar102 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar103 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar102.x ), ( p0_nodeVar1.y - p0_nodeVar102.y ) );
		p0_nodeVar104 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar99 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar101.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar101.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.23333333333333334 ), ( vec2<f32>( ( p0_nodeVar103.x * ( f32(knobs.strength) / p0_nodeVar104 ) ), ( p0_nodeVar103.y * ( f32(knobs.strength) / p0_nodeVar104 ) ) ).x * -0.23333333333333334 ) ).y;

	} else {

		p0_nodeVar105 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar106 = vec2<f32>( cos( p0_nodeVar105 ), sin( p0_nodeVar105 ) );
		p0_nodeVar107 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar108 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar107.x ), ( p0_nodeVar1.y - p0_nodeVar107.y ) );
		p0_nodeVar109 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar99 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar106.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar106.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.23333333333333334 ), ( vec2<f32>( ( p0_nodeVar108.x * ( f32(knobs.strength) / p0_nodeVar109 ) ), ( p0_nodeVar108.y * ( f32(knobs.strength) / p0_nodeVar109 ) ) ).x * -0.23333333333333334 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar111 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar112 = vec2<f32>( cos( p0_nodeVar111 ), sin( p0_nodeVar111 ) );
		p0_nodeVar113 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar114 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar113.x ), ( p0_nodeVar1.y - p0_nodeVar113.y ) );
		p0_nodeVar115 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar110 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar112.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar112.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.23333333333333334 ), ( vec2<f32>( ( p0_nodeVar114.x * ( f32(knobs.strength) / p0_nodeVar115 ) ), ( p0_nodeVar114.y * ( f32(knobs.strength) / p0_nodeVar115 ) ) ).y * -0.23333333333333334 ) ).y;

	} else {

		p0_nodeVar116 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar117 = vec2<f32>( cos( p0_nodeVar116 ), sin( p0_nodeVar116 ) );
		p0_nodeVar118 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar119 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar118.x ), ( p0_nodeVar1.y - p0_nodeVar118.y ) );
		p0_nodeVar120 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar110 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar117.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar117.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.23333333333333334 ), ( vec2<f32>( ( p0_nodeVar119.x * ( f32(knobs.strength) / p0_nodeVar120 ) ), ( p0_nodeVar119.y * ( f32(knobs.strength) / p0_nodeVar120 ) ) ).y * -0.23333333333333334 ) ).x;

	}

	p0_nodeVar121 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar99 ), ( p0_nodeVar1.y + p0_nodeVar110 ) ) );
	p0_nodeVar122 = step( 4.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar124 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar125 = vec2<f32>( cos( p0_nodeVar124 ), sin( p0_nodeVar124 ) );
		p0_nodeVar126 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar127 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar126.x ), ( p0_nodeVar1.y - p0_nodeVar126.y ) );
		p0_nodeVar128 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar123 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar125.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar125.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.16666666666666669 ), ( vec2<f32>( ( p0_nodeVar127.x * ( f32(knobs.strength) / p0_nodeVar128 ) ), ( p0_nodeVar127.y * ( f32(knobs.strength) / p0_nodeVar128 ) ) ).x * -0.16666666666666669 ) ).y;

	} else {

		p0_nodeVar129 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar130 = vec2<f32>( cos( p0_nodeVar129 ), sin( p0_nodeVar129 ) );
		p0_nodeVar131 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar132 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar131.x ), ( p0_nodeVar1.y - p0_nodeVar131.y ) );
		p0_nodeVar133 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar123 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar130.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar130.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.16666666666666669 ), ( vec2<f32>( ( p0_nodeVar132.x * ( f32(knobs.strength) / p0_nodeVar133 ) ), ( p0_nodeVar132.y * ( f32(knobs.strength) / p0_nodeVar133 ) ) ).x * -0.16666666666666669 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar135 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar136 = vec2<f32>( cos( p0_nodeVar135 ), sin( p0_nodeVar135 ) );
		p0_nodeVar137 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar138 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar137.x ), ( p0_nodeVar1.y - p0_nodeVar137.y ) );
		p0_nodeVar139 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar134 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar136.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar136.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.16666666666666669 ), ( vec2<f32>( ( p0_nodeVar138.x * ( f32(knobs.strength) / p0_nodeVar139 ) ), ( p0_nodeVar138.y * ( f32(knobs.strength) / p0_nodeVar139 ) ) ).y * -0.16666666666666669 ) ).y;

	} else {

		p0_nodeVar140 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar141 = vec2<f32>( cos( p0_nodeVar140 ), sin( p0_nodeVar140 ) );
		p0_nodeVar142 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar143 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar142.x ), ( p0_nodeVar1.y - p0_nodeVar142.y ) );
		p0_nodeVar144 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar134 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar141.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar141.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.16666666666666669 ), ( vec2<f32>( ( p0_nodeVar143.x * ( f32(knobs.strength) / p0_nodeVar144 ) ), ( p0_nodeVar143.y * ( f32(knobs.strength) / p0_nodeVar144 ) ) ).y * -0.16666666666666669 ) ).x;

	}

	p0_nodeVar145 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar123 ), ( p0_nodeVar1.y + p0_nodeVar134 ) ) );
	p0_nodeVar146 = step( 5.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar148 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar149 = vec2<f32>( cos( p0_nodeVar148 ), sin( p0_nodeVar148 ) );
		p0_nodeVar150 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar151 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar150.x ), ( p0_nodeVar1.y - p0_nodeVar150.y ) );
		p0_nodeVar152 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar147 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar149.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar149.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar151.x * ( f32(knobs.strength) / p0_nodeVar152 ) ), ( p0_nodeVar151.y * ( f32(knobs.strength) / p0_nodeVar152 ) ) ).x * -0.09999999999999998 ) ).y;

	} else {

		p0_nodeVar153 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar154 = vec2<f32>( cos( p0_nodeVar153 ), sin( p0_nodeVar153 ) );
		p0_nodeVar155 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar156 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar155.x ), ( p0_nodeVar1.y - p0_nodeVar155.y ) );
		p0_nodeVar157 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar147 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar154.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar154.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar156.x * ( f32(knobs.strength) / p0_nodeVar157 ) ), ( p0_nodeVar156.y * ( f32(knobs.strength) / p0_nodeVar157 ) ) ).x * -0.09999999999999998 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar159 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar160 = vec2<f32>( cos( p0_nodeVar159 ), sin( p0_nodeVar159 ) );
		p0_nodeVar161 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar162 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar161.x ), ( p0_nodeVar1.y - p0_nodeVar161.y ) );
		p0_nodeVar163 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar158 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar160.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar160.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar162.x * ( f32(knobs.strength) / p0_nodeVar163 ) ), ( p0_nodeVar162.y * ( f32(knobs.strength) / p0_nodeVar163 ) ) ).y * -0.09999999999999998 ) ).y;

	} else {

		p0_nodeVar164 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar165 = vec2<f32>( cos( p0_nodeVar164 ), sin( p0_nodeVar164 ) );
		p0_nodeVar166 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar167 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar166.x ), ( p0_nodeVar1.y - p0_nodeVar166.y ) );
		p0_nodeVar168 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar158 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar165.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar165.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar167.x * ( f32(knobs.strength) / p0_nodeVar168 ) ), ( p0_nodeVar167.y * ( f32(knobs.strength) / p0_nodeVar168 ) ) ).y * -0.09999999999999998 ) ).x;

	}

	p0_nodeVar169 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar147 ), ( p0_nodeVar1.y + p0_nodeVar158 ) ) );
	p0_nodeVar170 = step( 6.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar172 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar173 = vec2<f32>( cos( p0_nodeVar172 ), sin( p0_nodeVar172 ) );
		p0_nodeVar174 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar175 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar174.x ), ( p0_nodeVar1.y - p0_nodeVar174.y ) );
		p0_nodeVar176 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar171 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar173.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar173.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar175.x * ( f32(knobs.strength) / p0_nodeVar176 ) ), ( p0_nodeVar175.y * ( f32(knobs.strength) / p0_nodeVar176 ) ) ).x * -0.033333333333333326 ) ).y;

	} else {

		p0_nodeVar177 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar178 = vec2<f32>( cos( p0_nodeVar177 ), sin( p0_nodeVar177 ) );
		p0_nodeVar179 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar180 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar179.x ), ( p0_nodeVar1.y - p0_nodeVar179.y ) );
		p0_nodeVar181 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar171 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar178.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar178.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * -0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar180.x * ( f32(knobs.strength) / p0_nodeVar181 ) ), ( p0_nodeVar180.y * ( f32(knobs.strength) / p0_nodeVar181 ) ) ).x * -0.033333333333333326 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar183 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar184 = vec2<f32>( cos( p0_nodeVar183 ), sin( p0_nodeVar183 ) );
		p0_nodeVar185 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar186 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar185.x ), ( p0_nodeVar1.y - p0_nodeVar185.y ) );
		p0_nodeVar187 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar182 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar184.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar184.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar186.x * ( f32(knobs.strength) / p0_nodeVar187 ) ), ( p0_nodeVar186.y * ( f32(knobs.strength) / p0_nodeVar187 ) ) ).y * -0.033333333333333326 ) ).y;

	} else {

		p0_nodeVar188 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar189 = vec2<f32>( cos( p0_nodeVar188 ), sin( p0_nodeVar188 ) );
		p0_nodeVar190 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar191 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar190.x ), ( p0_nodeVar1.y - p0_nodeVar190.y ) );
		p0_nodeVar192 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar182 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar189.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar189.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * -0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar191.x * ( f32(knobs.strength) / p0_nodeVar192 ) ), ( p0_nodeVar191.y * ( f32(knobs.strength) / p0_nodeVar192 ) ) ).y * -0.033333333333333326 ) ).x;

	}

	p0_nodeVar193 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar171 ), ( p0_nodeVar1.y + p0_nodeVar182 ) ) );
	p0_nodeVar194 = step( 7.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar196 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar197 = vec2<f32>( cos( p0_nodeVar196 ), sin( p0_nodeVar196 ) );
		p0_nodeVar198 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar199 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar198.x ), ( p0_nodeVar1.y - p0_nodeVar198.y ) );
		p0_nodeVar200 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar195 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar197.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar197.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar199.x * ( f32(knobs.strength) / p0_nodeVar200 ) ), ( p0_nodeVar199.y * ( f32(knobs.strength) / p0_nodeVar200 ) ) ).x * 0.033333333333333326 ) ).y;

	} else {

		p0_nodeVar201 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar202 = vec2<f32>( cos( p0_nodeVar201 ), sin( p0_nodeVar201 ) );
		p0_nodeVar203 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar204 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar203.x ), ( p0_nodeVar1.y - p0_nodeVar203.y ) );
		p0_nodeVar205 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar195 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar202.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar202.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar204.x * ( f32(knobs.strength) / p0_nodeVar205 ) ), ( p0_nodeVar204.y * ( f32(knobs.strength) / p0_nodeVar205 ) ) ).x * 0.033333333333333326 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar207 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar208 = vec2<f32>( cos( p0_nodeVar207 ), sin( p0_nodeVar207 ) );
		p0_nodeVar209 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar210 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar209.x ), ( p0_nodeVar1.y - p0_nodeVar209.y ) );
		p0_nodeVar211 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar206 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar208.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar208.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar210.x * ( f32(knobs.strength) / p0_nodeVar211 ) ), ( p0_nodeVar210.y * ( f32(knobs.strength) / p0_nodeVar211 ) ) ).y * 0.033333333333333326 ) ).y;

	} else {

		p0_nodeVar212 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar213 = vec2<f32>( cos( p0_nodeVar212 ), sin( p0_nodeVar212 ) );
		p0_nodeVar214 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar215 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar214.x ), ( p0_nodeVar1.y - p0_nodeVar214.y ) );
		p0_nodeVar216 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar206 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar213.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar213.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.033333333333333326 ), ( vec2<f32>( ( p0_nodeVar215.x * ( f32(knobs.strength) / p0_nodeVar216 ) ), ( p0_nodeVar215.y * ( f32(knobs.strength) / p0_nodeVar216 ) ) ).y * 0.033333333333333326 ) ).x;

	}

	p0_nodeVar217 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar195 ), ( p0_nodeVar1.y + p0_nodeVar206 ) ) );
	p0_nodeVar218 = step( 8.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar220 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar221 = vec2<f32>( cos( p0_nodeVar220 ), sin( p0_nodeVar220 ) );
		p0_nodeVar222 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar223 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar222.x ), ( p0_nodeVar1.y - p0_nodeVar222.y ) );
		p0_nodeVar224 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar219 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar221.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar221.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar223.x * ( f32(knobs.strength) / p0_nodeVar224 ) ), ( p0_nodeVar223.y * ( f32(knobs.strength) / p0_nodeVar224 ) ) ).x * 0.09999999999999998 ) ).y;

	} else {

		p0_nodeVar225 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar226 = vec2<f32>( cos( p0_nodeVar225 ), sin( p0_nodeVar225 ) );
		p0_nodeVar227 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar228 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar227.x ), ( p0_nodeVar1.y - p0_nodeVar227.y ) );
		p0_nodeVar229 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar219 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar226.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar226.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar228.x * ( f32(knobs.strength) / p0_nodeVar229 ) ), ( p0_nodeVar228.y * ( f32(knobs.strength) / p0_nodeVar229 ) ) ).x * 0.09999999999999998 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar231 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar232 = vec2<f32>( cos( p0_nodeVar231 ), sin( p0_nodeVar231 ) );
		p0_nodeVar233 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar234 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar233.x ), ( p0_nodeVar1.y - p0_nodeVar233.y ) );
		p0_nodeVar235 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar230 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar232.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar232.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar234.x * ( f32(knobs.strength) / p0_nodeVar235 ) ), ( p0_nodeVar234.y * ( f32(knobs.strength) / p0_nodeVar235 ) ) ).y * 0.09999999999999998 ) ).y;

	} else {

		p0_nodeVar236 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar237 = vec2<f32>( cos( p0_nodeVar236 ), sin( p0_nodeVar236 ) );
		p0_nodeVar238 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar239 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar238.x ), ( p0_nodeVar1.y - p0_nodeVar238.y ) );
		p0_nodeVar240 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar230 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar237.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar237.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.09999999999999998 ), ( vec2<f32>( ( p0_nodeVar239.x * ( f32(knobs.strength) / p0_nodeVar240 ) ), ( p0_nodeVar239.y * ( f32(knobs.strength) / p0_nodeVar240 ) ) ).y * 0.09999999999999998 ) ).x;

	}

	p0_nodeVar241 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar219 ), ( p0_nodeVar1.y + p0_nodeVar230 ) ) );
	p0_nodeVar242 = step( 9.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar244 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar245 = vec2<f32>( cos( p0_nodeVar244 ), sin( p0_nodeVar244 ) );
		p0_nodeVar246 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar247 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar246.x ), ( p0_nodeVar1.y - p0_nodeVar246.y ) );
		p0_nodeVar248 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar243 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar245.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar245.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.16666666666666663 ), ( vec2<f32>( ( p0_nodeVar247.x * ( f32(knobs.strength) / p0_nodeVar248 ) ), ( p0_nodeVar247.y * ( f32(knobs.strength) / p0_nodeVar248 ) ) ).x * 0.16666666666666663 ) ).y;

	} else {

		p0_nodeVar249 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar250 = vec2<f32>( cos( p0_nodeVar249 ), sin( p0_nodeVar249 ) );
		p0_nodeVar251 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar252 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar251.x ), ( p0_nodeVar1.y - p0_nodeVar251.y ) );
		p0_nodeVar253 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar243 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar250.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar250.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.16666666666666663 ), ( vec2<f32>( ( p0_nodeVar252.x * ( f32(knobs.strength) / p0_nodeVar253 ) ), ( p0_nodeVar252.y * ( f32(knobs.strength) / p0_nodeVar253 ) ) ).x * 0.16666666666666663 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar255 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar256 = vec2<f32>( cos( p0_nodeVar255 ), sin( p0_nodeVar255 ) );
		p0_nodeVar257 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar258 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar257.x ), ( p0_nodeVar1.y - p0_nodeVar257.y ) );
		p0_nodeVar259 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar254 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar256.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar256.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.16666666666666663 ), ( vec2<f32>( ( p0_nodeVar258.x * ( f32(knobs.strength) / p0_nodeVar259 ) ), ( p0_nodeVar258.y * ( f32(knobs.strength) / p0_nodeVar259 ) ) ).y * 0.16666666666666663 ) ).y;

	} else {

		p0_nodeVar260 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar261 = vec2<f32>( cos( p0_nodeVar260 ), sin( p0_nodeVar260 ) );
		p0_nodeVar262 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar263 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar262.x ), ( p0_nodeVar1.y - p0_nodeVar262.y ) );
		p0_nodeVar264 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar254 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar261.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar261.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.16666666666666663 ), ( vec2<f32>( ( p0_nodeVar263.x * ( f32(knobs.strength) / p0_nodeVar264 ) ), ( p0_nodeVar263.y * ( f32(knobs.strength) / p0_nodeVar264 ) ) ).y * 0.16666666666666663 ) ).x;

	}

	p0_nodeVar265 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar243 ), ( p0_nodeVar1.y + p0_nodeVar254 ) ) );
	p0_nodeVar266 = step( 10.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar268 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar269 = vec2<f32>( cos( p0_nodeVar268 ), sin( p0_nodeVar268 ) );
		p0_nodeVar270 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar271 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar270.x ), ( p0_nodeVar1.y - p0_nodeVar270.y ) );
		p0_nodeVar272 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar267 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar269.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar269.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.23333333333333328 ), ( vec2<f32>( ( p0_nodeVar271.x * ( f32(knobs.strength) / p0_nodeVar272 ) ), ( p0_nodeVar271.y * ( f32(knobs.strength) / p0_nodeVar272 ) ) ).x * 0.23333333333333328 ) ).y;

	} else {

		p0_nodeVar273 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar274 = vec2<f32>( cos( p0_nodeVar273 ), sin( p0_nodeVar273 ) );
		p0_nodeVar275 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar276 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar275.x ), ( p0_nodeVar1.y - p0_nodeVar275.y ) );
		p0_nodeVar277 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar267 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar274.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar274.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.23333333333333328 ), ( vec2<f32>( ( p0_nodeVar276.x * ( f32(knobs.strength) / p0_nodeVar277 ) ), ( p0_nodeVar276.y * ( f32(knobs.strength) / p0_nodeVar277 ) ) ).x * 0.23333333333333328 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar279 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar280 = vec2<f32>( cos( p0_nodeVar279 ), sin( p0_nodeVar279 ) );
		p0_nodeVar281 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar282 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar281.x ), ( p0_nodeVar1.y - p0_nodeVar281.y ) );
		p0_nodeVar283 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar278 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar280.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar280.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.23333333333333328 ), ( vec2<f32>( ( p0_nodeVar282.x * ( f32(knobs.strength) / p0_nodeVar283 ) ), ( p0_nodeVar282.y * ( f32(knobs.strength) / p0_nodeVar283 ) ) ).y * 0.23333333333333328 ) ).y;

	} else {

		p0_nodeVar284 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar285 = vec2<f32>( cos( p0_nodeVar284 ), sin( p0_nodeVar284 ) );
		p0_nodeVar286 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar287 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar286.x ), ( p0_nodeVar1.y - p0_nodeVar286.y ) );
		p0_nodeVar288 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar278 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar285.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar285.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.23333333333333328 ), ( vec2<f32>( ( p0_nodeVar287.x * ( f32(knobs.strength) / p0_nodeVar288 ) ), ( p0_nodeVar287.y * ( f32(knobs.strength) / p0_nodeVar288 ) ) ).y * 0.23333333333333328 ) ).x;

	}

	p0_nodeVar289 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar267 ), ( p0_nodeVar1.y + p0_nodeVar278 ) ) );
	p0_nodeVar290 = step( 11.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar292 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar293 = vec2<f32>( cos( p0_nodeVar292 ), sin( p0_nodeVar292 ) );
		p0_nodeVar294 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar295 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar294.x ), ( p0_nodeVar1.y - p0_nodeVar294.y ) );
		p0_nodeVar296 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar291 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar293.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar293.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.30000000000000004 ), ( vec2<f32>( ( p0_nodeVar295.x * ( f32(knobs.strength) / p0_nodeVar296 ) ), ( p0_nodeVar295.y * ( f32(knobs.strength) / p0_nodeVar296 ) ) ).x * 0.30000000000000004 ) ).y;

	} else {

		p0_nodeVar297 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar298 = vec2<f32>( cos( p0_nodeVar297 ), sin( p0_nodeVar297 ) );
		p0_nodeVar299 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar300 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar299.x ), ( p0_nodeVar1.y - p0_nodeVar299.y ) );
		p0_nodeVar301 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar291 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar298.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar298.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.30000000000000004 ), ( vec2<f32>( ( p0_nodeVar300.x * ( f32(knobs.strength) / p0_nodeVar301 ) ), ( p0_nodeVar300.y * ( f32(knobs.strength) / p0_nodeVar301 ) ) ).x * 0.30000000000000004 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar303 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar304 = vec2<f32>( cos( p0_nodeVar303 ), sin( p0_nodeVar303 ) );
		p0_nodeVar305 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar306 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar305.x ), ( p0_nodeVar1.y - p0_nodeVar305.y ) );
		p0_nodeVar307 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar302 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar304.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar304.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.30000000000000004 ), ( vec2<f32>( ( p0_nodeVar306.x * ( f32(knobs.strength) / p0_nodeVar307 ) ), ( p0_nodeVar306.y * ( f32(knobs.strength) / p0_nodeVar307 ) ) ).y * 0.30000000000000004 ) ).y;

	} else {

		p0_nodeVar308 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar309 = vec2<f32>( cos( p0_nodeVar308 ), sin( p0_nodeVar308 ) );
		p0_nodeVar310 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar311 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar310.x ), ( p0_nodeVar1.y - p0_nodeVar310.y ) );
		p0_nodeVar312 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar302 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar309.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar309.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.30000000000000004 ), ( vec2<f32>( ( p0_nodeVar311.x * ( f32(knobs.strength) / p0_nodeVar312 ) ), ( p0_nodeVar311.y * ( f32(knobs.strength) / p0_nodeVar312 ) ) ).y * 0.30000000000000004 ) ).x;

	}

	p0_nodeVar313 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar291 ), ( p0_nodeVar1.y + p0_nodeVar302 ) ) );
	p0_nodeVar314 = step( 12.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar316 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar317 = vec2<f32>( cos( p0_nodeVar316 ), sin( p0_nodeVar316 ) );
		p0_nodeVar318 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar319 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar318.x ), ( p0_nodeVar1.y - p0_nodeVar318.y ) );
		p0_nodeVar320 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar315 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar317.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar317.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar319.x * ( f32(knobs.strength) / p0_nodeVar320 ) ), ( p0_nodeVar319.y * ( f32(knobs.strength) / p0_nodeVar320 ) ) ).x * 0.3666666666666667 ) ).y;

	} else {

		p0_nodeVar321 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar322 = vec2<f32>( cos( p0_nodeVar321 ), sin( p0_nodeVar321 ) );
		p0_nodeVar323 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar324 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar323.x ), ( p0_nodeVar1.y - p0_nodeVar323.y ) );
		p0_nodeVar325 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar315 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar322.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar322.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar324.x * ( f32(knobs.strength) / p0_nodeVar325 ) ), ( p0_nodeVar324.y * ( f32(knobs.strength) / p0_nodeVar325 ) ) ).x * 0.3666666666666667 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar327 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar328 = vec2<f32>( cos( p0_nodeVar327 ), sin( p0_nodeVar327 ) );
		p0_nodeVar329 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar330 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar329.x ), ( p0_nodeVar1.y - p0_nodeVar329.y ) );
		p0_nodeVar331 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar326 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar328.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar328.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar330.x * ( f32(knobs.strength) / p0_nodeVar331 ) ), ( p0_nodeVar330.y * ( f32(knobs.strength) / p0_nodeVar331 ) ) ).y * 0.3666666666666667 ) ).y;

	} else {

		p0_nodeVar332 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar333 = vec2<f32>( cos( p0_nodeVar332 ), sin( p0_nodeVar332 ) );
		p0_nodeVar334 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar335 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar334.x ), ( p0_nodeVar1.y - p0_nodeVar334.y ) );
		p0_nodeVar336 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar326 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar333.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar333.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.3666666666666667 ), ( vec2<f32>( ( p0_nodeVar335.x * ( f32(knobs.strength) / p0_nodeVar336 ) ), ( p0_nodeVar335.y * ( f32(knobs.strength) / p0_nodeVar336 ) ) ).y * 0.3666666666666667 ) ).x;

	}

	p0_nodeVar337 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar315 ), ( p0_nodeVar1.y + p0_nodeVar326 ) ) );
	p0_nodeVar338 = step( 13.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar340 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar341 = vec2<f32>( cos( p0_nodeVar340 ), sin( p0_nodeVar340 ) );
		p0_nodeVar342 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar343 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar342.x ), ( p0_nodeVar1.y - p0_nodeVar342.y ) );
		p0_nodeVar344 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar339 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar341.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar341.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar343.x * ( f32(knobs.strength) / p0_nodeVar344 ) ), ( p0_nodeVar343.y * ( f32(knobs.strength) / p0_nodeVar344 ) ) ).x * 0.43333333333333335 ) ).y;

	} else {

		p0_nodeVar345 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar346 = vec2<f32>( cos( p0_nodeVar345 ), sin( p0_nodeVar345 ) );
		p0_nodeVar347 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar348 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar347.x ), ( p0_nodeVar1.y - p0_nodeVar347.y ) );
		p0_nodeVar349 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar339 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar346.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar346.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar348.x * ( f32(knobs.strength) / p0_nodeVar349 ) ), ( p0_nodeVar348.y * ( f32(knobs.strength) / p0_nodeVar349 ) ) ).x * 0.43333333333333335 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar351 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar352 = vec2<f32>( cos( p0_nodeVar351 ), sin( p0_nodeVar351 ) );
		p0_nodeVar353 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar354 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar353.x ), ( p0_nodeVar1.y - p0_nodeVar353.y ) );
		p0_nodeVar355 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar350 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar352.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar352.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar354.x * ( f32(knobs.strength) / p0_nodeVar355 ) ), ( p0_nodeVar354.y * ( f32(knobs.strength) / p0_nodeVar355 ) ) ).y * 0.43333333333333335 ) ).y;

	} else {

		p0_nodeVar356 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar357 = vec2<f32>( cos( p0_nodeVar356 ), sin( p0_nodeVar356 ) );
		p0_nodeVar358 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar359 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar358.x ), ( p0_nodeVar1.y - p0_nodeVar358.y ) );
		p0_nodeVar360 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar350 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar357.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar357.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.43333333333333335 ), ( vec2<f32>( ( p0_nodeVar359.x * ( f32(knobs.strength) / p0_nodeVar360 ) ), ( p0_nodeVar359.y * ( f32(knobs.strength) / p0_nodeVar360 ) ) ).y * 0.43333333333333335 ) ).x;

	}

	p0_nodeVar361 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar339 ), ( p0_nodeVar1.y + p0_nodeVar350 ) ) );
	p0_nodeVar362 = step( 14.5, f32(knobs.samples) );

	if ( p0_nodeVar3 ) {

		p0_nodeVar364 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar365 = vec2<f32>( cos( p0_nodeVar364 ), sin( p0_nodeVar364 ) );
		p0_nodeVar366 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar367 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar366.x ), ( p0_nodeVar1.y - p0_nodeVar366.y ) );
		p0_nodeVar368 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar363 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar365.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar365.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.5 ), ( vec2<f32>( ( p0_nodeVar367.x * ( f32(knobs.strength) / p0_nodeVar368 ) ), ( p0_nodeVar367.y * ( f32(knobs.strength) / p0_nodeVar368 ) ) ).x * 0.5 ) ).y;

	} else {

		p0_nodeVar369 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar370 = vec2<f32>( cos( p0_nodeVar369 ), sin( p0_nodeVar369 ) );
		p0_nodeVar371 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar372 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar371.x ), ( p0_nodeVar1.y - p0_nodeVar371.y ) );
		p0_nodeVar373 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar363 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar370.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar370.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).x * 0.5 ), ( vec2<f32>( ( p0_nodeVar372.x * ( f32(knobs.strength) / p0_nodeVar373 ) ), ( p0_nodeVar372.y * ( f32(knobs.strength) / p0_nodeVar373 ) ) ).x * 0.5 ) ).x;

	}


	if ( p0_nodeVar3 ) {

		p0_nodeVar375 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar376 = vec2<f32>( cos( p0_nodeVar375 ), sin( p0_nodeVar375 ) );
		p0_nodeVar377 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar378 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar377.x ), ( p0_nodeVar1.y - p0_nodeVar377.y ) );
		p0_nodeVar379 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar374 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar376.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar376.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.5 ), ( vec2<f32>( ( p0_nodeVar378.x * ( f32(knobs.strength) / p0_nodeVar379 ) ), ( p0_nodeVar378.y * ( f32(knobs.strength) / p0_nodeVar379 ) ) ).y * 0.5 ) ).y;

	} else {

		p0_nodeVar380 = ( f32(knobs.angle) * 0.017453292519943295 );
		p0_nodeVar381 = vec2<f32>( cos( p0_nodeVar380 ), sin( p0_nodeVar380 ) );
		p0_nodeVar382 = vec2<f32>( f32(0.5), f32(0.5) );
		p0_nodeVar383 = vec2<f32>( ( p0_nodeVar1.x - p0_nodeVar382.x ), ( p0_nodeVar1.y - p0_nodeVar382.y ) );
		p0_nodeVar384 = min( f32(knobs.resolution.x), f32(knobs.resolution.y) );
		p0_nodeVar374 = vec2<f32>( ( vec2<f32>( ( p0_nodeVar381.x * ( f32(knobs.strength) / f32(knobs.resolution.x) ) ), ( p0_nodeVar381.y * ( f32(knobs.strength) / f32(knobs.resolution.y) ) ) ).y * 0.5 ), ( vec2<f32>( ( p0_nodeVar383.x * ( f32(knobs.strength) / p0_nodeVar384 ) ), ( p0_nodeVar383.y * ( f32(knobs.strength) / p0_nodeVar384 ) ) ).y * 0.5 ) ).x;

	}

	p0_nodeVar385 = picture_read( vec2<f32>( ( p0_nodeVar1.x + p0_nodeVar363 ), ( p0_nodeVar1.y + p0_nodeVar374 ) ) );
	p0_nodeVar386 = step( 15.5, f32(knobs.samples) );
	p0_nodeVar387 = max( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p0_nodeVar26 ) + p0_nodeVar50 ) + p0_nodeVar74 ) + p0_nodeVar98 ) + p0_nodeVar122 ) + p0_nodeVar146 ) + p0_nodeVar170 ) + p0_nodeVar194 ) + p0_nodeVar218 ) + p0_nodeVar242 ) + p0_nodeVar266 ) + p0_nodeVar290 ) + p0_nodeVar314 ) + p0_nodeVar338 ) + p0_nodeVar362 ) + p0_nodeVar386 ), 1.0 );
	p0_nodeVar388 = vec4<f32>( vec3<f32>( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar25.x * p0_nodeVar26 ) ) + ( p0_nodeVar49.x * p0_nodeVar50 ) ) + ( p0_nodeVar73.x * p0_nodeVar74 ) ) + ( p0_nodeVar97.x * p0_nodeVar98 ) ) + ( p0_nodeVar121.x * p0_nodeVar122 ) ) + ( p0_nodeVar145.x * p0_nodeVar146 ) ) + ( p0_nodeVar169.x * p0_nodeVar170 ) ) + ( p0_nodeVar193.x * p0_nodeVar194 ) ) + ( p0_nodeVar217.x * p0_nodeVar218 ) ) + ( p0_nodeVar241.x * p0_nodeVar242 ) ) + ( p0_nodeVar265.x * p0_nodeVar266 ) ) + ( p0_nodeVar289.x * p0_nodeVar290 ) ) + ( p0_nodeVar313.x * p0_nodeVar314 ) ) + ( p0_nodeVar337.x * p0_nodeVar338 ) ) + ( p0_nodeVar361.x * p0_nodeVar362 ) ) + ( p0_nodeVar385.x * p0_nodeVar386 ) ) / p0_nodeVar387 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar25.y * p0_nodeVar26 ) ) + ( p0_nodeVar49.y * p0_nodeVar50 ) ) + ( p0_nodeVar73.y * p0_nodeVar74 ) ) + ( p0_nodeVar97.y * p0_nodeVar98 ) ) + ( p0_nodeVar121.y * p0_nodeVar122 ) ) + ( p0_nodeVar145.y * p0_nodeVar146 ) ) + ( p0_nodeVar169.y * p0_nodeVar170 ) ) + ( p0_nodeVar193.y * p0_nodeVar194 ) ) + ( p0_nodeVar217.y * p0_nodeVar218 ) ) + ( p0_nodeVar241.y * p0_nodeVar242 ) ) + ( p0_nodeVar265.y * p0_nodeVar266 ) ) + ( p0_nodeVar289.y * p0_nodeVar290 ) ) + ( p0_nodeVar313.y * p0_nodeVar314 ) ) + ( p0_nodeVar337.y * p0_nodeVar338 ) ) + ( p0_nodeVar361.y * p0_nodeVar362 ) ) + ( p0_nodeVar385.y * p0_nodeVar386 ) ) / p0_nodeVar387 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar25.z * p0_nodeVar26 ) ) + ( p0_nodeVar49.z * p0_nodeVar50 ) ) + ( p0_nodeVar73.z * p0_nodeVar74 ) ) + ( p0_nodeVar97.z * p0_nodeVar98 ) ) + ( p0_nodeVar121.z * p0_nodeVar122 ) ) + ( p0_nodeVar145.z * p0_nodeVar146 ) ) + ( p0_nodeVar169.z * p0_nodeVar170 ) ) + ( p0_nodeVar193.z * p0_nodeVar194 ) ) + ( p0_nodeVar217.z * p0_nodeVar218 ) ) + ( p0_nodeVar241.z * p0_nodeVar242 ) ) + ( p0_nodeVar265.z * p0_nodeVar266 ) ) + ( p0_nodeVar289.z * p0_nodeVar290 ) ) + ( p0_nodeVar313.z * p0_nodeVar314 ) ) + ( p0_nodeVar337.z * p0_nodeVar338 ) ) + ( p0_nodeVar361.z * p0_nodeVar362 ) ) + ( p0_nodeVar385.z * p0_nodeVar386 ) ) / p0_nodeVar387 ) ), 1.0 );
	p0_nodeVar389 = vec3<f32>( p0_nodeVar388.x, p0_nodeVar388.y, p0_nodeVar388.z );
	p0_nodeVar390 = ( ( ( p0_nodeVar389.x * 0.2126 ) + ( p0_nodeVar389.y * 0.7152 ) ) + ( p0_nodeVar389.z * 0.0722 ) );
	p0_nodeVar391 = mix( vec3<f32>( p0_nodeVar390, p0_nodeVar390, p0_nodeVar390 ), p0_nodeVar389, f32(1.0) );
	p0_nodeVar392 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar391.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar391.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar391.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar391.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar391.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar391.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar391.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar391.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar391.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar388.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar392.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar392.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar393 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar393;

	// result

	p0_output.color = p0_nodeVar393;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

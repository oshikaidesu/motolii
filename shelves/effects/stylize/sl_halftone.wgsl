// Halftone: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
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
// --track@paperColor_x:Paper Color r,0,1,0.913098651791473,0.001
// --track@paperColor_y:Paper Color g,0,1,0.913098651791473,0.001
// --track@paperColor_z:Paper Color b,0,1,0.8713671191959567,0.001
// --track@paperGrain:Paper Grain,0,0.5,0.15,0.01
// --track@registration:Registration,0,5,0,0.1
// --track@inkCyan_x:Cyan Ink r,0,1,0,0.001
// --track@inkCyan_y:Cyan Ink g,0,1,0.4232676699760063,0.001
// --track@inkCyan_z:Cyan Ink b,0,1,0.8631572134510892,0.001
// --track@inkMagenta_x:Magenta Ink r,0,1,0.8387990117372213,0.001
// --track@inkMagenta_y:Magenta Ink g,0,1,0,0.001
// --track@inkMagenta_z:Magenta Ink b,0,1,0.26225065751888765,0.001
// --track@inkYellow_x:Yellow Ink r,0,1,1,0.001
// --track@inkYellow_y:Yellow Ink g,0,1,0.8879231178794776,0.001
// --track@inkYellow_z:Yellow Ink b,0,1,0,0.001
// --track@inkKey_x:Key Ink r,0,1,0.010329823026364548,0.001
// --track@inkKey_y:Key Ink g,0,1,0.010329823026364548,0.001
// --track@inkKey_z:Key Ink b,0,1,0.010329823026364548,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  shape: f32,
  spacing: f32,
  dotSize: f32,
  dotMin: f32,
  contrast: f32,
  softness: f32,
  dotGain: f32,
  dotMorph: f32,
  invertLuma: f32,
  gcr: f32,
  cyanAngle: f32,
  magentaAngle: f32,
  yellowAngle: f32,
  keyAngle: f32,
  paperColor: vec3<f32>,
  paperGrain: f32,
  registration: f32,
  inkCyan: vec3<f32>,
  inkMagenta: vec3<f32>,
  inkYellow: vec3<f32>,
  inkKey: vec3<f32>,
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
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec3<f32>;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec4<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec2<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : vec2<f32>;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : vec2<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : vec2<f32>;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec4<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : vec2<f32>;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : vec2<f32>;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : vec2<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : vec2<f32>;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec2<f32>;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : vec2<f32>;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : vec2<f32>;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : vec2<f32>;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : vec2<f32>;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : vec2<f32>;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : vec4<f32>;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : vec2<f32>;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : vec4<f32>;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : vec2<f32>;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : f32;
var<private> p0_nodeVar89 : vec2<f32>;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : f32;
var<private> p0_nodeVar95 : f32;
var<private> p0_nodeVar96 : vec2<f32>;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : f32;
var<private> p0_nodeVar99 : vec2<f32>;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : f32;
var<private> p0_nodeVar102 : vec4<f32>;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : vec2<f32>;
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : vec4<f32>;
var<private> p0_nodeVar108 : f32;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : vec2<f32>;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : vec2<f32>;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : f32;
var<private> p0_nodeVar119 : vec2<f32>;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : f32;
var<private> p0_nodeVar122 : vec2<f32>;
var<private> p0_nodeVar123 : f32;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : vec2<f32>;
var<private> p0_nodeVar126 : f32;
var<private> p0_nodeVar127 : vec4<f32>;
var<private> p0_nodeVar128 : f32;
var<private> p0_nodeVar129 : vec2<f32>;
var<private> p0_nodeVar130 : f32;
var<private> p0_nodeVar131 : vec4<f32>;
var<private> p0_nodeVar132 : f32;
var<private> p0_nodeVar133 : f32;
var<private> p0_nodeVar134 : f32;
var<private> p0_nodeVar135 : vec2<f32>;
var<private> p0_nodeVar136 : f32;
var<private> p0_nodeVar137 : f32;
var<private> p0_nodeVar138 : f32;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : f32;
var<private> p0_nodeVar141 : f32;
var<private> p0_nodeVar142 : f32;
var<private> p0_nodeVar143 : vec2<f32>;
var<private> p0_nodeVar144 : f32;
var<private> p0_nodeVar145 : f32;
var<private> p0_nodeVar146 : vec2<f32>;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : f32;
var<private> p0_nodeVar149 : vec2<f32>;
var<private> p0_nodeVar150 : vec4<f32>;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : vec2<f32>;
var<private> p0_nodeVar153 : vec4<f32>;
var<private> p0_nodeVar154 : f32;
var<private> p0_nodeVar155 : f32;
var<private> p0_nodeVar156 : f32;
var<private> p0_nodeVar157 : vec2<f32>;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : f32;
var<private> p0_nodeVar161 : vec2<f32>;
var<private> p0_nodeVar162 : f32;
var<private> p0_nodeVar163 : f32;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : vec2<f32>;
var<private> p0_nodeVar166 : f32;
var<private> p0_nodeVar167 : f32;
var<private> p0_nodeVar168 : vec2<f32>;
var<private> p0_nodeVar169 : f32;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : vec2<f32>;
var<private> p0_nodeVar172 : f32;
var<private> p0_nodeVar173 : vec4<f32>;
var<private> p0_nodeVar174 : f32;
var<private> p0_nodeVar175 : vec2<f32>;
var<private> p0_nodeVar176 : f32;
var<private> p0_nodeVar177 : vec4<f32>;
var<private> p0_nodeVar178 : f32;
var<private> p0_nodeVar179 : f32;
var<private> p0_nodeVar180 : f32;
var<private> p0_nodeVar181 : vec2<f32>;
var<private> p0_nodeVar182 : f32;
var<private> p0_nodeVar183 : f32;
var<private> p0_nodeVar184 : f32;
var<private> p0_nodeVar185 : vec2<f32>;
var<private> p0_nodeVar186 : f32;
var<private> p0_nodeVar187 : f32;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : vec2<f32>;
var<private> p0_nodeVar190 : f32;
var<private> p0_nodeVar191 : f32;
var<private> p0_nodeVar192 : vec2<f32>;
var<private> p0_nodeVar193 : f32;
var<private> p0_nodeVar194 : f32;
var<private> p0_nodeVar195 : vec2<f32>;
var<private> p0_nodeVar196 : vec4<f32>;
var<private> p0_nodeVar197 : f32;
var<private> p0_nodeVar198 : vec2<f32>;
var<private> p0_nodeVar199 : vec4<f32>;
var<private> p0_nodeVar200 : f32;
var<private> p0_nodeVar201 : f32;
var<private> p0_nodeVar202 : f32;
var<private> p0_nodeVar203 : vec2<f32>;
var<private> p0_nodeVar204 : f32;
var<private> p0_nodeVar205 : f32;
var<private> p0_nodeVar206 : f32;
var<private> p0_nodeVar207 : vec2<f32>;
var<private> p0_nodeVar208 : f32;
var<private> p0_nodeVar209 : f32;
var<private> p0_nodeVar210 : f32;
var<private> p0_nodeVar211 : vec2<f32>;
var<private> p0_nodeVar212 : f32;
var<private> p0_nodeVar213 : f32;
var<private> p0_nodeVar214 : vec2<f32>;
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
var<private> p0_nodeVar228 : vec3<f32>;
var<private> p0_nodeVar229 : vec3<f32>;
var<private> p0_nodeVar230 : f32;
var<private> p0_nodeVar231 : vec2<f32>;
var<private> p0_nodeVar232 : vec4<f32>;
var<private> p0_nodeVar233 : f32;
var<private> p0_nodeVar234 : vec2<f32>;
var<private> p0_nodeVar235 : vec4<f32>;
var<private> p0_nodeVar236 : f32;
var<private> p0_nodeVar237 : f32;
var<private> p0_nodeVar238 : f32;
var<private> p0_nodeVar239 : f32;
var<private> p0_nodeVar240 : vec2<f32>;
var<private> p0_nodeVar241 : f32;
var<private> p0_nodeVar242 : f32;
var<private> p0_nodeVar243 : f32;
var<private> p0_nodeVar244 : vec2<f32>;
var<private> p0_nodeVar245 : f32;
var<private> p0_nodeVar246 : f32;
var<private> p0_nodeVar247 : f32;
var<private> p0_nodeVar248 : vec2<f32>;
var<private> p0_nodeVar249 : f32;
var<private> p0_nodeVar250 : f32;
var<private> p0_nodeVar251 : vec2<f32>;
var<private> p0_nodeVar252 : f32;
var<private> p0_nodeVar253 : f32;
var<private> p0_nodeVar254 : vec2<f32>;
var<private> p0_nodeVar255 : f32;
var<private> p0_nodeVar256 : vec4<f32>;
var<private> p0_nodeVar257 : f32;
var<private> p0_nodeVar258 : vec2<f32>;
var<private> p0_nodeVar259 : f32;
var<private> p0_nodeVar260 : vec4<f32>;
var<private> p0_nodeVar261 : f32;
var<private> p0_nodeVar262 : f32;
var<private> p0_nodeVar263 : f32;
var<private> p0_nodeVar264 : vec2<f32>;
var<private> p0_nodeVar265 : f32;
var<private> p0_nodeVar266 : f32;
var<private> p0_nodeVar267 : f32;
var<private> p0_nodeVar268 : vec2<f32>;
var<private> p0_nodeVar269 : f32;
var<private> p0_nodeVar270 : f32;
var<private> p0_nodeVar271 : f32;
var<private> p0_nodeVar272 : vec2<f32>;
var<private> p0_nodeVar273 : f32;
var<private> p0_nodeVar274 : f32;
var<private> p0_nodeVar275 : vec2<f32>;
var<private> p0_nodeVar276 : f32;
var<private> p0_nodeVar277 : f32;
var<private> p0_nodeVar278 : vec2<f32>;
var<private> p0_nodeVar279 : vec4<f32>;
var<private> p0_nodeVar280 : f32;
var<private> p0_nodeVar281 : vec2<f32>;
var<private> p0_nodeVar282 : vec4<f32>;
var<private> p0_nodeVar283 : f32;
var<private> p0_nodeVar284 : f32;
var<private> p0_nodeVar285 : f32;
var<private> p0_nodeVar286 : vec2<f32>;
var<private> p0_nodeVar287 : f32;
var<private> p0_nodeVar288 : f32;
var<private> p0_nodeVar289 : f32;
var<private> p0_nodeVar290 : vec2<f32>;
var<private> p0_nodeVar291 : f32;
var<private> p0_nodeVar292 : f32;
var<private> p0_nodeVar293 : f32;
var<private> p0_nodeVar294 : vec2<f32>;
var<private> p0_nodeVar295 : f32;
var<private> p0_nodeVar296 : f32;
var<private> p0_nodeVar297 : vec2<f32>;
var<private> p0_nodeVar298 : f32;
var<private> p0_nodeVar299 : f32;
var<private> p0_nodeVar300 : vec2<f32>;
var<private> p0_nodeVar301 : f32;
var<private> p0_nodeVar302 : vec4<f32>;
var<private> p0_nodeVar303 : f32;
var<private> p0_nodeVar304 : vec2<f32>;
var<private> p0_nodeVar305 : f32;
var<private> p0_nodeVar306 : vec4<f32>;
var<private> p0_nodeVar307 : f32;
var<private> p0_nodeVar308 : f32;
var<private> p0_nodeVar309 : f32;
var<private> p0_nodeVar310 : vec2<f32>;
var<private> p0_nodeVar311 : f32;
var<private> p0_nodeVar312 : f32;
var<private> p0_nodeVar313 : f32;
var<private> p0_nodeVar314 : vec2<f32>;
var<private> p0_nodeVar315 : f32;
var<private> p0_nodeVar316 : f32;
var<private> p0_nodeVar317 : f32;
var<private> p0_nodeVar318 : vec2<f32>;
var<private> p0_nodeVar319 : f32;
var<private> p0_nodeVar320 : f32;
var<private> p0_nodeVar321 : vec2<f32>;
var<private> p0_nodeVar322 : f32;
var<private> p0_nodeVar323 : f32;
var<private> p0_nodeVar324 : vec2<f32>;
var<private> p0_nodeVar325 : f32;
var<private> p0_nodeVar326 : f32;
var<private> p0_nodeVar327 : vec4<f32>;
var<private> p0_nodeVar328 : f32;
var<private> p0_nodeVar329 : vec2<f32>;
var<private> p0_nodeVar330 : f32;
var<private> p0_nodeVar331 : f32;
var<private> p0_nodeVar332 : vec4<f32>;
var<private> p0_nodeVar333 : f32;
var<private> p0_nodeVar334 : f32;
var<private> p0_nodeVar335 : f32;
var<private> p0_nodeVar336 : vec2<f32>;
var<private> p0_nodeVar337 : f32;
var<private> p0_nodeVar338 : f32;
var<private> p0_nodeVar339 : f32;
var<private> p0_nodeVar340 : vec2<f32>;
var<private> p0_nodeVar341 : f32;
var<private> p0_nodeVar342 : f32;
var<private> p0_nodeVar343 : f32;
var<private> p0_nodeVar344 : vec2<f32>;
var<private> p0_nodeVar345 : f32;
var<private> p0_nodeVar346 : f32;
var<private> p0_nodeVar347 : vec2<f32>;
var<private> p0_nodeVar348 : f32;
var<private> p0_nodeVar349 : f32;
var<private> p0_nodeVar350 : vec2<f32>;
var<private> p0_nodeVar351 : f32;
var<private> p0_nodeVar352 : vec4<f32>;
var<private> p0_nodeVar353 : f32;
var<private> p0_nodeVar354 : vec2<f32>;
var<private> p0_nodeVar355 : f32;
var<private> p0_nodeVar356 : vec4<f32>;
var<private> p0_nodeVar357 : f32;
var<private> p0_nodeVar358 : f32;
var<private> p0_nodeVar359 : f32;
var<private> p0_nodeVar360 : vec2<f32>;
var<private> p0_nodeVar361 : f32;
var<private> p0_nodeVar362 : f32;
var<private> p0_nodeVar363 : f32;
var<private> p0_nodeVar364 : vec2<f32>;
var<private> p0_nodeVar365 : f32;
var<private> p0_nodeVar366 : f32;
var<private> p0_nodeVar367 : f32;
var<private> p0_nodeVar368 : vec2<f32>;
var<private> p0_nodeVar369 : f32;
var<private> p0_nodeVar370 : f32;
var<private> p0_nodeVar371 : vec2<f32>;
var<private> p0_nodeVar372 : f32;
var<private> p0_nodeVar373 : f32;
var<private> p0_nodeVar374 : vec2<f32>;
var<private> p0_nodeVar375 : vec4<f32>;
var<private> p0_nodeVar376 : f32;
var<private> p0_nodeVar377 : vec2<f32>;
var<private> p0_nodeVar378 : vec4<f32>;
var<private> p0_nodeVar379 : f32;
var<private> p0_nodeVar380 : f32;
var<private> p0_nodeVar381 : f32;
var<private> p0_nodeVar382 : vec2<f32>;
var<private> p0_nodeVar383 : f32;
var<private> p0_nodeVar384 : f32;
var<private> p0_nodeVar385 : f32;
var<private> p0_nodeVar386 : vec2<f32>;
var<private> p0_nodeVar387 : f32;
var<private> p0_nodeVar388 : f32;
var<private> p0_nodeVar389 : f32;
var<private> p0_nodeVar390 : vec2<f32>;
var<private> p0_nodeVar391 : f32;
var<private> p0_nodeVar392 : f32;
var<private> p0_nodeVar393 : vec2<f32>;
var<private> p0_nodeVar394 : f32;
var<private> p0_nodeVar395 : f32;
var<private> p0_nodeVar396 : vec2<f32>;
var<private> p0_nodeVar397 : f32;
var<private> p0_nodeVar398 : vec4<f32>;
var<private> p0_nodeVar399 : f32;
var<private> p0_nodeVar400 : vec2<f32>;
var<private> p0_nodeVar401 : f32;
var<private> p0_nodeVar402 : vec4<f32>;
var<private> p0_nodeVar403 : f32;
var<private> p0_nodeVar404 : f32;
var<private> p0_nodeVar405 : f32;
var<private> p0_nodeVar406 : vec2<f32>;
var<private> p0_nodeVar407 : f32;
var<private> p0_nodeVar408 : f32;
var<private> p0_nodeVar409 : f32;
var<private> p0_nodeVar410 : vec2<f32>;
var<private> p0_nodeVar411 : f32;
var<private> p0_nodeVar412 : f32;
var<private> p0_nodeVar413 : f32;
var<private> p0_nodeVar414 : vec2<f32>;
var<private> p0_nodeVar415 : f32;
var<private> p0_nodeVar416 : f32;
var<private> p0_nodeVar417 : vec2<f32>;
var<private> p0_nodeVar418 : f32;
var<private> p0_nodeVar419 : f32;
var<private> p0_nodeVar420 : vec2<f32>;
var<private> p0_nodeVar421 : vec4<f32>;
var<private> p0_nodeVar422 : f32;
var<private> p0_nodeVar423 : vec2<f32>;
var<private> p0_nodeVar424 : vec4<f32>;
var<private> p0_nodeVar425 : f32;
var<private> p0_nodeVar426 : f32;
var<private> p0_nodeVar427 : f32;
var<private> p0_nodeVar428 : vec2<f32>;
var<private> p0_nodeVar429 : f32;
var<private> p0_nodeVar430 : f32;
var<private> p0_nodeVar431 : f32;
var<private> p0_nodeVar432 : vec2<f32>;
var<private> p0_nodeVar433 : f32;
var<private> p0_nodeVar434 : f32;
var<private> p0_nodeVar435 : f32;
var<private> p0_nodeVar436 : vec2<f32>;
var<private> p0_nodeVar437 : f32;
var<private> p0_nodeVar438 : f32;
var<private> p0_nodeVar439 : vec2<f32>;
var<private> p0_nodeVar440 : f32;
var<private> p0_nodeVar441 : f32;
var<private> p0_nodeVar442 : f32;
var<private> p0_nodeVar443 : f32;
var<private> p0_nodeVar444 : f32;
var<private> p0_nodeVar445 : f32;
var<private> p0_nodeVar446 : f32;
var<private> p0_nodeVar447 : f32;
var<private> p0_nodeVar448 : f32;
var<private> p0_nodeVar449 : f32;
var<private> p0_nodeVar450 : f32;
var<private> p0_nodeVar451 : f32;
var<private> p0_nodeVar452 : f32;
var<private> p0_nodeVar453 : vec3<f32>;
var<private> p0_nodeVar454 : vec3<f32>;
var<private> p0_nodeVar455 : f32;
var<private> p0_nodeVar456 : vec2<f32>;
var<private> p0_nodeVar457 : vec4<f32>;
var<private> p0_nodeVar458 : f32;
var<private> p0_nodeVar459 : vec2<f32>;
var<private> p0_nodeVar460 : vec4<f32>;
var<private> p0_nodeVar461 : f32;
var<private> p0_nodeVar462 : f32;
var<private> p0_nodeVar463 : f32;
var<private> p0_nodeVar464 : f32;
var<private> p0_nodeVar465 : vec2<f32>;
var<private> p0_nodeVar466 : f32;
var<private> p0_nodeVar467 : f32;
var<private> p0_nodeVar468 : f32;
var<private> p0_nodeVar469 : vec2<f32>;
var<private> p0_nodeVar470 : f32;
var<private> p0_nodeVar471 : f32;
var<private> p0_nodeVar472 : f32;
var<private> p0_nodeVar473 : vec2<f32>;
var<private> p0_nodeVar474 : f32;
var<private> p0_nodeVar475 : f32;
var<private> p0_nodeVar476 : vec2<f32>;
var<private> p0_nodeVar477 : f32;
var<private> p0_nodeVar478 : f32;
var<private> p0_nodeVar479 : vec2<f32>;
var<private> p0_nodeVar480 : f32;
var<private> p0_nodeVar481 : vec4<f32>;
var<private> p0_nodeVar482 : f32;
var<private> p0_nodeVar483 : vec2<f32>;
var<private> p0_nodeVar484 : f32;
var<private> p0_nodeVar485 : vec4<f32>;
var<private> p0_nodeVar486 : f32;
var<private> p0_nodeVar487 : f32;
var<private> p0_nodeVar488 : f32;
var<private> p0_nodeVar489 : vec2<f32>;
var<private> p0_nodeVar490 : f32;
var<private> p0_nodeVar491 : f32;
var<private> p0_nodeVar492 : f32;
var<private> p0_nodeVar493 : vec2<f32>;
var<private> p0_nodeVar494 : f32;
var<private> p0_nodeVar495 : f32;
var<private> p0_nodeVar496 : f32;
var<private> p0_nodeVar497 : vec2<f32>;
var<private> p0_nodeVar498 : f32;
var<private> p0_nodeVar499 : f32;
var<private> p0_nodeVar500 : vec2<f32>;
var<private> p0_nodeVar501 : f32;
var<private> p0_nodeVar502 : f32;
var<private> p0_nodeVar503 : vec2<f32>;
var<private> p0_nodeVar504 : vec4<f32>;
var<private> p0_nodeVar505 : f32;
var<private> p0_nodeVar506 : vec2<f32>;
var<private> p0_nodeVar507 : vec4<f32>;
var<private> p0_nodeVar508 : f32;
var<private> p0_nodeVar509 : f32;
var<private> p0_nodeVar510 : f32;
var<private> p0_nodeVar511 : vec2<f32>;
var<private> p0_nodeVar512 : f32;
var<private> p0_nodeVar513 : f32;
var<private> p0_nodeVar514 : f32;
var<private> p0_nodeVar515 : vec2<f32>;
var<private> p0_nodeVar516 : f32;
var<private> p0_nodeVar517 : f32;
var<private> p0_nodeVar518 : f32;
var<private> p0_nodeVar519 : vec2<f32>;
var<private> p0_nodeVar520 : f32;
var<private> p0_nodeVar521 : f32;
var<private> p0_nodeVar522 : vec2<f32>;
var<private> p0_nodeVar523 : f32;
var<private> p0_nodeVar524 : f32;
var<private> p0_nodeVar525 : vec2<f32>;
var<private> p0_nodeVar526 : f32;
var<private> p0_nodeVar527 : vec4<f32>;
var<private> p0_nodeVar528 : f32;
var<private> p0_nodeVar529 : vec2<f32>;
var<private> p0_nodeVar530 : f32;
var<private> p0_nodeVar531 : vec4<f32>;
var<private> p0_nodeVar532 : f32;
var<private> p0_nodeVar533 : f32;
var<private> p0_nodeVar534 : f32;
var<private> p0_nodeVar535 : vec2<f32>;
var<private> p0_nodeVar536 : f32;
var<private> p0_nodeVar537 : f32;
var<private> p0_nodeVar538 : f32;
var<private> p0_nodeVar539 : vec2<f32>;
var<private> p0_nodeVar540 : f32;
var<private> p0_nodeVar541 : f32;
var<private> p0_nodeVar542 : f32;
var<private> p0_nodeVar543 : vec2<f32>;
var<private> p0_nodeVar544 : f32;
var<private> p0_nodeVar545 : f32;
var<private> p0_nodeVar546 : vec2<f32>;
var<private> p0_nodeVar547 : f32;
var<private> p0_nodeVar548 : f32;
var<private> p0_nodeVar549 : vec2<f32>;
var<private> p0_nodeVar550 : f32;
var<private> p0_nodeVar551 : f32;
var<private> p0_nodeVar552 : vec4<f32>;
var<private> p0_nodeVar553 : f32;
var<private> p0_nodeVar554 : vec2<f32>;
var<private> p0_nodeVar555 : f32;
var<private> p0_nodeVar556 : f32;
var<private> p0_nodeVar557 : vec4<f32>;
var<private> p0_nodeVar558 : f32;
var<private> p0_nodeVar559 : f32;
var<private> p0_nodeVar560 : f32;
var<private> p0_nodeVar561 : vec2<f32>;
var<private> p0_nodeVar562 : f32;
var<private> p0_nodeVar563 : f32;
var<private> p0_nodeVar564 : f32;
var<private> p0_nodeVar565 : vec2<f32>;
var<private> p0_nodeVar566 : f32;
var<private> p0_nodeVar567 : f32;
var<private> p0_nodeVar568 : f32;
var<private> p0_nodeVar569 : vec2<f32>;
var<private> p0_nodeVar570 : f32;
var<private> p0_nodeVar571 : f32;
var<private> p0_nodeVar572 : vec2<f32>;
var<private> p0_nodeVar573 : f32;
var<private> p0_nodeVar574 : f32;
var<private> p0_nodeVar575 : vec2<f32>;
var<private> p0_nodeVar576 : f32;
var<private> p0_nodeVar577 : vec4<f32>;
var<private> p0_nodeVar578 : f32;
var<private> p0_nodeVar579 : vec2<f32>;
var<private> p0_nodeVar580 : f32;
var<private> p0_nodeVar581 : vec4<f32>;
var<private> p0_nodeVar582 : f32;
var<private> p0_nodeVar583 : f32;
var<private> p0_nodeVar584 : f32;
var<private> p0_nodeVar585 : vec2<f32>;
var<private> p0_nodeVar586 : f32;
var<private> p0_nodeVar587 : f32;
var<private> p0_nodeVar588 : f32;
var<private> p0_nodeVar589 : vec2<f32>;
var<private> p0_nodeVar590 : f32;
var<private> p0_nodeVar591 : f32;
var<private> p0_nodeVar592 : f32;
var<private> p0_nodeVar593 : vec2<f32>;
var<private> p0_nodeVar594 : f32;
var<private> p0_nodeVar595 : f32;
var<private> p0_nodeVar596 : vec2<f32>;
var<private> p0_nodeVar597 : f32;
var<private> p0_nodeVar598 : f32;
var<private> p0_nodeVar599 : vec2<f32>;
var<private> p0_nodeVar600 : vec4<f32>;
var<private> p0_nodeVar601 : f32;
var<private> p0_nodeVar602 : vec2<f32>;
var<private> p0_nodeVar603 : vec4<f32>;
var<private> p0_nodeVar604 : f32;
var<private> p0_nodeVar605 : f32;
var<private> p0_nodeVar606 : f32;
var<private> p0_nodeVar607 : vec2<f32>;
var<private> p0_nodeVar608 : f32;
var<private> p0_nodeVar609 : f32;
var<private> p0_nodeVar610 : f32;
var<private> p0_nodeVar611 : vec2<f32>;
var<private> p0_nodeVar612 : f32;
var<private> p0_nodeVar613 : f32;
var<private> p0_nodeVar614 : f32;
var<private> p0_nodeVar615 : vec2<f32>;
var<private> p0_nodeVar616 : f32;
var<private> p0_nodeVar617 : f32;
var<private> p0_nodeVar618 : vec2<f32>;
var<private> p0_nodeVar619 : f32;
var<private> p0_nodeVar620 : f32;
var<private> p0_nodeVar621 : vec2<f32>;
var<private> p0_nodeVar622 : f32;
var<private> p0_nodeVar623 : vec4<f32>;
var<private> p0_nodeVar624 : f32;
var<private> p0_nodeVar625 : vec2<f32>;
var<private> p0_nodeVar626 : f32;
var<private> p0_nodeVar627 : vec4<f32>;
var<private> p0_nodeVar628 : f32;
var<private> p0_nodeVar629 : f32;
var<private> p0_nodeVar630 : f32;
var<private> p0_nodeVar631 : vec2<f32>;
var<private> p0_nodeVar632 : f32;
var<private> p0_nodeVar633 : f32;
var<private> p0_nodeVar634 : f32;
var<private> p0_nodeVar635 : vec2<f32>;
var<private> p0_nodeVar636 : f32;
var<private> p0_nodeVar637 : f32;
var<private> p0_nodeVar638 : f32;
var<private> p0_nodeVar639 : vec2<f32>;
var<private> p0_nodeVar640 : f32;
var<private> p0_nodeVar641 : f32;
var<private> p0_nodeVar642 : vec2<f32>;
var<private> p0_nodeVar643 : f32;
var<private> p0_nodeVar644 : f32;
var<private> p0_nodeVar645 : vec2<f32>;
var<private> p0_nodeVar646 : vec4<f32>;
var<private> p0_nodeVar647 : f32;
var<private> p0_nodeVar648 : vec2<f32>;
var<private> p0_nodeVar649 : vec4<f32>;
var<private> p0_nodeVar650 : f32;
var<private> p0_nodeVar651 : f32;
var<private> p0_nodeVar652 : f32;
var<private> p0_nodeVar653 : vec2<f32>;
var<private> p0_nodeVar654 : f32;
var<private> p0_nodeVar655 : f32;
var<private> p0_nodeVar656 : f32;
var<private> p0_nodeVar657 : vec2<f32>;
var<private> p0_nodeVar658 : f32;
var<private> p0_nodeVar659 : f32;
var<private> p0_nodeVar660 : f32;
var<private> p0_nodeVar661 : vec2<f32>;
var<private> p0_nodeVar662 : f32;
var<private> p0_nodeVar663 : f32;
var<private> p0_nodeVar664 : vec2<f32>;
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
var<private> p0_nodeVar678 : vec3<f32>;
var<private> p0_nodeVar679 : vec3<f32>;
var<private> p0_nodeVar680 : f32;
var<private> p0_nodeVar681 : vec2<f32>;
var<private> p0_nodeVar682 : vec4<f32>;
var<private> p0_nodeVar683 : vec2<f32>;
var<private> p0_nodeVar684 : vec4<f32>;
var<private> p0_nodeVar685 : f32;
var<private> p0_nodeVar686 : f32;
var<private> p0_nodeVar687 : f32;
var<private> p0_nodeVar688 : vec2<f32>;
var<private> p0_nodeVar689 : f32;
var<private> p0_nodeVar690 : f32;
var<private> p0_nodeVar691 : f32;
var<private> p0_nodeVar692 : vec2<f32>;
var<private> p0_nodeVar693 : f32;
var<private> p0_nodeVar694 : f32;
var<private> p0_nodeVar695 : f32;
var<private> p0_nodeVar696 : vec2<f32>;
var<private> p0_nodeVar697 : f32;
var<private> p0_nodeVar698 : f32;
var<private> p0_nodeVar699 : vec2<f32>;
var<private> p0_nodeVar700 : f32;
var<private> p0_nodeVar701 : f32;
var<private> p0_nodeVar702 : vec2<f32>;
var<private> p0_nodeVar703 : f32;
var<private> p0_nodeVar704 : vec4<f32>;
var<private> p0_nodeVar705 : vec2<f32>;
var<private> p0_nodeVar706 : f32;
var<private> p0_nodeVar707 : vec4<f32>;
var<private> p0_nodeVar708 : f32;
var<private> p0_nodeVar709 : f32;
var<private> p0_nodeVar710 : vec2<f32>;
var<private> p0_nodeVar711 : f32;
var<private> p0_nodeVar712 : f32;
var<private> p0_nodeVar713 : f32;
var<private> p0_nodeVar714 : vec2<f32>;
var<private> p0_nodeVar715 : f32;
var<private> p0_nodeVar716 : f32;
var<private> p0_nodeVar717 : f32;
var<private> p0_nodeVar718 : vec2<f32>;
var<private> p0_nodeVar719 : f32;
var<private> p0_nodeVar720 : f32;
var<private> p0_nodeVar721 : vec2<f32>;
var<private> p0_nodeVar722 : f32;
var<private> p0_nodeVar723 : f32;
var<private> p0_nodeVar724 : vec2<f32>;
var<private> p0_nodeVar725 : vec4<f32>;
var<private> p0_nodeVar726 : vec2<f32>;
var<private> p0_nodeVar727 : vec4<f32>;
var<private> p0_nodeVar728 : f32;
var<private> p0_nodeVar729 : f32;
var<private> p0_nodeVar730 : vec2<f32>;
var<private> p0_nodeVar731 : f32;
var<private> p0_nodeVar732 : f32;
var<private> p0_nodeVar733 : f32;
var<private> p0_nodeVar734 : vec2<f32>;
var<private> p0_nodeVar735 : f32;
var<private> p0_nodeVar736 : f32;
var<private> p0_nodeVar737 : f32;
var<private> p0_nodeVar738 : vec2<f32>;
var<private> p0_nodeVar739 : f32;
var<private> p0_nodeVar740 : f32;
var<private> p0_nodeVar741 : vec2<f32>;
var<private> p0_nodeVar742 : f32;
var<private> p0_nodeVar743 : f32;
var<private> p0_nodeVar744 : vec2<f32>;
var<private> p0_nodeVar745 : f32;
var<private> p0_nodeVar746 : vec4<f32>;
var<private> p0_nodeVar747 : vec2<f32>;
var<private> p0_nodeVar748 : f32;
var<private> p0_nodeVar749 : vec4<f32>;
var<private> p0_nodeVar750 : f32;
var<private> p0_nodeVar751 : f32;
var<private> p0_nodeVar752 : vec2<f32>;
var<private> p0_nodeVar753 : f32;
var<private> p0_nodeVar754 : f32;
var<private> p0_nodeVar755 : f32;
var<private> p0_nodeVar756 : vec2<f32>;
var<private> p0_nodeVar757 : f32;
var<private> p0_nodeVar758 : f32;
var<private> p0_nodeVar759 : f32;
var<private> p0_nodeVar760 : vec2<f32>;
var<private> p0_nodeVar761 : f32;
var<private> p0_nodeVar762 : f32;
var<private> p0_nodeVar763 : vec2<f32>;
var<private> p0_nodeVar764 : f32;
var<private> p0_nodeVar765 : f32;
var<private> p0_nodeVar766 : vec2<f32>;
var<private> p0_nodeVar767 : f32;
var<private> p0_nodeVar768 : f32;
var<private> p0_nodeVar769 : vec4<f32>;
var<private> p0_nodeVar770 : vec2<f32>;
var<private> p0_nodeVar771 : f32;
var<private> p0_nodeVar772 : f32;
var<private> p0_nodeVar773 : vec4<f32>;
var<private> p0_nodeVar774 : f32;
var<private> p0_nodeVar775 : f32;
var<private> p0_nodeVar776 : vec2<f32>;
var<private> p0_nodeVar777 : f32;
var<private> p0_nodeVar778 : f32;
var<private> p0_nodeVar779 : f32;
var<private> p0_nodeVar780 : vec2<f32>;
var<private> p0_nodeVar781 : f32;
var<private> p0_nodeVar782 : f32;
var<private> p0_nodeVar783 : f32;
var<private> p0_nodeVar784 : vec2<f32>;
var<private> p0_nodeVar785 : f32;
var<private> p0_nodeVar786 : f32;
var<private> p0_nodeVar787 : vec2<f32>;
var<private> p0_nodeVar788 : f32;
var<private> p0_nodeVar789 : f32;
var<private> p0_nodeVar790 : vec2<f32>;
var<private> p0_nodeVar791 : f32;
var<private> p0_nodeVar792 : vec4<f32>;
var<private> p0_nodeVar793 : vec2<f32>;
var<private> p0_nodeVar794 : f32;
var<private> p0_nodeVar795 : vec4<f32>;
var<private> p0_nodeVar796 : f32;
var<private> p0_nodeVar797 : f32;
var<private> p0_nodeVar798 : vec2<f32>;
var<private> p0_nodeVar799 : f32;
var<private> p0_nodeVar800 : f32;
var<private> p0_nodeVar801 : f32;
var<private> p0_nodeVar802 : vec2<f32>;
var<private> p0_nodeVar803 : f32;
var<private> p0_nodeVar804 : f32;
var<private> p0_nodeVar805 : f32;
var<private> p0_nodeVar806 : vec2<f32>;
var<private> p0_nodeVar807 : f32;
var<private> p0_nodeVar808 : f32;
var<private> p0_nodeVar809 : vec2<f32>;
var<private> p0_nodeVar810 : f32;
var<private> p0_nodeVar811 : f32;
var<private> p0_nodeVar812 : vec2<f32>;
var<private> p0_nodeVar813 : vec4<f32>;
var<private> p0_nodeVar814 : vec2<f32>;
var<private> p0_nodeVar815 : vec4<f32>;
var<private> p0_nodeVar816 : f32;
var<private> p0_nodeVar817 : f32;
var<private> p0_nodeVar818 : vec2<f32>;
var<private> p0_nodeVar819 : f32;
var<private> p0_nodeVar820 : f32;
var<private> p0_nodeVar821 : f32;
var<private> p0_nodeVar822 : vec2<f32>;
var<private> p0_nodeVar823 : f32;
var<private> p0_nodeVar824 : f32;
var<private> p0_nodeVar825 : f32;
var<private> p0_nodeVar826 : vec2<f32>;
var<private> p0_nodeVar827 : f32;
var<private> p0_nodeVar828 : f32;
var<private> p0_nodeVar829 : vec2<f32>;
var<private> p0_nodeVar830 : f32;
var<private> p0_nodeVar831 : f32;
var<private> p0_nodeVar832 : vec2<f32>;
var<private> p0_nodeVar833 : f32;
var<private> p0_nodeVar834 : vec4<f32>;
var<private> p0_nodeVar835 : vec2<f32>;
var<private> p0_nodeVar836 : f32;
var<private> p0_nodeVar837 : vec4<f32>;
var<private> p0_nodeVar838 : f32;
var<private> p0_nodeVar839 : f32;
var<private> p0_nodeVar840 : vec2<f32>;
var<private> p0_nodeVar841 : f32;
var<private> p0_nodeVar842 : f32;
var<private> p0_nodeVar843 : f32;
var<private> p0_nodeVar844 : vec2<f32>;
var<private> p0_nodeVar845 : f32;
var<private> p0_nodeVar846 : f32;
var<private> p0_nodeVar847 : f32;
var<private> p0_nodeVar848 : vec2<f32>;
var<private> p0_nodeVar849 : f32;
var<private> p0_nodeVar850 : f32;
var<private> p0_nodeVar851 : vec2<f32>;
var<private> p0_nodeVar852 : f32;
var<private> p0_nodeVar853 : f32;
var<private> p0_nodeVar854 : vec2<f32>;
var<private> p0_nodeVar855 : vec4<f32>;
var<private> p0_nodeVar856 : vec2<f32>;
var<private> p0_nodeVar857 : vec4<f32>;
var<private> p0_nodeVar858 : f32;
var<private> p0_nodeVar859 : f32;
var<private> p0_nodeVar860 : vec2<f32>;
var<private> p0_nodeVar861 : f32;
var<private> p0_nodeVar862 : f32;
var<private> p0_nodeVar863 : f32;
var<private> p0_nodeVar864 : vec2<f32>;
var<private> p0_nodeVar865 : f32;
var<private> p0_nodeVar866 : f32;
var<private> p0_nodeVar867 : f32;
var<private> p0_nodeVar868 : vec2<f32>;
var<private> p0_nodeVar869 : f32;
var<private> p0_nodeVar870 : f32;
var<private> p0_nodeVar871 : vec2<f32>;
var<private> p0_nodeVar872 : f32;
var<private> p0_nodeVar873 : f32;
var<private> p0_nodeVar874 : f32;
var<private> p0_nodeVar875 : f32;
var<private> p0_nodeVar876 : f32;
var<private> p0_nodeVar877 : f32;
var<private> p0_nodeVar878 : f32;
var<private> p0_nodeVar879 : f32;
var<private> p0_nodeVar880 : f32;
var<private> p0_nodeVar881 : f32;
var<private> p0_nodeVar882 : f32;
var<private> p0_nodeVar883 : f32;
var<private> p0_nodeVar884 : f32;
var<private> p0_nodeVar885 : vec3<f32>;
var<private> p0_nodeVar886 : vec3<f32>;
var<private> p0_nodeVar887 : vec4<f32>;
var<private> p0_nodeVar888 : vec3<f32>;
var<private> p0_nodeVar889 : f32;
var<private> p0_nodeVar890 : vec3<f32>;
var<private> p0_nodeVar891 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar892 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar3 = ( ( fract( ( sin( dot( ( p0_nodeVar1 * p0_nodeVar2 ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * f32(knobs.paperGrain) );
	p0_nodeVar4 = vec3<f32>( clamp( ( f32(knobs.paperColor.x) + p0_nodeVar3 ), 0.0, 1.0 ), clamp( ( f32(knobs.paperColor.y) + p0_nodeVar3 ), 0.0, 1.0 ), clamp( ( f32(knobs.paperColor.z) + p0_nodeVar3 ), 0.0, 1.0 ) );

	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar6 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar7 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar6.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar8 = ( ( 1.0 - max( max( p0_nodeVar7.x, p0_nodeVar7.y ), p0_nodeVar7.z ) ) * f32(knobs.gcr) );
		p0_nodeVar5 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar7.x ) - p0_nodeVar8 ) / max( ( 1.0 - p0_nodeVar8 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar9 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar10 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar9.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar11 = ( ( 1.0 - max( max( p0_nodeVar10.x, p0_nodeVar10.y ), p0_nodeVar10.z ) ) * f32(knobs.gcr) );
		p0_nodeVar5 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar10.x ) - p0_nodeVar11 ) / max( ( 1.0 - p0_nodeVar11 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar12 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar5 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );
	p0_nodeVar13 = max( 0.5, ( ( f32(knobs.softness) * f32(knobs.spacing) ) * 0.3 ) );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar15 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar16 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar15.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar15.y ) );
		p0_nodeVar17 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar15.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar15.x ) );
		p0_nodeVar14 = length( vec2<f32>( ( p0_nodeVar16 - ( ( floor( ( ( p0_nodeVar16 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar17 - ( ( floor( ( ( p0_nodeVar17 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar19 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar20 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar19.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar19.y ) );
			p0_nodeVar21 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar19.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar19.x ) );
			p0_nodeVar18 = max( abs( ( p0_nodeVar20 - ( ( floor( ( ( p0_nodeVar20 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar21 - ( ( floor( ( ( p0_nodeVar21 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar23 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar24 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar23.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar23.y ) );
				p0_nodeVar25 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar23.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar23.x ) );
				p0_nodeVar22 = ( abs( ( p0_nodeVar24 - ( ( floor( ( ( p0_nodeVar24 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar25 - ( ( floor( ( ( p0_nodeVar25 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar26 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar27 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar26.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar26.x ) );
				p0_nodeVar22 = abs( ( p0_nodeVar27 - ( ( floor( ( ( p0_nodeVar27 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar18 = p0_nodeVar22;

		}

		p0_nodeVar14 = p0_nodeVar18;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar29 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar30 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar31 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar30 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar30 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar29.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar32 = ( ( 1.0 - max( max( p0_nodeVar31.x, p0_nodeVar31.y ), p0_nodeVar31.z ) ) * f32(knobs.gcr) );
		p0_nodeVar28 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar31.x ) - p0_nodeVar32 ) / max( ( 1.0 - p0_nodeVar32 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar33 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar34 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar35 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar34 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar34 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar33.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar36 = ( ( 1.0 - max( max( p0_nodeVar35.x, p0_nodeVar35.y ), p0_nodeVar35.z ) ) * f32(knobs.gcr) );
		p0_nodeVar28 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar35.x ) - p0_nodeVar36 ) / max( ( 1.0 - p0_nodeVar36 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar37 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar28 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar39 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar40 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar39.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar39.y ) );
		p0_nodeVar41 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar39.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar39.x ) );
		p0_nodeVar38 = length( vec2<f32>( ( p0_nodeVar40 - ( floor( ( ( p0_nodeVar40 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar41 - ( ( floor( ( ( p0_nodeVar41 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar43 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar44 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar43.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar43.y ) );
			p0_nodeVar45 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar43.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar43.x ) );
			p0_nodeVar42 = max( abs( ( p0_nodeVar44 - ( floor( ( ( p0_nodeVar44 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar45 - ( ( floor( ( ( p0_nodeVar45 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar47 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar48 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar47.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar47.y ) );
				p0_nodeVar49 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar47.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar47.x ) );
				p0_nodeVar46 = ( abs( ( p0_nodeVar48 - ( floor( ( ( p0_nodeVar48 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar49 - ( ( floor( ( ( p0_nodeVar49 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar50 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar51 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar50.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar50.x ) );
				p0_nodeVar46 = abs( ( p0_nodeVar51 - ( ( floor( ( ( p0_nodeVar51 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar42 = p0_nodeVar46;

		}

		p0_nodeVar38 = p0_nodeVar42;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar53 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar54 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar53.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar55 = ( ( 1.0 - max( max( p0_nodeVar54.x, p0_nodeVar54.y ), p0_nodeVar54.z ) ) * f32(knobs.gcr) );
		p0_nodeVar52 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar54.x ) - p0_nodeVar55 ) / max( ( 1.0 - p0_nodeVar55 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar56 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar57 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar56.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar58 = ( ( 1.0 - max( max( p0_nodeVar57.x, p0_nodeVar57.y ), p0_nodeVar57.z ) ) * f32(knobs.gcr) );
		p0_nodeVar52 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar57.x ) - p0_nodeVar58 ) / max( ( 1.0 - p0_nodeVar58 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar59 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar52 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar61 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar62 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar61.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar61.y ) );
		p0_nodeVar63 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar61.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar61.x ) );
		p0_nodeVar60 = length( vec2<f32>( ( p0_nodeVar62 - ( ( floor( ( ( p0_nodeVar62 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar63 - ( ( floor( ( ( p0_nodeVar63 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar65 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar66 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar65.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar65.y ) );
			p0_nodeVar67 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar65.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar65.x ) );
			p0_nodeVar64 = max( abs( ( p0_nodeVar66 - ( ( floor( ( ( p0_nodeVar66 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar67 - ( ( floor( ( ( p0_nodeVar67 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar69 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar70 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar69.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar69.y ) );
				p0_nodeVar71 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar69.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar69.x ) );
				p0_nodeVar68 = ( abs( ( p0_nodeVar70 - ( ( floor( ( ( p0_nodeVar70 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar71 - ( ( floor( ( ( p0_nodeVar71 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar72 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar73 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar72.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar72.x ) );
				p0_nodeVar68 = abs( ( p0_nodeVar73 - ( ( floor( ( ( p0_nodeVar73 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar64 = p0_nodeVar68;

		}

		p0_nodeVar60 = p0_nodeVar64;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar75 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar76 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar77 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar76 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar75.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar76 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar78 = ( ( 1.0 - max( max( p0_nodeVar77.x, p0_nodeVar77.y ), p0_nodeVar77.z ) ) * f32(knobs.gcr) );
		p0_nodeVar74 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar77.x ) - p0_nodeVar78 ) / max( ( 1.0 - p0_nodeVar78 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar79 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar80 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar81 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar80 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar79.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar80 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar82 = ( ( 1.0 - max( max( p0_nodeVar81.x, p0_nodeVar81.y ), p0_nodeVar81.z ) ) * f32(knobs.gcr) );
		p0_nodeVar74 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar81.x ) - p0_nodeVar82 ) / max( ( 1.0 - p0_nodeVar82 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar83 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar74 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar85 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar86 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar85.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar85.y ) );
		p0_nodeVar87 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar85.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar85.x ) );
		p0_nodeVar84 = length( vec2<f32>( ( p0_nodeVar86 - ( ( floor( ( ( p0_nodeVar86 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar87 - ( floor( ( ( p0_nodeVar87 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar89 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar90 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar89.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar89.y ) );
			p0_nodeVar91 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar89.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar89.x ) );
			p0_nodeVar88 = max( abs( ( p0_nodeVar90 - ( ( floor( ( ( p0_nodeVar90 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar91 - ( floor( ( ( p0_nodeVar91 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar93 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar94 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar93.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar93.y ) );
				p0_nodeVar95 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar93.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar93.x ) );
				p0_nodeVar92 = ( abs( ( p0_nodeVar94 - ( ( floor( ( ( p0_nodeVar94 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar95 - ( floor( ( ( p0_nodeVar95 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar96 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar97 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar96.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar96.x ) );
				p0_nodeVar92 = abs( ( p0_nodeVar97 - ( floor( ( ( p0_nodeVar97 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar88 = p0_nodeVar92;

		}

		p0_nodeVar84 = p0_nodeVar88;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar99 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar100 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar99.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar99.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar101 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar99.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar99.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar102 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar100 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar101 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar100 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar101 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar103 = ( ( 1.0 - max( max( p0_nodeVar102.x, p0_nodeVar102.y ), p0_nodeVar102.z ) ) * f32(knobs.gcr) );
		p0_nodeVar98 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar102.x ) - p0_nodeVar103 ) / max( ( 1.0 - p0_nodeVar103 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar104 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar105 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar104.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar104.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar106 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar104.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar104.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar107 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar105 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar106 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar105 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar106 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar108 = ( ( 1.0 - max( max( p0_nodeVar107.x, p0_nodeVar107.y ), p0_nodeVar107.z ) ) * f32(knobs.gcr) );
		p0_nodeVar98 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar107.x ) - p0_nodeVar108 ) / max( ( 1.0 - p0_nodeVar108 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar109 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar98 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar111 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar112 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar111.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar111.y ) );
		p0_nodeVar113 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar111.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar111.x ) );
		p0_nodeVar110 = length( vec2<f32>( ( p0_nodeVar112 - ( floor( ( ( p0_nodeVar112 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar113 - ( floor( ( ( p0_nodeVar113 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar115 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar116 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar115.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar115.y ) );
			p0_nodeVar117 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar115.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar115.x ) );
			p0_nodeVar114 = max( abs( ( p0_nodeVar116 - ( floor( ( ( p0_nodeVar116 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar117 - ( floor( ( ( p0_nodeVar117 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar119 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar120 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar119.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar119.y ) );
				p0_nodeVar121 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar119.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar119.x ) );
				p0_nodeVar118 = ( abs( ( p0_nodeVar120 - ( floor( ( ( p0_nodeVar120 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar121 - ( floor( ( ( p0_nodeVar121 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar122 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar123 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar122.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar122.x ) );
				p0_nodeVar118 = abs( ( p0_nodeVar123 - ( floor( ( ( p0_nodeVar123 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar114 = p0_nodeVar118;

		}

		p0_nodeVar110 = p0_nodeVar114;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar125 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar126 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar127 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar126 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar125.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar126 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar128 = ( ( 1.0 - max( max( p0_nodeVar127.x, p0_nodeVar127.y ), p0_nodeVar127.z ) ) * f32(knobs.gcr) );
		p0_nodeVar124 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar127.x ) - p0_nodeVar128 ) / max( ( 1.0 - p0_nodeVar128 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar129 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar130 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar131 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar130 ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar129.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar130 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar132 = ( ( 1.0 - max( max( p0_nodeVar131.x, p0_nodeVar131.y ), p0_nodeVar131.z ) ) * f32(knobs.gcr) );
		p0_nodeVar124 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar131.x ) - p0_nodeVar132 ) / max( ( 1.0 - p0_nodeVar132 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar133 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar124 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar135 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar136 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar135.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar135.y ) );
		p0_nodeVar137 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar135.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar135.x ) );
		p0_nodeVar134 = length( vec2<f32>( ( p0_nodeVar136 - ( ( floor( ( ( p0_nodeVar136 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar137 - ( floor( ( ( p0_nodeVar137 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar139 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar140 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar139.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar139.y ) );
			p0_nodeVar141 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar139.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar139.x ) );
			p0_nodeVar138 = max( abs( ( p0_nodeVar140 - ( ( floor( ( ( p0_nodeVar140 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar141 - ( floor( ( ( p0_nodeVar141 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar143 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar144 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar143.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar143.y ) );
				p0_nodeVar145 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar143.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar143.x ) );
				p0_nodeVar142 = ( abs( ( p0_nodeVar144 - ( ( floor( ( ( p0_nodeVar144 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar145 - ( floor( ( ( p0_nodeVar145 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar146 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar147 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar146.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar146.x ) );
				p0_nodeVar142 = abs( ( p0_nodeVar147 - ( floor( ( ( p0_nodeVar147 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar138 = p0_nodeVar142;

		}

		p0_nodeVar134 = p0_nodeVar138;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar149 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar150 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar149.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar151 = ( ( 1.0 - max( max( p0_nodeVar150.x, p0_nodeVar150.y ), p0_nodeVar150.z ) ) * f32(knobs.gcr) );
		p0_nodeVar148 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar150.x ) - p0_nodeVar151 ) / max( ( 1.0 - p0_nodeVar151 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar152 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar153 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar152.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar154 = ( ( 1.0 - max( max( p0_nodeVar153.x, p0_nodeVar153.y ), p0_nodeVar153.z ) ) * f32(knobs.gcr) );
		p0_nodeVar148 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar153.x ) - p0_nodeVar154 ) / max( ( 1.0 - p0_nodeVar154 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar155 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar148 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar157 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar158 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar157.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar157.y ) );
		p0_nodeVar159 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar157.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar157.x ) );
		p0_nodeVar156 = length( vec2<f32>( ( p0_nodeVar158 - ( ( floor( ( ( p0_nodeVar158 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar159 - ( ( floor( ( ( p0_nodeVar159 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar161 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar162 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar161.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar161.y ) );
			p0_nodeVar163 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar161.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar161.x ) );
			p0_nodeVar160 = max( abs( ( p0_nodeVar162 - ( ( floor( ( ( p0_nodeVar162 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar163 - ( ( floor( ( ( p0_nodeVar163 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar165 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar166 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar165.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar165.y ) );
				p0_nodeVar167 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar165.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar165.x ) );
				p0_nodeVar164 = ( abs( ( p0_nodeVar166 - ( ( floor( ( ( p0_nodeVar166 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar167 - ( ( floor( ( ( p0_nodeVar167 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar168 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar169 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar168.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar168.x ) );
				p0_nodeVar164 = abs( ( p0_nodeVar169 - ( ( floor( ( ( p0_nodeVar169 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar160 = p0_nodeVar164;

		}

		p0_nodeVar156 = p0_nodeVar160;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar171 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar172 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar173 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar172 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar172 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar171.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar174 = ( ( 1.0 - max( max( p0_nodeVar173.x, p0_nodeVar173.y ), p0_nodeVar173.z ) ) * f32(knobs.gcr) );
		p0_nodeVar170 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar173.x ) - p0_nodeVar174 ) / max( ( 1.0 - p0_nodeVar174 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar175 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar176 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar177 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar176 ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar176 ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar175.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar178 = ( ( 1.0 - max( max( p0_nodeVar177.x, p0_nodeVar177.y ), p0_nodeVar177.z ) ) * f32(knobs.gcr) );
		p0_nodeVar170 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar177.x ) - p0_nodeVar178 ) / max( ( 1.0 - p0_nodeVar178 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar179 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar170 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar181 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar182 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar181.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar181.y ) );
		p0_nodeVar183 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar181.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar181.x ) );
		p0_nodeVar180 = length( vec2<f32>( ( p0_nodeVar182 - ( floor( ( ( p0_nodeVar182 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar183 - ( ( floor( ( ( p0_nodeVar183 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar185 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar186 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar185.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar185.y ) );
			p0_nodeVar187 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar185.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar185.x ) );
			p0_nodeVar184 = max( abs( ( p0_nodeVar186 - ( floor( ( ( p0_nodeVar186 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar187 - ( ( floor( ( ( p0_nodeVar187 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar189 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar190 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar189.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar189.y ) );
				p0_nodeVar191 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar189.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar189.x ) );
				p0_nodeVar188 = ( abs( ( p0_nodeVar190 - ( floor( ( ( p0_nodeVar190 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar191 - ( ( floor( ( ( p0_nodeVar191 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar192 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar193 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar192.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar192.x ) );
				p0_nodeVar188 = abs( ( p0_nodeVar193 - ( ( floor( ( ( p0_nodeVar193 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar184 = p0_nodeVar188;

		}

		p0_nodeVar180 = p0_nodeVar184;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar195 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar196 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar195.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar197 = ( ( 1.0 - max( max( p0_nodeVar196.x, p0_nodeVar196.y ), p0_nodeVar196.z ) ) * f32(knobs.gcr) );
		p0_nodeVar194 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar196.x ) - p0_nodeVar197 ) / max( ( 1.0 - p0_nodeVar197 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar198 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar199 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar198.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar200 = ( ( 1.0 - max( max( p0_nodeVar199.x, p0_nodeVar199.y ), p0_nodeVar199.z ) ) * f32(knobs.gcr) );
		p0_nodeVar194 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar199.x ) - p0_nodeVar200 ) / max( ( 1.0 - p0_nodeVar200 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar201 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar194 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar203 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
		p0_nodeVar204 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar203.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar203.y ) );
		p0_nodeVar205 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar203.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar203.x ) );
		p0_nodeVar202 = length( vec2<f32>( ( p0_nodeVar204 - ( ( floor( ( ( p0_nodeVar204 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar205 - ( ( floor( ( ( p0_nodeVar205 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar207 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
			p0_nodeVar208 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar207.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar207.y ) );
			p0_nodeVar209 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar207.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar207.x ) );
			p0_nodeVar206 = max( abs( ( p0_nodeVar208 - ( ( floor( ( ( p0_nodeVar208 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar209 - ( ( floor( ( ( p0_nodeVar209 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar211 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar212 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar211.x ) + ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar211.y ) );
				p0_nodeVar213 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar211.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar211.x ) );
				p0_nodeVar210 = ( abs( ( p0_nodeVar212 - ( ( floor( ( ( p0_nodeVar212 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar213 - ( ( floor( ( ( p0_nodeVar213 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar214 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( f32(knobs.registration), 0.0 ) );
				p0_nodeVar215 = ( ( cos( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar214.y ) - ( sin( f32((0.017453292519943295 * knobs.cyanAngle + -5.551115123125783e-17)) ) * p0_nodeVar214.x ) );
				p0_nodeVar210 = abs( ( p0_nodeVar215 - ( ( floor( ( ( p0_nodeVar215 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar206 = p0_nodeVar210;

		}

		p0_nodeVar202 = p0_nodeVar206;

	}

	p0_nodeVar216 = max( 0.01, ( ( p0_nodeVar13 / f32(knobs.spacing) ) * 0.5 ) );
	p0_nodeVar217 = clamp( f32(knobs.dotMorph), 0.0, 1.0 );
	p0_nodeVar218 = ( ( f32(knobs.spacing) * p0_nodeVar217 ) * 0.6 );
	p0_nodeVar219 = clamp( ( 1.0 - ( p0_nodeVar202 / max( ( p0_nodeVar201 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar220 = clamp( ( 1.0 - ( p0_nodeVar180 / max( ( p0_nodeVar179 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar221 = clamp( ( 1.0 - ( p0_nodeVar156 / max( ( p0_nodeVar155 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar222 = clamp( ( 1.0 - ( p0_nodeVar134 / max( ( p0_nodeVar133 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar223 = clamp( ( 1.0 - ( p0_nodeVar110 / max( ( p0_nodeVar109 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar224 = clamp( ( 1.0 - ( p0_nodeVar84 / max( ( p0_nodeVar83 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar225 = clamp( ( 1.0 - ( p0_nodeVar60 / max( ( p0_nodeVar59 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar226 = clamp( ( 1.0 - ( p0_nodeVar38 / max( ( p0_nodeVar37 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar227 = clamp( ( 1.0 - ( p0_nodeVar14 / max( ( p0_nodeVar12 + p0_nodeVar218 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar228 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(knobs.inkCyan.x, knobs.inkCyan.y, knobs.inkCyan.z).x, vec3<f32>(knobs.inkCyan.x, knobs.inkCyan.y, knobs.inkCyan.z).y, vec3<f32>(knobs.inkCyan.x, knobs.inkCyan.y, knobs.inkCyan.z).z ), mix( max( smoothstep( ( p0_nodeVar12 + p0_nodeVar13 ), ( p0_nodeVar12 - p0_nodeVar13 ), p0_nodeVar14 ), max( smoothstep( ( p0_nodeVar37 + p0_nodeVar13 ), ( p0_nodeVar37 - p0_nodeVar13 ), p0_nodeVar38 ), max( smoothstep( ( p0_nodeVar59 + p0_nodeVar13 ), ( p0_nodeVar59 - p0_nodeVar13 ), p0_nodeVar60 ), max( smoothstep( ( p0_nodeVar83 + p0_nodeVar13 ), ( p0_nodeVar83 - p0_nodeVar13 ), p0_nodeVar84 ), max( smoothstep( ( p0_nodeVar109 + p0_nodeVar13 ), ( p0_nodeVar109 - p0_nodeVar13 ), p0_nodeVar110 ), max( smoothstep( ( p0_nodeVar133 + p0_nodeVar13 ), ( p0_nodeVar133 - p0_nodeVar13 ), p0_nodeVar134 ), max( smoothstep( ( p0_nodeVar155 + p0_nodeVar13 ), ( p0_nodeVar155 - p0_nodeVar13 ), p0_nodeVar156 ), max( smoothstep( ( p0_nodeVar179 + p0_nodeVar13 ), ( p0_nodeVar179 - p0_nodeVar13 ), p0_nodeVar180 ), max( smoothstep( ( p0_nodeVar201 + p0_nodeVar13 ), ( p0_nodeVar201 - p0_nodeVar13 ), p0_nodeVar202 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - p0_nodeVar216 ), ( 0.5 + p0_nodeVar216 ), ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar219 * p0_nodeVar219 ) ) + ( p0_nodeVar220 * p0_nodeVar220 ) ) + ( p0_nodeVar221 * p0_nodeVar221 ) ) + ( p0_nodeVar222 * p0_nodeVar222 ) ) + ( p0_nodeVar223 * p0_nodeVar223 ) ) + ( p0_nodeVar224 * p0_nodeVar224 ) ) + ( p0_nodeVar225 * p0_nodeVar225 ) ) + ( p0_nodeVar226 * p0_nodeVar226 ) ) + ( p0_nodeVar227 * p0_nodeVar227 ) ) ), p0_nodeVar217 ) );
	p0_nodeVar229 = vec3<f32>( ( p0_nodeVar4.x * p0_nodeVar228.x ), ( p0_nodeVar4.y * p0_nodeVar228.y ), ( p0_nodeVar4.z * p0_nodeVar228.z ) );

	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar231 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar232 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar231.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar233 = ( ( 1.0 - max( max( p0_nodeVar232.x, p0_nodeVar232.y ), p0_nodeVar232.z ) ) * f32(knobs.gcr) );
		p0_nodeVar230 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar232.y ) - p0_nodeVar233 ) / max( ( 1.0 - p0_nodeVar233 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar234 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar235 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar234.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar236 = ( ( 1.0 - max( max( p0_nodeVar235.x, p0_nodeVar235.y ), p0_nodeVar235.z ) ) * f32(knobs.gcr) );
		p0_nodeVar230 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar235.y ) - p0_nodeVar236 ) / max( ( 1.0 - p0_nodeVar236 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar237 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar230 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );
	p0_nodeVar238 = max( 0.5, ( ( f32(knobs.softness) * f32(knobs.spacing) ) * 0.3 ) );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar240 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar241 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar240.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar240.y ) );
		p0_nodeVar242 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar240.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar240.x ) );
		p0_nodeVar239 = length( vec2<f32>( ( p0_nodeVar241 - ( ( floor( ( ( p0_nodeVar241 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar242 - ( ( floor( ( ( p0_nodeVar242 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar244 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar245 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar244.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar244.y ) );
			p0_nodeVar246 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar244.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar244.x ) );
			p0_nodeVar243 = max( abs( ( p0_nodeVar245 - ( ( floor( ( ( p0_nodeVar245 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar246 - ( ( floor( ( ( p0_nodeVar246 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar248 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar249 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar248.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar248.y ) );
				p0_nodeVar250 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar248.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar248.x ) );
				p0_nodeVar247 = ( abs( ( p0_nodeVar249 - ( ( floor( ( ( p0_nodeVar249 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar250 - ( ( floor( ( ( p0_nodeVar250 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar251 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar252 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar251.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar251.x ) );
				p0_nodeVar247 = abs( ( p0_nodeVar252 - ( ( floor( ( ( p0_nodeVar252 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar243 = p0_nodeVar247;

		}

		p0_nodeVar239 = p0_nodeVar243;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar254 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar255 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar256 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar255 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar255 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar254.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar257 = ( ( 1.0 - max( max( p0_nodeVar256.x, p0_nodeVar256.y ), p0_nodeVar256.z ) ) * f32(knobs.gcr) );
		p0_nodeVar253 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar256.y ) - p0_nodeVar257 ) / max( ( 1.0 - p0_nodeVar257 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar258 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar259 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar260 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar259 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar259 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar258.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar261 = ( ( 1.0 - max( max( p0_nodeVar260.x, p0_nodeVar260.y ), p0_nodeVar260.z ) ) * f32(knobs.gcr) );
		p0_nodeVar253 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar260.y ) - p0_nodeVar261 ) / max( ( 1.0 - p0_nodeVar261 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar262 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar253 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar264 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar265 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar264.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar264.y ) );
		p0_nodeVar266 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar264.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar264.x ) );
		p0_nodeVar263 = length( vec2<f32>( ( p0_nodeVar265 - ( floor( ( ( p0_nodeVar265 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar266 - ( ( floor( ( ( p0_nodeVar266 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar268 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar269 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar268.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar268.y ) );
			p0_nodeVar270 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar268.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar268.x ) );
			p0_nodeVar267 = max( abs( ( p0_nodeVar269 - ( floor( ( ( p0_nodeVar269 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar270 - ( ( floor( ( ( p0_nodeVar270 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar272 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar273 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar272.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar272.y ) );
				p0_nodeVar274 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar272.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar272.x ) );
				p0_nodeVar271 = ( abs( ( p0_nodeVar273 - ( floor( ( ( p0_nodeVar273 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar274 - ( ( floor( ( ( p0_nodeVar274 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar275 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar276 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar275.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar275.x ) );
				p0_nodeVar271 = abs( ( p0_nodeVar276 - ( ( floor( ( ( p0_nodeVar276 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar267 = p0_nodeVar271;

		}

		p0_nodeVar263 = p0_nodeVar267;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar278 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar279 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar278.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar280 = ( ( 1.0 - max( max( p0_nodeVar279.x, p0_nodeVar279.y ), p0_nodeVar279.z ) ) * f32(knobs.gcr) );
		p0_nodeVar277 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar279.y ) - p0_nodeVar280 ) / max( ( 1.0 - p0_nodeVar280 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar281 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar282 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar281.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar283 = ( ( 1.0 - max( max( p0_nodeVar282.x, p0_nodeVar282.y ), p0_nodeVar282.z ) ) * f32(knobs.gcr) );
		p0_nodeVar277 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar282.y ) - p0_nodeVar283 ) / max( ( 1.0 - p0_nodeVar283 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar284 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar277 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar286 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar287 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar286.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar286.y ) );
		p0_nodeVar288 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar286.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar286.x ) );
		p0_nodeVar285 = length( vec2<f32>( ( p0_nodeVar287 - ( ( floor( ( ( p0_nodeVar287 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar288 - ( ( floor( ( ( p0_nodeVar288 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar290 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar291 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar290.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar290.y ) );
			p0_nodeVar292 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar290.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar290.x ) );
			p0_nodeVar289 = max( abs( ( p0_nodeVar291 - ( ( floor( ( ( p0_nodeVar291 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar292 - ( ( floor( ( ( p0_nodeVar292 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar294 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar295 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar294.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar294.y ) );
				p0_nodeVar296 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar294.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar294.x ) );
				p0_nodeVar293 = ( abs( ( p0_nodeVar295 - ( ( floor( ( ( p0_nodeVar295 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar296 - ( ( floor( ( ( p0_nodeVar296 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar297 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar298 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar297.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar297.x ) );
				p0_nodeVar293 = abs( ( p0_nodeVar298 - ( ( floor( ( ( p0_nodeVar298 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar289 = p0_nodeVar293;

		}

		p0_nodeVar285 = p0_nodeVar289;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar300 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar301 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar302 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar301 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar300.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar301 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar303 = ( ( 1.0 - max( max( p0_nodeVar302.x, p0_nodeVar302.y ), p0_nodeVar302.z ) ) * f32(knobs.gcr) );
		p0_nodeVar299 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar302.y ) - p0_nodeVar303 ) / max( ( 1.0 - p0_nodeVar303 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar304 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar305 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar306 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar305 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar304.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar305 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar307 = ( ( 1.0 - max( max( p0_nodeVar306.x, p0_nodeVar306.y ), p0_nodeVar306.z ) ) * f32(knobs.gcr) );
		p0_nodeVar299 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar306.y ) - p0_nodeVar307 ) / max( ( 1.0 - p0_nodeVar307 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar308 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar299 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar310 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar311 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar310.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar310.y ) );
		p0_nodeVar312 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar310.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar310.x ) );
		p0_nodeVar309 = length( vec2<f32>( ( p0_nodeVar311 - ( ( floor( ( ( p0_nodeVar311 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar312 - ( floor( ( ( p0_nodeVar312 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar314 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar315 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar314.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar314.y ) );
			p0_nodeVar316 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar314.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar314.x ) );
			p0_nodeVar313 = max( abs( ( p0_nodeVar315 - ( ( floor( ( ( p0_nodeVar315 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar316 - ( floor( ( ( p0_nodeVar316 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar318 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar319 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar318.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar318.y ) );
				p0_nodeVar320 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar318.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar318.x ) );
				p0_nodeVar317 = ( abs( ( p0_nodeVar319 - ( ( floor( ( ( p0_nodeVar319 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar320 - ( floor( ( ( p0_nodeVar320 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar321 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar322 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar321.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar321.x ) );
				p0_nodeVar317 = abs( ( p0_nodeVar322 - ( floor( ( ( p0_nodeVar322 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar313 = p0_nodeVar317;

		}

		p0_nodeVar309 = p0_nodeVar313;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar324 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar325 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar324.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar324.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar326 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar324.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar324.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar327 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar325 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar326 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar325 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar326 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar328 = ( ( 1.0 - max( max( p0_nodeVar327.x, p0_nodeVar327.y ), p0_nodeVar327.z ) ) * f32(knobs.gcr) );
		p0_nodeVar323 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar327.y ) - p0_nodeVar328 ) / max( ( 1.0 - p0_nodeVar328 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar329 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar330 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar329.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar329.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar331 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar329.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar329.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar332 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar330 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar331 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar330 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar331 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar333 = ( ( 1.0 - max( max( p0_nodeVar332.x, p0_nodeVar332.y ), p0_nodeVar332.z ) ) * f32(knobs.gcr) );
		p0_nodeVar323 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar332.y ) - p0_nodeVar333 ) / max( ( 1.0 - p0_nodeVar333 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar334 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar323 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar336 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar337 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar336.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar336.y ) );
		p0_nodeVar338 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar336.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar336.x ) );
		p0_nodeVar335 = length( vec2<f32>( ( p0_nodeVar337 - ( floor( ( ( p0_nodeVar337 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar338 - ( floor( ( ( p0_nodeVar338 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar340 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar341 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar340.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar340.y ) );
			p0_nodeVar342 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar340.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar340.x ) );
			p0_nodeVar339 = max( abs( ( p0_nodeVar341 - ( floor( ( ( p0_nodeVar341 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar342 - ( floor( ( ( p0_nodeVar342 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar344 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar345 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar344.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar344.y ) );
				p0_nodeVar346 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar344.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar344.x ) );
				p0_nodeVar343 = ( abs( ( p0_nodeVar345 - ( floor( ( ( p0_nodeVar345 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar346 - ( floor( ( ( p0_nodeVar346 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar347 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar348 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar347.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar347.x ) );
				p0_nodeVar343 = abs( ( p0_nodeVar348 - ( floor( ( ( p0_nodeVar348 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar339 = p0_nodeVar343;

		}

		p0_nodeVar335 = p0_nodeVar339;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar350 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar351 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar352 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar351 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar350.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar351 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar353 = ( ( 1.0 - max( max( p0_nodeVar352.x, p0_nodeVar352.y ), p0_nodeVar352.z ) ) * f32(knobs.gcr) );
		p0_nodeVar349 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar352.y ) - p0_nodeVar353 ) / max( ( 1.0 - p0_nodeVar353 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar354 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar355 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar356 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar355 ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar354.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar355 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar357 = ( ( 1.0 - max( max( p0_nodeVar356.x, p0_nodeVar356.y ), p0_nodeVar356.z ) ) * f32(knobs.gcr) );
		p0_nodeVar349 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar356.y ) - p0_nodeVar357 ) / max( ( 1.0 - p0_nodeVar357 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar358 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar349 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar360 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar361 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar360.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar360.y ) );
		p0_nodeVar362 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar360.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar360.x ) );
		p0_nodeVar359 = length( vec2<f32>( ( p0_nodeVar361 - ( ( floor( ( ( p0_nodeVar361 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar362 - ( floor( ( ( p0_nodeVar362 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar364 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar365 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar364.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar364.y ) );
			p0_nodeVar366 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar364.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar364.x ) );
			p0_nodeVar363 = max( abs( ( p0_nodeVar365 - ( ( floor( ( ( p0_nodeVar365 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar366 - ( floor( ( ( p0_nodeVar366 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar368 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar369 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar368.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar368.y ) );
				p0_nodeVar370 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar368.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar368.x ) );
				p0_nodeVar367 = ( abs( ( p0_nodeVar369 - ( ( floor( ( ( p0_nodeVar369 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar370 - ( floor( ( ( p0_nodeVar370 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar371 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar372 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar371.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar371.x ) );
				p0_nodeVar367 = abs( ( p0_nodeVar372 - ( floor( ( ( p0_nodeVar372 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar363 = p0_nodeVar367;

		}

		p0_nodeVar359 = p0_nodeVar363;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar374 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar375 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar374.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar376 = ( ( 1.0 - max( max( p0_nodeVar375.x, p0_nodeVar375.y ), p0_nodeVar375.z ) ) * f32(knobs.gcr) );
		p0_nodeVar373 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar375.y ) - p0_nodeVar376 ) / max( ( 1.0 - p0_nodeVar376 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar377 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar378 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar377.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar379 = ( ( 1.0 - max( max( p0_nodeVar378.x, p0_nodeVar378.y ), p0_nodeVar378.z ) ) * f32(knobs.gcr) );
		p0_nodeVar373 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar378.y ) - p0_nodeVar379 ) / max( ( 1.0 - p0_nodeVar379 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar380 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar373 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar382 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar383 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar382.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar382.y ) );
		p0_nodeVar384 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar382.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar382.x ) );
		p0_nodeVar381 = length( vec2<f32>( ( p0_nodeVar383 - ( ( floor( ( ( p0_nodeVar383 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar384 - ( ( floor( ( ( p0_nodeVar384 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar386 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar387 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar386.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar386.y ) );
			p0_nodeVar388 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar386.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar386.x ) );
			p0_nodeVar385 = max( abs( ( p0_nodeVar387 - ( ( floor( ( ( p0_nodeVar387 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar388 - ( ( floor( ( ( p0_nodeVar388 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar390 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar391 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar390.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar390.y ) );
				p0_nodeVar392 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar390.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar390.x ) );
				p0_nodeVar389 = ( abs( ( p0_nodeVar391 - ( ( floor( ( ( p0_nodeVar391 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar392 - ( ( floor( ( ( p0_nodeVar392 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar393 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar394 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar393.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar393.x ) );
				p0_nodeVar389 = abs( ( p0_nodeVar394 - ( ( floor( ( ( p0_nodeVar394 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar385 = p0_nodeVar389;

		}

		p0_nodeVar381 = p0_nodeVar385;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar396 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar397 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar398 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar397 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar397 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar396.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar399 = ( ( 1.0 - max( max( p0_nodeVar398.x, p0_nodeVar398.y ), p0_nodeVar398.z ) ) * f32(knobs.gcr) );
		p0_nodeVar395 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar398.y ) - p0_nodeVar399 ) / max( ( 1.0 - p0_nodeVar399 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar400 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar401 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar402 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar401 ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar401 ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar400.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar403 = ( ( 1.0 - max( max( p0_nodeVar402.x, p0_nodeVar402.y ), p0_nodeVar402.z ) ) * f32(knobs.gcr) );
		p0_nodeVar395 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar402.y ) - p0_nodeVar403 ) / max( ( 1.0 - p0_nodeVar403 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar404 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar395 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar406 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar407 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar406.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar406.y ) );
		p0_nodeVar408 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar406.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar406.x ) );
		p0_nodeVar405 = length( vec2<f32>( ( p0_nodeVar407 - ( floor( ( ( p0_nodeVar407 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar408 - ( ( floor( ( ( p0_nodeVar408 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar410 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar411 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar410.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar410.y ) );
			p0_nodeVar412 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar410.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar410.x ) );
			p0_nodeVar409 = max( abs( ( p0_nodeVar411 - ( floor( ( ( p0_nodeVar411 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar412 - ( ( floor( ( ( p0_nodeVar412 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar414 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar415 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar414.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar414.y ) );
				p0_nodeVar416 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar414.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar414.x ) );
				p0_nodeVar413 = ( abs( ( p0_nodeVar415 - ( floor( ( ( p0_nodeVar415 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar416 - ( ( floor( ( ( p0_nodeVar416 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar417 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar418 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar417.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar417.x ) );
				p0_nodeVar413 = abs( ( p0_nodeVar418 - ( ( floor( ( ( p0_nodeVar418 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar409 = p0_nodeVar413;

		}

		p0_nodeVar405 = p0_nodeVar409;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar420 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar421 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar420.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar422 = ( ( 1.0 - max( max( p0_nodeVar421.x, p0_nodeVar421.y ), p0_nodeVar421.z ) ) * f32(knobs.gcr) );
		p0_nodeVar419 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar421.y ) - p0_nodeVar422 ) / max( ( 1.0 - p0_nodeVar422 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar423 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar424 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar423.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar425 = ( ( 1.0 - max( max( p0_nodeVar424.x, p0_nodeVar424.y ), p0_nodeVar424.z ) ) * f32(knobs.gcr) );
		p0_nodeVar419 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar424.y ) - p0_nodeVar425 ) / max( ( 1.0 - p0_nodeVar425 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar426 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar419 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar428 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
		p0_nodeVar429 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar428.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar428.y ) );
		p0_nodeVar430 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar428.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar428.x ) );
		p0_nodeVar427 = length( vec2<f32>( ( p0_nodeVar429 - ( ( floor( ( ( p0_nodeVar429 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar430 - ( ( floor( ( ( p0_nodeVar430 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar432 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
			p0_nodeVar433 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar432.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar432.y ) );
			p0_nodeVar434 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar432.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar432.x ) );
			p0_nodeVar431 = max( abs( ( p0_nodeVar433 - ( ( floor( ( ( p0_nodeVar433 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar434 - ( ( floor( ( ( p0_nodeVar434 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar436 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar437 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar436.x ) + ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar436.y ) );
				p0_nodeVar438 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar436.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar436.x ) );
				p0_nodeVar435 = ( abs( ( p0_nodeVar437 - ( ( floor( ( ( p0_nodeVar437 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar438 - ( ( floor( ( ( p0_nodeVar438 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar439 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * 0.866 ) ) );
				p0_nodeVar440 = ( ( cos( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar439.y ) - ( sin( f32((0.017453292519943295 * knobs.magentaAngle + -5.551115123125783e-17)) ) * p0_nodeVar439.x ) );
				p0_nodeVar435 = abs( ( p0_nodeVar440 - ( ( floor( ( ( p0_nodeVar440 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar431 = p0_nodeVar435;

		}

		p0_nodeVar427 = p0_nodeVar431;

	}

	p0_nodeVar441 = max( 0.01, ( ( p0_nodeVar238 / f32(knobs.spacing) ) * 0.5 ) );
	p0_nodeVar442 = clamp( f32(knobs.dotMorph), 0.0, 1.0 );
	p0_nodeVar443 = ( ( f32(knobs.spacing) * p0_nodeVar442 ) * 0.6 );
	p0_nodeVar444 = clamp( ( 1.0 - ( p0_nodeVar427 / max( ( p0_nodeVar426 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar445 = clamp( ( 1.0 - ( p0_nodeVar405 / max( ( p0_nodeVar404 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar446 = clamp( ( 1.0 - ( p0_nodeVar381 / max( ( p0_nodeVar380 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar447 = clamp( ( 1.0 - ( p0_nodeVar359 / max( ( p0_nodeVar358 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar448 = clamp( ( 1.0 - ( p0_nodeVar335 / max( ( p0_nodeVar334 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar449 = clamp( ( 1.0 - ( p0_nodeVar309 / max( ( p0_nodeVar308 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar450 = clamp( ( 1.0 - ( p0_nodeVar285 / max( ( p0_nodeVar284 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar451 = clamp( ( 1.0 - ( p0_nodeVar263 / max( ( p0_nodeVar262 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar452 = clamp( ( 1.0 - ( p0_nodeVar239 / max( ( p0_nodeVar237 + p0_nodeVar443 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar453 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(knobs.inkMagenta.x, knobs.inkMagenta.y, knobs.inkMagenta.z).x, vec3<f32>(knobs.inkMagenta.x, knobs.inkMagenta.y, knobs.inkMagenta.z).y, vec3<f32>(knobs.inkMagenta.x, knobs.inkMagenta.y, knobs.inkMagenta.z).z ), mix( max( smoothstep( ( p0_nodeVar237 + p0_nodeVar238 ), ( p0_nodeVar237 - p0_nodeVar238 ), p0_nodeVar239 ), max( smoothstep( ( p0_nodeVar262 + p0_nodeVar238 ), ( p0_nodeVar262 - p0_nodeVar238 ), p0_nodeVar263 ), max( smoothstep( ( p0_nodeVar284 + p0_nodeVar238 ), ( p0_nodeVar284 - p0_nodeVar238 ), p0_nodeVar285 ), max( smoothstep( ( p0_nodeVar308 + p0_nodeVar238 ), ( p0_nodeVar308 - p0_nodeVar238 ), p0_nodeVar309 ), max( smoothstep( ( p0_nodeVar334 + p0_nodeVar238 ), ( p0_nodeVar334 - p0_nodeVar238 ), p0_nodeVar335 ), max( smoothstep( ( p0_nodeVar358 + p0_nodeVar238 ), ( p0_nodeVar358 - p0_nodeVar238 ), p0_nodeVar359 ), max( smoothstep( ( p0_nodeVar380 + p0_nodeVar238 ), ( p0_nodeVar380 - p0_nodeVar238 ), p0_nodeVar381 ), max( smoothstep( ( p0_nodeVar404 + p0_nodeVar238 ), ( p0_nodeVar404 - p0_nodeVar238 ), p0_nodeVar405 ), max( smoothstep( ( p0_nodeVar426 + p0_nodeVar238 ), ( p0_nodeVar426 - p0_nodeVar238 ), p0_nodeVar427 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - p0_nodeVar441 ), ( 0.5 + p0_nodeVar441 ), ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar444 * p0_nodeVar444 ) ) + ( p0_nodeVar445 * p0_nodeVar445 ) ) + ( p0_nodeVar446 * p0_nodeVar446 ) ) + ( p0_nodeVar447 * p0_nodeVar447 ) ) + ( p0_nodeVar448 * p0_nodeVar448 ) ) + ( p0_nodeVar449 * p0_nodeVar449 ) ) + ( p0_nodeVar450 * p0_nodeVar450 ) ) + ( p0_nodeVar451 * p0_nodeVar451 ) ) + ( p0_nodeVar452 * p0_nodeVar452 ) ) ), p0_nodeVar442 ) );
	p0_nodeVar454 = vec3<f32>( ( p0_nodeVar4.x * p0_nodeVar453.x ), ( p0_nodeVar4.y * p0_nodeVar453.y ), ( p0_nodeVar4.z * p0_nodeVar453.z ) );

	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar456 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar457 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar456.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar458 = ( ( 1.0 - max( max( p0_nodeVar457.x, p0_nodeVar457.y ), p0_nodeVar457.z ) ) * f32(knobs.gcr) );
		p0_nodeVar455 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar457.z ) - p0_nodeVar458 ) / max( ( 1.0 - p0_nodeVar458 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar459 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar460 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar459.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar461 = ( ( 1.0 - max( max( p0_nodeVar460.x, p0_nodeVar460.y ), p0_nodeVar460.z ) ) * f32(knobs.gcr) );
		p0_nodeVar455 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar460.z ) - p0_nodeVar461 ) / max( ( 1.0 - p0_nodeVar461 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar462 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar455 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );
	p0_nodeVar463 = max( 0.5, ( ( f32(knobs.softness) * f32(knobs.spacing) ) * 0.3 ) );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar465 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar466 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar465.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar465.y ) );
		p0_nodeVar467 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar465.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar465.x ) );
		p0_nodeVar464 = length( vec2<f32>( ( p0_nodeVar466 - ( ( floor( ( ( p0_nodeVar466 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar467 - ( ( floor( ( ( p0_nodeVar467 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar469 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar470 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar469.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar469.y ) );
			p0_nodeVar471 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar469.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar469.x ) );
			p0_nodeVar468 = max( abs( ( p0_nodeVar470 - ( ( floor( ( ( p0_nodeVar470 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar471 - ( ( floor( ( ( p0_nodeVar471 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar473 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar474 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar473.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar473.y ) );
				p0_nodeVar475 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar473.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar473.x ) );
				p0_nodeVar472 = ( abs( ( p0_nodeVar474 - ( ( floor( ( ( p0_nodeVar474 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar475 - ( ( floor( ( ( p0_nodeVar475 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar476 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar477 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar476.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar476.x ) );
				p0_nodeVar472 = abs( ( p0_nodeVar477 - ( ( floor( ( ( p0_nodeVar477 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar468 = p0_nodeVar472;

		}

		p0_nodeVar464 = p0_nodeVar468;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar479 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar480 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar481 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar480 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar480 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar479.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar482 = ( ( 1.0 - max( max( p0_nodeVar481.x, p0_nodeVar481.y ), p0_nodeVar481.z ) ) * f32(knobs.gcr) );
		p0_nodeVar478 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar481.z ) - p0_nodeVar482 ) / max( ( 1.0 - p0_nodeVar482 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar483 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar484 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar485 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar484 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar484 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar483.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar486 = ( ( 1.0 - max( max( p0_nodeVar485.x, p0_nodeVar485.y ), p0_nodeVar485.z ) ) * f32(knobs.gcr) );
		p0_nodeVar478 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar485.z ) - p0_nodeVar486 ) / max( ( 1.0 - p0_nodeVar486 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar487 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar478 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar489 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar490 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar489.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar489.y ) );
		p0_nodeVar491 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar489.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar489.x ) );
		p0_nodeVar488 = length( vec2<f32>( ( p0_nodeVar490 - ( floor( ( ( p0_nodeVar490 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar491 - ( ( floor( ( ( p0_nodeVar491 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar493 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar494 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar493.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar493.y ) );
			p0_nodeVar495 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar493.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar493.x ) );
			p0_nodeVar492 = max( abs( ( p0_nodeVar494 - ( floor( ( ( p0_nodeVar494 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar495 - ( ( floor( ( ( p0_nodeVar495 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar497 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar498 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar497.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar497.y ) );
				p0_nodeVar499 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar497.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar497.x ) );
				p0_nodeVar496 = ( abs( ( p0_nodeVar498 - ( floor( ( ( p0_nodeVar498 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar499 - ( ( floor( ( ( p0_nodeVar499 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar500 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar501 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar500.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar500.x ) );
				p0_nodeVar496 = abs( ( p0_nodeVar501 - ( ( floor( ( ( p0_nodeVar501 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar492 = p0_nodeVar496;

		}

		p0_nodeVar488 = p0_nodeVar492;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar503 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar504 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar503.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar505 = ( ( 1.0 - max( max( p0_nodeVar504.x, p0_nodeVar504.y ), p0_nodeVar504.z ) ) * f32(knobs.gcr) );
		p0_nodeVar502 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar504.z ) - p0_nodeVar505 ) / max( ( 1.0 - p0_nodeVar505 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar506 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar507 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar506.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar508 = ( ( 1.0 - max( max( p0_nodeVar507.x, p0_nodeVar507.y ), p0_nodeVar507.z ) ) * f32(knobs.gcr) );
		p0_nodeVar502 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar507.z ) - p0_nodeVar508 ) / max( ( 1.0 - p0_nodeVar508 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar509 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar502 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar511 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar512 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar511.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar511.y ) );
		p0_nodeVar513 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar511.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar511.x ) );
		p0_nodeVar510 = length( vec2<f32>( ( p0_nodeVar512 - ( ( floor( ( ( p0_nodeVar512 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar513 - ( ( floor( ( ( p0_nodeVar513 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar515 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar516 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar515.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar515.y ) );
			p0_nodeVar517 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar515.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar515.x ) );
			p0_nodeVar514 = max( abs( ( p0_nodeVar516 - ( ( floor( ( ( p0_nodeVar516 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar517 - ( ( floor( ( ( p0_nodeVar517 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar519 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar520 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar519.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar519.y ) );
				p0_nodeVar521 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar519.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar519.x ) );
				p0_nodeVar518 = ( abs( ( p0_nodeVar520 - ( ( floor( ( ( p0_nodeVar520 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar521 - ( ( floor( ( ( p0_nodeVar521 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar522 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar523 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar522.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar522.x ) );
				p0_nodeVar518 = abs( ( p0_nodeVar523 - ( ( floor( ( ( p0_nodeVar523 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar514 = p0_nodeVar518;

		}

		p0_nodeVar510 = p0_nodeVar514;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar525 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar526 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar527 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar526 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar525.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar526 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar528 = ( ( 1.0 - max( max( p0_nodeVar527.x, p0_nodeVar527.y ), p0_nodeVar527.z ) ) * f32(knobs.gcr) );
		p0_nodeVar524 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar527.z ) - p0_nodeVar528 ) / max( ( 1.0 - p0_nodeVar528 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar529 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar530 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar531 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar530 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar529.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar530 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar532 = ( ( 1.0 - max( max( p0_nodeVar531.x, p0_nodeVar531.y ), p0_nodeVar531.z ) ) * f32(knobs.gcr) );
		p0_nodeVar524 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar531.z ) - p0_nodeVar532 ) / max( ( 1.0 - p0_nodeVar532 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar533 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar524 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar535 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar536 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar535.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar535.y ) );
		p0_nodeVar537 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar535.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar535.x ) );
		p0_nodeVar534 = length( vec2<f32>( ( p0_nodeVar536 - ( ( floor( ( ( p0_nodeVar536 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar537 - ( floor( ( ( p0_nodeVar537 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar539 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar540 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar539.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar539.y ) );
			p0_nodeVar541 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar539.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar539.x ) );
			p0_nodeVar538 = max( abs( ( p0_nodeVar540 - ( ( floor( ( ( p0_nodeVar540 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar541 - ( floor( ( ( p0_nodeVar541 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar543 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar544 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar543.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar543.y ) );
				p0_nodeVar545 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar543.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar543.x ) );
				p0_nodeVar542 = ( abs( ( p0_nodeVar544 - ( ( floor( ( ( p0_nodeVar544 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar545 - ( floor( ( ( p0_nodeVar545 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar546 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar547 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar546.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar546.x ) );
				p0_nodeVar542 = abs( ( p0_nodeVar547 - ( floor( ( ( p0_nodeVar547 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar538 = p0_nodeVar542;

		}

		p0_nodeVar534 = p0_nodeVar538;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar549 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar550 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar549.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar549.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar551 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar549.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar549.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar552 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar550 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar551 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar550 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar551 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar553 = ( ( 1.0 - max( max( p0_nodeVar552.x, p0_nodeVar552.y ), p0_nodeVar552.z ) ) * f32(knobs.gcr) );
		p0_nodeVar548 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar552.z ) - p0_nodeVar553 ) / max( ( 1.0 - p0_nodeVar553 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar554 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar555 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar554.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar554.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar556 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar554.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar554.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar557 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar555 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar556 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar555 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar556 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar558 = ( ( 1.0 - max( max( p0_nodeVar557.x, p0_nodeVar557.y ), p0_nodeVar557.z ) ) * f32(knobs.gcr) );
		p0_nodeVar548 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar557.z ) - p0_nodeVar558 ) / max( ( 1.0 - p0_nodeVar558 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar559 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar548 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar561 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar562 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar561.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar561.y ) );
		p0_nodeVar563 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar561.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar561.x ) );
		p0_nodeVar560 = length( vec2<f32>( ( p0_nodeVar562 - ( floor( ( ( p0_nodeVar562 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar563 - ( floor( ( ( p0_nodeVar563 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar565 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar566 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar565.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar565.y ) );
			p0_nodeVar567 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar565.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar565.x ) );
			p0_nodeVar564 = max( abs( ( p0_nodeVar566 - ( floor( ( ( p0_nodeVar566 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar567 - ( floor( ( ( p0_nodeVar567 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar569 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar570 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar569.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar569.y ) );
				p0_nodeVar571 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar569.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar569.x ) );
				p0_nodeVar568 = ( abs( ( p0_nodeVar570 - ( floor( ( ( p0_nodeVar570 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar571 - ( floor( ( ( p0_nodeVar571 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar572 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar573 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar572.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar572.x ) );
				p0_nodeVar568 = abs( ( p0_nodeVar573 - ( floor( ( ( p0_nodeVar573 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar564 = p0_nodeVar568;

		}

		p0_nodeVar560 = p0_nodeVar564;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar575 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar576 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar577 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar576 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar575.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar576 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar578 = ( ( 1.0 - max( max( p0_nodeVar577.x, p0_nodeVar577.y ), p0_nodeVar577.z ) ) * f32(knobs.gcr) );
		p0_nodeVar574 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar577.z ) - p0_nodeVar578 ) / max( ( 1.0 - p0_nodeVar578 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar579 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar580 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar581 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar580 ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar579.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar580 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar582 = ( ( 1.0 - max( max( p0_nodeVar581.x, p0_nodeVar581.y ), p0_nodeVar581.z ) ) * f32(knobs.gcr) );
		p0_nodeVar574 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar581.z ) - p0_nodeVar582 ) / max( ( 1.0 - p0_nodeVar582 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar583 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar574 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar585 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar586 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar585.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar585.y ) );
		p0_nodeVar587 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar585.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar585.x ) );
		p0_nodeVar584 = length( vec2<f32>( ( p0_nodeVar586 - ( ( floor( ( ( p0_nodeVar586 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar587 - ( floor( ( ( p0_nodeVar587 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar589 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar590 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar589.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar589.y ) );
			p0_nodeVar591 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar589.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar589.x ) );
			p0_nodeVar588 = max( abs( ( p0_nodeVar590 - ( ( floor( ( ( p0_nodeVar590 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar591 - ( floor( ( ( p0_nodeVar591 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar593 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar594 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar593.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar593.y ) );
				p0_nodeVar595 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar593.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar593.x ) );
				p0_nodeVar592 = ( abs( ( p0_nodeVar594 - ( ( floor( ( ( p0_nodeVar594 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar595 - ( floor( ( ( p0_nodeVar595 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar596 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar597 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar596.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar596.x ) );
				p0_nodeVar592 = abs( ( p0_nodeVar597 - ( floor( ( ( p0_nodeVar597 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar588 = p0_nodeVar592;

		}

		p0_nodeVar584 = p0_nodeVar588;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar599 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar600 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar599.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar601 = ( ( 1.0 - max( max( p0_nodeVar600.x, p0_nodeVar600.y ), p0_nodeVar600.z ) ) * f32(knobs.gcr) );
		p0_nodeVar598 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar600.z ) - p0_nodeVar601 ) / max( ( 1.0 - p0_nodeVar601 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar602 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar603 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar602.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar604 = ( ( 1.0 - max( max( p0_nodeVar603.x, p0_nodeVar603.y ), p0_nodeVar603.z ) ) * f32(knobs.gcr) );
		p0_nodeVar598 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar603.z ) - p0_nodeVar604 ) / max( ( 1.0 - p0_nodeVar604 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar605 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar598 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar607 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar608 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar607.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar607.y ) );
		p0_nodeVar609 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar607.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar607.x ) );
		p0_nodeVar606 = length( vec2<f32>( ( p0_nodeVar608 - ( ( floor( ( ( p0_nodeVar608 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar609 - ( ( floor( ( ( p0_nodeVar609 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar611 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar612 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar611.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar611.y ) );
			p0_nodeVar613 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar611.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar611.x ) );
			p0_nodeVar610 = max( abs( ( p0_nodeVar612 - ( ( floor( ( ( p0_nodeVar612 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar613 - ( ( floor( ( ( p0_nodeVar613 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar615 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar616 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar615.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar615.y ) );
				p0_nodeVar617 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar615.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar615.x ) );
				p0_nodeVar614 = ( abs( ( p0_nodeVar616 - ( ( floor( ( ( p0_nodeVar616 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar617 - ( ( floor( ( ( p0_nodeVar617 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar618 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar619 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar618.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar618.x ) );
				p0_nodeVar614 = abs( ( p0_nodeVar619 - ( ( floor( ( ( p0_nodeVar619 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar610 = p0_nodeVar614;

		}

		p0_nodeVar606 = p0_nodeVar610;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar621 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar622 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar623 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar622 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar622 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar621.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar624 = ( ( 1.0 - max( max( p0_nodeVar623.x, p0_nodeVar623.y ), p0_nodeVar623.z ) ) * f32(knobs.gcr) );
		p0_nodeVar620 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar623.z ) - p0_nodeVar624 ) / max( ( 1.0 - p0_nodeVar624 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar625 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar626 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar627 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar626 ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar626 ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar625.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar628 = ( ( 1.0 - max( max( p0_nodeVar627.x, p0_nodeVar627.y ), p0_nodeVar627.z ) ) * f32(knobs.gcr) );
		p0_nodeVar620 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar627.z ) - p0_nodeVar628 ) / max( ( 1.0 - p0_nodeVar628 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar629 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar620 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar631 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar632 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar631.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar631.y ) );
		p0_nodeVar633 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar631.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar631.x ) );
		p0_nodeVar630 = length( vec2<f32>( ( p0_nodeVar632 - ( floor( ( ( p0_nodeVar632 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar633 - ( ( floor( ( ( p0_nodeVar633 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar635 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar636 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar635.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar635.y ) );
			p0_nodeVar637 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar635.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar635.x ) );
			p0_nodeVar634 = max( abs( ( p0_nodeVar636 - ( floor( ( ( p0_nodeVar636 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar637 - ( ( floor( ( ( p0_nodeVar637 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar639 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar640 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar639.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar639.y ) );
				p0_nodeVar641 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar639.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar639.x ) );
				p0_nodeVar638 = ( abs( ( p0_nodeVar640 - ( floor( ( ( p0_nodeVar640 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar641 - ( ( floor( ( ( p0_nodeVar641 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar642 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar643 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar642.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar642.x ) );
				p0_nodeVar638 = abs( ( p0_nodeVar643 - ( ( floor( ( ( p0_nodeVar643 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar634 = p0_nodeVar638;

		}

		p0_nodeVar630 = p0_nodeVar634;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar645 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar646 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar645.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar647 = ( ( 1.0 - max( max( p0_nodeVar646.x, p0_nodeVar646.y ), p0_nodeVar646.z ) ) * f32(knobs.gcr) );
		p0_nodeVar644 = ( 1.0 - clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar646.z ) - p0_nodeVar647 ) / max( ( 1.0 - p0_nodeVar647 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar648 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar649 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar648.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar650 = ( ( 1.0 - max( max( p0_nodeVar649.x, p0_nodeVar649.y ), p0_nodeVar649.z ) ) * f32(knobs.gcr) );
		p0_nodeVar644 = clamp( ( clamp( ( ( ( 1.0 - p0_nodeVar649.z ) - p0_nodeVar650 ) / max( ( 1.0 - p0_nodeVar650 ), 0.001 ) ), 0.0, 1.0 ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar651 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar644 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar653 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
		p0_nodeVar654 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar653.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar653.y ) );
		p0_nodeVar655 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar653.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar653.x ) );
		p0_nodeVar652 = length( vec2<f32>( ( p0_nodeVar654 - ( ( floor( ( ( p0_nodeVar654 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar655 - ( ( floor( ( ( p0_nodeVar655 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar657 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
			p0_nodeVar658 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar657.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar657.y ) );
			p0_nodeVar659 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar657.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar657.x ) );
			p0_nodeVar656 = max( abs( ( p0_nodeVar658 - ( ( floor( ( ( p0_nodeVar658 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar659 - ( ( floor( ( ( p0_nodeVar659 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar661 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar662 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar661.x ) + ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar661.y ) );
				p0_nodeVar663 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar661.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar661.x ) );
				p0_nodeVar660 = ( abs( ( p0_nodeVar662 - ( ( floor( ( ( p0_nodeVar662 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar663 - ( ( floor( ( ( p0_nodeVar663 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar664 = ( ( p0_nodeVar1 * p0_nodeVar2 ) + vec2<f32>( ( f32(knobs.registration) * -0.5 ), ( f32(knobs.registration) * -0.866 ) ) );
				p0_nodeVar665 = ( ( cos( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar664.y ) - ( sin( f32((0.017453292519943295 * knobs.yellowAngle + -5.551115123125783e-17)) ) * p0_nodeVar664.x ) );
				p0_nodeVar660 = abs( ( p0_nodeVar665 - ( ( floor( ( ( p0_nodeVar665 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar656 = p0_nodeVar660;

		}

		p0_nodeVar652 = p0_nodeVar656;

	}

	p0_nodeVar666 = max( 0.01, ( ( p0_nodeVar463 / f32(knobs.spacing) ) * 0.5 ) );
	p0_nodeVar667 = clamp( f32(knobs.dotMorph), 0.0, 1.0 );
	p0_nodeVar668 = ( ( f32(knobs.spacing) * p0_nodeVar667 ) * 0.6 );
	p0_nodeVar669 = clamp( ( 1.0 - ( p0_nodeVar652 / max( ( p0_nodeVar651 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar670 = clamp( ( 1.0 - ( p0_nodeVar630 / max( ( p0_nodeVar629 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar671 = clamp( ( 1.0 - ( p0_nodeVar606 / max( ( p0_nodeVar605 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar672 = clamp( ( 1.0 - ( p0_nodeVar584 / max( ( p0_nodeVar583 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar673 = clamp( ( 1.0 - ( p0_nodeVar560 / max( ( p0_nodeVar559 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar674 = clamp( ( 1.0 - ( p0_nodeVar534 / max( ( p0_nodeVar533 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar675 = clamp( ( 1.0 - ( p0_nodeVar510 / max( ( p0_nodeVar509 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar676 = clamp( ( 1.0 - ( p0_nodeVar488 / max( ( p0_nodeVar487 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar677 = clamp( ( 1.0 - ( p0_nodeVar464 / max( ( p0_nodeVar462 + p0_nodeVar668 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar678 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(knobs.inkYellow.x, knobs.inkYellow.y, knobs.inkYellow.z).x, vec3<f32>(knobs.inkYellow.x, knobs.inkYellow.y, knobs.inkYellow.z).y, vec3<f32>(knobs.inkYellow.x, knobs.inkYellow.y, knobs.inkYellow.z).z ), mix( max( smoothstep( ( p0_nodeVar462 + p0_nodeVar463 ), ( p0_nodeVar462 - p0_nodeVar463 ), p0_nodeVar464 ), max( smoothstep( ( p0_nodeVar487 + p0_nodeVar463 ), ( p0_nodeVar487 - p0_nodeVar463 ), p0_nodeVar488 ), max( smoothstep( ( p0_nodeVar509 + p0_nodeVar463 ), ( p0_nodeVar509 - p0_nodeVar463 ), p0_nodeVar510 ), max( smoothstep( ( p0_nodeVar533 + p0_nodeVar463 ), ( p0_nodeVar533 - p0_nodeVar463 ), p0_nodeVar534 ), max( smoothstep( ( p0_nodeVar559 + p0_nodeVar463 ), ( p0_nodeVar559 - p0_nodeVar463 ), p0_nodeVar560 ), max( smoothstep( ( p0_nodeVar583 + p0_nodeVar463 ), ( p0_nodeVar583 - p0_nodeVar463 ), p0_nodeVar584 ), max( smoothstep( ( p0_nodeVar605 + p0_nodeVar463 ), ( p0_nodeVar605 - p0_nodeVar463 ), p0_nodeVar606 ), max( smoothstep( ( p0_nodeVar629 + p0_nodeVar463 ), ( p0_nodeVar629 - p0_nodeVar463 ), p0_nodeVar630 ), max( smoothstep( ( p0_nodeVar651 + p0_nodeVar463 ), ( p0_nodeVar651 - p0_nodeVar463 ), p0_nodeVar652 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - p0_nodeVar666 ), ( 0.5 + p0_nodeVar666 ), ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar669 * p0_nodeVar669 ) ) + ( p0_nodeVar670 * p0_nodeVar670 ) ) + ( p0_nodeVar671 * p0_nodeVar671 ) ) + ( p0_nodeVar672 * p0_nodeVar672 ) ) + ( p0_nodeVar673 * p0_nodeVar673 ) ) + ( p0_nodeVar674 * p0_nodeVar674 ) ) + ( p0_nodeVar675 * p0_nodeVar675 ) ) + ( p0_nodeVar676 * p0_nodeVar676 ) ) + ( p0_nodeVar677 * p0_nodeVar677 ) ) ), p0_nodeVar667 ) );
	p0_nodeVar679 = vec3<f32>( ( p0_nodeVar4.x * p0_nodeVar678.x ), ( p0_nodeVar4.y * p0_nodeVar678.y ), ( p0_nodeVar4.z * p0_nodeVar678.z ) );

	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar681 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar682 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar681.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar680 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar682.x, p0_nodeVar682.y ), p0_nodeVar682.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar683 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar684 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar683.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar680 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar684.x, p0_nodeVar684.y ), p0_nodeVar684.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar685 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar680 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );
	p0_nodeVar686 = max( 0.5, ( ( f32(knobs.softness) * f32(knobs.spacing) ) * 0.3 ) );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar688 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar689 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar688.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar688.y ) );
		p0_nodeVar690 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar688.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar688.x ) );
		p0_nodeVar687 = length( vec2<f32>( ( p0_nodeVar689 - ( ( floor( ( ( p0_nodeVar689 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar690 - ( ( floor( ( ( p0_nodeVar690 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar692 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar693 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar692.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar692.y ) );
			p0_nodeVar694 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar692.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar692.x ) );
			p0_nodeVar691 = max( abs( ( p0_nodeVar693 - ( ( floor( ( ( p0_nodeVar693 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar694 - ( ( floor( ( ( p0_nodeVar694 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar696 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar697 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar696.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar696.y ) );
				p0_nodeVar698 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar696.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar696.x ) );
				p0_nodeVar695 = ( abs( ( p0_nodeVar697 - ( ( floor( ( ( p0_nodeVar697 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar698 - ( ( floor( ( ( p0_nodeVar698 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar699 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar700 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar699.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar699.x ) );
				p0_nodeVar695 = abs( ( p0_nodeVar700 - ( ( floor( ( ( p0_nodeVar700 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar691 = p0_nodeVar695;

		}

		p0_nodeVar687 = p0_nodeVar691;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar702 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar703 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar704 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar703 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar703 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar702.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar701 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar704.x, p0_nodeVar704.y ), p0_nodeVar704.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar705 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar706 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar707 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar706 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar706 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar705.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar701 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar707.x, p0_nodeVar707.y ), p0_nodeVar707.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar708 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar701 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar710 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar711 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar710.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar710.y ) );
		p0_nodeVar712 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar710.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar710.x ) );
		p0_nodeVar709 = length( vec2<f32>( ( p0_nodeVar711 - ( floor( ( ( p0_nodeVar711 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar712 - ( ( floor( ( ( p0_nodeVar712 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar714 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar715 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar714.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar714.y ) );
			p0_nodeVar716 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar714.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar714.x ) );
			p0_nodeVar713 = max( abs( ( p0_nodeVar715 - ( floor( ( ( p0_nodeVar715 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar716 - ( ( floor( ( ( p0_nodeVar716 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar718 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar719 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar718.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar718.y ) );
				p0_nodeVar720 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar718.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar718.x ) );
				p0_nodeVar717 = ( abs( ( p0_nodeVar719 - ( floor( ( ( p0_nodeVar719 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar720 - ( ( floor( ( ( p0_nodeVar720 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar721 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar722 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar721.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar721.x ) );
				p0_nodeVar717 = abs( ( p0_nodeVar722 - ( ( floor( ( ( p0_nodeVar722 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar713 = p0_nodeVar717;

		}

		p0_nodeVar709 = p0_nodeVar713;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar724 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar725 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar724.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar723 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar725.x, p0_nodeVar725.y ), p0_nodeVar725.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar726 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar727 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar726.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar723 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar727.x, p0_nodeVar727.y ), p0_nodeVar727.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar728 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar723 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar730 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar731 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar730.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar730.y ) );
		p0_nodeVar732 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar730.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar730.x ) );
		p0_nodeVar729 = length( vec2<f32>( ( p0_nodeVar731 - ( ( floor( ( ( p0_nodeVar731 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar732 - ( ( floor( ( ( p0_nodeVar732 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar734 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar735 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar734.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar734.y ) );
			p0_nodeVar736 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar734.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar734.x ) );
			p0_nodeVar733 = max( abs( ( p0_nodeVar735 - ( ( floor( ( ( p0_nodeVar735 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar736 - ( ( floor( ( ( p0_nodeVar736 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar738 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar739 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar738.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar738.y ) );
				p0_nodeVar740 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar738.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar738.x ) );
				p0_nodeVar737 = ( abs( ( p0_nodeVar739 - ( ( floor( ( ( p0_nodeVar739 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar740 - ( ( floor( ( ( p0_nodeVar740 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) );

			} else {

				p0_nodeVar741 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar742 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar741.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar741.x ) );
				p0_nodeVar737 = abs( ( p0_nodeVar742 - ( ( floor( ( ( p0_nodeVar742 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) );

			}

			p0_nodeVar733 = p0_nodeVar737;

		}

		p0_nodeVar729 = p0_nodeVar733;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar744 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar745 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar746 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar745 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar744.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar745 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar743 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar746.x, p0_nodeVar746.y ), p0_nodeVar746.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar747 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar748 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar749 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar748 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar747.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar748 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar743 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar749.x, p0_nodeVar749.y ), p0_nodeVar749.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar750 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar743 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar752 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar753 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar752.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar752.y ) );
		p0_nodeVar754 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar752.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar752.x ) );
		p0_nodeVar751 = length( vec2<f32>( ( p0_nodeVar753 - ( ( floor( ( ( p0_nodeVar753 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar754 - ( floor( ( ( p0_nodeVar754 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar756 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar757 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar756.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar756.y ) );
			p0_nodeVar758 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar756.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar756.x ) );
			p0_nodeVar755 = max( abs( ( p0_nodeVar757 - ( ( floor( ( ( p0_nodeVar757 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar758 - ( floor( ( ( p0_nodeVar758 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar760 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar761 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar760.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar760.y ) );
				p0_nodeVar762 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar760.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar760.x ) );
				p0_nodeVar759 = ( abs( ( p0_nodeVar761 - ( ( floor( ( ( p0_nodeVar761 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar762 - ( floor( ( ( p0_nodeVar762 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar763 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar764 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar763.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar763.x ) );
				p0_nodeVar759 = abs( ( p0_nodeVar764 - ( floor( ( ( p0_nodeVar764 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar755 = p0_nodeVar759;

		}

		p0_nodeVar751 = p0_nodeVar755;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar766 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar767 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar766.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar766.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar768 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar766.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar766.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar769 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar767 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar768 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar767 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar768 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar765 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar769.x, p0_nodeVar769.y ), p0_nodeVar769.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar770 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar771 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar770.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar770.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar772 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar770.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar770.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar773 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar771 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar772 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar771 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar772 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar765 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar773.x, p0_nodeVar773.y ), p0_nodeVar773.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar774 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar765 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar776 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar777 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar776.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar776.y ) );
		p0_nodeVar778 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar776.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar776.x ) );
		p0_nodeVar775 = length( vec2<f32>( ( p0_nodeVar777 - ( floor( ( ( p0_nodeVar777 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar778 - ( floor( ( ( p0_nodeVar778 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar780 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar781 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar780.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar780.y ) );
			p0_nodeVar782 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar780.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar780.x ) );
			p0_nodeVar779 = max( abs( ( p0_nodeVar781 - ( floor( ( ( p0_nodeVar781 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar782 - ( floor( ( ( p0_nodeVar782 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar784 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar785 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar784.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar784.y ) );
				p0_nodeVar786 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar784.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar784.x ) );
				p0_nodeVar783 = ( abs( ( p0_nodeVar785 - ( floor( ( ( p0_nodeVar785 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar786 - ( floor( ( ( p0_nodeVar786 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar787 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar788 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar787.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar787.x ) );
				p0_nodeVar783 = abs( ( p0_nodeVar788 - ( floor( ( ( p0_nodeVar788 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar779 = p0_nodeVar783;

		}

		p0_nodeVar775 = p0_nodeVar779;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar790 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar791 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar792 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar791 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar790.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar791 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar789 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar792.x, p0_nodeVar792.y ), p0_nodeVar792.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar793 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar794 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar795 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar794 ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar793.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar794 ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar789 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar795.x, p0_nodeVar795.y ), p0_nodeVar795.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar796 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar789 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar798 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar799 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar798.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar798.y ) );
		p0_nodeVar800 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar798.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar798.x ) );
		p0_nodeVar797 = length( vec2<f32>( ( p0_nodeVar799 - ( ( floor( ( ( p0_nodeVar799 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar800 - ( floor( ( ( p0_nodeVar800 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar802 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar803 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar802.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar802.y ) );
			p0_nodeVar804 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar802.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar802.x ) );
			p0_nodeVar801 = max( abs( ( p0_nodeVar803 - ( ( floor( ( ( p0_nodeVar803 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar804 - ( floor( ( ( p0_nodeVar804 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar806 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar807 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar806.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar806.y ) );
				p0_nodeVar808 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar806.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar806.x ) );
				p0_nodeVar805 = ( abs( ( p0_nodeVar807 - ( ( floor( ( ( p0_nodeVar807 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar808 - ( floor( ( ( p0_nodeVar808 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) );

			} else {

				p0_nodeVar809 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar810 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar809.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar809.x ) );
				p0_nodeVar805 = abs( ( p0_nodeVar810 - ( floor( ( ( p0_nodeVar810 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) );

			}

			p0_nodeVar801 = p0_nodeVar805;

		}

		p0_nodeVar797 = p0_nodeVar801;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar812 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar813 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar812.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar811 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar813.x, p0_nodeVar813.y ), p0_nodeVar813.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar814 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar815 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar814.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar811 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar815.x, p0_nodeVar815.y ), p0_nodeVar815.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar816 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar811 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar818 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar819 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar818.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar818.y ) );
		p0_nodeVar820 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar818.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar818.x ) );
		p0_nodeVar817 = length( vec2<f32>( ( p0_nodeVar819 - ( ( floor( ( ( p0_nodeVar819 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ), ( p0_nodeVar820 - ( ( floor( ( ( p0_nodeVar820 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar822 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar823 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar822.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar822.y ) );
			p0_nodeVar824 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar822.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar822.x ) );
			p0_nodeVar821 = max( abs( ( p0_nodeVar823 - ( ( floor( ( ( p0_nodeVar823 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ), abs( ( p0_nodeVar824 - ( ( floor( ( ( p0_nodeVar824 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar826 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar827 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar826.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar826.y ) );
				p0_nodeVar828 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar826.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar826.x ) );
				p0_nodeVar825 = ( abs( ( p0_nodeVar827 - ( ( floor( ( ( p0_nodeVar827 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * 1.0 ) ) ) ) + abs( ( p0_nodeVar828 - ( ( floor( ( ( p0_nodeVar828 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar829 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar830 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar829.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar829.x ) );
				p0_nodeVar825 = abs( ( p0_nodeVar830 - ( ( floor( ( ( p0_nodeVar830 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar821 = p0_nodeVar825;

		}

		p0_nodeVar817 = p0_nodeVar821;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar832 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar833 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar834 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar833 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar833 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar832.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar831 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar834.x, p0_nodeVar834.y ), p0_nodeVar834.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar835 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar836 = ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) );
		p0_nodeVar837 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar836 ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar836 ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar835.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar831 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar837.x, p0_nodeVar837.y ), p0_nodeVar837.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar838 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar831 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar840 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar841 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar840.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar840.y ) );
		p0_nodeVar842 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar840.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar840.x ) );
		p0_nodeVar839 = length( vec2<f32>( ( p0_nodeVar841 - ( floor( ( ( p0_nodeVar841 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ), ( p0_nodeVar842 - ( ( floor( ( ( p0_nodeVar842 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar844 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar845 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar844.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar844.y ) );
			p0_nodeVar846 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar844.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar844.x ) );
			p0_nodeVar843 = max( abs( ( p0_nodeVar845 - ( floor( ( ( p0_nodeVar845 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ), abs( ( p0_nodeVar846 - ( ( floor( ( ( p0_nodeVar846 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar848 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar849 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar848.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar848.y ) );
				p0_nodeVar850 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar848.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar848.x ) );
				p0_nodeVar847 = ( abs( ( p0_nodeVar849 - ( floor( ( ( p0_nodeVar849 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) ) ) + abs( ( p0_nodeVar850 - ( ( floor( ( ( p0_nodeVar850 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar851 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar852 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar851.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar851.x ) );
				p0_nodeVar847 = abs( ( p0_nodeVar852 - ( ( floor( ( ( p0_nodeVar852 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar843 = p0_nodeVar847;

		}

		p0_nodeVar839 = p0_nodeVar843;

	}


	if ( ( f32(knobs.invertLuma) > 0.5 ) ) {

		p0_nodeVar854 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar855 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar854.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar853 = ( 1.0 - clamp( ( ( ( 1.0 - max( max( p0_nodeVar855.x, p0_nodeVar855.y ), p0_nodeVar855.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 ) );

	} else {

		p0_nodeVar856 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar857 = picture_read( ( vec2<f32>( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), ( ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.y ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) + ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * ( ( floor( ( ( ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar856.x ) ) / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) ) / vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );
		p0_nodeVar853 = clamp( ( ( ( 1.0 - max( max( p0_nodeVar857.x, p0_nodeVar857.y ), p0_nodeVar857.z ) ) * f32(knobs.gcr) ) * f32(knobs.contrast) ), 0.0, 1.0 );

	}

	p0_nodeVar858 = ( ( ( ( f32(knobs.dotMin) + ( p0_nodeVar853 * f32(knobs.dotSize) ) ) + f32(knobs.dotGain) ) * f32(knobs.spacing) ) * 0.5 );

	if ( ( f32(knobs.shape) < 0.5 ) ) {

		p0_nodeVar860 = ( p0_nodeVar1 * p0_nodeVar2 );
		p0_nodeVar861 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar860.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar860.y ) );
		p0_nodeVar862 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar860.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar860.x ) );
		p0_nodeVar859 = length( vec2<f32>( ( p0_nodeVar861 - ( ( floor( ( ( p0_nodeVar861 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ), ( p0_nodeVar862 - ( ( floor( ( ( p0_nodeVar862 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

	} else {


		if ( ( f32(knobs.shape) < 1.5 ) ) {

			p0_nodeVar864 = ( p0_nodeVar1 * p0_nodeVar2 );
			p0_nodeVar865 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar864.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar864.y ) );
			p0_nodeVar866 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar864.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar864.x ) );
			p0_nodeVar863 = max( abs( ( p0_nodeVar865 - ( ( floor( ( ( p0_nodeVar865 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ), abs( ( p0_nodeVar866 - ( ( floor( ( ( p0_nodeVar866 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

		} else {


			if ( ( f32(knobs.shape) < 2.5 ) ) {

				p0_nodeVar868 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar869 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar868.x ) + ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar868.y ) );
				p0_nodeVar870 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar868.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar868.x ) );
				p0_nodeVar867 = ( abs( ( p0_nodeVar869 - ( ( floor( ( ( p0_nodeVar869 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) + abs( ( p0_nodeVar870 - ( ( floor( ( ( p0_nodeVar870 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) ) );

			} else {

				p0_nodeVar871 = ( p0_nodeVar1 * p0_nodeVar2 );
				p0_nodeVar872 = ( ( cos( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar871.y ) - ( sin( f32((0.017453292519943295 * knobs.keyAngle + -5.551115123125783e-17)) ) * p0_nodeVar871.x ) );
				p0_nodeVar867 = abs( ( p0_nodeVar872 - ( ( floor( ( ( p0_nodeVar872 / f32(knobs.spacing) ) + 0.5 ) ) * f32(knobs.spacing) ) + ( f32(knobs.spacing) * -1.0 ) ) ) );

			}

			p0_nodeVar863 = p0_nodeVar867;

		}

		p0_nodeVar859 = p0_nodeVar863;

	}

	p0_nodeVar873 = max( 0.01, ( ( p0_nodeVar686 / f32(knobs.spacing) ) * 0.5 ) );
	p0_nodeVar874 = clamp( f32(knobs.dotMorph), 0.0, 1.0 );
	p0_nodeVar875 = ( ( f32(knobs.spacing) * p0_nodeVar874 ) * 0.6 );
	p0_nodeVar876 = clamp( ( 1.0 - ( p0_nodeVar859 / max( ( p0_nodeVar858 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar877 = clamp( ( 1.0 - ( p0_nodeVar839 / max( ( p0_nodeVar838 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar878 = clamp( ( 1.0 - ( p0_nodeVar817 / max( ( p0_nodeVar816 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar879 = clamp( ( 1.0 - ( p0_nodeVar797 / max( ( p0_nodeVar796 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar880 = clamp( ( 1.0 - ( p0_nodeVar775 / max( ( p0_nodeVar774 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar881 = clamp( ( 1.0 - ( p0_nodeVar751 / max( ( p0_nodeVar750 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar882 = clamp( ( 1.0 - ( p0_nodeVar729 / max( ( p0_nodeVar728 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar883 = clamp( ( 1.0 - ( p0_nodeVar709 / max( ( p0_nodeVar708 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar884 = clamp( ( 1.0 - ( p0_nodeVar687 / max( ( p0_nodeVar685 + p0_nodeVar875 ), 0.001 ) ) ), 0.0, 1.0 );
	p0_nodeVar885 = mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( vec3<f32>(knobs.inkKey.x, knobs.inkKey.y, knobs.inkKey.z).x, vec3<f32>(knobs.inkKey.x, knobs.inkKey.y, knobs.inkKey.z).y, vec3<f32>(knobs.inkKey.x, knobs.inkKey.y, knobs.inkKey.z).z ), mix( max( smoothstep( ( p0_nodeVar685 + p0_nodeVar686 ), ( p0_nodeVar685 - p0_nodeVar686 ), p0_nodeVar687 ), max( smoothstep( ( p0_nodeVar708 + p0_nodeVar686 ), ( p0_nodeVar708 - p0_nodeVar686 ), p0_nodeVar709 ), max( smoothstep( ( p0_nodeVar728 + p0_nodeVar686 ), ( p0_nodeVar728 - p0_nodeVar686 ), p0_nodeVar729 ), max( smoothstep( ( p0_nodeVar750 + p0_nodeVar686 ), ( p0_nodeVar750 - p0_nodeVar686 ), p0_nodeVar751 ), max( smoothstep( ( p0_nodeVar774 + p0_nodeVar686 ), ( p0_nodeVar774 - p0_nodeVar686 ), p0_nodeVar775 ), max( smoothstep( ( p0_nodeVar796 + p0_nodeVar686 ), ( p0_nodeVar796 - p0_nodeVar686 ), p0_nodeVar797 ), max( smoothstep( ( p0_nodeVar816 + p0_nodeVar686 ), ( p0_nodeVar816 - p0_nodeVar686 ), p0_nodeVar817 ), max( smoothstep( ( p0_nodeVar838 + p0_nodeVar686 ), ( p0_nodeVar838 - p0_nodeVar686 ), p0_nodeVar839 ), max( smoothstep( ( p0_nodeVar858 + p0_nodeVar686 ), ( p0_nodeVar858 - p0_nodeVar686 ), p0_nodeVar859 ), 0.0 ) ) ) ) ) ) ) ) ), smoothstep( ( 0.5 - p0_nodeVar873 ), ( 0.5 + p0_nodeVar873 ), ( ( ( ( ( ( ( ( ( 0.0 + ( p0_nodeVar876 * p0_nodeVar876 ) ) + ( p0_nodeVar877 * p0_nodeVar877 ) ) + ( p0_nodeVar878 * p0_nodeVar878 ) ) + ( p0_nodeVar879 * p0_nodeVar879 ) ) + ( p0_nodeVar880 * p0_nodeVar880 ) ) + ( p0_nodeVar881 * p0_nodeVar881 ) ) + ( p0_nodeVar882 * p0_nodeVar882 ) ) + ( p0_nodeVar883 * p0_nodeVar883 ) ) + ( p0_nodeVar884 * p0_nodeVar884 ) ) ), p0_nodeVar874 ) );
	p0_nodeVar886 = vec3<f32>( ( p0_nodeVar4.x * p0_nodeVar885.x ), ( p0_nodeVar4.y * p0_nodeVar885.y ), ( p0_nodeVar4.z * p0_nodeVar885.z ) );
	p0_nodeVar887 = vec4<f32>( vec3<f32>( clamp( min( min( p0_nodeVar229.x, p0_nodeVar454.x ), min( p0_nodeVar679.x, p0_nodeVar886.x ) ), 0.0, 1.0 ), clamp( min( min( p0_nodeVar229.y, p0_nodeVar454.y ), min( p0_nodeVar679.y, p0_nodeVar886.y ) ), 0.0, 1.0 ), clamp( min( min( p0_nodeVar229.z, p0_nodeVar454.z ), min( p0_nodeVar679.z, p0_nodeVar886.z ) ), 0.0, 1.0 ) ), 1.0 );
	p0_nodeVar888 = vec3<f32>( p0_nodeVar887.x, p0_nodeVar887.y, p0_nodeVar887.z );
	p0_nodeVar889 = ( ( ( p0_nodeVar888.x * 0.2126 ) + ( p0_nodeVar888.y * 0.7152 ) ) + ( p0_nodeVar888.z * 0.0722 ) );
	p0_nodeVar890 = mix( vec3<f32>( p0_nodeVar889, p0_nodeVar889, p0_nodeVar889 ), p0_nodeVar888, f32(1.0) );
	p0_nodeVar891 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar890.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar890.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar890.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar890.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar890.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar890.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar890.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar890.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar890.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar887.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar891.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar891.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar892 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar892;

	// result

	p0_output.color = p0_nodeVar892;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

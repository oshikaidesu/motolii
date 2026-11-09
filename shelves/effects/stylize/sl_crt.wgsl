// CRT: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:An old CRT screen: scanlines, phosphor glow and signal noise.
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s0.5,s0.5
// --pass@t2:0,1,s0.25,s0.25
// --pass@t3:0,1,s0.125,s0.125
// --pass@t4:0,1,s0.0625,s0.0625
// --pass@t5:0,1,s0.125,s0.125
// --pass@t6:0,1,s0.25,s0.25
// --pass@t7:1,1,s1,s1
// --pass@:0,0,s1,s1
// --track@cellSize:Mask Scale,3,32,3,1
// --track@scanlineIntensity:Scanline Intensity,0,1,0.17,0.01
// --track@maskIntensity:Mask Intensity,0,1,1,0.01
// --track@barrelDistortion:Barrel Distortion,0,0.3,0.15,0.001
// --track@chromaticAberration:Convergence,0,2,2,0.01
// --track@beamFocus:Beam Focus,0,1,0.58,0.01
// --track@brightness:Brightness,0.5,100,1.2,0.01
// --track@highlightDrive:Highlight Drive,1,100,1,0.01
// --track@highlightThreshold:Highlight Threshold,0,1,0.62,0.01
// --track@shoulder:Shoulder,0,4,0.25,0.01
// --track@chromaRetention:Chroma Retention,0,2,1.15,0.01
// --track@shadowLift:Shadow Lift,0,1,0.16,0.01
// --track@persistence:Persistence,0,1,0.18,0.01
// --track@vignetteIntensity:Vignette,0,1,0.45,0.01
// --track@flickerIntensity:Flicker,0,0.2,0.2,0.01
// --track@glitchIntensity:Glitch,0,1,0.13,0.01
// --track@glitchSpeed:Glitch Speed,0.1,5,5,0.1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  cellSize: f32,
  scanlineIntensity: f32,
  maskIntensity: f32,
  barrelDistortion: f32,
  chromaticAberration: f32,
  beamFocus: f32,
  brightness: f32,
  highlightDrive: f32,
  highlightThreshold: f32,
  shoulder: f32,
  chromaRetention: f32,
  shadowLift: f32,
  persistence: f32,
  vignetteIntensity: f32,
  flickerIntensity: f32,
  glitchIntensity: f32,
  glitchSpeed: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var t1: texture_2d<f32>;
@group(0) @binding(5) var t1_sampler: sampler;
@group(0) @binding(6) var t2: texture_2d<f32>;
@group(0) @binding(7) var t2_sampler: sampler;
@group(0) @binding(8) var t3: texture_2d<f32>;
@group(0) @binding(9) var t3_sampler: sampler;
@group(0) @binding(10) var t4: texture_2d<f32>;
@group(0) @binding(11) var t4_sampler: sampler;
@group(0) @binding(12) var t5: texture_2d<f32>;
@group(0) @binding(13) var t5_sampler: sampler;
@group(0) @binding(14) var t6: texture_2d<f32>;
@group(0) @binding(15) var t6_sampler: sampler;
@group(0) @binding(16) var t7: texture_2d<f32>;
@group(0) @binding(17) var t7_sampler: sampler;
@group(0) @binding(18) var<uniform> knobs: Knobs;
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
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec3<f32>;
var<private> p0_nodeVar6 : vec3<f32>;
var<private> p0_nodeVar7 : vec3<f32>;
var<private> p0_nodeVar8 : vec3<f32>;
var<private> p0_nodeVar9 : vec3<f32>;
var<private> p0_nodeVar10 : vec3<f32>;
var<private> p0_nodeVar11 : vec3<f32>;
var<private> p0_nodeVar12 : vec3<f32>;
var<private> p0_nodeVar13 : vec3<f32>;
var<private> p0_nodeVar14 : vec3<f32>;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : vec4<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec3<f32>;
var<private> p0_nodeVar21 : vec4<f32>;
var<private> p0_nodeVar22 : vec4<f32>;
var<private> p0_nodeVar23 : vec4<f32>;
var<private> p0_nodeVar24 : vec4<f32>;
var<private> p0_nodeVar25 : vec4<f32>;
var<private> p0_nodeVar26 : vec4<f32>;
var<private> p0_nodeVar27 : vec4<f32>;
var<private> p0_nodeVar28 : vec4<f32>;
var<private> p0_nodeVar29 : vec4<f32>;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : vec4<f32>;
var<private> p0_nodeVar32 : vec3<f32>;
var<private> p0_nodeVar33 : vec3<f32>;
var<private> p0_nodeVar34 : vec3<f32>;
var<private> p0_nodeVar35 : vec3<f32>;
var<private> p0_nodeVar36 : vec4<f32>;
var<private> p0_nodeVar37 : vec4<f32>;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : vec3<f32>;
var<private> p0_nodeVar42 : vec3<f32>;
var<private> p0_nodeVar43 : vec3<f32>;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : vec3<f32>;
var<private> p0_nodeVar46 : vec3<f32>;
var<private> p0_nodeVar47 : vec3<f32>;
var<private> p0_nodeVar48 : vec3<f32>;
var<private> p0_nodeVar49 : vec3<f32>;
var<private> p0_nodeVar50 : vec3<f32>;
var<private> p0_nodeVar51 : vec4<f32>;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : vec4<f32>;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : vec3<f32>;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : vec4<f32>;
var<private> p0_nodeVar59 : vec4<f32>;
var<private> p0_nodeVar60 : vec4<f32>;
var<private> p0_nodeVar61 : vec4<f32>;
var<private> p0_nodeVar62 : vec4<f32>;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : vec4<f32>;
var<private> p0_nodeVar65 : vec4<f32>;
var<private> p0_nodeVar66 : vec4<f32>;
var<private> p0_nodeVar67 : vec4<f32>;
var<private> p0_nodeVar68 : vec3<f32>;
var<private> p0_nodeVar69 : vec3<f32>;
var<private> p0_nodeVar70 : vec3<f32>;
var<private> p0_nodeVar71 : vec3<f32>;
var<private> p0_nodeVar72 : vec4<f32>;
var<private> p0_nodeVar73 : vec4<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : vec2<f32>;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : bool;
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
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : f32;
var<private> p0_nodeVar108 : f32;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
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
var<private> p0_nodeVar144 : vec3<f32>;
var<private> p0_nodeVar145 : vec2<f32>;
var<private> p0_nodeVar146 : vec2<f32>;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : vec2<f32>;
var<private> p0_nodeVar149 : vec3<f32>;
var<private> p0_nodeVar150 : vec3<f32>;
var<private> p0_nodeVar151 : vec3<f32>;
var<private> p0_nodeVar152 : vec3<f32>;
var<private> p0_nodeVar153 : vec3<f32>;
var<private> p0_nodeVar154 : vec3<f32>;
var<private> p0_nodeVar155 : vec3<f32>;
var<private> p0_nodeVar156 : vec3<f32>;
var<private> p0_nodeVar157 : vec3<f32>;
var<private> p0_nodeVar158 : vec3<f32>;
var<private> p0_nodeVar159 : vec4<f32>;
var<private> p0_nodeVar160 : vec4<f32>;
var<private> p0_nodeVar161 : vec4<f32>;
var<private> p0_nodeVar162 : vec4<f32>;
var<private> p0_nodeVar163 : f32;
var<private> p0_nodeVar164 : vec3<f32>;
var<private> p0_nodeVar165 : vec4<f32>;
var<private> p0_nodeVar166 : vec4<f32>;
var<private> p0_nodeVar167 : vec4<f32>;
var<private> p0_nodeVar168 : vec4<f32>;
var<private> p0_nodeVar169 : vec4<f32>;
var<private> p0_nodeVar170 : vec4<f32>;
var<private> p0_nodeVar171 : vec4<f32>;
var<private> p0_nodeVar172 : vec4<f32>;
var<private> p0_nodeVar173 : vec4<f32>;
var<private> p0_nodeVar174 : vec4<f32>;
var<private> p0_nodeVar175 : vec4<f32>;
var<private> p0_nodeVar176 : vec3<f32>;
var<private> p0_nodeVar177 : vec3<f32>;
var<private> p0_nodeVar178 : vec3<f32>;
var<private> p0_nodeVar179 : vec3<f32>;
var<private> p0_nodeVar180 : vec4<f32>;
var<private> p0_nodeVar181 : vec4<f32>;
var<private> p0_nodeVar182 : vec2<f32>;
var<private> p0_nodeVar183 : vec2<f32>;
var<private> p0_nodeVar184 : vec2<f32>;
var<private> p0_nodeVar185 : vec2<f32>;
var<private> p0_nodeVar186 : vec2<f32>;
var<private> p0_nodeVar187 : vec4<f32>;
var<private> p0_nodeVar188 : vec3<f32>;
var<private> p0_nodeVar189 : f32;
var<private> p0_nodeVar190 : f32;
var<private> p0_nodeVar191 : vec2<f32>;
var<private> p0_nodeVar192 : vec4<f32>;
var<private> p0_nodeVar193 : vec3<f32>;
var<private> p0_nodeVar194 : f32;
var<private> p0_nodeVar195 : f32;
var<private> p0_nodeVar196 : vec3<f32>;
var<private> p0_nodeVar197 : f32;
var<private> p0_nodeVar198 : f32;
var<private> p0_nodeVar199 : vec2<f32>;
var<private> p0_nodeVar200 : vec4<f32>;
var<private> p0_nodeVar201 : vec3<f32>;
var<private> p0_nodeVar202 : f32;
var<private> p0_nodeVar203 : f32;
var<private> p0_nodeVar204 : vec4<f32>;
var<private> p0_nodeVar205 : vec3<f32>;
var<private> p0_nodeVar206 : f32;
var<private> p0_nodeVar207 : f32;
var<private> p0_nodeVar208 : f32;
var<private> p0_nodeVar209 : vec2<f32>;
var<private> p0_nodeVar210 : vec4<f32>;
var<private> p0_nodeVar211 : vec3<f32>;
var<private> p0_nodeVar212 : f32;
var<private> p0_nodeVar213 : f32;
var<private> p0_nodeVar214 : vec4<f32>;
var<private> p0_nodeVar215 : vec3<f32>;
var<private> p0_nodeVar216 : f32;
var<private> p0_nodeVar217 : f32;
var<private> p0_nodeVar218 : vec3<f32>;
var<private> p0_nodeVar219 : f32;
var<private> p0_nodeVar220 : vec2<f32>;
var<private> p0_nodeVar221 : vec4<f32>;
var<private> p0_nodeVar222 : vec3<f32>;
var<private> p0_nodeVar223 : f32;
var<private> p0_nodeVar224 : f32;
var<private> p0_nodeVar225 : vec2<f32>;
var<private> p0_nodeVar226 : vec4<f32>;
var<private> p0_nodeVar227 : vec3<f32>;
var<private> p0_nodeVar228 : f32;
var<private> p0_nodeVar229 : f32;
var<private> p0_nodeVar230 : vec4<f32>;
var<private> p0_nodeVar231 : vec3<f32>;
var<private> p0_nodeVar232 : f32;
var<private> p0_nodeVar233 : f32;
var<private> p0_nodeVar234 : vec2<f32>;
var<private> p0_nodeVar235 : vec4<f32>;
var<private> p0_nodeVar236 : vec3<f32>;
var<private> p0_nodeVar237 : f32;
var<private> p0_nodeVar238 : f32;
var<private> p0_nodeVar239 : vec2<f32>;
var<private> p0_nodeVar240 : vec4<f32>;
var<private> p0_nodeVar241 : vec3<f32>;
var<private> p0_nodeVar242 : f32;
var<private> p0_nodeVar243 : f32;
var<private> p0_nodeVar244 : vec4<f32>;
var<private> p0_nodeVar245 : vec3<f32>;
var<private> p0_nodeVar246 : f32;
var<private> p0_nodeVar247 : f32;
var<private> p0_nodeVar248 : vec3<f32>;
var<private> p0_nodeVar249 : vec3<f32>;
var<private> p0_nodeVar250 : vec3<f32>;
var<private> p0_nodeVar251 : vec3<f32>;
var<private> p0_nodeVar252 : vec3<f32>;
var<private> p0_nodeVar253 : vec3<f32>;
var<private> p0_nodeVar254 : vec3<f32>;
var<private> p0_nodeVar255 : vec3<f32>;
var<private> p0_nodeVar256 : vec3<f32>;
var<private> p0_nodeVar257 : vec3<f32>;
var<private> p0_nodeVar258 : vec3<f32>;
var<private> p0_nodeVar259 : vec4<f32>;
var<private> p0_nodeVar260 : vec4<f32>;
var<private> p0_nodeVar261 : vec4<f32>;
var<private> p0_nodeVar262 : vec4<f32>;
var<private> p0_nodeVar263 : f32;
var<private> p0_nodeVar264 : vec3<f32>;
var<private> p0_nodeVar265 : vec4<f32>;
var<private> p0_nodeVar266 : vec4<f32>;
var<private> p0_nodeVar267 : vec4<f32>;
var<private> p0_nodeVar268 : vec4<f32>;
var<private> p0_nodeVar269 : vec4<f32>;
var<private> p0_nodeVar270 : vec4<f32>;
var<private> p0_nodeVar271 : vec4<f32>;
var<private> p0_nodeVar272 : vec4<f32>;
var<private> p0_nodeVar273 : vec4<f32>;
var<private> p0_nodeVar274 : vec4<f32>;
var<private> p0_nodeVar275 : vec4<f32>;
var<private> p0_nodeVar276 : vec3<f32>;
var<private> p0_nodeVar277 : vec3<f32>;
var<private> p0_nodeVar278 : vec3<f32>;
var<private> p0_nodeVar279 : vec3<f32>;
var<private> p0_nodeVar280 : vec4<f32>;
var<private> p0_nodeVar281 : vec4<f32>;
var<private> p0_nodeVar282 : f32;
var<private> p0_nodeVar283 : f32;
var<private> p0_nodeVar284 : f32;
var<private> p0_nodeVar285 : f32;
var<private> p0_nodeVar286 : f32;
var<private> p0_nodeVar287 : vec3<f32>;
var<private> p0_nodeVar288 : vec3<f32>;
var<private> p0_nodeVar289 : vec3<f32>;
var<private> p0_nodeVar290 : vec3<f32>;
var<private> p0_nodeVar291 : vec3<f32>;
var<private> p0_nodeVar292 : vec3<f32>;
var<private> p0_nodeVar293 : vec3<f32>;
var<private> p0_nodeVar294 : vec3<f32>;
var<private> p0_nodeVar295 : vec3<f32>;
var<private> p0_nodeVar296 : vec3<f32>;
var<private> p0_nodeVar297 : vec4<f32>;
var<private> p0_nodeVar298 : vec4<f32>;
var<private> p0_nodeVar299 : vec4<f32>;
var<private> p0_nodeVar300 : vec4<f32>;
var<private> p0_nodeVar301 : f32;
var<private> p0_nodeVar302 : vec3<f32>;
var<private> p0_nodeVar303 : vec4<f32>;
var<private> p0_nodeVar304 : vec4<f32>;
var<private> p0_nodeVar305 : vec4<f32>;
var<private> p0_nodeVar306 : vec4<f32>;
var<private> p0_nodeVar307 : vec4<f32>;
var<private> p0_nodeVar308 : vec4<f32>;
var<private> p0_nodeVar309 : vec4<f32>;
var<private> p0_nodeVar310 : vec4<f32>;
var<private> p0_nodeVar311 : vec4<f32>;
var<private> p0_nodeVar312 : vec4<f32>;
var<private> p0_nodeVar313 : vec4<f32>;
var<private> p0_nodeVar314 : vec3<f32>;
var<private> p0_nodeVar315 : vec3<f32>;
var<private> p0_nodeVar316 : vec3<f32>;
var<private> p0_nodeVar317 : vec3<f32>;
var<private> p0_nodeVar318 : vec4<f32>;
var<private> p0_nodeVar319 : vec4<f32>;
var<private> p0_nodeVar320 : vec3<f32>;
var<private> p0_nodeVar321 : vec3<f32>;
var<private> p0_nodeVar322 : vec3<f32>;
var<private> p0_nodeVar323 : vec3<f32>;
var<private> p0_nodeVar324 : vec3<f32>;
var<private> p0_nodeVar325 : vec3<f32>;
var<private> p0_nodeVar326 : vec3<f32>;
var<private> p0_nodeVar327 : vec3<f32>;
var<private> p0_nodeVar328 : vec3<f32>;
var<private> p0_nodeVar329 : vec3<f32>;
var<private> p0_nodeVar330 : vec4<f32>;
var<private> p0_nodeVar331 : vec4<f32>;
var<private> p0_nodeVar332 : vec4<f32>;
var<private> p0_nodeVar333 : vec4<f32>;
var<private> p0_nodeVar334 : f32;
var<private> p0_nodeVar335 : vec3<f32>;
var<private> p0_nodeVar336 : vec4<f32>;
var<private> p0_nodeVar337 : vec4<f32>;
var<private> p0_nodeVar338 : vec4<f32>;
var<private> p0_nodeVar339 : vec4<f32>;
var<private> p0_nodeVar340 : vec4<f32>;
var<private> p0_nodeVar341 : vec4<f32>;
var<private> p0_nodeVar342 : vec4<f32>;
var<private> p0_nodeVar343 : vec4<f32>;
var<private> p0_nodeVar344 : vec4<f32>;
var<private> p0_nodeVar345 : vec4<f32>;
var<private> p0_nodeVar346 : vec4<f32>;
var<private> p0_nodeVar347 : vec3<f32>;
var<private> p0_nodeVar348 : vec3<f32>;
var<private> p0_nodeVar349 : vec3<f32>;
var<private> p0_nodeVar350 : vec3<f32>;
var<private> p0_nodeVar351 : vec4<f32>;
var<private> p0_nodeVar352 : vec4<f32>;
var<private> p0_nodeVar353 : vec3<f32>;
var<private> p0_nodeVar354 : vec3<f32>;
var<private> p0_nodeVar355 : f32;
var<private> p0_nodeVar356 : f32;
var<private> p0_nodeVar357 : f32;
var<private> p0_nodeVar358 : f32;
var<private> p0_nodeVar359 : f32;
var<private> p0_nodeVar360 : vec3<f32>;
var<private> p0_nodeVar361 : f32;
var<private> p0_nodeVar362 : f32;
var<private> p0_nodeVar363 : f32;
var<private> p0_nodeVar364 : f32;
var<private> p0_nodeVar365 : f32;
var<private> p0_nodeVar366 : f32;
var<private> p0_nodeVar367 : f32;
var<private> p0_nodeVar368 : f32;
var<private> p0_nodeVar369 : f32;
var<private> p0_nodeVar370 : vec2<f32>;
var<private> p0_nodeVar371 : vec4<f32>;
var<private> p0_nodeVar372 : vec3<f32>;
var<private> p0_nodeVar373 : f32;
var<private> p0_nodeVar374 : f32;
var<private> p0_nodeVar375 : vec4<f32>;
var<private> p0_nodeVar376 : vec3<f32>;
var<private> p0_nodeVar377 : f32;
var<private> p0_nodeVar378 : f32;
var<private> p0_nodeVar379 : vec2<f32>;
var<private> p0_nodeVar380 : vec4<f32>;
var<private> p0_nodeVar381 : vec3<f32>;
var<private> p0_nodeVar382 : f32;
var<private> p0_nodeVar383 : f32;
var<private> p0_nodeVar384 : vec4<f32>;
var<private> p0_nodeVar385 : vec3<f32>;
var<private> p0_nodeVar386 : f32;
var<private> p0_nodeVar387 : f32;
var<private> p0_nodeVar388 : vec3<f32>;
var<private> p0_nodeVar389 : f32;
var<private> p0_nodeVar390 : f32;
var<private> p0_nodeVar391 : f32;
var<private> p0_nodeVar392 : f32;
var<private> p0_nodeVar393 : f32;
var<private> p0_nodeVar394 : f32;
var<private> p0_nodeVar395 : vec2<f32>;
var<private> p0_nodeVar396 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar397 : vec4<f32>;

// codes
fn p0_tsl_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }
fn p0_tsl_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar1 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar2 = ( p0_nodeVar0 * p0_nodeVar1 );
	p0_nodeVar3 = max( f32(knobs.cellSize), 2.0 );
	p0_nodeVar4 = floor( ( p0_nodeVar2 / vec2<f32>( p0_nodeVar3 ) ) );
	p0_nodeVar5 = vec3<f32>( 0.0, p0_nodeVar4.y, 3.7 );
	p0_nodeVar6 = floor( ( p0_nodeVar5 + vec3<f32>( dot( p0_nodeVar5, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar7 = ( ( p0_nodeVar5 - p0_nodeVar6 ) + vec3<f32>( dot( p0_nodeVar6, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar8 = step( p0_nodeVar7.yzx, p0_nodeVar7 );
	p0_nodeVar9 = ( vec3<f32>( 1.0 ) - p0_nodeVar8 );
	p0_nodeVar10 = min( p0_nodeVar8, p0_nodeVar9.zxy );
	p0_nodeVar11 = max( p0_nodeVar8, p0_nodeVar9.zxy );
	p0_nodeVar12 = ( ( p0_nodeVar7 - p0_nodeVar10 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar13 = ( ( p0_nodeVar7 - p0_nodeVar11 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar14 = ( ( p0_nodeVar7 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar6 = p0_tsl_mod_vec3( p0_nodeVar6, vec3<f32>( 289.0 ) );
	p0_nodeVar15 = ( vec4<f32>( p0_nodeVar6.z ) + vec4<f32>( 0.0, p0_nodeVar10.z, p0_nodeVar11.z, 1.0 ) );
	p0_nodeVar16 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar15 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar15 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar6.y ) + vec4<f32>( 0.0, p0_nodeVar10.y, p0_nodeVar11.y, 1.0 ) ) );
	p0_nodeVar17 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar16 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar16 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar6.x ) + vec4<f32>( 0.0, p0_nodeVar10.x, p0_nodeVar11.x, 1.0 ) ) );
	p0_nodeVar18 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar17 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar17 ), vec4<f32>( 289.0 ) );
	p0_nodeVar19 = 0.14285714285714285;
	p0_nodeVar20 = ( ( vec3<f32>( p0_nodeVar19 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar21 = ( p0_nodeVar18 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar18 * vec4<f32>( ( p0_nodeVar20.z * p0_nodeVar20.z ) ) ) ) ) );
	p0_nodeVar22 = ( ( floor( ( p0_nodeVar21 * vec4<f32>( p0_nodeVar20.z ) ) ) * vec4<f32>( p0_nodeVar20.x ) ) + vec4<f32>( p0_nodeVar20, 1.0 ).yyyy );
	p0_nodeVar23 = ( ( floor( ( p0_nodeVar21 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar21 * vec4<f32>( p0_nodeVar20.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar20.x ) ) + vec4<f32>( p0_nodeVar20, 1.0 ).yyyy );
	p0_nodeVar24 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar22 ) - abs( p0_nodeVar23 ) ) );
	p0_nodeVar25 = vec4<f32>( p0_nodeVar22.xy, p0_nodeVar23.xy );
	p0_nodeVar26 = vec4<f32>( p0_nodeVar22.zw, p0_nodeVar23.zw );
	p0_nodeVar27 = ( ( floor( p0_nodeVar25 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar28 = ( ( floor( p0_nodeVar26 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar29 = ( - step( p0_nodeVar24, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar30 = ( p0_nodeVar25.xzyw + ( p0_nodeVar27.xzyw * p0_nodeVar29.xxyy ) );
	p0_nodeVar31 = ( p0_nodeVar26.xzyw + ( p0_nodeVar28.xzyw * p0_nodeVar29.zzww ) );
	p0_nodeVar32 = vec3<f32>( p0_nodeVar30.xy, p0_nodeVar24.x );
	p0_nodeVar33 = vec3<f32>( p0_nodeVar30.zw, p0_nodeVar24.y );
	p0_nodeVar34 = vec3<f32>( p0_nodeVar31.xy, p0_nodeVar24.z );
	p0_nodeVar35 = vec3<f32>( p0_nodeVar31.zw, p0_nodeVar24.w );
	p0_nodeVar36 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar32, p0_nodeVar32 ), dot( p0_nodeVar33, p0_nodeVar33 ), dot( p0_nodeVar34, p0_nodeVar34 ), dot( p0_nodeVar35, p0_nodeVar35 ) ) ) );
	p0_nodeVar32 = ( p0_nodeVar32 * vec3<f32>( p0_nodeVar36.x ) );
	p0_nodeVar33 = ( p0_nodeVar33 * vec3<f32>( p0_nodeVar36.y ) );
	p0_nodeVar34 = ( p0_nodeVar34 * vec3<f32>( p0_nodeVar36.z ) );
	p0_nodeVar35 = ( p0_nodeVar35 * vec3<f32>( p0_nodeVar36.w ) );
	p0_nodeVar37 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar7, p0_nodeVar7 ), dot( p0_nodeVar12, p0_nodeVar12 ), dot( p0_nodeVar13, p0_nodeVar13 ), dot( p0_nodeVar14, p0_nodeVar14 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar37 = ( p0_nodeVar37 * p0_nodeVar37 );
	p0_nodeVar38 = ( ( ( ( 42.0 * dot( ( p0_nodeVar37 * p0_nodeVar37 ), vec4<f32>( dot( p0_nodeVar32, p0_nodeVar7 ), dot( p0_nodeVar33, p0_nodeVar12 ), dot( p0_nodeVar34, p0_nodeVar13 ), dot( p0_nodeVar35, p0_nodeVar14 ) ) ) ) * 0.5 ) + 0.5 ) - 0.5 );
	p0_nodeVar39 = ( 0.16666666666666666 - ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar40 = mix( 0.72, 1.18, f32(knobs.maskIntensity) );
	p0_nodeVar41 = vec3<f32>( p0_nodeVar4.x, p0_nodeVar4.y, 9.3 );
	p0_nodeVar42 = floor( ( p0_nodeVar41 + vec3<f32>( dot( p0_nodeVar41, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar43 = ( ( p0_nodeVar41 - p0_nodeVar42 ) + vec3<f32>( dot( p0_nodeVar42, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar44 = step( p0_nodeVar43.yzx, p0_nodeVar43 );
	p0_nodeVar45 = ( vec3<f32>( 1.0 ) - p0_nodeVar44 );
	p0_nodeVar46 = min( p0_nodeVar44, p0_nodeVar45.zxy );
	p0_nodeVar47 = max( p0_nodeVar44, p0_nodeVar45.zxy );
	p0_nodeVar48 = ( ( p0_nodeVar43 - p0_nodeVar46 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar49 = ( ( p0_nodeVar43 - p0_nodeVar47 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar50 = ( ( p0_nodeVar43 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar42 = p0_tsl_mod_vec3( p0_nodeVar42, vec3<f32>( 289.0 ) );
	p0_nodeVar51 = ( vec4<f32>( p0_nodeVar42.z ) + vec4<f32>( 0.0, p0_nodeVar46.z, p0_nodeVar47.z, 1.0 ) );
	p0_nodeVar52 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar51 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar51 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar42.y ) + vec4<f32>( 0.0, p0_nodeVar46.y, p0_nodeVar47.y, 1.0 ) ) );
	p0_nodeVar53 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar52 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar52 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar42.x ) + vec4<f32>( 0.0, p0_nodeVar46.x, p0_nodeVar47.x, 1.0 ) ) );
	p0_nodeVar54 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar53 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar53 ), vec4<f32>( 289.0 ) );
	p0_nodeVar55 = 0.14285714285714285;
	p0_nodeVar56 = ( ( vec3<f32>( p0_nodeVar55 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar57 = ( p0_nodeVar54 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar54 * vec4<f32>( ( p0_nodeVar56.z * p0_nodeVar56.z ) ) ) ) ) );
	p0_nodeVar58 = ( ( floor( ( p0_nodeVar57 * vec4<f32>( p0_nodeVar56.z ) ) ) * vec4<f32>( p0_nodeVar56.x ) ) + vec4<f32>( p0_nodeVar56, 1.0 ).yyyy );
	p0_nodeVar59 = ( ( floor( ( p0_nodeVar57 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar57 * vec4<f32>( p0_nodeVar56.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar56.x ) ) + vec4<f32>( p0_nodeVar56, 1.0 ).yyyy );
	p0_nodeVar60 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar58 ) - abs( p0_nodeVar59 ) ) );
	p0_nodeVar61 = vec4<f32>( p0_nodeVar58.xy, p0_nodeVar59.xy );
	p0_nodeVar62 = vec4<f32>( p0_nodeVar58.zw, p0_nodeVar59.zw );
	p0_nodeVar63 = ( ( floor( p0_nodeVar61 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar64 = ( ( floor( p0_nodeVar62 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar65 = ( - step( p0_nodeVar60, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar66 = ( p0_nodeVar61.xzyw + ( p0_nodeVar63.xzyw * p0_nodeVar65.xxyy ) );
	p0_nodeVar67 = ( p0_nodeVar62.xzyw + ( p0_nodeVar64.xzyw * p0_nodeVar65.zzww ) );
	p0_nodeVar68 = vec3<f32>( p0_nodeVar66.xy, p0_nodeVar60.x );
	p0_nodeVar69 = vec3<f32>( p0_nodeVar66.zw, p0_nodeVar60.y );
	p0_nodeVar70 = vec3<f32>( p0_nodeVar67.xy, p0_nodeVar60.z );
	p0_nodeVar71 = vec3<f32>( p0_nodeVar67.zw, p0_nodeVar60.w );
	p0_nodeVar72 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar68, p0_nodeVar68 ), dot( p0_nodeVar69, p0_nodeVar69 ), dot( p0_nodeVar70, p0_nodeVar70 ), dot( p0_nodeVar71, p0_nodeVar71 ) ) ) );
	p0_nodeVar68 = ( p0_nodeVar68 * vec3<f32>( p0_nodeVar72.x ) );
	p0_nodeVar69 = ( p0_nodeVar69 * vec3<f32>( p0_nodeVar72.y ) );
	p0_nodeVar70 = ( p0_nodeVar70 * vec3<f32>( p0_nodeVar72.z ) );
	p0_nodeVar71 = ( p0_nodeVar71 * vec3<f32>( p0_nodeVar72.w ) );
	p0_nodeVar73 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar43, p0_nodeVar43 ), dot( p0_nodeVar48, p0_nodeVar48 ), dot( p0_nodeVar49, p0_nodeVar49 ), dot( p0_nodeVar50, p0_nodeVar50 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar73 = ( p0_nodeVar73 * p0_nodeVar73 );
	p0_nodeVar74 = ( ( ( ( 42.0 * dot( ( p0_nodeVar73 * p0_nodeVar73 ), vec4<f32>( dot( p0_nodeVar68, p0_nodeVar43 ), dot( p0_nodeVar69, p0_nodeVar48 ), dot( p0_nodeVar70, p0_nodeVar49 ), dot( p0_nodeVar71, p0_nodeVar50 ) ) ) ) * 0.5 ) + 0.5 ) - 0.5 );
	p0_nodeVar75 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar76 = vec2<f32>( fract( ( p0_nodeVar2.x / p0_nodeVar3 ) ), fract( ( p0_nodeVar2.y / p0_nodeVar3 ) ) );
	p0_nodeVar77 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar75 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar78 = ( p0_nodeVar39 - p0_nodeVar77 );
	p0_nodeVar79 = max( f32(knobs.cellSize), 2.0 );
	p0_nodeVar80 = ( ( 1.0 / p0_nodeVar79 ) / 3.0 );
	p0_nodeVar82 = ( p0_tsl_mod_float( p0_nodeVar4.y, 2.0 ) > 0.5 );

	if ( p0_nodeVar82 ) {

		p0_nodeVar81 = 0.5;

	} else {

		p0_nodeVar81 = 0.0;

	}

	p0_nodeVar83 = fract( ( ( p0_nodeVar76.x - p0_nodeVar80 ) + p0_nodeVar81 ) );
	p0_nodeVar84 = ( p0_nodeVar39 + p0_nodeVar77 );
	p0_nodeVar85 = ( 0.5 - p0_nodeVar75 );
	p0_nodeVar86 = ( 0.5 + p0_nodeVar75 );
	p0_nodeVar87 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar88 = ( ( ( 0.115 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.008 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar87 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar89 = ( 0.5 - p0_nodeVar88 );
	p0_nodeVar90 = ( 0.5 + p0_nodeVar88 );
	p0_nodeVar91 = ( 0.5 - p0_nodeVar87 );
	p0_nodeVar92 = ( 0.5 + p0_nodeVar87 );
	p0_nodeVar93 = ( 0.8333333333333334 + ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar94 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar95 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar94 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar96 = ( p0_nodeVar93 - p0_nodeVar95 );
	p0_nodeVar97 = ( p0_nodeVar93 + p0_nodeVar95 );
	p0_nodeVar98 = ( 0.5 - p0_nodeVar94 );
	p0_nodeVar99 = ( 0.5 + p0_nodeVar94 );
	p0_nodeVar100 = ( 0.16666666666666666 - ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar101 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar102 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar101 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar103 = ( p0_nodeVar100 - p0_nodeVar102 );

	if ( p0_nodeVar82 ) {

		p0_nodeVar104 = 0.5;

	} else {

		p0_nodeVar104 = 0.0;

	}

	p0_nodeVar105 = fract( ( p0_nodeVar76.x + p0_nodeVar104 ) );
	p0_nodeVar106 = ( p0_nodeVar100 + p0_nodeVar102 );
	p0_nodeVar107 = ( 0.5 - p0_nodeVar101 );
	p0_nodeVar108 = ( 0.5 + p0_nodeVar101 );
	p0_nodeVar109 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar110 = ( ( ( 0.115 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.008 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar109 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar111 = ( 0.5 - p0_nodeVar110 );
	p0_nodeVar112 = ( 0.5 + p0_nodeVar110 );
	p0_nodeVar113 = ( 0.5 - p0_nodeVar109 );
	p0_nodeVar114 = ( 0.5 + p0_nodeVar109 );
	p0_nodeVar115 = ( 0.8333333333333334 + ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar116 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar117 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar116 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar118 = ( p0_nodeVar115 - p0_nodeVar117 );
	p0_nodeVar119 = ( p0_nodeVar115 + p0_nodeVar117 );
	p0_nodeVar120 = ( 0.5 - p0_nodeVar116 );
	p0_nodeVar121 = ( 0.5 + p0_nodeVar116 );
	p0_nodeVar122 = ( 0.16666666666666666 - ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar123 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar124 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar123 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar125 = ( p0_nodeVar122 - p0_nodeVar124 );

	if ( p0_nodeVar82 ) {

		p0_nodeVar126 = 0.5;

	} else {

		p0_nodeVar126 = 0.0;

	}

	p0_nodeVar127 = fract( ( ( p0_nodeVar76.x + p0_nodeVar80 ) + p0_nodeVar126 ) );
	p0_nodeVar128 = ( p0_nodeVar122 + p0_nodeVar124 );
	p0_nodeVar129 = ( 0.5 - p0_nodeVar123 );
	p0_nodeVar130 = ( 0.5 + p0_nodeVar123 );
	p0_nodeVar131 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar132 = ( ( ( 0.115 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.008 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar131 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar133 = ( 0.5 - p0_nodeVar132 );
	p0_nodeVar134 = ( 0.5 + p0_nodeVar132 );
	p0_nodeVar135 = ( 0.5 - p0_nodeVar131 );
	p0_nodeVar136 = ( 0.5 + p0_nodeVar131 );
	p0_nodeVar137 = ( 0.8333333333333334 + ( p0_nodeVar38 * 0.01 ) );
	p0_nodeVar138 = ( 0.38 + ( abs( p0_nodeVar74 ) * 0.03 ) );
	p0_nodeVar139 = ( ( ( 0.12 * p0_nodeVar40 ) + ( p0_nodeVar74 * 0.01 ) ) * mix( 1.0, 0.38, smoothstep( ( p0_nodeVar138 * 0.42 ), 0.5, abs( ( p0_nodeVar76.y - 0.5 ) ) ) ) );
	p0_nodeVar140 = ( p0_nodeVar137 - p0_nodeVar139 );
	p0_nodeVar141 = ( p0_nodeVar137 + p0_nodeVar139 );
	p0_nodeVar142 = ( 0.5 - p0_nodeVar138 );
	p0_nodeVar143 = ( 0.5 + p0_nodeVar138 );
	p0_nodeVar144 = mix( vec3<f32>( 0.3333333333333333, 0.3333333333333333, 0.3333333333333333 ), ( ( ( vec3<f32>( ( ( smoothstep( ( p0_nodeVar78 - 0.015 ), p0_nodeVar78, p0_nodeVar83 ) * ( 1.0 - smoothstep( p0_nodeVar84, ( p0_nodeVar84 + 0.015 ), p0_nodeVar83 ) ) ) * ( smoothstep( ( p0_nodeVar85 - 0.015 ), p0_nodeVar85, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar86, ( p0_nodeVar86 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar89 - 0.015 ), p0_nodeVar89, p0_nodeVar83 ) * ( 1.0 - smoothstep( p0_nodeVar90, ( p0_nodeVar90 + 0.015 ), p0_nodeVar83 ) ) ) * ( smoothstep( ( p0_nodeVar91 - 0.015 ), p0_nodeVar91, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar92, ( p0_nodeVar92 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar96 - 0.015 ), p0_nodeVar96, p0_nodeVar83 ) * ( 1.0 - smoothstep( p0_nodeVar97, ( p0_nodeVar97 + 0.015 ), p0_nodeVar83 ) ) ) * ( smoothstep( ( p0_nodeVar98 - 0.015 ), p0_nodeVar98, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar99, ( p0_nodeVar99 + 0.015 ), p0_nodeVar76.y ) ) ) ) ) + vec3<f32>( ( ( smoothstep( ( p0_nodeVar103 - 0.015 ), p0_nodeVar103, p0_nodeVar105 ) * ( 1.0 - smoothstep( p0_nodeVar106, ( p0_nodeVar106 + 0.015 ), p0_nodeVar105 ) ) ) * ( smoothstep( ( p0_nodeVar107 - 0.015 ), p0_nodeVar107, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar108, ( p0_nodeVar108 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar111 - 0.015 ), p0_nodeVar111, p0_nodeVar105 ) * ( 1.0 - smoothstep( p0_nodeVar112, ( p0_nodeVar112 + 0.015 ), p0_nodeVar105 ) ) ) * ( smoothstep( ( p0_nodeVar113 - 0.015 ), p0_nodeVar113, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar114, ( p0_nodeVar114 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar118 - 0.015 ), p0_nodeVar118, p0_nodeVar105 ) * ( 1.0 - smoothstep( p0_nodeVar119, ( p0_nodeVar119 + 0.015 ), p0_nodeVar105 ) ) ) * ( smoothstep( ( p0_nodeVar120 - 0.015 ), p0_nodeVar120, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar121, ( p0_nodeVar121 + 0.015 ), p0_nodeVar76.y ) ) ) ) ) ) + vec3<f32>( ( ( smoothstep( ( p0_nodeVar125 - 0.015 ), p0_nodeVar125, p0_nodeVar127 ) * ( 1.0 - smoothstep( p0_nodeVar128, ( p0_nodeVar128 + 0.015 ), p0_nodeVar127 ) ) ) * ( smoothstep( ( p0_nodeVar129 - 0.015 ), p0_nodeVar129, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar130, ( p0_nodeVar130 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar133 - 0.015 ), p0_nodeVar133, p0_nodeVar127 ) * ( 1.0 - smoothstep( p0_nodeVar134, ( p0_nodeVar134 + 0.015 ), p0_nodeVar127 ) ) ) * ( smoothstep( ( p0_nodeVar135 - 0.015 ), p0_nodeVar135, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar136, ( p0_nodeVar136 + 0.015 ), p0_nodeVar76.y ) ) ) ), ( ( smoothstep( ( p0_nodeVar140 - 0.015 ), p0_nodeVar140, p0_nodeVar127 ) * ( 1.0 - smoothstep( p0_nodeVar141, ( p0_nodeVar141 + 0.015 ), p0_nodeVar127 ) ) ) * ( smoothstep( ( p0_nodeVar142 - 0.015 ), p0_nodeVar142, p0_nodeVar76.y ) * ( 1.0 - smoothstep( p0_nodeVar143, ( p0_nodeVar143 + 0.015 ), p0_nodeVar76.y ) ) ) ) ) ) / vec3<f32>( 3.0 ) ), smoothstep( 1.5, 3.5, p0_nodeVar79 ) );
	p0_nodeVar145 = ( ( ( p0_nodeVar4 + vec2<f32>( 0.5, 0.5 ) ) * vec2<f32>( p0_nodeVar3 ) ) / p0_nodeVar1 );
	p0_nodeVar146 = ( p0_nodeVar145 - vec2<f32>( 0.5, 0.5 ) );
	p0_nodeVar147 = ( ( ( 1.0 * 1.0 ) + ( 0.0 * 0.72 ) ) + ( 0.0 * 1.16 ) );
	p0_nodeVar148 = ( p0_nodeVar145 + ( ( ( p0_nodeVar146 * vec2<f32>( dot( p0_nodeVar146, p0_nodeVar146 ) ) ) * vec2<f32>( f32(knobs.barrelDistortion) ) ) * vec2<f32>( p0_nodeVar147 ) ) );
	p0_nodeVar149 = vec3<f32>( 0.0, ( p0_nodeVar4.y * 0.1 ), ( f32(knobs.time) * f32(knobs.glitchSpeed) ) );
	p0_nodeVar150 = floor( ( p0_nodeVar149 + vec3<f32>( dot( p0_nodeVar149, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar151 = ( ( p0_nodeVar149 - p0_nodeVar150 ) + vec3<f32>( dot( p0_nodeVar150, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar152 = step( p0_nodeVar151.yzx, p0_nodeVar151 );
	p0_nodeVar153 = ( vec3<f32>( 1.0 ) - p0_nodeVar152 );
	p0_nodeVar154 = min( p0_nodeVar152, p0_nodeVar153.zxy );
	p0_nodeVar155 = max( p0_nodeVar152, p0_nodeVar153.zxy );
	p0_nodeVar156 = ( ( p0_nodeVar151 - p0_nodeVar154 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar157 = ( ( p0_nodeVar151 - p0_nodeVar155 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar158 = ( ( p0_nodeVar151 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar150 = p0_tsl_mod_vec3( p0_nodeVar150, vec3<f32>( 289.0 ) );
	p0_nodeVar159 = ( vec4<f32>( p0_nodeVar150.z ) + vec4<f32>( 0.0, p0_nodeVar154.z, p0_nodeVar155.z, 1.0 ) );
	p0_nodeVar160 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar159 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar159 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar150.y ) + vec4<f32>( 0.0, p0_nodeVar154.y, p0_nodeVar155.y, 1.0 ) ) );
	p0_nodeVar161 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar160 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar160 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar150.x ) + vec4<f32>( 0.0, p0_nodeVar154.x, p0_nodeVar155.x, 1.0 ) ) );
	p0_nodeVar162 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar161 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar161 ), vec4<f32>( 289.0 ) );
	p0_nodeVar163 = 0.14285714285714285;
	p0_nodeVar164 = ( ( vec3<f32>( p0_nodeVar163 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar165 = ( p0_nodeVar162 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar162 * vec4<f32>( ( p0_nodeVar164.z * p0_nodeVar164.z ) ) ) ) ) );
	p0_nodeVar166 = ( ( floor( ( p0_nodeVar165 * vec4<f32>( p0_nodeVar164.z ) ) ) * vec4<f32>( p0_nodeVar164.x ) ) + vec4<f32>( p0_nodeVar164, 1.0 ).yyyy );
	p0_nodeVar167 = ( ( floor( ( p0_nodeVar165 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar165 * vec4<f32>( p0_nodeVar164.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar164.x ) ) + vec4<f32>( p0_nodeVar164, 1.0 ).yyyy );
	p0_nodeVar168 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar166 ) - abs( p0_nodeVar167 ) ) );
	p0_nodeVar169 = vec4<f32>( p0_nodeVar166.xy, p0_nodeVar167.xy );
	p0_nodeVar170 = vec4<f32>( p0_nodeVar166.zw, p0_nodeVar167.zw );
	p0_nodeVar171 = ( ( floor( p0_nodeVar169 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar172 = ( ( floor( p0_nodeVar170 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar173 = ( - step( p0_nodeVar168, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar174 = ( p0_nodeVar169.xzyw + ( p0_nodeVar171.xzyw * p0_nodeVar173.xxyy ) );
	p0_nodeVar175 = ( p0_nodeVar170.xzyw + ( p0_nodeVar172.xzyw * p0_nodeVar173.zzww ) );
	p0_nodeVar176 = vec3<f32>( p0_nodeVar174.xy, p0_nodeVar168.x );
	p0_nodeVar177 = vec3<f32>( p0_nodeVar174.zw, p0_nodeVar168.y );
	p0_nodeVar178 = vec3<f32>( p0_nodeVar175.xy, p0_nodeVar168.z );
	p0_nodeVar179 = vec3<f32>( p0_nodeVar175.zw, p0_nodeVar168.w );
	p0_nodeVar180 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar176, p0_nodeVar176 ), dot( p0_nodeVar177, p0_nodeVar177 ), dot( p0_nodeVar178, p0_nodeVar178 ), dot( p0_nodeVar179, p0_nodeVar179 ) ) ) );
	p0_nodeVar176 = ( p0_nodeVar176 * vec3<f32>( p0_nodeVar180.x ) );
	p0_nodeVar177 = ( p0_nodeVar177 * vec3<f32>( p0_nodeVar180.y ) );
	p0_nodeVar178 = ( p0_nodeVar178 * vec3<f32>( p0_nodeVar180.z ) );
	p0_nodeVar179 = ( p0_nodeVar179 * vec3<f32>( p0_nodeVar180.w ) );
	p0_nodeVar181 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar151, p0_nodeVar151 ), dot( p0_nodeVar156, p0_nodeVar156 ), dot( p0_nodeVar157, p0_nodeVar157 ), dot( p0_nodeVar158, p0_nodeVar158 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar181 = ( p0_nodeVar181 * p0_nodeVar181 );
	p0_nodeVar182 = clamp( vec2<f32>( ( p0_nodeVar148.x + ( ( ( 42.0 * dot( ( p0_nodeVar181 * p0_nodeVar181 ), vec4<f32>( dot( p0_nodeVar176, p0_nodeVar151 ), dot( p0_nodeVar177, p0_nodeVar156 ), dot( p0_nodeVar178, p0_nodeVar157 ), dot( p0_nodeVar179, p0_nodeVar158 ) ) ) ) * f32(knobs.glitchIntensity) ) * ( ( ( 1.0 * 0.003 ) + ( 0.0 * 0.007 ) ) + ( 0.0 * 0.0025 ) ) ) ), p0_nodeVar148.y ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) );
	p0_nodeVar183 = ( p0_nodeVar0 - vec2<f32>( 0.5, 0.5 ) );
	p0_nodeVar184 = ( ( vec2<f32>( ( ( f32(knobs.chromaticAberration) * pow( clamp( ( length( p0_nodeVar183 ) * 1.82 ), 0.0, 1.0 ), 2.0 ) ) * ( ( ( 1.0 * 1.0 ) + ( 0.0 * 0.82 ) ) + ( 0.0 * 1.18 ) ) ) ) / p0_nodeVar1 ) * vec2<f32>( 1.6 ) );
	p0_nodeVar185 = ( vec2<f32>( ( p0_nodeVar183.x * ( abs( p0_nodeVar183.x ) + 0.16 ) ), ( p0_nodeVar183.y * ( abs( p0_nodeVar183.y ) + 0.08 ) ) ) * p0_nodeVar184 );
	p0_nodeVar186 = clamp( ( p0_nodeVar182 + p0_nodeVar185 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) );
	p0_nodeVar187 = picture_read( p0_nodeVar186 );
	p0_nodeVar188 = vec3<f32>( p0_nodeVar187.x, p0_nodeVar187.y, p0_nodeVar187.z );
	p0_nodeVar189 = dot( p0_nodeVar188, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar190 = ( p0_nodeVar189 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar189 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar191 = vec2<f32>( ( 1.0 / max( f32(knobs.resolution.x), 1.0 ) ), ( 1.0 / max( f32(knobs.resolution.y), 1.0 ) ) );
	p0_nodeVar192 = picture_read( p0_nodeVar182 );
	p0_nodeVar193 = vec3<f32>( p0_nodeVar192.x, p0_nodeVar192.y, p0_nodeVar192.z );
	p0_nodeVar194 = dot( p0_nodeVar193, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar195 = ( p0_nodeVar194 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar194 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar196 = clamp( ( vec3<f32>( p0_nodeVar195, p0_nodeVar195, p0_nodeVar195 ) + ( p0_nodeVar193 - vec3<f32>( p0_nodeVar194, p0_nodeVar194, p0_nodeVar194 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) );
	p0_nodeVar197 = dot( p0_nodeVar196, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar198 = ( ( mix( ( p0_nodeVar3 * 0.8 ), 0.1, f32(knobs.beamFocus) ) * ( ( mix( 0.82, 1.34, smoothstep( 0.12, 0.95, p0_nodeVar197 ) ) * 0.15 ) + 0.92 ) ) * ( ( ( 1.0 * 1.0 ) + ( 0.0 * 0.72 ) ) + ( 0.0 * 1.4 ) ) );
	p0_nodeVar199 = vec2<f32>( ( p0_nodeVar191.x * p0_nodeVar198 ), 0.0 );
	p0_nodeVar200 = picture_read( clamp( ( p0_nodeVar186 - p0_nodeVar199 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar201 = vec3<f32>( p0_nodeVar200.x, p0_nodeVar200.y, p0_nodeVar200.z );
	p0_nodeVar202 = dot( p0_nodeVar201, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar203 = ( p0_nodeVar202 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar202 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar204 = picture_read( clamp( ( p0_nodeVar186 + p0_nodeVar199 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar205 = vec3<f32>( p0_nodeVar204.x, p0_nodeVar204.y, p0_nodeVar204.z );
	p0_nodeVar206 = dot( p0_nodeVar205, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar207 = ( p0_nodeVar206 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar206 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar208 = ( mix( ( p0_nodeVar3 * 0.6 ), 0.05, f32(knobs.beamFocus) ) * ( ( ( 1.0 * 1.0 ) + ( 0.0 * 0.84 ) ) + ( 0.0 * 1.3 ) ) );
	p0_nodeVar209 = vec2<f32>( 0.0, ( p0_nodeVar191.y * p0_nodeVar208 ) );
	p0_nodeVar210 = picture_read( clamp( ( p0_nodeVar182 - p0_nodeVar209 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar211 = vec3<f32>( p0_nodeVar210.x, p0_nodeVar210.y, p0_nodeVar210.z );
	p0_nodeVar212 = dot( p0_nodeVar211, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar213 = ( p0_nodeVar212 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar212 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar214 = picture_read( clamp( ( p0_nodeVar182 + p0_nodeVar209 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar215 = vec3<f32>( p0_nodeVar214.x, p0_nodeVar214.y, p0_nodeVar214.z );
	p0_nodeVar216 = dot( p0_nodeVar215, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar217 = ( p0_nodeVar216 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar216 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar218 = ( ( clamp( ( vec3<f32>( p0_nodeVar213, p0_nodeVar213, p0_nodeVar213 ) + ( p0_nodeVar211 - vec3<f32>( p0_nodeVar212, p0_nodeVar212, p0_nodeVar212 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) + clamp( ( vec3<f32>( p0_nodeVar217, p0_nodeVar217, p0_nodeVar217 ) + ( p0_nodeVar215 - vec3<f32>( p0_nodeVar216, p0_nodeVar216, p0_nodeVar216 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) * vec3<f32>( 0.5 ) );
	p0_nodeVar219 = ( smoothstep( 0.1, 1.5, p0_nodeVar208 ) * 0.45 );
	p0_nodeVar220 = clamp( ( p0_nodeVar182 + vec2<f32>( 0.0, ( p0_nodeVar184.y * -0.2 ) ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) );
	p0_nodeVar221 = picture_read( p0_nodeVar220 );
	p0_nodeVar222 = vec3<f32>( p0_nodeVar221.x, p0_nodeVar221.y, p0_nodeVar221.z );
	p0_nodeVar223 = dot( p0_nodeVar222, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar224 = ( p0_nodeVar223 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar223 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar225 = vec2<f32>( ( p0_nodeVar191.x * p0_nodeVar198 ), 0.0 );
	p0_nodeVar226 = picture_read( clamp( ( p0_nodeVar220 - p0_nodeVar225 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar227 = vec3<f32>( p0_nodeVar226.x, p0_nodeVar226.y, p0_nodeVar226.z );
	p0_nodeVar228 = dot( p0_nodeVar227, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar229 = ( p0_nodeVar228 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar228 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar230 = picture_read( clamp( ( p0_nodeVar220 + p0_nodeVar225 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar231 = vec3<f32>( p0_nodeVar230.x, p0_nodeVar230.y, p0_nodeVar230.z );
	p0_nodeVar232 = dot( p0_nodeVar231, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar233 = ( p0_nodeVar232 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar232 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar234 = clamp( ( p0_nodeVar182 - p0_nodeVar185 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) );
	p0_nodeVar235 = picture_read( p0_nodeVar234 );
	p0_nodeVar236 = vec3<f32>( p0_nodeVar235.x, p0_nodeVar235.y, p0_nodeVar235.z );
	p0_nodeVar237 = dot( p0_nodeVar236, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar238 = ( p0_nodeVar237 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar237 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar239 = vec2<f32>( ( p0_nodeVar191.x * p0_nodeVar198 ), 0.0 );
	p0_nodeVar240 = picture_read( clamp( ( p0_nodeVar234 - p0_nodeVar239 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar241 = vec3<f32>( p0_nodeVar240.x, p0_nodeVar240.y, p0_nodeVar240.z );
	p0_nodeVar242 = dot( p0_nodeVar241, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar243 = ( p0_nodeVar242 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar242 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar244 = picture_read( clamp( ( p0_nodeVar234 + p0_nodeVar239 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar245 = vec3<f32>( p0_nodeVar244.x, p0_nodeVar244.y, p0_nodeVar244.z );
	p0_nodeVar246 = dot( p0_nodeVar245, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar247 = ( p0_nodeVar246 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar246 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar248 = vec3<f32>( mix( ( ( clamp( ( vec3<f32>( p0_nodeVar190, p0_nodeVar190, p0_nodeVar190 ) + ( p0_nodeVar188 - vec3<f32>( p0_nodeVar189, p0_nodeVar189, p0_nodeVar189 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) * vec3<f32>( 0.5 ) ) + ( ( clamp( ( vec3<f32>( p0_nodeVar203, p0_nodeVar203, p0_nodeVar203 ) + ( p0_nodeVar201 - vec3<f32>( p0_nodeVar202, p0_nodeVar202, p0_nodeVar202 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) + clamp( ( vec3<f32>( p0_nodeVar207, p0_nodeVar207, p0_nodeVar207 ) + ( p0_nodeVar205 - vec3<f32>( p0_nodeVar206, p0_nodeVar206, p0_nodeVar206 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) * vec3<f32>( 0.25 ) ) ), p0_nodeVar218, p0_nodeVar219 ).x, mix( ( ( clamp( ( vec3<f32>( p0_nodeVar224, p0_nodeVar224, p0_nodeVar224 ) + ( p0_nodeVar222 - vec3<f32>( p0_nodeVar223, p0_nodeVar223, p0_nodeVar223 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) * vec3<f32>( 0.5 ) ) + ( ( clamp( ( vec3<f32>( p0_nodeVar229, p0_nodeVar229, p0_nodeVar229 ) + ( p0_nodeVar227 - vec3<f32>( p0_nodeVar228, p0_nodeVar228, p0_nodeVar228 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) + clamp( ( vec3<f32>( p0_nodeVar233, p0_nodeVar233, p0_nodeVar233 ) + ( p0_nodeVar231 - vec3<f32>( p0_nodeVar232, p0_nodeVar232, p0_nodeVar232 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) * vec3<f32>( 0.25 ) ) ), p0_nodeVar218, p0_nodeVar219 ).y, mix( ( ( clamp( ( vec3<f32>( p0_nodeVar238, p0_nodeVar238, p0_nodeVar238 ) + ( p0_nodeVar236 - vec3<f32>( p0_nodeVar237, p0_nodeVar237, p0_nodeVar237 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) * vec3<f32>( 0.5 ) ) + ( ( clamp( ( vec3<f32>( p0_nodeVar243, p0_nodeVar243, p0_nodeVar243 ) + ( p0_nodeVar241 - vec3<f32>( p0_nodeVar242, p0_nodeVar242, p0_nodeVar242 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) + clamp( ( vec3<f32>( p0_nodeVar247, p0_nodeVar247, p0_nodeVar247 ) + ( p0_nodeVar245 - vec3<f32>( p0_nodeVar246, p0_nodeVar246, p0_nodeVar246 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) * vec3<f32>( 0.25 ) ) ), p0_nodeVar218, p0_nodeVar219 ).z );
	p0_nodeVar249 = vec3<f32>( ( p0_nodeVar4.x + 0.19 ), p0_nodeVar4.y, 7.1 );
	p0_nodeVar250 = floor( ( p0_nodeVar249 + vec3<f32>( dot( p0_nodeVar249, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar251 = ( ( p0_nodeVar249 - p0_nodeVar250 ) + vec3<f32>( dot( p0_nodeVar250, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar252 = step( p0_nodeVar251.yzx, p0_nodeVar251 );
	p0_nodeVar253 = ( vec3<f32>( 1.0 ) - p0_nodeVar252 );
	p0_nodeVar254 = min( p0_nodeVar252, p0_nodeVar253.zxy );
	p0_nodeVar255 = max( p0_nodeVar252, p0_nodeVar253.zxy );
	p0_nodeVar256 = ( ( p0_nodeVar251 - p0_nodeVar254 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar257 = ( ( p0_nodeVar251 - p0_nodeVar255 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar258 = ( ( p0_nodeVar251 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar250 = p0_tsl_mod_vec3( p0_nodeVar250, vec3<f32>( 289.0 ) );
	p0_nodeVar259 = ( vec4<f32>( p0_nodeVar250.z ) + vec4<f32>( 0.0, p0_nodeVar254.z, p0_nodeVar255.z, 1.0 ) );
	p0_nodeVar260 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar259 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar259 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar250.y ) + vec4<f32>( 0.0, p0_nodeVar254.y, p0_nodeVar255.y, 1.0 ) ) );
	p0_nodeVar261 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar260 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar260 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar250.x ) + vec4<f32>( 0.0, p0_nodeVar254.x, p0_nodeVar255.x, 1.0 ) ) );
	p0_nodeVar262 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar261 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar261 ), vec4<f32>( 289.0 ) );
	p0_nodeVar263 = 0.14285714285714285;
	p0_nodeVar264 = ( ( vec3<f32>( p0_nodeVar263 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar265 = ( p0_nodeVar262 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar262 * vec4<f32>( ( p0_nodeVar264.z * p0_nodeVar264.z ) ) ) ) ) );
	p0_nodeVar266 = ( ( floor( ( p0_nodeVar265 * vec4<f32>( p0_nodeVar264.z ) ) ) * vec4<f32>( p0_nodeVar264.x ) ) + vec4<f32>( p0_nodeVar264, 1.0 ).yyyy );
	p0_nodeVar267 = ( ( floor( ( p0_nodeVar265 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar265 * vec4<f32>( p0_nodeVar264.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar264.x ) ) + vec4<f32>( p0_nodeVar264, 1.0 ).yyyy );
	p0_nodeVar268 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar266 ) - abs( p0_nodeVar267 ) ) );
	p0_nodeVar269 = vec4<f32>( p0_nodeVar266.xy, p0_nodeVar267.xy );
	p0_nodeVar270 = vec4<f32>( p0_nodeVar266.zw, p0_nodeVar267.zw );
	p0_nodeVar271 = ( ( floor( p0_nodeVar269 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar272 = ( ( floor( p0_nodeVar270 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar273 = ( - step( p0_nodeVar268, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar274 = ( p0_nodeVar269.xzyw + ( p0_nodeVar271.xzyw * p0_nodeVar273.xxyy ) );
	p0_nodeVar275 = ( p0_nodeVar270.xzyw + ( p0_nodeVar272.xzyw * p0_nodeVar273.zzww ) );
	p0_nodeVar276 = vec3<f32>( p0_nodeVar274.xy, p0_nodeVar268.x );
	p0_nodeVar277 = vec3<f32>( p0_nodeVar274.zw, p0_nodeVar268.y );
	p0_nodeVar278 = vec3<f32>( p0_nodeVar275.xy, p0_nodeVar268.z );
	p0_nodeVar279 = vec3<f32>( p0_nodeVar275.zw, p0_nodeVar268.w );
	p0_nodeVar280 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar276, p0_nodeVar276 ), dot( p0_nodeVar277, p0_nodeVar277 ), dot( p0_nodeVar278, p0_nodeVar278 ), dot( p0_nodeVar279, p0_nodeVar279 ) ) ) );
	p0_nodeVar276 = ( p0_nodeVar276 * vec3<f32>( p0_nodeVar280.x ) );
	p0_nodeVar277 = ( p0_nodeVar277 * vec3<f32>( p0_nodeVar280.y ) );
	p0_nodeVar278 = ( p0_nodeVar278 * vec3<f32>( p0_nodeVar280.z ) );
	p0_nodeVar279 = ( p0_nodeVar279 * vec3<f32>( p0_nodeVar280.w ) );
	p0_nodeVar281 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar251, p0_nodeVar251 ), dot( p0_nodeVar256, p0_nodeVar256 ), dot( p0_nodeVar257, p0_nodeVar257 ), dot( p0_nodeVar258, p0_nodeVar258 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar281 = ( p0_nodeVar281 * p0_nodeVar281 );
	p0_nodeVar282 = max( p0_nodeVar248.x, max( p0_nodeVar248.y, p0_nodeVar248.z ) );
	p0_nodeVar283 = max( p0_nodeVar282, 0.0001 );
	p0_nodeVar284 = ( ( ( 1.0 * 0.86 ) + ( 0.0 * 0.78 ) ) + ( 0.0 * 0.58 ) );
	p0_nodeVar285 = ( ( ( 0.0 * 0.12 ) + ( 1.0 * 0.04 ) ) + ( 0.0 * 0.03 ) );
	p0_nodeVar286 = ( ( ( 1.0 * 0.92 ) + ( 0.0 * 0.88 ) ) + ( 0.0 * 1.04 ) );
	p0_nodeVar287 = vec3<f32>( ( p0_nodeVar4.x + 0.41 ), p0_nodeVar4.y, 13.7 );
	p0_nodeVar288 = floor( ( p0_nodeVar287 + vec3<f32>( dot( p0_nodeVar287, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar289 = ( ( p0_nodeVar287 - p0_nodeVar288 ) + vec3<f32>( dot( p0_nodeVar288, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar290 = step( p0_nodeVar289.yzx, p0_nodeVar289 );
	p0_nodeVar291 = ( vec3<f32>( 1.0 ) - p0_nodeVar290 );
	p0_nodeVar292 = min( p0_nodeVar290, p0_nodeVar291.zxy );
	p0_nodeVar293 = max( p0_nodeVar290, p0_nodeVar291.zxy );
	p0_nodeVar294 = ( ( p0_nodeVar289 - p0_nodeVar292 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar295 = ( ( p0_nodeVar289 - p0_nodeVar293 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar296 = ( ( p0_nodeVar289 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar288 = p0_tsl_mod_vec3( p0_nodeVar288, vec3<f32>( 289.0 ) );
	p0_nodeVar297 = ( vec4<f32>( p0_nodeVar288.z ) + vec4<f32>( 0.0, p0_nodeVar292.z, p0_nodeVar293.z, 1.0 ) );
	p0_nodeVar298 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar297 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar297 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar288.y ) + vec4<f32>( 0.0, p0_nodeVar292.y, p0_nodeVar293.y, 1.0 ) ) );
	p0_nodeVar299 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar298 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar298 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar288.x ) + vec4<f32>( 0.0, p0_nodeVar292.x, p0_nodeVar293.x, 1.0 ) ) );
	p0_nodeVar300 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar299 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar299 ), vec4<f32>( 289.0 ) );
	p0_nodeVar301 = 0.14285714285714285;
	p0_nodeVar302 = ( ( vec3<f32>( p0_nodeVar301 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar303 = ( p0_nodeVar300 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar300 * vec4<f32>( ( p0_nodeVar302.z * p0_nodeVar302.z ) ) ) ) ) );
	p0_nodeVar304 = ( ( floor( ( p0_nodeVar303 * vec4<f32>( p0_nodeVar302.z ) ) ) * vec4<f32>( p0_nodeVar302.x ) ) + vec4<f32>( p0_nodeVar302, 1.0 ).yyyy );
	p0_nodeVar305 = ( ( floor( ( p0_nodeVar303 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar303 * vec4<f32>( p0_nodeVar302.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar302.x ) ) + vec4<f32>( p0_nodeVar302, 1.0 ).yyyy );
	p0_nodeVar306 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar304 ) - abs( p0_nodeVar305 ) ) );
	p0_nodeVar307 = vec4<f32>( p0_nodeVar304.xy, p0_nodeVar305.xy );
	p0_nodeVar308 = vec4<f32>( p0_nodeVar304.zw, p0_nodeVar305.zw );
	p0_nodeVar309 = ( ( floor( p0_nodeVar307 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar310 = ( ( floor( p0_nodeVar308 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar311 = ( - step( p0_nodeVar306, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar312 = ( p0_nodeVar307.xzyw + ( p0_nodeVar309.xzyw * p0_nodeVar311.xxyy ) );
	p0_nodeVar313 = ( p0_nodeVar308.xzyw + ( p0_nodeVar310.xzyw * p0_nodeVar311.zzww ) );
	p0_nodeVar314 = vec3<f32>( p0_nodeVar312.xy, p0_nodeVar306.x );
	p0_nodeVar315 = vec3<f32>( p0_nodeVar312.zw, p0_nodeVar306.y );
	p0_nodeVar316 = vec3<f32>( p0_nodeVar313.xy, p0_nodeVar306.z );
	p0_nodeVar317 = vec3<f32>( p0_nodeVar313.zw, p0_nodeVar306.w );
	p0_nodeVar318 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar314, p0_nodeVar314 ), dot( p0_nodeVar315, p0_nodeVar315 ), dot( p0_nodeVar316, p0_nodeVar316 ), dot( p0_nodeVar317, p0_nodeVar317 ) ) ) );
	p0_nodeVar314 = ( p0_nodeVar314 * vec3<f32>( p0_nodeVar318.x ) );
	p0_nodeVar315 = ( p0_nodeVar315 * vec3<f32>( p0_nodeVar318.y ) );
	p0_nodeVar316 = ( p0_nodeVar316 * vec3<f32>( p0_nodeVar318.z ) );
	p0_nodeVar317 = ( p0_nodeVar317 * vec3<f32>( p0_nodeVar318.w ) );
	p0_nodeVar319 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar289, p0_nodeVar289 ), dot( p0_nodeVar294, p0_nodeVar294 ), dot( p0_nodeVar295, p0_nodeVar295 ), dot( p0_nodeVar296, p0_nodeVar296 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar319 = ( p0_nodeVar319 * p0_nodeVar319 );
	p0_nodeVar320 = vec3<f32>( ( p0_nodeVar4.x + 0.73 ), p0_nodeVar4.y, 19.9 );
	p0_nodeVar321 = floor( ( p0_nodeVar320 + vec3<f32>( dot( p0_nodeVar320, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar322 = ( ( p0_nodeVar320 - p0_nodeVar321 ) + vec3<f32>( dot( p0_nodeVar321, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar323 = step( p0_nodeVar322.yzx, p0_nodeVar322 );
	p0_nodeVar324 = ( vec3<f32>( 1.0 ) - p0_nodeVar323 );
	p0_nodeVar325 = min( p0_nodeVar323, p0_nodeVar324.zxy );
	p0_nodeVar326 = max( p0_nodeVar323, p0_nodeVar324.zxy );
	p0_nodeVar327 = ( ( p0_nodeVar322 - p0_nodeVar325 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar328 = ( ( p0_nodeVar322 - p0_nodeVar326 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar329 = ( ( p0_nodeVar322 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar321 = p0_tsl_mod_vec3( p0_nodeVar321, vec3<f32>( 289.0 ) );
	p0_nodeVar330 = ( vec4<f32>( p0_nodeVar321.z ) + vec4<f32>( 0.0, p0_nodeVar325.z, p0_nodeVar326.z, 1.0 ) );
	p0_nodeVar331 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar330 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar330 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar321.y ) + vec4<f32>( 0.0, p0_nodeVar325.y, p0_nodeVar326.y, 1.0 ) ) );
	p0_nodeVar332 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar331 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar331 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar321.x ) + vec4<f32>( 0.0, p0_nodeVar325.x, p0_nodeVar326.x, 1.0 ) ) );
	p0_nodeVar333 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar332 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar332 ), vec4<f32>( 289.0 ) );
	p0_nodeVar334 = 0.14285714285714285;
	p0_nodeVar335 = ( ( vec3<f32>( p0_nodeVar334 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar336 = ( p0_nodeVar333 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar333 * vec4<f32>( ( p0_nodeVar335.z * p0_nodeVar335.z ) ) ) ) ) );
	p0_nodeVar337 = ( ( floor( ( p0_nodeVar336 * vec4<f32>( p0_nodeVar335.z ) ) ) * vec4<f32>( p0_nodeVar335.x ) ) + vec4<f32>( p0_nodeVar335, 1.0 ).yyyy );
	p0_nodeVar338 = ( ( floor( ( p0_nodeVar336 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar336 * vec4<f32>( p0_nodeVar335.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar335.x ) ) + vec4<f32>( p0_nodeVar335, 1.0 ).yyyy );
	p0_nodeVar339 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar337 ) - abs( p0_nodeVar338 ) ) );
	p0_nodeVar340 = vec4<f32>( p0_nodeVar337.xy, p0_nodeVar338.xy );
	p0_nodeVar341 = vec4<f32>( p0_nodeVar337.zw, p0_nodeVar338.zw );
	p0_nodeVar342 = ( ( floor( p0_nodeVar340 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar343 = ( ( floor( p0_nodeVar341 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar344 = ( - step( p0_nodeVar339, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar345 = ( p0_nodeVar340.xzyw + ( p0_nodeVar342.xzyw * p0_nodeVar344.xxyy ) );
	p0_nodeVar346 = ( p0_nodeVar341.xzyw + ( p0_nodeVar343.xzyw * p0_nodeVar344.zzww ) );
	p0_nodeVar347 = vec3<f32>( p0_nodeVar345.xy, p0_nodeVar339.x );
	p0_nodeVar348 = vec3<f32>( p0_nodeVar345.zw, p0_nodeVar339.y );
	p0_nodeVar349 = vec3<f32>( p0_nodeVar346.xy, p0_nodeVar339.z );
	p0_nodeVar350 = vec3<f32>( p0_nodeVar346.zw, p0_nodeVar339.w );
	p0_nodeVar351 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar347, p0_nodeVar347 ), dot( p0_nodeVar348, p0_nodeVar348 ), dot( p0_nodeVar349, p0_nodeVar349 ), dot( p0_nodeVar350, p0_nodeVar350 ) ) ) );
	p0_nodeVar347 = ( p0_nodeVar347 * vec3<f32>( p0_nodeVar351.x ) );
	p0_nodeVar348 = ( p0_nodeVar348 * vec3<f32>( p0_nodeVar351.y ) );
	p0_nodeVar349 = ( p0_nodeVar349 * vec3<f32>( p0_nodeVar351.z ) );
	p0_nodeVar350 = ( p0_nodeVar350 * vec3<f32>( p0_nodeVar351.w ) );
	p0_nodeVar352 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar322, p0_nodeVar322 ), dot( p0_nodeVar327, p0_nodeVar327 ), dot( p0_nodeVar328, p0_nodeVar328 ), dot( p0_nodeVar329, p0_nodeVar329 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar352 = ( p0_nodeVar352 * p0_nodeVar352 );
	p0_nodeVar353 = clamp( vec3<f32>( pow( clamp( ( ( ( p0_nodeVar248.x * mix( 0.82, 1.18, ( ( ( 42.0 * dot( ( p0_nodeVar281 * p0_nodeVar281 ), vec4<f32>( dot( p0_nodeVar276, p0_nodeVar251 ), dot( p0_nodeVar277, p0_nodeVar256 ), dot( p0_nodeVar278, p0_nodeVar257 ), dot( p0_nodeVar279, p0_nodeVar258 ) ) ) ) * 0.5 ) + 0.5 ) ) ) * mix( 1.0, pow( clamp( ( p0_nodeVar248.x / p0_nodeVar283 ), 0.0, 1.0 ), 0.82 ), p0_nodeVar284 ) ) + ( p0_nodeVar282 * p0_nodeVar285 ) ), 0.0, 1.0 ), p0_nodeVar286 ), pow( clamp( ( ( ( p0_nodeVar248.y * mix( 0.84, 1.16, ( ( ( 42.0 * dot( ( p0_nodeVar319 * p0_nodeVar319 ), vec4<f32>( dot( p0_nodeVar314, p0_nodeVar289 ), dot( p0_nodeVar315, p0_nodeVar294 ), dot( p0_nodeVar316, p0_nodeVar295 ), dot( p0_nodeVar317, p0_nodeVar296 ) ) ) ) * 0.5 ) + 0.5 ) ) ) * mix( 1.0, pow( clamp( ( p0_nodeVar248.y / p0_nodeVar283 ), 0.0, 1.0 ), 0.82 ), p0_nodeVar284 ) ) + ( p0_nodeVar282 * p0_nodeVar285 ) ), 0.0, 1.0 ), p0_nodeVar286 ), pow( clamp( ( ( ( p0_nodeVar248.z * mix( 0.8, 1.2, ( ( ( 42.0 * dot( ( p0_nodeVar352 * p0_nodeVar352 ), vec4<f32>( dot( p0_nodeVar347, p0_nodeVar322 ), dot( p0_nodeVar348, p0_nodeVar327 ), dot( p0_nodeVar349, p0_nodeVar328 ), dot( p0_nodeVar350, p0_nodeVar329 ) ) ) ) * 0.5 ) + 0.5 ) ) ) * mix( 1.0, pow( clamp( ( p0_nodeVar248.z / p0_nodeVar283 ), 0.0, 1.0 ), 0.82 ), p0_nodeVar284 ) ) + ( p0_nodeVar282 * p0_nodeVar285 ) ), 0.0, 1.0 ), p0_nodeVar286 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) );
	p0_nodeVar354 = vec3<f32>( ( p0_nodeVar248.x * p0_nodeVar353.x ), ( p0_nodeVar248.y * p0_nodeVar353.y ), ( p0_nodeVar248.z * p0_nodeVar353.z ) );
	p0_nodeVar355 = dot( p0_nodeVar354, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar356 = smoothstep( f32(knobs.highlightThreshold), 1.0, p0_nodeVar197 );
	p0_nodeVar357 = ( mix( 1.0, f32(knobs.brightness), smoothstep( 0.22, 0.98, p0_nodeVar197 ) ) * mix( 1.0, f32(knobs.highlightDrive), p0_nodeVar356 ) );
	p0_nodeVar358 = ( ( p0_nodeVar355 * p0_nodeVar357 ) * mix( 1.0, ( ( f32(knobs.shadowLift) * 0.35 ) + 1.0 ), smoothstep( 0.42, 0.02, p0_nodeVar197 ) ) );
	p0_nodeVar359 = mix( p0_nodeVar358, ( p0_nodeVar358 / ( ( p0_nodeVar358 * ( ( f32(knobs.shoulder) * p0_nodeVar356 ) * 0.15 ) ) + 1.0 ) ), smoothstep( 0.05, 1.0, p0_nodeVar356 ) );
	p0_nodeVar360 = ( vec3<f32>( p0_nodeVar359, p0_nodeVar359, p0_nodeVar359 ) + ( ( p0_nodeVar354 - vec3<f32>( p0_nodeVar355, p0_nodeVar355, p0_nodeVar355 ) ) * vec3<f32>( mix( 1.0, ( f32(knobs.chromaRetention) * mix( 1.0, p0_nodeVar357, 0.18 ) ), smoothstep( 0.18, 0.95, p0_nodeVar197 ) ) ) ) );
	p0_nodeVar361 = ( ( ( p0_nodeVar360.x + p0_nodeVar360.y ) + p0_nodeVar360.z ) / 3.0 );
	p0_nodeVar362 = min( p0_nodeVar360.x, min( p0_nodeVar360.y, p0_nodeVar360.z ) );
	p0_nodeVar363 = max( p0_nodeVar360.x, max( p0_nodeVar360.y, p0_nodeVar360.z ) );
	p0_nodeVar364 = ( ( smoothstep( 0.24, 0.82, p0_nodeVar361 ) * smoothstep( 0.55, 0.96, clamp( ( p0_nodeVar362 / max( p0_nodeVar363, 0.0001 ) ), 0.0, 1.0 ) ) ) * mix( 0.03, 0.18, pow( clamp( ( p0_nodeVar361 / max( p0_nodeVar363, 0.0001 ) ), 0.0, 1.0 ), 0.72 ) ) );
	p0_nodeVar365 = ( ( mix( 0.48, 0.21, f32(knobs.scanlineIntensity) ) * mix( 0.82, 1.18, smoothstep( 0.08, 1.0, p0_nodeVar197 ) ) ) * mix( 1.0, 1.12, 0.0 ) );
	p0_nodeVar366 = ( 0.5 - p0_nodeVar365 );
	p0_nodeVar367 = fract( ( p0_nodeVar2.y / max( f32(knobs.cellSize), 2.0 ) ) );
	p0_nodeVar368 = ( 0.5 + p0_nodeVar365 );
	p0_nodeVar369 = ( smoothstep( ( p0_nodeVar366 - 0.12 ), p0_nodeVar366, p0_nodeVar367 ) * ( 1.0 - smoothstep( p0_nodeVar368, ( p0_nodeVar368 + 0.12 ), p0_nodeVar367 ) ) );
	p0_nodeVar370 = vec2<f32>( ( p0_nodeVar191.x * 2.2 ), 0.0 );
	p0_nodeVar371 = picture_read( clamp( ( p0_nodeVar182 - p0_nodeVar370 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar372 = vec3<f32>( p0_nodeVar371.x, p0_nodeVar371.y, p0_nodeVar371.z );
	p0_nodeVar373 = dot( p0_nodeVar372, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar374 = ( p0_nodeVar373 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar373 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar375 = picture_read( clamp( ( p0_nodeVar182 + p0_nodeVar370 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar376 = vec3<f32>( p0_nodeVar375.x, p0_nodeVar375.y, p0_nodeVar375.z );
	p0_nodeVar377 = dot( p0_nodeVar376, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar378 = ( p0_nodeVar377 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar377 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar379 = vec2<f32>( 0.0, ( p0_nodeVar191.y * 1.6 ) );
	p0_nodeVar380 = picture_read( clamp( ( p0_nodeVar182 - p0_nodeVar379 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar381 = vec3<f32>( p0_nodeVar380.x, p0_nodeVar380.y, p0_nodeVar380.z );
	p0_nodeVar382 = dot( p0_nodeVar381, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar383 = ( p0_nodeVar382 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar382 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar384 = picture_read( clamp( ( p0_nodeVar182 + p0_nodeVar379 ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar385 = vec3<f32>( p0_nodeVar384.x, p0_nodeVar384.y, p0_nodeVar384.z );
	p0_nodeVar386 = dot( p0_nodeVar385, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
	p0_nodeVar387 = ( p0_nodeVar386 + ( ( smoothstep( 0.38, 0.02, p0_nodeVar386 ) * f32(knobs.shadowLift) ) * 0.08 ) );
	p0_nodeVar388 = ( ( ( ( clamp( ( vec3<f32>( p0_nodeVar374, p0_nodeVar374, p0_nodeVar374 ) + ( p0_nodeVar372 - vec3<f32>( p0_nodeVar373, p0_nodeVar373, p0_nodeVar373 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) + clamp( ( vec3<f32>( p0_nodeVar378, p0_nodeVar378, p0_nodeVar378 ) + ( p0_nodeVar376 - vec3<f32>( p0_nodeVar377, p0_nodeVar377, p0_nodeVar377 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) + clamp( ( vec3<f32>( p0_nodeVar383, p0_nodeVar383, p0_nodeVar383 ) + ( p0_nodeVar381 - vec3<f32>( p0_nodeVar382, p0_nodeVar382, p0_nodeVar382 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) + clamp( ( vec3<f32>( p0_nodeVar387, p0_nodeVar387, p0_nodeVar387 ) + ( p0_nodeVar385 - vec3<f32>( p0_nodeVar386, p0_nodeVar386, p0_nodeVar386 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) ) * vec3<f32>( 0.25 ) );
	p0_nodeVar389 = max( p0_nodeVar196.x, max( p0_nodeVar196.y, p0_nodeVar196.z ) );
	p0_nodeVar390 = smoothstep( 0.58, 0.98, p0_nodeVar389 );
	p0_nodeVar391 = max( p0_nodeVar196.x, max( p0_nodeVar196.y, p0_nodeVar196.z ) );
	p0_nodeVar392 = ( length( p0_nodeVar183 ) * 2.0 );
	p0_nodeVar393 = ( f32(knobs.time) * 8.0 );
	p0_nodeVar395 = ( p0_nodeVar0 + ( ( ( p0_nodeVar183 * vec2<f32>( dot( p0_nodeVar183, p0_nodeVar183 ) ) ) * vec2<f32>( f32(knobs.barrelDistortion) ) ) * vec2<f32>( p0_nodeVar147 ) ) );

	if ( ( ( ( ( p0_nodeVar395.x >= 0.0 ) && ( p0_nodeVar395.x <= 1.0 ) ) && ( p0_nodeVar395.y >= 0.0 ) ) && ( p0_nodeVar395.y <= 1.0 ) ) ) {

		p0_nodeVar394 = 1.0;

	} else {

		p0_nodeVar394 = 0.0;

	}

	p0_nodeVar396 = target_read( t7, t7_sampler, p0_nodeVar0 );
	p0_DiffuseColor = vec4<f32>( ( ( ( ( ( ( ( ( clamp( ( ( vec3<f32>( ( p0_nodeVar144.x * p0_nodeVar360.x ), ( p0_nodeVar144.y * p0_nodeVar360.y ), ( p0_nodeVar144.z * p0_nodeVar360.z ) ) * vec3<f32>( ( ( ( 1.0 * 2.8 ) + ( 0.0 * 2.4 ) ) + ( 0.0 * 2.6 ) ) ) ) + ( ( ( vec3<f32>( p0_nodeVar364, p0_nodeVar364, p0_nodeVar364 ) * ( ( p0_nodeVar144 + vec3<f32>( p0_nodeVar362, p0_nodeVar362, p0_nodeVar362 ) ) / vec3<f32>( 4.0 ) ) ) * vec3<f32>( ( ( ( 1.0 * 0.34 ) + ( 0.0 * 0.28 ) ) + ( 0.0 * 0.46 ) ) ) ) * vec3<f32>( mix( 1.0, p0_nodeVar357, smoothstep( 0.52, 1.0, p0_nodeVar361 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) * mix( vec3<f32>( 1.0, 1.0, 1.0 ), vec3<f32>( p0_nodeVar369, p0_nodeVar369, p0_nodeVar369 ), f32(knobs.scanlineIntensity) ) ) + ( vec3<f32>( p0_nodeVar388.x, p0_nodeVar388.y, p0_nodeVar388.z ) * vec3<f32>( ( smoothstep( 0.45, 1.0, p0_nodeVar197 ) * ( ( ( 1.0 * 0.04 ) + ( 0.0 * 0.03 ) ) + ( 0.0 * 0.07 ) ) ) ) ) ) + ( ( mix( p0_nodeVar196, mix( vec3<f32>( p0_nodeVar197, p0_nodeVar197, p0_nodeVar197 ), vec3<f32>( ( p0_nodeVar197 * 1.03 ), ( p0_nodeVar197 * 0.99 ), ( p0_nodeVar197 * 0.96 ) ), ( ( 1.0 * 0.18 ) + ( 0.0 * 0.28 ) ) ), ( ( ( smoothstep( 0.55, 0.94, p0_nodeVar197 ) * smoothstep( 0.62, 0.98, clamp( ( min( p0_nodeVar196.x, min( p0_nodeVar196.y, p0_nodeVar196.z ) ) / max( p0_nodeVar389, 0.0001 ) ), 0.0, 1.0 ) ) ) * mix( 0.04, 0.18, p0_nodeVar390 ) ) * mix( 1.0, 0.55, clamp( ( f32(knobs.chromaRetention) - 1.0 ), 0.0, 1.0 ) ) ) ) * vec3<f32>( smoothstep( 0.42, 0.18, length( ( p0_nodeVar76 - vec2<f32>( 0.5, 0.5 ) ) ) ) ) ) * vec3<f32>( ( ( p0_nodeVar390 * p0_nodeVar197 ) * ( ( ( 1.0 * 0.04 ) + ( 0.0 * 0.03 ) ) + ( 0.0 * 0.08 ) ) ) ) ) ) + ( ( mix( p0_nodeVar196, vec3<f32>( p0_nodeVar391, p0_nodeVar391, p0_nodeVar391 ), 0.86 ) * vec3<f32>( smoothstep( 0.44, 0.02, length( ( p0_nodeVar76 - vec2<f32>( 0.5, 0.5 ) ) ) ) ) ) * vec3<f32>( ( ( ( smoothstep( 0.62, 0.98, p0_nodeVar391 ) * smoothstep( 0.42, 0.92, p0_nodeVar197 ) ) * mix( 0.32, 0.9, clamp( ( min( p0_nodeVar196.x, min( p0_nodeVar196.y, p0_nodeVar196.z ) ) / max( p0_nodeVar391, 0.0001 ) ), 0.0, 1.0 ) ) ) * ( ( ( 1.0 * 0.95 ) + ( 0.0 * 0.78 ) ) + ( 0.0 * 1.08 ) ) ) ) ) ) * vec3<f32>( clamp( ( 1.0 - ( ( p0_nodeVar392 * p0_nodeVar392 ) * ( f32(knobs.vignetteIntensity) * ( ( ( 1.0 * 1.0 ) + ( 0.0 * 0.82 ) ) + ( 0.0 * 1.1 ) ) ) ) ), 0.0, 1.0 ) ) ) * vec3<f32>( ( 1.0 + ( ( ( ( sin( p0_nodeVar393 ) * 0.6 ) + ( sin( ( p0_nodeVar393 * 2.3 ) ) * 0.3 ) ) + ( sin( ( p0_nodeVar393 * 5.7 ) ) * 0.1 ) ) * f32(knobs.flickerIntensity) ) ) ) ) * vec3<f32>( p0_nodeVar394 ) ) + ( ( vec3<f32>( p0_nodeVar396.x, p0_nodeVar396.y, p0_nodeVar396.z ) * vec3<f32>( mix( 0.0, 0.92, f32(knobs.persistence) ), mix( 0.0, 0.96, f32(knobs.persistence) ), mix( 0.0, 0.88, f32(knobs.persistence) ) ) ) * vec3<f32>( 0.55 ) ) ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar397 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar397;

	// result

	p0_output.color = p0_nodeVar397;

	return p0_output;

}

// structs

struct p1_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p1_output : p1_OutputStruct;

// uniforms


// vars
var<private> p1_DiffuseColor : vec4<f32>;
var<private> p1_nodeVar0 : vec4<f32>;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar1 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p1_DiffuseColor = vec4<f32>( ( p1_nodeVar0.xyz * vec3<f32>( smoothstep( f32(0.0), ( f32(0.0) + max( f32(0.0775), 0.0001 ) ), dot( p1_nodeVar0.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) ) ), 1.0 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_DiffuseColor.w = 1.0;
	p1_nodeVar1 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar1;

	// result

	p1_output.color = p1_nodeVar1;

	return p1_output;

}

// structs

struct p2_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p2_output : p2_OutputStruct;

// uniforms


// vars
var<private> p2_DiffuseColor : vec4<f32>;
var<private> p2_nodeVar0 : vec2<f32>;
var<private> p2_nodeVar1 : vec4<f32>;
var<private> p2_nodeVar2 : vec4<f32>;
var<private> p2_nodeVar3 : vec4<f32>;
var<private> p2_nodeVar4 : vec4<f32>;
var<private> p2_nodeVar5 : vec4<f32>;
var<private> p2_nodeVar6 : vec4<f32>;
var<private> p2_nodeVar7 : vec4<f32>;
var<private> p2_nodeVar8 : vec4<f32>;
var<private> p2_nodeVar9 : vec4<f32>;
var<private> p2_nodeVar10 : vec4<f32>;
var<private> p2_nodeVar11 : vec4<f32>;
var<private> p2_nodeVar12 : vec4<f32>;
var<private> p2_nodeVar13 : vec4<f32>;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar14 : vec4<f32>;

// codes


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p2_nodeVar1 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 0.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 0.0 ) ) ) );
	p2_nodeVar2 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * -1.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * -1.0 ) ) ) );
	p2_nodeVar3 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 1.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * -1.0 ) ) ) );
	p2_nodeVar4 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * -1.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 1.0 ) ) ) );
	p2_nodeVar5 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 1.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 1.0 ) ) ) );
	p2_nodeVar6 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * -2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 0.0 ) ) ) );
	p2_nodeVar7 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 0.0 ) ) ) );
	p2_nodeVar8 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 0.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * -2.0 ) ) ) );
	p2_nodeVar9 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 0.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 2.0 ) ) ) );
	p2_nodeVar10 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * -2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * -2.0 ) ) ) );
	p2_nodeVar11 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * -2.0 ) ) ) );
	p2_nodeVar12 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * -2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 2.0 ) ) ) );
	p2_nodeVar13 = target_read( t1, t1_sampler, ( p2_nodeVar0 + vec2<f32>( ( vec2<f32>(0.0009765625, 0.001953125).x * 2.0 ), ( vec2<f32>(0.0009765625, 0.001953125).y * 2.0 ) ) ) );
	p2_DiffuseColor = vec4<f32>( ( ( ( ( p2_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p2_nodeVar2.xyz + p2_nodeVar3.xyz ) + ( p2_nodeVar4.xyz + p2_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p2_nodeVar6.xyz + p2_nodeVar7.xyz ) + ( p2_nodeVar8.xyz + p2_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p2_nodeVar10.xyz + p2_nodeVar11.xyz ) + ( p2_nodeVar12.xyz + p2_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_DiffuseColor.w = 1.0;
	p2_nodeVar14 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar14;

	// result

	p2_output.color = p2_nodeVar14;

	return p2_output;

}

// structs

struct p3_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p3_output : p3_OutputStruct;

// uniforms


// vars
var<private> p3_DiffuseColor : vec4<f32>;
var<private> p3_nodeVar0 : vec2<f32>;
var<private> p3_nodeVar1 : vec4<f32>;
var<private> p3_nodeVar2 : vec4<f32>;
var<private> p3_nodeVar3 : vec4<f32>;
var<private> p3_nodeVar4 : vec4<f32>;
var<private> p3_nodeVar5 : vec4<f32>;
var<private> p3_nodeVar6 : vec4<f32>;
var<private> p3_nodeVar7 : vec4<f32>;
var<private> p3_nodeVar8 : vec4<f32>;
var<private> p3_nodeVar9 : vec4<f32>;
var<private> p3_nodeVar10 : vec4<f32>;
var<private> p3_nodeVar11 : vec4<f32>;
var<private> p3_nodeVar12 : vec4<f32>;
var<private> p3_nodeVar13 : vec4<f32>;
var<private> p3_Output : vec4<f32>;
var<private> p3_nodeVar14 : vec4<f32>;

// codes


fn p3_main(door_uv: vec2f) -> p3_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p3_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p3_nodeVar1 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 0.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 0.0 ) ) ) );
	p3_nodeVar2 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * -1.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * -1.0 ) ) ) );
	p3_nodeVar3 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 1.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * -1.0 ) ) ) );
	p3_nodeVar4 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * -1.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 1.0 ) ) ) );
	p3_nodeVar5 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 1.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 1.0 ) ) ) );
	p3_nodeVar6 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * -2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 0.0 ) ) ) );
	p3_nodeVar7 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 0.0 ) ) ) );
	p3_nodeVar8 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 0.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * -2.0 ) ) ) );
	p3_nodeVar9 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 0.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 2.0 ) ) ) );
	p3_nodeVar10 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * -2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * -2.0 ) ) ) );
	p3_nodeVar11 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * -2.0 ) ) ) );
	p3_nodeVar12 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * -2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 2.0 ) ) ) );
	p3_nodeVar13 = target_read( t2, t2_sampler, ( p3_nodeVar0 + vec2<f32>( ( vec2<f32>(0.001953125, 0.00390625).x * 2.0 ), ( vec2<f32>(0.001953125, 0.00390625).y * 2.0 ) ) ) );
	p3_DiffuseColor = vec4<f32>( ( ( ( ( p3_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p3_nodeVar2.xyz + p3_nodeVar3.xyz ) + ( p3_nodeVar4.xyz + p3_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p3_nodeVar6.xyz + p3_nodeVar7.xyz ) + ( p3_nodeVar8.xyz + p3_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p3_nodeVar10.xyz + p3_nodeVar11.xyz ) + ( p3_nodeVar12.xyz + p3_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_DiffuseColor.w = 1.0;
	p3_nodeVar14 = max( vec4<f32>( p3_DiffuseColor.xyz, p3_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p3_Output = p3_nodeVar14;

	// result

	p3_output.color = p3_nodeVar14;

	return p3_output;

}

// structs

struct p4_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p4_output : p4_OutputStruct;

// uniforms


// vars
var<private> p4_DiffuseColor : vec4<f32>;
var<private> p4_nodeVar0 : vec2<f32>;
var<private> p4_nodeVar1 : vec4<f32>;
var<private> p4_nodeVar2 : vec4<f32>;
var<private> p4_nodeVar3 : vec4<f32>;
var<private> p4_nodeVar4 : vec4<f32>;
var<private> p4_nodeVar5 : vec4<f32>;
var<private> p4_nodeVar6 : vec4<f32>;
var<private> p4_nodeVar7 : vec4<f32>;
var<private> p4_nodeVar8 : vec4<f32>;
var<private> p4_nodeVar9 : vec4<f32>;
var<private> p4_nodeVar10 : vec4<f32>;
var<private> p4_nodeVar11 : vec4<f32>;
var<private> p4_nodeVar12 : vec4<f32>;
var<private> p4_nodeVar13 : vec4<f32>;
var<private> p4_Output : vec4<f32>;
var<private> p4_nodeVar14 : vec4<f32>;

// codes


fn p4_main(door_uv: vec2f) -> p4_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p4_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p4_nodeVar1 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p4_nodeVar2 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -1.0 ) ) ) );
	p4_nodeVar3 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -1.0 ) ) ) );
	p4_nodeVar4 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 1.0 ) ) ) );
	p4_nodeVar5 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 1.0 ) ) ) );
	p4_nodeVar6 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p4_nodeVar7 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p4_nodeVar8 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -2.0 ) ) ) );
	p4_nodeVar9 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 2.0 ) ) ) );
	p4_nodeVar10 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -2.0 ) ) ) );
	p4_nodeVar11 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -2.0 ) ) ) );
	p4_nodeVar12 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 2.0 ) ) ) );
	p4_nodeVar13 = target_read( t3, t3_sampler, ( p4_nodeVar0 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 2.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 2.0 ) ) ) );
	p4_DiffuseColor = vec4<f32>( ( ( ( ( p4_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p4_nodeVar2.xyz + p4_nodeVar3.xyz ) + ( p4_nodeVar4.xyz + p4_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p4_nodeVar6.xyz + p4_nodeVar7.xyz ) + ( p4_nodeVar8.xyz + p4_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p4_nodeVar10.xyz + p4_nodeVar11.xyz ) + ( p4_nodeVar12.xyz + p4_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p4_DiffuseColor.w = ( p4_DiffuseColor.w * f32(1.0) );
	p4_DiffuseColor.w = 1.0;
	p4_nodeVar14 = max( vec4<f32>( p4_DiffuseColor.xyz, p4_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p4_Output = p4_nodeVar14;

	// result

	p4_output.color = p4_nodeVar14;

	return p4_output;

}

// structs

struct p5_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p5_output : p5_OutputStruct;

// uniforms


// vars
var<private> p5_DiffuseColor : vec4<f32>;
var<private> p5_nodeVar0 : vec4<f32>;
var<private> p5_nodeVar1 : vec2<f32>;
var<private> p5_nodeVar2 : vec4<f32>;
var<private> p5_nodeVar3 : vec4<f32>;
var<private> p5_nodeVar4 : vec4<f32>;
var<private> p5_nodeVar5 : vec4<f32>;
var<private> p5_nodeVar6 : vec4<f32>;
var<private> p5_nodeVar7 : vec4<f32>;
var<private> p5_nodeVar8 : vec4<f32>;
var<private> p5_nodeVar9 : vec4<f32>;
var<private> p5_nodeVar10 : vec4<f32>;
var<private> p5_Output : vec4<f32>;
var<private> p5_nodeVar11 : vec4<f32>;

// codes


fn p5_main(door_uv: vec2f) -> p5_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p5_nodeVar0 = target_read( t3, t3_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p5_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p5_nodeVar2 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 0.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 0.0 ) ) ) );
	p5_nodeVar3 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * -1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 0.0 ) ) ) );
	p5_nodeVar4 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 0.0 ) ) ) );
	p5_nodeVar5 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 0.0 ), ( vec2<f32>(0.0078125, 0.015625).y * -1.0 ) ) ) );
	p5_nodeVar6 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 0.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 1.0 ) ) ) );
	p5_nodeVar7 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * -1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * -1.0 ) ) ) );
	p5_nodeVar8 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * -1.0 ) ) ) );
	p5_nodeVar9 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * -1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 1.0 ) ) ) );
	p5_nodeVar10 = target_read( t4, t4_sampler, ( p5_nodeVar1 + vec2<f32>( ( vec2<f32>(0.0078125, 0.015625).x * 1.0 ), ( vec2<f32>(0.0078125, 0.015625).y * 1.0 ) ) ) );
	p5_DiffuseColor = vec4<f32>( ( p5_nodeVar0.xyz + ( ( ( p5_nodeVar2.xyz * vec3<f32>( 0.25 ) ) + ( ( ( p5_nodeVar3.xyz + p5_nodeVar4.xyz ) + ( p5_nodeVar5.xyz + p5_nodeVar6.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p5_nodeVar7.xyz + p5_nodeVar8.xyz ) + ( p5_nodeVar9.xyz + p5_nodeVar10.xyz ) ) * vec3<f32>( 0.0625 ) ) ) ), 1.0 );
	p5_DiffuseColor.w = ( p5_DiffuseColor.w * f32(1.0) );
	p5_DiffuseColor.w = 1.0;
	p5_nodeVar11 = max( vec4<f32>( p5_DiffuseColor.xyz, p5_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p5_Output = p5_nodeVar11;

	// result

	p5_output.color = p5_nodeVar11;

	return p5_output;

}

// structs

struct p6_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p6_output : p6_OutputStruct;

// uniforms


// vars
var<private> p6_DiffuseColor : vec4<f32>;
var<private> p6_nodeVar0 : vec4<f32>;
var<private> p6_nodeVar1 : vec2<f32>;
var<private> p6_nodeVar2 : vec4<f32>;
var<private> p6_nodeVar3 : vec4<f32>;
var<private> p6_nodeVar4 : vec4<f32>;
var<private> p6_nodeVar5 : vec4<f32>;
var<private> p6_nodeVar6 : vec4<f32>;
var<private> p6_nodeVar7 : vec4<f32>;
var<private> p6_nodeVar8 : vec4<f32>;
var<private> p6_nodeVar9 : vec4<f32>;
var<private> p6_nodeVar10 : vec4<f32>;
var<private> p6_Output : vec4<f32>;
var<private> p6_nodeVar11 : vec4<f32>;

// codes


fn p6_main(door_uv: vec2f) -> p6_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p6_nodeVar0 = target_read( t2, t2_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p6_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p6_nodeVar2 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p6_nodeVar3 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p6_nodeVar4 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 0.0 ) ) ) );
	p6_nodeVar5 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -1.0 ) ) ) );
	p6_nodeVar6 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 0.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 1.0 ) ) ) );
	p6_nodeVar7 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -1.0 ) ) ) );
	p6_nodeVar8 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * -1.0 ) ) ) );
	p6_nodeVar9 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * -1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 1.0 ) ) ) );
	p6_nodeVar10 = target_read( t5, t5_sampler, ( p6_nodeVar1 + vec2<f32>( ( vec2<f32>(0.00390625, 0.0078125).x * 1.0 ), ( vec2<f32>(0.00390625, 0.0078125).y * 1.0 ) ) ) );
	p6_DiffuseColor = vec4<f32>( ( p6_nodeVar0.xyz + ( ( ( p6_nodeVar2.xyz * vec3<f32>( 0.25 ) ) + ( ( ( p6_nodeVar3.xyz + p6_nodeVar4.xyz ) + ( p6_nodeVar5.xyz + p6_nodeVar6.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p6_nodeVar7.xyz + p6_nodeVar8.xyz ) + ( p6_nodeVar9.xyz + p6_nodeVar10.xyz ) ) * vec3<f32>( 0.0625 ) ) ) ), 1.0 );
	p6_DiffuseColor.w = ( p6_DiffuseColor.w * f32(1.0) );
	p6_DiffuseColor.w = 1.0;
	p6_nodeVar11 = max( vec4<f32>( p6_DiffuseColor.xyz, p6_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p6_Output = p6_nodeVar11;

	// result

	p6_output.color = p6_nodeVar11;

	return p6_output;

}

// structs

struct p7_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p7_output : p7_OutputStruct;

// uniforms


// vars
var<private> p7_DiffuseColor : vec4<f32>;
var<private> p7_nodeVar0 : vec4<f32>;
var<private> p7_nodeVar1 : vec4<f32>;
var<private> p7_nodeVar2 : vec4<f32>;
var<private> p7_nodeVar3 : vec4<f32>;
var<private> p7_nodeVar4 : vec3<f32>;
var<private> p7_nodeVar5 : f32;
var<private> p7_nodeVar6 : vec3<f32>;
var<private> p7_nodeVar7 : vec4<f32>;
var<private> p7_Output : vec4<f32>;
var<private> p7_nodeVar8 : vec4<f32>;

// codes


fn p7_main(door_uv: vec2f) -> p7_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p7_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_nodeVar1 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_nodeVar2 = target_read( t6, t6_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_nodeVar3 = vec4<f32>( clamp( ( p7_nodeVar1.xyz + clamp( ( ( p7_nodeVar2.xyz * vec3<f32>( f32(1.1) ) ) * vec3<f32>( f32(1.93) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 2.0, 2.0, 2.0 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p7_nodeVar4 = vec3<f32>( p7_nodeVar3.x, p7_nodeVar3.y, p7_nodeVar3.z );
	p7_nodeVar5 = ( ( ( p7_nodeVar4.x * 0.2126 ) + ( p7_nodeVar4.y * 0.7152 ) ) + ( p7_nodeVar4.z * 0.0722 ) );
	p7_nodeVar6 = mix( vec3<f32>( p7_nodeVar5, p7_nodeVar5, p7_nodeVar5 ), p7_nodeVar4, f32(1.0) );
	p7_nodeVar7 = vec4<f32>( clamp( vec3<f32>( ( ( ( p7_nodeVar6.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p7_nodeVar6.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p7_nodeVar6.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p7_nodeVar6.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p7_nodeVar6.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p7_nodeVar6.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p7_nodeVar6.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p7_nodeVar6.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p7_nodeVar6.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p7_nodeVar3.w, 0.0, 1.0 ) );
	p7_DiffuseColor = vec4<f32>( mix( p7_nodeVar0.xyz, p7_nodeVar7.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p7_nodeVar7.w, 0.0, 1.0 ) ) ), clamp( p7_nodeVar0.w, 0.0, 1.0 ) );
	p7_DiffuseColor.w = ( p7_DiffuseColor.w * f32(1.0) );
	p7_nodeVar8 = max( vec4<f32>( p7_DiffuseColor.xyz, p7_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p7_Output = p7_nodeVar8;

	// result

	p7_output.color = p7_nodeVar8;

	return p7_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    case 1u: { return p1_main(door_uv).color; }
    case 2u: { return p2_main(door_uv).color; }
    case 3u: { return p3_main(door_uv).color; }
    case 4u: { return p4_main(door_uv).color; }
    case 5u: { return p5_main(door_uv).color; }
    case 6u: { return p6_main(door_uv).color; }
    case 7u: { return p7_main(door_uv).color; }
    default: {}
  }
  return to_shelf(target_read(t7, t7_sampler, door_uv));
}

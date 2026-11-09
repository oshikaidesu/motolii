// Mesh Gradient: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --track@activePoints:Active Points,2,5,5,1
// --track@point1Color_x:Point 1 Color r,0,1,1,0.001
// --track@point1Color_y:Point 1 Color g,0,1,0.19461783043107173,0.001
// --track@point1Color_z:Point 1 Color b,0,1,0.09989872823822872,0.001
// --track@point1Weight:Point 1 Weight,0,3,1.2,0.01
// --track@point2Color_x:Point 2 Color r,0,1,1,0.001
// --track@point2Color_y:Point 2 Color g,0,1,0.6938717612856897,0.001
// --track@point2Color_z:Point 2 Color b,0,1,0.4793201830913402,0.001
// --track@point2Weight:Point 2 Weight,0,3,1,0.01
// --track@point3Color_x:Point 3 Color r,0,1,1,0.001
// --track@point3Color_y:Point 3 Color g,0,1,0.450785782828426,0.001
// --track@point3Color_z:Point 3 Color b,0,1,0.5711248294565854,0.001
// --track@point3Weight:Point 3 Weight,0,3,0.9,0.01
// --track@point4Color_x:Point 4 Color r,0,1,1,0.001
// --track@point4Color_y:Point 4 Color g,0,1,0.5775804404214573,0.001
// --track@point4Color_z:Point 4 Color b,0,1,0.09530746662221588,0.001
// --track@point4Weight:Point 4 Weight,0,3,1,0.01
// --track@point5Color_x:Point 5 Color r,0,1,1,0.001
// --track@point5Color_y:Point 5 Color g,0,1,0.8796223968851662,0.001
// --track@point5Color_z:Point 5 Color b,0,1,0.7681511472425809,0.001
// --track@point5Weight:Point 5 Weight,0,3,1.1,0.01
// --check@distortionMode:Mode,0
// --track@softness:Softness,0,1,0.7,0.01
// --track@warp:Warp,0,1,0.3,0.01
// --track@detail:Detail,0,1,0.1,0.01
// --track@motionStyle:Motion,0,5,2,1
// --track@motionAmount:Amount,0,1,0.4,0.01
// --track@glowStrength:Glow Strength,0,1,0,0.01
// --track@glowThreshold:Glow Threshold,0,1,0,0.01
// --track@grainAmount:Grain,0,1,0.04,0.01
// --track@vignetteStrength:Vignette Strength,0,1,0,0.01
// --track@vignetteRadius:Vignette Radius,0,1.5,1.5,0.01
// --track@vignetteSoftness:Vignette Softness,0.01,1,1,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  activePoints: f32,
  point1Color: vec3<f32>,
  point1Weight: f32,
  point2Color: vec3<f32>,
  point2Weight: f32,
  point3Color: vec3<f32>,
  point3Weight: f32,
  point4Color: vec3<f32>,
  point4Weight: f32,
  point5Color: vec3<f32>,
  point5Weight: f32,
  distortionMode: f32,
  softness: f32,
  warp: f32,
  detail: f32,
  motionStyle: f32,
  motionAmount: f32,
  glowStrength: f32,
  glowThreshold: f32,
  grainAmount: f32,
  vignetteStrength: f32,
  vignetteRadius: f32,
  vignetteSoftness: f32,
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
var<private> p0_nodeVar0 : vec3<f32>;
var<private> p0_nodeVar1 : vec4<f32>;
var<private> p0_nodeVar2 : f32;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec3<f32>;
var<private> p0_nodeVar7 : vec3<f32>;
var<private> p0_nodeVar8 : vec3<f32>;
var<private> p0_nodeVar9 : vec3<f32>;
var<private> p0_nodeVar10 : vec3<f32>;
var<private> p0_nodeVar11 : vec3<f32>;
var<private> p0_nodeVar12 : vec3<f32>;
var<private> p0_nodeVar13 : vec3<f32>;
var<private> p0_nodeVar14 : vec3<f32>;
var<private> p0_nodeVar15 : vec3<f32>;
var<private> p0_nodeVar16 : vec4<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : vec4<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec3<f32>;
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
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : vec3<f32>;
var<private> p0_nodeVar34 : vec3<f32>;
var<private> p0_nodeVar35 : vec3<f32>;
var<private> p0_nodeVar36 : vec3<f32>;
var<private> p0_nodeVar37 : vec4<f32>;
var<private> p0_nodeVar38 : vec4<f32>;
var<private> p0_nodeVar39 : vec3<f32>;
var<private> p0_nodeVar40 : vec3<f32>;
var<private> p0_nodeVar41 : vec3<f32>;
var<private> p0_nodeVar42 : vec3<f32>;
var<private> p0_nodeVar43 : vec3<f32>;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : vec3<f32>;
var<private> p0_nodeVar46 : vec3<f32>;
var<private> p0_nodeVar47 : vec3<f32>;
var<private> p0_nodeVar48 : vec3<f32>;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : vec4<f32>;
var<private> p0_nodeVar51 : vec4<f32>;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : vec3<f32>;
var<private> p0_nodeVar55 : vec4<f32>;
var<private> p0_nodeVar56 : vec4<f32>;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : vec4<f32>;
var<private> p0_nodeVar59 : vec4<f32>;
var<private> p0_nodeVar60 : vec4<f32>;
var<private> p0_nodeVar61 : vec4<f32>;
var<private> p0_nodeVar62 : vec4<f32>;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : vec4<f32>;
var<private> p0_nodeVar65 : vec4<f32>;
var<private> p0_nodeVar66 : vec3<f32>;
var<private> p0_nodeVar67 : vec3<f32>;
var<private> p0_nodeVar68 : vec3<f32>;
var<private> p0_nodeVar69 : vec3<f32>;
var<private> p0_nodeVar70 : vec4<f32>;
var<private> p0_nodeVar71 : vec4<f32>;
var<private> p0_nodeVar72 : vec3<f32>;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : vec2<f32>;
var<private> p0_nodeVar76 : vec2<f32>;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : vec2<f32>;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : vec2<f32>;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : vec2<f32>;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : vec2<f32>;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : vec4<f32>;
var<private> p0_nodeVar95 : vec3<f32>;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : vec3<f32>;
var<private> p0_nodeVar98 : vec4<f32>;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : vec2<f32>;
var<private> p0_nodeVar101 : f32;
var<private> p0_nodeVar102 : vec2<f32>;
var<private> p0_nodeVar103 : vec3<f32>;
var<private> p0_nodeVar104 : vec3<f32>;
var<private> p0_nodeVar105 : vec3<f32>;
var<private> p0_nodeVar106 : vec3<f32>;
var<private> p0_nodeVar107 : vec3<f32>;
var<private> p0_nodeVar108 : vec3<f32>;
var<private> p0_nodeVar109 : vec3<f32>;
var<private> p0_nodeVar110 : vec3<f32>;
var<private> p0_nodeVar111 : vec3<f32>;
var<private> p0_nodeVar112 : vec3<f32>;
var<private> p0_nodeVar113 : vec4<f32>;
var<private> p0_nodeVar114 : vec4<f32>;
var<private> p0_nodeVar115 : vec4<f32>;
var<private> p0_nodeVar116 : vec4<f32>;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : vec3<f32>;
var<private> p0_nodeVar119 : vec4<f32>;
var<private> p0_nodeVar120 : vec4<f32>;
var<private> p0_nodeVar121 : vec4<f32>;
var<private> p0_nodeVar122 : vec4<f32>;
var<private> p0_nodeVar123 : vec4<f32>;
var<private> p0_nodeVar124 : vec4<f32>;
var<private> p0_nodeVar125 : vec4<f32>;
var<private> p0_nodeVar126 : vec4<f32>;
var<private> p0_nodeVar127 : vec4<f32>;
var<private> p0_nodeVar128 : vec4<f32>;
var<private> p0_nodeVar129 : vec4<f32>;
var<private> p0_nodeVar130 : vec3<f32>;
var<private> p0_nodeVar131 : vec3<f32>;
var<private> p0_nodeVar132 : vec3<f32>;
var<private> p0_nodeVar133 : vec3<f32>;
var<private> p0_nodeVar134 : vec4<f32>;
var<private> p0_nodeVar135 : vec4<f32>;
var<private> p0_nodeVar136 : vec3<f32>;
var<private> p0_nodeVar137 : vec3<f32>;
var<private> p0_nodeVar138 : vec3<f32>;
var<private> p0_nodeVar139 : vec3<f32>;
var<private> p0_nodeVar140 : vec3<f32>;
var<private> p0_nodeVar141 : vec3<f32>;
var<private> p0_nodeVar142 : vec3<f32>;
var<private> p0_nodeVar143 : vec3<f32>;
var<private> p0_nodeVar144 : vec3<f32>;
var<private> p0_nodeVar145 : vec3<f32>;
var<private> p0_nodeVar146 : vec4<f32>;
var<private> p0_nodeVar147 : vec4<f32>;
var<private> p0_nodeVar148 : vec4<f32>;
var<private> p0_nodeVar149 : vec4<f32>;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : vec3<f32>;
var<private> p0_nodeVar152 : vec4<f32>;
var<private> p0_nodeVar153 : vec4<f32>;
var<private> p0_nodeVar154 : vec4<f32>;
var<private> p0_nodeVar155 : vec4<f32>;
var<private> p0_nodeVar156 : vec4<f32>;
var<private> p0_nodeVar157 : vec4<f32>;
var<private> p0_nodeVar158 : vec4<f32>;
var<private> p0_nodeVar159 : vec4<f32>;
var<private> p0_nodeVar160 : vec4<f32>;
var<private> p0_nodeVar161 : vec4<f32>;
var<private> p0_nodeVar162 : vec4<f32>;
var<private> p0_nodeVar163 : vec3<f32>;
var<private> p0_nodeVar164 : vec3<f32>;
var<private> p0_nodeVar165 : vec3<f32>;
var<private> p0_nodeVar166 : vec3<f32>;
var<private> p0_nodeVar167 : vec4<f32>;
var<private> p0_nodeVar168 : vec4<f32>;
var<private> p0_nodeVar169 : vec3<f32>;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : vec2<f32>;
var<private> p0_nodeVar173 : vec2<f32>;
var<private> p0_nodeVar174 : f32;
var<private> p0_nodeVar175 : f32;
var<private> p0_nodeVar176 : vec2<f32>;
var<private> p0_nodeVar177 : f32;
var<private> p0_nodeVar178 : f32;
var<private> p0_nodeVar179 : vec2<f32>;
var<private> p0_nodeVar180 : f32;
var<private> p0_nodeVar181 : f32;
var<private> p0_nodeVar182 : vec2<f32>;
var<private> p0_nodeVar183 : f32;
var<private> p0_nodeVar184 : f32;
var<private> p0_nodeVar185 : vec2<f32>;
var<private> p0_nodeVar186 : f32;
var<private> p0_nodeVar187 : f32;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : f32;
var<private> p0_nodeVar190 : vec2<f32>;
var<private> p0_nodeVar191 : vec4<f32>;
var<private> p0_nodeVar192 : vec3<f32>;
var<private> p0_nodeVar193 : f32;
var<private> p0_nodeVar194 : vec3<f32>;
var<private> p0_nodeVar195 : vec4<f32>;
var<private> p0_nodeVar196 : f32;
var<private> p0_nodeVar197 : f32;
var<private> p0_nodeVar198 : f32;
var<private> p0_nodeVar199 : f32;
var<private> p0_nodeVar200 : vec2<f32>;
var<private> p0_nodeVar201 : f32;
var<private> p0_nodeVar202 : vec2<f32>;
var<private> p0_nodeVar203 : vec3<f32>;
var<private> p0_nodeVar204 : vec3<f32>;
var<private> p0_nodeVar205 : vec3<f32>;
var<private> p0_nodeVar206 : vec3<f32>;
var<private> p0_nodeVar207 : vec3<f32>;
var<private> p0_nodeVar208 : vec3<f32>;
var<private> p0_nodeVar209 : vec3<f32>;
var<private> p0_nodeVar210 : vec3<f32>;
var<private> p0_nodeVar211 : vec3<f32>;
var<private> p0_nodeVar212 : vec3<f32>;
var<private> p0_nodeVar213 : vec4<f32>;
var<private> p0_nodeVar214 : vec4<f32>;
var<private> p0_nodeVar215 : vec4<f32>;
var<private> p0_nodeVar216 : vec4<f32>;
var<private> p0_nodeVar217 : f32;
var<private> p0_nodeVar218 : vec3<f32>;
var<private> p0_nodeVar219 : vec4<f32>;
var<private> p0_nodeVar220 : vec4<f32>;
var<private> p0_nodeVar221 : vec4<f32>;
var<private> p0_nodeVar222 : vec4<f32>;
var<private> p0_nodeVar223 : vec4<f32>;
var<private> p0_nodeVar224 : vec4<f32>;
var<private> p0_nodeVar225 : vec4<f32>;
var<private> p0_nodeVar226 : vec4<f32>;
var<private> p0_nodeVar227 : vec4<f32>;
var<private> p0_nodeVar228 : vec4<f32>;
var<private> p0_nodeVar229 : vec4<f32>;
var<private> p0_nodeVar230 : vec3<f32>;
var<private> p0_nodeVar231 : vec3<f32>;
var<private> p0_nodeVar232 : vec3<f32>;
var<private> p0_nodeVar233 : vec3<f32>;
var<private> p0_nodeVar234 : vec4<f32>;
var<private> p0_nodeVar235 : vec4<f32>;
var<private> p0_nodeVar236 : vec3<f32>;
var<private> p0_nodeVar237 : vec3<f32>;
var<private> p0_nodeVar238 : vec3<f32>;
var<private> p0_nodeVar239 : vec3<f32>;
var<private> p0_nodeVar240 : vec3<f32>;
var<private> p0_nodeVar241 : vec3<f32>;
var<private> p0_nodeVar242 : vec3<f32>;
var<private> p0_nodeVar243 : vec3<f32>;
var<private> p0_nodeVar244 : vec3<f32>;
var<private> p0_nodeVar245 : vec3<f32>;
var<private> p0_nodeVar246 : vec4<f32>;
var<private> p0_nodeVar247 : vec4<f32>;
var<private> p0_nodeVar248 : vec4<f32>;
var<private> p0_nodeVar249 : vec4<f32>;
var<private> p0_nodeVar250 : f32;
var<private> p0_nodeVar251 : vec3<f32>;
var<private> p0_nodeVar252 : vec4<f32>;
var<private> p0_nodeVar253 : vec4<f32>;
var<private> p0_nodeVar254 : vec4<f32>;
var<private> p0_nodeVar255 : vec4<f32>;
var<private> p0_nodeVar256 : vec4<f32>;
var<private> p0_nodeVar257 : vec4<f32>;
var<private> p0_nodeVar258 : vec4<f32>;
var<private> p0_nodeVar259 : vec4<f32>;
var<private> p0_nodeVar260 : vec4<f32>;
var<private> p0_nodeVar261 : vec4<f32>;
var<private> p0_nodeVar262 : vec4<f32>;
var<private> p0_nodeVar263 : vec3<f32>;
var<private> p0_nodeVar264 : vec3<f32>;
var<private> p0_nodeVar265 : vec3<f32>;
var<private> p0_nodeVar266 : vec3<f32>;
var<private> p0_nodeVar267 : vec4<f32>;
var<private> p0_nodeVar268 : vec4<f32>;
var<private> p0_nodeVar269 : vec3<f32>;
var<private> p0_nodeVar270 : f32;
var<private> p0_nodeVar271 : f32;
var<private> p0_nodeVar272 : vec2<f32>;
var<private> p0_nodeVar273 : vec2<f32>;
var<private> p0_nodeVar274 : f32;
var<private> p0_nodeVar275 : f32;
var<private> p0_nodeVar276 : vec2<f32>;
var<private> p0_nodeVar277 : f32;
var<private> p0_nodeVar278 : f32;
var<private> p0_nodeVar279 : vec2<f32>;
var<private> p0_nodeVar280 : f32;
var<private> p0_nodeVar281 : f32;
var<private> p0_nodeVar282 : vec2<f32>;
var<private> p0_nodeVar283 : f32;
var<private> p0_nodeVar284 : f32;
var<private> p0_nodeVar285 : vec2<f32>;
var<private> p0_nodeVar286 : f32;
var<private> p0_nodeVar287 : f32;
var<private> p0_nodeVar288 : f32;
var<private> p0_nodeVar289 : f32;
var<private> p0_nodeVar290 : vec2<f32>;
var<private> p0_nodeVar291 : vec4<f32>;
var<private> p0_nodeVar292 : vec3<f32>;
var<private> p0_nodeVar293 : f32;
var<private> p0_nodeVar294 : vec3<f32>;
var<private> p0_nodeVar295 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar296 : vec4<f32>;

// codes
fn p0_tsl_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }
fn p0_tsl_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar1 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );

	if ( ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) == 1.0 ) ) {

		p0_nodeVar2 = ( ( f32(knobs.time) * f32(1.2566370614359172) ) * f32(array<f32, 6>(0.0, 1.0, 1.0, 1.0, 1.0, 1.0)[u32(knobs.motionStyle)]) );
		p0_nodeVar3 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * f32((knobs.resolution.x / knobs.resolution.y)) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( p0_nodeVar2 ) * f32(knobs.motionAmount) ) * 0.06 ) ) ) );
		p0_nodeVar4 = ( f32((0.75 * knobs.warp + 0)) / pow( 1.0, f32((-0.7999999999999998 * knobs.detail + 1.6)) ) );
		p0_nodeVar5 = ( ( ( p0_nodeVar3 * vec2<f32>( f32((1.6000000000000005 * knobs.detail + 0.7299999999999998)) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
		p0_nodeVar6 = vec3<f32>( p0_nodeVar5, 100.0 );
		p0_nodeVar7 = floor( ( p0_nodeVar6 + vec3<f32>( dot( p0_nodeVar6, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar8 = ( ( p0_nodeVar6 - p0_nodeVar7 ) + vec3<f32>( dot( p0_nodeVar7, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar9 = step( p0_nodeVar8.yzx, p0_nodeVar8 );
		p0_nodeVar10 = ( vec3<f32>( 1.0 ) - p0_nodeVar9 );
		p0_nodeVar11 = min( p0_nodeVar9, p0_nodeVar10.zxy );
		p0_nodeVar12 = max( p0_nodeVar9, p0_nodeVar10.zxy );
		p0_nodeVar13 = ( ( p0_nodeVar8 - p0_nodeVar11 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar14 = ( ( p0_nodeVar8 - p0_nodeVar12 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar15 = ( ( p0_nodeVar8 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar7 = p0_tsl_mod_vec3( p0_nodeVar7, vec3<f32>( 289.0 ) );
		p0_nodeVar16 = ( vec4<f32>( p0_nodeVar7.z ) + vec4<f32>( 0.0, p0_nodeVar11.z, p0_nodeVar12.z, 1.0 ) );
		p0_nodeVar17 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar16 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar16 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar7.y ) + vec4<f32>( 0.0, p0_nodeVar11.y, p0_nodeVar12.y, 1.0 ) ) );
		p0_nodeVar18 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar17 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar17 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar7.x ) + vec4<f32>( 0.0, p0_nodeVar11.x, p0_nodeVar12.x, 1.0 ) ) );
		p0_nodeVar19 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar18 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar18 ), vec4<f32>( 289.0 ) );
		p0_nodeVar20 = 0.14285714285714285;
		p0_nodeVar21 = ( ( vec3<f32>( p0_nodeVar20 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar22 = ( p0_nodeVar19 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar19 * vec4<f32>( ( p0_nodeVar21.z * p0_nodeVar21.z ) ) ) ) ) );
		p0_nodeVar23 = ( ( floor( ( p0_nodeVar22 * vec4<f32>( p0_nodeVar21.z ) ) ) * vec4<f32>( p0_nodeVar21.x ) ) + vec4<f32>( p0_nodeVar21, 1.0 ).yyyy );
		p0_nodeVar24 = ( ( floor( ( p0_nodeVar22 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar22 * vec4<f32>( p0_nodeVar21.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar21.x ) ) + vec4<f32>( p0_nodeVar21, 1.0 ).yyyy );
		p0_nodeVar25 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar23 ) - abs( p0_nodeVar24 ) ) );
		p0_nodeVar26 = vec4<f32>( p0_nodeVar23.xy, p0_nodeVar24.xy );
		p0_nodeVar27 = vec4<f32>( p0_nodeVar23.zw, p0_nodeVar24.zw );
		p0_nodeVar28 = ( ( floor( p0_nodeVar26 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar29 = ( ( floor( p0_nodeVar27 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar30 = ( - step( p0_nodeVar25, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar31 = ( p0_nodeVar26.xzyw + ( p0_nodeVar28.xzyw * p0_nodeVar30.xxyy ) );
		p0_nodeVar32 = ( p0_nodeVar27.xzyw + ( p0_nodeVar29.xzyw * p0_nodeVar30.zzww ) );
		p0_nodeVar33 = vec3<f32>( p0_nodeVar31.xy, p0_nodeVar25.x );
		p0_nodeVar34 = vec3<f32>( p0_nodeVar31.zw, p0_nodeVar25.y );
		p0_nodeVar35 = vec3<f32>( p0_nodeVar32.xy, p0_nodeVar25.z );
		p0_nodeVar36 = vec3<f32>( p0_nodeVar32.zw, p0_nodeVar25.w );
		p0_nodeVar37 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar33, p0_nodeVar33 ), dot( p0_nodeVar34, p0_nodeVar34 ), dot( p0_nodeVar35, p0_nodeVar35 ), dot( p0_nodeVar36, p0_nodeVar36 ) ) ) );
		p0_nodeVar33 = ( p0_nodeVar33 * vec3<f32>( p0_nodeVar37.x ) );
		p0_nodeVar34 = ( p0_nodeVar34 * vec3<f32>( p0_nodeVar37.y ) );
		p0_nodeVar35 = ( p0_nodeVar35 * vec3<f32>( p0_nodeVar37.z ) );
		p0_nodeVar36 = ( p0_nodeVar36 * vec3<f32>( p0_nodeVar37.w ) );
		p0_nodeVar38 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar8, p0_nodeVar8 ), dot( p0_nodeVar13, p0_nodeVar13 ), dot( p0_nodeVar14, p0_nodeVar14 ), dot( p0_nodeVar15, p0_nodeVar15 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar38 = ( p0_nodeVar38 * p0_nodeVar38 );
		p0_nodeVar3.x = ( p0_nodeVar3.x + ( ( p0_nodeVar4 * ( 42.0 * dot( ( p0_nodeVar38 * p0_nodeVar38 ), vec4<f32>( dot( p0_nodeVar33, p0_nodeVar8 ), dot( p0_nodeVar34, p0_nodeVar13 ), dot( p0_nodeVar35, p0_nodeVar14 ), dot( p0_nodeVar36, p0_nodeVar15 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
		p0_nodeVar39 = vec3<f32>( ( p0_nodeVar5 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
		p0_nodeVar40 = floor( ( p0_nodeVar39 + vec3<f32>( dot( p0_nodeVar39, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar41 = ( ( p0_nodeVar39 - p0_nodeVar40 ) + vec3<f32>( dot( p0_nodeVar40, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar42 = step( p0_nodeVar41.yzx, p0_nodeVar41 );
		p0_nodeVar43 = ( vec3<f32>( 1.0 ) - p0_nodeVar42 );
		p0_nodeVar44 = min( p0_nodeVar42, p0_nodeVar43.zxy );
		p0_nodeVar45 = max( p0_nodeVar42, p0_nodeVar43.zxy );
		p0_nodeVar46 = ( ( p0_nodeVar41 - p0_nodeVar44 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar47 = ( ( p0_nodeVar41 - p0_nodeVar45 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar48 = ( ( p0_nodeVar41 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar40 = p0_tsl_mod_vec3( p0_nodeVar40, vec3<f32>( 289.0 ) );
		p0_nodeVar49 = ( vec4<f32>( p0_nodeVar40.z ) + vec4<f32>( 0.0, p0_nodeVar44.z, p0_nodeVar45.z, 1.0 ) );
		p0_nodeVar50 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar49 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar49 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar40.y ) + vec4<f32>( 0.0, p0_nodeVar44.y, p0_nodeVar45.y, 1.0 ) ) );
		p0_nodeVar51 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar50 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar50 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar40.x ) + vec4<f32>( 0.0, p0_nodeVar44.x, p0_nodeVar45.x, 1.0 ) ) );
		p0_nodeVar52 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar51 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar51 ), vec4<f32>( 289.0 ) );
		p0_nodeVar53 = 0.14285714285714285;
		p0_nodeVar54 = ( ( vec3<f32>( p0_nodeVar53 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar55 = ( p0_nodeVar52 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar52 * vec4<f32>( ( p0_nodeVar54.z * p0_nodeVar54.z ) ) ) ) ) );
		p0_nodeVar56 = ( ( floor( ( p0_nodeVar55 * vec4<f32>( p0_nodeVar54.z ) ) ) * vec4<f32>( p0_nodeVar54.x ) ) + vec4<f32>( p0_nodeVar54, 1.0 ).yyyy );
		p0_nodeVar57 = ( ( floor( ( p0_nodeVar55 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar55 * vec4<f32>( p0_nodeVar54.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar54.x ) ) + vec4<f32>( p0_nodeVar54, 1.0 ).yyyy );
		p0_nodeVar58 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar56 ) - abs( p0_nodeVar57 ) ) );
		p0_nodeVar59 = vec4<f32>( p0_nodeVar56.xy, p0_nodeVar57.xy );
		p0_nodeVar60 = vec4<f32>( p0_nodeVar56.zw, p0_nodeVar57.zw );
		p0_nodeVar61 = ( ( floor( p0_nodeVar59 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar62 = ( ( floor( p0_nodeVar60 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar63 = ( - step( p0_nodeVar58, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar64 = ( p0_nodeVar59.xzyw + ( p0_nodeVar61.xzyw * p0_nodeVar63.xxyy ) );
		p0_nodeVar65 = ( p0_nodeVar60.xzyw + ( p0_nodeVar62.xzyw * p0_nodeVar63.zzww ) );
		p0_nodeVar66 = vec3<f32>( p0_nodeVar64.xy, p0_nodeVar58.x );
		p0_nodeVar67 = vec3<f32>( p0_nodeVar64.zw, p0_nodeVar58.y );
		p0_nodeVar68 = vec3<f32>( p0_nodeVar65.xy, p0_nodeVar58.z );
		p0_nodeVar69 = vec3<f32>( p0_nodeVar65.zw, p0_nodeVar58.w );
		p0_nodeVar70 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar66, p0_nodeVar66 ), dot( p0_nodeVar67, p0_nodeVar67 ), dot( p0_nodeVar68, p0_nodeVar68 ), dot( p0_nodeVar69, p0_nodeVar69 ) ) ) );
		p0_nodeVar66 = ( p0_nodeVar66 * vec3<f32>( p0_nodeVar70.x ) );
		p0_nodeVar67 = ( p0_nodeVar67 * vec3<f32>( p0_nodeVar70.y ) );
		p0_nodeVar68 = ( p0_nodeVar68 * vec3<f32>( p0_nodeVar70.z ) );
		p0_nodeVar69 = ( p0_nodeVar69 * vec3<f32>( p0_nodeVar70.w ) );
		p0_nodeVar71 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar41, p0_nodeVar41 ), dot( p0_nodeVar46, p0_nodeVar46 ), dot( p0_nodeVar47, p0_nodeVar47 ), dot( p0_nodeVar48, p0_nodeVar48 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar71 = ( p0_nodeVar71 * p0_nodeVar71 );
		p0_nodeVar3.y = ( p0_nodeVar3.y + ( ( p0_nodeVar4 * ( 42.0 * dot( ( p0_nodeVar71 * p0_nodeVar71 ), vec4<f32>( dot( p0_nodeVar66, p0_nodeVar41 ), dot( p0_nodeVar67, p0_nodeVar46 ), dot( p0_nodeVar68, p0_nodeVar47 ), dot( p0_nodeVar69, p0_nodeVar48 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
		p0_nodeVar72 = vec3<f32>( 0.0, 0.0, 0.0 );
		p0_nodeVar73 = 0.0;
		p0_nodeVar74 = ( sqrt( max( dot( p0_nodeVar3, p0_nodeVar3 ), 0.0001 ) ) * f32((0.69 * knobs.distortionMode + 0)) );
		p0_nodeVar75 = vec2<f32>( ( ( p0_nodeVar3.x * cos( p0_nodeVar74 ) ) - ( p0_nodeVar3.y * sin( p0_nodeVar74 ) ) ), ( ( p0_nodeVar3.x * sin( p0_nodeVar74 ) ) + ( p0_nodeVar3.y * cos( p0_nodeVar74 ) ) ) );
		p0_nodeVar76 = ( p0_nodeVar75 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 1.0 ) ) {

			p0_nodeVar77 = 1.0;

		} else {

			p0_nodeVar77 = 0.0;

		}

		p0_nodeVar78 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar76, p0_nodeVar76 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point1Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar2 + ( 1.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar77 );
		p0_nodeVar72 = ( p0_nodeVar72 + ( vec3<f32>( f32(knobs.point1Color.x), f32(knobs.point1Color.y), f32(knobs.point1Color.z) ) * vec3<f32>( p0_nodeVar78 ) ) );
		p0_nodeVar73 = ( p0_nodeVar73 + p0_nodeVar78 );
		p0_nodeVar79 = ( p0_nodeVar75 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 2.0 ) ) {

			p0_nodeVar80 = 1.0;

		} else {

			p0_nodeVar80 = 0.0;

		}

		p0_nodeVar81 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar79, p0_nodeVar79 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point2Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar2 + ( 2.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar80 );
		p0_nodeVar72 = ( p0_nodeVar72 + ( vec3<f32>( f32(knobs.point2Color.x), f32(knobs.point2Color.y), f32(knobs.point2Color.z) ) * vec3<f32>( p0_nodeVar81 ) ) );
		p0_nodeVar73 = ( p0_nodeVar73 + p0_nodeVar81 );
		p0_nodeVar82 = ( p0_nodeVar75 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 3.0 ) ) {

			p0_nodeVar83 = 1.0;

		} else {

			p0_nodeVar83 = 0.0;

		}

		p0_nodeVar84 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar82, p0_nodeVar82 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point3Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar2 + ( 3.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar83 );
		p0_nodeVar72 = ( p0_nodeVar72 + ( vec3<f32>( f32(knobs.point3Color.x), f32(knobs.point3Color.y), f32(knobs.point3Color.z) ) * vec3<f32>( p0_nodeVar84 ) ) );
		p0_nodeVar73 = ( p0_nodeVar73 + p0_nodeVar84 );
		p0_nodeVar85 = ( p0_nodeVar75 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 4.0 ) ) {

			p0_nodeVar86 = 1.0;

		} else {

			p0_nodeVar86 = 0.0;

		}

		p0_nodeVar87 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar85, p0_nodeVar85 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point4Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar2 + ( 4.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar86 );
		p0_nodeVar72 = ( p0_nodeVar72 + ( vec3<f32>( f32(knobs.point4Color.x), f32(knobs.point4Color.y), f32(knobs.point4Color.z) ) * vec3<f32>( p0_nodeVar87 ) ) );
		p0_nodeVar73 = ( p0_nodeVar73 + p0_nodeVar87 );
		p0_nodeVar88 = ( p0_nodeVar75 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 5.0 ) ) {

			p0_nodeVar89 = 1.0;

		} else {

			p0_nodeVar89 = 0.0;

		}

		p0_nodeVar90 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar88, p0_nodeVar88 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point5Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar2 + ( 5.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar89 );
		p0_nodeVar72 = ( p0_nodeVar72 + ( vec3<f32>( f32(knobs.point5Color.x), f32(knobs.point5Color.y), f32(knobs.point5Color.z) ) * vec3<f32>( p0_nodeVar90 ) ) );
		p0_nodeVar73 = ( p0_nodeVar73 + p0_nodeVar90 );
		p0_nodeVar72 = ( p0_nodeVar72 / vec3<f32>( max( p0_nodeVar73, 0.0001 ) ) );
		p0_nodeVar91 = ( smoothstep( f32(knobs.glowThreshold), 1.0, dot( p0_nodeVar72, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * f32(knobs.glowStrength) );
		p0_nodeVar72 = ( p0_nodeVar72 + vec3<f32>( p0_nodeVar91, p0_nodeVar91, p0_nodeVar91 ) );
		p0_nodeVar92 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * f32(knobs.grainAmount) );
		p0_nodeVar72 = ( p0_nodeVar72 + vec3<f32>( p0_nodeVar92, p0_nodeVar92, p0_nodeVar92 ) );
		p0_nodeVar93 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
		p0_nodeVar72 = ( p0_nodeVar72 * vec3<f32>( mix( 1.0, smoothstep( f32(knobs.vignetteRadius), ( f32(knobs.vignetteRadius) - f32(knobs.vignetteSoftness) ), sqrt( max( dot( p0_nodeVar93, p0_nodeVar93 ), 0.0001 ) ) ), f32(knobs.vignetteStrength) ) ) );
		p0_nodeVar94 = vec4<f32>( clamp( p0_nodeVar72, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
		p0_nodeVar95 = vec3<f32>( p0_nodeVar94.x, p0_nodeVar94.y, p0_nodeVar94.z );
		p0_nodeVar96 = ( ( ( p0_nodeVar95.x * 0.2126 ) + ( p0_nodeVar95.y * 0.7152 ) ) + ( p0_nodeVar95.z * 0.0722 ) );
		p0_nodeVar97 = mix( vec3<f32>( p0_nodeVar96, p0_nodeVar96, p0_nodeVar96 ), p0_nodeVar95, f32(1.0) );
		p0_nodeVar98 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar97.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar97.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar97.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar97.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar97.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar97.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar97.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar97.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar97.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar94.w, 0.0, 1.0 ) );
		p0_nodeVar0 = mix( p0_nodeVar1.xyz, p0_nodeVar98.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar98.w, 0.0, 1.0 ) ) );

	} else {

		p0_nodeVar99 = ( ( f32(knobs.time) * f32(1.2566370614359172) ) * f32(array<f32, 6>(0.0, 1.0, 1.0, 1.0, 1.0, 1.0)[u32(knobs.motionStyle)]) );
		p0_nodeVar100 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * f32((knobs.resolution.x / knobs.resolution.y)) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( p0_nodeVar99 ) * f32(knobs.motionAmount) ) * 0.06 ) ) ) );
		p0_nodeVar101 = ( f32((0.75 * knobs.warp + 0)) / pow( 1.0, f32((-0.7999999999999998 * knobs.detail + 1.6)) ) );
		p0_nodeVar102 = ( ( ( p0_nodeVar100 * vec2<f32>( f32((1.6000000000000005 * knobs.detail + 0.7299999999999998)) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
		p0_nodeVar103 = vec3<f32>( p0_nodeVar102, 100.0 );
		p0_nodeVar104 = floor( ( p0_nodeVar103 + vec3<f32>( dot( p0_nodeVar103, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar105 = ( ( p0_nodeVar103 - p0_nodeVar104 ) + vec3<f32>( dot( p0_nodeVar104, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar106 = step( p0_nodeVar105.yzx, p0_nodeVar105 );
		p0_nodeVar107 = ( vec3<f32>( 1.0 ) - p0_nodeVar106 );
		p0_nodeVar108 = min( p0_nodeVar106, p0_nodeVar107.zxy );
		p0_nodeVar109 = max( p0_nodeVar106, p0_nodeVar107.zxy );
		p0_nodeVar110 = ( ( p0_nodeVar105 - p0_nodeVar108 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar111 = ( ( p0_nodeVar105 - p0_nodeVar109 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar112 = ( ( p0_nodeVar105 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar104 = p0_tsl_mod_vec3( p0_nodeVar104, vec3<f32>( 289.0 ) );
		p0_nodeVar113 = ( vec4<f32>( p0_nodeVar104.z ) + vec4<f32>( 0.0, p0_nodeVar108.z, p0_nodeVar109.z, 1.0 ) );
		p0_nodeVar114 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar113 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar113 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar104.y ) + vec4<f32>( 0.0, p0_nodeVar108.y, p0_nodeVar109.y, 1.0 ) ) );
		p0_nodeVar115 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar114 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar114 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar104.x ) + vec4<f32>( 0.0, p0_nodeVar108.x, p0_nodeVar109.x, 1.0 ) ) );
		p0_nodeVar116 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar115 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar115 ), vec4<f32>( 289.0 ) );
		p0_nodeVar117 = 0.14285714285714285;
		p0_nodeVar118 = ( ( vec3<f32>( p0_nodeVar117 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar119 = ( p0_nodeVar116 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar116 * vec4<f32>( ( p0_nodeVar118.z * p0_nodeVar118.z ) ) ) ) ) );
		p0_nodeVar120 = ( ( floor( ( p0_nodeVar119 * vec4<f32>( p0_nodeVar118.z ) ) ) * vec4<f32>( p0_nodeVar118.x ) ) + vec4<f32>( p0_nodeVar118, 1.0 ).yyyy );
		p0_nodeVar121 = ( ( floor( ( p0_nodeVar119 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar119 * vec4<f32>( p0_nodeVar118.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar118.x ) ) + vec4<f32>( p0_nodeVar118, 1.0 ).yyyy );
		p0_nodeVar122 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar120 ) - abs( p0_nodeVar121 ) ) );
		p0_nodeVar123 = vec4<f32>( p0_nodeVar120.xy, p0_nodeVar121.xy );
		p0_nodeVar124 = vec4<f32>( p0_nodeVar120.zw, p0_nodeVar121.zw );
		p0_nodeVar125 = ( ( floor( p0_nodeVar123 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar126 = ( ( floor( p0_nodeVar124 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar127 = ( - step( p0_nodeVar122, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar128 = ( p0_nodeVar123.xzyw + ( p0_nodeVar125.xzyw * p0_nodeVar127.xxyy ) );
		p0_nodeVar129 = ( p0_nodeVar124.xzyw + ( p0_nodeVar126.xzyw * p0_nodeVar127.zzww ) );
		p0_nodeVar130 = vec3<f32>( p0_nodeVar128.xy, p0_nodeVar122.x );
		p0_nodeVar131 = vec3<f32>( p0_nodeVar128.zw, p0_nodeVar122.y );
		p0_nodeVar132 = vec3<f32>( p0_nodeVar129.xy, p0_nodeVar122.z );
		p0_nodeVar133 = vec3<f32>( p0_nodeVar129.zw, p0_nodeVar122.w );
		p0_nodeVar134 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar130, p0_nodeVar130 ), dot( p0_nodeVar131, p0_nodeVar131 ), dot( p0_nodeVar132, p0_nodeVar132 ), dot( p0_nodeVar133, p0_nodeVar133 ) ) ) );
		p0_nodeVar130 = ( p0_nodeVar130 * vec3<f32>( p0_nodeVar134.x ) );
		p0_nodeVar131 = ( p0_nodeVar131 * vec3<f32>( p0_nodeVar134.y ) );
		p0_nodeVar132 = ( p0_nodeVar132 * vec3<f32>( p0_nodeVar134.z ) );
		p0_nodeVar133 = ( p0_nodeVar133 * vec3<f32>( p0_nodeVar134.w ) );
		p0_nodeVar135 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar105, p0_nodeVar105 ), dot( p0_nodeVar110, p0_nodeVar110 ), dot( p0_nodeVar111, p0_nodeVar111 ), dot( p0_nodeVar112, p0_nodeVar112 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar135 = ( p0_nodeVar135 * p0_nodeVar135 );
		p0_nodeVar100.x = ( p0_nodeVar100.x + ( ( p0_nodeVar101 * ( 42.0 * dot( ( p0_nodeVar135 * p0_nodeVar135 ), vec4<f32>( dot( p0_nodeVar130, p0_nodeVar105 ), dot( p0_nodeVar131, p0_nodeVar110 ), dot( p0_nodeVar132, p0_nodeVar111 ), dot( p0_nodeVar133, p0_nodeVar112 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
		p0_nodeVar136 = vec3<f32>( ( p0_nodeVar102 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
		p0_nodeVar137 = floor( ( p0_nodeVar136 + vec3<f32>( dot( p0_nodeVar136, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar138 = ( ( p0_nodeVar136 - p0_nodeVar137 ) + vec3<f32>( dot( p0_nodeVar137, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar139 = step( p0_nodeVar138.yzx, p0_nodeVar138 );
		p0_nodeVar140 = ( vec3<f32>( 1.0 ) - p0_nodeVar139 );
		p0_nodeVar141 = min( p0_nodeVar139, p0_nodeVar140.zxy );
		p0_nodeVar142 = max( p0_nodeVar139, p0_nodeVar140.zxy );
		p0_nodeVar143 = ( ( p0_nodeVar138 - p0_nodeVar141 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar144 = ( ( p0_nodeVar138 - p0_nodeVar142 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar145 = ( ( p0_nodeVar138 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar137 = p0_tsl_mod_vec3( p0_nodeVar137, vec3<f32>( 289.0 ) );
		p0_nodeVar146 = ( vec4<f32>( p0_nodeVar137.z ) + vec4<f32>( 0.0, p0_nodeVar141.z, p0_nodeVar142.z, 1.0 ) );
		p0_nodeVar147 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar146 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar146 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar137.y ) + vec4<f32>( 0.0, p0_nodeVar141.y, p0_nodeVar142.y, 1.0 ) ) );
		p0_nodeVar148 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar147 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar147 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar137.x ) + vec4<f32>( 0.0, p0_nodeVar141.x, p0_nodeVar142.x, 1.0 ) ) );
		p0_nodeVar149 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar148 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar148 ), vec4<f32>( 289.0 ) );
		p0_nodeVar150 = 0.14285714285714285;
		p0_nodeVar151 = ( ( vec3<f32>( p0_nodeVar150 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar152 = ( p0_nodeVar149 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar149 * vec4<f32>( ( p0_nodeVar151.z * p0_nodeVar151.z ) ) ) ) ) );
		p0_nodeVar153 = ( ( floor( ( p0_nodeVar152 * vec4<f32>( p0_nodeVar151.z ) ) ) * vec4<f32>( p0_nodeVar151.x ) ) + vec4<f32>( p0_nodeVar151, 1.0 ).yyyy );
		p0_nodeVar154 = ( ( floor( ( p0_nodeVar152 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar152 * vec4<f32>( p0_nodeVar151.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar151.x ) ) + vec4<f32>( p0_nodeVar151, 1.0 ).yyyy );
		p0_nodeVar155 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar153 ) - abs( p0_nodeVar154 ) ) );
		p0_nodeVar156 = vec4<f32>( p0_nodeVar153.xy, p0_nodeVar154.xy );
		p0_nodeVar157 = vec4<f32>( p0_nodeVar153.zw, p0_nodeVar154.zw );
		p0_nodeVar158 = ( ( floor( p0_nodeVar156 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar159 = ( ( floor( p0_nodeVar157 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar160 = ( - step( p0_nodeVar155, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar161 = ( p0_nodeVar156.xzyw + ( p0_nodeVar158.xzyw * p0_nodeVar160.xxyy ) );
		p0_nodeVar162 = ( p0_nodeVar157.xzyw + ( p0_nodeVar159.xzyw * p0_nodeVar160.zzww ) );
		p0_nodeVar163 = vec3<f32>( p0_nodeVar161.xy, p0_nodeVar155.x );
		p0_nodeVar164 = vec3<f32>( p0_nodeVar161.zw, p0_nodeVar155.y );
		p0_nodeVar165 = vec3<f32>( p0_nodeVar162.xy, p0_nodeVar155.z );
		p0_nodeVar166 = vec3<f32>( p0_nodeVar162.zw, p0_nodeVar155.w );
		p0_nodeVar167 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar163, p0_nodeVar163 ), dot( p0_nodeVar164, p0_nodeVar164 ), dot( p0_nodeVar165, p0_nodeVar165 ), dot( p0_nodeVar166, p0_nodeVar166 ) ) ) );
		p0_nodeVar163 = ( p0_nodeVar163 * vec3<f32>( p0_nodeVar167.x ) );
		p0_nodeVar164 = ( p0_nodeVar164 * vec3<f32>( p0_nodeVar167.y ) );
		p0_nodeVar165 = ( p0_nodeVar165 * vec3<f32>( p0_nodeVar167.z ) );
		p0_nodeVar166 = ( p0_nodeVar166 * vec3<f32>( p0_nodeVar167.w ) );
		p0_nodeVar168 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar138, p0_nodeVar138 ), dot( p0_nodeVar143, p0_nodeVar143 ), dot( p0_nodeVar144, p0_nodeVar144 ), dot( p0_nodeVar145, p0_nodeVar145 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar168 = ( p0_nodeVar168 * p0_nodeVar168 );
		p0_nodeVar100.y = ( p0_nodeVar100.y + ( ( p0_nodeVar101 * ( 42.0 * dot( ( p0_nodeVar168 * p0_nodeVar168 ), vec4<f32>( dot( p0_nodeVar163, p0_nodeVar138 ), dot( p0_nodeVar164, p0_nodeVar143 ), dot( p0_nodeVar165, p0_nodeVar144 ), dot( p0_nodeVar166, p0_nodeVar145 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
		p0_nodeVar169 = vec3<f32>( 0.0, 0.0, 0.0 );
		p0_nodeVar170 = 0.0;
		p0_nodeVar171 = ( sqrt( max( dot( p0_nodeVar100, p0_nodeVar100 ), 0.0001 ) ) * f32((0.69 * knobs.distortionMode + 0)) );
		p0_nodeVar172 = vec2<f32>( ( ( p0_nodeVar100.x * cos( p0_nodeVar171 ) ) - ( p0_nodeVar100.y * sin( p0_nodeVar171 ) ) ), ( ( p0_nodeVar100.x * sin( p0_nodeVar171 ) ) + ( p0_nodeVar100.y * cos( p0_nodeVar171 ) ) ) );
		p0_nodeVar173 = ( p0_nodeVar172 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 1.0 ) ) {

			p0_nodeVar174 = 1.0;

		} else {

			p0_nodeVar174 = 0.0;

		}

		p0_nodeVar175 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar173, p0_nodeVar173 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point1Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar99 + ( 1.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar174 );
		p0_nodeVar169 = ( p0_nodeVar169 + ( vec3<f32>( f32(knobs.point1Color.x), f32(knobs.point1Color.y), f32(knobs.point1Color.z) ) * vec3<f32>( p0_nodeVar175 ) ) );
		p0_nodeVar170 = ( p0_nodeVar170 + p0_nodeVar175 );
		p0_nodeVar176 = ( p0_nodeVar172 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 2.0 ) ) {

			p0_nodeVar177 = 1.0;

		} else {

			p0_nodeVar177 = 0.0;

		}

		p0_nodeVar178 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar176, p0_nodeVar176 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point2Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar99 + ( 2.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar177 );
		p0_nodeVar169 = ( p0_nodeVar169 + ( vec3<f32>( f32(knobs.point2Color.x), f32(knobs.point2Color.y), f32(knobs.point2Color.z) ) * vec3<f32>( p0_nodeVar178 ) ) );
		p0_nodeVar170 = ( p0_nodeVar170 + p0_nodeVar178 );
		p0_nodeVar179 = ( p0_nodeVar172 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 3.0 ) ) {

			p0_nodeVar180 = 1.0;

		} else {

			p0_nodeVar180 = 0.0;

		}

		p0_nodeVar181 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar179, p0_nodeVar179 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point3Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar99 + ( 3.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar180 );
		p0_nodeVar169 = ( p0_nodeVar169 + ( vec3<f32>( f32(knobs.point3Color.x), f32(knobs.point3Color.y), f32(knobs.point3Color.z) ) * vec3<f32>( p0_nodeVar181 ) ) );
		p0_nodeVar170 = ( p0_nodeVar170 + p0_nodeVar181 );
		p0_nodeVar182 = ( p0_nodeVar172 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 4.0 ) ) {

			p0_nodeVar183 = 1.0;

		} else {

			p0_nodeVar183 = 0.0;

		}

		p0_nodeVar184 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar182, p0_nodeVar182 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point4Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar99 + ( 4.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar183 );
		p0_nodeVar169 = ( p0_nodeVar169 + ( vec3<f32>( f32(knobs.point4Color.x), f32(knobs.point4Color.y), f32(knobs.point4Color.z) ) * vec3<f32>( p0_nodeVar184 ) ) );
		p0_nodeVar170 = ( p0_nodeVar170 + p0_nodeVar184 );
		p0_nodeVar185 = ( p0_nodeVar172 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

		if ( ( f32(knobs.activePoints) >= 5.0 ) ) {

			p0_nodeVar186 = 1.0;

		} else {

			p0_nodeVar186 = 0.0;

		}

		p0_nodeVar187 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar185, p0_nodeVar185 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point5Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar99 + ( 5.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar186 );
		p0_nodeVar169 = ( p0_nodeVar169 + ( vec3<f32>( f32(knobs.point5Color.x), f32(knobs.point5Color.y), f32(knobs.point5Color.z) ) * vec3<f32>( p0_nodeVar187 ) ) );
		p0_nodeVar170 = ( p0_nodeVar170 + p0_nodeVar187 );
		p0_nodeVar169 = ( p0_nodeVar169 / vec3<f32>( max( p0_nodeVar170, 0.0001 ) ) );
		p0_nodeVar188 = ( smoothstep( f32(knobs.glowThreshold), 1.0, dot( p0_nodeVar169, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * f32(knobs.glowStrength) );
		p0_nodeVar169 = ( p0_nodeVar169 + vec3<f32>( p0_nodeVar188, p0_nodeVar188, p0_nodeVar188 ) );
		p0_nodeVar189 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * f32(knobs.grainAmount) );
		p0_nodeVar169 = ( p0_nodeVar169 + vec3<f32>( p0_nodeVar189, p0_nodeVar189, p0_nodeVar189 ) );
		p0_nodeVar190 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
		p0_nodeVar169 = ( p0_nodeVar169 * vec3<f32>( mix( 1.0, smoothstep( f32(knobs.vignetteRadius), ( f32(knobs.vignetteRadius) - f32(knobs.vignetteSoftness) ), sqrt( max( dot( p0_nodeVar190, p0_nodeVar190 ), 0.0001 ) ) ), f32(knobs.vignetteStrength) ) ) );
		p0_nodeVar191 = vec4<f32>( clamp( p0_nodeVar169, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
		p0_nodeVar192 = vec3<f32>( p0_nodeVar191.x, p0_nodeVar191.y, p0_nodeVar191.z );
		p0_nodeVar193 = ( ( ( p0_nodeVar192.x * 0.2126 ) + ( p0_nodeVar192.y * 0.7152 ) ) + ( p0_nodeVar192.z * 0.0722 ) );
		p0_nodeVar194 = mix( vec3<f32>( p0_nodeVar193, p0_nodeVar193, p0_nodeVar193 ), p0_nodeVar192, f32(1.0) );
		p0_nodeVar195 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar194.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar194.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar194.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar194.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar194.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar194.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar194.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar194.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar194.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar191.w, 0.0, 1.0 ) );
		p0_nodeVar196 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar195.w, 0.0, 1.0 ) );
		p0_nodeVar198 = ( p0_nodeVar196 + ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - p0_nodeVar196 ) ) );

		if ( ( p0_nodeVar198 > 0.0 ) ) {

			p0_nodeVar197 = p0_nodeVar198;

		} else {

			p0_nodeVar197 = 1.0;

		}

		p0_nodeVar0 = ( ( ( mix( p0_nodeVar195.xyz, p0_nodeVar195.xyz, clamp( p0_nodeVar1.w, 0.0, 1.0 ) ) * vec3<f32>( p0_nodeVar196 ) ) + ( ( p0_nodeVar1.xyz * vec3<f32>( clamp( p0_nodeVar1.w, 0.0, 1.0 ) ) ) * vec3<f32>( ( 1.0 - p0_nodeVar196 ) ) ) ) / vec3<f32>( p0_nodeVar197 ) );

	}

	p0_nodeVar199 = ( ( f32(knobs.time) * f32(1.2566370614359172) ) * f32(array<f32, 6>(0.0, 1.0, 1.0, 1.0, 1.0, 1.0)[u32(knobs.motionStyle)]) );
	p0_nodeVar200 = ( vec2<f32>( ( ( ( nodeVarying4.x * 2.0 ) - 1.0 ) * f32((knobs.resolution.x / knobs.resolution.y)) ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) ) / vec2<f32>( ( 1.0 + ( ( sin( p0_nodeVar199 ) * f32(knobs.motionAmount) ) * 0.06 ) ) ) );
	p0_nodeVar201 = ( f32((0.75 * knobs.warp + 0)) / pow( 1.0, f32((-0.7999999999999998 * knobs.detail + 1.6)) ) );
	p0_nodeVar202 = ( ( ( p0_nodeVar200 * vec2<f32>( f32((1.6000000000000005 * knobs.detail + 0.7299999999999998)) ) ) + vec2<f32>( ( 70.3 * 73.7 ) ) ) + vec2<f32>( 0.0, 0.0 ) );
	p0_nodeVar203 = vec3<f32>( p0_nodeVar202, 100.0 );
	p0_nodeVar204 = floor( ( p0_nodeVar203 + vec3<f32>( dot( p0_nodeVar203, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar205 = ( ( p0_nodeVar203 - p0_nodeVar204 ) + vec3<f32>( dot( p0_nodeVar204, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar206 = step( p0_nodeVar205.yzx, p0_nodeVar205 );
	p0_nodeVar207 = ( vec3<f32>( 1.0 ) - p0_nodeVar206 );
	p0_nodeVar208 = min( p0_nodeVar206, p0_nodeVar207.zxy );
	p0_nodeVar209 = max( p0_nodeVar206, p0_nodeVar207.zxy );
	p0_nodeVar210 = ( ( p0_nodeVar205 - p0_nodeVar208 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar211 = ( ( p0_nodeVar205 - p0_nodeVar209 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar212 = ( ( p0_nodeVar205 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar204 = p0_tsl_mod_vec3( p0_nodeVar204, vec3<f32>( 289.0 ) );
	p0_nodeVar213 = ( vec4<f32>( p0_nodeVar204.z ) + vec4<f32>( 0.0, p0_nodeVar208.z, p0_nodeVar209.z, 1.0 ) );
	p0_nodeVar214 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar213 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar213 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar204.y ) + vec4<f32>( 0.0, p0_nodeVar208.y, p0_nodeVar209.y, 1.0 ) ) );
	p0_nodeVar215 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar214 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar214 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar204.x ) + vec4<f32>( 0.0, p0_nodeVar208.x, p0_nodeVar209.x, 1.0 ) ) );
	p0_nodeVar216 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar215 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar215 ), vec4<f32>( 289.0 ) );
	p0_nodeVar217 = 0.14285714285714285;
	p0_nodeVar218 = ( ( vec3<f32>( p0_nodeVar217 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar219 = ( p0_nodeVar216 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar216 * vec4<f32>( ( p0_nodeVar218.z * p0_nodeVar218.z ) ) ) ) ) );
	p0_nodeVar220 = ( ( floor( ( p0_nodeVar219 * vec4<f32>( p0_nodeVar218.z ) ) ) * vec4<f32>( p0_nodeVar218.x ) ) + vec4<f32>( p0_nodeVar218, 1.0 ).yyyy );
	p0_nodeVar221 = ( ( floor( ( p0_nodeVar219 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar219 * vec4<f32>( p0_nodeVar218.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar218.x ) ) + vec4<f32>( p0_nodeVar218, 1.0 ).yyyy );
	p0_nodeVar222 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar220 ) - abs( p0_nodeVar221 ) ) );
	p0_nodeVar223 = vec4<f32>( p0_nodeVar220.xy, p0_nodeVar221.xy );
	p0_nodeVar224 = vec4<f32>( p0_nodeVar220.zw, p0_nodeVar221.zw );
	p0_nodeVar225 = ( ( floor( p0_nodeVar223 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar226 = ( ( floor( p0_nodeVar224 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar227 = ( - step( p0_nodeVar222, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar228 = ( p0_nodeVar223.xzyw + ( p0_nodeVar225.xzyw * p0_nodeVar227.xxyy ) );
	p0_nodeVar229 = ( p0_nodeVar224.xzyw + ( p0_nodeVar226.xzyw * p0_nodeVar227.zzww ) );
	p0_nodeVar230 = vec3<f32>( p0_nodeVar228.xy, p0_nodeVar222.x );
	p0_nodeVar231 = vec3<f32>( p0_nodeVar228.zw, p0_nodeVar222.y );
	p0_nodeVar232 = vec3<f32>( p0_nodeVar229.xy, p0_nodeVar222.z );
	p0_nodeVar233 = vec3<f32>( p0_nodeVar229.zw, p0_nodeVar222.w );
	p0_nodeVar234 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar230, p0_nodeVar230 ), dot( p0_nodeVar231, p0_nodeVar231 ), dot( p0_nodeVar232, p0_nodeVar232 ), dot( p0_nodeVar233, p0_nodeVar233 ) ) ) );
	p0_nodeVar230 = ( p0_nodeVar230 * vec3<f32>( p0_nodeVar234.x ) );
	p0_nodeVar231 = ( p0_nodeVar231 * vec3<f32>( p0_nodeVar234.y ) );
	p0_nodeVar232 = ( p0_nodeVar232 * vec3<f32>( p0_nodeVar234.z ) );
	p0_nodeVar233 = ( p0_nodeVar233 * vec3<f32>( p0_nodeVar234.w ) );
	p0_nodeVar235 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar205, p0_nodeVar205 ), dot( p0_nodeVar210, p0_nodeVar210 ), dot( p0_nodeVar211, p0_nodeVar211 ), dot( p0_nodeVar212, p0_nodeVar212 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar235 = ( p0_nodeVar235 * p0_nodeVar235 );
	p0_nodeVar200.x = ( p0_nodeVar200.x + ( ( p0_nodeVar201 * ( 42.0 * dot( ( p0_nodeVar235 * p0_nodeVar235 ), vec4<f32>( dot( p0_nodeVar230, p0_nodeVar205 ), dot( p0_nodeVar231, p0_nodeVar210 ), dot( p0_nodeVar232, p0_nodeVar211 ), dot( p0_nodeVar233, p0_nodeVar212 ) ) ) ) ) * ( f32(0.5) * 2.0 ) ) );
	p0_nodeVar236 = vec3<f32>( ( p0_nodeVar202 + vec2<f32>( 13.7, 7.1 ) ), 200.0 );
	p0_nodeVar237 = floor( ( p0_nodeVar236 + vec3<f32>( dot( p0_nodeVar236, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar238 = ( ( p0_nodeVar236 - p0_nodeVar237 ) + vec3<f32>( dot( p0_nodeVar237, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar239 = step( p0_nodeVar238.yzx, p0_nodeVar238 );
	p0_nodeVar240 = ( vec3<f32>( 1.0 ) - p0_nodeVar239 );
	p0_nodeVar241 = min( p0_nodeVar239, p0_nodeVar240.zxy );
	p0_nodeVar242 = max( p0_nodeVar239, p0_nodeVar240.zxy );
	p0_nodeVar243 = ( ( p0_nodeVar238 - p0_nodeVar241 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar244 = ( ( p0_nodeVar238 - p0_nodeVar242 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar245 = ( ( p0_nodeVar238 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar237 = p0_tsl_mod_vec3( p0_nodeVar237, vec3<f32>( 289.0 ) );
	p0_nodeVar246 = ( vec4<f32>( p0_nodeVar237.z ) + vec4<f32>( 0.0, p0_nodeVar241.z, p0_nodeVar242.z, 1.0 ) );
	p0_nodeVar247 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar246 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar246 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar237.y ) + vec4<f32>( 0.0, p0_nodeVar241.y, p0_nodeVar242.y, 1.0 ) ) );
	p0_nodeVar248 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar247 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar247 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar237.x ) + vec4<f32>( 0.0, p0_nodeVar241.x, p0_nodeVar242.x, 1.0 ) ) );
	p0_nodeVar249 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar248 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar248 ), vec4<f32>( 289.0 ) );
	p0_nodeVar250 = 0.14285714285714285;
	p0_nodeVar251 = ( ( vec3<f32>( p0_nodeVar250 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar252 = ( p0_nodeVar249 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar249 * vec4<f32>( ( p0_nodeVar251.z * p0_nodeVar251.z ) ) ) ) ) );
	p0_nodeVar253 = ( ( floor( ( p0_nodeVar252 * vec4<f32>( p0_nodeVar251.z ) ) ) * vec4<f32>( p0_nodeVar251.x ) ) + vec4<f32>( p0_nodeVar251, 1.0 ).yyyy );
	p0_nodeVar254 = ( ( floor( ( p0_nodeVar252 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar252 * vec4<f32>( p0_nodeVar251.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar251.x ) ) + vec4<f32>( p0_nodeVar251, 1.0 ).yyyy );
	p0_nodeVar255 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar253 ) - abs( p0_nodeVar254 ) ) );
	p0_nodeVar256 = vec4<f32>( p0_nodeVar253.xy, p0_nodeVar254.xy );
	p0_nodeVar257 = vec4<f32>( p0_nodeVar253.zw, p0_nodeVar254.zw );
	p0_nodeVar258 = ( ( floor( p0_nodeVar256 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar259 = ( ( floor( p0_nodeVar257 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar260 = ( - step( p0_nodeVar255, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar261 = ( p0_nodeVar256.xzyw + ( p0_nodeVar258.xzyw * p0_nodeVar260.xxyy ) );
	p0_nodeVar262 = ( p0_nodeVar257.xzyw + ( p0_nodeVar259.xzyw * p0_nodeVar260.zzww ) );
	p0_nodeVar263 = vec3<f32>( p0_nodeVar261.xy, p0_nodeVar255.x );
	p0_nodeVar264 = vec3<f32>( p0_nodeVar261.zw, p0_nodeVar255.y );
	p0_nodeVar265 = vec3<f32>( p0_nodeVar262.xy, p0_nodeVar255.z );
	p0_nodeVar266 = vec3<f32>( p0_nodeVar262.zw, p0_nodeVar255.w );
	p0_nodeVar267 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar263, p0_nodeVar263 ), dot( p0_nodeVar264, p0_nodeVar264 ), dot( p0_nodeVar265, p0_nodeVar265 ), dot( p0_nodeVar266, p0_nodeVar266 ) ) ) );
	p0_nodeVar263 = ( p0_nodeVar263 * vec3<f32>( p0_nodeVar267.x ) );
	p0_nodeVar264 = ( p0_nodeVar264 * vec3<f32>( p0_nodeVar267.y ) );
	p0_nodeVar265 = ( p0_nodeVar265 * vec3<f32>( p0_nodeVar267.z ) );
	p0_nodeVar266 = ( p0_nodeVar266 * vec3<f32>( p0_nodeVar267.w ) );
	p0_nodeVar268 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar238, p0_nodeVar238 ), dot( p0_nodeVar243, p0_nodeVar243 ), dot( p0_nodeVar244, p0_nodeVar244 ), dot( p0_nodeVar245, p0_nodeVar245 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar268 = ( p0_nodeVar268 * p0_nodeVar268 );
	p0_nodeVar200.y = ( p0_nodeVar200.y + ( ( p0_nodeVar201 * ( 42.0 * dot( ( p0_nodeVar268 * p0_nodeVar268 ), vec4<f32>( dot( p0_nodeVar263, p0_nodeVar238 ), dot( p0_nodeVar264, p0_nodeVar243 ), dot( p0_nodeVar265, p0_nodeVar244 ), dot( p0_nodeVar266, p0_nodeVar245 ) ) ) ) ) * ( ( 1.0 - f32(0.5) ) * 2.0 ) ) );
	p0_nodeVar269 = vec3<f32>( 0.0, 0.0, 0.0 );
	p0_nodeVar270 = 0.0;
	p0_nodeVar271 = ( sqrt( max( dot( p0_nodeVar200, p0_nodeVar200 ), 0.0001 ) ) * f32((0.69 * knobs.distortionMode + 0)) );
	p0_nodeVar272 = vec2<f32>( ( ( p0_nodeVar200.x * cos( p0_nodeVar271 ) ) - ( p0_nodeVar200.y * sin( p0_nodeVar271 ) ) ), ( ( p0_nodeVar200.x * sin( p0_nodeVar271 ) ) + ( p0_nodeVar200.y * cos( p0_nodeVar271 ) ) ) );
	p0_nodeVar273 = ( p0_nodeVar272 - ( vec2<f32>( f32(-1.15), f32(0.55) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( f32(knobs.activePoints) >= 1.0 ) ) {

		p0_nodeVar274 = 1.0;

	} else {

		p0_nodeVar274 = 0.0;

	}

	p0_nodeVar275 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar273, p0_nodeVar273 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point1Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar199 + ( 1.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar274 );
	p0_nodeVar269 = ( p0_nodeVar269 + ( vec3<f32>( f32(knobs.point1Color.x), f32(knobs.point1Color.y), f32(knobs.point1Color.z) ) * vec3<f32>( p0_nodeVar275 ) ) );
	p0_nodeVar270 = ( p0_nodeVar270 + p0_nodeVar275 );
	p0_nodeVar276 = ( p0_nodeVar272 - ( vec2<f32>( f32(1.05), f32(0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( f32(knobs.activePoints) >= 2.0 ) ) {

		p0_nodeVar277 = 1.0;

	} else {

		p0_nodeVar277 = 0.0;

	}

	p0_nodeVar278 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar276, p0_nodeVar276 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point2Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar199 + ( 2.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar277 );
	p0_nodeVar269 = ( p0_nodeVar269 + ( vec3<f32>( f32(knobs.point2Color.x), f32(knobs.point2Color.y), f32(knobs.point2Color.z) ) * vec3<f32>( p0_nodeVar278 ) ) );
	p0_nodeVar270 = ( p0_nodeVar270 + p0_nodeVar278 );
	p0_nodeVar279 = ( p0_nodeVar272 - ( vec2<f32>( f32(0.05), f32(-0.15) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( f32(knobs.activePoints) >= 3.0 ) ) {

		p0_nodeVar280 = 1.0;

	} else {

		p0_nodeVar280 = 0.0;

	}

	p0_nodeVar281 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar279, p0_nodeVar279 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point3Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar199 + ( 3.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar280 );
	p0_nodeVar269 = ( p0_nodeVar269 + ( vec3<f32>( f32(knobs.point3Color.x), f32(knobs.point3Color.y), f32(knobs.point3Color.z) ) * vec3<f32>( p0_nodeVar281 ) ) );
	p0_nodeVar270 = ( p0_nodeVar270 + p0_nodeVar281 );
	p0_nodeVar282 = ( p0_nodeVar272 - ( vec2<f32>( f32(-0.7), f32(-0.8) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( f32(knobs.activePoints) >= 4.0 ) ) {

		p0_nodeVar283 = 1.0;

	} else {

		p0_nodeVar283 = 0.0;

	}

	p0_nodeVar284 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar282, p0_nodeVar282 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point4Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar199 + ( 4.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar283 );
	p0_nodeVar269 = ( p0_nodeVar269 + ( vec3<f32>( f32(knobs.point4Color.x), f32(knobs.point4Color.y), f32(knobs.point4Color.z) ) * vec3<f32>( p0_nodeVar284 ) ) );
	p0_nodeVar270 = ( p0_nodeVar270 + p0_nodeVar284 );
	p0_nodeVar285 = ( p0_nodeVar272 - ( vec2<f32>( f32(1.2), f32(-0.7) ) + vec2<f32>( 0.0, 0.0 ) ) );

	if ( ( f32(knobs.activePoints) >= 5.0 ) ) {

		p0_nodeVar286 = 1.0;

	} else {

		p0_nodeVar286 = 0.0;

	}

	p0_nodeVar287 = ( ( ( ( 1.0 / max( pow( sqrt( max( ( dot( p0_nodeVar285, p0_nodeVar285 ) + ( f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) * f32((0.21999999999999997 * knobs.softness + 0.08000000000000002)) ) ), 0.0001 ) ), f32((-3.4000000000000004 * knobs.softness + 4.6)) ), 0.0001 ) ) * f32(knobs.point5Weight) ) * ( 1.0 + ( ( sin( ( p0_nodeVar199 + ( 5.0 * 1.25 ) ) ) * f32(knobs.motionAmount) ) * 0.6 ) ) ) * p0_nodeVar286 );
	p0_nodeVar269 = ( p0_nodeVar269 + ( vec3<f32>( f32(knobs.point5Color.x), f32(knobs.point5Color.y), f32(knobs.point5Color.z) ) * vec3<f32>( p0_nodeVar287 ) ) );
	p0_nodeVar270 = ( p0_nodeVar270 + p0_nodeVar287 );
	p0_nodeVar269 = ( p0_nodeVar269 / vec3<f32>( max( p0_nodeVar270, 0.0001 ) ) );
	p0_nodeVar288 = ( smoothstep( f32(knobs.glowThreshold), 1.0, dot( p0_nodeVar269, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) * f32(knobs.glowStrength) );
	p0_nodeVar269 = ( p0_nodeVar269 + vec3<f32>( p0_nodeVar288, p0_nodeVar288, p0_nodeVar288 ) );
	p0_nodeVar289 = ( ( fract( ( sin( dot( nodeVarying4, vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * f32(knobs.grainAmount) );
	p0_nodeVar269 = ( p0_nodeVar269 + vec3<f32>( p0_nodeVar289, p0_nodeVar289, p0_nodeVar289 ) );
	p0_nodeVar290 = vec2<f32>( ( ( nodeVarying4.x * 2.0 ) - 1.0 ), ( ( ( 1.0 - nodeVarying4.y ) * 2.0 ) - 1.0 ) );
	p0_nodeVar269 = ( p0_nodeVar269 * vec3<f32>( mix( 1.0, smoothstep( f32(knobs.vignetteRadius), ( f32(knobs.vignetteRadius) - f32(knobs.vignetteSoftness) ), sqrt( max( dot( p0_nodeVar290, p0_nodeVar290 ), 0.0001 ) ) ), f32(knobs.vignetteStrength) ) ) );
	p0_nodeVar291 = vec4<f32>( clamp( p0_nodeVar269, vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p0_nodeVar292 = vec3<f32>( p0_nodeVar291.x, p0_nodeVar291.y, p0_nodeVar291.z );
	p0_nodeVar293 = ( ( ( p0_nodeVar292.x * 0.2126 ) + ( p0_nodeVar292.y * 0.7152 ) ) + ( p0_nodeVar292.z * 0.0722 ) );
	p0_nodeVar294 = mix( vec3<f32>( p0_nodeVar293, p0_nodeVar293, p0_nodeVar293 ), p0_nodeVar292, f32(1.0) );
	p0_nodeVar295 = ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar294.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar294.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar294.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar294.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar294.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar294.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar294.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar294.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar294.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar291.w, 0.0, 1.0 ) ).w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( p0_nodeVar0, ( p0_nodeVar295 + ( clamp( p0_nodeVar1.w, 0.0, 1.0 ) * ( 1.0 - p0_nodeVar295 ) ) ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar296 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar296;

	// result

	p0_output.color = p0_nodeVar296;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

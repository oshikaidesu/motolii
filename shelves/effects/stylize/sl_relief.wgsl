// Relief: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Embosses or debosses the image into a lit surface: silver plate, letterpress, blind emboss or gold foil.
// --check@relief:Relief,0
// --track@heightFrom:Height From,0,2,0,1
// --track@depth:Depth,0,4,1.4,0.01
// --track@bevel:Bevel,1,32,2,0.5
// --track@amount:Amount,0,1,1,0.01
// --track@lightAngle:Light Angle,0,360,135,1
// --track@elevation:Elevation,5,90,38,1
// --track@ambient:Ambient,0,1,0.35,0.01
// --check@surface:Surface,0
// --track@color_x:Color r,0,1,0.33245153633549385,0.001
// --track@color_y:Color g,0,1,0.34191442489801843,0.001
// --track@color_z:Color b,0,1,0.35640014413537763,0.001
// --track@specular:Specular,0,2,0.8,0.01
// --track@shininess:Shininess,1,128,28,1
// --track@grain:Grain,0,1,0.35,0.01
// --track@grainSize:Grain Size,0.5,8,1.2,0.05
// --track@engrave:Engrave,0,2,2,1
// --track@engraveDepth:Engrave Depth,0,2,0.5,0.01
// --track@lineSpacing:Line Spacing,2,40,5,0.5
// --track@engraveAngle:Line Angle,-180,180,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  relief: f32,
  heightFrom: f32,
  depth: f32,
  bevel: f32,
  amount: f32,
  lightAngle: f32,
  elevation: f32,
  ambient: f32,
  surface: f32,
  color: vec3<f32>,
  specular: f32,
  shininess: f32,
  grain: f32,
  grainSize: f32,
  engrave: f32,
  engraveDepth: f32,
  lineSpacing: f32,
  engraveAngle: f32,
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
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : vec4<f32>;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : vec4<f32>;
var<private> p0_nodeVar8 : vec4<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : vec4<f32>;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : vec3<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : vec2<f32>;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec2<f32>;
var<private> p0_nodeVar39 : vec2<f32>;
var<private> p0_nodeVar40 : vec3<f32>;
var<private> p0_nodeVar41 : vec3<f32>;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : vec3<f32>;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : vec2<f32>;
var<private> p0_nodeVar46 : vec2<f32>;
var<private> p0_nodeVar47 : vec2<f32>;
var<private> p0_nodeVar48 : vec3<f32>;
var<private> p0_nodeVar49 : vec3<f32>;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : vec3<f32>;
var<private> p0_nodeVar52 : vec3<f32>;
var<private> p0_nodeVar53 : vec2<f32>;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : vec2<f32>;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : vec3<f32>;
var<private> p0_nodeVar60 : vec3<f32>;
var<private> p0_nodeVar61 : vec2<f32>;
var<private> p0_nodeVar62 : vec3<f32>;
var<private> p0_nodeVar63 : vec3<f32>;
var<private> p0_nodeVar64 : vec2<f32>;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : vec2<f32>;
var<private> p0_nodeVar67 : vec3<f32>;
var<private> p0_nodeVar68 : vec3<f32>;
var<private> p0_nodeVar69 : vec2<f32>;
var<private> p0_nodeVar70 : vec3<f32>;
var<private> p0_nodeVar71 : vec3<f32>;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : vec2<f32>;
var<private> p0_nodeVar74 : vec2<f32>;
var<private> p0_nodeVar75 : vec2<f32>;
var<private> p0_nodeVar76 : vec3<f32>;
var<private> p0_nodeVar77 : vec3<f32>;
var<private> p0_nodeVar78 : vec2<f32>;
var<private> p0_nodeVar79 : vec3<f32>;
var<private> p0_nodeVar80 : vec3<f32>;
var<private> p0_nodeVar81 : vec2<f32>;
var<private> p0_nodeVar82 : vec2<f32>;
var<private> p0_nodeVar83 : vec2<f32>;
var<private> p0_nodeVar84 : vec3<f32>;
var<private> p0_nodeVar85 : vec3<f32>;
var<private> p0_nodeVar86 : vec2<f32>;
var<private> p0_nodeVar87 : vec3<f32>;
var<private> p0_nodeVar88 : vec3<f32>;
var<private> p0_nodeVar89 : vec2<f32>;
var<private> p0_nodeVar90 : vec3<f32>;
var<private> p0_nodeVar91 : vec3<f32>;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : f32;
var<private> p0_nodeVar94 : vec2<f32>;
var<private> p0_nodeVar95 : f32;
var<private> p0_nodeVar96 : vec2<f32>;
var<private> p0_nodeVar97 : vec2<f32>;
var<private> p0_nodeVar98 : vec3<f32>;
var<private> p0_nodeVar99 : vec3<f32>;
var<private> p0_nodeVar100 : vec2<f32>;
var<private> p0_nodeVar101 : vec3<f32>;
var<private> p0_nodeVar102 : vec3<f32>;
var<private> p0_nodeVar103 : vec2<f32>;
var<private> p0_nodeVar104 : vec2<f32>;
var<private> p0_nodeVar105 : vec2<f32>;
var<private> p0_nodeVar106 : vec3<f32>;
var<private> p0_nodeVar107 : vec3<f32>;
var<private> p0_nodeVar108 : vec2<f32>;
var<private> p0_nodeVar109 : vec3<f32>;
var<private> p0_nodeVar110 : vec3<f32>;
var<private> p0_nodeVar111 : vec2<f32>;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : vec2<f32>;
var<private> p0_nodeVar116 : vec2<f32>;
var<private> p0_nodeVar117 : vec3<f32>;
var<private> p0_nodeVar118 : vec3<f32>;
var<private> p0_nodeVar119 : vec2<f32>;
var<private> p0_nodeVar120 : vec3<f32>;
var<private> p0_nodeVar121 : vec3<f32>;
var<private> p0_nodeVar122 : vec2<f32>;
var<private> p0_nodeVar123 : vec2<f32>;
var<private> p0_nodeVar124 : vec2<f32>;
var<private> p0_nodeVar125 : vec3<f32>;
var<private> p0_nodeVar126 : vec3<f32>;
var<private> p0_nodeVar127 : vec2<f32>;
var<private> p0_nodeVar128 : vec3<f32>;
var<private> p0_nodeVar129 : vec3<f32>;
var<private> p0_nodeVar130 : f32;
var<private> p0_nodeVar131 : vec2<f32>;
var<private> p0_nodeVar132 : vec2<f32>;
var<private> p0_nodeVar133 : vec2<f32>;
var<private> p0_nodeVar134 : vec3<f32>;
var<private> p0_nodeVar135 : vec3<f32>;
var<private> p0_nodeVar136 : vec2<f32>;
var<private> p0_nodeVar137 : vec3<f32>;
var<private> p0_nodeVar138 : vec3<f32>;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : vec2<f32>;
var<private> p0_nodeVar141 : vec2<f32>;
var<private> p0_nodeVar142 : vec3<f32>;
var<private> p0_nodeVar143 : vec3<f32>;
var<private> p0_nodeVar144 : vec2<f32>;
var<private> p0_nodeVar145 : vec3<f32>;
var<private> p0_nodeVar146 : vec3<f32>;
var<private> p0_nodeVar147 : vec2<f32>;
var<private> p0_nodeVar148 : vec3<f32>;
var<private> p0_nodeVar149 : vec3<f32>;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : vec2<f32>;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : vec2<f32>;
var<private> p0_nodeVar155 : vec2<f32>;
var<private> p0_nodeVar156 : vec3<f32>;
var<private> p0_nodeVar157 : vec3<f32>;
var<private> p0_nodeVar158 : vec2<f32>;
var<private> p0_nodeVar159 : vec3<f32>;
var<private> p0_nodeVar160 : vec3<f32>;
var<private> p0_nodeVar161 : vec2<f32>;
var<private> p0_nodeVar162 : vec2<f32>;
var<private> p0_nodeVar163 : vec2<f32>;
var<private> p0_nodeVar164 : vec3<f32>;
var<private> p0_nodeVar165 : vec3<f32>;
var<private> p0_nodeVar166 : vec2<f32>;
var<private> p0_nodeVar167 : vec3<f32>;
var<private> p0_nodeVar168 : vec3<f32>;
var<private> p0_nodeVar169 : vec2<f32>;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : f32;
var<private> p0_nodeVar173 : vec2<f32>;
var<private> p0_nodeVar174 : vec2<f32>;
var<private> p0_nodeVar175 : vec3<f32>;
var<private> p0_nodeVar176 : vec3<f32>;
var<private> p0_nodeVar177 : vec2<f32>;
var<private> p0_nodeVar178 : vec3<f32>;
var<private> p0_nodeVar179 : vec3<f32>;
var<private> p0_nodeVar180 : vec2<f32>;
var<private> p0_nodeVar181 : vec2<f32>;
var<private> p0_nodeVar182 : vec2<f32>;
var<private> p0_nodeVar183 : vec3<f32>;
var<private> p0_nodeVar184 : vec3<f32>;
var<private> p0_nodeVar185 : vec2<f32>;
var<private> p0_nodeVar186 : vec3<f32>;
var<private> p0_nodeVar187 : vec3<f32>;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : vec2<f32>;
var<private> p0_nodeVar190 : vec2<f32>;
var<private> p0_nodeVar191 : vec2<f32>;
var<private> p0_nodeVar192 : vec3<f32>;
var<private> p0_nodeVar193 : vec3<f32>;
var<private> p0_nodeVar194 : vec2<f32>;
var<private> p0_nodeVar195 : vec3<f32>;
var<private> p0_nodeVar196 : vec3<f32>;
var<private> p0_nodeVar197 : vec2<f32>;
var<private> p0_nodeVar198 : vec2<f32>;
var<private> p0_nodeVar199 : vec2<f32>;
var<private> p0_nodeVar200 : vec3<f32>;
var<private> p0_nodeVar201 : vec3<f32>;
var<private> p0_nodeVar202 : vec2<f32>;
var<private> p0_nodeVar203 : vec3<f32>;
var<private> p0_nodeVar204 : vec3<f32>;
var<private> p0_nodeVar205 : vec2<f32>;
var<private> p0_nodeVar206 : vec3<f32>;
var<private> p0_nodeVar207 : vec3<f32>;
var<private> p0_nodeVar208 : f32;
var<private> p0_nodeVar209 : f32;
var<private> p0_nodeVar210 : vec2<f32>;
var<private> p0_nodeVar211 : f32;
var<private> p0_nodeVar212 : vec2<f32>;
var<private> p0_nodeVar213 : vec2<f32>;
var<private> p0_nodeVar214 : vec3<f32>;
var<private> p0_nodeVar215 : vec3<f32>;
var<private> p0_nodeVar216 : vec2<f32>;
var<private> p0_nodeVar217 : vec3<f32>;
var<private> p0_nodeVar218 : vec3<f32>;
var<private> p0_nodeVar219 : vec2<f32>;
var<private> p0_nodeVar220 : vec2<f32>;
var<private> p0_nodeVar221 : vec2<f32>;
var<private> p0_nodeVar222 : vec3<f32>;
var<private> p0_nodeVar223 : vec3<f32>;
var<private> p0_nodeVar224 : vec2<f32>;
var<private> p0_nodeVar225 : vec3<f32>;
var<private> p0_nodeVar226 : vec3<f32>;
var<private> p0_nodeVar227 : vec2<f32>;
var<private> p0_nodeVar228 : f32;
var<private> p0_nodeVar229 : f32;
var<private> p0_nodeVar230 : f32;
var<private> p0_nodeVar231 : vec2<f32>;
var<private> p0_nodeVar232 : vec2<f32>;
var<private> p0_nodeVar233 : vec3<f32>;
var<private> p0_nodeVar234 : vec3<f32>;
var<private> p0_nodeVar235 : vec2<f32>;
var<private> p0_nodeVar236 : vec3<f32>;
var<private> p0_nodeVar237 : vec3<f32>;
var<private> p0_nodeVar238 : vec2<f32>;
var<private> p0_nodeVar239 : vec2<f32>;
var<private> p0_nodeVar240 : vec2<f32>;
var<private> p0_nodeVar241 : vec3<f32>;
var<private> p0_nodeVar242 : vec3<f32>;
var<private> p0_nodeVar243 : vec2<f32>;
var<private> p0_nodeVar244 : vec3<f32>;
var<private> p0_nodeVar245 : vec3<f32>;
var<private> p0_nodeVar246 : f32;
var<private> p0_nodeVar247 : vec2<f32>;
var<private> p0_nodeVar248 : vec2<f32>;
var<private> p0_nodeVar249 : vec2<f32>;
var<private> p0_nodeVar250 : vec3<f32>;
var<private> p0_nodeVar251 : vec3<f32>;
var<private> p0_nodeVar252 : vec2<f32>;
var<private> p0_nodeVar253 : vec3<f32>;
var<private> p0_nodeVar254 : vec3<f32>;
var<private> p0_nodeVar255 : vec2<f32>;
var<private> p0_nodeVar256 : vec2<f32>;
var<private> p0_nodeVar257 : vec2<f32>;
var<private> p0_nodeVar258 : vec3<f32>;
var<private> p0_nodeVar259 : vec3<f32>;
var<private> p0_nodeVar260 : vec2<f32>;
var<private> p0_nodeVar261 : vec3<f32>;
var<private> p0_nodeVar262 : vec3<f32>;
var<private> p0_nodeVar263 : vec2<f32>;
var<private> p0_nodeVar264 : vec3<f32>;
var<private> p0_nodeVar265 : vec3<f32>;
var<private> p0_nodeVar266 : vec3<f32>;
var<private> p0_nodeVar267 : f32;
var<private> p0_nodeVar268 : vec3<f32>;
var<private> p0_nodeVar269 : f32;
var<private> p0_nodeVar270 : f32;
var<private> p0_nodeVar271 : vec3<f32>;
var<private> p0_nodeVar272 : vec3<f32>;
var<private> p0_nodeVar273 : vec4<f32>;
var<private> p0_nodeVar274 : vec3<f32>;
var<private> p0_nodeVar275 : f32;
var<private> p0_nodeVar276 : vec3<f32>;
var<private> p0_nodeVar277 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar278 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = picture_read( p0_nodeVar1 );
	p0_nodeVar3 = p0_nodeVar2;
	p0_nodeVar4 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar5 = ( vec2<f32>( ( 1.0 / p0_nodeVar4.x ), ( 1.0 / p0_nodeVar4.y ) ) * vec2<f32>( f32(knobs.bevel) ) );
	p0_nodeVar6 = picture_read( ( p0_nodeVar1 + vec2<f32>( p0_nodeVar5.x, 0.0 ) ) );
	p0_nodeVar7 = p0_nodeVar6;
	p0_nodeVar8 = picture_read( ( p0_nodeVar1 - vec2<f32>( p0_nodeVar5.x, 0.0 ) ) );
	p0_nodeVar9 = p0_nodeVar8;
	p0_nodeVar10 = picture_read( ( p0_nodeVar1 + vec2<f32>( 0.0, p0_nodeVar5.y ) ) );
	p0_nodeVar11 = p0_nodeVar10;
	p0_nodeVar12 = picture_read( ( p0_nodeVar1 - vec2<f32>( 0.0, p0_nodeVar5.y ) ) );
	p0_nodeVar13 = p0_nodeVar12;
	p0_nodeVar14 = p0_nodeVar3.w;
	p0_nodeVar15 = p0_nodeVar7.w;
	p0_nodeVar16 = p0_nodeVar9.w;
	p0_nodeVar17 = p0_nodeVar11.w;
	p0_nodeVar18 = p0_nodeVar13.w;

	if ( ( f32(knobs.heightFrom) < 0.5 ) ) {

		p0_nodeVar20 = clamp( dot( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar20 <= 0.0031308 ) ) {

			p0_nodeVar19 = ( p0_nodeVar20 * 12.92 );

		} else {

			p0_nodeVar19 = ( ( pow( p0_nodeVar20, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar14 = p0_nodeVar19;
		p0_nodeVar22 = clamp( dot( vec3<f32>( p0_nodeVar7.x, p0_nodeVar7.y, p0_nodeVar7.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar22 <= 0.0031308 ) ) {

			p0_nodeVar21 = ( p0_nodeVar22 * 12.92 );

		} else {

			p0_nodeVar21 = ( ( pow( p0_nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar15 = p0_nodeVar21;
		p0_nodeVar24 = clamp( dot( vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar24 <= 0.0031308 ) ) {

			p0_nodeVar23 = ( p0_nodeVar24 * 12.92 );

		} else {

			p0_nodeVar23 = ( ( pow( p0_nodeVar24, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar16 = p0_nodeVar23;
		p0_nodeVar26 = clamp( dot( vec3<f32>( p0_nodeVar11.x, p0_nodeVar11.y, p0_nodeVar11.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar26 <= 0.0031308 ) ) {

			p0_nodeVar25 = ( p0_nodeVar26 * 12.92 );

		} else {

			p0_nodeVar25 = ( ( pow( p0_nodeVar26, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar17 = p0_nodeVar25;
		p0_nodeVar28 = clamp( dot( vec3<f32>( p0_nodeVar13.x, p0_nodeVar13.y, p0_nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar28 <= 0.0031308 ) ) {

			p0_nodeVar27 = ( p0_nodeVar28 * 12.92 );

		} else {

			p0_nodeVar27 = ( ( pow( p0_nodeVar28, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar18 = p0_nodeVar27;
		

	} else {


		if ( ( f32(knobs.heightFrom) < 1.5 ) ) {

			p0_nodeVar14 = p0_nodeVar3.x;
			p0_nodeVar15 = p0_nodeVar7.x;
			p0_nodeVar16 = p0_nodeVar9.x;
			p0_nodeVar17 = p0_nodeVar11.x;
			p0_nodeVar18 = p0_nodeVar13.x;
			

		}

		

	}

	p0_nodeVar29 = ( p0_nodeVar1 * p0_nodeVar4 );
	p0_nodeVar30 = picture_read( p0_nodeVar1 );
	p0_nodeVar31 = vec3<f32>( p0_nodeVar30.x, p0_nodeVar30.y, p0_nodeVar30.z );
	p0_nodeVar32 = 0.0;
	p0_nodeVar33 = 0.0;

	if ( ( ( f32(knobs.engraveDepth) > 0.0 ) || ( f32(knobs.grain) > 0.0 ) ) ) {


		if ( ( f32(knobs.engrave) < 0.5 ) ) {

			p0_nodeVar34 = 0.0;

		} else {


			if ( ( f32(knobs.engrave) < 1.5 ) ) {

				p0_nodeVar36 = ( p0_nodeVar29 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar37 = ( f32(knobs.engraveAngle) * 0.017453292519943295 );
				p0_nodeVar38 = vec2<f32>( ( ( ( p0_nodeVar36.y * cos( p0_nodeVar37 ) ) - ( p0_nodeVar36.x * sin( p0_nodeVar37 ) ) ) / ( f32(knobs.lineSpacing) * 9.0 ) ), 3.1 );
				p0_nodeVar39 = floor( p0_nodeVar38 );
				p0_nodeVar40 = fract( ( vec3<f32>( p0_nodeVar39.x, p0_nodeVar39.y, p0_nodeVar39.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar41 = ( p0_nodeVar40 + vec3<f32>( dot( p0_nodeVar40, ( vec3<f32>( p0_nodeVar40.y, p0_nodeVar40.z, p0_nodeVar40.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar42 = ( p0_nodeVar39 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar43 = fract( ( vec3<f32>( p0_nodeVar42.x, p0_nodeVar42.y, p0_nodeVar42.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar44 = ( p0_nodeVar43 + vec3<f32>( dot( p0_nodeVar43, ( vec3<f32>( p0_nodeVar43.y, p0_nodeVar43.z, p0_nodeVar43.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar45 = fract( p0_nodeVar38 );
				p0_nodeVar46 = ( ( p0_nodeVar45 * p0_nodeVar45 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar45 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar47 = ( p0_nodeVar39 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar48 = fract( ( vec3<f32>( p0_nodeVar47.x, p0_nodeVar47.y, p0_nodeVar47.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar49 = ( p0_nodeVar48 + vec3<f32>( dot( p0_nodeVar48, ( vec3<f32>( p0_nodeVar48.y, p0_nodeVar48.z, p0_nodeVar48.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar50 = ( p0_nodeVar39 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar51 = fract( ( vec3<f32>( p0_nodeVar50.x, p0_nodeVar50.y, p0_nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar52 = ( p0_nodeVar51 + vec3<f32>( dot( p0_nodeVar51, ( vec3<f32>( p0_nodeVar51.y, p0_nodeVar51.z, p0_nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar35 = cos( ( ( ( ( ( p0_nodeVar36.x * cos( p0_nodeVar37 ) ) + ( p0_nodeVar36.y * sin( p0_nodeVar37 ) ) ) + ( ( mix( mix( fract( ( ( p0_nodeVar41.x + p0_nodeVar41.y ) * p0_nodeVar41.z ) ), fract( ( ( p0_nodeVar44.x + p0_nodeVar44.y ) * p0_nodeVar44.z ) ), p0_nodeVar46.x ), mix( fract( ( ( p0_nodeVar49.x + p0_nodeVar49.y ) * p0_nodeVar49.z ) ), fract( ( ( p0_nodeVar52.x + p0_nodeVar52.y ) * p0_nodeVar52.z ) ), p0_nodeVar46.x ), p0_nodeVar46.y ) - 0.5 ) * ( f32(knobs.lineSpacing) * 0.8 ) ) ) / f32(knobs.lineSpacing) ) * 6.283185307179586 ) );

			} else {

				p0_nodeVar53 = ( ( p0_nodeVar29 + vec2<f32>( 1.0, 0.0 ) ) - ( p0_nodeVar4 * vec2<f32>( 0.5 ) ) );
				p0_nodeVar54 = atan2( p0_nodeVar53.y, p0_nodeVar53.x );
				p0_nodeVar55 = ( ( min( p0_nodeVar4.x, p0_nodeVar4.y ) * 1.5707963267948966 ) / f32(knobs.lineSpacing) );
				p0_nodeVar56 = length( p0_nodeVar53 );
				p0_nodeVar57 = vec2<f32>( ( ( p0_nodeVar54 * p0_nodeVar55 ) / 6.2831853 ), ( p0_nodeVar56 / ( f32(knobs.lineSpacing) * 14.0 ) ) );
				p0_nodeVar58 = floor( p0_nodeVar57 );
				p0_nodeVar59 = fract( ( vec3<f32>( p0_nodeVar58.x, p0_nodeVar58.y, p0_nodeVar58.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar60 = ( p0_nodeVar59 + vec3<f32>( dot( p0_nodeVar59, ( vec3<f32>( p0_nodeVar59.y, p0_nodeVar59.z, p0_nodeVar59.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar61 = ( p0_nodeVar58 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar62 = fract( ( vec3<f32>( p0_nodeVar61.x, p0_nodeVar61.y, p0_nodeVar61.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar63 = ( p0_nodeVar62 + vec3<f32>( dot( p0_nodeVar62, ( vec3<f32>( p0_nodeVar62.y, p0_nodeVar62.z, p0_nodeVar62.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar64 = fract( p0_nodeVar57 );
				p0_nodeVar65 = ( ( p0_nodeVar64 * p0_nodeVar64 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar64 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar66 = ( p0_nodeVar58 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar67 = fract( ( vec3<f32>( p0_nodeVar66.x, p0_nodeVar66.y, p0_nodeVar66.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar68 = ( p0_nodeVar67 + vec3<f32>( dot( p0_nodeVar67, ( vec3<f32>( p0_nodeVar67.y, p0_nodeVar67.z, p0_nodeVar67.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar69 = ( p0_nodeVar58 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar70 = fract( ( vec3<f32>( p0_nodeVar69.x, p0_nodeVar69.y, p0_nodeVar69.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar71 = ( p0_nodeVar70 + vec3<f32>( dot( p0_nodeVar70, ( vec3<f32>( p0_nodeVar70.y, p0_nodeVar70.z, p0_nodeVar70.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar72 = min( p0_nodeVar4.x, p0_nodeVar4.y );
				p0_nodeVar35 = ( cos( ( ( p0_nodeVar54 * p0_nodeVar55 ) + ( ( mix( mix( fract( ( ( p0_nodeVar60.x + p0_nodeVar60.y ) * p0_nodeVar60.z ) ), fract( ( ( p0_nodeVar63.x + p0_nodeVar63.y ) * p0_nodeVar63.z ) ), p0_nodeVar65.x ), mix( fract( ( ( p0_nodeVar68.x + p0_nodeVar68.y ) * p0_nodeVar68.z ) ), fract( ( ( p0_nodeVar71.x + p0_nodeVar71.y ) * p0_nodeVar71.z ) ), p0_nodeVar65.x ), p0_nodeVar65.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( p0_nodeVar72 * 0.06 ), ( p0_nodeVar72 * 0.22 ), p0_nodeVar56 ) );

			}

			p0_nodeVar34 = p0_nodeVar35;

		}

		p0_nodeVar73 = ( p0_nodeVar29 + vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar74 = ( p0_nodeVar73 / vec2<f32>( f32(knobs.grainSize) ) );
		p0_nodeVar75 = floor( p0_nodeVar74 );
		p0_nodeVar76 = fract( ( vec3<f32>( p0_nodeVar75.x, p0_nodeVar75.y, p0_nodeVar75.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar77 = ( p0_nodeVar76 + vec3<f32>( dot( p0_nodeVar76, ( vec3<f32>( p0_nodeVar76.y, p0_nodeVar76.z, p0_nodeVar76.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar78 = ( p0_nodeVar75 + vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar79 = fract( ( vec3<f32>( p0_nodeVar78.x, p0_nodeVar78.y, p0_nodeVar78.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar80 = ( p0_nodeVar79 + vec3<f32>( dot( p0_nodeVar79, ( vec3<f32>( p0_nodeVar79.y, p0_nodeVar79.z, p0_nodeVar79.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar81 = fract( p0_nodeVar74 );
		p0_nodeVar82 = ( ( p0_nodeVar81 * p0_nodeVar81 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar81 * vec2<f32>( 2.0 ) ) ) );
		p0_nodeVar83 = ( p0_nodeVar75 + vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar84 = fract( ( vec3<f32>( p0_nodeVar83.x, p0_nodeVar83.y, p0_nodeVar83.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar85 = ( p0_nodeVar84 + vec3<f32>( dot( p0_nodeVar84, ( vec3<f32>( p0_nodeVar84.y, p0_nodeVar84.z, p0_nodeVar84.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar86 = ( p0_nodeVar75 + vec2<f32>( 1.0, 1.0 ) );
		p0_nodeVar87 = fract( ( vec3<f32>( p0_nodeVar86.x, p0_nodeVar86.y, p0_nodeVar86.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar88 = ( p0_nodeVar87 + vec3<f32>( dot( p0_nodeVar87, ( vec3<f32>( p0_nodeVar87.y, p0_nodeVar87.z, p0_nodeVar87.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar89 = floor( ( ( p0_nodeVar73 / vec2<f32>( f32(knobs.grainSize) ) ) * vec2<f32>( 2.1 ) ) );
		p0_nodeVar90 = fract( ( vec3<f32>( p0_nodeVar89.x, p0_nodeVar89.y, p0_nodeVar89.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar91 = ( p0_nodeVar90 + vec3<f32>( dot( p0_nodeVar90, ( vec3<f32>( p0_nodeVar90.y, p0_nodeVar90.z, p0_nodeVar90.x ) + vec3<f32>( 33.33 ) ) ) ) );

		if ( ( f32(knobs.engrave) < 0.5 ) ) {

			p0_nodeVar92 = 0.0;

		} else {


			if ( ( f32(knobs.engrave) < 1.5 ) ) {

				p0_nodeVar94 = ( p0_nodeVar29 - vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar95 = ( f32(knobs.engraveAngle) * 0.017453292519943295 );
				p0_nodeVar96 = vec2<f32>( ( ( ( p0_nodeVar94.y * cos( p0_nodeVar95 ) ) - ( p0_nodeVar94.x * sin( p0_nodeVar95 ) ) ) / ( f32(knobs.lineSpacing) * 9.0 ) ), 3.1 );
				p0_nodeVar97 = floor( p0_nodeVar96 );
				p0_nodeVar98 = fract( ( vec3<f32>( p0_nodeVar97.x, p0_nodeVar97.y, p0_nodeVar97.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar99 = ( p0_nodeVar98 + vec3<f32>( dot( p0_nodeVar98, ( vec3<f32>( p0_nodeVar98.y, p0_nodeVar98.z, p0_nodeVar98.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar100 = ( p0_nodeVar97 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar101 = fract( ( vec3<f32>( p0_nodeVar100.x, p0_nodeVar100.y, p0_nodeVar100.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar102 = ( p0_nodeVar101 + vec3<f32>( dot( p0_nodeVar101, ( vec3<f32>( p0_nodeVar101.y, p0_nodeVar101.z, p0_nodeVar101.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar103 = fract( p0_nodeVar96 );
				p0_nodeVar104 = ( ( p0_nodeVar103 * p0_nodeVar103 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar103 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar105 = ( p0_nodeVar97 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar106 = fract( ( vec3<f32>( p0_nodeVar105.x, p0_nodeVar105.y, p0_nodeVar105.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar107 = ( p0_nodeVar106 + vec3<f32>( dot( p0_nodeVar106, ( vec3<f32>( p0_nodeVar106.y, p0_nodeVar106.z, p0_nodeVar106.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar108 = ( p0_nodeVar97 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar109 = fract( ( vec3<f32>( p0_nodeVar108.x, p0_nodeVar108.y, p0_nodeVar108.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar110 = ( p0_nodeVar109 + vec3<f32>( dot( p0_nodeVar109, ( vec3<f32>( p0_nodeVar109.y, p0_nodeVar109.z, p0_nodeVar109.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar93 = cos( ( ( ( ( ( p0_nodeVar94.x * cos( p0_nodeVar95 ) ) + ( p0_nodeVar94.y * sin( p0_nodeVar95 ) ) ) + ( ( mix( mix( fract( ( ( p0_nodeVar99.x + p0_nodeVar99.y ) * p0_nodeVar99.z ) ), fract( ( ( p0_nodeVar102.x + p0_nodeVar102.y ) * p0_nodeVar102.z ) ), p0_nodeVar104.x ), mix( fract( ( ( p0_nodeVar107.x + p0_nodeVar107.y ) * p0_nodeVar107.z ) ), fract( ( ( p0_nodeVar110.x + p0_nodeVar110.y ) * p0_nodeVar110.z ) ), p0_nodeVar104.x ), p0_nodeVar104.y ) - 0.5 ) * ( f32(knobs.lineSpacing) * 0.8 ) ) ) / f32(knobs.lineSpacing) ) * 6.283185307179586 ) );

			} else {

				p0_nodeVar111 = ( ( p0_nodeVar29 - vec2<f32>( 1.0, 0.0 ) ) - ( p0_nodeVar4 * vec2<f32>( 0.5 ) ) );
				p0_nodeVar112 = atan2( p0_nodeVar111.y, p0_nodeVar111.x );
				p0_nodeVar113 = ( ( min( p0_nodeVar4.x, p0_nodeVar4.y ) * 1.5707963267948966 ) / f32(knobs.lineSpacing) );
				p0_nodeVar114 = length( p0_nodeVar111 );
				p0_nodeVar115 = vec2<f32>( ( ( p0_nodeVar112 * p0_nodeVar113 ) / 6.2831853 ), ( p0_nodeVar114 / ( f32(knobs.lineSpacing) * 14.0 ) ) );
				p0_nodeVar116 = floor( p0_nodeVar115 );
				p0_nodeVar117 = fract( ( vec3<f32>( p0_nodeVar116.x, p0_nodeVar116.y, p0_nodeVar116.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar118 = ( p0_nodeVar117 + vec3<f32>( dot( p0_nodeVar117, ( vec3<f32>( p0_nodeVar117.y, p0_nodeVar117.z, p0_nodeVar117.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar119 = ( p0_nodeVar116 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar120 = fract( ( vec3<f32>( p0_nodeVar119.x, p0_nodeVar119.y, p0_nodeVar119.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar121 = ( p0_nodeVar120 + vec3<f32>( dot( p0_nodeVar120, ( vec3<f32>( p0_nodeVar120.y, p0_nodeVar120.z, p0_nodeVar120.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar122 = fract( p0_nodeVar115 );
				p0_nodeVar123 = ( ( p0_nodeVar122 * p0_nodeVar122 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar122 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar124 = ( p0_nodeVar116 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar125 = fract( ( vec3<f32>( p0_nodeVar124.x, p0_nodeVar124.y, p0_nodeVar124.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar126 = ( p0_nodeVar125 + vec3<f32>( dot( p0_nodeVar125, ( vec3<f32>( p0_nodeVar125.y, p0_nodeVar125.z, p0_nodeVar125.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar127 = ( p0_nodeVar116 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar128 = fract( ( vec3<f32>( p0_nodeVar127.x, p0_nodeVar127.y, p0_nodeVar127.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar129 = ( p0_nodeVar128 + vec3<f32>( dot( p0_nodeVar128, ( vec3<f32>( p0_nodeVar128.y, p0_nodeVar128.z, p0_nodeVar128.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar130 = min( p0_nodeVar4.x, p0_nodeVar4.y );
				p0_nodeVar93 = ( cos( ( ( p0_nodeVar112 * p0_nodeVar113 ) + ( ( mix( mix( fract( ( ( p0_nodeVar118.x + p0_nodeVar118.y ) * p0_nodeVar118.z ) ), fract( ( ( p0_nodeVar121.x + p0_nodeVar121.y ) * p0_nodeVar121.z ) ), p0_nodeVar123.x ), mix( fract( ( ( p0_nodeVar126.x + p0_nodeVar126.y ) * p0_nodeVar126.z ) ), fract( ( ( p0_nodeVar129.x + p0_nodeVar129.y ) * p0_nodeVar129.z ) ), p0_nodeVar123.x ), p0_nodeVar123.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( p0_nodeVar130 * 0.06 ), ( p0_nodeVar130 * 0.22 ), p0_nodeVar114 ) );

			}

			p0_nodeVar92 = p0_nodeVar93;

		}

		p0_nodeVar131 = ( p0_nodeVar29 - vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar132 = ( p0_nodeVar131 / vec2<f32>( f32(knobs.grainSize) ) );
		p0_nodeVar133 = floor( p0_nodeVar132 );
		p0_nodeVar134 = fract( ( vec3<f32>( p0_nodeVar133.x, p0_nodeVar133.y, p0_nodeVar133.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar135 = ( p0_nodeVar134 + vec3<f32>( dot( p0_nodeVar134, ( vec3<f32>( p0_nodeVar134.y, p0_nodeVar134.z, p0_nodeVar134.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar136 = ( p0_nodeVar133 + vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar137 = fract( ( vec3<f32>( p0_nodeVar136.x, p0_nodeVar136.y, p0_nodeVar136.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar138 = ( p0_nodeVar137 + vec3<f32>( dot( p0_nodeVar137, ( vec3<f32>( p0_nodeVar137.y, p0_nodeVar137.z, p0_nodeVar137.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar139 = fract( p0_nodeVar132 );
		p0_nodeVar140 = ( ( p0_nodeVar139 * p0_nodeVar139 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar139 * vec2<f32>( 2.0 ) ) ) );
		p0_nodeVar141 = ( p0_nodeVar133 + vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar142 = fract( ( vec3<f32>( p0_nodeVar141.x, p0_nodeVar141.y, p0_nodeVar141.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar143 = ( p0_nodeVar142 + vec3<f32>( dot( p0_nodeVar142, ( vec3<f32>( p0_nodeVar142.y, p0_nodeVar142.z, p0_nodeVar142.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar144 = ( p0_nodeVar133 + vec2<f32>( 1.0, 1.0 ) );
		p0_nodeVar145 = fract( ( vec3<f32>( p0_nodeVar144.x, p0_nodeVar144.y, p0_nodeVar144.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar146 = ( p0_nodeVar145 + vec3<f32>( dot( p0_nodeVar145, ( vec3<f32>( p0_nodeVar145.y, p0_nodeVar145.z, p0_nodeVar145.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar147 = floor( ( ( p0_nodeVar131 / vec2<f32>( f32(knobs.grainSize) ) ) * vec2<f32>( 2.1 ) ) );
		p0_nodeVar148 = fract( ( vec3<f32>( p0_nodeVar147.x, p0_nodeVar147.y, p0_nodeVar147.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar149 = ( p0_nodeVar148 + vec3<f32>( dot( p0_nodeVar148, ( vec3<f32>( p0_nodeVar148.y, p0_nodeVar148.z, p0_nodeVar148.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar32 = ( ( ( ( ( p0_nodeVar34 * 0.5 ) * f32(knobs.engraveDepth) ) * ( 0.35 + ( ( 1.0 - p0_nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( p0_nodeVar77.x + p0_nodeVar77.y ) * p0_nodeVar77.z ) ), fract( ( ( p0_nodeVar80.x + p0_nodeVar80.y ) * p0_nodeVar80.z ) ), p0_nodeVar82.x ), mix( fract( ( ( p0_nodeVar85.x + p0_nodeVar85.y ) * p0_nodeVar85.z ) ), fract( ( ( p0_nodeVar88.x + p0_nodeVar88.y ) * p0_nodeVar88.z ) ), p0_nodeVar82.x ), p0_nodeVar82.y ) * 0.6 ) + ( fract( ( ( p0_nodeVar91.x + p0_nodeVar91.y ) * p0_nodeVar91.z ) ) * 0.4 ) ) - 0.5 ) * f32(knobs.grain) ) ) - ( ( ( ( p0_nodeVar92 * 0.5 ) * f32(knobs.engraveDepth) ) * ( 0.35 + ( ( 1.0 - p0_nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( p0_nodeVar135.x + p0_nodeVar135.y ) * p0_nodeVar135.z ) ), fract( ( ( p0_nodeVar138.x + p0_nodeVar138.y ) * p0_nodeVar138.z ) ), p0_nodeVar140.x ), mix( fract( ( ( p0_nodeVar143.x + p0_nodeVar143.y ) * p0_nodeVar143.z ) ), fract( ( ( p0_nodeVar146.x + p0_nodeVar146.y ) * p0_nodeVar146.z ) ), p0_nodeVar140.x ), p0_nodeVar140.y ) * 0.6 ) + ( fract( ( ( p0_nodeVar149.x + p0_nodeVar149.y ) * p0_nodeVar149.z ) ) * 0.4 ) ) - 0.5 ) * f32(knobs.grain) ) ) );

		if ( ( f32(knobs.engrave) < 0.5 ) ) {

			p0_nodeVar150 = 0.0;

		} else {


			if ( ( f32(knobs.engrave) < 1.5 ) ) {

				p0_nodeVar152 = ( p0_nodeVar29 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar153 = ( f32(knobs.engraveAngle) * 0.017453292519943295 );
				p0_nodeVar154 = vec2<f32>( ( ( ( p0_nodeVar152.y * cos( p0_nodeVar153 ) ) - ( p0_nodeVar152.x * sin( p0_nodeVar153 ) ) ) / ( f32(knobs.lineSpacing) * 9.0 ) ), 3.1 );
				p0_nodeVar155 = floor( p0_nodeVar154 );
				p0_nodeVar156 = fract( ( vec3<f32>( p0_nodeVar155.x, p0_nodeVar155.y, p0_nodeVar155.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar157 = ( p0_nodeVar156 + vec3<f32>( dot( p0_nodeVar156, ( vec3<f32>( p0_nodeVar156.y, p0_nodeVar156.z, p0_nodeVar156.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar158 = ( p0_nodeVar155 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar159 = fract( ( vec3<f32>( p0_nodeVar158.x, p0_nodeVar158.y, p0_nodeVar158.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar160 = ( p0_nodeVar159 + vec3<f32>( dot( p0_nodeVar159, ( vec3<f32>( p0_nodeVar159.y, p0_nodeVar159.z, p0_nodeVar159.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar161 = fract( p0_nodeVar154 );
				p0_nodeVar162 = ( ( p0_nodeVar161 * p0_nodeVar161 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar161 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar163 = ( p0_nodeVar155 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar164 = fract( ( vec3<f32>( p0_nodeVar163.x, p0_nodeVar163.y, p0_nodeVar163.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar165 = ( p0_nodeVar164 + vec3<f32>( dot( p0_nodeVar164, ( vec3<f32>( p0_nodeVar164.y, p0_nodeVar164.z, p0_nodeVar164.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar166 = ( p0_nodeVar155 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar167 = fract( ( vec3<f32>( p0_nodeVar166.x, p0_nodeVar166.y, p0_nodeVar166.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar168 = ( p0_nodeVar167 + vec3<f32>( dot( p0_nodeVar167, ( vec3<f32>( p0_nodeVar167.y, p0_nodeVar167.z, p0_nodeVar167.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar151 = cos( ( ( ( ( ( p0_nodeVar152.x * cos( p0_nodeVar153 ) ) + ( p0_nodeVar152.y * sin( p0_nodeVar153 ) ) ) + ( ( mix( mix( fract( ( ( p0_nodeVar157.x + p0_nodeVar157.y ) * p0_nodeVar157.z ) ), fract( ( ( p0_nodeVar160.x + p0_nodeVar160.y ) * p0_nodeVar160.z ) ), p0_nodeVar162.x ), mix( fract( ( ( p0_nodeVar165.x + p0_nodeVar165.y ) * p0_nodeVar165.z ) ), fract( ( ( p0_nodeVar168.x + p0_nodeVar168.y ) * p0_nodeVar168.z ) ), p0_nodeVar162.x ), p0_nodeVar162.y ) - 0.5 ) * ( f32(knobs.lineSpacing) * 0.8 ) ) ) / f32(knobs.lineSpacing) ) * 6.283185307179586 ) );

			} else {

				p0_nodeVar169 = ( ( p0_nodeVar29 + vec2<f32>( 0.0, 1.0 ) ) - ( p0_nodeVar4 * vec2<f32>( 0.5 ) ) );
				p0_nodeVar170 = atan2( p0_nodeVar169.y, p0_nodeVar169.x );
				p0_nodeVar171 = ( ( min( p0_nodeVar4.x, p0_nodeVar4.y ) * 1.5707963267948966 ) / f32(knobs.lineSpacing) );
				p0_nodeVar172 = length( p0_nodeVar169 );
				p0_nodeVar173 = vec2<f32>( ( ( p0_nodeVar170 * p0_nodeVar171 ) / 6.2831853 ), ( p0_nodeVar172 / ( f32(knobs.lineSpacing) * 14.0 ) ) );
				p0_nodeVar174 = floor( p0_nodeVar173 );
				p0_nodeVar175 = fract( ( vec3<f32>( p0_nodeVar174.x, p0_nodeVar174.y, p0_nodeVar174.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar176 = ( p0_nodeVar175 + vec3<f32>( dot( p0_nodeVar175, ( vec3<f32>( p0_nodeVar175.y, p0_nodeVar175.z, p0_nodeVar175.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar177 = ( p0_nodeVar174 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar178 = fract( ( vec3<f32>( p0_nodeVar177.x, p0_nodeVar177.y, p0_nodeVar177.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar179 = ( p0_nodeVar178 + vec3<f32>( dot( p0_nodeVar178, ( vec3<f32>( p0_nodeVar178.y, p0_nodeVar178.z, p0_nodeVar178.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar180 = fract( p0_nodeVar173 );
				p0_nodeVar181 = ( ( p0_nodeVar180 * p0_nodeVar180 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar180 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar182 = ( p0_nodeVar174 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar183 = fract( ( vec3<f32>( p0_nodeVar182.x, p0_nodeVar182.y, p0_nodeVar182.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar184 = ( p0_nodeVar183 + vec3<f32>( dot( p0_nodeVar183, ( vec3<f32>( p0_nodeVar183.y, p0_nodeVar183.z, p0_nodeVar183.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar185 = ( p0_nodeVar174 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar186 = fract( ( vec3<f32>( p0_nodeVar185.x, p0_nodeVar185.y, p0_nodeVar185.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar187 = ( p0_nodeVar186 + vec3<f32>( dot( p0_nodeVar186, ( vec3<f32>( p0_nodeVar186.y, p0_nodeVar186.z, p0_nodeVar186.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar188 = min( p0_nodeVar4.x, p0_nodeVar4.y );
				p0_nodeVar151 = ( cos( ( ( p0_nodeVar170 * p0_nodeVar171 ) + ( ( mix( mix( fract( ( ( p0_nodeVar176.x + p0_nodeVar176.y ) * p0_nodeVar176.z ) ), fract( ( ( p0_nodeVar179.x + p0_nodeVar179.y ) * p0_nodeVar179.z ) ), p0_nodeVar181.x ), mix( fract( ( ( p0_nodeVar184.x + p0_nodeVar184.y ) * p0_nodeVar184.z ) ), fract( ( ( p0_nodeVar187.x + p0_nodeVar187.y ) * p0_nodeVar187.z ) ), p0_nodeVar181.x ), p0_nodeVar181.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( p0_nodeVar188 * 0.06 ), ( p0_nodeVar188 * 0.22 ), p0_nodeVar172 ) );

			}

			p0_nodeVar150 = p0_nodeVar151;

		}

		p0_nodeVar189 = ( p0_nodeVar29 + vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar190 = ( p0_nodeVar189 / vec2<f32>( f32(knobs.grainSize) ) );
		p0_nodeVar191 = floor( p0_nodeVar190 );
		p0_nodeVar192 = fract( ( vec3<f32>( p0_nodeVar191.x, p0_nodeVar191.y, p0_nodeVar191.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar193 = ( p0_nodeVar192 + vec3<f32>( dot( p0_nodeVar192, ( vec3<f32>( p0_nodeVar192.y, p0_nodeVar192.z, p0_nodeVar192.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar194 = ( p0_nodeVar191 + vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar195 = fract( ( vec3<f32>( p0_nodeVar194.x, p0_nodeVar194.y, p0_nodeVar194.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar196 = ( p0_nodeVar195 + vec3<f32>( dot( p0_nodeVar195, ( vec3<f32>( p0_nodeVar195.y, p0_nodeVar195.z, p0_nodeVar195.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar197 = fract( p0_nodeVar190 );
		p0_nodeVar198 = ( ( p0_nodeVar197 * p0_nodeVar197 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar197 * vec2<f32>( 2.0 ) ) ) );
		p0_nodeVar199 = ( p0_nodeVar191 + vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar200 = fract( ( vec3<f32>( p0_nodeVar199.x, p0_nodeVar199.y, p0_nodeVar199.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar201 = ( p0_nodeVar200 + vec3<f32>( dot( p0_nodeVar200, ( vec3<f32>( p0_nodeVar200.y, p0_nodeVar200.z, p0_nodeVar200.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar202 = ( p0_nodeVar191 + vec2<f32>( 1.0, 1.0 ) );
		p0_nodeVar203 = fract( ( vec3<f32>( p0_nodeVar202.x, p0_nodeVar202.y, p0_nodeVar202.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar204 = ( p0_nodeVar203 + vec3<f32>( dot( p0_nodeVar203, ( vec3<f32>( p0_nodeVar203.y, p0_nodeVar203.z, p0_nodeVar203.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar205 = floor( ( ( p0_nodeVar189 / vec2<f32>( f32(knobs.grainSize) ) ) * vec2<f32>( 2.1 ) ) );
		p0_nodeVar206 = fract( ( vec3<f32>( p0_nodeVar205.x, p0_nodeVar205.y, p0_nodeVar205.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar207 = ( p0_nodeVar206 + vec3<f32>( dot( p0_nodeVar206, ( vec3<f32>( p0_nodeVar206.y, p0_nodeVar206.z, p0_nodeVar206.x ) + vec3<f32>( 33.33 ) ) ) ) );

		if ( ( f32(knobs.engrave) < 0.5 ) ) {

			p0_nodeVar208 = 0.0;

		} else {


			if ( ( f32(knobs.engrave) < 1.5 ) ) {

				p0_nodeVar210 = ( p0_nodeVar29 - vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar211 = ( f32(knobs.engraveAngle) * 0.017453292519943295 );
				p0_nodeVar212 = vec2<f32>( ( ( ( p0_nodeVar210.y * cos( p0_nodeVar211 ) ) - ( p0_nodeVar210.x * sin( p0_nodeVar211 ) ) ) / ( f32(knobs.lineSpacing) * 9.0 ) ), 3.1 );
				p0_nodeVar213 = floor( p0_nodeVar212 );
				p0_nodeVar214 = fract( ( vec3<f32>( p0_nodeVar213.x, p0_nodeVar213.y, p0_nodeVar213.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar215 = ( p0_nodeVar214 + vec3<f32>( dot( p0_nodeVar214, ( vec3<f32>( p0_nodeVar214.y, p0_nodeVar214.z, p0_nodeVar214.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar216 = ( p0_nodeVar213 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar217 = fract( ( vec3<f32>( p0_nodeVar216.x, p0_nodeVar216.y, p0_nodeVar216.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar218 = ( p0_nodeVar217 + vec3<f32>( dot( p0_nodeVar217, ( vec3<f32>( p0_nodeVar217.y, p0_nodeVar217.z, p0_nodeVar217.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar219 = fract( p0_nodeVar212 );
				p0_nodeVar220 = ( ( p0_nodeVar219 * p0_nodeVar219 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar219 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar221 = ( p0_nodeVar213 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar222 = fract( ( vec3<f32>( p0_nodeVar221.x, p0_nodeVar221.y, p0_nodeVar221.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar223 = ( p0_nodeVar222 + vec3<f32>( dot( p0_nodeVar222, ( vec3<f32>( p0_nodeVar222.y, p0_nodeVar222.z, p0_nodeVar222.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar224 = ( p0_nodeVar213 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar225 = fract( ( vec3<f32>( p0_nodeVar224.x, p0_nodeVar224.y, p0_nodeVar224.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar226 = ( p0_nodeVar225 + vec3<f32>( dot( p0_nodeVar225, ( vec3<f32>( p0_nodeVar225.y, p0_nodeVar225.z, p0_nodeVar225.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar209 = cos( ( ( ( ( ( p0_nodeVar210.x * cos( p0_nodeVar211 ) ) + ( p0_nodeVar210.y * sin( p0_nodeVar211 ) ) ) + ( ( mix( mix( fract( ( ( p0_nodeVar215.x + p0_nodeVar215.y ) * p0_nodeVar215.z ) ), fract( ( ( p0_nodeVar218.x + p0_nodeVar218.y ) * p0_nodeVar218.z ) ), p0_nodeVar220.x ), mix( fract( ( ( p0_nodeVar223.x + p0_nodeVar223.y ) * p0_nodeVar223.z ) ), fract( ( ( p0_nodeVar226.x + p0_nodeVar226.y ) * p0_nodeVar226.z ) ), p0_nodeVar220.x ), p0_nodeVar220.y ) - 0.5 ) * ( f32(knobs.lineSpacing) * 0.8 ) ) ) / f32(knobs.lineSpacing) ) * 6.283185307179586 ) );

			} else {

				p0_nodeVar227 = ( ( p0_nodeVar29 - vec2<f32>( 0.0, 1.0 ) ) - ( p0_nodeVar4 * vec2<f32>( 0.5 ) ) );
				p0_nodeVar228 = atan2( p0_nodeVar227.y, p0_nodeVar227.x );
				p0_nodeVar229 = ( ( min( p0_nodeVar4.x, p0_nodeVar4.y ) * 1.5707963267948966 ) / f32(knobs.lineSpacing) );
				p0_nodeVar230 = length( p0_nodeVar227 );
				p0_nodeVar231 = vec2<f32>( ( ( p0_nodeVar228 * p0_nodeVar229 ) / 6.2831853 ), ( p0_nodeVar230 / ( f32(knobs.lineSpacing) * 14.0 ) ) );
				p0_nodeVar232 = floor( p0_nodeVar231 );
				p0_nodeVar233 = fract( ( vec3<f32>( p0_nodeVar232.x, p0_nodeVar232.y, p0_nodeVar232.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar234 = ( p0_nodeVar233 + vec3<f32>( dot( p0_nodeVar233, ( vec3<f32>( p0_nodeVar233.y, p0_nodeVar233.z, p0_nodeVar233.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar235 = ( p0_nodeVar232 + vec2<f32>( 1.0, 0.0 ) );
				p0_nodeVar236 = fract( ( vec3<f32>( p0_nodeVar235.x, p0_nodeVar235.y, p0_nodeVar235.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar237 = ( p0_nodeVar236 + vec3<f32>( dot( p0_nodeVar236, ( vec3<f32>( p0_nodeVar236.y, p0_nodeVar236.z, p0_nodeVar236.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar238 = fract( p0_nodeVar231 );
				p0_nodeVar239 = ( ( p0_nodeVar238 * p0_nodeVar238 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar238 * vec2<f32>( 2.0 ) ) ) );
				p0_nodeVar240 = ( p0_nodeVar232 + vec2<f32>( 0.0, 1.0 ) );
				p0_nodeVar241 = fract( ( vec3<f32>( p0_nodeVar240.x, p0_nodeVar240.y, p0_nodeVar240.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar242 = ( p0_nodeVar241 + vec3<f32>( dot( p0_nodeVar241, ( vec3<f32>( p0_nodeVar241.y, p0_nodeVar241.z, p0_nodeVar241.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar243 = ( p0_nodeVar232 + vec2<f32>( 1.0, 1.0 ) );
				p0_nodeVar244 = fract( ( vec3<f32>( p0_nodeVar243.x, p0_nodeVar243.y, p0_nodeVar243.x ) * vec3<f32>( 0.1031 ) ) );
				p0_nodeVar245 = ( p0_nodeVar244 + vec3<f32>( dot( p0_nodeVar244, ( vec3<f32>( p0_nodeVar244.y, p0_nodeVar244.z, p0_nodeVar244.x ) + vec3<f32>( 33.33 ) ) ) ) );
				p0_nodeVar246 = min( p0_nodeVar4.x, p0_nodeVar4.y );
				p0_nodeVar209 = ( cos( ( ( p0_nodeVar228 * p0_nodeVar229 ) + ( ( mix( mix( fract( ( ( p0_nodeVar234.x + p0_nodeVar234.y ) * p0_nodeVar234.z ) ), fract( ( ( p0_nodeVar237.x + p0_nodeVar237.y ) * p0_nodeVar237.z ) ), p0_nodeVar239.x ), mix( fract( ( ( p0_nodeVar242.x + p0_nodeVar242.y ) * p0_nodeVar242.z ) ), fract( ( ( p0_nodeVar245.x + p0_nodeVar245.y ) * p0_nodeVar245.z ) ), p0_nodeVar239.x ), p0_nodeVar239.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( p0_nodeVar246 * 0.06 ), ( p0_nodeVar246 * 0.22 ), p0_nodeVar230 ) );

			}

			p0_nodeVar208 = p0_nodeVar209;

		}

		p0_nodeVar247 = ( p0_nodeVar29 - vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar248 = ( p0_nodeVar247 / vec2<f32>( f32(knobs.grainSize) ) );
		p0_nodeVar249 = floor( p0_nodeVar248 );
		p0_nodeVar250 = fract( ( vec3<f32>( p0_nodeVar249.x, p0_nodeVar249.y, p0_nodeVar249.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar251 = ( p0_nodeVar250 + vec3<f32>( dot( p0_nodeVar250, ( vec3<f32>( p0_nodeVar250.y, p0_nodeVar250.z, p0_nodeVar250.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar252 = ( p0_nodeVar249 + vec2<f32>( 1.0, 0.0 ) );
		p0_nodeVar253 = fract( ( vec3<f32>( p0_nodeVar252.x, p0_nodeVar252.y, p0_nodeVar252.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar254 = ( p0_nodeVar253 + vec3<f32>( dot( p0_nodeVar253, ( vec3<f32>( p0_nodeVar253.y, p0_nodeVar253.z, p0_nodeVar253.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar255 = fract( p0_nodeVar248 );
		p0_nodeVar256 = ( ( p0_nodeVar255 * p0_nodeVar255 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar255 * vec2<f32>( 2.0 ) ) ) );
		p0_nodeVar257 = ( p0_nodeVar249 + vec2<f32>( 0.0, 1.0 ) );
		p0_nodeVar258 = fract( ( vec3<f32>( p0_nodeVar257.x, p0_nodeVar257.y, p0_nodeVar257.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar259 = ( p0_nodeVar258 + vec3<f32>( dot( p0_nodeVar258, ( vec3<f32>( p0_nodeVar258.y, p0_nodeVar258.z, p0_nodeVar258.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar260 = ( p0_nodeVar249 + vec2<f32>( 1.0, 1.0 ) );
		p0_nodeVar261 = fract( ( vec3<f32>( p0_nodeVar260.x, p0_nodeVar260.y, p0_nodeVar260.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar262 = ( p0_nodeVar261 + vec3<f32>( dot( p0_nodeVar261, ( vec3<f32>( p0_nodeVar261.y, p0_nodeVar261.z, p0_nodeVar261.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar263 = floor( ( ( p0_nodeVar247 / vec2<f32>( f32(knobs.grainSize) ) ) * vec2<f32>( 2.1 ) ) );
		p0_nodeVar264 = fract( ( vec3<f32>( p0_nodeVar263.x, p0_nodeVar263.y, p0_nodeVar263.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar265 = ( p0_nodeVar264 + vec3<f32>( dot( p0_nodeVar264, ( vec3<f32>( p0_nodeVar264.y, p0_nodeVar264.z, p0_nodeVar264.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar33 = ( ( ( ( ( p0_nodeVar150 * 0.5 ) * f32(knobs.engraveDepth) ) * ( 0.35 + ( ( 1.0 - p0_nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( p0_nodeVar193.x + p0_nodeVar193.y ) * p0_nodeVar193.z ) ), fract( ( ( p0_nodeVar196.x + p0_nodeVar196.y ) * p0_nodeVar196.z ) ), p0_nodeVar198.x ), mix( fract( ( ( p0_nodeVar201.x + p0_nodeVar201.y ) * p0_nodeVar201.z ) ), fract( ( ( p0_nodeVar204.x + p0_nodeVar204.y ) * p0_nodeVar204.z ) ), p0_nodeVar198.x ), p0_nodeVar198.y ) * 0.6 ) + ( fract( ( ( p0_nodeVar207.x + p0_nodeVar207.y ) * p0_nodeVar207.z ) ) * 0.4 ) ) - 0.5 ) * f32(knobs.grain) ) ) - ( ( ( ( p0_nodeVar208 * 0.5 ) * f32(knobs.engraveDepth) ) * ( 0.35 + ( ( 1.0 - p0_nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( p0_nodeVar251.x + p0_nodeVar251.y ) * p0_nodeVar251.z ) ), fract( ( ( p0_nodeVar254.x + p0_nodeVar254.y ) * p0_nodeVar254.z ) ), p0_nodeVar256.x ), mix( fract( ( ( p0_nodeVar259.x + p0_nodeVar259.y ) * p0_nodeVar259.z ) ), fract( ( ( p0_nodeVar262.x + p0_nodeVar262.y ) * p0_nodeVar262.z ) ), p0_nodeVar256.x ), p0_nodeVar256.y ) * 0.6 ) + ( fract( ( ( p0_nodeVar265.x + p0_nodeVar265.y ) * p0_nodeVar265.z ) ) * 0.4 ) ) - 0.5 ) * f32(knobs.grain) ) ) );
		

	}


	if ( ( f32(knobs.surface) > 0.5 ) ) {

		p0_nodeVar266 = p0_nodeVar31;

	} else {

		p0_nodeVar266 = vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z);

	}


	if ( ( f32(knobs.relief) > 0.5 ) ) {

		p0_nodeVar267 = -1.0;

	} else {

		p0_nodeVar267 = 1.0;

	}

	p0_nodeVar268 = normalize( vec3<f32>( ( ( ( ( ( p0_nodeVar15 - p0_nodeVar16 ) * f32(knobs.depth) ) * p0_nodeVar267 ) + p0_nodeVar32 ) * -2.0 ), ( ( ( ( ( p0_nodeVar17 - p0_nodeVar18 ) * f32(knobs.depth) ) * p0_nodeVar267 ) + p0_nodeVar33 ) * 2.0 ), 1.0 ) );
	p0_nodeVar269 = ( f32(knobs.lightAngle) * 0.017453292519943295 );
	p0_nodeVar270 = ( f32(knobs.elevation) * 0.017453292519943295 );
	p0_nodeVar271 = normalize( vec3<f32>( ( cos( p0_nodeVar269 ) * cos( p0_nodeVar270 ) ), ( sin( p0_nodeVar269 ) * cos( p0_nodeVar270 ) ), sin( p0_nodeVar270 ) ) );
	p0_nodeVar272 = normalize( ( p0_nodeVar271 + vec3<f32>( 0.0, 0.0, 1.0 ) ) );
	p0_nodeVar273 = vec4<f32>( mix( p0_nodeVar31, clamp( ( ( p0_nodeVar266 * vec3<f32>( ( f32(knobs.ambient) + ( ( 1.0 - f32(knobs.ambient) ) * ( max( dot( p0_nodeVar268, p0_nodeVar271 ), 0.0 ) / sin( p0_nodeVar270 ) ) ) ) ) ) + vec3<f32>( ( max( ( pow( max( dot( p0_nodeVar268, p0_nodeVar272 ), 0.0 ), f32(knobs.shininess) ) - pow( max( p0_nodeVar272.z, 0.0 ), f32(knobs.shininess) ) ), 0.0 ) * f32(knobs.specular) ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), f32(knobs.amount) ), p0_nodeVar30.w );
	p0_nodeVar274 = vec3<f32>( p0_nodeVar273.x, p0_nodeVar273.y, p0_nodeVar273.z );
	p0_nodeVar275 = ( ( ( p0_nodeVar274.x * 0.2126 ) + ( p0_nodeVar274.y * 0.7152 ) ) + ( p0_nodeVar274.z * 0.0722 ) );
	p0_nodeVar276 = mix( vec3<f32>( p0_nodeVar275, p0_nodeVar275, p0_nodeVar275 ), p0_nodeVar274, f32(1.0) );
	p0_nodeVar277 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar276.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar276.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar276.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar276.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar276.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar276.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar276.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar276.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar276.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar273.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar277.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar277.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar278 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar278;

	// result

	p0_output.color = p0_nodeVar278;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

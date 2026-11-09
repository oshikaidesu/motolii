// Signal Rot: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Distort
// --about:A failing scan: dragged streaks, wobble, torn bands, color drift and line noise.
// --check@direction:Streaks,0
// --track@drag:Drag,0,1,0.55,0.01
// --track@dragLength:Drag Length,0.01,1,0.35,0.01
// --track@stretch:Stretch,0,1,0.35,0.01
// --track@wobble:Wobble,0,1,0.45,0.01
// --track@wobbleScale:Wobble Scale,0.02,2,0.35,0.01
// --track@tear:Tear,0,1,0.25,0.01
// --track@bandSize:Band Size,0.01,0.5,0.14,0.01
// --track@dropout:Dropout,0,1,0.3,0.01
// --track@dropoutColor_x:Dropout Color r,0,1,1,0.001
// --track@dropoutColor_y:Dropout Color g,0,1,1,0.001
// --track@dropoutColor_z:Dropout Color b,0,1,1,0.001
// --track@chroma:Chroma Shift,0,1,0,0.01
// --track@crush:Crush,0,1,0,0.01
// --track@lineNoise:Line Noise,0,1,0,0.01
// --track@seed:Seed,0,999,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  direction: f32,
  drag: f32,
  dragLength: f32,
  stretch: f32,
  wobble: f32,
  wobbleScale: f32,
  tear: f32,
  bandSize: f32,
  dropout: f32,
  dropoutColor: vec3<f32>,
  chroma: f32,
  crush: f32,
  lineNoise: f32,
  seed: f32,
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
var<private> p0_nodeVar4 : bool;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec2<f32>;
var<private> p0_nodeVar21 : vec3<f32>;
var<private> p0_nodeVar22 : vec3<f32>;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : vec3<f32>;
var<private> p0_nodeVar25 : vec3<f32>;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : vec3<f32>;
var<private> p0_nodeVar31 : vec3<f32>;
var<private> p0_nodeVar32 : vec2<f32>;
var<private> p0_nodeVar33 : vec3<f32>;
var<private> p0_nodeVar34 : vec3<f32>;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec2<f32>;
var<private> p0_nodeVar39 : vec3<f32>;
var<private> p0_nodeVar40 : vec3<f32>;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : vec3<f32>;
var<private> p0_nodeVar43 : vec3<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : vec2<f32>;
var<private> p0_nodeVar48 : vec3<f32>;
var<private> p0_nodeVar49 : vec3<f32>;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : vec3<f32>;
var<private> p0_nodeVar52 : vec3<f32>;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : vec2<f32>;
var<private> p0_nodeVar55 : vec3<f32>;
var<private> p0_nodeVar56 : vec3<f32>;
var<private> p0_nodeVar57 : vec2<f32>;
var<private> p0_nodeVar58 : vec3<f32>;
var<private> p0_nodeVar59 : vec3<f32>;
var<private> p0_nodeVar60 : vec2<f32>;
var<private> p0_nodeVar61 : vec3<f32>;
var<private> p0_nodeVar62 : vec3<f32>;
var<private> p0_nodeVar63 : vec2<f32>;
var<private> p0_nodeVar64 : vec3<f32>;
var<private> p0_nodeVar65 : vec3<f32>;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : vec2<f32>;
var<private> p0_nodeVar69 : vec3<f32>;
var<private> p0_nodeVar70 : vec3<f32>;
var<private> p0_nodeVar71 : vec2<f32>;
var<private> p0_nodeVar72 : vec3<f32>;
var<private> p0_nodeVar73 : vec3<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : vec2<f32>;
var<private> p0_nodeVar78 : vec3<f32>;
var<private> p0_nodeVar79 : vec3<f32>;
var<private> p0_nodeVar80 : vec2<f32>;
var<private> p0_nodeVar81 : vec3<f32>;
var<private> p0_nodeVar82 : vec3<f32>;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : f32;
var<private> p0_nodeVar86 : vec2<f32>;
var<private> p0_nodeVar87 : vec3<f32>;
var<private> p0_nodeVar88 : vec3<f32>;
var<private> p0_nodeVar89 : vec2<f32>;
var<private> p0_nodeVar90 : vec3<f32>;
var<private> p0_nodeVar91 : vec3<f32>;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : vec3<f32>;
var<private> p0_nodeVar95 : vec3<f32>;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : vec2<f32>;
var<private> p0_nodeVar99 : vec3<f32>;
var<private> p0_nodeVar100 : vec3<f32>;
var<private> p0_nodeVar101 : vec2<f32>;
var<private> p0_nodeVar102 : vec3<f32>;
var<private> p0_nodeVar103 : vec3<f32>;
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : vec2<f32>;
var<private> p0_nodeVar108 : vec3<f32>;
var<private> p0_nodeVar109 : vec3<f32>;
var<private> p0_nodeVar110 : vec2<f32>;
var<private> p0_nodeVar111 : vec3<f32>;
var<private> p0_nodeVar112 : vec3<f32>;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : vec2<f32>;
var<private> p0_nodeVar117 : vec3<f32>;
var<private> p0_nodeVar118 : vec3<f32>;
var<private> p0_nodeVar119 : vec2<f32>;
var<private> p0_nodeVar120 : vec3<f32>;
var<private> p0_nodeVar121 : vec3<f32>;
var<private> p0_nodeVar122 : f32;
var<private> p0_nodeVar123 : f32;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : f32;
var<private> p0_nodeVar126 : vec2<f32>;
var<private> p0_nodeVar127 : vec3<f32>;
var<private> p0_nodeVar128 : vec3<f32>;
var<private> p0_nodeVar129 : vec2<f32>;
var<private> p0_nodeVar130 : vec3<f32>;
var<private> p0_nodeVar131 : vec3<f32>;
var<private> p0_nodeVar132 : f32;
var<private> p0_nodeVar133 : f32;
var<private> p0_nodeVar134 : f32;
var<private> p0_nodeVar135 : vec2<f32>;
var<private> p0_nodeVar136 : vec3<f32>;
var<private> p0_nodeVar137 : vec3<f32>;
var<private> p0_nodeVar138 : vec2<f32>;
var<private> p0_nodeVar139 : vec3<f32>;
var<private> p0_nodeVar140 : vec3<f32>;
var<private> p0_nodeVar141 : f32;
var<private> p0_nodeVar142 : f32;
var<private> p0_nodeVar143 : f32;
var<private> p0_nodeVar144 : vec2<f32>;
var<private> p0_nodeVar145 : vec3<f32>;
var<private> p0_nodeVar146 : vec3<f32>;
var<private> p0_nodeVar147 : vec2<f32>;
var<private> p0_nodeVar148 : vec3<f32>;
var<private> p0_nodeVar149 : vec3<f32>;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : vec2<f32>;
var<private> p0_nodeVar155 : vec3<f32>;
var<private> p0_nodeVar156 : vec3<f32>;
var<private> p0_nodeVar157 : vec2<f32>;
var<private> p0_nodeVar158 : vec3<f32>;
var<private> p0_nodeVar159 : vec3<f32>;
var<private> p0_nodeVar160 : f32;
var<private> p0_nodeVar161 : f32;
var<private> p0_nodeVar162 : f32;
var<private> p0_nodeVar163 : vec2<f32>;
var<private> p0_nodeVar164 : vec3<f32>;
var<private> p0_nodeVar165 : vec3<f32>;
var<private> p0_nodeVar166 : vec2<f32>;
var<private> p0_nodeVar167 : vec3<f32>;
var<private> p0_nodeVar168 : vec3<f32>;
var<private> p0_nodeVar169 : f32;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : vec2<f32>;
var<private> p0_nodeVar173 : vec3<f32>;
var<private> p0_nodeVar174 : vec3<f32>;
var<private> p0_nodeVar175 : vec2<f32>;
var<private> p0_nodeVar176 : vec3<f32>;
var<private> p0_nodeVar177 : vec3<f32>;
var<private> p0_nodeVar178 : f32;
var<private> p0_nodeVar179 : f32;
var<private> p0_nodeVar180 : f32;
var<private> p0_nodeVar181 : vec2<f32>;
var<private> p0_nodeVar182 : vec3<f32>;
var<private> p0_nodeVar183 : vec3<f32>;
var<private> p0_nodeVar184 : vec2<f32>;
var<private> p0_nodeVar185 : vec3<f32>;
var<private> p0_nodeVar186 : vec3<f32>;
var<private> p0_nodeVar187 : f32;
var<private> p0_nodeVar188 : f32;
var<private> p0_nodeVar189 : f32;
var<private> p0_nodeVar190 : vec2<f32>;
var<private> p0_nodeVar191 : vec3<f32>;
var<private> p0_nodeVar192 : vec3<f32>;
var<private> p0_nodeVar193 : f32;
var<private> p0_nodeVar194 : vec2<f32>;
var<private> p0_nodeVar195 : vec3<f32>;
var<private> p0_nodeVar196 : vec3<f32>;
var<private> p0_nodeVar197 : vec2<f32>;
var<private> p0_nodeVar198 : vec3<f32>;
var<private> p0_nodeVar199 : vec3<f32>;
var<private> p0_nodeVar200 : vec2<f32>;
var<private> p0_nodeVar201 : vec4<f32>;
var<private> p0_nodeVar202 : vec4<f32>;
var<private> p0_nodeVar203 : vec3<f32>;
var<private> p0_nodeVar204 : f32;
var<private> p0_nodeVar205 : vec2<f32>;
var<private> p0_nodeVar206 : vec4<f32>;
var<private> p0_nodeVar207 : vec2<f32>;
var<private> p0_nodeVar208 : vec4<f32>;
var<private> p0_nodeVar209 : f32;
var<private> p0_nodeVar210 : vec2<f32>;
var<private> p0_nodeVar211 : vec3<f32>;
var<private> p0_nodeVar212 : vec3<f32>;
var<private> p0_nodeVar213 : vec4<f32>;
var<private> p0_nodeVar214 : vec3<f32>;
var<private> p0_nodeVar215 : f32;
var<private> p0_nodeVar216 : vec3<f32>;
var<private> p0_nodeVar217 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar218 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar2 = ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * p0_nodeVar1 );
	p0_nodeVar4 = ( f32((-1 * knobs.direction + 1)) > 0.5 );

	if ( p0_nodeVar4 ) {

		p0_nodeVar3 = p0_nodeVar2.y;

	} else {

		p0_nodeVar3 = p0_nodeVar2.x;

	}

	p0_nodeVar5 = p0_nodeVar3;

	if ( p0_nodeVar4 ) {

		p0_nodeVar6 = p0_nodeVar2.x;

	} else {

		p0_nodeVar6 = p0_nodeVar2.y;

	}

	p0_nodeVar7 = p0_nodeVar6;

	if ( p0_nodeVar4 ) {

		p0_nodeVar8 = p0_nodeVar1.y;

	} else {

		p0_nodeVar8 = p0_nodeVar1.x;

	}

	p0_nodeVar9 = p0_nodeVar8;

	if ( p0_nodeVar4 ) {

		p0_nodeVar10 = p0_nodeVar1.x;

	} else {

		p0_nodeVar10 = p0_nodeVar1.y;

	}

	p0_nodeVar11 = p0_nodeVar10;
	p0_nodeVar12 = min( p0_nodeVar1.x, p0_nodeVar1.y );
	p0_nodeVar13 = ( f32(knobs.seed) * 7.31 );
	p0_nodeVar14 = floor( ( f32(0.0) * 8.0 ) );
	p0_nodeVar15 = p0_nodeVar7;
	p0_nodeVar16 = 0.0;

	if ( ( ( f32(knobs.tear) > 0.0 ) || ( f32(knobs.dropout) >= 0.0001 ) ) ) {

		p0_nodeVar17 = ( f32(knobs.bandSize) * p0_nodeVar9 );
		p0_nodeVar18 = ( ( p0_nodeVar7 / ( p0_nodeVar12 * 0.08 ) ) + p0_nodeVar13 );
		p0_nodeVar19 = floor( p0_nodeVar18 );
		p0_nodeVar20 = vec2<f32>( p0_nodeVar19, 11.0 );
		p0_nodeVar21 = fract( ( vec3<f32>( p0_nodeVar20.x, p0_nodeVar20.y, p0_nodeVar20.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar22 = ( p0_nodeVar21 + vec3<f32>( dot( p0_nodeVar21, ( vec3<f32>( p0_nodeVar21.y, p0_nodeVar21.z, p0_nodeVar21.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar23 = vec2<f32>( ( p0_nodeVar19 + 1.0 ), 11.0 );
		p0_nodeVar24 = fract( ( vec3<f32>( p0_nodeVar23.x, p0_nodeVar23.y, p0_nodeVar23.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar25 = ( p0_nodeVar24 + vec3<f32>( dot( p0_nodeVar24, ( vec3<f32>( p0_nodeVar24.y, p0_nodeVar24.z, p0_nodeVar24.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar26 = fract( p0_nodeVar18 );
		p0_nodeVar27 = ( ( p0_nodeVar18 * 2.3 ) + 17.1 );
		p0_nodeVar28 = floor( p0_nodeVar27 );
		p0_nodeVar29 = vec2<f32>( p0_nodeVar28, 12.0 );
		p0_nodeVar30 = fract( ( vec3<f32>( p0_nodeVar29.x, p0_nodeVar29.y, p0_nodeVar29.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar31 = ( p0_nodeVar30 + vec3<f32>( dot( p0_nodeVar30, ( vec3<f32>( p0_nodeVar30.y, p0_nodeVar30.z, p0_nodeVar30.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar32 = vec2<f32>( ( p0_nodeVar28 + 1.0 ), 12.0 );
		p0_nodeVar33 = fract( ( vec3<f32>( p0_nodeVar32.x, p0_nodeVar32.y, p0_nodeVar32.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar34 = ( p0_nodeVar33 + vec3<f32>( dot( p0_nodeVar33, ( vec3<f32>( p0_nodeVar33.y, p0_nodeVar33.z, p0_nodeVar33.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar35 = fract( p0_nodeVar27 );
		p0_nodeVar36 = ( ( p0_nodeVar18 * 5.1 ) + 3.7 );
		p0_nodeVar37 = floor( p0_nodeVar36 );
		p0_nodeVar38 = vec2<f32>( p0_nodeVar37, 13.0 );
		p0_nodeVar39 = fract( ( vec3<f32>( p0_nodeVar38.x, p0_nodeVar38.y, p0_nodeVar38.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar40 = ( p0_nodeVar39 + vec3<f32>( dot( p0_nodeVar39, ( vec3<f32>( p0_nodeVar39.y, p0_nodeVar39.z, p0_nodeVar39.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar41 = vec2<f32>( ( p0_nodeVar37 + 1.0 ), 13.0 );
		p0_nodeVar42 = fract( ( vec3<f32>( p0_nodeVar41.x, p0_nodeVar41.y, p0_nodeVar41.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar43 = ( p0_nodeVar42 + vec3<f32>( dot( p0_nodeVar42, ( vec3<f32>( p0_nodeVar42.y, p0_nodeVar42.z, p0_nodeVar42.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar44 = fract( p0_nodeVar36 );
		p0_nodeVar45 = ( ( p0_nodeVar7 / 3.0 ) + p0_nodeVar13 );
		p0_nodeVar46 = floor( p0_nodeVar45 );
		p0_nodeVar47 = vec2<f32>( p0_nodeVar46, 14.0 );
		p0_nodeVar48 = fract( ( vec3<f32>( p0_nodeVar47.x, p0_nodeVar47.y, p0_nodeVar47.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar49 = ( p0_nodeVar48 + vec3<f32>( dot( p0_nodeVar48, ( vec3<f32>( p0_nodeVar48.y, p0_nodeVar48.z, p0_nodeVar48.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar50 = vec2<f32>( ( p0_nodeVar46 + 1.0 ), 14.0 );
		p0_nodeVar51 = fract( ( vec3<f32>( p0_nodeVar50.x, p0_nodeVar50.y, p0_nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar52 = ( p0_nodeVar51 + vec3<f32>( dot( p0_nodeVar51, ( vec3<f32>( p0_nodeVar51.y, p0_nodeVar51.z, p0_nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar53 = fract( p0_nodeVar45 );
		p0_nodeVar54 = vec2<f32>( ( floor( ( ( p0_nodeVar5 + ( ( ( ( ( ( mix( fract( ( ( p0_nodeVar22.x + p0_nodeVar22.y ) * p0_nodeVar22.z ) ), fract( ( ( p0_nodeVar25.x + p0_nodeVar25.y ) * p0_nodeVar25.z ) ), ( ( p0_nodeVar26 * p0_nodeVar26 ) * ( 3.0 - ( p0_nodeVar26 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( p0_nodeVar31.x + p0_nodeVar31.y ) * p0_nodeVar31.z ) ), fract( ( ( p0_nodeVar34.x + p0_nodeVar34.y ) * p0_nodeVar34.z ) ), ( ( p0_nodeVar35 * p0_nodeVar35 ) * ( 3.0 - ( p0_nodeVar35 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( p0_nodeVar40.x + p0_nodeVar40.y ) * p0_nodeVar40.z ) ), fract( ( ( p0_nodeVar43.x + p0_nodeVar43.y ) * p0_nodeVar43.z ) ), ( ( p0_nodeVar44 * p0_nodeVar44 ) * ( 3.0 - ( p0_nodeVar44 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * ( p0_nodeVar17 * 0.4 ) ) + ( ( mix( fract( ( ( p0_nodeVar49.x + p0_nodeVar49.y ) * p0_nodeVar49.z ) ), fract( ( ( p0_nodeVar52.x + p0_nodeVar52.y ) * p0_nodeVar52.z ) ), ( ( p0_nodeVar53 * p0_nodeVar53 ) * ( 3.0 - ( p0_nodeVar53 * 2.0 ) ) ) ) - 0.5 ) * ( p0_nodeVar17 * 0.04 ) ) ) ) / p0_nodeVar17 ) ) + p0_nodeVar13 ), p0_nodeVar14 );

		if ( ( f32(knobs.tear) > 0.0 ) ) {

			p0_nodeVar55 = fract( ( vec3<f32>( p0_nodeVar54.x, p0_nodeVar54.y, p0_nodeVar54.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar56 = ( p0_nodeVar55 + vec3<f32>( dot( p0_nodeVar55, ( vec3<f32>( p0_nodeVar55.y, p0_nodeVar55.z, p0_nodeVar55.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar57 = ( p0_nodeVar54 + vec2<f32>( 4.1 ) );
			p0_nodeVar58 = fract( ( vec3<f32>( p0_nodeVar57.x, p0_nodeVar57.y, p0_nodeVar57.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar59 = ( p0_nodeVar58 + vec3<f32>( dot( p0_nodeVar58, ( vec3<f32>( p0_nodeVar58.y, p0_nodeVar58.z, p0_nodeVar58.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar15 = ( p0_nodeVar7 + ( ( ( ( ( ( fract( ( ( p0_nodeVar56.x + p0_nodeVar56.y ) * p0_nodeVar56.z ) ) - 0.5 ) * 2.0 ) * f32(knobs.tear) ) * p0_nodeVar11 ) * 0.3 ) * step( fract( ( ( p0_nodeVar59.x + p0_nodeVar59.y ) * p0_nodeVar59.z ) ), ( ( f32(knobs.tear) * 0.6 ) + 0.4 ) ) ) );
			

		}


		if ( ( f32(knobs.dropout) >= 0.0001 ) ) {

			p0_nodeVar60 = ( p0_nodeVar54 + vec2<f32>( 2.3 ) );
			p0_nodeVar61 = fract( ( vec3<f32>( p0_nodeVar60.x, p0_nodeVar60.y, p0_nodeVar60.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar62 = ( p0_nodeVar61 + vec3<f32>( dot( p0_nodeVar61, ( vec3<f32>( p0_nodeVar61.y, p0_nodeVar61.z, p0_nodeVar61.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar63 = ( p0_nodeVar54 + vec2<f32>( 9.7 ) );
			p0_nodeVar64 = fract( ( vec3<f32>( p0_nodeVar63.x, p0_nodeVar63.y, p0_nodeVar63.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar65 = ( p0_nodeVar64 + vec3<f32>( dot( p0_nodeVar64, ( vec3<f32>( p0_nodeVar64.y, p0_nodeVar64.z, p0_nodeVar64.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar66 = ( ( p0_nodeVar5 / 19.0 ) + p0_nodeVar13 );
			p0_nodeVar67 = floor( p0_nodeVar66 );
			p0_nodeVar68 = vec2<f32>( p0_nodeVar67, 23.0 );
			p0_nodeVar69 = fract( ( vec3<f32>( p0_nodeVar68.x, p0_nodeVar68.y, p0_nodeVar68.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar70 = ( p0_nodeVar69 + vec3<f32>( dot( p0_nodeVar69, ( vec3<f32>( p0_nodeVar69.y, p0_nodeVar69.z, p0_nodeVar69.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar71 = vec2<f32>( ( p0_nodeVar67 + 1.0 ), 23.0 );
			p0_nodeVar72 = fract( ( vec3<f32>( p0_nodeVar71.x, p0_nodeVar71.y, p0_nodeVar71.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar73 = ( p0_nodeVar72 + vec3<f32>( dot( p0_nodeVar72, ( vec3<f32>( p0_nodeVar72.y, p0_nodeVar72.z, p0_nodeVar72.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar74 = fract( p0_nodeVar66 );
			p0_nodeVar75 = ( ( p0_nodeVar66 * 2.3 ) + 17.1 );
			p0_nodeVar76 = floor( p0_nodeVar75 );
			p0_nodeVar77 = vec2<f32>( p0_nodeVar76, 24.0 );
			p0_nodeVar78 = fract( ( vec3<f32>( p0_nodeVar77.x, p0_nodeVar77.y, p0_nodeVar77.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar79 = ( p0_nodeVar78 + vec3<f32>( dot( p0_nodeVar78, ( vec3<f32>( p0_nodeVar78.y, p0_nodeVar78.z, p0_nodeVar78.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar80 = vec2<f32>( ( p0_nodeVar76 + 1.0 ), 24.0 );
			p0_nodeVar81 = fract( ( vec3<f32>( p0_nodeVar80.x, p0_nodeVar80.y, p0_nodeVar80.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar82 = ( p0_nodeVar81 + vec3<f32>( dot( p0_nodeVar81, ( vec3<f32>( p0_nodeVar81.y, p0_nodeVar81.z, p0_nodeVar81.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar83 = fract( p0_nodeVar75 );
			p0_nodeVar84 = ( ( p0_nodeVar66 * 5.1 ) + 3.7 );
			p0_nodeVar85 = floor( p0_nodeVar84 );
			p0_nodeVar86 = vec2<f32>( p0_nodeVar85, 25.0 );
			p0_nodeVar87 = fract( ( vec3<f32>( p0_nodeVar86.x, p0_nodeVar86.y, p0_nodeVar86.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar88 = ( p0_nodeVar87 + vec3<f32>( dot( p0_nodeVar87, ( vec3<f32>( p0_nodeVar87.y, p0_nodeVar87.z, p0_nodeVar87.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar89 = vec2<f32>( ( p0_nodeVar85 + 1.0 ), 25.0 );
			p0_nodeVar90 = fract( ( vec3<f32>( p0_nodeVar89.x, p0_nodeVar89.y, p0_nodeVar89.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar91 = ( p0_nodeVar90 + vec3<f32>( dot( p0_nodeVar90, ( vec3<f32>( p0_nodeVar90.y, p0_nodeVar90.z, p0_nodeVar90.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar92 = fract( p0_nodeVar84 );
			p0_nodeVar93 = vec2<f32>( floor( ( p0_nodeVar5 / 1.5 ) ), ( p0_nodeVar13 + 23.0 ) );
			p0_nodeVar94 = fract( ( vec3<f32>( p0_nodeVar93.x, p0_nodeVar93.y, p0_nodeVar93.x ) * vec3<f32>( 0.1031 ) ) );
			p0_nodeVar95 = ( p0_nodeVar94 + vec3<f32>( dot( p0_nodeVar94, ( vec3<f32>( p0_nodeVar94.y, p0_nodeVar94.z, p0_nodeVar94.x ) + vec3<f32>( 33.33 ) ) ) ) );
			p0_nodeVar16 = ( ( step( fract( ( ( p0_nodeVar62.x + p0_nodeVar62.y ) * p0_nodeVar62.z ) ), f32(knobs.dropout) ) * step( ( p0_nodeVar7 / p0_nodeVar11 ), ( ( ( fract( ( ( p0_nodeVar65.x + p0_nodeVar65.y ) * p0_nodeVar65.z ) ) * 0.7 ) + ( ( ( ( ( mix( fract( ( ( p0_nodeVar70.x + p0_nodeVar70.y ) * p0_nodeVar70.z ) ), fract( ( ( p0_nodeVar73.x + p0_nodeVar73.y ) * p0_nodeVar73.z ) ), ( ( p0_nodeVar74 * p0_nodeVar74 ) * ( 3.0 - ( p0_nodeVar74 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( p0_nodeVar79.x + p0_nodeVar79.y ) * p0_nodeVar79.z ) ), fract( ( ( p0_nodeVar82.x + p0_nodeVar82.y ) * p0_nodeVar82.z ) ), ( ( p0_nodeVar83 * p0_nodeVar83 ) * ( 3.0 - ( p0_nodeVar83 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( p0_nodeVar88.x + p0_nodeVar88.y ) * p0_nodeVar88.z ) ), fract( ( ( p0_nodeVar91.x + p0_nodeVar91.y ) * p0_nodeVar91.z ) ), ( ( p0_nodeVar92 * p0_nodeVar92 ) * ( 3.0 - ( p0_nodeVar92 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * 0.06 ) ) + ( fract( ( ( p0_nodeVar95.x + p0_nodeVar95.y ) * p0_nodeVar95.z ) ) * 0.012 ) ) ) ) * step( 0.0001, f32(knobs.dropout) ) );
			

		}

		

	}


	if ( ( f32(knobs.wobble) > 0.0 ) ) {

		p0_nodeVar96 = ( ( ( p0_nodeVar5 / ( f32(knobs.wobbleScale) * p0_nodeVar12 ) ) + p0_nodeVar13 ) + ( f32(0.0) * 0.6 ) );
		p0_nodeVar97 = floor( p0_nodeVar96 );
		p0_nodeVar98 = vec2<f32>( p0_nodeVar97, 31.0 );
		p0_nodeVar99 = fract( ( vec3<f32>( p0_nodeVar98.x, p0_nodeVar98.y, p0_nodeVar98.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar100 = ( p0_nodeVar99 + vec3<f32>( dot( p0_nodeVar99, ( vec3<f32>( p0_nodeVar99.y, p0_nodeVar99.z, p0_nodeVar99.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar101 = vec2<f32>( ( p0_nodeVar97 + 1.0 ), 31.0 );
		p0_nodeVar102 = fract( ( vec3<f32>( p0_nodeVar101.x, p0_nodeVar101.y, p0_nodeVar101.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar103 = ( p0_nodeVar102 + vec3<f32>( dot( p0_nodeVar102, ( vec3<f32>( p0_nodeVar102.y, p0_nodeVar102.z, p0_nodeVar102.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar104 = fract( p0_nodeVar96 );
		p0_nodeVar105 = ( ( p0_nodeVar96 * 2.3 ) + 17.1 );
		p0_nodeVar106 = floor( p0_nodeVar105 );
		p0_nodeVar107 = vec2<f32>( p0_nodeVar106, 32.0 );
		p0_nodeVar108 = fract( ( vec3<f32>( p0_nodeVar107.x, p0_nodeVar107.y, p0_nodeVar107.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar109 = ( p0_nodeVar108 + vec3<f32>( dot( p0_nodeVar108, ( vec3<f32>( p0_nodeVar108.y, p0_nodeVar108.z, p0_nodeVar108.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar110 = vec2<f32>( ( p0_nodeVar106 + 1.0 ), 32.0 );
		p0_nodeVar111 = fract( ( vec3<f32>( p0_nodeVar110.x, p0_nodeVar110.y, p0_nodeVar110.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar112 = ( p0_nodeVar111 + vec3<f32>( dot( p0_nodeVar111, ( vec3<f32>( p0_nodeVar111.y, p0_nodeVar111.z, p0_nodeVar111.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar113 = fract( p0_nodeVar105 );
		p0_nodeVar114 = ( ( p0_nodeVar96 * 5.1 ) + 3.7 );
		p0_nodeVar115 = floor( p0_nodeVar114 );
		p0_nodeVar116 = vec2<f32>( p0_nodeVar115, 33.0 );
		p0_nodeVar117 = fract( ( vec3<f32>( p0_nodeVar116.x, p0_nodeVar116.y, p0_nodeVar116.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar118 = ( p0_nodeVar117 + vec3<f32>( dot( p0_nodeVar117, ( vec3<f32>( p0_nodeVar117.y, p0_nodeVar117.z, p0_nodeVar117.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar119 = vec2<f32>( ( p0_nodeVar115 + 1.0 ), 33.0 );
		p0_nodeVar120 = fract( ( vec3<f32>( p0_nodeVar119.x, p0_nodeVar119.y, p0_nodeVar119.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar121 = ( p0_nodeVar120 + vec3<f32>( dot( p0_nodeVar120, ( vec3<f32>( p0_nodeVar120.y, p0_nodeVar120.z, p0_nodeVar120.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar122 = fract( p0_nodeVar114 );
		p0_nodeVar15 = ( p0_nodeVar15 + ( ( ( ( ( ( ( ( mix( fract( ( ( p0_nodeVar100.x + p0_nodeVar100.y ) * p0_nodeVar100.z ) ), fract( ( ( p0_nodeVar103.x + p0_nodeVar103.y ) * p0_nodeVar103.z ) ), ( ( p0_nodeVar104 * p0_nodeVar104 ) * ( 3.0 - ( p0_nodeVar104 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( p0_nodeVar109.x + p0_nodeVar109.y ) * p0_nodeVar109.z ) ), fract( ( ( p0_nodeVar112.x + p0_nodeVar112.y ) * p0_nodeVar112.z ) ), ( ( p0_nodeVar113 * p0_nodeVar113 ) * ( 3.0 - ( p0_nodeVar113 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( p0_nodeVar118.x + p0_nodeVar118.y ) * p0_nodeVar118.z ) ), fract( ( ( p0_nodeVar121.x + p0_nodeVar121.y ) * p0_nodeVar121.z ) ), ( ( p0_nodeVar122 * p0_nodeVar122 ) * ( 3.0 - ( p0_nodeVar122 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * 2.0 ) * f32(knobs.wobble) ) * p0_nodeVar12 ) * 0.12 ) );
		

	}

	p0_nodeVar123 = p0_nodeVar5;

	if ( ( f32(knobs.stretch) > 0.0 ) ) {

		p0_nodeVar124 = ( ( p0_nodeVar5 / ( p0_nodeVar12 * 0.45 ) ) + ( p0_nodeVar13 * 1.3 ) );
		p0_nodeVar125 = floor( p0_nodeVar124 );
		p0_nodeVar126 = vec2<f32>( p0_nodeVar125, 41.0 );
		p0_nodeVar127 = fract( ( vec3<f32>( p0_nodeVar126.x, p0_nodeVar126.y, p0_nodeVar126.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar128 = ( p0_nodeVar127 + vec3<f32>( dot( p0_nodeVar127, ( vec3<f32>( p0_nodeVar127.y, p0_nodeVar127.z, p0_nodeVar127.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar129 = vec2<f32>( ( p0_nodeVar125 + 1.0 ), 41.0 );
		p0_nodeVar130 = fract( ( vec3<f32>( p0_nodeVar129.x, p0_nodeVar129.y, p0_nodeVar129.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar131 = ( p0_nodeVar130 + vec3<f32>( dot( p0_nodeVar130, ( vec3<f32>( p0_nodeVar130.y, p0_nodeVar130.z, p0_nodeVar130.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar132 = fract( p0_nodeVar124 );
		p0_nodeVar133 = ( ( p0_nodeVar124 * 2.3 ) + 17.1 );
		p0_nodeVar134 = floor( p0_nodeVar133 );
		p0_nodeVar135 = vec2<f32>( p0_nodeVar134, 42.0 );
		p0_nodeVar136 = fract( ( vec3<f32>( p0_nodeVar135.x, p0_nodeVar135.y, p0_nodeVar135.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar137 = ( p0_nodeVar136 + vec3<f32>( dot( p0_nodeVar136, ( vec3<f32>( p0_nodeVar136.y, p0_nodeVar136.z, p0_nodeVar136.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar138 = vec2<f32>( ( p0_nodeVar134 + 1.0 ), 42.0 );
		p0_nodeVar139 = fract( ( vec3<f32>( p0_nodeVar138.x, p0_nodeVar138.y, p0_nodeVar138.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar140 = ( p0_nodeVar139 + vec3<f32>( dot( p0_nodeVar139, ( vec3<f32>( p0_nodeVar139.y, p0_nodeVar139.z, p0_nodeVar139.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar141 = fract( p0_nodeVar133 );
		p0_nodeVar142 = ( ( p0_nodeVar124 * 5.1 ) + 3.7 );
		p0_nodeVar143 = floor( p0_nodeVar142 );
		p0_nodeVar144 = vec2<f32>( p0_nodeVar143, 43.0 );
		p0_nodeVar145 = fract( ( vec3<f32>( p0_nodeVar144.x, p0_nodeVar144.y, p0_nodeVar144.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar146 = ( p0_nodeVar145 + vec3<f32>( dot( p0_nodeVar145, ( vec3<f32>( p0_nodeVar145.y, p0_nodeVar145.z, p0_nodeVar145.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar147 = vec2<f32>( ( p0_nodeVar143 + 1.0 ), 43.0 );
		p0_nodeVar148 = fract( ( vec3<f32>( p0_nodeVar147.x, p0_nodeVar147.y, p0_nodeVar147.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar149 = ( p0_nodeVar148 + vec3<f32>( dot( p0_nodeVar148, ( vec3<f32>( p0_nodeVar148.y, p0_nodeVar148.z, p0_nodeVar148.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar150 = fract( p0_nodeVar142 );
		p0_nodeVar123 = ( p0_nodeVar5 + ( ( ( ( ( ( ( mix( fract( ( ( p0_nodeVar128.x + p0_nodeVar128.y ) * p0_nodeVar128.z ) ), fract( ( ( p0_nodeVar131.x + p0_nodeVar131.y ) * p0_nodeVar131.z ) ), ( ( p0_nodeVar132 * p0_nodeVar132 ) * ( 3.0 - ( p0_nodeVar132 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( p0_nodeVar137.x + p0_nodeVar137.y ) * p0_nodeVar137.z ) ), fract( ( ( p0_nodeVar140.x + p0_nodeVar140.y ) * p0_nodeVar140.z ) ), ( ( p0_nodeVar141 * p0_nodeVar141 ) * ( 3.0 - ( p0_nodeVar141 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( p0_nodeVar146.x + p0_nodeVar146.y ) * p0_nodeVar146.z ) ), fract( ( ( p0_nodeVar149.x + p0_nodeVar149.y ) * p0_nodeVar149.z ) ), ( ( p0_nodeVar150 * p0_nodeVar150 ) * ( 3.0 - ( p0_nodeVar150 * 2.0 ) ) ) ) * 0.1 ) ) - 0.5 ) * f32(knobs.stretch) ) * p0_nodeVar12 ) * 0.35 ) );
		

	}


	if ( ( f32(knobs.drag) >= 0.0001 ) ) {

		p0_nodeVar151 = ( f32(knobs.dragLength) * p0_nodeVar9 );
		p0_nodeVar152 = ( ( p0_nodeVar7 / ( p0_nodeVar12 * 0.12 ) ) + p0_nodeVar13 );
		p0_nodeVar153 = floor( p0_nodeVar152 );
		p0_nodeVar154 = vec2<f32>( p0_nodeVar153, 51.0 );
		p0_nodeVar155 = fract( ( vec3<f32>( p0_nodeVar154.x, p0_nodeVar154.y, p0_nodeVar154.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar156 = ( p0_nodeVar155 + vec3<f32>( dot( p0_nodeVar155, ( vec3<f32>( p0_nodeVar155.y, p0_nodeVar155.z, p0_nodeVar155.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar157 = vec2<f32>( ( p0_nodeVar153 + 1.0 ), 51.0 );
		p0_nodeVar158 = fract( ( vec3<f32>( p0_nodeVar157.x, p0_nodeVar157.y, p0_nodeVar157.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar159 = ( p0_nodeVar158 + vec3<f32>( dot( p0_nodeVar158, ( vec3<f32>( p0_nodeVar158.y, p0_nodeVar158.z, p0_nodeVar158.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar160 = fract( p0_nodeVar152 );
		p0_nodeVar161 = ( ( p0_nodeVar152 * 2.3 ) + 17.1 );
		p0_nodeVar162 = floor( p0_nodeVar161 );
		p0_nodeVar163 = vec2<f32>( p0_nodeVar162, 52.0 );
		p0_nodeVar164 = fract( ( vec3<f32>( p0_nodeVar163.x, p0_nodeVar163.y, p0_nodeVar163.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar165 = ( p0_nodeVar164 + vec3<f32>( dot( p0_nodeVar164, ( vec3<f32>( p0_nodeVar164.y, p0_nodeVar164.z, p0_nodeVar164.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar166 = vec2<f32>( ( p0_nodeVar162 + 1.0 ), 52.0 );
		p0_nodeVar167 = fract( ( vec3<f32>( p0_nodeVar166.x, p0_nodeVar166.y, p0_nodeVar166.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar168 = ( p0_nodeVar167 + vec3<f32>( dot( p0_nodeVar167, ( vec3<f32>( p0_nodeVar167.y, p0_nodeVar167.z, p0_nodeVar167.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar169 = fract( p0_nodeVar161 );
		p0_nodeVar170 = ( ( p0_nodeVar152 * 5.1 ) + 3.7 );
		p0_nodeVar171 = floor( p0_nodeVar170 );
		p0_nodeVar172 = vec2<f32>( p0_nodeVar171, 53.0 );
		p0_nodeVar173 = fract( ( vec3<f32>( p0_nodeVar172.x, p0_nodeVar172.y, p0_nodeVar172.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar174 = ( p0_nodeVar173 + vec3<f32>( dot( p0_nodeVar173, ( vec3<f32>( p0_nodeVar173.y, p0_nodeVar173.z, p0_nodeVar173.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar175 = vec2<f32>( ( p0_nodeVar171 + 1.0 ), 53.0 );
		p0_nodeVar176 = fract( ( vec3<f32>( p0_nodeVar175.x, p0_nodeVar175.y, p0_nodeVar175.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar177 = ( p0_nodeVar176 + vec3<f32>( dot( p0_nodeVar176, ( vec3<f32>( p0_nodeVar176.y, p0_nodeVar176.z, p0_nodeVar176.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar178 = fract( p0_nodeVar170 );
		p0_nodeVar179 = ( ( p0_nodeVar7 / 4.0 ) + p0_nodeVar13 );
		p0_nodeVar180 = floor( p0_nodeVar179 );
		p0_nodeVar181 = vec2<f32>( p0_nodeVar180, 54.0 );
		p0_nodeVar182 = fract( ( vec3<f32>( p0_nodeVar181.x, p0_nodeVar181.y, p0_nodeVar181.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar183 = ( p0_nodeVar182 + vec3<f32>( dot( p0_nodeVar182, ( vec3<f32>( p0_nodeVar182.y, p0_nodeVar182.z, p0_nodeVar182.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar184 = vec2<f32>( ( p0_nodeVar180 + 1.0 ), 54.0 );
		p0_nodeVar185 = fract( ( vec3<f32>( p0_nodeVar184.x, p0_nodeVar184.y, p0_nodeVar184.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar186 = ( p0_nodeVar185 + vec3<f32>( dot( p0_nodeVar185, ( vec3<f32>( p0_nodeVar185.y, p0_nodeVar185.z, p0_nodeVar185.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar187 = fract( p0_nodeVar179 );
		p0_nodeVar188 = ( ( ( ( ( ( mix( fract( ( ( p0_nodeVar156.x + p0_nodeVar156.y ) * p0_nodeVar156.z ) ), fract( ( ( p0_nodeVar159.x + p0_nodeVar159.y ) * p0_nodeVar159.z ) ), ( ( p0_nodeVar160 * p0_nodeVar160 ) * ( 3.0 - ( p0_nodeVar160 * 2.0 ) ) ) ) * 0.6 ) + ( mix( fract( ( ( p0_nodeVar165.x + p0_nodeVar165.y ) * p0_nodeVar165.z ) ), fract( ( ( p0_nodeVar168.x + p0_nodeVar168.y ) * p0_nodeVar168.z ) ), ( ( p0_nodeVar169 * p0_nodeVar169 ) * ( 3.0 - ( p0_nodeVar169 * 2.0 ) ) ) ) * 0.3 ) ) + ( mix( fract( ( ( p0_nodeVar174.x + p0_nodeVar174.y ) * p0_nodeVar174.z ) ), fract( ( ( p0_nodeVar177.x + p0_nodeVar177.y ) * p0_nodeVar177.z ) ), ( ( p0_nodeVar178 * p0_nodeVar178 ) * ( 3.0 - ( p0_nodeVar178 * 2.0 ) ) ) ) * 0.1 ) ) * 0.35 ) + ( mix( fract( ( ( p0_nodeVar183.x + p0_nodeVar183.y ) * p0_nodeVar183.z ) ), fract( ( ( p0_nodeVar186.x + p0_nodeVar186.y ) * p0_nodeVar186.z ) ), ( ( p0_nodeVar187 * p0_nodeVar187 ) * ( 3.0 - ( p0_nodeVar187 * 2.0 ) ) ) ) * 0.03 ) ) * p0_nodeVar151 );
		p0_nodeVar189 = floor( ( ( p0_nodeVar123 + p0_nodeVar188 ) / p0_nodeVar151 ) );
		p0_nodeVar190 = vec2<f32>( ( p0_nodeVar189 + p0_nodeVar13 ), ( p0_nodeVar14 * 3.0 ) );
		p0_nodeVar191 = fract( ( vec3<f32>( p0_nodeVar190.x, p0_nodeVar190.y, p0_nodeVar190.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar192 = ( p0_nodeVar191 + vec3<f32>( dot( p0_nodeVar191, ( vec3<f32>( p0_nodeVar191.y, p0_nodeVar191.z, p0_nodeVar191.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar123 = mix( p0_nodeVar123, ( ( p0_nodeVar189 * p0_nodeVar151 ) - p0_nodeVar188 ), ( step( fract( ( ( p0_nodeVar192.x + p0_nodeVar192.y ) * p0_nodeVar192.z ) ), f32(knobs.drag) ) * step( 0.0001, f32(knobs.drag) ) ) );
		

	}

	p0_nodeVar193 = floor( ( p0_nodeVar7 / 2.0 ) );

	if ( ( f32(knobs.lineNoise) > 0.0 ) ) {

		p0_nodeVar194 = vec2<f32>( ( p0_nodeVar193 + p0_nodeVar13 ), ( p0_nodeVar14 + 1.0 ) );
		p0_nodeVar195 = fract( ( vec3<f32>( p0_nodeVar194.x, p0_nodeVar194.y, p0_nodeVar194.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar196 = ( p0_nodeVar195 + vec3<f32>( dot( p0_nodeVar195, ( vec3<f32>( p0_nodeVar195.y, p0_nodeVar195.z, p0_nodeVar195.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar197 = ( p0_nodeVar194 + vec2<f32>( 6.6 ) );
		p0_nodeVar198 = fract( ( vec3<f32>( p0_nodeVar197.x, p0_nodeVar197.y, p0_nodeVar197.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar199 = ( p0_nodeVar198 + vec3<f32>( dot( p0_nodeVar198, ( vec3<f32>( p0_nodeVar198.y, p0_nodeVar198.z, p0_nodeVar198.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar123 = ( p0_nodeVar123 + ( ( ( ( ( fract( ( ( p0_nodeVar196.x + p0_nodeVar196.y ) * p0_nodeVar196.z ) ) - 0.5 ) * f32(knobs.lineNoise) ) * p0_nodeVar12 ) * 0.06 ) * step( fract( ( ( p0_nodeVar199.x + p0_nodeVar199.y ) * p0_nodeVar199.z ) ), ( f32(knobs.lineNoise) * 0.5 ) ) ) );
		

	}


	if ( p0_nodeVar4 ) {

		p0_nodeVar200 = vec2<f32>( p0_nodeVar15, p0_nodeVar123 );

	} else {

		p0_nodeVar200 = vec2<f32>( p0_nodeVar123, p0_nodeVar15 );

	}

	p0_nodeVar201 = picture_read_level( ( p0_nodeVar200 / p0_nodeVar1 ), 0.0 );
	p0_nodeVar202 = p0_nodeVar201;
	p0_nodeVar203 = vec3<f32>( p0_nodeVar202.x, p0_nodeVar202.y, p0_nodeVar202.z );

	if ( ( f32(knobs.chroma) > 0.0 ) ) {

		p0_nodeVar204 = ( ( f32(knobs.chroma) * p0_nodeVar12 ) * 0.02 );

		if ( p0_nodeVar4 ) {

			p0_nodeVar205 = vec2<f32>( p0_nodeVar15, ( p0_nodeVar123 + p0_nodeVar204 ) );

		} else {

			p0_nodeVar205 = vec2<f32>( ( p0_nodeVar123 + p0_nodeVar204 ), p0_nodeVar15 );

		}

		p0_nodeVar206 = picture_read_level( ( p0_nodeVar205 / p0_nodeVar1 ), 0.0 );

		if ( p0_nodeVar4 ) {

			p0_nodeVar207 = vec2<f32>( p0_nodeVar15, ( p0_nodeVar123 - p0_nodeVar204 ) );

		} else {

			p0_nodeVar207 = vec2<f32>( ( p0_nodeVar123 - p0_nodeVar204 ), p0_nodeVar15 );

		}

		p0_nodeVar208 = picture_read_level( ( p0_nodeVar207 / p0_nodeVar1 ), 0.0 );
		p0_nodeVar203 = vec3<f32>( p0_nodeVar206.x, p0_nodeVar202.y, p0_nodeVar208.z );
		

	}


	if ( ( f32(knobs.crush) >= 0.0001 ) ) {

		p0_nodeVar209 = mix( 64.0, 3.0, f32(knobs.crush) );
		p0_nodeVar203 = mix( p0_nodeVar203, pow( ( floor( ( ( pow( max( p0_nodeVar203, vec3<f32>( 0.0, 0.0, 0.0 ) ), vec3<f32>( 0.45454545454545453, 0.45454545454545453, 0.45454545454545453 ) ) * vec3<f32>( p0_nodeVar209 ) ) + vec3<f32>( 0.5 ) ) ) / vec3<f32>( p0_nodeVar209 ) ), vec3<f32>( 2.2, 2.2, 2.2 ) ), step( 0.0001, f32(knobs.crush) ) );
		

	}


	if ( ( f32(knobs.lineNoise) >= 0.0001 ) ) {

		p0_nodeVar210 = vec2<f32>( ( p0_nodeVar193 + ( p0_nodeVar13 * 2.0 ) ), ( p0_nodeVar14 + 2.0 ) );
		p0_nodeVar211 = fract( ( vec3<f32>( p0_nodeVar210.x, p0_nodeVar210.y, p0_nodeVar210.x ) * vec3<f32>( 0.1031 ) ) );
		p0_nodeVar212 = ( p0_nodeVar211 + vec3<f32>( dot( p0_nodeVar211, ( vec3<f32>( p0_nodeVar211.y, p0_nodeVar211.z, p0_nodeVar211.x ) + vec3<f32>( 33.33 ) ) ) ) );
		p0_nodeVar203 = mix( p0_nodeVar203, clamp( ( p0_nodeVar203 + vec3<f32>( ( ( ( fract( ( ( p0_nodeVar212.x + p0_nodeVar212.y ) * p0_nodeVar212.z ) ) - 0.5 ) * f32(knobs.lineNoise) ) * 0.35 ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), step( 0.0001, f32(knobs.lineNoise) ) );
		

	}

	p0_nodeVar213 = vec4<f32>( mix( p0_nodeVar203, vec3<f32>(knobs.dropoutColor.x, knobs.dropoutColor.y, knobs.dropoutColor.z), p0_nodeVar16 ), 1.0 );
	p0_nodeVar214 = vec3<f32>( p0_nodeVar213.x, p0_nodeVar213.y, p0_nodeVar213.z );
	p0_nodeVar215 = ( ( ( p0_nodeVar214.x * 0.2126 ) + ( p0_nodeVar214.y * 0.7152 ) ) + ( p0_nodeVar214.z * 0.0722 ) );
	p0_nodeVar216 = mix( vec3<f32>( p0_nodeVar215, p0_nodeVar215, p0_nodeVar215 ), p0_nodeVar214, f32(1.0) );
	p0_nodeVar217 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar216.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar216.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar216.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar216.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar216.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar216.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar216.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar216.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar216.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar213.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar217.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar217.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar218 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar218;

	// result

	p0_output.color = p0_nodeVar218;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

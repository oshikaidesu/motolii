// Fluted Glass: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Distort
// --about:Ribbed glass that slices the image into vertical strips with a slight color split.
// --check@preset:Preset,0
// --track@frequency:Frequency,2,100,20,1
// --track@amplitude:Amplitude,0,0.1,0.02,0.001
// --track@warp:Warp,0,1,0.28,0.01
// --track@irregularity:Irregularity,0,1,0.35,0.01
// --track@angle:Angle,0,360,0,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  preset: f32,
  frequency: f32,
  amplitude: f32,
  warp: f32,
  irregularity: f32,
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
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : bool;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec3<f32>;
var<private> p0_nodeVar10 : vec3<f32>;
var<private> p0_nodeVar11 : vec3<f32>;
var<private> p0_nodeVar12 : vec3<f32>;
var<private> p0_nodeVar13 : vec3<f32>;
var<private> p0_nodeVar14 : vec3<f32>;
var<private> p0_nodeVar15 : vec3<f32>;
var<private> p0_nodeVar16 : vec3<f32>;
var<private> p0_nodeVar17 : vec3<f32>;
var<private> p0_nodeVar18 : vec3<f32>;
var<private> p0_nodeVar19 : vec4<f32>;
var<private> p0_nodeVar20 : vec4<f32>;
var<private> p0_nodeVar21 : vec4<f32>;
var<private> p0_nodeVar22 : vec4<f32>;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : vec3<f32>;
var<private> p0_nodeVar25 : vec4<f32>;
var<private> p0_nodeVar26 : vec4<f32>;
var<private> p0_nodeVar27 : vec4<f32>;
var<private> p0_nodeVar28 : vec4<f32>;
var<private> p0_nodeVar29 : vec4<f32>;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : vec4<f32>;
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : vec4<f32>;
var<private> p0_nodeVar34 : vec4<f32>;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : vec3<f32>;
var<private> p0_nodeVar37 : vec3<f32>;
var<private> p0_nodeVar38 : vec3<f32>;
var<private> p0_nodeVar39 : vec3<f32>;
var<private> p0_nodeVar40 : vec4<f32>;
var<private> p0_nodeVar41 : vec4<f32>;
var<private> p0_nodeVar42 : vec3<f32>;
var<private> p0_nodeVar43 : vec3<f32>;
var<private> p0_nodeVar44 : vec3<f32>;
var<private> p0_nodeVar45 : vec3<f32>;
var<private> p0_nodeVar46 : vec3<f32>;
var<private> p0_nodeVar47 : vec3<f32>;
var<private> p0_nodeVar48 : vec3<f32>;
var<private> p0_nodeVar49 : vec3<f32>;
var<private> p0_nodeVar50 : vec3<f32>;
var<private> p0_nodeVar51 : vec3<f32>;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : vec4<f32>;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : vec4<f32>;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : vec3<f32>;
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
var<private> p0_nodeVar68 : vec4<f32>;
var<private> p0_nodeVar69 : vec3<f32>;
var<private> p0_nodeVar70 : vec3<f32>;
var<private> p0_nodeVar71 : vec3<f32>;
var<private> p0_nodeVar72 : vec3<f32>;
var<private> p0_nodeVar73 : vec4<f32>;
var<private> p0_nodeVar74 : vec4<f32>;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : vec3<f32>;
var<private> p0_nodeVar77 : vec3<f32>;
var<private> p0_nodeVar78 : vec3<f32>;
var<private> p0_nodeVar79 : vec3<f32>;
var<private> p0_nodeVar80 : vec3<f32>;
var<private> p0_nodeVar81 : vec3<f32>;
var<private> p0_nodeVar82 : vec3<f32>;
var<private> p0_nodeVar83 : vec3<f32>;
var<private> p0_nodeVar84 : vec3<f32>;
var<private> p0_nodeVar85 : vec3<f32>;
var<private> p0_nodeVar86 : vec4<f32>;
var<private> p0_nodeVar87 : vec4<f32>;
var<private> p0_nodeVar88 : vec4<f32>;
var<private> p0_nodeVar89 : vec4<f32>;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : vec3<f32>;
var<private> p0_nodeVar92 : vec4<f32>;
var<private> p0_nodeVar93 : vec4<f32>;
var<private> p0_nodeVar94 : vec4<f32>;
var<private> p0_nodeVar95 : vec4<f32>;
var<private> p0_nodeVar96 : vec4<f32>;
var<private> p0_nodeVar97 : vec4<f32>;
var<private> p0_nodeVar98 : vec4<f32>;
var<private> p0_nodeVar99 : vec4<f32>;
var<private> p0_nodeVar100 : vec4<f32>;
var<private> p0_nodeVar101 : vec4<f32>;
var<private> p0_nodeVar102 : vec4<f32>;
var<private> p0_nodeVar103 : vec3<f32>;
var<private> p0_nodeVar104 : vec3<f32>;
var<private> p0_nodeVar105 : vec3<f32>;
var<private> p0_nodeVar106 : vec3<f32>;
var<private> p0_nodeVar107 : vec4<f32>;
var<private> p0_nodeVar108 : vec4<f32>;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : vec3<f32>;
var<private> p0_nodeVar115 : vec3<f32>;
var<private> p0_nodeVar116 : vec3<f32>;
var<private> p0_nodeVar117 : vec3<f32>;
var<private> p0_nodeVar118 : vec3<f32>;
var<private> p0_nodeVar119 : vec3<f32>;
var<private> p0_nodeVar120 : vec3<f32>;
var<private> p0_nodeVar121 : vec3<f32>;
var<private> p0_nodeVar122 : vec3<f32>;
var<private> p0_nodeVar123 : vec3<f32>;
var<private> p0_nodeVar124 : vec4<f32>;
var<private> p0_nodeVar125 : vec4<f32>;
var<private> p0_nodeVar126 : vec4<f32>;
var<private> p0_nodeVar127 : vec4<f32>;
var<private> p0_nodeVar128 : f32;
var<private> p0_nodeVar129 : vec3<f32>;
var<private> p0_nodeVar130 : vec4<f32>;
var<private> p0_nodeVar131 : vec4<f32>;
var<private> p0_nodeVar132 : vec4<f32>;
var<private> p0_nodeVar133 : vec4<f32>;
var<private> p0_nodeVar134 : vec4<f32>;
var<private> p0_nodeVar135 : vec4<f32>;
var<private> p0_nodeVar136 : vec4<f32>;
var<private> p0_nodeVar137 : vec4<f32>;
var<private> p0_nodeVar138 : vec4<f32>;
var<private> p0_nodeVar139 : vec4<f32>;
var<private> p0_nodeVar140 : vec4<f32>;
var<private> p0_nodeVar141 : vec3<f32>;
var<private> p0_nodeVar142 : vec3<f32>;
var<private> p0_nodeVar143 : vec3<f32>;
var<private> p0_nodeVar144 : vec3<f32>;
var<private> p0_nodeVar145 : vec4<f32>;
var<private> p0_nodeVar146 : vec4<f32>;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : f32;
var<private> p0_nodeVar149 : f32;
var<private> p0_nodeVar150 : vec3<f32>;
var<private> p0_nodeVar151 : vec3<f32>;
var<private> p0_nodeVar152 : vec3<f32>;
var<private> p0_nodeVar153 : vec3<f32>;
var<private> p0_nodeVar154 : vec3<f32>;
var<private> p0_nodeVar155 : vec3<f32>;
var<private> p0_nodeVar156 : vec3<f32>;
var<private> p0_nodeVar157 : vec3<f32>;
var<private> p0_nodeVar158 : vec3<f32>;
var<private> p0_nodeVar159 : vec3<f32>;
var<private> p0_nodeVar160 : vec4<f32>;
var<private> p0_nodeVar161 : vec4<f32>;
var<private> p0_nodeVar162 : vec4<f32>;
var<private> p0_nodeVar163 : vec4<f32>;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : vec3<f32>;
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
var<private> p0_nodeVar176 : vec4<f32>;
var<private> p0_nodeVar177 : vec3<f32>;
var<private> p0_nodeVar178 : vec3<f32>;
var<private> p0_nodeVar179 : vec3<f32>;
var<private> p0_nodeVar180 : vec3<f32>;
var<private> p0_nodeVar181 : vec4<f32>;
var<private> p0_nodeVar182 : vec4<f32>;
var<private> p0_nodeVar183 : f32;
var<private> p0_nodeVar184 : f32;
var<private> p0_nodeVar185 : f32;
var<private> p0_nodeVar186 : vec3<f32>;
var<private> p0_nodeVar187 : vec3<f32>;
var<private> p0_nodeVar188 : vec3<f32>;
var<private> p0_nodeVar189 : vec3<f32>;
var<private> p0_nodeVar190 : vec3<f32>;
var<private> p0_nodeVar191 : vec3<f32>;
var<private> p0_nodeVar192 : vec3<f32>;
var<private> p0_nodeVar193 : vec3<f32>;
var<private> p0_nodeVar194 : vec3<f32>;
var<private> p0_nodeVar195 : vec3<f32>;
var<private> p0_nodeVar196 : vec4<f32>;
var<private> p0_nodeVar197 : vec4<f32>;
var<private> p0_nodeVar198 : vec4<f32>;
var<private> p0_nodeVar199 : vec4<f32>;
var<private> p0_nodeVar200 : f32;
var<private> p0_nodeVar201 : vec3<f32>;
var<private> p0_nodeVar202 : vec4<f32>;
var<private> p0_nodeVar203 : vec4<f32>;
var<private> p0_nodeVar204 : vec4<f32>;
var<private> p0_nodeVar205 : vec4<f32>;
var<private> p0_nodeVar206 : vec4<f32>;
var<private> p0_nodeVar207 : vec4<f32>;
var<private> p0_nodeVar208 : vec4<f32>;
var<private> p0_nodeVar209 : vec4<f32>;
var<private> p0_nodeVar210 : vec4<f32>;
var<private> p0_nodeVar211 : vec4<f32>;
var<private> p0_nodeVar212 : vec4<f32>;
var<private> p0_nodeVar213 : vec3<f32>;
var<private> p0_nodeVar214 : vec3<f32>;
var<private> p0_nodeVar215 : vec3<f32>;
var<private> p0_nodeVar216 : vec3<f32>;
var<private> p0_nodeVar217 : vec4<f32>;
var<private> p0_nodeVar218 : vec4<f32>;
var<private> p0_nodeVar219 : f32;
var<private> p0_nodeVar220 : vec4<f32>;
var<private> p0_nodeVar221 : vec4<f32>;
var<private> p0_nodeVar222 : f32;
var<private> p0_nodeVar223 : vec4<f32>;
var<private> p0_nodeVar224 : vec3<f32>;
var<private> p0_nodeVar225 : f32;
var<private> p0_nodeVar226 : vec3<f32>;
var<private> p0_nodeVar227 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar228 : vec4<f32>;

// codes
fn p0_tsl_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }
fn p0_tsl_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = ( f32(knobs.angle) * 0.017453292519943295 );
	p0_nodeVar3 = sin( p0_nodeVar2 );
	p0_nodeVar5 = ( f32(knobs.preset) > 0.5 );

	if ( p0_nodeVar5 ) {

		p0_nodeVar6 = cos( p0_nodeVar2 );
		p0_nodeVar7 = ( ( p0_nodeVar1.x * p0_nodeVar6 ) + ( p0_nodeVar1.y * p0_nodeVar3 ) );
		p0_nodeVar8 = ( ( p0_nodeVar1.x * ( - p0_nodeVar3 ) ) + ( p0_nodeVar1.y * p0_nodeVar6 ) );
		p0_nodeVar9 = vec3<f32>( ( p0_nodeVar7 * 1.35 ), ( p0_nodeVar8 * 1.1 ), 0.17 );
		p0_nodeVar10 = floor( ( p0_nodeVar9 + vec3<f32>( dot( p0_nodeVar9, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar11 = ( ( p0_nodeVar9 - p0_nodeVar10 ) + vec3<f32>( dot( p0_nodeVar10, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar12 = step( p0_nodeVar11.yzx, p0_nodeVar11 );
		p0_nodeVar13 = ( vec3<f32>( 1.0 ) - p0_nodeVar12 );
		p0_nodeVar14 = min( p0_nodeVar12, p0_nodeVar13.zxy );
		p0_nodeVar15 = max( p0_nodeVar12, p0_nodeVar13.zxy );
		p0_nodeVar16 = ( ( p0_nodeVar11 - p0_nodeVar14 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar17 = ( ( p0_nodeVar11 - p0_nodeVar15 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar18 = ( ( p0_nodeVar11 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar10 = p0_tsl_mod_vec3( p0_nodeVar10, vec3<f32>( 289.0 ) );
		p0_nodeVar19 = ( vec4<f32>( p0_nodeVar10.z ) + vec4<f32>( 0.0, p0_nodeVar14.z, p0_nodeVar15.z, 1.0 ) );
		p0_nodeVar20 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar19 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar19 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar10.y ) + vec4<f32>( 0.0, p0_nodeVar14.y, p0_nodeVar15.y, 1.0 ) ) );
		p0_nodeVar21 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar20 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar20 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar10.x ) + vec4<f32>( 0.0, p0_nodeVar14.x, p0_nodeVar15.x, 1.0 ) ) );
		p0_nodeVar22 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar21 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar21 ), vec4<f32>( 289.0 ) );
		p0_nodeVar23 = 0.14285714285714285;
		p0_nodeVar24 = ( ( vec3<f32>( p0_nodeVar23 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar25 = ( p0_nodeVar22 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar22 * vec4<f32>( ( p0_nodeVar24.z * p0_nodeVar24.z ) ) ) ) ) );
		p0_nodeVar26 = ( ( floor( ( p0_nodeVar25 * vec4<f32>( p0_nodeVar24.z ) ) ) * vec4<f32>( p0_nodeVar24.x ) ) + vec4<f32>( p0_nodeVar24, 1.0 ).yyyy );
		p0_nodeVar27 = ( ( floor( ( p0_nodeVar25 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar25 * vec4<f32>( p0_nodeVar24.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar24.x ) ) + vec4<f32>( p0_nodeVar24, 1.0 ).yyyy );
		p0_nodeVar28 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar26 ) - abs( p0_nodeVar27 ) ) );
		p0_nodeVar29 = vec4<f32>( p0_nodeVar26.xy, p0_nodeVar27.xy );
		p0_nodeVar30 = vec4<f32>( p0_nodeVar26.zw, p0_nodeVar27.zw );
		p0_nodeVar31 = ( ( floor( p0_nodeVar29 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar32 = ( ( floor( p0_nodeVar30 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar33 = ( - step( p0_nodeVar28, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar34 = ( p0_nodeVar29.xzyw + ( p0_nodeVar31.xzyw * p0_nodeVar33.xxyy ) );
		p0_nodeVar35 = ( p0_nodeVar30.xzyw + ( p0_nodeVar32.xzyw * p0_nodeVar33.zzww ) );
		p0_nodeVar36 = vec3<f32>( p0_nodeVar34.xy, p0_nodeVar28.x );
		p0_nodeVar37 = vec3<f32>( p0_nodeVar34.zw, p0_nodeVar28.y );
		p0_nodeVar38 = vec3<f32>( p0_nodeVar35.xy, p0_nodeVar28.z );
		p0_nodeVar39 = vec3<f32>( p0_nodeVar35.zw, p0_nodeVar28.w );
		p0_nodeVar40 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar36, p0_nodeVar36 ), dot( p0_nodeVar37, p0_nodeVar37 ), dot( p0_nodeVar38, p0_nodeVar38 ), dot( p0_nodeVar39, p0_nodeVar39 ) ) ) );
		p0_nodeVar36 = ( p0_nodeVar36 * vec3<f32>( p0_nodeVar40.x ) );
		p0_nodeVar37 = ( p0_nodeVar37 * vec3<f32>( p0_nodeVar40.y ) );
		p0_nodeVar38 = ( p0_nodeVar38 * vec3<f32>( p0_nodeVar40.z ) );
		p0_nodeVar39 = ( p0_nodeVar39 * vec3<f32>( p0_nodeVar40.w ) );
		p0_nodeVar41 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar11, p0_nodeVar11 ), dot( p0_nodeVar16, p0_nodeVar16 ), dot( p0_nodeVar17, p0_nodeVar17 ), dot( p0_nodeVar18, p0_nodeVar18 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar41 = ( p0_nodeVar41 * p0_nodeVar41 );
		p0_nodeVar42 = vec3<f32>( ( floor( ( p0_nodeVar7 * f32(knobs.frequency) ) ) * 0.19 ), ( p0_nodeVar8 * 0.45 ), 5.11 );
		p0_nodeVar43 = floor( ( p0_nodeVar42 + vec3<f32>( dot( p0_nodeVar42, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar44 = ( ( p0_nodeVar42 - p0_nodeVar43 ) + vec3<f32>( dot( p0_nodeVar43, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar45 = step( p0_nodeVar44.yzx, p0_nodeVar44 );
		p0_nodeVar46 = ( vec3<f32>( 1.0 ) - p0_nodeVar45 );
		p0_nodeVar47 = min( p0_nodeVar45, p0_nodeVar46.zxy );
		p0_nodeVar48 = max( p0_nodeVar45, p0_nodeVar46.zxy );
		p0_nodeVar49 = ( ( p0_nodeVar44 - p0_nodeVar47 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar50 = ( ( p0_nodeVar44 - p0_nodeVar48 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar51 = ( ( p0_nodeVar44 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar43 = p0_tsl_mod_vec3( p0_nodeVar43, vec3<f32>( 289.0 ) );
		p0_nodeVar52 = ( vec4<f32>( p0_nodeVar43.z ) + vec4<f32>( 0.0, p0_nodeVar47.z, p0_nodeVar48.z, 1.0 ) );
		p0_nodeVar53 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar52 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar52 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar43.y ) + vec4<f32>( 0.0, p0_nodeVar47.y, p0_nodeVar48.y, 1.0 ) ) );
		p0_nodeVar54 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar53 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar53 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar43.x ) + vec4<f32>( 0.0, p0_nodeVar47.x, p0_nodeVar48.x, 1.0 ) ) );
		p0_nodeVar55 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar54 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar54 ), vec4<f32>( 289.0 ) );
		p0_nodeVar56 = 0.14285714285714285;
		p0_nodeVar57 = ( ( vec3<f32>( p0_nodeVar56 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar58 = ( p0_nodeVar55 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar55 * vec4<f32>( ( p0_nodeVar57.z * p0_nodeVar57.z ) ) ) ) ) );
		p0_nodeVar59 = ( ( floor( ( p0_nodeVar58 * vec4<f32>( p0_nodeVar57.z ) ) ) * vec4<f32>( p0_nodeVar57.x ) ) + vec4<f32>( p0_nodeVar57, 1.0 ).yyyy );
		p0_nodeVar60 = ( ( floor( ( p0_nodeVar58 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar58 * vec4<f32>( p0_nodeVar57.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar57.x ) ) + vec4<f32>( p0_nodeVar57, 1.0 ).yyyy );
		p0_nodeVar61 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar59 ) - abs( p0_nodeVar60 ) ) );
		p0_nodeVar62 = vec4<f32>( p0_nodeVar59.xy, p0_nodeVar60.xy );
		p0_nodeVar63 = vec4<f32>( p0_nodeVar59.zw, p0_nodeVar60.zw );
		p0_nodeVar64 = ( ( floor( p0_nodeVar62 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar65 = ( ( floor( p0_nodeVar63 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar66 = ( - step( p0_nodeVar61, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar67 = ( p0_nodeVar62.xzyw + ( p0_nodeVar64.xzyw * p0_nodeVar66.xxyy ) );
		p0_nodeVar68 = ( p0_nodeVar63.xzyw + ( p0_nodeVar65.xzyw * p0_nodeVar66.zzww ) );
		p0_nodeVar69 = vec3<f32>( p0_nodeVar67.xy, p0_nodeVar61.x );
		p0_nodeVar70 = vec3<f32>( p0_nodeVar67.zw, p0_nodeVar61.y );
		p0_nodeVar71 = vec3<f32>( p0_nodeVar68.xy, p0_nodeVar61.z );
		p0_nodeVar72 = vec3<f32>( p0_nodeVar68.zw, p0_nodeVar61.w );
		p0_nodeVar73 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar69, p0_nodeVar69 ), dot( p0_nodeVar70, p0_nodeVar70 ), dot( p0_nodeVar71, p0_nodeVar71 ), dot( p0_nodeVar72, p0_nodeVar72 ) ) ) );
		p0_nodeVar69 = ( p0_nodeVar69 * vec3<f32>( p0_nodeVar73.x ) );
		p0_nodeVar70 = ( p0_nodeVar70 * vec3<f32>( p0_nodeVar73.y ) );
		p0_nodeVar71 = ( p0_nodeVar71 * vec3<f32>( p0_nodeVar73.z ) );
		p0_nodeVar72 = ( p0_nodeVar72 * vec3<f32>( p0_nodeVar73.w ) );
		p0_nodeVar74 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar44, p0_nodeVar44 ), dot( p0_nodeVar49, p0_nodeVar49 ), dot( p0_nodeVar50, p0_nodeVar50 ), dot( p0_nodeVar51, p0_nodeVar51 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar74 = ( p0_nodeVar74 * p0_nodeVar74 );
		p0_nodeVar75 = ( 42.0 * dot( ( p0_nodeVar74 * p0_nodeVar74 ), vec4<f32>( dot( p0_nodeVar69, p0_nodeVar44 ), dot( p0_nodeVar70, p0_nodeVar49 ), dot( p0_nodeVar71, p0_nodeVar50 ), dot( p0_nodeVar72, p0_nodeVar51 ) ) ) );
		p0_nodeVar76 = vec3<f32>( ( ( p0_nodeVar7 * 1.6 ) - 8.2 ), ( ( p0_nodeVar8 * 4.8 ) + 2.7 ), 3.73 );
		p0_nodeVar77 = floor( ( p0_nodeVar76 + vec3<f32>( dot( p0_nodeVar76, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar78 = ( ( p0_nodeVar76 - p0_nodeVar77 ) + vec3<f32>( dot( p0_nodeVar77, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar79 = step( p0_nodeVar78.yzx, p0_nodeVar78 );
		p0_nodeVar80 = ( vec3<f32>( 1.0 ) - p0_nodeVar79 );
		p0_nodeVar81 = min( p0_nodeVar79, p0_nodeVar80.zxy );
		p0_nodeVar82 = max( p0_nodeVar79, p0_nodeVar80.zxy );
		p0_nodeVar83 = ( ( p0_nodeVar78 - p0_nodeVar81 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar84 = ( ( p0_nodeVar78 - p0_nodeVar82 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar85 = ( ( p0_nodeVar78 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar77 = p0_tsl_mod_vec3( p0_nodeVar77, vec3<f32>( 289.0 ) );
		p0_nodeVar86 = ( vec4<f32>( p0_nodeVar77.z ) + vec4<f32>( 0.0, p0_nodeVar81.z, p0_nodeVar82.z, 1.0 ) );
		p0_nodeVar87 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar86 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar86 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar77.y ) + vec4<f32>( 0.0, p0_nodeVar81.y, p0_nodeVar82.y, 1.0 ) ) );
		p0_nodeVar88 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar87 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar87 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar77.x ) + vec4<f32>( 0.0, p0_nodeVar81.x, p0_nodeVar82.x, 1.0 ) ) );
		p0_nodeVar89 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar88 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar88 ), vec4<f32>( 289.0 ) );
		p0_nodeVar90 = 0.14285714285714285;
		p0_nodeVar91 = ( ( vec3<f32>( p0_nodeVar90 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar92 = ( p0_nodeVar89 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar89 * vec4<f32>( ( p0_nodeVar91.z * p0_nodeVar91.z ) ) ) ) ) );
		p0_nodeVar93 = ( ( floor( ( p0_nodeVar92 * vec4<f32>( p0_nodeVar91.z ) ) ) * vec4<f32>( p0_nodeVar91.x ) ) + vec4<f32>( p0_nodeVar91, 1.0 ).yyyy );
		p0_nodeVar94 = ( ( floor( ( p0_nodeVar92 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar92 * vec4<f32>( p0_nodeVar91.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar91.x ) ) + vec4<f32>( p0_nodeVar91, 1.0 ).yyyy );
		p0_nodeVar95 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar93 ) - abs( p0_nodeVar94 ) ) );
		p0_nodeVar96 = vec4<f32>( p0_nodeVar93.xy, p0_nodeVar94.xy );
		p0_nodeVar97 = vec4<f32>( p0_nodeVar93.zw, p0_nodeVar94.zw );
		p0_nodeVar98 = ( ( floor( p0_nodeVar96 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar99 = ( ( floor( p0_nodeVar97 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar100 = ( - step( p0_nodeVar95, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar101 = ( p0_nodeVar96.xzyw + ( p0_nodeVar98.xzyw * p0_nodeVar100.xxyy ) );
		p0_nodeVar102 = ( p0_nodeVar97.xzyw + ( p0_nodeVar99.xzyw * p0_nodeVar100.zzww ) );
		p0_nodeVar103 = vec3<f32>( p0_nodeVar101.xy, p0_nodeVar95.x );
		p0_nodeVar104 = vec3<f32>( p0_nodeVar101.zw, p0_nodeVar95.y );
		p0_nodeVar105 = vec3<f32>( p0_nodeVar102.xy, p0_nodeVar95.z );
		p0_nodeVar106 = vec3<f32>( p0_nodeVar102.zw, p0_nodeVar95.w );
		p0_nodeVar107 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar103, p0_nodeVar103 ), dot( p0_nodeVar104, p0_nodeVar104 ), dot( p0_nodeVar105, p0_nodeVar105 ), dot( p0_nodeVar106, p0_nodeVar106 ) ) ) );
		p0_nodeVar103 = ( p0_nodeVar103 * vec3<f32>( p0_nodeVar107.x ) );
		p0_nodeVar104 = ( p0_nodeVar104 * vec3<f32>( p0_nodeVar107.y ) );
		p0_nodeVar105 = ( p0_nodeVar105 * vec3<f32>( p0_nodeVar107.z ) );
		p0_nodeVar106 = ( p0_nodeVar106 * vec3<f32>( p0_nodeVar107.w ) );
		p0_nodeVar108 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar78, p0_nodeVar78 ), dot( p0_nodeVar83, p0_nodeVar83 ), dot( p0_nodeVar84, p0_nodeVar84 ), dot( p0_nodeVar85, p0_nodeVar85 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar108 = ( p0_nodeVar108 * p0_nodeVar108 );
		p0_nodeVar109 = ( 42.0 * dot( ( p0_nodeVar108 * p0_nodeVar108 ), vec4<f32>( dot( p0_nodeVar103, p0_nodeVar78 ), dot( p0_nodeVar104, p0_nodeVar83 ), dot( p0_nodeVar105, p0_nodeVar84 ), dot( p0_nodeVar106, p0_nodeVar85 ) ) ) );
		p0_nodeVar110 = ( ( fract( ( ( ( ( ( p0_nodeVar7 + ( ( ( 42.0 * dot( ( p0_nodeVar41 * p0_nodeVar41 ), vec4<f32>( dot( p0_nodeVar36, p0_nodeVar11 ), dot( p0_nodeVar37, p0_nodeVar16 ), dot( p0_nodeVar38, p0_nodeVar17 ), dot( p0_nodeVar39, p0_nodeVar18 ) ) ) ) * f32(knobs.irregularity) ) * 0.055 ) ) + ( ( p0_nodeVar75 * f32(knobs.irregularity) ) * 0.045 ) ) + ( ( p0_nodeVar109 * f32(knobs.warp) ) * 0.02 ) ) * f32(knobs.frequency) ) + ( ( p0_nodeVar75 * f32(knobs.irregularity) ) * 0.85 ) ) ) * 2.0 ) - 1.0 );
		p0_nodeVar111 = max( 0.0, ( 1.0 - ( p0_nodeVar110 * p0_nodeVar110 ) ) );
		p0_nodeVar112 = abs( p0_nodeVar110 );
		p0_nodeVar113 = ( smoothstep( 0.08, 0.52, p0_nodeVar112 ) * ( 1.0 - smoothstep( 0.62, 0.98, p0_nodeVar112 ) ) );
		p0_nodeVar114 = vec3<f32>( ( ( p0_nodeVar7 * 3.9 ) + 11.7 ), ( ( p0_nodeVar8 * 2.4 ) - 4.3 ), 1.91 );
		p0_nodeVar115 = floor( ( p0_nodeVar114 + vec3<f32>( dot( p0_nodeVar114, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar116 = ( ( p0_nodeVar114 - p0_nodeVar115 ) + vec3<f32>( dot( p0_nodeVar115, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar117 = step( p0_nodeVar116.yzx, p0_nodeVar116 );
		p0_nodeVar118 = ( vec3<f32>( 1.0 ) - p0_nodeVar117 );
		p0_nodeVar119 = min( p0_nodeVar117, p0_nodeVar118.zxy );
		p0_nodeVar120 = max( p0_nodeVar117, p0_nodeVar118.zxy );
		p0_nodeVar121 = ( ( p0_nodeVar116 - p0_nodeVar119 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar122 = ( ( p0_nodeVar116 - p0_nodeVar120 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar123 = ( ( p0_nodeVar116 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar115 = p0_tsl_mod_vec3( p0_nodeVar115, vec3<f32>( 289.0 ) );
		p0_nodeVar124 = ( vec4<f32>( p0_nodeVar115.z ) + vec4<f32>( 0.0, p0_nodeVar119.z, p0_nodeVar120.z, 1.0 ) );
		p0_nodeVar125 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar124 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar124 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar115.y ) + vec4<f32>( 0.0, p0_nodeVar119.y, p0_nodeVar120.y, 1.0 ) ) );
		p0_nodeVar126 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar125 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar125 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar115.x ) + vec4<f32>( 0.0, p0_nodeVar119.x, p0_nodeVar120.x, 1.0 ) ) );
		p0_nodeVar127 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar126 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar126 ), vec4<f32>( 289.0 ) );
		p0_nodeVar128 = 0.14285714285714285;
		p0_nodeVar129 = ( ( vec3<f32>( p0_nodeVar128 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar130 = ( p0_nodeVar127 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar127 * vec4<f32>( ( p0_nodeVar129.z * p0_nodeVar129.z ) ) ) ) ) );
		p0_nodeVar131 = ( ( floor( ( p0_nodeVar130 * vec4<f32>( p0_nodeVar129.z ) ) ) * vec4<f32>( p0_nodeVar129.x ) ) + vec4<f32>( p0_nodeVar129, 1.0 ).yyyy );
		p0_nodeVar132 = ( ( floor( ( p0_nodeVar130 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar130 * vec4<f32>( p0_nodeVar129.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar129.x ) ) + vec4<f32>( p0_nodeVar129, 1.0 ).yyyy );
		p0_nodeVar133 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar131 ) - abs( p0_nodeVar132 ) ) );
		p0_nodeVar134 = vec4<f32>( p0_nodeVar131.xy, p0_nodeVar132.xy );
		p0_nodeVar135 = vec4<f32>( p0_nodeVar131.zw, p0_nodeVar132.zw );
		p0_nodeVar136 = ( ( floor( p0_nodeVar134 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar137 = ( ( floor( p0_nodeVar135 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar138 = ( - step( p0_nodeVar133, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar139 = ( p0_nodeVar134.xzyw + ( p0_nodeVar136.xzyw * p0_nodeVar138.xxyy ) );
		p0_nodeVar140 = ( p0_nodeVar135.xzyw + ( p0_nodeVar137.xzyw * p0_nodeVar138.zzww ) );
		p0_nodeVar141 = vec3<f32>( p0_nodeVar139.xy, p0_nodeVar133.x );
		p0_nodeVar142 = vec3<f32>( p0_nodeVar139.zw, p0_nodeVar133.y );
		p0_nodeVar143 = vec3<f32>( p0_nodeVar140.xy, p0_nodeVar133.z );
		p0_nodeVar144 = vec3<f32>( p0_nodeVar140.zw, p0_nodeVar133.w );
		p0_nodeVar145 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar141, p0_nodeVar141 ), dot( p0_nodeVar142, p0_nodeVar142 ), dot( p0_nodeVar143, p0_nodeVar143 ), dot( p0_nodeVar144, p0_nodeVar144 ) ) ) );
		p0_nodeVar141 = ( p0_nodeVar141 * vec3<f32>( p0_nodeVar145.x ) );
		p0_nodeVar142 = ( p0_nodeVar142 * vec3<f32>( p0_nodeVar145.y ) );
		p0_nodeVar143 = ( p0_nodeVar143 * vec3<f32>( p0_nodeVar145.z ) );
		p0_nodeVar144 = ( p0_nodeVar144 * vec3<f32>( p0_nodeVar145.w ) );
		p0_nodeVar146 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar116, p0_nodeVar116 ), dot( p0_nodeVar121, p0_nodeVar121 ), dot( p0_nodeVar122, p0_nodeVar122 ), dot( p0_nodeVar123, p0_nodeVar123 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar146 = ( p0_nodeVar146 * p0_nodeVar146 );
		p0_nodeVar147 = ( 42.0 * dot( ( p0_nodeVar146 * p0_nodeVar146 ), vec4<f32>( dot( p0_nodeVar141, p0_nodeVar116 ), dot( p0_nodeVar142, p0_nodeVar121 ), dot( p0_nodeVar143, p0_nodeVar122 ), dot( p0_nodeVar144, p0_nodeVar123 ) ) ) );
		p0_nodeVar4 = ( ( p0_nodeVar110 * ( ( ( p0_nodeVar111 * 0.38 ) + ( p0_nodeVar113 * 0.84 ) ) * ( 1.0 + ( ( p0_nodeVar147 * f32(knobs.warp) ) * 0.35 ) ) ) ) + ( ( ( ( p0_nodeVar147 * f32(knobs.warp) ) * p0_nodeVar111 ) * 0.55 ) + ( ( ( p0_nodeVar109 * f32(knobs.irregularity) ) * p0_nodeVar113 ) * 0.24 ) ) );

	} else {

		p0_nodeVar148 = cos( p0_nodeVar2 );
		p0_nodeVar149 = ( ( p0_nodeVar1.x * p0_nodeVar148 ) + ( p0_nodeVar1.y * p0_nodeVar3 ) );
		p0_nodeVar150 = vec3<f32>( ( p0_nodeVar149 * 1.35 ), ( ( ( p0_nodeVar1.x * ( - p0_nodeVar3 ) ) + ( p0_nodeVar1.y * p0_nodeVar148 ) ) * 1.1 ), 0.17 );
		p0_nodeVar151 = floor( ( p0_nodeVar150 + vec3<f32>( dot( p0_nodeVar150, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
		p0_nodeVar152 = ( ( p0_nodeVar150 - p0_nodeVar151 ) + vec3<f32>( dot( p0_nodeVar151, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
		p0_nodeVar153 = step( p0_nodeVar152.yzx, p0_nodeVar152 );
		p0_nodeVar154 = ( vec3<f32>( 1.0 ) - p0_nodeVar153 );
		p0_nodeVar155 = min( p0_nodeVar153, p0_nodeVar154.zxy );
		p0_nodeVar156 = max( p0_nodeVar153, p0_nodeVar154.zxy );
		p0_nodeVar157 = ( ( p0_nodeVar152 - p0_nodeVar155 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar158 = ( ( p0_nodeVar152 - p0_nodeVar156 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar159 = ( ( p0_nodeVar152 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
		p0_nodeVar151 = p0_tsl_mod_vec3( p0_nodeVar151, vec3<f32>( 289.0 ) );
		p0_nodeVar160 = ( vec4<f32>( p0_nodeVar151.z ) + vec4<f32>( 0.0, p0_nodeVar155.z, p0_nodeVar156.z, 1.0 ) );
		p0_nodeVar161 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar160 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar160 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar151.y ) + vec4<f32>( 0.0, p0_nodeVar155.y, p0_nodeVar156.y, 1.0 ) ) );
		p0_nodeVar162 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar161 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar161 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar151.x ) + vec4<f32>( 0.0, p0_nodeVar155.x, p0_nodeVar156.x, 1.0 ) ) );
		p0_nodeVar163 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar162 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar162 ), vec4<f32>( 289.0 ) );
		p0_nodeVar164 = 0.14285714285714285;
		p0_nodeVar165 = ( ( vec3<f32>( p0_nodeVar164 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
		p0_nodeVar166 = ( p0_nodeVar163 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar163 * vec4<f32>( ( p0_nodeVar165.z * p0_nodeVar165.z ) ) ) ) ) );
		p0_nodeVar167 = ( ( floor( ( p0_nodeVar166 * vec4<f32>( p0_nodeVar165.z ) ) ) * vec4<f32>( p0_nodeVar165.x ) ) + vec4<f32>( p0_nodeVar165, 1.0 ).yyyy );
		p0_nodeVar168 = ( ( floor( ( p0_nodeVar166 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar166 * vec4<f32>( p0_nodeVar165.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar165.x ) ) + vec4<f32>( p0_nodeVar165, 1.0 ).yyyy );
		p0_nodeVar169 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar167 ) - abs( p0_nodeVar168 ) ) );
		p0_nodeVar170 = vec4<f32>( p0_nodeVar167.xy, p0_nodeVar168.xy );
		p0_nodeVar171 = vec4<f32>( p0_nodeVar167.zw, p0_nodeVar168.zw );
		p0_nodeVar172 = ( ( floor( p0_nodeVar170 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar173 = ( ( floor( p0_nodeVar171 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
		p0_nodeVar174 = ( - step( p0_nodeVar169, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
		p0_nodeVar175 = ( p0_nodeVar170.xzyw + ( p0_nodeVar172.xzyw * p0_nodeVar174.xxyy ) );
		p0_nodeVar176 = ( p0_nodeVar171.xzyw + ( p0_nodeVar173.xzyw * p0_nodeVar174.zzww ) );
		p0_nodeVar177 = vec3<f32>( p0_nodeVar175.xy, p0_nodeVar169.x );
		p0_nodeVar178 = vec3<f32>( p0_nodeVar175.zw, p0_nodeVar169.y );
		p0_nodeVar179 = vec3<f32>( p0_nodeVar176.xy, p0_nodeVar169.z );
		p0_nodeVar180 = vec3<f32>( p0_nodeVar176.zw, p0_nodeVar169.w );
		p0_nodeVar181 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar177, p0_nodeVar177 ), dot( p0_nodeVar178, p0_nodeVar178 ), dot( p0_nodeVar179, p0_nodeVar179 ), dot( p0_nodeVar180, p0_nodeVar180 ) ) ) );
		p0_nodeVar177 = ( p0_nodeVar177 * vec3<f32>( p0_nodeVar181.x ) );
		p0_nodeVar178 = ( p0_nodeVar178 * vec3<f32>( p0_nodeVar181.y ) );
		p0_nodeVar179 = ( p0_nodeVar179 * vec3<f32>( p0_nodeVar181.z ) );
		p0_nodeVar180 = ( p0_nodeVar180 * vec3<f32>( p0_nodeVar181.w ) );
		p0_nodeVar182 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar152, p0_nodeVar152 ), dot( p0_nodeVar157, p0_nodeVar157 ), dot( p0_nodeVar158, p0_nodeVar158 ), dot( p0_nodeVar159, p0_nodeVar159 ) ) ), vec4<f32>( 0.0 ) );
		p0_nodeVar182 = ( p0_nodeVar182 * p0_nodeVar182 );
		p0_nodeVar183 = ( ( fract( ( ( p0_nodeVar149 + ( ( ( 42.0 * dot( ( p0_nodeVar182 * p0_nodeVar182 ), vec4<f32>( dot( p0_nodeVar177, p0_nodeVar152 ), dot( p0_nodeVar178, p0_nodeVar157 ), dot( p0_nodeVar179, p0_nodeVar158 ), dot( p0_nodeVar180, p0_nodeVar159 ) ) ) ) * f32(knobs.irregularity) ) * 0.028 ) ) * f32(knobs.frequency) ) ) * 2.0 ) - 1.0 );
		p0_nodeVar4 = ( p0_nodeVar183 * ( ( pow( max( 0.0, ( 1.0 - ( p0_nodeVar183 * p0_nodeVar183 ) ) ), 1.08 ) * 0.7 ) * ( 1.0 - ( ( abs( p0_nodeVar183 ) * f32(knobs.irregularity) ) * 0.18 ) ) ) );

	}


	if ( p0_nodeVar5 ) {

		p0_nodeVar184 = 2.7;

	} else {

		p0_nodeVar184 = 1.7;

	}

	p0_nodeVar185 = cos( p0_nodeVar2 );
	p0_nodeVar186 = vec3<f32>( ( ( ( ( p0_nodeVar1.x * p0_nodeVar185 ) + ( p0_nodeVar1.y * p0_nodeVar3 ) ) * 1.6 ) - 8.2 ), ( ( ( ( p0_nodeVar1.x * ( - p0_nodeVar3 ) ) + ( p0_nodeVar1.y * p0_nodeVar185 ) ) * 4.8 ) + 2.7 ), 3.73 );
	p0_nodeVar187 = floor( ( p0_nodeVar186 + vec3<f32>( dot( p0_nodeVar186, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).yyy ) ) ) );
	p0_nodeVar188 = ( ( p0_nodeVar186 - p0_nodeVar187 ) + vec3<f32>( dot( p0_nodeVar187, vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) ) );
	p0_nodeVar189 = step( p0_nodeVar188.yzx, p0_nodeVar188 );
	p0_nodeVar190 = ( vec3<f32>( 1.0 ) - p0_nodeVar189 );
	p0_nodeVar191 = min( p0_nodeVar189, p0_nodeVar190.zxy );
	p0_nodeVar192 = max( p0_nodeVar189, p0_nodeVar190.zxy );
	p0_nodeVar193 = ( ( p0_nodeVar188 - p0_nodeVar191 ) + ( vec3<f32>( 1.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar194 = ( ( p0_nodeVar188 - p0_nodeVar192 ) + ( vec3<f32>( 2.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar195 = ( ( p0_nodeVar188 - vec3<f32>( 1.0 ) ) + ( vec3<f32>( 3.0 ) * vec3<f32>( vec2<f32>( 0.16666666666666666, 0.3333333333333333 ), 0.0 ).xxx ) );
	p0_nodeVar187 = p0_tsl_mod_vec3( p0_nodeVar187, vec3<f32>( 289.0 ) );
	p0_nodeVar196 = ( vec4<f32>( p0_nodeVar187.z ) + vec4<f32>( 0.0, p0_nodeVar191.z, p0_nodeVar192.z, 1.0 ) );
	p0_nodeVar197 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar196 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar196 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar187.y ) + vec4<f32>( 0.0, p0_nodeVar191.y, p0_nodeVar192.y, 1.0 ) ) );
	p0_nodeVar198 = ( p0_tsl_mod_vec4( ( ( ( p0_nodeVar197 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar197 ), vec4<f32>( 289.0 ) ) + ( vec4<f32>( p0_nodeVar187.x ) + vec4<f32>( 0.0, p0_nodeVar191.x, p0_nodeVar192.x, 1.0 ) ) );
	p0_nodeVar199 = p0_tsl_mod_vec4( ( ( ( p0_nodeVar198 * vec4<f32>( 34.0 ) ) + vec4<f32>( 10.0 ) ) * p0_nodeVar198 ), vec4<f32>( 289.0 ) );
	p0_nodeVar200 = 0.14285714285714285;
	p0_nodeVar201 = ( ( vec3<f32>( p0_nodeVar200 ) * vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).wyz ) - vec4<f32>( 0.0, 0.5, 1.0, 2.0 ).xzx );
	p0_nodeVar202 = ( p0_nodeVar199 - ( vec4<f32>( 49.0 ) * floor( ( p0_nodeVar199 * vec4<f32>( ( p0_nodeVar201.z * p0_nodeVar201.z ) ) ) ) ) );
	p0_nodeVar203 = ( ( floor( ( p0_nodeVar202 * vec4<f32>( p0_nodeVar201.z ) ) ) * vec4<f32>( p0_nodeVar201.x ) ) + vec4<f32>( p0_nodeVar201, 1.0 ).yyyy );
	p0_nodeVar204 = ( ( floor( ( p0_nodeVar202 - ( vec4<f32>( 7.0 ) * floor( ( p0_nodeVar202 * vec4<f32>( p0_nodeVar201.z ) ) ) ) ) ) * vec4<f32>( p0_nodeVar201.x ) ) + vec4<f32>( p0_nodeVar201, 1.0 ).yyyy );
	p0_nodeVar205 = ( vec4<f32>( 1.0 ) - ( abs( p0_nodeVar203 ) - abs( p0_nodeVar204 ) ) );
	p0_nodeVar206 = vec4<f32>( p0_nodeVar203.xy, p0_nodeVar204.xy );
	p0_nodeVar207 = vec4<f32>( p0_nodeVar203.zw, p0_nodeVar204.zw );
	p0_nodeVar208 = ( ( floor( p0_nodeVar206 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar209 = ( ( floor( p0_nodeVar207 ) * vec4<f32>( 2.0 ) ) + vec4<f32>( 1.0 ) );
	p0_nodeVar210 = ( - step( p0_nodeVar205, vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) ) );
	p0_nodeVar211 = ( p0_nodeVar206.xzyw + ( p0_nodeVar208.xzyw * p0_nodeVar210.xxyy ) );
	p0_nodeVar212 = ( p0_nodeVar207.xzyw + ( p0_nodeVar209.xzyw * p0_nodeVar210.zzww ) );
	p0_nodeVar213 = vec3<f32>( p0_nodeVar211.xy, p0_nodeVar205.x );
	p0_nodeVar214 = vec3<f32>( p0_nodeVar211.zw, p0_nodeVar205.y );
	p0_nodeVar215 = vec3<f32>( p0_nodeVar212.xy, p0_nodeVar205.z );
	p0_nodeVar216 = vec3<f32>( p0_nodeVar212.zw, p0_nodeVar205.w );
	p0_nodeVar217 = ( vec4<f32>( 1.79284291400159 ) - ( vec4<f32>( 0.85373472095314 ) * vec4<f32>( dot( p0_nodeVar213, p0_nodeVar213 ), dot( p0_nodeVar214, p0_nodeVar214 ), dot( p0_nodeVar215, p0_nodeVar215 ), dot( p0_nodeVar216, p0_nodeVar216 ) ) ) );
	p0_nodeVar213 = ( p0_nodeVar213 * vec3<f32>( p0_nodeVar217.x ) );
	p0_nodeVar214 = ( p0_nodeVar214 * vec3<f32>( p0_nodeVar217.y ) );
	p0_nodeVar215 = ( p0_nodeVar215 * vec3<f32>( p0_nodeVar217.z ) );
	p0_nodeVar216 = ( p0_nodeVar216 * vec3<f32>( p0_nodeVar217.w ) );
	p0_nodeVar218 = max( ( vec4<f32>( 0.6 ) - vec4<f32>( dot( p0_nodeVar188, p0_nodeVar188 ), dot( p0_nodeVar193, p0_nodeVar193 ), dot( p0_nodeVar194, p0_nodeVar194 ), dot( p0_nodeVar195, p0_nodeVar195 ) ) ), vec4<f32>( 0.0 ) );
	p0_nodeVar218 = ( p0_nodeVar218 * p0_nodeVar218 );
	p0_nodeVar219 = ( ( p0_nodeVar4 * ( f32(knobs.amplitude) * p0_nodeVar184 ) ) + ( ( ( ( 42.0 * dot( ( p0_nodeVar218 * p0_nodeVar218 ), vec4<f32>( dot( p0_nodeVar213, p0_nodeVar188 ), dot( p0_nodeVar214, p0_nodeVar193 ), dot( p0_nodeVar215, p0_nodeVar194 ), dot( p0_nodeVar216, p0_nodeVar195 ) ) ) ) * f32(knobs.warp) ) * f32(knobs.amplitude) ) * 0.22 ) );
	p0_nodeVar220 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( - p0_nodeVar3 ) * p0_nodeVar219 ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( p0_nodeVar185 * p0_nodeVar219 ) ), 0.0, 1.0 ) ) );
	p0_nodeVar221 = picture_read( p0_nodeVar1 );

	if ( p0_nodeVar5 ) {

		p0_nodeVar222 = 0.08;

	} else {

		p0_nodeVar222 = 0.14;

	}

	p0_nodeVar223 = vec4<f32>( clamp( mix( vec3<f32>( p0_nodeVar220.x, p0_nodeVar220.y, p0_nodeVar220.z ), vec3<f32>( p0_nodeVar221.x, p0_nodeVar221.y, p0_nodeVar221.z ), ( p0_nodeVar222 * ( 1.0 - clamp( ( f32(knobs.amplitude) * 8.0 ), 0.0, 0.85 ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p0_nodeVar224 = vec3<f32>( p0_nodeVar223.x, p0_nodeVar223.y, p0_nodeVar223.z );
	p0_nodeVar225 = ( ( ( p0_nodeVar224.x * 0.2126 ) + ( p0_nodeVar224.y * 0.7152 ) ) + ( p0_nodeVar224.z * 0.0722 ) );
	p0_nodeVar226 = mix( vec3<f32>( p0_nodeVar225, p0_nodeVar225, p0_nodeVar225 ), p0_nodeVar224, f32(1.0) );
	p0_nodeVar227 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar226.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar226.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar226.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar226.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar226.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar226.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar226.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar226.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar226.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar223.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar227.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar227.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar228 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar228;

	// result

	p0_output.color = p0_nodeVar228;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

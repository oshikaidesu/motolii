// Crater noise: threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions), by three.js's own builder (engine/tsl/noise_fx_shelf.ts)
// --label:Generate
// --track@scale:Scale,0,24,6,0.1
// --track@pace:Pace,0,4,1,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  pace: f32,
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
var<private> p0_nodeVar0 : f32;
var<private> p0_nodeVar1 : f32;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : u32;
var<private> p0_nodeVar8 : u32;
var<private> p0_nodeVar9 : u32;
var<private> p0_nodeVar10 : u32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : vec2<f32>;
var<private> p0_nodeVar14 : u32;
var<private> p0_nodeVar15 : u32;
var<private> p0_nodeVar16 : u32;
var<private> p0_nodeVar17 : u32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec2<f32>;
var<private> p0_nodeVar21 : u32;
var<private> p0_nodeVar22 : u32;
var<private> p0_nodeVar23 : u32;
var<private> p0_nodeVar24 : u32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : vec2<f32>;
var<private> p0_nodeVar28 : u32;
var<private> p0_nodeVar29 : u32;
var<private> p0_nodeVar30 : u32;
var<private> p0_nodeVar31 : u32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : vec2<f32>;
var<private> p0_nodeVar35 : u32;
var<private> p0_nodeVar36 : u32;
var<private> p0_nodeVar37 : u32;
var<private> p0_nodeVar38 : u32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : u32;
var<private> p0_nodeVar43 : u32;
var<private> p0_nodeVar44 : u32;
var<private> p0_nodeVar45 : u32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec2<f32>;
var<private> p0_nodeVar49 : u32;
var<private> p0_nodeVar50 : u32;
var<private> p0_nodeVar51 : u32;
var<private> p0_nodeVar52 : u32;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : vec2<f32>;
var<private> p0_nodeVar56 : u32;
var<private> p0_nodeVar57 : u32;
var<private> p0_nodeVar58 : u32;
var<private> p0_nodeVar59 : u32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : vec2<f32>;
var<private> p0_nodeVar63 : u32;
var<private> p0_nodeVar64 : u32;
var<private> p0_nodeVar65 : u32;
var<private> p0_nodeVar66 : u32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : vec2<f32>;
var<private> p0_nodeVar70 : u32;
var<private> p0_nodeVar71 : u32;
var<private> p0_nodeVar72 : u32;
var<private> p0_nodeVar73 : u32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : vec2<f32>;
var<private> p0_nodeVar77 : u32;
var<private> p0_nodeVar78 : u32;
var<private> p0_nodeVar79 : u32;
var<private> p0_nodeVar80 : u32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : vec2<f32>;
var<private> p0_nodeVar84 : u32;
var<private> p0_nodeVar85 : u32;
var<private> p0_nodeVar86 : u32;
var<private> p0_nodeVar87 : u32;
var<private> p0_nodeVar88 : f32;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : vec2<f32>;
var<private> p0_nodeVar91 : u32;
var<private> p0_nodeVar92 : u32;
var<private> p0_nodeVar93 : u32;
var<private> p0_nodeVar94 : u32;
var<private> p0_nodeVar95 : f32;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : vec2<f32>;
var<private> p0_nodeVar98 : u32;
var<private> p0_nodeVar99 : u32;
var<private> p0_nodeVar100 : u32;
var<private> p0_nodeVar101 : u32;
var<private> p0_nodeVar102 : f32;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : vec2<f32>;
var<private> p0_nodeVar105 : u32;
var<private> p0_nodeVar106 : u32;
var<private> p0_nodeVar107 : u32;
var<private> p0_nodeVar108 : u32;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : vec2<f32>;
var<private> p0_nodeVar112 : u32;
var<private> p0_nodeVar113 : u32;
var<private> p0_nodeVar114 : u32;
var<private> p0_nodeVar115 : u32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : vec2<f32>;
var<private> p0_nodeVar119 : u32;
var<private> p0_nodeVar120 : u32;
var<private> p0_nodeVar121 : u32;
var<private> p0_nodeVar122 : u32;
var<private> p0_nodeVar123 : f32;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : vec2<f32>;
var<private> p0_nodeVar126 : u32;
var<private> p0_nodeVar127 : u32;
var<private> p0_nodeVar128 : u32;
var<private> p0_nodeVar129 : u32;
var<private> p0_nodeVar130 : f32;
var<private> p0_nodeVar131 : f32;
var<private> p0_nodeVar132 : vec2<f32>;
var<private> p0_nodeVar133 : u32;
var<private> p0_nodeVar134 : u32;
var<private> p0_nodeVar135 : u32;
var<private> p0_nodeVar136 : u32;
var<private> p0_nodeVar137 : f32;
var<private> p0_nodeVar138 : f32;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : u32;
var<private> p0_nodeVar141 : u32;
var<private> p0_nodeVar142 : u32;
var<private> p0_nodeVar143 : u32;
var<private> p0_nodeVar144 : f32;
var<private> p0_nodeVar145 : f32;
var<private> p0_nodeVar146 : vec2<f32>;
var<private> p0_nodeVar147 : u32;
var<private> p0_nodeVar148 : u32;
var<private> p0_nodeVar149 : u32;
var<private> p0_nodeVar150 : u32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : vec2<f32>;
var<private> p0_nodeVar154 : u32;
var<private> p0_nodeVar155 : u32;
var<private> p0_nodeVar156 : u32;
var<private> p0_nodeVar157 : u32;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : vec2<f32>;
var<private> p0_nodeVar161 : u32;
var<private> p0_nodeVar162 : u32;
var<private> p0_nodeVar163 : u32;
var<private> p0_nodeVar164 : u32;
var<private> p0_nodeVar165 : f32;
var<private> p0_nodeVar166 : f32;
var<private> p0_nodeVar167 : vec2<f32>;
var<private> p0_nodeVar168 : u32;
var<private> p0_nodeVar169 : u32;
var<private> p0_nodeVar170 : u32;
var<private> p0_nodeVar171 : u32;
var<private> p0_nodeVar172 : f32;
var<private> p0_nodeVar173 : f32;
var<private> p0_nodeVar174 : vec2<f32>;
var<private> p0_nodeVar175 : u32;
var<private> p0_nodeVar176 : u32;
var<private> p0_nodeVar177 : u32;
var<private> p0_nodeVar178 : u32;
var<private> p0_nodeVar179 : f32;
var<private> p0_nodeVar180 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar181 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_nodeVar0 = 0.0;
	p0_nodeVar1 = 0.0;
	p0_nodeVar2 = ( ( ( nodeVarying4.xy + vec2<f32>( 3.0 ) ) * vec2<f32>( ( f32(knobs.scale) / 2.0 ) ) ) + vec2<f32>( ( sin( ( f32(knobs.time) * f32(knobs.pace) ) ) + 1.0 ) ) );
	p0_nodeVar3 = fract( p0_nodeVar2 );
	p0_nodeVar4 = floor( p0_nodeVar2 );
	p0_nodeVar5 = ( p0_nodeVar4 - ( floor( ( p0_nodeVar4 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) );
	p0_nodeVar6 = ( p0_nodeVar5 + vec2<f32>( -2.0, -2.0 ) );
	p0_nodeVar7 = ( ( vec2<u32>( floor( ( p0_nodeVar6 - ( floor( ( p0_nodeVar6 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar6 - ( floor( ( p0_nodeVar6 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar8 = ( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 16u ) ) * 2146121005u );
	p0_nodeVar9 = ( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 15u ) ) * 2221713035u );
	p0_nodeVar10 = ( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 13u ) ) * 2654435769u );
	p0_nodeVar11 = distance( ( p0_nodeVar3 - vec2<f32>( -2.0, -2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar9 ^ ( p0_nodeVar9 >> 16u ) ) ), f32( ( p0_nodeVar10 ^ ( p0_nodeVar10 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar12 = exp( ( -4.0 * p0_nodeVar11 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar12 * sin( ( 6.28 * sqrt( max( p0_nodeVar11, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar12 );
	p0_nodeVar13 = ( p0_nodeVar5 + vec2<f32>( -2.0, -1.0 ) );
	p0_nodeVar14 = ( ( vec2<u32>( floor( ( p0_nodeVar13 - ( floor( ( p0_nodeVar13 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar13 - ( floor( ( p0_nodeVar13 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar15 = ( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 16u ) ) * 2146121005u );
	p0_nodeVar16 = ( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 15u ) ) * 2221713035u );
	p0_nodeVar17 = ( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 13u ) ) * 2654435769u );
	p0_nodeVar18 = distance( ( p0_nodeVar3 - vec2<f32>( -2.0, -1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 16u ) ) ), f32( ( p0_nodeVar17 ^ ( p0_nodeVar17 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar19 = exp( ( -4.0 * p0_nodeVar18 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar19 * sin( ( 6.28 * sqrt( max( p0_nodeVar18, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar19 );
	p0_nodeVar20 = ( p0_nodeVar5 + vec2<f32>( -2.0, 0.0 ) );
	p0_nodeVar21 = ( ( vec2<u32>( floor( ( p0_nodeVar20 - ( floor( ( p0_nodeVar20 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar20 - ( floor( ( p0_nodeVar20 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar22 = ( ( p0_nodeVar21 ^ ( p0_nodeVar21 >> 16u ) ) * 2146121005u );
	p0_nodeVar23 = ( ( p0_nodeVar22 ^ ( p0_nodeVar22 >> 15u ) ) * 2221713035u );
	p0_nodeVar24 = ( ( p0_nodeVar22 ^ ( p0_nodeVar22 >> 13u ) ) * 2654435769u );
	p0_nodeVar25 = distance( ( p0_nodeVar3 - vec2<f32>( -2.0, 0.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar23 ^ ( p0_nodeVar23 >> 16u ) ) ), f32( ( p0_nodeVar24 ^ ( p0_nodeVar24 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar26 = exp( ( -4.0 * p0_nodeVar25 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar26 * sin( ( 6.28 * sqrt( max( p0_nodeVar25, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar26 );
	p0_nodeVar27 = ( p0_nodeVar5 + vec2<f32>( -2.0, 1.0 ) );
	p0_nodeVar28 = ( ( vec2<u32>( floor( ( p0_nodeVar27 - ( floor( ( p0_nodeVar27 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar27 - ( floor( ( p0_nodeVar27 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar29 = ( ( p0_nodeVar28 ^ ( p0_nodeVar28 >> 16u ) ) * 2146121005u );
	p0_nodeVar30 = ( ( p0_nodeVar29 ^ ( p0_nodeVar29 >> 15u ) ) * 2221713035u );
	p0_nodeVar31 = ( ( p0_nodeVar29 ^ ( p0_nodeVar29 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = distance( ( p0_nodeVar3 - vec2<f32>( -2.0, 1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar30 ^ ( p0_nodeVar30 >> 16u ) ) ), f32( ( p0_nodeVar31 ^ ( p0_nodeVar31 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar33 = exp( ( -4.0 * p0_nodeVar32 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar33 * sin( ( 6.28 * sqrt( max( p0_nodeVar32, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar33 );
	p0_nodeVar34 = ( p0_nodeVar5 + vec2<f32>( -2.0, 2.0 ) );
	p0_nodeVar35 = ( ( vec2<u32>( floor( ( p0_nodeVar34 - ( floor( ( p0_nodeVar34 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar34 - ( floor( ( p0_nodeVar34 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar36 = ( ( p0_nodeVar35 ^ ( p0_nodeVar35 >> 16u ) ) * 2146121005u );
	p0_nodeVar37 = ( ( p0_nodeVar36 ^ ( p0_nodeVar36 >> 15u ) ) * 2221713035u );
	p0_nodeVar38 = ( ( p0_nodeVar36 ^ ( p0_nodeVar36 >> 13u ) ) * 2654435769u );
	p0_nodeVar39 = distance( ( p0_nodeVar3 - vec2<f32>( -2.0, 2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar37 ^ ( p0_nodeVar37 >> 16u ) ) ), f32( ( p0_nodeVar38 ^ ( p0_nodeVar38 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar40 = exp( ( -4.0 * p0_nodeVar39 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar40 * sin( ( 6.28 * sqrt( max( p0_nodeVar39, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar40 );
	p0_nodeVar41 = ( p0_nodeVar5 + vec2<f32>( -1.0, -2.0 ) );
	p0_nodeVar42 = ( ( vec2<u32>( floor( ( p0_nodeVar41 - ( floor( ( p0_nodeVar41 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar41 - ( floor( ( p0_nodeVar41 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar43 = ( ( p0_nodeVar42 ^ ( p0_nodeVar42 >> 16u ) ) * 2146121005u );
	p0_nodeVar44 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 15u ) ) * 2221713035u );
	p0_nodeVar45 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 13u ) ) * 2654435769u );
	p0_nodeVar46 = distance( ( p0_nodeVar3 - vec2<f32>( -1.0, -2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar44 ^ ( p0_nodeVar44 >> 16u ) ) ), f32( ( p0_nodeVar45 ^ ( p0_nodeVar45 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar47 = exp( ( -4.0 * p0_nodeVar46 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar47 * sin( ( 6.28 * sqrt( max( p0_nodeVar46, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar47 );
	p0_nodeVar48 = ( p0_nodeVar5 + vec2<f32>( -1.0, -1.0 ) );
	p0_nodeVar49 = ( ( vec2<u32>( floor( ( p0_nodeVar48 - ( floor( ( p0_nodeVar48 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar48 - ( floor( ( p0_nodeVar48 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar50 = ( ( p0_nodeVar49 ^ ( p0_nodeVar49 >> 16u ) ) * 2146121005u );
	p0_nodeVar51 = ( ( p0_nodeVar50 ^ ( p0_nodeVar50 >> 15u ) ) * 2221713035u );
	p0_nodeVar52 = ( ( p0_nodeVar50 ^ ( p0_nodeVar50 >> 13u ) ) * 2654435769u );
	p0_nodeVar53 = distance( ( p0_nodeVar3 - vec2<f32>( -1.0, -1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar51 ^ ( p0_nodeVar51 >> 16u ) ) ), f32( ( p0_nodeVar52 ^ ( p0_nodeVar52 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar54 = exp( ( -4.0 * p0_nodeVar53 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar54 * sin( ( 6.28 * sqrt( max( p0_nodeVar53, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar54 );
	p0_nodeVar55 = ( p0_nodeVar5 + vec2<f32>( -1.0, 0.0 ) );
	p0_nodeVar56 = ( ( vec2<u32>( floor( ( p0_nodeVar55 - ( floor( ( p0_nodeVar55 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar55 - ( floor( ( p0_nodeVar55 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar57 = ( ( p0_nodeVar56 ^ ( p0_nodeVar56 >> 16u ) ) * 2146121005u );
	p0_nodeVar58 = ( ( p0_nodeVar57 ^ ( p0_nodeVar57 >> 15u ) ) * 2221713035u );
	p0_nodeVar59 = ( ( p0_nodeVar57 ^ ( p0_nodeVar57 >> 13u ) ) * 2654435769u );
	p0_nodeVar60 = distance( ( p0_nodeVar3 - vec2<f32>( -1.0, 0.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar58 ^ ( p0_nodeVar58 >> 16u ) ) ), f32( ( p0_nodeVar59 ^ ( p0_nodeVar59 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar61 = exp( ( -4.0 * p0_nodeVar60 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar61 * sin( ( 6.28 * sqrt( max( p0_nodeVar60, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar61 );
	p0_nodeVar62 = ( p0_nodeVar5 + vec2<f32>( -1.0, 1.0 ) );
	p0_nodeVar63 = ( ( vec2<u32>( floor( ( p0_nodeVar62 - ( floor( ( p0_nodeVar62 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar62 - ( floor( ( p0_nodeVar62 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar64 = ( ( p0_nodeVar63 ^ ( p0_nodeVar63 >> 16u ) ) * 2146121005u );
	p0_nodeVar65 = ( ( p0_nodeVar64 ^ ( p0_nodeVar64 >> 15u ) ) * 2221713035u );
	p0_nodeVar66 = ( ( p0_nodeVar64 ^ ( p0_nodeVar64 >> 13u ) ) * 2654435769u );
	p0_nodeVar67 = distance( ( p0_nodeVar3 - vec2<f32>( -1.0, 1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar65 ^ ( p0_nodeVar65 >> 16u ) ) ), f32( ( p0_nodeVar66 ^ ( p0_nodeVar66 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar68 = exp( ( -4.0 * p0_nodeVar67 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar68 * sin( ( 6.28 * sqrt( max( p0_nodeVar67, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar68 );
	p0_nodeVar69 = ( p0_nodeVar5 + vec2<f32>( -1.0, 2.0 ) );
	p0_nodeVar70 = ( ( vec2<u32>( floor( ( p0_nodeVar69 - ( floor( ( p0_nodeVar69 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar69 - ( floor( ( p0_nodeVar69 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar71 = ( ( p0_nodeVar70 ^ ( p0_nodeVar70 >> 16u ) ) * 2146121005u );
	p0_nodeVar72 = ( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 15u ) ) * 2221713035u );
	p0_nodeVar73 = ( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 13u ) ) * 2654435769u );
	p0_nodeVar74 = distance( ( p0_nodeVar3 - vec2<f32>( -1.0, 2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar72 ^ ( p0_nodeVar72 >> 16u ) ) ), f32( ( p0_nodeVar73 ^ ( p0_nodeVar73 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar75 = exp( ( -4.0 * p0_nodeVar74 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar75 * sin( ( 6.28 * sqrt( max( p0_nodeVar74, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar75 );
	p0_nodeVar76 = ( p0_nodeVar5 + vec2<f32>( 0.0, -2.0 ) );
	p0_nodeVar77 = ( ( vec2<u32>( floor( ( p0_nodeVar76 - ( floor( ( p0_nodeVar76 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar76 - ( floor( ( p0_nodeVar76 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar78 = ( ( p0_nodeVar77 ^ ( p0_nodeVar77 >> 16u ) ) * 2146121005u );
	p0_nodeVar79 = ( ( p0_nodeVar78 ^ ( p0_nodeVar78 >> 15u ) ) * 2221713035u );
	p0_nodeVar80 = ( ( p0_nodeVar78 ^ ( p0_nodeVar78 >> 13u ) ) * 2654435769u );
	p0_nodeVar81 = distance( ( p0_nodeVar3 - vec2<f32>( 0.0, -2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar79 ^ ( p0_nodeVar79 >> 16u ) ) ), f32( ( p0_nodeVar80 ^ ( p0_nodeVar80 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar82 = exp( ( -4.0 * p0_nodeVar81 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar82 * sin( ( 6.28 * sqrt( max( p0_nodeVar81, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar82 );
	p0_nodeVar83 = ( p0_nodeVar5 + vec2<f32>( 0.0, -1.0 ) );
	p0_nodeVar84 = ( ( vec2<u32>( floor( ( p0_nodeVar83 - ( floor( ( p0_nodeVar83 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar83 - ( floor( ( p0_nodeVar83 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar85 = ( ( p0_nodeVar84 ^ ( p0_nodeVar84 >> 16u ) ) * 2146121005u );
	p0_nodeVar86 = ( ( p0_nodeVar85 ^ ( p0_nodeVar85 >> 15u ) ) * 2221713035u );
	p0_nodeVar87 = ( ( p0_nodeVar85 ^ ( p0_nodeVar85 >> 13u ) ) * 2654435769u );
	p0_nodeVar88 = distance( ( p0_nodeVar3 - vec2<f32>( 0.0, -1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar86 ^ ( p0_nodeVar86 >> 16u ) ) ), f32( ( p0_nodeVar87 ^ ( p0_nodeVar87 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar89 = exp( ( -4.0 * p0_nodeVar88 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar89 * sin( ( 6.28 * sqrt( max( p0_nodeVar88, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar89 );
	p0_nodeVar90 = ( p0_nodeVar5 + vec2<f32>( 0.0, 0.0 ) );
	p0_nodeVar91 = ( ( vec2<u32>( floor( ( p0_nodeVar90 - ( floor( ( p0_nodeVar90 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar90 - ( floor( ( p0_nodeVar90 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar92 = ( ( p0_nodeVar91 ^ ( p0_nodeVar91 >> 16u ) ) * 2146121005u );
	p0_nodeVar93 = ( ( p0_nodeVar92 ^ ( p0_nodeVar92 >> 15u ) ) * 2221713035u );
	p0_nodeVar94 = ( ( p0_nodeVar92 ^ ( p0_nodeVar92 >> 13u ) ) * 2654435769u );
	p0_nodeVar95 = distance( ( p0_nodeVar3 - vec2<f32>( 0.0, 0.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar93 ^ ( p0_nodeVar93 >> 16u ) ) ), f32( ( p0_nodeVar94 ^ ( p0_nodeVar94 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar96 = exp( ( -4.0 * p0_nodeVar95 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar96 * sin( ( 6.28 * sqrt( max( p0_nodeVar95, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar96 );
	p0_nodeVar97 = ( p0_nodeVar5 + vec2<f32>( 0.0, 1.0 ) );
	p0_nodeVar98 = ( ( vec2<u32>( floor( ( p0_nodeVar97 - ( floor( ( p0_nodeVar97 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar97 - ( floor( ( p0_nodeVar97 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar99 = ( ( p0_nodeVar98 ^ ( p0_nodeVar98 >> 16u ) ) * 2146121005u );
	p0_nodeVar100 = ( ( p0_nodeVar99 ^ ( p0_nodeVar99 >> 15u ) ) * 2221713035u );
	p0_nodeVar101 = ( ( p0_nodeVar99 ^ ( p0_nodeVar99 >> 13u ) ) * 2654435769u );
	p0_nodeVar102 = distance( ( p0_nodeVar3 - vec2<f32>( 0.0, 1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar100 ^ ( p0_nodeVar100 >> 16u ) ) ), f32( ( p0_nodeVar101 ^ ( p0_nodeVar101 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar103 = exp( ( -4.0 * p0_nodeVar102 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar103 * sin( ( 6.28 * sqrt( max( p0_nodeVar102, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar103 );
	p0_nodeVar104 = ( p0_nodeVar5 + vec2<f32>( 0.0, 2.0 ) );
	p0_nodeVar105 = ( ( vec2<u32>( floor( ( p0_nodeVar104 - ( floor( ( p0_nodeVar104 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar104 - ( floor( ( p0_nodeVar104 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar106 = ( ( p0_nodeVar105 ^ ( p0_nodeVar105 >> 16u ) ) * 2146121005u );
	p0_nodeVar107 = ( ( p0_nodeVar106 ^ ( p0_nodeVar106 >> 15u ) ) * 2221713035u );
	p0_nodeVar108 = ( ( p0_nodeVar106 ^ ( p0_nodeVar106 >> 13u ) ) * 2654435769u );
	p0_nodeVar109 = distance( ( p0_nodeVar3 - vec2<f32>( 0.0, 2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar107 ^ ( p0_nodeVar107 >> 16u ) ) ), f32( ( p0_nodeVar108 ^ ( p0_nodeVar108 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar110 = exp( ( -4.0 * p0_nodeVar109 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar110 * sin( ( 6.28 * sqrt( max( p0_nodeVar109, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar110 );
	p0_nodeVar111 = ( p0_nodeVar5 + vec2<f32>( 1.0, -2.0 ) );
	p0_nodeVar112 = ( ( vec2<u32>( floor( ( p0_nodeVar111 - ( floor( ( p0_nodeVar111 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar111 - ( floor( ( p0_nodeVar111 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar113 = ( ( p0_nodeVar112 ^ ( p0_nodeVar112 >> 16u ) ) * 2146121005u );
	p0_nodeVar114 = ( ( p0_nodeVar113 ^ ( p0_nodeVar113 >> 15u ) ) * 2221713035u );
	p0_nodeVar115 = ( ( p0_nodeVar113 ^ ( p0_nodeVar113 >> 13u ) ) * 2654435769u );
	p0_nodeVar116 = distance( ( p0_nodeVar3 - vec2<f32>( 1.0, -2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar114 ^ ( p0_nodeVar114 >> 16u ) ) ), f32( ( p0_nodeVar115 ^ ( p0_nodeVar115 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar117 = exp( ( -4.0 * p0_nodeVar116 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar117 * sin( ( 6.28 * sqrt( max( p0_nodeVar116, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar117 );
	p0_nodeVar118 = ( p0_nodeVar5 + vec2<f32>( 1.0, -1.0 ) );
	p0_nodeVar119 = ( ( vec2<u32>( floor( ( p0_nodeVar118 - ( floor( ( p0_nodeVar118 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar118 - ( floor( ( p0_nodeVar118 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar120 = ( ( p0_nodeVar119 ^ ( p0_nodeVar119 >> 16u ) ) * 2146121005u );
	p0_nodeVar121 = ( ( p0_nodeVar120 ^ ( p0_nodeVar120 >> 15u ) ) * 2221713035u );
	p0_nodeVar122 = ( ( p0_nodeVar120 ^ ( p0_nodeVar120 >> 13u ) ) * 2654435769u );
	p0_nodeVar123 = distance( ( p0_nodeVar3 - vec2<f32>( 1.0, -1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar121 ^ ( p0_nodeVar121 >> 16u ) ) ), f32( ( p0_nodeVar122 ^ ( p0_nodeVar122 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar124 = exp( ( -4.0 * p0_nodeVar123 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar124 * sin( ( 6.28 * sqrt( max( p0_nodeVar123, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar124 );
	p0_nodeVar125 = ( p0_nodeVar5 + vec2<f32>( 1.0, 0.0 ) );
	p0_nodeVar126 = ( ( vec2<u32>( floor( ( p0_nodeVar125 - ( floor( ( p0_nodeVar125 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar125 - ( floor( ( p0_nodeVar125 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar127 = ( ( p0_nodeVar126 ^ ( p0_nodeVar126 >> 16u ) ) * 2146121005u );
	p0_nodeVar128 = ( ( p0_nodeVar127 ^ ( p0_nodeVar127 >> 15u ) ) * 2221713035u );
	p0_nodeVar129 = ( ( p0_nodeVar127 ^ ( p0_nodeVar127 >> 13u ) ) * 2654435769u );
	p0_nodeVar130 = distance( ( p0_nodeVar3 - vec2<f32>( 1.0, 0.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar128 ^ ( p0_nodeVar128 >> 16u ) ) ), f32( ( p0_nodeVar129 ^ ( p0_nodeVar129 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar131 = exp( ( -4.0 * p0_nodeVar130 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar131 * sin( ( 6.28 * sqrt( max( p0_nodeVar130, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar131 );
	p0_nodeVar132 = ( p0_nodeVar5 + vec2<f32>( 1.0, 1.0 ) );
	p0_nodeVar133 = ( ( vec2<u32>( floor( ( p0_nodeVar132 - ( floor( ( p0_nodeVar132 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar132 - ( floor( ( p0_nodeVar132 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar134 = ( ( p0_nodeVar133 ^ ( p0_nodeVar133 >> 16u ) ) * 2146121005u );
	p0_nodeVar135 = ( ( p0_nodeVar134 ^ ( p0_nodeVar134 >> 15u ) ) * 2221713035u );
	p0_nodeVar136 = ( ( p0_nodeVar134 ^ ( p0_nodeVar134 >> 13u ) ) * 2654435769u );
	p0_nodeVar137 = distance( ( p0_nodeVar3 - vec2<f32>( 1.0, 1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar135 ^ ( p0_nodeVar135 >> 16u ) ) ), f32( ( p0_nodeVar136 ^ ( p0_nodeVar136 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar138 = exp( ( -4.0 * p0_nodeVar137 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar138 * sin( ( 6.28 * sqrt( max( p0_nodeVar137, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar138 );
	p0_nodeVar139 = ( p0_nodeVar5 + vec2<f32>( 1.0, 2.0 ) );
	p0_nodeVar140 = ( ( vec2<u32>( floor( ( p0_nodeVar139 - ( floor( ( p0_nodeVar139 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar139 - ( floor( ( p0_nodeVar139 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar141 = ( ( p0_nodeVar140 ^ ( p0_nodeVar140 >> 16u ) ) * 2146121005u );
	p0_nodeVar142 = ( ( p0_nodeVar141 ^ ( p0_nodeVar141 >> 15u ) ) * 2221713035u );
	p0_nodeVar143 = ( ( p0_nodeVar141 ^ ( p0_nodeVar141 >> 13u ) ) * 2654435769u );
	p0_nodeVar144 = distance( ( p0_nodeVar3 - vec2<f32>( 1.0, 2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar142 ^ ( p0_nodeVar142 >> 16u ) ) ), f32( ( p0_nodeVar143 ^ ( p0_nodeVar143 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar145 = exp( ( -4.0 * p0_nodeVar144 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar145 * sin( ( 6.28 * sqrt( max( p0_nodeVar144, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar145 );
	p0_nodeVar146 = ( p0_nodeVar5 + vec2<f32>( 2.0, -2.0 ) );
	p0_nodeVar147 = ( ( vec2<u32>( floor( ( p0_nodeVar146 - ( floor( ( p0_nodeVar146 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar146 - ( floor( ( p0_nodeVar146 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar148 = ( ( p0_nodeVar147 ^ ( p0_nodeVar147 >> 16u ) ) * 2146121005u );
	p0_nodeVar149 = ( ( p0_nodeVar148 ^ ( p0_nodeVar148 >> 15u ) ) * 2221713035u );
	p0_nodeVar150 = ( ( p0_nodeVar148 ^ ( p0_nodeVar148 >> 13u ) ) * 2654435769u );
	p0_nodeVar151 = distance( ( p0_nodeVar3 - vec2<f32>( 2.0, -2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar149 ^ ( p0_nodeVar149 >> 16u ) ) ), f32( ( p0_nodeVar150 ^ ( p0_nodeVar150 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar152 = exp( ( -4.0 * p0_nodeVar151 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar152 * sin( ( 6.28 * sqrt( max( p0_nodeVar151, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar152 );
	p0_nodeVar153 = ( p0_nodeVar5 + vec2<f32>( 2.0, -1.0 ) );
	p0_nodeVar154 = ( ( vec2<u32>( floor( ( p0_nodeVar153 - ( floor( ( p0_nodeVar153 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar153 - ( floor( ( p0_nodeVar153 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar155 = ( ( p0_nodeVar154 ^ ( p0_nodeVar154 >> 16u ) ) * 2146121005u );
	p0_nodeVar156 = ( ( p0_nodeVar155 ^ ( p0_nodeVar155 >> 15u ) ) * 2221713035u );
	p0_nodeVar157 = ( ( p0_nodeVar155 ^ ( p0_nodeVar155 >> 13u ) ) * 2654435769u );
	p0_nodeVar158 = distance( ( p0_nodeVar3 - vec2<f32>( 2.0, -1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar156 ^ ( p0_nodeVar156 >> 16u ) ) ), f32( ( p0_nodeVar157 ^ ( p0_nodeVar157 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar159 = exp( ( -4.0 * p0_nodeVar158 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar159 * sin( ( 6.28 * sqrt( max( p0_nodeVar158, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar159 );
	p0_nodeVar160 = ( p0_nodeVar5 + vec2<f32>( 2.0, 0.0 ) );
	p0_nodeVar161 = ( ( vec2<u32>( floor( ( p0_nodeVar160 - ( floor( ( p0_nodeVar160 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar160 - ( floor( ( p0_nodeVar160 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar162 = ( ( p0_nodeVar161 ^ ( p0_nodeVar161 >> 16u ) ) * 2146121005u );
	p0_nodeVar163 = ( ( p0_nodeVar162 ^ ( p0_nodeVar162 >> 15u ) ) * 2221713035u );
	p0_nodeVar164 = ( ( p0_nodeVar162 ^ ( p0_nodeVar162 >> 13u ) ) * 2654435769u );
	p0_nodeVar165 = distance( ( p0_nodeVar3 - vec2<f32>( 2.0, 0.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar163 ^ ( p0_nodeVar163 >> 16u ) ) ), f32( ( p0_nodeVar164 ^ ( p0_nodeVar164 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar166 = exp( ( -4.0 * p0_nodeVar165 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar166 * sin( ( 6.28 * sqrt( max( p0_nodeVar165, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar166 );
	p0_nodeVar167 = ( p0_nodeVar5 + vec2<f32>( 2.0, 1.0 ) );
	p0_nodeVar168 = ( ( vec2<u32>( floor( ( p0_nodeVar167 - ( floor( ( p0_nodeVar167 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar167 - ( floor( ( p0_nodeVar167 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar169 = ( ( p0_nodeVar168 ^ ( p0_nodeVar168 >> 16u ) ) * 2146121005u );
	p0_nodeVar170 = ( ( p0_nodeVar169 ^ ( p0_nodeVar169 >> 15u ) ) * 2221713035u );
	p0_nodeVar171 = ( ( p0_nodeVar169 ^ ( p0_nodeVar169 >> 13u ) ) * 2654435769u );
	p0_nodeVar172 = distance( ( p0_nodeVar3 - vec2<f32>( 2.0, 1.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar170 ^ ( p0_nodeVar170 >> 16u ) ) ), f32( ( p0_nodeVar171 ^ ( p0_nodeVar171 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar173 = exp( ( -4.0 * p0_nodeVar172 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar173 * sin( ( 6.28 * sqrt( max( p0_nodeVar172, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar173 );
	p0_nodeVar174 = ( p0_nodeVar5 + vec2<f32>( 2.0, 2.0 ) );
	p0_nodeVar175 = ( ( vec2<u32>( floor( ( p0_nodeVar174 - ( floor( ( p0_nodeVar174 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( ( p0_nodeVar174 - ( floor( ( p0_nodeVar174 / vec2<f32>( 13.0 ) ) ) * vec2<f32>( 13.0 ) ) ) ) ).y );
	p0_nodeVar176 = ( ( p0_nodeVar175 ^ ( p0_nodeVar175 >> 16u ) ) * 2146121005u );
	p0_nodeVar177 = ( ( p0_nodeVar176 ^ ( p0_nodeVar176 >> 15u ) ) * 2221713035u );
	p0_nodeVar178 = ( ( p0_nodeVar176 ^ ( p0_nodeVar176 >> 13u ) ) * 2654435769u );
	p0_nodeVar179 = distance( ( p0_nodeVar3 - vec2<f32>( 2.0, 2.0 ) ), ( vec2<f32>( f32( ( p0_nodeVar177 ^ ( p0_nodeVar177 >> 16u ) ) ), f32( ( p0_nodeVar178 ^ ( p0_nodeVar178 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) );
	p0_nodeVar180 = exp( ( -4.0 * p0_nodeVar179 ) );
	p0_nodeVar0 = ( p0_nodeVar0 + ( p0_nodeVar180 * sin( ( 6.28 * sqrt( max( p0_nodeVar179, 0.06 ) ) ) ) ) );
	p0_nodeVar1 = ( p0_nodeVar1 + p0_nodeVar180 );
	p0_DiffuseColor = vec4<f32>( abs( ( p0_nodeVar0 / p0_nodeVar1 ) ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar181 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar181;

	// result

	p0_output.color = p0_nodeVar181;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

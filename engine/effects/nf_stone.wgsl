// Stone noise: threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions), by three.js's own builder (engine/tsl/noise_fx_shelf.ts)
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
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec3<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : u32;
var<private> p0_nodeVar6 : u32;
var<private> p0_nodeVar7 : u32;
var<private> p0_nodeVar8 : u32;
var<private> p0_nodeVar9 : vec2<f32>;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : u32;
var<private> p0_nodeVar14 : u32;
var<private> p0_nodeVar15 : u32;
var<private> p0_nodeVar16 : u32;
var<private> p0_nodeVar17 : vec2<f32>;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : u32;
var<private> p0_nodeVar20 : u32;
var<private> p0_nodeVar21 : u32;
var<private> p0_nodeVar22 : u32;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : u32;
var<private> p0_nodeVar26 : u32;
var<private> p0_nodeVar27 : u32;
var<private> p0_nodeVar28 : u32;
var<private> p0_nodeVar29 : vec2<f32>;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : vec2<f32>;
var<private> p0_nodeVar37 : u32;
var<private> p0_nodeVar38 : u32;
var<private> p0_nodeVar39 : u32;
var<private> p0_nodeVar40 : u32;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : u32;
var<private> p0_nodeVar43 : u32;
var<private> p0_nodeVar44 : u32;
var<private> p0_nodeVar45 : u32;
var<private> p0_nodeVar46 : vec2<f32>;
var<private> p0_nodeVar47 : u32;
var<private> p0_nodeVar48 : u32;
var<private> p0_nodeVar49 : u32;
var<private> p0_nodeVar50 : u32;
var<private> p0_nodeVar51 : u32;
var<private> p0_nodeVar52 : u32;
var<private> p0_nodeVar53 : u32;
var<private> p0_nodeVar54 : u32;
var<private> p0_nodeVar55 : vec2<f32>;
var<private> p0_nodeVar56 : u32;
var<private> p0_nodeVar57 : u32;
var<private> p0_nodeVar58 : u32;
var<private> p0_nodeVar59 : u32;
var<private> p0_nodeVar60 : vec2<f32>;
var<private> p0_nodeVar61 : u32;
var<private> p0_nodeVar62 : u32;
var<private> p0_nodeVar63 : u32;
var<private> p0_nodeVar64 : u32;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : u32;
var<private> p0_nodeVar67 : u32;
var<private> p0_nodeVar68 : u32;
var<private> p0_nodeVar69 : u32;
var<private> p0_nodeVar70 : u32;
var<private> p0_nodeVar71 : u32;
var<private> p0_nodeVar72 : u32;
var<private> p0_nodeVar73 : u32;
var<private> p0_nodeVar74 : vec2<f32>;
var<private> p0_nodeVar75 : u32;
var<private> p0_nodeVar76 : u32;
var<private> p0_nodeVar77 : u32;
var<private> p0_nodeVar78 : u32;
var<private> p0_nodeVar79 : vec2<f32>;
var<private> p0_nodeVar80 : u32;
var<private> p0_nodeVar81 : u32;
var<private> p0_nodeVar82 : u32;
var<private> p0_nodeVar83 : u32;
var<private> p0_nodeVar84 : vec2<f32>;
var<private> p0_nodeVar85 : u32;
var<private> p0_nodeVar86 : u32;
var<private> p0_nodeVar87 : u32;
var<private> p0_nodeVar88 : u32;
var<private> p0_nodeVar89 : u32;
var<private> p0_nodeVar90 : u32;
var<private> p0_nodeVar91 : u32;
var<private> p0_nodeVar92 : u32;
var<private> p0_nodeVar93 : vec2<f32>;
var<private> p0_nodeVar94 : u32;
var<private> p0_nodeVar95 : u32;
var<private> p0_nodeVar96 : u32;
var<private> p0_nodeVar97 : u32;
var<private> p0_nodeVar98 : vec2<f32>;
var<private> p0_nodeVar99 : u32;
var<private> p0_nodeVar100 : u32;
var<private> p0_nodeVar101 : u32;
var<private> p0_nodeVar102 : u32;
var<private> p0_nodeVar103 : vec2<f32>;
var<private> p0_nodeVar104 : u32;
var<private> p0_nodeVar105 : u32;
var<private> p0_nodeVar106 : u32;
var<private> p0_nodeVar107 : u32;
var<private> p0_nodeVar108 : u32;
var<private> p0_nodeVar109 : u32;
var<private> p0_nodeVar110 : u32;
var<private> p0_nodeVar111 : u32;
var<private> p0_nodeVar112 : vec2<f32>;
var<private> p0_nodeVar113 : u32;
var<private> p0_nodeVar114 : u32;
var<private> p0_nodeVar115 : u32;
var<private> p0_nodeVar116 : u32;
var<private> p0_nodeVar117 : vec2<f32>;
var<private> p0_nodeVar118 : u32;
var<private> p0_nodeVar119 : u32;
var<private> p0_nodeVar120 : u32;
var<private> p0_nodeVar121 : u32;
var<private> p0_nodeVar122 : vec2<f32>;
var<private> p0_nodeVar123 : u32;
var<private> p0_nodeVar124 : u32;
var<private> p0_nodeVar125 : u32;
var<private> p0_nodeVar126 : u32;
var<private> p0_nodeVar127 : u32;
var<private> p0_nodeVar128 : u32;
var<private> p0_nodeVar129 : u32;
var<private> p0_nodeVar130 : u32;
var<private> p0_nodeVar131 : vec2<f32>;
var<private> p0_nodeVar132 : u32;
var<private> p0_nodeVar133 : u32;
var<private> p0_nodeVar134 : u32;
var<private> p0_nodeVar135 : u32;
var<private> p0_nodeVar136 : vec2<f32>;
var<private> p0_nodeVar137 : u32;
var<private> p0_nodeVar138 : u32;
var<private> p0_nodeVar139 : u32;
var<private> p0_nodeVar140 : u32;
var<private> p0_nodeVar141 : vec2<f32>;
var<private> p0_nodeVar142 : u32;
var<private> p0_nodeVar143 : u32;
var<private> p0_nodeVar144 : u32;
var<private> p0_nodeVar145 : u32;
var<private> p0_nodeVar146 : u32;
var<private> p0_nodeVar147 : u32;
var<private> p0_nodeVar148 : u32;
var<private> p0_nodeVar149 : u32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar150 : vec4<f32>;

// codes
fn p0_tsl_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_nodeVar0 = ( ( ( nodeVarying4.xy + vec2<f32>( 3.0 ) ) * vec2<f32>( ( f32(knobs.scale) / 2.0 ) ) ) + vec2<f32>( ( sin( ( f32(knobs.time) * f32(knobs.pace) ) ) + 1.0 ) ) );
	p0_nodeVar1 = p0_nodeVar0;
	p0_nodeVar2 = vec3<f32>( 0.0, 0.0, 0.0 );
	p0_nodeVar3 = 1.0;

	for ( var i : i32 = 0; i < 6; i ++ ) {

		p0_nodeVar4 = p0_tsl_mod_vec2( floor( p0_nodeVar1 ), vec2<f32>( 6.0 ) );
		p0_nodeVar5 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 0.0, 0.0 ) ), vec2<f32>( 6.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 0.0, 0.0 ) ), vec2<f32>( 6.0 ) ) ) ).y );
		p0_nodeVar6 = ( ( p0_nodeVar5 ^ ( p0_nodeVar5 >> 16u ) ) * 2146121005u );
		p0_nodeVar7 = ( ( p0_nodeVar6 ^ ( p0_nodeVar6 >> 15u ) ) * 2221713035u );
		p0_nodeVar8 = ( ( p0_nodeVar6 ^ ( p0_nodeVar6 >> 13u ) ) * 2654435769u );
		p0_nodeVar9 = ( ( ( vec2<f32>( f32( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 16u ) ) ), f32( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
		p0_nodeVar10 = fract( p0_nodeVar1 );
		p0_nodeVar11 = dot( p0_nodeVar9, ( p0_nodeVar10 - vec2<f32>( 0.0, 0.0 ) ) );
		p0_nodeVar12 = ( ( ( p0_nodeVar10 * p0_nodeVar10 ) * p0_nodeVar10 ) * ( ( p0_nodeVar10 * ( ( p0_nodeVar10 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) + vec2<f32>( 10.0 ) ) );
		p0_nodeVar13 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 6.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 6.0 ) ) ) ).y );
		p0_nodeVar14 = ( ( p0_nodeVar13 ^ ( p0_nodeVar13 >> 16u ) ) * 2146121005u );
		p0_nodeVar15 = ( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 15u ) ) * 2221713035u );
		p0_nodeVar16 = ( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 13u ) ) * 2654435769u );
		p0_nodeVar17 = ( ( ( vec2<f32>( f32( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 16u ) ) ), f32( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
		p0_nodeVar18 = dot( p0_nodeVar17, ( p0_nodeVar10 - vec2<f32>( 1.0, 0.0 ) ) );
		p0_nodeVar19 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 6.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 6.0 ) ) ) ).y );
		p0_nodeVar20 = ( ( p0_nodeVar19 ^ ( p0_nodeVar19 >> 16u ) ) * 2146121005u );
		p0_nodeVar21 = ( ( p0_nodeVar20 ^ ( p0_nodeVar20 >> 15u ) ) * 2221713035u );
		p0_nodeVar22 = ( ( p0_nodeVar20 ^ ( p0_nodeVar20 >> 13u ) ) * 2654435769u );
		p0_nodeVar23 = ( ( ( vec2<f32>( f32( ( p0_nodeVar21 ^ ( p0_nodeVar21 >> 16u ) ) ), f32( ( p0_nodeVar22 ^ ( p0_nodeVar22 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
		p0_nodeVar24 = dot( p0_nodeVar23, ( p0_nodeVar10 - vec2<f32>( 0.0, 1.0 ) ) );
		p0_nodeVar25 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 6.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar4 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 6.0 ) ) ) ).y );
		p0_nodeVar26 = ( ( p0_nodeVar25 ^ ( p0_nodeVar25 >> 16u ) ) * 2146121005u );
		p0_nodeVar27 = ( ( p0_nodeVar26 ^ ( p0_nodeVar26 >> 15u ) ) * 2221713035u );
		p0_nodeVar28 = ( ( p0_nodeVar26 ^ ( p0_nodeVar26 >> 13u ) ) * 2654435769u );
		p0_nodeVar29 = ( ( ( vec2<f32>( f32( ( p0_nodeVar27 ^ ( p0_nodeVar27 >> 16u ) ) ), f32( ( p0_nodeVar28 ^ ( p0_nodeVar28 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
		p0_nodeVar30 = dot( p0_nodeVar29, ( p0_nodeVar10 - vec2<f32>( 1.0, 1.0 ) ) );
		p0_nodeVar2 = ( p0_nodeVar2 + ( vec3<f32>( p0_nodeVar3 ) * vec3<f32>( ( ( ( p0_nodeVar11 + ( p0_nodeVar12.x * ( p0_nodeVar18 - p0_nodeVar11 ) ) ) + ( p0_nodeVar12.y * ( p0_nodeVar24 - p0_nodeVar11 ) ) ) + ( ( p0_nodeVar12.x * p0_nodeVar12.y ) * ( ( ( p0_nodeVar11 - p0_nodeVar18 ) - p0_nodeVar24 ) + p0_nodeVar30 ) ) ), ( ( ( ( p0_nodeVar9 + ( vec2<f32>( p0_nodeVar12.x ) * ( p0_nodeVar17 - p0_nodeVar9 ) ) ) + ( vec2<f32>( p0_nodeVar12.y ) * ( p0_nodeVar23 - p0_nodeVar9 ) ) ) + ( vec2<f32>( ( p0_nodeVar12.x * p0_nodeVar12.y ) ) * ( ( ( p0_nodeVar9 - p0_nodeVar17 ) - p0_nodeVar23 ) + p0_nodeVar29 ) ) ) + ( ( ( ( vec2<f32>( 30.0 ) * p0_nodeVar10 ) * p0_nodeVar10 ) * ( ( p0_nodeVar10 * ( p0_nodeVar10 - vec2<f32>( 2.0 ) ) ) + vec2<f32>( 1.0 ) ) ) * ( ( p0_nodeVar12.yx * vec2<f32>( ( ( ( p0_nodeVar11 - p0_nodeVar18 ) - p0_nodeVar24 ) + p0_nodeVar30 ) ) ) + ( vec2<f32>( p0_nodeVar18, p0_nodeVar24 ) - vec2<f32>( p0_nodeVar11 ) ) ) ) ) ) ) );
		p0_nodeVar3 = ( p0_nodeVar3 * 0.5 );
		p0_nodeVar1 = ( p0_nodeVar1 * vec2<f32>( 2.0 ) );

	}

	p0_nodeVar31 = ( p0_nodeVar0 + ( p0_nodeVar2.yz * vec2<f32>( 0.4 ) ) );
	p0_nodeVar32 = 0.0;
	p0_nodeVar33 = 0.0;
	p0_nodeVar34 = 1.0;
	p0_nodeVar35 = 6.0;
	p0_nodeVar36 = floor( p0_nodeVar31 );
	p0_nodeVar37 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar36, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar36, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar38 = ( ( p0_nodeVar37 ^ ( p0_nodeVar37 >> 16u ) ) * 2146121005u );
	p0_nodeVar39 = ( ( p0_nodeVar38 ^ ( p0_nodeVar38 >> 15u ) ) * 2221713035u );
	p0_nodeVar40 = ( ( p0_nodeVar38 ^ ( p0_nodeVar38 >> 13u ) ) * 2654435769u );
	p0_nodeVar41 = ( p0_nodeVar31 - p0_nodeVar36 );
	p0_nodeVar42 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar43 = ( ( p0_nodeVar42 ^ ( p0_nodeVar42 >> 16u ) ) * 2146121005u );
	p0_nodeVar44 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 15u ) ) * 2221713035u );
	p0_nodeVar45 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 13u ) ) * 2654435769u );
	p0_nodeVar46 = ( ( ( p0_nodeVar41 * p0_nodeVar41 ) * p0_nodeVar41 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar41 * ( ( p0_nodeVar41 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar47 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar48 = ( ( p0_nodeVar47 ^ ( p0_nodeVar47 >> 16u ) ) * 2146121005u );
	p0_nodeVar49 = ( ( p0_nodeVar48 ^ ( p0_nodeVar48 >> 15u ) ) * 2221713035u );
	p0_nodeVar50 = ( ( p0_nodeVar48 ^ ( p0_nodeVar48 >> 13u ) ) * 2654435769u );
	p0_nodeVar51 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar36 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar52 = ( ( p0_nodeVar51 ^ ( p0_nodeVar51 >> 16u ) ) * 2146121005u );
	p0_nodeVar53 = ( ( p0_nodeVar52 ^ ( p0_nodeVar52 >> 15u ) ) * 2221713035u );
	p0_nodeVar54 = ( ( p0_nodeVar52 ^ ( p0_nodeVar52 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar39 ^ ( p0_nodeVar39 >> 16u ) ) ), f32( ( p0_nodeVar40 ^ ( p0_nodeVar40 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar41 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar44 ^ ( p0_nodeVar44 >> 16u ) ) ), f32( ( p0_nodeVar45 ^ ( p0_nodeVar45 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar41 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar46.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar49 ^ ( p0_nodeVar49 >> 16u ) ) ), f32( ( p0_nodeVar50 ^ ( p0_nodeVar50 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar41 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar53 ^ ( p0_nodeVar53 >> 16u ) ) ), f32( ( p0_nodeVar54 ^ ( p0_nodeVar54 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar41 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar46.x ), p0_nodeVar46.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_nodeVar55 = floor( p0_nodeVar31 );
	p0_nodeVar56 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar55, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar55, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar57 = ( ( p0_nodeVar56 ^ ( p0_nodeVar56 >> 16u ) ) * 2146121005u );
	p0_nodeVar58 = ( ( p0_nodeVar57 ^ ( p0_nodeVar57 >> 15u ) ) * 2221713035u );
	p0_nodeVar59 = ( ( p0_nodeVar57 ^ ( p0_nodeVar57 >> 13u ) ) * 2654435769u );
	p0_nodeVar60 = ( p0_nodeVar31 - p0_nodeVar55 );
	p0_nodeVar61 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar62 = ( ( p0_nodeVar61 ^ ( p0_nodeVar61 >> 16u ) ) * 2146121005u );
	p0_nodeVar63 = ( ( p0_nodeVar62 ^ ( p0_nodeVar62 >> 15u ) ) * 2221713035u );
	p0_nodeVar64 = ( ( p0_nodeVar62 ^ ( p0_nodeVar62 >> 13u ) ) * 2654435769u );
	p0_nodeVar65 = ( ( ( p0_nodeVar60 * p0_nodeVar60 ) * p0_nodeVar60 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar60 * ( ( p0_nodeVar60 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar66 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar67 = ( ( p0_nodeVar66 ^ ( p0_nodeVar66 >> 16u ) ) * 2146121005u );
	p0_nodeVar68 = ( ( p0_nodeVar67 ^ ( p0_nodeVar67 >> 15u ) ) * 2221713035u );
	p0_nodeVar69 = ( ( p0_nodeVar67 ^ ( p0_nodeVar67 >> 13u ) ) * 2654435769u );
	p0_nodeVar70 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar55 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar71 = ( ( p0_nodeVar70 ^ ( p0_nodeVar70 >> 16u ) ) * 2146121005u );
	p0_nodeVar72 = ( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 15u ) ) * 2221713035u );
	p0_nodeVar73 = ( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar58 ^ ( p0_nodeVar58 >> 16u ) ) ), f32( ( p0_nodeVar59 ^ ( p0_nodeVar59 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar60 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar63 ^ ( p0_nodeVar63 >> 16u ) ) ), f32( ( p0_nodeVar64 ^ ( p0_nodeVar64 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar60 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar65.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar68 ^ ( p0_nodeVar68 >> 16u ) ) ), f32( ( p0_nodeVar69 ^ ( p0_nodeVar69 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar60 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar72 ^ ( p0_nodeVar72 >> 16u ) ) ), f32( ( p0_nodeVar73 ^ ( p0_nodeVar73 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar60 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar65.x ), p0_nodeVar65.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_nodeVar74 = floor( p0_nodeVar31 );
	p0_nodeVar75 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar74, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar74, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar76 = ( ( p0_nodeVar75 ^ ( p0_nodeVar75 >> 16u ) ) * 2146121005u );
	p0_nodeVar77 = ( ( p0_nodeVar76 ^ ( p0_nodeVar76 >> 15u ) ) * 2221713035u );
	p0_nodeVar78 = ( ( p0_nodeVar76 ^ ( p0_nodeVar76 >> 13u ) ) * 2654435769u );
	p0_nodeVar79 = ( p0_nodeVar31 - p0_nodeVar74 );
	p0_nodeVar80 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar81 = ( ( p0_nodeVar80 ^ ( p0_nodeVar80 >> 16u ) ) * 2146121005u );
	p0_nodeVar82 = ( ( p0_nodeVar81 ^ ( p0_nodeVar81 >> 15u ) ) * 2221713035u );
	p0_nodeVar83 = ( ( p0_nodeVar81 ^ ( p0_nodeVar81 >> 13u ) ) * 2654435769u );
	p0_nodeVar84 = ( ( ( p0_nodeVar79 * p0_nodeVar79 ) * p0_nodeVar79 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar79 * ( ( p0_nodeVar79 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar85 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar86 = ( ( p0_nodeVar85 ^ ( p0_nodeVar85 >> 16u ) ) * 2146121005u );
	p0_nodeVar87 = ( ( p0_nodeVar86 ^ ( p0_nodeVar86 >> 15u ) ) * 2221713035u );
	p0_nodeVar88 = ( ( p0_nodeVar86 ^ ( p0_nodeVar86 >> 13u ) ) * 2654435769u );
	p0_nodeVar89 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar74 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar90 = ( ( p0_nodeVar89 ^ ( p0_nodeVar89 >> 16u ) ) * 2146121005u );
	p0_nodeVar91 = ( ( p0_nodeVar90 ^ ( p0_nodeVar90 >> 15u ) ) * 2221713035u );
	p0_nodeVar92 = ( ( p0_nodeVar90 ^ ( p0_nodeVar90 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar77 ^ ( p0_nodeVar77 >> 16u ) ) ), f32( ( p0_nodeVar78 ^ ( p0_nodeVar78 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar79 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar82 ^ ( p0_nodeVar82 >> 16u ) ) ), f32( ( p0_nodeVar83 ^ ( p0_nodeVar83 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar79 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar84.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar87 ^ ( p0_nodeVar87 >> 16u ) ) ), f32( ( p0_nodeVar88 ^ ( p0_nodeVar88 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar79 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar91 ^ ( p0_nodeVar91 >> 16u ) ) ), f32( ( p0_nodeVar92 ^ ( p0_nodeVar92 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar79 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar84.x ), p0_nodeVar84.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_nodeVar93 = floor( p0_nodeVar31 );
	p0_nodeVar94 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar93, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar93, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar95 = ( ( p0_nodeVar94 ^ ( p0_nodeVar94 >> 16u ) ) * 2146121005u );
	p0_nodeVar96 = ( ( p0_nodeVar95 ^ ( p0_nodeVar95 >> 15u ) ) * 2221713035u );
	p0_nodeVar97 = ( ( p0_nodeVar95 ^ ( p0_nodeVar95 >> 13u ) ) * 2654435769u );
	p0_nodeVar98 = ( p0_nodeVar31 - p0_nodeVar93 );
	p0_nodeVar99 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar100 = ( ( p0_nodeVar99 ^ ( p0_nodeVar99 >> 16u ) ) * 2146121005u );
	p0_nodeVar101 = ( ( p0_nodeVar100 ^ ( p0_nodeVar100 >> 15u ) ) * 2221713035u );
	p0_nodeVar102 = ( ( p0_nodeVar100 ^ ( p0_nodeVar100 >> 13u ) ) * 2654435769u );
	p0_nodeVar103 = ( ( ( p0_nodeVar98 * p0_nodeVar98 ) * p0_nodeVar98 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar98 * ( ( p0_nodeVar98 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar104 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar105 = ( ( p0_nodeVar104 ^ ( p0_nodeVar104 >> 16u ) ) * 2146121005u );
	p0_nodeVar106 = ( ( p0_nodeVar105 ^ ( p0_nodeVar105 >> 15u ) ) * 2221713035u );
	p0_nodeVar107 = ( ( p0_nodeVar105 ^ ( p0_nodeVar105 >> 13u ) ) * 2654435769u );
	p0_nodeVar108 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar93 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar109 = ( ( p0_nodeVar108 ^ ( p0_nodeVar108 >> 16u ) ) * 2146121005u );
	p0_nodeVar110 = ( ( p0_nodeVar109 ^ ( p0_nodeVar109 >> 15u ) ) * 2221713035u );
	p0_nodeVar111 = ( ( p0_nodeVar109 ^ ( p0_nodeVar109 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar96 ^ ( p0_nodeVar96 >> 16u ) ) ), f32( ( p0_nodeVar97 ^ ( p0_nodeVar97 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar98 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar101 ^ ( p0_nodeVar101 >> 16u ) ) ), f32( ( p0_nodeVar102 ^ ( p0_nodeVar102 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar98 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar103.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar106 ^ ( p0_nodeVar106 >> 16u ) ) ), f32( ( p0_nodeVar107 ^ ( p0_nodeVar107 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar98 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar110 ^ ( p0_nodeVar110 >> 16u ) ) ), f32( ( p0_nodeVar111 ^ ( p0_nodeVar111 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar98 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar103.x ), p0_nodeVar103.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_nodeVar112 = floor( p0_nodeVar31 );
	p0_nodeVar113 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar112, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar112, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar114 = ( ( p0_nodeVar113 ^ ( p0_nodeVar113 >> 16u ) ) * 2146121005u );
	p0_nodeVar115 = ( ( p0_nodeVar114 ^ ( p0_nodeVar114 >> 15u ) ) * 2221713035u );
	p0_nodeVar116 = ( ( p0_nodeVar114 ^ ( p0_nodeVar114 >> 13u ) ) * 2654435769u );
	p0_nodeVar117 = ( p0_nodeVar31 - p0_nodeVar112 );
	p0_nodeVar118 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar119 = ( ( p0_nodeVar118 ^ ( p0_nodeVar118 >> 16u ) ) * 2146121005u );
	p0_nodeVar120 = ( ( p0_nodeVar119 ^ ( p0_nodeVar119 >> 15u ) ) * 2221713035u );
	p0_nodeVar121 = ( ( p0_nodeVar119 ^ ( p0_nodeVar119 >> 13u ) ) * 2654435769u );
	p0_nodeVar122 = ( ( ( p0_nodeVar117 * p0_nodeVar117 ) * p0_nodeVar117 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar117 * ( ( p0_nodeVar117 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar123 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar124 = ( ( p0_nodeVar123 ^ ( p0_nodeVar123 >> 16u ) ) * 2146121005u );
	p0_nodeVar125 = ( ( p0_nodeVar124 ^ ( p0_nodeVar124 >> 15u ) ) * 2221713035u );
	p0_nodeVar126 = ( ( p0_nodeVar124 ^ ( p0_nodeVar124 >> 13u ) ) * 2654435769u );
	p0_nodeVar127 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar112 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar128 = ( ( p0_nodeVar127 ^ ( p0_nodeVar127 >> 16u ) ) * 2146121005u );
	p0_nodeVar129 = ( ( p0_nodeVar128 ^ ( p0_nodeVar128 >> 15u ) ) * 2221713035u );
	p0_nodeVar130 = ( ( p0_nodeVar128 ^ ( p0_nodeVar128 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar115 ^ ( p0_nodeVar115 >> 16u ) ) ), f32( ( p0_nodeVar116 ^ ( p0_nodeVar116 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar117 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar120 ^ ( p0_nodeVar120 >> 16u ) ) ), f32( ( p0_nodeVar121 ^ ( p0_nodeVar121 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar117 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar122.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar125 ^ ( p0_nodeVar125 >> 16u ) ) ), f32( ( p0_nodeVar126 ^ ( p0_nodeVar126 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar117 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar129 ^ ( p0_nodeVar129 >> 16u ) ) ), f32( ( p0_nodeVar130 ^ ( p0_nodeVar130 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar117 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar122.x ), p0_nodeVar122.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_nodeVar131 = floor( p0_nodeVar31 );
	p0_nodeVar132 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar131, vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar131, vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar133 = ( ( p0_nodeVar132 ^ ( p0_nodeVar132 >> 16u ) ) * 2146121005u );
	p0_nodeVar134 = ( ( p0_nodeVar133 ^ ( p0_nodeVar133 >> 15u ) ) * 2221713035u );
	p0_nodeVar135 = ( ( p0_nodeVar133 ^ ( p0_nodeVar133 >> 13u ) ) * 2654435769u );
	p0_nodeVar136 = ( p0_nodeVar31 - p0_nodeVar131 );
	p0_nodeVar137 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar138 = ( ( p0_nodeVar137 ^ ( p0_nodeVar137 >> 16u ) ) * 2146121005u );
	p0_nodeVar139 = ( ( p0_nodeVar138 ^ ( p0_nodeVar138 >> 15u ) ) * 2221713035u );
	p0_nodeVar140 = ( ( p0_nodeVar138 ^ ( p0_nodeVar138 >> 13u ) ) * 2654435769u );
	p0_nodeVar141 = ( ( ( p0_nodeVar136 * p0_nodeVar136 ) * p0_nodeVar136 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar136 * ( ( p0_nodeVar136 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar142 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar143 = ( ( p0_nodeVar142 ^ ( p0_nodeVar142 >> 16u ) ) * 2146121005u );
	p0_nodeVar144 = ( ( p0_nodeVar143 ^ ( p0_nodeVar143 >> 15u ) ) * 2221713035u );
	p0_nodeVar145 = ( ( p0_nodeVar143 ^ ( p0_nodeVar143 >> 13u ) ) * 2654435769u );
	p0_nodeVar146 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar131 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( p0_nodeVar35 ) ) ) ).y );
	p0_nodeVar147 = ( ( p0_nodeVar146 ^ ( p0_nodeVar146 >> 16u ) ) * 2146121005u );
	p0_nodeVar148 = ( ( p0_nodeVar147 ^ ( p0_nodeVar147 >> 15u ) ) * 2221713035u );
	p0_nodeVar149 = ( ( p0_nodeVar147 ^ ( p0_nodeVar147 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( p0_nodeVar32 + ( p0_nodeVar34 * ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar134 ^ ( p0_nodeVar134 >> 16u ) ) ), f32( ( p0_nodeVar135 ^ ( p0_nodeVar135 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar136 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar139 ^ ( p0_nodeVar139 >> 16u ) ) ), f32( ( p0_nodeVar140 ^ ( p0_nodeVar140 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar136 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar141.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar144 ^ ( p0_nodeVar144 >> 16u ) ) ), f32( ( p0_nodeVar145 ^ ( p0_nodeVar145 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar136 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar148 ^ ( p0_nodeVar148 >> 16u ) ) ), f32( ( p0_nodeVar149 ^ ( p0_nodeVar149 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar136 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar141.x ), p0_nodeVar141.y ) * 0.7 ) + 0.5 ) ) );
	p0_nodeVar33 = ( p0_nodeVar33 + p0_nodeVar34 );
	p0_nodeVar34 = ( p0_nodeVar34 * 0.5 );
	p0_nodeVar31 = ( p0_nodeVar31 * vec2<f32>( 2.0 ) );
	p0_nodeVar35 = ( p0_nodeVar35 * 2.0 );
	p0_DiffuseColor = vec4<f32>( ( p0_nodeVar32 / p0_nodeVar33 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar150 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar150;

	// result

	p0_output.color = p0_nodeVar150;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

// Curl noise: threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_noise_and_tslfx.ts)
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
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : u32;
var<private> p0_nodeVar4 : u32;
var<private> p0_nodeVar5 : u32;
var<private> p0_nodeVar6 : u32;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : u32;
var<private> p0_nodeVar9 : u32;
var<private> p0_nodeVar10 : u32;
var<private> p0_nodeVar11 : u32;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : u32;
var<private> p0_nodeVar14 : u32;
var<private> p0_nodeVar15 : u32;
var<private> p0_nodeVar16 : u32;
var<private> p0_nodeVar17 : u32;
var<private> p0_nodeVar18 : u32;
var<private> p0_nodeVar19 : u32;
var<private> p0_nodeVar20 : u32;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : vec2<f32>;
var<private> p0_nodeVar23 : u32;
var<private> p0_nodeVar24 : u32;
var<private> p0_nodeVar25 : u32;
var<private> p0_nodeVar26 : u32;
var<private> p0_nodeVar27 : vec2<f32>;
var<private> p0_nodeVar28 : u32;
var<private> p0_nodeVar29 : u32;
var<private> p0_nodeVar30 : u32;
var<private> p0_nodeVar31 : u32;
var<private> p0_nodeVar32 : vec2<f32>;
var<private> p0_nodeVar33 : u32;
var<private> p0_nodeVar34 : u32;
var<private> p0_nodeVar35 : u32;
var<private> p0_nodeVar36 : u32;
var<private> p0_nodeVar37 : u32;
var<private> p0_nodeVar38 : u32;
var<private> p0_nodeVar39 : u32;
var<private> p0_nodeVar40 : u32;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : u32;
var<private> p0_nodeVar44 : u32;
var<private> p0_nodeVar45 : u32;
var<private> p0_nodeVar46 : u32;
var<private> p0_nodeVar47 : vec2<f32>;
var<private> p0_nodeVar48 : u32;
var<private> p0_nodeVar49 : u32;
var<private> p0_nodeVar50 : u32;
var<private> p0_nodeVar51 : u32;
var<private> p0_nodeVar52 : vec2<f32>;
var<private> p0_nodeVar53 : u32;
var<private> p0_nodeVar54 : u32;
var<private> p0_nodeVar55 : u32;
var<private> p0_nodeVar56 : u32;
var<private> p0_nodeVar57 : u32;
var<private> p0_nodeVar58 : u32;
var<private> p0_nodeVar59 : u32;
var<private> p0_nodeVar60 : u32;
var<private> p0_nodeVar61 : vec2<f32>;
var<private> p0_nodeVar62 : vec2<f32>;
var<private> p0_nodeVar63 : u32;
var<private> p0_nodeVar64 : u32;
var<private> p0_nodeVar65 : u32;
var<private> p0_nodeVar66 : u32;
var<private> p0_nodeVar67 : vec2<f32>;
var<private> p0_nodeVar68 : u32;
var<private> p0_nodeVar69 : u32;
var<private> p0_nodeVar70 : u32;
var<private> p0_nodeVar71 : u32;
var<private> p0_nodeVar72 : vec2<f32>;
var<private> p0_nodeVar73 : u32;
var<private> p0_nodeVar74 : u32;
var<private> p0_nodeVar75 : u32;
var<private> p0_nodeVar76 : u32;
var<private> p0_nodeVar77 : u32;
var<private> p0_nodeVar78 : u32;
var<private> p0_nodeVar79 : u32;
var<private> p0_nodeVar80 : u32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar81 : vec4<f32>;

// codes
fn p0_tsl_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_nodeVar0 = ( ( ( nodeVarying4.xy + vec2<f32>( 3.0 ) ) * vec2<f32>( ( f32(knobs.scale) / 2.0 ) ) ) + vec2<f32>( ( sin( ( f32(knobs.time) * f32(knobs.pace) ) ) + 1.0 ) ) );
	p0_nodeVar1 = ( p0_nodeVar0 + vec2<f32>( 0.1, 0.0 ) );
	p0_nodeVar2 = floor( p0_nodeVar1 );
	p0_nodeVar3 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar2, vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar2, vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar4 = ( ( p0_nodeVar3 ^ ( p0_nodeVar3 >> 16u ) ) * 2146121005u );
	p0_nodeVar5 = ( ( p0_nodeVar4 ^ ( p0_nodeVar4 >> 15u ) ) * 2221713035u );
	p0_nodeVar6 = ( ( p0_nodeVar4 ^ ( p0_nodeVar4 >> 13u ) ) * 2654435769u );
	p0_nodeVar7 = ( p0_nodeVar1 - p0_nodeVar2 );
	p0_nodeVar8 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar9 = ( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 16u ) ) * 2146121005u );
	p0_nodeVar10 = ( ( p0_nodeVar9 ^ ( p0_nodeVar9 >> 15u ) ) * 2221713035u );
	p0_nodeVar11 = ( ( p0_nodeVar9 ^ ( p0_nodeVar9 >> 13u ) ) * 2654435769u );
	p0_nodeVar12 = ( ( ( p0_nodeVar7 * p0_nodeVar7 ) * p0_nodeVar7 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar7 * ( ( p0_nodeVar7 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar13 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar14 = ( ( p0_nodeVar13 ^ ( p0_nodeVar13 >> 16u ) ) * 2146121005u );
	p0_nodeVar15 = ( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 15u ) ) * 2221713035u );
	p0_nodeVar16 = ( ( p0_nodeVar14 ^ ( p0_nodeVar14 >> 13u ) ) * 2654435769u );
	p0_nodeVar17 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar2 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar18 = ( ( p0_nodeVar17 ^ ( p0_nodeVar17 >> 16u ) ) * 2146121005u );
	p0_nodeVar19 = ( ( p0_nodeVar18 ^ ( p0_nodeVar18 >> 15u ) ) * 2221713035u );
	p0_nodeVar20 = ( ( p0_nodeVar18 ^ ( p0_nodeVar18 >> 13u ) ) * 2654435769u );
	p0_nodeVar21 = ( p0_nodeVar0 + vec2<f32>( 0.1, 0.0 ).yx );
	p0_nodeVar22 = floor( p0_nodeVar21 );
	p0_nodeVar23 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar22, vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar22, vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar24 = ( ( p0_nodeVar23 ^ ( p0_nodeVar23 >> 16u ) ) * 2146121005u );
	p0_nodeVar25 = ( ( p0_nodeVar24 ^ ( p0_nodeVar24 >> 15u ) ) * 2221713035u );
	p0_nodeVar26 = ( ( p0_nodeVar24 ^ ( p0_nodeVar24 >> 13u ) ) * 2654435769u );
	p0_nodeVar27 = ( p0_nodeVar21 - p0_nodeVar22 );
	p0_nodeVar28 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar29 = ( ( p0_nodeVar28 ^ ( p0_nodeVar28 >> 16u ) ) * 2146121005u );
	p0_nodeVar30 = ( ( p0_nodeVar29 ^ ( p0_nodeVar29 >> 15u ) ) * 2221713035u );
	p0_nodeVar31 = ( ( p0_nodeVar29 ^ ( p0_nodeVar29 >> 13u ) ) * 2654435769u );
	p0_nodeVar32 = ( ( ( p0_nodeVar27 * p0_nodeVar27 ) * p0_nodeVar27 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar27 * ( ( p0_nodeVar27 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar33 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar34 = ( ( p0_nodeVar33 ^ ( p0_nodeVar33 >> 16u ) ) * 2146121005u );
	p0_nodeVar35 = ( ( p0_nodeVar34 ^ ( p0_nodeVar34 >> 15u ) ) * 2221713035u );
	p0_nodeVar36 = ( ( p0_nodeVar34 ^ ( p0_nodeVar34 >> 13u ) ) * 2654435769u );
	p0_nodeVar37 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar22 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar38 = ( ( p0_nodeVar37 ^ ( p0_nodeVar37 >> 16u ) ) * 2146121005u );
	p0_nodeVar39 = ( ( p0_nodeVar38 ^ ( p0_nodeVar38 >> 15u ) ) * 2221713035u );
	p0_nodeVar40 = ( ( p0_nodeVar38 ^ ( p0_nodeVar38 >> 13u ) ) * 2654435769u );
	p0_nodeVar41 = ( p0_nodeVar0 - vec2<f32>( 0.1, 0.0 ) );
	p0_nodeVar42 = floor( p0_nodeVar41 );
	p0_nodeVar43 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar42, vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar42, vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar44 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 16u ) ) * 2146121005u );
	p0_nodeVar45 = ( ( p0_nodeVar44 ^ ( p0_nodeVar44 >> 15u ) ) * 2221713035u );
	p0_nodeVar46 = ( ( p0_nodeVar44 ^ ( p0_nodeVar44 >> 13u ) ) * 2654435769u );
	p0_nodeVar47 = ( p0_nodeVar41 - p0_nodeVar42 );
	p0_nodeVar48 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar49 = ( ( p0_nodeVar48 ^ ( p0_nodeVar48 >> 16u ) ) * 2146121005u );
	p0_nodeVar50 = ( ( p0_nodeVar49 ^ ( p0_nodeVar49 >> 15u ) ) * 2221713035u );
	p0_nodeVar51 = ( ( p0_nodeVar49 ^ ( p0_nodeVar49 >> 13u ) ) * 2654435769u );
	p0_nodeVar52 = ( ( ( p0_nodeVar47 * p0_nodeVar47 ) * p0_nodeVar47 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar47 * ( ( p0_nodeVar47 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar53 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar54 = ( ( p0_nodeVar53 ^ ( p0_nodeVar53 >> 16u ) ) * 2146121005u );
	p0_nodeVar55 = ( ( p0_nodeVar54 ^ ( p0_nodeVar54 >> 15u ) ) * 2221713035u );
	p0_nodeVar56 = ( ( p0_nodeVar54 ^ ( p0_nodeVar54 >> 13u ) ) * 2654435769u );
	p0_nodeVar57 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar42 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar58 = ( ( p0_nodeVar57 ^ ( p0_nodeVar57 >> 16u ) ) * 2146121005u );
	p0_nodeVar59 = ( ( p0_nodeVar58 ^ ( p0_nodeVar58 >> 15u ) ) * 2221713035u );
	p0_nodeVar60 = ( ( p0_nodeVar58 ^ ( p0_nodeVar58 >> 13u ) ) * 2654435769u );
	p0_nodeVar61 = ( p0_nodeVar0 - vec2<f32>( 0.1, 0.0 ).yx );
	p0_nodeVar62 = floor( p0_nodeVar61 );
	p0_nodeVar63 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar62, vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( p0_nodeVar62, vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar64 = ( ( p0_nodeVar63 ^ ( p0_nodeVar63 >> 16u ) ) * 2146121005u );
	p0_nodeVar65 = ( ( p0_nodeVar64 ^ ( p0_nodeVar64 >> 15u ) ) * 2221713035u );
	p0_nodeVar66 = ( ( p0_nodeVar64 ^ ( p0_nodeVar64 >> 13u ) ) * 2654435769u );
	p0_nodeVar67 = ( p0_nodeVar61 - p0_nodeVar62 );
	p0_nodeVar68 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar69 = ( ( p0_nodeVar68 ^ ( p0_nodeVar68 >> 16u ) ) * 2146121005u );
	p0_nodeVar70 = ( ( p0_nodeVar69 ^ ( p0_nodeVar69 >> 15u ) ) * 2221713035u );
	p0_nodeVar71 = ( ( p0_nodeVar69 ^ ( p0_nodeVar69 >> 13u ) ) * 2654435769u );
	p0_nodeVar72 = ( ( ( p0_nodeVar67 * p0_nodeVar67 ) * p0_nodeVar67 ) * ( vec2<f32>( 10.0 ) + ( p0_nodeVar67 * ( ( p0_nodeVar67 * vec2<f32>( 6.0 ) ) - vec2<f32>( 15.0 ) ) ) ) );
	p0_nodeVar73 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar74 = ( ( p0_nodeVar73 ^ ( p0_nodeVar73 >> 16u ) ) * 2146121005u );
	p0_nodeVar75 = ( ( p0_nodeVar74 ^ ( p0_nodeVar74 >> 15u ) ) * 2221713035u );
	p0_nodeVar76 = ( ( p0_nodeVar74 ^ ( p0_nodeVar74 >> 13u ) ) * 2654435769u );
	p0_nodeVar77 = ( ( vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).x * 2246822519u ) + vec2<u32>( floor( p0_tsl_mod_vec2( ( p0_nodeVar62 + vec2<f32>( 1.0, 1.0 ) ), vec2<f32>( 13.0 ) ) ) ).y );
	p0_nodeVar78 = ( ( p0_nodeVar77 ^ ( p0_nodeVar77 >> 16u ) ) * 2146121005u );
	p0_nodeVar79 = ( ( p0_nodeVar78 ^ ( p0_nodeVar78 >> 15u ) ) * 2221713035u );
	p0_nodeVar80 = ( ( p0_nodeVar78 ^ ( p0_nodeVar78 >> 13u ) ) * 2654435769u );
	p0_DiffuseColor = vec4<f32>( vec3<f32>( ( ( ( vec2<f32>( ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar5 ^ ( p0_nodeVar5 >> 16u ) ) ), f32( ( p0_nodeVar6 ^ ( p0_nodeVar6 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar7 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar10 ^ ( p0_nodeVar10 >> 16u ) ) ), f32( ( p0_nodeVar11 ^ ( p0_nodeVar11 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar7 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar12.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 16u ) ) ), f32( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar7 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar19 ^ ( p0_nodeVar19 >> 16u ) ) ), f32( ( p0_nodeVar20 ^ ( p0_nodeVar20 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar7 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar12.x ), p0_nodeVar12.y ) * 0.7 ) + 0.5 ), ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar25 ^ ( p0_nodeVar25 >> 16u ) ) ), f32( ( p0_nodeVar26 ^ ( p0_nodeVar26 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar27 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar30 ^ ( p0_nodeVar30 >> 16u ) ) ), f32( ( p0_nodeVar31 ^ ( p0_nodeVar31 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar27 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar32.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar35 ^ ( p0_nodeVar35 >> 16u ) ) ), f32( ( p0_nodeVar36 ^ ( p0_nodeVar36 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar27 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar39 ^ ( p0_nodeVar39 >> 16u ) ) ), f32( ( p0_nodeVar40 ^ ( p0_nodeVar40 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar27 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar32.x ), p0_nodeVar32.y ) * 0.7 ) + 0.5 ) ) - vec2<f32>( ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar45 ^ ( p0_nodeVar45 >> 16u ) ) ), f32( ( p0_nodeVar46 ^ ( p0_nodeVar46 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar47 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar50 ^ ( p0_nodeVar50 >> 16u ) ) ), f32( ( p0_nodeVar51 ^ ( p0_nodeVar51 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar47 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar52.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar55 ^ ( p0_nodeVar55 >> 16u ) ) ), f32( ( p0_nodeVar56 ^ ( p0_nodeVar56 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar47 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar59 ^ ( p0_nodeVar59 >> 16u ) ) ), f32( ( p0_nodeVar60 ^ ( p0_nodeVar60 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar47 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar52.x ), p0_nodeVar52.y ) * 0.7 ) + 0.5 ), ( ( mix( mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar65 ^ ( p0_nodeVar65 >> 16u ) ) ), f32( ( p0_nodeVar66 ^ ( p0_nodeVar66 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar67 - vec2<f32>( 0.0, 0.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar70 ^ ( p0_nodeVar70 >> 16u ) ) ), f32( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar67 - vec2<f32>( 1.0, 0.0 ) ) ), p0_nodeVar72.x ), mix( dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar75 ^ ( p0_nodeVar75 >> 16u ) ) ), f32( ( p0_nodeVar76 ^ ( p0_nodeVar76 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar67 - vec2<f32>( 0.0, 1.0 ) ) ), dot( normalize( ( ( vec2<f32>( f32( ( p0_nodeVar79 ^ ( p0_nodeVar79 >> 16u ) ) ), f32( ( p0_nodeVar80 ^ ( p0_nodeVar80 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) - vec2<f32>( 0.5 ) ) ), ( p0_nodeVar67 - vec2<f32>( 1.0, 1.0 ) ) ), p0_nodeVar72.x ), p0_nodeVar72.y ) * 0.7 ) + 0.5 ) ) ) / vec2<f32>( vec2<f32>( 0.1, 0.0 ).x ) ) * vec2<f32>( 0.5 ) ), 0.0 ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar81 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar81;

	// result

	p0_output.color = p0_nodeVar81;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

// Scratches noise: threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions), by three.js's own builder (engine/tsl/noise_fx_shelf.ts)
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
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : u32;
var<private> p0_nodeVar7 : u32;
var<private> p0_nodeVar8 : u32;
var<private> p0_nodeVar9 : u32;
var<private> p0_nodeVar10 : vec2<f32>;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : vec2<f32>;
var<private> p0_nodeVar14 : vec2<f32>;
var<private> p0_nodeVar15 : u32;
var<private> p0_nodeVar16 : u32;
var<private> p0_nodeVar17 : u32;
var<private> p0_nodeVar18 : u32;
var<private> p0_nodeVar19 : vec2<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : vec2<f32>;
var<private> p0_nodeVar23 : vec2<f32>;
var<private> p0_nodeVar24 : u32;
var<private> p0_nodeVar25 : u32;
var<private> p0_nodeVar26 : u32;
var<private> p0_nodeVar27 : u32;
var<private> p0_nodeVar28 : vec2<f32>;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : vec2<f32>;
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : vec2<f32>;
var<private> p0_nodeVar33 : u32;
var<private> p0_nodeVar34 : u32;
var<private> p0_nodeVar35 : u32;
var<private> p0_nodeVar36 : u32;
var<private> p0_nodeVar37 : vec2<f32>;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : vec2<f32>;
var<private> p0_nodeVar40 : vec2<f32>;
var<private> p0_nodeVar41 : vec2<f32>;
var<private> p0_nodeVar42 : u32;
var<private> p0_nodeVar43 : u32;
var<private> p0_nodeVar44 : u32;
var<private> p0_nodeVar45 : u32;
var<private> p0_nodeVar46 : vec2<f32>;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec2<f32>;
var<private> p0_nodeVar49 : vec2<f32>;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : u32;
var<private> p0_nodeVar52 : u32;
var<private> p0_nodeVar53 : u32;
var<private> p0_nodeVar54 : u32;
var<private> p0_nodeVar55 : vec2<f32>;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : vec2<f32>;
var<private> p0_nodeVar58 : vec2<f32>;
var<private> p0_nodeVar59 : vec2<f32>;
var<private> p0_nodeVar60 : u32;
var<private> p0_nodeVar61 : u32;
var<private> p0_nodeVar62 : u32;
var<private> p0_nodeVar63 : u32;
var<private> p0_nodeVar64 : vec2<f32>;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : vec2<f32>;
var<private> p0_nodeVar67 : vec2<f32>;
var<private> p0_nodeVar68 : vec2<f32>;
var<private> p0_nodeVar69 : u32;
var<private> p0_nodeVar70 : u32;
var<private> p0_nodeVar71 : u32;
var<private> p0_nodeVar72 : u32;
var<private> p0_nodeVar73 : vec2<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : vec2<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar76 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_nodeVar0 = 0.0;
	p0_nodeVar1 = ( ( ( nodeVarying4.xy + vec2<f32>( 3.0 ) ) * vec2<f32>( ( f32(knobs.scale) / 2.0 ) ) ) + vec2<f32>( ( sin( ( f32(knobs.time) * f32(knobs.pace) ) ) + 1.0 ) ) );
	p0_nodeVar2 = p0_nodeVar1;
	p0_nodeVar3 = ( length( fwidth( p0_nodeVar1 ) ) * 3.0 );
	p0_nodeVar4 = floor( p0_nodeVar2 );
	p0_nodeVar5 = ( ( ( p0_nodeVar2 - p0_nodeVar4 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar6 = ( ( vec2<u32>( floor( p0_nodeVar4 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar4 ) ).y );
	p0_nodeVar7 = ( ( p0_nodeVar6 ^ ( p0_nodeVar6 >> 16u ) ) * 2146121005u );
	p0_nodeVar8 = ( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 15u ) ) * 2221713035u );
	p0_nodeVar9 = ( ( p0_nodeVar7 ^ ( p0_nodeVar7 >> 13u ) ) * 2654435769u );
	p0_nodeVar10 = ( ( vec2<f32>( f32( ( p0_nodeVar8 ^ ( p0_nodeVar8 >> 16u ) ) ), f32( ( p0_nodeVar9 ^ ( p0_nodeVar9 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar11 = ( p0_nodeVar10.x + p0_nodeVar10.y );
	p0_nodeVar12 = ( ( ( p0_nodeVar5 * vec2<f32>( cos( p0_nodeVar11 ) ) ) + ( vec2<f32>( ( - p0_nodeVar5.y ), p0_nodeVar5.x ) * vec2<f32>( sin( p0_nodeVar11 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar10.x - p0_nodeVar10.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar12.x - ( cos( ( p0_nodeVar10.x + ( p0_nodeVar12.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar12.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar13 = floor( p0_nodeVar2 );
	p0_nodeVar14 = ( ( ( p0_nodeVar2 - p0_nodeVar13 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar15 = ( ( vec2<u32>( floor( p0_nodeVar13 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar13 ) ).y );
	p0_nodeVar16 = ( ( p0_nodeVar15 ^ ( p0_nodeVar15 >> 16u ) ) * 2146121005u );
	p0_nodeVar17 = ( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 15u ) ) * 2221713035u );
	p0_nodeVar18 = ( ( p0_nodeVar16 ^ ( p0_nodeVar16 >> 13u ) ) * 2654435769u );
	p0_nodeVar19 = ( ( vec2<f32>( f32( ( p0_nodeVar17 ^ ( p0_nodeVar17 >> 16u ) ) ), f32( ( p0_nodeVar18 ^ ( p0_nodeVar18 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar20 = ( p0_nodeVar19.x + p0_nodeVar19.y );
	p0_nodeVar21 = ( ( ( p0_nodeVar14 * vec2<f32>( cos( p0_nodeVar20 ) ) ) + ( vec2<f32>( ( - p0_nodeVar14.y ), p0_nodeVar14.x ) * vec2<f32>( sin( p0_nodeVar20 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar19.x - p0_nodeVar19.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar21.x - ( cos( ( p0_nodeVar19.x + ( p0_nodeVar21.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar21.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar22 = floor( p0_nodeVar2 );
	p0_nodeVar23 = ( ( ( p0_nodeVar2 - p0_nodeVar22 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar24 = ( ( vec2<u32>( floor( p0_nodeVar22 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar22 ) ).y );
	p0_nodeVar25 = ( ( p0_nodeVar24 ^ ( p0_nodeVar24 >> 16u ) ) * 2146121005u );
	p0_nodeVar26 = ( ( p0_nodeVar25 ^ ( p0_nodeVar25 >> 15u ) ) * 2221713035u );
	p0_nodeVar27 = ( ( p0_nodeVar25 ^ ( p0_nodeVar25 >> 13u ) ) * 2654435769u );
	p0_nodeVar28 = ( ( vec2<f32>( f32( ( p0_nodeVar26 ^ ( p0_nodeVar26 >> 16u ) ) ), f32( ( p0_nodeVar27 ^ ( p0_nodeVar27 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar29 = ( p0_nodeVar28.x + p0_nodeVar28.y );
	p0_nodeVar30 = ( ( ( p0_nodeVar23 * vec2<f32>( cos( p0_nodeVar29 ) ) ) + ( vec2<f32>( ( - p0_nodeVar23.y ), p0_nodeVar23.x ) * vec2<f32>( sin( p0_nodeVar29 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar28.x - p0_nodeVar28.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar30.x - ( cos( ( p0_nodeVar28.x + ( p0_nodeVar30.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar30.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar31 = floor( p0_nodeVar2 );
	p0_nodeVar32 = ( ( ( p0_nodeVar2 - p0_nodeVar31 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar33 = ( ( vec2<u32>( floor( p0_nodeVar31 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar31 ) ).y );
	p0_nodeVar34 = ( ( p0_nodeVar33 ^ ( p0_nodeVar33 >> 16u ) ) * 2146121005u );
	p0_nodeVar35 = ( ( p0_nodeVar34 ^ ( p0_nodeVar34 >> 15u ) ) * 2221713035u );
	p0_nodeVar36 = ( ( p0_nodeVar34 ^ ( p0_nodeVar34 >> 13u ) ) * 2654435769u );
	p0_nodeVar37 = ( ( vec2<f32>( f32( ( p0_nodeVar35 ^ ( p0_nodeVar35 >> 16u ) ) ), f32( ( p0_nodeVar36 ^ ( p0_nodeVar36 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar38 = ( p0_nodeVar37.x + p0_nodeVar37.y );
	p0_nodeVar39 = ( ( ( p0_nodeVar32 * vec2<f32>( cos( p0_nodeVar38 ) ) ) + ( vec2<f32>( ( - p0_nodeVar32.y ), p0_nodeVar32.x ) * vec2<f32>( sin( p0_nodeVar38 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar37.x - p0_nodeVar37.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar39.x - ( cos( ( p0_nodeVar37.x + ( p0_nodeVar39.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar39.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar40 = floor( p0_nodeVar2 );
	p0_nodeVar41 = ( ( ( p0_nodeVar2 - p0_nodeVar40 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar42 = ( ( vec2<u32>( floor( p0_nodeVar40 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar40 ) ).y );
	p0_nodeVar43 = ( ( p0_nodeVar42 ^ ( p0_nodeVar42 >> 16u ) ) * 2146121005u );
	p0_nodeVar44 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 15u ) ) * 2221713035u );
	p0_nodeVar45 = ( ( p0_nodeVar43 ^ ( p0_nodeVar43 >> 13u ) ) * 2654435769u );
	p0_nodeVar46 = ( ( vec2<f32>( f32( ( p0_nodeVar44 ^ ( p0_nodeVar44 >> 16u ) ) ), f32( ( p0_nodeVar45 ^ ( p0_nodeVar45 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar47 = ( p0_nodeVar46.x + p0_nodeVar46.y );
	p0_nodeVar48 = ( ( ( p0_nodeVar41 * vec2<f32>( cos( p0_nodeVar47 ) ) ) + ( vec2<f32>( ( - p0_nodeVar41.y ), p0_nodeVar41.x ) * vec2<f32>( sin( p0_nodeVar47 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar46.x - p0_nodeVar46.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar48.x - ( cos( ( p0_nodeVar46.x + ( p0_nodeVar48.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar48.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar49 = floor( p0_nodeVar2 );
	p0_nodeVar50 = ( ( ( p0_nodeVar2 - p0_nodeVar49 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar51 = ( ( vec2<u32>( floor( p0_nodeVar49 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar49 ) ).y );
	p0_nodeVar52 = ( ( p0_nodeVar51 ^ ( p0_nodeVar51 >> 16u ) ) * 2146121005u );
	p0_nodeVar53 = ( ( p0_nodeVar52 ^ ( p0_nodeVar52 >> 15u ) ) * 2221713035u );
	p0_nodeVar54 = ( ( p0_nodeVar52 ^ ( p0_nodeVar52 >> 13u ) ) * 2654435769u );
	p0_nodeVar55 = ( ( vec2<f32>( f32( ( p0_nodeVar53 ^ ( p0_nodeVar53 >> 16u ) ) ), f32( ( p0_nodeVar54 ^ ( p0_nodeVar54 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar56 = ( p0_nodeVar55.x + p0_nodeVar55.y );
	p0_nodeVar57 = ( ( ( p0_nodeVar50 * vec2<f32>( cos( p0_nodeVar56 ) ) ) + ( vec2<f32>( ( - p0_nodeVar50.y ), p0_nodeVar50.x ) * vec2<f32>( sin( p0_nodeVar56 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar55.x - p0_nodeVar55.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar57.x - ( cos( ( p0_nodeVar55.x + ( p0_nodeVar57.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar57.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar58 = floor( p0_nodeVar2 );
	p0_nodeVar59 = ( ( ( p0_nodeVar2 - p0_nodeVar58 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar60 = ( ( vec2<u32>( floor( p0_nodeVar58 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar58 ) ).y );
	p0_nodeVar61 = ( ( p0_nodeVar60 ^ ( p0_nodeVar60 >> 16u ) ) * 2146121005u );
	p0_nodeVar62 = ( ( p0_nodeVar61 ^ ( p0_nodeVar61 >> 15u ) ) * 2221713035u );
	p0_nodeVar63 = ( ( p0_nodeVar61 ^ ( p0_nodeVar61 >> 13u ) ) * 2654435769u );
	p0_nodeVar64 = ( ( vec2<f32>( f32( ( p0_nodeVar62 ^ ( p0_nodeVar62 >> 16u ) ) ), f32( ( p0_nodeVar63 ^ ( p0_nodeVar63 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar65 = ( p0_nodeVar64.x + p0_nodeVar64.y );
	p0_nodeVar66 = ( ( ( p0_nodeVar59 * vec2<f32>( cos( p0_nodeVar65 ) ) ) + ( vec2<f32>( ( - p0_nodeVar59.y ), p0_nodeVar59.x ) * vec2<f32>( sin( p0_nodeVar65 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar64.x - p0_nodeVar64.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar66.x - ( cos( ( p0_nodeVar64.x + ( p0_nodeVar66.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar66.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_nodeVar67 = floor( p0_nodeVar2 );
	p0_nodeVar68 = ( ( ( p0_nodeVar2 - p0_nodeVar67 ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) );
	p0_nodeVar69 = ( ( vec2<u32>( floor( p0_nodeVar67 ) ).x * 2246822519u ) + vec2<u32>( floor( p0_nodeVar67 ) ).y );
	p0_nodeVar70 = ( ( p0_nodeVar69 ^ ( p0_nodeVar69 >> 16u ) ) * 2146121005u );
	p0_nodeVar71 = ( ( p0_nodeVar70 ^ ( p0_nodeVar70 >> 15u ) ) * 2221713035u );
	p0_nodeVar72 = ( ( p0_nodeVar70 ^ ( p0_nodeVar70 >> 13u ) ) * 2654435769u );
	p0_nodeVar73 = ( ( vec2<f32>( f32( ( p0_nodeVar71 ^ ( p0_nodeVar71 >> 16u ) ) ), f32( ( p0_nodeVar72 ^ ( p0_nodeVar72 >> 16u ) ) ) ) / vec2<f32>( 4294967295.0 ) ) * vec2<f32>( 3104.0, 554.0 ) );
	p0_nodeVar74 = ( p0_nodeVar73.x + p0_nodeVar73.y );
	p0_nodeVar75 = ( ( ( p0_nodeVar68 * vec2<f32>( cos( p0_nodeVar74 ) ) ) + ( vec2<f32>( ( - p0_nodeVar68.y ), p0_nodeVar68.x ) * vec2<f32>( sin( p0_nodeVar74 ) ) ) ) + vec2<f32>( sin( ( p0_nodeVar73.x - p0_nodeVar73.y ) ) ) );
	p0_nodeVar0 = max( p0_nodeVar0, ( smoothstep( ( 0.02 + p0_nodeVar3 ), ( 0.02 - p0_nodeVar3 ), abs( ( p0_nodeVar75.x - ( cos( ( p0_nodeVar73.x + ( p0_nodeVar75.y * 1.57 ) ) ) * 0.5 ) ) ) ) * ( ( p0_nodeVar75.y * 0.5 ) + 0.5 ) ) );
	p0_nodeVar2 = ( ( mat2x2<f32>( 1.0, -0.7, 0.7, 1.0 ) * p0_nodeVar2 ) - vec2<f32>( 12.31 ) );
	p0_nodeVar3 = ( p0_nodeVar3 * 1.22 );
	p0_DiffuseColor = vec4<f32>( p0_nodeVar0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar76 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar76;

	// result

	p0_output.color = p0_nodeVar76;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

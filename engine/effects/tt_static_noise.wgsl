// Static noise: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture renders a static noise with possibility to update
// --track@scale:Scale,0,4,2,0.04
// --track@balance:Balance,-3,3,0,0.06
// --track@contrast:Contrast,-2,2,0,0.04
// --track@delay:Delay,0,1,0,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  balance: f32,
  contrast: f32,
  delay: f32,
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
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;

// codes
fn p0_vnoise ( v : vec3<f32> ) -> f32 {

	


	return ( ( fract( ( sin( dot( v, vec3<f32>( 12.9898, 78.233, -97.5123 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

}

fn p0_mx_floor ( x : f32 ) -> i32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = x;

	return i32( floor( p0_nodeVar0 ) );

}

fn p0_mx_fade ( t : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = t;

	return ( ( ( p0_nodeVar0 * p0_nodeVar0 ) * p0_nodeVar0 ) * ( ( p0_nodeVar0 * ( ( p0_nodeVar0 * 6.0 ) - 15.0 ) ) + 10.0 ) );

}

fn p0_mx_rotl32 ( x : u32, k : i32 ) -> u32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : u32;

	p0_nodeVar0 = k;
	nodeVar1 = x;

	return ( ( nodeVar1 << u32( p0_nodeVar0 ) ) | ( nodeVar1 >> u32( ( 32 - p0_nodeVar0 ) ) ) );

}

fn p0_mx_bjfinal ( a : u32, b : u32, c : u32 ) -> u32 {

	var p0_nodeVar0 : u32;
	var nodeVar1 : u32;
	var nodeVar2 : u32;

	p0_nodeVar0 = c;
	nodeVar1 = b;
	nodeVar2 = a;
	p0_nodeVar0 = ( p0_nodeVar0 ^ nodeVar1 );
	p0_nodeVar0 = ( p0_nodeVar0 - p0_mx_rotl32( nodeVar1, 14 ) );
	nodeVar2 = ( nodeVar2 ^ p0_nodeVar0 );
	nodeVar2 = ( nodeVar2 - p0_mx_rotl32( p0_nodeVar0, 11 ) );
	nodeVar1 = ( nodeVar1 ^ nodeVar2 );
	nodeVar1 = ( nodeVar1 - p0_mx_rotl32( nodeVar2, 25 ) );
	p0_nodeVar0 = ( p0_nodeVar0 ^ nodeVar1 );
	p0_nodeVar0 = ( p0_nodeVar0 - p0_mx_rotl32( nodeVar1, 16 ) );
	nodeVar2 = ( nodeVar2 ^ p0_nodeVar0 );
	nodeVar2 = ( nodeVar2 - p0_mx_rotl32( p0_nodeVar0, 4 ) );
	nodeVar1 = ( nodeVar1 ^ nodeVar2 );
	nodeVar1 = ( nodeVar1 - p0_mx_rotl32( nodeVar2, 14 ) );
	p0_nodeVar0 = ( p0_nodeVar0 ^ nodeVar1 );
	p0_nodeVar0 = ( p0_nodeVar0 - p0_mx_rotl32( nodeVar1, 24 ) );

	return p0_nodeVar0;

}

fn p0_mx_hash_int_1 ( x : i32, y : i32 ) -> u32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : i32;
	var nodeVar2 : u32;
	var nodeVar3 : u32;
	var nodeVar4 : u32;
	var nodeVar5 : u32;

	p0_nodeVar0 = y;
	nodeVar1 = x;
	nodeVar2 = 2u;
	nodeVar3 = 0u;
	nodeVar4 = 0u;
	nodeVar5 = 0u;
	nodeVar5 = ( ( 3735928559u + ( nodeVar2 << 2u ) ) + 13u );
	nodeVar4 = nodeVar5;
	nodeVar3 = nodeVar4;
	nodeVar3 = ( nodeVar3 + u32( nodeVar1 ) );
	nodeVar4 = ( nodeVar4 + u32( p0_nodeVar0 ) );

	return p0_mx_bjfinal( nodeVar3, nodeVar4, nodeVar5 );

}

fn p0_mx_select ( b : bool, t : f32, f : f32 ) -> f32 {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : bool;
	var nodeVar3 : f32;

	p0_nodeVar0 = f;
	nodeVar1 = t;
	nodeVar2 = b;

	return select( p0_nodeVar0, nodeVar1, nodeVar2 );

}

fn p0_mx_negate_if ( val : f32, b : bool ) -> f32 {

	var p0_nodeVar0 : bool;
	var nodeVar1 : f32;
	var nodeVar2 : f32;

	p0_nodeVar0 = b;
	nodeVar1 = val;

	return select( nodeVar1, ( - nodeVar1 ), p0_nodeVar0 );

}

fn p0_mx_gradient_float_0 ( hash : u32, x : f32, y : f32 ) -> f32 {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : u32;
	var nodeVar3 : u32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;

	p0_nodeVar0 = y;
	nodeVar1 = x;
	nodeVar2 = hash;
	nodeVar3 = ( nodeVar2 & 7u );
	nodeVar4 = p0_mx_select( ( nodeVar3 < 4u ), nodeVar1, p0_nodeVar0 );
	nodeVar5 = ( 2.0 * p0_mx_select( ( nodeVar3 < 4u ), p0_nodeVar0, nodeVar1 ) );

	return ( p0_mx_negate_if( nodeVar4, bool( ( nodeVar3 & 1u ) ) ) + p0_mx_negate_if( nodeVar5, bool( ( nodeVar3 & 2u ) ) ) );

}

fn p0_mx_bilerp_0 ( v0 : f32, v1 : f32, v2 : f32, v3 : f32, s : f32, t : f32 ) -> f32 {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : f32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;

	p0_nodeVar0 = t;
	nodeVar1 = s;
	nodeVar2 = v3;
	nodeVar3 = v2;
	nodeVar4 = v1;
	nodeVar5 = v0;
	nodeVar6 = ( 1.0 - nodeVar1 );

	return ( ( ( 1.0 - p0_nodeVar0 ) * ( ( nodeVar5 * nodeVar6 ) + ( nodeVar4 * nodeVar1 ) ) ) + ( p0_nodeVar0 * ( ( nodeVar3 * nodeVar6 ) + ( nodeVar2 * nodeVar1 ) ) ) );

}

fn p0_mx_gradient_scale2d_0 ( v : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = v;

	return ( 0.6616 * p0_nodeVar0 );

}

fn p0_mx_perlin_noise_float_0 ( p : vec2<f32> ) -> f32 {

	var p0_nodeVar0 : vec2<f32>;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : f32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : f32;

	p0_nodeVar0 = p;
	nodeVar1 = 0;
	nodeVar2 = 0;
	nodeVar3 = p0_nodeVar0.x;
	nodeVar1 = p0_mx_floor( nodeVar3 );
	nodeVar4 = ( nodeVar3 - f32( nodeVar1 ) );
	nodeVar5 = p0_nodeVar0.y;
	nodeVar2 = p0_mx_floor( nodeVar5 );
	nodeVar6 = ( nodeVar5 - f32( nodeVar2 ) );
	nodeVar7 = p0_mx_fade( nodeVar4 );
	nodeVar8 = p0_mx_fade( nodeVar6 );
	nodeVar9 = p0_mx_bilerp_0( p0_mx_gradient_float_0( p0_mx_hash_int_1( nodeVar1, nodeVar2 ), nodeVar4, nodeVar6 ), p0_mx_gradient_float_0( p0_mx_hash_int_1( ( nodeVar1 + 1 ), nodeVar2 ), ( nodeVar4 - 1.0 ), nodeVar6 ), p0_mx_gradient_float_0( p0_mx_hash_int_1( nodeVar1, ( nodeVar2 + 1 ) ), nodeVar4, ( nodeVar6 - 1.0 ) ), p0_mx_gradient_float_0( p0_mx_hash_int_1( ( nodeVar1 + 1 ), ( nodeVar2 + 1 ) ), ( nodeVar4 - 1.0 ), ( nodeVar6 - 1.0 ) ), nodeVar7, nodeVar8 );

	return p0_mx_gradient_scale2d_0( nodeVar9 );

}

fn p0_staticNoiseRaw ( position : vec2<f32>, time : f32, scale : f32, balance : f32, contrast : f32, delay : f32, seed : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = exp( ( ( delay - 1.0 ) * 5.0 ) );

	return vec3<f32>( ( ( ( ( clamp( 0.0, 1.0, ( ( p0_mx_perlin_noise_float_0( ( ( ( position / vec2<f32>( exp( scale ) ) ) + vec2<f32>( seed ) ) + vec2<f32>( ( p0_vnoise( vec3<f32>( sin( ( round( ( time / p0_nodeVar0 ) ) * p0_nodeVar0 ) ) ) ) * 1000.0 ) ) ) ) * 1.0 ) + 0.0 ) ) * 0.5 ) * exp( contrast ) ) + 0.5 ) + balance ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let fragCoord = vec4f(door_uv * knobs.resolution, 0.0, 1.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_staticNoiseRaw( fragCoord.xy, f32(knobs.time), f32(knobs.scale), f32(knobs.balance), f32(knobs.contrast), f32(knobs.delay), 0.0 ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar0 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar0;

	// result

	p0_output.color = p0_nodeVar0;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

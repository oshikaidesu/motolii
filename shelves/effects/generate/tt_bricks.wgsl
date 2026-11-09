// Bricks: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:Generate
// --about:This texture recreates various bricks wall &ndash; mossy bricks, Manchester red
// --track@scale:Scale,0,4,2,0.04
// --track@brickSize_x:Brick Size x,0.1,10,2,0.01
// --track@brickSize_y:Brick Size y,0.1,10,1,0.01
// --track@brickSize_z:Brick Size z,0.1,10,2,0.01
// --track@brickShift:Brick Shift,1,4,2,0.03
// --track@jointSize:Joint Size,0,0.2,0.05,0.002
// --track@jointSpan:Joint Span,0,1,0.5,0.01
// --track@jointJitter:Joint Jitter,0,1,0.5,0.01
// --track@jointBlur:Joint Blur,0,1,0.03,0.01
// --track@noiseSize:Noise Size,0,1,0.5,0.01
// --track@noiseStrength:Noise Strength,0,1,0.2,0.01
// --track@colorShade:Color Shade,0,1,0.5,0.01
// --track@color_x:Color r,0,1,1,0.001
// --track@color_y:Color g,0,1,0.05126945836711539,0.001
// --track@color_z:Color b,0,1,0,0.001
// --track@additional_x:Additional r,0,1,0.6307571363387763,0.001
// --track@additional_y:Additional g,0,1,0.3515325994898463,0.001
// --track@additional_z:Additional b,0,1,0.02955683443236377,0.001
// --track@background_x:Background r,0,1,0.4019777798219466,0.001
// --track@background_y:Background g,0,1,0.4019777798219466,0.001
// --track@background_z:Background b,0,1,0.4019777798219466,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  brickSize: vec3<f32>,
  brickShift: f32,
  jointSize: f32,
  jointSpan: f32,
  jointJitter: f32,
  jointBlur: f32,
  noiseSize: f32,
  noiseStrength: f32,
  colorShade: f32,
  color: vec3<f32>,
  additional: vec3<f32>,
  background: vec3<f32>,
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
fn p0_remapExp ( x : f32, fromMin : f32, fromMax : f32, toMin : f32, toMax : f32 ) -> f32 {

	


	return pow( 2.0, ( ( ( ( ( ( x - fromMin ) / ( fromMax - fromMin ) ) * ( 1.0 - 0.0 ) ) + 0.0 ) * log2( ( toMax / toMin ) ) ) + log2( toMin ) ) );

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

fn p0_mx_hash_int_2 ( x : i32, y : i32, z : i32 ) -> u32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : u32;
	var nodeVar4 : u32;
	var nodeVar5 : u32;
	var nodeVar6 : u32;

	p0_nodeVar0 = z;
	nodeVar1 = y;
	nodeVar2 = x;
	nodeVar3 = 3u;
	nodeVar4 = 0u;
	nodeVar5 = 0u;
	nodeVar6 = 0u;
	nodeVar6 = ( ( 3735928559u + ( nodeVar3 << 2u ) ) + 13u );
	nodeVar5 = nodeVar6;
	nodeVar4 = nodeVar5;
	nodeVar4 = ( nodeVar4 + u32( nodeVar2 ) );
	nodeVar5 = ( nodeVar5 + u32( nodeVar1 ) );
	nodeVar6 = ( nodeVar6 + u32( p0_nodeVar0 ) );

	return p0_mx_bjfinal( nodeVar4, nodeVar5, nodeVar6 );

}

fn p0_mx_hash_vec3_1 ( x : i32, y : i32, z : i32 ) -> vec3<u32> {

	var p0_nodeVar0 : i32;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : u32;
	var nodeVar4 : vec3<u32>;

	p0_nodeVar0 = z;
	nodeVar1 = y;
	nodeVar2 = x;
	nodeVar3 = p0_mx_hash_int_2( nodeVar2, nodeVar1, p0_nodeVar0 );
	nodeVar4 = vec3<u32>( 0u, 0u, 0u );
	nodeVar4.x = ( nodeVar3 & 255u );
	nodeVar4.y = ( ( nodeVar3 >> 8u ) & 255u );
	nodeVar4.z = ( ( nodeVar3 >> 16u ) & 255u );

	return nodeVar4;

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

fn p0_mx_gradient_float_1 ( hash : u32, x : f32, y : f32, z : f32 ) -> f32 {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : u32;
	var nodeVar4 : u32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;

	p0_nodeVar0 = z;
	nodeVar1 = y;
	nodeVar2 = x;
	nodeVar3 = hash;
	nodeVar4 = ( nodeVar3 & 15u );
	nodeVar5 = p0_mx_select( ( nodeVar4 < 8u ), nodeVar2, nodeVar1 );
	nodeVar6 = p0_mx_select( ( nodeVar4 < 4u ), nodeVar1, p0_mx_select( ( ( nodeVar4 == 12u ) || ( nodeVar4 == 14u ) ), nodeVar2, p0_nodeVar0 ) );

	return ( p0_mx_negate_if( nodeVar5, bool( ( nodeVar4 & 1u ) ) ) + p0_mx_negate_if( nodeVar6, bool( ( nodeVar4 & 2u ) ) ) );

}

fn p0_mx_gradient_vec3_1 ( hash : vec3<u32>, x : f32, y : f32, z : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : vec3<u32>;

	p0_nodeVar0 = z;
	nodeVar1 = y;
	nodeVar2 = x;
	nodeVar3 = hash;

	return vec3<f32>( p0_mx_gradient_float_1( nodeVar3.x, nodeVar2, nodeVar1, p0_nodeVar0 ), p0_mx_gradient_float_1( nodeVar3.y, nodeVar2, nodeVar1, p0_nodeVar0 ), p0_mx_gradient_float_1( nodeVar3.z, nodeVar2, nodeVar1, p0_nodeVar0 ) );

}

fn p0_mx_trilerp_1 ( v0 : vec3<f32>, v1 : vec3<f32>, v2 : vec3<f32>, v3 : vec3<f32>, v4 : vec3<f32>, v5 : vec3<f32>, v6 : vec3<f32>, v7 : vec3<f32>, s : f32, t : f32, r : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : vec3<f32>;
	var nodeVar5 : vec3<f32>;
	var nodeVar6 : vec3<f32>;
	var nodeVar7 : vec3<f32>;
	var nodeVar8 : vec3<f32>;
	var nodeVar9 : vec3<f32>;
	var nodeVar10 : vec3<f32>;
	var nodeVar11 : f32;
	var nodeVar12 : f32;
	var nodeVar13 : f32;

	p0_nodeVar0 = r;
	nodeVar1 = t;
	nodeVar2 = s;
	nodeVar3 = v7;
	nodeVar4 = v6;
	nodeVar5 = v5;
	nodeVar6 = v4;
	nodeVar7 = v3;
	nodeVar8 = v2;
	nodeVar9 = v1;
	nodeVar10 = v0;
	nodeVar11 = ( 1.0 - nodeVar2 );
	nodeVar12 = ( 1.0 - nodeVar1 );
	nodeVar13 = ( 1.0 - p0_nodeVar0 );

	return ( ( vec3<f32>( nodeVar13 ) * ( ( vec3<f32>( nodeVar12 ) * ( ( nodeVar10 * vec3<f32>( nodeVar11 ) ) + ( nodeVar9 * vec3<f32>( nodeVar2 ) ) ) ) + ( vec3<f32>( nodeVar1 ) * ( ( nodeVar8 * vec3<f32>( nodeVar11 ) ) + ( nodeVar7 * vec3<f32>( nodeVar2 ) ) ) ) ) ) + ( vec3<f32>( p0_nodeVar0 ) * ( ( vec3<f32>( nodeVar12 ) * ( ( nodeVar6 * vec3<f32>( nodeVar11 ) ) + ( nodeVar5 * vec3<f32>( nodeVar2 ) ) ) ) + ( vec3<f32>( nodeVar1 ) * ( ( nodeVar4 * vec3<f32>( nodeVar11 ) ) + ( nodeVar3 * vec3<f32>( nodeVar2 ) ) ) ) ) ) );

}

fn p0_mx_gradient_scale3d_1 ( v : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;

	p0_nodeVar0 = v;

	return ( vec3<f32>( 0.982 ) * p0_nodeVar0 );

}

fn p0_mx_perlin_noise_vec3_1 ( p : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : i32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : f32;
	var nodeVar10 : f32;
	var nodeVar11 : f32;
	var nodeVar12 : f32;
	var nodeVar13 : vec3<f32>;

	p0_nodeVar0 = p;
	nodeVar1 = 0;
	nodeVar2 = 0;
	nodeVar3 = 0;
	nodeVar4 = p0_nodeVar0.x;
	nodeVar1 = p0_mx_floor( nodeVar4 );
	nodeVar5 = ( nodeVar4 - f32( nodeVar1 ) );
	nodeVar6 = p0_nodeVar0.y;
	nodeVar2 = p0_mx_floor( nodeVar6 );
	nodeVar7 = ( nodeVar6 - f32( nodeVar2 ) );
	nodeVar8 = p0_nodeVar0.z;
	nodeVar3 = p0_mx_floor( nodeVar8 );
	nodeVar9 = ( nodeVar8 - f32( nodeVar3 ) );
	nodeVar10 = p0_mx_fade( nodeVar5 );
	nodeVar11 = p0_mx_fade( nodeVar7 );
	nodeVar12 = p0_mx_fade( nodeVar9 );
	nodeVar13 = p0_mx_trilerp_1( p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( nodeVar1, nodeVar2, nodeVar3 ), nodeVar5, nodeVar7, nodeVar9 ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( ( nodeVar1 + 1 ), nodeVar2, nodeVar3 ), ( nodeVar5 - 1.0 ), nodeVar7, nodeVar9 ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( nodeVar1, ( nodeVar2 + 1 ), nodeVar3 ), nodeVar5, ( nodeVar7 - 1.0 ), nodeVar9 ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( ( nodeVar1 + 1 ), ( nodeVar2 + 1 ), nodeVar3 ), ( nodeVar5 - 1.0 ), ( nodeVar7 - 1.0 ), nodeVar9 ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( nodeVar1, nodeVar2, ( nodeVar3 + 1 ) ), nodeVar5, nodeVar7, ( nodeVar9 - 1.0 ) ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( ( nodeVar1 + 1 ), nodeVar2, ( nodeVar3 + 1 ) ), ( nodeVar5 - 1.0 ), nodeVar7, ( nodeVar9 - 1.0 ) ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( nodeVar1, ( nodeVar2 + 1 ), ( nodeVar3 + 1 ) ), nodeVar5, ( nodeVar7 - 1.0 ), ( nodeVar9 - 1.0 ) ), p0_mx_gradient_vec3_1( p0_mx_hash_vec3_1( ( nodeVar1 + 1 ), ( nodeVar2 + 1 ), ( nodeVar3 + 1 ) ), ( nodeVar5 - 1.0 ), ( nodeVar7 - 1.0 ), ( nodeVar9 - 1.0 ) ), nodeVar10, nodeVar11, nodeVar12 );

	return p0_mx_gradient_scale3d_1( nodeVar13 );

}

fn p0_mx_fractal_noise_vec3 ( p : vec3<f32>, octaves : i32, lacunarity : f32, diminish : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : vec3<f32>;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : f32;
	var nodeVar5 : i32;

	p0_nodeVar0 = diminish;
	nodeVar1 = lacunarity;
	nodeVar2 = p;
	nodeVar3 = vec3<f32>( 0.0, 0.0, 0.0 );
	nodeVar4 = 1.0;
	nodeVar5 = octaves;

	for ( var i : i32 = 0; i < nodeVar5; i ++ ) {

		nodeVar3 = ( nodeVar3 + ( vec3<f32>( nodeVar4 ) * p0_mx_perlin_noise_vec3_1( nodeVar2 ) ) );
		nodeVar4 = ( nodeVar4 * p0_nodeVar0 );
		nodeVar2 = ( nodeVar2 * vec3<f32>( nodeVar1 ) );

	}


	return nodeVar3;

}

fn p0_mx_trilerp_0 ( v0 : f32, v1 : f32, v2 : f32, v3 : f32, v4 : f32, v5 : f32, v6 : f32, v7 : f32, s : f32, t : f32, r : f32 ) -> f32 {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : f32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : f32;
	var nodeVar10 : f32;
	var nodeVar11 : f32;
	var nodeVar12 : f32;
	var nodeVar13 : f32;

	p0_nodeVar0 = r;
	nodeVar1 = t;
	nodeVar2 = s;
	nodeVar3 = v7;
	nodeVar4 = v6;
	nodeVar5 = v5;
	nodeVar6 = v4;
	nodeVar7 = v3;
	nodeVar8 = v2;
	nodeVar9 = v1;
	nodeVar10 = v0;
	nodeVar11 = ( 1.0 - nodeVar2 );
	nodeVar12 = ( 1.0 - nodeVar1 );
	nodeVar13 = ( 1.0 - p0_nodeVar0 );

	return ( ( nodeVar13 * ( ( nodeVar12 * ( ( nodeVar10 * nodeVar11 ) + ( nodeVar9 * nodeVar2 ) ) ) + ( nodeVar1 * ( ( nodeVar8 * nodeVar11 ) + ( nodeVar7 * nodeVar2 ) ) ) ) ) + ( p0_nodeVar0 * ( ( nodeVar12 * ( ( nodeVar6 * nodeVar11 ) + ( nodeVar5 * nodeVar2 ) ) ) + ( nodeVar1 * ( ( nodeVar4 * nodeVar11 ) + ( nodeVar3 * nodeVar2 ) ) ) ) ) );

}

fn p0_mx_gradient_scale3d_0 ( v : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = v;

	return ( 0.982 * p0_nodeVar0 );

}

fn p0_mx_perlin_noise_float_1 ( p : vec3<f32> ) -> f32 {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : i32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : f32;
	var nodeVar10 : f32;
	var nodeVar11 : f32;
	var nodeVar12 : f32;
	var nodeVar13 : f32;

	p0_nodeVar0 = p;
	nodeVar1 = 0;
	nodeVar2 = 0;
	nodeVar3 = 0;
	nodeVar4 = p0_nodeVar0.x;
	nodeVar1 = p0_mx_floor( nodeVar4 );
	nodeVar5 = ( nodeVar4 - f32( nodeVar1 ) );
	nodeVar6 = p0_nodeVar0.y;
	nodeVar2 = p0_mx_floor( nodeVar6 );
	nodeVar7 = ( nodeVar6 - f32( nodeVar2 ) );
	nodeVar8 = p0_nodeVar0.z;
	nodeVar3 = p0_mx_floor( nodeVar8 );
	nodeVar9 = ( nodeVar8 - f32( nodeVar3 ) );
	nodeVar10 = p0_mx_fade( nodeVar5 );
	nodeVar11 = p0_mx_fade( nodeVar7 );
	nodeVar12 = p0_mx_fade( nodeVar9 );
	nodeVar13 = p0_mx_trilerp_0( p0_mx_gradient_float_1( p0_mx_hash_int_2( nodeVar1, nodeVar2, nodeVar3 ), nodeVar5, nodeVar7, nodeVar9 ), p0_mx_gradient_float_1( p0_mx_hash_int_2( ( nodeVar1 + 1 ), nodeVar2, nodeVar3 ), ( nodeVar5 - 1.0 ), nodeVar7, nodeVar9 ), p0_mx_gradient_float_1( p0_mx_hash_int_2( nodeVar1, ( nodeVar2 + 1 ), nodeVar3 ), nodeVar5, ( nodeVar7 - 1.0 ), nodeVar9 ), p0_mx_gradient_float_1( p0_mx_hash_int_2( ( nodeVar1 + 1 ), ( nodeVar2 + 1 ), nodeVar3 ), ( nodeVar5 - 1.0 ), ( nodeVar7 - 1.0 ), nodeVar9 ), p0_mx_gradient_float_1( p0_mx_hash_int_2( nodeVar1, nodeVar2, ( nodeVar3 + 1 ) ), nodeVar5, nodeVar7, ( nodeVar9 - 1.0 ) ), p0_mx_gradient_float_1( p0_mx_hash_int_2( ( nodeVar1 + 1 ), nodeVar2, ( nodeVar3 + 1 ) ), ( nodeVar5 - 1.0 ), nodeVar7, ( nodeVar9 - 1.0 ) ), p0_mx_gradient_float_1( p0_mx_hash_int_2( nodeVar1, ( nodeVar2 + 1 ), ( nodeVar3 + 1 ) ), nodeVar5, ( nodeVar7 - 1.0 ), ( nodeVar9 - 1.0 ) ), p0_mx_gradient_float_1( p0_mx_hash_int_2( ( nodeVar1 + 1 ), ( nodeVar2 + 1 ), ( nodeVar3 + 1 ) ), ( nodeVar5 - 1.0 ), ( nodeVar7 - 1.0 ), ( nodeVar9 - 1.0 ) ), nodeVar10, nodeVar11, nodeVar12 );

	return p0_mx_gradient_scale3d_0( nodeVar13 );

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

fn p0_bricksRaw ( position : vec3<f32>, scale : f32, brickSize : vec3<f32>, brickShift : f32, jointSize : f32, jointSpan : f32, jointJitter : f32, jointBlur : f32, noiseSize : f32, noiseStrength : f32, colorShade : f32, color : vec3<f32>, additional : vec3<f32>, background : vec3<f32>, seed : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : vec3<f32>;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : f32;

	p0_nodeVar0 = ( ( position * vec3<f32>( exp( scale ) ) ) + vec3<f32>( seed ) );
	nodeVar1 = vec3<f32>( ( floor( ( p0_nodeVar0 / brickSize ) ) / vec3<f32>( brickShift ) ).y, 0.0, ( floor( ( p0_nodeVar0 / brickSize ) ) / vec3<f32>( brickShift ) ).y );
	nodeVar2 = fract( ( fract( ( p0_nodeVar0 / brickSize ) ) + nodeVar1 ) );
	nodeVar3 = ( ( p0_mx_fractal_noise_vec3( ( p0_nodeVar0 * vec3<f32>( p0_remapExp( jointSpan, 0.0, 1.0, 20.0, 0.2 ) ) ), 3, 2.0, 0.5 ) * vec3<f32>( 1.0 ) ) / vec3<f32>( p0_remapExp( jointJitter, 0.0, 1.0, 500.0, 1.0 ) ) );
	nodeVar4 = clamp( ( ( ( ( ( ( 1.0 - smoothstep( vec3<f32>( ( ( brickSize.y - jointSize ) - jointBlur ) ), vec3<f32>( ( brickSize.y - jointSize ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.z ) ) ).y ) * smoothstep( vec3<f32>( jointSize ), vec3<f32>( ( jointSize + jointBlur ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.y ) ) ).y ) * ( 1.0 - smoothstep( vec3<f32>( ( ( brickSize.x - jointSize ) - jointBlur ) ), vec3<f32>( ( brickSize.x - jointSize ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.y ) ) ).x ) ) * smoothstep( vec3<f32>( jointSize ), vec3<f32>( ( jointSize + jointBlur ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.x ) ) ).x ) * ( 1.0 - smoothstep( vec3<f32>( ( ( brickSize.z - jointSize ) - jointBlur ) ), vec3<f32>( ( brickSize.z - jointSize ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.x ) ) ).z ) ) * smoothstep( vec3<f32>( jointSize ), vec3<f32>( ( jointSize + jointBlur ) ), ( ( nodeVar2 * brickSize ) + vec3<f32>( nodeVar3.z ) ) ).z ), 0.0, 1.0 );

	return ( mix( background, ( ( vec3<f32>( mix( 1.0, clamp( pow( ( ( ( ( p0_mx_perlin_noise_float_0( vec2<f32>( ( ( ( p0_mx_perlin_noise_float_1( ( ( floor( ( ( p0_nodeVar0 / brickSize ) + nodeVar1 ) ).zxy * vec3<f32>( 100.0 ) ) + vec3<f32>( 3.141592653589793 ) ) ) * 1.0 ) + 0.0 ) * 10.0 ) ) ) * 1.0 ) + 0.0 ) + 2.0 ) / 2.0 ), 4.0 ), 0.0, 1.0 ), colorShade ) ) * mix( color, additional, pow( ( ( ( ( p0_mx_perlin_noise_float_0( vec2<f32>( ( ( ( p0_mx_perlin_noise_float_1( ( ( floor( ( ( p0_nodeVar0 / brickSize ) + nodeVar1 ) ).zxy * vec3<f32>( 200.0 ) ) + vec3<f32>( 3.141592653589793 ) ) ) * 1.0 ) + 0.0 ) * 10.0 ) ) ) * 1.0 ) + 0.0 ) + 1.0 ) / 1.0 ), 2.0 ) ) ) * vec3<f32>( nodeVar4 ) ), nodeVar4 ) * vec3<f32>( ( ( ( ( p0_mx_perlin_noise_float_1( ( p0_nodeVar0 * vec3<f32>( p0_remapExp( noiseSize, 0.0, 1.0, 5.0, 250.0 ) ) ) ) * 1.0 ) + 0.0 ) * noiseStrength ) + 1.0 ) ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_bricksRaw( nodeVarying4, f32(knobs.scale), vec3<f32>(knobs.brickSize.x, knobs.brickSize.y, knobs.brickSize.z), f32(knobs.brickShift), f32(knobs.jointSize), f32(knobs.jointSpan), f32(knobs.jointJitter), f32(knobs.jointBlur), f32(knobs.noiseSize), f32(knobs.noiseStrength), f32(knobs.colorShade), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.additional.x, knobs.additional.y, knobs.additional.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z), 0.0 ), 1.0 );
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

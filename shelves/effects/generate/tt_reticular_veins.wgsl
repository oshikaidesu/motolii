// Reticular veins: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture generates reticular veins of plant leaves. These vains
// --track@scale:Scale,0,4,2,0.04
// --track@reticulation:Reticulation,2,10,5,0.08
// --track@strength:Strength,0,1,0.2,0.01
// --track@organelles:Organelles,0,1,0.2,0.01
// --track@color_x:Color r,0,1,1,0.001
// --track@color_y:Color g,0,1,1,0.001
// --track@color_z:Color b,0,1,0.8713671191959567,0.001
// --track@background_x:Background r,0,1,0.014443843592229466,0.001
// --track@background_y:Background g,0,1,0.21586050010324417,0.001
// --track@background_z:Background b,0,1,0.014443843592229466,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  reticulation: f32,
  strength: f32,
  organelles: f32,
  color: vec3<f32>,
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
fn p0_mx_floor ( x : f32 ) -> i32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = x;

	return i32( floor( p0_nodeVar0 ) );

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

fn p0_mx_hash_int_3 ( x : i32, y : i32, z : i32, xx : i32 ) -> u32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : i32;
	var nodeVar4 : u32;
	var nodeVar5 : u32;
	var nodeVar6 : u32;
	var nodeVar7 : u32;

	p0_nodeVar0 = xx;
	nodeVar1 = z;
	nodeVar2 = y;
	nodeVar3 = x;
	nodeVar4 = 4u;
	nodeVar5 = 0u;
	nodeVar6 = 0u;
	nodeVar7 = 0u;
	nodeVar7 = ( ( 3735928559u + ( nodeVar4 << 2u ) ) + 13u );
	nodeVar6 = nodeVar7;
	nodeVar5 = nodeVar6;
	nodeVar5 = ( nodeVar5 + u32( nodeVar3 ) );
	nodeVar6 = ( nodeVar6 + u32( nodeVar2 ) );
	nodeVar7 = ( nodeVar7 + u32( nodeVar1 ) );
	nodeVar5 = ( nodeVar5 + u32( p0_nodeVar0 ) );

	return p0_mx_bjfinal( nodeVar5, nodeVar6, nodeVar7 );

}

fn p0_mx_bits_to_01 ( bits : u32 ) -> f32 {

	var p0_nodeVar0 : u32;

	p0_nodeVar0 = bits;

	return ( f32( p0_nodeVar0 ) / f32( 4294967295u ) );

}

fn p0_mx_cell_noise_vec3_2 ( p : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : i32;
	var nodeVar2 : i32;
	var nodeVar3 : i32;

	p0_nodeVar0 = p;
	nodeVar1 = p0_mx_floor( p0_nodeVar0.x );
	nodeVar2 = p0_mx_floor( p0_nodeVar0.y );
	nodeVar3 = p0_mx_floor( p0_nodeVar0.z );

	return vec3<f32>( p0_mx_bits_to_01( p0_mx_hash_int_3( nodeVar1, nodeVar2, nodeVar3, 0 ) ), p0_mx_bits_to_01( p0_mx_hash_int_3( nodeVar1, nodeVar2, nodeVar3, 1 ) ), p0_mx_bits_to_01( p0_mx_hash_int_3( nodeVar1, nodeVar2, nodeVar3, 2 ) ) );

}

fn p0_mx_worley_distance_1 ( p : vec3<f32>, x : i32, y : i32, z : i32, xoff : i32, yoff : i32, zoff : i32, jitter : f32, metric : i32 ) -> f32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : f32;
	var nodeVar2 : i32;
	var nodeVar3 : i32;
	var nodeVar4 : i32;
	var nodeVar5 : i32;
	var nodeVar6 : i32;
	var nodeVar7 : i32;
	var nodeVar8 : vec3<f32>;
	var nodeVar9 : vec3<f32>;
	var nodeVar10 : vec3<f32>;
	var nodeVar11 : vec3<f32>;

	p0_nodeVar0 = metric;
	nodeVar1 = jitter;
	nodeVar2 = zoff;
	nodeVar3 = yoff;
	nodeVar4 = xoff;
	nodeVar5 = z;
	nodeVar6 = y;
	nodeVar7 = x;
	nodeVar8 = p;
	nodeVar9 = p0_mx_cell_noise_vec3_2( vec3<f32>( f32( ( nodeVar7 + nodeVar4 ) ), f32( ( nodeVar6 + nodeVar3 ) ), f32( ( nodeVar5 + nodeVar2 ) ) ) );
	nodeVar9 = ( nodeVar9 - vec3<f32>( 0.5 ) );
	nodeVar9 = ( nodeVar9 * vec3<f32>( nodeVar1 ) );
	nodeVar9 = ( nodeVar9 + vec3<f32>( 0.5 ) );
	nodeVar10 = ( vec3<f32>( f32( nodeVar7 ), f32( nodeVar6 ), f32( nodeVar5 ) ) + nodeVar9 );
	nodeVar11 = ( nodeVar10 - nodeVar8 );

	if ( ( p0_nodeVar0 == 2 ) ) {

		return ( ( abs( nodeVar11.x ) + abs( nodeVar11.y ) ) + abs( nodeVar11.z ) );

	}


	if ( ( p0_nodeVar0 == 3 ) ) {

		return max( max( abs( nodeVar11.x ), abs( nodeVar11.y ) ), abs( nodeVar11.z ) );

	}


	return dot( nodeVar11, nodeVar11 );

}

fn p0_mx_worley_noise_float_1 ( p : vec3<f32>, jitter : f32, metric : i32 ) -> f32 {

	var p0_nodeVar0 : i32;
	var nodeVar1 : f32;
	var nodeVar2 : vec3<f32>;
	var nodeVar3 : i32;
	var nodeVar4 : i32;
	var nodeVar5 : i32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : vec3<f32>;
	var nodeVar10 : f32;
	var nodeVar11 : f32;

	p0_nodeVar0 = metric;
	nodeVar1 = jitter;
	nodeVar2 = p;
	nodeVar3 = 0;
	nodeVar4 = 0;
	nodeVar5 = 0;
	nodeVar6 = nodeVar2.x;
	nodeVar3 = p0_mx_floor( nodeVar6 );
	nodeVar7 = nodeVar2.y;
	nodeVar4 = p0_mx_floor( nodeVar7 );
	nodeVar8 = nodeVar2.z;
	nodeVar5 = p0_mx_floor( nodeVar8 );
	nodeVar9 = vec3<f32>( ( nodeVar6 - f32( nodeVar3 ) ), ( nodeVar7 - f32( nodeVar4 ) ), ( nodeVar8 - f32( nodeVar5 ) ) );
	nodeVar10 = 1000000.0;

	for ( var x : i32 = -1; x <= 1; x ++ ) {


		for ( var y : i32 = -1; y <= 1; y ++ ) {


			for ( var z : i32 = -1; z <= 1; z ++ ) {

				nodeVar11 = p0_mx_worley_distance_1( nodeVar9, x, y, z, nodeVar3, nodeVar4, nodeVar5, nodeVar1, p0_nodeVar0 );
				nodeVar10 = min( nodeVar10, nodeVar11 );

			}


		}


	}


	if ( ( p0_nodeVar0 == 0 ) ) {

		nodeVar10 = sqrt( nodeVar10 );
		

	}


	return nodeVar10;

}

fn p0_mx_fade ( t : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = t;

	return ( ( ( p0_nodeVar0 * p0_nodeVar0 ) * p0_nodeVar0 ) * ( ( p0_nodeVar0 * ( ( p0_nodeVar0 * 6.0 ) - 15.0 ) ) + 10.0 ) );

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

fn p0_reticularVeinsRaw ( position : vec3<f32>, scale : f32, reticulation : f32, strength : f32, organelles : f32, color : vec3<f32>, background : vec3<f32>, seed : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;

	p0_nodeVar0 = ( ( position * vec3<f32>( exp( ( ( scale / 2.0 ) + 0.5 ) ) ) ) + vec3<f32>( seed ) );

	return mix( background, color, ( ( p0_mx_worley_noise_float_1( p0_nodeVar0, 1.0, 1 ) + ( p0_mx_worley_noise_float_1( ( ( p0_nodeVar0 + vec3<f32>( 100.0 ) ) * vec3<f32>( reticulation ) ), 1.0, 1 ) * strength ) ) + ( ( ( ( p0_mx_perlin_noise_float_1( ( p0_nodeVar0 * vec3<f32>( 100.0 ) ) ) * 1.0 ) + 0.0 ) * strength ) * organelles ) ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_reticularVeinsRaw( nodeVarying4, f32(knobs.scale), f32(knobs.reticulation), f32(knobs.strength), f32(knobs.organelles), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z), 0.0 ), 1.0 );
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

// Scepter head: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture designs the stone and the metal rim of a scepter
// --track@colorRim_x:Color Rim r,0,1,1,0.001
// --track@colorRim_y:Color Rim g,0,1,1,0.001
// --track@colorRim_z:Color Rim b,0,1,1,0.001
// --track@colorA_x:Color A r,0,1,0.16202937562896222,0.001
// --track@colorA_y:Color A g,0,1,0.7454042095350284,0.001
// --track@colorA_z:Color A b,0,1,1,0.001
// --track@colorB_x:Color B r,0,1,0.02955683443236377,0.001
// --track@colorB_y:Color B g,0,1,0,0.001
// --track@colorB_z:Color B b,0,1,1,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  colorRim: vec3<f32>,
  colorA: vec3<f32>,
  colorB: vec3<f32>,
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

fn p0_toHsl ( rgb : vec3<f32> ) -> vec3<f32> {

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

	p0_nodeVar0 = rgb.x;
	nodeVar1 = rgb.y;
	nodeVar2 = rgb.z;
	nodeVar3 = max( p0_nodeVar0, max( nodeVar1, nodeVar2 ) );
	nodeVar4 = min( p0_nodeVar0, min( nodeVar1, nodeVar2 ) );
	nodeVar5 = 0.0;
	nodeVar6 = 0.0;

	if ( ( nodeVar4 != nodeVar3 ) ) {

		nodeVar7 = ( nodeVar3 - nodeVar4 );

		if ( ( ( ( nodeVar3 + nodeVar4 ) / 2.0 ) <= 0.5 ) ) {

			nodeVar8 = ( nodeVar7 / ( nodeVar4 + nodeVar3 ) );

		} else {

			nodeVar8 = ( nodeVar7 / ( 2.0 - ( nodeVar4 + nodeVar3 ) ) );

		}

		nodeVar6 = nodeVar8;

		if ( ( nodeVar3 == p0_nodeVar0 ) ) {


			if ( ( nodeVar1 <= nodeVar2 ) ) {

				nodeVar9 = 6.0;

			} else {

				nodeVar9 = 0.0;

			}

			nodeVar5 = ( ( ( nodeVar1 - nodeVar2 ) / nodeVar7 ) + nodeVar9 );
			

		} else {


			if ( ( nodeVar3 == nodeVar1 ) ) {

				nodeVar5 = ( ( ( nodeVar2 - p0_nodeVar0 ) / nodeVar7 ) + 2.0 );
				

			} else {

				nodeVar5 = ( ( ( p0_nodeVar0 - nodeVar1 ) / nodeVar7 ) + 4.0 );
				

			}

			

		}

		nodeVar5 = ( nodeVar5 / 6.0 );
		

	}


	return vec3<f32>( nodeVar5, nodeVar6, ( ( nodeVar3 + nodeVar4 ) / 2.0 ) );

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

fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }
fn p0_hslHelper ( h : f32, s : f32, l : f32, n : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = p0_tsl_mod_float( ( n + ( h * 12.0 ) ), 12.0 );

	return ( l - ( ( s * min( l, ( 1.0 - l ) ) ) * max( -1.0, min( min( ( p0_nodeVar0 - 3.0 ), ( 9.0 - p0_nodeVar0 ) ), 1.0 ) ) ) );

}

fn p0_hsl ( col : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;

	p0_nodeVar0 = fract( ( fract( col.x ) + 1.0 ) );
	nodeVar1 = clamp( col.y, 0.0, 1.0 );
	nodeVar2 = clamp( col.z, 0.0, 1.0 );

	return vec3<f32>( p0_hslHelper( p0_nodeVar0, nodeVar1, nodeVar2, 0.0 ), p0_hslHelper( p0_nodeVar0, nodeVar1, nodeVar2, 8.0 ), p0_hslHelper( p0_nodeVar0, nodeVar1, nodeVar2, 4.0 ) );

}

fn p0_scepterHeadRaw ( position : vec3<f32>, xFactor : f32, yFactor : f32, zFactor : f32, colorRim : vec3<f32>, colorA : vec3<f32>, colorB : vec3<f32> ) -> vec3<f32> {

	var pos : vec3<f32>;
	var fx : f32;
	var fy : f32;
	var fz : f32;
	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : f32;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var color1 : vec3<f32>;
	var color2 : vec3<f32>;

	pos = position;
	fx = ( pos.x * p0_remapExp( xFactor, 0.0, 100.0, 1.35, 30.0 ) );
	fy = ( pos.y * p0_remapExp( yFactor, 0.0, 100.0, 1.35, 30.0 ) );
	fz = ( pos.z * p0_remapExp( zFactor, 0.0, 100.0, 1.35, 30.0 ) );
	p0_nodeVar0 = vec3<f32>( 0.0, 0.0, 0.0 );
	p0_nodeVar0 = p0_toHsl( mix( colorA, colorB, p0_tsl_mod_float( ( ( abs( floor( ( ( ( fx * 0.6366197723675814 ) + 1.0 ) / 2.0 ) ) ) + abs( floor( ( ( ( fy * 0.6366197723675814 ) + 1.0 ) / 2.0 ) ) ) ) + abs( floor( ( ( ( fz * 0.6366197723675814 ) + 1.0 ) / 2.0 ) ) ) ), 2.0 ) ) );
	nodeVar1 = cos( fx );
	nodeVar2 = cos( fy );
	nodeVar3 = cos( fz );
	nodeVar4 = ( ( p0_mx_perlin_noise_float_1( vec3<f32>( ( pos.x / nodeVar1 ), ( pos.y / nodeVar2 ), ( pos.z / nodeVar3 ) ) ) * 1.0 ) + 0.0 );
	nodeVar5 = ( sign( nodeVar4 ) * pow( abs( nodeVar4 ), 0.75 ) );
	color1 = p0_hsl( vec3<f32>( p0_nodeVar0.xy, ( p0_nodeVar0.z * nodeVar5 ) ) );
	p0_nodeVar0 = p0_toHsl( colorRim );
	color2 = p0_hsl( vec3<f32>( p0_nodeVar0.xy, ( ( 2.0 * nodeVar5 ) * p0_nodeVar0.z ) ) );

	return mix( color1, color2, ( ( clamp( ( ( max( abs( ( ( ( fx * tan( fx ) ) + 1.0 ) / nodeVar1 ) ), max( abs( ( ( ( fy * tan( fy ) ) + 1.0 ) / nodeVar2 ) ), abs( ( ( ( fz * tan( fz ) ) + 1.0 ) / nodeVar3 ) ) ) ) - 45.0 ) / ( 65.0 - 45.0 ) ), 0.0, 1.0 ) * ( 1.0 - 0.0 ) ) + 0.0 ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x * knobs.frameRect.z / (knobs.resolution.y * knobs.frameRect.w), 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_scepterHeadRaw( nodeVarying4, 10.0, 22.0, 10.0, vec3<f32>(knobs.colorRim.x, knobs.colorRim.y, knobs.colorRim.z), vec3<f32>(knobs.colorA.x, knobs.colorA.y, knobs.colorA.z), vec3<f32>(knobs.colorB.x, knobs.colorB.y, knobs.colorB.z) ), 1.0 );
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

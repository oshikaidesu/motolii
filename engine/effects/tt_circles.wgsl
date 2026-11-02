// Circles: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture geenrates concentric horizonta circles. Click on a snapshot to open it online.
// --track@scale:Scale,0,4,2,0.04
// --track@variety:Variety,0,1,1,0.01
// --track@color_x:Color r,0,1,0.8713671191959567,0.001
// --track@color_y:Color g,0,1,0.7454042095350284,0.001
// --track@color_z:Color b,0,1,0.6307571363387763,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  variety: f32,
  color: vec3<f32>,
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

fn p0_circlesRaw ( position : vec3<f32>, scale : f32, variety : f32, color : vec3<f32>, seed : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;
	var nodeVar7 : f32;

	p0_nodeVar0 = position;
	nodeVar1 = ( sin( seed ) * 100.0 );
	nodeVar2 = ( ( ( acos( clamp( p0_nodeVar0.y, -1.0, 1.0 ) ) * 20.0 ) / 3000.0 ) * exp( ( scale - 1.0 ) ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 1.0 ) - 0.0 ) ) * 0.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 2.0 ) - 1.5707963267948966 ) ) * -1.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 4.0 ) - 3.141592653589793 ) ) * -3.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 8.0 ) - 4.71238898038469 ) ) * -6.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 16.0 ) - 6.283185307179586 ) ) * -10.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 32.0 ) - 7.853981633974483 ) ) * -15.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 64.0 ) - 9.42477796076938 ) ) * -21.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 128.0 ) - 10.995574287564276 ) ) * -28.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 256.0 ) - 12.566370614359172 ) ) * -36.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 512.0 ) - 14.137166941154069 ) ) * -45.0 ) );
	nodeVar1 = ( nodeVar1 + ( sin( ( ( nodeVar2 * 1024.0 ) - 15.707963267948966 ) ) * -55.0 ) );
	nodeVar1 = clamp( ( nodeVar1 / 200.0 ), -2.0, 2.0 );
	nodeVar3 = p0_toHsl( color );
	nodeVar4 = ( p0_tsl_mod_float( ( nodeVar3.x + ( nodeVar1 * variety ) ), 1.0 ) * 10.0 );
	nodeVar5 = floor( nodeVar4 );
	nodeVar7 = ( nodeVar4 - nodeVar5 );

	if ( ( nodeVar7 < 0.5 ) ) {

		nodeVar6 = pow( nodeVar7, 1.5 );

	} else {

		nodeVar6 = pow( nodeVar7, 0.6666666666666666 );

	}


	return p0_hsl( vec3<f32>( ( ( nodeVar5 + nodeVar6 ) / 10.0 ), nodeVar3.yz ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x * knobs.frameRect.z / (knobs.resolution.y * knobs.frameRect.w), 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_circlesRaw( nodeVarying4, f32(knobs.scale), f32(knobs.variety), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), 0.0 ), 1.0 );
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

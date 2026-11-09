// Polka dots: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:Generate
// --about:This texture arranges dots similar to the [Polka dots](https://en.wikipedia.org/wiki/Polka_dot)
// --track@count:Count,1,4,2,0.03
// --track@size:Size,0,1,0.5,0.01
// --track@blur:Blur,0,1,0.25,0.01
// --track@color_x:Color r,0,1,0,0.001
// --track@color_y:Color g,0,1,0,0.001
// --track@color_z:Color b,0,1,0,0.001
// --track@background_x:Background r,0,1,1,0.001
// --track@background_y:Background g,0,1,1,0.001
// --track@background_z:Background b,0,1,1,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  count: f32,
  size: f32,
  blur: f32,
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
fn p0_spherical ( phi : f32, theta : f32 ) -> vec3<f32> {

	


	return vec3<f32>( ( sin( theta ) * sin( phi ) ), cos( phi ), ( cos( theta ) * sin( phi ) ) );

}

fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }
fn p0_polkaDotsRaw ( position : vec3<f32>, count : f32, size : f32, blur : f32, color : vec3<f32>, background : vec3<f32>, xflat : i32 ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : vec2<f32>;
	var nodeVar3 : vec2<f32>;
	var nodeVar4 : f32;
	var nodeVar5 : vec3<f32>;
	var nodeVar6 : f32;
	var nodeVar7 : f32;
	var nodeVar8 : f32;
	var nodeVar9 : f32;
	var nodeVar10 : i32;
	var nodeVar11 : f32;
	var nodeVar12 : f32;

	p0_nodeVar0 = 1.0;

	if ( ( f32( xflat ) == 1.0 ) ) {

		nodeVar1 = ( pow( count, 2.0 ) - 0.5 );
		nodeVar2 = ( ( position.xy * vec2<f32>( nodeVar1 ) ) * mat2x2<f32>( 1.0, -1.0, 1.0, 1.0 ) );
		nodeVar3 = round( nodeVar2 );
		p0_nodeVar0 = ( distance( nodeVar2, nodeVar3 ) / nodeVar1 );
		

	} else {

		nodeVar4 = pow( 10.0, count );
		nodeVar5 = normalize( position );
		p0_nodeVar0 = 1.0;
		nodeVar6 = p0_nodeVar0;
		nodeVar7 = ( ( ( ( 1.0 - nodeVar5.y ) * nodeVar4 ) - 1.0 ) / 2.0 );
		nodeVar8 = max( 10.0, pow( nodeVar4, 0.5 ) );
		nodeVar9 = clamp( floor( ( nodeVar7 - nodeVar8 ) ), 0.0, nodeVar4 );

		for ( var i : i32 = 0; i < i32( ( clamp( floor( ( nodeVar7 + nodeVar8 ) ), 0.0, nodeVar4 ) - nodeVar9 ) ); i ++ ) {

			nodeVar10 = ( i + i32( nodeVar9 ) );
			p0_nodeVar0 = min( p0_nodeVar0, distance( nodeVar5, p0_spherical( acos( ( 1.0 - ( ( ( f32( nodeVar10 ) * 2.0 ) + 1.0 ) / nodeVar4 ) ) ), p0_tsl_mod_float( ( 3.8832220774509327 * f32( nodeVar10 ) ), 6.283185307179586 ) ) ) );

		}

		

	}

	nodeVar11 = exp( ( ( size * 5.0 ) - 5.0 ) );
	nodeVar12 = pow( blur, 4.0 );

	return mix( color, background, smoothstep( ( nodeVar11 - nodeVar12 ), ( nodeVar11 + nodeVar12 ), p0_nodeVar0 ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_polkaDotsRaw( nodeVarying4, f32(knobs.count), f32(knobs.size), f32(knobs.blur), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z), 0 ), 1.0 );
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

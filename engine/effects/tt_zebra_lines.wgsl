// Zebra lines: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture renders a pattern of regularily spread lines
// --track@scale:Scale,0,4,2,0.04
// --track@thinness:Thinness,0,1,0.5,0.01
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
  scale: f32,
  thinness: f32,
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

fn p0_zebraLinesRaw ( position : vec3<f32>, scale : f32, thinness : f32, phi : f32, theta : f32, color : vec3<f32>, background : vec3<f32>, xflat : i32 ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : vec3<f32>;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : f32;
	var nodeVar5 : f32;
	var nodeVar6 : f32;


	if ( bool( xflat ) ) {

		p0_nodeVar0 = position;

	} else {

		p0_nodeVar0 = normalize( position );

	}

	nodeVar1 = p0_nodeVar0;

	if ( bool( xflat ) ) {

		nodeVar2 = vec3<f32>( vec2<f32>( cos( phi ), sin( phi ) ), 0.0 );

	} else {

		nodeVar2 = p0_spherical( phi, theta );

	}

	nodeVar3 = nodeVar2;

	if ( bool( xflat ) ) {

		nodeVar4 = clamp( dot( nodeVar3, nodeVar1 ), -2.0, 2.0 );

	} else {

		nodeVar4 = acos( clamp( dot( nodeVar3, nodeVar1 ), -1.0, 1.0 ) );

	}

	nodeVar5 = nodeVar4;
	nodeVar6 = exp( ( scale + 1.0 ) );

	return mix( background, color, ( ( clamp( ( ( ( sin( ( nodeVar5 * nodeVar6 ) ) - ( ( thinness - 0.5 ) * 2.0 ) ) * 1000.0 ) / nodeVar6 ), -1.0, 1.0 ) * 0.5 ) + 0.5 ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_zebraLinesRaw( nodeVarying4, f32(knobs.scale), f32(knobs.thinness), 0.0, 0.0, vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z), 0 ), 1.0 );
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

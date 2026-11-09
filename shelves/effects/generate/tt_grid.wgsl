// Grid: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:Generate
// --about:This texture draws a spherical grid trying to maintain fixed width of
// --track@countU:Count U,6,100,32,1
// --track@countV:Count V,3,50,16,1
// --track@thinness:Thinness,0,1,0.8,0.01
// --check@equirectangular:Equirectangular,0
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
  countU: f32,
  countV: f32,
  thinness: f32,
  equirectangular: f32,
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
fn p0_gridRaw ( uvs : vec2<f32>, countU : f32, countV : f32, aspect : f32, thinness : f32, equirectangular : i32, color : vec3<f32>, background : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : f32;
	var nodeVar2 : f32;
	var nodeVar3 : f32;

	p0_nodeVar0 = max( exp2( aspect ), 1.0 );
	nodeVar1 = ( ( uvs.x * p0_nodeVar0 ) * 3.141592653589793 );
	nodeVar2 = ( uvs.y * 3.141592653589793 );
	nodeVar3 = ( ( min( ( ( p0_nodeVar0 * 3.141592653589793 ) / countU ), ( 3.141592653589793 / countV ) ) * ( ( clamp( ( ( pow( thinness, 0.5 ) - 0.0 ) / ( 1.0 - 0.0 ) ), 0.0, 1.0 ) * ( 0.04 - 0.9 ) ) + 0.9 ) ) * 0.5 );

	return mix( background, color, ( 1.0 - smoothstep( ( nodeVar3 - 0.002 ), ( nodeVar3 + 0.002 ), min( ( abs( ( nodeVar1 - ( ( ( round( ( uvs.x * countU ) ) / countU ) * p0_nodeVar0 ) * 3.141592653589793 ) ) ) * mix( 1.0, sin( nodeVar2 ), f32( equirectangular ) ) ), abs( ( nodeVar2 - ( ( round( ( uvs.y * countV ) ) / countV ) * 3.141592653589793 ) ) ) ) ) ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_gridRaw( nodeVarying4, f32(knobs.countU), f32(knobs.countV), 1.0, f32(knobs.thinness), i32( f32(knobs.equirectangular) ), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z) ), 1.0 );
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

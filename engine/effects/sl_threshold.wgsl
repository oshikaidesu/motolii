// Threshold: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Turns the image into stark black and white at a cutoff you set.
// --track@threshold:Threshold,0,1,0.5,0.01
// --track@softness:Softness,0,0.2,0.02,0.001
// --track@noise:Noise,0,0.3,0.08,0.001
// --check@invert:Invert,0
// --track@darkColor_x:Dark Color r,0,1,0,0.001
// --track@darkColor_y:Dark Color g,0,1,0,0.001
// --track@darkColor_z:Dark Color b,0,1,0,0.001
// --track@lightColor_x:Light Color r,0,1,1,0.001
// --track@lightColor_y:Light Color g,0,1,1,0.001
// --track@lightColor_z:Light Color b,0,1,1,0.001
// Three.js r185 - Node System

// global
diagnostic( off, derivative_uniformity );


// structs

struct OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> output : OutputStruct;

// uniforms
struct Knobs {
  time: f32,
  darkColor: vec3<f32>,
  lightColor: vec3<f32>,
  invert: f32,
  threshold: f32,
  softness: f32,
  resolution: vec2<f32>,
  noise: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;
fn to_linear(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }
fn to_srgb(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }
fn picture_read(uv: vec2<f32>) -> vec4<f32> { return picture_read_level(uv, 0.0); }
fn picture_read_level(uv: vec2<f32>, level: f32) -> vec4<f32> {
  let p = textureSampleLevel(picture, picture_sampler, uv, level);
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_linear(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}
fn to_shelf(p: vec4<f32>) -> vec4<f32> {
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_srgb(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}


// vars
var<private> DiffuseColor : vec4<f32>;
var<private> nodeVar0 : vec4<f32>;
var<private> nodeVar1 : f32;
var<private> nodeVar2 : vec2<f32>;
var<private> nodeVar3 : vec2<f32>;
var<private> nodeVar4 : vec2<f32>;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec2<f32>;
var<private> nodeVar8 : vec4<f32>;
var<private> nodeVar9 : vec3<f32>;
var<private> nodeVar10 : f32;
var<private> nodeVar11 : vec3<f32>;
var<private> nodeVar12 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar13 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );

	if ( ( (1 * knobs.invert + 0) > 0.5 ) ) {

		nodeVar2 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		nodeVar3 = vec2<f32>( ( nodeVar2.x * knobs.resolution.x ), ( nodeVar2.y * knobs.resolution.y ) );
		nodeVar4 = vec2<f32>( ( nodeVar3.y + 19.19 ), ( nodeVar3.x + 73.71 ) );
		nodeVar1 = ( 1.0 - smoothstep( ( knobs.threshold - knobs.softness ), ( knobs.threshold + knobs.softness ), clamp( ( dot( vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) + ( ( ( fract( ( sin( ( ( nodeVar3.x * 12.9898 ) + ( nodeVar3.y * 78.233 ) ) ) * 43758.5453 ) ) + fract( ( sin( ( ( nodeVar4.x * 12.9898 ) + ( nodeVar4.y * 78.233 ) ) ) * 43758.5453 ) ) ) - 1.0 ) * knobs.noise ) ), 0.0, 1.0 ) ) );

	} else {

		nodeVar5 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		nodeVar6 = vec2<f32>( ( nodeVar5.x * knobs.resolution.x ), ( nodeVar5.y * knobs.resolution.y ) );
		nodeVar7 = vec2<f32>( ( nodeVar6.y + 19.19 ), ( nodeVar6.x + 73.71 ) );
		nodeVar1 = smoothstep( ( knobs.threshold - knobs.softness ), ( knobs.threshold + knobs.softness ), clamp( ( dot( vec3<f32>( nodeVar0.x, nodeVar0.y, nodeVar0.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) + ( ( ( fract( ( sin( ( ( nodeVar6.x * 12.9898 ) + ( nodeVar6.y * 78.233 ) ) ) * 43758.5453 ) ) + fract( ( sin( ( ( nodeVar7.x * 12.9898 ) + ( nodeVar7.y * 78.233 ) ) ) * 43758.5453 ) ) ) - 1.0 ) * knobs.noise ) ), 0.0, 1.0 ) );

	}

	nodeVar8 = vec4<f32>( mix( knobs.darkColor, knobs.lightColor, nodeVar1 ), 1.0 );
	nodeVar9 = vec3<f32>( nodeVar8.x, nodeVar8.y, nodeVar8.z );
	nodeVar10 = ( ( ( nodeVar9.x * 0.2126 ) + ( nodeVar9.y * 0.7152 ) ) + ( nodeVar9.z * 0.0722 ) );
	nodeVar11 = mix( vec3<f32>( nodeVar10, nodeVar10, nodeVar10 ), nodeVar9, f32(1.0) );
	nodeVar12 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar11.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar11.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar11.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar11.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar11.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar11.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar11.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar11.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar11.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar8.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar12.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar12.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar13 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar13;

	// result

	output.color = nodeVar13;

	output.color = to_shelf(output.color);
	return output;

}

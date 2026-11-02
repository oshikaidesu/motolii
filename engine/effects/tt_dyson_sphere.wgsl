// Dyson sphere: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture generates a possible fractal interpretation of a
// --track@scale:Scale,0,4,2,0.04
// --track@complexity:Complexity,1,6,2,1
// --track@color_x:Color r,0,1,0.5271151256969157,0.001
// --track@color_y:Color g,0,1,0.6307571363387763,0.001
// --track@color_z:Color b,0,1,1,0.001
// --track@background_x:Background r,0,1,0,0.001
// --track@background_y:Background g,0,1,0,0.001
// --track@background_z:Background b,0,1,0,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  complexity: f32,
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
fn p0_smoother ( x : f32 ) -> f32 {

	var p0_nodeVar0 : f32;

	p0_nodeVar0 = clamp( ( 1.0 - x ), 0.0, 1.0 );

	return ( ( p0_nodeVar0 * p0_nodeVar0 ) * ( 3.0 - ( p0_nodeVar0 * 2.0 ) ) );

}

fn p0_noisea ( pos : vec3<f32> ) -> f32 {

	var p0_nodeVar0 : vec3<f32>;

	p0_nodeVar0 = fract( ( pos * vec3<f32>( 2.23606797749979 ) ) );
	p0_nodeVar0 = ( p0_nodeVar0 + vec3<f32>( dot( p0_nodeVar0, ( p0_nodeVar0 + vec3<f32>( 31.4159, 27.1828, 14.142 ) ) ) ) );

	return ( ( fract( ( p0_nodeVar0.z * ( p0_nodeVar0.x + p0_nodeVar0.y ) ) ) * 2.0 ) - 1.0 );

}

fn p0_noiseg ( pos : vec3<f32> ) -> f32 {

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
	var nodeVar14 : f32;
	var nodeVar15 : f32;
	var nodeVar16 : f32;
	var nodeVar17 : f32;
	var nodeVar18 : f32;
	var nodeVar19 : f32;

	p0_nodeVar0 = floor( pos.x );
	nodeVar1 = ( p0_nodeVar0 + 1.0 );
	nodeVar2 = floor( pos.y );
	nodeVar3 = ( nodeVar2 + 1.0 );
	nodeVar4 = floor( pos.z );
	nodeVar5 = ( nodeVar4 + 1.0 );
	nodeVar6 = p0_smoother( fract( pos.x ) );
	nodeVar7 = p0_smoother( fract( pos.y ) );
	nodeVar8 = p0_smoother( fract( pos.z ) );
	nodeVar9 = p0_smoother( ( 1.0 - nodeVar6 ) );
	nodeVar10 = p0_smoother( ( 1.0 - nodeVar7 ) );
	nodeVar11 = p0_smoother( ( 1.0 - nodeVar8 ) );
	nodeVar12 = ( ( ( p0_noisea( vec3<f32>( p0_nodeVar0, nodeVar2, nodeVar4 ) ) * nodeVar9 ) * nodeVar10 ) * nodeVar11 );
	nodeVar13 = ( ( ( p0_noisea( vec3<f32>( p0_nodeVar0, nodeVar2, nodeVar5 ) ) * nodeVar9 ) * nodeVar10 ) * nodeVar8 );
	nodeVar14 = ( ( ( p0_noisea( vec3<f32>( p0_nodeVar0, nodeVar3, nodeVar4 ) ) * nodeVar9 ) * nodeVar7 ) * nodeVar11 );
	nodeVar15 = ( ( ( p0_noisea( vec3<f32>( p0_nodeVar0, nodeVar3, nodeVar5 ) ) * nodeVar9 ) * nodeVar7 ) * nodeVar8 );
	nodeVar16 = ( ( ( p0_noisea( vec3<f32>( nodeVar1, nodeVar2, nodeVar4 ) ) * nodeVar6 ) * nodeVar10 ) * nodeVar11 );
	nodeVar17 = ( ( ( p0_noisea( vec3<f32>( nodeVar1, nodeVar2, nodeVar5 ) ) * nodeVar6 ) * nodeVar10 ) * nodeVar8 );
	nodeVar18 = ( ( ( p0_noisea( vec3<f32>( nodeVar1, nodeVar3, nodeVar4 ) ) * nodeVar6 ) * nodeVar7 ) * nodeVar11 );
	nodeVar19 = ( ( ( p0_noisea( vec3<f32>( nodeVar1, nodeVar3, nodeVar5 ) ) * nodeVar6 ) * nodeVar7 ) * nodeVar8 );

	return ( ( ( ( ( ( ( nodeVar12 + nodeVar13 ) + nodeVar14 ) + nodeVar15 ) + nodeVar16 ) + nodeVar17 ) + nodeVar18 ) + nodeVar19 );

}

fn p0_dysonSphereRaw ( position : vec3<f32>, scale : f32, complexity : f32, color : vec3<f32>, background : vec3<f32>, seed : f32 ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : f32;

	p0_nodeVar0 = ( ( position * vec3<f32>( exp( ( ( scale / 2.0 ) + 0.5 ) ) ) ) + vec3<f32>( seed ) );
	nodeVar1 = vec3<f32>( 0.0, 0.0, 0.0 );
	nodeVar2 = 1.0;

	for ( var i : i32 = 0; i < i32( ( complexity + 4.0 ) ); i ++ ) {

		nodeVar1 = ( nodeVar1 + vec3<f32>( p0_noiseg( ( p0_nodeVar0 * vec3<f32>( nodeVar2 ) ) ) ) );
		nodeVar2 = ( nodeVar2 + nodeVar2 );

	}


	return mix( background, color, ( ( nodeVar1.x + 1.0 ) / 5.0 ) );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x * knobs.frameRect.z / (knobs.resolution.y * knobs.frameRect.w), 1.0 - 2.0 * door_uv.y, 0.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_dysonSphereRaw( nodeVarying4, f32(knobs.scale), f32(knobs.complexity), vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.background.x, knobs.background.y, knobs.background.z), 0.0 ), 1.0 );
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

// Impact: TSLFX by Verekia (MIT, github.com/verekia/tslfx), by three.js's own builder (engine/tsl/noise_fx_shelf.ts)
// --label:Generate
// --track@duration:Duration,0.1,3,0.5,0.1
// --track@vesicaCount:Vesica Count,0,15,6,1
// --track@circleSizeStart:Circle Size Start,0,1,0,0.01
// --track@circleSizeEnd:Circle Size End,0,1,0.6,0.01
// --track@circleThickness:Circle Thickness,0,1,0.13,0.01
// --track@circleColor_x:Circle Color r,0,1,1,0.001
// --track@circleColor_y:Circle Color g,0,1,0.1,0.001
// --track@circleColor_z:Circle Color b,0,1,0,0.001
// --track@vesicaColor_x:Vesica Color r,0,1,1,0.001
// --track@vesicaColor_y:Vesica Color g,0,1,0.6,0.001
// --track@vesicaColor_z:Vesica Color b,0,1,0,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  duration: f32,
  vesicaCount: f32,
  circleSizeStart: f32,
  circleSizeEnd: f32,
  circleThickness: f32,
  circleColor: vec3<f32>,
  vesicaColor: vec3<f32>,
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
var<private> p0_nodeVar0 : f32;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : u32;
var<private> p0_nodeVar5 : u32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec2<f32>;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar13 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = ( f32(knobs.circleThickness) * 0.5 );
	p0_nodeVar1 = ( ( ( nodeVarying4 * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0 ) ) * vec2<f32>( f32(knobs.resolution.x / knobs.resolution.y), 1.0 ) );
	p0_nodeVar2 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );

	for ( var i : i32 = 0; i < i32( f32(knobs.vesicaCount) ); i ++ ) {

		p0_nodeVar4 = ( ( u32( ( ( f32(0.0) + 0.0 ) + f32( i ) ) ) * 747796405u ) + 2891336453u );
		p0_nodeVar5 = ( ( ( p0_nodeVar4 >> ( ( p0_nodeVar4 >> 28u ) + 4u ) ) ^ p0_nodeVar4 ) * 277803737u );
		p0_nodeVar6 = ( ( ( ( f32( ( ( p0_nodeVar5 >> 22u ) ^ p0_nodeVar5 ) ) * 2.3283064365386963e-10 ) * 2.0 ) - 1.0 ) * 3.141592653589793 );
		p0_nodeVar7 = cos( p0_nodeVar6 );
		p0_nodeVar8 = sin( p0_nodeVar6 );
		p0_nodeVar9 = abs( ( ( mat2x2<f32>( p0_nodeVar7, p0_nodeVar8, ( - p0_nodeVar8 ), p0_nodeVar7 ) * p0_nodeVar1 ) + vec2<f32>( 0.0, ( f32(fract(knobs.time / max(knobs.duration, 0.001))) * 0.9 ) ) ) );
		p0_nodeVar10 = ( 1.0 * ( ( ( 1.0 - f32(fract(knobs.time / max(knobs.duration, 0.001))) ) * f32(fract(knobs.time / max(knobs.duration, 0.001))) ) * 2.0 ) );
		p0_nodeVar11 = ( 0.8 * ( ( ( 1.0 - f32(fract(knobs.time / max(knobs.duration, 0.001))) ) * f32(fract(knobs.time / max(knobs.duration, 0.001))) ) * 2.0 ) );
		p0_nodeVar12 = sqrt( ( ( p0_nodeVar10 * p0_nodeVar10 ) - ( p0_nodeVar11 * p0_nodeVar11 ) ) );

		if ( ( ( ( p0_nodeVar9.y - p0_nodeVar12 ) * p0_nodeVar11 ) > ( p0_nodeVar9.x * p0_nodeVar12 ) ) ) {

			p0_nodeVar3 = length( ( p0_nodeVar9 - vec2<f32>( 0.0, p0_nodeVar12 ) ) );

		} else {

			p0_nodeVar3 = ( length( ( p0_nodeVar9 - vec2<f32>( ( -1.0 * p0_nodeVar11 ), 0.0 ) ) ) - p0_nodeVar10 );

		}

		p0_nodeVar2 = ( p0_nodeVar2 + ( vec4<f32>( ( 1.0 - step( 0.0, p0_nodeVar3 ) ) ) * vec4<f32>( ( vec4<f32>(knobs.vesicaColor.x, knobs.vesicaColor.y, knobs.vesicaColor.z, 1.0).xyz * vec3<f32>( vec4<f32>(knobs.vesicaColor.x, knobs.vesicaColor.y, knobs.vesicaColor.z, 1.0).w ) ), vec4<f32>(knobs.vesicaColor.x, knobs.vesicaColor.y, knobs.vesicaColor.z, 1.0).w ) ) );

	}

	p0_DiffuseColor = ( ( vec4<f32>( ( 1.0 - step( p0_nodeVar0, abs( ( length( p0_nodeVar1 ) - ( ( f32(knobs.circleSizeStart) + ( ( f32(knobs.circleSizeEnd) - f32(knobs.circleSizeStart) ) * pow( f32(fract(knobs.time / max(knobs.duration, 0.001))), 0.5 ) ) ) - p0_nodeVar0 ) ) ) ) ) ) * vec4<f32>( ( vec4<f32>(knobs.circleColor.x, knobs.circleColor.y, knobs.circleColor.z, 1.0).xyz * vec3<f32>( vec4<f32>(knobs.circleColor.x, knobs.circleColor.y, knobs.circleColor.z, 1.0).w ) ), vec4<f32>(knobs.circleColor.x, knobs.circleColor.y, knobs.circleColor.z, 1.0).w ) ) + p0_nodeVar2 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar13 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar13;

	// result

	p0_output.color = p0_nodeVar13;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

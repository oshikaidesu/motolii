// Posterize: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Flattens the image into a few bands of color.
// --track@levels:Levels,2,16,5,1
// --track@gamma:Gamma,0.4,2.5,1,0.01
// --check@mode:Mode,0
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  levels: f32,
  gamma: f32,
  mode: f32,
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
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : f32;
var<private> p0_nodeVar2 : bool;
var<private> p0_nodeVar3 : vec3<f32>;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : vec3<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : vec3<f32>;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : vec3<f32>;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : vec3<f32>;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec3<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : vec4<f32>;
var<private> p0_nodeVar24 : vec3<f32>;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : vec3<f32>;
var<private> p0_nodeVar27 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar28 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar2 = ( f32(knobs.mode) > 0.5 );

	if ( p0_nodeVar2 ) {

		p0_nodeVar3 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar4 = dot( p0_nodeVar3, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		p0_nodeVar5 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar6 = ( pow( ( floor( ( ( pow( clamp( p0_nodeVar4, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar5 ) + 0.5 ) ) / p0_nodeVar5 ), f32((1.0 / knobs.gamma)) ) / max( p0_nodeVar4, 0.001 ) );
		p0_nodeVar1 = clamp( vec3<f32>( ( p0_nodeVar3.x * p0_nodeVar6 ), ( p0_nodeVar3.y * p0_nodeVar6 ), ( p0_nodeVar3.z * p0_nodeVar6 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).x;

	} else {

		p0_nodeVar7 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar8 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar1 = vec3<f32>( pow( ( floor( ( ( pow( clamp( p0_nodeVar7.x, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar8 ) + 0.5 ) ) / p0_nodeVar8 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar7.y, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar8 ) + 0.5 ) ) / p0_nodeVar8 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar7.z, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar8 ) + 0.5 ) ) / p0_nodeVar8 ), f32((1.0 / knobs.gamma)) ) ).x;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar10 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar11 = dot( p0_nodeVar10, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		p0_nodeVar12 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar13 = ( pow( ( floor( ( ( pow( clamp( p0_nodeVar11, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar12 ) + 0.5 ) ) / p0_nodeVar12 ), f32((1.0 / knobs.gamma)) ) / max( p0_nodeVar11, 0.001 ) );
		p0_nodeVar9 = clamp( vec3<f32>( ( p0_nodeVar10.x * p0_nodeVar13 ), ( p0_nodeVar10.y * p0_nodeVar13 ), ( p0_nodeVar10.z * p0_nodeVar13 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).y;

	} else {

		p0_nodeVar14 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar15 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar9 = vec3<f32>( pow( ( floor( ( ( pow( clamp( p0_nodeVar14.x, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar15 ) + 0.5 ) ) / p0_nodeVar15 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar14.y, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar15 ) + 0.5 ) ) / p0_nodeVar15 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar14.z, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar15 ) + 0.5 ) ) / p0_nodeVar15 ), f32((1.0 / knobs.gamma)) ) ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar17 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar18 = dot( p0_nodeVar17, vec3<f32>( 0.2126, 0.7152, 0.0722 ) );
		p0_nodeVar19 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar20 = ( pow( ( floor( ( ( pow( clamp( p0_nodeVar18, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar19 ) + 0.5 ) ) / p0_nodeVar19 ), f32((1.0 / knobs.gamma)) ) / max( p0_nodeVar18, 0.001 ) );
		p0_nodeVar16 = clamp( vec3<f32>( ( p0_nodeVar17.x * p0_nodeVar20 ), ( p0_nodeVar17.y * p0_nodeVar20 ), ( p0_nodeVar17.z * p0_nodeVar20 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ).z;

	} else {

		p0_nodeVar21 = vec3<f32>( p0_nodeVar0.x, p0_nodeVar0.y, p0_nodeVar0.z );
		p0_nodeVar22 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
		p0_nodeVar16 = vec3<f32>( pow( ( floor( ( ( pow( clamp( p0_nodeVar21.x, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar22 ) + 0.5 ) ) / p0_nodeVar22 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar21.y, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar22 ) + 0.5 ) ) / p0_nodeVar22 ), f32((1.0 / knobs.gamma)) ), pow( ( floor( ( ( pow( clamp( p0_nodeVar21.z, 0.0, 1.0 ), f32(knobs.gamma) ) * p0_nodeVar22 ) + 0.5 ) ) / p0_nodeVar22 ), f32((1.0 / knobs.gamma)) ) ).z;

	}

	p0_nodeVar23 = vec4<f32>( vec3<f32>( p0_nodeVar1, p0_nodeVar9, p0_nodeVar16 ), 1.0 );
	p0_nodeVar24 = vec3<f32>( p0_nodeVar23.x, p0_nodeVar23.y, p0_nodeVar23.z );
	p0_nodeVar25 = ( ( ( p0_nodeVar24.x * 0.2126 ) + ( p0_nodeVar24.y * 0.7152 ) ) + ( p0_nodeVar24.z * 0.0722 ) );
	p0_nodeVar26 = mix( vec3<f32>( p0_nodeVar25, p0_nodeVar25, p0_nodeVar25 ), p0_nodeVar24, f32(1.0) );
	p0_nodeVar27 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar26.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar26.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar26.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar26.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar26.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar26.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar26.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar26.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar26.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar23.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar27.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar27.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar28 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar28;

	// result

	p0_output.color = p0_nodeVar28;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

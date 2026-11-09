// ASCII Light: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Redraws the image as text characters, like an old terminal.
// --pass@t0:0,1,s1,s1
// --pass@:0,0,s1,s1
// --track@columns:Columns,4,400,80,1
// --track@boldness:Boldness,-1,1,0,0.01
// --check@colorMode:Color Mode,1
// --track@monoColor_x:Tint r,0,1,0.913098651791473,0.001
// --track@monoColor_y:Tint g,0,1,0.913098651791473,0.001
// --track@monoColor_z:Tint b,0,1,0.8713671191959567,0.001
// --track@bgOpacity:Background,0,1,0,0.01
// --track@signalBlackPoint:Black Point,0,1,0,0.01
// --track@signalWhitePoint:White Point,0,1,1,0.01
// --check@invert:Invert,0
// --image@image0:sl_ascii_light.0.png
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  columns: f32,
  boldness: f32,
  colorMode: f32,
  monoColor: vec3<f32>,
  bgOpacity: f32,
  signalBlackPoint: f32,
  signalWhitePoint: f32,
  invert: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var image0: texture_2d<f32>;
@group(0) @binding(5) var image0_sampler: sampler;
@group(0) @binding(6) var<uniform> knobs: Knobs;
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
fn image_read(t: texture_2d<f32>, s: sampler, uv: vec2f) -> vec4f { return textureSampleLevel(t, s, uv, 0.0); }
fn image_read_level(t: texture_2d<f32>, s: sampler, uv: vec2f, level: f32) -> vec4f { return textureSampleLevel(t, s, uv, level); }
fn image_load(t: texture_2d<f32>, p: vec2i, level: u32) -> vec4f { return textureLoad(t, p, level); }

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : vec4<f32>;
var<private> p0_nodeVar4 : vec4<f32>;
var<private> p0_nodeVar5 : vec4<f32>;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : vec4<f32>;
var<private> p0_nodeVar8 : vec4<f32>;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar11 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( f32((1.0 / knobs.columns)), f32((2.064516129032258 * (knobs.resolution.x / (knobs.columns * knobs.resolution.y)) + 0)) );
	p0_nodeVar1 = ( vec2<f32>( f32(0.0), f32(0.0) ) + ( floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32((0.996969696969697 * knobs.columns + 0.9454545454545666)), f32((0.48398833828787835 * (knobs.columns * knobs.resolution.y / knobs.resolution.x) + 0.3994682106475196)) ) ) ) * p0_nodeVar0 ) );
	p0_nodeVar2 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.16666666666666666, 0.16666666666666666 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar3 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.5, 0.16666666666666666 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar4 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.8333333333333334, 0.16666666666666666 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar5 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.16666666666666666, 0.5 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar6 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.5, 0.5 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar7 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.8333333333333334, 0.5 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar8 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.16666666666666666, 0.8333333333333334 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar9 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.5, 0.8333333333333334 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_nodeVar10 = picture_read( clamp( ( p0_nodeVar1 + ( vec2<f32>( 0.8333333333333334, 0.8333333333333334 ) * p0_nodeVar0 ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p0_DiffuseColor = vec4<f32>( ( ( ( ( ( ( ( ( ( ( vec3<f32>( 0.0, 0.0, 0.0 ) + p0_nodeVar2.xyz ) + p0_nodeVar3.xyz ) + p0_nodeVar4.xyz ) + p0_nodeVar5.xyz ) + p0_nodeVar6.xyz ) + p0_nodeVar7.xyz ) + p0_nodeVar8.xyz ) + p0_nodeVar9.xyz ) + p0_nodeVar10.xyz ) / vec3<f32>( 9.0 ) ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar11 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar11;

	// result

	p0_output.color = p0_nodeVar11;

	return p0_output;

}

// structs

struct p1_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p1_output : p1_OutputStruct;

// uniforms


// vars
var<private> p1_DiffuseColor : vec4<f32>;
var<private> p1_nodeVar0 : vec4<f32>;
var<private> p1_nodeVar1 : vec2<f32>;
var<private> p1_nodeVar2 : vec2<f32>;
var<private> p1_nodeVar3 : vec4<f32>;
var<private> p1_nodeVar4 : f32;
var<private> p1_nodeVar5 : f32;
var<private> p1_nodeVar6 : vec2<f32>;
var<private> p1_nodeVar7 : vec2<f32>;
var<private> p1_nodeVar8 : vec2<f32>;
var<private> p1_nodeVar9 : vec2<f32>;
var<private> p1_nodeVar10 : vec4<f32>;
var<private> p1_nodeVar11 : f32;
var<private> p1_nodeVar12 : vec3<f32>;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : vec4<f32>;
var<private> p1_nodeVar15 : vec3<f32>;
var<private> p1_nodeVar16 : f32;
var<private> p1_nodeVar17 : vec3<f32>;
var<private> p1_nodeVar18 : vec4<f32>;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar19 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p1_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar2 = floor( ( ( p1_nodeVar1 - vec2<f32>( f32(0.0), f32(0.0) ) ) / vec2<f32>( f32((1.0 / knobs.columns)), f32((2.064516129032258 * (knobs.resolution.x / (knobs.columns * knobs.resolution.y)) + 0)) ) ) );
	p1_nodeVar3 = target_read( t0, t0_sampler, clamp( ( ( ( p1_nodeVar2 + vec2<f32>( ( ( 1.0 * 0.5 ) - 0.5 ) ) ) + vec2<f32>( 0.5, 0.5 ) ) / vec2<f32>( f32((0.996969696969697 * knobs.columns + 0.9454545454545666)), f32((0.48398833828787835 * (knobs.columns * knobs.resolution.y / knobs.resolution.x) + 0.3994682106475196)) ) ), vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) ) );
	p1_nodeVar4 = clamp( ( ( dot( p1_nodeVar3.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) - f32(knobs.signalBlackPoint) ) / max( ( f32(knobs.signalWhitePoint) - f32(knobs.signalBlackPoint) ), 0.001 ) ), 0.0, 1.0 );
	p1_nodeVar5 = floor( ( ( mix( p1_nodeVar4, ( 1.0 - p1_nodeVar4 ), f32(knobs.invert) ) * ( f32(10.0) - 1.0 ) ) + 0.5 ) );
	p1_nodeVar6 = vec2<f32>( f32((1.0 / knobs.columns)), f32((2.064516129032258 * (knobs.resolution.x / (knobs.columns * knobs.resolution.y)) + 0)) );
	p1_nodeVar7 = ( ( p1_nodeVar1 - ( vec2<f32>( f32(0.0), f32(0.0) ) + ( p1_nodeVar2 * p1_nodeVar6 ) ) ) / ( p1_nodeVar6 * vec2<f32>( 1.0 ) ) );
	p1_nodeVar8 = clamp( p1_nodeVar7, vec2<f32>( 0.0, 0.0 ), vec2<f32>( 1.0, 1.0 ) );
	p1_nodeVar9 = vec2<f32>( ( f32(0.13953488372093023) + ( p1_nodeVar8.x * f32(0.7209302325581395) ) ), ( f32(0.07894736842105263) + ( p1_nodeVar8.y * f32(0.8421052631578947) ) ) );
	p1_nodeVar10 = image_read( image0, image0_sampler, vec2<f32>( ( ( ( p1_nodeVar5 - ( floor( ( p1_nodeVar5 / f32(4.0) ) ) * f32(4.0) ) ) + p1_nodeVar9.x ) / f32(4.0) ), ( ( floor( ( p1_nodeVar5 / f32(4.0) ) ) + p1_nodeVar9.y ) / f32(4.0) ) ) );
	p1_nodeVar11 = ( clamp( smoothstep( -0.5, 0.5, ( ( ( ( p1_nodeVar10.x - 0.5 ) * f32(8.0) ) + ( f32(knobs.boldness) * 2.0 ) ) * ( ( ( f32((2.064516129032258 * (knobs.resolution.x / knobs.columns) + 0)) * 1.0 ) * f32(1.0) ) / f32(64.0) ) ) ), 0.0, 1.0 ) * ( ( ( step( 0.0, p1_nodeVar7.x ) * step( p1_nodeVar7.x, 1.0 ) ) * step( 0.0, p1_nodeVar7.y ) ) * step( p1_nodeVar7.y, 1.0 ) ) );
	p1_nodeVar12 = mix( vec3<f32>( 0.0, 0.0, 0.0 ), p1_nodeVar3.xyz, step( 0.0, p1_nodeVar11 ) );
	p1_nodeVar13 = clamp( ( ( dot( p1_nodeVar12, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) - f32(knobs.signalBlackPoint) ) / max( ( f32(knobs.signalWhitePoint) - f32(knobs.signalBlackPoint) ), 0.001 ) ), 0.0, 1.0 );
	p1_nodeVar14 = vec4<f32>( mix( ( ( p1_nodeVar12 * vec3<f32>( f32(knobs.bgOpacity) ) ) * vec3<f32>( f32((-1 * knobs.colorMode + 1)) ) ), mix( ( vec3<f32>( f32(knobs.monoColor.x), f32(knobs.monoColor.y), f32(knobs.monoColor.z) ) * vec3<f32>( mix( p1_nodeVar13, ( 1.0 - p1_nodeVar13 ), f32(knobs.invert) ) ) ), p1_nodeVar12, f32((-1 * knobs.colorMode + 1)) ), max( 0.0, p1_nodeVar11 ) ), 1.0 );
	p1_nodeVar15 = vec3<f32>( p1_nodeVar14.x, p1_nodeVar14.y, p1_nodeVar14.z );
	p1_nodeVar16 = ( ( ( p1_nodeVar15.x * 0.2126 ) + ( p1_nodeVar15.y * 0.7152 ) ) + ( p1_nodeVar15.z * 0.0722 ) );
	p1_nodeVar17 = mix( vec3<f32>( p1_nodeVar16, p1_nodeVar16, p1_nodeVar16 ), p1_nodeVar15, f32(1.0) );
	p1_nodeVar18 = vec4<f32>( clamp( vec3<f32>( ( ( ( p1_nodeVar17.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p1_nodeVar17.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p1_nodeVar17.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p1_nodeVar17.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p1_nodeVar17.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p1_nodeVar17.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p1_nodeVar17.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p1_nodeVar17.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p1_nodeVar17.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p1_nodeVar14.w, 0.0, 1.0 ) );
	p1_DiffuseColor = vec4<f32>( mix( p1_nodeVar0.xyz, p1_nodeVar18.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p1_nodeVar18.w, 0.0, 1.0 ) ) ), clamp( p1_nodeVar0.w, 0.0, 1.0 ) );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_nodeVar19 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar19;

	// result

	p1_output.color = p1_nodeVar19;

	return p1_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p1_main(door_uv).color);
}

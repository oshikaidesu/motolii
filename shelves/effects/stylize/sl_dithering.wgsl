// Dithering: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Reduces the image to a few colors with ordered or textured dithering patterns.
// --track@algorithm:Algorithm,0,3,1,1
// --track@pixelSize:Pixel Size,1,24,1,1
// --track@spread:Strength,0,1,0.5,0.01
// --track@levels:Levels,2,16,4,1
// --track@dotScale:Dot Scale,0.1,1,1,0.1
// --check@animateDither:Animate Dither,0
// --track@ditherSpeed:Dither Speed,0,3,1,0.5
// --check@chromaticSplit:Chromatic Split,0
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  algorithm: f32,
  pixelSize: f32,
  spread: f32,
  levels: f32,
  dotScale: f32,
  animateDither: f32,
  ditherSpeed: f32,
  chromaticSplit: f32,
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
const own0_read_texels = array<vec4f, 16>(vec4f(0.0,0.0,0.0,1.0),vec4f(0.5019607843137255,0.5019607843137255,0.5019607843137255,1.0),vec4f(0.12549019607843137,0.12549019607843137,0.12549019607843137,1.0),vec4f(0.6235294117647059,0.6235294117647059,0.6235294117647059,1.0),vec4f(0.7490196078431373,0.7490196078431373,0.7490196078431373,1.0),vec4f(0.25098039215686274,0.25098039215686274,0.25098039215686274,1.0),vec4f(0.8745098039215686,0.8745098039215686,0.8745098039215686,1.0),vec4f(0.3764705882352941,0.3764705882352941,0.3764705882352941,1.0),vec4f(0.18823529411764706,0.18823529411764706,0.18823529411764706,1.0),vec4f(0.6862745098039216,0.6862745098039216,0.6862745098039216,1.0),vec4f(0.06274509803921569,0.06274509803921569,0.06274509803921569,1.0),vec4f(0.5607843137254902,0.5607843137254902,0.5607843137254902,1.0),vec4f(0.9372549019607843,0.9372549019607843,0.9372549019607843,1.0),vec4f(0.4392156862745098,0.4392156862745098,0.4392156862745098,1.0),vec4f(0.8117647058823529,0.8117647058823529,0.8117647058823529,1.0),vec4f(0.3137254901960784,0.3137254901960784,0.3137254901960784,1.0));
fn own0_read_at(x: i32, y: i32) -> vec4f { return own0_read_texels[((y % 4) + 4) % 4 * 4 + ((x % 4) + 4) % 4]; }
fn own0_read(uv: vec2f) -> vec4f {
  let p = vec2f(fract(uv.x), fract(uv.y)) * vec2f(4.0, 4.0) - vec2f(0.5);
  let a = vec2i(floor(p)); let f = fract(p);
  return own0_read_at(a.x + i32(f.x + 0.5), a.y + i32(f.y + 0.5));
}
fn own0_read_load(p: vec2i, level: u32) -> vec4f { return own0_read((vec2f(p) + 0.5) / vec2f(4.0, 4.0)); }
fn own0_read_level(uv: vec2f, level: f32) -> vec4f { return own0_read(uv); }

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : f32;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : vec2<f32>;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : vec4<f32>;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : vec2<f32>;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : vec3<f32>;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : vec3<f32>;
var<private> p0_nodeVar19 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar20 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = max( f32(knobs.pixelSize), 1.0 );
	p0_nodeVar3 = max( ( f32(knobs.resolution.x) / p0_nodeVar2 ), 1.0 );
	p0_nodeVar4 = max( ( f32(knobs.resolution.y) / p0_nodeVar2 ), 1.0 );
	p0_nodeVar5 = vec2<f32>( floor( ( p0_nodeVar1.x * p0_nodeVar3 ) ), floor( ( p0_nodeVar1.y * p0_nodeVar4 ) ) );
	p0_nodeVar6 = picture_read( vec2<f32>( ( ( p0_nodeVar5.x + 0.5 ) / p0_nodeVar3 ), ( ( p0_nodeVar5.y + 0.5 ) / p0_nodeVar4 ) ) );
	p0_nodeVar7 = ( ( p0_nodeVar5 / vec2<f32>( f32(array<f32, 4>(2.0, 4.0, 8.0, 64.0)[u32(knobs.algorithm)]) ) ) + vec2<f32>( ( ( f32(knobs.time) * f32(knobs.ditherSpeed) ) * f32(knobs.animateDither) ) ) );
	p0_nodeVar8 = own0_read( p0_nodeVar7 );
	p0_nodeVar9 = max( ( f32(knobs.levels) - 1.0 ), 1.0 );
	p0_nodeVar10 = ( f32(knobs.chromaticSplit) / f32(array<f32, 4>(2.0, 4.0, 8.0, 64.0)[u32(knobs.algorithm)]) );
	p0_nodeVar11 = own0_read( ( p0_nodeVar7 + vec2<f32>( p0_nodeVar10, 0.0 ) ) );
	p0_nodeVar12 = own0_read( ( p0_nodeVar7 + vec2<f32>( 0.0, p0_nodeVar10 ) ) );
	p0_nodeVar13 = ( 0.5 * f32(knobs.dotScale) );
	p0_nodeVar14 = ( fract( ( p0_nodeVar1 * vec2<f32>( p0_nodeVar3, p0_nodeVar4 ) ) ) - vec2<f32>( 0.5, 0.5 ) );
	p0_nodeVar15 = vec4<f32>( ( clamp( vec3<f32>( ( floor( ( ( ( p0_nodeVar6.x + ( ( p0_nodeVar8.x - 0.5 ) * f32(knobs.spread) ) ) * p0_nodeVar9 ) + 0.5 ) ) / p0_nodeVar9 ), ( floor( ( ( ( p0_nodeVar6.y + ( ( p0_nodeVar11.x - 0.5 ) * f32(knobs.spread) ) ) * p0_nodeVar9 ) + 0.5 ) ) / p0_nodeVar9 ), ( floor( ( ( ( p0_nodeVar6.z + ( ( p0_nodeVar12.x - 0.5 ) * f32(knobs.spread) ) ) * p0_nodeVar9 ) + 0.5 ) ) / p0_nodeVar9 ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ) * vec3<f32>( smoothstep( p0_nodeVar13, ( p0_nodeVar13 - 0.01 ), max( abs( p0_nodeVar14.x ), abs( p0_nodeVar14.y ) ) ) ) ), 1.0 );
	p0_nodeVar16 = vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z );
	p0_nodeVar17 = ( ( ( p0_nodeVar16.x * 0.2126 ) + ( p0_nodeVar16.y * 0.7152 ) ) + ( p0_nodeVar16.z * 0.0722 ) );
	p0_nodeVar18 = mix( vec3<f32>( p0_nodeVar17, p0_nodeVar17, p0_nodeVar17 ), p0_nodeVar16, f32(1.0) );
	p0_nodeVar19 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar18.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar18.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar18.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar18.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar18.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar18.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar18.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar18.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar18.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar15.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar19.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar19.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar20 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar20;

	// result

	p0_output.color = p0_nodeVar20;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

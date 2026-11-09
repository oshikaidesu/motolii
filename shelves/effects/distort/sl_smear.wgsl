// Progressive Blur: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Blur that ramps from sharp to soft across the frame.
// --track@angle:Angle,0,360,0,1
// --track@start:Start,0,1,0.25,0.01
// --track@end:End,0,1,0.75,0.01
// --track@strength:Strength,0,64,24,1
// --track@samples:Samples,4,32,12,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  angle: f32,
  start: f32,
  end: f32,
  strength: f32,
  samples: f32,
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
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec2<f32>;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : vec4<f32>;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : vec4<f32>;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : vec4<f32>;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : vec4<f32>;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec4<f32>;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : vec4<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec4<f32>;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec4<f32>;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : vec4<f32>;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : vec4<f32>;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : vec4<f32>;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : vec4<f32>;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : vec4<f32>;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : f32;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : vec4<f32>;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : f32;
var<private> p0_nodeVar92 : f32;
var<private> p0_nodeVar93 : vec4<f32>;
var<private> p0_nodeVar94 : f32;
var<private> p0_nodeVar95 : f32;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : vec4<f32>;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : f32;
var<private> p0_nodeVar102 : f32;
var<private> p0_nodeVar103 : vec4<f32>;
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : f32;
var<private> p0_nodeVar107 : f32;
var<private> p0_nodeVar108 : vec4<f32>;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : f32;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : vec4<f32>;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : vec4<f32>;
var<private> p0_nodeVar119 : f32;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : f32;
var<private> p0_nodeVar122 : f32;
var<private> p0_nodeVar123 : vec4<f32>;
var<private> p0_nodeVar124 : f32;
var<private> p0_nodeVar125 : f32;
var<private> p0_nodeVar126 : f32;
var<private> p0_nodeVar127 : f32;
var<private> p0_nodeVar128 : vec4<f32>;
var<private> p0_nodeVar129 : f32;
var<private> p0_nodeVar130 : f32;
var<private> p0_nodeVar131 : f32;
var<private> p0_nodeVar132 : f32;
var<private> p0_nodeVar133 : vec4<f32>;
var<private> p0_nodeVar134 : f32;
var<private> p0_nodeVar135 : f32;
var<private> p0_nodeVar136 : f32;
var<private> p0_nodeVar137 : f32;
var<private> p0_nodeVar138 : vec4<f32>;
var<private> p0_nodeVar139 : f32;
var<private> p0_nodeVar140 : f32;
var<private> p0_nodeVar141 : f32;
var<private> p0_nodeVar142 : f32;
var<private> p0_nodeVar143 : vec4<f32>;
var<private> p0_nodeVar144 : f32;
var<private> p0_nodeVar145 : f32;
var<private> p0_nodeVar146 : f32;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : vec4<f32>;
var<private> p0_nodeVar149 : f32;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : vec4<f32>;
var<private> p0_nodeVar154 : f32;
var<private> p0_nodeVar155 : f32;
var<private> p0_nodeVar156 : f32;
var<private> p0_nodeVar157 : f32;
var<private> p0_nodeVar158 : vec4<f32>;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : f32;
var<private> p0_nodeVar161 : f32;
var<private> p0_nodeVar162 : f32;
var<private> p0_nodeVar163 : vec4<f32>;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : f32;
var<private> p0_nodeVar166 : f32;
var<private> p0_nodeVar167 : f32;
var<private> p0_nodeVar168 : vec4<f32>;
var<private> p0_nodeVar169 : f32;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : vec4<f32>;
var<private> p0_nodeVar172 : vec3<f32>;
var<private> p0_nodeVar173 : f32;
var<private> p0_nodeVar174 : vec3<f32>;
var<private> p0_nodeVar175 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar176 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = picture_read( p0_nodeVar1 );
	p0_nodeVar3 = ( f32(knobs.angle) * 0.017453292519943295 );
	p0_nodeVar4 = cos( p0_nodeVar3 );
	p0_nodeVar5 = sin( p0_nodeVar3 );
	p0_nodeVar6 = vec2<f32>( p0_nodeVar4, p0_nodeVar5 );
	p0_nodeVar7 = vec2<f32>( ( p0_nodeVar1.x * f32(knobs.resolution.x) ), ( p0_nodeVar1.y * f32(knobs.resolution.y) ) );
	p0_nodeVar8 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 1.7 ), ( p0_nodeVar7.y + 8.3 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar9 = vec2<f32>( ( - p0_nodeVar5 ), p0_nodeVar4 );
	p0_nodeVar10 = ( smoothstep( min( f32(knobs.start), f32(knobs.end) ), max( f32(knobs.start), f32(knobs.end) ), ( ( p0_nodeVar1.x * p0_nodeVar4 ) + ( p0_nodeVar1.y * p0_nodeVar5 ) ) ) * f32(knobs.strength) );
	p0_nodeVar11 = pow( 0.03125, 0.82 );
	p0_nodeVar12 = ( p0_nodeVar10 * ( ( p0_nodeVar11 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 3.1 ), ( p0_nodeVar7.x + 13.9 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar13 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar8 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar8 ) * 0.65 ) ) ) * p0_nodeVar12 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar8 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar8 ) * 0.65 ) ) ) * p0_nodeVar12 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar14 = ( step( 0.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar11 * 0.7 ) ) ) );
	p0_nodeVar15 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 18.83 ), ( p0_nodeVar7.y + 14.010000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar16 = pow( 0.0625, 0.82 );
	p0_nodeVar17 = ( p0_nodeVar10 * ( ( p0_nodeVar16 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 14.469999999999999 ), ( p0_nodeVar7.x + 21.07 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar18 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar15 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar15 ) * 0.65 ) ) ) * p0_nodeVar17 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar15 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar15 ) * 0.65 ) ) ) * p0_nodeVar17 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar19 = ( step( 1.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar16 * 0.7 ) ) ) );
	p0_nodeVar20 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 35.96 ), ( p0_nodeVar7.y + 19.72 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar21 = pow( 0.09375, 0.82 );
	p0_nodeVar22 = ( p0_nodeVar10 * ( ( p0_nodeVar21 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 25.84 ), ( p0_nodeVar7.x + 28.240000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar23 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar20 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar20 ) * 0.65 ) ) ) * p0_nodeVar22 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar20 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar20 ) * 0.65 ) ) ) * p0_nodeVar22 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar24 = ( step( 2.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar21 * 0.7 ) ) ) );
	p0_nodeVar25 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 53.09 ), ( p0_nodeVar7.y + 25.43 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar26 = pow( 0.125, 0.82 );
	p0_nodeVar27 = ( p0_nodeVar10 * ( ( p0_nodeVar26 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 37.21 ), ( p0_nodeVar7.x + 35.41 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar28 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar25 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar25 ) * 0.65 ) ) ) * p0_nodeVar27 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar25 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar25 ) * 0.65 ) ) ) * p0_nodeVar27 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar29 = ( step( 3.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar26 * 0.7 ) ) ) );
	p0_nodeVar30 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 70.22 ), ( p0_nodeVar7.y + 31.14 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar31 = pow( 0.15625, 0.82 );
	p0_nodeVar32 = ( p0_nodeVar10 * ( ( p0_nodeVar31 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 48.58 ), ( p0_nodeVar7.x + 42.58 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar33 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar30 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar30 ) * 0.65 ) ) ) * p0_nodeVar32 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar30 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar30 ) * 0.65 ) ) ) * p0_nodeVar32 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar34 = ( step( 4.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar31 * 0.7 ) ) ) );
	p0_nodeVar35 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 87.35 ), ( p0_nodeVar7.y + 36.85 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar36 = pow( 0.1875, 0.82 );
	p0_nodeVar37 = ( p0_nodeVar10 * ( ( p0_nodeVar36 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 59.949999999999996 ), ( p0_nodeVar7.x + 49.75 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar38 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar35 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar35 ) * 0.65 ) ) ) * p0_nodeVar37 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar35 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar35 ) * 0.65 ) ) ) * p0_nodeVar37 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar39 = ( step( 5.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar36 * 0.7 ) ) ) );
	p0_nodeVar40 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 104.48 ), ( p0_nodeVar7.y + 42.56 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar41 = pow( 0.21875, 0.82 );
	p0_nodeVar42 = ( p0_nodeVar10 * ( ( p0_nodeVar41 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 71.32 ), ( p0_nodeVar7.x + 56.919999999999995 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar43 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar40 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar40 ) * 0.65 ) ) ) * p0_nodeVar42 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar40 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar40 ) * 0.65 ) ) ) * p0_nodeVar42 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar44 = ( step( 6.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar41 * 0.7 ) ) ) );
	p0_nodeVar45 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 121.61 ), ( p0_nodeVar7.y + 48.269999999999996 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar46 = pow( 0.25, 0.82 );
	p0_nodeVar47 = ( p0_nodeVar10 * ( ( p0_nodeVar46 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 82.68999999999998 ), ( p0_nodeVar7.x + 64.09 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar48 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar45 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar45 ) * 0.65 ) ) ) * p0_nodeVar47 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar45 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar45 ) * 0.65 ) ) ) * p0_nodeVar47 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar49 = ( step( 7.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar46 * 0.7 ) ) ) );
	p0_nodeVar50 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 138.73999999999998 ), ( p0_nodeVar7.y + 53.980000000000004 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar51 = pow( 0.28125, 0.82 );
	p0_nodeVar52 = ( p0_nodeVar10 * ( ( p0_nodeVar51 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 94.05999999999999 ), ( p0_nodeVar7.x + 71.26 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar53 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar50 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar50 ) * 0.65 ) ) ) * p0_nodeVar52 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar50 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar50 ) * 0.65 ) ) ) * p0_nodeVar52 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar54 = ( step( 8.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar51 * 0.7 ) ) ) );
	p0_nodeVar55 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 155.86999999999998 ), ( p0_nodeVar7.y + 59.69 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar56 = pow( 0.3125, 0.82 );
	p0_nodeVar57 = ( p0_nodeVar10 * ( ( p0_nodeVar56 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 105.42999999999999 ), ( p0_nodeVar7.x + 78.43 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar58 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar55 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar55 ) * 0.65 ) ) ) * p0_nodeVar57 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar55 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar55 ) * 0.65 ) ) ) * p0_nodeVar57 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar59 = ( step( 9.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar56 * 0.7 ) ) ) );
	p0_nodeVar60 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 172.99999999999997 ), ( p0_nodeVar7.y + 65.4 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar61 = pow( 0.34375, 0.82 );
	p0_nodeVar62 = ( p0_nodeVar10 * ( ( p0_nodeVar61 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 116.79999999999998 ), ( p0_nodeVar7.x + 85.60000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar63 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar60 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar60 ) * 0.65 ) ) ) * p0_nodeVar62 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar60 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar60 ) * 0.65 ) ) ) * p0_nodeVar62 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar64 = ( step( 10.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar61 * 0.7 ) ) ) );
	p0_nodeVar65 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 190.12999999999997 ), ( p0_nodeVar7.y + 71.11 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar66 = pow( 0.375, 0.82 );
	p0_nodeVar67 = ( p0_nodeVar10 * ( ( p0_nodeVar66 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 128.17 ), ( p0_nodeVar7.x + 92.77000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar68 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar65 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar65 ) * 0.65 ) ) ) * p0_nodeVar67 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar65 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar65 ) * 0.65 ) ) ) * p0_nodeVar67 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar69 = ( step( 11.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar66 * 0.7 ) ) ) );
	p0_nodeVar70 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 207.26 ), ( p0_nodeVar7.y + 76.82 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar71 = pow( 0.40625, 0.82 );
	p0_nodeVar72 = ( p0_nodeVar10 * ( ( p0_nodeVar71 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 139.54 ), ( p0_nodeVar7.x + 99.94 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar73 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar70 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar70 ) * 0.65 ) ) ) * p0_nodeVar72 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar70 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar70 ) * 0.65 ) ) ) * p0_nodeVar72 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar74 = ( step( 12.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar71 * 0.7 ) ) ) );
	p0_nodeVar75 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 224.39 ), ( p0_nodeVar7.y + 82.53 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar76 = pow( 0.4375, 0.82 );
	p0_nodeVar77 = ( p0_nodeVar10 * ( ( p0_nodeVar76 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 150.91 ), ( p0_nodeVar7.x + 107.11 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar78 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar75 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar75 ) * 0.65 ) ) ) * p0_nodeVar77 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar75 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar75 ) * 0.65 ) ) ) * p0_nodeVar77 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar79 = ( step( 13.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar76 * 0.7 ) ) ) );
	p0_nodeVar80 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 241.51999999999998 ), ( p0_nodeVar7.y + 88.24 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar81 = pow( 0.46875, 0.82 );
	p0_nodeVar82 = ( p0_nodeVar10 * ( ( p0_nodeVar81 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 162.27999999999997 ), ( p0_nodeVar7.x + 114.28 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar83 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar80 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar80 ) * 0.65 ) ) ) * p0_nodeVar82 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar80 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar80 ) * 0.65 ) ) ) * p0_nodeVar82 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar84 = ( step( 14.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar81 * 0.7 ) ) ) );
	p0_nodeVar85 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 258.65 ), ( p0_nodeVar7.y + 93.95 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar86 = pow( 0.5, 0.82 );
	p0_nodeVar87 = ( p0_nodeVar10 * ( ( p0_nodeVar86 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 173.64999999999998 ), ( p0_nodeVar7.x + 121.45 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar88 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar85 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar85 ) * 0.65 ) ) ) * p0_nodeVar87 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar85 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar85 ) * 0.65 ) ) ) * p0_nodeVar87 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar89 = ( step( 15.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar86 * 0.7 ) ) ) );
	p0_nodeVar90 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 275.78 ), ( p0_nodeVar7.y + 99.66 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar91 = pow( 0.53125, 0.82 );
	p0_nodeVar92 = ( p0_nodeVar10 * ( ( p0_nodeVar91 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 185.01999999999998 ), ( p0_nodeVar7.x + 128.62 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar93 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar90 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar90 ) * 0.65 ) ) ) * p0_nodeVar92 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar90 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar90 ) * 0.65 ) ) ) * p0_nodeVar92 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar94 = ( step( 16.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar91 * 0.7 ) ) ) );
	p0_nodeVar95 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 292.90999999999997 ), ( p0_nodeVar7.y + 105.36999999999999 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar96 = pow( 0.5625, 0.82 );
	p0_nodeVar97 = ( p0_nodeVar10 * ( ( p0_nodeVar96 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 196.39 ), ( p0_nodeVar7.x + 135.79 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar98 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar95 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar95 ) * 0.65 ) ) ) * p0_nodeVar97 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar95 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar95 ) * 0.65 ) ) ) * p0_nodeVar97 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar99 = ( step( 17.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar96 * 0.7 ) ) ) );
	p0_nodeVar100 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 310.03999999999996 ), ( p0_nodeVar7.y + 111.08 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar101 = pow( 0.59375, 0.82 );
	p0_nodeVar102 = ( p0_nodeVar10 * ( ( p0_nodeVar101 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 207.76 ), ( p0_nodeVar7.x + 142.96 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar103 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar100 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar100 ) * 0.65 ) ) ) * p0_nodeVar102 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar100 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar100 ) * 0.65 ) ) ) * p0_nodeVar102 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar104 = ( step( 18.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar101 * 0.7 ) ) ) );
	p0_nodeVar105 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 327.16999999999996 ), ( p0_nodeVar7.y + 116.78999999999999 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar106 = pow( 0.625, 0.82 );
	p0_nodeVar107 = ( p0_nodeVar10 * ( ( p0_nodeVar106 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 219.12999999999997 ), ( p0_nodeVar7.x + 150.13 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar108 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar105 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar105 ) * 0.65 ) ) ) * p0_nodeVar107 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar105 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar105 ) * 0.65 ) ) ) * p0_nodeVar107 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar109 = ( step( 19.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar106 * 0.7 ) ) ) );
	p0_nodeVar110 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 344.29999999999995 ), ( p0_nodeVar7.y + 122.5 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar111 = pow( 0.65625, 0.82 );
	p0_nodeVar112 = ( p0_nodeVar10 * ( ( p0_nodeVar111 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 230.49999999999997 ), ( p0_nodeVar7.x + 157.3 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar113 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar110 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar110 ) * 0.65 ) ) ) * p0_nodeVar112 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar110 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar110 ) * 0.65 ) ) ) * p0_nodeVar112 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar114 = ( step( 20.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar111 * 0.7 ) ) ) );
	p0_nodeVar115 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 361.42999999999995 ), ( p0_nodeVar7.y + 128.21 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar116 = pow( 0.6875, 0.82 );
	p0_nodeVar117 = ( p0_nodeVar10 * ( ( p0_nodeVar116 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 241.86999999999998 ), ( p0_nodeVar7.x + 164.47 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar118 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar115 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar115 ) * 0.65 ) ) ) * p0_nodeVar117 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar115 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar115 ) * 0.65 ) ) ) * p0_nodeVar117 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar119 = ( step( 21.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar116 * 0.7 ) ) ) );
	p0_nodeVar120 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 378.55999999999995 ), ( p0_nodeVar7.y + 133.92000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar121 = pow( 0.71875, 0.82 );
	p0_nodeVar122 = ( p0_nodeVar10 * ( ( p0_nodeVar121 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 253.23999999999998 ), ( p0_nodeVar7.x + 171.64000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar123 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar120 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar120 ) * 0.65 ) ) ) * p0_nodeVar122 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar120 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar120 ) * 0.65 ) ) ) * p0_nodeVar122 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar124 = ( step( 22.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar121 * 0.7 ) ) ) );
	p0_nodeVar125 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 395.68999999999994 ), ( p0_nodeVar7.y + 139.63000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar126 = pow( 0.75, 0.82 );
	p0_nodeVar127 = ( p0_nodeVar10 * ( ( p0_nodeVar126 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 264.61 ), ( p0_nodeVar7.x + 178.81 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar128 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar125 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar125 ) * 0.65 ) ) ) * p0_nodeVar127 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar125 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar125 ) * 0.65 ) ) ) * p0_nodeVar127 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar129 = ( step( 23.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar126 * 0.7 ) ) ) );
	p0_nodeVar130 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 412.82 ), ( p0_nodeVar7.y + 145.34 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar131 = pow( 0.78125, 0.82 );
	p0_nodeVar132 = ( p0_nodeVar10 * ( ( p0_nodeVar131 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 275.98 ), ( p0_nodeVar7.x + 185.98 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar133 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar130 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar130 ) * 0.65 ) ) ) * p0_nodeVar132 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar130 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar130 ) * 0.65 ) ) ) * p0_nodeVar132 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar134 = ( step( 24.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar131 * 0.7 ) ) ) );
	p0_nodeVar135 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 429.95 ), ( p0_nodeVar7.y + 151.05 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar136 = pow( 0.8125, 0.82 );
	p0_nodeVar137 = ( p0_nodeVar10 * ( ( p0_nodeVar136 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 287.35 ), ( p0_nodeVar7.x + 193.15 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar138 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar135 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar135 ) * 0.65 ) ) ) * p0_nodeVar137 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar135 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar135 ) * 0.65 ) ) ) * p0_nodeVar137 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar139 = ( step( 25.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar136 * 0.7 ) ) ) );
	p0_nodeVar140 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 447.08 ), ( p0_nodeVar7.y + 156.76000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar141 = pow( 0.84375, 0.82 );
	p0_nodeVar142 = ( p0_nodeVar10 * ( ( p0_nodeVar141 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 298.72 ), ( p0_nodeVar7.x + 200.32 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar143 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar140 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar140 ) * 0.65 ) ) ) * p0_nodeVar142 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar140 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar140 ) * 0.65 ) ) ) * p0_nodeVar142 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar144 = ( step( 26.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar141 * 0.7 ) ) ) );
	p0_nodeVar145 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 464.21 ), ( p0_nodeVar7.y + 162.47 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar146 = pow( 0.875, 0.82 );
	p0_nodeVar147 = ( p0_nodeVar10 * ( ( p0_nodeVar146 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 310.09 ), ( p0_nodeVar7.x + 207.49 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar148 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar145 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar145 ) * 0.65 ) ) ) * p0_nodeVar147 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar145 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar145 ) * 0.65 ) ) ) * p0_nodeVar147 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar149 = ( step( 27.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar146 * 0.7 ) ) ) );
	p0_nodeVar150 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 481.34 ), ( p0_nodeVar7.y + 168.18 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar151 = pow( 0.90625, 0.82 );
	p0_nodeVar152 = ( p0_nodeVar10 * ( ( p0_nodeVar151 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 321.46 ), ( p0_nodeVar7.x + 214.66 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar153 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar150 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar150 ) * 0.65 ) ) ) * p0_nodeVar152 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar150 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar150 ) * 0.65 ) ) ) * p0_nodeVar152 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar154 = ( step( 28.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar151 * 0.7 ) ) ) );
	p0_nodeVar155 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 498.46999999999997 ), ( p0_nodeVar7.y + 173.89000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar156 = pow( 0.9375, 0.82 );
	p0_nodeVar157 = ( p0_nodeVar10 * ( ( p0_nodeVar156 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 332.83 ), ( p0_nodeVar7.x + 221.83 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar158 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar155 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar155 ) * 0.65 ) ) ) * p0_nodeVar157 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar155 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar155 ) * 0.65 ) ) ) * p0_nodeVar157 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar159 = ( step( 29.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar156 * 0.7 ) ) ) );
	p0_nodeVar160 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 515.6 ), ( p0_nodeVar7.y + 179.60000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar161 = pow( 0.96875, 0.82 );
	p0_nodeVar162 = ( p0_nodeVar10 * ( ( p0_nodeVar161 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 344.2 ), ( p0_nodeVar7.x + 229.0 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar163 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar160 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar160 ) * 0.65 ) ) ) * p0_nodeVar162 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar160 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar160 ) * 0.65 ) ) ) * p0_nodeVar162 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar164 = ( step( 30.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar161 * 0.7 ) ) ) );
	p0_nodeVar165 = ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.x + 532.73 ), ( p0_nodeVar7.y + 185.31 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	p0_nodeVar166 = pow( 1.0, 0.82 );
	p0_nodeVar167 = ( p0_nodeVar10 * ( ( p0_nodeVar166 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( p0_nodeVar7.y + 355.57 ), ( p0_nodeVar7.x + 236.17000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	p0_nodeVar168 = picture_read( vec2<f32>( clamp( ( p0_nodeVar1.x + ( ( ( ( p0_nodeVar6.x * cos( p0_nodeVar165 ) ) + ( p0_nodeVar9.x * ( sin( p0_nodeVar165 ) * 0.65 ) ) ) * p0_nodeVar167 ) / f32(knobs.resolution.x) ) ), 0.0, 1.0 ), clamp( ( p0_nodeVar1.y + ( ( ( ( p0_nodeVar6.y * cos( p0_nodeVar165 ) ) + ( p0_nodeVar9.y * ( sin( p0_nodeVar165 ) * 0.65 ) ) ) * p0_nodeVar167 ) / f32(knobs.resolution.y) ) ), 0.0, 1.0 ) ) );
	p0_nodeVar169 = ( step( 31.5, f32(knobs.samples) ) * max( 0.35, ( 1.1 - ( p0_nodeVar166 * 0.7 ) ) ) );
	p0_nodeVar170 = max( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 1.0 + p0_nodeVar14 ) + p0_nodeVar19 ) + p0_nodeVar24 ) + p0_nodeVar29 ) + p0_nodeVar34 ) + p0_nodeVar39 ) + p0_nodeVar44 ) + p0_nodeVar49 ) + p0_nodeVar54 ) + p0_nodeVar59 ) + p0_nodeVar64 ) + p0_nodeVar69 ) + p0_nodeVar74 ) + p0_nodeVar79 ) + p0_nodeVar84 ) + p0_nodeVar89 ) + p0_nodeVar94 ) + p0_nodeVar99 ) + p0_nodeVar104 ) + p0_nodeVar109 ) + p0_nodeVar114 ) + p0_nodeVar119 ) + p0_nodeVar124 ) + p0_nodeVar129 ) + p0_nodeVar134 ) + p0_nodeVar139 ) + p0_nodeVar144 ) + p0_nodeVar149 ) + p0_nodeVar154 ) + p0_nodeVar159 ) + p0_nodeVar164 ) + p0_nodeVar169 ), 1.0 );
	p0_nodeVar171 = vec4<f32>( vec3<f32>( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( p0_nodeVar2.x + ( p0_nodeVar13.x * p0_nodeVar14 ) ) + ( p0_nodeVar18.x * p0_nodeVar19 ) ) + ( p0_nodeVar23.x * p0_nodeVar24 ) ) + ( p0_nodeVar28.x * p0_nodeVar29 ) ) + ( p0_nodeVar33.x * p0_nodeVar34 ) ) + ( p0_nodeVar38.x * p0_nodeVar39 ) ) + ( p0_nodeVar43.x * p0_nodeVar44 ) ) + ( p0_nodeVar48.x * p0_nodeVar49 ) ) + ( p0_nodeVar53.x * p0_nodeVar54 ) ) + ( p0_nodeVar58.x * p0_nodeVar59 ) ) + ( p0_nodeVar63.x * p0_nodeVar64 ) ) + ( p0_nodeVar68.x * p0_nodeVar69 ) ) + ( p0_nodeVar73.x * p0_nodeVar74 ) ) + ( p0_nodeVar78.x * p0_nodeVar79 ) ) + ( p0_nodeVar83.x * p0_nodeVar84 ) ) + ( p0_nodeVar88.x * p0_nodeVar89 ) ) + ( p0_nodeVar93.x * p0_nodeVar94 ) ) + ( p0_nodeVar98.x * p0_nodeVar99 ) ) + ( p0_nodeVar103.x * p0_nodeVar104 ) ) + ( p0_nodeVar108.x * p0_nodeVar109 ) ) + ( p0_nodeVar113.x * p0_nodeVar114 ) ) + ( p0_nodeVar118.x * p0_nodeVar119 ) ) + ( p0_nodeVar123.x * p0_nodeVar124 ) ) + ( p0_nodeVar128.x * p0_nodeVar129 ) ) + ( p0_nodeVar133.x * p0_nodeVar134 ) ) + ( p0_nodeVar138.x * p0_nodeVar139 ) ) + ( p0_nodeVar143.x * p0_nodeVar144 ) ) + ( p0_nodeVar148.x * p0_nodeVar149 ) ) + ( p0_nodeVar153.x * p0_nodeVar154 ) ) + ( p0_nodeVar158.x * p0_nodeVar159 ) ) + ( p0_nodeVar163.x * p0_nodeVar164 ) ) + ( p0_nodeVar168.x * p0_nodeVar169 ) ) / p0_nodeVar170 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( p0_nodeVar2.y + ( p0_nodeVar13.y * p0_nodeVar14 ) ) + ( p0_nodeVar18.y * p0_nodeVar19 ) ) + ( p0_nodeVar23.y * p0_nodeVar24 ) ) + ( p0_nodeVar28.y * p0_nodeVar29 ) ) + ( p0_nodeVar33.y * p0_nodeVar34 ) ) + ( p0_nodeVar38.y * p0_nodeVar39 ) ) + ( p0_nodeVar43.y * p0_nodeVar44 ) ) + ( p0_nodeVar48.y * p0_nodeVar49 ) ) + ( p0_nodeVar53.y * p0_nodeVar54 ) ) + ( p0_nodeVar58.y * p0_nodeVar59 ) ) + ( p0_nodeVar63.y * p0_nodeVar64 ) ) + ( p0_nodeVar68.y * p0_nodeVar69 ) ) + ( p0_nodeVar73.y * p0_nodeVar74 ) ) + ( p0_nodeVar78.y * p0_nodeVar79 ) ) + ( p0_nodeVar83.y * p0_nodeVar84 ) ) + ( p0_nodeVar88.y * p0_nodeVar89 ) ) + ( p0_nodeVar93.y * p0_nodeVar94 ) ) + ( p0_nodeVar98.y * p0_nodeVar99 ) ) + ( p0_nodeVar103.y * p0_nodeVar104 ) ) + ( p0_nodeVar108.y * p0_nodeVar109 ) ) + ( p0_nodeVar113.y * p0_nodeVar114 ) ) + ( p0_nodeVar118.y * p0_nodeVar119 ) ) + ( p0_nodeVar123.y * p0_nodeVar124 ) ) + ( p0_nodeVar128.y * p0_nodeVar129 ) ) + ( p0_nodeVar133.y * p0_nodeVar134 ) ) + ( p0_nodeVar138.y * p0_nodeVar139 ) ) + ( p0_nodeVar143.y * p0_nodeVar144 ) ) + ( p0_nodeVar148.y * p0_nodeVar149 ) ) + ( p0_nodeVar153.y * p0_nodeVar154 ) ) + ( p0_nodeVar158.y * p0_nodeVar159 ) ) + ( p0_nodeVar163.y * p0_nodeVar164 ) ) + ( p0_nodeVar168.y * p0_nodeVar169 ) ) / p0_nodeVar170 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( p0_nodeVar2.z + ( p0_nodeVar13.z * p0_nodeVar14 ) ) + ( p0_nodeVar18.z * p0_nodeVar19 ) ) + ( p0_nodeVar23.z * p0_nodeVar24 ) ) + ( p0_nodeVar28.z * p0_nodeVar29 ) ) + ( p0_nodeVar33.z * p0_nodeVar34 ) ) + ( p0_nodeVar38.z * p0_nodeVar39 ) ) + ( p0_nodeVar43.z * p0_nodeVar44 ) ) + ( p0_nodeVar48.z * p0_nodeVar49 ) ) + ( p0_nodeVar53.z * p0_nodeVar54 ) ) + ( p0_nodeVar58.z * p0_nodeVar59 ) ) + ( p0_nodeVar63.z * p0_nodeVar64 ) ) + ( p0_nodeVar68.z * p0_nodeVar69 ) ) + ( p0_nodeVar73.z * p0_nodeVar74 ) ) + ( p0_nodeVar78.z * p0_nodeVar79 ) ) + ( p0_nodeVar83.z * p0_nodeVar84 ) ) + ( p0_nodeVar88.z * p0_nodeVar89 ) ) + ( p0_nodeVar93.z * p0_nodeVar94 ) ) + ( p0_nodeVar98.z * p0_nodeVar99 ) ) + ( p0_nodeVar103.z * p0_nodeVar104 ) ) + ( p0_nodeVar108.z * p0_nodeVar109 ) ) + ( p0_nodeVar113.z * p0_nodeVar114 ) ) + ( p0_nodeVar118.z * p0_nodeVar119 ) ) + ( p0_nodeVar123.z * p0_nodeVar124 ) ) + ( p0_nodeVar128.z * p0_nodeVar129 ) ) + ( p0_nodeVar133.z * p0_nodeVar134 ) ) + ( p0_nodeVar138.z * p0_nodeVar139 ) ) + ( p0_nodeVar143.z * p0_nodeVar144 ) ) + ( p0_nodeVar148.z * p0_nodeVar149 ) ) + ( p0_nodeVar153.z * p0_nodeVar154 ) ) + ( p0_nodeVar158.z * p0_nodeVar159 ) ) + ( p0_nodeVar163.z * p0_nodeVar164 ) ) + ( p0_nodeVar168.z * p0_nodeVar169 ) ) / p0_nodeVar170 ) ), 1.0 );
	p0_nodeVar172 = vec3<f32>( p0_nodeVar171.x, p0_nodeVar171.y, p0_nodeVar171.z );
	p0_nodeVar173 = ( ( ( p0_nodeVar172.x * 0.2126 ) + ( p0_nodeVar172.y * 0.7152 ) ) + ( p0_nodeVar172.z * 0.0722 ) );
	p0_nodeVar174 = mix( vec3<f32>( p0_nodeVar173, p0_nodeVar173, p0_nodeVar173 ), p0_nodeVar172, f32(1.0) );
	p0_nodeVar175 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar174.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar174.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar174.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar174.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar174.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar174.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar174.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar174.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar174.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar171.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar175.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar175.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar176 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar176;

	// result

	p0_output.color = p0_nodeVar176;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

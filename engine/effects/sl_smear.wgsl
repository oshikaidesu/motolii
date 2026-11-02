// Progressive Blur: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Blur that ramps from sharp to soft across the frame.
// --track@angle:Angle,0,360,0,1
// --track@start:Start,0,1,0.25,0.01
// --track@end:End,0,1,0.75,0.01
// --track@strength:Strength,0,64,24,1
// --track@samples:Samples,4,32,12,1
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
  angle: f32,
  resolution: vec2<f32>,
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
var<private> nodeVar1 : vec2<f32>;
var<private> nodeVar2 : vec4<f32>;
var<private> nodeVar3 : f32;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : vec2<f32>;
var<private> nodeVar7 : vec2<f32>;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : vec2<f32>;
var<private> nodeVar10 : f32;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : vec4<f32>;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : vec4<f32>;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : f32;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : vec4<f32>;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : vec4<f32>;
var<private> nodeVar29 : f32;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : f32;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : vec4<f32>;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : f32;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : vec4<f32>;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : f32;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : f32;
var<private> nodeVar43 : vec4<f32>;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : f32;
var<private> nodeVar47 : f32;
var<private> nodeVar48 : vec4<f32>;
var<private> nodeVar49 : f32;
var<private> nodeVar50 : f32;
var<private> nodeVar51 : f32;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : vec4<f32>;
var<private> nodeVar54 : f32;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : f32;
var<private> nodeVar58 : vec4<f32>;
var<private> nodeVar59 : f32;
var<private> nodeVar60 : f32;
var<private> nodeVar61 : f32;
var<private> nodeVar62 : f32;
var<private> nodeVar63 : vec4<f32>;
var<private> nodeVar64 : f32;
var<private> nodeVar65 : f32;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : vec4<f32>;
var<private> nodeVar69 : f32;
var<private> nodeVar70 : f32;
var<private> nodeVar71 : f32;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : vec4<f32>;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : f32;
var<private> nodeVar78 : vec4<f32>;
var<private> nodeVar79 : f32;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : f32;
var<private> nodeVar82 : f32;
var<private> nodeVar83 : vec4<f32>;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : f32;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : vec4<f32>;
var<private> nodeVar89 : f32;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : f32;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : vec4<f32>;
var<private> nodeVar94 : f32;
var<private> nodeVar95 : f32;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : f32;
var<private> nodeVar98 : vec4<f32>;
var<private> nodeVar99 : f32;
var<private> nodeVar100 : f32;
var<private> nodeVar101 : f32;
var<private> nodeVar102 : f32;
var<private> nodeVar103 : vec4<f32>;
var<private> nodeVar104 : f32;
var<private> nodeVar105 : f32;
var<private> nodeVar106 : f32;
var<private> nodeVar107 : f32;
var<private> nodeVar108 : vec4<f32>;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : f32;
var<private> nodeVar111 : f32;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : vec4<f32>;
var<private> nodeVar114 : f32;
var<private> nodeVar115 : f32;
var<private> nodeVar116 : f32;
var<private> nodeVar117 : f32;
var<private> nodeVar118 : vec4<f32>;
var<private> nodeVar119 : f32;
var<private> nodeVar120 : f32;
var<private> nodeVar121 : f32;
var<private> nodeVar122 : f32;
var<private> nodeVar123 : vec4<f32>;
var<private> nodeVar124 : f32;
var<private> nodeVar125 : f32;
var<private> nodeVar126 : f32;
var<private> nodeVar127 : f32;
var<private> nodeVar128 : vec4<f32>;
var<private> nodeVar129 : f32;
var<private> nodeVar130 : f32;
var<private> nodeVar131 : f32;
var<private> nodeVar132 : f32;
var<private> nodeVar133 : vec4<f32>;
var<private> nodeVar134 : f32;
var<private> nodeVar135 : f32;
var<private> nodeVar136 : f32;
var<private> nodeVar137 : f32;
var<private> nodeVar138 : vec4<f32>;
var<private> nodeVar139 : f32;
var<private> nodeVar140 : f32;
var<private> nodeVar141 : f32;
var<private> nodeVar142 : f32;
var<private> nodeVar143 : vec4<f32>;
var<private> nodeVar144 : f32;
var<private> nodeVar145 : f32;
var<private> nodeVar146 : f32;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : vec4<f32>;
var<private> nodeVar149 : f32;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : vec4<f32>;
var<private> nodeVar154 : f32;
var<private> nodeVar155 : f32;
var<private> nodeVar156 : f32;
var<private> nodeVar157 : f32;
var<private> nodeVar158 : vec4<f32>;
var<private> nodeVar159 : f32;
var<private> nodeVar160 : f32;
var<private> nodeVar161 : f32;
var<private> nodeVar162 : f32;
var<private> nodeVar163 : vec4<f32>;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : f32;
var<private> nodeVar166 : f32;
var<private> nodeVar167 : f32;
var<private> nodeVar168 : vec4<f32>;
var<private> nodeVar169 : f32;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : vec4<f32>;
var<private> nodeVar172 : vec3<f32>;
var<private> nodeVar173 : f32;
var<private> nodeVar174 : vec3<f32>;
var<private> nodeVar175 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar176 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = picture_read( nodeVar1 );
	nodeVar3 = ( knobs.angle * 0.017453292519943295 );
	nodeVar4 = cos( nodeVar3 );
	nodeVar5 = sin( nodeVar3 );
	nodeVar6 = vec2<f32>( nodeVar4, nodeVar5 );
	nodeVar7 = vec2<f32>( ( nodeVar1.x * knobs.resolution.x ), ( nodeVar1.y * knobs.resolution.y ) );
	nodeVar8 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 1.7 ), ( nodeVar7.y + 8.3 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar9 = vec2<f32>( ( - nodeVar5 ), nodeVar4 );
	nodeVar10 = ( smoothstep( min( knobs.start, knobs.end ), max( knobs.start, knobs.end ), ( ( nodeVar1.x * nodeVar4 ) + ( nodeVar1.y * nodeVar5 ) ) ) * knobs.strength );
	nodeVar11 = pow( 0.03125, 0.82 );
	nodeVar12 = ( nodeVar10 * ( ( nodeVar11 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 3.1 ), ( nodeVar7.x + 13.9 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar13 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar8 ) ) + ( nodeVar9.x * ( sin( nodeVar8 ) * 0.65 ) ) ) * nodeVar12 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar8 ) ) + ( nodeVar9.y * ( sin( nodeVar8 ) * 0.65 ) ) ) * nodeVar12 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar14 = ( step( 0.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar11 * 0.7 ) ) ) );
	nodeVar15 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 18.83 ), ( nodeVar7.y + 14.010000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar16 = pow( 0.0625, 0.82 );
	nodeVar17 = ( nodeVar10 * ( ( nodeVar16 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 14.469999999999999 ), ( nodeVar7.x + 21.07 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar18 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar15 ) ) + ( nodeVar9.x * ( sin( nodeVar15 ) * 0.65 ) ) ) * nodeVar17 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar15 ) ) + ( nodeVar9.y * ( sin( nodeVar15 ) * 0.65 ) ) ) * nodeVar17 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar19 = ( step( 1.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar16 * 0.7 ) ) ) );
	nodeVar20 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 35.96 ), ( nodeVar7.y + 19.72 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar21 = pow( 0.09375, 0.82 );
	nodeVar22 = ( nodeVar10 * ( ( nodeVar21 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 25.84 ), ( nodeVar7.x + 28.240000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar23 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar20 ) ) + ( nodeVar9.x * ( sin( nodeVar20 ) * 0.65 ) ) ) * nodeVar22 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar20 ) ) + ( nodeVar9.y * ( sin( nodeVar20 ) * 0.65 ) ) ) * nodeVar22 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar24 = ( step( 2.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar21 * 0.7 ) ) ) );
	nodeVar25 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 53.09 ), ( nodeVar7.y + 25.43 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar26 = pow( 0.125, 0.82 );
	nodeVar27 = ( nodeVar10 * ( ( nodeVar26 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 37.21 ), ( nodeVar7.x + 35.41 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar28 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar25 ) ) + ( nodeVar9.x * ( sin( nodeVar25 ) * 0.65 ) ) ) * nodeVar27 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar25 ) ) + ( nodeVar9.y * ( sin( nodeVar25 ) * 0.65 ) ) ) * nodeVar27 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar29 = ( step( 3.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar26 * 0.7 ) ) ) );
	nodeVar30 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 70.22 ), ( nodeVar7.y + 31.14 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar31 = pow( 0.15625, 0.82 );
	nodeVar32 = ( nodeVar10 * ( ( nodeVar31 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 48.58 ), ( nodeVar7.x + 42.58 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar33 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar30 ) ) + ( nodeVar9.x * ( sin( nodeVar30 ) * 0.65 ) ) ) * nodeVar32 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar30 ) ) + ( nodeVar9.y * ( sin( nodeVar30 ) * 0.65 ) ) ) * nodeVar32 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar34 = ( step( 4.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar31 * 0.7 ) ) ) );
	nodeVar35 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 87.35 ), ( nodeVar7.y + 36.85 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar36 = pow( 0.1875, 0.82 );
	nodeVar37 = ( nodeVar10 * ( ( nodeVar36 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 59.949999999999996 ), ( nodeVar7.x + 49.75 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar38 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar35 ) ) + ( nodeVar9.x * ( sin( nodeVar35 ) * 0.65 ) ) ) * nodeVar37 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar35 ) ) + ( nodeVar9.y * ( sin( nodeVar35 ) * 0.65 ) ) ) * nodeVar37 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar39 = ( step( 5.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar36 * 0.7 ) ) ) );
	nodeVar40 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 104.48 ), ( nodeVar7.y + 42.56 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar41 = pow( 0.21875, 0.82 );
	nodeVar42 = ( nodeVar10 * ( ( nodeVar41 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 71.32 ), ( nodeVar7.x + 56.919999999999995 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar43 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar40 ) ) + ( nodeVar9.x * ( sin( nodeVar40 ) * 0.65 ) ) ) * nodeVar42 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar40 ) ) + ( nodeVar9.y * ( sin( nodeVar40 ) * 0.65 ) ) ) * nodeVar42 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar44 = ( step( 6.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar41 * 0.7 ) ) ) );
	nodeVar45 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 121.61 ), ( nodeVar7.y + 48.269999999999996 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar46 = pow( 0.25, 0.82 );
	nodeVar47 = ( nodeVar10 * ( ( nodeVar46 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 82.68999999999998 ), ( nodeVar7.x + 64.09 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar48 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar45 ) ) + ( nodeVar9.x * ( sin( nodeVar45 ) * 0.65 ) ) ) * nodeVar47 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar45 ) ) + ( nodeVar9.y * ( sin( nodeVar45 ) * 0.65 ) ) ) * nodeVar47 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar49 = ( step( 7.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar46 * 0.7 ) ) ) );
	nodeVar50 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 138.73999999999998 ), ( nodeVar7.y + 53.980000000000004 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar51 = pow( 0.28125, 0.82 );
	nodeVar52 = ( nodeVar10 * ( ( nodeVar51 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 94.05999999999999 ), ( nodeVar7.x + 71.26 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar53 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar50 ) ) + ( nodeVar9.x * ( sin( nodeVar50 ) * 0.65 ) ) ) * nodeVar52 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar50 ) ) + ( nodeVar9.y * ( sin( nodeVar50 ) * 0.65 ) ) ) * nodeVar52 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar54 = ( step( 8.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar51 * 0.7 ) ) ) );
	nodeVar55 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 155.86999999999998 ), ( nodeVar7.y + 59.69 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar56 = pow( 0.3125, 0.82 );
	nodeVar57 = ( nodeVar10 * ( ( nodeVar56 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 105.42999999999999 ), ( nodeVar7.x + 78.43 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar58 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar55 ) ) + ( nodeVar9.x * ( sin( nodeVar55 ) * 0.65 ) ) ) * nodeVar57 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar55 ) ) + ( nodeVar9.y * ( sin( nodeVar55 ) * 0.65 ) ) ) * nodeVar57 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar59 = ( step( 9.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar56 * 0.7 ) ) ) );
	nodeVar60 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 172.99999999999997 ), ( nodeVar7.y + 65.4 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar61 = pow( 0.34375, 0.82 );
	nodeVar62 = ( nodeVar10 * ( ( nodeVar61 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 116.79999999999998 ), ( nodeVar7.x + 85.60000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar63 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar60 ) ) + ( nodeVar9.x * ( sin( nodeVar60 ) * 0.65 ) ) ) * nodeVar62 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar60 ) ) + ( nodeVar9.y * ( sin( nodeVar60 ) * 0.65 ) ) ) * nodeVar62 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar64 = ( step( 10.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar61 * 0.7 ) ) ) );
	nodeVar65 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 190.12999999999997 ), ( nodeVar7.y + 71.11 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar66 = pow( 0.375, 0.82 );
	nodeVar67 = ( nodeVar10 * ( ( nodeVar66 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 128.17 ), ( nodeVar7.x + 92.77000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar68 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar65 ) ) + ( nodeVar9.x * ( sin( nodeVar65 ) * 0.65 ) ) ) * nodeVar67 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar65 ) ) + ( nodeVar9.y * ( sin( nodeVar65 ) * 0.65 ) ) ) * nodeVar67 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar69 = ( step( 11.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar66 * 0.7 ) ) ) );
	nodeVar70 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 207.26 ), ( nodeVar7.y + 76.82 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar71 = pow( 0.40625, 0.82 );
	nodeVar72 = ( nodeVar10 * ( ( nodeVar71 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 139.54 ), ( nodeVar7.x + 99.94 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar73 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar70 ) ) + ( nodeVar9.x * ( sin( nodeVar70 ) * 0.65 ) ) ) * nodeVar72 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar70 ) ) + ( nodeVar9.y * ( sin( nodeVar70 ) * 0.65 ) ) ) * nodeVar72 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar74 = ( step( 12.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar71 * 0.7 ) ) ) );
	nodeVar75 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 224.39 ), ( nodeVar7.y + 82.53 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar76 = pow( 0.4375, 0.82 );
	nodeVar77 = ( nodeVar10 * ( ( nodeVar76 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 150.91 ), ( nodeVar7.x + 107.11 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar78 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar75 ) ) + ( nodeVar9.x * ( sin( nodeVar75 ) * 0.65 ) ) ) * nodeVar77 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar75 ) ) + ( nodeVar9.y * ( sin( nodeVar75 ) * 0.65 ) ) ) * nodeVar77 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar79 = ( step( 13.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar76 * 0.7 ) ) ) );
	nodeVar80 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 241.51999999999998 ), ( nodeVar7.y + 88.24 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar81 = pow( 0.46875, 0.82 );
	nodeVar82 = ( nodeVar10 * ( ( nodeVar81 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 162.27999999999997 ), ( nodeVar7.x + 114.28 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar83 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar80 ) ) + ( nodeVar9.x * ( sin( nodeVar80 ) * 0.65 ) ) ) * nodeVar82 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar80 ) ) + ( nodeVar9.y * ( sin( nodeVar80 ) * 0.65 ) ) ) * nodeVar82 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar84 = ( step( 14.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar81 * 0.7 ) ) ) );
	nodeVar85 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 258.65 ), ( nodeVar7.y + 93.95 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar86 = pow( 0.5, 0.82 );
	nodeVar87 = ( nodeVar10 * ( ( nodeVar86 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 173.64999999999998 ), ( nodeVar7.x + 121.45 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar88 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar85 ) ) + ( nodeVar9.x * ( sin( nodeVar85 ) * 0.65 ) ) ) * nodeVar87 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar85 ) ) + ( nodeVar9.y * ( sin( nodeVar85 ) * 0.65 ) ) ) * nodeVar87 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar89 = ( step( 15.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar86 * 0.7 ) ) ) );
	nodeVar90 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 275.78 ), ( nodeVar7.y + 99.66 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar91 = pow( 0.53125, 0.82 );
	nodeVar92 = ( nodeVar10 * ( ( nodeVar91 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 185.01999999999998 ), ( nodeVar7.x + 128.62 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar93 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar90 ) ) + ( nodeVar9.x * ( sin( nodeVar90 ) * 0.65 ) ) ) * nodeVar92 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar90 ) ) + ( nodeVar9.y * ( sin( nodeVar90 ) * 0.65 ) ) ) * nodeVar92 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar94 = ( step( 16.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar91 * 0.7 ) ) ) );
	nodeVar95 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 292.90999999999997 ), ( nodeVar7.y + 105.36999999999999 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar96 = pow( 0.5625, 0.82 );
	nodeVar97 = ( nodeVar10 * ( ( nodeVar96 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 196.39 ), ( nodeVar7.x + 135.79 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar98 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar95 ) ) + ( nodeVar9.x * ( sin( nodeVar95 ) * 0.65 ) ) ) * nodeVar97 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar95 ) ) + ( nodeVar9.y * ( sin( nodeVar95 ) * 0.65 ) ) ) * nodeVar97 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar99 = ( step( 17.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar96 * 0.7 ) ) ) );
	nodeVar100 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 310.03999999999996 ), ( nodeVar7.y + 111.08 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar101 = pow( 0.59375, 0.82 );
	nodeVar102 = ( nodeVar10 * ( ( nodeVar101 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 207.76 ), ( nodeVar7.x + 142.96 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar103 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar100 ) ) + ( nodeVar9.x * ( sin( nodeVar100 ) * 0.65 ) ) ) * nodeVar102 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar100 ) ) + ( nodeVar9.y * ( sin( nodeVar100 ) * 0.65 ) ) ) * nodeVar102 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar104 = ( step( 18.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar101 * 0.7 ) ) ) );
	nodeVar105 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 327.16999999999996 ), ( nodeVar7.y + 116.78999999999999 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar106 = pow( 0.625, 0.82 );
	nodeVar107 = ( nodeVar10 * ( ( nodeVar106 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 219.12999999999997 ), ( nodeVar7.x + 150.13 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar108 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar105 ) ) + ( nodeVar9.x * ( sin( nodeVar105 ) * 0.65 ) ) ) * nodeVar107 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar105 ) ) + ( nodeVar9.y * ( sin( nodeVar105 ) * 0.65 ) ) ) * nodeVar107 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar109 = ( step( 19.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar106 * 0.7 ) ) ) );
	nodeVar110 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 344.29999999999995 ), ( nodeVar7.y + 122.5 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar111 = pow( 0.65625, 0.82 );
	nodeVar112 = ( nodeVar10 * ( ( nodeVar111 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 230.49999999999997 ), ( nodeVar7.x + 157.3 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar113 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar110 ) ) + ( nodeVar9.x * ( sin( nodeVar110 ) * 0.65 ) ) ) * nodeVar112 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar110 ) ) + ( nodeVar9.y * ( sin( nodeVar110 ) * 0.65 ) ) ) * nodeVar112 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar114 = ( step( 20.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar111 * 0.7 ) ) ) );
	nodeVar115 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 361.42999999999995 ), ( nodeVar7.y + 128.21 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar116 = pow( 0.6875, 0.82 );
	nodeVar117 = ( nodeVar10 * ( ( nodeVar116 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 241.86999999999998 ), ( nodeVar7.x + 164.47 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar118 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar115 ) ) + ( nodeVar9.x * ( sin( nodeVar115 ) * 0.65 ) ) ) * nodeVar117 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar115 ) ) + ( nodeVar9.y * ( sin( nodeVar115 ) * 0.65 ) ) ) * nodeVar117 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar119 = ( step( 21.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar116 * 0.7 ) ) ) );
	nodeVar120 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 378.55999999999995 ), ( nodeVar7.y + 133.92000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar121 = pow( 0.71875, 0.82 );
	nodeVar122 = ( nodeVar10 * ( ( nodeVar121 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 253.23999999999998 ), ( nodeVar7.x + 171.64000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar123 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar120 ) ) + ( nodeVar9.x * ( sin( nodeVar120 ) * 0.65 ) ) ) * nodeVar122 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar120 ) ) + ( nodeVar9.y * ( sin( nodeVar120 ) * 0.65 ) ) ) * nodeVar122 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar124 = ( step( 22.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar121 * 0.7 ) ) ) );
	nodeVar125 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 395.68999999999994 ), ( nodeVar7.y + 139.63000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar126 = pow( 0.75, 0.82 );
	nodeVar127 = ( nodeVar10 * ( ( nodeVar126 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 264.61 ), ( nodeVar7.x + 178.81 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar128 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar125 ) ) + ( nodeVar9.x * ( sin( nodeVar125 ) * 0.65 ) ) ) * nodeVar127 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar125 ) ) + ( nodeVar9.y * ( sin( nodeVar125 ) * 0.65 ) ) ) * nodeVar127 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar129 = ( step( 23.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar126 * 0.7 ) ) ) );
	nodeVar130 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 412.82 ), ( nodeVar7.y + 145.34 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar131 = pow( 0.78125, 0.82 );
	nodeVar132 = ( nodeVar10 * ( ( nodeVar131 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 275.98 ), ( nodeVar7.x + 185.98 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar133 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar130 ) ) + ( nodeVar9.x * ( sin( nodeVar130 ) * 0.65 ) ) ) * nodeVar132 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar130 ) ) + ( nodeVar9.y * ( sin( nodeVar130 ) * 0.65 ) ) ) * nodeVar132 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar134 = ( step( 24.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar131 * 0.7 ) ) ) );
	nodeVar135 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 429.95 ), ( nodeVar7.y + 151.05 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar136 = pow( 0.8125, 0.82 );
	nodeVar137 = ( nodeVar10 * ( ( nodeVar136 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 287.35 ), ( nodeVar7.x + 193.15 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar138 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar135 ) ) + ( nodeVar9.x * ( sin( nodeVar135 ) * 0.65 ) ) ) * nodeVar137 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar135 ) ) + ( nodeVar9.y * ( sin( nodeVar135 ) * 0.65 ) ) ) * nodeVar137 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar139 = ( step( 25.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar136 * 0.7 ) ) ) );
	nodeVar140 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 447.08 ), ( nodeVar7.y + 156.76000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar141 = pow( 0.84375, 0.82 );
	nodeVar142 = ( nodeVar10 * ( ( nodeVar141 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 298.72 ), ( nodeVar7.x + 200.32 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar143 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar140 ) ) + ( nodeVar9.x * ( sin( nodeVar140 ) * 0.65 ) ) ) * nodeVar142 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar140 ) ) + ( nodeVar9.y * ( sin( nodeVar140 ) * 0.65 ) ) ) * nodeVar142 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar144 = ( step( 26.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar141 * 0.7 ) ) ) );
	nodeVar145 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 464.21 ), ( nodeVar7.y + 162.47 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar146 = pow( 0.875, 0.82 );
	nodeVar147 = ( nodeVar10 * ( ( nodeVar146 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 310.09 ), ( nodeVar7.x + 207.49 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar148 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar145 ) ) + ( nodeVar9.x * ( sin( nodeVar145 ) * 0.65 ) ) ) * nodeVar147 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar145 ) ) + ( nodeVar9.y * ( sin( nodeVar145 ) * 0.65 ) ) ) * nodeVar147 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar149 = ( step( 27.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar146 * 0.7 ) ) ) );
	nodeVar150 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 481.34 ), ( nodeVar7.y + 168.18 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar151 = pow( 0.90625, 0.82 );
	nodeVar152 = ( nodeVar10 * ( ( nodeVar151 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 321.46 ), ( nodeVar7.x + 214.66 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar153 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar150 ) ) + ( nodeVar9.x * ( sin( nodeVar150 ) * 0.65 ) ) ) * nodeVar152 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar150 ) ) + ( nodeVar9.y * ( sin( nodeVar150 ) * 0.65 ) ) ) * nodeVar152 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar154 = ( step( 28.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar151 * 0.7 ) ) ) );
	nodeVar155 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 498.46999999999997 ), ( nodeVar7.y + 173.89000000000001 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar156 = pow( 0.9375, 0.82 );
	nodeVar157 = ( nodeVar10 * ( ( nodeVar156 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 332.83 ), ( nodeVar7.x + 221.83 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar158 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar155 ) ) + ( nodeVar9.x * ( sin( nodeVar155 ) * 0.65 ) ) ) * nodeVar157 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar155 ) ) + ( nodeVar9.y * ( sin( nodeVar155 ) * 0.65 ) ) ) * nodeVar157 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar159 = ( step( 29.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar156 * 0.7 ) ) ) );
	nodeVar160 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 515.6 ), ( nodeVar7.y + 179.60000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar161 = pow( 0.96875, 0.82 );
	nodeVar162 = ( nodeVar10 * ( ( nodeVar161 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 344.2 ), ( nodeVar7.x + 229.0 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar163 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar160 ) ) + ( nodeVar9.x * ( sin( nodeVar160 ) * 0.65 ) ) ) * nodeVar162 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar160 ) ) + ( nodeVar9.y * ( sin( nodeVar160 ) * 0.65 ) ) ) * nodeVar162 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar164 = ( step( 30.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar161 * 0.7 ) ) ) );
	nodeVar165 = ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.x + 532.73 ), ( nodeVar7.y + 185.31 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 6.283185307179586 );
	nodeVar166 = pow( 1.0, 0.82 );
	nodeVar167 = ( nodeVar10 * ( ( nodeVar166 * 0.8 ) + ( fract( ( sin( dot( vec2<f32>( ( nodeVar7.y + 355.57 ), ( nodeVar7.x + 236.17000000000002 ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453 ) ) * 0.35 ) ) );
	nodeVar168 = picture_read( vec2<f32>( clamp( ( nodeVar1.x + ( ( ( ( nodeVar6.x * cos( nodeVar165 ) ) + ( nodeVar9.x * ( sin( nodeVar165 ) * 0.65 ) ) ) * nodeVar167 ) / knobs.resolution.x ) ), 0.0, 1.0 ), clamp( ( nodeVar1.y + ( ( ( ( nodeVar6.y * cos( nodeVar165 ) ) + ( nodeVar9.y * ( sin( nodeVar165 ) * 0.65 ) ) ) * nodeVar167 ) / knobs.resolution.y ) ), 0.0, 1.0 ) ) );
	nodeVar169 = ( step( 31.5, knobs.samples ) * max( 0.35, ( 1.1 - ( nodeVar166 * 0.7 ) ) ) );
	nodeVar170 = max( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 1.0 + nodeVar14 ) + nodeVar19 ) + nodeVar24 ) + nodeVar29 ) + nodeVar34 ) + nodeVar39 ) + nodeVar44 ) + nodeVar49 ) + nodeVar54 ) + nodeVar59 ) + nodeVar64 ) + nodeVar69 ) + nodeVar74 ) + nodeVar79 ) + nodeVar84 ) + nodeVar89 ) + nodeVar94 ) + nodeVar99 ) + nodeVar104 ) + nodeVar109 ) + nodeVar114 ) + nodeVar119 ) + nodeVar124 ) + nodeVar129 ) + nodeVar134 ) + nodeVar139 ) + nodeVar144 ) + nodeVar149 ) + nodeVar154 ) + nodeVar159 ) + nodeVar164 ) + nodeVar169 ), 1.0 );
	nodeVar171 = vec4<f32>( vec3<f32>( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( nodeVar2.x + ( nodeVar13.x * nodeVar14 ) ) + ( nodeVar18.x * nodeVar19 ) ) + ( nodeVar23.x * nodeVar24 ) ) + ( nodeVar28.x * nodeVar29 ) ) + ( nodeVar33.x * nodeVar34 ) ) + ( nodeVar38.x * nodeVar39 ) ) + ( nodeVar43.x * nodeVar44 ) ) + ( nodeVar48.x * nodeVar49 ) ) + ( nodeVar53.x * nodeVar54 ) ) + ( nodeVar58.x * nodeVar59 ) ) + ( nodeVar63.x * nodeVar64 ) ) + ( nodeVar68.x * nodeVar69 ) ) + ( nodeVar73.x * nodeVar74 ) ) + ( nodeVar78.x * nodeVar79 ) ) + ( nodeVar83.x * nodeVar84 ) ) + ( nodeVar88.x * nodeVar89 ) ) + ( nodeVar93.x * nodeVar94 ) ) + ( nodeVar98.x * nodeVar99 ) ) + ( nodeVar103.x * nodeVar104 ) ) + ( nodeVar108.x * nodeVar109 ) ) + ( nodeVar113.x * nodeVar114 ) ) + ( nodeVar118.x * nodeVar119 ) ) + ( nodeVar123.x * nodeVar124 ) ) + ( nodeVar128.x * nodeVar129 ) ) + ( nodeVar133.x * nodeVar134 ) ) + ( nodeVar138.x * nodeVar139 ) ) + ( nodeVar143.x * nodeVar144 ) ) + ( nodeVar148.x * nodeVar149 ) ) + ( nodeVar153.x * nodeVar154 ) ) + ( nodeVar158.x * nodeVar159 ) ) + ( nodeVar163.x * nodeVar164 ) ) + ( nodeVar168.x * nodeVar169 ) ) / nodeVar170 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( nodeVar2.y + ( nodeVar13.y * nodeVar14 ) ) + ( nodeVar18.y * nodeVar19 ) ) + ( nodeVar23.y * nodeVar24 ) ) + ( nodeVar28.y * nodeVar29 ) ) + ( nodeVar33.y * nodeVar34 ) ) + ( nodeVar38.y * nodeVar39 ) ) + ( nodeVar43.y * nodeVar44 ) ) + ( nodeVar48.y * nodeVar49 ) ) + ( nodeVar53.y * nodeVar54 ) ) + ( nodeVar58.y * nodeVar59 ) ) + ( nodeVar63.y * nodeVar64 ) ) + ( nodeVar68.y * nodeVar69 ) ) + ( nodeVar73.y * nodeVar74 ) ) + ( nodeVar78.y * nodeVar79 ) ) + ( nodeVar83.y * nodeVar84 ) ) + ( nodeVar88.y * nodeVar89 ) ) + ( nodeVar93.y * nodeVar94 ) ) + ( nodeVar98.y * nodeVar99 ) ) + ( nodeVar103.y * nodeVar104 ) ) + ( nodeVar108.y * nodeVar109 ) ) + ( nodeVar113.y * nodeVar114 ) ) + ( nodeVar118.y * nodeVar119 ) ) + ( nodeVar123.y * nodeVar124 ) ) + ( nodeVar128.y * nodeVar129 ) ) + ( nodeVar133.y * nodeVar134 ) ) + ( nodeVar138.y * nodeVar139 ) ) + ( nodeVar143.y * nodeVar144 ) ) + ( nodeVar148.y * nodeVar149 ) ) + ( nodeVar153.y * nodeVar154 ) ) + ( nodeVar158.y * nodeVar159 ) ) + ( nodeVar163.y * nodeVar164 ) ) + ( nodeVar168.y * nodeVar169 ) ) / nodeVar170 ), ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( nodeVar2.z + ( nodeVar13.z * nodeVar14 ) ) + ( nodeVar18.z * nodeVar19 ) ) + ( nodeVar23.z * nodeVar24 ) ) + ( nodeVar28.z * nodeVar29 ) ) + ( nodeVar33.z * nodeVar34 ) ) + ( nodeVar38.z * nodeVar39 ) ) + ( nodeVar43.z * nodeVar44 ) ) + ( nodeVar48.z * nodeVar49 ) ) + ( nodeVar53.z * nodeVar54 ) ) + ( nodeVar58.z * nodeVar59 ) ) + ( nodeVar63.z * nodeVar64 ) ) + ( nodeVar68.z * nodeVar69 ) ) + ( nodeVar73.z * nodeVar74 ) ) + ( nodeVar78.z * nodeVar79 ) ) + ( nodeVar83.z * nodeVar84 ) ) + ( nodeVar88.z * nodeVar89 ) ) + ( nodeVar93.z * nodeVar94 ) ) + ( nodeVar98.z * nodeVar99 ) ) + ( nodeVar103.z * nodeVar104 ) ) + ( nodeVar108.z * nodeVar109 ) ) + ( nodeVar113.z * nodeVar114 ) ) + ( nodeVar118.z * nodeVar119 ) ) + ( nodeVar123.z * nodeVar124 ) ) + ( nodeVar128.z * nodeVar129 ) ) + ( nodeVar133.z * nodeVar134 ) ) + ( nodeVar138.z * nodeVar139 ) ) + ( nodeVar143.z * nodeVar144 ) ) + ( nodeVar148.z * nodeVar149 ) ) + ( nodeVar153.z * nodeVar154 ) ) + ( nodeVar158.z * nodeVar159 ) ) + ( nodeVar163.z * nodeVar164 ) ) + ( nodeVar168.z * nodeVar169 ) ) / nodeVar170 ) ), 1.0 );
	nodeVar172 = vec3<f32>( nodeVar171.x, nodeVar171.y, nodeVar171.z );
	nodeVar173 = ( ( ( nodeVar172.x * 0.2126 ) + ( nodeVar172.y * 0.7152 ) ) + ( nodeVar172.z * 0.0722 ) );
	nodeVar174 = mix( vec3<f32>( nodeVar173, nodeVar173, nodeVar173 ), nodeVar172, f32(1.0) );
	nodeVar175 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar174.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar174.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar174.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar174.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar174.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar174.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar174.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar174.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar174.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar171.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar175.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar175.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar176 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar176;

	// result

	output.color = nodeVar176;

	output.color = to_shelf(output.color);
	return output;

}

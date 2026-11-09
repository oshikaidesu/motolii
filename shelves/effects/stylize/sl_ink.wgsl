// Ink: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Smeared glow and fluid bleed for neon, ink-like edges.
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t2:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t3:0,1,s1,s1
// --pass@t4:0,1,s1,s1
// --pass@t5:0,1,s0.5,s0.5
// --pass@t6:0,1,s0.25,s0.25
// --pass@t7:0,1,s0.5,s0.5
// --pass@:0,0,s1,s1
// --track@crispBlend:Detail Blend,0,1,0.81,0.01
// --track@blurStrength:Bleed Strength,0.001,0.08,0.044,0.001
// --track@blurDirection:Flow Direction,-180,180,90,1
// --track@dripLength:Drip Length,1,10,1,0.1
// --track@fluidNoise:Fluid Noise,0,2,0.02,0.01
// --track@noiseScale:Noise Scale,0.5,8,1.2,0.1
// --track@smokeSpeed:Smoke Speed,0,2,0.36,0.01
// --track@smokeTurbulence:Smoke Turbulence,0,1.5,0,0.01
// --track@blurSpread:Spread,0.5,4,1.6,0.1
// --check@colorMode:Color Mode,0
// --track@coreColor_x:Core Color r,0,1,1,0.001
// --track@coreColor_y:Core Color g,0,1,0.982250550332711,0.001
// --track@coreColor_z:Core Color b,0,1,0.8069522576650873,0.001
// --track@midColor_x:Mid Color r,0,1,1,0.001
// --track@midColor_y:Mid Color g,0,1,0.38642943377667954,0.001
// --track@midColor_z:Mid Color b,0,1,0,0.001
// --track@edgeColor_x:Edge Color r,0,1,0.16513219449147767,0.001
// --track@edgeColor_y:Edge Color g,0,1,0.2874408377161099,0.001
// --track@edgeColor_z:Edge Color b,0,1,0.8796223968851662,0.001
// --track@backgroundColor_x:Background r,0,1,0,0.001
// --track@backgroundColor_y:Background g,0,1,0,0.001
// --track@backgroundColor_z:Background b,0,1,0,0.001
// --check@grainEnabled:Enable Grain,0
// --track@grainIntensity:Grain Intensity,0,0.3,0.3,0.005
// --track@grainScale:Grain Scale,0.5,5,1.5,0.1
// --track@bloomIntensity:Intensity,0,2,2,0.01
// --track@bloomThreshold:Threshold,0,1,0.97,0.01
// --track@bloomSoftness:Softness,0,1,0.96,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  crispBlend: f32,
  blurStrength: f32,
  blurDirection: f32,
  dripLength: f32,
  fluidNoise: f32,
  noiseScale: f32,
  smokeSpeed: f32,
  smokeTurbulence: f32,
  blurSpread: f32,
  colorMode: f32,
  coreColor: vec3<f32>,
  midColor: vec3<f32>,
  edgeColor: vec3<f32>,
  backgroundColor: vec3<f32>,
  grainEnabled: f32,
  grainIntensity: f32,
  grainScale: f32,
  bloomIntensity: f32,
  bloomThreshold: f32,
  bloomSoftness: f32,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var t1: texture_2d<f32>;
@group(0) @binding(5) var t1_sampler: sampler;
@group(0) @binding(6) var t2: texture_2d<f32>;
@group(0) @binding(7) var t2_sampler: sampler;
@group(0) @binding(8) var t3: texture_2d<f32>;
@group(0) @binding(9) var t3_sampler: sampler;
@group(0) @binding(10) var t4: texture_2d<f32>;
@group(0) @binding(11) var t4_sampler: sampler;
@group(0) @binding(12) var t5: texture_2d<f32>;
@group(0) @binding(13) var t5_sampler: sampler;
@group(0) @binding(14) var t6: texture_2d<f32>;
@group(0) @binding(15) var t6_sampler: sampler;
@group(0) @binding(16) var t7: texture_2d<f32>;
@group(0) @binding(17) var t7_sampler: sampler;
@group(0) @binding(18) var<uniform> knobs: Knobs;
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
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : vec2<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : vec4<f32>;
var<private> p0_nodeVar5 : vec3<f32>;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : vec4<f32>;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec4<f32>;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : vec4<f32>;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : vec4<f32>;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : vec4<f32>;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : vec4<f32>;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : vec4<f32>;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec4<f32>;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : vec4<f32>;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar56 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p0_nodeVar2 = picture_read( ( ( ( p0_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(0.0) * 0.1 ), ( f32(0.0) * 0.1 ) ) ) + p0_nodeVar1 ) );
	p0_nodeVar3 = vec2<f32>( ( ( p0_nodeVar0.x * 0.7071054825112363 ) - ( p0_nodeVar0.y * 0.7071080798594735 ) ), ( ( p0_nodeVar0.x * 0.7071080798594735 ) + ( p0_nodeVar0.y * 0.7071054825112363 ) ) );
	p0_nodeVar4 = picture_read( ( ( ( ( p0_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(0.0) * 0.15 ), ( f32(0.0) * 0.15 ) ) ) + ( p0_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p0_nodeVar5 = mix( p0_nodeVar2.xyz, p0_nodeVar4.xyz, 0.5 );
	p0_nodeVar6 = picture_read( ( ( ( p0_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p0_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p0_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p0_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p0_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p0_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p0_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p0_nodeVar9 = ( ( ( p0_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p0_nodeVar10 = ( p0_nodeVar9 * 1.0 );
	p0_nodeVar11 = ( ( p0_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar12 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar10 + p0_nodeVar11 ), ( ( p0_nodeVar10 + p0_nodeVar11 ) * 0.3 ) ) ) );
	p0_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p0_nodeVar14 = ( p0_nodeVar9 * 1.1 );
	p0_nodeVar15 = ( ( p0_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar16 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar14 + p0_nodeVar15 ), ( ( p0_nodeVar14 + p0_nodeVar15 ) * 0.3 ) ) ) );
	p0_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p0_nodeVar18 = ( p0_nodeVar9 * 1.2 );
	p0_nodeVar19 = ( ( p0_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar20 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar18 + p0_nodeVar19 ), ( ( p0_nodeVar18 + p0_nodeVar19 ) * 0.3 ) ) ) );
	p0_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p0_nodeVar22 = ( p0_nodeVar9 * 1.3 );
	p0_nodeVar23 = ( ( p0_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar24 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar22 + p0_nodeVar23 ), ( ( p0_nodeVar22 + p0_nodeVar23 ) * 0.3 ) ) ) );
	p0_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p0_nodeVar26 = ( p0_nodeVar9 * 1.4 );
	p0_nodeVar27 = ( ( p0_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar28 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar26 + p0_nodeVar27 ), ( ( p0_nodeVar26 + p0_nodeVar27 ) * 0.3 ) ) ) );
	p0_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p0_nodeVar30 = ( p0_nodeVar9 * 1.5 );
	p0_nodeVar31 = ( ( p0_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar32 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar30 + p0_nodeVar31 ), ( ( p0_nodeVar30 + p0_nodeVar31 ) * 0.3 ) ) ) );
	p0_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p0_nodeVar34 = ( p0_nodeVar9 * 1.6 );
	p0_nodeVar35 = ( ( p0_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar36 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar34 + p0_nodeVar35 ), ( ( p0_nodeVar34 + p0_nodeVar35 ) * 0.3 ) ) ) );
	p0_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p0_nodeVar38 = ( p0_nodeVar9 * 1.7000000000000002 );
	p0_nodeVar39 = ( ( p0_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar40 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar38 + p0_nodeVar39 ), ( ( p0_nodeVar38 + p0_nodeVar39 ) * 0.3 ) ) ) );
	p0_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p0_nodeVar42 = ( p0_nodeVar9 * 1.8 );
	p0_nodeVar43 = ( ( p0_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar44 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar42 + p0_nodeVar43 ), ( ( p0_nodeVar42 + p0_nodeVar43 ) * 0.3 ) ) ) );
	p0_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p0_nodeVar46 = ( p0_nodeVar9 * 1.9 );
	p0_nodeVar47 = ( ( p0_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p0_nodeVar48 = picture_read( ( ( p0_nodeVar0 + ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(0.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p0_nodeVar46 + p0_nodeVar47 ), ( ( p0_nodeVar46 + p0_nodeVar47 ) * 0.3 ) ) ) );
	p0_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p0_nodeVar50 = picture_read( ( p0_nodeVar0 - ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p0_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p0_nodeVar52 = picture_read( ( p0_nodeVar0 - ( ( ( p0_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p0_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p0_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p0_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p0_nodeVar12 * vec4<f32>( p0_nodeVar13 ) ) ) + ( p0_nodeVar16 * vec4<f32>( p0_nodeVar17 ) ) ) + ( p0_nodeVar20 * vec4<f32>( p0_nodeVar21 ) ) ) + ( p0_nodeVar24 * vec4<f32>( p0_nodeVar25 ) ) ) + ( p0_nodeVar28 * vec4<f32>( p0_nodeVar29 ) ) ) + ( p0_nodeVar32 * vec4<f32>( p0_nodeVar33 ) ) ) + ( p0_nodeVar36 * vec4<f32>( p0_nodeVar37 ) ) ) + ( p0_nodeVar40 * vec4<f32>( p0_nodeVar41 ) ) ) + ( p0_nodeVar44 * vec4<f32>( p0_nodeVar45 ) ) ) + ( p0_nodeVar48 * vec4<f32>( p0_nodeVar49 ) ) ) + ( p0_nodeVar50 * vec4<f32>( p0_nodeVar51 ) ) ) + ( p0_nodeVar52 * vec4<f32>( p0_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p0_nodeVar13 ) + p0_nodeVar17 ) + p0_nodeVar21 ) + p0_nodeVar25 ) + p0_nodeVar29 ) + p0_nodeVar33 ) + p0_nodeVar37 ) + p0_nodeVar41 ) + p0_nodeVar45 ) + p0_nodeVar49 ) + p0_nodeVar51 ) + p0_nodeVar53 ), 0.0001 ) ) );
	p0_nodeVar55 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar54.xyz, max( p0_nodeVar54, p0_nodeVar55 ).xyz, ( max( max( p0_nodeVar55.x, p0_nodeVar55.y ), p0_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar56 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar56;

	// result

	p0_output.color = p0_nodeVar56;

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
var<private> p1_nodeVar0 : vec2<f32>;
var<private> p1_nodeVar1 : vec2<f32>;
var<private> p1_nodeVar2 : vec4<f32>;
var<private> p1_nodeVar3 : vec2<f32>;
var<private> p1_nodeVar4 : vec4<f32>;
var<private> p1_nodeVar5 : vec3<f32>;
var<private> p1_nodeVar6 : vec4<f32>;
var<private> p1_nodeVar7 : vec2<f32>;
var<private> p1_nodeVar8 : vec2<f32>;
var<private> p1_nodeVar9 : f32;
var<private> p1_nodeVar10 : f32;
var<private> p1_nodeVar11 : f32;
var<private> p1_nodeVar12 : vec4<f32>;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : f32;
var<private> p1_nodeVar15 : f32;
var<private> p1_nodeVar16 : vec4<f32>;
var<private> p1_nodeVar17 : f32;
var<private> p1_nodeVar18 : f32;
var<private> p1_nodeVar19 : f32;
var<private> p1_nodeVar20 : vec4<f32>;
var<private> p1_nodeVar21 : f32;
var<private> p1_nodeVar22 : f32;
var<private> p1_nodeVar23 : f32;
var<private> p1_nodeVar24 : vec4<f32>;
var<private> p1_nodeVar25 : f32;
var<private> p1_nodeVar26 : f32;
var<private> p1_nodeVar27 : f32;
var<private> p1_nodeVar28 : vec4<f32>;
var<private> p1_nodeVar29 : f32;
var<private> p1_nodeVar30 : f32;
var<private> p1_nodeVar31 : f32;
var<private> p1_nodeVar32 : vec4<f32>;
var<private> p1_nodeVar33 : f32;
var<private> p1_nodeVar34 : f32;
var<private> p1_nodeVar35 : f32;
var<private> p1_nodeVar36 : vec4<f32>;
var<private> p1_nodeVar37 : f32;
var<private> p1_nodeVar38 : f32;
var<private> p1_nodeVar39 : f32;
var<private> p1_nodeVar40 : vec4<f32>;
var<private> p1_nodeVar41 : f32;
var<private> p1_nodeVar42 : f32;
var<private> p1_nodeVar43 : f32;
var<private> p1_nodeVar44 : vec4<f32>;
var<private> p1_nodeVar45 : f32;
var<private> p1_nodeVar46 : f32;
var<private> p1_nodeVar47 : f32;
var<private> p1_nodeVar48 : vec4<f32>;
var<private> p1_nodeVar49 : f32;
var<private> p1_nodeVar50 : vec4<f32>;
var<private> p1_nodeVar51 : f32;
var<private> p1_nodeVar52 : vec4<f32>;
var<private> p1_nodeVar53 : f32;
var<private> p1_nodeVar54 : vec4<f32>;
var<private> p1_nodeVar55 : vec4<f32>;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar56 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p1_nodeVar2 = picture_read( ( ( ( p1_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(1.0) * 0.1 ), ( f32(1.0) * 0.1 ) ) ) + p1_nodeVar1 ) );
	p1_nodeVar3 = vec2<f32>( ( ( p1_nodeVar0.x * 0.7071054825112363 ) - ( p1_nodeVar0.y * 0.7071080798594735 ) ), ( ( p1_nodeVar0.x * 0.7071080798594735 ) + ( p1_nodeVar0.y * 0.7071054825112363 ) ) );
	p1_nodeVar4 = picture_read( ( ( ( ( p1_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(1.0) * 0.15 ), ( f32(1.0) * 0.15 ) ) ) + ( p1_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p1_nodeVar5 = mix( p1_nodeVar2.xyz, p1_nodeVar4.xyz, 0.5 );
	p1_nodeVar6 = picture_read( ( ( ( p1_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p1_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p1_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p1_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p1_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p1_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p1_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p1_nodeVar9 = ( ( ( p1_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p1_nodeVar10 = ( p1_nodeVar9 * 1.0 );
	p1_nodeVar11 = ( ( p1_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar12 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar10 + p1_nodeVar11 ), ( ( p1_nodeVar10 + p1_nodeVar11 ) * 0.3 ) ) ) );
	p1_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p1_nodeVar14 = ( p1_nodeVar9 * 1.1 );
	p1_nodeVar15 = ( ( p1_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar16 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar14 + p1_nodeVar15 ), ( ( p1_nodeVar14 + p1_nodeVar15 ) * 0.3 ) ) ) );
	p1_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p1_nodeVar18 = ( p1_nodeVar9 * 1.2 );
	p1_nodeVar19 = ( ( p1_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar20 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar18 + p1_nodeVar19 ), ( ( p1_nodeVar18 + p1_nodeVar19 ) * 0.3 ) ) ) );
	p1_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p1_nodeVar22 = ( p1_nodeVar9 * 1.3 );
	p1_nodeVar23 = ( ( p1_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar24 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar22 + p1_nodeVar23 ), ( ( p1_nodeVar22 + p1_nodeVar23 ) * 0.3 ) ) ) );
	p1_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p1_nodeVar26 = ( p1_nodeVar9 * 1.4 );
	p1_nodeVar27 = ( ( p1_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar28 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar26 + p1_nodeVar27 ), ( ( p1_nodeVar26 + p1_nodeVar27 ) * 0.3 ) ) ) );
	p1_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p1_nodeVar30 = ( p1_nodeVar9 * 1.5 );
	p1_nodeVar31 = ( ( p1_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar32 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar30 + p1_nodeVar31 ), ( ( p1_nodeVar30 + p1_nodeVar31 ) * 0.3 ) ) ) );
	p1_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p1_nodeVar34 = ( p1_nodeVar9 * 1.6 );
	p1_nodeVar35 = ( ( p1_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar36 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar34 + p1_nodeVar35 ), ( ( p1_nodeVar34 + p1_nodeVar35 ) * 0.3 ) ) ) );
	p1_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p1_nodeVar38 = ( p1_nodeVar9 * 1.7000000000000002 );
	p1_nodeVar39 = ( ( p1_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar40 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar38 + p1_nodeVar39 ), ( ( p1_nodeVar38 + p1_nodeVar39 ) * 0.3 ) ) ) );
	p1_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p1_nodeVar42 = ( p1_nodeVar9 * 1.8 );
	p1_nodeVar43 = ( ( p1_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar44 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar42 + p1_nodeVar43 ), ( ( p1_nodeVar42 + p1_nodeVar43 ) * 0.3 ) ) ) );
	p1_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p1_nodeVar46 = ( p1_nodeVar9 * 1.9 );
	p1_nodeVar47 = ( ( p1_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p1_nodeVar48 = target_read( t0, t0_sampler, ( ( p1_nodeVar0 + ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(1.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p1_nodeVar46 + p1_nodeVar47 ), ( ( p1_nodeVar46 + p1_nodeVar47 ) * 0.3 ) ) ) );
	p1_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p1_nodeVar50 = target_read( t0, t0_sampler, ( p1_nodeVar0 - ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p1_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p1_nodeVar52 = target_read( t0, t0_sampler, ( p1_nodeVar0 - ( ( ( p1_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p1_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p1_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p1_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p1_nodeVar12 * vec4<f32>( p1_nodeVar13 ) ) ) + ( p1_nodeVar16 * vec4<f32>( p1_nodeVar17 ) ) ) + ( p1_nodeVar20 * vec4<f32>( p1_nodeVar21 ) ) ) + ( p1_nodeVar24 * vec4<f32>( p1_nodeVar25 ) ) ) + ( p1_nodeVar28 * vec4<f32>( p1_nodeVar29 ) ) ) + ( p1_nodeVar32 * vec4<f32>( p1_nodeVar33 ) ) ) + ( p1_nodeVar36 * vec4<f32>( p1_nodeVar37 ) ) ) + ( p1_nodeVar40 * vec4<f32>( p1_nodeVar41 ) ) ) + ( p1_nodeVar44 * vec4<f32>( p1_nodeVar45 ) ) ) + ( p1_nodeVar48 * vec4<f32>( p1_nodeVar49 ) ) ) + ( p1_nodeVar50 * vec4<f32>( p1_nodeVar51 ) ) ) + ( p1_nodeVar52 * vec4<f32>( p1_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p1_nodeVar13 ) + p1_nodeVar17 ) + p1_nodeVar21 ) + p1_nodeVar25 ) + p1_nodeVar29 ) + p1_nodeVar33 ) + p1_nodeVar37 ) + p1_nodeVar41 ) + p1_nodeVar45 ) + p1_nodeVar49 ) + p1_nodeVar51 ) + p1_nodeVar53 ), 0.0001 ) ) );
	p1_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p1_DiffuseColor = vec4<f32>( mix( p1_nodeVar54.xyz, max( p1_nodeVar54, p1_nodeVar55 ).xyz, ( max( max( p1_nodeVar55.x, p1_nodeVar55.y ), p1_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_DiffuseColor.w = 1.0;
	p1_nodeVar56 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar56;

	// result

	p1_output.color = p1_nodeVar56;

	return p1_output;

}

// structs

struct p2_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p2_output : p2_OutputStruct;

// uniforms


// vars
var<private> p2_DiffuseColor : vec4<f32>;
var<private> p2_nodeVar0 : vec2<f32>;
var<private> p2_nodeVar1 : vec2<f32>;
var<private> p2_nodeVar2 : vec4<f32>;
var<private> p2_nodeVar3 : vec2<f32>;
var<private> p2_nodeVar4 : vec4<f32>;
var<private> p2_nodeVar5 : vec3<f32>;
var<private> p2_nodeVar6 : vec4<f32>;
var<private> p2_nodeVar7 : vec2<f32>;
var<private> p2_nodeVar8 : vec2<f32>;
var<private> p2_nodeVar9 : f32;
var<private> p2_nodeVar10 : f32;
var<private> p2_nodeVar11 : f32;
var<private> p2_nodeVar12 : vec4<f32>;
var<private> p2_nodeVar13 : f32;
var<private> p2_nodeVar14 : f32;
var<private> p2_nodeVar15 : f32;
var<private> p2_nodeVar16 : vec4<f32>;
var<private> p2_nodeVar17 : f32;
var<private> p2_nodeVar18 : f32;
var<private> p2_nodeVar19 : f32;
var<private> p2_nodeVar20 : vec4<f32>;
var<private> p2_nodeVar21 : f32;
var<private> p2_nodeVar22 : f32;
var<private> p2_nodeVar23 : f32;
var<private> p2_nodeVar24 : vec4<f32>;
var<private> p2_nodeVar25 : f32;
var<private> p2_nodeVar26 : f32;
var<private> p2_nodeVar27 : f32;
var<private> p2_nodeVar28 : vec4<f32>;
var<private> p2_nodeVar29 : f32;
var<private> p2_nodeVar30 : f32;
var<private> p2_nodeVar31 : f32;
var<private> p2_nodeVar32 : vec4<f32>;
var<private> p2_nodeVar33 : f32;
var<private> p2_nodeVar34 : f32;
var<private> p2_nodeVar35 : f32;
var<private> p2_nodeVar36 : vec4<f32>;
var<private> p2_nodeVar37 : f32;
var<private> p2_nodeVar38 : f32;
var<private> p2_nodeVar39 : f32;
var<private> p2_nodeVar40 : vec4<f32>;
var<private> p2_nodeVar41 : f32;
var<private> p2_nodeVar42 : f32;
var<private> p2_nodeVar43 : f32;
var<private> p2_nodeVar44 : vec4<f32>;
var<private> p2_nodeVar45 : f32;
var<private> p2_nodeVar46 : f32;
var<private> p2_nodeVar47 : f32;
var<private> p2_nodeVar48 : vec4<f32>;
var<private> p2_nodeVar49 : f32;
var<private> p2_nodeVar50 : vec4<f32>;
var<private> p2_nodeVar51 : f32;
var<private> p2_nodeVar52 : vec4<f32>;
var<private> p2_nodeVar53 : f32;
var<private> p2_nodeVar54 : vec4<f32>;
var<private> p2_nodeVar55 : vec4<f32>;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar56 : vec4<f32>;

// codes


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p2_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p2_nodeVar2 = picture_read( ( ( ( p2_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(2.0) * 0.1 ), ( f32(2.0) * 0.1 ) ) ) + p2_nodeVar1 ) );
	p2_nodeVar3 = vec2<f32>( ( ( p2_nodeVar0.x * 0.7071054825112363 ) - ( p2_nodeVar0.y * 0.7071080798594735 ) ), ( ( p2_nodeVar0.x * 0.7071080798594735 ) + ( p2_nodeVar0.y * 0.7071054825112363 ) ) );
	p2_nodeVar4 = picture_read( ( ( ( ( p2_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(2.0) * 0.15 ), ( f32(2.0) * 0.15 ) ) ) + ( p2_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p2_nodeVar5 = mix( p2_nodeVar2.xyz, p2_nodeVar4.xyz, 0.5 );
	p2_nodeVar6 = picture_read( ( ( ( p2_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p2_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p2_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p2_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p2_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p2_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p2_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p2_nodeVar9 = ( ( ( p2_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p2_nodeVar10 = ( p2_nodeVar9 * 1.0 );
	p2_nodeVar11 = ( ( p2_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar12 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar10 + p2_nodeVar11 ), ( ( p2_nodeVar10 + p2_nodeVar11 ) * 0.3 ) ) ) );
	p2_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p2_nodeVar14 = ( p2_nodeVar9 * 1.1 );
	p2_nodeVar15 = ( ( p2_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar16 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar14 + p2_nodeVar15 ), ( ( p2_nodeVar14 + p2_nodeVar15 ) * 0.3 ) ) ) );
	p2_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p2_nodeVar18 = ( p2_nodeVar9 * 1.2 );
	p2_nodeVar19 = ( ( p2_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar20 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar18 + p2_nodeVar19 ), ( ( p2_nodeVar18 + p2_nodeVar19 ) * 0.3 ) ) ) );
	p2_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p2_nodeVar22 = ( p2_nodeVar9 * 1.3 );
	p2_nodeVar23 = ( ( p2_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar24 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar22 + p2_nodeVar23 ), ( ( p2_nodeVar22 + p2_nodeVar23 ) * 0.3 ) ) ) );
	p2_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p2_nodeVar26 = ( p2_nodeVar9 * 1.4 );
	p2_nodeVar27 = ( ( p2_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar28 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar26 + p2_nodeVar27 ), ( ( p2_nodeVar26 + p2_nodeVar27 ) * 0.3 ) ) ) );
	p2_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p2_nodeVar30 = ( p2_nodeVar9 * 1.5 );
	p2_nodeVar31 = ( ( p2_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar32 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar30 + p2_nodeVar31 ), ( ( p2_nodeVar30 + p2_nodeVar31 ) * 0.3 ) ) ) );
	p2_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p2_nodeVar34 = ( p2_nodeVar9 * 1.6 );
	p2_nodeVar35 = ( ( p2_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar36 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar34 + p2_nodeVar35 ), ( ( p2_nodeVar34 + p2_nodeVar35 ) * 0.3 ) ) ) );
	p2_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p2_nodeVar38 = ( p2_nodeVar9 * 1.7000000000000002 );
	p2_nodeVar39 = ( ( p2_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar40 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar38 + p2_nodeVar39 ), ( ( p2_nodeVar38 + p2_nodeVar39 ) * 0.3 ) ) ) );
	p2_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p2_nodeVar42 = ( p2_nodeVar9 * 1.8 );
	p2_nodeVar43 = ( ( p2_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar44 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar42 + p2_nodeVar43 ), ( ( p2_nodeVar42 + p2_nodeVar43 ) * 0.3 ) ) ) );
	p2_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p2_nodeVar46 = ( p2_nodeVar9 * 1.9 );
	p2_nodeVar47 = ( ( p2_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p2_nodeVar48 = target_read( t1, t1_sampler, ( ( p2_nodeVar0 + ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(2.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p2_nodeVar46 + p2_nodeVar47 ), ( ( p2_nodeVar46 + p2_nodeVar47 ) * 0.3 ) ) ) );
	p2_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p2_nodeVar50 = target_read( t1, t1_sampler, ( p2_nodeVar0 - ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p2_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p2_nodeVar52 = target_read( t1, t1_sampler, ( p2_nodeVar0 - ( ( ( p2_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p2_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p2_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p2_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p2_nodeVar12 * vec4<f32>( p2_nodeVar13 ) ) ) + ( p2_nodeVar16 * vec4<f32>( p2_nodeVar17 ) ) ) + ( p2_nodeVar20 * vec4<f32>( p2_nodeVar21 ) ) ) + ( p2_nodeVar24 * vec4<f32>( p2_nodeVar25 ) ) ) + ( p2_nodeVar28 * vec4<f32>( p2_nodeVar29 ) ) ) + ( p2_nodeVar32 * vec4<f32>( p2_nodeVar33 ) ) ) + ( p2_nodeVar36 * vec4<f32>( p2_nodeVar37 ) ) ) + ( p2_nodeVar40 * vec4<f32>( p2_nodeVar41 ) ) ) + ( p2_nodeVar44 * vec4<f32>( p2_nodeVar45 ) ) ) + ( p2_nodeVar48 * vec4<f32>( p2_nodeVar49 ) ) ) + ( p2_nodeVar50 * vec4<f32>( p2_nodeVar51 ) ) ) + ( p2_nodeVar52 * vec4<f32>( p2_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p2_nodeVar13 ) + p2_nodeVar17 ) + p2_nodeVar21 ) + p2_nodeVar25 ) + p2_nodeVar29 ) + p2_nodeVar33 ) + p2_nodeVar37 ) + p2_nodeVar41 ) + p2_nodeVar45 ) + p2_nodeVar49 ) + p2_nodeVar51 ) + p2_nodeVar53 ), 0.0001 ) ) );
	p2_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p2_DiffuseColor = vec4<f32>( mix( p2_nodeVar54.xyz, max( p2_nodeVar54, p2_nodeVar55 ).xyz, ( max( max( p2_nodeVar55.x, p2_nodeVar55.y ), p2_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_DiffuseColor.w = 1.0;
	p2_nodeVar56 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar56;

	// result

	p2_output.color = p2_nodeVar56;

	return p2_output;

}

// structs

struct p3_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p3_output : p3_OutputStruct;

// uniforms


// vars
var<private> p3_DiffuseColor : vec4<f32>;
var<private> p3_nodeVar0 : vec4<f32>;
var<private> p3_Output : vec4<f32>;
var<private> p3_nodeVar1 : vec4<f32>;

// codes


fn p3_main(door_uv: vec2f) -> p3_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p3_nodeVar0 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p3_DiffuseColor = vec4<f32>( p3_nodeVar0.xyz, 1.0 );
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_DiffuseColor.w = 1.0;
	p3_nodeVar1 = max( vec4<f32>( p3_DiffuseColor.xyz, p3_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p3_Output = p3_nodeVar1;

	// result

	p3_output.color = p3_nodeVar1;

	return p3_output;

}

// structs

struct p4_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p4_output : p4_OutputStruct;

// uniforms


// vars
var<private> p4_DiffuseColor : vec4<f32>;
var<private> p4_nodeVar0 : vec2<f32>;
var<private> p4_nodeVar1 : vec2<f32>;
var<private> p4_nodeVar2 : vec4<f32>;
var<private> p4_nodeVar3 : vec2<f32>;
var<private> p4_nodeVar4 : vec4<f32>;
var<private> p4_nodeVar5 : vec3<f32>;
var<private> p4_nodeVar6 : vec4<f32>;
var<private> p4_nodeVar7 : vec2<f32>;
var<private> p4_nodeVar8 : vec2<f32>;
var<private> p4_nodeVar9 : f32;
var<private> p4_nodeVar10 : f32;
var<private> p4_nodeVar11 : f32;
var<private> p4_nodeVar12 : vec4<f32>;
var<private> p4_nodeVar13 : f32;
var<private> p4_nodeVar14 : f32;
var<private> p4_nodeVar15 : f32;
var<private> p4_nodeVar16 : vec4<f32>;
var<private> p4_nodeVar17 : f32;
var<private> p4_nodeVar18 : f32;
var<private> p4_nodeVar19 : f32;
var<private> p4_nodeVar20 : vec4<f32>;
var<private> p4_nodeVar21 : f32;
var<private> p4_nodeVar22 : f32;
var<private> p4_nodeVar23 : f32;
var<private> p4_nodeVar24 : vec4<f32>;
var<private> p4_nodeVar25 : f32;
var<private> p4_nodeVar26 : f32;
var<private> p4_nodeVar27 : f32;
var<private> p4_nodeVar28 : vec4<f32>;
var<private> p4_nodeVar29 : f32;
var<private> p4_nodeVar30 : f32;
var<private> p4_nodeVar31 : f32;
var<private> p4_nodeVar32 : vec4<f32>;
var<private> p4_nodeVar33 : f32;
var<private> p4_nodeVar34 : f32;
var<private> p4_nodeVar35 : f32;
var<private> p4_nodeVar36 : vec4<f32>;
var<private> p4_nodeVar37 : f32;
var<private> p4_nodeVar38 : f32;
var<private> p4_nodeVar39 : f32;
var<private> p4_nodeVar40 : vec4<f32>;
var<private> p4_nodeVar41 : f32;
var<private> p4_nodeVar42 : f32;
var<private> p4_nodeVar43 : f32;
var<private> p4_nodeVar44 : vec4<f32>;
var<private> p4_nodeVar45 : f32;
var<private> p4_nodeVar46 : f32;
var<private> p4_nodeVar47 : f32;
var<private> p4_nodeVar48 : vec4<f32>;
var<private> p4_nodeVar49 : f32;
var<private> p4_nodeVar50 : vec4<f32>;
var<private> p4_nodeVar51 : f32;
var<private> p4_nodeVar52 : vec4<f32>;
var<private> p4_nodeVar53 : f32;
var<private> p4_nodeVar54 : vec4<f32>;
var<private> p4_nodeVar55 : vec4<f32>;
var<private> p4_Output : vec4<f32>;
var<private> p4_nodeVar56 : vec4<f32>;

// codes


fn p4_main(door_uv: vec2f) -> p4_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p4_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p4_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p4_nodeVar2 = picture_read( ( ( ( p4_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(3.0) * 0.1 ), ( f32(3.0) * 0.1 ) ) ) + p4_nodeVar1 ) );
	p4_nodeVar3 = vec2<f32>( ( ( p4_nodeVar0.x * 0.7071054825112363 ) - ( p4_nodeVar0.y * 0.7071080798594735 ) ), ( ( p4_nodeVar0.x * 0.7071080798594735 ) + ( p4_nodeVar0.y * 0.7071054825112363 ) ) );
	p4_nodeVar4 = picture_read( ( ( ( ( p4_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(3.0) * 0.15 ), ( f32(3.0) * 0.15 ) ) ) + ( p4_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p4_nodeVar5 = mix( p4_nodeVar2.xyz, p4_nodeVar4.xyz, 0.5 );
	p4_nodeVar6 = picture_read( ( ( ( p4_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p4_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p4_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p4_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p4_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p4_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p4_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p4_nodeVar9 = ( ( ( p4_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p4_nodeVar10 = ( p4_nodeVar9 * 1.0 );
	p4_nodeVar11 = ( ( p4_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar12 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar10 + p4_nodeVar11 ), ( ( p4_nodeVar10 + p4_nodeVar11 ) * 0.3 ) ) ) );
	p4_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p4_nodeVar14 = ( p4_nodeVar9 * 1.1 );
	p4_nodeVar15 = ( ( p4_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar16 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar14 + p4_nodeVar15 ), ( ( p4_nodeVar14 + p4_nodeVar15 ) * 0.3 ) ) ) );
	p4_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p4_nodeVar18 = ( p4_nodeVar9 * 1.2 );
	p4_nodeVar19 = ( ( p4_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar20 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar18 + p4_nodeVar19 ), ( ( p4_nodeVar18 + p4_nodeVar19 ) * 0.3 ) ) ) );
	p4_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p4_nodeVar22 = ( p4_nodeVar9 * 1.3 );
	p4_nodeVar23 = ( ( p4_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar24 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar22 + p4_nodeVar23 ), ( ( p4_nodeVar22 + p4_nodeVar23 ) * 0.3 ) ) ) );
	p4_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p4_nodeVar26 = ( p4_nodeVar9 * 1.4 );
	p4_nodeVar27 = ( ( p4_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar28 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar26 + p4_nodeVar27 ), ( ( p4_nodeVar26 + p4_nodeVar27 ) * 0.3 ) ) ) );
	p4_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p4_nodeVar30 = ( p4_nodeVar9 * 1.5 );
	p4_nodeVar31 = ( ( p4_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar32 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar30 + p4_nodeVar31 ), ( ( p4_nodeVar30 + p4_nodeVar31 ) * 0.3 ) ) ) );
	p4_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p4_nodeVar34 = ( p4_nodeVar9 * 1.6 );
	p4_nodeVar35 = ( ( p4_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar36 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar34 + p4_nodeVar35 ), ( ( p4_nodeVar34 + p4_nodeVar35 ) * 0.3 ) ) ) );
	p4_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p4_nodeVar38 = ( p4_nodeVar9 * 1.7000000000000002 );
	p4_nodeVar39 = ( ( p4_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar40 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar38 + p4_nodeVar39 ), ( ( p4_nodeVar38 + p4_nodeVar39 ) * 0.3 ) ) ) );
	p4_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p4_nodeVar42 = ( p4_nodeVar9 * 1.8 );
	p4_nodeVar43 = ( ( p4_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar44 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar42 + p4_nodeVar43 ), ( ( p4_nodeVar42 + p4_nodeVar43 ) * 0.3 ) ) ) );
	p4_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p4_nodeVar46 = ( p4_nodeVar9 * 1.9 );
	p4_nodeVar47 = ( ( p4_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p4_nodeVar48 = target_read( t0, t0_sampler, ( ( p4_nodeVar0 + ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(3.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p4_nodeVar46 + p4_nodeVar47 ), ( ( p4_nodeVar46 + p4_nodeVar47 ) * 0.3 ) ) ) );
	p4_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p4_nodeVar50 = target_read( t0, t0_sampler, ( p4_nodeVar0 - ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p4_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p4_nodeVar52 = target_read( t0, t0_sampler, ( p4_nodeVar0 - ( ( ( p4_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p4_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p4_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p4_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p4_nodeVar12 * vec4<f32>( p4_nodeVar13 ) ) ) + ( p4_nodeVar16 * vec4<f32>( p4_nodeVar17 ) ) ) + ( p4_nodeVar20 * vec4<f32>( p4_nodeVar21 ) ) ) + ( p4_nodeVar24 * vec4<f32>( p4_nodeVar25 ) ) ) + ( p4_nodeVar28 * vec4<f32>( p4_nodeVar29 ) ) ) + ( p4_nodeVar32 * vec4<f32>( p4_nodeVar33 ) ) ) + ( p4_nodeVar36 * vec4<f32>( p4_nodeVar37 ) ) ) + ( p4_nodeVar40 * vec4<f32>( p4_nodeVar41 ) ) ) + ( p4_nodeVar44 * vec4<f32>( p4_nodeVar45 ) ) ) + ( p4_nodeVar48 * vec4<f32>( p4_nodeVar49 ) ) ) + ( p4_nodeVar50 * vec4<f32>( p4_nodeVar51 ) ) ) + ( p4_nodeVar52 * vec4<f32>( p4_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p4_nodeVar13 ) + p4_nodeVar17 ) + p4_nodeVar21 ) + p4_nodeVar25 ) + p4_nodeVar29 ) + p4_nodeVar33 ) + p4_nodeVar37 ) + p4_nodeVar41 ) + p4_nodeVar45 ) + p4_nodeVar49 ) + p4_nodeVar51 ) + p4_nodeVar53 ), 0.0001 ) ) );
	p4_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p4_DiffuseColor = vec4<f32>( mix( p4_nodeVar54.xyz, max( p4_nodeVar54, p4_nodeVar55 ).xyz, ( max( max( p4_nodeVar55.x, p4_nodeVar55.y ), p4_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p4_DiffuseColor.w = ( p4_DiffuseColor.w * f32(1.0) );
	p4_DiffuseColor.w = 1.0;
	p4_nodeVar56 = max( vec4<f32>( p4_DiffuseColor.xyz, p4_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p4_Output = p4_nodeVar56;

	// result

	p4_output.color = p4_nodeVar56;

	return p4_output;

}

// structs

struct p5_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p5_output : p5_OutputStruct;

// uniforms


// vars
var<private> p5_DiffuseColor : vec4<f32>;
var<private> p5_nodeVar0 : vec2<f32>;
var<private> p5_nodeVar1 : vec2<f32>;
var<private> p5_nodeVar2 : vec4<f32>;
var<private> p5_nodeVar3 : vec2<f32>;
var<private> p5_nodeVar4 : vec4<f32>;
var<private> p5_nodeVar5 : vec3<f32>;
var<private> p5_nodeVar6 : vec4<f32>;
var<private> p5_nodeVar7 : vec2<f32>;
var<private> p5_nodeVar8 : vec2<f32>;
var<private> p5_nodeVar9 : f32;
var<private> p5_nodeVar10 : f32;
var<private> p5_nodeVar11 : f32;
var<private> p5_nodeVar12 : vec4<f32>;
var<private> p5_nodeVar13 : f32;
var<private> p5_nodeVar14 : f32;
var<private> p5_nodeVar15 : f32;
var<private> p5_nodeVar16 : vec4<f32>;
var<private> p5_nodeVar17 : f32;
var<private> p5_nodeVar18 : f32;
var<private> p5_nodeVar19 : f32;
var<private> p5_nodeVar20 : vec4<f32>;
var<private> p5_nodeVar21 : f32;
var<private> p5_nodeVar22 : f32;
var<private> p5_nodeVar23 : f32;
var<private> p5_nodeVar24 : vec4<f32>;
var<private> p5_nodeVar25 : f32;
var<private> p5_nodeVar26 : f32;
var<private> p5_nodeVar27 : f32;
var<private> p5_nodeVar28 : vec4<f32>;
var<private> p5_nodeVar29 : f32;
var<private> p5_nodeVar30 : f32;
var<private> p5_nodeVar31 : f32;
var<private> p5_nodeVar32 : vec4<f32>;
var<private> p5_nodeVar33 : f32;
var<private> p5_nodeVar34 : f32;
var<private> p5_nodeVar35 : f32;
var<private> p5_nodeVar36 : vec4<f32>;
var<private> p5_nodeVar37 : f32;
var<private> p5_nodeVar38 : f32;
var<private> p5_nodeVar39 : f32;
var<private> p5_nodeVar40 : vec4<f32>;
var<private> p5_nodeVar41 : f32;
var<private> p5_nodeVar42 : f32;
var<private> p5_nodeVar43 : f32;
var<private> p5_nodeVar44 : vec4<f32>;
var<private> p5_nodeVar45 : f32;
var<private> p5_nodeVar46 : f32;
var<private> p5_nodeVar47 : f32;
var<private> p5_nodeVar48 : vec4<f32>;
var<private> p5_nodeVar49 : f32;
var<private> p5_nodeVar50 : vec4<f32>;
var<private> p5_nodeVar51 : f32;
var<private> p5_nodeVar52 : vec4<f32>;
var<private> p5_nodeVar53 : f32;
var<private> p5_nodeVar54 : vec4<f32>;
var<private> p5_nodeVar55 : vec4<f32>;
var<private> p5_Output : vec4<f32>;
var<private> p5_nodeVar56 : vec4<f32>;

// codes


fn p5_main(door_uv: vec2f) -> p5_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p5_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p5_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p5_nodeVar2 = picture_read( ( ( ( p5_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(4.0) * 0.1 ), ( f32(4.0) * 0.1 ) ) ) + p5_nodeVar1 ) );
	p5_nodeVar3 = vec2<f32>( ( ( p5_nodeVar0.x * 0.7071054825112363 ) - ( p5_nodeVar0.y * 0.7071080798594735 ) ), ( ( p5_nodeVar0.x * 0.7071080798594735 ) + ( p5_nodeVar0.y * 0.7071054825112363 ) ) );
	p5_nodeVar4 = picture_read( ( ( ( ( p5_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(4.0) * 0.15 ), ( f32(4.0) * 0.15 ) ) ) + ( p5_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p5_nodeVar5 = mix( p5_nodeVar2.xyz, p5_nodeVar4.xyz, 0.5 );
	p5_nodeVar6 = picture_read( ( ( ( p5_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p5_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p5_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p5_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p5_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p5_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p5_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p5_nodeVar9 = ( ( ( p5_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p5_nodeVar10 = ( p5_nodeVar9 * 1.0 );
	p5_nodeVar11 = ( ( p5_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar12 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar10 + p5_nodeVar11 ), ( ( p5_nodeVar10 + p5_nodeVar11 ) * 0.3 ) ) ) );
	p5_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p5_nodeVar14 = ( p5_nodeVar9 * 1.1 );
	p5_nodeVar15 = ( ( p5_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar16 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar14 + p5_nodeVar15 ), ( ( p5_nodeVar14 + p5_nodeVar15 ) * 0.3 ) ) ) );
	p5_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p5_nodeVar18 = ( p5_nodeVar9 * 1.2 );
	p5_nodeVar19 = ( ( p5_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar20 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar18 + p5_nodeVar19 ), ( ( p5_nodeVar18 + p5_nodeVar19 ) * 0.3 ) ) ) );
	p5_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p5_nodeVar22 = ( p5_nodeVar9 * 1.3 );
	p5_nodeVar23 = ( ( p5_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar24 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar22 + p5_nodeVar23 ), ( ( p5_nodeVar22 + p5_nodeVar23 ) * 0.3 ) ) ) );
	p5_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p5_nodeVar26 = ( p5_nodeVar9 * 1.4 );
	p5_nodeVar27 = ( ( p5_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar28 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar26 + p5_nodeVar27 ), ( ( p5_nodeVar26 + p5_nodeVar27 ) * 0.3 ) ) ) );
	p5_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p5_nodeVar30 = ( p5_nodeVar9 * 1.5 );
	p5_nodeVar31 = ( ( p5_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar32 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar30 + p5_nodeVar31 ), ( ( p5_nodeVar30 + p5_nodeVar31 ) * 0.3 ) ) ) );
	p5_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p5_nodeVar34 = ( p5_nodeVar9 * 1.6 );
	p5_nodeVar35 = ( ( p5_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar36 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar34 + p5_nodeVar35 ), ( ( p5_nodeVar34 + p5_nodeVar35 ) * 0.3 ) ) ) );
	p5_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p5_nodeVar38 = ( p5_nodeVar9 * 1.7000000000000002 );
	p5_nodeVar39 = ( ( p5_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar40 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar38 + p5_nodeVar39 ), ( ( p5_nodeVar38 + p5_nodeVar39 ) * 0.3 ) ) ) );
	p5_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p5_nodeVar42 = ( p5_nodeVar9 * 1.8 );
	p5_nodeVar43 = ( ( p5_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar44 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar42 + p5_nodeVar43 ), ( ( p5_nodeVar42 + p5_nodeVar43 ) * 0.3 ) ) ) );
	p5_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p5_nodeVar46 = ( p5_nodeVar9 * 1.9 );
	p5_nodeVar47 = ( ( p5_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p5_nodeVar48 = target_read( t1, t1_sampler, ( ( p5_nodeVar0 + ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(4.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p5_nodeVar46 + p5_nodeVar47 ), ( ( p5_nodeVar46 + p5_nodeVar47 ) * 0.3 ) ) ) );
	p5_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p5_nodeVar50 = target_read( t1, t1_sampler, ( p5_nodeVar0 - ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p5_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p5_nodeVar52 = target_read( t1, t1_sampler, ( p5_nodeVar0 - ( ( ( p5_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p5_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p5_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p5_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p5_nodeVar12 * vec4<f32>( p5_nodeVar13 ) ) ) + ( p5_nodeVar16 * vec4<f32>( p5_nodeVar17 ) ) ) + ( p5_nodeVar20 * vec4<f32>( p5_nodeVar21 ) ) ) + ( p5_nodeVar24 * vec4<f32>( p5_nodeVar25 ) ) ) + ( p5_nodeVar28 * vec4<f32>( p5_nodeVar29 ) ) ) + ( p5_nodeVar32 * vec4<f32>( p5_nodeVar33 ) ) ) + ( p5_nodeVar36 * vec4<f32>( p5_nodeVar37 ) ) ) + ( p5_nodeVar40 * vec4<f32>( p5_nodeVar41 ) ) ) + ( p5_nodeVar44 * vec4<f32>( p5_nodeVar45 ) ) ) + ( p5_nodeVar48 * vec4<f32>( p5_nodeVar49 ) ) ) + ( p5_nodeVar50 * vec4<f32>( p5_nodeVar51 ) ) ) + ( p5_nodeVar52 * vec4<f32>( p5_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p5_nodeVar13 ) + p5_nodeVar17 ) + p5_nodeVar21 ) + p5_nodeVar25 ) + p5_nodeVar29 ) + p5_nodeVar33 ) + p5_nodeVar37 ) + p5_nodeVar41 ) + p5_nodeVar45 ) + p5_nodeVar49 ) + p5_nodeVar51 ) + p5_nodeVar53 ), 0.0001 ) ) );
	p5_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p5_DiffuseColor = vec4<f32>( mix( p5_nodeVar54.xyz, max( p5_nodeVar54, p5_nodeVar55 ).xyz, ( max( max( p5_nodeVar55.x, p5_nodeVar55.y ), p5_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p5_DiffuseColor.w = ( p5_DiffuseColor.w * f32(1.0) );
	p5_DiffuseColor.w = 1.0;
	p5_nodeVar56 = max( vec4<f32>( p5_DiffuseColor.xyz, p5_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p5_Output = p5_nodeVar56;

	// result

	p5_output.color = p5_nodeVar56;

	return p5_output;

}

// structs

struct p6_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p6_output : p6_OutputStruct;

// uniforms


// vars
var<private> p6_DiffuseColor : vec4<f32>;
var<private> p6_nodeVar0 : vec2<f32>;
var<private> p6_nodeVar1 : vec2<f32>;
var<private> p6_nodeVar2 : vec4<f32>;
var<private> p6_nodeVar3 : vec2<f32>;
var<private> p6_nodeVar4 : vec4<f32>;
var<private> p6_nodeVar5 : vec3<f32>;
var<private> p6_nodeVar6 : vec4<f32>;
var<private> p6_nodeVar7 : vec2<f32>;
var<private> p6_nodeVar8 : vec2<f32>;
var<private> p6_nodeVar9 : f32;
var<private> p6_nodeVar10 : f32;
var<private> p6_nodeVar11 : f32;
var<private> p6_nodeVar12 : vec4<f32>;
var<private> p6_nodeVar13 : f32;
var<private> p6_nodeVar14 : f32;
var<private> p6_nodeVar15 : f32;
var<private> p6_nodeVar16 : vec4<f32>;
var<private> p6_nodeVar17 : f32;
var<private> p6_nodeVar18 : f32;
var<private> p6_nodeVar19 : f32;
var<private> p6_nodeVar20 : vec4<f32>;
var<private> p6_nodeVar21 : f32;
var<private> p6_nodeVar22 : f32;
var<private> p6_nodeVar23 : f32;
var<private> p6_nodeVar24 : vec4<f32>;
var<private> p6_nodeVar25 : f32;
var<private> p6_nodeVar26 : f32;
var<private> p6_nodeVar27 : f32;
var<private> p6_nodeVar28 : vec4<f32>;
var<private> p6_nodeVar29 : f32;
var<private> p6_nodeVar30 : f32;
var<private> p6_nodeVar31 : f32;
var<private> p6_nodeVar32 : vec4<f32>;
var<private> p6_nodeVar33 : f32;
var<private> p6_nodeVar34 : f32;
var<private> p6_nodeVar35 : f32;
var<private> p6_nodeVar36 : vec4<f32>;
var<private> p6_nodeVar37 : f32;
var<private> p6_nodeVar38 : f32;
var<private> p6_nodeVar39 : f32;
var<private> p6_nodeVar40 : vec4<f32>;
var<private> p6_nodeVar41 : f32;
var<private> p6_nodeVar42 : f32;
var<private> p6_nodeVar43 : f32;
var<private> p6_nodeVar44 : vec4<f32>;
var<private> p6_nodeVar45 : f32;
var<private> p6_nodeVar46 : f32;
var<private> p6_nodeVar47 : f32;
var<private> p6_nodeVar48 : vec4<f32>;
var<private> p6_nodeVar49 : f32;
var<private> p6_nodeVar50 : vec4<f32>;
var<private> p6_nodeVar51 : f32;
var<private> p6_nodeVar52 : vec4<f32>;
var<private> p6_nodeVar53 : f32;
var<private> p6_nodeVar54 : vec4<f32>;
var<private> p6_nodeVar55 : vec4<f32>;
var<private> p6_Output : vec4<f32>;
var<private> p6_nodeVar56 : vec4<f32>;

// codes


fn p6_main(door_uv: vec2f) -> p6_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p6_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p6_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p6_nodeVar2 = picture_read( ( ( ( p6_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(5.0) * 0.1 ), ( f32(5.0) * 0.1 ) ) ) + p6_nodeVar1 ) );
	p6_nodeVar3 = vec2<f32>( ( ( p6_nodeVar0.x * 0.7071054825112363 ) - ( p6_nodeVar0.y * 0.7071080798594735 ) ), ( ( p6_nodeVar0.x * 0.7071080798594735 ) + ( p6_nodeVar0.y * 0.7071054825112363 ) ) );
	p6_nodeVar4 = picture_read( ( ( ( ( p6_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(5.0) * 0.15 ), ( f32(5.0) * 0.15 ) ) ) + ( p6_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p6_nodeVar5 = mix( p6_nodeVar2.xyz, p6_nodeVar4.xyz, 0.5 );
	p6_nodeVar6 = picture_read( ( ( ( p6_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p6_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p6_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p6_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p6_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p6_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p6_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p6_nodeVar9 = ( ( ( p6_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p6_nodeVar10 = ( p6_nodeVar9 * 1.0 );
	p6_nodeVar11 = ( ( p6_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar12 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar10 + p6_nodeVar11 ), ( ( p6_nodeVar10 + p6_nodeVar11 ) * 0.3 ) ) ) );
	p6_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p6_nodeVar14 = ( p6_nodeVar9 * 1.1 );
	p6_nodeVar15 = ( ( p6_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar16 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar14 + p6_nodeVar15 ), ( ( p6_nodeVar14 + p6_nodeVar15 ) * 0.3 ) ) ) );
	p6_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p6_nodeVar18 = ( p6_nodeVar9 * 1.2 );
	p6_nodeVar19 = ( ( p6_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar20 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar18 + p6_nodeVar19 ), ( ( p6_nodeVar18 + p6_nodeVar19 ) * 0.3 ) ) ) );
	p6_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p6_nodeVar22 = ( p6_nodeVar9 * 1.3 );
	p6_nodeVar23 = ( ( p6_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar24 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar22 + p6_nodeVar23 ), ( ( p6_nodeVar22 + p6_nodeVar23 ) * 0.3 ) ) ) );
	p6_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p6_nodeVar26 = ( p6_nodeVar9 * 1.4 );
	p6_nodeVar27 = ( ( p6_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar28 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar26 + p6_nodeVar27 ), ( ( p6_nodeVar26 + p6_nodeVar27 ) * 0.3 ) ) ) );
	p6_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p6_nodeVar30 = ( p6_nodeVar9 * 1.5 );
	p6_nodeVar31 = ( ( p6_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar32 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar30 + p6_nodeVar31 ), ( ( p6_nodeVar30 + p6_nodeVar31 ) * 0.3 ) ) ) );
	p6_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p6_nodeVar34 = ( p6_nodeVar9 * 1.6 );
	p6_nodeVar35 = ( ( p6_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar36 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar34 + p6_nodeVar35 ), ( ( p6_nodeVar34 + p6_nodeVar35 ) * 0.3 ) ) ) );
	p6_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p6_nodeVar38 = ( p6_nodeVar9 * 1.7000000000000002 );
	p6_nodeVar39 = ( ( p6_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar40 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar38 + p6_nodeVar39 ), ( ( p6_nodeVar38 + p6_nodeVar39 ) * 0.3 ) ) ) );
	p6_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p6_nodeVar42 = ( p6_nodeVar9 * 1.8 );
	p6_nodeVar43 = ( ( p6_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar44 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar42 + p6_nodeVar43 ), ( ( p6_nodeVar42 + p6_nodeVar43 ) * 0.3 ) ) ) );
	p6_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p6_nodeVar46 = ( p6_nodeVar9 * 1.9 );
	p6_nodeVar47 = ( ( p6_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p6_nodeVar48 = target_read( t0, t0_sampler, ( ( p6_nodeVar0 + ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(5.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p6_nodeVar46 + p6_nodeVar47 ), ( ( p6_nodeVar46 + p6_nodeVar47 ) * 0.3 ) ) ) );
	p6_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p6_nodeVar50 = target_read( t0, t0_sampler, ( p6_nodeVar0 - ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p6_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p6_nodeVar52 = target_read( t0, t0_sampler, ( p6_nodeVar0 - ( ( ( p6_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p6_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p6_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p6_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p6_nodeVar12 * vec4<f32>( p6_nodeVar13 ) ) ) + ( p6_nodeVar16 * vec4<f32>( p6_nodeVar17 ) ) ) + ( p6_nodeVar20 * vec4<f32>( p6_nodeVar21 ) ) ) + ( p6_nodeVar24 * vec4<f32>( p6_nodeVar25 ) ) ) + ( p6_nodeVar28 * vec4<f32>( p6_nodeVar29 ) ) ) + ( p6_nodeVar32 * vec4<f32>( p6_nodeVar33 ) ) ) + ( p6_nodeVar36 * vec4<f32>( p6_nodeVar37 ) ) ) + ( p6_nodeVar40 * vec4<f32>( p6_nodeVar41 ) ) ) + ( p6_nodeVar44 * vec4<f32>( p6_nodeVar45 ) ) ) + ( p6_nodeVar48 * vec4<f32>( p6_nodeVar49 ) ) ) + ( p6_nodeVar50 * vec4<f32>( p6_nodeVar51 ) ) ) + ( p6_nodeVar52 * vec4<f32>( p6_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p6_nodeVar13 ) + p6_nodeVar17 ) + p6_nodeVar21 ) + p6_nodeVar25 ) + p6_nodeVar29 ) + p6_nodeVar33 ) + p6_nodeVar37 ) + p6_nodeVar41 ) + p6_nodeVar45 ) + p6_nodeVar49 ) + p6_nodeVar51 ) + p6_nodeVar53 ), 0.0001 ) ) );
	p6_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p6_DiffuseColor = vec4<f32>( mix( p6_nodeVar54.xyz, max( p6_nodeVar54, p6_nodeVar55 ).xyz, ( max( max( p6_nodeVar55.x, p6_nodeVar55.y ), p6_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p6_DiffuseColor.w = ( p6_DiffuseColor.w * f32(1.0) );
	p6_DiffuseColor.w = 1.0;
	p6_nodeVar56 = max( vec4<f32>( p6_DiffuseColor.xyz, p6_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p6_Output = p6_nodeVar56;

	// result

	p6_output.color = p6_nodeVar56;

	return p6_output;

}

// structs

struct p7_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p7_output : p7_OutputStruct;

// uniforms


// vars
var<private> p7_DiffuseColor : vec4<f32>;
var<private> p7_nodeVar0 : vec2<f32>;
var<private> p7_nodeVar1 : vec2<f32>;
var<private> p7_nodeVar2 : vec4<f32>;
var<private> p7_nodeVar3 : vec2<f32>;
var<private> p7_nodeVar4 : vec4<f32>;
var<private> p7_nodeVar5 : vec3<f32>;
var<private> p7_nodeVar6 : vec4<f32>;
var<private> p7_nodeVar7 : vec2<f32>;
var<private> p7_nodeVar8 : vec2<f32>;
var<private> p7_nodeVar9 : f32;
var<private> p7_nodeVar10 : f32;
var<private> p7_nodeVar11 : f32;
var<private> p7_nodeVar12 : vec4<f32>;
var<private> p7_nodeVar13 : f32;
var<private> p7_nodeVar14 : f32;
var<private> p7_nodeVar15 : f32;
var<private> p7_nodeVar16 : vec4<f32>;
var<private> p7_nodeVar17 : f32;
var<private> p7_nodeVar18 : f32;
var<private> p7_nodeVar19 : f32;
var<private> p7_nodeVar20 : vec4<f32>;
var<private> p7_nodeVar21 : f32;
var<private> p7_nodeVar22 : f32;
var<private> p7_nodeVar23 : f32;
var<private> p7_nodeVar24 : vec4<f32>;
var<private> p7_nodeVar25 : f32;
var<private> p7_nodeVar26 : f32;
var<private> p7_nodeVar27 : f32;
var<private> p7_nodeVar28 : vec4<f32>;
var<private> p7_nodeVar29 : f32;
var<private> p7_nodeVar30 : f32;
var<private> p7_nodeVar31 : f32;
var<private> p7_nodeVar32 : vec4<f32>;
var<private> p7_nodeVar33 : f32;
var<private> p7_nodeVar34 : f32;
var<private> p7_nodeVar35 : f32;
var<private> p7_nodeVar36 : vec4<f32>;
var<private> p7_nodeVar37 : f32;
var<private> p7_nodeVar38 : f32;
var<private> p7_nodeVar39 : f32;
var<private> p7_nodeVar40 : vec4<f32>;
var<private> p7_nodeVar41 : f32;
var<private> p7_nodeVar42 : f32;
var<private> p7_nodeVar43 : f32;
var<private> p7_nodeVar44 : vec4<f32>;
var<private> p7_nodeVar45 : f32;
var<private> p7_nodeVar46 : f32;
var<private> p7_nodeVar47 : f32;
var<private> p7_nodeVar48 : vec4<f32>;
var<private> p7_nodeVar49 : f32;
var<private> p7_nodeVar50 : vec4<f32>;
var<private> p7_nodeVar51 : f32;
var<private> p7_nodeVar52 : vec4<f32>;
var<private> p7_nodeVar53 : f32;
var<private> p7_nodeVar54 : vec4<f32>;
var<private> p7_nodeVar55 : vec4<f32>;
var<private> p7_Output : vec4<f32>;
var<private> p7_nodeVar56 : vec4<f32>;

// codes


fn p7_main(door_uv: vec2f) -> p7_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p7_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p7_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p7_nodeVar2 = picture_read( ( ( ( p7_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(6.0) * 0.1 ), ( f32(6.0) * 0.1 ) ) ) + p7_nodeVar1 ) );
	p7_nodeVar3 = vec2<f32>( ( ( p7_nodeVar0.x * 0.7071054825112363 ) - ( p7_nodeVar0.y * 0.7071080798594735 ) ), ( ( p7_nodeVar0.x * 0.7071080798594735 ) + ( p7_nodeVar0.y * 0.7071054825112363 ) ) );
	p7_nodeVar4 = picture_read( ( ( ( ( p7_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(6.0) * 0.15 ), ( f32(6.0) * 0.15 ) ) ) + ( p7_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p7_nodeVar5 = mix( p7_nodeVar2.xyz, p7_nodeVar4.xyz, 0.5 );
	p7_nodeVar6 = picture_read( ( ( ( p7_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p7_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p7_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p7_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p7_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p7_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p7_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p7_nodeVar9 = ( ( ( p7_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p7_nodeVar10 = ( p7_nodeVar9 * 1.0 );
	p7_nodeVar11 = ( ( p7_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar12 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar10 + p7_nodeVar11 ), ( ( p7_nodeVar10 + p7_nodeVar11 ) * 0.3 ) ) ) );
	p7_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p7_nodeVar14 = ( p7_nodeVar9 * 1.1 );
	p7_nodeVar15 = ( ( p7_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar16 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar14 + p7_nodeVar15 ), ( ( p7_nodeVar14 + p7_nodeVar15 ) * 0.3 ) ) ) );
	p7_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p7_nodeVar18 = ( p7_nodeVar9 * 1.2 );
	p7_nodeVar19 = ( ( p7_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar20 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar18 + p7_nodeVar19 ), ( ( p7_nodeVar18 + p7_nodeVar19 ) * 0.3 ) ) ) );
	p7_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p7_nodeVar22 = ( p7_nodeVar9 * 1.3 );
	p7_nodeVar23 = ( ( p7_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar24 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar22 + p7_nodeVar23 ), ( ( p7_nodeVar22 + p7_nodeVar23 ) * 0.3 ) ) ) );
	p7_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p7_nodeVar26 = ( p7_nodeVar9 * 1.4 );
	p7_nodeVar27 = ( ( p7_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar28 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar26 + p7_nodeVar27 ), ( ( p7_nodeVar26 + p7_nodeVar27 ) * 0.3 ) ) ) );
	p7_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p7_nodeVar30 = ( p7_nodeVar9 * 1.5 );
	p7_nodeVar31 = ( ( p7_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar32 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar30 + p7_nodeVar31 ), ( ( p7_nodeVar30 + p7_nodeVar31 ) * 0.3 ) ) ) );
	p7_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p7_nodeVar34 = ( p7_nodeVar9 * 1.6 );
	p7_nodeVar35 = ( ( p7_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar36 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar34 + p7_nodeVar35 ), ( ( p7_nodeVar34 + p7_nodeVar35 ) * 0.3 ) ) ) );
	p7_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p7_nodeVar38 = ( p7_nodeVar9 * 1.7000000000000002 );
	p7_nodeVar39 = ( ( p7_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar40 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar38 + p7_nodeVar39 ), ( ( p7_nodeVar38 + p7_nodeVar39 ) * 0.3 ) ) ) );
	p7_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p7_nodeVar42 = ( p7_nodeVar9 * 1.8 );
	p7_nodeVar43 = ( ( p7_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar44 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar42 + p7_nodeVar43 ), ( ( p7_nodeVar42 + p7_nodeVar43 ) * 0.3 ) ) ) );
	p7_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p7_nodeVar46 = ( p7_nodeVar9 * 1.9 );
	p7_nodeVar47 = ( ( p7_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p7_nodeVar48 = target_read( t1, t1_sampler, ( ( p7_nodeVar0 + ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(6.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p7_nodeVar46 + p7_nodeVar47 ), ( ( p7_nodeVar46 + p7_nodeVar47 ) * 0.3 ) ) ) );
	p7_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p7_nodeVar50 = target_read( t1, t1_sampler, ( p7_nodeVar0 - ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p7_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p7_nodeVar52 = target_read( t1, t1_sampler, ( p7_nodeVar0 - ( ( ( p7_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p7_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p7_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p7_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p7_nodeVar12 * vec4<f32>( p7_nodeVar13 ) ) ) + ( p7_nodeVar16 * vec4<f32>( p7_nodeVar17 ) ) ) + ( p7_nodeVar20 * vec4<f32>( p7_nodeVar21 ) ) ) + ( p7_nodeVar24 * vec4<f32>( p7_nodeVar25 ) ) ) + ( p7_nodeVar28 * vec4<f32>( p7_nodeVar29 ) ) ) + ( p7_nodeVar32 * vec4<f32>( p7_nodeVar33 ) ) ) + ( p7_nodeVar36 * vec4<f32>( p7_nodeVar37 ) ) ) + ( p7_nodeVar40 * vec4<f32>( p7_nodeVar41 ) ) ) + ( p7_nodeVar44 * vec4<f32>( p7_nodeVar45 ) ) ) + ( p7_nodeVar48 * vec4<f32>( p7_nodeVar49 ) ) ) + ( p7_nodeVar50 * vec4<f32>( p7_nodeVar51 ) ) ) + ( p7_nodeVar52 * vec4<f32>( p7_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p7_nodeVar13 ) + p7_nodeVar17 ) + p7_nodeVar21 ) + p7_nodeVar25 ) + p7_nodeVar29 ) + p7_nodeVar33 ) + p7_nodeVar37 ) + p7_nodeVar41 ) + p7_nodeVar45 ) + p7_nodeVar49 ) + p7_nodeVar51 ) + p7_nodeVar53 ), 0.0001 ) ) );
	p7_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p7_DiffuseColor = vec4<f32>( mix( p7_nodeVar54.xyz, max( p7_nodeVar54, p7_nodeVar55 ).xyz, ( max( max( p7_nodeVar55.x, p7_nodeVar55.y ), p7_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p7_DiffuseColor.w = ( p7_DiffuseColor.w * f32(1.0) );
	p7_DiffuseColor.w = 1.0;
	p7_nodeVar56 = max( vec4<f32>( p7_DiffuseColor.xyz, p7_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p7_Output = p7_nodeVar56;

	// result

	p7_output.color = p7_nodeVar56;

	return p7_output;

}

// structs

struct p8_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p8_output : p8_OutputStruct;

// uniforms


// vars
var<private> p8_DiffuseColor : vec4<f32>;
var<private> p8_nodeVar0 : vec2<f32>;
var<private> p8_nodeVar1 : vec2<f32>;
var<private> p8_nodeVar2 : vec4<f32>;
var<private> p8_nodeVar3 : vec2<f32>;
var<private> p8_nodeVar4 : vec4<f32>;
var<private> p8_nodeVar5 : vec3<f32>;
var<private> p8_nodeVar6 : vec4<f32>;
var<private> p8_nodeVar7 : vec2<f32>;
var<private> p8_nodeVar8 : vec2<f32>;
var<private> p8_nodeVar9 : f32;
var<private> p8_nodeVar10 : f32;
var<private> p8_nodeVar11 : f32;
var<private> p8_nodeVar12 : vec4<f32>;
var<private> p8_nodeVar13 : f32;
var<private> p8_nodeVar14 : f32;
var<private> p8_nodeVar15 : f32;
var<private> p8_nodeVar16 : vec4<f32>;
var<private> p8_nodeVar17 : f32;
var<private> p8_nodeVar18 : f32;
var<private> p8_nodeVar19 : f32;
var<private> p8_nodeVar20 : vec4<f32>;
var<private> p8_nodeVar21 : f32;
var<private> p8_nodeVar22 : f32;
var<private> p8_nodeVar23 : f32;
var<private> p8_nodeVar24 : vec4<f32>;
var<private> p8_nodeVar25 : f32;
var<private> p8_nodeVar26 : f32;
var<private> p8_nodeVar27 : f32;
var<private> p8_nodeVar28 : vec4<f32>;
var<private> p8_nodeVar29 : f32;
var<private> p8_nodeVar30 : f32;
var<private> p8_nodeVar31 : f32;
var<private> p8_nodeVar32 : vec4<f32>;
var<private> p8_nodeVar33 : f32;
var<private> p8_nodeVar34 : f32;
var<private> p8_nodeVar35 : f32;
var<private> p8_nodeVar36 : vec4<f32>;
var<private> p8_nodeVar37 : f32;
var<private> p8_nodeVar38 : f32;
var<private> p8_nodeVar39 : f32;
var<private> p8_nodeVar40 : vec4<f32>;
var<private> p8_nodeVar41 : f32;
var<private> p8_nodeVar42 : f32;
var<private> p8_nodeVar43 : f32;
var<private> p8_nodeVar44 : vec4<f32>;
var<private> p8_nodeVar45 : f32;
var<private> p8_nodeVar46 : f32;
var<private> p8_nodeVar47 : f32;
var<private> p8_nodeVar48 : vec4<f32>;
var<private> p8_nodeVar49 : f32;
var<private> p8_nodeVar50 : vec4<f32>;
var<private> p8_nodeVar51 : f32;
var<private> p8_nodeVar52 : vec4<f32>;
var<private> p8_nodeVar53 : f32;
var<private> p8_nodeVar54 : vec4<f32>;
var<private> p8_nodeVar55 : vec4<f32>;
var<private> p8_Output : vec4<f32>;
var<private> p8_nodeVar56 : vec4<f32>;

// codes


fn p8_main(door_uv: vec2f) -> p8_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p8_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p8_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p8_nodeVar2 = picture_read( ( ( ( p8_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(7.0) * 0.1 ), ( f32(7.0) * 0.1 ) ) ) + p8_nodeVar1 ) );
	p8_nodeVar3 = vec2<f32>( ( ( p8_nodeVar0.x * 0.7071054825112363 ) - ( p8_nodeVar0.y * 0.7071080798594735 ) ), ( ( p8_nodeVar0.x * 0.7071080798594735 ) + ( p8_nodeVar0.y * 0.7071054825112363 ) ) );
	p8_nodeVar4 = picture_read( ( ( ( ( p8_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(7.0) * 0.15 ), ( f32(7.0) * 0.15 ) ) ) + ( p8_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p8_nodeVar5 = mix( p8_nodeVar2.xyz, p8_nodeVar4.xyz, 0.5 );
	p8_nodeVar6 = picture_read( ( ( ( p8_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p8_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p8_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p8_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p8_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p8_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p8_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p8_nodeVar9 = ( ( ( p8_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p8_nodeVar10 = ( p8_nodeVar9 * 1.0 );
	p8_nodeVar11 = ( ( p8_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar12 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar10 + p8_nodeVar11 ), ( ( p8_nodeVar10 + p8_nodeVar11 ) * 0.3 ) ) ) );
	p8_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p8_nodeVar14 = ( p8_nodeVar9 * 1.1 );
	p8_nodeVar15 = ( ( p8_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar16 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar14 + p8_nodeVar15 ), ( ( p8_nodeVar14 + p8_nodeVar15 ) * 0.3 ) ) ) );
	p8_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p8_nodeVar18 = ( p8_nodeVar9 * 1.2 );
	p8_nodeVar19 = ( ( p8_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar20 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar18 + p8_nodeVar19 ), ( ( p8_nodeVar18 + p8_nodeVar19 ) * 0.3 ) ) ) );
	p8_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p8_nodeVar22 = ( p8_nodeVar9 * 1.3 );
	p8_nodeVar23 = ( ( p8_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar24 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar22 + p8_nodeVar23 ), ( ( p8_nodeVar22 + p8_nodeVar23 ) * 0.3 ) ) ) );
	p8_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p8_nodeVar26 = ( p8_nodeVar9 * 1.4 );
	p8_nodeVar27 = ( ( p8_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar28 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar26 + p8_nodeVar27 ), ( ( p8_nodeVar26 + p8_nodeVar27 ) * 0.3 ) ) ) );
	p8_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p8_nodeVar30 = ( p8_nodeVar9 * 1.5 );
	p8_nodeVar31 = ( ( p8_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar32 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar30 + p8_nodeVar31 ), ( ( p8_nodeVar30 + p8_nodeVar31 ) * 0.3 ) ) ) );
	p8_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p8_nodeVar34 = ( p8_nodeVar9 * 1.6 );
	p8_nodeVar35 = ( ( p8_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar36 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar34 + p8_nodeVar35 ), ( ( p8_nodeVar34 + p8_nodeVar35 ) * 0.3 ) ) ) );
	p8_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p8_nodeVar38 = ( p8_nodeVar9 * 1.7000000000000002 );
	p8_nodeVar39 = ( ( p8_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar40 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar38 + p8_nodeVar39 ), ( ( p8_nodeVar38 + p8_nodeVar39 ) * 0.3 ) ) ) );
	p8_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p8_nodeVar42 = ( p8_nodeVar9 * 1.8 );
	p8_nodeVar43 = ( ( p8_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar44 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar42 + p8_nodeVar43 ), ( ( p8_nodeVar42 + p8_nodeVar43 ) * 0.3 ) ) ) );
	p8_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p8_nodeVar46 = ( p8_nodeVar9 * 1.9 );
	p8_nodeVar47 = ( ( p8_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p8_nodeVar48 = target_read( t0, t0_sampler, ( ( p8_nodeVar0 + ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(7.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p8_nodeVar46 + p8_nodeVar47 ), ( ( p8_nodeVar46 + p8_nodeVar47 ) * 0.3 ) ) ) );
	p8_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p8_nodeVar50 = target_read( t0, t0_sampler, ( p8_nodeVar0 - ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p8_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p8_nodeVar52 = target_read( t0, t0_sampler, ( p8_nodeVar0 - ( ( ( p8_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p8_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p8_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p8_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p8_nodeVar12 * vec4<f32>( p8_nodeVar13 ) ) ) + ( p8_nodeVar16 * vec4<f32>( p8_nodeVar17 ) ) ) + ( p8_nodeVar20 * vec4<f32>( p8_nodeVar21 ) ) ) + ( p8_nodeVar24 * vec4<f32>( p8_nodeVar25 ) ) ) + ( p8_nodeVar28 * vec4<f32>( p8_nodeVar29 ) ) ) + ( p8_nodeVar32 * vec4<f32>( p8_nodeVar33 ) ) ) + ( p8_nodeVar36 * vec4<f32>( p8_nodeVar37 ) ) ) + ( p8_nodeVar40 * vec4<f32>( p8_nodeVar41 ) ) ) + ( p8_nodeVar44 * vec4<f32>( p8_nodeVar45 ) ) ) + ( p8_nodeVar48 * vec4<f32>( p8_nodeVar49 ) ) ) + ( p8_nodeVar50 * vec4<f32>( p8_nodeVar51 ) ) ) + ( p8_nodeVar52 * vec4<f32>( p8_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p8_nodeVar13 ) + p8_nodeVar17 ) + p8_nodeVar21 ) + p8_nodeVar25 ) + p8_nodeVar29 ) + p8_nodeVar33 ) + p8_nodeVar37 ) + p8_nodeVar41 ) + p8_nodeVar45 ) + p8_nodeVar49 ) + p8_nodeVar51 ) + p8_nodeVar53 ), 0.0001 ) ) );
	p8_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p8_DiffuseColor = vec4<f32>( mix( p8_nodeVar54.xyz, max( p8_nodeVar54, p8_nodeVar55 ).xyz, ( max( max( p8_nodeVar55.x, p8_nodeVar55.y ), p8_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p8_DiffuseColor.w = ( p8_DiffuseColor.w * f32(1.0) );
	p8_DiffuseColor.w = 1.0;
	p8_nodeVar56 = max( vec4<f32>( p8_DiffuseColor.xyz, p8_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p8_Output = p8_nodeVar56;

	// result

	p8_output.color = p8_nodeVar56;

	return p8_output;

}

// structs

struct p9_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p9_output : p9_OutputStruct;

// uniforms


// vars
var<private> p9_DiffuseColor : vec4<f32>;
var<private> p9_nodeVar0 : vec2<f32>;
var<private> p9_nodeVar1 : vec2<f32>;
var<private> p9_nodeVar2 : vec4<f32>;
var<private> p9_nodeVar3 : vec2<f32>;
var<private> p9_nodeVar4 : vec4<f32>;
var<private> p9_nodeVar5 : vec3<f32>;
var<private> p9_nodeVar6 : vec4<f32>;
var<private> p9_nodeVar7 : vec2<f32>;
var<private> p9_nodeVar8 : vec2<f32>;
var<private> p9_nodeVar9 : f32;
var<private> p9_nodeVar10 : f32;
var<private> p9_nodeVar11 : f32;
var<private> p9_nodeVar12 : vec4<f32>;
var<private> p9_nodeVar13 : f32;
var<private> p9_nodeVar14 : f32;
var<private> p9_nodeVar15 : f32;
var<private> p9_nodeVar16 : vec4<f32>;
var<private> p9_nodeVar17 : f32;
var<private> p9_nodeVar18 : f32;
var<private> p9_nodeVar19 : f32;
var<private> p9_nodeVar20 : vec4<f32>;
var<private> p9_nodeVar21 : f32;
var<private> p9_nodeVar22 : f32;
var<private> p9_nodeVar23 : f32;
var<private> p9_nodeVar24 : vec4<f32>;
var<private> p9_nodeVar25 : f32;
var<private> p9_nodeVar26 : f32;
var<private> p9_nodeVar27 : f32;
var<private> p9_nodeVar28 : vec4<f32>;
var<private> p9_nodeVar29 : f32;
var<private> p9_nodeVar30 : f32;
var<private> p9_nodeVar31 : f32;
var<private> p9_nodeVar32 : vec4<f32>;
var<private> p9_nodeVar33 : f32;
var<private> p9_nodeVar34 : f32;
var<private> p9_nodeVar35 : f32;
var<private> p9_nodeVar36 : vec4<f32>;
var<private> p9_nodeVar37 : f32;
var<private> p9_nodeVar38 : f32;
var<private> p9_nodeVar39 : f32;
var<private> p9_nodeVar40 : vec4<f32>;
var<private> p9_nodeVar41 : f32;
var<private> p9_nodeVar42 : f32;
var<private> p9_nodeVar43 : f32;
var<private> p9_nodeVar44 : vec4<f32>;
var<private> p9_nodeVar45 : f32;
var<private> p9_nodeVar46 : f32;
var<private> p9_nodeVar47 : f32;
var<private> p9_nodeVar48 : vec4<f32>;
var<private> p9_nodeVar49 : f32;
var<private> p9_nodeVar50 : vec4<f32>;
var<private> p9_nodeVar51 : f32;
var<private> p9_nodeVar52 : vec4<f32>;
var<private> p9_nodeVar53 : f32;
var<private> p9_nodeVar54 : vec4<f32>;
var<private> p9_nodeVar55 : vec4<f32>;
var<private> p9_Output : vec4<f32>;
var<private> p9_nodeVar56 : vec4<f32>;

// codes


fn p9_main(door_uv: vec2f) -> p9_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p9_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p9_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p9_nodeVar2 = picture_read( ( ( ( p9_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(8.0) * 0.1 ), ( f32(8.0) * 0.1 ) ) ) + p9_nodeVar1 ) );
	p9_nodeVar3 = vec2<f32>( ( ( p9_nodeVar0.x * 0.7071054825112363 ) - ( p9_nodeVar0.y * 0.7071080798594735 ) ), ( ( p9_nodeVar0.x * 0.7071080798594735 ) + ( p9_nodeVar0.y * 0.7071054825112363 ) ) );
	p9_nodeVar4 = picture_read( ( ( ( ( p9_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(8.0) * 0.15 ), ( f32(8.0) * 0.15 ) ) ) + ( p9_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p9_nodeVar5 = mix( p9_nodeVar2.xyz, p9_nodeVar4.xyz, 0.5 );
	p9_nodeVar6 = picture_read( ( ( ( p9_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p9_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p9_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p9_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p9_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p9_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p9_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p9_nodeVar9 = ( ( ( p9_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p9_nodeVar10 = ( p9_nodeVar9 * 1.0 );
	p9_nodeVar11 = ( ( p9_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar12 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar10 + p9_nodeVar11 ), ( ( p9_nodeVar10 + p9_nodeVar11 ) * 0.3 ) ) ) );
	p9_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p9_nodeVar14 = ( p9_nodeVar9 * 1.1 );
	p9_nodeVar15 = ( ( p9_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar16 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar14 + p9_nodeVar15 ), ( ( p9_nodeVar14 + p9_nodeVar15 ) * 0.3 ) ) ) );
	p9_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p9_nodeVar18 = ( p9_nodeVar9 * 1.2 );
	p9_nodeVar19 = ( ( p9_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar20 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar18 + p9_nodeVar19 ), ( ( p9_nodeVar18 + p9_nodeVar19 ) * 0.3 ) ) ) );
	p9_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p9_nodeVar22 = ( p9_nodeVar9 * 1.3 );
	p9_nodeVar23 = ( ( p9_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar24 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar22 + p9_nodeVar23 ), ( ( p9_nodeVar22 + p9_nodeVar23 ) * 0.3 ) ) ) );
	p9_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p9_nodeVar26 = ( p9_nodeVar9 * 1.4 );
	p9_nodeVar27 = ( ( p9_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar28 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar26 + p9_nodeVar27 ), ( ( p9_nodeVar26 + p9_nodeVar27 ) * 0.3 ) ) ) );
	p9_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p9_nodeVar30 = ( p9_nodeVar9 * 1.5 );
	p9_nodeVar31 = ( ( p9_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar32 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar30 + p9_nodeVar31 ), ( ( p9_nodeVar30 + p9_nodeVar31 ) * 0.3 ) ) ) );
	p9_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p9_nodeVar34 = ( p9_nodeVar9 * 1.6 );
	p9_nodeVar35 = ( ( p9_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar36 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar34 + p9_nodeVar35 ), ( ( p9_nodeVar34 + p9_nodeVar35 ) * 0.3 ) ) ) );
	p9_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p9_nodeVar38 = ( p9_nodeVar9 * 1.7000000000000002 );
	p9_nodeVar39 = ( ( p9_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar40 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar38 + p9_nodeVar39 ), ( ( p9_nodeVar38 + p9_nodeVar39 ) * 0.3 ) ) ) );
	p9_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p9_nodeVar42 = ( p9_nodeVar9 * 1.8 );
	p9_nodeVar43 = ( ( p9_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar44 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar42 + p9_nodeVar43 ), ( ( p9_nodeVar42 + p9_nodeVar43 ) * 0.3 ) ) ) );
	p9_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p9_nodeVar46 = ( p9_nodeVar9 * 1.9 );
	p9_nodeVar47 = ( ( p9_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p9_nodeVar48 = target_read( t1, t1_sampler, ( ( p9_nodeVar0 + ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(8.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p9_nodeVar46 + p9_nodeVar47 ), ( ( p9_nodeVar46 + p9_nodeVar47 ) * 0.3 ) ) ) );
	p9_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p9_nodeVar50 = target_read( t1, t1_sampler, ( p9_nodeVar0 - ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p9_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p9_nodeVar52 = target_read( t1, t1_sampler, ( p9_nodeVar0 - ( ( ( p9_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p9_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p9_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p9_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p9_nodeVar12 * vec4<f32>( p9_nodeVar13 ) ) ) + ( p9_nodeVar16 * vec4<f32>( p9_nodeVar17 ) ) ) + ( p9_nodeVar20 * vec4<f32>( p9_nodeVar21 ) ) ) + ( p9_nodeVar24 * vec4<f32>( p9_nodeVar25 ) ) ) + ( p9_nodeVar28 * vec4<f32>( p9_nodeVar29 ) ) ) + ( p9_nodeVar32 * vec4<f32>( p9_nodeVar33 ) ) ) + ( p9_nodeVar36 * vec4<f32>( p9_nodeVar37 ) ) ) + ( p9_nodeVar40 * vec4<f32>( p9_nodeVar41 ) ) ) + ( p9_nodeVar44 * vec4<f32>( p9_nodeVar45 ) ) ) + ( p9_nodeVar48 * vec4<f32>( p9_nodeVar49 ) ) ) + ( p9_nodeVar50 * vec4<f32>( p9_nodeVar51 ) ) ) + ( p9_nodeVar52 * vec4<f32>( p9_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p9_nodeVar13 ) + p9_nodeVar17 ) + p9_nodeVar21 ) + p9_nodeVar25 ) + p9_nodeVar29 ) + p9_nodeVar33 ) + p9_nodeVar37 ) + p9_nodeVar41 ) + p9_nodeVar45 ) + p9_nodeVar49 ) + p9_nodeVar51 ) + p9_nodeVar53 ), 0.0001 ) ) );
	p9_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p9_DiffuseColor = vec4<f32>( mix( p9_nodeVar54.xyz, max( p9_nodeVar54, p9_nodeVar55 ).xyz, ( max( max( p9_nodeVar55.x, p9_nodeVar55.y ), p9_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p9_DiffuseColor.w = ( p9_DiffuseColor.w * f32(1.0) );
	p9_DiffuseColor.w = 1.0;
	p9_nodeVar56 = max( vec4<f32>( p9_DiffuseColor.xyz, p9_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p9_Output = p9_nodeVar56;

	// result

	p9_output.color = p9_nodeVar56;

	return p9_output;

}

// structs

struct p10_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p10_output : p10_OutputStruct;

// uniforms


// vars
var<private> p10_DiffuseColor : vec4<f32>;
var<private> p10_nodeVar0 : vec2<f32>;
var<private> p10_nodeVar1 : vec2<f32>;
var<private> p10_nodeVar2 : vec4<f32>;
var<private> p10_nodeVar3 : vec2<f32>;
var<private> p10_nodeVar4 : vec4<f32>;
var<private> p10_nodeVar5 : vec3<f32>;
var<private> p10_nodeVar6 : vec4<f32>;
var<private> p10_nodeVar7 : vec2<f32>;
var<private> p10_nodeVar8 : vec2<f32>;
var<private> p10_nodeVar9 : f32;
var<private> p10_nodeVar10 : f32;
var<private> p10_nodeVar11 : f32;
var<private> p10_nodeVar12 : vec4<f32>;
var<private> p10_nodeVar13 : f32;
var<private> p10_nodeVar14 : f32;
var<private> p10_nodeVar15 : f32;
var<private> p10_nodeVar16 : vec4<f32>;
var<private> p10_nodeVar17 : f32;
var<private> p10_nodeVar18 : f32;
var<private> p10_nodeVar19 : f32;
var<private> p10_nodeVar20 : vec4<f32>;
var<private> p10_nodeVar21 : f32;
var<private> p10_nodeVar22 : f32;
var<private> p10_nodeVar23 : f32;
var<private> p10_nodeVar24 : vec4<f32>;
var<private> p10_nodeVar25 : f32;
var<private> p10_nodeVar26 : f32;
var<private> p10_nodeVar27 : f32;
var<private> p10_nodeVar28 : vec4<f32>;
var<private> p10_nodeVar29 : f32;
var<private> p10_nodeVar30 : f32;
var<private> p10_nodeVar31 : f32;
var<private> p10_nodeVar32 : vec4<f32>;
var<private> p10_nodeVar33 : f32;
var<private> p10_nodeVar34 : f32;
var<private> p10_nodeVar35 : f32;
var<private> p10_nodeVar36 : vec4<f32>;
var<private> p10_nodeVar37 : f32;
var<private> p10_nodeVar38 : f32;
var<private> p10_nodeVar39 : f32;
var<private> p10_nodeVar40 : vec4<f32>;
var<private> p10_nodeVar41 : f32;
var<private> p10_nodeVar42 : f32;
var<private> p10_nodeVar43 : f32;
var<private> p10_nodeVar44 : vec4<f32>;
var<private> p10_nodeVar45 : f32;
var<private> p10_nodeVar46 : f32;
var<private> p10_nodeVar47 : f32;
var<private> p10_nodeVar48 : vec4<f32>;
var<private> p10_nodeVar49 : f32;
var<private> p10_nodeVar50 : vec4<f32>;
var<private> p10_nodeVar51 : f32;
var<private> p10_nodeVar52 : vec4<f32>;
var<private> p10_nodeVar53 : f32;
var<private> p10_nodeVar54 : vec4<f32>;
var<private> p10_nodeVar55 : vec4<f32>;
var<private> p10_Output : vec4<f32>;
var<private> p10_nodeVar56 : vec4<f32>;

// codes


fn p10_main(door_uv: vec2f) -> p10_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p10_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p10_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p10_nodeVar2 = picture_read( ( ( ( p10_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(9.0) * 0.1 ), ( f32(9.0) * 0.1 ) ) ) + p10_nodeVar1 ) );
	p10_nodeVar3 = vec2<f32>( ( ( p10_nodeVar0.x * 0.7071054825112363 ) - ( p10_nodeVar0.y * 0.7071080798594735 ) ), ( ( p10_nodeVar0.x * 0.7071080798594735 ) + ( p10_nodeVar0.y * 0.7071054825112363 ) ) );
	p10_nodeVar4 = picture_read( ( ( ( ( p10_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(9.0) * 0.15 ), ( f32(9.0) * 0.15 ) ) ) + ( p10_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p10_nodeVar5 = mix( p10_nodeVar2.xyz, p10_nodeVar4.xyz, 0.5 );
	p10_nodeVar6 = picture_read( ( ( ( p10_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p10_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p10_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p10_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p10_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p10_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p10_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p10_nodeVar9 = ( ( ( p10_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p10_nodeVar10 = ( p10_nodeVar9 * 1.0 );
	p10_nodeVar11 = ( ( p10_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar12 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar10 + p10_nodeVar11 ), ( ( p10_nodeVar10 + p10_nodeVar11 ) * 0.3 ) ) ) );
	p10_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p10_nodeVar14 = ( p10_nodeVar9 * 1.1 );
	p10_nodeVar15 = ( ( p10_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar16 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar14 + p10_nodeVar15 ), ( ( p10_nodeVar14 + p10_nodeVar15 ) * 0.3 ) ) ) );
	p10_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p10_nodeVar18 = ( p10_nodeVar9 * 1.2 );
	p10_nodeVar19 = ( ( p10_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar20 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar18 + p10_nodeVar19 ), ( ( p10_nodeVar18 + p10_nodeVar19 ) * 0.3 ) ) ) );
	p10_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p10_nodeVar22 = ( p10_nodeVar9 * 1.3 );
	p10_nodeVar23 = ( ( p10_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar24 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar22 + p10_nodeVar23 ), ( ( p10_nodeVar22 + p10_nodeVar23 ) * 0.3 ) ) ) );
	p10_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p10_nodeVar26 = ( p10_nodeVar9 * 1.4 );
	p10_nodeVar27 = ( ( p10_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar28 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar26 + p10_nodeVar27 ), ( ( p10_nodeVar26 + p10_nodeVar27 ) * 0.3 ) ) ) );
	p10_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p10_nodeVar30 = ( p10_nodeVar9 * 1.5 );
	p10_nodeVar31 = ( ( p10_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar32 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar30 + p10_nodeVar31 ), ( ( p10_nodeVar30 + p10_nodeVar31 ) * 0.3 ) ) ) );
	p10_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p10_nodeVar34 = ( p10_nodeVar9 * 1.6 );
	p10_nodeVar35 = ( ( p10_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar36 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar34 + p10_nodeVar35 ), ( ( p10_nodeVar34 + p10_nodeVar35 ) * 0.3 ) ) ) );
	p10_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p10_nodeVar38 = ( p10_nodeVar9 * 1.7000000000000002 );
	p10_nodeVar39 = ( ( p10_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar40 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar38 + p10_nodeVar39 ), ( ( p10_nodeVar38 + p10_nodeVar39 ) * 0.3 ) ) ) );
	p10_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p10_nodeVar42 = ( p10_nodeVar9 * 1.8 );
	p10_nodeVar43 = ( ( p10_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar44 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar42 + p10_nodeVar43 ), ( ( p10_nodeVar42 + p10_nodeVar43 ) * 0.3 ) ) ) );
	p10_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p10_nodeVar46 = ( p10_nodeVar9 * 1.9 );
	p10_nodeVar47 = ( ( p10_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p10_nodeVar48 = target_read( t0, t0_sampler, ( ( p10_nodeVar0 + ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(9.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p10_nodeVar46 + p10_nodeVar47 ), ( ( p10_nodeVar46 + p10_nodeVar47 ) * 0.3 ) ) ) );
	p10_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p10_nodeVar50 = target_read( t0, t0_sampler, ( p10_nodeVar0 - ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p10_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p10_nodeVar52 = target_read( t0, t0_sampler, ( p10_nodeVar0 - ( ( ( p10_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p10_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p10_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p10_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p10_nodeVar12 * vec4<f32>( p10_nodeVar13 ) ) ) + ( p10_nodeVar16 * vec4<f32>( p10_nodeVar17 ) ) ) + ( p10_nodeVar20 * vec4<f32>( p10_nodeVar21 ) ) ) + ( p10_nodeVar24 * vec4<f32>( p10_nodeVar25 ) ) ) + ( p10_nodeVar28 * vec4<f32>( p10_nodeVar29 ) ) ) + ( p10_nodeVar32 * vec4<f32>( p10_nodeVar33 ) ) ) + ( p10_nodeVar36 * vec4<f32>( p10_nodeVar37 ) ) ) + ( p10_nodeVar40 * vec4<f32>( p10_nodeVar41 ) ) ) + ( p10_nodeVar44 * vec4<f32>( p10_nodeVar45 ) ) ) + ( p10_nodeVar48 * vec4<f32>( p10_nodeVar49 ) ) ) + ( p10_nodeVar50 * vec4<f32>( p10_nodeVar51 ) ) ) + ( p10_nodeVar52 * vec4<f32>( p10_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p10_nodeVar13 ) + p10_nodeVar17 ) + p10_nodeVar21 ) + p10_nodeVar25 ) + p10_nodeVar29 ) + p10_nodeVar33 ) + p10_nodeVar37 ) + p10_nodeVar41 ) + p10_nodeVar45 ) + p10_nodeVar49 ) + p10_nodeVar51 ) + p10_nodeVar53 ), 0.0001 ) ) );
	p10_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p10_DiffuseColor = vec4<f32>( mix( p10_nodeVar54.xyz, max( p10_nodeVar54, p10_nodeVar55 ).xyz, ( max( max( p10_nodeVar55.x, p10_nodeVar55.y ), p10_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p10_DiffuseColor.w = ( p10_DiffuseColor.w * f32(1.0) );
	p10_DiffuseColor.w = 1.0;
	p10_nodeVar56 = max( vec4<f32>( p10_DiffuseColor.xyz, p10_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p10_Output = p10_nodeVar56;

	// result

	p10_output.color = p10_nodeVar56;

	return p10_output;

}

// structs

struct p11_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p11_output : p11_OutputStruct;

// uniforms


// vars
var<private> p11_DiffuseColor : vec4<f32>;
var<private> p11_nodeVar0 : vec2<f32>;
var<private> p11_nodeVar1 : vec2<f32>;
var<private> p11_nodeVar2 : vec4<f32>;
var<private> p11_nodeVar3 : vec2<f32>;
var<private> p11_nodeVar4 : vec4<f32>;
var<private> p11_nodeVar5 : vec3<f32>;
var<private> p11_nodeVar6 : vec4<f32>;
var<private> p11_nodeVar7 : vec2<f32>;
var<private> p11_nodeVar8 : vec2<f32>;
var<private> p11_nodeVar9 : f32;
var<private> p11_nodeVar10 : f32;
var<private> p11_nodeVar11 : f32;
var<private> p11_nodeVar12 : vec4<f32>;
var<private> p11_nodeVar13 : f32;
var<private> p11_nodeVar14 : f32;
var<private> p11_nodeVar15 : f32;
var<private> p11_nodeVar16 : vec4<f32>;
var<private> p11_nodeVar17 : f32;
var<private> p11_nodeVar18 : f32;
var<private> p11_nodeVar19 : f32;
var<private> p11_nodeVar20 : vec4<f32>;
var<private> p11_nodeVar21 : f32;
var<private> p11_nodeVar22 : f32;
var<private> p11_nodeVar23 : f32;
var<private> p11_nodeVar24 : vec4<f32>;
var<private> p11_nodeVar25 : f32;
var<private> p11_nodeVar26 : f32;
var<private> p11_nodeVar27 : f32;
var<private> p11_nodeVar28 : vec4<f32>;
var<private> p11_nodeVar29 : f32;
var<private> p11_nodeVar30 : f32;
var<private> p11_nodeVar31 : f32;
var<private> p11_nodeVar32 : vec4<f32>;
var<private> p11_nodeVar33 : f32;
var<private> p11_nodeVar34 : f32;
var<private> p11_nodeVar35 : f32;
var<private> p11_nodeVar36 : vec4<f32>;
var<private> p11_nodeVar37 : f32;
var<private> p11_nodeVar38 : f32;
var<private> p11_nodeVar39 : f32;
var<private> p11_nodeVar40 : vec4<f32>;
var<private> p11_nodeVar41 : f32;
var<private> p11_nodeVar42 : f32;
var<private> p11_nodeVar43 : f32;
var<private> p11_nodeVar44 : vec4<f32>;
var<private> p11_nodeVar45 : f32;
var<private> p11_nodeVar46 : f32;
var<private> p11_nodeVar47 : f32;
var<private> p11_nodeVar48 : vec4<f32>;
var<private> p11_nodeVar49 : f32;
var<private> p11_nodeVar50 : vec4<f32>;
var<private> p11_nodeVar51 : f32;
var<private> p11_nodeVar52 : vec4<f32>;
var<private> p11_nodeVar53 : f32;
var<private> p11_nodeVar54 : vec4<f32>;
var<private> p11_nodeVar55 : vec4<f32>;
var<private> p11_Output : vec4<f32>;
var<private> p11_nodeVar56 : vec4<f32>;

// codes


fn p11_main(door_uv: vec2f) -> p11_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p11_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p11_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p11_nodeVar2 = picture_read( ( ( ( p11_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(10.0) * 0.1 ), ( f32(10.0) * 0.1 ) ) ) + p11_nodeVar1 ) );
	p11_nodeVar3 = vec2<f32>( ( ( p11_nodeVar0.x * 0.7071054825112363 ) - ( p11_nodeVar0.y * 0.7071080798594735 ) ), ( ( p11_nodeVar0.x * 0.7071080798594735 ) + ( p11_nodeVar0.y * 0.7071054825112363 ) ) );
	p11_nodeVar4 = picture_read( ( ( ( ( p11_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(10.0) * 0.15 ), ( f32(10.0) * 0.15 ) ) ) + ( p11_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p11_nodeVar5 = mix( p11_nodeVar2.xyz, p11_nodeVar4.xyz, 0.5 );
	p11_nodeVar6 = picture_read( ( ( ( p11_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p11_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p11_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p11_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p11_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p11_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p11_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p11_nodeVar9 = ( ( ( p11_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p11_nodeVar10 = ( p11_nodeVar9 * 1.0 );
	p11_nodeVar11 = ( ( p11_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar12 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar10 + p11_nodeVar11 ), ( ( p11_nodeVar10 + p11_nodeVar11 ) * 0.3 ) ) ) );
	p11_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p11_nodeVar14 = ( p11_nodeVar9 * 1.1 );
	p11_nodeVar15 = ( ( p11_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar16 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar14 + p11_nodeVar15 ), ( ( p11_nodeVar14 + p11_nodeVar15 ) * 0.3 ) ) ) );
	p11_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p11_nodeVar18 = ( p11_nodeVar9 * 1.2 );
	p11_nodeVar19 = ( ( p11_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar20 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar18 + p11_nodeVar19 ), ( ( p11_nodeVar18 + p11_nodeVar19 ) * 0.3 ) ) ) );
	p11_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p11_nodeVar22 = ( p11_nodeVar9 * 1.3 );
	p11_nodeVar23 = ( ( p11_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar24 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar22 + p11_nodeVar23 ), ( ( p11_nodeVar22 + p11_nodeVar23 ) * 0.3 ) ) ) );
	p11_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p11_nodeVar26 = ( p11_nodeVar9 * 1.4 );
	p11_nodeVar27 = ( ( p11_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar28 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar26 + p11_nodeVar27 ), ( ( p11_nodeVar26 + p11_nodeVar27 ) * 0.3 ) ) ) );
	p11_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p11_nodeVar30 = ( p11_nodeVar9 * 1.5 );
	p11_nodeVar31 = ( ( p11_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar32 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar30 + p11_nodeVar31 ), ( ( p11_nodeVar30 + p11_nodeVar31 ) * 0.3 ) ) ) );
	p11_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p11_nodeVar34 = ( p11_nodeVar9 * 1.6 );
	p11_nodeVar35 = ( ( p11_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar36 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar34 + p11_nodeVar35 ), ( ( p11_nodeVar34 + p11_nodeVar35 ) * 0.3 ) ) ) );
	p11_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p11_nodeVar38 = ( p11_nodeVar9 * 1.7000000000000002 );
	p11_nodeVar39 = ( ( p11_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar40 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar38 + p11_nodeVar39 ), ( ( p11_nodeVar38 + p11_nodeVar39 ) * 0.3 ) ) ) );
	p11_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p11_nodeVar42 = ( p11_nodeVar9 * 1.8 );
	p11_nodeVar43 = ( ( p11_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar44 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar42 + p11_nodeVar43 ), ( ( p11_nodeVar42 + p11_nodeVar43 ) * 0.3 ) ) ) );
	p11_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p11_nodeVar46 = ( p11_nodeVar9 * 1.9 );
	p11_nodeVar47 = ( ( p11_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p11_nodeVar48 = target_read( t1, t1_sampler, ( ( p11_nodeVar0 + ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(10.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p11_nodeVar46 + p11_nodeVar47 ), ( ( p11_nodeVar46 + p11_nodeVar47 ) * 0.3 ) ) ) );
	p11_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p11_nodeVar50 = target_read( t1, t1_sampler, ( p11_nodeVar0 - ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p11_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p11_nodeVar52 = target_read( t1, t1_sampler, ( p11_nodeVar0 - ( ( ( p11_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p11_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p11_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p11_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p11_nodeVar12 * vec4<f32>( p11_nodeVar13 ) ) ) + ( p11_nodeVar16 * vec4<f32>( p11_nodeVar17 ) ) ) + ( p11_nodeVar20 * vec4<f32>( p11_nodeVar21 ) ) ) + ( p11_nodeVar24 * vec4<f32>( p11_nodeVar25 ) ) ) + ( p11_nodeVar28 * vec4<f32>( p11_nodeVar29 ) ) ) + ( p11_nodeVar32 * vec4<f32>( p11_nodeVar33 ) ) ) + ( p11_nodeVar36 * vec4<f32>( p11_nodeVar37 ) ) ) + ( p11_nodeVar40 * vec4<f32>( p11_nodeVar41 ) ) ) + ( p11_nodeVar44 * vec4<f32>( p11_nodeVar45 ) ) ) + ( p11_nodeVar48 * vec4<f32>( p11_nodeVar49 ) ) ) + ( p11_nodeVar50 * vec4<f32>( p11_nodeVar51 ) ) ) + ( p11_nodeVar52 * vec4<f32>( p11_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p11_nodeVar13 ) + p11_nodeVar17 ) + p11_nodeVar21 ) + p11_nodeVar25 ) + p11_nodeVar29 ) + p11_nodeVar33 ) + p11_nodeVar37 ) + p11_nodeVar41 ) + p11_nodeVar45 ) + p11_nodeVar49 ) + p11_nodeVar51 ) + p11_nodeVar53 ), 0.0001 ) ) );
	p11_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p11_DiffuseColor = vec4<f32>( mix( p11_nodeVar54.xyz, max( p11_nodeVar54, p11_nodeVar55 ).xyz, ( max( max( p11_nodeVar55.x, p11_nodeVar55.y ), p11_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p11_DiffuseColor.w = ( p11_DiffuseColor.w * f32(1.0) );
	p11_DiffuseColor.w = 1.0;
	p11_nodeVar56 = max( vec4<f32>( p11_DiffuseColor.xyz, p11_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p11_Output = p11_nodeVar56;

	// result

	p11_output.color = p11_nodeVar56;

	return p11_output;

}

// structs

struct p12_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p12_output : p12_OutputStruct;

// uniforms


// vars
var<private> p12_DiffuseColor : vec4<f32>;
var<private> p12_nodeVar0 : vec2<f32>;
var<private> p12_nodeVar1 : vec2<f32>;
var<private> p12_nodeVar2 : vec4<f32>;
var<private> p12_nodeVar3 : vec2<f32>;
var<private> p12_nodeVar4 : vec4<f32>;
var<private> p12_nodeVar5 : vec3<f32>;
var<private> p12_nodeVar6 : vec4<f32>;
var<private> p12_nodeVar7 : vec2<f32>;
var<private> p12_nodeVar8 : vec2<f32>;
var<private> p12_nodeVar9 : f32;
var<private> p12_nodeVar10 : f32;
var<private> p12_nodeVar11 : f32;
var<private> p12_nodeVar12 : vec4<f32>;
var<private> p12_nodeVar13 : f32;
var<private> p12_nodeVar14 : f32;
var<private> p12_nodeVar15 : f32;
var<private> p12_nodeVar16 : vec4<f32>;
var<private> p12_nodeVar17 : f32;
var<private> p12_nodeVar18 : f32;
var<private> p12_nodeVar19 : f32;
var<private> p12_nodeVar20 : vec4<f32>;
var<private> p12_nodeVar21 : f32;
var<private> p12_nodeVar22 : f32;
var<private> p12_nodeVar23 : f32;
var<private> p12_nodeVar24 : vec4<f32>;
var<private> p12_nodeVar25 : f32;
var<private> p12_nodeVar26 : f32;
var<private> p12_nodeVar27 : f32;
var<private> p12_nodeVar28 : vec4<f32>;
var<private> p12_nodeVar29 : f32;
var<private> p12_nodeVar30 : f32;
var<private> p12_nodeVar31 : f32;
var<private> p12_nodeVar32 : vec4<f32>;
var<private> p12_nodeVar33 : f32;
var<private> p12_nodeVar34 : f32;
var<private> p12_nodeVar35 : f32;
var<private> p12_nodeVar36 : vec4<f32>;
var<private> p12_nodeVar37 : f32;
var<private> p12_nodeVar38 : f32;
var<private> p12_nodeVar39 : f32;
var<private> p12_nodeVar40 : vec4<f32>;
var<private> p12_nodeVar41 : f32;
var<private> p12_nodeVar42 : f32;
var<private> p12_nodeVar43 : f32;
var<private> p12_nodeVar44 : vec4<f32>;
var<private> p12_nodeVar45 : f32;
var<private> p12_nodeVar46 : f32;
var<private> p12_nodeVar47 : f32;
var<private> p12_nodeVar48 : vec4<f32>;
var<private> p12_nodeVar49 : f32;
var<private> p12_nodeVar50 : vec4<f32>;
var<private> p12_nodeVar51 : f32;
var<private> p12_nodeVar52 : vec4<f32>;
var<private> p12_nodeVar53 : f32;
var<private> p12_nodeVar54 : vec4<f32>;
var<private> p12_nodeVar55 : vec4<f32>;
var<private> p12_Output : vec4<f32>;
var<private> p12_nodeVar56 : vec4<f32>;

// codes


fn p12_main(door_uv: vec2f) -> p12_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p12_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p12_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p12_nodeVar2 = picture_read( ( ( ( p12_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(11.0) * 0.1 ), ( f32(11.0) * 0.1 ) ) ) + p12_nodeVar1 ) );
	p12_nodeVar3 = vec2<f32>( ( ( p12_nodeVar0.x * 0.7071054825112363 ) - ( p12_nodeVar0.y * 0.7071080798594735 ) ), ( ( p12_nodeVar0.x * 0.7071080798594735 ) + ( p12_nodeVar0.y * 0.7071054825112363 ) ) );
	p12_nodeVar4 = picture_read( ( ( ( ( p12_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(11.0) * 0.15 ), ( f32(11.0) * 0.15 ) ) ) + ( p12_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p12_nodeVar5 = mix( p12_nodeVar2.xyz, p12_nodeVar4.xyz, 0.5 );
	p12_nodeVar6 = picture_read( ( ( ( p12_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p12_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p12_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p12_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p12_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p12_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p12_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p12_nodeVar9 = ( ( ( p12_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p12_nodeVar10 = ( p12_nodeVar9 * 1.0 );
	p12_nodeVar11 = ( ( p12_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar12 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar10 + p12_nodeVar11 ), ( ( p12_nodeVar10 + p12_nodeVar11 ) * 0.3 ) ) ) );
	p12_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p12_nodeVar14 = ( p12_nodeVar9 * 1.1 );
	p12_nodeVar15 = ( ( p12_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar16 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar14 + p12_nodeVar15 ), ( ( p12_nodeVar14 + p12_nodeVar15 ) * 0.3 ) ) ) );
	p12_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p12_nodeVar18 = ( p12_nodeVar9 * 1.2 );
	p12_nodeVar19 = ( ( p12_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar20 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar18 + p12_nodeVar19 ), ( ( p12_nodeVar18 + p12_nodeVar19 ) * 0.3 ) ) ) );
	p12_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p12_nodeVar22 = ( p12_nodeVar9 * 1.3 );
	p12_nodeVar23 = ( ( p12_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar24 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar22 + p12_nodeVar23 ), ( ( p12_nodeVar22 + p12_nodeVar23 ) * 0.3 ) ) ) );
	p12_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p12_nodeVar26 = ( p12_nodeVar9 * 1.4 );
	p12_nodeVar27 = ( ( p12_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar28 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar26 + p12_nodeVar27 ), ( ( p12_nodeVar26 + p12_nodeVar27 ) * 0.3 ) ) ) );
	p12_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p12_nodeVar30 = ( p12_nodeVar9 * 1.5 );
	p12_nodeVar31 = ( ( p12_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar32 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar30 + p12_nodeVar31 ), ( ( p12_nodeVar30 + p12_nodeVar31 ) * 0.3 ) ) ) );
	p12_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p12_nodeVar34 = ( p12_nodeVar9 * 1.6 );
	p12_nodeVar35 = ( ( p12_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar36 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar34 + p12_nodeVar35 ), ( ( p12_nodeVar34 + p12_nodeVar35 ) * 0.3 ) ) ) );
	p12_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p12_nodeVar38 = ( p12_nodeVar9 * 1.7000000000000002 );
	p12_nodeVar39 = ( ( p12_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar40 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar38 + p12_nodeVar39 ), ( ( p12_nodeVar38 + p12_nodeVar39 ) * 0.3 ) ) ) );
	p12_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p12_nodeVar42 = ( p12_nodeVar9 * 1.8 );
	p12_nodeVar43 = ( ( p12_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar44 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar42 + p12_nodeVar43 ), ( ( p12_nodeVar42 + p12_nodeVar43 ) * 0.3 ) ) ) );
	p12_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p12_nodeVar46 = ( p12_nodeVar9 * 1.9 );
	p12_nodeVar47 = ( ( p12_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p12_nodeVar48 = target_read( t0, t0_sampler, ( ( p12_nodeVar0 + ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(11.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p12_nodeVar46 + p12_nodeVar47 ), ( ( p12_nodeVar46 + p12_nodeVar47 ) * 0.3 ) ) ) );
	p12_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p12_nodeVar50 = target_read( t0, t0_sampler, ( p12_nodeVar0 - ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p12_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p12_nodeVar52 = target_read( t0, t0_sampler, ( p12_nodeVar0 - ( ( ( p12_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p12_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p12_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p12_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p12_nodeVar12 * vec4<f32>( p12_nodeVar13 ) ) ) + ( p12_nodeVar16 * vec4<f32>( p12_nodeVar17 ) ) ) + ( p12_nodeVar20 * vec4<f32>( p12_nodeVar21 ) ) ) + ( p12_nodeVar24 * vec4<f32>( p12_nodeVar25 ) ) ) + ( p12_nodeVar28 * vec4<f32>( p12_nodeVar29 ) ) ) + ( p12_nodeVar32 * vec4<f32>( p12_nodeVar33 ) ) ) + ( p12_nodeVar36 * vec4<f32>( p12_nodeVar37 ) ) ) + ( p12_nodeVar40 * vec4<f32>( p12_nodeVar41 ) ) ) + ( p12_nodeVar44 * vec4<f32>( p12_nodeVar45 ) ) ) + ( p12_nodeVar48 * vec4<f32>( p12_nodeVar49 ) ) ) + ( p12_nodeVar50 * vec4<f32>( p12_nodeVar51 ) ) ) + ( p12_nodeVar52 * vec4<f32>( p12_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p12_nodeVar13 ) + p12_nodeVar17 ) + p12_nodeVar21 ) + p12_nodeVar25 ) + p12_nodeVar29 ) + p12_nodeVar33 ) + p12_nodeVar37 ) + p12_nodeVar41 ) + p12_nodeVar45 ) + p12_nodeVar49 ) + p12_nodeVar51 ) + p12_nodeVar53 ), 0.0001 ) ) );
	p12_nodeVar55 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p12_DiffuseColor = vec4<f32>( mix( p12_nodeVar54.xyz, max( p12_nodeVar54, p12_nodeVar55 ).xyz, ( max( max( p12_nodeVar55.x, p12_nodeVar55.y ), p12_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p12_DiffuseColor.w = ( p12_DiffuseColor.w * f32(1.0) );
	p12_DiffuseColor.w = 1.0;
	p12_nodeVar56 = max( vec4<f32>( p12_DiffuseColor.xyz, p12_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p12_Output = p12_nodeVar56;

	// result

	p12_output.color = p12_nodeVar56;

	return p12_output;

}

// structs

struct p13_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p13_output : p13_OutputStruct;

// uniforms


// vars
var<private> p13_DiffuseColor : vec4<f32>;
var<private> p13_nodeVar0 : vec2<f32>;
var<private> p13_nodeVar1 : vec2<f32>;
var<private> p13_nodeVar2 : vec4<f32>;
var<private> p13_nodeVar3 : vec2<f32>;
var<private> p13_nodeVar4 : vec4<f32>;
var<private> p13_nodeVar5 : vec3<f32>;
var<private> p13_nodeVar6 : vec4<f32>;
var<private> p13_nodeVar7 : vec2<f32>;
var<private> p13_nodeVar8 : vec2<f32>;
var<private> p13_nodeVar9 : f32;
var<private> p13_nodeVar10 : f32;
var<private> p13_nodeVar11 : f32;
var<private> p13_nodeVar12 : vec4<f32>;
var<private> p13_nodeVar13 : f32;
var<private> p13_nodeVar14 : f32;
var<private> p13_nodeVar15 : f32;
var<private> p13_nodeVar16 : vec4<f32>;
var<private> p13_nodeVar17 : f32;
var<private> p13_nodeVar18 : f32;
var<private> p13_nodeVar19 : f32;
var<private> p13_nodeVar20 : vec4<f32>;
var<private> p13_nodeVar21 : f32;
var<private> p13_nodeVar22 : f32;
var<private> p13_nodeVar23 : f32;
var<private> p13_nodeVar24 : vec4<f32>;
var<private> p13_nodeVar25 : f32;
var<private> p13_nodeVar26 : f32;
var<private> p13_nodeVar27 : f32;
var<private> p13_nodeVar28 : vec4<f32>;
var<private> p13_nodeVar29 : f32;
var<private> p13_nodeVar30 : f32;
var<private> p13_nodeVar31 : f32;
var<private> p13_nodeVar32 : vec4<f32>;
var<private> p13_nodeVar33 : f32;
var<private> p13_nodeVar34 : f32;
var<private> p13_nodeVar35 : f32;
var<private> p13_nodeVar36 : vec4<f32>;
var<private> p13_nodeVar37 : f32;
var<private> p13_nodeVar38 : f32;
var<private> p13_nodeVar39 : f32;
var<private> p13_nodeVar40 : vec4<f32>;
var<private> p13_nodeVar41 : f32;
var<private> p13_nodeVar42 : f32;
var<private> p13_nodeVar43 : f32;
var<private> p13_nodeVar44 : vec4<f32>;
var<private> p13_nodeVar45 : f32;
var<private> p13_nodeVar46 : f32;
var<private> p13_nodeVar47 : f32;
var<private> p13_nodeVar48 : vec4<f32>;
var<private> p13_nodeVar49 : f32;
var<private> p13_nodeVar50 : vec4<f32>;
var<private> p13_nodeVar51 : f32;
var<private> p13_nodeVar52 : vec4<f32>;
var<private> p13_nodeVar53 : f32;
var<private> p13_nodeVar54 : vec4<f32>;
var<private> p13_nodeVar55 : vec4<f32>;
var<private> p13_Output : vec4<f32>;
var<private> p13_nodeVar56 : vec4<f32>;

// codes


fn p13_main(door_uv: vec2f) -> p13_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p13_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p13_nodeVar1 = vec2<f32>( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.3 ), ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.15 ) );
	p13_nodeVar2 = picture_read( ( ( ( p13_nodeVar0 * vec2<f32>( f32(knobs.noiseScale) ) ) + vec2<f32>( ( f32(12.0) * 0.1 ), ( f32(12.0) * 0.1 ) ) ) + p13_nodeVar1 ) );
	p13_nodeVar3 = vec2<f32>( ( ( p13_nodeVar0.x * 0.7071054825112363 ) - ( p13_nodeVar0.y * 0.7071080798594735 ) ), ( ( p13_nodeVar0.x * 0.7071080798594735 ) + ( p13_nodeVar0.y * 0.7071054825112363 ) ) );
	p13_nodeVar4 = picture_read( ( ( ( ( p13_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.8 ) ) + vec2<f32>( ( f32(12.0) * 0.15 ), ( f32(12.0) * 0.15 ) ) ) + ( p13_nodeVar1 * vec2<f32>( 1.2 ) ) ) );
	p13_nodeVar5 = mix( p13_nodeVar2.xyz, p13_nodeVar4.xyz, 0.5 );
	p13_nodeVar6 = picture_read( ( ( ( p13_nodeVar3 * vec2<f32>( f32(knobs.noiseScale) ) ) * vec2<f32>( 0.6 ) ) + ( vec2<f32>( ( sin( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.7 ) ) * 0.1 ), ( sin( ( ( ( f32((1 * knobs.time + -1)) * f32(knobs.smokeSpeed) ) * 0.5 ) + 1.5707963 ) ) * 0.08 ) ) * vec2<f32>( 2.0 ) ) ) );
	p13_nodeVar7 = normalize( vec2<f32>( ( f32(6.123233995736766e-17) + ( ( ( ( p13_nodeVar5.x - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) + ( ( p13_nodeVar6.x - 0.5 ) * f32(knobs.smokeTurbulence) ) ) ), ( f32((0.011111111111111112 * knobs.blurDirection + 0)) + ( ( ( ( ( p13_nodeVar5.y - 0.5 ) * 2.0 ) * f32(knobs.fluidNoise) ) * 0.4 ) + ( ( ( p13_nodeVar6.y - 0.5 ) * f32(knobs.smokeTurbulence) ) * 0.5 ) ) ) ) );
	p13_nodeVar8 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
	p13_nodeVar9 = ( ( ( p13_nodeVar5.z - 0.5 ) * 0.03 ) * f32(knobs.fluidNoise) );
	p13_nodeVar10 = ( p13_nodeVar9 * 1.0 );
	p13_nodeVar11 = ( ( p13_nodeVar10 * 0.0 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar12 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.0 ) * 0.0 ) + ( 0.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar10 + p13_nodeVar11 ), ( ( p13_nodeVar10 + p13_nodeVar11 ) * 0.3 ) ) ) );
	p13_nodeVar13 = mix( ( 1.0 - 0.0 ), 1.0, smoothstep( 0.35, 0.0, 0.0 ) );
	p13_nodeVar14 = ( p13_nodeVar9 * 1.1 );
	p13_nodeVar15 = ( ( p13_nodeVar14 * 0.1111111111111111 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar16 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.1111111111111111 ) * 0.1111111111111111 ) + ( 0.1111111111111111 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar14 + p13_nodeVar15 ), ( ( p13_nodeVar14 + p13_nodeVar15 ) * 0.3 ) ) ) );
	p13_nodeVar17 = mix( ( 1.0 - 0.1111111111111111 ), 1.0, smoothstep( 0.35, 0.0, 0.1111111111111111 ) );
	p13_nodeVar18 = ( p13_nodeVar9 * 1.2 );
	p13_nodeVar19 = ( ( p13_nodeVar18 * 0.2222222222222222 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar20 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.2222222222222222 ) * 0.2222222222222222 ) + ( 0.2222222222222222 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar18 + p13_nodeVar19 ), ( ( p13_nodeVar18 + p13_nodeVar19 ) * 0.3 ) ) ) );
	p13_nodeVar21 = mix( ( 1.0 - 0.2222222222222222 ), 1.0, smoothstep( 0.35, 0.0, 0.2222222222222222 ) );
	p13_nodeVar22 = ( p13_nodeVar9 * 1.3 );
	p13_nodeVar23 = ( ( p13_nodeVar22 * 0.3333333333333333 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar24 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.3333333333333333 ) * 0.3333333333333333 ) + ( 0.3333333333333333 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar22 + p13_nodeVar23 ), ( ( p13_nodeVar22 + p13_nodeVar23 ) * 0.3 ) ) ) );
	p13_nodeVar25 = mix( ( 1.0 - 0.3333333333333333 ), 1.0, smoothstep( 0.35, 0.0, 0.3333333333333333 ) );
	p13_nodeVar26 = ( p13_nodeVar9 * 1.4 );
	p13_nodeVar27 = ( ( p13_nodeVar26 * 0.4444444444444444 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar28 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.4444444444444444 ) * 0.4444444444444444 ) + ( 0.4444444444444444 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar26 + p13_nodeVar27 ), ( ( p13_nodeVar26 + p13_nodeVar27 ) * 0.3 ) ) ) );
	p13_nodeVar29 = mix( ( 1.0 - 0.4444444444444444 ), 1.0, smoothstep( 0.35, 0.0, 0.4444444444444444 ) );
	p13_nodeVar30 = ( p13_nodeVar9 * 1.5 );
	p13_nodeVar31 = ( ( p13_nodeVar30 * 0.5555555555555556 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar32 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.5555555555555556 ) * 0.5555555555555556 ) + ( 0.5555555555555556 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar30 + p13_nodeVar31 ), ( ( p13_nodeVar30 + p13_nodeVar31 ) * 0.3 ) ) ) );
	p13_nodeVar33 = mix( ( 1.0 - 0.5555555555555556 ), 1.0, smoothstep( 0.35, 0.0, 0.5555555555555556 ) );
	p13_nodeVar34 = ( p13_nodeVar9 * 1.6 );
	p13_nodeVar35 = ( ( p13_nodeVar34 * 0.6666666666666666 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar36 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.6666666666666666 ) * 0.6666666666666666 ) + ( 0.6666666666666666 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar34 + p13_nodeVar35 ), ( ( p13_nodeVar34 + p13_nodeVar35 ) * 0.3 ) ) ) );
	p13_nodeVar37 = mix( ( 1.0 - 0.6666666666666666 ), 1.0, smoothstep( 0.35, 0.0, 0.6666666666666666 ) );
	p13_nodeVar38 = ( p13_nodeVar9 * 1.7000000000000002 );
	p13_nodeVar39 = ( ( p13_nodeVar38 * 0.7777777777777778 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar40 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.7777777777777778 ) * 0.7777777777777778 ) + ( 0.7777777777777778 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar38 + p13_nodeVar39 ), ( ( p13_nodeVar38 + p13_nodeVar39 ) * 0.3 ) ) ) );
	p13_nodeVar41 = mix( ( 1.0 - 0.7777777777777778 ), 1.0, smoothstep( 0.35, 0.0, 0.7777777777777778 ) );
	p13_nodeVar42 = ( p13_nodeVar9 * 1.8 );
	p13_nodeVar43 = ( ( p13_nodeVar42 * 0.8888888888888888 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar44 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 0.8888888888888888 ) * 0.8888888888888888 ) + ( 0.8888888888888888 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar42 + p13_nodeVar43 ), ( ( p13_nodeVar42 + p13_nodeVar43 ) * 0.3 ) ) ) );
	p13_nodeVar45 = mix( ( 1.0 - 0.8888888888888888 ), 1.0, smoothstep( 0.35, 0.0, 0.8888888888888888 ) );
	p13_nodeVar46 = ( p13_nodeVar9 * 1.9 );
	p13_nodeVar47 = ( ( p13_nodeVar46 * 1.0 ) * f32(knobs.smokeTurbulence) );
	p13_nodeVar48 = target_read( t1, t1_sampler, ( ( p13_nodeVar0 + ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( ( ( smoothstep( 0.0, 1.0, 1.0 ) * 1.0 ) + ( 1.0 * 0.5 ) ) * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * ( 1.0 + ( ( f32(12.0) * f32(knobs.blurSpread) ) * 0.15 ) ) ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) + vec2<f32>( ( p13_nodeVar46 + p13_nodeVar47 ), ( ( p13_nodeVar46 + p13_nodeVar47 ) * 0.3 ) ) ) );
	p13_nodeVar49 = mix( ( 1.0 - 1.0 ), 1.0, smoothstep( 0.35, 0.0, 1.0 ) );
	p13_nodeVar50 = target_read( t1, t1_sampler, ( p13_nodeVar0 - ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( 0.3333333333333333 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p13_nodeVar51 = ( ( 1.0 - 0.3333333333333333 ) * 0.4 );
	p13_nodeVar52 = target_read( t1, t1_sampler, ( p13_nodeVar0 - ( ( ( p13_nodeVar7 * vec2<f32>( ( ( ( 0.6666666666666666 * f32(knobs.dripLength) ) * f32(knobs.blurStrength) ) * 0.2 ) ) ) * p13_nodeVar8 ) * vec2<f32>( 100.0 ) ) ) );
	p13_nodeVar53 = ( ( 1.0 - 0.6666666666666666 ) * 0.4 );
	p13_nodeVar54 = ( ( ( ( ( ( ( ( ( ( ( ( ( vec4<f32>( 0.0, 0.0, 0.0, 0.0 ) + ( p13_nodeVar12 * vec4<f32>( p13_nodeVar13 ) ) ) + ( p13_nodeVar16 * vec4<f32>( p13_nodeVar17 ) ) ) + ( p13_nodeVar20 * vec4<f32>( p13_nodeVar21 ) ) ) + ( p13_nodeVar24 * vec4<f32>( p13_nodeVar25 ) ) ) + ( p13_nodeVar28 * vec4<f32>( p13_nodeVar29 ) ) ) + ( p13_nodeVar32 * vec4<f32>( p13_nodeVar33 ) ) ) + ( p13_nodeVar36 * vec4<f32>( p13_nodeVar37 ) ) ) + ( p13_nodeVar40 * vec4<f32>( p13_nodeVar41 ) ) ) + ( p13_nodeVar44 * vec4<f32>( p13_nodeVar45 ) ) ) + ( p13_nodeVar48 * vec4<f32>( p13_nodeVar49 ) ) ) + ( p13_nodeVar50 * vec4<f32>( p13_nodeVar51 ) ) ) + ( p13_nodeVar52 * vec4<f32>( p13_nodeVar53 ) ) ) / vec4<f32>( max( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + p13_nodeVar13 ) + p13_nodeVar17 ) + p13_nodeVar21 ) + p13_nodeVar25 ) + p13_nodeVar29 ) + p13_nodeVar33 ) + p13_nodeVar37 ) + p13_nodeVar41 ) + p13_nodeVar45 ) + p13_nodeVar49 ) + p13_nodeVar51 ) + p13_nodeVar53 ), 0.0001 ) ) );
	p13_nodeVar55 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p13_DiffuseColor = vec4<f32>( mix( p13_nodeVar54.xyz, max( p13_nodeVar54, p13_nodeVar55 ).xyz, ( max( max( p13_nodeVar55.x, p13_nodeVar55.y ), p13_nodeVar55.z ) * 0.5 ) ), 1.0 );
	p13_DiffuseColor.w = ( p13_DiffuseColor.w * f32(1.0) );
	p13_DiffuseColor.w = 1.0;
	p13_nodeVar56 = max( vec4<f32>( p13_DiffuseColor.xyz, p13_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p13_Output = p13_nodeVar56;

	// result

	p13_output.color = p13_nodeVar56;

	return p13_output;

}

// structs

struct p14_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p14_output : p14_OutputStruct;

// uniforms


// vars
var<private> p14_DiffuseColor : vec4<f32>;
var<private> p14_nodeVar0 : vec3<f32>;
var<private> p14_nodeVar1 : vec3<f32>;
var<private> p14_nodeVar2 : vec3<f32>;
var<private> p14_nodeVar3 : bool;
var<private> p14_nodeVar4 : vec4<f32>;
var<private> p14_nodeVar5 : vec2<f32>;
var<private> p14_nodeVar6 : vec2<f32>;
var<private> p14_nodeVar7 : vec4<f32>;
var<private> p14_nodeVar8 : vec4<f32>;
var<private> p14_nodeVar9 : vec4<f32>;
var<private> p14_nodeVar10 : f32;
var<private> p14_nodeVar11 : vec2<f32>;
var<private> p14_nodeVar12 : vec4<f32>;
var<private> p14_nodeVar13 : vec3<f32>;
var<private> p14_nodeVar14 : vec3<f32>;
var<private> p14_nodeVar15 : vec4<f32>;
var<private> p14_nodeVar16 : vec4<f32>;
var<private> p14_nodeVar17 : f32;
var<private> p14_nodeVar18 : vec4<f32>;
var<private> p14_nodeVar19 : f32;
var<private> p14_nodeVar20 : f32;
var<private> p14_nodeVar21 : vec3<f32>;
var<private> p14_nodeVar22 : bool;
var<private> p14_nodeVar23 : vec4<f32>;
var<private> p14_nodeVar24 : vec2<f32>;
var<private> p14_nodeVar25 : vec2<f32>;
var<private> p14_nodeVar26 : vec4<f32>;
var<private> p14_nodeVar27 : vec4<f32>;
var<private> p14_nodeVar28 : vec4<f32>;
var<private> p14_nodeVar29 : f32;
var<private> p14_nodeVar30 : vec2<f32>;
var<private> p14_nodeVar31 : vec4<f32>;
var<private> p14_nodeVar32 : vec3<f32>;
var<private> p14_nodeVar33 : vec3<f32>;
var<private> p14_nodeVar34 : vec4<f32>;
var<private> p14_nodeVar35 : vec4<f32>;
var<private> p14_nodeVar36 : f32;
var<private> p14_nodeVar37 : vec4<f32>;
var<private> p14_nodeVar38 : f32;
var<private> p14_nodeVar39 : vec2<f32>;
var<private> p14_nodeVar40 : vec4<f32>;
var<private> p14_nodeVar41 : vec4<f32>;
var<private> p14_nodeVar42 : vec2<f32>;
var<private> p14_Output : vec4<f32>;
var<private> p14_nodeVar43 : vec4<f32>;

// codes


fn p14_main(door_uv: vec2f) -> p14_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p14_nodeVar0 = vec3<f32>( vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z).x, vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z).y, vec3<f32>(knobs.backgroundColor.x, knobs.backgroundColor.y, knobs.backgroundColor.z).z );

	if ( ( f32(knobs.grainEnabled) > 0.5 ) ) {

		p14_nodeVar3 = ( f32(knobs.colorMode) > 0.5 );

		if ( p14_nodeVar3 ) {

			p14_nodeVar4 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
			p14_nodeVar5 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
			p14_nodeVar6 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
			p14_nodeVar7 = target_read( t0, t0_sampler, ( p14_nodeVar5 + vec2<f32>( ( p14_nodeVar6.x * 2.0 ), p14_nodeVar6.y ) ) );
			p14_nodeVar8 = target_read( t0, t0_sampler, ( p14_nodeVar5 - vec2<f32>( ( p14_nodeVar6.x * 2.0 ), p14_nodeVar6.y ) ) );
			p14_nodeVar2 = vec3<f32>( mix( p14_nodeVar4.x, ( p14_nodeVar4.x * 1.1 ), ( p14_nodeVar7.x * 0.3 ) ), p14_nodeVar4.y, mix( p14_nodeVar4.z, ( p14_nodeVar4.z * 1.15 ), ( p14_nodeVar8.z * 0.3 ) ) );

		} else {

			p14_nodeVar9 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
			p14_nodeVar10 = max( max( p14_nodeVar9.x, p14_nodeVar9.y ), p14_nodeVar9.z );
			p14_nodeVar2 = mix( mix( mix( p14_nodeVar0, vec3<f32>( vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).x, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).y, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).z ), smoothstep( 0.0, 0.25, p14_nodeVar10 ) ), vec3<f32>( vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).x, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).y, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).z ), smoothstep( 0.2, 0.65, p14_nodeVar10 ) ), vec3<f32>( vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).x, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).y, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).z ), smoothstep( 0.6, 0.95, p14_nodeVar10 ) );

		}

		p14_nodeVar11 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		p14_nodeVar12 = target_read( t0, t0_sampler, p14_nodeVar11 );
		p14_nodeVar13 = ( ( p14_nodeVar2 * vec3<f32>( pow( clamp( max( max( p14_nodeVar12.x, p14_nodeVar12.y ), p14_nodeVar12.z ), 0.0, 1.0 ), 1.2 ) ) ) * vec3<f32>( 1.8 ) );

		if ( p14_nodeVar3 ) {

			p14_nodeVar15 = target_read( t2, t2_sampler, p14_nodeVar11 );
			p14_nodeVar14 = p14_nodeVar15.xyz;

		} else {

			p14_nodeVar16 = target_read( t2, t2_sampler, p14_nodeVar11 );
			p14_nodeVar17 = max( max( p14_nodeVar16.x, p14_nodeVar16.y ), p14_nodeVar16.z );
			p14_nodeVar14 = mix( mix( mix( p14_nodeVar0, vec3<f32>( vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).x, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).y, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).z ), smoothstep( 0.0, 0.25, p14_nodeVar17 ) ), vec3<f32>( vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).x, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).y, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).z ), smoothstep( 0.2, 0.65, p14_nodeVar17 ) ), vec3<f32>( vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).x, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).y, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).z ), smoothstep( 0.6, 0.95, p14_nodeVar17 ) );

		}

		p14_nodeVar18 = target_read( t2, t2_sampler, p14_nodeVar11 );
		p14_nodeVar19 = pow( clamp( max( max( p14_nodeVar18.x, p14_nodeVar18.y ), p14_nodeVar18.z ), 0.0, 1.0 ), 0.96 );
		p14_nodeVar20 = ( ( fract( ( sin( dot( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.grainScale), f32(knobs.grainScale) ) ), vec2<f32>( 12.9898, 78.233 ) ) ) * 43758.5453123 ) ) - 0.5 ) * f32(knobs.grainIntensity) );
		p14_nodeVar1 = ( ( mix( p14_nodeVar13, ( ( p14_nodeVar14 * vec3<f32>( p14_nodeVar19 ) ) * vec3<f32>( 1.95 ) ), ( p14_nodeVar19 * f32(knobs.crispBlend) ) ) + ( p14_nodeVar13 * vec3<f32>( 0.15 ) ) ) + vec3<f32>( p14_nodeVar20, p14_nodeVar20, p14_nodeVar20 ) );

	} else {

		p14_nodeVar22 = ( f32(knobs.colorMode) > 0.5 );

		if ( p14_nodeVar22 ) {

			p14_nodeVar23 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
			p14_nodeVar24 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
			p14_nodeVar25 = vec2<f32>( ( 1.0 / f32(knobs.resolution.x) ), ( 1.0 / f32(knobs.resolution.y) ) );
			p14_nodeVar26 = target_read( t0, t0_sampler, ( p14_nodeVar24 + vec2<f32>( ( p14_nodeVar25.x * 2.0 ), p14_nodeVar25.y ) ) );
			p14_nodeVar27 = target_read( t0, t0_sampler, ( p14_nodeVar24 - vec2<f32>( ( p14_nodeVar25.x * 2.0 ), p14_nodeVar25.y ) ) );
			p14_nodeVar21 = vec3<f32>( mix( p14_nodeVar23.x, ( p14_nodeVar23.x * 1.1 ), ( p14_nodeVar26.x * 0.3 ) ), p14_nodeVar23.y, mix( p14_nodeVar23.z, ( p14_nodeVar23.z * 1.15 ), ( p14_nodeVar27.z * 0.3 ) ) );

		} else {

			p14_nodeVar28 = target_read( t0, t0_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
			p14_nodeVar29 = max( max( p14_nodeVar28.x, p14_nodeVar28.y ), p14_nodeVar28.z );
			p14_nodeVar21 = mix( mix( mix( p14_nodeVar0, vec3<f32>( vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).x, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).y, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).z ), smoothstep( 0.0, 0.25, p14_nodeVar29 ) ), vec3<f32>( vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).x, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).y, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).z ), smoothstep( 0.2, 0.65, p14_nodeVar29 ) ), vec3<f32>( vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).x, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).y, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).z ), smoothstep( 0.6, 0.95, p14_nodeVar29 ) );

		}

		p14_nodeVar30 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
		p14_nodeVar31 = target_read( t0, t0_sampler, p14_nodeVar30 );
		p14_nodeVar32 = ( ( p14_nodeVar21 * vec3<f32>( pow( clamp( max( max( p14_nodeVar31.x, p14_nodeVar31.y ), p14_nodeVar31.z ), 0.0, 1.0 ), 1.2 ) ) ) * vec3<f32>( 1.8 ) );

		if ( p14_nodeVar22 ) {

			p14_nodeVar34 = target_read( t2, t2_sampler, p14_nodeVar30 );
			p14_nodeVar33 = p14_nodeVar34.xyz;

		} else {

			p14_nodeVar35 = target_read( t2, t2_sampler, p14_nodeVar30 );
			p14_nodeVar36 = max( max( p14_nodeVar35.x, p14_nodeVar35.y ), p14_nodeVar35.z );
			p14_nodeVar33 = mix( mix( mix( p14_nodeVar0, vec3<f32>( vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).x, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).y, vec3<f32>(knobs.edgeColor.x, knobs.edgeColor.y, knobs.edgeColor.z).z ), smoothstep( 0.0, 0.25, p14_nodeVar36 ) ), vec3<f32>( vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).x, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).y, vec3<f32>(knobs.midColor.x, knobs.midColor.y, knobs.midColor.z).z ), smoothstep( 0.2, 0.65, p14_nodeVar36 ) ), vec3<f32>( vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).x, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).y, vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z).z ), smoothstep( 0.6, 0.95, p14_nodeVar36 ) );

		}

		p14_nodeVar37 = target_read( t2, t2_sampler, p14_nodeVar30 );
		p14_nodeVar38 = pow( clamp( max( max( p14_nodeVar37.x, p14_nodeVar37.y ), p14_nodeVar37.z ), 0.0, 1.0 ), 0.96 );
		p14_nodeVar1 = ( mix( p14_nodeVar32, ( ( p14_nodeVar33 * vec3<f32>( p14_nodeVar38 ) ) * vec3<f32>( 1.95 ) ), ( p14_nodeVar38 * f32(knobs.crispBlend) ) ) + ( p14_nodeVar32 * vec3<f32>( 0.15 ) ) );

	}

	p14_nodeVar39 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p14_nodeVar40 = target_read( t0, t0_sampler, p14_nodeVar39 );
	p14_nodeVar41 = target_read( t2, t2_sampler, p14_nodeVar39 );
	p14_nodeVar42 = ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( 2.0 ) ) - vec2<f32>( 1.0, 1.0 ) );
	p14_DiffuseColor = vec4<f32>( clamp( ( mix( p14_nodeVar0, p14_nodeVar1, smoothstep( 0.01, 0.85, max( pow( clamp( max( max( p14_nodeVar40.x, p14_nodeVar40.y ), p14_nodeVar40.z ), 0.0, 1.0 ), 1.2 ), pow( clamp( max( max( p14_nodeVar41.x, p14_nodeVar41.y ), p14_nodeVar41.z ), 0.0, 1.0 ), 0.96 ) ) ) ) * vec3<f32>( ( 1.0 - ( dot( p14_nodeVar42, p14_nodeVar42 ) * 0.15 ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p14_DiffuseColor.w = ( p14_DiffuseColor.w * f32(1.0) );
	p14_DiffuseColor.w = 1.0;
	p14_nodeVar43 = max( vec4<f32>( p14_DiffuseColor.xyz, p14_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p14_Output = p14_nodeVar43;

	// result

	p14_output.color = p14_nodeVar43;

	return p14_output;

}

// structs

struct p15_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p15_output : p15_OutputStruct;

// uniforms


// vars
var<private> p15_DiffuseColor : vec4<f32>;
var<private> p15_nodeVar0 : vec4<f32>;
var<private> p15_Output : vec4<f32>;
var<private> p15_nodeVar1 : vec4<f32>;

// codes


fn p15_main(door_uv: vec2f) -> p15_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p15_nodeVar0 = target_read( t3, t3_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p15_DiffuseColor = vec4<f32>( vec3<f32>( p15_nodeVar0.x, p15_nodeVar0.y, p15_nodeVar0.z ), 1.0 );
	p15_DiffuseColor.w = ( p15_DiffuseColor.w * f32(1.0) );
	p15_DiffuseColor.w = 1.0;
	p15_nodeVar1 = max( vec4<f32>( p15_DiffuseColor.xyz, p15_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p15_Output = p15_nodeVar1;

	// result

	p15_output.color = p15_nodeVar1;

	return p15_output;

}

// structs

struct p16_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p16_output : p16_OutputStruct;

// uniforms


// vars
var<private> p16_DiffuseColor : vec4<f32>;
var<private> p16_nodeVar0 : vec4<f32>;
var<private> p16_Output : vec4<f32>;
var<private> p16_nodeVar1 : vec4<f32>;

// codes


fn p16_main(door_uv: vec2f) -> p16_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p16_nodeVar0 = target_read( t4, t4_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p16_DiffuseColor = vec4<f32>( ( p16_nodeVar0.xyz * vec3<f32>( smoothstep( f32(knobs.bloomThreshold), ( f32(knobs.bloomThreshold) + max( f32((0.25 * knobs.bloomSoftness + 0)), 0.0001 ) ), dot( p16_nodeVar0.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ) ) ) ), 1.0 );
	p16_DiffuseColor.w = ( p16_DiffuseColor.w * f32(1.0) );
	p16_DiffuseColor.w = 1.0;
	p16_nodeVar1 = max( vec4<f32>( p16_DiffuseColor.xyz, p16_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p16_Output = p16_nodeVar1;

	// result

	p16_output.color = p16_nodeVar1;

	return p16_output;

}

// structs

struct p17_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p17_output : p17_OutputStruct;

// uniforms


// vars
var<private> p17_DiffuseColor : vec4<f32>;
var<private> p17_nodeVar0 : vec2<f32>;
var<private> p17_nodeVar1 : vec4<f32>;
var<private> p17_nodeVar2 : vec4<f32>;
var<private> p17_nodeVar3 : vec4<f32>;
var<private> p17_nodeVar4 : vec4<f32>;
var<private> p17_nodeVar5 : vec4<f32>;
var<private> p17_nodeVar6 : vec4<f32>;
var<private> p17_nodeVar7 : vec4<f32>;
var<private> p17_nodeVar8 : vec4<f32>;
var<private> p17_nodeVar9 : vec4<f32>;
var<private> p17_nodeVar10 : vec4<f32>;
var<private> p17_nodeVar11 : vec4<f32>;
var<private> p17_nodeVar12 : vec4<f32>;
var<private> p17_nodeVar13 : vec4<f32>;
var<private> p17_Output : vec4<f32>;
var<private> p17_nodeVar14 : vec4<f32>;

// codes


fn p17_main(door_uv: vec2f) -> p17_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p17_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p17_nodeVar1 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p17_nodeVar2 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p17_nodeVar3 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -1.0 ) ) ) );
	p17_nodeVar4 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p17_nodeVar5 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 1.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 1.0 ) ) ) );
	p17_nodeVar6 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p17_nodeVar7 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 0.0 ) ) ) );
	p17_nodeVar8 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p17_nodeVar9 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 0.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p17_nodeVar10 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p17_nodeVar11 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * -2.0 ) ) ) );
	p17_nodeVar12 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * -2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p17_nodeVar13 = target_read( t5, t5_sampler, ( p17_nodeVar0 + vec2<f32>( ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).x * 2.0 ), ( vec2<f32>((2 * (1.0 / (knobs.resolution.x / 0.25)) + 0), (2 * (1.0 / (knobs.resolution.y / 0.25)) + 0)).y * 2.0 ) ) ) );
	p17_DiffuseColor = vec4<f32>( ( ( ( ( p17_nodeVar1.xyz * vec3<f32>( 0.125 ) ) + ( ( ( p17_nodeVar2.xyz + p17_nodeVar3.xyz ) + ( p17_nodeVar4.xyz + p17_nodeVar5.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p17_nodeVar6.xyz + p17_nodeVar7.xyz ) + ( p17_nodeVar8.xyz + p17_nodeVar9.xyz ) ) * vec3<f32>( 0.0625 ) ) ) + ( ( ( p17_nodeVar10.xyz + p17_nodeVar11.xyz ) + ( p17_nodeVar12.xyz + p17_nodeVar13.xyz ) ) * vec3<f32>( 0.03125 ) ) ), 1.0 );
	p17_DiffuseColor.w = ( p17_DiffuseColor.w * f32(1.0) );
	p17_DiffuseColor.w = 1.0;
	p17_nodeVar14 = max( vec4<f32>( p17_DiffuseColor.xyz, p17_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p17_Output = p17_nodeVar14;

	// result

	p17_output.color = p17_nodeVar14;

	return p17_output;

}

// structs

struct p18_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p18_output : p18_OutputStruct;

// uniforms


// vars
var<private> p18_DiffuseColor : vec4<f32>;
var<private> p18_nodeVar0 : vec4<f32>;
var<private> p18_nodeVar1 : vec2<f32>;
var<private> p18_nodeVar2 : vec4<f32>;
var<private> p18_nodeVar3 : vec4<f32>;
var<private> p18_nodeVar4 : vec4<f32>;
var<private> p18_nodeVar5 : vec4<f32>;
var<private> p18_nodeVar6 : vec4<f32>;
var<private> p18_nodeVar7 : vec4<f32>;
var<private> p18_nodeVar8 : vec4<f32>;
var<private> p18_nodeVar9 : vec4<f32>;
var<private> p18_nodeVar10 : vec4<f32>;
var<private> p18_Output : vec4<f32>;
var<private> p18_nodeVar11 : vec4<f32>;

// codes


fn p18_main(door_uv: vec2f) -> p18_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p18_nodeVar0 = target_read( t5, t5_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p18_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p18_nodeVar2 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 0.0 ) ) ) );
	p18_nodeVar3 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 0.0 ) ) ) );
	p18_nodeVar4 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 0.0 ) ) ) );
	p18_nodeVar5 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * -1.0 ) ) ) );
	p18_nodeVar6 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 0.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 1.0 ) ) ) );
	p18_nodeVar7 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * -1.0 ) ) ) );
	p18_nodeVar8 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * -1.0 ) ) ) );
	p18_nodeVar9 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * -1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 1.0 ) ) ) );
	p18_nodeVar10 = target_read( t6, t6_sampler, ( p18_nodeVar1 + vec2<f32>( ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).x * 1.0 ), ( vec2<f32>((4 * (1.0 / (knobs.resolution.x / 0.5)) + 0), (4 * (1.0 / (knobs.resolution.y / 0.5)) + 0)).y * 1.0 ) ) ) );
	p18_DiffuseColor = vec4<f32>( ( p18_nodeVar0.xyz + ( ( ( p18_nodeVar2.xyz * vec3<f32>( 0.25 ) ) + ( ( ( p18_nodeVar3.xyz + p18_nodeVar4.xyz ) + ( p18_nodeVar5.xyz + p18_nodeVar6.xyz ) ) * vec3<f32>( 0.125 ) ) ) + ( ( ( p18_nodeVar7.xyz + p18_nodeVar8.xyz ) + ( p18_nodeVar9.xyz + p18_nodeVar10.xyz ) ) * vec3<f32>( 0.0625 ) ) ) ), 1.0 );
	p18_DiffuseColor.w = ( p18_DiffuseColor.w * f32(1.0) );
	p18_DiffuseColor.w = 1.0;
	p18_nodeVar11 = max( vec4<f32>( p18_DiffuseColor.xyz, p18_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p18_Output = p18_nodeVar11;

	// result

	p18_output.color = p18_nodeVar11;

	return p18_output;

}

// structs

struct p19_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p19_output : p19_OutputStruct;

// uniforms


// vars
var<private> p19_DiffuseColor : vec4<f32>;
var<private> p19_nodeVar0 : vec4<f32>;
var<private> p19_nodeVar1 : vec4<f32>;
var<private> p19_nodeVar2 : vec4<f32>;
var<private> p19_nodeVar3 : vec4<f32>;
var<private> p19_nodeVar4 : vec3<f32>;
var<private> p19_nodeVar5 : f32;
var<private> p19_nodeVar6 : vec3<f32>;
var<private> p19_nodeVar7 : vec4<f32>;
var<private> p19_Output : vec4<f32>;
var<private> p19_nodeVar8 : vec4<f32>;

// codes


fn p19_main(door_uv: vec2f) -> p19_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p19_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p19_nodeVar1 = target_read( t4, t4_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p19_nodeVar2 = target_read( t7, t7_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p19_nodeVar3 = vec4<f32>( clamp( ( p19_nodeVar1.xyz + clamp( ( ( p19_nodeVar2.xyz * vec3<f32>( f32(2.2) ) ) * vec3<f32>( f32(knobs.bloomIntensity) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 2.0, 2.0, 2.0 ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), 1.0 );
	p19_nodeVar4 = vec3<f32>( p19_nodeVar3.x, p19_nodeVar3.y, p19_nodeVar3.z );
	p19_nodeVar5 = ( ( ( p19_nodeVar4.x * 0.2126 ) + ( p19_nodeVar4.y * 0.7152 ) ) + ( p19_nodeVar4.z * 0.0722 ) );
	p19_nodeVar6 = mix( vec3<f32>( p19_nodeVar5, p19_nodeVar5, p19_nodeVar5 ), p19_nodeVar4, f32(1.0) );
	p19_nodeVar7 = vec4<f32>( clamp( vec3<f32>( ( ( ( p19_nodeVar6.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p19_nodeVar6.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p19_nodeVar6.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p19_nodeVar6.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p19_nodeVar6.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p19_nodeVar6.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p19_nodeVar6.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p19_nodeVar6.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p19_nodeVar6.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p19_nodeVar3.w, 0.0, 1.0 ) );
	p19_DiffuseColor = vec4<f32>( mix( p19_nodeVar0.xyz, p19_nodeVar7.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p19_nodeVar7.w, 0.0, 1.0 ) ) ), clamp( p19_nodeVar0.w, 0.0, 1.0 ) );
	p19_DiffuseColor.w = ( p19_DiffuseColor.w * f32(1.0) );
	p19_nodeVar8 = max( vec4<f32>( p19_DiffuseColor.xyz, p19_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p19_Output = p19_nodeVar8;

	// result

	p19_output.color = p19_nodeVar8;

	return p19_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    case 1u: { return p1_main(door_uv).color; }
    case 2u: { return p2_main(door_uv).color; }
    case 3u: { return p3_main(door_uv).color; }
    case 4u: { return p4_main(door_uv).color; }
    case 5u: { return p5_main(door_uv).color; }
    case 6u: { return p6_main(door_uv).color; }
    case 7u: { return p7_main(door_uv).color; }
    case 8u: { return p8_main(door_uv).color; }
    case 9u: { return p9_main(door_uv).color; }
    case 10u: { return p10_main(door_uv).color; }
    case 11u: { return p11_main(door_uv).color; }
    case 12u: { return p12_main(door_uv).color; }
    case 13u: { return p13_main(door_uv).color; }
    case 14u: { return p14_main(door_uv).color; }
    case 15u: { return p15_main(door_uv).color; }
    case 16u: { return p16_main(door_uv).color; }
    case 17u: { return p17_main(door_uv).color; }
    case 18u: { return p18_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p19_main(door_uv).color);
}

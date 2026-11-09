// Flares: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Light flares on the brightest points: crosses, stars, starbursts or anamorphic streaks.
// --pass@t0:0,1,s0.25,s0.25
// --pass@t1:0,1,s0.25,s0.25
// --pass@:0,0,s1,s1
// --track@threshold:Threshold,0,1,0.85,0.01
// --track@isolation:Isolation,0,120,10,1
// --track@intensity:Intensity,0,12,4,0.01
// --track@rays:Rays,1,16,4,1
// --track@rotation:Rotation,-180,180,0,1
// --track@length:Length,4,1200,120,1
// --track@secondaryLength:Secondary Rays,0,2,1,0.01
// --track@lengthJitter:Length Jitter,0,1,0,0.01
// --track@thickness:Thickness,0,16,1,0.1
// --track@falloff:Falloff,0.2,6,1.5,0.01
// --track@seed:Seed,0,999,0,1
// --track@color_x:Ray Color r,0,1,1,0.001
// --track@color_y:Ray Color g,0,1,0.19461783043107173,0.001
// --track@color_z:Ray Color b,0,1,0.04666508633021928,0.001
// --track@coreGlow:Core Glow,0,4,1,0.01
// --track@coreSize:Core Size,0,80,6,0.5
// --track@coreColor_x:Core Color r,0,1,1,0.001
// --track@coreColor_y:Core Color g,0,1,0.8962693533719567,0.001
// --track@coreColor_z:Core Color b,0,1,0.7454042095350284,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  threshold: f32,
  isolation: f32,
  intensity: f32,
  rays: f32,
  rotation: f32,
  length: f32,
  secondaryLength: f32,
  lengthJitter: f32,
  thickness: f32,
  falloff: f32,
  seed: f32,
  color: vec3<f32>,
  coreGlow: f32,
  coreSize: f32,
  coreColor: vec3<f32>,
};
@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var t0: texture_2d<f32>;
@group(0) @binding(3) var t0_sampler: sampler;
@group(0) @binding(4) var t1: texture_2d<f32>;
@group(0) @binding(5) var t1_sampler: sampler;
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

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec2<f32>;
var<private> p0_nodeVar1 : f32;
var<private> p0_nodeVar2 : vec2<f32>;
var<private> p0_nodeVar3 : vec4<f32>;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : vec4<f32>;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : vec4<f32>;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : vec4<f32>;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : vec4<f32>;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec4<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : vec4<f32>;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : vec4<f32>;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : vec4<f32>;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : vec4<f32>;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : vec4<f32>;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : vec4<f32>;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : vec4<f32>;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec4<f32>;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : vec2<f32>;
var<private> p0_nodeVar54 : vec4<f32>;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : vec4<f32>;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : vec4<f32>;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : vec4<f32>;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : vec4<f32>;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : vec4<f32>;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : vec4<f32>;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : vec4<f32>;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar78 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar2 = max( ( vec2<f32>((1.0 / (knobs.resolution.x / 0.25)), (1.0 / (knobs.resolution.y / 0.25))) * vec2<f32>( 1.0 ) ), ( vec2<f32>((1.0 / (knobs.resolution.x / 0.25)), (1.0 / (knobs.resolution.y / 0.25))) * vec2<f32>( ( f32(knobs.thickness) * 0.5 ) ) ) );
	p0_nodeVar3 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.5, -1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar4 = clamp( dot( vec3<f32>( p0_nodeVar3.x, p0_nodeVar3.y, p0_nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar4 <= 0.0031308 ) ) {

		p0_nodeVar1 = ( p0_nodeVar4 * 12.92 );

	} else {

		p0_nodeVar1 = ( ( pow( p0_nodeVar4, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar6 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.5, -1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar7 = clamp( dot( vec3<f32>( p0_nodeVar6.x, p0_nodeVar6.y, p0_nodeVar6.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar7 <= 0.0031308 ) ) {

		p0_nodeVar5 = ( p0_nodeVar7 * 12.92 );

	} else {

		p0_nodeVar5 = ( ( pow( p0_nodeVar7, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar9 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.5, -1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar10 = clamp( dot( vec3<f32>( p0_nodeVar9.x, p0_nodeVar9.y, p0_nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar10 <= 0.0031308 ) ) {

		p0_nodeVar8 = ( p0_nodeVar10 * 12.92 );

	} else {

		p0_nodeVar8 = ( ( pow( p0_nodeVar10, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar12 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 1.5, -1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar13 = clamp( dot( vec3<f32>( p0_nodeVar12.x, p0_nodeVar12.y, p0_nodeVar12.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar13 <= 0.0031308 ) ) {

		p0_nodeVar11 = ( p0_nodeVar13 * 12.92 );

	} else {

		p0_nodeVar11 = ( ( pow( p0_nodeVar13, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar15 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.5, -0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar16 = clamp( dot( vec3<f32>( p0_nodeVar15.x, p0_nodeVar15.y, p0_nodeVar15.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar16 <= 0.0031308 ) ) {

		p0_nodeVar14 = ( p0_nodeVar16 * 12.92 );

	} else {

		p0_nodeVar14 = ( ( pow( p0_nodeVar16, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar18 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.5, -0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar19 = clamp( dot( vec3<f32>( p0_nodeVar18.x, p0_nodeVar18.y, p0_nodeVar18.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar19 <= 0.0031308 ) ) {

		p0_nodeVar17 = ( p0_nodeVar19 * 12.92 );

	} else {

		p0_nodeVar17 = ( ( pow( p0_nodeVar19, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar21 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.5, -0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar22 = clamp( dot( vec3<f32>( p0_nodeVar21.x, p0_nodeVar21.y, p0_nodeVar21.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar22 <= 0.0031308 ) ) {

		p0_nodeVar20 = ( p0_nodeVar22 * 12.92 );

	} else {

		p0_nodeVar20 = ( ( pow( p0_nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar24 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 1.5, -0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar25 = clamp( dot( vec3<f32>( p0_nodeVar24.x, p0_nodeVar24.y, p0_nodeVar24.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar25 <= 0.0031308 ) ) {

		p0_nodeVar23 = ( p0_nodeVar25 * 12.92 );

	} else {

		p0_nodeVar23 = ( ( pow( p0_nodeVar25, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar27 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.5, 0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar28 = clamp( dot( vec3<f32>( p0_nodeVar27.x, p0_nodeVar27.y, p0_nodeVar27.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar28 <= 0.0031308 ) ) {

		p0_nodeVar26 = ( p0_nodeVar28 * 12.92 );

	} else {

		p0_nodeVar26 = ( ( pow( p0_nodeVar28, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar30 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.5, 0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar31 = clamp( dot( vec3<f32>( p0_nodeVar30.x, p0_nodeVar30.y, p0_nodeVar30.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar31 <= 0.0031308 ) ) {

		p0_nodeVar29 = ( p0_nodeVar31 * 12.92 );

	} else {

		p0_nodeVar29 = ( ( pow( p0_nodeVar31, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar33 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.5, 0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar34 = clamp( dot( vec3<f32>( p0_nodeVar33.x, p0_nodeVar33.y, p0_nodeVar33.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar34 <= 0.0031308 ) ) {

		p0_nodeVar32 = ( p0_nodeVar34 * 12.92 );

	} else {

		p0_nodeVar32 = ( ( pow( p0_nodeVar34, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar36 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 1.5, 0.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar37 = clamp( dot( vec3<f32>( p0_nodeVar36.x, p0_nodeVar36.y, p0_nodeVar36.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar37 <= 0.0031308 ) ) {

		p0_nodeVar35 = ( p0_nodeVar37 * 12.92 );

	} else {

		p0_nodeVar35 = ( ( pow( p0_nodeVar37, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar39 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.5, 1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar40 = clamp( dot( vec3<f32>( p0_nodeVar39.x, p0_nodeVar39.y, p0_nodeVar39.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar40 <= 0.0031308 ) ) {

		p0_nodeVar38 = ( p0_nodeVar40 * 12.92 );

	} else {

		p0_nodeVar38 = ( ( pow( p0_nodeVar40, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar42 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.5, 1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar43 = clamp( dot( vec3<f32>( p0_nodeVar42.x, p0_nodeVar42.y, p0_nodeVar42.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar43 <= 0.0031308 ) ) {

		p0_nodeVar41 = ( p0_nodeVar43 * 12.92 );

	} else {

		p0_nodeVar41 = ( ( pow( p0_nodeVar43, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar45 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.5, 1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar46 = clamp( dot( vec3<f32>( p0_nodeVar45.x, p0_nodeVar45.y, p0_nodeVar45.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar46 <= 0.0031308 ) ) {

		p0_nodeVar44 = ( p0_nodeVar46 * 12.92 );

	} else {

		p0_nodeVar44 = ( ( pow( p0_nodeVar46, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar48 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 1.5, 1.5 ) * p0_nodeVar2 ) ) );
	p0_nodeVar49 = clamp( dot( vec3<f32>( p0_nodeVar48.x, p0_nodeVar48.y, p0_nodeVar48.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

	if ( ( p0_nodeVar49 <= 0.0031308 ) ) {

		p0_nodeVar47 = ( p0_nodeVar49 * 12.92 );

	} else {

		p0_nodeVar47 = ( ( pow( p0_nodeVar49, 0.4166666666666667 ) * 1.055 ) - 0.055 );

	}

	p0_nodeVar50 = ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( 0.0 + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar1 ) * clamp( p0_nodeVar3.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar5 ) * clamp( p0_nodeVar6.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar8 ) * clamp( p0_nodeVar9.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar11 ) * clamp( p0_nodeVar12.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar14 ) * clamp( p0_nodeVar15.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar17 ) * clamp( p0_nodeVar18.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar20 ) * clamp( p0_nodeVar21.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar23 ) * clamp( p0_nodeVar24.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar26 ) * clamp( p0_nodeVar27.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar29 ) * clamp( p0_nodeVar30.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar32 ) * clamp( p0_nodeVar33.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar35 ) * clamp( p0_nodeVar36.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar38 ) * clamp( p0_nodeVar39.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar41 ) * clamp( p0_nodeVar42.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar44 ) * clamp( p0_nodeVar45.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar47 ) * clamp( p0_nodeVar48.w, 0.0, 1.0 ) ) ) / 16.0 );
	p0_nodeVar51 = 0.0;

	if ( ( f32(knobs.isolation) >= 0.5 ) ) {

		p0_nodeVar53 = ( vec2<f32>((1.0 / (knobs.resolution.x / 0.25)), (1.0 / (knobs.resolution.y / 0.25))) * vec2<f32>( f32(knobs.isolation) ) );
		p0_nodeVar54 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 1.0, 0.0 ) * p0_nodeVar53 ) ) );
		p0_nodeVar55 = clamp( dot( vec3<f32>( p0_nodeVar54.x, p0_nodeVar54.y, p0_nodeVar54.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar55 <= 0.0031308 ) ) {

			p0_nodeVar52 = ( p0_nodeVar55 * 12.92 );

		} else {

			p0_nodeVar52 = ( ( pow( p0_nodeVar55, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar57 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.7071067811865476, 0.7071067811865475 ) * p0_nodeVar53 ) ) );
		p0_nodeVar58 = clamp( dot( vec3<f32>( p0_nodeVar57.x, p0_nodeVar57.y, p0_nodeVar57.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar58 <= 0.0031308 ) ) {

			p0_nodeVar56 = ( p0_nodeVar58 * 12.92 );

		} else {

			p0_nodeVar56 = ( ( pow( p0_nodeVar58, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar60 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 6.123233995736766e-17, 1.0 ) * p0_nodeVar53 ) ) );
		p0_nodeVar61 = clamp( dot( vec3<f32>( p0_nodeVar60.x, p0_nodeVar60.y, p0_nodeVar60.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar61 <= 0.0031308 ) ) {

			p0_nodeVar59 = ( p0_nodeVar61 * 12.92 );

		} else {

			p0_nodeVar59 = ( ( pow( p0_nodeVar61, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar63 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.7071067811865475, 0.7071067811865476 ) * p0_nodeVar53 ) ) );
		p0_nodeVar64 = clamp( dot( vec3<f32>( p0_nodeVar63.x, p0_nodeVar63.y, p0_nodeVar63.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar64 <= 0.0031308 ) ) {

			p0_nodeVar62 = ( p0_nodeVar64 * 12.92 );

		} else {

			p0_nodeVar62 = ( ( pow( p0_nodeVar64, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar66 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.0, 1.2246467991473532e-16 ) * p0_nodeVar53 ) ) );
		p0_nodeVar67 = clamp( dot( vec3<f32>( p0_nodeVar66.x, p0_nodeVar66.y, p0_nodeVar66.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar67 <= 0.0031308 ) ) {

			p0_nodeVar65 = ( p0_nodeVar67 * 12.92 );

		} else {

			p0_nodeVar65 = ( ( pow( p0_nodeVar67, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar69 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -0.7071067811865477, -0.7071067811865475 ) * p0_nodeVar53 ) ) );
		p0_nodeVar70 = clamp( dot( vec3<f32>( p0_nodeVar69.x, p0_nodeVar69.y, p0_nodeVar69.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar70 <= 0.0031308 ) ) {

			p0_nodeVar68 = ( p0_nodeVar70 * 12.92 );

		} else {

			p0_nodeVar68 = ( ( pow( p0_nodeVar70, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar72 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( -1.8369701987210297e-16, -1.0 ) * p0_nodeVar53 ) ) );
		p0_nodeVar73 = clamp( dot( vec3<f32>( p0_nodeVar72.x, p0_nodeVar72.y, p0_nodeVar72.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar73 <= 0.0031308 ) ) {

			p0_nodeVar71 = ( p0_nodeVar73 * 12.92 );

		} else {

			p0_nodeVar71 = ( ( pow( p0_nodeVar73, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar75 = picture_read( ( p0_nodeVar0 + ( vec2<f32>( 0.7071067811865474, -0.7071067811865477 ) * p0_nodeVar53 ) ) );
		p0_nodeVar76 = clamp( dot( vec3<f32>( p0_nodeVar75.x, p0_nodeVar75.y, p0_nodeVar75.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( p0_nodeVar76 <= 0.0031308 ) ) {

			p0_nodeVar74 = ( p0_nodeVar76 * 12.92 );

		} else {

			p0_nodeVar74 = ( ( pow( p0_nodeVar76, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		p0_nodeVar51 = ( ( ( ( ( ( ( ( ( ( 0.0 + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar52 ) * clamp( p0_nodeVar54.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar56 ) * clamp( p0_nodeVar57.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar59 ) * clamp( p0_nodeVar60.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar62 ) * clamp( p0_nodeVar63.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar65 ) * clamp( p0_nodeVar66.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar68 ) * clamp( p0_nodeVar69.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar71 ) * clamp( p0_nodeVar72.w, 0.0, 1.0 ) ) ) + ( smoothstep( f32(knobs.threshold), 1.0, p0_nodeVar74 ) * clamp( p0_nodeVar75.w, 0.0, 1.0 ) ) ) / 8.0 ) * step( 0.5, f32(knobs.isolation) ) );
		

	}

	p0_nodeVar77 = max( ( p0_nodeVar50 - p0_nodeVar51 ), 0.0 );
	p0_DiffuseColor = vec4<f32>( p0_nodeVar77, p0_nodeVar77, p0_nodeVar77, 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar78 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar78;

	// result

	p0_output.color = p0_nodeVar78;

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
var<private> p1_nodeVar2 : f32;
var<private> p1_nodeVar3 : f32;
var<private> p1_nodeVar4 : f32;
var<private> p1_nodeVar5 : f32;
var<private> p1_nodeVar6 : f32;
var<private> p1_nodeVar7 : f32;
var<private> p1_nodeVar8 : f32;
var<private> p1_nodeVar9 : f32;
var<private> p1_nodeVar10 : f32;
var<private> p1_nodeVar11 : vec4<f32>;
var<private> p1_nodeVar12 : f32;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : vec4<f32>;
var<private> p1_nodeVar15 : vec2<f32>;
var<private> p1_nodeVar16 : vec4<f32>;
var<private> p1_nodeVar17 : vec4<f32>;
var<private> p1_nodeVar18 : vec4<f32>;
var<private> p1_nodeVar19 : vec4<f32>;
var<private> p1_nodeVar20 : vec4<f32>;
var<private> p1_nodeVar21 : vec4<f32>;
var<private> p1_nodeVar22 : vec4<f32>;
var<private> p1_nodeVar23 : vec4<f32>;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar24 : vec4<f32>;

// codes
fn p1_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar1 = vec2<f32>((1.0 / (knobs.resolution.x / 0.25)), (1.0 / (knobs.resolution.y / 0.25)));
	p1_nodeVar2 = 0.0;
	p1_nodeVar3 = 0.0;

	for ( var rayIndex : i32 = 0; rayIndex < i32( f32(knobs.rays) ); rayIndex ++ ) {


		if ( ( p1_tsl_mod_float( f32( rayIndex ), 2.0 ) > 0.5 ) ) {

			p1_nodeVar4 = f32(knobs.secondaryLength);

		} else {

			p1_nodeVar4 = 1.0;

		}

		p1_nodeVar5 = ( f32(knobs.length) * ( p1_nodeVar4 * mix( 1.0, ( ( fract( ( sin( ( ( f32( rayIndex ) * 12.9898 ) + ( f32(knobs.seed) * 78.233 ) ) ) * 43758.5453 ) ) * 0.85 ) + 0.15 ), f32(knobs.lengthJitter) ) ) );
		p1_nodeVar6 = clamp( ( floor( ( p1_nodeVar5 / f32(2.8) ) ) + 1.0 ), 4.0, 320.0 );

		for ( var tapIndex : i32 = 1; tapIndex < ( i32( p1_nodeVar6 ) + 1 ); tapIndex ++ ) {

			p1_nodeVar7 = ( 1.0 / p1_nodeVar6 );
			p1_nodeVar8 = ( f32( tapIndex ) * p1_nodeVar7 );
			p1_nodeVar9 = ( 1.0 - p1_nodeVar8 );
			p1_nodeVar10 = ( ( f32(knobs.rotation) * 0.017453292519943295 ) + ( ( f32( rayIndex ) * 6.283185307179586 ) / max( f32(knobs.rays), 1.0 ) ) );
			p1_nodeVar11 = target_read( t0, t0_sampler, ( p1_nodeVar0 - ( ( vec2<f32>( cos( p1_nodeVar10 ), ( - sin( p1_nodeVar10 ) ) ) * p1_nodeVar1 ) * vec2<f32>( ( p1_nodeVar5 * p1_nodeVar8 ) ) ) ) );
			p1_nodeVar12 = ( ( pow( p1_nodeVar9, f32(knobs.falloff) ) * p1_nodeVar11.x ) * p1_nodeVar7 );
			p1_nodeVar2 = ( p1_nodeVar2 + p1_nodeVar12 );
			p1_nodeVar3 = ( p1_nodeVar3 + ( p1_nodeVar12 * pow( p1_nodeVar9, 10.0 ) ) );

		}


	}

	p1_nodeVar13 = 0.0;

	if ( ( f32(knobs.coreGlow) >= 0.0001 ) ) {

		p1_nodeVar14 = target_read( t0, t0_sampler, p1_nodeVar0 );
		p1_nodeVar15 = ( p1_nodeVar1 * vec2<f32>( f32(knobs.coreSize) ) );
		p1_nodeVar16 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( 1.0, 0.0 ) * p1_nodeVar15 ) ) );
		p1_nodeVar17 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( 0.7071067811865476, 0.7071067811865475 ) * p1_nodeVar15 ) ) );
		p1_nodeVar18 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( 6.123233995736766e-17, 1.0 ) * p1_nodeVar15 ) ) );
		p1_nodeVar19 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( -0.7071067811865475, 0.7071067811865476 ) * p1_nodeVar15 ) ) );
		p1_nodeVar20 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( -1.0, 1.2246467991473532e-16 ) * p1_nodeVar15 ) ) );
		p1_nodeVar21 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( -0.7071067811865477, -0.7071067811865475 ) * p1_nodeVar15 ) ) );
		p1_nodeVar22 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( -1.8369701987210297e-16, -1.0 ) * p1_nodeVar15 ) ) );
		p1_nodeVar23 = target_read( t0, t0_sampler, ( p1_nodeVar0 + ( vec2<f32>( 0.7071067811865474, -0.7071067811865477 ) * p1_nodeVar15 ) ) );
		p1_nodeVar13 = ( ( ( ( ( ( ( ( ( p1_nodeVar14.x + ( p1_nodeVar16.x * 0.5 ) ) + ( p1_nodeVar17.x * 0.5 ) ) + ( p1_nodeVar18.x * 0.5 ) ) + ( p1_nodeVar19.x * 0.5 ) ) + ( p1_nodeVar20.x * 0.5 ) ) + ( p1_nodeVar21.x * 0.5 ) ) + ( p1_nodeVar22.x * 0.5 ) ) + ( p1_nodeVar23.x * 0.5 ) ) / 5.0 );
		

	}

	p1_DiffuseColor = vec4<f32>( p1_nodeVar2, p1_nodeVar3, p1_nodeVar13, 1.0 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_nodeVar24 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar24;

	// result

	p1_output.color = p1_nodeVar24;

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
var<private> p2_nodeVar0 : vec4<f32>;
var<private> p2_nodeVar1 : vec2<f32>;
var<private> p2_nodeVar2 : vec4<f32>;
var<private> p2_nodeVar3 : f32;
var<private> p2_nodeVar4 : f32;
var<private> p2_nodeVar5 : f32;
var<private> p2_nodeVar6 : vec3<f32>;
var<private> p2_nodeVar7 : f32;
var<private> p2_nodeVar8 : vec4<f32>;
var<private> p2_nodeVar9 : f32;
var<private> p2_nodeVar10 : f32;
var<private> p2_nodeVar11 : vec4<f32>;
var<private> p2_nodeVar12 : vec3<f32>;
var<private> p2_nodeVar13 : f32;
var<private> p2_nodeVar14 : vec3<f32>;
var<private> p2_nodeVar15 : vec4<f32>;
var<private> p2_nodeVar16 : f32;
var<private> p2_nodeVar17 : f32;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar18 : vec4<f32>;

// codes


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p2_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p2_nodeVar2 = target_read( t1, t1_sampler, p2_nodeVar1 );
	p2_nodeVar3 = ( f32(knobs.intensity) * 6.0 );
	p2_nodeVar4 = ( 1.0 - exp( ( - ( p2_nodeVar2.x * p2_nodeVar3 ) ) ) );
	p2_nodeVar5 = ( ( 1.0 - exp( ( - ( ( p2_nodeVar2.z * p2_nodeVar3 ) * f32(knobs.coreGlow) ) ) ) ) * step( 0.0001, f32(knobs.coreGlow) ) );
	p2_nodeVar6 = clamp( ( ( mix( vec3<f32>(knobs.color.x, knobs.color.y, knobs.color.z), vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z), clamp( ( p2_nodeVar2.y / max( p2_nodeVar2.x, 0.0001 ) ), 0.0, 1.0 ) ) * vec3<f32>( p2_nodeVar4 ) ) + ( vec3<f32>(knobs.coreColor.x, knobs.coreColor.y, knobs.coreColor.z) * vec3<f32>( p2_nodeVar5 ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) );
	p2_nodeVar7 = max( p2_nodeVar4, p2_nodeVar5 );
	p2_nodeVar8 = picture_read( p2_nodeVar1 );
	p2_nodeVar9 = clamp( p2_nodeVar8.w, 0.0, 1.0 );
	p2_nodeVar10 = max( p2_nodeVar9, p2_nodeVar7 );
	p2_nodeVar11 = vec4<f32>( mix( clamp( ( p2_nodeVar6 / vec3<f32>( max( p2_nodeVar7, 0.0001 ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), ( vec3<f32>( 1.0 ) - ( ( vec3<f32>( 1.0 ) - vec3<f32>( p2_nodeVar8.x, p2_nodeVar8.y, p2_nodeVar8.z ) ) * ( vec3<f32>( 1.0, 1.0, 1.0 ) - p2_nodeVar6 ) ) ), ( p2_nodeVar9 / max( p2_nodeVar10, 0.0001 ) ) ), p2_nodeVar10 );
	p2_nodeVar12 = vec3<f32>( p2_nodeVar11.x, p2_nodeVar11.y, p2_nodeVar11.z );
	p2_nodeVar13 = ( ( ( p2_nodeVar12.x * 0.2126 ) + ( p2_nodeVar12.y * 0.7152 ) ) + ( p2_nodeVar12.z * 0.0722 ) );
	p2_nodeVar14 = mix( vec3<f32>( p2_nodeVar13, p2_nodeVar13, p2_nodeVar13 ), p2_nodeVar12, f32(1.0) );
	p2_nodeVar15 = vec4<f32>( clamp( vec3<f32>( ( ( ( p2_nodeVar14.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p2_nodeVar14.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p2_nodeVar14.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p2_nodeVar14.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p2_nodeVar14.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p2_nodeVar14.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p2_nodeVar14.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p2_nodeVar14.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p2_nodeVar14.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p2_nodeVar11.w, 0.0, 1.0 ) );
	p2_nodeVar17 = mix( clamp( p2_nodeVar0.w, 0.0, 1.0 ), clamp( p2_nodeVar15.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p2_nodeVar17 > 0.0 ) ) {

		p2_nodeVar16 = p2_nodeVar17;

	} else {

		p2_nodeVar16 = 1.0;

	}

	p2_DiffuseColor = vec4<f32>( ( mix( ( p2_nodeVar0.xyz * vec3<f32>( clamp( p2_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p2_nodeVar15.xyz, p2_nodeVar15.xyz, clamp( p2_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p2_nodeVar15.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p2_nodeVar16 ) ), p2_nodeVar17 );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_nodeVar18 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar18;

	// result

	p2_output.color = p2_nodeVar18;

	return p2_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    case 1u: { return p1_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p2_main(door_uv).color);
}

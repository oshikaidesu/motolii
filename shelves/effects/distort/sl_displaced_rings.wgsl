// Displaced Rings: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Distort
// --about:Cuts the image into concentric rings or half-discs and shifts each one.
// --track@ringShape:Shape,0,3,0,1
// --check@shape:Cut,1
// --track@count:Rings,1,128,22,1
// --track@radius:Radius,0.01,2,2,0.01
// --track@distribution:Band Distribution,0.25,3,1,0.01
// --track@widthJitter:Width Jitter,0,1,0,0.01
// --track@pattern:Offset Pattern,0,2,0,1
// --track@rotation:Rotation,-180,180,0,1
// --track@rotationStep:Rotation per Ring,-180,180,45,1
// --track@rotationJitter:Rotation Jitter,0,180,0,1
// --track@scaleStep:Scale Progression,-0.9,3,0,0.01
// --track@seed:Seed,0,1000,1,1
// --check@output:Output,0
// --track@gap:Gap,0,1,0,0.01
// --track@softness:Edge Softness,0,0.1,0,0.001
// --track@lines:Lines,0,2,0,1
// --track@lineWidth:Line Width,0.25,12,1.5,0.25
// --track@lineColor_x:Line Color r,0,1,0.028426039499072558,0.001
// --track@lineColor_y:Line Color g,0,1,0.19806931954941637,0.001
// --track@lineColor_z:Line Color b,0,1,1,0.001
// --track@lineOpacity:Line Opacity,0,1,1,0.01
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  ringShape: f32,
  shape: f32,
  count: f32,
  radius: f32,
  distribution: f32,
  widthJitter: f32,
  pattern: f32,
  rotation: f32,
  rotationStep: f32,
  rotationJitter: f32,
  scaleStep: f32,
  seed: f32,
  output: f32,
  gap: f32,
  softness: f32,
  lines: f32,
  lineWidth: f32,
  lineColor: vec3<f32>,
  lineOpacity: f32,
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
var<private> p0_nodeVar2 : vec3<f32>;
var<private> p0_nodeVar3 : vec3<f32>;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : f32;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : vec2<f32>;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : bool;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : f32;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : vec3<f32>;
var<private> p0_nodeVar39 : vec2<f32>;
var<private> p0_nodeVar40 : vec4<f32>;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : vec2<f32>;
var<private> p0_nodeVar43 : vec4<f32>;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : vec2<f32>;
var<private> p0_nodeVar46 : vec4<f32>;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : vec2<f32>;
var<private> p0_nodeVar49 : vec4<f32>;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : vec2<f32>;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : vec2<f32>;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : f32;
var<private> p0_nodeVar77 : f32;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : f32;
var<private> p0_nodeVar81 : vec4<f32>;
var<private> p0_nodeVar82 : vec3<f32>;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : vec3<f32>;
var<private> p0_nodeVar85 : vec4<f32>;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar88 : vec4<f32>;

// codes
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>(0.5, 0.5) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) );

	if ( ( f32(knobs.output) > 0.5 ) ) {

		p0_nodeVar2 = vec3<f32>( 0.0, 0.0, 0.0 );

	} else {

		p0_nodeVar2 = ( p0_nodeVar0.xyz * vec3<f32>( p0_nodeVar0.w ) );

	}

	p0_nodeVar3 = p0_nodeVar2;

	if ( ( f32(knobs.output) > 0.5 ) ) {

		p0_nodeVar4 = 0.0;

	} else {

		p0_nodeVar4 = p0_nodeVar0.w;

	}

	p0_nodeVar5 = p0_nodeVar4;
	p0_nodeVar6 = max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) );
	p0_nodeVar7 = 0.0;
	p0_nodeVar8 = ( f32((knobs.lineWidth / knobs.resolution.y)) * 0.5 );
	p0_nodeVar9 = ( 6.283185307179586 / max( f32(array<f32, 4>(0.0, 3.0, 4.0, 6.0)[u32(knobs.ringShape)]), 3.0 ) );
	p0_nodeVar10 = cos( ( p0_nodeVar9 * 0.5 ) );

	if ( ( ( f32(knobs.count) > 0.5 ) && ( f32(knobs.count) < ( f32(knobs.count) - 0.5 ) ) ) ) {

		p0_nodeVar12 = ( pow( min( max( ( f32(knobs.count) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );
		p0_nodeVar11 = ( p0_nodeVar12 + ( ( ( ( fract( ( sin( ( ( f32(knobs.count) * 144.4 ) + ( f32(knobs.seed) * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * f32(knobs.widthJitter) ) * min( ( ( pow( min( max( ( ( f32(knobs.count) + 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) ) - p0_nodeVar12 ), ( p0_nodeVar12 - ( pow( min( max( ( ( f32(knobs.count) - 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) ) ) ) ) * 0.9 ) );

	} else {

		p0_nodeVar11 = ( pow( min( max( ( f32(knobs.count) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );

	}

	p0_nodeVar13 = p0_nodeVar11;
	p0_nodeVar14 = ( pow( min( max( ( f32(knobs.count) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );
	p0_nodeVar15 = ( pow( min( max( ( ( f32(knobs.count) - 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );

	for ( var i : i32 = 0; i < i32( f32(knobs.count) ); i ++ ) {

		p0_nodeVar16 = ( ( f32(knobs.count) - 1.0 ) - f32( i ) );
		p0_nodeVar17 = ( p0_nodeVar16 / max( ( f32(knobs.count) - 1.0 ), 1.0 ) );

		if ( ( f32(knobs.pattern) > 1.5 ) ) {

			p0_nodeVar18 = ( ( fract( ( sin( ( ( p0_nodeVar16 * 127.1 ) + ( f32(knobs.seed) * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

		} else {


			if ( ( f32(knobs.pattern) > 0.5 ) ) {

				p0_nodeVar19 = p0_nodeVar17;

			} else {


				if ( ( p0_tsl_mod_float( p0_nodeVar16, 2.0 ) < 1.0 ) ) {

					p0_nodeVar20 = -1.0;

				} else {

					p0_nodeVar20 = 1.0;

				}

				p0_nodeVar19 = ( p0_nodeVar20 * ( ( p0_nodeVar17 * 0.65 ) + 0.35 ) );

			}

			p0_nodeVar18 = p0_nodeVar19;

		}

		p0_nodeVar21 = ( p0_nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( p0_nodeVar18 ) ) );
		p0_nodeVar22 = ( ( f32((0.017453292519943295 * knobs.rotation + 0)) + ( f32((0.017453292519943295 * knobs.rotationStep + 0)) * p0_nodeVar16 ) ) + ( ( ( fract( ( sin( ( ( p0_nodeVar16 * 132.2 ) + ( f32(knobs.seed) * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * f32((0.017453292519943295 * knobs.rotationJitter + 0)) ) );
		p0_nodeVar23 = cos( p0_nodeVar22 );
		p0_nodeVar24 = sin( p0_nodeVar22 );
		p0_nodeVar25 = vec2<f32>( ( ( p0_nodeVar21.x * p0_nodeVar23 ) + ( p0_nodeVar21.y * p0_nodeVar24 ) ), ( ( p0_nodeVar21.y * p0_nodeVar23 ) - ( p0_nodeVar21.x * p0_nodeVar24 ) ) );
		p0_nodeVar26 = 0.0;

		if ( ( f32(array<f32, 4>(0.0, 3.0, 4.0, 6.0)[u32(knobs.ringShape)]) < 2.5 ) ) {

			p0_nodeVar26 = length( p0_nodeVar25 );
			

		} else {

			p0_nodeVar26 = ( ( length( p0_nodeVar25 ) * cos( ( p0_tsl_mod_float( ( atan2( p0_nodeVar25.y, p0_nodeVar25.x ) + 1.5707963267948966 ), p0_nodeVar9 ) - ( p0_nodeVar9 * 0.5 ) ) ) ) / p0_nodeVar10 );
			

		}

		p0_nodeVar27 = ( pow( min( max( ( ( p0_nodeVar16 - 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );
		p0_nodeVar28 = p0_nodeVar15;

		if ( ( ( ( p0_nodeVar16 > 0.5 ) && ( p0_nodeVar16 < ( f32(knobs.count) - 0.5 ) ) ) && ( f32(knobs.widthJitter) > 0.0 ) ) ) {

			p0_nodeVar28 = ( p0_nodeVar15 + ( ( ( ( fract( ( sin( ( ( p0_nodeVar16 * 144.4 ) + ( f32(knobs.seed) * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * f32(knobs.widthJitter) ) * min( ( p0_nodeVar14 - p0_nodeVar15 ), ( p0_nodeVar15 - p0_nodeVar27 ) ) ) * 0.9 ) );
			

		}


		if ( ( f32(knobs.lines) > 0.5 ) ) {

			p0_nodeVar7 = max( p0_nodeVar7, ( 1.0 - smoothstep( ( p0_nodeVar8 - p0_nodeVar6 ), ( p0_nodeVar8 + p0_nodeVar6 ), abs( ( p0_nodeVar26 - p0_nodeVar13 ) ) ) ) );
			

		}

		p0_nodeVar30 = ( ( ( ( ( f32(knobs.gap) == 0.0 ) && ( f32(knobs.softness) == 0.0 ) ) && ( length( vec2<f32>(0.0, 0.0) ) == 0.0 ) ) && ( f32(knobs.shape) == 0.0 ) ) && ( ( f32(array<f32, 4>(0.0, 3.0, 4.0, 6.0)[u32(knobs.ringShape)]) < 2.5 ) || ( ( f32((0.017453292519943295 * knobs.rotationStep + 0)) == 0.0 ) && ( f32((0.017453292519943295 * knobs.rotationJitter + 0)) == 0.0 ) ) ) );

		if ( ( p0_nodeVar30 && ( p0_nodeVar16 < ( f32(knobs.count) - 1.0 ) ) ) ) {

			p0_nodeVar29 = ( 1.0 - step( p0_nodeVar13, p0_nodeVar26 ) );

		} else {

			p0_nodeVar31 = ( ( ( p0_nodeVar13 - p0_nodeVar28 ) * f32(knobs.gap) ) * 0.5 );
			p0_nodeVar29 = ( 1.0 - smoothstep( ( ( p0_nodeVar13 - p0_nodeVar31 ) - p0_nodeVar6 ), ( ( p0_nodeVar13 - p0_nodeVar31 ) + p0_nodeVar6 ), p0_nodeVar26 ) );

		}


		if ( p0_nodeVar30 ) {

			p0_nodeVar32 = step( p0_nodeVar28, p0_nodeVar26 );

		} else {


			if ( ( p0_nodeVar16 == 0.0 ) ) {

				p0_nodeVar33 = 1.0;

			} else {

				p0_nodeVar34 = ( ( ( p0_nodeVar13 - p0_nodeVar28 ) * f32(knobs.gap) ) * 0.5 );
				p0_nodeVar33 = smoothstep( ( ( p0_nodeVar28 + p0_nodeVar34 ) - p0_nodeVar6 ), ( ( p0_nodeVar28 + p0_nodeVar34 ) + p0_nodeVar6 ), p0_nodeVar26 );

			}

			p0_nodeVar32 = p0_nodeVar33;

		}


		if ( ( f32(knobs.shape) > 0.5 ) ) {

			p0_nodeVar35 = smoothstep( ( - p0_nodeVar6 ), p0_nodeVar6, ( - p0_nodeVar25.y ) );

		} else {

			p0_nodeVar35 = 1.0;

		}


		if ( ( f32(knobs.gap) >= 1.0 ) ) {

			p0_nodeVar36 = 0.0;

		} else {

			p0_nodeVar36 = 1.0;

		}

		p0_nodeVar37 = ( ( ( p0_nodeVar29 * p0_nodeVar32 ) * p0_nodeVar35 ) * p0_nodeVar36 );

		if ( ( p0_nodeVar37 > 0.0 ) ) {


			if ( ( f32(knobs.output) > 0.5 ) ) {

				p0_nodeVar39 = ( ( ( p0_nodeVar25 / vec2<f32>( max( ( 1.0 + ( f32(knobs.scaleStep) * p0_nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>(0.5, 0.5) );
				p0_nodeVar40 = picture_read_level( p0_nodeVar39, 0.0 );
				p0_nodeVar41 = ( ( p0_nodeVar40.w * ( ( ( step( 0.0, p0_nodeVar39.x ) * step( p0_nodeVar39.x, 1.0 ) ) * step( 0.0, p0_nodeVar39.y ) ) * step( p0_nodeVar39.y, 1.0 ) ) ) * p0_nodeVar37 );
				p0_nodeVar38 = ( ( p0_nodeVar40.xyz * vec3<f32>( p0_nodeVar41 ) ) + ( p0_nodeVar3 * vec3<f32>( ( 1.0 - p0_nodeVar41 ) ) ) );

			} else {

				p0_nodeVar42 = ( ( ( p0_nodeVar25 / vec2<f32>( max( ( 1.0 + ( f32(knobs.scaleStep) * p0_nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>(0.5, 0.5) );
				p0_nodeVar43 = picture_read_level( p0_nodeVar42, 0.0 );
				p0_nodeVar38 = mix( p0_nodeVar3, ( p0_nodeVar43.xyz * vec3<f32>( ( p0_nodeVar43.w * ( ( ( step( 0.0, p0_nodeVar42.x ) * step( p0_nodeVar42.x, 1.0 ) ) * step( 0.0, p0_nodeVar42.y ) ) * step( p0_nodeVar42.y, 1.0 ) ) ) ) ), p0_nodeVar37 );

			}

			p0_nodeVar3 = p0_nodeVar38;

			if ( ( f32(knobs.output) > 0.5 ) ) {

				p0_nodeVar45 = ( ( ( p0_nodeVar25 / vec2<f32>( max( ( 1.0 + ( f32(knobs.scaleStep) * p0_nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>(0.5, 0.5) );
				p0_nodeVar46 = picture_read_level( p0_nodeVar45, 0.0 );
				p0_nodeVar47 = ( ( p0_nodeVar46.w * ( ( ( step( 0.0, p0_nodeVar45.x ) * step( p0_nodeVar45.x, 1.0 ) ) * step( 0.0, p0_nodeVar45.y ) ) * step( p0_nodeVar45.y, 1.0 ) ) ) * p0_nodeVar37 );
				p0_nodeVar44 = ( p0_nodeVar47 + ( p0_nodeVar5 * ( 1.0 - p0_nodeVar47 ) ) );

			} else {

				p0_nodeVar48 = ( ( ( p0_nodeVar25 / vec2<f32>( max( ( 1.0 + ( f32(knobs.scaleStep) * p0_nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>(0.5, 0.5) );
				p0_nodeVar49 = picture_read_level( p0_nodeVar48, 0.0 );
				p0_nodeVar44 = mix( p0_nodeVar5, ( p0_nodeVar49.w * ( ( ( step( 0.0, p0_nodeVar48.x ) * step( p0_nodeVar48.x, 1.0 ) ) * step( 0.0, p0_nodeVar48.y ) ) * step( p0_nodeVar48.y, 1.0 ) ) ), p0_nodeVar37 );

			}

			p0_nodeVar5 = p0_nodeVar44;
			

		}

		p0_nodeVar13 = p0_nodeVar28;
		p0_nodeVar14 = p0_nodeVar15;
		p0_nodeVar15 = p0_nodeVar27;

	}

	p0_nodeVar50 = 0.0;

	if ( ( f32(knobs.lines) > 1.5 ) ) {

		p0_nodeVar51 = 0.0;

		if ( ( f32(array<f32, 4>(0.0, 3.0, 4.0, 6.0)[u32(knobs.ringShape)]) < 2.5 ) ) {


			if ( ( f32(knobs.pattern) > 1.5 ) ) {

				p0_nodeVar52 = ( ( fract( ( sin( ( ( ( f32(knobs.count) - 1.0 ) * 127.1 ) + ( f32(knobs.seed) * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

			} else {


				if ( ( f32(knobs.pattern) > 0.5 ) ) {

					p0_nodeVar53 = ( ( f32(knobs.count) - 1.0 ) / max( ( f32(knobs.count) - 1.0 ), 1.0 ) );

				} else {

					p0_nodeVar55 = ( f32(knobs.count) - 1.0 );

					if ( ( p0_tsl_mod_float( p0_nodeVar55, 2.0 ) < 1.0 ) ) {

						p0_nodeVar54 = -1.0;

					} else {

						p0_nodeVar54 = 1.0;

					}

					p0_nodeVar53 = ( p0_nodeVar54 * ( ( ( p0_nodeVar55 / max( ( f32(knobs.count) - 1.0 ), 1.0 ) ) * 0.65 ) + 0.35 ) );

				}

				p0_nodeVar52 = p0_nodeVar53;

			}

			p0_nodeVar56 = ( p0_nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( p0_nodeVar52 ) ) );
			p0_nodeVar57 = ( f32(knobs.count) - 1.0 );
			p0_nodeVar58 = ( ( f32((0.017453292519943295 * knobs.rotation + 0)) + ( f32((0.017453292519943295 * knobs.rotationStep + 0)) * p0_nodeVar57 ) ) + ( ( ( fract( ( sin( ( ( p0_nodeVar57 * 132.2 ) + ( f32(knobs.seed) * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * f32((0.017453292519943295 * knobs.rotationJitter + 0)) ) );
			p0_nodeVar59 = cos( p0_nodeVar58 );
			p0_nodeVar60 = sin( p0_nodeVar58 );
			p0_nodeVar51 = length( vec2<f32>( ( ( p0_nodeVar56.x * p0_nodeVar59 ) + ( p0_nodeVar56.y * p0_nodeVar60 ) ), ( ( p0_nodeVar56.y * p0_nodeVar59 ) - ( p0_nodeVar56.x * p0_nodeVar60 ) ) ) );
			

		} else {


			if ( ( f32(knobs.pattern) > 1.5 ) ) {

				p0_nodeVar61 = ( ( fract( ( sin( ( ( ( f32(knobs.count) - 1.0 ) * 127.1 ) + ( f32(knobs.seed) * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

			} else {


				if ( ( f32(knobs.pattern) > 0.5 ) ) {

					p0_nodeVar62 = ( ( f32(knobs.count) - 1.0 ) / max( ( f32(knobs.count) - 1.0 ), 1.0 ) );

				} else {

					p0_nodeVar64 = ( f32(knobs.count) - 1.0 );

					if ( ( p0_tsl_mod_float( p0_nodeVar64, 2.0 ) < 1.0 ) ) {

						p0_nodeVar63 = -1.0;

					} else {

						p0_nodeVar63 = 1.0;

					}

					p0_nodeVar62 = ( p0_nodeVar63 * ( ( ( p0_nodeVar64 / max( ( f32(knobs.count) - 1.0 ), 1.0 ) ) * 0.65 ) + 0.35 ) );

				}

				p0_nodeVar61 = p0_nodeVar62;

			}

			p0_nodeVar65 = ( p0_nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( p0_nodeVar61 ) ) );
			p0_nodeVar66 = ( f32(knobs.count) - 1.0 );
			p0_nodeVar67 = ( ( f32((0.017453292519943295 * knobs.rotation + 0)) + ( f32((0.017453292519943295 * knobs.rotationStep + 0)) * p0_nodeVar66 ) ) + ( ( ( fract( ( sin( ( ( p0_nodeVar66 * 132.2 ) + ( f32(knobs.seed) * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * f32((0.017453292519943295 * knobs.rotationJitter + 0)) ) );
			p0_nodeVar68 = cos( p0_nodeVar67 );
			p0_nodeVar69 = sin( p0_nodeVar67 );
			p0_nodeVar70 = vec2<f32>( ( ( p0_nodeVar65.x * p0_nodeVar68 ) + ( p0_nodeVar65.y * p0_nodeVar69 ) ), ( ( p0_nodeVar65.y * p0_nodeVar68 ) - ( p0_nodeVar65.x * p0_nodeVar69 ) ) );
			p0_nodeVar51 = ( ( length( p0_nodeVar70 ) * cos( ( p0_tsl_mod_float( ( atan2( p0_nodeVar70.y, p0_nodeVar70.x ) + 1.5707963267948966 ), p0_nodeVar9 ) - ( p0_nodeVar9 * 0.5 ) ) ) ) / p0_nodeVar10 );
			

		}

		p0_nodeVar71 = ( p0_nodeVar51 - f32(knobs.radius) );
		p0_nodeVar73 = ( f32(knobs.count) - 1.0 );

		if ( ( ( p0_nodeVar73 > 0.5 ) && ( p0_nodeVar73 < ( f32(knobs.count) - 0.5 ) ) ) ) {

			p0_nodeVar74 = ( pow( min( max( ( p0_nodeVar73 / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );
			p0_nodeVar72 = ( p0_nodeVar74 + ( ( ( ( fract( ( sin( ( ( p0_nodeVar73 * 144.4 ) + ( f32(knobs.seed) * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * f32(knobs.widthJitter) ) * min( ( ( pow( min( max( ( ( p0_nodeVar73 + 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) ) - p0_nodeVar74 ), ( p0_nodeVar74 - ( pow( min( max( ( ( p0_nodeVar73 - 1.0 ) / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) ) ) ) ) * 0.9 ) );

		} else {

			p0_nodeVar72 = ( pow( min( max( ( p0_nodeVar73 / f32(knobs.count) ), 0.0 ), 1.0 ), f32(knobs.distribution) ) * f32(knobs.radius) );

		}

		p0_nodeVar75 = max( ( f32(knobs.radius) - p0_nodeVar72 ), ( f32((knobs.lineWidth / knobs.resolution.y)) * 4.0 ) );
		p0_nodeVar50 = ( ( 1.0 - smoothstep( ( p0_nodeVar8 - p0_nodeVar6 ), ( p0_nodeVar8 + p0_nodeVar6 ), ( abs( ( fract( ( ( p0_nodeVar71 / p0_nodeVar75 ) + 0.5 ) ) - 0.5 ) ) * p0_nodeVar75 ) ) ) * step( 0.0, p0_nodeVar71 ) );
		

	}


	if ( ( p0_nodeVar5 > 0.0 ) ) {

		p0_nodeVar76 = p0_nodeVar5;

	} else {

		p0_nodeVar76 = 1.0;

	}

	p0_nodeVar77 = min( p0_nodeVar5, 1.0 );
	p0_nodeVar78 = ( max( p0_nodeVar7, p0_nodeVar50 ) * f32(knobs.lineOpacity) );
	p0_nodeVar80 = ( ( p0_nodeVar77 * ( 1.0 - p0_nodeVar78 ) ) + p0_nodeVar78 );

	if ( ( p0_nodeVar80 > 0.0 ) ) {

		p0_nodeVar79 = p0_nodeVar80;

	} else {

		p0_nodeVar79 = 1.0;

	}

	p0_nodeVar81 = vec4<f32>( ( mix( ( ( p0_nodeVar3 / vec3<f32>( p0_nodeVar76 ) ) * vec3<f32>( p0_nodeVar77 ) ), vec3<f32>(knobs.lineColor.x, knobs.lineColor.y, knobs.lineColor.z), p0_nodeVar78 ) / vec3<f32>( p0_nodeVar79 ) ), p0_nodeVar80 );
	p0_nodeVar82 = vec3<f32>( p0_nodeVar81.x, p0_nodeVar81.y, p0_nodeVar81.z );
	p0_nodeVar83 = ( ( ( p0_nodeVar82.x * 0.2126 ) + ( p0_nodeVar82.y * 0.7152 ) ) + ( p0_nodeVar82.z * 0.0722 ) );
	p0_nodeVar84 = mix( vec3<f32>( p0_nodeVar83, p0_nodeVar83, p0_nodeVar83 ), p0_nodeVar82, f32(1.0) );
	p0_nodeVar85 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar84.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar84.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar84.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar84.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar84.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar84.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar84.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar84.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar84.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar81.w, 0.0, 1.0 ) );
	p0_nodeVar87 = mix( clamp( p0_nodeVar0.w, 0.0, 1.0 ), clamp( p0_nodeVar85.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p0_nodeVar87 > 0.0 ) ) {

		p0_nodeVar86 = p0_nodeVar87;

	} else {

		p0_nodeVar86 = 1.0;

	}

	p0_DiffuseColor = vec4<f32>( ( mix( ( p0_nodeVar0.xyz * vec3<f32>( clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p0_nodeVar85.xyz, p0_nodeVar85.xyz, clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p0_nodeVar85.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p0_nodeVar86 ) ), p0_nodeVar87 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar88 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar88;

	// result

	p0_output.color = p0_nodeVar88;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

// Displaced Rings: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Cuts the image into concentric rings or half-discs and shifts each one.
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
  output: f32,
  softness: f32,
  resolution: vec2<f32>,
  count: f32,
  distribution: f32,
  radius: f32,
  seed: f32,
  widthJitter: f32,
  pattern: f32,
  rotation: f32,
  rotationStep: f32,
  rotationJitter: f32,
  lines: f32,
  gap: f32,
  shape: f32,
  scaleStep: f32,
  lineColor: vec3<f32>,
  lineOpacity: f32,
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
var<private> nodeVar2 : vec3<f32>;
var<private> nodeVar3 : vec3<f32>;
var<private> nodeVar4 : f32;
var<private> nodeVar5 : f32;
var<private> nodeVar6 : f32;
var<private> nodeVar7 : f32;
var<private> nodeVar8 : f32;
var<private> nodeVar9 : f32;
var<private> nodeVar10 : f32;
var<private> nodeVar11 : f32;
var<private> nodeVar12 : f32;
var<private> nodeVar13 : f32;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : vec2<f32>;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : vec2<f32>;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : f32;
var<private> nodeVar30 : bool;
var<private> nodeVar31 : f32;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : f32;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : vec3<f32>;
var<private> nodeVar39 : vec2<f32>;
var<private> nodeVar40 : vec4<f32>;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : vec2<f32>;
var<private> nodeVar43 : vec4<f32>;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : vec2<f32>;
var<private> nodeVar46 : vec4<f32>;
var<private> nodeVar47 : f32;
var<private> nodeVar48 : vec2<f32>;
var<private> nodeVar49 : vec4<f32>;
var<private> nodeVar50 : f32;
var<private> nodeVar51 : f32;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : f32;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : vec2<f32>;
var<private> nodeVar57 : f32;
var<private> nodeVar58 : f32;
var<private> nodeVar59 : f32;
var<private> nodeVar60 : f32;
var<private> nodeVar61 : f32;
var<private> nodeVar62 : f32;
var<private> nodeVar63 : f32;
var<private> nodeVar64 : f32;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : f32;
var<private> nodeVar69 : f32;
var<private> nodeVar70 : vec2<f32>;
var<private> nodeVar71 : f32;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : f32;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : f32;
var<private> nodeVar77 : f32;
var<private> nodeVar78 : f32;
var<private> nodeVar79 : f32;
var<private> nodeVar80 : f32;
var<private> nodeVar81 : vec4<f32>;
var<private> nodeVar82 : vec3<f32>;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : vec3<f32>;
var<private> nodeVar85 : vec4<f32>;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> Output : vec4<f32>;
var<private> nodeVar88 : vec4<f32>;

// codes
fn tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>(0.5, 0.5) ) * vec2<f32>(1.7777777777777777, 1.0) );

	if ( ( (1 * knobs.output + 0) > 0.5 ) ) {

		nodeVar2 = vec3<f32>( 0.0, 0.0, 0.0 );

	} else {

		nodeVar2 = ( nodeVar0.xyz * vec3<f32>( nodeVar0.w ) );

	}

	nodeVar3 = nodeVar2;

	if ( ( (1 * knobs.output + 0) > 0.5 ) ) {

		nodeVar4 = 0.0;

	} else {

		nodeVar4 = nodeVar0.w;

	}

	nodeVar5 = nodeVar4;
	nodeVar6 = max( ( max( ( vec2<f32>(1.7777777777777777, 1.0).x / vec2<f32>(1920.0, 1080.0).x ), ( vec2<f32>(1.7777777777777777, 1.0).y / vec2<f32>(1920.0, 1080.0).y ) ) * 0.75 ), knobs.softness );
	nodeVar7 = 0.0;
	nodeVar8 = ( (-0.0000023809523809523808 * knobs.resolution.y + 0.0038095238095238095) * 0.5 );
	nodeVar9 = ( 6.283185307179586 / max( f32(0.0), 3.0 ) );
	nodeVar10 = cos( ( nodeVar9 * 0.5 ) );

	if ( ( ( knobs.count > 0.5 ) && ( knobs.count < ( knobs.count - 0.5 ) ) ) ) {

		nodeVar12 = ( pow( min( max( ( knobs.count / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );
		nodeVar11 = ( nodeVar12 + ( ( ( ( fract( ( sin( ( ( knobs.count * 144.4 ) + ( knobs.seed * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * knobs.widthJitter ) * min( ( ( pow( min( max( ( ( knobs.count + 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius ) - nodeVar12 ), ( nodeVar12 - ( pow( min( max( ( ( knobs.count - 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius ) ) ) ) * 0.9 ) );

	} else {

		nodeVar11 = ( pow( min( max( ( knobs.count / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );

	}

	nodeVar13 = nodeVar11;
	nodeVar14 = ( pow( min( max( ( knobs.count / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );
	nodeVar15 = ( pow( min( max( ( ( knobs.count - 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );

	for ( var i : i32 = 0; i < i32( knobs.count ); i ++ ) {

		nodeVar16 = ( ( knobs.count - 1.0 ) - f32( i ) );
		nodeVar17 = ( nodeVar16 / max( ( knobs.count - 1.0 ), 1.0 ) );

		if ( ( knobs.pattern > 1.5 ) ) {

			nodeVar18 = ( ( fract( ( sin( ( ( nodeVar16 * 127.1 ) + ( knobs.seed * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

		} else {


			if ( ( knobs.pattern > 0.5 ) ) {

				nodeVar19 = nodeVar17;

			} else {


				if ( ( tsl_mod_float( nodeVar16, 2.0 ) < 1.0 ) ) {

					nodeVar20 = -1.0;

				} else {

					nodeVar20 = 1.0;

				}

				nodeVar19 = ( nodeVar20 * ( ( nodeVar17 * 0.65 ) + 0.35 ) );

			}

			nodeVar18 = nodeVar19;

		}

		nodeVar21 = ( nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( nodeVar18 ) ) );
		nodeVar22 = ( ( (0.017453292519943295 * knobs.rotation + 0) + ( (0.017453292519943295 * knobs.rotationStep + 0) * nodeVar16 ) ) + ( ( ( fract( ( sin( ( ( nodeVar16 * 132.2 ) + ( knobs.seed * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * (0.017453292519943295 * knobs.rotationJitter + 0) ) );
		nodeVar23 = cos( nodeVar22 );
		nodeVar24 = sin( nodeVar22 );
		nodeVar25 = vec2<f32>( ( ( nodeVar21.x * nodeVar23 ) + ( nodeVar21.y * nodeVar24 ) ), ( ( nodeVar21.y * nodeVar23 ) - ( nodeVar21.x * nodeVar24 ) ) );
		nodeVar26 = 0.0;

		if ( ( f32(0.0) < 2.5 ) ) {

			nodeVar26 = length( nodeVar25 );
			

		} else {

			nodeVar26 = ( ( length( nodeVar25 ) * cos( ( tsl_mod_float( ( atan2( nodeVar25.y, nodeVar25.x ) + 1.5707963267948966 ), nodeVar9 ) - ( nodeVar9 * 0.5 ) ) ) ) / nodeVar10 );
			

		}

		nodeVar27 = ( pow( min( max( ( ( nodeVar16 - 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );
		nodeVar28 = nodeVar15;

		if ( ( ( ( nodeVar16 > 0.5 ) && ( nodeVar16 < ( knobs.count - 0.5 ) ) ) && ( knobs.widthJitter > 0.0 ) ) ) {

			nodeVar28 = ( nodeVar15 + ( ( ( ( fract( ( sin( ( ( nodeVar16 * 144.4 ) + ( knobs.seed * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * knobs.widthJitter ) * min( ( nodeVar14 - nodeVar15 ), ( nodeVar15 - nodeVar27 ) ) ) * 0.9 ) );
			

		}


		if ( ( knobs.lines > 0.5 ) ) {

			nodeVar7 = max( nodeVar7, ( 1.0 - smoothstep( ( nodeVar8 - nodeVar6 ), ( nodeVar8 + nodeVar6 ), abs( ( nodeVar26 - nodeVar13 ) ) ) ) );
			

		}

		nodeVar30 = ( ( ( ( ( knobs.gap == 0.0 ) && ( knobs.softness == 0.0 ) ) && ( length( vec2<f32>(0.0, 0.0) ) == 0.0 ) ) && ( (1 * knobs.shape + 0) == 0.0 ) ) && ( ( f32(0.0) < 2.5 ) || ( ( (0.017453292519943295 * knobs.rotationStep + 0) == 0.0 ) && ( (0.017453292519943295 * knobs.rotationJitter + 0) == 0.0 ) ) ) );

		if ( ( nodeVar30 && ( nodeVar16 < ( knobs.count - 1.0 ) ) ) ) {

			nodeVar29 = ( 1.0 - step( nodeVar13, nodeVar26 ) );

		} else {

			nodeVar31 = ( ( ( nodeVar13 - nodeVar28 ) * knobs.gap ) * 0.5 );
			nodeVar29 = ( 1.0 - smoothstep( ( ( nodeVar13 - nodeVar31 ) - nodeVar6 ), ( ( nodeVar13 - nodeVar31 ) + nodeVar6 ), nodeVar26 ) );

		}


		if ( nodeVar30 ) {

			nodeVar32 = step( nodeVar28, nodeVar26 );

		} else {


			if ( ( nodeVar16 == 0.0 ) ) {

				nodeVar33 = 1.0;

			} else {

				nodeVar34 = ( ( ( nodeVar13 - nodeVar28 ) * knobs.gap ) * 0.5 );
				nodeVar33 = smoothstep( ( ( nodeVar28 + nodeVar34 ) - nodeVar6 ), ( ( nodeVar28 + nodeVar34 ) + nodeVar6 ), nodeVar26 );

			}

			nodeVar32 = nodeVar33;

		}


		if ( ( (1 * knobs.shape + 0) > 0.5 ) ) {

			nodeVar35 = smoothstep( ( - nodeVar6 ), nodeVar6, ( - nodeVar25.y ) );

		} else {

			nodeVar35 = 1.0;

		}


		if ( ( knobs.gap >= 1.0 ) ) {

			nodeVar36 = 0.0;

		} else {

			nodeVar36 = 1.0;

		}

		nodeVar37 = ( ( ( nodeVar29 * nodeVar32 ) * nodeVar35 ) * nodeVar36 );

		if ( ( nodeVar37 > 0.0 ) ) {


			if ( ( (1 * knobs.output + 0) > 0.5 ) ) {

				nodeVar39 = ( ( ( nodeVar25 / vec2<f32>( max( ( 1.0 + ( knobs.scaleStep * nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>(1.7777777777777777, 1.0) ) + vec2<f32>(0.5, 0.5) );
				nodeVar40 = picture_read_level( nodeVar39, 0.0 );
				nodeVar41 = ( ( nodeVar40.w * ( ( ( step( 0.0, nodeVar39.x ) * step( nodeVar39.x, 1.0 ) ) * step( 0.0, nodeVar39.y ) ) * step( nodeVar39.y, 1.0 ) ) ) * nodeVar37 );
				nodeVar38 = ( ( nodeVar40.xyz * vec3<f32>( nodeVar41 ) ) + ( nodeVar3 * vec3<f32>( ( 1.0 - nodeVar41 ) ) ) );

			} else {

				nodeVar42 = ( ( ( nodeVar25 / vec2<f32>( max( ( 1.0 + ( knobs.scaleStep * nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>(1.7777777777777777, 1.0) ) + vec2<f32>(0.5, 0.5) );
				nodeVar43 = picture_read_level( nodeVar42, 0.0 );
				nodeVar38 = mix( nodeVar3, ( nodeVar43.xyz * vec3<f32>( ( nodeVar43.w * ( ( ( step( 0.0, nodeVar42.x ) * step( nodeVar42.x, 1.0 ) ) * step( 0.0, nodeVar42.y ) ) * step( nodeVar42.y, 1.0 ) ) ) ) ), nodeVar37 );

			}

			nodeVar3 = nodeVar38;

			if ( ( (1 * knobs.output + 0) > 0.5 ) ) {

				nodeVar45 = ( ( ( nodeVar25 / vec2<f32>( max( ( 1.0 + ( knobs.scaleStep * nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>(1.7777777777777777, 1.0) ) + vec2<f32>(0.5, 0.5) );
				nodeVar46 = picture_read_level( nodeVar45, 0.0 );
				nodeVar47 = ( ( nodeVar46.w * ( ( ( step( 0.0, nodeVar45.x ) * step( nodeVar45.x, 1.0 ) ) * step( 0.0, nodeVar45.y ) ) * step( nodeVar45.y, 1.0 ) ) ) * nodeVar37 );
				nodeVar44 = ( nodeVar47 + ( nodeVar5 * ( 1.0 - nodeVar47 ) ) );

			} else {

				nodeVar48 = ( ( ( nodeVar25 / vec2<f32>( max( ( 1.0 + ( knobs.scaleStep * nodeVar17 ) ), 0.1 ) ) ) / vec2<f32>(1.7777777777777777, 1.0) ) + vec2<f32>(0.5, 0.5) );
				nodeVar49 = picture_read_level( nodeVar48, 0.0 );
				nodeVar44 = mix( nodeVar5, ( nodeVar49.w * ( ( ( step( 0.0, nodeVar48.x ) * step( nodeVar48.x, 1.0 ) ) * step( 0.0, nodeVar48.y ) ) * step( nodeVar48.y, 1.0 ) ) ), nodeVar37 );

			}

			nodeVar5 = nodeVar44;
			

		}

		nodeVar13 = nodeVar28;
		nodeVar14 = nodeVar15;
		nodeVar15 = nodeVar27;

	}

	nodeVar50 = 0.0;

	if ( ( knobs.lines > 1.5 ) ) {

		nodeVar51 = 0.0;

		if ( ( f32(0.0) < 2.5 ) ) {


			if ( ( knobs.pattern > 1.5 ) ) {

				nodeVar52 = ( ( fract( ( sin( ( ( ( knobs.count - 1.0 ) * 127.1 ) + ( knobs.seed * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

			} else {


				if ( ( knobs.pattern > 0.5 ) ) {

					nodeVar53 = ( ( knobs.count - 1.0 ) / max( ( knobs.count - 1.0 ), 1.0 ) );

				} else {

					nodeVar55 = ( knobs.count - 1.0 );

					if ( ( tsl_mod_float( nodeVar55, 2.0 ) < 1.0 ) ) {

						nodeVar54 = -1.0;

					} else {

						nodeVar54 = 1.0;

					}

					nodeVar53 = ( nodeVar54 * ( ( ( nodeVar55 / max( ( knobs.count - 1.0 ), 1.0 ) ) * 0.65 ) + 0.35 ) );

				}

				nodeVar52 = nodeVar53;

			}

			nodeVar56 = ( nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( nodeVar52 ) ) );
			nodeVar57 = ( knobs.count - 1.0 );
			nodeVar58 = ( ( (0.017453292519943295 * knobs.rotation + 0) + ( (0.017453292519943295 * knobs.rotationStep + 0) * nodeVar57 ) ) + ( ( ( fract( ( sin( ( ( nodeVar57 * 132.2 ) + ( knobs.seed * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * (0.017453292519943295 * knobs.rotationJitter + 0) ) );
			nodeVar59 = cos( nodeVar58 );
			nodeVar60 = sin( nodeVar58 );
			nodeVar51 = length( vec2<f32>( ( ( nodeVar56.x * nodeVar59 ) + ( nodeVar56.y * nodeVar60 ) ), ( ( nodeVar56.y * nodeVar59 ) - ( nodeVar56.x * nodeVar60 ) ) ) );
			

		} else {


			if ( ( knobs.pattern > 1.5 ) ) {

				nodeVar61 = ( ( fract( ( sin( ( ( ( knobs.count - 1.0 ) * 127.1 ) + ( knobs.seed * 311.7 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 );

			} else {


				if ( ( knobs.pattern > 0.5 ) ) {

					nodeVar62 = ( ( knobs.count - 1.0 ) / max( ( knobs.count - 1.0 ), 1.0 ) );

				} else {

					nodeVar64 = ( knobs.count - 1.0 );

					if ( ( tsl_mod_float( nodeVar64, 2.0 ) < 1.0 ) ) {

						nodeVar63 = -1.0;

					} else {

						nodeVar63 = 1.0;

					}

					nodeVar62 = ( nodeVar63 * ( ( ( nodeVar64 / max( ( knobs.count - 1.0 ), 1.0 ) ) * 0.65 ) + 0.35 ) );

				}

				nodeVar61 = nodeVar62;

			}

			nodeVar65 = ( nodeVar1 - ( vec2<f32>(0.0, 0.0) * vec2<f32>( nodeVar61 ) ) );
			nodeVar66 = ( knobs.count - 1.0 );
			nodeVar67 = ( ( (0.017453292519943295 * knobs.rotation + 0) + ( (0.017453292519943295 * knobs.rotationStep + 0) * nodeVar66 ) ) + ( ( ( fract( ( sin( ( ( nodeVar66 * 132.2 ) + ( knobs.seed * 327.0 ) ) ) * 43758.5453 ) ) * 2.0 ) - 1.0 ) * (0.017453292519943295 * knobs.rotationJitter + 0) ) );
			nodeVar68 = cos( nodeVar67 );
			nodeVar69 = sin( nodeVar67 );
			nodeVar70 = vec2<f32>( ( ( nodeVar65.x * nodeVar68 ) + ( nodeVar65.y * nodeVar69 ) ), ( ( nodeVar65.y * nodeVar68 ) - ( nodeVar65.x * nodeVar69 ) ) );
			nodeVar51 = ( ( length( nodeVar70 ) * cos( ( tsl_mod_float( ( atan2( nodeVar70.y, nodeVar70.x ) + 1.5707963267948966 ), nodeVar9 ) - ( nodeVar9 * 0.5 ) ) ) ) / nodeVar10 );
			

		}

		nodeVar71 = ( nodeVar51 - knobs.radius );
		nodeVar73 = ( knobs.count - 1.0 );

		if ( ( ( nodeVar73 > 0.5 ) && ( nodeVar73 < ( knobs.count - 0.5 ) ) ) ) {

			nodeVar74 = ( pow( min( max( ( nodeVar73 / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );
			nodeVar72 = ( nodeVar74 + ( ( ( ( fract( ( sin( ( ( nodeVar73 * 144.4 ) + ( knobs.seed * 363.6 ) ) ) * 43758.5453 ) ) - 0.5 ) * knobs.widthJitter ) * min( ( ( pow( min( max( ( ( nodeVar73 + 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius ) - nodeVar74 ), ( nodeVar74 - ( pow( min( max( ( ( nodeVar73 - 1.0 ) / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius ) ) ) ) * 0.9 ) );

		} else {

			nodeVar72 = ( pow( min( max( ( nodeVar73 / knobs.count ), 0.0 ), 1.0 ), knobs.distribution ) * knobs.radius );

		}

		nodeVar75 = max( ( knobs.radius - nodeVar72 ), ( (-0.0000023809523809523808 * knobs.resolution.y + 0.0038095238095238095) * 4.0 ) );
		nodeVar50 = ( ( 1.0 - smoothstep( ( nodeVar8 - nodeVar6 ), ( nodeVar8 + nodeVar6 ), ( abs( ( fract( ( ( nodeVar71 / nodeVar75 ) + 0.5 ) ) - 0.5 ) ) * nodeVar75 ) ) ) * step( 0.0, nodeVar71 ) );
		

	}


	if ( ( nodeVar5 > 0.0 ) ) {

		nodeVar76 = nodeVar5;

	} else {

		nodeVar76 = 1.0;

	}

	nodeVar77 = min( nodeVar5, 1.0 );
	nodeVar78 = ( max( nodeVar7, nodeVar50 ) * knobs.lineOpacity );
	nodeVar80 = ( ( nodeVar77 * ( 1.0 - nodeVar78 ) ) + nodeVar78 );

	if ( ( nodeVar80 > 0.0 ) ) {

		nodeVar79 = nodeVar80;

	} else {

		nodeVar79 = 1.0;

	}

	nodeVar81 = vec4<f32>( ( mix( ( ( nodeVar3 / vec3<f32>( nodeVar76 ) ) * vec3<f32>( nodeVar77 ) ), knobs.lineColor, nodeVar78 ) / vec3<f32>( nodeVar79 ) ), nodeVar80 );
	nodeVar82 = vec3<f32>( nodeVar81.x, nodeVar81.y, nodeVar81.z );
	nodeVar83 = ( ( ( nodeVar82.x * 0.2126 ) + ( nodeVar82.y * 0.7152 ) ) + ( nodeVar82.z * 0.0722 ) );
	nodeVar84 = mix( vec3<f32>( nodeVar83, nodeVar83, nodeVar83 ), nodeVar82, f32(1.0) );
	nodeVar85 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar84.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar84.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar84.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar84.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar84.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar84.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar84.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar84.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar84.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar81.w, 0.0, 1.0 ) );
	nodeVar87 = mix( clamp( nodeVar0.w, 0.0, 1.0 ), clamp( nodeVar85.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( nodeVar87 > 0.0 ) ) {

		nodeVar86 = nodeVar87;

	} else {

		nodeVar86 = 1.0;

	}

	DiffuseColor = vec4<f32>( ( mix( ( nodeVar0.xyz * vec3<f32>( clamp( nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( nodeVar85.xyz, nodeVar85.xyz, clamp( nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( nodeVar85.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( nodeVar86 ) ), nodeVar87 );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar88 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar88;

	// result

	output.color = nodeVar88;

	output.color = to_shelf(output.color);
	return output;

}

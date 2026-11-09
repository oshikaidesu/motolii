// Pixel Sorting: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Distort
// --about:Sorts pixels into streaks by brightness or color.
// --pass@t0:0,1,s1,s1
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
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@:0,0,s1,s1
// --track@threshold:Threshold,0,1,0.25,0.01
// --track@upperThreshold:Upper Threshold,0,1,1,0.01
// --check@direction:Direction,0
// --track@mode:Mode,0,2,0,1
// --check@reverse:Reverse,0
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  threshold: f32,
  upperThreshold: f32,
  direction: f32,
  mode: f32,
  reverse: f32,
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
var<private> p0_nodeVar0 : f32;
var<private> p0_nodeVar1 : f32;
var<private> p0_nodeVar2 : bool;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : vec2<f32>;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : f32;
var<private> p0_nodeVar12 : vec2<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : vec2<f32>;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec2<f32>;
var<private> p0_nodeVar21 : vec2<f32>;
var<private> p0_nodeVar22 : vec4<f32>;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : vec4<f32>;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : bool;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : bool;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : f32;
var<private> p0_nodeVar42 : f32;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : bool;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : f32;
var<private> p0_nodeVar62 : f32;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : bool;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar76 : vec4<f32>;

// codes
fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar2 = ( f32(knobs.direction) < 0.5 );

	if ( p0_nodeVar2 ) {


		if ( p0_nodeVar2 ) {

			p0_nodeVar4 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p0_nodeVar2 ) {

				p0_nodeVar6 = p0_nodeVar4.x;

			} else {

				p0_nodeVar6 = p0_nodeVar4.y;

			}


			if ( ( p0_tsl_mod_float( ( p0_nodeVar6 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p0_nodeVar5 = 1.0;

			} else {

				p0_nodeVar5 = -1.0;

			}

			p0_nodeVar3 = ( p0_nodeVar4.x + p0_nodeVar5 );

		} else {

			p0_nodeVar3 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p0_nodeVar2 ) {

			p0_nodeVar7 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p0_nodeVar8 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p0_nodeVar2 ) {

				p0_nodeVar10 = p0_nodeVar8.x;

			} else {

				p0_nodeVar10 = p0_nodeVar8.y;

			}


			if ( ( p0_tsl_mod_float( ( p0_nodeVar10 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p0_nodeVar9 = 1.0;

			} else {

				p0_nodeVar9 = -1.0;

			}

			p0_nodeVar7 = ( p0_nodeVar8.y + p0_nodeVar9 );

		}

		p0_nodeVar1 = vec2<f32>( p0_nodeVar3, p0_nodeVar7 ).x;

	} else {


		if ( p0_nodeVar2 ) {

			p0_nodeVar12 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p0_nodeVar2 ) {

				p0_nodeVar14 = p0_nodeVar12.x;

			} else {

				p0_nodeVar14 = p0_nodeVar12.y;

			}


			if ( ( p0_tsl_mod_float( ( p0_nodeVar14 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p0_nodeVar13 = 1.0;

			} else {

				p0_nodeVar13 = -1.0;

			}

			p0_nodeVar11 = ( p0_nodeVar12.x + p0_nodeVar13 );

		} else {

			p0_nodeVar11 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p0_nodeVar2 ) {

			p0_nodeVar15 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p0_nodeVar16 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p0_nodeVar2 ) {

				p0_nodeVar18 = p0_nodeVar16.x;

			} else {

				p0_nodeVar18 = p0_nodeVar16.y;

			}


			if ( ( p0_tsl_mod_float( ( p0_nodeVar18 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p0_nodeVar17 = 1.0;

			} else {

				p0_nodeVar17 = -1.0;

			}

			p0_nodeVar15 = ( p0_nodeVar16.y + p0_nodeVar17 );

		}

		p0_nodeVar1 = vec2<f32>( p0_nodeVar11, p0_nodeVar15 ).y;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar19 = f32(knobs.resolution.x);

	} else {

		p0_nodeVar19 = f32(knobs.resolution.y);

	}

	p0_nodeVar20 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar21 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * p0_nodeVar20 ) );
	p0_nodeVar22 = picture_read( ( ( p0_nodeVar21 + vec2<f32>( 0.5 ) ) / p0_nodeVar20 ) );
	p0_nodeVar23 = dot( vec3<f32>( p0_nodeVar22.x, p0_nodeVar22.y, p0_nodeVar22.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( p0_nodeVar2 ) {


		if ( p0_nodeVar2 ) {

			p0_nodeVar26 = p0_nodeVar21.x;

		} else {

			p0_nodeVar26 = p0_nodeVar21.y;

		}


		if ( ( p0_tsl_mod_float( ( p0_nodeVar26 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

			p0_nodeVar25 = 1.0;

		} else {

			p0_nodeVar25 = -1.0;

		}

		p0_nodeVar24 = ( p0_nodeVar21.x + p0_nodeVar25 );

	} else {

		p0_nodeVar24 = p0_nodeVar21.x;

	}


	if ( p0_nodeVar2 ) {

		p0_nodeVar27 = p0_nodeVar21.y;

	} else {


		if ( p0_nodeVar2 ) {

			p0_nodeVar29 = p0_nodeVar21.x;

		} else {

			p0_nodeVar29 = p0_nodeVar21.y;

		}


		if ( ( p0_tsl_mod_float( ( p0_nodeVar29 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

			p0_nodeVar28 = 1.0;

		} else {

			p0_nodeVar28 = -1.0;

		}

		p0_nodeVar27 = ( p0_nodeVar21.y + p0_nodeVar28 );

	}

	p0_nodeVar30 = picture_read( ( ( vec2<f32>( p0_nodeVar24, p0_nodeVar27 ) + vec2<f32>( 0.5 ) ) / p0_nodeVar20 ) );
	p0_nodeVar31 = dot( vec3<f32>( p0_nodeVar30.x, p0_nodeVar30.y, p0_nodeVar30.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( ( f32(knobs.reverse) > 0.5 ) ) {


		if ( p0_nodeVar2 ) {

			p0_nodeVar34 = p0_nodeVar21.x;

		} else {

			p0_nodeVar34 = p0_nodeVar21.y;

		}

		p0_nodeVar35 = ( p0_tsl_mod_float( ( p0_nodeVar34 + f32(0.0) ), 2.0 ) < 1.0 );

		if ( p0_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar38 = max( max( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z );

				if ( ( p0_nodeVar38 > 0.001 ) ) {

					p0_nodeVar37 = ( ( p0_nodeVar38 - min( min( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z ) ) / p0_nodeVar38 );

				} else {

					p0_nodeVar37 = 0.0;

				}

				p0_nodeVar36 = p0_nodeVar37;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar39 = ( p0_nodeVar30.x - p0_nodeVar30.z );

				} else {

					p0_nodeVar39 = p0_nodeVar31;

				}

				p0_nodeVar36 = p0_nodeVar39;

			}

			p0_nodeVar33 = p0_nodeVar36;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar42 = max( max( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z );

				if ( ( p0_nodeVar42 > 0.001 ) ) {

					p0_nodeVar41 = ( ( p0_nodeVar42 - min( min( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z ) ) / p0_nodeVar42 );

				} else {

					p0_nodeVar41 = 0.0;

				}

				p0_nodeVar40 = p0_nodeVar41;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar43 = ( p0_nodeVar22.x - p0_nodeVar22.z );

				} else {

					p0_nodeVar43 = p0_nodeVar23;

				}

				p0_nodeVar40 = p0_nodeVar43;

			}

			p0_nodeVar33 = p0_nodeVar40;

		}


		if ( p0_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar47 = max( max( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z );

				if ( ( p0_nodeVar47 > 0.001 ) ) {

					p0_nodeVar46 = ( ( p0_nodeVar47 - min( min( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z ) ) / p0_nodeVar47 );

				} else {

					p0_nodeVar46 = 0.0;

				}

				p0_nodeVar45 = p0_nodeVar46;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar48 = ( p0_nodeVar22.x - p0_nodeVar22.z );

				} else {

					p0_nodeVar48 = p0_nodeVar23;

				}

				p0_nodeVar45 = p0_nodeVar48;

			}

			p0_nodeVar44 = p0_nodeVar45;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar51 = max( max( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z );

				if ( ( p0_nodeVar51 > 0.001 ) ) {

					p0_nodeVar50 = ( ( p0_nodeVar51 - min( min( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z ) ) / p0_nodeVar51 );

				} else {

					p0_nodeVar50 = 0.0;

				}

				p0_nodeVar49 = p0_nodeVar50;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar52 = ( p0_nodeVar30.x - p0_nodeVar30.z );

				} else {

					p0_nodeVar52 = p0_nodeVar31;

				}

				p0_nodeVar49 = p0_nodeVar52;

			}

			p0_nodeVar44 = p0_nodeVar49;

		}

		p0_nodeVar32 = ( p0_nodeVar33 > p0_nodeVar44 );

	} else {


		if ( p0_nodeVar2 ) {

			p0_nodeVar54 = p0_nodeVar21.x;

		} else {

			p0_nodeVar54 = p0_nodeVar21.y;

		}

		p0_nodeVar55 = ( p0_tsl_mod_float( ( p0_nodeVar54 + f32(0.0) ), 2.0 ) < 1.0 );

		if ( p0_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar58 = max( max( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z );

				if ( ( p0_nodeVar58 > 0.001 ) ) {

					p0_nodeVar57 = ( ( p0_nodeVar58 - min( min( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z ) ) / p0_nodeVar58 );

				} else {

					p0_nodeVar57 = 0.0;

				}

				p0_nodeVar56 = p0_nodeVar57;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar59 = ( p0_nodeVar22.x - p0_nodeVar22.z );

				} else {

					p0_nodeVar59 = p0_nodeVar23;

				}

				p0_nodeVar56 = p0_nodeVar59;

			}

			p0_nodeVar53 = p0_nodeVar56;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar62 = max( max( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z );

				if ( ( p0_nodeVar62 > 0.001 ) ) {

					p0_nodeVar61 = ( ( p0_nodeVar62 - min( min( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z ) ) / p0_nodeVar62 );

				} else {

					p0_nodeVar61 = 0.0;

				}

				p0_nodeVar60 = p0_nodeVar61;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar63 = ( p0_nodeVar30.x - p0_nodeVar30.z );

				} else {

					p0_nodeVar63 = p0_nodeVar31;

				}

				p0_nodeVar60 = p0_nodeVar63;

			}

			p0_nodeVar53 = p0_nodeVar60;

		}


		if ( p0_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar67 = max( max( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z );

				if ( ( p0_nodeVar67 > 0.001 ) ) {

					p0_nodeVar66 = ( ( p0_nodeVar67 - min( min( p0_nodeVar30.x, p0_nodeVar30.y ), p0_nodeVar30.z ) ) / p0_nodeVar67 );

				} else {

					p0_nodeVar66 = 0.0;

				}

				p0_nodeVar65 = p0_nodeVar66;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar68 = ( p0_nodeVar30.x - p0_nodeVar30.z );

				} else {

					p0_nodeVar68 = p0_nodeVar31;

				}

				p0_nodeVar65 = p0_nodeVar68;

			}

			p0_nodeVar64 = p0_nodeVar65;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p0_nodeVar71 = max( max( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z );

				if ( ( p0_nodeVar71 > 0.001 ) ) {

					p0_nodeVar70 = ( ( p0_nodeVar71 - min( min( p0_nodeVar22.x, p0_nodeVar22.y ), p0_nodeVar22.z ) ) / p0_nodeVar71 );

				} else {

					p0_nodeVar70 = 0.0;

				}

				p0_nodeVar69 = p0_nodeVar70;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p0_nodeVar72 = ( p0_nodeVar22.x - p0_nodeVar22.z );

				} else {

					p0_nodeVar72 = p0_nodeVar23;

				}

				p0_nodeVar69 = p0_nodeVar72;

			}

			p0_nodeVar64 = p0_nodeVar69;

		}

		p0_nodeVar32 = ( p0_nodeVar53 > p0_nodeVar64 );

	}

	p0_nodeVar73 = ( ( ( ( p0_nodeVar1 >= 0.0 ) && ( p0_nodeVar1 < p0_nodeVar19 ) ) && ( ( ( p0_nodeVar23 > f32(knobs.threshold) ) && ( p0_nodeVar23 < f32(knobs.upperThreshold) ) ) || ( ( p0_nodeVar31 > f32(knobs.threshold) ) && ( p0_nodeVar31 < f32(knobs.upperThreshold) ) ) ) ) && p0_nodeVar32 );

	if ( p0_nodeVar73 ) {

		p0_nodeVar0 = p0_nodeVar30.x;

	} else {

		p0_nodeVar0 = p0_nodeVar22.x;

	}


	if ( p0_nodeVar73 ) {

		p0_nodeVar74 = p0_nodeVar30.y;

	} else {

		p0_nodeVar74 = p0_nodeVar22.y;

	}


	if ( p0_nodeVar73 ) {

		p0_nodeVar75 = p0_nodeVar30.z;

	} else {

		p0_nodeVar75 = p0_nodeVar22.z;

	}

	p0_DiffuseColor = vec4<f32>( p0_nodeVar0, p0_nodeVar74, p0_nodeVar75, 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar76 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar76;

	// result

	p0_output.color = p0_nodeVar76;

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
var<private> p1_nodeVar0 : f32;
var<private> p1_nodeVar1 : f32;
var<private> p1_nodeVar2 : bool;
var<private> p1_nodeVar3 : f32;
var<private> p1_nodeVar4 : vec2<f32>;
var<private> p1_nodeVar5 : f32;
var<private> p1_nodeVar6 : f32;
var<private> p1_nodeVar7 : f32;
var<private> p1_nodeVar8 : vec2<f32>;
var<private> p1_nodeVar9 : f32;
var<private> p1_nodeVar10 : f32;
var<private> p1_nodeVar11 : f32;
var<private> p1_nodeVar12 : vec2<f32>;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : f32;
var<private> p1_nodeVar15 : f32;
var<private> p1_nodeVar16 : vec2<f32>;
var<private> p1_nodeVar17 : f32;
var<private> p1_nodeVar18 : f32;
var<private> p1_nodeVar19 : f32;
var<private> p1_nodeVar20 : vec2<f32>;
var<private> p1_nodeVar21 : vec2<f32>;
var<private> p1_nodeVar22 : vec4<f32>;
var<private> p1_nodeVar23 : f32;
var<private> p1_nodeVar24 : f32;
var<private> p1_nodeVar25 : f32;
var<private> p1_nodeVar26 : f32;
var<private> p1_nodeVar27 : f32;
var<private> p1_nodeVar28 : f32;
var<private> p1_nodeVar29 : f32;
var<private> p1_nodeVar30 : vec4<f32>;
var<private> p1_nodeVar31 : f32;
var<private> p1_nodeVar32 : bool;
var<private> p1_nodeVar33 : f32;
var<private> p1_nodeVar34 : f32;
var<private> p1_nodeVar35 : bool;
var<private> p1_nodeVar36 : f32;
var<private> p1_nodeVar37 : f32;
var<private> p1_nodeVar38 : f32;
var<private> p1_nodeVar39 : f32;
var<private> p1_nodeVar40 : f32;
var<private> p1_nodeVar41 : f32;
var<private> p1_nodeVar42 : f32;
var<private> p1_nodeVar43 : f32;
var<private> p1_nodeVar44 : f32;
var<private> p1_nodeVar45 : f32;
var<private> p1_nodeVar46 : f32;
var<private> p1_nodeVar47 : f32;
var<private> p1_nodeVar48 : f32;
var<private> p1_nodeVar49 : f32;
var<private> p1_nodeVar50 : f32;
var<private> p1_nodeVar51 : f32;
var<private> p1_nodeVar52 : f32;
var<private> p1_nodeVar53 : f32;
var<private> p1_nodeVar54 : f32;
var<private> p1_nodeVar55 : bool;
var<private> p1_nodeVar56 : f32;
var<private> p1_nodeVar57 : f32;
var<private> p1_nodeVar58 : f32;
var<private> p1_nodeVar59 : f32;
var<private> p1_nodeVar60 : f32;
var<private> p1_nodeVar61 : f32;
var<private> p1_nodeVar62 : f32;
var<private> p1_nodeVar63 : f32;
var<private> p1_nodeVar64 : f32;
var<private> p1_nodeVar65 : f32;
var<private> p1_nodeVar66 : f32;
var<private> p1_nodeVar67 : f32;
var<private> p1_nodeVar68 : f32;
var<private> p1_nodeVar69 : f32;
var<private> p1_nodeVar70 : f32;
var<private> p1_nodeVar71 : f32;
var<private> p1_nodeVar72 : f32;
var<private> p1_nodeVar73 : bool;
var<private> p1_nodeVar74 : f32;
var<private> p1_nodeVar75 : f32;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar76 : vec4<f32>;

// codes
fn p1_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar2 = ( f32(knobs.direction) < 0.5 );

	if ( p1_nodeVar2 ) {


		if ( p1_nodeVar2 ) {

			p1_nodeVar4 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p1_nodeVar2 ) {

				p1_nodeVar6 = p1_nodeVar4.x;

			} else {

				p1_nodeVar6 = p1_nodeVar4.y;

			}


			if ( ( p1_tsl_mod_float( ( p1_nodeVar6 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

				p1_nodeVar5 = 1.0;

			} else {

				p1_nodeVar5 = -1.0;

			}

			p1_nodeVar3 = ( p1_nodeVar4.x + p1_nodeVar5 );

		} else {

			p1_nodeVar3 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p1_nodeVar2 ) {

			p1_nodeVar7 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p1_nodeVar8 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p1_nodeVar2 ) {

				p1_nodeVar10 = p1_nodeVar8.x;

			} else {

				p1_nodeVar10 = p1_nodeVar8.y;

			}


			if ( ( p1_tsl_mod_float( ( p1_nodeVar10 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

				p1_nodeVar9 = 1.0;

			} else {

				p1_nodeVar9 = -1.0;

			}

			p1_nodeVar7 = ( p1_nodeVar8.y + p1_nodeVar9 );

		}

		p1_nodeVar1 = vec2<f32>( p1_nodeVar3, p1_nodeVar7 ).x;

	} else {


		if ( p1_nodeVar2 ) {

			p1_nodeVar12 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p1_nodeVar2 ) {

				p1_nodeVar14 = p1_nodeVar12.x;

			} else {

				p1_nodeVar14 = p1_nodeVar12.y;

			}


			if ( ( p1_tsl_mod_float( ( p1_nodeVar14 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

				p1_nodeVar13 = 1.0;

			} else {

				p1_nodeVar13 = -1.0;

			}

			p1_nodeVar11 = ( p1_nodeVar12.x + p1_nodeVar13 );

		} else {

			p1_nodeVar11 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p1_nodeVar2 ) {

			p1_nodeVar15 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p1_nodeVar16 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p1_nodeVar2 ) {

				p1_nodeVar18 = p1_nodeVar16.x;

			} else {

				p1_nodeVar18 = p1_nodeVar16.y;

			}


			if ( ( p1_tsl_mod_float( ( p1_nodeVar18 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

				p1_nodeVar17 = 1.0;

			} else {

				p1_nodeVar17 = -1.0;

			}

			p1_nodeVar15 = ( p1_nodeVar16.y + p1_nodeVar17 );

		}

		p1_nodeVar1 = vec2<f32>( p1_nodeVar11, p1_nodeVar15 ).y;

	}


	if ( p1_nodeVar2 ) {

		p1_nodeVar19 = f32(knobs.resolution.x);

	} else {

		p1_nodeVar19 = f32(knobs.resolution.y);

	}

	p1_nodeVar20 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p1_nodeVar21 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * p1_nodeVar20 ) );
	p1_nodeVar22 = target_read( t0, t0_sampler, ( ( p1_nodeVar21 + vec2<f32>( 0.5 ) ) / p1_nodeVar20 ) );
	p1_nodeVar23 = dot( vec3<f32>( p1_nodeVar22.x, p1_nodeVar22.y, p1_nodeVar22.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( p1_nodeVar2 ) {


		if ( p1_nodeVar2 ) {

			p1_nodeVar26 = p1_nodeVar21.x;

		} else {

			p1_nodeVar26 = p1_nodeVar21.y;

		}


		if ( ( p1_tsl_mod_float( ( p1_nodeVar26 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

			p1_nodeVar25 = 1.0;

		} else {

			p1_nodeVar25 = -1.0;

		}

		p1_nodeVar24 = ( p1_nodeVar21.x + p1_nodeVar25 );

	} else {

		p1_nodeVar24 = p1_nodeVar21.x;

	}


	if ( p1_nodeVar2 ) {

		p1_nodeVar27 = p1_nodeVar21.y;

	} else {


		if ( p1_nodeVar2 ) {

			p1_nodeVar29 = p1_nodeVar21.x;

		} else {

			p1_nodeVar29 = p1_nodeVar21.y;

		}


		if ( ( p1_tsl_mod_float( ( p1_nodeVar29 + f32(1.0) ), 2.0 ) < 1.0 ) ) {

			p1_nodeVar28 = 1.0;

		} else {

			p1_nodeVar28 = -1.0;

		}

		p1_nodeVar27 = ( p1_nodeVar21.y + p1_nodeVar28 );

	}

	p1_nodeVar30 = target_read( t0, t0_sampler, ( ( vec2<f32>( p1_nodeVar24, p1_nodeVar27 ) + vec2<f32>( 0.5 ) ) / p1_nodeVar20 ) );
	p1_nodeVar31 = dot( vec3<f32>( p1_nodeVar30.x, p1_nodeVar30.y, p1_nodeVar30.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( ( f32(knobs.reverse) > 0.5 ) ) {


		if ( p1_nodeVar2 ) {

			p1_nodeVar34 = p1_nodeVar21.x;

		} else {

			p1_nodeVar34 = p1_nodeVar21.y;

		}

		p1_nodeVar35 = ( p1_tsl_mod_float( ( p1_nodeVar34 + f32(1.0) ), 2.0 ) < 1.0 );

		if ( p1_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar38 = max( max( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z );

				if ( ( p1_nodeVar38 > 0.001 ) ) {

					p1_nodeVar37 = ( ( p1_nodeVar38 - min( min( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z ) ) / p1_nodeVar38 );

				} else {

					p1_nodeVar37 = 0.0;

				}

				p1_nodeVar36 = p1_nodeVar37;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar39 = ( p1_nodeVar30.x - p1_nodeVar30.z );

				} else {

					p1_nodeVar39 = p1_nodeVar31;

				}

				p1_nodeVar36 = p1_nodeVar39;

			}

			p1_nodeVar33 = p1_nodeVar36;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar42 = max( max( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z );

				if ( ( p1_nodeVar42 > 0.001 ) ) {

					p1_nodeVar41 = ( ( p1_nodeVar42 - min( min( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z ) ) / p1_nodeVar42 );

				} else {

					p1_nodeVar41 = 0.0;

				}

				p1_nodeVar40 = p1_nodeVar41;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar43 = ( p1_nodeVar22.x - p1_nodeVar22.z );

				} else {

					p1_nodeVar43 = p1_nodeVar23;

				}

				p1_nodeVar40 = p1_nodeVar43;

			}

			p1_nodeVar33 = p1_nodeVar40;

		}


		if ( p1_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar47 = max( max( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z );

				if ( ( p1_nodeVar47 > 0.001 ) ) {

					p1_nodeVar46 = ( ( p1_nodeVar47 - min( min( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z ) ) / p1_nodeVar47 );

				} else {

					p1_nodeVar46 = 0.0;

				}

				p1_nodeVar45 = p1_nodeVar46;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar48 = ( p1_nodeVar22.x - p1_nodeVar22.z );

				} else {

					p1_nodeVar48 = p1_nodeVar23;

				}

				p1_nodeVar45 = p1_nodeVar48;

			}

			p1_nodeVar44 = p1_nodeVar45;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar51 = max( max( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z );

				if ( ( p1_nodeVar51 > 0.001 ) ) {

					p1_nodeVar50 = ( ( p1_nodeVar51 - min( min( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z ) ) / p1_nodeVar51 );

				} else {

					p1_nodeVar50 = 0.0;

				}

				p1_nodeVar49 = p1_nodeVar50;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar52 = ( p1_nodeVar30.x - p1_nodeVar30.z );

				} else {

					p1_nodeVar52 = p1_nodeVar31;

				}

				p1_nodeVar49 = p1_nodeVar52;

			}

			p1_nodeVar44 = p1_nodeVar49;

		}

		p1_nodeVar32 = ( p1_nodeVar33 > p1_nodeVar44 );

	} else {


		if ( p1_nodeVar2 ) {

			p1_nodeVar54 = p1_nodeVar21.x;

		} else {

			p1_nodeVar54 = p1_nodeVar21.y;

		}

		p1_nodeVar55 = ( p1_tsl_mod_float( ( p1_nodeVar54 + f32(1.0) ), 2.0 ) < 1.0 );

		if ( p1_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar58 = max( max( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z );

				if ( ( p1_nodeVar58 > 0.001 ) ) {

					p1_nodeVar57 = ( ( p1_nodeVar58 - min( min( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z ) ) / p1_nodeVar58 );

				} else {

					p1_nodeVar57 = 0.0;

				}

				p1_nodeVar56 = p1_nodeVar57;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar59 = ( p1_nodeVar22.x - p1_nodeVar22.z );

				} else {

					p1_nodeVar59 = p1_nodeVar23;

				}

				p1_nodeVar56 = p1_nodeVar59;

			}

			p1_nodeVar53 = p1_nodeVar56;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar62 = max( max( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z );

				if ( ( p1_nodeVar62 > 0.001 ) ) {

					p1_nodeVar61 = ( ( p1_nodeVar62 - min( min( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z ) ) / p1_nodeVar62 );

				} else {

					p1_nodeVar61 = 0.0;

				}

				p1_nodeVar60 = p1_nodeVar61;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar63 = ( p1_nodeVar30.x - p1_nodeVar30.z );

				} else {

					p1_nodeVar63 = p1_nodeVar31;

				}

				p1_nodeVar60 = p1_nodeVar63;

			}

			p1_nodeVar53 = p1_nodeVar60;

		}


		if ( p1_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar67 = max( max( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z );

				if ( ( p1_nodeVar67 > 0.001 ) ) {

					p1_nodeVar66 = ( ( p1_nodeVar67 - min( min( p1_nodeVar30.x, p1_nodeVar30.y ), p1_nodeVar30.z ) ) / p1_nodeVar67 );

				} else {

					p1_nodeVar66 = 0.0;

				}

				p1_nodeVar65 = p1_nodeVar66;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar68 = ( p1_nodeVar30.x - p1_nodeVar30.z );

				} else {

					p1_nodeVar68 = p1_nodeVar31;

				}

				p1_nodeVar65 = p1_nodeVar68;

			}

			p1_nodeVar64 = p1_nodeVar65;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p1_nodeVar71 = max( max( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z );

				if ( ( p1_nodeVar71 > 0.001 ) ) {

					p1_nodeVar70 = ( ( p1_nodeVar71 - min( min( p1_nodeVar22.x, p1_nodeVar22.y ), p1_nodeVar22.z ) ) / p1_nodeVar71 );

				} else {

					p1_nodeVar70 = 0.0;

				}

				p1_nodeVar69 = p1_nodeVar70;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p1_nodeVar72 = ( p1_nodeVar22.x - p1_nodeVar22.z );

				} else {

					p1_nodeVar72 = p1_nodeVar23;

				}

				p1_nodeVar69 = p1_nodeVar72;

			}

			p1_nodeVar64 = p1_nodeVar69;

		}

		p1_nodeVar32 = ( p1_nodeVar53 > p1_nodeVar64 );

	}

	p1_nodeVar73 = ( ( ( ( p1_nodeVar1 >= 0.0 ) && ( p1_nodeVar1 < p1_nodeVar19 ) ) && ( ( ( p1_nodeVar23 > f32(knobs.threshold) ) && ( p1_nodeVar23 < f32(knobs.upperThreshold) ) ) || ( ( p1_nodeVar31 > f32(knobs.threshold) ) && ( p1_nodeVar31 < f32(knobs.upperThreshold) ) ) ) ) && p1_nodeVar32 );

	if ( p1_nodeVar73 ) {

		p1_nodeVar0 = p1_nodeVar30.x;

	} else {

		p1_nodeVar0 = p1_nodeVar22.x;

	}


	if ( p1_nodeVar73 ) {

		p1_nodeVar74 = p1_nodeVar30.y;

	} else {

		p1_nodeVar74 = p1_nodeVar22.y;

	}


	if ( p1_nodeVar73 ) {

		p1_nodeVar75 = p1_nodeVar30.z;

	} else {

		p1_nodeVar75 = p1_nodeVar22.z;

	}

	p1_DiffuseColor = vec4<f32>( p1_nodeVar0, p1_nodeVar74, p1_nodeVar75, 1.0 );
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_DiffuseColor.w = 1.0;
	p1_nodeVar76 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar76;

	// result

	p1_output.color = p1_nodeVar76;

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
var<private> p2_nodeVar0 : f32;
var<private> p2_nodeVar1 : f32;
var<private> p2_nodeVar2 : bool;
var<private> p2_nodeVar3 : f32;
var<private> p2_nodeVar4 : vec2<f32>;
var<private> p2_nodeVar5 : f32;
var<private> p2_nodeVar6 : f32;
var<private> p2_nodeVar7 : f32;
var<private> p2_nodeVar8 : vec2<f32>;
var<private> p2_nodeVar9 : f32;
var<private> p2_nodeVar10 : f32;
var<private> p2_nodeVar11 : f32;
var<private> p2_nodeVar12 : vec2<f32>;
var<private> p2_nodeVar13 : f32;
var<private> p2_nodeVar14 : f32;
var<private> p2_nodeVar15 : f32;
var<private> p2_nodeVar16 : vec2<f32>;
var<private> p2_nodeVar17 : f32;
var<private> p2_nodeVar18 : f32;
var<private> p2_nodeVar19 : f32;
var<private> p2_nodeVar20 : vec2<f32>;
var<private> p2_nodeVar21 : vec2<f32>;
var<private> p2_nodeVar22 : vec4<f32>;
var<private> p2_nodeVar23 : f32;
var<private> p2_nodeVar24 : f32;
var<private> p2_nodeVar25 : f32;
var<private> p2_nodeVar26 : f32;
var<private> p2_nodeVar27 : f32;
var<private> p2_nodeVar28 : f32;
var<private> p2_nodeVar29 : f32;
var<private> p2_nodeVar30 : vec4<f32>;
var<private> p2_nodeVar31 : f32;
var<private> p2_nodeVar32 : bool;
var<private> p2_nodeVar33 : f32;
var<private> p2_nodeVar34 : f32;
var<private> p2_nodeVar35 : bool;
var<private> p2_nodeVar36 : f32;
var<private> p2_nodeVar37 : f32;
var<private> p2_nodeVar38 : f32;
var<private> p2_nodeVar39 : f32;
var<private> p2_nodeVar40 : f32;
var<private> p2_nodeVar41 : f32;
var<private> p2_nodeVar42 : f32;
var<private> p2_nodeVar43 : f32;
var<private> p2_nodeVar44 : f32;
var<private> p2_nodeVar45 : f32;
var<private> p2_nodeVar46 : f32;
var<private> p2_nodeVar47 : f32;
var<private> p2_nodeVar48 : f32;
var<private> p2_nodeVar49 : f32;
var<private> p2_nodeVar50 : f32;
var<private> p2_nodeVar51 : f32;
var<private> p2_nodeVar52 : f32;
var<private> p2_nodeVar53 : f32;
var<private> p2_nodeVar54 : f32;
var<private> p2_nodeVar55 : bool;
var<private> p2_nodeVar56 : f32;
var<private> p2_nodeVar57 : f32;
var<private> p2_nodeVar58 : f32;
var<private> p2_nodeVar59 : f32;
var<private> p2_nodeVar60 : f32;
var<private> p2_nodeVar61 : f32;
var<private> p2_nodeVar62 : f32;
var<private> p2_nodeVar63 : f32;
var<private> p2_nodeVar64 : f32;
var<private> p2_nodeVar65 : f32;
var<private> p2_nodeVar66 : f32;
var<private> p2_nodeVar67 : f32;
var<private> p2_nodeVar68 : f32;
var<private> p2_nodeVar69 : f32;
var<private> p2_nodeVar70 : f32;
var<private> p2_nodeVar71 : f32;
var<private> p2_nodeVar72 : f32;
var<private> p2_nodeVar73 : bool;
var<private> p2_nodeVar74 : f32;
var<private> p2_nodeVar75 : f32;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar76 : vec4<f32>;

// codes
fn p2_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar2 = ( f32(knobs.direction) < 0.5 );

	if ( p2_nodeVar2 ) {


		if ( p2_nodeVar2 ) {

			p2_nodeVar4 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p2_nodeVar2 ) {

				p2_nodeVar6 = p2_nodeVar4.x;

			} else {

				p2_nodeVar6 = p2_nodeVar4.y;

			}


			if ( ( p2_tsl_mod_float( ( p2_nodeVar6 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p2_nodeVar5 = 1.0;

			} else {

				p2_nodeVar5 = -1.0;

			}

			p2_nodeVar3 = ( p2_nodeVar4.x + p2_nodeVar5 );

		} else {

			p2_nodeVar3 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p2_nodeVar2 ) {

			p2_nodeVar7 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p2_nodeVar8 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p2_nodeVar2 ) {

				p2_nodeVar10 = p2_nodeVar8.x;

			} else {

				p2_nodeVar10 = p2_nodeVar8.y;

			}


			if ( ( p2_tsl_mod_float( ( p2_nodeVar10 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p2_nodeVar9 = 1.0;

			} else {

				p2_nodeVar9 = -1.0;

			}

			p2_nodeVar7 = ( p2_nodeVar8.y + p2_nodeVar9 );

		}

		p2_nodeVar1 = vec2<f32>( p2_nodeVar3, p2_nodeVar7 ).x;

	} else {


		if ( p2_nodeVar2 ) {

			p2_nodeVar12 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p2_nodeVar2 ) {

				p2_nodeVar14 = p2_nodeVar12.x;

			} else {

				p2_nodeVar14 = p2_nodeVar12.y;

			}


			if ( ( p2_tsl_mod_float( ( p2_nodeVar14 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p2_nodeVar13 = 1.0;

			} else {

				p2_nodeVar13 = -1.0;

			}

			p2_nodeVar11 = ( p2_nodeVar12.x + p2_nodeVar13 );

		} else {

			p2_nodeVar11 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).x;

		}


		if ( p2_nodeVar2 ) {

			p2_nodeVar15 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) ).y;

		} else {

			p2_nodeVar16 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) ) ) );

			if ( p2_nodeVar2 ) {

				p2_nodeVar18 = p2_nodeVar16.x;

			} else {

				p2_nodeVar18 = p2_nodeVar16.y;

			}


			if ( ( p2_tsl_mod_float( ( p2_nodeVar18 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

				p2_nodeVar17 = 1.0;

			} else {

				p2_nodeVar17 = -1.0;

			}

			p2_nodeVar15 = ( p2_nodeVar16.y + p2_nodeVar17 );

		}

		p2_nodeVar1 = vec2<f32>( p2_nodeVar11, p2_nodeVar15 ).y;

	}


	if ( p2_nodeVar2 ) {

		p2_nodeVar19 = f32(knobs.resolution.x);

	} else {

		p2_nodeVar19 = f32(knobs.resolution.y);

	}

	p2_nodeVar20 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p2_nodeVar21 = floor( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * p2_nodeVar20 ) );
	p2_nodeVar22 = target_read( t1, t1_sampler, ( ( p2_nodeVar21 + vec2<f32>( 0.5 ) ) / p2_nodeVar20 ) );
	p2_nodeVar23 = dot( vec3<f32>( p2_nodeVar22.x, p2_nodeVar22.y, p2_nodeVar22.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( p2_nodeVar2 ) {


		if ( p2_nodeVar2 ) {

			p2_nodeVar26 = p2_nodeVar21.x;

		} else {

			p2_nodeVar26 = p2_nodeVar21.y;

		}


		if ( ( p2_tsl_mod_float( ( p2_nodeVar26 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

			p2_nodeVar25 = 1.0;

		} else {

			p2_nodeVar25 = -1.0;

		}

		p2_nodeVar24 = ( p2_nodeVar21.x + p2_nodeVar25 );

	} else {

		p2_nodeVar24 = p2_nodeVar21.x;

	}


	if ( p2_nodeVar2 ) {

		p2_nodeVar27 = p2_nodeVar21.y;

	} else {


		if ( p2_nodeVar2 ) {

			p2_nodeVar29 = p2_nodeVar21.x;

		} else {

			p2_nodeVar29 = p2_nodeVar21.y;

		}


		if ( ( p2_tsl_mod_float( ( p2_nodeVar29 + f32(0.0) ), 2.0 ) < 1.0 ) ) {

			p2_nodeVar28 = 1.0;

		} else {

			p2_nodeVar28 = -1.0;

		}

		p2_nodeVar27 = ( p2_nodeVar21.y + p2_nodeVar28 );

	}

	p2_nodeVar30 = target_read( t1, t1_sampler, ( ( vec2<f32>( p2_nodeVar24, p2_nodeVar27 ) + vec2<f32>( 0.5 ) ) / p2_nodeVar20 ) );
	p2_nodeVar31 = dot( vec3<f32>( p2_nodeVar30.x, p2_nodeVar30.y, p2_nodeVar30.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) );

	if ( ( f32(knobs.reverse) > 0.5 ) ) {


		if ( p2_nodeVar2 ) {

			p2_nodeVar34 = p2_nodeVar21.x;

		} else {

			p2_nodeVar34 = p2_nodeVar21.y;

		}

		p2_nodeVar35 = ( p2_tsl_mod_float( ( p2_nodeVar34 + f32(0.0) ), 2.0 ) < 1.0 );

		if ( p2_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar38 = max( max( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z );

				if ( ( p2_nodeVar38 > 0.001 ) ) {

					p2_nodeVar37 = ( ( p2_nodeVar38 - min( min( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z ) ) / p2_nodeVar38 );

				} else {

					p2_nodeVar37 = 0.0;

				}

				p2_nodeVar36 = p2_nodeVar37;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar39 = ( p2_nodeVar30.x - p2_nodeVar30.z );

				} else {

					p2_nodeVar39 = p2_nodeVar31;

				}

				p2_nodeVar36 = p2_nodeVar39;

			}

			p2_nodeVar33 = p2_nodeVar36;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar42 = max( max( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z );

				if ( ( p2_nodeVar42 > 0.001 ) ) {

					p2_nodeVar41 = ( ( p2_nodeVar42 - min( min( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z ) ) / p2_nodeVar42 );

				} else {

					p2_nodeVar41 = 0.0;

				}

				p2_nodeVar40 = p2_nodeVar41;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar43 = ( p2_nodeVar22.x - p2_nodeVar22.z );

				} else {

					p2_nodeVar43 = p2_nodeVar23;

				}

				p2_nodeVar40 = p2_nodeVar43;

			}

			p2_nodeVar33 = p2_nodeVar40;

		}


		if ( p2_nodeVar35 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar47 = max( max( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z );

				if ( ( p2_nodeVar47 > 0.001 ) ) {

					p2_nodeVar46 = ( ( p2_nodeVar47 - min( min( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z ) ) / p2_nodeVar47 );

				} else {

					p2_nodeVar46 = 0.0;

				}

				p2_nodeVar45 = p2_nodeVar46;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar48 = ( p2_nodeVar22.x - p2_nodeVar22.z );

				} else {

					p2_nodeVar48 = p2_nodeVar23;

				}

				p2_nodeVar45 = p2_nodeVar48;

			}

			p2_nodeVar44 = p2_nodeVar45;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar51 = max( max( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z );

				if ( ( p2_nodeVar51 > 0.001 ) ) {

					p2_nodeVar50 = ( ( p2_nodeVar51 - min( min( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z ) ) / p2_nodeVar51 );

				} else {

					p2_nodeVar50 = 0.0;

				}

				p2_nodeVar49 = p2_nodeVar50;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar52 = ( p2_nodeVar30.x - p2_nodeVar30.z );

				} else {

					p2_nodeVar52 = p2_nodeVar31;

				}

				p2_nodeVar49 = p2_nodeVar52;

			}

			p2_nodeVar44 = p2_nodeVar49;

		}

		p2_nodeVar32 = ( p2_nodeVar33 > p2_nodeVar44 );

	} else {


		if ( p2_nodeVar2 ) {

			p2_nodeVar54 = p2_nodeVar21.x;

		} else {

			p2_nodeVar54 = p2_nodeVar21.y;

		}

		p2_nodeVar55 = ( p2_tsl_mod_float( ( p2_nodeVar54 + f32(0.0) ), 2.0 ) < 1.0 );

		if ( p2_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar58 = max( max( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z );

				if ( ( p2_nodeVar58 > 0.001 ) ) {

					p2_nodeVar57 = ( ( p2_nodeVar58 - min( min( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z ) ) / p2_nodeVar58 );

				} else {

					p2_nodeVar57 = 0.0;

				}

				p2_nodeVar56 = p2_nodeVar57;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar59 = ( p2_nodeVar22.x - p2_nodeVar22.z );

				} else {

					p2_nodeVar59 = p2_nodeVar23;

				}

				p2_nodeVar56 = p2_nodeVar59;

			}

			p2_nodeVar53 = p2_nodeVar56;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar62 = max( max( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z );

				if ( ( p2_nodeVar62 > 0.001 ) ) {

					p2_nodeVar61 = ( ( p2_nodeVar62 - min( min( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z ) ) / p2_nodeVar62 );

				} else {

					p2_nodeVar61 = 0.0;

				}

				p2_nodeVar60 = p2_nodeVar61;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar63 = ( p2_nodeVar30.x - p2_nodeVar30.z );

				} else {

					p2_nodeVar63 = p2_nodeVar31;

				}

				p2_nodeVar60 = p2_nodeVar63;

			}

			p2_nodeVar53 = p2_nodeVar60;

		}


		if ( p2_nodeVar55 ) {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar67 = max( max( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z );

				if ( ( p2_nodeVar67 > 0.001 ) ) {

					p2_nodeVar66 = ( ( p2_nodeVar67 - min( min( p2_nodeVar30.x, p2_nodeVar30.y ), p2_nodeVar30.z ) ) / p2_nodeVar67 );

				} else {

					p2_nodeVar66 = 0.0;

				}

				p2_nodeVar65 = p2_nodeVar66;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar68 = ( p2_nodeVar30.x - p2_nodeVar30.z );

				} else {

					p2_nodeVar68 = p2_nodeVar31;

				}

				p2_nodeVar65 = p2_nodeVar68;

			}

			p2_nodeVar64 = p2_nodeVar65;

		} else {


			if ( ( f32(knobs.mode) > 1.5 ) ) {

				p2_nodeVar71 = max( max( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z );

				if ( ( p2_nodeVar71 > 0.001 ) ) {

					p2_nodeVar70 = ( ( p2_nodeVar71 - min( min( p2_nodeVar22.x, p2_nodeVar22.y ), p2_nodeVar22.z ) ) / p2_nodeVar71 );

				} else {

					p2_nodeVar70 = 0.0;

				}

				p2_nodeVar69 = p2_nodeVar70;

			} else {


				if ( ( f32(knobs.mode) > 0.5 ) ) {

					p2_nodeVar72 = ( p2_nodeVar22.x - p2_nodeVar22.z );

				} else {

					p2_nodeVar72 = p2_nodeVar23;

				}

				p2_nodeVar69 = p2_nodeVar72;

			}

			p2_nodeVar64 = p2_nodeVar69;

		}

		p2_nodeVar32 = ( p2_nodeVar53 > p2_nodeVar64 );

	}

	p2_nodeVar73 = ( ( ( ( p2_nodeVar1 >= 0.0 ) && ( p2_nodeVar1 < p2_nodeVar19 ) ) && ( ( ( p2_nodeVar23 > f32(knobs.threshold) ) && ( p2_nodeVar23 < f32(knobs.upperThreshold) ) ) || ( ( p2_nodeVar31 > f32(knobs.threshold) ) && ( p2_nodeVar31 < f32(knobs.upperThreshold) ) ) ) ) && p2_nodeVar32 );

	if ( p2_nodeVar73 ) {

		p2_nodeVar0 = p2_nodeVar30.x;

	} else {

		p2_nodeVar0 = p2_nodeVar22.x;

	}


	if ( p2_nodeVar73 ) {

		p2_nodeVar74 = p2_nodeVar30.y;

	} else {

		p2_nodeVar74 = p2_nodeVar22.y;

	}


	if ( p2_nodeVar73 ) {

		p2_nodeVar75 = p2_nodeVar30.z;

	} else {

		p2_nodeVar75 = p2_nodeVar22.z;

	}

	p2_DiffuseColor = vec4<f32>( p2_nodeVar0, p2_nodeVar74, p2_nodeVar75, 1.0 );
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_DiffuseColor.w = 1.0;
	p2_nodeVar76 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar76;

	// result

	p2_output.color = p2_nodeVar76;

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
var<private> p3_nodeVar1 : vec4<f32>;
var<private> p3_nodeVar2 : vec4<f32>;
var<private> p3_nodeVar3 : vec3<f32>;
var<private> p3_nodeVar4 : f32;
var<private> p3_nodeVar5 : vec3<f32>;
var<private> p3_nodeVar6 : vec4<f32>;
var<private> p3_Output : vec4<f32>;
var<private> p3_nodeVar7 : vec4<f32>;

// codes


fn p3_main(door_uv: vec2f) -> p3_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p3_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p3_nodeVar1 = target_read( t1, t1_sampler, vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p3_nodeVar2 = vec4<f32>( p3_nodeVar1.x, p3_nodeVar1.y, p3_nodeVar1.z, 1.0 );
	p3_nodeVar3 = vec3<f32>( p3_nodeVar2.x, p3_nodeVar2.y, p3_nodeVar2.z );
	p3_nodeVar4 = ( ( ( p3_nodeVar3.x * 0.2126 ) + ( p3_nodeVar3.y * 0.7152 ) ) + ( p3_nodeVar3.z * 0.0722 ) );
	p3_nodeVar5 = mix( vec3<f32>( p3_nodeVar4, p3_nodeVar4, p3_nodeVar4 ), p3_nodeVar3, f32(1.0) );
	p3_nodeVar6 = vec4<f32>( clamp( vec3<f32>( ( ( ( p3_nodeVar5.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p3_nodeVar5.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p3_nodeVar5.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p3_nodeVar5.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p3_nodeVar5.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p3_nodeVar5.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p3_nodeVar5.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p3_nodeVar5.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p3_nodeVar5.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p3_nodeVar2.w, 0.0, 1.0 ) );
	p3_DiffuseColor = vec4<f32>( mix( p3_nodeVar0.xyz, p3_nodeVar6.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p3_nodeVar6.w, 0.0, 1.0 ) ) ), clamp( p3_nodeVar0.w, 0.0, 1.0 ) );
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_nodeVar7 = max( vec4<f32>( p3_DiffuseColor.xyz, p3_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p3_Output = p3_nodeVar7;

	// result

	p3_output.color = p3_nodeVar7;

	return p3_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  switch u32(knobs.passindex + 0.5) {
    case 0u: { return p0_main(door_uv).color; }
    case 1u, 3u, 5u, 7u, 9u, 11u, 13u, 15u, 17u, 19u, 21u, 23u, 25u, 27u, 29u, 31u, 33u, 35u, 37u, 39u, 41u, 43u, 45u, 47u, 49u, 51u, 53u, 55u, 57u, 59u, 61u, 63u, 65u, 67u, 69u, 71u, 73u, 75u, 77u, 79u, 81u, 83u, 85u, 87u, 89u: { return p1_main(door_uv).color; }
    case 2u, 4u, 6u, 8u, 10u, 12u, 14u, 16u, 18u, 20u, 22u, 24u, 26u, 28u, 30u, 32u, 34u, 36u, 38u, 40u, 42u, 44u, 46u, 48u, 50u, 52u, 54u, 56u, 58u, 60u, 62u, 64u, 66u, 68u, 70u, 72u, 74u, 76u, 78u, 80u, 82u, 84u, 86u, 88u: { return p2_main(door_uv).color; }
    default: {}
  }
  return to_shelf(p3_main(door_uv).color);
}

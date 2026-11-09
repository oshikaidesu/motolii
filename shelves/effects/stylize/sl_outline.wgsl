// Outline: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Draws outlines around text, cutouts or the shapes in the image: solid, double, dashed or scalloped, repeated as rings.
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@t0:0,1,s1,s1
// --pass@t1:0,1,s1,s1
// --pass@:0,0,s1,s1
// --track@source:Outline,0,2,0,1
// --track@threshold:Threshold,0.01,1,0.5,0.01
// --track@style:Style,0,3,0,1
// --track@ringGap:Ring Gap,1,120,8,0.5
// --track@lineColor_x:Line Color r,0,1,0.005605391621829108,0.001
// --track@lineColor_y:Line Color g,0,1,0.005605391621829108,0.001
// --track@lineColor_z:Line Color b,0,1,0.005605391621829108,0.001
// --track@fill:Fill,0,1,0,0.01
// --track@fillColor_x:Fill Color r,0,1,1,0.001
// --track@fillColor_y:Fill Color g,0,1,1,0.001
// --track@fillColor_z:Fill Color b,0,1,1,0.001
// --check@showImage:Show Image,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  source: f32,
  threshold: f32,
  style: f32,
  ringGap: f32,
  lineColor: vec3<f32>,
  fill: f32,
  fillColor: vec3<f32>,
  showImage: f32,
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
var<private> p0_nodeVar1 : vec4<f32>;
var<private> p0_nodeVar2 : vec4<f32>;
var<private> p0_nodeVar3 : f32;
var<private> p0_nodeVar4 : f32;
var<private> p0_nodeVar5 : f32;
var<private> p0_nodeVar6 : f32;
var<private> p0_nodeVar7 : f32;
var<private> p0_nodeVar8 : f32;
var<private> p0_nodeVar9 : f32;
var<private> p0_nodeVar10 : f32;
var<private> p0_nodeVar11 : vec4<f32>;
var<private> p0_nodeVar12 : vec4<f32>;
var<private> p0_nodeVar13 : f32;
var<private> p0_nodeVar14 : f32;
var<private> p0_nodeVar15 : f32;
var<private> p0_nodeVar16 : f32;
var<private> p0_nodeVar17 : f32;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : vec4<f32>;
var<private> p0_nodeVar22 : vec4<f32>;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : vec4<f32>;
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : f32;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_nodeVar38 : f32;
var<private> p0_nodeVar39 : f32;
var<private> p0_nodeVar40 : f32;
var<private> p0_nodeVar41 : vec4<f32>;
var<private> p0_nodeVar42 : vec4<f32>;
var<private> p0_nodeVar43 : f32;
var<private> p0_nodeVar44 : f32;
var<private> p0_nodeVar45 : f32;
var<private> p0_nodeVar46 : f32;
var<private> p0_nodeVar47 : f32;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : f32;
var<private> p0_nodeVar51 : vec4<f32>;
var<private> p0_nodeVar52 : vec4<f32>;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : vec4<f32>;
var<private> p0_nodeVar62 : vec4<f32>;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : f32;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : vec2<f32>;
var<private> p0_nodeVar72 : bool;
var<private> p0_nodeVar73 : vec2<f32>;
var<private> p0_nodeVar74 : vec2<f32>;
var<private> p0_nodeVar75 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar76 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p0_nodeVar1 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) ) );
	p0_nodeVar2 = p0_nodeVar1;
	p0_nodeVar3 = clamp( p0_nodeVar2.w, 0.0, 1.0 );
	p0_nodeVar4 = p0_nodeVar3;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar7 = clamp( dot( vec3<f32>( p0_nodeVar2.x, p0_nodeVar2.y, p0_nodeVar2.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar7 <= 0.0031308 ) ) {

				p0_nodeVar6 = ( p0_nodeVar7 * 12.92 );

			} else {

				p0_nodeVar6 = ( ( pow( p0_nodeVar7, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar5 = ( ( 1.0 - p0_nodeVar6 ) * p0_nodeVar3 );

		} else {

			p0_nodeVar9 = clamp( dot( vec3<f32>( p0_nodeVar2.x, p0_nodeVar2.y, p0_nodeVar2.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar9 <= 0.0031308 ) ) {

				p0_nodeVar8 = ( p0_nodeVar9 * 12.92 );

			} else {

				p0_nodeVar8 = ( ( pow( p0_nodeVar9, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar5 = ( p0_nodeVar8 * p0_nodeVar3 );

		}

		p0_nodeVar4 = p0_nodeVar5;
		

	}

	p0_nodeVar10 = step( f32(knobs.threshold), p0_nodeVar4 );
	p0_nodeVar11 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) ) );
	p0_nodeVar12 = p0_nodeVar11;
	p0_nodeVar13 = clamp( p0_nodeVar12.w, 0.0, 1.0 );
	p0_nodeVar14 = p0_nodeVar13;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar17 = clamp( dot( vec3<f32>( p0_nodeVar12.x, p0_nodeVar12.y, p0_nodeVar12.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar17 <= 0.0031308 ) ) {

				p0_nodeVar16 = ( p0_nodeVar17 * 12.92 );

			} else {

				p0_nodeVar16 = ( ( pow( p0_nodeVar17, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar15 = ( ( 1.0 - p0_nodeVar16 ) * p0_nodeVar13 );

		} else {

			p0_nodeVar19 = clamp( dot( vec3<f32>( p0_nodeVar12.x, p0_nodeVar12.y, p0_nodeVar12.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar19 <= 0.0031308 ) ) {

				p0_nodeVar18 = ( p0_nodeVar19 * 12.92 );

			} else {

				p0_nodeVar18 = ( ( pow( p0_nodeVar19, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar15 = ( p0_nodeVar18 * p0_nodeVar13 );

		}

		p0_nodeVar14 = p0_nodeVar15;
		

	}

	p0_nodeVar20 = step( f32(knobs.threshold), p0_nodeVar14 );
	p0_nodeVar21 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) ) );
	p0_nodeVar22 = p0_nodeVar21;
	p0_nodeVar23 = clamp( p0_nodeVar22.w, 0.0, 1.0 );
	p0_nodeVar24 = p0_nodeVar23;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar27 = clamp( dot( vec3<f32>( p0_nodeVar22.x, p0_nodeVar22.y, p0_nodeVar22.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar27 <= 0.0031308 ) ) {

				p0_nodeVar26 = ( p0_nodeVar27 * 12.92 );

			} else {

				p0_nodeVar26 = ( ( pow( p0_nodeVar27, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar25 = ( ( 1.0 - p0_nodeVar26 ) * p0_nodeVar23 );

		} else {

			p0_nodeVar29 = clamp( dot( vec3<f32>( p0_nodeVar22.x, p0_nodeVar22.y, p0_nodeVar22.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar29 <= 0.0031308 ) ) {

				p0_nodeVar28 = ( p0_nodeVar29 * 12.92 );

			} else {

				p0_nodeVar28 = ( ( pow( p0_nodeVar29, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar25 = ( p0_nodeVar28 * p0_nodeVar23 );

		}

		p0_nodeVar24 = p0_nodeVar25;
		

	}

	p0_nodeVar30 = step( f32(knobs.threshold), p0_nodeVar24 );
	p0_nodeVar31 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) ) );
	p0_nodeVar32 = p0_nodeVar31;
	p0_nodeVar33 = clamp( p0_nodeVar32.w, 0.0, 1.0 );
	p0_nodeVar34 = p0_nodeVar33;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar37 = clamp( dot( vec3<f32>( p0_nodeVar32.x, p0_nodeVar32.y, p0_nodeVar32.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar37 <= 0.0031308 ) ) {

				p0_nodeVar36 = ( p0_nodeVar37 * 12.92 );

			} else {

				p0_nodeVar36 = ( ( pow( p0_nodeVar37, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar35 = ( ( 1.0 - p0_nodeVar36 ) * p0_nodeVar33 );

		} else {

			p0_nodeVar39 = clamp( dot( vec3<f32>( p0_nodeVar32.x, p0_nodeVar32.y, p0_nodeVar32.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar39 <= 0.0031308 ) ) {

				p0_nodeVar38 = ( p0_nodeVar39 * 12.92 );

			} else {

				p0_nodeVar38 = ( ( pow( p0_nodeVar39, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar35 = ( p0_nodeVar38 * p0_nodeVar33 );

		}

		p0_nodeVar34 = p0_nodeVar35;
		

	}

	p0_nodeVar40 = step( f32(knobs.threshold), p0_nodeVar34 );
	p0_nodeVar41 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) ) );
	p0_nodeVar42 = p0_nodeVar41;
	p0_nodeVar43 = clamp( p0_nodeVar42.w, 0.0, 1.0 );
	p0_nodeVar44 = p0_nodeVar43;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar47 = clamp( dot( vec3<f32>( p0_nodeVar42.x, p0_nodeVar42.y, p0_nodeVar42.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar47 <= 0.0031308 ) ) {

				p0_nodeVar46 = ( p0_nodeVar47 * 12.92 );

			} else {

				p0_nodeVar46 = ( ( pow( p0_nodeVar47, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar45 = ( ( 1.0 - p0_nodeVar46 ) * p0_nodeVar43 );

		} else {

			p0_nodeVar49 = clamp( dot( vec3<f32>( p0_nodeVar42.x, p0_nodeVar42.y, p0_nodeVar42.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar49 <= 0.0031308 ) ) {

				p0_nodeVar48 = ( p0_nodeVar49 * 12.92 );

			} else {

				p0_nodeVar48 = ( ( pow( p0_nodeVar49, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar45 = ( p0_nodeVar48 * p0_nodeVar43 );

		}

		p0_nodeVar44 = p0_nodeVar45;
		

	}

	p0_nodeVar50 = step( f32(knobs.threshold), p0_nodeVar44 );
	p0_nodeVar51 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) ) );
	p0_nodeVar52 = p0_nodeVar51;
	p0_nodeVar53 = clamp( p0_nodeVar52.w, 0.0, 1.0 );
	p0_nodeVar54 = p0_nodeVar53;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar57 = clamp( dot( vec3<f32>( p0_nodeVar52.x, p0_nodeVar52.y, p0_nodeVar52.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar57 <= 0.0031308 ) ) {

				p0_nodeVar56 = ( p0_nodeVar57 * 12.92 );

			} else {

				p0_nodeVar56 = ( ( pow( p0_nodeVar57, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar55 = ( ( 1.0 - p0_nodeVar56 ) * p0_nodeVar53 );

		} else {

			p0_nodeVar59 = clamp( dot( vec3<f32>( p0_nodeVar52.x, p0_nodeVar52.y, p0_nodeVar52.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar59 <= 0.0031308 ) ) {

				p0_nodeVar58 = ( p0_nodeVar59 * 12.92 );

			} else {

				p0_nodeVar58 = ( ( pow( p0_nodeVar59, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar55 = ( p0_nodeVar58 * p0_nodeVar53 );

		}

		p0_nodeVar54 = p0_nodeVar55;
		

	}

	p0_nodeVar60 = step( f32(knobs.threshold), p0_nodeVar54 );
	p0_nodeVar61 = picture_read( ( p0_nodeVar0 + vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) ) );
	p0_nodeVar62 = p0_nodeVar61;
	p0_nodeVar63 = clamp( p0_nodeVar62.w, 0.0, 1.0 );
	p0_nodeVar64 = p0_nodeVar63;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p0_nodeVar67 = clamp( dot( vec3<f32>( p0_nodeVar62.x, p0_nodeVar62.y, p0_nodeVar62.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar67 <= 0.0031308 ) ) {

				p0_nodeVar66 = ( p0_nodeVar67 * 12.92 );

			} else {

				p0_nodeVar66 = ( ( pow( p0_nodeVar67, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar65 = ( ( 1.0 - p0_nodeVar66 ) * p0_nodeVar63 );

		} else {

			p0_nodeVar69 = clamp( dot( vec3<f32>( p0_nodeVar62.x, p0_nodeVar62.y, p0_nodeVar62.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p0_nodeVar69 <= 0.0031308 ) ) {

				p0_nodeVar68 = ( p0_nodeVar69 * 12.92 );

			} else {

				p0_nodeVar68 = ( ( pow( p0_nodeVar69, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p0_nodeVar65 = ( p0_nodeVar68 * p0_nodeVar63 );

		}

		p0_nodeVar64 = p0_nodeVar65;
		

	}

	p0_nodeVar70 = step( f32(knobs.threshold), p0_nodeVar64 );
	p0_nodeVar72 = ( ( p0_nodeVar10 * ( 1.0 - min( min( p0_nodeVar20, p0_nodeVar30 ), min( p0_nodeVar40, p0_nodeVar50 ) ) ) ) > 0.5 );

	if ( p0_nodeVar72 ) {

		p0_nodeVar71 = ( p0_nodeVar0 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );

	} else {

		p0_nodeVar71 = vec2<f32>( 100000.0, 100000.0 );

	}

	p0_nodeVar74 = ( p0_nodeVar0 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p0_nodeVar75 = max( ( f32(18.0) * f32(1.0) ), 2.0 );

	if ( ( p0_nodeVar72 && ( ( ( abs( ( floor( ( p0_nodeVar74.x / p0_nodeVar75 ) ) - floor( ( ( p0_nodeVar74.x - 1.0 ) / p0_nodeVar75 ) ) ) ) > 0.5 ) || ( abs( ( floor( ( p0_nodeVar74.y / p0_nodeVar75 ) ) - floor( ( ( p0_nodeVar74.y - 1.0 ) / p0_nodeVar75 ) ) ) ) > 0.5 ) ) || ( ( ( ( p0_nodeVar72 && ( p0_nodeVar30 < 0.5 ) ) && ( p0_nodeVar50 < 0.5 ) ) && ( p0_nodeVar60 < 0.5 ) ) && ( p0_nodeVar70 < 0.5 ) ) ) ) ) {

		p0_nodeVar73 = p0_nodeVar74;

	} else {

		p0_nodeVar73 = vec2<f32>( 100000.0, 100000.0 );

	}

	p0_DiffuseColor = vec4<f32>( p0_nodeVar71, p0_nodeVar73 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
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
var<private> p1_nodeVar0 : vec4<f32>;
var<private> p1_nodeVar1 : f32;
var<private> p1_nodeVar2 : f32;
var<private> p1_nodeVar3 : vec2<f32>;
var<private> p1_nodeVar4 : vec2<f32>;
var<private> p1_nodeVar5 : vec4<f32>;
var<private> p1_nodeVar6 : vec2<f32>;
var<private> p1_nodeVar7 : f32;
var<private> p1_nodeVar8 : bool;
var<private> p1_nodeVar9 : f32;
var<private> p1_nodeVar10 : vec2<f32>;
var<private> p1_nodeVar11 : f32;
var<private> p1_nodeVar12 : bool;
var<private> p1_nodeVar13 : f32;
var<private> p1_nodeVar14 : vec2<f32>;
var<private> p1_nodeVar15 : vec4<f32>;
var<private> p1_nodeVar16 : f32;
var<private> p1_nodeVar17 : bool;
var<private> p1_nodeVar18 : f32;
var<private> p1_nodeVar19 : vec2<f32>;
var<private> p1_nodeVar20 : f32;
var<private> p1_nodeVar21 : bool;
var<private> p1_nodeVar22 : f32;
var<private> p1_nodeVar23 : vec2<f32>;
var<private> p1_nodeVar24 : vec4<f32>;
var<private> p1_nodeVar25 : f32;
var<private> p1_nodeVar26 : bool;
var<private> p1_nodeVar27 : f32;
var<private> p1_nodeVar28 : vec2<f32>;
var<private> p1_nodeVar29 : f32;
var<private> p1_nodeVar30 : bool;
var<private> p1_nodeVar31 : f32;
var<private> p1_nodeVar32 : vec2<f32>;
var<private> p1_nodeVar33 : vec4<f32>;
var<private> p1_nodeVar34 : f32;
var<private> p1_nodeVar35 : bool;
var<private> p1_nodeVar36 : f32;
var<private> p1_nodeVar37 : vec2<f32>;
var<private> p1_nodeVar38 : f32;
var<private> p1_nodeVar39 : bool;
var<private> p1_nodeVar40 : f32;
var<private> p1_nodeVar41 : vec2<f32>;
var<private> p1_nodeVar42 : vec4<f32>;
var<private> p1_nodeVar43 : f32;
var<private> p1_nodeVar44 : bool;
var<private> p1_nodeVar45 : f32;
var<private> p1_nodeVar46 : vec2<f32>;
var<private> p1_nodeVar47 : f32;
var<private> p1_nodeVar48 : bool;
var<private> p1_nodeVar49 : f32;
var<private> p1_nodeVar50 : vec2<f32>;
var<private> p1_nodeVar51 : vec4<f32>;
var<private> p1_nodeVar52 : f32;
var<private> p1_nodeVar53 : bool;
var<private> p1_nodeVar54 : f32;
var<private> p1_nodeVar55 : vec2<f32>;
var<private> p1_nodeVar56 : f32;
var<private> p1_nodeVar57 : bool;
var<private> p1_nodeVar58 : f32;
var<private> p1_nodeVar59 : vec2<f32>;
var<private> p1_nodeVar60 : vec4<f32>;
var<private> p1_nodeVar61 : f32;
var<private> p1_nodeVar62 : bool;
var<private> p1_nodeVar63 : f32;
var<private> p1_nodeVar64 : vec2<f32>;
var<private> p1_nodeVar65 : f32;
var<private> p1_nodeVar66 : bool;
var<private> p1_nodeVar67 : f32;
var<private> p1_nodeVar68 : vec2<f32>;
var<private> p1_nodeVar69 : vec4<f32>;
var<private> p1_nodeVar70 : f32;
var<private> p1_nodeVar71 : bool;
var<private> p1_nodeVar72 : f32;
var<private> p1_nodeVar73 : vec2<f32>;
var<private> p1_nodeVar74 : f32;
var<private> p1_nodeVar75 : bool;
var<private> p1_nodeVar76 : f32;
var<private> p1_nodeVar77 : vec2<f32>;
var<private> p1_nodeVar78 : vec4<f32>;
var<private> p1_nodeVar79 : f32;
var<private> p1_nodeVar80 : bool;
var<private> p1_nodeVar81 : f32;
var<private> p1_nodeVar82 : vec2<f32>;
var<private> p1_nodeVar83 : f32;
var<private> p1_nodeVar84 : bool;
var<private> p1_nodeVar85 : f32;
var<private> p1_Output : vec4<f32>;
var<private> p1_nodeVar86 : vec4<f32>;

// codes


fn p1_main(door_uv: vec2f) -> p1_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p1_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p1_nodeVar1 = 400000.0;
	p1_nodeVar2 = 400000.0;
	p1_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p1_nodeVar5 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar6 = ( p1_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p1_nodeVar7 = length( ( vec2<f32>( p1_nodeVar5.x, p1_nodeVar5.y ) - p1_nodeVar6 ) );
	p1_nodeVar8 = ( p1_nodeVar7 < p1_nodeVar1 );

	if ( p1_nodeVar8 ) {

		p1_nodeVar3 = vec2<f32>( p1_nodeVar5.x, p1_nodeVar5.y );

	} else {

		p1_nodeVar3 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar3, p1_nodeVar0.zw );

	if ( p1_nodeVar8 ) {

		p1_nodeVar9 = p1_nodeVar7;

	} else {

		p1_nodeVar9 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar9;
	p1_nodeVar11 = length( ( vec2<f32>( p1_nodeVar5.z, p1_nodeVar5.w ) - p1_nodeVar6 ) );
	p1_nodeVar12 = ( p1_nodeVar11 < p1_nodeVar2 );

	if ( p1_nodeVar12 ) {

		p1_nodeVar10 = vec2<f32>( p1_nodeVar5.z, p1_nodeVar5.w );

	} else {

		p1_nodeVar10 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar10 );

	if ( p1_nodeVar12 ) {

		p1_nodeVar13 = p1_nodeVar11;

	} else {

		p1_nodeVar13 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar13;
	p1_nodeVar15 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar16 = length( ( vec2<f32>( p1_nodeVar15.x, p1_nodeVar15.y ) - p1_nodeVar6 ) );
	p1_nodeVar17 = ( p1_nodeVar16 < p1_nodeVar1 );

	if ( p1_nodeVar17 ) {

		p1_nodeVar14 = vec2<f32>( p1_nodeVar15.x, p1_nodeVar15.y );

	} else {

		p1_nodeVar14 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar14, p1_nodeVar0.zw );

	if ( p1_nodeVar17 ) {

		p1_nodeVar18 = p1_nodeVar16;

	} else {

		p1_nodeVar18 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar18;
	p1_nodeVar20 = length( ( vec2<f32>( p1_nodeVar15.z, p1_nodeVar15.w ) - p1_nodeVar6 ) );
	p1_nodeVar21 = ( p1_nodeVar20 < p1_nodeVar2 );

	if ( p1_nodeVar21 ) {

		p1_nodeVar19 = vec2<f32>( p1_nodeVar15.z, p1_nodeVar15.w );

	} else {

		p1_nodeVar19 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar19 );

	if ( p1_nodeVar21 ) {

		p1_nodeVar22 = p1_nodeVar20;

	} else {

		p1_nodeVar22 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar22;
	p1_nodeVar24 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar25 = length( ( vec2<f32>( p1_nodeVar24.x, p1_nodeVar24.y ) - p1_nodeVar6 ) );
	p1_nodeVar26 = ( p1_nodeVar25 < p1_nodeVar1 );

	if ( p1_nodeVar26 ) {

		p1_nodeVar23 = vec2<f32>( p1_nodeVar24.x, p1_nodeVar24.y );

	} else {

		p1_nodeVar23 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar23, p1_nodeVar0.zw );

	if ( p1_nodeVar26 ) {

		p1_nodeVar27 = p1_nodeVar25;

	} else {

		p1_nodeVar27 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar27;
	p1_nodeVar29 = length( ( vec2<f32>( p1_nodeVar24.z, p1_nodeVar24.w ) - p1_nodeVar6 ) );
	p1_nodeVar30 = ( p1_nodeVar29 < p1_nodeVar2 );

	if ( p1_nodeVar30 ) {

		p1_nodeVar28 = vec2<f32>( p1_nodeVar24.z, p1_nodeVar24.w );

	} else {

		p1_nodeVar28 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar28 );

	if ( p1_nodeVar30 ) {

		p1_nodeVar31 = p1_nodeVar29;

	} else {

		p1_nodeVar31 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar31;
	p1_nodeVar33 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar34 = length( ( vec2<f32>( p1_nodeVar33.x, p1_nodeVar33.y ) - p1_nodeVar6 ) );
	p1_nodeVar35 = ( p1_nodeVar34 < p1_nodeVar1 );

	if ( p1_nodeVar35 ) {

		p1_nodeVar32 = vec2<f32>( p1_nodeVar33.x, p1_nodeVar33.y );

	} else {

		p1_nodeVar32 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar32, p1_nodeVar0.zw );

	if ( p1_nodeVar35 ) {

		p1_nodeVar36 = p1_nodeVar34;

	} else {

		p1_nodeVar36 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar36;
	p1_nodeVar38 = length( ( vec2<f32>( p1_nodeVar33.z, p1_nodeVar33.w ) - p1_nodeVar6 ) );
	p1_nodeVar39 = ( p1_nodeVar38 < p1_nodeVar2 );

	if ( p1_nodeVar39 ) {

		p1_nodeVar37 = vec2<f32>( p1_nodeVar33.z, p1_nodeVar33.w );

	} else {

		p1_nodeVar37 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar37 );

	if ( p1_nodeVar39 ) {

		p1_nodeVar40 = p1_nodeVar38;

	} else {

		p1_nodeVar40 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar40;
	p1_nodeVar42 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar43 = length( ( vec2<f32>( p1_nodeVar42.x, p1_nodeVar42.y ) - p1_nodeVar6 ) );
	p1_nodeVar44 = ( p1_nodeVar43 < p1_nodeVar1 );

	if ( p1_nodeVar44 ) {

		p1_nodeVar41 = vec2<f32>( p1_nodeVar42.x, p1_nodeVar42.y );

	} else {

		p1_nodeVar41 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar41, p1_nodeVar0.zw );

	if ( p1_nodeVar44 ) {

		p1_nodeVar45 = p1_nodeVar43;

	} else {

		p1_nodeVar45 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar45;
	p1_nodeVar47 = length( ( vec2<f32>( p1_nodeVar42.z, p1_nodeVar42.w ) - p1_nodeVar6 ) );
	p1_nodeVar48 = ( p1_nodeVar47 < p1_nodeVar2 );

	if ( p1_nodeVar48 ) {

		p1_nodeVar46 = vec2<f32>( p1_nodeVar42.z, p1_nodeVar42.w );

	} else {

		p1_nodeVar46 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar46 );

	if ( p1_nodeVar48 ) {

		p1_nodeVar49 = p1_nodeVar47;

	} else {

		p1_nodeVar49 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar49;
	p1_nodeVar51 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar52 = length( ( vec2<f32>( p1_nodeVar51.x, p1_nodeVar51.y ) - p1_nodeVar6 ) );
	p1_nodeVar53 = ( p1_nodeVar52 < p1_nodeVar1 );

	if ( p1_nodeVar53 ) {

		p1_nodeVar50 = vec2<f32>( p1_nodeVar51.x, p1_nodeVar51.y );

	} else {

		p1_nodeVar50 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar50, p1_nodeVar0.zw );

	if ( p1_nodeVar53 ) {

		p1_nodeVar54 = p1_nodeVar52;

	} else {

		p1_nodeVar54 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar54;
	p1_nodeVar56 = length( ( vec2<f32>( p1_nodeVar51.z, p1_nodeVar51.w ) - p1_nodeVar6 ) );
	p1_nodeVar57 = ( p1_nodeVar56 < p1_nodeVar2 );

	if ( p1_nodeVar57 ) {

		p1_nodeVar55 = vec2<f32>( p1_nodeVar51.z, p1_nodeVar51.w );

	} else {

		p1_nodeVar55 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar55 );

	if ( p1_nodeVar57 ) {

		p1_nodeVar58 = p1_nodeVar56;

	} else {

		p1_nodeVar58 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar58;
	p1_nodeVar60 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar61 = length( ( vec2<f32>( p1_nodeVar60.x, p1_nodeVar60.y ) - p1_nodeVar6 ) );
	p1_nodeVar62 = ( p1_nodeVar61 < p1_nodeVar1 );

	if ( p1_nodeVar62 ) {

		p1_nodeVar59 = vec2<f32>( p1_nodeVar60.x, p1_nodeVar60.y );

	} else {

		p1_nodeVar59 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar59, p1_nodeVar0.zw );

	if ( p1_nodeVar62 ) {

		p1_nodeVar63 = p1_nodeVar61;

	} else {

		p1_nodeVar63 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar63;
	p1_nodeVar65 = length( ( vec2<f32>( p1_nodeVar60.z, p1_nodeVar60.w ) - p1_nodeVar6 ) );
	p1_nodeVar66 = ( p1_nodeVar65 < p1_nodeVar2 );

	if ( p1_nodeVar66 ) {

		p1_nodeVar64 = vec2<f32>( p1_nodeVar60.z, p1_nodeVar60.w );

	} else {

		p1_nodeVar64 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar64 );

	if ( p1_nodeVar66 ) {

		p1_nodeVar67 = p1_nodeVar65;

	} else {

		p1_nodeVar67 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar67;
	p1_nodeVar69 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar70 = length( ( vec2<f32>( p1_nodeVar69.x, p1_nodeVar69.y ) - p1_nodeVar6 ) );
	p1_nodeVar71 = ( p1_nodeVar70 < p1_nodeVar1 );

	if ( p1_nodeVar71 ) {

		p1_nodeVar68 = vec2<f32>( p1_nodeVar69.x, p1_nodeVar69.y );

	} else {

		p1_nodeVar68 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar68, p1_nodeVar0.zw );

	if ( p1_nodeVar71 ) {

		p1_nodeVar72 = p1_nodeVar70;

	} else {

		p1_nodeVar72 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar72;
	p1_nodeVar74 = length( ( vec2<f32>( p1_nodeVar69.z, p1_nodeVar69.w ) - p1_nodeVar6 ) );
	p1_nodeVar75 = ( p1_nodeVar74 < p1_nodeVar2 );

	if ( p1_nodeVar75 ) {

		p1_nodeVar73 = vec2<f32>( p1_nodeVar69.z, p1_nodeVar69.w );

	} else {

		p1_nodeVar73 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar73 );

	if ( p1_nodeVar75 ) {

		p1_nodeVar76 = p1_nodeVar74;

	} else {

		p1_nodeVar76 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar76;
	p1_nodeVar78 = target_read( t0, t0_sampler, ( p1_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(64.0) ) ) ) );
	p1_nodeVar79 = length( ( vec2<f32>( p1_nodeVar78.x, p1_nodeVar78.y ) - p1_nodeVar6 ) );
	p1_nodeVar80 = ( p1_nodeVar79 < p1_nodeVar1 );

	if ( p1_nodeVar80 ) {

		p1_nodeVar77 = vec2<f32>( p1_nodeVar78.x, p1_nodeVar78.y );

	} else {

		p1_nodeVar77 = p1_nodeVar0.xy;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar77, p1_nodeVar0.zw );

	if ( p1_nodeVar80 ) {

		p1_nodeVar81 = p1_nodeVar79;

	} else {

		p1_nodeVar81 = p1_nodeVar1;

	}

	p1_nodeVar1 = p1_nodeVar81;
	p1_nodeVar83 = length( ( vec2<f32>( p1_nodeVar78.z, p1_nodeVar78.w ) - p1_nodeVar6 ) );
	p1_nodeVar84 = ( p1_nodeVar83 < p1_nodeVar2 );

	if ( p1_nodeVar84 ) {

		p1_nodeVar82 = vec2<f32>( p1_nodeVar78.z, p1_nodeVar78.w );

	} else {

		p1_nodeVar82 = p1_nodeVar0.zw;

	}

	p1_nodeVar0 = vec4<f32>( p1_nodeVar0.xy, p1_nodeVar82 );

	if ( p1_nodeVar84 ) {

		p1_nodeVar85 = p1_nodeVar83;

	} else {

		p1_nodeVar85 = p1_nodeVar2;

	}

	p1_nodeVar2 = p1_nodeVar85;
	p1_DiffuseColor = p1_nodeVar0;
	p1_DiffuseColor.w = ( p1_DiffuseColor.w * f32(1.0) );
	p1_nodeVar86 = max( vec4<f32>( p1_DiffuseColor.xyz, p1_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p1_Output = p1_nodeVar86;

	// result

	p1_output.color = p1_nodeVar86;

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
var<private> p2_nodeVar1 : f32;
var<private> p2_nodeVar2 : f32;
var<private> p2_nodeVar3 : vec2<f32>;
var<private> p2_nodeVar4 : vec2<f32>;
var<private> p2_nodeVar5 : vec4<f32>;
var<private> p2_nodeVar6 : vec2<f32>;
var<private> p2_nodeVar7 : f32;
var<private> p2_nodeVar8 : bool;
var<private> p2_nodeVar9 : f32;
var<private> p2_nodeVar10 : vec2<f32>;
var<private> p2_nodeVar11 : f32;
var<private> p2_nodeVar12 : bool;
var<private> p2_nodeVar13 : f32;
var<private> p2_nodeVar14 : vec2<f32>;
var<private> p2_nodeVar15 : vec4<f32>;
var<private> p2_nodeVar16 : f32;
var<private> p2_nodeVar17 : bool;
var<private> p2_nodeVar18 : f32;
var<private> p2_nodeVar19 : vec2<f32>;
var<private> p2_nodeVar20 : f32;
var<private> p2_nodeVar21 : bool;
var<private> p2_nodeVar22 : f32;
var<private> p2_nodeVar23 : vec2<f32>;
var<private> p2_nodeVar24 : vec4<f32>;
var<private> p2_nodeVar25 : f32;
var<private> p2_nodeVar26 : bool;
var<private> p2_nodeVar27 : f32;
var<private> p2_nodeVar28 : vec2<f32>;
var<private> p2_nodeVar29 : f32;
var<private> p2_nodeVar30 : bool;
var<private> p2_nodeVar31 : f32;
var<private> p2_nodeVar32 : vec2<f32>;
var<private> p2_nodeVar33 : vec4<f32>;
var<private> p2_nodeVar34 : f32;
var<private> p2_nodeVar35 : bool;
var<private> p2_nodeVar36 : f32;
var<private> p2_nodeVar37 : vec2<f32>;
var<private> p2_nodeVar38 : f32;
var<private> p2_nodeVar39 : bool;
var<private> p2_nodeVar40 : f32;
var<private> p2_nodeVar41 : vec2<f32>;
var<private> p2_nodeVar42 : vec4<f32>;
var<private> p2_nodeVar43 : f32;
var<private> p2_nodeVar44 : bool;
var<private> p2_nodeVar45 : f32;
var<private> p2_nodeVar46 : vec2<f32>;
var<private> p2_nodeVar47 : f32;
var<private> p2_nodeVar48 : bool;
var<private> p2_nodeVar49 : f32;
var<private> p2_nodeVar50 : vec2<f32>;
var<private> p2_nodeVar51 : vec4<f32>;
var<private> p2_nodeVar52 : f32;
var<private> p2_nodeVar53 : bool;
var<private> p2_nodeVar54 : f32;
var<private> p2_nodeVar55 : vec2<f32>;
var<private> p2_nodeVar56 : f32;
var<private> p2_nodeVar57 : bool;
var<private> p2_nodeVar58 : f32;
var<private> p2_nodeVar59 : vec2<f32>;
var<private> p2_nodeVar60 : vec4<f32>;
var<private> p2_nodeVar61 : f32;
var<private> p2_nodeVar62 : bool;
var<private> p2_nodeVar63 : f32;
var<private> p2_nodeVar64 : vec2<f32>;
var<private> p2_nodeVar65 : f32;
var<private> p2_nodeVar66 : bool;
var<private> p2_nodeVar67 : f32;
var<private> p2_nodeVar68 : vec2<f32>;
var<private> p2_nodeVar69 : vec4<f32>;
var<private> p2_nodeVar70 : f32;
var<private> p2_nodeVar71 : bool;
var<private> p2_nodeVar72 : f32;
var<private> p2_nodeVar73 : vec2<f32>;
var<private> p2_nodeVar74 : f32;
var<private> p2_nodeVar75 : bool;
var<private> p2_nodeVar76 : f32;
var<private> p2_nodeVar77 : vec2<f32>;
var<private> p2_nodeVar78 : vec4<f32>;
var<private> p2_nodeVar79 : f32;
var<private> p2_nodeVar80 : bool;
var<private> p2_nodeVar81 : f32;
var<private> p2_nodeVar82 : vec2<f32>;
var<private> p2_nodeVar83 : f32;
var<private> p2_nodeVar84 : bool;
var<private> p2_nodeVar85 : f32;
var<private> p2_Output : vec4<f32>;
var<private> p2_nodeVar86 : vec4<f32>;

// codes


fn p2_main(door_uv: vec2f) -> p2_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p2_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p2_nodeVar1 = 400000.0;
	p2_nodeVar2 = 400000.0;
	p2_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p2_nodeVar5 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar6 = ( p2_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p2_nodeVar7 = length( ( vec2<f32>( p2_nodeVar5.x, p2_nodeVar5.y ) - p2_nodeVar6 ) );
	p2_nodeVar8 = ( p2_nodeVar7 < p2_nodeVar1 );

	if ( p2_nodeVar8 ) {

		p2_nodeVar3 = vec2<f32>( p2_nodeVar5.x, p2_nodeVar5.y );

	} else {

		p2_nodeVar3 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar3, p2_nodeVar0.zw );

	if ( p2_nodeVar8 ) {

		p2_nodeVar9 = p2_nodeVar7;

	} else {

		p2_nodeVar9 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar9;
	p2_nodeVar11 = length( ( vec2<f32>( p2_nodeVar5.z, p2_nodeVar5.w ) - p2_nodeVar6 ) );
	p2_nodeVar12 = ( p2_nodeVar11 < p2_nodeVar2 );

	if ( p2_nodeVar12 ) {

		p2_nodeVar10 = vec2<f32>( p2_nodeVar5.z, p2_nodeVar5.w );

	} else {

		p2_nodeVar10 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar10 );

	if ( p2_nodeVar12 ) {

		p2_nodeVar13 = p2_nodeVar11;

	} else {

		p2_nodeVar13 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar13;
	p2_nodeVar15 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar16 = length( ( vec2<f32>( p2_nodeVar15.x, p2_nodeVar15.y ) - p2_nodeVar6 ) );
	p2_nodeVar17 = ( p2_nodeVar16 < p2_nodeVar1 );

	if ( p2_nodeVar17 ) {

		p2_nodeVar14 = vec2<f32>( p2_nodeVar15.x, p2_nodeVar15.y );

	} else {

		p2_nodeVar14 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar14, p2_nodeVar0.zw );

	if ( p2_nodeVar17 ) {

		p2_nodeVar18 = p2_nodeVar16;

	} else {

		p2_nodeVar18 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar18;
	p2_nodeVar20 = length( ( vec2<f32>( p2_nodeVar15.z, p2_nodeVar15.w ) - p2_nodeVar6 ) );
	p2_nodeVar21 = ( p2_nodeVar20 < p2_nodeVar2 );

	if ( p2_nodeVar21 ) {

		p2_nodeVar19 = vec2<f32>( p2_nodeVar15.z, p2_nodeVar15.w );

	} else {

		p2_nodeVar19 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar19 );

	if ( p2_nodeVar21 ) {

		p2_nodeVar22 = p2_nodeVar20;

	} else {

		p2_nodeVar22 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar22;
	p2_nodeVar24 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar25 = length( ( vec2<f32>( p2_nodeVar24.x, p2_nodeVar24.y ) - p2_nodeVar6 ) );
	p2_nodeVar26 = ( p2_nodeVar25 < p2_nodeVar1 );

	if ( p2_nodeVar26 ) {

		p2_nodeVar23 = vec2<f32>( p2_nodeVar24.x, p2_nodeVar24.y );

	} else {

		p2_nodeVar23 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar23, p2_nodeVar0.zw );

	if ( p2_nodeVar26 ) {

		p2_nodeVar27 = p2_nodeVar25;

	} else {

		p2_nodeVar27 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar27;
	p2_nodeVar29 = length( ( vec2<f32>( p2_nodeVar24.z, p2_nodeVar24.w ) - p2_nodeVar6 ) );
	p2_nodeVar30 = ( p2_nodeVar29 < p2_nodeVar2 );

	if ( p2_nodeVar30 ) {

		p2_nodeVar28 = vec2<f32>( p2_nodeVar24.z, p2_nodeVar24.w );

	} else {

		p2_nodeVar28 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar28 );

	if ( p2_nodeVar30 ) {

		p2_nodeVar31 = p2_nodeVar29;

	} else {

		p2_nodeVar31 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar31;
	p2_nodeVar33 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar34 = length( ( vec2<f32>( p2_nodeVar33.x, p2_nodeVar33.y ) - p2_nodeVar6 ) );
	p2_nodeVar35 = ( p2_nodeVar34 < p2_nodeVar1 );

	if ( p2_nodeVar35 ) {

		p2_nodeVar32 = vec2<f32>( p2_nodeVar33.x, p2_nodeVar33.y );

	} else {

		p2_nodeVar32 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar32, p2_nodeVar0.zw );

	if ( p2_nodeVar35 ) {

		p2_nodeVar36 = p2_nodeVar34;

	} else {

		p2_nodeVar36 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar36;
	p2_nodeVar38 = length( ( vec2<f32>( p2_nodeVar33.z, p2_nodeVar33.w ) - p2_nodeVar6 ) );
	p2_nodeVar39 = ( p2_nodeVar38 < p2_nodeVar2 );

	if ( p2_nodeVar39 ) {

		p2_nodeVar37 = vec2<f32>( p2_nodeVar33.z, p2_nodeVar33.w );

	} else {

		p2_nodeVar37 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar37 );

	if ( p2_nodeVar39 ) {

		p2_nodeVar40 = p2_nodeVar38;

	} else {

		p2_nodeVar40 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar40;
	p2_nodeVar42 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar43 = length( ( vec2<f32>( p2_nodeVar42.x, p2_nodeVar42.y ) - p2_nodeVar6 ) );
	p2_nodeVar44 = ( p2_nodeVar43 < p2_nodeVar1 );

	if ( p2_nodeVar44 ) {

		p2_nodeVar41 = vec2<f32>( p2_nodeVar42.x, p2_nodeVar42.y );

	} else {

		p2_nodeVar41 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar41, p2_nodeVar0.zw );

	if ( p2_nodeVar44 ) {

		p2_nodeVar45 = p2_nodeVar43;

	} else {

		p2_nodeVar45 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar45;
	p2_nodeVar47 = length( ( vec2<f32>( p2_nodeVar42.z, p2_nodeVar42.w ) - p2_nodeVar6 ) );
	p2_nodeVar48 = ( p2_nodeVar47 < p2_nodeVar2 );

	if ( p2_nodeVar48 ) {

		p2_nodeVar46 = vec2<f32>( p2_nodeVar42.z, p2_nodeVar42.w );

	} else {

		p2_nodeVar46 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar46 );

	if ( p2_nodeVar48 ) {

		p2_nodeVar49 = p2_nodeVar47;

	} else {

		p2_nodeVar49 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar49;
	p2_nodeVar51 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar52 = length( ( vec2<f32>( p2_nodeVar51.x, p2_nodeVar51.y ) - p2_nodeVar6 ) );
	p2_nodeVar53 = ( p2_nodeVar52 < p2_nodeVar1 );

	if ( p2_nodeVar53 ) {

		p2_nodeVar50 = vec2<f32>( p2_nodeVar51.x, p2_nodeVar51.y );

	} else {

		p2_nodeVar50 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar50, p2_nodeVar0.zw );

	if ( p2_nodeVar53 ) {

		p2_nodeVar54 = p2_nodeVar52;

	} else {

		p2_nodeVar54 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar54;
	p2_nodeVar56 = length( ( vec2<f32>( p2_nodeVar51.z, p2_nodeVar51.w ) - p2_nodeVar6 ) );
	p2_nodeVar57 = ( p2_nodeVar56 < p2_nodeVar2 );

	if ( p2_nodeVar57 ) {

		p2_nodeVar55 = vec2<f32>( p2_nodeVar51.z, p2_nodeVar51.w );

	} else {

		p2_nodeVar55 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar55 );

	if ( p2_nodeVar57 ) {

		p2_nodeVar58 = p2_nodeVar56;

	} else {

		p2_nodeVar58 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar58;
	p2_nodeVar60 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar61 = length( ( vec2<f32>( p2_nodeVar60.x, p2_nodeVar60.y ) - p2_nodeVar6 ) );
	p2_nodeVar62 = ( p2_nodeVar61 < p2_nodeVar1 );

	if ( p2_nodeVar62 ) {

		p2_nodeVar59 = vec2<f32>( p2_nodeVar60.x, p2_nodeVar60.y );

	} else {

		p2_nodeVar59 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar59, p2_nodeVar0.zw );

	if ( p2_nodeVar62 ) {

		p2_nodeVar63 = p2_nodeVar61;

	} else {

		p2_nodeVar63 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar63;
	p2_nodeVar65 = length( ( vec2<f32>( p2_nodeVar60.z, p2_nodeVar60.w ) - p2_nodeVar6 ) );
	p2_nodeVar66 = ( p2_nodeVar65 < p2_nodeVar2 );

	if ( p2_nodeVar66 ) {

		p2_nodeVar64 = vec2<f32>( p2_nodeVar60.z, p2_nodeVar60.w );

	} else {

		p2_nodeVar64 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar64 );

	if ( p2_nodeVar66 ) {

		p2_nodeVar67 = p2_nodeVar65;

	} else {

		p2_nodeVar67 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar67;
	p2_nodeVar69 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar70 = length( ( vec2<f32>( p2_nodeVar69.x, p2_nodeVar69.y ) - p2_nodeVar6 ) );
	p2_nodeVar71 = ( p2_nodeVar70 < p2_nodeVar1 );

	if ( p2_nodeVar71 ) {

		p2_nodeVar68 = vec2<f32>( p2_nodeVar69.x, p2_nodeVar69.y );

	} else {

		p2_nodeVar68 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar68, p2_nodeVar0.zw );

	if ( p2_nodeVar71 ) {

		p2_nodeVar72 = p2_nodeVar70;

	} else {

		p2_nodeVar72 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar72;
	p2_nodeVar74 = length( ( vec2<f32>( p2_nodeVar69.z, p2_nodeVar69.w ) - p2_nodeVar6 ) );
	p2_nodeVar75 = ( p2_nodeVar74 < p2_nodeVar2 );

	if ( p2_nodeVar75 ) {

		p2_nodeVar73 = vec2<f32>( p2_nodeVar69.z, p2_nodeVar69.w );

	} else {

		p2_nodeVar73 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar73 );

	if ( p2_nodeVar75 ) {

		p2_nodeVar76 = p2_nodeVar74;

	} else {

		p2_nodeVar76 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar76;
	p2_nodeVar78 = target_read( t1, t1_sampler, ( p2_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(32.0) ) ) ) );
	p2_nodeVar79 = length( ( vec2<f32>( p2_nodeVar78.x, p2_nodeVar78.y ) - p2_nodeVar6 ) );
	p2_nodeVar80 = ( p2_nodeVar79 < p2_nodeVar1 );

	if ( p2_nodeVar80 ) {

		p2_nodeVar77 = vec2<f32>( p2_nodeVar78.x, p2_nodeVar78.y );

	} else {

		p2_nodeVar77 = p2_nodeVar0.xy;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar77, p2_nodeVar0.zw );

	if ( p2_nodeVar80 ) {

		p2_nodeVar81 = p2_nodeVar79;

	} else {

		p2_nodeVar81 = p2_nodeVar1;

	}

	p2_nodeVar1 = p2_nodeVar81;
	p2_nodeVar83 = length( ( vec2<f32>( p2_nodeVar78.z, p2_nodeVar78.w ) - p2_nodeVar6 ) );
	p2_nodeVar84 = ( p2_nodeVar83 < p2_nodeVar2 );

	if ( p2_nodeVar84 ) {

		p2_nodeVar82 = vec2<f32>( p2_nodeVar78.z, p2_nodeVar78.w );

	} else {

		p2_nodeVar82 = p2_nodeVar0.zw;

	}

	p2_nodeVar0 = vec4<f32>( p2_nodeVar0.xy, p2_nodeVar82 );

	if ( p2_nodeVar84 ) {

		p2_nodeVar85 = p2_nodeVar83;

	} else {

		p2_nodeVar85 = p2_nodeVar2;

	}

	p2_nodeVar2 = p2_nodeVar85;
	p2_DiffuseColor = p2_nodeVar0;
	p2_DiffuseColor.w = ( p2_DiffuseColor.w * f32(1.0) );
	p2_nodeVar86 = max( vec4<f32>( p2_DiffuseColor.xyz, p2_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p2_Output = p2_nodeVar86;

	// result

	p2_output.color = p2_nodeVar86;

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
var<private> p3_nodeVar1 : f32;
var<private> p3_nodeVar2 : f32;
var<private> p3_nodeVar3 : vec2<f32>;
var<private> p3_nodeVar4 : vec2<f32>;
var<private> p3_nodeVar5 : vec4<f32>;
var<private> p3_nodeVar6 : vec2<f32>;
var<private> p3_nodeVar7 : f32;
var<private> p3_nodeVar8 : bool;
var<private> p3_nodeVar9 : f32;
var<private> p3_nodeVar10 : vec2<f32>;
var<private> p3_nodeVar11 : f32;
var<private> p3_nodeVar12 : bool;
var<private> p3_nodeVar13 : f32;
var<private> p3_nodeVar14 : vec2<f32>;
var<private> p3_nodeVar15 : vec4<f32>;
var<private> p3_nodeVar16 : f32;
var<private> p3_nodeVar17 : bool;
var<private> p3_nodeVar18 : f32;
var<private> p3_nodeVar19 : vec2<f32>;
var<private> p3_nodeVar20 : f32;
var<private> p3_nodeVar21 : bool;
var<private> p3_nodeVar22 : f32;
var<private> p3_nodeVar23 : vec2<f32>;
var<private> p3_nodeVar24 : vec4<f32>;
var<private> p3_nodeVar25 : f32;
var<private> p3_nodeVar26 : bool;
var<private> p3_nodeVar27 : f32;
var<private> p3_nodeVar28 : vec2<f32>;
var<private> p3_nodeVar29 : f32;
var<private> p3_nodeVar30 : bool;
var<private> p3_nodeVar31 : f32;
var<private> p3_nodeVar32 : vec2<f32>;
var<private> p3_nodeVar33 : vec4<f32>;
var<private> p3_nodeVar34 : f32;
var<private> p3_nodeVar35 : bool;
var<private> p3_nodeVar36 : f32;
var<private> p3_nodeVar37 : vec2<f32>;
var<private> p3_nodeVar38 : f32;
var<private> p3_nodeVar39 : bool;
var<private> p3_nodeVar40 : f32;
var<private> p3_nodeVar41 : vec2<f32>;
var<private> p3_nodeVar42 : vec4<f32>;
var<private> p3_nodeVar43 : f32;
var<private> p3_nodeVar44 : bool;
var<private> p3_nodeVar45 : f32;
var<private> p3_nodeVar46 : vec2<f32>;
var<private> p3_nodeVar47 : f32;
var<private> p3_nodeVar48 : bool;
var<private> p3_nodeVar49 : f32;
var<private> p3_nodeVar50 : vec2<f32>;
var<private> p3_nodeVar51 : vec4<f32>;
var<private> p3_nodeVar52 : f32;
var<private> p3_nodeVar53 : bool;
var<private> p3_nodeVar54 : f32;
var<private> p3_nodeVar55 : vec2<f32>;
var<private> p3_nodeVar56 : f32;
var<private> p3_nodeVar57 : bool;
var<private> p3_nodeVar58 : f32;
var<private> p3_nodeVar59 : vec2<f32>;
var<private> p3_nodeVar60 : vec4<f32>;
var<private> p3_nodeVar61 : f32;
var<private> p3_nodeVar62 : bool;
var<private> p3_nodeVar63 : f32;
var<private> p3_nodeVar64 : vec2<f32>;
var<private> p3_nodeVar65 : f32;
var<private> p3_nodeVar66 : bool;
var<private> p3_nodeVar67 : f32;
var<private> p3_nodeVar68 : vec2<f32>;
var<private> p3_nodeVar69 : vec4<f32>;
var<private> p3_nodeVar70 : f32;
var<private> p3_nodeVar71 : bool;
var<private> p3_nodeVar72 : f32;
var<private> p3_nodeVar73 : vec2<f32>;
var<private> p3_nodeVar74 : f32;
var<private> p3_nodeVar75 : bool;
var<private> p3_nodeVar76 : f32;
var<private> p3_nodeVar77 : vec2<f32>;
var<private> p3_nodeVar78 : vec4<f32>;
var<private> p3_nodeVar79 : f32;
var<private> p3_nodeVar80 : bool;
var<private> p3_nodeVar81 : f32;
var<private> p3_nodeVar82 : vec2<f32>;
var<private> p3_nodeVar83 : f32;
var<private> p3_nodeVar84 : bool;
var<private> p3_nodeVar85 : f32;
var<private> p3_Output : vec4<f32>;
var<private> p3_nodeVar86 : vec4<f32>;

// codes


fn p3_main(door_uv: vec2f) -> p3_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p3_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p3_nodeVar1 = 400000.0;
	p3_nodeVar2 = 400000.0;
	p3_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p3_nodeVar5 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar6 = ( p3_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p3_nodeVar7 = length( ( vec2<f32>( p3_nodeVar5.x, p3_nodeVar5.y ) - p3_nodeVar6 ) );
	p3_nodeVar8 = ( p3_nodeVar7 < p3_nodeVar1 );

	if ( p3_nodeVar8 ) {

		p3_nodeVar3 = vec2<f32>( p3_nodeVar5.x, p3_nodeVar5.y );

	} else {

		p3_nodeVar3 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar3, p3_nodeVar0.zw );

	if ( p3_nodeVar8 ) {

		p3_nodeVar9 = p3_nodeVar7;

	} else {

		p3_nodeVar9 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar9;
	p3_nodeVar11 = length( ( vec2<f32>( p3_nodeVar5.z, p3_nodeVar5.w ) - p3_nodeVar6 ) );
	p3_nodeVar12 = ( p3_nodeVar11 < p3_nodeVar2 );

	if ( p3_nodeVar12 ) {

		p3_nodeVar10 = vec2<f32>( p3_nodeVar5.z, p3_nodeVar5.w );

	} else {

		p3_nodeVar10 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar10 );

	if ( p3_nodeVar12 ) {

		p3_nodeVar13 = p3_nodeVar11;

	} else {

		p3_nodeVar13 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar13;
	p3_nodeVar15 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar16 = length( ( vec2<f32>( p3_nodeVar15.x, p3_nodeVar15.y ) - p3_nodeVar6 ) );
	p3_nodeVar17 = ( p3_nodeVar16 < p3_nodeVar1 );

	if ( p3_nodeVar17 ) {

		p3_nodeVar14 = vec2<f32>( p3_nodeVar15.x, p3_nodeVar15.y );

	} else {

		p3_nodeVar14 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar14, p3_nodeVar0.zw );

	if ( p3_nodeVar17 ) {

		p3_nodeVar18 = p3_nodeVar16;

	} else {

		p3_nodeVar18 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar18;
	p3_nodeVar20 = length( ( vec2<f32>( p3_nodeVar15.z, p3_nodeVar15.w ) - p3_nodeVar6 ) );
	p3_nodeVar21 = ( p3_nodeVar20 < p3_nodeVar2 );

	if ( p3_nodeVar21 ) {

		p3_nodeVar19 = vec2<f32>( p3_nodeVar15.z, p3_nodeVar15.w );

	} else {

		p3_nodeVar19 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar19 );

	if ( p3_nodeVar21 ) {

		p3_nodeVar22 = p3_nodeVar20;

	} else {

		p3_nodeVar22 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar22;
	p3_nodeVar24 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar25 = length( ( vec2<f32>( p3_nodeVar24.x, p3_nodeVar24.y ) - p3_nodeVar6 ) );
	p3_nodeVar26 = ( p3_nodeVar25 < p3_nodeVar1 );

	if ( p3_nodeVar26 ) {

		p3_nodeVar23 = vec2<f32>( p3_nodeVar24.x, p3_nodeVar24.y );

	} else {

		p3_nodeVar23 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar23, p3_nodeVar0.zw );

	if ( p3_nodeVar26 ) {

		p3_nodeVar27 = p3_nodeVar25;

	} else {

		p3_nodeVar27 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar27;
	p3_nodeVar29 = length( ( vec2<f32>( p3_nodeVar24.z, p3_nodeVar24.w ) - p3_nodeVar6 ) );
	p3_nodeVar30 = ( p3_nodeVar29 < p3_nodeVar2 );

	if ( p3_nodeVar30 ) {

		p3_nodeVar28 = vec2<f32>( p3_nodeVar24.z, p3_nodeVar24.w );

	} else {

		p3_nodeVar28 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar28 );

	if ( p3_nodeVar30 ) {

		p3_nodeVar31 = p3_nodeVar29;

	} else {

		p3_nodeVar31 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar31;
	p3_nodeVar33 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar34 = length( ( vec2<f32>( p3_nodeVar33.x, p3_nodeVar33.y ) - p3_nodeVar6 ) );
	p3_nodeVar35 = ( p3_nodeVar34 < p3_nodeVar1 );

	if ( p3_nodeVar35 ) {

		p3_nodeVar32 = vec2<f32>( p3_nodeVar33.x, p3_nodeVar33.y );

	} else {

		p3_nodeVar32 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar32, p3_nodeVar0.zw );

	if ( p3_nodeVar35 ) {

		p3_nodeVar36 = p3_nodeVar34;

	} else {

		p3_nodeVar36 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar36;
	p3_nodeVar38 = length( ( vec2<f32>( p3_nodeVar33.z, p3_nodeVar33.w ) - p3_nodeVar6 ) );
	p3_nodeVar39 = ( p3_nodeVar38 < p3_nodeVar2 );

	if ( p3_nodeVar39 ) {

		p3_nodeVar37 = vec2<f32>( p3_nodeVar33.z, p3_nodeVar33.w );

	} else {

		p3_nodeVar37 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar37 );

	if ( p3_nodeVar39 ) {

		p3_nodeVar40 = p3_nodeVar38;

	} else {

		p3_nodeVar40 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar40;
	p3_nodeVar42 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar43 = length( ( vec2<f32>( p3_nodeVar42.x, p3_nodeVar42.y ) - p3_nodeVar6 ) );
	p3_nodeVar44 = ( p3_nodeVar43 < p3_nodeVar1 );

	if ( p3_nodeVar44 ) {

		p3_nodeVar41 = vec2<f32>( p3_nodeVar42.x, p3_nodeVar42.y );

	} else {

		p3_nodeVar41 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar41, p3_nodeVar0.zw );

	if ( p3_nodeVar44 ) {

		p3_nodeVar45 = p3_nodeVar43;

	} else {

		p3_nodeVar45 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar45;
	p3_nodeVar47 = length( ( vec2<f32>( p3_nodeVar42.z, p3_nodeVar42.w ) - p3_nodeVar6 ) );
	p3_nodeVar48 = ( p3_nodeVar47 < p3_nodeVar2 );

	if ( p3_nodeVar48 ) {

		p3_nodeVar46 = vec2<f32>( p3_nodeVar42.z, p3_nodeVar42.w );

	} else {

		p3_nodeVar46 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar46 );

	if ( p3_nodeVar48 ) {

		p3_nodeVar49 = p3_nodeVar47;

	} else {

		p3_nodeVar49 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar49;
	p3_nodeVar51 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar52 = length( ( vec2<f32>( p3_nodeVar51.x, p3_nodeVar51.y ) - p3_nodeVar6 ) );
	p3_nodeVar53 = ( p3_nodeVar52 < p3_nodeVar1 );

	if ( p3_nodeVar53 ) {

		p3_nodeVar50 = vec2<f32>( p3_nodeVar51.x, p3_nodeVar51.y );

	} else {

		p3_nodeVar50 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar50, p3_nodeVar0.zw );

	if ( p3_nodeVar53 ) {

		p3_nodeVar54 = p3_nodeVar52;

	} else {

		p3_nodeVar54 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar54;
	p3_nodeVar56 = length( ( vec2<f32>( p3_nodeVar51.z, p3_nodeVar51.w ) - p3_nodeVar6 ) );
	p3_nodeVar57 = ( p3_nodeVar56 < p3_nodeVar2 );

	if ( p3_nodeVar57 ) {

		p3_nodeVar55 = vec2<f32>( p3_nodeVar51.z, p3_nodeVar51.w );

	} else {

		p3_nodeVar55 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar55 );

	if ( p3_nodeVar57 ) {

		p3_nodeVar58 = p3_nodeVar56;

	} else {

		p3_nodeVar58 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar58;
	p3_nodeVar60 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar61 = length( ( vec2<f32>( p3_nodeVar60.x, p3_nodeVar60.y ) - p3_nodeVar6 ) );
	p3_nodeVar62 = ( p3_nodeVar61 < p3_nodeVar1 );

	if ( p3_nodeVar62 ) {

		p3_nodeVar59 = vec2<f32>( p3_nodeVar60.x, p3_nodeVar60.y );

	} else {

		p3_nodeVar59 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar59, p3_nodeVar0.zw );

	if ( p3_nodeVar62 ) {

		p3_nodeVar63 = p3_nodeVar61;

	} else {

		p3_nodeVar63 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar63;
	p3_nodeVar65 = length( ( vec2<f32>( p3_nodeVar60.z, p3_nodeVar60.w ) - p3_nodeVar6 ) );
	p3_nodeVar66 = ( p3_nodeVar65 < p3_nodeVar2 );

	if ( p3_nodeVar66 ) {

		p3_nodeVar64 = vec2<f32>( p3_nodeVar60.z, p3_nodeVar60.w );

	} else {

		p3_nodeVar64 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar64 );

	if ( p3_nodeVar66 ) {

		p3_nodeVar67 = p3_nodeVar65;

	} else {

		p3_nodeVar67 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar67;
	p3_nodeVar69 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar70 = length( ( vec2<f32>( p3_nodeVar69.x, p3_nodeVar69.y ) - p3_nodeVar6 ) );
	p3_nodeVar71 = ( p3_nodeVar70 < p3_nodeVar1 );

	if ( p3_nodeVar71 ) {

		p3_nodeVar68 = vec2<f32>( p3_nodeVar69.x, p3_nodeVar69.y );

	} else {

		p3_nodeVar68 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar68, p3_nodeVar0.zw );

	if ( p3_nodeVar71 ) {

		p3_nodeVar72 = p3_nodeVar70;

	} else {

		p3_nodeVar72 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar72;
	p3_nodeVar74 = length( ( vec2<f32>( p3_nodeVar69.z, p3_nodeVar69.w ) - p3_nodeVar6 ) );
	p3_nodeVar75 = ( p3_nodeVar74 < p3_nodeVar2 );

	if ( p3_nodeVar75 ) {

		p3_nodeVar73 = vec2<f32>( p3_nodeVar69.z, p3_nodeVar69.w );

	} else {

		p3_nodeVar73 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar73 );

	if ( p3_nodeVar75 ) {

		p3_nodeVar76 = p3_nodeVar74;

	} else {

		p3_nodeVar76 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar76;
	p3_nodeVar78 = target_read( t0, t0_sampler, ( p3_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(16.0) ) ) ) );
	p3_nodeVar79 = length( ( vec2<f32>( p3_nodeVar78.x, p3_nodeVar78.y ) - p3_nodeVar6 ) );
	p3_nodeVar80 = ( p3_nodeVar79 < p3_nodeVar1 );

	if ( p3_nodeVar80 ) {

		p3_nodeVar77 = vec2<f32>( p3_nodeVar78.x, p3_nodeVar78.y );

	} else {

		p3_nodeVar77 = p3_nodeVar0.xy;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar77, p3_nodeVar0.zw );

	if ( p3_nodeVar80 ) {

		p3_nodeVar81 = p3_nodeVar79;

	} else {

		p3_nodeVar81 = p3_nodeVar1;

	}

	p3_nodeVar1 = p3_nodeVar81;
	p3_nodeVar83 = length( ( vec2<f32>( p3_nodeVar78.z, p3_nodeVar78.w ) - p3_nodeVar6 ) );
	p3_nodeVar84 = ( p3_nodeVar83 < p3_nodeVar2 );

	if ( p3_nodeVar84 ) {

		p3_nodeVar82 = vec2<f32>( p3_nodeVar78.z, p3_nodeVar78.w );

	} else {

		p3_nodeVar82 = p3_nodeVar0.zw;

	}

	p3_nodeVar0 = vec4<f32>( p3_nodeVar0.xy, p3_nodeVar82 );

	if ( p3_nodeVar84 ) {

		p3_nodeVar85 = p3_nodeVar83;

	} else {

		p3_nodeVar85 = p3_nodeVar2;

	}

	p3_nodeVar2 = p3_nodeVar85;
	p3_DiffuseColor = p3_nodeVar0;
	p3_DiffuseColor.w = ( p3_DiffuseColor.w * f32(1.0) );
	p3_nodeVar86 = max( vec4<f32>( p3_DiffuseColor.xyz, p3_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p3_Output = p3_nodeVar86;

	// result

	p3_output.color = p3_nodeVar86;

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
var<private> p4_nodeVar0 : vec4<f32>;
var<private> p4_nodeVar1 : f32;
var<private> p4_nodeVar2 : f32;
var<private> p4_nodeVar3 : vec2<f32>;
var<private> p4_nodeVar4 : vec2<f32>;
var<private> p4_nodeVar5 : vec4<f32>;
var<private> p4_nodeVar6 : vec2<f32>;
var<private> p4_nodeVar7 : f32;
var<private> p4_nodeVar8 : bool;
var<private> p4_nodeVar9 : f32;
var<private> p4_nodeVar10 : vec2<f32>;
var<private> p4_nodeVar11 : f32;
var<private> p4_nodeVar12 : bool;
var<private> p4_nodeVar13 : f32;
var<private> p4_nodeVar14 : vec2<f32>;
var<private> p4_nodeVar15 : vec4<f32>;
var<private> p4_nodeVar16 : f32;
var<private> p4_nodeVar17 : bool;
var<private> p4_nodeVar18 : f32;
var<private> p4_nodeVar19 : vec2<f32>;
var<private> p4_nodeVar20 : f32;
var<private> p4_nodeVar21 : bool;
var<private> p4_nodeVar22 : f32;
var<private> p4_nodeVar23 : vec2<f32>;
var<private> p4_nodeVar24 : vec4<f32>;
var<private> p4_nodeVar25 : f32;
var<private> p4_nodeVar26 : bool;
var<private> p4_nodeVar27 : f32;
var<private> p4_nodeVar28 : vec2<f32>;
var<private> p4_nodeVar29 : f32;
var<private> p4_nodeVar30 : bool;
var<private> p4_nodeVar31 : f32;
var<private> p4_nodeVar32 : vec2<f32>;
var<private> p4_nodeVar33 : vec4<f32>;
var<private> p4_nodeVar34 : f32;
var<private> p4_nodeVar35 : bool;
var<private> p4_nodeVar36 : f32;
var<private> p4_nodeVar37 : vec2<f32>;
var<private> p4_nodeVar38 : f32;
var<private> p4_nodeVar39 : bool;
var<private> p4_nodeVar40 : f32;
var<private> p4_nodeVar41 : vec2<f32>;
var<private> p4_nodeVar42 : vec4<f32>;
var<private> p4_nodeVar43 : f32;
var<private> p4_nodeVar44 : bool;
var<private> p4_nodeVar45 : f32;
var<private> p4_nodeVar46 : vec2<f32>;
var<private> p4_nodeVar47 : f32;
var<private> p4_nodeVar48 : bool;
var<private> p4_nodeVar49 : f32;
var<private> p4_nodeVar50 : vec2<f32>;
var<private> p4_nodeVar51 : vec4<f32>;
var<private> p4_nodeVar52 : f32;
var<private> p4_nodeVar53 : bool;
var<private> p4_nodeVar54 : f32;
var<private> p4_nodeVar55 : vec2<f32>;
var<private> p4_nodeVar56 : f32;
var<private> p4_nodeVar57 : bool;
var<private> p4_nodeVar58 : f32;
var<private> p4_nodeVar59 : vec2<f32>;
var<private> p4_nodeVar60 : vec4<f32>;
var<private> p4_nodeVar61 : f32;
var<private> p4_nodeVar62 : bool;
var<private> p4_nodeVar63 : f32;
var<private> p4_nodeVar64 : vec2<f32>;
var<private> p4_nodeVar65 : f32;
var<private> p4_nodeVar66 : bool;
var<private> p4_nodeVar67 : f32;
var<private> p4_nodeVar68 : vec2<f32>;
var<private> p4_nodeVar69 : vec4<f32>;
var<private> p4_nodeVar70 : f32;
var<private> p4_nodeVar71 : bool;
var<private> p4_nodeVar72 : f32;
var<private> p4_nodeVar73 : vec2<f32>;
var<private> p4_nodeVar74 : f32;
var<private> p4_nodeVar75 : bool;
var<private> p4_nodeVar76 : f32;
var<private> p4_nodeVar77 : vec2<f32>;
var<private> p4_nodeVar78 : vec4<f32>;
var<private> p4_nodeVar79 : f32;
var<private> p4_nodeVar80 : bool;
var<private> p4_nodeVar81 : f32;
var<private> p4_nodeVar82 : vec2<f32>;
var<private> p4_nodeVar83 : f32;
var<private> p4_nodeVar84 : bool;
var<private> p4_nodeVar85 : f32;
var<private> p4_Output : vec4<f32>;
var<private> p4_nodeVar86 : vec4<f32>;

// codes


fn p4_main(door_uv: vec2f) -> p4_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p4_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p4_nodeVar1 = 400000.0;
	p4_nodeVar2 = 400000.0;
	p4_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p4_nodeVar5 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar6 = ( p4_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p4_nodeVar7 = length( ( vec2<f32>( p4_nodeVar5.x, p4_nodeVar5.y ) - p4_nodeVar6 ) );
	p4_nodeVar8 = ( p4_nodeVar7 < p4_nodeVar1 );

	if ( p4_nodeVar8 ) {

		p4_nodeVar3 = vec2<f32>( p4_nodeVar5.x, p4_nodeVar5.y );

	} else {

		p4_nodeVar3 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar3, p4_nodeVar0.zw );

	if ( p4_nodeVar8 ) {

		p4_nodeVar9 = p4_nodeVar7;

	} else {

		p4_nodeVar9 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar9;
	p4_nodeVar11 = length( ( vec2<f32>( p4_nodeVar5.z, p4_nodeVar5.w ) - p4_nodeVar6 ) );
	p4_nodeVar12 = ( p4_nodeVar11 < p4_nodeVar2 );

	if ( p4_nodeVar12 ) {

		p4_nodeVar10 = vec2<f32>( p4_nodeVar5.z, p4_nodeVar5.w );

	} else {

		p4_nodeVar10 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar10 );

	if ( p4_nodeVar12 ) {

		p4_nodeVar13 = p4_nodeVar11;

	} else {

		p4_nodeVar13 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar13;
	p4_nodeVar15 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar16 = length( ( vec2<f32>( p4_nodeVar15.x, p4_nodeVar15.y ) - p4_nodeVar6 ) );
	p4_nodeVar17 = ( p4_nodeVar16 < p4_nodeVar1 );

	if ( p4_nodeVar17 ) {

		p4_nodeVar14 = vec2<f32>( p4_nodeVar15.x, p4_nodeVar15.y );

	} else {

		p4_nodeVar14 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar14, p4_nodeVar0.zw );

	if ( p4_nodeVar17 ) {

		p4_nodeVar18 = p4_nodeVar16;

	} else {

		p4_nodeVar18 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar18;
	p4_nodeVar20 = length( ( vec2<f32>( p4_nodeVar15.z, p4_nodeVar15.w ) - p4_nodeVar6 ) );
	p4_nodeVar21 = ( p4_nodeVar20 < p4_nodeVar2 );

	if ( p4_nodeVar21 ) {

		p4_nodeVar19 = vec2<f32>( p4_nodeVar15.z, p4_nodeVar15.w );

	} else {

		p4_nodeVar19 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar19 );

	if ( p4_nodeVar21 ) {

		p4_nodeVar22 = p4_nodeVar20;

	} else {

		p4_nodeVar22 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar22;
	p4_nodeVar24 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar25 = length( ( vec2<f32>( p4_nodeVar24.x, p4_nodeVar24.y ) - p4_nodeVar6 ) );
	p4_nodeVar26 = ( p4_nodeVar25 < p4_nodeVar1 );

	if ( p4_nodeVar26 ) {

		p4_nodeVar23 = vec2<f32>( p4_nodeVar24.x, p4_nodeVar24.y );

	} else {

		p4_nodeVar23 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar23, p4_nodeVar0.zw );

	if ( p4_nodeVar26 ) {

		p4_nodeVar27 = p4_nodeVar25;

	} else {

		p4_nodeVar27 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar27;
	p4_nodeVar29 = length( ( vec2<f32>( p4_nodeVar24.z, p4_nodeVar24.w ) - p4_nodeVar6 ) );
	p4_nodeVar30 = ( p4_nodeVar29 < p4_nodeVar2 );

	if ( p4_nodeVar30 ) {

		p4_nodeVar28 = vec2<f32>( p4_nodeVar24.z, p4_nodeVar24.w );

	} else {

		p4_nodeVar28 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar28 );

	if ( p4_nodeVar30 ) {

		p4_nodeVar31 = p4_nodeVar29;

	} else {

		p4_nodeVar31 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar31;
	p4_nodeVar33 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar34 = length( ( vec2<f32>( p4_nodeVar33.x, p4_nodeVar33.y ) - p4_nodeVar6 ) );
	p4_nodeVar35 = ( p4_nodeVar34 < p4_nodeVar1 );

	if ( p4_nodeVar35 ) {

		p4_nodeVar32 = vec2<f32>( p4_nodeVar33.x, p4_nodeVar33.y );

	} else {

		p4_nodeVar32 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar32, p4_nodeVar0.zw );

	if ( p4_nodeVar35 ) {

		p4_nodeVar36 = p4_nodeVar34;

	} else {

		p4_nodeVar36 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar36;
	p4_nodeVar38 = length( ( vec2<f32>( p4_nodeVar33.z, p4_nodeVar33.w ) - p4_nodeVar6 ) );
	p4_nodeVar39 = ( p4_nodeVar38 < p4_nodeVar2 );

	if ( p4_nodeVar39 ) {

		p4_nodeVar37 = vec2<f32>( p4_nodeVar33.z, p4_nodeVar33.w );

	} else {

		p4_nodeVar37 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar37 );

	if ( p4_nodeVar39 ) {

		p4_nodeVar40 = p4_nodeVar38;

	} else {

		p4_nodeVar40 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar40;
	p4_nodeVar42 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar43 = length( ( vec2<f32>( p4_nodeVar42.x, p4_nodeVar42.y ) - p4_nodeVar6 ) );
	p4_nodeVar44 = ( p4_nodeVar43 < p4_nodeVar1 );

	if ( p4_nodeVar44 ) {

		p4_nodeVar41 = vec2<f32>( p4_nodeVar42.x, p4_nodeVar42.y );

	} else {

		p4_nodeVar41 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar41, p4_nodeVar0.zw );

	if ( p4_nodeVar44 ) {

		p4_nodeVar45 = p4_nodeVar43;

	} else {

		p4_nodeVar45 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar45;
	p4_nodeVar47 = length( ( vec2<f32>( p4_nodeVar42.z, p4_nodeVar42.w ) - p4_nodeVar6 ) );
	p4_nodeVar48 = ( p4_nodeVar47 < p4_nodeVar2 );

	if ( p4_nodeVar48 ) {

		p4_nodeVar46 = vec2<f32>( p4_nodeVar42.z, p4_nodeVar42.w );

	} else {

		p4_nodeVar46 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar46 );

	if ( p4_nodeVar48 ) {

		p4_nodeVar49 = p4_nodeVar47;

	} else {

		p4_nodeVar49 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar49;
	p4_nodeVar51 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar52 = length( ( vec2<f32>( p4_nodeVar51.x, p4_nodeVar51.y ) - p4_nodeVar6 ) );
	p4_nodeVar53 = ( p4_nodeVar52 < p4_nodeVar1 );

	if ( p4_nodeVar53 ) {

		p4_nodeVar50 = vec2<f32>( p4_nodeVar51.x, p4_nodeVar51.y );

	} else {

		p4_nodeVar50 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar50, p4_nodeVar0.zw );

	if ( p4_nodeVar53 ) {

		p4_nodeVar54 = p4_nodeVar52;

	} else {

		p4_nodeVar54 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar54;
	p4_nodeVar56 = length( ( vec2<f32>( p4_nodeVar51.z, p4_nodeVar51.w ) - p4_nodeVar6 ) );
	p4_nodeVar57 = ( p4_nodeVar56 < p4_nodeVar2 );

	if ( p4_nodeVar57 ) {

		p4_nodeVar55 = vec2<f32>( p4_nodeVar51.z, p4_nodeVar51.w );

	} else {

		p4_nodeVar55 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar55 );

	if ( p4_nodeVar57 ) {

		p4_nodeVar58 = p4_nodeVar56;

	} else {

		p4_nodeVar58 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar58;
	p4_nodeVar60 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar61 = length( ( vec2<f32>( p4_nodeVar60.x, p4_nodeVar60.y ) - p4_nodeVar6 ) );
	p4_nodeVar62 = ( p4_nodeVar61 < p4_nodeVar1 );

	if ( p4_nodeVar62 ) {

		p4_nodeVar59 = vec2<f32>( p4_nodeVar60.x, p4_nodeVar60.y );

	} else {

		p4_nodeVar59 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar59, p4_nodeVar0.zw );

	if ( p4_nodeVar62 ) {

		p4_nodeVar63 = p4_nodeVar61;

	} else {

		p4_nodeVar63 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar63;
	p4_nodeVar65 = length( ( vec2<f32>( p4_nodeVar60.z, p4_nodeVar60.w ) - p4_nodeVar6 ) );
	p4_nodeVar66 = ( p4_nodeVar65 < p4_nodeVar2 );

	if ( p4_nodeVar66 ) {

		p4_nodeVar64 = vec2<f32>( p4_nodeVar60.z, p4_nodeVar60.w );

	} else {

		p4_nodeVar64 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar64 );

	if ( p4_nodeVar66 ) {

		p4_nodeVar67 = p4_nodeVar65;

	} else {

		p4_nodeVar67 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar67;
	p4_nodeVar69 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar70 = length( ( vec2<f32>( p4_nodeVar69.x, p4_nodeVar69.y ) - p4_nodeVar6 ) );
	p4_nodeVar71 = ( p4_nodeVar70 < p4_nodeVar1 );

	if ( p4_nodeVar71 ) {

		p4_nodeVar68 = vec2<f32>( p4_nodeVar69.x, p4_nodeVar69.y );

	} else {

		p4_nodeVar68 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar68, p4_nodeVar0.zw );

	if ( p4_nodeVar71 ) {

		p4_nodeVar72 = p4_nodeVar70;

	} else {

		p4_nodeVar72 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar72;
	p4_nodeVar74 = length( ( vec2<f32>( p4_nodeVar69.z, p4_nodeVar69.w ) - p4_nodeVar6 ) );
	p4_nodeVar75 = ( p4_nodeVar74 < p4_nodeVar2 );

	if ( p4_nodeVar75 ) {

		p4_nodeVar73 = vec2<f32>( p4_nodeVar69.z, p4_nodeVar69.w );

	} else {

		p4_nodeVar73 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar73 );

	if ( p4_nodeVar75 ) {

		p4_nodeVar76 = p4_nodeVar74;

	} else {

		p4_nodeVar76 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar76;
	p4_nodeVar78 = target_read( t1, t1_sampler, ( p4_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(8.0) ) ) ) );
	p4_nodeVar79 = length( ( vec2<f32>( p4_nodeVar78.x, p4_nodeVar78.y ) - p4_nodeVar6 ) );
	p4_nodeVar80 = ( p4_nodeVar79 < p4_nodeVar1 );

	if ( p4_nodeVar80 ) {

		p4_nodeVar77 = vec2<f32>( p4_nodeVar78.x, p4_nodeVar78.y );

	} else {

		p4_nodeVar77 = p4_nodeVar0.xy;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar77, p4_nodeVar0.zw );

	if ( p4_nodeVar80 ) {

		p4_nodeVar81 = p4_nodeVar79;

	} else {

		p4_nodeVar81 = p4_nodeVar1;

	}

	p4_nodeVar1 = p4_nodeVar81;
	p4_nodeVar83 = length( ( vec2<f32>( p4_nodeVar78.z, p4_nodeVar78.w ) - p4_nodeVar6 ) );
	p4_nodeVar84 = ( p4_nodeVar83 < p4_nodeVar2 );

	if ( p4_nodeVar84 ) {

		p4_nodeVar82 = vec2<f32>( p4_nodeVar78.z, p4_nodeVar78.w );

	} else {

		p4_nodeVar82 = p4_nodeVar0.zw;

	}

	p4_nodeVar0 = vec4<f32>( p4_nodeVar0.xy, p4_nodeVar82 );

	if ( p4_nodeVar84 ) {

		p4_nodeVar85 = p4_nodeVar83;

	} else {

		p4_nodeVar85 = p4_nodeVar2;

	}

	p4_nodeVar2 = p4_nodeVar85;
	p4_DiffuseColor = p4_nodeVar0;
	p4_DiffuseColor.w = ( p4_DiffuseColor.w * f32(1.0) );
	p4_nodeVar86 = max( vec4<f32>( p4_DiffuseColor.xyz, p4_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p4_Output = p4_nodeVar86;

	// result

	p4_output.color = p4_nodeVar86;

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
var<private> p5_nodeVar0 : vec4<f32>;
var<private> p5_nodeVar1 : f32;
var<private> p5_nodeVar2 : f32;
var<private> p5_nodeVar3 : vec2<f32>;
var<private> p5_nodeVar4 : vec2<f32>;
var<private> p5_nodeVar5 : vec4<f32>;
var<private> p5_nodeVar6 : vec2<f32>;
var<private> p5_nodeVar7 : f32;
var<private> p5_nodeVar8 : bool;
var<private> p5_nodeVar9 : f32;
var<private> p5_nodeVar10 : vec2<f32>;
var<private> p5_nodeVar11 : f32;
var<private> p5_nodeVar12 : bool;
var<private> p5_nodeVar13 : f32;
var<private> p5_nodeVar14 : vec2<f32>;
var<private> p5_nodeVar15 : vec4<f32>;
var<private> p5_nodeVar16 : f32;
var<private> p5_nodeVar17 : bool;
var<private> p5_nodeVar18 : f32;
var<private> p5_nodeVar19 : vec2<f32>;
var<private> p5_nodeVar20 : f32;
var<private> p5_nodeVar21 : bool;
var<private> p5_nodeVar22 : f32;
var<private> p5_nodeVar23 : vec2<f32>;
var<private> p5_nodeVar24 : vec4<f32>;
var<private> p5_nodeVar25 : f32;
var<private> p5_nodeVar26 : bool;
var<private> p5_nodeVar27 : f32;
var<private> p5_nodeVar28 : vec2<f32>;
var<private> p5_nodeVar29 : f32;
var<private> p5_nodeVar30 : bool;
var<private> p5_nodeVar31 : f32;
var<private> p5_nodeVar32 : vec2<f32>;
var<private> p5_nodeVar33 : vec4<f32>;
var<private> p5_nodeVar34 : f32;
var<private> p5_nodeVar35 : bool;
var<private> p5_nodeVar36 : f32;
var<private> p5_nodeVar37 : vec2<f32>;
var<private> p5_nodeVar38 : f32;
var<private> p5_nodeVar39 : bool;
var<private> p5_nodeVar40 : f32;
var<private> p5_nodeVar41 : vec2<f32>;
var<private> p5_nodeVar42 : vec4<f32>;
var<private> p5_nodeVar43 : f32;
var<private> p5_nodeVar44 : bool;
var<private> p5_nodeVar45 : f32;
var<private> p5_nodeVar46 : vec2<f32>;
var<private> p5_nodeVar47 : f32;
var<private> p5_nodeVar48 : bool;
var<private> p5_nodeVar49 : f32;
var<private> p5_nodeVar50 : vec2<f32>;
var<private> p5_nodeVar51 : vec4<f32>;
var<private> p5_nodeVar52 : f32;
var<private> p5_nodeVar53 : bool;
var<private> p5_nodeVar54 : f32;
var<private> p5_nodeVar55 : vec2<f32>;
var<private> p5_nodeVar56 : f32;
var<private> p5_nodeVar57 : bool;
var<private> p5_nodeVar58 : f32;
var<private> p5_nodeVar59 : vec2<f32>;
var<private> p5_nodeVar60 : vec4<f32>;
var<private> p5_nodeVar61 : f32;
var<private> p5_nodeVar62 : bool;
var<private> p5_nodeVar63 : f32;
var<private> p5_nodeVar64 : vec2<f32>;
var<private> p5_nodeVar65 : f32;
var<private> p5_nodeVar66 : bool;
var<private> p5_nodeVar67 : f32;
var<private> p5_nodeVar68 : vec2<f32>;
var<private> p5_nodeVar69 : vec4<f32>;
var<private> p5_nodeVar70 : f32;
var<private> p5_nodeVar71 : bool;
var<private> p5_nodeVar72 : f32;
var<private> p5_nodeVar73 : vec2<f32>;
var<private> p5_nodeVar74 : f32;
var<private> p5_nodeVar75 : bool;
var<private> p5_nodeVar76 : f32;
var<private> p5_nodeVar77 : vec2<f32>;
var<private> p5_nodeVar78 : vec4<f32>;
var<private> p5_nodeVar79 : f32;
var<private> p5_nodeVar80 : bool;
var<private> p5_nodeVar81 : f32;
var<private> p5_nodeVar82 : vec2<f32>;
var<private> p5_nodeVar83 : f32;
var<private> p5_nodeVar84 : bool;
var<private> p5_nodeVar85 : f32;
var<private> p5_Output : vec4<f32>;
var<private> p5_nodeVar86 : vec4<f32>;

// codes


fn p5_main(door_uv: vec2f) -> p5_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p5_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p5_nodeVar1 = 400000.0;
	p5_nodeVar2 = 400000.0;
	p5_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p5_nodeVar5 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar6 = ( p5_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p5_nodeVar7 = length( ( vec2<f32>( p5_nodeVar5.x, p5_nodeVar5.y ) - p5_nodeVar6 ) );
	p5_nodeVar8 = ( p5_nodeVar7 < p5_nodeVar1 );

	if ( p5_nodeVar8 ) {

		p5_nodeVar3 = vec2<f32>( p5_nodeVar5.x, p5_nodeVar5.y );

	} else {

		p5_nodeVar3 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar3, p5_nodeVar0.zw );

	if ( p5_nodeVar8 ) {

		p5_nodeVar9 = p5_nodeVar7;

	} else {

		p5_nodeVar9 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar9;
	p5_nodeVar11 = length( ( vec2<f32>( p5_nodeVar5.z, p5_nodeVar5.w ) - p5_nodeVar6 ) );
	p5_nodeVar12 = ( p5_nodeVar11 < p5_nodeVar2 );

	if ( p5_nodeVar12 ) {

		p5_nodeVar10 = vec2<f32>( p5_nodeVar5.z, p5_nodeVar5.w );

	} else {

		p5_nodeVar10 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar10 );

	if ( p5_nodeVar12 ) {

		p5_nodeVar13 = p5_nodeVar11;

	} else {

		p5_nodeVar13 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar13;
	p5_nodeVar15 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar16 = length( ( vec2<f32>( p5_nodeVar15.x, p5_nodeVar15.y ) - p5_nodeVar6 ) );
	p5_nodeVar17 = ( p5_nodeVar16 < p5_nodeVar1 );

	if ( p5_nodeVar17 ) {

		p5_nodeVar14 = vec2<f32>( p5_nodeVar15.x, p5_nodeVar15.y );

	} else {

		p5_nodeVar14 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar14, p5_nodeVar0.zw );

	if ( p5_nodeVar17 ) {

		p5_nodeVar18 = p5_nodeVar16;

	} else {

		p5_nodeVar18 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar18;
	p5_nodeVar20 = length( ( vec2<f32>( p5_nodeVar15.z, p5_nodeVar15.w ) - p5_nodeVar6 ) );
	p5_nodeVar21 = ( p5_nodeVar20 < p5_nodeVar2 );

	if ( p5_nodeVar21 ) {

		p5_nodeVar19 = vec2<f32>( p5_nodeVar15.z, p5_nodeVar15.w );

	} else {

		p5_nodeVar19 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar19 );

	if ( p5_nodeVar21 ) {

		p5_nodeVar22 = p5_nodeVar20;

	} else {

		p5_nodeVar22 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar22;
	p5_nodeVar24 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar25 = length( ( vec2<f32>( p5_nodeVar24.x, p5_nodeVar24.y ) - p5_nodeVar6 ) );
	p5_nodeVar26 = ( p5_nodeVar25 < p5_nodeVar1 );

	if ( p5_nodeVar26 ) {

		p5_nodeVar23 = vec2<f32>( p5_nodeVar24.x, p5_nodeVar24.y );

	} else {

		p5_nodeVar23 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar23, p5_nodeVar0.zw );

	if ( p5_nodeVar26 ) {

		p5_nodeVar27 = p5_nodeVar25;

	} else {

		p5_nodeVar27 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar27;
	p5_nodeVar29 = length( ( vec2<f32>( p5_nodeVar24.z, p5_nodeVar24.w ) - p5_nodeVar6 ) );
	p5_nodeVar30 = ( p5_nodeVar29 < p5_nodeVar2 );

	if ( p5_nodeVar30 ) {

		p5_nodeVar28 = vec2<f32>( p5_nodeVar24.z, p5_nodeVar24.w );

	} else {

		p5_nodeVar28 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar28 );

	if ( p5_nodeVar30 ) {

		p5_nodeVar31 = p5_nodeVar29;

	} else {

		p5_nodeVar31 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar31;
	p5_nodeVar33 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar34 = length( ( vec2<f32>( p5_nodeVar33.x, p5_nodeVar33.y ) - p5_nodeVar6 ) );
	p5_nodeVar35 = ( p5_nodeVar34 < p5_nodeVar1 );

	if ( p5_nodeVar35 ) {

		p5_nodeVar32 = vec2<f32>( p5_nodeVar33.x, p5_nodeVar33.y );

	} else {

		p5_nodeVar32 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar32, p5_nodeVar0.zw );

	if ( p5_nodeVar35 ) {

		p5_nodeVar36 = p5_nodeVar34;

	} else {

		p5_nodeVar36 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar36;
	p5_nodeVar38 = length( ( vec2<f32>( p5_nodeVar33.z, p5_nodeVar33.w ) - p5_nodeVar6 ) );
	p5_nodeVar39 = ( p5_nodeVar38 < p5_nodeVar2 );

	if ( p5_nodeVar39 ) {

		p5_nodeVar37 = vec2<f32>( p5_nodeVar33.z, p5_nodeVar33.w );

	} else {

		p5_nodeVar37 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar37 );

	if ( p5_nodeVar39 ) {

		p5_nodeVar40 = p5_nodeVar38;

	} else {

		p5_nodeVar40 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar40;
	p5_nodeVar42 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar43 = length( ( vec2<f32>( p5_nodeVar42.x, p5_nodeVar42.y ) - p5_nodeVar6 ) );
	p5_nodeVar44 = ( p5_nodeVar43 < p5_nodeVar1 );

	if ( p5_nodeVar44 ) {

		p5_nodeVar41 = vec2<f32>( p5_nodeVar42.x, p5_nodeVar42.y );

	} else {

		p5_nodeVar41 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar41, p5_nodeVar0.zw );

	if ( p5_nodeVar44 ) {

		p5_nodeVar45 = p5_nodeVar43;

	} else {

		p5_nodeVar45 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar45;
	p5_nodeVar47 = length( ( vec2<f32>( p5_nodeVar42.z, p5_nodeVar42.w ) - p5_nodeVar6 ) );
	p5_nodeVar48 = ( p5_nodeVar47 < p5_nodeVar2 );

	if ( p5_nodeVar48 ) {

		p5_nodeVar46 = vec2<f32>( p5_nodeVar42.z, p5_nodeVar42.w );

	} else {

		p5_nodeVar46 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar46 );

	if ( p5_nodeVar48 ) {

		p5_nodeVar49 = p5_nodeVar47;

	} else {

		p5_nodeVar49 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar49;
	p5_nodeVar51 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar52 = length( ( vec2<f32>( p5_nodeVar51.x, p5_nodeVar51.y ) - p5_nodeVar6 ) );
	p5_nodeVar53 = ( p5_nodeVar52 < p5_nodeVar1 );

	if ( p5_nodeVar53 ) {

		p5_nodeVar50 = vec2<f32>( p5_nodeVar51.x, p5_nodeVar51.y );

	} else {

		p5_nodeVar50 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar50, p5_nodeVar0.zw );

	if ( p5_nodeVar53 ) {

		p5_nodeVar54 = p5_nodeVar52;

	} else {

		p5_nodeVar54 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar54;
	p5_nodeVar56 = length( ( vec2<f32>( p5_nodeVar51.z, p5_nodeVar51.w ) - p5_nodeVar6 ) );
	p5_nodeVar57 = ( p5_nodeVar56 < p5_nodeVar2 );

	if ( p5_nodeVar57 ) {

		p5_nodeVar55 = vec2<f32>( p5_nodeVar51.z, p5_nodeVar51.w );

	} else {

		p5_nodeVar55 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar55 );

	if ( p5_nodeVar57 ) {

		p5_nodeVar58 = p5_nodeVar56;

	} else {

		p5_nodeVar58 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar58;
	p5_nodeVar60 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar61 = length( ( vec2<f32>( p5_nodeVar60.x, p5_nodeVar60.y ) - p5_nodeVar6 ) );
	p5_nodeVar62 = ( p5_nodeVar61 < p5_nodeVar1 );

	if ( p5_nodeVar62 ) {

		p5_nodeVar59 = vec2<f32>( p5_nodeVar60.x, p5_nodeVar60.y );

	} else {

		p5_nodeVar59 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar59, p5_nodeVar0.zw );

	if ( p5_nodeVar62 ) {

		p5_nodeVar63 = p5_nodeVar61;

	} else {

		p5_nodeVar63 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar63;
	p5_nodeVar65 = length( ( vec2<f32>( p5_nodeVar60.z, p5_nodeVar60.w ) - p5_nodeVar6 ) );
	p5_nodeVar66 = ( p5_nodeVar65 < p5_nodeVar2 );

	if ( p5_nodeVar66 ) {

		p5_nodeVar64 = vec2<f32>( p5_nodeVar60.z, p5_nodeVar60.w );

	} else {

		p5_nodeVar64 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar64 );

	if ( p5_nodeVar66 ) {

		p5_nodeVar67 = p5_nodeVar65;

	} else {

		p5_nodeVar67 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar67;
	p5_nodeVar69 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar70 = length( ( vec2<f32>( p5_nodeVar69.x, p5_nodeVar69.y ) - p5_nodeVar6 ) );
	p5_nodeVar71 = ( p5_nodeVar70 < p5_nodeVar1 );

	if ( p5_nodeVar71 ) {

		p5_nodeVar68 = vec2<f32>( p5_nodeVar69.x, p5_nodeVar69.y );

	} else {

		p5_nodeVar68 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar68, p5_nodeVar0.zw );

	if ( p5_nodeVar71 ) {

		p5_nodeVar72 = p5_nodeVar70;

	} else {

		p5_nodeVar72 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar72;
	p5_nodeVar74 = length( ( vec2<f32>( p5_nodeVar69.z, p5_nodeVar69.w ) - p5_nodeVar6 ) );
	p5_nodeVar75 = ( p5_nodeVar74 < p5_nodeVar2 );

	if ( p5_nodeVar75 ) {

		p5_nodeVar73 = vec2<f32>( p5_nodeVar69.z, p5_nodeVar69.w );

	} else {

		p5_nodeVar73 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar73 );

	if ( p5_nodeVar75 ) {

		p5_nodeVar76 = p5_nodeVar74;

	} else {

		p5_nodeVar76 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar76;
	p5_nodeVar78 = target_read( t0, t0_sampler, ( p5_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(4.0) ) ) ) );
	p5_nodeVar79 = length( ( vec2<f32>( p5_nodeVar78.x, p5_nodeVar78.y ) - p5_nodeVar6 ) );
	p5_nodeVar80 = ( p5_nodeVar79 < p5_nodeVar1 );

	if ( p5_nodeVar80 ) {

		p5_nodeVar77 = vec2<f32>( p5_nodeVar78.x, p5_nodeVar78.y );

	} else {

		p5_nodeVar77 = p5_nodeVar0.xy;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar77, p5_nodeVar0.zw );

	if ( p5_nodeVar80 ) {

		p5_nodeVar81 = p5_nodeVar79;

	} else {

		p5_nodeVar81 = p5_nodeVar1;

	}

	p5_nodeVar1 = p5_nodeVar81;
	p5_nodeVar83 = length( ( vec2<f32>( p5_nodeVar78.z, p5_nodeVar78.w ) - p5_nodeVar6 ) );
	p5_nodeVar84 = ( p5_nodeVar83 < p5_nodeVar2 );

	if ( p5_nodeVar84 ) {

		p5_nodeVar82 = vec2<f32>( p5_nodeVar78.z, p5_nodeVar78.w );

	} else {

		p5_nodeVar82 = p5_nodeVar0.zw;

	}

	p5_nodeVar0 = vec4<f32>( p5_nodeVar0.xy, p5_nodeVar82 );

	if ( p5_nodeVar84 ) {

		p5_nodeVar85 = p5_nodeVar83;

	} else {

		p5_nodeVar85 = p5_nodeVar2;

	}

	p5_nodeVar2 = p5_nodeVar85;
	p5_DiffuseColor = p5_nodeVar0;
	p5_DiffuseColor.w = ( p5_DiffuseColor.w * f32(1.0) );
	p5_nodeVar86 = max( vec4<f32>( p5_DiffuseColor.xyz, p5_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p5_Output = p5_nodeVar86;

	// result

	p5_output.color = p5_nodeVar86;

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
var<private> p6_nodeVar0 : vec4<f32>;
var<private> p6_nodeVar1 : f32;
var<private> p6_nodeVar2 : f32;
var<private> p6_nodeVar3 : vec2<f32>;
var<private> p6_nodeVar4 : vec2<f32>;
var<private> p6_nodeVar5 : vec4<f32>;
var<private> p6_nodeVar6 : vec2<f32>;
var<private> p6_nodeVar7 : f32;
var<private> p6_nodeVar8 : bool;
var<private> p6_nodeVar9 : f32;
var<private> p6_nodeVar10 : vec2<f32>;
var<private> p6_nodeVar11 : f32;
var<private> p6_nodeVar12 : bool;
var<private> p6_nodeVar13 : f32;
var<private> p6_nodeVar14 : vec2<f32>;
var<private> p6_nodeVar15 : vec4<f32>;
var<private> p6_nodeVar16 : f32;
var<private> p6_nodeVar17 : bool;
var<private> p6_nodeVar18 : f32;
var<private> p6_nodeVar19 : vec2<f32>;
var<private> p6_nodeVar20 : f32;
var<private> p6_nodeVar21 : bool;
var<private> p6_nodeVar22 : f32;
var<private> p6_nodeVar23 : vec2<f32>;
var<private> p6_nodeVar24 : vec4<f32>;
var<private> p6_nodeVar25 : f32;
var<private> p6_nodeVar26 : bool;
var<private> p6_nodeVar27 : f32;
var<private> p6_nodeVar28 : vec2<f32>;
var<private> p6_nodeVar29 : f32;
var<private> p6_nodeVar30 : bool;
var<private> p6_nodeVar31 : f32;
var<private> p6_nodeVar32 : vec2<f32>;
var<private> p6_nodeVar33 : vec4<f32>;
var<private> p6_nodeVar34 : f32;
var<private> p6_nodeVar35 : bool;
var<private> p6_nodeVar36 : f32;
var<private> p6_nodeVar37 : vec2<f32>;
var<private> p6_nodeVar38 : f32;
var<private> p6_nodeVar39 : bool;
var<private> p6_nodeVar40 : f32;
var<private> p6_nodeVar41 : vec2<f32>;
var<private> p6_nodeVar42 : vec4<f32>;
var<private> p6_nodeVar43 : f32;
var<private> p6_nodeVar44 : bool;
var<private> p6_nodeVar45 : f32;
var<private> p6_nodeVar46 : vec2<f32>;
var<private> p6_nodeVar47 : f32;
var<private> p6_nodeVar48 : bool;
var<private> p6_nodeVar49 : f32;
var<private> p6_nodeVar50 : vec2<f32>;
var<private> p6_nodeVar51 : vec4<f32>;
var<private> p6_nodeVar52 : f32;
var<private> p6_nodeVar53 : bool;
var<private> p6_nodeVar54 : f32;
var<private> p6_nodeVar55 : vec2<f32>;
var<private> p6_nodeVar56 : f32;
var<private> p6_nodeVar57 : bool;
var<private> p6_nodeVar58 : f32;
var<private> p6_nodeVar59 : vec2<f32>;
var<private> p6_nodeVar60 : vec4<f32>;
var<private> p6_nodeVar61 : f32;
var<private> p6_nodeVar62 : bool;
var<private> p6_nodeVar63 : f32;
var<private> p6_nodeVar64 : vec2<f32>;
var<private> p6_nodeVar65 : f32;
var<private> p6_nodeVar66 : bool;
var<private> p6_nodeVar67 : f32;
var<private> p6_nodeVar68 : vec2<f32>;
var<private> p6_nodeVar69 : vec4<f32>;
var<private> p6_nodeVar70 : f32;
var<private> p6_nodeVar71 : bool;
var<private> p6_nodeVar72 : f32;
var<private> p6_nodeVar73 : vec2<f32>;
var<private> p6_nodeVar74 : f32;
var<private> p6_nodeVar75 : bool;
var<private> p6_nodeVar76 : f32;
var<private> p6_nodeVar77 : vec2<f32>;
var<private> p6_nodeVar78 : vec4<f32>;
var<private> p6_nodeVar79 : f32;
var<private> p6_nodeVar80 : bool;
var<private> p6_nodeVar81 : f32;
var<private> p6_nodeVar82 : vec2<f32>;
var<private> p6_nodeVar83 : f32;
var<private> p6_nodeVar84 : bool;
var<private> p6_nodeVar85 : f32;
var<private> p6_Output : vec4<f32>;
var<private> p6_nodeVar86 : vec4<f32>;

// codes


fn p6_main(door_uv: vec2f) -> p6_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p6_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p6_nodeVar1 = 400000.0;
	p6_nodeVar2 = 400000.0;
	p6_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p6_nodeVar5 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar6 = ( p6_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p6_nodeVar7 = length( ( vec2<f32>( p6_nodeVar5.x, p6_nodeVar5.y ) - p6_nodeVar6 ) );
	p6_nodeVar8 = ( p6_nodeVar7 < p6_nodeVar1 );

	if ( p6_nodeVar8 ) {

		p6_nodeVar3 = vec2<f32>( p6_nodeVar5.x, p6_nodeVar5.y );

	} else {

		p6_nodeVar3 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar3, p6_nodeVar0.zw );

	if ( p6_nodeVar8 ) {

		p6_nodeVar9 = p6_nodeVar7;

	} else {

		p6_nodeVar9 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar9;
	p6_nodeVar11 = length( ( vec2<f32>( p6_nodeVar5.z, p6_nodeVar5.w ) - p6_nodeVar6 ) );
	p6_nodeVar12 = ( p6_nodeVar11 < p6_nodeVar2 );

	if ( p6_nodeVar12 ) {

		p6_nodeVar10 = vec2<f32>( p6_nodeVar5.z, p6_nodeVar5.w );

	} else {

		p6_nodeVar10 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar10 );

	if ( p6_nodeVar12 ) {

		p6_nodeVar13 = p6_nodeVar11;

	} else {

		p6_nodeVar13 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar13;
	p6_nodeVar15 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar16 = length( ( vec2<f32>( p6_nodeVar15.x, p6_nodeVar15.y ) - p6_nodeVar6 ) );
	p6_nodeVar17 = ( p6_nodeVar16 < p6_nodeVar1 );

	if ( p6_nodeVar17 ) {

		p6_nodeVar14 = vec2<f32>( p6_nodeVar15.x, p6_nodeVar15.y );

	} else {

		p6_nodeVar14 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar14, p6_nodeVar0.zw );

	if ( p6_nodeVar17 ) {

		p6_nodeVar18 = p6_nodeVar16;

	} else {

		p6_nodeVar18 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar18;
	p6_nodeVar20 = length( ( vec2<f32>( p6_nodeVar15.z, p6_nodeVar15.w ) - p6_nodeVar6 ) );
	p6_nodeVar21 = ( p6_nodeVar20 < p6_nodeVar2 );

	if ( p6_nodeVar21 ) {

		p6_nodeVar19 = vec2<f32>( p6_nodeVar15.z, p6_nodeVar15.w );

	} else {

		p6_nodeVar19 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar19 );

	if ( p6_nodeVar21 ) {

		p6_nodeVar22 = p6_nodeVar20;

	} else {

		p6_nodeVar22 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar22;
	p6_nodeVar24 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar25 = length( ( vec2<f32>( p6_nodeVar24.x, p6_nodeVar24.y ) - p6_nodeVar6 ) );
	p6_nodeVar26 = ( p6_nodeVar25 < p6_nodeVar1 );

	if ( p6_nodeVar26 ) {

		p6_nodeVar23 = vec2<f32>( p6_nodeVar24.x, p6_nodeVar24.y );

	} else {

		p6_nodeVar23 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar23, p6_nodeVar0.zw );

	if ( p6_nodeVar26 ) {

		p6_nodeVar27 = p6_nodeVar25;

	} else {

		p6_nodeVar27 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar27;
	p6_nodeVar29 = length( ( vec2<f32>( p6_nodeVar24.z, p6_nodeVar24.w ) - p6_nodeVar6 ) );
	p6_nodeVar30 = ( p6_nodeVar29 < p6_nodeVar2 );

	if ( p6_nodeVar30 ) {

		p6_nodeVar28 = vec2<f32>( p6_nodeVar24.z, p6_nodeVar24.w );

	} else {

		p6_nodeVar28 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar28 );

	if ( p6_nodeVar30 ) {

		p6_nodeVar31 = p6_nodeVar29;

	} else {

		p6_nodeVar31 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar31;
	p6_nodeVar33 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar34 = length( ( vec2<f32>( p6_nodeVar33.x, p6_nodeVar33.y ) - p6_nodeVar6 ) );
	p6_nodeVar35 = ( p6_nodeVar34 < p6_nodeVar1 );

	if ( p6_nodeVar35 ) {

		p6_nodeVar32 = vec2<f32>( p6_nodeVar33.x, p6_nodeVar33.y );

	} else {

		p6_nodeVar32 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar32, p6_nodeVar0.zw );

	if ( p6_nodeVar35 ) {

		p6_nodeVar36 = p6_nodeVar34;

	} else {

		p6_nodeVar36 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar36;
	p6_nodeVar38 = length( ( vec2<f32>( p6_nodeVar33.z, p6_nodeVar33.w ) - p6_nodeVar6 ) );
	p6_nodeVar39 = ( p6_nodeVar38 < p6_nodeVar2 );

	if ( p6_nodeVar39 ) {

		p6_nodeVar37 = vec2<f32>( p6_nodeVar33.z, p6_nodeVar33.w );

	} else {

		p6_nodeVar37 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar37 );

	if ( p6_nodeVar39 ) {

		p6_nodeVar40 = p6_nodeVar38;

	} else {

		p6_nodeVar40 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar40;
	p6_nodeVar42 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar43 = length( ( vec2<f32>( p6_nodeVar42.x, p6_nodeVar42.y ) - p6_nodeVar6 ) );
	p6_nodeVar44 = ( p6_nodeVar43 < p6_nodeVar1 );

	if ( p6_nodeVar44 ) {

		p6_nodeVar41 = vec2<f32>( p6_nodeVar42.x, p6_nodeVar42.y );

	} else {

		p6_nodeVar41 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar41, p6_nodeVar0.zw );

	if ( p6_nodeVar44 ) {

		p6_nodeVar45 = p6_nodeVar43;

	} else {

		p6_nodeVar45 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar45;
	p6_nodeVar47 = length( ( vec2<f32>( p6_nodeVar42.z, p6_nodeVar42.w ) - p6_nodeVar6 ) );
	p6_nodeVar48 = ( p6_nodeVar47 < p6_nodeVar2 );

	if ( p6_nodeVar48 ) {

		p6_nodeVar46 = vec2<f32>( p6_nodeVar42.z, p6_nodeVar42.w );

	} else {

		p6_nodeVar46 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar46 );

	if ( p6_nodeVar48 ) {

		p6_nodeVar49 = p6_nodeVar47;

	} else {

		p6_nodeVar49 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar49;
	p6_nodeVar51 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar52 = length( ( vec2<f32>( p6_nodeVar51.x, p6_nodeVar51.y ) - p6_nodeVar6 ) );
	p6_nodeVar53 = ( p6_nodeVar52 < p6_nodeVar1 );

	if ( p6_nodeVar53 ) {

		p6_nodeVar50 = vec2<f32>( p6_nodeVar51.x, p6_nodeVar51.y );

	} else {

		p6_nodeVar50 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar50, p6_nodeVar0.zw );

	if ( p6_nodeVar53 ) {

		p6_nodeVar54 = p6_nodeVar52;

	} else {

		p6_nodeVar54 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar54;
	p6_nodeVar56 = length( ( vec2<f32>( p6_nodeVar51.z, p6_nodeVar51.w ) - p6_nodeVar6 ) );
	p6_nodeVar57 = ( p6_nodeVar56 < p6_nodeVar2 );

	if ( p6_nodeVar57 ) {

		p6_nodeVar55 = vec2<f32>( p6_nodeVar51.z, p6_nodeVar51.w );

	} else {

		p6_nodeVar55 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar55 );

	if ( p6_nodeVar57 ) {

		p6_nodeVar58 = p6_nodeVar56;

	} else {

		p6_nodeVar58 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar58;
	p6_nodeVar60 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar61 = length( ( vec2<f32>( p6_nodeVar60.x, p6_nodeVar60.y ) - p6_nodeVar6 ) );
	p6_nodeVar62 = ( p6_nodeVar61 < p6_nodeVar1 );

	if ( p6_nodeVar62 ) {

		p6_nodeVar59 = vec2<f32>( p6_nodeVar60.x, p6_nodeVar60.y );

	} else {

		p6_nodeVar59 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar59, p6_nodeVar0.zw );

	if ( p6_nodeVar62 ) {

		p6_nodeVar63 = p6_nodeVar61;

	} else {

		p6_nodeVar63 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar63;
	p6_nodeVar65 = length( ( vec2<f32>( p6_nodeVar60.z, p6_nodeVar60.w ) - p6_nodeVar6 ) );
	p6_nodeVar66 = ( p6_nodeVar65 < p6_nodeVar2 );

	if ( p6_nodeVar66 ) {

		p6_nodeVar64 = vec2<f32>( p6_nodeVar60.z, p6_nodeVar60.w );

	} else {

		p6_nodeVar64 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar64 );

	if ( p6_nodeVar66 ) {

		p6_nodeVar67 = p6_nodeVar65;

	} else {

		p6_nodeVar67 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar67;
	p6_nodeVar69 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar70 = length( ( vec2<f32>( p6_nodeVar69.x, p6_nodeVar69.y ) - p6_nodeVar6 ) );
	p6_nodeVar71 = ( p6_nodeVar70 < p6_nodeVar1 );

	if ( p6_nodeVar71 ) {

		p6_nodeVar68 = vec2<f32>( p6_nodeVar69.x, p6_nodeVar69.y );

	} else {

		p6_nodeVar68 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar68, p6_nodeVar0.zw );

	if ( p6_nodeVar71 ) {

		p6_nodeVar72 = p6_nodeVar70;

	} else {

		p6_nodeVar72 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar72;
	p6_nodeVar74 = length( ( vec2<f32>( p6_nodeVar69.z, p6_nodeVar69.w ) - p6_nodeVar6 ) );
	p6_nodeVar75 = ( p6_nodeVar74 < p6_nodeVar2 );

	if ( p6_nodeVar75 ) {

		p6_nodeVar73 = vec2<f32>( p6_nodeVar69.z, p6_nodeVar69.w );

	} else {

		p6_nodeVar73 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar73 );

	if ( p6_nodeVar75 ) {

		p6_nodeVar76 = p6_nodeVar74;

	} else {

		p6_nodeVar76 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar76;
	p6_nodeVar78 = target_read( t1, t1_sampler, ( p6_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(2.0) ) ) ) );
	p6_nodeVar79 = length( ( vec2<f32>( p6_nodeVar78.x, p6_nodeVar78.y ) - p6_nodeVar6 ) );
	p6_nodeVar80 = ( p6_nodeVar79 < p6_nodeVar1 );

	if ( p6_nodeVar80 ) {

		p6_nodeVar77 = vec2<f32>( p6_nodeVar78.x, p6_nodeVar78.y );

	} else {

		p6_nodeVar77 = p6_nodeVar0.xy;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar77, p6_nodeVar0.zw );

	if ( p6_nodeVar80 ) {

		p6_nodeVar81 = p6_nodeVar79;

	} else {

		p6_nodeVar81 = p6_nodeVar1;

	}

	p6_nodeVar1 = p6_nodeVar81;
	p6_nodeVar83 = length( ( vec2<f32>( p6_nodeVar78.z, p6_nodeVar78.w ) - p6_nodeVar6 ) );
	p6_nodeVar84 = ( p6_nodeVar83 < p6_nodeVar2 );

	if ( p6_nodeVar84 ) {

		p6_nodeVar82 = vec2<f32>( p6_nodeVar78.z, p6_nodeVar78.w );

	} else {

		p6_nodeVar82 = p6_nodeVar0.zw;

	}

	p6_nodeVar0 = vec4<f32>( p6_nodeVar0.xy, p6_nodeVar82 );

	if ( p6_nodeVar84 ) {

		p6_nodeVar85 = p6_nodeVar83;

	} else {

		p6_nodeVar85 = p6_nodeVar2;

	}

	p6_nodeVar2 = p6_nodeVar85;
	p6_DiffuseColor = p6_nodeVar0;
	p6_DiffuseColor.w = ( p6_DiffuseColor.w * f32(1.0) );
	p6_nodeVar86 = max( vec4<f32>( p6_DiffuseColor.xyz, p6_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p6_Output = p6_nodeVar86;

	// result

	p6_output.color = p6_nodeVar86;

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
var<private> p7_nodeVar0 : vec4<f32>;
var<private> p7_nodeVar1 : f32;
var<private> p7_nodeVar2 : f32;
var<private> p7_nodeVar3 : vec2<f32>;
var<private> p7_nodeVar4 : vec2<f32>;
var<private> p7_nodeVar5 : vec4<f32>;
var<private> p7_nodeVar6 : vec2<f32>;
var<private> p7_nodeVar7 : f32;
var<private> p7_nodeVar8 : bool;
var<private> p7_nodeVar9 : f32;
var<private> p7_nodeVar10 : vec2<f32>;
var<private> p7_nodeVar11 : f32;
var<private> p7_nodeVar12 : bool;
var<private> p7_nodeVar13 : f32;
var<private> p7_nodeVar14 : vec2<f32>;
var<private> p7_nodeVar15 : vec4<f32>;
var<private> p7_nodeVar16 : f32;
var<private> p7_nodeVar17 : bool;
var<private> p7_nodeVar18 : f32;
var<private> p7_nodeVar19 : vec2<f32>;
var<private> p7_nodeVar20 : f32;
var<private> p7_nodeVar21 : bool;
var<private> p7_nodeVar22 : f32;
var<private> p7_nodeVar23 : vec2<f32>;
var<private> p7_nodeVar24 : vec4<f32>;
var<private> p7_nodeVar25 : f32;
var<private> p7_nodeVar26 : bool;
var<private> p7_nodeVar27 : f32;
var<private> p7_nodeVar28 : vec2<f32>;
var<private> p7_nodeVar29 : f32;
var<private> p7_nodeVar30 : bool;
var<private> p7_nodeVar31 : f32;
var<private> p7_nodeVar32 : vec2<f32>;
var<private> p7_nodeVar33 : vec4<f32>;
var<private> p7_nodeVar34 : f32;
var<private> p7_nodeVar35 : bool;
var<private> p7_nodeVar36 : f32;
var<private> p7_nodeVar37 : vec2<f32>;
var<private> p7_nodeVar38 : f32;
var<private> p7_nodeVar39 : bool;
var<private> p7_nodeVar40 : f32;
var<private> p7_nodeVar41 : vec2<f32>;
var<private> p7_nodeVar42 : vec4<f32>;
var<private> p7_nodeVar43 : f32;
var<private> p7_nodeVar44 : bool;
var<private> p7_nodeVar45 : f32;
var<private> p7_nodeVar46 : vec2<f32>;
var<private> p7_nodeVar47 : f32;
var<private> p7_nodeVar48 : bool;
var<private> p7_nodeVar49 : f32;
var<private> p7_nodeVar50 : vec2<f32>;
var<private> p7_nodeVar51 : vec4<f32>;
var<private> p7_nodeVar52 : f32;
var<private> p7_nodeVar53 : bool;
var<private> p7_nodeVar54 : f32;
var<private> p7_nodeVar55 : vec2<f32>;
var<private> p7_nodeVar56 : f32;
var<private> p7_nodeVar57 : bool;
var<private> p7_nodeVar58 : f32;
var<private> p7_nodeVar59 : vec2<f32>;
var<private> p7_nodeVar60 : vec4<f32>;
var<private> p7_nodeVar61 : f32;
var<private> p7_nodeVar62 : bool;
var<private> p7_nodeVar63 : f32;
var<private> p7_nodeVar64 : vec2<f32>;
var<private> p7_nodeVar65 : f32;
var<private> p7_nodeVar66 : bool;
var<private> p7_nodeVar67 : f32;
var<private> p7_nodeVar68 : vec2<f32>;
var<private> p7_nodeVar69 : vec4<f32>;
var<private> p7_nodeVar70 : f32;
var<private> p7_nodeVar71 : bool;
var<private> p7_nodeVar72 : f32;
var<private> p7_nodeVar73 : vec2<f32>;
var<private> p7_nodeVar74 : f32;
var<private> p7_nodeVar75 : bool;
var<private> p7_nodeVar76 : f32;
var<private> p7_nodeVar77 : vec2<f32>;
var<private> p7_nodeVar78 : vec4<f32>;
var<private> p7_nodeVar79 : f32;
var<private> p7_nodeVar80 : bool;
var<private> p7_nodeVar81 : f32;
var<private> p7_nodeVar82 : vec2<f32>;
var<private> p7_nodeVar83 : f32;
var<private> p7_nodeVar84 : bool;
var<private> p7_nodeVar85 : f32;
var<private> p7_Output : vec4<f32>;
var<private> p7_nodeVar86 : vec4<f32>;

// codes


fn p7_main(door_uv: vec2f) -> p7_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p7_nodeVar0 = vec4<f32>( 100000.0, 100000.0, 100000.0, 100000.0 );
	p7_nodeVar1 = 400000.0;
	p7_nodeVar2 = 400000.0;
	p7_nodeVar4 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p7_nodeVar5 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar6 = ( p7_nodeVar4 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) );
	p7_nodeVar7 = length( ( vec2<f32>( p7_nodeVar5.x, p7_nodeVar5.y ) - p7_nodeVar6 ) );
	p7_nodeVar8 = ( p7_nodeVar7 < p7_nodeVar1 );

	if ( p7_nodeVar8 ) {

		p7_nodeVar3 = vec2<f32>( p7_nodeVar5.x, p7_nodeVar5.y );

	} else {

		p7_nodeVar3 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar3, p7_nodeVar0.zw );

	if ( p7_nodeVar8 ) {

		p7_nodeVar9 = p7_nodeVar7;

	} else {

		p7_nodeVar9 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar9;
	p7_nodeVar11 = length( ( vec2<f32>( p7_nodeVar5.z, p7_nodeVar5.w ) - p7_nodeVar6 ) );
	p7_nodeVar12 = ( p7_nodeVar11 < p7_nodeVar2 );

	if ( p7_nodeVar12 ) {

		p7_nodeVar10 = vec2<f32>( p7_nodeVar5.z, p7_nodeVar5.w );

	} else {

		p7_nodeVar10 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar10 );

	if ( p7_nodeVar12 ) {

		p7_nodeVar13 = p7_nodeVar11;

	} else {

		p7_nodeVar13 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar13;
	p7_nodeVar15 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar16 = length( ( vec2<f32>( p7_nodeVar15.x, p7_nodeVar15.y ) - p7_nodeVar6 ) );
	p7_nodeVar17 = ( p7_nodeVar16 < p7_nodeVar1 );

	if ( p7_nodeVar17 ) {

		p7_nodeVar14 = vec2<f32>( p7_nodeVar15.x, p7_nodeVar15.y );

	} else {

		p7_nodeVar14 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar14, p7_nodeVar0.zw );

	if ( p7_nodeVar17 ) {

		p7_nodeVar18 = p7_nodeVar16;

	} else {

		p7_nodeVar18 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar18;
	p7_nodeVar20 = length( ( vec2<f32>( p7_nodeVar15.z, p7_nodeVar15.w ) - p7_nodeVar6 ) );
	p7_nodeVar21 = ( p7_nodeVar20 < p7_nodeVar2 );

	if ( p7_nodeVar21 ) {

		p7_nodeVar19 = vec2<f32>( p7_nodeVar15.z, p7_nodeVar15.w );

	} else {

		p7_nodeVar19 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar19 );

	if ( p7_nodeVar21 ) {

		p7_nodeVar22 = p7_nodeVar20;

	} else {

		p7_nodeVar22 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar22;
	p7_nodeVar24 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * -1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar25 = length( ( vec2<f32>( p7_nodeVar24.x, p7_nodeVar24.y ) - p7_nodeVar6 ) );
	p7_nodeVar26 = ( p7_nodeVar25 < p7_nodeVar1 );

	if ( p7_nodeVar26 ) {

		p7_nodeVar23 = vec2<f32>( p7_nodeVar24.x, p7_nodeVar24.y );

	} else {

		p7_nodeVar23 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar23, p7_nodeVar0.zw );

	if ( p7_nodeVar26 ) {

		p7_nodeVar27 = p7_nodeVar25;

	} else {

		p7_nodeVar27 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar27;
	p7_nodeVar29 = length( ( vec2<f32>( p7_nodeVar24.z, p7_nodeVar24.w ) - p7_nodeVar6 ) );
	p7_nodeVar30 = ( p7_nodeVar29 < p7_nodeVar2 );

	if ( p7_nodeVar30 ) {

		p7_nodeVar28 = vec2<f32>( p7_nodeVar24.z, p7_nodeVar24.w );

	} else {

		p7_nodeVar28 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar28 );

	if ( p7_nodeVar30 ) {

		p7_nodeVar31 = p7_nodeVar29;

	} else {

		p7_nodeVar31 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar31;
	p7_nodeVar33 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar34 = length( ( vec2<f32>( p7_nodeVar33.x, p7_nodeVar33.y ) - p7_nodeVar6 ) );
	p7_nodeVar35 = ( p7_nodeVar34 < p7_nodeVar1 );

	if ( p7_nodeVar35 ) {

		p7_nodeVar32 = vec2<f32>( p7_nodeVar33.x, p7_nodeVar33.y );

	} else {

		p7_nodeVar32 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar32, p7_nodeVar0.zw );

	if ( p7_nodeVar35 ) {

		p7_nodeVar36 = p7_nodeVar34;

	} else {

		p7_nodeVar36 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar36;
	p7_nodeVar38 = length( ( vec2<f32>( p7_nodeVar33.z, p7_nodeVar33.w ) - p7_nodeVar6 ) );
	p7_nodeVar39 = ( p7_nodeVar38 < p7_nodeVar2 );

	if ( p7_nodeVar39 ) {

		p7_nodeVar37 = vec2<f32>( p7_nodeVar33.z, p7_nodeVar33.w );

	} else {

		p7_nodeVar37 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar37 );

	if ( p7_nodeVar39 ) {

		p7_nodeVar40 = p7_nodeVar38;

	} else {

		p7_nodeVar40 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar40;
	p7_nodeVar42 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar43 = length( ( vec2<f32>( p7_nodeVar42.x, p7_nodeVar42.y ) - p7_nodeVar6 ) );
	p7_nodeVar44 = ( p7_nodeVar43 < p7_nodeVar1 );

	if ( p7_nodeVar44 ) {

		p7_nodeVar41 = vec2<f32>( p7_nodeVar42.x, p7_nodeVar42.y );

	} else {

		p7_nodeVar41 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar41, p7_nodeVar0.zw );

	if ( p7_nodeVar44 ) {

		p7_nodeVar45 = p7_nodeVar43;

	} else {

		p7_nodeVar45 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar45;
	p7_nodeVar47 = length( ( vec2<f32>( p7_nodeVar42.z, p7_nodeVar42.w ) - p7_nodeVar6 ) );
	p7_nodeVar48 = ( p7_nodeVar47 < p7_nodeVar2 );

	if ( p7_nodeVar48 ) {

		p7_nodeVar46 = vec2<f32>( p7_nodeVar42.z, p7_nodeVar42.w );

	} else {

		p7_nodeVar46 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar46 );

	if ( p7_nodeVar48 ) {

		p7_nodeVar49 = p7_nodeVar47;

	} else {

		p7_nodeVar49 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar49;
	p7_nodeVar51 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 0.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar52 = length( ( vec2<f32>( p7_nodeVar51.x, p7_nodeVar51.y ) - p7_nodeVar6 ) );
	p7_nodeVar53 = ( p7_nodeVar52 < p7_nodeVar1 );

	if ( p7_nodeVar53 ) {

		p7_nodeVar50 = vec2<f32>( p7_nodeVar51.x, p7_nodeVar51.y );

	} else {

		p7_nodeVar50 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar50, p7_nodeVar0.zw );

	if ( p7_nodeVar53 ) {

		p7_nodeVar54 = p7_nodeVar52;

	} else {

		p7_nodeVar54 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar54;
	p7_nodeVar56 = length( ( vec2<f32>( p7_nodeVar51.z, p7_nodeVar51.w ) - p7_nodeVar6 ) );
	p7_nodeVar57 = ( p7_nodeVar56 < p7_nodeVar2 );

	if ( p7_nodeVar57 ) {

		p7_nodeVar55 = vec2<f32>( p7_nodeVar51.z, p7_nodeVar51.w );

	} else {

		p7_nodeVar55 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar55 );

	if ( p7_nodeVar57 ) {

		p7_nodeVar58 = p7_nodeVar56;

	} else {

		p7_nodeVar58 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar58;
	p7_nodeVar60 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * -1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar61 = length( ( vec2<f32>( p7_nodeVar60.x, p7_nodeVar60.y ) - p7_nodeVar6 ) );
	p7_nodeVar62 = ( p7_nodeVar61 < p7_nodeVar1 );

	if ( p7_nodeVar62 ) {

		p7_nodeVar59 = vec2<f32>( p7_nodeVar60.x, p7_nodeVar60.y );

	} else {

		p7_nodeVar59 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar59, p7_nodeVar0.zw );

	if ( p7_nodeVar62 ) {

		p7_nodeVar63 = p7_nodeVar61;

	} else {

		p7_nodeVar63 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar63;
	p7_nodeVar65 = length( ( vec2<f32>( p7_nodeVar60.z, p7_nodeVar60.w ) - p7_nodeVar6 ) );
	p7_nodeVar66 = ( p7_nodeVar65 < p7_nodeVar2 );

	if ( p7_nodeVar66 ) {

		p7_nodeVar64 = vec2<f32>( p7_nodeVar60.z, p7_nodeVar60.w );

	} else {

		p7_nodeVar64 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar64 );

	if ( p7_nodeVar66 ) {

		p7_nodeVar67 = p7_nodeVar65;

	} else {

		p7_nodeVar67 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar67;
	p7_nodeVar69 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 0.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar70 = length( ( vec2<f32>( p7_nodeVar69.x, p7_nodeVar69.y ) - p7_nodeVar6 ) );
	p7_nodeVar71 = ( p7_nodeVar70 < p7_nodeVar1 );

	if ( p7_nodeVar71 ) {

		p7_nodeVar68 = vec2<f32>( p7_nodeVar69.x, p7_nodeVar69.y );

	} else {

		p7_nodeVar68 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar68, p7_nodeVar0.zw );

	if ( p7_nodeVar71 ) {

		p7_nodeVar72 = p7_nodeVar70;

	} else {

		p7_nodeVar72 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar72;
	p7_nodeVar74 = length( ( vec2<f32>( p7_nodeVar69.z, p7_nodeVar69.w ) - p7_nodeVar6 ) );
	p7_nodeVar75 = ( p7_nodeVar74 < p7_nodeVar2 );

	if ( p7_nodeVar75 ) {

		p7_nodeVar73 = vec2<f32>( p7_nodeVar69.z, p7_nodeVar69.w );

	} else {

		p7_nodeVar73 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar73 );

	if ( p7_nodeVar75 ) {

		p7_nodeVar76 = p7_nodeVar74;

	} else {

		p7_nodeVar76 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar76;
	p7_nodeVar78 = target_read( t0, t0_sampler, ( p7_nodeVar4 + ( vec2<f32>( ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).x * 1.0 ), ( vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)).y * 1.0 ) ) * vec2<f32>( f32(1.0) ) ) ) );
	p7_nodeVar79 = length( ( vec2<f32>( p7_nodeVar78.x, p7_nodeVar78.y ) - p7_nodeVar6 ) );
	p7_nodeVar80 = ( p7_nodeVar79 < p7_nodeVar1 );

	if ( p7_nodeVar80 ) {

		p7_nodeVar77 = vec2<f32>( p7_nodeVar78.x, p7_nodeVar78.y );

	} else {

		p7_nodeVar77 = p7_nodeVar0.xy;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar77, p7_nodeVar0.zw );

	if ( p7_nodeVar80 ) {

		p7_nodeVar81 = p7_nodeVar79;

	} else {

		p7_nodeVar81 = p7_nodeVar1;

	}

	p7_nodeVar1 = p7_nodeVar81;
	p7_nodeVar83 = length( ( vec2<f32>( p7_nodeVar78.z, p7_nodeVar78.w ) - p7_nodeVar6 ) );
	p7_nodeVar84 = ( p7_nodeVar83 < p7_nodeVar2 );

	if ( p7_nodeVar84 ) {

		p7_nodeVar82 = vec2<f32>( p7_nodeVar78.z, p7_nodeVar78.w );

	} else {

		p7_nodeVar82 = p7_nodeVar0.zw;

	}

	p7_nodeVar0 = vec4<f32>( p7_nodeVar0.xy, p7_nodeVar82 );

	if ( p7_nodeVar84 ) {

		p7_nodeVar85 = p7_nodeVar83;

	} else {

		p7_nodeVar85 = p7_nodeVar2;

	}

	p7_nodeVar2 = p7_nodeVar85;
	p7_DiffuseColor = p7_nodeVar0;
	p7_DiffuseColor.w = ( p7_DiffuseColor.w * f32(1.0) );
	p7_nodeVar86 = max( vec4<f32>( p7_DiffuseColor.xyz, p7_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p7_Output = p7_nodeVar86;

	// result

	p7_output.color = p7_nodeVar86;

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
var<private> p8_nodeVar0 : vec4<f32>;
var<private> p8_nodeVar1 : vec2<f32>;
var<private> p8_nodeVar2 : vec4<f32>;
var<private> p8_nodeVar3 : vec4<f32>;
var<private> p8_nodeVar4 : vec4<f32>;
var<private> p8_nodeVar5 : vec4<f32>;
var<private> p8_nodeVar6 : f32;
var<private> p8_nodeVar7 : f32;
var<private> p8_nodeVar8 : f32;
var<private> p8_nodeVar9 : f32;
var<private> p8_nodeVar10 : f32;
var<private> p8_nodeVar11 : f32;
var<private> p8_nodeVar12 : f32;
var<private> p8_nodeVar13 : f32;
var<private> p8_nodeVar14 : f32;
var<private> p8_nodeVar15 : f32;
var<private> p8_nodeVar16 : f32;
var<private> p8_nodeVar17 : f32;
var<private> p8_nodeVar18 : f32;
var<private> p8_nodeVar19 : f32;
var<private> p8_nodeVar20 : f32;
var<private> p8_nodeVar21 : vec2<f32>;
var<private> p8_nodeVar22 : f32;
var<private> p8_nodeVar23 : f32;
var<private> p8_nodeVar24 : f32;
var<private> p8_nodeVar25 : vec4<f32>;
var<private> p8_nodeVar26 : vec3<f32>;
var<private> p8_nodeVar27 : f32;
var<private> p8_nodeVar28 : vec3<f32>;
var<private> p8_nodeVar29 : vec4<f32>;
var<private> p8_nodeVar30 : f32;
var<private> p8_nodeVar31 : f32;
var<private> p8_Output : vec4<f32>;
var<private> p8_nodeVar32 : vec4<f32>;

// codes


fn p8_main(door_uv: vec2f) -> p8_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p8_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p8_nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	p8_nodeVar2 = target_read( t1, t1_sampler, p8_nodeVar1 );
	p8_nodeVar3 = p8_nodeVar2;
	p8_nodeVar4 = picture_read( p8_nodeVar1 );
	p8_nodeVar5 = p8_nodeVar4;
	p8_nodeVar6 = clamp( p8_nodeVar5.w, 0.0, 1.0 );
	p8_nodeVar7 = p8_nodeVar6;

	if ( ( f32(knobs.source) >= 0.5 ) ) {


		if ( ( f32(knobs.source) < 1.5 ) ) {

			p8_nodeVar10 = clamp( dot( vec3<f32>( p8_nodeVar5.x, p8_nodeVar5.y, p8_nodeVar5.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p8_nodeVar10 <= 0.0031308 ) ) {

				p8_nodeVar9 = ( p8_nodeVar10 * 12.92 );

			} else {

				p8_nodeVar9 = ( ( pow( p8_nodeVar10, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p8_nodeVar8 = ( ( 1.0 - p8_nodeVar9 ) * p8_nodeVar6 );

		} else {

			p8_nodeVar12 = clamp( dot( vec3<f32>( p8_nodeVar5.x, p8_nodeVar5.y, p8_nodeVar5.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

			if ( ( p8_nodeVar12 <= 0.0031308 ) ) {

				p8_nodeVar11 = ( p8_nodeVar12 * 12.92 );

			} else {

				p8_nodeVar11 = ( ( pow( p8_nodeVar12, 0.4166666666666667 ) * 1.055 ) - 0.055 );

			}

			p8_nodeVar8 = ( p8_nodeVar11 * p8_nodeVar6 );

		}

		p8_nodeVar7 = p8_nodeVar8;
		

	}

	p8_nodeVar13 = step( f32(knobs.threshold), p8_nodeVar7 );

	if ( ( p8_nodeVar13 > 0.5 ) ) {

		p8_nodeVar14 = ( - ( length( ( vec2<f32>( p8_nodeVar3.x, p8_nodeVar3.y ) - ( p8_nodeVar1 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) ) ) ) + 0.5 ) );

	} else {

		p8_nodeVar14 = ( length( ( vec2<f32>( p8_nodeVar3.x, p8_nodeVar3.y ) - ( p8_nodeVar1 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) ) ) ) - 0.5 );

	}

	p8_nodeVar15 = ( p8_nodeVar14 / f32(1.0) );
	p8_nodeVar16 = ( p8_nodeVar15 - f32(6.0) );

	if ( ( f32(knobs.style) > 2.5 ) ) {


		if ( ( f32(6.0) >= 0.0 ) ) {

			p8_nodeVar17 = min( p8_nodeVar15, ( ( length( ( vec2<f32>( p8_nodeVar3.z, p8_nodeVar3.w ) - ( p8_nodeVar1 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) ) ) ) / f32(1.0) ) - max( abs( f32(6.0) ), ( f32(18.0) * 0.6 ) ) ) );

		} else {

			p8_nodeVar17 = max( p8_nodeVar15, ( max( abs( f32(6.0) ), ( f32(18.0) * 0.6 ) ) - ( length( ( vec2<f32>( p8_nodeVar3.z, p8_nodeVar3.w ) - ( p8_nodeVar1 / vec2<f32>((1.0 / knobs.resolution.x), (1.0 / knobs.resolution.y)) ) ) ) / f32(1.0) ) ) );

		}

		p8_nodeVar16 = p8_nodeVar17;
		

	}

	p8_nodeVar18 = ( f32(2.0) * 0.5 );
	p8_nodeVar19 = ( 0.75 / f32(1.0) );
	p8_nodeVar20 = 0.0;

	for ( var ringIndex : i32 = 0; ringIndex < i32( f32(1.0) ); ringIndex ++ ) {

		p8_nodeVar20 = max( p8_nodeVar20, ( 1.0 - smoothstep( ( p8_nodeVar18 - p8_nodeVar19 ), ( p8_nodeVar18 + p8_nodeVar19 ), abs( ( p8_nodeVar16 - ( f32(knobs.ringGap) * f32( ringIndex ) ) ) ) ) ) );

	}


	if ( ( ( f32(knobs.style) > 0.5 ) && ( f32(knobs.style) < 1.5 ) ) ) {

		p8_nodeVar20 = max( p8_nodeVar20, ( 1.0 - smoothstep( ( p8_nodeVar18 - p8_nodeVar19 ), ( p8_nodeVar18 + p8_nodeVar19 ), abs( ( p8_nodeVar16 - ( ( p8_nodeVar18 * 2.0 ) + ( f32(2.0) * 1.5 ) ) ) ) ) ) );
		

	}


	if ( ( ( f32(knobs.style) > 1.5 ) && ( f32(knobs.style) < 2.5 ) ) ) {

		p8_nodeVar21 = floor( ( vec2<f32>( p8_nodeVar3.z, p8_nodeVar3.w ) / vec2<f32>( max( ( f32(18.0) * f32(1.0) ), 2.0 ) ) ) );
		p8_nodeVar20 = ( p8_nodeVar20 * step( 0.5, ( fract( ( ( p8_nodeVar21.x + p8_nodeVar21.y ) * 0.5 ) ) * 2.0 ) ) );
		

	}

	p8_nodeVar22 = ( clamp( p8_nodeVar5.w, 0.0, 1.0 ) * f32(knobs.showImage) );
	p8_nodeVar23 = ( ( step( p8_nodeVar16, 0.0 ) * ( 1.0 - p8_nodeVar13 ) ) * f32(knobs.fill) );
	p8_nodeVar24 = mix( mix( p8_nodeVar22, 1.0, p8_nodeVar23 ), 1.0, p8_nodeVar20 );
	p8_nodeVar25 = vec4<f32>( ( mix( mix( ( vec3<f32>( p8_nodeVar5.x, p8_nodeVar5.y, p8_nodeVar5.z ) * vec3<f32>( p8_nodeVar22 ) ), vec3<f32>(knobs.fillColor.x, knobs.fillColor.y, knobs.fillColor.z), p8_nodeVar23 ), vec3<f32>(knobs.lineColor.x, knobs.lineColor.y, knobs.lineColor.z), p8_nodeVar20 ) / vec3<f32>( max( p8_nodeVar24, 0.0001 ) ) ), p8_nodeVar24 );
	p8_nodeVar26 = vec3<f32>( p8_nodeVar25.x, p8_nodeVar25.y, p8_nodeVar25.z );
	p8_nodeVar27 = ( ( ( p8_nodeVar26.x * 0.2126 ) + ( p8_nodeVar26.y * 0.7152 ) ) + ( p8_nodeVar26.z * 0.0722 ) );
	p8_nodeVar28 = mix( vec3<f32>( p8_nodeVar27, p8_nodeVar27, p8_nodeVar27 ), p8_nodeVar26, f32(1.0) );
	p8_nodeVar29 = vec4<f32>( clamp( vec3<f32>( ( ( ( p8_nodeVar28.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p8_nodeVar28.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p8_nodeVar28.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p8_nodeVar28.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p8_nodeVar28.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p8_nodeVar28.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p8_nodeVar28.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p8_nodeVar28.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p8_nodeVar28.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p8_nodeVar25.w, 0.0, 1.0 ) );
	p8_nodeVar31 = mix( clamp( p8_nodeVar0.w, 0.0, 1.0 ), clamp( p8_nodeVar29.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p8_nodeVar31 > 0.0 ) ) {

		p8_nodeVar30 = p8_nodeVar31;

	} else {

		p8_nodeVar30 = 1.0;

	}

	p8_DiffuseColor = vec4<f32>( ( mix( ( p8_nodeVar0.xyz * vec3<f32>( clamp( p8_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p8_nodeVar29.xyz, p8_nodeVar29.xyz, clamp( p8_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p8_nodeVar29.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p8_nodeVar30 ) ), p8_nodeVar31 );
	p8_DiffuseColor.w = ( p8_DiffuseColor.w * f32(1.0) );
	p8_nodeVar32 = max( vec4<f32>( p8_DiffuseColor.xyz, p8_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p8_Output = p8_nodeVar32;

	// result

	p8_output.color = p8_nodeVar32;

	return p8_output;

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
    default: {}
  }
  return to_shelf(p8_main(door_uv).color);
}

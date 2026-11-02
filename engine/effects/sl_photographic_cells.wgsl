// Photographic Cells: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Distort
// --about:Reveals the photo through a grid of cells joined into regions, with stepped edges and outlines.
// --track@mode:Layout,0,2,0,1
// --track@regionSize:Region Size,0.05,2,0.35,0.01
// --track@selection:Selection Source,0,2,2,1
// --track@threshold:Threshold,0,1,0.5,0.01
// --check@invert:Invert Selection,0
// --track@size:Cell Size,0.015,0.5,0.04,0.005
// --track@cellAspect:Cell Aspect,0.25,4,1,0.05
// --track@irregularity:Irregularity,0,1,0,0.01
// --track@edgeScatter:Edge Scatter,0,1,0,0.01
// --track@seed:Seed,0,1000,1,1
// --check@output:Output,0
// --track@gap:Gap,0,1,0,0.01
// --track@softness:Edge Softness,0,0.025,0,0.001
// --track@outlineMode:Outline,0,2,1,1
// --track@outline:Outline Width,0,0.5,0.025,0.005
// --track@outlineColor_x:Outline Color r,0,1,0.46207699964472876,0.001
// --track@outlineColor_y:Outline Color g,0,1,0.033104766565152086,0.001
// --track@outlineColor_z:Outline Color b,0,1,0.24228112245478564,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  mode: f32,
  regionSize: f32,
  selection: f32,
  threshold: f32,
  invert: f32,
  size: f32,
  cellAspect: f32,
  irregularity: f32,
  edgeScatter: f32,
  seed: f32,
  output: f32,
  gap: f32,
  softness: f32,
  outlineMode: f32,
  outline: f32,
  outlineColor: vec3<f32>,
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
fn own0_read(uv: vec2f) -> vec4f { return vec4f(0.0,0.0,0.0,1.0); }
fn own0_read_load(p: vec2i, level: u32) -> vec4f { return own0_read((vec2f(p) + 0.5) / vec2f(512.0, 512.0)); }
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
var<private> p0_nodeVar5 : vec4<f32>;
var<private> p0_nodeVar6 : vec2<f32>;
var<private> p0_nodeVar7 : vec2<f32>;
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
var<private> p0_nodeVar19 : vec4<f32>;
var<private> p0_nodeVar20 : f32;
var<private> p0_nodeVar21 : f32;
var<private> p0_nodeVar22 : f32;
var<private> p0_nodeVar23 : f32;
var<private> p0_nodeVar24 : f32;
var<private> p0_nodeVar25 : f32;
var<private> p0_nodeVar26 : f32;
var<private> p0_nodeVar27 : f32;
var<private> p0_nodeVar28 : f32;
var<private> p0_nodeVar29 : f32;
var<private> p0_nodeVar30 : f32;
var<private> p0_nodeVar31 : f32;
var<private> p0_nodeVar32 : vec3<f32>;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : vec3<f32>;
var<private> p0_nodeVar35 : vec4<f32>;
var<private> p0_nodeVar36 : f32;
var<private> p0_nodeVar37 : f32;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar38 : vec4<f32>;

// codes
fn p0_photographicCell ( id : vec2<f32>, geometry : vec2<f32> ) -> vec4<f32> {

	var p0_nodeVar0 : vec2<f32>;
	var p0_nodeVar1 : vec2<f32>;
	var p0_nodeVar2 : f32;
	var p0_nodeVar3 : f32;
	var p0_nodeVar4 : vec2<f32>;
	var p0_nodeVar5 : vec4<f32>;
	var p0_nodeVar6 : vec4<f32>;
	var p0_nodeVar7 : vec2<f32>;
	var p0_nodeVar8 : vec2<f32>;
	var p0_nodeVar9 : vec2<f32>;
	var p0_nodeVar10 : vec4<f32>;
	var p0_nodeVar11 : vec2<f32>;
	var p0_nodeVar12 : vec4<f32>;
	var p0_nodeVar13 : vec2<f32>;
	var p0_nodeVar14 : vec4<f32>;
	var p0_nodeVar15 : vec2<f32>;
	var p0_nodeVar16 : vec4<f32>;
	var p0_nodeVar17 : vec2<f32>;
	var p0_nodeVar18 : vec2<f32>;
	var p0_nodeVar19 : f32;
	var p0_nodeVar20 : vec2<f32>;
	var p0_nodeVar21 : vec4<f32>;
	var p0_nodeVar22 : vec2<f32>;
	var p0_nodeVar23 : vec4<f32>;
	var p0_nodeVar24 : f32;
	var p0_nodeVar25 : f32;
	var p0_nodeVar26 : f32;
	var p0_nodeVar27 : f32;
	var p0_nodeVar28 : f32;
	var p0_nodeVar29 : f32;
	var p0_nodeVar30 : f32;

	p0_nodeVar0 = vec2<f32>( ( ( ( id.x + 0.5 ) * geometry.x ) - geometry.y ), ( ( id.y + 0.5 ) * f32(knobs.size) ) );
	p0_nodeVar1 = p0_nodeVar0;

	if ( ( ( f32(knobs.edgeScatter) > 0.0 ) && ( ( f32(array<f32, 3>(1.0, 0.0, 0.0)[u32(knobs.mode)]) > 0.5 ) || ( f32(array<f32, 3>(0.0, 1.0, 0.0)[u32(knobs.mode)]) > 0.5 ) ) ) ) {

		p0_nodeVar1 = ( p0_nodeVar1 + ( ( ( vec2<f32>( fract( ( sin( ( dot( ( id + vec2<f32>( 71.0, 193.0 ) ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( dot( ( id + vec2<f32>( 137.0, 47.0 ) ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>( geometry.x, f32(knobs.size) ) ) * vec2<f32>( ( f32(knobs.edgeScatter) * 3.0 ) ) ) );
		

	}

	p0_nodeVar2 = 0.0;

	if ( ( f32(array<f32, 3>(0.0, 1.0, 0.0)[u32(knobs.mode)]) > 0.5 ) ) {

		p0_nodeVar4 = ( ( p0_nodeVar1 / vec2<f32>(1.0, 1.0) ) + vec2<f32>( 0.5 ) );

		if ( ( ( ( ( p0_nodeVar4.x >= 0.0 ) && ( p0_nodeVar4.x < 1.0 ) ) && ( p0_nodeVar4.y >= 0.0 ) ) && ( p0_nodeVar4.y < 1.0 ) ) ) {

			p0_nodeVar5 = own0_read_level( p0_nodeVar4, 0.0 );
			p0_nodeVar3 = p0_nodeVar5.x;

		} else {

			p0_nodeVar3 = 0.0;

		}

		p0_nodeVar2 = p0_nodeVar3;
		

	} else {


		if ( ( f32(array<f32, 3>(1.0, 0.0, 0.0)[u32(knobs.mode)]) > 0.5 ) ) {

			p0_nodeVar6 = vec4<f32>( 0.0, 0.0, 0.0, 0.0 );

			if ( ( f32(knobs.selection) > 1.5 ) ) {

				p0_nodeVar7 = floor( ( p0_nodeVar1 / vec2<f32>( f32(knobs.regionSize) ) ) );
				p0_nodeVar6 = vec4<f32>( fract( ( sin( ( dot( p0_nodeVar7, vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( dot( ( p0_nodeVar7 + vec2<f32>( 1.0, 0.0 ) ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( dot( ( p0_nodeVar7 + vec2<f32>( 0.0, 1.0 ) ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ), fract( ( sin( ( dot( ( p0_nodeVar7 + vec2<f32>( 1.0 ) ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) );
				

			} else {

				p0_nodeVar8 = floor( ( p0_nodeVar1 / vec2<f32>( f32(knobs.regionSize) ) ) );
				p0_nodeVar9 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
				p0_nodeVar10 = picture_read_level( clamp( ( ( ( p0_nodeVar8 * vec2<f32>( f32(knobs.regionSize) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar9, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar9 ) ), 0.0 );
				p0_nodeVar11 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
				p0_nodeVar12 = picture_read_level( clamp( ( ( ( ( p0_nodeVar8 + vec2<f32>( 1.0, 0.0 ) ) * vec2<f32>( f32(knobs.regionSize) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar11, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar11 ) ), 0.0 );
				p0_nodeVar13 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
				p0_nodeVar14 = picture_read_level( clamp( ( ( ( ( p0_nodeVar8 + vec2<f32>( 0.0, 1.0 ) ) * vec2<f32>( f32(knobs.regionSize) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar13, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar13 ) ), 0.0 );
				p0_nodeVar15 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
				p0_nodeVar16 = picture_read_level( clamp( ( ( ( ( p0_nodeVar8 + vec2<f32>( 1.0 ) ) * vec2<f32>( f32(knobs.regionSize) ) ) / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar15, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar15 ) ), 0.0 );
				p0_nodeVar6 = vec4<f32>( clamp( dot( p0_nodeVar10.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 ), clamp( dot( p0_nodeVar12.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 ), clamp( dot( p0_nodeVar14.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 ), clamp( dot( p0_nodeVar16.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 ) );

				if ( ( f32(knobs.selection) > 0.5 ) ) {

					p0_nodeVar6 = ( vec4<f32>( 1.0 ) - p0_nodeVar6 );
					

				}

				

			}

			p0_nodeVar17 = fract( ( p0_nodeVar1 / vec2<f32>( f32(knobs.regionSize) ) ) );
			p0_nodeVar18 = ( ( p0_nodeVar17 * p0_nodeVar17 ) * ( vec2<f32>( 3.0 ) - ( p0_nodeVar17 * vec2<f32>( 2.0 ) ) ) );
			p0_nodeVar2 = mix( mix( p0_nodeVar6.x, p0_nodeVar6.y, p0_nodeVar18.x ), mix( p0_nodeVar6.z, p0_nodeVar6.w, p0_nodeVar18.x ), p0_nodeVar18.y );
			

		} else {


			if ( ( f32(knobs.selection) > 1.5 ) ) {

				p0_nodeVar2 = fract( ( sin( ( dot( id, vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) );
				

			} else {


				if ( ( f32(knobs.selection) > 0.5 ) ) {

					p0_nodeVar20 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
					p0_nodeVar21 = picture_read_level( clamp( ( ( p0_nodeVar0 / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar20, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar20 ) ), 0.0 );
					p0_nodeVar19 = ( 1.0 - clamp( dot( p0_nodeVar21.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 ) );

				} else {

					p0_nodeVar22 = ( vec2<f32>( 0.5, 0.5 ) / vec2<f32>(knobs.resolution.x, knobs.resolution.y) );
					p0_nodeVar23 = picture_read_level( clamp( ( ( p0_nodeVar0 / vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) ) + vec2<f32>( 0.5 ) ), p0_nodeVar22, ( vec2<f32>( 1.0, 1.0 ) - p0_nodeVar22 ) ), 0.0 );
					p0_nodeVar19 = clamp( dot( p0_nodeVar23.xyz, vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

				}

				p0_nodeVar2 = p0_nodeVar19;
				

			}

			

		}

		

	}


	if ( ( f32(knobs.invert) > 0.5 ) ) {


		if ( ( f32(array<f32, 3>(0.0, 1.0, 0.0)[u32(knobs.mode)]) > 0.5 ) ) {

			p0_nodeVar25 = step( 0.5, p0_nodeVar2 );

		} else {


			if ( ( f32(knobs.threshold) <= 0.0 ) ) {

				p0_nodeVar26 = 1.0;

			} else {


				if ( ( f32(knobs.threshold) >= 1.0 ) ) {

					p0_nodeVar27 = 0.0;

				} else {

					p0_nodeVar27 = step( f32(knobs.threshold), p0_nodeVar2 );

				}

				p0_nodeVar26 = p0_nodeVar27;

			}

			p0_nodeVar25 = p0_nodeVar26;

		}

		p0_nodeVar24 = ( 1.0 - p0_nodeVar25 );

	} else {


		if ( ( f32(array<f32, 3>(0.0, 1.0, 0.0)[u32(knobs.mode)]) > 0.5 ) ) {

			p0_nodeVar28 = step( 0.5, p0_nodeVar2 );

		} else {


			if ( ( f32(knobs.threshold) <= 0.0 ) ) {

				p0_nodeVar29 = 1.0;

			} else {


				if ( ( f32(knobs.threshold) >= 1.0 ) ) {

					p0_nodeVar30 = 0.0;

				} else {

					p0_nodeVar30 = step( f32(knobs.threshold), p0_nodeVar2 );

				}

				p0_nodeVar29 = p0_nodeVar30;

			}

			p0_nodeVar28 = p0_nodeVar29;

		}

		p0_nodeVar24 = p0_nodeVar28;

	}


	return vec4<f32>( p0_nodeVar0, geometry.x, p0_nodeVar24 );

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar1 = ( ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) - vec2<f32>( 0.5 ) ) * vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0) );
	p0_nodeVar2 = floor( ( p0_nodeVar1.y / f32(knobs.size) ) );
	p0_nodeVar3 = ( ( f32(knobs.size) * f32(knobs.cellAspect) ) * mix( 1.0, ( ( fract( ( sin( ( dot( vec2<f32>( p0_nodeVar2, 17.0 ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) * 0.8 ) + 0.6 ), f32(knobs.irregularity) ) );
	p0_nodeVar4 = ( ( ( fract( ( sin( ( dot( vec2<f32>( p0_nodeVar2, 53.0 ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) - 0.5 ) * p0_nodeVar3 ) * f32(knobs.irregularity) );
	p0_nodeVar5 = p0_photographicCell( vec2<f32>( floor( ( ( p0_nodeVar1.x + p0_nodeVar4 ) / p0_nodeVar3 ) ), p0_nodeVar2 ), vec2<f32>( p0_nodeVar3, p0_nodeVar4 ) );
	p0_nodeVar6 = abs( ( p0_nodeVar1 - p0_nodeVar5.xy ) );
	p0_nodeVar7 = ( ( vec2<f32>( p0_nodeVar5.z, f32(knobs.size) ) * vec2<f32>( ( 1.0 - f32(knobs.gap) ) ) ) * vec2<f32>( 0.5 ) );
	p0_nodeVar8 = max( ( p0_nodeVar6.x - p0_nodeVar7.x ), ( p0_nodeVar6.y - p0_nodeVar7.y ) );
	p0_nodeVar9 = p0_nodeVar8;

	if ( ( ( ( f32(knobs.outlineMode) == 1.0 ) && ( f32(knobs.gap) == 0.0 ) ) && ( f32(knobs.outline) > 0.0 ) ) ) {

		p0_nodeVar10 = min( ( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x * 0.5 ) - abs( p0_nodeVar1.x ) ), ( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y * 0.5 ) - abs( p0_nodeVar1.y ) ) );
		p0_nodeVar11 = ( ( min( p0_nodeVar5.z, f32(knobs.size) ) * f32(knobs.outline) ) + max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) ) );

		if ( ( ( p0_nodeVar5.w > 0.5 ) && ( p0_nodeVar8 >= ( - p0_nodeVar11 ) ) ) ) {

			p0_nodeVar12 = min( ( floor( ( p0_nodeVar11 / f32(knobs.size) ) ) + 1.0 ), 2.0 );

			for ( var i : i32 = 0; i < i32( ( ( p0_nodeVar12 * 2.0 ) + 1.0 ) ); i ++ ) {

				p0_nodeVar13 = ( p0_nodeVar2 + ( f32( i ) - p0_nodeVar12 ) );
				p0_nodeVar14 = ( ( f32(knobs.size) * f32(knobs.cellAspect) ) * mix( 1.0, ( ( fract( ( sin( ( dot( vec2<f32>( p0_nodeVar13, 17.0 ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) * 0.8 ) + 0.6 ), f32(knobs.irregularity) ) );
				p0_nodeVar15 = min( ( floor( ( p0_nodeVar11 / p0_nodeVar14 ) ) + 1.0 ), 2.0 );

				for ( var j : i32 = 0; j < i32( ( ( p0_nodeVar15 * 2.0 ) + 1.0 ) ); j ++ ) {

					p0_nodeVar16 = ( ( ( fract( ( sin( ( dot( vec2<f32>( p0_nodeVar13, 53.0 ), vec2<f32>( 127.1, 311.7 ) ) + ( f32(knobs.seed) * 74.7 ) ) ) * 43758.5453 ) ) - 0.5 ) * p0_nodeVar14 ) * f32(knobs.irregularity) );
					p0_nodeVar17 = ( floor( ( ( p0_nodeVar1.x + p0_nodeVar16 ) / p0_nodeVar14 ) ) + ( f32( j ) - p0_nodeVar15 ) );
					p0_nodeVar18 = length( max( ( abs( ( p0_nodeVar1 - vec2<f32>( ( ( ( p0_nodeVar17 + 0.5 ) * p0_nodeVar14 ) - p0_nodeVar16 ), ( ( p0_nodeVar13 + 0.5 ) * f32(knobs.size) ) ) ) ) - ( vec2<f32>( p0_nodeVar14, f32(knobs.size) ) * vec2<f32>( 0.5 ) ) ), vec2<f32>( 0.0, 0.0 ) ) );

					if ( ( ( ( p0_nodeVar18 < p0_nodeVar10 ) && ( p0_nodeVar18 < p0_nodeVar11 ) ) && ( ( abs( ( f32( i ) - p0_nodeVar12 ) ) + abs( ( f32( j ) - p0_nodeVar15 ) ) ) > 0.0 ) ) ) {


						if ( ( p0_photographicCell( vec2<f32>( p0_nodeVar17, p0_nodeVar13 ), vec2<f32>( p0_nodeVar14, p0_nodeVar16 ) ).w < 0.5 ) ) {

							p0_nodeVar10 = p0_nodeVar18;
							

						}

						

					}


				}


			}

			

		}

		p0_nodeVar9 = ( - p0_nodeVar10 );
		

	}


	if ( ( f32((-1 * knobs.output + 1)) > 0.5 ) ) {


		if ( ( f32(knobs.gap) == 0.0 ) ) {

			p0_nodeVar20 = 1.0;

		} else {

			p0_nodeVar21 = max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) );
			p0_nodeVar20 = ( 1.0 - smoothstep( ( - p0_nodeVar21 ), p0_nodeVar21, p0_nodeVar8 ) );

		}


		if ( ( f32(knobs.gap) >= 1.0 ) ) {

			p0_nodeVar22 = 0.0;

		} else {

			p0_nodeVar22 = 1.0;

		}

		p0_nodeVar23 = ( p0_nodeVar20 * p0_nodeVar22 );
		p0_nodeVar24 = max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) );

		if ( ( ( f32(knobs.outline) > 0.0 ) && ( f32(knobs.outlineMode) > 0.0 ) ) ) {

			p0_nodeVar25 = 1.0;

		} else {

			p0_nodeVar25 = 0.0;

		}

		p0_nodeVar19 = vec4<f32>( mix( p0_nodeVar0.xyz, vec3<f32>(knobs.outlineColor.x, knobs.outlineColor.y, knobs.outlineColor.z), ( ( max( ( p0_nodeVar23 - ( 1.0 - smoothstep( ( - p0_nodeVar24 ), p0_nodeVar24, ( p0_nodeVar9 + ( min( p0_nodeVar5.z, f32(knobs.size) ) * f32(knobs.outline) ) ) ) ) ), 0.0 ) * p0_nodeVar25 ) / max( p0_nodeVar23, 0.000001 ) ) ), ( p0_nodeVar0.w * max( ( p0_nodeVar23 * p0_nodeVar5.w ), ( f32(0.0) * f32(array<f32, 3>(0.0, 1.0, 0.0)[u32(knobs.mode)]) ) ) ) );

	} else {


		if ( ( f32(knobs.gap) == 0.0 ) ) {

			p0_nodeVar26 = 1.0;

		} else {

			p0_nodeVar27 = max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) );
			p0_nodeVar26 = ( 1.0 - smoothstep( ( - p0_nodeVar27 ), p0_nodeVar27, p0_nodeVar8 ) );

		}


		if ( ( f32(knobs.gap) >= 1.0 ) ) {

			p0_nodeVar28 = 0.0;

		} else {

			p0_nodeVar28 = 1.0;

		}

		p0_nodeVar29 = ( p0_nodeVar26 * p0_nodeVar28 );
		p0_nodeVar30 = max( ( max( ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).x / vec2<f32>(knobs.resolution.x, knobs.resolution.y).x ), ( vec2<f32>((knobs.resolution.x / knobs.resolution.y), 1.0).y / vec2<f32>(knobs.resolution.x, knobs.resolution.y).y ) ) * 0.75 ), f32(knobs.softness) );

		if ( ( ( f32(knobs.outline) > 0.0 ) && ( f32(knobs.outlineMode) > 0.0 ) ) ) {

			p0_nodeVar31 = 1.0;

		} else {

			p0_nodeVar31 = 0.0;

		}

		p0_nodeVar19 = vec4<f32>( mix( p0_nodeVar0.xyz, mix( p0_nodeVar0.xyz, vec3<f32>(knobs.outlineColor.x, knobs.outlineColor.y, knobs.outlineColor.z), ( ( max( ( p0_nodeVar29 - ( 1.0 - smoothstep( ( - p0_nodeVar30 ), p0_nodeVar30, ( p0_nodeVar9 + ( min( p0_nodeVar5.z, f32(knobs.size) ) * f32(knobs.outline) ) ) ) ) ), 0.0 ) * p0_nodeVar31 ) / max( p0_nodeVar29, 0.000001 ) ) ), ( p0_nodeVar29 * p0_nodeVar5.w ) ), p0_nodeVar0.w );

	}

	p0_nodeVar32 = vec3<f32>( p0_nodeVar19.x, p0_nodeVar19.y, p0_nodeVar19.z );
	p0_nodeVar33 = ( ( ( p0_nodeVar32.x * 0.2126 ) + ( p0_nodeVar32.y * 0.7152 ) ) + ( p0_nodeVar32.z * 0.0722 ) );
	p0_nodeVar34 = mix( vec3<f32>( p0_nodeVar33, p0_nodeVar33, p0_nodeVar33 ), p0_nodeVar32, f32(1.0) );
	p0_nodeVar35 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar34.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar34.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar34.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar34.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar34.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar34.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar34.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar34.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar34.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar19.w, 0.0, 1.0 ) );
	p0_nodeVar37 = mix( clamp( p0_nodeVar0.w, 0.0, 1.0 ), clamp( p0_nodeVar35.w, 0.0, 1.0 ), clamp( f32(1.0), 0.0, 1.0 ) );

	if ( ( p0_nodeVar37 > 0.0 ) ) {

		p0_nodeVar36 = p0_nodeVar37;

	} else {

		p0_nodeVar36 = 1.0;

	}

	p0_DiffuseColor = vec4<f32>( ( mix( ( p0_nodeVar0.xyz * vec3<f32>( clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) ), ( mix( p0_nodeVar35.xyz, p0_nodeVar35.xyz, clamp( p0_nodeVar0.w, 0.0, 1.0 ) ) * vec3<f32>( clamp( p0_nodeVar35.w, 0.0, 1.0 ) ) ), clamp( f32(1.0), 0.0, 1.0 ) ) / vec3<f32>( p0_nodeVar36 ) ), p0_nodeVar37 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar38 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar38;

	// result

	p0_output.color = p0_nodeVar38;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

// Voxel: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_shader_lab.ts)
// --label:Stylize
// --about:Rebuilds the image from isometric cubes, with brighter areas rising higher.
// --track@cellSize:Cell Size,4,96,24,1
// --track@depth:Depth,0,1,0,0.01
// --track@maxHeight:Max Height,1,8,6,1
// --track@topShade:Top Shade,0,1.5,1,0.01
// --track@lightShade:Light Side,0,1.5,0.78,0.01
// --track@darkShade:Dark Side,0,1.5,0.55,0.01
// --check@flipLight:Flip Light,0
// --check@lego:Lego,0
// --track@outlineWidth:Outline,0,4,1,0.1
// --track@outlineColor_x:Outline Color r,0,1,0.0030352698352941175,0.001
// --track@outlineColor_y:Outline Color g,0,1,0.0030352698352941175,0.001
// --track@outlineColor_z:Outline Color b,0,1,0.0030352698352941175,0.001
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  cellSize: f32,
  depth: f32,
  maxHeight: f32,
  topShade: f32,
  lightShade: f32,
  darkShade: f32,
  flipLight: f32,
  lego: f32,
  outlineWidth: f32,
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

// structs

struct p0_OutputStruct {
	@location( 0 ) color: vec4<f32>
};
var<private> p0_output : p0_OutputStruct;

// uniforms


// vars
var<private> p0_DiffuseColor : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;
var<private> p0_nodeVar1 : vec3<f32>;
var<private> p0_nodeVar2 : f32;
var<private> p0_nodeVar3 : vec2<f32>;
var<private> p0_nodeVar4 : vec2<f32>;
var<private> p0_nodeVar5 : vec2<f32>;
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
var<private> p0_nodeVar16 : vec2<f32>;
var<private> p0_nodeVar17 : vec4<f32>;
var<private> p0_nodeVar18 : f32;
var<private> p0_nodeVar19 : f32;
var<private> p0_nodeVar20 : vec2<f32>;
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
var<private> p0_nodeVar31 : vec2<f32>;
var<private> p0_nodeVar32 : vec4<f32>;
var<private> p0_nodeVar33 : f32;
var<private> p0_nodeVar34 : f32;
var<private> p0_nodeVar35 : vec2<f32>;
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
var<private> p0_nodeVar46 : vec2<f32>;
var<private> p0_nodeVar47 : vec4<f32>;
var<private> p0_nodeVar48 : f32;
var<private> p0_nodeVar49 : f32;
var<private> p0_nodeVar50 : vec2<f32>;
var<private> p0_nodeVar51 : f32;
var<private> p0_nodeVar52 : f32;
var<private> p0_nodeVar53 : f32;
var<private> p0_nodeVar54 : f32;
var<private> p0_nodeVar55 : f32;
var<private> p0_nodeVar56 : f32;
var<private> p0_nodeVar57 : f32;
var<private> p0_nodeVar58 : f32;
var<private> p0_nodeVar59 : f32;
var<private> p0_nodeVar60 : f32;
var<private> p0_nodeVar61 : vec2<f32>;
var<private> p0_nodeVar62 : vec4<f32>;
var<private> p0_nodeVar63 : f32;
var<private> p0_nodeVar64 : f32;
var<private> p0_nodeVar65 : vec2<f32>;
var<private> p0_nodeVar66 : f32;
var<private> p0_nodeVar67 : f32;
var<private> p0_nodeVar68 : f32;
var<private> p0_nodeVar69 : f32;
var<private> p0_nodeVar70 : f32;
var<private> p0_nodeVar71 : f32;
var<private> p0_nodeVar72 : f32;
var<private> p0_nodeVar73 : f32;
var<private> p0_nodeVar74 : f32;
var<private> p0_nodeVar75 : f32;
var<private> p0_nodeVar76 : vec2<f32>;
var<private> p0_nodeVar77 : vec4<f32>;
var<private> p0_nodeVar78 : f32;
var<private> p0_nodeVar79 : f32;
var<private> p0_nodeVar80 : vec2<f32>;
var<private> p0_nodeVar81 : f32;
var<private> p0_nodeVar82 : f32;
var<private> p0_nodeVar83 : f32;
var<private> p0_nodeVar84 : f32;
var<private> p0_nodeVar85 : f32;
var<private> p0_nodeVar86 : f32;
var<private> p0_nodeVar87 : f32;
var<private> p0_nodeVar88 : f32;
var<private> p0_nodeVar89 : f32;
var<private> p0_nodeVar90 : f32;
var<private> p0_nodeVar91 : vec2<f32>;
var<private> p0_nodeVar92 : vec4<f32>;
var<private> p0_nodeVar93 : f32;
var<private> p0_nodeVar94 : f32;
var<private> p0_nodeVar95 : vec2<f32>;
var<private> p0_nodeVar96 : f32;
var<private> p0_nodeVar97 : f32;
var<private> p0_nodeVar98 : f32;
var<private> p0_nodeVar99 : f32;
var<private> p0_nodeVar100 : f32;
var<private> p0_nodeVar101 : f32;
var<private> p0_nodeVar102 : f32;
var<private> p0_nodeVar103 : f32;
var<private> p0_nodeVar104 : f32;
var<private> p0_nodeVar105 : f32;
var<private> p0_nodeVar106 : vec2<f32>;
var<private> p0_nodeVar107 : vec4<f32>;
var<private> p0_nodeVar108 : f32;
var<private> p0_nodeVar109 : f32;
var<private> p0_nodeVar110 : vec2<f32>;
var<private> p0_nodeVar111 : f32;
var<private> p0_nodeVar112 : f32;
var<private> p0_nodeVar113 : f32;
var<private> p0_nodeVar114 : f32;
var<private> p0_nodeVar115 : f32;
var<private> p0_nodeVar116 : f32;
var<private> p0_nodeVar117 : f32;
var<private> p0_nodeVar118 : f32;
var<private> p0_nodeVar119 : f32;
var<private> p0_nodeVar120 : f32;
var<private> p0_nodeVar121 : vec2<f32>;
var<private> p0_nodeVar122 : vec4<f32>;
var<private> p0_nodeVar123 : bool;
var<private> p0_nodeVar124 : bool;
var<private> p0_nodeVar125 : bool;
var<private> p0_nodeVar126 : bool;
var<private> p0_nodeVar127 : bool;
var<private> p0_nodeVar128 : bool;
var<private> p0_nodeVar129 : bool;
var<private> p0_nodeVar130 : bool;
var<private> p0_nodeVar131 : vec3<f32>;
var<private> p0_nodeVar132 : vec3<f32>;
var<private> p0_nodeVar133 : vec3<f32>;
var<private> p0_nodeVar134 : vec3<f32>;
var<private> p0_nodeVar135 : vec3<f32>;
var<private> p0_nodeVar136 : vec3<f32>;
var<private> p0_nodeVar137 : vec3<f32>;
var<private> p0_nodeVar138 : f32;
var<private> p0_nodeVar139 : vec2<f32>;
var<private> p0_nodeVar140 : vec2<f32>;
var<private> p0_nodeVar141 : vec2<f32>;
var<private> p0_nodeVar142 : vec2<f32>;
var<private> p0_nodeVar143 : vec2<f32>;
var<private> p0_nodeVar144 : vec2<f32>;
var<private> p0_nodeVar145 : vec2<f32>;
var<private> p0_nodeVar146 : vec2<f32>;
var<private> p0_nodeVar147 : f32;
var<private> p0_nodeVar148 : f32;
var<private> p0_nodeVar149 : f32;
var<private> p0_nodeVar150 : f32;
var<private> p0_nodeVar151 : f32;
var<private> p0_nodeVar152 : f32;
var<private> p0_nodeVar153 : f32;
var<private> p0_nodeVar154 : f32;
var<private> p0_nodeVar155 : vec2<f32>;
var<private> p0_nodeVar156 : f32;
var<private> p0_nodeVar157 : bool;
var<private> p0_nodeVar158 : f32;
var<private> p0_nodeVar159 : f32;
var<private> p0_nodeVar160 : f32;
var<private> p0_nodeVar161 : f32;
var<private> p0_nodeVar162 : f32;
var<private> p0_nodeVar163 : bool;
var<private> p0_nodeVar164 : f32;
var<private> p0_nodeVar165 : f32;
var<private> p0_nodeVar166 : f32;
var<private> p0_nodeVar167 : bool;
var<private> p0_nodeVar168 : f32;
var<private> p0_nodeVar169 : f32;
var<private> p0_nodeVar170 : f32;
var<private> p0_nodeVar171 : f32;
var<private> p0_nodeVar172 : f32;
var<private> p0_nodeVar173 : vec4<f32>;
var<private> p0_nodeVar174 : vec3<f32>;
var<private> p0_nodeVar175 : f32;
var<private> p0_nodeVar176 : vec3<f32>;
var<private> p0_nodeVar177 : vec4<f32>;
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar178 : vec4<f32>;

// codes


fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let nodeVarying4 = vec2f(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	p0_nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	p0_nodeVar3 = vec2<f32>( f32(knobs.resolution.x), f32(knobs.resolution.y) );
	p0_nodeVar4 = ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * p0_nodeVar3 );
	p0_nodeVar5 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 0.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar6 = ( ( ( p0_nodeVar5.x * 0.5773502691896257 ) - ( p0_nodeVar5.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar7 = floor( ( p0_nodeVar6 + 0.5 ) );
	p0_nodeVar8 = abs( ( p0_nodeVar7 - p0_nodeVar6 ) );
	p0_nodeVar9 = ( ( p0_nodeVar5.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar10 = floor( ( p0_nodeVar9 + 0.5 ) );
	p0_nodeVar11 = abs( ( p0_nodeVar10 - p0_nodeVar9 ) );
	p0_nodeVar12 = ( ( - p0_nodeVar6 ) - p0_nodeVar9 );
	p0_nodeVar13 = floor( ( p0_nodeVar12 + 0.5 ) );
	p0_nodeVar14 = abs( ( p0_nodeVar13 - p0_nodeVar12 ) );

	if ( ( ( p0_nodeVar8 > p0_nodeVar11 ) && ( p0_nodeVar8 > p0_nodeVar14 ) ) ) {

		p0_nodeVar2 = ( ( - p0_nodeVar10 ) - p0_nodeVar13 );

	} else {

		p0_nodeVar2 = p0_nodeVar7;

	}


	if ( ( ( ( p0_nodeVar8 <= p0_nodeVar11 ) || ( p0_nodeVar8 <= p0_nodeVar14 ) ) && ( p0_nodeVar11 > p0_nodeVar14 ) ) ) {

		p0_nodeVar15 = ( ( - p0_nodeVar2 ) - p0_nodeVar13 );

	} else {

		p0_nodeVar15 = p0_nodeVar10;

	}

	p0_nodeVar16 = vec2<f32>( ( ( ( p0_nodeVar2 * 1.7320508075688772 ) + ( p0_nodeVar15 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar15 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar17 = picture_read( ( p0_nodeVar16 / p0_nodeVar3 ) );
	p0_nodeVar20 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 1.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar21 = ( ( ( p0_nodeVar20.x * 0.5773502691896257 ) - ( p0_nodeVar20.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar22 = floor( ( p0_nodeVar21 + 0.5 ) );
	p0_nodeVar23 = abs( ( p0_nodeVar22 - p0_nodeVar21 ) );
	p0_nodeVar24 = ( ( p0_nodeVar20.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar25 = floor( ( p0_nodeVar24 + 0.5 ) );
	p0_nodeVar26 = abs( ( p0_nodeVar25 - p0_nodeVar24 ) );
	p0_nodeVar27 = ( ( - p0_nodeVar21 ) - p0_nodeVar24 );
	p0_nodeVar28 = floor( ( p0_nodeVar27 + 0.5 ) );
	p0_nodeVar29 = abs( ( p0_nodeVar28 - p0_nodeVar27 ) );

	if ( ( ( p0_nodeVar23 > p0_nodeVar26 ) && ( p0_nodeVar23 > p0_nodeVar29 ) ) ) {

		p0_nodeVar19 = ( ( - p0_nodeVar25 ) - p0_nodeVar28 );

	} else {

		p0_nodeVar19 = p0_nodeVar22;

	}


	if ( ( ( ( p0_nodeVar23 <= p0_nodeVar26 ) || ( p0_nodeVar23 <= p0_nodeVar29 ) ) && ( p0_nodeVar26 > p0_nodeVar29 ) ) ) {

		p0_nodeVar30 = ( ( - p0_nodeVar19 ) - p0_nodeVar28 );

	} else {

		p0_nodeVar30 = p0_nodeVar25;

	}

	p0_nodeVar31 = vec2<f32>( ( ( ( p0_nodeVar19 * 1.7320508075688772 ) + ( p0_nodeVar30 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar30 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar32 = picture_read( ( p0_nodeVar31 / p0_nodeVar3 ) );
	p0_nodeVar35 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 2.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar36 = ( ( ( p0_nodeVar35.x * 0.5773502691896257 ) - ( p0_nodeVar35.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar37 = floor( ( p0_nodeVar36 + 0.5 ) );
	p0_nodeVar38 = abs( ( p0_nodeVar37 - p0_nodeVar36 ) );
	p0_nodeVar39 = ( ( p0_nodeVar35.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar40 = floor( ( p0_nodeVar39 + 0.5 ) );
	p0_nodeVar41 = abs( ( p0_nodeVar40 - p0_nodeVar39 ) );
	p0_nodeVar42 = ( ( - p0_nodeVar36 ) - p0_nodeVar39 );
	p0_nodeVar43 = floor( ( p0_nodeVar42 + 0.5 ) );
	p0_nodeVar44 = abs( ( p0_nodeVar43 - p0_nodeVar42 ) );

	if ( ( ( p0_nodeVar38 > p0_nodeVar41 ) && ( p0_nodeVar38 > p0_nodeVar44 ) ) ) {

		p0_nodeVar34 = ( ( - p0_nodeVar40 ) - p0_nodeVar43 );

	} else {

		p0_nodeVar34 = p0_nodeVar37;

	}


	if ( ( ( ( p0_nodeVar38 <= p0_nodeVar41 ) || ( p0_nodeVar38 <= p0_nodeVar44 ) ) && ( p0_nodeVar41 > p0_nodeVar44 ) ) ) {

		p0_nodeVar45 = ( ( - p0_nodeVar34 ) - p0_nodeVar43 );

	} else {

		p0_nodeVar45 = p0_nodeVar40;

	}

	p0_nodeVar46 = vec2<f32>( ( ( ( p0_nodeVar34 * 1.7320508075688772 ) + ( p0_nodeVar45 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar45 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar47 = picture_read( ( p0_nodeVar46 / p0_nodeVar3 ) );
	p0_nodeVar50 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 3.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar51 = ( ( ( p0_nodeVar50.x * 0.5773502691896257 ) - ( p0_nodeVar50.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar52 = floor( ( p0_nodeVar51 + 0.5 ) );
	p0_nodeVar53 = abs( ( p0_nodeVar52 - p0_nodeVar51 ) );
	p0_nodeVar54 = ( ( p0_nodeVar50.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar55 = floor( ( p0_nodeVar54 + 0.5 ) );
	p0_nodeVar56 = abs( ( p0_nodeVar55 - p0_nodeVar54 ) );
	p0_nodeVar57 = ( ( - p0_nodeVar51 ) - p0_nodeVar54 );
	p0_nodeVar58 = floor( ( p0_nodeVar57 + 0.5 ) );
	p0_nodeVar59 = abs( ( p0_nodeVar58 - p0_nodeVar57 ) );

	if ( ( ( p0_nodeVar53 > p0_nodeVar56 ) && ( p0_nodeVar53 > p0_nodeVar59 ) ) ) {

		p0_nodeVar49 = ( ( - p0_nodeVar55 ) - p0_nodeVar58 );

	} else {

		p0_nodeVar49 = p0_nodeVar52;

	}


	if ( ( ( ( p0_nodeVar53 <= p0_nodeVar56 ) || ( p0_nodeVar53 <= p0_nodeVar59 ) ) && ( p0_nodeVar56 > p0_nodeVar59 ) ) ) {

		p0_nodeVar60 = ( ( - p0_nodeVar49 ) - p0_nodeVar58 );

	} else {

		p0_nodeVar60 = p0_nodeVar55;

	}

	p0_nodeVar61 = vec2<f32>( ( ( ( p0_nodeVar49 * 1.7320508075688772 ) + ( p0_nodeVar60 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar60 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar62 = picture_read( ( p0_nodeVar61 / p0_nodeVar3 ) );
	p0_nodeVar65 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 4.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar66 = ( ( ( p0_nodeVar65.x * 0.5773502691896257 ) - ( p0_nodeVar65.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar67 = floor( ( p0_nodeVar66 + 0.5 ) );
	p0_nodeVar68 = abs( ( p0_nodeVar67 - p0_nodeVar66 ) );
	p0_nodeVar69 = ( ( p0_nodeVar65.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar70 = floor( ( p0_nodeVar69 + 0.5 ) );
	p0_nodeVar71 = abs( ( p0_nodeVar70 - p0_nodeVar69 ) );
	p0_nodeVar72 = ( ( - p0_nodeVar66 ) - p0_nodeVar69 );
	p0_nodeVar73 = floor( ( p0_nodeVar72 + 0.5 ) );
	p0_nodeVar74 = abs( ( p0_nodeVar73 - p0_nodeVar72 ) );

	if ( ( ( p0_nodeVar68 > p0_nodeVar71 ) && ( p0_nodeVar68 > p0_nodeVar74 ) ) ) {

		p0_nodeVar64 = ( ( - p0_nodeVar70 ) - p0_nodeVar73 );

	} else {

		p0_nodeVar64 = p0_nodeVar67;

	}


	if ( ( ( ( p0_nodeVar68 <= p0_nodeVar71 ) || ( p0_nodeVar68 <= p0_nodeVar74 ) ) && ( p0_nodeVar71 > p0_nodeVar74 ) ) ) {

		p0_nodeVar75 = ( ( - p0_nodeVar64 ) - p0_nodeVar73 );

	} else {

		p0_nodeVar75 = p0_nodeVar70;

	}

	p0_nodeVar76 = vec2<f32>( ( ( ( p0_nodeVar64 * 1.7320508075688772 ) + ( p0_nodeVar75 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar75 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar77 = picture_read( ( p0_nodeVar76 / p0_nodeVar3 ) );
	p0_nodeVar80 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 5.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar81 = ( ( ( p0_nodeVar80.x * 0.5773502691896257 ) - ( p0_nodeVar80.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar82 = floor( ( p0_nodeVar81 + 0.5 ) );
	p0_nodeVar83 = abs( ( p0_nodeVar82 - p0_nodeVar81 ) );
	p0_nodeVar84 = ( ( p0_nodeVar80.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar85 = floor( ( p0_nodeVar84 + 0.5 ) );
	p0_nodeVar86 = abs( ( p0_nodeVar85 - p0_nodeVar84 ) );
	p0_nodeVar87 = ( ( - p0_nodeVar81 ) - p0_nodeVar84 );
	p0_nodeVar88 = floor( ( p0_nodeVar87 + 0.5 ) );
	p0_nodeVar89 = abs( ( p0_nodeVar88 - p0_nodeVar87 ) );

	if ( ( ( p0_nodeVar83 > p0_nodeVar86 ) && ( p0_nodeVar83 > p0_nodeVar89 ) ) ) {

		p0_nodeVar79 = ( ( - p0_nodeVar85 ) - p0_nodeVar88 );

	} else {

		p0_nodeVar79 = p0_nodeVar82;

	}


	if ( ( ( ( p0_nodeVar83 <= p0_nodeVar86 ) || ( p0_nodeVar83 <= p0_nodeVar89 ) ) && ( p0_nodeVar86 > p0_nodeVar89 ) ) ) {

		p0_nodeVar90 = ( ( - p0_nodeVar79 ) - p0_nodeVar88 );

	} else {

		p0_nodeVar90 = p0_nodeVar85;

	}

	p0_nodeVar91 = vec2<f32>( ( ( ( p0_nodeVar79 * 1.7320508075688772 ) + ( p0_nodeVar90 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar90 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar92 = picture_read( ( p0_nodeVar91 / p0_nodeVar3 ) );
	p0_nodeVar95 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 6.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar96 = ( ( ( p0_nodeVar95.x * 0.5773502691896257 ) - ( p0_nodeVar95.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar97 = floor( ( p0_nodeVar96 + 0.5 ) );
	p0_nodeVar98 = abs( ( p0_nodeVar97 - p0_nodeVar96 ) );
	p0_nodeVar99 = ( ( p0_nodeVar95.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar100 = floor( ( p0_nodeVar99 + 0.5 ) );
	p0_nodeVar101 = abs( ( p0_nodeVar100 - p0_nodeVar99 ) );
	p0_nodeVar102 = ( ( - p0_nodeVar96 ) - p0_nodeVar99 );
	p0_nodeVar103 = floor( ( p0_nodeVar102 + 0.5 ) );
	p0_nodeVar104 = abs( ( p0_nodeVar103 - p0_nodeVar102 ) );

	if ( ( ( p0_nodeVar98 > p0_nodeVar101 ) && ( p0_nodeVar98 > p0_nodeVar104 ) ) ) {

		p0_nodeVar94 = ( ( - p0_nodeVar100 ) - p0_nodeVar103 );

	} else {

		p0_nodeVar94 = p0_nodeVar97;

	}


	if ( ( ( ( p0_nodeVar98 <= p0_nodeVar101 ) || ( p0_nodeVar98 <= p0_nodeVar104 ) ) && ( p0_nodeVar101 > p0_nodeVar104 ) ) ) {

		p0_nodeVar105 = ( ( - p0_nodeVar94 ) - p0_nodeVar103 );

	} else {

		p0_nodeVar105 = p0_nodeVar100;

	}

	p0_nodeVar106 = vec2<f32>( ( ( ( p0_nodeVar94 * 1.7320508075688772 ) + ( p0_nodeVar105 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar105 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar107 = picture_read( ( p0_nodeVar106 / p0_nodeVar3 ) );
	p0_nodeVar110 = vec2<f32>( p0_nodeVar4.x, ( p0_nodeVar4.y + ( 7.0 * f32(knobs.cellSize) ) ) );
	p0_nodeVar111 = ( ( ( p0_nodeVar110.x * 0.5773502691896257 ) - ( p0_nodeVar110.y / 3.0 ) ) / f32(knobs.cellSize) );
	p0_nodeVar112 = floor( ( p0_nodeVar111 + 0.5 ) );
	p0_nodeVar113 = abs( ( p0_nodeVar112 - p0_nodeVar111 ) );
	p0_nodeVar114 = ( ( p0_nodeVar110.y * 0.6666666666666666 ) / f32(knobs.cellSize) );
	p0_nodeVar115 = floor( ( p0_nodeVar114 + 0.5 ) );
	p0_nodeVar116 = abs( ( p0_nodeVar115 - p0_nodeVar114 ) );
	p0_nodeVar117 = ( ( - p0_nodeVar111 ) - p0_nodeVar114 );
	p0_nodeVar118 = floor( ( p0_nodeVar117 + 0.5 ) );
	p0_nodeVar119 = abs( ( p0_nodeVar118 - p0_nodeVar117 ) );

	if ( ( ( p0_nodeVar113 > p0_nodeVar116 ) && ( p0_nodeVar113 > p0_nodeVar119 ) ) ) {

		p0_nodeVar109 = ( ( - p0_nodeVar115 ) - p0_nodeVar118 );

	} else {

		p0_nodeVar109 = p0_nodeVar112;

	}


	if ( ( ( ( p0_nodeVar113 <= p0_nodeVar116 ) || ( p0_nodeVar113 <= p0_nodeVar119 ) ) && ( p0_nodeVar116 > p0_nodeVar119 ) ) ) {

		p0_nodeVar120 = ( ( - p0_nodeVar109 ) - p0_nodeVar118 );

	} else {

		p0_nodeVar120 = p0_nodeVar115;

	}

	p0_nodeVar121 = vec2<f32>( ( ( ( p0_nodeVar109 * 1.7320508075688772 ) + ( p0_nodeVar120 * 0.8660254037844386 ) ) * f32(knobs.cellSize) ), ( ( p0_nodeVar120 * 1.5 ) * f32(knobs.cellSize) ) );
	p0_nodeVar122 = picture_read( ( p0_nodeVar121 / p0_nodeVar3 ) );
	p0_nodeVar123 = ( ( 7.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar122.x * 0.2126 ) + ( p0_nodeVar122.y * 0.7152 ) ) + ( p0_nodeVar122.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( 0.0 < 0.5 ) );

	if ( p0_nodeVar123 ) {

		p0_nodeVar108 = 1.0;

	} else {

		p0_nodeVar108 = 0.0;

	}

	p0_nodeVar124 = ( ( 6.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar107.x * 0.2126 ) + ( p0_nodeVar107.y * 0.7152 ) ) + ( p0_nodeVar107.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar108 < 0.5 ) );

	if ( p0_nodeVar124 ) {

		p0_nodeVar93 = 1.0;

	} else {

		p0_nodeVar93 = p0_nodeVar108;

	}

	p0_nodeVar125 = ( ( 5.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar92.x * 0.2126 ) + ( p0_nodeVar92.y * 0.7152 ) ) + ( p0_nodeVar92.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar93 < 0.5 ) );

	if ( p0_nodeVar125 ) {

		p0_nodeVar78 = 1.0;

	} else {

		p0_nodeVar78 = p0_nodeVar93;

	}

	p0_nodeVar126 = ( ( 4.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar77.x * 0.2126 ) + ( p0_nodeVar77.y * 0.7152 ) ) + ( p0_nodeVar77.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar78 < 0.5 ) );

	if ( p0_nodeVar126 ) {

		p0_nodeVar63 = 1.0;

	} else {

		p0_nodeVar63 = p0_nodeVar78;

	}

	p0_nodeVar127 = ( ( 3.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar62.x * 0.2126 ) + ( p0_nodeVar62.y * 0.7152 ) ) + ( p0_nodeVar62.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar63 < 0.5 ) );

	if ( p0_nodeVar127 ) {

		p0_nodeVar48 = 1.0;

	} else {

		p0_nodeVar48 = p0_nodeVar63;

	}

	p0_nodeVar128 = ( ( 2.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar47.x * 0.2126 ) + ( p0_nodeVar47.y * 0.7152 ) ) + ( p0_nodeVar47.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar48 < 0.5 ) );

	if ( p0_nodeVar128 ) {

		p0_nodeVar33 = 1.0;

	} else {

		p0_nodeVar33 = p0_nodeVar48;

	}

	p0_nodeVar129 = ( ( 1.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar32.x * 0.2126 ) + ( p0_nodeVar32.y * 0.7152 ) ) + ( p0_nodeVar32.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar33 < 0.5 ) );

	if ( p0_nodeVar129 ) {

		p0_nodeVar18 = 1.0;

	} else {

		p0_nodeVar18 = p0_nodeVar33;

	}

	p0_nodeVar130 = ( ( 0.0 < mix( 1.0, ( 1.0 + ( ( ( ( p0_nodeVar17.x * 0.2126 ) + ( p0_nodeVar17.y * 0.7152 ) ) + ( p0_nodeVar17.z * 0.0722 ) ) * ( f32(knobs.maxHeight) - 1.0 ) ) ), f32(knobs.depth) ) ) && ( p0_nodeVar18 < 0.5 ) );

	if ( p0_nodeVar130 ) {

		p0_nodeVar1 = vec3<f32>( p0_nodeVar17.x, p0_nodeVar17.y, p0_nodeVar17.z );

	} else {


		if ( p0_nodeVar129 ) {

			p0_nodeVar131 = vec3<f32>( p0_nodeVar32.x, p0_nodeVar32.y, p0_nodeVar32.z );

		} else {


			if ( p0_nodeVar128 ) {

				p0_nodeVar132 = vec3<f32>( p0_nodeVar47.x, p0_nodeVar47.y, p0_nodeVar47.z );

			} else {


				if ( p0_nodeVar127 ) {

					p0_nodeVar133 = vec3<f32>( p0_nodeVar62.x, p0_nodeVar62.y, p0_nodeVar62.z );

				} else {


					if ( p0_nodeVar126 ) {

						p0_nodeVar134 = vec3<f32>( p0_nodeVar77.x, p0_nodeVar77.y, p0_nodeVar77.z );

					} else {


						if ( p0_nodeVar125 ) {

							p0_nodeVar135 = vec3<f32>( p0_nodeVar92.x, p0_nodeVar92.y, p0_nodeVar92.z );

						} else {


							if ( p0_nodeVar124 ) {

								p0_nodeVar136 = vec3<f32>( p0_nodeVar107.x, p0_nodeVar107.y, p0_nodeVar107.z );

							} else {


								if ( p0_nodeVar123 ) {

									p0_nodeVar137 = vec3<f32>( p0_nodeVar122.x, p0_nodeVar122.y, p0_nodeVar122.z );

								} else {

									p0_nodeVar137 = vec3<f32>( 0.0, 0.0, 0.0 );

								}

								p0_nodeVar136 = p0_nodeVar137;

							}

							p0_nodeVar135 = p0_nodeVar136;

						}

						p0_nodeVar134 = p0_nodeVar135;

					}

					p0_nodeVar133 = p0_nodeVar134;

				}

				p0_nodeVar132 = p0_nodeVar133;

			}

			p0_nodeVar131 = p0_nodeVar132;

		}

		p0_nodeVar1 = p0_nodeVar131;

	}


	if ( p0_nodeVar130 ) {

		p0_nodeVar139 = p0_nodeVar16;

	} else {


		if ( p0_nodeVar129 ) {

			p0_nodeVar140 = p0_nodeVar31;

		} else {


			if ( p0_nodeVar128 ) {

				p0_nodeVar141 = p0_nodeVar46;

			} else {


				if ( p0_nodeVar127 ) {

					p0_nodeVar142 = p0_nodeVar61;

				} else {


					if ( p0_nodeVar126 ) {

						p0_nodeVar143 = p0_nodeVar76;

					} else {


						if ( p0_nodeVar125 ) {

							p0_nodeVar144 = p0_nodeVar91;

						} else {


							if ( p0_nodeVar124 ) {

								p0_nodeVar145 = p0_nodeVar106;

							} else {


								if ( p0_nodeVar123 ) {

									p0_nodeVar146 = p0_nodeVar121;

								} else {

									p0_nodeVar146 = vec2<f32>( 0.0, 0.0 );

								}

								p0_nodeVar145 = p0_nodeVar146;

							}

							p0_nodeVar144 = p0_nodeVar145;

						}

						p0_nodeVar143 = p0_nodeVar144;

					}

					p0_nodeVar142 = p0_nodeVar143;

				}

				p0_nodeVar141 = p0_nodeVar142;

			}

			p0_nodeVar140 = p0_nodeVar141;

		}

		p0_nodeVar139 = p0_nodeVar140;

	}


	if ( p0_nodeVar130 ) {

		p0_nodeVar147 = 0.0;

	} else {


		if ( p0_nodeVar129 ) {

			p0_nodeVar148 = 1.0;

		} else {


			if ( p0_nodeVar128 ) {

				p0_nodeVar149 = 2.0;

			} else {


				if ( p0_nodeVar127 ) {

					p0_nodeVar150 = 3.0;

				} else {


					if ( p0_nodeVar126 ) {

						p0_nodeVar151 = 4.0;

					} else {


						if ( p0_nodeVar125 ) {

							p0_nodeVar152 = 5.0;

						} else {


							if ( p0_nodeVar124 ) {

								p0_nodeVar153 = 6.0;

							} else {


								if ( p0_nodeVar123 ) {

									p0_nodeVar154 = 7.0;

								} else {

									p0_nodeVar154 = 0.0;

								}

								p0_nodeVar153 = p0_nodeVar154;

							}

							p0_nodeVar152 = p0_nodeVar153;

						}

						p0_nodeVar151 = p0_nodeVar152;

					}

					p0_nodeVar150 = p0_nodeVar151;

				}

				p0_nodeVar149 = p0_nodeVar150;

			}

			p0_nodeVar148 = p0_nodeVar149;

		}

		p0_nodeVar147 = p0_nodeVar148;

	}

	p0_nodeVar155 = ( p0_nodeVar4 - vec2<f32>( p0_nodeVar139.x, ( p0_nodeVar139.y - ( p0_nodeVar147 * f32(knobs.cellSize) ) ) ) );
	p0_nodeVar156 = ( - ( abs( p0_nodeVar155.x ) / 1.7320508075688772 ) );
	p0_nodeVar157 = ( p0_nodeVar155.y < p0_nodeVar156 );
	p0_nodeVar158 = ( f32(knobs.cellSize) * 0.4 );
	p0_nodeVar159 = ( f32(knobs.cellSize) * -0.5 );
	p0_nodeVar160 = ( p0_nodeVar159 - ( f32(knobs.cellSize) * 0.18 ) );
	p0_nodeVar161 = ( p0_nodeVar155.y - p0_nodeVar160 );
	p0_nodeVar162 = ( f32(knobs.cellSize) * 0.2 );
	p0_nodeVar163 = ( ( ( ( p0_nodeVar155.x / p0_nodeVar158 ) * ( p0_nodeVar155.x / p0_nodeVar158 ) ) + ( ( p0_nodeVar161 / p0_nodeVar162 ) * ( p0_nodeVar161 / p0_nodeVar162 ) ) ) < 1.0 );
	p0_nodeVar164 = ( sqrt( clamp( ( 1.0 - ( ( p0_nodeVar155.x / p0_nodeVar158 ) * ( p0_nodeVar155.x / p0_nodeVar158 ) ) ), 0.0, 1.0 ) ) * p0_nodeVar162 );

	if ( ( ( ( f32(knobs.lego) > 0.5 ) && p0_nodeVar157 ) && ( p0_nodeVar163 || ( ( ( abs( p0_nodeVar155.x ) < p0_nodeVar158 ) && ( p0_nodeVar155.y >= ( p0_nodeVar160 + p0_nodeVar164 ) ) ) && ( p0_nodeVar155.y < ( p0_nodeVar159 + p0_nodeVar164 ) ) ) ) ) ) {


		if ( p0_nodeVar163 ) {

			p0_nodeVar165 = ( f32(knobs.topShade) * 0.92 );

		} else {

			p0_nodeVar167 = ( f32(knobs.flipLight) > 0.5 );

			if ( p0_nodeVar167 ) {

				p0_nodeVar166 = f32(knobs.lightShade);

			} else {

				p0_nodeVar166 = f32(knobs.darkShade);

			}


			if ( p0_nodeVar167 ) {

				p0_nodeVar168 = f32(knobs.darkShade);

			} else {

				p0_nodeVar168 = f32(knobs.lightShade);

			}

			p0_nodeVar165 = mix( p0_nodeVar166, p0_nodeVar168, clamp( ( ( ( p0_nodeVar155.x / p0_nodeVar158 ) + 1.0 ) * 0.5 ), 0.0, 1.0 ) );

		}

		p0_nodeVar138 = p0_nodeVar165;

	} else {


		if ( p0_nodeVar157 ) {

			p0_nodeVar169 = f32(knobs.topShade);

		} else {


			if ( ( ( p0_nodeVar155.y >= p0_nodeVar156 ) && ( p0_nodeVar155.x > 0.0 ) ) ) {


				if ( ( f32(knobs.flipLight) > 0.5 ) ) {

					p0_nodeVar171 = f32(knobs.darkShade);

				} else {

					p0_nodeVar171 = f32(knobs.lightShade);

				}

				p0_nodeVar170 = p0_nodeVar171;

			} else {


				if ( ( f32(knobs.flipLight) > 0.5 ) ) {

					p0_nodeVar172 = f32(knobs.lightShade);

				} else {

					p0_nodeVar172 = f32(knobs.darkShade);

				}

				p0_nodeVar170 = p0_nodeVar172;

			}

			p0_nodeVar169 = p0_nodeVar170;

		}

		p0_nodeVar138 = p0_nodeVar169;

	}

	p0_nodeVar173 = vec4<f32>( mix( ( p0_nodeVar1 * vec3<f32>( p0_nodeVar138 ) ), vec3<f32>( vec3<f32>(knobs.outlineColor.x, knobs.outlineColor.y, knobs.outlineColor.z).x, vec3<f32>(knobs.outlineColor.x, knobs.outlineColor.y, knobs.outlineColor.z).y, vec3<f32>(knobs.outlineColor.x, knobs.outlineColor.y, knobs.outlineColor.z).z ), ( 1.0 - smoothstep( 0.0, max( f32(knobs.outlineWidth), 0.0001 ), ( ( f32(knobs.cellSize) * 0.8660254037844386 ) - max( max( abs( p0_nodeVar155.x ), abs( ( ( p0_nodeVar155.x * 0.5 ) + ( p0_nodeVar155.y * 0.8660254037844386 ) ) ) ), abs( ( ( p0_nodeVar155.x * 0.5 ) - ( p0_nodeVar155.y * 0.8660254037844386 ) ) ) ) ) ) ) ), 1.0 );
	p0_nodeVar174 = vec3<f32>( p0_nodeVar173.x, p0_nodeVar173.y, p0_nodeVar173.z );
	p0_nodeVar175 = ( ( ( p0_nodeVar174.x * 0.2126 ) + ( p0_nodeVar174.y * 0.7152 ) ) + ( p0_nodeVar174.z * 0.0722 ) );
	p0_nodeVar176 = mix( vec3<f32>( p0_nodeVar175, p0_nodeVar175, p0_nodeVar175 ), p0_nodeVar174, f32(1.0) );
	p0_nodeVar177 = vec4<f32>( clamp( vec3<f32>( ( ( ( p0_nodeVar176.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( p0_nodeVar176.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar176.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( p0_nodeVar176.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( p0_nodeVar176.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( p0_nodeVar176.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( p0_nodeVar176.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( p0_nodeVar176.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( p0_nodeVar176.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( p0_nodeVar173.w, 0.0, 1.0 ) );
	p0_DiffuseColor = vec4<f32>( mix( p0_nodeVar0.xyz, p0_nodeVar177.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( p0_nodeVar177.w, 0.0, 1.0 ) ) ), clamp( p0_nodeVar0.w, 0.0, 1.0 ) );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_nodeVar178 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar178;

	// result

	p0_output.color = p0_nodeVar178;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color);
}

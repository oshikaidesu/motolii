// Voxel: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
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
  resolution: vec2<f32>,
  cellSize: f32,
  maxHeight: f32,
  depth: f32,
  lego: f32,
  topShade: f32,
  flipLight: f32,
  lightShade: f32,
  darkShade: f32,
  outlineWidth: f32,
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
var<private> nodeVar1 : vec3<f32>;
var<private> nodeVar2 : f32;
var<private> nodeVar3 : vec2<f32>;
var<private> nodeVar4 : vec2<f32>;
var<private> nodeVar5 : vec2<f32>;
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
var<private> nodeVar16 : vec2<f32>;
var<private> nodeVar17 : vec4<f32>;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : vec2<f32>;
var<private> nodeVar21 : f32;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : f32;
var<private> nodeVar30 : f32;
var<private> nodeVar31 : vec2<f32>;
var<private> nodeVar32 : vec4<f32>;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : vec2<f32>;
var<private> nodeVar36 : f32;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : f32;
var<private> nodeVar39 : f32;
var<private> nodeVar40 : f32;
var<private> nodeVar41 : f32;
var<private> nodeVar42 : f32;
var<private> nodeVar43 : f32;
var<private> nodeVar44 : f32;
var<private> nodeVar45 : f32;
var<private> nodeVar46 : vec2<f32>;
var<private> nodeVar47 : vec4<f32>;
var<private> nodeVar48 : f32;
var<private> nodeVar49 : f32;
var<private> nodeVar50 : vec2<f32>;
var<private> nodeVar51 : f32;
var<private> nodeVar52 : f32;
var<private> nodeVar53 : f32;
var<private> nodeVar54 : f32;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : f32;
var<private> nodeVar58 : f32;
var<private> nodeVar59 : f32;
var<private> nodeVar60 : f32;
var<private> nodeVar61 : vec2<f32>;
var<private> nodeVar62 : vec4<f32>;
var<private> nodeVar63 : f32;
var<private> nodeVar64 : f32;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : f32;
var<private> nodeVar67 : f32;
var<private> nodeVar68 : f32;
var<private> nodeVar69 : f32;
var<private> nodeVar70 : f32;
var<private> nodeVar71 : f32;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : f32;
var<private> nodeVar74 : f32;
var<private> nodeVar75 : f32;
var<private> nodeVar76 : vec2<f32>;
var<private> nodeVar77 : vec4<f32>;
var<private> nodeVar78 : f32;
var<private> nodeVar79 : f32;
var<private> nodeVar80 : vec2<f32>;
var<private> nodeVar81 : f32;
var<private> nodeVar82 : f32;
var<private> nodeVar83 : f32;
var<private> nodeVar84 : f32;
var<private> nodeVar85 : f32;
var<private> nodeVar86 : f32;
var<private> nodeVar87 : f32;
var<private> nodeVar88 : f32;
var<private> nodeVar89 : f32;
var<private> nodeVar90 : f32;
var<private> nodeVar91 : vec2<f32>;
var<private> nodeVar92 : vec4<f32>;
var<private> nodeVar93 : f32;
var<private> nodeVar94 : f32;
var<private> nodeVar95 : vec2<f32>;
var<private> nodeVar96 : f32;
var<private> nodeVar97 : f32;
var<private> nodeVar98 : f32;
var<private> nodeVar99 : f32;
var<private> nodeVar100 : f32;
var<private> nodeVar101 : f32;
var<private> nodeVar102 : f32;
var<private> nodeVar103 : f32;
var<private> nodeVar104 : f32;
var<private> nodeVar105 : f32;
var<private> nodeVar106 : vec2<f32>;
var<private> nodeVar107 : vec4<f32>;
var<private> nodeVar108 : f32;
var<private> nodeVar109 : f32;
var<private> nodeVar110 : vec2<f32>;
var<private> nodeVar111 : f32;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : f32;
var<private> nodeVar114 : f32;
var<private> nodeVar115 : f32;
var<private> nodeVar116 : f32;
var<private> nodeVar117 : f32;
var<private> nodeVar118 : f32;
var<private> nodeVar119 : f32;
var<private> nodeVar120 : f32;
var<private> nodeVar121 : vec2<f32>;
var<private> nodeVar122 : vec4<f32>;
var<private> nodeVar123 : bool;
var<private> nodeVar124 : bool;
var<private> nodeVar125 : bool;
var<private> nodeVar126 : bool;
var<private> nodeVar127 : bool;
var<private> nodeVar128 : bool;
var<private> nodeVar129 : bool;
var<private> nodeVar130 : bool;
var<private> nodeVar131 : vec3<f32>;
var<private> nodeVar132 : vec3<f32>;
var<private> nodeVar133 : vec3<f32>;
var<private> nodeVar134 : vec3<f32>;
var<private> nodeVar135 : vec3<f32>;
var<private> nodeVar136 : vec3<f32>;
var<private> nodeVar137 : vec3<f32>;
var<private> nodeVar138 : f32;
var<private> nodeVar139 : vec2<f32>;
var<private> nodeVar140 : vec2<f32>;
var<private> nodeVar141 : vec2<f32>;
var<private> nodeVar142 : vec2<f32>;
var<private> nodeVar143 : vec2<f32>;
var<private> nodeVar144 : vec2<f32>;
var<private> nodeVar145 : vec2<f32>;
var<private> nodeVar146 : vec2<f32>;
var<private> nodeVar147 : f32;
var<private> nodeVar148 : f32;
var<private> nodeVar149 : f32;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : f32;
var<private> nodeVar153 : f32;
var<private> nodeVar154 : f32;
var<private> nodeVar155 : vec2<f32>;
var<private> nodeVar156 : f32;
var<private> nodeVar157 : bool;
var<private> nodeVar158 : f32;
var<private> nodeVar159 : f32;
var<private> nodeVar160 : f32;
var<private> nodeVar161 : f32;
var<private> nodeVar162 : f32;
var<private> nodeVar163 : bool;
var<private> nodeVar164 : f32;
var<private> nodeVar165 : f32;
var<private> nodeVar166 : f32;
var<private> nodeVar167 : bool;
var<private> nodeVar168 : f32;
var<private> nodeVar169 : f32;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : f32;
var<private> nodeVar173 : vec4<f32>;
var<private> nodeVar174 : vec3<f32>;
var<private> nodeVar175 : f32;
var<private> nodeVar176 : vec3<f32>;
var<private> nodeVar177 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar178 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar3 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
	nodeVar4 = ( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) * nodeVar3 );
	nodeVar5 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 0.0 * knobs.cellSize ) ) );
	nodeVar6 = ( ( ( nodeVar5.x * 0.5773502691896257 ) - ( nodeVar5.y / 3.0 ) ) / knobs.cellSize );
	nodeVar7 = floor( ( nodeVar6 + 0.5 ) );
	nodeVar8 = abs( ( nodeVar7 - nodeVar6 ) );
	nodeVar9 = ( ( nodeVar5.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar10 = floor( ( nodeVar9 + 0.5 ) );
	nodeVar11 = abs( ( nodeVar10 - nodeVar9 ) );
	nodeVar12 = ( ( - nodeVar6 ) - nodeVar9 );
	nodeVar13 = floor( ( nodeVar12 + 0.5 ) );
	nodeVar14 = abs( ( nodeVar13 - nodeVar12 ) );

	if ( ( ( nodeVar8 > nodeVar11 ) && ( nodeVar8 > nodeVar14 ) ) ) {

		nodeVar2 = ( ( - nodeVar10 ) - nodeVar13 );

	} else {

		nodeVar2 = nodeVar7;

	}


	if ( ( ( ( nodeVar8 <= nodeVar11 ) || ( nodeVar8 <= nodeVar14 ) ) && ( nodeVar11 > nodeVar14 ) ) ) {

		nodeVar15 = ( ( - nodeVar2 ) - nodeVar13 );

	} else {

		nodeVar15 = nodeVar10;

	}

	nodeVar16 = vec2<f32>( ( ( ( nodeVar2 * 1.7320508075688772 ) + ( nodeVar15 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar15 * 1.5 ) * knobs.cellSize ) );
	nodeVar17 = picture_read( ( nodeVar16 / nodeVar3 ) );
	nodeVar20 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 1.0 * knobs.cellSize ) ) );
	nodeVar21 = ( ( ( nodeVar20.x * 0.5773502691896257 ) - ( nodeVar20.y / 3.0 ) ) / knobs.cellSize );
	nodeVar22 = floor( ( nodeVar21 + 0.5 ) );
	nodeVar23 = abs( ( nodeVar22 - nodeVar21 ) );
	nodeVar24 = ( ( nodeVar20.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar25 = floor( ( nodeVar24 + 0.5 ) );
	nodeVar26 = abs( ( nodeVar25 - nodeVar24 ) );
	nodeVar27 = ( ( - nodeVar21 ) - nodeVar24 );
	nodeVar28 = floor( ( nodeVar27 + 0.5 ) );
	nodeVar29 = abs( ( nodeVar28 - nodeVar27 ) );

	if ( ( ( nodeVar23 > nodeVar26 ) && ( nodeVar23 > nodeVar29 ) ) ) {

		nodeVar19 = ( ( - nodeVar25 ) - nodeVar28 );

	} else {

		nodeVar19 = nodeVar22;

	}


	if ( ( ( ( nodeVar23 <= nodeVar26 ) || ( nodeVar23 <= nodeVar29 ) ) && ( nodeVar26 > nodeVar29 ) ) ) {

		nodeVar30 = ( ( - nodeVar19 ) - nodeVar28 );

	} else {

		nodeVar30 = nodeVar25;

	}

	nodeVar31 = vec2<f32>( ( ( ( nodeVar19 * 1.7320508075688772 ) + ( nodeVar30 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar30 * 1.5 ) * knobs.cellSize ) );
	nodeVar32 = picture_read( ( nodeVar31 / nodeVar3 ) );
	nodeVar35 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 2.0 * knobs.cellSize ) ) );
	nodeVar36 = ( ( ( nodeVar35.x * 0.5773502691896257 ) - ( nodeVar35.y / 3.0 ) ) / knobs.cellSize );
	nodeVar37 = floor( ( nodeVar36 + 0.5 ) );
	nodeVar38 = abs( ( nodeVar37 - nodeVar36 ) );
	nodeVar39 = ( ( nodeVar35.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar40 = floor( ( nodeVar39 + 0.5 ) );
	nodeVar41 = abs( ( nodeVar40 - nodeVar39 ) );
	nodeVar42 = ( ( - nodeVar36 ) - nodeVar39 );
	nodeVar43 = floor( ( nodeVar42 + 0.5 ) );
	nodeVar44 = abs( ( nodeVar43 - nodeVar42 ) );

	if ( ( ( nodeVar38 > nodeVar41 ) && ( nodeVar38 > nodeVar44 ) ) ) {

		nodeVar34 = ( ( - nodeVar40 ) - nodeVar43 );

	} else {

		nodeVar34 = nodeVar37;

	}


	if ( ( ( ( nodeVar38 <= nodeVar41 ) || ( nodeVar38 <= nodeVar44 ) ) && ( nodeVar41 > nodeVar44 ) ) ) {

		nodeVar45 = ( ( - nodeVar34 ) - nodeVar43 );

	} else {

		nodeVar45 = nodeVar40;

	}

	nodeVar46 = vec2<f32>( ( ( ( nodeVar34 * 1.7320508075688772 ) + ( nodeVar45 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar45 * 1.5 ) * knobs.cellSize ) );
	nodeVar47 = picture_read( ( nodeVar46 / nodeVar3 ) );
	nodeVar50 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 3.0 * knobs.cellSize ) ) );
	nodeVar51 = ( ( ( nodeVar50.x * 0.5773502691896257 ) - ( nodeVar50.y / 3.0 ) ) / knobs.cellSize );
	nodeVar52 = floor( ( nodeVar51 + 0.5 ) );
	nodeVar53 = abs( ( nodeVar52 - nodeVar51 ) );
	nodeVar54 = ( ( nodeVar50.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar55 = floor( ( nodeVar54 + 0.5 ) );
	nodeVar56 = abs( ( nodeVar55 - nodeVar54 ) );
	nodeVar57 = ( ( - nodeVar51 ) - nodeVar54 );
	nodeVar58 = floor( ( nodeVar57 + 0.5 ) );
	nodeVar59 = abs( ( nodeVar58 - nodeVar57 ) );

	if ( ( ( nodeVar53 > nodeVar56 ) && ( nodeVar53 > nodeVar59 ) ) ) {

		nodeVar49 = ( ( - nodeVar55 ) - nodeVar58 );

	} else {

		nodeVar49 = nodeVar52;

	}


	if ( ( ( ( nodeVar53 <= nodeVar56 ) || ( nodeVar53 <= nodeVar59 ) ) && ( nodeVar56 > nodeVar59 ) ) ) {

		nodeVar60 = ( ( - nodeVar49 ) - nodeVar58 );

	} else {

		nodeVar60 = nodeVar55;

	}

	nodeVar61 = vec2<f32>( ( ( ( nodeVar49 * 1.7320508075688772 ) + ( nodeVar60 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar60 * 1.5 ) * knobs.cellSize ) );
	nodeVar62 = picture_read( ( nodeVar61 / nodeVar3 ) );
	nodeVar65 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 4.0 * knobs.cellSize ) ) );
	nodeVar66 = ( ( ( nodeVar65.x * 0.5773502691896257 ) - ( nodeVar65.y / 3.0 ) ) / knobs.cellSize );
	nodeVar67 = floor( ( nodeVar66 + 0.5 ) );
	nodeVar68 = abs( ( nodeVar67 - nodeVar66 ) );
	nodeVar69 = ( ( nodeVar65.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar70 = floor( ( nodeVar69 + 0.5 ) );
	nodeVar71 = abs( ( nodeVar70 - nodeVar69 ) );
	nodeVar72 = ( ( - nodeVar66 ) - nodeVar69 );
	nodeVar73 = floor( ( nodeVar72 + 0.5 ) );
	nodeVar74 = abs( ( nodeVar73 - nodeVar72 ) );

	if ( ( ( nodeVar68 > nodeVar71 ) && ( nodeVar68 > nodeVar74 ) ) ) {

		nodeVar64 = ( ( - nodeVar70 ) - nodeVar73 );

	} else {

		nodeVar64 = nodeVar67;

	}


	if ( ( ( ( nodeVar68 <= nodeVar71 ) || ( nodeVar68 <= nodeVar74 ) ) && ( nodeVar71 > nodeVar74 ) ) ) {

		nodeVar75 = ( ( - nodeVar64 ) - nodeVar73 );

	} else {

		nodeVar75 = nodeVar70;

	}

	nodeVar76 = vec2<f32>( ( ( ( nodeVar64 * 1.7320508075688772 ) + ( nodeVar75 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar75 * 1.5 ) * knobs.cellSize ) );
	nodeVar77 = picture_read( ( nodeVar76 / nodeVar3 ) );
	nodeVar80 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 5.0 * knobs.cellSize ) ) );
	nodeVar81 = ( ( ( nodeVar80.x * 0.5773502691896257 ) - ( nodeVar80.y / 3.0 ) ) / knobs.cellSize );
	nodeVar82 = floor( ( nodeVar81 + 0.5 ) );
	nodeVar83 = abs( ( nodeVar82 - nodeVar81 ) );
	nodeVar84 = ( ( nodeVar80.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar85 = floor( ( nodeVar84 + 0.5 ) );
	nodeVar86 = abs( ( nodeVar85 - nodeVar84 ) );
	nodeVar87 = ( ( - nodeVar81 ) - nodeVar84 );
	nodeVar88 = floor( ( nodeVar87 + 0.5 ) );
	nodeVar89 = abs( ( nodeVar88 - nodeVar87 ) );

	if ( ( ( nodeVar83 > nodeVar86 ) && ( nodeVar83 > nodeVar89 ) ) ) {

		nodeVar79 = ( ( - nodeVar85 ) - nodeVar88 );

	} else {

		nodeVar79 = nodeVar82;

	}


	if ( ( ( ( nodeVar83 <= nodeVar86 ) || ( nodeVar83 <= nodeVar89 ) ) && ( nodeVar86 > nodeVar89 ) ) ) {

		nodeVar90 = ( ( - nodeVar79 ) - nodeVar88 );

	} else {

		nodeVar90 = nodeVar85;

	}

	nodeVar91 = vec2<f32>( ( ( ( nodeVar79 * 1.7320508075688772 ) + ( nodeVar90 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar90 * 1.5 ) * knobs.cellSize ) );
	nodeVar92 = picture_read( ( nodeVar91 / nodeVar3 ) );
	nodeVar95 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 6.0 * knobs.cellSize ) ) );
	nodeVar96 = ( ( ( nodeVar95.x * 0.5773502691896257 ) - ( nodeVar95.y / 3.0 ) ) / knobs.cellSize );
	nodeVar97 = floor( ( nodeVar96 + 0.5 ) );
	nodeVar98 = abs( ( nodeVar97 - nodeVar96 ) );
	nodeVar99 = ( ( nodeVar95.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar100 = floor( ( nodeVar99 + 0.5 ) );
	nodeVar101 = abs( ( nodeVar100 - nodeVar99 ) );
	nodeVar102 = ( ( - nodeVar96 ) - nodeVar99 );
	nodeVar103 = floor( ( nodeVar102 + 0.5 ) );
	nodeVar104 = abs( ( nodeVar103 - nodeVar102 ) );

	if ( ( ( nodeVar98 > nodeVar101 ) && ( nodeVar98 > nodeVar104 ) ) ) {

		nodeVar94 = ( ( - nodeVar100 ) - nodeVar103 );

	} else {

		nodeVar94 = nodeVar97;

	}


	if ( ( ( ( nodeVar98 <= nodeVar101 ) || ( nodeVar98 <= nodeVar104 ) ) && ( nodeVar101 > nodeVar104 ) ) ) {

		nodeVar105 = ( ( - nodeVar94 ) - nodeVar103 );

	} else {

		nodeVar105 = nodeVar100;

	}

	nodeVar106 = vec2<f32>( ( ( ( nodeVar94 * 1.7320508075688772 ) + ( nodeVar105 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar105 * 1.5 ) * knobs.cellSize ) );
	nodeVar107 = picture_read( ( nodeVar106 / nodeVar3 ) );
	nodeVar110 = vec2<f32>( nodeVar4.x, ( nodeVar4.y + ( 7.0 * knobs.cellSize ) ) );
	nodeVar111 = ( ( ( nodeVar110.x * 0.5773502691896257 ) - ( nodeVar110.y / 3.0 ) ) / knobs.cellSize );
	nodeVar112 = floor( ( nodeVar111 + 0.5 ) );
	nodeVar113 = abs( ( nodeVar112 - nodeVar111 ) );
	nodeVar114 = ( ( nodeVar110.y * 0.6666666666666666 ) / knobs.cellSize );
	nodeVar115 = floor( ( nodeVar114 + 0.5 ) );
	nodeVar116 = abs( ( nodeVar115 - nodeVar114 ) );
	nodeVar117 = ( ( - nodeVar111 ) - nodeVar114 );
	nodeVar118 = floor( ( nodeVar117 + 0.5 ) );
	nodeVar119 = abs( ( nodeVar118 - nodeVar117 ) );

	if ( ( ( nodeVar113 > nodeVar116 ) && ( nodeVar113 > nodeVar119 ) ) ) {

		nodeVar109 = ( ( - nodeVar115 ) - nodeVar118 );

	} else {

		nodeVar109 = nodeVar112;

	}


	if ( ( ( ( nodeVar113 <= nodeVar116 ) || ( nodeVar113 <= nodeVar119 ) ) && ( nodeVar116 > nodeVar119 ) ) ) {

		nodeVar120 = ( ( - nodeVar109 ) - nodeVar118 );

	} else {

		nodeVar120 = nodeVar115;

	}

	nodeVar121 = vec2<f32>( ( ( ( nodeVar109 * 1.7320508075688772 ) + ( nodeVar120 * 0.8660254037844386 ) ) * knobs.cellSize ), ( ( nodeVar120 * 1.5 ) * knobs.cellSize ) );
	nodeVar122 = picture_read( ( nodeVar121 / nodeVar3 ) );
	nodeVar123 = ( ( 7.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar122.x * 0.2126 ) + ( nodeVar122.y * 0.7152 ) ) + ( nodeVar122.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( 0.0 < 0.5 ) );

	if ( nodeVar123 ) {

		nodeVar108 = 1.0;

	} else {

		nodeVar108 = 0.0;

	}

	nodeVar124 = ( ( 6.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar107.x * 0.2126 ) + ( nodeVar107.y * 0.7152 ) ) + ( nodeVar107.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar108 < 0.5 ) );

	if ( nodeVar124 ) {

		nodeVar93 = 1.0;

	} else {

		nodeVar93 = nodeVar108;

	}

	nodeVar125 = ( ( 5.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar92.x * 0.2126 ) + ( nodeVar92.y * 0.7152 ) ) + ( nodeVar92.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar93 < 0.5 ) );

	if ( nodeVar125 ) {

		nodeVar78 = 1.0;

	} else {

		nodeVar78 = nodeVar93;

	}

	nodeVar126 = ( ( 4.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar77.x * 0.2126 ) + ( nodeVar77.y * 0.7152 ) ) + ( nodeVar77.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar78 < 0.5 ) );

	if ( nodeVar126 ) {

		nodeVar63 = 1.0;

	} else {

		nodeVar63 = nodeVar78;

	}

	nodeVar127 = ( ( 3.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar62.x * 0.2126 ) + ( nodeVar62.y * 0.7152 ) ) + ( nodeVar62.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar63 < 0.5 ) );

	if ( nodeVar127 ) {

		nodeVar48 = 1.0;

	} else {

		nodeVar48 = nodeVar63;

	}

	nodeVar128 = ( ( 2.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar47.x * 0.2126 ) + ( nodeVar47.y * 0.7152 ) ) + ( nodeVar47.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar48 < 0.5 ) );

	if ( nodeVar128 ) {

		nodeVar33 = 1.0;

	} else {

		nodeVar33 = nodeVar48;

	}

	nodeVar129 = ( ( 1.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar32.x * 0.2126 ) + ( nodeVar32.y * 0.7152 ) ) + ( nodeVar32.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar33 < 0.5 ) );

	if ( nodeVar129 ) {

		nodeVar18 = 1.0;

	} else {

		nodeVar18 = nodeVar33;

	}

	nodeVar130 = ( ( 0.0 < mix( 1.0, ( 1.0 + ( ( ( ( nodeVar17.x * 0.2126 ) + ( nodeVar17.y * 0.7152 ) ) + ( nodeVar17.z * 0.0722 ) ) * ( knobs.maxHeight - 1.0 ) ) ), knobs.depth ) ) && ( nodeVar18 < 0.5 ) );

	if ( nodeVar130 ) {

		nodeVar1 = vec3<f32>( nodeVar17.x, nodeVar17.y, nodeVar17.z );

	} else {


		if ( nodeVar129 ) {

			nodeVar131 = vec3<f32>( nodeVar32.x, nodeVar32.y, nodeVar32.z );

		} else {


			if ( nodeVar128 ) {

				nodeVar132 = vec3<f32>( nodeVar47.x, nodeVar47.y, nodeVar47.z );

			} else {


				if ( nodeVar127 ) {

					nodeVar133 = vec3<f32>( nodeVar62.x, nodeVar62.y, nodeVar62.z );

				} else {


					if ( nodeVar126 ) {

						nodeVar134 = vec3<f32>( nodeVar77.x, nodeVar77.y, nodeVar77.z );

					} else {


						if ( nodeVar125 ) {

							nodeVar135 = vec3<f32>( nodeVar92.x, nodeVar92.y, nodeVar92.z );

						} else {


							if ( nodeVar124 ) {

								nodeVar136 = vec3<f32>( nodeVar107.x, nodeVar107.y, nodeVar107.z );

							} else {


								if ( nodeVar123 ) {

									nodeVar137 = vec3<f32>( nodeVar122.x, nodeVar122.y, nodeVar122.z );

								} else {

									nodeVar137 = vec3<f32>( 0.0, 0.0, 0.0 );

								}

								nodeVar136 = nodeVar137;

							}

							nodeVar135 = nodeVar136;

						}

						nodeVar134 = nodeVar135;

					}

					nodeVar133 = nodeVar134;

				}

				nodeVar132 = nodeVar133;

			}

			nodeVar131 = nodeVar132;

		}

		nodeVar1 = nodeVar131;

	}


	if ( nodeVar130 ) {

		nodeVar139 = nodeVar16;

	} else {


		if ( nodeVar129 ) {

			nodeVar140 = nodeVar31;

		} else {


			if ( nodeVar128 ) {

				nodeVar141 = nodeVar46;

			} else {


				if ( nodeVar127 ) {

					nodeVar142 = nodeVar61;

				} else {


					if ( nodeVar126 ) {

						nodeVar143 = nodeVar76;

					} else {


						if ( nodeVar125 ) {

							nodeVar144 = nodeVar91;

						} else {


							if ( nodeVar124 ) {

								nodeVar145 = nodeVar106;

							} else {


								if ( nodeVar123 ) {

									nodeVar146 = nodeVar121;

								} else {

									nodeVar146 = vec2<f32>( 0.0, 0.0 );

								}

								nodeVar145 = nodeVar146;

							}

							nodeVar144 = nodeVar145;

						}

						nodeVar143 = nodeVar144;

					}

					nodeVar142 = nodeVar143;

				}

				nodeVar141 = nodeVar142;

			}

			nodeVar140 = nodeVar141;

		}

		nodeVar139 = nodeVar140;

	}


	if ( nodeVar130 ) {

		nodeVar147 = 0.0;

	} else {


		if ( nodeVar129 ) {

			nodeVar148 = 1.0;

		} else {


			if ( nodeVar128 ) {

				nodeVar149 = 2.0;

			} else {


				if ( nodeVar127 ) {

					nodeVar150 = 3.0;

				} else {


					if ( nodeVar126 ) {

						nodeVar151 = 4.0;

					} else {


						if ( nodeVar125 ) {

							nodeVar152 = 5.0;

						} else {


							if ( nodeVar124 ) {

								nodeVar153 = 6.0;

							} else {


								if ( nodeVar123 ) {

									nodeVar154 = 7.0;

								} else {

									nodeVar154 = 0.0;

								}

								nodeVar153 = nodeVar154;

							}

							nodeVar152 = nodeVar153;

						}

						nodeVar151 = nodeVar152;

					}

					nodeVar150 = nodeVar151;

				}

				nodeVar149 = nodeVar150;

			}

			nodeVar148 = nodeVar149;

		}

		nodeVar147 = nodeVar148;

	}

	nodeVar155 = ( nodeVar4 - vec2<f32>( nodeVar139.x, ( nodeVar139.y - ( nodeVar147 * knobs.cellSize ) ) ) );
	nodeVar156 = ( - ( abs( nodeVar155.x ) / 1.7320508075688772 ) );
	nodeVar157 = ( nodeVar155.y < nodeVar156 );
	nodeVar158 = ( knobs.cellSize * 0.4 );
	nodeVar159 = ( knobs.cellSize * -0.5 );
	nodeVar160 = ( nodeVar159 - ( knobs.cellSize * 0.18 ) );
	nodeVar161 = ( nodeVar155.y - nodeVar160 );
	nodeVar162 = ( knobs.cellSize * 0.2 );
	nodeVar163 = ( ( ( ( nodeVar155.x / nodeVar158 ) * ( nodeVar155.x / nodeVar158 ) ) + ( ( nodeVar161 / nodeVar162 ) * ( nodeVar161 / nodeVar162 ) ) ) < 1.0 );
	nodeVar164 = ( sqrt( clamp( ( 1.0 - ( ( nodeVar155.x / nodeVar158 ) * ( nodeVar155.x / nodeVar158 ) ) ), 0.0, 1.0 ) ) * nodeVar162 );

	if ( ( ( ( (1 * knobs.lego + 0) > 0.5 ) && nodeVar157 ) && ( nodeVar163 || ( ( ( abs( nodeVar155.x ) < nodeVar158 ) && ( nodeVar155.y >= ( nodeVar160 + nodeVar164 ) ) ) && ( nodeVar155.y < ( nodeVar159 + nodeVar164 ) ) ) ) ) ) {


		if ( nodeVar163 ) {

			nodeVar165 = ( knobs.topShade * 0.92 );

		} else {

			nodeVar167 = ( (1 * knobs.flipLight + 0) > 0.5 );

			if ( nodeVar167 ) {

				nodeVar166 = knobs.lightShade;

			} else {

				nodeVar166 = knobs.darkShade;

			}


			if ( nodeVar167 ) {

				nodeVar168 = knobs.darkShade;

			} else {

				nodeVar168 = knobs.lightShade;

			}

			nodeVar165 = mix( nodeVar166, nodeVar168, clamp( ( ( ( nodeVar155.x / nodeVar158 ) + 1.0 ) * 0.5 ), 0.0, 1.0 ) );

		}

		nodeVar138 = nodeVar165;

	} else {


		if ( nodeVar157 ) {

			nodeVar169 = knobs.topShade;

		} else {


			if ( ( ( nodeVar155.y >= nodeVar156 ) && ( nodeVar155.x > 0.0 ) ) ) {


				if ( ( (1 * knobs.flipLight + 0) > 0.5 ) ) {

					nodeVar171 = knobs.darkShade;

				} else {

					nodeVar171 = knobs.lightShade;

				}

				nodeVar170 = nodeVar171;

			} else {


				if ( ( (1 * knobs.flipLight + 0) > 0.5 ) ) {

					nodeVar172 = knobs.lightShade;

				} else {

					nodeVar172 = knobs.darkShade;

				}

				nodeVar170 = nodeVar172;

			}

			nodeVar169 = nodeVar170;

		}

		nodeVar138 = nodeVar169;

	}

	nodeVar173 = vec4<f32>( mix( ( nodeVar1 * vec3<f32>( nodeVar138 ) ), vec3<f32>( vec3<f32>(0.0030352698352941175, 0.0030352698352941175, 0.0030352698352941175).x, vec3<f32>(0.0030352698352941175, 0.0030352698352941175, 0.0030352698352941175).y, vec3<f32>(0.0030352698352941175, 0.0030352698352941175, 0.0030352698352941175).z ), ( 1.0 - smoothstep( 0.0, max( knobs.outlineWidth, 0.0001 ), ( ( knobs.cellSize * 0.8660254037844386 ) - max( max( abs( nodeVar155.x ), abs( ( ( nodeVar155.x * 0.5 ) + ( nodeVar155.y * 0.8660254037844386 ) ) ) ), abs( ( ( nodeVar155.x * 0.5 ) - ( nodeVar155.y * 0.8660254037844386 ) ) ) ) ) ) ) ), 1.0 );
	nodeVar174 = vec3<f32>( nodeVar173.x, nodeVar173.y, nodeVar173.z );
	nodeVar175 = ( ( ( nodeVar174.x * 0.2126 ) + ( nodeVar174.y * 0.7152 ) ) + ( nodeVar174.z * 0.0722 ) );
	nodeVar176 = mix( vec3<f32>( nodeVar175, nodeVar175, nodeVar175 ), nodeVar174, f32(1.0) );
	nodeVar177 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar176.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar176.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar176.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar176.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar176.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar176.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar176.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar176.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar176.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar173.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar177.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar177.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar178 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar178;

	// result

	output.color = nodeVar178;

	output.color = to_shelf(output.color);
	return output;

}

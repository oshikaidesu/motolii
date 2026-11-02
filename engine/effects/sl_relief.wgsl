// Relief: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)
// --label:Stylize
// --about:Embosses or debosses the image into a lit surface: silver plate, letterpress, blind emboss or gold foil.
// --check@relief:Relief,0
// --track@heightFrom:Height From,0,2,0,1
// --track@depth:Depth,0,4,1.4,0.01
// --track@bevel:Bevel,1,32,2,0.5
// --track@amount:Amount,0,1,1,0.01
// --track@lightAngle:Light Angle,0,360,135,1
// --track@elevation:Elevation,5,90,38,1
// --track@ambient:Ambient,0,1,0.35,0.01
// --check@surface:Surface,0
// --track@color_x:Color r,0,1,0.33245153633549385,0.001
// --track@color_y:Color g,0,1,0.34191442489801843,0.001
// --track@color_z:Color b,0,1,0.35640014413537763,0.001
// --track@specular:Specular,0,2,0.8,0.01
// --track@shininess:Shininess,1,128,28,1
// --track@grain:Grain,0,1,0.35,0.01
// --track@grainSize:Grain Size,0.5,8,1.2,0.05
// --track@engrave:Engrave,0,2,2,1
// --track@engraveDepth:Engrave Depth,0,2,0.5,0.01
// --track@lineSpacing:Line Spacing,2,40,5,0.5
// --track@engraveAngle:Line Angle,-180,180,0,1
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
  bevel: f32,
  heightFrom: f32,
  engraveDepth: f32,
  grain: f32,
  engrave: f32,
  engraveAngle: f32,
  lineSpacing: f32,
  grainSize: f32,
  surface: f32,
  color: vec3<f32>,
  ambient: f32,
  depth: f32,
  relief: f32,
  lightAngle: f32,
  elevation: f32,
  shininess: f32,
  specular: f32,
  amount: f32,
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
var<private> nodeVar3 : vec4<f32>;
var<private> nodeVar4 : vec2<f32>;
var<private> nodeVar5 : vec2<f32>;
var<private> nodeVar6 : vec4<f32>;
var<private> nodeVar7 : vec4<f32>;
var<private> nodeVar8 : vec4<f32>;
var<private> nodeVar9 : vec4<f32>;
var<private> nodeVar10 : vec4<f32>;
var<private> nodeVar11 : vec4<f32>;
var<private> nodeVar12 : vec4<f32>;
var<private> nodeVar13 : vec4<f32>;
var<private> nodeVar14 : f32;
var<private> nodeVar15 : f32;
var<private> nodeVar16 : f32;
var<private> nodeVar17 : f32;
var<private> nodeVar18 : f32;
var<private> nodeVar19 : f32;
var<private> nodeVar20 : f32;
var<private> nodeVar21 : f32;
var<private> nodeVar22 : f32;
var<private> nodeVar23 : f32;
var<private> nodeVar24 : f32;
var<private> nodeVar25 : f32;
var<private> nodeVar26 : f32;
var<private> nodeVar27 : f32;
var<private> nodeVar28 : f32;
var<private> nodeVar29 : vec2<f32>;
var<private> nodeVar30 : vec4<f32>;
var<private> nodeVar31 : vec3<f32>;
var<private> nodeVar32 : f32;
var<private> nodeVar33 : f32;
var<private> nodeVar34 : f32;
var<private> nodeVar35 : f32;
var<private> nodeVar36 : vec2<f32>;
var<private> nodeVar37 : f32;
var<private> nodeVar38 : vec2<f32>;
var<private> nodeVar39 : vec2<f32>;
var<private> nodeVar40 : vec3<f32>;
var<private> nodeVar41 : vec3<f32>;
var<private> nodeVar42 : vec2<f32>;
var<private> nodeVar43 : vec3<f32>;
var<private> nodeVar44 : vec3<f32>;
var<private> nodeVar45 : vec2<f32>;
var<private> nodeVar46 : vec2<f32>;
var<private> nodeVar47 : vec2<f32>;
var<private> nodeVar48 : vec3<f32>;
var<private> nodeVar49 : vec3<f32>;
var<private> nodeVar50 : vec2<f32>;
var<private> nodeVar51 : vec3<f32>;
var<private> nodeVar52 : vec3<f32>;
var<private> nodeVar53 : vec2<f32>;
var<private> nodeVar54 : f32;
var<private> nodeVar55 : f32;
var<private> nodeVar56 : f32;
var<private> nodeVar57 : vec2<f32>;
var<private> nodeVar58 : vec2<f32>;
var<private> nodeVar59 : vec3<f32>;
var<private> nodeVar60 : vec3<f32>;
var<private> nodeVar61 : vec2<f32>;
var<private> nodeVar62 : vec3<f32>;
var<private> nodeVar63 : vec3<f32>;
var<private> nodeVar64 : vec2<f32>;
var<private> nodeVar65 : vec2<f32>;
var<private> nodeVar66 : vec2<f32>;
var<private> nodeVar67 : vec3<f32>;
var<private> nodeVar68 : vec3<f32>;
var<private> nodeVar69 : vec2<f32>;
var<private> nodeVar70 : vec3<f32>;
var<private> nodeVar71 : vec3<f32>;
var<private> nodeVar72 : f32;
var<private> nodeVar73 : vec2<f32>;
var<private> nodeVar74 : vec2<f32>;
var<private> nodeVar75 : vec2<f32>;
var<private> nodeVar76 : vec3<f32>;
var<private> nodeVar77 : vec3<f32>;
var<private> nodeVar78 : vec2<f32>;
var<private> nodeVar79 : vec3<f32>;
var<private> nodeVar80 : vec3<f32>;
var<private> nodeVar81 : vec2<f32>;
var<private> nodeVar82 : vec2<f32>;
var<private> nodeVar83 : vec2<f32>;
var<private> nodeVar84 : vec3<f32>;
var<private> nodeVar85 : vec3<f32>;
var<private> nodeVar86 : vec2<f32>;
var<private> nodeVar87 : vec3<f32>;
var<private> nodeVar88 : vec3<f32>;
var<private> nodeVar89 : vec2<f32>;
var<private> nodeVar90 : vec3<f32>;
var<private> nodeVar91 : vec3<f32>;
var<private> nodeVar92 : f32;
var<private> nodeVar93 : f32;
var<private> nodeVar94 : vec2<f32>;
var<private> nodeVar95 : f32;
var<private> nodeVar96 : vec2<f32>;
var<private> nodeVar97 : vec2<f32>;
var<private> nodeVar98 : vec3<f32>;
var<private> nodeVar99 : vec3<f32>;
var<private> nodeVar100 : vec2<f32>;
var<private> nodeVar101 : vec3<f32>;
var<private> nodeVar102 : vec3<f32>;
var<private> nodeVar103 : vec2<f32>;
var<private> nodeVar104 : vec2<f32>;
var<private> nodeVar105 : vec2<f32>;
var<private> nodeVar106 : vec3<f32>;
var<private> nodeVar107 : vec3<f32>;
var<private> nodeVar108 : vec2<f32>;
var<private> nodeVar109 : vec3<f32>;
var<private> nodeVar110 : vec3<f32>;
var<private> nodeVar111 : vec2<f32>;
var<private> nodeVar112 : f32;
var<private> nodeVar113 : f32;
var<private> nodeVar114 : f32;
var<private> nodeVar115 : vec2<f32>;
var<private> nodeVar116 : vec2<f32>;
var<private> nodeVar117 : vec3<f32>;
var<private> nodeVar118 : vec3<f32>;
var<private> nodeVar119 : vec2<f32>;
var<private> nodeVar120 : vec3<f32>;
var<private> nodeVar121 : vec3<f32>;
var<private> nodeVar122 : vec2<f32>;
var<private> nodeVar123 : vec2<f32>;
var<private> nodeVar124 : vec2<f32>;
var<private> nodeVar125 : vec3<f32>;
var<private> nodeVar126 : vec3<f32>;
var<private> nodeVar127 : vec2<f32>;
var<private> nodeVar128 : vec3<f32>;
var<private> nodeVar129 : vec3<f32>;
var<private> nodeVar130 : f32;
var<private> nodeVar131 : vec2<f32>;
var<private> nodeVar132 : vec2<f32>;
var<private> nodeVar133 : vec2<f32>;
var<private> nodeVar134 : vec3<f32>;
var<private> nodeVar135 : vec3<f32>;
var<private> nodeVar136 : vec2<f32>;
var<private> nodeVar137 : vec3<f32>;
var<private> nodeVar138 : vec3<f32>;
var<private> nodeVar139 : vec2<f32>;
var<private> nodeVar140 : vec2<f32>;
var<private> nodeVar141 : vec2<f32>;
var<private> nodeVar142 : vec3<f32>;
var<private> nodeVar143 : vec3<f32>;
var<private> nodeVar144 : vec2<f32>;
var<private> nodeVar145 : vec3<f32>;
var<private> nodeVar146 : vec3<f32>;
var<private> nodeVar147 : vec2<f32>;
var<private> nodeVar148 : vec3<f32>;
var<private> nodeVar149 : vec3<f32>;
var<private> nodeVar150 : f32;
var<private> nodeVar151 : f32;
var<private> nodeVar152 : vec2<f32>;
var<private> nodeVar153 : f32;
var<private> nodeVar154 : vec2<f32>;
var<private> nodeVar155 : vec2<f32>;
var<private> nodeVar156 : vec3<f32>;
var<private> nodeVar157 : vec3<f32>;
var<private> nodeVar158 : vec2<f32>;
var<private> nodeVar159 : vec3<f32>;
var<private> nodeVar160 : vec3<f32>;
var<private> nodeVar161 : vec2<f32>;
var<private> nodeVar162 : vec2<f32>;
var<private> nodeVar163 : vec2<f32>;
var<private> nodeVar164 : vec3<f32>;
var<private> nodeVar165 : vec3<f32>;
var<private> nodeVar166 : vec2<f32>;
var<private> nodeVar167 : vec3<f32>;
var<private> nodeVar168 : vec3<f32>;
var<private> nodeVar169 : vec2<f32>;
var<private> nodeVar170 : f32;
var<private> nodeVar171 : f32;
var<private> nodeVar172 : f32;
var<private> nodeVar173 : vec2<f32>;
var<private> nodeVar174 : vec2<f32>;
var<private> nodeVar175 : vec3<f32>;
var<private> nodeVar176 : vec3<f32>;
var<private> nodeVar177 : vec2<f32>;
var<private> nodeVar178 : vec3<f32>;
var<private> nodeVar179 : vec3<f32>;
var<private> nodeVar180 : vec2<f32>;
var<private> nodeVar181 : vec2<f32>;
var<private> nodeVar182 : vec2<f32>;
var<private> nodeVar183 : vec3<f32>;
var<private> nodeVar184 : vec3<f32>;
var<private> nodeVar185 : vec2<f32>;
var<private> nodeVar186 : vec3<f32>;
var<private> nodeVar187 : vec3<f32>;
var<private> nodeVar188 : f32;
var<private> nodeVar189 : vec2<f32>;
var<private> nodeVar190 : vec2<f32>;
var<private> nodeVar191 : vec2<f32>;
var<private> nodeVar192 : vec3<f32>;
var<private> nodeVar193 : vec3<f32>;
var<private> nodeVar194 : vec2<f32>;
var<private> nodeVar195 : vec3<f32>;
var<private> nodeVar196 : vec3<f32>;
var<private> nodeVar197 : vec2<f32>;
var<private> nodeVar198 : vec2<f32>;
var<private> nodeVar199 : vec2<f32>;
var<private> nodeVar200 : vec3<f32>;
var<private> nodeVar201 : vec3<f32>;
var<private> nodeVar202 : vec2<f32>;
var<private> nodeVar203 : vec3<f32>;
var<private> nodeVar204 : vec3<f32>;
var<private> nodeVar205 : vec2<f32>;
var<private> nodeVar206 : vec3<f32>;
var<private> nodeVar207 : vec3<f32>;
var<private> nodeVar208 : f32;
var<private> nodeVar209 : f32;
var<private> nodeVar210 : vec2<f32>;
var<private> nodeVar211 : f32;
var<private> nodeVar212 : vec2<f32>;
var<private> nodeVar213 : vec2<f32>;
var<private> nodeVar214 : vec3<f32>;
var<private> nodeVar215 : vec3<f32>;
var<private> nodeVar216 : vec2<f32>;
var<private> nodeVar217 : vec3<f32>;
var<private> nodeVar218 : vec3<f32>;
var<private> nodeVar219 : vec2<f32>;
var<private> nodeVar220 : vec2<f32>;
var<private> nodeVar221 : vec2<f32>;
var<private> nodeVar222 : vec3<f32>;
var<private> nodeVar223 : vec3<f32>;
var<private> nodeVar224 : vec2<f32>;
var<private> nodeVar225 : vec3<f32>;
var<private> nodeVar226 : vec3<f32>;
var<private> nodeVar227 : vec2<f32>;
var<private> nodeVar228 : f32;
var<private> nodeVar229 : f32;
var<private> nodeVar230 : f32;
var<private> nodeVar231 : vec2<f32>;
var<private> nodeVar232 : vec2<f32>;
var<private> nodeVar233 : vec3<f32>;
var<private> nodeVar234 : vec3<f32>;
var<private> nodeVar235 : vec2<f32>;
var<private> nodeVar236 : vec3<f32>;
var<private> nodeVar237 : vec3<f32>;
var<private> nodeVar238 : vec2<f32>;
var<private> nodeVar239 : vec2<f32>;
var<private> nodeVar240 : vec2<f32>;
var<private> nodeVar241 : vec3<f32>;
var<private> nodeVar242 : vec3<f32>;
var<private> nodeVar243 : vec2<f32>;
var<private> nodeVar244 : vec3<f32>;
var<private> nodeVar245 : vec3<f32>;
var<private> nodeVar246 : f32;
var<private> nodeVar247 : vec2<f32>;
var<private> nodeVar248 : vec2<f32>;
var<private> nodeVar249 : vec2<f32>;
var<private> nodeVar250 : vec3<f32>;
var<private> nodeVar251 : vec3<f32>;
var<private> nodeVar252 : vec2<f32>;
var<private> nodeVar253 : vec3<f32>;
var<private> nodeVar254 : vec3<f32>;
var<private> nodeVar255 : vec2<f32>;
var<private> nodeVar256 : vec2<f32>;
var<private> nodeVar257 : vec2<f32>;
var<private> nodeVar258 : vec3<f32>;
var<private> nodeVar259 : vec3<f32>;
var<private> nodeVar260 : vec2<f32>;
var<private> nodeVar261 : vec3<f32>;
var<private> nodeVar262 : vec3<f32>;
var<private> nodeVar263 : vec2<f32>;
var<private> nodeVar264 : vec3<f32>;
var<private> nodeVar265 : vec3<f32>;
var<private> nodeVar266 : vec3<f32>;
var<private> nodeVar267 : f32;
var<private> nodeVar268 : vec3<f32>;
var<private> nodeVar269 : f32;
var<private> nodeVar270 : f32;
var<private> nodeVar271 : vec3<f32>;
var<private> nodeVar272 : vec3<f32>;
var<private> nodeVar273 : vec4<f32>;
var<private> nodeVar274 : vec3<f32>;
var<private> nodeVar275 : f32;
var<private> nodeVar276 : vec3<f32>;
var<private> nodeVar277 : vec4<f32>;
var<private> Output : vec4<f32>;
var<private> nodeVar278 : vec4<f32>;

// codes


@fragment
fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {
	let nodeVarying4 = vec2<f32>(door_uv.x, 1.0 - door_uv.y);

	// flow
	// code

	nodeVar0 = picture_read( vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) ) );
	nodeVar1 = vec2<f32>( nodeVarying4.x, ( 1.0 - nodeVarying4.y ) );
	nodeVar2 = picture_read( nodeVar1 );
	nodeVar3 = nodeVar2;
	nodeVar4 = vec2<f32>( knobs.resolution.x, knobs.resolution.y );
	nodeVar5 = ( vec2<f32>( ( 1.0 / nodeVar4.x ), ( 1.0 / nodeVar4.y ) ) * vec2<f32>( knobs.bevel ) );
	nodeVar6 = picture_read( ( nodeVar1 + vec2<f32>( nodeVar5.x, 0.0 ) ) );
	nodeVar7 = nodeVar6;
	nodeVar8 = picture_read( ( nodeVar1 - vec2<f32>( nodeVar5.x, 0.0 ) ) );
	nodeVar9 = nodeVar8;
	nodeVar10 = picture_read( ( nodeVar1 + vec2<f32>( 0.0, nodeVar5.y ) ) );
	nodeVar11 = nodeVar10;
	nodeVar12 = picture_read( ( nodeVar1 - vec2<f32>( 0.0, nodeVar5.y ) ) );
	nodeVar13 = nodeVar12;
	nodeVar14 = nodeVar3.w;
	nodeVar15 = nodeVar7.w;
	nodeVar16 = nodeVar9.w;
	nodeVar17 = nodeVar11.w;
	nodeVar18 = nodeVar13.w;

	if ( ( knobs.heightFrom < 0.5 ) ) {

		nodeVar20 = clamp( dot( vec3<f32>( nodeVar3.x, nodeVar3.y, nodeVar3.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar20 <= 0.0031308 ) ) {

			nodeVar19 = ( nodeVar20 * 12.92 );

		} else {

			nodeVar19 = ( ( pow( nodeVar20, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar14 = nodeVar19;
		nodeVar22 = clamp( dot( vec3<f32>( nodeVar7.x, nodeVar7.y, nodeVar7.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar22 <= 0.0031308 ) ) {

			nodeVar21 = ( nodeVar22 * 12.92 );

		} else {

			nodeVar21 = ( ( pow( nodeVar22, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar15 = nodeVar21;
		nodeVar24 = clamp( dot( vec3<f32>( nodeVar9.x, nodeVar9.y, nodeVar9.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar24 <= 0.0031308 ) ) {

			nodeVar23 = ( nodeVar24 * 12.92 );

		} else {

			nodeVar23 = ( ( pow( nodeVar24, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar16 = nodeVar23;
		nodeVar26 = clamp( dot( vec3<f32>( nodeVar11.x, nodeVar11.y, nodeVar11.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar26 <= 0.0031308 ) ) {

			nodeVar25 = ( nodeVar26 * 12.92 );

		} else {

			nodeVar25 = ( ( pow( nodeVar26, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar17 = nodeVar25;
		nodeVar28 = clamp( dot( vec3<f32>( nodeVar13.x, nodeVar13.y, nodeVar13.z ), vec3<f32>( 0.2126, 0.7152, 0.0722 ) ), 0.0, 1.0 );

		if ( ( nodeVar28 <= 0.0031308 ) ) {

			nodeVar27 = ( nodeVar28 * 12.92 );

		} else {

			nodeVar27 = ( ( pow( nodeVar28, 0.4166666666666667 ) * 1.055 ) - 0.055 );

		}

		nodeVar18 = nodeVar27;
		

	} else {


		if ( ( knobs.heightFrom < 1.5 ) ) {

			nodeVar14 = nodeVar3.x;
			nodeVar15 = nodeVar7.x;
			nodeVar16 = nodeVar9.x;
			nodeVar17 = nodeVar11.x;
			nodeVar18 = nodeVar13.x;
			

		}

		

	}

	nodeVar29 = ( nodeVar1 * nodeVar4 );
	nodeVar30 = picture_read( nodeVar1 );
	nodeVar31 = vec3<f32>( nodeVar30.x, nodeVar30.y, nodeVar30.z );
	nodeVar32 = 0.0;
	nodeVar33 = 0.0;

	if ( ( ( knobs.engraveDepth > 0.0 ) || ( knobs.grain > 0.0 ) ) ) {


		if ( ( knobs.engrave < 0.5 ) ) {

			nodeVar34 = 0.0;

		} else {


			if ( ( knobs.engrave < 1.5 ) ) {

				nodeVar36 = ( nodeVar29 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar37 = ( knobs.engraveAngle * 0.017453292519943295 );
				nodeVar38 = vec2<f32>( ( ( ( nodeVar36.y * cos( nodeVar37 ) ) - ( nodeVar36.x * sin( nodeVar37 ) ) ) / ( knobs.lineSpacing * 9.0 ) ), 3.1 );
				nodeVar39 = floor( nodeVar38 );
				nodeVar40 = fract( ( vec3<f32>( nodeVar39.x, nodeVar39.y, nodeVar39.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar41 = ( nodeVar40 + vec3<f32>( dot( nodeVar40, ( vec3<f32>( nodeVar40.y, nodeVar40.z, nodeVar40.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar42 = ( nodeVar39 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar43 = fract( ( vec3<f32>( nodeVar42.x, nodeVar42.y, nodeVar42.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar44 = ( nodeVar43 + vec3<f32>( dot( nodeVar43, ( vec3<f32>( nodeVar43.y, nodeVar43.z, nodeVar43.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar45 = fract( nodeVar38 );
				nodeVar46 = ( ( nodeVar45 * nodeVar45 ) * ( vec2<f32>( 3.0 ) - ( nodeVar45 * vec2<f32>( 2.0 ) ) ) );
				nodeVar47 = ( nodeVar39 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar48 = fract( ( vec3<f32>( nodeVar47.x, nodeVar47.y, nodeVar47.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar49 = ( nodeVar48 + vec3<f32>( dot( nodeVar48, ( vec3<f32>( nodeVar48.y, nodeVar48.z, nodeVar48.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar50 = ( nodeVar39 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar51 = fract( ( vec3<f32>( nodeVar50.x, nodeVar50.y, nodeVar50.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar52 = ( nodeVar51 + vec3<f32>( dot( nodeVar51, ( vec3<f32>( nodeVar51.y, nodeVar51.z, nodeVar51.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar35 = cos( ( ( ( ( ( nodeVar36.x * cos( nodeVar37 ) ) + ( nodeVar36.y * sin( nodeVar37 ) ) ) + ( ( mix( mix( fract( ( ( nodeVar41.x + nodeVar41.y ) * nodeVar41.z ) ), fract( ( ( nodeVar44.x + nodeVar44.y ) * nodeVar44.z ) ), nodeVar46.x ), mix( fract( ( ( nodeVar49.x + nodeVar49.y ) * nodeVar49.z ) ), fract( ( ( nodeVar52.x + nodeVar52.y ) * nodeVar52.z ) ), nodeVar46.x ), nodeVar46.y ) - 0.5 ) * ( knobs.lineSpacing * 0.8 ) ) ) / knobs.lineSpacing ) * 6.283185307179586 ) );

			} else {

				nodeVar53 = ( ( nodeVar29 + vec2<f32>( 1.0, 0.0 ) ) - ( nodeVar4 * vec2<f32>( 0.5 ) ) );
				nodeVar54 = atan2( nodeVar53.y, nodeVar53.x );
				nodeVar55 = ( ( min( nodeVar4.x, nodeVar4.y ) * 1.5707963267948966 ) / knobs.lineSpacing );
				nodeVar56 = length( nodeVar53 );
				nodeVar57 = vec2<f32>( ( ( nodeVar54 * nodeVar55 ) / 6.2831853 ), ( nodeVar56 / ( knobs.lineSpacing * 14.0 ) ) );
				nodeVar58 = floor( nodeVar57 );
				nodeVar59 = fract( ( vec3<f32>( nodeVar58.x, nodeVar58.y, nodeVar58.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar60 = ( nodeVar59 + vec3<f32>( dot( nodeVar59, ( vec3<f32>( nodeVar59.y, nodeVar59.z, nodeVar59.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar61 = ( nodeVar58 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar62 = fract( ( vec3<f32>( nodeVar61.x, nodeVar61.y, nodeVar61.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar63 = ( nodeVar62 + vec3<f32>( dot( nodeVar62, ( vec3<f32>( nodeVar62.y, nodeVar62.z, nodeVar62.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar64 = fract( nodeVar57 );
				nodeVar65 = ( ( nodeVar64 * nodeVar64 ) * ( vec2<f32>( 3.0 ) - ( nodeVar64 * vec2<f32>( 2.0 ) ) ) );
				nodeVar66 = ( nodeVar58 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar67 = fract( ( vec3<f32>( nodeVar66.x, nodeVar66.y, nodeVar66.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar68 = ( nodeVar67 + vec3<f32>( dot( nodeVar67, ( vec3<f32>( nodeVar67.y, nodeVar67.z, nodeVar67.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar69 = ( nodeVar58 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar70 = fract( ( vec3<f32>( nodeVar69.x, nodeVar69.y, nodeVar69.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar71 = ( nodeVar70 + vec3<f32>( dot( nodeVar70, ( vec3<f32>( nodeVar70.y, nodeVar70.z, nodeVar70.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar72 = min( nodeVar4.x, nodeVar4.y );
				nodeVar35 = ( cos( ( ( nodeVar54 * nodeVar55 ) + ( ( mix( mix( fract( ( ( nodeVar60.x + nodeVar60.y ) * nodeVar60.z ) ), fract( ( ( nodeVar63.x + nodeVar63.y ) * nodeVar63.z ) ), nodeVar65.x ), mix( fract( ( ( nodeVar68.x + nodeVar68.y ) * nodeVar68.z ) ), fract( ( ( nodeVar71.x + nodeVar71.y ) * nodeVar71.z ) ), nodeVar65.x ), nodeVar65.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( nodeVar72 * 0.06 ), ( nodeVar72 * 0.22 ), nodeVar56 ) );

			}

			nodeVar34 = nodeVar35;

		}

		nodeVar73 = ( nodeVar29 + vec2<f32>( 1.0, 0.0 ) );
		nodeVar74 = ( nodeVar73 / vec2<f32>( knobs.grainSize ) );
		nodeVar75 = floor( nodeVar74 );
		nodeVar76 = fract( ( vec3<f32>( nodeVar75.x, nodeVar75.y, nodeVar75.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar77 = ( nodeVar76 + vec3<f32>( dot( nodeVar76, ( vec3<f32>( nodeVar76.y, nodeVar76.z, nodeVar76.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar78 = ( nodeVar75 + vec2<f32>( 1.0, 0.0 ) );
		nodeVar79 = fract( ( vec3<f32>( nodeVar78.x, nodeVar78.y, nodeVar78.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar80 = ( nodeVar79 + vec3<f32>( dot( nodeVar79, ( vec3<f32>( nodeVar79.y, nodeVar79.z, nodeVar79.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar81 = fract( nodeVar74 );
		nodeVar82 = ( ( nodeVar81 * nodeVar81 ) * ( vec2<f32>( 3.0 ) - ( nodeVar81 * vec2<f32>( 2.0 ) ) ) );
		nodeVar83 = ( nodeVar75 + vec2<f32>( 0.0, 1.0 ) );
		nodeVar84 = fract( ( vec3<f32>( nodeVar83.x, nodeVar83.y, nodeVar83.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar85 = ( nodeVar84 + vec3<f32>( dot( nodeVar84, ( vec3<f32>( nodeVar84.y, nodeVar84.z, nodeVar84.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar86 = ( nodeVar75 + vec2<f32>( 1.0, 1.0 ) );
		nodeVar87 = fract( ( vec3<f32>( nodeVar86.x, nodeVar86.y, nodeVar86.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar88 = ( nodeVar87 + vec3<f32>( dot( nodeVar87, ( vec3<f32>( nodeVar87.y, nodeVar87.z, nodeVar87.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar89 = floor( ( ( nodeVar73 / vec2<f32>( knobs.grainSize ) ) * vec2<f32>( 2.1 ) ) );
		nodeVar90 = fract( ( vec3<f32>( nodeVar89.x, nodeVar89.y, nodeVar89.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar91 = ( nodeVar90 + vec3<f32>( dot( nodeVar90, ( vec3<f32>( nodeVar90.y, nodeVar90.z, nodeVar90.x ) + vec3<f32>( 33.33 ) ) ) ) );

		if ( ( knobs.engrave < 0.5 ) ) {

			nodeVar92 = 0.0;

		} else {


			if ( ( knobs.engrave < 1.5 ) ) {

				nodeVar94 = ( nodeVar29 - vec2<f32>( 1.0, 0.0 ) );
				nodeVar95 = ( knobs.engraveAngle * 0.017453292519943295 );
				nodeVar96 = vec2<f32>( ( ( ( nodeVar94.y * cos( nodeVar95 ) ) - ( nodeVar94.x * sin( nodeVar95 ) ) ) / ( knobs.lineSpacing * 9.0 ) ), 3.1 );
				nodeVar97 = floor( nodeVar96 );
				nodeVar98 = fract( ( vec3<f32>( nodeVar97.x, nodeVar97.y, nodeVar97.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar99 = ( nodeVar98 + vec3<f32>( dot( nodeVar98, ( vec3<f32>( nodeVar98.y, nodeVar98.z, nodeVar98.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar100 = ( nodeVar97 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar101 = fract( ( vec3<f32>( nodeVar100.x, nodeVar100.y, nodeVar100.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar102 = ( nodeVar101 + vec3<f32>( dot( nodeVar101, ( vec3<f32>( nodeVar101.y, nodeVar101.z, nodeVar101.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar103 = fract( nodeVar96 );
				nodeVar104 = ( ( nodeVar103 * nodeVar103 ) * ( vec2<f32>( 3.0 ) - ( nodeVar103 * vec2<f32>( 2.0 ) ) ) );
				nodeVar105 = ( nodeVar97 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar106 = fract( ( vec3<f32>( nodeVar105.x, nodeVar105.y, nodeVar105.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar107 = ( nodeVar106 + vec3<f32>( dot( nodeVar106, ( vec3<f32>( nodeVar106.y, nodeVar106.z, nodeVar106.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar108 = ( nodeVar97 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar109 = fract( ( vec3<f32>( nodeVar108.x, nodeVar108.y, nodeVar108.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar110 = ( nodeVar109 + vec3<f32>( dot( nodeVar109, ( vec3<f32>( nodeVar109.y, nodeVar109.z, nodeVar109.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar93 = cos( ( ( ( ( ( nodeVar94.x * cos( nodeVar95 ) ) + ( nodeVar94.y * sin( nodeVar95 ) ) ) + ( ( mix( mix( fract( ( ( nodeVar99.x + nodeVar99.y ) * nodeVar99.z ) ), fract( ( ( nodeVar102.x + nodeVar102.y ) * nodeVar102.z ) ), nodeVar104.x ), mix( fract( ( ( nodeVar107.x + nodeVar107.y ) * nodeVar107.z ) ), fract( ( ( nodeVar110.x + nodeVar110.y ) * nodeVar110.z ) ), nodeVar104.x ), nodeVar104.y ) - 0.5 ) * ( knobs.lineSpacing * 0.8 ) ) ) / knobs.lineSpacing ) * 6.283185307179586 ) );

			} else {

				nodeVar111 = ( ( nodeVar29 - vec2<f32>( 1.0, 0.0 ) ) - ( nodeVar4 * vec2<f32>( 0.5 ) ) );
				nodeVar112 = atan2( nodeVar111.y, nodeVar111.x );
				nodeVar113 = ( ( min( nodeVar4.x, nodeVar4.y ) * 1.5707963267948966 ) / knobs.lineSpacing );
				nodeVar114 = length( nodeVar111 );
				nodeVar115 = vec2<f32>( ( ( nodeVar112 * nodeVar113 ) / 6.2831853 ), ( nodeVar114 / ( knobs.lineSpacing * 14.0 ) ) );
				nodeVar116 = floor( nodeVar115 );
				nodeVar117 = fract( ( vec3<f32>( nodeVar116.x, nodeVar116.y, nodeVar116.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar118 = ( nodeVar117 + vec3<f32>( dot( nodeVar117, ( vec3<f32>( nodeVar117.y, nodeVar117.z, nodeVar117.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar119 = ( nodeVar116 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar120 = fract( ( vec3<f32>( nodeVar119.x, nodeVar119.y, nodeVar119.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar121 = ( nodeVar120 + vec3<f32>( dot( nodeVar120, ( vec3<f32>( nodeVar120.y, nodeVar120.z, nodeVar120.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar122 = fract( nodeVar115 );
				nodeVar123 = ( ( nodeVar122 * nodeVar122 ) * ( vec2<f32>( 3.0 ) - ( nodeVar122 * vec2<f32>( 2.0 ) ) ) );
				nodeVar124 = ( nodeVar116 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar125 = fract( ( vec3<f32>( nodeVar124.x, nodeVar124.y, nodeVar124.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar126 = ( nodeVar125 + vec3<f32>( dot( nodeVar125, ( vec3<f32>( nodeVar125.y, nodeVar125.z, nodeVar125.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar127 = ( nodeVar116 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar128 = fract( ( vec3<f32>( nodeVar127.x, nodeVar127.y, nodeVar127.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar129 = ( nodeVar128 + vec3<f32>( dot( nodeVar128, ( vec3<f32>( nodeVar128.y, nodeVar128.z, nodeVar128.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar130 = min( nodeVar4.x, nodeVar4.y );
				nodeVar93 = ( cos( ( ( nodeVar112 * nodeVar113 ) + ( ( mix( mix( fract( ( ( nodeVar118.x + nodeVar118.y ) * nodeVar118.z ) ), fract( ( ( nodeVar121.x + nodeVar121.y ) * nodeVar121.z ) ), nodeVar123.x ), mix( fract( ( ( nodeVar126.x + nodeVar126.y ) * nodeVar126.z ) ), fract( ( ( nodeVar129.x + nodeVar129.y ) * nodeVar129.z ) ), nodeVar123.x ), nodeVar123.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( nodeVar130 * 0.06 ), ( nodeVar130 * 0.22 ), nodeVar114 ) );

			}

			nodeVar92 = nodeVar93;

		}

		nodeVar131 = ( nodeVar29 - vec2<f32>( 1.0, 0.0 ) );
		nodeVar132 = ( nodeVar131 / vec2<f32>( knobs.grainSize ) );
		nodeVar133 = floor( nodeVar132 );
		nodeVar134 = fract( ( vec3<f32>( nodeVar133.x, nodeVar133.y, nodeVar133.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar135 = ( nodeVar134 + vec3<f32>( dot( nodeVar134, ( vec3<f32>( nodeVar134.y, nodeVar134.z, nodeVar134.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar136 = ( nodeVar133 + vec2<f32>( 1.0, 0.0 ) );
		nodeVar137 = fract( ( vec3<f32>( nodeVar136.x, nodeVar136.y, nodeVar136.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar138 = ( nodeVar137 + vec3<f32>( dot( nodeVar137, ( vec3<f32>( nodeVar137.y, nodeVar137.z, nodeVar137.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar139 = fract( nodeVar132 );
		nodeVar140 = ( ( nodeVar139 * nodeVar139 ) * ( vec2<f32>( 3.0 ) - ( nodeVar139 * vec2<f32>( 2.0 ) ) ) );
		nodeVar141 = ( nodeVar133 + vec2<f32>( 0.0, 1.0 ) );
		nodeVar142 = fract( ( vec3<f32>( nodeVar141.x, nodeVar141.y, nodeVar141.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar143 = ( nodeVar142 + vec3<f32>( dot( nodeVar142, ( vec3<f32>( nodeVar142.y, nodeVar142.z, nodeVar142.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar144 = ( nodeVar133 + vec2<f32>( 1.0, 1.0 ) );
		nodeVar145 = fract( ( vec3<f32>( nodeVar144.x, nodeVar144.y, nodeVar144.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar146 = ( nodeVar145 + vec3<f32>( dot( nodeVar145, ( vec3<f32>( nodeVar145.y, nodeVar145.z, nodeVar145.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar147 = floor( ( ( nodeVar131 / vec2<f32>( knobs.grainSize ) ) * vec2<f32>( 2.1 ) ) );
		nodeVar148 = fract( ( vec3<f32>( nodeVar147.x, nodeVar147.y, nodeVar147.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar149 = ( nodeVar148 + vec3<f32>( dot( nodeVar148, ( vec3<f32>( nodeVar148.y, nodeVar148.z, nodeVar148.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar32 = ( ( ( ( ( nodeVar34 * 0.5 ) * knobs.engraveDepth ) * ( 0.35 + ( ( 1.0 - nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( nodeVar77.x + nodeVar77.y ) * nodeVar77.z ) ), fract( ( ( nodeVar80.x + nodeVar80.y ) * nodeVar80.z ) ), nodeVar82.x ), mix( fract( ( ( nodeVar85.x + nodeVar85.y ) * nodeVar85.z ) ), fract( ( ( nodeVar88.x + nodeVar88.y ) * nodeVar88.z ) ), nodeVar82.x ), nodeVar82.y ) * 0.6 ) + ( fract( ( ( nodeVar91.x + nodeVar91.y ) * nodeVar91.z ) ) * 0.4 ) ) - 0.5 ) * knobs.grain ) ) - ( ( ( ( nodeVar92 * 0.5 ) * knobs.engraveDepth ) * ( 0.35 + ( ( 1.0 - nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( nodeVar135.x + nodeVar135.y ) * nodeVar135.z ) ), fract( ( ( nodeVar138.x + nodeVar138.y ) * nodeVar138.z ) ), nodeVar140.x ), mix( fract( ( ( nodeVar143.x + nodeVar143.y ) * nodeVar143.z ) ), fract( ( ( nodeVar146.x + nodeVar146.y ) * nodeVar146.z ) ), nodeVar140.x ), nodeVar140.y ) * 0.6 ) + ( fract( ( ( nodeVar149.x + nodeVar149.y ) * nodeVar149.z ) ) * 0.4 ) ) - 0.5 ) * knobs.grain ) ) );

		if ( ( knobs.engrave < 0.5 ) ) {

			nodeVar150 = 0.0;

		} else {


			if ( ( knobs.engrave < 1.5 ) ) {

				nodeVar152 = ( nodeVar29 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar153 = ( knobs.engraveAngle * 0.017453292519943295 );
				nodeVar154 = vec2<f32>( ( ( ( nodeVar152.y * cos( nodeVar153 ) ) - ( nodeVar152.x * sin( nodeVar153 ) ) ) / ( knobs.lineSpacing * 9.0 ) ), 3.1 );
				nodeVar155 = floor( nodeVar154 );
				nodeVar156 = fract( ( vec3<f32>( nodeVar155.x, nodeVar155.y, nodeVar155.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar157 = ( nodeVar156 + vec3<f32>( dot( nodeVar156, ( vec3<f32>( nodeVar156.y, nodeVar156.z, nodeVar156.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar158 = ( nodeVar155 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar159 = fract( ( vec3<f32>( nodeVar158.x, nodeVar158.y, nodeVar158.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar160 = ( nodeVar159 + vec3<f32>( dot( nodeVar159, ( vec3<f32>( nodeVar159.y, nodeVar159.z, nodeVar159.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar161 = fract( nodeVar154 );
				nodeVar162 = ( ( nodeVar161 * nodeVar161 ) * ( vec2<f32>( 3.0 ) - ( nodeVar161 * vec2<f32>( 2.0 ) ) ) );
				nodeVar163 = ( nodeVar155 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar164 = fract( ( vec3<f32>( nodeVar163.x, nodeVar163.y, nodeVar163.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar165 = ( nodeVar164 + vec3<f32>( dot( nodeVar164, ( vec3<f32>( nodeVar164.y, nodeVar164.z, nodeVar164.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar166 = ( nodeVar155 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar167 = fract( ( vec3<f32>( nodeVar166.x, nodeVar166.y, nodeVar166.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar168 = ( nodeVar167 + vec3<f32>( dot( nodeVar167, ( vec3<f32>( nodeVar167.y, nodeVar167.z, nodeVar167.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar151 = cos( ( ( ( ( ( nodeVar152.x * cos( nodeVar153 ) ) + ( nodeVar152.y * sin( nodeVar153 ) ) ) + ( ( mix( mix( fract( ( ( nodeVar157.x + nodeVar157.y ) * nodeVar157.z ) ), fract( ( ( nodeVar160.x + nodeVar160.y ) * nodeVar160.z ) ), nodeVar162.x ), mix( fract( ( ( nodeVar165.x + nodeVar165.y ) * nodeVar165.z ) ), fract( ( ( nodeVar168.x + nodeVar168.y ) * nodeVar168.z ) ), nodeVar162.x ), nodeVar162.y ) - 0.5 ) * ( knobs.lineSpacing * 0.8 ) ) ) / knobs.lineSpacing ) * 6.283185307179586 ) );

			} else {

				nodeVar169 = ( ( nodeVar29 + vec2<f32>( 0.0, 1.0 ) ) - ( nodeVar4 * vec2<f32>( 0.5 ) ) );
				nodeVar170 = atan2( nodeVar169.y, nodeVar169.x );
				nodeVar171 = ( ( min( nodeVar4.x, nodeVar4.y ) * 1.5707963267948966 ) / knobs.lineSpacing );
				nodeVar172 = length( nodeVar169 );
				nodeVar173 = vec2<f32>( ( ( nodeVar170 * nodeVar171 ) / 6.2831853 ), ( nodeVar172 / ( knobs.lineSpacing * 14.0 ) ) );
				nodeVar174 = floor( nodeVar173 );
				nodeVar175 = fract( ( vec3<f32>( nodeVar174.x, nodeVar174.y, nodeVar174.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar176 = ( nodeVar175 + vec3<f32>( dot( nodeVar175, ( vec3<f32>( nodeVar175.y, nodeVar175.z, nodeVar175.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar177 = ( nodeVar174 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar178 = fract( ( vec3<f32>( nodeVar177.x, nodeVar177.y, nodeVar177.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar179 = ( nodeVar178 + vec3<f32>( dot( nodeVar178, ( vec3<f32>( nodeVar178.y, nodeVar178.z, nodeVar178.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar180 = fract( nodeVar173 );
				nodeVar181 = ( ( nodeVar180 * nodeVar180 ) * ( vec2<f32>( 3.0 ) - ( nodeVar180 * vec2<f32>( 2.0 ) ) ) );
				nodeVar182 = ( nodeVar174 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar183 = fract( ( vec3<f32>( nodeVar182.x, nodeVar182.y, nodeVar182.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar184 = ( nodeVar183 + vec3<f32>( dot( nodeVar183, ( vec3<f32>( nodeVar183.y, nodeVar183.z, nodeVar183.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar185 = ( nodeVar174 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar186 = fract( ( vec3<f32>( nodeVar185.x, nodeVar185.y, nodeVar185.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar187 = ( nodeVar186 + vec3<f32>( dot( nodeVar186, ( vec3<f32>( nodeVar186.y, nodeVar186.z, nodeVar186.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar188 = min( nodeVar4.x, nodeVar4.y );
				nodeVar151 = ( cos( ( ( nodeVar170 * nodeVar171 ) + ( ( mix( mix( fract( ( ( nodeVar176.x + nodeVar176.y ) * nodeVar176.z ) ), fract( ( ( nodeVar179.x + nodeVar179.y ) * nodeVar179.z ) ), nodeVar181.x ), mix( fract( ( ( nodeVar184.x + nodeVar184.y ) * nodeVar184.z ) ), fract( ( ( nodeVar187.x + nodeVar187.y ) * nodeVar187.z ) ), nodeVar181.x ), nodeVar181.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( nodeVar188 * 0.06 ), ( nodeVar188 * 0.22 ), nodeVar172 ) );

			}

			nodeVar150 = nodeVar151;

		}

		nodeVar189 = ( nodeVar29 + vec2<f32>( 0.0, 1.0 ) );
		nodeVar190 = ( nodeVar189 / vec2<f32>( knobs.grainSize ) );
		nodeVar191 = floor( nodeVar190 );
		nodeVar192 = fract( ( vec3<f32>( nodeVar191.x, nodeVar191.y, nodeVar191.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar193 = ( nodeVar192 + vec3<f32>( dot( nodeVar192, ( vec3<f32>( nodeVar192.y, nodeVar192.z, nodeVar192.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar194 = ( nodeVar191 + vec2<f32>( 1.0, 0.0 ) );
		nodeVar195 = fract( ( vec3<f32>( nodeVar194.x, nodeVar194.y, nodeVar194.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar196 = ( nodeVar195 + vec3<f32>( dot( nodeVar195, ( vec3<f32>( nodeVar195.y, nodeVar195.z, nodeVar195.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar197 = fract( nodeVar190 );
		nodeVar198 = ( ( nodeVar197 * nodeVar197 ) * ( vec2<f32>( 3.0 ) - ( nodeVar197 * vec2<f32>( 2.0 ) ) ) );
		nodeVar199 = ( nodeVar191 + vec2<f32>( 0.0, 1.0 ) );
		nodeVar200 = fract( ( vec3<f32>( nodeVar199.x, nodeVar199.y, nodeVar199.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar201 = ( nodeVar200 + vec3<f32>( dot( nodeVar200, ( vec3<f32>( nodeVar200.y, nodeVar200.z, nodeVar200.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar202 = ( nodeVar191 + vec2<f32>( 1.0, 1.0 ) );
		nodeVar203 = fract( ( vec3<f32>( nodeVar202.x, nodeVar202.y, nodeVar202.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar204 = ( nodeVar203 + vec3<f32>( dot( nodeVar203, ( vec3<f32>( nodeVar203.y, nodeVar203.z, nodeVar203.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar205 = floor( ( ( nodeVar189 / vec2<f32>( knobs.grainSize ) ) * vec2<f32>( 2.1 ) ) );
		nodeVar206 = fract( ( vec3<f32>( nodeVar205.x, nodeVar205.y, nodeVar205.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar207 = ( nodeVar206 + vec3<f32>( dot( nodeVar206, ( vec3<f32>( nodeVar206.y, nodeVar206.z, nodeVar206.x ) + vec3<f32>( 33.33 ) ) ) ) );

		if ( ( knobs.engrave < 0.5 ) ) {

			nodeVar208 = 0.0;

		} else {


			if ( ( knobs.engrave < 1.5 ) ) {

				nodeVar210 = ( nodeVar29 - vec2<f32>( 0.0, 1.0 ) );
				nodeVar211 = ( knobs.engraveAngle * 0.017453292519943295 );
				nodeVar212 = vec2<f32>( ( ( ( nodeVar210.y * cos( nodeVar211 ) ) - ( nodeVar210.x * sin( nodeVar211 ) ) ) / ( knobs.lineSpacing * 9.0 ) ), 3.1 );
				nodeVar213 = floor( nodeVar212 );
				nodeVar214 = fract( ( vec3<f32>( nodeVar213.x, nodeVar213.y, nodeVar213.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar215 = ( nodeVar214 + vec3<f32>( dot( nodeVar214, ( vec3<f32>( nodeVar214.y, nodeVar214.z, nodeVar214.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar216 = ( nodeVar213 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar217 = fract( ( vec3<f32>( nodeVar216.x, nodeVar216.y, nodeVar216.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar218 = ( nodeVar217 + vec3<f32>( dot( nodeVar217, ( vec3<f32>( nodeVar217.y, nodeVar217.z, nodeVar217.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar219 = fract( nodeVar212 );
				nodeVar220 = ( ( nodeVar219 * nodeVar219 ) * ( vec2<f32>( 3.0 ) - ( nodeVar219 * vec2<f32>( 2.0 ) ) ) );
				nodeVar221 = ( nodeVar213 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar222 = fract( ( vec3<f32>( nodeVar221.x, nodeVar221.y, nodeVar221.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar223 = ( nodeVar222 + vec3<f32>( dot( nodeVar222, ( vec3<f32>( nodeVar222.y, nodeVar222.z, nodeVar222.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar224 = ( nodeVar213 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar225 = fract( ( vec3<f32>( nodeVar224.x, nodeVar224.y, nodeVar224.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar226 = ( nodeVar225 + vec3<f32>( dot( nodeVar225, ( vec3<f32>( nodeVar225.y, nodeVar225.z, nodeVar225.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar209 = cos( ( ( ( ( ( nodeVar210.x * cos( nodeVar211 ) ) + ( nodeVar210.y * sin( nodeVar211 ) ) ) + ( ( mix( mix( fract( ( ( nodeVar215.x + nodeVar215.y ) * nodeVar215.z ) ), fract( ( ( nodeVar218.x + nodeVar218.y ) * nodeVar218.z ) ), nodeVar220.x ), mix( fract( ( ( nodeVar223.x + nodeVar223.y ) * nodeVar223.z ) ), fract( ( ( nodeVar226.x + nodeVar226.y ) * nodeVar226.z ) ), nodeVar220.x ), nodeVar220.y ) - 0.5 ) * ( knobs.lineSpacing * 0.8 ) ) ) / knobs.lineSpacing ) * 6.283185307179586 ) );

			} else {

				nodeVar227 = ( ( nodeVar29 - vec2<f32>( 0.0, 1.0 ) ) - ( nodeVar4 * vec2<f32>( 0.5 ) ) );
				nodeVar228 = atan2( nodeVar227.y, nodeVar227.x );
				nodeVar229 = ( ( min( nodeVar4.x, nodeVar4.y ) * 1.5707963267948966 ) / knobs.lineSpacing );
				nodeVar230 = length( nodeVar227 );
				nodeVar231 = vec2<f32>( ( ( nodeVar228 * nodeVar229 ) / 6.2831853 ), ( nodeVar230 / ( knobs.lineSpacing * 14.0 ) ) );
				nodeVar232 = floor( nodeVar231 );
				nodeVar233 = fract( ( vec3<f32>( nodeVar232.x, nodeVar232.y, nodeVar232.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar234 = ( nodeVar233 + vec3<f32>( dot( nodeVar233, ( vec3<f32>( nodeVar233.y, nodeVar233.z, nodeVar233.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar235 = ( nodeVar232 + vec2<f32>( 1.0, 0.0 ) );
				nodeVar236 = fract( ( vec3<f32>( nodeVar235.x, nodeVar235.y, nodeVar235.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar237 = ( nodeVar236 + vec3<f32>( dot( nodeVar236, ( vec3<f32>( nodeVar236.y, nodeVar236.z, nodeVar236.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar238 = fract( nodeVar231 );
				nodeVar239 = ( ( nodeVar238 * nodeVar238 ) * ( vec2<f32>( 3.0 ) - ( nodeVar238 * vec2<f32>( 2.0 ) ) ) );
				nodeVar240 = ( nodeVar232 + vec2<f32>( 0.0, 1.0 ) );
				nodeVar241 = fract( ( vec3<f32>( nodeVar240.x, nodeVar240.y, nodeVar240.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar242 = ( nodeVar241 + vec3<f32>( dot( nodeVar241, ( vec3<f32>( nodeVar241.y, nodeVar241.z, nodeVar241.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar243 = ( nodeVar232 + vec2<f32>( 1.0, 1.0 ) );
				nodeVar244 = fract( ( vec3<f32>( nodeVar243.x, nodeVar243.y, nodeVar243.x ) * vec3<f32>( 0.1031 ) ) );
				nodeVar245 = ( nodeVar244 + vec3<f32>( dot( nodeVar244, ( vec3<f32>( nodeVar244.y, nodeVar244.z, nodeVar244.x ) + vec3<f32>( 33.33 ) ) ) ) );
				nodeVar246 = min( nodeVar4.x, nodeVar4.y );
				nodeVar209 = ( cos( ( ( nodeVar228 * nodeVar229 ) + ( ( mix( mix( fract( ( ( nodeVar234.x + nodeVar234.y ) * nodeVar234.z ) ), fract( ( ( nodeVar237.x + nodeVar237.y ) * nodeVar237.z ) ), nodeVar239.x ), mix( fract( ( ( nodeVar242.x + nodeVar242.y ) * nodeVar242.z ) ), fract( ( ( nodeVar245.x + nodeVar245.y ) * nodeVar245.z ) ), nodeVar239.x ), nodeVar239.y ) - 0.5 ) * 1.4 ) ) ) * smoothstep( ( nodeVar246 * 0.06 ), ( nodeVar246 * 0.22 ), nodeVar230 ) );

			}

			nodeVar208 = nodeVar209;

		}

		nodeVar247 = ( nodeVar29 - vec2<f32>( 0.0, 1.0 ) );
		nodeVar248 = ( nodeVar247 / vec2<f32>( knobs.grainSize ) );
		nodeVar249 = floor( nodeVar248 );
		nodeVar250 = fract( ( vec3<f32>( nodeVar249.x, nodeVar249.y, nodeVar249.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar251 = ( nodeVar250 + vec3<f32>( dot( nodeVar250, ( vec3<f32>( nodeVar250.y, nodeVar250.z, nodeVar250.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar252 = ( nodeVar249 + vec2<f32>( 1.0, 0.0 ) );
		nodeVar253 = fract( ( vec3<f32>( nodeVar252.x, nodeVar252.y, nodeVar252.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar254 = ( nodeVar253 + vec3<f32>( dot( nodeVar253, ( vec3<f32>( nodeVar253.y, nodeVar253.z, nodeVar253.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar255 = fract( nodeVar248 );
		nodeVar256 = ( ( nodeVar255 * nodeVar255 ) * ( vec2<f32>( 3.0 ) - ( nodeVar255 * vec2<f32>( 2.0 ) ) ) );
		nodeVar257 = ( nodeVar249 + vec2<f32>( 0.0, 1.0 ) );
		nodeVar258 = fract( ( vec3<f32>( nodeVar257.x, nodeVar257.y, nodeVar257.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar259 = ( nodeVar258 + vec3<f32>( dot( nodeVar258, ( vec3<f32>( nodeVar258.y, nodeVar258.z, nodeVar258.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar260 = ( nodeVar249 + vec2<f32>( 1.0, 1.0 ) );
		nodeVar261 = fract( ( vec3<f32>( nodeVar260.x, nodeVar260.y, nodeVar260.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar262 = ( nodeVar261 + vec3<f32>( dot( nodeVar261, ( vec3<f32>( nodeVar261.y, nodeVar261.z, nodeVar261.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar263 = floor( ( ( nodeVar247 / vec2<f32>( knobs.grainSize ) ) * vec2<f32>( 2.1 ) ) );
		nodeVar264 = fract( ( vec3<f32>( nodeVar263.x, nodeVar263.y, nodeVar263.x ) * vec3<f32>( 0.1031 ) ) );
		nodeVar265 = ( nodeVar264 + vec3<f32>( dot( nodeVar264, ( vec3<f32>( nodeVar264.y, nodeVar264.z, nodeVar264.x ) + vec3<f32>( 33.33 ) ) ) ) );
		nodeVar33 = ( ( ( ( ( nodeVar150 * 0.5 ) * knobs.engraveDepth ) * ( 0.35 + ( ( 1.0 - nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( nodeVar193.x + nodeVar193.y ) * nodeVar193.z ) ), fract( ( ( nodeVar196.x + nodeVar196.y ) * nodeVar196.z ) ), nodeVar198.x ), mix( fract( ( ( nodeVar201.x + nodeVar201.y ) * nodeVar201.z ) ), fract( ( ( nodeVar204.x + nodeVar204.y ) * nodeVar204.z ) ), nodeVar198.x ), nodeVar198.y ) * 0.6 ) + ( fract( ( ( nodeVar207.x + nodeVar207.y ) * nodeVar207.z ) ) * 0.4 ) ) - 0.5 ) * knobs.grain ) ) - ( ( ( ( nodeVar208 * 0.5 ) * knobs.engraveDepth ) * ( 0.35 + ( ( 1.0 - nodeVar14 ) * 0.65 ) ) ) + ( ( ( ( mix( mix( fract( ( ( nodeVar251.x + nodeVar251.y ) * nodeVar251.z ) ), fract( ( ( nodeVar254.x + nodeVar254.y ) * nodeVar254.z ) ), nodeVar256.x ), mix( fract( ( ( nodeVar259.x + nodeVar259.y ) * nodeVar259.z ) ), fract( ( ( nodeVar262.x + nodeVar262.y ) * nodeVar262.z ) ), nodeVar256.x ), nodeVar256.y ) * 0.6 ) + ( fract( ( ( nodeVar265.x + nodeVar265.y ) * nodeVar265.z ) ) * 0.4 ) ) - 0.5 ) * knobs.grain ) ) );
		

	}


	if ( ( (1 * knobs.surface + 0) > 0.5 ) ) {

		nodeVar266 = nodeVar31;

	} else {

		nodeVar266 = knobs.color;

	}


	if ( ( (1 * knobs.relief + 0) > 0.5 ) ) {

		nodeVar267 = -1.0;

	} else {

		nodeVar267 = 1.0;

	}

	nodeVar268 = normalize( vec3<f32>( ( ( ( ( ( nodeVar15 - nodeVar16 ) * knobs.depth ) * nodeVar267 ) + nodeVar32 ) * -2.0 ), ( ( ( ( ( nodeVar17 - nodeVar18 ) * knobs.depth ) * nodeVar267 ) + nodeVar33 ) * 2.0 ), 1.0 ) );
	nodeVar269 = ( knobs.lightAngle * 0.017453292519943295 );
	nodeVar270 = ( knobs.elevation * 0.017453292519943295 );
	nodeVar271 = normalize( vec3<f32>( ( cos( nodeVar269 ) * cos( nodeVar270 ) ), ( sin( nodeVar269 ) * cos( nodeVar270 ) ), sin( nodeVar270 ) ) );
	nodeVar272 = normalize( ( nodeVar271 + vec3<f32>( 0.0, 0.0, 1.0 ) ) );
	nodeVar273 = vec4<f32>( mix( nodeVar31, clamp( ( ( nodeVar266 * vec3<f32>( ( knobs.ambient + ( ( 1.0 - knobs.ambient ) * ( max( dot( nodeVar268, nodeVar271 ), 0.0 ) / sin( nodeVar270 ) ) ) ) ) ) + vec3<f32>( ( max( ( pow( max( dot( nodeVar268, nodeVar272 ), 0.0 ), knobs.shininess ) - pow( max( nodeVar272.z, 0.0 ), knobs.shininess ) ), 0.0 ) * knobs.specular ) ) ), vec3<f32>( 0.0 ), vec3<f32>( 1.0 ) ), knobs.amount ), nodeVar30.w );
	nodeVar274 = vec3<f32>( nodeVar273.x, nodeVar273.y, nodeVar273.z );
	nodeVar275 = ( ( ( nodeVar274.x * 0.2126 ) + ( nodeVar274.y * 0.7152 ) ) + ( nodeVar274.z * 0.0722 ) );
	nodeVar276 = mix( vec3<f32>( nodeVar275, nodeVar275, nodeVar275 ), nodeVar274, f32(1.0) );
	nodeVar277 = vec4<f32>( clamp( vec3<f32>( ( ( ( nodeVar276.x * ( ( 0.213 + ( cos( f32(0.0) ) * 0.787 ) ) - ( sin( f32(0.0) ) * 0.213 ) ) ) + ( nodeVar276.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) - ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar276.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) + ( sin( f32(0.0) ) * 0.928 ) ) ) ), ( ( ( nodeVar276.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) + ( sin( f32(0.0) ) * 0.143 ) ) ) + ( nodeVar276.y * ( ( 0.715 + ( cos( f32(0.0) ) * 0.285 ) ) + ( sin( f32(0.0) ) * 0.14 ) ) ) ) + ( nodeVar276.z * ( ( 0.072 - ( cos( f32(0.0) ) * 0.072 ) ) - ( sin( f32(0.0) ) * 0.283 ) ) ) ), ( ( ( nodeVar276.x * ( ( 0.213 - ( cos( f32(0.0) ) * 0.213 ) ) - ( sin( f32(0.0) ) * 0.787 ) ) ) + ( nodeVar276.y * ( ( 0.715 - ( cos( f32(0.0) ) * 0.715 ) ) + ( sin( f32(0.0) ) * 0.715 ) ) ) ) + ( nodeVar276.z * ( ( 0.072 + ( cos( f32(0.0) ) * 0.928 ) ) + ( sin( f32(0.0) ) * 0.072 ) ) ) ) ), vec3<f32>( 0.0, 0.0, 0.0 ), vec3<f32>( 1.0, 1.0, 1.0 ) ), clamp( nodeVar273.w, 0.0, 1.0 ) );
	DiffuseColor = vec4<f32>( mix( nodeVar0.xyz, nodeVar277.xyz, ( clamp( f32(1.0), 0.0, 1.0 ) * clamp( nodeVar277.w, 0.0, 1.0 ) ) ), clamp( nodeVar0.w, 0.0, 1.0 ) );
	DiffuseColor.w = ( DiffuseColor.w * f32(1.0) );
	nodeVar278 = max( vec4<f32>( DiffuseColor.xyz, DiffuseColor.w ), vec4<f32>( 0.0 ) );
	Output = nodeVar278;

	// result

	output.color = nodeVar278;

	output.color = to_shelf(output.color);
	return output;

}

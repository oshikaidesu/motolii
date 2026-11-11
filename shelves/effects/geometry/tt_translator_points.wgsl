// Translator: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:3d
// --track@distance_x:Distance x,-4,4,-0.5,0.01
// --track@distance_y:Distance y,-4,4,0,0.01
// --track@distance_z:Distance z,-4,4,0.2,0.01
struct Knobs {
  time: f32,
  distance_x: f32,
  distance_y: f32,
  distance_z: f32,
};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
@group(0) @binding(8) var<storage, read_write> shape_normals: array<f32>;
@group(0) @binding(10) var<storage, read_write> normals: array<f32>;
@group(0) @binding(12) var<storage, read_write> shape_tangents: array<f32>;

// structs


// uniforms



// varyings

struct VaryingsStruct {
	@location( 0 ) v_shape_normal : vec3<f32>,
	@builtin( position ) builtinClipSpace : vec4<f32>
};
var<private> varyings : VaryingsStruct;

// vars
var<private> normalLocal : vec3<f32>;
var<private> tangentLocal : vec3<f32>;
var<private> modelViewMatrix : mat4x4<f32>;
var<private> VERTEX_nodeVar1 : vec4<f32>;
var<private> positionLocal : vec3<f32>;
var<private> v_modelViewProjection : vec4<f32>;
var<private> v_positionView : vec3<f32>;
var<private> VERTEX_v_modelViewProjection : vec4<f32>;

// codes
fn spherical ( phi : f32, theta : f32 ) -> vec3<f32> {

	


	return vec3<f32>( ( sin( theta ) * sin( phi ) ), cos( phi ), ( cos( theta ) * sin( phi ) ) );

}

fn selectPlanar ( pos : vec3<f32>, selAngles : vec2<f32>, selCenter : vec3<f32>, selWidth : f32 ) -> f32 {

	var nodeVar0 : vec3<f32>;

	nodeVar0 = ( spherical( selAngles.x, selAngles.y ) * vec3<f32>( selWidth ) );

	return smoothstep( 0.0, 1.0, ( dot( ( ( pos + ( nodeVar0 / vec3<f32>( 2.0 ) ) ) - selCenter ), nodeVar0 ) / dot( nodeVar0, nodeVar0 ) ) );

}

fn surfacePos ( pos : vec3<f32>, distance : vec3<f32>, selectorAngles : vec2<f32>, selectorCenter : vec3<f32>, selectorWidth : f32 ) -> vec3<f32> {

	


	return ( pos + ( distance * vec3<f32>( selectPlanar( pos, selectorAngles, selectorCenter, selectorWidth ) ) ) );

}

fn translatorRaw ( position : vec3<f32>, distance : vec3<f32>, selectorAngles : vec2<f32>, selectorCenter : vec3<f32>, selectorWidth : f32 ) -> vec3<f32> {

	


	return surfacePos( position, distance, selectorAngles, selectorCenter, selectorWidth );

}

fn approximateNormal ( pos : vec3<f32>, posU : vec3<f32>, posV : vec3<f32> ) -> vec3<f32> {

	


	return normalize( ( mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) * vec4<f32>( ( f32(1.0) * normalize( cross( ( posU - pos ), ( posV - pos ) ) ) ), 0.0 ) ).xyz );

}

fn translatorNormalRaw ( position : vec3<f32>, normalLoc : vec3<f32>, tangentLoc : vec3<f32>, distance : vec3<f32>, selectorAngles : vec2<f32>, selectorCenter : vec3<f32>, selectorWidth : f32 ) -> vec3<f32> {

	var nodeVar0 : vec3<f32>;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : vec3<f32>;

	nodeVar0 = normalize( normalLoc );
	nodeVar1 = ( normalize( tangentLoc ) * vec3<f32>( 0.01 ) );
	nodeVar2 = ( normalize( cross( nodeVar0, nodeVar1 ) ) * vec3<f32>( 0.01 ) );

	return approximateNormal( surfacePos( position, distance, selectorAngles, selectorCenter, selectorWidth ), surfacePos( ( position + nodeVar1 ), distance, selectorAngles, selectorCenter, selectorWidth ), surfacePos( ( position + nodeVar2 ), distance, selectorAngles, selectorCenter, selectorWidth ) );

}



fn point_moved( position : vec3<f32>,
	normal : vec3<f32>,
	tangent : vec4<f32> ) -> vec3<f32> {

	// flow
	// code

	positionLocal = position;
	positionLocal = translatorRaw( position, vec3<f32>(knobs.distance_x, knobs.distance_y, knobs.distance_z), vec2<f32>( 0.0, 0.0 ), vec3<f32>( 0.0, 0.0, 0.0 ), 0.7 );
	normalLocal = normal;
	tangentLocal = tangent.xyz;
	varyings.v_shape_normal = translatorNormalRaw( position, normalLocal, tangentLocal, vec3<f32>(knobs.distance_x, knobs.distance_y, knobs.distance_z), vec2<f32>( 0.0, 0.0 ), vec3<f32>( 0.0, 0.0, 0.0 ), 0.7 );
	modelViewMatrix = ( mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) * mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) );
	v_positionView = ( modelViewMatrix * vec4<f32>( positionLocal, 1.0 ) ).xyz;
	VERTEX_nodeVar1 = ( mat4x4<f32>(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.0, 1.0) * vec4<f32>( v_positionView, 1.0 ) );
	VERTEX_v_modelViewProjection = VERTEX_nodeVar1;

	// result

	varyings.builtinClipSpace = VERTEX_v_modelViewProjection;

	return positionLocal;

}

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&points) || 3u * i + 2u >= arrayLength(&shape_points) || 2u * i + 1u >= arrayLength(&shape_uvs) || 3u * i + 2u >= arrayLength(&shape_normals) || 4u * i + 3u >= arrayLength(&shape_tangents)) { return; }
  let p = point_moved(vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u]), vec3f(shape_normals[3u * i], shape_normals[3u * i + 1u], shape_normals[3u * i + 2u]), vec4f(shape_tangents[4u * i], shape_tangents[4u * i + 1u], shape_tangents[4u * i + 2u], shape_tangents[4u * i + 3u]));
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
  let n = varyings.v_shape_normal;
  normals[3u * i] = n.x; normals[3u * i + 1u] = n.y; normals[3u * i + 2u] = n.z;
}

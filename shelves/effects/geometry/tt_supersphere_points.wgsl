// Supersphere: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:3d
// --track@exponent:Exponent,-1,7,3,0.1
struct Knobs {
  time: f32,
  exponent: f32,
};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
@group(0) @binding(8) var<storage, read_write> shape_normals: array<f32>;
@group(0) @binding(12) var<storage, read_write> shape_tangents: array<f32>;

// structs


// uniforms



// varyings

struct VaryingsStruct {
	@builtin( position ) builtinClipSpace : vec4<f32>
};
var<private> varyings : VaryingsStruct;

// vars
var<private> modelViewMatrix : mat4x4<f32>;
var<private> VERTEX_nodeVar1 : vec4<f32>;
var<private> positionLocal : vec3<f32>;
var<private> v_modelViewProjection : vec4<f32>;
var<private> v_positionView : vec3<f32>;
var<private> VERTEX_v_modelViewProjection : vec4<f32>;

// codes
fn surfacePos ( pos : vec3<f32>, exponent : f32 ) -> vec3<f32> {

	var nodeVar0 : vec3<f32>;
	var nodeVar1 : f32;
	var nodeVar2 : vec3<f32>;

	nodeVar0 = ( pos / vec3<f32>( length( pos ) ) );
	nodeVar1 = pow( 2.0, exponent );
	nodeVar2 = pow( abs( nodeVar0 ), vec3<f32>( nodeVar1 ) );

	return ( nodeVar0 / vec3<f32>( pow( ( ( nodeVar2.x + nodeVar2.y ) + nodeVar2.z ), ( 1.0 / nodeVar1 ) ) ) );

}

fn supersphereRaw ( position : vec3<f32>, exponent : f32 ) -> vec3<f32> {

	


	return surfacePos( position, exponent );

}



fn point_moved( position : vec3<f32> ) -> vec3<f32> {

	// flow
	// code

	positionLocal = position;
	positionLocal = supersphereRaw( position, f32(knobs.exponent) );
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
  let p = point_moved(vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u]));
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
}

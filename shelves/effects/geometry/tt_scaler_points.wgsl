// Scaler: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)
// --label:3d
// --track@scales_x:Scales x,0.01,4,0.01,0.01
// --track@scales_y:Scales y,0.01,4,0.9,0.01
// --track@scales_z:Scales z,0.01,4,1.7,0.01
// --track@center_x:Center x,-4,4,0,0.01
// --track@center_y:Center y,-4,4,0,0.01
// --track@center_z:Center z,-4,4,0,0.01
struct Knobs {
  time: f32,
  scales_x: f32,
  scales_y: f32,
  scales_z: f32,
  center_x: f32,
  center_y: f32,
  center_z: f32,
};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
@group(0) @binding(8) var<storage, read_write> shape_normals: array<f32>;

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
fn spherical ( phi : f32, theta : f32 ) -> vec3<f32> {

	


	return vec3<f32>( ( sin( theta ) * sin( phi ) ), cos( phi ), ( cos( theta ) * sin( phi ) ) );

}

fn selectPlanar ( pos : vec3<f32>, selAngles : vec2<f32>, selCenter : vec3<f32>, selWidth : f32 ) -> f32 {

	var nodeVar0 : vec3<f32>;

	nodeVar0 = ( spherical( selAngles.x, selAngles.y ) * vec3<f32>( selWidth ) );

	return smoothstep( 0.0, 1.0, ( dot( ( ( pos + ( nodeVar0 / vec3<f32>( 2.0 ) ) ) - selCenter ), nodeVar0 ) / dot( nodeVar0, nodeVar0 ) ) );

}

fn scalerRaw ( position : vec3<f32>, scales : vec3<f32>, center : vec3<f32>, selectorAngles : vec2<f32>, selectorCenter : vec3<f32>, selectorWidth : f32 ) -> vec3<f32> {

	


	return ( ( ( position - center ) * mix( vec3<f32>( 1.0, 1.0, 1.0 ), scales, selectPlanar( position, selectorAngles, selectorCenter, selectorWidth ) ) ) + center );

}



fn point_moved( position : vec3<f32> ) -> vec3<f32> {

	// flow
	// code

	positionLocal = position;
	positionLocal = scalerRaw( position, vec3<f32>(knobs.scales_x, knobs.scales_y, knobs.scales_z), vec3<f32>(knobs.center_x, knobs.center_y, knobs.center_z), vec2<f32>( 0.0, 0.0 ), vec3<f32>( 0.0, 0.0, 0.0 ), 2.0 );
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
  if (3u * i + 2u >= arrayLength(&points) || 3u * i + 2u >= arrayLength(&shape_points) || 2u * i + 1u >= arrayLength(&shape_uvs) || 3u * i + 2u >= arrayLength(&shape_normals)) { return; }
  let p = point_moved(vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u]));
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
}

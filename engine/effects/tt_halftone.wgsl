// Halftone: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/tsl/textures_shelf.ts)
// --label:Generate
// --about:This texture enforces halftone pattern by keeping some part of the object surface
// --track@scale:Scale,0,4,2,0.04
// --track@radius:Radius,0,2,0.5,0.02
// --track@pattern:Pattern,0,10,1,1
diagnostic(off, derivative_uniformity);
struct Knobs {
  time: f32,
  passindex: f32,
  resolution: vec2<f32>,
  frameRect: vec4<f32>,
  passRect: vec4<f32>,
  scale: f32,
  radius: f32,
  pattern: f32,
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
var<private> p0_Output : vec4<f32>;
var<private> p0_nodeVar0 : vec4<f32>;

// codes
fn p0_halftoneGridRaw ( position : vec3<f32>, scale : f32, radius : f32, attenuation : i32, far : f32, near : f32, color : vec3<f32>, positionView : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : f32;

	p0_nodeVar0 = exp( ( 5.0 - scale ) );
	nodeVar1 = position;
	nodeVar2 = ( radius / 1.4142135623730951 );

	if ( ( f32( attenuation ) != 0.0 ) ) {

		nodeVar2 = ( nodeVar2 * pow( smoothstep( far, near, ( positionView.z * -1.0 ) ), 0.5 ) );
		

	}


	if ( ( distance( nodeVar1, ( round( ( nodeVar1 / vec3<f32>( p0_nodeVar0 ) ) ) * vec3<f32>( p0_nodeVar0 ) ) ) > ( p0_nodeVar0 * nodeVar2 ) ) ) {

		discard;
		discard;
		

	}


	return color;

}

fn p0_tsl_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }
fn p0_halftoneDiagRaw ( position : vec3<f32>, scale : f32, radius : f32, attenuation : i32, far : f32, near : f32, color : vec3<f32>, positionView : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : f32;
	var nodeVar1 : vec3<f32>;
	var nodeVar2 : f32;
	var nodeVar3 : vec3<f32>;
	var nodeVar4 : vec3<f32>;
	var nodeVar5 : vec2<f32>;

	p0_nodeVar0 = exp( ( 5.0 - scale ) );
	nodeVar1 = position;
	nodeVar2 = ( radius / 1.4142135623730951 );
	nodeVar3 = round( ( nodeVar1 / vec3<f32>( p0_nodeVar0 ) ) );
	nodeVar3 = ( nodeVar3 * vec3<f32>( p0_nodeVar0 ) );
	nodeVar4 = nodeVar3;

	if ( ( p0_tsl_mod_float( round( ( nodeVar1.y / p0_nodeVar0 ) ), 2.0 ) == 0.0 ) ) {

		nodeVar4.x = ( nodeVar4.x + ( p0_nodeVar0 * 0.5 ) );
		

	}

	nodeVar5 = vec2<f32>( ( nodeVar4.x - p0_nodeVar0 ), nodeVar4.y );

	if ( ( f32( attenuation ) != 0.0 ) ) {

		nodeVar2 = ( nodeVar2 * pow( smoothstep( far, near, ( positionView.z * -1.0 ) ), 0.5 ) );
		

	}


	if ( ( min( distance( nodeVar1, nodeVar4 ), distance( nodeVar1, vec3<f32>( nodeVar5, 0.0 ) ) ) > ( p0_nodeVar0 * nodeVar2 ) ) ) {

		discard;
		discard;
		

	}


	return color;

}

fn p0_halftoneTrigRaw ( position : vec3<f32>, scale : f32, radius : f32, pattern : i32, attenuation : i32, far : f32, near : f32, color : vec3<f32>, positionView : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;
	var nodeVar1 : f32;
	var nodeVar2 : f32;

	p0_nodeVar0 = ( ( sin( ( position * vec3<f32>( exp( ( scale - 3.5 ) ) ) ) ) + vec3<f32>( 1.0 ) ) / vec3<f32>( 2.0 ) );
	nodeVar1 = ( radius / 1.4142135623730951 );
	nodeVar2 = 0.0;

	if ( ( f32( pattern ) == 2.0 ) ) {

		nodeVar2 = ( ( p0_nodeVar0.x + p0_nodeVar0.y ) / 2.0 );
		

	} else {


		if ( ( f32( pattern ) == 3.0 ) ) {

			nodeVar2 = ( 1.0 - abs( ( p0_nodeVar0.x - p0_nodeVar0.y ) ) );
			

		} else {


			if ( ( f32( pattern ) == 10.0 ) ) {

				nodeVar2 = abs( ( p0_nodeVar0.x - p0_nodeVar0.y ) );
				

			} else {


				if ( ( f32( pattern ) == 4.0 ) ) {

					nodeVar2 = ( 1.0 - ( p0_nodeVar0.x * p0_nodeVar0.y ) );
					

				} else {


					if ( ( f32( pattern ) == 9.0 ) ) {

						nodeVar2 = ( p0_nodeVar0.x * p0_nodeVar0.y );
						

					} else {


						if ( ( f32( pattern ) == 5.0 ) ) {

							nodeVar2 = max( p0_nodeVar0.x, p0_nodeVar0.y );
							

						} else {


							if ( ( f32( pattern ) == 6.0 ) ) {

								nodeVar2 = min( p0_nodeVar0.x, p0_nodeVar0.y );
								

							} else {


								if ( ( f32( pattern ) == 7.0 ) ) {

									nodeVar2 = p0_nodeVar0.x;
									

								} else {


									if ( ( f32( pattern ) == 8.0 ) ) {

										nodeVar2 = p0_nodeVar0.y;
										

									}

									

								}

								

							}

							

						}

						

					}

					

				}

				

			}

			

		}

		

	}


	if ( ( f32( attenuation ) != 0.0 ) ) {

		nodeVar1 = ( nodeVar1 * pow( smoothstep( far, near, ( positionView.z * -1.0 ) ), 0.5 ) );
		

	}


	if ( ( nodeVar2 > nodeVar1 ) ) {

		discard;
		discard;
		

	}


	return color;

}

fn p0_halftoneRaw ( position : vec3<f32>, scale : f32, radius : f32, pattern : i32, attenuation : i32, far : f32, near : f32, color : vec3<f32>, positionView : vec3<f32> ) -> vec3<f32> {

	var p0_nodeVar0 : vec3<f32>;

	p0_nodeVar0 = vec3<f32>( 0.0, 0.0, 0.0 );

	if ( ( f32( pattern ) == 0.0 ) ) {

		p0_nodeVar0 = p0_halftoneGridRaw( position, scale, radius, attenuation, far, near, color, positionView );
		

	} else {


		if ( ( f32( pattern ) == 1.0 ) ) {

			p0_nodeVar0 = p0_halftoneDiagRaw( position, scale, radius, attenuation, far, near, color, positionView );
			

		} else {

			p0_nodeVar0 = p0_halftoneTrigRaw( position, scale, radius, pattern, attenuation, far, near, color, positionView );
			

		}

		

	}


	return p0_nodeVar0;

}



fn p0_main(door_uv: vec2f) -> p0_OutputStruct {
	let v_positionView = vec3f(door_uv.x, 1.0 - door_uv.y, 0.0);
	let fragCoord = vec4f(door_uv * knobs.resolution, 0.0, 1.0);

	// flow
	// code

	p0_DiffuseColor = vec4<f32>( p0_halftoneRaw( vec3<f32>( fragCoord.xy, 0.0 ), f32(knobs.scale), f32(knobs.radius), i32( f32(knobs.pattern) ), 0, 14.0, 6.0, vec4<f32>( 1.0, 1.0, 1.0, 1.0 ).xyz, v_positionView ), 1.0 );
	p0_DiffuseColor.w = ( p0_DiffuseColor.w * f32(1.0) );
	p0_DiffuseColor.w = 1.0;
	p0_nodeVar0 = max( vec4<f32>( p0_DiffuseColor.xyz, p0_DiffuseColor.w ), vec4<f32>( 0.0 ) );
	p0_Output = p0_nodeVar0;

	// result

	p0_output.color = p0_nodeVar0;

	return p0_output;

}

@fragment
fn main(@location(0) door_on: vec2f) -> @location(0) vec4f {
  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;
  return to_shelf(p0_main(door_uv).color) * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a;
}

// AviUtl2 `obj.drawpoly`: a coloured face with the source texture, or a face
// of pure colour when its uv is off the texture (a drawn polygon, no image).
struct K { alpha: f32 }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@location(0) uv: vec2f, @location(1) colour: vec4f) -> @location(0) vec4f {
  let seen = textureSampleLevel(sourceTexture, near, uv, 0.0);
  return select(seen, vec4f(1.0), uv.x < -1.0) * colour * k.alpha;   // (a coloured face: its uv off the sourceTexture, its colour alone)
}

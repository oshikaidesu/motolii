// AviUtl2 blur: a Gaussian along k.step, with sigma half of k.radius. Taps
// capped at 96, so a huge radius does not lock the frame.
struct K { step: vec2f, radius: f32, unused: f32 }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let at = frag.xy / vec2f(textureDimensions(sourceTexture));
  let sigma = max(k.radius * 0.5, 0.5);
  var sum = textureSampleLevel(sourceTexture, near, at, 0.0);
  var total = 1.0;
  let taps = i32(min(k.radius, 96.0));
  for (var i = 1; i <= taps; i++) {
    let o = f32(i);
    let w = exp(-0.5 * o * o / (sigma * sigma));
    sum += (textureSampleLevel(sourceTexture, near, at + k.step * o, 0.0) + textureSampleLevel(sourceTexture, near, at - k.step * o, 0.0)) * w;
    total += 2.0 * w;
  }
  return sum / total;
}

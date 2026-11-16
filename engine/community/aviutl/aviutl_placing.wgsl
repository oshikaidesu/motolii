// AviUtl2 `obj.draw`: places the source texture at k.at with the 2x2 matrix k.m,
// scaled by k.size, offset by k.src. k.way: 0 = place with edge taper,
// 1 = fill with k.colour, 2 = place without edge taper. k.colour.x switches
// between premultiplied and straight alpha.
struct K { m: vec4f, at: vec2f, src: vec2f, size: vec2f, alpha: f32, way: f32, colour: vec4f }
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: K;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  if (k.way == 1.0) { return k.colour; }
  let d = frag.xy - k.at;
  let c = (vec2f(dot(k.m.xy, d), dot(k.m.zw, d)) + k.src) / k.size;
  let w = clamp(c * k.size + 0.5, vec2f(0.0), vec2f(1.0)) * clamp((1.0 - c) * k.size + 0.5, vec2f(0.0), vec2f(1.0));
  var s = textureSampleLevel(sourceTexture, near, c, 0.0);
  if (k.colour.x == 1.0) { s = vec4f(s.rgb * s.a, s.a); }
  s = s * (k.alpha * select(w.x * w.y, 1.0, k.way == 2.0));
  if (k.colour.x == 2.0 && s.a > 0.0) { s = vec4f(s.rgb / s.a, s.a); }
  return s;
}

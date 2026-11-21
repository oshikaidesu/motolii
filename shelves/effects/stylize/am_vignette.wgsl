// Vignette: AbsentMotion's vignette (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --about:Darkens the layer toward its edges outside a rounded shape: Size sets the shape, Roundness how round it is, Feather how soft its edge is, Strength how dark it gets and Tint how much it takes on Color. Punch Out makes the edges transparent instead.
diagnostic(off, derivative_uniformity);
diagnostic(off, chromium.unreachable_code);
struct FSIn {
  @builtin(position) sk_FragCoord: vec4<f32>,
};
struct FSOut {
  @location(0) sk_FragColor: vec4<f32>,
};
struct Knobs {
  @auto resolution: vec2<f32>,
  @auto time: f32,
  @label("Size")
  @range(0.001, 2, 0.001, 0.95) extent_: f32,
  @range(0, 1, 0.001, 0.8)     strength: f32,
  @label("Roundness")
  @range(0, 9.9, 0.01, 1.5)    rounding: f32,
  @range(0.001, 1, 0.001, 0.5) feather: f32,
  @range(0, 1, 0.01, 0.2)      tint: f32,
  @color(0, 0, 0, 1)           color: vec4<f32>,
  punch: f32,
  layerRect: vec4<f32>,
};
@group(0) @binding(2) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let c: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if c.w <= 0.0001 {
      return vec4<f32>(0.0);
    }
    let n: vec2<f32> = abs((coord / max(select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0)), vec2<f32>(1.0)) - 0.5) * 2.0);
    let p: f32 = max(_uniform0.rounding, 0.5);
    let d: f32 = pow(pow(n.x, p) + pow(n.y, p), 1.0 / p);
    let s: f32 = max(_uniform0.extent_, 0.001);
    let v: f32 = smoothstep(s * (1.0 - _uniform0.feather * 0.25), s * (1.0 + _uniform0.feather * 3.0) + 0.001, d) * clamp(_uniform0.strength, 0.0, 1.0);
    if _uniform0.punch > 0.5 {
      return c * f32(1.0 - v);
    }
    var rgb: vec3<f32> = vec3<f32>(c.xyz / c.w);
    rgb = mix(max(rgb - v * (1.0 - _uniform0.tint), vec3<f32>(0.0)), vec3<f32>(_uniform0.color.xyz), vec3<f32>(_uniform0.tint * v));
    return vec4<f32>(vec3<f32>(rgb) * c.w, c.w);
  }
}
fn _skslMain(_stageIn: FSIn, _stageOut: ptr<function, FSOut>) {
  {
    (*_stageOut).sk_FragColor = effect__h4f2(_stageIn.sk_FragCoord.xy - (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0))));
  }
}
@fragment fn main(_stageIn: FSIn) -> FSOut {
  var _stageOut: FSOut;
  _skslMain(_stageIn, &_stageOut);
  return _stageOut;
}

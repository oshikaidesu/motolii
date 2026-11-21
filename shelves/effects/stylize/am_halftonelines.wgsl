// Halftone Lines: AbsentMotion's halftonelines (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --about:Redraws the layer as printed lines that get thicker in dark areas and thinner in light ones.
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
  @range(0, 500, 0.1, 100)     amount: f32,
  @range(0, 1, 0.001, 0.5)     strength: f32,
  @range(0, 3600, 0.5, 45)     angle: f32,
  @range(-1000, 1000, 0.001, 0) phase: f32,
  @label("Color 1")
  @color(0.06667, 0.2, 0.3333, 1) color1: vec4<f32>,
  @label("Color 2")
  @color(1, 0.9333, 0.8667, 1) color2: vec4<f32>,
  layerRect: vec4<f32>,
};
@group(0) @binding(2) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let src: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if src.w <= 0.0 {
      return src;
    }
    let period: f32 = (select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))).x / max(_uniform0.amount, 0.5);
    let a: f32 = radians(_uniform0.angle);
    let u: f32 = dot(coord - (select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))) * 0.5, vec2<f32>(-sin(a), cos(a))) / period + _uniform0.phase;
    let s: f32 = clamp(_uniform0.strength, 0.001, 0.999);
    let ink: f32 = pow(clamp(1.0 - dot(vec3<f32>(src.xyz) / f32(src.w), vec3<f32>(0.2126, 0.7152, 0.0722)), 0.0, 1.0), (1.0 - s) / s);
    let e: f32 = abs(fract(u) - 0.5) * period;
    let line: f32 = clamp(((ink * period) * 0.5 - e) + 0.5, 0.0, 1.0);
    let rgb: vec3<f32> = mix(vec3<f32>(_uniform0.color2.xyz), vec3<f32>(_uniform0.color1.xyz), vec3<f32>(line));
    return vec4<f32>(vec3<f32>(rgb) * src.w, src.w);
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

// Checker: AbsentMotion's checker (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --about:Draws a checkerboard over the opaque parts of the layer, or punches the checkers out of it.
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
  @auto screen: vec4<f32>,
  @auto time: f32,
  @range(-5000, 5000, 1, 0, 0) offset: vec2<f32>,
  @range(0.5, 200, 0.1, 10)    count: f32,
  @range(0.01, 10, 0.01, 1, 1) stretch: vec2<f32>,
  @color(0.1765, 0.1176, 0.9647, 1) color: vec4<f32>,
  punch: f32,
  @range(-3600, 3600, 0.5, 0)  angle: f32,
  screenSpace: f32,
  layerRect: vec4<f32>,
};
@group(0) @binding(2) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
fn layerSize__f2() -> vec2<f32> {
  {
    return select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0));
  }
}
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let src: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if src.w <= 0.0 {
      return src;
    }
    var _skTemp1: vec2<f32>;
    if _uniform0.screenSpace > 0.5 {
      _skTemp1 = _uniform0.screen.zw;
    } else {
      _skTemp1 = layerSize__f2();
    }
    let patternSize: vec2<f32> = _skTemp1;
    var _skTemp2: vec2<f32>;
    if _uniform0.screenSpace > 0.5 {
      _skTemp2 = _uniform0.screen.xy + _uniform0.screen.zw * 0.5;
    } else {
      _skTemp2 = layerSize__f2() * 0.5;
    }
    let origin: vec2<f32> = _skTemp2;
    let cell: f32 = patternSize.y / (2.475 * max(_uniform0.count, 0.5));
    let a: f32 = radians(_uniform0.angle);
    var p: vec2<f32> = (coord - origin) - _uniform0.offset;
    p = vec2<f32>(cos(a) * p.x + sin(a) * p.y, -sin(a) * p.x + cos(a) * p.y) / (max(abs(_uniform0.stretch), vec2<f32>(0.01)) * cell);
    let e: vec2<f32> = (min(fract(p), 1.0 - fract(p)) * max(abs(_uniform0.stretch), vec2<f32>(0.01))) * cell;
    let _skTemp3 = floor(p.x) + floor(p.y);
    let on: f32 = (_skTemp3 - 2.0 * floor(_skTemp3 / 2.0));
    let aa: f32 = clamp(min(e.x, e.y) + 0.5, 0.0, 1.0);
    let s: f32 = mix(0.5, on, aa);
    if _uniform0.punch > 0.5 {
      return src * f32(1.0 - s);
    }
    let base: vec3<f32> = vec3<f32>(src.xyz) / f32(src.w);
    let rgb: vec3<f32> = mix(base, vec3<f32>(_uniform0.color.xyz), vec3<f32>(s * f32(_uniform0.color.w)));
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

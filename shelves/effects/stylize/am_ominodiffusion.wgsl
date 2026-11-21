// Omino Diffusion+: AbsentMotion's ominodiffusion (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --about:Redraws the layer in a small palette and drags the rounding error along a direction, for a glitchy dithered look that comes alive in motion.
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
  @range(0, 3600, 0.5, 0)      angle: f32,
  @range(0.01, 1, 0.001, 1)    strength: f32,
  @range(1, 200, 1, 35)        steps: f32,
  @label("Error Weight")
  @range(0, 10, 0.001, 0.75)   weight: f32,
  @label("Weight Falloff")
  @range(0, 1, 0.001, 0)       falloff: f32,
  @range(0, 1, 0.01, 2)        palette: f32,
  @label("Color 1")
  @color(0, 0, 0, 1)           color1: vec4<f32>,
  @label("Color 2")
  @color(0.3333, 0.3333, 1, 1) color2: vec4<f32>,
  @label("Color 3")
  @color(0.3333, 1, 0.3333, 1) color3: vec4<f32>,
  @label("Color 4")
  @color(0.3333, 1, 1, 1)      color4: vec4<f32>,
  @label("Color 5")
  @color(1, 0.3333, 0.3333, 1) color5: vec4<f32>,
  @label("Color 6")
  @color(1, 0.3333, 1, 1)      color6: vec4<f32>,
  @range(0, 1, 0.001, 1)       alpha: f32,
  @label("Blending Mode")
  @range(0, 1, 0.01, 0)        blend: f32,
  layerRect: vec4<f32>,
};
@group(0) @binding(2) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
fn nearest_f3f3f3f3f(x: vec3<f32>, best: vec3<f32>, c: vec3<f32>, d: ptr<function, f32>) -> vec3<f32> {
  {
    let e: f32 = dot(x - c, x - c);
    if e < (*d) {
      {
        (*d) = e;
        return c;
      }
    }
    return best;
  }
}
fn quant_f3f3(x: vec3<f32>) -> vec3<f32> {
  {
    if _uniform0.palette < 0.5 {
      {
        return vec3<f32>(f32(dot(x, vec3<f32>(0.2126, 0.7152, 0.0722)) > 0.5));
      }
    }
    if _uniform0.palette < 3.5 {
      {
        let n: f32 = _uniform0.palette;
        return floor(clamp(x, vec3<f32>(0.0), vec3<f32>(1.0)) * n + 0.5) / n;
      }
    }
    if _uniform0.palette < 5.5 {
      {
        let n: f32 = _uniform0.palette - 2.0;
        return vec3<f32>(floor(clamp(dot(x, vec3<f32>(0.2126, 0.7152, 0.0722)), 0.0, 1.0) * n + 0.5) / n);
      }
    }
    if (_uniform0.palette > 8.5) && (_uniform0.palette < 9.5) {
      {
        let s: vec3<f32> = clamp(dot(x, vec3<f32>(0.2126, 0.7152, 0.0722)) + (x - dot(x, vec3<f32>(0.2126, 0.7152, 0.0722))) * 2.5, vec3<f32>(0.0), vec3<f32>(1.0));
        return floor(s + 0.5);
      }
    }
    var d: f32 = 100.0;
    var best: vec3<f32> = vec3<f32>(0.0);
    if _uniform0.palette < 6.5 {
      {
        var _skTemp1: f32 = d;
        let _skTemp2 = nearest_f3f3f3f3f(x, best, vec3<f32>(0.0), &_skTemp1);
        d = _skTemp1;
        best = _skTemp2;
        var _skTemp3: f32 = d;
        let _skTemp4 = nearest_f3f3f3f3f(x, best, vec3<f32>(0.0, 0.67, 0.0), &_skTemp3);
        d = _skTemp3;
        best = _skTemp4;
        var _skTemp5: f32 = d;
        let _skTemp6 = nearest_f3f3f3f3f(x, best, vec3<f32>(0.67, 0.0, 0.0), &_skTemp5);
        d = _skTemp5;
        best = _skTemp6;
        var _skTemp7: f32 = d;
        let _skTemp8 = nearest_f3f3f3f3f(x, best, vec3<f32>(0.67, 0.33, 0.0), &_skTemp7);
        d = _skTemp7;
        return _skTemp8;
      }
    }
    if _uniform0.palette < 8.5 {
      {
        var _skTemp9: f32 = d;
        let _skTemp10 = nearest_f3f3f3f3f(x, best, select(vec3<f32>(0.0, 0.0, 0.67), vec3<f32>(0.0), vec3<bool>(_uniform0.palette < 7.5)), &_skTemp9);
        d = _skTemp9;
        best = _skTemp10;
        var _skTemp11: f32 = d;
        let _skTemp12 = nearest_f3f3f3f3f(x, best, vec3<f32>(0.33, 1.0, 1.0), &_skTemp11);
        d = _skTemp11;
        best = _skTemp12;
        var _skTemp13: f32 = d;
        let _skTemp14 = nearest_f3f3f3f3f(x, best, vec3<f32>(1.0, 0.33, 1.0), &_skTemp13);
        d = _skTemp13;
        best = _skTemp14;
        var _skTemp15: f32 = d;
        let _skTemp16 = nearest_f3f3f3f3f(x, best, vec3<f32>(1.0), &_skTemp15);
        d = _skTemp15;
        return _skTemp16;
      }
    }
    let n: f32 = _uniform0.palette - 8.0;
    var _skTemp17: f32 = d;
    let _skTemp18 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color1.xyz), &_skTemp17);
    d = _skTemp17;
    best = _skTemp18;
    var _skTemp19: f32 = d;
    let _skTemp20 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color2.xyz), &_skTemp19);
    d = _skTemp19;
    best = _skTemp20;
    if n > 2.5 {
      var _skTemp21: f32 = d;
      let _skTemp22 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color3.xyz), &_skTemp21);
      d = _skTemp21;
      best = _skTemp22;
    }
    if n > 3.5 {
      var _skTemp23: f32 = d;
      let _skTemp24 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color4.xyz), &_skTemp23);
      d = _skTemp23;
      best = _skTemp24;
    }
    if n > 4.5 {
      var _skTemp25: f32 = d;
      let _skTemp26 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color5.xyz), &_skTemp25);
      d = _skTemp25;
      best = _skTemp26;
    }
    if n > 5.5 {
      var _skTemp27: f32 = d;
      let _skTemp28 = nearest_f3f3f3f3f(x, best, vec3<f32>(_uniform0.color6.xyz), &_skTemp27);
      d = _skTemp27;
      best = _skTemp28;
    }
    return best;
  }
}
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let src: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if src.w <= 0.0 {
      return vec4<f32>(0.0);
    }
    let a: f32 = radians(_uniform0.angle);
    let dir: vec2<f32> = vec2<f32>(cos(a), sin(a));
    let reach: f32 = clamp(_uniform0.strength, 0.01, 1.0) * max((select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))).x, (select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))).y);
    let n: f32 = clamp(floor(_uniform0.steps), 1.0, 200.0);
    var err: vec3<f32> = vec3<f32>(0.0);
    {
      var j: i32 = 0;
      for (; j < 200; j = j + i32(1)) {
        {
          if f32(j) >= n {
            break;
          }
          let far: f32 = n - f32(j);
          var _skTemp29: f32;
          if far <= 1.0 {
            _skTemp29 = 1.0;
          } else {
            _skTemp29 = pow(1.0 - clamp(_uniform0.falloff, 0.0, 1.0), far - 1.0);
          }
          let propagation: f32 = _skTemp29;
          let w: f32 = 1.0 + (_uniform0.weight - 1.0) * propagation;
          let _0_c: vec4<f32> = textureSample(image_Texture, image_Sampler, ((coord - ((dir * reach) * far) / n) + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
          var _skTemp30: vec3<f32>;
          if _0_c.w > 0.0 {
            _skTemp30 = vec3<f32>(_0_c.xyz) / f32(_0_c.w);
          } else {
            _skTemp30 = vec3<f32>(0.0);
          }
          let x: vec3<f32> = _skTemp30 + err * w;
          err = clamp(x - quant_f3f3(x), vec3<f32>(-4.0), vec3<f32>(4.0));
        }
      }
    }
    let base: vec3<f32> = vec3<f32>(src.xyz) / f32(src.w);
    var q: vec3<f32> = quant_f3f3(base + err * _uniform0.weight);
    if (_uniform0.blend > 0.5) && (_uniform0.blend < 1.5) {
      q = q * base;
    }
    if _uniform0.blend > 1.5 {
      q = 1.0 - (1.0 - q) * (1.0 - base);
    }
    let rgb: vec3<f32> = mix(base, q, vec3<f32>(clamp(_uniform0.alpha, 0.0, 1.0)));
    return vec4<f32>(vec3<f32>(rgb * f32(src.w)), src.w);
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

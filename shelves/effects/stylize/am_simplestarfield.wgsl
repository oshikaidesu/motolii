// Simple Starfield: AbsentMotion's simplestarfield (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --about:Scatters small stars in layers of depth over the opaque parts of the layer. Position moves the field with parallax, Depth flies through it, Scale zooms it, Size and Feather shape each star and Amount sets how many there are.
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
  @label("Position")
  @range(-100000, 100000, 1, 0, 0) R_position: vec2<f32>,
  @range(-100000, 100000, 1, 0) depth: f32,
  @range(0.01, 50, 0.01, 1)    scale: f32,
  @label("Size")
  @range(0, 5, 0.001, 0.5)     starSize: f32,
  @range(0, 20, 0.1, 0)        feather: f32,
  @color(1, 1, 1, 1)           color: vec4<f32>,
  @range(0, 1, 0.01, 1)        alpha: f32,
  @range(0, 100, 0.1, 25)      amount: f32,
  @range(0, 5, 0.001, 1)       brightness: f32,
  @label("Blending Mode")
  @range(0, 1, 0.01, 2)        blend: f32,
  layerRect: vec4<f32>,
};
@group(0) @binding(2) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
fn hash12_ff2(p: vec2<f32>) -> f32 {
  {
    var q: vec3<f32> = fract(p.xyx * 0.1031);
    q = q + dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
  }
}
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let src: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if src.w <= 0.0 {
      return src;
    }
    let zoom: f32 = max(_uniform0.scale, 0.01);
    let cell: f32 = 16.0 * zoom;
    let density: f32 = clamp((_uniform0.amount * 0.01) * 0.7, 0.0, 1.0);
    var glow: f32 = 0.0;
    {
      var k: i32 = 0;
      for (; k < 6; k = k + i32(1)) {
        {
          let _skTemp1 = f32(k) - _uniform0.depth * 0.01;
          let layer: f32 = (_skTemp1 - 6.0 * floor(_skTemp1 / 6.0));
          let d: f32 = 0.4 + layer * 0.6;
          let fade: f32 = smoothstep(0.0, 0.6, layer) * smoothstep(6.0, 5.0, layer);
          let id: f32 = floor(((f32(k) - _uniform0.depth * 0.01) - layer) + 0.5) + f32(k) * 13.0;
          let p: vec2<f32> = (((coord - (select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))) * 0.5) - _uniform0.R_position / d) * d) / cell + id * 7.13;
          let n: vec2<f32> = floor(p);
          if hash12_ff2(n + id * 3.7) > density {
            continue;
          }
          let at: vec2<f32> = vec2<f32>(hash12_ff2((n + 1.3) + id), hash12_ff2((n + 5.9) - id)) * 0.8 + 0.1;
          let r: f32 = ((_uniform0.starSize * 0.5) * zoom) / d;
          let amp: f32 = min((r * r) * 4.0, 1.0);
          let re: f32 = max(r, 0.5);
          let soft: f32 = 0.5 + ((_uniform0.feather * 0.15) * zoom) / d;
          let dist: f32 = length((((p - n) - at) * cell) / d);
          glow = glow + (fade * amp) * (1.0 - smoothstep(max(re - soft, 0.0), re + soft, dist));
        }
      }
    }
    let s: f32 = (clamp(glow * _uniform0.brightness, 0.0, 1.0) * clamp(_uniform0.alpha, 0.0, 1.0)) * f32(_uniform0.color.w);
    let base: vec3<f32> = vec3<f32>(src.xyz) / f32(src.w);
    let c: vec3<f32> = vec3<f32>(_uniform0.color.xyz);
    var _skTemp2: vec3<f32>;
    if _uniform0.blend < 0.5 {
      _skTemp2 = mix(base, c, vec3<f32>(s));
    } else {
      var _skTemp3: vec3<f32>;
      if _uniform0.blend < 1.5 {
        _skTemp3 = base + c * s;
      } else {
        var _skTemp4: vec3<f32>;
        if _uniform0.blend < 2.5 {
          _skTemp4 = 1.0 - (1.0 - base) * (1.0 - c * s);
        } else {
          _skTemp4 = mix(base, base * c, vec3<f32>(s));
        }
        _skTemp3 = _skTemp4;
      }
      _skTemp2 = _skTemp3;
    }
    let rgb: vec3<f32> = _skTemp2;
    return vec4<f32>(vec3<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0))) * src.w, src.w);
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

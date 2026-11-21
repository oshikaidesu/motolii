// Palette Map: AbsentMotion's palettemap (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Color
// --about:Maps each pixel to the nearest color in a palette of up to eight colors. Alpha blends the mapped colors with the original layer.
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
  @range(2, 8, 1, 5)           colors: f32,
  @label("Color 1")
  @color(0.1137, 0.1686, 0.3255, 1) color1: vec4<f32>,
  @label("Color 2")
  @color(0.4941, 0.1451, 0.3255, 1) color2: vec4<f32>,
  @label("Color 3")
  @color(1, 0, 0.302, 1)       color3: vec4<f32>,
  @label("Color 4")
  @color(1, 0.6392, 0, 1)      color4: vec4<f32>,
  @label("Color 5")
  @color(1, 0.9451, 0.9098, 1) color5: vec4<f32>,
  @label("Color 6")
  @color(1, 0.3333, 1, 1)      color6: vec4<f32>,
  @label("Color 7")
  @color(1, 1, 0.3333, 1)      color7: vec4<f32>,
  @label("Color 8")
  @color(1, 1, 1, 1)           color8: vec4<f32>,
  @range(0, 1, 0.001, 0)       dither: f32,
  @range(0, 1, 0.001, 1)       alpha: f32,
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
    var _0_q: vec3<f32> = fract(floor(coord).xyx * 0.1031);
    _0_q = _0_q + dot(_0_q, _0_q.yzx + 33.33);
    let rgb: vec3<f32> = vec3<f32>(src.xyz) / f32(src.w) + ((fract((_0_q.x + _0_q.y) * _0_q.z) - 0.5) * _uniform0.dither) * 0.3;
    var best: vec3<f32> = vec3<f32>(_uniform0.color1.xyz);
    var bestD: f32 = distance(rgb, best);
    var d: f32 = distance(rgb, vec3<f32>(_uniform0.color2.xyz));
    if d < bestD {
      {
        bestD = d;
        best = vec3<f32>(_uniform0.color2.xyz);
      }
    }
    if _uniform0.colors > 2.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color3.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color3.xyz);
          }
        }
      }
    }
    if _uniform0.colors > 3.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color4.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color4.xyz);
          }
        }
      }
    }
    if _uniform0.colors > 4.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color5.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color5.xyz);
          }
        }
      }
    }
    if _uniform0.colors > 5.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color6.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color6.xyz);
          }
        }
      }
    }
    if _uniform0.colors > 6.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color7.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color7.xyz);
          }
        }
      }
    }
    if _uniform0.colors > 7.5 {
      {
        d = distance(rgb, vec3<f32>(_uniform0.color8.xyz));
        if d < bestD {
          {
            bestD = d;
            best = vec3<f32>(_uniform0.color8.xyz);
          }
        }
      }
    }
    let base: vec3<f32> = vec3<f32>(src.xyz) / f32(src.w);
    return vec4<f32>(vec3<f32>(mix(base, best, vec3<f32>(clamp(_uniform0.alpha, 0.0, 1.0)))) * src.w, src.w);
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

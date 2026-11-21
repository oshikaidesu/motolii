// Electric Edges: AbsentMotion's electricedges (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Stylize
// --pass@h_:0,1,s1,s1
// --pass@blurPicture:0,1,s1,s1
// --pass@:0,0,s1,s1
// --about:Draws a crackling, glowing outline around the layer that jitters like electricity when Seed or Evolution is animated, with optional contour lines inside.
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
  @label("Distance")
  @range(0, 300, 0.1, 30)      blur: f32,
  @range(0, 1, 0.001, 0.8)     thickness: f32,
  @range(0, 20, 0.01, 2)       detail: f32,
  @range(-1, 1, 0.001, 0.5)    distortion: f32,
  @color(1, 1, 1, 1)           color: vec4<f32>,
  @color(0.2353, 0.549, 1, 1)  glowColor: vec4<f32>,
  @range(0, 1, 0.001, 1)       alpha: f32,
  @range(0, 1, 0.001, 0.5)     glow: f32,
  @range(0, 5, 0.01, 0)        seed: f32,
  @range(-999, 999, 0.01, 0)   evolution: f32,
  @range(0, 1, 0.001, 1)       fill: f32,
  @range(0, 1, 0.001, 0)       maskStrength: f32,
  @range(-50, 50, 0.01, 0)     maskEvolution: f32,
  @range(0.01, 50, 0.01, 1)    maskScale: f32,
  @range(0, 5, 0.01, 0)        maskSeed: f32,
  @color(1, 0.2353, 0.8627, 1) maskColor: vec4<f32>,
  contours: f32,
  @label("Contour Count")
  @range(0, 200, 0.1, 20)      count: f32,
  @label("Contour Phase")
  @range(-999, 999, 0.01, 0)   phase: f32,
  @range(-3600, 3600, 0.5, 0)  contourAngle: f32,
  layerRect: vec4<f32>,
  @auto passindex: f32,
};
@group(0) @binding(6) var<uniform> _uniform0 : Knobs;
@group(0) @binding(1) var image_Sampler: sampler;
@group(0) @binding(0) var image_Texture: texture_2d<f32>;
@group(0) @binding(3) var h__Sampler: sampler;
@group(0) @binding(2) var h__Texture: texture_2d<f32>;
@group(0) @binding(5) var blurPicture_Sampler: sampler;
@group(0) @binding(4) var blurPicture_Texture: texture_2d<f32>;
fn layerAt__f2() -> vec2<f32> {
  {
    return select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0));
  }
}
fn gauss__h4f2f2i(p: vec2<f32>, by: vec2<f32>, R_from: i32) -> vec4<f32> {
  {
    let sigma: f32 = max(_uniform0.blur, 0.0) * 0.333333343;
    if sigma < 0.5 {
      var _skTemp1: vec4<f32>;
      if R_from == 0 {
        _skTemp1 = textureSample(image_Texture, image_Sampler, p / _uniform0.resolution);
      } else {
        _skTemp1 = textureSample(h__Texture, h__Sampler, p / _uniform0.resolution);
      }
      return _skTemp1;
    }
    var _0_all: vec4<f32> = vec4<f32>(0.0);
    var weight: f32 = 0.0;
    {
      var i: i32 = -96;
      for (; i <= 96; i = i + i32(1)) {
        {
          let x: f32 = f32(i);
          if abs(x) > (3.0 * sigma) {
            continue;
          }
          let w: f32 = exp((-x * x) / ((2.0 * sigma) * sigma));
          var _skTemp2: vec4<f32>;
          if R_from == 0 {
            _skTemp2 = textureSample(image_Texture, image_Sampler, (p + by * x) / _uniform0.resolution);
          } else {
            _skTemp2 = textureSample(h__Texture, h__Sampler, (p + by * x) / _uniform0.resolution);
          }
          let c: vec4<f32> = _skTemp2;
          _0_all = _0_all + vec4<f32>(vec4<f32>(c) * w);
          weight = weight + w;
        }
      }
    }
    return vec4<f32>(vec4<f32>(_0_all) / weight);
  }
}
fn hash13_ff3(_skParam0: vec3<f32>) -> f32 {
  var p = _skParam0;
  {
    p = fract(p * 0.1031);
    p = p + dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
  }
}
fn vnoise_ff3(p: vec3<f32>) -> f32 {
  {
    let i: vec3<f32> = floor(p);
    var f: vec3<f32> = fract(p);
    f = (f * f) * (3.0 - 2.0 * f);
    let a: f32 = mix(hash13_ff3(i), hash13_ff3(i + vec3<f32>(1.0, 0.0, 0.0)), f.x);
    let b: f32 = mix(hash13_ff3(i + vec3<f32>(0.0, 1.0, 0.0)), hash13_ff3(i + vec3<f32>(1.0, 1.0, 0.0)), f.x);
    let c: f32 = mix(hash13_ff3(i + vec3<f32>(0.0, 0.0, 1.0)), hash13_ff3(i + vec3<f32>(1.0, 0.0, 1.0)), f.x);
    let d: f32 = mix(hash13_ff3(i + vec3<f32>(0.0, 1.0, 1.0)), hash13_ff3(i + vec3<f32>(1.0)), f.x);
    return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
  }
}
fn fbm_ff3f(_skParam0: vec3<f32>, octaves: f32) -> f32 {
  var p = _skParam0;
  {
    var sum: f32 = 0.0;
    var amp: f32 = 0.5;
    var norm: f32 = 0.0;
    {
      var i: i32 = 0;
      for (; i < 6; i = i + i32(1)) {
        {
          if f32(i) >= octaves {
            break;
          }
          sum = sum + amp * vnoise_ff3(p);
          norm = norm + amp;
          amp = amp * 0.55;
          p = vec3<f32>(p.xy * 2.07 + 13.1, p.z * 1.5 + 2.3);
        }
      }
    }
    var _skTemp3: f32;
    if norm > 0.0 {
      _skTemp3 = sum / norm;
    } else {
      _skTemp3 = 0.5;
    }
    return _skTemp3;
  }
}
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let src: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    let reach: f32 = max(_uniform0.blur, 1.0);
    let octaves: f32 = clamp(2.0 + _uniform0.detail * 0.5, 1.0, 6.0);
    let q: vec3<f32> = vec3<f32>((coord * (1.0 + _uniform0.detail * 0.25)) / (reach * 0.8) + _uniform0.seed * vec2<f32>(41.3, 17.9), _uniform0.evolution * 0.1);
    let warp: vec2<f32> = vec2<f32>(fbm_ff3f(q, octaves), fbm_ff3f(q + vec3<f32>(19.1, 7.3, 3.7), octaves)) - 0.5;
    let p: vec2<f32> = coord + ((warp * _uniform0.distortion) * reach) * 0.7;
    let b: f32 = f32(textureSample(blurPicture_Texture, blurPicture_Sampler, (p + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w);
    const e: f32 = 1.0;
    let g: vec2<f32> = vec2<f32>(f32(textureSample(blurPicture_Texture, blurPicture_Sampler, ((p + vec2<f32>(e, 0.0)) + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w) - f32(textureSample(blurPicture_Texture, blurPicture_Sampler, ((p - vec2<f32>(e, 0.0)) + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w), f32(textureSample(blurPicture_Texture, blurPicture_Sampler, ((p + vec2<f32>(0.0, e)) + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w) - f32(textureSample(blurPicture_Texture, blurPicture_Sampler, ((p - vec2<f32>(0.0, e)) + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w)) / (2.0 * e);
    let level: f32 = mix(0.5, 0.06, f32(_uniform0.blur > 0.0));
    let dist: f32 = abs(b - level) / max(length(g), 0.0005);
    let width: f32 = mix(0.6, reach * 0.12, clamp(_uniform0.thickness, 0.0, 1.0));
    let core: f32 = (1.0 - smoothstep(width * 0.5, width * 0.5 + 1.0, dist)) * clamp(_uniform0.alpha, 0.0, 1.0);
    let halo: f32 = exp(-dist / max(width * 2.0, 2.0)) * clamp(_uniform0.glow, 0.0, 1.0);
    var rgb: vec3<f32> = (vec3<f32>(_uniform0.color.xyz) * core) * f32(_uniform0.color.w) + (vec3<f32>(_uniform0.glowColor.xyz) * halo) * f32(_uniform0.glowColor.w);
    var a: f32 = clamp(core * f32(_uniform0.color.w) + halo * f32(_uniform0.glowColor.w), 0.0, 1.0);
    if _uniform0.maskStrength > 0.0 {
      {
        let mn: f32 = vnoise_ff3(vec3<f32>(coord / (40.0 * max(_uniform0.maskScale, 0.01)) + _uniform0.maskSeed * vec2<f32>(23.1, 51.7), _uniform0.maskEvolution * 0.2));
        let keep: f32 = smoothstep(_uniform0.maskStrength - 0.12, _uniform0.maskStrength + 0.12, mn);
        let edge: f32 = (keep * (1.0 - keep)) * 4.0;
        rgb = mix(rgb, vec3<f32>(_uniform0.maskColor.xyz) * a, vec3<f32>(edge));
        rgb = rgb * keep;
        a = a * keep;
      }
    }
    var body: vec4<f32> = src * f32(clamp(_uniform0.fill, 0.0, 1.0));
    if (_uniform0.contours > 0.5) && (src.w > 0.0) {
      {
        let ca: f32 = radians(_uniform0.contourAngle);
        let dir: vec2<f32> = vec2<f32>(-sin(ca), cos(ca));
        let h: f32 = ((dot(coord - (select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))) * 0.5, dir) / max(length(select(_uniform0.resolution, _uniform0.layerRect.zw, vec2<bool>(_uniform0.layerRect.z > 0.0))), 1.0)) * _uniform0.count + _uniform0.phase) + (1.0 - f32(textureSample(blurPicture_Texture, blurPicture_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution).w)) * 2.0;
        let line: f32 = 1.0 - smoothstep(0.0, 0.12, abs(fract(h) - 0.5) * 2.0 - 0.76);
        let la: f32 = (line * f32(src.w)) * clamp(_uniform0.alpha, 0.0, 1.0);
        body = vec4<f32>(vec3<f32>(vec3<f32>(body.xyz) * (1.0 - la) + vec3<f32>(_uniform0.color.xyz) * la), max(body.w, f32(la)));
      }
    }
    let edgeLight: vec4<f32> = vec4<f32>(vec3<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0))), f32(a));
    let outA: f32 = body.w + edgeLight.w * (1.0 - body.w);
    return vec4<f32>(min(body.xyz + edgeLight.xyz, vec3<f32>(outA)), outA);
  }
}
fn _skslMain(_stageIn: FSIn, _stageOut: ptr<function, FSOut>) {
  {
    var _skTemp4: vec4<f32>;
    if _uniform0.passindex < 0.5 {
      _skTemp4 = gauss__h4f2f2i(_stageIn.sk_FragCoord.xy, vec2<f32>(1.0, 0.0), 0);
    } else {
      var _skTemp5: vec4<f32>;
      if _uniform0.passindex < 1.5 {
        _skTemp5 = gauss__h4f2f2i(_stageIn.sk_FragCoord.xy, vec2<f32>(0.0, 1.0), 1);
      } else {
        _skTemp5 = effect__h4f2(_stageIn.sk_FragCoord.xy - layerAt__f2());
      }
      _skTemp4 = _skTemp5;
    }
    (*_stageOut).sk_FragColor = _skTemp4;
  }
}
@fragment fn main(_stageIn: FSIn) -> FSOut {
  var _stageOut: FSOut;
  _skslMain(_stageIn, &_stageOut);
  return _stageOut;
}

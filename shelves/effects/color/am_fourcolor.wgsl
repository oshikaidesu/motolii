// Four-Color Gradient: AbsentMotion's fourcolor (Apache-2.0, Copyright 2026 The AbsentMotion authors, github.com/Comett1225/AbsentMotion), its SkSL made WGSL by Skia's skslc (shelves/effects/sources/from_absent.py)
// --label:Color
// --about:Blends four colors placed at four points (in pixels from the layer's center) over the layer.
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
  @label("Color 1")
  @color(1, 0.2353, 0.4314, 1) color1: vec4<f32>,
  @label("Point 1")
  @range(-5000, 5000, 1, -400, -400) point1: vec2<f32>,
  @label("Color 2")
  @color(1, 0.7843, 0.2353, 1) color2: vec4<f32>,
  @label("Point 2")
  @range(-5000, 5000, 1, 400, -400) point2: vec2<f32>,
  @label("Color 3")
  @color(0.2353, 0.7843, 1, 1) color3: vec4<f32>,
  @label("Point 3")
  @range(-5000, 5000, 1, 400, 400) point3: vec2<f32>,
  @label("Color 4")
  @color(0.4314, 0.2353, 1, 1) color4: vec4<f32>,
  @label("Point 4")
  @range(-5000, 5000, 1, -400, 400) point4: vec2<f32>,
  @range(0, 1, 0.01, 1)        softness: f32,
  @range(0, 1, 0.01, 0.7)      opacity: f32,
  @range(0, 1, 0.01, 0)        blend: f32,
  corner: f32,
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
fn blendWith_f3ff3f3(m: f32, b: vec3<f32>, s: vec3<f32>) -> vec3<f32> {
  {
    if m < 0.5 {
      return s;
    }
    if m < 1.5 {
      return b * s;
    }
    if m < 2.5 {
      return (b + s) - b * s;
    }
    if m < 3.5 {
      return mix((2.0 * b) * s, 1.0 - (2.0 * (1.0 - b)) * (1.0 - s), step(vec3<f32>(0.5), b));
    }
    if m < 4.5 {
      {
        let d: vec3<f32> = mix(sqrt(b), ((16.0 * b - 12.0) * b + 4.0) * b, step(b, vec3<f32>(0.25)));
        return mix(b - ((1.0 - 2.0 * s) * b) * (1.0 - b), b + (2.0 * s - 1.0) * (d - b), step(vec3<f32>(0.5), s));
      }
    }
    if m < 5.5 {
      return mix((2.0 * b) * s, 1.0 - (2.0 * (1.0 - b)) * (1.0 - s), step(vec3<f32>(0.5), s));
    }
    if m < 6.5 {
      return min(b + s, vec3<f32>(1.0));
    }
    if m < 7.5 {
      return min(b, s);
    }
    if m < 8.5 {
      return max(b, s);
    }
    if m < 9.5 {
      return abs(b - s);
    }
    if m < 10.5 {
      return min(b / max(1.0 - s, vec3<f32>(0.0001)), vec3<f32>(1.0));
    }
    return 1.0 - min((1.0 - b) / max(s, vec3<f32>(0.0001)), vec3<f32>(1.0));
  }
}
fn effect__h4f2(coord: vec2<f32>) -> vec4<f32> {
  {
    let c: vec4<f32> = textureSample(image_Texture, image_Sampler, (coord + (select(vec2<f32>(0.0), _uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution);
    if c.w <= 0.0 {
      return c;
    }
    let base: vec3<f32> = vec3<f32>(c.xyz) / f32(c.w);
    let p: vec2<f32> = coord - 0.5 * layerSize__f2();
    let unit: f32 = max(max(layerSize__f2().x, layerSize__f2().y), 1.0);
    let reach: vec2<f32> = (0.5 * layerSize__f2()) * _uniform0.corner;
    let q1: vec2<f32> = _uniform0.point1 + vec2<f32>(-reach.x, -reach.y);
    let q2: vec2<f32> = _uniform0.point2 + vec2<f32>(reach.x, -reach.y);
    let q3: vec2<f32> = _uniform0.point3 + vec2<f32>(reach.x, reach.y);
    let q4: vec2<f32> = _uniform0.point4 + vec2<f32>(-reach.x, reach.y);
    let power: f32 = 2.0 + 6.0 * (1.0 - clamp(_uniform0.softness, 0.0, 1.0));
    let w1: f32 = pow(max(distance(p, q1) / unit, 0.001), -power);
    let w2: f32 = pow(max(distance(p, q2) / unit, 0.001), -power);
    let w3: f32 = pow(max(distance(p, q3) / unit, 0.001), -power);
    let w4: f32 = pow(max(distance(p, q4) / unit, 0.001), -power);
    let g: vec4<f32> = (((w1 * vec4<f32>(_uniform0.color1) + w2 * vec4<f32>(_uniform0.color2)) + w3 * vec4<f32>(_uniform0.color3)) + w4 * vec4<f32>(_uniform0.color4)) / (((w1 + w2) + w3) + w4);
    let rgb: vec3<f32> = mix(base, clamp(blendWith_f3ff3f3(_uniform0.blend, base, g.xyz), vec3<f32>(0.0), vec3<f32>(1.0)), vec3<f32>(clamp(_uniform0.opacity, 0.0, 1.0) * g.w));
    return vec4<f32>(vec3<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0))) * c.w, c.w);
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

// AudioLink Pulse: VRChat AudioLink-style 1-pass audio-reactive radial pulse and shimmer using Motolii's stage-shared 128x8 AudioLink bus texture.
// --label:Stylize
// --about:Pulses color, radial bass waves, and beat highlights in sync with the stage's shared AudioLink audio bus (no per-layer audio wiring required).
// --sound@audioLink:AudioLink,audiolink,128
// --pad:0
// --bypass:intensity
// --track@intensity:Intensity,0,2,0.8,0.01
// --track@waveSpeed:Wave Spread,0.2,4,1.2,0.01
// --track@bandMix:Bass / Treble,0,1,0.35,0.01
// --color@pulseColor:Pulse Color,4ae8ff

struct Knobs {
  resolution: vec2f,
  time: f32,
  intensity: f32,
  waveSpeed: f32,
  bandMix: f32,
  pulseColor: vec4f,
};

@group(0) @binding(0) var image: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var audioLink: texture_2d<f32>;
@group(0) @binding(3) var audioSamp: sampler;
@group(0) @binding(4) var<uniform> k: Knobs;

// Samples one row of Motolii's shared 128x8 AudioLink texture:
//   row 0..3: Bass / Low-Mid / High-Mid / Treble history (x=0 now -> x=1 past)
//   row 4: 128-bin live FFT | row 5: waveform | row 6: RMS | row 7: beat pulse
fn al_read(row: f32, x: f32) -> f32 {
  return textureSampleLevel(audioLink, audioSamp, vec2f(clamp(x, 0.0, 1.0), (row + 0.5) / 8.0), 0.0).r;
}

@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let c = textureSampleLevel(image, near, uv, 0.0);
  if (c.a <= 0.001) { return vec4f(0.0); }
  let rgb = c.rgb / c.a;

  // Radial distance from layer center drives temporal lookup into bass history.
  let d = length((uv - vec2f(0.5)) * 2.0);
  let histX = clamp(d * 0.35 / max(k.waveSpeed, 0.05), 0.0, 1.0);
  let bassWave = al_read(0.0, histX);
  let treble = al_read(3.0, histX * 0.5);
  let beat = al_read(7.0, histX * 0.4);
  let pulse = mix(bassWave, treble, k.bandMix) * 0.75 + beat * 0.55;

  let lit = rgb + k.pulseColor.rgb * (pulse * k.intensity * 0.65);
  return vec4f(clamp(lit, vec3f(0.0), vec3f(1.0)) * c.a, c.a);
}

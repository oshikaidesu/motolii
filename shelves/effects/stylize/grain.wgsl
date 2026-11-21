// Grain: a thing's see-through turned to grains, as a riso print's grainy gradient: each point wholly there or wholly not, as likely as it was there (a colour to clear down a ramp becomes grains thinning out)
// --label:Film
// --alpha (on a thing: its own see-through is what it lays, the grains)

struct Knobs {
  @label("Grain size")
  @range(1, 12, 0.1, 2)        size: f32,
  @range(0, 100, 1, 0)         seed: f32,
}

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;

fn hash(p: vec2f) -> f32 {
    return fract(sin(dot(p, vec2f(12.9898, 78.233))) * 43758.5453);
}

@fragment fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    let c = textureSampleLevel(picture, near, uv, 0.0);
    let cell = floor(frag.xy / max(knobs.size, 1.0));
    let r = hash(cell + vec2f(knobs.seed * 13.1, knobs.seed * 7.7));
    if (c.a < 1e-3 || c.a <= r) { return vec4f(0.0); }
    return vec4f(c.rgb / c.a, 1.0);
}

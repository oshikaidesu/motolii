// Fine Grain: a fine grain of light over everything, as film or a print's paper gives it (the grainy blur's grain): as
// --label:Film
// large on every picture size, weighed by how light each place is, and still, boiling every frame, or every few

struct Knobs {
  @range(0, 1, 0.001, 0.16)    amount: f32,
  @range(0.5, 4, 0.01, 1)      size: f32,
  @label("Boil every (frames; 0 still)")
  @range(0, 12, 1, 2)          every: f32,
  @range(0, 2, 0.01, 1)        shadows: f32,
  @range(0, 2, 0.01, 1)        mids: f32,
  @range(0, 2, 0.01, 0.45)     highlights: f32,
  @range(0, 1, 0.01, 0)        colour: f32,
  @auto frame: f32,
  @auto resolution: vec2f,
}

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> k: Knobs;

fn hash(p: vec3f) -> f32 {
    return fract(sin(dot(p, vec3f(12.9898, 78.233, 37.719))) * 43758.5453);
}
fn grain(cell: vec2f, seed: f32) -> f32 {   // (near a bell, from two evens)
    return (hash(vec3f(cell, seed)) + hash(vec3f(cell + 17.3, seed + 3.1))) - 1.0;
}

@fragment fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    let c = textureSampleLevel(picture, near, uv, 0.0);
    let px = max(k.size * k.resolution.y / 1080.0, 0.5);   // (as large on a 4K picture as on a 1080 one)
    let cell = floor(frag.xy / px);
    let seed = select(0.0, floor(k.frame / max(k.every, 1.0)), k.every >= 0.5);
    let l = dot(c.rgb / max(c.a, 1e-4), vec3f(0.2126, 0.7152, 0.0722));
    let w = select(mix(k.mids, k.highlights, smoothstep(0.5, 1.0, l)), mix(k.shadows, k.mids, smoothstep(0.0, 0.5, l)), l < 0.5);
    let g = vec3f(grain(cell, seed), grain(cell, seed + 11.0), grain(cell, seed + 23.0));
    let n = mix(vec3f(g.x), g, k.colour) * k.amount * w;
    return vec4f(max(c.rgb + n * c.a, vec3f(0.0)), c.a);
}

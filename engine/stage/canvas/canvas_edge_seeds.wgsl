// Edge seeds: each pixel's sub-pixel delta to the nearest edge of the glyph's
// coverage, found from Sobel gradient. Pixels fully outside the glyph get an
// "infinite" inward marker (except at the texture rim), fully inside get an
// infinite outward marker. The inward / outward deltas are packed into xy and
// zw of the result. Read by canvas_edge_flood.wgsl.
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
fn sample(p: vec2i) -> f32 {
    if (any(p < vec2i(0)) || any(p >= vec2i(textureDimensions(sourceTexture)))) { return 1.0; }
    return 1.0 - textureLoad(sourceTexture, p, 0).a;
}
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    let pos = vec2i(frag.xy);
    let coverage = sample(pos);
    let last = vec2i(textureDimensions(sourceTexture)) - vec2i(1);
    let tl = sample(pos + vec2i(-1, -1)); let tc = sample(pos + vec2i(0, -1)); let tr = sample(pos + vec2i(1, -1));
    let ml = sample(pos + vec2i(-1, 0)); let mr = sample(pos + vec2i(1, 0));
    let bl = sample(pos + vec2i(-1, 1)); let bc = sample(pos + vec2i(0, 1)); let br = sample(pos + vec2i(1, 1));
    let g = vec2f((tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl), (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr));
    var delta = vec2f(0.0);
    if (length(g) > 1e-4) { delta = -g / length(g) * (coverage - 0.5); }
    var inward = delta;
    if (coverage <= 0.1) {   // (bevy's is 0, no seam in its outlines; a glyph's own, a hair under full, is not its edge. A sourceTexture's rim is: it stops there)
        inward = vec2f(4096.0);
        if (any(pos == vec2i(0)) || any(pos == last)) { inward = vec2f(0.0); }
    }
    var outward = delta;
    if (coverage >= 0.9) { outward = vec2f(4096.0); }
    return vec4f(inward, outward);
}

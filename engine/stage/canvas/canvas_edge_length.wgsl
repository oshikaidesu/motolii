// Edge length: packs the signed distance to the nearest glyph edge into a
// single-channel texture. Reads the flooded inward (xy) and outward (zw)
// deltas and takes |inward| - |outward|, then blurs the result through a 7x7
// Gaussian (every other pixel: a slanted edge turns in steps, and the mirror
// shows every one).
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    let last = vec2i(textureDimensions(sourceTexture)) - vec2i(1);
    let w = array<f32, 7>(1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);   // (a Gaussian across 13 points, every other one: the way to a slanted edge turns in steps, and a mirror shows every one)
    var r = 0.0;
    for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
            let p = vec2i(frag.xy) + 2 * vec2i(x - 3, y - 3);
            let clamped = clamp(p, vec2i(0), last);
            let seen = textureLoad(sourceTexture, clamp(2 * clamped - p, vec2i(0), last), 0);
            var length_at = length(seen.xy) - length(seen.zw);
            if (any(p != clamped)) { length_at = -length_at; }   // (past the sourceTexture's rim, its own turned over: it still comes down to 0 there)
            r += w[x] * w[y] * length_at;
        }
    }
    return vec4f(r / 4096.0, 0.0, 0.0, 1.0);
}

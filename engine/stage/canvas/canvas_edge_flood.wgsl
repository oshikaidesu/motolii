// Edge flood: a Jump-Flooding pass. Each pixel checks its 8 neighbours at
// stride `step_length` and keeps the shortest delta to the nearest edge
// (inward in xy, outward in zw). Run once per halving step_length, so a
// radius-R distance field completes in log2(R) passes.
struct Parameters { step_length: f32, a: f32, b: f32, c: f32 };
@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var near: sampler;
@group(0) @binding(2) var<uniform> instance: Parameters;
@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    let dims = vec2i(textureDimensions(screen_texture));
    let step = i32(instance.step_length);
    let pos = vec2i(frag.xy);
    let own = textureLoad(screen_texture, pos, 0);
    var result = own.xy;
    var closest_dist = length(result);
    var outer = own.zw;
    var closest_out = length(outer);
    for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) { continue; }
            let offset = vec2i(dx * step, dy * step);
            let neighbour_coord = pos + offset;
            if (any(neighbour_coord < vec2i(0)) || any(neighbour_coord >= dims)) { continue; }
            let seen = textureLoad(screen_texture, neighbour_coord, 0);
            let delta = seen.xy + vec2f(offset);
            let dist = length(delta);
            if (dist < closest_dist) { closest_dist = dist; result = delta; }
            let out_delta = seen.zw + vec2f(offset);
            let out_dist = length(out_delta);
            if (out_dist < closest_out) { closest_out = out_dist; outer = out_delta; }
        }
    }
    return vec4f(result, outer);
}

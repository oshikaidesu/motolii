#include "stage/canvas/canvas_edge.h"

#include <algorithm>
#include <array>
#include <map>

#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include "gpu/screen_interop.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace {

const char* const edge_seeds_wgsl = R"(
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
)";
const char* const edge_flood_wgsl = R"(
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
)";
const char* const edge_length_wgsl = R"(
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
)";

}  // namespace

void edge_make(Stage& s, Canvas2D* d, uint32_t w, uint32_t h) {
    for (int k = 0; k < 3; k++) {
        d->edge[k] = Texture::Builder().width(w).height(h).levels(1).format(Texture::InternalFormat::RGBA16F).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*s.engine);
        d->edgeInto[k] = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, d->edge[k]).build(*s.engine);
    }
    d->edgeW = w, d->edgeH = h;
}
void edge_off(Stage& s, Canvas2D* d) {
    s.once.erase(d);
    for (int k = 0; k < 3; k++) if (d->edge[k]) s.engine->destroy(d->edgeInto[k]), s.engine->destroy(d->edge[k]), d->edge[k] = nullptr;
}
void edge_ask(Stage& s, Canvas2D* d, int reach) {
    d->stale = false;
    s.once[d] = [&s, d, reach] {
        static std::map<Engine*, std::array<interop::Screen*, 3>> interops;
        auto& built = interops[s.engine];
        if (!built[0]) built = {interop::screen(s.engine, "edge seeds", edge_seeds_wgsl, 0), interop::screen(s.engine, "edge flood", edge_flood_wgsl, 16), interop::screen(s.engine, "edge length", edge_length_wgsl, 0)};
        if (!built[0] || !built[1] || !built[2]) return;
        interop::draw(s.engine, built[0], d->texture, d->edgeInto[0], d->edgeW, d->edgeH);
        int front = 0, pass = 0, step = 1;
        while (step < std::max(reach, 8)) step *= 2;   // (8: the last pass reads 6 points round each, outside too)
        for (; step >= 1; step /= 2, pass++) {
            const float k[4] = {(float)step, 0.f, 0.f, 0.f};
            interop::parameters(s.engine, built[1], k, sizeof k, pass);
            Texture* from = d->edge[front];
            interop::draw(s.engine, built[1], &from, d->edgeInto[!front], d->edgeW, d->edgeH, pass);
            front = !front;
        }
        interop::draw(s.engine, built[2], d->edge[front], d->edgeInto[2], d->edgeW, d->edgeH);
    };
}

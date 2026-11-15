// Noise: smooth interpolation between hashed values at whole positions along
// time. Each copy starts further along in the sequence by `k.apart * 4`. The
// hash is the one used by random.js, so the same seed and the same integer
// give the same value. (Cavalry's Noise behaviour, smoothed with Perlin's
// 3t^2 - 2t^3 fade.)
//
// The hash follows the engine's uint32 mixer bit for bit: a 32-bit multiply
// through Math.imul, shifts with `>>>` to stay unsigned. The final divide by
// 2^32 - 1 matches engine/document/evaluate/relations.cpp.
function hash(seed, k) {
    let h = Math.imul(seed | 0, 0x9E3779B9 | 0) ^
            Math.imul(k | 0, 0x85EBCA6B | 0) ^ 0xC2B2AE35;
    h = h ^ (h >>> 16);
    h = Math.imul(h, 0x7FEB352D);
    h = h ^ (h >>> 15);
    h = Math.imul(h, 0x846CA68B);
    h = h ^ (h >>> 16);
    return (h >>> 0) / 4294967295;
}
export function at(copy, n, t, k) {
    const x = k.frequency * t + k.offset + k.apart * copy * 4;
    const f = Math.floor(x);
    const e = (x - f) * (x - f) * (3 - 2 * (x - f));
    return hash(k.seed, f | 0) * (1 - e) + hash(k.seed, (f | 0) + 1) * e;
}

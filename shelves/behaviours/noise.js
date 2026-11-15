// Noise: smooth interpolation between hashed values at whole positions along
// time. Each copy starts further along in the sequence by `k.apart * 4`.
// (Cavalry's Noise behaviour, smoothed with Perlin's 3t^2 - 2t^3 fade.)
//
// The hash is the uint32 mixer that random.js uses too; see that file. The
// engine's doc_behaviour_at uses the same mixer in C++ so values are bit for
// bit identical.
//
// Called once per frame per behaviour layer; see stagger.js for the batching
// contract.
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
export function all(n, t, k) {
    const out = new Float64Array(n);
    const base = k.frequency * t + k.offset;
    const step = k.apart * 4;
    for (let i = 0; i < n; i++) {
        const x = base + step * i;
        const f = Math.floor(x);
        const e = (x - f) * (x - f) * (3 - 2 * (x - f));
        out[i] = hash(k.seed, f | 0) * (1 - e) + hash(k.seed, (f | 0) + 1) * e;
    }
    return out;
}

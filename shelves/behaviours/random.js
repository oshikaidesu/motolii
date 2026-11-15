// Random: a fixed value for each copy, drawn from the seed. The same seed and
// the same copy give the same value. (Cavalry's Random behaviour.)
//
// The hash is the uint32 mixer that noise.js uses too; see that file.
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
    for (let i = 0; i < n; i++) out[i] = hash(k.seed, i + 1);
    return out;
}

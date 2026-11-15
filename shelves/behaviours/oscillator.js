// Oscillator: a sine wave over time, mapped to the range 0 to 1. `k.frequency`
// is how many cycles per second, `k.offset` shifts the phase in turns, and
// `k.apart` is how much each copy's phase differs from the one before (also
// in turns). (Cavalry's Oscillator behaviour.)
//
// Called once per frame per behaviour layer; see stagger.js for the batching
// contract.
const TAU = 2 * Math.PI;
export function all(n, t, k) {
    const out = new Float64Array(n);
    const base = TAU * (k.frequency * t + k.offset);
    const step = TAU * k.apart;
    for (let i = 0; i < n; i++) out[i] = 0.5 + 0.5 * Math.sin(base + step * i);
    return out;
}

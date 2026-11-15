// Oscillator: a sine wave over time, mapped to the range 0 to 1. `k.frequency`
// is how many cycles per second, `k.offset` shifts the phase in turns, and
// `k.apart` is how much each copy's phase differs from the one before (also in
// turns). (Cavalry's Oscillator behaviour.)
const TAU = 2 * Math.PI;
export function at(copy, n, t, k) {
    return 0.5 + 0.5 * Math.sin(TAU * (k.frequency * t + k.offset + k.apart * copy));
}

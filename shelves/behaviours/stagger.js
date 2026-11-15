// Stagger: the copy's position in the order, from 0 for the first copy to 1
// for the last, shifted by the offset. The same curve of its range is laid
// out across the copies, so every member ends somewhere between minimum and
// maximum. (Cavalry's Stagger behaviour.)
//
// Called once per frame per behaviour layer with the number of copies n.
// Returns a Float64Array of u values for copies 0 .. n - 1, so the C++ side
// makes one QuickJS call per frame instead of one per copy. engine/document/
// evaluate/relations.cpp reads out[copy] after the single call.
export function all(n, t, k) {
    const out = new Float64Array(n);
    for (let i = 0; i < n; i++) {
        const u = (n > 1 ? i / (n - 1) : 0) + k.offset;
        out[i] = u < 0 ? 0 : u > 1 ? 1 : u;
    }
    return out;
}

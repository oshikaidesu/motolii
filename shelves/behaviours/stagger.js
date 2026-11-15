// Stagger: the copy's position in the order, from 0 for the first copy to 1
// for the last, shifted by the offset. The same curve of its range is laid out
// across the copies, so every member ends somewhere between minimum and
// maximum. (Cavalry's Stagger behaviour.)
export function at(copy, n, t, k) {
    const u = (n > 1 ? copy / (n - 1) : 0) + k.offset;
    return u < 0 ? 0 : u > 1 ? 1 : u;
}

// Wave: each copy moves, turns and swells in a wave, each a little behind the one before (the engine's own wave, engine/document/evaluate/place.h, until 2026-11-10: its formula as it was there)
// (Cavalry's oscillator, as the engine's comment had it: so far across, up and towards the eye (units of the stage), so far
// turned (degrees), so much larger (a share), so many times a second, each copy so far behind the one before (turns spread
// over all). Towards the eye is a quarter round after up and down: with Up/down, round and round, a helix.
// Random: how much of the wave is a smooth noise in place of the sine (Cavalry's noise; 1 all noise). Blob: that noise read
// where each copy lies, so near ones move alike: how large its blobs are, in units of the stage; 0: each copy its own.
// Another Seed, another noise.)
// --track@wave_x:Sideways,-1,1,0,0.01
// --track@wave_y:Up/down,-1,1,0,0.01
// --track@wave_z:In/out,-1,1,0,0.01
// --track@wave_rotate:Swing,-90,90,0,1
// --track@wave_size:Pulse,-1,2,0,0.01
// --track@wave_speed:Speed,0,4,1,0.01
// --track@wave_phase:Ripple,-4,4,0,0.01
// --group:Noise
// --track@wave_noise:Random,0,1,0,0.01
// --track@wave_noise_scale:Blob,0,3,0,0.01
// --group
// --track@wave_seed:Seed,0,9999,0,1

// Where a copy lies for Blob is each()'s fifth, `at`: where the layer's script and the expressions before this one lay it
// (so this goes after what lays the copies out, the Repeater). t is the layer's own clock: a layer that begins later is as
// far behind in the wave, and a Delay of the layer's copies does not hold the wave back (Ripple does that).
const TAU = 2 * Math.PI;

// -1 to 1 at a corner of the lattice: a 32-bit hash of the seed, the corner and, where each copy has a noise of its own, the copy.
function corner(seed, i, j, k, own) {
  let h = Math.imul(seed, 0x9E3779B9) ^ Math.imul(i, 0x85EBCA6B) ^ Math.imul(j, 0x27D4EB2D) ^ Math.imul(k, 0xC2B2AE35) ^ own;
  h ^= h >>> 16, h = Math.imul(h, 0x7FEB352D), h ^= h >>> 15, h = Math.imul(h, 0x846CA68B), h ^= h >>> 16;
  return (h >>> 0) / 2147483647.5 - 1;
}

function each(i, n, t, k, at) {
  // (a whole number of times round in the document, k.round seconds: its film loops)
  const turns = Math.round(k.wave_speed * k.round), speed = turns > 0 ? turns / k.round : k.wave_speed;
  const angle = TAU * (speed * t - (k.wave_phase * i) / n);
  let w = Math.sin(angle);
  if (k.wave_noise > 0) {   // (random values at the corners of a lattice, eased between)
    const scale = k.wave_noise_scale, seed = Math.trunc(k.wave_seed), own = scale > 0 ? 0 : Math.imul(i + 1, 0x165667B1);
    const ring = turns > 0 ? turns * 2 : 0;   // (round in time as the wave is: the lattice's last row is its first)
    const px = scale > 0 ? at.x / scale : 0, py = scale > 0 ? at.y / scale : 0, pz = speed * t * 2;
    const fx = Math.floor(px), fy = Math.floor(py), fz = Math.floor(pz);
    const eased = (u) => u * u * (3 - 2 * u), ex = eased(px - fx), ey = eased(py - fy), ez = eased(pz - fz);
    let sum = 0;
    for (let c = 0; c < 8; ++c) {
      let row = fz + ((c >> 2) & 1);
      if (ring > 0) row = ((row % ring) + ring) % ring;
      sum += corner(seed, fx + (c & 1), fy + ((c >> 1) & 1), row, own) * (c & 1 ? ex : 1 - ex) * (c & 2 ? ey : 1 - ey) * (c & 4 ? ez : 1 - ez);
    }
    w = w * (1 - k.wave_noise) + k.wave_noise * sum;
  }
  return { x: k.wave_x * w, y: k.wave_y * w, z: k.wave_z * Math.cos(angle), rotate: w * k.wave_rotate, size: Math.max(0, 1 + w * k.wave_size) };
}

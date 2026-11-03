// Each goes after its own place on a spring, past it and back: Cavalry's Spring (Mass, Damping, Speed Limit) and MASH's,
// for the moves its keys give it. Out of its Falloff each goes back under it.
// --track@mass:Mass,.05,10,1,0.01
// --track@damping:Damping,0,30,4,0.01
// --track@limit:Speed Limit,0,60,60,0.1
function relate(things, t, k, was) {
  return things.map(a => {
    const o = was ? was[a.i] : { px: a.x, py: a.y, pz: a.z, vx: 0, vy: 0, vz: 0 };
    const v = createVector(o.vx, o.vy, o.vz).add(createVector(a.x - o.px, a.y - o.py, a.z - o.pz).mult(1 / k.mass)).mult(1 - k.damping / 60).limit(k.limit);
    const px = o.px + v.x / 60, py = o.py + v.y / 60, pz = o.pz + v.z / 60;
    return { i: a.i, px, py, pz, vx: v.x, vy: v.y, vz: v.z, x: lerp(a.x, px, a.near), y: lerp(a.y, py, a.near), z: lerp(a.z, pz, a.near) };
  });
}

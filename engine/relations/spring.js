// Each goes after its own place on a spring, past it and back: Cavalry's Spring (Mass, Damping, Speed Limit) and MASH's,
// for the moves its keys give it.
// --track@mass:Mass,.05,10,1,0.01
// --track@damping:Damping,0,30,4,0.01
// --track@limit:Speed Limit,0,60,60,0.1
function relate(things, t, k, was) {
  return things.map(a => {
    const o = was ? was[a.i] : { x: a.x, y: a.y, z: a.z, vx: 0, vy: 0, vz: 0 };
    const v = createVector(o.vx, o.vy, o.vz).add(createVector(a.x - o.x, a.y - o.y, a.z - o.z).mult(1 / k.mass)).mult(1 - k.damping / 60).limit(k.limit);
    return { i: a.i, x: o.x + v.x / 60, y: o.y + v.y / 60, z: o.z + v.z / 60, vx: v.x, vy: v.y, vz: v.z };
  });
}

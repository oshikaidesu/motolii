// Each goes after where it would be left alone on a spring, past it and back: Cavalry's Spring (Mass, Damping, Speed
// Limit) and MASH's, for the moves its keys give it.
// --track@mass:Mass,.05,10,1,0.01
// --track@damping:Damping,0,30,4,0.01
// --track@limit:Speed Limit,0,60,60,0.1
function force(things, t, k) {   // (plain numbers, as flock.js)
  const pull = 1 / (60 * k.mass), keep = 1 - k.damping / 60, most = k.limit / 60;
  things.forEach(a => {
    a.vx = (a.vx + (a.home.x - a.x) * pull) * keep, a.vy = (a.vy + (a.home.y - a.y) * pull) * keep, a.vz = (a.vz + (a.home.z - a.z) * pull) * keep;
    const s = sqrt(a.vx * a.vx + a.vy * a.vy + a.vz * a.vz);
    if (s > most) a.vx *= most / s, a.vy *= most / s, a.vz *= most / s;
  });
}

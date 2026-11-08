// A flock: Reynolds' Boids (1986, red3d.com/cwr/boids), as MASH's Flight. Each steers by those it can see: away from the
// closest, along their heading, toward their middle. Steering is what it wants less what it does, as his 1999 paper
// says. Home pulls each back to where it would be left alone, so they stay on the stage.
// --track@speed:Speed,0,6,1.6,0.01
// --track@force:Force,0,20,5,0.01
// --track@sight:Sight,0,4,1.2,0.01
// --track@apart:Apart,0,4,1.6,0.01
// --track@along:Along,0,4,1,0.01
// --track@together:Together,0,4,1,0.01
// --track@home:Home,0,4,.6,0.01
// --track@face:Face,0,1,0,0.01
function setup() { noiseSeed(7); }
function force(things, t, k) {   // (plain numbers, not p5's vectors: those took 17 ms a frame for 30 of them)
  things.forEach(a => {
    if (a.off) return;   // (each off its own way the first it is pushed, as his Boids start)
    const way = noise(a.i * 7.3) * TWO_PI * 4;
    a.off = true, a.vx += cos(way) * k.speed / 60, a.vy += sin(way) * k.speed / 60;
  });
  const vx = things.map(a => a.vx * 60), vy = things.map(a => a.vy * 60);
  const was = things.map((a, i) => ({ x: a.x, y: a.y, vx: vx[i], vy: vy[i] }));
  things.forEach((a, i) => {
    let ax = 0, ay = 0, lx = 0, ly = 0, mx = 0, my = 0, fx = 0, fy = 0, seen = 0;
    const toward = (u, v, weight) => {
      const l = sqrt(u * u + v * v) || 1;
      let sx = u / l * k.speed - vx[i], sy = v / l * k.speed - vy[i];
      const f = sqrt(sx * sx + sy * sy);
      if (f > k.force) sx *= k.force / f, sy *= k.force / f;
      fx += sx * weight, fy += sy * weight;
    };
    was.forEach((b, j) => {
      const dx = a.x - b.x, dy = a.y - b.y, d2 = dx * dx + dy * dy;
      if (j === i || d2 > k.sight * k.sight) return;
      const near = max(d2, 1e-4);
      ax += dx / near, ay += dy / near, lx += b.vx, ly += b.vy, mx += b.x, my += b.y, ++seen;
    });
    if (seen) toward(ax, ay, k.apart), toward(lx, ly, k.along), toward(mx / seen - a.x, my / seen - a.y, k.together);
    const hx = a.home.x - a.x, hy = a.home.y - a.y;
    toward(hx, hy, k.home * sqrt(hx * hx + hy * hy));
    let wx = vx[i] + fx / 60, wy = vy[i] + fy / 60;
    const s = sqrt(wx * wx + wy * wy);
    if (s > k.speed) wx *= k.speed / s, wy *= k.speed / s;
    a.vx = wx / 60, a.vy = wy / 60, a.rotate += k.face * degrees(atan2(wy, wx));
  });
}

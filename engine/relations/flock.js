// A flock: Reynolds' Boids (1986, red3d.com/cwr/boids), as MASH's Flight. Each steers by those it can see: away from the
// closest, along their heading, toward their middle. Steering is what it wants less what it does, as his 1999 paper
// says. Home pulls each back to its own place, so they stay on the stage.
// --track@speed:Speed,0,6,1.6,0.01
// --track@force:Force,0,20,5,0.01
// --track@sight:Sight,0,4,1.2,0.01
// --track@apart:Apart,0,4,1.6,0.01
// --track@along:Along,0,4,1,0.01
// --track@together:Together,0,4,1,0.01
// --track@home:Home,0,4,.6,0.01
// --track@face:Face,0,1,0,0.01
function setup() { noiseSeed(7); }
function relate(things, t, k, was) {   // (plain numbers, not p5's vectors: those took 17 ms a frame for 30 of them)
  const x = [], y = [], vx = [], vy = [];
  things.forEach((a, i) => {
    const o = was && was[a.i], way = o ? 0 : noise(a.i * 7.3) * TWO_PI * 4;
    x[i] = o ? o.x : a.x, y[i] = o ? o.y : a.y, vx[i] = o ? o.vx : cos(way) * k.speed, vy[i] = o ? o.vy : sin(way) * k.speed;
  });
  return things.map((a, i) => {
    let ax = 0, ay = 0, lx = 0, ly = 0, mx = 0, my = 0, fx = 0, fy = 0, seen = 0;
    const toward = (u, v, weight) => {
      const l = sqrt(u * u + v * v) || 1;
      let sx = u / l * k.speed - vx[i], sy = v / l * k.speed - vy[i];
      const f = sqrt(sx * sx + sy * sy);
      if (f > k.force) sx *= k.force / f, sy *= k.force / f;
      fx += sx * weight, fy += sy * weight;
    };
    for (let j = 0; j < x.length; ++j) {
      const dx = x[i] - x[j], dy = y[i] - y[j], d2 = dx * dx + dy * dy;
      if (j === i || d2 > k.sight * k.sight) continue;
      const near = max(d2, 1e-4);
      ax += dx / near, ay += dy / near, lx += vx[j], ly += vy[j], mx += x[j], my += y[j], ++seen;
    }
    if (seen) toward(ax, ay, k.apart), toward(lx, ly, k.along), toward(mx / seen - x[i], my / seen - y[i], k.together);
    const hx = a.x - x[i], hy = a.y - y[i];
    toward(hx, hy, k.home * sqrt(hx * hx + hy * hy));
    let wx = vx[i] + fx / 60, wy = vy[i] + fy / 60;
    const s = sqrt(wx * wx + wy * wy);
    if (s > k.speed) wx *= k.speed / s, wy *= k.speed / s;
    return { i: a.i, x: x[i] + wx / 60, y: y[i] + wy / 60, vx: wx, vy: wy, rotate: a.rotate + k.face * degrees(atan2(wy, wx)) };
  });
}

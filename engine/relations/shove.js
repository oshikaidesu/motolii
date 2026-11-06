// They wander, each by p5's noise, and shove each other so that none lies on another:
// where one stands hangs on where all the others stand.
// --about:They wander and shove each other so that none lies on another
// --track@amount:Amount,0,4,1.6,0.01
// --track@speed:Speed,0,3,.35,0.01
// --track@room:Room,0,1,.06,0.01
function setup() { noiseSeed(7); }
function relate(things, t, k) {
  const at = things.map(a => createVector(
    a.x + (noise(a.i * 7.3, t * k.speed) - .5) * k.amount,
    a.y + (noise(a.i * 3.1 + 50, t * k.speed) - .5) * k.amount));
  for (let pass = 0; pass < 12; ++pass)
    things.forEach((a, i) => things.forEach((b, j) => {
      if (j <= i) return;
      const d = p5.Vector.sub(at[i], at[j]);
      const over = createVector((a.w + b.w) / 2 + k.room - abs(d.x), (a.h + b.h) / 2 + k.room - abs(d.y));
      if (over.x <= 0 || over.y <= 0) return;
      const by = over.x < over.y ? createVector((d.x < 0 ? -1 : 1) * over.x / 2, 0) : createVector(0, (d.y < 0 ? -1 : 1) * over.y / 2);
      at[i].add(by), at[j].sub(by);
    }));
  return at.map((p, i) => ({ i, x: p.x, y: p.y }));
}

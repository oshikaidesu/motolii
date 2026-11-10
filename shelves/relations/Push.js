// Pushed out of Leader's way: a layer within Radius of the leader goes out to between 0.6 and 1 times Radius, the
// nearer ones staying the nearer, so none ends up on another. The leader is a layer, moving or not.
// --track@radius:Radius,0,2,0.5,0.01
// --picture@leader:Leader
function relate(things, t, k) {
  if (!k.leader || k.radius <= 0) return things.map(a => ({ i: a.i }));
  const lx = layerValue(k.leader, 'x', t, 0), ly = layerValue(k.leader, 'y', t, 0);
  return things.map((a, n) => {
    let dx = a.x - lx, dy = a.y - ly, far = Math.hypot(dx, dy);
    if (far >= k.radius || a.id === k.leader) return { i: a.i };
    // One exactly on the leader is pushed out the way its order says.
    if (far < 1e-6) dx = sin(TWO_PI * n / things.length), dy = cos(TWO_PI * n / things.length), far = 1;
    const out = k.radius * (0.6 + 0.4 * far / k.radius);
    return { i: a.i, x: lx + dx / far * out, y: ly + dy / far * out };
  });
}

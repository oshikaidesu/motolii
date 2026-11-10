// A ring: the layers round a middle, the first at the top and the rest clockwise, Radius from it. The middle is Centre
// or, with a Leader, Leader's place plus Centre. Offset turns the ring (1 is a whole turn); Tilt tips it back about the x
// axis, which spreads the layers in depth. Cavalry's Duplicator in its Radial distribution. Where a layer showed when it
// joined is subtracted from x and y, so one the user moved by hand stays moved by as much. Lag: each is that many seconds
// later in Strength.
// --track@radius:Radius,0,2,0.5,0.01
// --track@offset:Offset,-1,1,0,0.01
// --track@tilt:Tilt,-90,90,0,1
// --track@centre_x:Centre X,-2,2,0,0.01
// --track@centre_y:Centre Y,-2,2,0,0.01
// --picture@leader:Leader
// --track@rotate:Rotate,-360,360,0,1
// --track@rotate_y:Y Rotation,-360,360,0,1
// --track@lag:Lag,0,1,0,0.01
function relate(things, t, k) {
  const at = (name, otherwise) => k.leader ? layerValue(k.leader, name, t, otherwise) : 0;
  const cx = k.centre_x + at('x'), cy = k.centre_y + at('y'), cz = at('z'), tilt = radians(k.tilt);
  const to = (a, axis, place) => isNaN(a.from[axis]) ? place : a[axis] + place - a.from[axis];
  return things.map((a, n) => {
    const turn = TWO_PI * (k.offset + n / things.length), up = k.radius * cos(turn);
    const out = { i: a.i, x: to(a, 'x', cx + k.radius * sin(turn)), y: to(a, 'y', cy + up * cos(tilt)), rotate: a.rotate + k.rotate, rotate_y: a.rotate_y + k.rotate_y };
    if (tilt !== 0 || k.leader) out.z = cz + up * sin(tilt);   // (a ring facing the camera with no leader leaves depth alone)
    return out;
  });
}

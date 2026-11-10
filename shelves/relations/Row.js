// A row: the layers in a line, Gap apart, about a middle that is Centre or Leader's place plus Centre.
// Cavalry's Duplicator in its Linear distribution, Cinema 4D's Linear Cloner. Where a layer showed when it joined is
// subtracted, so one the user moved by hand stays moved by as much. Lag: each is that many seconds later in Strength.
// --track@gap:Gap,-1,1,0.2,0.01
// --track@centre_x:Centre X,-2,2,0,0.01
// --track@centre_y:Centre Y,-2,2,0,0.01
// --picture@leader:Leader
// --track@rotate:Rotate,-360,360,0,1
// --track@rotate_y:Y Rotation,-360,360,0,1
// --track@lag:Lag,0,1,0,0.01
function relate(things, t, k) {
  const at = name => k.leader ? layerValue(k.leader, name, t, 0) : 0;
  const cx = k.centre_x + at('x'), cy = k.centre_y + at('y');
  const to = (a, axis, place) => isNaN(a.from[axis]) ? place : a[axis] + place - a.from[axis];
  return things.map((a, n) => ({
    i: a.i,
    x: to(a, 'x', cx + k.gap * (n - (things.length - 1) / 2)),
    y: to(a, 'y', cy),
    rotate: a.rotate + k.rotate,
    rotate_y: a.rotate_y + k.rotate_y,
  }));
}

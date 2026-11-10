// Turns to face the way it is going: After Effects' Auto-Orient. The heading is the direction from where the layer is a
// moment before to where it is a moment after (a 120th of a second across; a 15th if it has not moved in that), so it
// needs nothing from the frame before. A layer standing still keeps its own turn. Offset is added to the heading, for
// artwork that does not face along x.
// --track@offset:Offset,-180,180,0,1
function relate(things, t, k) {
  const going = (a, step) => {
    const dx = layerValue(a.id, 'x', t + step, a.x) - layerValue(a.id, 'x', t - step, a.x);
    const dy = layerValue(a.id, 'y', t + step, a.y) - layerValue(a.id, 'y', t - step, a.y);
    return Math.hypot(dx, dy) > 1e-6 ? degrees(atan2(dy, dx)) : null;
  };
  return things.map(a => {
    const heading = going(a, 1 / 240) ?? going(a, 1 / 30);
    return heading === null ? { i: a.i } : { i: a.i, rotate: a.rotate + k.offset + heading };
  });
}

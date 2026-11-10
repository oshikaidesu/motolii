// Move in: the layers in an order, each coming a little after the one before (Lag, in seconds) along Strength, which the
// move keys from 1 to 0. Alight Motion's Move in. Each goes X and Y from where it is, and Spread times as far from the
// middle of where they joined (1 keeps them, 0 puts all at the middle), and Scatter further in its own fixed direction,
// turns by Rotate, and keeps Size and Opacity of its own.
// --track@x:X,-2,2,0,0.01
// --track@y:Y,-2,2,0,0.01
// --track@spread:Spread,0,3,1,0.01
// --track@scatter:Scatter,0,2,0,0.01
// --track@rotate:Rotate,-360,360,0,1
// --track@rotate_y:Y Rotation,-360,360,0,1
// --track@size:Size,0,3,1,0.01
// --track@opacity:Opacity,0,1,1,0.01
// --track@lag:Lag,0,1,0,0.01
function relate(things, t, k) {
  // The middle of where they joined, or of where they are if that is not known.
  const middle = axis => {
    const known = things.map(a => a.from[axis]).filter(v => !isNaN(v));
    const all = known.length ? known : things.map(a => a[axis]);
    return all.reduce((sum, v) => sum + v, 0) / all.length;
  };
  // A fixed number from -1 to 1 for each layer and axis, so the same scatter shows each time: the hash GLSL's fract(sin) gives.
  const scatter = (n, axis) => { const s = Math.sin((n + 1) * (axis === 'y' ? 78.233 : 12.9898)) * 43758.5453; return (s - Math.floor(s)) * 2 - 1; };
  const mid = { x: middle('x'), y: middle('y') };
  const away = (a, n, axis) => a[axis] + k[axis] + (a[axis] - mid[axis]) * (k.spread - 1) + k.scatter * scatter(n, axis);
  return things.map((a, n) => ({
    i: a.i, x: away(a, n, 'x'), y: away(a, n, 'y'),
    rotate: a.rotate + k.rotate, rotate_y: a.rotate_y + k.rotate_y, size: a.size * k.size, opacity: a.opacity * k.opacity,
  }));
}

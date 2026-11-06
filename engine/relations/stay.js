// What its Falloff has touched stays changed: Cavalry's Value Solver, Highest, with its Fade. Each is told how much the
// shape covers it now (near) and keeps the most it was ever told. Move the shape across them.
// --about:What its Falloff shape passes over stays changed
// --track@grow:Grow,0,4,1.8,0.01
// --track@turn:Turn,-360,360,0,1
// --track@lift:Lift,-2,2,0,0.01
// --track@fade:Fade,.8,1,1,0.001
function relate(things, t, k, was) {
  return things.map(a => {
    const had = max(a.near, was ? was[a.i].had * k.fade : 0);
    return { i: a.i, had, size: a.size * lerp(1, k.grow, had), rotate: a.rotate + k.turn * had, y: a.y + k.lift * had };
  });
}

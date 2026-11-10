// They fall: Gravity pulls each down (units of the stage per second per second) and a floor at Floor, which a layer stands
// on by its bottom edge, throws it back up by Bounce of the speed it hit with (0 stops it, 1 keeps all) and takes Friction
// of its sideways speed each frame it touches. A layer that is nearly still on the floor stays on it. Falling is the
// semi-implicit Euler step d3-force uses, 60 frames a second, from where the layer is when the relation starts.
// --track@gravity:Gravity,0,30,9.81,0.01
// --track@floor:Floor,-3,3,-1,0.01
// --track@bounce:Bounce,0,1,0.3,0.01
// --track@friction:Friction,0,1,0.1,0.01
function force(things, t, k) {
  const pull = k.gravity / 3600;   // (a speed is units a frame)
  things.forEach(a => {
    a.vy -= pull;
    const rest = k.floor + a.h / 2, next = a.y + a.vy;
    if (next >= rest) return;
    const up = (rest - next) * k.bounce;
    a.vy = up < 2 * pull ? rest - a.y : rest + up - a.y;
    a.vx *= 1 - k.friction;
  });
}

// A wave along the row, each up and down by where it stands.
// --track@height:Height,0,2,.45,0.01
// --track@speed:Speed,0,4,.6,0.01
function relate(things, t, k) {
  return things.map(a => ({ i: a.i, y: a.y + k.height * sin(a.x * 2 + t * k.speed * TWO_PI) }));
}

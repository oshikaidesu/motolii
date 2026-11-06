// They do not go through each other: d3-force-3d's forceCollide (MIT, third_party/js), as it is.
// --about:They do not go through each other
// --track@room:Room,0,3,1,0.01
// --track@hard:Hard,0,1,.7,0.01
const collide = d3.forceCollide();
function force(things, t, k) {
  randomSeed(7);   // (the same each time: it jiggles those exactly on top of each other)
  collide.radius(a => max(a.w, a.h) / 2 * k.room).strength(k.hard);
  collide.initialize(things, () => random(), 3);
  collide(1);
}

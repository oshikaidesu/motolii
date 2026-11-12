// Rigid Body: each letter (or copy) is a solid box that falls, lands on the other rigid bodies and piles up; Jolt Physics moves it
// --track@mass:Mass,0,10,1,0.01
// --track@gravity:Gravity,0,10,1,0.01
// --track@bounce:Bounciness,0,1,0,0.01
// --track@friction:Friction,0,1,0.2,0.01
// With Mass 0 it stays where its layer puts it, keyframes and all, and holds up or pushes the others: a floor, a wall, a hand.
// A key on Mass from 0 to 1 lets it go at that moment (Blender's "Animated").
// The labels are those of Blender's Rigid Body panel. The values go to Jolt as they are, at Jolt's own defaults: the mass in
// kilograms, mGravityFactor (1 is 9.81 m/s² downward; a metre is 100 pixels of the project), mRestitution and mFriction.
function each(i, n, t, k) {
  return { mass: k.mass, gravityFactor: k.gravity, restitution: k.bounce, friction: k.friction };
}

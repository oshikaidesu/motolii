// Wind: pushes each rigid body sideways (Wind) and up (Lift); put keys on them to let it blow and stop
// --track@wind:Wind,-50,50,0,0.1
// --track@lift:Lift,-50,50,0,0.1
// A force in newtons, given to Jolt each frame (BodyInterface::AddForce): a body of Mass 1 gains that many metres a second,
// each second. Gravity is 9.81 of them downward. It goes after Rigid Body in the layer's list; any expression may say `force`.
function each(i, n, t, k) {
  return { force: [k.wind, k.lift] };
}

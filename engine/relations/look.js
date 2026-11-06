// All turn to face the first of them: Cavalry's Look At, Cinema 4D's Target Effector, MASH's Orient.
// --about:All turn to face the first of them
// --track@offset:Offset,-180,180,0,1
function relate(things, t, k) {
  const lead = things[0];
  return things.map(a => a === lead ? { i: a.i } : { i: a.i, rotate: a.rotate + k.offset + degrees(atan2(lead.y - a.y, lead.x - a.x)) });
}

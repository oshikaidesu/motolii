// Letter: each sits on a letter of Leader, a text split into letters, where that letter is now: its CSS, its script
// and its delay taken in. The place is read by After Effects' own follow expression as it is posted, with Leader's
// layer standing for the letter; Letter counts from 1, as After Effects counts characters (textIndex). The first layer
// takes letter Letter, the next the letter after it, and so on.
// --picture@leader:Leader
// --track@letter:Letter,1,20,1,1
const follow = AE.compile(`thisComp.layer("Leader").transform.position`);
function relate(things, t, k) {
  if (!k.leader) return things.map(a => ({ i: a.i }));
  return things.map((a, n) => {
    const at = Math.round(k.letter) - 1 + n;
    const leader = { name: 'Leader', index: 1, position: u => [layerValue(k.leader, 'x', u, 0, at), layerValue(k.leader, 'y', u, 0, at)] };
    const [x, y] = AE.run(follow, { time: t, value: [a.x, a.y], comp: AE.comp({}, [leader]) });
    return { i: a.i, x, y };
  });
}

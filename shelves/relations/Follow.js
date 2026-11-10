// Follow the leader: each goes where Leader goes, later by Lag seconds for each place in the order (the first by Lag, the
// second by twice that), as in After Effects' valueAtTime(time - delay) on the leader's position. Hand to is a second
// leader, handed over to as Handed goes from 0 to 1. What the leader does after the layers joined is what they do;
// choosing the leader keeps them where they are.
// --picture@leader:Leader
// --track@lag:Lag,0,1,0.1,0.01
// --picture@hand_to:Hand to
// --track@hand:Handed,0,1,0,0.01
function relate(things, t, k) {
  if (!k.leader) return things.map(a => ({ i: a.i }));
  const hand = k.hand_to ? constrain(k.hand, 0, 1) : 0;
  return things.map((a, n) => {
    const back = t - k.lag * (n + 1), out = { i: a.i };
    ['x', 'y'].forEach(name => {
      const lead = layerValue(k.leader, name, back, 0);
      out[name] = a[name] + lead + ((k.hand_to ? layerValue(k.hand_to, name, back, 0) : lead) - lead) * hand;
    });
    return out;
  });
}

// Word after word, in reading order: each comes up and swells past its size, and what is already there leans away
// from the one coming in. A lyric's line, the user's word of 10/22: in turn is a relation.
// --track@lag:Lag,0,1,.32,0.01
// --track@rise:Rise,0,1.5,.5,0.01
// --track@lean:Lean,0,.5,.14,0.01
function relate(things, t, k) {
  const row = [...things].sort((a, b) => a.x - b.x);
  const seen = row.map((a, n) => constrain((t - n * k.lag) / .55, 0, 1));
  return row.map((a, n) => {
    const u = ease('BounceOut', seen[n]);
    const coming = row.reduce((sum, b, m) => sum + (seen[m] > 0 && seen[m] < 1 ? (a.x < b.x ? -1 : a.x > b.x ? 1 : 0) * sin(seen[m] * PI) : 0), 0);
    return { i: a.i, y: a.y - k.rise * (1 - u), x: a.x + k.lean * coming, size: a.size * lerp(.4, 1, u), opacity: seen[n] > 0 ? constrain(seen[n] * 4, 0, 1) : 0 };
  });
}

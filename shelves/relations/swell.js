// Each swells as Focus comes near, and those beside it move away by as much as it grew, so the gaps stay as they were.
// One thing's place hangs on all the others: After Effects' expressions cannot say that without text layers working it
// out first (Creative Cow, 2023, reports/relation_precedents_2026-11-03.md).
// --track@focus:Focus,-3,3,0,0.01
// --track@reach:Reach,0.1,3,0.6,0.01
// --track@grow:Grow,1,5,2.2,0.01
function relate(things, t, k) {
  const row = [...things].sort((a, b) => a.x - b.x);
  const near = a => { const u = constrain(1 - abs(a.x - k.focus) / k.reach, 0, 1); return 1 + (k.grow - 1) * u * u * (3 - 2 * u); };
  const gap = row.map((a, i) => i ? a.x - row[i - 1].x - (a.w + row[i - 1].w) / 2 : 0);
  let x = row[0].x - row[0].w / 2;
  const to = row.map((a, i) => {
    const s = near(a), w = a.w * s, at = x + gap[i] + w / 2;
    x = at + w / 2;
    return { i: a.i, x: at, size: a.size * s };
  });
  const off = (row[0].x + row[row.length - 1].x - to[0].x - to[to.length - 1].x) / 2;
  to.forEach(a => a.x += off);
  return to;
}

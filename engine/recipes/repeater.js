// Repeater: copies laid in a row or in rows, each turned and sized a step more, then scattered (After Effects' Repeater, Cinema 4D's Cloner in Grid Array, Cavalry's Duplicator)
// make shape circle
// say fill ff3366
// set size 0.1
// set copies 5
// --track@Columns:Columns,0,100,0,1
// --track@StepX:Step X,-5,5,0.3,0.01
// --track@StepY:Step Y,-5,5,0,0.01
// --track@StepZ:Step Z,-5,5,0,0.01
// --track@Turn:Turn,-720,720,0,1
// --track@Rotate:Rotate,-360,360,0,0.1
// --track@RotateX:Rotate X,-360,360,0,0.1
// --track@RotateY:Rotate Y,-360,360,0,0.1
// --track@Size:Size,0.01,4,1,0.01
// --track@Wide:Wide,0.01,10,1,0.01
// --track@ScatterX:Scatter X,0,4,0,0.01
// --track@ScatterY:Scatter Y,0,4,0,0.01
// --track@ScatterZ:Scatter Z,0,4,0,0.01
// --track@ScatterRotate:Scatter Rotate,0,360,0,0.1
// --track@ScatterSize:Scatter Size,0,1,0,0.01
// --track@Seed:Scatter seed,0,9999,0,1
// --track@DriftX:Scatter flow X,-2,2,0,0.01
// --track@DriftY:Scatter flow Y,-2,2,0,0.01

// What the document's own copy values (copy_x, copy_y, copy_z, copy_columns, copy_turn, copy_rotate, copy_rotate_x, copy_rotate_y,
// copy_size, copy_wide and scatter_x, scatter_y, scatter_z, scatter_rotate, scatter_size, seed, drift_x, drift_y) said before,
// as one recipe: a thing has one script, so laying out and scattering are one file. Units of the stage, as those were.
// Copy i of n; k.round is how long the document runs (a flow goes round a whole number of times in it: its film loops).
// A turn about the screen is rotate; rotate_x and rotate_y tip each copy more than the one before.
const sign = (v) => (v < 0 ? -1 : 1);
const roundAway = (v) => sign(v) * Math.round(Math.abs(v));   // (as C++'s std::round: halves go away from 0)

// -1 to 1: a hash of the seed, the copy and which roll, the same each time (a 32-bit integer hash: Wellons' lowbias32 shape).
function roll(seed, i, which) {
  let h = Math.imul(seed, 0x9E3779B9) ^ Math.imul(i + 1, 0x85EBCA6B) ^ Math.imul(which, 0xC2B2AE35);
  h ^= h >>> 16, h = Math.imul(h, 0x7FEB352D), h ^= h >>> 15, h = Math.imul(h, 0x846CA68B), h ^= h >>> 16;
  return (h >>> 0) / 2147483647.5 - 1;
}

function each(i, n, t, k) {
  const cols = Math.trunc(k.Columns);
  const along = cols > 0 ? i % cols : i, down = cols > 0 ? Math.floor(i / cols) : i;
  const alongMid = cols > 0 ? (Math.min(n, cols) - 1) / 2 : (n - 1) / 2;
  const downMid = cols > 0 ? (Math.ceil(n / cols) - 1) / 2 : (n - 1) / 2;
  let x = (along - alongMid) * k.StepX, y = (down - downMid) * k.StepY;
  let z = (cols > 0 ? down - downMid : i - (n - 1) / 2) * k.StepZ;
  let rotate = (i * k.Turn) / n + i * k.Rotate;
  let size = Math.pow(k.Size, i);
  const seed = Math.trunc(k.Seed);
  if (k.ScatterZ !== 0) z += k.ScatterZ * roll(seed, i, 5);
  if (k.ScatterX !== 0 || k.ScatterY !== 0 || k.ScatterRotate !== 0 || k.ScatterSize !== 0) {
    const wrap = (v, edge) => (edge > 0 ? v - 2 * edge * Math.floor((v + edge) / (2 * edge)) : v);   // (flowing past the edge: back in at the other)
    const whole = (drift, edge) => {   // (round the scattering a whole number of times in the document)
      const times = edge > 0 ? roundAway((drift * k.round) / (2 * edge)) : 0;
      return times !== 0 ? (times * 2 * edge) / k.round : drift;
    };
    x += wrap(k.ScatterX * roll(seed, i, 1) + whole(k.DriftX, k.ScatterX) * t, k.ScatterX);
    y += wrap(k.ScatterY * roll(seed, i, 2) + whole(k.DriftY, k.ScatterY) * t, k.ScatterY);
    rotate += k.ScatterRotate * roll(seed, i, 3);
    size *= Math.max(0, 1 + k.ScatterSize * roll(seed, i, 4));
  }
  return { x, y, z, rotate, rotate_x: i * k.RotateX, rotate_y: i * k.RotateY, size, scale_x: n > 1 ? Math.pow(k.Wide, i / (n - 1)) : 1 };
}

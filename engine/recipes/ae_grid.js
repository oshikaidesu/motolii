// AE Grid: copies in columns and rows, laid by an After Effects expression (index, thisComp.numLayers, effect()("Slider")), read once and only called each frame (ae_expr.h)
// make shape circle
// say fill ffd166
// set size 0.03
// set copies 12
// --track@Columns:Columns,1,40,4,1
// --track@Spacing:Spacing,0,500,120,1

// The expression is as After Effects would hold it, in its pixels, laid about the middle; a slider it reads is this recipe's knob of that name.
// After Effects' y goes down, the stage's up, so y is turned over: the first row stays the top one.
const grid = AE.compile(`
cols = Math.max(1, Math.floor(effect("Columns")("Slider")));
gap = effect("Spacing")("Slider");
n = index - 1;
rows = Math.ceil(thisComp.numLayers / cols);
[(n % cols - (cols - 1) / 2) * gap, (Math.floor(n / cols) - (rows - 1) / 2) * gap]
`);
let K;
const c = { value: [0, 0], comp: AE.comp({ width: 1920, height: 1080 }, []), effect: (e) => () => K[AE.name(e)] };
function each(i, n, t, k) {
  K = k, c.index = i + 1, c.time = t, c.comp.numLayers = n;
  const p = AE.run(grid, c);
  return { x: p[0] * k.px, y: -p[1] * k.px };
}

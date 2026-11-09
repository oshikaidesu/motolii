// AE Stagger: a row of copies that come in one after another, timed by an After Effects expression (index, time, ease(), effect()("Slider")), read once and only called each frame (ae_expr.h)
// make shape circle
// say fill 3a86ff
// set size 0.05
// set copies 8
// --track@Delay:Delay,0,1,0.12,0.01
// --track@Length:Length,0.05,3,0.6,0.01

// The expression is as After Effects would hold it for a scale (0 to 100 per cent); a slider it reads is this recipe's knob of that name.
const grow = AE.compile(`
d = effect("Delay")("Slider") * (index - 1);
ease(time, d, d + effect("Length")("Slider"), 0, 100)
`);
let K;
const c = { value: 100, comp: AE.comp({ width: 1920, height: 1080 }, []), effect: (e) => () => K[AE.name(e)] };
function each(i, n, t, k) {
  K = k, c.index = i + 1, c.time = t, c.comp.numLayers = n;
  return { x: (i - (n - 1) / 2) * 0.12, size: AE.run(grow, c) / 100 };
}

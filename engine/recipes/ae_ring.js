// AE Ring: copies on a ring, laid by an After Effects expression (index, thisComp.numLayers, effect()("Slider")), read once and only called each frame (ae_expr.h)
// make shape circle
// say fill ff3366
// set size 0.03
// set copies 12
// --track@Radius:Radius,0,1000,300,1
// --track@Turn:Turn,-360,360,0,1

// The expression is as After Effects would hold it, in its pixels; a slider it reads (effect("Radius")("Slider")) is this recipe's knob of that name (k.Radius).
// k.px turns After Effects' pixels into the stage's units; After Effects' y goes down, the stage's up, so y is turned over.
const ring = AE.compile(`
r = effect("Radius")("Slider");
a = degreesToRadians(360 / thisComp.numLayers * (index - 1) + effect("Turn")("Slider"));
[Math.cos(a) * r, Math.sin(a) * r]
`);
let K;
const c = { value: [0, 0], comp: AE.comp({ width: 1920, height: 1080 }, []), effect: (e) => () => K[AE.name(e)] };
function each(i, n, t, k) {
  K = k, c.index = i + 1, c.time = t, c.comp.numLayers = n;
  const p = AE.run(ring, c);
  return { x: p[0] * k.px, y: -p[1] * k.px };
}

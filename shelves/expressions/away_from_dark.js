// Away From Dark: each letter (or copy) reads the video or image under it and moves to where it is lighter, by the square of how dark it stands
// --picture@video:Video
// --track@reach:Reach,0,1,0.15,0.005
// --track@push:Push,0,2,0.5,0.01

// The reading is an After Effects expression, as it would be written there on a position: sampleImage() of the layer under it, here
// and in eight directions at one, two and three times Reach, each averaged over a square a third of Reach to a side. The layer picked
// as Video stands for thisComp.layer("Video").
const lighter = AE.compile(`
v = thisComp.layer("Video");
reach = effect("Reach")("Slider");
r = v.fromComp(value + [reach, reach]) - v.fromComp(value);
r = [Math.abs(r[0]), Math.abs(r[1])] / 3;
light = function (p) { c = v.sampleImage(v.fromComp(p), r, true, time); return (c[0] + c[1] + c[2]) / 3 * c[3]; };
to = [0, 0];
for (ring = 1; ring <= 3; ring++)
  for (turn = 0; turn < 8; turn++) {
    way = [Math.cos(turn * Math.PI / 4), Math.sin(turn * Math.PI / 4)];
    to = to + way * light(value + way * ring * reach) / ring;
  }
far = length(to);
dark = 1 - light(value);
value + (far > 0 ? to / far : to) * Math.min(1, far * 2) * dark * dark * effect("Push")("Slider")
`);
let K;
const video = { name: 'Video', index: 1, sampleImage: (p, r, after, u) => sampleImage(K.video, p, r, after, u), fromWorld: (p, u) => fromWorld(K.video, p, u) };
const c = { comp: AE.comp({}, [video]), effect: (name) => () => K[name.toLowerCase()] };
function each(i, n, t, k) {
  if (!k.video) return {};
  // Where this letter is before this expression moves it, in stage units, as layerValue gives it for the layer's own number.
  const x = layerValue(k.id, 'x', k.time, 0, i), y = layerValue(k.id, 'y', k.time, 0, i);
  K = k, c.index = i + 1, c.time = k.time, c.value = [x, y];
  const [lx, ly] = AE.run(lighter, c);
  return { x: lx - x, y: ly - y };
}

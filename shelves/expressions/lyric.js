// Lyric: each letter comes in from one side one after another, and leaves before the thing ends
// (the controls are those Texton lists on its page, https://booth.pm/ja/items/7838882: letters moved by a distance along X or
// Y, a length, an offset a letter, both ways, alternate, an In and an Out each with its ease, scale, rotation and opacity
// besides. Texton is closed jsxbin: none of its code was seen; this is written from that list alone. Order's words are
// GSAP's stagger `from` (start, end, center, edges, random: https://gsap.com/docs/v3/Staggers); Cavalry's Stagger has no
// such list. The ease names are Motolii's own (engine/motion/easing_names.h): Overshoot goes past and comes back)
// The knobs in leva's object form (pmndrs/leva: https://github.com/pmndrs/leva; read by script_leva.h): the kind from the
// value, folder() a fold. min and max are only how far a knob goes: a number typed past them is taken
const knobs = {
  distance: { value: 2, min: -20, max: 20, step: 0.01 },
  axis: { value: "X", options: ["X", "Y"] },
  length: { value: 0.5, min: 0.05, max: 4, step: 0.01 },
  delay: { value: 0.05, min: 0, max: 1, step: 0.01 },
  order: { value: "Start", options: ["Start", "End", "Centre", "Edges", "Random"] },
  alternate: false,
  both: false,
  ease_in: { value: "VerySlowOut", options: ["VerySlowOut", "SlowOut", "Overshoot", "SpringOut", "SmallSpringOut", "BounceOut", "SlowInSlowOut", "SlowIn", "VerySlowIn", "Linear"] },
  ease_out: { value: "SlowIn", options: ["SlowIn", "VerySlowIn", "SlowInSlowOut", "SlowOut", "VerySlowOut", "Overshoot", "Linear"] },
  out: true,
  Advanced: folder({
    scale_from: { value: 1, min: 0, max: 4, step: 0.01 },
    rotate_from: { value: 0, min: -360, max: 360, step: 1 },
    opacity_from: { value: 0, min: 0, max: 1, step: 0.01 },
  }, { collapsed: true }),
};

function each(i, n, t, k) {
  var mid = (n - 1) / 2;
  // (which turn a letter takes, in letters: its delay is so many Delays)
  var turn = k.order === 'End' ? n - 1 - i
    : k.order === 'Centre' ? Math.abs(i - mid)
    : k.order === 'Edges' ? mid - Math.abs(i - mid)
    : k.order === 'Random' ? cavalry.random(0, 1, 50, i) * (n - 1)
    : i;
  var last = k.order === 'Centre' || k.order === 'Edges' ? mid : n - 1;
  // (the side it comes from: odd letters from the other with Alternate, the second half from the other with Both ways)
  var side = (k.alternate && i % 2 === 1 ? -1 : 1) * (k.both && i >= n / 2 ? -1 : 1);
  var come = ease(k.ease_in, (t - k.delay * turn) / k.length);
  var leaving = 0;
  if (k.out) {   // (as animate()'s Out: the last letter gone 1/60 s before the thing ends)
    var from = Math.max(0, (k.duration > 0 ? k.duration : 4) - 1 / 60 - k.delay * last - k.length);
    leaving = t > from ? ease(k.ease_out, (t - from - k.delay * turn) / k.length) : 0;
  }
  var away = (1 - come) + leaving;   // (0 where it stands; 1 a Distance off, on the side it came from before, the other after)
  var off = side * k.distance * ((1 - come) - leaving);
  var there = Math.min(1, Math.max(0, 1 - away));
  var out = {
    size: k.scale_from + (1 - k.scale_from) * (1 - away),
    rotate: k.rotate_from * away,
    opacity: k.opacity_from + (1 - k.opacity_from) * there,
  };
  out[k.axis === 'Y' ? 'y' : 'x'] = off;
  return out;
}

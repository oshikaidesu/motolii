// Texflow: per-letter non-destructive text animation with character-class rules (Kanji/Kana),
// custom cubic-bezier curve, Bounce (damped oscillation), Hang (pendulum), and Scatter modes.
const knobs = {
  mode: { value: "Slide", options: ["Slide", "Bounce", "Hang", "Scatter"] },
  order: { value: "Start", options: ["Start", "End", "Centre", "Edges", "Random"] },
  axis: { value: "Y", options: ["Y", "X", "XY"] },
  distance: { value: 1.5, min: -10, max: 10, step: 0.05 },
  length: { value: 0.55, min: 0.05, max: 4, step: 0.01 },
  delay: { value: 0.05, min: 0, max: 1, step: 0.01 },
  out: true,
  alternate: false,
  ease_preset: {
    value: "Custom",
    options: ["Custom", "VerySlowOut", "SlowOut", "Overshoot", "SpringOut", "BounceOut", "SlowInSlowOut", "Linear"],
  },
  Curve: folder({
    x1: { value: 0.16, min: 0, max: 1, step: 0.01 },
    y1: { value: 1.0, min: -0.4, max: 1.6, step: 0.01 },
    x2: { value: 0.3, min: 0, max: 1, step: 0.01 },
    y2: { value: 1.0, min: -0.4, max: 1.6, step: 0.01 },
  }, { collapsed: true }),
  CharacterRules: folder({
    kanji_scale: { value: 1.0, min: 0.5, max: 2.5, step: 0.05 },
    kanji_delay: { value: 0.0, min: -0.5, max: 0.5, step: 0.01 },
    kana_delay: { value: 0.0, min: -0.5, max: 0.5, step: 0.01 },
  }, { collapsed: true }),
  Physics: folder({
    bounce_freq: { value: 3.0, min: 0.5, max: 10, step: 0.1 },
    bounce_decay: { value: 4.5, min: 0.5, max: 12, step: 0.1 },
    scatter_spread: { value: 1.8, min: 0, max: 8, step: 0.05 },
    scatter_seed: { value: 17, min: 1, max: 999, step: 1 },
  }, { collapsed: true }),
  Transform: folder({
    scale_from: { value: 0.65, min: 0, max: 3, step: 0.05 },
    rotate_from: { value: -18, min: -360, max: 360, step: 1 },
    opacity_from: { value: 0, min: 0, max: 1, step: 0.05 },
  }, { collapsed: true }),
};

function _bezierY(x, x1, y1, x2, y2) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  var lo = 0, hi = 1, t = x;
  for (var it = 0; it < 12; it++) {
    var u = 1 - t;
    var bx = 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t;
    if (Math.abs(bx - x) < 1e-4) break;
    if (bx < x) lo = t; else hi = t;
    t = 0.5 * (lo + hi);
  }
  var v = 1 - t;
  return 3 * v * v * t * y1 + 3 * v * t * t * y2 + t * t * t;
}

function _hash(seed, idx) {
  var h = Math.sin(seed * 127.1 + idx * 311.7) * 43758.5453;
  return h - Math.floor(h);
}

function _charClass(ch) {
  if (!ch) return "other";
  var cp = ch.codePointAt(0);
  if ((cp >= 0x4E00 && cp <= 0x9FFF) || (cp >= 0x3400 && cp <= 0x4DBF) || cp === 0x3005) return "kanji";
  if (cp >= 0x3040 && cp <= 0x309F) return "hiragana";
  if (cp >= 0x30A0 && cp <= 0x30FF) return "katakana";
  return "other";
}

function each(i, n, t, k) {
  var chars = typeof k.text === "string" ? Array.from(k.text.replace(/[\r\n]/g, "")) : [];
  var ch = i < chars.length ? chars[i] : "";
  var cls = _charClass(ch);

  var mid = (n - 1) / 2;
  var turn = k.order === "End" ? (n - 1 - i)
    : k.order === "Centre" ? Math.abs(i - mid)
    : k.order === "Edges" ? (mid - Math.abs(i - mid))
    : k.order === "Random" ? _hash(k.scatter_seed + 3, i) * Math.max(1, n - 1)
    : i;
  var last = (k.order === "Centre" || k.order === "Edges") ? mid : Math.max(0, n - 1);

  var extraDelay = cls === "kanji" ? k.kanji_delay
    : (cls === "hiragana" || cls === "katakana") ? k.kana_delay
    : 0;
  var startT = Math.max(0, k.delay * turn + extraDelay);
  var uIn = Math.max(0, Math.min(1, (t - startT) / Math.max(0.01, k.length)));
  var pIn = k.ease_preset === "Custom"
    ? _bezierY(uIn, k.x1, k.y1, k.x2, k.y2)
    : ease(k.ease_preset, uIn);

  var pOut = 0;
  if (k.out) {
    var dur = k.duration > 0 ? k.duration : 4;
    var outStart = Math.max(0, dur - 1 / 60 - k.delay * last - k.length);
    var uOut = Math.max(0, Math.min(1, (t - outStart - k.delay * turn) / Math.max(0.01, k.length)));
    if (uOut > 0) {
      pOut = k.ease_preset === "Custom"
        ? _bezierY(uOut, 1 - k.x2, 1 - k.y2, 1 - k.x1, 1 - k.y1)
        : ease("SlowIn", uOut);
    }
  }

  var side = (k.alternate && i % 2 === 1) ? -1 : 1;
  var away = (1 - pIn) + pOut;
  var signed = (1 - pIn) - pOut;
  var visible = Math.max(0, Math.min(1, 1 - away));
  var clsScale = cls === "kanji" ? k.kanji_scale : 1.0;

  var ox = 0, oy = 0;
  var rot = k.rotate_from * away;
  var sz = (k.scale_from + (1 - k.scale_from) * (1 - away)) * clsScale;

  if (k.mode === "Bounce") {
    var ring = uIn > 0 && uIn < 1
      ? Math.sin(uIn * Math.PI * 2 * k.bounce_freq) * Math.exp(-k.bounce_decay * uIn) * (1 - uIn)
      : 0;
    oy = -k.distance * signed * side + ring * k.distance * 0.35;
    sz = (1 + (k.scale_from - 1) * away + ring * 0.25) * clsScale;
    rot = k.rotate_from * away + ring * 18;
  } else if (k.mode === "Hang") {
    var swing = uIn > 0
      ? Math.cos(uIn * Math.PI * 2 * k.bounce_freq) * Math.exp(-k.bounce_decay * uIn * 0.75) * (1 - uIn * 0.5)
      : 1;
    oy = k.distance * away * 0.65;
    rot = (k.rotate_from !== 0 ? k.rotate_from : 38) * side * (away + swing * 0.45 * (1 - pOut));
  } else if (k.mode === "Scatter") {
    var ang = _hash(k.scatter_seed, i) * Math.PI * 2;
    var rad = (0.4 + 0.8 * _hash(k.scatter_seed + 11, i)) * k.scatter_spread;
    ox = Math.cos(ang) * rad * signed;
    oy = Math.sin(ang) * rad * signed;
    rot = (_hash(k.scatter_seed + 23, i) - 0.5) * 360 * away;
  } else {
    if (k.axis === "X" || k.axis === "XY") ox = side * k.distance * signed;
    if (k.axis === "Y" || k.axis === "XY") oy = -side * k.distance * signed;
  }

  return {
    x: ox,
    y: oy,
    size: Math.max(0.01, sz),
    rotate: rot,
    opacity: k.opacity_from + (1 - k.opacity_from) * visible,
  };
}

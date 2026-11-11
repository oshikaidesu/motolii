#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_

// JavaScript prelude that compiles and runs After Effects expressions.
//
// The prelude is a raw string, ae_prelude, that the caller evaluates in a
// QuickJS-ng context when a script uses AE.compile. An expression is parsed
// once by AE.compile, which returns a function; each frame only calls that
// function. The parser is acorn (third_party/js/acorn, MIT license), loaded
// into the context only when the script uses AE.compile.
//
// Work done once, at compile time:
//   - The operators + - * / become vector-aware calls ($a, $s, $m, $d).
//   QuickJS-ng has no
//     operator overloading, so [1,2] + [3,4] would otherwise give the string
//     "1,23,4".
//   - The value of the last statement becomes the return value, as in After
//   Effects.
//   - A name that is assigned but never declared gets a var declaration.
//   - The random state is reset on each call only if the text uses a random
//   function.
//
// This follows Bodymovin, which rewrites expressions to $bm_sum, $bm_rt and so
// on once at export; lottie-web and ThorVG's tvgLottieExpressions.cpp then run
// that text. Here the rewrite is done on the text as the user posted it. Names
// follow After Effects (ae-expressions.docsforadobe.dev).
//
// Usage:
//   const f = AE.compile(`...an expression as it was posted...`);
//   // Returns the expression's value, or c.value if the expression returns
//   undefined. AE.run(f, { index, time, value, comp, layer, effect })
//   // Builds thisComp from the canvas size and a list of layers. "controls" is
//   either
//   // { Effect: { Slider: 1 } } or a function (effect, property) => number; it
//   supplies what
//   // effect("Effect")("Slider") reads.
//   AE.comp({ width, height, numLayers },
//           [{ name, index, width, height, position: (t) => [x, y], controls
//           }])
//   // A layer may also be given sampleImage: (point, radius, postEffect, t) =>
//   // [r, g, b, a] and fromWorld: (point, t) => [x, y]; they answer
//   // thisComp.layer("...").sampleImage(), .fromComp() and .fromWorld(). A
//   // script hands them the engine's functions of those names
//   // (script_runner.h; shelves/expressions/away_from_dark.js).
//   // Turns a parameter name into an identifier: AE.name("X Offset") is
//   "X_Offset". AE.name("X Offset")
//
// Bare names of the layer (position, rotation, scale, opacity, transform) and
// valueAtTime are read from c.layer and c.property when the caller gives them.
//
// loopOut and loopIn go by the keyframe seconds the caller gives a layer (keys),
// and thisComp.layer("name") asks the composition's `find` for a layer it was
// not given.
//
// Not supported: the
// operators + - * / on a vector in unary minus and +=, toWorld, and footage().
//
// wiggle and random do not reproduce After Effects' own random sequences, so
// values that depend on the exact numbers will not match After Effects.
//
// ease(), easeIn() and easeOut() are the Beziers lottie-web uses for them, a
// re-implementation checked against After Effects by its users, not After
// Effects itself; their solver is the engine's (__bezier, script_natives.cpp),
// so there is one easing solver for keys, expressions and (to come) CSS.
// Tested against numbers worked out outside the engine:
// community/script_runner/ae_ease_test.cpp.

namespace motolii {

inline const char ae_prelude[] = R"AEJS(
(function (G) {
  const val = (x) => (x !== null && typeof x === 'object' && !Array.isArray(x) && 'value' in x) ? x.value : x;
  const lift = (f) => function (a, b) {
    if (typeof a === 'number' && typeof b === 'number') return f(a, b);
    a = val(a); b = val(b);
    const A = Array.isArray(a), B = Array.isArray(b);
    if (!A && !B) return f(a, b);
    const n = Math.max(A ? a.length : 0, B ? b.length : 0), out = new Array(n);
    for (let i = 0; i < n; i++) out[i] = f(A ? (a[i] === undefined ? 0 : a[i]) : a, B ? (b[i] === undefined ? 0 : b[i]) : b);
    return out;
  };
  const $a = lift((x, y) => x + y), $s = lift((x, y) => x - y), $m = lift((x, y) => x * y), $d = lift((x, y) => x / y);

  const S = { time: 0, value: 0, index: 0 };
  const hash2 = (a, b) => { let h = Math.imul((a | 0) ^ 0x9E3779B9, 0x85EBCA6B) ^ Math.imul((b | 0) + 1, 0xC2B2AE35); h ^= h >>> 16; h = Math.imul(h, 0x7FEB352D); h ^= h >>> 15; return h | 0; };
  const mulberry = (a) => () => { a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  let rng = mulberry(1), seedBase = 0;
  const reset = (index, time) => { seedBase = hash2(index, 0); rng = mulberry(hash2(index, Math.round(time * 1000))); };
  const seedRandom = (seed, timeless) => { seedBase = hash2(seed, 0); rng = mulberry(timeless ? hash2(seed, 0) : hash2(seed, Math.round(S.time * 1000))); };
  const random = (a, b) => {
    if (a === undefined) return rng();
    if (b === undefined) return Array.isArray(a) ? a.map((m) => rng() * m) : rng() * a;
    return Array.isArray(a) ? a.map((lo, i) => lo + rng() * (b[i] - lo)) : a + rng() * (b - a);
  };
  const lattice = (k, c) => hash2(hash2(seedBase, c), k) / 2147483648;
  const noise1 = (x, c) => { const f = Math.floor(x), u = x - f, s = u * u * (3 - 2 * u); return lattice(f, c) * (1 - s) + lattice(f + 1, c) * s; };
  const wiggle = (freq, amp, octaves, ampMult, t) => {
    octaves = octaves === undefined ? 1 : octaves; ampMult = ampMult === undefined ? 0.5 : ampMult; t = t === undefined ? S.time : t;
    const v = S.value, arr = Array.isArray(v), n = arr ? v.length : 1, out = new Array(n);
    for (let c = 0; c < n; c++) {
      let sum = 0, f = freq, a = amp;
      for (let o = 0; o < octaves; o++, f *= 2, a *= ampMult) sum += a * noise1(f * t, c * 977 + o);
      out[c] = (arr ? v[c] : v) + sum;
    }
    return arr ? out : out[0];
  };

  const bez = (x1, y1, x2, y2) => (u) => G.__bezier(x1, y1, x2, y2, u);
  const mix = (v1, v2, u) => Array.isArray(v1) ? v1.map((x, i) => x + (v2[i] - x) * u) : v1 + (v2 - v1) * u;
  const interp = (shape) => function (t, a, b, c, d) {
    let lo = 0, hi = 1, v1 = a, v2 = b;
    if (arguments.length > 3) { lo = a; hi = b; v1 = c; v2 = d; }
    let u = hi === lo ? (t >= lo ? 1 : 0) : (t - lo) / (hi - lo);
    u = u < 0 ? 0 : u > 1 ? 1 : u;
    return mix(v1, v2, shape(u));
  };
  const H = {
    S, reset, $a, $s, $m, $d, seedRandom, random, wiggle, add: $a, sub: $s, mul: $m, div: $d,
    linear: interp((u) => u),
    // The three curves as lottie-web draws them (player/js/utils/expressions/ExpressionManager.js): cubic Beziers, whose
    // control points are all this file holds; the solver is motion/easing_curves.h's, given as __bezier.
    ease: interp(bez(0.33, 0, 0.667, 1)),
    easeIn: interp(bez(0.333, 0, 0.833, 0.833)),
    easeOut: interp(bez(0.167, 0.167, 0.667, 1)),
    clamp: (v, lo, hi) => Array.isArray(v) ? v.map((x, i) => Math.min(Math.max(x, lo[i]), hi[i])) : Math.min(Math.max(v, lo), hi),
    degreesToRadians: (d) => d * Math.PI / 180, radiansToDegrees: (r) => r * 180 / Math.PI,
    noise: (x) => noise1(x, 0),
    length: (a, b) => { const v = b === undefined ? a : $s(a, b); return Array.isArray(v) ? Math.hypot(...v) : Math.abs(v); },
  };

  // (a property read by its parts, position[0], as After Effects reads one)
  class Prop {
    constructor(f, keys) { this.f = f; this.keys = keys || []; }
    valueAtTime(t) { return this.f(t); }
    get value() { return this.f(S.time); }
    get 0() { return this.value[0]; } get 1() { return this.value[1]; } get 2() { return this.value[2]; }
    get numKeys() { return this.keys.length; }
    // loopOut and loopIn (ae-expressions.docsforadobe.dev/property/#loopout): past the last keyframe, or before the first, the keys are
    // gone through again: 'cycle', 'pingpong', 'offset' (each round starts where the one before ended) or 'continue' (on at the speed it
    // ended with). The span is all the keys, or the last (first) numKeyframes segments. The same rounds as the engine's own repeat of
    // keys (document/evaluate/value_at.cpp doc_keys_at).
    loop(type, n, out) {
      const k = this.keys, t = S.time;
      if (k.length < 2) return this.f(t);
      const a = out ? k[n > 0 ? Math.max(0, k.length - 1 - n) : 0] : k[0], b = out ? k[k.length - 1] : k[n > 0 ? Math.min(k.length - 1, n) : k.length - 1];
      if (out ? t <= b : t >= a) return this.f(t);
      const span = b - a, edge = out ? b : a;
      if (type === 'continue') { const step = out ? -0.001 : 0.001; return $a(this.f(edge), $m($d($s(this.f(edge), this.f(edge + step)), -step), t - edge)); }
      const rounds = Math.floor((t - a) / span), left = t - a - rounds * span;
      const at = this.f(type === 'pingpong' && rounds % 2 ? b - left : a + left);
      return type === 'offset' ? $a(at, $m($s(this.f(b), this.f(a)), rounds)) : at;
    }
    loopOut(type, n) { return this.loop(type || 'cycle', n || 0, true); }
    loopIn(type, n) { return this.loop(type || 'cycle', n || 0, false); }
  }
  const makeLayer = (s) => {
    const L = { name: s.name, index: s.index, width: s.width || 0, height: s.height || 0, controls: s.controls || {} };
    const keys = s.keys || {};   // (the seconds of each property's keyframes, when the script gives them)
    L.position = new Prop(s.position || (() => [0, 0, 0]), keys.position);
    // (the rest of its Transform, when the script says how each is read: rotation, scale, opacity, anchorPoint)
    L.transform = { position: L.position };
    for (const name of ['rotation', 'scale', 'opacity', 'anchorPoint']) if (s[name]) L[name] = L.transform[name] = new Prop(s[name], keys[name]);
    L.effect = (n) => (m) => typeof L.controls === 'function' ? L.controls(n, m) : L.controls[n][m];
    // The layer's picture, when the script gives what reads it: sampleImage(point, radius, postEffect, t) and a point brought into the
    // layer's own pixels (fromComp, fromWorld), with After Effects' defaults: a radius of half a pixel, after effects, now.
    L.sampleImage = (p, r, post, t) => s.sampleImage ? s.sampleImage(val(p), r === undefined ? [0.5, 0.5] : val(r), post === undefined ? true : post, t === undefined ? S.time : t) : [0, 0, 0, 0];
    L.fromComp = L.fromWorld = (p, t) => s.fromWorld ? s.fromWorld(val(p), t === undefined ? S.time : t) : val(p);
    return L;
  };
  const makeComp = (o, specs) => {
    const layers = specs.map(makeLayer);
    return { width: o.width, height: o.height, frameDuration: o.frameDuration || 1 / 60, numLayers: o.numLayers || layers.length, layers,
      layer(a, rel) {
        const one = typeof a === 'string' ? layers.find((l) => l.name === a) : typeof a === 'number' ? layers.find((l) => l.index === a) : layers.find((l) => l.index === a.index + rel);
        if (one || !o.find || typeof a === 'object') return one;
        const spec = o.find(a);   // (a layer the script did not list: asked of whoever made the composition, once)
        if (spec) layers.push(makeLayer(spec));
        return spec ? layers[layers.length - 1] : undefined;
      } };
  };

  const PARAMS = new Set(['index', 'time', 'value', 'thisComp', 'thisLayer', 'textIndex', 'textTotal', 'selectorValue', 'effect', 'thisProperty']);
  // (what an expression names bare: After Effects looks a name up on the property it is on, then on its layer)
  const LAYER = ['position', 'rotation', 'scale', 'opacity', 'anchorPoint', 'transform', 'name', 'width', 'height'];
  const RANDOMS = new Set(['random', 'seedRandom', 'wiggle', 'noise', 'gaussRandom']);
  const OPS = { '+': '$a', '-': '$s', '*': '$m', '/': '$d' };
  const DECL = 'var ' + Object.keys(H).map((k) => k + '=H.' + k).join(',') + ';';
  const kids = (n) => {
    const out = [];
    for (const k in n) {
      if (k === 'type' || k === 'start' || k === 'end') continue;
      const v = n[k];
      if (Array.isArray(v)) { for (const x of v) if (x && typeof x.type === 'string') out.push(x); } else if (v && typeof v.type === 'string') out.push(v);
    }
    return out;
  };
  function compile(src) {
    const ast = acorn.parse(src, { ecmaVersion: 2020 });
    const declared = new Set(), assigned = new Set(), named = new Set();
    let usesRandom = false;
    const walk = (n) => {
      if (n.type === 'VariableDeclarator' && n.id.type === 'Identifier') declared.add(n.id.name);
      else if (n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression' || n.type === 'ArrowFunctionExpression') { if (n.id) declared.add(n.id.name); for (const p of n.params) if (p.type === 'Identifier') declared.add(p.name); }
      else if (n.type === 'AssignmentExpression' && n.left.type === 'Identifier') assigned.add(n.left.name);
      else if (n.type === 'UpdateExpression' && n.argument.type === 'Identifier') assigned.add(n.argument.name);
      else if (n.type === 'Identifier') { named.add(n.name); if (RANDOMS.has(n.name)) usesRandom = true; }
      kids(n).forEach(walk);
    };
    walk(ast);
    const tails = new Set();
    const mark = (s) => {
      if (!s) return;
      if (s.type === 'ExpressionStatement') tails.add(s);
      else if (s.type === 'IfStatement') { mark(s.consequent); mark(s.alternate); }
      else if (s.type === 'BlockStatement') mark(s.body[s.body.length - 1]);
    };
    mark(ast.body[ast.body.length - 1]);
    const emit = (n) => {
      if (n.type === 'BinaryExpression' && OPS[n.operator]) return OPS[n.operator] + '(' + emit(n.left) + ',' + emit(n.right) + ')';
      if (tails.has(n)) return 'return (' + emit(n.expression) + ');';
      let out = '', pos = n.start;
      for (const k of kids(n).sort((a, b) => a.start - b.start)) { out += src.slice(pos, k.start) + emit(k); pos = k.end; }
      return out + src.slice(pos, n.end);
    };
    const vars = [...assigned].filter((v) => !declared.has(v) && !PARAMS.has(v));
    const free = (v) => named.has(v) && !declared.has(v) && !assigned.has(v);
    const bare = LAYER.filter(free).map((v) => v + '=thisLayer?thisLayer.' + v + ':undefined');
    if (free('valueAtTime')) bare.push('valueAtTime=(t)=>thisProperty.valueAtTime(t)');
    for (const v of ['loopOut', 'loopIn']) if (free(v)) bare.push(v + '=(a,b)=>thisProperty.' + v + '(a,b)');
    if (free('numKeys')) bare.push('numKeys=thisProperty.numKeys');
    const head = (vars.length ? 'var ' + vars.join(',') + ';' : '') + (bare.length ? 'var ' + bare.join(',') + ';' : '') + (usesRandom ? 'H.reset(index,time);' : '');
    const make = new Function('H', DECL + 'return function(index,time,value,thisComp,thisLayer,textIndex,textTotal,selectorValue,effect,thisProperty){S.time=time;S.value=value;' + head + emit(ast) + '\n};');
    return make(H);
  }
  // A property left as the result gives its value, as After Effects takes thisComp.layer("Null 1").transform.position.
  const run = (f, c) => { const r = f(c.index, c.time, c.value, c.comp, c.layer, c.textIndex, c.textTotal, c.selectorValue, c.effect, c.property); return r === undefined ? c.value : val(r); };
  G.AE = { compile, run, comp: makeComp, layer: makeLayer, name: (s) => String(s).replace(/\W+/g, '_'), H };
})(globalThis);
)AEJS";

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_

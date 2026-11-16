#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_

// The After Effects expression runtime: its JavaScript lives beside acorn as
// engine/third_party/js/ae/ae_prelude.js. community/script_runner/script_runner.cpp
// evaluates that file into a QuickJS-ng context when a script uses AE.compile,
// after loading acorn (third_party/js/acorn/acorn.js).
//
// The engine's only role here is to hand the JS runtime the easing solver as
// `__bezier` (community/script_runner/script_natives.cpp bezier_ease, the same
// solver as motion/easing_curves.h) and to read the two .js files from disk.
// Everything the expression does — compile, run, vector arithmetic, random,
// wiggle, ease, loopIn/Out, the Prop and Layer wrappers — is in ae_prelude.js.
//
// Usage from a script (inside ae_prelude.js):
//   const f = AE.compile(`...an expression as it was posted...`);
//   AE.run(f, { index, time, value, comp, layer, effect })
//   AE.comp({ width, height, numLayers },
//           [{ name, index, width, height, position: (t) => [x, y], controls }])
//   AE.layer(spec) and AE.name("X Offset") → "X_Offset"
//
<<<<<<< Updated upstream
// Supported, not supported, and the random-sequence caveat are described at
// the top of ae_prelude.js.
=======
// footage("names.csv") reads a data file from the folder named like the script
// beside it (rows.js: rows/names.csv), in an expression and as AE.footage() in
// the script around it: .sourceText, .dataValue([column, row]) of a CSV or TSV
// file, and .sourceData (a JSON file's data as After Effects gives it; a CSV
// file's rows, which is this file's own). See the comment at `footage` below.
// A number in a CSV cell is given as a number; what After Effects gives there
// was not found in its documents. Tested from the contract alone:
// community/script_runner/footage_test.cpp.
//
// Not supported: bare property names (position, opacity), loopOut, the
// operators + - * / on a vector in unary minus and +=, toWorld, and of
// footage() the MGJSON streams (dataKeyCount, dataKeyTimes, dataKeyValues).
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

  // footage(name): After Effects' footage() for a data file, read by the last part of its name from the folder the
  // script has beside it (__text_read). Rows of a CSV or TSV file as RFC 4180 has them: a field may stand in double
  // quotes, where a comma, a line break and a doubled quote are themselves; lines end in CRLF or LF.
  const table = (text, between) => {
    const rows = [[]];
    let cell = '', quoted = false, begun = false;
    for (let i = text.charCodeAt(0) === 0xFEFF ? 1 : 0; i < text.length; i++) {
      const c = text[i];
      if (quoted) { if (c !== '"') cell += c; else if (text[i + 1] === '"') cell += '"', i++; else quoted = false; }
      else if (c === '"') quoted = begun = true;
      else if (c === between) rows[rows.length - 1].push(cell), cell = '', begun = true;
      else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; rows[rows.length - 1].push(cell), rows.push([]), cell = '', begun = false; }
      else cell += c, begun = true;
    }
    if (begun) rows[rows.length - 1].push(cell); else rows.pop();   // (a line break at the very end makes no row)
    return rows;
  };
  const cellOf = (s) => /^-?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$/.test(s) ? Number(s) : s;   // (a cell that is a number is one)
  const files = new Map();
  const footage = (name) => {
    name = String(name);
    const text = typeof G.__text_read === 'function' ? G.__text_read(name) : null;
    if (typeof text !== 'string') throw new Error('footage("' + name + '"): no such file in the folder beside the script');
    let f = files.get(name);
    if (f && f.sourceText === text) return f;
    const kind = name.toLowerCase().split('.').pop();
    f = { name: name.split('/').pop(), sourceText: text };
    if (kind === 'csv' || kind === 'tsv') {
      // dataValue([column, row]) as After Effects has it: both from 0, the line of column names not a row, and an
      // error outside the table. sourceData, which After Effects gives a JSON file, is here the rows, one object a
      // row by the columns' names, so that its length is how many rows there are: After Effects has no name for that.
      const rows = table(text, kind === 'tsv' ? '\t' : ','), names = rows.shift() || [], cells = rows.map((r) => r.map(cellOf));
      f.dataValue = (path) => {
        path = val(path);
        const v = Array.isArray(path) && cells[path[1]] ? cells[path[1]][path[0]] : undefined;
        if (v === undefined) throw new Error('footage("' + name + '").dataValue([' + path + ']): the file has ' + names.length + ' columns and ' + cells.length + ' rows');
        return v;
      };
      f.sourceData = cells.map((r) => Object.fromEntries(names.map((n, c) => [n, r[c] === undefined ? '' : r[c]])));
    } else if (kind === 'json') f.sourceData = JSON.parse(text);
    files.set(name, f);
    return f;
  };
  H.footage = footage;

  class Prop { constructor(f) { this.f = f; } valueAtTime(t) { return this.f(t); } get value() { return this.f(S.time); } }
  const makeLayer = (s) => {
    const L = { name: s.name, index: s.index, width: s.width || 0, height: s.height || 0, controls: s.controls || {} };
    L.position = new Prop(s.position || (() => [0, 0, 0]));
    L.transform = { position: L.position };
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
      layer(a, rel) { return typeof a === 'string' ? layers.find((l) => l.name === a) : typeof a === 'number' ? layers.find((l) => l.index === a) : layers.find((l) => l.index === a.index + rel); } };
  };

  const PARAMS = new Set(['index', 'time', 'value', 'thisComp', 'thisLayer', 'textIndex', 'textTotal', 'selectorValue', 'effect']);
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
    const declared = new Set(), assigned = new Set();
    let usesRandom = false;
    const walk = (n) => {
      if (n.type === 'VariableDeclarator' && n.id.type === 'Identifier') declared.add(n.id.name);
      else if (n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression' || n.type === 'ArrowFunctionExpression') { if (n.id) declared.add(n.id.name); for (const p of n.params) if (p.type === 'Identifier') declared.add(p.name); }
      else if (n.type === 'AssignmentExpression' && n.left.type === 'Identifier') assigned.add(n.left.name);
      else if (n.type === 'UpdateExpression' && n.argument.type === 'Identifier') assigned.add(n.argument.name);
      else if (n.type === 'Identifier' && RANDOMS.has(n.name)) usesRandom = true;
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
    const head = (vars.length ? 'var ' + vars.join(',') + ';' : '') + (usesRandom ? 'H.reset(index,time);' : '');
    const make = new Function('H', DECL + 'return function(index,time,value,thisComp,thisLayer,textIndex,textTotal,selectorValue,effect){S.time=time;S.value=value;' + head + emit(ast) + '\n};');
    return make(H);
  }
  // A property left as the result gives its value, as After Effects takes thisComp.layer("Null 1").transform.position.
  const run = (f, c) => { const r = f(c.index, c.time, c.value, c.comp, c.layer, c.textIndex, c.textTotal, c.selectorValue, c.effect); return r === undefined ? c.value : val(r); };
  G.AE = { compile, run, comp: makeComp, footage, name: (s) => String(s).replace(/\W+/g, '_'), H };
})(globalThis);
)AEJS";

}  // namespace motolii
>>>>>>> Stashed changes

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_

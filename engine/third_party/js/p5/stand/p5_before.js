var __T = 0, __Q = [], __seed = 12345, __L = 0;   // (__L: the line of the sketch that draws now: script.h sketch_marked)
function __at(line, it) { __L = line; return it; }
Math.random = () => (__seed = (1664525 * __seed + 1013904223) % 4294967296) / 4294967296;   // (the same film each time it is played: p5's own _lcg, src/math/random.js, from one seed)
function __any(name) {
  const f = function () {};
  return new Proxy(f, {
    get(t, k) { if (k === Symbol.toPrimitive) return () => 0; if (k === Symbol.iterator) return function* () {}; if (k === 'length') return 0; if (k === 'name') return __any(name + '.name'); if (k === 'then') return undefined; if (k in t) return t[k]; return t[k] = __any(name + '.' + String(k)); },
    set(t, k, v) { t[k] = v; return true; },
    apply() { return __any(name + '()'); }, construct() { return __any('new ' + name); },
  });
}
// A canvas with no pixels, as a 2D sketch paints on it: what the WHATWG canvas context is told, cached as numbers for ThorVG
// (canvas_sketch.h), each paint its kind (1 fill, 2 stroke, 3 words), colour, blend, line, how many numbers follow of its path
// (0 move, 1 line, 2 curve, 3 close) and of its gradient and the sketch's line that drew it, its points turned by the matrix as they are told, as the spec says. svgcanvas, which writes the same calls as SVG, took
// 45 ms a frame in QuickJS for 1161 shapes and this 6, and has no globalCompositeOperation.
const __blends = { multiply: 1, screen: 2, overlay: 3, darken: 4, lighten: 5, 'color-dodge': 6, 'color-burn': 7, 'hard-light': 8, 'soft-light': 9, difference: 10, exclusion: 11, hue: 12, saturation: 13, color: 14, luminosity: 15, lighter: 16 };   // (ThorVG's BlendMethod)
const __colours = new Map();
function __rgba(style) {   // (a colour as p5 itself reads it)
  let c = __colours.get(style);
  if (!c) __colours.set(style, c = p5.prototype.color.call(p5.instance, style).levels);
  return c;
}
// Whole pictures a sketch holds, loaded, built pixel by pixel or a film's: their bytes stay here, a paint says which by its number
// (canvas_sketch.h sketch_bitmap). What is built each frame goes when 300 MB of them are held: what shows it is on disk by then (canvas_cache.h).
var __bitmaps = [null], __bitmaps_owned = [], __bitmaps_held = 0;
function __bitmap_new(bytes, stays) {
  __bitmaps.push(bytes);
  if (!stays) __bitmaps_owned.push(__bitmaps.length - 1), __bitmaps_held += bytes.length;
  while (__bitmaps_held > 3e8 && __bitmaps_owned.length > 1) { const i = __bitmaps_owned.shift(); __bitmaps_held -= __bitmaps[i].length, __bitmaps[i] = null; }
  return __bitmaps.length - 1;
}
function __bitmap(i) { globalThis.__bytes = __bitmaps[i] || new Uint8Array(0); }
function __flat(e) {
  const keep = ['fillStyle', 'strokeStyle', 'lineWidth', 'lineCap', 'lineJoin', 'miterLimit', 'globalAlpha', 'globalCompositeOperation', 'font', 'textAlign', 'textBaseline', 'shadowBlur', 'shadowColor', 'shadowOffsetX', 'shadowOffsetY', 'filter', 'imageSmoothingEnabled'], saved = [];
  let m = [1, 0, 0, 1, 0, 0], path = [], ux = 0, uy = 0, sx = 0, sy = 0, ops = [], clear = false, seen = 0;
  const X = (x, y) => m[0] * x + m[2] * y + m[4], Y = (x, y) => m[1] * x + m[3] * y + m[5];
  const M = (x, y) => { path.push(0, X(x, y), Y(x, y)), ux = sx = x, uy = sy = y; };
  const L = (x, y) => { if (!path.length) return M(x, y); path.push(1, X(x, y), Y(x, y)), ux = x, uy = y; };
  const C = (a, b, c, d, x, y) => { if (!path.length) M(a, b); path.push(2, X(a, b), Y(a, b), X(c, d), Y(c, d), X(x, y), Y(x, y)), ux = x, uy = y; };
  const large = () => Math.sqrt(Math.abs(m[0] * m[3] - m[1] * m[2]));
  const ramp = g => {   // (a gradient's ends where the matrix puts them when it is used, as the spec says; ThorVG's radial has them as outer and focal)
    const q = g.kind === 3 && Math.cos(g.a), s = g.kind === 3 && Math.sin(g.a);
    const out = g.kind === 3 ? [3, m[0] * q + m[2] * s, m[1] * q + m[3] * s, m[2] * q - m[0] * s, m[3] * q - m[1] * s, X(g.x0, g.y0), Y(g.x0, g.y0)]   // (a conic one: where its first ray and the one a quarter on go, and its centre)
      : [g.kind, X(g.x0, g.y0), Y(g.x0, g.y0), g.r0 * large(), X(g.x1, g.y1), Y(g.x1, g.y1), g.r1 * large()];
    for (const [at, k] of g.stops.slice().sort((a, b) => a[0] - b[0])) { const q = __rgba(k); out.push(at, q[0], q[1], q[2], q[3] * c.globalAlpha); }
    return out;
  };
  const paint = (kind, style) => {
    const g = typeof style === 'string' ? null : style, k = g ? [255, 255, 255, 255] : __rgba(style), a = k[3] * c.globalAlpha, more = g && g.kind ? ramp(g) : [];
    if (!path.length || a <= 0) return;
    ops.push(kind, k[0], k[1], k[2], a, __blends[c.globalCompositeOperation] || 0, kind === 2 ? c.lineWidth * large() : 0, { round: 1, square: 2 }[c.lineCap] || 0, { round: 1, bevel: 2 }[c.lineJoin] || 0, path.length, more.length, __L);
    for (let i = 0; i < path.length; ++i) ops.push(path[i]);
    for (let i = 0; i < more.length; ++i) ops.push(more[i]);
  };
  const words = (t, x, y, style) => {   // (its matrix and its letters as numbers; a gradient's words white, for now)
    const k = typeof style === 'string' ? __rgba(style) : [255, 255, 255, 255], a = k[3] * c.globalAlpha, codes = Array.from(String(t), h => h.codePointAt(0));
    if (!codes.length || a <= 0) return;
    ops.push(3, k[0], k[1], k[2], a, __blends[c.globalCompositeOperation] || 0, parseFloat((/([\d.]+)px/.exec(c.font) || [0, 10])[1]), { center: 1, right: 2, end: 2 }[c.textAlign] || 0, { top: 1, hanging: 1, middle: 2, bottom: 3, ideographic: 3 }[c.textBaseline] || 0, 6 + codes.length, 0, __L, m[0], m[1], m[2], m[3], X(x, y), Y(x, y));
    for (let i = 0; i < codes.length; ++i) ops.push(codes[i]);
  };
  const bitmap = (id, w, h, x, y, ax = 0, ay = 0, aw = w, ah = h) => ops.push(4, 255, 255, 255, 255 * c.globalAlpha, __blends[c.globalCompositeOperation] || 0, 0, 0, 0, 14, 0, __L, m[0], m[1], m[2], m[3], X(x, y), Y(x, y), id, w, h, ax, ay, aw, ah, c.imageSmoothingEnabled ? 0 : 1);
  const whole_ink = k => typeof k === 'string' ? __rgba(k)[3] === 255 : k.kind && k.stops.every(q => __rgba(q[1])[3] === 255);
  const whole = (x, y, w, h) => X(x, y) <= 0 && Y(x, y) <= 0 && X(x + w, y + h) >= e.width && Y(x + w, y + h) >= e.height && !m[1] && !m[2];   // (a background(): what was painted before is gone)
  const box = (x, y, w, h) => { M(x, y), L(x + w, y), L(x + w, y + h), L(x, y + h), path.push(3), ux = sx, uy = sy; };
  const wipe = () => {   // (the spec's: a canvas told its size again is new; a page's own colour behind it, __adapter_canvas's sheet, is what it then shows)
    ops = [], clear = true, path = [], m = [1, 0, 0, 1, 0, 0];
    if (c) Object.assign(c, { fillStyle: '#000000', strokeStyle: '#000000', lineWidth: 1, globalAlpha: 1, globalCompositeOperation: 'source-over' });
    if (c && e.sheet) c.fillStyle = e.sheet, c.fillRect(0, 0, e.width, e.height), c.fillStyle = '#000000';
  };
  for (const side of ['width', 'height']) { let size = e[side]; Object.defineProperty(e, side, { get: () => size, set: v => { size = v, wipe(); }, configurable: true, enumerable: true }); }
  const alone = (f) => { const was = path; path = [], f(), path = was; };   // (fillRect and its like leave the path as it was)
  const c = { canvas: e, fillStyle: '#000000', strokeStyle: '#000000', lineWidth: 1, lineCap: 'butt', lineJoin: 'miter', miterLimit: 10, globalAlpha: 1, globalCompositeOperation: 'source-over', font: '10px sans-serif', textAlign: 'start', textBaseline: 'alphabetic', shadowBlur: 0, shadowColor: '', shadowOffsetX: 0, shadowOffsetY: 0, filter: 'none', imageSmoothingEnabled: true, lineDashOffset: 0,
    save() { saved.push([m.slice(), keep.map(k => c[k])]); },
    restore() { const s = saved.pop(); if (s) m = s[0], keep.forEach((k, i) => c[k] = s[1][i]); },
    setTransform(a, b, cc, d, x, y) { m = typeof a === 'object' ? [a.a, a.b, a.c, a.d, a.e, a.f] : [a, b, cc, d, x, y]; }, resetTransform() { m = [1, 0, 0, 1, 0, 0]; }, getTransform() { return { a: m[0], b: m[1], c: m[2], d: m[3], e: m[4], f: m[5] }; },
    transform(a, b, cc, d, x, y) { const [A, B, C2, D, E, F] = m; m = [A * a + C2 * b, B * a + D * b, A * cc + C2 * d, B * cc + D * d, A * x + C2 * y + E, B * x + D * y + F]; },
    translate(x, y) { c.transform(1, 0, 0, 1, x, y); }, scale(x, y) { c.transform(x, 0, 0, y, 0, 0); }, rotate(a) { const q = Math.cos(a), s = Math.sin(a); c.transform(q, s, -s, q, 0, 0); },
    beginPath() { path = []; }, closePath() { if (path.length) path.push(3), ux = sx, uy = sy; }, moveTo: M, lineTo: L, bezierCurveTo: C, rect: box,
    quadraticCurveTo(a, b, x, y) { if (!path.length) M(a, b); C(ux + 2 / 3 * (a - ux), uy + 2 / 3 * (b - uy), x + 2 / 3 * (a - x), y + 2 / 3 * (b - y), x, y); },   // (a quadratic is the cubic with its handles 2/3 of the way)
    ellipse(x, y, rx, ry, turn, from, to, back) {   // (at most a quarter to a curve, each with handles 4/3 tan(a/4) long: Goldapp 1991)
      const two = 2 * Math.PI, co = Math.cos(turn), si = Math.sin(turn);
      let go = to - from;
      if (!back) go = go >= two ? two : (go % two + two) % two; else go = go <= -two ? -two : -((-go % two + two) % two);
      const n = Math.max(1, Math.ceil(Math.abs(go) / (Math.PI / 2) - 1e-6)), d = go / n, k = 4 / 3 * Math.tan(d / 4);
      const A = (u, v) => x + rx * u * co - ry * v * si, B = (u, v) => y + rx * u * si + ry * v * co;
      let q = Math.cos(from), s = Math.sin(from);
      if (path.length) L(A(q, s), B(q, s)); else M(A(q, s), B(q, s));
      for (let i = 1; i <= n; ++i) { const t = from + i * d, Q = Math.cos(t), S = Math.sin(t); C(A(q - k * s, s + k * q), B(q - k * s, s + k * q), A(Q + k * S, S - k * Q), B(Q + k * S, S - k * Q), A(Q, S), B(Q, S)), q = Q, s = S; }
    },
    arc(x, y, r, from, to, back) { c.ellipse(x, y, r, r, 0, from, to, back); },
    arcTo(a, b, x, y, r) {   // (the circle touching both lines, as one curve from where it touches one to where it touches the other)
      const p = Math.hypot(ux - a, uy - b) || 1, q = Math.hypot(x - a, y - b) || 1, ix = (ux - a) / p, iy = (uy - b) / p, jx = (x - a) / q, jy = (y - b) / q, wide = Math.acos(Math.max(-1, Math.min(1, ix * jx + iy * jy))), far = r / Math.tan(wide / 2), k = 4 / 3 * Math.tan((Math.PI - wide) / 4) * r;
      if (!r || !isFinite(far)) return L(a, b);
      L(a + ix * far, b + iy * far), C(a + ix * (far - k), b + iy * (far - k), a + jx * (far - k), b + jy * (far - k), a + jx * far, b + jy * far);
    },
    roundRect(x, y, w, h, r) {   // (a corner each, as p5's rect() asks them; the spec's order: from the top left, clockwise)
      const [a, b, d, e] = Array.isArray(r) ? (r.length < 4 ? [r[0], r[0], r[0], r[0]] : r) : [r, r, r, r];
      M(x + a, y), c.arcTo(x + w, y, x + w, y + h, b), c.arcTo(x + w, y + h, x, y + h, d), c.arcTo(x, y + h, x, y, e), c.arcTo(x, y, x + w, y, a), path.push(3), ux = sx, uy = sy;
    },
    fill() { paint(1, c.fillStyle); }, stroke() { paint(2, c.strokeStyle); },
    fillRect(x, y, w, h) { if (whole(x, y, w, h) && whole_ink(c.fillStyle) && c.globalAlpha === 1 && !__blends[c.globalCompositeOperation]) ops = [], clear = true; alone(() => { box(x, y, w, h), paint(1, c.fillStyle); }); },
    strokeRect(x, y, w, h) { alone(() => { box(x, y, w, h), paint(2, c.strokeStyle); }); },
    clearRect(x, y, w, h) { if (whole(x, y, w, h)) ops = [], clear = true; },
    createLinearGradient(x0, y0, x1, y1) { const g = { kind: 1, x0, y0, r0: 0, x1, y1, r1: 0, stops: [], addColorStop(at, k) { g.stops.push([at, k]); } }; return g; },
    createRadialGradient(x0, y0, r0, x1, y1, r1) { return Object.assign(c.createLinearGradient(x0, y0, x1, y1), { kind: 2, r0, r1 }); }, createConicGradient(a, x, y) { return Object.assign(c.createLinearGradient(x, y, x, y), { kind: 3, a }); }, createPattern() { return { kind: 0, stops: [] }; },
    measureText(t) { return { width: String(t).length * parseFloat(c.font) * 0.5, actualBoundingBoxAscent: 0, actualBoundingBoxDescent: 0 }; },
    getImageData(x, y, w, h) {   // (no pixels but a film's: see __film_step)
      const data = new Uint8ClampedArray(4 * w * h), b = e.bytes;
      if (w === 1 && h === 1 && !b && typeof c.fillStyle === 'string') { const k = __rgba(c.fillStyle); data[0] = k[0], data[1] = k[1], data[2] = k[2], data[3] = k[3]; return { width: 1, height: 1, data }; }   // (a dot just painted read back: how Paper.js and others read a colour's CSS name)
      if (b) for (let r = 0, W = e.width; r < h; ++r) data.set(b.subarray(4 * ((y + r) * W + x), 4 * ((y + r) * W + x + w)), 4 * r * w);
      return { width: w, height: h, data };
    },
    createImageData(w, h) { return { width: w, height: h, data: new Uint8ClampedArray(4 * w * h) }; },
    putImageData(d, x, y) {   // (ignoring the matrix, as the spec has it: what it held is gone only where these pixels are)
      const was = m, all = x <= 0 && y <= 0 && d.width >= e.width && d.height >= e.height;
      if (all) ops = [], clear = true, e.bytes = new Uint8ClampedArray(d.data);
      m = [1, 0, 0, 1, 0, 0], bitmap(__bitmap_new(all ? e.bytes : new Uint8ClampedArray(d.data)), d.width, d.height, x, y), m = was;
    },
    bytes_are(bytes, stays) { const was = m; ops = [], clear = true, e.bytes = bytes, m = [1, 0, 0, 1, 0, 0], bitmap(__bitmap_new(bytes, stays), e.width, e.height, 0, 0), m = was; },
    fillText(t, x, y) { words(t, x, y, c.fillStyle); }, strokeText(t, x, y) { words(t, x, y, c.strokeStyle); },
    drawImage(im, a, b, w, h, dx, dy, dw, dh) {   // (another canvas, a createGraphics: what it holds painted again here)
      const from = im && im.flat;
      if (!from) return;
      if (dx === undefined) dx = a, dy = b, dw = w === undefined ? im.width : w, dh = h === undefined ? im.height : h, a = b = 0, w = im.width, h = im.height;
      const o = from === c ? ops.slice() : from.held(), sx = dw / w, sy = dh / h, U = x => dx + (x - a) * sx, V = y => dy + (y - b) * sy, grow = large() * Math.sqrt(Math.abs(sx * sy)), P = (x, y) => { const u = U(x), v = V(y); ops.push(X(u, v), Y(u, v)); };
      for (let i = 0; i < o.length;) {
        const kind = o[i], n = o[i + 9], more = o[i + 10], end = i + 12 + n;
        for (let j = 0; j < 12; ++j) ops.push(j === 6 && kind !== 3 ? o[i + 6] * grow : j === 11 ? __L : j === 4 ? o[i + 4] * c.globalAlpha : j === 5 ? __blends[c.globalCompositeOperation] || o[i + 5] : o[i + j]);   // (what another canvas holds shows where image() says it does)
        let q = i + 12;
        if (kind >= 3) {
          const part = kind === 4 ? [Math.max(o[q + 9], (a - o[q + 4]) / o[q]), Math.max(o[q + 10], (b - o[q + 5]) / o[q + 3]), Math.min(o[q + 9] + o[q + 11], (a + w - o[q + 4]) / o[q]), Math.min(o[q + 10] + o[q + 12], (b + h - o[q + 5]) / o[q + 3])] : null;   // (the part of a picture asked for: as it stands, not turned)
          ops.push(m[0] * sx * o[q] + m[2] * sy * o[q + 1], m[1] * sx * o[q] + m[3] * sy * o[q + 1], m[0] * sx * o[q + 2] + m[2] * sy * o[q + 3], m[1] * sx * o[q + 2] + m[3] * sy * o[q + 3]), P(o[q + 4], o[q + 5]), q += 6;
          if (part) ops.push(o[q], o[q + 1], o[q + 2], part[0], part[1], part[2] - part[0], part[3] - part[1], c.imageSmoothingEnabled ? 0 : 1), q = end;
          while (q < end) ops.push(o[q++]);
        } else while (q < end) { const t = o[q++]; ops.push(t); for (let p = t === 2 ? 3 : t === 3 ? 0 : 1; p > 0; --p, q += 2) P(o[q], o[q + 1]); }
        if (more && o[q] === 3) { const L = [m[0] * sx, m[1] * sx, m[2] * sy, m[3] * sy]; ops.push(3, L[0] * o[q + 1] + L[2] * o[q + 2], L[1] * o[q + 1] + L[3] * o[q + 2], L[0] * o[q + 3] + L[2] * o[q + 4], L[1] * o[q + 3] + L[3] * o[q + 4]), P(o[q + 5], o[q + 6]); for (let j = q + 7; j < q + more; ++j) ops.push(o[j]); }
        else if (more) { ops.push(o[q]), P(o[q + 1], o[q + 2]), ops.push(o[q + 3] * grow), P(o[q + 4], o[q + 5]), ops.push(o[q + 6] * grow); for (let j = q + 7; j < q + more; ++j) ops.push(o[j]); }
        i = end + more;
      }
    },
    clip() {}, setLineDash() {}, getLineDash() { return []; }, isPointInPath() { return false; }, isPointInStroke() { return false; }, getContextAttributes() { return {}; },
    held() { return ops; }, take() { const o = Float64Array.from(ops), was = clear; ops = [], clear = false; return [was, o]; },
    fresh() { const o = Float64Array.from(ops.slice(clear ? 0 : seen)), was = clear; clear = false, seen = ops.length; return [was, o]; } };   // (what came since it was last asked, what it holds staying: another canvas's own picture)
  return c;
}
function __element(tag) {
  const kids = [], name = String(tag).toUpperCase();
  const e = { tagName: name, nodeName: name, style: {}, width: 100, height: 100, id: '', className: '', dataset: {}, childNodes: kids, children: kids, classList: { add() {}, remove() {}, contains() { return false; } },
    appendChild(c) { kids.push(c); c.parentNode = e; return c; }, removeChild() {}, remove() {}, setAttribute() {}, getAttribute() { return null; }, hasAttribute() { return false; }, addEventListener() {}, removeEventListener() {}, getBoundingClientRect() { return { left: 0, top: 0, width: e.width, height: e.height }; },
    querySelector() { return __element('div'); }, querySelectorAll() { return []; }, getElementsByTagName() { return []; }, focus() {}, blur() {},
    append(...c) { c.forEach(k => typeof k === 'object' && e.appendChild(k)); }, prepend() {}, replaceChildren() { kids.length = 0; }, replaceWith() {}, insertBefore(c) { return e.appendChild(c); }, insertAdjacentHTML() {}, insertAdjacentElement() {}, after() {}, before() {},
    closest() { return null; }, matches() { return false; }, contains() { return false; }, click() {}, cloneNode() { return __element(tag); }, removeAttribute() {}, toggleAttribute() {}, scrollIntoView() {}, dispatchEvent() {}, setPointerCapture() {}, releasePointerCapture() {},
    getContext(kind) { if (kind === '2d') return e.flat = e.flat || __flat(e); const c = __any('context'); c.getParameter = () => 16384; return c; } };   // (how large a texture may be: p5 clamps the canvas to it)
  e.scrollWidth = e.clientWidth = 100, e.parentNode = globalThis.__main || null;
  return e;
}
// The clock is the sketch's, not the wall's: Date, setTimeout and setInterval as timesnap has them (lib/overwrite-time.js), its
// frames stepped by hand; what waits on them comes when the frames reach them. The wall's is cached for how long to wait for a sketch.
const __wall = Date.now, __began = __wall(), __WallDate = Date;
globalThis.Date = class extends __WallDate { constructor(...a) { if (a.length) super(...a); else super(__began + __T); } static now() { return __began + __T; } };
var __timers = [], __timer = 0;
function __later(f, ms, every, args) { __timers.push({ id: ++__timer, at: __T + (+ms || 0), f, every: every ? Math.max(+ms || 0, 1) : 0, args }); return __timer; }
function __unlater(id) { __timers = __timers.filter(t => t.id !== id); }
function __timers_due() {
  for (const t of __timers.filter(q => q.at <= __T).sort((p, q) => p.at - q.at)) {
    if (t.every) t.at += t.every * Math.ceil((__T - t.at + 1) / t.every); else __unlater(t.id);
    if (typeof t.f === 'function') t.f(...t.args);
  }
}
var __main = __element('main'), __ids = {};   // (a page's parts it asks for by name: there, and nothing comes of them. p5 counts up its own canvases' names until one is not there)
var __page = { window: globalThis, self: globalThis, document: Object.assign(__element('document'), { readyState: 'complete', body: __element('body'), documentElement: __element('html'), head: __element('head'), createElement: __element, createElementNS: (_, t) => __element(t), createTextNode: () => __element('text'), getElementById: id => /^(defaultCanvas|p5_loading)/.test(id) ? null : __ids[id] = __ids[id] || Object.assign(__element('div'), { id, parentNode: __main }), getElementsByTagName: t => t === 'main' ? [__main] : [], hasFocus: () => true, fonts: __any('fonts'), hidden: false }),
  location: { href: '', search: '', pathname: '/', hostname: 'localhost', protocol: 'file:', origin: 'file://' }, screen: { width: 1920, height: 1080 }, navigator: { userAgent: '', platform: '', language: 'en' },
  mocha: true,   // (p5 starts by itself after a promise, not when it is run under a test: new p5() below is the start)
  innerWidth: 1920, innerHeight: 1080, devicePixelRatio: 1, pageXOffset: 0, pageYOffset: 0, scrollX: 0, scrollY: 0,
  addEventListener() {}, removeEventListener() {}, dispatchEvent() {}, getComputedStyle: () => ({ getPropertyValue: () => '' }), matchMedia: () => ({ matches: false, addListener() {}, addEventListener() {} }),
  requestAnimationFrame: f => (__Q.push(f), __Q.length), cancelAnimationFrame() {}, setTimeout: (f, ms, ...a) => __later(f, ms, false, a), clearTimeout: __unlater, setInterval: (f, ms, ...a) => __later(f, ms, true, a), clearInterval: __unlater,
  performance: { now: () => __T, mark() {}, measure() {} }, console: { log() {}, warn() {}, error() {}, info() {}, debug() {}, trace() {}, table() {}, group() {}, groupCollapsed() {}, groupEnd() {}, time() {}, timeEnd() {}, timeLog() {}, assert() {}, count() {}, countReset() {}, dir() {}, clear() {} }, URL: { createObjectURL: () => '' },
  fetch: r => {   // (a file that came with it, by the last part of its name, as loadImage's: p5's loadTable, loadJSON and loadStrings, d3.csv and the like. No net)
    const u = typeof r === 'string' ? r : r && r.url, t = typeof u === 'string' ? __text_read(u) : null;
    if (t === null) return Promise.reject(new Error('no net: ' + u));
    const bytes = () => Uint8Array.from(unescape(encodeURIComponent(t)), c => c.charCodeAt(0)).buffer;
    return Promise.resolve({ ok: true, status: 200, url: u, body: t, headers: { get: () => null }, text: async () => t, json: async () => JSON.parse(t), arrayBuffer: async () => bytes(), clone() { return this; } });
  },
  Request: function (u, o) { this.url = u, Object.assign(this, o); },
  Image: function () { return __element('img'); } };
for (const k of ['Headers', 'Response', 'HTMLElement', 'HTMLCanvasElement', 'Element', 'Node', 'ImageData', 'FileReader', 'Blob', 'XMLHttpRequest', 'DOMMatrix', 'Path2D', 'WebGL2RenderingContext', 'WebGLRenderingContext', 'Event', 'MouseEvent', 'TouchEvent', 'KeyboardEvent', 'WheelEvent', 'CustomEvent', 'FontFace']) __page[k] = function () {};
for (const k in __page) Object.defineProperty(globalThis, k, { value: __page[k], writable: true, configurable: true });

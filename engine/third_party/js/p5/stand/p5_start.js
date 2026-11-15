new p5();
__jobs();   // (the files preload() asked for, read at once: fetch above)
if (!globalThis.frameCount && (p5.instance._preloadCount || globalThis._preloadCount)) p5.instance._preloadCount = globalThis._preloadCount = 0, p5.instance._runIfPreloadsAreDone();   // (what preload() asked of the net or of files does not come: on without it)
var __frames = [], __from = [];
Object.defineProperty(globalThis, '__2d', { get: () => !p5.instance._renderer.isP3D });   // (asked late: an async setup() makes its canvas after new p5())
Object.defineProperty(globalThis, '__canvas', { get: () => p5.instance._renderer.drawingContext });
function __to(f) {
  if (!__frames.length) __U = 3.2154 / (globalThis.height || 400), p5.instance._lastTargetFrameTime = -Infinity;   // (here, not after new p5(): an async setup() has its size only by now. p5's _draw waits a frame's time after setup, and at frameRate(30) that is a first frame with nothing on it)
  while (__frames.length <= f) {
    const was = globalThis.frameCount, q = __Q, last = __frames[__frames.length - 1];
    if (q.length) __placed = [];
    if (__film) __film_step();
    __T += 1000 / 60, __Q = [];
    if (globalThis.__audio_step) __audio_step();   // (what listens hears on: web_audio_stand.h)
    __timers_due();
    q.forEach(g => g(__T));
    __jobs();   // (what was awaiting them goes on)
    if (__2d) {   // (2D: what each frame adds to the one before, as its canvas keeps what was painted; __from: the frame it was last wiped at)
      const [wiped, o] = __canvas.take();
      __from.push(wiped || !__frames.length ? __frames.length : __from[__from.length - 1]), __frames.push(o);
    } else __frames.push(last && globalThis.frameCount === was ? last : Float64Array.from(__placed)), __mesh_done();   // (a noLoop(), a frameRate(30): as it was)
  }
}
function __shaded_take(seconds) {   // (the shader that paints its stage and what the sketch tells it every 0.1 second, a few seconds of waiting at most: "" none)
  const told = {}, from = __wall();
  for (let k = 0; k <= seconds * 10 && __wall() - from < 5000; ++k) {
    __to(k * 6);
    if (!__shaded && k < 2) continue;
    if (!__shaded || __draws_most > 1) return '';
    const now = __shaded.__told || {};
    for (const n in now) {
      const row = told[n] = told[n] || [];
      while (row.length < k) row.push(now[n]);   // (told late: as if from the first)
      row.push(now[n]);
    }
  }
  return JSON.stringify({ vert: __shaded._vertSrc, frag: __shaded._fragSrc, kind: __shaded_kind, width: globalThis.width, height: globalThis.height, density: pixelDensity(), told });
}
function __paints(f, had, pic) {   // (what makes frame f on a canvas holding frame `had`: all since it was last wiped, or if `had` is on that way only what came after it; first a 1 if it is to be wiped)
  __to(f);
  const q = __tex[pic], frames = q ? q.frames : __frames, from = q ? q.from : __from;
  if (from[f] === undefined) return Float64Array.of(1);   // (a picture it had not drawn with yet)
  const go = had >= from[f] && had <= f, first = go ? had + 1 : from[f];
  let n = 1;
  for (let i = first; i <= f; ++i) n += frames[i].length;
  const all = new Float64Array(n);
  all[0] = go ? 0 : 1;
  for (let i = first, at = 1; i <= f; at += frames[i++].length) all.set(frames[i], at);
  return all;
}
function __most() {   // (as many copies as its first seconds draw at once, a second of waiting at most)
  const from = __wall();
  for (let f = 1; f < 300 && __wall() - from < 1000; ++f) __to(f);
  return Math.max(...__frames.map(c => c.length / 11));
}
function __shape() {   // (only boxes, only balls or only rings, with no lines and no lights of its own: the world's own, as real as any. Any more: as it draws them, document/evaluate/sketch.h)
  __most();
  if (__parts.length || __three) return '';
  const builtin = { box: 'cube', ellipsoid: 'ball', torus: 'ring' }, kinds = Object.keys(__kinds);
  return kinds.length === 1 && builtin[kinds[0]] && !__lined && !__tex.length && !__shaders.length && !__meshes.some(m => m.tris.length || m.rows.length) ? builtin[kinds[0]] : 'sketch';
}
var __by_at = -1, __by = [];
function __three_each(i, f, part) {   // (the frame's meshes by their parts; each part's copies a solid's: adapter.h)
  if (__by_at !== f) {
    __three_whole(), __by_at = f, __by = [];
    const c = __frames[f];
    for (let at = 0; at < c.length; at += 11) { const w = __whole.of[c[at + 9]]; if (w !== undefined) (__by[w] = __by[w] || []).push(at); }
  }
  const at = (__by[part] || [])[i], c = __frames[f];
  return at === undefined ? { size: 0 } : { x: c[at], y: c[at + 1], z: c[at + 2], scale_x: c[at + 3], scale_y: c[at + 4], scale_z: c[at + 5], rotate: c[at + 6], rotate_y: c[at + 7], rotate_x: c[at + 8] };
}
function __three_parts() { return __three_whole().first.length; }
function each(i, n, t, k) {
  const f = Math.max(0, Math.round(t * 60));
  __to(f);
  if (__parts.length || __three) return __three_each(i, f, k.part | 0);
  const c = __frames[f], at = i * 11, strong = (k && k['line_' + c[at + 9]]) ?? 1;   // (its line's parameter: what that line drew grows out of nothing)
  return at < c.length ? { x: c[at], y: c[at + 1], z: c[at + 2], scale_x: c[at + 3] * strong, scale_y: c[at + 4] * strong, scale_z: c[at + 5] * strong, rotate: c[at + 6], rotate_y: c[at + 7], rotate_x: c[at + 8], colour: c[at + 10] } : { size: 0 };
}

// What a sketch's camera or video sees is the film under it: it asks as p5 lets it (createCapture, createVideo) and reads it
// as a p5.Image, by get() and pixels; its image(video) paints nothing, the film itself being there underneath. A picture
// it loads is that film too where there is one, so what reads a photo reads the film each frame.
var __film = null, __film_at = undefined;
function __film_first() { return __film_at === undefined ? __film_at = __film_next() : __film_at; }
function __film_open() {
  if (__film) return __film;
  const first = __film_first() || { w: 320, h: 180, data: null };
  const im = __film = new p5.Image(first.w, first.h), none = () => im;
  __film.source = first;
  Object.assign(im, { hide: none, show: none, play: none, pause: none, stop: none, loop: none, noLoop: none, autoplay: none, volume: none, speed: none, time: () => __T / 1000, duration: () => 600, position: none, style: none, parent: none, id: none, class: none, attribute: none, showControls: none, hideControls: none, elt: im.canvas,
    size(w, h) { if (w === undefined) return { width: im.width, height: im.height }; if (h === undefined || h === 'auto') h = w * first.h / first.w; if (w === 'auto') w = h * first.w / first.h; im.width = im.canvas.width = Math.round(w), im.height = im.canvas.height = Math.round(h); __film_show(); return im; } });
  __film_show();
  return im;
}
function __film_show() {   // (at the size it was asked for, each its nearest of the film's)
  const s = __film.source, w = __film.width, h = __film.height;
  if (!s.data) return;
  const from = new Uint8ClampedArray(s.data);
  if (w === s.w && h === s.h) { __film.drawingContext.bytes_are(from); return; }
  const out = new Uint8ClampedArray(4 * w * h);
  for (let y = 0, o = 0; y < h; ++y) { const r = Math.floor(y * s.h / h) * s.w; for (let x = 0; x < w; ++x, o += 4) { const p = 4 * (r + Math.floor(x * s.w / w)); out[o] = from[p], out[o + 1] = from[p + 1], out[o + 2] = from[p + 2], out[o + 3] = 255; } }
  __film.drawingContext.bytes_are(out);
}
function __film_step() { const next = __film_next(); if (next) __film.source = next, __film_show(); }
// What the forms of adapter.h paint on is p5's own canvas: asked for by a page's id or built, it is that one; a second built is another.
function __adapter_canvas() {
  const e = drawingContext.canvas, make = document.createElement;
  let given = false;
  e.ownerDocument = document, e.nodeType = 1, document.defaultView = globalThis, document.nodeType = 9;
  document.createElement = t => { if (/^canvas$/i.test(t) && !given) return given = true, e; return make.call(document, t); };
  document.getElementById = document.querySelector = () => (given = true, e);
  document.getElementsByTagName = document.querySelectorAll = () => (given = true, [e]);
  document.getElementsByClassName = () => (given = true, [e]);
}
var tokenData = { hash: '0x' + '6b3d'.repeat(16), tokenId: '1000000' }, fxhash = 'oo' + 'Mot0lii'.repeat(7), fxrand = Math.random, $fx = { hash: fxhash, rand: fxrand, minter: 'tz1', iteration: 1, context: 'standalone', preview() {}, isPreview: false, features() {}, getFeature() {}, getFeatures: () => ({}), params() {}, getParam() {}, getParams: () => ({}), on() {}, emit() {} };   // (what Art Blocks' and fxhash's pages give a work: a seed, here always the same)
// p5.sound, when its file is not beside p5's (script_runner.cpp reads it from addons/): what a sketch asks of it is there and silent, so that what it draws is drawn.
for (const k of ['SoundFile', 'FFT', 'Amplitude', 'Oscillator', 'SinOsc', 'TriOsc', 'SawOsc', 'SqrOsc', 'Noise', 'Envelope', 'Env', 'AudioIn', 'Reverb', 'Delay', 'Filter', 'LowPass', 'HighPass', 'BandPass', 'PeakDetect', 'Part', 'Phrase', 'Score', 'SoundLoop', 'Gain', 'Pulse', 'MonoSynth', 'PolySynth', 'Panner3D', 'Distortion', 'Compressor', 'EQ', 'Convolver', 'SoundRecorder', 'Signal', 'Effect'])
  p5[k] = p5[k] || function () { return __any('p5.' + k); };
for (const k of ['loadSound', 'getAudioContext', 'userStartAudio', 'soundFormats', 'outputVolume', 'getOutputVolume', 'masterVolume', 'sampleRate'])
  globalThis[k] = globalThis[k] || function () { return __any(k); };
const __load_image = p5.prototype.loadImage;
const __promised = im => Object.assign(im, { then(ok) { delete im.then, delete im.catch; if (ok) ok(im); return Promise.resolve(im); }, catch() { return im; } });   // (p5 2's loadImage is a promise, 1's the picture itself: it is both, until it has been waited for)
p5.prototype.loadImage = function (path, ok) {   // (a picture that came with it; none, the film under it: what it puts over a picture it puts over yours)
  const read = typeof path === 'string' ? __image_read(path) : null;
  let f;
  if (read) f = new p5.Image(read.w, read.h), f.drawingContext.bytes_are(new Uint8ClampedArray(read.data), true);
  else if (!__film_first()) return __promised(__load_image.apply(this, arguments));
  else f = __film_open();
  if (typeof ok === 'function') ok(f);
  return __promised(f);
};
p5.prototype.createCapture = p5.prototype.createVideo = function () { const f = __film_open(), ready = [...arguments].find(a => typeof a === 'function'); if (ready) ready(f); return f; };
const __packed = c => c ? Math.round(c[0] * 255) << 16 | Math.round(c[1] * 255) << 8 | Math.round(c[2] * 255) : -1;   // (a copy's colour, red green blue; -1: its own solid's)
var __placed = [], __kinds = {}, __U = 0.01;   // (a pixel of the sketch in the world's unit: as tall as the stage as it comes, new p5() below)
globalThis.flex = () => {};   // (p5.flex, how a canvas sits on its page: there is no page)
// OpenProcessing's configurator, by its README (github.com/msawired/OPC, MIT): each call makes a global of that name, at its first value.
var OPC = new Proxy({}, { get(t, k) {
  const first = { toggle: o => true, color: o => '#333333', palette: o => o.options[0], select: o => Array.isArray(o.options) ? o.options[0] : Object.values(o.options)[0] }[k] || (o => null);
  if (k === 'bezier') return (name) => { globalThis[typeof name === 'object' ? name.name : name] = t => t; };
  if (k === 'palette' || k === 'select') return (a, options, value) => { const o = typeof a === 'object' ? a : { name: a, options, value }; globalThis[o.name] = o.value ?? first(o); };
  if (['slider', 'toggle', 'text', 'button', 'color', 'label'].includes(k)) return (a, value) => { const o = typeof a === 'object' ? a : { name: a, value }; globalThis[o.name] = o.value ?? first(o); };
  return () => {};
} });

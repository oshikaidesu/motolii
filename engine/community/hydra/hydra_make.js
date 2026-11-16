// JavaScript module that runs inside QuickJS to turn Hydra code (global
// __code) into an ISF effect (global __isf), with its time-varying numbers
// captured as keyframes (global __parameters) by sampling them every __step
// seconds up to __seconds. On failure it sets __why.
//
// Not loaded as a shelf: it is motolii's own glue between Hydra's
// generator-factory.js and the ISF text that community/isf runs.
import Generator from './generator-factory.js'
import arrayUtils from './lib/array-utils.js'
import utility from './glsl/utility-functions.js'
try {
  const outs = {}, cached = [], names = ['o0', 'o1', 'o2', 'o3'];
  const output = n => ({ name: n, precision: 'highp', getTexture() { return this; }, render(p) { outs[n] = p[0]; } });
  const source = n => { const s = { name: n, getTexture() { return this; } }; for (const k of ['initCam', 'initImage', 'initVideo', 'initScreen', 'initStream', 'init', 'clear']) s[k] = () => s; return s; };
  const g = globalThis, o = names.map(output);
  arrayUtils.init();
  const synth = new Generator({ defaultUniforms: { time: 0, resolution: [1920, 1080] }, defaultOutput: o[0], changeListener() {} });
  const told = v => typeof v === 'number' ? () => v : v;   // (a number as a function: Hydra makes it a uniform)
  for (const [k, f] of Object.entries(synth.generators)) g[k] = (...a) => f(...a.map(told));
  const P = synth.sourceClass.prototype;
  for (const k of Object.keys(synth.glslTransforms)) if (P[k]) { const was = P[k]; P[k] = function (...a) { return was.apply(this, a.map(told)); }; }
  o.forEach(x => g[x.name] = x);
  ['s0', 's1', 's2', 's3'].forEach(n => g[n] = source(n));
  let shown = o[0];
  Object.assign(g, { time: 0, bpm: Object.assign(() => {}, { valueOf: () => 30 }), speed: 1, width: 1920, height: 1080, mouse: { x: 0, y: 0 }, a: { fft: [0, 0, 0, 0], show() {}, hide() {}, setBins() {}, setSmooth() {}, setCutoff() {}, setScale() {} }, render: x => { shown = x || o[0]; }, hush() {}, update() {}, setResolution() {}, setFunction: f => synth.setFunction(f), setBins() {}, console: { log() {}, warn() {}, error() {} } });
  (0, eval)(g.__code);
  const built = names.filter(n => outs[n]);
  if (!built.length) throw new Error('nothing was sent to an output');
  let head = '', bodies = {}, inputs = [], reads = false;
  const sampled = f => { const all = []; for (let t = 0; t <= g.__seconds + 1e-9; t += g.__step) { g.time = t * g.speed; let v = 0; try { v = f(null, { time: g.time, bpm: g.bpm }, 0); } catch (e) {} all.push(typeof v === 'number' && isFinite(v) ? v : 0); } return all; };
  const fns = new Set();
  for (const n of built) {
    const { frag, uniforms } = outs[n];
    for (const k of Object.keys(synth.glslTransforms)) if (frag.includes(synth.glslTransforms[k].glsl)) fns.add(k);
    let body = frag.slice(frag.indexOf('void main'));
    body = body.slice(body.indexOf('{') + 1, body.lastIndexOf('}'));
    for (const [name, value] of Object.entries(uniforms)) {
      if (name === 'time' || name === 'resolution') continue;
      const own = n === 'o0' ? name : name + '_' + n, word = new RegExp('\\b' + name + '\\b', 'g');
      if (typeof value === 'function') {
        const first = value(null, { time: 0, bpm: g.bpm }, 0);
        if (first && first.getTexture) {
          const t = first.name[0] === 's' ? (reads = true, 'inputImage') : first.name;
          body = body.replace(new RegExp('\\bsrc\\(\\s*([^,]+?),\\s*' + name + '\\s*\\)', 'g'), 'IMG_NORM_PIXEL(' + t + ',fract($1))');   // (a sampler is not passed in ISF: read where it is named)
          if (t !== 'inputImage' && !cached.includes(t)) cached.push(t);
          continue;
        }
        const all = sampled(value), low = Math.min(...all), high = Math.max(...all);
        inputs.push({ NAME: own, TYPE: 'float', DEFAULT: all[0], MIN: Math.min(0, low * 2), MAX: Math.max(1, high * 2) });
        if (low !== high) (g.__moving = g.__moving || []).push({ name: own, keys: all });
      }
      if (own !== name) body = body.replace(word, own);
    }
    bodies[n] = body;
  }
  fns.delete('src');
  head = Object.values(utility).map(t => t.glsl).join('\n') + [...fns].map(k => synth.glslTransforms[k].glsl).join('\n');
  const passes = built.length > 1 || cached.length ? built.map(n => n).concat(cached.filter(n => !built.includes(n))) : [];
  const isf = { ISFVSN: '2', DESCRIPTION: 'Hydra', CATEGORIES: ['Hydra'], INPUTS: (reads ? [{ NAME: 'inputImage', TYPE: 'image' }] : []).concat(inputs) };
  if (passes.length) isf.PASSES = passes.map(n => ({ TARGET: n, PERSISTENT: true })).concat([{}]);
  let main = '';
  for (const n of Object.keys(bodies)) main += 'void adapter_' + n + '(){' + bodies[n] + '}\n';
  if (passes.length) {
    main += 'void main(){';
    passes.forEach((n, i) => main += 'if(PASSINDEX==' + i + '){' + (bodies[n] ? 'adapter_' + n + '();' : 'gl_FragColor=vec4(0.,0.,0.,1.);') + 'return;}');
    main += 'gl_FragColor=IMG_NORM_PIXEL(' + shown.name + ',isf_FragNormCoord);}\n';
  } else main += 'void main(){adapter_' + shown.name + '();}\n';
  g.__isf = '/*' + JSON.stringify(isf) + '*/\n' + head + '\n' + main;
  g.__parameters = JSON.stringify(g.__moving || []);
} catch (e) { globalThis.__why = String(e) + ' ' + (e.stack || ''); }

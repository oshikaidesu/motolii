#ifndef MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_
#define MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_

// Web Audio with no page and no loudspeaker, for a sketch that listens: what
// p5.sound (third_party/js/p5/addons, its file as it is released) and code
// written against the W3C Web Audio API ask of a browser in order to hear a
// sound and measure it. p5.sound itself runs on it unchanged: its SoundFile,
// FFT and Amplitude are its own code, and the worklet processors it brings
// are run as it wrote them.
//
// What is real here:
//   - The graph. Nodes remember what is connected to what, and what a node
//     hears is each sounding source that reaches it, times the gains on the
//     way (GainNode, and the fixed gain a DynamicsCompressorNode ends with)
//     and later by the delays on the way (DelayNode, the compressor's 6 ms).
//   - AnalyserNode: one asking a frame, by the specification's steps
//     (media/sound_level.h's analyser_asked), with its own fftSize,
//     smoothingTimeConstant, minDecibels and maxDecibels.
//   - AudioWorkletNode: the processor a module registers is run on the sound
//     its node hears, 128 samples at a time, and its port carries messages.
//   - Time: the context's currentTime is the sketch's own clock (p5_stand.h),
//     so a frame hears the same thing every time it is drawn.
// The sound: an AudioBuffer made by decodeAudioData from a file the sketch
// asked for by its address (loadSound) is the sound of the video or sound
// layer under the sketch, as the video a sketch sees is the layer under it. It
// is where the timeline is, whatever second the sketch starts or loops it at:
// start() and stop() only say whether it is heard. A buffer the sketch fills
// itself plays its own samples.
//
// Not here: sound that the page itself makes (oscillators, noise) is silent
// and nothing a sketch plays is heard in the export; filters, panners,
// convolvers and wave shapers are passed through unchanged; a value set to
// ramp arrives at once; a compressor only applies its fixed gain and delay;
// a sound is one channel, the mix of the file's; ScriptProcessorNode never
// calls back; microphones and <audio> elements give nothing; the clock
// Tone.js keeps in a Worker never ticks, so p5.Part, p5.Phrase and
// p5.SoundLoop do not run.
//
// Nobody is in front of the page: a sketch that has asked for a sound and
// started none by the end of its first frame is clicked once, in the middle
// of its canvas, as the visitor it waits for would ("tap to play").
//
// Evaluated after p5_before (the page) and before p5.sound.

namespace motolii {

inline const char* const web_audio_stand = R"JS(
{
const RATE = 48000, QUANTUM = 128, contexts = [], urls = new Map();
const lin = d => Math.pow(10, d / 20), db = x => 20 * Math.log10(x);
let wants = false, pressed = false;

class AudioParam {
  constructor(v) { this.value = this.defaultValue = v, this.minValue = -3.4028234663852886e38, this.maxValue = 3.4028234663852886e38, this.automationRate = 'a-rate'; }
  setValueAtTime(v) { return this.value = v, this; }
  setValueCurveAtTime(c) { return this.value = c[c.length - 1], this; }
  cancelScheduledValues() { return this; }
  cancelAndHoldAtTime() { return this; }
}
AudioParam.prototype.linearRampToValueAtTime = AudioParam.prototype.exponentialRampToValueAtTime = AudioParam.prototype.setTargetAtTime = AudioParam.prototype.setValueAtTime;

class Listened {   // (EventTarget)
  addEventListener(type, f) { const on = this.__on || (this.__on = {}); (on[type] || (on[type] = [])).push(f); }
  removeEventListener(type, f) { const l = this.__on && this.__on[type], i = l ? l.indexOf(f) : -1; if (i >= 0) l.splice(i, 1); }
  dispatchEvent(e) {
    e.target = e.currentTarget = this;
    for (const f of (this.__on && this.__on[e.type] || []).slice()) f.call(this, e);
    if (typeof this['on' + e.type] === 'function') this['on' + e.type](e);
    return true;
  }
}

class AudioNode extends Listened {
  constructor(context, params, more) {
    super();
    this.context = context, this.__to = new Set(), this.__from = new Set();
    this.numberOfInputs = this.numberOfOutputs = 1, this.channelCount = 2, this.channelCountMode = 'max', this.channelInterpretation = 'speakers';
    for (const k in params) this[k] = new AudioParam(params[k]);
    Object.assign(this, more);
  }
  connect(to) { if (to instanceof AudioNode) this.__to.add(to), to.__from.add(this); return to; }
  disconnect(to) { for (const t of to instanceof AudioNode ? [to] : [...this.__to]) this.__to.delete(t), t.__from.delete(this); }
  __gain() { return 1; }
  __delay() { return 0; }
}
// Adds to `out` what `node` hears at second `at` of its context: the samples up to then of every source that reaches it.
function hear(node, out, at, gain, seen) {
  for (const from of node.__from) {
    if (seen.has(from)) continue;
    if (from.__plays) { from.__plays(out, at, gain); continue; }
    const g = gain * from.__gain();
    if (g) seen.add(from), hear(from, out, at - from.__delay(), g, seen), seen.delete(from);
  }
}

class GainNode extends AudioNode {
  constructor(context, o) { super(context, { gain: o && o.gain !== undefined ? o.gain : 1 }); }
  __gain() { return this.gain.value; }
}
class DelayNode extends AudioNode {
  constructor(context, o) { super(context, { delayTime: o && o.delayTime || 0 }); }
  __delay() { return this.delayTime.value; }
}
class DynamicsCompressorNode extends AudioNode {
  constructor(context, o) { super(context, Object.assign({ threshold: -24, knee: 30, ratio: 12, attack: 0.003, release: 0.25 }, o), { reduction: 0 }); }
  // The gain it ends with, whatever comes in: the 0.6 power of what would bring a full-scale sound back up after its
  // curve (W3C Web Audio API, section 1.19.4 "Computing the makeup gain"), with the curve of the knee that the
  // specification leaves to the browser taken as Chromium has it (DynamicsCompressorKernel: an exponential that
  // leaves the threshold at slope 1 and reaches the slope of the ratio where the knee ends).
  __gain() {
    const T = this.threshold.value, K = this.knee.value, R = this.ratio.value, t = lin(T), end = lin(T + K);
    const curve = (x, k) => x < t ? x : t + (1 - Math.exp(-k * (x - t))) / k;
    const slope = (x, k) => x < t ? 1 : (db(curve(x * 1.001, k)) - db(curve(x, k))) / (db(x * 1.001) - db(x));
    let low = 0.1, high = 10000, k = 5;
    for (let i = 0; i < 15; i++) { if (slope(end, k) < 1 / R) high = k; else low = k; k = Math.sqrt(low * high); }
    const full = 1 < end ? curve(1, k) : lin(db(curve(end, k)) + (0 - (T + K)) / R);
    return Math.pow(1 / full, 0.6);
  }
  __delay() { return 0.006; }   // (it looks 6 ms ahead: Chromium's pre-delay)
}
class AnalyserNode extends AudioNode {
  constructor(context, o) {
    super(context);
    o = o || {};
    this.minDecibels = o.minDecibels !== undefined ? o.minDecibels : -100, this.maxDecibels = o.maxDecibels !== undefined ? o.maxDecibels : -30;
    this.smoothingTimeConstant = o.smoothingTimeConstant !== undefined ? o.smoothingTimeConstant : 0.8, this.fftSize = o.fftSize || 2048;
  }
  get fftSize() { return this.__size; }
  set fftSize(n) {
    if (!(n >= 32 && n <= 32768) || (n & (n - 1))) throw new RangeError('IndexSizeError: an fftSize is a power of two from 32 to 32768');
    if (n !== this.__size) this.__size = n, this.__smooth = new Float64Array(n / 2), this.__asked = -1;
  }
  get frequencyBinCount() { return this.__size / 2; }
  __wave() { const w = new Float32Array(this.__size); hear(this, w, this.context.currentTime, 1, new Set()); return w; }
  __spectrum() {   // (one asking a frame, as a page asks once each time it draws)
    if (this.__asked !== __T) __analyser(this.__wave(), this.__smooth, this.smoothingTimeConstant), this.__asked = __T;
    return this.__smooth;
  }
  getFloatTimeDomainData(a) { const w = this.__wave(); for (let i = 0; i < a.length && i < w.length; i++) a[i] = w[i]; }
  getByteTimeDomainData(a) { const w = this.__wave(); for (let i = 0; i < a.length && i < w.length; i++) a[i] = Math.max(0, Math.min(255, Math.floor(128 * (1 + w[i])))); }
  getFloatFrequencyData(a) { const s = this.__spectrum(); for (let i = 0; i < a.length && i < s.length; i++) a[i] = db(s[i]); }
  getByteFrequencyData(a) {
    const s = this.__spectrum(), low = this.minDecibels, per = 255 / (this.maxDecibels - low);
    for (let i = 0; i < a.length && i < s.length; i++) a[i] = Math.max(0, Math.min(255, Math.floor(per * (db(s[i]) - low)))) || 0;
  }
}

class AudioBuffer {
  constructor(o) { this.numberOfChannels = o.numberOfChannels || 1, this.length = o.length, this.sampleRate = o.sampleRate, this.duration = o.length / o.sampleRate, this.__data = []; }
  getChannelData(c) {
    if (!this.__data[c]) {
      const d = this.__data[c] = new Float32Array(this.length);
      if (this.__film) __sound_wave(d, this.duration);
    }
    return this.__data[c];
  }
  copyFromChannel(to, c, from) { to.set(this.getChannelData(c).subarray(from || 0, (from || 0) + to.length)); }
  copyToChannel(of, c, from) { this.getChannelData(c).set(of, from || 0); }
  __wave(out, at) {   // (the out.length samples before second `at` of it)
    if (this.__film) return __sound_wave(out, at);
    const d = this.getChannelData(0), end = Math.round(at * this.sampleRate), n = out.length;
    for (let i = 0; i < n; i++) { const k = end - n + i; out[i] = k >= 0 && k < d.length ? d[k] : 0; }
  }
}

class Scheduled extends AudioNode {   // (AudioScheduledSourceNode: a source that makes its own sound is silent here)
  constructor(context, params, more) { super(context, params, more); this.numberOfInputs = 0; }
  start(when) { this.__start = Math.max(when || 0, this.context.currentTime), this.context.__sources.add(this), this.context.__started = true; }
  stop(when) { this.__stop = Math.max(when || 0, this.context.currentTime); }
  __over(now) { return this.__stop !== undefined && now >= this.__stop; }
}
class AudioBufferSourceNode extends Scheduled {
  constructor(context, o) { super(context, { playbackRate: 1, detune: 0 }, Object.assign({ buffer: null, loop: false, loopStart: 0, loopEnd: 0 }, o)); }
  start(when, offset, lasts) { super.start(when), this.__offset = offset || 0, this.__lasts = lasts; }
  __at(t) {   // (the second of its buffer that sounds at second t of the context; undefined while it is silent)
    const b = this.buffer;
    if (!b || this.__start === undefined || t < this.__start || (this.__stop !== undefined && t >= this.__stop)) return undefined;
    if (b.__film) return t <= b.duration ? t : undefined;   // (the timeline's sound is where the timeline is)
    let at = this.__offset + (t - this.__start) * this.playbackRate.value;
    if (this.loop) {
      const from = this.loopStart || 0, to = this.loopEnd > from ? this.loopEnd : b.duration;
      if (at >= to && to > from) at = from + (at - from) % (to - from);
    } else if (at > b.duration || (this.__lasts !== undefined && t - this.__start > this.__lasts)) return undefined;
    return at;
  }
  __plays(out, t, gain) {
    const at = this.__at(t);
    if (at === undefined) return;
    const one = new Float32Array(out.length);
    this.buffer.__wave(one, at);
    for (let i = 0; i < one.length; i++) out[i] += gain * one[i];
  }
  __over(now) { return super.__over(now) || (this.buffer && !this.loop && now > this.__start && this.__at(now) === undefined); }
}

function AudioWorkletProcessor() { this.port = AudioWorkletProcessor.__port; }   // (a function, not a class: p5.sound's processors, made for older browsers, call it without new)
class AudioWorkletNode extends AudioNode {
  constructor(context, name, o) {
    super(context);
    const made = context.__processors[name];
    if (!made) throw new Error('InvalidStateError: no processor is registered as ' + name);
    const mine = new Listened(), its = new Listened();
    mine.postMessage = m => its.dispatchEvent({ type: 'message', data: m }), its.postMessage = m => mine.dispatchEvent({ type: 'message', data: m });
    mine.start = its.start = mine.close = its.close = () => {};
    this.port = mine, this.parameters = new Map(), AudioWorkletProcessor.__port = its;
    this.__processor = new made(o || {}), context.__worklets.add(this);
  }
}

class BaseAudioContext extends Listened {
  constructor() {
    super();
    this.sampleRate = RATE, this.state = 'running', this.baseLatency = this.outputLatency = 0;
    this.__processors = {}, this.__worklets = new Set(), this.__sources = new Set(), this.__pumped = 0, this.__started = false;
    this.destination = new AudioNode(this, {}, { maxChannelCount: 2, numberOfOutputs: 0 });
    this.listener = new AudioNode(this, { positionX: 0, positionY: 0, positionZ: 0, forwardX: 0, forwardY: 0, forwardZ: -1, upX: 0, upY: 1, upZ: 0 }, { setPosition() {}, setOrientation() {} });
    this.audioWorklet = { addModule: url => {   // (a module made here from text, as p5.sound makes its three: run now, with what a worklet's scope has)
      const text = urls.get(url);
      if (text === undefined) return Promise.reject(new Error('a module that was not made on this page: ' + url));
      new Function('AudioWorkletProcessor', 'registerProcessor', 'sampleRate', 'currentTime', 'currentFrame', text)(AudioWorkletProcessor, (name, made) => { this.__processors[name] = made; }, RATE, 0, 0);
      return Promise.resolve();
    } };
    contexts.push(this);
  }
  get currentTime() { return __T / 1000; }
  resume() { return Promise.resolve(); }
  suspend() { return Promise.resolve(); }
  close() { return Promise.resolve(); }
  getOutputTimestamp() { return { contextTime: this.currentTime, performanceTime: __T }; }
  createGain() { return new GainNode(this); }
  createDelay() { return new DelayNode(this); }
  createDynamicsCompressor() { return new DynamicsCompressorNode(this); }
  createAnalyser() { return new AnalyserNode(this); }
  createBufferSource() { return new AudioBufferSourceNode(this); }
  createBuffer(channels, length, rate) { return new AudioBuffer({ numberOfChannels: channels, length, sampleRate: rate }); }
  createPeriodicWave() { return {}; }
  decodeAudioData(data, ok) {   // (a sound asked for by its address: the timeline's, see above)
    const b = new AudioBuffer({ numberOfChannels: 1, length: Math.round((data && data.__sound !== undefined ? __sound_seconds() : 0) * RATE), sampleRate: RATE });
    b.__film = true, wants = true;
    if (ok) ok(b);
    return Promise.resolve(b);
  }
}
// The nodes that are passed through unchanged, each with the values it starts with.
const through = {
  createBiquadFilter: [{ frequency: 350, detune: 0, Q: 1, gain: 0 }, { type: 'lowpass', getFrequencyResponse() {} }], createIIRFilter: [{}, { getFrequencyResponse() {} }],
  createStereoPanner: [{ pan: 0 }], createWaveShaper: [{}, { curve: null, oversample: 'none' }], createConvolver: [{}, { buffer: null, normalize: true }],
  createPanner: [{ positionX: 0, positionY: 0, positionZ: 0, orientationX: 1, orientationY: 0, orientationZ: 0 }, { panningModel: 'equalpower', distanceModel: 'inverse', refDistance: 1, maxDistance: 10000, rolloffFactor: 1, coneInnerAngle: 360, coneOuterAngle: 360, coneOuterGain: 0, setPosition() {}, setOrientation() {}, setVelocity() {} }],
  createChannelSplitter: [{}], createChannelMerger: [{}],
  createMediaStreamSource: [{}], createMediaElementSource: [{}], createMediaStreamDestination: [{}, { stream: {} }] };
for (const k in through) BaseAudioContext.prototype[k] = function () { return new AudioNode(this, through[k][0], through[k][1]); };
class ScriptProcessorNode extends AudioNode {}   // (never called back)
BaseAudioContext.prototype.createScriptProcessor = function (size) { return new ScriptProcessorNode(this, {}, { bufferSize: size || 4096, onaudioprocess: null }); };
BaseAudioContext.prototype.createOscillator = function () { return new Scheduled(this, { frequency: 440, detune: 0 }, { type: 'sine', setPeriodicWave() {} }); };
BaseAudioContext.prototype.createConstantSource = function () { return new Scheduled(this, { offset: 1 }); };
class AudioContext extends BaseAudioContext {}
class OfflineAudioContext extends BaseAudioContext {   // (rendered at once, and silent)
  constructor(channels, length, rate) { super(); const o = typeof channels === 'object' ? channels : { numberOfChannels: channels, length, sampleRate: rate }; this.length = o.length, this.__channels = o.numberOfChannels || 1; }
  startRendering() { const b = this.createBuffer(this.__channels, this.length, RATE); this.dispatchEvent({ type: 'complete', renderedBuffer: b }); return Promise.resolve(b); }
}

// What p5.sound asks of the page besides: a file by its address, and a module of text by an address it makes for it.
class XMLHttpRequest extends Listened {
  open(method, url) { this.__url = String(url), this.readyState = 1; }
  setRequestHeader() {} overrideMimeType() {} abort() {} getResponseHeader() { return null; } getAllResponseHeaders() { return ''; }
  send() {   // (bytes are asked for a sound: it is there. Anything else is not)
    const sound = this.responseType === 'arraybuffer';
    this.readyState = 4, this.status = sound ? 200 : 404, this.statusText = sound ? 'OK' : 'Not Found';
    this.response = sound ? Object.assign(new ArrayBuffer(8), { __sound: this.__url }) : null;
    for (const type of ['readystatechange', sound ? 'load' : 'error', 'loadend']) this.dispatchEvent({ type });
  }
}
class Worker extends Listened { postMessage() {} terminate() {} }   // (Tone.js, inside p5.sound, keeps its clock in one: it never ticks here)
class Blob {
  constructor(parts, o) { this.__text = (parts || []).join(''), this.type = o && o.type || '', this.size = this.__text.length; }
  text() { return Promise.resolve(this.__text); }
}
const URL = typeof globalThis.URL === 'function' ? globalThis.URL : function () {};
URL.createObjectURL = b => { const u = 'blob:motolii/' + urls.size; urls.set(u, b && b.__text); return u; }, URL.revokeObjectURL = () => {};
const element = document.createElement;
document.createElement = function (tag) { const e = element.apply(this, arguments); if (/^(audio|video)$/i.test(tag)) e.canPlayType = () => 'probably'; return e; };

function press() {   // (the click of the visitor the sketch waits for: p5's own handlers, and its canvas's)
  const p = p5.instance, r = p && p._renderer, x = (globalThis.width || 100) / 2, y = (globalThis.height || 100) / 2;
  for (const type of ['mousedown', 'mouseup', 'click']) {
    const e = { type, clientX: x, clientY: y, pageX: x, pageY: y, offsetX: x, offsetY: y, button: 0, buttons: 1, which: 1, target: p && p.canvas, touches: [], changedTouches: [], preventDefault() {}, stopPropagation() {} };
    try { if (p && typeof p['_on' + type] === 'function') p['_on' + type](e); } catch (wrong) {}
    try { if (r && r._events && typeof r._events[type] === 'function') r._events[type](e); } catch (wrong) {}
  }
}
// Called once a frame, when the sketch's clock has moved on and before it draws (p5_stand.h's __to).
function step() {
  if (wants && !pressed && typeof __frames !== 'undefined' && __frames.length >= 1 && !contexts.some(c => c.__started)) pressed = true, press();
  for (const c of contexts) {
    for (; c.__pumped + QUANTUM <= c.currentTime * RATE + 1e-6; c.__pumped += QUANTUM)
      for (const w of c.__worklets) {
        if (!w.__from.size) continue;
        const block = new Float32Array(QUANTUM);
        hear(w, block, (c.__pumped + QUANTUM) / RATE, 1, new Set());
        try { w.__processor.process([[block, block]], [[new Float32Array(QUANTUM), new Float32Array(QUANTUM)]], {}); } catch (wrong) { w.dispatchEvent({ type: 'processorerror', error: wrong }); }
      }
    for (const s of [...c.__sources]) if (s.__over(c.currentTime)) c.__sources.delete(s), s.dispatchEvent({ type: 'ended' });
  }
}
Object.assign(globalThis, { AudioParam, AudioNode, GainNode, DelayNode, DynamicsCompressorNode, AnalyserNode, AudioBuffer, AudioBufferSourceNode, AudioWorkletNode, ScriptProcessorNode, BaseAudioContext, AudioContext, OfflineAudioContext, XMLHttpRequest, Blob, Worker, URL, __audio_step: step });
}
)JS";

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_

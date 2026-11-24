// Motolii side of the lottie-web expression runtime: bridges AE.compile /
// AE.run / AE.comp / AE.layer to lottie-web's ExpressionManager, automatically
// wiring thisComp, thisLayer, transform, effect, text, sourceRectAtTime,
// toWorld/fromWorld, sampleImage, keyframes and loopOut/loopIn to the live
// Motolii project while preserving manual AE.comp(spec, [layers]) recipes.

import Expressions from 'motolii-lottie/utils/expressions/Expressions.js';
import ExpressionManager from 'motolii-lottie/utils/expressions/ExpressionManager.js';

if (typeof globalThis.navigator === 'undefined') {
  globalThis.navigator = { userAgent: '' };
}
if (typeof globalThis.window === 'undefined') globalThis.window = null;
if (typeof globalThis.document === 'undefined') globalThis.document = null;

const DEFAULT_FPS = 60;

function hostK() {
  return globalThis.__hostK || {};
}

function hostFps(ctx) {
  if (ctx && typeof ctx.fps === 'number' && ctx.fps > 0) return ctx.fps;
  if (ctx && ctx.k && typeof ctx.k.fps === 'number' && ctx.k.fps > 0) return ctx.k.fps;
  const k = hostK();
  if (typeof k.fps === 'number' && k.fps > 0) return k.fps;
  return DEFAULT_FPS;
}

// Matches script_parameters.cpp's snake_name.
function snakeName(s) {
  return String(s)
    .split('')
    .map((c) => (/\w/.test(c) ? c.toLowerCase() : '_'))
    .join('');
}

function unwrapAe(v) {
  if (v instanceof Number) return v.valueOf();
  return v;
}

function subVec(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) {
    const out = new Array(a.length);
    for (let i = 0; i < a.length; i++) out[i] = (a[i] || 0) - (b[i] || 0);
    return out;
  }
  return (+a || 0) - (+b || 0);
}

function addVec(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) {
    const out = new Array(a.length);
    for (let i = 0; i < a.length; i++) out[i] = (a[i] || 0) + (b[i] || 0);
    return out;
  }
  return (+a || 0) + (+b || 0);
}

function scaleVec(a, s) {
  if (Array.isArray(a)) return a.map((x) => (x || 0) * s);
  return (+a || 0) * s;
}

function vecLen(a) {
  if (!Array.isArray(a)) return Math.abs(+a || 0);
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += (a[i] || 0) * (a[i] || 0);
  return Math.sqrt(sum);
}

// Evaluates AE loopOut/loopIn in seconds over an ascending keyframe time list.
function evalLoop(dir, type, arg, durationFlag, nowSec, evalAt, keyTimes, layerIn, layerOut) {
  if (!keyTimes || keyTimes.length < 2) return evalAt(nowSec);
  const mode = (type ? String(type) : 'cycle').toLowerCase();
  const n = keyTimes.length;
  let t0, t1;
  if (dir === 'out') {
    t1 = keyTimes[n - 1];
    if (nowSec <= t1) return evalAt(nowSec);
    if (durationFlag) {
      const span = arg > 0 ? arg : Math.max(0, t1 - layerIn);
      t0 = t1 - span;
    } else {
      const count = !arg || arg > n - 1 ? n - 1 : Math.max(1, arg | 0);
      t0 = keyTimes[n - 1 - count];
    }
    const span = t1 - t0;
    if (span <= 1e-9) return evalAt(t1);
    if (mode === 'continue') {
      const dt = 0.001;
      const v1 = evalAt(t1);
      const v0 = evalAt(t1 - dt);
      return addVec(v1, scaleVec(subVec(v1, v0), (nowSec - t1) / dt));
    }
    const elapsed = nowSec - t0;
    const iter = Math.floor(elapsed / span);
    const rem = elapsed - iter * span;
    if (mode === 'pingpong' && iter % 2 !== 0) return evalAt(t1 - rem);
    if (mode === 'offset') {
      const delta = subVec(evalAt(t1), evalAt(t0));
      return addVec(evalAt(t0 + rem), scaleVec(delta, iter));
    }
    return evalAt(t0 + rem);
  }
  t0 = keyTimes[0];
  if (nowSec >= t0) return evalAt(nowSec);
  if (durationFlag) {
    const span = arg > 0 ? arg : Math.max(0, layerOut - t0);
    t1 = t0 + span;
  } else {
    const count = !arg || arg > n - 1 ? n - 1 : Math.max(1, arg | 0);
    t1 = keyTimes[count];
  }
  const span = t1 - t0;
  if (span <= 1e-9) return evalAt(t0);
  if (mode === 'continue') {
    const dt = 0.001;
    const v0 = evalAt(t0);
    const v1 = evalAt(t0 + dt);
    return addVec(v0, scaleVec(subVec(v0, v1), (t0 - nowSec) / dt));
  }
  const before = t0 - nowSec;
  const iter = Math.floor(before / span);
  const rem = before - iter * span;
  if (mode === 'pingpong' && iter % 2 === 0) return evalAt(t0 + rem);
  if (mode === 'offset') {
    const delta = subVec(evalAt(t1), evalAt(t0));
    return subVec(evalAt(t1 - rem), scaleVec(delta, iter + 1));
  }
  return evalAt(t1 - rem);
}

// Wraps a live property value so it behaves as both its current JS value
// (array for vectors, boxed Number for scalars) and an AE Property object
// (.value, .valueAtTime, .velocity, .velocityAtTime, .speed, .numKeys, .key,
// .nearestKey, .loopOut, .loopIn, .smooth).
function makeLiveProp(evalAt, getKeys, nowFn, layerIn, layerOut) {
  const cur = evalAt(nowFn());
  const boxed = Array.isArray(cur) ? cur.slice() : new Number(+cur || 0);
  const velAt = (t) => {
    const at = t === undefined ? nowFn() : t;
    const dt = 0.001;
    return scaleVec(subVec(evalAt(at + dt), evalAt(at - dt)), 0.5 / dt);
  };
  const keys = () => (getKeys ? getKeys() : []);
  Object.defineProperties(boxed, {
    value: { get() { return cur; }, enumerable: false },
    velocity: { get() { return velAt(nowFn()); }, enumerable: false },
    speed: { get() { return vecLen(velAt(nowFn())); }, enumerable: false },
    numKeys: { get() { return keys().length; }, enumerable: false },
    valueAtTime: { value(t) { return evalAt(t); }, enumerable: false },
    velocityAtTime: { value(t) { return velAt(t); }, enumerable: false },
    speedAtTime: { value(t) { return vecLen(velAt(t)); }, enumerable: false },
    key: {
      value(ind) {
        const ks = keys();
        const i = (ind | 0) - 1;
        if (i < 0 || i >= ks.length) {
          throw new Error('The property has no keyframe at index ' + ind);
        }
        const kt = ks[i];
        const kv = evalAt(kt);
        const out = { index: i + 1, time: kt, value: kv };
        if (Array.isArray(kv)) {
          for (let j = 0; j < kv.length; j++) out[j] = kv[j];
        } else {
          out[0] = kv;
        }
        return out;
      },
      enumerable: false,
    },
    nearestKey: {
      value(t) {
        const ks = keys();
        if (!ks.length) return { index: 0, time: 0 };
        let best = 0;
        let bestDist = Math.abs(t - ks[0]);
        for (let i = 1; i < ks.length; i++) {
          const d = Math.abs(t - ks[i]);
          if (d < bestDist) { bestDist = d; best = i; }
        }
        return { index: best + 1, time: ks[best] };
      },
      enumerable: false,
    },
    loopOut: {
      value(type, num, flag) {
        return evalLoop('out', type, num, !!flag, nowFn(), evalAt, keys(), layerIn, layerOut);
      },
      enumerable: false,
    },
    loopIn: {
      value(type, num, flag) {
        return evalLoop('in', type, num, !!flag, nowFn(), evalAt, keys(), layerIn, layerOut);
      },
      enumerable: false,
    },
    loopOutDuration: {
      value(type, dur) {
        return evalLoop('out', type, dur, true, nowFn(), evalAt, keys(), layerIn, layerOut);
      },
      enumerable: false,
    },
    loopInDuration: {
      value(type, dur) {
        return evalLoop('in', type, dur, true, nowFn(), evalAt, keys(), layerIn, layerOut);
      },
      enumerable: false,
    },
    smooth: {
      value(width, samples) {
        const w = (width || 0.2) * 0.5;
        const s = Math.max(1, Math.floor(samples || 5));
        if (s <= 1) return evalAt(nowFn());
        const center = nowFn();
        let acc = evalAt(center - w);
        for (let i = 1; i < s; i++) {
          acc = addVec(acc, evalAt(center - w + (2 * w * i) / (s - 1)));
        }
        return scaleVec(acc, 1 / s);
      },
      enumerable: false,
    },
  });
  return boxed;
}

function makeComp(spec, layers) {
  spec = spec || {};
  const layerList = layers || spec.layers || [];
  const fps = spec.frameRate || spec.fps || hostFps();
  const k = hostK();
  const comp = {
    name: spec.name || 'Comp',
    width: spec.width || k.wide || 1920,
    height: spec.height || k.high || 1080,
    duration: spec.duration !== undefined ? spec.duration : k.round || 10,
    px: spec.px || k.px || 1,
    displayStartTime: 0,
    renderedFrame: 0,
    pixelRatio: 1,
    layers: layerList,
    find: typeof spec.find === 'function' ? spec.find : null,
    hierarchy: [],
    frameDuration: 1 / fps,
    numLayers:
      spec.numLayers !== undefined
        ? spec.numLayers
        : layerList.length || (globalThis.layers ? globalThis.layers().length : 0),
  };
  comp.globalData = {
    frameRate: fps,
    frameId: 0,
    renderConfig: { runExpressions: true },
    projectInterface() { return null; },
    pushExpression() {},
    popExpression() {},
    registerExpressionProperty() {},
  };
  return comp;
}

function mergeKeyTimes(id, props) {
  if (!globalThis.layerKeys) return [];
  const set = new Set();
  for (let i = 0; i < props.length; i++) {
    const ks = globalThis.layerKeys(id, props[i]);
    for (let j = 0; j < ks.length; j++) set.add(ks[j]);
  }
  return Array.from(set).sort((a, b) => a - b);
}

// Builds a live AE layer object backed directly by Motolii's host reads.
function makeHostLayer(id, comp, nowSeconds, copyIdx, knobs, customEffect, depth) {
  const lv = (prop, t, fb, c) => {
    if (!globalThis.layerValue) return fb;
    const v = globalThis.layerValue(id, prop, t, fb, c === undefined ? -1 : c);
    return Number.isNaN(v) ? fb : v;
  };
  const lw = (prop) => (globalThis.layerWord ? globalThis.layerWord(id, prop) : '');
  const W = () => comp.width || hostK().wide || 1920;
  const H = () => comp.height || hostK().high || 1080;
  const px = () => comp.px || hostK().px || 1;
  const inPt = lv('start', 0, 0);
  const rawDur = lv('duration', 0, -1);
  const outPt = rawDur >= 0 ? inPt + rawDur : comp.duration || 10;

  const evalPosition = (t) => {
    const p = px();
    return [
      W() * 0.5 + lv('x', t, 0, copyIdx) / p,
      H() * 0.5 - lv('y', t, 0, copyIdx) / p,
      lv('z', t, 0, copyIdx) / p,
    ];
  };
  const evalAnchor = (t) => {
    const b = globalThis.layerBounds ? globalThis.layerBounds(id, t) : null;
    const p = px();
    const hx = b && !Number.isNaN(b.halfX) ? b.halfX : 0;
    const hy = b && !Number.isNaN(b.halfY) ? b.halfY : 0;
    return [lv('anchor_x', t, 0) * hx / p, -lv('anchor_y', t, 0) * hy / p, 0];
  };
  const evalScale = (t) => {
    const sz = lv('size', t, 1);
    return [
      100 * lv('scale_x', t, 1) * sz,
      100 * lv('scale_y', t, 1) * sz,
      100 * lv('scale_z', t, 1) * sz,
    ];
  };
  const evalRotation = (t) => -lv('rotate', t, 0);
  const evalXRot = (t) => lv('rotate_x', t, 0);
  const evalYRot = (t) => lv('rotate_y', t, 0);
  const evalOpacity = (t) => 100 * lv('opacity', t, 1);

  const propSpec = {
    position: [evalPosition, () => mergeKeyTimes(id, ['x', 'y', 'z'])],
    anchorPoint: [evalAnchor, () => mergeKeyTimes(id, ['anchor_x', 'anchor_y'])],
    scale: [evalScale, () => mergeKeyTimes(id, ['scale_x', 'scale_y', 'scale_z', 'size'])],
    rotation: [evalRotation, () => mergeKeyTimes(id, ['rotate'])],
    zRotation: [evalRotation, () => mergeKeyTimes(id, ['rotate'])],
    xRotation: [evalXRot, () => mergeKeyTimes(id, ['rotate_x'])],
    yRotation: [evalYRot, () => mergeKeyTimes(id, ['rotate_y'])],
    opacity: [evalOpacity, () => mergeKeyTimes(id, ['opacity'])],
  };

  const propOf = (name) => {
    const s = propSpec[name];
    return makeLiveProp(s[0], s[1], nowSeconds, inPt, outPt);
  };

  const transform = {};
  for (const name of Object.keys(propSpec)) {
    Object.defineProperty(transform, name, {
      get() { return propOf(name); },
      enumerable: true,
    });
  }

  const effectFn = function (fxName) {
    const key = snakeName(fxName);
    return function (paramName) {
      if (typeof customEffect === 'function') {
        const inner = customEffect(fxName);
        if (typeof inner === 'function') {
          const cv = inner(paramName);
          if (cv !== undefined && cv !== null) return cv;
        }
      }
      if (knobs && knobs[key] !== undefined && knobs[key] !== null) {
        return makeLiveProp(() => knobs[key], null, nowSeconds, inPt, outPt);
      }
      const pName = paramName === undefined ? 'Slider' : String(paramName);
      const evalFx = (t) => {
        if (!globalThis.layerEffect) return 0;
        const v = globalThis.layerEffect(id, String(fxName), pName, t);
        return Number.isNaN(v) ? 0 : v;
      };
      return makeLiveProp(evalFx, null, nowSeconds, inPt, outPt);
    };
  };

  const layerObj = {
    id,
    get name() { return lw('name') || ('Layer ' + id); },
    get index() {
      const all = globalThis.layers ? globalThis.layers() : [];
      const pos = all.indexOf(id);
      return pos >= 0 ? pos + 1 : id;
    },
    inPoint: inPt,
    outPoint: outPt,
    get active() {
      const t = nowSeconds();
      return t >= inPt && t < outPt;
    },
    get width() {
      const b = globalThis.layerBounds ? globalThis.layerBounds(id, nowSeconds()) : null;
      return b ? b.width : W();
    },
    get height() {
      const b = globalThis.layerBounds ? globalThis.layerBounds(id, nowSeconds()) : null;
      return b ? b.height : H();
    },
    get hasParent() { return (lv('parent', 0, 0) | 0) > 0; },
    get parent() {
      if ((depth || 0) >= 8) return null;
      const pid = lv('parent', 0, 0) | 0;
      return pid > 0
        ? makeHostLayer(pid, comp, nowSeconds, -1, null, null, (depth || 0) + 1)
        : null;
    },
    transform,
    effect: effectFn,
    text: {
      get sourceText() { return lw('text'); },
    },
    sourceRectAtTime(t) {
      const at = t === undefined ? nowSeconds() : t;
      const b = globalThis.layerBounds ? globalThis.layerBounds(id, at) : null;
      if (!b) return { left: 0, top: 0, width: W(), height: H() };
      return { left: -b.width * 0.5, top: -b.height * 0.5, width: b.width, height: b.height };
    },
    sampleImage(point, radius, postEffect, t) {
      if (!globalThis.sampleImage) return [0, 0, 0, 0];
      return globalThis.sampleImage(
        id,
        point,
        radius === undefined ? [0.5, 0.5] : radius,
        postEffect === undefined ? true : postEffect,
        t === undefined ? nowSeconds() : t
      );
    },
    toWorld(vec, t) {
      const v = Array.isArray(vec) ? [vec[0] || 0, vec[1] || 0, vec[2] || 0] : vec;
      return globalThis.toWorld ? globalThis.toWorld(id, v, t === undefined ? nowSeconds() : t) : v;
    },
    fromWorld(vec, t) {
      const v = Array.isArray(vec) ? [vec[0] || 0, vec[1] || 0, vec[2] || 0] : vec;
      return globalThis.fromWorld ? globalThis.fromWorld(id, v, t === undefined ? nowSeconds() : t) : v;
    },
    _propSpec: propSpec,
  };
  layerObj.toComp = layerObj.toWorld;
  layerObj.fromComp = layerObj.fromWorld;
  // AE allows both layer.transform.position and layer.position.
  for (const name of Object.keys(propSpec)) {
    Object.defineProperty(layerObj, name, {
      get() { return propOf(name); },
      enumerable: true,
    });
  }
  return layerObj;
}

// Wraps a recipe-supplied layer object so AE defaults apply and function-valued
// position/rotation/scale/opacity also expose .transform & .valueAtTime.
function wrapRecipeLayer(layer, nowSeconds) {
  if (!layer || typeof layer !== 'object') return layer;
  const wrapped = Object.create(layer);
  if (typeof layer.sampleImage === 'function') {
    wrapped.sampleImage = function (point, radius, postEffect, t) {
      return layer.sampleImage(
        point,
        radius === undefined ? [0.5, 0.5] : radius,
        postEffect === undefined ? true : postEffect,
        t === undefined ? nowSeconds() : t
      );
    };
  }
  const fw = layer.fromWorld || layer.fromComp;
  const tw = layer.toWorld || layer.toComp;
  if (typeof fw === 'function') {
    const call = function (vec, t) {
      const v = Array.isArray(vec) ? [vec[0] || 0, vec[1] || 0, vec[2] || 0] : vec;
      return fw(v, t === undefined ? nowSeconds() : t);
    };
    wrapped.fromWorld = call;
    wrapped.fromComp = call;
  }
  if (typeof tw === 'function') {
    const call = function (vec, t) {
      const v = Array.isArray(vec) ? [vec[0] || 0, vec[1] || 0, vec[2] || 0] : vec;
      return tw(v, t === undefined ? nowSeconds() : t);
    };
    wrapped.toWorld = call;
    wrapped.toComp = call;
  }
  if (!layer.transform) {
    const tObj = {};
    let any = false;
    for (const k of ['position', 'anchorPoint', 'scale', 'rotation', 'opacity']) {
      if (typeof layer[k] === 'function') {
        any = true;
        const fn = layer[k];
        const ks = layer.keys && Array.isArray(layer.keys[k]) ? () => layer.keys[k] : null;
        Object.defineProperty(tObj, k, {
          get() { return makeLiveProp(fn, ks, nowSeconds, 0, 10); },
          enumerable: true,
        });
      }
    }
    if (any) wrapped.transform = tObj;
  }
  return wrapped;
}

function makeCompInterface(comp) {
  function nowSeconds() {
    return comp.renderedFrame / (comp.globalData.frameRate || DEFAULT_FPS);
  }
  return {
    layer(nameOrIndex) {
      // 1. Explicit layers passed to AE.comp(spec, [layers]).
      if (comp.layers && comp.layers.length) {
        if (typeof nameOrIndex === 'string') {
          const hit = comp.layers.find((l) => l && l.name === nameOrIndex);
          if (hit) return wrapRecipeLayer(hit, nowSeconds);
        } else if (typeof nameOrIndex === 'number') {
          const hit = comp.layers[(nameOrIndex | 0) - 1];
          if (hit) return wrapRecipeLayer(hit, nowSeconds);
        }
      }
      // 2. Custom finder passed to AE.comp({ find }).
      if (typeof comp.find === 'function') {
        const hit = comp.find(nameOrIndex);
        if (hit) return wrapRecipeLayer(hit, nowSeconds);
      }
      // 3. Automatic live Motolii host lookup.
      let id = 0;
      if (typeof nameOrIndex === 'string' && globalThis.layerNamed) {
        id = globalThis.layerNamed(nameOrIndex);
      } else if (typeof nameOrIndex === 'number' && globalThis.layers) {
        const all = globalThis.layers();
        const idx = (nameOrIndex | 0) - 1;
        if (idx >= 0 && idx < all.length) id = all[idx];
      }
      if (id > 0) return makeHostLayer(id, comp, nowSeconds, -1, null, null, 0);
      return null;
    },
    get width() { return comp.width; },
    get height() { return comp.height; },
    get duration() { return comp.duration; },
    get frameDuration() { return 1 / (comp.globalData.frameRate || DEFAULT_FPS); },
    get numLayers() {
      if (comp.numLayers > 0) return comp.numLayers;
      return globalThis.layers ? globalThis.layers().length : comp.layers.length;
    },
    displayStartTime: comp.displayStartTime,
    pixelAspect: 1,
    compName: comp.name,
  };
}

function makeElem(comp, spec, knobs, state) {
  spec = spec || {};
  const fps = comp.globalData.frameRate || DEFAULT_FPS;
  const noVal = { v: [0, 0, 0], pv: [0, 0, 0], getValueAtTime() { return this.v; } };
  const scaleVal = { v: [100, 100], pv: [100, 100], getValueAtTime() { return this.v; } };
  const scalar0 = { v: 0, pv: 0, getValueAtTime() { return this.v; } };
  const opacVal = { v: 100, pv: 100, getValueAtTime() { return this.v; } };
  const mProp = {
    a: noVal, p: noVal, s: scaleVal, r: scalar0, o: opacVal,
    sk: scalar0, sa: scalar0,
    getValueAtTime() { return mProp; },
    applyToMatrix(mat) { return mat; },
  };
  const nowSeconds = () => comp.renderedFrame / (comp.globalData.frameRate || DEFAULT_FPS);
  return {
    data: {
      ty: spec.ty !== undefined ? spec.ty : 4,
      nm: spec.name || 'Layer',
      ind: spec.index || 1,
      ip: (spec.inPoint !== undefined ? spec.inPoint : 0) * fps,
      op: (spec.outPoint !== undefined ? spec.outPoint : comp.duration || 10) * fps,
      sw: spec.width || comp.width,
      sh: spec.height || comp.height,
      sr: 1,
      ks: {},
      hd: false,
    },
    comp,
    globalData: comp.globalData,
    finalTransform: { mProp },
    hierarchy: [],
    sourceRectAtTime(t) {
      if (state.hostLayer) return state.hostLayer.sourceRectAtTime(t);
      return { top: 0, left: 0, width: comp.width, height: comp.height };
    },
    getLayerSize() {
      return { w: spec.width || comp.width, h: spec.height || comp.height };
    },
    effect(name) {
      const key = snakeName(name);
      return function (paramName) {
        if (typeof state.customEffect === 'function') {
          const inner = state.customEffect(name);
          if (typeof inner === 'function') {
            const cv = inner(paramName);
            if (cv !== undefined && cv !== null) return cv;
          }
        }
        if (knobs && knobs[key] !== undefined && knobs[key] !== null) {
          return knobs[key];
        }
        if (state.hostLayer && paramName !== undefined) {
          return state.hostLayer.effect(name)(paramName);
        }
        return 0;
      };
    },
    maskManager: { getMaskProperty() { return { v: 0 }; } },
  };
}

function makeProperty(comp, elem, initial, propSpecEntry, layerIn, layerOut) {
  const v = Array.isArray(initial) ? initial.slice() : initial;
  const nowSeconds = () => comp.renderedFrame / (comp.globalData.frameRate || DEFAULT_FPS);
  const evalAt = propSpecEntry ? propSpecEntry[0] : () => prop.pv;
  const getKeys = propSpecEntry ? propSpecEntry[1] : () => [];
  const prop = {
    v,
    pv: v,
    _mdf: false,
    kf: false,
    k: false,
    keyframes: [],
    comp,
    elem,
    container: elem,
    propType: Array.isArray(v) ? 'multidimensional' : 'unidimensional',
    getValueAtTime(t) { return evalAt(t); },
    getVelocityAtTime(t) {
      const at = t === undefined ? nowSeconds() : t;
      const dt = 0.001;
      return scaleVec(subVec(evalAt(at + dt), evalAt(at - dt)), 0.5 / dt);
    },
    loopOut(type, num, flag) {
      return evalLoop('out', type, num, !!flag, nowSeconds(), evalAt, getKeys(), layerIn, layerOut);
    },
    loopIn(type, num, flag) {
      return evalLoop('in', type, num, !!flag, nowSeconds(), evalAt, getKeys(), layerIn, layerOut);
    },
    smooth(width, samples) {
      const w = (width || 0.2) * 0.5;
      const s = Math.max(1, Math.floor(samples || 5));
      if (s <= 1) return evalAt(nowSeconds());
      const center = nowSeconds();
      let acc = evalAt(center - w);
      for (let i = 1; i < s; i++) {
        acc = addVec(acc, evalAt(center - w + (2 * w * i) / (s - 1)));
      }
      return scaleVec(acc, 1 / s);
    },
  };
  return prop;
}

function compile(src) {
  let processed = String(src).trim();
  while (processed.endsWith(';')) processed = processed.slice(0, -1).trim();
  if (!/\$bm_rt\s*=/.test(processed)) {
    processed = 'var $bm_rt; $bm_rt = (' + processed + ')';
  }
  let bound = null;
  const bind = (ctx) => {
    const fps = hostFps(ctx);
    const comp = (ctx && ctx.comp) || makeComp(Object.assign({ frameRate: fps }, ctx && ctx.compSpec));
    comp.globalData.frameRate = fps;
    comp.frameDuration = 1 / fps;
    if (ctx && ctx.k && typeof ctx.k.px === 'number') comp.px = ctx.k.px;
    if (ctx && ctx.k && typeof ctx.k.wide === 'number') comp.width = ctx.k.wide;
    if (ctx && ctx.k && typeof ctx.k.high === 'number') comp.height = ctx.k.high;
    if (ctx && ctx.k && typeof ctx.k.round === 'number') comp.duration = ctx.k.round;

    const knobs = {};
    if (ctx && ctx.k && typeof ctx.k === 'object') {
      for (const key in ctx.k) knobs[key] = ctx.k[key];
    }
    const nowSeconds = () => comp.renderedFrame / (comp.globalData.frameRate || DEFAULT_FPS);
    const selfId =
      ctx && typeof ctx.id === 'number'
        ? ctx.id
        : ctx && ctx.k && typeof ctx.k.id === 'number'
        ? ctx.k.id
        : typeof hostK().id === 'number'
        ? hostK().id
        : 0;
    const copyIdx = ctx && typeof ctx.copy === 'number' ? ctx.copy : -1;
    const state = {
      customEffect: ctx && typeof ctx.effect === 'function' ? ctx.effect : null,
      hostLayer: null,
    };
    if (selfId > 0 && globalThis.layerValue) {
      state.hostLayer = makeHostLayer(selfId, comp, nowSeconds, copyIdx, knobs, state.customEffect, 0);
    }

    const layerSpec = Object.assign(
      state.hostLayer
        ? {
            name: state.hostLayer.name,
            index: state.hostLayer.index,
            inPoint: state.hostLayer.inPoint,
            outPoint: state.hostLayer.outPoint,
            width: state.hostLayer.width,
            height: state.hostLayer.height,
          }
        : {},
      (ctx && ctx.layer) || {}
    );
    const elem = makeElem(comp, layerSpec, knobs, state);
    const value = ctx && ctx.value !== undefined ? ctx.value : 0;
    const propName = (ctx && ctx.propertyName) || '';
    const propEntry =
      state.hostLayer && propName && state.hostLayer._propSpec[propName]
        ? state.hostLayer._propSpec[propName]
        : null;
    const property = makeProperty(
      comp,
      elem,
      value,
      propEntry,
      layerSpec.inPoint || 0,
      layerSpec.outPoint || comp.duration || 10
    );

    // Populate lottie's data.k so key(n), nearestKey(t) and numKeys reflect
    // real project keyframes on the bound property.
    const data = { x: processed, k: 0 };
    if (propEntry) {
      const ks = propEntry[1]();
      if (ks.length) {
        const lottieKeys = ks.map((kt) => {
          const kv = propEntry[0](kt);
          return { t: kt * fps, s: Array.isArray(kv) ? kv : [kv] };
        });
        data.k = lottieKeys;
        property.keyframes = lottieKeys;
        property.kf = true;
        property.k = true;
      }
    }

    comp.compInterface = makeCompInterface(comp);
    const thisLayer = function (name) {
      if (name === 4 || name === 'ADBE Effect Parade') return elem.effect;
      if (name === 'ADBE Transform Group') {
        return state.hostLayer ? state.hostLayer.transform : null;
      }
      if (name === 'ADBE Text Properties') return thisLayer.text;
      if (name === 'ADBE Root Vectors Group') return thisLayer.shapeInterface;
      if (state.hostLayer && name in state.hostLayer) return state.hostLayer[name];
      return null;
    };
    thisLayer.text = state.hostLayer ? state.hostLayer.text : {};
    thisLayer.shapeInterface = {};
    thisLayer.transform = state.hostLayer ? state.hostLayer.transform : {};
    thisLayer.toWorld = (p, t) => (state.hostLayer ? state.hostLayer.toWorld(p, t) : p);
    thisLayer.fromWorld = (p, t) => (state.hostLayer ? state.hostLayer.fromWorld(p, t) : p);
    thisLayer.toComp = thisLayer.toWorld;
    thisLayer.fromComp = thisLayer.fromWorld;
    thisLayer.sampleImage = (p, r, post, t) =>
      state.hostLayer ? state.hostLayer.sampleImage(p, r, post, t) : [0, 0, 0, 0];
    thisLayer.sourceRectAtTime = (t) => elem.sourceRectAtTime(t);
    thisLayer.mask = null;
    thisLayer.effect = elem.effect;
    thisLayer._elem = elem;
    Object.defineProperties(thisLayer, {
      name: { get() { return state.hostLayer ? state.hostLayer.name : elem.data.nm; } },
      index: { get() { return elem.data.ind; } },
      inPoint: { get() { return elem.data.ip / (comp.globalData.frameRate || DEFAULT_FPS); } },
      outPoint: { get() { return elem.data.op / (comp.globalData.frameRate || DEFAULT_FPS); } },
      width: { get() { return state.hostLayer ? state.hostLayer.width : elem.data.sw; } },
      height: { get() { return state.hostLayer ? state.hostLayer.height : elem.data.sh; } },
      hasParent: { get() { return state.hostLayer ? state.hostLayer.hasParent : false; } },
      parent: { get() { return state.hostLayer ? state.hostLayer.parent : null; } },
      active: { get() { return state.hostLayer ? state.hostLayer.active : true; } },
    });
    if (state.hostLayer && state.hostLayer.hasParent) {
      elem.hierarchy = [{ layerInterface: state.hostLayer.parent }];
    }
    elem.layerInterface = thisLayer;

    const exec = ExpressionManager.initiateExpression.call(
      property,
      elem,
      data,
      property
    );
    return { comp, elem, property, exec, knobs, state, propName, selfId };
  };

  return function run(ctx) {
    const wantProp = (ctx && ctx.propertyName) || '';
    const wantId =
      ctx && typeof ctx.id === 'number'
        ? ctx.id
        : ctx && ctx.k && typeof ctx.k.id === 'number'
        ? ctx.k.id
        : typeof hostK().id === 'number'
        ? hostK().id
        : 0;
    if (!bound || bound.propName !== wantProp || bound.selfId !== wantId) {
      bound = bind(ctx);
    }
    if (ctx) {
      const fps = hostFps(ctx);
      bound.comp.globalData.frameRate = fps;
      bound.comp.frameDuration = 1 / fps;
      if (typeof ctx.effect === 'function') bound.state.customEffect = ctx.effect;
      if (ctx.time !== undefined) {
        bound.comp.renderedFrame = ctx.time * fps;
      }
      if (ctx.value !== undefined) {
        bound.property.v = bound.property.pv = ctx.value;
      }
      if (ctx.index !== undefined) bound.elem.data.ind = ctx.index;
      if (ctx.count !== undefined) bound.comp.numLayers = ctx.count;
      if (ctx.k && typeof ctx.k === 'object') {
        for (const key in ctx.k) bound.knobs[key] = ctx.k[key];
        if (typeof ctx.k.px === 'number') bound.comp.px = ctx.k.px;
        if (typeof ctx.k.wide === 'number') bound.comp.width = ctx.k.wide;
        if (typeof ctx.k.high === 'number') bound.comp.height = ctx.k.high;
      }
      bound.comp.globalData.frameId = (bound.comp.globalData.frameId | 0) + 1;
    }
    ExpressionManager.resetFrame();
    return unwrapAe(bound.exec.call(bound.property, bound.property.pv));
  };
}

globalThis.AE = {
  compile,
  run(f, ctx) { return f(ctx); },
  comp: makeComp,
  layer(spec) { return spec; },
  name(s) { return String(s).replace(/\W+/g, '_'); },
};

globalThis.__LottieExpressions = Expressions;

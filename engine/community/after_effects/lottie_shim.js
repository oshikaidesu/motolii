// Motolii side of the lottie-web expression runtime: it bridges the
// AE.compile / AE.run surface that shelves/create scripts and ae_expr.h use
// to lottie-web's ExpressionManager (engine/third_party/js/lottie/expressions/).
//
// AGENTS.md 原則 2：同じ動きを自前で書かない。AE expression の解釈は
// lottie-web (ExpressionManager.js) に全部任せる。この shim は engine 側の
// 呼び方 (AE.compile(src), AE.run(f, ctx), AE.comp(...), AE.layer(...)) を
// lottie の initiateExpression(elem, data, property) へ写すだけの小さな板。
//
// Loaded as an ES module by community/script_runner/script_runner.cpp after it
// installs a module loader that resolves 'motolii-lottie/*' to the vendored
// files under engine/third_party/js/lottie/*. Keep this file free of DOM and
// of motolii-specific state; it only sets `globalThis.AE`.

import Expressions from 'motolii-lottie/utils/expressions/Expressions.js';
import ExpressionManager from 'motolii-lottie/utils/expressions/ExpressionManager.js';
import LayerExpressionInterface from 'motolii-lottie/utils/expressions/LayerInterface.js';
import CompExpressionInterface from 'motolii-lottie/utils/expressions/CompInterface.js';

// lottie-web reads a handful of DOM globals at module load time. motolii has
// no DOM, so stub them to the smallest values that keep lottie's internal
// browser checks (e.g. the Safari regex in utils/common.js) from throwing.
if (typeof globalThis.navigator === 'undefined') {
  globalThis.navigator = { userAgent: '' };
}
if (typeof globalThis.window === 'undefined') globalThis.window = null;
if (typeof globalThis.document === 'undefined') globalThis.document = null;

const FPS = 60; // motolii's fixed frame rate (WorkspaceController.fps)

function makeComp(spec, layers) {
  spec = spec || {};
  const layerList = layers || spec.layers || [];
  const comp = {
    name: spec.name || 'Comp',
    width: spec.width || 1920,
    height: spec.height || 1080,
    displayStartTime: 0,
    renderedFrame: 0,
    pixelRatio: 1,
    layers: layerList,
    hierarchy: [],
    frameDuration: 1 / FPS,
    numLayers: spec.numLayers !== undefined ? spec.numLayers : layerList.length,
  };
  comp.globalData = {
    frameRate: FPS,
    frameId: 0,
    renderConfig: { runExpressions: true },
    projectInterface() { return null; },
    pushExpression() {},
    popExpression() {},
    registerExpressionProperty() {},
  };
  return comp;
}

// Motolii-style compInterface: callable (thisComp("Video")) and also exposes
// layer(nameOrIndex), width/height/numLayers. Returns the raw layer object
// the recipe passed in (so thisComp.layer("Video").sampleImage calls the
// recipe-supplied sampleImage directly, matching ae_prelude's behaviour).
function makeCompInterface(comp) {
  // AE-spec defaults for the handful of layer calls expressions use. When an
  // expression omits an argument, AE fills it in (sampleImage radius = half a
  // pixel, postEffect = true, t = current time; fromWorld adds a z = 0 and
  // defaults t to current time). lottie doesn't do this — the raw layer
  // object a recipe passed to AE.comp sees undefineds otherwise.
  function nowSeconds() {
    return comp.renderedFrame / (comp.globalData.frameRate || 60);
  }
  function wrapLayer(layer) {
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
    // In AE, world == comp for a 2D layer. If the layer only has one of the
    // pair, use it for both (matches ae_prelude's `L.fromComp = L.fromWorld`).
    const fw = layer.fromWorld || layer.fromComp;
    const tw = layer.toWorld || layer.toComp;
    if (typeof fw === 'function') {
      const call = function (vec, t) {
        const v = Array.isArray(vec)
          ? [vec[0] || 0, vec[1] || 0, vec[2] || 0]
          : vec;
        return fw(v, t === undefined ? nowSeconds() : t);
      };
      wrapped.fromWorld = call;
      wrapped.fromComp = call;
    }
    if (typeof tw === 'function') {
      const call = function (vec, t) {
        const v = Array.isArray(vec)
          ? [vec[0] || 0, vec[1] || 0, vec[2] || 0]
          : vec;
        return tw(v, t === undefined ? nowSeconds() : t);
      };
      wrapped.toWorld = call;
      wrapped.toComp = call;
    }
    return wrapped;
  }
  const api = {
    layer(nameOrIndex) {
      if (typeof nameOrIndex === 'string') {
        return wrapLayer(
          comp.layers.find((l) => l && l.name === nameOrIndex) || null
        );
      }
      if (typeof nameOrIndex === 'number') {
        return wrapLayer(comp.layers[nameOrIndex - 1] || null);
      }
      return null;
    },
    width: comp.width,
    height: comp.height,
    numLayers: comp.numLayers,
    displayStartTime: comp.displayStartTime,
    pixelAspect: 1,
    compName: comp.name,
  };
  return api;
}

// Matches script_parameters.cpp's snake_name: the key an AE effect's name is
// stored under in the knobs object the script's each(i, n, t, k) receives.
function snakeName(s) {
  return String(s)
    .split('')
    .map((c) => (/\w/.test(c) ? c.toLowerCase() : '_'))
    .join('');
}

function makeElem(comp, spec, knobs) {
  spec = spec || {};
  const noVal = { v: [0, 0, 0], pv: [0, 0, 0], getValueAtTime() { return this.v; } };
  const scaleVal = { v: [100, 100], pv: [100, 100], getValueAtTime() { return this.v; } };
  const scalar0 = { v: 0, pv: 0, getValueAtTime() { return this.v; } };
  const opacVal = { v: 100, pv: 100, getValueAtTime() { return this.v; } };
  const mProp = {
    a: noVal, p: noVal, s: scaleVal, r: scalar0, o: opacVal,
    sk: scalar0, sa: scalar0,
    getValueAtTime(t) { return mProp; },
    applyToMatrix(mat) { return mat; },
  };
  return {
    data: {
      ty: spec.ty !== undefined ? spec.ty : 4,
      nm: spec.name || 'Layer',
      ind: spec.index || 1,
      ip: spec.inPoint !== undefined ? spec.inPoint : 0,
      op: spec.outPoint !== undefined ? spec.outPoint : FPS * 10,
      sw: spec.width || comp.width,
      sh: spec.height || comp.height,
      sr: 1,
      ks: {},
      hd: false,
    },
    comp,
    globalData: comp.globalData,
    finalTransform: { mProp: mProp },
    hierarchy: [],
    sourceRectAtTime() {
      return { top: 0, left: 0, width: comp.width, height: comp.height };
    },
    getLayerSize() {
      return { w: spec.width || comp.width, h: spec.height || comp.height };
    },
    // AE's effect("Name Control")("Slider") reads the value the user set
    // on the layer's card. On motolii the card's values arrive as `k` in
    // each(i, n, t, k) and the shim's bind captured them in `knobs`.
    // script_parameters.cpp emits one track per unique effect name, keyed by
    // snake_name(name). When no slider has been set, the AE Slider default
    // (0) is used.
    effect(name) {
      const key = snakeName(name);
      // Returns a plain number so `effect("Freq")("Slider") * 10` is numeric,
      // matching AE's behaviour (a Slider control is a scalar). Lottie's own
      // EffectInterface would return a PropertyInterface, but motolii's
      // recipes multiply / add the value directly — see ae_prelude.js's old
      // L.effect for the same contract.
      return function () {
        return knobs && knobs[key] !== undefined && knobs[key] !== null
          ? knobs[key]
          : 0;
      };
    },
    maskManager: { getMaskProperty() { return { v: 0 }; } },
  };
}

function makeProperty(comp, elem, initial) {
  const v = Array.isArray(initial) ? initial.slice() : initial;
  return {
    v: v,
    pv: v,
    _mdf: false,
    kf: false,
    keyframes: [],
    comp,
    elem,
    container: elem,
    propType: 'unidimensional',
    getValueAtTime() { return v; },
    getVelocityAtTime() { return Array.isArray(v) ? v.map(() => 0) : 0; },
  };
}

// Compiles `src` as an AE expression and returns a runner. The first call to
// the runner binds the context (comp/layer/value) the expression sees; later
// calls reuse that binding and just update time / value / index.
function compile(src) {
    // lottie-web expects expression source to have been rewritten by the
    // bodymovin After Effects plugin to assign its final value to `$bm_rt`.
    // When a recipe passes a raw AE expression like `ease(time, 0, 1, 0, 1)`
    // we wrap it so the eval'd function's result lands in scoped_bm_rt.
    // Expressions that already contain `$bm_rt = …` are left alone.
    let processed = String(src).trim();
    while (processed.endsWith(';')) processed = processed.slice(0, -1).trim();
    if (!/\$bm_rt\s*=/.test(processed)) {
      // `$bm_rt` must be declared (strict mode in the eval'd function).
      processed = 'var $bm_rt; $bm_rt = (' + processed + ')';
    }
    const data = { x: processed, k: 0 };
  // The knobs object lives at bound.knobs. Each run updates it in place so
  // the closure effect() built in makeElem sees fresh values.
  let bound = null;
  const bind = (ctx) => {
    const comp = (ctx && ctx.comp) || makeComp(ctx && ctx.compSpec);
    const knobs = {};
    const elem = makeElem(comp, (ctx && ctx.layer) || {}, knobs);
    const value = ctx && ctx.value !== undefined ? ctx.value : 0;
    const property = makeProperty(comp, elem, value);
    // lottie's executeExpression reads elem.layerInterface and
    // elem.comp.compInterface. We provide motolii-flavored interfaces that
    // keep recipe-passed layer objects reachable (lottie's own CompInterface
    // wraps each layer in its own structure, breaking AE.comp(spec, [layer])
    // recipes).
    comp.compInterface = makeCompInterface(comp);
    // layerInterface must be a *callable* function — lottie's executeExpression
    // calls `thisLayer(4)` (ExpressionManager.js:718) to grab the effect
    // getter. The factory in LayerInterface.js returns a function with
    // `.shapeInterface / .effect / .textInterface / .toWorld / ...` attached.
    // We build the same shape with just the methods expressions touch.
    const thisLayer = function (name) {
      if (name === 4 || name === 'ADBE Effect Parade') return elem.effect;
      if (name === 'ADBE Text Properties') return thisLayer.text;
      if (name === 'ADBE Root Vectors Group') return thisLayer.shapeInterface;
      // callable property access: thisLayer("Rotation") etc.
      return null;
    };
    thisLayer.text = {};
    thisLayer.shapeInterface = {};
    thisLayer.toWorld = (p) => p;
    thisLayer.fromWorld = (p) => p;
    thisLayer.toComp = (p) => p;
    thisLayer.fromComp = (p) => p;
    thisLayer.mask = null;
    thisLayer.effect = elem.effect;
    thisLayer._elem = elem;
    elem.layerInterface = thisLayer;
    // `this` inside initiateExpression is the property (reads this.data.hd
    // and this.comp). lottie assumes the caller binds it.
    const exec = ExpressionManager.initiateExpression.call(
      property,
      elem,
      data,
      property
    );
    return { comp, elem, property, exec, knobs };
  };
  return function run(ctx) {
    if (!bound) bound = bind(ctx);
    if (ctx) {
      if (ctx.time !== undefined) {
        bound.comp.renderedFrame = ctx.time * FPS;
      }
      if (ctx.value !== undefined) {
        bound.property.v = bound.property.pv = ctx.value;
      }
      if (ctx.index !== undefined) bound.elem.data.ind = ctx.index;
      // Mirror ctx.k (user's slider values) into the knobs object that
      // elem.effect(...) reads from. Values stay between runs so a card
      // slider that stops being updated keeps its last reading.
      if (ctx.k && typeof ctx.k === 'object') {
        for (const key in ctx.k) bound.knobs[key] = ctx.k[key];
      }
      bound.comp.globalData.frameId = (bound.comp.globalData.frameId | 0) + 1;
    }
    ExpressionManager.resetFrame();
    return bound.exec.call(bound.property, bound.property.pv);
  };
}

// The AE.* surface older recipes read. AE.compile wraps `src` into a lottie
// expression that returns `$bm_rt`; AE.run passes the ctx straight through.
globalThis.AE = {
  compile,
  run(f, ctx) { return f(ctx); },
  comp: makeComp,
  layer(spec) { return spec; },
  name(s) { return String(s).replace(/\W+/g, '_'); },
};

// Debugging hook, in case a recipe needs to inspect which implementation
// answers its AE calls.
globalThis.__LottieExpressions = Expressions;

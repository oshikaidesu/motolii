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

// lottie-web reads a handful of DOM globals at module load time. motolii has
// no DOM, so stub them to the smallest values that keep lottie's internal
// browser checks (e.g. the Safari regex in utils/common.js) from throwing.
if (typeof globalThis.navigator === 'undefined') {
  globalThis.navigator = { userAgent: '' };
}
if (typeof globalThis.window === 'undefined') globalThis.window = null;
if (typeof globalThis.document === 'undefined') globalThis.document = null;

const FPS = 60; // motolii's fixed frame rate (WorkspaceController.fps)

function makeComp(spec) {
  spec = spec || {};
  const comp = {
    name: spec.name || 'Comp',
    width: spec.width || 1920,
    height: spec.height || 1080,
    displayStartTime: 0,
    renderedFrame: 0,
    pixelRatio: 1,
    layers: spec.layers || [],
    hierarchy: [],
    frameDuration: 1 / FPS,
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

function makeElem(comp, spec) {
  spec = spec || {};
  return {
    data: {
      ty: spec.ty !== undefined ? spec.ty : 4, // 4 = shape layer
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
    finalTransform: {
      mProp: {
        a: { v: [0, 0, 0] },
        p: { v: [0, 0, 0] },
        s: { v: [100, 100] },
        r: { v: 0 },
        o: { v: 100 },
      },
    },
    hierarchy: [],
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
  const data = { x: String(src), k: 0 };
  let bound = null;
  const bind = (ctx) => {
    const comp = (ctx && ctx.comp) || makeComp(ctx && ctx.compSpec);
    const elem = makeElem(comp, (ctx && ctx.layer) || {});
    const value = ctx && ctx.value !== undefined ? ctx.value : 0;
    const property = makeProperty(comp, elem, value);
    // `this` inside initiateExpression is the property (reads this.data.hd
    // and this.comp). lottie assumes the caller binds it.
    const exec = ExpressionManager.initiateExpression.call(
      property,
      elem,
      data,
      property
    );
    return { comp, elem, property, exec };
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
      bound.comp.globalData.frameId = (bound.comp.globalData.frameId | 0) + 1;
    }
    ExpressionManager.resetFrame();
    return bound.exec.call(bound.property, bound.property.pv);
  };
}

// The surface older recipes read (see engine/third_party/js/ae/ae_prelude.js,
// which this shim is replacing once it is wired in script_runner.cpp).
globalThis.AE = {
  compile,
  run(f, ctx) { return f(ctx); },
  comp: makeComp,
  layer(spec) { return spec; },
  name(s) { return String(s).replace(/\W+/g, '_'); },
};

// expose Expressions for tests that want the raw lottie entry
globalThis.__LottieExpressions = Expressions;

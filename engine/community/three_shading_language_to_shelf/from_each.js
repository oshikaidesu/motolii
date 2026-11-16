// Builds WGSL vertex shader from an each() expression file.
// Called by engine/community/three/tsl_each.cpp when a .js expression is loaded.
// Based on docs/internal/gpu_trace_probe/trace.mjs (the probe that confirmed the approach).
import * as acorn from 'acorn';
import * as THREE from 'three/webgpu';
import * as T from 'three/tsl';

const renderer = new THREE.WebGPURenderer({ canvas: { getContext() { return null }, style: {}, addEventListener() {} } });
renderer._initialized = true;
renderer.backend.hasFeature = () => false;
renderer.backend.device = { limits: { maxUniformBufferBindingSize: 65536, maxStorageBufferBindingSize: 134217728 } };
renderer.backend.utils = new Proxy({}, { get: (_, k) => () => k === "getTextureSampleData" ? { primarySamples: 1 } : undefined });

const plane = new THREE.PlaneGeometry(1, 1);

class Reason extends Error {}
const isNode = v => v !== null && typeof v === "object" && v.isNode === true;
const B = n => (n.__b = true, n), U = n => (n.__u = true, n);
const node = v => {
  if (isNode(v)) return v;
  if (typeof v === "number") return T.float(v);
  if (typeof v === "boolean") return B(T.bool(v));
  throw new Reason(`a ${typeof v} meets a value that changes per copy or frame`);
};
const asFloat = v => isNode(v) ? (v.__u ? T.float(v) : v.__b ? T.select(v, T.float(1), T.float(0)) : v) : node(v);
const asUint = v => isNode(v) ? (v.__u ? v : T.uint(T.int(v))) : T.uint(v >>> 0);
const truth = v => v.__b ? v : asFloat(v).notEqual(0);
const js = {
  "+": (a, b) => a + b, "-": (a, b) => a - b, "*": (a, b) => a * b, "/": (a, b) => a / b, "%": (a, b) => a % b,
  "<": (a, b) => a < b, ">": (a, b) => a > b, "<=": (a, b) => a <= b, ">=": (a, b) => a >= b,
  "==": (a, b) => a == b, "===": (a, b) => a === b, "!=": (a, b) => a != b, "!==": (a, b) => a !== b,
  "&": (a, b) => a & b, "|": (a, b) => a | b, "^": (a, b) => a ^ b,
  "<<": (a, b) => a << b, ">>": (a, b) => a >> b, ">>>": (a, b) => a >>> b,
};
const bits = { "&": "bitAnd", "|": "bitOr", "^": "bitXor", "<<": "shiftLeft", ">>": "shiftRight", ">>>": "shiftRight" };
const cmp = { "<": "lessThan", ">": "greaterThan", "<=": "lessThanEqual", ">=": "greaterThanEqual", "==": "equal", "===": "equal", "!=": "notEqual", "!==": "notEqual" };
const arith = { "+": "add", "-": "sub", "*": "mul", "/": "div", "%": "mod" };
globalThis.$op = (op, a, b) => {
  if (!isNode(a) && !isNode(b)) return js[op](a, b);
  const plain = v => isNode(v) || typeof v === "number" || typeof v === "boolean";
  if (cmp[op] && (!plain(a) || !plain(b))) return js[op](a, b);
  if (bits[op]) return U(asUint(a)[bits[op]](asUint(b)));
  if (cmp[op]) return B(asFloat(a)[cmp[op]](asFloat(b)));
  const intish = v => isNode(v) ? v.__u : Number.isInteger(v);
  if (op !== "/" && op !== "%" && intish(a) && intish(b)) return U(asUint(a)[arith[op]](asUint(b)));
  return asFloat(a)[arith[op]](asFloat(b));
};
globalThis.$un = (op, a) => {
  if (!isNode(a)) return op === "-" ? -a : op === "+" ? +a : op === "!" ? !a : ~a;
  return op === "-" ? asFloat(a).negate() : op === "+" ? a : op === "!" ? B(truth(a).not()) : U(asUint(a).bitNot());
};
const DEFAULT = { x: 0, y: 0, z: 0, rotate: 0, rotate_x: 0, rotate_y: 0, size: 1, opacity: 1, scale_x: 1, scale_y: 1, scale_z: 1 };
const pick = (c, a, b) => {
  if (a !== null && typeof a === "object" && !isNode(a) || b !== null && typeof b === "object" && !isNode(b)) {
    const out = {};
    for (const k of new Set([...Object.keys(a || {}), ...Object.keys(b || {})])) out[k] = pick(c, (a || {})[k] ?? DEFAULT[k] ?? 0, (b || {})[k] ?? DEFAULT[k] ?? 0);
    return out;
  }
  return T.select(c, asFloat(a), asFloat(b));
};
globalThis.$sel = (c, fa, fb) => isNode(c) ? pick(truth(c), fa(), fb()) : c ? fa() : fb();
globalThis.$logic = (op, fa, fb) => {
  const a = fa();
  if (!isNode(a)) return op === "&&" ? (a ? fb() : a) : op === "||" ? (a ? a : fb()) : (a ?? fb());
  if (op === "??") return a;
  const b = fb();
  return op === "&&" ? pick(truth(a), b, a) : pick(truth(a), a, b);
};
globalThis.$test = c => { if (isNode(c)) throw new Reason("an if or a loop on a value that changes per copy or frame"); return c; };
const fold = (f, g) => (...v) => v.some(isNode) ? v.map(asFloat).reduce((a, b) => g(a, b)) : f(...v);
globalThis.$M = new Proxy(Math, {
  get(M, k) {
    const one = { floor: T.floor, ceil: T.ceil, round: T.round, trunc: T.trunc, abs: T.abs, sin: T.sin, cos: T.cos, tan: T.tan, asin: T.asin, acos: T.acos, atan: T.atan, sqrt: T.sqrt, exp: T.exp, log: T.log, sign: T.sign, fround: x => x }[k];
    if (one) return x => isNode(x) ? one(asFloat(x)) : M[k](x);
    if (k === "min") return fold(M.min, T.min);
    if (k === "max") return fold(M.max, T.max);
    if (k === "pow") return (a, b) => isNode(a) || isNode(b) ? T.pow(asFloat(a), asFloat(b)) : M.pow(a, b);
    if (k === "atan2") return (y, x) => isNode(y) || isNode(x) ? T.atan(asFloat(y), asFloat(x)) : M.atan2(y, x);
    if (k === "hypot") return (...v) => v.some(isNode) ? T.sqrt(v.map(asFloat).map(a => a.mul(a)).reduce((a, b) => a.add(b))) : M.hypot(...v);
    if (k === "imul") return (a, b) => isNode(a) || isNode(b) ? U(asUint(a).mul(asUint(b))) : M.imul(a, b);
    if (k === "random") return () => { throw new Reason("Math.random: a new number on every run"); };
    return M[k];
  },
});

const OPS = new Set(Object.keys(js));
function rewrite(src) {
  const ast = acorn.parse(src, { ecmaVersion: 2022, allowReturnOutsideFunction: true });
  const kids = n => {
    const out = [];
    for (const k in n) {
      if (k === "type" || k === "start" || k === "end") continue;
      const v = n[k];
      if (Array.isArray(v)) { for (const x of v) if (x && typeof x.type === "string") out.push(x); }
      else if (v && typeof v.type === "string") out.push(v);
    }
    return out;
  };
  const returns = s =>
    s.type === "ReturnStatement" ||
    s.type === "BlockStatement" && s.body.length > 0 && returns(s.body[s.body.length - 1]) ||
    s.type === "IfStatement" && !!s.alternate && returns(s.consequent) && returns(s.alternate);
  const body = s => s.type === "BlockStatement" ? s.body : [s];
  const block = list => {
    let out = "";
    for (let j = 0; j < list.length; j++) {
      const s = list[j];
      if (s.type === "IfStatement" && returns(s.consequent) && (s.alternate ? returns(s.alternate) : returns(list[list.length - 1]))) {
        const rest = s.alternate ? body(s.alternate) : list.slice(j + 1);
        return out + `return $sel(${emit(s.test)},()=>{${block(body(s.consequent))}},()=>{${block(rest)}});`;
      }
      out += emit(s) + "\n";
    }
    return out;
  };
  const emit = (n, parent) => {
    if (n.type === "Property" && n.shorthand) return `${n.key.name}:${emit(n.value)}`;
    if (n.type === "BinaryExpression" && OPS.has(n.operator)) return `$op(${JSON.stringify(n.operator)},${emit(n.left)},${emit(n.right)})`;
    if (n.type === "LogicalExpression") return `$logic(${JSON.stringify(n.operator)},()=>(${emit(n.left)}),()=>(${emit(n.right)}))`;
    if (n.type === "ConditionalExpression") return `$sel(${emit(n.test)},()=>(${emit(n.consequent)}),()=>(${emit(n.alternate)}))`;
    if (n.type === "UnaryExpression" && "-+!~".includes(n.operator)) return `$un(${JSON.stringify(n.operator)},${emit(n.argument)})`;
    if (n.type === "AssignmentExpression" && n.operator !== "=" && OPS.has(n.operator.slice(0, -1)))
      return `${src.slice(n.left.start, n.left.end)}=$op(${JSON.stringify(n.operator.slice(0, -1))},${emit(n.left)},${emit(n.right)})`;
    if (n.type === "MemberExpression" && n.object.type === "Identifier" && n.object.name === "Math") return "$M" + src.slice(n.object.end, n.end);
    if (n.type === "BlockStatement" && n.body.length && returns(n.body[n.body.length - 1])) return `{${block(n.body)}}`;
    let out = "", pos = n.start;
    for (const k of kids(n).sort((a, b) => a.start - b.start)) {
      const e = emit(k, n);
      out += src.slice(pos, k.start) + (k === n.test && /If|While|For|DoWhile/.test(n.type) ? `$test(${e})` : e);
      pos = k.end;
    }
    return out + src.slice(pos, n.end);
  };
  return emit(ast);
}

// Builds a WGSL vertex shader from an each() expression source.
// cavalryJs: the cavalry_prelude.js text (random, animate, etc.).
// easeJs: the ways_prelude() text (ease by name).
// Returns { wgsl, why } — wgsl is empty when why is set.
export function buildEach(src, cavalryJs, easeJs) {
  try {
    globalThis.each = undefined;
    (0, eval)(rewrite(easeJs));
    (0, eval)(rewrite(cavalryJs));
    // const/let knobs → var knobs so eval can read it from outside the block.
    (0, eval)(rewrite(src.replace(/^(?:const|let)(\s+knobs\b)/m, "var$1")));
    if (typeof globalThis.each !== "function") return { wgsl: "", why: "no each()" };

    const knobs = {};
    for (const m of src.matchAll(/^\/\/\s*--(\w+)@(\w+):([^\n]*)$/gm)) {
      const parts = m[3].split(","), num = parts.slice(1).map(Number);
      const v = m[1] === "track" ? num[2] : m[1] === "check" ? num[0] : m[1] === "select" ? parts[1] : Number.isNaN(num[0]) ? parts[1] : num[0];
      knobs[m[2]] = typeof v === "number" ? T.uniform(v) : v;
    }

    const n = 1000;
    const at = T.instancedArray(n, "vec4").element(T.instanceIndex);
    const i = T.float(T.instanceIndex), count = T.uniform(n), t = T.uniform(0);
    const k = new Proxy(knobs, { get: (o, key) => o[key] });
    const realMath = Math;
    globalThis.Math = $M;
    let o;
    try {
      o = globalThis.each(i, count, t, k, { x: at.x, y: at.y, z: at.z, size: at.w, rotate: 0, opacity: 1, i, n: count }) || {};
    } finally {
      globalThis.Math = realMath;
    }

    const v = key => o[key] === undefined ? T.float(DEFAULT[key]) : asFloat(o[key]);
    const material = new THREE.MeshBasicNodeMaterial({ transparent: true });
    material.positionNode = T.rotate(
      T.positionLocal.mul(v("size")),
      T.vec3(v("rotate_x"), v("rotate_y"), v("rotate").mul(Math.PI / 180)),
    ).add(T.vec3(v("x"), v("y"), v("z")));
    material.opacityNode = v("opacity");
    const mesh = new THREE.InstancedMesh(plane, material, n);
    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    camera.coordinateSystem = THREE.WebGPUCoordinateSystem;
    camera.updateProjectionMatrix();
    const scene = new THREE.Scene();
    scene.updateMatrixWorld(); camera.updateMatrixWorld(); mesh.updateMatrixWorld();
    const b = new THREE.WGSLNodeBuilder(mesh, renderer);
    b.scene = scene; b.material = material; b.camera = camera; b.context.material = material;
    b.build();
    return { wgsl: b.vertexShader, why: "" };
  } catch (e) {
    return { wgsl: "", why: (e instanceof Reason ? "outside: " : "error: ") + String(e && e.message || e).replace(/\s+/g, " ").slice(0, 200) };
  }
}

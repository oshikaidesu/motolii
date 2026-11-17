// Probe: each() run once with TSL nodes for its inputs (copy number, time, knobs), its operators rewritten into calls the
// way AE.compile rewrites + - * / (engine/community/after_effects/ae_expr.h), and the result built to WGSL by three.js's
// own WGSLNodeBuilder with no GPU (as engine/community/three_shading_language_to_shelf/convert.ts does). Measures only.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import * as T from "three/tsl"
const [, ENGINE, LIST, OUT] = scriptArgs
std.evalScript(std.loadFile(ENGINE + "/third_party/js/acorn/acorn.js"))
const renderer = new THREE.WebGPURenderer({ canvas: { getContext() { return null }, style: {}, addEventListener() {} } })
renderer._initialized = true
renderer.backend.hasFeature = () => false
// WebGPU's own default limits (https://www.w3.org/TR/webgpu/#limits): the builder reads maxUniformBufferBindingSize.
renderer.backend.device = { limits: { maxUniformBufferBindingSize: 65536, maxStorageBufferBindingSize: 134217728 } }
const MODE = std.getenv("KNOBS") || "uniform"
renderer.backend.utils = new Proxy({}, { get: (_, k) => () => k === "getTextureSampleData" ? { primarySamples: 1 } : undefined })

class Reason extends Error {}
const isNode = v => v !== null && typeof v === "object" && v.isNode === true
const B = n => (n.__b = true, n), U = n => (n.__u = true, n)
const node = v => {
  if (isNode(v)) return v
  if (typeof v === "number") return T.float(v)
  if (typeof v === "boolean") return B(T.bool(v))
  throw new Reason(`a ${typeof v} meets a value that changes per copy or frame`)
}
const asFloat = v => isNode(v) ? (v.__u ? T.float(v) : v.__b ? T.select(v, T.float(1), T.float(0)) : v) : node(v)
const asUint = v => isNode(v) ? (v.__u ? v : T.uint(T.int(v))) : T.uint(v >>> 0)
const truth = v => v.__b ? v : asFloat(v).notEqual(0)
const js = { "+": (a, b) => a + b, "-": (a, b) => a - b, "*": (a, b) => a * b, "/": (a, b) => a / b, "%": (a, b) => a % b,
  "<": (a, b) => a < b, ">": (a, b) => a > b, "<=": (a, b) => a <= b, ">=": (a, b) => a >= b, "==": (a, b) => a == b, "===": (a, b) => a === b,
  "!=": (a, b) => a != b, "!==": (a, b) => a !== b, "&": (a, b) => a & b, "|": (a, b) => a | b, "^": (a, b) => a ^ b,
  "<<": (a, b) => a << b, ">>": (a, b) => a >> b, ">>>": (a, b) => a >>> b }
const bits = { "&": "bitAnd", "|": "bitOr", "^": "bitXor", "<<": "shiftLeft", ">>": "shiftRight", ">>>": "shiftRight" }
const cmp = { "<": "lessThan", ">": "greaterThan", "<=": "lessThanEqual", ">=": "greaterThanEqual", "==": "equal", "===": "equal", "!=": "notEqual", "!==": "notEqual" }
const arith = { "+": "add", "-": "sub", "*": "mul", "/": "div", "%": "mod" }
globalThis.$op = (op, a, b) => {
  if (!isNode(a) && !isNode(b)) return js[op](a, b)
  // A node is never undefined, null or a string: comparing with one is known now.
  const plain = v => isNode(v) || typeof v === "number" || typeof v === "boolean"
  if (cmp[op] && (!plain(a) || !plain(b))) return js[op](a, b)
  if (bits[op]) return U(asUint(a)[bits[op]](asUint(b)))
  if (cmp[op]) return B(asFloat(a)[cmp[op]](asFloat(b)))
  const intish = v => isNode(v) ? v.__u : Number.isInteger(v)
  if (op !== "/" && op !== "%" && intish(a) && intish(b)) return U(asUint(a)[arith[op]](asUint(b)))
  return asFloat(a)[arith[op]](asFloat(b))
}
globalThis.$un = (op, a) => {
  if (!isNode(a)) return op === "-" ? -a : op === "+" ? +a : op === "!" ? !a : ~a
  return op === "-" ? asFloat(a).negate() : op === "+" ? a : op === "!" ? B(truth(a).not()) : U(asUint(a).bitNot())
}
const DEFAULT = { x: 0, y: 0, z: 0, rotate: 0, rotate_x: 0, rotate_y: 0, size: 1, opacity: 1, scale_x: 1, scale_y: 1, scale_z: 1 }
const pick = (c, a, b) => {
  if (a !== null && typeof a === "object" && !isNode(a) || b !== null && typeof b === "object" && !isNode(b)) {
    const out = {}
    for (const k of new Set([...Object.keys(a || {}), ...Object.keys(b || {})])) out[k] = pick(c, (a || {})[k] ?? DEFAULT[k] ?? 0, (b || {})[k] ?? DEFAULT[k] ?? 0)
    return out
  }
  const n = T.select(c, asFloat(a), asFloat(b))
  return n
}
globalThis.$sel = (c, fa, fb) => isNode(c) ? pick(truth(c), fa(), fb()) : c ? fa() : fb()
globalThis.$logic = (op, fa, fb) => {
  const a = fa()
  if (!isNode(a)) return op === "&&" ? (a ? fb() : a) : op === "||" ? (a ? a : fb()) : (a ?? fb())
  if (op === "??") return a
  const b = fb()
  return op === "&&" ? pick(truth(a), b, a) : pick(truth(a), a, b)
}
globalThis.$test = c => { if (isNode(c)) throw new Reason("an if or a loop on a value that changes per copy or frame"); return c }
const fold = (f, g) => (...v) => v.some(isNode) ? v.map(asFloat).reduce((a, b) => g(a, b)) : f(...v)
globalThis.$M = new Proxy(Math, { get(M, k) {
  const one = { floor: T.floor, ceil: T.ceil, round: T.round, trunc: T.trunc, abs: T.abs, sin: T.sin, cos: T.cos, tan: T.tan, asin: T.asin,
    acos: T.acos, atan: T.atan, sqrt: T.sqrt, exp: T.exp, log: T.log, sign: T.sign, fround: x => x }[k]
  if (one) return x => isNode(x) ? one(asFloat(x)) : M[k](x)
  if (k === "min") return fold(M.min, T.min)
  if (k === "max") return fold(M.max, T.max)
  if (k === "pow") return (a, b) => isNode(a) || isNode(b) ? T.pow(asFloat(a), asFloat(b)) : M.pow(a, b)
  if (k === "atan2") return (y, x) => isNode(y) || isNode(x) ? T.atan(asFloat(y), asFloat(x)) : M.atan2(y, x)
  if (k === "hypot") return (...v) => v.some(isNode) ? T.sqrt(v.map(asFloat).map(a => a.mul(a)).reduce((a, b) => a.add(b))) : M.hypot(...v)
  if (k === "imul") return (a, b) => isNode(a) || isNode(b) ? U(asUint(a).mul(asUint(b))) : M.imul(a, b)
  if (k === "random") return () => { throw new Reason("Math.random: a new number on every run") }
  return M[k]
} })

// The rewrite: AE.compile's emit (ae_expr.h), with more operators, ?:, && || ??, the tests of if and loops, and Math.
const OPS = new Set(Object.keys(js))
function rewrite(src) {
  const ast = acorn.parse(src, { ecmaVersion: 2022, allowReturnOutsideFunction: true })
  const kids = n => { const out = []; for (const k in n) { if (k === "type" || k === "start" || k === "end") continue; const v = n[k]; if (Array.isArray(v)) { for (const x of v) if (x && typeof x.type === "string") out.push(x) } else if (v && typeof v.type === "string") out.push(v) } return out }
  const emit = (n, parent) => {
    if (n.type === "Property" && n.shorthand) return `${n.key.name}:${emit(n.value)}`
    if (n.type === "BinaryExpression" && OPS.has(n.operator)) return `$op(${JSON.stringify(n.operator)},${emit(n.left)},${emit(n.right)})`
    if (n.type === "LogicalExpression") return `$logic(${JSON.stringify(n.operator)},()=>(${emit(n.left)}),()=>(${emit(n.right)}))`
    if (n.type === "ConditionalExpression") return `$sel(${emit(n.test)},()=>(${emit(n.consequent)}),()=>(${emit(n.alternate)}))`
    if (n.type === "UnaryExpression" && "-+!~".includes(n.operator)) return `$un(${JSON.stringify(n.operator)},${emit(n.argument)})`
    if (n.type === "AssignmentExpression" && n.operator !== "=" && OPS.has(n.operator.slice(0, -1)))
      return `${src.slice(n.left.start, n.left.end)}=$op(${JSON.stringify(n.operator.slice(0, -1))},${emit(n.left)},${emit(n.right)})`
    if (n.type === "MemberExpression" && n.object.type === "Identifier" && n.object.name === "Math") return "$M" + src.slice(n.object.end, n.end)
    if (n.type === "BlockStatement" && n.body.length && returns(n.body[n.body.length - 1])) return `{${block(n.body)}}`
    let out = "", pos = n.start
    for (const k of kids(n).sort((a, b) => a.start - b.start)) {
      const e = emit(k, n)
      out += src.slice(pos, k.start) + (k === n.test && /If|While|For|DoWhile/.test(n.type) ? `$test(${e})` : e)
      pos = k.end
    }
    return out + src.slice(pos, n.end)
  }
  // An early return becomes a select of the two ways on (design doc §7): `if (c) return A; rest` is
  // `return $sel(c, () => { return A }, () => { rest })`, only where the rest returns too, so nothing falls through.
  const returns = s => s.type === "ReturnStatement" || s.type === "BlockStatement" && s.body.length > 0 && returns(s.body[s.body.length - 1]) ||
    s.type === "IfStatement" && !!s.alternate && returns(s.consequent) && returns(s.alternate)
  const body = s => s.type === "BlockStatement" ? s.body : [s]
  const block = list => {
    let out = ""
    for (let j = 0; j < list.length; j++) {
      const s = list[j]
      if (s.type === "IfStatement" && returns(s.consequent) && (s.alternate ? returns(s.alternate) : returns(list[list.length - 1]))) {
        const rest = s.alternate ? body(s.alternate) : list.slice(j + 1)
        return out + `return $sel(${emit(s.test)},()=>{${block(body(s.consequent))}},()=>{${block(rest)}});`
      }
      out += emit(s) + "\n"
    }
    return out
  }
  return emit(ast)
}

// The engine's own preludes, taken from its sources as text: Cavalry's random and Animators, and ease() by name.
const natives = std.loadFile(ENGINE + "/community/script_runner/script_natives.cpp")
const cavalry = natives.slice(natives.indexOf('cavalry_prelude = R"(') + 21, natives.indexOf(')";', natives.indexOf("cavalry_prelude")))
const ways = [...std.loadFile(ENGINE + "/motion/easing_names.h").matchAll(/\{"(\w+)", "([^"]+)"\}/g)].map(m => `${m[1]}: function (u) { return ${m[2]}; }`)
const easeJs = `var ease = (function () { var pow = Math.pow, exp = Math.exp, cos = Math.cos, abs = Math.abs, pi = function () { return Math.PI; }; var w = {${ways.join(", ")}}; return function (name, u) { u = Math.min(1, Math.max(0, u)); return w[name] ? w[name](u) : u; }; })();`
const aeText = (() => { const h = std.loadFile(ENGINE + "/community/after_effects/ae_expr.h"); return h.slice(h.indexOf('R"AEJS(') + 7, h.indexOf(')AEJS"')) })()
;(0, eval)(rewrite(easeJs)); (0, eval)(rewrite(cavalry))
// Code a script makes with new Function (AE.compile does) is rewritten too, the way it was written.
const RealFunction = Function
globalThis.Function = new Proxy(RealFunction, { construct: (F, a) => new F(...a.slice(0, -1), rewrite(String(a[a.length - 1] ?? ""))), apply: (F, _, a) => new F(...a.slice(0, -1), rewrite(String(a[a.length - 1] ?? ""))) })
// After Effects' runtime (ae_expr.h). Its val() takes .value from an object, and a uniform node has one: a node is not an AE property.
;(0, eval)(rewrite(aeText.replace("'value' in x)", "'value' in x && !x.isNode)")))
// The expression AE.compile builds is made by new Function, out of reach of the rewrite; its Math is the node-aware one.
const realMath = Math, traced = (...a) => { globalThis.Math = $M; try { return globalThis.each(...a) } finally { globalThis.Math = realMath } }
globalThis.folder = o => ({ __folder: o })   // leva's folder() (community/quickjs/script_leva.h)

const plane = new THREE.PlaneGeometry(1, 1)
const said = std.open(OUT + "/fit.tsv", "w")
let fit = 0, all = 0
for (const file of std.loadFile(LIST).trim().split("\n")) {
  all++
  const src = std.loadFile(file), name = file.split("/").pop().replace(/\.js$/, "")
  let why = "", wgsl = ""
  try {
    // A number knob is a uniform (KNOBS=uniform) or a constant built in (KNOBS=const); a word stays a word.
    const knobs = {}, put = (key, v) => knobs[key] = typeof v === "number" ? (MODE === "uniform" ? T.uniform(v) : v) : typeof v === "boolean" ? (MODE === "uniform" ? T.uniform(v ? 1 : 0) : v) : v
    for (const m of src.matchAll(/^\/\/\s*--(\w+)@(\w+):([^\n]*)$/gm)) {
      const parts = m[3].split(","), num = parts.slice(1).map(Number)
      put(m[2], m[1] === "track" ? num[2] : m[1] === "check" ? num[0] : m[1] === "select" ? parts[1] : Number.isNaN(num[0]) ? parts[1] : num[0])
    }
    globalThis.each = undefined
    if (std.getenv("SHOW")) console.log(rewrite(src).split("\n").map((l, j) => `${j + 1}: ${l}`).join("\n"))
    // (a const at the top of eval code stays inside that eval: the knobs object is read the way script_leva.h reads it, as a var)
    ;(0, eval)(rewrite(src.replace(/^(?:const|let)(\s+knobs\b)/m, "var$1")))
    let leva; try { leva = (0, eval)("typeof knobs === 'object' ? knobs : undefined") } catch {}
    const flat = o => { for (const [key, v] of Object.entries(o)) v && v.__folder ? flat(v.__folder) : put(key, v !== null && typeof v === "object" ? v.value : v) }
    if (leva) flat(leva)
    put("round", 4)   // (k.round: how long the document runs, as repeater.js says; any number for the check)
    put("px", 2 / 1080)   // (the runner's k.px, a document pixel in the stage's units: script_runner.cpp; any number for the check)
    if (typeof globalThis.each !== "function") throw new Reason("no each()")
    const n = 1000, at = T.instancedArray(n, "vec4").element(T.instanceIndex)
    const i = T.float(T.instanceIndex), count = T.uniform(n), t = T.uniform(0)
    const k = new Proxy(knobs, { get: (o, key) => o[key] })
    const o = traced(i, count, t, k, { x: at.x, y: at.y, z: at.z, size: at.w, rotate: 0, opacity: 1, i, n: count }) || {}
    const v = key => o[key] === undefined ? T.float(DEFAULT[key]) : asFloat(o[key])
    const material = new THREE.MeshBasicNodeMaterial({ transparent: true })
    material.positionNode = T.rotate(T.positionLocal.mul(v("size")), T.vec3(v("rotate_x"), v("rotate_y"), v("rotate").mul(Math.PI / 180))).add(T.vec3(v("x"), v("y"), v("z")))
    material.opacityNode = v("opacity")
    const mesh = new THREE.InstancedMesh(plane, material, n)
    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1); camera.coordinateSystem = THREE.WebGPUCoordinateSystem; camera.updateProjectionMatrix()
    const scene = new THREE.Scene(); scene.updateMatrixWorld(); camera.updateMatrixWorld(); mesh.updateMatrixWorld()
    const b = new THREE.WGSLNodeBuilder(mesh, renderer); b.scene = scene; b.material = material; b.camera = camera; b.context.material = material
    b.build()
    wgsl = b.vertexShader
    std.open(`${OUT}/${name}.vert.wgsl`, "w").puts(wgsl)
    fit++
    // For the value check: the same each() with only the copy number changing, written out per copy by a compute
    // shader at each time in CHECK (the copy's own place is made from its number, the same way in ref.mjs).
    for (const at_t of (std.getenv("CHECK") || "").split(",").filter(Boolean).map(Number)) {
      const N = 64, id = T.instanceIndex, fi = T.float(id), res = T.instancedArray(N * 2, "vec4")
      const p = traced(fi, N, at_t, k, { x: T.sin(fi), y: T.cos(fi.mul(0.7)), z: fi.mul(0.01), size: fi.mul(0.001).add(1), rotate: 0, opacity: 1, i: fi, n: N }) || {}
      const w = key => p[key] === undefined ? T.float(DEFAULT[key]) : asFloat(p[key])
      const job = T.Fn(() => {
        res.element(id.mul(2)).assign(T.vec4(w("x"), w("y"), w("z"), w("size")))
        res.element(id.mul(2).add(1)).assign(T.vec4(w("rotate"), w("rotate_x"), w("rotate_y"), w("opacity")))
      })().compute(N)
      const cb = new THREE.WGSLNodeBuilder(job, renderer); cb.build()
      std.open(`${OUT}/${name}@${at_t}.comp.wgsl`, "w").puts(cb.computeShader)
    }
  } catch (e) { if (std.getenv("WHY")) console.log(e.stack); why = (e instanceof Reason ? "outside: " : "error: ") + String(e && e.message || e).replace(/\s+/g, " ").slice(0, 140) }
  said.puts(`${name}\t${why || "wgsl"}\n`)
  console.log(`${why ? "NO " : "OK "} ${name}${why ? "  " + why : ""}`)
}
said.close()
console.log(`\nbuilt to WGSL: ${fit} of ${all}`)

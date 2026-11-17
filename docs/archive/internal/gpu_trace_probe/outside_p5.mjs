// Measure: p5.js sketches taken from outside (one file each, unchanged). Each is run with stand-ins for p5 (nothing is
// drawn; what is called is noted) to see whether a frame can be worked out from its number alone:
//   1. setup(), then draw() twice with plain numbers: do the sketch's own variables change, or does it paint over the
//      last frame without clearing it? Then it keeps earlier frames.
//   2. If not: draw() once with TSL nodes for frameCount, the clock and the mouse (trace.mjs's tracing): does it get
//      through, or is there an if or a loop on a changing value?
// No WGSL is built here: what comes out of a sketch is calls that paint, not one value.
//   qjs -m outside_p5.mjs <engine> <trace.mjs> <list of files> <out folder>
import { std, T, THREE, standIn, load, guard, note } from "./outside_lib.mjs"
const [, ENGINE, TRACE, LIST, OUT] = scriptArgs
const lib = load(ENGINE, TRACE)

let called = []
const rec = name => {
  const own = {}
  return new Proxy(function () {}, {
    get(_, k) {
      if (k === "__rec") return true
      if (k === Symbol.toPrimitive) return () => 0
      if (k === Symbol.iterator) return function* () {}
      if (typeof k === "symbol" || k === "then" || k === "isNode" || k === "__standin" || k === "__u" || k === "__b") return undefined
      if (Object.hasOwn(own, k)) return own[k]
      return k === "length" ? 0 : rec(name + "." + k)
    },
    set(_, k, v) { own[k] = v; return true },
    apply(_, self, args) { const moving = args.some(a => lib.isNode(a)); called.push(name + (moving ? "*" : "")); return moving ? standIn(name + "()") : rec(name + "()") },
    construct() { return rec("new " + name) },
  })
}
let stepping = false
globalThis.__called = n => { if (stepping && n === "random") throw new lib.Reason("random() in a step: its seed is a carried whole number, which this probe does not carry"); called.push(n) }
globalThis.__noise = a => [...a].some(lib.isNode) ? standIn("noise()") : 0.5

// p5's functions that give a number back, as p5's reference describes them (p5js.org/reference), in plain JavaScript:
// rewritten like the sketch, so they take nodes too. random() is p5's own generator (src/math/random.js, _lcg).
const one = ["sin", "cos", "tan", "asin", "acos", "atan", "abs", "floor", "ceil", "round", "sqrt", "exp", "log"]
const prelude = one.map(k => `function ${k}(x) { return Math.${k}(x) }`).join("\n") + `
var PI = Math.PI, TWO_PI = PI * 2, TAU = TWO_PI, HALF_PI = PI / 2, QUARTER_PI = PI / 4;
var width = 100, height = 100, windowWidth = 1280, windowHeight = 720, displayWidth = 1280, displayHeight = 720, __seed = 12345, __clock = 0;
function createCanvas(w, h) { width = w; height = h; __called("createCanvas"); }
function resizeCanvas(w, h) { width = w; height = h; }
function atan2(y, x) { return Math.atan2(y, x) } function pow(a, b) { return Math.pow(a, b) } function sq(x) { return x * x }
function __list(a) { return a.length === 1 && Array.isArray(a[0]) ? a[0] : Array.prototype.slice.call(a) }
function min() { return Math.min.apply(null, __list(arguments)) } function max() { return Math.max.apply(null, __list(arguments)) }
function map(v, a, b, c, d) { return c + (d - c) * ((v - a) / (b - a)) } function lerp(a, b, t) { return a + (b - a) * t }
function constrain(v, lo, hi) { return Math.min(Math.max(v, lo), hi) } function norm(v, a, b) { return (v - a) / (b - a) }
function dist(a, b, c, d) { return Math.hypot(c - a, d - b) } function mag(x, y) { return Math.hypot(x, y) }
function radians(d) { return d * Math.PI / 180 } function degrees(r) { return r * 180 / Math.PI }
function int(x) { return Math.trunc(x) } function fract(x) { return x - Math.floor(x) }
function millis() { return __clock }
function random(a, b) {
  __called("random"); __seed = (1664525 * __seed + 1013904223) % 4294967296; var r = __seed / 4294967296;
  if (Array.isArray(a)) return a[Math.floor(r * a.length)];
  return a === undefined ? r : b === undefined ? r * a : a + r * (b - a);
}
function noise() { __called("noise"); return __noise(arguments) }
var p5 = { Vector: class Vector {
  constructor(x, y, z) { this.x = x || 0; this.y = y || 0; this.z = z || 0 }
  static of(a, b, c) { return a instanceof p5.Vector ? a : new p5.Vector(a, b, c) }
  copy() { return new p5.Vector(this.x, this.y, this.z) } set(a, b, c) { var v = p5.Vector.of(a, b, c); this.x = v.x; this.y = v.y; this.z = v.z; return this }
  add(a, b, c) { var v = p5.Vector.of(a, b, c); this.x += v.x; this.y += v.y; this.z += v.z; return this }
  sub(a, b, c) { var v = p5.Vector.of(a, b, c); this.x -= v.x; this.y -= v.y; this.z -= v.z; return this }
  mult(n) { this.x *= n; this.y *= n; this.z *= n; return this } div(n) { this.x /= n; this.y /= n; this.z /= n; return this }
  magSq() { return this.x * this.x + this.y * this.y + this.z * this.z } mag() { return Math.sqrt(this.magSq()) }
  normalize() { var m = this.mag(); return m > 0 ? this.div(m) : this } setMag(m) { return this.normalize().mult(m) }
  limit(m) { return this.mag() > m ? this.setMag(m) : this } heading() { return Math.atan2(this.y, this.x) }
  dist(v) { return v.copy().sub(this).mag() } dot(v) { return this.x * v.x + this.y * v.y + this.z * v.z }
  rotate(a) { var x = this.x, y = this.y; this.x = x * Math.cos(a) - y * Math.sin(a); this.y = x * Math.sin(a) + y * Math.cos(a); return this }
  lerp(v, t) { this.x += (v.x - this.x) * t; this.y += (v.y - this.y) * t; this.z += (v.z - this.z) * t; return this }
  static add(a, b) { return a.copy().add(b) } static sub(a, b) { return a.copy().sub(b) } static mult(a, n) { return a.copy().mult(n) }
  static div(a, n) { return a.copy().div(n) } static dist(a, b) { return a.dist(b) }
  static fromAngle(a, l) { l = l === undefined ? 1 : l; return new p5.Vector(l * Math.cos(a), l * Math.sin(a)) }
  static random2D() { return p5.Vector.fromAngle(random(TWO_PI)) }
} };
function createVector(x, y, z) { return new p5.Vector(x, y, z) }
`
;(0, eval)(lib.rewrite(prelude))

const EVENTS = ["mousePressed", "mouseReleased", "mouseClicked", "mouseMoved", "mouseDragged", "mouseWheel", "doubleClicked", "keyPressed", "keyReleased", "keyTyped", "touchStarted", "touchMoved", "touchEnded", "deviceMoved", "deviceTurned", "deviceShaken"]
const INPUTS = ["frameCount", "deltaTime", "mouseX", "mouseY", "pmouseX", "pmouseY", "movedX", "movedY", "mouseIsPressed", "keyIsPressed", "key", "keyCode"]
const PAINT = new Set(["ellipse", "circle", "rect", "square", "line", "point", "triangle", "quad", "arc", "bezier", "curve", "text", "image", "vertex", "curveVertex", "bezierVertex", "endShape", "box", "sphere", "plane", "cone", "cylinder", "torus", "ellipsoid", "model"])
const base = n => n.replace("*", "").split(".").pop()
const ser = (v, d = 0) => v === null || typeof v !== "object" && typeof v !== "function" ? String(v) : v.__rec ? "<p5>" : lib.isNode(v) ? "<node>" : typeof v === "function" ? "<f>" : d > 5 ? "…"
  : Array.isArray(v) || ArrayBuffer.isView(v) ? "[" + Array.prototype.slice.call(v, 0, 300).map(x => ser(x, d + 1)).join(",") + "]"
  : v instanceof Map || v instanceof Set ? ser([...v], d + 1) : "{" + Object.keys(v).map(k => k + ":" + ser(v[k], d + 1)).join(",") + "}"

// The names a sketch uses and does not make itself: each becomes a stand-in for p5 that notes when it is called.
function names(ast) {
  const used = new Set(), top = []
  for (const s of ast.body) {
    if (s.type === "VariableDeclaration") for (const d of s.declarations) if (d.id.type === "Identifier") top.push(d.id.name)
  }
  const walk = (n, parent, key) => {
    if (n.type === "Identifier" && !(parent && (parent.type === "MemberExpression" && key === "property" && !parent.computed || /^(Property|MethodDefinition|PropertyDefinition)$/.test(parent.type) && key === "key" && !parent.computed))) used.add(n.name)
    for (const k in n) { const v = n[k]; if (Array.isArray(v)) { for (const x of v) if (x && typeof x.type === "string") walk(x, n, k) } else if (v && typeof v.type === "string") walk(v, n, k) }
  }
  walk(ast)
  return { used, top }
}

async function play(src, withNodes) {
  const ast = acorn.parse(src, { ecmaVersion: 2022 }), { used, top } = names(ast)
  const made = [], fns = ["preload", "setup", "draw", ...EVENTS]
  for (const n of used) if (!(n in globalThis)) { globalThis[n] = rec(n); made.push(n) }
  for (const n of INPUTS) globalThis[n] = 0
  globalThis.__seed = 12345; globalThis.__clock = 0; globalThis.width = 100; globalThis.height = 100
  called = []
  try {
    ;(0, eval)(lib.rewrite(src) + `\n;globalThis.__snap = () => [${top.join(",")}]; globalThis.__fn = {${fns.map(n => `${n}: typeof ${n} === "function" && !${n}.__rec ? ${n} : undefined`).join(",")}}`)
    const fn = globalThis.__fn, out = { has: Object.fromEntries(fns.map(n => [n, !!fn[n]])) }
    if (fn.preload) await fn.preload()
    if (fn.setup) await fn.setup()
    out.setup = called; out.s = [ser(globalThis.__snap())]; out.draws = []
    if (!withNodes) for (let f = 1; f <= 2 && fn.draw; f++) {
      globalThis.frameCount = f; globalThis.__clock = f * 1000 / 60; globalThis.deltaTime = 1000 / 60; called = []
      await fn.draw()
      out.draws.push(called); out.s.push(ser(globalThis.__snap()))
    } else {
      for (const n of INPUTS) globalThis[n] = T.uniform(n === "frameCount" ? 1 : 0)
      globalThis.__clock = T.uniform(0); called = []
      await fn.draw()
      out.draws.push(called)
    }
    return out
  } finally {
    for (const n of [...made, ...fns, ...INPUTS, "__snap", "__fn"]) delete globalThis[n]
  }
}


// STATE=1 — the declaration, read from the sketch as it is written: its top-level variables are what is carried from
// frame to frame, what setup() leaves in them is the first value, and draw() is one step. Three things are done:
//   1. 120 plain frames (the handlers of the mouse and keys called once at frame 60): which numbers change, and does
//      their count change?
//   2. After 30 plain frames each changing number is replaced by a node read from a buffer, and draw() is run once: is
//      every next value a formula of the last ones? If so the step is built to WGSL (a compute shader, buffer to buffer).
//   3. The same with the frame's inputs as plain numbers, and the values before and after frame 31 written beside it,
//      for run_state.ts to run on the GPU and compare.
async function stage(src) {
  const ast = acorn.parse(src, { ecmaVersion: 2022 }), { used } = names(ast), tops = []
  for (const s of ast.body) if (s.type === "VariableDeclaration") for (const d of s.declarations) if (d.id.type === "Identifier") tops.push({ name: d.id.name, fixed: s.kind === "const" })
  const made = [], fns = ["preload", "setup", "draw", ...EVENTS]
  for (const n of used) if (!(n in globalThis)) { globalThis[n] = rec(n); made.push(n) }
  for (const n of INPUTS) globalThis[n] = 0
  globalThis.__seed = 12345; globalThis.__clock = 0; globalThis.width = 100; globalThis.height = 100
  called = []
  const done = () => { for (const n of [...made, ...fns, ...INPUTS, "__snap", "__fn", "__put"]) delete globalThis[n] }
  try {
    ;(0, eval)(lib.rewrite(src) + `\n;globalThis.__snap = () => [${tops.map(t => t.name).join(",")}]; globalThis.__put = [${tops.map(t => t.fixed ? "null" : `$v => ${t.name} = $v`).join(",")}];` +
      `globalThis.__fn = {${fns.map(n => `${n}: typeof ${n} === "function" && !${n}.__rec ? ${n} : undefined`).join(",")}}`)
    const st = { fn: globalThis.__fn, tops, snap: globalThis.__snap, put: globalThis.__put, done }
    if (st.fn.preload) await st.fn.preload()
    if (st.fn.setup) await st.fn.setup()
    return st
  } catch (e) { done(); throw e }
}
const frame = f => { globalThis.frameCount = f; globalThis.__clock = f * 1000 / 60; globalThis.deltaTime = 1000 / 60 }
function leaves(st) {
  const out = new Map(), seen = new Set(), lists = []
  const walk = (v, path, o, k, d) => {
    if (typeof v === "number" || typeof v === "boolean" || lib.isNode(v)) { if (out.size < 50000) out.set(path, { o, k, v }); return }
    if (v === null || typeof v !== "object" || seen.has(v) || ArrayBuffer.isView(v) || d > 8) return
    seen.add(v)
    if (Array.isArray(v)) lists.push(v)
    for (const key of Object.keys(v)) walk(v[key], path + "." + key, v, key, d + 1)
  }
  const vals = st.snap()
  st.tops.forEach((t, i) => walk(vals[i], t.name, null, i, 0))
  return { out, lists }
}
const shape = m => [...m.keys()].join("|")
const W = 30

async function discover(src) {
  const st = await stage(src)
  try {
    let prev = leaves(st).out, grows = "", when = "warm"
    const byDraw = new Set(), byEvent = new Set(), at = {}, has = Object.fromEntries(["draw", ...EVENTS].map(n => [n, !!st.fn[n]]))
    const diff = into => { const now = leaves(st).out; if (shape(now) !== shape(prev) && when !== "warm") grows = grows || when; for (const [p, e] of now) { const b = prev.get(p); if (b && !Object.is(b.v, e.v)) into.add(p) } return prev = now }
    const tick = async f => { frame(f); called = []; when = f <= W ? "warm" : f <= 60 ? "draw" : "after a click"; if (st.fn.draw) await st.fn.draw(); return diff(byDraw) }
    at[0] = prev.size
    for (let f = 1; f <= 60; f++) { const now = await tick(f); if (f === W || f === W + 1) at[f] = new Map([...now].map(([p, e]) => [p, e.v])) }
    const last = called.map(base), picture = last.some(n => PAINT.has(n)) && !last.some(n => n === "background" || n === "clear")
    globalThis.mouseX = globalThis.pmouseX = globalThis.width / 2; globalThis.mouseY = globalThis.pmouseY = globalThis.height / 2
    globalThis.mouseIsPressed = globalThis.keyIsPressed = true; globalThis.key = "a"; globalThis.keyCode = 65
    when = "a click"
    for (const h of EVENTS) if (st.fn[h]) { await st.fn[h](rec("event")); diff(byEvent) }
    for (let f = 61; f <= 120; f++) await tick(f)
    return { byDraw, byEvent, grows, at, has, picture, size: [at[0], prev.size] }
  } finally { st.done() }
}

async function step(src, paths, what, plainInputs) {
  const st = await stage(src)
  try {
    for (let f = 1; f <= W; f++) { frame(f); if (st.fn.draw) await st.fn.draw() }
    const { out, lists } = leaves(st), P = paths.filter(p => out.has(p)), inP = new Set(P)
    const before = new Map([...out].map(([p, e]) => [p, e.v])), sIn = T.instancedArray(Math.max(1, P.length), "float")
    P.forEach((p, i) => {
      const e = out.get(p); let n = sIn.element(i)
      if (typeof e.v === "boolean") { n = n.notEqual(0); n.__b = true }
      if (e.o) e.o[e.k] = n; else st.put[e.k](n)
    })
    frame(W + 1)
    if (!plainInputs) { for (const n of INPUTS) globalThis[n] = T.uniform(n === "frameCount" ? W + 1 : 0); globalThis.__clock = T.uniform(0) }
    guard.lists = lists; guard.strict = true; stepping = true; note.used = 0; called = []
    try { if (st.fn[what]) await st.fn[what](what === "draw" ? undefined : rec("event")) } finally { guard.strict = false; stepping = false; guard.lists = [] }
    const after = leaves(st).out
    if (shape(after) !== shape(out)) throw new lib.Reason("the number of carried values changes in this step")
    const missed = [...after].filter(([p, e]) => !inP.has(p) && !Object.is(e.v, before.get(p))).map(([p]) => p)
    return { P, missed, next: P.map(p => after.get(p).v), leaned: note.used }
  } finally { st.done() }
}
function build(r, file) {
  const sOut = T.instancedArray(Math.max(1, r.P.length), "float")
  const job = T.Fn(() => { r.next.forEach((v, i) => sOut.element(i).assign(lib.asFloat(v === true ? 1 : v === false ? 0 : v))) })().compute(1)
  const b = new THREE.WGSLNodeBuilder(job, lib.renderer); b.build()
  std.open(file, "w").puts(b.computeShader)
}
// The step with every missed value added until none is missed (a value the 120 frames did not show changing).
async function whole(src, paths, what, plainInputs) {
  let P = paths, r
  for (let round = 0; round < 5; round++) { r = await step(src, P, what, plainInputs); if (!r.missed.length) return r; P = [...P, ...r.missed] }
  throw new lib.Reason("values keep turning up as carried")
}

async function declared(src, name) {
  const d = await discover(src), paths = [...new Set([...d.byDraw, ...d.byEvent])], events = EVENTS.filter(h => d.has[h])
  const row = { kind: "", why: "", carried: paths.length, events: events.join(" "), handlers: "" }
  if (!paths.length) { row.kind = d.picture ? "carries only the picture" : "carries nothing"; return row }
  if (d.grows === "draw") { row.kind = "the number of carried values changes"; row.why = `${d.size[0]} numbers after setup, ${d.size[1]} after 120 frames`; return row }
  const grew = d.grows ? `a click or a key adds carried values (${d.size[0]} to ${d.size[1]})` : ""
  const steps = [...(d.has.draw ? ["draw"] : []), ...events], file = `${OUT}/${name.replace(/\W+/g, "_")}`
  for (const what of steps) {
    try {
      const r = await whole(src, paths, what, false)
      if (what === "draw") { build(r, file + ".step.wgsl"); row.carried = r.P.length; if (r.leaned) row.why = "leans on a stand-in for p5" }
      else row.handlers += ` ${what}:ok`
    } catch (e) {
      if (std.getenv("WHY")) console.log(name, what, e.stack)
      const why = (e instanceof lib.Reason ? "" : "error: ") + String(e && e.message || e).replace(/\s+/g, " ").slice(0, 110)
      if (what === "draw") { row.kind = e instanceof lib.Reason ? "outside" : "error with nodes"; row.why = why; return row }
      row.handlers += ` ${what}:NO(${why})`
    }
  }
  row.kind = d.has.draw ? "one step is one formula" : "one step is one formula (on a click or a key only)"
  if (grew) row.handlers += " " + grew
  if (d.has.draw && !row.why) try {
    const r = await whole(src, paths, "draw", true)
    build(r, file + ".check.wgsl")
    const n = v => v === true ? 1 : v === false ? 0 : v
    std.open(file + ".check.json", "w").puts(JSON.stringify({ paths: r.P, in: r.P.map(p => n(d.at[W].get(p))), out: r.P.map(p => n(d.at[W + 1].get(p))) }))
  } catch (e) { row.why = "no check: " + String(e && e.message || e).replace(/\s+/g, " ").slice(0, 90) }
  return row
}


// ITEM=1 — the rule of one object, traced once. The sketch's largest list of like objects is taken as the things that
// are carried; where draw() walks that list, its body is run once, for "this object" (its numbers read from the buffer
// at the instance's own place), and the compute shader runs it once per object. A loop over the same list inside that
// rule (each bird looking at every bird) stays a loop in the shader: its body is run once with "the other object" at
// the loop's index, and what the body writes outside itself becomes a shader variable (three.js's Loop and toVar).
// Two things to compare the GPU's step with are written beside the shader: the sketch run as written (objects updated
// one after another, each seeing those before it already moved), and the same rule with every object reading the list
// as it was before the frame, which is what objects updated all at once can see.
const plain = v => v === true ? 1 : v === false ? 0 : v
function numbers(x) {   // the numbers in one object, in a fixed order
  const out = [], seen = new Set()
  const walk = (v, o, k, d) => {
    if (typeof v === "number" || typeof v === "boolean" || lib.isNode(v)) { out.push({ o, k, v }); return }
    if (v === null || typeof v !== "object" || seen.has(v) || ArrayBuffer.isView(v) || d > 6) return
    seen.add(v)
    for (const key of Object.keys(v)) walk(v[key], v, key, d + 1)
  }
  walk(x, null, null, 0)
  return out
}
function likeList(st) {
  let best = null
  for (const a of leaves(st).lists) {
    if (a.length < 2 || !a.every(x => x && typeof x === "object" && !Array.isArray(x))) continue
    const shapes = a.map(x => numbers(x).map(l => l.k).join("|"))
    if (!shapes[0] || !shapes.every(q => q === shapes[0])) continue
    const stride = numbers(a[0]).length
    if (!best || a.length * stride > best.list.length * best.stride) best = { list: a, stride }
  }
  return best
}
const valuesOf = list => list.flatMap(x => numbers(x).map(l => l.v))
const putBack = (list, flat) => { let n = 0; for (const x of list) for (const l of numbers(x)) l.o[l.k] = flat[n++] }
// One object of the list with its numbers read from the buffer at `index`.
function view(template, index, stride, buffer) {
  let n = 0
  const made = new Map()
  const clone = x => {
    if (made.has(x)) return made.get(x)
    const y = Array.isArray(x) ? [] : Object.create(Object.getPrototypeOf(x)); made.set(x, y)
    for (const key of Object.keys(x)) {
      const v = x[key]
      if (typeof v === "number" || typeof v === "boolean") { let node = buffer.element(index.mul(stride).add(n++)); if (typeof v === "boolean") { node = node.notEqual(0); node.__b = true } y[key] = node }
      else y[key] = v !== null && typeof v === "object" && !ArrayBuffer.isView(v) ? clone(v) : v
    }
    return y
  }
  return clone(template)
}
function shaderLoop(count, run) {
  const scalar = v => typeof v === "number" || typeof v === "boolean" || lib.isNode(v)
  const targets = lib.watch(() => run(T.int(0)))
  if (!targets.every(t => scalar(t.read()))) throw new lib.Reason("a loop over the list sets something that is not a number")
  const vars = targets.map(t => { const v = lib.asFloat(plain(t.read())).toVar(); t.write(v); return v })
  run(T.expression("i", "int"))
  const next = targets.map((t, n) => { const v = t.read(); t.write(vars[n]); return v === vars[n] ? null : lib.asFloat(plain(v)) })
  // (every new value first, then every variable: a new value reads the variables as they were before this turn)
  T.Loop(count, () => { const fresh = next.map(e => e && e.toVar()); fresh.forEach((e, n) => { if (e) vars[n].assign(e) }) })
}
async function warmed(src) {
  const st = await stage(src)
  try { for (let f = 1; f <= W; f++) { frame(f); if (st.fn.draw) await st.fn.draw() } } catch (e) { st.done(); throw e }
  const L = likeList(st)
  if (!L) { st.done(); throw new lib.Reason("no list of like objects") }
  return { st, ...L }
}
async function itemRule(src, name) {
  const file = `${OUT}/${name.replace(/\W+/g, "_")}`, ref = {}
  {   // as written
    const { st, list, stride } = await warmed(src)
    try {
      ref.count = list.length; ref.stride = stride; ref.in = valuesOf(list).map(plain)
      frame(W + 1); await st.fn.draw()
      if (list.length !== ref.count) throw new lib.Reason("the list changes its length in this frame")
      ref.out = valuesOf(list).map(plain)
    } finally { st.done() }
  }
  {   // every object reading the list as it was
    const { st, list } = await warmed(src)
    try {
      guard.items = { list, inside: false, at: j => list[j], over(run) {
        if (this.inside) { for (let j = 0; j < list.length; j++) run(j); return }
        const was = valuesOf(list), outs = []
        for (let k = 0; k < list.length; k++) { putBack(list, was); this.inside = true; try { run(k) } finally { this.inside = false } outs.push(numbers(list[k]).map(l => l.v)) }
        putBack(list, outs.flat())
      } }
      frame(W + 1); await st.fn.draw()
      ref.outAtOnce = valuesOf(list).map(plain)
    } finally { guard.items = null; st.done() }
  }
  const { st, list, stride } = await warmed(src)
  try {
    const N = list.length, sIn = T.instancedArray(N * stride, "float"), sOut = T.instancedArray(N * stride, "float")
    let walked = 0, loops = 0
    const job = T.Fn(() => {
      const self = T.instanceIndex, views = new Map()
      const I = guard.items = { list, inside: false, at: j => { let v = views.get(j); if (!v) views.set(j, v = view(list[0], j, stride, sIn)); return v },
        over(run) { if (this.inside) { loops++; return shaderLoop(N, run) } walked++; this.inside = true; try { run(self) } finally { this.inside = false } } }
      frame(W + 1); guard.lists = [list]; guard.strict = true; stepping = true; called = []
      try { st.fn.draw() } finally { guard.strict = false; stepping = false; guard.lists = []; guard.items = null }
      const next = numbers(I.at(self))
      if (next.length !== stride) throw new lib.Reason("the object's numbers change in number in its own rule")
      next.forEach((l, k) => sOut.element(self.mul(stride).add(k)).assign(lib.asFloat(plain(l.v))))
    })().compute(N)
    const b = new THREE.WGSLNodeBuilder(job, lib.renderer); b.build()
    if (walked !== 1) throw new lib.Reason(`draw() walks its list ${walked} times, not once`)
    std.open(file + ".check.wgsl", "w").puts(b.computeShader)
    std.open(file + ".check.json", "w").puts(JSON.stringify(ref))
    return { kind: "one object's rule is one shader", why: `${N} objects of ${stride} numbers, ${loops} loops over the list kept`, carried: N * stride, events: "", handlers: "" }
  } finally { st.done() }
}

const said = std.open(OUT + "/p5.tsv", "w"), count = {}
if (std.getenv("STATE")) {
  for (const file of std.loadFile(LIST).trim().split("\n")) {
    const src = std.loadFile(file), name = file.split("/").slice(-3, -1).join("/")
    let row
    try { row = await (std.getenv("ITEM") ? itemRule(src, name) : declared(src, name)) } catch (e) { if (std.getenv("WHY")) console.log(name, e.stack); row = { kind: e instanceof lib.Reason ? "outside" : "does not run here", why: String(e && e.message || e).replace(/\s+/g, " ").slice(0, 110), carried: "", events: "", handlers: "" } }
    said.puts(`${name}\t${row.kind}\t${row.why}\t${row.carried}\t${row.events}\t${row.handlers.trim()}\n`)
    console.log(`${row.kind.padEnd(40)} ${name}  ${row.carried} carried${row.why ? "  — " + row.why : ""}${row.handlers ? "  [" + row.handlers.trim() + "]" : ""}`)
  }
  said.close()
  std.exit(0)
}
for (const file of std.loadFile(LIST).trim().split("\n")) {
  const src = std.loadFile(file), name = file.split("/").slice(-3, -1).join("/")
  let kind = "", why = "", events = ""
  try {
    const a = await play(src, false)
    events = EVENTS.filter(n => a.has[n]).join(" ")
    const stopped = a.setup.some(n => base(n) === "noLoop") || a.draws.flat().some(n => base(n) === "noLoop")
    if (!a.has.setup && !a.has.draw) throw new Error("no setup() or draw() of its own")
    if (!a.has.draw || stopped) kind = events ? "moves only on a click or a key" : "a still"
    else {
      const vars = a.s[0] !== a.s[1] || a.s[1] !== a.s[2], last = a.draws[1].map(base)
      const picture = last.some(n => PAINT.has(n)) && !last.some(n => n === "background" || n === "clear")
      if (vars || picture) { kind = "keeps earlier frames"; why = [vars && "its variables", picture && "the picture"].filter(Boolean).join(" and ") }
      else if (last.includes("random")) kind = "new random numbers each frame"
      else {
        try {
          const b = await play(src, true)
          kind = b.draws[0].some(n => n.endsWith("*")) ? "worked out from the frame alone" : "does not move"
        } catch (e) { if (std.getenv("WHY")) console.log(name, e.stack); kind = e instanceof lib.Reason ? "outside" : "error with nodes"; why = String(e && e.message || e).replace(/\s+/g, " ").slice(0, 110) }
      }
    }
  } catch (e) { if (std.getenv("WHY")) console.log(name, e.stack); kind = "does not run here"; why = String(e && e.message || e).replace(/\s+/g, " ").slice(0, 110) }
  count[kind] = (count[kind] || 0) + 1
  said.puts(`${name}\t${kind}\t${why}\t${events}\n`)
  console.log(`${kind.padEnd(32)} ${name}${why ? "  — " + why : ""}${events ? "  [" + events + "]" : ""}`)
}
said.close()
console.log("\n" + Object.entries(count).map(([k, v]) => `${k}: ${v}`).join("   "))

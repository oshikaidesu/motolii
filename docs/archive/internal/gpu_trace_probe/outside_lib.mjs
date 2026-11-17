// What the outside measures share: trace.mjs's tracing read as text (one copy of it), a stand-in for what code reads,
// and (IFCONVERT=1) an `if` on a changing value run both ways.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import * as T from "three/tsl"
export { std, THREE, T }

// A stand-in: something read from the project. It is a number that may change (a uniform), any of its members is
// another stand-in, and calling it gives another. What was called, and whether with a changing value (*), is noted.
export const note = { calls: [], used: 0 }
const un = v => v && v.__standin === true ? v.__node : v
export const standIn = name => {
  let n
  return new Proxy(function () {}, {
    get(_, k) {
      if (k === "isNode" || k === "__standin") return true
      if (k === "__node") { note.used++; return n ??= T.uniform(0) }
      if (k === Symbol.toPrimitive) return () => { throw new lib.Reason(`${name} is wanted as a word or as a place in a list`) }
      if (typeof k === "symbol" || k === "__u" || k === "__b" || k === "then") return undefined
      return standIn(/^\d+$/.test(k) ? `${name}[${k}]` : `${name}.${k}`)
    },
    apply(_, self, args) { note.calls.push(name.split(".").pop() + (args.some(a => lib.isNode(a)) ? "*" : "")); return standIn(name + "()") },
  })
}

// IFCONVERT=1: if-conversion, done while the code runs. An `if` (or ?:, &&, ||) on a changing value runs both ways:
// every write made on the first way is noted and taken back, the second way runs, and each written variable or member
// ends as a select of the two. This is what jax.lax.cond and TensorFlow AutoGraph do to Python's `if`
// (tensorflow.org/guide/function#conditionals). For that, every assignment in the rewritten code goes through $setv
// (a name) or $setm (a member). An `if` with a return or a break inside is left as it was, and stops the trace.
const FIRST = '    if (n.type === "Property" && n.shorthand)'
// Which function's run a name belongs to: a name set inside an `if` on a changing value is noted only if that run
// began before the `if` did ($d<id>, the number of open ifs when the function was entered). A name of a function
// called from inside the `if` is that call's own, and is gone when it returns.
const EMIT = "  const emit = (n, parent) => {"
const SCOPES = String.raw`
  let $next = 0
  const $top = { id: 0, names: new Set(), up: null }
  const $pat = (p, f) => { if (p.type === "Identifier") f.names.add(p.name); else kids(p).forEach(k => $pat(k, f)) }
  const $scan = (n, f) => {
    if (/Function/.test(n.type)) {
      const g = { id: n.body.type === "BlockStatement" ? ++$next : -1, names: new Set(), up: f }
      if (n.id) (n.type === "FunctionDeclaration" ? f : g).names.add(n.id.name)
      for (const p of n.params) $pat(p, g)
      n.$f = g; n.$in = f
      kids(n).forEach(k => $scan(k, g))
      return
    }
    if (n.type === "VariableDeclarator") $pat(n.id, f)
    if (n.type === "ClassDeclaration" && n.id) f.names.add(n.id.name)
    if (n.type === "CatchClause" && n.param) $pat(n.param, f)
    n.$in = f
    kids(n).forEach(k => $scan(k, f))
  }
  $scan(ast, $top)
  const $since = (name, n) => { let f = n.$in; while (f && !f.names.has(name)) f = f.up; return !f || f.id === 0 ? "0" : f.id < 0 ? "1/0" : "$d" + f.id }
`
const HOOKS = String.raw`
    {
      const key = m => m.computed ? emit(m.property, m) : JSON.stringify(m.property.name)
      const member = m => m.type === "MemberExpression" && m.object.type !== "Super" && m.property.type !== "PrivateIdentifier" && !m.optional
      const cell = x => "()=>" + x + ",$v=>" + x + "=$v," + JSON.stringify(x)
      const free = (s, loop) => !s || /Function/.test(s.type) || !(s.type === "ReturnStatement" || s.type === "ThrowStatement" || s.type === "AwaitExpression" || s.type === "YieldExpression" || /^(Break|Continue)Statement$/.test(s.type) && !loop) &&
        kids(s).every(k => free(k, loop || /^(For|While|DoWhile|Switch)/.test(s.type)))
      if (n.type === "UpdateExpression") {
        const op = JSON.stringify(n.operator[0]), a = n.argument
        if (a.type === "Identifier") return "$setv(" + cell(a.name) + "," + op + ",1," + !n.prefix + "," + $since(a.name, n) + ")"
        if (member(a)) return "$setm(" + emit(a.object, a) + "," + key(a) + "," + op + ",1," + !n.prefix + ")"
      }
      if (n.type === "AssignmentExpression" && (n.operator === "=" || OPS.has(n.operator.slice(0, -1)))) {
        const op = JSON.stringify(n.operator.slice(0, -1)), l = n.left
        if (l.type === "Identifier") return "$setv(" + cell(l.name) + "," + op + "," + emit(n.right, n) + ",false," + $since(l.name, n) + ")"
        if (member(l)) return "$setm(" + emit(l.object, l) + "," + key(l) + "," + op + "," + emit(n.right, n) + ")"
        return "($unnoted()," + src.slice(l.start, l.end) + n.operator + emit(n.right, n) + ")"
      }
      if (/Function/.test(n.type) && n.$f && n.$f.id > 0) return src.slice(n.start, n.body.start) + "{const $d" + n.$f.id + "=$depth();" + emit(n.body, n).slice(1)
      // A loop over a list, and a read at a place in a list, go through $forOf, $loop and $at: guard.items may answer
      // them for the list of like objects (ITEM=1 in outside_p5.mjs). Otherwise they are the plain loop and read.
      if (n.type === "ForOfStatement" && !n.await && n.left.type === "VariableDeclaration" && n.left.declarations[0].id.type === "Identifier" && free(n.body))
        return "$forOf(" + emit(n.right, n) + ",(" + n.left.declarations[0].id.name + ")=>{" + emit(n.body, n) + "});"
      if (n.type === "ForStatement" && n.init && n.init.type === "VariableDeclaration" && n.init.declarations.length === 1 && n.test && n.update && free(n.body)) {
        const d = n.init.declarations[0], t = n.test, u = n.update, i = d.id.name
        if (i && d.init && d.init.type === "Literal" && d.init.value === 0 && t.type === "BinaryExpression" && t.operator === "<" && t.left.type === "Identifier" && t.left.name === i &&
            t.right.type === "MemberExpression" && !t.right.computed && t.right.property.name === "length" && u.type === "UpdateExpression" && u.operator === "++" && u.argument.type === "Identifier" && u.argument.name === i)
          return "$loop(" + emit(t.right.object, t.right) + ",(" + i + ")=>{" + emit(n.body, n) + "});"
      }
      if (n.type === "MemberExpression" && n.computed && member(n) && !(parent && (parent.type === "CallExpression" && parent.callee === n || parent.type === "UnaryExpression" && parent.operator === "delete" ||
          parent.type === "AssignmentExpression" && parent.left === n || parent.type === "UpdateExpression")))
        return "$at(" + emit(n.object, n) + "," + emit(n.property, n) + ")"
      if (n.type === "SwitchStatement") return "switch($plain(" + emit(n.discriminant, n) + ")){" + n.cases.map(c => emit(c, n)).join("") + "}"
      if (n.type === "IfStatement" && !returns(n) && free(n.consequent) && free(n.alternate)) {
        const id = globalThis.$ids = (globalThis.$ids || 0) + 1, c = "$c" + id, a = emit(n.consequent, n), b = n.alternate ? emit(n.alternate, n) : ""
        return "{const " + c + "=" + emit(n.test, n) + ";if(!$moving(" + c + ")){if(" + c + "){" + a + "}else{" + b + "}}else{$open();{" + a + "}$swap();{" + b + "}$close(" + c + ");}}"
      }
    }
`

// What a step may not do unseen: `strict` makes a changing value refuse to become a plain number or a word, and
// `lists` are the lists whose lengths may not change inside an `if` on a changing value.
export const guard = { strict: false, lists: [], items: null }
export let lib
export function load(ENGINE, TRACE) {
  std.evalScript(std.loadFile(ENGINE + "/third_party/js/acorn/acorn.js"))
  const text = std.loadFile(TRACE)
  const part = text.slice(text.indexOf("const renderer ="), text.indexOf("// The engine's own preludes"))
    .replace('const isNode = v => v !== null && typeof v === "object" && v.isNode === true', 'const isNode = v => v != null && (typeof v === "object" || typeof v === "function") && v.isNode === true')
    .replace("const asFloat = v =>", "const asFloat = w => asFloat0(un(w)), asFloat0 = v =>")
    .replace("const asUint = v =>", "const asUint = w => asUint0(un(w)), asUint0 = v =>")
    .replace("`$test(${e})`", "`$test(${e},${JSON.stringify(n.type)})`")
  for (const must of ['typeof v === "function"', "asFloat0", "asUint0", "JSON.stringify(n.type)"]) if (!part.includes(must)) throw new Error("trace.mjs changed: " + must)
  const both = !!std.getenv("IFCONVERT"), on = both ? part.replace(FIRST, HOOKS + FIRST).replace(EMIT, SCOPES + EMIT) : part
  if (both && !(on.includes(HOOKS) && on.includes(SCOPES))) throw new Error("trace.mjs changed: " + FIRST + " or " + EMIT)
  lib = new Function("T", "THREE", "std", "un", on + "\n;return { Reason, isNode, asFloat, rewrite, renderer }")(T, THREE, std, un)
  const G = globalThis, isNode = lib.isNode, Reason = lib.Reason
  G.$test = (c, type) => { if (isNode(c)) throw new Reason(type === "IfStatement" ? (both ? "an if on a changing value, with a return or a break inside" : "an if on a changing value, with more than a result inside") : "a loop that runs a changing number of times"); return c }
  if (!both) return lib

  THREE.Node.prototype[Symbol.toPrimitive] = function (hint) { if (guard.strict) throw new Reason("a changing value is wanted as a plain number, a word or a place in a list"); return hint === "number" ? NaN : "[node]" }
  const sel0 = G.$sel, scalar = v => typeof v === "number" || typeof v === "boolean" || isNode(v), num = v => v === true ? 1 : v === false ? 0 : v
  const mix = (c, a, b) => {
    if (a === b) return a
    // (set on one way only: the other way never had it, and would have read nothing; the one value there is stays)
    if (a === undefined) return b
    if (b === undefined) return a
    if (Array.isArray(a) && Array.isArray(b) && a.length === b.length) return a.map((e, i) => mix(c, e, b[i]))
    if (scalar(a) && scalar(b)) return sel0(c, () => num(a), () => num(b))
    if (like(a, b)) { const o = Object.create(Object.getPrototypeOf(a)); for (const k of Object.keys(a)) o[k] = mix(c, a[k], b[k]); return o }
    throw new Reason("an if on a changing value leaves two things that are not both numbers")
  }
  const like = (a, b) => a && b && typeof a === "object" && typeof b === "object" && !isNode(a) && !isNode(b) && !Array.isArray(a) && Object.getPrototypeOf(a) === Object.getPrototypeOf(b) && Object.keys(a).join() === Object.keys(b).join()
  // The writes of the way being run: members by object and key, names by a pair of functions that read and set them.
  const open = [], SENT = {}, lengths = () => { let s = 0; for (const a of guard.lists) s += a.length; return s }
  const same = (e, get) => { let keep, r = false; try { keep = e.get() } catch { return false } e.set(SENT); try { r = get() === SENT } catch {} e.set(keep); return r }
  const notem = (f, o, k, old) => { let per = f.m.get(o); if (!per) f.m.set(o, per = new Map()); if (!per.has(k)) per.set(k, { old }) }
  const notev = (f, get, set, name, old, since) => { if (!f.v.some(e => e.name === name && same(e, get))) f.v.push({ get, set, name, old, since }) }
  G.$moving = isNode
  G.$plain = v => { if (isNode(v)) throw new Reason("a switch on a changing value"); return v }
  G.$unnoted = () => { if (open.length) throw new Reason("several names are set at once inside an if on a changing value") }
  G.$setm = (o, k, op, v, post) => {
    const old = o[k], next = op ? G.$op(op, old, v) : v
    // (a member that was not there is not noted: an object made on one way is that way's own, and is not taken back)
    if (open.length && k in o) notem(open[open.length - 1], o, k, old)
    if (ArrayBuffer.isView(o) && isNode(next)) throw new Reason("a changing value is put into a list of plain numbers")
    o[k] = next
    return post ? old : next
  }
  G.$depth = () => open.length
  G.$setv = (get, set, name, op, v, post, since) => {
    let old
    if (op || open.length > since) try { old = get() } catch {}
    const next = op ? G.$op(op, old, v) : v
    if (open.length > since) notev(open[open.length - 1], get, set, name, old, since)
    set(next)
    return post ? old : next
  }
  G.$open = () => open.push({ m: new Map(), v: [], lengths: lengths() })
  G.$swap = () => {
    const f = open[open.length - 1]
    for (const [o, per] of f.m) for (const [k, e] of per) { e.a = o[k]; o[k] = e.old }
    for (const e of f.v) { e.a = e.get(); e.set(e.old) }
    f.A = { m: f.m, v: f.v }; f.m = new Map(); f.v = []
  }
  G.$close = c => {
    const f = open.pop(), up = open[open.length - 1]
    if (lengths() !== f.lengths) throw new Reason("a list changes its length inside an if on a changing value")
    for (const [o, per] of f.A.m) for (const [k, e] of per) { const b = o[k]; o[k] = mix(c, e.a, b); if (up) notem(up, o, k, e.old) }
    for (const [o, per] of f.m) for (const [k, e] of per) if (!f.A.m.get(o)?.has(k)) { o[k] = mix(c, e.old, o[k]); if (up) notem(up, o, k, e.old) }
    for (const e of f.A.v) { e.set(mix(c, e.a, e.get())); if (up && open.length > e.since) notev(up, e.get, e.set, e.name, e.old, e.since) }
    for (const e of f.v) if (!f.A.v.some(a => a.name === e.name && same(a, e.get))) { e.set(mix(c, e.old, e.get())); if (up && open.length > e.since) notev(up, e.get, e.set, e.name, e.old, e.since) }
  }
  // What a piece of code writes that outlives it, each as a pair that reads and writes it; the writes are taken back.
  lib.watch = fn => {
    G.$open(); let f
    try { fn() } finally { f = open.pop() }
    const out = []
    for (const [o, per] of f.m) for (const [k, e] of per) { o[k] = e.old; out.push({ read: () => o[k], write: v => { o[k] = v } }) }
    for (const e of f.v) { e.set(e.old); out.push({ read: e.get, write: e.set }) }
    return out
  }
  G.$forOf = (it, body) => { const I = guard.items; if (I && it === I.list) return I.over(j => body(I.at(j))); for (const x of it) body(x) }
  G.$loop = (list, body) => { const I = guard.items; if (I && list === I.list) return I.over(body); for (let i = 0; i < list.length; i++) body(i) }
  G.$at = (o, k) => { const I = guard.items; return I && o === I.list && isNode(k) ? I.at(k) : o[k] }
  G.$sel = (c, fa, fb) => {
    if (!isNode(c)) return c ? fa() : fb()
    G.$open(); const a = fa(); G.$swap(); const b = fb(); G.$close(c)
    return a === b ? a : scalar(a) && scalar(b) || Array.isArray(a) && Array.isArray(b) || like(a, b) ? mix(c, a, b) : sel0(c, () => a, () => b)
  }
  G.$logic = (op, fa, fb) => {
    const a = fa()
    if (!isNode(a)) return op === "&&" ? (a ? fb() : a) : op === "||" ? (a ? a : fb()) : (a ?? fb())
    if (op === "??") return a
    let b
    G.$open(); if (op === "&&") { b = fb(); G.$swap() } else { G.$swap(); b = fb() } G.$close(a)
    return op === "&&" ? sel0(a, () => b, () => a) : sel0(a, () => a, () => b)
  }
  return lib
}

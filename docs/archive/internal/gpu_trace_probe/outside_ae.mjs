// Measure: After Effects expressions taken from outside (one file each, unchanged) run once through AE.compile with TSL
// nodes for time and index, and a stand-in for everything else an expression reads (value, thisComp, a bare property
// name, a function the adapter does not have). The result is built to WGSL by three.js's own WGSLNodeBuilder.
// The tracing itself is trace.mjs's, read as text, so there is one copy of it.
//   qjs -m outside_ae.mjs <engine> <trace.mjs> <list of files> <out folder>
import { std, THREE, T, note, standIn, load } from "./outside_lib.mjs"
const [, ENGINE, TRACE, LIST, OUT] = scriptArgs
const lib = load(ENGINE, TRACE)

const RealFunction = Function
globalThis.Function = new Proxy(RealFunction, { construct: (F, a) => new F(...a.slice(0, -1), lib.rewrite(String(a[a.length - 1] ?? ""))), apply: (F, _, a) => new F(...a.slice(0, -1), lib.rewrite(String(a[a.length - 1] ?? ""))) })
// The engine's one Bezier solver is C++ (script_natives.cpp): a node cannot go through it. Noted, and stood in for.
globalThis.__bezier = () => { note.calls.push("__bezier(native)"); return standIn("__bezier()") }
const h = std.loadFile(ENGINE + "/community/after_effects/ae_expr.h")
;(0, eval)(lib.rewrite(h.slice(h.indexOf('R"AEJS(') + 7, h.indexOf(')AEJS"')).replace("'value' in x)", "'value' in x && !x.isNode)")))
const known = new Set(Object.keys(AE.H))

const said = std.open(OUT + "/ae.tsv", "w")
const count = {}
for (const file of std.loadFile(LIST).trim().split("\n")) {
  const src = std.loadFile(file), name = file.split("/").pop().replace(/\.js$/, "")
  note.calls = []
  const stood = []
  let kind = "", why = ""
  try {
    let f
    try { f = AE.compile(src) } catch (e) { if (e instanceof SyntaxError) { kind = "not JavaScript"; throw e } throw e }
    const c = { index: T.float(T.instanceIndex).add(1), time: T.uniform(0), value: standIn("value"), comp: standIn("thisComp"), layer: standIn("thisLayer"),
      textIndex: standIn("textIndex"), textTotal: standIn("textTotal"), selectorValue: standIn("selectorValue"), effect: standIn("effect") }
    let r
    for (let tries = 0; ; tries++) {
      note.calls = []
      try { r = AE.run(f, c); break } catch (e) {
        const m = e instanceof ReferenceError && tries < 60 && /'?([\w$]+)'? is not defined/.exec(e.message)
        if (!m) throw e
        stood.push(m[1]); globalThis[m[1]] = standIn(m[1])
      }
    }
    const flat = [], walk = v => Array.isArray(v) ? v.forEach(walk) : flat.push(v)
    walk(r)
    if (flat.some(v => typeof v === "string")) throw new lib.Reason("gives words")
    if (flat.some(v => v === null || v === undefined || (typeof v === "object" || typeof v === "function") && !lib.isNode(v))) throw new lib.Reason("gives something that is not a number")
    // A result that is only what a stand-in handed back was not worked out by the code: nothing was traced.
    if (!flat.some(lib.isNode)) kind = "a fixed number"
    else if (!flat.some(v => lib.isNode(v) && v.__standin !== true)) kind = "only a read"
    else {
      const id = T.instanceIndex, res = T.instancedArray(64 * flat.length, "vec4")
      const job = T.Fn(() => { flat.forEach((v, j) => res.element(id.mul(flat.length).add(j)).assign(T.vec4(lib.asFloat(v), 0, 0, 0))) })().compute(64)
      const b = new THREE.WGSLNodeBuilder(job, lib.renderer); b.build()
      std.open(`${OUT}/${name}.comp.wgsl`, "w").puts(b.computeShader)
      kind = "wgsl"
    }
  } catch (e) {
    if (std.getenv("WHY")) console.log(name, e.stack)
    kind = kind || (e instanceof lib.Reason ? "outside" : "error"); why = String(e && e.message || e).replace(/\s+/g, " ").slice(0, 120)
  }
  for (const s of stood) delete globalThis[s]
  count[kind] = (count[kind] || 0) + 1
  const names = [...new Set([...stood.filter(s => !known.has(s)), ...note.calls])].join(" ")
  said.puts(`${name}\t${kind}\t${why}\t${names}\n`)
  console.log(`${kind.padEnd(15)} ${name}${why ? "  " + why : ""}`)
}
said.close()
console.log("\n" + Object.entries(count).map(([k, v]) => `${k}: ${v}`).join("   "))

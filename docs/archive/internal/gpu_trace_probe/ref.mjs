// The values each() gives when run as written, in QuickJS with the engine's own preludes (no rewrite), for the check.
import * as std from "qjs:std"
const [, ENGINE, LIST, OUT, TIMES] = scriptArgs
const natives = std.loadFile(ENGINE + "/community/script_runner/script_natives.cpp")
const cavalry = natives.slice(natives.indexOf('cavalry_prelude = R"(') + 21, natives.indexOf(')";', natives.indexOf("cavalry_prelude")))
const ways = [...std.loadFile(ENGINE + "/motion/easing_names.h").matchAll(/\{"(\w+)", "([^"]+)"\}/g)].map(m => `${m[1]}: function (u) { return ${m[2]}; }`)
;(0, eval)(`var ease = (function () { var pow = Math.pow, exp = Math.exp, cos = Math.cos, abs = Math.abs, pi = function () { return Math.PI; }; var w = {${ways.join(", ")}}; return function (name, u) { u = Math.min(1, Math.max(0, u)); return w[name] ? w[name](u) : u; }; })();`)
const aeText = (() => { const h = std.loadFile(ENGINE + "/community/after_effects/ae_expr.h"); return h.slice(h.indexOf('R"AEJS(') + 7, h.indexOf(')AEJS"')) })()
;(0, eval)(cavalry)
;(0, eval)(std.loadFile(ENGINE + "/third_party/js/acorn/acorn.js")); (0, eval)(aeText)
globalThis.folder = o => ({ __folder: o })
const DEFAULT = { x: 0, y: 0, z: 0, rotate: 0, rotate_x: 0, rotate_y: 0, size: 1, opacity: 1 }
const keys = ["x", "y", "z", "size", "rotate", "rotate_x", "rotate_y", "opacity"]
for (const file of std.loadFile(LIST).trim().split("\n")) {
  const src = std.loadFile(file), name = file.split("/").pop().replace(/\.js$/, "")
  try {
    const k = {}
    for (const m of src.matchAll(/^\/\/\s*--(\w+)@(\w+):([^\n]*)$/gm)) {
      const parts = m[3].split(","), num = parts.slice(1).map(Number)
      k[m[2]] = m[1] === "track" ? num[2] : m[1] === "check" ? !!num[0] : m[1] === "select" ? parts[1] : Number.isNaN(num[0]) ? parts[1] : num[0]
    }
    globalThis.each = undefined
    ;(0, eval)(src.replace(/^(?:const|let)(\s+knobs\b)/m, "var$1"))
    let leva; try { leva = (0, eval)("typeof knobs === 'object' ? knobs : undefined") } catch {}
    const flat = o => { for (const [key, v] of Object.entries(o)) v && v.__folder ? flat(v.__folder) : k[key] = v !== null && typeof v === "object" ? v.value : v }
    if (leva) flat(leva)
    k.round = 4, k.px = 2 / 1080
    for (const t of TIMES.split(",").map(Number)) {
      const N = 64, rows = []
      for (let i = 0; i < N; i++) {
        const o = globalThis.each(i, N, t, k, { x: Math.sin(i), y: Math.cos(i * 0.7), z: i * 0.01, size: 1 + i * 0.001, rotate: 0, opacity: 1, i, n: N }) || {}
        rows.push(keys.map(key => o[key] === undefined ? DEFAULT[key] : +o[key]))
      }
      std.open(`${OUT}/${name}@${t}.ref.json`, "w").puts(JSON.stringify(rows))
    }
  } catch (e) { console.log(`ref ${name}: ${e.message}`) }
}

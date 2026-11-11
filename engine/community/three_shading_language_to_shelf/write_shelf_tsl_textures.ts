// boytchev/tsl-textures (MIT): its textures as files of the effects shelf, each made as its own page says (tsl_textures.ts),
// by three.js's own builder. A knob is what the author's demo page (online/<name>.html) shows, with the span it gives; what
// the page does not show stays as the author left it. A texture for a slot other than the colour's (bumps, moved points)
// makes no picture of its own and is left out.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import { uniform, uv } from "three/tsl"
import * as T from "../../third_party/tsl/boytchev__tsl-textures/src/tsl-textures.js"
import { madeText, parts } from "./write_shelf_file"
import { pointsText } from "./write_shelf_points"

const root = "../../third_party/tsl/boytchev__tsl-textures/", dir = "../../../shelves/effects/generate"   // (its --label:Generate)
const pages = (std.popen(`ls ${root}docs`, "r").readAsString() ?? "").split("\n").filter(f => f.endsWith(".md")).map(p => std.loadFile(`${root}docs/${p}`) ?? "")
const only = scriptArgs.slice(1)
const axes = "xyz"

for (const [name, f] of Object.entries(T) as [string, any][]) {
  if (typeof f !== "function" || !f.defaults || (only.length && !only.includes(name))) continue
  const slots = new Set(pages.flatMap(t => [...t.matchAll(new RegExp(`material\\.(\\w+Node) = ${name}\\b`, "g"))].map(m => m[1])))
  const moves = slots.has("positionNode") || f.defaults.$positionNode   // (it moves a shape's points: a points file, write_shelf_points.ts)
  if (slots.size && !slots.has("colorNode") && !moves) { console.log(`${name}: left out, for ${[...slots].join(" ")}`); continue }
  if (name === "darthMaul") { console.log(`${name}: left out, a ball's stripes, on a sheet its usual distance leaves only the background`); continue }
  try {
    const page = std.loadFile(`${root}online/${name.replace(/[A-Z]/g, c => "-" + c.toLowerCase())}.html`) ?? ""
    const shown = [...page.matchAll(/gui\.add(Color)?\( params(?:\.(\w+))?, '(\w+)' \)\s*(?:\.min\( (-?[\d.]+) \)\.max\( (-?[\d.]+) \))?(?:\.step\( ([\d.]+) \))?/g)]
    const picks = new Map([...page.matchAll(/gui\.add\( params, '(\w+)', \{([^}]*)\}/g)].map(m => [m[1], [...m[2].matchAll(/:\s*(-?\d+)/g)].map(x => +x[1])]))
    const args: any = {}, fields = new Map<string, string>(), of = new Map<any, string[]>(), lines: [any, string][] = []
    const title = f.defaults.$name ?? name
    for (const [key, value] of Object.entries(f.defaults) as [string, any][]) {
      if (name === "halftone" && /^(attenuation|near|far)$/.test(key)) continue   // (how far from the eye: a sheet has no depth)
      const rows = shown.filter(m => (m[2] ?? m[3]) === key)
      const label = key[0].toUpperCase() + key.slice(1).replace(/([A-Z])/g, " $1")
      if (typeof value === "number" && rows[0]?.[4] !== undefined) {
        const knob = key === "smooth" ? "own_smooth" : key   // (WGSL's reserved word)
        args[key] = uniform(value); fields.set(knob, "f32"); of.set(args[key], [`knobs.${knob}`])
        const [lo, hi] = [+rows[0][4], +rows[0][5]]
        lines.push([args[key], `// --track@${knob}:${label},${lo},${hi},${value},${rows[0][6] ?? (hi - lo) / 100}`])
      } else if (typeof value === "number" && picks.has(key)) {
        args[key] = uniform(value); fields.set(key, "f32"); of.set(args[key], [`knobs.${key}`])
        lines.push([args[key], `// --track@${key}:${label},${Math.min(...picks.get(key)!)},${Math.max(...picks.get(key)!)},${value},1`])
      } else if (typeof value === "boolean" && rows.length) {
        const on = key === "equirectangular" && f.defaults.$replaceExportUVS ? 0 : Number(value)   // (off its ball: no ball to straighten it for)
        args[key] = uniform(on); fields.set(key, "f32"); of.set(args[key], [`knobs.${key}`])
        lines.push([args[key], `// --check@${key}:${label},${on}`])
      } else if (value?.isColor && rows.length) {
        args[key] = uniform(value.clone()); fields.set(key, "vec3<f32>"); of.set(args[key], [0, 1, 2].map(i => `knobs.${key}.${axes[i]}`))
        ;["r", "g", "b"].forEach((c, i) => lines.push([args[key], `// --track@${key}_${axes[i]}:${label} ${c},0,1,${[value.r, value.g, value.b][i]},0.001`]))
      } else if ((value?.isVector2 || value?.isVector3) && rows.length) {
        const n = value.isVector2 ? 2 : 3
        args[key] = uniform(value.clone()); fields.set(key, `vec${n}<f32>`); of.set(args[key], [...axes.slice(0, n)].map(a => `knobs.${key}.${a}`))
        for (const m of rows) lines.push([args[key], `// --track@${key}_${m[3]}:${label} ${m[3]},${m[4] ?? -4},${m[5] ?? 4},${value[m[3]]},${m[6] ?? 0.01}`])
      }
    }
    if (moves) {   // (a points file's sliders are single numbers: a vector's shown parts each one, the others as the author left them)
      const tracks = lines.map(([, line]) => line), has = new Set(tracks.map(l => /@(\w+):/.exec(l)![1]))
      for (const [node, made] of of) of.set(node, made.map((m, i) => { const n = m.replace(/^knobs\.(\w+)\.(\w)$/, "$1_$2").replace(/^knobs\./, ""); return has.has(n) ? `knobs.${n}` : String(parts(node.value)![i]) }))
      const material: any = new THREE.MeshBasicNodeMaterial()
      material.positionNode = f(args)
      const text = pointsText(new THREE.Mesh(new THREE.SphereGeometry(), material), [`// ${title}: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)`, "// --label:3d"], tracks, of)
      std.open(`../../../shelves/effects/geometry/tt_${name.replace(/[A-Z]/g, c => "_" + c.toLowerCase())}_points.wgsl`, "w").puts(text)
      console.log(`${name}: a points file, ${tracks.length} sliders`)
      continue
    }
    if (f.defaults.$replaceExportUVS) args.uvs = uv()   // (the author's own word for a texture taken off its ball)
    const material: any = new THREE.MeshBasicNodeMaterial()
    material.colorNode = f(args)
    const about = new RegExp(`^## .*\\n+(?!<)([^\\n]+)`, "m").exec(pages.find(t => t.includes(`import { ${name} }`)) ?? "")?.[1]
    const head = [`// ${title}: tsl-textures by Pavel Boytchev (MIT, github.com/boytchev/tsl-textures), by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_tsl_textures.ts)`, "// --label:Generate"]
    if (about) head.push(`// --about:${about.trim()}`)
    const made = madeText(material, head, lines, fields, of)
    std.open(`${dir}/tt_${name.replace(/[A-Z]/g, c => "_" + c.toLowerCase())}.wgsl`, "w").puts(made.text)
    console.log(`${name}: ${made.knobs} knobs, ${made.uniforms} uniforms`)
  } catch (e: any) { console.log(`${name}: not made, ${String(e?.message ?? e).slice(0, 140)}`) }
}

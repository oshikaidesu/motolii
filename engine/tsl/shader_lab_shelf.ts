// basementstudio/shader-lab (Apache-2.0): its effects of one pass as files of the effects shelf, the shape screen.h
// screen_read takes. Each is made as shader_lab.ts makes it and turned by three.js's own builder; which uniform is which
// is seen by moving the author's own values (updateParams, resize, beforeRender) and watching which follow, so that no
// effect is wired by hand. A uniform nothing moves stays what the author left it, written into the shader.
import "core-js/actual/url"   // (first: its modules use URL as they load)
import "core-js/actual/structured-clone"
import { getLayerDefinition } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/config/layer-registry"
import { LAYER_CATALOG } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/config/layer-catalog"
import { buildParameterValues } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/parameter-schema"
import { DEFAULT_MASK_CONFIG } from "../third_party/tsl/basementstudio__shader-lab/src/types/editor"
import { PipelineManager } from "../third_party/tsl/basementstudio__shader-lab/packages/shader-lab-react/src/renderer/pipeline-manager"
import { built, renderer } from "./convert"
import * as std from "qjs:std"
import * as os from "qjs:os"

renderer.backend.hasFeature = (f: string) => f === "float32-filterable"   // (the shelf's pictures can be filtered. screen.h frames what is sampled, not what is loaded)

const types = ["chromatic-aberration", "circuit-bent", "directional-blur", "displaced-rings", "displacement-map", "dithering",
  "dot-grid", "edge-detect", "erosion", "fluted-glass", "gradient-map", "gradient", "grain", "halftone", "lumen-print",
  "photographic-cells", "pixelation", "posterize", "relief", "shape", "signal-rot", "slice", "smear", "threshold", "voxel"]   // (the ones whose JS only hands values on: reports/tsl_collection.md)
const taken = new Set(["time", "frame", "aspect", "resolution", "width", "height", "screen", "passindex"])   // (names screen.h fills itself: screen_knobs)
const manager: any = { renderer: null, onRuntimeError: () => {} }
const dir = "../effects"

const same = (a: any, b: number) => typeof a === "number" && Math.abs(a - b) < 1e-5
type Read = { field: string, read: string, type?: string }   // (a knob's name in the struct, and what three's value is made of it)
const uniformsOf = (b: any) => {
  const all: any[] = []
  b.getBindings().forEach((g: any) => g.bindings.forEach((x: any) => { if (x.isUniformsGroup) for (const u of x.uniforms) all.push(u.nodeUniform) }))
  return all
}

// What a uniform left alone is, in WGSL: three's own value as its type says.
function literal(type: string, v: any): string {
  const f = (x: number) => (Number.isInteger(x) ? x.toFixed(1) : String(x))
  if (type === "f32") return `f32(${f(v)})`
  if (type === "i32" || type === "u32") return `${type}(${Math.round(Number(v))})`
  const parts = v.isColor ? [v.r, v.g, v.b] : v.isVector2 ? [v.x, v.y] : v.isVector3 ? [v.x, v.y, v.z] : v.isVector4 ? [v.x, v.y, v.z, v.w] : Array.from(v.elements as number[])
  return `${type}(${parts.map(f).join(", ")})`
}

// three works in linear light, the shelf's effects in sRGB (screen.h screen_tone, whose lines these are): the picture read
// and the colour handed back said again, on colours not premultiplied.
const tones = `fn to_linear(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }
fn to_srgb(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }
fn picture_read(uv: vec2<f32>) -> vec4<f32> { return picture_read_level(uv, 0.0); }
fn picture_read_level(uv: vec2<f32>, level: f32) -> vec4<f32> {
  let p = textureSampleLevel(picture, picture_sampler, uv, level);
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_linear(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}
fn to_shelf(p: vec4<f32>) -> vec4<f32> {
  if (p.a <= 0.0) { return vec4<f32>(0.0); }
  return vec4<f32>(to_srgb(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);
}
`

// three's fragment shader as screen.h reads a file: one picture and its sampler, one struct of knobs, an entry with a uv
// from the top left (three's from the bottom).
function fileText(frag: string, head: string[], said: Map<string, Read>, uniforms: any[]): string {
  const fields = new Map<string, string>([["time", "f32"]]), reads: [RegExp, string][] = []   // (the knobs by name, and what each of three's reads becomes)
  let body = frag.replace(/@binding\( \d+ \) @group\( \d+ \) var (\w+) : (texture_2d<f32>|sampler);\n/g, (_, name, type) => {
    reads.push([new RegExp(`\\b${name}\\b`, "g"), type === "sampler" ? "picture_sampler" : "picture"])
    return ""
  })
  body = body.replace(/struct (\w+) \{\n([\s\S]*?)\n\};\n@binding\( \d+ \) @group\( \d+ \)\nvar<uniform> (\w+) : \1;\n/g, (_, _s, list: string, block: string) => {
    for (const line of list.split("\n")) {
      const [name, type] = line.replace(/[\s,]/g, "").split(":"), knob = said.get(name)
      if (!frag.includes(`${block}.${name}`)) continue   // (the vertex shader's alone)
      if (knob) fields.set(knob.field, knob.type ?? type)
      const value = knob ? (type === "f32" || knob.read === `knobs.${knob.field}` ? knob.read : `${type}(${knob.read})`) : literal(type, uniforms.find(x => x.name === name).node.value)
      reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), value])
    }
    return ""
  })
  for (const [from, to] of reads) body = body.replace(from, to)
  const given = `struct Knobs {\n${[...fields].map(([n, t]) => `  ${n}: ${t},`).join("\n")}\n};\n@group(0) @binding(0) var picture: texture_2d<f32>;\n@group(0) @binding(1) var picture_sampler: sampler;\n@group(0) @binding(2) var<uniform> knobs: Knobs;\n`
  body = body.replace("// uniforms\n", `// uniforms\n${given}${tones}`).replace(/textureSample\( picture, picture_sampler, /g, "picture_read( ").replace(/textureSampleLevel\( picture, picture_sampler, /g, "picture_read_level( ")
  body = body.replace(/return output;/g, "output.color = to_shelf(output.color);\n\treturn output;")
  body = body.replace(/fn main\( @location\( 0 \) (\w+) : vec2<f32> \) -> OutputStruct \{/, (_, uv) => `fn main(@location(0) door_uv: vec2<f32>) -> OutputStruct {\n\tlet ${uv} = vec2<f32>(door_uv.x, 1.0 - door_uv.y);`)
  return head.join("\n") + "\n" + body
}

for (const type of types) try {
  const definition = getLayerDefinition(type as any), about = LAYER_CATALOG[type as keyof typeof LAYER_CATALOG]
  const params = buildParameterValues(definition.params)
  const layer = { assetId: null, blendMode: "normal", compositeMode: "filter", hue: 0, id: type, kind: definition.kind,
    maskConfig: { ...DEFAULT_MASK_CONFIG }, opacity: 1, params, saturation: 1, type, visible: true, mask: null }
  const pass: any = PipelineManager.prototype["createPass" as keyof PipelineManager].call(manager, layer)
  ;(PipelineManager.prototype as any).applyLayerState.call(manager, pass, layer)
  pass.resize?.(1920, 1080); pass.updateLogicalSize?.(1920, 1080)
  const mesh = pass.compositeMesh, own: string[] = []
  built(mesh, mesh.material, pass.camera, pass.scene).getBindings().forEach((g: any) => g.bindings.forEach((x: any) => {
    if (!x.isSampledTexture) return
    x.texture.minFilter = x.texture.magFilter = 1006   // (the author's nearest pictures, THREE.LinearFilter: three would load them)
    if (x.texture.isDataTexture || x.texture.image) own.push(x.name)   // (a picture it makes itself: the shelf's file has only the one it is given)
  }))
  if (own.length) { console.log(`${type}: not yet, reads ${own.length} pictures of its own`); continue }
  const b = built(mesh, mesh.material, pass.camera, pass.scene), uniforms = uniformsOf(b), said = new Map<string, Read>()
  // (the uniforms that go along with three values of the author's, and how: a v + b, as degrees go to radians)
  const along = (values: number[], move: (v: number) => void) => {
    const seen = values.map(v => (move(v), uniforms.map(u => u.node.value)))
    pass.updateParams(params)
    const found = new Map<string, [number, number]>()
    uniforms.forEach((u, k) => {
      const [p, q, r] = seen.map(s => s[k])
      if (typeof p !== "number" || typeof q !== "number" || typeof r !== "number" || p === q) return
      const a = (q - p) / (values[1] - values[0]), c = p - a * values[0]
      if (Math.abs(a * values[2] + c - r) < 1e-4 * Math.max(1, Math.abs(r))) found.set(u.name, [a, c])
    })
    return found
  }
  const wired = (found: Map<string, [number, number]>, field: string, to = `knobs.${field}`) => {
    for (const [name, [a, c]] of found) said.set(name, { field: field.split(".")[0], type: to.includes("resolution") ? "vec2<f32>" : undefined,
      read: same(a, 1) && same(c, 0) ? to : `(${a} * ${to} + ${c})` })
    return found.size
  }
  const set = (key: string) => (v: any) => pass.updateParams({ ...params, [key]: v })
  const lines = [`// ${about.label}: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)`,
    `// --label:${about.category === "distort" ? "Distort" : "Stylize"}`]
  if (about.description) lines.push(`// --about:${about.description}`)
  const left: string[] = []
  for (const p of definition.params as any[]) {
    const knob = (taken.has(p.key) ? "own_" : "") + p.key.replace(/\W/g, "_"), label = p.label.replace(/,/g, "")
    let got = 0
    if (p.type === "number") {
      const low = p.min ?? 0, high = p.max ?? 1, on = (x: number) => p.step ? low + Math.round((low + (high - low) * x - low) / p.step) * p.step : low + (high - low) * x
      got = wired(along([on(.25), on(.5), on(.75)], v => set(p.key)(v)), knob)
      if (got) lines.push(`// --track@${knob}:${label},${low},${high},${p.defaultValue},${p.step ?? (high - low) / 100}`)
    } else if (p.type === "select" && p.options.length > 2) {   // (as isf.cpp takes an ISF long: a whole number)
      got = wired(along([0, 1, 2], i => set(p.key)(p.options[i].value)), knob)
      if (got) lines.push(`// --track@${knob}:${label},0,${p.options.length - 1},${p.options.findIndex((o: any) => o.value === p.defaultValue)},1`)
    } else if (p.type === "boolean" || p.type === "select") {
      const of = (v: number) => p.type === "boolean" ? !!v : p.options[v].value
      for (const u of uniforms) {
        const off = (set(p.key)(of(0)), u.node.value), on = (set(p.key)(of(1)), u.node.value)
        const number = (x: any) => typeof x === "boolean" ? Number(x) : x
        if (typeof number(off) === "number" && number(off) !== number(on)) { said.set(u.name, { field: knob, read: `(${number(on) - number(off)} * knobs.${knob} + ${number(off)})` }); got++ }
      }
      pass.updateParams(params)
      if (got) lines.push(`// --check@${knob}:${label},${of(1) === p.defaultValue ? 1 : 0}`)
    } else if (p.type === "color") {   // (as isf.cpp takes an ISF color: a number for each of its parts)
      for (const u of uniforms) {
        const v = u.node.value
        if (!v?.isColor) continue
        const red = (set(p.key)("#ff0000"), same(v.r, 1) && same(v.g, 0)), green = (set(p.key)("#00ff00"), same(v.r, 0) && same(v.g, 1))
        pass.updateParams(params)
        if (red && green) { said.set(u.name, { field: knob, read: `knobs.${knob}` }); got++; ["r", "g", "b"].forEach((part, i) => lines.push(`// --track@${knob}_${"xyz"[i]}:${label} ${part},0,1,${v[part]},0.001`)) }
      }
    }
    if (!got) left.push(p.key)
  }
  wired(along([1, 2, 3], v => { try { pass.beforeRender(v, 1) } catch {} }), "time")
  const sized = (w: number, h: number) => { pass.resize?.(w, h); pass.updateLogicalSize?.(w, h) }
  wired(along([900, 1100, 1300], w => sized(w, 1080)), "resolution", "knobs.resolution.x")
  wired(along([700, 900, 1000], h => sized(1920, h)), "resolution", "knobs.resolution.y")
  sized(1920, 1080)
  const file = `${dir}/sl_${type.replace(/-/g, "_")}.wgsl`
  std.open(file, "w").puts(fileText(b.fragmentShader, lines, said, uniforms))
  console.log(`${type}: ${said.size} of ${uniforms.length} uniforms moved${left.length ? `, left as they are: ${left.join(" ")}` : ""}`)
} catch (e: any) { console.log(`${type}: not made, ${String(e?.message ?? e).slice(0, 120)}`) }

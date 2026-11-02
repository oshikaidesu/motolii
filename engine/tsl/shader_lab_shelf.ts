// basementstudio/shader-lab (Apache-2.0): its effects as files of the effects shelf. Each is made as shader_lab.ts makes it
// and its own render() run once with a renderer that only writes down what it is told: which material, into which picture,
// with which values (the steps of ISF's PASSES, as Dawn's capture showed them: reports/tsl_collection.md). Which uniform is
// which knob is seen by moving the author's own values and watching which follow, so that no effect is wired by hand. A
// uniform nothing moves stays what the author left it, written into the shader; three.js is not there when it plays.
import "core-js/actual/url"   // (first: its modules use URL as they load)
import "core-js/actual/structured-clone"
import * as THREE from "three/webgpu"
import { getLayerDefinition } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/config/layer-registry"
import { LAYER_CATALOG } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/config/layer-catalog"
import { buildParameterValues } from "../third_party/tsl/basementstudio__shader-lab/src/lib/editor/parameter-schema"
import { DEFAULT_MASK_CONFIG } from "../third_party/tsl/basementstudio__shader-lab/src/types/editor"
import { PipelineManager } from "../third_party/tsl/basementstudio__shader-lab/packages/shader-lab-react/src/renderer/pipeline-manager"
import { BlurPyramid } from "../third_party/tsl/basementstudio__shader-lab/packages/shader-lab-react/src/renderer/blur-pyramid"
import { renderer } from "./convert"
import { fileText, parts, stepOf, type Said, type Step, type Target } from "./shelf_file"
import * as std from "qjs:std"

renderer.backend.hasFeature = (f: string) => f === "float32-filterable"   // (the shelf's pictures can be filtered. screen.h frames what is sampled, not what is loaded)
BlurPyramid.prototype.needsLevels = () => true   // (drawn always: whether its levels are read is a knob's to say, as the file plays)

const only = scriptArgs.slice(1)
const types = only.length ? only : ["bloom", "chromatic-aberration", "circuit-bent", "connected-dots", "crt", "directional-blur", "displaced-rings", "displacement-map", "dithering",
  "dot-grid", "edge-detect", "erosion", "flares", "fluted-glass", "focus-blur", "glass", "gradient-map", "gradient", "halftone", "ink", "lumen-print", "outline",
  "particle-grid", "pattern:bars", "pattern:candles", "pattern:shapes", "photocopy", "photographic-cells", "pixel-sorting", "pixelation", "plotter", "posterize", "relief", "shape", "signal-rot", "slice", "smear", "threshold", "voxel"]
const taken = new Set(["time", "frame", "aspect", "resolution", "width", "height", "screen", "passindex", "frameRect", "passRect"])   // (names screen.h fills itself: screen_knobs)
const manager: any = { renderer: null, onRuntimeError: () => {} }
const dir = "../effects", W = 2048, H = 1024   // (each level of a pyramid an exact share of it)

// a x + c through what was seen, or none.
function fit(xs: number[], ys: number[]): [number, number] | null {
  const far = xs.findIndex(x => Math.abs(x - xs[0]) > 1e-9)
  if (far < 0) return null
  const a = (ys[far] - ys[0]) / (xs[far] - xs[0]), c = ys[0] - a * xs[0], reach = Math.max(...ys) - Math.min(...ys)
  return reach > 0 && xs.every((x, i) => Math.abs(a * x + c - ys[i]) <= 1e-3 * reach) ? [a, c] : null
}
const same = (a: number, b: number) => Math.abs(a - b) < 1e-5
// What the author's render() does, told to a renderer that does nothing else (each step: step, each copy: copied).
function drawn(pass: any, input: any, output: any, time: number, step: (scene: any, camera: any, target: any) => void, copied: (from: any, to: any) => void) {
  let target: any = null
  const told: any = { setRenderTarget: (t: any) => { target = t }, getRenderTarget: () => target, render: (scene: any, camera: any) => step(scene, camera, target),
    copyTextureToTexture: copied, compute: () => { throw new Error("it computes with the GPU") } }
  pass.setInputChanged?.(true)
  pass.render(new Proxy({}, { get: (_, k) => told[k as string] ?? (() => {}) }), input, output, time, 1 / 60)
  pass.lastRenderer = null   // (a value moved later is not to be compiled on it)
}

// What buildPatternAtlas draws on its canvas and how it turns that to a mask (pattern-atlas.ts), its SVGs drawn by librsvg.
function atlas(preset: string, cell = 16): any {
  const from = `../third_party/tsl/basementstudio__shader-lab/public/assets/patterns/${preset}`, raw = "out/atlas.rgba"
  const files = (std.popen(`ls ${from}`, "r").readAsString() ?? "").split("\n").filter(f => f.endsWith(".svg"))
  const data = new Uint8Array(files.length * cell * cell * 4), one = new Uint8Array(cell * cell * 4)
  files.forEach((f, i) => {
    std.popen(`rsvg-convert -w ${cell} -h ${cell} ${from}/${f} | magick png:- -depth 8 rgba:${raw}`, "r").readAsString()
    const got = std.open(raw, "rb"); got.read(one.buffer, 0, one.length); got.close()
    for (let y = 0; y < cell; y++) for (let x = 0; x < cell; x++) {
      const p = (y * cell + x) * 4, on = one[p + 3] > 0 && Math.max(one[p], one[p + 1], one[p + 2]) > 32 ? 255 : 0, q = (y * files.length * cell + i * cell + x) * 4
      data.set([on, on, on, 255], q)
    }
  })
  return new THREE.DataTexture(data, files.length * cell, cell)
}

for (const word of types) try {
  const [type, preset] = word.split(":")
  const definition = getLayerDefinition(type as any), about = LAYER_CATALOG[type as keyof typeof LAYER_CATALOG]
  const params = buildParameterValues(definition.params)
  if (preset) params.preset = preset
  const layer = { assetId: null, blendMode: "normal", compositeMode: "filter", hue: 0, id: type, kind: definition.kind,
    maskConfig: { ...DEFAULT_MASK_CONFIG }, opacity: 1, params, saturation: 1, type, visible: true, mask: null }
  const pass: any = PipelineManager.prototype["createPass" as keyof PipelineManager].call(manager, layer)
  ;(PipelineManager.prototype as any).applyLayerState.call(manager, pass, layer)
  if (type === "plotter") pass.isStipple = () => true   // (drawn always, as the pyramid: which of its modes reads it is a knob's to say)
  if (preset) { pass.atlasTexture = atlas(preset); pass.numPatternsUniform.value = pass.atlasTexture.image.width / 16; pass.atlasPending = false; pass.rebuildEffectNode() }
  const output = new THREE.RenderTarget(W, H, { type: THREE.HalfFloatType }), input = new THREE.Texture()
  const sized = (w: number, h: number) => { output.setSize(w, h); pass.resize?.(w, h); pass.updateLogicalSize?.(w, h) }
  sized(W, H)
  // Pictures that are one: the two of a pair turned round each frame, and a picture copied whole to another.
  const joined = new Map<any, any>(), root = (t: any): any => joined.has(t) ? root(joined.get(t)) : t
  const join = (a: any, b: any) => { a = root(a); b = root(b); if (a !== b) joined.set(a, b) }
  const made = new Map<any, any>()
  const frame = (time: number) => {
    const steps: Step[] = []
    drawn(pass, input, output, time, (scene, camera, target) => {
      const mesh = scene.children.find((c: any) => c.isMesh)
      if (scene.children.length !== 1 || mesh?.geometry?.type !== "PlaneGeometry") throw new Error("it draws more than a sheet")
      steps.push(stepOf(made, mesh, camera, scene, target?.texture ?? null))
    }, join)
    return steps
  }
  frame(0); frame(1 / 60)   // (the first frames of a kept picture are made another way: crt-pass.ts historyPrimedFrames)
  const one = frame(2 / 60), steps = frame(3 / 60)
  one.forEach((s, k) => {
    if (s.target && steps[k]?.target && s.target !== steps[k].target) join(s.target, steps[k].target)
    s.pictures.forEach(([, t], p) => { const o = steps[k]?.pictures[p]?.[1]; if (t?.isRenderTargetTexture && o?.isRenderTargetTexture && t !== o) join(t, o) })
  })
  const out = root(output.texture), names = new Map<any, string>(), targets: Target[] = [], written = new Set<any>()
  const reading = steps.some(s => s.pictures.some(([, t]) => t?.isRenderTargetTexture && root(t) === out))   // (what it showed is read again: crt-pass.ts captureHistory)
  const nameOf = (t: any) => t?.isRenderTargetTexture ? names.get(root(t)) ?? "none" : t?.isDataTexture ? "own" : "picture"
  const drawnTo = new Set(steps.map(s => root(s.target ?? output.texture)))
  const passes: string[] = []
  const add = (t: any, kept: boolean) => {   // (read before it is drawn: it is the frame before's)
    if (names.has(t)) return
    names.set(t, `t${targets.length}`)
    targets.push({ name: `t${targets.length}`, kept, fine: t.type !== THREE.UnsignedByteType, share: [t.image.width / W, t.image.height / H], points: [0, 0] })
  }
  for (const s of steps) {
    for (const [, t] of s.pictures)
      if (t?.isRenderTargetTexture && root(t) !== out && !written.has(root(t)) && drawnTo.has(root(t))) add(root(t), true)
    const t = root(s.target ?? output.texture)
    if (t === out && !reading) { s.target = null; continue }
    add(t, t === out)
    written.add(t)
  }
  const tail = reading ? nameOf(output.texture) : null
  // A picture whose size goes with a knob (a cell of it for each dot: connected-dots-pass.ts syncSiteGrid) as large as that
  // knob ever asks, a little over since its margin is in cells; what says its size then says the picture's own.
  const grew = new Map<string, any>()
  for (const p of definition.params as any[]) if (p.type === "number") for (const v of [p.min ?? 0, p.max ?? 1]) {
    pass.updateParams({ ...params, [p.key]: v })
    for (const [t, name] of names) {
      const x = targets.find(y => y.name === name)!, w = t.image.width / W, h = t.image.height / H
      if (w > x.share[0] || h > x.share[1]) { x.share = [Math.max(w, x.share[0]), Math.max(h, x.share[1])]; grew.set(name, t) }
    }
  }
  pass.updateParams(params)
  for (const name of grew.keys()) { const x = targets.find(y => y.name === name)!; x.share = [x.share[0] * 1.1, x.share[1] * 1.1] }

  const entries = (each: (step: number, name: string, part: number, v: number) => void) => steps.forEach((s, k) => s.uniforms.forEach((u, j) => parts(s.values[j])?.forEach((v, i) => each(k, u.name, i, v))))
  const flat = () => {   // (every number of every step, now)
    const all: number[] = []
    let k = 0
    drawn(pass, input, output, 0, () => { const s = steps[k++]; if (s) for (const u of s.uniforms) all.push(...(parts(u.node.value) ?? [NaN])) }, () => {})
    return k === steps.length ? all : null
  }
  const shape = steps.flatMap((s, k) => s.uniforms.flatMap((u, j) => (parts(s.values[j]) ?? [NaN]).map((_, i) => [k, u.name, i] as [number, string, number])))
  const said: Said = new Map(), fields = new Map<string, string>()
  const wire = (at: [number, string, number], a: number, c: number, to: string) => {
    const key = `${at[0]}:${at[1]}`
    if (!said.has(key)) said.set(key, [])
    said.get(key)![at[2]] = same(a, 1) && same(c, 0) ? to : `(${a} * ${to} + ${c})`
  }
  // (the uniforms that go along with some of the author's values, and how: a v + c, as degrees go to radians)
  // (a list's numbers may be in an order of their own, MODES in plotter-pass.ts: then its own numbers, by position)
  const along = (values: number[], move: (v: number) => void, to: string, list = false) => {
    const seen = values.map(v => (move(v), flat()))
    pass.updateParams(params)
    if (seen.some(s => !s)) return 0
    let got = 0
    shape.forEach((at, n) => {
      const ys = seen.map(s => s![n]), line = fit(values, ys)
      if (line) { wire(at, line[0], line[1], to); got++ }
      else if (list && new Set(ys).size > 1) { wire(at, 1, 0, `array<f32, ${ys.length}>(${ys.map(y => Number.isInteger(y) ? y.toFixed(1) : y).join(", ")})[u32(${to})]`); got++ }
    })
    return got
  }
  const set = (key: string) => (v: any) => pass.updateParams({ ...params, [key]: v })
  const lines = [`// ${about.label}${preset ? ` ${preset[0].toUpperCase() + preset.slice(1)}` : ""}: Shader Lab's (Apache-2.0, Copyright 2026 basement.studio LLC, github.com/basementstudio/shader-lab), by three.js's own builder (engine/tsl/shader_lab_shelf.ts)`,
    `// --label:${about.category === "distort" ? "Distort" : "Stylize"}`]
  if (about.description) lines.push(`// --about:${about.description}`)
  for (const s of steps) { const t = targets.find(x => x.name === nameOf(s.target)); passes.push(`// --pass@${s.target ? t!.name : ""}:${t?.kept ? 1 : 0},${t?.fine ? 1 : 0},s${t?.share[0] ?? 1},s${t?.share[1] ?? 1}`) }
  if (tail) passes.push("// --pass@:0,0,s1,s1")
  if (passes.length > 1) lines.push(...passes)
  const left: string[] = []
  for (const p of definition.params as any[]) {
    const knob = (taken.has(p.key) ? "own_" : "") + p.key.replace(/\W/g, "_"), label = p.label.replace(/,/g, "")
    let got = 0
    if (p.type === "number") {
      const low = p.min ?? 0, high = p.max ?? 1, on = (x: number) => p.step ? low + Math.round((high - low) * x / p.step) * p.step : low + (high - low) * x
      got = along([on(.25), on(.5), on(.75)], v => set(p.key)(v), `knobs.${knob}`)
      if (got) { fields.set(knob, "f32"); lines.push(`// --track@${knob}:${label},${low},${high},${p.defaultValue},${p.step ?? (high - low) / 100}`) }
    } else if (p.type === "select" && p.options.length > 2) {   // (as isf.cpp takes an ISF long: a whole number)
      got = along(p.options.map((_: any, i: number) => i), i => set(p.key)(p.options[i].value), `knobs.${knob}`, true)
      if (got) { fields.set(knob, "f32"); lines.push(`// --track@${knob}:${label},0,${p.options.length - 1},${p.options.findIndex((o: any) => o.value === p.defaultValue)},1`) }
    } else if (p.type === "boolean" || p.type === "select") {
      const of = (v: number) => p.type === "boolean" ? !!v : p.options[v].value
      got = along([0, 1], v => set(p.key)(of(v)), `knobs.${knob}`)
      if (got) { fields.set(knob, "f32"); lines.push(`// --check@${knob}:${label},${of(1) === p.defaultValue ? 1 : 0}`) }
    } else if (p.type === "color") {   // (as isf.cpp takes an ISF color: a number for each of its parts)
      const seen = ["#ff0000", "#00ff00", "#0000ff"].map(c => (set(p.key)(c), flat()))
      pass.updateParams(params)
      const base = flat()
      const usual: number[] = []   // (each part where it is: the parts of one uniform, or a uniform each as halftone-pass.ts has them)
      if (seen.every(s => s) && base) shape.forEach((at, n) => {
        const [r, g, b] = seen.map(s => s![n]), i = [r, g, b].findIndex(v => same(v, 1))
        if (i >= 0 && [r, g, b].filter(v => same(v, 0)).length === 2) { wire(at, 1, 0, `knobs.${knob}.${"xyz"[i]}`); usual[i] = base[n]; got++ }
      })
      if (got) {
        fields.set(knob, "vec3<f32>")
        ;["r", "g", "b"].forEach((part, i) => lines.push(`// --track@${knob}_${"xyz"[i]}:${label} ${part},0,1,${usual[i]},0.001`))
      }
    }
    if (!got) left.push(p.key)
  }
  const flatAt = (time: number) => { const all: number[] = []; let k = 0; drawn(pass, input, output, time, () => { const s = steps[k++]; if (s) for (const u of s.uniforms) all.push(...(parts(u.node.value) ?? [NaN])) }, () => {}); return all }
  const times = [1, 2, 3].map(flatAt)
  shape.forEach((at, n) => { const line = fit([1, 2, 3], times.map(s => s[n])); if (line) wire(at, line[0], line[1], "knobs.time") })
  // (what goes with the size it plays at: the stage's in `S`, shelf_file.ts turning that into a step's own)
  const sizes = [[W, H], [W * 1.5, H], [W * 2, H], [W, H * 1.5], [W, H * 2]]
  const seen = sizes.map(([w, h]) => (sized(w, h), flat()))
  const owns = sizes.map(([w, h]) => (sized(w, h), new Map([...grew].map(([name, t]) => [name, [t.image.width, t.image.height]]))))
  sized(W, H)
  if (seen.every(s => s)) {
    const forms: [string, (w: number, h: number) => number][] = [["S.x", w => w], ["S.y", (_, h) => h], ["(1.0 / S.x)", w => 1 / w], ["(1.0 / S.y)", (_, h) => 1 / h], ["(S.x / S.y)", (w, h) => w / h], ["(S.y / S.x)", (w, h) => h / w]]
    shape.forEach((at, n) => {
      const ys = seen.map(s => s![n]), own = nameOf(steps[at[0]].target)
      if (grew.has(own) && at[2] < 2 && ys.every((y, i) => same(y, owns[i].get(own)![at[2]]))) return wire(at, 1, 0, `knobs.resolution.${"xy"[at[2]]}`)
      if (said.get(`${at[0]}:${at[1]}`)?.[at[2]] || ys.some(y => Number.isNaN(y))) return
      for (const [form, of] of forms) { const line = fit(sizes.map(([w, h]) => of(w, h)), ys); if (line) { wire(at, line[0], line[1], form); break } }
    })
  }
  const file = `${dir}/sl_${word.replace(/\W/g, "_")}.wgsl`
  std.open(file, "w").puts(fileText(lines, steps, said, fields, targets, nameOf, tail))
  console.log(`${word}: ${steps.length} steps, ${targets.length} pictures, ${said.size} uniforms moved${left.length ? `, left as they are: ${left.join(" ")}` : ""}`)
} catch (e: any) { console.log(`${word}: not made, ${String(e?.message ?? e).slice(0, 140)}`, std.getenv("TRACE") ? e?.stack : "") }

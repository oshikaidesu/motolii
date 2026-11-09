// Two small collections as files of the effects shelf, each making its own picture. bandinopla/threejs-noise-functions (MIT),
// the noises that are more than cells of random numbers, as its README shows one: `colorNode: gabor12( uv().mul(6.0).add(
// time.sin()) )` (README.md:33), on a sheet as wide as what it fills; the two numbers of that line are its knobs.
// verekia/tslfx (MIT), its bursts, as its pages play them: `uniforms.time.value += delta / duration`, back to 0 past 1
// (src/pages/primitive/scatter.tsx:111-115), the first preset as the usual and the pages' spans.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import { positionGeometry, time, uniform } from "three/tsl"
import * as N from "../../third_party/tsl/bandinopla__threejs-noise-functions/src/index"
import { impact, scatter } from "../../third_party/tsl/verekia__tslfx/src/shaders/index"
import { madeText } from "./write_shelf_file"

const dir = "../../../shelves/effects/generate"   // (its --label:Generate)
const write = (file: string, title: string, by: string, material: any, lines: [any, string][], fields: Map<string, string>, of: Map<any, string[]>) => {
  const made = madeText(material, [`// ${title}: ${by}, by three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_noise_and_tslfx.ts)`, "// --label:Generate"], lines, fields, of)
  std.open(`${dir}/${file}.wgsl`, "w").puts(made.text)
  console.log(`${file}: ${made.knobs} knobs, ${made.uniforms} uniforms`)
}

const noises: [string, string][] = [["crater12", "Crater"], ["curl22", "Curl"], ["erosion12", "Erosion"], ["gabor12", "Gabor"], ["paper12", "Paper"],
  ["scratches12", "Scratches"], ["stone12", "Stone"], ["wavelet12", "Wavelet"], ["wool12", "Wool"]]
for (const [name, title] of noises) {
  const scale = uniform(6), pace = uniform(1), material: any = new THREE.MeshBasicNodeMaterial()
  material.colorNode = (N as any)[name](positionGeometry.xy.add(3).mul(scale.div(2)).add(time.mul(pace).sin().add(1)))   // (above zero as uv() is: Gabor is flat below it)
  const lines: [any, string][] = [[scale, "// --track@scale:Scale,0,24,6,0.1"], [pace, "// --track@pace:Pace,0,4,1,0.01"]]
  write(`nf_${title.toLowerCase()}`, `${title} noise`, "threejs-noise-functions by lumiey (MIT, github.com/bandinopla/threejs-noise-functions)", material, lines,
    new Map([["scale", "f32"], ["pace", "f32"]]), new Map([[scale, ["knobs.scale"]], [pace, ["knobs.pace"]]]))
}

const wide = "knobs.resolution.x / knobs.resolution.y"
const colour = (key: string, label: string, v: THREE.Vector4) => ["r", "g", "b"].map((c, i) => `// --track@${key}_${"xyz"[i]}:${label} ${c},0,1,${[v.x, v.y, v.z][i]},0.001`)
const burst = (file: string, title: string, f: any, usual: any, spans: [string, string, number, number, number][], colours: [string, string][]) => {
  const { uniforms: u, nodes } = f(usual), material: any = new THREE.MeshBasicNodeMaterial()
  material.colorNode = nodes.colorNode
  const fields = new Map([["duration", "f32"]]), of = new Map<any, string[]>([[u.aspect, [wide]], [u.time, ["fract(knobs.time / max(knobs.duration, 0.001))"]]])
  const lines: [any, string][] = [[u.time, `// --track@duration:Duration,0.1,3,${usual.duration},0.1`]]
  for (const [key, label, lo, hi, step] of spans) { fields.set(key, "f32"); of.set(u[key], [`knobs.${key}`]); lines.push([u[key], `// --track@${key}:${label},${lo},${hi},${usual[key]},${step}`]) }
  for (const [key, label] of colours) { fields.set(key, "vec3<f32>"); of.set(u[key], [0, 1, 2].map(i => `knobs.${key}.${"xyz"[i]}`)); for (const line of colour(key, label, usual[key])) lines.push([u[key], line]) }
  write(file, title, "TSLFX by Verekia (MIT, github.com/verekia/tslfx)", material, lines, fields, of)
}
burst("tf_impact", "Impact", impact, { circleColor: new THREE.Vector4(1, 0.1, 0, 1), vesicaColor: new THREE.Vector4(1, 0.6, 0, 1), vesicaCount: 6, duration: 0.5, circleSizeStart: 0, circleSizeEnd: 0.6, circleThickness: 0.13 },
  [["vesicaCount", "Vesica Count", 0, 15, 1], ["circleSizeStart", "Circle Size Start", 0, 1, 0.01], ["circleSizeEnd", "Circle Size End", 0, 1, 0.01], ["circleThickness", "Circle Thickness", 0, 1, 0.01]],
  [["circleColor", "Circle Color"], ["vesicaColor", "Vesica Color"]])
burst("tf_scatter", "Scatter", scatter, { vesicaColor: new THREE.Vector4(1, 0.6, 0, 1), vesicaCount: 6, duration: 0.5, radiusStart: 0, radiusEnd: 1 },
  [["vesicaCount", "Vesica Count", 0, 15, 1], ["radiusStart", "Radius Start", 0, 1, 0.01], ["radiusEnd", "Radius End", 0, 1, 0.01]],
  [["vesicaColor", "Vesica Color"]])

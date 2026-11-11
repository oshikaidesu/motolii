// TypeGPU's own three.js examples (software-mansion/TypeGPU, MIT) as files of the effects shelf: JavaScript functions marked
// 'use gpu', made TSL nodes by @typegpu/three's toTSL as each example does it (apps/typegpu-docs/src/examples/threejs/
// simple/index.ts:18 `material.colorNode = t3.toTSL(() => {`), then WGSL by three.js's own builder. An example is a page's
// script: it is run whole, unchanged, with the page's things it asks for stood in below, and the material of the mesh it
// draws is what is written. Its numbers are the author's; it has no uniforms of its own, so no knobs.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import { time } from "three/tsl"
import { built } from "./convert"
import { madeText, parts, uniformsOf } from "./write_shelf_file"

const dir = "../../../shelves/effects/generate"   // (its --label:Generate)
const g: any = globalThis
let drawn: any
g.window = g; g.devicePixelRatio = 1
g.document = { querySelector: () => ({ getContext: () => null, style: {}, addEventListener() {}, clientWidth: 1, clientHeight: 1 }) }
g.ResizeObserver = class { observe() {} disconnect() {} }
const R: any = THREE.WebGPURenderer.prototype   // (no GPU here: the page's renderer only says what it would draw)
R.init = async function () {}; R.setPixelRatio = R.setSize = function () {}
R.setAnimationLoop = async function (frame: any) { frame?.(0) }
R.render = function (scene: any) { drawn = scene }

// A material that moves its mesh's points (positionNode), as a compute shader of the shape stage/layer_effects/layer_fx.h
// thing_fx_points runs: three's own vertex shader for the author's mesh, kept as its builder wrote it, its entry made a
// function that is given a point and returns positionLocal, where three has the moved point before its camera. Its
// uniforms are said as they stand; time is the file's time. The normals are the shape's own: this material gives none.
function pointsText(mesh: any, head: string[]): string {
  const b = built(mesh, mesh.material), uniforms = uniformsOf(b)
  let body: string = b.vertexShader.slice(b.vertexShader.indexOf("// structs"))
  const reads: [RegExp, string][] = []
  body = body.replace(/struct (\w+) \{\n([\s\S]*?)\n\};\n@binding\( \d+ \) @group\( \d+ \)\nvar<uniform> (\w+) : \1;\n/g, (_, _s, list: string, block: string) => {
    for (const line of list.split("\n")) {
      const [name, type] = line.replace(/[\s,]/g, "").split(":")
      const u = uniforms.find((x: any) => x.name === name), v = u?.node?.value
      const numbers = u?.node === time ? null : parts(v) ?? (v?.elements ? Array.from(v.elements as number[]) : type === "mat4x4<f32>" ? [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1] : [0])
      reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), numbers ? `${type}(${numbers.map(x => Number.isInteger(x) ? x.toFixed(1) : String(x)).join(", ")})` : "knobs.time"])
    }
    return ""
  })
  for (const [from, to] of reads) body = body.replace(from, to)
  const entry = /@vertex\s*fn main\( ([\s\S]*?) \) -> VaryingsStruct \{/.exec(body)
  if (!entry) throw new Error("no vertex entry")
  const given = entry[1].split(",").map(x => /(\w+) : ([\w<>]+)/.exec(x)!).map(([, name, type]) => {
    if (name === "position") return "vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u])"
    if (name === "uv") return "vec2f(shape_uvs[2u * i], shape_uvs[2u * i + 1u])"
    throw new Error(`reads the shape's ${name} (${type}), which a points file is not given yet`)
  })
  body = body.replace(entry[0], `fn point_moved( ${entry[1].replace(/@location\( \d+ \) /g, "")} ) -> vec3<f32> {`).replace(/return varyings;/, "return positionLocal;")
  return [...head, `struct Knobs {\n  time: f32,\n};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
`, body, `@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&points) || 3u * i + 2u >= arrayLength(&shape_points) || 2u * i + 1u >= arrayLength(&shape_uvs)) { return; }
  let p = point_moved(${given.join(", ")});
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
}
`].join("\n")
}

const examples: [string, string, () => Promise<any>][] = [
  ["tg_simple", "Perlin Noise", () => import("../../third_party/tsl/software-mansion__TypeGPU/apps/typegpu-docs/src/examples/threejs/simple/index")],
]
for (const [file, title, run] of examples) {
  drawn = undefined
  await run()
  let mesh: any
  drawn.traverse((o: any) => { if (o.isMesh) mesh ??= o })
  const material = mesh.material, by = `TypeGPU's "Three.js - Simple" example by Software Mansion (MIT, github.com/software-mansion/TypeGPU), by TypeGPU's toTSL and three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_typegpu.ts)`
  if (material.positionNode) {
    std.open(`../../../shelves/effects/geometry/${file}_points.wgsl`, "w").puts(pointsText(mesh, [`// ${title} Wobble: the points of a solid moved by noise. ${by}`, "// --label:3d"]))
    console.log(`${file}_points: made`)
  }
  const sheet: any = new THREE.MeshBasicNodeMaterial()
  sheet.colorNode = material.colorNode
  const made = madeText(sheet, [`// ${title}: ${by}`, "// --label:Generate",
    "// --about:Uses TypeGPU shader functions and procedural noise inside a minimal Three.js WebGPU material."], [], new Map(), new Map())
  std.open(`${dir}/${file}.wgsl`, "w").puts(made.text)
  console.log(`${file}: ${made.knobs} knobs, ${made.uniforms} uniforms`)
}

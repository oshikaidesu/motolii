// TypeGPU's own three.js examples (software-mansion/TypeGPU, MIT) as files of the effects shelf: JavaScript functions marked
// 'use gpu', made TSL nodes by @typegpu/three's toTSL as each example does it (apps/typegpu-docs/src/examples/threejs/
// simple/index.ts:18 `material.colorNode = t3.toTSL(() => {`), then WGSL by three.js's own builder. An example is a page's
// script: it is run whole, unchanged, with the page's things it asks for stood in below, and the material of the mesh it
// draws is what is written. Its numbers are the author's; it has no uniforms of its own, so no knobs.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as THREE from "three/webgpu"
import { madeText } from "./write_shelf_file"
import { pointsText } from "./write_shelf_points"

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
    std.open(`../../../shelves/effects/geometry/${file}_points.wgsl`, "w").puts(pointsText(mesh, [`// ${title} Wobble: the points of a solid moved by noise. ${by}`, "// --label:3d"], [], new Map()))
    console.log(`${file}_points: made`)
  }
  const sheet: any = new THREE.MeshBasicNodeMaterial()
  sheet.colorNode = material.colorNode
  const made = madeText(sheet, [`// ${title}: ${by}`, "// --label:Generate",
    "// --about:Uses TypeGPU shader functions and procedural noise inside a minimal Three.js WebGPU material."], [], new Map(), new Map())
  std.open(`${dir}/${file}.wgsl`, "w").puts(made.text)
  console.log(`${file}: ${made.knobs} knobs, ${made.uniforms} uniforms`)
}

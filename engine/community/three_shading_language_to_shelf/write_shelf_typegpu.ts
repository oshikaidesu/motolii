// TypeGPU's own three.js examples (software-mansion/TypeGPU, MIT) as files of the effects shelf: JavaScript functions marked
// 'use gpu', made TSL nodes by @typegpu/three's toTSL as each example does it (apps/typegpu-docs/src/examples/threejs/
// simple/index.ts:18 `material.colorNode = t3.toTSL(() => {`), then WGSL by three.js's own builder. An example is a page's
// script: it is run whole, unchanged, as from_page.js runs any three.js page, and the material of the mesh it draws is
// what is written. Its numbers are the author's; it has no uniforms of its own, so no knobs.
import "core-js/actual/url"
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import { drawnMesh, made, stand } from "./from_page.js"

const dir = "../../../shelves/effects/generate"   // (its --label:Generate)

const examples: [string, string, () => Promise<any>][] = [
  ["tg_simple", "Perlin Noise", () => import("../../third_party/tsl/software-mansion__TypeGPU/apps/typegpu-docs/src/examples/threejs/simple/index")],
]
for (const [file, title, run] of examples) {
  stand()
  await run()
  const mesh = drawnMesh(), by = `TypeGPU's "Three.js - Simple" example by Software Mansion (MIT, github.com/software-mansion/TypeGPU), by TypeGPU's toTSL and three.js's own builder (engine/community/three_shading_language_to_shelf/write_shelf_typegpu.ts)`
  const text = made(mesh, [`// ${title}: ${by}`, "// --label:Generate", "// --about:Uses TypeGPU shader functions and procedural noise inside a minimal Three.js WebGPU material."],
    [`// ${title} Wobble: the points of a solid moved by noise. ${by}`, "// --label:3d"])
  if (text.points) { std.open(`../../../shelves/effects/geometry/${file}_points.wgsl`, "w").puts(text.points); console.log(`${file}_points: made`) }
  if (text.effect) { std.open(`${dir}/${file}.wgsl`, "w").puts(text.effect); console.log(`${file}: made`) }
}

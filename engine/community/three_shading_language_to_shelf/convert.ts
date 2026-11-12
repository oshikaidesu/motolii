// Each collection's entry (tsl_textures.ts, ...) makes its effects as its author's README says and hands them here; three.js's
// own builder turns them to WGSL (three_builder.js) and the shaders land in engine/out/tsl/<collection>/
// (reports/shaderlab_origins.md).
import "core-js/actual/url"   // QuickJS has no URL or structuredClone: core-js's (MIT), the usual ones
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as os from "qjs:os"
import { wgsl } from "./three_builder.js"
export { built, plane, renderer, wgsl } from "./three_builder.js"

// Each named effect made by `make` (a material for the plane) written to engine/out/tsl/<collection>/<name>.{vert,frag}.wgsl; a line
// for each in engine/out/tsl/<collection>/made.tsv: name, ok or the builder's error.
export function convertAll(collection: string, effects: [string, () => any][]) {
  const dir = "../../out/tsl/" + collection
  os.mkdir("../../out"); os.mkdir("../../out/tsl"); os.mkdir(dir)
  const said = std.open(dir + "/made.tsv", "w")
  let ok = 0
  for (const [name, make] of effects) {
    try {
      const material = make()
      const [v, f] = wgsl(new THREE.Mesh(plane, material), material)
      std.open(`${dir}/${name}.vert.wgsl`, "w").puts(v)
      std.open(`${dir}/${name}.frag.wgsl`, "w").puts(f)
      said.puts(`${name}\tok\n`); ok++
    } catch (e: any) { said.puts(`${name}\t${String(e?.message ?? e).replace(/\s+/g, " ").slice(0, 160)}\n`) }
  }
  said.close()
  console.log(`${collection}: ${ok} of ${effects.length} turned to WGSL`)
}

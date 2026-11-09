// A TSL material turned to WGSL by three.js's own builder (WGSLNodeBuilder), with no GPU, in QuickJS: set up as three's
// Nodes._createNodeBuilder does (three.webgpu.js 55300-55310), the camera in WebGPU's own coordinates as its Renderer
// does before it draws (62657). Each collection's entry (tsl_textures.ts, ...) makes its effects as its author's README
// says and hands them here; the shaders land in engine/out/tsl/<collection>/ (reports/shaderlab_origins.md).
import "core-js/actual/url"   // QuickJS has no URL or structuredClone: core-js's (MIT), the usual ones
import "core-js/actual/structured-clone"
import * as std from "qjs:std"
import * as os from "qjs:os"
import * as THREE from "three/webgpu"

export const renderer: any = new THREE.WebGPURenderer({ canvas: { getContext() { return null }, style: {}, addEventListener() {} } as any })
// The two things the builder asks the GPU it will draw on, answered as plain WebGPU with no optional features.
renderer._initialized = true
renderer.backend.hasFeature = () => false
renderer.backend.utils = new Proxy({}, { get: (_, k: string) => () => k === "getTextureSampleData" ? { primarySamples: 1 } : undefined })

export const plane = new THREE.PlaneGeometry(2, 2)

export function built(object: any, material: any, camera?: any, scene?: any): any {
  camera ??= new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)
  scene ??= new THREE.Scene()
  camera.coordinateSystem = (THREE as any).WebGPUCoordinateSystem
  camera.updateProjectionMatrix()
  scene.updateMatrixWorld(); camera.updateMatrixWorld(); object.updateMatrixWorld()
  const b: any = new (THREE as any).WGSLNodeBuilder(object, renderer)
  b.scene = scene; b.material = material; b.camera = camera; b.context.material = material
  b.build()
  return b
}

export function wgsl(object: any, material: any, camera?: any, scene?: any): [string, string] {
  const b = built(object, material, camera, scene)
  return [b.vertexShader, b.fragmentShader]
}

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

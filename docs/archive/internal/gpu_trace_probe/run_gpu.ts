// Runs each compute shader on the GPU (Deno's WebGPU, wgpu on Metal) and compares every copy with ref.mjs's values.
const dir = Deno.args[0]
const adapter = await navigator.gpu.requestAdapter(); const device = await adapter!.requestDevice()
const N = 64, results: string[] = []
let same = 0, all = 0
for (const e of [...Deno.readDirSync(dir)].filter(e => e.name.endsWith(".comp.wgsl")).sort((a, b) => a.name.localeCompare(b.name))) {
  const stem = e.name.replace(".comp.wgsl", ""), code = Deno.readTextFileSync(`${dir}/${e.name}`)
  let ref: number[][]; try { ref = JSON.parse(Deno.readTextFileSync(`${dir}/${stem}.ref.json`)) } catch { results.push(`${stem}\tno ref`); continue }
  all++
  device.pushErrorScope("validation")
  const module = device.createShaderModule({ code })
  const pipeline = device.createComputePipeline({ layout: "auto", compute: { module, entryPoint: "main" } })
  const out = device.createBuffer({ size: N * 2 * 16, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC })
  const uni = device.createBuffer({ size: 16, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST })
  device.queue.writeBuffer(uni, 0, new Uint32Array([N, 0, 0, 0]))
  const read = device.createBuffer({ size: N * 2 * 16, usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST })
  const used = [...code.matchAll(/@binding\( (\d+) \) @group\( 0 \)\s*var<(\w+)/g)].map(m => ({ binding: +m[1], resource: { buffer: m[2] === "uniform" ? uni : out } }))
  const bind = device.createBindGroup({ layout: pipeline.getBindGroupLayout(0), entries: used })
  const enc = device.createCommandEncoder(), pass = enc.beginComputePass()
  pass.setPipeline(pipeline); pass.setBindGroup(0, bind); pass.dispatchWorkgroups(1); pass.end()
  enc.copyBufferToBuffer(out, 0, read, 0, N * 2 * 16); device.queue.submit([enc.finish()])
  const err = await device.popErrorScope(); if (err) { results.push(`${stem}\tgpu error: ${err.message.slice(0, 120)}`); continue }
  await read.mapAsync(GPUMapMode.READ); const g = new Float32Array(read.getMappedRange().slice(0)); read.unmap()
  let worst = 0, where = ""
  const keys = ["x", "y", "z", "size", "rotate", "rotate_x", "rotate_y", "opacity"], order = [0, 1, 2, 3, 4, 5, 6, 7]
  for (let i = 0; i < N; i++) for (const j of order) {
    const a = g[i * 8 + j], b = ref[i][j], d = Math.abs(a - b) / Math.max(1, Math.abs(b))
    if (!(d <= worst) ) { worst = Number.isNaN(d) ? Infinity : d; where = `copy ${i} ${keys[j]} gpu ${a} js ${b}` }
  }
  const ok = worst < 1e-4; if (ok) same++
  results.push(`${stem}\t${ok ? "same" : "DIFFERS"}\tworst ${worst.toExponential(2)}${ok ? "" : "  " + where}`)
}
Deno.writeTextFileSync(`${dir}/values.tsv`, results.join("\n") + "\n")
console.log(results.join("\n")); console.log(`\nsame as the code run as written: ${same} of ${all} (file, time)`)

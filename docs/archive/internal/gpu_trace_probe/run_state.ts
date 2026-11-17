// Runs each <name>.check.wgsl (one step of a sketch, buffer to buffer) on the GPU (Deno's WebGPU, wgpu on Metal) with
// the carried values before frame 31 from <name>.check.json, and compares what comes out with the values the sketch
// run as written had after frame 31.   deno run --allow-read --allow-write --unstable-webgpu run_state.ts <folder>
const dir = Deno.args[0]
const adapter = await navigator.gpu.requestAdapter(); const device = await adapter!.requestDevice()
const results: string[] = []
let same = 0, all = 0
for (const e of [...Deno.readDirSync(dir)].filter(e => e.name.endsWith(".check.wgsl")).sort((a, b) => a.name.localeCompare(b.name))) {
  const stem = e.name.replace(".check.wgsl", ""), code = Deno.readTextFileSync(`${dir}/${e.name}`)
  const ref = JSON.parse(Deno.readTextFileSync(`${dir}/${stem}.check.json`)) as { paths?: string[]; in: number[]; out: number[]; count?: number; stride?: number; outAtOnce?: number[] }
  all++
  const n = Math.max(1, ref.in.length), bytes = n * 4, runs = ref.count ?? 1
  device.pushErrorScope("validation")
  const module = device.createShaderModule({ code })
  const pipeline = device.createComputePipeline({ layout: "auto", compute: { module, entryPoint: "main" } })
  // The buffers in the order three.js made them: the one the step reads first, the one it writes last.
  const found = [...code.matchAll(/@binding\( (\d+) \) @group\( (\d+) \)\s*var<(\w+)[^>]*> (\w+)/g)].map(m => ({ binding: +m[1], group: +m[2], kind: m[3], name: m[4] }))
  const stores = found.filter(f => f.kind === "storage").sort((a, b) => +a.name.replace(/\D+/g, "") - +b.name.replace(/\D+/g, ""))
  const make = (data?: Float32Array) => { const b = device.createBuffer({ size: bytes, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST }); if (data) device.queue.writeBuffer(b, 0, data); return b }
  const out = make(), into = make(new Float32Array(n).map((_, i) => ref.in[i] ?? 0)), count = device.createBuffer({ size: 256, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST })
  // (three.js's compute shader stops past its count, the one uniform it has here: one run of the step)
  device.queue.writeBuffer(count, 0, new Uint32Array([runs]))
  if (/var<uniform>/.test(code) && !/struct objectStruct \{\s*nodeUniform\d+ : u32\s*\};/.test(code)) { results.push(`${stem}\tnot run: the step has uniforms besides its count`); all--; continue }
  const groups = [...new Set(found.map(f => f.group))]
  const enc = device.createCommandEncoder(), pass = enc.beginComputePass()
  pass.setPipeline(pipeline)
  for (const g of groups) pass.setBindGroup(g, device.createBindGroup({ layout: pipeline.getBindGroupLayout(g), entries: found.filter(f => f.group === g).map(f =>
    ({ binding: f.binding, resource: { buffer: f.kind !== "storage" ? count : stores.length > 1 && f.name === stores[0].name ? into : out } })) }))
  pass.dispatchWorkgroups(Math.ceil(runs / 64)); pass.end()
  const read = device.createBuffer({ size: bytes, usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST })
  enc.copyBufferToBuffer(out, 0, read, 0, bytes); device.queue.submit([enc.finish()])
  const err = await device.popErrorScope(); if (err) { results.push(`${stem}\tgpu error: ${err.message.replace(/\s+/g, " ").slice(0, 160)}`); continue }
  await read.mapAsync(GPUMapMode.READ); const g = new Float32Array(read.getMappedRange().slice(0)); read.unmap()
  if (ref.stride) {   // one object's rule: against the sketch as written, and against every object reading the list as it was
    const far = (want: number[], from = 0, to = n) => { let w = 0, at = -1; for (let i = from; i < to; i++) { const d = Math.abs(g[i] - want[i]) / Math.max(1, Math.abs(want[i])); if (!(d <= w)) { w = Number.isNaN(d) ? Infinity : d; at = i } } return { w, at } }
    const a = far(ref.out), first = far(ref.out, 0, ref.stride), b = far(ref.outAtOnce!)
    const moved = ref.in.filter((v, i) => v !== ref.out[i]).length, differ = ref.out.filter((v, i) => Math.abs(v - ref.outAtOnce![i]) > 1e-4 * Math.max(1, Math.abs(v))).length
    const ok = b.w < 1e-4; if (ok) same++
    results.push(`${stem}\t${ok ? "same" : "DIFFERS"} as every object reading the list as it was (worst ${b.w.toExponential(2)}${ok ? "" : `, number ${b.at}: gpu ${g[b.at]}, wanted ${ref.outAtOnce![b.at]}`})` +
      `\t${a.w < 1e-4 ? "same" : "differs"} as written (worst ${a.w.toExponential(2)}; the first object ${first.w.toExponential(2)}; as written and all-at-once differ in ${differ} of ${n} numbers)\t${ref.count} objects, ${moved} of ${n} numbers moved`)
    continue
  }
  let worst = 0, where = "", moved = 0
  ref.paths!.forEach((p, i) => {
    if (ref.in[i] !== ref.out[i]) moved++
    const d = Math.abs(g[i] - ref.out[i]) / Math.max(1, Math.abs(ref.out[i]))
    if (!(d <= worst)) { worst = Number.isNaN(d) ? Infinity : d; where = `${p}: gpu ${g[i]}, as written ${ref.out[i]} (was ${ref.in[i]})` }
  })
  const ok = worst < 1e-4; if (ok) same++
  results.push(`${stem}\t${ok ? "same" : "DIFFERS"}\t${ref.paths!.length} carried, ${moved} moved in this frame\tworst ${worst.toExponential(2)}${ok ? "" : "  " + where}`)
}
Deno.writeTextFileSync(`${dir}/values.tsv`, results.join("\n") + "\n")
console.log(results.join("\n")); console.log(`\nsame as the sketch run as written: ${same} of ${all}`)

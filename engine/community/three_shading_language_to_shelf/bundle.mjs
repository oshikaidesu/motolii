// run.sh's bundling: esbuild with TypeGPU's own build plugin (unplugin-typegpu, MIT), which gives each function marked
// 'use gpu' the syntax tree TypeGPU turns into WGSL (docs.swmansion.com/TypeGPU/tooling/unplugin-typegpu). A file with no
// such function passes through unchanged.   node bundle.mjs <entry>
import { build } from "esbuild"
import typegpu from "unplugin-typegpu/esbuild"

const name = process.argv[2]
await build({
  entryPoints: [`${name}.ts`], outfile: `../../out/tsl/${name}.mjs`, tsconfig: "../../third_party/tsl/basementstudio__shader-lab/tsconfig.json",
  bundle: true, format: "esm", platform: "neutral", mainFields: ["module", "main"], external: ["qjs:std", "qjs:os", "typescript"], logLevel: "error", define: { "process.env.NODE_ENV": '"production"' },
  nodePaths: [`${process.cwd()}/node_modules`], plugins: [typegpu({})],
})

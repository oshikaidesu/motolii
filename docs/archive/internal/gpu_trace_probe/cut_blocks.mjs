// Cuts every ```js block out of the Markdown files under a folder into one file each, and prints their paths.
//   node cut_blocks.mjs <docs folder> <out folder>
import fs from "node:fs"
import path from "node:path"
const [, , docs, out] = process.argv
fs.mkdirSync(out, { recursive: true })
const walk = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith(".md") ? [path.join(d, e.name)] : [])
for (const md of walk(docs).sort()) {
  let n = 0
  for (const m of fs.readFileSync(md, "utf8").matchAll(/^( *)```js\n([\s\S]*?)^\1```/gm)) {
    const file = path.join(out, `${path.relative(docs, md).replace(/\.md$/, "").replace(/\W+/g, "_")}__${String(++n).padStart(2, "0")}.js`)
    fs.writeFileSync(file, m[2].split("\n").map(l => l.slice(m[1].length)).join("\n"))
    console.log(file)
  }
}

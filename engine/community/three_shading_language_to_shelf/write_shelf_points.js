// A three.js material that moves its mesh's points, written as a points file of the effects shelf (a WGSL compute shader,
// stage/layer_effects/layer_fx.h thing_fx_points).
import { time } from "three/tsl";
import { built } from "./three_builder.js";
import { parts, uniformsOf } from "./write_shelf_file.js";
// A material that moves its mesh's points (positionNode), as a compute shader of the shape stage/layer_effects/layer_fx.h
// thing_fx_points runs: three's own vertex shader for the author's mesh, kept as its builder wrote it, its entry made a
// function that is given a point and returns positionLocal, where three has the moved point before its camera. Its
// uniforms are said as they stand; time is the file's time; `of` says which are the file's sliders (each of a uniform's
// numbers as `knobs.<name>`), `tracks` their head lines, in the order the Knobs struct lists them: all f32, as the engine
// fills them. The normals drawn are the shape's own, unless the material has a varying named v_shape_normal: then that
// is written as each point's normal.
export function pointsText(mesh, head, tracks, of) {
    const b = built(mesh, mesh.material), uniforms = uniformsOf(b);
    let body = b.vertexShader.slice(b.vertexShader.indexOf("// structs"));
    const reads = [];
    body = body.replace(/struct (\w+) \{\n([\s\S]*?)\n\};\n@binding\( \d+ \) @group\( \d+ \)\nvar<uniform> (\w+) : \1;\n/g, (_, _s, list, block) => {
        for (const line of list.split("\n")) {
            const [name, type] = line.replace(/[\s,]/g, "").split(":");
            const u = uniforms.find((x) => x.name === name), v = u?.node?.value;
            if (u && of.has(u.node)) {
                const made = of.get(u.node);
                reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), made.length === 1 ? `${type}(${made[0]})` : `${type}(${made.join(", ")})`]);
                continue;
            }
            const numbers = u?.node === time ? null : parts(v) ?? (v?.elements ? Array.from(v.elements) : type === "mat4x4<f32>" ? [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1] : type === "mat3x3<f32>" ? [1, 0, 0, 0, 1, 0, 0, 0, 1] : [0]);
            reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), numbers ? `${type}(${numbers.map(x => Number.isInteger(x) ? x.toFixed(1) : String(x)).join(", ")})` : "knobs.time"]);
        }
        return "";
    });
    for (const [from, to] of reads)
        body = body.replace(from, to);
    const entry = /@vertex\s*fn main\( ([\s\S]*?) \) -> VaryingsStruct \{/.exec(body);
    if (!entry)
        throw new Error("no vertex entry");
    const given = entry[1].split(",").map(x => /(\w+) : ([\w<>]+)/.exec(x)).map(([, name, type]) => {
        if (name === "position")
            return "vec3f(shape_points[3u * i], shape_points[3u * i + 1u], shape_points[3u * i + 2u])";
        if (name === "uv")
            return "vec2f(shape_uvs[2u * i], shape_uvs[2u * i + 1u])";
        if (name === "tangent")
            return "vec4f(shape_tangents[4u * i], shape_tangents[4u * i + 1u], shape_tangents[4u * i + 2u], shape_tangents[4u * i + 3u])";
        if (name === "normal")
            return "vec3f(shape_normals[3u * i], shape_normals[3u * i + 1u], shape_normals[3u * i + 2u])";
        throw new Error(`reads the shape's ${name} (${type}), which a points file is not given yet`);
    });
    body = body.replace(entry[0], `fn point_moved( ${entry[1].replace(/@location\( \d+ \) /g, "")} ) -> vec3<f32> {`).replace(/return varyings;/, "return positionLocal;");
    const fns = [...body.matchAll(/^fn (\w+)/gm)].map(m => m[1]), twice = fns.find((n, i) => fns.indexOf(n) !== i);
    if (twice)
        throw new Error(`two functions named ${twice}: GLSL takes that, WGSL does not`);
    const normals = body.includes("varyings.v_shape_normal"); // (the material's own normals after the move, as a varying of that name)
    const names = tracks.map(l => /@(\w+):/.exec(l)[1]);
    return [...head, ...tracks, `struct Knobs {\n  time: f32,\n${names.map(n => `  ${n}: f32,\n`).join("")}};
@group(0) @binding(0) var<uniform> knobs: Knobs;
@group(0) @binding(2) var<storage, read_write> shape_points: array<f32>;
@group(0) @binding(4) var<storage, read_write> shape_uvs: array<f32>;
@group(0) @binding(6) var<storage, read_write> points: array<f32>;
@group(0) @binding(8) var<storage, read_write> shape_normals: array<f32>;
${normals ? "@group(0) @binding(10) var<storage, read_write> normals: array<f32>;\n" : ""}@group(0) @binding(12) var<storage, read_write> shape_tangents: array<f32>;
`, body, `@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&points) || 3u * i + 2u >= arrayLength(&shape_points) || 2u * i + 1u >= arrayLength(&shape_uvs) || 3u * i + 2u >= arrayLength(&shape_normals) || 4u * i + 3u >= arrayLength(&shape_tangents)) { return; }
  let p = point_moved(${given.join(", ")});
  points[3u * i] = p.x; points[3u * i + 1u] = p.y; points[3u * i + 2u] = p.z;
${normals ? "  let n = varyings.v_shape_normal;\n  normals[3u * i] = n.x; normals[3u * i + 1u] = n.y; normals[3u * i + 2u] = n.z;\n" : ""}}
`].join("\n");
}

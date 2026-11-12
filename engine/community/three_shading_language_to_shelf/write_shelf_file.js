// three's shaders as one file of the effects shelf, the shape screen_fx.h screen_read takes, the shape engine/community/isf/isf.cpp makes of
// ISF's PASSES: the stage's picture at binding 0, each target's after it, one struct of knobs, one entry that goes by
// `passindex`; every step's fragment shader kept as three's builder wrote it, its names apart.
import * as THREE from "three/webgpu";
import { time } from "three/tsl";
import { built, plane } from "./three_builder.js";
// (the builder's own list: getBindings() gives a shared group, time's, as first built, with that build's names)
export const uniformsOf = (b) => [...b.uniforms.vertex, ...b.uniforms.fragment].filter((u) => !/texture|sampler/i.test(u.type));
// A uniform's value as numbers (none: not a thing a knob can be).
export function parts(v) {
    if (typeof v === "number")
        return [v];
    if (typeof v === "boolean")
        return [Number(v)];
    if (v?.isColor)
        return [v.r, v.g, v.b];
    if (v?.isVector2)
        return [v.x, v.y];
    if (v?.isVector3)
        return [v.x, v.y, v.z];
    if (v?.isVector4)
        return [v.x, v.y, v.z, v.w];
    return null;
}
const number = (x) => (Number.isInteger(x) ? x.toFixed(1) : String(x));
function literal(type, v) {
    if (type === "f32")
        return `f32(${number(Number(v))})`;
    if (type === "i32" || type === "u32")
        return `${type}(${Math.round(Number(v))})`;
    return `${type}(${(parts(v) ?? Array.from(v.elements)).map(number).join(", ")})`;
}
// One drawing of a material as it stands now. `made` keeps what a material was built into: its text is the same each time.
export function stepOf(made, mesh, camera, scene, target) {
    let one = made.get(mesh.material);
    if (!one) {
        const sampled = (b) => { const all = []; b.getBindings().forEach((g) => g.bindings.forEach((x) => { if (x.isSampledTexture)
            all.push(x); })); return all; };
        for (const x of sampled(built(mesh, mesh.material, camera, scene))) { // (the author's nearest pictures, THREE.LinearFilter: three would load them, and a load is not read through the frame)
            const t = x.textureNode?.value;
            if (t) {
                t.userData.nearest ??= t.magFilter === 1003;
                t.minFilter = t.magFilter = 1006;
            }
        }
        const b = built(mesh, mesh.material, camera, scene);
        one = { frag: b.fragmentShader, varying: [...b.vertexShader.matchAll(/varyings\.(\w+) = (\w+);/g)].map(m => `${m[1]}=${m[2]}`), uniforms: uniformsOf(b), nodes: sampled(b).map((x) => [x.name, x.textureNode]) };
        made.set(mesh.material, one);
    }
    return { ...one, values: one.uniforms.map((u) => { const v = u.node.value; return v?.clone ? v.clone() : v; }),
        pictures: one.nodes.map(([name, node]) => [name, node.value]), target };
}
// three works in linear light on colours not premultiplied, the shelf's effects in sRGB on premultiplied ones (screen_fx.h
// screen_tone, whose lines these are). What is read goes through the frame as isf.cpp's `texture` does; a target's is as
// three drew it.
// (a picture beside the file, screen_fx.h's --image@: read whole, no frame on it)
const whole = `fn image_read(t: texture_2d<f32>, s: sampler, uv: vec2f) -> vec4f { return textureSampleLevel(t, s, uv, 0.0); }
fn image_read_level(t: texture_2d<f32>, s: sampler, uv: vec2f, level: f32) -> vec4f { return textureSampleLevel(t, s, uv, level); }
fn image_load(t: texture_2d<f32>, p: vec2i, level: u32) -> vec4f { return textureLoad(t, p, level); }
`;
const tones = `fn to_linear(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }
fn to_srgb(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }
fn framed(uv: vec2f) -> vec2f { return uv * knobs.frameRect.zw + knobs.frameRect.xy; }
fn picture_read(uv: vec2f) -> vec4f { return picture_read_level(uv, 0.0); }
fn picture_read_level(uv: vec2f, level: f32) -> vec4f {
  let p = textureSampleLevel(picture, picture_sampler, framed(uv), level);
  if (p.a <= 0.0) { return vec4f(0.0); }
  return vec4f(to_linear(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))), p.a);
}
fn picture_load(p: vec2i, level: u32) -> vec4f { return picture_read_level((vec2f(p) + 0.5) / knobs.resolution, 0.0); }
fn target_read(t: texture_2d<f32>, s: sampler, uv: vec2f) -> vec4f { return textureSampleLevel(t, s, framed(uv), 0.0); }
fn target_load(t: texture_2d<f32>, p: vec2i, level: u32) -> vec4f { return textureLoad(t, p + vec2i(knobs.frameRect.xy * vec2f(textureDimensions(t)) + 0.5), level); }
fn target_read_level(t: texture_2d<f32>, s: sampler, uv: vec2f, level: f32) -> vec4f { return textureSampleLevel(t, s, framed(uv), level); }
fn to_shelf(p: vec4f) -> vec4f { return vec4f(to_srgb(clamp(p.rgb, vec3f(0.0), vec3f(1.0))) * p.a, p.a); }
fn none(uv: vec2f) -> vec4f { return vec4f(0.0); }
fn none_level(uv: vec2f, level: f32) -> vec4f { return vec4f(0.0); }
fn none_load(p: vec2i, level: u32) -> vec4f { return vec4f(0.0); }
`;
// A picture of its own small enough to say in the file: its numbers, read as the author's sampler reads it. All one colour:
// that colour.
function table(name, t) {
    const { data, width: w, height: h } = t.image, load = `fn ${name}_load(p: vec2i, level: u32) -> vec4f { return ${name}((vec2f(p) + 0.5) / vec2f(${w}.0, ${h}.0)); }\n`, scale = data instanceof Uint8Array ? 1 / 255 : 1, per = data.length / (w * h);
    const at = (i) => { const c = [0, 1, 2, 3].map(k => k < per ? data[i * per + k] * scale : k === 3 ? 1 : per === 1 ? data[i] * scale : 0); return `vec4f(${c.map(number).join(",")})`; };
    const texels = Array.from({ length: w * h }, (_, i) => at(i));
    if (new Set(texels).size === 1)
        return `fn ${name}(uv: vec2f) -> vec4f { return ${texels[0]}; }\n` + load;
    const wrap = (axis, way) => way === 1000 ? `fract(${axis})` : way === 1002 ? `(1.0 - abs(1.0 - 2.0 * fract(${axis} * 0.5)))` : `clamp(${axis}, 0.0, 1.0)`;
    const edge = (axis, way, n) => way === 1001 ? `clamp(${axis}, 0, ${n - 1})` : `((${axis} % ${n}) + ${n}) % ${n}`; // (past the end: THREE.ClampToEdgeWrapping stops there)
    const pick = t.userData.nearest ? "" : "linear";
    return `const ${name}_texels = array<vec4f, ${w * h}>(${texels.join(",")});
fn ${name}_at(x: i32, y: i32) -> vec4f { return ${name}_texels[${edge("y", t.wrapT, h)} * ${w} + ${edge("x", t.wrapS, w)}]; }
fn ${name}(uv: vec2f) -> vec4f {
  let p = vec2f(${wrap("uv.x", t.wrapS)}, ${wrap("uv.y", t.wrapT)}) * vec2f(${w}.0, ${h}.0) - vec2f(0.5);
  let a = vec2i(floor(p)); let f = fract(p);
  ${pick ? `return mix(mix(${name}_at(a.x, a.y), ${name}_at(a.x + 1, a.y), f.x), mix(${name}_at(a.x, a.y + 1), ${name}_at(a.x + 1, a.y + 1), f.x), f.y);` : `return ${name}_at(a.x + i32(f.x + 0.5), a.y + i32(f.y + 0.5));`}
}
` + load;
}
// Each step's shader with its names apart (p<step>_), what it reads and its uniforms said in the file's terms.
function stepText(k, step, said, fields, nameOf, tables, images, share, place) {
    let body = step.frag.slice(step.frag.indexOf("// structs")), picture = new Map(step.pictures);
    const reads = [], late = [];
    body = body.replace(/@binding\( \d+ \) @group\( \d+ \) var (\w+) : (texture_2d<f32>|sampler);\n/g, (_, name, type) => {
        if (type === "sampler")
            return "";
        const t = picture.get(name), of = images.get(t) ?? nameOf(t), kind = images.has(t) ? "image" : "target";
        const fn = of === "picture" ? "picture" : tables.get(t), by = fn ? `${fn}( ` : `${kind}_read( ${of}, ${of}_sampler, `, level = fn ? `${fn}_level( ` : `${kind}_read_level( ${of}, ${of}_sampler, `;
        late.push([`textureSample( ${name}, ${name}_sampler, `, fn === "picture" ? "picture_read( " : by], [`textureSampleLevel( ${name}, ${name}_sampler, `, fn === "picture" ? "picture_read_level( " : level], [`textureLoad( ${name}, `, fn ? `${fn}_load( ` : `${kind}_load( ${of}, `]);
        return "";
    });
    const staged = (e) => e.replace(/\bS\.x\b/g, share[0] === 1 ? "knobs.resolution.x" : `(knobs.resolution.x / ${share[0]})`).replace(/\bS\.y\b/g, share[1] === 1 ? "knobs.resolution.y" : `(knobs.resolution.y / ${share[1]})`);
    body = body.replace(/struct (\w+) \{\n([\s\S]*?)\n\};\n@binding\( \d+ \) @group\( \d+ \)\nvar<uniform> (\w+) : \1;\n/g, (_, _s, list, block) => {
        for (const line of list.split("\n")) {
            const [name, type] = line.replace(/[\s,]/g, "").split(":");
            if (!step.frag.includes(`${block}.${name}`) || name === undefined)
                continue; // (the vertex shader's alone)
            const at = step.uniforms.findIndex(x => x.name === name), value = step.values[at], made = said.get(`${k}:${name}`);
            if (made && parts(value)) {
                const all = parts(value), each = all.map((v, i) => staged(made[i] ?? number(v)));
                reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), each.length === 1 ? `${type}(${each[0]})` : `${type}(${each.join(", ")})`]);
            }
            else
                reads.push([new RegExp(`\\b${block}\\.${name}\\b`, "g"), literal(type, value)]);
        }
        return "";
    });
    for (const [from, to] of reads)
        body = body.replace(from, to);
    for (const [from, to] of late)
        body = body.split(from).join(to);
    const varying = /fn main\( ([\s\S]*?) \) -> OutputStruct \{/.exec(body)?.[1] ?? "";
    const given = varying.split(",").filter(x => x.trim()).map(x => /(\w+) : (vec\d<f32>)/.exec(x)).map(([, name, type]) => {
        const was = step.varying.find(v => v.startsWith(`${name}=`))?.split("=")[1] ?? "uv";
        return `\tlet ${name} = ${name === "fragCoord" ? "vec4f(door_uv * knobs.resolution, 0.0, 1.0)" : was === "position" ? place : was === "normal" ? "vec3f(0.0, 0.0, 1.0)" : type === "vec2<f32>" ? "vec2f(door_uv.x, 1.0 - door_uv.y)" : "vec3f(door_uv.x, 1.0 - door_uv.y, 0.0)"};`;
    }).join("\n");
    body = body.replace(/@fragment\s*\n/, "").replace(/fn main\( [\s\S]*? \) -> OutputStruct \{/, `fn main(door_uv: vec2f) -> OutputStruct {\n${given}`);
    for (const m of [...body.matchAll(/^(?:fn|struct|const|var<private>|var)\s+(\w+)/gm)])
        body = body.replace(new RegExp(`(?<![.\\w])${m[1]}\\b`, "g"), `PSTEP_${m[1]}`);
    return body;
}
// `made`: a texture that makes its own picture (its place on a sheet as wide as what it fills, its see-through what is under
// it, as an ISF generator's: isf.cpp, Preserve Underlying Transparency).
// `saved`: where a picture of its own too large to say in the file goes, the file's name for it.
export function fileText(head, steps, said, fields, targets, nameOf, tail, made = false, saved) {
    const last = steps.length - 1, tables = new Map(), images = new Map();
    let code = "";
    steps.forEach(s => s.pictures.forEach(([, t]) => {
        if (nameOf(t) === "none")
            tables.set(t, "none"); // (read by a step and drawn by none, as the file plays: the author's own branch, off)
        if (nameOf(t) !== "own" || tables.has(t) || images.has(t))
            return;
        if (saved && t.image.data instanceof Uint8Array && t.image.width * t.image.height > 4096 && new Set(t.image.data).size > 1) {
            head = [...head, `// --image@image${images.size}:${saved(t, images.size)}`];
            images.set(t, `image${images.size}`);
            return;
        }
        const fn = `own${tables.size}_read`;
        tables.set(t, fn);
        code += table(fn, t) + `fn ${fn}_level(uv: vec2f, level: f32) -> vec4f { return ${fn}(uv); }\n`;
    }));
    const bound = ["picture", ...targets.map(t => t.name), ...images.values()];
    const bindings = bound.map((n, i) => `@group(0) @binding(${2 * i}) var ${n}: texture_2d<f32>;\n@group(0) @binding(${2 * i + 1}) var ${n}_sampler: sampler;\n`).join("");
    const each = steps.map((s, k) => {
        const t = s.target ? targets.find(x => x.name === nameOf(s.target)) : null;
        return stepText(k, s, said, fields, nameOf, tables, images, t ? t.share : [1, 1], made ? "vec3f((2.0 * door_uv.x - 1.0) * knobs.resolution.x / knobs.resolution.y, 1.0 - 2.0 * door_uv.y, 0.0)" : "vec3f(2.0 * door_uv.x - 1.0, 1.0 - 2.0 * door_uv.y, 0.0)");
    });
    const texts = [...new Set(each)], of = each.map(t => texts.indexOf(t)); // (a step that draws what one before it does: that one's lines)
    const knobs = `struct Knobs {\n  time: f32,\n  passindex: f32,\n  resolution: vec2<f32>,\n  frameRect: vec4<f32>,\n  passRect: vec4<f32>,\n${[...fields].map(([n, t]) => `  ${n}: ${t},`).join("\n")}\n};\n`;
    const drawn = tail ? steps.length : last, cases = texts.map((_, j) => of.map((o, k) => o === j && k < drawn ? `${k}u` : "").filter(x => x)).map((ks, j) => ks.length ? `    case ${ks.join(", ")}: { return p${j}_main(door_uv).color; }\n` : "").join("");
    const entry = `@fragment\nfn main(@location(0) door_on: vec2f) -> @location(0) vec4f {\n  let door_uv = (door_on - knobs.passRect.xy) / knobs.passRect.zw;\n${drawn ? `  switch u32(knobs.passindex + 0.5) {\n${cases}    default: {}\n  }\n` : ""}  return to_shelf(${tail ? `target_read(${tail}, ${tail}_sampler, door_uv)` : `p${of[last]}_main(door_uv).color`})${made ? " * textureSampleLevel(picture, picture_sampler, framed(door_uv), 0.0).a" : ""};\n}\n`;
    return [...head, "diagnostic(off, derivative_uniformity);", knobs + bindings + `@group(0) @binding(${2 * bound.length}) var<uniform> knobs: Knobs;\n` + tones + (images.size ? whole : "") + code, ...texts.map((t, j) => t.replace(/\bPSTEP_/g, `p${j}_`)), entry].join("\n");
}
// A material that makes its own picture, as one file: `of` says which of its uniforms are which knobs, `lines` is each
// knob's head line with its uniform, and one the colour's shader does not read is not said.
export function madeText(material, head, lines, fields, of) {
    const step = stepOf(new Map(), new THREE.Mesh(plane, material), undefined, undefined, null), said = new Map();
    for (const u of step.uniforms) {
        if (u.node === time)
            said.set(`0:${u.name}`, ["knobs.time"]);
        else if (of.has(u.node))
            said.set(`0:${u.name}`, of.get(u.node));
    }
    const used = new Set(step.uniforms.map(u => u.node)), kept = lines.filter(([node]) => used.has(node)).map(([, line]) => line);
    return { text: fileText([...head, ...kept], [step], said, fields, [], t => t?.isDataTexture ? "own" : "picture", null, true), knobs: kept.length, uniforms: step.uniforms.length };
}

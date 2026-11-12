// A three.js page's script (an example, a pen, a demo's main file) run whole and unchanged with no page and no GPU: the
// things of the page it asks for are stood in, its renderer only notes the scene it is told to draw, and the material of
// the first mesh of that scene is what is written: its colour as an effect that makes its own picture, and, when it
// moves the mesh's points (positionNode), a points file. Plain JavaScript: the shelf writers use it (write_shelf_typegpu.ts)
// and so does the engine when TSL is pasted in the app (engine/community/three/tsl_shelf.cpp).
import * as THREE from "three/webgpu";
import { madeText } from "./write_shelf_file.js";
import { pointsText } from "./write_shelf_points.js";

let drawn;
// Stands the page in. Call before the script runs.
export function stand() {
    const g = globalThis, nothing = () => { };
    // (anything asked of an element: itself again, so chains of calls and reads go through)
    const element = () => new Proxy(function () { }, { get: (t, k) => k === "style" ? {} : k === "getContext" ? () => null : k === "clientWidth" || k === "clientHeight" || k === "width" || k === "height" ? 1 : k === Symbol.toPrimitive ? () => 1 : element(), set: () => true, apply: () => element() });
    drawn = undefined;
    g.window = g, g.self = g, g.devicePixelRatio = 1, g.innerWidth = 1, g.innerHeight = 1;
    g.addEventListener = nothing, g.removeEventListener = nothing, g.requestAnimationFrame = nothing, g.cancelAnimationFrame = nothing;
    g.setTimeout ??= nothing, g.setInterval ??= nothing, g.clearTimeout ??= nothing, g.clearInterval ??= nothing;
    g.performance ??= { now: () => 0 };
    g.navigator ??= { userAgent: "" };
    g.document = { querySelector: element, getElementById: element, createElement: element, createElementNS: element, addEventListener: nothing, body: element(), documentElement: element() };
    g.ResizeObserver = class { observe() { } disconnect() { } };
    const R = THREE.WebGPURenderer.prototype; // (no GPU here: the page's renderer only says what it would draw)
    R.init = async function () { }, R.setPixelRatio = R.setSize = nothing;
    R.setAnimationLoop = async function (frame) { frame?.(0); };
    R.render = R.renderAsync = function (scene) { drawn ??= scene; };
}
// The first mesh of the scene the script drew, or nothing.
export function drawnMesh() {
    let mesh;
    drawn?.traverse((o) => { if (o.isMesh && o.material?.isNodeMaterial) mesh ??= o; });
    return mesh;
}
// What the mesh's material is written as: { effect, points }, each a file's text or null. `effectHead` and `pointsHead`
// are the files' first lines (name, source, label).
export function made(mesh, effectHead, pointsHead) {
    const material = mesh.material, out = { effect: null, points: null };
    if (material.colorNode) {
        const sheet = new THREE.MeshBasicNodeMaterial();
        sheet.colorNode = material.colorNode;
        out.effect = madeText(sheet, effectHead, [], new Map(), new Map()).text;
    }
    if (material.positionNode) out.points = pointsText(mesh, pointsHead, [], new Map());
    return out;
}
